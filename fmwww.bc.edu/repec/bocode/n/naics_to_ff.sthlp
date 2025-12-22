{smcl}
{* *! version 1.0  19dec2025}{...}
{vieweralsosee "[D] generate" "help generate"}{...}
{vieweralsosee "sic_to_ff" "help sic_to_ff"}{...}
{viewerjumpto "Syntax" "naics_to_ff##syntax"}{...}
{viewerjumpto "Description" "naics_to_ff##description"}{...}
{viewerjumpto "Options" "naics_to_ff##options"}{...}
{viewerjumpto "Stored results" "naics_to_ff##results"}{...}
{viewerjumpto "Remarks" "naics_to_ff##remarks"}{...}
{viewerjumpto "Examples" "naics_to_ff##examples"}{...}
{viewerjumpto "Technical Notes" "naics_to_ff##technical"}{...}
{viewerjumpto "References" "naics_to_ff##references"}{...}
{viewerjumpto "Author" "naics_to_ff##author"}{...}
{title:Title}

{phang}
{bf:naics_to_ff} {hline 2} Convert NAICS codes to Fama-French industry classifications


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:naics_to_ff}
{varname}
{ifin}
{cmd:,} {opth gen:erate(newvar)} [{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opth gen:erate(newvar)}}name of new variable to create{p_end}

{syntab:Optional}
{synopt:{opt sch:eme(#)}}industry classification scheme: 5, 10, 12, 17, 30, 38, 48, or 49; default is {bf:48}{p_end}
{synopt:{opt lab:els}}apply value labels to the new variable{p_end}
{synopt:{opt replace}}overwrite existing variable{p_end}
{synopt:{opt nomissing}}force mapped SICs into "Other" if outside FF ranges{p_end}
{synopt:{opt diag:nostics}}display detailed mapping diagnostics{p_end}

{syntab:Mapping transparency}
{synopt:{opth sic:gen(newvar)}}save the mapped SIC code{p_end}
{synopt:{opth source:gen(newvar)}}save mapping source (dorn/census/manual/fallback/compustat){p_end}
{synopt:{opth weight:gen(newvar)}}save employment weight from the Dorn crosswalk{p_end}

{pstd}
{opt weightgen()} reports employment weights from the Dorn crosswalk (or market-cap
weights when {opt compustat()} is used) and is only populated under
{opt method(maxweight)}; for {opt method(skipaux)} and {opt method(first)} it is missing.

{syntab:Fallback}
{synopt:{opth fall:back(varname)}}use this variable (e.g., sich) when NAICS mapping fails{p_end}

{syntab:Comparison}
{synopt:{opth com:pare(varname)}}compare with SIC-based classification{p_end}

{syntab:Method}
{synopt:{opt meth:od(string)}}SIC selection method: {bf:maxweight}, {bf:skipaux}, or {bf:first}; default is {bf:maxweight}{p_end}

{syntab:Compustat weights}
{synopt:{opth compu:stat(filename)}}use Compustat annual data for market-cap weighted NAICS-to-SIC mapping{p_end}
{synopt:{opth year:var(varname)}}variable for time-varying weights (by fiscal year){p_end}
{synopt:{opt cy:ear(#)}}fixed calendar year for weights (e.g., 2020){p_end}
{synopt:{opt nofall:back}}disable Dorn fallback for NAICS codes not in Compustat{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:naics_to_ff} converts North American Industry Classification System (NAICS)
codes to Fama-French industry classifications. This is a companion command to
{helpb sic_to_ff}.

{pstd}
Requires {helpb sic_to_ff} version 1.1 or later.

{pstd}
The command works in two steps:

{phang}1. Maps NAICS codes to SIC codes using the Dorn crosswalk (with employment
weights) supplemented by the Census 2002 concordance{p_end}
{phang}2. Maps SIC codes to Fama-French industries using Ken French definitions{p_end}

{pstd}
The command includes 1,463 NAICS code mappings covering NAICS 1997-2022 vintages:

{p2colset 5 25 27 2}{...}
{p2col:Source}Coverage{p_end}
{p2line}
{p2col:{bf:Dorn crosswalk}}1,239 codes (includes NAICS 2022 codes recovered via concordance chaining){p_end}
{p2col:{bf:Census concordance}}222 codes (primarily agricultural production NAICS 111xxx-112xxx){p_end}
{p2col:{bf:Manual mappings}}2 codes for new industries (519130 Internet Publishing,
517919 All Other Telecom){p_end}
{p2line}
{p2colreset}{...}

{pstd}
Six of the 1,463 codes map to auxiliary SIC codes (70001/40001) and are treated
as unmapped for FF classification; excluding these, the effective mapping count
is 1,457 (1,233 Dorn + 222 Census + 2 manual).

{pstd}
For NAICS codes that cannot be mapped (truncated codes, newer industries), use the
{opt fallback()} option to specify a SIC variable to use as a fallback.


{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{opth generate(newvar)} specifies the name of the new variable to be created
containing the Fama-French industry code.

{dlgtab:Optional}

{phang}
{opt scheme(#)} specifies which Fama-French industry classification scheme
to use. Valid values are 5, 10, 12, 17, 30, 38, 48, or 49. The default is 48.

{phang}
{opt labels} attaches value labels to the new variable.

{phang}
{opt replace} permits overwriting an existing variable (also applies to {opt sicgen},
{opt sourcegen}, and {opt weightgen}).

{phang}
{opt nomissing} forces any mapped SIC code into "Other" if it falls outside
Ken French's explicit SIC ranges for the chosen scheme. This option cannot
assign industries to NAICS codes that are missing from the NAICS-to-SIC mapping.

{phang}
{opt diagnostics} displays detailed mapping diagnostics including source
distribution, FF industry distribution, non-6-digit NAICS warnings, and top
unmapped NAICS codes.

{dlgtab:Mapping transparency}

{phang}
{opth sicgen(newvar)} saves the intermediate SIC code mapped from the NAICS code.
Useful for auditing classifications and understanding the two-step mapping.

{phang}
{opth sourcegen(newvar)} saves the mapping source: "dorn" for codes from the
Dorn crosswalk (employment-weighted), "census" for codes from the Census
2002 concordance, "manual" for manually assigned newer industry codes,
"fallback" when the fallback variable was used, or "compustat" when
the {opt compustat()} option was used for market-cap weighted mapping.

{phang}
{opth weightgen(newvar)} saves the mapping weight. For default Dorn/Census mapping,
this is the employment weight from the Dorn crosswalk (missing for Census-sourced codes).
For {opt compustat()} mapping, this is the market-cap share used for SIC selection.
{bf:Note:} Weights are only populated when {opt method(maxweight)} is used; with other
methods the weight variable will be missing (to avoid confusion about which SIC the
weight refers to).

{dlgtab:Fallback}

{phang}
{opth fallback(varname)} specifies a variable to use as the SIC code when NAICS
mapping fails or is unavailable. This is useful for handling:

{p2colset 9 30 32 2}{...}
{p2col:{bf:Missing NAICS}}Observations with blank or missing NAICS codes{p_end}
{p2col:{bf:Truncated NAICS}}Compustat often stores 2-5 digit NAICS codes (e.g., "212"
instead of "212xxx") which cannot be mapped to specific SIC codes{p_end}
{p2col:{bf:Newer industries}}Some NAICS 2017/2022 codes represent industries that
did not exist in 2002 and have no SIC equivalent{p_end}
{p2col:{bf:Invalid codes}}Placeholder codes like "999990" in Compustat{p_end}
{p2colreset}{...}

{pstd}
When specified, observations without a successful NAICS-to-SIC mapping (including
those with missing NAICS) will use the fallback variable as their SIC code for FF
classification. The {opt sourcegen()} variable will show "fallback" for these
observations. The fallback variable must contain valid SIC codes (numeric or
string, 4-digit, <= 9999). String values are automatically trimmed of whitespace.

{pstd}
{bf:Example:} With Compustat data containing both {it:naics} and {it:sich}:

        {cmd:. naics_to_ff naics, gen(ff48) fallback(sich) diagnostics}

{pstd}
This maps NAICS codes first, then uses {it:sich} for any observations where NAICS
is missing or mapping failed, achieving higher coverage than NAICS alone.

{dlgtab:Comparison}

{phang}
{opth compare(varname)} computes the FF industry classification from a user-supplied
SIC variable and reports concordance statistics. This directly operationalizes
the validation comparison between NAICS-based and SIC-based classifications.
The SIC variable may be numeric or string. Note: the {opt nomissing} option does not
affect the compare SIC classification, ensuring an unbiased concordance measure.

{dlgtab:Method}

{phang}
{opt method(string)} specifies which SIC selection strategy to use when a NAICS
code maps to multiple SIC codes:

{p2colset 9 22 24 2}{...}
{p2col:{bf:maxweight}}(default) Choose the SIC with the highest employment weight
from the Dorn crosswalk. This is the most economically meaningful selection.{p_end}
{p2col:{bf:skipaux}}Like maxweight, but excludes auxiliary SIC codes (70001, 40001, etc.).
Use this for Compustat data where auxiliary codes produce missing FF values.
Note: NAICS codes that only map to auxiliary SICs will have missing values,
which may reduce coverage compared to maxweight.{p_end}
{p2col:{bf:first}}Uses the first-listed SIC from the original crosswalk ordering
(typically by SIC code), which may differ from maxweight for some NAICS codes.
Useful for sensitivity analysis or replicating non-weighted mappings.{p_end}
{p2colreset}{...}

{pstd}
{bf:Concrete Example: NAICS 493110 (General Warehousing)}

{pstd}
This NAICS code maps to multiple SICs with different employment weights:

        {c TLC}{hline 20}{c TT}{hline 12}{c TT}{hline 15}{c TRC}
        {c |} SIC Code           {c |} Weight     {c |} Description   {c |}
        {c LT}{hline 20}{c +}{hline 12}{c +}{hline 15}{c RT}
        {c |} 70001 (auxiliary)  {c |}   0.46     {c |} Services aux  {c |}
        {c |} 4225               {c |}   0.32     {c |} Gen Warehousing{c |}
        {c |} 4226               {c |}   0.22     {c |} Special Warehousing{c |}
        {c BLC}{hline 20}{c BT}{hline 12}{c BT}{hline 15}{c BRC}

{pstd}
Method selection results:

{p2colset 9 22 24 2}{...}
{p2col:{bf:maxweight}}selects SIC 70001 (highest weight) {c -}> {bf:FF = missing} (aux code){p_end}
{p2col:{bf:skipaux}}selects SIC 4225 (highest non-aux) {c -}> {bf:FF48 = 40} (Transportation){p_end}
{p2col:{bf:first}}selects SIC 4225 (lowest code #) {c -}> {bf:FF48 = 40} (Transportation){p_end}
{p2colreset}{...}

{pstd}
{bf:What are auxiliary SIC codes?}

{pstd}
The SIC system includes "auxiliary establishments" {c -} support units that serve
other establishments in the same company (e.g., corporate headquarters,
centralized warehouses, data processing centers). These don't have regular
4-digit SIC codes. In Dorn's crosswalk, they are coded as 5-digit placeholders:

{p2colset 9 14 16 2}{...}
{p2col:{bf:20001}}Auxiliary for Manufacturing (SIC sector 2){p_end}
{p2col:{bf:40001}}Auxiliary for Transportation/Utilities (SIC sector 4){p_end}
{p2col:{bf:70001}}Auxiliary for Services (SIC sector 7){p_end}
{p2colreset}{...}

{pstd}
Since these codes exceed 9999, they fall outside Ken French's SIC ranges and
produce missing FF industry values. Use {opt method(skipaux)} to avoid them.


{dlgtab:Compustat weights}

{phang}
{opth compustat(filename)} enables market-cap weighted NAICS-to-SIC mapping using
your own Compustat annual fundamental data file. This is an alternative to the
default Dorn employment-weighted crosswalk.

{pstd}
{opt compustat()} requires {opt method(maxweight)} (the default); other methods are
not supported.

{pstd}
{bf:Required Compustat variables:}

{p2colset 9 22 24 2}{...}
{p2col:{bf:naics}}NAICS code (string or numeric){p_end}
{p2col:{bf:sich}}Historical SIC code{p_end}
{p2col:{bf:prcc_f}}Fiscal year-end stock price{p_end}
{p2col:{bf:csho}}Common shares outstanding{p_end}
{p2col:{bf:fyear}}Fiscal year{p_end}
{p2colreset}{...}

{pstd}
Market capitalization is calculated as {it:prcc_f} × {it:csho}. For each NAICS code
(and optionally each year), the command aggregates market cap by SIC code and
selects the SIC with the highest total market cap as the mapping.

{phang}
{opth yearvar(varname)} specifies a variable in your current dataset (e.g., {it:fyear})
to match against the Compustat mapping file. This enables {bf:time-varying weights}:
each observation is mapped using the market-cap weights from its corresponding year.
Mutually exclusive with {opt cyear()}.

{phang}
{opt cyear(#)} specifies a fixed calendar year to use for all observations' weights.
For example, {cmd:cyear(2020)} uses market-cap weights computed from fiscal year 2020
Compustat data for all observations, regardless of their actual year.
Mutually exclusive with {opt yearvar()}.

{phang}
{opt nofallback} prevents falling back to the Dorn crosswalk for NAICS codes not
found in the Compustat mapping. By default (without this option), NAICS codes that
cannot be mapped via Compustat are mapped using the embedded Dorn/Census crosswalk.
With {opt nofallback}, unmapped NAICS codes will have missing SIC values.

{pstd}
{bf:Example: Time-varying market-cap weights}

        {cmd:. naics_to_ff naics, gen(ff48) compustat("compustat_annual.dta") yearvar(fyear)}

{pstd}
This maps each firm-year using the market-cap weighted NAICS-to-SIC from that year's
Compustat data. Firms with NAICS codes not in Compustat will fall back to Dorn weights.

{pstd}
{bf:Example: Fixed year weights}

        {cmd:. naics_to_ff naics, gen(ff48) compustat("compustat_annual.dta") cyear(2020)}

{pstd}
This maps all observations using 2020 market-cap weights. Useful for cross-sectional
analysis or when you want consistent weights across all observations.

{pstd}
{bf:Example: Compustat-only mapping (no Dorn fallback)}

        {cmd:. naics_to_ff naics, gen(ff48) compustat("compustat_annual.dta") cyear(2020) nofallback}

{pstd}
This uses only Compustat-derived weights. NAICS codes not found in Compustat 2020
will have missing FF industry values.


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:naics_to_ff} stores the following in {cmd:r()}:

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}total observations in sample{p_end}
{synopt:{cmd:r(N_naics)}}observations with non-missing NAICS code{p_end}
{synopt:{cmd:r(N_naics_mapped)}}NAICS codes successfully mapped to SIC{p_end}
{synopt:{cmd:r(N_naics_unmapped)}}NAICS codes not mapped to SIC (given method){p_end}
{synopt:{cmd:r(N_ff_mapped)}}observations with FF industry assignment{p_end}
{synopt:{cmd:r(N_ff_unmapped)}}SIC mapped but no FF assignment (SIC outside Ken French ranges){p_end}
{synopt:{cmd:r(naics_map_rate)}}percent of NAICS codes mapped to SIC{p_end}
{synopt:{cmd:r(ff_map_rate)}}percent of observations with FF assignment{p_end}

{pstd}
With {opt fallback()}:

{synopt:{cmd:r(N_fallback)}}observations using fallback SIC variable{p_end}

{pstd}
With {opt compare()}:

{synopt:{cmd:r(N_concordant)}}observations with same FF from NAICS and SIC{p_end}
{synopt:{cmd:r(N_discordant)}}observations with different FF from NAICS and SIC{p_end}
{synopt:{cmd:r(N_comparable)}}observations with both FF assignments non-missing{p_end}
{synopt:{cmd:r(concordance_rate)}}percent concordance{p_end}

{pstd}
With {opt compustat()}:

{synopt:{cmd:r(N_compustat_mapped)}}observations mapped via Compustat market-cap weights{p_end}
{synopt:{cmd:r(N_dorn_fallback)}}observations using Dorn fallback (when not {opt nofallback}){p_end}
{synopt:{cmd:r(cyear)}}fixed year used (if {opt cyear()} specified){p_end}
{synopt:{cmd:r(nofallback)}}1 if {opt nofallback} specified, 0 otherwise{p_end}

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Macros}{p_end}
{synopt:{cmd:r(scheme)}}FF scheme used{p_end}
{synopt:{cmd:r(varname)}}name of the created variable{p_end}
{synopt:{cmd:r(method)}}SIC selection method used{p_end}
{synopt:{cmd:r(fallback_var)}}name of fallback variable (if {opt fallback()} specified){p_end}
{synopt:{cmd:r(compare_var)}}name of SIC variable compared (if {opt compare()} specified){p_end}
{synopt:{cmd:r(compustat_file)}}path to Compustat file (if {opt compustat()} specified){p_end}
{synopt:{cmd:r(yearvar)}}year variable name (if {opt yearvar()} specified){p_end}
{p2colreset}{...}


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Validation}

{pstd}
Using Compustat firm-years (2006-2024) with both SIC and NAICS codes available,
I find 93.3% concordance between SIC-based and NAICS-based FF48 classifications.
The 6.7% discordance is concentrated in Finance/Real Estate and Business Services
boundaries.


{marker examples}{...}
{title:Examples}

{pstd}Basic usage:{p_end}
{phang2}{cmd:. naics_to_ff naics, gen(ff48)}{p_end}

{pstd}With labels and diagnostics:{p_end}
{phang2}{cmd:. naics_to_ff naicsh, gen(ff48) labels diagnostics}{p_end}
{phang2}{cmd:. return list}{p_end}

{pstd}Check mapping rate:{p_end}
{phang2}{cmd:. display "Mapping rate: " r(naics_map_rate) "%"}{p_end}

{pstd}Expose underlying mapping for auditing:{p_end}
{phang2}{cmd:. naics_to_ff naicsh, gen(ff48) sicgen(mapped_sic) sourcegen(map_src)}{p_end}
{phang2}{cmd:. tab map_src}{p_end}

{pstd}Compare NAICS-based vs SIC-based classifications (Compustat example):{p_end}
{phang2}{cmd:. naics_to_ff naicsh, gen(ff48_naics) compare(sich)}{p_end}
{phang2}{cmd:. display "Concordance: " r(concordance_rate) "%"}{p_end}

{pstd}Use skipaux method to avoid auxiliary SIC codes:{p_end}
{phang2}{cmd:. naics_to_ff naicsh, gen(ff48) method(skipaux)}{p_end}

{pstd}Sensitivity analysis across methods:{p_end}
{phang2}{cmd:. naics_to_ff naicsh, gen(ff48_max) method(maxweight)}{p_end}
{phang2}{cmd:. naics_to_ff naicsh, gen(ff48_skip) method(skipaux) replace}{p_end}
{phang2}{cmd:. gen differ = (ff48_max != ff48_skip) if !missing(ff48_max, ff48_skip)}{p_end}
{phang2}{cmd:. tab differ}{p_end}


{marker technical}{...}
{title:Technical Notes}

{phang}1. Both numeric and string NAICS variables are accepted. String NAICS codes
are cleaned (whitespace and hyphens removed) before conversion. Hyphenated sector
ranges like {bf:31-33} are treated as missing (with a warning) to avoid accidental
creation of bogus numeric codes. If string values contain non-numeric characters
that cannot be parsed, a warning is displayed and those observations are treated
as missing NAICS.{p_end}

{phang}2. The mapping data (1,463 NAICS-to-SIC codes) is embedded directly in the
ado file. Six of these map to auxiliary SIC codes (>9999) and are treated as
unmapped for FF classification, leaving 1,457 effective mappings. No external
.dta file is required. The program preserves sort order ({opt sortpreserve}).{p_end}

{phang}2a. The {opt method()} option controls SIC selection: {bf:maxweight} (default)
uses the SIC with highest employment weight from the Dorn crosswalk; {bf:skipaux}
uses the highest-weight non-auxiliary SIC (excludes 70001, 40001 which produce
missing FF values); {bf:first} uses the first-listed SIC from the original
crosswalk ordering, which differs from maxweight for some NAICS codes.{p_end}

{phang}2b. For Census-sourced NAICS codes (210 agricultural codes), only one SIC
mapping exists per code. The {opt method()} option has no effect on these codes.{p_end}

{phang}3. Six NAICS codes have auxiliary SIC as their max-weight mapping (70001, 40001).
With the default {opt method(maxweight)}, these will have missing FF values unless
{opt nomissing} is specified. With {opt method(skipaux)}, four of these codes (493110,
493120, 493130, 493190) receive valid non-auxiliary SICs; two codes (551114, 950000)
have no non-auxiliary alternative and remain missing.{p_end}

{phang}3a. Auxiliary SIC observations are counted in {cmd:r(N_ff_unmapped)} separately
from {cmd:r(N_naics_unmapped)}.{p_end}

{phang}4. Non-6-digit NAICS codes trigger a warning by default (e.g., 5-digit or 7-digit
codes). Additionally, fractional/decimal NAICS values (e.g., 541711.5) trigger a
separate warning. Both indicate potential data quality issues. The {opt diagnostics}
option provides additional detail on top unmapped codes.{p_end}

{phang}5. {bf:NAICS vintage:} The crosswalk is based on NAICS 1997/2002 codes. Datasets
using later NAICS vintages (2007, 2012, 2017, 2022) may have reduced coverage
due to new codes not in the mapping, and potential conceptual drift where code
meanings have shifted even when digits match.{p_end}


{marker references}{...}
{title:References}

{pstd}
Autor, Dorn, and Hanson. 2013. "The China Syndrome." {it:AER} 103(6): 2121-2168.

{pstd}
Kenneth R. French Data Library:
{browse "https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html"}


{marker author}{...}
{title:Author}

{pstd}
Kelvin Law, Nanyang Business School, NTU Singapore


{title:Also see}

{psee}
Online: {helpb sic_to_ff}, {helpb generate}
{p_end}
