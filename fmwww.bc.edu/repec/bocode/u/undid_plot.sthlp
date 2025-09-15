{smcl}
{* *! version 1.0.0 14sept2025}
{help undid_stage_three:undid_plot}
{hline}

{title:undid}

{pstd}
undid - Estimate difference-in-differences with unpoolable data. {p_end}

{title:Command Description}  

{phang}
{cmd:undid_plot} Takes in all of the trends data CSV files and uses them to create parallel trends plots or event study plots.

Required parameters:

- {bf:dir_path} : A string specifying the filepath to the directory (folder) where all of the trends data CSV files for this analysis are stored.

Optional parameters:

- {bf:plot} : A string which specifies the type of plot to make. Options are:
    -> "agg", "dis", "silo", or "event". Defaults to "agg".

- {bf:weights} : Integer, either 1 (true) or 0 (false), which determines whether or not the weights should be used. Defaults to 1.

- {bf:covariates} : Integer, either 1 (true) or 0 (false), which specifies whether to use the `mean_outcome` column
or the `mean_outcome_residualized` column from the trends data CSV files while plotting. Setting to 0 (false) selects the `mean_outcome` column
and 1 (true) selects the `mean_outcome_residualized` column. Defaults to 0 (false).

- {bf:omit_silos} : A string, with different silo names separated by spaces, indicating any silos to omit from the plot.

- {bf:include_silos} : A string, with different silo names separated by spaces, indicating to only include these silos in the plot.

- {bf:treated_colours} : A string, with different colours seprated by spaces, used to select the colours used for treated silos when the 'plot' argument is set to either "silo" or "dis".
  Defaults to "cranberry maroon red orange_red dkorange sienna brown gold pink magenta purple".

- {bf:control_colours} : A string, with different colours seprated by spaces, used to select the colours used for control silos when the 'plot' argument is set to either "silo" or "dis".
  Defaults to "navy dknavy blue midblue ltblue teal dkgreen emerald forest_green mint cyan".

- {bf:ci} : Real value, between 0 and 1, used to indicate the confidence interval for event study plots, i.e. when the 'plot' argument is set to  "event".
  Setting to 0 toggles off the confidence intervals. Defaults to 0.95.

- {bf:event_window} : Two numeric values, which if supplied, determine the periods before (the first value) and the periods after (the second value) the event that should be included in the plot.


{title:Syntax}

{pstd}

{cmd:undid_plot} dir_path(string) [{it:plot(string)} {it:weights(int)} {it:covariates(int)} {it:omit_silos(string)} {it:include_silos(string)} {it:treated_colours(string)} {it:control_colours(string)} {it:ci(real)} {it:event_window(numlist)}]{p_end}

{title:Author}

{pstd}
Eric Jamieson{p_end}

{pstd}
For more information about undid, visit the {browse "https://github.com/ebjamieson97/undid"} GitHub repository.{p_end}

{title:Citation}

{pstd}
Please cite: Sunny Karim, Matthew D. Webb, Nichole Austin, Erin Strumpf. 2024. Difference-in-Differenecs with Unpoolable Data. {browse "https://arxiv.org/abs/2403.15910"} {p_end}