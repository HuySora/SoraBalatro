local upgradeMapping = {
    foil = { 
        level = 1, -- Using this to decide new edition higher or lower compared to current edition
        nextEdition = 'holo', -- Using this to decide which edition does this edition upgraded to
        editionStr = 'e_foil',
    },
    holo = {
        level = 2,
        nextEdition = 'polychrome',
        editionStr = 'e_holo',
    },
    polychrome = {
        level = 3,
        nextEdition = 'negative',
        editionStr = 'e_polychrome',
    },
    negative = {
        level = 4,
        nextEdition = 'negative',
        editionStr = 'e_negative',
    }  -- No further upgrade from negative
}

local function get_eligible_strength_jokers()
    -- Idk how to cache this yet
    local eligible_strength_jokers = {}

    -- First, check for jokers without any edition
    for k, v in pairs(G.jokers.cards) do
        if v.ability.set == 'Joker' and (not v.edition) then
            table.insert(eligible_strength_jokers, v)
        end
    end
    -- If no eligible jokers found, check for jokers with foil edition
    if not next(eligible_strength_jokers) then
        for k, v in pairs(G.jokers.cards) do
            if v.ability.set == 'Joker' and v.edition and v.edition.type == 'foil' then
                table.insert(eligible_strength_jokers, v)
            end
        end
    end
    -- If still no eligible jokers found, check for hologram edition
    if not next(eligible_strength_jokers) then
        for k, v in pairs(G.jokers.cards) do
            if v.ability.set == 'Joker' and v.edition and v.edition.type == 'holo' then
                table.insert(eligible_strength_jokers, v)
            end
        end
    end
    -- If still no eligible jokers found, check for polychrome edition
    if not next(eligible_strength_jokers) then
        for k, v in pairs(G.jokers.cards) do
            if v.ability.set == 'Joker' and v.edition and v.edition.type == 'polychrome' then
                table.insert(eligible_strength_jokers, v)
            end
        end
    end

    return eligible_strength_jokers
end

SMODS.Consumable:take_ownership('wheel_of_fortune', {
    can_use = function(self, card)
        return next(get_eligible_strength_jokers());
    end,
    use = function(self, card)
        if pseudorandom('wheel_of_fortune') >= G.GAME.probabilities.normal/card.ability.extra then
            G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.4, func = function()
                attention_text({
                    text = localize('k_nope_ex'),
                    scale = 1.3, 
                    hold = 1.4,
                    major = used_tarot,
                    backdrop_colour = G.C.SECONDARY_SET.Tarot,
                    align = (G.STATE == G.STATES.TAROT_PACK or G.STATE == G.STATES.SPECTRAL_PACK) and 'tm' or 'cm',
                    offset = {x = 0, y = (G.STATE == G.STATES.TAROT_PACK or G.STATE == G.STATES.SPECTRAL_PACK) and -0.2 or 0},
                    silent = true
                    })
                    G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.06*G.SETTINGS.GAMESPEED, blockable = false, blocking = false, func = function()
                        play_sound('tarot2', 0.76, 0.4);
                        return true
                    end}))
                    play_sound('tarot2', 1, 0.4)
            return true end }))
            delay(0.6)
            -- Exit
            return
        end

        local eligible_strength_jokers = get_eligible_strength_jokers() or {}
        G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.4, func = function()
            local eligible_card = pseudorandom_element(eligible_strength_jokers, pseudoseed('wheel_of_fortune'))
            local new_edition = poll_edition('wheel_of_fortune', nil, true, true)
            local curr_edition = eligible_card.edition
            
            if new_edition and curr_edition then
                -- Based on vanilla source code lol
                local newEditionLv = 0
                if new_edition.foil then
                    newEditionLv = upgradeMapping['foil'].level
                elseif new_edition.holo then
                    newEditionLv = upgradeMapping['holo'].level
                elseif new_edition.polychrome then
                    newEditionLv = upgradeMapping['polychrome'].level
                elseif new_edition.negative then
                    newEditionLv = upgradeMapping['negative'].level
                end
                local currEditionLv = upgradeMapping[curr_edition.type].level

                -- Determine next edition
                if newEditionLv > currEditionLv then
                    -- It's an upgrade
                    eligible_card:set_edition(new_edition, true)
                else
                    -- It's a downgrade, upgrade to the next edition instead
                    local nextEditionKey = upgradeMapping[curr_edition.type].nextEdition
                    local nextEditionStr = upgradeMapping[nextEditionKey].editionStr
                    eligible_card:set_edition(nextEditionStr, true, false)
                end
            else
                -- If there's no current edition, just set the new edition (vanilla)
                eligible_card:set_edition(new_edition, true)
            end
            check_for_unlock({type = 'have_edition'})
            delay(0.6)
            return true
        end}))
    end
})