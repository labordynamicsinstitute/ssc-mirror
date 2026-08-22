{smcl}
{* *! version 1.0.1  21aug2026}{...}
{vieweralsosee "gvar" "help gvar"}{...}
{vieweralsosee "gvar estimate" "help gvar_estimate"}{...}
{vieweralsosee "gvar stability" "help gvar_stability"}{...}
{vieweralsosee "gvar lags" "help gvar_lags"}{...}
{vieweralsosee "gvar methods" "help gvar_methods"}{...}
{vieweralsosee "gvar bconv" "help gvar_bconv"}{...}
{vieweralsosee "gvar contemp" "help gvar_contemp"}{...}
{viewerjumpto "Syntax" "gvar_diag##syntax"}{...}
{viewerjumpto "Description" "gvar_diag##description"}{...}
{viewerjumpto "Remarks" "gvar_diag##remarks"}{...}
{viewerjumpto "Examples" "gvar_diag##examples"}{...}
{viewerjumpto "Stored results" "gvar_diag##results"}{...}
{viewerjumpto "Options" "gvar_diag##options"}{...}
{title:Title}

{phang}
{bf:gvar diag} {hline 2} residual diagnostics, equation by equation and system-wide


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:gvar diag} [{cmd:,} {it:options}]

{synoptset 32 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt psc(#)}}order of the serial-correlation F test. Default 4.{p_end}
{synopt:{opt arch(#)}}order of the univariate ARCH-LM test. Default 4.{p_end}
{synopt:{opt multi:variate}}add the system-wide tests.{p_end}
{synopt:{opt lagspt(#)}}portmanteau order. Default 16.{p_end}
{synopt:{opt lagsbg(#)}}Breusch-Godfrey order. Default 5.{p_end}
{synopt:{opt mvarch(#)}}multivariate ARCH order. Default 2.{p_end}
{synopt:{opt reps(#)}}bootstrap p-values from this many replications.{p_end}
{synopt:{opt seed(#)}}random-number seed for the bootstrap.{p_end}
{synopt:{opt det:ail}}residual descriptives, White heteroskedasticity, R-squared.{p_end}
{synopt:{opt nosum:mary}}suppress the tables.{p_end}
{synopt:{opt saving(name)} {opt savemv(name)}}save the univariate and multivariate matrices.{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:gvar diag} reports the Toolbox's per-equation battery - serial
correlation F, Jarque-Bera, ARCH-LM, skewness and kurtosis - and, with
{cmd:multivariate}, the system-wide tests that GVARX adds: multivariate
Jarque-Bera, the portmanteau statistics Qh and Qh*, multivariate ARCH-LM, the
Breusch-Godfrey LM and the Edgerton-Shukur F.

{pstd}
An equation can look clean one at a time and still fail as a system, because
the univariate tests ignore the contemporaneous correlation across the
equations of the same country model.


{marker options}{...}
{title:Options}

{phang}
{opt psc(#)} the order of the serial-correlation F test, default 4, and
{opt arch(#)} the order of the ARCH test, default 4.

{phang}
{opt multivariate} adds the system-wide tests, with {opt lagspt(#)} the
Portmanteau lag length (default 16), {opt lagsbg(#)} the multivariate
Breusch-Godfrey order (default 5), and {opt mvarch(#)} the multivariate ARCH
order (default 2).

{phang}
{opt reps(#)} and {opt seed(string)} bootstrap the critical values rather than
using asymptotic ones, which matters here: the asymptotic distributions of the
system-wide statistics are poor approximations at {it:T} = 134 with {it:K} = 136.

{phang}
{opt detail} prints the per-equation table rather than the per-unit summary.

{phang}
{opt graph} and {opt name()} plot each statistic against its cutoff;
{opt saving()} and {opt savemv(name)} write the univariate and multivariate
tables to datasets. {opt nosummary} suppresses the report.

{pmore}
{bf:On the Breusch-Godfrey test.} GVARX's own version passes only the short-run
block of regressors, omitting the {it:r_i} error-correction terms, which inflates
the statistic in proportion to {it:r_i / k_i}. Corrected here: empirical size of
the Edgerton-Shukur F moved from 0.108 to 0.066 on average, and from 0.248 to
0.116 for Australia, whose rank is 5 of 6. See
{helpb gvar_methods:gvar methods}.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Read the bootstrap p-values in preference to the asymptotic ones.} A Monte
Carlo at this model's own dimensions puts the adjusted portmanteau Qh* at
three to nine times its nominal size, rising with the block size, and the
Edgerton-Shukur F at about twice nominal for a unit whose rank is close to its
block size. Only Qh at {it:h} = 16 and the multivariate Jarque-Bera hold up
unaided. {cmd:reps()} removes the approximation entirely.

{pstd}
{bf:On the lag orders.} GVARX's default of 5 for the multivariate ARCH test is
meant for small VARs; a six-variable country model would need 106 auxiliary
regressors against about 110 usable quarters. The order is cut back until
there are at least three observations per regressor, and the orders actually
used are printed in the {cmd:h,h,q} column so a shortened lag is never passed
off as the one requested.

{pstd}
{bf:There are no dots in these tables.} Every equation has residuals, so every
cell is computable. If you see a missing value here, something failed.


{marker examples}{...}
{title:Examples}

        {cmd:. gvar diag}
        {cmd:. gvar diag, detail}
        {cmd:. gvar diag, multivariate}
        {cmd:. gvar diag, multivariate reps(200)}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gvar diag} stores the following in {cmd:r()}:

{synoptset 26 tabbed}{...}
{synopt:{cmd:r(diag)}}the per-equation matrix{p_end}
{synopt:{cmd:r(diagmv)}}the system-wide matrix{p_end}
{synopt:{cmd:r(diagboot)}}bootstrap p-values{p_end}
{synopt:{cmd:r(nequations)}}equations diagnosed{p_end}
{synopt:{cmd:r(nsc)}}serial-correlation rejections{p_end}
{synopt:{cmd:r(njb)}}non-normality rejections{p_end}
{synopt:{cmd:r(narch)}}ARCH rejections{p_end}
{synopt:{cmd:r(nwhite)}}heteroskedasticity rejections{p_end}
{synopt:{cmd:r(reps)}}bootstrap replications that converged{p_end}
{synoptline}


{marker source}{...}
{title:Source}

{pstd}
Toolbox {it:Ftest_rsc.m}, {it:jarquebera.m}, {it:dstats.m}; GVARX
{it:.jb.multi}, {it:.pt.multi}, {it:.bgserial}, {it:.arch.multi}.

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
