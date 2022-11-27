{smcl}
{* *! version 1.0.0  21august2022}{...}
{viewerdialog compress "dialog compress"}{...}
{vieweralsosee "[D] compress" "mansection D compress"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[D] Data types" "help data_types"}{...}
{vieweralsosee "[D] recast" "help recast"}{...}
{viewerjumpto "Syntax" "compress##syntax"}{...}
{viewerjumpto "Description" "compress##description"}{...}
{viewerjumpto "Links to PDF documentation" "compress##linkspdf"}{...}
{viewerjumpto "Option" "compress##option"}{...}
{viewerjumpto "Remarks" "compress##remarks"}{...}
{viewerjumpto "Example" "compress##example"}{...}
{viewerjumpto "Video example" "compress##video"}{...}
{p2colset 1 17 19 2}{...}
{p2col:{bf:supercompress} {hline 2} Compress all datasets throughout a folder and its subfolders}{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

	{cmd:supercompress}{cmd:,} {opt top:level}{cmd:(}{it:filepath}{cmd:)}


{marker description}{...}
{title:Description}

{pstd}
{opt supercompress} attempts to reduce the amount of memory used by your data by running {opt compress} on every Stata dataset it can find within the filepath you specify in the toplevel option. This includes all datasets directly within your top level filepath and all datasets within all subfolders of your top level filepath, including subfolders of subfolders and so on.

{pstd}
This command finds every file within {cmd: toplevel} and its subfolders, opens each one individually, runs {cmd: compress} on it, and then saves the file. As such, if you maintain massive drives with lots of folders (like the collaborative Record Linking Lab shared network drive this program was designed for), this will probably take quite a while to run.

{pstd}
Because this program resaves the files, it updates the "Last Modified" date on every file, so if you rely on "Last Modified" dates to organize your data, don't use this command until you have another way to organize it.

{pstd}
I also do not have the programming skills to have {cmd: supercompress} tell you whether there was an error and stuff broke or whether it actually didn't save any data. Both of those return 0 bytes saved in all cases I've tested.

{marker option}{...}
{title:Option}

{phang}
{cmd:toplevel} requires a string filepath within its parentheses. It does not require double quotes within the parentheses unless the filepath has a space in it.


{marker remarks}{...}
{title:Remarks}

{pstd}
Sorry about making you type toplevel as an option. I couldn't figure out a way to make it run on just a filepath. This is my first custom program for Stata, so send any feedback you have to labhours@tmorg.org and it will be very appreciated!