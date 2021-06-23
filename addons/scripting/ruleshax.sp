#pragma semicolon 1
#include <sourcemod>

#undef REQUIRE_EXTENSIONS
#include <SteamWorks>

public Plugin:myinfo = 
{
	name = "CS:GO A2S_Rules Hax",
	author = "Dr!fter, KyleS",
	description = "Fixes A2S_Rules for CS:GO",
	version = "0.0.7",
	url = ""
};

public OnPluginStart()
{
	new Handle:hGameConf;
	new String:error[128];
	
	hGameConf = LoadGameConfigFile("ruleshax.games");
	if(!hGameConf)
	{
		Format(error, sizeof(error), "Failed to find ruleshax.games");
		SetFailState(error);
	}
	
	new Address:addr = GameConfGetAddress(hGameConf, "NET_SendPacket");
	new Address:offset = Address:GameConfGetOffset(hGameConf, "NET_SendPacket_Offset");
	new Address:plusone = Address:1;
	
	if(LoadFromAddress(addr+offset, NumberType_Int32) != GameConfGetOffset(hGameConf, "NET_SendPacket_Byte"))
	{
		CloseHandle(hGameConf);
		Format(error, sizeof(error), "Failed to get valid patch value for NET_SendPacket");
		SetFailState(error);
	}
	
	StoreToAddress(addr+Address:offset, 65000, NumberType_Int32);
	
	if (GetFeatureStatus(FeatureType_Native, "SteamWorks_ClearRules") != FeatureStatus_Available)
	{
		addr = GameConfGetAddress(hGameConf, "UpdateMasterServerRules");
		offset = Address:GameConfGetOffset(hGameConf, "UpdateMasterServerRules_Offset");
		
		if(LoadFromAddress(addr+offset, NumberType_Int8) != GameConfGetOffset(hGameConf, "UpdateMasterServerRules_Byte"))
		{
			CloseHandle(hGameConf);
			Format(error, sizeof(error), "Failed to get valid patch value for UpdateMasterServerRules");
			SetFailState(error);
		}
		
		StoreToAddress(addr+offset, 0x90, NumberType_Int8);
		StoreToAddress(addr+(offset+plusone), 0x90, NumberType_Int8);
		
		addr = GameConfGetAddress(hGameConf, "ServerNotifyVarChangeCallback");
		offset = Address:GameConfGetOffset(hGameConf, "ServerNotifyVarChangeCallback_Offset");
		
		if(LoadFromAddress(addr+offset, NumberType_Int8) != GameConfGetOffset(hGameConf, "ServerNotifyVarChangeCallback_Byte"))
		{
			CloseHandle(hGameConf);
			Format(error, sizeof(error), "Failed to get valid patch value for ServerNotifyVarChangeCallback");
			SetFailState(error);
		}
		
		StoreToAddress(addr+offset, 0x90, NumberType_Int8);
		StoreToAddress(addr+(offset+plusone), 0x90, NumberType_Int8);
	}
	CloseHandle(hGameConf);

	new Handle:cvar = FindConVar("host_players_show");
	if(cvar)
	{
		HandleCvars(cvar, "", "");
		HookConVarChange(cvar, HandleCvars);
	}
	cvar = FindConVar("host_info_show");
	if(cvar)
	{
		HandleCvars(cvar, "", "");
		HookConVarChange(cvar, HandleCvars);
	}
}

public SteamWorks_SteamServersConnected()
{
	SteamWorks_ClearRules();
	
	decl String:name[64], String:value[256];
	new Handle:cvariter, bool:isCommand, flags;
	new Handle:cvar;

	cvariter = FindFirstConCommand(name, sizeof(name), isCommand, flags);
	if (cvariter == INVALID_HANDLE)
	{
		return;
	}

	do
	{
		if (isCommand || !(flags & FCVAR_NOTIFY))
		{
			continue;
		}
		
		cvar = FindConVar(name);
		GetConVarString(cvar, value, sizeof(value));
		
		if (!(flags & FCVAR_PROTECTED))
		{
			SteamWorks_SetRule(name, value);
		} else {
			if (StrEqual(value, "", false))
			{
				SteamWorks_SetRule(name, "0");
			} else {
				SteamWorks_SetRule(name, "1");
			}
		}
		
		CloseHandle(cvar);
	} while (FindNextConCommand(cvariter, name, sizeof(name), isCommand, flags));

	CloseHandle(cvariter);
}

public HandleCvars(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(GetConVarInt(convar) != 2)
	{
		SetConVarInt(convar, 2);
	}
}