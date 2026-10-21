-- A block of text rows inside a prettyui container (a SimpleView, Window or Panel).
-- Rows are updated in place instead of rebuilding the container, so a window
-- keeps its position and nothing flickers when the totals change.
local TextLines = {}
TextLines.__index = TextLines

function TextLines.new(container)
    return setmetatable({ container = container, rows = {} }, TextLines)
end

-- Shows the given lines. Rows that are no longer needed are blanked, because
-- prettyui has no way to remove a single row.
function TextLines:set(lines)
    for i, line in ipairs(lines) do
        if self.rows[i] then
            self.rows[i].content = line
        else
            self.rows[i] = self.container:AddText(line)
        end
    end
    for i = #lines + 1, #self.rows do
        self.rows[i].content = ""
    end
end

return TextLines
