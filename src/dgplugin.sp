#pragma newdecls required

#include <sourcemod>
#include <string>
#include <sdktools>
#include <tf2>
#include <sdkhooks>
#include <tf2_stocks>
#include <adt_trie>

#include "globals.sp"

#include "helpers.sp"
#include "effects.sp"
#include "balance.sp"
#include "chug.sp"
#include "tf2_extra.sp"
#include "hooks.sp"
#include "commands.sp"
#include "message.sp"
#include "drinkevents.sp"
#include "drinks.sp"

public Plugin myinfo = {
	name = "Drinking Game",
	author = "The BRH Community",
	description = "Sends players with [DG] in their name a message when they should drink",
	version = "4.0.0",
	url = "http://www.team-brh.com"
}

public int MenuHandler1(Handle menu, MenuAction action, int param1, int param2) {

}

//is player DG for the purposes of causing drinks
public bool DG_IsPlayerPlaying(char[] playerName) {
	if(StrContains(playerName,"[DG]",false) != -1) {
		return true;
	}
	if(StrContains(playerName,"[SG]",false) != -1) {
		return true;
	}
	if(StrContains(playerName,"[DCG]",false) != -1) {
		return true;
	}
	if(StrContains(playerName,"[SCG]",false) != -1) {
		return true;
	}
	return false;
}

public Action DG_ReadList(int client, int start) {
	int[] clients = new int[MaxClients];
	for (int s = 0; s < MaxClients; s++){
		clients[s] = s+1;
	}

	SortCustom1D(clients,MaxClients,DG_SortByTotalDrinkCount)

	char name[64]
	char[][] rtn = new char[MaxClients][1000];
	int numDgers = 0;
	for (int i = 0; i < MaxClients; i++) {
		if (!IsClientConnected(clients[i]) && !IsClientInGame(clients[i])) {
			continue;
		}

		GetClientName(clients[i],name,sizeof(name));

		//Only count people with drinks
		if (TotalDrinks[clients[i]] > 0) {
			numDgers++;
			char strLine[510];

			Format(strLine,sizeof(strLine),"%s drank %d\n",name,TotalDrinks[clients[i]]);

			strcopy(rtn[numDgers - 1][0],1000,strLine);
		}
	}

	if (start < 0) {
		start = 0;
	}
	int stop = start + 5;
	if (stop > numDgers)
		stop = numDgers;

	Handle panel = CreatePanel();
	SetPanelTitle(panel, "Drinks this map");
	for (int i = start; i < stop; i++) {
		char value[1000]; Format(value, sizeof(value), "%d - %s", i+1, rtn[i]);
		DrawPanelText(panel, value);
	}

	if (start + 5 < numDgers) {
		DrawPanelItem(panel, "Next");
	}
	if (start > 0) {
		DrawPanelItem(panel, "Prev");
	}
	DrawPanelItem(panel, "Close");
	DrinkListStart[client] = start;
	SendPanelToClient(panel,client, DrinkListHandler, 20);
	CloseHandle(panel);
	return Plugin_Handled;
}

public Action SetTransmit(int entity, int client) {
	//ATTN: THIS FUNCTION MAY HOLD THE BUG THAT CAUSES DG SPRITE AT SOME TEAMMATES
	//Do not display if it is the clients own sprite
	if (dgSprites[client] == entity) {
		return Plugin_Handled;
	}

	//Find target entities owner
	int playerLookingAt = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if (dgSprites[i] == entity) {
			playerLookingAt = i;
			break;
		}
	}

	//If its a spy disguising or disguised or cloaked don't show it
	if (playerLookingAt > 0) {
		if (GetEntProp(playerLookingAt, Prop_Send, "m_nPlayerCond") & (TF2_PLAYERCOND_DISGUISING|TF2_PLAYERCOND_DISGUISED|TF2_PLAYERCOND_SPYCLOAK))
			return Plugin_Handled;
	}

	//If they are on the same team. Don't show it
	if (playerLookingAt > 0) {
		if (GetClientTeam(client) == GetClientTeam(playerLookingAt)) {
			return Plugin_Handled;
		}
	}

	char playerName[32];
	GetClientName(client, playerName,sizeof(playerName));

	//Don't display to non DGers
	if (!DG_IsPlayerPlaying(playerName)) {
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

//// On

public void OnClientDisconnect(int client) {
	TotalDrinks[client] = 0;
	GivenDrinks[client] = 0;
	DG_Effects_KillSprite(client);
}

public void OnPluginStart() {
	DG_Globals_Init();	// globals.sp
	HookEvents_Init();	// hooks.sp
	ConsoleCmds_Init();	// commands.sp
	
	dgRulesURL = CreateConVar("dg_rulesurl", "http://www.team-brh.com/forums/viewtopic.php?f=8&t=7666", "Web location where rules are posted for when a player types dg_info in chat");
	dgBottleDeath = CreateConVar("dg_bottledeath", "1", "Spawn bottles based on how many drinks were given on death");
	dgUnfairBalance = CreateConVar("dg_unfairbalance", "1", "Prevent certain heavy medic pairs from being dg-balanced separated");
	dgHolidayMode = CreateConVar("dg_holidaymode", "0", "Drink irresponsibly this holiday season.");
	dgDebug = CreateConVar("dg_debug", "0", "Drinking Game Debug Mode");
	//For findtarget
	LoadTranslations("common.phrases");

	//Turn on holiday mode if month is december
	char date[30];
	FormatTime(date, sizeof(date), "%b");
	SetConVarBool(dgHolidayMode, StrEqual(date, "Dec"));
}

public void OnPluginEnd() {
	//Kill all sprites on end
	DG_Effects_KillAllSprites();
}

public void OnConfigsExecuted() {
	if (GetConVarBool(dgDebug)) {
		return;
	}
	PrecacheSound("vo/burp05.mp3");
	PrecacheModel("models/props_gameplay/bottle001.mdl",true);
}

public void OnGameFrame() {
	int ent; float vOrigin[3]; float vVelocity[3];

	for(int i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i)) { continue; }
		
		if ((ent = dgSpritesParents[i]) > 0) {
			if (!IsValidEntity(ent)) {
				dgSpritesParents[i] = 0;
			}
			else if((ent = EntRefToEntIndex(ent)) > 0) {
				GetClientEyePosition(i, vOrigin);
				vOrigin[2] += 25.0;
				GetEntDataVector(i, gVelocityOffset, vVelocity);
				TeleportEntity(ent, vOrigin, NULL_VECTOR,vVelocity);
			}
		}
	}
}


public void OnMapStart() {
	if (GetConVarBool(dgDebug)) {
		return;
	}
	PrecacheGeneric(DG_SPRITE_RED_VMT, true);
	AddFileToDownloadsTable(DG_SPRITE_RED_VMT);
	PrecacheGeneric(DG_SPRITE_RED_VTF, true);
	AddFileToDownloadsTable(DG_SPRITE_RED_VTF);

	PrecacheGeneric(DG_SPRITE_BLU_VMT, true);
	AddFileToDownloadsTable(DG_SPRITE_BLU_VMT);
	PrecacheGeneric(DG_SPRITE_BLU_VTF, true);
	AddFileToDownloadsTable(DG_SPRITE_BLU_VTF);
}