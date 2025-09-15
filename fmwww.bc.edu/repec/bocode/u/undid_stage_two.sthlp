{smcl}
{* *! version 1.0.0 14sept2025}
{help undid_stage_two:undid_stage_two}
{hline}

{title:undid}

{pstd}
undid - Estimate difference-in-differences with unpoolable data. {p_end}

{title:Command Description}

{phang}
{cmd:undid_stage_two} Based on the information given in the received `empty_diff_df.csv`, computes the appropriate differences in mean outcomes at the local silo and saves as `filled_diff_df_silo_name.csv`. Also stores trends data as `trends_data_silo_name.csv`. Displays the filepath of the created CSV files as the results output.

Required parameters:

- {bf:empty_diff_filepath} : A string specifying the filepath to the empty_diff_df.csv

- {bf:silo_name} : A string specifying the name of the local silo. Should reflect the spelling used in the empty_diff_df.csv to reference this silo.

- {bf:time_column} : Variable name specifying the variable containing the date data. Must reference a string a column.

- {bf:outcome_column} : Variable name specifying the variable containing the outcome of interest. Must reference a numeric column.

- {bf:silo_date_format} : A string which specifies the date format used in the local silo data. Options are:
    -> "ddmonyyyy yyyym00 yyyy/mm/dd yyyy-mm-dd yyyymmdd yyyy/dd/mm yyyy-dd-mm yyyyddmm dd/mm/yyyy dd-mm-yyyy ddmmyyyy mm/dd/yyyy mm-dd-yyyy mmddyyyy yyyy"

Optional parameters:

- {bf:consider_covariates} : An integer which if set to 0 will cause `undid_stage_two` to ignore any calculations involving covariates. Can only be 1 or 0. Defaults to 1. 

- {bf:anonymize_weights} : An integer, either 0 (false) or 1 (true), which determines if the counts of n (# of obs. used to calculate a contrast/difference)
  and n_t (# of treated obs. used in the calculation of a contrast/difference) should be rounded. Defaults to 0.

- {bf:anonymize_size} : An integer. Counts will be rounded to the nearest multiple of this value if 'anonymize_weights' is toggled on. Defaults to 5.

- {bf:filepath} : A string specifying the path to the folder in which to save the output file, e.g. "`c(pwd)'". Defaults to "`c(tempdir)'".


{title:Syntax}

{pstd}
{cmd:undid_stage_two} empty_diff_filepath(string) silo_name(string) time_column(varname) outcome_column(varname) silo_date_format(string) [{it:consider_covariates(int)} {it:anonymize_weights(int)} {it:anonymize_size(int)} {it:filepath(string)}]{p_end}

{title:Examples}

{phang2}{cmd:undid_stage_two, empty_diff_filepath("test_csv_files\empty_diff_df_staggered.csv") silo_name("71") time_column(year) outcome_column(coll) silo_date_format("yyyy")}

{phang2}filled_diff_df_71.csv file saved to: C:\Users\ERICBR~1\AppData\Local\Temp\filled_diff_df_71.csv.csv

{phang2}trends_data_71.csv file saved to: C:\Users\ERICBR~1\AppData\Local\Temp\trends_data_df_71.csv.csv

{title:Author}

{pstd}
Eric Jamieson{p_end}

{pstd}
For more information about undid, visit the {browse "https://github.com/ebjamieson97/undid"} GitHub repository.{p_end}

{title:Citation}

{pstd}
Please cite: Sunny Karim, Matthew D. Webb, Nichole Austin, Erin Strumpf. 2024. Difference-in-Differenecs with Unpoolable Data. {browse "https://arxiv.org/abs/2403.15910"} {p_end}