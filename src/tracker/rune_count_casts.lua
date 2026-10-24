-- Counts casts by how many runes were used, for spells where the timer can't
-- tell (see the known gap in cast_detection.lua). Casting quickly can put
-- several casts in the same moment, and from the timer alone that looks like a
-- multi-cast (5 casts) or a single cast.
--
-- The game keeps a count of each rune in the backpack and rune pouches
-- together. When a spell's timer goes up, we wait a few logic ticks for that
-- count to drop (in game it drops 1-2 ticks after the timer). The drop divided
-- by the runes one cast uses is the number of casts. If the count doesn't
-- drop in time (e.g. something saved the runes), the timer's guess is used.
---@class RuneCountCasts
---@field wait_ticks integer
---@field pending table<string, PendingCast> By spell key
---@field last_counts table<RuneName, integer>
local RuneCountCasts = {}
RuneCountCasts.__index = RuneCountCasts

-- A cast seen on the timer, waiting for its runes to be used.
---@class PendingCast
---@field spell Spell
---@field timer_casts integer How many casts the timer suggested
---@field runes_used integer How many of the spell's counted rune have been used since
---@field deadline integer The logic tick after which it is counted anyway

---@param wait_ticks integer How many logic ticks to wait for the rune count to drop
---@return RuneCountCasts
function RuneCountCasts.new(wait_ticks)
    local self = setmetatable({}, RuneCountCasts)
    self.wait_ticks = wait_ticks
    self.pending = {}
    self.last_counts = {}
    return self
end

-- Called when the timer shows a spell with counted_by_rune was cast. Another
-- cast of the same spell while it is still waiting is added to it, so a burst
-- of quick casts is counted together.
---@param spell_cast SpellCast
---@param tick integer The current logic tick
function RuneCountCasts:timer_cast(spell_cast, tick)
    local spell = spell_cast.spell
    local pending = self.pending[spell.key]
    if pending == nil then
        pending = { spell = spell, timer_casts = 0, runes_used = 0 }
        self.pending[spell.key] = pending
    end
    pending.timer_casts = pending.timer_casts + spell_cast.casts
    pending.deadline = tick + self.wait_ticks
end

-- Called on every logic tick with the current count of a rune. A drop is
-- put on the waiting spell that uses that rune, if there is one.
---@param rune RuneName
---@param count integer
function RuneCountCasts:rune_count(rune, count)
    local last = self.last_counts[rune]
    self.last_counts[rune] = count
    if last == nil or count >= last then
        return
    end
    for _, pending in pairs(self.pending) do
        if pending.spell.counted_by_rune == rune then
            pending.runes_used = pending.runes_used + (last - count)
            return
        end
    end
end

---@param pending PendingCast
---@return integer
local function casts_of(pending)
    if pending.runes_used == 0 then
        return pending.timer_casts
    end
    local per_cast = pending.spell.runes[pending.spell.counted_by_rune]
    return math.max(1, math.floor(pending.runes_used / per_cast + 0.5))
end

-- Returns the casts that are done waiting, and forgets them.
---@param tick integer The current logic tick
---@return SpellCast[]
function RuneCountCasts:finished(tick)
    local done = {}
    for key, pending in pairs(self.pending) do
        if tick >= pending.deadline then
            table.insert(done, { spell = pending.spell, casts = casts_of(pending) })
            self.pending[key] = nil
        end
    end
    return done
end

return RuneCountCasts
