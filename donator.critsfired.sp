//	------------------------------------------------------------------------------------
//	Filename:		donator.x.sp
//	Author:			Malachi
//	Version:		(see PLUGIN_VERSION)
//	Description:
//					Plugin allows donators to stop themselves from firing critical shots.
//
// * Changelog (date/version/description):
// * 2013-10-15	-	0.1.1		-	initial test version
// * 2013-11-09	-	0.1.2		-	return plugin changed
//	------------------------------------------------------------------------------------


// INCLUDES
#include <sourcemod>
#include <donator>
#include <clientprefs>				// cookies
#include <tf2>						// TF2_CalcIsAttackCritical


#pragma semicolon 1


// DEFINES

// Plugin Info
#define PLUGIN_INFO_VERSION			"0.1.2"
#define PLUGIN_INFO_NAME			"Donator Crits Fired"
#define PLUGIN_INFO_AUTHOR			"Malachi"
#define PLUGIN_INFO_DESCRIPTION		"Allows donators to not fire crits"
#define PLUGIN_INFO_URL				"www.necrophix.com"

// Plugin
#define PLUGIN_PRINT_NAME			"[Donator:CritsFired]"			// Used for self-identification in chat/logging

// These define the text players see in the donator menu
#define MENUTEXT_CRITS					"Crits Fired"
#define MENUTITLE_CRITS					"Crits Fired:"
#define MENUSELECT_ITEM_NORMAL			"Normal"
#define MENUSELECT_ITEM_SUPRESS			"Supress Crits"

// cookie names
#define COOKIENAME_SPAWN_ITEM			"donator_critsfired"
#define COOKIEDESCRIPTION_SPAWN_ITEM	"Supress critical shots fired."

// GLOBALS
new g_bSupressCrits[MAXPLAYERS + 1];
new Handle:g_hCritsFiredCookie = INVALID_HANDLE;

enum _:CookieActionType
{
	Action_Normal = 0,
	Action_Supress = 1,
};


public Plugin:myinfo = 
{
	name = PLUGIN_INFO_NAME,
	author = PLUGIN_INFO_AUTHOR,
	description = PLUGIN_INFO_DESCRIPTION,
	version = PLUGIN_INFO_VERSION,
	url = PLUGIN_INFO_URL
}


public OnPluginStart()
{
	PrintToServer("%s Plugin start...", PLUGIN_PRINT_NAME);

	// Cookie time
	g_hCritsFiredCookie = RegClientCookie(COOKIENAME_SPAWN_ITEM, COOKIEDESCRIPTION_SPAWN_ITEM, CookieAccess_Private);
}


public OnPluginEnd() 
{
}


// Required: Basic donator interface
public OnAllPluginsLoaded()
{
	if(!LibraryExists("donator.core"))
		SetFailState("Unable to find plugin: Basic Donator Interface");
		
	Donator_RegisterMenuItem(MENUTEXT_CRITS, ChangeCritsFiredCallback);
}


// If client passes donator check, set status=true, otherwise false
// We assume this will happen before jointeam, otherwise nothing will show
public OnPostDonatorCheck(iClient)
{
	new String:szBuffer[256];

	if (!IsPlayerDonator(iClient))
	{
		return;
	}
	
	
	if (AreClientCookiesCached(iClient))
	{		
		GetClientCookie(iClient, g_hCritsFiredCookie, szBuffer, sizeof(szBuffer));
		
		if (strlen(szBuffer) > 0)
			g_bSupressCrits[iClient] = StringToInt(szBuffer);
	}

	return;
}



// Cleanup when player leaves
public OnClientDisconnect(iClient)
{
	g_bSupressCrits[iClient] = false;
}


public DonatorMenu:ChangeCritsFiredCallback(iClient)
{
	Panel_ChangeCritsFiredItem(iClient);
}


// Cleanup on map end
public OnMapEnd()
{

	// Cleanup crits for all players
	for(new i = 0; i < (MAXPLAYERS + 1); i++)
	{
		g_bSupressCrits[i] = false;
	}
}


// Create Menu 
public Action:Panel_ChangeCritsFiredItem(iClient)
{
	new Handle:menu = CreateMenu(CritsFiredMenuHandler);
	decl String:iTmp[32];
	new iSelected;

	SetMenuTitle(menu, MENUTITLE_CRITS);

	GetClientCookie(iClient, g_hCritsFiredCookie, iTmp, sizeof(iTmp));
	iSelected = StringToInt(iTmp);

	// Disabled
	if (_:iSelected == Action_Normal)
	{
		new String:iCompare[32];
		IntToString(Action_Normal, iCompare, sizeof(iCompare));
		AddMenuItem(menu, iCompare, MENUSELECT_ITEM_NORMAL, ITEMDRAW_DISABLED);
	}
	else
	{
		new String:iCompare[32];
		IntToString(Action_Normal, iCompare, sizeof(iCompare));
		AddMenuItem(menu, iCompare, MENUSELECT_ITEM_NORMAL, ITEMDRAW_DEFAULT);
	}
	
	// Enabled
	if (_:iSelected == Action_Supress)
	{
		new String:iCompare[32];
		IntToString(Action_Supress, iCompare, sizeof(iCompare));
		AddMenuItem(menu, iCompare, MENUSELECT_ITEM_SUPRESS, ITEMDRAW_DISABLED);
	}
	else
	{
		new String:iCompare[32];
		IntToString(Action_Supress, iCompare, sizeof(iCompare));
		AddMenuItem(menu, iCompare, MENUSELECT_ITEM_SUPRESS, ITEMDRAW_DEFAULT);
	}
	
	
	DisplayMenu(menu, iClient, 20);
}


// Menu Handler
public CritsFiredMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	decl String:sSelected[32];
	new iSelected;

	GetMenuItem(menu, param2, sSelected, sizeof(sSelected));
	iSelected = StringToInt(sSelected);

	switch (action)
	{
		case MenuAction_Select:
		{
			SetClientCookie(param1, g_hCritsFiredCookie, sSelected);
			if(iSelected == Action_Normal)
			{
				g_bSupressCrits[param1] = false;
			}
			else
			{
				if(iSelected == Action_Supress)
				{
					g_bSupressCrits[param1] = true;
				}
				else
				{
					LogError("%s Failed to parse menu selection.", PLUGIN_PRINT_NAME);
				}
			}
			
		}
//		case MenuAction_Cancel: ;
		case MenuAction_End: CloseHandle(menu);
	}
}


public Action:TF2_CalcIsAttackCritical(iClient, weapon, String:weaponname[], &bool:bResult)
{
	if (!g_bSupressCrits[iClient])
	{
		return Plugin_Continue;	
	}
	else
	{
		bResult = false;
		return Plugin_Changed;
	}
}

