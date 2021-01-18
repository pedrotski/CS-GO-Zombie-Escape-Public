#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include <zombiereloaded>

#define PL_VERSION "1.2.0-A"

new Handle:g_hTime = INVALID_HANDLE;
new Float:g_Time;
new Float:b_colors;

new bool:g_RoundEnd = false;
new bool:g_BeaconActive = false;

new Handle:g_Cvar_BeaconColor = INVALID_HANDLE;

new g_BeamSprite = -1;
new g_HaloSprite = -1;

int redColor[4]		= {255, 75, 75, 255};
int orangeColor[4]	= {255, 128, 0, 255};
int greenColor[4]	= {75, 255, 75, 255};
int blueColor[4]	= {75, 75, 255, 255};
int whiteColor[4]	= {255, 255, 255, 255};
int greyColor[4]	= {128, 128, 128, 255};


public Plugin:myinfo =
{
    name        = "Beacon Last Human",
    author      = "alongub, Anubis Edition",
    description = "Beacons last survivor for X seconds.",
    version     = PL_VERSION,
    url         = "http://steamcommunity.com/id/alon"
};

public OnPluginStart()
{
	g_hTime = CreateConVar("sm_beaconlasthuman_time", "30", "The amount of time in seconds to beacon last survivor.");
	g_Cvar_BeaconColor = CreateConVar("sm_beaconlasthuman_color", "0", "Color beacon [ 0=Red 2=Orange 3=Green 4=Blue 5=White 6=Grey ].");

	g_Time = GetConVarFloat(g_hTime);
	b_colors = GetConVarFloat(g_Cvar_BeaconColor);
	
	HookConVarChange(g_hTime, OnTimeCvarChange);
	HookConVarChange(g_Cvar_BeaconColor, OnTimeCvarChange);

	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_death", Event_PlayerDeath);

	AutoExecConfig(true, "beaconlasthuman");
}

public OnMapStart()
{
	LoadTranslations("beaconlasthuman.phrases");
	g_BeamSprite = PrecacheModel("sprites/laserbeam.vmt");
	g_HaloSprite = PrecacheModel("sprites/glow01.vmt");
}

public OnTimeCvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == g_hTime)
	{
		g_Time = StringToFloat(newValue);
	}

	else if (convar == g_Cvar_BeaconColor)
	{
		b_colors = StringToFloat(newValue);
	}
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new humans = 0;
	new zombies = 0;
	
	new client = -1;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;

		if (!IsPlayerAlive(i))
			continue;

		if (ZR_IsClientHuman(i))
		{
			humans++;
			client = i;
		}
		else if (ZR_IsClientZombie(i))
		{
			zombies++;
		}
	}

	if (zombies > 0 && humans == 1 && client != -1 && (!g_BeaconActive))
	{
		CreateTimer(1.0, Timer_Beacon, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		g_BeaconActive = true;
	}
	
	return;
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_RoundEnd = false;
	g_BeaconActive = false;
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_RoundEnd = true;
	g_BeaconActive = false;
}

public Action:Timer_Beacon(Handle:timer, any:client)
{
	static times = 0;

	if (g_RoundEnd)
	{
		times = 0;
		return Plugin_Stop;
	}
	
	if (times < g_Time)
	{
		new Float:vec[3];
		GetClientAbsOrigin(client, vec);
		vec[2] += 10;
		
		if (b_colors == 0) {
		TE_SetupBeamRingPoint(vec, 10.0, 190.0, g_BeamSprite, g_HaloSprite, 0, 15, 1.0, 5.0, 0.0, redColor, 10, 0);
		} else if (b_colors == 1) {
		TE_SetupBeamRingPoint(vec, 10.0, 190.0, g_BeamSprite, g_HaloSprite, 0, 15, 1.0, 5.0, 0.0, orangeColor, 10, 0);
		} else if (b_colors == 2) {
		TE_SetupBeamRingPoint(vec, 10.0, 190.0, g_BeamSprite, g_HaloSprite, 0, 15, 1.0, 5.0, 0.0, greenColor, 10, 0);
		} else if (b_colors == 3) {
		TE_SetupBeamRingPoint(vec, 10.0, 190.0, g_BeamSprite, g_HaloSprite, 0, 15, 1.0, 5.0, 0.0, blueColor, 10, 0);
		} else if (b_colors == 4) {
		TE_SetupBeamRingPoint(vec, 10.0, 190.0, g_BeamSprite, g_HaloSprite, 0, 15, 1.0, 5.0, 0.0, whiteColor, 10, 0);
		} else if (b_colors >= 5) {
		TE_SetupBeamRingPoint(vec, 10.0, 190.0, g_BeamSprite, g_HaloSprite, 0, 15, 1.0, 5.0, 0.0, greyColor, 10, 0);
		}
		TE_SendToAll();

		EmitAmbientSound("buttons/blip1.wav", vec, client, SNDLEVEL_RAIDSIREN);
		times++;

		PrintCenterTextAll("%t", "Last human is under beacon", (g_Time - times));
	}
	else
	{
		times = 0;
		g_BeaconActive = false;
		return Plugin_Stop;
	}

	return Plugin_Continue;
}