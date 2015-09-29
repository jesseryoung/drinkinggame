new bool:canChugRound = true;

public Action:DGChugRound(client1, args) {
	if (!canChugRound) {
		//PrintToChat(client1, "There has been a chug round too recently to chug again");
		return Plugin_Handled;
	}
	canChugRound = false;
	for(new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) {
			continue;
		}
		new String:playerName[64];
		GetClientName(i, playerName,sizeof(playerName));
		if (mayDrink(playerName) || willDrink(playerName)) {
			EmitSoundToClient(i,"vo/burp05.mp3");
			PrintCenterText(i,"CHUG ROUND!!! CHEERS");
			if (IsPlayerAlive(i)) {
			 	new Float:vel[3];
				new Float:ang[3];
				GetClientEyeAngles(i, ang);
				GetAngleVectors(ang, vel, NULL_VECTOR, NULL_VECTOR);
				ScaleVector(vel, 300.0);
				SpawnBottleAtClient(i, vel);
			}
		}
	}
	CreateTimer(6.0, ResetChugRound);
	return Plugin_Handled;
}

public Action ResetChugRound(Handle:timer) {
	canChugRound = true;
}
