-- A fake prettyui global with just enough of SimpleView, Window and Tabs for the interface tests.
local fake_prettyui = {}

local new_container

local function new_text(content)
    return { content = content }
end

local Container = {}
Container.__index = Container

function Container:AddTitle(title)
    self.title = title
end

function Container:AddText(content)
    local text = new_text(content)
    table.insert(self.texts, text)
    return text
end

-- Checkboxes are kept by value, in the order they were added.
function Container:AddCheckboxButton(buttons, options)
    local checkbox = {
        text = buttons[1].text,
        selected = buttons[1].selected,
        tooltip = buttons[1].tooltip,
        on_change = options.onChange,
    }
    self.checkboxes[buttons[1].value] = checkbox
    table.insert(self.checkbox_order, buttons[1].value)
end

-- Tabs keep their labels and options, and one container per tab as its page.
function Container:AddTabs(labels, options)
    local tabs = { labels = labels, options = options, pages = {}, active = options.activeIndex or 1 }
    for index in ipairs(labels) do
        tabs.pages[index] = new_container("TabPage", self, {})
    end
    function tabs.GetPage(_, index) return tabs.pages[index] end
    function tabs.GetActiveIndex() return tabs.active end
    -- refreshes counts how often prettyui would re-measure the tabs.
    tabs.refreshes = 0
    function tabs.SetActive(_, index)
        tabs.active = index
        tabs.refreshes = tabs.refreshes + 1
    end
    self.tabs = tabs
    return tabs
end

-- Sprite buttons are kept in the order they were added, with their current sprite, tooltip and options.
function Container:AddSpriteButton(sprite, on_click, options)
    local button = {
        sprite = sprite, on_click = on_click, options = options or {},
        tooltip = (options or {}).tooltip, disabled = (options or {}).disabled == true,
    }
    function button.SetSprite(self, value) self.sprite = value end
    function button.SetTooltip(self, value) self.tooltip = value end
    function button.SetDisabled(self, value) self.disabled = value end
    table.insert(self.sprite_buttons, button)
    return button
end

function Container:AddSimpleButton(label, on_click)
    self.buttons[label] = on_click
end

function Container:SetSize(width, height)
    self.root.width = width
    self.root.height = height
end

function Container:Show()
    self.shown = self.shown + 1
end

function Container:Close()
    if self.options.onClose then self.options.onClose(self) end
    self.closed = true
end

function Container:Destroy()
    self.destroyed = true
end

-- The text currently shown, ignoring rows that were blanked.
function Container:visible_lines()
    local lines = {}
    for _, text in ipairs(self.texts) do
        if text.content ~= "" then table.insert(lines, text.content) end
    end
    return lines
end

function new_container(kind, parent, options)
    return setmetatable({
        kind = kind, parent = parent, options = options,
        texts = {}, buttons = {}, sprite_buttons = {}, checkboxes = {}, checkbox_order = {}, shown = 0,
        content = { kind = "content" },
        background = { rgba = 0xFFFFFFFF },
        root = { x = options.x or 80, y = options.y or 80, width = options.width, height = options.height },
    }, Container)
end

-- Installs the fake and returns a list that every created view, window and dialog is added to.
-- Tab pages aren't added; they are on their window's tabs.pages.
function fake_prettyui.install()
    local created = {}
    local function constructor(kind)
        return {
            new = function(parent, options)
                local container = new_container(kind, parent, options or {})
                table.insert(created, container)
                return container
            end,
        }
    end
    prettyui = {
        SimpleView = constructor("SimpleView"),
        Window = constructor("Window"),
        -- Confirm dialogs are added to the created list as { kind = "Confirm", parent, options }.
        Confirm = {
            new = function(parent, options)
                local dialog = { kind = "Confirm", parent = parent, options = options }
                table.insert(created, dialog)
                return dialog
            end,
        },
        -- Keeps the tooltip on the text it is bound to, as text.tooltip.
        Tooltip = {
            bind = function(owner, target, parent, value)
                owner.fake_tooltip_target = target
                target.tooltip = value
                target.tooltip_parent = parent
            end,
            set = function(owner, value)
                owner.fake_tooltip_target.tooltip = value
                return true
            end,
        },
    }
    return created
end

return fake_prettyui
