public void HookEvents_Init() {
	HookEvent("player_changename",Event_PlayerChangeName);
	HookEvent("player_spawn",Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("object_destroyed",Event_SentryDeath);
	HookEvent("teamplay_round_start",Event_RoundStart);
	HookEvent("teamplay_round_win",Event_RoundWin);
}

enum struct Name {
	char name[32];
	
	void Init(int client) {
		char nameBuf[32];
		GetClientName(client, nameBuf, sizeof(nameBuf));
		strcopy(this.name, 32, nameBuf);
	}
	
	void EventInit(Handle event, const char[] eventName) {
		char nameBuf[32];
		GetEventString(event, eventName, nameBuf, sizeof(nameBuf));
		strcopy(this.name, 32, nameBuf);
	}
	
	bool IsPlaying() {
		return DG_IsPlayerPlaying(this.name);
	}
}

void Event_CreateSprite(int client) {
	// Get team's DG sprite
	int team = GetClientTeam(client);
	char sprite[24];
	strcopy(sprite, 24, (team == RED_TEAM) ? DG_SPRITE_RED_VMT : DG_SPRITE_BLU_VMT);
	
	// Create DG sprite
	DG_Effects_CreateSprite(client, sprite);
}

public void Event_PlayerChangeName(Handle event, const char[] name, bool dontBroadcast) {
	// Get player's previous name, new name, and client ID
	Name newName; newName.EventInit(event,"newname");
	Name oldName; oldName.EventInit(event,"oldname");
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	//If they are dead don't worry about it it will be taken care of at spawn
	if (!IsPlayerAlive(client)) { return; }
	
	//If they have started DGin
	if (newName.IsPlaying() && !GetConVarBool(dgDebug)) {
		// Return if was already DGing
		if (oldName.IsPlaying()) { return; }
		
		Event_CreateSprite(client);
	} 
	// Destroy DG sprite if not playing DG game
	else if(dgSprites[client] > 0) {
		DG_Effects_KillSprite(client);
	}
}

public void Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast) {
	// Bail if debugging
	if (GetConVarBool(dgDebug)) { return; }
	
	// Get client's ID and name
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	Name playerName; playerName.Init(client);

	//If they are DG'n put a sprite above their heads
	if (playerName.IsPlaying()) {
		Event_CreateSprite(client);
	}
}

public void Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast) {
	// Give the player their drinks
	DG_Drinks_GivePlayerDeathDrinks(event, name);

	// Return if building destroyed
	if(StrEqual(name,"object_destroyed",false)) { return; }
	
	// Kill the player's sprite
	int victim_id = GetEventInt(event, "userid")
	int victim = GetClientOfUserId(victim_id);
	DG_Effects_KillSprite(victim);
}

public void Event_SentryDeath(Handle event, const char[] name, bool dontBroadcast) {
	Event_PlayerDeath(event,name,dontBroadcast);
}

public void Event_RoundStart(Handle event, const char[] name, bool dontBroadcast) {
	if (DG_Balance_Timer != INVALID_HANDLE) {
		CloseHandle(DG_Balance_Timer);
		DG_Balance_Timer = INVALID_HANDLE;
	}
	DG_Balance_Timer = CreateTimer(5.0,DG_Balance_CallBalance);
}

public void Event_RoundWin(Handle event, const char[] name, bool dontBroadcast) {
	int team = GetEventInt(event,"team")

	// See if there are any drinkers that round
	bool drinkers = false;
	for (int client = 1; client <= MaxClients; client++) {
		if (TotalDrinks[client] > 0) {
			drinkers = true;
		}
	}

	//Loop through all clients
	for (int client = 1; client <= MaxClients; client++) {
		//Make sure client is connected
		if (!IsClientInGame(client)) { continue; }

		//Get player Name
		Name playerName; playerName.Init(client);
		// Skip player if not DG player
		if (playerName.IsPlaying()) { continue; }
		
		// Display drink messages to DG players
		DG_Msg_NoDrinkers(client, drinkers);
		DG_Msg_LosingTeam(client, team);
		// Display special drink categories
		DG_Drinks_EndDRDrinks(client);
		DG_Drinks_EndBuildingDrinks(client);
	}
	
	// Display top 5 drinkers
	DG_Msg_TopDrinkers(drinkers);

	// Reset drink totals
	for (int client = 1; client <= MaxClients; client++) {
		TotalDrinks[client] = 0;
		GivenDrinks[client] = 0;
	}
}

