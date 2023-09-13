{smcl}
{* August19,2022}{...}
{cmd:help scul} 
{hline}

{cmd:Beta version 0.0.9} - Release date:June 31, 2022.
Update: August19,2022

{p}

{title:Description}


{p 6 6 2}
{hi:scul} is adapted from the R code by Hollingsworth and Wing (2021) in the framework described by Abadie (2003,2010,2021) for comparative case studies. It uses LASSO to learn the treated
unit's pre-intervention outcomes via the donor pool's outcomes, and then projects the counterfactual. {p_end}
{p2colreset}{...}

{title:Prerequisites}
{cmd:scul} demands an {cmd:xtset} panel dataset before it can be used. Also, one needs the {cmd:tabstatmat} (ssc inst {cmd:tabstatmat}, replace), {cmd:distinct} (ssc inst {cmd:distinct}, replace), {cmd:greshape} (ssc inst {cmd:gtools}, replace), {cmd:coefplot} (ssc inst {cmd:coefplot}, replace), and {cmd:cvlasso} commands to use {cmd:scul}. Quintessential to estimation is the {cmd:cvlasso} commmand from the {cmd:lassopack}

 
{marker syntax}{...}

{title:Syntax}

{p}
Note that by default, this command generates real vs. synthetic plots, as well as gap plots.

{cmd:scul} {depvar}{cmd:,} {opt treated(variable)} [{opt ahead(number)}] [{opt pla:cebos}] [{opt plat}] [{opt times(numlist)}] [{opt lamb:da(string)}] [{opt cov:s(varlist)}] [{opt cv(string)}] [{opt scheme(string)}]  [{opt rellab(numlist)}] 
[{opt obscol(string)}] [{opt cfcol(string)}] [{opt conf(string)}] [{opt legpos(integer)}] [{opt trans:form(string)}] [{opt q(real)}] [{opt donoradj(string)}] [{opt before(integer)}] [{opt after(integer)}]

{marker options}{...}

{title:Requirements}

{phang}{depvar} specifies the outcome. This variable may not have missing observations.

{phang}{opt treated} specifies the treatment variable. This variable may have no missing values, must be either 0 or 1, and must always be 1 after the treatment turns on. If more than one unit is treated, then scul uses staggered adoption.


{title:Options}

{phang}{opt ahead} specifies the number of periods ahead the user wishes to predict in the training dataset. See the options for {cmd:cvlasso} for details on this procedure.

{phang}{opt lambda} is optional. The user may specify {opt lopt} (optimal lambda) or {opt lse} (standard error rule), following the discussion from chapter two of Hastie et al. (2019).

{phang}{opt placebos} is optional. Iteratively, the treatment is reassigned to the entire donor pool of units, using the original model specified by the user. This produces a plot of these estimates, as well as 95% CIs of placebos.

{phang}{opt plat} is optional, and {opt times} is required. {opt plat} specifies the desire for in-time placebos. {opt times} reflects the relative event-time periods that the user wishes to use as a placebo period. If the
intervention happens in 2000 and the user specifies 5 and 10, the intervention will be evaluated at 1995 and 1990.


{phang}{opt covs} is optional. The counterfactual is estimated with these covariates.

{phang}{opt scheme} is optional. The user may specify the graph scheme they want here.

{phang}{opt placebos} is optional. The user estimates in-space placebos.

{phang}{opt legpos} is optional. The user specifies where they'd like their legend to appear on the graph in Stata's o'clock notation.

{phang}{opt squerr} is required, if {opt placebos} are specified. This option drops placebo units whose pre-intervention RMSPE is a given order of magnitude times greater than the RMSPE of the treated unit in the same period.

{phang}{opt obscol} and {opt cfcol} are optional. The user specifies the colors they'd like for their treated and untreated units lines to be.

{phang}{opt q} is optional. The user specifies the regularizer they'd like to use. When {opt q}=0, we have the Ridge penalty, and when {opt q}=1, we have the LASSO. By default, the LASSO is specified.

{phang}{opt conf} is optional. The user specifies "ci". The user graphs the confidence intervals from the t-test. Note that the confidence intervals are still calculated and present in the saved datasets, they just are not graphed if the user does not specify this option.

{phang}{opt transform} is optional. The outcome variable is normalized to the time before the intervention takes place at. See (Wiltshire, 2022) for details.

{title:Required Options, Staggered Adoption}

{phang}{opt donoradj} is required. The user specifies how they would like to adjust their donor pool by inputting {opt et} or {opt nt} as options. Specifying {opt et} means that the user wishes to use the units that were ever-treated as donors,
while {opt nt} means using only units which were never treated as donors.

{phang}{opt before} and {opt after} are required. The user specifies how many relative event-time periods the treatment effect will be averaged over. Note that this keeps only the treated units that have this many 
before and after periods. Suppose a user has one year of monthly data on three treated units, one treated in January (period 1), another treated in March (period 3) and another treated unit in August (period 8). If the user specifies {opt before}(2) and {opt after}(2), then the first treated unit will be dropped because it doesn't have 2 periods of pre-intervention data.

{title:Options, Staggered Adoption}
{phang}{opt rellab} is optional. The user specifies how many periods the event-time axis will be labeled from and to. For example, if the user were to specify (-5(5)5), the graph will show the 
average treatment effect from 5 periods before the intervention to 5 periods after the intervention. Note that this does NOT change the period over which the effects are calculated, only about how the treatment effect graph is displayed.

{title:Results}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Datasets}{p_end}
{synopt:{cmd:scul_unit}}Dataset for Single Treated Unit{p_end}

{synopt:{cmd:timeplacebos}}In-Time Placebo Dataset{p_end}

{synopt:{cmd:atts_scul}}Staggered Adoption Dataset{p_end}

{synopt:{cmd:placebos_unit}}In-Space Placebo Dataset{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(W)}}Weights Table for Single-Treated Case{p_end}

{synopt:{cmd:r(ATTs)}}ATTs and Confidence Intervals for Staggered Adoption{p_end}

{synopt:{cmd:r(itplacebos)}}ATTs and RMSEs for In-Time Placebo Studies{p_end}

{synopt:{cmd:r(errs)}}ATT, Pre/Post RMSEs, Ratio and rank of In-Space Placebos{p_end}


{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(ATT)}}Average Treatment Effect{p_end}

{synopt:{cmd:e(MSE)}}Pre-Intervention Error{p_end}

{synopt:{cmd:e(PMSE)}}Post-Intervention Error{p_end}

{synopt:{cmd:e(LB)}}Lower Bound of ATT{p_end}

{synopt:{cmd:e(UB)}}Upper Bound of ATT{p_end}

{synopt:{cmd:e(ratio)}}Post error divided by pre-error{p_end}


{marker examples}{...}

{title:Examples}

Note I use labvars and labmask

{hline}

{pstd}Single Treated Cases

{title:Basque Country}

u "http://fmwww.bc.edu/repec/bocode/s/scul_basque.dta", clear

qui xtset
local lbl: value label `r(panelvar)'

loc unit ="Basque Country (Pais Vasco)":`lbl'


loc int_time = 1975

qui xtset
cls

g treat = cond(`r(panelvar)'==`unit' & `r(timevar)' >= `int_time',1,0)

scul gdpcap, ahead(3) treat(treat) ///
obscol(black) cfcol("170 19 15") legpos(11)


{title:Proposition 99- Divisional Analysis}

loc int_time = 1989

u "http://fmwww.bc.edu/repec/bocode/s/scul_p99_region", clear
qui xtset
local lbl: value label `r(panelvar)'

loc unit ="California":`lbl'
qui xtset
g treat = cond(`r(panelvar)'==`unit' & `r(timevar)' >= `int_time',1,0)
cls

scul cigsale, ///
	ahead(1)  ///
	treated(treat) ///
	obscol(black) ///
	cfcol(blue) ///
	legpos(7) cv(adaptive)
{hline}
{title:BP Analysis}
loc dv score

loc covs index_score buzz_score ///
impression_score ///
quality_score ///
value_score satisfaction_score ///
recommend_score

loc int_time: di tm(2010m4)


u "http://fmwww.bc.edu/repec/bocode/s/scul_bp.dta", clear

replace yougovname = subinstr(yougovname, ".", "",.)

labmask id, value(yougovname)
local lbl: value label id


loc unit ="BP":`lbl'
qui xtset
cls

g treat = cond(`r(panelvar)'==`unit' & `r(timevar)' >= `int_time',1,0)

format date %tm

lab var date "Month"

xtset id date, m // !! Makes our data panel data

keep if date <= tm(2012m6)

cls

scul score, ///
	ahead(6) ///
	treat(treat) ///
	obscol(black) ///
	cfcol(red) ///
	legpos(5) ///
	cv(adaptive)	

{title:West Germany}
u "http://fmwww.bc.edu/repec/bocode/s/scul_Reunification.dta", clear
loc int_time = 1990
cls
qui xtset
local lbl: value label `r(panelvar)'


loc unit ="West Germany":`lbl'

g treat = cond(`r(panelvar)'==`unit' & `r(timevar)' >=`int_time',1,0)

// ssc inst labvars
labvars gdp treat "GDP per Capita" "Reunification"

scul gdp, ///
	tr(treat) ///
	ahead(8)  ///
	cfcol(red) obscol(black) cv(adaptive) ///
	legpos(9) //
{hline}
{title:Kansas Tax Cuts}

u "http://fmwww.bc.edu/repec/bocode/s/scul_Taxes", clear
loc int_time: disp tq(2012q1)
cls
qui xtset
local lbl: value label `r(panelvar)'


loc unit ="Kansas":`lbl'

g treat = cond(`r(panelvar)'==`unit' & `r(timevar)' >=`int_time',1,0)


scul gdp, ahead(4) treated(treat) ///
	obscol(black) ///
	cfcol(blue) ///
	q(.5) cv(adaptive) legpos(7)
{hline}
{title:Ukraine Invasion Effect on GDP}

u "http://fmwww.bc.edu/repec/bocode/s/scul_invasion.dta", clear
loc int_time = 2014
cls
qui xtset
local lbl: value label `r(panelvar)'


loc unit ="Ukraine":`lbl'

g treat = cond(`r(panelvar)'==`unit' & `r(timevar)' >=`int_time',1,0)


scul gdp, ahead(4) treated(treat) ///
	obscol(black) ///
	cfcol(blue) ///
	q(.5) cv(adaptive) legpos(7)
{hline}
{title:Effect of Stadium on Housing Prices}	
u "http://fmwww.bc.edu/repec/bocode/s/scul_Stadium.dta", clear
loc int_time = 2017
cls
qui xtset
local lbl: value label `r(panelvar)'


loc unit ="Cobb":`lbl'

g treat = cond(`r(panelvar)'==`unit' & `r(timevar)' >=`int_time',1,0)


scul realgrossvpa, ahead(4) treated(treat) ///
	obscol(black) ///
	cfcol(blue) ///
	q(.5) cv(adaptive) legpos(7)

{title: Gas Holiday Studies}

u "http://fmwww.bc.edu/repec/bocode/g/GasHoliday.dta", clear

xtset id date, d

scul regular, ///
	ahead(28)  ///
	treat(treat) ///
	obscol(black) ///
	cfcol(170 19 15) ///
	legpos(7) ///
	before(28) after(28) ///
	donadj(et) ///
	rellab(-28(7)28) //
{hline}

{title:References}
{p 4 8 2}
Abadie, A. (2021). Using synthetic controls: Feasibility, data requirements, and methodological aspects. J. Econ. Lit, 59(2), 391-425. {browse "https://doi.org/10.1257/jel.20191450"}

{p 4 8 2}
Abadie, A., Diamond, A., & Hainmueller, J. (2010). Synthetic control methods for comparative case studies: Estimating the effect of california’s tobacco control program. J. Am. Stat. Assoc.,
105(490), 493-505. {browse "https://doi.org/10.1198/jasa.2009.ap08746"}

{p 4 8 2}
Abadie, A., Diamond, A., & Hainmueller, J. (2015). Comparative politics and the synthetic control method. Am. J. Pol. Sci., 59(2), 495-510. {browse "https://doi.org/10.1111/ajps.12116"}
 
{p 4 8 2}
Abadie, A., & Jeremy, L. H. (2021). A penalized synthetic control estimator for disaggregated data. J. Am. Stat. Assoc., 116(536), 1817-1834. {browse "https://doi.org/10.1080/01621459.2021.1971535"}
 
{p 4 8 2}
Amjad, M., Shah, D., & Shen, D. (2018). Robust synthetic control. The Journal of Machine Learning Research, 19(1), 802-852. {browse "https://dl.acm.org/doi/10.5555/3291125.3291147"}

{p 4 8 2}
Botosaru, I., & Ferman, B. (2019). On the role of covariates in the synthetic control method. Economet J, 22(2), 117-130. {browse "https://doi.org/10.1093/ectj/utz001"}

{p 4 8 2}
Bouttell, J., Craig, P., Lewsey, J., Robinson, M., & Popham, F. (2018). Synthetic control methodology as a tool for evaluating population-level health interventions. J. Epidemiol. Community Health,
72(8), 673-678.{browse "https://doi.org/10.1136/jech-2017-210106"}

{p 4 8 2}
Bradbury, J. C. 2022. Does hosting a professional sports team benefit the local community? Evidence from property assessments. Economics of Governance 1–34. {browse "https://doi.org/10.1007/s10101-022-00268-z"}

{p 4 8 2}
Hastie, T., Tibshirani, R., & Wainwright, M. (2019). Statistical learning with sparsity: The lasso and generalizations. Chapman and Hall/CRC.

{p 4 8 2}
Hollingsworth, A., & Wing, C. (2022). Tactics for design and inference in synthetic control studies: An applied example using high-dimensional data [working paper] {browse "10.31235/osf.io/fc9xt."}

{p 4 8 2}
Li, K. T., & Bell, D. R. (2017). Estimation of average treatment effects with panel data: Asymptotic theory and implementation. J. Econom., 197(1), 65-75. {browse "https://doi.org/10.1016/j.jeconom.2016.01.011"}

{p 4 8 2}
Shi, Z., & Huang, J. (2021). Forward-selected panel data approach for program evaluation. J. Econom. {browse "https://doi.org/10.1016/j.jeconom.2021.04.009"}

{p 4 8 2}
Wiltshire, J. C. (2022). Allsynth: (stacked) synthetic control bias-correction utilities for stata [working paper]. {browse "https://tinyurl.com/2qmtqk9q"} {p_end}
{p2colreset}{...}

{title:Contact}

Jared Greathouse, Georgia State University -- {browse "https://tinyurl.com/2yjzfjz4"}
Emails--
Student: {browse "jgreathouse3@student.gsu.edu"}
Personal: {browse "j.greathouse200@gmail.com"}

Email me with questions, comments, suggestions or bug reports.
 

{hline}
