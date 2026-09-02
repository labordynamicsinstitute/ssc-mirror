{smcl}
{* *! version 1.0.0  19Aug2026}{...}
{vieweralsosee "plssem2 postestimation" "help plssem2_estat"}{...}
{vieweralsosee "plssem2 predict" "help plssem2_predict"}{...}
{viewerjumpto "Syntax" "plssem2##syntax"}{...}
{viewerjumpto "Description" "plssem2##description"}{...}
{viewerjumpto "Options" "plssem2##options"}{...}
{viewerjumpto "Remarks" "plssem2##remarks"}{...}
{viewerjumpto "Examples" "plssem2##examples"}{...}
{viewerjumpto "Stored results" "plssem2##results"}{...}
{viewerjumpto "Methods and formulas" "plssem2##methods"}{...}
{viewerjumpto "References" "plssem2##references"}{...}
{viewerjumpto "Authors" "plssem2##authors"}{...}
{viewerjumpto "Also see" "plssem2##seealso"}{...}
{title:Title}

{p 4 18 2}
{hi:plssem2} {hline 2} Partial least squares structural equation modeling
(PLS-SEM) / 偏最小二乘结构方程模型

{marker syntax}{...}
{title:Syntax}

{pstd}
Partial least squares structural equation modeling of data

{p 8 12 2}
{cmd:plssem2} ({it:LV1} {cmd:>} {it:indblock1}) ({it:LV2} {cmd:>} {it:indblock2})
({it:LV3} {cmd:<} {it:indblock3}) ... {ifin}
[{cmd:,} {it:{help plssem2##plssem2opts:options}}]

{pstd}
{it:LV} denotes a latent variable and {it:indblock} its block of observed
indicators.  The {bf:greater-than} sign ({cmd:>}) declares a {bf:reflective}
(Mode A) measurement model; the {bf:less-than} sign ({cmd:<}) declares a
{bf:formative} (Mode B) measurement model.  At least two latent variables are
required.

{p 8 12 2}
{cmd:plssem2} ... {cmd:,} {bf:structural}({it:dep1} {it:pred1a} {it:pred1b},
{it:dep2} {it:pred2a} ...) {it:{help plssem2##plssem2opts:options}}

{pstd}
The structural (inner) model is specified with the {cmd:structural()} option:
for each endogenous latent variable, list the latent variable first and then
its direct predictors, separating equations by commas, e.g.,
{cmd:structural(Satisfaction Quality Value, Quality Expectation)}.

{marker plssem2opts}{...}
{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt STRuctural(string)}}structural model specification{p_end}
{synopt:{cmdab:w:scheme(centroid)}}centroid inner weighting scheme{p_end}
{synopt:{cmdab:w:scheme(factorial)}}factorial inner weighting scheme{p_end}
{synopt:{cmdab:w:scheme(path)}}path inner weighting scheme; the default{p_end}
{synopt:{opth boot(#)}}number of bootstrap replications{p_end}
{synopt:{opth s:eed(#)}}bootstrap seed{p_end}
{synopt:{opt bca}}bias-corrected and accelerated (BCa) bootstrap confidence
intervals{p_end}
{synopt:{cmd:no}{cmdab:j:ack}}skip the jackknife (BCa reduces to a
bias-corrected interval){p_end}
{synopt:{opth blind:fold(#)}}Stone-Geisser blindfolding omission distance for
the cross-validated Q2{p_end}
{synopt:{cmd:no}{cmdab:ht:mt}}do not display the HTMT matrix{p_end}
{synopt:{opt lev:el(#)}}confidence level; default is {cmd:95}{p_end}
{synopt:{opt t:ol(#)}}convergence tolerance; default is {cmd:1e-7}{p_end}
{synopt:{opt max:iter(#)}}maximum number of iterations; default is {cmd:100}{p_end}
{synopt:{cmdab:init(eigen)}}initialize the latent variables using the first
principal component{p_end}
{synopt:{cmdab:init(indsum)}}initialize the latent variables using the sum of
the indicators; the default{p_end}
{synopt:{cmdab:conv:crit(relative)}}relative convergence criterion; the default{p_end}
{synopt:{cmdab:conv:crit(square)}}square convergence criterion{p_end}
{synopt:{cmdab:conv:crit(absolute)}}absolute convergence criterion{p_end}
{synopt:{opt dig:its(#)}}number of decimals to display; default is {cmd:3}{p_end}
{synopt:{cmd:no}{cmdab:head:er}}suppress the output header{p_end}
{synopt:{cmd:no}{cmdab:mea:stable}}suppress the measurement-model table{p_end}
{synopt:{cmd:no}{cmdab:discrim:table}}suppress the discriminant-validity table{p_end}
{synopt:{cmd:no}{cmdab:struct:table}}suppress the structural-model table{p_end}
{synopt:{opth high:er(string)}}higher-order constructs (two-stage approach){p_end}
{synopt:{opth gr:oup(string)}}multi-group analysis (MGA){p_end}
{synopt:{opt raw:sum}}use summated scales (sum of the indicators) as scores{p_end}
{synopt:{cmd:no}{cmdab:sc:ale}}do not standardize the indicators before running
the algorithm{p_end}
{synopt:{opt stat:s}}print indicator summary statistics{p_end}
{synopt:{opt no}{cmdab:cleanup}}do not remove Mata temporary objects
(undocumented){p_end}
{synoptline}

{p 4 6 2}
{cmd:by} is allowed with {cmd:plssem2}; see {help prefix}.  {cmd:plssem2} may be
replayed without arguments to redisplay the last results.  See
{helpb plssem2_estat:plssem2 postestimation} for {cmd:estat} subcommands and
{helpb plssem2_predict:plssem2 predict} for {cmd:predict} after estimation.
The structural path coefficients are stored in {cmd:e(b)} with a bootstrap
variance matrix {cmd:e(V)} (when {cmd:boot()} is used), so the results can be
exported with {helpb estout:esttab} / {helpb estout:estout} (see {help plssem2##remarks:Remarks}).

{marker description}{...}
{title:Description}

{pstd}
{bf:plssem2} fits partial least squares structural equation models (PLS-SEM),
a variance-based, composite-based alternative to covariance-based structural
equation modeling (CB-SEM, e.g., {cmd:sem} and {cmd:gsem}).  The estimation
follows the algorithm of {help plssem2##Wold1975:Wold (1975)} and
{help plssem2##Lohmoller1989:Lohmöller (1989)} as implemented in SmartPLS and
in the Stata package {help plssem2##VenturiniMehmetoglu2019:plssem}
(Venturini and Mehmetoglu 2019), with the additions of
{bf:blindfolding} (Stone-Geisser Q2), {bf:HTMT} discriminant validity
(Henseler et al. 2015), {bf:bootstrap with bias-corrected and accelerated (BCa)}
confidence intervals (Efron 1987), {bf:higher-order constructs} via the
two-stage approach (Becker et al. 2012; Sarstedt et al. 2019), and
{bf:multi-group analysis} based on the permutation test (Henseler et al. 2016).

{pstd}
The PLS algorithm proceeds in three stages:

{pstd}
{bf:Stage 1 (iterative).}  The indicators are standardized.  Starting from an
initialization ({cmd:init(indsum)}, the default, or {cmd:init(eigen)}), the
algorithm alternates between the {bf:outer approximation} (each latent
variable score is a weighted composite of its indicators),
the {bf:inner approximation} (each latent variable score is updated from the
scores of the connected latent variables using the inner weights of the
chosen {bf:weighting scheme}: {bf:centroid}, {bf:factorial}, or, the default,
{bf:path}), and the {bf:outer weights update} (Mode A, reflective: the
weights are the correlations between each indicator and the inner
approximation; Mode B, formative: the weights are the ordinary least squares
regression coefficients of the inner approximation on the block of
indicators).  The iterations stop when the change of the outer weights falls
below the tolerance (convergence criterion {cmd:relative}, {cmd:square}, or
{cmd:absolute}).

{pstd}
{bf:Stage 2.}  The final latent variable (composite) scores are computed, the
outer {bf:loadings} are obtained as the correlations of each indicator with
its composite score, and the {bf:path coefficients} of the structural model
are estimated by OLS regressions among the composite scores.  R-squared of the
endogenous latent variables, indicator reliability measures (Cronbach's
alpha, composite reliability rho_c, and average variance extracted AVE), the
Fornell-Larcker criterion, the HTMT matrix, the inner and outer VIFs and the
Cohen effect sizes f2 are computed.

{pstd}
{bf:Stage 3 (optional).}  Inference is obtained by nonparametric bootstrap
({cmd:boot(#)}): each replication resamples the cases with replacement and
re-estimates the whole model; bootstrap standard errors, t values, p-values,
percentile and (with {cmd:bca}) bias-corrected and accelerated confidence
intervals are reported for the path coefficients, outer loadings and outer
weights.  Predictive relevance is assessed by the {bf:blindfolding} procedure
({cmd:blindfold(#)}): the data are divided into d groups, each group is
omitted in turn, the model is re-estimated on the remaining observations and
the omitted indicator values are predicted, giving the cross-validated
{bf:communality} and {bf:redundancy} Q2 (Stone 1974; Geisser 1974; Chin 1998).

{marker options}{...}
{title:Options}

{phang}{opt structural(dep1 pred1 ... , dep2 pred2 ...)}
defines the structural (inner) model.  For each endogenous latent variable,
type its name first and then its direct predictors.  Multiple equations are
separated by commas; the equations themselves may be enclosed in parentheses,
e.g., {cmd:structural(Satisfaction Quality Value, Quality Expectation)}.
All latent variables that are not endogenous are treated as exogenous.

{phang}{opt wscheme(centroid|factorial|path)}
chooses the inner weighting scheme used in Stage 1 of the PLS algorithm.
{bf:path} (the default) uses the structural-model path coefficients for the
predecessors of each latent variable and the correlations for its successors;
{bf:centroid} uses only the sign of the correlation; {bf:factorial} uses the
correlation itself.  The {bf:path} scheme is recommended and is the default
in SmartPLS.

{phang}{opt boot(#)}
performs # nonparametric bootstrap replications.  Bootstrap standard errors,
t values, p-values, and percentile confidence intervals are reported for the
path coefficients, outer loadings, outer weights, R-squared, and the direct,
indirect and total effects.  The number of inadmissible replications (models
that did not converge) is reported as {cmd:e(n_inadmissibles)}.

{phang}{opt seed(#)}
sets the random-number seed for the bootstrap (and for the permutation
procedure of {cmd:group()}).  Useful for reproducibility.

{phang}{opt bca}
reports bias-corrected and accelerated (BCa) bootstrap confidence intervals
(Efron 1987) in addition to the percentile intervals.  The acceleration is
computed by a leave-one-out jackknife, which requires n additional model
estimations; use {cmd:nojack} to skip the jackknife (the intervals then reduce
to bias-corrected intervals).

{phang}{opt blindfold(#)}
performs the Stone-Geisser blindfolding procedure with omission distance
{it:#} (a value between 5 and 10 is recommended; 7 is typical).  Reports the
cross-validated redundancy Q2 and communality Q2 for every latent variable
and indicator.  Q2 values above zero indicate predictive relevance of the
construct.  The results are stored in {cmd:e(q2_redundancy)},
{cmd:e(q2_communality)}, {cmd:e(q2_ind_red)} and {cmd:e(q2_ind_com)} and can
be displayed with {cmd:estat q2}.

{phang}{opt higher("HOname: comp1 comp2 ..." [, mode(reflective|formative)])}
declares one or more higher-order (second-order) constructs, estimated with
the two-stage approach (Becker et al. 2012; Sarstedt et al. 2019).  In
{bf:stage 1} the model containing only the first-order latent variables
(the components) is estimated and the component scores are saved; in
{bf:stage 2} these scores are used as indicators of the higher-order construct
and the full model is re-estimated.  The default mode of the higher-order
construct is {bf:reflective}; use {cmd:, mode(formative)} for a formative
higher-order construct.  Multiple higher-order constructs are separated by
semicolons, e.g.,
{cmd:higher("ESG: E S G, formative; HQD: Innov Effic Green, reflective")}.
The higher-order construct names must not appear in the measurement blocks
and may be used freely in {cmd:structural()}.  The component latent variables
must be declared in the measurement part of the syntax.

{phang}{opt group(groupvar [, method(permutation|normal) reps(#) seed(#) alpha(#)])}
performs a multi-group analysis (MGA).  The model is estimated separately for
each of the two groups defined by {it:groupvar}, and the absolute difference
of every structural path coefficient is tested.  The default
{bf:method(permutation)} implements the permutation test of
Henseler et al. (2016): the group labels are randomly permuted {cmd:reps}
times (default 1000), the model is re-estimated for the two permuted groups,
and the p-value is the proportion of permuted absolute differences at least
as large as the observed one.  {bf:method(normal)} uses a normal-theory test
based on the bootstrap standard errors of the two group-specific estimates.
{cmd:seed()} sets the seed for the permutation and {cmd:alpha()} the
significance threshold used in the output (default 0.05).  The group()
results are stored in {cmd:e()}; see {help plssem2##results:Stored results}
and {cmd:estat group}.  When {cmd:higher()} is combined with {cmd:group()},
the stage-1 component scores are computed once on the pooled sample and
then used as the higher-order indicators in the group-specific stage-2
models (two-stage MGA).  The {cmd:boot()} option is not allowed with
{cmd:group()}; use {cmd:group(..., method(normal))} for an asymptotic
test instead.

{phang}{opt rawsum}
uses the sum of the (standardized) indicators of each block as the latent
variable score and estimates only the structural part (summated scales; no
iterative PLS algorithm).

{phang}{opt noscale}
does not standardize the indicators before running the algorithm.

{phang}{opt tol(#)}
sets the convergence tolerance.  The default is {cmd:1e-7}.

{phang}{opt maxiter(#)}
sets the maximum number of iterations of the PLS algorithm.  The default is
{cmd:100}; the algorithm usually converges in fewer than 15 iterations.

{phang}{opt init(eigen|indsum)}
chooses the initialization of the outer weights.  {cmd:indsum} (the default)
starts from equal weights; {cmd:eigen} starts from the first principal
component of each block.

{phang}{opt convcrit(relative|square|absolute)}
chooses the convergence criterion.  {cmd:relative} (the default) compares the
relative change of the outer weights, {cmd:square} the change of their
squares, {cmd:absolute} the absolute change.

{phang}{opt digits(#)}
sets the number of decimals displayed for the estimates.  The default is 3.

{phang}{opt noheader, nomeastable, nodiscrimtable, nostructtable}
suppress the output header, the measurement-model table, the
discriminant-validity table, and the structural-model table, respectively.

{phang}{opt nohtmt}
suppresses the HTMT matrix from the discriminant-validity section.

{phang}{opt stats}
prints the summary statistics (mean, standard deviation, etc.) of the
indicators.

{phang}{opt level(#)}
sets the confidence level for the bootstrap confidence intervals.
The default is 95.

{marker remarks}{...}
{title:Remarks}

{title:PLS-SEM does not provide a global goodness-of-fit statistic}

{pstd}
{bf:plssem2} is a {bf:variance-based} and {bf:composite-based} method: the
model parameters are obtained by a sequence of OLS regressions among
weighted composites of the indicators, not by maximizing a likelihood or by
minimizing the discrepancy between an implied and an observed covariance
matrix.  Consequently, {bf:PLS-SEM has no global goodness-of-fit statistic}.
{bf:plssem2} deliberately does {bf:not} report a chi-squared statistic,
RMSEA, CFI, TLI, SRMR, or any other CB-SEM fit index: such indices are not
defined for PLS-SEM and reporting them would be misleading.  Model evaluation
rests instead on the assessment criteria printed by {cmd:plssem2} and by its
{helpb plssem2_estat:postestimation} commands:

{pstd}
- {bf:Measurement model.}  Indicator loadings (should exceed 0.708
  ideally), indicator reliability, Cronbach's alpha and composite
  reliability rho_c (>= 0.7), and average variance extracted AVE (>= 0.5).
  For formative blocks, assess the indicator weights, their significance
  (bootstrap) and the outer VIFs (see {cmd:estat vif}).
- {bf:Discriminant validity.}  Fornell-Larcker criterion (the square root of
  the AVE of each construct must exceed its correlations with the other
  constructs) and the HTMT ratio of correlations (all HTMT values below
  0.90, or 0.85 for conceptually distinct constructs).
- {bf:Structural model.}  Path coefficients with bootstrap-based inference,
  R-squared of the endogenous constructs, Cohen's effect sizes f2
  (0.02/0.15/0.35), inner VIFs, and the Stone-Geisser Q2 from blindfolding
  (predictive relevance, Q2 > 0).

{pstd}
Use {cmd:sem} or {cmd:gsem} for CB-SEM applications where global fit
assessment is required; use {cmd:plssem2} when the focus is on prediction,
when the model contains formative constructs, when the sample size is small,
or when the distributional assumptions of maximum likelihood cannot be
maintained.

{title:Composite-based estimation and "consistency at large"}

{pstd}
The latent variable scores estimated by PLS are {bf:composites} (weighted
sums) of the indicators, not common factors.  The outer loadings therefore
converge (as the sample size grows) to the correlations between the
indicators and the composite scores ("consistency at large", Lohmöller
1989), and the path coefficients converge to the OLS coefficients among the
composite scores.  For reflective measurement models the structural path
coefficients are attenuated relative to the common-factor (CB-SEM) values;
this is a property of PLS-SEM itself, not of {cmd:plssem2}.  Inferences
should be based on the bootstrap, which is the standard approach in the
PLS-SEM literature.

{title:Exporting the results (estout / esttab compatibility)}

{pstd}
The structural path coefficients are stored in {cmd:e(b)} with coefficient
names of the form {it:"dep:pred"} (e.g., {cmd:"RA:ESG"}), and, when
{cmd:boot()} is used, {cmd:e(V)} contains the bootstrap covariance matrix of
the path coefficients.  Standard estimation-table commands can therefore be
used, e.g.:

{p 8 12 2}
{cmd:. plssem2 (ESG > e1-e3) (RA > ra1-ra3) (HQD > in1-in3),}  ///
{break} {cmd:    structural(RA ESG HQD, HQD RA) boot(500) seed(123)}{p_end}
{p 8 12 2}
{cmd:. estimates store m1}{p_end}
{p 8 12 2}
{cmd:. esttab m1, se star(* 0.10 ** 0.05 *** 0.01) title("PLS-SEM path coefficients")}{p_end}
{pstd}
{cmd:esttab} and {cmd:estout} must be installed from SSC
({cmd:ssc install estout}).  The loadings, weights, reliability, HTMT, Q2,
effects and VIF tables are available as stored matrices
(see {help plssem2##results:Stored results}) and through the {cmd:estat}
subcommands.

{title:Data, missing values and latent-variable scores}

{pstd}
Observations with missing values in any indicator are excluded from the
estimation (listwise deletion), as are observations excluded by the {cmd:if}
and {cmd:in} qualifiers.  {cmd:plssem2} creates one new variable per latent
variable containing the estimated composite scores (named after the latent
variables, as in {help plssem2##VenturiniMehmetoglu2019:plssem}); these
variables can be used for further analysis (e.g., creating interaction terms)
or can be regenerated with {cmd:predict}.  Choose latent-variable names that
do not collide with existing variable names.

{title:中文说明 (Remarks in Chinese)}

{pstd}
{bf:plssem2} 是基于偏最小二乘（PLS）算法的结构方程模型程序，适用于预测导向、
小样本、包含形成型（formative）构念或数据分布不满足最大似然假设的研究场景
（会计、管理、营销等实证领域的高频场景）。

{pstd}
{bf:重要提示}：{bf:PLS-SEM 不是基于似然的方法}，{bf:没有}传统的全局拟合优度
（GOF）指标——程序{bf:不会}输出 CB-SEM 的卡方（chi2）、RMSEA、CFI、TLI 等
拟合指数，也不应把这些指数用于 PLS-SEM 的模型评价。模型评价应依据：
（1）测量模型——载荷（>0.708 为佳）、Cronbach's alpha 与组合信度 CR（>=0.7）、
AVE（>=0.5）；（2）判别效度——Fornell-Larcker 准则与 HTMT（<0.90 或 0.85）；
（3）结构模型——路径系数及其 Bootstrap 检验、R2、效应量 f2、内部 VIF，
以及 Blindfolding 的 Stone-Geisser Q2（>0 表明具有预测相关性）。

{pstd}
{bf:常用命令示例}（形成型/反映型混合模型、高阶构念、中介效应）：

{p 8 12 2}
{cmd:. plssem2 (ESG < esg1 esg2 esg3) (RA > ra1-ra4) (MP > mp1-mp4) (RM > rm1-rm4) (HQD > hq1-hq4),}  ///{break}
{cmd:    structural(RA ESG, MP ESG, RM ESG, HQD RA MP RM) boot(999) seed(2026) bca blindfold(7) level(95)}{p_end}

{pstd}
{bf:中介效应}：直接效应、间接效应和总效应通过 {cmd:estat effects} 查看，
间接效应（如 ESG→RA→HQD）的显著性以 Bootstrap 置信区间（含 BCa 区间）
判断，区间不含 0 即为显著。{bf:多组分析}：{cmd:group(soe, method(permutation) reps(1000))} 可检验国有/民营企业等分组下路径系数的差异（置换检验 p 值）。

{marker examples}{...}
{title:Examples}

    {hline}
{pstd}Setup (the dataset ships with the package; see
{cmd:python/run_example.py}){p_end}
{phang2}{cmd:. import delimited "results/esg_simdata.csv", clear}{p_end}

{pstd}A simple mediation model (reflective measurement, bootstrap BCa,
blindfolding){p_end}
{phang2}{cmd:. plssem2 (ESG > e1 e2 e3) (RA > ra1 ra2 ra3) (HQD > in1 in2 in3), structural(HQD RA ESG, RA ESG) boot(200) seed(101) bca blindfold(7)}{p_end}

{pstd}Formative and reflective blocks together with the centroid scheme{p_end}
{phang2}{cmd:. plssem2 (ESGindex < e1 s1 g1) (RA > ra1-ra3) (HQD > in1-in3), structural(HQD RA ESGindex, RA ESGindex) wscheme(centroid)}{p_end}

{pstd}Higher-order constructs (two-stage; ESG second-order formative, HQD
second-order reflective) with bootstrap BCa, blindfolding and multi-group
analysis by ownership type.  This is the model of the project "ESG
information disclosure and the high-quality development of enterprises"
(see the example do-file {cmd:plssem2_esg_model.do}).{p_end}
{phang2}{cmd:. plssem2 (E > e1-e4) (S > s1-s4) (G > g1-g4) (RA > ra1-ra4) (MP > mp1-mp4) (RM > rm1-rm4)} ///{break}
{cmd: (Innov > in1-in4) (Effic > ef1-ef4) (Green > gr1-gr4), } ///{break}
{cmd: structural(HQD RA MP RM ESG, RA ESG, MP ESG, RM ESG)} ///{break}
{cmd: higher("ESG: E S G, formative; HQD: Innov Effic Green, reflective")} ///{break}
{cmd: boot(999) seed(20260819) bca blindfold(7)}{p_end}

{pstd}Post-estimation{p_end}
{phang2}{cmd:. estat effects, indirect total level(95)}{p_end}
{phang2}{cmd:. estat reliability}{p_end}
{phang2}{cmd:. estat htmt}{p_end}
{phang2}{cmd:. estat q2}{p_end}
{phang2}{cmd:. estat vif}{p_end}
{phang2}{cmd:. predict scores, lv(ESG HQD)}{p_end}

{pstd}Multi-group analysis (state-owned vs. private enterprises){p_end}
{phang2}{cmd:. plssem2 (E > e1-e4) (S > s1-s4) (G > g1-g4) (RA > ra1-ra4) (MP > mp1-mp4) (RM > rm1-rm4) } ///{break}
{cmd: (Innov > in1-in4) (Effic > ef1-ef4) (Green > gr1-gr4), } ///{break}
{cmd: structural(HQD RA MP RM ESG, RA ESG, MP ESG, RM ESG) } ///{break}
{cmd: higher("ESG: E S G, formative; HQD: Innov Effic Green, reflective") } ///{break}
{cmd: group(soe, method(permutation) reps(1000) seed(20260819))}{p_end}

    {hline}

{marker output}{...}
{title:Example output (excerpt)}

{pstd}
The following excerpt shows the plssem2 output for the ESG research model
(simulated data, n = 260; full results in the Word and LaTeX versions in the
{cmd:results} folder and in the example do-files):

{p 8 12 2}
{cmd:. plssem2 (E > e1-e4) (S > s1-s4) (G > g1-g4) (RA > ra1-ra4) (MP > mp1-mp4) (RM > rm1-rm4) } ///{break}
{cmd: (Innov > in1-in4) (Effic > ef1-ef4) (Green > gr1-gr4), } ///{break}
{cmd: structural(HQD RA MP RM ESG, RA ESG, MP ESG, RM ESG)} ///{break}
{cmd: higher("ESG: E S G, formative; HQD: Innov Effic Green, reflective")} ///{break}
{cmd: boot(999) seed(20260819) bca blindfold(7) digits(4)}
{break}
{com}.{break}
{com}Structural model (inner model){break}
{com}Path coefficients (OLS among the composite scores); significance{break}
{com}is obtained by nonparametric bootstrap (999 replications).{break}
{com}Confidence intervals are bias-corrected and accelerated (BCa).{break}
{break}
{com}Path                     Coef       SE       t      p>|t|   [95% CI]{break}
{com}RA <- ESG              0.4407    0.0534    8.26    0.0000  [0.3305, 0.5397]{break}
{com}MP <- ESG              0.2685    0.0554    4.85    0.0000  [0.1405, 0.3678]{break}
{com}RM <- ESG              0.4345    0.0505    8.61    0.0000  [0.3160, 0.5157]{break}
{com}HQD <- RA              0.1715    0.0645    2.66    0.0078  [0.0359, 0.2949]{break}
{com}HQD <- MP              0.2204    0.0608    3.62    0.0003  [0.1079, 0.3508]{break}
{com}HQD <- RM              0.0659    0.0635    1.04    0.2991  [-0.0557, 0.1900]{break}
{com}HQD <- ESG             0.2192    0.0707    3.10    0.0019  [0.0659, 0.3460]{break}
{break}
{com}Endogenous LV   R-squared{break}
{com}RA               0.1942{break}
{com}MP               0.0721{break}
{com}RM               0.1888{break}
{com}HQD              0.2218{break}
{p_end}

{pstd}
(Figures are based on the simulated data of {cmd:python/run_example.py} and
illustrate the program output; replace them with the project's own results.)

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:plssem2} stores the following in {cmd:e()}:

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(k_lv)}}number of latent variables{p_end}
{synopt:{cmd:e(k_mv)}}number of manifest variables (indicators){p_end}
{synopt:{cmd:e(k_aux)}}number of auxiliary variables (0){p_end}
{synopt:{cmd:e(iterations)}}number of iterations to convergence{p_end}
{synopt:{cmd:e(converged)}}1 if the algorithm converged, 0 otherwise{p_end}
{synopt:{cmd:e(tolerance)}}convergence tolerance{p_end}
{synopt:{cmd:e(maxiter)}}maximum number of iterations{p_end}
{synopt:{cmd:e(reps)}}number of bootstrap replications (if {cmd:boot()}){p_end}
{synopt:{cmd:e(n_inadmissibles)}}number of inadmissible bootstrap
replications (if {cmd:boot()}){p_end}
{synopt:{cmd:e(level)}}confidence level{p_end}
{synopt:{cmd:e(blindfold)}}blindfolding omission distance (if
{cmd:blindfold()}){p_end}

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:plssem2}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(title)}}title in the estimation output{p_end}
{synopt:{cmd:e(estat_cmd)}}program implementing {cmd:estat}{p_end}
{synopt:{cmd:e(predict)}}program implementing {cmd:predict}{p_end}
{synopt:{cmd:e(lvs)}}latent variables used{p_end}
{synopt:{cmd:e(mvs)}}manifest variables (indicators) used{p_end}
{synopt:{cmd:e(reflective)}}reflective (Mode A) latent variables{p_end}
{synopt:{cmd:e(formative)}}formative (Mode B) latent variables{p_end}
{synopt:{cmd:e(wscheme)}}inner weighting scheme used{p_end}
{synopt:{cmd:e(convcrit)}}convergence criterion used{p_end}
{synopt:{cmd:e(init)}}initialization method used{p_end}
{synopt:{cmd:e(struct_eqs)}}structural equations as specified{p_end}
{synopt:{cmd:e(higher)}}higher-order specifications (if any){p_end}
{synopt:{cmd:e(bca)}}{cmd:bca} if the {cmd:bca} option was used{p_end}

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}vector of the structural path coefficients (direct
effects), named {it:"dep:pred"}{p_end}
{synopt:{cmd:e(V)}}bootstrap covariance matrix of the path coefficients
(if {cmd:boot()}){p_end}
{synopt:{cmd:e(b_indirect)}}matrix of indirect effects (P x P){p_end}
{synopt:{cmd:e(b_total)}}matrix of total effects (P x P){p_end}
{synopt:{cmd:e(indirect_effects)}}same as {cmd:e(b_indirect)}{p_end}
{synopt:{cmd:e(total_effects)}}same as {cmd:e(b_total)}{p_end}
{synopt:{cmd:e(pathcoef)}}matrix of path coefficients (P x P){p_end}
{synopt:{cmd:e(loadings)}}matrix of outer loadings (Q x P){p_end}
{synopt:{cmd:e(outerweights)}}matrix of outer weights (Q x P){p_end}
{synopt:{cmd:e(cross_loadings)}}matrix of cross loadings (Q x P){p_end}
{synopt:{cmd:e(scores)}}matrix of the latent variable (composite) scores
(n x P){p_end}
{synopt:{cmd:e(rsquared)}}row vector of R-squared (1 x P){p_end}
{synopt:{cmd:e(alpha)}}row vector of Cronbach's alpha (1 x P){p_end}
{synopt:{cmd:e(cr)}}row vector of composite reliability rho_c (1 x P){p_end}
{synopt:{cmd:e(ave)}}row vector of average variance extracted (1 x P){p_end}
{synopt:{cmd:e(lvcorr)}}latent variable correlation matrix (P x P){p_end}
{synopt:{cmd:e(htmt)}}HTMT matrix (P x P){p_end}
{synopt:{cmd:e(vif)}}inner model VIF matrix (P x P){p_end}
{synopt:{cmd:e(f2)}}effect size matrix (P x P){p_end}
{synopt:{cmd:e(modes)}}row vector of the measurement modes (1 = Mode B){p_end}
{synopt:{cmd:e(adj_meas)}}measurement model adjacency matrix{p_end}
{synopt:{cmd:e(adj_struct)}}structural model adjacency matrix{p_end}
{synopt:{cmd:e(se_path)}}bootstrap standard errors of the path coefficients
(if {cmd:boot()}){p_end}
{synopt:{cmd:e(ci_path)}}2 x K bootstrap confidence intervals of the path
coefficients (if {cmd:boot()}){p_end}
{synopt:{cmd:e(se_load)}}bootstrap standard errors of the outer loadings
(if {cmd:boot()}){p_end}
{synopt:{cmd:e(ci_load)}}bootstrap confidence intervals of the outer loadings
(if {cmd:boot()}){p_end}
{synopt:{cmd:e(se_weg)}}bootstrap standard errors of the outer weights
(if {cmd:boot()}){p_end}
{synopt:{cmd:e(ci_weg)}}bootstrap confidence intervals of the outer weights
(if {cmd:boot()}){p_end}
{synopt:{cmd:e(ci_ind)}}bootstrap confidence intervals of the indirect
effects, 2 x P2 (if {cmd:boot()}){p_end}
{synopt:{cmd:e(ci_tot)}}bootstrap confidence intervals of the total
effects, 2 x P2 (if {cmd:boot()}){p_end}
{synopt:{cmd:e(ci_r2)}}bootstrap CIs of R-squared (if {cmd:boot()}){p_end}
{synopt:{cmd:e(q2_redundancy)}}row vector of redundancy Q2 (if
{cmd:blindfold()}){p_end}
{synopt:{cmd:e(q2_communality)}}row vector of communality Q2 (if
{cmd:blindfold()}){p_end}
{synopt:{cmd:e(q2_ind_red)}}per-indicator redundancy Q2 vector
(if {cmd:blindfold()}){p_end}
{synopt:{cmd:e(q2_ind_com)}}per-indicator communality Q2 vector
(if {cmd:blindfold()}){p_end}

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks the estimation sample{p_end}
{p2colreset}{...}

{pstd}
After {cmd:group()}, {cmd:plssem2} stores the group-specific estimates and the
test results: {cmd:e(groupvar)}, {cmd:e(gmethod)}, {cmd:e(greps)},
{cmd:e(galpha)}, {cmd:e(W1)}, {cmd:e(W2)}, {cmd:e(L1)}, {cmd:e(L2)},
{cmd:e(B1)}, {cmd:e(B2)}, {cmd:e(R2_1)}, {cmd:e(R2_2)}, {cmd:e(diff_obs)} and
{cmd:e(p_values)}.

{marker methods}{...}
{title:Methods and formulas}

{pstd}
Let X be the n x Q matrix of standardized indicators and let the Q x P matrix
{bf:A} (adjacency of the measurement model) and the P x P matrix {bf:S}
(adjacency of the structural model) describe the model.  In iteration t of
Stage 1, with outer weights W(t):

{pstd}
1. Outer approximation: {it:Y_j} = sum_k {it:w_jk} {it:x_k}, standardized.
2. Inner weights E: {bf:centroid} E_jk = sign(r_jk); {bf:factorial}
   E_jk = r_jk; {bf:path} E_jk = path coefficient of the regression of
   Y_j on its predictors, and E_jk = r_jk for the successors of j, where
   r_jk = corr(Y_j, Y_k).
3. Inner approximation: {it:Z_j} = sum_k E_jk {it:Y_k}, standardized.
4. Outer weights update: Mode A, w_jk = corr(x_jk, Z_j); Mode B,
   w_j = (X_j'X_j)^{-1} X_j' Z_j.
5. Stop when the change of the outer weights is below the tolerance.

{pstd}
In Stage 2 the final scores Y = X W are standardized; the loadings are
lambda_jk = corr(x_jk, Y_j); the path coefficients of each endogenous
equation are the OLS coefficients of Y_j on its predictors; R2_j is the
coefficient of determination of that regression.  Cronbach's alpha,
rho_c = (sum lambda)^2 / [(sum lambda)^2 + sum(1 - lambda^2)] and
AVE = mean(lambda^2) are computed per block.  The HTMT ratio of correlations
between constructs i and j is

{p 8 12 2}
HTMT_ij = (1/(Ki Kj)) sum_k sum_l r(x_ik, x_jl) /
          sqrt[ (2/(Ki(Ki-1))) sum_{k<l} r(x_ik, x_il)
              * (2/(Kj(Kj-1))) sum_{k<l} r(x_jk, x_jl) ]

{pstd}
The total effects are T = (I - B)^{-1} - I, and the indirect effects are
T - B, where B is the matrix of path coefficients.  In the blindfolding
procedure with omission distance d, each of the d groups of cases is omitted
in turn; the model is re-estimated on the remaining cases and the omitted
indicator values are predicted from the estimated weights, loadings and path
coefficients (communality: loading times the case-wise composite score;
redundancy: loading times the structural prediction of the score); Q2 = 1 -
SSE/SSO accumulated over the omitted data points.  The BCa bootstrap
intervals follow Efron (1987): the bias correction z0 = Phi^{-1}(proportion
of bootstrap estimates below the original estimate) and the acceleration
estimated by the jackknife are used to adjust the percentile levels of the
bootstrap distribution.

{marker references}{...}
{title:References}

{marker Becker2012}{...}
{phang}
Becker, J.-M., Klein, K., and Wetzels, M. 2012.  Hierarchical latent variable
models in PLS-SEM: Guidelines for using reflective-formative type models.
{it:Long Range Planning}, 45(5-6): 359-394.

{marker Chin1998}{...}
{phang}
Chin, W. W. 1998.  The partial least squares approach to structural equation
modeling.  In Marcoulides, G. A. (ed.), {it:Modern Methods for Business Research},
pp. 295-336.  Mahwah, NJ: Lawrence Erlbaum.

{marker Efron1987}{...}
{phang}
Efron, B. 1987.  Better bootstrap confidence intervals.  {it:Journal of the American Statistical Association}, 82(397): 171-185.

{marker Geisser1974}{...}
{phang}
Geisser, S. 1974.  A predictive approach to the random effect model.
{it:Biometrika}, 61(1): 101-107.

{marker Henseler2015}{...}
{phang}
Henseler, J., Ringle, C. M., and Sarstedt, M. 2015.  A new criterion for
assessing discriminant validity in variance-based structural equation
modeling.  {it:Journal of the Academy of Marketing Science}, 43(1): 115-135.

{marker Henseler2016}{...}
{phang}
Henseler, J., Ringle, C. M., and Sarstedt, M. 2016.  Testing measurement
invariance of composites using partial least squares.  {it:International Marketing Review}, 33(3): 405-431.

{marker Lohmoller1989}{...}
{phang}
Lohmöller, J.-B. 1989.  {it:Latent Variable Path Modeling with Partial Least Squares}.  Heidelberg: Physica-Verlag.

{marker Sarstedt2019}{...}
{phang}
Sarstedt, M., Hair, J. F., Cheah, J.-H., Becker, J.-M., and Ringle, C. M.
2019.  How to specify, estimate, and validate higher-order constructs in
PLS-SEM.  {it:Australasian Marketing Journal}, 27(3): 197-211.

{marker Stone1974}{...}
{phang}
Stone, M. 1974.  Cross-validatory choice and assessment of statistical
predictions.  {it:Journal of the Royal Statistical Society, Series B},
36(2): 111-147.

{marker VenturiniMehmetoglu2019}{...}
{phang}
Venturini, S., and Mehmetoglu, M. 2019.  plssem: A Stata package for partial
least squares structural equation modeling.  {it:The Stata Journal},
19(4): 899-926.

{marker Wold1975}{...}
{phang}
Wold, H. O. A. 1975.  Path models with latent variables: The NIPALS
approach.  In Blalock, H. M. et al. (eds.), {it:Quantitative Sociology: International Perspectives on Mathematical and Statistical Modeling},
pp. 307-357.  New York: Academic Press.

{phang}
Hair, J. F., Hult, G. T. M., Ringle, C. M., and Sarstedt, M. 2022.
{it:A Primer on Partial Least Squares Structural Equation Modeling (PLS-SEM)}.  3rd ed.  Thousand Oaks, CA: Sage.

{phang}
Mehmetoglu, M., and Venturini, S. 2021.  {it:Structural Equation Modelling with Partial Least Squares Using Stata and R}.  Boca Raton, FL: CRC Press.

{marker authors}{...}
{title:Authors}

{pstd}
{bf:WU Lianghai}{break}
School of Business, Anhui University of Technology (AHUT){break}
Ma'anshan, Anhui, China{break}
{browse "mailto:agd2010@yeah.net":agd2010@yeah.net}{break}

{pstd}
{bf:WU Hanyan}{break}
Department of Accountancy, City University of Hong Kong (CityU){break}
{browse "mailto:2325476320@qq.com":2325476320@qq.com}{break}

{pstd}
Development date: 19 August 2026.  The development of {bf:plssem2} is based
on Stata's official {bf:sem} and {bf:gsem} (syntax and post-estimation
conventions) and on the unofficial program {bf:plssem} (Venturini and
Mehmetoglu 2019).  This version is an independent implementation of the
PLS-SEM algorithm; it is not affiliated with StataCorp or with the authors
of plssem.

{marker seealso}{...}
{title:Also see}

{p 4 6 2}
{help sem:sem} -- Structural equation modeling (CB-SEM){p_end}
{p 4 6 2}
{help gsem:gsem} -- Generalized structural equation modeling{p_end}
{p 4 6 2}
{helpb plssem2_estat:plssem2 postestimation} -- Postestimation commands{p_end}
{p 4 6 2}
{helpb plssem2_predict:plssem2 predict} -- predict after plssem2{p_end}
{p 4 6 2}
{helpb plssem:plssem} -- Partial least squares structural equation modeling
(SSC){p_end}
