#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <csgo_colors>
#include <geoip>
#include <emitsoundany>

#pragma newdecls required // let's go new syntax! 

#define MAXLENGTH_INPUT 		128
#define PLUGIN_VERSION 		"1.1-B"

int color_hudA = 0;
int color_hudB = 0;
int number, onumber, number2, onumber2, hudAB;
Handle timerHandle1 = INVALID_HANDLE, timerHandle2 = INVALID_HANDLE, HudSyncA, HudSyncB ,kv;
char Path[PLATFORM_MAX_PATH];

public Plugin myinfo = 
{
	name = "ChatHud_Translator",
	author = "Anúbis",
	description = "Countdown timers & Chat Translator based on messages from maps.Based Progect Franug & Antiteal",
	version = PLUGIN_VERSION,
	url = ""
}

ConVar g_cVHudPositionA, g_cVHudPositionB, g_cVHudColor1, g_cVHudColor2, g_cVHudSymbols, g_changecolor;

float HudPosA[2], HudPosB[2], Color_Time;
int HudColor1[3];
int HudColor2[3];
bool HudSymbols;
bool csgo;

public void OnPluginStart()
{
	CreateConVar("sm_chathud_version", PLUGIN_VERSION, "ChatHud_Translator Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	//AddCommandListener(Chat, "say");
	RegConsoleCmd("say", SayConsole);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);

	DeleteTimerA();
	DeleteTimerB();
	HudSyncA = CreateHudSynchronizer();
	HudSyncB = CreateHudSynchronizer();
	hudAB = 1;
	g_cVHudPositionA = CreateConVar("sm_chathud_1_position", "-1.0 0.100", "The X and Y position for the hud 1.");
	g_cVHudPositionB = CreateConVar("sm_chathud_2_position", "-1.0 0.125", "The X and Y position for the hud 2.");
	g_cVHudColor1 = CreateConVar("sm_chathud_color_1", "0 255 0", "RGB color value for the hud Start.");
	g_cVHudColor2 = CreateConVar("sm_chathud_color_2", "255 0 0", "RGB color value for the hud Finish.");
	g_cVHudSymbols = CreateConVar("sm_chathud_symbols", "0", "Determines whether >> and << are wrapped around the text.");
	g_changecolor = CreateConVar("sm_chathud_time_changecolor", "3", "Set the final time for Hud to change colors.");

	g_cVHudPositionA.AddChangeHook(ConVarChange);
	g_cVHudPositionB.AddChangeHook(ConVarChange);
	g_cVHudColor1.AddChangeHook(ConVarChange);
	g_cVHudColor2.AddChangeHook(ConVarChange);
	g_cVHudSymbols.AddChangeHook(ConVarChange);
	g_changecolor.AddChangeHook(ConVarChange);

	AutoExecConfig(true, "chathud");
	GetConVars();
}

public APLRes AskPluginLoad2(Handle myself, bool late, char [] error, int err_max)
{
	if(GetEngineVersion() == Engine_CSGO)
	{
		csgo = true;
	} else csgo = false;
	
	return APLRes_Success;
}

public void OnMapStart()
{
	ReadT();
	hudAB = 1;
}

public void ReadT()
{
	delete kv;
	
	char map[64];
	GetCurrentMap(map, sizeof(map));
	BuildPath(Path_SM, Path, sizeof(Path), "configs/chathud_translator/%s.txt", map);
	
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
				if(!csgo) PrecacheSound(buffer);
				else PrecacheSoundAny(buffer);
				
				Format(buffer, 255, "sound/%s", buffer);
				AddFileToDownloadsTable(buffer);
			}
			
		} while (KvGotoNextKey(kv));
	}
	
	KvRewind(kv);
}

public void ColorStringToArray(const char[] sColorString, int aColor[3])
{
	char asColors[4][4];
	ExplodeString(sColorString, " ", asColors, sizeof(asColors), sizeof(asColors[]));

	aColor[0] = StringToInt(asColors[0]);
	aColor[1] = StringToInt(asColors[1]);
	aColor[2] = StringToInt(asColors[2]);
}

public void GetConVars()
{
	char StringPosA[2][8];
	char StringPosB[2][8];
	char PosValueA[16];
	char PosValueB[16];
	g_cVHudPositionA.GetString(PosValueA, sizeof(PosValueA));
	g_cVHudPositionB.GetString(PosValueB, sizeof(PosValueB));
	ExplodeString(PosValueA, " ", StringPosA, sizeof(StringPosA), sizeof(StringPosA[]));
	ExplodeString(PosValueB, " ", StringPosB, sizeof(StringPosB), sizeof(StringPosB[]));

	HudPosA[0] = StringToFloat(StringPosA[0]);
	HudPosA[1] = StringToFloat(StringPosA[1]);
	HudPosB[0] = StringToFloat(StringPosB[0]);
	HudPosB[1] = StringToFloat(StringPosB[1]);

	char ColorValue1[64];
	char ColorValue2[64];
	g_cVHudColor1.GetString(ColorValue1, sizeof(ColorValue1));
	g_cVHudColor2.GetString(ColorValue2, sizeof(ColorValue2));

	ColorStringToArray(ColorValue1, HudColor1);
	ColorStringToArray(ColorValue2, HudColor2);

	HudSymbols = g_cVHudSymbols.BoolValue;
	Color_Time = g_changecolor.FloatValue;
}

public void ConVarChange(ConVar convar, char[] oldValue, char[] newValue)
{
	GetConVars();
}

public void Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	DeleteTimerA();
	DeleteTimerB();
}

public void Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	DeleteTimerA();
	DeleteTimerB();
}

public void DeleteTimerA()
{
	if(timerHandle1 != INVALID_HANDLE)
	{
		KillTimer(timerHandle1);
		timerHandle1 = INVALID_HANDLE;
	}
}

public void DeleteTimerB()
{
	if(timerHandle2 != INVALID_HANDLE)
	{
		KillTimer(timerHandle2);
		timerHandle2 = INVALID_HANDLE;
	}
}

//public Action Chat(int client, const char[] command, int argc)
public Action SayConsole(int client, int args)
{
	if(client)
	{
		return Plugin_Continue;
	}

	char ConsoleChat[MAXLENGTH_INPUT], FilterText[sizeof(ConsoleChat)+1], ChatArray[32][MAXLENGTH_INPUT];
	int consoleNumber, filterPos;
	bool blocked = (KvGetNum(kv, "blocked", 0)?true:false);
	bool isCountable;
	char buffer[255], buffer2[255], soundp[255], soundt[255];
	char sText[256];
	char hText[256];
	char sCountryTag[3];
	char sIP[26];
	
	GetCmdArgString(ConsoleChat, sizeof(ConsoleChat));
	StripQuotes(ConsoleChat);
	
	KvGetString(kv, "sound", soundp, sizeof(soundp), "default");
	if(StrEqual(soundp, "default"))
		Format(soundt, 255, "common/talk.wav");
	else
		Format(soundt, 255, soundp);
	
	if(kv == INVALID_HANDLE)
	{
		ReadT();
	}
	
	for (int i = 0; i < sizeof(ConsoleChat); i++) 
	{
		if (IsCharAlpha(ConsoleChat[i]) || IsCharNumeric(ConsoleChat[i]) || IsCharSpace(ConsoleChat[i])) 
		{
			FilterText[filterPos++] = ConsoleChat[i];
		}
	}
	
	FilterText[filterPos] = '\0';
	TrimString(FilterText);
	
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
	}

	if(blocked)
	{
		KvRewind(kv);
		return Plugin_Stop;
	}

	if(!KvJumpToKey(kv, ConsoleChat))
	{
		KvRewind(kv);
		KvJumpToKey(kv, ConsoleChat, true);
		Format(buffer, sizeof(buffer), "{red}Console: {green}%s", ConsoleChat);
		KvSetString(kv, "default", buffer);
		if(isCountable)
		{
			Format(buffer2, sizeof(buffer2), "%s", ConsoleChat);
			KvSetString(kv, "hud", buffer2);
		}
		KvRewind(kv);
		KeyValuesToFile(kv, Path);
		KvJumpToKey(kv, ConsoleChat);
	}

	if(!StrEqual(soundp, "none"))
	{
		if(!csgo || StrEqual(soundp, "default")) EmitSoundToAll(soundt);
		else EmitSoundToAllAny(soundt);
	}

	for(int j = 1 ; j < MaxClients; j++)
		if(IsClientInGame(j))
		{
			GetClientIP(j, sIP, sizeof(sIP));
			GeoipCode2(sIP, sCountryTag);
			KvGetString(kv, sCountryTag, sText, sizeof(sText), "LANGMISSING");

			if (StrEqual(sText, "LANGMISSING")) KvGetString(kv, "default", sText, sizeof(sText));
				
			CPrintToChat(j, sText);
		}

	if(KvJumpToKey(kv, "hinttext"))
	{
		for(int j = 1 ; j < MaxClients; j++)
			if(IsClientInGame(j))
			{
				GetClientIP(j, sIP, sizeof(sIP));
				GeoipCode2(sIP, sCountryTag);
				KvGetString(kv, sCountryTag, sText, sizeof(sText), "LANGMISSING");

				if (StrEqual(sText, "LANGMISSING")) KvGetString(kv, "default", sText, sizeof(sText));
				
				PrintHintText(j, sText);
			}
	}

	if(isCountable)
	{
		if(hudAB == 1)
		{
			KvGetString(kv, "hud", hText, sizeof(hText), "default");

			number = consoleNumber;
			onumber = consoleNumber;
			InitCountDownA(hText);
			KvRewind(kv);
			return Plugin_Handled;
		}
		if(hudAB == 2)
		{
			KvGetString(kv, "hud", hText, sizeof(hText), "default");

			number2 = consoleNumber;
			onumber2 = consoleNumber;
			InitCountDownB(hText);
			KvRewind(kv);
			return Plugin_Handled;
		}
	}
	KvRewind(kv);
	return Plugin_Handled;
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

public void InitCountDownA(char[] text)
{
	if(timerHandle1 != INVALID_HANDLE)
	{
		KillTimer(timerHandle1);
		timerHandle1 = INVALID_HANDLE;
	}

	DataPack TimerPack;
	timerHandle1 = CreateDataTimer(1.0, RepeatMSGA, TimerPack, TIMER_REPEAT);
	char text2[MAXLENGTH_INPUT + 10];
	if(HudSymbols)
	{
		Format(text2, sizeof(text2), ">> %s <<", text);
	}
	else
	{
		Format(text2, sizeof(text2), "%s", text);
	}

	TimerPack.WriteString(text2);

	for (int i = 1; i <= MAXPLAYERS + 1; i++)
	{
		if(IsValidClient(i))
		{
			hudAB = 2;
			SendHudMsgA(i, text2);
		}
	}
}

public Action RepeatMSGA(Handle timer, Handle pack)
{
	number--;
	if(number <= 0)
	{
		DeleteTimerA();
		color_hudA = 0;
		for (int i = 1; i <= MAXPLAYERS + 1; i++)
		{
			if(IsValidClient(i))
			{
				ClearSyncHud(i, HudSyncA);
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
		if(IsValidClient(i))
		{
			SendHudMsgA(i, string);
		}
	}
	return Plugin_Handled;
}

public void SendHudMsgA(int client, char[] szMessage)
{
	if(color_hudA == 0 && number > Color_Time) {
	SetHudTextParams(HudPosA[0], HudPosA[1], 1.0, HudColor1[0], HudColor1[1], HudColor1[2], 255, 2, 0.1, 0.02, 0.1);
	} if(color_hudA >= 1 && number > Color_Time) {
	SetHudTextParams(HudPosA[0], HudPosA[1], 1.0, HudColor1[0], HudColor1[1], HudColor1[2], 255, 0, 0.0, 0.0, 0.0);
	} if(color_hudA > 0  && number <= Color_Time) {
	SetHudTextParams(HudPosA[0], HudPosA[1], 1.0, HudColor2[0], HudColor2[1], HudColor2[2], 255, 0, 0.0, 0.0, 0.0);
	}
	color_hudA++;
	ShowSyncHudText(client, HudSyncA, szMessage);
	if(number <= 0) color_hudA = 0;
}

public void InitCountDownB(char[] text)
{
	if(timerHandle2 != INVALID_HANDLE)
	{
		KillTimer(timerHandle2);
		timerHandle2 = INVALID_HANDLE;
	}

	DataPack TimerPack;
	timerHandle2 = CreateDataTimer(1.0, RepeatMSGB, TimerPack, TIMER_REPEAT);
	char text2[MAXLENGTH_INPUT + 10];
	if(HudSymbols)
	{
		Format(text2, sizeof(text2), ">> %s <<", text);
	}
	else
	{
		Format(text2, sizeof(text2), "%s", text);
	}

	TimerPack.WriteString(text2);

	for (int i = 1; i <= MAXPLAYERS + 1; i++)
	{
		if(IsValidClient(i))
		{
			hudAB = 1;
			SendHudMsgB(i, text2);
		}
	}
}

public Action RepeatMSGB(Handle timer, Handle pack)
{
	number2--;
	if(number2 <= 0)
	{
		DeleteTimerB();
		color_hudB = 0;
		for (int i = 1; i <= MAXPLAYERS + 1; i++)
		{
			if(IsValidClient(i))
			{
				ClearSyncHud(i, HudSyncB);
			}
		}
		return Plugin_Handled;
	}
	
	char string[MAXLENGTH_INPUT + 10], sNumber[8], sONumber[8];
	ResetPack(pack);
	ReadPackString(pack, string, sizeof(string));

	IntToString(onumber2, sONumber, sizeof(sONumber));
	IntToString(number2, sNumber, sizeof(sNumber));

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

public void SendHudMsgB(int client, char[] szMessage)
{
	if(color_hudB == 0 && number2 > Color_Time) {
	SetHudTextParams(HudPosB[0], HudPosB[1], 1.0, HudColor1[0], HudColor1[1], HudColor1[2], 255, 2, 0.2, 0.01, 0.1);
	} if(color_hudB >= 1 && number2 > Color_Time) {
	SetHudTextParams(HudPosB[0], HudPosB[1], 1.0, HudColor1[0], HudColor1[1], HudColor1[2], 255, 0, 0.0, 0.0, 0.0);
	} if(color_hudB > 0  && number2 <= Color_Time) {
	SetHudTextParams(HudPosB[0], HudPosB[1], 1.0, HudColor2[0], HudColor2[1], HudColor2[2], 255, 0, 0.0, 0.0, 0.0);
	}
	color_hudB++;
	ShowSyncHudText(client, HudSyncB, szMessage);
	if(number2 <= 0) color_hudB = 0;
}

bool IsValidClient(int client, bool nobots = true)
{ 
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
	{
		return false; 
	}
	return IsClientInGame(client); 
}
