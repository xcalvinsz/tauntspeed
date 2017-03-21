# TF2 Taunt Speed Modifier

[![IMAGE ALT TEXT HERE](http://img.youtube.com/vi/QJzz6oUtAMk/0.jpg)](http://www.youtube.com/watch?v=QJzz6oUtAMk)

## Description
This plugin will change the taunt animation/kill speed

## Requirements
```
Plugin for Team Fortress 2
Requires Sourcemod 1.8+ and Metamod 1.10+
```

## Convar settings
```
sm_tauntspeed_enabled - [1/0] - Enables/Disables Taunt Speed Modifier
sm_tauntspeed_flag - Enable taunt speed on players with the given flag [0 - OFF, 1 - PUBLIC, FLAG (https://wiki.alliedmods.net/Adding_Admins_(SourceMod)#Levels)]
sm_tauntspeed_speed - The speed of taunt if player has the flag given in sm_tauntspeed_flag
```

## Commands
```
sm_tauntspeed <client> <float:value> - Enables Taunt Speed on players (ADMIN GENERIC)
sm_tauntspeedme - Enable Taunt Speed on yourself (ADMIN GENERIC)
```

## Installation
```
1. Place tauntspeed.smx to addons/sourcemod/plugins/
2. Place tauntspeed_menu.cfg to addons/sourcemod/configs/
3. Place tauntspeed_exclude.cfg to addons/sourcemod/configs/
4. Place tf2.tauntspeed to addons/sourcemod/gamedata
5. Place taunt.cfg to cfg/sourcemod/
```

## Configuration Setup
* Open addons/sourcemod/configs/tauntspeed_menu.cfg
```
"Taunt Speed"
{
	//1.0 is normal speed
    "Very Slow"
    {
		"Speed"			"0.2"
    }
	"Slow"
    {
		"Speed"			"0.5"
    }
	"Regular"
    {
		"Speed"			"1.0"
    }
	"Fast"
    {
		"Speed"			"1.5"
    }
	"Very Fast"
    {
		"Speed"			"2.0"
    }
	"WTF"
	{
		"Speed"			"5.0"
	}
}
```
Here you can change the menu that is displayed to clients

* Open addons/sourcemod/configs/tauntspeed_exclude.cfg
```
"Taunt Speed Exclude"
{
	//Weapon Index can be found here: https://wiki.alliedmods.net/Team_Fortress_2_Item_Definition_Indexes
	//Each index must be seperated by a ;
	//For example: "5;7;867;342;64"
	"Weapon Index"  ""
	
	//Taunt Index can be found in the original post thread of this plugin
	//Each index must be seperated by a ;
	//For example: "5;7;867;342;64"
	"Taunt Index" ""
}
```
Here you can exclude certain weapon taunts or action taunts

## Natives
```
/**
 * Sets the taunt speed on client given the vale
 *
 * @param client	An integer.
 * @param value		A float.
 * @return
 */
native void SetTauntSpeed(int client, float value);

/**
 * Removes the taunt speed on client
 *
 * @param client 	An integer.
 * @return
 */
native void RemoveTauntSpeed(int client);
```
These natives can be used to set/remove taunt speeds on client
