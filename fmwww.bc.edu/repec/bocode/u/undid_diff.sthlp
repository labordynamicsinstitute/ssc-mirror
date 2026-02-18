{smcl}
{help undid_diff:undid_diff}
{hline}

{title:undid_diff}

{pstd}
Creates the empty difference dataframe CSV file to be sent to each data silo.
{p_end}

{title:Command Description}

{phang}
{cmd:undid_diff} reads the init.csv file and generates an empty_diff_df.csv file specifying 
which period-to-period contrasts each silo should compute. This file includes placeholders for 
difference estimates, variances, and sample sizes to be filled in during stage two.
{p_end}

{title:Syntax}

{p 8 17 2}
{cmd:undid_diff}
{cmd:,}
{cmd:init_filepath(}{it:string}{cmd:)}
{cmd:date_format(}{it:string}{cmd:)}
{cmd:freq(}{it:string}{cmd:)}
{p_end}

{p 8 17 2}
[{cmd:covariates(}{it:string}{cmd:)}
{cmd:freq_multiplier(}{it:integer}{cmd:)}
{cmd:weights(}{it:string}{cmd:)}
{cmd:filename(}{it:string}{cmd:)}
{cmd:filepath(}{it:string}{cmd:)}]
{p_end}

{title:Parameters}

{synoptset 35 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt init_filepath(string)}}filepath to init.csv file{p_end}
{synopt:{opt date_format(string)}}date format used in init.csv{p_end}
{synopt:{opt freq(string)}}time period frequency: "year", "month", "week", or "day"{p_end}

{syntab:Optional}
{synopt:{opt covariates(string)}}space-separated list of covariates (overrides init.csv){p_end}
{synopt:{opt freq_multiplier(integer)}}multiplier for freq (default: 1); e.g., 2 for two-year periods{p_end}
{synopt:{opt weights(string)}}weighting scheme: "none", "diff", "att", or "both" (default: "both"){p_end}
{synopt:{opt filename(string)}}output filename (must end in .csv, default: "empty_diff_df.csv"){p_end}
{synopt:{opt filepath(string)}}directory to save output file (default: temporary directory){p_end}
{synoptline}
{p2colreset}{...}

{title:Date Format Options}

{pstd}
Supported date formats:

{synoptset 25 tabbed}{...}
{synopthdr:Format}
{synoptline}
{synopt:{cmd:"yyyy/mm/dd"}}Example: 1997/08/25{p_end}
{synopt:{cmd:"yyyy-mm-dd"}}Example: 1997-08-25{p_end}
{synopt:{cmd:"yyyymmdd"}}Example: 19970825{p_end}
{synopt:{cmd:"yyyy/dd/mm"}}Example: 1997/25/08{p_end}
{synopt:{cmd:"yyyy-dd-mm"}}Example: 1997-25-08{p_end}
{synopt:{cmd:"yyyyddmm"}}Example: 19972508{p_end}
{synopt:{cmd:"dd/mm/yyyy"}}Example: 25/08/1997{p_end}
{synopt:{cmd:"dd-mm-yyyy"}}Example: 25-08-1997{p_end}
{synopt:{cmd:"ddmmyyyy"}}Example: 25081997{p_end}
{synopt:{cmd:"mm/dd/yyyy"}}Example: 08/25/1997{p_end}
{synopt:{cmd:"mm-dd-yyyy"}}Example: 08-25-1997{p_end}
{synopt:{cmd:"mmddyyyy"}}Example: 08251997{p_end}
{synopt:{cmd:"mm/yyyy"}}Example: 08/1997{p_end}
{synopt:{cmd:"mm-yyyy"}}Example: 08-1997{p_end}
{synopt:{cmd:"mmyyyy"}}Example: 081997{p_end}
{synopt:{cmd:"yyyy"}}Example: 1997{p_end}
{synopt:{cmd:"ddmonyyyy"}}Example: 25aug1997{p_end}
{synopt:{cmd:"yyyym00"}}Example: 1997m8{p_end}
{synoptline}
{p2colreset}{...}

{title:Examples}

{pstd}
For more examples and sample data, please visit the GitHub repository:{p_end}
{pstd}
{browse "https://github.com/ebjamieson97/undid"}{p_end}

{pstd}
{bf:Basic example:}{p_end}

{phang2}{cmd:. undid_diff, ///}{p_end}
{phang2}{cmd:    init_filepath("init.csv") ///}{p_end}
{phang2}{cmd:    date_format("yyyy") ///}{p_end}
{phang2}{cmd:    freq("year")}{p_end}

{pstd}
Output:{p_end}
{phang2}empty_diff_df.csv saved to: C:\Temp\empty_diff_df.csv{p_end}

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

{* undid_diff                                         }
{* written by Eric Jamieson                           }
{* version 1.0.0 2025-02-15                           }

{smcl}