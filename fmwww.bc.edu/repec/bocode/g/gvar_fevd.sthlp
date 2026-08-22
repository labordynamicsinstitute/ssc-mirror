{smcl}
{* *! version 1.0.1  21aug2026}{...}
{vieweralsosee "gvar" "help gvar"}{...}
{vieweralsosee "gvar irf" "help gvar_irf"}{...}
{vieweralsosee "gvar spillover" "help gvar_spillover"}{...}
{vieweralsosee "gvar methods" "help gvar_methods"}{...}
{vieweralsosee "gvar bayes" "help gvar_bayes"}{...}
{viewerjumpto "Syntax" "gvar_fevd##syntax"}{...}
{viewerjumpto "Description" "gvar_fevd##description"}{...}
{viewerjumpto "Remarks" "gvar_fevd##remarks"}{...}
{viewerjumpto "Examples" "gvar_fevd##examples"}{...}
{viewerjumpto "Stored results" "gvar_fevd##results"}{...}
{viewerjumpto "Options" "gvar_fevd##options"}{...}
{title:Title}

{phang}
{bf:gvar fevd} {hline 2} forecast error variance decomposition


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:gvar fevd} {cmd:,} {opt var:iable(unit:var)} [{it:options}]

{synoptset 32 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt var:iable(unit:var)}}the variable decomposed. Required.{p_end}
{synopt:{opt step(#)}}horizon. Default 24.{p_end}
{synopt:{opt type(string)}}{cmd:girf}, {cmd:oirf} or {cmd:sgirf}.{p_end}
{synopt:{opt top(#)}}how many leading contributors to show. Default 10.{p_end}
{synopt:{opt shocks(spec)}}name the shocks to show instead of ranking them.{p_end}
{synopt:{opt hor:izons(numlist)}}which horizons to print.{p_end}
{synopt:{opt first(units)}}which units lead the ordering. For {cmd:type(sgirf)} this {bf:is} the identifying assumption, and the block size is derived from it.{p_end}
{synopt:{opt vord:er(spec)}}the variable order inside each leading unit, one block per unit separated by {cmd:;}.{p_end}
{synopt:{opt vcov(string)}}{cmd:sample} keeps the estimated covariance; {cmd:blockdiag} zeroes every cross-unit covariance; {cmd:blockdiag }{it:unit} does the same but leaves one unit's cross-covariances free.{p_end}
{synopt:{opt shrink}}shrink the correlation matrix towards the identity, intensity chosen internally.{p_end}
{synopt:{opt lam:bda(#)}}set the shrinkage intensity by hand, between 0 and 1.{p_end}
{synopt:{opt gr:aph}}plot the contributions.{p_end}
{synopt:{opt name(name)}}graph name.{p_end}
{synopt:{opt nosum:mary}}suppress the table.{p_end}
{synopt:{opt saving(name)}}save the decomposition.{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:gvar fevd} decomposes the forecast error variance of one variable across
all the shocks in the system, generalized or orthogonalised.


{marker options}{...}
{title:Options}

{phang}
{opt variable(unit:variable)} names the variable whose forecast error variance
is decomposed. Required, and it must select exactly one element: a decomposition
is read one series at a time.

{pmore}
Note this is the {bf:responding} variable, not the shock -- the opposite of
{helpb gvar_irf:gvar irf}'s {opt shock()}. The table answers "where does the
uncertainty in this series come from", so the rows are the shocks.

{phang}
{opt shocks(spec)} restricts which shocks are listed, if you already know which
few matter.

{phang}
{opt step(#)} the horizon, default 24, and {opt horizons(numlist)} which
horizons appear in the table.

{phang}
{opt type(girf|oirf|sgirf)} the identification, as in
{helpb gvar_irf:gvar irf}. The distinction matters more here: only the
{bf:orthogonalised} decomposition sums to one across shocks. The generalized one
does not, because the shocks are not orthogonal, and a generalized FEVD whose
column sums to 1.3 is not a bug.

{phang}
{opt first(units)} and {opt vorder(spec)} set the leading block for
{cmd:type(sgirf)}.

{phang}
{opt top(#)} lists only the largest contributors. Default 10. With 136 shocks
the full column is unreadable and mostly zeros.

{phang}
{opt vcov(spec)}, {opt shrink} and {opt lambda(#)} as in
{helpb gvar_irf:gvar irf}. An orthogonalised FEVD needs a Cholesky factor, so on
the shipped demo it needs one of the last two.

{phang}
{opt graph}, {opt name()}, {opt saving()} and {opt nosummary} as elsewhere.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:The generalized decomposition does not sum to one.} The shocks are
correlated by construction, so the shares overlap. That is a property of the
Pesaran-Shin estimator, which defines each share against its own shock
variance, not a defect. The reported TOTAL column is the sum over all shocks
and shows how far from one it falls; a value well above one signals strong
contemporaneous correlation. Use {cmd:type(oirf)} for shares that do sum to
one.

{pstd}
{bf:The own share at horizon zero is not one either,} unlike in a standard
VAR, because the reduced form carries {it:G0^-1}.


{marker examples}{...}
{title:Examples}

        {cmd:. gvar fevd, variable(euro:y) step(24) top(8)}
        {cmd:. gvar fevd, variable(usa:y) type(oirf) shrink}
        {cmd:. gvar fevd, variable(usa:y) shocks(usa:r usa:eq) graph}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gvar fevd} stores the following in {cmd:r()}:

{synoptset 26 tabbed}{...}
{synopt:{cmd:r(fevd)}}the reported shares plus the TOTAL column{p_end}
{synopt:{cmd:r(fevdfull)}}shares against every shock{p_end}
{synopt:{cmd:r(variable)}}the variable decomposed{p_end}
{synopt:{cmd:r(shocks)}}the shocks reported{p_end}
{synopt:{cmd:r(type)}}girf, oirf or sgirf{p_end}
{synopt:{cmd:r(step)}}the horizon{p_end}
{synoptline}


{marker source}{...}
{title:Source}

{pstd}
Toolbox {it:fevd.m}.

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
