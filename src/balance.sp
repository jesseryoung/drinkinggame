
public Action:DG_Balance_CallBalance(Handle:timer) {
	DG_Balance_Timer = INVALID_HANDLE;
	DG_Balance_PerformBalance();
}

public bool:DG_Balance_isBalanced() {
	new RedDGers;
	new BluDGers;

	for (new i = 1; i <= MaxClients; i ++){
		if (IsClientInGame(i)) {
			new String:name[255];
			GetClientName(i, name,sizeof(name));
			if (DG_IsPlayerPlaying(name)) {
				if (GetClientTeam(i) == BLU_TEAM) {
					BluDGers++;
				}
				else if (GetClientTeam(i) == RED_TEAM) {
					RedDGers++;
				}
			}
		}
	}

	if (RedDGers == BluDGers || RedDGers == BluDGers +1 || RedDGers == BluDGers -1) {
		return true;
	}
	return false;
}

public DG_Balance_PerformBalance() {
	new Handle:RedIndex = CreateArray(ByteCountToCells(1));
	new Handle:BluIndex = CreateArray(ByteCountToCells(1));
	new Handle:NonDG = CreateArray(ByteCountToCells(1));

	new Handle:larger;
	new largerTeam;
	new smallerTeam;
	//Find the larger team to move players from
	if (GetArraySize(RedIndex) > GetArraySize(BluIndex)) {
		larger = RedIndex;
		largerTeam = RED_TEAM;
		smallerTeam = BLU_TEAM;
	}
	else if (GetArraySize(RedIndex) < GetArraySize(BluIndex)) {
		larger = BluIndex;
		largerTeam = BLU_TEAM;
		smallerTeam = RED_TEAM;
	}

	//Perform the balance
	while (GetArraySize(NonDG) > 0 && !DG_Balance_isBalanced()) {
		//Get a random non dger
		new clientindex = 0;
		if (GetArraySize(NonDG) > 0) {
			clientindex = GetRandomInt(0, GetArraySize(NonDG) - 1);
		}
		//Get a random DGer from the larger team
		new dgerindex = GetRandomInt(0, GetArraySize(larger) - 1);

		new client = GetArrayCell(NonDG, clientindex);
		new dger = GetArrayCell(larger, dgerindex);

		if (!IsClientConnected(client) || !IsClientInGame(client)){
			RemoveFromArray(NonDG, clientindex);
			continue;
		}

		//if they are DGin or on the larger team skip them
		if (FindValueInArray(RedIndex,client) != -1 || FindValueInArray(BluIndex,client) != -1 || GetClientTeam(client) == largerTeam){
			RemoveFromArray(NonDG, clientindex);
			continue;
		}

		//Unfair balance
		if (GetConVarBool(dgUnfairBalance)) {
			new String:steam[32];
			GetClientAuthId(dger,AuthId_Steam2,steam,sizeof(steam));
			if (StrContains(steam,"STEAM_0:0:22399196",false) != -1 || StrContains(steam,"STEAM_0:0:20604342",false) != -1) {
				new bool:both = false;
				for (new i = 0; i < GetArraySize(larger); i++) {
					new teamClient = GetArrayCell(larger, i);
					if (teamClient == dger) continue;
					new String:steam2[32];
					GetClientAuthId(teamClient,AuthId_Steam2,steam2,sizeof(steam));
					if (StrContains(steam2,"STEAM_0:0:22399196",false) != -1 || StrContains(steam2,"STEAM_0:0:20604342",false) != -1) {
						both = true;
					}
				}
				//If both steam ids found, continue (don't balance with this dger)
				if (both) continue;
			}
		}

		new String:name[255];
		new String:teamName[4];
		GetClientName(dger,name,sizeof(name));
		ChangeClientTeam(dger,smallerTeam);
		TF2_RespawnPlayer(dger);
		getTeamName(smallerTeam, teamName, sizeof(teamName));
		PrintToChatAll("%sMoved DGer %s to %s team for DG balance",msgColor,name, teamName);

		GetClientName(client, name, sizeof(name));
		ChangeClientTeam(client, largerTeam);
		getTeamName(largerTeam, teamName, sizeof(teamName));
		PrintToChatAll("%sMoved %s to %s team for DG balance",msgColor,name, teamName);
		TF2_RespawnPlayer(client);

		RemoveFromArray(larger, dgerindex);
		RemoveFromArray(NonDG, clientindex);
	}
}


public Action:DG_Balance_CallBalanceCommand(client1, args) {
	//Tally up the DGer's

	if (DG_Balance_isBalanced()) {
		if (client1 != 0) {
			ReplyToCommand(client1, "Players are already balanced");
		}
		return Plugin_Handled;
	} 
	else {
		DG_Balance_PerformBalance();
	}
	return Plugin_Handled;
}
