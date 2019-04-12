public void ConsoleCmds_Init() {
	// Console Commands
	RegConsoleCmd("say",Command_Say);
	RegConsoleCmd("dg_drinklist",DG_DrinkListCommand);
	RegConsoleCmd("dg_info",DG_InfoCommand);
	
	// Admin Commands
	RegAdminCmd("dg_add_bot", DG_AddBotCommand, ADMFLAG_GENERIC);
	RegAdminCmd("dg_balance", DG_Balance_CallBalanceCommand, ADMFLAG_GENERIC);
	RegAdminCmd("dg_chuground", DG_Chug_ChugRoundCommand, ADMFLAG_GENERIC);
}

//// Console Commands

public Action Command_Say(int client, int args) {
	char text[200];
	GetCmdArgString(text,sizeof(text));
	StripQuotes(text);
	//Just leave if the console says something
	if (client == 0) {
		return Plugin_Continue;
	}

	char forumPost[300];
	GetConVarString(dgRulesURL,forumPost,sizeof(forumPost));

	if (StrContains(text, "dg",false) != -1 || StrContains(text, "dcg",false) != -1
		|| StrContains(text, "sg",false) != -1 || StrContains(text, "scg",false) != -1) {
		if (StrContains(text, "what is",false) != -1)
			ShowMOTDPanel(client,"DG Rules",forumPost,MOTDPANEL_TYPE_URL);
		else if (StrContains(text, "wat is",false) != -1)
			ShowMOTDPanel(client,"DG Rules",forumPost,MOTDPANEL_TYPE_URL);
		else if (StrContains(text, "wtf is",false) != -1)
			ShowMOTDPanel(client,"DG Rules",forumPost,MOTDPANEL_TYPE_URL);
		else if (StrContains(text, "why do you have",false) != -1)
			ShowMOTDPanel(client,"DG Rules",forumPost,MOTDPANEL_TYPE_URL);
		else if (StrContains(text, "how to",false) != -1)
			ShowMOTDPanel(client,"DG Rules",forumPost,MOTDPANEL_TYPE_URL);
		else if (StrContains(text, "how do",false) != -1)
			ShowMOTDPanel(client,"DG Rules",forumPost,MOTDPANEL_TYPE_URL);
	}

	//If they're trying to run a dg command, run it as a client command as if they entered it in console
	if (StrContains(text, "dg_", false) != -1) {
		ClientCommand(client, text);
	}

	return Plugin_Continue;
}

public Action DG_DrinkListCommand(int client, int args) {
	DG_ReadList(client,0);
	return Plugin_Handled;
}

public Action DG_InfoCommand(int client, int args) {
	char forumPost[300];
	GetConVarString(dgRulesURL,forumPost,sizeof(forumPost));
	ShowMOTDPanel(client,"DG Rules",forumPost,MOTDPANEL_TYPE_URL);
	return Plugin_Handled;
}

//// Admin Commands

public Action DG_AddBotCommand(int client, int args) {
	char command[50];
	if (GetRandomFloat() < 0.6) {
		Format(command, sizeof(command), "tf_bot_add \"[DG] Drinker\"");
	}
	else {
		Format(command, sizeof(command), "tf_bot_add \"Non Drinker\"");
	}
	ServerCommand(command);
}

public Action DG_Chug_ChugRoundCommand(int client, int args) {
	return DG_Chug_ChugRound(client, args);
}
