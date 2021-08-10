{smcl}
{* 16dec2013}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
{vieweralsosee "elfs" "elfs"}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf:elfs instance} {hline 2} Settings for concurrent Stata instances
 

{title:Description}

{pstd}These settings are used to assign a unique {it:ID} to the each running instance of Stata, and to load preferences based on that ID.

{pstd}The main purpose of giving each instance an {it:ID} is to track all settings and ancillary files independently for each instance {hline 2} especially the current and recent data-sources and paths.
Without setting an {it:ID}, the most recently used file in {it:any} instance becomes the most recent for {it:all} instances.


{title:Fields}

{phang}{cmd:precedence} is the order in which to assign the ids & settings to the instances. That is, when you launch Stata, if the ID for {cmd:precedence 1} is not in use, it will be assigned to the new instance.
If it is already in use, {cmd:precdence 2} will be checked, etc.

{phang}{cmd:ID} is the ID assigned to the instance; it is included in the main window title, by default (as described in {stata "elfs misc, help":elfs misc}).

{phang}{cmd:Preference Set Name} is the name of a Stata Preference Set to load when the relevant ID is assigned. A {bf:Preference Set} with that name must have already been saved, ie: {cmd:Edit}->{cmd:Preferences}->{cmd:Save Preference Set}.


{title:Links}

{phang}{cmd:Edit All} opens a data editor with all the settings. After editing, be sure to use the {cmd:save} link.

{phang}{cmd:Delete} deletes a user-created setting.

{pstd}In order for these settings to have any effect, you must use {stata "elfs startup, help":elfs startup} to set {cmd:instance} to {cmd:on}.


{title:Remarks}

{pstd}Because of the way the {cmd:ID}s are assigned in order, you can create setups that are always initiated for your {ul:first} or {ul:second} instance, etc. For example, if you:

{phang2}1) save a {bf:preference set} named {cmd:instance_1} with window positions on the left side of the monitor, and standard colors{p_end}
{phang2}2) save a {bf:preference set} named  {cmd:instance_2} with window positions on the right side of the monitor, and alternate colors{p_end}
{phang2}3) use {stata "elfs startup, help":elfs startup} to set {cmd:instance} to {cmd:on}

{pstd}then, when you launch Stata the {ul:first} time, it will show up on the left with standard colors, and if you launch a {ul:second} copy, it will show up on the right with alternate colors.

{pstd}Furthermore, if you closed the {ul:first} one and relaunched stata, you'd get a new {ul:first}: on the left, standard colors, recent files etc. of the {ul:first} instance.
Same with closing the {ul:second} and relaunching.

{pstd}{stata "elfs colors, help":elfs colors} includes color sets that could be used to distinguish up to three instances. 
