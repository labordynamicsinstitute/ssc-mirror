{smcl}
{* 28aug2007}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
{vieweralsosee "cdl" "cdl"}{...}
{vieweralsosee "usel" "usel"}{...}
{vieweralsosee "savel" "savel"}{...}
{vieweralsosee "collect" "collect"}{...}
{vieweralsosee "sql" "sql"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "elfs misc" "elfs misc"}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf:recent} {hline 2} Recently used files and directories

{title:Syntax}

{phang}{cmd:recent} [{cmd:data}]

{phang}{cmd:recent} {{opt cdl} | {opt pr:oject} | {opt sql: path} | {opt oth:er data}}{p_end}

{title:Description}

{pstd}{cmd:recent} displays lists of recently used data and locations, of a few varieties. The lists are in chronological order, and include clickable links to switch to or use most of the locations/data sources.
The lists are remembered across Stata sessions, and are specific to stata instances, when {cmd:instance} is turned on using {stata elfs startup, help:elfs startup}.

{pstd}The {it:most} recent entry in the list is the {hi:current} one, which (except for {opt oth:er data}) plays a special role in most commands that use the data or locations.

{marker datasource}{title:Data Sources}

{pstd}{cmd:recent} [{cmd:data}] lists the {bf:current} and recent {bf:data sources}. The {bf:current data source} is, roughly, the most recently used external source of data; the commands that set the {bf:current data source} are:

{phang2}{cmd:usel}, always{p_end}
{phang2}{cmd:clearl}, always{p_end}
{phang2}{cmd:sql get}, always{p_end}
{phang2}{cmd:sqli} and {cmd:sql do}, when they download data{p_end}
{phang2}{cmd:collect}, when not appending{p_end}
{phang2}{cmd:savel}, when it saves all the data in memory to a stata file{p_end}

{pstd}{cmd:usel}, {cmd:savel}, and {cmd:collect} set the {bf:data source} to the (first) file that they use or save.
{cmd:clearl} sets the {bf:data source} to 'none', empty. {cmd:sql get} and {cmd:sql i} set it to the query they used.
{cmd:sql do} is similar to {cmd:clearl} {hline 2} it is identified as the current source of data, but the query isn't retained or reusable.

{pstd}{bf:{ul:Window Title}}

{pstd}When the {bf:current data source} is updated, the main window title is updated to reflect it. You can specify how the {bf:currrent data source} is reflected in the window title with {help elfs misc}.


{title:Directories}

{phang}{cmd:recent cdl} and {cmd:recent} {opt pr:oject} list recent working and {help cdl##project:project directories}, respectively, both of which are set with the {help cdl} command.

{phang}{cmd:recent }{opt sql: path} lists those, as described in {help sql path}.


{title:Other Data}

{phang}{cmd:recent} {opt oth:er data} lists recent data files other than recent {bf:data source}s. Specifically, data files used by {cmd:finddata}, {cmd:collect}, and {cmd:savel} (when saving partial datasets or foreign formats).

