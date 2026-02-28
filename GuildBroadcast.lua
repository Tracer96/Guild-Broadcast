-------------------------------------------------------------------------------
-- GuildBroadcast.lua
-- Lightweight minimap icon addon for sending guild messages with a cooldown.
-- Compatible with WoW 1.12 (Vanilla) client API.
-------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- Namespace / defaults
-- ---------------------------------------------------------------------------
GuildBroadcast_DefaultDB = {
    cooldownSeconds = 300,   -- 5 minutes default
    minimapAngle    = 225,   -- degrees around the minimap (0 = top, clockwise)
}

-- Runtime state (not persisted)
GuildBroadcast_LastSendTime = 0   -- GetTime() value of last broadcast
GuildBroadcast_IsDragging   = false

-- ---------------------------------------------------------------------------
-- Utility: print a message to the default chat frame
-- ---------------------------------------------------------------------------
function GuildBroadcast_Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[GuildBroadcast]|r " .. msg)
end

-- ---------------------------------------------------------------------------
-- Cooldown helpers
-- ---------------------------------------------------------------------------
function GuildBroadcast_GetRemaining()
    local elapsed = GetTime() - GuildBroadcast_LastSendTime
    local remaining = GuildBroadcastDB.cooldownSeconds - elapsed
    if remaining < 0 then remaining = 0 end
    return remaining
end

function GuildBroadcast_IsReady()
    return GuildBroadcast_GetRemaining() == 0
end

-- ---------------------------------------------------------------------------
-- Core broadcast function
-- ---------------------------------------------------------------------------
function GuildBroadcast_Send(message)
    -- Validate message
    if not message or string.len(message) == 0 then
        GuildBroadcast_Print("Cannot send an empty message.")
        return
    end

    -- Validate guild membership (GetGuildInfo returns nil/empty when not in guild)
    local guildName = GetGuildInfo("player")
    if not guildName or string.len(guildName) == 0 then
        GuildBroadcast_Print("You are not in a guild.")
        return
    end

    -- Validate cooldown
    local remaining = GuildBroadcast_GetRemaining()
    if remaining > 0 then
        local mins = math.floor(remaining / 60)
        local secs = math.floor(remaining - mins * 60)
        GuildBroadcast_Print("On cooldown! " .. mins .. " minute(s) " .. secs .. " second(s) remaining.")
        return
    end

    -- Send the message
    SendChatMessage(message, "GUILD")
    GuildBroadcast_LastSendTime = GetTime()

    -- Update button appearance (dimmed while on cooldown)
    GuildBroadcast_UpdateButtonState()

    GuildBroadcast_Print("Message sent!")
end

-- ---------------------------------------------------------------------------
-- Popup helpers
-- ---------------------------------------------------------------------------
function GuildBroadcast_SendFromPopup()
    local msg = GuildBroadcastEditBox:GetText()
    GuildBroadcast_Send(msg)
    if GuildBroadcast_IsReady() then
        -- Still ready (send failed validation) — keep popup open
    else
        GuildBroadcastPopup:Hide()
    end
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
-- Button visual state (dim when on cooldown)
-- ---------------------------------------------------------------------------
function GuildBroadcast_UpdateButtonState()
    if GuildBroadcast_IsReady() then
        GuildBroadcastMinimapButton:GetNormalTexture():SetDesaturated(false)
        GuildBroadcastMinimapButton:GetNormalTexture():SetAlpha(1.0)
    else
        GuildBroadcastMinimapButton:GetNormalTexture():SetDesaturated(true)
        GuildBroadcastMinimapButton:GetNormalTexture():SetAlpha(0.5)
    end
end

-- ---------------------------------------------------------------------------
-- Main frame: OnLoad
-- ---------------------------------------------------------------------------
function GuildBroadcast_OnLoad()
    -- Register events
    GuildBroadcastFrame:RegisterEvent("VARIABLES_LOADED")
    GuildBroadcastFrame:RegisterEvent("PLAYER_LOGIN")

    -- Register slash commands
    SLASH_GUILDBROADCAST1 = "/gb"
    SLASH_GUILDBROADCAST2 = "/guildbroadcast"
    SlashCmdList["GUILDBROADCAST"] = GuildBroadcast_SlashCommand
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
        if not GuildBroadcastDB.cooldownSeconds then
            GuildBroadcastDB.cooldownSeconds = GuildBroadcast_DefaultDB.cooldownSeconds
        end
        if not GuildBroadcastDB.minimapAngle then
            GuildBroadcastDB.minimapAngle = GuildBroadcast_DefaultDB.minimapAngle
        end

        -- Position the minimap button now that DB is ready
        GuildBroadcast_UpdateButtonPosition()
        GuildBroadcast_UpdateButtonState()

    elseif event == "PLAYER_LOGIN" then
        GuildBroadcast_Print("Loaded. Type /gb for help.")
    end
end

-- ---------------------------------------------------------------------------
-- Minimap button: OnLoad
-- ---------------------------------------------------------------------------
function GuildBroadcast_MinimapButton_OnLoad(button)
    -- Clamp the button to Minimap parent (size 31x31 = radius ~15)
    button:SetMovable(true)
end

-- ---------------------------------------------------------------------------
-- Minimap button: OnClick
-- ---------------------------------------------------------------------------
function GuildBroadcast_MinimapButton_OnClick(button, mouseButton)
    if mouseButton == "LeftButton" then
        if GuildBroadcastPopup:IsShown() then
            GuildBroadcastPopup:Hide()
        else
            GuildBroadcastPopup:Show()
        end
    elseif mouseButton == "RightButton" then
        GuildBroadcast_PrintHelp()
    end
end

-- ---------------------------------------------------------------------------
-- Minimap button: OnEnter — show tooltip
-- ---------------------------------------------------------------------------
function GuildBroadcast_MinimapButton_OnEnter(button)
    GameTooltip:SetOwner(button, "ANCHOR_LEFT")
    GameTooltip:SetText("Guild Broadcast", 1, 0.82, 0)

    local remaining = GuildBroadcast_GetRemaining()
    if remaining > 0 then
        local mins = math.floor(remaining / 60)
        local secs = math.floor(remaining - mins * 60)
        GameTooltip:AddLine("Cooldown: " .. mins .. "m " .. secs .. "s remaining", 1, 0.3, 0.3)
    else
        GameTooltip:AddLine("Ready to broadcast!", 0.3, 1, 0.3)
    end

    GameTooltip:AddLine("Left-click to open broadcast window.", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Right-click for help.", 0.8, 0.8, 0.8)
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
        GuildBroadcast_IsDragging = false
        GuildBroadcast_DragStartX, GuildBroadcast_DragStartY = GetCursorPosition()
    end
end

function GuildBroadcast_MinimapButton_OnMouseUp(button, mouseButton)
    GuildBroadcast_IsDragging = false
end

function GuildBroadcast_MinimapButton_OnUpdate(button, elapsed)
    if not GuildBroadcast_IsDragging then
        -- Detect drag by checking if mouse moved more than 4 pixels since press
        if IsMouseButtonDown("LeftButton") then
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

    -- Periodically refresh the button visual (cooldown state)
    GuildBroadcast_UpdateButtonState()
end

-- ---------------------------------------------------------------------------
-- Slash command handler
-- ---------------------------------------------------------------------------
function GuildBroadcast_SlashCommand(msg)
    if not msg or string.len(msg) == 0 then
        GuildBroadcast_PrintHelp()
        return
    end

    -- /gb send <message>
    local sendStart = string.find(msg, "^send%s+(.+)")
    if sendStart then
        local message = string.sub(msg, 6)   -- skip "send "
        -- trim leading spaces
        message = string.gsub(message, "^%s+", "")
        GuildBroadcast_Send(message)
        return
    end

    -- /gb cd <minutes>
    local cdStart, cdEnd, cdVal = string.find(msg, "^cd%s+(%d+)")
    if cdStart then
        local minutes = tonumber(cdVal)
        if minutes and minutes > 0 then
            GuildBroadcastDB.cooldownSeconds = minutes * 60
            GuildBroadcast_Print("Cooldown set to " .. minutes .. " minute(s).")
        else
            GuildBroadcast_Print("Usage: /gb cd <minutes> (must be a positive number).")
        end
        return
    end

    -- /gb status
    if msg == "status" then
        local cfgMins = math.floor(GuildBroadcastDB.cooldownSeconds / 60)
        local cfgSecs = GuildBroadcastDB.cooldownSeconds - cfgMins * 60
        GuildBroadcast_Print("Configured cooldown: " .. cfgMins .. "m " .. cfgSecs .. "s")
        local remaining = GuildBroadcast_GetRemaining()
        if remaining > 0 then
            local mins = math.floor(remaining / 60)
            local secs = math.floor(remaining - mins * 60)
            GuildBroadcast_Print("Status: On cooldown — " .. mins .. "m " .. secs .. "s remaining.")
        else
            GuildBroadcast_Print("Status: Ready to broadcast!")
        end
        return
    end

    -- Default: show help
    GuildBroadcast_PrintHelp()
end

-- ---------------------------------------------------------------------------
-- Help text
-- ---------------------------------------------------------------------------
function GuildBroadcast_PrintHelp()
    GuildBroadcast_Print("Commands:")
    DEFAULT_CHAT_FRAME:AddMessage("  /gb send <message>  — Broadcast a guild message")
    DEFAULT_CHAT_FRAME:AddMessage("  /gb cd <minutes>    — Set cooldown (e.g. /gb cd 10)")
    DEFAULT_CHAT_FRAME:AddMessage("  /gb status          — Show cooldown status")
    DEFAULT_CHAT_FRAME:AddMessage("  /gb                 — Show this help")
    DEFAULT_CHAT_FRAME:AddMessage("Left-click the minimap icon to open the broadcast window.")
end
