Config = {}

Config.Debug = false
Config.Locale = 'en'



Config.PoliceRequired = 0
Config.MinDeliveryPayout = 420
Config.MaxDeliveryPayout = 780

Config.Progress = {
    Harvest = 5500,
    Ferment = 9000,
    Distill = 10500,
    Bottle = 6000,
    Pack = 5000,
    Stock = 6500
}

Config.Cooldowns = {
    Harvest = 20,
    Process = 3,
    Delivery = 10
}

Config.Items = {
    grape = 'grape',
    barley = 'barley',
    yeast = 'yeast',
    springWater = 'spring_water',
    wineMash = 'wine_mash',
    beerMash = 'beer_mash',
    distilledSpirit = 'distilled_spirit',
    emptyBottle = 'empty_bottle',
    cardboard = 'cardboard',
    bottledLiquor = 'bottled_liquor',
    liquorCrate = 'liquor_crate'
}

Config.Minigames = {
    Harvest = {
        stages = { 'easy', 'easy' },
        keys = { 'w', 'a', 's', 'd' }
    },
    Ferment = {
        stages = { 'easy', 'medium', 'medium' },
        keys = { 'w', 'a', 's', 'd' },
        tempMin = 18,
        tempMax = 30,
        sweetSpotVariance = 1,
        stirMin = 1,
        stirMax = 5,
        explosionChance = 35,
        explosionRadius = 5.0,
        explosionDamage = 50
    },
    Distill = {
        stages = { 'medium', 'medium', 'hard' },
        keys = { 'w', 'a', 's', 'd' },
        tempMin = 60,
        tempMax = 100,
        timeMin = 20,
        timeMax = 140
    },
    Bottle = {
        stages = { 'easy', 'medium', 'hard' },
        keys = { 'q', 'e', 'a', 'd' }
    },
    Pack = {
        stages = { 'medium', 'hard', 'hard' },
        keys = { 'q', 'e', 'a', 'd' },
        breakMin = 1,
        breakMax = 2
    },
    Stock = {
        stages = { 'easy', 'medium' },
        keys = { 'w', 'a', 's', 'd' }
    }
}

Config.FermentationRoutes = {
    wine = {
        label = 'Wine Mash (Grapes)',
        output = Config.Items.wineMash,
        outputCount = 2,
        input = {
            [Config.Items.grape] = 4,
            [Config.Items.yeast] = 1,
            [Config.Items.springWater] = 1
        }
    },
    beer = {
        label = 'Beer Mash (Barley)',
        output = Config.Items.beerMash,
        outputCount = 2,
        input = {
            [Config.Items.barley] = 4,
            [Config.Items.yeast] = 1,
            [Config.Items.springWater] = 1
        }
    }
}

Config.DistillProfiles = {
    {
        source = 'beer',
        label = 'Whiskey Spirit',
        temp = { min = 74, max = 83 },
        time = { min = 60, max = 95 },
        purity = { min = 82, max = 94 }
    },
    {
        source = 'beer',
        label = 'Vodka Spirit',
        temp = { min = 84, max = 96 },
        time = { min = 45, max = 75 },
        purity = { min = 88, max = 99 }
    },
    {
        source = 'beer',
        label = 'Gin Spirit',
        temp = { min = 68, max = 78 },
        time = { min = 80, max = 120 },
        purity = { min = 75, max = 90 }
    },
    {
        source = 'wine',
        label = 'Wine Spirit',
        temp = { min = 65, max = 86 },
        time = { min = 35, max = 90 },
        purity = { min = 72, max = 88 }
    }
}

Config.Recipes = {
    Bottle = {
        input = {
            [Config.Items.distilledSpirit] = 1,
            [Config.Items.emptyBottle] = 1
        },
        output = {
            item = Config.Items.bottledLiquor,
            count = 1
        }
    },
    Pack = {
        input = {
            [Config.Items.bottledLiquor] = 6,
            [Config.Items.cardboard] = 1
        },
        output = {
            item = Config.Items.liquorCrate,
            count = 1
        }
    }
}

Config.HarvestZones = {
    {
        name = 'grape_harvest',
        label = 'Harvest Grapes',
        icon = 'fa-solid fa-seedling',
        item = Config.Items.grape,
        count = { min = 2, max = 4 },
        coords = vec3(-1886.68, 2101.8, 140.98),
        size = vec3(2.0, 2.0, 2.0),
        rotation = 330.0
    },
    {
        name = 'barley_harvest',
        label = 'Cut Barley',
        icon = 'fa-solid fa-wheat-awn',
        item = Config.Items.barley,
        count = { min = 1, max = 3 },
        coords = vec3(2306.8, 5130.59, 50.44),
        size = vec3(2.2, 2.2, 2.2),
        rotation = 315.0
    },
    {
        name = 'spring_water_collect',
        label = 'Collect Spring Water',
        icon = 'fa-solid fa-droplet',
        item = Config.Items.springWater,
        count = { min = 1, max = 2 },
        coords = vec3(1658.85, -26.42, 173.78),
        size = vec3(2.0, 2.0, 2.0),
        rotation = 350.0
    },
    {
        name = 'yeast_supply',
        label = 'Collect Yeast Shipment',
        icon = 'fa-solid fa-box-open',
        item = Config.Items.yeast,
        count = { min = 1, max = 2 },
        coords = vec3(-102.51, 6208.35, 31.03),
        size = vec3(2.5, 2.5, 2.5),
        rotation = 45.0
    },
    {
        name = 'bottle_supply',
        label = 'Collect Empty Bottles',
        icon = 'fa-solid fa-wine-bottle',
        item = Config.Items.emptyBottle,
        count = { min = 2, max = 4 },
        coords = vec3(2743.4, 3471.75, 55.67),
        size = vec3(2.5, 2.5, 2.5),
        rotation = 250.0
    },
    {
        name = 'cardboard_supply',
        label = 'Collect Cardboard',
        icon = 'fa-solid fa-box',
        item = Config.Items.cardboard,
        count = { min = 1, max = 2 },
        coords = vec3(145.58, -3093.85, 5.9),
        size = vec3(2.8, 2.8, 2.8),
        rotation = 90.0
    }
}

Config.ProcessingStations = {
    {
        name = 'fermentation_vat',
        label = 'Start Fermentation',
        event = 'qb-boozebiz:client:FermentMash',
        icon = 'fa-solid fa-vial-circle-check',
        coords = vec3(1980.91, 3052.36, 47.22),
        size = vec3(2.0, 2.0, 2.0),
        rotation = 60.0
    },
    {
        name = 'distillery_station',
        label = 'Run Distillery',
        event = 'qb-boozebiz:client:DistillSpirit',
        icon = 'fa-solid fa-fire-burner',
        coords = vec3(1983.35, 3055.81, 47.22),
        size = vec3(2.2, 2.2, 2.2),
        rotation = 300.0
    },
    {
        name = 'bottling_line',
        label = 'Bottle Liquor',
        event = 'qb-boozebiz:client:BottleLiquor',
        icon = 'fa-solid fa-bottle-droplet',
        coords = vec3(1986.34, 3051.98, 47.22),
        size = vec3(2.0, 2.0, 2.0),
        rotation = 30.0
    },
    {
        name = 'packing_table',
        label = 'Pack Liquor Crate',
        event = 'qb-boozebiz:client:PackCrate',
        icon = 'fa-solid fa-boxes-packing',
        coords = vec3(1988.83, 3048.32, 47.22),
        size = vec3(2.2, 2.2, 2.0),
        rotation = 340.0
    }
}

Config.StockZones = {
    {
        name = 'downtown_liquor_stock',
        label = 'Stock Downtown Liquor',
        icon = 'fa-solid fa-store',
        coords = vec3(-1222.2, -906.75, 12.33),
        size = vec3(1.8, 1.8, 2.0),
        rotation = 30.0
    },
    {
        name = 'sandy_liquor_stock',
        label = 'Stock Sandy Liquor Ace',
        icon = 'fa-solid fa-store',
        coords = vec3(1393.12, 3605.16, 34.98),
        size = vec3(1.8, 1.8, 2.0),
        rotation = 20.0
    },
    {
        name = 'vespucci_liquor_stock',
        label = 'Stock Vespucci Liquor',
        icon = 'fa-solid fa-store',
        coords = vec3(-2966.51, 391.2, 15.04),
        size = vec3(1.8, 1.8, 2.0),
        rotation = 355.0
    }
}

Config.Blips = {
    { label = 'Booze Farm', sprite = 469, color = 25, scale = 0.8, coords = vec3(-1886.68, 2101.8, 140.98) },
    { label = 'Distillery', sprite = 93, color = 47, scale = 0.8, coords = vec3(1983.35, 3055.81, 47.22) },
    { label = 'Distribution Route', sprite = 478, color = 17, scale = 0.8, coords = vec3(-1222.2, -906.75, 12.33) }
}
