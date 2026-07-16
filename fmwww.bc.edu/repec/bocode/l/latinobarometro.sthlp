{smcl}
{* *! version 1.0.0  14jul2026}{...}
{viewerjumpto "Syntax" "latinobarometro##syntax"}{...}
{viewerjumpto "Description" "latinobarometro##description"}{...}
{viewerjumpto "Options" "latinobarometro##options"}{...}
{viewerjumpto "Remarks" "latinobarometro##remarks"}{...}
{viewerjumpto "Examples" "latinobarometro##examples"}{...}
{viewerjumpto "Stored results" "latinobarometro##results"}{...}
{viewerjumpto "Author" "latinobarometro##author"}{...}
{title:Title}

{phang}
{bf:latinobarometro} {hline 2} Load, standardize, and enrich a Latinobarometro survey wave


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:latinobarometro}{cmd:,} {cmdab:y:ear(}{it:#}{cmd:)} [{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{cmdab:y:ear(}{it:#}{cmd:)}}survey year to load (See available years); {bf:required}{p_end}
{synopt:{opt rename}}rename all variables to standardized cross-year names using the official Latinobarometro time-series crosswalk{p_end}
{synopt:{opt addp:opulation}}add World Bank population-based sampling weights at the country level; {bf:requires} {opt rename}{p_end}

{syntab:Caching}
{synopt:{opt force}}ignore any cached files (survey data zip, crosswalk Excel file, population data) and re-download everything fresh{p_end}
{synopt:{opt cache(string)}}override the default cache folder location. The default lives "latinobarometro_cache" {p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:latinobarometro} downloads (or reuses a cached copy of) a single year's
Latinobarometro survey wave, loads the English-language {cmd:.dta} file,
sanitizes variable names and value-label names that are invalid in Stata
(accented/Unicode characters and periods), and optionally:

{phang2}
1. renames every variable to a standardized name that is consistent
across survey years, using the official Latinobarometro "Serie de
Tiempo" crosswalk file, and

{phang2}
2. merges in World Bank total-population data by country and
constructs a population-based sampling weight ({cmd:wt_lac}) suitable
for pooled cross-country analysis.

{pstd}
All downloaded files (survey zips, the crosswalk Excel file, and the
World Bank population extract) are cached locally so that repeated
calls to {cmd:latinobarometro} do not require re-downloading. Use the
{opt force} option to bypass the cache and fetch fresh copies.

{pstd}
{bf:This program only downloads from latinobarometro.org.} There is
deliberately no fallback mirror: Latinobarometro's own terms of use
prohibit republishing their data on other websites, so no alternate
source is built in. If latinobarometro.org is temporarily unreachable,
{cmd:latinobarometro} will report a clear download error rather than
silently substituting another source. The local cache still means any
year you have already successfully loaded once remains available
offline indefinitely, regardless of the site's availability.


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt year(#)} specifies the four-digit survey year to load, e.g.
{cmd:year(2020)}. {bf:This option is required.} The year must be one
covered by the internal year-to-URL lookup table (1995-2018, 2020,
2023, 2024 at the time of writing); years not yet added to the table
will produce an error directing you to update it.

{phang}
{opt rename} renames every matched variable from its raw, year-specific
name (e.g. {cmd:P12STGBS} in the 2020 file) to a standardized name that
is stable across years (e.g. {cmd:A_001_001}), and attaches the
corresponding English variable label. Renaming is driven entirely by
the official Latinobarometro crosswalk file (xlsx), downloaded and cached
automatically; no local copy needs to be supplied by the user. Only
variables with a non-missing mapping for the requested year are
renamed; everything else is left untouched.

{phang}
{opt addpopulation} adds two country-level variables constructed from
World Bank population data ({cmd:sp.pop.totl}): {cmd:total_sample}
(the sample size collected in that country) and {cmd:wt_lac} (a
weight rescaling the sample to be proportional to each country's
actual population. Use with proper weight and survey optins). {bf:This option requires}
{opt rename} to have already been specified in the same call, since it
depends on the standardized {cmd:X_001} (country code) and
{cmd:X_020} (original sample weight) variables that only exist after
renaming.

{dlgtab:Caching}


{phang}
{opt force} ignores every cache (the survey-year zip, the crosswalk
Excel file, and the population extract, as applicable to the options
specified) and re-downloads all of them fresh. Use this if you suspect
Latinobarometro has updated a file, or if a cached file appears
corrupted.

{phang}
{opt cache(string)} overrides the default folder used to store all
cached downloads. If not specified, files are cached to a fixed
default path ("`c(sysdir_personal)'latinobarometro_cache/year").
The folder is created automatically if it does not already exist.


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:latinobarometro} loads exactly one survey year per call. To build a
pooled panel across multiple years, call {cmd:latinobarometro} in a loop,
{cmd:save} or {cmd:append} the result after each call, and use
{opt rename} (and typically {opt addpopulation}) consistently across
all years so that variable names line up. For example:

{phang2}{cmd:. tempfile all}{p_end}
{phang2}{cmd:. latinobarometro, year(2007) rename addpopulation local}{p_end}
{phang2}{cmd:. save `all', replace}{p_end}
{phang2}{cmd:. foreach y of numlist 2008/2020 {c -(}}{p_end}
{phang2}{cmd:.     capture latinobarometro, year(`y') rename addpopulation local}{p_end}
{phang2}{cmd:.     if !_rc {c -(}}{p_end}
{phang2}{cmd:.         append using `all'}{p_end}
{phang2}{cmd:.         save `all', replace}{p_end}
{phang2}{cmd:.     {c )-}}{p_end}
{phang2}{cmd:. {c )-}}{p_end}

{pstd}
Wrapping each call in {cmd:capture} is recommended when looping over a
range of years, since not every year in the range is necessarily a
survey year (e.g. 2012, 2014, 2019 do not exist), and the year lookup
table may not yet cover every year you request.

{pstd}
The variable-name and value-label sanitization steps run unconditionally
on every call, regardless of whether {opt rename} is specified, since
some years' raw files contain variable names or value-label names with
characters that are not valid in Stata (in particular, periods, which
caused certain years to fail to load prior to this fix).


{marker examples}{...}
{title:Examples}

{pstd}Load a single year with no further processing{p_end}
{phang2}{cmd:. latinobarometro, year(2018)}{p_end}

{pstd}Load a year and standardize variable names{p_end}
{phang2}{cmd:. latinobarometro, year(2018) rename}{p_end}

{pstd}Load a year, standardize variable names, and add population weights {p_end}
{phang2}{cmd:. latinobarometro, year(2018) rename addpopulation}{p_end}


{pstd}Force a fresh re-download of everything for this year, bypassing all caches{p_end}
{phang2}{cmd:. latinobarometro, year(2020) rename addpopulation force}{p_end}

{pstd}Use a custom cache folder{p_end}
{phang2}{cmd:. latinobarometro, year(2020) rename cache("/Users/me/Desktop/lb_cache")}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:latinobarometro} does not leave behind any {cmd:r()} or {cmd:e()} results.
Its output is the loaded-and-processed dataset itself, left in memory
after the command completes, exactly as {cmd:use} would.

{marker Issues}{...}
{title:Issues}

{pstd}
{cmd:latinobarometro} uses the official Excel crosswalk file to rename the variables of each survey wave in order to have a harmonized multiple-year database. This harmonization is not free from errors, for example, multiple coded answers that are not specifically labeled in the Excel are not rename. For example, The variable for the Social Network Services used is {cmd:P83TNC_?} where {cmd:?} represents a different social network. Since the Excel file doesn't list every social network, the {cmd:renamed} file will still have the year-specific same (P83TNC_?), not the harmonized one (E_003_001). Currently, the issue is being considered.

{pstd}
LAC wide weights {cmd:wt_lac} should be used with caution. Latinobarometro typically covers 18+ respondents, and each country has it's own survey design, so pooling should respond to specific work.


{marker author}{...}
{title:Author}

{pstd}Jorge Soler-Lopez{p_end}
{pstd}jorge.solerlopez@phd.unibocconi.it{p_end}
{pstd}Bocconi University{p_end}

{marker Citations}{...}
{title:Citations & Usage}

{pstd}
As per Latinobarometro all datasets are available for non-commercial research, teaching, and publications.
Cite as follows (changing for the year that is used):

{pstd}
Latinobarómetro Study 2023. Latinobarómetro Corporation: 2023 Wave – Aggregated Version: https://www.latinobarometro.org/latinobarometro-2023. Madrid: JD Systems Institute.


