local _G = _G

-- Likely deals with automatically skipping cutscenes using PlayMovie_hook
local PlayMovie_hook = MovieFrame_PlayMovie
MovieFrame_PlayMovie = function(...)
    local step = GetSteps(APRData[APR.PlayerID][APR.ActiveRoute])

    if IsModifierKeyDown() or not APR.settings.profile.autoSkipCutScene or (step and step.Dontskipvidthen) then
        PlayMovie_hook(...) --MovieFrame_PlayMovie, as previously stated
    else
        GameMovieFinished()
    end
end

CinematicFrame:HookScript("OnKeyDown", function(self, key)
    if key == "ESCAPE" then
        if CinematicFrame:IsShown() and CinematicFrame.closeDialog and CinematicFrameCloseDialogConfirmButton then
            CinematicFrameCloseDialog:Hide()
        end
    end
end)
CinematicFrame:HookScript("OnKeyUp", function(self, key)
    if key == "SPACE" or key == "ESCAPE" or key == "ENTER" then
        if CinematicFrame:IsShown() and CinematicFrame.closeDialog and CinematicFrameCloseDialogConfirmButton then
            CinematicFrameCloseDialogConfirmButton:Click()
        end
    end
end)

APR.SceneCutterEventFrame = CreateFrame("Frame")
APR.SceneCutterEventFrame:RegisterEvent("CINEMATIC_START")
APR.SceneCutterEventFrame:SetScript("OnEvent", function(self, event, ...)
    if not APR.settings.profile.enableAddon or not APR.settings.profile.autoSkipCutScene or IsModifierKeyDown() then return end
    local step = GetSteps(APRData[APR.PlayerID][APR.ActiveRoute])
    if step and step.Dontskipvid then
        return
    end
    C_Timer.After(0.5, CinematicFrame_CancelCinematic)
end)
