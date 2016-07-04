new TotalDrinks[MAXPLAYERS + 1];
new BuildingDrinks[MAXPLAYERS + 1];
new DeadRingerDrinks[MAXPLAYERS + 1];
new MedicDrinks[MAXPLAYERS + 1];
new GivenDrinks[MAXPLAYERS + 1];


stock DG_Drinks_GivePlayerDeathDrinks(Handle:event, const String:name[]) {
	new bool:buildingDeath = StrEqual(name,"object_destroyed",false);

	//Get user ids of people that the event happend to
	new victim_id = GetEventInt(event, "userid")
	new attacker_id = GetEventInt(event, "attacker")
	new assister_id = GetEventInt(event,"assister")

	//Get their client indexs
	new victim = GetClientOfUserId(victim_id);
	new attacker = GetClientOfUserId(attacker_id);
	new assister = GetClientOfUserId(assister_id);

	new customkill = GetEventInt(event, "customkill");

	new Float:atPos[3];
	new Float:vicPos[3];
	GetEntPropVector(attacker, Prop_Data, "m_vecOrigin", atPos);
	GetEntPropVector(victim, Prop_Data, "m_vecOrigin", vicPos);
	new Float:attackerDistance = GetVectorDistance(atPos, vicPos);

	if (victim == 0) {
		return;
	}

	new flags = 0;
	if (!buildingDeath) {
		flags = GetEventInt(event,"death_flags")
		//Only kill the sprite if its a player death
		DG_Effects_KillSprite(victim);
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
	new bool:vicDG  = DG_IsPlayerPlaying(vicName);
	new bool:atDG   = DG_IsPlayerPlaying(attackName);
	new bool:asDG   = DG_IsPlayerPlaying(assistName);

	//Exit if vic isnt DGin
	if (!vicDG) {
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

			DG_Database_AddDrinks(victim,0,victim,6,0,6,"train");

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
			//Set the attacker to a player (if you want to continue flow, otherwise this stops)
			if (GetEventInt(event,"damagebits") & DMG_FALL) {
				new parachute = GetEntProp(victim, Prop_Send, "m_bParachuteEquipped");
				if (parachute == 1) {
					attacker = victim;
				}
			}
			else {
				return;
			}
		}
	}

	new bool:tauntKill = (StrContains(weaponName,"taunt",false) != -1);

	//Check for domination kill
	new bool:atDomRev = (flags & 1 || flags & 4);
	new bool:asDomRev = (flags & 2 || flags & 8) && asDG;

	new healingTarget = TF2_GetHealingTarget(victim);
	if (healingTarget != -1) {
		new patient = GetClientOfUserId(healingTarget);
		new String:patientName[100];
		GetClientName(patient, patientName,sizeof(patientName))
		if (DG_IsPlayerPlaying(patientName) && atDG) {
			MedicDrinks[patient] += 1;
		}
	}

	if (buildingDeath) {
		BuildingDrinks[victim] += 1;
		//should this update for dead ringer coward deaths?
		DG_Database_AddDrinks(atDG ? attacker : 0, asDG ? assister : 0, victim, 1, 1, 1, weaponName);

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

		if (TF2_GetPlayerClass(victim) == TF2_GetClass("medic") && (atDG || asDG) && attacker != victim) {
			new uberWeapon = GetPlayerWeaponSlot(victim, 1);
			new Float:chargeLevel = GetEntPropFloat(uberWeapon, Prop_Send, "m_flChargeLevel");
			if (chargeLevel > 0.99) {
				drinkCount += 1;
				atDrinkCount += 1;
				StrCat(reason,sizeof(reason),", you died with full ubercharge");
				Format(drinkTextBuffer, sizeof(drinkTextBuffer), "[+1]You died with full ubercharge!");
				PushArrayString(drinkText, drinkTextBuffer);
			}
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

		//Market gardener jousting (both players using market gardener, kill in midair)
		if (atDG) {
			new attackerWeapon = TF2_GetCurrentWeapon(attacker);
			new victimWeapon = TF2_GetCurrentWeapon(victim);
			new attackerWeaponIndex = GetEntProp(attackerWeapon, Prop_Send, "m_iItemDefinitionIndex");
			new victimWeaponIndex = GetEntProp(victimWeapon, Prop_Send, "m_iItemDefinitionIndex");
			if (attackerWeaponIndex == 416 && victimWeaponIndex == 416) { //market gardener weapon index is 416
				//Were both players in the air?
				if (!(GetEntityFlags(victim) & (FL_ONGROUND)) && !(GetEntityFlags(attacker) & (FL_ONGROUND))) {
					drinkCount += 4;
					atDrinkCount += 4;
					StrCat(reason, sizeof(reason), ", bested mid air with a shovel");
					if (GetEntProp(attacker, Prop_Send, "m_bParachuteEquipped")) {
						//One less drink if the attacker is parachuting
						drinkCount -= 1;
						atDrinkCount -= 1;
						PushArrayString(drinkText, "[+3]Bested mid air with a shovel");
					} else {
						PushArrayString(drinkText, "[+4]Bested mid air with a shovel");	
					}
				}
			}
		}

		//Huntsman shooting rocket jumpers out of the air
		if (atDG) {
			if (!(GetEntityFlags(victim) & FL_ONGROUND) && (StrEqual(weaponName,"huntsman",false) || StrEqual(weaponName,"deflect_arrow",false))) {
				new victimWeapon = GetPlayerWeaponSlot(victim, 0);
				new victimWeaponIndex = GetEntProp(victimWeapon, Prop_Send, "m_iItemDefinitionIndex");
				if (victimWeaponIndex == 237) { //Rocket jumper weapon index

					new drinks = 0;
					if (StrEqual(weaponName,"deflect_arrow",false)) {
						drinks += 4;
					}
					new feetDistance = RoundToFloor(attackerDistance / 32); //Source engine units are generally 16units = 1ft, but measurements are also comically oversized.
					if (attackerDistance <= 400) {
						drinks += 2;
					}
					else if (attackerDistance > 800) {
						drinks += RoundToFloor(attackerDistance / 400);
					}
					new String:msg[150];
					if (customkill != TF_CUSTOM_HEADSHOT) {
						drinks += 1;
						drinkCount += drinks;
						atDrinkCount += drinks;
						Format(msg, sizeof(msg), "[+%i]Shot out of the air from %i feet", drinks, feetDistance);
						StrCat(reason, sizeof(reason), " , shot out of the air");
						PushArrayString(drinkText, msg);
					} else {
						drinks += 3;
						drinkCount += drinks;
						atDrinkCount += drinks;
						Format(msg, sizeof(msg), "[+%i]Headshot out of the air from %i feet", drinks, feetDistance);
						StrCat(reason, sizeof(reason), " , headshot out of the air");
						PushArrayString(drinkText, msg);
					}	
				}
			}
		}

		if (flags & TF_DEATHFLAG_DEADRINGER ) {
			DeadRingerDrinks[victim] += drinkCount;
			Format(drinkTextBuffer, sizeof(drinkTextBuffer), "...but you were dead ringing");
			PushArrayString(drinkText, drinkTextBuffer);
			//because fake death
			return;
		}

		//Suicides
		if (victim == attacker) {
			drinkCount += 2;
			atDrinkCount = 0;
			reason =  "killed by yourself";
			PushArrayString(drinkText, "[+1]You killed yourself");

			if (GetEventInt(event,"damagebits") & DMG_FALL) {
				new parachute = GetEntProp(victim, Prop_Send, "m_bParachuteEquipped");
				if (parachute == 1) {
					TotalDrinks[victim] += 2;
					drinkCount += 2;
					StrCat(reason, sizeof(reason), ", you fell to your death wearing a parachute");
					PushArrayString(drinkText, "[+2]Fell to your death wearing a parachute");
				}
			}
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
		DG_Effects_CreateDeathEffect(victim, drinkCount);

		//Give them the victim their drinks
		TotalDrinks[victim] += drinkCount;
		GivenDrinks[attacker] += atDrinkCount;
		GivenDrinks[assister] += asDrinkCount;
		DG_Drinks_GiveDrinks(victim, drinkCount, attacker, assister, atDrinkCount, asDrinkCount, weaponName, reason, drinkText);
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

stock DG_Drinks_GiveDrinks(victim, drinkCount, attacker, assister, at_drinks, as_drinks, String:weaponName[], String:reason[], Handle:menuLines) {
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
	new bool:atDG   = DG_IsPlayerPlaying(attackName);
	new bool:asDG   = DG_IsPlayerPlaying(assistName);
	//Print out all this info to the victim

	//Now the taunt for that player
	new String: steamID[32];
	GetClientAuthId(attacker,AuthId_Steam2,steamID,sizeof(steamID));
	new String:attaunt[100];
	DG_Taunts_GetTaunt(steamID,attaunt,sizeof(attaunt),false);

	PrintCenterText(victim,"%s DRINK %d BITCH",attaunt, drinkCount);
	PrintToChat(victim,"%sYou were %s drink %d",msgColor, reason, drinkCount);

	if (asDG) {
		if (victim != attacker) {
			PrintToChat(attacker, "%sYou and %s made %s drink %d. Good job!",msgColor,assistName,vicName,drinkCount);		
		}
		PrintToChat(assister, "%s%s and You made %s drink %d. Good job!",msgColor,attackName,vicName,drinkCount);	
	}
	else {
		if (victim != attacker) {
			PrintToChat(attacker,"%sYou made %s drink %d. Good job!",msgColor, vicName,drinkCount);	
		}
	}
	if (GetConVarBool(dgDebug)) {
		EmitSoundToClient(victim,"vo/burp05.mp3");
		DG_Database_AddDrinks(atDG ? attacker : 0, asDG ? assister : 0, victim, at_drinks, as_drinks, drinkCount, weaponName);
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

public Action:DG_Drinks_MyStats(int client, args) {
	PrintToChat(client, "%sYou've had %i drinks this round",msgColor, TotalDrinks[client]);
	PrintToChat(client, "%sYou've made others drink %i drinks this round",msgColor, GivenDrinks[client]);
	return Plugin_Handled;
}