{smcl}
{* *! version 1.0.1  21aug2026}{...}
{vieweralsosee "gvar" "help gvar"}{...}
{vieweralsosee "gvar references" "help gvar_references"}{...}
{vieweralsosee "gvar estimate" "help gvar_estimate"}{...}
{vieweralsosee "gvar coint" "help gvar_coint"}{...}
{vieweralsosee "gvar diag" "help gvar_diag"}{...}
{vieweralsosee "gvar contemp" "help gvar_contemp"}{...}
{viewerjumpto "Syntax" "gvar_wetest##syntax"}{...}
{viewerjumpto "Description" "gvar_wetest##description"}{...}
{viewerjumpto "Remarks" "gvar_wetest##remarks"}{...}
{viewerjumpto "Examples" "gvar_wetest##examples"}{...}
{viewerjumpto "Stored results" "gvar_wetest##results"}{...}
{viewerjumpto "Options" "gvar_wetest##options"}{...}
{title:Title}

{phang}
{bf:gvar wetest} {hline 2} test the weak exogeneity of the foreign variables


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:gvar wetest} [{cmd:,} {opt ls(#)} {opt ln(#)} {opt lev:el(#)} {opt nosum:mary} {opt saving(name)}]

{synoptset 32 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt ls(#)}}lagged differences of the domestic variables in the marginal model. Default 1.{p_end}
{synopt:{opt ln(#)}}lagged differences of the foreign variables. Default 1.{p_end}
{synopt:{opt sel:ect(aic|sbc)}}choose {opt ls()} and {opt ln()} per unit by that criterion instead.{p_end}
{synopt:{opt maxls(#)}}maximum domestic order searched by {opt select()}. Default 2.{p_end}
{synopt:{opt maxln(#)}}maximum foreign order searched by {opt select()}. Default 2.{p_end}
{synopt:{opt wef:oreign(varlist)}}add these variables' foreign counterparts to the marginal model. Default none.{p_end}
{synopt:{opt lev:el(#)}}level for the critical value. Default 95.{p_end}
{synopt:{opt nosum:mary}}suppress the table.{p_end}
{synopt:{opt saving(name)}}save the results matrix.{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:gvar wetest} runs the F test of Dees, di Mauro, Pesaran and Smith (2007)
for each unit and each of its weakly exogenous variables. A marginal model is
fitted for the first difference of the foreign variable on a constant, the
error-correction terms of that unit's own model, and lagged differences of
its domestic and foreign variables. The null is that the error-correction
terms do not enter.

{pstd}
This is the assumption the whole country-by-country estimation rests on. If
the foreign variables are not weakly exogenous, the VECMX* estimates are not
consistent for the long-run parameters.


{marker options}{...}
{title:Options}

{phang}
{opt ls(#)} and {opt ln(#)} the lag orders in the auxiliary regression: the lags
of the foreign variables and of the error-correction terms. Both default to 1.

{phang}
{opt weforeign(varlist)} adds the foreign counterparts of these {it:domestic}
variables to the marginal model's regressor block, where the unit does not
already carry them. A global variable name adds the series itself, and is
ignored for any unit holding it endogenous. The left-hand side is untouched, so
the shape of the table does not change.

{pmore}
The Toolbox specifies this block separately from the country model's weakly
exogenous block ({it:fvflag_we} / {it:gvflag_we}, {it:gvar.m}:1680-1714) and
pauses to let you edit it; the default there, and here, is to leave it equal to
the estimation block. Its note at that pause offers {cmd:weforeign(ep)} for
DdPS(2007), but that is {bf:not} what the shipped demo's published
{it:exogeneity_test} sheet was run with -- it changes the degrees of freedom
away from the published ones. See
{help gvar_methods##wedev:gvar methods, "Weak exogeneity: a known deviation"}.

{phang}
{opt level(#)} the significance level for the reported critical value. Default
95.

{phang}
{opt graph}, {opt name()}, {opt saving()} and {opt nosummary} as elsewhere.

{pmore}
{bf:How to read the result.} Weak exogeneity is the assumption the whole
country-by-country estimation rests on: it is what allows each VECMX* to be
fitted conditional on {it:x*} without modelling the rest of the world. A rejection
for a few (unit, variable) pairs out of many is expected at any level -- roughly
5 to 10% of tests on a correctly specified GVAR. A rejection concentrated in one
unit, or in one variable across many units, is the one worth investigating.

{pmore}
A test that could not be computed is reported as such rather than dropped. That is
a failure of the auxiliary regression, not a specification fact, and the two
should not look alike in a table.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Against the Toolbox demo.} This command reproduces
{it:test_weakexogeneity.m}'s formula, restriction count and degrees of freedom
(24 of 26 units, and the same 24 critical values exactly), and 96.1% of the 5%
verdicts on the shipped demo -- but not the {it:F} levels on its published
{it:exogeneity_test} sheet, none of which agree to 1e-6. Read the rejection
pattern rather than individual {it:F} values, and do not quote them against the
Toolbox's. The full account, including what has been ruled out, is in
{help gvar_methods##wedev:gvar methods, "Weak exogeneity: a known deviation"}.

{pstd}
{bf:What a normal result looks like.} Dees, di Mauro, Pesaran and Smith
report rejection rates of roughly 5 to 10 per cent for a correctly specified
GVAR. The shipped demo rejects 18 of 203, or 8.9 per cent, which is in that
range. A much higher rate is evidence against the specification, not a
curiosity.

{pstd}
{bf:A dash is not a failure; a dot is.} The table carries one column per weakly
exogenous variable across the whole model, and most units do not have all of
them, so the grid is necessarily sparse.

{p 8 8 2}{bf:-}{space 4}the variable is not in that unit's block -- a fact about
the specification{p_end}
{p 8 8 2}{bf:.}{space 4}the variable IS in the block but no F could be
computed -- a failure{p_end}

{pstd}
The two used to print as the same dot, which made a 25-row column of structural
blanks under {bf:ep*} look identical to 25 broken tests. They are now distinct
and the footer counts the second kind; on the shipped demo that count is zero.

{pstd}
Why {bf:ep*} is a dash for 25 of 26 units: only the USA has a foreign exchange
rate, every other country holding its own {it:ep} as a domestic variable. And
the USA's own row is dashes except under {it:y*}, {it:Dp*} and {it:ep*}, because
its foreign block is deliberately just those three. Both patterns are the
Dees-di Mauro-Pesaran-Smith convention and both match the Toolbox's own
{it:exogeneity_test} sheet cell for cell.

{pstd}
{bf:The critical value varies by unit,} because it depends on the
cointegrating rank. It is reported in the last column rather than assumed.


{marker examples}{...}
{title:Examples}

        {cmd:. gvar wetest}
        {cmd:. gvar wetest, ls(1) ln(1)}
        {cmd:. gvar wetest, saving(WE)}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gvar wetest} stores the following in {cmd:r()}:

{synoptset 26 tabbed}{...}
{synopt:{cmd:r(wetest)}}the F statistics and critical values{p_end}
{synopt:{cmd:r(nrej)}}rejections at the chosen level{p_end}
{synopt:{cmd:r(ntot)}}tests computed{p_end}
{synopt:{cmd:r(nmiss)}}tests that should have been computable but were not{p_end}
{synoptline}


{marker source}{...}
{title:Source}

{pstd}
Toolbox {it:test_weakexogeneity.m}, {it:select_lags_we.m}.

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
