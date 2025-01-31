#include <sdktools>
#include <sdkhooks>
#include <shavit/core>
#include <clientprefs>

#pragma semicolon 1

public Plugin myinfo = 
{
	name = "LandFix",
	author = "Haze, nimmy, ta de hack ctz",
	description = "Modified Landfix plugin that saves players settings and has a toggleable HUD.",
	version = "1.1",
	url = ""
}

#define CHERRY 0
#define HAZE 1

int gI_TicksOnGround[MAXPLAYERS + 1];
int gI_Jump[MAXPLAYERS + 1];
int gI_HudPosition[MAXPLAYERS + 1];
float gF_HudPositionX[MAXPLAYERS + 1];
float gF_HudPositionY[MAXPLAYERS + 1];
float gF_HudTimerDuration = 0.5;

bool gB_LandfixType[MAXPLAYERS + 1] = {true, ...}; // initializing this as true will always start as HAZE lfType
bool gB_Enabled[MAXPLAYERS+1] = {false, ...};
bool gB_UseHud[MAXPLAYERS+1] = {true, ...};

new gI_HudTimerID[MAXPLAYERS + 1];
new iLastValidID[MAXPLAYERS + 1];
new Handle:g_hudTimers[MAXPLAYERS + 1] = { null };

Cookie g_cEnabledCookie;
Cookie g_cUseHudCookie;
Cookie g_cHudPositionCookie;

public void OnPluginStart()
{
    // Toggle Landfix
    RegConsoleCmd("sm_landfix", Command_LandFix, "Landfix");
    RegConsoleCmd("sm_lfix", Command_LandFix, "Landfix");
    RegConsoleCmd("sm_lf", Command_LandFix, "Landfix");
    RegConsoleCmd("sm_land", Command_LandFix, "Landfix");
    RegConsoleCmd("sm_64fix", Command_LandFix, "Landfix");
    RegConsoleCmd("sm_64", Command_LandFix, "Landfix");
    
    // Toggle Landfix HUD
    RegConsoleCmd("sm_landfixhud", Command_LandFixHud, "LandfixHud");
    RegConsoleCmd("sm_lfhud", Command_LandFixHud, "LandfixHud");
    RegConsoleCmd("sm_landhud", Command_LandFixHud, "LandfixHud");
    RegConsoleCmd("sm_lhud", Command_LandFixHud, "LandfixHud");
    
    // Change HUD Position
    RegConsoleCmd("sm_lfhp", Command_LandFixHudPos, "LandfixHudPos");
    RegConsoleCmd("sm_lfhudpos", Command_LandFixHudPos, "LandfixHudPos");
    RegConsoleCmd("sm_lfhudposition", Command_LandFixHudPos, "LandfixHudPos");
    
    HookEvent("player_jump", PlayerJump);
    
    // Cookies
    g_cEnabledCookie = new Cookie("landfix_enabled", "Landfix enabled state", CookieAccess_Protected);
    g_cUseHudCookie = new Cookie("landfix_hud", "Landfix HUD enabled state", CookieAccess_Protected);
    g_cHudPositionCookie = new Cookie("landfix_hud_position", "Landfix HUD position state", CookieAccess_Protected);

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
}

public void OnClientCookiesCached(int client)
{
    if (IsFakeClient(client))
        return;

    char buffer[8];

    // Load Landfix enabled cookie
    g_cEnabledCookie.Get(client, buffer, sizeof(buffer));
    gB_Enabled[client] = (buffer[0] != '\0' && StringToInt(buffer) == 1);

    if (buffer[0] == '\0')
        g_cEnabledCookie.Set(client, "0");

    // Load HUD enabled cookie
    g_cUseHudCookie.Get(client, buffer, sizeof(buffer));
    gB_UseHud[client] = (buffer[0] != '\0' && StringToInt(buffer) == 1);

    if (buffer[0] == '\0')
        g_cUseHudCookie.Set(client, "1");

    if (gB_UseHud[client] && gB_Enabled[client])
    {
        gI_HudTimerID[client]++;
        iLastValidID[client] = gI_HudTimerID[client];        
        g_hudTimers[client] = CreateTimer(gF_HudTimerDuration, Timer_ShowHudText, client, TIMER_REPEAT);
    }
    
    // Load HUD position cookie
    g_cHudPositionCookie.Get(client, buffer, sizeof(buffer));
    
    if (buffer[0] == '\0')
    {
    	gI_HudPosition[client] = 0;
    	g_cHudPositionCookie.Set(client, "0");
    	
    	gF_HudPositionX[client] = 0.01;
    	gF_HudPositionY[client] = 0.16;
    }
    else
    	gI_HudPosition[client] = StringToInt(buffer);
    	
    SetHudPosition(client);
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_GroundEntChangedPost, OnGroundChange);
    
    // Force Landfix Type to use Haze's on connect
    gB_LandfixType[client] = true;
    
    gI_Jump[client] = 0;

    // Load player cookies
    OnClientCookiesCached(client);
}

public void OnClientDisconnect(int client)
{
    if (g_hudTimers[client] != null)
    {
        KillTimer(g_hudTimers[client]);
        g_hudTimers[client] = null;
    }
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	if(!IsClientConnected(client) || !IsPlayerAlive(client) || IsFakeClient(client) || !gB_Enabled[client])
	{
		return Plugin_Continue;
	}

	if(GetEntityFlags(client) & FL_ONGROUND)
	{
		if(gI_TicksOnGround[client] > 15)
		{
			gI_Jump[client] = 0;
		}
		gI_TicksOnGround[client]++;

		if(buttons & IN_JUMP && gI_TicksOnGround[client] == 1)
		{
			gI_TicksOnGround[client] = 0;
		}
	}
	else
	{
		gI_TicksOnGround[client] = 0;
	}

	return Plugin_Continue;
}

public PlayerJump(Handle event, const char[] name, bool dontBroadcast)
{
	int userid = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userid);

	if(!gB_Enabled[client] || gB_LandfixType[client] == view_as<bool>(HAZE))
	{
		return;
	}

	if(IsFakeClient(client))
	{
		return;
	}

	if(gB_Enabled[client])
	{
		gI_Jump[client]++;
		if(gI_Jump[client] > 1)
		{
			CreateTimer(0.1, TimerFix, client);
		}
	}
}

public void OnGroundChange(int client)
{
	if(!gB_Enabled[client])
	{
		return;
	}

	if(gB_LandfixType[client])
	{
		RequestFrame(DoLandFix, client);
	}
}

// Deprecated LandFixType Command:
public Action Command_LandFixType(int client, int args) 
{
	if(client == 0)
	{
		return Plugin_Handled;
	}

	gB_LandfixType[client] = !gB_LandfixType[client];
	Shavit_PrintToChat(client, "Landfix Type: %s.", gB_LandfixType[client] ? "Haze" : "Cherry");
	return Plugin_Handled;
}

public Action Command_LandFixHud(int client, int args) 
{
    if (client == 0)
        return Plugin_Handled;

    gB_UseHud[client] = !gB_UseHud[client];
    Shavit_PrintToChat(client, "Landfix Hud: %s", gB_UseHud[client] ? "On" : "Off");
    
    // Save the new HUD enabled state in the cookie
    char buffer[2];
    Format(buffer, sizeof(buffer), "%d", gB_UseHud[client]);
    g_cUseHudCookie.Set(client, buffer);

    if (!gB_UseHud[client] && gB_Enabled[client])
    {
        if (g_hudTimers[client] != null)
        {
            KillTimer(g_hudTimers[client]);
            g_hudTimers[client] = null;
        }

        SetHudTextParams(gF_HudPositionX[client], gF_HudPositionY[client], 0.0, 0, 0, 0, 0, 0.0, 0.0, 0);
        ShowHudText(client, -1, " ");
    }
    else if (gB_UseHud[client] && gB_Enabled[client])
    {
        if (g_hudTimers[client] != null)
        {
            KillTimer(g_hudTimers[client]);
            g_hudTimers[client] = null;
        }

        gI_HudTimerID[client]++;
        iLastValidID[client] = gI_HudTimerID[client];        
        g_hudTimers[client] = CreateTimer(gF_HudTimerDuration, Timer_ShowHudText, client, TIMER_REPEAT);
    }

    return Plugin_Handled;
}

public Action Command_LandFixHudPos(int client, int args)
{
	if (args < 1)
	{
		Shavit_PrintToChat(client, "Choose a position from 0 to 2, example: /lfhudpos 1");
		Shavit_PrintToChat(client, "Current Landfix Hud position: %d", gI_HudPosition[client]);
		return Plugin_Handled;
	}
	
	char arg[2];
    GetCmdArg(1, arg, sizeof(arg));
    int hudPosition = StringToInt(arg);
	
	if (hudPosition < 0 || hudPosition > 2)
	{
		Shavit_PrintToChat(client, "Choose a position from 0 to 2, example: /lfhudpos 1");
		Shavit_PrintToChat(client, "Current Landfix Hud position: %d", gI_HudPosition[client]);
		return Plugin_Handled;
	}
	
	gI_HudPosition[client] = hudPosition;
	SetHudPosition(client);
	
	char buffer[2];
	Format(buffer, sizeof(buffer), "%d", gI_HudPosition[client]);
	g_cHudPositionCookie.Set(client, buffer);

	Shavit_PrintToChat(client, "Landfix Hud position set to: %d", hudPosition);
	//Shavit_PrintToChat(client, "Exact Landfix Hud Position: X: %.3f | Y: %.3f", gF_HudPositionX[client], gF_HudPositionY[client]);

	return Plugin_Handled;
}

void SetHudPosition(int client)
{
	// Top Left
	if (gI_HudPosition[client] == 0)
	{
		gF_HudPositionX[client] = 0.01;
		gF_HudPositionY[client] = 0.16;
	}
	// Top Right
	else if (gI_HudPosition[client] == 1)
	{
		gF_HudPositionX[client] = 0.895;
		gF_HudPositionY[client] = 0.01;
	}
	// Top Center
	else if (gI_HudPosition[client] == 2)
	{
		gF_HudPositionX[client] = 0.453;
		gF_HudPositionY[client] = 0.01;
	}
}

public Action Command_LandFix(int client, int args) 
{
    if (client == 0)
        return Plugin_Handled;

    gB_Enabled[client] = !gB_Enabled[client];
    Shavit_PrintToChat(client, "Landfix: %s", gB_Enabled[client] ? "On" : "Off");
    
    // Save the new Landfix enabled state in the cookie
    char buffer[2];
    Format(buffer, sizeof(buffer), "%d", gB_Enabled[client]);
    g_cEnabledCookie.Set(client, buffer);

    if (gB_Enabled[client])
    {
        if (g_hudTimers[client] != null)
        {
            KillTimer(g_hudTimers[client]);
            g_hudTimers[client] = null;
        }
	
		if (gB_UseHud[client])
		{
			gI_HudTimerID[client]++;
	        iLastValidID[client] = gI_HudTimerID[client];        
	        g_hudTimers[client] = CreateTimer(gF_HudTimerDuration, Timer_ShowHudText, client, TIMER_REPEAT);
		}
    }
    else 
    {
        // Stop the HUD timer when disabling LandFix - if HUD is On
        if (gB_UseHud[client])
        {
        	if (g_hudTimers[client] != null)
        	{
	            KillTimer(g_hudTimers[client]);
	            g_hudTimers[client] = null;
        	}
        }
    }

    return Plugin_Handled;
}

public Action Timer_ShowHudText(Handle timer, any client) 
{
    if (!IsClientInGame(client) || !gB_Enabled[client] || !gB_UseHud[client]) 
        return Plugin_Stop;

    if (gI_HudTimerID[client] != iLastValidID[client])
        return Plugin_Stop;

    SetHudTextParams(gF_HudPositionX[client], gF_HudPositionY[client], gF_HudTimerDuration, 255, 255, 255, 255, 0.0, 0.0, 0);
    ShowHudText(client, -1, "Landfix: On");

    return Plugin_Continue;
}

//Thanks MARU for the idea/http://steamcommunity.com/profiles/76561197970936804
float GetGroundUnits(int client)
{
	if (!IsPlayerAlive(client) || GetEntityMoveType(client) != MOVETYPE_WALK || GetEntProp(client, Prop_Data, "m_nWaterLevel") > 1)
	{
		return 0.0;
	}

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
		{
			defaultheight = 0.03125;
		}

		float heightbug = origin[2] - originBelow[2] + defaultheight;
		return heightbug;
	}
	else
	{
		return 0.0;
	}
}

void DoLandFix(int client)
{
	if(GetEntPropEnt(client, Prop_Data, "m_hGroundEntity") != -1)
	{
		float difference = (1.50 - GetGroundUnits(client)), origin[3];
		GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", origin);
		origin[2] += difference;
		SetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", origin);
	}
}

Action TimerFix(Handle timer, any client)
{
	float cll[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", cll);
	cll[2] += 1.0;
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, cll);

	CreateTimer(0.05, TimerFix2, client);
	return Plugin_Handled;
}

Action TimerFix2(Handle timer, any client)
{
	if(!(GetEntityFlags(client) & FL_ONGROUND))
	{
		float cll[3];
		GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", cll);
		cll[2] -= 1.5;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, cll);
	}
	return Plugin_Handled;
}

public bool PlayerFilter(int entity, int mask)
{
	return !(1 <= entity <= MaxClients);
}
