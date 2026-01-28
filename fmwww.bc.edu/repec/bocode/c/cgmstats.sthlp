{smcl}
{hline}
help for {cmd:cgmstats}
{hline}


{title:Title}

{p2colset 5 14 21 2}{...}
{bf: cgmstats}  {hline 2} Process, summarize and visualize data from continuous glucose monitors (CGM)

{title:Input}

{pstd}The file path of the input file(s) (in .dta format) should be specified in the "dtadir" option 

{pstd}The file(s) should contain 3 columns: ID (unique identifier for each person), CGM readings, time stamp. Note: timestamp should be in the format %tcCCYY/NN/DD_HH:MM

{title:Syntax}

{opt cgmstats}, {opt id(var)} {opt glucose(var)} {opt time(var)} {opt dtadir(var)} [options]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt id(var)}}Variable containing ID(s){p_end}
{synopt:{opt glucose(var)}}Variable (numeric) containing sensor glucose values {p_end}
{synopt:{opt time(var)}}Variable containing timestamp (format %tcCCYY/NN/DD_HH:MM) {p_end}
{synopt:{opt dtadir(var)}}File path containing the input file(s) (.dta) {p_end}
{syntab:Optional}
{synopt:{opt freq(int)}}Establishes CGM recording frequency (in minutes), default is 15 minutes{p_end}
{synopt:{opt unit(mmol/l)}}Specifies glucose units are in mmol/L, default is mg/dL {p_end}
{synopt:{opt by(day)} or {opt by(id day)}}Produces CGM metric summary files (datasets and plots) by day of CGM wear (i.e., by(day)), or produces one CGM metric 
summary file by ID and day of wear (multiple rows per ID) (i.e., by(id day)){p_end}
{synopt:{opt keep(string)}}Contains conditional statement(s) to subset data according to glucose values or ID (i.e., keep(if sensorglucose>50)){p_end}
{synopt:{opt hyper(numlist)}}Defines glucose value cut point(s) for a hyperglycemic episode. An episode is defined as no values below glucose value cut point(s) for a 
certain period of time. Default values are 140 mg/dL (7.8 mmol/L), 180 mg/dL (10 mmol/L) and 250 mg/dL (13.9 mmol/L). If unit(mmol/L) is specified, then cut points 
should be in units of mmol/L. Decimals are accepted but decimal points will be converted to “_” in variable names{p_end}
{synopt:{opt hypo(numlist)}}Defines glucose value cut point(s) for a hypoglycemic episode. An episode is defined as no values above glucose value cut point(s) 
for a certain period of time. Default values are 54 mg/dL (3 mmol/L) and 70 mg/dL (3.9 mmol/L). If unit(mmol/L) is specified, then cut points should be in units of mmol/L. 
Decimals are accepted but decimal points will be converted to “_” in variable names {p_end}
{synopt:{opt hyper_exc_lngth(int)}}Defines length (in minutes) of a hyperglycemic episode, default is 30 minutes. During this period, 
there are no values below X (as defined by option hyper(numlist)){p_end}
{synopt:{opt hypo_exc_lngth(int)}}Defines length (in minutes) of a hypoglycemic episode, default is 30 minutes. During this period, there are no values 
above X (as defined by option hypo(numlist)) {p_end}
{synopt:{opt daystart(string)}}Defines the time indicating start of day (HH:MM, 24-hour scale), default is 06:00{p_end}
{synopt:{opt dayend(string)}}Defines the time indicating end of day (HH:MM, 24-hour scale), default is 22:00{p_end}
{synopt:{opt firsthours(int)}}Defines the number of hours to drop from the start of the CGM wear period. Accepts decimals (i.e., 0.5 for 30 minutes).{p_end}
{synopt:{opt lasthours(int)}}Defines the number of hours to drop from the end of the CGM wear period. Accepts decimals  (i.e., 0.5 for 30 minutes).{p_end}
{synopt:{opt timebefore(string)}}Subsets data to time before specified timestamp, i.e. timebefore("2021/09/01 12:00"){p_end}
{synopt:{opt timeafter(string)}}Subsets data to time after specified timestamp, i.e. timeafter("2023/09/01 12:00"){p_end}
{synopt:{opt auc}}Calculates the AUC over glucose value cut point(s) defined by option hyper(numlist){p_end}
{synopt:{opt hist(string, [freq bw(int)])}}Plots histograms of user-specified CGM summary statistics overlaid with kernel density 
plots [i.e., hist(mean_sensor cv_sensor)] by default. 
If option “freq” is used, the frequency histograms are plotted instead, without kernel density plots [i.e., hist(mean_sensor, freq)]. “bw(int)” 
executes the option to alter the bar widths of the histogram.{p_end}
{synopt:{opt plot(numlist, [nostats fill])}}Plots CGM glucose tracings over the entire CGM wear period with key CGM summary metrics 
(can be turned off using option “nostats”, i.e., plot(4 10, nostats). Users define the two cut points (low and high) for time in range and these cut points 
must be contained in options hypo(numlist) and hyper(numlist). If a decimal was specified in options hypo(numlist) or hyper(numlist), 
it must be rounded to nearest whole 
number for the plot option. “fill” executes option to fill in gaps in CGM glucose tracings using linear interpolation. {p_end}
{synopt:{opt savecombdta(string)}}The name of the .dta file containing the combined input .dta files {p_end}
{synopt:{opt savecombdir(string)}}The file path where the combined input .dta file (named in the savecombdta(string) option) is saved. 
If the directory is not specified along with "savecombdta(string)", 
it defaults to the user's working directory. {p_end}
{synopt:{opt savesumdta(string)}}The name of the .dta file containing the summary CGM metrics. {p_end}

{synopt:{opt savesumdir(string)}}The file path where the summary CGM metric dataset (named in the savesumdta(string) option) is saved. 
If the directory is not specified along with "savesumdta(string)", it defaults to the user's working directory. {p_end}

{synopt:{opt saveplotdir(string)}} The user-specified file path where any plots (histogram as specified in the “hist” option 
and CGM glucose tracings as specified in the “plot” option) are saved. If "saveplotdir(string)" is not specified, then plots are not 
saved. {p_end}

{title:Description}

{pstd}
{opt cgmstats} merges raw CGM data (one dataset per person) and outputs a CGM metric summary file(s) and optional visualizations (i.e., histograms of CGM summary 
statistics, plots of CGM glucose tracings). {p_end}

{title:Example}

{phang}{cmd:. local mydir "`c(pwd)'"} // provided input files are saved in folder titled "example2" in the working directory {p_end}
{phang}{cmd:. cgmstats, id(subjectid) glucose(sensorglucose) time(timestamp) dtadir(`mydir'/example2) by(id day) firsthours(1) hyper_exc_lngth(45) hypo_exc_lngth(15) savecombdta(cgmcombined_ex2) savesumdta(cgm_summary_file_ex2)}{p_end}

{title:Output}

{p2colset 5 34 34 0}{...}
{p2col:{it:CGM Variable}}Definition{p_end}
{p2line}
{p2col:{bf:first_glucose_reading}}The timestamp of the first CGM reading{p_end}
{p2col:{bf:ndayswear}}Number of days CGM device was worn{p_end}
{p2col:{bf:total_sensor_readings}}Total number of CGM sensor readings{p_end}
{p2col:{bf:percent_cgm_wear}}The number of sensor readings as a percentage of possible obtained readings by the CGM (given time worn){p_end}
{p2col:{bf:*mean_sensor}}Mean of all sensor glucose values{p_end}
{p2col:{bf: *median_sensor}}Median sensor glucose value{p_end}
{p2col:{bf: *q1_sensor}}First quartile sensor glucose value{p_end}
{p2col:{bf: *q3_sensor}}Third quartile sensor glucose value{p_end}
{p2col:{bf: *min_sensor}}Minimum of sensor glucose values{p_end}
{p2col:{bf: *max_sensor}}Maximum of sensor glucose values{p_end}
{p2col:{bf: *sd_sensor}}Standard deviation of sensor glucose values{p_end}
{p2col:{bf: *cv_sensor}}Coefficient of variation (%) of sensor glucose values (100*SD/mean glucose){p_end}
{p2col:{bf: *min_spent_Xi_Yi}}Minutes spent in the target blood glucose range (X-Y, where X and Y are determined by any combination of cut points from options "hypo" and "hyper"){p_end}
{p2col:{bf: *percent_time_Xi_Yi}}Minutes spent in the target blood glucose range (X-Y), as a percentage of the total time CGM was worn{p_end}
{p2col:{bf: *min_spent_under_Xi}}Total number of minutes spent below cut point(s) X (i.e., 54 and 70 mg/dL; option "hypo"){p_end}
{p2col:{bf: *percent_time_under_Xi}}Minutes spent below cut point(s) X (i.e., 54 and 70 mg/dL), as a percentage of the total time CGM was worn{p_end}
{p2col:{bf: episodes_under_Xi}}The count of glucose episodes below cut point(s) X (i.e., 54 and 70 mg/dL; option "hypo"), for user-defined time (i.e., default at least 30 minutes; option "hypo_exc_lngth"){p_end}
{p2col:{bf: avg_hypo_lngth_Xi}}The mean length (in minutes) of episodes below cut point(s) X (i.e., 54 and 70 mg/dL; option "hypo"). Minimum length to be considered an episode defined by option "hypo_exc_lngth" (default 30 min).{p_end}
{p2col:{bf: *min_spent_over_Xi}}Total number of minutes spent above cut point(s) X (i.e., 180 and 250 mg/dL; option "hyper"){p_end}
{p2col:{bf: *percent_time_over_Xi}}Minutes spent above cut point(s) X (i.e., 180 and 250 mg/dL), as a percentage of the total time CGM was worn{p_end}
{p2col:{bf: episodes_over_Xi}}The count of glucose episodes above cut point(s) X (i.e., 180 and 250 mg/dL; option "hyper"), for user-defined time (i.e., default at least 30 minutes; option "hyper_exc_lngth"){p_end}
{p2col:{bf: avg_hyper_lngth_Xi}}The mean length (in minutes) of episodes above cut point(s) X (i.e., 180 and 250 mg/dL; option "hyper"). Minimum length to be considered an episode defined by option "hyper_exc_lngth" (default 30 min).{p_end}
{p2col:{bf: auc_over_Xi}}Area under the sensor glucose curve over cut point(s) X (i.e., 180 and 250 mg/dL; option “hyper”), calculated using the trapezoidal rule.{p_end}
*These metrics are calculated overall and for day time/night time (as defined by options “daystart” and “dayend”).
{p2line}
{marker col_form_opts}{...}

{title:Corresponding Author}

Natalie Daya Malek, Johns Hopkins University, ndaya1@jh.edu
