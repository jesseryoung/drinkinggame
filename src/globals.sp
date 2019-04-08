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

char msgColor[] = "\x04[DG]";

int dgSprites[MAXPLAYERS + 1];
int dgSpritesParents[MAXPLAYERS + 1];

enum struct Eweapon {
	int wepMult;
	char wepName[40];
}

Handle Weapons = INVALID_HANDLE;
Handle DG_Balance_Timer = INVALID_HANDLE;
Handle dgRulesURL;
Handle dgBottleDeath;
Handle dgUnfairBalance;
Handle dgHolidayMode;
Handle dgDebug;

// Drink tallies
int DrinkListStart[MAXPLAYERS + 1];
int TotalDrinks[MAXPLAYERS + 1];
int BuildingDrinks[MAXPLAYERS + 1];
int DeadRingerDrinks[MAXPLAYERS + 1];
int MedicDrinks[MAXPLAYERS + 1];
int GivenDrinks[MAXPLAYERS + 1];

bool canChugRound = true;

int gVelocityOffset;

public void DG_Globals_Init() {
	gVelocityOffset= FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
}