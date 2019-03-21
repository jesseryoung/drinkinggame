new Handle:db = INVALID_HANDLE;

public DG_Database_Connect() {
	if (GetConVarBool(dgDebug)) {
		return; 
	}
	new String:error[255]
	db = SQLite_UseDatabase("drinkinggame", error, sizeof(error))

	if (db == INVALID_HANDLE) {
		PrintToServer("Could not connect: %s", error);
		return;
	}
	else {
		PrintToServer("DG: Connected to SQL server");
	}
}


public DG_Database_LoadWeaponInfo() {
	if (GetConVarBool(dgDebug)) {
		return;
	}
	if (Weapons != INVALID_HANDLE)
		CloseHandle(Weapons);

	SQL_LockDatabase(db);
	new Handle:query = SQL_Query(db, "SELECT weapon,mult FROM dgwepmults");
	SQL_UnlockDatabase(db);
	Weapons = CreateTrie();


	while (SQL_FetchRow(query))
	{
		new _:weaponinfo[Eweapon];

		SQL_FetchString(query, 0, weaponinfo[wepName], sizeof(weaponinfo[wepName]));
		weaponinfo[wepMult] = SQL_FetchInt(query,1);
		SetTrieValue(Weapons,weaponinfo[wepName],weaponinfo[0]);
	}
}

public T_SQLThreadReturn(Handle:owner, Handle:hndl, const String:error[], any:data) {
	if (hndl == INVALID_HANDLE)
	{
		LogError(error)
	}
}

public DG_Database_AddDrinks(attacker, assister, victim, at_drinks, as_drinks, vic_drinks, String: weapon[]) {
	//Return if the db is closed
	if (db == INVALID_HANDLE || GetConVarBool(dgDebug)) {
		return;
	}

	new String:atName[100] = "NULL";
	new String:atSteam[50] = "NULL";
	new String:asName[100] = "NULL";
	new String:asSteam[50] = "NULL";
	new String:vicName[100] = "NULL";
	new String:vicSteam[50] = "NULL";

	/*
	0 IN attack_name VARCHAR(50),
	1 IN attack_steam_id VARCHAR(50),
	2 IN assist_name VARCHAR(50),
	3 IN assist_steam_id VARCHAR(50),
	4 IN victim_name VARCHAR(50),
	5 IN victim_steam_id VARCHAR(50),
	6 IN weapon VARCHAR(45),
	7 IN attack_drinks INT(11),
	8 IN assist_drinks INT(11),
	9 IN victim_drinks INT(11)
	*/

	if (attacker != 0) {
		GetClientAuthId(attacker,AuthId_Steam2,atSteam,sizeof(atSteam));
		Format(atSteam, sizeof(atSteam),"'%s'",atSteam);
	}
	if (assister != 0) {
		GetClientAuthId(assister,AuthId_Steam2,asSteam,sizeof(asSteam));
		Format(asSteam, sizeof(asSteam),"'%s'",asSteam);
	}

	GetClientAuthId(victim,AuthId_Steam2,vicSteam,sizeof(vicSteam));
	Format(vicSteam, sizeof(vicSteam),"'%s'",vicSteam);

	new String:query[1000];
	SQL_LockDatabase(db);
	SQL_FastQuery(db,"SET NAMES UTF8");
	SQL_UnlockDatabase(db);
	Format(query,sizeof(query),"call add_drinks(%s, %s, %s, %s, %s, %s, '%s', %d, %d, %d);", atName, atSteam, asName, asSteam, vicName, vicSteam, weapon, at_drinks, as_drinks, vic_drinks)

	SQL_TQuery(db, T_SQLThreadReturn, query)
}
