#include <sdktools>
#include <sdkhooks>
#include <shavit/core>
#include <clientprefs>

#pragma semicolon 1

public Plugin myinfo = {
	name = "LandFix",
	author = "Haze, nimmy, ta de hack ctz",
	description = "",
	version = "1.1",
	url = ""
}

#define CHERRY 0
#define HAZE 1

int gI_TicksOnGround[MAXPLAYERS + 1];
int gI_Jump[MAXPLAYERS + 1];

bool gB_LandfixType[MAXPLAYERS + 1] = {true, ...}; // initializing this as true will always start as HAZE lfType
bool gB_Enabled[MAXPLAYERS+1] = {false, ...};
bool gB_UseHud[MAXPLAYERS+1] = {true, ...};

new gI_HudTimerID[MAXPLAYERS + 1];
new iLastValidID[MAXPLAYERS + 1];
new Handle:g_hudTimers[MAXPLAYERS + 1] = { null };

Cookie g_cEnabledCookie;
Cookie g_cUseHudCookie;

public void OnPluginStart()
{
    // Toggle Landfix
    RegConsoleCmd("sm_landfix", Command_LandFix, "Landfix");
    RegConsoleCmd("sm_lfix", Command_LandFix, "Landfix");
    RegConsoleCmd("sm_lf", Command_LandFix, "Landfix");
    RegConsoleCmd("sm_land", Command_LandFix, "Landfix");
    RegConsoleCmd("sm_64fix", Command_LandFix, "Landfix");
    RegConsoleCmd("sm_64", Command_LandFix, "Landfix");
    
    // Toggle Landfix Hud
    RegConsoleCmd("sm_landfixhud", Command_LandFixHud, "LandfixHud");
    RegConsoleCmd("sm_lfhud", Command_LandFixHud, "LandfixHud");
    RegConsoleCmd("sm_landhud", Command_LandFixHud, "LandfixHud");
    RegConsoleCmd("sm_lhud", Command_LandFixHud, "LandfixHud");
    
    HookEvent("player_jump", PlayerJump);
    
    g_cEnabledCookie = new Cookie("landfix_enabled", "Landfix enabled state", CookieAccess_Protected);
    g_cUseHudCookie = new Cookie("landfix_hud", "Landfix HUD enabled state", CookieAccess_Protected);

    for(int client = 1; client <= MaxClients; client++)
    {
        if(IsClientInGame(client) && !IsFakeClient(client))
        {
            OnClientPutInServer(client);
            
            if (AreClientCookiesCached(client))
                OnClientCookiesCached(client);
                
            // This if statement is probably not needed but idk man, the plugin is working and i'm kinda lazy rn
            if (gB_UseHud[client] && gB_Enabled[client])
		    {
		        gI_HudTimerID[client]++;
		        iLastValidID[client] = gI_HudTimerID[client];        
		        g_hudTimers[client] = CreateTimer(1.0, Timer_ShowHudText, client, TIMER_REPEAT);
		    }
        }
    }

    AutoExecConfig();
}

public void OnClientCookiesCached(int client)
{
    if (IsFakeClient(client))
        return;

    char buffer[8];

    // Load Landfix enabled state from the cookie
    g_cEnabledCookie.Get(client, buffer, sizeof(buffer));
    gB_Enabled[client] = (StringToInt(buffer) == 1);

    // Load HUD enabled state from the cookie
    g_cUseHudCookie.Get(client, buffer, sizeof(buffer));
    gB_UseHud[client] = (StringToInt(buffer) == 1);
    
    if (gB_UseHud[client] && gB_Enabled[client])
    {
        gI_HudTimerID[client]++;
        iLastValidID[client] = gI_HudTimerID[client];        
        g_hudTimers[client] = CreateTimer(1.0, Timer_ShowHudText, client, TIMER_REPEAT);
    }
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_GroundEntChangedPost, OnGroundChange);
    gI_Jump[client] = 0;
    gB_Enabled[client] = false;
    
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
    buffer[0] = view_as<char>(gB_UseHud[client]) + '0';
    g_cUseHudCookie.Set(client, buffer);

    if (!gB_UseHud[client] && gB_Enabled[client])
    {
        if (g_hudTimers[client] != null)
        {
            KillTimer(g_hudTimers[client]);
            g_hudTimers[client] = null;
        }

        SetHudTextParams(0.895, 0.01, 0.0, 0, 0, 0, 0, 0.0, 0.0, 0);
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
        g_hudTimers[client] = CreateTimer(1.0, Timer_ShowHudText, client, TIMER_REPEAT);
    }

    return Plugin_Handled;
}

public Action Command_LandFix(int client, int args) 
{
    if (client == 0)
        return Plugin_Handled;

    gB_Enabled[client] = !gB_Enabled[client];
    Shavit_PrintToChat(client, "Landfix: %s", gB_Enabled[client] ? "On" : "Off");
    
    // Save the new Landfix enabled state in the cookie
    char buffer[2];
    buffer[0] = view_as<char>(gB_Enabled[client]) + '0';
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
	    	g_hudTimers[client] = CreateTimer(1.0, Timer_ShowHudText, client, TIMER_REPEAT);
        }
    }
    else 
    {
        // Stop the HUD timer when disabling LandFix
        if (g_hudTimers[client] != null)
        {
            KillTimer(g_hudTimers[client]);
            g_hudTimers[client] = null;
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

    SetHudTextParams(0.895, 0.01, 1.0, 255, 255, 255, 255, 0.0, 0.0, 0);
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
