{smcl}
{* 06jan2023}{...}
{hi:help riflogit}{...}
{right:{browse "http://github.com/benjann/riflogit/"}}
{hline}

{title:Title}

{pstd}{hi:riflogit} {hline 2} Unconditional logistic regression


{title:Syntax}

{p 8 15 2}
    {cmd:riflogit} {depvar} [{indepvars}] {ifin} {weight}
    [{cmd:,}
    {help riflogit##opt:{it:options}}
    ]

{p 8 15 2}
    {cmd:predict} {dtype} {newvar} {ifin}
    [{cmd:,}
    {it:{help riflogit##popt:predict_options}}
    ]


{synoptset 20 tabbed}{...}
{marker opt}{synopthdr:options}
{synoptline}
{syntab :Main}
{synopt :{opt nocons:tant}}suppress constant term
    {p_end}
{synopt :{opt h:ascons}}has user-supplied constant
    {p_end}

{syntab :SE/Robust}
{synopt :{cmd:vce(}{help riflogit##vcetype:{it:vcetype}}{cmd:)}}{it:vcetype} may be
    {cmd:ols}, {cmdab:r:obust}, {cmdab:cl:uster} {it:clustvar},
    {cmdab:boot:strap}, {cmdab:jack:knife}, {cmd:hc2}, or {cmd:hc3}
    {p_end}

{syntab :Reporting}
{synopt :{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}
    {p_end}
{synopt :{opt or}}report odds ratios
    {p_end}
{synopt :{opt nohead:er}}suppress table header
    {p_end}
{synopt :{opt notab:le}}suppress table of results
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
    {helpb svy} and {helpb mi} are allowed; see {help prefix}.
    {p_end}
{pstd}
    {cmd:pweight}s, {cmd:fweight}s, and {cmd:iweight}s are allowed; see help
    {help weight}.
    {p_end}


{synoptset 20}{...}
{marker popt}{synopthdr:predict_options}
{synoptline}
{syntab :Main}
{synopt :{space 2}{opt xb}}linear prediction; the default
    {p_end}
{synopt :{space 2}{opt stdp}}standard error of the linear prediction
    {p_end}
{synopt :{space 2}{opt r:esiduals}}residuals
    {p_end}
{synopt :{cmd:*} {opt rif}}recentered influence function
    {p_end}
{synopt :{space 2}{opt sc:ore}}score
    {p_end}

{syntab :Options}
{synopt :{space 2}{opt nolab:el}}do not label the newly created variable
    {p_end}
{synoptline}
{pstd}
    Unstarred statistics are available both in and out of sample.
    {p_end}


{title:Description}

{pstd}
    {cmd:riflogit} fits an unconditional logistic regression by applying
    least-squares estimation to the RIF (recentered influence function) of
    the marginal log odds of a positive outcome. {it:depvar} equal to nonzero
    and nonmissing (typically {it:depvar} equal to one) indicates a positive
    outcome, whereas {it:depvar} equal to zero indicates a negative outcome. The
    exponents of the coefficients have an (approximate) marginal odds ratio
    interpretation. See {browse "https://doi.org/10.3982/ECTA6822":Firpo et al. (2009)}
    for methodological background on RIF regression. For details on
    unconditional logistic regression and marginal odds ratios see
    {browse "https://ideas.repec.org/p/bss/wpaper/44.html":Jann and Karlson (2023)}.


{title:Options}

{phang}
    {cmd:noconstant} suppresses the constant term (intercept) in the model.

{phang}
    {cmd:hascons} indicates that a user-defined constant or its equivalent is
    specified among the independent variables in {indepvars}. See {helpb regress}
    for further explanations.

{marker vcetype}{...}
{phang}
    {cmd:vce(}{it:vcetype}{cmd:)} specifies the type of standard error reported,
    which includes types that are derived from asymptotic theory
    ({cmd:ols}), that are robust to some kinds of misspecification
    ({cmd:robust}), that allow for intragroup correlation ({cmd:cluster} {it:clustvar}),
    and that use bootstrap or jackknife methods ({cmd:bootstrap},
    {cmd:jackknife}); see {it:{help vce_option}}. Allowed are also {cmd:hc2} and {cmd:hc3}
    which provide alternative bias corrections for the robust variance calculation; see
    {helpb regress##vcetype:regress}.

{pmore}
    The default is {cmd:vce(robust)}, unless {cmd:iweight}s are specified, in which
    case the default is {cmd:vce(ols)}.

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
    {cmd:riflogit}.

{phang}
    {opt noheader} suppresses the display of the table header.

{phang}
    {opt notable} suppresses the display of the table of results.

{phang}
    {it:display_options} are usual display options as documented in
    {helpb estimation options##display_options:[R] Estimation options}.

{phang}
    {opt coeflegend} specifies that the legend of the coefficients and how to
    specify them in an expression be displayed rather
    than displaying the statistics for the coefficients.


{title:Examples}

        . {stata webuse lbw}
        . {stata logit low i.smoke age lwt i.race ptl ht ui, or vce(robust)}
        . {stata riflogit low i.smoke age lwt i.race ptl ht ui, or vce(robust)}


{title:Stored results}

{pstd}
    See {helpb regress} for information on stored results. {cmd:riflogit}
    updates macros {cmd:e(cmd)}, {cmd:e(predict)}, and {cmd:e(title)}, and
    removes macro {cmd:e(estat_cmd)}.


{title:References}

{phang}
    Firpo, Sergio, Nicole M. Fortin, Thomas Lemieux. 2009. Unconditional
    Quantile Regressions. Econometrica
    77(3):953–973. DOI: {browse "https://doi.org/10.3982/ECTA6822":10.3982/ECTA6822}
    {p_end}
{phang}
    Jann, Ben, Kristian Bernt Karlson. 2023. Estimation of marginal odds ratios. University
    of Bern Social Sciences Working Papers 44. Available from
    {browse "https://ideas.repec.org/p/bss/wpaper/44.html"}.
    {p_end}


{title:Author}

{pstd}
    Ben Jann, University of Bern, ben.jann@unibe.ch

{pstd}
    Thanks for citing this software as follows:

{pmore}
    Jann, B. (2022). riflogit: Stata module to fit unconditional logistic regression. Available from
    {browse "http://github.com/benjann/riflogit/"}.


{title:Also see}

{psee}
    Online:  help for
    {helpb regress}, {helpb logit}, {helpb ipwlogit} (if installed),
    {helpb lnmor} (if installed)
