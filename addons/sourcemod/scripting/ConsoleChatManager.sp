/*  Console Chat Manager
 *
 *  Copyright (C) 2020 maxime1907
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

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include <geoip>
#include <emitsoundany>

#pragma newdecls required

#define VERSION 			"2.1"

#define MAXLENGTH_INPUT		512

#define NORMALHUD 1
#define CSGO_WARMUPTIMER 2

Handle kv;
char Path[PLATFORM_MAX_PATH];

char lastMessage[MAXLENGTH_INPUT] = "";

ConVar g_ConsoleMessage;
ConVar g_cBlockSpam;
ConVar g_cBlockSpamDelay;
ConVar g_EnableTranslation;
ConVar g_EnableHud;
ConVar g_cHudPosition;
ConVar g_cHudColor;
ConVar g_cHudSymbols;
ConVar g_cHudDuration;
ConVar g_cHudDurationFadeOut;
ConVar g_cHudType;
ConVar g_cHudHtmlColor;

float HudPos[2];
int HudColor[3];
bool HudSymbols;

int number, onumber;
Handle timerHandle, HudSync;

char Blacklist[][] = {
	"recharge", "recast", "cooldown", "cool"
};

bool isCSGO;

int lastMessageTime = -1;

int roundStartedTime = -1;

int hudtype;

char htmlcolor[64];

public Plugin myinfo = 
{
	name = "ConsoleChatManager",
	author = "Franc1sco Steam: franug, maxime1907, inGame, AntiTeal, Oylsister",
	description = "Interact with console messages",
	version = VERSION,
	url = ""
};

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);

	DeleteTimer();
	HudSync = CreateHudSynchronizer();

	CreateConVar("sm_consolechatmanager_version", VERSION, "", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_ConsoleMessage = CreateConVar("sm_consolechatmanager_tag", "{green}[NARRATOR] {white}", "The tag that will be printed instead of the console default messages");

	g_EnableTranslation = CreateConVar("sm_consolechatmanager_translation", "0", "Enable translation of console chat messages. 1 = Enabled, 0 = Disabled");

	g_EnableHud = CreateConVar("sm_consolechatmanager_hud", "1", "Enables printing the console output in the middle of the screen");
	g_cHudDuration = CreateConVar("sm_consolechatmanager_hud_duration", "2.5", "How long the message stays");
	g_cHudDurationFadeOut = CreateConVar("sm_consolechatmanager_hud_duration_fadeout", "1.0", "How long the message takes to disapear");
	g_cHudPosition = CreateConVar("sm_consolechatmanager_hud_position", "-1.0 0.125", "The X and Y position for the hud.");
	g_cHudColor = CreateConVar("sm_consolechatmanager_hud_color", "0 255 0", "RGB color value for the hud.");
	g_cHudSymbols = CreateConVar("sm_consolechatmanager_hud_symbols", "1", "Determines whether >> and << are wrapped around the text.");
	g_cHudType = CreateConVar("sm_consolechatmanager_hud_type", "1.0", "Specify the type of Hud Msg [1 = SendTextHud, 2 = CS:GO Warmup Timer]", _, true, 1.0, true, 2.0);
	g_cHudHtmlColor = CreateConVar("sm_consolecharmanager_hud_htmlcolor", "#6CFF00", "Html color for second type of Hud Message");

	g_cBlockSpam = CreateConVar("sm_consolechatmanager_block_spam", "1", "Blocks console messages that repeat the same message.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cBlockSpamDelay = CreateConVar("sm_consolechatmanager_block_spam_delay", "1", "Time to wait before printing the same message", FCVAR_NONE, true, 1.0, true, 60.0);

	g_cHudPosition.AddChangeHook(OnConVarChanged);
	g_cHudColor.AddChangeHook(OnConVarChanged);
	g_cHudSymbols.AddChangeHook(OnConVarChanged);
	g_cHudType.AddChangeHook(OnConVarChanged);

	AddCommandListener(SayConsole, "say");

	AutoExecConfig(true);

	GetConVars();
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	isCSGO = (GetEngineVersion() == Engine_CSGO);
	return APLRes_Success;
}

public void OnMapStart()
{
	if (g_EnableTranslation.BoolValue)
		ReadT();
}

public void OnConVarChanged(ConVar convar, char[] oldValue, char[] newValue)
{
	GetConVars();
}

public void Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	roundStartedTime = GetTime();
	DeleteTimer();
}

public int GetCurrentRoundTime()
{
	Handle hFreezeTime = FindConVar("mp_freezetime"); // Freezetime Handle
	int freezeTime = GetConVarInt(hFreezeTime); // Freezetime in seconds
	return GameRules_GetProp("m_iRoundTime") - ( (GetTime() - roundStartedTime) - freezeTime );
}

public int GetRoundTimeAtTimerEnd()
{
	return GetCurrentRoundTime() - number; 
}

public void DeleteTimer()
{
	if(timerHandle != INVALID_HANDLE)
	{
		KillTimer(timerHandle);
		timerHandle = INVALID_HANDLE;
	}
}

public void GetConVars()
{
	char StringPos[2][8];
	char PosValue[16];
	g_cHudPosition.GetString(PosValue, sizeof(PosValue));
	ExplodeString(PosValue, " ", StringPos, sizeof(StringPos), sizeof(StringPos[]));

	HudPos[0] = StringToFloat(StringPos[0]);
	HudPos[1] = StringToFloat(StringPos[1]);

	char ColorValue[64];
	g_cHudColor.GetString(ColorValue, sizeof(ColorValue));

	ColorStringToArray(ColorValue, HudColor);

	HudSymbols = g_cHudSymbols.BoolValue;

	hudtype = g_cHudType.IntValue;

	g_cHudHtmlColor.GetString(htmlcolor, sizeof(htmlcolor));
}

public void ColorStringToArray(const char[] sColorString, int aColor[3])
{
	char asColors[4][4];
	ExplodeString(sColorString, " ", asColors, sizeof(asColors), sizeof(asColors[]));

	aColor[0] = StringToInt(asColors[0]);
	aColor[1] = StringToInt(asColors[1]);
	aColor[2] = StringToInt(asColors[2]);
}

public void ReadT()
{
	delete kv;

	char map[64];
	GetCurrentMap(map, sizeof(map));
	BuildPath(Path_SM, Path, sizeof(Path), "configs/consolechatmanager/%s.txt", map);

	kv = CreateKeyValues("Console_C");

	if(!FileExists(Path)) KeyValuesToFile(kv, Path);
	else FileToKeyValues(kv, Path);
	
	CheckSounds();
}

void CheckSounds()
{
	PrecacheSound("common/talk.wav", false);

	char buffer[255];
	if(KvGotoFirstSubKey(kv))
	{
		do
		{
			KvGetString(kv, "sound", buffer, 64, "default");
			if(!StrEqual(buffer, "default"))
			{
				if(!isCSGO) PrecacheSound(buffer);
				else PrecacheSoundAny(buffer);
				
				Format(buffer, 255, "sound/%s", buffer);
				AddFileToDownloadsTable(buffer);
			}
			
		} while (KvGotoNextKey(kv));
	}

	KvRewind(kv);
}

public bool CheckString(const char[] string)
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

public bool IsCountable(const char sMessage[MAXLENGTH_INPUT])
{
	char FilterText[sizeof(sMessage)+1], ChatArray[32][MAXLENGTH_INPUT];
	int consoleNumber, filterPos;
	bool isCountable = false;

	for (int i = 0; i < sizeof(sMessage); i++)
	{
		if (IsCharAlpha(sMessage[i]) || IsCharNumeric(sMessage[i]) || IsCharSpace(sMessage[i]))
		{
			FilterText[filterPos++] = sMessage[i];
		}
	}
	FilterText[filterPos] = '\0';
	TrimString(FilterText);

	if(CheckString(sMessage))
		return isCountable;

	int words = ExplodeString(FilterText, " ", ChatArray, sizeof(ChatArray), sizeof(ChatArray[]));

	if(words == 1)
	{
		if(StringToInt(ChatArray[0]) != 0)
		{
			isCountable = true;
			consoleNumber = StringToInt(ChatArray[0]);
		}
	}

	for(int i = 0; i <= words; i++)
	{
		if(StringToInt(ChatArray[i]) != 0)
		{
			if(i + 1 <= words && (StrEqual(ChatArray[i + 1], "s", false) || (CharEqual(ChatArray[i + 1][0], 's') && CharEqual(ChatArray[i + 1][1], 'e'))))
			{
				consoleNumber = StringToInt(ChatArray[i]);
				isCountable = true;
			}
			if(!isCountable && i + 2 <= words && (StrEqual(ChatArray[i + 2], "s", false) || (CharEqual(ChatArray[i + 2][0], 's') && CharEqual(ChatArray[i + 2][1], 'e'))))
			{
				consoleNumber = StringToInt(ChatArray[i]);
				isCountable = true;
			}
		}
		if(!isCountable)
		{
			char word[MAXLENGTH_INPUT];
			strcopy(word, sizeof(word), ChatArray[i]);
			int len = strlen(word);

			if(IsCharNumeric(word[0]))
			{
				if(IsCharNumeric(word[1]))
				{
					if(IsCharNumeric(word[2]))
					{
						if(CharEqual(word[3], 's'))
						{
							consoleNumber = StringEnder(word, 5, len);
							isCountable = true;
						}
					}
					else if(CharEqual(word[2], 's'))
					{
						consoleNumber = StringEnder(word, 4, len);
						isCountable = true;
					}
				}
				else if(CharEqual(word[1], 's'))
				{
					consoleNumber = StringEnder(word, 3, len);
					isCountable = true;
				}
			}
		}
		if(isCountable)
		{
			number = consoleNumber;
			onumber = consoleNumber;
			break;
		}
	}
	return isCountable;
}

public Action SayConsole(int client, const char[] command, int args)
{
	if (client)
		return Plugin_Continue;

	char sText[MAXLENGTH_INPUT];
	GetCmdArgString(sText, sizeof(sText));
	StripQuotes(sText);

	if (g_cBlockSpam.BoolValue)
	{
		int currentTime = GetTime();
		if (StrEqual(sText, lastMessage, true))
		{
			if (lastMessageTime != -1 && ((currentTime - lastMessageTime) <= g_cBlockSpamDelay.IntValue))
			{
				lastMessage = sText;
				lastMessageTime = currentTime;
				return Plugin_Handled;
			}
		}
		lastMessage = sText;
		lastMessageTime = currentTime;
	}

	char soundp[255], soundt[255];
	if (g_EnableTranslation.BoolValue)
	{
		if(kv == INVALID_HANDLE)
		{
			ReadT();
		}

		if(!KvJumpToKey(kv, sText))
		{
			KvJumpToKey(kv, sText, true);
			KvSetString(kv, "default", sText);
			KvRewind(kv);
			KeyValuesToFile(kv, Path);
			KvJumpToKey(kv, sText);
		}

		bool blocked = (KvGetNum(kv, "blocked", 0)?true:false);

		if(blocked)
		{
			KvRewind(kv);
			return Plugin_Handled;
		}

		KvGetString(kv, "sound", soundp, sizeof(soundp), "default");
		if(StrEqual(soundp, "default"))
			Format(soundt, 255, "common/talk.wav");
		else
			Format(soundt, 255, soundp);
	}

	char sFinalText[1024];
	char sConsoleTag[255];
	char sCountryTag[3];
	char sIP[26];
	bool isCountable = IsCountable(sText);

	g_ConsoleMessage.GetString(sConsoleTag, sizeof(sConsoleTag));

	if (g_EnableHud.BoolValue && isCountable)
		InitCountDown(sText);

	for(int i = 1 ; i < MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if (g_EnableTranslation.BoolValue)
			{
				GetClientIP(i, sIP, sizeof(sIP));
				GeoipCode2(sIP, sCountryTag);
				KvGetString(kv, sCountryTag, sText, sizeof(sText), "LANGMISSING");

				if (StrEqual(sText, "LANGMISSING")) KvGetString(kv, "default", sText, sizeof(sText));
			}

			Format(sFinalText, sizeof(sFinalText), "%s%s", sConsoleTag, sText);

			if(isCountable && GetRoundTimeAtTimerEnd() > 0)
			{
				float fMinutes = GetRoundTimeAtTimerEnd() / 60.0;
				int minutes = RoundToFloor(fMinutes);
				int seconds = GetRoundTimeAtTimerEnd() - minutes * 60;
				char roundTimeText[32];

				Format(roundTimeText, sizeof(roundTimeText), " {orange}@ %i:%s%i", minutes, (seconds < 10 ? "0" : ""), seconds);
				Format(sFinalText, sizeof(sFinalText), "%s%s", sFinalText, roundTimeText);
			}

			CPrintToChat(i, sFinalText);

			if (g_EnableHud.BoolValue && !isCountable)
			{
				if(isCSGO)
				{
					if(hudtype == NORMALHUD)
						SendHudMsg(i, sText, false);

					else
						SendNewHudMsg(i, sText, false);
				}
				else
					SendHudMsg(i, sText, false);
			}
		}
	}

	if (g_EnableTranslation.BoolValue)
	{
		if(!StrEqual(soundp, "none"))
		{
			if(!isCSGO || StrEqual(soundp, "default")) EmitSoundToAll(soundt);
			else EmitSoundToAllAny(soundt);
		}

		if(KvJumpToKey(kv, "hinttext"))
		{
			for(int i = 1 ; i < MaxClients; i++)
				if(IsClientInGame(i))
				{
					GetClientIP(i, sIP, sizeof(sIP));
					GeoipCode2(sIP, sCountryTag);
					KvGetString(kv, sCountryTag, sText, sizeof(sText), "LANGMISSING");

					if (StrEqual(sText, "LANGMISSING")) KvGetString(kv, "default", sText, sizeof(sText));
				
					PrintHintText(i, sText);
				}
		}

		KvRewind(kv);
	}
	return Plugin_Handled;
}

bool IsValidClient(int client, bool nobots = true)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
	{
		return false;
	}
	return IsClientInGame(client);
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

public void InitCountDown(const char[] text)
{
	if(timerHandle != INVALID_HANDLE)
	{
		KillTimer(timerHandle);
		timerHandle = INVALID_HANDLE;
	}

	DataPack TimerPack;
	timerHandle = CreateDataTimer(1.0, RepeatMsg, TimerPack, TIMER_REPEAT);

	char text2[MAXLENGTH_INPUT + 10];
	if	(HudSymbols && hudtype == NORMALHUD)
		Format(text2, sizeof(text2), ">> %s <<", text);
	else
		Format(text2, sizeof(text2), "%s", text);

	TimerPack.WriteString(text2);

	for (int i = 1; i <= MAXPLAYERS + 1; i++)
	{
		if(isCSGO)
		{
			if(hudtype == NORMALHUD)
				SendHudMsg(i, text2, true);
			
			else
				SendNewHudMsg(i, text2, true);
		}
		else
			SendHudMsg(i, text2, true);
	}
}

public Action RepeatMsg(Handle timer, Handle pack)
{
	number--;
	if (number <= 0)
	{
		DeleteTimer();
		for (int i = 1; i <= MAXPLAYERS + 1; i++)
		{
			if(IsValidClient(i))
			{
				ClearSyncHud(i, HudSync);
			}
		}
		return Plugin_Handled;
	}

	char string[MAXLENGTH_INPUT + 10], sNumber[8], sONumber[8];

	ResetPack(pack);
	ReadPackString(pack, string, sizeof(string));

	IntToString(onumber, sONumber, sizeof(sONumber));
	IntToString(number, sNumber, sizeof(sNumber));

	ReplaceString(string, sizeof(string), sONumber, sNumber);

	for (int i = 1; i <= MAXPLAYERS + 1; i++)
	{
		if(isCSGO)
		{
			if(hudtype == NORMALHUD)
				SendHudMsg(i, string, true);

			else
				SendNewHudMsg(i, string, true);
		}
		else
			SendHudMsg(i, string, true);
	}
	return Plugin_Handled;
}

public void SendHudMsg(int client, const char[] szMessage, bool isCountdown)
{
	if (!IsValidClient(client))
		return;
	float duration = isCountdown ? 1.0 : g_cHudDuration.FloatValue;
	SetHudTextParams(HudPos[0], HudPos[1], duration, HudColor[0], HudColor[1], HudColor[2], 255, 0, 0.0, 0.0, g_cHudDurationFadeOut.FloatValue);
	ShowSyncHudText(client, HudSync, szMessage);
}

public void SendNewHudMsg(int client, const char[] szMessage, bool isCountdown)
{
	if (!IsValidClient(client))
		return;

	// if it's not csgo engine, then return
	if (!isCSGO)
		return;

	// Event use int for duration
	int duration = isCountdown ? 2 : RoundToNearest(g_cHudDuration.FloatValue);

	// We don't want to mess with original constant char
	char originalmsg[MAX_BUFFER_LENGTH + 10];
	Format(originalmsg, sizeof(originalmsg), "%s", szMessage);

	int orilen = strlen(originalmsg);

	// Need to remove These Html symbol from console message or it will get messy.
	ReplaceString(originalmsg, orilen, "<", "", false);
	ReplaceString(originalmsg, orilen, ">", "", false);

	// Put color in to the message
	char newmessage[MAX_BUFFER_LENGTH + 10];
	int newlen = strlen(newmessage);

	// If the message is too long we need to reduce font size.
	if(newlen <= 65)

		// Put color in to the message (These html format is fine)
		Format(newmessage, sizeof(newmessage), "<span class='fontSize-l'><span color='%s'>%s</span></span>", htmlcolor, originalmsg);

	else if(newlen <= 100)
		Format(newmessage, sizeof(newmessage), "<span class='fontSize-m'><span color='%s'>%s</span></span>", htmlcolor, originalmsg);

	else
		Format(newmessage, sizeof(newmessage), "<span class='fontSize-sm'><span color='%s'>%s</span></span>", htmlcolor, originalmsg);
	
	// Fire the message to player (https://github.com/Kxnrl/CSGO-HtmlHud/blob/main/fys.huds.sp#L167)
	Event event = CreateEvent("show_survival_respawn_status");
	if (event != null)
	{
		event.SetString("loc_token", newmessage);
		event.SetInt("duration", duration);
		event.SetInt("userid", -1);
		if(client == -1)
		{
			for(int i = 1; i <= MaxClients; i++) 
			{
				if(IsClientInGame(i) && !IsFakeClient(i))
				{
					event.FireToClient(i);
				}
			}
		}
		else
		{
			event.FireToClient(client);
		}
		event.Cancel(); 
	}
}
