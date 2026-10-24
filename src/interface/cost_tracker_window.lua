-- A separate, movable window with the spell totals on the main game screen,
-- opened from the plugin's page. It has a tab for the totals so far and one for
-- the current session, with buttons to pause or resume it, start a new one and
-- show the past sessions.
local TextLines = require("src/interface/text_lines")

local cost_tracker_window = {}

-- The lines shown on each tab.
---@class WindowPages
---@field total Line[]
---@field session Line[]
---@field session_state SessionState Which pause/resume button to show

-- What the session buttons ask main.lua to do.
---@class SessionControls
---@field pause fun()
---@field resume fun()
---@field new_session fun() Called when the player confirms "New session"
---@field show_history fun()

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
local session_state = "paused"
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

-- The pause/resume button is one of prettyui's media icons, showing what
-- clicking it does.
---@class SessionButtonLook
---@field sprite string
---@field tooltip string

---@return SessionButtonLook
local function pause_resume_look()
    if session_state == "running" then
        return { sprite = "PAUSE", tooltip = "Pause the session" }
    end
    return { sprite = "PLAY", tooltip = "Resume the session" }
end

local function apply_pause_resume_look()
    local look = pause_resume_look()
    pause_resume_button:SetSprite(look.sprite)
    pause_resume_button:SetTooltip(look.tooltip)
end

local function on_pause_resume()
    if session_state == "running" then
        session_controls.pause()
    else
        session_controls.resume()
    end
end

-- Asks the player to confirm before the session is replaced, since its casts
-- can't be counted again afterwards. Its time and cost go to the history.
local function confirm_new_session()
    prettyui.Confirm.new(game_area(), {
        title = "New session",
        body = "This starts a new session from zero. The current one is moved to the past sessions.",
        confirmLabel = "START",
        onConfirm = function()
            session_controls.new_session()
        end,
    })
end

-- Puts the session buttons at the top of the Session tab.
---@param page table The Session tab's prettyui page
local function add_session_buttons(page)
    local look = pause_resume_look()
    pause_resume_button = page:AddSpriteButton(look.sprite, on_pause_resume, { tooltip = look.tooltip })
    page:AddSimpleButton("New session", confirm_new_session)
    -- Wrapped so the extra arguments prettyui passes to button clicks aren't passed on.
    page:AddSimpleButton("Past sessions", function()
        session_controls.show_history()
    end)
end

---@param pages WindowPages
local function set_lines(pages)
    for _, page in ipairs(tab_pages) do
        texts[page]:set(pages[page])
        line_counts[page] = #pages[page]
    end
    if pages.session_state ~= session_state then
        session_state = pages.session_state
        apply_pause_resume_look()
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
