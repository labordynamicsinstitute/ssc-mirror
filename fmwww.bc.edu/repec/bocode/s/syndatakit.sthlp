{smcl}
{* *! syndatakit v0.3.0  15 March 2026}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "help python" "help python"}{...}
{vieweralsosee "help sdkprofiles" "help sdkprofiles"}{...}
{viewerjumpto "Syntax" "syndatakit##syntax"}{...}
{viewerjumpto "Description" "syndatakit##description"}{...}
{viewerjumpto "Options" "syndatakit##options"}{...}
{viewerjumpto "Examples" "syndatakit##examples"}{...}
{viewerjumpto "Installation" "syndatakit##installation"}{...}
{viewerjumpto "Citation" "syndatakit##citation"}{...}
{title:Title}

{phang}
{bf:syndatakit} {hline 2} Generate synthetic econometric and financial data


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:syndatakit}{cmd:,} {opt profile(name)} [{it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt profile(name)}}dataset profile to generate; see {help sdkprofiles}{p_end}

{syntab:Size}
{synopt:{opt n(#)}}number of synthetic rows to generate; default is 1000{p_end}

{syntab:Scenario}
{synopt:{opt scenario(name)}}economic scenario: {bf:recession}, {bf:severe},
    {bf:rate_shock}, or {bf:expansion}{p_end}
{synopt:{opt intensity(#)}}scenario intensity from 0.0 to 1.0; default is 1.0{p_end}

{syntab:Reproducibility}
{synopt:{opt seed(#)}}random seed for exact reproducibility{p_end}

{syntab:Privacy}
{synopt:{opt dp}}enable formal (epsilon, delta) differential privacy{p_end}
{synopt:{opt epsilon(#)}}privacy budget epsilon; default is 1.0; lower = more private{p_end}

{syntab:Data management}
{synopt:{opt clear}}clear current dataset before loading{p_end}
{synopt:{opt replace}}allow replacing output file if saving{p_end}
{synopt:{opt nogen}}display profile metadata without generating data{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:syndatakit} calls the {browse "https://github.com/Nityahapani/syndatakit":syndatakit}
Python package to generate synthetic tabular data calibrated to the
statistical properties of real econometric and financial datasets.  Generated
data preserves marginal distributions, Spearman rank correlations, VAR(1)
temporal dynamics, and GARCH volatility structure.  It contains zero real
individuals and requires no data use agreements.

{pstd}
Eighteen built-in profiles cover macroeconomic indicators (FRED), mortgage
origination (HMDA), bank call reports (FDIC), equity returns, corporate bonds,
insurance, real estate, tax statistics, and commodity markets.  Each profile
is calibrated against published aggregate statistics from U.S. federal agencies
and international statistical bodies.

{pstd}
Fidelity scores range from 81.7% (IRS SOI, limited by extreme income tail)
to 95.0% (CFTC, FDIC).  The fidelity score combines marginal moment agreement
(45%), KS distributional fit (30%), and Spearman correlation distance (25%).
Full reproduction code is available at
{browse "https://github.com/Nityahapani/syndatakit/blob/main/validation/"}.

{pstd}
To list all available profiles with fidelity scores, sources, and variable
counts, run {cmd:sdkprofiles}.


{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{opt profile(name)} specifies which dataset profile to generate.  Use
{cmd:sdkprofiles} to see all available profiles.  Example profiles include:
{bf:fred_macro} (8 macroeconomic variables), {bf:hmda} (7 mortgage variables),
{bf:equity_returns} (11 return and risk factor variables).

{dlgtab:Size}

{phang}
{opt n(#)} specifies the number of synthetic rows to generate.  The Python
package has no practical upper limit; very large values (> 1,000,000) may
require significant memory.  Default is 1,000.

{dlgtab:Scenario}

{phang}
{opt scenario(name)} applies an economic scenario shift to all generated
variables.  Available scenarios:
{p_end}
{pmore}{bf:recession} - moderate demand contraction, rising unemployment{p_end}
{pmore}{bf:severe} - severe recession, financial stress conditions{p_end}
{pmore}{bf:rate_shock} - rapid interest rate increases, credit tightening{p_end}
{pmore}{bf:expansion} - above-trend growth, falling unemployment{p_end}

{phang}
{opt intensity(#)} scales the scenario shift continuously from 0.0 (no shift)
to 1.0 (full scenario).  Allows generating intermediate stress scenarios.
Default is 1.0.

{dlgtab:Reproducibility}

{phang}
{opt seed(#)} sets the Python random seed before generation.  Using the same
profile, n, and seed produces identical output on any machine with the same
syndatakit version installed.  Recommended for replication packages.

{dlgtab:Privacy}

{phang}
{opt dp} enables formal (epsilon, delta)-differential privacy using the
Laplace mechanism on marginal statistics and the Wishart mechanism on the
correlation matrix.  Privacy budget is tracked and reported.

{phang}
{opt epsilon(#)} sets the privacy budget.  Smaller values mean more privacy
and lower fidelity.  epsilon = 1.0 is a standard moderate-privacy setting.
epsilon = 0.1 is strong privacy with noticeable fidelity reduction.
epsilon = 10.0 provides minimal privacy but near-nominal fidelity.
Default is 1.0.

{dlgtab:Data management}

{phang}
{opt clear} clears the current dataset in memory before loading synthetic
data.  Equivalent to running {cmd:clear} before {cmd:syndatakit}.

{phang}
{opt nogen} displays metadata for the requested profile (source, variable
count, fidelity score, variable descriptions) without generating any data.
Useful for exploring available profiles.


{marker examples}{...}
{title:Examples}

{pstd}
Generate 1,000 rows of FRED macroeconomic indicators:{p_end}
{phang2}{cmd:. syndatakit, profile(fred_macro) n(1000) clear}{p_end}

{pstd}
Generate 10,000 mortgage applications under a rate shock scenario:{p_end}
{phang2}{cmd:. syndatakit, profile(hmda) n(10000) scenario(rate_shock) intensity(0.8) clear}{p_end}

{pstd}
Generate equity return data with a reproducibility seed:{p_end}
{phang2}{cmd:. syndatakit, profile(equity_returns) n(5000) seed(2026) clear}{p_end}

{pstd}
Generate FDIC call report data with differential privacy (epsilon = 0.5):{p_end}
{phang2}{cmd:. syndatakit, profile(fdic) n(2000) dp epsilon(0.5) clear}{p_end}

{pstd}
View profile metadata without generating data:{p_end}
{phang2}{cmd:. syndatakit, profile(irs_soi) nogen}{p_end}

{pstd}
List all 18 available profiles:{p_end}
{phang2}{cmd:. sdkprofiles}{p_end}

{pstd}
Generate BLS employment data and immediately run a regression:{p_end}
{phang2}{cmd:. syndatakit, profile(bls) n(3000) clear}{p_end}
{phang2}{cmd:. regress weekly_wage avg_weekly_hours labor_force_part}{p_end}


{marker installation}{...}
{title:Installation}

{pstd}
{bf:Requirements:} Stata 16 or later with Python integration enabled.
Python 3.8 or later with syndatakit installed.

{pstd}
Step 1: Verify Python is available in Stata:{p_end}
{phang2}{cmd:. python query}{p_end}

{pstd}
Step 2: Install the syndatakit Python package:{p_end}
{phang2}{cmd:. python: import subprocess; subprocess.run(["pip", "install", "syndatakit"])}{p_end}

{pstd}
Step 3 (once published on SSC):{p_end}
{phang2}{cmd:. ssc install syndatakit}{p_end}

{pstd}
Step 3 (manual installation):{p_end}
{pmore}
Copy {bf:syndatakit.ado} and {bf:syndatakit.sthlp} to your personal ado directory.
{p_end}
{pmore}
On Unix/Mac: {bf:~/ado/personal/}{p_end}
{pmore}
On Windows: {bf:C:\ado\personal\}{p_end}


{marker citation}{...}
{title:Citation}

{pstd}
If you use syndatakit in published research, please cite:{p_end}

{pmore}
Hapani, N. (2026).  syndatakit: Production-grade synthetic data generation
for econometrics and finance.  {it:Journal of Open Source Software}.
{browse "https://doi.org/10.XXXXX/joss.XXXXX"}
{p_end}

{pstd}
BibTeX:{p_end}

{phang2}
{cmd:@article}{c -(}hapani2026syndatakit,{break}
{col 4}author  = {c -(}Hapani, Nitya{c )},{break}
{col 4}title   = {c -(}{c -(}syndatakit{c )}: Production-grade synthetic data generation for econometrics and finance{c )},{break}
{col 4}journal = {c -(}Journal of Open Source Software{c )},{break}
{col 4}year    = {c -(}2026{c )},{break}
{col 4}doi     = {c -(}10.XXXXX/joss.XXXXX{c )}{break}
{c )}
{p_end}


{title:Author}

{pstd}
Nitya Hapani{break}
{browse "mailto:nitya@syndatakit.com":nitya@syndatakit.com}{break}
{browse "https://github.com/Nityahapani/syndatakit"}
{p_end}


{title:Also see}

{psee}
{helpb sdkprofiles}: List all available syndatakit profiles{break}
{helpb python}: Stata Python integration{break}
{browse "https://github.com/Nityahapani/syndatakit/blob/main/validation/"}: Full fidelity validation code
{p_end}
