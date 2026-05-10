Config = {}

Config.Debug = false
Config.Locale = 'sv'

-- Debugläge för lokal felsökning utan externa exports.
-- Sätt Config.Debug = true för att aktivera valen nedan.
Config.DebugOptions = {
    verbose = true,              -- skriver extra [nb-chopshop:debug]-rader i server console/F8
    bypassRoleCheck = true,      -- hoppar över RoleCheckExport och CriminalAccess
    forcedRoute = 'criminal',    -- 'criminal', 'both' ger access, allt annat nekar
    ignoreCooldown = true,       -- hoppar över kontrakts-cooldown
    ignorePolice = true,         -- hoppar över Config.Criminal.policeRequired
}

-- Inventory system: 'ox_inventory' eller 'qb-inventory'
Config.Inventory = 'ox_inventory'

Config.Criminal = {
    vehicleCount = 3,
    cooldown = 1800,
    minReward = 500,
    maxReward = 1000,
    policeRequired = 0,
}

Config.NPCs = {
    main = {
        name = 'chop_main_npc',
        model = 'g_m_m_chigoon_01',
        coords = vec4(257.55, -1801.48, 27.11, 56.98),
        blip = { enabled = true, sprite = 61, color = 1, scale = 0.8, labelKey = 'blip_main_npc' },
    },
}

-- Optional role/alignment export. Returnera 'criminal', 'both', true, eller table med isCriminal = true.
Config.RoleCheckExport = {
    resource = 'nb-skilltree',
    func = 'GetActiveAlignment',
    passServerId = true,
}

-- Fallback om exporten saknas eller inte svarar. Servern kontrollerar alltid access.
Config.CriminalAccess = {
    jobs = {},
    gangs = {
        ballas = true,
        vagos = true,
        families = true,
        lostmc = true,
        cartel = true,
        mafia = true,
    },
}

Config.ChopZone = {
    coords = vec3(294.84, -1722.37, 29.32),
    radius = 30.0,
    vehicleDetectionDistance = 8.0,
    blip = { enabled = true, sprite = 50, color = 4, scale = 0.8, labelKey = 'blip_chop_zone' },
}

-- Kontraktsfordon spawnas inte. Spelaren maste hitta dessa modeller ute pa gatorna.
Config.ContractVehicles = {
    { model = 'sultan', label = 'Sultan' },
    { model = 'dominator', label = 'Dominator' },
    { model = 'elegy2', label = 'Elegy RH8' },
    { model = 'futo', label = 'Futo' },
    { model = 'kuruma', label = 'Kuruma' },
    { model = 'sentinel', label = 'Sentinel' },
    { model = 'buffalo', label = 'Buffalo' },
    { model = 'banshee', label = 'Banshee' },
    { model = 'jester', label = 'Jester' },
    { model = 'feltzer2', label = 'Feltzer' },
    { model = 'comet2', label = 'Comet' },
    { model = 'exemplar', label = 'Exemplar' },
}

Config.StripParts = {
    { name = 'driver_door', labelKey = 'strip_driver_door', item = 'car_door', duration = 8000, icon = 'fa-solid fa-car-side' },
    { name = 'passenger_door', labelKey = 'strip_passenger_door', item = 'car_door', duration = 8000, icon = 'fa-solid fa-car-side' },
    { name = 'rear_left_door', labelKey = 'strip_rear_left_door', item = 'car_door', duration = 8000, icon = 'fa-solid fa-car-side' },
    { name = 'rear_right_door', labelKey = 'strip_rear_right_door', item = 'car_door', duration = 8000, icon = 'fa-solid fa-car-side' },
    { name = 'hood', labelKey = 'strip_hood', item = 'car_hood', duration = 6000, icon = 'fa-solid fa-car' },
    { name = 'trunk', labelKey = 'strip_trunk', item = 'car_trunk_lid', duration = 6000, icon = 'fa-solid fa-box' },
}

Config.FrameStrip = {
    name = 'frame',
    labelKey = 'strip_frame',
    scrapItem = 'scrap_metal',
    scrapCount = { min = 2, max = 4 },
    duration = 15000,
}

Config.Items = {
    money = 'money',
    chop_contract = 'chop_contract',
}

Config.MaterialRewards = {
    { item = 'rubber', chance = 70, count = { min = 1, max = 3 } },
    { item = 'steel', chance = 60, count = { min = 1, max = 3 } },
    { item = 'aluminum', chance = 50, count = { min = 1, max = 2 } },
    { item = 'copper', chance = 40, count = { min = 1, max = 2 } },
    { item = 'plastic', chance = 65, count = { min = 1, max = 3 } },
    { item = 'glass', chance = 35, count = { min = 1, max = 2 } },
}

Config.Minigames = {
    StripPart = {
        stages = { 'easy' },
        keys = { 'w', 'a', 's', 'd' },
    },
    StripFrame = {
        stages = { 'easy', 'medium' },
        keys = { 'w', 'a', 's', 'd' },
    },
}

Config.ModelLoadTimeout = 5000
Config.NetworkControlTimeout = 3000

Config.Animations = {
    door = { dict = 'mini@repair', clip = 'fixing_a_ped', flag = 1 },
    hood = { dict = 'amb@world_human_hammering@male@base', clip = 'base', flag = 1 },
    trunk = { dict = 'mini@repair', clip = 'fixing_a_ped', flag = 1 },
    frame = { dict = 'amb@world_human_hammering@male@base', clip = 'base', flag = 1 },
}
