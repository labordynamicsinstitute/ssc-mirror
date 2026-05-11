{smcl}
{* *! version 1.0.0 11 May 2026}{...}
{viewerjumpto "Syntax" "qresid##syntax"}{...}
{viewerjumpto "Description" "qresid##description"}{...}
{viewerjumpto "Links to GitHub documentation" "qresid##githubdocs"}{...}
{viewerjumpto "Options" "qresid##options"}{...}
{viewerjumpto "Supported models" "qresid##supported"}{...}
{viewerjumpto "Examples" "qresid##examples"}{...}
{viewerjumpto "Stored results" "qresid##results"}{...}
{viewerjumpto "Methods and formulas" "qresid##methods"}{...}
{viewerjumpto "Limitations" "qresid##limitations"}{...}
{viewerjumpto "References" "qresid##references"}{...}
{viewerjumpto "Also see" "qresid##alsosee"}{...}

{title:Title}

{p 4 4 2}
{bf:qresid} {hline 2} Randomized quantile residuals for regression diagnostics in Stata

{p 4 4 2}
Requires Stata 15.0 or newer.


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:qresid} {it:newvarname} {ifin}
[{cmd:,} {it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{cmd:seed(}{it:integer}{cmd:)}}set random-number seed before drawing randomized PIT values{p_end}
{synopt:{cmd:uvar(}{it:varname}{cmd:)}}use externally supplied uniform values for discrete residuals{p_end}
{synopt:{cmd:type(}{it:string}{cmd:)}}select {cmd:quantile}, {cmd:adjusted}, or {cmd:studentized}{p_end}
{synopt:{cmd:dispersion(}{it:#}{cmd:)}}use a fixed positive dispersion for Gamma or inverse Gaussian CDFs{p_end}
{synopt:{cmd:family(}{it:string}{cmd:)}}require {cmd:qresid}'s inferred family to match {it:string}{p_end}
{syntab:Saved quantities}
{synopt:{cmd:saveflo(}{it:name}{cmd:)}}save {it:F_low}, the lower fitted CDF endpoint{p_end}
{synopt:{cmd:savefhi(}{it:name}{cmd:)}}save {it:F_high}, the upper fitted CDF endpoint{p_end}
{synopt:{cmd:saveu(}{it:name}{cmd:)}}save {it:U}, the final PIT value before {cmd:invnormal()}{p_end}
{synopt:{cmd:savev(}{it:name}{cmd:)}}save {it:V}, the base uniform value used within a discrete CDF interval{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:qresid} implements randomized quantile residuals (Dunn-Smyth residuals)
for regression diagnostics in supported independent regression models in
Stata. The package is intended for generalized linear and related models where
conventional residuals may be difficult to interpret. These residuals are also
known as probability integral transform (PIT) residuals on the normal scale;
for discrete outcomes, the randomized version is commonly called a randomized
quantile residual (RQR).

{pstd}
For continuous outcomes, the fitted PIT value is
{it:U_i = F_i(y_i;theta_hat)}. For discrete outcomes, the fitted CDF has jumps.
{cmd:qresid} uses the Dunn-Smyth randomized construction: it computes
{it:F_low = P(Y_i < y_i)} and {it:F_high = P(Y_i <= y_i)}, draws or accepts a
uniform value {it:V_i} in [0,1], sets
{it:U_i = F_low + V_i(F_high-F_low)}, and reports
{it:Phi^-1(U_i)}; see Dunn and Smyth (1996) in {help qresid##references:References}.

{pstd}
The resulting residual is already on an approximate standard-normal scale.
That common scale is the practical advantage of quantile residuals: Gaussian,
count, binary, positive continuous, and other supported specifications can be
inspected with familiar tools such as {cmd:qnorm}, much as ordinary normal-theory
residuals are inspected after linear regression.

{pstd}
For discrete outcomes with few possible values, Pearson and deviance residuals
can show strong discreteness, skewness, or artificial curvature even when a
model is adequate. Quantile residuals instead use the full fitted conditional
distribution. The same principle applies to zero-inflated, truncated, censored,
and hurdle or mixture count models, but the CDF must then include the extra
mass at zero, the restricted support, the censoring interval, or the two-part
mixture structure; see Dunn and Smyth (1996), Feng, Li, and Sadeghpour (2020),
and Bai et al. (2021).

{pstd}
A Q-Q plot mainly checks whether the fitted conditional distribution is
compatible with the observed responses on the normal-quantile scale. Residuals
plotted against fitted values or covariates can suggest problems in the fitted
mean, link, dispersion, support, offset/exposure, weights, or dependence,
because each of these affects the fitted conditional CDF. These plots are
diagnostic aids, not formal proof of model correctness; see Cox and Snell
(1968), Dunn and Smyth (1996), and Warton, Thibaut, and Wang (2017).


{marker githubdocs}{...}
{title:Links to GitHub documentation}

{pstd}
The installed help file gives the command syntax, options, examples, methods,
and limitations. Extended examples, validation summaries, and release notes are
maintained in the GitHub repository.

{synoptset 30 tabbed}{...}
{synopthdr:resource}
{synoptline}
{synopt:{browse "https://github.com/psotob91/qresid#readme":README and overview}}package overview, installation, quick start, and citation{p_end}
{synopt:{browse "https://github.com/psotob91/qresid/blob/main/docs/README.md":Extended manual}}tutorial index and reproduction notes{p_end}
{synopt:{browse "https://github.com/psotob91/qresid/blob/main/docs/supported-specifications.md":Supported specifications}}public support scope for this release{p_end}
{synopt:{browse "https://github.com/psotob91/qresid/blob/main/docs/validation.md":Validation evidence}}validation summary and benchmark links{p_end}
{synopt:{browse "https://github.com/psotob91/qresid/blob/main/changelog/CHANGELOG.md":News and changelog}}release notes and documentation changes{p_end}
{synoptline}


{marker options}{...}
{title:Options}

{phang}
{cmd:seed(}{it:integer}{cmd:)} sets Stata's random-number seed before drawing
uniform values for randomized residuals. It affects only model specifications
where randomization is needed.

{phang}
{cmd:uvar(}{it:varname}{cmd:)} supplies {it:V}, the uniform value used to
choose a point inside the CDF interval [{it:F_low}, {it:F_high}] for discrete
outcomes. Values must be in [0,1] for observations used by the model. This is
useful for reproducible analyses and transparent diagnostic checks.

{phang}
{cmd:saveflo(}{it:name}{cmd:)} saves {it:F_low}. For a discrete outcome this is
{it:P(Y_i < y_i)}. For a continuous outcome it is the fitted CDF at the observed
response, up to numerical endpoint handling.

{phang}
{cmd:savefhi(}{it:name}{cmd:)} saves {it:F_high}. For a discrete outcome this
is {it:P(Y_i <= y_i)}. For continuous outcomes {it:F_low} and {it:F_high} are
the same fitted PIT value except for numerical safeguards.

{phang}
{cmd:saveu(}{it:name}{cmd:)} saves {it:U}, the final PIT value used before
applying {cmd:invnormal()}. For discrete outcomes, {it:U} lies inside
[{it:F_low}, {it:F_high}].

{phang}
{cmd:savev(}{it:name}{cmd:)} saves {it:V}, the base uniform value used to form
{it:U} for discrete outcomes. For continuous outcomes it is not needed for the
mathematical construction.

{phang}
{cmd:type(quantile)} is the default Dunn-Smyth normal-score quantile residual.
{cmd:type(adjusted)} creates the validated leverage-adjusted residual
{it:r_i}/sqrt(1-{it:h_i}), where {it:r_i} is the base quantile residual and
{it:h_i} is obtained from {cmd:predict, hat}. {cmd:type(studentized)} is an
exact alias for {cmd:type(adjusted)} on the same supported specifications.
Other adjusted/studentized specifications exit with an informative error.

{phang}
{cmd:dispersion(}{it:#}{cmd:)} uses a fixed positive dispersion in the fitted
CDF for {cmd:glm, family(gamma)} and {cmd:glm, family(igaussian)}. It does not
refit the model or change the fitted means. If omitted, {cmd:qresid} uses the
dispersion stored by Stata after estimation. For Gamma and inverse Gaussian
GLMs, this is Stata's postestimation scale parameter. For Poisson and binomial
models the scale is fixed by the likelihood. For negative-binomial models the
analogous quantities are the estimated ancillary parameters, such as alpha,
theta, or delta, and they are not set with {cmd:dispersion()}.

{phang}
{cmd:family(}{it:string}{cmd:)} is a check on {cmd:qresid}'s family inference.
For example, {cmd:family(bernoulli)} after {cmd:logit} or {cmd:logistic}
requires {cmd:qresid} to treat the fitted model as Bernoulli. If
{cmd:family()} does not match the fitted model and supported postestimation
specification, {cmd:qresid} exits with an error.


{marker supported}{...}
{title:Supported models}

{pstd}
Support is by Stata estimation command and fitted distribution. A specification
is usable only when the model converges, fitted values are in the
distributional support, and Stata exposes the postestimation quantities needed
by {cmd:qresid}.

{dlgtab:Official Stata commands and external commands}

{synoptset 36 tabbed}{...}
{synopthdr:Command}
{synoptline}
{synopt:{cmd:regress}, {cmd:glm}, {cmd:poisson}}official Stata commands{p_end}
{synopt:{cmd:logit}, {cmd:logistic}, {cmd:binreg}}official Stata commands{p_end}
{synopt:{cmd:nbreg}, {cmd:gnbreg}}official Stata commands{p_end}
{synopt:{cmd:zip}, {cmd:zinb}}official Stata commands{p_end}
{synopt:{cmd:tpoisson}, {cmd:ztp}, {cmd:tnbreg}, {cmd:ztnb}}official Stata commands{p_end}
{synopt:{cmd:cpoisson}}official Stata command{p_end}
{synopt:{cmd:gpoisson}}external Stata Journal command with documented source/version; use {cmd:findit gpoisson} and install separately{p_end}
{synopt:{cmd:hplogit}, {cmd:hnblogit}}external Hilbe/Hardin commands with documented source/version; use {cmd:findit hplogit} or {cmd:findit hnblogit} and install separately{p_end}
{synoptline}

{dlgtab:Continuous families and links}

{synoptset 36 tabbed}{...}
{synopthdr:Family}
{synoptline}
{synopt:Gaussian}available after {cmd:regress} and {cmd:glm, family(gaussian)} with valid fitted means{p_end}
{synopt:Gamma}available after {cmd:glm, family(gamma)} with positive outcomes and fitted means; links include log, inverse-power, and identity when the model converges{p_end}
{synopt:inverse Gaussian}available after {cmd:glm, family(igaussian)} with positive outcomes and fitted means; links include {cmd:power -2}, log, identity, and {cmd:power -1}{p_end}
{synoptline}

{dlgtab:Binary and binomial}

{synoptset 36 tabbed}{...}
{synopthdr:Specification}
{synoptline}
{synopt:Bernoulli}available after {cmd:logit}, {cmd:logistic}, Bernoulli {cmd:binreg}, and Bernoulli {cmd:glm, family(binomial)}{p_end}
{synopt:Bernoulli links}links include logit, probit, cloglog, log, and identity where Stata estimates the model and fitted probabilities are valid{p_end}
{synopt:binomial counts with trials}available after {cmd:glm, family(binomial }{it:trials}{cmd:)} and {cmd:binreg, n(}{it:trials}{cmd:)}{p_end}
{synopt:{cmd:binreg} aliases}available aliases include {cmd:or}, {cmd:rr}, {cmd:rd}, and {cmd:hr}; {cmd:hr} uses Stata-side endpoint validation{p_end}
{synoptline}

{dlgtab:Count models}

{synoptset 36 tabbed}{...}
{synopthdr:Specification}
{synoptline}
{synopt:Poisson}available after {cmd:poisson} and {cmd:glm, family(poisson)}; links include log, identity, and square-root power link where fitted means are valid{p_end}
{synopt:Negative binomial}available after {cmd:nbreg}, including {cmd:dispersion(mean)}, {cmd:dispersion(constant)}, offset, and exposure specifications{p_end}
{synopt:{cmd:gnbreg}}available when observation-specific alpha can be extracted{p_end}
{synopt:fixed-theta GLM NB}available after {cmd:glm, family(nbinomial #)}; {cmd:glm, family(nbinomial ml)} is not currently supported{p_end}
{synopt:Zero-inflated}available after unweighted {cmd:zip} and {cmd:zinb}; the CDF includes the extra probability mass at zero{p_end}
{synopt:Truncated}available after unweighted {cmd:tpoisson}, {cmd:ztp}, {cmd:tnbreg}, and {cmd:ztnb}; the CDF is conditional on the truncated support{p_end}
{synopt:Censored}available after unweighted {cmd:cpoisson}; the PIT uses the fitted CDF interval implied by censoring{p_end}
{synopt:Generalized Poisson}available for the documented external {cmd:gpoisson} command only, without weights{p_end}
{synopt:Hurdle count}available for the documented external {cmd:hplogit} and {cmd:hnblogit} commands only, without weights{p_end}
{synoptline}

{dlgtab:Weights, offset, exposure, and dispersion}

{synoptset 36 tabbed}{...}
{synopthdr:Feature}
{synoptline}
{synopt:{cmd:fweight}}available only on supported specifications: Gaussian, Poisson, Bernoulli, binomial counts with trials, NB, Gamma, and inverse Gaussian{p_end}
{synopt:{cmd:pweight}}available only as a model-based diagnostic for Gaussian, Poisson, and Bernoulli; not {cmd:svy:} support and not an exact survey-design residual{p_end}
{synopt:{cmd:aweight}, {cmd:iweight}}not currently supported{p_end}
{synopt:{cmd:offset()}, {cmd:exposure()}}available for Poisson and supported count specifications where Stata's fitted mean includes the offset or exposure{p_end}
{synopt:{cmd:dispersion(#)}}available only for Gamma and inverse Gaussian {cmd:glm}; changes the CDF used for the residual, not the fitted model{p_end}
{synopt:ancillary parameters}NB alpha/theta, NB1 delta, generalized Poisson delta, zero-inflation probability, truncation/censoring limits, and hurdle probabilities enter the fitted CDF when those specifications are supported{p_end}
{synoptline}


{marker examples}{...}
{title:Examples}

{dlgtab:Continuous outcomes}

{pstd}
Fit a Gaussian regression and create residuals on the normal quantile scale.
{cmd:qnorm} checks whether the fitted conditional distribution gives residuals
that are close to normal; the residual-versus-fitted plot checks for systematic
mean or variance patterns.

{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. regress price mpg}{p_end}
{phang2}{cmd:. qresid rq}{p_end}
{phang2}{cmd:. qnorm rq}{p_end}
{phang2}{cmd:. predict double muhat, xb}{p_end}
{phang2}{cmd:. scatter rq muhat, yline(0)}{p_end}

{pstd}
Create the validated leverage-adjusted form. {cmd:type(studentized)} is an
alias for {cmd:type(adjusted)} where this adjustment is supported.

{phang2}{cmd:. qresid rq_adj, type(adjusted)}{p_end}
{phang2}{cmd:. qresid rq_stu, type(studentized)}{p_end}

{dlgtab:Binomial outcomes}

{pstd}
For Bernoulli outcomes, the residual is randomized within the fitted Bernoulli
CDF jump. {cmd:seed()} makes the randomization reproducible.

{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. generate byte foreign01 = foreign}{p_end}
{phang2}{cmd:. logit foreign01 mpg}{p_end}
{phang2}{cmd:. qresid rq_logit, seed(12345) family(bernoulli)}{p_end}
{phang2}{cmd:. qnorm rq_logit}{p_end}

{pstd}
Alternative binomial links can be inspected on the same normal-quantile scale.

{phang2}{cmd:. glm foreign01 mpg, family(binomial) link(probit)}{p_end}
{phang2}{cmd:. qresid rq_probit, seed(12345)}{p_end}
{phang2}{cmd:. glm foreign01 mpg, family(binomial) link(cloglog)}{p_end}
{phang2}{cmd:. qresid rq_cloglog, seed(12345)}{p_end}

{pstd}
Binomial-count residuals use the observed number of successes and the number
of trials.

{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set obs 60}{p_end}
{phang2}{cmd:. generate double x = (_n-30.5)/30}{p_end}
{phang2}{cmd:. generate int trials = 8 + mod(_n,4)}{p_end}
{phang2}{cmd:. generate int y = floor(trials*invlogit(-.1 + .6*x) + .5)}{p_end}
{phang2}{cmd:. replace y = max(0,min(trials,y))}{p_end}
{phang2}{cmd:. glm y x, family(binomial trials) link(logit)}{p_end}
{phang2}{cmd:. qresid rq_gbinom, seed(12345)}{p_end}
{phang2}{cmd:. qnorm rq_gbinom}{p_end}

{dlgtab:Count outcomes}

{pstd}
For Poisson counts, {cmd:qresid} uses the fitted Poisson CDF. The Q-Q plot
checks whether the fitted count distribution gives approximately normal
quantile residuals.

{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. poisson rep78 mpg if rep78 < .}{p_end}
{phang2}{cmd:. qresid rq_pois, seed(12345) saveflo(flo) savefhi(fhi) saveu(u)}{p_end}
{phang2}{cmd:. qnorm rq_pois}{p_end}

{pstd}
Alternative Poisson links are supported where fitted means remain positive.

{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set obs 100}{p_end}
{phang2}{cmd:. generate double x = (_n-50)/100}{p_end}
{phang2}{cmd:. generate int y = 2 + mod(_n,4)}{p_end}
{phang2}{cmd:. glm y x, family(poisson) link(identity)}{p_end}
{phang2}{cmd:. qresid rq_pois_id, seed(12345)}{p_end}
{phang2}{cmd:. glm y x, family(poisson) link(power .5)}{p_end}
{phang2}{cmd:. qresid rq_pois_sqrt, seed(12345)}{p_end}

{pstd}
Offset and exposure enter through the fitted mean from the estimation command.
{cmd:qresid} does not add them a second time.

{phang2}{cmd:. generate double exposure = .5 + runiform()*2}{p_end}
{phang2}{cmd:. poisson y x, exposure(exposure)}{p_end}
{phang2}{cmd:. qresid rq_pois_exp, seed(12345)}{p_end}
{phang2}{cmd:. generate double lnoffset = ln(exposure)}{p_end}
{phang2}{cmd:. poisson y x, offset(lnoffset)}{p_end}
{phang2}{cmd:. qresid rq_pois_off, seed(12345)}{p_end}

{pstd}
Negative binomial residuals use the fitted mean and auxiliary distribution
parameter from the active {cmd:nbreg} specification.

{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set obs 120}{p_end}
{phang2}{cmd:. set seed 811}{p_end}
{phang2}{cmd:. generate double x = rnormal()}{p_end}
{phang2}{cmd:. generate double mu = exp(.2 + .4*x)}{p_end}
{phang2}{cmd:. generate double exposure = .5 + runiform()*2}{p_end}
{phang2}{cmd:. generate int y = rnbinomial(3, 3/(3+mu))}{p_end}
{phang2}{cmd:. nbreg y x, exposure(exposure) dispersion(mean)}{p_end}
{phang2}{cmd:. qresid rq_nb, seed(12345)}{p_end}
{phang2}{cmd:. qnorm rq_nb}{p_end}

{dlgtab:Positive continuous outcomes}

{pstd}
Gamma and inverse Gaussian residuals use the fitted continuous CDF. The
{cmd:dispersion()} option fixes the dispersion used for the CDF calculation
without refitting the model.

{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set obs 80}{p_end}
{phang2}{cmd:. generate double x = (_n-40)/20}{p_end}
{phang2}{cmd:. generate double y = exp(1 + .25*x)}{p_end}
{phang2}{cmd:. glm y x, family(gamma) link(log)}{p_end}
{phang2}{cmd:. qresid rq_gamma, family(gamma)}{p_end}
{phang2}{cmd:. qresid rq_gamma_phi, dispersion(.5)}{p_end}
{phang2}{cmd:. glm y x, family(gamma) link(power -1)}{p_end}
{phang2}{cmd:. qresid rq_gamma_inv, family(gamma)}{p_end}

{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set obs 80}{p_end}
{phang2}{cmd:. generate double x = (_n-40)/60}{p_end}
{phang2}{cmd:. generate double y = exp(.8 + .25*x) + .2}{p_end}
{phang2}{cmd:. glm y x, family(igaussian) link(log)}{p_end}
{phang2}{cmd:. qresid rq_ig_log, family(igaussian)}{p_end}
{phang2}{cmd:. glm y x, family(igaussian) link(identity)}{p_end}
{phang2}{cmd:. qresid rq_ig_id, family(igaussian)}{p_end}
{phang2}{cmd:. glm y x, family(igaussian) link(power -1)}{p_end}
{phang2}{cmd:. qresid rq_ig_p1, family(igaussian)}{p_end}
{phang2}{cmd:. glm y x, family(igaussian) link(power -2)}{p_end}
{phang2}{cmd:. qresid rq_ig_p2, family(igaussian)}{p_end}

{dlgtab:Weights and external commands}

{pstd}
Frequency weights are available only for documented specifications. They
represent repeated observations in the fitted model; {cmd:qresid} then
evaluates the fitted CDF for each recorded observation.

{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. generate int fw = 1 + mod(_n,3)}{p_end}
{phang2}{cmd:. regress price mpg [fweight=fw]}{p_end}
{phang2}{cmd:. qresid rq_fw}{p_end}
{phang2}{cmd:. qnorm rq_fw}{p_end}

{pstd}
{cmd:pweight} is available only as a model-based diagnostic on selected
specifications. It is not {cmd:svy:} support and is not a survey-design
residual.

{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. generate double pw = max(1, weight/1000)}{p_end}
{phang2}{cmd:. regress price mpg [pweight=pw]}{p_end}
{phang2}{cmd:. qresid rq_pw}{p_end}

{pstd}
Some supported count specifications require external commands with documented
source/version. Install and cite those commands separately before use. The
{cmd:findit} commands below open Stata's search interface; they do not install
the estimators by themselves.

{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set obs 120}{p_end}
{phang2}{cmd:. set seed 13579}{p_end}
{phang2}{cmd:. generate double x = rnormal()}{p_end}
{phang2}{cmd:. generate double mu = exp(.3 + .4*x)}{p_end}
{phang2}{cmd:. generate int y = rpoisson(mu)}{p_end}
{phang2}{cmd:. replace y = 0 if runiform() < .25}{p_end}
{phang2}{cmd:. findit gpoisson}{p_end}
{phang2}{cmd:. capture which gpoisson}{p_end}
{phang2}{cmd:. if !_rc {c -(}}{p_end}
{phang2}{cmd:.     gpoisson y x}{p_end}
{phang2}{cmd:.     qresid rq_gp, seed(12345)}{p_end}
{phang2}{cmd:. {c )-}}{p_end}
{phang2}{cmd:. findit hplogit}{p_end}
{phang2}{cmd:. capture which hplogit}{p_end}
{phang2}{cmd:. if !_rc {c -(}}{p_end}
{phang2}{cmd:.     hplogit y x, nolog}{p_end}
{phang2}{cmd:.     qresid rq_hp, seed(12345)}{p_end}
{phang2}{cmd:. {c )-}}{p_end}
{phang2}{cmd:. findit hnblogit}{p_end}
{phang2}{cmd:. capture which hnblogit}{p_end}
{phang2}{cmd:. if !_rc {c -(}}{p_end}
{phang2}{cmd:.     hnblogit y x, nolog}{p_end}
{phang2}{cmd:.     qresid rq_hnb, seed(12345)}{p_end}
{phang2}{cmd:. {c )-}}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:qresid} stores the following in {cmd:r()}:

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{cmd:r(N)}}estimation-sample observations used by {cmd:qresid}{p_end}
{synopt:{cmd:r(cmd)}}Stata estimation command found in {cmd:e(cmd)}{p_end}
{synopt:{cmd:r(family)}}fitted distributional family used for the CDF{p_end}
{synopt:{cmd:r(type)}}residual scale requested: quantile, adjusted, or studentized alias{p_end}
{synopt:{cmd:r(weight_type)}}Stata estimation weight type, if any{p_end}
{synopt:{cmd:r(weight_status)}}whether the fit was unweighted, supported with weights, or diagnostic{p_end}
{synopt:{cmd:r(dispersion_source)}}whether dispersion came from Stata or from {cmd:dispersion()}{p_end}
{synopt:{cmd:r(depvar)}}dependent variable from the fitted model{p_end}
{synopt:{cmd:r(residual)}}generated residual variable{p_end}
{synopt:{cmd:r(saveflo)}}variable storing {it:F_low}, if requested{p_end}
{synopt:{cmd:r(savefhi)}}variable storing {it:F_high}, if requested{p_end}
{synopt:{cmd:r(saveu)}}variable storing {it:U}, if requested{p_end}
{synopt:{cmd:r(savev)}}variable storing {it:V}, if requested{p_end}
{synopt:{cmd:r(clipped_low)}}number of PIT values numerically moved away from 0{p_end}
{synopt:{cmd:r(clipped_high)}}number of PIT values numerically moved away from 1{p_end}
{synopt:{cmd:r(dispersion)}}user-supplied dispersion, if {cmd:dispersion()} was specified{p_end}
{synopt:{cmd:r(phi)}}Gamma or inverse Gaussian dispersion, when applicable{p_end}
{synopt:{cmd:r(lambda)}}inverse Gaussian shape parameter lambda, when applicable{p_end}
{synopt:{cmd:r(alpha)}, {cmd:r(theta)}}negative binomial ancillary parameters, when applicable{p_end}
{synopt:{cmd:r(delta)}}NB1 or generalized Poisson dispersion parameter, when applicable{p_end}
{synoptline}


{marker methods}{...}
{title:Methods and formulas}

{pstd}
Let {it:F_i(y;theta_hat)} be the fitted conditional CDF for observation
{it:i}. For a continuous response, {cmd:qresid} uses
{it:U_i = F_i(y_i;theta_hat)} and reports
{it:r_i = Phi^-1(U_i)}, where {it:Phi} is the standard normal CDF. This is the
probability integral transform followed by a normal quantile transformation
(Cox and Snell 1968; Dunn and Smyth 1996).

{pstd}
For a discrete response, define {it:F_low = P(Y_i < y_i)} and
{it:F_high = P(Y_i <= y_i)} under the fitted model. The randomized PIT value is
{it:U_i = F_low + V_i(F_high-F_low)} with {it:V_i} uniform on [0,1]. The
randomized quantile residual is {it:Phi^-1(U_i)}. The randomization is the
Dunn-Smyth device that converts a discrete CDF jump into a continuous PIT
interval.

{pstd}
Links, offsets, exposure variables, and weights do not change this definition.
They affect the fitted conditional distribution through the estimation command.
For example, a log link means that covariates act multiplicatively on the
fitted mean, an exposure term changes the amount of time or population at risk,
and {cmd:fweight}s estimate the model as if identical observations had been
expanded. {cmd:qresid} then evaluates the CDF implied by that fitted model. It
does not apply an additional residual-scale multiplier after the CDF has been
evaluated.

{pstd}
For Gamma and inverse Gaussian GLM specifications, dispersion is part of the fitted
conditional distribution. {cmd:qresid} normally uses Stata's stored dispersion.
{cmd:dispersion(#)} fixes that value for the CDF calculation only; it does not
refit coefficients or change fitted means. Poisson and binomial likelihoods
use fixed scale in the supported specifications. Negative-binomial,
generalized-Poisson, zero-inflated, truncated, censored, and hurdle models use
their own ancillary quantities: alpha/theta for NB2, delta for NB1 or
generalized Poisson, the zero-inflation probability for {cmd:zip}/{cmd:zinb},
the truncation or censoring limits for restricted-support models, and the
zero-versus-positive probability in hurdle models.

{pstd}
The same PIT/RQR construction applies to more complex outcomes once the fitted
CDF is specified. For zero-inflated count models, let {it:pi_i} be the fitted
probability of a structural zero and let {it:F_0i} be the CDF of the ordinary
count component. Then

{p 8 8 2}
{it:F_i(0) = pi_i + (1-pi_i)F_0i(0)}

{p 8 8 2}
{it:F_i(y) = pi_i + (1-pi_i)F_0i(y)}, for {it:y > 0}.

{pstd}
The endpoints {it:F_low} and {it:F_high} are computed from this mixture CDF.
Graphically, the zero mass and the positive-count tail are therefore placed on
the same normal-score scale, which can help distinguish a zero-process problem
from a tail or count-distribution problem (Bai et al. 2021).

{pstd}
For truncated models, the fitted distribution is conditional on being
observable. If {it:F_0i} is the untruncated CDF and the observed support is
{it:L_i < Y_i <= U_i}, then

{p 8 8 2}
{it:F_Ti(y) = [F_0i(y)-F_0i(L_i)]/[F_0i(U_i)-F_0i(L_i)]}.

{pstd}
One-sided truncation uses 0 or 1 for the unused probability endpoint. The
diagnostic is then about the probability law after the sampling restriction,
not about values that could not enter the dataset by design (Yee 2015; Yee and
Ma 2024).

{pstd}
For censored outcomes, the observation identifies a probability interval rather
than an exact response. If the observed information is {it:a_i < Y_i <= b_i},
then

{p 8 8 2}
{it:U_i = F_i(a_i) + V_i[F_i(b_i)-F_i(a_i)]}, with {it:V_i} uniform on [0,1].

{pstd}
Left- and right-censoring use the same expression with the lower or upper
probability limit set to 0 or 1. A censored response therefore contributes a
fitted probability interval to the diagnostic rather than a false exact value.

{pstd}
For hurdle count models, let {it:pi_i = P(Y_i=0)} and let {it:F_+i} be the CDF
of the positive count component, truncated so that it starts at 1. Then

{p 8 8 2}
{it:P(Y_i=0) = pi_i}

{p 8 8 2}
{it:F_i(y) = pi_i + (1-pi_i)F_+i(y)}, for {it:y > 0}.

{pstd}
The zero process and the positive truncated component are read through one
normal-score residual display. A visible pattern may indicate that the zero
part, the positive count distribution, or both pieces need attention
(Zeileis, Kleiber, and Jackman 2008).

{pstd}
The adjusted residual is {it:r_i}/sqrt(1-{it:h_i}), where {it:h_i} is the
diagonal leverage from {cmd:predict, hat}. This help uses
{cmd:type(adjusted)} as the canonical name. {cmd:type(studentized)} is retained
as an alias because the same formula appears under studentized or
leverage-adjusted terminology in software and papers, including the GLM
adjustment discussed by Scudilio and Pereira (2020).


{marker limitations}{...}
{title:Limitations}

{pstd}
Quantile residuals diagnose the fitted conditional distribution. A nonnormal
Q-Q pattern may indicate distributional misspecification, tail problems,
unmodeled zero inflation, truncation or censoring issues, or incorrect
ancillary parameters. Residual patterns against fitted values or covariates may
also suggest mean-structure, link, dispersion, weight, or dependence problems
because those features enter the fitted CDF.

{pstd}
With estimated parameters, residuals are not exactly independent standard
normal variables in finite samples. Randomized residuals also depend on the
random-number seed unless {cmd:seed()} or {cmd:uvar()} is used.

{pstd}
When a model has many discrete outcomes and randomization is used, Dunn and
Smyth recommend checking that conclusions are not driven by a single arbitrary
set of random uniforms. A practical approach is to set different seeds, produce
two or three Q-Q plots, and look for patterns that persist across the plots.

{pstd}
{cmd:qresid} does not currently support {cmd:aweight}, {cmd:iweight},
{cmd:svy:} residuals, survey-design residuals, correlated, panel, multilevel,
finite-mixture, or mixed-model residuals. Models outside the documented specifications
require separate mathematical support, postestimation extraction, tests, and
benchmarks.

{pstd}
Some unsupported specifications are planned engineering work, such as additional
weights or fitted-model extractors. Others require new published or derivable
statistical theory because a fitted individual CDF is not yet well defined for
the intended diagnostic. {cmd:qresid} reports an error rather than applying a
residual formula outside its documented mathematical scope.


{marker references}{...}
{title:References}

{p 4 8 2}
Cox, D. R., and E. J. Snell. 1968. A general definition of residuals.
{it:Journal of the Royal Statistical Society, Series B} 30: 248-275.

{p 4 8 2}
Dunn, P. K., and G. K. Smyth. 1996. Randomized quantile residuals.
{it:Journal of Computational and Graphical Statistics} 5(3): 236-244.
doi:10.1080/10618600.1996.10474708.

{p 4 8 2}
Dunn, P. K., and G. K. Smyth. 2018. {it:Generalized Linear Models With
Examples in R}. New York: Springer.

{p 4 8 2}
Feng, C., L. Li, and A. Sadeghpour. 2020. A comparison of residual diagnosis
tools for diagnosing regression models for count data. {it:BMC Medical
Research Methodology} 20: 175.

{p 4 8 2}
Bai, W., M. Dong, L. Li, C. Feng, et al. 2021. Randomized quantile residuals
for diagnosing zero-inflated generalized linear mixed models with applications
to microbiome count data. {it:BMC Bioinformatics} 22: 564.

{p 4 8 2}
Haghish, E. F. 2020. Developing, maintaining, and hosting Stata statistical
software on GitHub. {it:The Stata Journal} 20(4): 931-951.

{p 4 8 2}
Scudilio, J., and G. H. A. Pereira. 2020. Adjusted quantile residual for
generalized linear models. {it:Computational Statistics} 35: 399-421.

{p 4 8 2}
Warton, D. I., L. Thibaut, and Y. A. Wang. 2017. The PIT-trap: A
model-free bootstrap procedure for inference about regression models with
discrete, multivariate responses. {it:PLOS ONE} 12(7): e0181790.


{marker alsosee}{...}
{title:Also see}

{psee}
Manual: {manlink R predict}, {manlink R glm}, {manlink R poisson},
{manlink R nbreg}, {manlink R zip}, {manlink R zinb}, {manlink R tpoisson},
{manlink R cpoisson}

{psee}
Help: {helpb predict}, {helpb regress}, {helpb glm}, {helpb poisson},
{helpb nbreg}, {helpb gnbreg}, {helpb logit}, {helpb logistic},
{helpb binreg}, {helpb zip}, {helpb zinb}, {helpb tpoisson},
{helpb tnbreg}, {helpb ztp}, {helpb ztnb}, {helpb cpoisson}

{psee}
External commands: type {cmd:findit gpoisson}, {cmd:findit hplogit}, and
{cmd:findit hnblogit} in Stata.


{title:Author}

{p 4 4 2}
Percy Soto-Becerra, MD, MSc, PhD(c)

{p 4 4 2}
Universidad Privada del Norte, Lima, Peru

{p 4 4 2}
percy.soto@upn.edu.pe; percys1991@gmail.com
