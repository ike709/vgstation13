/* Weapons
 * Contains:
 *		Banhammer
 *		Sword
 *		Classic Baton
 *		Energy Blade
 *		Energy Axe
 *		Energy Shield
 *		Bone Sword
 */

/*
 * Banhammer
 */
/obj/item/weapon/banhammer/attack(mob/M as mob, mob/user as mob)
	to_chat(M, "<span class='red'><b>You have been banned FOR NO REISIN by [user]<b></span>")
	to_chat(user, "<span class='red'>You have <b>BANNED</b> [M]</span>")

/*
 * Classic Baton
 */
/obj/item/weapon/melee/classic_baton
	name = "police baton"
	desc = "A wooden truncheon for beating criminal scum."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "baton"
	inhand_states = list("left_hand" = 'icons/mob/in-hand/left/misc_tools.dmi', "right_hand" = 'icons/mob/in-hand/right/misc_tools.dmi')
	item_state = "classic_baton"
	origin_tech = Tc_COMBAT + "=3"
	mech_flags = MECH_SCAN_FAIL
	flags = FPRINT
	slot_flags = SLOT_BELT
	force = 10
	var/hurt_intent_stun_duration = 0.8 SECONDS
	var/normal_stun_duration = 0.5 SECONDS

/obj/item/weapon/melee/classic_baton/attack(mob/M as mob, mob/living/user as mob)
	if (clumsy_check(user) && prob(50))
		to_chat(user, "<span class='warning'>You club yourself over the head.</span>")
		user.Knockdown(hurt_intent_stun_duration)
		user.Stun(hurt_intent_stun_duration)
		if(ishuman(user))
			var/mob/living/carbon/human/H = user
			H.apply_damage(2*force, BRUTE, LIMB_HEAD)
		else
			user.take_organ_damage(2*force)
		return
/*this is already called in ..()
	src.add_fingerprint(user)
	M.attack_log += text("\[[time_stamp()]\] <font color='orange'>Has been attacked with [src.name] by [user.name] ([user.ckey])</font>")
	user.attack_log += text("\[[time_stamp()]\] <font color='red'>Used the [src.name] to attack [M.name] ([M.ckey])</font>")

	log_attack("<font color='red'>[user.name] ([user.ckey]) attacked [M.name] ([M.ckey]) with [src.name] (INTENT: [uppertext(user.a_intent)])</font>")
*/
	if (user.a_intent == I_HURT)
		if(!..())
			return
		playsound(src, "swing_hit", 50, 1, -1)
		if (M.stuttering < hurt_intent_stun_duration && (!(M_HULK in M.mutations))  /*&& (!istype(H:wear_suit, /obj/item/clothing/suit/judgerobe))*/)
			M.stuttering = hurt_intent_stun_duration
		M.Stun(hurt_intent_stun_duration)
		M.Knockdown(hurt_intent_stun_duration)
		for(var/mob/O in viewers(M))
			if (O.client)
				O.show_message("<span class='danger'>[M] has been beaten with \the [src] by [user]!</span>", 1, "<span class='warning'>You hear someone fall</span>", 2)
	else
		playsound(src, 'sound/weapons/Genhit.ogg', 50, 1, -1)
		M.Stun(normal_stun_duration)
		M.Knockdown(normal_stun_duration)
		M.attack_log += text("\[[time_stamp()]\] <font color='orange'>Has been attacked with [src.name] by [user.name] ([user.ckey])</font>")
		user.attack_log += text("\[[time_stamp()]\] <font color='red'>Used the [src.name] to attack [M.name] ([M.ckey])</font>")
		log_attack("<font color='red'>[user.name] ([user.ckey]) attacked [M.name] ([M.ckey]) with [src.name] (INTENT: [uppertext(user.a_intent)])</font>")
		if(!iscarbon(user))
			M.LAssailant = null
		else
			M.LAssailant = user
			M.assaulted_by(user)
		src.add_fingerprint(user)
		for(var/mob/O in viewers(M))
			if (O.client)
				O.show_message("<span class='danger'>[M] has been stunned with \the [src] by [user]!</span>", 1, "<span class='warning'>You hear someone fall</span>", 2)

/obj/item/weapon/melee/classic_baton/daystick
	name = "\improper Daystick"
	desc = "The Daystick is named as such as a Judge would \"beat the daylights\" out of a target."
	hurt_intent_stun_duration = 1.6 SECONDS
	normal_stun_duration = 1 SECONDS
	force = 15

//Telescopic baton
/obj/item/weapon/melee/telebaton
	name = "telescopic baton"
	desc = "A compact yet robust personal defense weapon. Can be concealed when folded."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "telebaton_0"
	item_state = "telebaton_0"
	origin_tech = Tc_COMBAT + "=2"
	flags = FPRINT
	slot_flags = SLOT_BELT
	w_class = W_CLASS_SMALL
	force = 3
	var/on = 0


/obj/item/weapon/melee/telebaton/attack_self(mob/user as mob)
	on = !on
	if(on)
		user.visible_message("<span class='warning'>With a flick of their wrist, [user] extends their telescopic baton.</span>",\
		"<span class='warning'>You extend the baton.</span>",\
		"You hear an ominous click.",\
		"<span class='notice'>[user] extends their fishing rod.</span>",\
		"<span class='notice'>You extend the fishing rod.</span>",\
		"You hear a balloon exploding.")

		icon_state = "telebaton_1"
		item_state = "telebaton_1"
		w_class = W_CLASS_LARGE
		force = 15//quite robust
		attack_verb = list("smacks", "strikes", "slaps")
	else
		user.visible_message("<span class='notice'>[user] collapses their telescopic baton.</span>",\
		"<span class='notice'>You collapse the baton.</span>",\
		"You hear a click.",\
		"<span class='warning'>[user] collapses their fishing rod.</span>",\
		"<span class='warning'>You collapse the fishing rod.</span>",\
		"You hear a balloon exploding.")

		icon_state = initial(icon_state)
		item_state = initial(item_state)
		w_class = initial(w_class)
		force = initial(force) //not so robust now
		attack_verb = list("hits", "punches")
	playsound(src, 'sound/weapons/empty.ogg', 50, 1)
	add_fingerprint(user)

	if(!blood_overlays["[type][icon_state]"])
		generate_blood_overlay()
	if(blood_overlay)
		overlays -= blood_overlay
	blood_overlay = blood_overlays["[type][icon_state]"]
	blood_overlay.color = blood_color
	overlays += blood_overlay

/obj/item/weapon/melee/telebaton/generate_blood_overlay()
	if(blood_overlays["[type][icon_state]"]) //Unless someone makes a wicked typepath this will never cause a problem
		return
	var/icon/I = new /icon(icon, icon_state)
	I.Blend(new /icon('icons/effects/blood.dmi', rgb(255,255,255)),ICON_ADD) //fills the icon_state with white (except where it's transparent)
	I.Blend(new /icon('icons/effects/blood.dmi', "itemblood"),ICON_MULTIPLY) //adds blood and the remaining white areas become transparant
	blood_overlays["[type][icon_state]"] = image(I)

/obj/item/weapon/melee/telebaton/attack(mob/target as mob, mob/living/user as mob)
	if(on)
		if (clumsy_check(user) && prob(50))
			user.simple_message("<span class='warning'>You club yourself over the head.</span>",
				"<span class='danger'>The fishing rod goes mad!</span>")

			user.Knockdown(4)
			user.Stun(4)
			if(ishuman(user))
				var/mob/living/carbon/human/H = user
				H.apply_damage(2*force, BRUTE, LIMB_HEAD)
			else
				user.take_organ_damage(2*force)
			return
		if (user.a_intent == I_HURT)
			if(!..())
				return
			if(!isrobot(target))
				playsound(src, "swing_hit", 50, 1, -1)
				//target.Stun(4)	//naaah
				target.Knockdown(4)
		else
			if(iscarbon(target))
				var/mob/living/carbon/C = target
				if(C.check_shields(force,src))
					return
			playsound(src, 'sound/weapons/Genhit.ogg', 50, 1, -1)
			target.Knockdown(2)
			target.Stun(2)
			target.attack_log += text("\[[time_stamp()]\] <font color='orange'>Has been attacked with [src.name] by [user.name] ([user.ckey])</font>")
			user.attack_log += text("\[[time_stamp()]\] <font color='red'>Used the [src.name] to attack [target.name] ([target.ckey])</font>")
			log_attack("<font color='red'>[user.name] ([user.ckey]) attacked [target.name] ([target.ckey]) with [src.name] (INTENT: [uppertext(user.a_intent)])</font>")
			src.add_fingerprint(user)

			target.visible_message("<span class='danger'>[target] has been stunned with \the [src] by [user]!</span>",\
				drugged_message="<span class='notice'>[user] smacks [target] with the fishing rod!</span>")

			if(!iscarbon(user))
				target.LAssailant = null
			else
				target.LAssailant = user
				target.assaulted_by(user)
		return
	else
		return ..()


/*
 *Energy Blade
 */
//Most of the other special functions are handled in their own files.

/obj/item/weapon/melee/energy/sword/green/New()
	..()
	_color = "green"

/obj/item/weapon/melee/energy/sword/red/New()
	..()
	_color = "red"

/*
 * Energy Axe
 */
/obj/item/weapon/melee/energy/axe/attack(target as mob, mob/user as mob)
	..()

/obj/item/weapon/melee/energy/axe/attack_self(mob/user as mob)
	src.active = !( src.active )
	if (src.active)
		to_chat(user, "<span class='notice'>\The [src] is now energised.</span>")
		src.force = active_force
		src.icon_state = "axe1"
		src.w_class = W_CLASS_HUGE
		src.sharpness = 1.5
		src.sharpness_flags = SHARP_BLADE | HOT_EDGE
		src.armor_penetration = 100
	else
		to_chat(user, "<span class='notice'>\The [src] can now be concealed.</span>")
		src.force = initial(src.force)
		src.icon_state = initial(src.icon_state)
		src.w_class = initial(src.w_class)
		src.sharpness = initial(src.sharpness)
		src.sharpness_flags = initial(src.sharpness_flags)
		src.armor_penetration = initial(armor_penetration)
	src.add_fingerprint(user)
	return

/obj/item/weapon/melee/bone_sword
	name = "bone sword"
	desc = "A somewhat gruesome blade that appears to be made of solid bone."
	icon_state = "bone_sword"
	inhand_states = list("left_hand" = 'icons/mob/in-hand/left/swords_axes.dmi', "right_hand" = 'icons/mob/in-hand/right/swords_axes.dmi')
	hitsound = "sound/weapons/bloodyslice.ogg"
	flags = FPRINT
	siemens_coefficient = 0
	slot_flags = null
	force = 18
	throwforce = 0
	w_class = 5
	sharpness = 1.5
	sharpness_flags = SHARP_TIP | SHARP_BLADE
	attack_verb = list("attacks", "slashes", "stabs", "slices", "tears", "rips", "dices", "cuts")
	mech_flags = MECH_SCAN_ILLEGAL
	autoignition_temperature = AUTOIGNITION_ORGANIC
	cant_drop = 1
	var/mob/living/simple_animal/borer/parent_borer = null

/obj/item/weapon/melee/bone_sword/New(atom/A, var/p_borer = null)
	..(A)
	if(istype(p_borer, /mob/living/simple_animal/borer))
		parent_borer = p_borer
	if(!parent_borer)
		qdel(src)
	else
		processing_objects.Add(src)

/obj/item/weapon/melee/bone_sword/Destroy()
	if(parent_borer)
		if(parent_borer.channeling_bone_sword)
			parent_borer.channeling_bone_sword = 0
		if(parent_borer.channeling)
			parent_borer.channeling = 0
		parent_borer = null
	processing_objects.Remove(src)
	..()

/obj/item/weapon/melee/bone_sword/process()
	set waitfor = 0
	if(!parent_borer)
		return
	if(!parent_borer.channeling_bone_sword) //the borer has stopped sustaining the sword
		qdel(src)
		return
	if(parent_borer.chemicals < 5) //the parent borer no longer has the chemicals required to sustain the sword
		qdel(src)
		return
	else
		parent_borer.chemicals -= 5
		sleep(10)

/obj/item/weapon/melee/training_sword
	name = "training sword"
	desc = "A blunt object in the shape of a one handed sword."
	icon_state = "grey_sword"
	inhand_states = list("left_hand" = 'icons/mob/in-hand/left/swords_axes.dmi', "right_hand" = 'icons/mob/in-hand/right/swords_axes.dmi')
	item_state = "grey_sword"
	force = 4
	w_type = RECYK_METAL

/obj/item/weapon/rsscimmy
	name = "rune scimitar"
	desc = "A vicious, curved sword."
	icon_state = "rsscimmy"
	inhand_states = list("left_hand" = 'icons/mob/in-hand/left/swords_axes.dmi', "right_hand" = 'icons/mob/in-hand/right/swords_axes.dmi')
	hitsound = 'sound/weapons/runescapeslash.ogg'
	flags = FPRINT
	siemens_coefficient = 1
	sharpness = 1
	sharpness_flags = SHARP_TIP | SHARP_BLADE
	force = 25.0
	w_class = W_CLASS_MEDIUM
	throwforce = 15.0
	throw_speed = 3
	throw_range = 9
	attack_verb = list("attacks", "slashes", "slices", "tears", "rips", "dices", "cuts")

/obj/item/weapon/damocles
	name = "Damocles"
	desc = "An extremely powerful experimental sword. Generates an explosion at the site of impact."
	icon_state = "damocles"
	inhand_states = list("left_hand" = 'icons/mob/in-hand/left/swords_axes.dmi', "right_hand" = 'icons/mob/in-hand/right/swords_axes.dmi')
	siemens_coefficient = 1
	sharpness = 1
	flags = FPRINT
	sharpness_flags = SHARP_TIP | SHARP_BLADE
	force = 25 //A solid weapon by itself
	w_class = W_CLASS_LARGE
	attack_verb = list("slashes", "rips", "dices", "cuts", "attacks", "slices", "tears")

/obj/item/weapon/damocles/attack(atom/target, mob/living/user)
	..()
	if(prob(1))
		to_chat(user, "<span class='notice'>You hit [pick("a good and caring parent", "a criminal", "someone everyone will miss",
		"someone no one will miss", "a thief", "an abusive parent", "a space communist", "an alcoholic", "an adventurer")].</span>")
	explosion(target, 0, 0, 1, whodunnit = user)

/obj/item/weapon/damocles/throw_impact(atom/hit_atom, speed, mob/user)
	..()
	explosion(get_turf(src), 0, 2, 3, whodunnit = user)
	qdel(src)
