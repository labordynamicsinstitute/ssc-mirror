{smcl}
{* *! version 14  1oct2021}{...}
{findalias asfradohelp}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] help" "help pathmaker"}{...}
{viewerjumpto "Syntax" "pathmaker##syntax"}{...}
{viewerjumpto "Description" "pathmaker##description"}{...}
{viewerjumpto "Options" "pathmaker##options"}{...}
{viewerjumpto "Remarks" "pathmaker##remarks"}{...}
{viewerjumpto "Examples" "pathmaker##examples"}{...}
{title:Title}

{phang}
{bf:pathmaker} {hline 2} Sets global path variables using subfolder names.


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:pathmaker}
{it:input_folder}{cmd:,} [{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt i:gnore(subf_names)}}list of subfolder names to be ignored {p_end}
{synopt:{opt low}}names global variables using lowercase; default is case of subfolder {p_end}
{synopt:{opt b:ack}}uses backward slashes in path; default is forward slash {p_end}
{synoptline}
{p2colreset}{...}



{marker description}{...}
{title:Description}

{pstd}
{cmd:pathmaker} creates global path variables for each folder in 
			{it:input_folder}. Global variables are named using subfolder names.


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt ignore(subf_names)} ignores all subfolders provided in {it:subf_names}. Global path variables will not be provided for these subfolders.

{phang}
{opt low} uses lower case for naming all global variables. If not specified then the case of the subfolder is adopted.
				
{phang}
{opt back} uses backward slashes in all global path variables regardless of direction specified for {it:input_folder}.


{marker remarks}{...}
{title:Remarks}

{pstd}
Note that global paths will not be created for subfolders whose name cannot be assigned to a global path. A subfolder named "_oldfolder" will not be assigned to a global path variable as "_oldfolder" cannot be used to name a global variable. {it:input_folder} will be assigned to global path "root". If a subfolder has a space in its name the space will be removed for the global variance name. Note that to ignore folders with spaces in their names requires the use of '""' as illustrated in the example below.


{marker examples}{...}
{title:Examples}

{phang}{cmd:. pathmaker C:\Users\dofiles, low}{p_end}

{phang}{cmd:. pathmaker C:\Users\dofiles, b}{p_end}

{phang}{cmd:. pathmaker C:\Users\dofiles, i(folder1 folder2)}{p_end}

{phang}{cmd:. pathmaker C:\Users\dofiles, i(`""folder 1" "folder2""')}{p_end}

{marker author}{...}
{title:Author}

{pstd}Iain Snoddy{p_end}
{pstd}iainsnoddy@gmail.com{p_end}
