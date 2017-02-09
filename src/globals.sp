
#define RED_TEAM 2
#define BLU_TEAM 3

//in tf2_stocks
#define TF2_PLAYERCOND_DISGUISING           (1<<2)
#define TF2_PLAYERCOND_DISGUISED            (1<<3)
#define TF2_PLAYERCOND_SPYCLOAK             (1<<4)


#define DG_SPRITE_RED_VTF   "materials/dg/DG_red.vtf"
#define DG_SPRITE_RED_VMT   "materials/dg/DG_red.vmt"
#define DG_SPRITE_BLU_VTF   "materials/dg/DG_blu.vtf"
#define DG_SPRITE_BLU_VMT   "materials/dg/DG_blu.vmt"
new DrinkListStart[MAXPLAYERS + 1];
new Handle:Weapons = INVALID_HANDLE;
new Handle:DG_Balance_Timer = INVALID_HANDLE;

enum Eweapon
{
	wepMult,
	String:wepName[40],
};

new String: msgColor[] = "\x04[DG]";


new dgSprites[MAXPLAYERS + 1];
new dgSpritesParents[MAXPLAYERS + 1];

// REMOVE DG Stats URL Handle
// new Handle:dgStatsURL;
new Handle:dgRulesURL;
new Handle:dgBottleDeath;
new Handle:dgUnfairBalance;
new Handle:dgHolidayMode;
new Handle:dgDebug;

new gVelocityOffset;

public DG_Globals_Initialize() {
	gVelocityOffset = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");	
}
