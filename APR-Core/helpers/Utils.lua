local L = LibStub("AceLocale-3.0"):GetLocale("APR")

--[[
Return a string with surrounding stars

TextWithStars("hello")          -- "\*\* hello \*\*"

TextWithStars("hello", 3)       -- "\*\*\* hello \*\*\*"

TextWithStars("hello", 4, true) -- "\*\*\*\* hello"

TextWithStars("hello", 0)       -- "hello"
]]
function TextWithStars(text, count, onlyLeft)
    count = count or 2;

    if count < 1 then
        return text;
    end

    onlyLeft = onlyLeft or false;

    local stars = string.rep("*", count);

    if onlyLeft then
        return stars .. " " .. text;
    end

    return stars .. " " .. text .. " " .. stars;
end

function CheckRidingSkill(skillID)
    local mountSkillIDs = { 90265, 34090, 33391, 33388 }
    for _, skill in pairs(mountSkillIDs) do
        if (GetSpellBookItemInfo(GetSpellInfo(skill))) then
            return true
        elseif (skill == skillID) then
            return GetSpellBookItemInfo(GetSpellInfo(skillID))
        end
    end
end

function GetTargetID(unit)
    unit = unit or "target"
    local targetGUID = UnitGUID(unit)
    if targetGUID then
        local targetID = select(6, strsplit("-", targetGUID))
        return tonumber(targetID)
    end
    return nil
end

function CheckDenyNPC(steps)
    if (steps and steps.DenyNPC) then
        local npc_id, name = GetTargetID(), UnitName("target")
        if (npc_id and name) then
            if (npc_id == steps.DenyNPC) then
                C_GossipInfo.CloseGossip()
                C_Timer.After(0.3, APR_CloseQuest)
                print("APR: " .. L["NOT_YET"])
            end
        end
    end
end

--- Contain data in list
---@param list array list
---@param x object object to check if in the list
---@return true|false Boolean
function Contains(list, x)
    if list then
        for _, v in pairs(list) do
            if v == x then return true end
        end
    end
    return false
end

function IsTableEmpty(table)
    if (table) then
        return next(table) == nil
    end
    return false
end

-- //TODO: Remove this shit
function PairsByKeys(t, f)
    local a = {}
    for n in pairs(t) do table.insert(a, n) end
    table.sort(a, f)
    local i = 0
    local iter = function()
        i = i + 1
        if a[i] == nil then
            return nil
        else
            return a[i], t[a[i]]
        end
    end
    return iter
end

function APR_AcceptQuest()
    AcceptQuest()
end

function APR_CloseQuest()
    CloseQuest()
end

function TrimPlayerServer(CLPName)
    local CL_First = string.match(CLPName, "^(.-)-")
    return CL_First or CLPName
end

function SplitQuestAndObjective(questID)
    local id, objective = questID:match("([^%-]+)%-([^%-]+)")
    if id and objective then
        return tonumber(id), tonumber(objective)
    end
    return tonumber(questID)
end

--- Display error in chat
--- @param errorMessage string
function APR:PrintError(errorMessage)
    if (errorMessage and type(errorMessage) == "string") then
        local redColorCode = "|cffff0000"
        DEFAULT_CHAT_FRAME:AddMessage(redColorCode .. L["ERROR"] .. ": " .. errorMessage .. "|r")
    end
end

--- Display info in chat
--- @param infoMessage string
function APR:PrintInfo(infoMessage)
    if (infoMessage and type(infoMessage) == "string") then
        local lightBlueColorCode = "|cff00bfff"
        DEFAULT_CHAT_FRAME:AddMessage(lightBlueColorCode .. "APR: " .. infoMessage .. "|r")
    end
end

function APR:Love()
    local currentDate = C_DateAndTime.GetCurrentCalendarTime()
    if currentDate.month == 2 and currentDate.monthDay == 14 then
        APR.Color.blue = APR.Color.pink
        APR.Color.yellow = APR.Color.pink
    end
end

function APR:IsInInstanceQuest()
    local steps = APR.ActiveRoute and GetSteps(APRData[APR.PlayerID][APR.ActiveRoute]) or nil
    local isIntance, type = IsInInstance()
    if steps and steps.InstanceQuest then
        return isIntance and type == "scenario"
    end
    return not isIntance
end

function APR:getStatus()
    APR.settings:CloseSettings()
    APR:showStatusReport()
end

-- Convert a lua table into a lua syntactically correct string
function APR:tableToString(table, skipKey)
    local result = "{"
    for k, v in pairs(table) do
        if not skipKey then
            -- Check the key type (ignore any numerical keys - assume its an array)
            if type(k) == "string" then
                result = result .. "[\"" .. k .. "\"]" .. "="
            end
        end
        -- Check the value type
        if type(v) == "table" then
            result = result .. APR:tableToString(v)
        elseif type(v) == "boolean" then
            result = result .. tostring(v)
        else
            result = result .. "\"" .. v .. "\""
        end
        result = result .. ","
    end
    -- Remove leading commas from the result
    if result ~= "" then
        result = result:sub(1, result:len() - 1)
    end
    return result .. "}"
end

function APR:IsMoPRemixCharacter()
    local aura = C_UnitAuras.GetPlayerAuraBySpellID(424143)
    return aura ~= nil
end
