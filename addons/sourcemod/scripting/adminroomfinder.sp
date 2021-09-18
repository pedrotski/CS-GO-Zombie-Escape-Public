
/*	Copyright (C) 2018 IT-KiLLER
	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.
	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
	
	You should have received a copy of the GNU General Public License
	along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

#include <sdktools>
#include <colors_csgo>
#include <regex>
#include <outputinfo>

#pragma semicolon 1
#pragma newdecls required
#define TAG_COLOR	"{green}[SM]{default}"
#define POSITIVE(%1) ((%1) < 0 ? 0 - (%1) : (%1))
#define STEP 4.0
#define RADIUSSIZE 40.0

int dArraySize;
int g_ArrayEntity[4096];
bool bUpdateEntities = true;
float playerOrgin[MAXPLAYERS+1][3];
char containsArray[][10] = {"admin", "stage", "level", "lvl", "act", "extreme", "ex1", "ex2", "ex3", "ex4", "round", "kill", "restart"};
int menuSelected[MAXPLAYERS+1];
Menu menuHandle[MAXPLAYERS+1];

// anti-stuck
bool isStuck[MAXPLAYERS+1];
int StuckCheck[MAXPLAYERS+1] = {0, ...};
float Ground_Velocity[3] = {0.0, 0.0, -300.0};

public Plugin myinfo =
{
	name = "[CS:GO] Admin Room Finder",
	author = "IT-KILLER",
	description = "You can easily navigate to the admin room.",
	version = "1.1.1",
	url = "https://github.com/IT-KiLLER"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_adminroom", Command_AdminRoom, ADMFLAG_CHANGEMAP, "The command opens the admin room menu");
	RegAdminCmd("sm_findadminroom", Command_AdminRoom, ADMFLAG_CHANGEMAP, "The command opens the admin room menu");
	HookEvent("round_start", EventRoundStart, EventHookMode_PostNoCopy);
}

public void EventRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	bUpdateEntities = true;
	for(int client = 1; client <= MaxClients; client++)
	{
		OnClientDisconnect(client);
	}
}

public void OnMapStart()
{
	bUpdateEntities = true;
}

public void OnClientDisconnect(int client)
{
	playerOrgin[client][0] = 0.0;
	playerOrgin[client][1] = 0.0;
	playerOrgin[client][2] = 0.0;
	menuSelected[client] = 0;
	isStuck[client] = false;
	StuckCheck[client] = false;
	menuHandle[client] = null; 
}

stock void UpdateEntitiesList()
{
	if(!bUpdateEntities) return;

	bUpdateEntities = false;
	dArraySize = 0;

	int entity = -1, entityNear = -1;
	bool loop;
	float entityPosition[3], entityPositionNear[3];
	float distance = 0.0;

	entity = -1;
	while((entity = FindEntityByClassname(entity, "func_button")) != -1)
	{
		if(!logicalButtonMatch(entity)) continue;

		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityPosition);
		loop = true;
		entityNear = -1;

		while((entityNear = FindEntityByClassname(entityNear, "func_button")) != -1 && loop)
		{
			if(entity != entityNear && logicalButtonMatch(entityNear))
			{
				GetEntPropVector(entityNear, Prop_Send, "m_vecOrigin", entityPositionNear);
				distance = GetVectorDistance(entityPosition, entityPositionNear, false);
				if(distance < 500.00)
				{	
					if(POSITIVE(entityPosition[0] - entityPositionNear[0]) < 40.00)
					{
						//PrintToChatAll("0: %f : distance %f" , POSITIVE(entityPosition[0] - entityPositionNear[0]), distance);
						g_ArrayEntity[dArraySize++] = entity;
						loop = false;
					}
					else if(POSITIVE(entityPosition[1] - entityPositionNear[1]) < 40.00)
					{
						//PrintToChatAll("2: %f : distance %f" , POSITIVE(entityPosition[1] - entityPositionNear[1]), distance);
						g_ArrayEntity[dArraySize++] = entity;
						loop = false;
					}
					else if(POSITIVE(entityPosition[2] - entityPositionNear[2]) < 40.00)
					{
						//PrintToChatAll("2: %f : distance %f" , POSITIVE(entityPosition[2] - entityPositionNear[2]), distance);
						g_ArrayEntity[dArraySize++] = entity;
						loop = false;
					}
				}
			}
		}
	}
	if(dArraySize)
	{
		SortCustom1D(g_ArrayEntity, dArraySize, OrderByLocation);

	}
}

stock bool logicalButtonMatch(int entity)
{
	char buffer[100];
	
	GetEntPropString(entity, Prop_Data, "m_iParent", buffer, 5);

	if(strlen(buffer))
	{
		// BAD MATCH
		return false;
	}

	GetEntPropString(entity, Prop_Data, "m_iName", buffer, 50);
	if(strlen(buffer))
	{
		for(int i = 0; i < sizeof(containsArray); i++)
		{
			if(StrContains(buffer, containsArray[i], false) !=-1)
			{
				// NICE MATCH
				return true;
			}
		}
	}

	int count = GetOutputActionCount( entity, "m_OnPressed" );
	for( int output = 0; output < count; output++ )
	{
		GetOutputActionParameter( entity, "m_OnPressed", output, buffer, 100);

		if(!startWith(buffer, "say")) continue;

		for(int i = 0; i < sizeof(containsArray); i++)
		{
			if(StrContains(buffer, containsArray[i], false) != -1)
			{
				// NICE MATCH
				return true;
			}
		}
	}

	// NO MATCH
	return false;
}

stock int OrderByLocation(int index1, int index2, const int[] array, Handle hndl)
{
	float position[3];

	GetEntPropVector(index1, Prop_Send, "m_vecOrigin", position);
	float A = position[0] + position[1] + position[2];

	GetEntPropVector(index2, Prop_Send, "m_vecOrigin", position);
	float B = position[0] + position[1] + position[2];

	return FloatCompare(A, B);
}

stock bool startWith(const char[] str, const char[] substr, bool caseSensitive = false)
{
	char pattern[125];
	FormatEx(pattern, 125, "%s^\\s*(%s)", caseSensitive ? "" : "(?i)", substr);
	Regex sw_regex = CompileRegex(pattern);
	int result = MatchRegex(sw_regex, str);
	CloseHandle(sw_regex);
	return result > 0;
}

public Action Command_AdminRoom(int client, int args)
{
	if(!client) return Plugin_Handled;

	UpdateEntitiesList();
	if(dArraySize)
	{
		Menu_Buttons(client);
	}
	else
	{
		CPrintToChat(client, "%s {red}This map has no admin room.", TAG_COLOR);
	}
	return Plugin_Handled;
}

void Menu_Buttons(int client)
{
	Menu menu = new Menu(MenuHandler_buttons, MenuAction_Select|MenuAction_Cancel|MenuAction_End|MenuAction_DrawItem);
	menuHandle[client] = menu;
	menu.SetTitle("[Admin Room Finder]");
	char menu_text[32];
	char entity_id[32];
	char strName[56];
	menu.AddItem("-1", "Get out (saved position)");
	int entity;
	for(int index = 0; index < dArraySize; index++)
	{
		entity = g_ArrayEntity[index];
		if(!IsValidEntity(entity) || !entity) continue;
		GetEntPropString(entity, Prop_Data, "m_iName", strName, sizeof(strName));

		if(!strlen(strName))
		{
			FormatEx(menu_text, sizeof(menu_text), "Button %d", index + 2);
		} 
		else
		{
			FormatEx(menu_text, sizeof(menu_text), "%s", strName);
		}
		FormatEx(entity_id, sizeof(entity_id), "%d", entity);
		menu.AddItem(entity_id, menu_text);
	}

	if(menu.ItemCount > 7)
	{
		menu.ExitBackButton = true;
	}
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_buttons(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Cancel:
		{
			menuSelected[param1] = 0;
		}
		case MenuAction_End:
		{
			if(param1 != MenuEnd_Selected)
			{
				delete(menu);
			}
		}
		case MenuAction_Select:
		{
			if(bUpdateEntities || !(dArraySize-1) || menuHandle[param1] != menu)
			{
				CPrintToChat(param1, "%s {red}You used an old session. Try again.", TAG_COLOR);
				delete menu;
				Command_AdminRoom(param1, 0);
				return 0;
			}
			char option[32];
			menu.GetItem(param2, option, sizeof(option));
			menuSelected[param1] = param2;
			int target = StringToInt(option);
			if(target == 0)
			{
				CPrintToChat(param1, "%s {red}An error occured.", TAG_COLOR);
				return 0;
			}
			else if(target == -1)
			{
				GetOut(param1);
			}
			else
			{
				GoToEntity(param1, target);
			}
			menu.DisplayAt(param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
			return 0;
		}
		case MenuAction_DrawItem:
		{
			int style;
			char option[32];
			menu.GetItem(param2, option, sizeof(option), style);
			if(param2 == 0 && playerOrgin[param1][0] == 0.0 && playerOrgin[param1][1] == 0.0 && playerOrgin[param1][2] == 0.0)
			{
				return ITEMDRAW_DISABLED;
			} 
			else if(menuSelected[param1] == param2)
			{
				return ITEMDRAW_DISABLED;
			} 
			return style;
		}
	}
	return 0;
}

stock void GoToEntity(int client, int entity)
{
	if(!IsValidEntity(entity))
	{
		CPrintToChat(client, "%s {red}The entity has become invalid", TAG_COLOR);
		return;
	}
	float currentPlayerPosition[3];
	float entityposition[3];

	GetClientAbsOrigin(client, currentPlayerPosition);
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityposition);

	float distanceButton = GetVectorDistance(currentPlayerPosition, entityposition, false);
	bool savedPosition = false;

	if(distanceButton > 700.00)
	{
		playerOrgin[client] = currentPlayerPosition;
		savedPosition = true;
	}

	TeleportEntity(client, entityposition, NULL_VECTOR, NULL_VECTOR);
	CPrintToChat(client, "%s {lightblue}You have been brought to {grey}Admin Room (button %d). %s", TAG_COLOR, entity, savedPosition ? "{lightgreen}Saved your position." : "");
	CreateTimer(0.2, Timer_StuckFix, client, TIMER_FLAG_NO_MAPCHANGE);
	return;
}

stock void GetOut(int client)
{
	if(playerOrgin[client][0] == 0.0 && playerOrgin[client][1] == 0.0 && playerOrgin[client][2] == 0.0)
	{
		CPrintToChat(client, "%s {red}Could not telport you because your position was not saved.", TAG_COLOR);
		return;
	}

	float currentPlayerPosition[3];
	float entityposition[3];
	GetClientAbsOrigin(client, currentPlayerPosition);
	bool InAdminRoom = false;

	for(int index=1; index < dArraySize; index++)
	{
		if(!IsValidEntity(g_ArrayEntity[index])) continue;

		GetEntPropVector(g_ArrayEntity[index], Prop_Send, "m_vecOrigin", entityposition);
		float distance = GetVectorDistance(currentPlayerPosition, entityposition, false);
		// In admin room
		if(distance < 2000.00)
		{
			InAdminRoom = true;
			break;
		}
	}

	if(InAdminRoom)
	{
		TeleportEntity(client, playerOrgin[client], NULL_VECTOR, NULL_VECTOR);
		CPrintToChat(client, "%s {orange}You have left the admin room.", TAG_COLOR);
	}
	else
	{
		CPrintToChat(client, "%s {red}You are not in the admin room.", TAG_COLOR);
	}
	return;
}

/*
======================================================================================================
	The anti-stuck code below is taken from: https://forums.alliedmods.net/showthread.php?t=243151
	Credit to Erreur 500 @ alliedmods
======================================================================================================
*/

public Action Timer_StuckFix(Handle timer, any client)
{
	StuckCheck[client] = 0;
	StartStuckDetection(client);
	FixPlayerPosition(client);
	return Plugin_Handled;
}

stock void StartStuckDetection(int client)
{
	isStuck[client] = false;
	isStuck[client] = CheckIfPlayerIsStuck(client); 
}

stock bool CheckIfPlayerIsStuck(int client)
{
	float vecMin[3];
	float vecMax[3];
	float vecOrigin[3];
	
	GetClientMins(client, vecMin);
	GetClientMaxs(client, vecMax);
	GetClientAbsOrigin(client, vecOrigin);
	
	TR_TraceHullFilter(vecOrigin, vecOrigin, vecMin, vecMax, MASK_SOLID, TraceEntityFilterSolid);
	return TR_DidHit();
}

public bool TraceEntityFilterSolid(int entity, int contentsMask) 
{
	return entity > MaxClients;
}

stock void FixPlayerPosition(int client)
{
	if(isStuck[client])
	{
		float pos_Z = 0.1;
		
		while(pos_Z <= RADIUSSIZE && !TryFixPosition(client, 10.0, pos_Z))
		{	
			pos_Z = -pos_Z;
			if(pos_Z > 0.0)
			{
				pos_Z += STEP;
			}
		}
	}
	else 
	{
		Handle trace = INVALID_HANDLE;
		float vecOrigin[3];
		float vecAngle[3];
		
		GetClientAbsOrigin(client, vecOrigin);
		vecAngle[0] = 90.0;
		trace = TR_TraceRayFilterEx(vecOrigin, vecAngle, MASK_SOLID, RayType_Infinite, TraceEntityFilterSolid);		
		if(!TR_DidHit(trace)) 
		{
			CloseHandle(trace);
			return;
		}
		
		TR_GetEndPosition(vecOrigin, trace);
		CloseHandle(trace);
		vecOrigin[2] += 10.0;
		TeleportEntity(client, vecOrigin, NULL_VECTOR, Ground_Velocity); 
		
		if(StuckCheck[client] < 7)
		{
			StartStuckDetection(client);
		}
	}
}

bool TryFixPosition(int client, float Radius, float pos_Z)
{
	float DegreeAngle;
	float vecPosition[3];
	float vecOrigin[3];
	float vecAngle[3];
	
	GetClientAbsOrigin(client, vecOrigin);
	GetClientEyeAngles(client, vecAngle);
	vecPosition[2] = vecOrigin[2] + pos_Z;

	DegreeAngle = -180.0;
	while(DegreeAngle < 180.0)
	{
		vecPosition[0] = vecOrigin[0] + Radius * Cosine(DegreeAngle * FLOAT_PI / 180);
		vecPosition[1] = vecOrigin[1] + Radius * Sine(DegreeAngle * FLOAT_PI / 180);
		
		TeleportEntity(client, vecPosition, vecAngle, Ground_Velocity);
		if(!CheckIfPlayerIsStuck(client))
		{
			return true;
		}
		DegreeAngle += 10.0;
	}
	
	TeleportEntity(client, vecOrigin, vecAngle, Ground_Velocity);
	
	if(Radius <= RADIUSSIZE)
	{
		return TryFixPosition(client, Radius + STEP, pos_Z);
	}
	return false;
}