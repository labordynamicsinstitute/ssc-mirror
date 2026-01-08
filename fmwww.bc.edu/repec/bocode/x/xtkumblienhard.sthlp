{smcl}
{* version 1.0.0, 05Jan2026 }{...}
{cmd:help xtkumblienhard}
{hline}

{title:Title}

{pstd}
    {hi: Performs Estimations of Generalized Four-Component Panel Data Stochastic Frontier Models}
	


{title:Syntax}

{pstd}
{cmd:xtkumblienhard}
{depvar}
{indepvars}
{ifin} {weight}
{cmd:,} {cmdab:stub:(}string{cmd:)} [{it:options}]



{synoptset 27 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent :* {cmdab:stub:}{cmd:(}string{cmd:)}}designates a string name from which new variable names will be created {p_end}
{synopt :{opt fe}}use the fixed-effects estimator instead of the default random-effects estimator  {p_end}
{synopt :{opth vce(vcetype)}}{it:vcetype} may be {opt r:obust},
   {opt cl:uster} {it:clustvar} {p_end}
{synopt :{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt :{it:{help frontier:frontier_options}}}in addition to the options listed above, all options of the command {bf:{manhelp frontier R}} can be used {p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2} * {cmd:stub()} is required.{p_end}
{p 4 6 2} You must {opt tsset}  or {opt xtset} your data before using {cmd:xtkumblienhard};
see {manhelp tsset TS} and {manhelp xtset XT}.{p_end}
{p 4 6 2} {depvar}, {indepvars} may contain time-series operators; see {help tsvarlist}.{p_end}
{p 4 6 2} {indepvars} may contain factor variables; see {help fvvarlist}. {p_end}
{p 4 6 2} {opt fweight}s and {opt pweight}s are allowed; see {help weight}. {p_end}



{title:Description}

{pstd} 
{cmd:xtkumblienhard} is a powerful and user-friendly {hi:Stata} command designed to estimate Generalized Four-Component 
Panel Data Stochastic Frontier Models, all in a single line of code. This package streamlines the estimation of 
a sophisticated stochastic frontier framework where the composite error term is decomposed into four distinct 
components: unobserved individual heterogeneity, persistent inefficiency, transitory inefficiency and random 
noise. By clearly separating these sources of variation, {cmd:xtkumblienhard} enables researchers to gain deeper 
insights into performance dynamics across panel data settings. This model builds on the influential and excellent 
works of Kumbhakar, Lien and Hardaker (Journal of Productivity Analysis, 2014), Kumbhakar, Wang and Horncastle 
(Cambridge University Press, 2015), and Nguyen, Sickles and Zelenyuk (Springer, 2022), who 
originally implemented it through multi-step procedures. The innovation of {cmd:xtkumblienhard} lies in its 
simplicity: it brings the full power of this four-component framework to {hi:Stata} users with native ADO language 
syntax, eliminating the need for complex coding or external scripts. Rather than replacing these foundational and 
outstanding contributions, {cmd:xtkumblienhard} democratizes access to advanced stochastic frontier analysis, making 
it faster, easier, and more intuitive for applied researchers, analysts, and students alike. Whether you are studying 
firm-level productivity, benchmarking efficiency, or exploring heterogeneity in performance, {cmd:xtkumblienhard} is 
your go-to tool for robust and elegant estimation.



{title:Econometric Model}

{p 4 6 2} The generalized four-component panel data stochastic frontier model is specified as: {p_end} 
{p 4 6 2} {it:y_it = beta_0 + x'_it*beta + c_i - eta_i + v_it - u_it} {space 2} {hi:(1)} {p_end}

{p 4 6 2} where the distributional assumptions are: {p_end} 
{p 4 6 2} {it:c_i ~ iid N(0, sigma_c^2)}, {space 3} {it:eta_i ~ iid N+(0, sigma_eta^2)} {p_end} 
{p 4 6 2} {it:v_it ~ iid N(0, sigma_v^2)}, {space 3} {it:u_it ~ iid N+(0, sigma_u^2)} {p_end}

{p 4 6 2} In {hi:Equation (1)}: {p_end} {p 4 6 2} {it:y_it} is the dependent variable {p_end} 
{p 4 6 2} {it:x'_it} are the regressors {p_end} {p 4 6 2} {it:beta_0} and {it:beta} are the parameters of interest {p_end} 
{p 4 6 2} {it:c_i} captures unobserved individual heterogeneity {p_end} 
{p 4 6 2} {it:eta_i} denotes persistent inefficiency {p_end} 
{p 4 6 2} {it:u_it} denotes transitory inefficiency {p_end} 
{p 4 6 2} {it:v_it} is the random disturbance {p_end}

{pstd} As shown by Kumbhakar et al. (2014), the model in {hi:Equation (1)} can be estimated through a multi-step 
procedure {it:(three steps in total)}. To facilitate estimation, the model can be rewritten as: {p_end} 
{p 4 6 2} {it:y_it = beta_0* + x'_it*beta + alpha_i + epsilon_it} {space 2} {hi:(2)} {p_end}

{p 4 6 2} with the following definitions: {p_end} 
{p 4 6 2} {it:beta_0* = beta_0 – E[eta_i] – E[u_it]} {space 3} {hi:(3)} {p_end} 
{p 4 6 2} {it:alpha_i = c_i – eta_i + E[eta_i]} {space 8} {hi:(4)} {p_end} 
{p 4 6 2} {it:epsilon_it = v_it – u_it + E[u_it]} {space 6} {hi:(5)} {p_end}

{pstd} In {hi:Equations (3)–(5)}, {hi:E[.]} denotes the expectation operator. The reformulated model 
in {hi:Equation (2)} is equivalent to a standard panel data specification and can be estimated using 
conventional panel data methods. Once {hi:Equation (2)} is estimated, predicted values 
of {it:alpha_i} and {it:epsilon_it} ({it:alpha_i_hat} and {it:epsilon_it_hat}) are 
obtained. These predictions are then used to recover the persistent and transitory inefficiency 
components by applying standard stochastic frontier techniques to {hi:Equations (4)} 
and {hi: (5)}, substituting {it:alpha_i_hat} and {it:epsilon_it_hat} for {it:alpha_i} 
and {it:epsilon_it}, respectively. {p_end}



{title:Options}

{phang}
{opt stub(string)} designates a string name from which new variable names will be 
created. To form this option, you put inside the parentheses a string name (without the 
double quotes). Then new variable names will be created from this string. You must 
specify this option in order to get a result. Hence this option is required.

{phang}
{opt fe} requests the fixed-effects (within) regression estimator. If you specify this 
option, you request to use the fixed-effects estimator instead of the default random-effects estimator.

{phang}
{opth vce(vcetype)} specifies the type of standard error reported, which
includes types that are robust to some kinds of misspecification ({cmd:robust}), that allow
for intragroup correlation ({cmd:cluster} {it:clustvar}).

{phang2}
{cmd:vce(robust)} is equivalent to specifying
{cmd:vce(cluster} {it:panelvar}{cmd:)}.

{phang2}
{cmd:vce(cluster} {it:clustvar}{cmd:)} specifies that standard errors
allow for intragroup correlation within groups defined by one 
variable in {it:clustvar}, relaxing the usual requirement that the
observations be independent.  For example, {cmd:vce(cluster clustvar)}
produces cluster-robust standard errors that allow for observations
that are independent across groups defined by {cmd:clustvar} but not
necessarily independent within groups.

{phang2}
For your information, the {hi:Defaults Variance Estimators} are: {hi:conventional} for 
the {it:first step}, and {hi:oim} for the {it:second} and {it:third steps}.

{phang}
{opt level(#)} specifies the confidence level, as a percentage, for confidence 
intervals. The default is {hi:level(95)} or as set by {helpb level:set level}. 
See {helpb estimation options##level():[R] Estimation options} for more information.

{phang}
{it:{help frontier:frontier_options}} in addition to the options listed above, all options 
of the command {bf:{manhelp frontier R}} can be used. You can form these {it:options} in exactly 
the same way as you would do with the command {bf:frontier}. Simply enter them as if you were 
using the command {bf:frontier}.  See {bf:{manhelp frontier R}} for more details.



{title:Return values for xtkumblienhard}

{pstd} The command {cmd:xtkumblienhard} stores its results in {cmd:e()}, following the three-step estimation
 procedure described above. Each step produces its own set of return values, which can be accessed and
 inspected individually. This design allows users to verify intermediate results, replicate calculations, and 
 better understand how the estimates are obtained. {p_end}

{pstd} To access the saved results, you need to restore the corresponding estimation set and 
then list the stored values. The procedure is as follows: {p_end}

{p 4 8 2}{hi:To get the first-step results, you type:} {p_end} 
{p 4 8 2}estimates restore step_1_stub{p_end} 
{p 4 8 2}ereturn list{p_end}

{p 4 8 2}{hi:To get the second-step results, you type:} {p_end} 
{p 4 8 2}estimates restore step_2_stub{p_end} 
{p 4 8 2}ereturn list{p_end}

{p 4 8 2}{hi:To get the third-step results, you type:} {p_end} 
{p 4 8 2}estimates restore step_3_stub{p_end} 
{p 4 8 2}ereturn list{p_end}

{pstd} In these commands, the placeholder {hi:stub} refers to the string name you specified in 
your estimation call. This stub is used to generate new variable names and to organize the stored results 
consistently across the three steps. Choosing a clear and memorable stub name will make it easier to 
track your outputs. {p_end}

{pstd} For additional details on how to manage and inspect stored estimation 
results, see {bf:{manhelp estimates R}} and {bf:{manhelp ereturn P}}. These references explain 
how {hi:Stata} handles estimation sets and return values, and they provide guidance on 
integrating {cmd:xtkumblienhard} outputs into your broader workflow. {p_end}



{title:Examples}

{p 4 8 2} Before beginning the estimations, we use the {hi:set more off} instruction to tell
{hi:Stata} not to pause when displaying the output. {p_end}

{p 4 8 2}{stata "set more off"}{p_end}

{p 4 8 2} We illustrate the use of the command {cmd:xtkumblienhard} with the dataset {hi:xtkumblienharddata.dta}. This 
dataset contains a sample of panel data for developing countries in the World. It contains 7 periods of 
4 non overlapping years from 1996-1999, 2000-2003 to 2020-2023. {p_end}

{p 4 8 2}{stata "use http://fmwww.bc.edu/repec/bocode/x/xtkumblienharddata.dta, clear"}{p_end}

{p 4 8 2} Next we describe the dataset to see the definition of each variable. {p_end}

{p 4 8 2} We observe that the dataset begins with the World Bank country codes, country names, and time periods. It 
also includes qualitative variables that define subsamples within the database, allowing users to distinguish 
groups of interest. The panel structure has already been declared with {cmd:xtset}, so the data are ready for 
panel estimation. Following this, the dataset provides the main quantitative variables of interest. All 
quantitative variables are expressed in logarithmic form, consistent with the estimation of stochastic 
frontier production functions presented in this {hi:Examples} section. {p_end}

{p 4 8 2}{stata "describe"}{p_end}

{p 4 8 2} We begin the regressions by estimating a random-effects Cobb–Douglas stochastic frontier 
production function. To do so, we indicate the name of the command {cmd:xtkumblienhard}, followed by the dependent 
variable {hi:lgnetodaidrec}. We then list the explanatory variables: 
{hi:lgmilitexppcgdp}, {hi:lgextdebtst}, {hi:lgpoptotal}, and {hi:lgevitotal}. After specifying the model, we 
include the relevant options. In particular, we provide the string {hi:sfadj1}, without quotation marks, to 
the option {cmd:stub()}, which determines the suffix used when generating new variables during the estimation 
steps. {p_end}

{p 4 8 2}{stata "xtkumblienhard lgnetodaidrec lgmilitexppcgdp lgextdebtst lgpoptotal lgevitotal, stub(sfadj1)"}{p_end}

{p 4 8 2} The output produced by the command {cmd:xtkumblienhard} is composed of three parts, each corresponding 
to each step of the multi-step estimation procedure. The first part, 
titled {hi:STEP 1: Random-Effects Panel Data Regression} displays 
the {it:Random-effects GLS regression} which contains the estimated parameters of interest. The second 
part, titled {hi:STEP 2: SFA Estimation to Obtain the Persistent (In)Efficiency} displays 
the {it:Stochastic frontier normal/half-normal model} that allows to calculate the Persistent Inefficiency 
and Efficiency Scores. The third part, titled {hi:STEP 3: SFA Estimation to Obtain the Transitory (In)Efficiency} 
displays the {it:Stochastic frontier normal/half-normal model} that allows to calculate the Transitory Inefficiency 
and Efficiency Scores. {p_end}

{p 4 8 2} Let us interpret the results we just found in this estimation. 
In this {hi:Examples} section, our objective is to estimate a country's Aid Absorption Capacity by 
regressing actual foreign aid on key economic and social characteristics. Each variable has an expected sign 
grounded in standard aid-allocation patterns. Higher military spending is often associated with greater aid 
inflows, as donors may support countries viewed as strategic or important for regional stability. External debt 
is also expected to have a positive sign, since highly indebted countries frequently receive assistance to ease 
financial pressures. By contrast, larger populations tend to reduce aid per capita, implying a negative 
effect. Countries exposed to external economic shocks - such as commodity dependence or vulnerability to 
natural disasters - typically receive more aid, so a positive sign is expected. The first-step results confirm these 
expectations: all coefficients are statistically 
significant, display the anticipated signs, and have economically meaningful magnitudes. These findings 
indicate that the model behaves as expected and provides a consistent basis for the inefficiency and efficiency 
analyses. {p_end}

{p 4 8 2} Next, we use {cmd:describe} to display all previously generated variables along with their 
labels, allowing us to verify that each variable has been created and documented correctly. {p_end}

{p 4 8 2}{stata "describe Alpha_sfadj1 Epsilon_sfadj1 Ineff_Pers_sfadj1 Eff_Pers_sfadj1 Ineff_Trans_sfadj1 Eff_Trans_sfadj1 Overall_TE_sfadj1 Overall_Ineff_sfadj1"}{p_end}

{p 4 8 2} We now summarize these variables to obtain a quick overview of their distributions and basic 
descriptive statistics. {p_end}

{p 4 8 2}{stata "summarize Alpha_sfadj1 Epsilon_sfadj1 Ineff_Pers_sfadj1 Eff_Pers_sfadj1 Ineff_Trans_sfadj1 Eff_Trans_sfadj1 Overall_TE_sfadj1 Overall_Ineff_sfadj1, sep(0)"}{p_end}

{p 4 8 2} The summary statistics show that the average of the estimated composed random individual-specific effects 
is very small, as expected. The mean of the composed error term is approximately zero, which is consistent with its 
definition. The estimated average Persistent Inefficiency is 175.65%, while the corresponding Persistent Efficiency 
averages 31%. The estimated average Transitory Inefficiency is 37.72%, with a Transitory Efficiency 
of 71.21%. Finally, the estimated Overall Technical Efficiency averages 22.40%, and Overall Inefficiency 
averages 213.38%. {p_end}

{p 4 8 2} We now list the World Bank country codes, the time periods, and all previously generated variables 
to inspect them in detail and verify that each has been created correctly. {p_end}

{p 4 8 2}{stata "list pbm period Alpha_sfadj1 Epsilon_sfadj1 Ineff_Pers_sfadj1 Eff_Pers_sfadj1 Ineff_Trans_sfadj1 Eff_Trans_sfadj1 Overall_TE_sfadj1 Overall_Ineff_sfadj1, sep(7)"}{p_end}

{p 4 8 2} Let us plot a histogram of the Overall Technical Efficiency scores. {p_end}

{p 4 8 2}{stata "histogram Overall_TE_sfadj1, bin(100) normal"}{p_end}

{p 4 8 2} We notice that, we have a right-skewed or positively-skewed distribution for the overall efficiency 
scores. Hence, the mean efficiency is greater than the median efficiency scores. {p_end}

{p 4 8 2} To display the results from the first step, we type: {p_end}

{p 4 8 2}{stata "estimates restore step_1_sfadj1"}{p_end}

{p 4 8 2}{stata "ereturn list"}{p_end}

{p 4 8 2} To display the results from the second step, we type: {p_end}

{p 4 8 2}{stata "estimates restore step_2_sfadj1"}{p_end}

{p 4 8 2}{stata "ereturn list"}{p_end}

{p 4 8 2} To display the results from the third step, we type: {p_end}

{p 4 8 2}{stata "estimates restore step_3_sfadj1"}{p_end}

{p 4 8 2}{stata "ereturn list"}{p_end}

{p 4 8 2} For more information on working with stored estimation results, see {bf:{manhelp estimates R}} 
and {bf:{manhelp ereturn P}}. {p_end}

{p 4 8 2} We now illustrate how to use {cmd:xtkumblienhard} in combination with the {cmd:predict} command. {p_end}

{p 4 8 2} We begin by restoring the estimation results from the first step. {p_end}

{p 4 8 2}{stata "estimates restore step_1_sfadj1"}{p_end}

{p 4 8 2} Then, we compute the linear prediction based on the first-step model. {p_end}

{p 4 8 2}{stata "predict double lgnetodaidrechat, xb"}{p_end}

{p 4 8 2} We describe the previously created variable to see its label. {p_end}

{p 4 8 2}{stata "describe lgnetodaidrechat"}{p_end}

{p 4 8 2} We summarize this variable. {p_end}

{p 4 8 2}{stata "summarize lgnetodaidrechat"}{p_end}

{p 4 8 2} We now illustrate how to tabulate the estimation results produced by {cmd:xtkumblienhard}. We 
begin by running a new regression and supplying a different string, {hi:sfadj2}, to the option {cmd:stub()} so 
that the results from this estimation are stored separately from the previous one. {p_end}

{p 4 8 2}{stata "xtkumblienhard lgnetodaidrec lggdppcapcstd lgmilitexppcgdp lggovernanceidx lggoodpolicyidx, stub(sfadj2)"}{p_end}

{p 4 8 2} The expected coefficient signs follow well-established patterns in the aid allocation literature. Higher GDP 
per capita generally reduces aid inflows, as wealthier countries are viewed as less dependent on external 
assistance; a negative sign is therefore expected. Military spending often attracts more aid because 
donors may support countries seen as strategic partners or contributors to regional stability, implying a 
positive sign. Stronger governance - reflected in better institutions, lower corruption, and more effective 
public administration - tends to increase donor confidence and thus aid receipts, again suggesting a positive 
sign. Similarly, countries with sound macroeconomic policies are typically rewarded with higher aid, as donors 
prefer environments where funds are more likely to be used effectively. The first-step results confirm these 
expectations: all coefficients are statistically significant, display the anticipated signs, and have economically 
meaningful magnitudes. 
These findings confirm that the estimation behaves as anticipated and 
provides a reliable basis for our study. {p_end}

{p 4 8 2} We can now tabulate the first-step results from both regressions using {bf:{help estimates table}}. {p_end}

{p 4 8 2}{stata "estimates table step_1_sfadj1 step_1_sfadj2, b(%7.4f) p(%7.4f) stats(N r2_o)"}{p_end}

{p 4 8 2} The same comparison can be produced with {bf:{manhelp etable R}}. {p_end}

{p 4 8 2}{stata "etable, estimates(step_1_sfadj1 step_1_sfadj2) cstat(_r_b) cstat(_r_p, nformat(%7.4f)) mstat(N) mstat(r2_o)"}{p_end}

{p 4 8 2} Readers/Users may also utilize {bf:{help outreg}} (if installed), {bf:{help outreg2}} 
(if installed), {bf:{help estout}} (if installed), or any other {hi:Stata} command designed to tabulate 
stored estimation results. {p_end}

{p 4 8 2} Next, we illustrate how to use some {it:{help frontier:frontier_options}}. In some cases, the second and third 
steps of the estimation may encounter convergence difficulties. When this occurs, these options can help improve 
numerical stability and guide the optimizer toward a solution. In the example below, we 
apply {hi:difficult}, {hi:technique(dfp)}, {hi:iterate(20000)}, and {hi:nrtolerance(0.005)} to demonstrate how 
such options can be incorporated when needed. {p_end}

{p 4 8 2}{stata "xtkumblienhard lgnetodaidrec lggdppcapcstd lgmilitexppcgdp lggovernanceidx lggoodpolicyidx, stub(sfadj3) difficult technique(dfp) iterate(20000) nrtolerance(0.005)"}{p_end}

{p 4 8 2} Up to this point, the first-step estimation has relied on the default random-effects estimator. The 
following example shows how to instead use the fixed-effects estimator in the first step. {p_end}

{p 4 8 2}{stata "xtkumblienhard lgnetodaidrec lgmilitexppcgdp lgextdebtst lgevitotal, stub(sfadj4) fe"}{p_end}

{p 4 8 2} The results indicate that all regressors remain statistically significant, retain their expected 
signs, and exhibit economically meaningful absolute values. This confirms that the first-step estimates of our study are 
robust to the choice between random-effects and fixed-effects specifications. {p_end}

{p 4 8 2} We now illustrate how to use {cmd:xtkumblienhard} with the {bf:{manhelp if U}} qualifier, and simultaneously 
show how to apply the {hi:vce(robust)} option. We begin by estimating a first model for Low-Income Countries only: {p_end}

{p 4 8 2}{stata `"xtkumblienhard lgnetodaidrec lggdppcapcstd lggovernanceidx lggoodpolicyidx if incomegrpwb == "Low income", stub(sfadj5) vce(robust)"'}{p_end}

{p 4 8 2} Next, we estimate a second model for Lower Middle-Income and Upper Middle-Income Countries combined: {p_end}

{p 4 8 2}{stata `"xtkumblienhard lgnetodaidrec lgmilitexppcgdp lgextdebtst lgevitotal if (incomegrpwb == "Lower middle income" | incomegrpwb == "Upper middle income"), stub(sfadj6) vce(robust)"'}{p_end}

{p 4 8 2} In both subsample estimations, all regressors remain statistically significant, preserve their expected 
signs, and display economically meaningful magnitudes. These results confirm that our findings are robust when the 
analysis is conducted on income-group subsamples. {p_end}

{p 4 8 2} We now illustrate how to include a {it:time trend} when using {cmd:xtkumblienhard}. To do so, we add the 
variable {hi:period} to our standard Cobb-Douglas specification. At the same time, we show how to apply the 
option {cmd:vce(cluster} {it:clustvar}{cmd:)} to obtain cluster-robust standard errors. {p_end}

{p 4 8 2}{stata "xtkumblienhard lgnetodaidrec period lggdppcapcstd lgpoptotal, stub(sfadj7) vce(cluster id)"}{p_end}

{p 4 8 2} The estimated coefficient on {hi:period} {it:(0.060353)} suggests a positive time trend in aid absorption 
capacity. Interpreted in growth-rate terms, this implies that total factor productivity associated with Net ODA and 
Aid received as a percentage of GDP increased by roughly 6.0% every four-year period, on average, across all 
countries in the sample from 1996 to 2023. This indicates a gradual improvement in countries' ability to absorb 
aid over time. {p_end}

{p 4 8 2} We next illustrate how to use the {opt level(#)} option to specify the confidence level reported in the 
estimation output. This option is useful when users require wider or narrower confidence intervals for 
inference. In the example below, we estimate the model using a 99% confidence interval. {p_end}

{p 4 8 2}{stata "xtkumblienhard lgnetodaidrec period lggdppcapcstd lgpoptotal, stub(sfadj8) vce(robust) level(99)"}{p_end}

{p 4 8 2} Specifying {opt level(99)} instructs Stata to compute 99% confidence intervals for all estimated 
coefficients, which is appropriate when a more conservative inference threshold is desired. {p_end}

{p 4 8 2} To conclude this {hi:Examples} section, we now switch from the Cobb-Douglas specification used so 
far to a more flexible Translog production function. This also provides opportunities to demonstrate the use 
of the {manhelp margins R} command for computing marginal effects 
and the implementation of factor variables (see {helpb fvvarlist}). We begin by estimating a Translog specification. {p_end}

{p 4 8 2}{stata "xtkumblienhard lgnetodaidrec per lggdppcapcstd lgpoptotal c.per#c.per  c.lggdppcapcstd#c.lggdppcapcstd  c.lgpoptotal#c.lgpoptotal  c.per#c.lggdppcapcstd  c.per#c.lgpoptotal  c.lggdppcapcstd#c.lgpoptotal,  stub(tl) vce(r)"}{p_end}

{p 4 8 2} We then restore the first-step estimation results. {p_end}

{p 4 8 2}{stata "estimates restore step_1_tl"}{p_end}

{p 4 8 2} Next, we use {manhelp margins R} to compute the {it:average marginal effects} of all independent 
variables. The option {hi:dydx(*)} requests marginal effects for every regressor, while {hi:post} stores the 
results in {hi:e()} for possible tabulation. We also specify {cmd:nochainrule} because {cmd:xtkumblienhard} is 
a community-contributed command, and margins must avoid applying the chain rule automatically. {p_end}

{p 4 8 2}{stata "margins, dydx(*) post nochainrule"}{p_end}

{p 4 8 2} The resulting marginal effects indicate that all regressors remain statistically significant, retain 
their expected signs, and exhibit economically meaningful magnitudes. These findings confirm that our results 
are robust to adopting a more flexible functional form. {p_end}

{p 4 8 2} {hi:EPILOGUE} {p_end}

{p 4 8 2} In preparing this {hi:Examples} section, we pursued two main objectives. First, we aimed to demonstrate 
how to use {cmd:xtkumblienhard} effectively through simple, transparent, and reproducible examples. Second, we 
sought to conduct an original empirical exercise on countries' Aid Absorption Capacity and Efficiency using 
stochastic frontier models for panel data, thereby offering a modest contribution to this line of 
research. Of course, these examples only scratch the surface of what can be achieved 
with {cmd:xtkumblienhard}, the accompanying dataset, and the many possibilities that arise when combining 
this command with other {hi:Stata} tools. The flexibility of the estimator, the richness of the data, and the 
breadth of {hi:Stata's ecosystem} open numerous avenues for further exploration. We leave these extensions to 
the reader/user, who is encouraged to adapt, expand, and refine the analyses according to her or his own research 
interests. {p_end}



{title:References}

{pstd}
{hi:Kumbhakar Subal C., Lien Gudbrand and Hardaker J. Brian: 2014,}
"Technical Efficiency in Competing Panel Data Models: A Study of Norwegian Grain Farming",
{it:Journal of Productivity Analysis} {bf:41}(2), 321–337, April.
{p_end}

{pstd}
{hi:Kumbhakar Subal C., Wang Hung-Jen and Horncastle Alan P.: 2015,}
"A Practitioner's Guide to Stochastic Frontier Analysis Using Stata",
{it:Cambridge University Press}, Cambridge, ISBN 9781107029514.
{p_end}

{pstd}
{hi:Nguyen Bao Hoang, Sickles Robin C. and Zelenyuk Valentin: 2022,}
"Efficiency Analysis with Stochastic Frontier Models Using Popular Statistical Softwares",
in: Duangkamon Chotikapanich, Alicia N. Rambaldi and Nicholas Rohde (eds.),
{it:Advances in Economic Measurement}, Chapter 3, pp. 129–171, Springer.
{p_end}



{title:Citation and Donation}

{pstd}
The command {cmd:xtkumblienhard} is not an {hi:Official Stata} command. Like a paper, it is a free contribution to 
the research community. If you find the command {cmd:xtkumblienhard} and its accompanying dataset useful and 
utilize them in your 
works, please cite them like a paper as it is explained in the {hi:Suggested Citation} section of 
the {hi:IDEAS/RePEc} {it:webpage} of the command. Please, also cite {hi:Kumbhakar, Lien and Hardaker (2014)}, 
{hi:Kumbhakar, Wang and Horncastle (2015)}, and 
{hi:Nguyen, Sickles and Zelenyuk (2022)} in your 
works. 
{it:Thank you infinitely, in advance, for doing all these gestures!} Please, note that citing this 
command {cmd:xtkumblienhard} and these references  are a good way to disseminate their use and their 
discovery by other researchers and analysts. Doing these actions, could also, potentially, help us, as a community, to solve 
challenging current problems and those that lie ahead in the future.

{pstd}
I would also like to ask you about one more thing, {hi:please!} I hope you are finding my {hi:Stata Packages} useful 
and insightful. If you have appreciated the work I do and would like to support me financially in continuing 
to develop these resources, I would be incredibly grateful. You can help fund my work 
through {hi:My Patreon Page} ({browse "https://patreon.com/zavrencp?utm_medium=unknown&utm_source=join_link&utm_campaign=creatorshare_creator&utm_content=copyLink":LINK HERE}) 
or through {hi:My PayPal Page} ({browse "https://www.paypal.com/donate/?hosted_button_id=UHUUCFH9W5TQE":LINK HERE}), 
which will allow me to dedicate more time and resources to creating even better 
tools and updates. Any contribution, no matter how small, is greatly appreciated 
and will go directly towards furthering my work. 
{it:Thank you so much in advance for your valuable support !} {hi:Best and Kind Regards !} 



{title:Acknowledgements}
 
{pstd} 
The command {cmd:xtkumblienhard} is a {hi:Stata} ADO File Language implementation inspired by the 
original Do-file program developed by Nguyen, Sickles, and Zelenyuk (2022). The name and theoretical 
foundation of this command are based on the influential work of Kumbhakar, Lien and Hardaker (2014), whose 
contributions to the field have been instrumental in shaping this package. I am deeply grateful to 
Bao Hoang Nguyen, Robin C. Sickles, and Valentin Zelenyuk for their pioneering implementation, and 
to Subal C. Kumbhakar, Gudbrand Lien, J. Brian Hardaker, Hung-Jen Wang, and Alan P. Horncastle for their 
extensive research and methodological advancements. I also thank StataCorp LLC for making their 
software, documentation, and resources widely accessible through both official and commercial 
channels. This {hi:Stata} package is built upon and inspired by the collective work of these scholars 
and company. I extend my sincere appreciation to all of them. As always, any remaining errors or shortcomings 
are entirely my own. Constructive feedback is warmly welcomed!

{pstd} 
Thank you, you the reader/user, for downloading and exploring this {hi:Stata} package. Your time, curiosity, and 
commitment to rigorous research mean the world to me. I am truly honored to be part of your analytical 
journey, and I hope this tool empowers your work with clarity, precision, and purpose. As an economist and 
data scientist, I offer consulting services to individuals, institutions, and companies across the 
globe. If you are working on a project that could benefit from collaboration, or if you would like to 
explore how we might work together, please feel free to reach out. I also welcome financial contributions 
to support future research, publications, and the continued development of open-access tools like 
this one. My contact details are included above and below for your convenience. I would like to close 
with a personal note of profound gratitude. To my father, my mother, my family, all Prophets, Messengers 
and their Companions, and to the Great Allah, thank you for your unwavering love, support, and faith throughout 
this long and challenging journey. Your strength has been my foundation, and your encouragement has carried me 
through every step of this work. I profoundly and sincerely thank you all. I am also deeply grateful to 
my Patreon and PayPal supporters: Aissata Coulibaly, Djedje Hermann Yohou, and Yeo Nibontenin, whose generosity 
and belief in my mission have been both humbling and motivating. Your support has helped bring this project 
to life, and I offer you my heartfelt thanks. To all readers/users of this package: may it serve as a 
launchpad for bold ideas, impactful research, and meaningful change! Keep pushing boundaries, keep asking 
questions, and above all - enjoy the journey! With sincere appreciation!



{title:Author}

{p 4}Diallo Ibrahima Amadou {p_end}
{p 4 4}FERDI (Fondation pour les Etudes et Recherches sur le Developpement International) {p_end}
{p 4}63 Boulevard Francois Mitterrand  {p_end}
{p 4}63000 Clermont-Ferrand   {p_end}
{p 4}France {p_end}
{p 4}{hi:E-Mail}: {browse "mailto:zavren@gmail.com":zavren@gmail.com} {p_end}

{p 4}Diallo Ibrahima Amadou {p_end}
{p 4 4}Zavren Consulting and Publishing {p_end}
{p 4}{hi:E-Mail}: {browse "mailto:zavren@gmail.com":zavren@gmail.com} {p_end}



{title:Also see}

{psee}
Online:  help for {bf:{manhelp xtreg XT}}, {bf:{manhelp frontier R}}, {bf:{manhelp xtfrontier XT}}, 
{bf:{manhelp estimates R}},
{bf:{manhelp ereturn P}}, {bf:{manhelp etable R}}, {bf:{manhelp margins R}}, 
{bf:{help outreg}} (if installed), {bf:{help outreg2}} (if installed), {bf:{help estout}} (if installed), 
{bf:{help sfcross}} (if installed), {bf:{help sfpanel}} (if installed), {bf:{help xtnondynthreshsfa}} (if installed), 
{bf:{help frontierhtail}} (if installed), {bf:{help sfkk}} (if installed), {bf:{help xtsfkk}} (if installed)
{p_end}


