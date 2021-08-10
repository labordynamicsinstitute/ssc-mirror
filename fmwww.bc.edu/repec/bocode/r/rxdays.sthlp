{smcl}
{* 30jan2012}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
{vieweralsosee "rrc" "rrc"}{...}
{vieweralsosee "rxdose" "rxdose"}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf: rxdays} {hline 2} Find patients who are on drug therapy, based on days supplied

{title:Syntax}

{phang}{cmd:rxdays} {it:supply}{cmd:/}{it:window} [{it:options}]

{synoptset}
{synopthdr}
{synoptline}
{synopt :{opt f:rom(date)}}earliest date at which to begin a window{p_end}
{synopt :{opt to(date)}}latest date at which to end a window{p_end}
{synopt :{opth pt:id(varname)}}patient ids{p_end}
{synopt :{opth drug:id(varname)}}drug ids{p_end}
{synopt :{opth prdate(varname)}}prescription dates{p_end}
{synopt :{opth prdays(varname)}}prescription durations (ie, days supply){p_end}
{synoptline}

{title:Description}

{pstd}{cmd:rxdays} identifies patients with a minimum (days) supply of drugs in a specified number of days (window). It requires 4 variables in the datafile: patient-id, drug-id, prescription-date, and prescription-duration (days supply).

{pstd}If the variables are the first 4 in the dataset, and ordered as above, they don't need to be explicitly specified.

{pstd}{bf:NOTE} that the command {bf:replaces} the data in memory.

{title:Options}

{phang}{opt f:rom(date)} specifies the earliest date at which a patient can be found to be 'on therapy'. Earlier records {it:will} be used to calculate any existing carryover at {opt f:rom(date)}.

{pmore}It needs to be specified in month-day-year order.

{phang}{opt to(date)} specifies the latest date on which to consider drug supply. If {opt to()} is not specifed, windows for each patient will run to the end of their data.
When {opt to()} is specified, all patients have their final window ending on {opt to()}, which may make it shorter than the {it:window} specified on the command line.

{pmore}It needs to be specified as month-day-year order.

{phang}{opth pt:id(varname)} specifies the patient-id variable.

{phang}{opth drug:id(varname)} specifies the drug-id variable.

{phang}{opth prdate(varname)} specifies the prescription-date (fill date) variable. It needs to formatted as a Stata {it:date} (ie, an integer representing a number of days).

{phang}{opth prdays(varname)} specifies the prescription-duration (days supply) variable.


{title:Remarks}

{pstd}The data in memory will be replaced. The new dataset will have 3 variables: those specified in {opt pt:id()} and {opt drug:id()}, and {cmd:asof},
which will hold the first date on which the patient both {it:had the drug} and had it for the required portion of the following window.

{pstd}The data in memory will have one record for every combination of patient and drug in the original dataset. {cmd:asof} will be missing for combinations which never had the minimum {it:supply}/{it:window}.

