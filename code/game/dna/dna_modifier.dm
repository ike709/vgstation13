#define DNA_BLOCK_SIZE 3

#define MAX_RADIATION_DURATION 20
#define MAX_RADIATION_INTENSITY 10

//list("data" = null, "owner" = null, "label" = null, "type" = null, "ue" = 0),
/datum/dna2/record
	var/datum/dna/dna = null
	var/types=0
	var/name="Empty"

	// Stuff for cloners
	var/id=null
	var/ckey=null
	var/mind=null
	var/list/languages = list()
	var/list/attack_log = list()
	var/default_language=null
	var/times_cloned=0
	var/talkcount

/datum/dna2/record/proc/GetData()
	var/list/ser=list("data" = null, "owner" = null, "label" = null, "type" = null, "ue" = 0)
	if(dna)
		ser["ue"] = (types & DNA2_BUF_UE) == DNA2_BUF_UE
		if(types & DNA2_BUF_SE)
			ser["data"] = dna.SE
		else
			ser["data"] = dna.UI
		ser["owner"] = src.dna.real_name
		ser["label"] = name
		if(types & DNA2_BUF_UI)
			ser["type"] = "ui"
		else
			ser["type"] = "se"
	return ser

/datum/dna2/record/proc/Clone()
	var/datum/dna2/record/new_copy = new
	if(dna)
		new_copy.dna = dna.Clone()
	new_copy.types = types
	new_copy.name = name
	new_copy.id = id
	new_copy.ckey = ckey
	new_copy.mind = mind
	new_copy.languages = languages.Copy()
	new_copy.attack_log = attack_log.Copy()
	new_copy.default_language = default_language
	new_copy.times_cloned = times_cloned

	return new_copy

/////////////////////////// DNA MACHINES
/obj/machinery/dna_scannernew
	name = "\improper DNA modifier"
	desc = "A machine that scans the DNA structures of an organism for use with adjacent machinery. Can modify an organism's DNA as well as perform other functions with the use of a console."
	icon = 'icons/obj/Cryogenic2.dmi'
	icon_state = "scanner_0"
	density = 1
	anchored = 1.0
	use_power = MACHINE_POWER_USE_IDLE
	idle_power_usage = 50
	active_power_usage = 300
	var/locked = 0
	var/mob/living/carbon/occupant = null
	var/obj/item/weapon/reagent_containers/glass/beaker = null
	var/injector_cooldown = 150 //Used by attachment
	machine_flags = SCREWTOGGLE | CROWDESTROY
	var/obj/machinery/computer/connected
	var/last_message // Used by go_out()

	light_color = LIGHT_COLOR_CYAN
	use_auto_lights = 1
	light_range_on = 3
	light_power_on = 2

/obj/machinery/dna_scannernew/splashable()
	return FALSE

/obj/machinery/dna_scannernew/New()
	. = ..()

	component_parts = newlist(
		/obj/item/weapon/circuitboard/clonescanner,
		/obj/item/weapon/stock_parts/scanning_module,
		/obj/item/weapon/stock_parts/manipulator,
		/obj/item/weapon/stock_parts/micro_laser,
		/obj/item/weapon/stock_parts/console_screen
	)

	RefreshParts()

/obj/machinery/dna_scannernew/RefreshParts()
	var/efficiency = 0
	for(var/obj/item/weapon/stock_parts/SP in component_parts)
		if(!istype(SP,/obj/item/weapon/stock_parts/console_screen))
			efficiency += SP.rating-1
	injector_cooldown = initial(injector_cooldown) - 15*(efficiency)

/obj/machinery/dna_scannernew/allow_drop()
	return 0

/obj/machinery/dna_scannernew/relaymove(mob/user as mob)
	if(user.stat)
		return
	src.go_out(ejector = user)
	return


/obj/machinery/dna_scannernew/verb/eject()
	set src in oview(1)
	set category = "Object"
	set name = "Eject DNA Scanner"

	if(usr.isUnconscious() || istype(usr, /mob/living/simple_animal))
		return

	go_out(ejector = usr)

	add_fingerprint(usr)
	return

/obj/machinery/dna_scannernew/crowbarDestroy(mob/user, obj/item/tool/crowbar/I)
	if(occupant)
		to_chat(user, "<span class='warning'>\the [src] is occupied.</span>")
		return FALSE
	return ..()

/obj/machinery/dna_scannernew/Destroy()

	go_out() //Eject everything

	if(connected)
		if(istype(connected,/obj/machinery/computer/cloning))
			var/obj/machinery/computer/cloning/C = connected
			C.scanner = null
		else if(istype(connected,/obj/machinery/computer/scan_consolenew))
			var/obj/machinery/computer/scan_consolenew/C = connected
			C.connected = null
		connected = null

	. = ..()

/obj/machinery/dna_scannernew/verb/move_inside()
	set src in oview(1)
	set category = "Object"
	set name = "Enter DNA Scanner"

	if(usr.incapacitated() || usr.lying) //are you cuffed, dying, lying, stunned or other
		return
	if (!ishuman(usr) && !ismonkey(usr)) //Make sure they're a mob that has dna
		to_chat(usr, "<span class='notice'>You cannot enter \the [src].</span>")
		return
	if (ismanifested(usr))
		to_chat(usr, "<span class='notice'> For some reason, the scanner is unable to read your genes.</span>")//to prevent a loophole that allows cultist to turn manifested ghosts into normal humans

		return
	if (src.occupant)
		to_chat(usr, "<span class='notice'> <B>The scanner is already occupied!</B></span>")
		return
	usr.stop_pulling()
	usr.forceMove(src)
	usr.reset_view()
	src.occupant = usr
	src.icon_state = "scanner_1"
	src.add_fingerprint(usr)

/obj/machinery/dna_scannernew/MouseDropTo(atom/movable/O as mob|obj, mob/user as mob)
	if(!ismob(O)) //mobs only
		return
	if(O.loc == user || !isturf(O.loc) || !isturf(user.loc) || !user.Adjacent(O)) //no you can't pull things out of your ass
		return
	if(user.incapacitated() || user.lying) //are you cuffed, dying, lying, stunned or other
		return
	if(!Adjacent(user) || !user.Adjacent(src) || user.contents.Find(src)) // is the mob too far away from you, or are you too far away from the source
		return

	var/mob/living/L = O
	if(!istype(L))
		return

	put_in(L,user)

/obj/machinery/dna_scannernew/MouseDropFrom(over_object, src_location, var/turf/over_location, src_control, over_control, params)
	if(!ishigherbeing(usr) && !isrobot(usr) || usr.incapacitated() || usr.lying)
		return
	if(!occupant)
		to_chat(usr, "<span class='warning'>The sleeper is unoccupied!</span>")
		return
	if(isrobot(usr))
		var/mob/living/silicon/robot/robit = usr
		if(!HAS_MODULE_QUIRK(robit, MODULE_CAN_HANDLE_MEDICAL))
			to_chat(usr, "<span class='warning'>You do not have the means to do this!</span>")
			return
	over_location = get_turf(over_location)
	if(!istype(over_location) || over_location.density)
		return
	if(!Adjacent(over_location))
		return
	if(!(occupant == usr) && (!Adjacent(usr) || !usr.Adjacent(over_location)))
		return
	for(var/atom/movable/A in over_location.contents)
		if(A.density)
			if((A == src) || istype(A, /mob))
				continue
			return
	if(occupant == usr)
		visible_message("[usr] climbs out of \the [src].")
	else
		visible_message("[usr] removes [occupant.name] from \the [src].")
	go_out(over_location, ejector = usr)

/obj/machinery/dna_scannernew/attackby(var/obj/item/weapon/item as obj, var/mob/user as mob)
	if(istype(item, /obj/item/weapon/reagent_containers/glass))
		if(item.w_class > W_CLASS_SMALL)
			to_chat(user, "<span class='warning'>\The [item] is too big to fit.</span>")
			return
		if(beaker)
			to_chat(user, "<span class='warning'>A beaker is already loaded into the machine.</span>")
			return
		if(user.drop_item(beaker, src))
			beaker = item
			user.visible_message("[user] adds \a [item] to \the [src]!", "You add \a [item] to \the [src]!")
			if(connected)
				nanomanager.update_uis(connected)
			return
	else if(istype(item, /obj/item/weapon/grab)) //sanity checks, you chucklefucks
		var/obj/item/weapon/grab/G = item
		if (!ismob(G.affecting))
			return
		if(put_in(G.affecting, user))
			qdel(G)
		return 1
	return ..()

/obj/machinery/dna_scannernew/proc/put_in(var/mob/M, var/mob/user)
	if(!istype(M))
		return FALSE
	if(M.locked_to)
		var/datum/locking_category/category = M.locked_to.get_lock_cat_for(M)
		if(!istype(category, /datum/locking_category/buckle/bed/roller))
			return FALSE
	else if(M.anchored)
		return FALSE

	if(ismanifested(M) || (!iscarbon(M) && !istype(M, /mob/living/slime_pile)))
		if(user)
			to_chat(user, "<span class='notice'>For some reason, the scanner is unable to read that organisms's genes.</span>")
		return

	if(user)
		if(!ishigherbeing(user) && !isrobot(user)) //No ghosts or mice putting people into the scanner
			return
		if(isrobot(user))
			var/mob/living/silicon/robot/robit = user
			if(!HAS_MODULE_QUIRK(robit, MODULE_CAN_HANDLE_MEDICAL))
				to_chat(user, "<span class='warning'>You do not have the means to do this!</span>")
				return

	for(var/mob/living/carbon/slime/S in range(1,M))
		if(S.Victim == M)
			if(user)
				to_chat(user, "<span class='warning'>[M] will not fit into \the [src] because they have a slime latched onto their head.</span>")
			return

	if(occupant)
		if(user)
			to_chat(user, "<span class='notice'>\The [src] is already occupied!</span>")
		return FALSE

	if(user && user.pulling == M)
		user.stop_pulling()
	if(user)
		add_fingerprint(user)
	M.unlock_from() //We checked above that they can ONLY be buckled to a rollerbed to allow this to happen!
	M.forceMove(src)
	M.reset_view()
	src.occupant = M
	src.icon_state = "scanner_1"
	if(connected)
		nanomanager.update_uis(connected)

	if(user)
		if(M == user)
			visible_message("[user] climbs into \the [src].")
		else
			visible_message("[user] places [M] into \the [src].")
	else
		visible_message("\the [M] is placed into \the [src].")

	// search for ghosts, if the corpse is empty and the scanner is connected to a cloner
	for(dir in cardinal)
		var/obj/machinery/computer/cloning/C = locate(/obj/machinery/computer/cloning) in get_step(src, dir)
		if(C)
			C.update_icon()
			C.updateUsrDialog()
			if(!M.client && M.mind)
				var/mob/dead/observer/ghost = mind_can_reenter(M.mind)
				if(ghost)
					var/mob/ghostmob = ghost.get_top_transmogrification()
					if(ghostmob)
						ghostmob << 'sound/effects/adminhelp.ogg'
						to_chat(ghostmob, "<span class='interface big'><span class='bold'>Your corpse has been placed into a cloning scanner. Return to your body if you want to be cloned!</span> \
							(Verbs -> Ghost -> Re-enter corpse, or <a href='?src=\ref[ghost];reentercorpse=1'>click here!</a>)</span>")
				break
			break
	return TRUE

/obj/machinery/dna_scannernew/conveyor_act(var/atom/movable/AM, var/obj/machinery/conveyor/CB)
	if(isliving(AM))
		var/mob/living/L = AM
		if(L.lying)
			if(put_in(L))
				return TRUE
	return FALSE

#define DNASCANNER_MESSAGE_INTERVAL 1 SECONDS

/obj/machinery/dna_scannernew/proc/go_out(var/exit = src.loc, var/mob/ejector)
	if(!occupant)
		for(var/mob/M in src)//Failsafe so you can get mobs out
			if(!M.gcDestroyed)
				M.forceMove(get_turf(src))
		return 0
	if(locked)
		if(world.time - last_message > DNASCANNER_MESSAGE_INTERVAL)
			say("Can't eject occupants while \the [src] is locked.")
			last_message = world.time
		return 0
	if(!occupant.gcDestroyed)
		occupant.forceMove(exit)
		occupant.reset_view()
		if(istype(ejector) && ejector != occupant)
			var/obj/structure/bed/roller/B = locate() in exit
			if(B)
				B.buckle_mob(occupant, ejector)
				ejector.start_pulling(B)
	occupant = null
	icon_state = "scanner_0"

	for(var/atom/movable/x in src.contents) //Ejects items that manage to get in there (exluding the components and beaker)
		if((x in component_parts) || (x == src.beaker))
			continue
		x.forceMove(src.loc)

	for(dir in cardinal)
		var/obj/machinery/computer/cloning/C = locate(/obj/machinery/computer/cloning) in get_step(src, dir)
		if(C)
			C.update_icon()
			C.updateUsrDialog()

	if(connected)
		nanomanager.update_uis(connected)

	return 1

#undef DNASCANNER_MESSAGE_INTERVAL

/obj/machinery/dna_scannernew/proc/contains_husk()
	if(occupant && (M_HUSK in occupant.mutations))
		return 1
	return 0

/obj/machinery/dna_scannernew/on_login(var/mob/M)
	if(M.mind && !M.client && locate(/obj/machinery/computer/cloning) in range(src, 1)) //!M.client = mob has ghosted out of their body
		var/mob/dead/observer/ghost = mind_can_reenter(M.mind)
		if(ghost)
			var/mob/ghostmob = ghost.get_top_transmogrification()
			if(ghostmob)
				ghostmob << 'sound/effects/adminhelp.ogg'
				to_chat(ghostmob, "<span class='interface big'><span class='bold'>Your corpse has been placed into a cloning scanner. Return to your body if you want to be cloned!</span> \
					(Verbs -> Ghost -> Re-enter corpse, or <a href='?src=\ref[ghost];reentercorpse=1'>click here!</a>)</span>")

/obj/machinery/dna_scannernew/ex_act(severity)
	//This is by far the oldest code I have ever seen, please appreciate how it's preserved in comments for distant posterity. Have some perspective of where we came from.
	switch(severity)
		if(1.0)
			for(var/atom/movable/A as mob|obj in src)
				//A.loc = src.loc
				A.forceMove(src.loc)
				//ex_act(severity)
				A.ex_act(severity)
				//Foreach goto(35)
			//SN src = null
			qdel(src)
			return
		if(2.0)
			if (prob(50))
				for(var/atom/movable/A as mob|obj in src)
					//A.loc = src.loc
					A.forceMove(src.loc)
					//ex_act(severity)
					A.ex_act(severity)
					//Foreach goto(108)
				//SN src = null
				qdel(src)
				return
		if(3.0)
			if (prob(25))
				for(var/atom/movable/A as mob|obj in src)
					A.forceMove(src.loc)
					ex_act(severity)
					//Foreach goto(181)
				//SN src = null
				qdel(src)
				return
		//else
	//return


/obj/machinery/dna_scannernew/blob_act()
	if(prob(75))
		qdel(src)

/obj/machinery/computer/scan_consolenew
	name = "DNA Modifier Access Console"
	desc = "Uses a DNA modifier to manipulate DNA via radiation as well as perform other functions."
	icon = 'icons/obj/computer.dmi'
	icon_state = "dna"
	density = 1

	anchored = 1
	idle_power_usage = 200
	active_power_usage = 400
	circuit = "/obj/item/weapon/circuitboard/scan_consolenew"

	var/selected_ui_block = 1.0
	var/selected_ui_subblock = 1.0
	var/selected_se_block = 1.0
	var/selected_se_subblock = 1.0
	var/selected_ui_target = 1
	var/selected_ui_target_hex = 1
	var/radiation_duration = 2.0
	var/radiation_intensity = 1.0
	var/list/datum/dna2/record/buffers[3]
	var/irradiating = 0
	var/list/datum/block_label/labels[DNA_SE_LENGTH]
	var/injector_ready = 0
	var/obj/machinery/dna_scannernew/connected
	var/obj/item/weapon/disk/data/disk
	var/selected_menu_key
	var/waiting_for_user_input = 0

	light_color = LIGHT_COLOR_BLUE

/obj/machinery/computer/scan_consolenew/Destroy()
	if(connected)
		if(connected.connected == src)
			connected.connected = null
		connected = null
	for(var/datum/block_label/label in labels)
		qdel(label)
	labels.Cut()
	buffers.Cut()
	if(disk)
		qdel(disk)
		disk = null
	..()

/datum/block_label
	var/name = ""
	var/color = "#1c1c1c"
/datum/block_label/proc/overwriteLabel(var/datum/block_label/L)
	L.name = src.name
	L.color = src.color

/obj/machinery/computer/scan_consolenew/attackby(obj/O as obj, mob/user as mob)
	..()
	if (istype(O, /obj/item/weapon/disk/data)) //INSERT SOME diskS
		if (!disk)
			if (user.drop_item(O, src))
				disk = O
				to_chat(user, "You insert [O].")
				nanomanager.update_uis(src)
	return

/obj/machinery/computer/scan_consolenew/New()
	..()
	for(var/i=1;i<=3;i++)
		buffers[i] = new /datum/dna2/record
	for(var/i=1;i<=DNA_SE_LENGTH;i++)
		labels[i] = new /datum/block_label
	if(world.has_round_started())
		initialize()
	spawn(250)
		setInjectorReady()

/obj/machinery/computer/scan_consolenew/initialize()
	connected = findScanner()
	if(connected)
		connected.connected = src

/obj/machinery/computer/scan_consolenew/ex_act(severity)
	switch(severity)
		if(1.0)
			qdel(src)
			return
		if(2.0)
			if (prob(50))
				qdel(src)
				return

/obj/machinery/computer/scan_consolenew/blob_act()
	if(prob(75))
		qdel(src)

/obj/machinery/computer/scan_consolenew/proc/findScanner()
	for(var/obj/machinery/dna_scannernew/DN in oview(1, src)) // All 8 directions.
		return DN

/obj/machinery/computer/scan_consolenew/proc/all_dna_blocks(var/list/buffer)
	var/list/arr = list()
	for(var/i = 1, i <= buffer.len, i++)
		arr += "[i]:[EncodeDNABlock(buffer[i])]"
	return arr

/obj/machinery/computer/scan_consolenew/proc/setInjectorBlock(var/obj/item/weapon/dnainjector/I, var/blk, var/datum/dna2/record/buffer)
	var/pos = findtext(blk,":")
	if(!pos)
		return 0
	var/id = text2num(copytext(blk,1,pos))
	if(!id)
		return 0
	I.block = id
	I.buf = buffer
	return 1

/obj/machinery/computer/scan_consolenew/proc/ejectDisk()
	if (!disk)
		return
	disk.forceMove(get_turf(src))
	disk = null

/obj/machinery/computer/scan_consolenew/process()
	if (connected && connected.occupant)
		use_power = MACHINE_POWER_USE_ACTIVE
	else
		use_power = MACHINE_POWER_USE_IDLE

/obj/machinery/computer/scan_consolenew/attack_hand(user as mob)
	if(!..())
		if(!connected)
			connected = findScanner() //lets get that machine
			if(connected)
				connected.connected = src
		ui_interact(user)

/obj/machinery/computer/scan_consolenew/AltClick()
	if(disk)
		ejectDisk()
	else
		..()

 /**
  * The ui_interact proc is used to open and update Nano UIs
  * If ui_interact is not used then the UI will not update correctly
  * ui_interact is currently defined for /atom/movable
  *
  * @param user /mob The mob who is interacting with this ui
  * @param ui_key string A string key to use for this ui. Allows for multiple unique uis on one obj/mob (defaut value "main")
  * @param ui /datum/nanoui This parameter is passed by the nanoui process() proc when updating an open ui
  *
  * @return nothing
  */
/obj/machinery/computer/scan_consolenew/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open=NANOUI_FOCUS)
	if(!connected)
		src.visible_message("[bicon(src)]<span class='notice'>No scanner connected!<span>")
		return

	if(user == connected.occupant)
		return

	// this is the data which will be sent to the ui
	var/data[0]
	data["selectedMenuKey"] = selected_menu_key
	data["locked"] = src.connected.locked
	data["hasOccupant"] = connected.occupant ? 1 : 0

	data["isInjectorReady"] = injector_ready

	data["hasDisk"] = disk ? 1 : 0
	data["isDiskProtected"] = disk && disk.read_only

	var/diskData[0]
	if (!disk || !disk.buf)
		diskData["data"] = null
		diskData["owner"] = null
		diskData["label"] = null
		diskData["type"] = null
		diskData["ue"] = null
	else
		diskData = disk.buf.GetData()
	data["disk"] = diskData

	var/list/new_buffers = list()
	for(var/datum/dna2/record/buf in src.buffers)
		new_buffers += list(buf.GetData())
	data["buffers"]=new_buffers

	data["radiationIntensity"] = radiation_intensity
	data["radiationDuration"] = radiation_duration
	data["irradiating"] = irradiating

	data["dnaBlockSize"] = DNA_BLOCK_SIZE
	data["selectedUIBlock"] = selected_ui_block
	data["selectedUISubBlock"] = selected_ui_subblock
	data["selectedSEBlock"] = selected_se_block
	data["selectedSESubBlock"] = selected_se_subblock
	data["selectedUITarget"] = selected_ui_target
	data["selectedUITargetHex"] = selected_ui_target_hex
	var/list/new_labels = list()
	for(var/datum/block_label/lmao2list in src.labels)
		new_labels += list(list("name" = lmao2list.name, "color" = lmao2list.color)) //Yes, you are reading this right, "list(list())"[sic]. If you're a sane person you're probably wondering what the fuck this is.
		//You know those weird, creepy twins that only speak between themselves in a made-up language that nobody else understands? NanoUI is it's OWN retarded twin.
	data["block_labels"] = new_labels

	var/occupantData[0]
	if (!src.connected.occupant || !src.connected.occupant.dna)
		occupantData["name"] = null
		occupantData["stat"] = null
		occupantData["isViableSubject"] = null
		occupantData["health"] = null
		occupantData["maxHealth"] = null
		occupantData["minHealth"] = null
		occupantData["uniqueEnzymes"] = null
		occupantData["uniqueIdentity"] = null
		occupantData["structuralEnzymes"] = null
		occupantData["radiationLevel"] = null
	else
		occupantData["name"] = connected.occupant.name
		occupantData["stat"] = connected.occupant.stat
		occupantData["isViableSubject"] = 1
		if (M_NOCLONE in connected.occupant.mutations || !src.connected.occupant.dna)
			occupantData["isViableSubject"] = 0
		occupantData["health"] = connected.occupant.health
		occupantData["maxHealth"] = connected.occupant.maxHealth
		occupantData["minHealth"] = config.health_threshold_dead
		occupantData["uniqueEnzymes"] = connected.occupant.dna.unique_enzymes
		occupantData["uniqueIdentity"] = connected.occupant.dna.uni_identity
		occupantData["structuralEnzymes"] = connected.occupant.dna.struc_enzymes
		occupantData["radiationLevel"] = connected.occupant.radiation
	data["occupant"] = occupantData;

	data["isBeakerLoaded"] = connected.beaker ? 1 : 0
	data["beakerLabel"] = null
	data["beakerVolume"] = 0
	if(connected.beaker)
		data["beakerLabel"] = connected.beaker.labeled ? connected.beaker.labeled : null
		if (connected.beaker.reagents && connected.beaker.reagents.reagent_list.len)
			for(var/datum/reagent/R in connected.beaker.reagents.reagent_list)
				data["beakerVolume"] += R.volume

	// update the ui if it exists, returns null if no ui is passed/found
	ui = nanomanager.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		// the ui does not exist, so we'll create a new() one
        // for a list of parameters and their descriptions see the code docs in \code\\modules\nano\nanoui.dm
		ui = new(user, src, ui_key, "dna_modifier.tmpl", "DNA Modifier Console", 660, 700)
		// when the ui is first opened this is the data it will use
		ui.set_initial_data(data)
		// open the new ui window
		ui.open()

/obj/machinery/computer/scan_consolenew/proc/pulse_radiation(mob/user)
	if(connected.contains_husk())
		to_chat(user, "<span class='notice'>The organism inside does not have DNA.</span>")
		return 1
	irradiating = src.radiation_duration
	var/lock_state = src.connected.locked
	src.connected.locked = 1//lock it

	nanomanager.update_uis(src)
	sleep(10*src.radiation_duration) // sleep for radiation_duration seconds
	irradiating = 0

	if(!src.connected.occupant)
		return 1

	if (prob(95))
		if(prob(75))
			randmutb(src.connected.occupant)
		else
			randmuti(src.connected.occupant)
	else
		if(prob(95))
			randmutg(src.connected.occupant)
		else
			randmuti(src.connected.occupant)

	src.connected.occupant.radiation += ((src.radiation_intensity*3)+src.radiation_duration*3)
	src.connected.locked = lock_state
	nanomanager.update_uis(src)

/obj/machinery/computer/scan_consolenew/proc/setInjectorReady()
	injector_ready = 1
	nanomanager.update_uis(src)

/obj/machinery/computer/scan_consolenew/npc_tamper_act(mob/living/L)
	radiation_duration = rand(1, MAX_RADIATION_DURATION)
	radiation_intensity= rand(1, MAX_RADIATION_INTENSITY)

	pulse_radiation(L)

/obj/machinery/computer/scan_consolenew/Topic(href, href_list)
	if(..())
		return 0 // don't update uis
	if(href_list["close"])
		if(usr.machine == src)
			usr.unset_machine()
	if(!istype(usr.loc, /turf))
		return 0 // don't update uis
	if(!src || !src.connected)
		return 0 // don't update uis
	if(irradiating) // Make sure that it isn't already irradiating someone...
		return 0 // don't update uis

	add_fingerprint(usr)

	if (href_list["selectMenuKey"])
		selected_menu_key = href_list["selectMenuKey"]
		return 1 // return 1 forces an update to all Nano uis attached to src

	if (href_list["toggleLock"])
		if ((src.connected && src.connected.occupant))
			src.connected.locked = !( src.connected.locked )
		return 1 // return 1 forces an update to all Nano uis attached to src

	if (href_list["pulseRadiation"])
		pulse_radiation(usr)
		return // pulse_radiation() handles the updating

	if (href_list["radiationDuration"])
		if (text2num(href_list["radiationDuration"]) > 0)
			if (src.radiation_duration < MAX_RADIATION_DURATION)
				src.radiation_duration = min(radiation_duration + 2, MAX_RADIATION_DURATION)
		else
			if (src.radiation_duration > 2)
				src.radiation_duration -= 2
		return 1 // return 1 forces an update to all Nano uis attached to src

	if (href_list["radiationIntensity"])
		if (text2num(href_list["radiationIntensity"]) > 0)
			if (src.radiation_intensity < MAX_RADIATION_INTENSITY)
				src.radiation_intensity++
		else
			if (src.radiation_intensity > 1)
				src.radiation_intensity--
		return 1 // return 1 forces an update to all Nano uis attached to src

	////////////////////////////////////////////////////////

	if (href_list["changeUITarget"] && text2num(href_list["changeUITarget"]) > 0)
		if (src.selected_ui_target < 15)
			src.selected_ui_target++
			src.selected_ui_target_hex = src.selected_ui_target
			switch(selected_ui_target)
				if(10)
					src.selected_ui_target_hex = "A"
				if(11)
					src.selected_ui_target_hex = "B"
				if(12)
					src.selected_ui_target_hex = "C"
				if(13)
					src.selected_ui_target_hex = "D"
				if(14)
					src.selected_ui_target_hex = "E"
				if(15)
					src.selected_ui_target_hex = "F"
		else
			src.selected_ui_target = 0
			src.selected_ui_target_hex = 0
		return 1 // return 1 forces an update to all Nano uis attached to src

	if (href_list["changeUITarget"] && text2num(href_list["changeUITarget"]) < 1)
		if (src.selected_ui_target > 0)
			src.selected_ui_target--
			src.selected_ui_target_hex = src.selected_ui_target
			switch(selected_ui_target)
				if(10)
					src.selected_ui_target_hex = "A"
				if(11)
					src.selected_ui_target_hex = "B"
				if(12)
					src.selected_ui_target_hex = "C"
				if(13)
					src.selected_ui_target_hex = "D"
				if(14)
					src.selected_ui_target_hex = "E"
		else
			src.selected_ui_target = 15
			src.selected_ui_target_hex = "F"
		return 1 // return 1 forces an update to all Nano uis attached to src

	if (href_list["selectUIBlock"] && href_list["selectUISubblock"]) // This chunk of code updates selected block / sub-block based on click
		var/select_block = text2num(href_list["selectUIBlock"])
		var/select_subblock = text2num(href_list["selectUISubblock"])
		if ((select_block <= 13) && (select_block >= 1))
			src.selected_ui_block = select_block
		if ((select_subblock <= DNA_BLOCK_SIZE) && (select_subblock >= 1))
			src.selected_ui_subblock = select_subblock
		return 1 // return 1 forces an update to all Nano uis attached to src

	if (href_list["pulseUIRadiation"])
		if(connected.contains_husk())
			to_chat(usr, "<span class='notice'>The organism inside does not have DNA.</span>")
			return 1
		var/block = src.connected.occupant.dna.GetUISubBlock(src.selected_ui_block,src.selected_ui_subblock)

		irradiating = src.radiation_duration
		var/lock_state = src.connected.locked
		src.connected.locked = 1//lock it

		nanomanager.update_uis(src)
		sleep(10*src.radiation_duration) // sleep for radiation_duration seconds
		irradiating = 0

		if (!src.connected.occupant)
			return 1

		if (prob((80 + (src.radiation_duration / 2))))
			block = miniscrambletarget(num2text(selected_ui_target), src.radiation_intensity, src.radiation_duration)
			src.connected.occupant.dna.SetUISubBlock(src.selected_ui_block,src.selected_ui_subblock,block)
			src.connected.occupant.UpdateAppearance()
			src.connected.occupant.radiation += (src.radiation_intensity+src.radiation_duration)
		else
			if	(prob(20+src.radiation_intensity))
				randmutb(src.connected.occupant)
				domutcheck(src.connected.occupant,src.connected)
			else
				randmuti(src.connected.occupant)
				src.connected.occupant.UpdateAppearance()
			src.connected.occupant.radiation += ((src.radiation_intensity*2)+src.radiation_duration)
		src.connected.locked = lock_state
		return 1 // return 1 forces an update to all Nano uis attached to src

	////////////////////////////////////////////////////////

	if (href_list["injectRejuvenators"])
		if (!connected.occupant)
			return 0
		var/inject_amount = round(text2num(href_list["injectRejuvenators"]), 5) // round to nearest 5
		if (inject_amount < 0) // Since the user can actually type the commands himself, some sanity checking
			inject_amount = 0
		if (inject_amount > 50)
			inject_amount = 50
		connected.beaker.reagents.trans_to(connected.occupant, inject_amount)
		connected.beaker.reagents.reaction(connected.occupant)
		return 1 // return 1 forces an update to all Nano uis attached to src

	////////////////////////////////////////////////////////

	if (href_list["selectSEBlock"] && href_list["selectSESubblock"]) // This chunk of code updates selected block / sub-block based on click (se stands for strutural enzymes)
		var/select_block = text2num(href_list["selectSEBlock"])
		var/select_subblock = text2num(href_list["selectSESubblock"])
		if ((select_block <= DNA_SE_LENGTH) && (select_block >= 1))
			src.selected_se_block = select_block
		if ((select_subblock <= DNA_BLOCK_SIZE) && (select_subblock >= 1))
			src.selected_se_subblock = select_subblock
		//testing("User selected block [selected_se_block] (sent [select_block]), subblock [selected_se_subblock] (sent [select_block]).")
		return 1 // return 1 forces an update to all Nano uis attached to src

	if (href_list["pulseSERadiation"])
		if(connected.contains_husk())
			to_chat(usr, "<span class='notice'>The organism inside does not have DNA.</span>")
			return 1
		var/block = src.connected.occupant.dna.GetSESubBlock(src.selected_se_block,src.selected_se_subblock)
		//var/original_block=block
		//testing("Irradiating SE block [src.selected_se_block]:[src.selected_se_subblock] ([block])...")

		irradiating = src.radiation_duration
		var/lock_state = src.connected.locked
		src.connected.locked = 1 //lock it

		nanomanager.update_uis(src)
		sleep(10*src.radiation_duration) // sleep for radiation_duration seconds
		irradiating = 0

		if(src.connected.occupant)
			if (prob((80 + (src.radiation_duration / 2))))
				// FIXME: Find out what these corresponded to and change them to the WHATEVERBLOCK they need to be.
				//if ((src.selected_se_block != 2 || src.selected_se_block != 12 || src.selected_se_block != 8 || src.selected_se_block || 10) && prob (20))
				var/real_SE_block=selected_se_block
				block = miniscramble(block, src.radiation_intensity, src.radiation_duration)
				if(prob(20))
					if (src.selected_se_block > 1 && src.selected_se_block < DNA_SE_LENGTH/2)
						real_SE_block++
					else if (src.selected_se_block > DNA_SE_LENGTH/2 && src.selected_se_block < DNA_SE_LENGTH)
						real_SE_block--

				//testing("Irradiated SE block [real_SE_block]:[src.selected_se_subblock] ([original_block] now [block]) [(real_SE_block!=selected_se_block) ? "(SHIFTED)":""]!")
				connected.occupant.dna.SetSESubBlock(real_SE_block,selected_se_subblock,block)
				src.connected.occupant.radiation += (src.radiation_intensity+src.radiation_duration)
				domutcheck(src.connected.occupant,src.connected)
			else
				src.connected.occupant.radiation += ((src.radiation_intensity*2)+src.radiation_duration)
				if	(prob(80-src.radiation_duration))
					//testing("Random bad mut!")
					randmutb(src.connected.occupant)
					domutcheck(src.connected.occupant,src.connected)
				else
					randmuti(src.connected.occupant)
					//testing("Random identity mut!")
					src.connected.occupant.UpdateAppearance()
		src.connected.locked = lock_state
		return 1 // return 1 forces an update to all Nano uis attached to src

	if(href_list["ejectBeaker"])
		if(connected.beaker)
			var/obj/item/weapon/reagent_containers/glass/B = connected.beaker
			B.forceMove(connected.loc)
			connected.beaker = null
		return 1

	if(href_list["changeBlockLabel"])
		var/which = text2num(href_list["changeBlockLabel"])
		var/datum/block_label/label = labels[which]
		var/text = copytext(sanitize(input(usr, "New Label:", "Edit Label", label.name) as text|null),1,MAX_NAME_LEN)
		if(!Adjacent(usr) || usr.incapacitated() || (stat & (FORCEDISABLE | BROKEN | NOPOWER | EMPED)))
			return
		if(text) //you can color the tab without a label, sure why not
			label.name = text
		var/newcolor = input("Select Tab Color", "Edit Label", label.color) as color
		if(!Adjacent(usr) || usr.incapacitated() || (stat & (FORCEDISABLE | BROKEN | NOPOWER | EMPED)))
			return
		if(newcolor)
			label.color = newcolor
		if(disk && !disk.read_only) //autobackup!
			for(var/i=1;i<=DNA_SE_LENGTH;i++)
				var/datum/block_label/L = labels[i]
				L.overwriteLabel(disk.labels[i])
		return 1

	if(href_list["copyLabelsFromDisk"])
		if(disk)
			for(var/i=1;i<=DNA_SE_LENGTH;i++)
				var/datum/block_label/L = disk.labels[i]
				L.overwriteLabel(labels[i])
		return 1

	if(href_list["copyLabelsToDisk"])
		if(disk)
			if(disk.read_only)
				to_chat(usr, "<span class='warning'>The disk's write-protect tab is set to read-only.</span>")
				return
			for(var/i=1;i<=DNA_SE_LENGTH;i++)
				var/datum/block_label/L = labels[i]
				L.overwriteLabel(disk.labels[i])
		return 1

	if(href_list["ejectOccupant"])
		connected.go_out()
		return 1

	// Transfer Buffer Management
	if(href_list["bufferOption"])
		var/bufferOption = href_list["bufferOption"]

		// These bufferOptions do not require a bufferId
		if (bufferOption == "wipeDisk")
			if ((isnull(src.disk)) || (src.disk.read_only))
				//src.temphtml = "Invalid disk. Please try again."
				return 0

			src.disk.buf=null
			//src.temphtml = "Data saved."
			return 1

		if (bufferOption == "ejectDisk")
			ejectDisk()
			return 1

		// All bufferOptions from here on require a bufferId
		if (!href_list["bufferId"])
			return 0

		var/bufferId = text2num(href_list["bufferId"])

		if (bufferId < 1 || bufferId > 3)
			return 0 // Not a valid buffer id

		if (bufferOption == "saveUI")
			if(connected.contains_husk())
				to_chat(usr, "<span class='notice'>The organism inside does not have DNA.</span>")
				return 1
			if(src.connected.occupant && src.connected.occupant.dna)
				var/datum/dna2/record/databuf=new
				databuf.types = DNA2_BUF_UI // DNA2_BUF_UE
				databuf.dna = src.connected.occupant.dna.Clone()
				if(ishuman(connected.occupant))
					var/datum/data/record/med_record = data_core.find_medical_record_by_dna(connected.occupant.dna.unique_enzymes)
					if(med_record)
						databuf.dna.real_name = med_record.fields["name"]
					else
						databuf.dna.real_name=connected.occupant.name
					databuf.dna.flavor_text=connected.occupant.flavor_text
				databuf.name = "Unique Identifier"
				src.buffers[bufferId] = databuf
			return 1

		if (bufferOption == "saveUIAndUE")
			if(connected.contains_husk())
				to_chat(usr, "<span class='notice'>The organism inside does not have DNA.</span>")
				return 1
			if(src.connected.occupant && src.connected.occupant.dna)
				var/datum/dna2/record/databuf=new
				databuf.types = DNA2_BUF_UI|DNA2_BUF_UE
				databuf.dna = src.connected.occupant.dna.Clone()
				if(ishuman(connected.occupant))
					var/datum/data/record/med_record = data_core.find_medical_record_by_dna(connected.occupant.dna.unique_enzymes)
					if(med_record)
						databuf.dna.real_name = med_record.fields["name"]
					else
						databuf.dna.real_name=connected.occupant.name
					databuf.dna.flavor_text=connected.occupant.flavor_text
				databuf.name = "Unique Identifier + Unique Enzymes"
				src.buffers[bufferId] = databuf
			return 1

		if (bufferOption == "saveSE")
			if(connected.contains_husk())
				to_chat(usr, "<span class='notice'>The organism inside does not have DNA.</span>")
				return 1
			if(src.connected.occupant && src.connected.occupant.dna)
				var/datum/dna2/record/databuf=new
				databuf.types = DNA2_BUF_SE
				databuf.dna = src.connected.occupant.dna.Clone()
				if(ishuman(connected.occupant))
					var/datum/data/record/med_record = data_core.find_medical_record_by_dna(connected.occupant.dna.unique_enzymes)
					if(med_record)
						databuf.dna.real_name = med_record.fields["name"]
					else
						databuf.dna.real_name=connected.occupant.name
				databuf.name = "Structural Enzymes"
				src.buffers[bufferId] = databuf
			return 1

		if (bufferOption == "clear")
			src.buffers[bufferId]=new /datum/dna2/record()
			return 1

		if (bufferOption == "changeLabel")
			var/datum/dna2/record/buf = src.buffers[bufferId]
			var/text = copytext(sanitize(input(usr, "New Label:", "Edit Label", buf.name) as text|null),1,MAX_NAME_LEN)
			buf.name = text
			src.buffers[bufferId] = buf
			return 1

		if (bufferOption == "transfer")
			if(connected.contains_husk())
				to_chat(usr, "<span class='notice'>The organism inside does not have DNA.</span>")
				return 1
			if (!src.connected.occupant || (M_NOCLONE in src.connected.occupant.mutations) || !src.connected.occupant.dna)
				return

			irradiating = 2
			var/lock_state = src.connected.locked
			src.connected.locked = 1//lock it

			sleep(2 SECONDS)

			irradiating = 0
			src.connected.locked = lock_state

			var/datum/dna2/record/buf = src.buffers[bufferId]

			if ((buf.types & DNA2_BUF_UI))
				if ((buf.types & DNA2_BUF_UE))
					src.connected.occupant.dna.unique_enzymes = buf.dna.unique_enzymes
					src.connected.occupant.real_name = buf.dna.real_name
					src.connected.occupant.name = buf.dna.real_name
					src.connected.occupant.flavor_text = buf.dna.flavor_text
				src.connected.occupant.UpdateAppearance(buf.dna.UI.Copy())
			else if (buf.types & DNA2_BUF_SE)
				src.connected.occupant.dna.SE = buf.dna.SE
				src.connected.occupant.dna.UpdateSE()
				domutcheck(src.connected.occupant,src.connected)
			src.connected.occupant.radiation += rand(20,50)
			return 1

		if (bufferOption == "createInjector")
			if (src.injector_ready || waiting_for_user_input)

				var/success = 1
				var/obj/item/weapon/dnainjector/I = new /obj/item/weapon/dnainjector
				var/datum/dna2/record/buf = src.buffers[bufferId]
				if(href_list["createBlockInjector"])
					waiting_for_user_input=1
					var/list/selectedbuf
					if(buf.types & DNA2_BUF_SE)
						selectedbuf=buf.dna.SE
					else
						selectedbuf=buf.dna.UI
					var/blk = input(usr,"Select Block","Block") as null|anything in all_dna_blocks(selectedbuf)
					if(!isnull(blk) && injector_ready)
						success = setInjectorBlock(I,blk,buf)
					else
						qdel(I)
						success = FALSE


				else
					I.buf = buf
				waiting_for_user_input=0
				if(success)
					I.forceMove(src.loc)
					I.name += " ([buf.name])"
					injector_ready = 0
					spawn(connected.injector_cooldown)
						setInjectorReady()
			return 1

		if (bufferOption == "loadDisk")
			if ((isnull(src.disk)) || (!src.disk.buf))
				//src.temphtml = "Invalid disk. Please try again."
				return 0

			src.buffers[bufferId]=src.disk.buf
			//src.temphtml = "Data loaded."
			return 1

		if (bufferOption == "saveDisk")
			if ((isnull(src.disk)) || (src.disk.read_only))
				//src.temphtml = "Invalid disk. Please try again."
				return 0

			var/datum/dna2/record/buf = src.buffers[bufferId]

			src.disk.buf = buf
			src.disk.name = "data disk - '[buf.dna.real_name]'"
			//src.temphtml = "Data saved."
			return 1


/////////////////////////// DNA MACHINES

#undef MAX_RADIATION_DURATION
#undef MAX_RADIATION_INTENSITY
