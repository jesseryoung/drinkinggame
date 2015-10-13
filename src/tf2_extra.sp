stock TF2_GetHealingTarget(client) {
	new String:classname[64];
	TF2_GetCurrentWeaponClass(client, classname, sizeof(classname));

	if(StrEqual(classname, "CWeaponMedigun"))	{
		new index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(GetEntProp(index, Prop_Send, "m_bHealing") == 1) {
			return GetEntPropEnt(index, Prop_Send, "m_hHealingTarget");
		}
	}

	return -1;
}

stock TF2_GetCurrentWeaponClass(client, String:name[], maxlength) {
	if(client > 0) {
		new index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (index > 0)
			GetEntityNetClass(index, name, maxlength);
	}
}

stock TF2_GetCurrentWeapon(client) {
	if(client > 0) {
		new weaponIndex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		return weaponIndex;
	}

	return -1;
}

stock TF2_GetWeaponClass(index, String:name[], maxlength) {
	if (index > 0)
		GetEntityNetClass(index, name, maxlength);
}

stock TF2_GetPlayerUberLevel(client) {
	new index = GetPlayerWeaponSlot(client, 1);

	if (index > 0) {
		new String:classname[64];
		TF2_GetWeaponClass(index, classname, sizeof(classname));

		if(StrEqual(classname, "CWeaponMedigun")) {
			return RoundFloat(GetEntPropFloat(index, Prop_Send, "m_flChargeLevel")*100);
		}
	}

	return 0;
}