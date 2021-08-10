{smcl}
{* 21dec2013}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf: elfs} {hline 2} Manage [el file] settings

{title:Sub-commands}

{p2colset 5 22 22 2}{...}
{p2col:{stata elfs misc, help:elfs misc}}Miscellaneous{p_end}
{p2col:{stata elfs startup, help:elfs startup}}Settings at startup{p_end}
{p2col:{stata elfs instance, help:elfs instance}}IDs and Preferences for multiple instances{p_end}
{p2col:{stata elfs callst, help:elfs callst}}StatTransfer path and default configuration{p_end}
{p2col:{stata elfs colors, help:elfs colors}}Color Schemes for the Results & Viewer windows{p_end}
{p2col:{stata elfs outhtml, help:elfs outhtml}}Schemes for {opt out()} to html{p_end}
{p2col:{stata elfs outemail, help:elfs outemail}}Schemes for {opt out()} to html, email{p_end}
{p2col:{stata elfs outstata, help:elfs outstata}}Schemes for {opt out()} to Stata{p_end}
{p2col:{stata elfs facts, help:elfs facts}}File actions/associations (icons, open commands, etc.){p_end}
{p2col:{stata elfs sql, help:elfs sql}}SQL settings{p_end}


{title:Description}

{pstd}{cmd:elfs} is a general command for managing user settings. Each sub-command will list the relevant settings, and produce links that can be used to manage them.

{pstd}When editing the settings in the data-editor, any built-in settings that are modified will be saved as user-defined settings. For settings with the same name/id, the user-defined version takes precedence.

