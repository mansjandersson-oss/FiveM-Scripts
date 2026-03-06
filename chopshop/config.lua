Config = {}

Config.Debug = false
Config.Locale = 'sv'

-- Inventariesystem att använda: 'ox_inventory' eller 'qb-inventory'
Config.Inventory = 'ox_inventory'

-- ─── Inställningar för kriminellt kontrakt ───────────────────────────────────
Config.Criminal = {
    vehicleCount  = 3,       -- fordon per kontrakt
    cooldown      = 1800,    -- sekunder innan ett nytt kontrakt är tillgängligt
    minReward     = 50,      -- minsta antal pengar-item som betalas vid inlämning
    maxReward     = 100,     -- högsta antal pengar-item som betalas vid inlämning
    policeRequired = 0,      -- minsta antal poliser i tjänst
}

-- ─── Inställningar för civilt jobb ───────────────────────────────────────────
Config.Civilian = {
    cooldown      = 600,                         -- sekunder mellan jobb
    rewardPerPart = { min = 1, max = 3   },      -- antal pengar-item per sålt material
    frameBonus    = { min = 5, max = 15  },      -- bonus i pengar-item för att demontera ramen
    -- Material som kan säljas till den civila skrotaren
    sellableParts = { 'scrap_metal', 'aluminum', 'rubber', 'glass', 'plastic', 'steel' },
}

-- ─── NPC-definitioner ─────────────────────────────────────────────────────────
Config.NPCs = {
    criminal = {
        name   = 'chop_criminal_npc',
        model  = 'g_m_m_chigoon_01',
        coords = vec4(947.51, -3096.07, 5.9, 182.17),
        blip   = { enabled = true, sprite = 61,  color = 1, scale = 0.8, labelKey = 'blip_criminal_npc' }
    },
    civilian = {
        name   = 'chop_civilian_npc',
        model  = 's_m_m_mech_01',
        coords = vec4(-359.22, -136.88, 39.43, 68.21),
        blip   = { enabled = true, sprite = 431, color = 3, scale = 0.8, labelKey = 'blip_civilian_npc' }
    }
}

-- ─── Chop-zon ────────────────────────────────────────────────────────────────
Config.ChopZone = {
    coords                  = vec3(1174.81, -3198.67, 5.07),
    size                    = vec3(25.0, 25.0, 4.0),
    rotation                = 270.0,
    vehicleDetectionDistance = 8.0,   -- meter: hur nära ett fordon måste vara för att visa demonteringsval
    blip                    = { enabled = true, sprite = 50, color = 4, scale = 0.8, labelKey = 'blip_chop_zone' }
}

-- ─── Kontraktsfordon (kriminell) ─────────────────────────────────────────────
-- Dessa fordonsmodeller väljs slumpmässigt för varje kontrakt.
Config.ContractVehicles = {
    { model = 'sultan',    label = 'Sultan'    },
    { model = 'dominator', label = 'Dominator' },
    { model = 'elegy2',    label = 'Elegy RH8' },
    { model = 'futo',      label = 'Futo'      },
    { model = 'kuruma',    label = 'Kuruma'    },
    { model = 'sentinel',  label = 'Sentinel'  },
    { model = 'buffalo',   label = 'Buffalo'   },
    { model = 'banshee',   label = 'Banshee'   },
    { model = 'jester',    label = 'Jester'    },
    { model = 'feltzer2',  label = 'Feltzer'   },
    { model = 'comet2',    label = 'Comet'     },
    { model = 'exemplar',  label = 'Exemplar'  },
}

-- Spawnpunkter för kontraktsfordon i världen
Config.ContractSpawnPoints = {
    vec4(-703.37,  -930.17,  19.22, 270.0),
    vec4(-1081.29, -841.42,   4.94, 185.0),
    vec4( 149.06, -1001.45,  29.37, 340.0),
    vec4( 408.75, -1634.51,  29.29,  90.0),
    vec4(-237.94, -1340.09,  31.33, 180.0),
    vec4(1161.19,  -779.66,  58.15,  90.0),
    vec4(-542.65,  -197.74,  37.67,  90.0),
    vec4( 221.74,  -798.37,  30.71, 355.0),
}

-- ─── Civila demonteringsfordon ───────────────────────────────────────────────
Config.CivilianVehicles = {
    { model = 'blista',     label = 'Blista'     },
    { model = 'panto',      label = 'Panto'      },
    { model = 'issi2',      label = 'Issi'       },
    { model = 'prairie',    label = 'Prairie'    },
    { model = 'ingot',      label = 'Ingot'      },
    { model = 'dilettante', label = 'Dilettante' },
}

-- Spawnpunkt för civilt fordon (nära civila NPC:n)
Config.CivilianVehicleSpawn = vec4(-356.05, -130.21, 38.31, 248.31)

-- ─── Delar att demontera från varje fordon ───────────────────────────────────
Config.StripParts = {
    { name = 'driver_door',    labelKey = 'strip_driver_door',    item = 'car_door',      duration = 8000, icon = 'fa-solid fa-car-side'          },
    { name = 'passenger_door', labelKey = 'strip_passenger_door', item = 'car_door',      duration = 8000, icon = 'fa-solid fa-car-side'          },
    { name = 'rear_left_door',  labelKey = 'strip_rear_left_door',  item = 'car_door',      duration = 8000, icon = 'fa-solid fa-car-side'          },
    { name = 'rear_right_door', labelKey = 'strip_rear_right_door', item = 'car_door',      duration = 8000, icon = 'fa-solid fa-car-side'          },
    { name = 'hood',           labelKey = 'strip_hood',           item = 'car_hood',      duration = 6000, icon = 'fa-solid fa-car'               },
    { name = 'trunk',          labelKey = 'strip_trunk',          item = 'car_trunk_lid', duration = 6000, icon = 'fa-solid fa-box'               },
}

-- Sista demonteringssteg: tar bort ramen och despawnar fordonet
Config.FrameStrip = {
    name       = 'frame',
    labelKey   = 'strip_frame',
    scrapItem  = 'scrap_metal',
    scrapCount = { min = 2, max = 4 },
    duration   = 15000,
}

-- ─── Itemnamn (måste matcha dina inventarie-items) ──────────────────────────
Config.Items = {
    car_door      = 'car_door',
    car_hood      = 'car_hood',
    car_trunk_lid = 'car_trunk_lid',
    scrap_metal   = 'scrap_metal',
    auto_parts    = 'auto_parts',
    -- Betalningsitem: sätt till det din server använder för pengar (t.ex. 'money')
    money         = 'money',
    -- Kontraktsitem som ges till spelaren när ett kriminellt kontrakt utfärdas.
    -- Om detta item används efter en krasch återställs det aktiva kontraktet.
    chop_contract = 'chop_contract',
}

-- ─── Materialbelöningar från fordon ──────────────────────────────────────────
-- Varje rad slås separat vid varje belöningshändelse.
-- chance: sannolikhet i procent (0-100) att itemet ges.
Config.MaterialRewards = {
    { item = 'rubber',      chance = 70, count = { min = 1, max = 3 } },
    { item = 'steel',       chance = 60, count = { min = 1, max = 3 } },
    { item = 'aluminum',    chance = 50, count = { min = 1, max = 2 } },
    { item = 'copper',      chance = 40, count = { min = 1, max = 2 } },
    { item = 'plastic',     chance = 65, count = { min = 1, max = 3 } },
    { item = 'glass',       chance = 35, count = { min = 1, max = 2 } },
}

-- ─── Inställningar för skill-check minispel ──────────────────────────────────
Config.Minigames = {
    StripPart = {
        stages = { 'easy', 'medium' },
        keys   = { 'w', 'a', 's', 'd' }
    },
    StripFrame = {
        stages = { 'medium', 'hard', 'hard' },
        keys   = { 'w', 'a', 's', 'd' }
    }
}

-- ─── Övriga tider ────────────────────────────────────────────────────────────
Config.ModelLoadTimeout        = 5000   -- ms att vänta på modellinladdning innan avbrott
Config.NetworkControlTimeout   = 3000   -- ms att vänta på nätverkskontroll av fordon
Config.Animations = {
    door  = { dict = 'mini@repair',                        clip = 'fixing_a_ped', flag = 1 },
    hood  = { dict = 'amb@world_human_hammering@male@base', clip = 'base',        flag = 1 },
    trunk = { dict = 'mini@repair',                        clip = 'fixing_a_ped', flag = 1 },
    frame = { dict = 'amb@world_human_hammering@male@base', clip = 'base',        flag = 1 },
}
