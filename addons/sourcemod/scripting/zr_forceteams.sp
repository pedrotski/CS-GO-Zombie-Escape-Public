/*
 * =============================================================================
 * File:		  SM ZR Force Teams.sp
 * Type:		  Base
 * Description:   Plugin's base file.
 *
 * Copyright (C) $CURRENT_YEAR  Anubis Edition. All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 */
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
//#include <zombiereloaded>

#pragma newdecls required

#define PLUGIN_NAME           "SM ZR Force Teams"
#define PLUGIN_AUTHOR         "Anubis"
#define PLUGIN_DESCRIPTION    "SM ZR Force Teams - Auto_Igroundwconditions"
#define PLUGIN_VERSION        "1.1"
#define PLUGIN_URL            "https://github.com/Stewart-Anubis"

#define CVARS_TEAMMATES_ARE_ENEMIES_LOCKED 0
#define CVARS_IGNORE_ROUND_WIN_CONDITIONS_LOCKED 1
#define CVARS_IGNORE_ROUND_WIN_CONDITIONS_ZOMBIESPAWNED_LOCKED 0

Handle g_hIgnoreRoundWinConditions = INVALID_HANDLE,
	g_hTeammatesAreEnemies = INVALID_HANDLE,
	g_hTimeRoundEnd = INVALID_HANDLE;

bool g_bStarted = false,
	g_bZombieSpawn = false;

int g_iMaxTime = 0;

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public void OnPluginStart()
{
	g_hIgnoreRoundWinConditions = FindConVar("mp_ignore_round_win_conditions");
	g_hTeammatesAreEnemies = FindConVar("mp_teammates_are_enemies");
	
	SetConVarInt(g_hIgnoreRoundWinConditions, CVARS_IGNORE_ROUND_WIN_CONDITIONS_LOCKED);
	SetConVarInt(g_hTeammatesAreEnemies, CVARS_TEAMMATES_ARE_ENEMIES_LOCKED);

	HookConVarChange(g_hIgnoreRoundWinConditions, CvarsHookLocked);
	HookConVarChange(g_hTeammatesAreEnemies, CvarsHookLocked);

	HookEvent("round_prestart", EventRoundPreStart, EventHookMode_Pre);
	HookEvent("player_spawn", EventPlayerSpawn);
	HookEvent("round_start", EventRound);
	HookEvent("round_freeze_end", EventRoundFreezeEnd);
	HookEvent("round_end", EventRound);
}

public void CvarsHookLocked(Handle cvar, const char[] oldvalue, const char[] newvalue)
{
	if (cvar == g_hIgnoreRoundWinConditions)
	{
		if(!g_bStarted)
		{
			// If plugin is reverting value, then stop.
			if (StringToInt(newvalue) == CVARS_IGNORE_ROUND_WIN_CONDITIONS_LOCKED)
			{
				return;
			}
		
			// Revert to locked value.
			SetConVarInt(g_hIgnoreRoundWinConditions, CVARS_IGNORE_ROUND_WIN_CONDITIONS_LOCKED);
		}
		else
		{
			// If plugin is reverting value, then stop.
			if (StringToInt(newvalue) == CVARS_IGNORE_ROUND_WIN_CONDITIONS_ZOMBIESPAWNED_LOCKED)
			{
				return;
			}
		
			// Revert to locked value.
			SetConVarInt(g_hIgnoreRoundWinConditions, CVARS_IGNORE_ROUND_WIN_CONDITIONS_ZOMBIESPAWNED_LOCKED);
		}
	}

	else if (cvar == g_hTeammatesAreEnemies)
	{
		// If plugin is reverting value, then stop.
		if (StringToInt(newvalue) == CVARS_TEAMMATES_ARE_ENEMIES_LOCKED)
		{
			return;
		}
		
		// Revert to locked value.
		SetConVarInt(g_hTeammatesAreEnemies, CVARS_TEAMMATES_ARE_ENEMIES_LOCKED);
	}
}

public void OnMapStart()
{
	// Reset timer handle.
	g_hTimeRoundEnd = INVALID_HANDLE;
}

public Action EventRoundPreStart(Handle event, const char[] name, bool dontBroadcast)
{
	g_iMaxTime = 0;
	g_bStarted = false;
	g_bZombieSpawn = false;
	SetConVarInt(g_hIgnoreRoundWinConditions, CVARS_IGNORE_ROUND_WIN_CONDITIONS_LOCKED);
}

public Action EventRound(Handle event, const char[] name, bool dontBroadcast)
{
	// If round end timer is running, then kill it.
	if (g_hTimeRoundEnd != INVALID_HANDLE)
	{
		// Kill timer.
		KillTimer(g_hTimeRoundEnd);
		
		// Reset timer handle.
		g_hTimeRoundEnd = INVALID_HANDLE;
	}
}

public Action EventRoundFreezeEnd(Handle event, const char[] name, bool dontBroadcast)
{
	// Calculate round length, in seconds.
	// Get mp_roundtime. (in minutes)
	float fRoundtime = GetConVarFloat(FindConVar("mp_roundtime"));

	// Convert to seconds.
	fRoundtime *= 60.0;
	fRoundtime++;

	// Start timer.
	CreateTimer(1.0, CheckZombieSpawnedEnd, _, TIMER_REPEAT);
	g_hTimeRoundEnd = CreateTimer(fRoundtime, RoundEndTimer, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action ZR_OnClientInfect(int &client, int &attacker, bool &motherInfect, bool &respawnOverride, bool &respawn)
{
	if(!g_bStarted)
	{
		g_bStarted = true;
		if(!g_bZombieSpawn && GetTeamClientCount(2) + GetTeamClientCount(3) >= 2) g_bZombieSpawn = true;
	}
}

public int ZR_OnContdownWarningTick(int tick)
{
	if (!g_bStarted && tick <= 0)
	{
		g_bStarted = true;
		if(!g_bZombieSpawn && GetTeamClientCount(2) + GetTeamClientCount(3) >= 2) g_bZombieSpawn = true;
	}
}

public Action EventPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	if(!g_bStarted || !g_bZombieSpawn && GetTeamClientCount(2) + GetTeamClientCount(3) <= 1)
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(GetClientTeam(client) == CS_TEAM_T) CS_SwitchTeam(client, CS_TEAM_CT);
	}
	else if(g_bStarted && !g_bZombieSpawn && GetTeamClientCount(2) + GetTeamClientCount(3) >= 2)
	{
		CS_TerminateRound(1.0, CSRoundEnd_GameStart, false);
	}
}

public Action RoundEndTimer(Handle timer)
{
	// Set the global timer handle variable to INVALID_HANDLE.
	g_hTimeRoundEnd = INVALID_HANDLE;

	// Prevent the map from being in time 00:00
	CS_TerminateRound(5.0, CSRoundEnd_Draw, false);
}

public Action CheckZombieSpawnedEnd(Handle timer)
{
	// Allow round end after zombie spawned
	if (g_bZombieSpawn)
	{
		SetConVarInt(g_hIgnoreRoundWinConditions, CVARS_IGNORE_ROUND_WIN_CONDITIONS_ZOMBIESPAWNED_LOCKED);
		return Plugin_Stop;
	}
	g_iMaxTime++;
	return Plugin_Continue;
}