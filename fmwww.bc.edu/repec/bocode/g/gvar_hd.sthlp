{smcl}
{* *! version 1.0.1  21aug2026}{...}
{vieweralsosee "gvar" "help gvar"}{...}
{vieweralsosee "gvar irf" "help gvar_irf"}{...}
{vieweralsosee "gvar fevd" "help gvar_fevd"}{...}
{vieweralsosee "gvar methods" "help gvar_methods"}{...}
{vieweralsosee "gvar bayes" "help gvar_bayes"}{...}
{viewerjumpto "Syntax" "gvar_hd##syntax"}{...}
{viewerjumpto "Description" "gvar_hd##description"}{...}
{viewerjumpto "Remarks" "gvar_hd##remarks"}{...}
{viewerjumpto "Examples" "gvar_hd##examples"}{...}
{viewerjumpto "Stored results" "gvar_hd##results"}{...}
{viewerjumpto "Options" "gvar_hd##options"}{...}
{title:Title}

{phang}
{bf:gvar hd} {hline 2} historical decomposition


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:gvar hd} {cmd:,} {opt var:iables(unit:var)} [{it:options}]

{synoptset 32 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt var:iables(unit:var)}}the series decomposed. One at a time.{p_end}
{synopt:{opt shocks(spec)}}name the shocks to show instead of ranking them.{p_end}
{synopt:{opt top(#)}}how many leading contributors to show. Default 6.{p_end}
{synopt:{opt per:iods(numlist)}}print the contributions in these periods.{p_end}
{synopt:{opt first(units)}}which units lead the ordering. For {cmd:type(sgirf)} this {bf:is} the identifying assumption, and the block size is derived from it.{p_end}
{synopt:{opt vord:er(spec)}}the variable order inside each leading unit, one block per unit separated by {cmd:;}.{p_end}
{synopt:{opt vcov(string)}}{cmd:sample} keeps the estimated covariance; {cmd:blockdiag} zeroes every cross-unit covariance; {cmd:blockdiag }{it:unit} does the same but leaves one unit's cross-covariances free.{p_end}
{synopt:{opt shrink}}shrink the correlation matrix towards the identity, intensity chosen internally.{p_end}
{synopt:{opt lam:bda(#)}}set the shrinkage intensity by hand, between 0 and 1.{p_end}
{synopt:{opt bgv:ar}}reproduce BGVAR's {it:hd.R} exactly, including its unscaled trend.{p_end}
{synopt:{opt gr:aph}}plot the contributions.{p_end}
{synopt:{opt name(name)}}graph name.{p_end}
{synopt:{opt nosum:mary}}suppress the tables.{p_end}
{synopt:{opt saving(name)}}save the decomposition.{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:gvar hd} splits one observed series into the cumulated contribution of
every structural shock, plus the constant, the trend, the initial condition
and a leftover slice.

{pstd}
A historical decomposition attributes each movement in the data to one shock,
so it requires orthogonal shocks. The source refuses to do this under
generalized identification and so does this command.


{marker options}{...}
{title:Options}

{phang}
{opt variables(unit:variable)} the series to decompose. It must select exactly
one element -- a historical decomposition is read one series at a time.

{phang}
{opt shocks(spec)} restricts which shocks are shown, and {opt top(#)} keeps only
the largest contributors. Default 6, which is what fits legibly in a stacked bar
chart.

{phang}
{opt periods(spec)} restricts the sample window shown, for zooming on an episode.

{phang}
{opt full} shows the deterministic and initial-condition blocks as well as the
shock contributions. By default they are netted out.

{pmore}
That default is deliberate. On data in levels the deterministic and initial-value
terms account for the overwhelming majority of the height of every bar -- around
85% on the shipped demo -- so a chart including them is technically complete and
tells you nothing about the shocks. {opt full} is there when you want to verify
that the pieces add back to the data.

{phang}
{opt lines} draws lines instead of stacked bars, which is easier to read when
you care about one contributor's path rather than the composition.

{phang}
{opt vcov(spec)}, {opt shrink} and {opt lambda(#)} as in
{helpb gvar_irf:gvar irf}. A historical decomposition is orthogonalised, so it
needs a Cholesky factor and {bf:will refuse} on the shipped demo without
{opt shrink} -- under either estimator, since {it:Sigma_zeta} is 136 x 136 from
134 quarters.

{phang}
{opt bgvar} reproduces {it:hd.R}'s own arithmetic, which feeds the trend
coefficient in unscaled and starts the initial-condition block one application of
the companion matrix short. Both are hidden by its trailing residual slice, which
is defined as data minus everything else. Corrected, the leftover falls from 48.7
to 9.4e-13 on a series whose level is 4.8. See {helpb gvar_methods:gvar methods}.

{phang}
{opt graph}, {opt name()}, {opt saving()} and {opt nosummary} as elsewhere.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Why it needs an orthogonal scheme.} Generalized shocks are correlated by
construction, so the attributions would double count and the pieces would not
add back to the data. Use {cmd:first()} and {cmd:vorder()} to set a Cholesky
ordering, and {cmd:shrink} if the covariance is singular.

{pstd}
{bf:Do not validate this by checking that the pieces sum to the data.} The
leftover slice is {bf:defined} as the data minus everything else, so that
identity holds however wrong the other blocks are. The quantity to read is the
size of the leftover itself, reported in the header. Correctly computed it is
at machine zero; the demo gives 9e-13 against a series whose level is 4.8.

{pstd}
{bf:On bgvar.} The reference implementation feeds the trend coefficient into
the companion recursion unscaled and starts its initial-condition block one
step short. Both defects are hidden by its residual slice. {cmd:bgvar}
reproduces that behaviour for replication; the default corrects it, and the
correction changes which shock is the largest contributor.


{marker examples}{...}
{title:Examples}

        {cmd:. gvar hd, variables(usa:y) shrink}
        {cmd:. gvar hd, variables(usa:y) shrink first(usa) ///}
                {cmd:vorder(poil pmat pmetal y Dp eq r lr) periods(40 80 120)}
        {cmd:. gvar hd, variables(euro:y) shrink graph}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gvar hd} stores the following in {cmd:r()}:

{synoptset 26 tabbed}{...}
{synopt:{cmd:r(hd)}}the decomposition, stacked blocks by period{p_end}
{synopt:{cmd:r(strshock)}}the recovered structural shocks{p_end}
{synopt:{cmd:r(contrib)}}mean absolute contribution of each shock{p_end}
{synopt:{cmd:r(leftover)}}the largest leftover, which should be at machine zero{p_end}
{synopt:{cmd:r(nblocks)}}number of blocks returned{p_end}
{synoptline}


{marker source}{...}
{title:Source}

{pstd}
BGVAR {it:hd.R}.

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
