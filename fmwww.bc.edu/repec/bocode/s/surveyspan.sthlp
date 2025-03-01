{smcl}
{* *! version 1.0  11feb2025}{...}
{vieweralsosee "[D] generate" "help generate"}{...}
{vieweralsosee "[R] summarize" "help summarize"}{...}
{viewerjumpto "Syntax" "surveyspan##syntax"}{...}
{viewerjumpto "Description" "surveyspan##description"}{...}
{viewerjumpto "Options" "surveyspan##options"}{...}
{viewerjumpto "Examples" "surveyspan##examples"}{...}
{viewerjumpto "Stored results" "surveyspan##results"}{...}
{viewerjumpto "Authors" "surveyspan##author"}{...}
{viewerjumpto "Acknowledgments" "surveyspan##acknowledgments"}{...}
{title:Title}

{phang}
{bf:surveyspan} {hline 2} Analyze and monitor survey timing metrics

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:surveyspan} {it:startvar} {it:endvar} {ifin} [{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt g:enerate(newvar)}}create new variable for calculated durations{p_end}
{synopt:{opt min:time(#)}}specify minimum acceptable duration in minutes{p_end}
{synopt:{opt max:time(#)}}specify maximum acceptable duration in minutes{p_end}
{synopt:{opt c:utoff(#)}}specify hour cutoff for after-hours flags (default: 17){p_end}
{synopt:{opt group:var(varname)}}generate Excel report grouped by specified variable{p_end}
{synopt:{opt out:file(filename)}}specify name for Excel output file (requires groupvar){p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:surveyspan} is an R-class command that analyzes timestamp metadata from field surveys to monitor data collection quality and identify timing issues. It processes start and end times in standard XLSForm format (YYYY-MM-DDThh:mm:ss) as used by KoboToolbox, SurveyCTO, and ODK. The command automatically handles common data issues such as single-digit days in timestamps and negative durations, excluding invalid timestamps.{p_end}

{pstd}
Time variables must exist in the dataset and be string type. The command will exit with error if:{p_end}

{phang2}- Time variables are not found in dataset{p_end}
{phang2}- Time variables are not string type and in the standard timestamp format{p_end}
{phang2}- Cutoff hour is not between 0 and 23{p_end}
{phang2}- Mintime or maxtime are negative{p_end}

{pstd}
As its core function, the command calculates survey durations and flags potential issues such as rushed interviews or after-hours data collection. Generated duration variables are automatically labeled with "end_time - start_time".{p_end}

{pstd}
When {opt groupvar} is specified, it creates an Excel workbook (sheet "Summary Stats") with comprehensive statistics including mean durations, excluded observations, and various quality indicators by the specified groupvar (date, region, enumerator id etc.).{p_end}

{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt generate(newvar)} saves calculated durations to the specified new variable.

{phang}
{opt mintime(#)} specifies the minimum acceptable survey duration in minutes. Surveys below this threshold are flagged.

{phang}
{opt maxtime(#)} specifies the maximum acceptable survey duration in minutes. Surveys above this threshold are excluded from calculations.

{phang}
{opt cutoff(#)} specifies the hour (in 24-hour format) after which surveys are flagged as after-hours. Default is 17 (5 PM). If the end time occurs after the specified cutoff hour (default: 17), the interview is flagged as an {bf:after-hours survey}. These flagged surveys can be reviewed in the optional Excel output.

{phang}
{opt groupvar(varname)} generates detailed Excel reports grouped by the specified variable. The report includes: - Mean and median survey durations - Number of excluded observations - Proportion of surveys flagged as after-hours - Count of surveys below the minimum time threshold and so on. 

{marker examples}{...}
{title:Examples}

{pstd}Setup example dataset:{p_end}
{phang2}{stata "clear"}{p_end}
{phang2}{stata "set obs 100"}{p_end}
{phang2}{stata `"gen str starttime = "2025-02-11T08:00:00" in 1/20"'}{p_end}
{phang2}{stata `"replace starttime = "2025-02-11T10:00:00" in 21/40"'}{p_end}
{phang2}{stata `"replace starttime = "2025-02-11T13:00:00" in 41/60"'}{p_end}
{phang2}{stata `"replace starttime = "2025-02-11T15:00:00" in 61/80"'}{p_end}
{phang2}{stata `"replace starttime = "2025-02-11T19:00:00" in 81/100"'}{p_end}
{phang2}{stata `"gen str endtime = "2025-02-11T08:05:00" in 1/10"'}{p_end}
{phang2}{stata `"replace endtime = "2025-02-12T11:30:00" in 11/30"'}{p_end}
{phang2}{stata `"replace endtime = "2025-02-11T13:08:00" in 31/50"'}{p_end}
{phang2}{stata `"replace endtime = "2025-02-11T16:45:00" in 51/70"'}{p_end}
{phang2}{stata `"replace endtime = "2025-02-11T19:03:00" in 71/100"'}{p_end}
{phang2}{stata "gen enum_id = ceil(_n/20)"}{p_end}
{phang2}{stata "gen region = ceil(_n/50)"}{p_end}

{pstd}Basic use:{p_end}
{phang2}{stata "surveyspan starttime endtime"}{p_end}

{pstd}Save durations to new variable:{p_end}
{phang2}{stata "surveyspan starttime endtime, generate(survey_length)"}{p_end}

{pstd}Set timing thresholds:{p_end}
{phang2}{stata "surveyspan starttime endtime, mintime(10) maxtime(120)"}{p_end}

{pstd}Analysis by enumerator:{p_end}
{phang2}{stata "surveyspan starttime endtime, groupvar(enum_id)"}{p_end}

{pstd}Comprehensive analysis:{p_end}
{phang2}{stata "surveyspan starttime endtime, generate(interview_duration) cutoff(18) mintime(15) groupvar(enum_id)"}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:surveyspan} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(total_obs)}}number of observations available{p_end}
{synopt:{cmd:r(used_obs)}}number of observations with valid durations{p_end}
{synopt:{cmd:r(mean)}}mean survey duration{p_end}
{synopt:{cmd:r(median)}}median survey duration{p_end}
{synopt:{cmd:r(sd)}}standard deviation of survey duration{p_end}
{synopt:{cmd:r(within_sd_pct)}}percentage of observations within one standard deviation of mean{p_end}
{synopt:{cmd:r(aft_cutoff_count)}}number of surveys after cutoff{p_end}
{synopt:{cmd:r(aft_cutoff_pct)}}percentage of surveys after cutoff{p_end}

{marker author}{...}
{title:Authors}

{pstd}
Kabira Namit{break}
World Bank{break}
knamit@worldbank.org

{pstd}
Ketki Samel{break}
Centre for Effective Governance of Indian States {break}
ketkisamel1@gmail.com 

{marker acknowledgments}{...}
{title:Acknowledgments}

{pstd}
Special thanks to Zaeen de Souza who always has brilliant suggestions and advice regarding nascent Stata modules and is also the one who suggested the Excel output option and the reporting of the standard deviation numbers for surveyspan, and also to Prabhmeet Kaur for testing and reviewing surveyspan.{p_end}

{pstd}
For updates and bug reports, please email: knamit@worldbank.org




