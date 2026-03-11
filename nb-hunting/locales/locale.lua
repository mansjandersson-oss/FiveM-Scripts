Locales = {
    en = {
        hunter_title = 'Hunter Guild',
        license_required = 'You need a hunting license.',
        buy_license = 'Buy Hunting License',
        license_success = 'You bought a hunting license.',
        no_money = 'You do not have enough money.',
        zone_entered = 'You entered a hunting zone: %s',
        mission_started = 'Mission started: %s',
        mission_completed = 'Mission complete! Reward collected.',
        level_up = 'Level up! You are now level %s.',
        invalid_weapon_level = 'Your level is too low for this weapon.',
        cut_started = 'Cutting animal...',
        no_cut_weapon = 'You need a configured cutting weapon.',
        sold_items = 'Sold hunting goods for $%s.',
        bait_used = 'Bait deployed.',
        call_used = 'Animal call used, nearby animals marked.',
        route_set = 'Route set to %s.',
        leaderboard_title = 'Top Hunters',

        loadout_request = 'Pick up hunting loadout',
        loadout_received = 'Hunting loadout collected.',
        loadout_removed = 'You left the hunting area. Temporary hunting loadout removed.',
        loadout_denied_level = 'Your level is too low for hunting loadout.'
    },
    sv = {
        hunter_title = 'Jaktgillet',
        license_required = 'Du behöver jaktlicens.',
        buy_license = 'Köp jaktlicens',
        license_success = 'Du köpte en jaktlicens.',
        no_money = 'Du har inte tillräckligt med pengar.',
        zone_entered = 'Du gick in i en jaktzon: %s',
        mission_started = 'Uppdrag startat: %s',
        mission_completed = 'Uppdrag klart! Belöning mottagen.',
        level_up = 'Level up! Du är nu level %s.',
        invalid_weapon_level = 'Din level är för låg för detta vapen.',
        cut_started = 'Styckar djur...',
        no_cut_weapon = 'Du behöver ett konfigurerat styckningsvapen.',
        sold_items = 'Sålde jaktvaror för $%s.',
        bait_used = 'Åtel placerad.',
        call_used = 'Djurläte använt, närliggande djur markerade.',
        route_set = 'Rutt satt till %s.',
        leaderboard_title = 'Topplista jägare',

        loadout_request = 'Hämta jaktutrustning',
        loadout_received = 'Du hämtade ut jaktutrustning.',
        loadout_removed = 'Du lämnade jaktområdet. Tillfällig jaktutrustning togs bort.',
        loadout_denied_level = 'Din level är för låg för jaktutrustning.'
    }
}

Locales.de = Locales.de or {}
Locales.es = Locales.es or {}
for key, value in pairs(Locales.en) do
    if Locales.de[key] == nil then Locales.de[key] = value end
    if Locales.es[key] == nil then Locales.es[key] = value end
end

function L(key, ...)
    local lang = Config.Locale or 'en'
    local str = (Locales[lang] and Locales[lang][key]) or Locales.en[key] or key
    if select('#', ...) > 0 then
        return str:format(...)
    end
    return str
end
