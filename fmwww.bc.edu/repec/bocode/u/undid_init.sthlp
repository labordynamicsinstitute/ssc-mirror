{smcl}
{help undid_init:undid_init}
{hline}

{title:undid_init}

{pstd}
Generates an initial CSV file specifying silo names, start times, end times, and treatment times 
for the UN-DID analysis.
{p_end}

{title:Command Description}

{phang}
{cmd:undid_init} creates an init.csv file containing the very basic structure of your UN-DID analysis. 
This file specifies which data silos will participate, the time periods to analyze, when each 
silo was treated (or if it serves as a control), and any covariates to be included.
{p_end}

{title:Syntax}

{p 8 17 2}
{cmd:undid_init}
{cmd:,}
{cmd:silo_names(}{it:string}{cmd:)}
{cmd:start_times(}{it:string}{cmd:)}
{cmd:end_times(}{it:string}{cmd:)}
{cmd:treatment_times(}{it:string}{cmd:)}
{p_end}

{p 8 17 2}
[{cmd:covariates(}{it:string}{cmd:)}
{cmd:filename(}{it:string}{cmd:)}
{cmd:filepath(}{it:string}{cmd:)}]
{p_end}

{title:Parameters}

{synoptset 35 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt silo_names(string)}}space-separated list of silo names{p_end}
{synopt:{opt start_times(string)}}space-separated list of start times for each silo{p_end}
{synopt:{opt end_times(string)}}space-separated list of end times for each silo{p_end}
{synopt:{opt treatment_times(string)}}space-separated list of treatment times; use "control" for control silos{p_end}

{syntab:Optional}
{synopt:{opt covariates(string)}}space-separated list of covariate names{p_end}
{synopt:{opt filename(string)}}output filename (must end in .csv, default: "init.csv"){p_end}
{synopt:{opt filepath(string)}}directory to save output file (default: temporary directory){p_end}
{synoptline}
{p2colreset}{...}

{title:Examples}

{pstd}
For more examples and sample data, please visit the GitHub repository:{p_end}
{pstd}
{browse "https://github.com/ebjamieson97/undid"}{p_end}

{pstd}
{bf:Basic example:}{p_end}

{phang2}{cmd:. undid_init, ///}{p_end}
{phang2}{cmd:    silo_names("71 73 58 46") ///}{p_end}
{phang2}{cmd:    start_times("1989 1989 1989 1989") ///}{p_end}
{phang2}{cmd:    end_times("2000 2000 2000 2000") ///}{p_end}
{phang2}{cmd:    treatment_times("1991 control 1993 control") ///}{p_end}
{phang2}{cmd:    covariates("asian black male")}{p_end}

{pstd}
Output:{p_end}
{phang2}init.csv saved to: C:\Temp\init.csv{p_end}

{title:Package Author}

{pstd}
Eric Jamieson. Report bugs at: ericbrucejamieson@gmail.com or {browse "https://github.com/ebjamieson97/undid"}.
{p_end}

{title:Citations}

{pstd}
If you use {cmd:undid} in your research, please cite:{p_end}

{pstd}
Sunny Karim, Matthew D. Webb, Nichole Austin, and Erin Strumpf. "Difference-in-Differences 
with Unpoolable Data." {browse "https://arxiv.org/abs/2403.15910"}{p_end}

{pstd}
To cite the {cmd:undid} Stata package:{p_end}

{pstd}
Eric Jamieson (2026). undid: Difference-in-Differences with Unpoolable Data. 
Stata package version 2.0.0. {browse "https://github.com/ebjamieson97/undid"}{p_end}

{* undid_init                                         }
{* written by Eric Jamieson                           }
{* version 1.0.0 2025-02-15                           }

{smcl}