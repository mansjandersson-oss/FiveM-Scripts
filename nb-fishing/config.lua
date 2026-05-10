Config = {}

Config.Debug = false
Config.Locale = 'sv'
Config.AutoSaveInterval = 5 -- minutes

Config.UseSkillChecks = true
Config.UseDurability = true
Config.RodDurability = {
    BaseUses = 100,
    CatchLoss = 2,
    EscapeLoss = 7
}
Config.DefaultCatchWindow = 14.0
Config.FailCooldown = 2

Config.Items = {
    Rod = 'fishing_rod',
    Bait = 'fishing_bait',
    Ticket = 'fishing_tournament_ticket'
}

Config.DiscordWebhook = ''

Config.Levels = {
    [1] = { xp = 0, label = 'Nybörjare vid dammen' },
    [2] = { xp = 160, label = 'Bryggfiskare' },
    [3] = { xp = 420, label = 'Åfiskare' },
    [4] = { xp = 900, label = 'Tidjägare' },
    [5] = { xp = 1600, label = 'Sjöman' },
    [6] = { xp = 2550, label = 'Djuphavsproffs' }
}

Config.Minigame = {
    barRisePerSecond = 0.9,
    barFallPerSecond = 0.72,
    captureFillPerSecond = 0.28,
    captureDrainPerSecond = 0.24,
    fishSpeedMin = 0.15,
    fishSpeedMax = 0.45,
    fishAggressionMultiplier = 1.0,
    barHeight = 0.18,
    perfectThreshold = 0.82
}


Config.FishTiers = {
    common = { label = 'Vanlig', xpMultiplier = 1.0, payoutMultiplier = 1.0, color = '#9ca3af' },
    uncommon = { label = 'Ovanlig', xpMultiplier = 1.12, payoutMultiplier = 1.18, color = '#60a5fa' },
    rare = { label = 'Sällsynt', xpMultiplier = 1.25, payoutMultiplier = 1.42, color = '#a78bfa' },
    epic = { label = 'Episk', xpMultiplier = 1.45, payoutMultiplier = 1.75, color = '#f472b6' },
    legendary = { label = 'Legendarisk', xpMultiplier = 1.8, payoutMultiplier = 2.35, color = '#f59e0b' }
}

Config.SizeClasses = {
    { id = 'tiny', label = 'Pytteliten', minPercent = 0.0, payoutMultiplier = 0.75, xpMultiplier = 0.85 },
    { id = 'small', label = 'Liten', minPercent = 0.2, payoutMultiplier = 0.95, xpMultiplier = 0.95 },
    { id = 'medium', label = 'Mellan', minPercent = 0.45, payoutMultiplier = 1.0, xpMultiplier = 1.0 },
    { id = 'large', label = 'Stor', minPercent = 0.68, payoutMultiplier = 1.2, xpMultiplier = 1.15 },
    { id = 'huge', label = 'Enorm', minPercent = 0.86, payoutMultiplier = 1.45, xpMultiplier = 1.35 }
}

Config.Shops = {
    {
        label = 'Del Perro Fiskehandel',
        coords = vec3(-1836.61, -1203.88, 13.02),
        items = {
            { item = Config.Items.Rod, price = 750, minLevel = 1 },
            { item = Config.Items.Bait, price = 25, minLevel = 1 }
        }
    }
}

Config.SellNPC = {
    label = 'Fiskhandlare',
    model = 'a_m_m_farmer_01',
    coords = vec4(-1815.84, -1193.36, 13.02, 332.0),
    scenario = 'WORLD_HUMAN_CLIPBOARD',
    targetRadius = 2.0,
    blip = {
        enabled = true,
        sprite = 356,
        color = 3,
        scale = 0.75,
        label = 'Fiskuppköpare'
    }
}

Config.Zones = {
    {
        id = 'del_perro_pier',
        label = 'Del Perro Pier',
        center = vec3(-1848.12, -1242.71, 8.62),
        radius = 120.0,
        minLevel = 1,
        xpMultiplier = 1.0,
        species = {
            { item = 'anchovy', label = 'Ansjovis', tier = 'common', minWeight = 0.3, maxWeight = 1.0, rarity = 42, xp = 30, price = 45, difficulty = 0.9 },
            { item = 'mackerel', label = 'Makrill', tier = 'uncommon', minWeight = 0.8, maxWeight = 2.1, rarity = 25, xp = 46, price = 85, difficulty = 1.1 },
            { item = 'sea_bass', label = 'Havsabborre', tier = 'uncommon', minWeight = 1.2, maxWeight = 3.4, rarity = 16, xp = 62, price = 125, difficulty = 1.25 },
            { item = 'squid', label = 'Bläckfisk', tier = 'rare', minWeight = 0.5, maxWeight = 2.4, rarity = 11, xp = 74, price = 165, difficulty = 1.35 },
            { item = 'golden_tuna', label = 'Gyllene tonfisk', tier = 'epic', minWeight = 4.0, maxWeight = 9.2, rarity = 6, xp = 132, price = 340, difficulty = 1.6 }
        }
    },
    {
        id = 'alamo_lake',
        label = 'Alamo Lake',
        center = vec3(1335.72, 4237.62, 33.91),
        radius = 155.0,
        minLevel = 2,
        xpMultiplier = 1.22,
        species = {
            { item = 'perch', label = 'Abborre', tier = 'common', minWeight = 0.6, maxWeight = 1.8, rarity = 34, xp = 44, price = 70, difficulty = 1.0 },
            { item = 'pike', label = 'Gädda', tier = 'uncommon', minWeight = 1.6, maxWeight = 4.4, rarity = 28, xp = 75, price = 160, difficulty = 1.28 },
            { item = 'salmon', label = 'Lax', tier = 'rare', minWeight = 2.0, maxWeight = 5.8, rarity = 22, xp = 88, price = 220, difficulty = 1.34 },
            { item = 'sturgeon', label = 'Stör', tier = 'epic', minWeight = 4.2, maxWeight = 11.6, rarity = 12, xp = 142, price = 440, difficulty = 1.72 },
            { item = 'mythic_carp', label = 'Mytisk karp', tier = 'legendary', minWeight = 6.5, maxWeight = 13.0, rarity = 4, xp = 220, price = 720, difficulty = 2.0 }
        }
    }
}

Config.Events = {
    tournaments = {
        enabled = true,
        intervalMinutes = 45,
        durationMinutes = 12,
        payout = {
            [1] = { cash = 4000, xp = 350 },
            [2] = { cash = 2500, xp = 220 },
            [3] = { cash = 1500, xp = 130 }
        }
    }
}

Config.Exports = {
    GetFishingLevel = 'GetFishingLevel',
    GetFishingXP = 'GetFishingXP'
}
