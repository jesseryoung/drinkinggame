#include <sdktools>

public void RegisterCommands()
{
	RegServerCmd("player_drinks", Command_Drink);
}

public Action Command_Drink(int args)
{
	if (args != 3)
	{
		// Exit without required number of args
		return Plugin_Continue;
	}

	int client_id = GetCmdArgInt(1);

	if (client_id == 0 || IsClientConnected(client_id) == false)
	{
		// Exit if client isn't even in the game
		return Plugin_Continue;
	}

	char steam_id[MAX_AUTHID_LENGTH];
	GetCmdArg(2, steam_id, sizeof(steam_id));

	char client_steam_id[MAX_AUTHID_LENGTH];
	GetClientAuthId(client_id, AuthId_SteamID64, client_steam_id, sizeof(client_steam_id));

	if (strcmp(steam_id, client_steam_id) != 0)
	{
		// Steam id didn't match, probably not the same person
		return Plugin_Continue;
	}

	char message[1024];
	GetCmdArg(3, message, sizeof(message));

	EmitSoundToClient(client_id, g_drink_sound);

	Panel panel = new Panel();
	panel.SetTitle("Drink Bitch");
	panel.DrawText(message);
	panel.Send(client_id, PanelHandler, 10);
	delete panel;

	return Plugin_Continue;
}

public int PanelHandler(Menu menu, MenuAction action, int param1, int param2)
{
	return 0;
}