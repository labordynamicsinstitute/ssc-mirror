{smcl}
{* *! version 1.00  06Sep2026}{...}

{title:Title}

{p2colset 5 14 21 2}{...}
{p2col :{hi:mmwsl} {hline 2}}Longitudinal marginal mean weighting through stratification for time-varying binary or nominal treatments{p_end}
{p2colreset}{...}



{title:Syntax}

{p 8 17 2}
		{cmd:mmwsl} {it:{help varname:treat}} {ifin}
		{cmd:,}
		{opth pan:elvar(varname)}
		{opth time:var(varname)}
		{opt cov:ariates}({it:{help varlist:varlist}})
		[ {opt nom:inal}
		{opt nstr:ata}({it:#})
		{opt smax}({it:#})
		{opt smd:level}({it:#})
		{opt nmin}({it:#})
		{opt pro:bit}
		{opt comm:on}
		{opt iptw:}
		{opt gap:report}
		{opt ex:clreport}
		{opt repl:ace}
		{opt pre:fix}({it:string})
		]

{p 4 4 2}
{it:{help varname: treat}} must contain integer values representing the treatment levels


{p 4 6 2}

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opt pan:elvar}{cmd:(}{it:{help varname:varname}}{cmd:)}}panel (subject) identifier{p_end}
{p2coldent:* {opt time:var}{cmd:(}{it:{help varname:varname}}{cmd:)}}wave identifier (common across panels){p_end}
{p2coldent:* {opt cov:ariates}{cmd:(}{it:{help varlist:varlist}}{cmd:)}}propensity-model predictors (the same set fit at every wave){p_end}
{synopt:{opt nom:inal}}treatment has more than two nominal (unordered) levels{p_end}
{synopt:{opt nstr:ata(#)}}number of quantile strata to generate when {cmd:strata()} is not supplied; default is to have {cmd:pstrata} 
select the count automatically{p_end}
{synopt:{opt smax(#)}}maximum strata to try per subgroup when {cmd:nstrata()} is omitted; default is {cmd:50}{p_end}
{synopt:{opt smd:level(#)}}max-pairwise-SMD balance threshold when {cmd:nstrata()} is omitted; default is {cmd:0.25}{p_end}
{synopt:{opt nmin(#)}}minimum observations required of each treatment level per stratum; default is {cmd:1}{p_end}
{synopt:{opt pro:bit}}use probit instead of logit for the per-wave/subgroup propensity models (binary treatments only){p_end}
{synopt:{opt comm:on}}restrict weighting to the region of common support within each wave/history-subgroup{p_end}
{synopt:{opt iptw}}also generate inverse probability of treatment weights{p_end}
{synopt:{opt gap:report}}show full wave-by-wave detail on any {cmd:panelvar}/{cmd:timevar} gaps found (default: one summary line){p_end}
{synopt:{opt ex:clreport}}show wave-by-wave detail on any stratum-overlap exclusions found (default: one summary line){p_end}
{synopt:{opt repl:ace}}replace existing variables created by {cmd:mmwsl}{p_end}
{synopt:{opt pre:fix(string)}}prefix applied to variable names created by {cmd:mmwsl}{p_end}
{synoptline}
{p 4 6 2}* {opt panelvar()}, {opt timevar()} and {opt covariates()} are required. {p_end}
{p2colreset}{...}



{title:Description}

{pstd}
{opt mmwsl} extends marginal mean weighting through stratification ({helpb mmws}) to panel (longitudinal) data with a time-varying 
treatments (see Hong 2015). When specified, inverse probability of treatment weights (IPTW) will also be computed, following 
Robins, Hernan, and Brumback (2000). Treatments can be either binary or nominal. {p_end}



{title:Options}

{phang}
{opth panelvar(varname)} identifies the panel (subject) to which each observation belongs; {cmd:required}.{p_end}

{phang}
{opth timevar(varname)} identifies the wave; must be numeric and common across panels; {cmd:required}.{p_end}

{phang}
{opth covariates(varlist)} the propensity-model predictors, fit against {it:{help varname:treat}} separately at every wave and every
treatment-history subgroup. The same set of covariates is used at every wave; {cmd:required}.{p_end}

{phang}
{opt nominal} specifies that {it:{help varname:treat}} has more than two unordered levels (nonnegative integers, up to 20 distinct
levels in the estimation sample). The propensity model at each wave/history-subgroup is then a multinomial logit predicting one
probability per treatment level, and {helpb pstrata} / {helpb mmws} are called with one propensity score per level actually present in
that subgroup. {p_end}

{phang}
{opt nstrata(#)} specifies the number of strata to use for every wave/history-subgroup's MMWS weight (passed through to {helpb mmws});
for a nominal treatment, the same number is used for every treatment level's own stratification.
If omitted, {helpb pstrata} selects the number of strata automatically for each wave/history-subgroup, subject to {cmd:smax()} and
{cmd:smdlevel()}. {cmd:nstrata} cannot be combined with automatic selection.{p_end}

{phang}
{opt smax(#)} the maximum number of strata to try, per wave/history-subgroup, when {cmd:nstrata()} is omitted; default is {cmd:smax(50)}.{p_end}

{phang}
{opt smdlevel(#)} the max-pairwise-SMD balance threshold used by {helpb pstrata} when {cmd:nstrata()} is omitted; default is {cmd:smdlevel(0.25)}.{p_end}

{phang}
{opt nmin(#)} specifies the minimum number of observations required for each required treatment level, within every stratum; default is {cmd:nmin(1)}. 

{phang}
{opt probit} uses probit, rather than logit, to fit the propensity model at each wave/history-subgroup. Not available with
{cmd:nominal}; the propensity model for a nominal treatment is always a multinomial logit.{p_end}

{phang}
{opt common} restricts weighting to the region of common support, separately within each wave/history-subgroup cell.{p_end}

{phang}
{opt iptw} also computes a longitudinal (cumulative-product) inverse probability of treatment weight, alongside the MMWS weight.
IPTW's restart behavior is evaluated independently of MMWS's, since IPTW has no stratum-exclusion mechanism of its own.{p_end}

{phang}
{opt gapreport} shows full wave-by-wave detail (a tabulation and a listing of affected {cmd:panelvar}/{cmd:timevar} combinations) for
any gaps found in the panel; by default, only a one-line summary is shown. {p_end}

{phang}
{opt exclreport} shows wave-by-wave detail (subgroup, sample sizes, and reason) for any exclusions from weighting; by default, only a
one-line summary is shown. {p_end}

{phang}
{opt replace} replaces variables created by {cmd:mmwsl} if they already exist. If {cmd:prefix()} is specified, only variables created
by {cmd:mmwsl} with the same prefix will be replaced.{p_end}

{phang}
{opt prefix(string)} adds a prefix to the names of variables created by {cmd:mmwsl}. Short prefixes are recommended.{p_end}



{title:Remarks}

{pstd}
{opt mmwsl} distinguishes three kinds of irregularity in a panel and purposely handles them differently: {p_end}

{phang}
(1) An ordinary gap in the {cmd:timevar} for a panel member at some wave is treated as non-informative: it is reported in {cmd:gapreport} 
but not imputed, and that panel member's history and cumulative weight simply condition on their own most recently {it:observed} wave, 
skipping the gap. {p_end}

{phang}
(2) By contrast, a genuine dropout ({cmd:treat} recorded as {it:missing} at a wave the panel member was observed) is 
treated as absorbing: that panel member is excluded from estimation from that wave forward. {p_end}

{phang}
(3) If a panel member's cumulative weight chain is broken for some other reason (excluded for lack of a comparator at some 
wave, or missing covariates) and they are then observed again with valid data at a later wave, the cumulative product restarts 
fresh at that wave rather than carrying forward an undefined value indefinitely; which rows are a
restart, rather than a normal continuation, is flagged in {cmd:_restart} (and, independently, {cmd:_iptw_restart} when {cmd:iptw} is
specified) so this is visible and auditable downstream. {p_end}

{pstd}
If a subgroup whose assigned stratum does not contain at least {cmd:nmin()} observations of a required
treatment level, a note is displayed (or full detail, with {cmd:exclreport}) identifying the deficient subgroup, and the observations 
lacking an adequate comparator are excluded from weighting for that wave forward. The total number of observations excluded this way, 
across all waves and history-subgroups, is returned in {cmd:r(nexcluded)}. If the propensity model itself fails to converge for an 
entire wave/history-subgroup, no stratification is attempted for that subgroup and a weight of 1 is assigned instead, matching 
what an uninformative IPTW weight would give, and {cmd:_fallback} is set to 1 for those rows. {p_end}

{pstd}
Hong (2015, Section 8.4.5) offers a rule of thumb for how large a treatment-history subgroup needs to be for its own propensity model
to be trustworthy in the first place, before {cmd:nmin()}/{cmd:exclreport} ever come into play: at least 30 individuals in any given
treatment-sequence cell at any wave, and, separately, at least 100 units in a cell for every 10 predictors in {cmd:covariates()} to
avoid overfitting the per-subgroup propensity model. {cmd:mmwsl} does not enforce this, but a wave/history-subgroup that is far 
below it is a reasonable prompt to simplify {cmd:covariates()}, merge sparse history categories, or treat that subgroup's 
estimate cautiously. {p_end}



{title:Variables added to the dataset}

{pstd} {cmd:mmwsl} generates several variables for the convenience of the user. If the user specifies a {cmd:prefix()}, it will
naturally be applied:{p_end}

{p 5 17 15}{cmd:_mmws:} the cumulative MMWS sequence weight through this wave{p_end}

{p 5 17 15}{cmd:_restart:} 1 if the cumulative MMWS chain restarted fresh at this wave (the previous wave's weight was missing --
excluded, or missing covariates -- so this panel member is treated as newly entering, rather than carrying forward an undefined
product){p_end}

{p 5 17 15}{cmd:_fallback:} 1 if this wave's weight used marginal-rate substitution because the propensity model failed to converge
for the whole wave/history-subgroup{p_end}

{p 5 17 15}{cmd:_nstrata:} the number of strata used for this wave/history-subgroup's propensity model (for a nominal treatment: the
mean across treatment levels, rounded, since each level's own propensity score can converge to a different count when {cmd:nstrata()}
is omitted){p_end}

{p 5 17 15}{cmd:_iptw:} the cumulative stabilized IPTW sequence weight through this wave, when the {cmd:iptw} option is specified{p_end}

{p 5 17 15}{cmd:_iptw_restart:} 1 if the cumulative IPTW chain restarted fresh at this wave, when the {cmd:iptw} option is specified
(evaluated independently of {cmd:_restart}; see {bf:Options} above){p_end}



{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. mmwsl_example, clear}{p_end}

{pstd}Generate weights for the time-varying binary treatment {cmd:union}, using {helpb pstrata} to select the number of strata
automatically at every wave/history-subgroup{p_end}
{phang2}{cmd:. mmwsl union, panelvar(idcode) timevar(year) covariates(grade c.age##c.age tenure south)}{p_end}

{pstd}Estimate the treatment effect of {cmd:union} on {cmd:ln_wage} using the cumulative MMWS weights generated in the previous run{p_end}
{phang2}{cmd:. regress ln_wage union [pw=_mmws], vce(cluster idcode)}{p_end}

{pstd}Generate weights using a fixed number of strata at every wave/history-subgroup instead{p_end}
{phang2}{cmd:. mmwsl union, panelvar(idcode) timevar(year) covariates(grade c.age##c.age tenure south) nstrata(5) replace}{p_end}

{pstd}Generate both MMWS and IPTW weights, with common support {p_end}
{phang2}{cmd:. mmwsl union, panelvar(idcode) timevar(year) covariates(grade c.age##c.age tenure) nstrata(5) common iptw replace} {p_end}

{pstd}Estimate the treatment effect using the cumulative IPTW weights instead, for comparison{p_end}
{phang2}{cmd:. regress ln_wage union [pw=_iptw], vce(cluster idcode)}{p_end}

{pstd}Examine how many strata were used, and how often the fallback and restart mechanisms were triggered{p_end}
{phang2}{cmd:. tabstat _nstrata _fallback _restart, stat(mean)}{p_end}

{pstd}Create a nominal (unordered, more-than-two-level) time-varying treatment{p_end}
{phang2}{cmd:. gen byte jobcat = 1 + union + 2*south}{p_end}

{pstd}Generate weights for the nominal treatment {cmd:jobcat}, using {helpb pstrata} to select each level's number of strata
automatically{p_end}
{phang2}{cmd:. mmwsl jobcat, panelvar(idcode) timevar(year) covariates(grade c.age##c.age tenure) nominal prefix(nom) replace}{p_end}

{pstd}Estimate the effect of {cmd:jobcat} on {cmd:ln_wage} using the cumulative MMWS weights generated in the previous run{p_end}
{phang2}{cmd:. regress ln_wage i.jobcat [pw=nom_mmws], vce(cluster idcode)}{p_end}

{pstd}Generate both MMWS and IPTW weights for {cmd:jobcat} using a fixed number of strata per level instead{p_end}
{phang2}{cmd:. mmwsl jobcat, panelvar(idcode) timevar(year) covariates(grade c.age##c.age tenure) nominal nstrata(5) iptw prefix(nom) replace}{p_end}

{pstd}Estimate the same effect using the cumulative IPTW weights instead, for comparison{p_end}
{phang2}{cmd:. regress ln_wage i.jobcat [pw=nom_iptw], vce(cluster idcode)}{p_end}



{title:Saved results}

{p 4 8 2}
By default, {cmd:mmwsl} stores the following in {cmd:r()}.

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(T)}}the number of distinct waves of {cmd:timevar} in the estimation sample{p_end}
{synopt:{cmd:r(K)}}the number of distinct treatment levels (2 for a binary treatment; the number of levels found in the estimation
sample for a nominal treatment){p_end}
{synopt:{cmd:r(nexcluded)}}the total number of observations excluded from weighting, across all waves and history-subgroups, because
their assigned stratum did not contain at least {cmd:nmin()} observations of a required treatment level, no variation in {cmd:treat}
was available to fit a propensity model, or automatic strata selection could not find a balanced stratification (0 if none were
excluded){p_end}


{title:References}

{p 4 8 2}
Hong, G. 2010. Marginal mean weighting through stratification: adjustment for selection bias in multilevel data.
{it:Journal of Educational and Behavioral Statistics} 35: 499-531.

{p 4 8 2}
Hong, G. 2012. Marginal mean weighting through stratification: a generalized method for evaluating multi-valued
and multiple treatments with non-experimental data. {it:Psychological Methods} 17: 44-60.

{p 4 8 2}
Hong, G. 2015. {it:Causality in a Social World: Moderation, Mediation and Spill-over}. Chichester, UK: John Wiley & Sons.

{p 4 8 2}
Huang, I.-C., Frangakis, C., Dominici, F., Diette, G. B., Wu, A. W. 2005. Application of a propensity score
approach for risk adjustment in profiling multiple physician groups on asthma care. {it:Health Services Research} 40: 253-278.

{p 4 8 2}
Linden, A. 2014. Combining propensity score-based stratification and weighting to improve 
causal inference in the evaluation of health care interventions. {it:Journal of Evaluation in Clinical Practice} 20: 1065-1071.

{p 4 8 2}
Linden, A. 2017a. Improving casual inference with a doubly robust estimator that combines propensity score stratification and weighting. 
{it:Journal of Evaluation in Clinical Practice} 23: 697-702.

{p 4 8 2}
Linden, A. 2017b. A comparison of approaches for stratifying on the propensity score to reduce bias. 
{it:Journal of Evaluation in Clinical Practice} 23: 690-696.

{p 4 8 2}
Linden, A. 2026. Marginal mean weighting through stratification for time-varying multivalued treatments: 
A Monte Carlo comparison with inverse-probability-weighted marginal structural models. 

{p 4 8 2}
Linden, A. & Adams, J. L. 2008. Improving participant selection in disease management programs: insights gained from propensity score
stratification. {it:Journal of Evaluation in Clinical Practice} 14: 914–918.

{p 4 8 2}
Linden, A., Uysal, S. D., Ryan, A., & Adams, J. L. (2016) Estimating causal effects for multivalued treatments: 
A comparison of approaches. {it: Statistics in Medicine} 35: 534-552.

{p 4 8 2}
Nichols, A. 2008. Erratum and discussion of propensity-score reweighting. {it: Stata Journal} 8: 532-539.

{p 4 8 2}
Robins, J. M., Hernan, M. A., Brumback B. 2000. Marginal Structural Models and Causal Inference in Epidemiology. {it:Epidemiology} 11: 550-560.

{p 4 8 2}
Sato, T., Matsuyama, Y. 2003. Marginal Structural Models as a Tool for Standardization. {it:Epidemiology} 14: 680-686.


{marker citation}{title:Citation of {cmd:mmwsl}}

{p 4 8 2}{cmd:mmwsl} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden, Ariel. 2026.
MMWSL: Stata module for implementing longitudinal marginal mean weighting through stratification for time-varying binary or 
nominal treatments. Statistical Software Components s459891, Boston College Department of Economics{p_end}



{title:Author}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also see}

{p 4 8 2}Online: {helpb mmws} (if installed), {helpb pstrata} (if installed){p_end}
