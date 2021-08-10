{smcl}
{* 18mar2016}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
{vieweralsosee "elfs" "elfs"}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf: elfs sql} {hline 2} SQL Settings


{title:Description}

{pstd}For this group, each {bf:record} is a different kind of setting.

{title:Records}

{phang}{cmd:Default driver} is used in the {help sql path} when an explicit server address is supplied without an explicit driver.

{phang}{cmd:Default schema} is used in the {help sql path} when a schema is required and no other value is found.

{phang}{cmd:Default owner} is used when creating schemas. {hi:%db%} will be replaced with the name of the current database. To use the server default value, set this to empty.{p_end}

{title:Links}

{phang}{cmd:Delete} deletes a user-added setting.

{phang}{cmd:Edit All} opens a data editor where all the settings can be edited.


