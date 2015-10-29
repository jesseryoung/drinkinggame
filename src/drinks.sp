new TotalDrinks[MAXPLAYERS + 1];
new BuildingDrinks[MAXPLAYERS + 1];
new DeadRingerDrinks[MAXPLAYERS + 1];
new MedicDrinks[MAXPLAYERS + 1];
new GivenDrinks[MAXPLAYERS + 1];

stock GivePlayerDeathDrinks(Handle:event, const String:name[]) {
	new bool:buildingDeath = StrEqual(name,"object_destroyed",false);

	//Get user ids of people that the event happend to
	new victim_id = GetEventInt(event, "userid")
	new attacker_id = GetEventInt(event, "attacker")
	new assister_id = GetEventInt(event,"assister")

	//Get their client indexs
	new victim = GetClientOfUserId(victim_id);
	new attacker = GetClientOfUserId(attacker_id);
	new assister = GetClientOfUserId(assister_id);

	if (victim == 0) {
		return;
	}

	new flags = 0;
	if (!buildingDeath) {
		flags = GetEventInt(event,"death_flags")
		//Only kill the sprite if its a player death
		KillSprite(victim);
	}

	//Get weapon that caused death
	new String:weaponName[128];
	GetEventString(event,"weapon",weaponName, 128);


	//Get their names
	new String:vicName[50];
	new String:attackName[50];
	new String:assistName[50];

	GetClientName(victim, vicName,sizeof(vicName))
	GetClientName(attacker, attackName,sizeof(attackName))
	GetClientName(assister, assistName,sizeof(assistName))

	//See whos playin DG
	new bool:vicDCG = willDrink(vicName);
	new bool:vicDG  = mayDrink (vicName);
	new bool:atDG   = causesDrinks(attackName);
	new bool:asDG   = causesDrinks(assistName);

	//Exit if vic isnt DGin
	if (!vicDG && !vicDCG) {
		return;
	}

	new Handle:drinkText = CreateArray(12);
	new String:drinkTextBuffer[100];

	if(attacker == 0) {
		if (GetEventInt(event,"damagebits") & DMG_VEHICLE) {
			TotalDrinks[victim] += 6;
			PrintCenterText(victim,"DRINK SIX BITCH");
			PrintToChat(victim,"%sDon't get disTRACKted, drink 6",msgColor);	
			EmitSoundToClient(victim,"vo/burp05.mp3");

			Update_DG_DB(victim,0,victim,6,0,6,"train");

			new Handle:myPanel = CreatePanel();
			new String:panelBuffer[100];
			DrawPanelText(myPanel,"[+6]You got run over by a train");
			DrawPanelText(myPanel,"--------------------------------");
			DrawPanelText(myPanel,"Total: 6");
			DrawPanelText(myPanel," ");
			Format(panelBuffer,sizeof(panelBuffer),"Total drinks this round: %d",TotalDrinks[victim]);
			DrawPanelText(myPanel,panelBuffer);
			DrawPanelItem(myPanel,"Close");
			SendPanelToClient(myPanel,victim,MenuHandler1,5);		
			CloseHandle(myPanel);
			return;
		}
		else {
			return;
		}
	}

	//Handle DCG
	//If vic is DCGin and attacker isn't tell them to drink
	if (vicDCG && !atDG && !asDG) {
		new Handle:myPanel = CreatePanel();
		new String:panelBuffer[100];

		//Increment drinks
		TotalDrinks[victim] += 1;
		PrintCenterText(victim,"DRINK ONE BITCH");
		PrintToChat(victim,"%sYou're DCGn, drink one",msgColor);

		Update_DG_DB(0,0,victim,0,0,1,"");

		new String:say[255];
		Format(say, sizeof(say),"%s killed you, drink %d", attackName, 1);

		EmitSoundToClient(victim,"vo/burp05.mp3");
		//Display the window
		DrawPanelText(myPanel,"[+1]You were killed while DCGing");
		DrawPanelText(myPanel,"--------------------------------");
		DrawPanelText(myPanel,"Total: 1");
		DrawPanelText(myPanel," ");
		Format(panelBuffer,sizeof(panelBuffer),"Total drinks this round: %d",TotalDrinks[victim]);
		DrawPanelText(myPanel,panelBuffer);
		DrawPanelItem(myPanel,"Close");
		SendPanelToClient(myPanel,victim,MenuHandler1,5);
		CloseHandle(myPanel);
		return;
	}

	//We don't care about the distinction between the two anymore
	vicDG = (vicDG || vicDCG);

	new bool:tauntKill = (StrContains(weaponName,"taunt",false) != -1);

	//Check for domination kill
	new bool:atDomRev = (flags & 1 || flags & 4);
	new bool:asDomRev = (flags & 2 || flags & 8) && asDG;

	new healingTarget = TF2_GetHealingTarget(victim);
	if (healingTarget != -1) {
		new patient = GetClientOfUserId(healingTarget);
		new String:patientName[100];
		GetClientName(patient, patientName,sizeof(patientName))
		if (causesDrinks(patientName) && atDG) {
			MedicDrinks[patient] += 1;
		}
	}

	if (buildingDeath) {
		BuildingDrinks[victim] += 1;
		//should this update for dead ringer coward deaths?
		Update_DG_DB(atDG ? attacker : 0, asDG ? assister : 0, victim, 1, 1, 1, weaponName);

		PrintToChat(attacker, "%sYou made %s drink %d. Good job!",msgColor, vicName, 1 );
		if (asDG) {
			PrintToChat(assister,"%sYou made %s drink %d. Good job!",msgColor, vicName, 1 );
		}
	}
	else {
		new drinkCount = 0;
		new atDrinkCount = 0;
		new asDrinkCount = 0;
		new String:reason[150] = "";

		if (atDG) {
			//Add one for attacker drinks caused
			atDrinkCount += 1;
			drinkCount += 1;
			StrCat(reason,sizeof(reason), "killed by [DG]");
			Format(drinkTextBuffer, sizeof(drinkTextBuffer), "[+1]You were killed by %s",attackName);
			PushArrayString(drinkText, drinkTextBuffer);
		}

		//Add one for assiter
		if (asDG && (victim_id != attacker_id)) {
		//Add one for assister drinks caused
			asDrinkCount += 1;
			drinkCount += 1;
			if (atDG) {
				StrCat(reason,sizeof(reason),", kill assisted by [DG]");
			}
			else {
				StrCat(reason,sizeof(reason),"kill assisted by [DG]");
			}
			Format(drinkTextBuffer, sizeof(drinkTextBuffer), "[+1]You were kill-assisted by %s",assistName);
			PushArrayString(drinkText, drinkTextBuffer);
		}

		//Add one if both gotcha
		if (asDG && atDG) {
		//Add one to both because the both helped with this one
			asDrinkCount+=1;
			atDrinkCount+=1;
			drinkCount  +=1;
			PushArrayString(drinkText, "[+1] Drinker synergy bonus drink");
		}

		//Add weapon multipliers only if attacker was dg'n
		if (GetEventInt(event,"customkill") != TF_CUSTOM_BACKSTAB && atDG) {
			new multCount = getDrinkCount(weaponName);
			if (multCount > 0) {
				drinkCount += multCount;
				//Add to attackers drink count
				atDrinkCount+=multCount;
				StrCat(reason,sizeof(reason),", killed using a special weapon");
				Format(drinkTextBuffer, sizeof(drinkTextBuffer), "[+%d]Killed with %s",multCount, weaponName);
				PushArrayString(drinkText, drinkTextBuffer);
			}
		}

		//6 for taunt kill if attacker was dg'n
		if (tauntKill && atDG) {
			drinkCount += 6;
			atDrinkCount+=6;
			StrCat(reason,sizeof(reason),", killed by a taunt kill");
			PushArrayString(drinkText, "[+6]Killed with a taunt kill");
		}

		//2 for attacker domination
		if (atDomRev & atDG) {
			drinkCount += 2;
			atDrinkCount+=2;
			StrCat(reason,sizeof(reason),", [DG] attacker dominated/revenged you");
			Format(drinkTextBuffer, sizeof(drinkTextBuffer),"[+2]You were dominated/revenged by %s",attackName);
			PushArrayString(drinkText, drinkTextBuffer);
		}

		//2 for assister domination
		if (asDomRev && asDG) {
			drinkCount += 2;
			asDrinkCount+=2;
			StrCat(reason,sizeof(reason),", [DG] assister dominated/revenged you");
			Format(drinkTextBuffer, sizeof(drinkTextBuffer), "[+2]You were dominated/revenged by %s",assistName);
			PushArrayString(drinkText, drinkTextBuffer);
		}

		//Display how many drinks that have to take for their building deaths
		if (BuildingDrinks[victim] > 0) {
			drinkCount += BuildingDrinks[victim];
			StrCat(reason,sizeof(reason),", [DG] killed your buildings last life");
			Format(drinkTextBuffer, sizeof(drinkTextBuffer),"[+%d]Your buildings were killed that life",BuildingDrinks[victim]);
			PushArrayString(drinkText, drinkTextBuffer);
		}

		//Add drinks if a [DG] medic killed by [DG] while healing you
		if (MedicDrinks[victim] > 0) {
			drinkCount += MedicDrinks[victim];
			if (strlen(reason) > 1) {
				StrCat(reason,sizeof(reason),", a [DG] medic killed by [DG] while healing you");
			}
			else {
				StrCat(reason,sizeof(reason),"A [DG] medic killed by [DG] while healing you");
			}
			Format(drinkTextBuffer, sizeof(drinkTextBuffer),"[+%d]A medic died healing you that life",MedicDrinks[victim]);
			PushArrayString(drinkText, drinkTextBuffer);
			MedicDrinks[victim] = 0;
		}

		if (flags & TF_DEATHFLAG_DEADRINGER ) {
			DeadRingerDrinks[victim] += drinkCount;
			Format(drinkTextBuffer, sizeof(drinkTextBuffer), "...but you were dead ringing");
			PushArrayString(drinkText, drinkTextBuffer);
			//because fake death
			return;
		}

		//Suicide
		if (victim_id == attacker_id) {
			drinkCount += 2;
			reason =  "killed by yourself";
			PushArrayString(drinkText, "[+1]You killed yourself");
		}

		//Display how many drinks that have to take for their fake deaths
		if (DeadRingerDrinks[victim] > 0) {
			//a victim of his own deception
			drinkCount += DeadRingerDrinks[victim];
			StrCat(reason,sizeof(reason),", you pretended to be killed by [DG]");
			Format(drinkTextBuffer, sizeof(drinkTextBuffer), "[+%d]You would have drank at time of fake death(s)",DeadRingerDrinks[victim]);
			PushArrayString(drinkText, drinkTextBuffer);
		}

		//Find the last , in the string and replace it with and
		new idx = FindCharInString(reason,',',true);
		if (idx != -1) {
			ReplaceString(reason[idx],sizeof(reason),","," and")
		}

		//Create the death effect based on # of drinks
		CreateDeathEffect(victim, drinkCount);

		//Give them the victim their drinks
		TotalDrinks[victim] += drinkCount;
		GiveDrinks(victim, drinkCount, attacker, assister, atDrinkCount, asDrinkCount, weaponName, reason, drinkText);
	}


	if (!buildingDeath) {
		//Means victim died, reset their building destroys
		BuildingDrinks[victim] = 0;
	}

	if (!(flags & TF_DEATHFLAG_DEADRINGER )) {
		//Means victim wasn't faking, reset their faker status
		DeadRingerDrinks[victim] = 0;
	}
}

stock GiveDrinks(victim, drinkCount, attacker, assister, at_drinks, as_drinks, String:weaponName[], String:reason[], Handle:menuLines) {
	if (drinkCount <= 0) {
		return;
	}
	//Get their names
	new String:vicName[50];
	new String:attackName[50];
	new String:assistName[50];

	GetClientName(victim, vicName,sizeof(vicName));
	GetClientName(attacker, attackName,sizeof(attackName));
	GetClientName(assister, assistName,sizeof(assistName));

	//See whos playin DG
	new bool:atDG   = causesDrinks(attackName);
	new bool:asDG   = causesDrinks(assistName);
	//Print out all this info to the victim

	//Now the taunt for that player
	new String: steamID[32];
	GetClientAuthId(attacker,AuthId_Steam2,steamID,sizeof(steamID));
	new String:attaunt[100];
	GetTaunt(steamID,attaunt,sizeof(attaunt),false);

	PrintCenterText(victim,"%s DRINK %d BITCH",attaunt, drinkCount);
	PrintToChat(victim,"%sYou were %s drink %d",msgColor, reason, drinkCount);

	PrintToChat(attacker, "%sYou made %s drink %d. Good job!",msgColor, vicName,drinkCount);
	if (asDG) {
		PrintToChat(assister,"%sYou made %s drink %d. Good job!",msgColor, vicName,drinkCount);
	}
	if (GetConVarBool(dgDebug)) {
		EmitSoundToClient(victim,"vo/burp05.mp3");
		Update_DG_DB(atDG ? attacker : 0, asDG ? assister : 0, victim, at_drinks, as_drinks, drinkCount, weaponName);
	}
	new Handle:panel = CreatePanel();
	new String:panelBuffer[100];
	for (new i=0;i<GetArraySize(menuLines);i++) {
		new String:line[100];
		GetArrayString(menuLines, i, line, sizeof(line));
		DrawPanelText(panel, line);
	}
	DrawPanelText(panel,"--------------------------------");
	Format(panelBuffer,sizeof(panelBuffer),"Total: %d",drinkCount + BuildingDrinks[victim]);
	DrawPanelText(panel,panelBuffer);
	DrawPanelText(panel," ");
	Format(panelBuffer,sizeof(panelBuffer),"Total drinks this round: %d",TotalDrinks[victim]);
	DrawPanelText(panel,panelBuffer);
	DrawPanelItem(panel,"Close");
	SendPanelToClient(panel,victim,MenuHandler1,5);
	CloseHandle(panel);
}

public Action:DGDrinkStatus(int client, args) {
	PrintToChat(client, "You've had %i drinks this round", TotalDrinks[client]);
	PrintToChat(client, "You've made others drink %i drinks this round", GivenDrinks[client]);
	return Plugin_Handled;
}