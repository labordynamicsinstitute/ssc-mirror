{smcl}
{* *! version 1.0.1  21aug2026}{...}
{vieweralsosee "gvar" "help gvar"}{...}
{vieweralsosee "gvar references" "help gvar_references"}{...}
{vieweralsosee "gvar coint" "help gvar_coint"}{...}
{vieweralsosee "gvar irf" "help gvar_irf"}{...}
{vieweralsosee "gvar overid" "help gvar_overid"}{...}
{vieweralsosee "gvar bayes" "help gvar_bayes"}{...}
{viewerjumpto "Syntax" "gvar_pp##syntax"}{...}
{viewerjumpto "Description" "gvar_pp##description"}{...}
{viewerjumpto "Remarks" "gvar_pp##remarks"}{...}
{viewerjumpto "Examples" "gvar_pp##examples"}{...}
{viewerjumpto "Stored results" "gvar_pp##results"}{...}
{viewerjumpto "Options" "gvar_pp##options"}{...}
{title:Title}

{phang}
{bf:gvar pp} {hline 2} persistence profiles of the cointegrating relations


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:gvar pp} [{cmd:,} {it:options}]

{synoptset 32 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt u:nits(list)}}which units. Default all.{p_end}
{synopt:{opt step(#)}}horizon. Default 24.{p_end}
{synopt:{opt hor:izons(numlist)}}which horizons to print.{p_end}
{synopt:{opt vcov(string)}}{cmd:sample} keeps the estimated covariance; {cmd:blockdiag} zeroes every cross-unit covariance; {cmd:blockdiag }{it:unit} does the same but leaves one unit's cross-covariances free.{p_end}
{synopt:{opt shrink}}shrink the correlation matrix towards the identity, intensity chosen internally.{p_end}
{synopt:{opt lam:bda(#)}}set the shrinkage intensity by hand, between 0 and 1.{p_end}
{synopt:{opt reps(#)}}bootstrap replications for the bands.{p_end}
{synopt:{opt lev:el(#)}}band level. Default 95.{p_end}
{synopt:{opt shuffle}}resample whole date columns.{p_end}
{synopt:{opt shrinkd:raw} {opt lamd:raw(#)}}shrink the draw covariance.{p_end}
{synopt:{opt gr:aph}}small-multiples plot.{p_end}
{synopt:{opt name(name)}}graph name.{p_end}
{synopt:{opt nosum:mary}}suppress the table.{p_end}
{synopt:{opt saving(name)}}save the profiles.{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:gvar pp} computes the effect of a system-wide shock on each estimated
long-run relation, scaled to one on impact. A well-behaved cointegrating
relation decays monotonically to zero; the speed of that decay is the
economically interesting quantity.


{marker options}{...}
{title:Options}

{phang}
{opt units(spec)} restricts which units' cointegrating relations are profiled.
Omitted, all of them are.

{phang}
{opt step(#)} the horizon. Default 24.

{phang}
{opt horizons(numlist)} which horizons appear in the printed table.

{phang}
{opt reps(#)} bootstrap replications for the bands and {opt level(#)} their
coverage. {cmd:reps(0)}, the default, gives point profiles only.

{phang}
{opt shuffle}, {opt shrinkdraw} and {opt lamdraw(#)} govern the bootstrap, as in
{helpb gvar_irf:gvar irf}.

{phang}
{opt vcov(spec)}, {opt shrink} and {opt lambda(#)} transform or regularise the
covariance.

{pmore}
{bf:A persistence profile starts at one for any covariance matrix}, because the
same {it:Sigma} sits in its numerator and denominator at {it:h} = 0. So the value
at zero cannot validate the covariance argument, and neither can the shape. If
you want to check that a covariance option is doing what you think, use an
orthogonalised FEVD, which sums to one only when it is right.

{phang}
{opt graph}, {opt name()}, {opt saving()} and {opt nosummary} as elsewhere.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:This is a specification test.} A profile that has not returned to near
zero by the end of the horizon says the relation is not settling back, and
the usual cause is an overstated cointegrating rank. The command counts those
and points at {helpb gvar_coint:gvar coint}. Dees, di Mauro, Pesaran and Smith
read overshooting and slow decay the same way.

{pstd}
{bf:Overshooting above one is common} and reflects short-run dynamics, not
misspecification. The half-life column - the first horizon at which the
profile falls to one half - is the summary worth quoting.

{pstd}
{bf:PP(0) = 1 is not a check.} The same covariance appears in the numerator
and denominator at horizon zero, so the profile starts at one whatever
covariance is supplied. It cannot detect a wrong covariance argument.

{pstd}
{bf:No ordering options.} The Toolbox computes persistence profiles on the
{bf:un}-reordered system, deliberately: a persistence profile is a property of
the cointegrating relations and carries no Cholesky ordering.


{marker examples}{...}
{title:Examples}

        {cmd:. gvar pp}
        {cmd:. gvar pp, units(usa euro china) step(24)}
        {cmd:. gvar pp, step(16) reps(200) shuffle graph}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gvar pp} stores the following in {cmd:r()}:

{synoptset 26 tabbed}{...}
{synopt:{cmd:r(pp)}}the profiles, with unit and relation identifiers{p_end}
{synopt:{cmd:r(ppband)}}the three bootstrap quantiles stacked{p_end}
{synopt:{cmd:r(nrelations)}}profiles reported{p_end}
{synopt:{cmd:r(nslow)}}profiles still above 0.10 at the final horizon{p_end}
{synopt:{cmd:r(step)}}the horizon{p_end}
{synopt:{cmd:r(reps)}}replications that converged{p_end}
{synoptline}


{marker source}{...}
{title:Source}

{pstd}
Toolbox {it:pprofile.m}; Pesaran and Shin (1996). Bands from
{it:bootstrap_GVAR.m}.

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
