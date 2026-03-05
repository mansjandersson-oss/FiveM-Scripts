Locales = {
    en = {
        script_title = 'Chop Shop',

        -- Blip labels
        blip_criminal_npc = 'Shady Contact',
        blip_civilian_npc = 'Auto Dismantler',
        blip_chop_zone    = 'Chop Zone',

        -- NPC interaction labels
        get_contract       = 'Get Vehicle Contract',
        view_contract      = 'View Active Contract',
        turn_in_contract   = 'Turn In Completed Contract',
        request_vehicle    = 'Request Dismantling Vehicle',
        turn_in_parts      = 'Turn In Auto Parts',

        -- Shared feedback
        busy_action       = 'You are already doing something.',
        failed_minigame   = 'You slipped up and failed.',
        action_cancelled  = 'Action cancelled.',

        -- Chop zone
        entered_chop_zone = 'Pull the vehicle in, exit it and start stripping.',

        -- Strip part labels (shown in ox_target)
        strip_driver_door    = 'Strip Driver Door',
        strip_passenger_door = 'Strip Passenger Door',
        strip_rear_left_door = 'Strip Rear Left Door',
        strip_rear_right_door = 'Strip Rear Right Door',
        strip_hood           = 'Strip Hood',
        strip_trunk          = 'Strip Trunk Lid',
        strip_frame          = 'Strip Frame (Despawns Vehicle)',

        -- Part names used in notifications
        part_driver_door    = 'driver door',
        part_passenger_door = 'passenger door',
        part_rear_left_door = 'rear left door',
        part_rear_right_door = 'rear right door',
        part_hood           = 'hood',
        part_trunk          = 'trunk lid',

        -- Contract status
        contract_status_title     = 'Active Contract',
        no_active_contract        = 'You do not have an active contract.',
        contract_already_active   = 'You already have an active contract. Finish it first.',
        contract_use_item_to_restore = 'You already have a contract. Use the Contract item in your inventory to restore it.',
        contract_cooldown         = 'You cannot take a new contract yet. Wait %ss.',
        contract_received         = 'Contract issued: steal %s vehicles and chop them.',
        contract_vehicles_spawned = 'Find the contract vehicles already roaming the city and bring each one to the chop zone.',
        contract_vehicle_blip     = 'Target: %s',
        contract_vehicle_detected = 'Contract vehicle detected: %s! Strip it here.',
        contract_vehicle_done     = '%s chopped. %s vehicle(s) remaining.',
        contract_all_done         = 'All contract vehicles chopped! Turn in to collect your payment.',
        contract_incomplete       = 'Contract is not complete yet.',
        contract_turned_in        = 'Contract fulfilled. Received x%s payment and some materials.',
        contract_restored         = 'Contract restored. Find the vehicles and bring them to the chop zone.',
        contract_item_complete    = '✓ Contract complete',
        not_enough_police         = 'Not enough police on duty (%s required).',

        -- Civilian job
        civil_job_already_active = 'You already have a vehicle to dismantle.',
        civil_job_cooldown       = 'The dismantler is busy. Try again in %ss.',
        civil_vehicle_incoming   = 'A %s has been brought round for you to dismantle.',
        civilian_vehicle_blip    = 'Dismantle Vehicle',
        civilian_vehicle_ready   = 'A %s is waiting near the shop. Drive it to the chop zone.',
        vehicle_spawn_failed     = 'Could not retrieve the vehicle. Try again.',
        civil_frame_stripped     = 'Frame fully stripped. Received x%s payment and some materials.',
        no_auto_parts            = 'You have no auto parts to turn in.',
        remove_parts_failed      = 'Could not remove parts from your inventory.',
        civil_parts_turned_in    = 'Turned in %s auto part(s). Received x%s payment and some materials.',

        -- Strip feedback
        part_stripped     = 'Stripped: %s.',
        frame_stripped    = 'Frame stripped and vehicle removed.',
        invalid_part      = 'Invalid part.',
        no_inventory_space = 'Not enough inventory space.',
    },

    sv = {
        script_title = 'Chop Shop',

        blip_criminal_npc = 'Skum Kontakt',
        blip_civilian_npc = 'Bilskrotare',
        blip_chop_zone    = 'Chopzon',

        get_contract       = 'Hämta fordonskontrakt',
        view_contract      = 'Visa aktivt kontrakt',
        turn_in_contract   = 'Lämna in avslutat kontrakt',
        request_vehicle    = 'Begär demonteringsbil',
        turn_in_parts      = 'Lämna in bildelar',

        busy_action       = 'Du gör redan något.',
        failed_minigame   = 'Du snubblade och misslyckades.',
        action_cancelled  = 'Handling avbruten.',

        entered_chop_zone = 'Kör in bilen, gå ur och börja plocka isär.',

        strip_driver_door    = 'Demontera förardörr',
        strip_passenger_door = 'Demontera passagerardörr',
        strip_rear_left_door = 'Demontera vänster bakdörr',
        strip_rear_right_door = 'Demontera höger bakdörr',
        strip_hood           = 'Demontera motorhuv',
        strip_trunk          = 'Demontera bagagelucka',
        strip_frame          = 'Demontera ram (tar bort fordon)',

        part_driver_door    = 'förardörr',
        part_passenger_door = 'passagerardörr',
        part_rear_left_door = 'vänster bakdörr',
        part_rear_right_door = 'höger bakdörr',
        part_hood           = 'motorhuv',
        part_trunk          = 'bagagelucka',

        contract_status_title     = 'Aktivt kontrakt',
        no_active_contract        = 'Du har inget aktivt kontrakt.',
        contract_already_active   = 'Du har redan ett aktivt kontrakt. Avsluta det först.',
        contract_use_item_to_restore = 'Du har redan ett kontrakt. Använd kontraktitemsen i ditt inventariet för att återställa det.',
        contract_cooldown         = 'Du kan inte ta ett nytt kontrakt ännu. Vänta %ss.',
        contract_received         = 'Kontrakt utfärdat: stjäl %s fordon och choppra dem.',
        contract_vehicles_spawned = 'Hitta kontraktfordonen som redan rör sig i staden och kör dem till chopzonen.',
        contract_vehicle_blip     = 'Mål: %s',
        contract_vehicle_detected = 'Kontraktfordon detekterat: %s! Demontera det här.',
        contract_vehicle_done     = '%s demonterad. %s fordon kvar.',
        contract_all_done         = 'Alla kontraktfordon chopprade! Lämna in för betalning.',
        contract_incomplete       = 'Kontraktet är inte klart ännu.',
        contract_turned_in        = 'Kontrakt fullgjort. Fick x%s betalning och lite material.',
        contract_restored         = 'Kontrakt återställt. Hitta fordonen och kör dem till chopzonen.',
        contract_item_complete    = '✓ Kontrakt slutfört',
        not_enough_police         = 'Inte tillräckligt med polis i tjänst (%s krävs).',

        civil_job_already_active = 'Du har redan ett fordon att demontera.',
        civil_job_cooldown       = 'Skrotaren är upptagen. Försök igen om %ss.',
        civil_vehicle_incoming   = 'En %s har tagits fram för dig att demontera.',
        civilian_vehicle_blip    = 'Demonteringsbil',
        civilian_vehicle_ready   = 'En %s väntar vid verkstaden. Kör den till chopzonen.',
        vehicle_spawn_failed     = 'Kunde inte hämta fordonet. Försök igen.',
        civil_frame_stripped     = 'Ram helt demonterad. Fick x%s betalning och lite material.',
        no_auto_parts            = 'Du har inga bildelar att lämna in.',
        remove_parts_failed      = 'Kunde inte ta bort delar från inventariet.',
        civil_parts_turned_in    = 'Lämnade in %s bildel(ar). Fick x%s betalning och lite material.',

        part_stripped     = 'Demonterad: %s.',
        frame_stripped    = 'Ram demonterad och fordon borttaget.',
        invalid_part      = 'Ogiltig del.',
        no_inventory_space = 'Inte tillräckligt med plats i inventariet.',
    },

    -- Placeholders for future translations — currently fall back to English.
    de = {},
    es = {}
}

for key, value in pairs(Locales.en) do
    if Locales.de[key] == nil then Locales.de[key] = value end
    if Locales.es[key] == nil then Locales.es[key] = value end
end
