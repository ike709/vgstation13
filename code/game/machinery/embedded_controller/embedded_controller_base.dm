/obj/machinery/embedded_controller
	var/datum/computer/file/embedded_program/program

	name = "Embedded Controller"
	icon = 'icons/obj/airlock_machines.dmi'
	icon_state = "airlock_control_build0"
	anchored = 1

	var/on = 1

	var/build=2        // Build state
	var/boardtype=null // /obj/item/weapon/circuitboard/ecb
	var/obj/item/weapon/circuitboard/_circuitboard
	machine_flags = MULTITOOL_MENU
/obj/machinery/embedded_controller/New(turf/loc, var/ndir, var/building=0)
	..()

	// offset 24 pixels in direction of dir
	// this allows the APC to be embedded in a wall, yet still inside an area
	if (building)
		dir = ndir

		//src.tdir = dir		// to fix Vars bug
		//dir = SOUTH

		pixel_x = (dir & 3)? 0 : (dir == 4 ? 24 * PIXEL_MULTIPLIER: -24 * PIXEL_MULTIPLIER)
		pixel_y = (dir & 3)? (dir ==1 ? 24 * PIXEL_MULTIPLIER: -24 * PIXEL_MULTIPLIER) : 0

		build=0
		stat |= MAINT
		src.update_icon()

/obj/machinery/embedded_controller/attackby(var/obj/item/W as obj, var/mob/user as mob)
	. = ..()
	if(.)
		return .
	if(type==/obj/machinery/embedded_controller)
		switch(build)
			if(0) // Empty hull
				if(W.is_screwdriver(user))
					to_chat(usr, "You begin removing screws from \the [src] backplate...")
					if(do_after(user, src, 50))
						to_chat(usr, "<span class='notice'>You unscrew \the [src] from the wall.</span>")
						W.playtoolsound(src, 50)
						new /obj/item/mounted/frame/airlock_controller(get_turf(src))
						qdel(src)
					return 1
				if(istype(W, /obj/item/weapon/circuitboard))
					var/obj/item/weapon/circuitboard/C=W
					if(C.board_type!= EMBEDDED_CONTROLLER)
						to_chat(user, "<span class='warning'>You cannot install this type of board into an embedded controller.</span>")
						return
					to_chat(usr, "You begin to insert \the [C] into \the [src].")
					if(do_after(user, src, 10))
						if(user.drop_item(C, src))
							to_chat(usr, "<span class='notice'>You secure \the [C]!</span>")
							_circuitboard=C
							playsound(src, 'sound/effects/pop.ogg', 50, 0)
							build++
							update_icon()
					return 1
			if(1) // Circuitboard installed
				if(iscrowbar(W))
					to_chat(usr, "You begin to pry out \the [W] into \the [src].")
					if(do_after(user, src, 10))
						playsound(src, 'sound/effects/pop.ogg', 50, 0)
						build--
						update_icon()
						var/obj/item/weapon/circuitboard/C
						if(_circuitboard)
							_circuitboard.forceMove(get_turf(src))
							C=_circuitboard
							_circuitboard=null
						else
							C=new boardtype(get_turf(src))
						user.visible_message(\
							"<span class='warning'>[user.name] has removed \the [C]!</span>",\
							"You remove \the [C].")
					return 1
				if(istype(W, /obj/item/stack/cable_coil))
					var/obj/item/stack/cable_coil/C=W
					to_chat(user, "You start adding cables to \the [src]...")
					playsound(src, 'sound/items/Deconstruct.ogg', 50, 1)
					if(do_after(user, src, 20) && C.amount >= 10)
						C.use(5)
						build++
						update_icon()
						user.visible_message(\
							"<span class='warning'>[user.name] has added cables to \the [src]!</span>",\
							"You add cables to \the [src].")
			if(2) // Circuitboard installed, wired.
				if(W.is_wirecutter(user))
					to_chat(usr, "You begin to remove the wiring from \the [src].")
					if(do_after(user, src, 50))
						new /obj/item/stack/cable_coil(loc,5)
						user.visible_message(\
							"<span class='warning'>[user.name] cut the cables.</span>",\
							"You cut the cables.")
						build--
						update_icon()
					return 1
				if(W.is_screwdriver(user))
					to_chat(user, "You begin to complete \the [src]...")
					W.playtoolsound(src, 50)
					if(do_after(user, src, 20))
						if(!_circuitboard)
							_circuitboard=new boardtype(src)
						var/obj/machinery/embedded_controller/EC=new _circuitboard.build_path(get_turf(src))
						EC.dir=dir
						EC.pixel_x=pixel_x
						EC.pixel_y=pixel_y
						user.visible_message(\
							"<span class='warning'>[user.name] has finished \the [src]!</span>",\
							"You finish \the [src].")
						qdel(src)
					return 1
	if(build<2)
		return ..()

/obj/machinery/embedded_controller/proc/post_signal(datum/signal/signal, comm_line)
	return 0

/obj/machinery/embedded_controller/receive_signal(datum/signal/signal, receive_method, receive_param)
	if(!signal || signal.encryption)
		return

	if(program)
		program.receive_signal(signal, receive_method, receive_param)
			//spawn(5) program.process() //no, program.process sends some signals and machines respond and we here again and we lag -rastaf0

/obj/machinery/embedded_controller/process()
	if(program)
		program.process()

	update_icon()
	src.updateDialog()

/obj/machinery/embedded_controller/attack_paw(mob/user as mob)
	attack_hand(user)
	return

/obj/machinery/embedded_controller/attack_hand(mob/user as mob)
	if(!user.dexterity_check())
		to_chat(user, "You do not have the dexterity to use this.")
		return
	if(build<2)
		return 1
	src.ui_interact(user)

/obj/machinery/embedded_controller/ui_interact()
	return

/obj/machinery/embedded_controller/radio
	icon = 'icons/obj/airlock_machines.dmi'
	icon_state = "airlock_control_standby"
	power_channel = ENVIRON
	density = 0

	// Setup parameters only

	var/tag_exterior_door
	var/tag_interior_door
	var/tag_airpump
	var/tag_chamber_sensor
	var/tag_exterior_sensor
	var/tag_interior_sensor
	var/tag_secure = 0

	var/frequency = 1449 //seems to be the frequency used for all the controllers on /vg/ so why not make it default
	var/datum/radio_frequency/radio_connection

/obj/machinery/embedded_controller/radio/dissolvable()
	return 0

/obj/machinery/embedded_controller/radio/initialize()
	set_frequency(frequency)
	var/datum/computer/file/embedded_program/new_prog = new

	new_prog.id_tag = id_tag
	new_prog.tag_exterior_door = tag_exterior_door
	new_prog.tag_interior_door = tag_interior_door
	new_prog.tag_airpump = tag_airpump
	new_prog.tag_chamber_sensor = tag_chamber_sensor
	new_prog.tag_exterior_sensor = tag_exterior_sensor
	new_prog.tag_interior_sensor = tag_interior_sensor
	new_prog.memory["secure"] = tag_secure

	new_prog.master = src
	program = new_prog

	spawn(10)
		program.signalDoor(tag_exterior_door, "update")		//signals connected doors to update their status
		program.signalDoor(tag_interior_door, "update")

/obj/machinery/embedded_controller/radio/update_icon()
	if(on && program)
		if(program.memory["processing"])
			icon_state = "airlock_control_process"
		else
			icon_state = "airlock_control_standby"
	else
		icon_state = "airlock_control_off"

/obj/machinery/embedded_controller/radio/post_signal(datum/signal/signal)
	signal.transmission_method = TRANSMISSION_RADIO
	if(radio_connection)
		return radio_connection.post_signal(src, signal)
	else
		qdel(signal)
		signal = null

/obj/machinery/embedded_controller/radio/proc/set_frequency(new_frequency)
	radio_controller.remove_object(src, frequency)
	frequency = new_frequency
	radio_connection = radio_controller.add_object(src, frequency)

/obj/machinery/embedded_controller/radio/shouldReInitOnMultitoolLink(var/mob/user, var/obj/buffer, var/list/context)
	return TRUE
