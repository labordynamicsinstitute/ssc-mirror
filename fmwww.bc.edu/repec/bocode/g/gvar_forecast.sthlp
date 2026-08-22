{smcl}
{* *! version 1.0.1  21aug2026}{...}
{vieweralsosee "gvar" "help gvar"}{...}
{vieweralsosee "gvar solve" "help gvar_solve"}{...}
{vieweralsosee "gvar irf" "help gvar_irf"}{...}
{vieweralsosee "gvar methods" "help gvar_methods"}{...}
{vieweralsosee "gvar bforecast" "help gvar_bforecast"}{...}
{vieweralsosee "gvar bayes" "help gvar_bayes"}{...}
{viewerjumpto "Syntax" "gvar_forecast##syntax"}{...}
{viewerjumpto "Description" "gvar_forecast##description"}{...}
{viewerjumpto "Remarks" "gvar_forecast##remarks"}{...}
{viewerjumpto "Examples" "gvar_forecast##examples"}{...}
{viewerjumpto "Stored results" "gvar_forecast##results"}{...}
{viewerjumpto "Options" "gvar_forecast##options"}{...}
{title:Title}

{phang}
{bf:gvar forecast} {hline 2} point and conditional forecasts


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:gvar forecast} [{cmd:,} {it:options}]

{synoptset 32 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt step(#)}}horizon. Default 8.{p_end}
{synopt:{opt var:iables(spec)}}which series to report. Default {cmd:*:y}.{p_end}
{synopt:{opt bound(varlist)}}which variables get the lower bound. Default {cmd:r lr}.{p_end}
{synopt:{opt rmin(#)}}the bound, in {bf:per-annum percent}. Default 0.25.{p_end}
{synopt:{opt nob:ound}}apply no bound.{p_end}
{synopt:{opt cond:ition(spec)}}conditioning paths, as {cmd:condition(usa:r = .001 .001 ; euro:y = 4.7)}.{p_end}
{synopt:{opt gr:aph}}plot the forecasts.{p_end}
{synopt:{opt name(name)}}graph name.{p_end}
{synopt:{opt nosum:mary}}suppress the table.{p_end}
{synopt:{opt saving(name)}}save the forecasts.{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:gvar forecast} produces ex-ante forecasts from the solved GVAR, with an
optional lower bound on the interest rates and optional conditioning paths for
chosen variables.


{marker options}{...}
{title:Options}

{phang}
{opt step(#)} the forecast horizon. Default 8.

{phang}
{opt variables(spec)} restricts which series are reported.

{phang}
{opt bands(numlist)} the coverage percentages for the interval. Default
{cmd:68 90}.

{pmore}
{bf:These bands carry no parameter uncertainty.} They come from
{it:Omega(h) = sum Phi_j Sigma_eta Phi_j'} with the estimated system treated as
{bf:known}. Integrating over a posterior instead roughly doubles them on the
shipped demo -- see {helpb gvar_bforecast:gvar bforecast}.

{phang}
{opt bound(spec)}, {opt rmin(#)} and {opt nobound} impose element-wise lower
bounds, which is how a nominal interest rate is kept from being forecast below
its floor. {opt rmin()} is the default floor applied to rate variables;
{opt nobound} switches the mechanism off entirely.

{phang}
{opt condition(spec)} produces a conditional forecast: fix the path of some
variables and let the rest follow. The conditioning moves later horizons too,
through the cross-horizon covariance block, which is why the covariance is built
to {it:max(H, H_bar)} here rather than truncated -- see
{helpb gvar_methods:gvar methods}.

{phang}
{opt evaluate} and {opt holdout(#)} score the forecast rather than reporting it:
hold back the last {it:#} observations, forecast them, and report the errors.

{phang}
{opt bgvar} labels the error column as BGVAR's {cmd:rmse()} does. Despite the
name that function returns a per-cell absolute error, not a root mean square, so
the label follows the arithmetic rather than the function name.

{phang}
{opt vcov(spec)}, {opt shrink} and {opt lambda(#)} as in
{helpb gvar_irf:gvar irf}.

{phang}
{opt graph}, {opt fan}, {opt name()}, {opt saving()} and {opt nosummary}.
{opt fan} shades every band rather than the outermost only.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:The bound is per-annum percent and is transformed.} The Toolbox builds
rates as {it:(1/freq) log(1 + R/100)}, so the floor is converted the same way:
for quarterly data and the default 0.25, it is 0.000624, not 0.25. Passing the
raw number would bind four hundred times too tightly. The bound is applied
before the forecast enters the lag stack, so it propagates.

{pstd}
{bf:Conditional forecasts carry no bound.} The source computes the conditional
baseline with the bound switched off, and so does this. A conditioned path can
therefore go below the floor, and in the demo it does.

{pstd}
{bf:Conditioning beyond the restriction horizon.} The information still moves
the forecast after the last restricted period, through the cross-horizon
covariance. The source's own indexing cannot handle a forecast horizon longer
than the restriction horizon; here the covariance is built out far enough that
it can.


{marker examples}{...}
{title:Examples}

        {cmd:. gvar forecast, step(8) variables(usa:y euro:y)}
        {cmd:. gvar forecast, step(8) variables(*:r) rmin(0.25)}
        {cmd:. gvar forecast, step(8) nobound}
        {cmd:. gvar forecast, step(8) variables(usa:y) ///}
                {cmd:condition(usa:r = 0.0002 0.0002 0.0002 0.0002)}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gvar forecast} stores the following in {cmd:r()}:

{synoptset 26 tabbed}{...}
{synopt:{cmd:r(forecast)}}the reported series{p_end}
{synopt:{cmd:r(full)}}forecasts for every variable{p_end}
{synopt:{cmd:r(step)}}the horizon{p_end}
{synopt:{cmd:r(nbound)}}series bounded{p_end}
{synopt:{cmd:r(bound)}}the bound in model units{p_end}
{synopt:{cmd:r(variables)}}the series reported{p_end}
{synoptline}


{marker source}{...}
{title:Source}

{pstd}
Toolbox {it:forecast_GVAR.m}, {it:con_forecast_GVAR.m}.

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
