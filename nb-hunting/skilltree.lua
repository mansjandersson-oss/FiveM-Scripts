Config = Config or {}

Config.SkillTree = {
    enabled = true,
    pointsPerLevel = 1,
    branches = {
        Stealth = { label = 'Stealth' },
        Expertise = { label = 'Expertise' }
    },
    skills = {
        suppressor = {
            branch = 'Stealth',
            label = 'Suppressor Training',
            description = 'Minskar risken att djuren blir rädda av ljudet.',
            maxLevel = 5,
            unlockLevel = 2,
            effectPerLevel = 0.1
        },
        reward_bonus = {
            branch = 'Expertise',
            label = 'Reward Mastery',
            description = 'Mer reward vid styckning (+0.1% per nivå, max 5).',
            maxLevel = 5,
            unlockLevel = 1,
            effectPerLevel = 0.001
        },
        silent_steps = {
            branch = 'Stealth',
            label = 'Silent Steps',
            description = 'Minskar ljud från rörelse i jaktzon.',
            maxLevel = 5,
            unlockLevel = 2,
            effectPerLevel = 0.025
        },
        camouflage = {
            branch = 'Stealth',
            label = 'Forest Camouflage',
            description = 'Mindre chans att djur upptäcker dig visuellt.',
            maxLevel = 5,
            unlockLevel = 2,
            effectPerLevel = 0.025
        },
        scent_mask = {
            branch = 'Stealth',
            label = 'Scent Masking',
            description = 'Minskar hur snabbt rovdjur låser på dig.',
            maxLevel = 5,
            unlockLevel = 3,
            effectPerLevel = 0.025
        },
        night_stalker = {
            branch = 'Stealth',
            label = 'Night Stalker',
            description = 'Bättre kontroll vid jakt i mörker.',
            maxLevel = 5,
            unlockLevel = 3,
            effectPerLevel = 0.025
        },
        brush_cover = {
            branch = 'Stealth',
            label = 'Brush Cover',
            description = 'Mindre upptäcktsradie nära vegetation.',
            maxLevel = 5,
            unlockLevel = 2,
            effectPerLevel = 0.025
        },
        wind_reader = {
            branch = 'Stealth',
            label = 'Wind Reader',
            description = 'Bättre positionering mot bytesdjur.',
            maxLevel = 5,
            unlockLevel = 3,
            effectPerLevel = 0.025
        },
        soft_knees = {
            branch = 'Stealth',
            label = 'Soft Knees',
            description = 'Mindre ljud vid hopp och landning.',
            maxLevel = 5,
            unlockLevel = 2,
            effectPerLevel = 0.025
        },
        stillness = {
            branch = 'Stealth',
            label = 'Stillness',
            description = 'Djur reagerar långsammare när du står still.',
            maxLevel = 5,
            unlockLevel = 2,
            effectPerLevel = 0.025
        },
        cold_blood = {
            branch = 'Stealth',
            label = 'Cold Blood',
            description = 'Mindre aggression från stressade djur.',
            maxLevel = 5,
            unlockLevel = 4,
            effectPerLevel = 0.025
        },
        predator_hush = {
            branch = 'Stealth',
            label = 'Predator Hush',
            description = 'Reducerar panik i zonen efter skott.',
            maxLevel = 5,
            unlockLevel = 4,
            effectPerLevel = 0.025
        },
        deep_hide = {
            branch = 'Stealth',
            label = 'Deep Hide',
            description = 'Bättre dold position i tät skog.',
            maxLevel = 5,
            unlockLevel = 5,
            effectPerLevel = 0.025
        },
        echo_control = {
            branch = 'Stealth',
            label = 'Echo Control',
            description = 'Minskar ljudspridning i kuperad terräng.',
            maxLevel = 5,
            unlockLevel = 4,
            effectPerLevel = 0.025
        },
        mist_walk = {
            branch = 'Stealth',
            label = 'Mist Walk',
            description = 'Stealth-bonus i regn/fuktig miljö.',
            maxLevel = 5,
            unlockLevel = 3,
            effectPerLevel = 0.025
        },
        trail_eraser = {
            branch = 'Stealth',
            label = 'Trail Eraser',
            description = 'Minskar spårbarhet av djurflockar.',
            maxLevel = 5,
            unlockLevel = 5,
            effectPerLevel = 0.025
        },
        hunter_patience = {
            branch = 'Stealth',
            label = 'Hunter Patience',
            description = 'Längre fönster innan djur flyr.',
            maxLevel = 5,
            unlockLevel = 3,
            effectPerLevel = 0.025
        },
        leaf_shadow = {
            branch = 'Stealth',
            label = 'Leaf Shadow',
            description = 'Stealth-bonus när du crouchar.',
            maxLevel = 5,
            unlockLevel = 2,
            effectPerLevel = 0.025
        },
        quiet_draw = {
            branch = 'Stealth',
            label = 'Quiet Draw',
            description = 'Tystare vapenbyte under jakt.',
            maxLevel = 5,
            unlockLevel = 3,
            effectPerLevel = 0.025
        },
        ghost_presence = {
            branch = 'Stealth',
            label = 'Ghost Presence',
            description = 'Minskad djurreaktion på nära håll.',
            maxLevel = 5,
            unlockLevel = 5,
            effectPerLevel = 0.025
        },
        silent_scope = {
            branch = 'Stealth',
            label = 'Silent Scope',
            description = 'Mindre stresspåslag vid siktad jakt.',
            maxLevel = 5,
            unlockLevel = 4,
            effectPerLevel = 0.025
        },
        apex_stealth = {
            branch = 'Stealth',
            label = 'Apex Stealth',
            description = 'Toppförmåga för maximal smygjakt.',
            maxLevel = 5,
            unlockLevel = 6,
            effectPerLevel = 0.05
        },
        field_dressing = {
            branch = 'Expertise',
            label = 'Field Dressing',
            description = 'Snabbare och effektivare styckning.',
            maxLevel = 5,
            unlockLevel = 1,
            effectPerLevel = 0.02
        },
        clean_cut = {
            branch = 'Expertise',
            label = 'Clean Cut',
            description = 'Mindre spill vid styckning.',
            maxLevel = 5,
            unlockLevel = 1,
            effectPerLevel = 0.02
        },
        bone_knowledge = {
            branch = 'Expertise',
            label = 'Bone Knowledge',
            description = 'Bättre uttag av ben/läder.',
            maxLevel = 5,
            unlockLevel = 2,
            effectPerLevel = 0.02
        },
        trophy_eye = {
            branch = 'Expertise',
            label = 'Trophy Eye',
            description = 'Ökad chans på trofé-loot.',
            maxLevel = 5,
            unlockLevel = 2,
            effectPerLevel = 0.02
        },
        meat_handler = {
            branch = 'Expertise',
            label = 'Meat Handler',
            description = 'Bättre köttkvalité efter fällning.',
            maxLevel = 5,
            unlockLevel = 1,
            effectPerLevel = 0.02
        },
        bait_master = {
            branch = 'Expertise',
            label = 'Bait Master',
            description = 'Mer effektiv åtelanvändning.',
            maxLevel = 5,
            unlockLevel = 2,
            effectPerLevel = 0.02
        },
        call_master = {
            branch = 'Expertise',
            label = 'Call Master',
            description = 'Djurläten ger bättre resultat.',
            maxLevel = 5,
            unlockLevel = 2,
            effectPerLevel = 0.02
        },
        tracking_lore = {
            branch = 'Expertise',
            label = 'Tracking Lore',
            description = 'Lättare att hålla djur i närzonen.',
            maxLevel = 5,
            unlockLevel = 2,
            effectPerLevel = 0.02
        },
        ammo_efficiency = {
            branch = 'Expertise',
            label = 'Ammo Efficiency',
            description = 'Bättre skottutnyttjande per jakt.',
            maxLevel = 5,
            unlockLevel = 3,
            effectPerLevel = 0.02
        },
        steady_aim = {
            branch = 'Expertise',
            label = 'Steady Aim',
            description = 'Stabilare precision i pressade lägen.',
            maxLevel = 5,
            unlockLevel = 2,
            effectPerLevel = 0.02
        },
        organ_harvest = {
            branch = 'Expertise',
            label = 'Organ Harvest',
            description = 'Högre chans på sällsynt loot.',
            maxLevel = 5,
            unlockLevel = 4,
            effectPerLevel = 0.02
        },
        expedition_pack = {
            branch = 'Expertise',
            label = 'Expedition Pack',
            description = 'Mer plats för jaktutbyte.',
            maxLevel = 5,
            unlockLevel = 3,
            effectPerLevel = 0.02
        },
        terrain_mastery = {
            branch = 'Expertise',
            label = 'Terrain Mastery',
            description = 'Bättre kontroll i brant terräng.',
            maxLevel = 5,
            unlockLevel = 3,
            effectPerLevel = 0.02
        },
        master_skinner = {
            branch = 'Expertise',
            label = 'Master Skinner',
            description = 'Signifikant bättre läderutbyte.',
            maxLevel = 5,
            unlockLevel = 4,
            effectPerLevel = 0.02
        },
        precision_butcher = {
            branch = 'Expertise',
            label = 'Precision Butcher',
            description = 'Bättre utfall på varje cut.',
            maxLevel = 5,
            unlockLevel = 4,
            effectPerLevel = 0.02
        },
        prime_selection = {
            branch = 'Expertise',
            label = 'Prime Selection',
            description = 'Högre värde på säljbara varor.',
            maxLevel = 5,
            unlockLevel = 4,
            effectPerLevel = 0.02
        },
        contractor = {
            branch = 'Expertise',
            label = 'Contractor',
            description = 'Mission rewards skalar bättre.',
            maxLevel = 5,
            unlockLevel = 5,
            effectPerLevel = 0.02
        },
        rare_harvest = {
            branch = 'Expertise',
            label = 'Rare Harvest',
            description = 'Ökad chans på sällsynta drops.',
            maxLevel = 5,
            unlockLevel = 5,
            effectPerLevel = 0.02
        },
        zone_specialist = {
            branch = 'Expertise',
            label = 'Zone Specialist',
            description = 'Bonus i alla jaktzoner.',
            maxLevel = 5,
            unlockLevel = 5,
            effectPerLevel = 0.02
        },
        apex_expertise = {
            branch = 'Expertise',
            label = 'Apex Expertise',
            description = 'Toppförmåga för maximal utdelning.',
            maxLevel = 5,
            unlockLevel = 6,
            effectPerLevel = 0.05
        }
    }
}
