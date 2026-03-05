Config = {}

Config.Debug = false
Config.Locale = 'en'

-- Inventory system to use: 'ox_inventory' or 'qb-inventory'
Config.Inventory = 'ox_inventory'

-- ─── Criminal contract settings ───────────────────────────────────────────────
Config.Criminal = {
    vehicleCount  = 3,       -- vehicles per contract
    cooldown      = 1800,    -- seconds before a new contract is available
    minReward     = 50,      -- minimum money-item count paid on contract turn-in
    maxReward     = 100,     -- maximum money-item count paid on contract turn-in
    policeRequired = 0,      -- minimum police on duty required
}

-- ─── Civilian job settings ────────────────────────────────────────────────────
Config.Civilian = {
    cooldown      = 600,                         -- seconds between jobs
    rewardPerPart = { min = 1, max = 3   },      -- money-item count per sold material
    frameBonus    = { min = 5, max = 15  },      -- money-item count bonus for stripping the frame
    -- Materials that can be sold to the civilian dismantler
    sellableParts = { 'scrap_metal', 'aluminum', 'rubber', 'glass', 'plastic', 'steel' },
}

-- ─── NPC definitions ──────────────────────────────────────────────────────────
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
        coords = vec4(-352.14, -135.95, 38.31, 248.31),
        blip   = { enabled = true, sprite = 431, color = 3, scale = 0.8, labelKey = 'blip_civilian_npc' }
    }
}

-- ─── Chop zone ────────────────────────────────────────────────────────────────
Config.ChopZone = {
    coords                  = vec3(1174.81, -3198.67, 5.07),
    size                    = vec3(25.0, 25.0, 4.0),
    rotation                = 270.0,
    vehicleDetectionDistance = 8.0,   -- metres: how close a vehicle must be to show strip options
    blip                    = { enabled = true, sprite = 50, color = 4, scale = 0.8, labelKey = 'blip_chop_zone' }
}

-- ─── Contract vehicles (criminal) ────────────────────────────────────────────
-- These vehicle models are randomly selected for each contract.
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

-- Spawn points used for contract vehicles in the world
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

-- ─── Civilian dismantling vehicles ────────────────────────────────────────────
Config.CivilianVehicles = {
    { model = 'blista',     label = 'Blista'     },
    { model = 'panto',      label = 'Panto'      },
    { model = 'issi2',      label = 'Issi'       },
    { model = 'prairie',    label = 'Prairie'    },
    { model = 'ingot',      label = 'Ingot'      },
    { model = 'dilettante', label = 'Dilettante' },
}

-- Spawn point for the civilian vehicle (near the civilian NPC)
Config.CivilianVehicleSpawn = vec4(-356.05, -130.21, 38.31, 248.31)

-- ─── Parts to strip from each vehicle ────────────────────────────────────────
Config.StripParts = {
    { name = 'driver_door',    labelKey = 'strip_driver_door',    item = 'car_door',      duration = 8000, icon = 'fa-solid fa-car-side'          },
    { name = 'passenger_door', labelKey = 'strip_passenger_door', item = 'car_door',      duration = 8000, icon = 'fa-solid fa-car-side'          },
    { name = 'rear_left_door',  labelKey = 'strip_rear_left_door',  item = 'car_door',      duration = 8000, icon = 'fa-solid fa-car-side'          },
    { name = 'rear_right_door', labelKey = 'strip_rear_right_door', item = 'car_door',      duration = 8000, icon = 'fa-solid fa-car-side'          },
    { name = 'hood',           labelKey = 'strip_hood',           item = 'car_hood',      duration = 6000, icon = 'fa-solid fa-car'               },
    { name = 'trunk',          labelKey = 'strip_trunk',          item = 'car_trunk_lid', duration = 6000, icon = 'fa-solid fa-box'               },
}

-- Final strip step: removes the frame and despawns the vehicle
Config.FrameStrip = {
    name       = 'frame',
    labelKey   = 'strip_frame',
    scrapItem  = 'scrap_metal',
    scrapCount = { min = 2, max = 4 },
    duration   = 15000,
}

-- ─── Item names (match your inventory item names) ────────────────────────────
Config.Items = {
    car_door      = 'car_door',
    car_hood      = 'car_hood',
    car_trunk_lid = 'car_trunk_lid',
    scrap_metal   = 'scrap_metal',
    auto_parts    = 'auto_parts',
    -- Payment item: set to whatever your server uses for cash (e.g. 'black_money', 'money')
    money         = 'money',
    -- Contract item given to the player when a criminal contract is issued.
    -- Using this item after a crash restores the active contract.
    chop_contract = 'chop_contract',
}

-- ─── Vehicle material rewards ─────────────────────────────────────────────────
-- Each entry is rolled independently at every reward event.
-- chance: 0-100 percentage probability this item is awarded.
Config.MaterialRewards = {
    { item = 'rubber',      chance = 70, count = { min = 1, max = 3 } },
    { item = 'steel',       chance = 60, count = { min = 1, max = 3 } },
    { item = 'aluminum',    chance = 50, count = { min = 1, max = 2 } },
    { item = 'copper',      chance = 40, count = { min = 1, max = 2 } },
    { item = 'plastic',     chance = 65, count = { min = 1, max = 3 } },
    { item = 'glass',       chance = 35, count = { min = 1, max = 2 } },
}

-- ─── Skill-check minigame configs ────────────────────────────────────────────
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

-- ─── Misc timings ─────────────────────────────────────────────────────────────
Config.ModelLoadTimeout        = 5000   -- ms to wait for a model to load before giving up
Config.NetworkControlTimeout   = 3000   -- ms to wait for network control of a vehicle
Config.Animations = {
    door  = { dict = 'mini@repair',                        clip = 'fixing_a_ped', flag = 1 },
    hood  = { dict = 'amb@world_human_hammering@male@base', clip = 'base',        flag = 1 },
    trunk = { dict = 'mini@repair',                        clip = 'fixing_a_ped', flag = 1 },
    frame = { dict = 'amb@world_human_hammering@male@base', clip = 'base',        flag = 1 },
}
