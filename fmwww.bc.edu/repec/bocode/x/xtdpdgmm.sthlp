{smcl}
{* *! version 2.6.2  03aug2022}{...}
{* *! Sebastian Kripfganz, www.kripfganz.de}{...}
{vieweralsosee "xtdpdgmm postestimation" "help xtdpdgmm_postestimation"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] regress" "help regress"}{...}
{vieweralsosee "[R] ivregress" "help ivregress"}{...}
{vieweralsosee "[R] gmm" "help gmm"}{...}
{vieweralsosee "[XT] xtreg" "help xtreg"}{...}
{vieweralsosee "[XT] xtivreg" "help xtivreg"}{...}
{vieweralsosee "[XT] xtabond" "help xtabond"}{...}
{vieweralsosee "[XT] xtdpd" "help xtdpd"}{...}
{vieweralsosee "[XT] xtdpdsys" "help xtdpdsys"}{...}
{vieweralsosee "[XT] xtset" "help xtset"}{...}
{viewerjumpto "Syntax" "xtdpdgmm##syntax"}{...}
{viewerjumpto "Description" "xtdpdgmm##description"}{...}
{viewerjumpto "Options" "xtdpdgmm##options"}{...}
{viewerjumpto "Remarks" "xtdpdgmm##remarks"}{...}
{viewerjumpto "Example" "xtdpdgmm##example"}{...}
{viewerjumpto "Saved results" "xtdpdgmm##results"}{...}
{viewerjumpto "Version history and updates" "xtdpdgmm##update"}{...}
{viewerjumpto "Author" "xtdpdgmm##author"}{...}
{viewerjumpto "References" "xtdpdgmm##references"}{...}
{title:Title}

{p2colset 5 17 19 2}{...}
{p2col :{bf:xtdpdgmm} {hline 2}}GMM linear dynamic panel data estimation{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}{cmd:xtdpdgmm} {depvar} [{indepvars}] {ifin} [{cmd:,} {it:options}]


{synoptset 20 tabbed}{...}
{synopthdr:options}
{synoptline}
{syntab:Model}
{synopt:{opt iv}{cmd:(}{it:{help xtdpdgmm##options_spec:iv_spec}}{cmd:)}}standard instruments; can be specified more than once{p_end}
{synopt:{opt gmm:iv}{cmd:(}{it:{help xtdpdgmm##options_spec:gmmiv_spec}}{cmd:)}}GMM-type instruments; can be specified more than once{p_end}
{synopt:{opt nl}{cmd:(}{it:{help xtdpdgmm##options_spec:nl_spec}}{cmd:)}}add nonlinear moment conditions derived from error covariance structure{p_end}
{synopt:{opt c:ollapse}}collapse GMM-type into standard instruments{p_end}
{synopt:{opt cur:tail(#)}}curtail the lag range for GMM-type instruments{p_end}
{synopt:{opt m:odel}{cmd:(}{it:{help xtdpdgmm##options_spec:model_spec}}{cmd:)}}set the default model for the instruments and VCE{p_end}
{synopt:{opt nolev:el}}ignore specifications for the model in levels{p_end}
{synopt:{opt nores:cale}}do not rescale the transformed moment conditions{p_end}
{synopt:{opt w:matrix}{cmd:(}{it:{help xtdpdgmm##options_spec:wmat_spec}}{cmd:)}}specify initial weighting matrix{p_end}
{synopt:{opt cen:ter}}center moments in the optimal weighting matrix{p_end}
{p2coldent :* {opt one:step}|{opt two:step}}use the one-step or two-step estimator{p_end}
{p2coldent :* {opt igmm}}use the iterated GMM estimator{p_end}
{p2coldent :* {opt cu:gmm}}use the continuously-updating GMM estimator{p_end}
{synopt:{opt te:ffects}}add time effects to the model{p_end}
{synopt:{opt nocons:tant}}suppress constant term{p_end}

{syntab:SE/Robust}
{synopt:{opt vce}{cmd:(}{it:{help xtdpdgmm##options_spec:vce_spec}}{cmd:)}}specify the {help xtdpdgmm##vcetype:{it:vcetype}} for the SE estimation{p_end}
{synopt:{opt sm:all}}make degrees-of-freedom adjustment and report small-sample statistics{p_end}

{syntab:Reporting}
{synopt:{opt over:id}}compute overidentification statistics for reduced models{p_end}
{synopt:{opt aux:iliary}}display all coefficients as auxiliary parameters{p_end}
{synopt:{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
INCLUDE help shortdes-coeflegend
{synopt:{opt nohe:ader}}suppress output header{p_end}
{synopt:{opt notab:le}}suppress coefficient table{p_end}
{synopt:{opt nofo:oter}}suppress output footer{p_end}
{synopt:{it:{help xtdpdgmm##display_options:display_options}}}control
INCLUDE help shortdes-displayoptall

{syntab:Minimization}
{synopt:{opt noan:alytic}}do not use analytical closed-form solutions{p_end}
{synopt:{opt from}{cmd:(}{it:{help xtdpdgmm##options_spec:init_spec}}{cmd:)}}initial values for the coefficients{p_end}
{synopt:{opt nodot:s}}display an iteration log instead of dots for each step of the iterated GMM estimator{p_end}
{synopt:{it:{help xtdpdgmm##igmm_options:igmm_options}}}control the iterated GMM process; seldom used{p_end}
{synopt:{it:{help xtdpdgmm##minimize_options:minimize_options}}}control the minimization process; seldom used{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}* You can specify at most one of these options. {cmd:onestep} is the default unless option {opt nl(nl_spec)} is specified, in which case {cmd:twostep} is the default.{p_end}

{marker options_spec}{...}
{p 4 6 2}
{it:iv_spec} is

{p 8 12 2}
{varlist} [{cmd:,} {opt l:agrange(#_1 [#_2])} {opt d:ifference} {opt bod:ev} {opt m:odel(model_spec)} [{cmdab:no:}]{opt res:cale}]

{p 4 6 2}
{it:gmmiv_spec} is

{p 8 12 2}
{varlist} [{cmd:,} {opt l:agrange(#_1 [#_2])} [{cmdab:no:}]{opt c:ollapse} {opt d:ifference} {opt bod:ev} {opt m:odel(model_spec)} [{cmdab:no:}]{opt res:cale} {opt iid}]

{p 4 6 2}
{it:nl_spec} is

{p 8 12 2}
{opt noser:ial}|{opt iid}|{opt pre:determined} [{cmd:,} [{cmdab:no:}]{opt c:ollapse} [{cmdab:no:}]{opt res:cale} {opt l:ag(#)} {opt w:eight(#)}]

{p 4 6 2}
{it:wmat_spec} is

{p 8 12 2}
[{opt un:adjusted}|{opt ind:ependent}|{opt sep:arate}|{opt identity}] [{cmd:,} {opt r:atio(#)}]

{p 4 6 2}
{it:vce_spec} is

{p 8 12 2}
[{opt conventional}|{opt r:obust}|{opt cl:uster} {it:clustvar}] [{cmd:,} {opt m:odel(model_spec)} {opt wc}|{opt dc}]

{p 4 6 2}
{it:model_spec} is

{p 8 12 2}
{opt l:evel}|{opt d:ifference}|{opt fod:ev}|{opt md:ev}|{opt m:ean}

{p 4 6 2}
{it:init_specs} is one of

{p 8 12 2}{it:matname} [{cmd:,} {cmd:skip} {cmd:copy}]{p_end}

{p 8 12 2}{it:#} [{it:#} {it:...}]{cmd:,} {cmd:copy}{p_end}

{p 4 6 2}
You must {cmd:xtset} your data before using {cmd:xtdpdgmm}; see {helpb xtset:[XT] xtset}.{p_end}
{p 4 6 2}
All {it:varlists} may contain factor variables; see {help fvvarlist}.{p_end}
{p 4 6 2}
{it:depvar} and all {it:varlists} may contain time-series operators; see {help tsvarlist}.{p_end}
{p 4 6 2}
See {helpb xtdpdgmm postestimation} for features available after estimation and {helpb xtdpdgmmfe} for a wrapper of {cmd:xtdpdgmm} with simplified syntax.{p_end}
{p 4 6 2}
{cmd:xtdpdgmm} is a community-contributed program. The current version requires Stata version 13 or higher; see {help xtdpdgmm##update:version history and updates}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtdpdgmm} implements generalized method of moments (GMM) estimators for linear dynamic panel data models. GMM estimators can be specified with linear moment conditions in the spirit of Anderson and Hsiao (1981), Arellano and Bond (1991),
Arellano and Bover (1995), Blundell and Bond (1998), and Hayakawa, Qi, and Breitung (2019). {cmd:xtdpdgmm} can also incorporate the nonlinear moment conditions suggested by Ahn and Schmidt (1995) or Chudik and Pesaran (2022),
which can yield efficiency gains and more robust results for highly persistent data.

{pstd}
The model can be estimated with the one-step, two-step, iterated, or continuously-updating GMM estimator. The two-step estimator uses an optimal weighting matrix which is estimated from the one-step residuals.
The iterated GMM estimator, suggested by Hansen, Heaton, and Yaron (1996), further updates the weighting matrix until convergence.
The continuously-updating GMM estimator, also proposed by Hansen, Heaton, and Yaron (1996), updates the weighting matrix jointly with the coefficients.

{pstd}
For estimators other than the continuously-updating GMM estimator, the Windmeijer (2005) finite-sample standard error correction is implemented.
Alternatively, the Lee (2014), Hansen and Lee (2021), and Hwang, Kang, and Lee (2022) doubly-corrected misspecification-robust standard errors are available as well.

{pstd}
Possible model transformations include first differences, deviations from within-group means, and forward-orthogonal deviations. With the latter, backward-orthogonal deviations of the instrumental variables are possible.
Instruments for different model transformations can be combined flexibly to form a 'system GMM' estimator.


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{cmd:iv(}{varlist} [{cmd:,} {it:suboptions}]{cmd:)} and {cmd:gmmiv(}{varlist} [{cmd:,} {it:suboptions}]{cmd:)} specify standard and GMM-type instruments, respectively. You may specify as many sets of standard instruments as you need.
Allowed {it:suboptions} for both type of instruments are {opt l:agrange(#_1 [#_2])}, {opt d:ifference}, {opt bod:ev}, {opt m:odel}{cmd:(}{opt l:evel}|{opt d:ifference}|{opt fod:ev}|{opt md:ev}|{opt m:ean}{cmd:)}, and [{cmdab:no:}]{opt res:cale}.
GMM-type instruments allow the additional {it:suboptions} [{cmdab:no:}]{opt c:ollapse} and {opt iid}.

{pmore}
{opt lagrange(#_1 [#_2])} specifies the range of lags of {it:varlist} to be used as instruments. Negative integers are allowed to include leads. The default depends on the type of instruments.

{pmore2}
Used with option {cmd:iv()}, the default is {cmd:lagrange(0 0)}. Specifying {cmd:iv(}{it:varlist}{cmd:,} {opt lagrange(#_1 #_2)}{cmd:)} is equivalent to specifying {cmd:iv(L(}{it:#_1}{cmd:/}{it:#_2}{cmd:).(}{it:varlist}{cmd:))}
unless suboption {cmd:bodev} is specified; see {help tsvarlist}. {opt lagrange(#_1)} with only one argument is equivalent to {opt lagrange(#_1 #_1)} with two identical arguments.

{pmore2}
Used with option {cmd:gmmiv()}, the default is {cmd:lagrange(1 .)} in combination with {cmd:model(difference)}, and {cmd:lagrange(0 .)} otherwise.
Unless restricted with option {cmd:curtail()}, a missing value for {it:#_1} requests all available leads to be used until {it:#_2}, while a missing value for {it:#_2} requests all available lags to be used starting with {it:#_1}.
Thus, {cmd:lagrange(. .)} uses all available observations. {opt lagrange(#_1)} with only one argument is equivalent to {cmd:lagrange(}{it:#_1}{cmd: .)}.

{pmore}
{opt collapse} and {opt nocollapse} used with option {cmd:gmmiv()} request to either collapse or to not collapse the GMM-type instruments into standard instruments. The suboption {cmd:collapse} is useful to reduce the number of instruments,
in particular if all available lags are used. With a limited number of lags, {cmd:gmmiv(}{it:varlist}{cmd:,} {cmd:lagrange(}{it:#_1 #_2}{cmd:) {cmd:collapse)}} is equivalent to {cmd:iv(}{it:varlist}{cmd:, lagrange(}{it:#_1 #_2}{cmd:))}.
The suboption {cmd:nocollapse} can be used to override the default set by the global option {cmd:collapse}.

{pmore}
{opt difference} requests a first-difference transformation of {it:varlist}. This is equivalent to specifying {cmd:iv(D.(}{it:varlist}{cmd:))}; see {help tsvarlist}.

{pmore}
{opt bodev} requests a backward-orthogonal deviations transformation of {it:varlist}. This is only possible in combination with {cmd:model(fodev)}.

{pmore}
{opt model(model)} specifies if the instruments apply to the model in levels, {cmd:model(level)}, in first differences, {cmd:model(difference)}, in forward-orthogonal deviations, {cmd:model(fodev)},
in deviations from within-group means, {cmd:model(mdev)}, or in within-group means, {cmd:model(mean)}. The default is {cmd:model(level)} unless otherwise specified with the global option {opt model(model)}.

{pmore}
{opt rescale} and {opt norescale} request to either rescale or to not rescale the moment conditions such that the transformed error term retains the same variance under the assumption that the untransformed idiosyncratic error component
is independent and identically distributed. These suboptions are seldom used and only have an effect in combination with {cmd:model(fodev)}, {cmd:model(mdev)}, or {cmd:model(mean)}.
They similarly affect the transformation of {it:varlist} when suboption {cmd:bodev} is specified. {cmd:rescale} is the default unless otherwise specified with the global option {cmd:norescale}.

{pmore}
{opt iid} used with option {cmd:gmmiv()} specifies instruments valid under an error-components structure with an independent and identically distributed idiosyncratic error component.
If specified as {cmd:gmmiv(L.}{it:depvar}{cmd:,} {cmd:iid)}, these are the additional instruments implied by the linear moment conditions derived by Ahn and Schmidt (1995) under the assumption of homoskedastic errors.
If specified as {cmd:gmmiv(L.}{it:depvar}{cmd:,} {cmd:difference} {cmd:iid)}, these are the additional instruments which can replace the nonlinear moment conditions derived by Chudik and Pesaran (2022).
This suboption is seldom used and it implies the other suboptions {cmd:model(difference)} and {cmd:lagrange(0 0)}.

{phang}
{cmd:nl(}{opt noser:ial}|{opt iid}|{opt pre:determined} [, {it:suboptions}]{cmd:)} adds nonlinear moment conditions that are valid under an error-components structure with specific assumptions on the idiosyncratic error component.
Allowed {it:suboptions} are [{cmdab:no:}]{opt c:ollapse}, [{cmdab:no:}]{opt res:cale}, {opt l:ag(#)}, and {opt w:eight(#)}.

{pmore}
{cmd:nl(noserial)} adds the nonlinear moment conditions suggested by Ahn and Schmidt (1995) under the absence of serial correlation in the idiosyncratic error component.

{pmore}
{cmd:nl(iid)} adds the nonlinear moment conditions suggested by Ahn and Schmidt (1995) under homoskedasticity and the absence of serial correlation in the idiosyncratic error component.
It further adds linear moment conditions of the form {cmd:gmmiv(L.}{it:depvar}{cmd:, iid} [{cmd:collapse}]{cmd:)} that are valid under this assumption.

{pmore}
{cmd:nl(predetermined)} adds the nonlinear moment conditions suggested by Chudik and Pesaran (2022) under the absence of serial correlation in the idiosyncratic error component.
It requires that all {it:indepvars} are predetermined or strictly exogenous.

{pmore}
{opt collapse} requests to add up the moment conditions to form a single moment condition. {cmd:nocollapse} can be used to override the default set by the global option {cmd:collapse}.

{pmore}
{opt rescale} and {opt norescale} request to either rescale or to not rescale the moment conditions such that the transformed error term retains the same variance
under the assumption that the untransformed idiosyncratic error term is independent and identically distributed. These suboptions are seldom used and only have an effect in combination with {cmd:nl(iid)}.
{cmd:rescale} is the default unless otherwise specified with the global option {cmd:norescale}.

{pmore}
{opt lag(#)} specifies the minimum lag of the first-differenced error term in the moment conditions under the absence of serial correlation. The default is {cmd:lag(1)}.
This option is only allowed in combination with {cmd:nl(noserial)}.

{pmore}
{opt weight(#)} specifies the weight of the nonlinear moment conditions in the initial weighting matrix relative to the linear moment conditions. The default is {cmd:weight(1)}.
Specifying {cmd:weight(0)} implies that the nonlinear moment conditions are ignored in the first estimation step.

{phang}
{opt collapse} requests to collapse all GMM-type instruments into standard instruments and to collapse the nonlinear moment conditions into a single moment condition.

{phang}
{opt curtail(#)} requests to curtail the lag range for GMM-type instruments if either {it:#_1} or {it:#_2} in the {cmd:gmmiv()} suboption {opt lagrange(#_1 [#_2])} are specified as missing values.
If {it:#_1} is missing, no leads will be used. If {it:#_2} is missing, all available lags until {it:#} will be used. Thus, {opt lagrange(. .)} is equivalent to {cmd:lagrange(0 }{it:#}{cmd:)}.
{opt curtail(.)} can be specified to only restrict {it:#_1}.

{phang}
{opt model(model)} sets the default model used to generate the instruments specified with options {cmd:iv()} and {cmd:gmmiv()} and the default model for the conventional variance estimator specified with option {cmd:vce()}.
{it:model} is allowed to be {opt l:evel}, {opt d:ifference}, {opt fod:ev}, {opt md:ev}, or {opt m:ean}. The default is {cmd:model(level)} unless option {opt nolevel} is specified, in which case the default is {cmd:model(difference)}.

{phang}
{opt nolevel} requests that all model specifications refer to a transformed model. This changes the default from {cmd:model(level)} to {cmd:model(difference)}.
All instruments which are explicitly specified for {cmd:model(level)} or {cmd:model(mean)} are ignored. With this option, instruments for the time dummies created with option {opt teffects} are no longer specified for the model in levels
but for the default model set with option {opt model(model)}. The degrees-of-freedom adjustment with option {opt small} is corrected for the reduction of time periods in the transformed model or the absorbed group-specific effects.
Groups with only a single observation are removed from the estimation sample. A regression intercept is still estimated for the model in levels unless option {opt noconstant} is specified.

{phang}
{opt norescale} requests not to rescale the moment conditions. By default, the moment conditions for {cmd:model(fodev)}, {cmd:model(mdev)}, and {cmd:model(mean)} are rescaled by a group-specific factor
such that the transformed error term retains the same variance under the assumption that the untransformed idiosyncratic error term is independent and identically distributed.
A similar transformation is applied to the nonlinear moment conditions added with option {cmd:nl(iid)}. In combination with option {opt center},
{opt norescale} ignores an adjustment to the mean of the moment functions in the optimal weighting matrix, which is applied by default when the number of observations differs across clusters, as in the case of unbalanced panel data.

{phang}
{cmd:wmatrix(}[{it:wmat_type}] [{cmd:,} {opt r:atio(#)}]{cmd:)} specifies the weighting matrix to be used to obtain one-step GMM estimates or initial estimates for two-step or iterated GMM estimation.
{it:wmat_type} is either {opt un:adjusted}, {opt ind:ependent}, {opt sep:arate}, or {opt identity}.

{pmore}
{cmd:wmatrix(unadjusted)}, the default, is optimal for an error-components structure with a group-specific component and an independent and identically distributed idiosyncratic component
if none of the instruments refer to the model in levels or if the variance ratio of the group-specific error component to the idiosyncratic error component is known,
and only if there are no nonlinear moment conditions. The variance ratio can be specified with the suboption {opt ratio(#)}. The default is {cmd:ratio(0)}.
Nonlinear moment conditions are always treated as independent in the initial weighting matrix.

{pmore}
{cmd:wmatrix(independent)} is the same as {cmd:wmatrix(unadjusted)} but treats the model in levels and the transformed models as independent, thus ignoring the covariance between the respective error terms.

{pmore}
{cmd:wmatrix(separate)} is the same as {cmd:wmatrix(unadjusted)} but treats the model in levels and the transformed models as separate models with an independent and identically distributed error term for the transformed models,
thus ignoring the covariance between the respective error terms and the serial correlation of the transformed error terms.

{pmore}
{cmd:wmatrix(identity)} is the identity matrix. This option is seldom used.

{phang}
{opt center} requests to center the moment functions in the computation of the optimal weighting matrix.

{phang}
{opt onestep}, {opt twostep}, {opt igmm}, and {opt cugmm} specify which estimator is to be used. At most one of these options can be specified.

{pmore}
{opt onestep} requests the one-step GMM estimator to be computed which is based on the initial weighting matrix specified with option {opt wmatrix(wmat_spec)}. This is the default unless option {opt nl(nl_spec)} is specified.
In a model without nonlinear moment conditions and with weighting matrix {cmd:wmatrix(unadjusted)}, the one-step estimator corresponds to the two-stage least squares estimator.

{pmore}
{opt twostep} requests the two-step GMM estimator to be computed which is based on an optimal weighting matrix. This is the default if option {opt nl(nl_spec)} is specified.
An unrestricted (cluster-robust) optimal weighting matrix is computed using one-step GMM estimates. The unrestricted weighting matrix allows for intragroup correlation at the level specified with {cmd:vce(cluster} {it:clustvar}{cmd:)}.
By default, {it:clustvar} equals {it:panelvar}.

{pmore}
{opt igmm} requests the iterated GMM estimator to be computed. At each iteration step, an unrestricted (cluster-robust) optimal weighting matrix is computed using the GMM estimates from the previous step.
Iterations continue until convergence is achieved for the coefficient vector or the weighting matrix, or the maximum number of iterations is reached; see {it:{help xtdpdgmm##igmm_options:igmm_options}}.

{pmore}
{opt cugmm} requests the continuously-updating GMM estimator to be computed. As a function of the model's coefficients, the unrestricted (cluster-robust) weighting matrix is updated jointly with the coefficients.

{phang}
{opt teffects} requests that time-specific effects are added to the model. Time dummies are instrumented by themselves for the model in levels unless option {opt nolevel} is specified,
in which case the time dummies are instrumented for the model specified by option {opt model(model)}. The first time period in the estimation sample is treated as the base period
unless options {opt nolevel} and {cmd:model(fodev)} are jointly specified, in which case the last time period is treated as the base period. 

{phang}
{opt noconstant}; see {helpb estimation options##noconstant:[R] estimation options}.

{marker vcetype}{...}
{dlgtab:SE/Robust}

{phang}
{opt vce}{cmd:(}{it:vcetype} [{cmd:,} {opt m:odel(model)} {opt wc}|{opt dc}]{cmd:)} specifies the type of standard error reported, which includes types that are derived from asymptotic theory ({opt conventional}),
that are robust to some kinds of misspecification ({opt r:obust}), and that allow for intragroup correlation ({opt cl:uster} {it:clustvar}). {it:model} is allowed to be {opt l:evel}, {opt d:ifference}, {opt fod:ev}, {opt md:ev}, or {opt m:ean}.

{pmore}
{cmd:vce(conventional)} uses the conventionally derived variance estimator. It is robust to some kinds of misspecification if the two-step GMM estimator is used or if nonlinear moment conditions are employed.
After one-step estimation, the error variance is by default computed from the level residuals, {cmd:model(level)}, unless it is specified that it is to be computed from the residuals in first differences, {cmd:model(difference)},
the residuals in forward-orthogonal deviations, {cmd:model(fodev)}, the residuals in deviations from within-group means, {cmd:model(mdev)}, or the within-group means of the residuals, {cmd:model(mean)}.
The sandwich estimator is used for one-step GMM estimation with nonlinear moment conditions, but without the Windmeijer (2005) correction. {cmd:vce(conventional)} is the default, although in most cases {cmd:vce(robust)} would be recommended.

{pmore}
{cmd:vce(robust)} and {cmd:vce(cluster} {it:clustvar}{cmd:)} use the sandwich estimator for one-step GMM estimation with only linear moment conditions. Suboption {opt wc}, the default, applies the Windmeijer (2005) finite-sample correction
to the conventional two-step or iterated GMM estimator. For GMM estimation with nonlinear moment conditions, the sandwich estimator with the respective Windmeijer (2005) correction is computed for one-step, two-step, and iterated estimation.
Alternatively, the Lee (2014), Hansen and Lee (2021), and Hwang, Kang, and Lee (2022) doubly-corrected misspecification-robust standard errors are available with suboption {opt dc}.
No correction is applied for continuously-updating GMM estimation. {cmd:vce(robust)} is equivalent to {cmd:vce(cluster} {it:panelvar}{cmd:)}.

{phang}
{opt small} requests that a degrees-of-freedom adjustment be made to the variance-covariance matrix and that small-sample t and F statistics be reported.
The adjustment factor is (N-1)/(N-K) * M/(M-1), where N is the number of observations, M the number of clusters specified with {cmd:vce(cluster} {it:clustvar}{cmd:)}, and K the number of coefficients.
When option {opt nolevel} is specified, the adjustment factor is corrected for the reduction of time periods in the transformed model or the absorbed group-specific effects.
By default, no degrees-of-freedom adjustment is made and z and Wald statistics are reported. This option does not affect the computation of the optimal weighting matrix.

{dlgtab:Reporting}

{phang}
{opt overid} requests to compute the overidentification statistics for the reduced models, leaving out one subset of moment conditions at a time.
These statistics can subsequently be used to compute Sargan-Hansen difference tests of the overidentifying restrictions with the postestimation command {cmd:estat overid}; see {helpb xtdpdgmm postestimation##estat:xtdpdgmm postestimation}.
This option is not needed to compute the Sargan-Hansen test for the full model.

{phang}
{opt auxiliary} displays all coefficients as auxiliary parameters and suppresses display of the {it:vcetype}. This option is seldom used.
It allows the subsequent use of postestimation commands that require equation-level scores; see {helpb suest:[R] suest}.

{phang}
{opt level(#)}; see {helpb estimation options##level():[R] estimation options}.

{phang}
{opt coeflegend}; see {helpb estimation options##coeflegend:[R] estimation options}.

{phang}
{opt noheader} suppresses display of the header above the coefficient table that displays the number of observations and moment conditions.

{phang}
{opt notable} suppresses display of the coefficient table.

{phang}
{opt nofooter} suppresses display of the footer below the coefficient table that displays the instruments corresponding to the linear moment conditions.

{marker display_options}{...}
{phang}
{it:display_options}: {opt noci}, {opt nopv:alues}, {opt noomit:ted}, {opt vsquish}, {opt noempty:cells}, {opt base:levels}, {opt allbase:levels}, {opt nofvlab:el}, {opt fvwrap(#)}, {opt fvwrapon(style)}, {opth cformat(%fmt)},
{opt pformat(%fmt)}, {opt sformat(%fmt)}, and {opt nolstretch}; see {helpb estimation options##display_options:[R] estimation options}.

{dlgtab:Minimization}

{phang}
{opt noanalytic} requests that the coefficient estimates are obtained numerically instead of using analytical closed-form solutions. This option is seldom used.
It is implied when the model contains nonlinear moment conditions under the option {opt nl(nl_spec)} or if the continuously-updating GMM estimator is used, because closed-form solutions do not exist in this case.

{phang}
{opt from(init_specs)} specifies initial values for the coefficients; see {helpb maximize:[R] maximize}. By default, initial values are set to zero unless the continuously-updating GMM estimator is used.
In the latter case, the default initial values are the two-stage least squares estimates, ignoring any nonlinear moment conditions.

{phang}
{opt nodots} specifies that an iteration log is displayed instead of dots. By default, one dot character is displayed for each step of the iterated GMM estimator.
For the one-step and two-step estimator, display of an iteration log is the default.

{marker igmm_options}{...}
{phang}
{it:igmm_options}: {opt igmmit:erate(#)}, {opt igmmeps(#)}, and {opt igmmweps(#)}; see {helpb gmm:[R] gmm}. These options are seldom used and only have an effect if the iterated GMM estimator is used.

{marker minimize_options}{...}
{phang}
{it:minimize_options}: {opt iter:ate(#)}, {opt nolo:g}, {opt showstep}, {opt showtol:erance}, {opt tol:erance(#)}, {opt ltol:erance(#)}, {opt nrtol:erance(#)}, and {opt nonrtol:erance}; see {helpb maximize:[R] maximize}.
These options are seldom used.


{marker remarks}{...}
{title:Remarks}

{pstd}
Remarks are presented under the following headings:

{phang2}{help xtdpdgmm##remarks_model:Model transformations}{p_end}
{phang2}{help xtdpdgmm##remarks_iv:Instrument transformations}{p_end}
{phang2}{help xtdpdgmm##remarks_exogenous:Strictly exogenous, predetermined, and endogenous variables}{p_end}
{phang2}{help xtdpdgmm##remarks_nl:Nonlinear moment conditions}{p_end}
{phang2}{help xtdpdgmm##remarks_collapse:Curtailing and collapsing of the instruments}{p_end}
{phang2}{help xtdpdgmm##remarks_rescale:Rescaling of the moment conditions}{p_end}
{phang2}{help xtdpdgmm##remarks_teffects:Time effects}{p_end}
{phang2}{help xtdpdgmm##remarks_invariant:Time-invariant regressors}{p_end}


{marker remarks_model}{...}
{title:Model transformations}

{pstd}
{cmd:xtdpdgmm} estimates panel data models of the type

{pmore2}
y = X b + u + e

{pstd}
referred to as the untransformed model, {cmd:model(level)}, where y denotes the vector containing all observations of {it:depvar}, X the matrix of {it:indepvars}, b the regression coefficients, u the group-specific error component,
and e the idiosyncratic error component. To remove the group-specific error component, a model transformation D can be applied which is orthogonal to u (i.e. D u = 0):

{pmore2}
D y = D X b + D e

{pstd}
Matrix D can yield a first-difference transformation, {cmd:model(difference)}, forward-orthogonal deviations, {cmd:model(fodev)}, deviations from within-group means, {cmd:model(mdev)}, or within-group means, {cmd:model(mean)}.

{pstd}
Instrumental variables can be specified for the untransformed model and/or for one or more of the transformed models. However, it is important to keep in mind that the estimation is not performed separately for different models.
In fact, instead of transforming the estimation equation, {cmd:xtdpdgmm} internally transforms the instruments Z for the transformed models back into instruments for the untransformed model.
Technically, this is achieved by forming instruments D' Z for the untransformed model, where D' is the transpose of the above transformation matrix.

{pstd}
These transformed instruments D' Z can be obtained as new Stata variables with option {opt iv} of the postestimation command {cmd:predict}; see {helpb xtdpdgmm postestimation##predict:xtdpdgmm postestimation}.
The new variables could subsequently be used as standard instruments to replicate the {cmd:xtdpdgmm} results with alternative Stata commands such as {cmd:ivregress}; see {helpb ivregress:[R] ivregress}.


{marker remarks_iv}{...}
{title:Instrument transformations}

{pstd}
The model transformations should not be confused with transformations of the instrumental variables. To specify first-differenced instruments D Z for the first-differenced model,
the options {opt difference} and {cmd:model(difference)} need to be combined. Internally, {cmd:xtdpdgmm} then constructs transformed instruments D' D Z for the untransformed model as explained above.

{pstd}
Taking lags and first differences of a variable is interchangeable such that the specifications {cmd:iv(L}{it:#}{cmd:D.(}{it:varlist}{cmd:))}, {cmd:iv(L}{it:#}{cmd:.(}{it:varlist}{cmd:), d)}, {cmd:iv(D.(}{it:varlist}{cmd:), l(}{it:#}{cmd:))},
and {cmd:iv(}{it:varlist}{cmd:, d l(}{it:#}{cmd:))} all create identical instruments. This is not true for the combination of lags and backward-orthogonal deviations.
The specification {cmd:iv(L}{it:#}{cmd:.(}{it:varlist}{cmd:), bod m(fod))} creates backward-orthogonal deviations of the {it:#}-th lag of {it:varlist}, as suggested by Hayakawa, Qi, and Breitung (2019),
while {cmd:iv(}{it:varlist}{cmd:, bod l(}{it:#}{cmd:) m(fod))} creates the {it:#}-th lag of the backward-orthogonal deviations of {it:varlist}.


{marker remarks_exogenous}{...}
{title:Strictly exogenous, predetermined, and endogenous variables}

{pstd}
Strictly exogenous variables are variables that are uncorrelated with the idiosyncratic error component of all time periods.
Predetermined variables, also referred to as weakly exogenous variables, are variables that are uncorrelated with the idiosyncratic error component of the current and all following time periods but which might be correlated with past errors.
Endogenous variables are variables that are uncorrelated with the idiosyncratic error component of all following time periods but which might be correlated with current or past errors.

{pstd}
Strictly exogenous variables are valid instruments with {cmd:lagrange(. .)} for any model transformation.
Predetermined variables are valid instruments with {cmd:lagrange(0 .)} for {cmd:model(level)} or {cmd:model(fodev)}, but only {cmd:lagrange(1 .)} for {cmd:model(difference)}.
Endogenous variables are valid instruments with {cmd:lagrange(1 .)} for {cmd:model(level)} or {cmd:model(fodev)}, but only {cmd:lagrange(2 .)} for {cmd:model(difference)}.

{pstd}
If the idiosyncratic error term is serially correlated in the untransformed model, the classification of variables into these three groups can become problematic.
Some variables might become correlated with the error term in the following periods, which would require an adjustment of the valid lag range.
As a general rule, if the serial correlation of the idiosyncratic error term in levels is of order {it:#}, then the starting lag needs to be increased by {it:#} as well.
Alternatively, the list of {it:indepvars} could be amended to obtain a dynamically complete model with serially uncorrelated errors.

{pstd}
Variables are only valid instruments for the untransformed model, {cmd:model(level)}, or the model in within-group means, {cmd:model(mean)}, if they are uncorrelated with the group-specific error component.
This might often be an unreasonable assumption if the instruments are not first-differenced with option {opt difference}, as proposed by Blundell and Bond (1998).
However, there is no guarantee that first-differenced instruments for the untransformed model are uncorrelated with the group-specific error component. This remains an assumption to be justified by the user.

{pstd}
When instruments are combined for multiple model transformations, some of them might become redundant.
A model specification approach that sequentially classifies variables as endogenous, predetermined, or strictly exogenous is proposed by Kiviet (2020).


{marker remarks_nl}{...}
{title:Nonlinear moment conditions}

{pstd}
A serially uncorrelated idiosyncratic error term in the model in levels is a necessary condition for the validity of the instruments in most dynamic panel data models.
In that case, the nonlinear moment conditions added by the option {cmd:nl(noserial)} only require the mild additional assumption that both the group-specific error component and the initial observations of {it:varlist} and {it:indepvars} are
uncorrelated with the first-differenced idiosyncratic error component. The moment conditions added by the option {cmd:nl(iid)} require an additional homoskedasticity assumption.
Both types of nonlinear moment conditions were proposed by Ahn and Schmidt (1995).

{pstd}
When there is evidence that the idiosyncratic error term is serially correlated, valid nonlinear moment conditions could still be formed by choosing a minimum lag of the first-differenced error term in the nonlinear moment conditions
by specifying {cmd:nl(noserial, lag(}{it:#}{cmd:))}. If the serial correlation of the idiosyncratic error term in levels is of order {it:#} minus 1, then {opt lag(#)} would still produce valid moment conditions.

{pstd}
Chudik and Pesaran (2022) proposed alternative nonlinear moment conditions, which are added by the option {cmd:nl(predetermined)}. In addition to a serially uncorrelated idiosyncratic error term, they require that all {it:indepvars} are
predetermined or strictly exogenous. It further requires that the deviations of the initial observations of {it:depvar} from its long-run mean are uncorrelated with the first-differenced idiosyncratic error component.
This is a weaker assumption than the corresponding requirement for {cmd:nl(noserial)} on the group-specific error component and the initial observations.
Under an additional homoskedasticity assumption, the nonlinear moment conditions proposed by Chudik and Pesaran (2022) can be replaced by linear moment conditions with the {cmd:gmmiv()} suboption {opt iid}.

{pstd}
Adding the nonlinear moment conditions might improve the (asymptotic) efficiency of the GMM estimator and could help to identify the coefficients.
However, the {cmd:nl(noserial)} or {cmd:nl(predetermined)} moment conditions might become redundant if instruments for {cmd:model(level)} in the spirit of Blundell and Bond (1998) are added.

{pstd}
Even if the weighting matrix for the one-step GMM estimator was optimal in the absence of nonlinear moment conditions, after adding them it is no longer optimal.
For efficient estimation, the two-step, iterated, or continuously-updating GMM estimator should be used.
It is not recommended to use the {opt noconstant} option in combination with {cmd:nl(noserial)} or {cmd:nl(iid)} even if all other moment conditions refer to transformed models.

{pstd}
{cmd:xtdpdgmm} minimizes the GMM criterion function numerically with the Gauss-Newton technique if some of the moment conditions are nonlinear, if the continuously-updating GMM estimator is used, or if the option {cmd:noanalytic} is specified.
Otherwise, the estimates are obtained from the analytical closed-form solutions of the first-order conditions.


{marker remarks_collapse}{...}
{title:Curtailing and collapsing of the instruments}

{pstd}
Depending on the specification, the number of GMM-type instruments grows linearly or quadratically in the number of time periods. The total number of moment conditions thus easily becomes large relative to the number of groups in the sample.
As summarized by Roodman (2009), such an instrument proliferation can have severe consequences including biased coefficient and standard error estimates and weakened specification tests.

{pstd}
The most common approaches to reduce the number of instruments, as discussed by Roodman (2009) and Kiviet (2020), are curtailing the lags used to form GMM-type instruments with the {cmd:lagrange()} suboption,
or collapsing the GMM-type into standard instruments with the {cmd:collapse} suboption. The latter approach can also be applied to the nonlinear moment conditions which effectively creates a sum over all time-specific moment conditions.


{marker remarks_rescale}{...}
{title:Rescaling of the moment conditions}

{pstd}
The moment conditions under deviations from within-group means with suboption {cmd:model(mdev)} are rescaled by the square root of the ratio {it:T_i} / ({it:T_i} - 1), where {it:T_i} is the number of observations for group {it:i},
unless the option {cmd:norescale} is specified. This ensures that the variance of the error term is left unchanged by the transformation under the assumption that the untransformed error term is independent and identically distributed.
Similarly, the moment conditions for the model in within-group means with suboption {cmd:model(mean)} are rescaled by the square root of {it:T_i}.
Rescaling for {cmd:model(mdev)} or {cmd:model(mean)} has no effect with balanced panel data.

{pstd}
For the moment conditions under forward-orthogonal deviations with suboption {cmd:model(fodev)}, a scaling factor with the same purpose was suggested by Arellano and Bover (1995).
A similar factor is also used to rescale the instrumental variables under backward-orthogonal deviations with suboption {cmd:bodev} and to rescale the nonlinear moment conditions specified with option {cmd:nl(iid)}.
This rescaling can be switched off again with the option {cmd:norescale}.


{marker remarks_teffects}{...}
{title:Time effects}

{pstd}
The option {opt teffects} adds dummy variables {cmd:i.}{it:timevar}, after removing collinear dummies, to {it:indepvars} and as standard instruments for the untransformed model, {cmd:iv(i.}{it:timevar}{cmd:, model(level))}.
This may not be desired in some cases if all other moment conditions refer to transformed models, for example if the weighting matrix of the one-step GMM estimator for the transformed model is already optimal,
which typically requires a homoskedasticity assumption. In this case, the option {opt nolevel} can be used to create standard instruments for the transformed model instead.

{pstd}
Time dummies and their instruments can also be specified manually. However, they should generally only be specified as instruments for a single model transformation or the untransformed model, not both.
Otherwise, some of these instruments would be (asymptotically) redundant.


{marker remarks_invariant}{...}
{title:Time-invariant regressors}

{pstd}
If time-invariant regressors are included in {it:indepvars}, the identification of their coefficients requires at least as many instruments specified for {cmd:model(level)} or {cmd:model(mean)} as there are time-invariant regressors.
These should generally be in addition to any first-differenced instruments or time dummies to avoid spurious estimates of those coefficients, as discussed by Kripfganz and Schwarz (2019).


{marker example}{...}
{title:Example}

{pstd}Setup{p_end}
{phang2}. {stata webuse abdata}{p_end}

{pstd}Anderson-Hsiao IV estimators with strictly exogenous covariates{p_end}
{phang2}. {stata xtdpdgmm L(0/1).n w k, iv(L2.n w k, d) m(d) nocons}{p_end}
{phang2}. {stata xtdpdgmm L(0/1).n w k, iv(L2.n) iv(w k, d) m(d) nocons}{p_end}

{pstd}Arellano-Bond one-step GMM estimator with strictly exogenous covariates and curtailed/collapsed instruments{p_end}
{phang2}. {stata xtdpdgmm L(0/1).n w k, gmm(L.n, l(1 4)) iv(w k, d) m(d) c nocons}{p_end}

{pstd}Arellano-Bover two-step GMM estimator with predetermined covariates and curtailed/collapsed instruments{p_end}
{phang2}. {stata xtdpdgmm L(0/1).n w k, gmm(L.n w k, l(0 3)) m(fod) c two vce(r)}{p_end}

{pstd}Ahn-Schmidt two-step GMM estimators with predetermined covariates and curtailed/collapsed instruments{p_end}
{phang2}. {stata xtdpdgmm L(0/1).n w k, gmm(L.n w k, l(1 4)) m(d) nl(noser) c two vce(r)}{p_end}
{phang2}. {stata xtdpdgmm L(0/1).n w k, gmm(L.n w k, l(1 4)) m(d) nl(iid) c two vce(r)}{p_end}

{pstd}Chudik-Pesaran two-step GMM estimator with predetermined covariates and curtailed/collapsed instruments{p_end}
{phang2}. {stata xtdpdgmm L(0/1).n w k, gmm(L.n w k, d l(1 4)) m(d) nl(pre) c two vce(r)}{p_end}

{pstd}Blundell-Bond two-step, iterated, and continuously-updating GMM estimators with predetermined covariates and curtailed/collapsed instruments{p_end}
{phang2}. {stata xtdpdgmm L(0/1).n w k, gmm(L.n w k, l(1 4) m(d)) iv(L.n w k, d) c two vce(r)}{p_end}
{phang2}. {stata xtdpdgmm L(0/1).n w k, gmm(L.n w k, l(1 4) m(d)) iv(L.n w k, d) c igmm vce(r)}{p_end}
{phang2}. {stata xtdpdgmm L(0/1).n w k, gmm(L.n w k, l(1 4) m(d)) iv(L.n w k, d) c cu}{p_end}

{pstd}Hayakawa-Qi-Breitung IV estimator with predetermined covariates{p_end}
{phang2}. {stata xtdpdgmm L(0/1).n w k, iv(L.n w k, bod) m(fod) nocons}{p_end}

{pstd}Replication of a static (weighted) fixed-effects estimator{p_end}
{phang2}. {stata xtdpdgmm n w k, iv(w k) m(md)}{p_end}
{phang2}. {stata "by id: egen weight = count(e(sample))"}{p_end}
{phang2}. {stata replace weight = sqrt(weight/(weight-1))}{p_end}
{phang2}. {stata xtreg n w k [aw=weight], fe}{p_end}

{pstd}Replication of a static (unweighted) fixed-effects estimator{p_end}
{phang2}. {stata xtdpdgmm n w k, iv(w k) m(md) nores}{p_end}
{phang2}. {stata xtreg n w k, fe}{p_end}


{marker results}{...}
{title:Saved results}

{pstd}
{cmd:xtdpdgmm} saves the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(df_r)}}residual degrees of freedom; not always saved{p_end}
{synopt:{cmd:e(N_g)}}number of groups{p_end}
{synopt:{cmd:e(N_clust)}}number of clusters{p_end}
{synopt:{cmd:e(g_min)}}smallest group size{p_end}
{synopt:{cmd:e(g_avg)}}average group size{p_end}
{synopt:{cmd:e(g_max)}}largest group size{p_end}
{synopt:{cmd:e(f)}}value of the objective function{p_end}
{synopt:{cmd:e(chi2_J)}}Hansen's J-statistic{p_end}
{synopt:{cmd:e(chi2_J_u)}}Hansen's J-statistic with updated weighting matrix; not always saved{p_end}
{synopt:{cmd:e(rank)}}rank of {cmd:e(V)}{p_end}
{synopt:{cmd:e(zrank)}}number of linear moment functions{p_end}
{synopt:{cmd:e(zrank_nl)}}number of nonlinear moment functions{p_end}
{synopt:{cmd:e(df_a)}}absorbed degrees of freedom; not always saved{p_end}
{synopt:{cmd:e(sigma2e)}}estimate of sigma_e^2; not always saved{p_end}
{synopt:{cmd:e(steps)}}number of steps{p_end}
{synopt:{cmd:e(ic)}}number of iterations in final step{p_end}
{synopt:{cmd:e(converged)}}= {cmd:1} if convergence achieved, {cmd:0} otherwise{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xtdpdgmm}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(ivar)}}variable denoting groups{p_end}
{synopt:{cmd:e(tvar)}}variable denoting time{p_end}
{synopt:{cmd:e(estat_cmd)}}{cmd:xtdpdgmm_estat}{p_end}
{synopt:{cmd:e(predict)}}{cmd:xtdpdgmm_p}{p_end}
{synopt:{cmd:e(marginsok)}}predictions allowed by {cmd:margins}{p_end}
{synopt:{cmd:e(teffects)}}time effects created with option {cmd:teffects}{p_end}
{synopt:{cmd:e(wmatrix)}}{it:wmat_spec} specified with option {cmd:wmatrix()}{p_end}
{synopt:{cmd:e(estimator)}}{cmd:onestep}, {cmd:twostep}, or {cmd:igmm}{p_end}
{synopt:{cmd:e(clustvar)}}name of cluster variable{p_end}
{synopt:{cmd:e(vce)}}{cmd:conventional} or {cmd:robust}{p_end}
{synopt:{cmd:e(vcetype)}}title used to label Std. Err.{p_end}
{synopt:{cmd:e(vcecor)}}type of variance correction; not always saved{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}
{synopt:{cmd:e(V_modelbased)}}model-based variance; not always saved{p_end}
{synopt:{cmd:e(W)}}weighting matrix{p_end}
{synopt:{cmd:e(ilog)}}iteration log (up to 20 iterations){p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}


{marker update}{...}
{title:Version history and updates}

{pstd}{cmd:xtdpdgmm} is a community-contributed program. To determine the currently installed version, type{p_end}
{phang2}. {stata which xtdpdgmm, all}{p_end}

{pstd}To update the {cmd:xtdpdgmm} package to the latest version, type{p_end}
{phang2}. {stata `"net install xtdpdgmm, from("http://www.kripfganz.de/stata/") replace"'}{p_end}

{pstd}If the connection to the previous website fails, alternatively type{p_end}
{phang2}. {stata ssc install xtdpdgmm, replace}{p_end}

{pstd}
The SSC version is less frequently updated and may not be the latest available version. The current version of the {cmd:xtdpdgmm} package requires Stata version 13 or higher.
For backward compatibility and replicability of results obtained with earlier versions, the following older versions can be installed as well. Note that these versions may use different syntax and may still contain bugs
that were fixed in subsequent versions. If you intend to install different versions alongside each other, you can set different installation paths with {cmd:net set ado} {it:dirname}; see {helpb net:[R] net}.

{pstd}To install the {cmd:xtdpdgmm} version 1.1.3 as of 24sep2018, requiring Stata version 12.1 or higher, type{p_end}
{phang2}. {stata `"net install xtdpdgmm, from("http://www.kripfganz.de/stata/xtdpdgmm_v1/")"'}{p_end}


{marker author}{...}
{title:Author}

{pstd}
Sebastian Kripfganz, University of Exeter, {browse "http://www.kripfganz.de"}


{title:Acknowledgement}

{pstd}
The development of this program benefited from discussions with the Stata community, with special thanks to Mark E. Schaffer for numerous helpful comments.


{marker references}{...}
{title:References}

{phang}
Ahn, S. C., and P. Schmidt. 1995.
Efficient estimation of models for dynamic panel data.
{it:Journal of Econometrics} 68: 5-27.

{phang}
Anderson, T. W., and C. Hsiao. 1981.
Estimation of dynamic models with error components.
{it:Journal of the American Statistical Association} 76: 598-606.

{phang}
Arellano, M., and S. R. Bond. 1991.
Some tests of specification for panel data: Monte Carlo evidence and an application to employment equations.
{it:Review of Economic Studies} 58: 277-297.

{phang}
Arellano, M., and O. Bover. 1995.
Another look at the instrumental variable estimation of error-components models.
{it:Journal of Econometrics} 68: 29-51.

{phang}
Blundell, R., and S. R. Bond. 1998.
Initial conditions and moment restrictions in dynamic panel data models.
{it:Journal of Econometrics} 87: 115-143.

{phang}
Chudik, A., and M. H. Pesaran. 2022.
An augmented Anderson-Hsiao estimator for dynamic short-T panels.
{it:Econometric Reviews} 41: 416-447.

{phang}
Hansen, B. E., and S. Lee. 2021.
Inference for iterated GMM under misspecification.
{it:Econometrica} 89: 1419-1447.

{phang}
Hansen, L. P., J. Heaton, and A. Yaron. 1996.
Finite-sample properties of some alternative GMM estimators.
{it:Journal of Business & Economic Statistics} 14: 262-280.

{phang}
Hayakawa, K., M. Qi, and J. Breitung. 2019.
Double filter instrumental variable estimation of panel data models with weakly exogenous variables.
{it:Econometric Reviews} 38: 1055-1088.

{phang}
Hwang, J., B. Kang, and S. Lee. 2022.
A doubly corrected robust variance estimator for linear GMM.
{it:Journal of Econometrics} 229: 276-298.

{phang}
Kiviet, J. F. 2020.
Microeconometric dynamic panel data methods: Model specification and selection issues.
{it:Econometrics and Statistics} 13: 16-45.

{phang}
Kripfganz, S., and C. Schwarz. 2019.
Estimation of linear dynamic panel data models with time-invariant regressors.
{it:Journal of Applied Econometrics} 34: 526-546.

{phang}
Lee, S. 2014.
Asymptotic refinements of a misspecification-robust bootstrap for generalized method of moments estimators.
{it:Journal of Applied Econometrics} 178: 398-413.

{phang}
Roodman, D. 2009.
A note on the theme of too many instruments.
{it:Oxford Bulletin of Economics and Statistics} 71: 135-158.

{phang}
Windmeijer, F. 2005.
A finite sample correction for the variance of linear efficient two-step GMM estimators.
{it:Journal of Econometrics} 126: 25-51.
