-- The spells whose cost is tracked, what each cast costs, and what counts as
-- Necromancy gear for Lord of Bones stalls.

---@alias RuneName string The rune's name as the player sees it, e.g. "Bone rune"

---@class Spell
---@field key string Short name used to save its settings and totals, e.g. "LordOfBones"
---@field name string Name shown to the player, e.g. "Lord of Bones"
---@field ability_id? integer Only for spells the game reports directly
---@field timer? SpellTimer Only for spells detected by their time left
---@field runes table<RuneName, integer> How many of each rune one cast uses
---@field counted_by_rune? RuneName Count casts by how many of this rune were used, see rune_count_casts.lua
---@field can_stall? boolean Only Lord of Bones

---@class SpellTimer
---@field var string The game value that holds the time left
---@field mask? integer Picks this spell's part out of the game value
---@field shift? integer Picks this spell's part out of the game value
---@field per_cast integer How much one cast adds to the time left
---@field cast_tick_var? string Only Darkness: the game value holding when it was cast

---@class Settings
---@field spells Spell[]
---@field item_ids table<RuneName, integer>
---@field item_config_names table<RuneName, string>
---@field store_price_multipliers table<RuneName, number>
---@field fallback_prices table<RuneName, number>
---@field necro_item_ids table<integer, true>
---@field rune_count_var_ids table<RuneName, integer>

---@type Settings
local settings = {
    -- The spells whose cost is tracked, in the order they are shown.
    --
    -- key:        a short name for the spell, used to save its settings and totals
    -- name:       the name shown to the player
    -- ability_id: how the game identifies the spell when it is cast. Only used
    --             for spells the game reports directly, like Lord of Bones.
    -- timer:      for spells the game doesn't report directly. Instead we watch
    --             how long the spell has left to run: each cast adds 12 minutes,
    --             so whenever the time left goes up, the spell was cast. These
    --             spells can also be multi-cast (5 casts at once).
    --             var:           the game value that holds the time left
    --             mask, shift:   some game values hold several things at once;
    --                            these pick out the part that is this spell's time
    --             per_cast:      how much one cast adds to the time left (12 minutes)
    --             cast_tick_var: Darkness stores the moment it runs out instead of
    --                            the time left. To work out the time left we also
    --                            need the moment it was cast, which the game keeps
    --                            in this value.
    -- runes:      the runes one cast uses
    -- counted_by_rune: count casts by how many of this rune were used, instead
    --             of only by the timer, which can't tell quick casts apart from
    --             a multi-cast. The rune needs an entry in rune_count_var_ids.
    -- can_stall:  Lord of Bones only. It is often cast just to stall, and with the
    --             "Only track Lord of Bones stalls" setting on, casts made while
    --             wearing Necromancy gear are ignored.
    spells = {
        {
            key = "LordOfBones",
            name = "Lord of Bones",
            ability_id = 49072,
            can_stall = true,
            runes = {
                ["Spirit rune"] = 8,
                ["Bone rune"] = 6,
                ["Flesh rune"] = 2,
                ["Miasma rune"] = 1,
            },
        },
        {
            key = "AnimateDead",
            name = "Animate Dead",
            timer = { var = "COMBATV2_GENERIC_BASE_VAR_7", mask = 0xff000000, shift = 24, per_cast = 48 },
            counted_by_rune = "Soul rune",
            runes = {
                ["Earth rune"] = 30,
                ["Death rune"] = 15,
                ["Blood rune"] = 15,
                ["Soul rune"] = 6,
            },
        },
        {
            key = "Vampyrism",
            name = "Vampyrism",
            timer = { var = "COMBATV2_GENERIC_BASE_VAR_8", mask = 0x3ff00, shift = 8, per_cast = 48 },
            counted_by_rune = "Soul rune",
            runes = {
                ["Fire rune"] = 40,
                ["Death rune"] = 10,
                ["Blood rune"] = 15,
                ["Soul rune"] = 6,
            },
        },
        {
            key = "Penance",
            name = "Penance",
            timer = { var = "COMBATV2_GENERIC_BASE_VAR_8", mask = 0xff, shift = 0, per_cast = 48 },
            counted_by_rune = "Soul rune",
            runes = {
                ["Body rune"] = 30,
                ["Chaos rune"] = 20,
                ["Law rune"] = 3,
                ["Soul rune"] = 10,
            },
        },
        {
            key = "Darkness",
            name = "Darkness",
            timer = {
                var = "COMBATV2_BUFF_NECROMANCY_DARKNESS_END",
                per_cast = 1200,
                cast_tick_var = "COMBATV2_COOLDOWN_NECROMANCY_DARKNESS_START",
            },
            runes = {
                ["Spirit rune"] = 40,
                ["Bone rune"] = 20,
                ["Flesh rune"] = 10,
                ["Miasma rune"] = 5,
            },
        },
    },

    -- The game values (VarClient ids) holding how many of a rune the player has
    -- in the backpack and rune pouches together. The game has these for the
    -- standard runes but not for Necromancy runes.
    rune_count_var_ids = {
        ["Soul rune"] = 5905, -- COMBATV2_RUNECOUNT_SOUL
    },

    -- The game's item id for each rune, used to look up its Grand Exchange price
    item_ids = {
        ["Spirit rune"] = 55337,
        ["Bone rune"] = 55338,
        ["Flesh rune"] = 55339,
        ["Miasma rune"] = 55340,
        ["Earth rune"] = 557,
        ["Fire rune"] = 554,
        ["Body rune"] = 559,
        ["Chaos rune"] = 562,
        ["Law rune"] = 563,
        ["Death rune"] = 560,
        ["Blood rune"] = 565,
        ["Soul rune"] = 566,
    },

    -- The game's internal name for each rune, used to look up its shop price
    item_config_names = {
        ["Spirit rune"] = "SPIRITRUNE",
        ["Bone rune"] = "BONERUNE",
        ["Flesh rune"] = "FLESHRUNE",
        ["Miasma rune"] = "MIASMARUNE",
        ["Earth rune"] = "EARTHRUNE",
        ["Fire rune"] = "FIRERUNE",
        ["Body rune"] = "BODYRUNE",
        ["Chaos rune"] = "CHAOSRUNE",
        ["Law rune"] = "LAWRUNE",
        ["Death rune"] = "DEATHRUNE",
        ["Blood rune"] = "BLOODRUNE",
        ["Soul rune"] = "SOULRUNE",
    },

    -- Runes that cost more in shops than the game's listed price. Thalmund's
    -- Wares in Um sells Necromancy runes at 10 times the listed price. (The shop
    -- that sells them at the listed price never has any in stock.)
    store_price_multipliers = {
        ["Spirit rune"] = 10,
        ["Bone rune"] = 10,
        ["Flesh rune"] = 10,
        ["Miasma rune"] = 10,
    },

    -- Rough prices in gp, used when a rune's Grand Exchange price isn't
    -- available. Costs that use these are marked as "estimated" for the player.
    fallback_prices = {
        ["Spirit rune"] = 70,
        ["Bone rune"] = 350,
        ["Flesh rune"] = 640,
        ["Miasma rune"] = 590,
        ["Earth rune"] = 15,
        ["Fire rune"] = 40,
        ["Body rune"] = 15,
        ["Chaos rune"] = 160,
        ["Law rune"] = 400,
        ["Death rune"] = 100,
        ["Blood rune"] = 290,
        ["Soul rune"] = 1000,
    },

    -- Item ids of Necromancy gear, used to tell Lord of Bones stalls apart from
    -- normal Necromancy combat. The game's internal name is next to each id.
    necro_item_ids = {
        -- Underworld, T90
        [55424] = true, -- NECRO_UNDERWORLD_HEAD_T90
        [55426] = true, -- NECRO_UNDERWORLD_BODY_T90
        [55434] = true, -- NECRO_UNDERWORLD_BODY_T90_AUGMENTED
        [55428] = true, -- NECRO_UNDERWORLD_LEGS_T90
        [55435] = true, -- NECRO_UNDERWORLD_LEGS_T90_AUGMENTED
        [55430] = true, -- NECRO_UNDERWORLD_HANDS_T90
        [55432] = true, -- NECRO_UNDERWORLD_FEET_T90
        [55542] = true, -- NECRO_UNDERWORLD_LANTERN_T90
        [55545] = true, -- NECRO_UNDERWORLD_LANTERN_T90_AUGMENTED

        -- Underworld power, T90
        [55466] = true, -- NECRO_UNDERWORLD_POWER_HEAD_T90
        [55468] = true, -- NECRO_UNDERWORLD_POWER_BODY_T90
        [55476] = true, -- NECRO_UNDERWORLD_POWER_BODY_T90_AUGMENTED
        [55470] = true, -- NECRO_UNDERWORLD_POWER_LEGS_T90
        [55477] = true, -- NECRO_UNDERWORLD_POWER_LEGS_T90_AUGMENTED
        [55472] = true, -- NECRO_UNDERWORLD_POWER_HANDS_T90
        [55474] = true, -- NECRO_UNDERWORLD_POWER_FEET_T90

        -- Rasial, T95
        [55488] = true, -- NECRO_RASIAL_HEAD_T95
        [55490] = true, -- NECRO_RASIAL_BODY_T95
        [55498] = true, -- NECRO_RASIAL_BODY_T95_AUGMENTED
        [55492] = true, -- NECRO_RASIAL_LEGS_T95
        [55499] = true, -- NECRO_RASIAL_LEGS_T95_AUGMENTED
        [55494] = true, -- NECRO_RASIAL_HANDS_T95
        [55496] = true, -- NECRO_RASIAL_FEET_T95
        [55480] = true, -- NECRO_RASIAL_ARMGUARD_T95
        [55484] = true, -- NECRO_RASIAL_ARMGUARD_T95_AUGMENTED
        [55482] = true, -- NECRO_RASIAL_LANTERN_T95
        [55485] = true, -- NECRO_RASIAL_LANTERN_T95_AUGMENTED
    },
}

return settings
