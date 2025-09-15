{smcl}
{* *! version 1.0.0 14sept2025}
{help undid_stage_three:undid_stage_three}
{hline}

{title:undid}

{pstd}
undid - Estimate difference-in-differences with unpoolable data. {p_end}

{title:Command Description}  

{phang}
{cmd:undid_stage_three} Takes in all of the filled diff df CSV files and uses them to compute group level ATTs as well as the aggregate ATT and its standard errors and p-values.

Required parameters:

- {bf:dir_path} : A string specifying the filepath to the folder where all of the filled diff CSV files for this analysis are stored.

Optional parameters:

- {bf:agg} : A string which specifies the aggregation methodology for computing the aggregate ATT. Options are:
    -> "silo", "g", "gt", "sgt", "time", or "none". Defaults to "g".

- {bf:weights} : A string, determines which of the weighting methodologies should be used. Options are:
    -> "none", "diff", "att", or "both". Defaults to the weighting methodology specified in the filled diff CSV files.

- {bf:covariates} : Integer, either 1 (true) or 0 (false), which specifies whether to use the `diff_estimate` column or the `diff_estimate_covariates` column from the filled diff df CSV files when computing ATTs.
  Setting to 1 (true) selects the `diff_estimate_covariates` column and 0 (false) selects the `diff_estimate` column. Defaults to 0 (false).

- {bf:use_pre_controls} : Integer, either 1 (true) or 0 (false), which declares if the not-yet-treated differences from treated silos should be used as controls when computing relevant sub-aggregate ATTs.
  Defaults to 0.

- {bf:nperm} : An integer specifying the number of unique random permutations to consider when performing the randomization inference. Defaults to 1000. 

- {bf:verbose} : An integer value that controls progress reporting frequency during the randomization inference procedure. When set to a positive integer N, progress updates will be displayed every N permutations.
  Setting to 0 disables the progress messages. Defaults to 0.

- {bf:seed} : An integer value, the seed used for randomization inference.

- {bf:max_attempts} : An integer, sets the maximum number of attempts to find a new unique random permutations during the randomization inference procedure. Defaults to 100.

- {bf:check_anon_size} : An integer, either 0 (false) or 1 (true), which if toggled on, displays which silos enabled the 'anonymize_weights' argument in stage two, and the respective 'anonymize_size' values.
  Defaults to 0.


{title:Syntax}

{pstd}

{cmd:undid_stage_three} dir_path(string) agg(string) [{it:weights(int)} {it:covariates(int)} {it:imputation(string)} {it:save_csv(int)} {it:filename(string)} {it:filepath(string)} {it:nperm(int)} {it:verbose(int)}]{p_end}

{title:Examples}

{phang2}{cmd:undid_stage_three,}

{phang2} filler filler 

{title:Author}

{pstd}
Eric Jamieson{p_end}

{pstd}
For more information about undid, visit the {browse "https://github.com/ebjamieson97/undid"} GitHub repository.{p_end}

{title:Citation}

{pstd}
Please cite: Sunny Karim, Matthew D. Webb, Nichole Austin, Erin Strumpf. 2024. Difference-in-Differenecs with Unpoolable Data. {browse "https://arxiv.org/abs/2403.15910"} {p_end}