-- TotemSwap.lua (Turtle WoW 1.12) - GCD-based + Configurable totem modes
-- Options: Rage/Stonebreaker pour Shocks, Storm/Crackling pour Bolts

local GetContainerNumSlots  = GetContainerNumSlots
local GetContainerItemLink  = GetContainerItemLink
local UseContainerItem      = UseContainerItem
local GetInventoryItemLink  = GetInventoryItemLink
local GetSpellName          = GetSpellName
local GetSpellCooldown      = GetSpellCooldown
local GetActionText         = GetActionText
local GetTime               = GetTime
local string_find           = string.find
local BOOKTYPE_SPELL        = BOOKTYPE_SPELL or "spell"

local NameIndex   = {}
local SpellCache = {}

local lastSwapTime = 0

local function IsInteractionBusy()
    return (MerchantFrame and MerchantFrame:IsVisible())
        or (BankFrame and BankFrame:IsVisible())
        or (AuctionFrame and AuctionFrame:IsVisible())
        or (TradeFrame and TradeFrame:IsVisible())
        or (MailFrame and MailFrame:IsVisible())
        or (QuestFrame and QuestFrame:IsVisible())
        or (GossipFrame and GossipFrame:IsVisible())
end

local lastEquippedTotem = nil

-- Config SavedVariables avec modes configurables
TotemSwapDb = TotemSwapDb or { 
    enabled = true, 
    spam = true,
    -- Modes pour choix de totems prioritaires
    shockMode = "rage",        -- "rage" ou "stonebreaker"
    boltMode = "storm"         -- "storm" ou "crackling"
}

-- GCD global uniquement
local GCD_THROTTLE = 1.5

-- Noms des totems
local TOTEM_RAGE = "Totem of Rage"
local TOTEM_STONEBREAKER = "Totem of the Stonebreaker"
local TOTEM_STORM = "Totem of the Storm"
local TOTEM_CRACKLING = "Totem of Crackling Thunder"
local TOTEM_ERUPTION = "Totem of Eruption"

local WatchedNames = {
    [TOTEM_RAGE] = true,
    [TOTEM_STONEBREAKER] = true,
    [TOTEM_STORM] = true,
    [TOTEM_CRACKLING] = true,
    [TOTEM_ERUPTION] = true
}

local function ItemIDFromLink(link)
    if not link then return nil end
    local _, _, id = string_find(link, "item:(%d+)")
    return id and tonumber(id) or nil
end

local function BuildBagIndex()
    for k in pairs(NameIndex) do NameIndex[k] = nil end
    for bag = 0, 4 do
        local slots = GetContainerNumSlots(bag)
        if slots and slots > 0 then
            for slot = 1, slots do
                local link = GetContainerItemLink(bag, slot)
                if link then
                    local _, _, bracketName = string_find(link, "%[(.-)%]")
                    if bracketName and WatchedNames[bracketName] then
                        NameIndex[bracketName] = { bag = bag, slot = slot, link = link }
                    end
                end
            end
        end
    end
end

local TotemSwapFrame = CreateFrame("Frame")
TotemSwapFrame:RegisterEvent("PLAYER_LOGIN")
TotemSwapFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
TotemSwapFrame:RegisterEvent("BAG_UPDATE")

TotemSwapFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        BuildBagIndex()
    elseif event == "BAG_UPDATE" then
        BuildBagIndex()
    end
end)

local SPELL_READY_ALLOWANCE = 0.15

local function SplitNameAndRank(spellSpec)
    if not spellSpec then return nil, nil end
    local _, _, base, rnum = string_find(spellSpec, "^(.-)%s*%(%s*[Rr][Aa][Nn][Kk]%s*(%d+)%s*%)%s*$")
    if base then return (string.gsub(base, "%s+$", "")), ("Rank " .. rnum) end
    return (string.gsub(spellSpec, "%s+$", "")), nil
end

local function IsSpellReadyById(spellId)
    local start, duration, enabled = GetSpellCooldown(spellId, BOOKTYPE_SPELL)
    if not (start and duration) or enabled == 0 then return false end
    if start == 0 or duration == 0 then return true end
    local remaining = (start + duration) - GetTime()
    return remaining <= SPELL_READY_ALLOWANCE
end

local function IsSpellReady(spellSpec)
    local spellId = SpellCache[spellSpec]
    if not spellId then
        local base, reqRank = SplitNameAndRank(spellSpec)
        if not base then return false end
        for i = 1, 300 do
            local name, rank = GetSpellName(i, BOOKTYPE_SPELL)
            if not name then break end
            local nameMatches = (name == base)
            local rankMatches = (not reqRank) or (rank and rank == reqRank)
            if nameMatches and rankMatches then
                spellId = i
                SpellCache[spellSpec] = i
                break
            end
        end
    end
    if not spellId then return false end
    return IsSpellReadyById(spellId)
end

local function HasItemInBags(itemName)
    local ref = NameIndex[itemName]
    if ref then
        local current = GetContainerItemLink(ref.bag, ref.slot)
        if current and string_find(current, itemName, 1, true) then return ref.bag, ref.slot end
        BuildBagIndex()
        ref = NameIndex[itemName]
        if ref then
            local verify = GetContainerItemLink(ref.bag, ref.slot)
            if verify and string_find(verify, itemName, 1, true) then return ref.bag, ref.slot end
        end
        return nil
    end
    for bag = 0, 4 do
        local slots = GetContainerNumSlots(bag)
        if slots > 0 then
            for slot = 1, slots do
                local link = GetContainerItemLink(bag, slot)
                if link and string.find(link, itemName, 1, true) then
                    NameIndex[itemName] = { bag = bag, slot = slot, link = link }
                    return bag, slot
                end
            end
        end
    end
    return nil
end

local function HasTotem(totemName)
    local equipped = GetInventoryItemLink("player", 17)
    return (lastEquippedTotem == totemName) or 
           (equipped and string_find(equipped, totemName, 1, true)) or 
           HasItemInBags(totemName)
end

local function GetGCDRemaining()
    local start, duration, enabled = GetSpellCooldown(61304, BOOKTYPE_SPELL)
    if not (start and duration) or enabled == 0 or duration == 0 then return 0 end
    local remaining = (start + duration) - GetTime()
    return math.max(0, remaining)
end

-- NOUVEAU: Résout le totem selon le mode config et la disponibilité
local function ResolveTotemForSpell(spellName)
    if spellName == "Molten Blast" then
        return TOTEM_ERUPTION
    elseif spellName == "Lightning Strike" then 
        return TOTEM_CRACKLING
    elseif spellName == "Earth Shock" or spellName == "Flame Shock" or spellName == "Frost Shock" then
        -- Shock mode: priorité selon config, fallback à l'autre
        if TotemSwapDb.shockMode == "stonebreaker" then
            if HasTotem(TOTEM_STONEBREAKER) then return TOTEM_STONEBREAKER end
            if HasTotem(TOTEM_RAGE) then return TOTEM_RAGE end
        else
            if HasTotem(TOTEM_RAGE) then return TOTEM_RAGE end
            if HasTotem(TOTEM_STONEBREAKER) then return TOTEM_STONEBREAKER end
        end
    elseif spellName == "Lightning Bolt" or spellName == "Chain Lightning" then
        -- Bolt mode: priorité selon config, fallback à l'autre
        if TotemSwapDb.boltMode == "crackling" then
            if HasTotem(TOTEM_CRACKLING) then return TOTEM_CRACKLING end
            if HasTotem(TOTEM_STORM) then return TOTEM_STORM end
        else
            if HasTotem(TOTEM_STORM) then return TOTEM_STORM end
            if HasTotem(TOTEM_CRACKLING) then return TOTEM_CRACKLING end
        end
    end
    return nil
end

local function EquipTotemForSpell(spellName, totemName)
    local equipped = GetInventoryItemLink("player", 17)
    if equipped and string_find(equipped, totemName, 1, true) then
        lastEquippedTotem = totemName
        return false
    end

    if IsInteractionBusy() then return false end

    local now = GetTime()
    if lastSwapTime and (now - lastSwapTime) < 1.5 then 
        return false 
    end
    lastSwapTime = now  -- Met à jour APRÈS validation

    local bag, slot = HasItemInBags(totemName)
    if bag and slot and not (CursorHasItem and CursorHasItem()) then
        UseContainerItem(bag, slot)
        lastEquippedTotem = totemName
        if TotemSwapDb.spam then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFAAAAFF[TotemSwap]:|r Équipé |cFFFFD700" .. totemName .. "|r (|cFF88FF88" .. spellName .. "|r)")
        end
        return true
    end
    return false
end

local hiddenActionTooltip = CreateFrame("GameTooltip", "TotemSwapActionTooltip", UIParent, "GameTooltipTemplate")
local function GetActionSpellName(slot)
    hiddenActionTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    hiddenActionTooltip:SetAction(slot)
    local name = TotemSwapActionTooltipTextLeft1:GetText()
    local rank = TotemSwapActionTooltipTextRight1:GetText()
    hiddenActionTooltip:Hide()
    return name, rank
end

-- Hooks
local Original_CastSpellByName = CastSpellByName
local Original_CastSpell = CastSpell
local Original_UseAction = UseAction

local function HandleSpellCast(base, rank, spellId)
    if not TotemSwapDb.enabled or not base then return end
    
    local totem = ResolveTotemForSpell(base)
    if not totem then return end

    local ready = spellId and IsSpellReadyById(spellId) or IsSpellReady((rank and rank ~= "") and (base .. "(" .. rank .. ")") or base)
    if not ready then return end

    EquipTotemForSpell(base, totem)
end

function CastSpellByName(spellName, bookType)
    local name, rank = SplitNameAndRank(spellName)
    HandleSpellCast(name, rank)
    return Original_CastSpellByName(spellName, bookType)
end

function CastSpell(spellIndex, bookType)
    if bookType ~= BOOKTYPE_SPELL then return Original_CastSpell(spellIndex, bookType) end
    local name, rank = GetSpellName(spellIndex, BOOKTYPE_SPELL)
    HandleSpellCast(name, rank, spellIndex)
    return Original_CastSpell(spellIndex, bookType)
end

function UseAction(slot, checkCursor, onSelf)
    if GetActionText(slot) then return Original_UseAction(slot, checkCursor, onSelf) end
    local name, rank = GetActionSpellName(slot)
    HandleSpellCast(name, rank)
    return Original_UseAction(slot, checkCursor, onSelf)
end

-- NOUVELLES commandes slash pour config
local function HandleTotemSwapCommand(msg)
    msg = string.lower(msg or "")
    local _, _, cmd, arg = string_find(msg, "^(%S+)%s*(.-)$")
    cmd = cmd or ""
    arg = string.lower(arg or "")

    if cmd == "on" then
        TotemSwapDb.enabled = true
        DEFAULT_CHAT_FRAME:AddMessage("|cFFAAAAFF[TotemSwap]:|r |cFF00FF00ACTIVÉ|r")
    elseif cmd == "off" then
        TotemSwapDb.enabled = false
        DEFAULT_CHAT_FRAME:AddMessage("|cFFAAAAFF[TotemSwap]:|r |cFFFF0000DÉSACTIVÉ|r")
    elseif cmd == "spam" then
        TotemSwapDb.spam = not TotemSwapDb.spam
        local status = TotemSwapDb.spam and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"
        DEFAULT_CHAT_FRAME:AddMessage("|cFFAAAAFF[TotemSwap]:|r Messages: " .. status)
        
    -- NOUVEAU: Shock mode
    elseif cmd == "shock" or cmd == "shocks" then
        if arg == "stonebreaker" or arg == "sb" or arg == "stone" then
            TotemSwapDb.shockMode = "stonebreaker"
            DEFAULT_CHAT_FRAME:AddMessage("|cFFAAAAFF[TotemSwap]:|r Shocks → |cFFFFD700" .. TOTEM_STONEBREAKER .. "|r (priorité)")
        elseif arg == "rage" or arg == "r" then
            TotemSwapDb.shockMode = "rage"
            DEFAULT_CHAT_FRAME:AddMessage("|cFFAAAAFF[TotemSwap]:|r Shocks → |cFFFFD700" .. TOTEM_RAGE .. "|r (priorité)")
        else
            local current = (TotemSwapDb.shockMode == "stonebreaker") and TOTEM_STONEBREAKER or TOTEM_RAGE
            DEFAULT_CHAT_FRAME:AddMessage("|cFFAAAAFF[TotemSwap]:|r Shocks: |cFFFFD700" .. current .. "|r |cFF888888(/ts shock [rage/stonebreaker])|r")
        end
        
    -- NOUVEAU: Bolt mode
    elseif cmd == "bolt" or cmd == "bolts" then
        if arg == "crackling" or arg == "crack" or arg == "c" then
            TotemSwapDb.boltMode = "crackling"
            DEFAULT_CHAT_FRAME:AddMessage("|cFFAAAAFF[TotemSwap]:|r Bolts → |cFFFFD700" .. TOTEM_CRACKLING .. "|r (priorité)")
        elseif arg == "storm" or arg == "s" then
            TotemSwapDb.boltMode = "storm"
            DEFAULT_CHAT_FRAME:AddMessage("|cFFAAAAFF[TotemSwap]:|r Bolts → |cFFFFD700" .. TOTEM_STORM .. "|r (priorité)")
        else
            local current = (TotemSwapDb.boltMode == "crackling") and TOTEM_CRACKLING or TOTEM_STORM
            DEFAULT_CHAT_FRAME:AddMessage("|cFFAAAAFF[TotemSwap]:|r Bolts: |cFFFFD700" .. current .. "|r |cFF888888(/ts bolt [storm/crackling])|r")
        end

    elseif cmd == "status" or cmd == "gcd" then
        local status = TotemSwapDb.enabled and "|cFF00FF00ACTIVÉ|r" or "|cFFFF0000DÉSACTIVÉ|r"
        local now = GetTime()
        local timeSinceSwap = now - (lastSwapTime or 0)
        local shock = (TotemSwapDb.shockMode == "stonebreaker") and TOTEM_STONEBREAKER or TOTEM_RAGE
        local bolt = (TotemSwapDb.boltMode == "crackling") and TOTEM_CRACKLING or TOTEM_STORM
        DEFAULT_CHAT_FRAME:AddMessage("|cFFAAAAFF[TotemSwap]:|r " .. status)
        DEFAULT_CHAT_FRAME:AddMessage("  Shocks: |cFFFFD700" .. shock .. "|r  | Bolts: |cFFFFD700" .. bolt .. "|r  |cFF888888(" .. string.format("%.1fs depuis dernier swap)|r"))

    elseif cmd == "" then
        TotemSwapDb.enabled = not TotemSwapDb.enabled
        local status = TotemSwapDb.enabled and "|cFF00FF00ACTIVÉ|r" or "|cFFFF0000DÉSACTIVÉ|r"
        DEFAULT_CHAT_FRAME:AddMessage("|cFFAAAAFF[TotemSwap]:|r " .. status)
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFAAAAFF[TotemSwap]:|r /ts [on/off/spam/status/shock/bolt] ou /totemswap")
    end
end

SLASH_TOTEMSWAP1 = "/totemswap"
SLASH_TOTEMSWAP2 = "/ts"
SlashCmdList["TOTEMSWAP"] = HandleTotemSwapCommand
