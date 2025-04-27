{smcl}
{* 26apr2025}{...}
{hi:help listreg}{...}
{right:{browse "https://github.com/benjann/listreg/"}}
{hline}

{title:Title}

{pstd}{hi:listreg} {hline 2} Linear regression for list experiments


{title:Syntax}

{pstd}
    Single-list design:

{p 8 15 2}
    {cmd:listreg} {help varname:{it:ovar}} [{cmd:=}] {help varname:{it:tvar}} [{help varlist:{it:indepvars}}] {ifin} {weight}
    [{cmd:,}
    {help listreg##opt:{it:options}}
    ]

{pstd}
    where {it:ovar} is the outcome variable from the list experiment, and where
    {it:tvar} is a variable identifying the experimental groups
    ({it:tvar}==1: long-list group; {it:tvar}!=1: short-list group).

{pstd}
    Double-list design:

{p 8 15 2}
    {cmd:listreg} {help varname:{it:ovar1}} {help varname:{it:ovar2}} {cmd:=} {help varname:{it:tvar}} [{help varlist:{it:indepvars}}] {ifin} {weight}
    [{cmd:,}
    {help listreg##opt:{it:options}}
    ]

{pstd}
    {it:ovar1} and {it:ovar2} are the two outcome variables from the double-list experiment, and where
    {it:tvar} is a variable identifying the experimental groups
    ({it:tvar}==1: long-list group for {it:ovar1} and short-list group for {it:ovar2};
    {it:tvar}!=1: short-list group for {it:ovar1} and long-list group for {it:ovar2}).


{synoptset 20 tabbed}{...}
{marker opt}{synopthdr:options}
{synoptline}
{syntab :Main}
{synopt :{opt nocons:tant}}suppress constant term
    {p_end}
{synopt :{opth c:ontrols(varlist)}}custom specification of short-list equation(s)
    {p_end}
{synopt :{opt ave:rage}}use alternative double-list estimator
    {p_end}
{synopt :{opt list:wise}}use listwise deletion to handle missing values
    {p_end}
{synopt :{opt case:wise}}synonym for {cmd:listwise}
    {p_end}
{synopt :{opt aeq:uations}}include auxiliary equations in results
    {p_end}
{synopt :{opt noi:sily}}display output from estimation process
    {p_end}

{syntab :VCE}
{synopt :{cmd:vce(}{help listreg##vce:{it:vcetype}}{cmd:)}}how standard errors are computed
    {p_end}
{synopt :{opt cl:uster(clustvar)}}synonym for {cmd:vce(cluster} {it:clustvar}{cmd:)}
    {p_end}
{synopt :{opt normal}}use normal distribution for statistical inference
    {p_end}
{synopt :{opt nose}}omit variance estimation
    {p_end}
{synopt :{cmdab:ifgen:erate(}{help listreg##ifgen:{it:spec}}{cmd:)}}store influence functions
    {p_end}
{synopt :{opt replace}}allow replacing existing variables
    {p_end}

{syntab :Reporting}
{synopt :{help listreg##reporting:{it:reporting_option}}}standard reporting options
    {p_end}
{synoptline}
{pstd}
    {it:indepvars} and {cmd:controls()} may contain factor variables; see {help fvvarlist}.
    {p_end}
{pstd}
    {cmd:pweight}s, {cmd:iweight}s, and {cmd:fweight}s are allowed; see help {help weight}.


{title:Description}

{pstd}
    {cmd:listreg} fits a linear model to data from a list experiment
    (a.k.a. item count technique; see, e.g.,
    {browse "https://doi.org/10.1002/9781118150382.ch11":Droitcour et al. 1991},
    {browse "https://doi.org/10.1093/pan/mpr048":Blair and Imai 2012},
    {browse "https://doi.org/10.1093/poq/nfs070":Glynn 2013},
    {browse "https://doi.org/10.1017/S0003055420000374":Blair et al. 2020},
    {browse "https://doi.org/10.1093/poq/nfab002":Ehler et al. 2021})
    or to data collected by the item-sum technique
    ({browse "https://doi.org/10.1093/jssam/smt019":Trappmann et al. 2014},
    {browse "https://doi.org/10.18148/srm/2018.v12i2.7247":Krumpal et al. 2018}).
    Single-list and double-list designs are supported.

{pstd}
    {cmd:listreg} only covers linear (least-squares) models. For a more comprehensive
    package featuring alternative methods see the {helpb kict} package by
    {browse "https://doi.org/10.1177/1536867X19854018":Tsai (2019)}.

{pstd}
    Variance estimation in {cmd:listreg} is based on influence functions
    (see {browse "https://ideas.repec.org/p/bss/wpaper/35.html":Jann 2020}). Complex
    survey estimation is supported, although you need to specify option
    {cmd:vce(svy)} rather than applying the {helpb svy} prefix command.

{pstd}
    A distinct feature of {cmd:listreg} is that the control equation modeling
    the short-list outcome can be different from the main equation of the
    model. For example, when applying an intercept-only model to estimate the
    overall prevalence, including predictors in the control equation may
    increase statistical efficiency of the estimate. Likewise, you
    may want to specify more complex effect shapes in the control equation than
    in the main equation to improve the fit of the short-list
    model. Important: While it is perfectly fine to use a main equation that is
    less complex than the control equation, using a control equation that is
    less complex than the main equation can lead to invalid results (i.e.,
    results that are only due to a lack of fit in the control equation; for
    example, it is usually not a good idea to include predictors in the main
    equation that are not part of the control equation).


{title:Options}

{phang}
    {opt noconstant} suppresses constant term.

{phang}
    {cmd:controls(}[{varlist}][{cmd:,} {cmdab:nocons:tant} {cmd:none}]{cmd:)}
    specifies the variables to be included in the short-list equation. By
    default, the same specification is used as for the main outcome
    equation. Factor variables are allowed; see {help fvvarlist}. Suboption
    {cmd:noconstant} omits the constant term in the specified
    short-list equation; {cmd:noconstant} has an effect only if {it:varlist} is
    specified. Suboption {cmd:none} leaves the short-list equation empty; {cmd:none}
    has no effect if {it:varlist} is specified.

{pmore}
    In the double-list design, option {cmd:controls()} can be repeated to set
    different specifications for the two short-list models. The first instance
    of {cmd:controls()} determines the specification of the short-list 1
    model; the second instance determines the specification of the short-list 2
    model. If {cmd:controls()} is specified only once, the same specification
    is used for both models.

{phang}
    {opt average} reports average coefficients from two separate outcome
    equations. This is only relevant in case of the double-list design. The default
    is to report coefficients from a pooled outcome model across both lists.

{phang}
    {opt listwise} handles missing values through listwise deletion,
    meaning that the same set of observations will be used for both
    outcome variables. This is only relevant in case of the double-list
    design. By default, {cmd:listreg} determines the available observations
    individually for each list.

{phang}
    {opt casewise} is a synonym for {cmd:listwise}.

{phang}
    {opt aequations} specifies that the coefficients from the
    auxiliary equations (short-list models, separate long-list models in case of
    {cmd:average}) be included in the results. By default, {cmd:listreg}
    only includes the main coefficients.

{phang}
    {opt noisily} displays a trace of the output from the estimation
    process. Note that the standard errors in
    the output made visible by {cmd:noisily} may not be valid.

{marker vce}{...}
{phang}
    {opt vce(vcetype)} determines how standard errors are computed. {it:vcetype} may be

            {opt r:obust}
            {opt cl:uster} {it:clustvar}
            {opt svy} [{help svy##svy_vcetype:{it:svy_vcetype}}] [{cmd:,} {help svy##svy_options:{it:svy_options}} ]
            {opt boot:strap} [{cmd:,} {help bootstrap:{it:bootstrap_options}} ]
            {opt jack:knife} [{cmd:,} {help jackknife:{it:jackknife_options}} ]

{pmore}
    {cmd:vce(robust)} computes robust standard errors; this
    is the default. {cmd:vce(cluster} {it:clustvar}{cmd:)} computes standard errors
    allowing for intragroup correlation within groups defined
    by {it:clustvar}. {cmd:vce(svy)} computes standard errors taking the survey
    design as set by {helpb svyset} into account. The syntax is equivalent to
    the syntax of the {helpb svy} prefix command; that is, {cmd:vce(svy)} is
    {cmd:listreg}'s way to support the {helpb svy} prefix. {cmd:vce(bootstrap)}
    and {cmd:vce(jackknife)} compute standard errors using {helpb bootstrap} or
    {helpb jackknife}, respectively; see help {it:{help vce_option}}.

{phang}
    {opt cluster(clustvar)} is a synonym for {cmd:vce(cluster} {it:clustvar}{cmd:)}.

{phang}
    {opt normal} divides variances by N rather than N-1 and reports test statistics
    based on the standard normal distribution rather than the
    t-distribution. Use this option to obtain results that are equivalent to
    results returned by {helpb gmm}. {cmd:normal} has no effect if {cmd:vce(svy)},
    {cmd:vce(bootstrap)}, or {cmd:vce(jackknife)} is specified.

{phang}
    {opt nose} omits variance estimation; no standard error will be reported
    in this case.

{marker ifgen}{...}
{phang}
    {opt ifgenerate(spec)} stores the influence functions of the coefficients
    in the outcome model. Either specify a list of new variables names, or
    specify {it:stub}{cmd:*}, in which case the new variables will be named
    {it:stub}{cmd:1}, {it:stub}{cmd:2}, etc. Option {cmd:ifgenerate()} is not
    allowed with {cmd:vce(bootstrap)} or {cmd:vce(jackknife)}.

{phang}
    {opt replace} allows to overwrite existing variables.

{marker reporting}{...}
{phang}
    {it:reporting_option} are standard reporting options such as {opt level(#)},
    {opt coefl:egend}, {opt nohead:er}, or
    {help regress##display_options:{it:display_options}}.


{title:Examples}

        {help listreg##ex_data:Data}
        {help listreg##ex_single:Single-list estimate}
        {help listreg##ex_double:Double-list estimate}
        {help listreg##ex_xvars:Adding predictors and controls}
        {help listreg##ex_test:Consistency test in the double-list design}
        {help listreg##ex_gmm:Relation to GMM}
        {help listreg##ex_atet:Relation to treatment effect estimation}

{marker ex_data}{...}
{dlgtab:Data}

{pstd}
    {browse "https://doi.org/10.1515/jbnst-2011-5-612":Coutts et al. (2011)}
    report results from a list experiment on plagiarism
    (intentional inclusion of text from another source without citation) by
    university students. An excerpt from the data of this study is as follows.

        {com}. {stata "use http://fmwww.bc.edu/repec/bocode/l/listreg.dta, clear"}
        . {stata describe}{txt}

{pstd}
    The study used a double-list design. Variable {cmd:plagiarism_1} contains
    the response to list 1, {cmd:plagiarism_2} contains the response to
    list 2. Variable {cmd:longlist}=1 indicates that the sensitive item was
    included in list 1; {cmd:longlist}=2 indicates that the sensitive item was
    included in list 2.

{marker ex_single}{...}
{dlgtab:Single-list estimate}

{pstd}
    The plagiarism prevalence can be estimates from list 1 as follows:

        {com}. {stata listreg plagiarism_1 longlist}{txt}

{pstd}
    Likewise, the estimate from list 2 is:

        {com}. {stata listreg plagiarism_2 2.longlist}{txt}

{pstd}
    Both results indicate that about 10 percent of students have ever intentionally
    plagiarized in a term paper, but the estimates are rather imprecise.

{marker ex_double}{...}
{dlgtab:Double-list estimate}

{pstd}
    A more efficient estimate can be obtained by a combined analysis of both lists:

        {com}. {stata listreg plagiarism_1 plagiarism_2 = longlist}{txt}

{pstd}
    The equal sign indicates to {cmd:listreg} that the first two variables
    are both outcome variables. Using wildcard notation, we can omit the equal
    sign (assuming that there are only two matching variables):

        {com}. {stata listreg plagiarism_* longlist}{txt}

{pstd}
    By default, the double-list estimator uses a pooled outcome model; to report
    average coefficients from two separate outcome equations, type:

        {com}. {stata listreg plagiarism_* longlist, average}{txt}

{pstd}
    Results are almost identical, which is not surprising since the two experimental
    groups are of similar size.

{marker ex_xvars}{...}
{dlgtab:Adding predictors and controls}

{pstd}
    Not all students seem to be aware of the university's plagiarism
    regulations. To test whether awareness of regulations is related to
    plagiarism prevalence we can add a corresponding indicator as an
    independent variable to the model:

        {com}. {stata listreg plagiarism_* longlist i.unaware}{txt}

{pstd}
    Indeed, it seems that plagiarism occurs primarily among students who are
    unaware of the regulations; plagiarism prevalence is about 32 percentage points
    higher than for other students. To report the plagiarism levels for both groups
    (rather than the difference), we can type:

        {com}. {stata listreg plagiarism_* longlist ibn.unaware, noconstant}{txt}

{pstd}
    The prevalence estimate for students who know the regulations is 2 percent;
    for students who do not know the regulations it is 34 percent.

{pstd}
    Here is a more complicated analysis that also tests the effect of gender and
    includes further covariates in the short-list equation to improve the fit:

{p 8 12 2}
{com}. {stata listreg plagiarism_* longlist i.unaware i.female, controls(i.unaware i.female year i.working i.papers)}{txt}

{pstd}
    The results of the short-list models are not included in the {cmd:listreg}
    output because they are not of primary interest. If you are interested in these
    models, you can specify option {cmd:noisily} to display a trace of the estimation
    process, including the short-list models. Alternatively, specify option
    {cmd:aequations} to include the auxiliary models in the final output as separate
    equations:

{p 8 12 2}
{com}. {stata listreg plagiarism_* longlist i.unaware i.female, controls(i.unaware i.female year i.working i.papers) aequations}{txt}

{pstd}
    Furthermore, it is typically easy to replicate the short-list
    models outside of {cmd:listreg} by applying {cmd:regress} to the short-list
    subsamples. In the current example, the two models are as follows:

{p 8 12 2}
{com}. {stata regress plagiarism_1 i.unaware i.female year i.working i.papers if longlist!=1, robust}{txt}
    {p_end}
{p 8 12 2}
{com}. {stata regress plagiarism_2 i.unaware i.female year i.working i.papers if longlist==1, robust}{txt}

{pstd}
    Note that you can specify two {cmd:controls()} options, if you want
    to use different specifications for the two short-list equations. Example:

{p 8 12 2}
{com}. {stata listreg plagiarism_* longlist i.unaware, controls(i.unaware i.female i.working i.papers) controls(i.unaware year)}{txt}

{marker ex_test}{...}
{dlgtab:Consistency test in the double-list design}

{pstd}
    A systematic difference in results between the two lists in a double-list
    design indicates that the list experiment did not work as expected: apparently,
    the choice of the shortlist, or other differences between the two
    experimental groups, mattered for the results, which is at odds
    with the basic assumptions of the list experiment.

{pstd}
    One approach to test the consistency of results
    across lists is to specify options {cmd:average} and {cmd:aequations} so that
    list-specific outcome equations are estimated and included
    in the results. Then use command {helpb test} to evaluate
    whether the two equations are different (when calling
    {helpb test}, make sure to specify option {cmd:constant} so that the constant
    is included in the test). Example:

        {com}. {stata listreg plagiarism_* longlist, average aequations}{txt}
        {com}. {stata test [LL1 = LL2], constant}{txt}

{pstd}
    This also works if there are predictors and controls in the model:

{p 8 12 2}
{com}. {stata listreg plagiarism_* longlist i.unaware i.female, average aequations controls(i.unaware i.female year i.working i.papers)}{txt}
{p_end}
        {com}. {stata test [LL1 = LL2], constant}{txt}

{pstd}
    An alternative approach is to add an indicator for the experimental group
    to the outcome equation of the default estimator. The effect of the
    group indicator is equal to the difference in results between the two lists.

        {com}. {stata listreg plagiarism_* longlist i.longlist}{txt}

{pstd}
    If the model contains predictors, include all interactions between the group
    indicator and the predictors and then use {helpb test} to perform a joint
    test across the main effect and all interaction terms.

{p 8 12 2}
{com}. {stata listreg plagiarism_* longlist i.unaware i.female i.longlist i.longlist#(i.unaware i.female), controls(i.unaware i.female year i.working i.papers)}{txt}
{p_end}
{p 8 12 2}
{com}. {stata test 2.longlist 2.longlist#1.unaware 2.longlist#1.female}{txt}

{pstd}
    The two outlined approaches lead to equivalent results.

{marker ex_gmm}{...}
{dlgtab:Relation to GMM}

{pstd}
    The results computed by {cmd:listreg} can be replicated by {helpb gmm}. Example
    for the single-list design:

        {com}local Y plagiarism_1
        local T longlist
        local X i.unaware i.female
        local Z `X' year i.working i.papers
        gmm (1: (`T'!=1)*(`Y' - {xb0:`Z' _cons})) ///
            (2: (`T'==1)*(`Y' - {xb0:} - {xb1:`X' _cons})) ///
            , instruments(1:`Z') instruments(2:`X') winitial(identity)
        listreg `Y' `T' `X', controls(`Z') normal{txt}

{pstd}
    Example for the double-list design:

        {com}local Y1 plagiarism_1
        local Y2 plagiarism_2
        local T  longlist
        local X  i.unaware
        local Z1 `X' i.female i.working i.papers
        local Z2 `X' year
        gmm (1: (`T'!=1)*(`Y1' - {xb0:`Z1' _cons})) ///
            (2: (`T'==1)*(`Y2' - {xb1:`Z2' _cons})) ///
            (3: (`T'==1)*(`Y1' - {xb0:}) + (`T'!=1)*(`Y2' - {xb1:}) - {xb2:`X' _cons}) ///
            , instruments(1:`Z1') instruments(2:`Z2') instruments(3:`X') ///
              winitial(identity)
        listreg `Y1' `Y2' = `T' `X', controls(`Z1') controls(`Z2') normal listwise{txt}

{marker ex_atet}{...}
{dlgtab:Relation to treatment effect estimation}

{pstd}
    The single-list estimator implemented in {cmd:listreg} is equivalent to a
    regression-adjustment (RA) estimator of the average treatment effect on the
    treated (ATET). Here is an example illustrating the equivalence between
    {cmd:listreg} and {helpb teffects ra} (treatment effect of smoking on birth weight):

        {com}. {stata webuse cattaneo2, clear}
{p 8 12 2}
        . {stata teffects ra (bweight prenatal1 mmarried mage fbaby) (mbsmoke), atet}
    {p_end}
{p 8 12 2}
        . {stata listreg bweight mbsmoke, controls(prenatal1 mmarried mage fbaby) normal}{txt}

{pstd}
    This means that {cmd:listreg} can be used for treatment effect heterogeneity
    analysis. For example, we might be interested in whether the treatment effect
    of smoking on birth weight varies by first-trimester exam status and
    first-birth status:

{p 8 12 2}
        . {stata listreg bweight mbsmoke prenatal1 fbaby, controls(prenatal1 mmarried mage fbaby) normal}{txt}

{pstd}
    First-trimester exam status does not seem to play a role, but the results
    indicate that the treatment effect is less pronounced in case of a
    first baby.

{pstd}
    Furthermore, note that the double-list estimator can be used to recover the
    average treatment effect (ATE). The trick is to use reversed outcomes in
    {it:ovar2}. Example:

{p 8 12 2}
        . {stata teffects ra (bweight prenatal1 mmarried mage fbaby) (mbsmoke)}
    {p_end}
{p 8 12 2}
        . {stata generate rbw = -bweight}
    {p_end}
{p 8 12 2}
        . {stata listreg bweight rbw = mbsmoke, controls(prenatal1 mmarried mage fbaby) normal}
    {p_end}
{p 8 12 2}
        . {stata listreg bweight rbw = mbsmoke prenatal1 fbaby, controls(prenatal1 mmarried mage fbaby) normal}{txt}


{title:Returned results}

{pstd}
    {cmd:listreg} stores its results in {cmd:e()}. Type {helpb ereturn list}
    after estimation for more information.


{title:Methods and Formulas}

{pstd}
    {cmd:listreg} works by applying linear regression to residualized outcome
    variables. Let Y be the outcome, T be the long-list indicator, X be
    a vector of predictors (including constant), and Z be a vector of controls. The
    estimation procedure for the single-list design then is as follows:

{phang2}1. Regress Y on Z in the subsample for which T != 1.{p_end}
{phang2}2. Predict residuals R from this model in the subsample for which T = 1.{p_end}
{phang2}3. Regress R on X in the subsample for which T = 1 and report the coefficients.{p_end}

{pstd}
    For the double-list design, let Y1 be the outcome from list 1,
    Y2 be the outcome from list 2, Z1 be the controls for list 1, and
    Z2 be the controls for list 2. The default procedure then is as follows:

{phang2}1. Regress Y1 on Z1 in the subsample for which T != 1.{p_end}
{phang2}2. Regress Y2 on Z2 in the subsample for which T = 1.{p_end}
{phang2}3. Predict residuals R from first model in the subsample for which T = 1
    and from the second model in the subsample for which T != 1.{p_end}
{phang2}4. Regress R on X and report the coefficients.{p_end}

{pstd}
    If option {cmd:average} is specified, step 4 is replaced by:

{phang2}4. Regress R on X subsample for which T = 1.{p_end}
{phang2}5. Regress R on X subsample for which T != 1.{p_end}
{phang2}6. Report the average of the coefficients from steps 4 and 5.{p_end}

{pstd}
    Variance estimation is conducted at the end, based on the influence functions
    implied by the chain of estimation steps.


{title:References}

{phang}
    Blair, G., A. Coppock, M. Moor. 2020. When to Worry about Sensitivity
    Bias: A Social Reference Theory and Evidence from 30 Years of List
    Experiments. American Political Science Review
    114(4):1297–1315. {browse "https://doi.org/10.1017/S0003055420000374":doi.org/10.1017/S0003055420000374}
    {p_end}
{phang}
    Blair, G., K. Imai. 2012. Statistical Analysis of List Experiments. Political
    Analysis 20(1):47-77. {browse "https://doi.org/10.1093/pan/mpr048":doi.org/10.1093/pan/mpr048}
    {p_end}
{phang}
    Coutts, E., B. Jann, I. Krumpal, A.-F. Näher. 2011. Plagiarism
    in Student Papers: Prevalence Estimation Using Special Techniques for
    Sensitive Questions. Jahrbücher für Nationalökonomie und Statistik
    231(5-6):749-760. {browse "https://doi.org/10.1515/jbnst-2011-5-612":doi.org/10.1515/jbnst-2011-5-612}
    {p_end}
{phang}
    Droitcour, J., R.A. Caspar, M.L. Hubbard, T.L. Parsely, W. Visscher,
    T.M. Ezzati. 1991. The Item Count Technique as a Method of Indirect
    Questioning: A Review of its Development and a Case Study Application. P. 185–210
    in: P.P. Biemer, R.M. Groves, L.E. Lyberg, N.A. Mathiowetz, S. Sudman (eds.). Measurement
    Errors in Surveys. New York: Wiley. {browse "https://doi.org/10.1002/9781118150382.ch11":doi.org/10.1002/9781118150382.ch11}
    {p_end}
{phang}
    Ehler, I., F. Wolter, J. Junkermann. 2021. Sensitive Questions in
    Surveys: A Comprehensive Meta-Analysis of Experimental Survey Studies on
    the Performance of the Item Count Technique. Public Opinion Quarterly
    85(1):6–27. {browse "https://doi.org/10.1093/poq/nfab002":doi.org/10.1093/poq/nfab002}
    {p_end}
{phang}
    Glynn, A. N. 2013. What Can We Learn with Statistical Truth Serum?: Design
    and Analysis of the List Experiment. Public Opinion Quarterly
    77(S1):159–172. {browse "https://doi.org/10.1093/poq/nfs070":doi.org/10.1093/poq/nfs070}
    {p_end}
{phang}
    Jann, B. 2020. Influence functions continued. A framework for estimating standard
    errors in reweighting, matching, and regression adjustment. University of Bern Social
    Sciences Working Papers No. 35. {browse "https://doi.org/10.7892/boris.142529":doi.org/10.7892/boris.142529}
    {p_end}
{phang}
    Krumpal, I., B. Jann, M. Korndörfer, S. Schmukle. 2018. Item Sum Double-List
    Technique: An Enhanced Design for Asking Quantitative Sensitive Questions. Survey
    Research Methods 12(2):91-102. {browse "https://doi.org/10.18148/srm/2018.v12i2.7247":doi.org/10.18148/srm/2018.v12i2.7247}
    {p_end}
{phang}
    Trappmann, M., I. Krumpal, A. Kirchner, B. Jann. 2014. Item Sum: A New
    Technique for Asking Quantitative Sensitive Questions. Journal of Survey Statistics
    and Methodology 2(1):58-77. {browse "https://doi.org/10.1093/jssam/smt019":doi.org/10.1093/jssam/smt019}
    {p_end}
{phang}
    Tsai, C. 2019. Statistical analysis of the item-count technique using Stata. Stata Journal
    19(2):390-434. {browse "https://doi.org/10.1177/1536867X19854018":doi.org/10.1177/1536867X19854018}
    {p_end}


{title:Author}

{pstd}
    Ben Jann, University of Bern, ben.jann@unibe.ch

{pstd}
    Thanks for citing this software as follows:

{pmore}
    Jann, B. (2024). listreg: Stata module for the analysis of list experiments
    using linear regression. Available from
    {browse "https://ideas.repec.org/c/boc/bocode/s459304.html"}.


{title:Also see}

{psee}
    Online:  help for
    {helpb regress}, {helpb gmm}, {helpb teffects ra}
