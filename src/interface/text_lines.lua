-- A block of text lines inside a page or window. When the totals change, the
-- existing lines are updated rather than redrawing everything, so a window
-- stays where it is and nothing flickers.
-- A line of text with a tooltip shown when hovering over it.
---@class LineWithTooltip
---@field text string
---@field tooltip string

---@alias Line string | LineWithTooltip

-- One shown line: the prettyui text it is drawn with, and its tooltip.
---@class TextRow
---@field text table The prettyui text
---@field tooltip_text? string
---@field has_tooltip_binding? boolean

---@class TextLines
---@field container table The prettyui page or window the lines are added to
---@field rows TextRow[]
local TextLines = {}
TextLines.__index = TextLines

---@param container table The prettyui page or window to add the lines to
---@return TextLines
function TextLines.new(container)
    return setmetatable({ container = container, rows = {} }, TextLines)
end

---@param line Line
---@return string
local function line_text(line)
    if type(line) == "table" then
        return line.text
    end
    return line
end

---@param line Line
---@return string?
local function line_tooltip(line)
    if type(line) == "table" then
        return line.tooltip
    end
    return nil
end

-- Rows are reused for whatever line ends up at their position, so a row's
-- tooltip has to be changed or removed along with its text. prettyui's
-- Tooltip.bind/set lets us do that after the row is created.
---@param row TextRow
---@param tooltip string?
function TextLines:set_tooltip(row, tooltip)
    if row.tooltip_text == tooltip then
        return
    end
    row.tooltip_text = tooltip

    if row.has_tooltip_binding then
        prettyui.Tooltip.set(row, tooltip)
    else
        -- Text only reacts to the mouse when enabled, which prettyui normally
        -- turns on only for text created with a tooltip.
        row.text.enabled = true
        prettyui.Tooltip.bind(row, row.text, self.container.content, tooltip)
        row.has_tooltip_binding = true
    end
end

-- Shows the given lines. Leftover lines from before are emptied, because
-- prettyui has no way to remove a single line.
---@param lines Line[]
function TextLines:set(lines)
    for i, line in ipairs(lines) do
        local row = self.rows[i]
        if row then
            row.text.content = line_text(line)
        else
            row = { text = self.container:AddText(line_text(line)) }
            self.rows[i] = row
        end
        self:set_tooltip(row, line_tooltip(line))
    end
    for i = #lines + 1, #self.rows do
        self.rows[i].text.content = ""
        self:set_tooltip(self.rows[i], nil)
    end
end

return TextLines
