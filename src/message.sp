enum struct DrinkWindow {
	int drinks;
	int client;
	Handle panel;
	char panelBuffer[100];
	
	void Init(int toClient) {
		this.drinks = 0;
		this.client = toClient;
		this.panel = CreatePanel();
		PrintToServer("Drink window created");
	}
	
	void AddTextMessage(char[] message) {
		Format(this.panelBuffer,100,message);
		DrawPanelText(this.panel, this.panelBuffer);
	}
	
	void AddFormatTextMessage(char[] message, int args, any ...) {
		strcopy(this.panelBuffer,100,message);	// Store base string in buffer
		for(int i=0; i < args; i++) {
			// Add each vararg into buffer string
	 		VFormat(this.panelBuffer,100,this.panelBuffer,i);
	 	}
		DrawPanelText(this.panel, this.panelBuffer);
	}
	
	void AddDrinkMessage(int addDrinks, char[] message) {
		PrintToServer("Adding drink message");
		this.drinks += addDrinks;
		Format(this.panelBuffer,100,message,addDrinks);
		DrawPanelText(this.panel, this.panelBuffer);
	}
	
	void AddFormatDrinkMessage(int addDrinks, char[] message, char[] formatValue) {
		PrintToServer("Adding formatted drink message");
		this.drinks += addDrinks;
		Format(this.panelBuffer,100,message,addDrinks,formatValue);	// Format drink count into string first
		DrawPanelText(this.panel, this.panelBuffer);
	}
	
	void Display() {
		PrintToServer("Displaying drink window");
		DrawPanelText(this.panel,"--------------------------------");
		Format(this.panelBuffer,100,"Total: %d",this.drinks);
		DrawPanelText(this.panel, this.panelBuffer);
		DrawPanelText(this.panel," ");
		Format(this.panelBuffer,100,"Total drinks this round: %d",TotalDrinks[this.client]);
		DrawPanelText(this.panel,this.panelBuffer);
		DrawPanelItem(this.panel,"Close");
		SendPanelToClient(this.panel, this.client, MenuHandler1, 5);
		CloseHandle(this.panel);
	}
}

//// Drink X Messages

public void DG_Msg_Drink(int client, int drinks) {
	PrintCenterText(client,"DRINK %d BITCH", drinks);
}

public void DG_Msg_DeathDrink(int client, char[] reason, int drinks) {
	DG_Msg_Drink(client, drinks);
	PrintToChat(client,"%sYou were %s drink %d",msgColor, reason, drinks);
}

public void DG_Msg_DRDrink(int client, int drinks) {
	DG_Msg_Drink(client, drinks);
	PrintToChat(client,"%sYou were dead ringing you cheeky git %d",msgColor, drinks);
}

public void DG_Msg_BuildingDrink(int client, int drinks) {
	DG_Msg_Drink(client, drinks);
	PrintToChat(client,"%sYour buildings were killed last life drink %d",msgColor, drinks);
}

public void DG_Msg_TrainDrink(int client, int drinks) {
	DG_Msg_Drink(client, drinks);
	PrintToChat(client,"%sDon't get disTRACKted, drink %d",msgColor, drinks);
}

//// Global/Team Messages

public void DG_Msg_NoDrinkers(int client, bool drinkers) {
	if(!drinkers) {
		PrintToChat(client, "%sNo one even drank that round, get killing you drunks",msgColor);
	}
}

public void DG_Msg_LosingTeam(int client, int team) {
	if (GetClientTeam(client) != team) {
		PrintCenterText(client,"Your team lost! Drink bitch");
	}
}

public void DG_GetTopDrinkersString(char[] buffer, int size, int listmax) {
	int[] clients = new int[MaxClients];

	for (int start = 0; start < MaxClients; start++){
		clients[start] = start+1;
	}

	SortCustom1D(clients,MaxClients,DG_SortByTotalDrinkCount)

	char name[64]
	//rtn is only going to be as big as the number of players
	char rtn[(MAXPLAYERS + 1)*(sizeof(name)+4)]
	int printed = 0;
	for (int i = 0; i < MaxClients; i++) {
		if (printed >= listmax) {
			continue;
		}

		if (!IsClientInGame(clients[i])) {
			continue;
		}

		GetClientName(clients[i],name,sizeof(name))

		//Only count people with drinks
		if (TotalDrinks[clients[i]] > 0) {
			printed++;
			char strLine[510];
			Format(strLine,sizeof(strLine),"%s drank %d\n",name,TotalDrinks[clients[i]]);
			StrCat(rtn,sizeof(rtn),strLine);
		}
	}

	strcopy(buffer,size,rtn);
}

public void DG_Msg_TopDrinkers(bool drinkers) {
	// Bail if no drinkers
	if(!drinkers) { return; }
	
	char TopDrinkers[(MAXPLAYERS + 1)*(66)];
	DG_GetTopDrinkersString(TopDrinkers,sizeof(TopDrinkers),5);
	PrintToChatAll("%sTop 5 Drinkers:\n%s",msgColor, TopDrinkers);
}

