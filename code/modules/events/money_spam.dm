/datum/event/pda_spam
	endWhen = 900 //No need to overdo it
	var/time_failed = 0
	var/obj/machinery/message_server/useMS

/datum/event/pda_spam/can_start()
	return 50

/datum/event/pda_spam/setup()
	time_failed = world.time
	for(var/obj/machinery/message_server/MS in message_servers)
		if(MS.is_functioning())
			useMS = MS
			break

/datum/event/pda_spam/tick()
	if(!useMS || !useMS.is_functioning())
		useMS = null
		if(message_servers)
			for (var/obj/machinery/message_server/MS in message_servers)
				if(MS.is_functioning())
					useMS = MS
					break

	if(useMS)
		time_failed = world.time
		if(prob(2))
			// /obj/machinery/message_server/proc/send_pda_message(var/recipient = "",var/sender = "",var/message = "")
			var/obj/item/device/pda/P
			var/list/viables = get_viewable_pdas()
			if(!viables.len)
				return
			P = pick(viables)

			var/datum/pda_app/spam_filter/filter_app = locate(/datum/pda_app/spam_filter) in P.applications
			if(filter_app && (filter_app.function == 2))
				return //Spam blocked!

			var/sender
			var/message
			switch(pick(1, 2, 3, 4, 5, 6, 7, 8))
				if(1)
					sender = pick("MaxBet", "MaxBet Online Casino", "There is no better time to register", "I'm excited for you to join us")
					message = pick("Triple deposits are waiting for you at MaxBet Online when you register to play with us.", \
					"You can qualify for a 200% Welcome Bonus at MaxBet Online when you sign up today.", \
					"Once you are a player with MaxBet, you will also receive lucrative weekly and monthly promotions.", \
					"You will be able to enjoy over 450 top-flight casino games at MaxBet.")
				if(2)
					sender = pick(300;"QuickDatingSystem", 200;"Find your russian bride", 50;"Tajaran beauties are waiting", 50;"Find your secret skrell crush", 50;"Beautiful unathi brides")
					message = pick("Your profile caught my attention and I wanted to write and say hello (QuickDating).", \
					"If you will write to me on my email [pick(first_names_female)]@[pick(last_names)].[pick("ru","ck","tj","ur","nt")] I shall necessarily send you a photo (QuickDating).", \
					"I want that we write each other and I hope, that you will like my profile and you will answer me (QuickDating).", \
					"You have (1) new message!", \
					"You have (2) new profile views!")
				if(3)
					sender = pick("Galactic Payments Association", "Better Business Bureau", "Tau Ceti E-Payments", "Nanotrasen Finance Department", "Luxury Replicas")
					message = pick("Luxury watches for Blowout sale prices!", \
					"Watches, Jewelry & Accessories, Bags & Wallets !", \
					"Deposit 100$ and get 300$ totally free!", \
					" 100K NT.|WOWGOLD �nly $89            <HOT>", \
					"We have been filed with a complaint from one of your customers in respect of their business relations with you.", \
					"We kindly ask you to open the COMPLAINT REPORT (attached) to reply on this complaint..")
				if(4)
					sender = pick("Buy Dr. Maxman", "Having dysfuctional troubles?")
					message = pick("DR MAXMAN: REAL Doctors, REAL Science, REAL Results!", \
					"Dr. Maxman was created by George Acuilar, M.D, a CentComm Certified Urologist who has treated over 70,000 patients sector wide with 'male problems'.", \
					"After seven years of research, Dr Acuilar and his team came up with this simple breakthrough male enhancement formula.", \
					"Men of all species report AMAZING increases in length, width and stamina.")
				if(5)
					sender = pick("Dr", "Crown prince", "King Regent", "Professor", "Captain")
					sender += " [pick("Robert", "Alfred", "Josephat", "Kingsley", "Sehi", "Zbahi")] [pick("Mugawe", "Nkem", "Gbatokwia", "Nchekwube", "Ndim", "Ndubisi")]"
					message = pick("YOUR FUND HAS BEEN MOVED TO [pick("Salusa", "Segunda", "Cepheus", "Andromeda", "Gruis", "Corona", "Aquila", "Asellus")] DEVELOPMENTARY BANK FOR ONWARD REMITTANCE.", \
					"We are happy to inform you that due to the delay, we have been instructed to IMMEDIATELY deposit all funds into your account", \
					"Dear fund beneficiary, We have please to inform you that overdue funds payment has finally been approved and released for payment", \
					"Due to my lack of agents I require an off-world financial account to immediately deposit the sum of 1 POINT FIVE MILLION credits.", \
					"Greetings sir, I regretfully to inform you that as I lay dying here due to my lack ofheirs I have chosen you to receive the full sum of my lifetime savings of 1.5 billion credits")
				if(6)
					sender = pick("Nanotrasen Morale Divison", "Feeling Lonely?", "Bored?", "www.wetskrell.nt")
					message = pick("The Nanotrasen Morale Division wishes to provide you with quality entertainment sites.", \
					"WetSkrell.nt is a xenophillic website endorsed by NT for the use of male crewmembers among it's many stations and outposts.", \
					"Wetskrell.nt only provides the highest quality of male entertaiment to Nanotrasen Employees.", \
					"Simply enter your Nanotrasen Bank account system number and pin. With three easy steps this service could be yours!")
				if(7)
					sender = pick("You have won free tickets!","Click here to claim your prize!","You are the 1000th vistor!","You are our lucky grand prize winner!")
					message = pick("You have won tickets to the newest ACTION JAXSON MOVIE!", \
					"You have won tickets to the newest crime drama DETECTIVE MYSTERY IN THE CLAMITY CAPER!", \
					"You have won tickets to the newest romantic comedy 16 RULES OF LOVE!", \
					"You have won tickets to the newest thriller THE CULT OF THE SLEEPING ONE!")
				if(8)
					sender = "Sponsored Content from " + pick("*buzzFeed", "ViralBluespace", "Clickvox", "Daily Honk")
					message = pick("This Assistant Died and Not a Word Was Said, Here’s Why", \
					"Five SME Setups That Will Make You Say, \"I Can't Believe That Works!\" (Number Four Will Shock You)", \
					"Is Your HoP A Traitor?... He Is, If He Does These Five Things. Click And Find Out!", \
					"These Scientists TRIPLED An Assistant's IQ - The Results Will Break Your Heart", \
					"Throw Away Your Slim-Belt! What This One Woman Did With a Plastic Bag Will Shock You!", \
					"Two Close Friends Went Exploring A Derelict Station. What They Found Is Chilling.", \
					"She Gave A Homeless Assistant A Free Meal, What Happened Next Is Incredible")

			useMS.send_pda_message("[P.owner]", sender, message)

			if(prob(50)) //Give the AI an increased chance to intercept the message
				for(var/mob/living/silicon/ai/ai in mob_list)
					//Allows other AIs to intercept the message but the AI won't intercept their own message.
					if(ai.aiPDA != P && ai.aiPDA != src)
						ai.show_message("<i>Intercepted message from <b>[sender]</b></i> (Unknown) <i>to <b>[P:owner]</b>: [message]</i>")

			var/datum/pda_app/messenger/message_app = locate(/datum/pda_app/messenger) in P.applications
			if(message_app) //If no messenger app these get ignored, lucky
				message_app.tnote["msg_id"] = "<i><b>&larr; From [sender] (Unknown):</b></i><br>[message]<br>"
				msg_id++

			if(!filter_app || (filter_app.function == 0)) //Checking if the PDA has the spam filtering app installed
				if(message_app && !message_app.silent)
					playsound(P.loc, 'sound/machines/twobeep.ogg', 50, 1)
				for(var/mob/O in hearers(3, P.loc))
					if(message_app && !message_app.silent)
						O.show_message(text("[bicon(P)] *[message_app.ttone]*"))
			//Search for holder of the PDA.
			var/mob/living/L = null
			if(P.loc && isliving(P.loc))
				L = P.loc
			//Maybe they are a pAI!
			else
				L = get_holder_of_type(P, /mob/living/silicon)

			if(L && (!filter_app || (filter_app.function == 0)))//the owner will still be able to manually read the spam in his Message log.
				to_chat(L, "[bicon(P)] <b>Message from [sender] (Unknown), </b>\"[message]\" (<a href='byond://?src=\ref[src];choice=Message;skiprefresh=1;target=\ref[src]'>Reply</a>)")

	else if(world.time > time_failed + 1200)
		//if there's no server active for two minutes, give up
		kill()
