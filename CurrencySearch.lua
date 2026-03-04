local ADDON_NAME = ...

local CurrencySearch = CreateFrame("Frame")
CurrencySearch.query = ""
CurrencySearch.editBox = nil
CurrencySearch.initializedUI = false

local function getDB()
    CurrencySearchDB = CurrencySearchDB or {}
    if CurrencySearchDB.enabled == nil then
        CurrencySearchDB.enabled = true
    end
    return CurrencySearchDB
end

local function isEnabled()
    return getDB().enabled ~= false
end

local function normalize(text)
    if not text then
        return ""
    end

    return string.lower(strtrim(text))
end

local function getCurrencyContainer()
    if TokenFrameContainer then
        return TokenFrameContainer
    end

    if TokenFrame and TokenFrame.Container then
        return TokenFrame.Container
    end

    if CurrencyFrame and CurrencyFrame.Container then
        return CurrencyFrame.Container
    end
end

local function getCurrencyButtons()
    local container = getCurrencyContainer()
    if container and container.buttons then
        return container.buttons, container
    end

    if TokenFrame and TokenFrame.buttons then
        return TokenFrame.buttons, TokenFrame
    end
end

local function getCurrencyNameFromButton(button)
    if not button then
        return nil
    end

    if button.index and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyListInfo then
        local info = C_CurrencyInfo.GetCurrencyListInfo(button.index)
        if info and info.name then
            return info.name
        end
    end

    if button.CurrencyName and button.CurrencyName.GetText then
        return button.CurrencyName:GetText()
    end

    if button.name and button.name.GetText then
        return button.name:GetText()
    end
end

local function requestCurrencyRefresh()
    if TokenFrame_Update then
        TokenFrame_Update()
        return
    end

    if CurrencyFrame and CurrencyFrame.Update then
        CurrencyFrame:Update()
        return
    end

    local buttons = getCurrencyButtons()
    if buttons then
        for _, button in ipairs(buttons) do
            if button.Update then
                button:Update()
            end
        end
    end
end

local function applyFilterToVisibleButtons()
    if not isEnabled() then
        return
    end

    local buttons, container = getCurrencyButtons()
    if not buttons or not container then
        return
    end

    local filter = CurrencySearch.query
    if filter == "" then
        return
    end

    local previousShown = nil

    for _, button in ipairs(buttons) do
        local name = getCurrencyNameFromButton(button)
        local shouldShow = name and string.find(string.lower(name), filter, 1, true)

        if shouldShow then
            button:Show()
            button:ClearAllPoints()

            if previousShown then
                button:SetPoint("TOPLEFT", previousShown, "BOTTOMLEFT", 0, -1)
                button:SetPoint("TOPRIGHT", previousShown, "BOTTOMRIGHT", 0, -1)
            else
                button:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
                button:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, 0)
            end

            previousShown = button
        else
            button:Hide()
        end
    end
end

local function updateFilterText(text)
    if not isEnabled() then
        CurrencySearch.query = ""
        return
    end

    CurrencySearch.query = normalize(text)
    requestCurrencyRefresh()
end

local function findSearchParent()
    if TokenFrame then
        return TokenFrame
    end

    if CharacterFrame and CharacterFrame.TokenFrame then
        return CharacterFrame.TokenFrame
    end

    if CurrencyFrame then
        return CurrencyFrame
    end
end

local function updateSearchVisibility()
    if not CurrencySearch.editBox then
        return
    end

    if isEnabled() then
        CurrencySearch.editBox:Show()
    else
        CurrencySearch.editBox:SetText("")
        CurrencySearch.editBox:Hide()
    end

    requestCurrencyRefresh()
end

local function createSearchBox()
    if CurrencySearch.editBox then
        return true
    end

    local parent = findSearchParent()
    if not parent then
        return false
    end

    local box = CreateFrame("EditBox", "CurrencySearchInput", parent, "SearchBoxTemplate")
    box:SetSize(180, 20)
    box:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -30, -28)
    box:SetAutoFocus(false)
    box:SetMaxLetters(20)
    SearchBoxTemplate_OnLoad(box)
    box.Instructions:SetText("Search currencies")

    box:SetScript("OnTextChanged", function(self, userInput)
        SearchBoxTemplate_OnTextChanged(self)

        updateFilterText(self:GetText())
    end)

    box:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    CurrencySearch.editBox = box
    updateSearchVisibility()
    return true
end

local function tryInitializeUI()
    if CurrencySearch.initializedUI then
        return
    end

    if not createSearchBox() then
        return
    end

    if TokenFrame and TokenFrame:HasScript("OnShow") then
        TokenFrame:HookScript("OnShow", function()
            updateSearchVisibility()
            requestCurrencyRefresh()
        end)
    end

    if TokenFrame_Update then
        hooksecurefunc("TokenFrame_Update", applyFilterToVisibleButtons)
    elseif CurrencyFrame and CurrencyFrame.Update then
        hooksecurefunc(CurrencyFrame, "Update", applyFilterToVisibleButtons)
    end

    CurrencySearch.initializedUI = true
end

local function printStatus(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff7fd5ffCurrencySearch:|r " .. message)
    else
        print("CurrencySearch: " .. message)
    end
end

local function setEnabled(enabled)
    getDB().enabled = enabled and true or false

    if not enabled then
        CurrencySearch.query = ""
    end

    updateSearchVisibility()

    if enabled then
        printStatus("enabled")
    else
        printStatus("disabled")
    end
end

local function handleSlashCommand(msg)
    local command = normalize(msg)

    if command == "" then
        printStatus("Usage: /cs on, /cs off, /cs enable, /cs disable")
        return
    end

    if command == "on" or command == "enable" then
        setEnabled(true)
        return
    end

    if command == "off" or command == "disable" then
        setEnabled(false)
        return
    end

    printStatus("Unknown command '" .. command .. "'. Use on/off or enable/disable.")
end

SLASH_CURRENCYSEARCH1 = "/cs"
SlashCmdList.CURRENCYSEARCH = handleSlashCommand

CurrencySearch:RegisterEvent("ADDON_LOADED")
CurrencySearch:RegisterEvent("PLAYER_LOGIN")

CurrencySearch:SetScript("OnEvent", function(_, event, addon)
    if event == "ADDON_LOADED" and addon == ADDON_NAME then
        getDB()
        return
    end

    if event == "PLAYER_LOGIN" then
        tryInitializeUI()

        if CharacterFrame then
            CharacterFrame:HookScript("OnShow", tryInitializeUI)
        end

        CurrencySearch:RegisterEvent("PLAYER_ENTERING_WORLD")
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        tryInitializeUI()
        requestCurrencyRefresh()
    end
end)
