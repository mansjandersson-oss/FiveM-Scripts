Locales = {
    en = {
        script_title = 'Chop Shop',

        blip_main_npc = 'Chop Contact',
        blip_chop_zone = 'Chop Yard',

        get_contract = 'Get Vehicle Contract',
        view_contract = 'View Active Contract',
        turn_in_contract = 'Turn In Completed Contract',

        busy_action = 'You are already doing something.',
        failed_minigame = 'You slipped up and failed.',
        action_cancelled = 'Action cancelled.',

        entered_chop_zone = 'Pull a contract vehicle in, exit it and start stripping.',
        mark_vehicle_for_scrap = 'Mark Vehicle for Scrapping',
        marking_vehicle = 'Marking vehicle...',
        vehicle_marked_for_scrap = 'Vehicle marked for scrapping. Start removing parts.',
        vehicle_network_failed = 'Could not lock this street vehicle for chopping. Try another one.',

        strip_driver_door = 'Strip Driver Door',
        strip_passenger_door = 'Strip Passenger Door',
        strip_rear_left_door = 'Strip Rear Left Door',
        strip_rear_right_door = 'Strip Rear Right Door',
        strip_hood = 'Strip Hood',
        strip_trunk = 'Strip Trunk Lid',
        strip_frame = 'Strip Frame',

        part_driver_door = 'driver door',
        part_passenger_door = 'passenger door',
        part_rear_left_door = 'rear left door',
        part_rear_right_door = 'rear right door',
        part_hood = 'hood',
        part_trunk = 'trunk lid',

        contract_status_title = 'Active Contract',
        contract_ui_subtitle = 'Street vehicle list',
        no_active_contract = 'You do not have an active contract.',
        contract_already_active = 'You already have an active contract. Finish it first.',
        contract_use_item_to_restore = 'You already have a contract. Use the contract item in your inventory to restore it.',
        contract_cooldown = 'You cannot take a new contract yet. Wait %ss.',
        contract_received = 'Contract issued: steal %s street vehicles and chop them.',
        contract_vehicles_spawned = 'Find matching vehicles already driving around the city and bring each one to the chop zone.',
        contract_vehicle_detected = 'Contract vehicle detected: %s. Strip it here.',
        contract_vehicle_done = '%s chopped. %s vehicle(s) remaining.',
        contract_all_done = 'All contract vehicles chopped. Turn in to collect your payment.',
        contract_incomplete = 'Contract is not complete yet.',
        contract_turned_in = 'Contract fulfilled. Received x%s payment and some materials.',
        contract_restored = 'Contract restored. Find the vehicles and bring them to the chop zone.',
        contract_item_complete = '[x] Contract complete',
        not_enough_police = 'Not enough police on duty (%s required).',
        not_criminal = 'You do not have the right contacts for this chopshop.',

        part_stripped = 'Stripped: %s.',
        frame_stripped = 'Frame stripped and vehicle removed.',
        invalid_part = 'Invalid part.',
        no_inventory_space = 'Not enough inventory space.',
        too_far_from_part = 'You must stand closer to that vehicle part.',
        invalid_target_vehicle = 'This vehicle is not valid for your active chop contract.',
    },

    sv = {
        script_title = 'Chop Shop',

        blip_main_npc = 'Chop-kontakt',
        blip_chop_zone = 'Bildemontering',

        get_contract = 'Hämta fordonskontrakt',
        view_contract = 'Visa aktivt kontrakt',
        turn_in_contract = 'Lämna in avslutat kontrakt',

        busy_action = 'Du gör redan något.',
        failed_minigame = 'Du misslyckades.',
        action_cancelled = 'Handling avbruten.',

        entered_chop_zone = 'Kör in ett kontraktsfordon, gå ur och börja plocka isär.',
        mark_vehicle_for_scrap = 'Markera fordon för skrotning',
        marking_vehicle = 'Markerar fordon...',
        vehicle_marked_for_scrap = 'Fordon markerat för skrotning. Börja plocka delar.',
        vehicle_network_failed = 'Kunde inte låsa gatubilen för demontering. Testa en annan.',

        strip_driver_door = 'Demontera förardörr',
        strip_passenger_door = 'Demontera passagerardörr',
        strip_rear_left_door = 'Demontera vänster bakdörr',
        strip_rear_right_door = 'Demontera höger bakdörr',
        strip_hood = 'Demontera motorhuv',
        strip_trunk = 'Demontera bagagelucka',
        strip_frame = 'Demontera ram',

        part_driver_door = 'förardörr',
        part_passenger_door = 'passagerardörr',
        part_rear_left_door = 'vänster bakdörr',
        part_rear_right_door = 'höger bakdörr',
        part_hood = 'motorhuv',
        part_trunk = 'bagagelucka',

        contract_status_title = 'Aktivt kontrakt',
        contract_ui_subtitle = 'Lista över gatubilar',
        no_active_contract = 'Du har inget aktivt kontrakt.',
        contract_already_active = 'Du har redan ett aktivt kontrakt. Avsluta det först.',
        contract_use_item_to_restore = 'Du har redan ett kontrakt. Använd kontraktsitemet i ditt inventory för att återställa det.',
        contract_cooldown = 'Du kan inte ta ett nytt kontrakt ännu. Vänta %ss.',
        contract_received = 'Kontrakt utfärdat: stjäl %s gatubilar och choppra dem.',
        contract_vehicles_spawned = 'Hitta matchande fordon som redan kör runt i staden och ta dem till chopzonen.',
        contract_vehicle_detected = 'Kontraktsfordon hittat: %s. Demontera det här.',
        contract_vehicle_done = '%s demonterad. %s fordon kvar.',
        contract_all_done = 'Alla kontraktsfordon är chopprade. Lämna in för betalning.',
        contract_incomplete = 'Kontraktet är inte klart ännu.',
        contract_turned_in = 'Kontrakt fullgjort. Fick x%s betalning och lite material.',
        contract_restored = 'Kontrakt återställt. Hitta fordonen och kör dem till chopzonen.',
        contract_item_complete = '[x] Kontrakt slutfört',
        not_enough_police = 'Inte tillräckligt med polis i tjänst (%s krävs).',
        not_criminal = 'Du har inte rätt kontakter för denna chopshop.',

        part_stripped = 'Demonterad: %s.',
        frame_stripped = 'Ram demonterad och fordon borttaget.',
        invalid_part = 'Ogiltig del.',
        no_inventory_space = 'Inte tillräckligt med plats i inventory.',
        too_far_from_part = 'Du måste stå närmare den bildelen.',
        invalid_target_vehicle = 'Detta fordon gäller inte för ditt aktiva chopkontrakt.',
    },

    de = {},
    es = {},
}

for key, value in pairs(Locales.en) do
    if Locales.de[key] == nil then Locales.de[key] = value end
    if Locales.es[key] == nil then Locales.es[key] = value end
end
