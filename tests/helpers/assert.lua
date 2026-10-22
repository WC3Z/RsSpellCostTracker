local assert_helpers = {}

function assert_helpers.equal(actual, expected)
    if actual ~= expected then
        error("expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

-- Compares the text of each line. A line can be a string or { text, tooltip }.
function assert_helpers.same_lines(actual, expected)
    local function texts(lines)
        local result = {}
        for i, line in ipairs(lines) do
            result[i] = type(line) == "table" and line.text or line
        end
        return table.concat(result, "\n")
    end
    assert_helpers.equal(texts(actual), texts(expected))
end

return assert_helpers
