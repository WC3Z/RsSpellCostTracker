-- Settings for what counts as a stall and what each cast costs.
return {
    -- Value of COMBATV2_JUST_USED_ABILITY when Invoke Lord of Bones is cast.
    ability_id = 49072,

    -- Runes used by one cast, taken from the RuneScape Wiki page for
    -- Invoke Lord of Bones. Check in game before trusting the totals.
    runes_per_cast = {
        ["Spirit rune"] = 8,
        ["Bone rune"] = 6,
        ["Flesh rune"] = 2,
        ["Miasma rune"] = 1,
    },

    -- Item ids of the runes above, read from the backpack in game
    -- (item.obj.id). Used to look up Grand Exchange prices.
    item_ids = {
        ["Spirit rune"] = 55337,
        ["Bone rune"] = 55338,
        ["Flesh rune"] = 55339,
        ["Miasma rune"] = 55340,
    },

    -- Prices in gp used when the Grand Exchange price of a rune can't be
    -- fetched. Casts priced this way are marked as estimated in the cost tracker.
    fallback_prices = {
        ["Spirit rune"] = 70,
        ["Bone rune"] = 350,
        ["Flesh rune"] = 640,
        ["Miasma rune"] = 590,
    },

    -- Item ids of Necromancy gear, as reported by the worn inventory
    -- (item.obj.id). Augmented and unaugmented versions have different ids,
    -- so each one has to be listed. The comments are the items' config names.
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
