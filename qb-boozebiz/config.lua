Config = {}

Config.Debug = false
Config.Locale = 'en'


Config.Translations = {
    en = {
        busy_action = 'You are already doing something.',
        failed_minigame = 'You failed the mini-game.',
        ferment_route_title = 'Fermentation Route',
        mash_type_label = 'Mash Type',
        wine_mash_option = 'Wine Mash (Grapes)',
        beer_mash_option = 'Beer Mash (Barley)',
        ferment_route_cancelled = 'Fermentation route selection cancelled.',
        fermentation_mix_title = 'Fermentation Mix',
        fermentation_temp_label = 'Set mash temperature (%s-%s°C)',
        fermentation_stir_label = 'Set stir intensity (%s-%s)',
        stopped_mixing = 'You stopped mixing.',
        mash_overheated = 'Mash overheated! High explosion risk!',
        mash_ruined = 'Mash ruined: target was ~%s°C.',
        mash_texture_wrong = 'Mash texture wrong (ideal stir %s).',
        distill_setup_title = 'Distillation Setup',
        mash_source_label = 'Mash Source',
        beer_mash_source = 'Beer Mash (Barley)',
        wine_mash_source = 'Wine Mash (Grape)',
        still_temp_label = 'Still Temperature (%s-%s°C)',
        distill_time_label = 'Distillation Time (%s-%s min)',
        distill_setup_cancelled = 'Distillation setup cancelled.',
        bottle_title = 'Bottle Your Liquor',
        bottle_name_label = 'Bottle Name',
        bottle_name_desc = 'Choose a brand name for this bottled run',
        purity_label = 'Purity %',
        purity_desc = 'Use the same purity/name for clean stacking',
        bottling_setup_cancelled = 'Bottling setup cancelled.',
        bottle_name_empty = 'Bottle name cannot be empty.',
        purity_range = 'Purity must be between 70% and 99%.',
        action_cancelled = 'Action cancelled.',
        stocking_cancelled = 'Stocking cancelled.',
        fermenting_action = 'Mixing mash in fermentation vat',
        fermentation_cancelled = 'Fermentation cancelled.',
        distill_action = 'Loading mash into distillation pot',
        distillation_cancelled = 'Distillation cancelled.',
        bottling_action = 'Pouring spirit into bottles',
        bottling_cancelled = 'Bottling cancelled.',
        pack_action = 'Carefully packing bottles into crate',
        packing_cancelled = 'Packing cancelled.',
        stock_action = 'Stocking liquor shelf',
        explosion_damage = 'A fermentation vat exploded and you were caught in the blast!',

        not_enough_police = 'Not enough police on duty (%s required).',
        invalid_harvest_zone = 'Invalid harvest zone.',
        field_exhausted = 'Field is exhausted, wait %ss.',
        not_enough_inventory = 'Not enough inventory space.',
        collected_item = 'You collected x%s %s.',
        invalid_ferment_data = 'Invalid fermentation data.',
        invalid_mash_route = 'Invalid mash recipe route.',
        cooling_down = 'Equipment cooling down, wait %ss.',
        missing_item = 'Missing x%s %s.',
        no_space_mash_output = 'You do not have enough space for mash output.',
        remove_ingredient_fail = 'Could not remove ingredient: %s',
        add_ferment_output_fail = 'Could not add fermented mash output.',
        fermentation_success = 'Fermentation success: x%s %s.',
        invalid_distill_settings = 'Invalid distillation settings.',
        invalid_mash_source = 'Invalid mash source.',
        invalid_distill_temp = 'Invalid distillation temperature.',
        invalid_distill_time = 'Invalid distillation time.',
        need_mash = 'You need %s to distill this route.',
        no_space_distill_output = 'Not enough space for distilled spirit.',
        remove_mash_fail = 'Could not remove mash input.',
        add_distill_output_fail = 'Could not add distilled spirit output.',
        distill_success = 'Distillation success: %s at %s°C for %s min.',
        invalid_recipe = 'Invalid recipe.',
        no_space_output = 'You do not have enough space for output.',
        add_crafted_fail = 'Could not add crafted item.',
        production_success = 'Production success: x%s %s.',
        avoided_explosion = 'You overcooked the mash but avoided an explosion.',
        broke_bottles = 'You fumbled the crate and broke x%s bottled liquor.',
        no_bottles_broken = 'You fumbled the crate, but had no bottles to break.',
        invalid_store_route = 'Invalid store route.',
        store_stocked_wait = 'Store already stocked. Wait %ss.',
        need_crate = 'You need a liquor crate to stock this store.',
        remove_crate_fail = 'Could not remove crate from inventory.',
        stock_success = '%s stocked. You received $%s in your bank account.'
    },
    sv = {
        busy_action = 'Du gör redan något.',
        failed_minigame = 'Du misslyckades med min spelet.',
        ferment_route_title = 'Jäsningsval',
        mash_type_label = 'Mäsktype',
        wine_mash_option = 'Vinmäsk (Druvor)',
        beer_mash_option = 'Ölmäsk (Korn)',
        ferment_route_cancelled = 'Val av jäsning avbröts.',
        fermentation_mix_title = 'Jäsningsblandning',
        fermentation_temp_label = 'Ställ in mäsktemperatur (%s-%s°C)',
        fermentation_stir_label = 'Ställ in omrörning (%s-%s)',
        stopped_mixing = 'Du slutade blanda.',
        mash_overheated = 'Mäsken blev överhettad! Hög explosionsrisk!',
        mash_ruined = 'Mäsken förstörd: måltemperaturen var ~%s°C.',
        mash_texture_wrong = 'Fel konsistens i mäsk (ideal omrörning %s).',
        distill_setup_title = 'Destillationsinställning',
        mash_source_label = 'Mäskkälla',
        beer_mash_source = 'Ölmäsk (Korn)',
        wine_mash_source = 'Vinmäsk (Druva)',
        still_temp_label = 'Pannans temperatur (%s-%s°C)',
        distill_time_label = 'Destillationstid (%s-%s min)',
        distill_setup_cancelled = 'Destillationsinställning avbröts.',
        bottle_title = 'Buteljera din alkohol',
        bottle_name_label = 'Flasknamn',
        bottle_name_desc = 'Välj ett varumärke för denna buteljering',
        purity_label = 'Renhet %',
        purity_desc = 'Samma renhet/namn ger bättre stapling',
        bottling_setup_cancelled = 'Buteljeringsinställning avbröts.',
        bottle_name_empty = 'Flasknamn kan inte vara tomt.',
        purity_range = 'Renhet måste vara mellan 70% och 99%.',
        action_cancelled = 'Handling avbruten.',
        stocking_cancelled = 'Påfyllning avbröts.',
        fermenting_action = 'Blandar mäsk i jäskärlet',
        fermentation_cancelled = 'Jäsning avbröts.',
        distill_action = 'Laddar mäsk i destillationspanna',
        distillation_cancelled = 'Destillation avbröts.',
        bottling_action = 'Häller sprit i flaskor',
        bottling_cancelled = 'Buteljering avbröts.',
        pack_action = 'Packar flaskor försiktigt i låda',
        packing_cancelled = 'Packning avbröts.',
        stock_action = 'Fyller på hyllan',
        explosion_damage = 'Ett jäskärl exploderade och du träffades av smällen!',

        not_enough_police = 'Inte tillräckligt många poliser i tjänst (%s krävs).',
        invalid_harvest_zone = 'Ogiltig skördezon.',
        field_exhausted = 'Fältet är uttömt, vänta %ss.',
        not_enough_inventory = 'Inte tillräckligt med plats i inventory.',
        collected_item = 'Du samlade x%s %s.',
        invalid_ferment_data = 'Ogiltig jäsningsdata.',
        invalid_mash_route = 'Ogiltig mäskrutt.',
        cooling_down = 'Utrustningen kyls ner, vänta %ss.',
        missing_item = 'Saknar x%s %s.',
        no_space_mash_output = 'Du har inte plats för mäskoutput.',
        remove_ingredient_fail = 'Kunde inte ta bort ingrediens: %s',
        add_ferment_output_fail = 'Kunde inte lägga till jäst mäsk.',
        fermentation_success = 'Jäsning lyckades: x%s %s.',
        invalid_distill_settings = 'Ogiltiga destillationsinställningar.',
        invalid_mash_source = 'Ogiltig mäskkälla.',
        invalid_distill_temp = 'Ogiltig destillationstemperatur.',
        invalid_distill_time = 'Ogiltig destillationstid.',
        need_mash = 'Du behöver %s för denna destillation.',
        no_space_distill_output = 'Inte tillräckligt med plats för destillerad sprit.',
        remove_mash_fail = 'Kunde inte ta bort mäsk.',
        add_distill_output_fail = 'Kunde inte lägga till destillerad sprit.',
        distill_success = 'Destillation lyckades: %s vid %s°C i %s min.',
        invalid_recipe = 'Ogiltigt recept.',
        no_space_output = 'Du har inte plats för output.',
        add_crafted_fail = 'Kunde inte lägga till tillverkad item.',
        production_success = 'Produktion lyckades: x%s %s.',
        avoided_explosion = 'Du överhettade mäsken men undvek explosion.',
        broke_bottles = 'Du fumlade med lådan och krossade x%s flaskor.',
        no_bottles_broken = 'Du fumlade med lådan men hade inga flaskor att krossa.',
        invalid_store_route = 'Ogiltig butiksrutt.',
        store_stocked_wait = 'Butiken är redan påfylld. Vänta %ss.',
        need_crate = 'Du behöver en spritlåde för att fylla på butiken.',
        remove_crate_fail = 'Kunde inte ta bort låda från inventory.',
        stock_success = '%s påfylld. Du fick $%s till ditt bankkonto.'
    }
}

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
