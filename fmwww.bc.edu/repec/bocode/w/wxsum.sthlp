{smcl}
{* *! version 5.0 12jun2026}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "wxsum##syntax"}{...}
{viewerjumpto "Description" "wxsum##description"}{...}
{viewerjumpto "Options" "wxsum##options"}{...}
{viewerjumpto "Examples" "wxsum##examples"}{...}
{title:Title}

{phang}
{bf:wxsum} {hline 2} A command for processing temperature and precipitation data

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:wxsum}
{it:stubname}
{cmd:,}
{opt type(rain|temp)}
{opt ini_month(month)}
{opt fin_month(month)}
		[{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt type(rain|temp)}}Specify {it:rain} for rainfall data or {it:temp} for temperature data.{p_end}
{synopt:{opt ini_month(month)}}Initial month of the season (e.g., 05 for May){p_end}
{synopt:{opt fin_month(month)}}Final month of the season (e.g., 10 for October){p_end}

{syntab:General}
{synopt:{opt ini_day(day)}}Start day of the season. Default is 01.{p_end}
{synopt:{opt fin_day(day)}}End day of the season. Defaults to the last day of the final month.{p_end}
{synopt:{opt lr_years(#)}}Number of strictly preceding years used to calculate rolling deviations and Z-scores. Default is 10. Max is 50.{p_end}
{synopt:{opt rain_threshold(#)}}Threshold for defining a rainy day. Defaults to 1. Missing rainfall values are excluded from rain-day and dry-spell calculations.{p_end}
{synopt:{opt gdd_lo(#)}}Lower bound for growing degree days calculation (required if type(temp) is used).{p_end}
{synopt:{opt gdd_hi(#)}}Upper bound for growing degree days calculation (required if type(temp) is used).{p_end}
{synopt:{opt kdd_base(#)}}Temperature threshold for calculating Killing Degree Days (KDD) (required if type(temp) is used).{p_end}
{synopt:{opt gdd_bin(#)}}Width of fixed-interval seasonal GDD categories.{p_end}
{synopt:{opt gdd_binlo(#)}}Lower endpoint for regular GDD intervals. Default 0.{p_end}
{synopt:{opt gdd_binhi(#)}}Upper endpoint for regular GDD intervals; values at or above are top-coded.{p_end}
{synopt:{opt tmp_bin(#)}}Total number of daily temperature bin count variables per season. Integer from 1 to 42.{p_end}
{synopt:{opt tmp_binlo(#)}}Lower bound of the temperature range for bin construction. Required with {opt tmp_bin()}.{p_end}
{synopt:{opt tmp_binhi(#)}}Upper bound of the temperature range for bin construction. Required with {opt tmp_bin()}.{p_end}
{synopt:{opt shape(wide|long)}}Shape of the final output. Default is {it:wide}.{p_end}
{synopt:{opt keep(varlist)}}Variables to keep in the final dataset along with the generated wxsum variables.{p_end}
{synopt:{opt save(filename)}}File path to save the resulting dataset.{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:wxsum} processes remote sensing rainfall and temperature data and outputs useful seasonal statistics. It can be used with either rainfall or temperature data from any source.

{marker remarks}{...}
{title:Remarks}

{pstd}
{ul:Data format requirements}

{pstd}
The data must be wide, where each location is a row and each column is a daily reading. Daily weather variable names must be the user-supplied prefix followed by {it:yyyymmdd}. For example, if the prefix is {it:rf_}, the variable for May 15, 1979 would be {it:rf_19790515}. 

{pstd}
{ul:Command syntax}

{pstd}
The general syntax of the command requires specifying a prefix, a data type, and the season's start and end months.

{pstd}
- After the command name, one has to define what variables contain the rain/temperature information by providing their common prefix (stub). For example, if the data contain variables named {it:rf_19790101}, {it:rf_19790102}, and so on, the prefix supplied to the command is {it:rf_}. Variables not beginning with the specified prefix are ignored unless they are retained by using the {opt keep()} option.

{pstd}
- Next, one needs to tell the command whether the data is {opt type(rain)} or {opt type(temp)}.

{pstd}
- One then has to select a season to study using the options {opt ini_month(month)}, {opt fin_month(month)}, {opt ini_day(day)}, and {opt fin_day(day)}. If the day options are not specified, the command dynamically defaults to the true last calendar day of the final month. For example, to choose a season from the middle of March to the middle of June, you would set ini_month(03), fin_month(06), ini_day(15), fin_day(15). The command seamlessly handles seasons that span across calendar years, such as November to February, keeping the data associated with the year the season starts.

{pstd}
- The {opt keep(varlist)} option tells the command to keep the variables it creates plus some of the original variables in order to match them with other datasets.

{pstd}
- The {opt save(filename)} option tells the program to save the dataset in a given location with a given name.

{pstd}
{ul:Long-run averages}

{pstd}
Z-scores and deviations from long-run averages are computed strictly against the specified number of preceding {opt lr_years}. If there is not enough historical preceding data to satisfy the user-defined {opt lr_years} constraint, deviations and z-scores are skipped for those initial years, though standard variables are still generated.

{marker options}{...}
{title:Options}

{phang}
{opt type(temp)} processes temperature variables to generate:
{break}- mean daily in a season
{break}- median daily in a season
{break}- variance of daily in a season
{break}- standard deviation of daily in a season
{break}- skew of daily in a season
{break}- max daily in a season
{break}- gdd in a season
{break}- deviations from long run average gdd in a season
{break}- z-score of gdd in a season
{break}- GDD category variable {it:gddcat_YEAR} (when {opt gdd_bin()} is specified)
{break}- kdd in a season
{break}- deviations from long run average kdd in a season
{break}- z-score of kdd in a season
{break}- daily temperature bin count variables {it:tmpbinXX_YEAR} (when {opt tmp_bin()} is specified)

{phang}
{opt type(rain)} processes rainfall variables to generate:
{break}- mean daily in a season
{break}- median daily in a season
{break}- variance of daily in a season
{break}- standard deviation of daily in a season
{break}- skew of daily in a season
{break}- mean of monthly rainfall totals in a season
{break}- deviation from long run average of mean monthly rainfall in a season
{break}- z-score of mean monthly rainfall in a season
{break}- total seasonal
{break}- deviation from long run average of total seasonal
{break}- z-score of total seasonal
{break}- number of observed days with rain in a season
{break}- deviation from long run average of rainy days in a season
{break}- z-score of rainy days in a season
{break}- number of observed days without rain in a season
{break}- deviation from long run average of days without rain in a season
{break}- z-score of days without rain in a season
{break}- percentage of days with rain in a season
{break}- deviation from the long run average of percentage of days with rain in a season
{break}- z-score of percentage of days with rain in a season
{break}- length of leading dry spell at the start of a season
{break}- longest mid-season dry spell
{break}- length of trailing dry spell at the end of a season

{phang}
{opt ini_month(month)} specifies the starting month of the season. 

{phang}
{opt fin_month(month)} specifies the ending month of the season. Seasons can span across calendar years (e.g., November to February).

{phang}
{opt ini_day(day)} specifies the day the season begins. If not specified, it defaults to 01.

{phang}
{opt fin_day(day)} specifies the day the season ends. If not specified, it dynamically defaults to the exact last day of the final month in the given season, correctly accounting for leap years.

{phang}
{opt lr_years(#)} Sets the rolling window history size for calculating deviations from the long run average. Defaults to 10.

{phang}
{opt rain_threshold(#)} allows the user to define what counts as a rainy day. Default is 1. Missing rainfall values are excluded from rain-day, no-rain-day, percentage, and dry-spell calculations.

{phang}
{opt gdd_lo(#)} specifies the lower temperature threshold for calculating Growing Degree Days.

{phang}
{opt gdd_hi(#)} specifies the upper temperature threshold for calculating Growing Degree Days.

{phang}
{opt kdd_base(#)} specifies the threshold temperature above which to calculate Killing Degree Days.

{phang}
{opt gdd_bin(#)} specifies the fixed width of seasonal GDD categories. When specified, {cmd:wxsum} creates one integer categorical variable {it:gddcat_YYYY} for each generated GDD season. The categories are defined over fixed-width intervals of the seasonal GDD total, following the approach used in Deschênes and Greenstone-style specifications. The user can then use Stata's factor-variable notation (e.g., {cmd:i.gddcat_1993}) to generate dummies in estimation commands. The command assigns Stata value labels to each category so that {cmd:tabulate gddcat_1993} displays the GDD intervals. The bin width is specified in the same units as the generated GDD variable. Requires {opt type(temp)}.

{phang}
{opt gdd_binlo(#)} specifies the lower endpoint at which regular fixed-width GDD intervals begin. Default is 0 when {opt gdd_bin()} is specified. If any seasonal GDD total falls below this value, a bottom-coded category "GDD < {it:#}" is created. Requires {opt gdd_bin()}.

{phang}
{opt gdd_binhi(#)} specifies the upper endpoint at which regular fixed-width GDD intervals end. Values at or above this endpoint are assigned to a top-coded category "GDD >= {it:#}". When omitted, the command automatically extends the regular intervals to cover the empirical maximum. Requires {opt gdd_bin()}. Must be greater than {opt gdd_binlo()}. The range ({opt gdd_binhi()} - {opt gdd_binlo()}) must be evenly divisible by {opt gdd_bin()}.

{phang}
{opt tmp_bin(#)} specifies the total number of daily temperature bin count variables to create per season. Must be a positive integer from 1 to 42. Requires {opt type(temp)} and both {opt tmp_binlo()} and {opt tmp_binhi()}.

{pmore}
These are daily temperature bin counts based on one observed daily temperature reading per day, in the spirit of Schlenker-Roberts. When only one daily reading is available, the entire day is assigned to the bin containing that reading.

{pmore}
The command is unit agnostic: the user must supply {opt tmp_binlo()} and {opt tmp_binhi()} in the same units as the daily temperature data.

{pmore}
Missing daily temperatures are not counted in any bin. If all daily temperatures for a location-season are missing, all {it:tmpbinXX_YYYY} variables for that location-season are set to missing. Otherwise, the sum of all {it:tmpbinXX_YYYY} equals the number of nonmissing daily temperature readings in that season.

{pmore}
For {opt tmp_bin(J)} with J >= 3, the bins are constructed as follows. Let lo = {opt tmp_binlo()}, hi = {opt tmp_binhi()}, and w = (hi - lo) / (J - 2). Then:
{break}  tmpbin01 counts days with T < lo (lower tail)
{break}  tmpbin02 counts days with lo <= T < lo + w
{break}  tmpbin03 counts days with lo + w <= T < lo + 2w
{break}  ...
{break}  tmpbinJJ counts days with T >= hi (upper tail)

{pmore}
Formally:
{break}  tmpbin_it^(1)   = sum_d 1{c -(}T_id < lo{c )-}
{break}  tmpbin_it^(j)   = sum_d 1{c -(}lo + (j-2)w <= T_id < lo + (j-1)w{c )-},  j = 2,...,J-1
{break}  tmpbin_it^(J)   = sum_d 1{c -(}T_id >= hi{c )-}
{break}  where w = (hi - lo) / (J - 2)

{pmore}
Interior bins are lower-closed and upper-open. The lower tail is strictly below lo. The upper tail is at or above hi.

{pmore}
Schlenker-Roberts-style lower-tail/interior/upper-tail bins are obtained with {opt tmp_bin(3)} or larger. Common fine-bin specifications use values such as {opt tmp_bin(15)} or {opt tmp_bin(42)}.

{pmore}
Special cases for small J:
{break}- {opt tmp_bin(1)}: Creates a single variable counting all nonmissing daily temperature readings. {opt tmp_binlo()} and {opt tmp_binhi()} are required for syntax consistency but are not used for assignment.
{break}- {opt tmp_bin(2)}: Splits at the midpoint m = (lo + hi) / 2. tmpbin01 counts T < m, tmpbin02 counts T >= m.

{phang}
{opt tmp_binlo(#)} specifies the lower bound of the temperature range for bin construction. Required when {opt tmp_bin()} is specified. Must be in the same units as the daily temperature data.

{phang}
{opt tmp_binhi(#)} specifies the upper bound of the temperature range for bin construction. Required when {opt tmp_bin()} is specified. Must be greater than {opt tmp_binlo()} and in the same units as the daily temperature data.

{phang}
{opt shape(wide|long)} specifies the shape of the final output. The default is {it:wide}, producing one row per spatial/analytic unit with year-suffixed variable names (e.g., {it:mean_1993}, {it:tmpbin01_1993}).

{pmore}
When {opt shape(long)} is specified, the final output is stacked long with one row per retained unit-year. A variable named {it:year} is created to identify the season year. Generated variables have their {it:_YYYY} suffixes stripped (e.g., {it:mean}, {it:tmpbin01}). Variables specified in {opt keep()} are repeated across years.

{pmore}
It is strongly recommended to use {opt keep(id ...)} or {opt keep()} with whatever merge keys are needed when {opt shape(long)} is requested. If {opt keep()} is empty, a note is printed but no error occurs.

{pmore}
{opt shape(long)} is a final-output stacking operation; the wide input requirement is unchanged. It can make panel workflows easier and can reduce the final number of variables when many years or temperature bins are generated, although it does not yet reduce the peak number of variables created internally.

{pmore}
If a variable named {it:year} is included in {opt keep()}, the command exits with an error to prevent naming conflicts.

{phang}
{opt keep(varlist)} specifies variables to keep in the final output (e.g., location identifiers).

{phang}
{opt save(filename)} saves the output dataset.

{phang}
Growing degree days are calculated as capped degree accumulation: {cmd:min(max(temp - gdd_lo, 0), gdd_hi - gdd_lo)}, summed over the season.

{phang}
Variance requires at least 2 non-missing observations. Skewness is calculated as the adjusted Fisher-Pearson sample skewness. It requires at least 3 non-missing observations.

{phang}
Dry spells are calculated strictly from non-missing rainfall data. A dry day is defined as rainfall strictly less than {opt rain_threshold(#)}. A rainy day is rainfall greater than or equal to {opt rain_threshold(#)}. Missing daily rainfall values are excluded from dry counts and break consecutive dry spells.
{break}- {it:dry_start_YYYY} captures the length of the leading dry spell before the first rainy day or missing value.
{break}- {it:dry_YYYY} captures the longest mid-season dry spell strictly after the first observed rainy day and strictly before the last observed rainy day.
{break}- {it:dry_end_YYYY} captures the trailing dry spell after the last rainy day or missing value.

{phang}
GDD categories are constructed over the seasonal GDD total, not over daily temperatures. Let tau_0 < tau_1 < ... < tau_J be fixed cutpoints generated from {opt gdd_bin()}, {opt gdd_binlo()}, and either {opt gdd_binhi()} or the automatic endpoint. Then {it:gddcat_it} = j if tau_{j-1} <= GDD_it < tau_j. If a bottom-coded category is needed, {it:gddcat_it} = 1 when GDD_it < tau_0. If a top-coded category is requested, {it:gddcat_it} = J+1 when GDD_it >= tau_J.

{marker examples}{...}
{title:Examples}

{phang}{cmd:. use rain.dta, clear}{p_end}
{phang}{cmd:. wxsum rf_, type(rain) ini_month(05) fin_month(10) ini_day(15) fin_day(15)}{p_end}

{phang}{cmd:. use temp.dta, clear}{p_end}
{phang}{cmd:. wxsum tmp_, type(temp) ini_month(11) fin_month(02) gdd_lo(8) gdd_hi(32) kdd_base(32) keep(hhid)}{p_end}

{phang}{cmd:. * GDD categories example}{p_end}
{phang}{cmd:. wxsum tmp_, type(temp) ini_month(04) ini_day(01) fin_month(09) fin_day(15) gdd_lo(18) gdd_hi(30) kdd_base(32) gdd_bin(100) gdd_binlo(50) gdd_binhi(950) keep(hhid)}{p_end}

{phang}{cmd:. * Daily temperature bin counts example}{p_end}
{phang}{cmd:. wxsum tmp_, type(temp) ini_month(04) ini_day(01) fin_month(09) fin_day(15) gdd_lo(18) gdd_hi(30) kdd_base(32) tmp_bin(15) tmp_binlo(0) tmp_binhi(39) keep(hhid)}{p_end}

{phang}{cmd:. * Changing the long-run benchmark}{p_end}
{phang}{cmd:. use rain.dta, clear}{p_end}
{phang}{cmd:. wxsum rf_, type(rain) ini_month(05) fin_month(10) lr_years(20) keep(hhid)}{p_end}

{phang}{cmd:. * Long output for panel workflows}{p_end}
{phang}{cmd:. use rain.dta, clear}{p_end}
{phang}{cmd:. wxsum rf_, type(rain) ini_month(05) fin_month(10) ini_day(15) fin_day(15) rain_threshold(1) keep(hhid) shape(long)}{p_end}

{title:Authors}

{pstd}Jeffrey D. Michler{p_end}
{pstd}Anna Josephson{p_end}
{pstd}Oscar Barriga-Cabanillas{p_end}
{pstd}Aleksandr Michuda{p_end}
{pstd}Jeffrey C. Oliver{p_end}
