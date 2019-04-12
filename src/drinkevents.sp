enum struct DGPlayer {
	int id;
	int client;
	float pos[3];
	char name[50];
	bool dg;
	
	void Init(Handle event, const char[] key) {
		this.id = GetEventInt(event, key);
		this.client = GetClientOfUserId(this.id);
		float pos[3];
		GetEntPropVector(this.client, Prop_Data, "m_vecOrigin", pos);
		for(int i=0;i<3;i++) this.pos[i] = pos[i];
		GetClientName(this.client, this.name, 50);
		this.dg = DG_IsPlayerPlaying(this.name);
	}
}

stock float DG_DistanceTo(DGPlayer playerA, DGPlayer playerB) {
	float posA[3]; for(int i=0;i<3;i++) posA[i] = playerA.pos[i];
	float posB[3]; for(int i=0;i<3;i++) posB[i] = playerB.pos[i];
	return GetVectorDistance(posA, posB);
}

// Below is pending rewrite into new drink system
/*
enum struct DrinkEvent {
	int drinks;
	DGPlayer victim;
	DGPlayer attacker;
	DGPlayer assister;
	char reason;
	char chatMessage;
	char windowMessage;
}

stock void DG_DrinkEvent_Template(DrinkEvent event, DGPlayer victim, DGPlayer attacker, DGPlayer assister) {
	event.drinks = 0;
	event.victim = victim;
	event.attacker = attacker;
	event.assister = assister;
	event.reason = "";
	event.chatMessage = "";
	event.windowMessage = "";
}

stock void DG_DrinkEvent_Train(DrinkEvent event, DGPlayer victim, DGPlayer attacker) {
	event.drinks = 6;
	event.victim = victim;
	event.attacker = attacker;
	event.chatMessage = "%sDon't get disTRACKted, drink %d";
	event.windowMessage = "[+%d]You got run over by a train";
}

stock void DG_DrinkEvent_Attacker(DrinkEvent event, DGPlayer victim, DGPlayer attacker) {
	event.drinks = 1;
	event.victim = victim;
	event.attacker = attacker;
	event.reason = "killed by [DG]";
	event.windowMessage = "[+%d]You were killed by %s";
}

stock void DG_DrinkEvent_Assister(DrinkEvent event, DGPlayer victim, DGPlayer assister, bool attackerDG) {
	event.drinks = 1;
	event.victim = victim;
	event.attacker = attacker;
	event.reason = attackerDG ? ", kill assisted by [DG]" : "kill assisted by [DG]";
	event.windowMessage = "[+%d]You were kill-assisted by %s";
}

stock void DG_DrinkEvent_Synergy(DrinkEvent event, DGPlayer victim, DGPlayer attacker, DGPlayer assister) {
	event.drinks = 1;
	event.victim = victim;
	event.attacker = attacker;
	event.assister = assister;
	event.windowMessage = "[+%d] Drinker synergy bonus drink";
}
*/