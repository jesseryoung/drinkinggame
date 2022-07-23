#include <json>
#include <sdkhooks>
#include <sourcemod>
#include "globals.sp"
#include "commands.sp"

public Plugin myinfo =
{
	name        = "Drinking Game",
	author      = "Jesse Young (Codemonkey)",
	description = "Drinking Game for Source Games",
	version     = "1.0",
	url         = "https://github.com/jesseryoung/drinkinggame"
};

public void OnPluginStart()
{
	HookEvent("player_death", Handle_Event);
	HookEvent("teamplay_round_start", Handle_Event);
	HookEvent("teamplay_round_win", Handle_Event);
	HookEvent("object_destroyed", Handle_Event);
	RegisterCommands();
}

public void OnMapStart()
{
	PrecacheSound(g_drink_sound);
}

public void Handle_Event(Event event, const char[] name, bool dontBroadcast)
{
	JSON_Object obj = new JSON_Object();
	if (StrEqual(name, "player_death"))
	{
		OnPlayerDeath(event, obj);
	}
	if (StrEqual(name, "object_destroyed"))
	{
		OnPlayerDeath(event, obj);
	}
	if (StrEqual(name, "teamplay_round_win"))
	{
		OnRoundWin(event, obj);
	}

	obj.SetString("event_name", name);
	char output[1024 * 10];
	obj.Encode(output, sizeof(output));
	json_cleanup_and_delete(obj);
	PrintToServer("drinkinggame_output: %s", output);
}

public void OnPlayerDeath(Event event, JSON_Object obj)
{
	char users[][] = { "userid", "attacker", "assister" };
	LogClientIds(event, obj, users, sizeof(users));
	LogNames(event, obj, users, sizeof(users));
	LogSteamIds(event, obj, users, sizeof(users));

	char extra_ints[][] = { "damagebits", "death_flags" };
	LogEventInts(event, obj, extra_ints, sizeof(extra_ints));

	char extra_strings[][] = { "weapon", "weapon_logclassname" };
	LogEventStrings(event, obj, extra_strings, sizeof(extra_strings));
}

public void OnRoundWin(Event event, JSON_Object obj)
{
	char extra_ints[][] = { "team", "winreason" };
	LogEventInts(event, obj, extra_ints, sizeof(extra_ints));
}

public void LogEventInts(Event event, JSON_Object obj, const char[][] keys, int total_keys)
{
	for (int i = 0; i < total_keys; i++)
	{
		obj.SetInt(keys[i], event.GetInt(keys[i]));
	}
}

public void LogEventStrings(Event event, JSON_Object obj, const char[][] keys, int total_keys)
{
	for (int i = 0; i < total_keys; i++)
	{
		char value[128];
		event.GetString(keys[i], value, sizeof(value));
		obj.SetString(keys[i], value);
	}
}

public void LogClientIds(Event event, JSON_Object obj, const char[][] keys, int total_keys)
{
	char suffix[] = "_client_id";
	for (int i = 0; i < total_keys; i++)
	{
		int user_id   = event.GetInt(keys[i]);
		int client_id = GetClientOfUserId(user_id);

		// Really, I can't just concat 2 dynamic strings. WTF is the point of a compiler?
		int size        = strlen(keys[i]) + sizeof(suffix) + 1;
		char[] key_name = new char[size];

		Format(key_name, size, "%s%s", keys[i], suffix);
		if (client_id == 0)
		{
			obj.SetObject(key_name, null);
		}
		else {
			obj.SetInt(key_name, client_id);
		}
	}
}

public void LogNames(Event event, JSON_Object obj, const char[][] keys, int total_keys)
{
	char suffix[] = "_name";

	for (int i = 0; i < total_keys; i++)
	{
		int user_id   = event.GetInt(keys[i]);
		int client_id = GetClientOfUserId(user_id);

		int size        = strlen(keys[i]) + sizeof(suffix) + 1;
		char[] key_name = new char[size];
		Format(key_name, size, "%s%s", keys[i], suffix);
		if (client_id == 0)
		{
			obj.SetObject(key_name, null);
		}
		else {
			char client_name[MAX_NAME_LENGTH];
			GetClientName(client_id, client_name, sizeof(client_name));
			obj.SetString(key_name, client_name);
		}
	}
}

public void LogSteamIds(Event event, JSON_Object obj, const char[][] keys, int total_keys)
{
	char suffix[] = "_steam_id";

	for (int i = 0; i < total_keys; i++)
	{
		int user_id   = event.GetInt(keys[i]);
		int client_id = GetClientOfUserId(user_id);

		int size        = strlen(keys[i]) + sizeof(suffix) + 1;
		char[] key_name = new char[size];
		Format(key_name, size, "%s%s", keys[i], suffix);
		if (client_id == 0)
		{
			obj.SetObject(key_name, null);
		}
		else {
			char steam_64_id[MAX_AUTHID_LENGTH];
			GetClientAuthId(client_id, AuthId_SteamID64, steam_64_id, sizeof(steam_64_id));
			obj.SetString(key_name, steam_64_id);
		}
	}
}