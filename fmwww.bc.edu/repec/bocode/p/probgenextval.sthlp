{smcl}
{* version 1.0.1, 30Nov2021 }{...}
{cmd:help probgenextval}
{hline}

{title:Title}

{pstd}
    {hi: Performs Estimations of Binary Generalized Extreme Value (GEV) Models}


	
{title:Syntax}

{pstd}
{cmd:probgenextval}
{depvar}
{indepvars}
{ifin} {weight}
[{cmd:,} {it:options}]



{synoptset 27 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt: {opth const:raints(estimation options##constraints():constraints)}}apply specified linear constraints{p_end}
{synopt :{opth exp:osure(varname:varname_e)}}include ln({it:varname_e}) in model with coefficient constrained to 1{p_end}
{synopt :{opth off:set(varname:varname_o)}}include {it:varname_o} in model with coefficient constrained to 1{p_end}
{synopt :{opt nocons:tant}}suppress constant term{p_end}
{synopt: {cmd:nolrtest}}report the model Wald test{p_end}
{synopt :{opt init}}specify the computation of the internal initial values{p_end}

{syntab:Reporting}
{synopt :{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt :{opt or}}odds ratio, {it:string} is {cmd:Odds Ratio}{p_end}

{syntab:SE/Robust}
{synopt :{opth vce(vcetype)}}{it:vcetype} may be {opt oim}, {opt r:obust}, or {opt opg}{p_end}
{synopt :{opth cl:uster(varname)}}adjust standard errors for intragroup correlation; implies {cmd:vce(robust)}{p_end}

{syntab:Max options}
{synopt :{it:{help maximize:maximize_options}}}control the maximization process; seldom used{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{indepvars} may contain factor variables; see {help fvvarlist}. {p_end}
{p 4 6 2}
{depvar} and {indepvars} may contain time-series operators; see {help tsvarlist}. {p_end}
{p 4 6 2}
{cmd:by} is allowed with {hi:probgenextval}; see {manhelp by D} for more details on {cmd:by}. {p_end}
{p 4 6 2}
{cmd:bootstrap}, {cmd:mi estimate}, {cmd:nestreg}, {cmd:rolling}, {cmd:statsby}, {cmd:stepwise}, and {cmd:svy} are allowed; see {help prefix}. {p_end}
{p 4 6 2}
{cmd:fweight}s, {cmd:iweight}s, and {cmd:pweight}s are allowed; see {help weight}.{p_end}
{p 4 6 2} See below for features available after estimation.  {p_end}



{title:Description}

{pstd}
{cmd:probgenextval} performs estimations of binary generalized extreme value (GEV) models. The generalized extreme value (GEV) distribution 
is a lineage of continuous probability laws that are utilized to characterize extreme values phenomena. It incorporates the Gumbel, Frechet 
and Weibull distributions lineages also known as type I, II and III extreme value distributions. The generalized extreme value (GEV) 
distribution, by incorporating the previous three distributions, permits to obtain a continuous spectrum of possible shapes encompassing 
all the three preceding distributions. In this sense, it is more flexible because it lets the data speak and choose which distribution 
is more suitable. The command {cmd:probgenextval} estimates a generalized extreme value (GEV) model for a binary dependent variable, typically 
with one of the outcomes rare, or extremely rare, relative to the other.  The command {cmd:probgenextval} can calculate robust and 
cluster-robust standard errors and remodel results for complex survey designs. The generalized extreme value (GEV) distribution is 
employed in Extreme Value Theory or Extreme Value Analysis to model the probability of events that are more extreme than any formerly 
noticed. That is, it is utilized to estimate the risk of extreme, rare events, for example: the 1755 Lisbon Earthquake, the 2004 Indian 
Ocean Earthquake and Tsunami, Credit Defaults, and the Modeling of COVID-19/CORONAVIRUS. The theory behind the command {cmd:probgenextval}  
can be found in Calabrese and Osmetti (Journal of Applied Statistics, 2013), and Wang and Dey (The Annals of Applied Statistics, 2010).



{title:Econometric Model}

{p 4 6 2}  The estimated econometric model can be written as: {p_end}

{p 4 6 2}  {it:Pr(y_j = 1| x_j) = F(x_j*b)} {space 3}  {hi:(1)} {p_end}

{p 4 6 2}  where {p_end}

{p 4 6 2}  {it:Pr(.)} denotes Probability  {p_end}

{p 4 6 2}  {it: y_j} is the dependent variable. It is a Binary variable. That is, it can have only two possible outcomes. This means that 
it is a (1/0) or (Yes/No) outcome. Typically, one of these two outcomes is rare, or is extremely rare, relative to the other {p_end}

{p 4 6 2}  {it:x_j} indicates the vector of independent variables {p_end}

{p 4 6 2}  {it:F(.)} is the Cumulative Distribution Function of the Generalized Extreme Value (GEV) probability law {p_end}

{p 4 6 2}  The vector of parameters {it:b} is typically estimated by Maximum Likelihood {p_end}

{p 4 6 2}  {it:j} indicates the {it:j}th observation {p_end}

{p 4 6 2}  The Cumulative Distribution Function of the Generalized Extreme Value (GEV) probability law, {it:F(.)}, has the following formula: {p_end}

{p 4 6 2}  {it:F(x_j*b) = exp{-([1 + cxi*(x_j*b)]+)^(-1/ cxi)} } {space 3}  {hi:(2)} {p_end}

{p 4 6 2}  with {p_end}

{p 4 6 2}  {it:[1 + cxi*(x_j*b)]+ = Max(0, 1 + cxi*(x_j*b))} {space 6}  {hi:(3)} {p_end}

{p 4 6 2}  {it:cxi} is the shape parameter. It can be any Real Number {p_end}

{p 4 6 2}  The log-likelihood function for the Generalized Extreme Value (GEV) model is: {p_end}

{p 4 6 2}  {it:ln(L) = \sum _{j\in S} w_j*ln{F(x_j*b)} + \sum _{j\notin S} w_j*ln{1 - F(x_j*b)}} {p_end}

{p 4 6 2}  where {it:S} is the set of all observations {it:j} such that {it:y_j = 1} {p_end}

{p 4 6 2}  {it:F(x_j*b)} is the Cumulative Distribution Function of the Generalized Extreme Value (GEV) probability law defined above {p_end}

{p 4 6 2}  {it: w_j} denotes the optional weights {p_end}

{p 4 6 2}  {it:ln(L)} is maximized as described in {helpb maximize:[R] Maximize} {p_end}

{p 4 6 2}  The command {cmd:probgenextval} supports the Huber/White/sandwich estimator of the variance and its clustered version 
using {hi:vce(robust)} and {hi:vce(cluster} {it:clustvar}{hi:)}, respectively. See {bf:{manhelp robust P}} for more details. The 
command can also calculate the equation-level scores {p_end}

{p 4 6 2}  The command {cmd:probgenextval} also supports estimation with survey data. For details on VCEs with survey data, 
see {mansection SVY svy:Variance estimation} {p_end}



{title:Options}

{dlgtab:Model}

{phang}
{opth const:raints(estimation options##constraints():constraints)},
{opth exp:osure(varname:varname_e)},
{opth off:set(varname:varname_o)}, and
{opt nocons:tant};
see {help estimation options}.

{phang}
{cmd:nolrtest} indicates that the model significance test should be a Wald
test instead of a likelihood-ratio test.

{phang}
{opt init} specifies the computation of the internal initial values. If you want 
to calculate the initial values, you indicate this, by issuing the option {opt init}. Then 
the command internally computes these initial values for you.

{dlgtab:Reporting}

{phang}
{opt level(#)}; set confidence level; default is {cmd:level(95)}.

{phang}
{opt or} odds ratio, {it:string} is {cmd:Odds Ratio}.

{dlgtab:SE/Robust}

{phang}
{opth vce(vcetype)}; {it:vcetype} may be {opt oim}, observed information matrix (OIM);
{opt r:obust}, Huber/White/sandwich estimator; or {opt opg}, outer product of the gradient
(OPG) vectors. see {it:{help vce_option}} for more details.

{phang}
{opth cluster(varname)}; adjust standard errors for intragroup correlation; implies {cmd:vce(robust)}.

{dlgtab:Max options}

{phang}
{it:maximize_options}:
{opt dif:ficult},
{opt tech:nique(algorithm_spec)},
{opt iter:ate(#)},
[{cmdab:no:}]{opt lo:g},
{opt tr:ace},
{opt grad:ient},
{opt showstep},
{opt hess:ian},
{opt showtol:erance},
{opt tol:erance(#)},
{opt ltol:erance(#)},
{opt nrtol:erance(#)},
{opt nonrtol:erance};
see {manhelp maximize R}.
These options are seldom used.



{title:Syntax for {helpb predict}}

{phang2}{cmd:predict}
{dtype}
{newvar}
{ifin}
[{cmd:,} {it:statistic}]

{synoptset 17 tabbed}{...}
{synopthdr:statistic}
{synoptline}
{syntab :Main}
{synopt :{opt pr}}probability of a positive outcome; the default{p_end}
{synopt :{opt xb}}linear prediction{p_end}
{synopt :{opt cxi}}shape parameter{p_end}
{synopt :{opt stdp}}standard error of the linear prediction{p_end}
{synopt :{opt sc:ore}}first derivative of the log likelihood with respect to xb{p_end}
{synoptline}
{p2colreset}{...}
INCLUDE help esample


{title:Description for {helpb predict}}

{pstd}
{cmd:predict} creates a new variable containing predictions such as
probabilities, linear predictions, standard errors, and equation-level scores.


{title:Options for {helpb predict}}

{phang}
{opt pr}, the default, calculates the probability of a positive outcome.

{phang}
{opt xb} calculates the linear prediction.

{phang}
{opt cxi} calculates the shape parameter. It can be any Real Number.

{phang}
{opt stdp} calculates the standard error of the linear prediction.

{phang}
{opt score} calculates the equation-level score, the derivative of the log
likelihood with respect to the linear prediction.



INCLUDE help syntax_margins

{synoptset 17}{...}
{synopthdr :statistic}
{synoptline}
{synopt :{opt pr}}probability of a positive outcome; the default{p_end}
{synopt :{opt xb}}linear prediction{p_end}
{synopt :{opt cxi}}shape parameter{p_end}
{synopt :{opt stdp}}not allowed with {cmd:margins}{p_end}
{synopt :{opt sc:ore}}not allowed with {cmd:margins}{p_end}
{synoptline}
{p2colreset}{...}

INCLUDE help notes_margins


{title:Description for {helpb margins}}

{pstd}
{cmd:margins} estimates margins of response for 
probabilities and linear predictions.



{title:Syntax, Description and Options for {helpb marginsplot}}

{pstd}
For the {hi:Syntax}, the {hi:Description} and the {hi:Options} for {hi: marginsplot}, please see {manhelp marginsplot R}.



{title:Return values for probgenextval}

{pstd}
{cmd:probgenextval} saves the following in {cmd:e()}. Note that these saved results are almost the same as those
returned by the command {manhelp maximize R} since {cmd:probgenextval} is fitted using {manhelp ml R}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations; always stored{p_end}
{synopt:{cmd:e(k)}}number of parameters; always stored{p_end}
{synopt:{cmd:e(k_eq)}}number of equations in {cmd:e(b)}; usually stored{p_end}
{synopt:{cmd:e(k_eq_model)}}number of equations in overall model 
                 test; usually stored{p_end}
{synopt:{cmd:e(k_dv)}}number of dependent variables; usually stored{p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom; always stored{p_end}
{synopt:{cmd:e(r2_p)}}pseudo-R-squared; sometimes stored{p_end}
{synopt:{cmd:e(ll)}}log likelihood; always stored{p_end}
{synopt:{cmd:e(ll_0)}}log likelihood, constant-only model; stored when
        constant-only model is fit{p_end}
{synopt:{cmd:e(N_clust)}}number of clusters; stored when {cmd:vce(cluster}
        {it:clustvar}{cmd:)} is specified;
        see {findalias frrobust}{p_end}
{synopt:{cmd:e(chi2)}}chi-squared; usually stored{p_end}
{synopt:{cmd:e(p)}}p-value for model test; usually stored{p_end}
{synopt:{cmd:e(rank)}}rank of {cmd:e(V)}; always stored{p_end}
{synopt:{cmd:e(rank0)}}rank of {cmd:e(V)} for constant-only model; stored
        when constant-only model is fit{p_end}
{synopt:{cmd:e(ic)}}number of iterations; usually stored{p_end}
{synopt:{cmd:e(rc)}}return code; usually stored{p_end}
{synopt:{cmd:e(converged)}}{cmd:1} if converged, {cmd:0} otherwise; usually stored{p_end}
{synopt:{cmd:e(k_aux)}}number of ancillary parameters; always saved{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}name of command; always stored{p_end}
{synopt:{cmd:e(cmdline)}}command as typed; always stored{p_end}
{synopt:{cmd:e(depvar)}}names of dependent variables; always stored{p_end}
{synopt:{cmd:e(wtype)}}weight type; stored when weights are specified or
        implied{p_end}
{synopt:{cmd:e(wexp)}}weight expression; stored when weights are specified or
        implied{p_end}
{synopt:{cmd:e(title)}}title in estimation output; usually stored by commands using {cmd:ml}{p_end}
{synopt:{cmd:e(clustvar)}}name of cluster variable; stored when
        {cmd:vce(cluster} {it:clustvar}{cmd:)} is specified;
        see {findalias frrobust}{p_end}
{synopt:{cmd:e(chi2type)}}{cmd:Wald} or {cmd:LR}; type of model chi-squared
        test; usually stored{p_end}
{synopt:{cmd:e(vce)}}{it:vcetype} specified in {cmd:vce()}; stored when command
        allows {cmd:vce()}{p_end}
{synopt:{cmd:e(vcetype)}}title used to label Std. Err.; sometimes stored{p_end}
{synopt:{cmd:e(opt)}}type of optimization; always stored{p_end}
{synopt:{cmd:e(which)}}{cmd:max} or {cmd:min}; whether optimizer is to perform
                         maximization or minimization; always stored{p_end}
{synopt:{cmd:e(ml_method)}}type of {cmd:ml} method; always stored by commands
using {cmd:ml}{p_end}
{synopt:{cmd:e(user)}}name of likelihood-evaluator program; always stored{p_end}
{synopt:{cmd:e(technique)}}from {cmd:technique()} option; sometimes stored{p_end}
{synopt:{cmd:e(singularHmethod)}}{cmd:m-marquardt} or {cmd:hybrid}; method used
                          when Hessian is singular; sometimes stored (1){p_end}
{synopt:{cmd:e(crittype)}}optimization criterion; always stored (1){p_end}
{synopt:{cmd:e(properties)}}estimator properties; always stored{p_end}
{synopt:{cmd:e(predict)}}program used to implement {cmd:predict}; usually
        stored{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector; always stored{p_end}
{synopt:{cmd:e(Cns)}}constraints matrix; sometimes stored{p_end}
{synopt:{cmd:e(ilog)}}iteration log (up to 20 iterations); usually stored{p_end}
{synopt:{cmd:e(gradient)}}gradient vector; usually stored{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators; always
        stored{p_end}
{synopt:{cmd:e(V_modelbased)}}model-based variance; only stored when {cmd:e(V)}
        is robust, cluster-robust, bootstrap, or jackknife variance{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample; always stored{p_end}
    {hline 20}
{p 4 6 2}
1. Type {cmd:ereturn} {cmd:list,} {cmd:all} to view these results; see
{helpb return:[P] return}.



{title:Examples}

{p 4 8 2} Before beginning the estimations, we use the {hi:set more off} instruction to tell
{hi:Stata} not to pause when displaying the output. {p_end}

{p 4 8 2}{stata "set more off"}{p_end}

{p 4 8 2} We illustrate the use of the command {cmd:probgenextval} with the dataset {hi:probgenextvalcovid.dta}. This dataset 
contains a sample of cross-sectional data for developed and developing countries in the World. It contains data on 187 countries 
in the World on the COVID-19 Status for the year 2020. The data on the remaining variables are for the year 2019 or the 
latest year of data availability (2018). {p_end}

{p 4 8 2}{stata "use http://fmwww.bc.edu/repec/bocode/p/probgenextvalcovid.dta, clear"}{p_end}

{p 4 8 2} Next we describe the dataset to see the definition of each variable. {p_end}

{p 4 8 2}{stata "describe"}{p_end}

{p 4 8 2} Some explanations on the data are in order. Our {it:dependent variable} {hi:covid19status} is a binary variable indicating 
whether a country is a Low COVID-19 ({hi:0}) or a High COVID-19 ({hi:1}) country in the year 2020. To obtain this classification 
scheme we used a {hi:Latent profile model} on the variables: the Number of Confirmed Cases, the Number of Death and the Number of 
Recovered Cases of COVID-19 per {it:100000 people} in the year 2020 with two classes. Please see {helpb gsem lclass options} 
for more details. This allows us to classify the countries in our sample as whether they are a Low COVID-19 or a High COVID-19 
country for the year 2020. We observe that most of the countries classified by the {hi:Latent profile model} as Low COVID-19 countries 
are indeed those categorized by {it:The news media} as Low COVID-19 countries for the year 2020. Similarly, most of the countries 
classified by the {hi:Latent profile model} as High COVID-19 countries are indeed those categorized by {it:The news media} as 
High COVID-19 countries for the year 2020. Thus, our {hi:Latent profile model} does a pretty good job in the classification of 
the countries. Our {it:variable of interest} {hi:pop014pctotr} is {hi:Population Ages 0-14 over Total Population} for the year 2019. The other 
remaining numerical variables are used as {hi:control variables} or {hi:filtering variables}. As indicated previously, all 
these variables ({hi:control variables} and {hi:filtering variables}) are for the years 2019 or 2018 according to 
their availability. {p_end}

{p 4 8 2} Now, we {it:inspect} the variable {hi:covid19status} to have a detailed view on its structure. {p_end}

{p 4 8 2}{stata "inspect covid19status"}{p_end}

{p 4 8 2} We see that the variable {hi:covid19status} takes on two unique values, {hi:0} and {hi:1}. The value {hi:0} denotes 
{hi:Low COVID-19}, and {hi:1} denotes {hi:High COVID-19}. We observe that there are {hi:138 Zeros} and {hi:49 Ones}. Hence, 
there are far more {hi:Zeros} than {hi:Ones}. Thus, there is an asymmetry in the distribution of {hi:Zeros} and {hi:Ones}. The 
number of {hi:Ones} is rare relative to the number of {hi:Zeros}. Consequently, this particular example appropriately lends itself 
to be modeled by the {cmd:probgenextval} command because: first, the {it:dependent variable} is binary, and second, one of the 
outcomes is rare relative to the other. This is what we will do in the following lines of codes. {p_end}

{p 4 8 2} We begin by regressing the {it:dependent variable} {hi:covid19status} on the {it:variable of interest} {hi:pop014pctotr} and 
on the {it:control variables} {hi:rconnar gcformpcr lggdppcap}. Before continuing, it is important to remind the reader that 
the {it:dependent variable} is measured for the year {hi:2020}, while the {it:variable of interest} is measured for the 
year {hi:2019} and the {it:control variables} are measured for the years {hi:2019} or {hi:2018}. Hence, the {it:variable of interest} 
and the {it:control variables} are predetermined compared to the {it:dependent variable}. Consequently, there is no {it:endogeneity issues} 
in this model and the ones that will follow.    {p_end}

{p 4 8 2}{stata "probgenextval covid19status pop014pctotr rconnar gcformpcr lggdppcap"}{p_end}

{p 4 8 2} We see that the variable {hi:pop014pctotr} has a negative and statistically significant impact on the probability 
of {it:High COVID-19}. This means that an increase in the {it:Population Ages 0-14 over Total Population} in a country reduces 
the probability of {it:High COVID-19}. We also observe that an increase in {it:Real Consumption over Real GDP} augments the 
probability of {it:High COVID-19}. This does not mean that consuming increases COVID-19. It simply says that the activity of 
consuming increases the {it:contact rate} between the infected and the susceptible population, and through this,  augments the 
probability of infection transmission. The other {it:control variables} are not significant. {p_end}

{p 4 8 2} Running the same regression as above, we now show how to use the {hi:vce(robust)} option with the command {cmd:probgenextval}. {p_end}

{p 4 8 2}{stata "probgenextval covid19status pop014pctotr rconnar gcformpcr lggdppcap, vce(robust)"}{p_end}

{p 4 8 2} Next, we study the effect of how belonging to a region in the World affects the COVID-19 Status. At the same time, we illustrate 
how to use factor variables (please see {helpb fvvarlist}). {p_end}

{p 4 8 2} We begin by tabulating the region variable. {p_end}

{p 4 8 2}{stata "tabulate regionwbnum"}{p_end}

{p 4 8 2} Then we estimate the effect of the factor variable {hi:i.regionwbnum} by taking {hi:North America} as the base level. {p_end}

{p 4 8 2}{stata "probgenextval covid19status pop014pctotr ib5.regionwbnum rconnar gcformpcr lggdppcap, vce(robust)"}{p_end}

{p 4 8 2} We notice that the {it:effect} of {hi:pop014pctotr} on the probability of {it:High COVID-19} is negative 
and statistically significant. This means that an increase in the {it:Population Ages 0-14 over Total Population} in a country reduces the 
probability of {it:High COVID-19}. We also observe that the {it:effects} of the following factor levels for the factor 
variable {hi:i.regionwbnum}: {hi:East Asia & Pacific}, {hi:Europe & Central Asia}, {hi:Latin America & Caribbean}, 
{hi:Middle East & North Africa}, {hi:South Asia} and {hi:Sub-Saharan Africa} are negative and significant 
compared to the base level {hi:North America}. The {it:effects} of the remaining regressors are not statistically 
significant. {p_end}

{p 4 8 2} Now, we repeat the preceding study for the {it:Income Groups} in our sample. That is, we examine the effect of how belonging 
to an {it:Income Group} in the World affects the COVID-19 Status. At the same time, we illustrate how to use factor 
variables (please see {helpb fvvarlist}), some {helpb maximize:maximize_options} and the {manhelp margins R} command. {p_end}

{p 4 8 2} We begin by tabulating the {it:Income Group} variable. {p_end}

{p 4 8 2}{stata "tabulate incomegrwbnum"}{p_end}

{p 4 8 2} Then we estimate the effect of the factor variable {hi:i.incomegrwbnum} including the impact of the remaining regressors, and 
add the options {hi:technique(dfp)}, {hi:qtolerance(0.005)} and {hi:iterate(20000)} for convergence purposes.  {p_end}

{p 4 8 2}{stata "probgenextval covid19status pop014pctotr i.incomegrwbnum rconnar gcformpcr lggdppcap, vce(robust) technique(dfp) qtolerance(0.005) iterate(20000)"}{p_end}

{p 4 8 2} Finally, we employ the {manhelp margins R} command to compute the {it:Average marginal effect} of each independent variable in 
our model with the option {hi:dydx(*)}. We add the {hi:post} option to tell {manhelp margins R} to post its results in {hi:e()}, in case we 
might want to tabulate the estimations results for example. We also add the {hi:vce(unconditional)} option because we utilized 
the {hi:vce(robust)} option in our previous estimation. We additionally specify the {cmd:nochainrule} option because {cmd:probgenextval} 
is a community-contributed command.   {p_end}

{p 4 8 2}{stata "margins, dydx(*) post vce(unconditional) nochainrule"}{p_end}

{p 4 8 2} We notice that the {it:Average marginal effect} of {hi:pop014pctotr} on the predicted probability of {it:High COVID-19} is negative 
and statistically significant. This means that an increase in the {it:Population Ages 0-14 over Total Population} in a country reduces the 
predicted probability of {it:High COVID-19}. We also observe that the {it:Average marginal effect} of the following factor level for the factor 
variable {hi:i.incomegrwbnum}: {hi:Lower middle income} is negative and significant compared to the base level {hi:High income}. The 
{it:Average marginal effects} of the {hi:Real Consumption over Real GDP} and {hi:Gross Capital Formation over GDP} are positive and 
statistically significant. As explained previously, this last result simply means that increasing {it:the activities of consuming and investing}  
augment the contact rate, and through this medium, rise the chance of infection. {p_end}

{p 4 8 2} Let us add more regressors to our estimation equation. {p_end}

{p 4 8 2}{stata "probgenextval covid19status pop014pctotr hc gcformpcr lggdppcap tradepcr lglifeexpec, technique(dfp)"}{p_end}

{p 4 8 2} We see that {hi:pop014pctotr} continues to have a negative and significant effect on the probability of {it:High COVID-19}. We also see that 
the {hi:Human capital index} has a positive and significant impact on the probability of {it:High COVID-19}. As explained previously, this 
last result simply means that increasing {it:Human capital} causes {it:Work} to increase, and through this medium, this augments the 
contact rate, which in turn, rises the chance of infection. {p_end}

{p 4 8 2} If we do not want to display the iterations log at the beginning of the regression, we type. {p_end}

{p 4 8 2}{stata "probgenextval covid19status pop014pctotr rconnar gcformpcr lggdppcap lglifeexpec, technique(dfp) nolog"}{p_end}

{p 4 8 2} Now, we show how to perform a {it:Likelihood-ratio test} that the coefficient for {hi:hc}, {it:Human capital index}, is equal 
to {hi:0}. At the same time, we demonstrate how to use the {helpb if} qualifier (please see {manhelp if U} for more details). {p_end}

{p 4 8 2} We start, by running the {it:full} estimation. {p_end}

{p 4 8 2}{stata "probgenextval covid19status pop014pctotr hc gcformpcr lggdppcap tradepcr lglifeexpec, technique(dfp)"}{p_end}

{p 4 8 2} Then, we store the {it:full} estimation result. {p_end}

{p 4 8 2}{stata "estimates store full"}{p_end}

{p 4 8 2} After this, we run the {it:restricted} estimation. {p_end}

{p 4 8 2}{stata "probgenextval covid19status pop014pctotr gcformpcr lggdppcap tradepcr lglifeexpec if e(sample), technique(dfp)"}{p_end}

{p 4 8 2} Then, we store the {it:restricted} estimation result. {p_end}

{p 4 8 2}{stata "estimates store restricted"}{p_end}

{p 4 8 2} Finally, we perform the {it:Likelihood-ratio test} that the coefficient for {hi:hc} is equal to {hi:0}. {p_end}

{p 4 8 2}{stata "lrtest full restricted"}{p_end}

{p 4 8 2} The result of the {it:Likelihood-ratio test} illustrate that the coefficient of {hi:hc} is different of {hi:0} at 
the {it:10 percent statistical significance level}. {p_end}

{p 4 8 2} We can perform the same test presented previously by using the command {manhelp nestreg R}, as in: {p_end}

{p 4 8 2}{stata "nestreg, quietly lrtable: probgenextval covid19status (pop014pctotr gcformpcr lggdppcap tradepcr lglifeexpec) (hc), technique(dfp)"}{p_end}

{p 4 8 2} We conclude from the {it:likelihood-ratio statistic} that the coefficient on {hi:hc} (that is, Block 2) is significant at 
the {it:10 percent level}. {p_end}

{p 4 8 2} We drop all stored estimation results before continuing.  {p_end}

{p 4 8 2}{stata "estimates clear"}{p_end}

{p 4 8 2} In the following estimation, we examine if the {it:Logarithm of International Tourism Number of Arrivals}, {hi:lgintertourism}, have an 
effect on the probability of {it:High COVID-19}. At the same time, we show how to perform a {it:Wald test} after the 
command {cmd:probgenextval}.  {p_end}

{p 4 8 2} First, we reload our examples dataset we described above. {p_end}

{p 4 8 2}{stata "use http://fmwww.bc.edu/repec/bocode/p/probgenextvalcovid.dta, clear"}{p_end}

{p 4 8 2} Second, we run the following regression by including {hi:lgintertourism} as a regressor. {p_end}

{p 4 8 2}{stata "probgenextval covid19status pop014pctotr hc rconnar tradepcr lgintertourism"}{p_end}

{p 4 8 2} We see that {hi:lgintertourism} has no effect on the probability of {it:High COVID-19}. But next, we perform a {it:Joint test} that 
the coefficients on {hi:pop014pctotr, hc, rconnar} and {hi:lgintertourism} are equal to {hi:0}. {p_end}

{p 4 8 2}{stata "test pop014pctotr hc rconnar lgintertourism"}{p_end}

{p 4 8 2} We observe that the {it:four variables} taken together are jointly different from {hi:0}. {p_end}

{p 4 8 2} Now, we demonstrate how to employ constraints (please see {manhelp constraint R}) with the command {cmd:probgenextval}. {p_end}

{p 4 8 2} We start by constraining the shape parameter {hi:cxi} to be equal to {hi:0.5}. {p_end}

{p 4 8 2}{stata "constraint define 1 _b[/cxi]=0.5"}{p_end}

{p 4 8 2} Then, we run the following regression by specifying the option {hi:constraints(1)}. {p_end}

{p 4 8 2}{stata "probgenextval covid19status pop014pctotr rconnar gcformpcr lggdppcap domcredpspcr, constraints(1)"}{p_end}

{p 4 8 2} We see that constraining the shape parameter {hi:cxi} to be {hi:0.5}, in order to get 
a {it:Positively Skewed Generalized Extreme Value (GEV) Distribution}, does not alter our main finding. That is, an increase in 
the {it:Population Ages 0-14 over Total Population} in a country reduces the probability of {it:High COVID-19}. However, we notice 
that {it:Gross Capital Formation over GDP} becomes significant and gets a positive impact, like that 
of {it:Real Consumption over Real GDP}. As explained previously, these last two results simply mean that 
increasing {it:the activities of consuming and investing}  augment the contact rate, and through this medium, rise 
the chance of infection. {p_end}

{p 4 8 2} Before continuing, we drop all the constraints we created previously. {p_end}

{p 4 8 2}{stata "constraint drop _all"}{p_end}

{p 4 8 2} We reload our examples dataset we described above before continuing. {p_end}

{p 4 8 2}{stata "use http://fmwww.bc.edu/repec/bocode/p/probgenextvalcovid.dta, clear"}{p_end}

{p 4 8 2} We exhibit how to employ the command {cmd:probgenextval} with the {bf:{manhelp by D}} prefix. First, we 
tabulate by the development level of the countries. {p_end}

{p 4 8 2}{stata "tabulate developedco"}{p_end}

{p 4 8 2} Then, we sort the dataset by the development level of the countries. {p_end}

{p 4 8 2}{stata "sort developedco"}{p_end}

{p 4 8 2} Finally, we use the command {cmd:probgenextval} with the {bf:{manhelp by D}} prefix.  {p_end}

{p 4 8 2}{stata "by developedco: probgenextval covid19status pop014pctotr hc rconnar tradepcr, technique(dfp) difficult tolerance(0.5) ltolerance(0.5) nrtolerance(0.5) vce(robust) nolog"}{p_end}

{p 4 8 2} We restore the original ordering of the dataset before continuing.  {p_end}

{p 4 8 2}{stata "sort pbm"}{p_end}

{p 4 8 2} We reload our examples dataset we described above before continuing. {p_end}

{p 4 8 2}{stata "use http://fmwww.bc.edu/repec/bocode/p/probgenextvalcovid.dta, clear"}{p_end}

{p 4 8 2} If we want to specify the computation of the internal initial values, we type. {p_end}

{p 4 8 2}{stata "probgenextval covid19status pop014pctotr rconnar gcformpcr lggdppcap, vce(robust) init iterate(20000)"}{p_end}

{p 4 8 2} Note that specifying the {opt init} option, could in some cases, help us 
to maximize the likelihood function quickly when we are having convergence problems. {p_end}

{p 4 8 2} In the previous equation, we notice that, the {it:Logarithm of GDP per Capita Constant 2010 USD} has a positive and significant 
impact on the probability of {it:High COVID-19}. An explanation could be that, when Real GDP per Capita augments, work and economic activity 
become higher.  This could in turn augment the contact rate, and through these means, rise the chance of infection when Real GDP per Capita 
becomes higher.  {p_end}

{p 4 8 2} Next, we estimate an equation with a {it:90%} confidence interval. At the same time, we investigate 
if {it:Institutions}, here {it:Democracy}, have an impact on the probability of {it:High COVID-19}. {p_end}

{p 4 8 2}{stata "probgenextval covid19status pop014pctotr hc gcformpcr lggdppcap tradepcr lglifeexpec democrataccc, vce(robust) init technique(bfgs) level(90)"}{p_end}

{p 4 8 2} We observe that, {it:Democratic Accountability} has a positive and significant effect on the probability of {it:High COVID-19}. A first 
explanation could be that in democracies, governments are less inclined to establish draconian measures of {hi:COVID-19 lockdowns} for fear of 
retaliations from the electorate compared to autocratic governments. This could in turn augment the contact rate, and through this 
medium, rise the chance of infection in democracies.  A second explanation could be that, in most democracies, work, economic activity and 
extra-activities are higher.  This could in turn augment the contact rate, and through these means, rise the chance of infection in 
democracies.  {p_end}

{p 4 8 2} If we do not want to have a constant, we type. {p_end}

{p 4 8 2}{stata "probgenextval covid19status pop014pctotr hc gcformpcr lggdppcap tradepcr lglifeexpec democrataccc, vce(robust) init nocons"}{p_end}

{p 4 8 2} We now illustrate how to use the command {cmd:probgenextval} with the {bf:{help predict}} command. {p_end}

{p 4 8 2} We start by running the following regression.  {p_end}

{p 4 8 2}{stata "probgenextval covid19status pop014pctotr rconnar gcformpcr lggdppcap domcredpspcr"}{p_end}

{p 4 8 2} We calculate the probability of a positive outcome. {p_end}

{p 4 8 2}{stata "predict double prpred, pr"}{p_end}

{p 4 8 2} We calculate the linear prediction. {p_end}

{p 4 8 2}{stata "predict double xbpred, xb"}{p_end}

{p 4 8 2} We calculate the shape parameter. {p_end}

{p 4 8 2}{stata "predict double cxipred, cxi"}{p_end}

{p 4 8 2} We calculate the standard error of the linear prediction. {p_end}

{p 4 8 2}{stata "predict double stdppred, stdp"}{p_end}

{p 4 8 2} We calculate the equation-level score, the derivative of the log
likelihood with respect to the linear prediction. {p_end}

{p 4 8 2}{stata "predict double sc*, score"}{p_end}

{p 4 8 2} We describe all the previously created variables to see their labels. {p_end}

{p 4 8 2}{stata "describe prpred xbpred cxipred stdppred sc1 sc2"}{p_end}

{p 4 8 2} We summarize these variables. {p_end}

{p 4 8 2}{stata "summarize prpred xbpred cxipred stdppred sc1 sc2, separator(0)"}{p_end}

{p 4 8 2} In the remaining examples of this section, we will demonstrate an extensive use of the command {cmd:probgenextval} with the 
commands {manhelp margins R} and {manhelp marginsplot R}. {p_end}

{p 4 8 2} We begin by reloading our examples dataset we described above. {p_end}

{p 4 8 2}{stata "use http://fmwww.bc.edu/repec/bocode/p/probgenextvalcovid.dta, clear"}{p_end}

{p 4 8 2} Now, we run the following regression. {p_end}

{p 4 8 2}{stata "probgenextval covid19status pop014pctotr democrataccc hc gcformpcr lggdppcap tradepcr lglifeexpec, vce(robust) init"}{p_end}

{p 4 8 2} Then, we compute the {it:Conditional marginal effects} of each independent variable in our model, setting all variables to 
their means with the option {hi:atmeans}. {p_end}

{p 4 8 2}{stata "margins, dydx(*) post atmeans vce(unconditional) nochainrule"}{p_end}

{p 4 8 2} We notice that the {it:Conditional marginal effect} of {hi:pop014pctotr} on the predicted probability of {it:High COVID-19} is negative 
and statistically significant. This means that an increase in the {it:Population Ages 0-14 over Total Population} in a country reduces the 
predicted probability of {it:High COVID-19}. We also observe that the {it:Conditional marginal effects} of the following 
variables: {hi:democrataccc} and {hi:gcformpcr} are positive and significant. The {it:Conditional marginal effects} of the remaining 
regressors are not statistically significant. The results found in this table illustrate that, using {it:Conditional marginal effects} does 
not change our main finding. That is, an increase in the {it:Population Ages 0-14 over Total Population} in a country reduces the 
predicted probability of {it:High COVID-19}. {p_end}

{p 4 8 2} Next, we investigate how {it:an older population} affects the probability of {it:High COVID-19}. At the same time, we show how 
to use {it:elasticities} with {manhelp margins R}.  {p_end}

{p 4 8 2}{stata "probgenextval covid19status pop65abpctotr hc rconnar, iterate(20000)"}{p_end}

{p 4 8 2} We calculate the {it:elasticity} of each independent variable in our model with the option {hi:eyex(*)}. {p_end}

{p 4 8 2}{stata "margins, eyex(*) post nochainrule"}{p_end}

{p 4 8 2} We see that the variable {hi:pop65abpctotr} has a positive and statistically significant impact on the predicted probability 
of {it:High COVID-19}. This means that an increase in {it:Population Ages 65 Above over Total Population} in a country augments the 
predicted probability of {it:High COVID-19}. {p_end}

{p 4 8 2} Let us examine if {hi:pop014pctotr} is still significant if we control for {hi:pop65abpctotr}. {p_end}

{p 4 8 2}{stata "probgenextval covid19status pop014pctotr pop65abpctotr hc rconnar"}{p_end}

{p 4 8 2} We calculate the {it:elasticity} of each independent variable in the previous model with the option {hi:eyex(*)}. {p_end}

{p 4 8 2}{stata "margins, eyex(*) post nochainrule"}{p_end}

{p 4 8 2} We notice that, an increase in {it:Population Ages 0-14 over Total Population} in a country continues to reduce the predicted 
probability of {it:High COVID-19} even after controlling for {it:Population Ages 65 Above over Total Population}. {p_end}

{p 4 8 2} Now, we show how to use {it:Marginal Effects at Representative Values} with the {opt at(atspec)} option. Thus, we run 
the following regression. {p_end}

{p 4 8 2}{stata "probgenextval covid19status pop014pctotr pop65abpctotr hc rconnar"}{p_end}

{p 4 8 2} We compute the {it:Average marginal effects} of {hi:pop014pctotr} at {it:Representative Values} of {hi:pop65abpctotr}: 25th 
Percentile ({hi:p25}), 50th Percentile ({hi:p50}) and 75th Percentile ({hi:p75}).  {p_end}

{p 4 8 2}{stata "margins, dydx(pop014pctotr) at((p25) pop65abpctotr) at((p50) pop65abpctotr) at((p75) pop65abpctotr) nochainrule"}{p_end}

{p 4 8 2} We see that the {it:Average marginal effects} of {hi:pop014pctotr} are approximately equal to {hi:-2} no matter the values 
taken by {hi:pop65abpctotr}. Hence, we conclude that the effects of {hi:pop014pctotr} do not differ greatly by the values taken 
by {hi:pop65abpctotr}.  {p_end}

{p 4 8 2} To finish this {hi:Examples} section, we now illustrate how to use the command {cmd:probgenextval} with 
the {manhelp marginsplot R} command. We start by summarizing the variable {hi:pop014pctotr} to see its range. {p_end}

{p 4 8 2}{stata "summarize pop014pctotr"}{p_end}

{p 4 8 2} Then, we estimate a model in which we examine if there exists a quadratic effect for the variable {hi:pop014pctotr}. For this, we 
specify {it:interactions of factor variables} using the {hi:pop014pctotr} variable. Please see {helpb fvvarlist} for more 
details. {p_end}

{p 4 8 2}{stata `"probgenextval covid19status c.pop014pctotr c.pop014pctotr#c.pop014pctotr rconnar gcformpcr lggdppcap, vce(robust) iterate(20000)"'}{p_end}

{p 4 8 2} Now, we compute the {it:Average marginal effects} of {hi:pop014pctotr} for {hi:pop014pctotr} ranging from {it:0.13} 
to {it:0.48} in {it:0.03} increments.  {p_end}

{p 4 8 2}{stata "margins, dydx(pop014pctotr) at(pop014pctotr=(0.13(0.03)0.48)) vce(unconditional) nochainrule"}{p_end}

{p 4 8 2} Finally, we use the {manhelp marginsplot R} command with the options {opt recast(line)}, {opt recastci(rarea)} and {opt yline(0)} to 
display the {it:Average marginal effects} as a line, the confidence interval as a shaded region and add a horizontal line at the 
value {it:0} respectively.  {p_end}

{p 4 8 2}{stata "marginsplot, recast(line) recastci(rarea) yline(0)"}{p_end}

{p 4 8 2} From this graphic, we observe that the {it:Average marginal effects} of {hi:pop014pctotr} on the predicted probability 
of {it:High COVID-19} are negative and statistically significant for {hi:pop014pctotr} ranging from {it:0.13} to {it:0.31}. But 
for {hi:pop014pctotr} ranging from {it:0.34} to {it:0.46}, the {it:Average marginal effects} of {hi:pop014pctotr} are not 
different from {it:0}.   {p_end}

{p 4 8 2} In writing this {hi:Examples} section, we had two goals. The first, was to show how to effectively use the 
command {cmd:probgenextval} through simple and clear examples. The second, was to undertake an original study on 
the COVID-19/CORONAVIRUS and contribute to this literature. But, despite our efforts, we have only scratched the 
surface of what can be done with the command {cmd:probgenextval}, the accompanying dataset, and the use of the 
command {cmd:probgenextval} in conjunction with the commands {manhelp margins R}, {manhelp marginsplot R}, 
{manhelp lrtest R}, {manhelp test R} or other {hi:Stata} commands. We leave these avenues of research to 
the reader/user to explore at her/his will!  {p_end}



{title:Citation}

{pstd}
The command {cmd:probgenextval} is not an {hi:Official Stata} command. Like a paper, it is a free contribution to the research 
community. If you find the command {cmd:probgenextval} and its accompanying dataset useful and utilize them in your works, please cite 
them like a paper as it is explained in the {hi:Suggested Citation} section of the {hi:IDEAS/RePEc} {it:webpage} of the 
command. {it:Many thanks, in advance, for doing that!} Please, note that citing the command {cmd:probgenextval}  is a good way 
to disseminate its use and its discovery by other researchers. Doing this, could also, potentially, help us, as a community, to 
overcome {it:COVID-19} and to help in solving other challenging current problems and those that lie ahead in the future.



{title:References}

{p 4 8 2}{hi:Calabrese Raffaella and Osmetti Silvia Angela: 2013,} 
"Modelling Small and Medium Enterprise Loan Defaults as Rare Events: The Generalized Extreme Value Regression Model", 
{it:Journal of Applied Statistics} {bf:40}(6), 1172-1188. {p_end}

{p 4 8 2}{hi:Wang Xia and Dey Dipak K.: 2010,} 
"Generalized Extreme Value Regression for Binary Response Data: An Application to B2B Electronic Payments System Adoption", 
{it:The Annals of Applied Statistics} {bf:4}(4), 2000-2023. {p_end}



{title:Author}

{p 4}Diallo Ibrahima Amadou {p_end}
{p 4 4}FERDI (Fondation pour les Etudes et Recherches sur le Developpement International) {p_end}
{p 4}63 Boulevard Francois Mitterrand  {p_end}
{p 4}63000 Clermont-Ferrand   {p_end}
{p 4}France {p_end}
{p 4}{hi:E-Mail}: {browse "mailto:zavren@gmail.com":zavren@gmail.com} {p_end}



{title:Also see}

{psee}
Online:  help for {bf:{manhelp cloglog R}}, {bf:{manhelp probit R}}, {bf:{manhelp logit R}}, {bf:{manhelp Maximize R}}, 
{bf:{help extreme}} (if installed), {bf:{help gevfit}} (if installed), {bf:{help gumbelfit}} (if installed), {bf:{help gevd}} (if installed)
{p_end}


