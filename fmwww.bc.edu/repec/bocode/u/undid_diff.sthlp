{smcl}
{* *! version 1.0.0 14sept2025}
{help undid_diff:undid_diff}
{hline}

{title:undid}

{pstd}
undid - Estimate difference-in-differences with unpoolable data. {p_end}

{title:Command Description}

{phang}
{cmd:undid_diff} Creates the CSV file to be sent out to each silo (`empty_diff_df.csv`) and displays its filepath

Required parameters:

- {bf:init_filepath} : A string specifying the filepath to the init.csv

- {bf:date_format} : A string which specifies the date format used in the init.csv. Options are:
    -> "ddmonyyyy yyyym00 yyyy/mm/dd yyyy-mm-dd yyyymmdd yyyy/dd/mm yyyy-dd-mm yyyyddmm dd/mm/yyyy dd-mm-yyyy ddmmyyyy mm/dd/yyyy mm-dd-yyyy mmddyyyy yyyy"

- {bf:freq} : A string which indicates the length of the time periods to be used when computing the differences in mean outcomes between
periods at each silo and the length of a period for the trends data. Either "year", "month", "week", or "day".

Optional parameters:

- {bf:covariates} : A string specifying covariates to be considered at each silo. If left blank uses covariates from init.csv.

- {bf:freq_multiplier} : An integer which specifies if the frequency should be multiplied by a non-zero integer. 
For example, if the time periods to consider are two years, set freq("year") freq_multiplier(2)

- {bf:weights} : A string indicating the type of weighting to use. Defaults to "both". Options are:
    -> "none", "diff", "att", or "both". The various options describe the level at which weights are applied (to the contrasts/differences, to the sub-aggregate ATTs, to both, or to none).

- {bf:filename} : A string specifying the outputted filename. Must end in ".csv". Defaults to "empty_diff_df.csv".

- {bf:filepath} : A string specifying the path to the folder in which to save the output file, e.g. "`c(pwd)'". Defaults to "`c(tempdir)'".


{title:Syntax}

{pstd}
{cmd:undid_diff} init_filepath(string) date_format(string) freq(string) [{it:covariates(string)} {it:freq_multiplier(int)} {it:weights(string)} {it:filename(string)} {it:filepath(string)}]{p_end}

{title:Examples}

{phang2}{cmd:undid_diff, filepath("C:/Users/User/Documents/Project Files/init.csv") date_format("yyyy") freq("year")}

{phang2}empty_diff_df.csv saved to: C:\Users\ERICBR~1\AppData\Local\Temp\empty_diff_df.csv

{title:Author}

{pstd}
Eric Jamieson{p_end}

{pstd}
For more information about undid, visit the {browse "https://github.com/ebjamieson97/undid"} GitHub repository.{p_end}

{title:Citation}

{pstd}
Please cite: Sunny Karim, Matthew D. Webb, Nichole Austin, Erin Strumpf. 2024. Difference-in-Differenecs with Unpoolable Data. {browse "https://arxiv.org/abs/2403.15910"} {p_end}