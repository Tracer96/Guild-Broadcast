-------------------------------------------------------------------------------
-- GuildBroadcast.lua
-- Simple auto-broadcast panel addon for WoW 1.12 (Vanilla) client API.
-------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- Namespace / defaults
-- ---------------------------------------------------------------------------
GuildBroadcast_DefaultDB = {
    minimapAngle = 225,   -- degrees around the minimap (0 = top, clockwise)
    message      = "",    -- last message typed in the panel
    interval     = 30,    -- last interval value in seconds
}

-- Runtime state (not persisted)
GuildBroadcast_IsDragging  = false
GuildBroadcast_MouseIsDown = false

-- Auto-broadcast state (not persisted)
GuildBroadcast_AutoMessage  = nil   -- message to auto-broadcast
GuildBroadcast_AutoInterval = nil   -- interval in seconds
GuildBroadcast_AutoLastTick = 0     -- GetTime() of last auto-broadcast tick
GuildBroadcast_AutoEnabled  = false -- whether auto-broadcast is active

-- ---------------------------------------------------------------------------
-- Utility: print a message to the default chat frame
-- ---------------------------------------------------------------------------
function GuildBroadcast_Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[GuildBroadcast]|r " .. msg)
end

-- ---------------------------------------------------------------------------
-- Minimap button positioning
-- ---------------------------------------------------------------------------
function GuildBroadcast_UpdateButtonPosition()
    local angle  = GuildBroadcastDB.minimapAngle
    local rad    = angle * (3.14159265 / 180)
    local radius = 80   -- distance from minimap center
    local x = math.cos(rad) * radius
    local y = math.sin(rad) * radius
    GuildBroadcastMinimapButton:ClearAllPoints()
    GuildBroadcastMinimapButton:SetPoint("CENTER", "Minimap", "CENTER", x, y)
end

-- ---------------------------------------------------------------------------
-- Button visual state (green while broadcasting, normal while idle)
-- ---------------------------------------------------------------------------
function GuildBroadcast_UpdateButtonState()
    if not GuildBroadcastDB then return end
    if GuildBroadcast_AutoEnabled then
        GuildBroadcastMinimapButton:GetNormalTexture():SetDesaturated(false)
        GuildBroadcastMinimapButton:GetNormalTexture():SetAlpha(1.0)
        GuildBroadcastMinimapButton:GetNormalTexture():SetVertexColor(0.3, 1.0, 0.3)
    else
        GuildBroadcastMinimapButton:GetNormalTexture():SetDesaturated(false)
        GuildBroadcastMinimapButton:GetNormalTexture():SetAlpha(1.0)
        GuildBroadcastMinimapButton:GetNormalTexture():SetVertexColor(1.0, 1.0, 1.0)
    end
end

-- ---------------------------------------------------------------------------
-- Toggle the broadcast panel open/closed
-- ---------------------------------------------------------------------------
function GuildBroadcast_TogglePanel()
    if GuildBroadcastPanel:IsShown() then
        GuildBroadcastPanel:Hide()
    else
        GuildBroadcastPanel:Show()
    end
end

-- ---------------------------------------------------------------------------
-- Main frame: OnLoad
-- ---------------------------------------------------------------------------
function GuildBroadcast_OnLoad()
    -- Register events
    GuildBroadcastFrame:RegisterEvent("VARIABLES_LOADED")
    GuildBroadcastFrame:RegisterEvent("PLAYER_LOGIN")

    -- Register slash command — /gb toggles the panel
    SLASH_GUILDBROADCAST1 = "/gb"
    SlashCmdList["GUILDBROADCAST"] = function(msg)
        GuildBroadcast_TogglePanel()
    end
end

-- ---------------------------------------------------------------------------
-- Main frame: OnEvent
-- ---------------------------------------------------------------------------
function GuildBroadcast_OnEvent()
    if event == "VARIABLES_LOADED" then
        -- Initialize SavedVariables with defaults where needed
        if not GuildBroadcastDB then
            GuildBroadcastDB = {}
        end
        if not GuildBroadcastDB.minimapAngle then
            GuildBroadcastDB.minimapAngle = GuildBroadcast_DefaultDB.minimapAngle
        end
        if not GuildBroadcastDB.message then
            GuildBroadcastDB.message = GuildBroadcast_DefaultDB.message
        end
        if not GuildBroadcastDB.interval then
            GuildBroadcastDB.interval = GuildBroadcast_DefaultDB.interval
        end

        -- Position the minimap button now that DB is ready
        GuildBroadcast_UpdateButtonPosition()
        GuildBroadcast_UpdateButtonState()

    elseif event == "PLAYER_LOGIN" then
        GuildBroadcast_Print("Loaded. Type /gb to open the broadcast panel.")
    end
end

-- ---------------------------------------------------------------------------
-- Panel: OnShow — restore saved message and interval
-- ---------------------------------------------------------------------------
function GuildBroadcast_Panel_OnShow()
    if GuildBroadcastDB then
        GuildBroadcastMessageBox:SetText(GuildBroadcastDB.message or "")
        GuildBroadcastIntervalBox:SetText(tostring(GuildBroadcastDB.interval or 30))
    end
    if GuildBroadcast_AutoEnabled then
        GuildBroadcastStatusText:SetText("Broadcasting every " .. GuildBroadcast_AutoInterval .. "s")
    else
        GuildBroadcastStatusText:SetText("Idle")
    end
end

-- ---------------------------------------------------------------------------
-- Panel: Start button — validate and begin auto-broadcast
-- ---------------------------------------------------------------------------
function GuildBroadcast_Panel_Start()
    local msg = GuildBroadcastMessageBox:GetText()
    msg = string.gsub(msg, "^%s+", "")
    msg = string.gsub(msg, "%s+$", "")
    if string.len(msg) == 0 then
        GuildBroadcastStatusText:SetText("Error: message is empty.")
        return
    end

    local interval = tonumber(GuildBroadcastIntervalBox:GetText())
    if not interval or interval < 10 then
        GuildBroadcastStatusText:SetText("Error: interval must be >= 10 seconds.")
        return
    end

    local guildName = GetGuildInfo("player")
    if not guildName or string.len(guildName) == 0 then
        GuildBroadcastStatusText:SetText("Error: you are not in a guild.")
        return
    end

    -- Persist to SavedVariables
    GuildBroadcastDB.message  = msg
    GuildBroadcastDB.interval = interval

    -- Send the first message immediately, then repeat every N seconds
    SendChatMessage(msg, "GUILD")
    GuildBroadcast_AutoMessage  = msg
    GuildBroadcast_AutoInterval = interval
    GuildBroadcast_AutoLastTick = GetTime()
    GuildBroadcast_AutoEnabled  = true

    GuildBroadcast_UpdateButtonState()
    GuildBroadcastStatusText:SetText("Broadcasting every " .. interval .. "s")
end

-- ---------------------------------------------------------------------------
-- Panel: Stop button — halt auto-broadcast
-- ---------------------------------------------------------------------------
function GuildBroadcast_Panel_Stop()
    GuildBroadcast_AutoEnabled = false
    GuildBroadcast_UpdateButtonState()
    GuildBroadcastStatusText:SetText("Idle")
end

-- ---------------------------------------------------------------------------
-- Minimap button: OnLoad
-- ---------------------------------------------------------------------------
function GuildBroadcast_MinimapButton_OnLoad(button)
    button:SetMovable(true)
end

-- ---------------------------------------------------------------------------
-- Minimap button: OnClick — left-click toggles the panel
-- ---------------------------------------------------------------------------
function GuildBroadcast_MinimapButton_OnClick(button, mouseButton)
    if mouseButton == "LeftButton" then
        GuildBroadcast_TogglePanel()
    end
end

-- ---------------------------------------------------------------------------
-- Minimap button: OnEnter — show tooltip
-- ---------------------------------------------------------------------------
function GuildBroadcast_MinimapButton_OnEnter(button)
    GameTooltip:SetOwner(button, "ANCHOR_LEFT")
    GameTooltip:SetText("Guild Broadcast", 1, 0.82, 0)
    if GuildBroadcast_AutoEnabled then
        GameTooltip:AddLine("Broadcasting every " .. GuildBroadcast_AutoInterval .. "s", 0.3, 1, 0.3)
    else
        GameTooltip:AddLine("Idle", 0.8, 0.8, 0.8)
    end
    GameTooltip:AddLine("Left-click to toggle broadcast panel.", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end

-- ---------------------------------------------------------------------------
-- Minimap button: OnLeave — hide tooltip
-- ---------------------------------------------------------------------------
function GuildBroadcast_MinimapButton_OnLeave(button)
    GameTooltip:Hide()
end

-- ---------------------------------------------------------------------------
-- Minimap button: drag support
-- ---------------------------------------------------------------------------
function GuildBroadcast_MinimapButton_OnMouseDown(button, mouseButton)
    if mouseButton == "LeftButton" then
        GuildBroadcast_MouseIsDown = true
        GuildBroadcast_IsDragging = false
        GuildBroadcast_DragStartX, GuildBroadcast_DragStartY = GetCursorPosition()
    end
end

function GuildBroadcast_MinimapButton_OnMouseUp(button, mouseButton)
    if mouseButton == "LeftButton" then
        GuildBroadcast_MouseIsDown = false
        GuildBroadcast_IsDragging = false
    end
end

function GuildBroadcast_MinimapButton_OnUpdate(button, elapsed)
    if not GuildBroadcast_IsDragging then
        -- Detect drag by checking if mouse moved more than 4 pixels since press
        if GuildBroadcast_MouseIsDown then
            local cx, cy = GetCursorPosition()
            if GuildBroadcast_DragStartX then
                local dx = cx - GuildBroadcast_DragStartX
                local dy = cy - GuildBroadcast_DragStartY
                if (dx * dx + dy * dy) > 16 then
                    GuildBroadcast_IsDragging = true
                end
            end
        end
    end

    if GuildBroadcast_IsDragging then
        -- Calculate angle from minimap center to cursor
        local mx, my = Minimap:GetCenter()
        local cx, cy = GetCursorPosition()
        local scale  = UIParent:GetEffectiveScale()
        cx = cx / scale
        cy = cy / scale
        local dx = cx - mx
        local dy = cy - my
        local angle = math.atan2(dy, dx) * (180 / 3.14159265)
        GuildBroadcastDB.minimapAngle = angle
        GuildBroadcast_UpdateButtonPosition()
    end

    -- Refresh minimap icon tint
    GuildBroadcast_UpdateButtonState()

    -- Auto-broadcast tick
    if GuildBroadcast_AutoEnabled then
        local now = GetTime()
        if now - GuildBroadcast_AutoLastTick >= GuildBroadcast_AutoInterval then
            local guildName = GetGuildInfo("player")
            if guildName and string.len(guildName) > 0 then
                SendChatMessage(GuildBroadcast_AutoMessage, "GUILD")
                GuildBroadcast_AutoLastTick = now
            else
                GuildBroadcast_AutoEnabled = false
                GuildBroadcast_UpdateButtonState()
                if GuildBroadcastPanel:IsShown() then
                    GuildBroadcastStatusText:SetText("Stopped: not in a guild.")
                end
                GuildBroadcast_Print("Auto-broadcast stopped: you are not in a guild.")
            end
        end
    end
end
