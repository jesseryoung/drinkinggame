
stock getTeamName(id, String:buffer[], maxlength) {
	if (maxlength < 4) {
		return;
	}
	new String:red[4] = "RED";
	new String:blu[4] = "BLU";
	if (id == RED_TEAM) {
		strcopy(buffer, maxlength, red);
	}
	else if (id == BLU_TEAM) {
		strcopy(buffer, maxlength, blu);
	}
}

public StringToUpper(String:str[]) {
	new i = 0;
	while (str[i] != '\0') {
		str[i] = CharToUpper(str[i]);
		i++;
	}
}