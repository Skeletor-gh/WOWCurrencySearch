local ADDON_NAME = ...

local CurrencySearch = CreateFrame("Frame")
CurrencySearch.db = nil
CurrencySearch.searchBox = nil
CurrencySearch.clearButton = nil
CurrencySearch.currentQuery = ""
CurrencySearch._isApplying = false

local function trim(text)
    if not text then
        return ""
    end

    return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function lower(text)
    return string.lower(text or "")
end

local function getCurrencyLabel(button)
    if not button then
        return nil
    end

    if button.name and button.name.GetText then
        return button.name:GetText()
    end

    if button.Name and button.Name.GetText then
        return button.Name:GetText()
    end

    if button.CurrencyName and button.CurrencyName.GetText then
        return button.CurrencyName:GetText()
    end

    for _, region in ipairs({ button:GetRegions() }) do
        if region and region.GetObjectType and region:GetObjectType() == "FontString" then
            local text = region:GetText()
            if text and text ~= "" then
                return text
            end
        end
    end

    return nil
end

local function isHeaderRow(button)
    if not button then
        return false
    end

    if button.isHeader ~= nil then
        return button.isHeader
    end

    if button.data and button.data.isHeader ~= nil then
        return button.data.isHeader
    end

    return false
end

function CurrencySearch:GetRootFrame()
    if TokenFrame and TokenFrame:IsObjectType("Frame") then
        return TokenFrame
    end

    if CurrencyFrame and CurrencyFrame:IsObjectType("Frame") then
        return CurrencyFrame
    end

    return nil
end

function CurrencySearch:CollectCurrencyButtons()
    local result = {}

    if TokenFrameContainer and TokenFrameContainer.buttons then
        for _, button in ipairs(TokenFrameContainer.buttons) do
            if button and button:IsObjectType("Button") then
                result[#result + 1] = button
            end
        end
        return result
    end

    if CurrencyFrame and CurrencyFrame.Container and CurrencyFrame.Container.buttons then
        for _, button in ipairs(CurrencyFrame.Container.buttons) do
            if button and button:IsObjectType("Button") then
                result[#result + 1] = button
            end
        end
        return result
    end

    local root = self:GetRootFrame()
    if not root then
        return result
    end

    local stack = { root }
    while #stack > 0 do
        local node = table.remove(stack)
        for _, child in ipairs({ node:GetChildren() }) do
            stack[#stack + 1] = child
            if child:IsObjectType("Button") then
                local label = getCurrencyLabel(child)
                if label and label ~= "" then
                    result[#result + 1] = child
                end
            end
        end
    end

    return result
end

function CurrencySearch:ApplyFilter()
    if self._isApplying then
        return
    end

    self._isApplying = true

    local enabled = self.db and self.db.enabled
    local query = lower(trim(self.currentQuery))
    local hasQuery = query ~= ""

    for _, button in ipairs(self:CollectCurrencyButtons()) do
        if button then
            if not enabled or not hasQuery then
                button:SetShown(true)
            else
                local label = lower(getCurrencyLabel(button) or "")
                local header = isHeaderRow(button)
                local show = header or (label ~= "" and string.find(label, query, 1, true) ~= nil)
                button:SetShown(show)
            end
        end
    end

    self._isApplying = false
end

function CurrencySearch:RefreshIfVisible()
    local root = self:GetRootFrame()
    if root and root:IsShown() then
        self:ApplyFilter()
    end
end

function CurrencySearch:SetEnabled(enabled)
    self.db.enabled = enabled and true or false

    if not self.db.enabled then
        self.currentQuery = ""
        if self.searchBox then
            self.searchBox:SetText("")
        end
    end

    self:RefreshIfVisible()

    if self.db.enabled then
        print("CurrencySearch: enabled")
    else
        print("CurrencySearch: disabled")
    end
end

function CurrencySearch:CreateSearchBox()
    if self.searchBox then
        return
    end

    local parent = self:GetRootFrame()
    if not parent then
        return
    end

    local searchBox = CreateFrame("EditBox", "CurrencySearchEditBox", parent, "SearchBoxTemplate")
    searchBox:SetSize(180, 20)
    searchBox:SetAutoFocus(false)
    searchBox:SetMaxLetters(20)

    if parent == TokenFrame then
        searchBox:SetPoint("TOPLEFT", TokenFrame, "TOPLEFT", 56, -32)
    else
        searchBox:SetPoint("TOPLEFT", parent, "TOPLEFT", 56, -32)
    end

    searchBox:HookScript("OnTextChanged", function(editBox, userInput)
        if not userInput then
            return
        end

        CurrencySearch.currentQuery = editBox:GetText() or ""
        CurrencySearch:ApplyFilter()
    end)

    searchBox:HookScript("OnEscapePressed", function(editBox)
        editBox:ClearFocus()
    end)

    local clearButton = searchBox.ClearButton
    if clearButton then
        clearButton:HookScript("OnClick", function()
            CurrencySearch.currentQuery = ""
            CurrencySearch:ApplyFilter()
        end)
    end

    self.searchBox = searchBox
    self.clearButton = clearButton

    if self.db and not self.db.enabled then
        searchBox:Hide()
    end
end

function CurrencySearch:UpdateSearchBoxVisibility()
    if not self.searchBox then
        return
    end

    if self.db and self.db.enabled then
        self.searchBox:Show()
    else
        self.searchBox:Hide()
    end
end

function CurrencySearch:InitializeSlashCommands()
    SLASH_CURRENCYSEARCH1 = "/cs"
    SlashCmdList.CURRENCYSEARCH = function(message)
        local cmd = lower(trim(message))

        if cmd == "" then
            print("CurrencySearch commands: /cs on, /cs off, /cs enable, /cs disable")
            return
        end

        if cmd == "on" or cmd == "enable" then
            CurrencySearch:SetEnabled(true)
            CurrencySearch:UpdateSearchBoxVisibility()
            return
        end

        if cmd == "off" or cmd == "disable" then
            CurrencySearch:SetEnabled(false)
            CurrencySearch:UpdateSearchBoxVisibility()
            return
        end

        print("CurrencySearch commands: /cs on, /cs off, /cs enable, /cs disable")
    end
end

function CurrencySearch:OnEvent(event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= ADDON_NAME then
            return
        end
        if CurrencySearchDB == nil then
            CurrencySearchDB = {}
        end

        if CurrencySearchDB.enabled == nil then
            CurrencySearchDB.enabled = true
        end

        self.db = CurrencySearchDB
        return
    end

    if event == "PLAYER_LOGIN" then
        self:CreateSearchBox()
        self:UpdateSearchBoxVisibility()
        self:InitializeSlashCommands()

        self:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
        self:RegisterEvent("PLAYER_MONEY")

        if TokenFrame then
            TokenFrame:HookScript("OnShow", function()
                CurrencySearch:CreateSearchBox()
                CurrencySearch:UpdateSearchBoxVisibility()
                CurrencySearch:RefreshIfVisible()
            end)
        end

        if CurrencyFrame then
            CurrencyFrame:HookScript("OnShow", function()
                CurrencySearch:CreateSearchBox()
                CurrencySearch:UpdateSearchBoxVisibility()
                CurrencySearch:RefreshIfVisible()
            end)
        end

        if TokenFrame_Update then
            hooksecurefunc("TokenFrame_Update", function()
                CurrencySearch:RefreshIfVisible()
            end)
        end

        return
    end

    if event == "CURRENCY_DISPLAY_UPDATE" or event == "PLAYER_MONEY" then
        self:RefreshIfVisible()
    end
end

CurrencySearch:SetScript("OnEvent", function(_, event, ...)
    CurrencySearch:OnEvent(event, ...)
end)

CurrencySearch:RegisterEvent("ADDON_LOADED")
CurrencySearch:RegisterEvent("PLAYER_LOGIN")
