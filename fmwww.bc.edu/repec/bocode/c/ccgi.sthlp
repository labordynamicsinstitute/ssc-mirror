{smcl}
{* 11June2026 Wu Lianghai & Wu Hanyan (Version 3.6)}
{hline}
help for {hi:ccgi}
{hline}

{title:Title}

{p 8 12 2}
{hi:ccgi} {hline 2} China Corporate Governance Index (CCGI)

{title:Syntax}

{p 8 16 2}
{cmd:ccgi} {varlist} [{cmd:if}] [{cmd:in}] {cmd:,}
    {cmd:reverse(}{it:varlist}{cmd:)}   (may be abbreviated {cmd:rev()})
    [{cmd:winsor(}{it:p1 p2}{cmd:)}]   (may be abbreviated {cmd:w()})
    [{cmd:missing(}{it:method}{cmd:)}]   (may be abbreviated {cmd:m()})
    [{cmd:replace}]   (may be abbreviated {cmd:rep})
    [{cmd:exportdta(}{it:filename}{cmd:)}]   (may be abbreviated {cmd:expd()})
    [{cmd:exportexcel(}{it:filename}{cmd:)}]   (may be abbreviated {cmd:expe()})

{title:Description}

{p 4 4 2}
{cmd:ccgi} constructs the China Corporate Governance Index (CCGI) using 12
governance indicators with equal weights. The program automatically performs
Min-Max normalization and distinguishes between forward and reverse indicators.
All variables are assigned descriptive labels.

{p 4 4 2}
After running {cmd:ccgi}, the dataset remains in memory with all original
variables, normalized variables (prefixed with "n_"), and the newly created
{cmd:ccgi_index} variable, allowing for further analysis.

{title:Options}

{p 8 12 2}
{cmd:reverse(}{it:varlist}{cmd:)} (may be abbreviated {cmd:rev()}) specifies the
list of reverse indicators. Variables not listed are treated as forward indicators.

{p 8 12 2}
Reverse indicator normalization: {it:(max - x)/(max - min)}

{p 8 12 2}
Forward indicator normalization: {it:(x - min)/(max - min)}

{p 8 12 2}
{cmd:winsor(}{it:p1 p2}{cmd:)} (may be abbreviated {cmd:w()}) performs
winsorization at the specified percentiles. This option MUST include two
percentiles. Examples:{break}
  {cmd:winsor(1 99)}         (1st and 99th percentiles){break}
  {cmd:winsor(2 98)}         (2nd and 98th percentiles){break}
  {cmd:winsor(0.5 99.5)}     (0.5th and 99.5th percentiles){break}
{it:p1} and {it:p2} must be numbers with {it:p1 < p2}. Winsorization is applied
before normalization. Binary variables (0/1 or only two distinct values) are
automatically skipped and a message is displayed.

{p 8 12 2}
By default, if {cmd:winsor()} is not specified, no winsorization is performed.

{p 8 12 2}
{cmd:missing(}{it:method}{cmd:)} (may be abbreviated {cmd:m()}) handles missing
values in the 12 governance indicators. Available methods:{break}
  {cmd:missing(drop)}   - Drop observations with any missing values{break}
  {cmd:missing(mean)}   - Impute missing values with variable means{break}
  {cmd:missing(median)} - Impute missing values with variable medians{break}
  {cmd:missing(zero)}   - Impute missing values with zeros{break}
If this option is not specified, the program will use the data as is, and any
missing values will result in missing CCGI scores (since rowmean returns missing
if any component is missing).

{p 8 12 2}
{cmd:replace} (may be abbreviated {cmd:rep}) allows overwriting existing DTA or
Excel files. Without this option, the program will issue an error if output
files already exist.

{p 8 12 2}
{cmd:exportdta(}{it:filename}{cmd:)} (may be abbreviated {cmd:expd()}) saves the
dataset (including original variables, normalized variables, and CCGI) as a
Stata DTA file. The dataset remains in memory after saving, allowing you to
continue your analysis without reloading the data.

{p 8 12 2}
{cmd:exportexcel(}{it:filename}{cmd:)} (may be abbreviated {cmd:expe()}) exports
the same dataset to an Excel file with variable names in the first row. The
dataset remains in memory after export, allowing for seamless workflow integration.

{p 8 12 2}
{cmd:Tip:} You can use both {cmd:exportdta()} and {cmd:exportexcel()} together
in the same command to save both file formats simultaneously while keeping the
data in memory for immediate use.

{title:Remarks}

{p 4 4 2}
1. Exactly 12 variables must be provided. The order of variables does not matter.

{p 4 4 2}
2. If an indicator has no variation across observations (min = max), it is set
to 0.5 after normalization with a warning message.

{p 4 4 2}
3. Missing values can be handled automatically using the {cmd:missing()} option.
If not handled, observations with any missing values will have missing CCGI scores.

{p 4 4 2}
4. Winsorization uses Stata's {cmd:_pctile} command. Binary variables (e.g.,
{cmd:dual_role}, {cmd:audit_committee}) are automatically excluded from winsorization.
No winsorization is applied unless {cmd:winsor(p1 p2)} is explicitly specified.

{p 4 4 2}
5. Normalized variables are renamed with prefix "n_" (e.g., {cmd:n_board_size})
and given descriptive labels.

{p 4 4 2}
6. After running {cmd:ccgi}, the dataset remains in memory. All original variables,
normalized variables, and the {cmd:ccgi_index} are available for further analysis.

{p 4 4 2}
7. The program returns the following scalars:{break}
   {cmd:r(mean_ccgi)}      - Mean of CCGI{break}
   {cmd:r(sd_ccgi)}        - Standard deviation of CCGI{break}
   {cmd:r(min_ccgi)}       - Minimum value of CCGI{break}
   {cmd:r(p25_ccgi)}       - 25th percentile of CCGI{break}
   {cmd:r(median_ccgi)}    - Median of CCGI{break}
   {cmd:r(p75_ccgi)}       - 75th percentile of CCGI{break}
   {cmd:r(max_ccgi)}       - Maximum value of CCGI

{title:Examples}

{p 8 12 2}
* Example 1: Basic usage without winsorization

{p 8 12 2}
{stata ccgi board_size indep_ratio mgt_share top1_share top5_share top10_share meeting_freq audit_committee dual_role salary disclosure_quality ipo_year, reverse(top1_share dual_role) exportdta(ccgi_result.dta)}

{p 8 12 2}
* Example 2: With winsorization at 1st and 99th percentiles

{p 8 12 2}
{stata ccgi board_size indep_ratio mgt_share top1_share top5_share top10_share meeting_freq audit_committee dual_role salary disclosure_quality ipo_year, rev(top1_share dual_role) winsor(1 99) rep expd(ccgi_result.dta)}

{p 8 12 2}
* Example 3: Custom winsorization (2% and 98%) with replace

{p 8 12 2}
{stata ccgi board_size indep_ratio mgt_share top1_share top5_share top10_share meeting_freq audit_committee dual_role salary disclosure_quality ipo_year, rev(top1_share dual_role) w(2 98) rep}

{p 8 12 2}
* Example 4: With sample restriction and missing value handling

{p 8 12 2}
{stata local g_vars "board_size indep_ratio mgt_share top1_share top5_share top10_share meeting_freq audit_committee dual_role salary disclosure_quality ipo_year"}

{p 8 12 2}
{stata ccgi `g_vars' if year==2025, rev(top1_share dual_role) winsor(0.5 99.5) missing(median) rep expd(ccgi_2025.dta)}

{p 8 12 2}
* Example 5: Export both DTA and Excel simultaneously

{p 8 12 2}
{stata ccgi `g_vars', rev(top1_share dual_role) winsor(1 99) rep expd(ccgi_result.dta) expe(ccgi_result.xlsx)}

{p 8 12 2}
* Example 6: Run CCGI and continue analysis (data remains in memory)

{p 8 12 2}
{stata ccgi `g_vars', rev(top1_share dual_role) winsor(1 99)}

{p 8 12 2}
{stata summarize ccgi_index}

{p 8 12 2}
{stata gen ccgi_above_median = ccgi_index > r(median_ccgi)}

{p 8 12 2}
* Example 7: Using returned scalars

{p 8 12 2}
{stata ccgi `g_vars', rev(top1_share dual_role) winsor(1 99)}

{p 8 12 2}
{stata return list}

{p 8 12 2}
{stata gen ccgi_centered = ccgi_index - r(mean_ccgi)}

{title:Required Variables}

{p 4 4 2}
The following 12 variables must be present in the dataset:{break}
{cmd:board_size}      - Board size (number of directors){break}
{cmd:indep_ratio}     - Proportion of independent directors (%){break}
{cmd:mgt_share}       - Management shareholding ratio (%){break}
{cmd:top1_share}      - Largest shareholder ownership (%){break}
{cmd:top5_share}      - Top5 shareholders ownership (%){break}
{cmd:top10_share}     - Top10 shareholders ownership (%){break}
{cmd:meeting_freq}    - Board meeting frequency (times per year){break}
{cmd:audit_committee} - Audit committee existence (1=yes, 0=no){break}
{cmd:dual_role}       - CEO duality (1=CEO is Chair, 0=no){break}
{cmd:salary}          - Executive compensation (log or level){break}
{cmd:disclosure_quality} - Information disclosure rating{break}
{cmd:ipo_year}        - Years since IPO (or IPO year){break}

{title:Option Abbreviations}

{p 4 4 2}
The following abbreviations are supported:{break}
{cmd:reverse()}   can be abbreviated as {cmd:rev()}{break}
{cmd:winsor()}    can be abbreviated as {cmd:w()}{break}
{cmd:missing()}   can be abbreviated as {cmd:m()}{break}
{cmd:replace}     can be abbreviated as {cmd:rep}{break}
{cmd:exportdta()} can be abbreviated as {cmd:expd()}{break}
{cmd:exportexcel()} can be abbreviated as {cmd:expe()}{break}

{title:Forward vs Reverse Indicators}

{p 4 4 2}
Forward indicators: Higher values indicate better corporate governance
(e.g., board independence, meeting frequency, disclosure quality)

{p 4 4 2}
Reverse indicators: Lower values indicate better corporate governance
(e.g., largest shareholder ownership, CEO duality)

{title:Other Commands I Have Written}

{p 4 4 2}
{cmd:mysuite} (if installed) {stata ssc install mysuite} (to install){break}
{cmd:mysuite} provides a collection of utility commands for data management,
regression diagnostics, and result export. See {help mysuite} for details.

{title:Also see}

{p 4 4 2}
Help: {help winsor2}, {help egen}, {help collapse}, {help export}, {help return},
{help winsor}, {help trimmean}

{title:Version History}

{p 4 4 2}
{cmd:Version 3.6} (11 June 2026):{break}
  - Fixed {cmd:exportdta()} and {cmd:exportexcel()} to properly save files
    while keeping data in memory{break}
  - Added confirmation message "Data remains in memory for further analysis"{break}
  - Improved Excel export to preserve memory state using temporary files

{p 4 4 2}
{cmd:Version 3.5} (11 June 2026):{break}
  - Winsorization now requires explicit percentiles{break}
  - Added warning for missing values handling

{p 4 4 2}
{cmd:Version 3.0-3.4}:{break}
  - Initial public releases with basic CCGI functionality

{title:Authors}

{p 8 12 2}
Wu Lianghai{break}
School of Business, Anhui University of Technology (AHUT){break}
Ma'anshan, China{break}
Email: {browse "mailto:agd2010@yeah.net":agd2010@yeah.net}

{p 8 12 2}
Wu Hanyan{break}
School of Economics and Management, Nanjing University of Aeronautics and Astronautics (NUAA){break}
Nanjing, China{break}
Email: {browse "mailto:2325476320@qq.com":2325476320@qq.com}

{p 8 12 2}
Development Date: 11 June 2026
{hline}