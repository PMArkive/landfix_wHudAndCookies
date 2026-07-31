#include <sdktools>
#include <sdkhooks>
#include <shavit/core>
#include <clientprefs>
#include <dhooks>

#pragma semicolon 1

// Plugin Info -------------------------------------------------------

public Plugin myinfo = 
{
	name = "LandFix with HUD and Cookies",
	author = "olivia, Haze, nimmy, shinoum, lukah, nora",
	description = "Unified Landfix (Olivia/Haze) with customizable HUD and cookies.",
	version = "1.3.0",
	url = "https://github.com/tadehack/landfix_wHudAndCookies"
}

// Global Variables --------------------------------------------------

char gS_Warning[16];
char gS_Style[16];

bool gB_Enabled[MAXPLAYERS+1] = {true, ...};
bool gB_LandfixType[MAXPLAYERS + 1] = {false, ...}; // false = Olivia | true = Haze
bool gB_UseHud[MAXPLAYERS+1] = {true, ...};

int gI_LastGroundEntity[MAXPLAYERS + 1];
int gI_HudPositionPreset[MAXPLAYERS + 1];
int gI_HudColor[MAXPLAYERS + 1];

float gF_HudPositionX[MAXPLAYERS + 1];
float gF_HudPositionY[MAXPLAYERS + 1];
float gF_HudTimerDuration = 0.7;

Handle gH_hudTimers[MAXPLAYERS + 1] = { null, ... };
Handle gH_CheckJumpButtonHookPre;

Cookie gC_EnabledCookie;
Cookie gC_LandfixTypeCookie;
Cookie gC_UseHudCookie;
Cookie gC_HudPositionCookie;
Cookie gC_HudColorCookie;

// HUD Colors
int gI_ColorRGB[6][4] = {
	{255,255,255,255},	// 0: White (Default)
	{0,255,255,255},	// 1: Cyan
	{255,0,255,255},	// 2: Purple
	{255,255,0,255},	// 3: Yellow
	{0,255,0,255},		// 4: Green
	{255,0,0,255}		// 5: Red
};

// Plugin Start ------------------------------------------------------

public void OnPluginStart()
{
	// Commands -----
	
	// Toggle Landfix
	RegConsoleCmd("sm_lf", Command_LandFix, "Landfix");
	RegConsoleCmd("sm_landfix", Command_LandFix, "Landfix");
	RegConsoleCmd("sm_lfix", Command_LandFix, "Landfix");
	RegConsoleCmd("sm_land", Command_LandFix, "Landfix");
	RegConsoleCmd("sm_64", Command_LandFix, "Landfix");
	RegConsoleCmd("sm_64fix", Command_LandFix, "Landfix");

	// Toggle Landfix Type
	RegConsoleCmd("sm_lft", Command_LandFixType, "LandfixType");
	RegConsoleCmd("sm_lftype", Command_LandFixType, "LandfixType");
	RegConsoleCmd("sm_landfixtype", Command_LandFixType, "LandfixType");
	RegConsoleCmd("sm_64type", Command_LandFixType, "LandfixType");
	RegConsoleCmd("sm_64t", Command_LandFixType, "LandfixType");
	
	// Toggle Landfix HUD
	RegConsoleCmd("sm_lfh", Command_LandFixHud, "LandfixHud");
	RegConsoleCmd("sm_lfhud", Command_LandFixHud, "LandfixHud");
	RegConsoleCmd("sm_landfixhud", Command_LandFixHud, "LandfixHud");
	RegConsoleCmd("sm_landhud", Command_LandFixHud, "LandfixHud");
	RegConsoleCmd("sm_lhud", Command_LandFixHud, "LandfixHud");
	RegConsoleCmd("sm_64hud", Command_LandFixHud, "LandfixHud");
	
	// Change HUD Position
	RegConsoleCmd("sm_lfhp", Command_LandFixHudPos, "LandfixHudPos");
	RegConsoleCmd("sm_lfpos", Command_LandFixHudPos, "LandfixHudPos");
	RegConsoleCmd("sm_landfixpos", Command_LandFixHudPos, "LandfixHudPos");
	RegConsoleCmd("sm_lfhudpos", Command_LandFixHudPos, "LandfixHudPos");
	RegConsoleCmd("sm_lfhudposition", Command_LandFixHudPos, "LandfixHudPos");
	RegConsoleCmd("sm_64hudpos", Command_LandFixHudPos, "LandfixHudPos");
	RegConsoleCmd("sm_64hudposition", Command_LandFixHudPos, "LandfixHudPos");
	
	// Change HUD Color
	RegConsoleCmd("sm_lfhc", Command_LandFixHudColor, "LandfixHUDColor");
	RegConsoleCmd("sm_lfcolor", Command_LandFixHudColor, "LandfixHUDColor");
	RegConsoleCmd("sm_lfhudcolor", Command_LandFixHudColor, "LandfixHUDColor");
	RegConsoleCmd("sm_64hudcolor", Command_LandFixHudColor, "LandfixHUDColor");
	RegConsoleCmd("sm_64color", Command_LandFixHudColor, "LandfixHUDColor");
	RegConsoleCmd("sm_64c", Command_LandFixHudColor, "LandfixHUDColor");
	
	// Landfix Main Menu
	RegConsoleCmd("sm_lfm", Command_LandFixMenu, "LandfixMenu");
	RegConsoleCmd("sm_lfmenu", Command_LandFixMenu, "LandfixMenu");
	RegConsoleCmd("sm_landmenu", Command_LandFixMenu, "LandfixMenu");
	RegConsoleCmd("sm_landfixmenu", Command_LandFixMenu, "LandfixMenu");
	RegConsoleCmd("sm_landfixsettings", Command_LandFixMenu, "LandfixMenu");
	RegConsoleCmd("sm_lfsettings", Command_LandFixMenu, "LandfixMenu");
	RegConsoleCmd("sm_lfoptions", Command_LandFixMenu, "LandfixMenu");
	RegConsoleCmd("sm_landfixconfig", Command_LandFixMenu, "LandfixMenu");
	RegConsoleCmd("sm_lfconfig", Command_LandFixMenu, "LandfixMenu");
	RegConsoleCmd("sm_64menu", Command_LandFixMenu, "LandfixMenu");
	RegConsoleCmd("sm_64m", Command_LandFixMenu, "LandfixMenu");
	RegConsoleCmd("sm_64settings", Command_LandFixMenu, "LandfixMenu");
	RegConsoleCmd("sm_64options", Command_LandFixMenu, "LandfixMenu");
	RegConsoleCmd("sm_64config", Command_LandFixMenu, "LandfixMenu");

	// Landfix Commands Menu
	RegConsoleCmd("sm_lfc", Command_LandFixCommandsMenu, "LandfixCommandsMenu");
	RegConsoleCmd("sm_lfcmds", Command_LandFixCommandsMenu, "LandfixCommandsMenu");
	RegConsoleCmd("sm_lfcommands", Command_LandFixCommandsMenu, "LandfixCommandsMenu");
	RegConsoleCmd("sm_landfixcommands", Command_LandFixCommandsMenu, "LandfixCommandsMenu");

	// Landfix About Menu
	RegConsoleCmd("sm_lfa", Command_LandFixAboutMenu, "LandfixAboutMenu");
	RegConsoleCmd("sm_lfabout", Command_LandFixAboutMenu, "LandfixAboutMenu");
	RegConsoleCmd("sm_64about", Command_LandFixAboutMenu, "LandfixAboutMenu");
	RegConsoleCmd("sm_landfixabout", Command_LandFixAboutMenu, "LandfixAboutMenu");

	// Cookies -----

	gC_EnabledCookie = new Cookie("landfix_toggle", "Landfix toggle state", CookieAccess_Protected);
	gC_LandfixTypeCookie = new Cookie("landfix_type_toggle", "Landfix type toggle state (Haze/Olivia)", CookieAccess_Protected);
	gC_UseHudCookie = new Cookie("landfix_hud_toggle", "Landfix HUD toggle state", CookieAccess_Protected);
	gC_HudPositionCookie = new Cookie("landfix_hud_position", "Landfix HUD position state", CookieAccess_Protected);
	gC_HudColorCookie = new Cookie("landfix_hud_color", "Landfix HUD Color", CookieAccess_Protected);

	// Olivia Stuff -----

	GameData gd = LoadGameConfigFile("landfix.games");
	if (gd == null)
		SetFailState("Failed to load landfix.games gamedata file");

	StartPrepSDKCall(SDKCall_Static);
	if(!PrepSDKCall_SetFromConf(gd, SDKConf_Signature, "CreateInterface"))
		SetFailState("Failed to get CreateInterface");

	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	Handle CreateInterface = EndPrepSDKCall();

	if(CreateInterface == null)
		SetFailState("Unable to prepare SDKCall for CreateInterface");

	char interfaceName[64];
	if(!GameConfGetKeyValue(gd, "IGameMovement", interfaceName, sizeof(interfaceName)))
		SetFailState("Failed to get IGameMovement interface name");

	Address IGameMovement = SDKCall(CreateInterface, interfaceName, 0);
	if(!IGameMovement)
		SetFailState("Failed to get IGameMovement pointer");

	int offset = GameConfGetOffset(gd, "CheckJumpButton");
	if(offset == -1)
		SetFailState("Failed to get CheckJumpButton offset");

	gH_CheckJumpButtonHookPre = DHookCreate(offset, HookType_Raw, ReturnType_Bool, ThisPointer_Address, DHook_CheckJumpButtonPre);
	DHookRaw(gH_CheckJumpButtonHookPre, false, IGameMovement);

	delete gd;
	delete CreateInterface;

	// Cookies load and Config Exec -----
	
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && !IsFakeClient(client))
		{
			OnClientPutInServer(client);
			
			if (AreClientCookiesCached(client))
			    OnClientCookiesCached(client);
		}
	}
	
	AutoExecConfig();

	GetShavitChatColors();
}

// Shavit Chat Color Stuff ----

public void OnMapStart()
{
	GetShavitChatColors();
}

public void Shavit_OnChatConfigLoaded()
{
	GetShavitChatColors();
}

void GetShavitChatColors()
{
	Shavit_GetChatStrings(sMessageWarning, gS_Warning, sizeof(gS_Warning));
	Shavit_GetChatStrings(sMessageStyle, gS_Style, sizeof(gS_Style));
}

// Player Stuff --------------------------------------------------

public Action OnPlayerRunCmd(int client, int &buttons) // This is from Haze
{
	if(IsFakeClient(client))
		return Plugin_Continue;

	int iGroundEnt = GetEntPropEnt(client, Prop_Data, "m_hGroundEntity");

	if(gB_Enabled[client] && gB_LandfixType[client] == true)
	{
		if(iGroundEnt != gI_LastGroundEntity[client] && iGroundEnt != -1)
		{
			if(HasEntProp(iGroundEnt, Prop_Data, "m_currentSound")) //retrowave mega fix
			{
				gI_LastGroundEntity[client] = iGroundEnt;
				return Plugin_Continue;
			}

			bool bHasVelocityProp = HasEntProp(iGroundEnt, Prop_Data, "m_vecVelocity");

			if(bHasVelocityProp)
			{
				float fVelocity[3];
				GetEntPropVector(iGroundEnt, Prop_Data, "m_vecVelocity", fVelocity);

				// ground is moving
				if(fVelocity[2] != 0.0)
				{
					gI_LastGroundEntity[client] = iGroundEnt;
					return Plugin_Continue;
				}
			}

			float difference = (1.50 - GetGroundUnits(client)), origin[3];
			GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", origin);
			origin[2] += difference;
			SetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", origin);
		}
	}

	gI_LastGroundEntity[client] = iGroundEnt;

	return Plugin_Continue;
}

public void OnClientCookiesCached(int client)
{
	if (IsFakeClient(client))
		return;
	
	char buffer[8];
	
	// Load Landfix enabled cookie
	gC_EnabledCookie.Get(client, buffer, sizeof(buffer));
	if (buffer[0] == '\0')
	{
	    gB_Enabled[client] = true;
	    gC_EnabledCookie.Set(client, "1");
	}
	else
	{
	    gB_Enabled[client] = (StringToInt(buffer) == 1);
	}

	// Load Landfix type cookie
    gC_LandfixTypeCookie.Get(client, buffer, sizeof(buffer));
    if (buffer[0] == '\0')
    {
        gB_LandfixType[client] = false;
        gC_LandfixTypeCookie.Set(client, "0");
    }
    else
    {
        gB_LandfixType[client] = (StringToInt(buffer) == 1);
    }
	
	// Load HUD enabled cookie
	gC_UseHudCookie.Get(client, buffer, sizeof(buffer));
	if (buffer[0] == '\0')
	{
	    gB_UseHud[client] = true;
	    gC_UseHudCookie.Set(client, "1");
	}
	else
	{
	    gB_UseHud[client] = (StringToInt(buffer) == 1);
	}

	// Load HUD position cookie
	gC_HudPositionCookie.Get(client, buffer, sizeof(buffer));
	if (buffer[0] == '\0')
	{
		gI_HudPositionPreset[client] = 1;
		gC_HudPositionCookie.Set(client, "1");
	}
	else
	{
		gI_HudPositionPreset[client] = StringToInt(buffer);
	}

	// Load HUD color cookie
	char colorBuffer[6];
	gC_HudColorCookie.Get(client, colorBuffer, sizeof(colorBuffer));
	if(colorBuffer[0] == '\0')
	{
		gI_HudColor[client] = 0;
		gC_HudColorCookie.Set(client, "0");
	}
	else
	{
		gI_HudColor[client] = StringToInt(colorBuffer);
	}

	SetHudPosition(client);
	StartHudTimer(client);
}

public void OnClientPutInServer(int client)
{
    OnClientCookiesCached(client);
}

// Commands --------------------------------------------------

public Action Command_LandFix(int client, int args) 
{
	if (client == 0)
		return Plugin_Handled;
	
	gB_Enabled[client] = !gB_Enabled[client];

	if(gB_LandfixType[client] == true)
	{
		if(gB_Enabled[client])
			Shavit_PrintToChat(client, "Landfix: %sOn \x07ffffff(Haze)", gS_Warning);
		else
			Shavit_PrintToChat(client, "Landfix: %sOff", gS_Style);
	}
	else
	{
		if(gB_Enabled[client])
			Shavit_PrintToChat(client, "Landfix: %sOn \x07ffffff(Olivia)", gS_Warning);
		else
			Shavit_PrintToChat(client, "Landfix: %sOff", gS_Style);
	}
	
	// Save Landfix enabled state in cookie
	char buffer[2];
	Format(buffer, sizeof(buffer), "%d", gB_Enabled[client]);
	gC_EnabledCookie.Set(client, buffer);
	
	if (gB_Enabled[client])
		StartHudTimer(client);
	else
		StopHudTimer(client);
	
	return Plugin_Handled;
}

public Action Command_LandFixType(int client, int args) 
{
    if(client == 0)
        return Plugin_Handled;

    gB_LandfixType[client] = !gB_LandfixType[client];
    
    // Save Landfix type state in cookie
    char buffer[2];
    Format(buffer, sizeof(buffer), "%d", gB_LandfixType[client]);
    gC_LandfixTypeCookie.Set(client, buffer);
    
    SetHudPosition(client);
    RefreshHudDisplay(client);
    
    if(gB_LandfixType[client])
        Shavit_PrintToChat(client, "Landfix Type: %sHaze", gS_Warning);
    else
        Shavit_PrintToChat(client, "Landfix Type: %sOlivia", gS_Style);
    return Plugin_Handled;
}

public Action Command_LandFixHud(int client, int args) 
{
	if (client == 0)
		return Plugin_Handled;
	
	gB_UseHud[client] = !gB_UseHud[client];
	if(gB_UseHud[client])
		Shavit_PrintToChat(client, "Landfix HUD: %sOn", gS_Warning);
	else
		Shavit_PrintToChat(client, "Landfix HUD: %sOff", gS_Style);
	
	// Save hud state in cookie
	char buffer[2];
	Format(buffer, sizeof(buffer), "%d", gB_UseHud[client]);
	gC_UseHudCookie.Set(client, buffer);
	
	if (gB_UseHud[client])
		StartHudTimer(client);
	else
		StopHudTimer(client);
	
	return Plugin_Handled;
}

public Action Command_LandFixHudPos(int client, int args)
{
	if (client == 0)
		return Plugin_Handled;
	
	if (args < 1)
	{
		Shavit_PrintToChat(client, "Choose a HUD position from 0 to 2, example: %s/lfhp 1", gS_Style);
		Shavit_PrintToChat(client, "Current Landfix HUD position: %s%d", gS_Warning, gI_HudPositionPreset[client]);

		ShowLandFixHudPosMenu(client);

		return Plugin_Handled;
	}
	
	char arg[2];
	GetCmdArg(1, arg, sizeof(arg));
	int hudPosition = StringToInt(arg);
	
	if (hudPosition < 0 || hudPosition > 2)
	{
		Shavit_PrintToChat(client, "Choose a HUD position from 0 to 2, example: %s/lfhp 1", gS_Style);
		Shavit_PrintToChat(client, "Current Landfix HUD position: %s%d", gS_Warning, gI_HudPositionPreset[client]);
		return Plugin_Handled;
	}
	
	gI_HudPositionPreset[client] = hudPosition;
	SetHudPosition(client);
	
	// Save hud pos state in cookie
	char buffer[2];
	Format(buffer, sizeof(buffer), "%d", gI_HudPositionPreset[client]);
	gC_HudPositionCookie.Set(client, buffer);

	// Refresh HUD display with new position
	RefreshHudDisplay(client);

	Shavit_PrintToChat(client, "Landfix HUD position set to: %s%d", gS_Warning, hudPosition);

	return Plugin_Handled;
}

public Action Command_LandFixHudColor(int client, int args)
{
	if (client == 0)
		return Plugin_Handled;
	
	if (args < 1)
	{
		Shavit_PrintToChat(client, "Choose a HUD color from 0 to 5, example: %s/lfhc 1", gS_Style);
		Shavit_PrintToChat(client, "Current Landfix HUD color: %s%d", gS_Warning, gI_HudColor[client]);

		ShowLandFixHudColorMenu(client);

		return Plugin_Handled;
	}
	
	char arg[8];
	GetCmdArg(1, arg, sizeof(arg));
	int color = StringToInt(arg);
	if (color < 0 || color >= 6)
	{
		Shavit_PrintToChat(client, "Choose a HUD color from 0 to 5, example: %s/lfhc 1", gS_Style);
		Shavit_PrintToChat(client, "Current Landfix HUD color: %s%d", gS_Warning, gI_HudColor[client]);
		return Plugin_Handled;
	}
	
	gI_HudColor[client] = color;

	// Save hud color state in cookie
	char buffer[8];
	Format(buffer, sizeof(buffer), "%d", color);
	gC_HudColorCookie.Set(client, buffer);
	
	// Refresh HUD display with new color
	RefreshHudDisplay(client);
	
	Shavit_PrintToChat(client, "Landfix HUD color set to: %s%d", gS_Warning, color);
	return Plugin_Handled;
}

public Action Command_LandFixMenu(int client, int args)
{
	if(client == 0)
		return Plugin_Handled;
	
	ShowLandFixMenu(client);

	return Plugin_Handled;
}

public Action Command_LandFixCommandsMenu(int client, int args)
{
	if(client == 0)
		return Plugin_Handled;
	
	ShowLandFixCommandsMenu(client);

	return Plugin_Handled;
}

public Action Command_LandFixAboutMenu(int client, int args)
{
	if(client == 0)
		return Plugin_Handled;
	
	ShowLandFixAboutMenu(client);

	return Plugin_Handled;
}

// Menus --------------------------------------------------

void ShowLandFixMenu(int client)
{
	Menu menu = CreateMenu(LandFixMenu_Callback);
	SetMenuTitle(menu, "Landfix\n \n");

	AddMenuItem(menu, "landfix", (gB_Enabled[client]) ? "Landfix: On" : "Landfix: Off");
	AddMenuItem(menu, "lftype", (gB_LandfixType[client]) ? "Type: Haze\n \n" : "Type: Olivia\n \n");

	AddMenuItem(menu, "lfhud", (gB_UseHud[client]) ? "HUD: On" : "HUD: Off");
	AddMenuItem(menu, "lfhudpos", "HUD Position");
	AddMenuItem(menu, "lfhudcolor", "HUD Color\n \n");

	AddMenuItem(menu, "lfcommands", "Commands");
	AddMenuItem(menu, "lfabout", "About");

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int LandFixMenu_Callback(Menu menu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		GetMenuItem(menu, option, info, sizeof(info));
		
		if(StrEqual(info, "landfix"))
		{
			Command_LandFix(client, 0);
			ShowLandFixMenu(client);
		}
		else if(StrEqual(info, "lftype"))
		{
			Command_LandFixType(client, 0);
			ShowLandFixMenu(client);
		}
		else if(StrEqual(info, "lfhud"))
		{
			Command_LandFixHud(client, 0);
			ShowLandFixMenu(client);
		}
		else if(StrEqual(info, "lfhudpos"))
		{
			ShowLandFixHudPosMenu(client);
		}
		else if(StrEqual(info, "lfhudcolor"))
		{
			ShowLandFixHudColorMenu(client);
		}
		else if(StrEqual(info, "lfcommands"))
		{
			ShowLandFixCommandsMenu(client);
		}
		else if(StrEqual(info, "lfabout"))
		{
			ShowLandFixAboutMenu(client);
		}
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}

void ShowLandFixHudPosMenu(int client)
{
	Menu menu = CreateMenu(LandFixHudPosMenu_Callback);
	SetMenuTitle(menu, "Landfix | HUD Position\n \n");
	AddMenuItem(menu, "0", "Top Left");
	AddMenuItem(menu, "1", "Top Right (Default)");
	AddMenuItem(menu, "2\n \n", "Top Center\n \n");
	AddMenuItem(menu, "back", "Back");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int LandFixHudPosMenu_Callback(Menu menu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		GetMenuItem(menu, option, info, sizeof(info));
		
		if(StrEqual(info, "back"))
		{
			ShowLandFixMenu(client);
		}
		else
		{
			int hudPos = StringToInt(info);
			gI_HudPositionPreset[client] = hudPos;
			SetHudPosition(client);
			
			char buffer[2];
			Format(buffer, sizeof(buffer), "%d", gI_HudPositionPreset[client]);
			gC_HudPositionCookie.Set(client, buffer);
			
			// Refresh HUD display with new position
			RefreshHudDisplay(client);
			
			Shavit_PrintToChat(client, "Landfix HUD position set to: %s%d", gS_Warning, hudPos);
			ShowLandFixHudPosMenu(client);
		}
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}

void ShowLandFixHudColorMenu(int client)
{
	Menu menu = CreateMenu(LandFixHudColorMenu_Callback);
	SetMenuTitle(menu, "Landfix | HUD Color\n \n");
	AddMenuItem(menu, "0", "White (Default)");
	AddMenuItem(menu, "1", "Cyan");
	AddMenuItem(menu, "2", "Purple");
	AddMenuItem(menu, "3", "Yellow");
	AddMenuItem(menu, "4", "Green");
	AddMenuItem(menu, "5\n \n", "Red\n \n");
	AddMenuItem(menu, "back", "Back");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int LandFixHudColorMenu_Callback(Menu menu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		GetMenuItem(menu, option, info, sizeof(info));
		
		if(StrEqual(info, "back"))
		{
			ShowLandFixMenu(client);
		}
		else
		{
			int colorIndex = StringToInt(info);
			gI_HudColor[client] = colorIndex;
			char buffer[6];
			Format(buffer, sizeof(buffer), "%d", colorIndex);
			gC_HudColorCookie.Set(client, buffer);
			
			// Refresh HUD display with new color
			RefreshHudDisplay(client);
			
			Shavit_PrintToChat(client, "Landfix HUD color set to: %s%d", gS_Warning, colorIndex);
			ShowLandFixHudColorMenu(client);
		}
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}

void ShowLandFixCommandsMenu(int client)
{
	Menu menu = CreateMenu(LandFixCommandsMenu_Callback);
	SetMenuTitle(menu, "Landfix | Commands\n \n/lf - Toggle Landfix (On/Off)\n/lft - Toggle Landfix Type (Olivia/Haze)\n \n/lfh - Toggle Landfix Hud (On/Off)\n/lfhp <number> - Set Hud Position (0-2)\n/lfhc <number> - Set Hud Color (0-5)\n \n/lfm - Open Landfix Main Menu\n/lfc - Open Landfix Commands Menu\n/lfa - Open Landfix About Menu\n \n");
	AddMenuItem(menu, "back", "Back");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int LandFixCommandsMenu_Callback(Menu menu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		GetMenuItem(menu, option, info, sizeof(info));
		
		if(StrEqual(info, "back"))
			ShowLandFixMenu(client);
	}

	return 0;
}

void ShowLandFixAboutMenu(int client)
{
	char sVersion[8];
	GetPluginInfo(GetMyHandle(), PlInfo_Version, sVersion, sizeof(sVersion));

	Menu menu = CreateMenu(LandFixAboutMenu_Callback);
	SetMenuTitle(menu, "Landfix with HUD and Cookies v%s\n \nThe Landfix plugin fixes a Source engine bug that causes jump height to vary by 2 units every jump\n \n \nLandfix Types:\n \nOlivia - Balances jump height by increasing the minimum height by 0.5 units while decreasing the maximum height by 0.5 units\nYou won't have any time loss during your run\n \nHaze - Makes every jump reach the maximum height, making 64-unit crouch jumps the easiest to perform\nYou will have a slight time loss by the end of your run\n \n", sVersion);
	AddMenuItem(menu, "back", "Back");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int LandFixAboutMenu_Callback(Menu menu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		GetMenuItem(menu, option, info, sizeof(info));
		
		if(StrEqual(info, "back"))
			ShowLandFixMenu(client);
	}

	return 0;
}

// HUD Timer Logic --------------------------------------------------

// Hud Timer
public Action Timer_ShowHudText(Handle timer, any client) 
{
	// Validate client and settings
	if (!IsClientInGame(client) || !gB_Enabled[client] || !gB_UseHud[client]) 
	{
		gH_hudTimers[client] = null;
		return Plugin_Stop;
	}

	if (gH_hudTimers[client] != timer)
		return Plugin_Stop;
	
	char hudText[32];
	Format(hudText, sizeof(hudText), "Landfix: %s", gB_LandfixType[client] ? "Haze" : "Olivia");
	
	SetHudTextParams(gF_HudPositionX[client], gF_HudPositionY[client], gF_HudTimerDuration,
        gI_ColorRGB[gI_HudColor[client]][0],
        gI_ColorRGB[gI_HudColor[client]][1],
        gI_ColorRGB[gI_HudColor[client]][2],
        gI_ColorRGB[gI_HudColor[client]][3],
        0, 0.0, 0.0);
		
	ShowHudText(client, -1, hudText);
	
	return Plugin_Continue;
}

void StopHudTimer(int client)
{
	if (gH_hudTimers[client] != null)
	{
		KillTimer(gH_hudTimers[client]);
		gH_hudTimers[client] = null;
	}
	
	// Clear any existing HUD text
	SetHudTextParams(-1.0, -1.0, 0.01, 255, 255, 255, 0, 0, 0.0, 0.0, 0.0);
	ShowHudText(client, -1, "");
}

void StartHudTimer(int client)
{
	if (!IsClientInGame(client) || IsFakeClient(client))
		return;
		
	// Always stop any existing timer first
	StopHudTimer(client);
	
	if (gB_Enabled[client] && gB_UseHud[client])
		gH_hudTimers[client] = CreateTimer(gF_HudTimerDuration, Timer_ShowHudText, client, TIMER_REPEAT);
}

// HUD Logic --------------------------------------------------

void SetHudPosition(int client)
{
    // Top Left
    if (gI_HudPositionPreset[client] == 0)
    {
        gF_HudPositionX[client] = 0.01;
        gF_HudPositionY[client] = 0.16;
    }
    // Top Right
    else if (gI_HudPositionPreset[client] == 1)
    {
        if (gB_LandfixType[client] == true)
            gF_HudPositionX[client] = 0.882;
        else
            gF_HudPositionX[client] = 0.874;
        
        gF_HudPositionY[client] = 0.01;
    }
    // Top Center
    else if (gI_HudPositionPreset[client] == 2)
    {
        if (gB_LandfixType[client] == true)
            gF_HudPositionX[client] = 0.444;
        else
            gF_HudPositionX[client] = 0.443;
        
        gF_HudPositionY[client] = 0.01;
    }
}

void RefreshHudDisplay(int client)
{
	if (!IsClientInGame(client) || IsFakeClient(client))
		return;
		
	// Stop current timer and restart with new settings
	StartHudTimer(client);
}

// Actual LandFix Logic --------------------------------------------------

// Olivia Logic -----

MRESReturn DHook_CheckJumpButtonPre(Address pThis, Handle hParams)
{
	Address mv = view_as<Address>(LoadFromAddress(pThis + view_as<Address>(0x8), NumberType_Int32));
	int client = LoadFromAddress(mv + view_as<Address>(0x4), NumberType_Int32) & 0xFFFF;

	if(client < 1 || client > MaxClients)
		return MRES_Ignored;

	if(IsFakeClient(client) || !IsPlayerAlive(client))
		return MRES_Ignored;

	if(!gB_Enabled[client] || gB_LandfixType[client] == true)
		return MRES_Ignored;

	if(!GetEntPropFloat(client, Prop_Data, "m_flWaterJumpTime"))
	{
		if(GetEntProp(client, Prop_Data, "m_nWaterLevel") >= 2 || GetEntPropEnt(client, Prop_Data, "m_hGroundEntity") == -1)
			return MRES_Ignored;

		int mv_old_buttons = LoadFromAddress(mv + view_as<Address>(0x28), NumberType_Int32);
		if(mv_old_buttons & IN_JUMP || mv_old_buttons & IN_DUCK)
			return MRES_Ignored;

		float origin[3];
		float grndPos[3];
		origin[0] = view_as<float>(LoadFromAddress(mv + view_as<Address>(0x9C + 0x0), NumberType_Int32));
		origin[1] = view_as<float>(LoadFromAddress(mv + view_as<Address>(0x9C + 0x4), NumberType_Int32));
		origin[2] = view_as<float>(LoadFromAddress(mv + view_as<Address>(0x9C + 0x8), NumberType_Int32));
		GetGroundPosition(client, origin, grndPos);

		float diff = FloatAbs(grndPos[2] - origin[2]);
		if(diff < 0.49)
		{
			origin[2] = grndPos[2] + 0.49;
			StoreToAddress(mv + view_as<Address>(0x9C + 0x0), view_as<int>(origin[0]), NumberType_Int32);
			StoreToAddress(mv + view_as<Address>(0x9C + 0x4), view_as<int>(origin[1]), NumberType_Int32);
			StoreToAddress(mv + view_as<Address>(0x9C + 0x8), view_as<int>(origin[2]), NumberType_Int32);
		}
		else if(diff > 1.5 && diff < 2.0)
		{
			origin[2] = grndPos[2] + 1.5;
			StoreToAddress(mv + view_as<Address>(0x9C + 0x0), view_as<int>(origin[0]), NumberType_Int32);
			StoreToAddress(mv + view_as<Address>(0x9C + 0x4), view_as<int>(origin[1]), NumberType_Int32);
			StoreToAddress(mv + view_as<Address>(0x9C + 0x8), view_as<int>(origin[2]), NumberType_Int32);
		}
	}
	return MRES_Ignored;
}

void GetGroundPosition(int client, float origin[3], float out[3])
{
	float originBelow[3], landingMins[3], landingMaxs[3];
	GetEntPropVector(client, Prop_Data, "m_vecMins", landingMins);
	GetEntPropVector(client, Prop_Data, "m_vecMaxs", landingMaxs);

	originBelow[0] = origin[0];
	originBelow[1] = origin[1];
	originBelow[2] = origin[2] - 2.0;

	TR_TraceHullFilter(origin, originBelow, landingMins, landingMaxs, MASK_PLAYERSOLID, PlayerFilter, client);
	if(!TR_DidHit())
		return;

	TR_GetEndPosition(out, null);
}

// Haze Logic -----

//Thanks MARU for the idea/http://steamcommunity.com/profiles/76561197970936804 | comment from Haze
float GetGroundUnits(int client)
{
	if (!IsPlayerAlive(client) || GetEntityMoveType(client) != MOVETYPE_WALK || GetEntProp(client, Prop_Data, "m_nWaterLevel") > 1)
		return 0.0;

	float origin[3], originBelow[3], landingMins[3], landingMaxs[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", origin);
	GetEntPropVector(client, Prop_Data, "m_vecMins", landingMins);
	GetEntPropVector(client, Prop_Data, "m_vecMaxs", landingMaxs);

	originBelow[0] = origin[0];
	originBelow[1] = origin[1];
	originBelow[2] = origin[2] - 2.0;

	TR_TraceHullFilter(origin, originBelow, landingMins, landingMaxs, MASK_PLAYERSOLID, PlayerFilter, client);

	if(TR_DidHit())
	{
		TR_GetEndPosition(originBelow, null);
		float defaultheight = originBelow[2] - RoundToFloor(originBelow[2]);

		if(defaultheight > 0.03125)
			defaultheight = 0.03125;

		float heightbug = origin[2] - originBelow[2] + defaultheight;
		return heightbug;
	}
	else
	{
		return 0.0;
	}
}

public bool PlayerFilter(int entity, int mask)
{
	return !(1 <= entity <= MaxClients);
}
