stock void getTeamName(int id, char[] buffer, int maxlength) {
	if (maxlength < 4) {
		return;
	}
	char red[4] = "RED";
	char blu[4] = "BLU";
	if (id == RED_TEAM) {
		strcopy(buffer, maxlength, red);
	}
	else if (id == BLU_TEAM) {
		strcopy(buffer, maxlength, blu);
	}
}

public void StringToUpper(char[] str) {
	int i = 0;
	while (str[i] != '\0') {
		str[i] = CharToUpper(str[i]);
		i++;
	}
}