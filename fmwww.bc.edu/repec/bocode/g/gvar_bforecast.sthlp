{smcl}
{* *! version 1.0.1  21aug2026}{...}
{vieweralsosee "gvar" "help gvar"}{...}
{vieweralsosee "gvar bayes" "help gvar_bayes"}{...}
{vieweralsosee "gvar forecast" "help gvar_forecast"}{...}
{vieweralsosee "gvar bconv" "help gvar_bconv"}{...}
{vieweralsosee "gvar bdic" "help gvar_bdic"}{...}
{viewerjumpto "Syntax" "gvar_bforecast##syntax"}{...}
{viewerjumpto "Description" "gvar_bforecast##description"}{...}
{viewerjumpto "Options" "gvar_bforecast##options"}{...}
{viewerjumpto "Remarks" "gvar_bforecast##remarks"}{...}
{viewerjumpto "Examples" "gvar_bforecast##examples"}{...}
{viewerjumpto "Stored results" "gvar_bforecast##results"}{...}
{title:Title}

{phang}
{bf:gvar bforecast} {hline 2} predictive density over the retained draws


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:gvar bforecast} {cmd:,} {opt var:iables(spec)} [{it:options}]

{synoptset 32 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt var:iables(spec)}}the elements to forecast, as {it:unit:variable}. Required.{p_end}
{synopt:{opt step(#)}}horizons. Default 8.{p_end}
{synopt:{opt bands(numlist)}}coverage percentages. Default {cmd:68 90}.{p_end}
{synopt:{opt gr:aph}}fan chart, one panel per variable.{p_end}
{synopt:{opt fan}}shade every band rather than the outermost only.{p_end}
{synopt:{opt name(name)}}graph name.{p_end}
{synopt:{opt sav:ing(name)}}save the table as a dataset.{p_end}
{synopt:{opt nosum:mary}}suppress the report.{p_end}
{synoptline}

{pstd}
{helpb gvar_bayes:gvar bayes} and {helpb gvar_solve:gvar solve} must have run
first.


{marker description}{...}
{title:Description}

{pstd}
{cmd:gvar bforecast} forecasts by stacking and solving {bf:every retained draw
separately}, so the resulting interval carries parameter uncertainty as well as
shock uncertainty.

{pstd}
That is the whole reason it exists. {helpb gvar_forecast:gvar forecast}'s bands
come from

{p 8 8 2}{it:Omega(h) = sum_{j<h} Phi_j Sigma_eta Phi_j'}{p_end}

{pstd}
with the estimated system treated as {bf:known}, so they contain no parameter
uncertainty at all. Integrating over the draws adds it, and on the shipped
26-unit demo that {bf:roughly doubles} the interval:

{p 8 8 2}{it:h}{space 4}{it:gvar forecast}{space 4}{it:gvar bforecast}{space 4}{it:ratio}{p_end}
{p 8 8 2}{space 1}1{space 9}0.012061{space 10}0.026890{space 6}2.229{p_end}
{p 8 8 2}{space 1}4{space 9}0.021225{space 10}0.040762{space 6}1.920{p_end}
{p 8 8 2}{space 1}8{space 9}0.030911{space 10}0.057073{space 6}1.846{p_end}

{pstd}
90% half-widths for {cmd:usa:y}. Reproduce them with

        {cmd:. gvar bayes, prior(mn) prmean(0) noeigentrim draws(200) burnin(200) seed(20260811)}
        {cmd:. gvar solve}
        {cmd:. gvar forecast, step(8) variables(usa:y)}
        {cmd:. gvar bforecast, variables(usa:y) step(8) bands(90)}

{pstd}
The settings are given because the figures are quoted to six places and an MCMC
number without its seed and chain length is not reproducible. Reading
{cmd:gvar forecast}'s bands as predictive intervals on this model understates
uncertainty by about half.

{pstd}
{bf:The ratio cannot fall below one.} The predictive variance decomposes as
{it:E_theta[Omega(h)] + Var_theta(mu_h)}: {cmd:gvar forecast} supplies the first
term at {it:theta-hat} and {cmd:gvar bforecast} carries both. The second cannot
be negative, so a predictive interval narrower than the analytic one means shock
or parameter uncertainty is being dropped somewhere -- it is a bug, never a
finding about the data. {cmd:_test54.do} asserts it at every horizon.


{marker options}{...}
{title:Options}

{phang}
{opt variables(spec)} names what to forecast, as {it:unit:variable} with
{cmd:*} wildcards, exactly as in {helpb gvar_hd:gvar hd} and
{helpb gvar_fevd:gvar fevd}. It is required: the system is solved jointly either
way, but a predictive density over all the endogenous variables is a table
nobody reads.

{phang}
{opt bands(numlist)} sets the coverage percentages. The widest band supplies the
{it:lower} and {it:upper} columns of the printed table; every band is in
{cmd:r(table)} and in the fan chart.

{phang}
{opt graph} draws one panel per variable, palest shade outermost.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:These are not sample paths.} Each horizon is drawn from its own {it:marginal}
predictive, using the cumulative forecast-error covariance at that horizon. So a
row of the output is exactly right for the interval at its own horizon, and
{bf:must not} be read as a trajectory: within one draw the horizons do not share
shock realisations. BGVAR does the same, and the distinction matters if you
intend to compute anything from the joint behaviour of a path.

{pstd}
{bf:Cross-country shock correlation is zero.} The per-draw {it:Sigma_zeta} is
block diagonal in the country covariances, because the sampler in
{helpb gvar_bayes:gvar bayes} treats the units independently and never estimates
a cross-unit covariance. BGVAR's predictive does the same -- its {it:Sig_t} is
{it:Ginv S_large Ginv'} with {it:S_large} the stacked per-country matrix. The
consequence is that joint uncertainty across countries is understated, and it is
inherited from the sampler rather than chosen here. {helpb gvar_irf:gvar irf}
still reads {it:Sigma_zeta} from the residuals, which does carry the
cross-country correlation.

{pstd}
{bf:Two defects in BGVAR's predictive are corrected, not reproduced.} Both were
settled by reading {it:predict.R} and {it:utils.R}:

{p 8 12 2}
{bf:the trend freezes.} {cmd:.get_companion} carries the deterministic block
forward with {cmd:diag(nd)}, so a trend stays at its last in-sample value and the
drift contribution is {it:a1*T} at every horizon instead of {it:a1*(T+h)}. A
trended forecast is flat in its trend component.{p_end}

{p 8 12 2}
{bf:the state starts a period early.} It is initialised at {cmd:Xn[bigT,]},
which {cmd:.mlag} fills with {it:y_{T-1}...y_{T-p}}, so the first companion
multiply returns the {it:fitted} value at {it:T} and horizon {it:h} is really
{it:T+h-1}.{p_end}

{pstd}
This command reuses the same routine {helpb gvar_forecast:gvar forecast} uses,
which starts from the observed terminal values and advances the trend. So both
are fixed by construction and the two commands cannot drift apart.

{pstd}
Neither is offered as a reproduction option. {opt bgvarsv} and {opt bgvarhs} in
{helpb gvar_bayes:gvar bayes} exist because reproducing those defects lets you
match published BGVAR output on quantities that are otherwise defensible. A
forecast whose first horizon is an in-sample fit is not defensible, and nobody
wants to match it.

{pstd}
{bf:Check the chains first.} The interval is only as good as the draws behind
it; run {helpb gvar_bconv:gvar bconv} before reading anything from this.

{pstd}
{bf:Cost.} Every draw is stacked and solved, so the work is roughly
{it:draws} times one {cmd:gvar solve}. A few hundred draws is quick; several
thousand is not.


{marker examples}{...}
{title:Examples}

{pstd}
Sample, check, solve, forecast. Note {opt prmean(0)}: the default random-walk
prior mean gives an unstable GVAR on this data, and a forecast from an explosive
system diverges rather than being merely wide -- see
{helpb gvar_bayes:gvar bayes}.{p_end}
{phang2}{cmd:. gvar bayes, prior(mn) prmean(0) noeigentrim draws(2000) burnin(2000) seed(20260811)}{p_end}
{phang2}{cmd:. gvar bconv}{p_end}
{phang2}{cmd:. gvar solve}{p_end}
{phang2}{cmd:. gvar bforecast, variables(usa:y) step(8)}{p_end}

{pstd}
A fan chart for three series, with a third band:{p_end}
{phang2}{cmd:. gvar bforecast, variables(usa:y uk:y euro:y) step(12) bands(50 68 90) graph}{p_end}

{pstd}
Every output gap in the model, saved rather than printed:{p_end}
{phang2}{cmd:. gvar bforecast, variables(*:y) step(8) saving(bfc) nosummary}{p_end}

{pstd}
Side by side with the interval that ignores parameter uncertainty:{p_end}
{phang2}{cmd:. gvar forecast, step(8) variables(usa:y) bands(90)}{p_end}
{phang2}{cmd:. gvar bforecast, variables(usa:y) step(8) bands(90)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gvar bforecast} stores the following in {cmd:r()}:

{synoptset 26 tabbed}{...}
{synopt:{cmd:r(table)}}one row per (variable, horizon): horizon, variable index, predictive mean, then one column per quantile in ascending order{p_end}
{synopt:{cmd:r(draws)}}draws integrated over{p_end}
{synopt:{cmd:r(step)}}horizons{p_end}
{synopt:{cmd:r(bands)}}the coverage percentages{p_end}
{synopt:{cmd:r(quantiles)}}the quantiles, matching the table columns{p_end}
{synopt:{cmd:r(varlist)}}{opt variables()} as typed{p_end}
{synoptline}


{marker source}{...}
{title:Source}

{pstd}
BGVAR {it:R/predict.R}; {it:R/utils.R} {cmd:.get_companion} and {cmd:.mlag}.
The mean path is the Toolbox's {it:forecast_GVAR.m}, shared with
{helpb gvar_forecast:gvar forecast}.

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
