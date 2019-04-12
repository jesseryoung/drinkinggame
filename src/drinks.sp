public void DG_Drinks_EndDRDrinks(int client) {
	// Bail if no dead ringer drinks for client
	if (DeadRingerDrinks[client] > 0) { return; }
	
	// Play burp sound if not debugging
	if(!GetConVarBool(dgDebug)){
		EmitSoundToClient(client,"vo/burp05.mp3");
	}
	
	// Display dead ringer drink messages
	DG_Msg_DRDrink(client, DeadRingerDrinks[client]);
	
	// Create drink display window
	DrinkWindow window; window.Init(client);
	window.AddDrinkMessage(DeadRingerDrinks[client],"[+%d]You would have drank at time of fake death(s)");
	window.Display();
	
	// Reset Dead Ringer drinks
	DeadRingerDrinks[client] = 0;
}

public void DG_Drinks_EndBuildingDrinks(int client) {
	// Bail if no building drinks for client
	if (BuildingDrinks[client] > 0) { return; }
	
	// Play burp sound if not debugging
	if(!GetConVarBool(dgDebug)){
		EmitSoundToClient(client,"vo/burp05.mp3");
	}
	
	// Display building drink messages
	DG_Msg_BuildingDrink(client, BuildingDrinks[client]);
	
	// Create drink display window
	DrinkWindow window; window.Init(client);
	window.AddDrinkMessage(BuildingDrinks[client],"[+%d]Your buildings were killed that life");
	window.Display();
	
	// Reset building drinks
	BuildingDrinks[client] = 0;
}

stock void DG_Drinks_GivePlayerDeathDrinks(Handle event, const char[] name) {
	if(debugInfo) {
		PrintToServer("Start Drink Giving");
	}
	//// Drink Giving Setup
	
	// Determine if building or DG player was destroyed
	bool buildingDeath = StrEqual(name,"object_destroyed",false);
	
	// Create DG player objects
	DGPlayer victim; victim.Init(event, "userid");
	if (victim.client == 0 || !victim.dg) { return; }	// Bail if no victim or victim is not DG player
	DGPlayer attacker; attacker.Init(event, "attacker");
	DGPlayer assister; assister.Init(event, "assister");
	
	if(debugInfo){
		PrintToServer("victim id=%d client=%d name=%s dg=%d",victim.id,victim.client,victim.name,victim.dg);
		PrintToServer("attacker id=%d client=%d name=%s dg=%d",attacker.id,attacker.client,attacker.name,attacker.dg);
		PrintToServer("assister id=%d client=%d name=%s dg=%d",assister.id,assister.client,assister.name,assister.dg);
	}
	
	// Get customkill value
	int customkill = GetEventInt(event, "customkill");
	
	// Inform attacker/assister of drinks from destroyed buildings
	if (buildingDeath) {
		BuildingDrinks[victim.client] += 1;
		//should this update for dead ringer coward deaths?

		PrintToChat(attacker.client, "%sYou made %s drink %d. Good job!",msgColor, victim.name, 1 );
		if (assister.dg) {
			PrintToChat(assister.client,"%sYou made %s drink %d. Good job!",msgColor, victim.name, 1 );
		}
		
		return;
	}

	// Get death flags
	int flags = GetEventInt(event,"death_flags");
	
	// Remove DG sprite if DG player (not building)
	DG_Effects_KillSprite(victim.client);

	// Get weapon that caused death
	char weaponName[128];
	GetEventString(event,"weapon",weaponName, 128);
	
	// Init drink window
	DrinkWindow drinkWindow; drinkWindow.Init(victim.client);

	//// Drink Conditions
	
	// Attacker is not player or player building
	if(attacker.client == 0) {
		// Victim was hit by train
		if (GetEventInt(event,"damagebits") & DMG_VEHICLE) {
			// Set # of drinks
			int trainDrinks = 6;
			TotalDrinks[victim.client] += trainDrinks;
			
			// Notify player of drinking
			DG_Msg_TrainDrink(victim.client, trainDrinks);
			EmitSoundToClient(victim.client,"vo/burp05.mp3");
			
			// Display drink window to victim
			drinkWindow.AddDrinkMessage(trainDrinks,"[+%d]You got run over by a train");
			drinkWindow.Display();
			
			return;	// Return after displaying drinks
		}
		// Victim fell to their death
		else if (GetEventInt(event,"damagebits") & DMG_FALL) {
			// If victim fell and had parachute on, set self as attacker.
			int parachute = GetEntProp(victim.client, Prop_Send, "m_bParachuteEquipped");
			if (parachute == 1) {
				attacker.Init(event, "userid");
			}
		}
		else {
			return;	// Return if other client == 0 deaths
		}
	}
	
	// Victim was killed by taunt
	bool tauntKill = (StrContains(weaponName,"taunt",false) != -1);

	// Victim was dominated by attacker and/or assister
	bool atDomRev = (flags & 1 || flags & 4);
	bool asDomRev = (flags & 2 || flags & 8) && assister.dg;

	// Give drinks to patient if patient and medic (victim) are DG players
	int healingTarget = TF2_GetHealingTarget(victim.client);
	if (healingTarget != -1) {
		int patient = GetClientOfUserId(healingTarget);
		char patientName[100];
		GetClientName(patient, patientName,sizeof(patientName))
		if (DG_IsPlayerPlaying(patientName) && attacker.dg) {
			MedicDrinks[patient] += 1;
		}
	}

	// Init drink counts and reason message
	int drinkCount = 0;
	int atDrinkCount = 0;
	int asDrinkCount = 0;
	char reason[200] = "";

	// Add one for DG attacker
	if (attacker.dg) {
		if(debugInfo){
			PrintToServer("Killed by DG");
		}
		int attackDrinks = 1;
		//Add one for attacker drinks caused
		atDrinkCount += attackDrinks;
		drinkCount += attackDrinks;
		StrCat(reason,sizeof(reason), "killed by [DG]");
		drinkWindow.AddFormatDrinkMessage(attackDrinks,"[+%d]You were killed by %s",attacker.name);
	}

	//Add one for DG assister (unless victim suicided)
	if (assister.dg && (victim.id != attacker.id)) {
		int assistDrinks = 1;
		//Add one for assister drinks caused
		asDrinkCount += assistDrinks;
		drinkCount += assistDrinks;
		if (attacker.dg) {
			StrCat(reason,sizeof(reason),", kill assisted by [DG]");
		}
		else {
			StrCat(reason,sizeof(reason),"kill assisted by [DG]");
		}
		drinkWindow.AddFormatDrinkMessage(assistDrinks,"[+%d]You were kill-assisted by %s",assister.name);
	}

	//Add one if both gotcha
	if (assister.dg && attacker.dg) {
		int synergyDrinks = 1;
		//Add one to both because the both helped with this one
		drinkCount  +=synergyDrinks;
		asDrinkCount+=synergyDrinks;
		atDrinkCount+=synergyDrinks;
		drinkWindow.AddDrinkMessage(synergyDrinks,"[+%d] Drinker synergy bonus drink");
	}

	//Add weapon multipliers only if attacker was dg'n
	if (GetEventInt(event,"customkill") != TF_CUSTOM_BACKSTAB && attacker.dg) {
		int multCount = getWeaponDrinkCount(weaponName);
		if (multCount > 0) {
			drinkCount += multCount;
			//Add to attackers drink count
			atDrinkCount+=multCount;
			StrCat(reason,sizeof(reason),", killed using a special weapon");
			drinkWindow.AddFormatDrinkMessage(multCount,"[+%d]Killed with %s",weaponName);
		}
	}

	//6 for taunt kill if attacker was dg'n
	if (tauntKill && attacker.dg) {
		int tauntDrinks = 6;
		drinkCount += tauntDrinks;
		atDrinkCount+=tauntDrinks;
		StrCat(reason,sizeof(reason),", killed by a taunt kill");
		drinkWindow.AddDrinkMessage(tauntDrinks,"[+%d]Killed with a taunt kill");
	}

	//2 for attacker domination
	if (atDomRev & attacker.dg) {
		int domDrinks = 2;
		drinkCount += domDrinks;
		atDrinkCount+=domDrinks;
		StrCat(reason,sizeof(reason),", [DG] attacker dominated/revenged you");
		drinkWindow.AddFormatDrinkMessage(domDrinks,"[+%d]You were dominated/revenged by %s",attacker.name);
	}

	//2 for assister domination
	if (asDomRev && assister.dg) {
		int domDrinks = 2;
		drinkCount += domDrinks;
		asDrinkCount+=domDrinks;
		StrCat(reason,sizeof(reason),", [DG] assister dominated/revenged you");
		drinkWindow.AddFormatDrinkMessage(domDrinks,"[+%d]You were dominated/revenged by %s",assister.name);
	}

	// Died while an ubercharge was ready
	if (TF2_GetPlayerClass(victim.client) == TF2_GetClass("medic") && (attacker.dg || assister.dg) && attacker.client != victim.client) {
		int uberDrinks = 1;
		int uberWeapon = GetPlayerWeaponSlot(victim.client, 1);
		float chargeLevel = GetEntPropFloat(uberWeapon, Prop_Send, "m_flChargeLevel");
		if (chargeLevel > 0.99) {
			drinkCount += uberDrinks;
			atDrinkCount += uberDrinks;
			StrCat(reason,sizeof(reason),", you died with full ubercharge");
			drinkWindow.AddDrinkMessage(uberDrinks,"[+%d]You died with full ubercharge!");
		}
	}

	//Display how many drinks that have to take for their building deaths
	if (BuildingDrinks[victim.client] > 0) {
		int destroyedDrinks = BuildingDrinks[victim.client];
		drinkCount += destroyedDrinks;
		StrCat(reason,sizeof(reason),", [DG] killed your buildings last life");
		drinkWindow.AddDrinkMessage(destroyedDrinks,"[+%d]Your buildings were killed that life");
	}

	//Add drinks if a [DG] medic killed by [DG] while healing you
	if (MedicDrinks[victim.client] > 0) {
		int helpYourMedicPleaseDrinks = MedicDrinks[victim.client];
		drinkCount += helpYourMedicPleaseDrinks;
		if (strlen(reason) > 1) {
			StrCat(reason,sizeof(reason),", a [DG] medic killed by [DG] while healing you");
		}
		else {
			StrCat(reason,sizeof(reason),"A [DG] medic killed by [DG] while healing you");
		}
		drinkWindow.AddDrinkMessage(helpYourMedicPleaseDrinks,"[+%d]A medic died healing you that life");
		MedicDrinks[victim.client] = 0;
	}

	//Market gardener jousting (both players using market gardener, kill in midair)
	if (attacker.dg) {
		do {
			int mgIndex = 416;	//market gardener weapon index is 416
			// 4 drinks for market garden kill, 3 drinks if attacker is parachuting.
			int mgDrinks = GetEntProp(attacker.client, Prop_Send, "m_bParachuteEquipped") ? 3 : 4;
			
			// Get weapons for victim and attacker
			int attackerWeapon = TF2_GetCurrentWeapon(attacker.client);
			int victimWeapon = TF2_GetCurrentWeapon(victim.client);
			
			// Skip check if neither player has a weapon
			if (attackerWeapon == -1 || victimWeapon == -1) { break; }
			
			// Get the index # of each weapon
			int attackerWeaponIndex = GetEntProp(attackerWeapon, Prop_Send, "m_iItemDefinitionIndex");
			int victimWeaponIndex = GetEntProp(victimWeapon, Prop_Send, "m_iItemDefinitionIndex");
			
			// Skip check if neither player has market gardener
			if (attackerWeaponIndex != mgIndex || victimWeaponIndex != mgIndex) { 
				break; 
			}
			
			//Were both players in the air?
			if ((GetEntityFlags(victim.client) & (FL_ONGROUND)) || (GetEntityFlags(attacker.client) & (FL_ONGROUND))) { 
				break;
			}
			
			drinkCount += mgDrinks;
			atDrinkCount += mgDrinks;
			StrCat(reason, sizeof(reason), ", bested mid air with a shovel");
			drinkWindow.AddDrinkMessage(mgDrinks,"[+%d]Bested mid air with a shovel");
		} while(0);
	}

	//Huntsman shooting rocket jumpers out of the air
	if (attacker.dg) {
		do {
			int onGroundFlag = GetEntityFlags(victim.client) & FL_ONGROUND;
			bool huntsmanUsed = StrEqual(weaponName,"huntsman",false);
			bool deflectUsed = StrEqual(weaponName,"deflect_arrow",false);
			
			// Skip check if on ground or not huntsman arrow
			if ( onGroundFlag || (!huntsmanUsed && !deflectUsed)) {
				break;
			}
			
			int rjIndex = 237	// Rocket jumper weapon index
			// Get victim's current weapon
			int victimWeapon = GetPlayerWeaponSlot(victim.client, 0);
			int victimWeaponIndex = GetEntProp(victimWeapon, Prop_Send, "m_iItemDefinitionIndex");
			
			// Skip check if victim isn't using rocket jumper weapon
			if (victimWeaponIndex == rjIndex) {
				break;
			}
			
			// Calculate distance
			float attackerDistance = DG_DistanceTo(attacker, victim);
			int feetDistance = RoundToFloor(attackerDistance / 32); //Source engine units are generally 16units = 1ft, but measurements are also comically oversized.
			
			// Add drinks for shots over (attackerDistance / 300)
			int drinks = attackerDistance > 300 ? RoundToFloor(attackerDistance / 300) + 1 : 2;
			// Add drinks if it was a reflect arrow
			if (StrEqual(weaponName,"deflect_arrow",false)) {
				drinks += 4;
			}
			
			// Message buffers
			char reasonMessage[150];
			char windowMessage[150];
			
			// Set more drinks and different messages for headshot
			if (customkill == TF_CUSTOM_HEADSHOT) {
				drinks += 2;
				reasonMessage = " , headshot out of the air";
				windowMessage = "[+%d]Headshot out of the air from %i feet";
			}
			else {
				reasonMessage = " , shot out of the air";
				windowMessage = "[+%d]Shot out of the air from %i feet";
			}
			StrCat(reason, sizeof(reason), reasonMessage);
			char feetString[16];
			IntToString(feetDistance, feetString, sizeof(feetString));
			drinkWindow.AddFormatDrinkMessage(drinks,windowMessage,feetString);
		} while(0);
	}
	
	// Dead ringer pulled a sneaky on ya'
	if (flags & TF_DEATHFLAG_DEADRINGER ) {
		DeadRingerDrinks[victim.client] += drinkCount;
		drinkWindow.AddTextMessage("...but you were dead ringing");
		//because fake death
		return;
	}

	//Suicides
	if (victim.client == attacker.client) {
		do {
			if(debugInfo){
				PrintToServer("Drinks for suicide");
			}
			
			int suicideDrinks = 2;
			drinkCount += suicideDrinks;
			atDrinkCount = 0;	// Clear any accrued attacker drinks
			reason =  "killed by yourself";
			drinkWindow.AddDrinkMessage(suicideDrinks,"[+%d]You killed yourself"); 
	
			// Skip parachute check if not falling
			if (GetEventInt(event,"damagebits") & DMG_FALL) { break; }
			
			// Skip parachute check if parachute isn't equipped
			int parachute = GetEntProp(victim.client, Prop_Send, "m_bParachuteEquipped");
			if (parachute != 1) { break; }
			
			// Apply penalty points for not 'chutin'
			int whoopsDrinks = 2;
			drinkCount += whoopsDrinks;
			StrCat(reason, sizeof(reason), ", you fell to your death wearing a parachute");
			drinkWindow.AddDrinkMessage(whoopsDrinks,"[+%d]Fell to your death wearing a parachute");
		} while(0);
	}

	//Display how many drinks that have to take for their fake deaths
	if (DeadRingerDrinks[victim.client] > 0) {
		//a victim of his own deception
		int drDrinks = DeadRingerDrinks[victim.client];
		drinkCount += drDrinks;
		StrCat(reason,sizeof(reason),", you pretended to be killed by [DG]");
		drinkWindow.AddDrinkMessage(drDrinks,"[+%d]You would have drank at time of fake death(s)");
	}
	
	//// End Drink Checks

	//Find the last , in the string and replace it with and
	int idx = FindCharInString(reason,',',true);
	if (idx != -1) {
		ReplaceString(reason[idx],sizeof(reason),","," and")
	}

	//Create the death effect based on # of drinks
	DG_Effects_CreateDeathEffect(victim.client, drinkCount);

	//Give the victim their drinks and credit the attackers
	TotalDrinks[victim.client] += drinkCount;
	GivenDrinks[attacker.client] += atDrinkCount;
	GivenDrinks[assister.client] += asDrinkCount;
	
	if (debugInfo) {
		PrintToServer("Final drink count: %d", drinkCount);
	}
	
	// Display death drink message if drinks were accrued
	if (drinkCount > 0) {
		DG_Msg_DeathDrink(victim.client, reason, drinkCount);
		
		// Display drink total to attacker and assister
		if (assister.dg && assister.client > 0) {
			if (victim.client != attacker.client && attacker.client > 0) {
				PrintToChat(attacker.client, "%sYou and %s made %s drink %d. Good job!",msgColor,assister.name,victim.name,drinkCount);		
			}
			PrintToChat(assister.client, "%s%s and You made %s drink %d. Good job!",msgColor,attacker.name,victim.name,drinkCount);	
		}
		else {
			if (victim.client != attacker.client && attacker.client > 0) {
				PrintToChat(attacker.client,"%sYou made %s drink %d. Good job!",msgColor, victim.name,drinkCount);	
			}
		}
		
		// buuuuurp
		if (GetConVarBool(dgDebug)) {
			EmitSoundToClient(victim.client,"vo/burp05.mp3");
		}
		
		// Show drink window to victim
		drinkWindow.Display();
	}
	
	// Reset victim's destroyed building count
	BuildingDrinks[victim.client] = 0;
	
	if (!(flags & TF_DEATHFLAG_DEADRINGER )) {
		//Means victim wasn't faking, reset their faker status
		DeadRingerDrinks[victim.client] = 0;
	}
}

public int getWeaponDrinkCount(char[] name) {
	if (GetConVarBool(dgDebug)) {
		return 3;
	}
	//Make sure not to read a bad map
	if (Weapons != INVALID_HANDLE) {
		int wepBonus = 0;
		GetTrieValue(Weapons,name,wepBonus);
		return wepBonus;
	}
	return 0;
}

public Action DG_Drinks_MyStats(int client, int args) {
	PrintToChat(client, "%sYou've had %i drinks this round",msgColor, TotalDrinks[client]);
	PrintToChat(client, "%sYou've made others drink %i drinks this round",msgColor, GivenDrinks[client]);
	return Plugin_Handled;
}

public int DrinkListHandler(Handle menu, MenuAction action, int client, int value) {

	int numDgers = 0;
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i)) {
			continue;
		}

		if  (TotalDrinks[i] > 0) {
			numDgers++;
		}
	}
	if (action == MenuAction_Select) {
		int next = 0;
		int prev = 0;
		//Next and prev is on there
		if (DrinkListStart[client] > 0 && DrinkListStart[client] + 5 < numDgers) {
			prev = 2;
			next = 1;
		} else if (DrinkListStart[client] == 0 && DrinkListStart[client] + 5 < numDgers) {
			next = 1;
		} else if (DrinkListStart[client] > 0) {
			prev = 1;
		}

		if (value == prev) {
			DG_ReadList(client, DrinkListStart[client]-5);
		}
		if (value == next) {
			DG_ReadList(client, DrinkListStart[client] + 5);
		}
	}
}

public int DG_SortByTotalDrinkCount(int elem1, int elem2, const int[] array, Handle hndl) {
	if (TotalDrinks[elem1] < TotalDrinks[elem2]) {
		return 1;
	}
	if (TotalDrinks[elem1] == TotalDrinks[elem2]) {
		return 0;
	}
	else {
		return -1;
	}
}