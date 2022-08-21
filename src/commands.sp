#include <sdktools>

public void RegisterCommands()
{
	RegServerCmd("dg_tell_player", Command_Drink);
}

public Action Command_Drink(int args)
{
	char command[1024 * 10];
	GetCmdArgString(command, sizeof(command));
	JSON_Object obj = json_decode(command);

	int client_id = obj.GetInt("client_id");

	if (client_id == 0 || IsClientConnected(client_id) == false)
	{
		// Exit if client isn't even in the game
		return Plugin_Continue;
	}

	char steam_id[MAX_AUTHID_LENGTH];
	obj.GetString("steam_id", steam_id, sizeof(steam_id));

	char client_steam_id[MAX_AUTHID_LENGTH];
	GetClientAuthId(client_id, AuthId_SteamID64, client_steam_id, sizeof(client_steam_id));

	if (strcmp(steam_id, client_steam_id) != 0)
	{
		// Steam id didn't match, probably not the same person
		return Plugin_Continue;
	}

	if (obj.GetBool("play_drink_sound"))
	{
		EmitSoundToClient(client_id, g_drink_sound);
	}

	JSON_Array messages = view_as<JSON_Array>(obj.GetObject("messages"));

	if (obj.GetBool("show_in_panel"))
	{
		Panel panel = new Panel();
		panel.SetTitle("Drink Bitch");
		for (int i = 0; i < messages.Length; i++)
		{
			char message[1024];
			messages.GetString(i, message, sizeof(message));
			panel.DrawText(message);
		}

		panel.Send(client_id, PanelHandler, 5);
		delete panel;
	}
	else
	{
		for (int i = 0; i < messages.Length; i++)
		{
			char message[1024];
			messages.GetString(i, message, sizeof(message));
			PrintToChat(client_id, message);
		}
	}

	json_cleanup_and_delete(obj);

	return Plugin_Continue;
}

public int PanelHandler(Menu menu, MenuAction action, int param1, int param2)
{
	return 0;
}