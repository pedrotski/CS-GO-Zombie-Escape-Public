#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#pragma newdecls required

#define DMG_FALL   (1 << 5)

public Plugin myinfo =  
{
	name = "[CS:GO] No Fall Damage",
	author = "alexip121093 & Neoxx",
	description = "No Falling Damage & No Fall Damage Sound",
	version = "1.0.1",
	url = "https://forums.alliedmods.net/showthread.php?p=2316188"
}

public void OnPluginStart() 
{
	AddNormalSoundHook(SoundHook);
}

public void OnClientPostAdminCheck(int client) 
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action SoundHook(int clients[64], int &numClients, char sound[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags) 
{
	if(StrContains(sound, "player/damage", false) >= 0)
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype) 
{
	if (damagetype & DMG_FALL)
		return Plugin_Handled;
	
	return Plugin_Continue;
}