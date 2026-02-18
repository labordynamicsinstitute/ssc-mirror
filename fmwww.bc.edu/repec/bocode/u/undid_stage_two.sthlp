{smcl}
{help undid_stage_two:undid_stage_two}
{hline}

{title:undid_stage_two}

{pstd}
Computes differences in mean outcomes at the local silo level and generates trends data for 
UN-DID estimation. This is the second stage of the UN-DID procedure, executed independently 
at each data silo.
{p_end}

{title:Command Description}

{phang}
{cmd:undid_stage_two} reads the empty difference dataframe CSV file generated in stage one 
and fills it. It calculates differences in mean outcomes (with and without covariate adjustment)
and saves results in a filled_diff_df CSV file. It also generates a trends_data CSV file
containing mean outcomes over time for visualization. Both files are saved with the silo name appended.
{p_end}

{title:Syntax}

{p 8 17 2}
{cmd:undid_stage_two}
{cmd:,}
{cmd:empty_diff_filepath(}{it:string}{cmd:)}
{cmd:silo_name(}{it:string}{cmd:)}
{cmd:time_column(}{it:varname}{cmd:)}
{cmd:outcome_column(}{it:varname}{cmd:)}
{cmd:silo_date_format(}{it:string}{cmd:)}
{p_end}

{p 8 17 2}
[{cmd:consider_covariates(}{it:integer}{cmd:)}
{cmd:filepath(}{it:string}{cmd:)}
{cmd:anonymize_weights(}{it:integer}{cmd:)}
{cmd:anonymize_size(}{it:integer}{cmd:)}]
{p_end}

{title:Parameters}

{synoptset 35 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt empty_diff_filepath(string)}}filepath to empty_diff_df.csv file from stage one{p_end}
{synopt:{opt silo_name(string)}}name of the local silo (must match spelling in empty_diff_df.csv){p_end}
{synopt:{opt time_column(varname)}}name of date variable in local dataset (must be string){p_end}
{synopt:{opt outcome_column(varname)}}name of outcome variable in local dataset (must be numeric){p_end}
{synopt:{opt silo_date_format(string)}}date format used in local silo data{p_end}

{syntab:Optional}
{synopt:{opt consider_covariates(integer)}}compute covariate-adjusted estimates: 1 = yes, 0 = no (default: 1){p_end}
{synopt:{opt filepath(string)}}directory to save output files (default: temporary directory){p_end}

{syntab:Privacy Protection}
{synopt:{opt anonymize_weights(integer)}}round observation counts for privacy: 1 = yes, 0 = no (default: 0){p_end}
{synopt:{opt anonymize_size(integer)}}rounding increment when anonymize_weights = 1 (default: 5){p_end}
{synoptline}
{p2colreset}{...}

{title:Date Format Options}

{pstd}
The {cmd:silo_date_format()} parameter must match the format of dates in your {cmd:time_column()}. 
Supported formats:

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

{pstd}
Ensure the format specified exactly matches your data. The time_column must be a string variable 
in one of these formats.

{title:Output Files}

{pstd}
{cmd:undid_stage_two} generates two CSV files:

{pstd}
{bf:1. filled_diff_df_[silo_name].csv}

{phang}
Contains the computed treatment effect estimates for this silo. Each row represents a 
period-to-period contrast with columns for:

{phang2}
- Treatment indicators and timing information{p_end}

{phang2}
- Point estimates (diff_estimate) and variances (diff_var){p_end}

{phang2}
- Covariate-adjusted estimates (diff_estimate_covariates, diff_var_covariates){p_end}

{phang2}
- Sample sizes (n, n_t) for weighting{p_end}

{pstd}
{bf:2. trends_data_[silo_name].csv}

{phang}
Contains mean outcomes over time for parallel trends visualization. Each row represents a 
time period with columns for:

{phang2}
- Mean outcome (mean_outcome){p_end}

{phang2}
- Covariate-adjusted mean outcome (mean_outcome_residualized){p_end}

{phang2}
- Sample size at each time point{p_end}

{title:Examples}

{pstd}
For more examples and sample data, please visit the GitHub repository:{p_end}
{pstd}
{browse "https://github.com/ebjamieson97/undid"}{p_end}

{pstd}
{bf:Basic example with yearly data:}{p_end}

{phang2}{cmd:. use "State71.dta", clear}{p_end}

{phang2}{cmd:. undid_stage_two, ///}{p_end}
{phang2}{cmd:    empty_diff_filepath("empty_diff_df_staggered.csv") ///}{p_end}
{phang2}{cmd:    silo_name("71") ///}{p_end}
{phang2}{cmd:    time_column(year) ///}{p_end}
{phang2}{cmd:    outcome_column(coll) ///}{p_end}
{phang2}{cmd:    silo_date_format("yyyy")}{p_end}

{pstd}
Output:{p_end}
{phang2}filled_diff_df_71.csv file saved to: C:\Temp\filled_diff_df_71.csv{p_end}
{phang2}trends_data_71.csv file saved to: C:\Temp\trends_data_71.csv{p_end}

{pstd}
{bf:Example with privacy protection:}{p_end}

{phang2}{cmd:. undid_stage_two, ///}{p_end}
{phang2}{cmd:    empty_diff_filepath("empty_diff_df.csv") ///}{p_end}
{phang2}{cmd:    silo_name("Hospital_A") ///}{p_end}
{phang2}{cmd:    time_column(admissiondate) ///}{p_end}
{phang2}{cmd:    outcome_column(los) ///}{p_end}
{phang2}{cmd:    silo_date_format("dd/mm/yyyy") ///}{p_end}
{phang2}{cmd:    anonymize_weights(1) ///}{p_end}
{phang2}{cmd:    anonymize_size(10)}{p_end}

{pstd}
This rounds all reported sample sizes to the nearest multiple of 10 for privacy protection.

{title:Privacy Protection with Anonymize Weights}

{pstd}
The {cmd:anonymize_weights()} and {cmd:anonymize_size()} options provide privacy protection 
for sensitive data:

{phang}
When {cmd:anonymize_weights(1)} is specified, all observation counts (n and n_t) reported in 
the output files are rounded to the nearest multiple of {cmd:anonymize_size}. Obviously, this reduces
the precision and reliability of the final estimates, please only consider using this option only if
absolutely required.

{pstd}
{bf:How it works:}

{phang}
- If a contrast uses 47 observations and anonymize_size = 5, it will be reported as 45{p_end}

{phang}
- If a contrast uses 12 observations and anonymize_size = 10, it will be reported as 10{p_end}

{phang}
- Minimum reported value is always anonymize_size (never rounds to 0){p_end}

{title:Data Requirements}

{pstd}
Before running {cmd:undid_stage_two}, ensure your local dataset has:

{phang}
1. {bf:Time variable} as a string in one of the supported date formats{p_end}

{phang}
2. {bf:Outcome variable} as a numeric variable with no missing values{p_end}

{phang}
3. {bf:Covariate variables} (if used) as numeric variables with no missing values{p_end}

{pstd}
The command performs extensive validation and will display informative error messages if 
requirements are not met.

{title:Common Issues and Solutions}

{pstd}
{bf:Error: time_column must be a string variable}

{phang}
Solution: Convert your time variable to string format matching one of the supported date formats

{pstd}
{bf:Error: The silo_name is not recognized}

{phang}
Solution: Check spelling matches exactly with empty_diff_df.csv (case-sensitive)

{pstd}
{bf:Error: covariate has missing values}

{phang}
Solution: Either drop observations with missing covariates or set consider_covariates(0)

{pstd}
{bf:Error: The local silo must have at least one obs before and after treatment}

{phang}
Solution: Verify your data includes both pre- and post-treatment periods

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

{* undid_stage_two                                    }
{* written by Eric Jamieson                           }
{* version 1.1.0 2025-09-30                           }

{smcl}