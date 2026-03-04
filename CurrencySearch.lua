local CurrencySearch = CreateFrame("Frame", "CurrencySearchFrame")
CurrencySearch.query = ""
CurrencySearch.filteredIndices = {}
CurrencySearch.enabled = true
CurrencySearch.searchBox = nil
CurrencySearch.clearButton = nil

local originalGetCurrencyListSize = _G.GetCurrencyListSize
local originalGetCurrencyListInfo = _G.GetCurrencyListInfo

local function trim(text)
    return (text and text:match("^%s*(.-)%s*$")) or ""
end

function CurrencySearch:IsCurrencyFrameVisible()
    if _G.TokenFrame and _G.TokenFrame:IsShown() then
        return true
    end

    if _G.CurrencyFrame and _G.CurrencyFrame:IsShown() then
        return true
    end

    return false
end

function CurrencySearch:ShouldFilter()
    return self.enabled and self.query ~= "" and self:IsCurrencyFrameVisible()
end

function CurrencySearch:RebuildFilter()
    wipe(self.filteredIndices)

    if type(originalGetCurrencyListSize) ~= "function" or type(originalGetCurrencyListInfo) ~= "function" then
        return
    end

    local total = originalGetCurrencyListSize()
    if total <= 0 then
        return
    end

    if self.query == "" then
        for i = 1, total do
            self.filteredIndices[#self.filteredIndices + 1] = i
        end
        return
    end

    local loweredQuery = self.query:lower()
    local pendingHeader = nil
    local headerInserted = false

    for i = 1, total do
        local name, isHeader = originalGetCurrencyListInfo(i)

        if isHeader then
            pendingHeader = i
            headerInserted = false
        elseif type(name) == "string" and name:lower():find(loweredQuery, 1, true) then
            if pendingHeader and not headerInserted then
                self.filteredIndices[#self.filteredIndices + 1] = pendingHeader
                headerInserted = true
            end
            self.filteredIndices[#self.filteredIndices + 1] = i
        end
    end
end

function CurrencySearch:RefreshCurrencyFrame()
    if not self:IsCurrencyFrameVisible() then
        return
    end

    if type(_G.TokenFrame_Update) == "function" then
        _G.TokenFrame_Update()
        return
    end

    if _G.CurrencyFrame and type(_G.CurrencyFrame.Update) == "function" then
        _G.CurrencyFrame:Update()
    end
end

function CurrencySearch:SetQuery(text)
    self.query = trim(text):lower()
    self:RebuildFilter()
    self:RefreshCurrencyFrame()
end

function CurrencySearch:SetEnabled(enabled)
    self.enabled = enabled and true or false

    if not self.enabled then
        self.query = ""
        if self.searchBox then
            self.searchBox:SetText("")
        end
    end

    if self.searchBox then
        if self.enabled then
            self.searchBox:Enable()
        else
            self.searchBox:Disable()
            if self.clearButton then
                self.clearButton:Hide()
            end
        end
    end

    if CurrencySearchDB then
        CurrencySearchDB.enabled = self.enabled
    end

    self:RefreshCurrencyFrame()
end

function CurrencySearch:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99CurrencySearch|r: " .. msg)
end

function CurrencySearch:HandleSlashCommand(message)
    local cmd = trim((message or ""):lower())

    if cmd == "enable" or cmd == "on" then
        self:SetEnabled(true)
        self:Print("Enabled.")
    elseif cmd == "disable" or cmd == "off" then
        self:SetEnabled(false)
        self:Print("Disabled.")
    else
        self:Print("Usage: /cs on|off (or /cs enable|disable)")
    end
end

function CurrencySearch:CreateSearchUI()
    if self.searchBox then
        return
    end

    local parent = _G.TokenFrame or _G.CurrencyFrame
    if not parent then
        return
    end

    local editBox = CreateFrame("EditBox", "CurrencySearchEditBox", parent, "InputBoxTemplate")
    editBox:SetSize(180, 20)
    editBox:SetAutoFocus(false)
    editBox:SetMaxLetters(20)
    editBox:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -36, -30)
    editBox:SetScript("OnTextChanged", function(box)
        CurrencySearch:SetQuery(box:GetText() or "")
        if CurrencySearch.clearButton then
            if box:GetText() == "" then
                CurrencySearch.clearButton:Hide()
            else
                CurrencySearch.clearButton:Show()
            end
        end
    end)

    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("BOTTOMLEFT", editBox, "TOPLEFT", 2, 2)
    label:SetText("Search")

    local clear = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    clear:SetSize(20, 20)
    clear:SetPoint("LEFT", editBox, "RIGHT", 2, 0)
    clear:SetText("x")
    clear:SetScript("OnClick", function()
        editBox:SetText("")
        editBox:SetFocus()
    end)
    clear:Hide()

    self.searchBox = editBox
    self.clearButton = clear

    if not self.enabled then
        editBox:Disable()
        clear:Hide()
    end
end

function CurrencySearch:TryInstallFilterHooks()
    if type(originalGetCurrencyListSize) ~= "function" or type(originalGetCurrencyListInfo) ~= "function" then
        return
    end

    if self.hooksInstalled then
        return
    end

    _G.GetCurrencyListSize = function(...)
        if CurrencySearch:ShouldFilter() then
            CurrencySearch:RebuildFilter()
            return #CurrencySearch.filteredIndices
        end
        return originalGetCurrencyListSize(...)
    end

    _G.GetCurrencyListInfo = function(index, ...)
        if CurrencySearch:ShouldFilter() and type(index) == "number" then
            CurrencySearch:RebuildFilter()
            local mappedIndex = CurrencySearch.filteredIndices[index]
            if not mappedIndex then
                return nil
            end
            return originalGetCurrencyListInfo(mappedIndex, ...)
        end
        return originalGetCurrencyListInfo(index, ...)
    end

    self.hooksInstalled = true
end

CurrencySearch:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        CurrencySearchDB = CurrencySearchDB or {}
        if CurrencySearchDB.enabled == nil then
            CurrencySearchDB.enabled = true
        end

        CurrencySearch.enabled = CurrencySearchDB.enabled
        CurrencySearch:TryInstallFilterHooks()

        SLASH_CURRENCYSEARCH1 = "/cs"
        SlashCmdList.CURRENCYSEARCH = function(message)
            CurrencySearch:HandleSlashCommand(message)
        end

        CurrencySearch:CreateSearchUI()
    elseif event == "PLAYER_ENTERING_WORLD" then
        CurrencySearch:CreateSearchUI()
    elseif event == "CURRENCY_DISPLAY_UPDATE" or event == "TOKEN_FRAME_UPDATE" then
        CurrencySearch:RebuildFilter()
    end
end)

CurrencySearch:RegisterEvent("PLAYER_LOGIN")
CurrencySearch:RegisterEvent("PLAYER_ENTERING_WORLD")
CurrencySearch:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
CurrencySearch:RegisterEvent("TOKEN_FRAME_UPDATE")
