#include <zombiereloaded>
#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

bool started;

public Plugin myinfo = 
{
	name = "SM ZR Force Teams", 
	author = "Franc1sco franug [ASS]", 
	description = "", 
	version = "1.1", 
	url = "http://steamcommunity.com/id/franug"
};

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_Pre);
}

Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (started)
	{
		return;
	}
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (GetClientTeam(client) == CS_TEAM_T)
	{
		CS_SwitchTeam(client, CS_TEAM_CT);
	}
}

Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	started = false;
}

public Action ZR_OnClientInfect(int &client, int &attacker, bool &motherInfect, bool &respawnOverride, bool &respawn)
{
	if (!started)
	{
		started = true;
	}
}
