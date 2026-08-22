{smcl}
{* *! version 1.0.1  21aug2026}{...}
{vieweralsosee "gvar" "help gvar"}{...}
{vieweralsosee "gvar references" "help gvar_references"}{...}
{vieweralsosee "gvar solve" "help gvar_solve"}{...}
{vieweralsosee "gvar wetest" "help gvar_wetest"}{...}
{vieweralsosee "gvar diag" "help gvar_diag"}{...}
{vieweralsosee "gvar avgcorr" "help gvar_avgcorr"}{...}
{vieweralsosee "gvar pp" "help gvar_pp"}{...}
{vieweralsosee "gvar methods" "help gvar_methods"}{...}
{viewerjumpto "Syntax" "gvar_report##syntax"}{...}
{viewerjumpto "Description" "gvar_report##description"}{...}
{viewerjumpto "What it checks" "gvar_report##checks"}{...}
{viewerjumpto "Remarks" "gvar_report##remarks"}{...}
{viewerjumpto "Examples" "gvar_report##examples"}{...}
{viewerjumpto "Stored results" "gvar_report##results"}{...}
{viewerjumpto "Options" "gvar_report##options"}{...}
{title:Title}

{phang}
{bf:gvar report} {hline 2} one specification audit of the fitted model


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:gvar report} [{cmd:,} {opt psc(#)} {opt step(#)}]

{synoptset 32 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt psc(#)}}lag order for the serial-correlation test. Default {cmd:psc(4)}.{p_end}
{synopt:{opt step(#)}}horizon at which persistence profiles must have settled.
Default {cmd:step(24)}.{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:gvar report} runs the checks a referee would ask for, in the order they
matter, and reduces each to a line or two. It is a triage tool: it tells you
which of the detailed subcommands to go and read, and it flags the ones whose
answer is outside the range the literature reports for a well-specified GVAR.

{pstd}
Nothing here is new arithmetic. Every number is produced by the subcommand
named in the right margin of its section, run quietly. If a section worries
you, run that subcommand yourself and read the full table.


{marker checks}{...}
{title:What it checks}

{synoptset 22}{...}
{synopthdr:section}
{synoptline}
{synopt:1. solve}largest eigenvalue modulus, explosive roots, and whether the
number of unit roots equals {it:K} - sum {it:r_i}. A disagreement means the
ranks and the dynamics are telling you different things.{p_end}
{synopt:2. wetest}share of weak-exogeneity tests rejected at 5%. Dees, di Mauro,
Pesaran and Smith report 5-10% for a correctly specified GVAR; above 15%
{cmd:gvar report} says so.{p_end}
{synopt:3. avgcorr}mean absolute pairwise correlation in the levels against
the same statistic in the residuals, and the ratio. This is the one number
that says whether the foreign variables did their job.{p_end}
{synopt:4. diag}counts of equations failing serial correlation, normality and
ARCH.{p_end}
{synopt:5. pp}how many cointegrating relations are still above 0.10 at horizon
{cmd:step()}.{p_end}
{synoptline}


{marker options}{...}
{title:Options}

{phang}
{opt psc(#)} the serial-correlation order carried into the diagnostic block,
default 4, and {opt step(#)} the horizon used for the dynamic checks, default 24.

{phang}
{opt graph} draws the dashboard, {opt panels(spec)} chooses which panels appear,
and {opt name()} names it.

{pmore}
The whole panel list is validated before anything is drawn. A misspelled panel
name is an error up front rather than a half-built dashboard: the alternative is
a figure that is missing something and does not say so.

{phang}
{opt nosummary} suppresses the report.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Read section 3 first.} A GVAR exists to make the country models
conditionally independent. If the mean absolute residual correlation is not
much smaller than the mean absolute correlation in the levels, the foreign
variables have not absorbed the common factors, and the generalized impulse
responses -- which are conditional on the residual covariance -- are not
telling you about country-specific shocks.

{pstd}
{bf:Non-normality is not a defect.} Quarterly macroeconomic data is
routinely non-normal, and generalized responses need only the first two
moments. Serial correlation is different: it says the lag orders are too
short, and it biases everything downstream.

{pstd}
{bf:The section 1 check is a real test, not a formality.} A GVAR with {it:K}
endogenous variables and sum {it:r_i} cointegrating relations must have
exactly {it:K} - sum {it:r_i} eigenvalues on the unit circle. More unit roots
than that means a rank has been understated somewhere; fewer means one has
been overstated. Either way the long-run behaviour of the solved system is not
the long-run behaviour the individual rank tests implied.

{pstd}
{bf:What it does not do.} {cmd:gvar report} runs only the asymptotic versions
of the diagnostics, because the bootstrap ones take minutes. At GVAR
dimensions the asymptotic multivariate tests are badly oversized -- see
{helpb gvar_diag:gvar diag} -- so treat section 4 as a screen, and settle the
question with {cmd:gvar diag, multivariate reps(200)}.


{marker examples}{...}
{title:Examples}

{pstd}The whole audit{p_end}
        {cmd:. gvar report}

{pstd}A longer settling horizon and a longer serial-correlation lag{p_end}
        {cmd:. gvar report, step(40) psc(8)}

{pstd}Keep the headline numbers{p_end}
        {cmd:. gvar report}
        {cmd:. display "WE rejection rate: " 100*r(wetest_rej)/r(wetest_tot) "%"}
        {cmd:. display "dependence reduced by a factor of " r(corr_lev)/r(corr_res)}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gvar report} stores the following in {cmd:r()}:

{synoptset 26 tabbed}{...}
{synopt:{cmd:r(wetest_rej)}}weak-exogeneity tests rejected at 5%{p_end}
{synopt:{cmd:r(wetest_tot)}}weak-exogeneity tests computed{p_end}
{synopt:{cmd:r(corr_lev)}}mean absolute correlation, levels{p_end}
{synopt:{cmd:r(corr_res)}}mean absolute correlation, residuals{p_end}
{synopt:{cmd:r(nequations)}}equations in the system{p_end}
{synoptline}


{marker source}{...}
{title:Source}

{pstd}
Reporting command. The checks and the ranges they are judged against follow
the specification tables of Dees, di Mauro, Pesaran and Smith (2007) and the
diagnostic output of GVAR Toolbox 2.0.

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
