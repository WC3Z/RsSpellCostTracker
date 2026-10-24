-- A separate, movable window with the spell totals on the main game screen,
-- opened from the plugin's page. It has a tab for the totals so far and one for
-- the current session, with buttons to start, stop, pause and resume it.
local TextLines = require("src/interface/text_lines")

local cost_tracker_window = {}

-- The lines shown on each tab.
---@class WindowPages
---@field total Line[]
---@field session Line[]
---@field session_state SessionState Which session buttons to show

-- What the session buttons ask main.lua to do.
---@class SessionControls
---@field start fun()
---@field stop fun()
---@field pause fun()
---@field resume fun()

-- The tabs in the order they are shown, with the WindowPages field each one shows.
local tab_pages = { "total", "session" }
local tab_labels = { "Total", "Session" }

local window
local tabs
---@type table<string, TextLines>
local texts = {}
---@type table<string, integer>
local line_counts = {}
local transparent = false
---@type SessionControls
local session_controls
---@type SessionState
local session_state = "stopped"
local start_stop_button
local pause_resume_button

-- The background's colour as 0xRRGGBBAA. White leaves the background image as
-- it is, and the last two digits set how see-through it is (FF = solid).
local solid_background = 0xFFFFFFFF
local transparent_background = 0xFFFFFF60

local function apply_transparency()
    window.background.rgba = transparent and transparent_background or solid_background
end

-- The main game screen, so the window can be moved anywhere over the game.
local function game_area()
    return ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__GAME_AREA)
end

-- Where the window is and how big it is.
---@class WindowBounds
---@field x? number
---@field y? number
---@field width number
---@field height number

-- The session buttons are prettyui's media icons. The first starts a new
-- session or stops the current one. The second pauses or resumes it, and
-- can't be clicked when there is no session.
---@class SessionButtonLook
---@field sprite string
---@field tooltip string
---@field disabled? boolean

---@return SessionButtonLook start_stop, SessionButtonLook pause_resume
local function session_button_looks()
    local start_stop = { sprite = "STOP", tooltip = "Stop the session" }
    if session_state == "stopped" then
        start_stop = { sprite = "PLAY", tooltip = "Start a new session (clears the last one)" }
    end
    local pause_resume = { sprite = "PAUSE", tooltip = "Pause the session", disabled = session_state == "stopped" }
    if session_state == "paused" then
        pause_resume = { sprite = "PLAY", tooltip = "Resume the session" }
    end
    return start_stop, pause_resume
end

---@param button table A prettyui SpriteButton
---@param look SessionButtonLook
local function apply_look(button, look)
    button:SetSprite(look.sprite)
    button:SetTooltip(look.tooltip)
    button:SetDisabled(look.disabled == true)
end

local function on_start_stop()
    if session_state == "stopped" then
        session_controls.start()
    else
        session_controls.stop()
    end
end

local function on_pause_resume()
    if session_state == "running" then
        session_controls.pause()
    elseif session_state == "paused" then
        session_controls.resume()
    end
end

-- Puts the session buttons on one row at the top of the Session tab.
---@param page table The Session tab's prettyui page
local function add_session_buttons(page)
    local start_stop, pause_resume = session_button_looks()
    start_stop_button = page:AddSpriteButton(start_stop.sprite, on_start_stop, { tooltip = start_stop.tooltip })
    pause_resume_button = page:AddSpriteButton(pause_resume.sprite, on_pause_resume, {
        tooltip = pause_resume.tooltip,
        disabled = pause_resume.disabled,
        inline = true,
    })
end

---@param pages WindowPages
local function set_lines(pages)
    for _, page in ipairs(tab_pages) do
        texts[page]:set(pages[page])
        line_counts[page] = #pages[page]
    end
    if pages.session_state ~= session_state then
        session_state = pages.session_state
        local start_stop, pause_resume = session_button_looks()
        apply_look(start_stop_button, start_stop)
        apply_look(pause_resume_button, pause_resume)
    end
end

-- prettyui only re-measures the window's own scroll area when the window is
-- resized, not the tabs', so their scrollbars would keep the old size. There
-- is no resize callback, so the window's SetSize (which resizing calls) is
-- wrapped. Selecting the open tab again makes prettyui re-measure every tab.
local function refresh_tabs_on_resize()
    local set_size = window.SetSize
    window.SetSize = function(self, width, height)
        set_size(self, width, height)
        if tabs then
            tabs:SetActive(tabs:GetActiveIndex(), false)
        end
    end
end

---@param pages WindowPages
---@param bounds? WindowBounds Without it the window opens in prettyui's default spot
---@param active_tab? integer Which tab is open, 1 if left out
local function create(pages, bounds, active_tab)
    bounds = bounds or { width = 260, height = 160 }
    window = prettyui.Window.new(game_area(), {
        title = "Spell costs",
        x = bounds.x,
        y = bounds.y,
        width = bounds.width,
        height = bounds.height,
        resizable = true,
        -- prettyui's default minimum is 220 x 140, which is bigger than a single cost line needs.
        -- The height leaves room for the tab bar and a line.
        minWidth = 120,
        minHeight = 100,
        -- The tabs scroll instead, see below.
        scrollable = false,
        destroyOnClose = true,
        onClose = function()
            window = nil
            tabs = nil
        end,
    })
    apply_transparency()
    refresh_tabs_on_resize()
    -- prettyui tabs keep a fixed height and never grow to fit their lines, so
    -- they are made to fill the window instead, and each tab scrolls its own
    -- lines when they don't fit.
    tabs = window:AddTabs(tab_labels, { activeIndex = active_tab, y = 0, height = 0, heightAnchor = 1.0 })
    session_state = pages.session_state
    add_session_buttons(tabs:GetPage(2))
    for index, page in ipairs(tab_pages) do
        texts[page] = TextLines.new(tabs:GetPage(index))
    end
    set_lines(pages)
end

local function remove()
    window:Destroy()
    window = nil
    tabs = nil
end

---@param pages WindowPages
---@return boolean
local function any_tab_has_fewer_lines(pages)
    for _, page in ipairs(tab_pages) do
        if #pages[page] < line_counts[page] then
            return true
        end
    end
    return false
end

-- prettyui windows can grow but never shrink their content, and text rows
-- can't be removed. If we just blanked the rows we no longer need, the window
-- would keep a scrollbar for the empty space. So when a tab has fewer lines
-- than before, the window is rebuilt in the same place, at the same size and
-- with the same tab open.
---@param pages WindowPages
local function show_pages(pages)
    if any_tab_has_fewer_lines(pages) then
        local root = window.root
        local bounds = { x = root.x, y = root.y, width = root.width, height = root.height }
        local active_tab = tabs:GetActiveIndex()
        remove()
        create(pages, bounds, active_tab)
        return
    end
    set_lines(pages)
end

-- Opens the window, or brings it to the front if it is already open.
---@param pages WindowPages
function cost_tracker_window.open(pages)
    if window then
        window:Show()
        show_pages(pages)
        return
    end
    create(pages)
end

-- Shows the latest lines if the window is open.
---@param pages WindowPages
function cost_tracker_window.refresh(pages)
    if window then
        show_pages(pages)
    end
end

-- Sets what the session buttons do. Call before the window is opened.
---@param controls SessionControls
function cost_tracker_window.set_session_controls(controls)
    session_controls = controls
end

-- Makes the window's background see-through or solid, now and for windows
-- opened later.
---@param on boolean
function cost_tracker_window.set_transparent(on)
    transparent = on
    if window then
        apply_transparency()
    end
end

-- Removes the window, e.g. when the plugin is turned off.
function cost_tracker_window.destroy()
    if window then
        remove()
    end
end

return cost_tracker_window
