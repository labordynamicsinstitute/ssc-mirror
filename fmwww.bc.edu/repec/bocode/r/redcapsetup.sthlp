{smcl}
{* *! version 1.0  2026-04-21 Mark Chatfield}{...}

{title:Title}

{phang}
{bf:redcapsetup} {hline 2} perform some checks on the setup of a REDCap database


{marker examples}{...}
{title:Example}

{pstd}Change the working directory to where you have stored the setup csv files, then run {cmd:redcapsetup}{p_end}	
{phang2}{sf:. cd "H:/ProjectX/REDCap setup csv files"}{p_end}
{phang2}{sf:. }{stata `"redcapsetup"'}{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:redcapsetup} performs some checks on the setup of a REDCap database (checks which REDCap does not perform).

{pstd}The following csv files are required in the working directory:{p_end}
{phang2}i)  *DataDictionary*.csv{p_end}
{phang2}ii) *InstrumentDesignations*.csv  ...within the "Project Setup" section, download from "Designate Instruments for My Events"{p_end}

{pstd}The following csv files are optional:{p_end}
{phang2}iii)  fdl_*.csv  ...within "Online Designer", download from "Form Display Logic"{p_end}
{phang2}iv) asi_*.csv   ...within "Online Designer", download all Automated Survey Invitations settings from "Auto Invitation options"{p_end}
{phang2}v) *Alerts_*.csv  ...download from the "Alerts & Notifications" Application{p_end}

{pstd}
{cmd:redcapsetup} checks for:{p_end}
{phang 4} * instances of [obviously-wrong-eventname][variablename]{p_end}
{phang 4} * instances of [variablename] which might need to be [eventname][variablename]{p_end}
{phang 4} * references to [non-existent variablename]{p_end}
{phang 4} * invalid names/correspondence between the key form column & event column in: Form Display Logic, Automated Survey Invitations, Alerts{p_end}



{marker explanation}{...}
{title:Detail}

{pstd}
{cmd:redcapsetup} extracts contents inside square brackets from the columns of each csv file.
Often this will be a variablename that appears in the Data Dictionary (DD). Sometimes it will be an eventname.
Sometimes it will be a {browse "https://kb.wisc.edu/smph/informatics/88571":"smart variable"}.
Note, smart variables (and other contents with a hyphen) are ignored.
Sometimes it may be other things such as units if text like "[kg]" appears in the DD. 
The user is told about rows which may be a problem, making it easy for the user to find any problem cell(s) on those rows.  

{pstd}
{ul:Checks that are not performed}

{pstd}
There are many checks on the setup of a REDCap database that {cmd:redcapsetup} does not perform.
For example, checks are not performed to see if
e.g. 'baseline_arm_1' in "if([event-name]='baseline_arm_1')" is an eventname because 'baseline_arm_1' is not in square brackets.
Checks are not performed on inactive Automated Survey Invitations settings or deactivated Alerts.


 

{marker author}{...}
{title:Author}

{p 4 4 2}
Mark Chatfield, The University of Queensland, Australia.{break}
m.chatfield@uq.edu.au{break}
