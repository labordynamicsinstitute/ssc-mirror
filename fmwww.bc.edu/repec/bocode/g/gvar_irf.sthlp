{smcl}
{* *! version 1.0.1  21aug2026}{...}
{vieweralsosee "gvar" "help gvar"}{...}
{vieweralsosee "gvar references" "help gvar_references"}{...}
{vieweralsosee "gvar fevd" "help gvar_fevd"}{...}
{vieweralsosee "gvar pp" "help gvar_pp"}{...}
{vieweralsosee "gvar hd" "help gvar_hd"}{...}
{vieweralsosee "gvar describe" "help gvar_describe"}{...}
{vieweralsosee "gvar methods" "help gvar_methods"}{...}
{vieweralsosee "gvar bayes" "help gvar_bayes"}{...}
{viewerjumpto "Syntax" "gvar_irf##syntax"}{...}
{viewerjumpto "Description" "gvar_irf##description"}{...}
{viewerjumpto "Remarks" "gvar_irf##remarks"}{...}
{viewerjumpto "Examples" "gvar_irf##examples"}{...}
{viewerjumpto "Stored results" "gvar_irf##results"}{...}
{viewerjumpto "Options" "gvar_irf##options"}{...}
{title:Title}

{phang}
{bf:gvar irf} {hline 2} impulse responses of the solved GVAR


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:gvar irf} {cmd:,} {opt shock(unit:var)} [{it:options}]

{synoptset 32 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt shock(unit:var)}}the element of x(t) that is shocked. Required.{p_end}
{synopt:{opt resp:onse(spec)}}which responses to report. Accepts {cmd:unit:var}, {cmd:unit:*}, {cmd:*:var} or a bare variable name. Default is the shocked variable in every unit.{p_end}
{synopt:{opt step(#)}}horizon. Default 24.{p_end}
{synopt:{opt type(string)}}{cmd:girf}, {cmd:oirf} or {cmd:sgirf}. Default {cmd:girf}.{p_end}
{synopt:{opt cumul:ative}}accumulate the responses.{p_end}
{synopt:{opt neg:ative}}a minus one standard-error shock.{p_end}
{synopt:{opt first(units)}}which units lead the ordering. For {cmd:type(sgirf)} this {bf:is} the identifying assumption, and the block size is derived from it.{p_end}
{synopt:{opt vord:er(spec)}}the variable order inside each leading unit, one block per unit separated by {cmd:;}.{p_end}
{synopt:{opt vcov(string)}}{cmd:sample} keeps the estimated covariance; {cmd:blockdiag} zeroes every cross-unit covariance; {cmd:blockdiag }{it:unit} does the same but leaves one unit's cross-covariances free.{p_end}
{synopt:{opt shrink}}shrink the correlation matrix towards the identity, intensity chosen internally.{p_end}
{synopt:{opt lam:bda(#)}}set the shrinkage intensity by hand, between 0 and 1.{p_end}
{synopt:{opt reps(#)}}bootstrap replications for the bands.{p_end}
{synopt:{opt lev:el(#)}}band level. Default 95.{p_end}
{synopt:{opt shuffle}}resample whole date columns rather than orthogonalised scalars.{p_end}
{synopt:{opt shrinkd:raw}}shrink the covariance used to generate the draws.{p_end}
{synopt:{opt lamd:raw(#)}}set that intensity by hand.{p_end}
{synopt:{opt hor:izons(numlist)}}which horizons to print.{p_end}
{synopt:{opt gr:aph}}small-multiples plot.{p_end}
{synopt:{opt name(name)} {opt by(string)}}graph name and {cmd:by()} options.{p_end}
{synopt:{opt nosum:mary}}suppress the table.{p_end}
{synopt:{opt saving(name)}}save the responses.{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:gvar irf} computes generalized, orthogonalised or structural impulse
responses, optionally cumulated, optionally with bootstrap confidence bands.

{pstd}
The generalized responses of Pesaran and Shin (1998) are the default because
they need no ordering of the variables: with 136 variables no Cholesky
ordering is defensible. They are not responses to orthogonal shocks, so they
do not decompose into contributions that sum to one.


{marker options}{...}
{title:Options}

{phang}
{opt shock(unit:variable)} names the element of the global vector that is
shocked. Required. It must select exactly one element -- a shock to "all of the
United States" is not defined.

{phang}
{opt response(spec)} restricts which responses are reported, as
{it:unit:variable} with {cmd:*} wildcards. Omitted, every element responds, which
on the shipped demo is 136 series -- readable as a graph, not as a table.

{phang}
{opt step(#)} the horizon. Default 24.

{phang}
{opt type(girf|oirf|sgirf)} the identification.
{cmd:girf} is the generalized response of Pesaran and Shin, which needs no
ordering and is what Dees, di Mauro, Pesaran and Smith report;
{cmd:oirf} is orthogonalised and needs a full ordering of all {it:K} variables;
{cmd:sgirf} is structural-generalized -- orthogonalised within a leading block
and generalized across the rest, which is the usual compromise for a GVAR where
a full ordering of 136 variables is indefensible.

{pmore}
{cmd:girf} is the default and the only one that needs no ordering argument. The
other two need a Cholesky factor and so will refuse on a singular
{it:Sigma_zeta} -- see {opt shrink}.

{phang}
{opt first(units)} and {opt vorder(spec)} set the leading block for
{cmd:type(sgirf)}: which units come first, and optionally the variable order
within them. The block size {it:n0} is the total number of endogenous variables
in those units, exactly as {it:reorder_GVAR.m} defines it.

{phang}
{opt cumulative} reports cumulated responses, which is what you want when the
variable is a growth rate and the question is about the level.

{phang}
{opt vcov(spec)} transforms the covariance before it is used:
the sample matrix, block diagonal (every cross-unit covariance set to zero), or
block diagonal with one unit's cross-covariances left free. The middle option is
the assumption a good many GVAR papers make when they want the generalized
responses to be readable as country-specific.

{phang}
{opt shrink} and {opt lambda(#)} shrink the correlation matrix towards the
identity. On the shipped demo {it:Sigma_zeta} is 136 x 136 with rank 133 -- 134
quarters cannot support more -- so it has no Cholesky factor and anything
orthogonalised needs one of these. {opt shrink} picks the intensity internally;
{opt lambda()} sets it by hand.

{phang}
{opt reps(#)} bootstrap replications for the confidence bands, and
{opt level(#)} their coverage. With {cmd:reps(0)}, the default, no bands are
drawn: the responses are point estimates from the estimated system treated as
known.

{phang}
{opt shuffle}, {opt shrinkdraw} and {opt lamdraw(#)} govern how each bootstrap
replication handles the same singularity. {opt shuffle} resamples the residual
matrix by columns, which keeps the cross-section dependence intact;
{opt shrinkdraw} shrinks within each replication rather than once at the start,
which is the honest choice if the shrinkage intensity is itself uncertain.

{phang}
{opt negative} flips the sign of the shock, so a "one standard error decrease"
reads the natural way round.

{phang}
{opt restrictions(spec)}, {opt signs(spec)}, {opt draws(#)} and
{opt maxtries(#)} identify the shock by sign and zero restrictions instead of by
ordering. {opt draws()} is how many accepted rotations to keep and
{opt maxtries()} how many candidates to try per accepted draw; if the second is
reached the restriction set is probably infeasible rather than merely tight.

{phang}
{opt cfhold(spec)}, {opt cfvia(spec)} and {opt cfbase} produce a counterfactual
response: hold one set of variables fixed, transmit the shock only through
another, and optionally report the unrestricted baseline alongside for
comparison.

{phang}
{opt horizons(numlist)} selects which horizons appear in the printed table;
{opt table} forces the table when a graph was also asked for.
{opt graph}, {opt name()} and {opt by()} control the plot -- {opt by()} panels it
by unit or by variable.

{phang}
{opt saving(name)} writes the responses to a dataset, one row per (response,
horizon).

{phang}
{opt nosummary} suppresses the report.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Choosing a type.} {cmd:girf} is invariant to ordering and is what the GVAR
literature reports. {cmd:oirf} orthogonalises the whole system by Cholesky and
depends on the order of x(t); see {helpb gvar_describe:gvar describe, order}.
{cmd:sgirf} orthogonalises only a leading block, which is the case where you
have a defensible ordering for a few units and none for the rest.

{pstd}
{bf:The impact matrix is not triangular.} In a GVAR the reduced form carries
{it:G0^-1}, so the Cholesky impact matrix is {it:G0^-1 P}, not {it:P}. Testing
for triangularity will report a correct implementation as broken. The identity
that does hold is {it:B0 B0' = G0^-1 Sigma G0^-1'}.

{pstd}
{bf:Orthogonalised responses need a factorable covariance.} With more
variables than periods {it:Sigma_zeta} is singular and no Cholesky factor
exists. The command refuses rather than returning missing values, and names
the two remedies. See {helpb gvar_methods##singular:gvar methods}.

{pstd}
{bf:On the bands.} {cmd:reps()} runs the full model-level bootstrap: the
global vector is regenerated, every country model re-estimated and the GVAR
re-solved on each replication. The count discarded as unstable is reported and
matters. For a model with {it:K > T}, {cmd:shuffle} is the better scheme.


{marker examples}{...}
{title:Examples}

        {cmd:. gvar irf, shock(usa:r) response(y) step(24)}
        {cmd:. gvar irf, shock(usa:poil) response(usa:y euro:y) cumulative}
        {cmd:. gvar irf, shock(usa:r) response(y) reps(200) shuffle}
        {cmd:. gvar irf, shock(usa:r) type(sgirf) first(usa) ///}
                {cmd:vorder(poil pmat pmetal y Dp eq r lr)}
        {cmd:. gvar irf, shock(usa:r) type(oirf) shrink}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gvar irf} stores the following in {cmd:r()}:

{synoptset 26 tabbed}{...}
{synopt:{cmd:r(irf)}}the responses, horizons by responses{p_end}
{synopt:{cmd:r(lower)}}lower band{p_end}
{synopt:{cmd:r(upper)}}upper band{p_end}
{synopt:{cmd:r(band)}}all three quantiles stacked{p_end}
{synopt:{cmd:r(shock)}}the shock{p_end}
{synopt:{cmd:r(responses)}}the responses reported{p_end}
{synopt:{cmd:r(type)}}girf, oirf or sgirf{p_end}
{synopt:{cmd:r(step)}}the horizon{p_end}
{synopt:{cmd:r(reps)}}replications that converged{p_end}
{synopt:{cmd:r(discarded)}}draws discarded{p_end}
{synoptline}


{marker source}{...}
{title:Source}

{pstd}
Toolbox {it:irf.m}, {it:phi.m}; reordering from {it:reorder_GVAR.m}; bands
from {it:bootstrap_GVAR.m}.

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
