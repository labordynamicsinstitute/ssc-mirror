{smcl}
{* *! version 0.1.4  8 Nov 2022}{...}
{vieweralsosee "mpitb" "help mpitb"}{...}
{viewerjumpto "Syntax" "mpitb_show##syntax"}{...}
{viewerjumpto "Description" "mpitb_show##description"}{...}
{viewerjumpto "Options" "mpitb_show##options"}{...}
{viewerjumpto "Examples" "mpitb_show##examples"}{...}
{p2colset 1 15 17 2}{...}
{p2col:{bf:mpitb show} {hline 2}} display information about a particular MPI{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:mpitb show , }[{it:options}]

{synoptset 22 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt :{opt n:ame(mpiname)}}name of the MPI to show{p_end}
{synopt :{opt l:ist}}lists all available MPI specifications{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:mpitb show} displays information about MPIs stored with the current data, 
which may include name, description, dimensions and indicators of a particular MPI, 
as specified with {helpb mpitb set}. If weights have already been set by 
{cmd:mpitb setwgts} or {cmd:mpitb est}, this information is shown, too.{p_end}

{marker options}{...}
{title:Options}

{phang}
{opt n:ame(mpiname)} allows to specify the name of the particular MPI to be displayed 
in more detail.{p_end}

{phang}
{opt l:ist} lists name and description for all the available MPI specifications.{p_end}

{marker examples}
{title:Examples}

    {hline}
{pstd}Setup{p_end}

{phang2}{cmd: use ...}{p_end}
{phang2}{cmd: mpi set ... , name(mympi1) ...}{p_end}
{phang2}{cmd: mpi set ... , name(mympi2) ...}{p_end}

{pstd}
Now display information about the previously specified MPI:{p_end}

{phang2}
{cmd: mpitb show , name(mympi1)}{p_end}

{pstd}
Since weights are set using {cmd:mpi est}, this information can only be displayed
after running {cmd:mpi est}.{p_end}

{phang2}{cmd: mpi est ... , name(mympi1) ...}{p_end}
{phang2}{cmd: mpitb show , name(mympi1)}{p_end}

    {hline}

