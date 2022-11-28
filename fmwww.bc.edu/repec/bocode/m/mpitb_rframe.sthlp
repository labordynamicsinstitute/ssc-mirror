{smcl}
{* *! version 0.1.4  8 Nov 2022}{...}
{vieweralsosee "mpitb" "help mpitb"}{...}
{viewerjumpto "Syntax" "mpitb_rframe##syntax"}{...}
{viewerjumpto "Description" "mpitb_rframe##description"}{...}
{viewerjumpto "Options" "mpitb_rframe##options"}{...}
{viewerjumpto "Examples" "mpitb_rframe##examples"}{...}

{p2colset 1 17 18 2}{...}
{p2col:{bf:mpitb rframe} {hline 2}}setup the results frame{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd: mpitb rframe, frame(}{it:name}{cmd:)} [{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent :* {opt fr:ame(name)}}name of results frame{p_end}
{synopt:{opt replace}}potentially existing frame is replaced{p_end}
{synopt:{opt dou:ble}}generate core variables of the estimate as type {bf:double}{p_end}
{synopt:{opt t}}results frame for harmonised over time levels{p_end}
{synopt:{opt cot}}results frame for changes over time{p_end}
{synopt:{opt add(name)}}add string as value for extra variable{p_end}
{synopt:{opt ts}}add data and estimation time stamps{p_end}
{synoptline}
{p 4 6 2}* required options.{p_end}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd: mpitb rframe} prepares the result frames in which custom estimates may be 
stored and is intended for advanced users and programmers who wish to store custom 
quantities in separate result frames. Note that {helpb mpitb est} may create result 
frames as well.{p_end}

{pstd}
Result frames contain the variables needed for storing the core estimate, including
{it:b}, {it:se}, {it:ll}, {it:ul}, {it:pval}, {it:tval}. Moreover, result 
frames also contain variables holding meta information about content and context of an estimate, including 
{it:wgts}, {it:measure}, {it:indicator}, {it:k}, {it:subg}, {it:spec}, {it:loa}, 
{it:ctype}. Finally, result frames may have additional variables depending on their 
type. There are three types of result frames: {p_end}

{phang2}
1. Result frames for level estimates, which is the default.

{phang2}
2. Result frames for level estimates over time, which additionally includes an 
(integer) time variable.

{phang2}
3. Result frames for estimates of changes over time. This frame type includes 
additional variables describing starting and end point of the observation period 
underlying the change estimate.

{marker options}{...}
{title:Options}

{phang}
{opt fr:ame(name)} specifies the name of the frame where to store results.

{phang}
{opt replace} replaces any potentially existing frame.{p_end}

{phang}
{opt dou:ble} generates core variables of the estimate (e.g., {bf:b}, {bf:se}) as type {bf:double}.
The default is to generate {bf:float} variables. See see {helpb data types} for more details.

{phang}
{opt t} prepares the results frame for harmonised over time levels. Specifically, 
the (integer) time variable {it:t} is added to the results frame.

{phang}
{opt cot} prepares the results frame for storing changes over time. Specifically, the variables 
{it:t0}, {it:t1}, {it:yt0}, {it:yt1} and {it:ann} are added to the results frame.

{phang}
{opt add(name)} adds {it:string} as a value for the extra variable specified by the 
{cmd:add(}{it:name}{cmd:)} option of {helpb mpitb_rframe:mpitb rframe}.

{phang}
{opt ts} adds timestamp for the underlying data set and for estimation time.

{marker examples}{...}
{title:Examples}

    {hline}
{pstd}Setup a simple results frame{p_end}

{phang2}{cmd:mpitb rframe , frame(mylevs)}

    {hline}
{pstd}Setup a results frame for changes over time allowing for timestamps{p_end}

{phang2}{cmd:mpitb rframe , frame(mycot) cot ts}

    {hline}
	
