stock int TF2_GetHealingTarget(int client) {
	char classname[64];
	TF2_GetCurrentWeaponClass(client, classname, sizeof(classname));

	if(StrEqual(classname, "CWeaponMedigun"))	{
		int index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(GetEntProp(index, Prop_Send, "m_bHealing") == 1) {
			return GetEntPropEnt(index, Prop_Send, "m_hHealingTarget");
		}
	}

	return -1;
}

stock void TF2_GetCurrentWeaponClass(int client, char[] name, int maxlength) {
	if(client > 0) {
		int index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (index > 0)
			GetEntityNetClass(index, name, maxlength);
	}
}

stock int TF2_GetCurrentWeapon(int client) {
	if(client > 0) {
		int weaponIndex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		return weaponIndex;
	}

	return -1;
}

stock void TF2_GetWeaponClass(int index, char[] name, int maxlength) {
	if (index > 0)
		GetEntityNetClass(index, name, maxlength);
}

stock int TF2_GetPlayerUberLevel(int client) {
	int index = GetPlayerWeaponSlot(client, 1);

	if (index > 0) {
		char classname[64];
		TF2_GetWeaponClass(index, classname, sizeof(classname));

		if(StrEqual(classname, "CWeaponMedigun")) {
			return RoundFloat(GetEntPropFloat(index, Prop_Send, "m_flChargeLevel")*100);
		}
	}

	return 0;
}