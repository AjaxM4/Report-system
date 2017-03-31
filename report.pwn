/*
	Author: AjaxM
	Date Created: 02/02/2017
	Time Took in creating: 30 Minutes (Includes Testing)
*/
#include <a_samp>
#include <a_mysql>
#include <i-zcmd>
#include <sscanf2>

// *** COLOUR DEFINES
#define RED 0xFF0000FF
#define USAGE 0x33CCFFAA
// *** VARIABLES
new ReportCoL[MAX_PLAYERS];
new mysql;
// ** FORWARDS & PUBLICS
forward RepCo(playerid);
forward AddReport(playerid);
public RepCo(playerid)
{
    ReportCoL[playerid] = 0;
    return 1;
}
public AddReport(playerid)
{
    new reportid;
    reportid = cache_insert_id();
    printf("Report ID %d added to reports table! [Reporter: %s]", reportid, rpN(playerid));
    return 1;
}
// *** MYSQL Configurations
#define    MYSQL_HOST        "localhost" // Host
#define    MYSQL_USER        "" // User
#define    MYSQL_DATABASE    "" // Database
#define    MYSQL_PASSWORD    "" // Password

// *** START OF MAIN SCRIPT

public OnFilterScriptInit()
{
    // 'Load' message

    print("\n----------------------------------");
    print("aReport System by AjaxM - Loaded!\n");
    print("----------------------------------\n");

    // MySQL - Printing Errors & Connections
    mysql_log(LOG_ALL);
    mysql = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_DATABASE, MYSQL_PASSWORD);
    if(mysql_errno() != 0)
    {
        printf("[MySQL] The connection has failed.");
    }
    else
    {
        printf("[MySQL] The connection was successful.");
    }
	return 1;
}

public OnPlayerConnect(playerid)
{
    ReportCoL[playerid] = 0; // In case it sets random values
    return 1;
}

//Report system
CMD:report(playerid, params[])
{
    if(ReportCoL[playerid] == 1) return SendClientMessage(playerid, RED, "Error: You had just reported a player!");
    new str[111], str2[20], when[50], id, rep_hr, rep_min, rep_sec, rep_month, rep_days, rep_years, query[628];
    if(sscanf(params, "us[20]", id, str2)) return SendClientMessage(playerid, USAGE,"Usage: /report [ID] [Reason]");
    if(!IsPlayerConnected(id)) return SendClientMessage(playerid, 0xFF0000FF, "Error: That player is not connected!");
    if(strlen(str2) < 5 || strlen(str2) > 20) return SendClientMessage(playerid, RED, "Error: Minimum: 5 || Maximum: 20 Characters!");
    if(playerid == id) return SendClientMessage(playerid, 0xFF0000FF, "Error: You can't complain yourself!");
    ReportCoL[playerid] = 1;
    SetTimerEx("RepCo", 60000, false, "i", playerid);
    format(str, sizeof(str), "[REPORT] Player %s reported %s! [Reason: %s]", rpN(playerid), rpN(id), str2);
    for(new i = 0; i < MAX_PLAYERS ; i++)
    {
        if(IsPlayerAdmin(i))
        {
            SendClientMessage(i, RED, str);
        }
    }
    SendClientMessage(playerid, 0xFFFF00AA, "|- Your report has been sent to online administrators -|");
    // Saving the report
    gettime(rep_hr, rep_min, rep_sec);
    getdate(rep_years, rep_month, rep_days);
    format(when, 128, "%02d/%02d/%d %02d:%02d:%02d", rep_month, rep_days, rep_years, rep_hr, rep_min, rep_sec);
    mysql_format(mysql, query, sizeof(query), "INSERT INTO `Reports` (`Reporter`, `Reported`, `ReportedOn`, `ReportReason`) VALUES ('%e', '%e', '%e', '%e')", rpN(playerid), rpN(id), when, str2);
    mysql_tquery(mysql, query, "AddReport");
    return 1;
}

// Check Reports
CMD:reports(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return 0;
    new str[128], Cache:reports;
    mysql_format(mysql, str, sizeof(str), "SELECT * FROM `Reports`");
    reports = mysql_query(mysql, str, true);
    new count = cache_num_rows();
    if(count > 0)
    {
     SendClientMessage(playerid, USAGE, "Reports:");
        for(new i = 0; i < count; i++)
        {
            new reporter[25], reported[25], reportid, reportedon[25], reportreason[25], showreps[450];
            reportid = cache_get_field_content_int(i, "ReportID");
            cache_get_field_content(i, "Reporter", reporter);
            cache_get_field_content(i, "Reported", reported);
            cache_get_field_content(i, "ReportedOn", reportedon);
            cache_get_field_content(i, "ReportReason", reportreason);
            format(showreps, sizeof(showreps), "[#%d] (%s) %s has reported %s! [Reason: %s]", reportid, reportedon, reporter, reported, reportreason);
            SendClientMessage(playerid, RED, showreps);
        }
    }
    else return SendClientMessage(playerid, RED, "There are currently no reports!");
    cache_delete(reports);
    return 1;
}

// Delete report
CMD:delrep(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return 0;
    new str[128], Cache:delrep, repid;
    if(sscanf(params, "i", repid)) return SendClientMessage(playerid, USAGE, "Usage: /delrep [Report ID]");
    mysql_format(mysql, str, sizeof(str), "SELECT * FROM `Reports` WHERE `ReportID` = '%d'", repid);
    delrep = mysql_query(mysql, str, true);
    new count = cache_num_rows();
    if(count > 0)
    {
	mysql_format(mysql, str, sizeof(str), "DELETE FROM `Reports` WHERE `ReportID` = '%d'", repid);
	mysql_query(mysql, str, false);
	format(str, sizeof(str), "You have deleted a report! [#%d]", repid);
	SendClientMessage(playerid, RED, str);
    }
    else return SendClientMessage(playerid, RED, "Report ID not found!");
    cache_delete(delrep);
    return 1;
}

// Delete all reports
CMD:delallrep(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return 0;
    new str[128], Cache:delrep;
    mysql_format(mysql, str, sizeof(str), "SELECT * FROM `Reports`");
    delrep = mysql_query(mysql, str, true);
    new count = cache_num_rows();
    if(count > 0)
    {
	mysql_format(mysql, str, sizeof(str), "DELETE FROM `Reports`");
	mysql_query(mysql, str, false);
	format(str, sizeof(str), "You have deleted all reports! (Total Reports: %d)", rpN(playerid), count);
	SendClientMessage(playerid, RED, str);
    }
    else return SendClientMessage(playerid, RED, "There are currently no reports to delete!");
    cache_delete(delrep);
    return 1;
}


// *** MISC

rpN(playerid)
{
    new pN[MAX_PLAYER_NAME];
    GetPlayerName(playerid, pN, sizeof(pN));
    return pN;
}
