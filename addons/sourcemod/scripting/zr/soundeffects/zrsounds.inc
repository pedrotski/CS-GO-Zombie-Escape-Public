/*
 * ============================================================================
 *
 *  Zombie:Reloaded
 *
 *  File:		  zrsounds.inc
 *  Type:		  Core
 *  Description:   Zr Sounds Control.
 *
 *  Copyright (C) 2009-2013  Greyscale, Richard Helgeby
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 */

 /**
 * List of Handle used by the plugin.
 */

new Handle:g_CountDownCookie = INVALID_HANDLE;
new Handle:g_ZrSoundsCookie = INVALID_HANDLE;
new Handle:g_ZombiesECookie = INVALID_HANDLE;
new Handle:g_ZRoundEndCookie = INVALID_HANDLE;
float g_fClientVol[MAXPLAYERS + 1];

ZsoundsOnCommandsCreate()
{
	// Register ZSound command.
	RegConsoleCmd(SAYHOOKS_KEYWORD_ZSOUNDS, ZSoundsMenuCommand, "Opens ZR's main menu.");
}

public Action:ZSoundsMenuCommand(client, argc)
{
	// If client is console, then stop and tell them this feature is for players only.
	if (ZRIsConsole(client))
	{
		TranslationPrintToServer("Must be player");
		return Plugin_Handled;
	}
	
	// Send ZSounds menu.
	ZSoundsMenuMain(client);
	
	// This stops the "Unknown command" message in client's console.
	return Plugin_Handled;
}

ZrSoundsOnCookiesCreate()
{
	// Create cookie handle if it doesn't exist.
	if (g_CountDownCookie == INVALID_HANDLE)
	{
		g_CountDownCookie = RegClientCookie("zr_voice_count", "Select Voz CountDown.", CookieAccess_Protected);
	}
	if (g_ZrSoundsCookie == INVALID_HANDLE)
	{
		g_ZrSoundsCookie = RegClientCookie("zr_sounds", "Select Vol ZrSounds.", CookieAccess_Protected);
	}
	if (g_ZombiesECookie == INVALID_HANDLE)
	{
		g_ZombiesECookie = RegClientCookie("zr_zombies_sounds_enable", "Zombies sounds enable.", CookieAccess_Protected);
	}
	if (g_ZRoundEndCookie == INVALID_HANDLE)
	{
		g_ZRoundEndCookie = RegClientCookie("zr_roundend_sounds_enable", "RoundEnd sounds enable.", CookieAccess_Protected);
	}
}

ZrSoundsOnCookiesCached(client)
{
	// Get default client setting from cvar.
	new bool:zvcd = GetConVarBool(g_hCvarsList[CVAR_VOICECOUNT_DEFAULT]);
	new bool:zsed = GetConVarBool(g_hCvarsList[CVAR_ZOMBIES_SOUNDS_DEFAULT]);
	new bool:zrod = GetConVarBool(g_hCvarsList[CVAR_ROUNDEND_SOUNDS_DEFAULT]);

	// Get VOICECOUNT enabled cookie value.
	decl String:voiceselect[8];
	decl String:zombisounde[8];
	decl String:zroundende[8];
	GetClientCookie(client, g_CountDownCookie, voiceselect, sizeof(voiceselect));
	GetClientCookie(client, g_ZombiesECookie, zombisounde, sizeof(zombisounde));
	GetClientCookie(client, g_ZRoundEndCookie, zroundende, sizeof(zroundende));

	// If the cookie is empty, then set the default value.
	if (!voiceselect[0])
	{
		// Set cookie to default value from cvar.
		CookiesSetClientCookieBool(client, g_CountDownCookie, zvcd);
	}
	if (!zombisounde[0])
		{
		// Set cookie to default value from cvar.
		CookiesSetClientCookieBool(client, g_ZombiesECookie, zsed);
	}
	if (!zroundende[0])
		{
		// Set cookie to default value from cvar.
		CookiesSetClientCookieBool(client, g_ZRoundEndCookie, zrod);
	}
}

ZSoundsMenuMain(client)
{
	float Vol = GetClientVolume(client);
	g_fClientVol[client] = Vol;
	
	// Create menu handle.
	new Handle:zsounds_menu_main = CreateMenu(ZrSoundsMenuHandler);
	
	// Make client global translations target.
	SetGlobalTransTarget(client);
	
	decl String:title[MENU_LINE_TITLE_LENGTH];
	decl String:zombisounde[MENU_LINE_SMALL_LENGTH];
	decl String:zroundende[MENU_LINE_SMALL_LENGTH];
	decl String:soundzombi[MENU_LINE_REG_LENGTH];
	decl String:soundrend[MENU_LINE_REG_LENGTH];
	decl String:coundsound[MENU_LINE_REG_LENGTH];
	decl String:zrvolume[MENU_LINE_HUGE_LENGTH];
	
	// Get the current toggle state of the cookies.
	ConfigBoolToSetting(CookiesGetClientCookieBool(client, g_ZombiesECookie), zombisounde, sizeof(zombisounde), false, client);
	ConfigBoolToSetting(CookiesGetClientCookieBool(client, g_ZRoundEndCookie), zroundende, sizeof(zroundende), false, client);
	
	// Translate each line into client's language.
	Format(title, sizeof(title), "%t\n ", "zr sounds");
	Format(soundzombi, sizeof(soundzombi), "%t", "Zombies_Sounds", zombisounde);
	Format(soundrend, sizeof(soundrend), "%t", "RoundEnd_Sounds", zroundende);
	Format(zrvolume, sizeof(zrvolume), "%t %i%", "zr_volume", RoundFloat(g_fClientVol[client] * 100));
	
	// Get conditional values for each option.
	new bool:zsecvar = GetConVarBool(g_hCvarsList[CVAR_ZOMBIES_SOUNDS]);
	new bool:zrecvar = GetConVarBool(g_hCvarsList[CVAR_ROUNDEND_SOUNDS]);
	int cookievalue = GetIntCookie(client, g_CountDownCookie);
	
	//Menu Variavel
	if(cookievalue == 1)
	{
		Format(coundsound, sizeof(coundsound), "%t %t", "Select Countdown", "voz_1"); //mem
	}
	if(cookievalue == 2)
	{
		Format(coundsound, sizeof(coundsound), "%t %t", "Select Countdown", "voz_2"); //woman
	}
	if(cookievalue == 0)
	{
		Format(coundsound, sizeof(coundsound), "%t %t", "Select Countdown", "voz_3"); //disabled
	}
	
	// Add items to menu.
	SetMenuTitle(zsounds_menu_main, title);
	AddMenuItem(zsounds_menu_main, "soundzombi", soundzombi, MenuGetItemDraw(zsecvar));
	AddMenuItem(zsounds_menu_main, "soundrend", soundrend, MenuGetItemDraw(zrecvar));
	AddMenuItem(zsounds_menu_main, "zrvolume", zrvolume);
	AddMenuItem(zsounds_menu_main, "coundsound", coundsound);

	// Create a "Back" button to the main menu.
	SetMenuExitBackButton(zsounds_menu_main, true);
	
	// Display menu to client.
	DisplayMenu(zsounds_menu_main, client, MENU_TIME_FOREVER);	
	
	//SetMenuExitButton(g_CookieMenu, true);
	//DisplayMenu(g_CookieMenu, client, 30);
	//return Plugin_Continue;
}

public ZrSoundsMenuHandler(Handle:menu, MenuAction:action, client, slot)
{
	// Client selected an option.
	if (action == MenuAction_Select)
	{
		new bool:resend = true;
		
		switch(slot)
		{
			// Toggled 
			case 0:
			{
				// Toggle 
				ZSEToggle(client);
			}
			// Toggled
			case 1:
			{
				ZREToggle(client);
			}
			// Toggled
			case 2:
			{
				ZSoundsVolumeMenuMain(client);
				resend = false;
			}
			// Opened
			case 3:
			{
				CounToggle(client);
				//resend = false;
			}
		}
		
		if (resend)
		{
			// Re-send menu.
			ZSoundsMenuMain(client);
		}
	}
	// Client closed the menu.
	if (action == MenuAction_Cancel)
	{
		// Client hit "Back" button.
		if (slot == MenuCancel_ExitBack)
		{
			// Re-open main menu.
			ZMenuMain(client);
		}
	}
	// Client exited menu.
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

ZSoundsVolumeMenuMain(client)
{
	// Get Client Vol.
	float Vol = GetClientVolume(client);	
	g_fClientVol[client] = Vol;
	
	// Create menu handle.
	new Handle:Volume_Menu_Main = CreateMenu(VolumeMenuHandler);
	
	// Make client global translations target.
	SetGlobalTransTarget(client);
	
	decl String:volumemenutitle[MENU_LINE_TITLE_LENGTH];
	decl String:v100[MENU_LINE_SMALL_LENGTH];
	decl String:v75[MENU_LINE_SMALL_LENGTH];
	decl String:v50[MENU_LINE_SMALL_LENGTH];
	decl String:v25[MENU_LINE_SMALL_LENGTH];
	decl String:v10[MENU_LINE_SMALL_LENGTH];
	decl String:v05[MENU_LINE_SMALL_LENGTH];
	
		
	// Translate each line into client's language.
	Format(volumemenutitle, sizeof(volumemenutitle), "%t\n%t %i%t\n ", "Volume Menu Title", "Volume Current", RoundFloat(g_fClientVol[client] * 100), "Porcento");
	Format(v100, sizeof(v100), "%t", "v100");
	Format(v75, sizeof(v75), "%t", "v75");
	Format(v50, sizeof(v50), "%t", "v50");
	Format(v25, sizeof(v25), "%t", "v25");
	Format(v10, sizeof(v10), "%t", "v10");
	Format(v05, sizeof(v05), "%t", "v05");
	
	// Add items to menu.
	SetMenuTitle(Volume_Menu_Main, volumemenutitle);
	AddMenuItem(Volume_Menu_Main, "100", v100);
	AddMenuItem(Volume_Menu_Main, "75", v75);
	AddMenuItem(Volume_Menu_Main, "50", v50);
	AddMenuItem(Volume_Menu_Main, "25", v25);
	AddMenuItem(Volume_Menu_Main, "10", v10);
	AddMenuItem(Volume_Menu_Main, "5", v05);

	// Create a "Back" button to the main menu.
	SetMenuExitBackButton(Volume_Menu_Main, true);

	// Display menu to client.
	DisplayMenu(Volume_Menu_Main, client, MENU_TIME_FOREVER);
}

public VolumeMenuHandler(Handle:menu, MenuAction:action, client, slot)
{
	char sCookieValue[12];

	
	if (action == MenuAction_Select && IsValidClient(client))
	{
		new bool:resend = true;
		switch(slot)
		{
			case 0:
			{
				g_fClientVol[client] = 1.0;
				FloatToString(g_fClientVol[client], sCookieValue, sizeof(sCookieValue));
				SetClientCookie(client, g_ZrSoundsCookie, sCookieValue);
				TranslationPrintCenterText(client, "Volume set to", RoundFloat(g_fClientVol[client] * 100));
				TranslationPrintToChat(client, "Volume updated");
			} 
			case 1:
			{
				g_fClientVol[client] = 0.75;
				FloatToString(g_fClientVol[client], sCookieValue, sizeof(sCookieValue));
				SetClientCookie(client, g_ZrSoundsCookie, sCookieValue);
				TranslationPrintCenterText(client, "Volume set to", RoundFloat(g_fClientVol[client] * 100));
				TranslationPrintToChat(client, "Volume updated");
			}
			case 2:
			{
				g_fClientVol[client] = 0.5;
				FloatToString(g_fClientVol[client], sCookieValue, sizeof(sCookieValue));
				SetClientCookie(client, g_ZrSoundsCookie, sCookieValue);
				TranslationPrintCenterText(client, "Volume set to", RoundFloat(g_fClientVol[client] * 100));
				TranslationPrintToChat(client, "Volume updated");
			}
			case 3:
			{
				g_fClientVol[client] = 0.25;
				FloatToString(g_fClientVol[client], sCookieValue, sizeof(sCookieValue));
				SetClientCookie(client, g_ZrSoundsCookie, sCookieValue);
				TranslationPrintCenterText(client, "Volume set to", RoundFloat(g_fClientVol[client] * 100));
				TranslationPrintToChat(client, "Volume updated");
			}
			case 4:
			{
				g_fClientVol[client] = 0.1;
				FloatToString(g_fClientVol[client], sCookieValue, sizeof(sCookieValue));
				SetClientCookie(client, g_ZrSoundsCookie, sCookieValue);
				TranslationPrintCenterText(client, "Volume set to", RoundFloat(g_fClientVol[client] * 100));
				TranslationPrintToChat(client, "Volume updated");
			}
			case 5:
			{
				g_fClientVol[client] = 0.05;
				FloatToString(g_fClientVol[client], sCookieValue, sizeof(sCookieValue));
				SetClientCookie(client, g_ZrSoundsCookie, sCookieValue);
				TranslationPrintCenterText(client, "Volume set to", RoundFloat(g_fClientVol[client] * 100));
				TranslationPrintToChat(client, "Volume updated");
			}
		}
		if (resend)
		{
			// Re-send menu.
			ZSoundsVolumeMenuMain(client);
		}
	}

		
		// Client closed the menu.
	if (action == MenuAction_Cancel)
	{
		// Client hit "Back" button.
		if (slot == MenuCancel_ExitBack)
		{
			// Re-open main menu.
			ZSoundsMenuMain(client);
		}
	}
	// Client exited menu.
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

int GetIntCookie(int client, Handle handle)
{
    char sCookieValue[11];
    GetClientCookie(client, handle, sCookieValue, sizeof(sCookieValue));
    return StringToInt(sCookieValue);
}

float GetIntZeCookie(int client)
{
    char gCookieValue[11];
    GetClientCookie(client, g_ZombiesECookie, gCookieValue, sizeof(gCookieValue));
    return StringToFloat(gCookieValue);
}

float GetIntCountdownCookie(int client)
{
    char cCookieValue[11];
    GetClientCookie(client, g_CountDownCookie, cCookieValue, sizeof(cCookieValue));
    return StringToFloat(cCookieValue);
}

float GetClientVolume(int client){
    float defaultVolume = GetConVarFloat(g_hCvarsList[CVAR_VOLUME_DEFAULT]);

    char vCookieValue[11];
    GetClientCookie(client, g_ZrSoundsCookie, vCookieValue, sizeof(vCookieValue));

    if(StrEqual(vCookieValue, "") || StrEqual(vCookieValue, "0"))
        Format(vCookieValue , sizeof(vCookieValue), "%0.2f", defaultVolume);

    return StringToFloat(vCookieValue);
}

//Toggle CountDown Voices.
CounToggle(client)
{
	// Get the cookie value.
	int Cdstate = GetIntCookie(client, g_CountDownCookie);

	if (Cdstate == 1)
	{
	// Toggle the value.
		TranslationPrintCenterText(client, "CCountDown select 2");
		TranslationPrintToChat(client, "CountDown select 2");
		SetClientCookie(client, g_CountDownCookie, "2");
		return true;
	}	
	if (Cdstate == 2)
	{
	// Toggle the value.
		TranslationPrintCenterText(client, "CCountDown select 0");
		TranslationPrintToChat(client, "CountDown select 0");
		SetClientCookie(client, g_CountDownCookie, "0");
		return true;
	}	
	else
	{
	// Toggle the value.
		TranslationPrintCenterText(client, "CCountDown select 1");
		TranslationPrintToChat(client, "CountDown select 1");
		SetClientCookie(client, g_CountDownCookie, "1");
	}
	
	return true;
}

//Toggle Zombis sounds.
bool:ZSEToggle(client)
{
	// If ZHP is disabled, then stop.
	new bool:zrzse = GetConVarBool(g_hCvarsList[CVAR_ZOMBIES_SOUNDS]);
	if (!zrzse)
	{
		//Tell client feature is disabled.
		TranslationPrintToChat(client, "Feature is disabled");

		return false;
	}
	
	// Get the cookie value.
	new bool:zsestate = CookiesGetClientCookieBool(client, g_ZombiesECookie);
	
	// Toggle the value.
	CookiesSetClientCookieBool(client, g_ZombiesECookie, !zsestate);
	
	// If ZHP was enabled, then tell client it has been disabled.
	if (zsestate)
	{
		TranslationPrintToChat(client, "Zombis sounds disable");
		TranslationPrintCenterText(client, "CZombis sounds disable");
	}
	// If ZHP was disabled, then tell client it has been enabled.
	else
	{
		TranslationPrintToChat(client, "Zombis sounds enable");
		TranslationPrintCenterText(client, "CZombis sounds enable");
	}
	
	return true;
}

//Toggle RoundEnd sounds.
bool:ZREToggle(client)
{
	// If RoundEnd sounds is disabled, then stop.
	new bool:reen = GetConVarBool(g_hCvarsList[CVAR_ROUNDEND_SOUNDS]);
	if (!reen)
	{
		// Tell client feature is disabled.
		TranslationPrintToChat(client, "Feature is disabled");
		
		return false;
	}
	
	// Get the cookie value.
	new bool:zrestate = CookiesGetClientCookieBool(client, g_ZRoundEndCookie);
	
	// Toggle the value.
	CookiesSetClientCookieBool(client, g_ZRoundEndCookie, !zrestate);
	
	// If RoundEnd sounds was enabled, then tell client it has been disabled.
	if (zrestate)
	{
		TranslationPrintToChat(client, "RoundEnd sounds disable");
		TranslationPrintCenterText(client, "CRoundEnd sounds disable");
	}
	// If RoundEnd sounds was disabled, then tell client it has been enabled.
	else
	{
		TranslationPrintToChat(client, "RoundEnd sounds enable");
		TranslationPrintCenterText(client, "CRoundEnd sounds enable");
	}
	
	return true;
}


// From Cliente Round end sound Zombis Wim.
RoundEndSoundsOnClientSoundT(x)
{
	// If death sound cvar is disabled, then stop.
	new bool:zrestate = CookiesGetClientCookieBool(x, g_ZRoundEndCookie);
	float level = GetClientVolume(x);
	if (!zrestate)
	{
		return;
	}
	
	// Get random death sound.
	decl String:soundre[SOUND_MAX_PATH];
	RoundEndSoundsGetRandomSound(soundre, ZombisWimT);
	
	RoundEndSoundsSoundFromClient(x, soundre, level);
}

// From Cliente Round end sound Humans Wim.
RoundEndSoundsOnClientSoundCT(x)
{
	// If death sound cvar is disabled, then stop.
	new bool:zrestate = CookiesGetClientCookieBool(x, g_ZRoundEndCookie);
	float level = GetClientVolume(x);
	if (!zrestate)
	{
		return;
	}
	
	// Get random death sound.
	decl String:soundre[SOUND_MAX_PATH];
	RoundEndSoundsGetRandomSound(soundre, HumansWinCt);
	
	RoundEndSoundsSoundFromClient(x, soundre, level);
}

stock static bool IsValidClient(int client) {
	if (!IsClientInGame(client)) {
		return false;
	}
	return true;
}