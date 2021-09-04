#include <sourcemod>
#include <sdktools>
#include <zombiereloaded>

#pragma newdecls required
#pragma semicolon 1

enum struct zrClasses
{
	int index;
	int health;
	char model[128];
}
ArrayList array_classes;

ConVar hPlayerClasses;

public Plugin myinfo = 
{
	name = "ZR Class Fix", 
	author = "Franc1sco franug", 
	description = "Class Fix", 
	version = "3.3", 
	url = "http://steamcommunity.com/id/franug"
};

public void OnPluginStart()
{
	array_classes = new ArrayList(sizeof(zrClasses));
}

public void OnAllPluginsLoaded()
{
	if (!(hPlayerClasses = FindConVar("zr_config_path_playerclasses")))
	{
		SetFailState("Zombie:Reloaded is not running on this server");
	}
	
	hPlayerClasses.AddChangeHook(OnClassPathChange);
}

public void OnClassPathChange(Handle convar, const char[] oldValue, const char[] newValue)
{
	OnConfigsExecuted();
}

public void OnConfigsExecuted()
{
	CreateTimer(0.2, OnConfigsExecutedPost);
}

Action OnConfigsExecutedPost(Handle timer)
{
	KeyValues kv = new KeyValues("classes");
	
	char buffer[PLATFORM_MAX_PATH];
	hPlayerClasses.GetString(buffer, sizeof(buffer));
	BuildPath(Path_SM, buffer, sizeof(buffer), "%s", buffer);
	
	if (!kv.ImportFromFile(buffer))
	{
		SetFailState("Class data file \"%s\" not found", buffer);
	}
	
	if (kv.GotoFirstSubKey())
	{
		array_classes.Clear();
		
		char name[64], enable[32], defaultclass[32];
		zrClasses Items;
		
		do
		{
			kv.GetString("enabled", enable, sizeof(enable));
			kv.GetString("team_default", defaultclass, sizeof(defaultclass));
			
			// check if is a enabled zombie class and no admin class and it's default class
			if (StrEqual(enable, "yes") && StrEqual(defaultclass, "yes") && !kv.GetNum("team") && !kv.GetNum("flags"))
			{
				kv.GetString("name", name, sizeof(name));
				Items.index = ZR_GetClassByName(name);
				Items.health = kv.GetNum("health", 5000);
				kv.GetString("model_path", Items.model, sizeof(zrClasses::model));
				
				array_classes.PushArray(Items);
			}
			
		} while (kv.GotoNextKey());
	}
	
	delete kv;
}

public int ZR_OnClientInfected(int client, int attacker, bool motherInfect, bool respawnOverride, bool respawn)
{
	
	int player_health = GetClientHealth(client);
	if (player_health < 300)
	{
		CreateTimer(0.5, Timer_SetDefaultClass, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

Action Timer_SetDefaultClass(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (client && IsClientInGame(client) && IsPlayerAlive(client) && ZR_IsClientZombie(client))
	{
		SetDefaultClass(client);
	}
}

void SetDefaultClass(int client)
{
	zrClasses Items;
	
	// get class info from the array
	array_classes.GetArray(GetRandomInt(0, array_classes.Length - 1), Items);
	
	// set a valid class
	ZR_SelectClientClass(client, Items.index); 
	
	// apply health of the class selected
	SetEntityHealth(client, Items.health); 
	
	// check if model is valid and is precached
	if (strlen(Items.model) > 2 && IsModelPrecached(Items.model)) 
	{
		// then apply it
		SetEntityModel(client, Items.model); 
	}
} 