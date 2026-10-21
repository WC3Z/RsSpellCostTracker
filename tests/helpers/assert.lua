local assert_helpers = {}

function assert_helpers.equal(actual, expected)
    if actual ~= expected then
        error("expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

function assert_helpers.same_lines(actual, expected)
    assert_helpers.equal(table.concat(actual, "\n"), table.concat(expected, "\n"))
end

return assert_helpers
