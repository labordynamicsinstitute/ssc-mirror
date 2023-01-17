{smcl}
{* 16jan2023}{...}
{hi:help ipwlogit}{...}
{right:{browse "http://github.com/benjann/ipwlogit/"}}
{hline}

{title:Title}

{pstd}{hi:ipwlogit} {hline 2} Marginal logistic regression by inverse probability weighting


{title:Syntax}

{p 8 15 2}
    {cmd:ipwlogit} {depvar} {help varname:{it:tvar}} [{indepvars}] {ifin} {weight}
    [{cmd:,}
    {help ipwlogit##opt:{it:options}}
    ]

{synoptset 20 tabbed}{...}
{marker opt}{synopthdr:options}
{synoptline}
{syntab :Main}
{synopt :{cmdab:psm:ethod(}{help ipwlogit##psmethod:{it:method}{cmd:)}}}propensity
    score estimation method
    {p_end}
{synopt :{cmdab:pso:pts(}{help ipwlogit##psopts:{it:options}{cmd:)}}}options
    passed through to propensity score model
    {p_end}
{synopt :{opt trunc:ate(#)}}truncate weights, {it:#} in [0,.5]
    {p_end}
{synopt :{opt bin:s(#)}}number of bins for continuous treatment
    {p_end}
{synopt :{opt discr:ete}}treat continuous treatment as discrete
    {p_end}
{synopt :{opt asbal:anced}}use balanced design (non-stabilized weights)
    {p_end}
{synopt :{opt noi:sily}}display output from propensity score estimation
    {p_end}
{synopt :{opt nodot:s}}suppress propensity score estimation progress dots
    {p_end}
{synopt :{opt nocons:tant}}suppress constant term in outcome model
    {p_end}
{synopt :{help logit##maximize_options:{it:maximize_options}}}maximization options
    for outcome model; seldom used
    {p_end}
{synopt :{opth gen:erate(newvar)}}store IPWs
    {p_end}
{synopt :{opth tgen:erate(newvar)}}store binned treatment variable
    {p_end}
{synopt :{opt replace}}allow replacing existing variables
    {p_end}

{syntab :SE/Robust}
{synopt :{cmd:vce(}{help ipwlogit##vcetype:{it:vcetype}}{cmd:)}}variance estimation
    method; {it:vcetype} may be {cmdab:r:obust}, {cmdab:cl:uster} {it:clustvar},
    {cmd:svy}, {cmdab:boot:strap}, or {cmdab:jack:knife}
    {p_end}
{synopt :{opt novceadj:ust}}treat IPWs as fixed
    {p_end}
{synopt :{opt ifgen:erate(spec)}}store influence functions; {it:spec} may be
    {it:namelist} or {it:stub}{cmd:*}
    {p_end}
{synopt :{opt rif:gerate(spec)}}store recentered influence functions; {it:spec} is
    {it:namelist} or {it:stub}{cmd:*}
    {p_end}
{synopt :{opt ifs:caling(spec)}}scaling of (recentered) IFs; {it:spec} if {cmd:total} (default) or {cmd:mean}
    {p_end}

{syntab :Reporting}
{synopt :{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}
    {p_end}
{synopt :{opt or}}report odds ratio
    {p_end}
{synopt :{opt nohead:er}}suppress table header
    {p_end}
{synopt :{opt notab:le}}suppress table of results
    {p_end}
{synopt :{opt noipw}}suppress table of IPW statistics
    {p_end}
{synopt :{help estimation options##display_options:{it:display_options}}}standard display option
    {p_end}
{synopt :{opt coefl:egend}}display legend instead of statistics
    {p_end}
{synoptline}
{pstd}
    {it:indepvars} may contain factor variables; see {help fvvarlist}.
    {p_end}
{pstd}
    {cmd:pweight}s, {cmd:fweight}s, and {cmd:iweight}s are allowed; see help
    {help weight}.
    {p_end}


{title:Description}

{pstd}
    {cmd:ipwlogit} fits marginal logistic regression of {it:depvar} on
    {it:tvar}, possibly adjusting for {it:indepvars} by inverse probability
    weighting (IPW). The resulting estimate can be interpreted as a marginal (log)
    odds ratio of a positive outcome. {it:depvar} equal to nonzero and nonmissing
    (typically {it:depvar} equal to one) indicates a positive outcome, whereas
    {it:depvar} equal to zero indicates a negative outcome.

{pstd}
    {it:tvar} can be categorical, continuous, or discrete.

{phang}
    {space 2}o Categorical treatment: Specify {it:tvar} as
    {cmd:i.}{it:varname}, where {it:varname} is the name of the treatment
    variable. More complicated factor-variable specifications such as, e.g.,
    {cmd:ibn.}{it:varname}, {bind:{cmd:i(2 3 4).}{it:varname}}, or 
    {bind:{cmd:0.}{it:varname} {cmd:1.}{it:varname}} are also allowed. In any 
    case, the computation of inverse probability
    weights (IPWs) will be based on the observed levels of the treatment variable,
    not the levels specified in {it:tvar}.

{phang}
    {space 2}o Continuous treatment: Specify {it:tvar} as {it:varname} or
    {cmd:c.}{it:varname} to model a linear effect, or as 
    {cmd:c.}{it:varname}{cmd:##}{cmd:c.}{it:varname} to model a nonlinear
    effect. More complicated interaction specifications such as
    {bind:{it:varname} {cmd:c.}{it:varname}{cmd:#}{cmd:c.}{it:varname}}
    or {cmd:c.}{it:varname}{cmd:##}{cmd:c.}{it:varname}{cmd:##}{cmd:c.}{it:varname}
    are also allowed. The computation of IPWs will be based
    based on a coarsened treatment variable that divides the original
    treatment into a series of equal probability bins. Use option {cmd:bins()}
    to control the number of bins.

{phang}
    {space 2}o Discrete treatment: Specify {it:tvar} as for a continuous 
    treatment, but additionally apply option {cmd:discrete}. No binning will be
    applied, that is, the computation of IPWs will be based on the observed levels
    of the treatment variable.

{pstd}
    For details on inverse probability weighting and marginal odds ratios see
    {browse "https://ideas.repec.org/p/bss/wpaper/44.html":Jann and Karlson (2023)}.


{title:Options}

{marker psmethod}{...}
{phang}
    {opt psmethod(method)} selects the propensity score estimation method. Supported
    methods are as follows.

{p2colset 13 22 24 2}{...}
{p2col:{opt l:ogit}}for each treatment level, fit
    a logistic regression of the level against all other levels
    (using command {helpb logit})
    {p_end}
{p2col:{opt m:logit}}fit a multinomial logistic regression across all
    levels (using command {helpb mlogit})
    {p_end}
{p2col:{opt o:logit}}fit an ordered logistic regression across all
    levels (using command {helpb ologit})
    {p_end}
{p2col:{opt go:logit}}fit a generalized ordered logistic regression  across all
    levels; this requires command {helpb gologit2} by Williams (2006)
    to be installed on the system (type {stata ssc install gologit2})
    {p_end}
{p2col:{opt co:logit}}fit a series of cumulative odds models across
    treatment levels (using command {helpb logit}); this is asymptotically
    equivalent to {helpb gologit2}, but imposes less computational burden
    {p_end}

{pmore}
    The default method depends on the type of the treatment variable. For a categorical
    treatment with two levels (dichotomous treatment), the default is {cmd:logit}; for
    a categorical treatment with more than two levels, the default is {cmd:mlogit}; for a
    continuous or discrete treatment, {cmd:cologit} is the default. For a dichotomous treatment,
    the choice of method does not matter; results will always be the same. For an
    ordered categorical treatment, you may want to consider {cmd:cologit}
    (or {cmd:gologit} or {cmd:ologit}) instead of {cmd:mlogit}.

{marker psopts}{...}
{phang}
    {opt psopts(options)} specifies options to be passed through to the
    propensity score estimation command. This may be useful, for example,
    to specify constraints. See the help file of the relevant command
    ({helpb logit}, {helpb mlogit}, {helpb ologit}, or {helpb gologit2}) for
    information on available options (option {cmd:link()} is not allowed in case
    of {helpb gologit2}).

{phang}
    {opt truncate(#)}, {it:#} in [0,0.5], applies truncation to the inverse
    probability weights. Weights smaller than quantile {it:#} of the overall
    distribution of weights will be replaced by the value of quantile {it:#}
    and weights larger than quantile 1-{it:#} will be replaced by the value of
    quantile 1-{it:#}. For example, type {cmd:truncate(0.01)} to truncate the
    weights to the 1st and 99th percentile. Truncation will always be applied
    on the basis of stabilized weights; truncated non-stabilized weights will be
    obtained by rescaling the truncated stabilized weights.

{phang}
    {opt bins(#)} sets the (maximum) number of quantile bins used to categorize
    a continuous treatment. The resulting number of bins may be less than
    {it:#} if there is heaping in the distribution of the treatment variable. The
    default is to determine the number of bins as ceil(ln({it:N})/ln(2)) + 1
    (Sturges' rule for the number of histogram bins).

{phang}
    {opt discrete} declares the treatment variable as discrete. In this case,
    the variable will not be categorized based on quantiles. Use this option for
    a quantitative treatment with relatively few distinct levels.

{phang}
    {opt asbalanced} scales the inverse probability weights in a way such that
    they correspond to a balanced design in which each treatment level has the
    same marginal probability. By default, {cmd:ipwlogit} uses so-called stabilized
    weights that are scaled such that the sum of weights within each treatment
    level corresponds to the relative frequency of the level (in expectation). Use
    {cmd:asbalanced} to request non-stabilized weights that are scaled such that
    the sum of weights within each treatment levels is the same (in expectation).

{phang}
    {opt noisily} displays the output from the model(s) used to estimate
    propensity scores. By default, such output is suppressed.

{phang}
    {opt nodots} suppresses the propensity score estimation progress dots. {cmd:nodots}
    has no effect of {cmd:noisily} is specified.

{phang}
    {opt noconstant} suppresses the constant term (intercept) in the outcome
    model. This may be useful if you want to report odds by levels of a
    categorical treatment rather than odds ratios with respect to the base
    level (specify {it:tvar} as {cmd:ibn.}{it:varname} in this case).

{phang}
    {it:maximize_options} are maximization options for the outcome model. See
    help {helpb logit##maximize_options:logit} for details.

{phang}
    {opt generate(newvar)} stores the inverse probability weights (IPWs) in variable
    {newvar}. The stored IPWs are net of sampling weights. To obtain overall weights,
    multiply the IPWs by the sampling weights. Option {cmd:generate()} is not
    allowed with {cmd:vce(bootstrap)} or {cmd:vce(jackknife)}.

{phang}
    {opt tgenerate(newvar)} stores the binned treatment in variable
    {newvar}. Option {cmd:tgenerate()} is not
    allowed with {cmd:vce(bootstrap)} or {cmd:vce(jackknife)}, or if the
    treatment variable is categorical.

{phang}
    {opt replace} allows to overwrite existing variables.

{marker vcetype}{...}
{phang}
    {cmd:vce(}{it:vcetype}{cmd:)} specifies how standard errors
    are computed. {it:vcetype} may be:

            {opt r:obust}
            {opt cl:uster} {it:clustvar}
            {opt svy} [{help svy##svy_vcetype:{it:svy_vcetype}}] [{cmd:,} {help svy##svy_options:{it:svy_options}} ]
            {opt boot:strap} [{cmd:,} {help bootstrap:{it:bootstrap_options}} ]
            {opt jack:knife} [{cmd:,} {help jackknife:{it:jackknife_options}} ]

{pmore}
    {cmd:vce(robust)}, the default, computes robust standard errors based on
    influence functions.

{pmore}
    {bind:{cmd:vce(cluster} {it:clustvar}{cmd:)}} computes standard errors based
    on influence functions allowing for intragroup correlation, where
    {it:clustvar} specifies to which group each observation belongs.

{pmore}
    {cmd:vce(svy)} computes standard errors taking the survey design as set by
    {helpb svyset} into account. The syntax is equivalent to the syntax of the {helpb svy}
    prefix command; that is, {cmd:vce(svy)} is {cmd:ipwlogit}'s way to support
    the {helpb svy} prefix.

{pmore}
    {cmd:vce(bootstrap)} and {cmd:vce(jackknife)} compute standard errors using
    {helpb bootstrap} or {helpb jackknife}, respectively; see help {it:{help vce_option}}.

{phang}
    {opt novceadjust} assumes the IPWs as fixed (rather than estimated)
    when computing standard errors. This typically leads to slightly
    conservative results. {cmd:vce(bootstrap)}, {cmd:vce(jackknife)}, and
    {cmd:vce(svy)} with replication-based VCE imply {cmd:novceadjust}
    (to save a little bit of computer time).

{phang}
    {opt ifgenerate(spec)} stores the influence functions of the parameters of the
    outcome model. Either specify a list of new variables names,
    or specify {it:stub}{cmd:*}, in which case the new variables will be named
    {it:stub}{cmd:1}, {it:stub}{cmd:2}, etc. Option {cmd:ifgenerate()} is not
    allowed with {cmd:vce(bootstrap)} or {cmd:vce(jackknife)}.

{phang}
    {opt rifgenerate(spec)} stores the recentered influence functions; see the description
    of {cmd:ifgenerate()}. Only one of {cmd:ifgenerate()} and {cmd:rifgenerate()}
    is allowed.

{phang}
    {opt ifscaling(spec)} determines the scaling of the stored (recentered) influence
    functions. {it:spec} can be {opt t:otal} (scaling for analysis by
    {helpb total}) or {opt m:ean} (scaling for analysis by {helpb mean}). Default is 
    {cmd:ifscaling(total)}.

{phang}
    {opt level(#)} specifies the confidence level, as a percentage, for
    confidence intervals. The default is {cmd:level(95)} or as
    set by {helpb set level}.

{phang}
    {opt or} reports the estimated coefficients transformed to odds ratios,
    that is, exp(b) rather than b. Standard errors and confidence intervals are
    similarly transformed. This option affects how results are displayed, not
    how they are estimated. {cmd:or} may be specified at estimation or when
    replaying previously estimated results. When applying multiple imputation,
    specify {cmd:or} as option to {helpb mi estimate}, not as option to
    {cmd:ipwlogit}.

{phang}
    {opt noheader} suppresses the display of the table header.

{phang}
    {opt notable} suppresses the display of the table of results.

{phang}
    {opt noipw} suppresses the display of the table of IPW statistics.

{phang}
    {it:display_options} are usual display options as documented in
    {helpb estimation options##display_options:[R] Estimation options}.

{phang}
    {opt coeflegend} specifies that the legend of the coefficients and how to
    specify them in an expression be displayed rather
    than displaying the statistics for the coefficients.


{title:Example}

{pstd}
    The following example illustrates how the adjusted marginal odds ratio can be
    different from the conditional odds ratio:

        {it:unadjusted marginal odds ratio}
        . {stata webuse lbw}
        . {stata logit low i.smoke, or vce(robust)}
        . {stata ipwlogit low i.smoke, or}

        {it:conditional odds ratio}
        . {stata logit low i.smoke age lwt i.race ptl ht ui, or vce(robust)}

        {it:adjusted marginal odds ratio}
        . {stata ipwlogit low i.smoke age lwt i.race ptl ht ui, or}


{title:Stored results}

{pstd}
{cmd:ipwlogit} stores the following in {cmd:e()}:

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(sum_w)}}sum of base weights{p_end}
{synopt:{cmd:e(tk)}}number of treatment levels/bins{p_end}
{synopt:{cmd:e(truncate)}}value of {cmd:truncate()}{p_end}
{synopt:{cmd:e(bins)}}requested number of bins; continuous treatment only{p_end}
{synopt:{cmd:e(k)}}number of parameters in outcome model{p_end}
{synopt:{cmd:e(k_eq)}}number of equations in outcome model{p_end}
{synopt:{cmd:e(df_m)}}degrees of freedom of outcome model{p_end}
{synopt:{cmd:e(r2_p)}}pseudo-R-squared of outcome model{p_end}
{synopt:{cmd:e(ll)}}log likelihood of outcome model{p_end}
{synopt:{cmd:e(ll_0)}}log likelihood of constant-only outcome model{p_end}
{synopt:{cmd:e(N_cds)}}number of completely determined successes in outcome model{p_end}
{synopt:{cmd:e(N_cdf)}}number of completely determined failures in outcome model{p_end}
{synopt:{cmd:e(ic)}}number of iterations of outcome model{p_end}
{synopt:{cmd:e(rc)}}return code of outcome model{p_end}
{synopt:{cmd:e(converged)}}{cmd:1} if outcome model converged, {cmd:0} otherwise{p_end}
{synopt:{cmd:e(N_clust)}}number of clusters{p_end}
{synopt:{cmd:e(chi2)}}outcome model chi-squared{p_end}
{synopt:{cmd:e(p)}}{it:p}-value for model test{p_end}
{synopt:{cmd:e(rank)}}rank of {cmd:e(V)}{p_end}

{p2col 5 23 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:ipwlogit}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(tvar)}}treatment variable specification{p_end}
{synopt:{cmd:e(tname)}}name of treatment variable{p_end}
{synopt:{cmd:e(ttype)}}{cmd:factor}, {cmd:discrete}, or {cmd:continuous}; type of treatment variable{p_end}
{synopt:{cmd:e(tlevels)}}list of treatment levels{p_end}
{synopt:{cmd:e(indepvars)}}adjustment variables{p_end}
{synopt:{cmd:e(psmethod)}}propensity score estimation method{p_end}
{synopt:{cmd:e(psopts)}}options passed through to propensity score estimation{p_end}
{synopt:{cmd:e(asbalanced)}}{cmd:asbalanced} or empty{p_end}
{synopt:{cmd:e(mlopts)}}maximization options passed through to outcome model{p_end}
{synopt:{cmd:e(wtype)}}weight type{p_end}
{synopt:{cmd:e(wexp)}}weight expression{p_end}
{synopt:{cmd:e(clustvar)}}name of cluster variable{p_end}
{synopt:{cmd:e(chi2type)}}{cmd:Wald}; type of model chi-squared test{p_end}
{synopt:{cmd:e(vce)}}{it:vcetype} specified in {cmd:vce()}{p_end}
{synopt:{cmd:e(vcetype)}}title used to label Std. err.{p_end}
{synopt:{cmd:e(vceadjust)}}{cmd:novceadjust} or empty{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}
{synopt:{cmd:e(generate)}}name of variable containing IPWs{p_end}
{synopt:{cmd:e(tgenerate)}}name of variable containing binned treatment{p_end}
{synopt:{cmd:e(ifgenerate)}}names of variables containing IFs{p_end}
{synopt:{cmd:e(iftype)}}{cmd:IF} or {cmd:RIF} (or empty){p_end}
{synopt:{cmd:e(ifscaling)}}{cmd:total} or {cmd:mean} (or empty){p_end}

{p2col 5 23 26 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}
{synopt:{cmd:e(V_modelbased)}}model-based variance{p_end}
{synopt:{cmd:e(at)}}breaks of continuous treatment or values of discrete treatment{p_end}
{synopt:{cmd:e(prop)}}marginal treatment probabilities{p_end}
{synopt:{cmd:e(ipw)}}information on the distribution of the IPWs{p_end}

{p2col 5 23 26 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}


{title:References}

{phang}
    Jann, Ben, Kristian Bernt Karlson. 2023. Estimation of marginal odds ratios. University
    of Bern Social Sciences Working Papers 44. Available from
    {browse "https://ideas.repec.org/p/bss/wpaper/44.html"}.
    {p_end}
{phang}
    Williams, Richard. 2006. Generalized ordered logit/partial proportional odds
    models for ordinal dependent variables. The Stata Journal
    6(1):58-82. DOI: {browse "https://doi.org/10.1177/1536867X0600600104":10.1177/1536867X0600600104}
    {p_end}

{title:Author}

{pstd}
    Ben Jann, University of Bern, ben.jann@unibe.ch

{pstd}
    Thanks for citing this software as follows:

{pmore}
    Jann, B. (2022). ipwlogit: Stata module to fit marginal logistic regression
    by inverse probability weighting. Available from
    {browse "http://github.com/benjann/ipwlogit/"}.


{title:Also see}

{psee}
    Online:  help for
    {helpb logit}, {helpb mlogit}, {helpb ologit},
    {helpb gologit2} (if installed), {helpb riflogit} (if installed),
    {helpb lnmor} (if installed)
