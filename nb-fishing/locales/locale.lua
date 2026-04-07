local Translations = {
    en = {
        no_rod = 'You need a fishing rod.',
        no_bait = 'You need bait to fish here.',
        level_locked = 'Fishing level too low for this water.',
        cast_started = 'Line cast... keep focus!',
        catch_success = 'You caught a [%s | %s] %s (%.2fkg)!',
        catch_failed = 'The fish got away.',
        xp_gain = '+%s fishing XP',
        skill_point = 'You gained a fishing skill point.',
        level_up = 'Fishing level up! You are now level %s.',
        sold_fish = 'Sold fish for $%s.',
        tournament_started = 'Fishing tournament started! Land your best fish.',
        tournament_ended = 'Tournament finished. Check the leaderboard for winners.',
        already_maxed = 'Skill is already maxed.',
        no_points = 'No skill points available.',
        skill_upgraded = 'Upgraded %s to level %s.',
        leaderboard_title = 'Fishing Leaderboard'
    }
}

local locale = Config and Config.Locale or 'en'

function L(key, ...)
    local dict = Translations[locale] or Translations.en
    local phrase = dict[key] or key
    if select('#', ...) > 0 then
        return phrase:format(...)
    end
    return phrase
end
