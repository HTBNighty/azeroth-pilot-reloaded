local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")

function GetStepString(step)
    local stepMappings = {
        ExitTutorial = L["SKIP_TUTORIAL"],
        PickUp = L["PICK_UP_Q"],
        DropQuest = L["Q_DROP"],
        Qpart = L["Q_PART"],
        Treasure = L["GET_TREASURE"],
        Group = L["GROUP_Q"],
        Done = L["TURN_IN_Q"],
        Waypoint = L["RUN_WAYPOINT"],
        SetHS = L["SET_HEARTHSTONE"],
        UseHS = L["USE_HEARTHSTONE"],
        UseDalaHS = L["USE_DALARAN_HEARTHSTONE"],
        UseGarrisonHS = L["USE_GARRISON_HEARTHSTONE"],
        GetFP = L["GET_FLIGHTPATH"],
        UseFlightPath = L["USE_FLIGHTPATH"],
        WarMode = L["TURN_ON_WARMODE"],
        ZoneDoneSave = L["ROUTE_COMPLETED"]
    }

    for key, _ in pairs(step) do
        if stepMappings[key] then
            return stepMappings[key], key
        end
    end

    return ''
end

function HasAchievement(achievementID)
    local id, name, _, completed = _G.GetAchievementInfo(achievementID)
    return completed
end

function HasAura(spellID)
    local aura = C_UnitAuras.GetPlayerAuraBySpellID(spellID)
    return aura ~= nil
end

function UpdateQuestAndStep()
    APR.BookingList["UpdateQuest"] = true
    APR.BookingList["UpdateStep"] = true
end

function UpdateNextQuest()
    APRData[APR.PlayerID][APR.ActiveRoute] = APRData[APR.PlayerID][APR.ActiveRoute] + 1
    APR.BookingList["UpdateQuest"] = true
end

function UpdateNextStep()
    APRData[APR.PlayerID][APR.ActiveRoute] = APRData[APR.PlayerID][APR.ActiveRoute] + 1
    APR.BookingList["UpdateStep"] = true
end

function NextQuestStep()
    APRData[APR.PlayerID][APR.ActiveRoute] = APRData[APR.PlayerID][APR.ActiveRoute] + 1
    UpdateQuestAndStep()
end

function PreviousQuestStep()
    local userMapData = APRData[APR.PlayerID]
    local activeMap = APR.ActiveRoute
    local questStepList = APR.RouteQuestStepList[activeMap]
    local faction = APR.Faction
    local race = APR.Race
    local gender = APR.Gender
    local className = APR.ClassName

    while true do
        userMapData[activeMap] = userMapData[activeMap] - 1
        local steps = questStepList[userMapData[activeMap]]

        if not ((steps.Faction and steps.Faction ~= faction) or
                (steps.Race and steps.Race ~= race) or
                (steps.Gender and steps.Gender ~= gender) or
                (steps.Class and steps.Class ~= className) or
                (steps.HasAchievement and not _G.HasAchievement(steps.HasAchievement)) or
                (steps.DontHaveAchievement and _G.HasAchievement(steps.DontHaveAchievement)) or
                (steps.HasAura and not _G.HasAura(steps.HasAura)) or
                (steps.DontHaveAura and _G.HasAura(steps.DontHaveAura)) or
                steps.Waypoint) then
            break
        end
    end

    -- Update the quest and step
    UpdateQuestAndStep()
end

function GetTotalSteps(route)
    route = route or APR.ActiveRoute
    local stepIndex = 0
    for id, step in pairs(APR.RouteQuestStepList[route]) do
        -- Hide step for Faction, Race, Class, Achievement
        if (
                (not step.Faction or step.Faction == APR.Faction) and
                (not step.Race or step.Race == APR.Race) and
                (not step.Gender or step.Gender == APR.Gender) and
                (not step.Class or step.Class == APR.ClassName) and
                (not step.HasAchievement or _G.HasAchievement(step.HasAchievement)) and
                (not step.DontHaveAchievement or not _G.HasAchievement(step.DontHaveAchievement)) and
                (not step.HasAura or _G.HasAura(step.HasAura)) and
                (not step.DontHaveAura or not _G.HasAura(step.DontHaveAura))
            ) then
            stepIndex = stepIndex + 1
        end
    end
    APRData[APR.PlayerID][route .. '-TotalSteps'] = stepIndex
    return stepIndex
end

function CheckIsInRouteZone()
    if (APR.settings.profile.debug) then
        print("Function: APR step helper- CheckIsInRouteZone()")
    end
    if not APR.ActiveRoute then
        return
    end
    local routeZoneMapIDs, mapid, routeName, expansion = APR.transport:GetRouteMapIDsAndName()
    local parentMapID = APR:GetPlayerParentMapID(Enum.UIMapType.Continent)
    local currentMapID = C_Map.GetBestMapForUnit("player")
    local isSameContinent, nextContinent = APR.transport:IsSameContinent(mapid)
    local step = GetSteps(APR.ActiveRoute and APRData[APR.PlayerID][APR.ActiveRoute] or nil)
    if not currentMapID or not isSameContinent then
        return false
    end

    if step and (step.Zone == parentMapID or step.Zone == currentMapID) then
        return true
    end

    if APR:IsInExpansionRouteMaps(routeZoneMapIDs, parentMapID) or APR:IsInExpansionRouteMaps(routeZoneMapIDs, currentMapID) then
        return true
    end

    if parentMapID then
        local childrenMap = C_Map.GetMapChildrenInfo(parentMapID)
        if not childrenMap then
            return false
        end

        for _, map in ipairs(childrenMap) do
            if APR:IsInExpansionRouteMaps(routeZoneMapIDs, map.mapID) or (step and step.Zone == map.mapID) then
                return true
            end
        end
    end

    return false
end

function GetSteps(CurStep)
    if (CurStep and APR.RouteQuestStepList and APR.RouteQuestStepList[APR.ActiveRoute]) then
        return APR.RouteQuestStepList[APR.ActiveRoute][CurStep]
    end
    return nil
end

function IsARouteQuest(questId)
    local steps = GetSteps(APRData[APR.PlayerID][APR.ActiveRoute])
    if (steps) then
        if Contains(steps.PickUp, questId) or Contains(steps.PickUpDB, questId) then
            return true
        end
    end
    return false
end

function IsPickupStep()
    local steps = GetSteps(APRData[APR.PlayerID][APR.ActiveRoute])
    if (steps) then
        if steps.PickUp or steps.PickUpDB then
            return true
        end
    end
    return false
end

function HasTaxiNode(nodeID)
    for id, name in pairs(APRTaxiNodes[APR.PlayerID]) do
        if id == nodeID then
            return true
        end
    end
    return false
end

function OverrideRouteData()
    if APR.ActiveRoute and string.match(APR.ActiveRoute, "DesMephisto%-Gorgrond") then
        if C_QuestLog.IsQuestFlaggedCompleted(35049) then
            APR.RouteQuestStepList["543-DesMephisto-Gorgrond"] = nil
            APR.RouteQuestStepList["543-DesMephisto-Gorgrond"] = APR.RouteQuestStepList
                ["543-DesMephisto-Gorgrond-Lumbermill"]
        end
        if C_QuestLog.IsQuestFlaggedCompleted(34992) then
            APR.RouteQuestStepList["543-DesMephisto-Gorgrond-p1"] = nil
            APR.RouteQuestStepList["543-DesMephisto-Gorgrond-p1"] = APR.RouteQuestStepList
                ["543-DesMephisto-Gorgrond-Lumbermill"]
        end
    end
end

function GetTaxiNodeName(step)
    -- First, try to get the node name from the player's specific nodes
    local playerNodes = APRTaxiNodes[APR.PlayerID]
    if playerNodes and playerNodes[step.NodeID] then
        return playerNodes[step.NodeID]
    end

    -- Fallback to the name directly from the step object
    if step.Name then
        return step.Name
    end

    -- Check global faction nodes
    for _, factionNodes in pairs(APR.TaxiNodes) do
        for _, continentNode in pairs(factionNodes) do
            if continentNode[step.NodeID] then
                return continentNode[step.NodeID].Name
            end
        end
    end

    -- If no name found, return nil
    return nil
end

function APR:LoadCustomRoutes()
    for name, steps in pairs(APRData.CustomRoute) do
        APR.RouteQuestStepList[name] = steps
        APR.RouteList.Custom[name] = name:match("%d+-(.*)")
    end
end
