-- A block of text lines inside a page or window. When the totals change, the
-- existing lines are updated rather than redrawing everything, so a window
-- stays where it is and nothing flickers.
local TextLines = {}
TextLines.__index = TextLines

function TextLines.new(container)
    return setmetatable({ container = container, rows = {} }, TextLines)
end

-- A line is either a string or { text, tooltip }.
local function line_text(line)
    if type(line) == "table" then
        return line.text
    end
    return line
end

local function line_tooltip(line)
    if type(line) == "table" then
        return line.tooltip
    end
    return nil
end

-- Rows are reused for whatever line ends up at their position, so a row's
-- tooltip has to be changed or removed along with its text. prettyui's
-- Tooltip.bind/set lets us do that after the row is created.
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
