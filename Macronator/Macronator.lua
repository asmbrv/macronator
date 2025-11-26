-- Macronator

local function setbody(index, body)
    if InCombatLockdown() then return end
    local button = _G["ExtraMacros"..index] or CreateFrame("Button", "ExtraMacros"..index, nil, "SecureActionButtonTemplate")
    button:SetAttribute("type", "macro")
    button:SetAttribute("macrotext", body)
end

local function new()
    if InCombatLockdown() then return end

    local index = 1

    if MacroPopupFrame.mode == "new" then
        index = CreateMacro(MacroPopupEditBox:GetText(), MacroPopupFrame.selectedIcon, nil, MacroFrame.macroBase > 0)

        local global, perchar = GetNumMacros()

        if MacroFrame.macroBase == 0 then
            for i = global - 1, index, -1 do
                StoredMacros[i + 1] = StoredMacros[i]
            end
            StoredMacros[index] = nil
        else
            for i = perchar + 36 - 1, index, -1 do
                StoredMacrosPerCharacter[i + 1] = StoredMacrosPerCharacter[i]
            end
            StoredMacrosPerCharacter[index] = nil
        end

    elseif MacroPopupFrame.mode == "edit" then
        index = EditMacro(MacroFrame.selectedMacro, MacroPopupEditBox:GetText(), MacroPopupFrame.selectedIcon)
    end

    MacroPopupFrame:Hide()
    MacroFrame_SelectMacro(index)
    MacroFrame_Update()
end

local function save()
    if InCombatLockdown() then return end

    if MacroFrame.textChanged and MacroFrame.selectedMacro then
        local body = MacroFrameText:GetText()

        if body:len() < 256 then
            if MacroFrame.macroBase == 0 then
                StoredMacros[MacroFrame.selectedMacro] = nil
            else
                StoredMacrosPerCharacter[MacroFrame.selectedMacro] = nil
            end

            EditMacro(MacroFrame.selectedMacro, nil, nil, body)

        else
            if MacroFrame.macroBase == 0 then
                StoredMacros[MacroFrame.selectedMacro] = body
            else
                StoredMacrosPerCharacter[MacroFrame.selectedMacro] = body
            end

            EditMacro(MacroFrame.selectedMacro, nil, nil, "/click ExtraMacros"..MacroFrame.selectedMacro)
            setbody(MacroFrame.selectedMacro, body)
        end

        MacroFrame.textChanged = nil
    end
end

local function delete()
    if InCombatLockdown() then return end

    local selectedMacro = MacroFrame.selectedMacro
    local global, perchar = GetNumMacros()

    DeleteMacro(selectedMacro)

    if MacroFrame.macroBase == 0 then
        for i = selectedMacro, 35 do
            StoredMacros[i] = StoredMacros[i + 1]
            if StoredMacros[i] then
                EditMacro(i, nil, nil, "/click ExtraMacros"..i)
            end
        end
        StoredMacros[global] = nil

    else
        for i = selectedMacro, 71 do
            StoredMacrosPerCharacter[i] = StoredMacrosPerCharacter[i + 1]
            if StoredMacrosPerCharacter[i] then
                EditMacro(i, nil, nil, "/click ExtraMacros"..i)
            end
        end
        StoredMacrosPerCharacter[perchar] = nil
    end

    local numMacros = select(PanelTemplates_GetSelectedTab(MacroFrame), GetNumMacros())

    if selectedMacro > numMacros + MacroFrame.macroBase then
        selectedMacro = selectedMacro - 1
    end

    if selectedMacro <= MacroFrame.macroBase then
        MacroFrame.selectedMacro = nil
    else
        MacroFrame.selectedMacro = selectedMacro
    end

    MacroFrame_Update()
    MacroFrameText:ClearFocus()
end

local function update()
    local numMacros
    local numAccountMacros, numCharacterMacros = GetNumMacros()
    local macroButton, macroIcon, macroName
    local name, texture, body

    if MacroFrame.macroBase == 0 then
        numMacros = numAccountMacros
    else
        numMacros = numCharacterMacros
    end

    local maxMacroButtons = max(MAX_ACCOUNT_MACROS, MAX_CHARACTER_MACROS)

    for i = 1, maxMacroButtons do
        macroButton = _G["MacroButton"..i]
        macroIcon = _G["MacroButton"..i.."Icon"]
        macroName = _G["MacroButton"..i.."Name"]

        if i <= MacroFrame.macroMax then
            if i <= numMacros then
                name, texture, body = GetMacroInfo(MacroFrame.macroBase + i)
                body = MacroFrame.macroBase == 0 and StoredMacros[i] or MacroFrame.macroBase == 36 and StoredMacrosPerCharacter[36 + i] or body

                macroIcon:SetTexture(texture)
                macroName:SetText(name)
                macroButton:Enable()

                if MacroFrame.selectedMacro and i == (MacroFrame.selectedMacro - MacroFrame.macroBase) then
                    macroButton:SetChecked(1)
                    MacroFrameSelectedMacroName:SetText(name)
                    MacroFrameText:SetText(body)
                    MacroFrameSelectedMacroButton:SetID(i)
                    MacroFrameSelectedMacroButtonIcon:SetTexture(texture)
                    MacroPopupFrame.selectedIconTexture = texture
                else
                    macroButton:SetChecked(0)
                end

            else
                macroButton:SetChecked(0)
                macroIcon:SetTexture("")
                macroName:SetText("")
                macroButton:Disable()
            end

            macroButton:Show()

        else
            macroButton:Hide()
        end
    end

    if MacroFrame.selectedMacro then
        MacroFrame_ShowDetails()
        MacroDeleteButton:Enable()
    else
        MacroFrame_HideDetails()
        MacroDeleteButton:Disable()
    end

    if numMacros < MacroFrame.macroMax then
        MacroNewButton:Enable()
    else
        MacroNewButton:Disable()
    end

    if MacroPopupFrame:IsShown() then
        MacroEditButton:Disable()
        MacroDeleteButton:Disable()
    else
        MacroEditButton:Enable()
        MacroDeleteButton:Enable()
    end

    if not MacroFrame.selectedMacro then
        MacroDeleteButton:Disable()
    end
end

local holder = CreateFrame("Frame")
holder:RegisterEvent("ADDON_LOADED")

holder:SetScript("OnEvent", function(self, event, addon)
    if addon == "Macronator" then

        StoredMacros = StoredMacros or {}
        StoredMacrosPerCharacter = StoredMacrosPerCharacter or {}

        for index, body in pairs(StoredMacros) do
            setbody(index, body)
        end

        for index, body in pairs(StoredMacrosPerCharacter) do
            setbody(index, body)
        end

    elseif addon == "Blizzard_MacroUI" then

        MacroFrameText:SetMaxLetters(1024)
        MACROFRAME_CHAR_LIMIT = MACROFRAME_CHAR_LIMIT:gsub("%d+", "1024")

        MacroFrame_SaveMacro = save
        MacroFrame_DeleteMacro = delete
        MacroFrame_Update = update
        MacroPopupOkayButton_OnClick = new
    end
end)
