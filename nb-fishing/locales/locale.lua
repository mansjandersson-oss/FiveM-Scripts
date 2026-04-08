local Translations = {
    sv = {
        no_rod = 'Du behöver ett fiskespö.',
        no_bait = 'Du behöver bete för att fiska här.',
        level_locked = 'Din fisknivå är för låg för detta vatten.',
        cast_started = 'Kastat ut linan... håll fokus!',
        catch_success = 'Du fångade en [%s | %s] %s (%.2fkg)!',
        catch_failed = 'Fisken slet sig.',
        rod_broken = 'Ditt fiskespö gick sönder.',
        rod_durability = 'Spö-hållbarhet: %s/%s användningar',
        xp_gain = '+%s fiske-XP',
        skill_point = 'Du fick en fiskeskill-poäng.',
        level_up = 'Nivå upp i fiske! Du är nu nivå %s.',
        sold_fish = 'Sålde fisk för $%s.',
        tournament_started = 'Fisketurnering startad! Fånga din största fisk.',
        tournament_ended = 'Turneringen är slut. Kolla topplistan för vinnare.',
        already_maxed = 'Denna skill är redan maxad.',
        no_points = 'Du har inga skill-poäng kvar.',
        skill_upgraded = 'Uppgraderade %s till nivå %s.',
        leaderboard_title = 'Fiske-topplista'
    }
}

local locale = Config and Config.Locale or 'sv'

function L(key, ...)
    local dict = Translations[locale] or Translations.sv
    local phrase = dict[key] or key
    if select('#', ...) > 0 then
        return phrase:format(...)
    end
    return phrase
end
