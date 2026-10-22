-- A fake prettyui global with just enough of SimpleView and Window for the interface tests.
local fake_prettyui = {}

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

function Container:AddSimpleButton(label, on_click)
    self.buttons[label] = on_click
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

-- Installs the fake and returns a list that every created view and window is added to.
function fake_prettyui.install()
    local created = {}
    local function constructor(kind)
        return {
            new = function(parent, options)
                options = options or {}
                local container = setmetatable({
                    kind = kind, parent = parent, options = options,
                    texts = {}, buttons = {}, checkboxes = {}, checkbox_order = {}, shown = 0,
                    content = { kind = "content" },
                    root = { x = options.x or 80, y = options.y or 80, width = options.width, height = options.height },
                }, Container)
                table.insert(created, container)
                return container
            end,
        }
    end
    prettyui = {
        SimpleView = constructor("SimpleView"),
        Window = constructor("Window"),
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
