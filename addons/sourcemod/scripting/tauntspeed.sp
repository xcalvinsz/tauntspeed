/*  TF2 Taunt Speed Modifier
 *
 *  Copyright (C) 2017 Calvin Lee (Chaosxk)
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

#include <tf2>
#include <tf2attributes>
#include <morecolors>

#pragma newdecls required

#define PLUGIN_VERSION "2.2"
#define MAX_STRING_LENGTH 2048	//max string length for keyvalue string, if for some reason you run out of space then increase this value
#define ATTRIBUTE_GESTURE 201
#define ATTRIBUTE_VOICE 2048

ConVar g_cEnabled, g_cFlag, g_cSpeed, g_cTauntAttack, g_cVoice;
int g_iOffset;
float g_flLastAttackTime[MAXPLAYERS + 1];
bool g_bFlagAccess[MAXPLAYERS + 1];
float g_flTauntSpeed[MAXPLAYERS + 1] = { 1.0, ...};
bool g_bTauntSpeedAltered[MAXPLAYERS + 1];
ArrayList g_hArrayMenu, g_hArrayWeapon, g_hArrayTaunt;

public Plugin myinfo = 
{
	name = "[TF2] Taunt Speed Modifier",
	author = "Tak (Chaosxk)",
	description = "Changes the animation/attack speed of taunts.",
	version = PLUGIN_VERSION,
	url = "https://github.com/xcalvinsz/tauntspeed"
};

public void OnPluginStart()
{
	CreateConVar("sm_tauntspeed_version", PLUGIN_VERSION, "Version for Taunt Speed Modifier", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_cEnabled = CreateConVar("sm_tauntspeed_enabled", "1", "Enables/Disables Taunt Speed Modifier");
	g_cFlag = CreateConVar("sm_tauntspeed_flag", "0", "Enable taunt speed on players with the given flag");
	g_cSpeed = CreateConVar("sm_tauntspeed_speed", "2.0", "The speed of taunt if player has the flag given in sm_tauntspeed_flag");
	g_cTauntAttack = CreateConVar("sm_tauntspeed_attack", "1", "Allow taunt attack timing to be changed with the taunt speed");
	g_cVoice = CreateConVar("sm_tauntspeed_voice", "1", "Allow voice pitch to be changed with taunt speed");
	
	RegAdminCmd("sm_tauntspeed", Command_TauntSpeed, ADMFLAG_GENERIC, "Enables Taunt Speed on players.");
	RegAdminCmd("sm_tauntspeedme", Command_TauntSpeedMe, ADMFLAG_GENERIC, "Enable Taunt Speed on yourself.");
	
	g_hArrayMenu = new ArrayList();
	g_hArrayWeapon = new ArrayList();
	g_hArrayTaunt = new ArrayList();
	
	g_cFlag.AddChangeHook(Hook_FlagChange);
	
	Handle hConf = LoadGameConfigFile("tf2.tauntspeed");
	
	if (LookupOffset(g_iOffset, "CTFPlayer", "m_iSpawnCounter"))
		g_iOffset -= GameConfGetOffset(hConf, "m_flTauntAttackTime");
		
	delete hConf;
	
	AutoExecConfig(true, "tauntspeed");
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;
		OnClientPostAdminCheck(i);
	}
}

public void OnPluginEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;
		RemoveGestureSpeed(i);
		RemoveVoicePitch(i);
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("SetGestureSpeed", Native_SetGestureSpeed);
	CreateNative("SetVoicePitch", Native_SetVoicePitch);
	CreateNative("SetTauntAttackSpeed", Native_SetTauntAttackSpeed);
	CreateNative("RemoveGestureSpeed", Native_RemoveGestureSpeed);
	CreateNative("RemoveVoicePitch", Native_RemoveVoicePitch);
	
	RegPluginLibrary("tauntspeed");
	
	return APLRes_Success;
}

public void OnConfigsExecuted()
{
	SetupMenuConfig();
	SetupTauntExcludeConfig();
}

public void Hook_FlagChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;
		OnClientPostAdminCheck(i);
	}
}

public void OnRebuildAdminCache(AdminCachePart part)
{
	if (part == AdminCache_Admins)
	{
		RequestFrame(Frame_AdminCache, 0);
	}
}

public void Frame_AdminCache(any data)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;
		OnClientPostAdminCheck(i);
	}
}

public void OnClientPostAdminCheck(int client)
{
	char sFlag[2];
	g_cFlag.GetString(sFlag, sizeof(sFlag));
	
	if (IsCharNumeric(sFlag[0]))
	{
		g_bFlagAccess[client] = !!StringToInt(sFlag);
	}
	else
	{
		int buffer = sFlag[0];
		AdminFlag flag;
		FindFlagByChar(buffer, flag);
		g_bFlagAccess[client] = CheckCommandAccess(client, "", (1 << view_as<int>(flag)), true);
	}
	g_flTauntSpeed[client] = 1.0;
	g_bTauntSpeedAltered[client] = false;
}

public int Native_SetGestureSpeed(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	float value = view_as<float>(GetNativeCell(2));
	SetGestureSpeed(client, value);
}

public int Native_SetVoicePitch(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	float value = view_as<float>(GetNativeCell(2));
	SetVoicePitch(client, value);
}

public int Native_SetTauntAttackSpeed(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	float value = view_as<float>(GetNativeCell(2));
	SetTauntAttackSpeed(client, value);
}

public int Native_RemoveGestureSpeed(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	RemoveGestureSpeed(client);
}

public int Native_RemoveVoicePitch(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	RemoveVoicePitch(client);
}

public Action Command_TauntSpeed(int client, int args)
{
	if (!g_cEnabled.BoolValue)
	{
		CReplyToCommand(client, "{green}[SM] {orange}This plugin is disabled.");
		return Plugin_Handled;
	}
	
	if (args != 2)
	{
		CReplyToCommand(client, "{green}[SM] {orange}Usage: !tauntspeed <client> <float:value> \n[E.G !tauntspeed @all 2.0] - Doubles taunt speed");
		return Plugin_Handled;
	}
	
	char arg1[64], arg2[8];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	float value = StringToFloat(arg2);
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		CReplyToCommand(client, "{green}[SM] {orange}Can not find client.");
		return Plugin_Handled;
	}
	
	for (int i = 0; i < target_count; i++)
	{
		if(1 <= target_list[i] <= MaxClients && IsClientInGame(target_list[i]))
		{
			g_flTauntSpeed[target_list[i]] = value;
			if (value != 1.0)
				SetGestureSpeed(target_list[i], value);
			else
				RemoveGestureSpeed(target_list[i]);
		}
	}
	
	CShowActivity2(client, "{green}[SM] ", "{orange}%N has set %s taunt speed to %.0f%%.", client, tn_is_ml ? "%%t" : "%%s", target_name, value * 100);
	
	//if (tn_is_ml)
	//	CShowActivity2(client, "{green}[SM] ", "{orange}%N has set %t taunt speed to %.0f%%.", client, target_name, value * 100);
	//else
	//	CShowActivity2(client, "{green}[SM] ", "{orange}%N has set %s taunt speed to %.0f%%", client, target_name, value * 100);
		
	return Plugin_Handled;
}

public Action Command_TauntSpeedMe(int client, int args)
{
	if (!g_cEnabled.BoolValue)
	{
		ReplyToCommand(client, "[SM] This plugin is disabled.");
		return Plugin_Handled;
	}	
	DisplayMenuHandle(client);
	return Plugin_Handled;
}

void DisplayMenuHandle(int client)
{
	Menu menu = new Menu(Menu_Handler);
	menu.SetTitle("Taunt Speed Menu");
	
	for (int i = 0; i < g_hArrayMenu.Length; i++)
	{
		DataPack hPack = g_hArrayMenu.Get(i);
		hPack.Reset();
		
		char sItemName[32];
		hPack.ReadString(sItemName, sizeof(sItemName));
		
		float flSpeed = hPack.ReadFloat();
		char buffer[8];
		FloatToString(flSpeed, buffer, sizeof(buffer));
		menu.AddItem(buffer, sItemName);
	}
	menu.ExitButton = true;
	menu.Display(client, 30);
}

public int Menu_Handler(Menu MenuHandle, MenuAction action, int client, int num)
{
	if (action == MenuAction_Select)
	{
		char buffer[8];
		MenuHandle.GetItem(num, buffer, sizeof(buffer));
		float flSpeed = StringToFloat(buffer);
		g_flTauntSpeed[client] = flSpeed;
		if (flSpeed != 1.0)
		{
			SetGestureSpeed(client, flSpeed);
			CPrintToChat(client, "{green}[SM] {orange}You have set your taunt speed to %.0f%%", flSpeed * 100);
		}
		else
		{
			RemoveGestureSpeed(client);
			CPrintToChat(client, "{green}[SM] {orange}You have set your taunt speed to normal: %.0f%%", (g_bFlagAccess[client] ? g_cSpeed.FloatValue : flSpeed) * 100);
		}
	}
	else if (action == MenuAction_End)
		delete MenuHandle;
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if (!g_cEnabled.BoolValue)
		return;
		
	if (condition == TFCond_Taunting)
	{
		int weapon;
		if ((weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon")) == -1)
			return;
			
		int weapon_index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		if (g_hArrayWeapon.FindValue(weapon_index) != -1)
			return;
			
		int taunt_index = GetEntProp(client, Prop_Send, "m_iTauntItemDefIndex");
		if (g_hArrayTaunt.FindValue(taunt_index) != -1)
			return;
		
		if (g_flTauntSpeed[client] != 1.0)
		{
			if (g_cTauntAttack.BoolValue)
				SetTauntAttackSpeed(client, g_flTauntSpeed[client]);
			if (g_cVoice.BoolValue)
				SetVoicePitch(client, g_flTauntSpeed[client]);
			g_bTauntSpeedAltered[client] = true;
		}
		else if (g_bFlagAccess[client])
		{
			if (g_cTauntAttack.BoolValue)
				SetTauntAttackSpeed(client, g_cSpeed.FloatValue);
			if (g_cVoice.BoolValue)
				SetVoicePitch(client, g_cSpeed.FloatValue);
			g_bTauntSpeedAltered[client] = true;
		}
	}
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	if (condition == TFCond_Taunting)
	{
		if (g_bTauntSpeedAltered[client])
		{
			RemoveVoicePitch(client);
			g_bTauntSpeedAltered[client] = false;
		}
	}
}

public void SetGestureSpeed(int client, float speed)
{
	TF2Attrib_SetByDefIndex(client, ATTRIBUTE_GESTURE, speed);
}

public void SetVoicePitch(int client, float pitch)
{
	TF2Attrib_SetByDefIndex(client, ATTRIBUTE_VOICE, pitch);
}

public void RemoveGestureSpeed(int client)
{
	TF2Attrib_RemoveByDefIndex(client, ATTRIBUTE_GESTURE);
}

public void RemoveVoicePitch(int client)
{
	TF2Attrib_RemoveByDefIndex(client, ATTRIBUTE_VOICE);
}

public void SetTauntAttackSpeed(int client, float speed)
{
	float flTauntAttackTime = GetEntDataFloat(client, g_iOffset);
	float flCurrentTime = GetGameTime();
	float flNextTauntAttackTime = flCurrentTime + ((flTauntAttackTime - flCurrentTime) / speed);
	if (flTauntAttackTime > 0.0)
	{
		SetEntDataFloat(client, g_iOffset, flNextTauntAttackTime, true);
		g_flLastAttackTime[client] = flNextTauntAttackTime;
		//This is to set the next attack time for taunts like spies knife where it attack 3 times
		//or sniper huntsman taunt where it daze the opponent then attacks
		DataPack hPack;
		CreateDataTimer(0.1, Timer_SetNextAttackTime, hPack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		hPack.WriteCell(GetClientUserId(client));
		hPack.WriteFloat(speed);
	}
}

public Action Timer_SetNextAttackTime(Handle timer, DataPack hPack)
{
	hPack.Reset();
	int client = GetClientOfUserId(hPack.ReadCell());
	float flTauntAttackTime = GetEntDataFloat(client, g_iOffset);
	
	if (g_flLastAttackTime[client] == flTauntAttackTime)
	{
		return Plugin_Continue;
	}
	else if (g_flLastAttackTime[client] > 0.0 && flTauntAttackTime == 0.0)
	{
		g_flLastAttackTime[client] = 0.0;
		return Plugin_Stop;
	}
	else
	{
		float speed = hPack.ReadFloat();
		float flCurrentTime = GetGameTime();
		float flNextTauntAttackTime = flCurrentTime + ((flTauntAttackTime - flCurrentTime) / speed);
		SetEntDataFloat(client, g_iOffset, flNextTauntAttackTime, true);
		g_flLastAttackTime[client] = flNextTauntAttackTime;
	}
	return Plugin_Continue;
}

bool LookupOffset(int &iOffset, const char[] strClass, const char[] strProp)
{
	iOffset = FindSendPropInfo(strClass, strProp);
	if (iOffset <= 0)
	{
		SetFailState("Could not locate offset for %s::%s", strClass, strProp);
	}
	return true;
}

void SetupMenuConfig()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/tauntspeed_menu.cfg");
	
	if (!FileExists(sPath))
		SetFailState("Can not find map filepath %s", sPath);
	
	KeyValues kv = CreateKeyValues("Taunt Speed Menu");
	kv.ImportFromFile(sPath);

	if (!kv.GotoFirstSubKey())
		SetFailState("Can not read file: %s", sPath);
	
	g_hArrayMenu.Clear();
	
	char sItemName[32];
	float flSpeed;
	
	do
	{
		kv.GetSectionName(sItemName, sizeof(sItemName));
		flSpeed = KvGetFloat(kv, "Speed", 1.0);
		
		DataPack hPack = new DataPack();
		hPack.WriteString(sItemName);
		hPack.WriteFloat(flSpeed);
		g_hArrayMenu.Push(hPack);
		
	} while (kv.GotoNextKey());
	
	delete kv;
}

void SetupTauntExcludeConfig()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/tauntspeed_exclude.cfg");
	
	if (!FileExists(sPath))
		SetFailState("Can not find map filepath %s", sPath);
	
	KeyValues kv = CreateKeyValues("Taunt Speed Exclude");
	kv.ImportFromFile(sPath);
		
	g_hArrayWeapon.Clear();
	g_hArrayTaunt.Clear();
	
	char sWeaponStringIndex[MAX_STRING_LENGTH], sTauntStringIndex[MAX_STRING_LENGTH];
	kv.GetString("Weapon Index", sWeaponStringIndex, sizeof(sWeaponStringIndex), NULL_STRING);
	kv.GetString("Taunt Index", sTauntStringIndex, sizeof(sTauntStringIndex), NULL_STRING);
	delete kv;
	
	//All this crap down here is to split the string with ; as deliminator and convert it to integer and store it to an array list
	int i = 0, count = 0;
	while (sWeaponStringIndex[i] != '\0')
	{
		if (sWeaponStringIndex[i++] == ';')
			count++;
	}
	if (sWeaponStringIndex[0] != '\0')
	{
		char[][] sWeaponSplitIndex = new char[++count][8];
		ExplodeString(sWeaponStringIndex, ";", sWeaponSplitIndex, count, 8);
		for (int j = 0; j < count; j++)
		{
			g_hArrayWeapon.Push(StringToInt(sWeaponSplitIndex[j]));
		}
	}
	
	i = 0, count = 0;
	while (sTauntStringIndex[i] != '\0')
	{
		if (sTauntStringIndex[i++] == ';')
			count++;
	}
	if (sTauntStringIndex[0] != '\0')
	{
		char[][] sTauntSplitIndex = new char[++count][8];
		ExplodeString(sTauntStringIndex, ";", sTauntSplitIndex, count, 8);
		for (int j = 0; j < count; j++)
		{
			g_hArrayTaunt.Push(StringToInt(sTauntSplitIndex[j]));
		}
	}
}