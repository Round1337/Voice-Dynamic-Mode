#include <cstrike>
#include <vdm_core>
#include <csgo_colors>
#include <PTaH>
#include <clientprefs>

#define FUNC_NAME       "clutch_mode_ptah"
#define FUNC_PRIORITY   10

int     g_iClutchMode;
bool    g_bClutchModeActive[MAXPLAYERS+1];
bool    g_bClutchMode[MAXPLAYERS+1];

Handle  hCookie;

public Plugin myinfo =
{
	name		=	"[VDM] Clutch Mode (PTaH Edition)",
	version		=	"1.0",
	author		=	"FIVE",
	url			=	"Source: http://hlmod.ru | Support: https://discord.gg/ajW69wN"
};

public void OnPluginStart()
{
    if(VDM_GetVersion() < 020000) SetFailState("VDM Core is older to use this module.");
    if(PTaH_Version() < 101000) SetFailState("PTaH is older to use this module.");
    
    PTaH(PTaH_ClientVoiceToPre, Hook, CVP);

    HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_PostNoCopy);
    HookEvent("round_end", Event_OnRoundEnd, EventHookMode_PostNoCopy);

    hCookie = RegClientCookie("VDM_ClutchMode", "VDM_ClutchMode", CookieAccess_Public);

    if(VDM_CoreIsLoaded()) VDM_OnCoreIsReady();
}

public void OnClientCookiesCached(int iClient)
{
    char szBuffer[4];
    GetClientCookie(iClient, hCookie, szBuffer, sizeof(szBuffer));

    if(szBuffer[0]) g_bClutchMode[iClient] = view_as<bool>(StringToInt(szBuffer));
    else g_bClutchMode[iClient] = false;
}

public void OnClientDisconnect(int iClient)
{
    if(g_bClutchMode[iClient]) SetClientCookie(iClient, hCookie, "1");
    else SetClientCookie(iClient, hCookie, "0");
}

public void OnPluginEnd()
{
	if (VDM_IsExistFeature(FUNC_NAME) && CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VDM_RemoveFeature") == FeatureStatus_Available)
	{
		VDM_RemoveFeature(FUNC_NAME);
	}
}

public void VDM_OnCoreIsReady()
{
	VDM_AddFeature(FUNC_NAME, FUNC_PRIORITY, MENUTYPE_SETTINGSMENU, OnItemSelectMenu, OnItemDisplayMenu, OnItemDrawMenu);
}

bool OnItemSelectMenu(int iClient)
{
	g_bClutchMode[iClient] = !g_bClutchMode[iClient];
	return true;
}

bool OnItemDisplayMenu(int iClient, char[] szDisplay, int iMaxLength)
{
	FormatEx(szDisplay, iMaxLength, "Режим Clutch [ %s ]", g_bClutchMode[iClient] ? "Вкл" : "Выкл");
	return true;
}

int OnItemDrawMenu(int iClient, int iStyle)
{
	return ITEMDRAW_DEFAULT;
}

public Action Event_OnPlayerDeath(Event hEvent, char[] name, bool dontBroadcast)
{
    int iCount_T, iCount_CT, iLastClientCT, iLastClientT;
    for(int i = 1; i <= MaxClients; i++)	if(IsClientInGame(i) && IsPlayerAlive(i))
    {
        switch(GetClientTeam(i))
        {
            case CS_TEAM_T: 
            {
                iLastClientT = i;
                iCount_T++;
            }
            case CS_TEAM_CT:
            { 
                iLastClientCT = i;
                iCount_CT++;
            }
        }
    }

    if(iCount_T == 0 || iCount_CT == 0) return;

    if(iCount_CT == 1) SetCluchMode(iLastClientCT);
    if(iCount_T == 1) SetCluchMode(iLastClientT);
}

void SetCluchMode(int iClient)
{
    if(!g_bClutchMode[iClient]) return;

    g_bClutchModeActive[iClient] = true;

    for(int i = 1; i <= MaxClients; i++)
    {
        if(iClient == i) CGOPrintToChat(i, "%t", "{LIGHTGREEN}[VDM] {DEFAULT}Вы остались одни. Теперь Вы не слышите %s игроков", g_iClutchMode == 1 ? "мертвых" : "всех");
        else CGOPrintToChat(i, "%t", "{LIGHTGREEN}[VDM] {DEFAULT}Игрок %N теперь не слышит %s игроков", iClient, g_iClutchMode == 1 ? "мертвых" : "всех");
    }
}

public void Event_OnRoundEnd(Event hEvent, char[] name, bool dontBroadcast) 
{ 
    for(int i = 1; i <= MaxClients; i++) g_bClutchModeActive[i] = false;
}

public Action CVP(int iClient, int iTarget, bool& bListen)
{
    if(!IsClientInGame(iClient) || !IsClientInGame(iTarget)) return Plugin_Continue;
    
    if(g_iClutchMode > 0 && g_bClutchMode[iTarget] && g_bClutchModeActive[iTarget])
    {
        if(g_iClutchMode == 0) return Plugin_Handled;
        if(g_iClutchMode == 1 && !IsPlayerAlive(iClient)) return Plugin_Handled;
    }

    return Plugin_Continue;
}