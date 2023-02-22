{smcl}
{*      *! version 1.1.1 2020-07-15}{...}
{vieweralsosee "strs" "help strs"}{...}
{vieweralsosee "stnet" "help stnet"}{...}
{vieweralsosee "stns " "help stns"}{...}

{hline}

{title:Title}

{p2colset 5 18 10 2}{...}
{p2col :{hi:stpp} {hline 1}}Pohar-Perme estimate of marginal relative survival and more...{p_end}
{p2colreset}{...}

{title:Syntax}
{p 8 16 2}{cmd:stpp}  {newvar} {cmd:using} {it:filename} {ifin}, 
{opt agediag(varname)} 
{opt datediag(varname)}
[{it:options}]

{marker options}{...}
{synoptset 29 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Options}
{synopt :{opt aged:iag(varname)}}age at diagnosis (in years){p_end}
{synopt :{opt dated:iag(varname)}}date at diagnosis{p_end}
{synopt :{opt allcause(newvarlist)}}calculate all-cause probabilities{varlist}{p_end}
{synopt :{opt by(varlist)}}calculate separately in groupes defined in {varlist}{p_end}
{synopt :{opt crudeprob(newvarlist)}}calculate crude probabilities{varlist}{p_end}
{synopt :{opt deathprob}}calculate probabilities of death rather than survival{p_end}
{synopt :{opt ederer2}}calculate Ederer II estimate rather than Pohar Perme{p_end}
{synopt :{opt fh}}use Fleming Harrington estimator of survival{p_end}
{synopt :{opt frame(framename)}}save list results to a frame{p_end}
{synopt :{opt indw:eights(varname)}}individual weights (used for external standardization){p_end}
{synopt :{opt lev:els(#)}}level for confidence intervals (default 95){p_end}
{synopt :{opt list(numlist)}}list of times to view in in output{p_end}
{synopt :{opt pmage(varname)}}name of age variable in popmort file{p_end}
{synopt :{opt pmother(varname)}}name of other variables in popmort file{p_end}
{synopt :{opt pmrate(varname)}}name of rate variable in popmort file{p_end}
{synopt :{opt pmyear(varname)}}name of calendar year variable in popmort file{p_end}
{synopt :{opt pmmaxage(#)}}maximum age in popmort file{p_end}
{synopt :{opt pmmaxyear(#)}}maximum year in popmort file{p_end}
{synopt :{opt standstrata(varname)}}name of standardization variables{p_end}
{synopt :{opt standweights(numlist)}}weights for standardizing{p_end}
{synopt :{opt using2(filename, suboptions)}}incorporate second population mortality file{p_end}
{synopt :{opt verbose}}more detailed output{p_end}
{synopt :{opt graph}}create a graph, with confidence interval{p_end}
{synopt :{opt graphn:ame(name [, replace])}}name the resulting graph{p_end}
{synopt :{opt graphc:ode(filename)}}create a do file that contains the code to recreate the graph{p_end}

{p2colreset}{...}
{p 4 6 2}

{title:Description}

{pstd}
{cmd:stpp} calculates the Pohar-Perme non-parametric estimate of marginal relative survival, which under assumptions can be interpreted as marginal net survival. The estimate is a step function and changes at each event time. 
This is a different implementation to {cmd:strs} and {cmd:stnet} where the time-scale is split into a number of intervals.


{pstd}
Standardized estimates (usually age standardization) can be obtained in two ways.

{phang2}
1) The traditional method by calculating (marginal) relative survival separately in (age) groups and then forming a weighted average of the (age) group specific estiamtes. 
This can done using the {cmd:standstrata(varname)} and {cmd:standweights(numlist)} options.

{phang2}
2) Using individual weights. An individual in a particular (age) group is up or down weighted relative to a reference population (ref Rutherforsd). This is implemented using the {cmd:indweights(varname)} option.

{pstd}
In addition {cmd:stpp} will calculate all-cause and crude probabilities of death, which can also be standardized


{pstd}
The data must be {cmd:stset} before using {cmd:stpp}. There should only be 1 row of data per subject before using {cmd:stpp}. The time units should be years.

{pstd}
{cmd:using} {it:filename} specifies a file containing general-population mortality rates typically stratified by age, sex, calendar year and potentially other variables. In the {cmd:using} file, age must be specified in one-year increments and calendar year in one-year intervals.

{pstd}
The {cmd:using2({it:filename})} option specifies a scecond file containing general-population mortality rates, which enables alternative weights to be used. This includes the methods descibed by Sasieni and Brentnall for net survival and reference adjusted measures for all-cause and crude probabilties. The aim of these methods is to estimate the survival that would be observed in a population with the expected survival defined by the rates in the {cmd:using2()} file.


{pstd}
Confidence intervals are also calculated and named {it: newvar}{cmd:_lci} and {it: newvar}{cmd:_uci}

{title:Options}

{phang}
{opt agediag(varname)} names the variable containing age at diagnosis. This should be in years. Note that if possible it is best to avoid using truncated (integer) age as this assumes that each person was diagnosed on their birthday.

{phang}
{opt datediag(varname)} names the variable containing the date at diagnosis. 

{phang}
{opt allcause(newvarname)} calculates all-cause probabilities.

{phang}
{opt by(varlist)} calculates separate estimates of marginal relative survival for the groups defined by {varlist}. 
Note that a missing value is included as a level when using {cmd:by()}.

{phang}
{opt crudeprob(newvarlist)} calculates crude probabilities of death. If only one new variable is listed then the crude probabilities of death due to the disease are calculated. 
If two variables are listed then both crude probabilties of death due to cancer and other causes are calculated.

{phang}
{opt deathprob} calculates probabilities of death rather than survival. This affects both net and all-cause survival, but has no impact for the {cmd:crudeprob()} option.

{phang}
{opt ederer2} will lead to calculation of the Ederer II estimate rather than Pohar Perme estimate.

{phang}
{opt fh} will use the Fleming-Harrington estiamtor of survival (the expoential of the negative cumulative (excess) hazard). The default is the product intergral method.

{phang}
{opt frame(framename)} will save the results obtained through using the {cmd:list()} option to a frame. You can use a {cmd:, replace} suboption to overwrite an existing frame.

{phang}
{opt indweights(varname)} incorporates individual level weights to up- or down-weight individuals relative to a reference population. This is useful for external age standardization.

{phang}
{opt level(#)} specifies the confidence level, as a percentage, for confidence intervals.  The default is level(95) or as set by set level.

{phang}
{opt list(numlist)} gives times to list estimates of marginal relative survival (and confidence intervals). 
For example, {cmd:list(1 5 10)} will list marginal survival at 1, 5 and 10 years.

{phang}
{opt pmage(varname)} gives name of age variable in the population mortality file. The default is {cmd:_age}. This variable cannot exist in the patient data file, but should exist in the population mortality file.

{phang}
{opt pmyear(varname)} name of year variable in the population mortality file. The default is {cmd:_year}. This variable cannot exist in the patient data file, but should exist in the population mortality file.

{phang}
{opt pmother(varlist)} names additional variables in the population mortality file. 
Usually this will include sex, but could additionally be, for example, information on region, deprivation etc. 
All variables listed should be in both the data and the population mortality file.

{phang}
{opt pmrate(varname)} name of the rate variable in the population mortality file. The default is {cmd:rate}.
The rate should be expressed per person year. 
If you only have one year survival probabilities in the population mortality file, then you can obtain the rate using {cmd:gen rate = -ln(survprob)},
where {cmd:survprob} is the one year survival probability.

{phang}
{opt pmmaxage(#)} specifies the maximum age for which general-population mortality rates are provided in the using file.
Rates for individuals older than this value are assumed to be the same as for maximum age {it:#}.
The default maximum age is 99.

{phang}
{opt pmmaxyear(#)} specifies the maximum year for which general-population mortality rates are provided in the using file.
Rates for individuals still at risk after this year are assumed to be the same as for maximum year {it:#}.  

{phang}
{opt standstrata(varname)} gives the variable defining strata across which to average marginal relative survival.
Weights can be specified using the {cmd:standweights()} options.

{phang}
{opt standweights(numlist)} gives the weights for obtaining standardized estimates. 
The {it:numlist} should be of length equal to the number of levels specified in {cmd:standstrata(varname)}

{phang}
{opt using2(filename, suboptions)} gives the name of a second population mortality file. 
This can be incorporated as a second time-dependent weight so that the estimators of Sasieni and Brentnall are incorporated when calculating marginal relative survival. When used when calculating crude probabilities of death or all-cause survival the second popmort file is applied to ensure that crude-probabilities are comparable in that they should only differ due to differences in excess mortality (assuming they have been standardized appropriately).

{phang2} 
The following suboptions are available.

{phang2} 
{opt pmage2(varname)} gives name of age variable in the second population mortality file. The default is the same name 
used in the {cmd:pmage} option. This variable must exist in the population mortality file.   

{phang2} 
{opt pmother2(varname)} names additional variables in the second population mortality file. The default is the same name 
used in the {cmd:pmother} option. If there are no additional variables in the second population mortality file then
use {cmd:pmother2(.)}.

{phang2} 
{opt pmrate2(varname)} name of the rate variable in the second population mortality file. The default is the same name 
used in the {cmd:pmrate} option

{phang2} 
{opt pmyear2(varname)} gives name of calednar year variable in the second population mortality file. The default is the same name 
used in the {cmd:pmyear} option. If population rates do not vary by calendar year in the second population mortality file then
use {cmd:pmyear2(.)}.

{phang}
{opt verbose} give some details about the how far the estimation process has proceeded. 
This was useful when developing the command, but may bring pleasure to those who like seeing dots appear.

{phang}
{opt graph} creates a plot of the main marginal relative survival estimate with a confidence interval. Really only one of the {cmd:graph}, {cmd:graphname} or {cmd:graphcode} options are required to get a plot.

{phang}
{opt graphname(name [, replace])} an option to name the graph - can replace an existing graph with the replace suboption. 

{phang}
{opt graphcode(filename)} creates a new do file, which contains the code to recreate the standard graph - this allows the option to make changes to the the plot - e.g. titles, whether to have a risktable etc.


{title:Examples}

{pstd}
All examples use colon cancer data available with {help strs}. First load and {cmd:stset} the data and then all example are clickable.
You will need to clear data in memory before running. 

{pmore}
{stata "use https://pclambert.net/data/colon.dta":. use "https://pclambert.net/data/colon.dta"}{p_end}
{pmore}
{stata "stset surv_mm,f(status=1,2) id(id)  scale(12) exit(time 120.5)":. stset surv_mm,f(status=1,2) id(id)  scale(12) exit(time 120.5)}{p_end}

{title:Example 1:}

Estimate marginal relative survival in the study population as a whole.


{phang2}
. stpp R_pp1 using "https://pclambert.net/data/popmort.dta", ///{p_end}
{p 16 20 2}
agediag(age) datediag(dx) {space 27 }///{p_end}
{p 16 20 2}
 pmother(sex) list(1 5 10) graphname(R_pp1, replace)  {p_end}

{pmore}
{it:({stata "stpp_example, egnumber(1)":click to run})}


{title:Example 2: }

Estimate marginal relative survival separately for males and females.

{phang2}
. stpp R_pp2 using "https://pclambert.net/data/popmort.dta", ///{p_end}
{p 16 20 2}
agediag(age) datediag(dx) {space 27 }///{p_end}
{p 16 20 2}
pmother(sex) list(1 5 10) graphname(R_pp2, replace) ///{p_end}
{p 16 20 2}
by(sex){p_end} 

{pmore}
{it:({stata "stpp_example, egnumber(2)":click to run})}

{title:Example 3: }

Estimate age-standardize marginal relative survival separately for males and females.
This uses the ICSS1 age standard with traditional standardiation through obtaining
a weighted average of age group-specific estimates.


{phang2}
. recode age (min/44=1) (45/54=2) (55/64=3) (65/74=4) (75/max=5), gen(ICSSagegrp){p_end}
{phang2}
. stpp R_pp3 using "https://pclambert.net/data/popmort.dta", ///{p_end}
{p 16 20 2}
agediag(age) datediag(dx) {space 27 }///{p_end}
{p 16 20 2}
pmother(sex) list(1 5 10){space 28 }///{p_end}
{p 16 20 2}
by(sex) {space 45 }///{p_end}
{p 16 20 2}
standstrata(ICSSagegrp){space 30 }///{p_end}
{p 16 20 2}
standweight(0.07 0.12 0.23 0.29 0.29) graphname(R_pp3, replace){p_end}

{pmore}
{it:({stata "stpp_example, egnumber(3)":click to run})}


{title:Example 4: }

Estimate age-standardize marginal relative survival separately for males and females.
This uses the ICSS1 age standard which is incorporated using individual weights.
This avoids the need to estimate separately in age groups.

{phang2}
. recode ICSSagegrp (1=0.28) (2=0.17) (3=0.21) (4=0.20) (5=0.14), gen(ICSSwt){p_end}
{phang2}
. bysort sex: gen sextotal= _N{p_end}
{phang2}
. bysort ICSSagegrp sex:gen a_age = _N/sextotal{p_end}
{phang2}
. gen double wt_age = ICSSwt/a_age{p_end}
{phang2}
. stpp R_pp4 using "https://pclambert.net/data/popmort.dta", ///{p_end}
{p 16 20 2}
agediag(age) datediag(dx) {space 27 }///{p_end}
{p 16 20 2}
pmother(sex) list(1 5 10){space 28 }///{p_end}
{p 16 20 2}
by(sex) {space 45 }///{p_end}
{p 16 20 2}
indweights(wt_age) graphname(R_pp4, replace) {p_end}

{pmore}
{it:({stata "stpp_example, egnumber(4)":click to run})}


{title:Stored results}

{pstd}
If the {cmd:list} option is used then the output is saved to matrix. 
When using the {cmd:by()} option multiple matrices will be saved as well
as the combined results.

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(PP)}}Pohar Perme estimates and 95% confidence intervals{p_end}
{synopt:{cmd:r(PPk)}}Pohar Perme estimates and 95% confidence intervals for kth by group{p_end}
{synopt:{cmd:r(AC)}}All-cause estimates and 95% confidence intervals{p_end}
{synopt:{cmd:r(ACk)}}All-cause estimates and 95% confidence intervals for kth by group{p_end}
{synopt:{cmd:r(CP_can)}}Crude probability estimates (cancer) and 95% confidence intervals{p_end}
{synopt:{cmd:r(CP_cank)}}Crude probability estimates (cancer) and 95% confidence intervals for kth by group{p_end}
{synopt:{cmd:r(CP_oth)}}Crude probability estimates (other causes) and 95% confidence intervals{p_end}
{synopt:{cmd:r(CP_othk)}}Crude probability estimates (other causes) and 95% confidence intervals for kth by group{p_end}
{title:Author}

{pstd}
Paul C Lambert, University of Leicester, UK & Karolinska Institutet, Sweden.
({browse "mailto:paul.lambert@leicester.ac.uk":paul.lambert@leicester.ac.uk})
Mark J Rutherford
({browse "mailto:mark.rutherford@leicester.ac.uk":mark.rutherford@leicester.ac.uk})

{title:References}

{phang}
E. Coviello, P.W. Dickman, K. Seppä, A. Pokhrel. Estimating net survival using a life table approach.
{it: The Stata Journal} 2015;15:173-185

{phang}
P.W. Dickman, E. Coviello, M.Hills, M. Estimating and modelling relative survival. {it: The Stata Journal} 2015;{bf:15}:186-215

{phang}
M. Pohar Perme, J. Stare, J. Estève. On estimation in relative survival 
{it:Biometrics} 2012;{bf:68}:113-120 

{phang}
P. Sasieni, A.R. Brentnall. On standardized relative Survival 
{it:Biometrics} 2016;{bf:73}:473-482 


