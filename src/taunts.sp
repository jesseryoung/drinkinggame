new Handle:hUpdateTaunt = INVALID_HANDLE;
new Handle:hInsertTaunt = INVALID_HANDLE;

public bool:DG_Taunts_SetTaunt(String:steamID[], String:taunt[]) {
	if(GetConVarBool(dgDebug)) {
		return false;
	}
	//Change it to uppercase
	StringToUpper(taunt);

	//Return if the db is closed
	if (db == INVALID_HANDLE) {
		return false;
	}

	SQL_LockDatabase(db);
	if (hUpdateTaunt == INVALID_HANDLE) {
		new String:error[255];
		hUpdateTaunt = SQL_PrepareQuery(db, "UPDATE dgtaunts SET taunt = ? WHERE Steam_ID = ?", error, sizeof(error));
		if (hUpdateTaunt == INVALID_HANDLE){
			LogError(error);
		}
	}
	if (hInsertTaunt == INVALID_HANDLE) {
		new String:error[255];
		hInsertTaunt = SQL_PrepareQuery(db, "INSERT INTO dgtaunts (taunt, Steam_ID) VALUES(?, ?)", error, sizeof(error));
		if (hInsertTaunt == INVALID_HANDLE){
			LogError(error);
		}
	}

	//Create a query for the DB
	new String:strQuery[500];
	Format(strQuery,sizeof(strQuery), "SELECT taunt FROM dgtaunts WHERE Steam_ID = '%s'",steamID);
	new Handle:query = SQL_Query(db,strQuery);

	if (query == INVALID_HANDLE) {
		new String:error[100];
		SQL_GetError(db,error,sizeof(error));
		PrintToServer(error);
		SQL_UnlockDatabase(db);
		return false;
	} else if(SQL_FetchRow(query)) {
		//That means that a row exists, so use update
		SQL_BindParamString(hUpdateTaunt, 0, taunt, false);
		SQL_BindParamString(hUpdateTaunt, 1, steamID, false);
		if (!SQL_Execute(hUpdateTaunt)) {
			new String:error[100];
			SQL_GetError(db,error,sizeof(error));
			LogError(error);
			SQL_UnlockDatabase(db);
			return false;
		}
	} else {
		//Use insert
		SQL_BindParamString(hInsertTaunt, 0, taunt, false);
		SQL_BindParamString(hInsertTaunt, 1, steamID, false);
		if (!SQL_Execute(hInsertTaunt)) {
			new String:error[100];
			SQL_GetError(db, error,sizeof(error));
			LogError(error);
			SQL_UnlockDatabase(db);
			return false;
		}
	}

	SQL_UnlockDatabase(db);
	return true;
}


public Action:DG_Taunts_SetTauntCommand(int client, args) {
	//Tell client that the functionality is disabled. Remove these two lines when taunts are good to go again.
	PrintToChat(client,"%sDG Taunts have been temporarily disabled.",msgColor);
	return Plugin_Handled;


	new String:text[128];
	GetCmdArgString(text, sizeof(text));
	if (strlen(text) < 1) {
		PrintToChat(client,"%sYou must specify a taunt to set",msgColor)
	}
	else {
		new String:steamID[32];
		GetClientAuthId(client,AuthId_Steam2,steamID,sizeof(steamID))
		new String:taunt[50];
		if (DG_Taunts_SetTaunt(steamID,text)) {
			DG_Taunts_GetTaunt(steamID,taunt,sizeof(taunt),true);
			PrintToChat(client,"%staunt added: '%s'",msgColor,taunt)
		} else
		PrintToChat(client, "%sThere was an error adding this taunt (tell CodeMonkey)",msgColor);
	}
	return Plugin_Handled;
}


public DG_Taunts_GetTaunt(String:steamID[32], String:buf[], bufLen, bool:returnError) {
	//Taunts are temporarily disabled, so we will return nothing. Remove this line when taunts are good to go.
	return;


	if (StrContains(steamID, "BOT") != -1 ) {
		return;
	}
	new String:rtn[100] = "";

	//Return if the db is closed
	if (db == INVALID_HANDLE) {
		return;
	}

	//Create a query for the DB
	new String:strQuery[250];
	Format(strQuery,sizeof(strQuery), "SELECT taunt FROM dgtaunts WHERE Steam_ID = '%s'",steamID);
	SQL_LockDatabase(db);
	new Handle:query = SQL_Query(db,strQuery);
	SQL_UnlockDatabase(db);

	if (query == INVALID_HANDLE && returnError) {
		SQL_GetError(db,rtn,sizeof(rtn));
		PrintToServer(rtn);
	} else if(SQL_FetchRow(query)) {
		SQL_FetchString(query,0,rtn,sizeof(rtn));
	}
	strcopy(buf,bufLen,rtn);
}

public Action:DG_Taunts_MyTauntCommand(int client, args) {
	//Tell client that the functionality is disabled. Remove these two lines when taunts are good to go again.
	PrintToChat(client,"%sDG Taunts have been temporarily disabled.",msgColor);
	return Plugin_Handled;


	new String:steamID[32];
	GetClientAuthId(client,AuthId_Steam2,steamID,sizeof(steamID))
	new String:tag[100];
	DG_Taunts_GetTaunt(steamID,tag,sizeof(tag),true);
	PrintToChat(client,"%s%s",msgColor,tag);
	return Plugin_Handled;
}