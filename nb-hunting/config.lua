Config = {}

Config.Debug = false
Config.Locale = 'sv'
Config.UseLicense = true
Config.LicenseItem = 'hunting_license'
Config.AutoSaveInterval = 5 -- minutes

Config.Items = {
    Meat = 'raw_meat',
    Leather = 'leather',
    Trophy = 'animal_trophy',
    Bait = 'hunting_bait',
    DeerCall = 'deer_call',
    BoarCall = 'boar_call'
}

Config.DiscordWebhook = ''

Config.Levels = {
    [1] = { xp = 0, label = 'Rookie Hunter' },
    [2] = { xp = 250, label = 'Tracker' },
    [3] = { xp = 600, label = 'Skilled Hunter' },
    [4] = { xp = 1100, label = 'Master Hunter' },
    [5] = { xp = 1800, label = 'Apex Hunter' }
}

Config.CuttingTypes = {
    keybind = true,
    melee = true,
    thirdEye = true
}

Config.CuttingWeapons = {
    ['weapon_knife'] = { level = 1, rewardMultiplier = 1.0 },
    ['weapon_machete'] = { level = 2, rewardMultiplier = 1.15 },
    ['weapon_hatchet'] = { level = 3, rewardMultiplier = 1.35 }
}

Config.HunterNPC = {
    model = 'cs_hunter',
    coords = vec4(-679.44, 5836.66, 17.33, 130.77),
    scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
    blip = {
        enabled = true,
        sprite = 141,
        color = 25,
        scale = 0.8,
        label = 'Jägare'
    }
}

Config.HuntingZones = {
    {
        id = 'paleto_forest',
        label = 'Paleto Forest',
        center = vec3(-555.21, 5468.66, 61.1),
        radius = 250.0,
        maxAlive = 6,
        spawnInterval = 30,
        animals = {
            { model = 'a_c_deer', xp = 55, rewards = { { item = Config.Items.Meat, min = 2, max = 4 }, { item = Config.Items.Leather, min = 1, max = 2 } } },
            { model = 'a_c_boar', xp = 70, rewards = { { item = Config.Items.Meat, min = 2, max = 5 }, { item = Config.Items.Leather, min = 1, max = 3 } } }
        }
    },
    {
        id = 'grapeseed_hills',
        label = 'Grapeseed Hills',
        center = vec3(2445.53, 4778.22, 34.64),
        radius = 190.0,
        maxAlive = 5,
        spawnInterval = 40,
        animals = {
            { model = 'a_c_coyote', xp = 65, rewards = { { item = Config.Items.Meat, min = 1, max = 3 }, { item = Config.Items.Trophy, min = 0, max = 1 } } },
            { model = 'a_c_mtlion', xp = 110, rewards = { { item = Config.Items.Meat, min = 3, max = 6 }, { item = Config.Items.Trophy, min = 1, max = 1 } } }
        }
    }
}

Config.Baits = {
    [Config.Items.Bait] = {
        radius = 65.0,
        duration = 90,
        cooldown = 180,
        allowedAnimals = { 'a_c_deer', 'a_c_boar', 'a_c_coyote' }
    }
}

Config.Calls = {
    [Config.Items.DeerCall] = {
        pingDuration = 25,
        cooldown = 60,
        targetModels = { 'a_c_deer' }
    },
    [Config.Items.BoarCall] = {
        pingDuration = 25,
        cooldown = 60,
        targetModels = { 'a_c_boar' }
    }
}

Config.Shops = {
    buy = {
        coords = vec3(-676.71, 5837.95, 17.33),
        -- Köp är avstängt för jaktutrustning. Utrustning hämtas via NPC-menyn och tas bort utanför jaktzon.
        items = {}
    },
    sell = {
        coords = vec3(-672.81, 5793.56, 17.33),
        items = {
            { item = Config.Items.Meat, price = 95, level = 1 },
            { item = Config.Items.Leather, price = 120, level = 2 },
            { item = Config.Items.Trophy, price = 425, level = 3 }
        }
    }
}


Config.FreeLoadout = {
    enabled = true,
    removeOnLeaveZone = true,
    items = {
        { item = Config.Items.Bait, count = 3, level = 1 },
        { item = Config.Items.DeerCall, count = 1, level = 1 },
        { item = Config.Items.BoarCall, count = 1, level = 2 },
        { item = 'weapon_marksmanpistol', count = 1, level = 1 },
        { item = 'weapon_precisionrifle', count = 1, level = 2 },
        { item = 'ammo-rifle', count = 80, level = 2 }
    }
}

Config.Missions = {
    {
        id = 'deer_cleanup',
        label = 'Rensa skogen',
        description = 'Jaga 3 hjortar i Paleto Forest',
        objective = { model = 'a_c_deer', amount = 3 },
        reward = { money = 1300, xp = 220 },
        cooldown = 30
    },
    {
        id = 'boar_hunt',
        label = 'Vildsvinsrundan',
        description = 'Jaga 2 vildsvin i valfri zon',
        objective = { model = 'a_c_boar', amount = 2 },
        reward = { money = 1800, xp = 260 },
        cooldown = 45
    },
    {
        id = 'coyote_patrol',
        label = 'Kojotpatrull',
        description = 'Eliminera 4 kojoter vid Grapeseed Hills',
        objective = { model = 'a_c_coyote', amount = 4 },
        reward = { money = 2400, xp = 320 },
        cooldown = 50
    },
    {
        id = 'forest_supplier',
        label = 'Skogens leverans',
        description = 'Fäll 2 hjortar för köttleverans till jaktstugan',
        objective = { model = 'a_c_deer', amount = 2 },
        reward = { money = 2100, xp = 280 },
        cooldown = 35
    },
    {
        id = 'alpha_predator',
        label = 'Rovdjursjägaren',
        description = 'Jaga 1 mountain lion i Grapeseed Hills',
        objective = { model = 'a_c_mtlion', amount = 1 },
        reward = { money = 3000, xp = 420 },
        cooldown = 60
    },
    {
        id = 'boar_control',
        label = 'Vildsvinskontroll',
        description = 'Jaga 5 vildsvin för att skydda området',
        objective = { model = 'a_c_boar', amount = 5 },
        reward = { money = 3400, xp = 450 },
        cooldown = 70
    }
}

Config.WeaponLevelRequirements = {
    ['weapon_marksmanpistol'] = 1,
    ['weapon_precisionrifle'] = 2,
    ['weapon_sniperrifle'] = 4
}

Config.StoresLevelRequirement = {
    buy = 1,
    sell = 1
}

Config.EnableMissionBroadcast = true
Config.EnableSync = true

Config.Exports = {
    GetHunterLevel = 'GetHunterLevel',
    GetHunterXP = 'GetHunterXP'
}
