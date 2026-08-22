{smcl}
{* *! version 1.0.1  21aug2026}{...}
{vieweralsosee "gvar" "help gvar"}{...}
{vieweralsosee "gvar coint" "help gvar_coint"}{...}
{vieweralsosee "gvar estimate" "help gvar_estimate"}{...}
{vieweralsosee "gvar pp" "help gvar_pp"}{...}
{vieweralsosee "gvar bayes" "help gvar_bayes"}{...}
{viewerjumpto "Syntax" "gvar_overid##syntax"}{...}
{viewerjumpto "Description" "gvar_overid##description"}{...}
{viewerjumpto "Remarks" "gvar_overid##remarks"}{...}
{viewerjumpto "Examples" "gvar_overid##examples"}{...}
{viewerjumpto "Stored results" "gvar_overid##results"}{...}
{viewerjumpto "Options" "gvar_overid##options"}{...}
{title:Title}

{phang}
{bf:gvar overid} {hline 2} LR test of over-identifying restrictions on beta


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:gvar overid} [{cmd:using} {it:filename}] [{cmd:,} {it:options}]

{synoptset 32 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt list}}print each unit's beta layout and stop.{p_end}
{synopt:{opt free(spec)}}coefficients left freely estimated, as {cmd:free(usa 3 euro 2)}. Feeds {it:nunrestrpar}.{p_end}
{synopt:{opt replace}}install the restricted estimates in the model.{p_end}
{synopt:{opt nosum:mary}}suppress the table.{p_end}
{synopt:{opt saving(name)}}save the results matrix.{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:gvar overid} re-estimates chosen country models with the cointegrating
vectors held at values you supply, and reports the likelihood-ratio test
against the unrestricted fit:

        {it:LR = -2 (logL restricted - logL unrestricted)}
        {it:d.f. = rows(beta) x rank - rank^2 - free parameters}

{pstd}
The {it:rank^2} term removes the just-identifying normalisation, so only
genuinely over-identifying restrictions enter the degrees of freedom.


{marker options}{...}
{title:Options}

{phang}
{cmd:using} {it:filename} supplies the restrictions on {it:beta}, one row per
element of the layout. Every row of the layout must appear in the file --
{opt list} prints it, and starting there rather than guessing is the only
practical way to write the file.

{phang}
{opt list} prints the layout of {it:beta} for every unit and stops. Run it first.

{phang}
{opt free(spec)} names elements left unrestricted, when it is easier to say what
is free than what is fixed.

{phang}
{opt replace} allows an existing output file to be overwritten;
{opt saving(name)} writes the test results to a dataset;
{opt nosummary} suppresses the report.

{pmore}
{bf:This command needs the cointegrating vectors,} so it is defined only after
{helpb gvar_estimate:gvar estimate}. It refuses after
{helpb gvar_bayes:gvar bayes}, which fits a VARX in levels and imposes no rank --
there is no {it:beta} to test. The refusal is deliberate: {it:beta} would
otherwise still hold whatever an earlier ML fit left in memory, and the test would
run and report a plausible number about a model that no longer exists.

{pmore}
{bf:What the LR test conditions on.} The statistic tests the restrictions given
the rank. It says nothing about whether the rank itself is right, and an
over-identification test that comfortably accepts a theory at an overstated rank
is a common way to be misled. Settle the rank with {helpb gvar_coint:gvar coint}
first, and read {helpb gvar_solve:gvar solve}'s unit-root count as the
cross-check.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:The restriction file} has one row per restricted coefficient with
variables {cmd:unit}, {cmd:relation}, {cmd:term} and {cmd:value}. {cmd:term}
names a row of beta: a domestic variable, a foreign variable written
{it:name}{cmd:*}, or {cmd:_trend} (case 4) or {cmd:_cons} (case 2). Run
{cmd:gvar overid, list} first to see the layout.

{pstd}
{bf:Every row of a restricted unit's beta must be supplied.} The restricted
estimator takes beta as {bf:given} and estimates everything else conditional
on it, so a partially specified vector is not meaningful. Coefficients you
want estimated freely are declared through {cmd:free()}, which only adjusts
the degrees of freedom.

{pstd}
{bf:Read the chi-squared p-value with care.} The Toolbox does not use it: it
takes the critical values from the bootstrap, because the country models are
estimated conditional on weakly exogenous regressors whose own uncertainty the
asymptotic distribution ignores.

{pstd}
{bf:A useful check.} Imposing a unit's own fitted beta is a restriction that
binds at the unrestricted optimum, so it must give LR = 0. That is a quick way
to confirm your file is laid out correctly before imposing anything real.


{marker examples}{...}
{title:Examples}

        {cmd:. gvar overid, list}
        {cmd:. gvar overid using myrestrictions.dta}
        {cmd:. gvar overid using myrestrictions.dta, free(usa 3) replace}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gvar overid} stores the following in {cmd:r()}:

{synoptset 26 tabbed}{...}
{synopt:{cmd:r(overid)}}LR, d.f., p, and both log likelihoods per unit{p_end}
{synopt:{cmd:r(nunits)}}units restricted{p_end}
{synopt:{cmd:r(nrej)}}rejections at 5 per cent{p_end}
{synoptline}


{marker source}{...}
{title:Source}

{pstd}
Toolbox {it:overid_restr.m}, {it:mlcoint_r.m}; the test at {it:gvar.m:1479}.

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
