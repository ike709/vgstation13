/obj/item/weapon/dice
	name = "d6"
	desc = "A die with six sides. Basic and servicable."
	icon = 'icons/obj/dice.dmi'
	icon_state = "d6"
	w_class = W_CLASS_TINY
	var/sides = 6
	var/minsides = 1
	var/result = null
	var/multiplier = 0 //For modifying the result (d00 etc)
	autoignition_temperature = AUTOIGNITION_PLASTIC

/obj/item/weapon/dice/New()
	..()
	result = rand(minsides, sides)
	update_icon()

/obj/item/weapon/dice/d2
	name = "d2"
	desc = "A die with two sides. Coins are undignified!"
	icon_state = "d2"
	sides = 2

/obj/item/weapon/dice/d4
	name = "d4"
	desc = "A die with four sides. The nerd's caltrop."
	icon_state = "d4"
	sides = 4

/obj/item/weapon/dice/d8
	name = "d8"
	desc = "A die with eight sides. It feels... lucky."
	icon_state = "d8"
	sides = 8

/obj/item/weapon/dice/d10
	name = "d10"
	desc = "A die with ten sides. Useful for percentages."
	icon_state = "d10"
	sides = 10

/obj/item/weapon/dice/d00
	name = "d00"
	desc = "A die with ten sides. Works better for d100 rolls than a golfball."
	icon_state = "d00"
	sides = 10
	multiplier = 10

/obj/item/weapon/dice/d12
	name = "d12"
	desc = "A die with twelve sides. There's an air of neglect about it."
	icon_state = "d12"
	sides = 12

/obj/item/weapon/dice/d20
	name = "d20"
	desc = "A die with twenty sides. The prefered die to throw at the GM."
	icon_state = "d20"
	sides = 20

/obj/item/weapon/dice/loaded
	desc = "A die with six even sides. Basic and servicable."

/obj/item/weapon/dice/loaded/d20
	name = "d20"
	desc = "A die with twenty even sides. The prefered die to throw at the GM."
	icon_state = "d20"
	sides = 20

/obj/item/weapon/dice/d20/e20
	var/triggered = 0

/obj/item/weapon/dice/attack_self(mob/user as mob)
	diceroll(user, 0)

/obj/item/weapon/dice/throw_impact(atom/hit_atom, speed, user)
	..()
	diceroll(user, 1)

/obj/item/weapon/dice/proc/show_roll(mob/user as mob, thrown, result)
	var/comment = ""
	if(sides == 20)
		if(result == 20)
			comment = "Nat 20!"
		else if(result == 1)
			comment = "Ouch, bad luck."
	update_icon()
	if(multiplier)
		result = (result - 1) * multiplier
	if(!thrown) //Dice was rolled in someone's hand
		user.visible_message("<span class='notice'>[user] has thrown [src]. It lands on [result]. [comment]</span>", \
							 "<span class='notice'>You throw [src]. It lands on [result]. [comment]</span>", \
							 "<span class='notice'>You hear [src] landing on [result]. [comment]</span>")
	else if(src.throwing == 0) //Dice was thrown and is coming to rest
		visible_message("<span class='notice'>[src] rolls to a stop, landing on [result]. [comment]</span>")

/obj/item/weapon/dice/proc/diceroll(mob/user as mob, thrown)
	result = rand(minsides, sides)
	show_roll(user, thrown, result)

/obj/item/weapon/dice/loaded/diceroll(mob/user as mob, thrown)
	result = rand(minsides, sides * 1.5)
	result = min(result, sides)
	show_roll(user, thrown, result)

/obj/item/weapon/dice/d4/Crossed(var/mob/living/carbon/human/H)
	if(..())
		return 1
	if(istype(H) && !H.shoes)
		to_chat(H, "<span class='danger'>You step on the D4!</span>")
		H.apply_damage(4,BRUTE,(pick(LIMB_LEFT_LEG, LIMB_RIGHT_LEG)))
		H.Knockdown(3)
		H.Stun(3)

/obj/item/weapon/dice/update_icon()
	overlays.len = 0
	overlays += image(icon = icon, icon_state = "[src.icon_state][src.result]")

/obj/item/weapon/dice/d20/e20/diceroll(mob/user as mob, thrown)
	if(!istype(user))
		return 0
	if(triggered)
		return
	..()
	message_admins("[key_name(user)] has [thrown? "used" : "thrown"] an explosive dice and rolled [result]")
	log_game("[key_name(user)] has [thrown? "used" : "thrown"] an explosive dice and rolled [result]")
	if(result == 1)
		to_chat(user, "<span class='danger'>Rocks fall, you die.</span>")
		user.gib()
		user.drop_item(src, force_drop = 1)
	else
		triggered = 1
		visible_message("<span class='notice'>You hear a quiet click.</span>")
		spawn(40)
			var/cap = 0
			var/uncapped = result
			if(result > 19) //Roll a nat 20
				result = 24
				sleep(40)
			else
				cap = 1
				if(result > 14)
					sleep(20)

			var/turf/epicenter = get_turf(src)
			explosion(epicenter, round(result*0.25), round(result*0.5), round(result), round(result*1.5), 1, cap, whodunnit = user)
			if(cap)
				for(var/obj/machinery/computer/bhangmeter/bhangmeter in doppler_arrays)
					if(bhangmeter)
						bhangmeter.sense_explosion(epicenter.x,epicenter.y,epicenter.z,round(uncapped*0.25), round(uncapped*0.5), round(uncapped),"???", cap)


/obj/item/weapon/dice/d20/cursed
	name = "\improper Mysterious d20"
	desc = "Something about this dice seems wrong."
	var/deactivated = 0 //Eventually the dice runs out of power
	var/infinite = 0 //dice with 1 will not run out
	mech_flags = MECH_SCAN_ILLEGAL

/obj/item/weapon/dice/d20/cursed/pickup(mob/user as mob)
	..()
	if(deactivated == 0)
		to_chat(user, "<span class='sinister'>Are you feeling lucky?</span>")

/obj/item/weapon/dice/d20/cursed/diceroll(mob/user as mob, thrown)
	..()
	if(deactivated == 0) //If the dice has power then something will happen
		if(istype(user,/mob/living/carbon/human)) //check that a humanoid is rolling the dice; Xenomorphs / Sillicons need not apply.
			message_admins("[key_name(user)] has [thrown? "used" : "thrown"] a cursed dice and rolled [result]")
			log_game("[key_name(user)] has [thrown? "used" : "thrown"] a cursed dice and rolled [result]")
			var/mob/living/carbon/human/h = user
			switch(result)
				if(1)
					to_chat(user, "<span class=sinister><B>A natural failure, your poor roll has cursed you. Better luck next time! </span></B>")
					h.flash_eyes(visual = 1)
					if(h.species.name != "Tajaran")
						if(h.set_species("Tajaran"))
							h.regenerate_icons()
						to_chat(user, "<span class=danger><B>You have been turned into a disgusting catbeast! </span></B>")
					else
						for(var/datum/organ/external/E in h.organs) //Being a catbeast doesn't exempt you from getting a curse just because you cannot turn into a catbeast again.
							E.droplimb(1)
				if(2 to 5)
					to_chat(user, "<span class=sinister><B>It could be worse, but not much worse! Enjoy your curse! </span></B>")
					h.flash_eyes(visual = 1)
					switch(pick(1,2,3))
						if(1)
							for(var/datum/organ/external/E in h.organs)
								E.droplimb(1)
						if(2)
							var/obj/item/clothing/shoes/kneesocks/kneesock = new /obj/item/clothing/shoes/kneesocks
							kneesock.canremove = 0
							var/obj/item/clothing/suit/maidapron/apron = new /obj/item/clothing/suit/maidapron
							apron.canremove = 0
							var/obj/item/clothing/head/kitty/kitty_ears = new /obj/item/clothing/head/kitty
							kitty_ears.canremove = 0
							kitty_ears.anime = TRUE
							kitty_ears.cringe = TRUE
							var/obj/item/clothing/under/maid/maid_uniform = new /obj/item/clothing/under/maid
							maid_uniform.canremove = 0
							if(h.w_uniform)
								h.drop_from_inventory(h.w_uniform)
							if(h.head)
								h.drop_from_inventory(h.head)
							if(h.wear_suit)
								h.drop_from_inventory(h.wear_suit)
							if(h.shoes)
								h.drop_from_inventory(h.shoes)
							h.equip_to_slot(maid_uniform,slot_w_uniform)
							h.equip_to_slot(kneesock,slot_shoes)
							h.equip_to_slot(apron,slot_wear_suit)
							h.equip_to_slot(kitty_ears,slot_head)
							to_chat(user, "<span class=danger><B>You have been turned into a disgusting faggot! </span></B>")
						if(3)
							if(h.species.name != "Tajaran") // Catbeasts don't get to roll the dice and turn into monsters.
								var/list/valid_species = (all_species - list("Krampus", "Horror"))
								for(var/datum/organ/external/E in h.organs)
									E.species = all_species[pick(valid_species)]
									h.regenerate_icons()
								to_chat(user, "<span class=danger><B>You have been turned into a disgusting monster! </span></B>")
							else
								for(var/datum/organ/external/E in h.organs)
									E.droplimb(1) //Catbeasts lose limbs

				if(6 to 9)
					to_chat(user, "<span class=sinister></B>You have rolled low and shall receive a curse! It could be a lot worse however! </span></B>")
					h.flash_eyes(visual = 1)
					switch(pick(1,2,3,4))
						if(1)
							user.dna.SetSEState(DEAFBLOCK,1)
							user.dna.SetSEState(MUTEBLOCK,1)
							user.dna.SetSEState(BLINDBLOCK,1)
							genemutcheck(user,DEAFBLOCK,null,MUTCHK_FORCED)
							genemutcheck(user,MUTEBLOCK,null,MUTCHK_FORCED)
							genemutcheck(user,BLINDBLOCK,null,MUTCHK_FORCED)
							user.update_mutations()
							to_chat(user, "<span class=danger><B>You've gone blind, deaf and mute! </span></B>")
						if(2)
							for(var/datum/organ/external/E in h.get_organs(LIMB_LEFT_ARM, LIMB_RIGHT_ARM))
								E.droplimb(1)
						if(3)
							if(h.species.name != "Tajaran") //someone who was made a catbeast by the dice can't become a different species by getting lucky
								switch(pick(1,2,3))
									if(1)
										if(h.species.name != "Unathi")
											if(h.set_species("Unathi"))
												h.regenerate_icons()
											to_chat(user, "<span class=danger><B>You have been turned into a disgusting lizard! </span></B>")
										else
											for(var/datum/organ/external/E in h.get_organs(LIMB_LEFT_ARM, LIMB_RIGHT_ARM)) //Someone who has already become a lizard can't get out of receiving a curse and so they lose their arms instead
												E.droplimb(1)
									if(2)
										if(h.species.name != "Skrell")
											if(h.set_species("Skrell"))
												h.regenerate_icons()
											to_chat(user, "<span class=danger><B>You have been turned into a disgusting squidman! </span></B>")
										else
											for(var/datum/organ/external/E in h.get_organs(LIMB_LEFT_ARM, LIMB_RIGHT_ARM)) //Someone who has already become a squid can't get out of receiving a curse and so they lose their arms instead
												E.droplimb(1)
									if(3)
										if(h.species.name != "Vox")
											if(h.set_species("Vox"))
												h.regenerate_icons()
											to_chat(user, "<span class=danger><B>You have been turned into a dumb, diseased bird! </span></B>")
										else
											for(var/datum/organ/external/E in h.get_organs(LIMB_LEFT_ARM, LIMB_RIGHT_ARM))
												E.droplimb(1)
						if(4)
							h.adjustBrainLoss(200)
							user.reagents.add_reagent(NUTRIMENT, 1000)
							user.overeatduration = 1000
							to_chat(user, "<span class=danger><B>In this moment you feel euphoric! </span></B>")

				if(10 to 12)
					to_chat(user, "<span class=sinister><B>You get nothing. No curse or reward! </span></B>")
				if(13)
					to_chat(user, "<span class=sinister><B>You've rolled 13! The cursed dice is broken! </span></B>")
					explosion(get_turf(src), 0, 0, 4, 7, whodunnit = user)
					to_chat(user, "<span class=danger><B>The dice explosively shatters! </span></B>")
					qdel(src)

				if(14 to 19)
					to_chat(user, "<span class=sinister><B>You've rolled well and shall be rewarded! </span></B>")
					switch(pick(1,2,3,4,5,6,7))
						if(1)
							user.dna.SetSEState(INCREASERUNBLOCK,1)
							user.dna.SetSEState(SMALLSIZEBLOCK,1)
							genemutcheck(user,INCREASERUNBLOCK,null,MUTCHK_FORCED)
							genemutcheck(user,SMALLSIZEBLOCK,null,MUTCHK_FORCED)
							user.update_mutations()
							to_chat(user, "<span class=danger><B>You have been made faster! </span></B>")
						if(2)
							user.dna.SetSEState(XRAYBLOCK,1)
							user.dna.SetSEState(TELEBLOCK,1)
							genemutcheck(user, XRAYBLOCK,null,MUTCHK_FORCED)
							genemutcheck(user,TELEBLOCK,null,MUTCHK_FORCED)
							user.update_mutations()
							to_chat(user, "<span class=danger><B>You have been granted vision! </span></B>")
						if(3)
							user.dna.SetSEState(COLDBLOCK,1)
							user.dna.SetSEState(FIREBLOCK,1)
							user.dna.SetSEState(NOBREATHBLOCK,1)
							genemutcheck(user,COLDBLOCK,null,MUTCHK_FORCED)
							genemutcheck(user,FIREBLOCK,null,MUTCHK_FORCED)
							genemutcheck(user,NOBREATHBLOCK,null,MUTCHK_FORCED)
							user.update_mutations()
							to_chat(user, "<span class=danger><B>You have been granted protection! </span></B>")
						if(4)
							new /obj/item/stack/sheet/mineral/gold(user.loc, 25)
							to_chat(user, "<span class=danger)(B>You have been reward in gold! </span></B>")
						if(5)
							new /obj/item/stack/sheet/mineral/silver(user.loc, 25)
							to_chat(user, "<span class=danger><B>You have been rewarded in silver! </span></B>")
						if(6)
							to_chat(user, "<span class=danger><B>You have been reward with a fancy new costume! </span></B>")
							switch(pick(1,2,3))
								if(1)
									new /obj/item/clothing/under/bikersuit(user.loc, user)
									new /obj/item/clothing/head/helmet/biker(user.loc, user)
									new /obj/item/clothing/shoes/mime/biker(user.loc, user)
									new /obj/item/clothing/gloves/bikergloves(user.loc, user)
								if(2)
									new /obj/item/clothing/under/officeruniform(user.loc, user)
									new /obj/item/clothing/suit/officercoat(user.loc, user)
									new /obj/item/clothing/head/naziofficer(user.loc, user)
									new /obj/item/clothing/shoes/jackboots(user.loc, user)
								if(3)
									new /obj/item/clothing/head/helmet/richard(user.loc, user)
									new /obj/item/clothing/under/jacketsuit(user.loc, user)
						if(7)
							to_chat(user, "<span class=danger><B>You have been reward with a selection of random potions! </span></B>")
							new /obj/item/weapon/storage/bag/potion/dice_potion_bundle(user.loc, user)


				if(20)
					to_chat(user, "<span class=sinister><B>A perfect roll! enjoy your reward! </span></B>")
					new /obj/item/stack/sheet/mineral/phazon(user.loc, 10)
					new /obj/item/stack/sheet/mineral/diamond(user.loc, 10)
					new /obj/item/stack/sheet/mineral/clown(user.loc, 10)
					user.dna.SetSEState(XRAYBLOCK,1)
					user.dna.SetSEState(TELEBLOCK,1)
					user.dna.SetSEState(INCREASERUNBLOCK,1)
					user.dna.SetSEState(SMALLSIZEBLOCK,1)
					user.dna.SetSEState(COLDBLOCK,1)
					user.dna.SetSEState(NOBREATHBLOCK,1)
					user.dna.SetSEState(FIREBLOCK,1)
					genemutcheck(user,XRAYBLOCK,null,MUTCHK_FORCED)
					genemutcheck(user,TELEBLOCK,null,MUTCHK_FORCED)
					genemutcheck(user,INCREASERUNBLOCK,null,MUTCHK_FORCED)
					genemutcheck(user,SMALLSIZEBLOCK,null,MUTCHK_FORCED)
					genemutcheck(user,COLDBLOCK,null,MUTCHK_FORCED)
					genemutcheck(user,NOBREATHBLOCK,null,MUTCHK_FORCED)
					genemutcheck(user,FIREBLOCK,null,MUTCHK_FORCED)
					user.update_mutations()
					to_chat(user, "<span class=danger><B>You have been rewarded handsomely with rare minerals and powers! </span></B>")

			if(prob(15))
				if(!infinite)
					deactivated = 1
					user.visible_message("<span class=danger><B>The dice shudders and loses its power! </span></B>")
					name = "d20"
					desc = "A die with twenty sides. The prefered die to throw at the GM."
				else
					return 0
	else
		return 0

/obj/item/weapon/dice/d20/cursed/infinite
	infinite = 1

/obj/item/weapon/dice/d20/cursed/unfair
	sides = 12 //unfair varient will never roll higher then 12, but it looks like a normal mysterious d20 and otherwise acts like one

//####Borg Die
/obj/item/weapon/dice/borg //8 in 1
	name = "digi-d6"
	desc = "A device that simulates dice rolls.\nIt has a small button to change the mode."
	var/possible_sides = list(2,4,6,8,10,12,20,100)
	var/datum/context_click/digi_die/dd

/obj/item/weapon/dice/borg/New()
	..()
	underlays.len = 0
	underlays += image(icon = icon, icon_state = "ddbg")
	dd = new(src)

/obj/item/weapon/dice/borg/attack_self(mob/user, params)
	if(!user.incapacitated() && is_holder_of(user, src))
		if(dd.action(null, user, params))
			return
		..()

/obj/item/weapon/dice/borg/AltClick()
	if(usr.incapacitated() || !is_holder_of(usr, src))
		return ..()
	set_sides(usr)

/datum/context_click/digi_die/return_clicked_id(x_pos, y_pos)
	if(23 <= x_pos && x_pos <= 26) //yellow bit
		if(23 <= y_pos && y_pos <= 26)
			return 1

/datum/context_click/digi_die/action(obj/item/used_item, mob/user, params)
	var/obj/item/weapon/dice/borg/d = holder
	if(return_clicked_id_by_params(params))
		d.set_sides(user)
		return 1

/obj/item/weapon/dice/borg/proc/set_sides(mob/user)
	var/S = input("Number of sides:") as null|anything in possible_sides
	if(user.incapacitated() || !is_holder_of(user, src)) //sanity
		return
	if (S)
		if(S == 100)
			name = "digi-d00"
			icon_state = "d00"
			sides = 10
			multiplier = 10
		else
			name = "digi-d[S]"
			icon_state = "d[S]"
			sides = S
			multiplier = 0
		result = 1 //For icon
		update_icon()
