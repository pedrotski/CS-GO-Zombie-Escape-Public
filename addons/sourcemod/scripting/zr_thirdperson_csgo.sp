/*  Thirdperson
 *
 *  Copyright (C) 2017 Francisco 'Franc1sco' García
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#include <sourcemod>
#include <sdktools>
#include <colors_csgo>

#include <zombiereloaded>

#define PLUGIN_VERSION "1.7-A CS:GO edition"

#pragma semicolon 1

new Third[MAXPLAYERS+1];
new Mirror[MAXPLAYERS+1];
new Handle:gH_Enabled = INVALID_HANDLE;
new Handle:gH_Admins = INVALID_HANDLE;
new Handle:mp_forcecamera;
new bool:gB_Enabled;
new bool:gB_Admins;

new Handle:tercera_cvar;

public Plugin:myinfo = 
{
	name = "Thirdperson & Mirror",
	author = "shavit and Franc1sco franug, Anubis Edition",
	description = "Allow players/admins to toggle thirdperson and mirror on themselves/players.",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/franug"
}

public OnPluginStart()
{
	new Handle:Version = CreateConVar("sm_csgothirdperson_version", PLUGIN_VERSION, "Thirdperson's version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	SetConVarString(Version, PLUGIN_VERSION, _, true);
	
	gH_Enabled = CreateConVar("sm_thirdperson_enabled", "1", "Thirdperson's enabled?", 0, true, 0.0, true, 1.0);
	gH_Admins = CreateConVar("sm_thirdperson_admins", "1", "Allow admins to toggle thirdperson to players?", 0, true, 0.0, true, 1.0);
	
	gB_Enabled = true;
	gB_Admins = true;
	
	HookConVarChange(gH_Enabled, ConVarChanged);
	HookConVarChange(gH_Admins, ConVarChanged);
	
	RegConsoleCmd("sm_third", Command_TP, "Toggle thirdperson");
	RegConsoleCmd("sm_thirdperson", Command_TP, "Toggle thirdperson");
	RegConsoleCmd("sm_tp", Command_TP, "Toggle thirdperson");
	RegConsoleCmd("sm_mirror", Command_MR, "Toggle Rotational Thirdperson view");
	RegConsoleCmd("sm_mr", Command_MR, "Toggle Rotational Thirdperson view");
	
	mp_forcecamera = FindConVar("mp_forcecamera");
	
	HookEvent("player_death", Player_Death, EventHookMode_Pre);
	HookEvent("player_spawn", Player_Spawn);
	
	LoadTranslations("common.phrases");
	LoadTranslations("thirdperson.phrases");
	
	tercera_cvar = FindConVar("sv_allow_thirdperson");
	if(tercera_cvar == INVALID_HANDLE)
		SetFailState("sv_allow_thirdperson not found!");
		
	SetConVarInt(tercera_cvar, 1);
	
	HookConVarChange(tercera_cvar, ConVarChanged);
	
	
	AutoExecConfig(true, "thirdperson_csgo");
}

public ConVarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(cvar == gH_Enabled)
	{
		gB_Enabled = StringToInt(newVal)? true:false;
	}
	
	else if(cvar == gH_Admins)
	{
		gB_Admins = StringToInt(newVal)? true:false;
	}
	else if(cvar == tercera_cvar)
	{
		if(StringToInt(newVal) != 1)
			SetConVarInt(tercera_cvar, 1);
	}
}

public Action:Command_TP(client, args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	
	new target = client, String:arg1[MAX_TARGET_LENGTH];
	
	GetCmdArg(1, arg1, MAX_TARGET_LENGTH);
	
	if(!gB_Enabled)
	{
		CReplyToCommand(client, "t%", "Thirdperson is disabled");
		return Plugin_Handled;
	}
	
	if(CheckCommandAccess(client, "tptarget", ADMFLAG_SLAY) && args == 1)
	{
		if(gB_Admins)
		{
			target = FindTarget(client, arg1);
			
			if(target == -1)
			{
				return Plugin_Handled;
			}
			
			if(IsValidClient(target, true))
			{
				Toggle(target);
				if(!Third[target])
				{
					CReplyToCommand(client, "%t", "Admin toggled firstsperson", target);
					CPrintToChat(target, "%t", "Admin toggled firstsperson client", client);
				}
				if(Third[target])
				{
					CReplyToCommand(client, "%t", "Admin toggled thirdsperson", target);
					CPrintToChat(target, "%t", "Admin toggled thirdsperson client", client);
				}
			}
			
			else if(!IsPlayerAlive(target))
			{
				CReplyToCommand(client, "%t", "The target has to be alive");
			}
			
			return Plugin_Handled;
		}
		
		else
		{
			CReplyToCommand(client, "%t", "Currently admins can toggle");
			
			return Plugin_Handled;
		}
	}
	
	if(IsValidClient(target, true))
	{
		Toggle(target);
		if(!Third[client]) CReplyToCommand(client, "%t", "You are in firstsperson");
		if(Third[client]) CReplyToCommand(client, "%t", "You are in thirdsperson");
		
		return Plugin_Handled;
	}
	
	else if(!IsPlayerAlive(target))
	{
		CReplyToCommand(client, "%t", "Is Player no Alive");
		
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
}

public Action:Command_MR(client, args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	
	new target = client, String:arg1[MAX_TARGET_LENGTH];
	
	GetCmdArg(1, arg1, MAX_TARGET_LENGTH);
	
	if(!gB_Enabled)
	{
		CReplyToCommand(client, "t%", "Thirdperson is disabled");
		return Plugin_Handled;
	}
	
	if(CheckCommandAccess(client, "tptarget", ADMFLAG_SLAY) && args == 1)
	{
		if(gB_Admins)
		{
			target = FindTarget(client, arg1);
			
			if(target == -1)
			{
				return Plugin_Handled;
			}
			
			if(IsValidClient(target, true))
			{
				ToggleMR(target);
				if(!Mirror[target])
				{
					CReplyToCommand(client, "%t", "Admin toggled mirror off", target);
					CPrintToChat(target, "%t", "Admin toggled mirror off client", client);
				}
				if(Mirror[target])
				{
					CReplyToCommand(client, "%t", "Admin toggled mirror on", target);
					CPrintToChat(target, "%t", "Admin toggled mirror on client", client);
				}
			}
			
			else if(!IsPlayerAlive(target))
			{
				CReplyToCommand(client, "%t", "The target has to be alive");
			}
			
			return Plugin_Handled;
		}
		
		else
		{
			CReplyToCommand(client, "%t", "Currently admins can toggle");
			
			return Plugin_Handled;
		}
	}
	
	if(IsValidClient(target, true))
	{
		ToggleMR(target);
		if(!Mirror[client]) CReplyToCommand(client, "%t", "Mirror mode off");
		if(Mirror[client]) CReplyToCommand(client, "%t", "Mirror mode enabled");

		return Plugin_Handled;
	}
	
	else if(!IsPlayerAlive(target))
	{
		CReplyToCommand(client, "%t", "Is Player no Alive");
		
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
}

public ZR_OnClientInfected(client, attacker, bool:motherInfect, bool:respawnOverride, bool:respawn)
{
	if(Mirror[client]) ToggleMR(client);
	if(Third[client])
		ClientCommand(client, "thirdperson");
}

public Action:Player_Spawn(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(Mirror[client]) ToggleMR(client);
	if(Third[client])
		ClientCommand(client, "thirdperson");
}

public Action:Player_Death(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(Mirror[client]) ToggleMR(client);
	if(Third[client])
		ClientCommand(client, "firstperson");
}

public OnClientPutInServer(client)
{
	Third[client] = false;
	Mirror[client] = false;
}

public Toggle(client)
{
	if(!Third[client])
	{
		if(Mirror[client]) ToggleMR(client);
		ClientCommand(client, "thirdperson");
		Third[client] = true;
	}
	
	else
	{
		ClientCommand(client, "firstperson");
		Third[client] = false;
	}
}

public ToggleMR(client)
{
	if(!Mirror[client])
	{
		if(Third[client]) Toggle(client);
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0); 
		SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
		SetEntProp(client, Prop_Send, "m_iFOV", 120);
		SendConVarValue(client, mp_forcecamera, "1");
		Mirror[client] = true;
	}
	
	else
	{
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
		SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
		SetEntProp(client, Prop_Send, "m_iFOV", 90);
		decl String:valor[6];
		GetConVarString(mp_forcecamera, valor, 6);
		SendConVarValue(client, mp_forcecamera, valor);
		Mirror[client] = false;
	}
}

stock bool:IsValidClient(client, bool:bAlive = false)
{
	if(client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && (bAlive == false || IsPlayerAlive(client)))
	{
		return true;
	}
	
	return false;
}