-- Works out which spells were cast, and how many times, by watching values
-- the game sends to the plugin.
--
-- Lord of Bones is easy: the game tells us directly when it is used
-- (COMBATV2_JUST_USED_ABILITY).
--
-- The other spells aren't reported that way, so we watch how long each one
-- has left to run instead. A cast adds 12 minutes. The time left otherwise
-- only goes down (it counts down, or another spell replaces it), so whenever
-- it goes up, the spell was cast.
--
-- A multi-cast casts the spell 5 times at once, filling it up to an hour.
-- Casting quickly by hand can also add more than 12 minutes in one go, but
-- only a multi-cast fills it all the way up, so that is how we tell them apart.
--
-- Known gap: a multi-cast always uses the runes of 5 casts, even if the
-- spell already had time left, but we only see the time it adds. With 48
-- minutes left, a multi-cast adds 12 minutes, which looks just like a single
-- cast, so it is counted as 1. The game doesn't allow a multi-cast when the
-- spell is nearly full (e.g. at 59 minutes), so this only happens when
-- there is room for at least one more cast.
local CastDetection = {}
CastDetection.__index = CastDetection

local just_used_ability_var = "COMBATV2_JUST_USED_ABILITY"

-- Picks this spell's time left out of a game value. For some spells the game
-- packs several things into one number, and mask/shift pick out our part.
-- Darkness has a value of its own, so it is used as is.
-- timer: as in config.lua
local function timer_value(var_value, timer)
    if timer.mask == nil then
        return var_value
    end
    return (var_value & timer.mask) >> timer.shift
end

-- A multi-cast is always counted as this many casts: it fills the spell up to
-- an hour (5 x 12 minutes) and always uses the runes of 5 casts.
local multi_cast_casts = 5

-- Turns the time added into a number of casts, e.g. 24 minutes = 2 casts.
-- The timer may have counted down a little at the same moment, so this rounds
-- to the nearest cast. Any increase counts as at least one cast, since topping
-- up a spell that is nearly full adds less than 12 minutes.
local function casts_from_timer_rise(rise, per_cast)
    return math.max(1, math.floor(rise / per_cast + 0.5))
end

-- Whether the spell now has about an hour left, as it does after a
-- multi-cast. A little under an hour still counts, since the timer may have
-- already counted down a bit.
local function is_full(time_left, per_cast)
    return time_left ~= nil and time_left >= multi_cast_casts * per_cast - per_cast / 2
end

-- spells: list of spells, as in config.lua
function CastDetection.new(spells)
    local self = setmetatable({}, CastDetection)
    self.spells = spells
    -- The last time each spell was cast, for spells like Darkness that need it
    -- (see cast_tick_var in config.lua).
    self.cast_ticks = {}
    return self
end

-- What the timer was before this cast, so we can see how much was added.
-- Returns nil when we can't tell.
--
-- For most spells that is simply the old value. Darkness is different: it
-- stores the moment it runs out rather than the time left. If Darkness wasn't
-- active, the old value is 0 or a moment in the past, so we measure from
-- the moment it was cast instead.
function CastDetection:timer_start(timer, old_timer)
    if timer.cast_tick_var == nil then
        return old_timer
    end
    local cast_tick = self.cast_ticks[timer.cast_tick_var]
    if cast_tick == nil then
        if old_timer == 0 then
            return nil
        end
        return old_timer
    end
    return math.max(old_timer, cast_tick)
end

-- How long the spell has left after this cast, or nil when we can't tell.
-- For most spells that is the timer itself. For Darkness it is the time
-- between when it was cast and when it runs out.
function CastDetection:time_left(timer, new_timer)
    if timer.cast_tick_var == nil then
        return new_timer
    end
    local cast_tick = self.cast_ticks[timer.cast_tick_var]
    if cast_tick == nil then
        return nil
    end
    return new_timer - cast_tick
end

-- Returns how many times the spell was cast in this change, 0 if it wasn't.
function CastDetection:times_cast(spell, var_name, old_value, new_value)
    if var_name == just_used_ability_var then
        if spell.ability_id ~= nil and spell.ability_id == new_value then
            return 1
        end
        return 0
    end

    local timer = spell.timer
    if timer == nil or timer.var ~= var_name or old_value == nil or new_value == nil then
        return 0
    end
    local old_timer = timer_value(old_value, timer)
    local new_timer = timer_value(new_value, timer)
    if new_timer <= old_timer then
        return 0
    end
    local start = self:timer_start(timer, old_timer)
    if start == nil then
        return 1
    end
    local casts = casts_from_timer_rise(new_timer - start, timer.per_cast)
    if casts > 1 and is_full(self:time_left(timer, new_timer), timer.per_cast) then
        return multi_cast_casts
    end
    return casts
end

-- Keeps track of when Darkness-like spells were last cast. The game updates
-- this just before it updates the spell's timer.
function CastDetection:remember_cast_tick(var_name, new_value)
    for _, spell in ipairs(self.spells) do
        if spell.timer ~= nil and spell.timer.cast_tick_var == var_name then
            self.cast_ticks[var_name] = new_value
        end
    end
end

-- Called every time the game changes one of its values. Returns a list of
-- { spell, casts } for each spell that this change shows was cast. Usually
-- the list is empty or has one entry.
function CastDetection:cast_spells(var_name, old_value, new_value)
    self:remember_cast_tick(var_name, new_value)

    local cast = {}
    for _, spell in ipairs(self.spells) do
        local casts = self:times_cast(spell, var_name, old_value, new_value)
        if casts > 0 then
            table.insert(cast, { spell = spell, casts = casts })
        end
    end
    return cast
end

return CastDetection
