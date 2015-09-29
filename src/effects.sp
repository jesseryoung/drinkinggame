
stock CreateDeathEffect(ent, val) {
	if (GetConVarBool(dgBottleDeath)) {
		new Handle:datapack;
		CreateDataTimer(0.1, SpawnDeathEffect, datapack);
		WritePackCell(datapack, ent);
		WritePackCell(datapack, val);
	}
}

public Action:SpawnDeathEffect(Handle:timer, Handle:data) {
	ResetPack(data);
	new client = ReadPackCell(data);
	new amount = ReadPackCell(data);
	if (amount < 0) amount = 0;
	for (new i = 0; i < amount; i++) {
		//Create the random angle/velocities of each bottle, based on adding to players velocity
		new Float:vel[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vel)
		ScaleVector(vel, 1.8);
		vel[0] += GetRandomFloat(-150.0, 150.0);
		vel[1] += GetRandomFloat(-150.0, 150.0);
		vel[2] += GetRandomFloat(-30.0, 90.0);
		SpawnBottleAtClient(client, vel);
	}
}

stock SpawnBottleAtClient(client, Float:avel[3]) {
	new ent = CreateEntityByName("prop_physics_override");
	//Create the random angle/velocities of each bottle, based on adding to players velocity
	new Float:cvel[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", cvel)

	new Float:vel[3];
	AddVectors(cvel, avel, vel);

	new Float:pos[3];
	//GetEntPropVector(client, Prop_Data, "m_vecOrigin", pos)
	GetClientEyePosition(client, pos);

	new Float:ang[3];
	ang[0] = GetRandomFloat(0.0, 359.0);
	ang[1] = GetRandomFloat(0.0, 359.0);
	ang[2] = GetRandomFloat(0.0, 359.0);

	DispatchKeyValue(ent,"damagetoenablemotion","0");
	DispatchKeyValue(ent,"forcetoenablemotion","0");
	DispatchKeyValue(ent,"Damagetype","0");
	DispatchKeyValue(ent,"disablereceiveshadows","1");
	//DispatchKeyValue(ent,"massScale","0");
	DispatchKeyValue(ent,"nodamageforces","0");
	DispatchKeyValue(ent,"shadowcastdist","0");
	DispatchKeyValue(ent,"physdamagescale", "0.0");
	DispatchKeyValue(ent,"disableshadows","1");
	DispatchKeyValue(ent,"physicsmode","3");
	DispatchKeyValue(ent,"spawnflags","4");
	DispatchKeyValue(ent,"model","models/props_gameplay/bottle001.mdl");
	DispatchSpawn(ent);
	TeleportEntity(ent, pos, ang, vel);
	SetEntityMoveType(ent, MOVETYPE_VPHYSICS);
	CreateTimer(12.0, DestroyDeathEffect, ent);
}

public Action:DestroyDeathEffect(Handle:timer, any:ent) {
	if (IsValidEntity(ent)) {
		//Make sure this is the entity we're expecting
		new String:classname[256];
		GetEntityClassname(ent, classname, sizeof(classname));
		if (StrContains(classname, "prop_physics_override")) {
			AcceptEntityInput(ent, "kill");
		}
	}
}

stock CreateSprite(iClient, String:sprite[])
{
	//Clean up any existing sprites and their parents:
	if (g_EntList[iClient] > 0 || g_EntParentList[iClient] > 0) {
		KillSprite(iClient);
	}

	//new String:strClient[64];
	//Format(strClient, sizeof(strClient), "client%i", iClient);
	//DispatchKeyValue(iClient, "targetname", strClient);


	new String:strParent[64];
	Format(strParent, sizeof(strParent), "prop%i", iClient);
	new parent = CreateEntityByName("prop_dynamic");
	DispatchKeyValue(parent, "targetname", strParent);
	//DispatchKeyValue(parent, "parentname", strClient);

	//Special values given by couch do reduce strain on server

	DispatchKeyValue(parent,"renderfx","0");
	DispatchKeyValue(parent,"damagetoenablemotion","0");
	DispatchKeyValue(parent,"forcetoenablemotion","0");
	DispatchKeyValue(parent,"Damagetype","0");
	DispatchKeyValue(parent,"disablereceiveshadows","1");
	DispatchKeyValue(parent,"massScale","0");
	DispatchKeyValue(parent,"nodamageforces","0");
	DispatchKeyValue(parent,"shadowcastdist","0");
	DispatchKeyValue(parent,"disableshadows","1");
	DispatchKeyValue(parent,"spawnflags","1670");
	DispatchKeyValue(parent,"model","models/player/medic_animations.mdl");
	DispatchKeyValue(parent,"PerformanceMode","1");
	DispatchKeyValue(parent,"rendermode","10");
	DispatchKeyValue(parent,"physdamagescale","0");
	DispatchKeyValue(parent,"physicsmode","2");

	DispatchSpawn(parent);

	//SetVariantString(strClient);
	//AcceptEntityInput(parent, "SetParent",parent, parent, 0);

	g_EntParentList[iClient] = parent;

	new ent = CreateEntityByName("env_sprite_oriented");

	if (ent)
	{
		new String:StrEntityName[64]; Format(StrEntityName, sizeof(StrEntityName), "ent_sprite_oriented_%i", ent);
		DispatchKeyValue(ent, "model", sprite);

		DispatchKeyValue(ent, "classname", "env_sprite_oriented");
		DispatchKeyValue(ent, "spawnflags", "1");
		DispatchKeyValue(ent, "scale", "0.1");
		DispatchKeyValue(ent, "rendermode", "1");
		DispatchKeyValue(ent, "rendercolor", "255 255 255");
		DispatchKeyValue(ent, "targetname", StrEntityName);
		DispatchKeyValue(ent, "parentname", strParent);

		DispatchSpawn(ent);
		//TeleportEntity(ent, vOrigin, NULL_VECTOR, NULL_VECTOR);
		g_EntList[iClient] = ent;

		SetVariantString(strParent);
		AcceptEntityInput(ent, "SetParent");

		SDKHook(ent, SDKHook_SetTransmit, SetTransmit);
	}
}

stock KillSprite(iClient)
{
	if (g_EntList[iClient] > 0 && IsValidEntity(g_EntList[iClient]))
	{
		AcceptEntityInput(g_EntList[iClient], "kill");
		g_EntList[iClient] = 0;
	}

	if (g_EntParentList[iClient] > 0 && IsValidEntity(g_EntParentList[iClient]))
	{
		AcceptEntityInput(g_EntParentList[iClient], "kill");
		g_EntParentList[iClient] = 0;
	}
}
