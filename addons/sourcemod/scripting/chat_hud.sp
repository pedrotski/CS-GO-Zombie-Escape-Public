/*
 * =============================================================================
 * File:		  Chat_Hud
 * Type:		  Base
 * Description:   Plugin's base file.
 *
 * Copyright (C)   Anubis Edition. All rights reserved.
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
#define PLUGIN_NAME           "Chat_Hud"
#define PLUGIN_AUTHOR         "Anubis"
#define PLUGIN_DESCRIPTION    "Countdown timers based on messages from maps. And translations of map messages."
#define PLUGIN_VERSION        "2.0"
#define PLUGIN_URL            "https://github.com/Stewart-Anubis"

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <csgocolors_fix>

#pragma newdecls required

#define MAXLENGTH_INPUT 			256
#define MAX_TEXT_LENGTH 			64

#define MENU_LINE_REG_LENGTH 		64
#define MENU_LINE_BIG_LENGTH 		128
#define MENU_LINE_TITLE_LENGTH 	256
#define HUGE_LINE_LENGTH 			512

ConVar g_cChatHud = null;
ConVar g_cAvoidSpanking = null;
ConVar g_cAvoidSpankingTime = null;
ConVar g_changecolor = null;
ConVar g_cVHudColor1 = null;
ConVar g_cVHudColor2 = null;

Handle g_hTimerHandleA = INVALID_HANDLE;
Handle g_hTimerHandleB = INVALID_HANDLE;
Handle g_hHudSyncA = INVALID_HANDLE;
Handle g_hHudSyncB = INVALID_HANDLE;
Handle g_hKvChatHud = INVALID_HANDLE;
Handle g_hKvChatHudAdmin = INVALID_HANDLE;

Handle g_hChatHud = INVALID_HANDLE;
Handle g_hChatMap = INVALID_HANDLE;
Handle g_hChatSound = INVALID_HANDLE;
Handle g_hHudSound = INVALID_HANDLE;
Handle g_hHudPosition = INVALID_HANDLE;

char g_sPathChatHud[PLATFORM_MAX_PATH];
char g_sClLang[MAXPLAYERS+1][3];
char g_sLineComapare[MAXLENGTH_INPUT];

int g_iNumberA;
int g_iNumberB;
int g_iONumberA;
int g_iONumberB;
int g_iHudColor1[3];
int g_iHudColor2[3];
int g_icolor_hudA = 0;
int g_icolor_hudB = 0;
int g_ihudAB = 1;
int g_iItemSettings[MAXPLAYERS + 1];

float g_fHudPosA[MAXPLAYERS+1][2];
float g_fHudPosB[MAXPLAYERS+1][2];
float g_fColor_Time;
float g_fAvoidSpankingTime;

bool g_bChatHud;
bool g_bAvoidSpanking;

enum struct ChatHud_Enum
{
	bool e_bChatHud;
	bool e_bChatMap;
	bool e_bChatSound;
	bool e_bHudSound;
	char e_bHudPosition[MAX_TEXT_LENGTH];
}

ChatHud_Enum ChatHudClientEnum[MAXPLAYERS+1];

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
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);

	DeleteTimer("All");
	g_hHudSyncA = CreateHudSynchronizer();
	g_hHudSyncB = CreateHudSynchronizer();

	g_hChatHud = RegClientCookie("Chat_Hud", "Chat Hud", CookieAccess_Protected);
	g_hChatMap = RegClientCookie("Chat_Hud_Chat", "Chat Hud Chat", CookieAccess_Protected);
	g_hChatSound = RegClientCookie("Chat_Hud_Chat_Sounds", "Chat Hud Chat Sounds", CookieAccess_Protected);
	g_hHudSound = RegClientCookie("Chat_Hud_Hud_Sounds", "Chat Hud Hud Sounds", CookieAccess_Protected);
	g_hHudPosition = RegClientCookie("Chat_Hud_Position", "Chat Hud Position", CookieAccess_Protected);

	RegConsoleCmd("sm_chud", Command_CHudClient, "Chat Hud Client Menu");
	RegAdminCmd("sm_chudadmin", Command_CHudAdmin, ADMFLAG_GENERIC, "Chat Hud Admin Menu");

	g_cChatHud = CreateConVar("sm_chat_hud", "1", "Chat Hud Enable = 1/Disable = 0");
	g_cAvoidSpanking = CreateConVar("sm_chat_hud_avoid_spanking", "1", "Map anti spam system, Enable = 1/Disable = 0");
	g_cAvoidSpankingTime = CreateConVar("sm_chat_hud_time_spanking", "5", "Map spam detection time");
	g_changecolor = CreateConVar("sm_chat_hud_time_changecolor", "3", "Set the final time for Hud to change colors.");
	g_cVHudColor1 = CreateConVar("sm_chat_hud_color_1", "0 255 0", "RGB color value for the hud Start.");
	g_cVHudColor2 = CreateConVar("sm_chat_hud_color_2", "255 0 0", "RGB color value for the hud Finish.");

	g_cChatHud.AddChangeHook(ConVarChange);
	g_cAvoidSpanking.AddChangeHook(ConVarChange);
	g_cAvoidSpankingTime.AddChangeHook(ConVarChange);
	g_changecolor.AddChangeHook(ConVarChange);
	g_cVHudColor1.AddChangeHook(ConVarChange);
	g_cVHudColor2.AddChangeHook(ConVarChange);

	g_bChatHud = g_cChatHud.BoolValue;
	g_bAvoidSpanking = g_cAvoidSpanking.BoolValue;
	g_fAvoidSpankingTime = g_cAvoidSpankingTime.FloatValue;
	g_fColor_Time = g_changecolor.FloatValue;
	ChatHudColorRead();

	AutoExecConfig(true, "Chat_hud");
	
	SetCookieMenuItem(PrefMenu, 0, "Chat Hud");

	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			OnClientPutInServer(i);
			OnClientCookiesCached(i);
		}
	}
}

public void ColorStringToArray(const char[] sColorString, int aColor[3])
{
	char asColors[4][4];
	ExplodeString(sColorString, " ", asColors, sizeof(asColors), sizeof(asColors[]));

	aColor[0] = StringToInt(asColors[0]);
	aColor[1] = StringToInt(asColors[1]);
	aColor[2] = StringToInt(asColors[2]);
}

public void OnMapStart()
{
	LoadTranslations("chat_hud.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
	ReadFileChatHud();
}

public void PrefMenu(int client, CookieMenuAction actions, any info, char[] buffer, int maxlen)
{
	if(actions == CookieMenuAction_DisplayOption)
	{
		FormatEx(buffer, maxlen, "%T", "Cookie_Menu", client);
	}

	if(actions == CookieMenuAction_SelectOption)
	{
		if(g_bChatHud)
		{
			MenuClientChud(client);
		}
	}
}

public void OnClientPutInServer(int client)
{
	CreateTimer(1.0, OnClientPutInServerPost, client);
}

public Action OnClientPutInServerPost(Handle PutTimer, int client)
{
	if(IsValidClient(client))
	{
		GetLanguageInfo(GetClientLanguage(client), g_sClLang[client], sizeof(g_sClLang[]));
	}
}

public void OnClientCookiesCached(int client)
{
	g_iItemSettings[client] = 0;
	char scookie[MAX_TEXT_LENGTH];

	GetClientCookie(client, g_hChatHud, scookie, sizeof(scookie));
	if(!StrEqual(scookie, ""))
	{
		ChatHudClientEnum[client].e_bChatHud = view_as<bool>(StringToInt(scookie));
	}
	else	ChatHudClientEnum[client].e_bChatHud = true;
		
	GetClientCookie(client, g_hChatMap, scookie, sizeof(scookie));
	if(!StrEqual(scookie, ""))
	{
		ChatHudClientEnum[client].e_bChatMap = view_as<bool>(StringToInt(scookie));
	}
	else	ChatHudClientEnum[client].e_bChatMap = true;

	GetClientCookie(client, g_hChatSound, scookie, sizeof(scookie));
	if(!StrEqual(scookie, ""))
	{
		ChatHudClientEnum[client].e_bChatSound = view_as<bool>(StringToInt(scookie));
	}
	else	ChatHudClientEnum[client].e_bChatSound = true;
	
	GetClientCookie(client, g_hHudSound, scookie, sizeof(scookie));
	if(!StrEqual(scookie, ""))
	{
		ChatHudClientEnum[client].e_bHudSound = view_as<bool>(StringToInt(scookie));
	}
	else	ChatHudClientEnum[client].e_bHudSound = false;
	
	GetClientCookie(client, g_hHudPosition, scookie, sizeof(scookie));
	if(!StrEqual(scookie, ""))
	{
		ChatHudClientEnum[client].e_bHudPosition = scookie;
	}
	else	ChatHudClientEnum[client].e_bHudPosition = "-1.0 0.060";

	ChatHudStringPos(client);
}

void ChatHudStringPos(int client)
{
	char StringPos[2][8];

	ExplodeString(ChatHudClientEnum[client].e_bHudPosition, " ", StringPos, sizeof(StringPos), sizeof(StringPos[]));

	g_fHudPosA[client][0] = StringToFloat(StringPos[0]);
	g_fHudPosA[client][1] = StringToFloat(StringPos[1]);
	g_fHudPosB[client][0] = StringToFloat(StringPos[0]);
	float f_temp = StringToFloat(StringPos[1]);
	g_fHudPosB[client][1] = f_temp + 0.025;
}

public void ReadFileChatHud()
{
	delete g_hKvChatHud;
	delete g_hKvChatHudAdmin;
	
	char mapname[64];
	GetCurrentMap(mapname, sizeof(mapname));
	BuildPath(Path_SM, g_sPathChatHud, sizeof(g_sPathChatHud), "configs/Chat_Hud/%s.txt", mapname);
	
	g_hKvChatHud = CreateKeyValues("Chat_Hud");
	g_hKvChatHudAdmin = CreateKeyValues("Chat_Hud");
	
	if(!FileExists(g_sPathChatHud)) KeyValuesToFile(g_hKvChatHud, g_sPathChatHud);
	else FileToKeyValues(g_hKvChatHud, g_sPathChatHud);

	KvRewind(g_hKvChatHud);
	KvCopySubkeys(g_hKvChatHud, g_hKvChatHudAdmin);
	KvRewind(g_hKvChatHudAdmin);
	CheckSoundsChatHud();
}

void CheckSoundsChatHud()
{
	char s_Buffer[MAXLENGTH_INPUT];
	PrecacheSound("common/talk.wav", false);
	PrecacheSound("common/stuck1.wav", false);
	if(KvGotoFirstSubKey(g_hKvChatHud))
	{
		do
		{
			KvGetString(g_hKvChatHud, "sound", s_Buffer, 64, "default");
			if(!StrEqual(s_Buffer, "default"))
			{
				PrecacheSound(s_Buffer);				
				Format(s_Buffer, sizeof(s_Buffer), "sound/%s", s_Buffer);
				AddFileToDownloadsTable(s_Buffer);
			}
		} while (KvGotoNextKey(g_hKvChatHud));
	}
	KvRewind(g_hKvChatHud);
}

public void ConVarChange(ConVar convar, char[] oldValue, char[] newValue)
{
	g_bChatHud = g_cChatHud.BoolValue;
	g_bAvoidSpanking = g_cAvoidSpanking.BoolValue;
	g_fAvoidSpankingTime = g_cAvoidSpankingTime.FloatValue;
	g_fColor_Time = g_changecolor.FloatValue;
	ChatHudColorRead();
}

public void ChatHudColorRead()
{
	char s_ColorValue1[64];
	char s_ColorValue2[64];
	g_cVHudColor1.GetString(s_ColorValue1, sizeof(s_ColorValue1));
	g_cVHudColor2.GetString(s_ColorValue2, sizeof(s_ColorValue2));

	ColorStringToArray(s_ColorValue1, g_iHudColor1);
	ColorStringToArray(s_ColorValue2, g_iHudColor2);
}

public void Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	DeleteTimer("All");
	g_ihudAB = 1;
	g_sLineComapare = "";
}

stock void DeleteTimer(char[] s_TimerHandle = "")
{
	bool b_TimerHandleA = false;
	bool b_TimerHandleB = false;

	if (StrEqual(s_TimerHandle, "A")) b_TimerHandleA = true;
	if (StrEqual(s_TimerHandle, "B")) b_TimerHandleB = true;
	if (StrEqual(s_TimerHandle, "All")) { b_TimerHandleA = true; b_TimerHandleB = true; }

	if(b_TimerHandleA && g_hTimerHandleA != INVALID_HANDLE)
	{
		KillTimer(g_hTimerHandleA);
		g_hTimerHandleA = INVALID_HANDLE;
		g_ihudAB = 1;
	}
	if(b_TimerHandleB && g_hTimerHandleB != INVALID_HANDLE)
	{
		KillTimer(g_hTimerHandleB);
		g_hTimerHandleB = INVALID_HANDLE;
		if(g_hTimerHandleA == INVALID_HANDLE) g_ihudAB = 1;
	}
}

char Blacklist[][] = {
	"recharge", "recast", "cooldown", "cool"
};

bool CheckString(char[] string)
{
	for (int i = 0; i < sizeof(Blacklist); i++)
	{
		if(StrContains(string, Blacklist[i], false) != -1)
		{
			return true;
		}
	}
	return false;
}

public Action SpanReload(Handle sTime)
{
	g_sLineComapare = "";
}

public Action Command_CHudClient(int client, int arg)
{
	if(IsValidClient(client) && g_bChatHud)
	{
		MenuClientChud(client);
	}
	return Plugin_Handled;
}

public Action Command_CHudAdmin(int client, int argc)
{
	if(IsValidClient(client) && IsValidGenericAdmin(client))
	{
		MenuAdminChud(client);
	}
	else
	PrintToChat(client, "%t", "No Access");
	return Plugin_Handled;
}

void MenuClientChud(int client)
{
	if (!IsValidClient(client))
	{
		return;
	}

	SetGlobalTransTarget(client);
	g_iItemSettings[client] = 0;

	char m_sTitle[MENU_LINE_TITLE_LENGTH];
	char m_sChatHud[MENU_LINE_REG_LENGTH];
	char m_sChatMap[MENU_LINE_REG_LENGTH];
	char m_sChatSound[MENU_LINE_REG_LENGTH];
	char m_sHudSound[MENU_LINE_REG_LENGTH];
	char m_sHudPosition[MENU_LINE_REG_LENGTH];

	char m_sChatHudTemp[16];
	char m_sChatMapTemp[16];
	char m_sChatSoundTemp[16];
	char m_sHudPositionTemp[16];

	if(ChatHudClientEnum[client].e_bChatHud) Format(m_sChatHudTemp, sizeof(m_sChatHudTemp), "%t", "Enabled");
	else Format(m_sChatHudTemp, sizeof(m_sChatHudTemp), "%t", "Desabled");

	if(ChatHudClientEnum[client].e_bChatMap) Format(m_sChatMapTemp, sizeof(m_sChatMapTemp), "%t", "Enabled");
	else Format(m_sChatMapTemp, sizeof(m_sChatMapTemp), "%t", "Desabled");

	if(ChatHudClientEnum[client].e_bChatSound) Format(m_sChatSoundTemp, sizeof(m_sChatSoundTemp), "%t", "Enabled");
	else Format(m_sChatSoundTemp, sizeof(m_sChatSoundTemp), "%t", "Desabled");

	if(ChatHudClientEnum[client].e_bHudSound) Format(m_sHudPositionTemp, sizeof(m_sHudPositionTemp), "%t", "Enabled");
	else Format(m_sHudPositionTemp, sizeof(m_sHudPositionTemp), "%t", "Desabled");

	Format(m_sTitle, sizeof(m_sTitle),"%t", "Chat Hud Title", m_sChatHudTemp, m_sChatMapTemp, m_sChatSoundTemp, m_sHudPositionTemp, ChatHudClientEnum[client].e_bHudPosition);

	Format(m_sChatHud, sizeof(m_sChatHud), "%t", "Time Counter");
	Format(m_sChatMap, sizeof(m_sChatMap), "%t", "Map Messages");
	Format(m_sChatSound, sizeof(m_sChatSound), "%t", "Chat Click Sound");
	Format(m_sHudSound, sizeof(m_sHudSound), "%t", "Counter Alert Sound");
	Format(m_sHudPosition, sizeof(m_sHudPosition), "%t", "Counter Position");

	Menu MenuCHud = new Menu(MenuClientCHudCallBack);

	MenuCHud.ExitBackButton = true;
	MenuCHud.SetTitle(m_sTitle);

	MenuCHud.AddItem("Time Counter", m_sChatHud);
	MenuCHud.AddItem("Map Messages", m_sChatMap);
	MenuCHud.AddItem("Chat Click Sound", m_sChatSound);
	MenuCHud.AddItem("Counter Alert Sound", m_sHudSound);
	MenuCHud.AddItem("Counter Position", m_sHudPosition);
	MenuCHud.AddItem("", "", ITEMDRAW_NOTEXT);

	MenuCHud.Display(client, MENU_TIME_FOREVER);
}

public int MenuClientCHudCallBack(Handle MenuCHud, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_End)
	{
		delete MenuCHud;
	}

	if (action == MenuAction_Select)
	{
		char sItem[MAX_TEXT_LENGTH];
		GetMenuItem(MenuCHud, itemNum, sItem, sizeof(sItem));

		if (StrEqual(sItem[0], "Time Counter"))
		{
			ChatHudClientEnum[client].e_bChatHud = !ChatHudClientEnum[client].e_bChatHud;
			ChatHudCookiesSetBool(client, g_hChatHud, ChatHudClientEnum[client].e_bChatHud);
			MenuClientChud(client);
		}
		if (StrEqual(sItem[0], "Map Messages"))
		{
			ChatHudClientEnum[client].e_bChatMap = !ChatHudClientEnum[client].e_bChatMap;
			ChatHudCookiesSetBool(client, g_hChatMap, ChatHudClientEnum[client].e_bChatMap);
			MenuClientChud(client);
		}
		if (StrEqual(sItem[0], "Chat Click Sound"))
		{
			ChatHudClientEnum[client].e_bChatSound = !ChatHudClientEnum[client].e_bChatSound;
			ChatHudCookiesSetBool(client, g_hChatSound, ChatHudClientEnum[client].e_bChatSound);
			MenuClientChud(client);
		}
		if (StrEqual(sItem[0], "Counter Alert Sound"))
		{
			ChatHudClientEnum[client].e_bHudSound = !ChatHudClientEnum[client].e_bHudSound;
			ChatHudCookiesSetBool(client, g_hHudSound, ChatHudClientEnum[client].e_bHudSound);
			MenuClientChud(client);
		}
		if (StrEqual(sItem[0], "Counter Position"))
		{
			g_iItemSettings[client] = 1;
			CPrintToChat(client, "%t", "Change Hud Position", ChatHudClientEnum[client].e_bHudPosition);
			action = MenuAction_Cancel;
		}
	}

	if (action == MenuAction_Cancel)
	{
		if(itemNum == MenuCancel_ExitBack) ShowCookieMenu(client);
	}

	return 0;
}

void MenuAdminChud(int client, bool MenuAdmin2 = false, char[] ItemMenu = "")
{
	if(g_hKvChatHudAdmin == INVALID_HANDLE || g_hKvChatHud == INVALID_HANDLE)
	{
		ReadFileChatHud();
	}

	g_iItemSettings[client] = 0;

	if (!IsValidClient(client))
	{
		return;
	}

	SetGlobalTransTarget(client);

	char sBuffer_temp[MAXLENGTH_INPUT];
	char sBuffer_temp2[MAXLENGTH_INPUT];
	char m_sTitle[MENU_LINE_TITLE_LENGTH];

	Menu MenuChudAdmin = new Menu(MenuAdminChudCallBack);

	if(MenuAdmin2 && strlen(ItemMenu) != 0)
	{
		if(!KvJumpToKey(g_hKvChatHudAdmin, ItemMenu))
		{
			CPrintToChat(client, "%t", "Invalid Messages", ItemMenu);
			return;
		}

		char c_sTemp[MAXLENGTH_INPUT];
		char c_sMenu2_ChatHud[MAXLENGTH_INPUT];

		KvGetString(g_hKvChatHudAdmin, "default", c_sTemp, sizeof(c_sTemp), "");

		if (KvGetNum(g_hKvChatHudAdmin, "enabled") <= 0)
		{
			Format(m_sTitle, sizeof(m_sTitle), "%t", "Chat Hud Title Admin Disabled", RemoveColors(c_sTemp));
			MenuChudAdmin.SetTitle(m_sTitle);
			Format(c_sMenu2_ChatHud, sizeof(c_sMenu2_ChatHud), "%t", "Enable");
			MenuChudAdmin.AddItem("ChatHud_Menu2_Enable", c_sMenu2_ChatHud);
		}
		else
		{
			Format(m_sTitle, sizeof(m_sTitle), "%t", "Chat Hud Title Admin Enabled", RemoveColors(c_sTemp));
			MenuChudAdmin.SetTitle(m_sTitle);
			Format(c_sMenu2_ChatHud, sizeof(c_sMenu2_ChatHud), "%t", "Desable");
			MenuChudAdmin.AddItem("ChatHud_Menu2_Disable", c_sMenu2_ChatHud);
		}
		MenuChudAdmin.ExitBackButton = true;
		MenuChudAdmin.AddItem("", "", ITEMDRAW_NOTEXT);
		MenuChudAdmin.AddItem("", "", ITEMDRAW_NOTEXT);
		MenuChudAdmin.AddItem("", "", ITEMDRAW_NOTEXT);
		MenuChudAdmin.AddItem("", "", ITEMDRAW_NOTEXT);
		MenuChudAdmin.AddItem("", "", ITEMDRAW_NOTEXT);
	}
	else
	{
		Format(m_sTitle, sizeof(m_sTitle), "%t", "Chat Hud Admin Title");
		MenuChudAdmin.SetTitle(m_sTitle);
		MenuChudAdmin.ExitBackButton = true;

		if (KvGotoFirstSubKey(g_hKvChatHudAdmin))
		{
			do
			{
				KvGetString(g_hKvChatHudAdmin, "default", sBuffer_temp, sizeof(sBuffer_temp), "");
				if (KvGetNum(g_hKvChatHudAdmin, "enabled") <= 0)
				{
					Format(sBuffer_temp, sizeof(sBuffer_temp), "[%t] %s", "Desabled", sBuffer_temp);
				}
				else
				{
					Format(sBuffer_temp, sizeof(sBuffer_temp), "[%t] %s", "Enabled", sBuffer_temp);
				}
				KvGetSectionName(g_hKvChatHudAdmin, sBuffer_temp2, sizeof(sBuffer_temp2)); 
				MenuChudAdmin.AddItem(sBuffer_temp2, RemoveColors(sBuffer_temp));
			} while (KvGotoNextKey(g_hKvChatHudAdmin));
			KvRewind(g_hKvChatHudAdmin);
		}
		else
		{
			if (IsValidClient(client))
			{
				CPrintToChat(client, "%t", "No Messages found");
			}
			KvRewind(g_hKvChatHudAdmin);
			delete MenuChudAdmin;
			return;
		}
	}
	MenuChudAdmin.Display(client, MENU_TIME_FOREVER);
}

public int MenuAdminChudCallBack(Handle MenuChudAdmin, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_End)
	{
		delete MenuChudAdmin;
	}

	if (action == MenuAction_Select)
    {
		char sItem[MAX_TEXT_LENGTH];
		GetMenuItem(MenuChudAdmin, itemNum, sItem, sizeof(sItem));

		if (StrEqual(sItem[0], "ChatHud_Menu2_Disable"))
		{
			char sBuffer[MAX_TEXT_LENGTH];
			KvSetNum(g_hKvChatHudAdmin, "enabled", 0);
			KvGetSectionName(g_hKvChatHudAdmin, sBuffer, sizeof(sBuffer));
			KvRewind(g_hKvChatHudAdmin);
			KvRewind(g_hKvChatHud);
			KvRewind(g_hKvChatHudAdmin);
			KvCopySubkeys(g_hKvChatHudAdmin, g_hKvChatHud);
			KeyValuesToFile(g_hKvChatHudAdmin, g_sPathChatHud);

			MenuAdminChud(client, true, sBuffer);
		}
		else if (StrEqual(sItem[0], "ChatHud_Menu2_Enable"))
		{
			char sBuffer[MAX_TEXT_LENGTH];
			KvSetNum(g_hKvChatHudAdmin, "enabled", 1);
			KvGetSectionName(g_hKvChatHudAdmin, sBuffer, sizeof(sBuffer));
			KvRewind(g_hKvChatHudAdmin);
			KvRewind(g_hKvChatHud);
			KvRewind(g_hKvChatHudAdmin);
			KvCopySubkeys(g_hKvChatHudAdmin, g_hKvChatHud);
			KeyValuesToFile(g_hKvChatHudAdmin, g_sPathChatHud);

			MenuAdminChud(client, true, sBuffer);
		}
		else MenuAdminChud(client, true, sItem);
 	}

	if (action == MenuAction_Cancel)
	{
		KvRewind(g_hKvChatHudAdmin);
	}

	if (itemNum == MenuCancel_ExitBack)
	{
		KvRewind(g_hKvChatHudAdmin);
		MenuAdminChud(client);
	}

	return 0;
}

void ChatHudCookiesSetBool(int client, Handle cookie, bool cookievalue)
{
	char strCookievalue[8];
	BoolToString(cookievalue, strCookievalue, sizeof(strCookievalue));

	SetClientCookie(client, cookie, strCookievalue);
}

void BoolToString(bool value, char[] output, int maxlen)
{
	if(value) strcopy(output, maxlen, "1");
	else strcopy(output, maxlen, "0");
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if(client == 0)
	{
		if(g_hKvChatHud == INVALID_HANDLE)
		{
			ReadFileChatHud();
			return Plugin_Continue;
		}
		KvRewind(g_hKvChatHud);

		char s_ConsoleChat[MAXLENGTH_INPUT], Buffer_Temp[MAXLENGTH_INPUT], s_FilterText[sizeof(s_ConsoleChat)+1], s_ChatArray[32][MAXLENGTH_INPUT];
		char s_PrintText[MAXLENGTH_INPUT], s_PrintHud[MAXLENGTH_INPUT], s_Soundp[MAXLENGTH_INPUT], s_Soundt[MAXLENGTH_INPUT];
		int i_ConsoleNumber, i_FilterPos;
		bool b_IsCountable = false;

		Format(s_ConsoleChat, sizeof(s_ConsoleChat), sArgs);
		StripQuotes(s_ConsoleChat);

		if (g_bAvoidSpanking && StrEqual(g_sLineComapare, s_ConsoleChat)) { CreateTimer(g_fAvoidSpankingTime, SpanReload, TIMER_DATA_HNDL_CLOSE|TIMER_FLAG_NO_MAPCHANGE); return Plugin_Stop;}
		Format(g_sLineComapare, sizeof(g_sLineComapare), s_ConsoleChat);

		for (int i = 0; i < sizeof(s_ConsoleChat); i++) 
		{
			if (IsCharAlpha(s_ConsoleChat[i]) || IsCharNumeric(s_ConsoleChat[i]) || IsCharSpace(s_ConsoleChat[i])) 
			{
				s_FilterText[i_FilterPos++] = s_ConsoleChat[i];
			}
		}
		s_FilterText[i_FilterPos] = '\0';
		TrimString(s_FilterText);
		int i_Words = ExplodeString(s_FilterText, " ", s_ChatArray, sizeof(s_ChatArray), sizeof(s_ChatArray[]));

		if(i_Words == 1)
		{
			if(StringToInt(s_ChatArray[0]) != 0)
			{
				b_IsCountable = true;
				i_ConsoleNumber = StringToInt(s_ChatArray[0]);
			}
		}

		for(int i = 0; i <= i_Words; i++)
		{
			if(StringToInt(s_ChatArray[i]) != 0)
			{
				if(i + 1 <= i_Words && (StrEqual(s_ChatArray[i + 1], "s", false) || (CharEqual(s_ChatArray[i + 1][0], 's') && CharEqual(s_ChatArray[i + 1][1], 'e'))))
				{
					i_ConsoleNumber = StringToInt(s_ChatArray[i]);
					b_IsCountable = true;
				}
				if(!b_IsCountable && i + 2 <= i_Words && (StrEqual(s_ChatArray[i + 2], "s", false) || (CharEqual(s_ChatArray[i + 2][0], 's') && CharEqual(s_ChatArray[i + 2][1], 'e'))))
				{
					i_ConsoleNumber = StringToInt(s_ChatArray[i]);
					b_IsCountable = true;
				}
			}
			if(!b_IsCountable)
			{
				char c_Word[MAXLENGTH_INPUT];
				strcopy(c_Word, sizeof(c_Word), s_ChatArray[i]);
				int i_Len = strlen(c_Word);

				if(IsCharNumeric(c_Word[0]))
				{
					if(IsCharNumeric(c_Word[1]))
					{
						if(IsCharNumeric(c_Word[2]))
						{
							if(CharEqual(c_Word[3], 's'))
							{
								i_ConsoleNumber = StringEnder(c_Word, 5, i_Len);
								b_IsCountable = true;
							}
						}
						else if(CharEqual(c_Word[2], 's'))
						{
							i_ConsoleNumber = StringEnder(c_Word, 4, i_Len);
							b_IsCountable = true;
						}
					}
					else if(CharEqual(c_Word[1], 's'))
					{
						i_ConsoleNumber = StringEnder(c_Word, 3, i_Len);
						b_IsCountable = true;
					}
				}
			}
			if(b_IsCountable) break;
		}
		if(!KvJumpToKey(g_hKvChatHud, s_ConsoleChat))
		{
			KvJumpToKey(g_hKvChatHud, s_ConsoleChat, true);
			KvSetNum(g_hKvChatHud, "enabled", 1);
			Format(Buffer_Temp, sizeof(Buffer_Temp), "{red}[Console] {yellow}► {green}%s {yellow}◄", RemoveItens(s_ConsoleChat));
			KvSetString(g_hKvChatHud, "default", Buffer_Temp);
			Format(Buffer_Temp, sizeof(Buffer_Temp), "► %s ◄", RemoveItens(s_ConsoleChat));
			if(b_IsCountable) KvSetString(g_hKvChatHud, "ChatHud", Buffer_Temp);
			KvRewind(g_hKvChatHud);
			KeyValuesToFile(g_hKvChatHud, g_sPathChatHud);
			KvRewind(g_hKvChatHudAdmin);
			KvCopySubkeys(g_hKvChatHud, g_hKvChatHudAdmin);
			KvJumpToKey(g_hKvChatHud, s_ConsoleChat);
		}
		if (KvGetNum(g_hKvChatHud, "enabled") <= 0)
		{
			KvRewind(g_hKvChatHud);
			return Plugin_Stop;
		}
		if(!g_bChatHud)
		{
			KvRewind(g_hKvChatHud);
			return Plugin_Continue;
		}
		if(b_IsCountable && !CheckString(s_ConsoleChat))
		{
			KvGetString(g_hKvChatHud, "ChatHud", s_PrintHud, sizeof(s_PrintHud), "HUDMISSING");
			if(!StrEqual(s_PrintHud, "HUDMISSING"))
			{
				if (g_ihudAB == 1)
				{
				g_iNumberA = i_ConsoleNumber;
				g_iONumberA = i_ConsoleNumber;
				}
				else
				{
				g_iNumberB = i_ConsoleNumber;
				g_iONumberB = i_ConsoleNumber;
				}
				InitCountDown(s_PrintHud);
			}
			b_IsCountable = false;
		}

		KvGetString(g_hKvChatHud, "sound", s_Soundp, sizeof(s_Soundp), "default");
		
		if(StrEqual(s_Soundp, "default")) Format(s_Soundt, sizeof(s_Soundt), "common/talk.wav");
		else Format(s_Soundt, sizeof(s_Soundt), s_Soundp);

		for(int i = 1 ; i < MaxClients; i++)
		{
			if(IsValidClient(i) && ChatHudClientEnum[i].e_bChatMap)
			{
				KvGetString(g_hKvChatHud, g_sClLang[i], s_PrintText, sizeof(s_PrintText), "LANGMISSING");
				if(StrEqual(s_PrintText, "LANGMISSING")) KvGetString(g_hKvChatHud, "default", s_PrintText, sizeof(s_PrintText), "TEXTMISSING");
				if(!StrEqual(s_PrintText, "TEXTMISSING")) CPrintToChat(i, s_PrintText);
			}
		}
		if(!StrEqual(s_Soundp, "none"))
		{
			for(int i = 1 ; i < MaxClients; i++)
			{
				if(IsValidClient(i) && ChatHudClientEnum[i].e_bChatSound && ChatHudClientEnum[i].e_bChatMap)
				{
					EmitSoundToClient(i, s_Soundt, _, SNDCHAN_AUTO);
				}
			}
		}
		if(KvJumpToKey(g_hKvChatHud, "hinttext"))
		{
			for(int i = 1 ; i < MaxClients; i++)
				if(IsValidClient(i) && ChatHudClientEnum[i].e_bChatHud)
				{
					KvGetString(g_hKvChatHud, g_sClLang[i], s_PrintText, sizeof(s_PrintText), "LANGMISSING");
					if(StrEqual(s_PrintText, "LANGMISSING")) KvGetString(g_hKvChatHud, "default", s_PrintText, sizeof(s_PrintText), "TEXTMISSING");
					if(!StrEqual(s_PrintText, "TEXTMISSING")) PrintHintText(i, s_PrintText);
				}
		}
		KvRewind(g_hKvChatHud);
		return Plugin_Stop;
	}

	if(!IsValidClient(client) || g_iItemSettings[client] == 0)
	{
		return Plugin_Continue;
	}

	char Args[MAX_TEXT_LENGTH];
	Format(Args, sizeof(Args), sArgs);
	StripQuotes(Args);

	if(StrEqual(sArgs, "!cancel") || StrContains(command, "say") <= -1 || StrContains(command, "say_team") <= -1)
	{
		CPrintToChat(client, "%t", "Cancel");
		if (g_iItemSettings[client] == 1) MenuClientChud(client);
		g_iItemSettings[client] = 0;
		return Plugin_Stop;
	}
	else if (!g_bChatHud)
	{
		return Plugin_Continue;
	}
	else if (g_iItemSettings[client] == 1)
	{
		ChatHudClientEnum[client].e_bHudPosition = Args;
		g_iItemSettings[client] = 0;
		ChatHudStringPos(client);
		SetClientCookie(client, g_hHudPosition, ChatHudClientEnum[client].e_bHudPosition);
		MenuClientChud(client);
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

public bool CharEqual(int a, int b)
{
	if(a == b || a == CharToLower(b) || a == CharToUpper(b))
	{
		return true;
	}
	return false;
}

public int StringEnder(char[] a, int b, int c)
{
	if(CharEqual(a[b], 'c'))
	{
		a[c - 3] = '\0';
	}
	else
	{
		a[c - 1] = '\0';
	}
	return StringToInt(a);
}

public void InitCountDown(char[] text)
{
	if (g_ihudAB == 1)
	{
		if(g_hTimerHandleA != INVALID_HANDLE)
		{
			KillTimer(g_hTimerHandleA);
			g_hTimerHandleA = INVALID_HANDLE;
		}

		DataPack TimerPackA;
		g_hTimerHandleA = CreateDataTimer(1.0, RepeatMSGA, TimerPackA, TIMER_REPEAT);
		TimerPackA.WriteString(text);
		g_ihudAB = 2;

		for (int i = 1; i <= MAXPLAYERS + 1; i++)
		{
			if(IsValidClient(i))
			{
				SendHudMsgA(i, text);
			}
		}
	}
	else 
	{
		if(g_hTimerHandleB != INVALID_HANDLE)
		{
			KillTimer(g_hTimerHandleB);
			g_hTimerHandleB = INVALID_HANDLE;
		}

		DataPack TimerPackB;
		g_hTimerHandleB = CreateDataTimer(1.0, RepeatMSGB, TimerPackB, TIMER_REPEAT);
		TimerPackB.WriteString(text);
		g_ihudAB = 1;

		for (int i = 1; i <= MAXPLAYERS + 1; i++)
		{
			if(IsValidClient(i))
			{
				SendHudMsgB(i, text);
			}
		}
	}
}

public Action RepeatMSGA(Handle timer, Handle h_PackA)
{
	g_iNumberA--;
	if(g_iNumberA <= 0)
	{
		DeleteTimer("A");
		g_icolor_hudA = 0;
		for (int i = 1; i <= MAXPLAYERS + 1; i++)
		{
			if(IsValidClient(i))
			{
				ClearSyncHud(i, g_hHudSyncA);
				if(ChatHudClientEnum[i].e_bChatHud && ChatHudClientEnum[i].e_bHudSound)
				{
					EmitSoundToClient(i, "common/stuck1.wav", _, SNDCHAN_AUTO, SNDLEVEL_LIBRARY);
				}
			}
		}
		return Plugin_Handled;
	}
	
	char string[MAXLENGTH_INPUT + 10], sNumber[8], sONumber[8];
	ResetPack(h_PackA);
	ReadPackString(h_PackA, string, sizeof(string));

	IntToString(g_iONumberA, sONumber, sizeof(sONumber));
	IntToString(g_iNumberA, sNumber, sizeof(sNumber));

	ReplaceString(string, sizeof(string), sONumber, sNumber);

	for (int i = 1; i <= MAXPLAYERS + 1; i++)
	{
		if(IsValidClient(i))
		{
			SendHudMsgA(i, string);
		}
	}
	return Plugin_Handled;
}

public Action RepeatMSGB(Handle timer, Handle h_PackB)
{
	g_iNumberB--;
	if(g_iNumberB <= 0)
	{
		DeleteTimer("B");
		g_icolor_hudB = 0;
		for (int i = 1; i <= MAXPLAYERS + 1; i++)
		{
			if(IsValidClient(i))
			{
				ClearSyncHud(i, g_hHudSyncB);
				if(ChatHudClientEnum[i].e_bChatHud && ChatHudClientEnum[i].e_bHudSound)
				{
					EmitSoundToClient(i, "common/stuck1.wav", _, SNDCHAN_AUTO, SNDLEVEL_LIBRARY);
				}
			}
		}
		return Plugin_Handled;
	}
	
	char string[MAXLENGTH_INPUT + 10], sNumber[8], sONumber[8];
	ResetPack(h_PackB);
	ReadPackString(h_PackB, string, sizeof(string));

	IntToString(g_iONumberB, sONumber, sizeof(sONumber));
	IntToString(g_iNumberB, sNumber, sizeof(sNumber));

	ReplaceString(string, sizeof(string), sONumber, sNumber);

	for (int i = 1; i <= MAXPLAYERS + 1; i++)
	{
		if(IsValidClient(i))
		{
			SendHudMsgB(i, string);
		}
	}
	return Plugin_Handled;
}

public void SendHudMsgA(int client, char[] szMessage)
{
	if (ChatHudClientEnum[client].e_bChatHud)
	{
		if(g_icolor_hudA == 0 && g_iNumberA > g_fColor_Time) SetHudTextParams(g_fHudPosA[client][0], g_fHudPosA[client][1], 1.0, g_iHudColor1[0], g_iHudColor1[1], g_iHudColor1[2], 255, 2, 0.1, 0.02, 0.1);
		if(g_icolor_hudA >= 1 && g_iNumberA > g_fColor_Time) SetHudTextParams(g_fHudPosA[client][0], g_fHudPosA[client][1], 1.0, g_iHudColor1[0], g_iHudColor1[1], g_iHudColor1[2], 255, 0, 0.0, 0.0, 0.0);
		if(g_icolor_hudA > 0  && g_iNumberA <= g_fColor_Time) SetHudTextParams(g_fHudPosA[client][0], g_fHudPosA[client][1], 1.0, g_iHudColor2[0], g_iHudColor2[1], g_iHudColor2[2], 255, 0, 0.0, 0.0, 0.0);
		ShowSyncHudText(client, g_hHudSyncA, szMessage);
	}

	g_icolor_hudA++;
	if(g_iNumberA <= 0) g_icolor_hudA = 0;
}

public void SendHudMsgB(int client, char[] szMessage)
{
	if (ChatHudClientEnum[client].e_bChatHud)
	{
		if(g_icolor_hudB == 0 && g_iNumberB > g_fColor_Time) SetHudTextParams(g_fHudPosB[client][0], g_fHudPosB[client][1], 1.0, g_iHudColor1[0], g_iHudColor1[1], g_iHudColor1[2], 255, 2, 0.2, 0.01, 0.1);
		if(g_icolor_hudB >= 1 && g_iNumberB > g_fColor_Time) SetHudTextParams(g_fHudPosB[client][0], g_fHudPosB[client][1], 1.0, g_iHudColor1[0], g_iHudColor1[1], g_iHudColor1[2], 255, 0, 0.0, 0.0, 0.0);
		if(g_icolor_hudB > 0  && g_iNumberB <= g_fColor_Time) SetHudTextParams(g_fHudPosB[client][0], g_fHudPosB[client][1], 1.0, g_iHudColor2[0], g_iHudColor2[1], g_iHudColor2[2], 255, 0, 0.0, 0.0, 0.0);
		ShowSyncHudText(client, g_hHudSyncB, szMessage);
	}
	g_icolor_hudB++;
	if(g_iNumberB <= 0) g_icolor_hudB = 0;
}

stock bool IsValidClient(int client, bool bzrAllowBots = false, bool bzrAllowDead = true)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bzrAllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!bzrAllowDead && !IsPlayerAlive(client)))
		return false;
	return true;
}

public bool IsValidGenericAdmin(int client) 
{ 
	return CheckCommandAccess(client, "generic_admin", ADMFLAG_GENERIC, false);
}

stock char RemoveItens(const char[] s_Format, any...) 
{
	char s_Text[MAXLENGTH_INPUT];
	VFormat(s_Text, sizeof(s_Text), s_Format, 2);
	/* Removes itens */
	char s_RemoveItens[][] = {"#", ">", "<", "*", "-", "_", "=", "+"};
	for(int i_Itens = 0; i_Itens < sizeof(s_RemoveItens); i_Itens++ ) {
		ReplaceString(s_Text, sizeof(s_Text), s_RemoveItens[i_Itens], "", false);
	}
	return s_Text;
}

stock char RemoveColors(const char[] s_Format, any...) 
{
	char s_Text[MAXLENGTH_INPUT];
	VFormat(s_Text, sizeof(s_Text), s_Format, 2);
	/* Removes colors */
	char s_RemoveColor[][] = {"{yellow}", "{default}", "{darkred}", "{green}", "{lightgreen}", "{red}", "{blue}", "{olive}", "{lime}", "{lightred}", "{purple}", "{grey}", "{orange}", "{bluegrey}", "{lightblue}", "{darkblue}", "{grey2}", "{orchid}", "{lightred2}"};
	for(int i_Color = 0; i_Color < sizeof(s_RemoveColor); i_Color++ ) {
		ReplaceString(s_Text, sizeof(s_Text), s_RemoveColor[i_Color], "", false);
	}
	return s_Text;
}