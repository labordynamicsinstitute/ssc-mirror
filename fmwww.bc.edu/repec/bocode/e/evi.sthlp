{smcl}
{* 28jan2026}{...}
{cmd:help evi}
{hline}

{title:Title}

{pstd} {cmd:evi} {hline 2} Epidemic Volatility Index (EVI) for detecting epidemic waves

{title:Syntax}

{p 8 14 2} {cmd: evi} {it:varlist} {if in} [, options]
	
{pstd} {it:varlist} should contain two variables and be entered in the following order: {it:cases} and {it:time} 

{title:Description}

{pstd} {cmd:evi} is based on the volatility of the newly reported {it:cases} per unit of {it:time} (ideally per day) and issues an early warning when 
the rate of the volatility change exceeds a threshold ('c'). Issuance of consecutive early warnings is a strong indication of an upcoming epidemic wave.
EVI is calculated for a rolling window of time series epidemic data ('lag'). At each step, the observations within the window are obtained by shifting 
the window forward over the time series data one observation at a time. The user should provide the minimum relative rise in mean (moving-average) 
cases ('r') between two consecutive time units (usually days or weeks) that, if present, should be detected. EVI is always anchored to the most recent day.
It is suitable for real-time or near–real-time surveillance. 

{title:Modules required}

{pstd} Users need to install {stata ssc install diagt:diagt} and {stata ssc install rangestat:rangestat}

{title:Options}

{pstd} {cmd:mov(#)} specifies the size (number of days) for the moving average of cases (by default it is 7,
corresponding to a weekly moving average when daily data are used). The moving average is
applied to the observed case counts before any volatility calculations are performed.
This transformation smooths short-term fluctuations, reduces day-to-day noise, and
stabilizes variance. In short, {cmd:mov()} defines the time scale over which mean case
levels are estimated and smooths the signal before subsequent EVI calculations.

{pstd} {cmd:lag(#1 #2)} specifies the range of lag values used to compare recent
variability with past variability when computing the EVI. The
{cmd:lag()} option controls how far back in time the historical reference window is taken,
relative to the recent window. For example, {cmd:lag(7 10)} compares current volatility
with volatility observed approximately 1–1.5 weeks earlier when using daily data.
The recent window is fixed internally by the EVI algorithm; the reference window is
shifted backward by the specified lag. Thus, {cmd:lag()} defines the temporal separation
between the recent and baseline windows but does not define their length.
The window length is fixed internally by the EVI algorithm and is applied to the 
smoothed series following the value in {cmd:mov()}.

{pstd}
When daily data are used, it is not recommended to use lag values ≤ 6, as short lags may result in overlapping
windows, strong short-term autocorrelation, and day-of-week effects. A lag range of 7–28 time units 
(approximately 1–4 weeks for daily data) is recommended. When weekly data are used, {cmd:mov()} should usually 
be omitted or set to 1, and {cmd:lag()} values should be rescaled accordingly (e.g., {cmd:lag(2 6)} weeks).
Multiple lag values are evaluated within the interval defined by {cmd:lag(#1 #2)} and the one producing the 
strongest or most appropriate signal is retained.

{pstd} {cmd:c(#1 #2)} specifies the range of values for the volatility threshold
parameter {it:c} (by default 0.01 to 0.05). This parameter controls the minimum relative
increase in volatility required to indicate abnormal variability in the number of cases.

{phang2} NOTE: When running EVI in a server or automated environment, it is recommended to
specify wider ranges for {cmd:lag()} (e.g., 7 to 28) and for {cmd:c()} (e.g., 0.01 to 0.5).
Wider ranges increase computational cost but improve robustness by allowing the algorithm
to adaptively select parameter combinations that perform well across varying surveillance
conditions without manual retuning. {p_end}

{pstd} {cmd:cumulative} specifies that {it:cases} are cumulative counts over time. In this
case, {cmd:evi} converts cumulative counts to incident counts per time unit by taking
first differences, and all subsequent calculations are performed on the reconstructed
incident case series.

{pstd} {cmd:r(#)} specifies the cut-off value for {it:r} (by default 1.2), representing
the minimum relative rise in mean (moving-average) cases between two consecutive time
units that, if present, should be detected by {cmd:evi}.	

{title:Selection of best lag and c to estimate EVI}

The Epidemic Volatility Index evaluates multiple combinations of {cmd:lag()} and {cmd:c()} values. At each time point, one combination is selected according to a user-specified 
criterion reflecting detection performance.

{pstd} {cmd:youden} specifies that selection is based on the highest Youden’s J statistic (default), defined as sensitivity + specificity − 1.

{pstd} {cmd:sensitivity(#)} specifies the maximum sensitivity desired when selecting {cmd:lag()} and {cmd:c()}. Sensitivity refers to the ability 
of EVI to correctly identify time periods followed by a user-defined relative increase in mean cases, as specified by {cmd:r()}.

{pstd} {cmd:specificity(#)} specifies the maximum specificity desired when selecting {cmd:lag()} and {cmd:c()}. Specificity refers to the ability of 
EVI to correctly identify time periods not followed by such increases.

Sensitivity and specificity are computed retrospectively and quantify the accuracy of EVI in detecting user-defined increases in case counts under different parameter 
combinations. They do not represent the probability that an outbreak will occur.

{title:Time series graph options}
{pstd} {cmd:logarithmic} displays the number of cases (x-axis) in the time series in the log10 scale. 

{pstd} {cmd:nograph} suppresses the time series graph. 

{pstd} {cmd: grtittle(string)} adds a user-defined title to the time-series graph. 

{pstd} {cmd: grsave(string)} saves the graph using the specified filename. If a graph with the same name already exists, it will be overwritten (replaced).

{title:Saved dataset}

After execution, {cmd:evi} adds the following variables to the dataset: {it:day}, {it:_mov_average}, {it:_mov}, {it:_status}, {it:_lag}, {it:_c}, {it:_r}, {it:_evi}, {it:_sens}, {it:_spec}, {it:_youden}, 
{it:_sens_run}, {it:spec_run}, and {it:_evi_runlen}. These variables document the internal calculations of the EVI and the resulting alert status.

{pstd} {cmd:norsample} prevents {cmd: evi} from adding new variables to the dataset. 

{pstd}
{cmd:day}
{p_end}
Original time variable (typically day). This variable preserves the original time scale after internal transformations.

{pstd}
{cmd:_mov_average}
{p_end}
Moving-average–smoothed case series. This variable is obtained by applying the window specified in {cmd:mov()} to the original case counts and represents the input series
used for volatility calculations.

{pstd} {cmd:mov(#)} specifies the size (number of days) the moving average of cases.

{pstd}
{cmd:_status}
{p_end}
Binary epidemic alert indicator derived from the EVI statistic and user-specified thresholds. Typically coded as:
{p 8 12} 0 = no epidemic alert,   1 = epidemic alert detected
{p_end}

{pstd}
{cmd:_lag}
{p_end}
Lag value used for the comparison between recent and historical volatility. When a range is specified in {cmd:lag(#1 #2)}, this variable records the selected lag (in the 
time units of the data) used to compute the EVI statistic at each time point.

{pstd}
{cmd:_c}
{p_end}
Threshold parameter {it:c} used for outbreak detection. When a range is specified in {cmd:c(#1 #2)}, this variable records the selected value controlling the minimum
relative increase in volatility required to generate an alert.

{pstd} {cmd:_r(#)} specifies the cut-off value for {it:r}. 

{pstd}
{cmd:_evi}
{p_end}
Epidemic Volatility Index (EVI) is a dichotomous variable equal 0 when the relative increase in volatility is not larger than the  
in the recent window compared with a lagged reference window. Values greater than 1 indicate increased volatility; larger values indicate stronger epidemic signals.

{pstd}
{cmd:_sens}
{p_end}
Sensitivity of the EVI detector, computed retrospectively when epidemic periods are known or defined. This variable reflects the proportion of epidemic periods correctly
identified as alerts and is intended for performance evaluation, not real-time surveillance.

{pstd}
{cmd:_spec}
{p_end}
Specificity of the EVI detector, computed retrospectively. This variable reflects the proportion of non-epidemic periods correctly identified as non-alerts and is used for
method evaluation.

{pstd}
{cmd:_youden}
{p_end}
Youden index, defined as sensitivity + specificity − 1. This summary measure is used to evaluate and compare combinations of tuning parameters (e.g., {cmd:lag()}, {cmd:c()})
and does not directly affect outbreak detection.	

{pstd}
{cmd:_sens_run}
{p_end}
Reports the average sensitivity for runs of three or more consecutive days when the EVI was above selected cut-point.	

{pstd}
{cmd:_spec_run}
{p_end}
Reports the average specificyt for runs of three or more consecutive days when the EVI was above selected cut-point.	

{pstd}
{cmd:_eviup_runlen}
{p_end}
Reports the number of consecutive days when the EVI was above the selected cut-point.	

Note: Some variables added by {cmd:evi} may contain missing values at the beginning of the series. These missing values arise because the EVI calculation requires fully populated
moving-average, volatility, and lagged reference windows. Until sufficient prior observations are available to define both the recent and lagged comparison windows, quantities 
such as {it:_evi}, {it:_lag}, and {it:_status} cannot be computed. Similarly, {it:_sens}, {it:_spec}, and {it:_youden} are retrospective performance measures and are undefined early in the series 
when insufficient information is available.

{title:Examples}

{pstd} Smooth daily cases with a 7-day moving average and compare recent volatility to volatility from a window 14 days earlier. {p_end}
{phang2}{stata . evi cases day, mov(7) lag(14)} {p_end}

{pstd} The data for the example is taken from the COVID-19 Data Repository maintained by the Center for Systems Science and Engineering at the Johns Hopkins University (https://github.com/CSSEGISandData/COVID-19).{p_end}
{phang2} {stata "use http://fmwww.bc.edu/repec/bocode/e/evi_example_data.dta":. use http://fmwww.bc.edu/repec/bocode/e/evi_example_data.dta } {p_end}

{pstd} EVI for the first 150 days of cumulative COVID-19 data from Italy.{p_end}
{phang2} Note: It takes approximately 5 minutes to complete the command {p_end}
{phang2}{stata "evi cases day, cumulative log":. evi cases day, cumulative log} {p_end}


{title:Authors}

{pstd} Luis Furuya-Kanamori, UQ Centre for Clinical Research, The University of Queensland, Australia{p_end}
{pstd} {browse "mailto:l.furuya@uq.edu.au?subject=EVI Stata enquiry":l.furuya@uq.edu.au}{p_end}

{pstd} Polychronis Kostoulas, Faculty of Public Health, University of Thessaly, Greece{p_end}
{pstd} {browse "mailto:pkost@uth.gr?subject=EVI Stata enquiry":pkost@uth.gr}{p_end}

{pstd} Leonelo Bautista, Department of Population Health Sciences, University of Wisconsin-Madison, USA{p_end}
{pstd} {browse "mailto:lebautista@wisc.edu?subject=EVI Stata enquiry":lebautista@wisc.edu}{p_end}

{title:References}

{pstd} Kostoulas P {it:et al.} The epidemic volatility index, a novel early warning tool for identifying new waves in an epidemic. DOI:{browse "https://doi.org/10.1038/s41598-021-02622-3"}

{pstd} The Epidemic Volatility Index: Predictions for COVID-19. {browse "http://83.212.174.99:3838/"}

{title:Funding}

{pstd} LFK was supported by an Australian National Health and Medical Research Council Fellowship (APP1158469).
