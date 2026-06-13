{smcl}
{* *! version 1.0.0 12jun2026}{...}
{vieweralsosee "mmqrtest" "help mmqrtest"}{...}
{vieweralsosee "mmqrtest canay" "help mmqrtest_canay"}{...}
{vieweralsosee "mmqrtest postestimation" "help mmqrtest_postestimation"}{...}
{vieweralsosee "mmqreg" "help mmqreg"}{...}
{viewerjumpto "Syntax" "mmqrtest_distfe##syntax"}{...}
{viewerjumpto "Description" "mmqrtest_distfe##description"}{...}
{viewerjumpto "Methods" "mmqrtest_distfe##methods"}{...}
{viewerjumpto "Options" "mmqrtest_distfe##options"}{...}
{viewerjumpto "Examples" "mmqrtest_distfe##examples"}{...}
{viewerjumpto "Stored results" "mmqrtest_distfe##results"}{...}
{title:Title}

{phang}
{bf:mmqrtest distfe} {hline 2} Distributional fixed-effects test,
H0: {it:delta_i} homogeneous across units


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:mmqrtest} {cmd:distfe} [{it:depvar} {it:indepvars}] {ifin}
[{cmd:,} {opt id(panelvar)} {opt q:uantile(numlist)} {opt gr:aph}
{opt name(string)} {opt gen:erate(stub)} {opt noheader}]


{marker description}{...}
{title:Description}

{pstd}
In MM-QR the quantile-{it:tau} fixed effect of unit {it:i} is

{p 8 8 2}
{it:alpha_i(tau)} = {it:alpha_i} + {it:delta_i q(tau)}

{pstd}
(Machado and Santos Silva 2019, eq. 6).  If {it:delta_i} = {it:delta} for
every unit, the {it:tau}-variation is common to all units and individual
heterogeneity shifts {it:all} quantiles by the same unit-specific constant:
the fixed effects are {bf:pure location shifters}, exactly the world of
Koenker (2004) and Canay (2011).  If {it:delta_i} varies across units, the
fixed effects are {bf:distributional}: time-invariant characteristics also
change dispersion and tail behavior, and location-shift estimators are
inconsistent.

{pstd}
Note that the relevant null is homogeneity ({it:delta_i} = {it:delta}),
{it:not} {it:delta_i} = 0: a common positive {it:delta} is required by the
scale-positivity condition whenever {it:X'gamma} can be small.


{marker methods}{...}
{title:Methods and formulas}

{pstd}
{it:delta_i} is the unit intercept of the Glejser-type scale regression of
|{it:R_it}| on {it:X_it} {hline 2} Step 3 of the MM-QR algorithm (Machado
and Santos Silva 2019, sec. 3.1; Glejser 1969).  The test is therefore the
classical fixed-effects equality F statistic in that auxiliary regression:

{p 8 8 2}
F = [ (RSS_pooled - RSS_within) / (G-1) ] / [ RSS_within / (N-G-k) ]

{pstd}
comparing the pooled model (common intercept, H0) with the within model
(unit intercepts, H1), where G is the number of units and k the number of
regressors.  The command also reports descriptive statistics of the
estimated {it:delta_i}, and the correlation between location effects
{it:alpha_i} and scale effects {it:delta_i}.

{pstd}
{bf:Caveats.}  |{it:R}-hat| is a generated regressand and {it:delta_i}-hat
converges at rate sqrt(T), so for very short panels the F test can
over-reject; a small-T warning is printed when average T < 10 (cf. the
O(1/T) biases in Machado and Santos Silva 2019, Theorem 4).


{marker options}{...}
{title:Options}

{phang}
{opt id(panelvar)}, {opt quantile(numlist)} {hline 2} see {helpb mmqrtest}.

{phang}
{opt graph} draws a two-panel figure: a histogram of {it:delta_i} and a
scatter of {it:delta_i} against {it:alpha_i} (the "location-scale
fixed-effects map") with a fitted line.

{phang}
{opt name(string)} names the combined graph (default {cmd:mmqrt_distfe}).

{phang}
{opt generate(stub)} saves {it:stub}{cmd:_alpha} ({it:alpha_i}) and
{it:stub}{cmd:_delta} ({it:delta_i}) as new variables.

{phang}
{opt noheader} suppresses the title box.


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. mmqreg ln_wage tenure ttl_exp, absorb(idcode) quantile(25 50 75)}{p_end}
{phang2}{cmd:. mmqrtest distfe, graph generate(fe)}{p_end}
{phang2}{cmd:. histogram fe_delta}{p_end}


{marker results}{...}
{title:Stored results}

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(F)}}F statistic{p_end}
{synopt:{cmd:r(df1)}}numerator df (G-1){p_end}
{synopt:{cmd:r(df2)}}denominator df (N-G-k){p_end}
{synopt:{cmd:r(p)}}p-value{p_end}
{synopt:{cmd:r(sd_delta)}}standard deviation of {it:delta_i}-hat{p_end}
{synopt:{cmd:r(corr_ad)}}corr({it:alpha_i}-hat, {it:delta_i}-hat){p_end}
{synopt:{cmd:r(G)}}number of units{p_end}
{synopt:{cmd:r(N)}}observations{p_end}

{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(verdict)}}{cmd:REJECT} or {cmd:NOT REJECTED}{p_end}


{title:Author}

{pstd}
Merwan Roudane {hline 2}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}
{hline 2} {browse "https://github.com/merwanroudane"}
