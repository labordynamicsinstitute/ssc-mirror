{smcl}
{* 18sep2021}{...}
{hi:help robreg}{...}
{right:{browse "http://github.com/benjann/robreg/"}}
{hline}
{p 0 0 2}

{title:Title}

{pstd}{hi:robreg} {hline 2} Robust regression


{title:Contents}

    {help robreg##syntax:Syntax}
    {help robreg##description:Description}
    {help robreg##options:Options}
    {help robreg##examples:Examples}
    {help robreg##results:Stored results}
    {help robreg##references:References}
    {help robreg##author:Author}
    {help robreg##alsosee:Also see}


{marker syntax}{...}
{title:Syntax}

{pstd}
    Estimation

{p 8 15 2}
    {cmd:robreg} {it:subcmd} {depvar} [{indepvars}] {ifin} {weight}
    [{cmd:,} {help robreg##opts:{it:options}} ]

{pmore}
    where {it:subcmd} is

{p2colset 13 20 22 2}{...}
{p2col:{opt ls}}least squares regression; equivalent to {helpb regress}{p_end}
{p2col:{opt q}}quantile regression; similar to {helpb qreg}{p_end}
{p2col:{opt m}}M regression{p_end}
{p2col:{opt s}}S regression{p_end}
{p2col:{opt mm}}MM regression{p_end}
{p2col:{opt lts}}least trimmed squares regression{p_end}
{p2col:{opt lqs}}least quantile of squares regression{p_end}
{p2col:{opt lms}}least median of squares regression{p_end}

{pmore}
    {it:indepvars} may contain factor variables; see {help fvvarlist}.
    {p_end}
{pmore}
    {it:depvar} and {it:indepvars} may contain time-series operators; see {help tsvarlist}.
    {p_end}
{pmore}
    {cmd:fweight}s and {cmd:pweight}s are allowed; see {help weight}.
    {p_end}
{pmore}
    The {helpb svy} prefix is allowed with {cmd:robreg ls}, {cmd:robreg q}, and {cmd:robreg m},
    unless {cmd:ivar()} or {cmd:absorb()} is specified.

{pstd}
    Refitting MM after {cmd:robreg s} or {cmd:robreg mm}

{p 8 15 2}
    {cmd:robreg} {cmd:mm} [{cmd:,} {help robreg##mm_refit_opts:{it:mm_refit_options}} ]

{pstd}
    Replaying results

{p 8 15 2}
    {cmd:robreg} [{cmd:,} {help robreg##repopts:{it:reporting_options}} ]

{pstd}
    Hausman test between models

{p 8 15 2}
    {cmd:robreg} {cmdab:haus:man} [{it:model1} [{it:model2}]] [{cmd:,}
    {help robreg##hopts:{it:hausman_options}} ]

{pmore}
    where {it:model1} and {it:model2} are names of stored estimates from
    {cmd:robreg} (or {cmd:.} for the active estimates). Omitting {it:model2}
    is only allowed if applying {cmd:robreg hausman} to a model obtained
    by {cmd:robreg mm} (the active estimates will be used if {it:model1} is also
    omitted).

{pstd}
    Prediction

{p 8 15 2}
    {cmd:predict} [{help datatypes:{it:type}}]
        {c -(}{newvar} |
        {help newvarlist##stub*:{it:stub}}{cmd:*} |
        {it:{help newvar:newvar1}} {it:{help newvar:newvar2}} {cmd:...}{c )-} {ifin}
        [{cmd:,} {it:{help robreg##propts:predict_options}} ]


{synoptset 21 tabbed}{...}
{marker opts}{col 5}{it:{help robreg##options:options}}{col 28}description
{synoptline}
{syntab :Main}
{synopt :{opt nocons:tant}}suppress constant term
    {p_end}
{synopt :{opt nor2}}do not compute the (pseudo) R-squared
    {p_end}

{syntab :Subcommand}
{synopt :{help robreg##ls_opts:{it:ls_options}}}additional options for {cmd:robreg ls}
    {p_end}
{synopt :{help robreg##q_opts:{it:q_options}}}additional options for {cmd:robreg q}
    {p_end}
{synopt :{help robreg##m_opts:{it:m_options}}}additional options for {cmd:robreg m}
    {p_end}
{synopt :{help robreg##s_opts:{it:s_options}}}additional options for {cmd:robreg s}
    {p_end}
{synopt :{help robreg##mm_opts:{it:mm_options}}}additional options for {cmd:robreg mm}
    {p_end}
{synopt :{help robreg##lts_opts:{it:lts_options}}}additional options for {cmd:robreg lts}
    {p_end}
{synopt :{help robreg##lqs_opts:{it:lqs/lms_options}}}additional options for {cmd:robreg lqs/lms}
    {p_end}

{syntab :VCE/SE}
{synopt:{cmd:vce(}{it:{help robreg##vcetype:vcetype}}{cmd:)}}variance estimation method;
    {it:vcetype} may be {cmdab:r:obust}, {cmdab:cl:uster} {it:clustvar},
    {cmdab:boot:strap}, or {cmdab:jack:knife}
    {p_end}
{synopt :{opt cl:uster(clustvar)}}synonym for
    {cmd:vce(cluster} {it:clustvar}{cmd:)}
    {p_end}
{synopt :{opt f:test}}report F tests rather then Wald tests
    {p_end}
{synopt :{opt nose}}do not compute standard errors
    {p_end}

{marker repopts}{...}
{syntab :Reporting}
{synopt :{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}
    {p_end}
{synopt :{opt nohead:er}}suppress table header
    {p_end}
{synopt :{opt notab:le}}suppress table of results
    {p_end}
{synopt :{opt all}}report results from all equations (relevant for {cmd:robreg s} and {cmd:robreg mm})
    {p_end}
{synopt :{help robreg##displayopts:{it:display_options}}}standard
    reporting options as described in
    {helpb estimation options:[R] estimation options}
    {p_end}

{marker optimopts}{...}
{syntab :Optimization}
{synopt :{opt tol:erance(#)}}tolerance for iterative algorithms
    {p_end}
{synopt :{opt iter:ate(#)}}maximum number of iterations
    {p_end}
{synopt :{opt relax}}do not return error if convergence is not reached
    {p_end}
{synopt :{opt noquad}}do not use quad precision when taking cross products
    {p_end}
{synopt :{opt nolog}}do not display progress information
    {p_end}
{synoptline}


{marker ls_opts}{col 5}{it:{help robreg##ls_options:ls_options}}{col 28}description
{synoptline}
{synopt :{help robreg##fe_opts:{it:fe_options}}}fixed-effects options
    {p_end}
{synoptline}


{marker q_opts}{col 5}{it:{help robreg##q_options:q_options}}{col 28}description
{synoptline}
{syntab :Main}
{synopt :{opt q:uantile(#)}}estimate # quantile; the default is 0.5 (LAD or median regression)
    {p_end}

{syntab :VCE/SE}
{synopt :{opt fit:ted}}alternative approach to estimate the sparsity function
    {p_end}
{synopt :{opt bo:finger}}use Bofinger's bandwidth rather than the Hall-Sheather bandwidth
    {p_end}

{syntab :Starting values}
{synopt :{opt init(matname)}}use custom starting values
    {p_end}
{synoptline}


{marker m_opts}{col 5}{it:{help robreg##m_options:m_options}}{col 28}description
{synoptline}
{syntab :Main}
{synopt :{opt h:uber}}use Huber objective function; the default
    {p_end}
{synopt :{opt bi:weight}}use biweight objective function
    {p_end}
{synopt :{opt bis:quare}}synonym for {cmd:biweight}
    {p_end}
{synopt :{opt eff:iciency(#)}}gaussian efficiency, in percent;
    default is {cmd:efficiency(95)}
    {p_end}
{synopt :{opt k(#)}}tuning constant; alternative to {cmd:efficiency()}
    {p_end}
{synopt :{help robreg##fe_opts:{it:fe_options}}}fixed-effects options
    {p_end}

{syntab :Scale}
{synopt :{opt s:cale(#)}}provide custom (starting) value for scale
    {p_end}
{synopt :{opt update:scale}}update scale in each iteration
    {p_end}
{synopt :{opt cen:ter}}center residuals when computing scale
    {p_end}

{syntab :Starting values}
{synopt :{cmd:init(}{help robreg##m_init:{it:arg}}{cmd:)}}set the starting values;
    default is {cmd:init(lad)}
    {p_end}
{synoptline}


{marker s_opts}{col 5}{it:{help robreg##s_options:s_options}}{col 28}description
{synoptline}
{syntab :Main}
{synopt :{opt bp(#)}}breakdown point, in percent; default is {cmd:bp(50)}
    {p_end}
{synopt :{opt k(#)}}tuning constant; alternative to {cmd:bp()}
    {p_end}
{synopt :{opt nohaus:man}}do not compute Hausman test of S against LS
    {p_end}
{synopt :{cmd:m(}{varlist} [{cmd:,} {it:{help robreg##s_mopt:opts}}]{cmd:)}}variables
    to be partialled out in the subsampling algorithm
    {p_end}
{synopt :{help robreg##fe_opts:{it:fe_options}}}fixed-effects options
    {p_end}

{syntab :Subsampling algorithm}
{synopt :{cmdab:n:samp(}{help robreg##s_nsamp:{it:args}}{cmd:)}}number of trial samples; {it:args} may be {it:#}
    or {it:alpha} [{it:epsilon}]
    {p_end}
{synopt :{opt rstep:s(#)}}number of local improvement steps; default
    is {cmd:rsteps(2)}
    {p_end}
{synopt :{opt nk:eep(#)}}number of candidates to be kept for final refinement; default
    is {cmd:nkeep(5)}
    {p_end}
{synopt :{opt naive}}use naive subsampling algorithm
    {p_end}
{synopt :{opt alt}}use alternative nonsingular subsampling algorithm
    {p_end}
{synopt :{opt nostd}}do not standardize the data (not recommended)
    {p_end}
{synoptline}


{marker mm_opts}{col 5}{it:{help robreg##mm_options:mm_options}}{col 28}description
{synoptline}
{syntab :Main}
{synopt :{opt eff:iciency(#)}}gaussian efficiency, in percent; default
    is {cmd:efficiency(85)}
    {p_end}
{synopt :{opt k(#)}}tuning constant; alternative to {cmd:efficiency()}
    {p_end}
{synopt :{opt nohaus:man}}do not compute Hausman test of MM against S
    {p_end}

{syntab :S estimate}
{synopt :{opt bp(#)}}breakdown point, in percent; default is {cmd:bp(50)}
    {p_end}
{synopt :{opt sopt:s(options)}}other options passed through to the S algorithm
    {p_end}
{synoptline}


{marker lts_opts}{col 5}{it:{help robreg##lts_options:lts_options}}{col 28}description
{synoptline}
{syntab :Main}
{synopt :{opt bp(#)}}breakdown point, in percent; default is {cmd:bp(50)}
    {p_end}

{syntab :Subsampling algorithm}
{synopt :{opt n:samp(args)}}number of trial samples; {it:args} may be {it:#}
    or {it:alpha} [{it:epsilon}]
    {p_end}
{synopt :{opt cstep:s(#)}}number of concentration steps; default
    is {cmd:csteps(2)}
    {p_end}
{synopt :{opt nk:eep(#)}}number of candidates to be kept for final refinement; default
    is {cmd:nkeep(10)}
    {p_end}
{synopt :{opt naive}}use naive subsampling algorithm
    {p_end}
{synopt :{opt alt}}use alternative nonsingular subsampling algorithm
    {p_end}
{synopt :{opt nostd}}do not standardize the data (not recommended)
    {p_end}
{synoptline}


{marker lqs_opts}{col 5}{it:{help robreg##lqs_options:lqs/lms_options}}{col 28}description
{synoptline}
{syntab :Main}
{synopt :{opt bp(#)}}breakdown point, in percent (only allowed with {cmd:robreg lqs})
    {p_end}

{syntab :Subsampling algorithm}
{synopt :{opt n:samp(args)}}number of trial samples; {it:args} may be {it:#}
    or {it:alpha} [{it:epsilon}]
    {p_end}
{synopt :{opt naive}}use naive subsampling algorithm
    {p_end}
{synopt :{opt alt}}use alternative nonsingular subsampling algorithm
    {p_end}
{synopt :{opt nostd}}do not standardize the data (not recommended)
    {p_end}
{synoptline}


{marker fe_opts}{col 5}{it:{help robreg##fe_options:fe_options}}{col 28}description
{synoptline}
{synopt :{opt i:var(varname)}}variable identifying the groups; VCE like {helpb xtreg:xtreg,fe}
    {p_end}
{synopt :{opt a:bsorb(varname)}}variable identifying the groups; VCE like {helpb areg}
    {p_end}
{synopt :[{ul:{cmd:no}}]{opt u:save}}whether to store fixed effects in {cmd:e()}
    {p_end}
{synopt :{opth ugen:erate(newvar)}}store fixed effects as a variable, rather than in {cmd:e()}
    {p_end}
{synopt :{opt replace}}allow overwriting existing variable
    {p_end}
{synoptline}


{marker mm_refit_opts}{col 5}{it:{help robreg##mm_refit_options:mm_refit_options}}{col 28}description
{synoptline}
{synopt :{opt eff:iciency(#)}}gaussian efficiency, in percent; default
    is {cmd:efficiency(85)}
    {p_end}
{synopt :{opt k(#)}}tuning constant; alternative to {cmd:efficiency()}
    {p_end}
{synopt :{opt nohaus:man}}do not compute Hausman test of MM against S
    {p_end}
{synopt :{opt f:test}}report F test rather then Wald test
    {p_end}
{synopt :{help robreg##repopts:{it:reporting_options}}}reporting options
    {p_end}
{synopt :{help robreg##optimopts:{it:optimization_options}}}optimization options
    {p_end}
{synoptline}


{marker hopts}{col 5}{help robreg##hausman_options:{it:hausman_options}}{col 28}description
{synoptline}
{synopt:{opt cons:tant}}include constant in the test
    {p_end}
{synopt:{opt com:mon}}restrict the test to coefficients that exist in both models
    {p_end}
{synopt:{opt keep(names)}}coefficients to be included; may use {cmd:*} and {cmd:?} wildcards
    {p_end}
{synopt:{opt drop(names)}}coefficients to be excluded; may use {cmd:*} and {cmd:?} wildcards
    {p_end}
{synopt :{opt f:test}}report F test rather then Wald test
    {p_end}
{synopt :{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}
    {p_end}
{synopt :{opt nohead:er}}suppress header containing the overall test
    {p_end}
{synopt :{opt notab:le}}suppress table containing tests by individual coefficients
    {p_end}
{synopt :{help robreg##displayopts:{it:display_options}}}standard
    reporting options as described in
    {helpb estimation options:[R] estimation options}
    {p_end}
{synopt :{opt post}}post results in {cmd:e()}
    {p_end}
{synoptline}


{marker propts}{col 5}{help robreg##predict_options:{it:predict_options}}{col 28}description
{synoptline}
{synopt:{opt xb}}linear prediction
    {p_end}
{p2coldent :* {opt xbu}}linear prediction plus fixed effect
    {p_end}
{p2coldent :* {opt u}}fixed effect
    {p_end}
{p2coldent :* {opt ue}}fixed effect plus residual
    {p_end}
{synopt:{opt r:esiduals}}residuals
    {p_end}
{synopt:{opt rs:tandard}}standardized residuals
    {p_end}
{synopt:{opt out:lier}[{cmd:(}{it:#}{cmd:)}]}outlier indicator
    {p_end}
{synopt:{opt in:lier}[{cmd:(}{it:#}{cmd:)}]}inlier indicator
    {p_end}
{p2coldent :§ {opt w:eights}}RLS weight
    {p_end}
{p2coldent :# {opt sub:set}}H-subset indicator
    {p_end}
{p2coldent :+ {opt sc:ores}}equation-level scores
    {p_end}
{p2coldent :+ {opt if:s}}coefficient-level influence functions
    {p_end}
{p2coldent :+ {opt rif:s}}recentered influence functions
    {p_end}
{synoptline}
{pstd}* only after {cmd:robreg ls}, {cmd:m}, or {cmd:s} with option {cmd:ivar()} or {cmd:absorb()}{p_end}
{pstd}§ only after {cmd:robreg m}, {cmd:s}, or {cmd:mm}{p_end}
{pstd}# only after {cmd:robreg lts}, {cmd:lqs}, or {cmd:lms}{p_end}
{pstd}+ only after {cmd:robreg ls}, {cmd:q}, {cmd:m}, {cmd:s}, or {cmd:mm}{p_end}


{marker description}{...}
{title:Description}

{pstd}
    {cmd:robreg} provides a number of robust estimators for linear
    regression models (see, e.g., Maronna et al. 2006 for an overview of robust
    regression estimators).

{pstd}
    {cmd:robreg ls} fits classical (non-robust) least-squared models. Results
    are equivalent to results from official {helpb regress} (with robust
    standard errors).

{pstd}
    {cmd:robreg q} fits quantile regression models (median or LAD regression by default)
    using the interior point algorithm (Portnoy and Koenker 1997). {cmd:robreg q} is similar
    to official {helpb qreg}.

{pstd}
    {cmd:robreg m} fits M regression models (Huber 1973) using
    iteratively reweighted least squares (IRLS).

{pstd}
    {cmd:robreg s} fits high breakdown S regression models (Rousseeuw and Yohai
    1984) based on random subsampling with local refinement
    (Salibian-Barrera and Yohai 2006; employing fast nonsingular subsampling as
    suggested by Koller 2012).

{pstd}
    {cmd:robreg mm} fits MM regression models (Yohai 1987), combining an initial
    high breakdown S estimator with a subsequent redescending M estimator.

{pstd}
    {cmd:robreg lts} fits least trimmed squares (LTS) regression models
    based on random subsampling with local concentration steps
    (Rousseeuw and van Driessen 2002). Influence-function based variance
    estimation is not supported by {cmd:robreg lts}.

{pstd}
    {cmd:robreg lqs} and {cmd:robreg lms} fit least quantile of squares (LQS) and
    least median of squares (LMS) regression models, respectively,
    based on random subsampling (see Rousseeuw 1984,
    Rousseeuw and Leroy 1987, Rousseeuw and Hubert 1997). Influence-function based variance
    estimation is not supported by {cmd:robreg lqs} and {cmd:robreg lms}.

{pstd}
    {cmd:robreg hausman} can be used after {cmd:robreg ls}, {cmd:robreg q},
    {cmd:robreg m}, {cmd:robreg s}, and {cmd:robreg mm} to perform
    Hausman tests between models.

{pstd}
    {cmd:robreg} requires {cmd:moremata}. See
    {net "describe moremata, from(http://fmwww.bc.edu/repec/bocode/m/)":ssc describe moremata}.


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
    {cmd:noconstant} suppresses the constant term (intercept) in the model. With
    robust estimators, omitting the constant typically only makes sense if the specified
    model is equivalent to a model including an intercept, for example, if the model contains
    a factor variable without base level (see operator {cmd:ibn.} in help
    {helpb fvvarlist}).

{pmore}
    Note that {cmd:robreg} always computes the R-squared with respect to a
    constant-only model, even if option {cmd:noconstant} has been specified
    (similar to {helpb regress} with option {cmd:tsscons}).

{phang}
    {cmd:nor2} skips the computation of the (pseudo) R-squared. Use this option to
    save computer time.

{marker ls_options}{...}
{dlgtab:Additional options for robreg ls}

{phang}
    {it:fe_options} are options to include fixed-effects in the model; see
    {help robreg##fe_options:Fixed effects options} below.

{marker q_options}{...}
{dlgtab:Additional options for robreg q}

{phang}
    {opt quantile(#)} specifies the quantile to be estimated, with # as a proportion
    between 0 and 1 (exclusive) (numbers between 1 and 100 will be interpreted as
    percentages). The default is {cmd:quantile(0.5)} (LAD or median regression).

{phang}
    {opt fitted} computes the sparsity function (which is needed for variance
    estimation) based on fitted values from auxiliary quantile regressions
    (approach suggested by Hendricks and Koenker 1992). The default is to
    compute the sparsity function based on nonparametric kernel density
    estimation (using a gaussian kernel) (approach suggested by Powell 1991). Also
    see Section 3.4.2 in Koenker (2005).

{phang}
    {opt bofinger} uses Bofinger's bandwidth for the estimation of the
    sparsity function. The default is to use the Hall-Sheather bandwidth. See
    Section 4.10.1 in Koenker (2005) for details. Note that the Hall-Sheather
    bandwidth depends on the confidence level set by the {cmd:level()} option. For
    the kernel-based approach (i.e. if {cmd:fitted} is not specified), the bandwidth
    is further transformed as suggested by Koenker (2005, page 81).

{phang}
    {opt init(matname)} provides a matrix containing custom starting values.
    Coefficients will be matched by name (starting values for coefficients
    without match will be set to zero). If {it:matname} has multiple rows, the first row
    will be used. The default is to obtain the starting values from a
    least-squares fit. The choice of starting values should only affects the
    number of iterations, but not the resulting estimates.

{marker m_options}{...}
{dlgtab:Additional options for robreg m}

{phang}
    {opt huber} uses the Huber objective function (monotone M estimator). This
    is the default.

{phang}
    {opt biweight} uses the biweight objective function
    (redescending M estimator). {cmd:bisquare} is a synonym for
    {cmd:biweight}. The solution of a redescending M estimator may depend on
    the starting values.

{phang}
    {opt efficiency(#)} sets the gaussian efficiency (the asymptotic
    relative efficiency compared to the LS or ML estimator in case of
    i.i.d. normal errors), in percent. {it:#} must be between 63.7 and 99.9 for {cmd:huber}
    and between 1 and 99.9 for {cmd:biweight}. The default is {cmd:efficiency(95)}.

{phang}
    {opt k(#)} specifies a custom tuning constant. The default is to use a
    tuning constant that is consistent with the requested gaussian
    efficiency. {cmd:k()} and {cmd:efficiency()} are not both allowed.

{phang}
    {it:fe_options} are options to include fixed-effects in the model; see
    {help robreg##fe_options:Fixed effects options} below.

{phang}
    {opt scale(#)} provides a custom (starting) value for the residual
    scale. The default is to use the MADN (normalized median absolute deviation)
    from the initial fit.

{phang}
    {opt updatescale} updates the scale in each iteration of the
    IRLS algorithm. The default is to hold the scale fixed.

{phang}
    {opt center} uses median-centered residuals to compute the MADN. The default
    is to use raw residuals.

{marker m_init}{...}
{phang}
    {opt init(arg)} determines the starting values of the IRLS algorithm. {it:arg}
    may be {cmd:lad} (median regression; the default) or {cmd:ls} (least-squares
    regression). Furthermore, {opt init(matname)} may be specified, in which case
    the starting values will be taken from the first row of matrix {it:matname}
    (coefficients will be matched by name; starting values for coefficients
    without match will be set to zero).

{pmore}
    If option {cmd:ivar()} or {cmd:absorb()} is specified, the fixed-effects
    (quasi) quantile estimator implemented in {helpb mf_mm_aqreg:mm_aqreg()} is used to
    determine the {cmd:lad} starting values. Furthermore, {opt init(matname)}
    is not allowed with {cmd:ivar()} or {cmd:absorb()}.

{marker s_options}{...}
{dlgtab:Additional options for robreg s}

{phang}
    {opt bp(#)} sets the breakdown point, in percent, with {it:#}
    between 1 and 50. The default is {cmd:bp(50)}.

{phang}
    {opt k(#)} specifies a custom tuning constant. The default is to use a
    tuning constant that is consistent with the requested breakdown
    point. {cmd:k()} and {cmd:bp()} are not both allowed.

{phang}
    {opt nohausman} suppresses the Hausman test of the S estimate against
    the least-squares fit.

{marker s_mopt}{...}
{phang}
    {cmd:m(}{it:varlist} [{cmd:,} {it:options}]{cmd:)} identifies outlier-free variables to be
    partialled out when searching for candidate estimates in the subsampling
    algorithm. The specified variables must be a subset from {it:indepvars}. If option {cmd:m()}
    is provided, the dependent variable and the remaining independent variables
    are residualized by regressing them on {it:varlist} using a Huber M
    estimator. In each replication, the subsampling algorithm then obtains a
    non-singular candidate fit from the residualized data. The candidate fit
    will be augmented by the coefficients of the M estimate of the dependent
    variable on {it:varlist} and then refined in the usual way based on the
    original data. Specifying {cmd:m()} can lead to significant improvements in
    computational speed and can also have beneficial effects on the stability
    of the results, but the variables included in {cmd:m()} must be known to be
    free of outliers (e.g. categorical variables). {it:options} are
    {cmd:efficiency()} or {cmd:k()} to set the tuning constant of the Huber M
    estimator (see {help robreg##m_options:{it:m_options}} above); default is
    {cmd:efficiency(95)}. The procedure invoked by the {cmd:m()} option is similar
    to the M-S estimator proposed by Maronna and Yohai (2000), but it results in
    a true S estimator (in contrast to the M-S estimator, the M part is only used
    to generate suitable candidate estimates without falling into the
    collinearity trap; the candidates are then optimized in the same way as without
    {cmd:m()} option).

{phang}
    {it:fe_options} are options to include fixed-effects in the model; see
    {help robreg##fe_options:Fixed effects options} below.

{marker s_nsamp}{...}
{phang}
    {opt nsamp(args)} determines the number of trial samples for the search
    algorithm. Specify {opt nsamp(#)} to use {it:#} trial samples. Alternatively,
    specify {cmd:nsamp(}{it:alpha} [{it:epsilon}]{cmd:)} to determine the
    number of trial samples as

            ceil(ln({it:alpha}) / ln(1 - (1 - {it:epsilon})^{it:k}))

{pmore}
    with a minimum of 20 and a maximum of 1000, where {it:k} is the
    number of predictors included in the subsampling algorithm. {it:alpha} is
    the maximum admissible risk of drawing a set of samples of which none is
    free of outliers; {it:epsilon} is the assumed maximum fraction of
    contaminated data. The default is to determine the number of subsamples
    according to the above formula with {it:alpha} = 0.01 and
    {it:epsilon} = 0.2.

{phang}
    {opt rsteps(#)} specifies the number of local improvement (refinement) steps
    applied to the trial candidates. The default is {cmd:rsteps(2)}.

{phang}
    {opt nkeep(#)} specifies the number of best candidates to be
    kept for final refinement. The default is {cmd:nkeep(5)}.

{phang}
    {opt naive} uses a naive subsampling algorithm. In each replication, the
    algorithm keeps on drawing random p-subsets until a non-singular subset is found
    (the algorithm aborts with error after 10'000 unsuccessful attempts). The
    default is to use the fast nonsingular subsampling algorithm suggested
    by Koller (2012) that creates a non-singular random p-subset by adding suitable
    observations one-by-one, until the desired subset size is reached.

{phang}
    {opt alt} uses an alternative nonsingular subsampling algorithm that
    expands the size of the random subset, instead of exchanging observations,
    until it becomes nonsingular. The alternative algorithm is typically
    somewhat faster than the default algorithm, but it may be less robust.

{phang}
    {opt nostd} omits standardization of the data for the subsampling
    algorithm. To avoid precision problems, the default is to apply the subsampling
    algorithm to data that has been standardized by deducting medians and
    dividing by MADNs (or only by dividing by MADNs if {cmd:noconstant}
    has been specified). Specifying {cmd:nostd} is not recommended.

{marker mm_options}{...}
{dlgtab:Additional options for robreg mm}

{phang}
    {opt efficiency(#)} sets the gaussian efficiency of the bisquare M
    estimator, in percent. {it:#} must be between between 1 and 99.9. The
    default is {cmd:efficiency(85)}.

{phang}
    {opt k(#)} specifies a custom tuning constant for the bisquare M
    estimator. The default is to use a tuning constant that is consistent with the
    requested gaussian efficiency. {cmd:k()} and {cmd:efficiency()} are not
    both allowed.

{phang}
    {opt nohausman} suppresses the Hausman test of the MM estimate against
    the S estimate.

{phang}
    {opt bp(#)} sets the breakdown point of the preliminary S estimator,
    in percent. {it:#} must be between 1 and 50. The default is {cmd:bp(50)}.

{phang}
    {opt sopts(options)} are (other) options to be passed through to the preliminary
    S estimator. {it:options} include all options listed above under
    {help robreg##s_options:Additional options for robreg s} (except {cmd:nohausman})
    as well as the options listed below under
    {help robreg##optimoptions:Optimization} (the default is to use the same
    optimization settings as for the bisquare M estimator, i.e., the settings
    specified outside {cmd:sopts()}; optimization option specified within
    {cmd:sopts()} will override these settings).

{marker lts_options}{...}
{dlgtab:Additional options for robreg lts}

{phang}
    {opt bp(#)} sets the breakdown point, in percent, with {it:#}
    between 1 and 50. The default is {cmd:bp(50)}. {cmd:bp()}
    determines the relative size of the H-subset with

            {it:h} = (floor((1-#/100)*{it:N}) + floor(#/100*({it:K} + 1))) / {it:N}

{pmore}
    where {it:N} is the sample size and {it:K} is the number of (non-omitted)
    coefficients in the model.

{phang}
    {opt nsamp(args)} determines the number of trial samples for the search
    algorithm. Specify {opt nsamp(#)} to use {it:#} trial samples. Alternatively,
    specify {cmd:nsamp(}{it:alpha} [{it:epsilon}]{cmd:)} to determine the
    number of trial samples as explained {help robreg##s_nsamp:above}
    (with a minimum of 50 and a maximum of 10'000).

{phang}
    {opt csteps(#)} specifies the number of concentration steps
    applied to the trial candidates. The default is {cmd:rsteps(2)}.

{phang}
    {opt nkeep(#)} specifies the number of best candidates to be
    kept for final refinement. The default is {cmd:nkeep(10)}.

{phang}
    {opt naive}, {opt alt}, and {opt nostd} are described above under
    {help robreg##s_options:Additional options for robreg s}.

{marker lqs_options}{...}
{dlgtab:Additional options for robreg lqs/lms}

{phang}
    {opt bp(#)} sets the breakdown point, in percent, with {it:#}
    between 1 and 50 (only allowed with {cmd:robreg lqs}). The default is
    {cmd:bp(50)}. {cmd:bp()} determines the relative size of the H-subset
    (see {help robreg##lts_options:above}; for {cmd:robreg lms}, {it:h} is fixed at
    0.5).

{phang}
    {opt nsamp(args)} determines the number of trial samples for the search
    algorithm. Specify {opt nsamp(#)} to use {it:#} trial samples. Alternatively,
    specify {cmd:nsamp(}{it:alpha} [{it:epsilon}]{cmd:)} to determine the
    number of trial samples as explained {help robreg##s_nsamp:above}
    (with a minimum of 500 and a maximum of 10'000).

{phang}
    {opt naive}, {opt alt}, and {opt nostd} are described above under
    {help robreg##s_options:Additional options for robreg s}.

{dlgtab:VCE/SE}

{marker vcetype}{...}
{phang}
    {opt vce(vcetype)} determines how standard errors are computed. {it:vcetype} may be:

            {opt r:obust}
            {opt cl:uster} {it:clustvar}
            {opt boot:strap} [{cmd:,} {help bootstrap:{it:bootstrap_options}} ]
            {opt jack:knife} [{cmd:,} {help jackknife:{it:jackknife_options}} ]

{pmore}
    {cmd:vce(robust)}, the default, computes heteroscedasticity-robust standard
    errors based on influence functions (equivalent to the approach proposed by
    Croux et al. 2003). Likewise, {bind:{cmd:vce(cluster} {it:clustvar}{cmd:)}}
    computes standard errors based on influence function allowing for intragroup
    correlation, where {it:clustvar} specifies to which group each observation
    belongs. {cmd:vce(bootstrap)} and {cmd:vce(jackknife)} compute standard errors
    using {helpb bootstrap} or {helpb jackknife}, respectively; see help
    {it:{help vce_option}}. {cmd:vce(robust)} and {cmd:vce(cluster)} are not
    supported by {cmd:robreg lts}, {cmd:robreg lqs}, and {cmd:robreg lms}.

{phang}
    {opt cluster(clustvar)} can be used as a synonym for {cmd:vce(cluster} {it:clustvar}{cmd:)}.

{phang}
    {opt ftest} requests that the overall model test and the Hausman test (in case of
    {cmd:robreg s} and {cmd:robreg mm}) be reported as F tests rather than
    Wald chi-squared tests. The residual degrees of freedom for the F test will be determined
    as the number of observations minus the number of (non-omitted) parameters
    in the (main equation of the) model (or in case of clustered standard
    errors, as the number of clusters minus one). The same residual degrees of freedom are
    used for the t tests of the individual coefficients.

{phang}
    {cmd:nose} omits the computation of standard errors. Use this option to
    save computer time.

{marker repoptions}{...}
{dlgtab:Reporting}

{phang}
    {opt level(#)} specifies the confidence level, as a percentage, for
    confidence intervals. The default is {cmd:level(95)} or as set by
    {helpb set level}.

{phang}
    {opt noheader} suppresses the display of the table header.

{phang}
    {opt notable} suppresses the display of the table of results.

{phang}
    {opt all} reports results from all equations in case of {cmd:robreg s} and
    {cmd:robreg mm}. The default is to display only the main equation.

{marker displayopts}{...}
{phang}
    {it:display_options} are standard reporting options such as {cmd:eform},
    {cmd:cformat()}, or {cmd:coeflegend}; see {help eform_option:{bf:[R]} {it:eform_option}} and
    the Reporting options in {helpb estimation options:[R] Estimation options}.

{marker optimoptions}{...}
{dlgtab:Optimization}

{phang}
    {opt tolerance(#)} specifies the convergence tolerance for iterative
    estimation procedures. When the maximum relative difference in coefficients
    from one iteration to the next is less than or equal to the specified tolerance,
    the convergence criterion is satisfied. The default is {cmd:tolerance(1e-10)}.

{pmore}
    An exception is {cmd:robreg q}, for which convergence is evaluated based on
    the duality gap (convergence is reached if the duality gap is smaller than
    the specified tolerance). The default for {cmd:robreg q} is {cmd:tolerance(1e-8)}.

{phang}
    {opt iterate(#)} specifies the maximum number of iterations. Error will be returned
    if convergence is not reached within the specified maximum number of iterations. The default is as set by
    {helpb set maxiter}.

{phang}
    {opt relax} causes {cmd:robreg} to proceed even if convergence is not reached.

{phang}
    {opt noquad} requests that double precision be used rather than quad precision
    when taking cross products in weighted least-squares fits. Specifying
    {cmd:noquad} will speed up computations for most estimators, but has the risk
    of precision loss if the data is not well behaved (unreasonable means,
    high collinearity). Note that {cmd:noquad} has no effect on computations
    performed within the subsampling algorithm employed by {cmd:robreg s} and
    {cmd:robreg lts/lqs/lts} (the subsampling algorithm does not use
    quad precision because it operates on standardized data; also
    see the {cmd:nostd} option {help robreg##s_options:above}).

{phang}
    {opt nolog} suppresses the display of progress information.

{marker fe_options}{...}
{dlgtab:Fixed effects options}

{phang}
    {opt ivar(varname)} specifies a variable identifying groups for which
    fixed effects are to be included in the model. Use 
    {cmd:ivar()} in cases in which the number of groups increases with the
    sample size (e.g. panel data). {cmd:ivar()} mimics
    the behavior of {helpb xtreg:xtreg,fe} with option {cmd:robust}, that is, it
    implies clustering on the group variable when computing standard errors (unless
    an alternative clustering variable is specified in {cmd:vce()} or
    {cmd:cluster()}; in any case, groups must be nested within clusters).

{phang}
    {opt absorb(varname)} is an alternative to {opt ivar()} that mimics the
    behavior of {helpb areg} (no clustering implied; groups not required 
    to be nested within clusters; somewhat different computation of 
    degrees of freedom). Use {cmd:absorb()} in cases in which the number
    of groups does not increase with the sample size. 

{phang}
    [{cmd:no}]{opt usave} decides whether a fixed-effects lookup table is stored
    in matrix {cmd:e(u)}. For {cmd:robreg ls} the default is 
    {cmd:nousave}, as the fixed effects can be recovered after model
    estimation. For all other models supporting {cmd:ivar()} or 
    {cmd:absorb()}, the default is {cmd:usave}. Typing {cmd:nousave} for these
    models implies that {it:{help robreg##propts:predict_options}} options
    involving fixed effects will not be available after model estimation.

{phang}
    {opt ugenerate(newvar)} stores the fixed effects as a variable in the data,
    rather than storing a lookup table in {cmd:e(u)}. {cmd:ugenerate()} takes precedence
    over {cmd:usave}.

{phang}
    {opt replace} allows overwriting an existing variable.

{marker mm_refit_options}{...}
{dlgtab:Refitting options for robreg mm}

{phang}
    {opt efficiency(#)} sets the gaussian efficiency of the bisquare M
    estimator, in percent. {it:#} must be between between 1 and 99.9. The
    default is {cmd:efficiency(85)}.

{phang}
    {opt k(#)} specifies a custom tuning constant for the bisquare M
    estimator. The default is to use a tuning constant that is consistent with the
    requested gaussian efficiency. {cmd:k()} and {cmd:efficiency()} are not
    both allowed.

{phang}
    {opt nohausman} suppresses the Hausman test of the MM estimate against
    the S estimate.

{phang}
    {opt ftest} requests that the overall model test and the Hausman test
    be reported as F tests rather than
    Wald chi-squared tests.

{phang}
    {it:reporting_options} are reporting options as described {help robreg##repoptions:above}.

{phang}
    {it:optimization_options} are optimization options as described {help robreg##optimoptions:above}.

{marker hausman_options}{...}
{dlgtab:Options for robreg hausman}

{phang}
    {opt constant} includes the constant in the test. The default is to exclude the constant.

{phang}
    {opt common} restricts the test to coefficients that exist in both models. The
    default is to use all (first-equation) coefficients from both models and
    treat coefficients that only exist in one model as constrained to zero in
    the other model.

{phang}
    {opt keep(names)} provides a space-separated list of coefficients to be included
    in the test. Wildcard characters {cmd:*} and {cmd:?} can be used in the names to
    match multiple coefficients. The constant is handled by the {cmd:constant} option,
    independently of {cmd:keep()}.

{phang}
    {opt keep(names)} provides a space-separated list of coefficients to be excluded
    from the test. Wildcard characters {cmd:*} and {cmd:?} can be used in the names to
    match multiple coefficients. The constant is handled by the {cmd:constant} option,
    independently of {cmd:drop()}.

{phang}
    {opt ftest} requests that the overall test be reported as an F test rather
    than a Wald chi-squared test. The residual degrees of freedom for the F
    test will be determined as the number of observations (in the joint sample
    across both models) minus the number of (non-omitted) parameters in the
    (main equation of the) larger model (or in case of clustered standard
    errors, as the number of clusters in the joint sample minus one). The same
    residual degrees of freedom are also used for the t tests of the differences
    between coefficients

{phang}
    {opt level(#)} specifies the confidence level, as a percentage, for the
    confidence intervals of the differences between coefficients. The default is
    {cmd:level(95)} or as set by {helpb set level}.

{phang}
    {opt noheader} suppresses the display of the header that contains the
    overall test.

{phang}
    {opt notable} suppresses the display of the table that contains the t-tests
    for the differences between individual coefficients.

{phang}
    {it:display_options} are standard reporting options such as {cmd:eform},
    {cmd:cformat()}, or {cmd:coeflegend}; see {help eform_option:{bf:[R]} {it:eform_option}} and
    the Reporting options in {helpb estimation options:[R] Estimation options}.

{phang}
    {opt post} stored the results in {cmd:e()}. The default is to store the results
    in {cmd:r()}.

{marker predict_options}{...}
{dlgtab:Options for predict}

{phang}
    {opt xb} calculates linear predictions.

{phang}
    {opt xbu} calculates linear predictions plus fixed effects. {cmd:xbu} is only
    allowed after option {cmd:ivar()} or {cmd:absorb()} has been applied.

{phang}
    {opt u} calculates fixed effects. {cmd:u} is only
    allowed after option {cmd:ivar()} or {cmd:absorb()} has been applied.

{phang}
    {opt ue} calculates fixed effects plus residuals. {cmd:ue} is only
    allowed after option {cmd:ivar()} or {cmd:absorb()} has been applied.

{phang}
    {opt residuals} calculates residuals.

{phang}
    {opt rstandard} calculates standardized residuals (residuals divided by {cmd:e(scale)}).

{phang}
    {opt outlier}[{cmd:(}{it:#}{cmd:)}] generates a 0/1 variable identifying
    outliers (1 = outlier, 0 = inlier). Optional argument {it:#} in [0,100] specifies the
    percentage of observations to be classified as outliers in normal data. That is,
    observations with absolute standardized residuals larger than
    invnormal(1 - #/200) will be classified as outliers. The default is {it:#} = 2.5.

{phang}
    {opt inlier}[{cmd:(}{it:#}{cmd:)}] generates a 0/1 variable identifying
    inliers (1 = inlier, 0 = outlier). Optional argument {it:#} in [0,100] specifies the
    percentage of observations to be classified as inliers in normal data. That is,
    observations with absolute standardized residuals smaller than or equal to
    invnormal(.5 + #/200) will be classified as inliers. The default is {it:#} = 97.5.

{phang}
    {opt weights} generates a variable containing weights corresponding to the final
    RLS fit. {cmd:weights} is only allowed after {cmd:robreg m}, {cmd:robreg s},
    and {cmd:robreg mm}.

{phang}
    {opt subset} generates a 0/1 variable identifying the H-subset. The variable
    will be 1 for observations with squared residuals smaller than or equal to the
    {cmd:e(h)} quantile of the squared residuals and 0 else. {cmd:subset} is only allowed after
    {cmd:robreg lts}, {cmd:robreg lqs}, and {cmd:robreg lms}.

{phang}
    {opt scores} calculates equation-level scores. The scores can be used
    together with the information stored in {cmd:e(V_modelbased)} to compute
    the influence functions. {cmd:scores} is not allowed after
    {cmd:robreg lts}, {cmd:robreg lqs}, or {cmd:robreg lts}. The scores
    generated after {cmd:robreg ls} deviate from the scores obtained by
    {cmd:predict} after {helpb regress} by factor 1/{cmd:e(scale)}^2.

{phang}
    {opt ifs} calculates coefficient-level influence functions. The
    influence functions are defined in a way such that their total is
    zero and the standard error of the total (as computed by command {helpb total})
    provides an estimate of the standard error of the coefficient. {cmd:ifs} is
    not allowed after {cmd:robreg lts}, {cmd:robreg lqs}, or {cmd:robreg lms}.

{phang}
    {opt rifs} calculates recentered influence functions. The
    recentered influence functions are defined in a way such that their mean is
    equal to the relevant coefficient and the standard error of the mean
    (as computed by command {helpb mean}) provides an estimate of the standard
    error of the coefficient. {cmd:rifs} is not allowed after
    {cmd:robreg lts}, {cmd:robreg lqs}, or {cmd:robreg lms}.


{marker examples}{...}
{title:Examples}

{pstd}
    Comparison of different estimators of the same model:

        . {stata sysuse auto, clear}
        . {stata robreg ls price mpg weight headroom foreign}
        . {stata robreg q price mpg weight headroom foreign}
        . {stata robreg m price mpg weight headroom foreign}
        . {stata robreg s price mpg weight headroom foreign}
        . {stata robreg mm price mpg weight headroom foreign}

{pstd}
    We see, for example, that the effect of {cmd:headroom} has a p-value of 0.03
    in the least-squares model, but is not significant in any of the robust
    estimators. Furthermore, the Hausman test of S against LS indicates that
    there are relevant outliers.

{pstd}
    Refitting MM with different efficiencies (without re-estimating the S):

        . {stata sysuse auto, clear}
        . {stata robreg s price mpg weight headroom foreign}
        . {stata robreg mm, efficiency(75)}
        . {stata robreg mm, efficiency(80)}
        . {stata robreg mm, efficiency(85)}
        . {stata robreg mm, efficiency(90)}
        . {stata robreg mm, efficiency(95)}

{pstd}
    Performing Hausman tests between models: The following example illustrates
    how one could do an interquantile range regression using {cmd:robreg q} followed
    by {cmd:robreg hausman}.

        . {stata sysuse auto, clear}
        . {stata robreg q price mpg weight headroom foreign, quantile(0.25)}
        . {stata estimates store q25}
        . {stata robreg q price mpg weight headroom foreign, quantile(0.75)}
        . {stata estimates store q75}
        . {stata robreg hausman q75 q25, constant}

{pstd}
    Using {cmd:predict} to flag outliers:

        . {stata sysuse auto, clear}
        . {stata robreg mm price mpg weight headroom foreign}
        . {stata predict outlier, outlier}
        . {stata two scatter price weight if outlier==0 || scatter price weight if outlier==1}

{pstd}
    Using {cmd:predict} to generate recentered influence functions (the difference
    in standard errors is because {cmd:robreg} divides by the residual degrees of freedom while
    {cmd:mean} divides by N-1):

        . {stata sysuse auto, clear}
        . {stata robreg q price mpg weight headroom foreign}
        . {stata predict RIF*, rifs}
        . {stata mean RIF*}


{marker results}{...}
{title:Stored results}

{pstd}
    Depending on estimator and options, {cmd:robreg} saves a selection of the following
    results in {cmd:e()}.

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(N_clust)}}number of clusters (if {cmd:vce(cluster)}){p_end}
{synopt:{cmd:e(k_eq)}}number of equations in {cmd:e(b)}{p_end}
{synopt:{cmd:e(k_eform)}}number of equations to be affected by {cmd:eform} option{p_end}
{synopt:{cmd:e(k_omit)}}number of omitted coefficients in {cmd:e(b)}{p_end}
{synopt:{cmd:e(scale)}}estimate of residual scale{p_end}
{synopt:{cmd:e(scale0)}}residual scale of empty model (unless {cmd:nor2}){p_end}
{synopt:{cmd:e(s0)}}raw scale ({cmd:robreg lts/lqs/lms}){p_end}
{synopt:{cmd:e(s0_0)}}raw scale of empty model ({cmd:robreg lts/lqs/lms}, unless {cmd:nor2}){p_end}
{synopt:{cmd:e(r2)}}R-squared ({cmd:robreg ls}){p_end}
{synopt:{cmd:e(r2_p)}}pseudo R-squared (all but {cmd:robreg ls}){p_end}
{synopt:{cmd:e(r2_w)}}R-squared from final WLS fit ({cmd:robreg m/s/mm}){p_end}
{synopt:{cmd:e(k)}}tuning constant ({cmd:robreg m/s/mm}){p_end}
{synopt:{cmd:e(m_k)}}tuning constant of residualizing M ({cmd:robreg s/mm}, if {cmd:m()}){p_end}
{synopt:{cmd:e(kS)}}tuning constant of S estimate ({cmd:robreg mm}){p_end}
{synopt:{cmd:e(bp)}}breakdown point ({cmd:robreg s/mm/lts/lqs}){p_end}
{synopt:{cmd:e(efficiency)}}gaussian efficiency ({cmd:robreg m/s/mm}){p_end}
{synopt:{cmd:e(m_efficiency)}}gaussian efficiency of residualizing M ({cmd:robreg s/mm}, if {cmd:m()}){p_end}
{synopt:{cmd:e(effS)}}gaussian efficiency of S estimate ({cmd:robreg mm}){p_end}
{synopt:{cmd:e(delta)}}consistency parameter for scale estimation ({cmd:robreg s/mm}){p_end}
{synopt:{cmd:e(h)}}relative size of H-subset ({cmd:robreg lts/lqs/lms}){p_end}
{synopt:{cmd:e(q_h)}}h-quantile of squared residuals ({cmd:robreg lts/lqs/lms}){p_end}
{synopt:{cmd:e(crit)}}value of optimization criterion ({cmd:robreg lts/lqs/lms}){p_end}
{synopt:{cmd:e(nsamp)}}number of subsamples ({cmd:robreg s/mm/lts/lqs/lms}){p_end}
{synopt:{cmd:e(rsteps)}}number of refinement steps ({cmd:robreg s/mm}){p_end}
{synopt:{cmd:e(csteps)}}number of concentration steps ({cmd:robreg lts}){p_end}
{synopt:{cmd:e(nkeep)}}number of candidates kept for final refinement ({cmd:robreg s/mm/lts}){p_end}
{synopt:{cmd:e(sum_adev)}}sum of absolute deviations ({cmd:robreg q}){p_end}
{synopt:{cmd:e(sum_rdev)}}sum of absolute deviations of empty model ({cmd:robreg q}, unless {cmd:nor2}){p_end}
{synopt:{cmd:e(q)}}quantile requested ({cmd:robreg q}){p_end}
{synopt:{cmd:e(bwidth)}}bandwidth ({cmd:robreg q}){p_end}
{synopt:{cmd:e(kbwidth)}}kernel bandwidth ({cmd:robreg q}, unless {cmd:fitted}){p_end}
{synopt:{cmd:e(iterations)}}number of iterations ({cmd:robreg q/m/mm}){p_end}
{synopt:{cmd:e(converged)}}1 if converged, 0 else ({cmd:robreg q/m/mm}){p_end}
{synopt:{cmd:e(hausman_chi2)}}chi-squared statistic of Hausman test ({cmd:robreg s/mm}){p_end}
{synopt:{cmd:e(hausman_F)}}F statistic of Hausman test ({cmd:robreg s/mm}, if {cmd:ftest}){p_end}
{synopt:{cmd:e(hausman_p)}}p value of Hausman test ({cmd:robreg s/mm}){p_end}
{synopt:{cmd:e(N_g)}}number of groups (if relevant){p_end}
{synopt:{cmd:e(g_avg)}}average group size (if relevant){p_end}
{synopt:{cmd:e(g_min)}}minimum group size (if relevant){p_end}
{synopt:{cmd:e(g_max)}}maximum group size (if relevant){p_end}
{synopt:{cmd:e(corr)}}correlation between fixed effects and Xb (if relevant){p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom{p_end}
{synopt:{cmd:e(df_r)}}residual degrees of freedom{p_end}
{synopt:{cmd:e(chi2)}}chi-squared statistic of model test (unless {cmd:nose}){p_end}
{synopt:{cmd:e(F)}}F statistic of model test (if {cmd:ftest}, unless {cmd:nose}){p_end}
{synopt:{cmd:e(p)}}p value of model test (unless {cmd:nose}){p_end}
{synopt:{cmd:e(rank)}}rank of {cmd:e(V)} (unless {cmd:nose}){p_end}
{synopt:{cmd:e(level)}}confidence level (unless {cmd:nose}){p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:robreg}{p_end}
{synopt:{cmd:e(subcmd)}}{cmd:ls}, {cmd:q}, {cmd:m}, {cmd:s}, {cmd:mm}, {cmd:lts}, {cmd:lqs}, or {cmd:lms}{p_end}
{synopt:{cmd:e(predict)}}{cmd:robreg predict}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(indepvars)}}names of independent variables{p_end}
{synopt:{cmd:e(m)}}variable names from {cmd:m()} option{p_end}
{synopt:{cmd:e(noconstant)}}{cmd:noconstant} or empty{p_end}
{synopt:{cmd:e(ivar)}}variable name from {cmd:ivar()} or empty{p_end}
{synopt:{cmd:e(absorb)}}variable name from {cmd:absorb()} or empty{p_end}
{synopt:{cmd:e(ugenerate)}}variable name from {cmd:ugenerate()} or empty{p_end}
{synopt:{cmd:e(nor2)}}{cmd:nor2} or empty{p_end}
{synopt:{cmd:e(noquad)}}{cmd:noquad} or empty{p_end}
{synopt:{cmd:e(denmethod)}}{cmd:kernel} or {cmd:fitted} ({cmd:robreg q}){p_end}
{synopt:{cmd:e(denmethod)}}{cmd:gaussian} ({cmd:robreg q}){p_end}
{synopt:{cmd:e(bofinger)}}{cmd:bofinger} or empty ({cmd:robreg q}){p_end}
{synopt:{cmd:e(vce)}}{it:vcetype} specified in {cmd:vce()}{p_end}
{synopt:{cmd:e(vcetype)}}title used to label Std. Err.{p_end}
{synopt:{cmd:e(clustvar)}}name of cluster variable{p_end}
{synopt:{cmd:e(wtype)}}weight type{p_end}
{synopt:{cmd:e(wexp)}}weight expression{p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(properties)}}{cmd:b} or {cmd:b V}{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}estimates{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of estimates (unless {cmd:nose}){p_end}
{synopt:{cmd:e(omit)}}vector identifying omitted coefficients{p_end}
{synopt:{cmd:e(V_modelbased)}}inverse of moment condition derivative matrix (unless {cmd:nose}){p_end}
{synopt:{cmd:e(u)}}fixed-effects lookup table (if appropriate){p_end}
{synopt:{cmd:e(b0)}}empty model fit (unless {cmd:nor2}){p_end}
{synopt:{cmd:e(b_init)}}starting values ({cmd:robreg q/m}){p_end}
{synopt:{cmd:e(b_lo)}}lower auxiliary fit ({cmd:robreg q}, if {cmd:fitted}){p_end}
{synopt:{cmd:e(b_up)}}upper auxiliary fit ({cmd:robreg q}, if {cmd:fitted}){p_end}
{synopt:{cmd:e(IFoffset)}}influence function offsets ({cmd:robreg q}){p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}estimation sample{p_end}
{p2colreset}{...}

{pstd}
    If {cmd:vce()} is {cmd:bootstrap} or {cmd:jackknife}, additional
    results are stored in {cmd:e()}; see {helpb bootstrap} and
    {helpb jackknife}, respectively.

{pstd}
    {cmd:robreg hausman} saves the following results in {cmd:r()}. If option
    {cmd:post} is specified, the results are moved to {cmd:e()}.

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(N_clust)}}number of clusters (if {cmd:vce(cluster)}){p_end}
{synopt:{cmd:r(df_m)}}test constraints degrees of freedom{p_end}
{synopt:{cmd:r(df_r)}}residual degrees of freedom{p_end}
{synopt:{cmd:r(chi2)}}chi-squared statistic of Hausman test{p_end}
{synopt:{cmd:r(F)}}F statistic of Hausman test (if {cmd:ftest}){p_end}
{synopt:{cmd:r(p)}}p value of Hausman test{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:robreg}{p_end}
{synopt:{cmd:r(subcmd)}}{cmd:hausman}{p_end}
{synopt:{cmd:r(wtype)}}weight type{p_end}
{synopt:{cmd:r(wexp)}}weight expression{p_end}
{synopt:{cmd:r(vce)}}{it:vcetype} specified in {cmd:vce()}{p_end}
{synopt:{cmd:r(vcetype)}}title used to label Std. Err.{p_end}
{synopt:{cmd:r(clustvar)}}name of cluster variable{p_end}
{synopt:{cmd:r(title)}}title in estimation output{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(b)}}coefficient differences{p_end}
{synopt:{cmd:r(V)}}variance-covariance matrix{p_end}


{marker refrerences}{...}
{title:References}

{phang}
    Croux, C., G. Dhaene, D. Hoorelbeke. 2003. Robust Standard Errors for
    Robust Estimators. Discussions Paper Series (DPS) 03.16. Center for
    Economic Studies.
    {p_end}
{phang}
    Hendricks, W., R. Koenker. 1992. Hierarchical Spline Models for Conditional
    Quantiles and the Demand for Electricity. Journal of the American Statistical
    Association 87:58-68.
    {p_end}
{phang}
    Huber, P.J. 1973. Robust Regression: Asymptotics, Conjectures and
    Monte Carlo. The Annals of Statistics 1:799-821.
    {p_end}
{phang}
    Koenker, R. 2005. Quantile Regression. Cambridge: Cambridge University Press.
    {p_end}
{phang}
    Koller, M. 2012. Nonsingular subsampling for S-estimators with categorical
    predictors. {browse "https://arxiv.org/abs/1208.5595":arXiv:1208.5595}.
    {p_end}
{phang}
    Maronna, R.A., V.J. Yohai. 2000. Robust regression with both
    continuous and categorical predictors. Journal of Statistical
    Planning and Inference 89:197-214.
    {p_end}
{phang}
    Maronna, R.A., D.R. Martin, V.J. Yohai. 2006. Robust Statistics. Theory
    and Methods. Chichester: Wiley.
    {p_end}
{phang}
    Portnoy, S., R. Koenker. 1997. The Gaussian hare and the Laplacian
    tortoise: computability of squared-error versus absolute-error
    estimators. Statistical Science 12:279-300.
    {p_end}
{phang}
    Powell, J.L. 1991. Estimation of monotonic regression models under quantile
    restrictions. Pp. 357-384 in: W.A. Barnett, J. Powell, G.E. Tauchen (eds.). Nonparametric and
    Semiparametric Methods in Econometrics and Statistics. Cambridge: Cambridge University Press.
    {p_end}
{phang}
    Salibian-Barrera, M., V.J. Yohai. 2006. A Fast Algorithm for
    S-Regression Estimates. Journal of Computational and Graphical
    Statistics 15:414-427.
    {p_end}
{phang}
    Rousseeuw, P.J. 1984. Least Median of Squares Regression. Journal of the
    American Statistical Association 79:871-880.
    {p_end}
{phang}
    Rousseeuw, P.J., M. Hubert. 1997. Recent developments in PROGRESS. Pp. 201-214
    in: Y. Dodge (ed.). L1-Statistical Procedures and Related Topics. Hayward, CA: Institute of
    Mathematical Statistics.
    {p_end}
{phang}
    Rousseeuw, P.J., A.M. Leroy. 1987. Robust Regression and Outlier
    Detection. New York: Wiley.
    {p_end}
{phang}
    Rousseeuw, P.J., K. van Driessen. 2002. Computing LTS regression for
    large data sets. Estadistica 54:163–190.
    {p_end}
{phang}
    Rousseeuw, P., V. Yohai. 1984. Robust Regression by Means of
    S-Estimators. Pp. 256-272 in: J. Franke, W. Hardle,
    D. Martin (eds.). Robust and Nonlinear Time Series Analysis.
    Lecture Notes in Statistics Vol. 26. Berlin: Springer.
    {p_end}
{phang}
    Yohai, V.J. 1987. High Breakdown-Point and High Efficiency Robust
    Estimates for Regression. The Annals of Statistics 15: 642-656.
    {p_end}


{marker author}{...}
{title:Author}

{pstd}
    Ben Jann, University of Bern, ben.jann@unibe.ch

{pstd}
    Thanks for citing this software as follows:

{pmore}
    Jann, B. (2021). robreg: Stata module providing robust regression
    estimators. Available from http://ideas.repec.org/c/boc/bocode/s458931.html.


{marker alsosee}{...}
{title:Also see}

{psee}
    Official Stata:
    {helpb regress},
    {helpb rreg},
    {helpb qreg}
    {p_end}
{psee}
    SSC Archive:{space 4}
    {helpb xtrobreg},
    {helpb robstat},
    {helpb dstat},
    {helpb robbox},
    {helpb robmv},
    {helpb moremata}
