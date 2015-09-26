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
