{smcl}
{* *! version 1.0.0 12jun2026}{...}
{vieweralsosee "mmqrtest" "help mmqrtest"}{...}
{vieweralsosee "mmqrtest postestimation" "help mmqrtest_postestimation"}{...}
{vieweralsosee "mmqreg" "help mmqreg"}{...}
{viewerjumpto "Syntax" "mmqrtest_spec##syntax"}{...}
{viewerjumpto "Description" "mmqrtest_spec##description"}{...}
{viewerjumpto "Methods" "mmqrtest_spec##methods"}{...}
{viewerjumpto "Options" "mmqrtest_spec##options"}{...}
{viewerjumpto "Examples" "mmqrtest_spec##examples"}{...}
{viewerjumpto "Stored results" "mmqrtest_spec##results"}{...}
{title:Title}

{phang}
{bf:mmqrtest spec} {hline 2} Location-scale specification /
overidentification test for the MM-QR model


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:mmqrtest} {cmd:spec} [{it:depvar} {it:indepvars}] {ifin}
[{cmd:,} {opt id(panelvar)} {opt q:uantile(numlist)} {opt aux(varlist)}
{opt gr:aph} {opt name(string)} {opt noheader}]

{pstd}
{cmd:mmqrtest overid} is a synonym.


{marker description}{...}
{title:Description}

{pstd}
The MM-QR model is restrictive: covariates may affect the distribution of
{it:Y} {bf:only} through the location {it:alpha_i} + {it:X'beta} and the
scale {it:delta_i} + {it:X'gamma}.  Machado and Santos Silva (2019) state
that this assumption {it:is} testable, {it:"by testing the overidentifying}
{it:restrictions resulting from augmenting [the moment conditions] with}
{it:conditions imposing the orthogonality between suitable functions of U}
{it:and functions of the regressors"} (fn. 5, citing Hansen 1982 and Newey
1985), and suggest that {it:"simpler regression-based procedures"} are
possible (sec. 7).  {cmd:mmqrtest spec} implements that regression-based
version.

{pstd}
Under H0 the standardized error
{it:U} = ({it:Y} - {it:alpha_i} - {it:X'beta}) / ({it:delta_i} +
{it:X'gamma}) is independent of {it:X} with E({it:U}) = 0 and
E(|{it:U}|) = 1.  Estimation already imposes orthogonality of {it:U} and
|{it:U}|-1 with {it:X} itself; the {bf:overidentifying} content of H0 is
that the same orthogonality holds for {it:additional} functions w({it:X})
not used in estimation.  Rejection signals {it:shape effects} {hline 2}
covariates moving skewness, kurtosis, or tails {hline 2} or some other
departure from the location-scale family.


{marker methods}{...}
{title:Methods and formulas}

{pstd}
With {it:U}-hat from the MM-QR sequential algorithm and default auxiliary
functions w({it:X}) = squares (and, when the regressor count is small,
pairwise products) of the regressors, three blocks of moment conditions are
examined through cluster-robust (by panel unit) Wald tests of the joint
significance of w({it:X}) in auxiliary regressions that also control for
{it:X}:

{p 8 12 2}
{bf:A. location:}  E[w({it:X}) {it:U}] = 0
{hline 2} regress {it:U}-hat on w({it:X}) and {it:X};

{p 8 12 2}
{bf:B. scale:}  E[w({it:X})(|{it:U}|-1)] = 0
{hline 2} regress |{it:U}-hat| on w({it:X}) and {it:X};

{p 8 12 2}
{bf:C. quantile:}  E[w({it:X})({it:tau} - I{c -({it:U} <= {it:q(tau)}{c )-})] = 0
for each requested {it:tau} {hline 2} checks the conditional quantiles of
{it:U} beyond the first two moments.

{pstd}
The overall p-value combines the three blocks by Bonferroni (block C is
itself Bonferroni-combined across {it:tau}), which is conservative.
Because {it:U}-hat embeds first-stage estimation error, the reported
asymptotic p-values are approximations; the cluster-robust construction
and the within-controls make them accurate in the designs we simulated,
but for small panels treat borderline rejections with caution (see also
the O(1/T) bias discussion in Machado and Santos Silva 2019, Theorem 4).

{pstd}
Observations with non-positive fitted scale are excluded from all
{it:U}-based moments; run {helpb mmqrtest_scalepos:mmqrtest scalepos} first.


{marker options}{...}
{title:Options}

{phang}
{opt id(panelvar)}, {opt quantile(numlist)} {hline 2} see {helpb mmqrtest}.
The quantiles determine the {it:tau} grid of block C.

{phang}
{opt aux(varlist)} replaces the default auxiliary functions w({it:X}) by a
user-supplied list (e.g. powers, interactions with external variables).
The variables must not be collinear with the regressors.

{phang}
{opt graph} draws a bar chart of the block p-values against the 0.05
reference line.

{phang}
{opt name(string)} names the graph (default {cmd:mmqrt_spec}).

{phang}
{opt noheader} suppresses the title box.


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. mmqreg ln_wage tenure ttl_exp, absorb(idcode) quantile(25 50 75)}{p_end}
{phang2}{cmd:. mmqrtest spec, graph}{p_end}

{pstd}Custom auxiliary functions:{p_end}
{phang2}{cmd:. gen ten3 = tenure^3}{p_end}
{phang2}{cmd:. mmqrtest spec, aux(ten3)}{p_end}


{marker results}{...}
{title:Stored results}

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(F_loc)}}block A Wald F{p_end}
{synopt:{cmd:r(p_loc)}}block A p-value{p_end}
{synopt:{cmd:r(F_scale)}}block B Wald F{p_end}
{synopt:{cmd:r(p_scale)}}block B p-value{p_end}
{synopt:{cmd:r(p_quant)}}block C p-value (Bonferroni across tau){p_end}
{synopt:{cmd:r(df_w)}}number of auxiliary functions tested{p_end}
{synopt:{cmd:r(p)}}overall Bonferroni p-value{p_end}

{p2col 5 18 22 2: Matrices}{p_end}
{synopt:{cmd:r(qtests)}}per-{it:tau} block C statistics (tau, F, p){p_end}

{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(verdict)}}{cmd:REJECT} or {cmd:NOT REJECTED}{p_end}


{title:Author}

{pstd}
Merwan Roudane {hline 2}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}
{hline 2} {browse "https://github.com/merwanroudane"}
