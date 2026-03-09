Config = {}

Config.Debug = false
Config.Locale = 'sv'

Config.MissionGiver = {
    model = `g_m_y_lost_01`,
    coords = vec4(170.14, -1799.27, 28.31, 145.0),
    scenario = 'WORLD_HUMAN_SMOKING'
}

Config.VehicleModels = {
    `sultan`,
    `schafter2`,
    `tailgater`,
    `felon`
}

Config.VehicleSpawns = {
    vec4(235.49, -777.11, 30.63, 158.0),
    vec4(-39.52, -1110.9, 26.44, 67.0),
    vec4(1211.13, -1389.14, 35.38, 85.0),
    vec4(914.42, -171.22, 74.35, 236.0)
}

Config.DeliveryGarage = vec3(966.23, -1812.45, 31.22)

Config.DecryptSeconds = 600
Config.PolicePingInterval = 10 -- seconds
Config.PoliceBlipDuration = 20 -- seconds
Config.MinPolice = 1

Config.Reward = {
    type = 'cash', -- cash | bank
    amount = 9000
}

Config.Text = {
    sv = {
        npc_target = 'Prata om biljobb',
        menu_title = 'Svart marknad - Biljobb',
        menu_desc = 'Stjäl en bil, dekryptera den och leverera till ett gömt garage.',
        menu_accept = 'Ta uppdrag',
        menu_cancel = 'Inte nu',
        mission_already = 'Du har redan ett aktivt uppdrag.',
        mission_started = 'Uppdrag startat! Stjäl bilen som markerats på GPS.',
        vehicle_marked = 'Målbil markerad.',
        hack_start = 'Kopplar in dekrypterare...',
        hack_failed = 'Du misslyckades med att koppla in dekrypteraren.',
        decrypt_started = 'Dekryptering startad (10 minuter). Kör till det gömda garaget.',
        decrypt_tick = 'Dekryptering klar om %s minuter.',
        decrypt_countdown = 'Dekryptering: %s',
        decrypt_done = 'Dekryptering klar! Leverera bilen vid det gömda garaget.',
        deliver_hint = '[E] Leverera bilen i garaget',
        mission_complete = 'Snyggt. Bilen är levererad och du fick betalt.',
        too_far = 'Du måste stå vid leveransplatsen med målbilen.',
        police_ping = 'Stulen bil spårad! Ny GPS-ping inkom.',
        mission_cancelled = 'Uppdraget avbröts.'
    }
}
