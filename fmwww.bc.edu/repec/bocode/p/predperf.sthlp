{smcl}
{* *! version 1.0 23 November 2024}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "C:\Users\tbuclin\ado\personal\predperf##syntax"}{...}
{viewerjumpto "Description" "C:\Users\tbuclin\ado\personal\predperf##description"}{...}
{viewerjumpto "Options" "C:\Users\tbuclin\ado\personal\predperf##options"}{...}
{viewerjumpto "Remarks" "C:\Users\tbuclin\ado\personal\predperf##remarks"}{...}
{viewerjumpto "Remarks" "C:\Users\tbuclin\ado\personal\predperf##references"}{...}

{p2colset 1 18 18 2}{...}
{p2col:{bf:[R] predperf} {hline 2}}Predictive performance {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 4 4 2}
Predictive performance versus 'true' observations (variable 1) of one single predictor (variable 2)

{p 8 12 2}
{cmd:predperf} {it:{help varname:varname1}} {it:{help varname:varname2}} {ifin}
[{it:{help predperf##weight:weight}}]
[{cmd:,} {it:{help predperf##options_table:options}}]

{p 4 4 2}
Predictive performance versus 'true' observations (variable 1) of two predictors (variables 2 and 3), 
with comparison of their respective performances

{p 8 12 2}
{cmd:predperf} {it:{help varname:varname1}} {it:{help varname:varname2}} {it:{help varname:varname3}} {ifin}
[{it:{help predperf##weight:weight}}]
[{cmd:,} {it:{help predperf##options:options}}]


{synoptset 18 tabbed}{...}
{marker options_table}{...}
{synopthdr}
{synoptline}
{synopt:{opt me:trics(#)}}  type of performance indices to compute; default is 1 (see {it:{help predperf##description:description}}){p_end}
{synopt:{opt re:l}}  equivalent to metrics(2): compute relative performance indices{p_end}
{synopt:{opt lo:g}}  equivalent to metrics(3): compute logarithmic performance indices{p_end}
{synopt:{opt le:vel(cilevel)}}  confidence level for the estimation of indices; default value is the confidence level set in STATA (usually 95){p_end}
{synopt:{opt df(# [#])}}  degrees of freedom to correct the computation of RMSE (or RMSPE or RMSLE); default is 0{p_end}
{synopt:{opt si:g}}  display significance levels associated to performance indices {p_end}
{synopt:{opt fl:oor(#)}}  constant to add to observations and predictions with metrics(3); default is 0{p_end}
{synopt:{opt no:graph}}  omit the production of a graph illustrating the predictive performance{p_end}
{synoptline}
{p2colreset}{...}
{marker weight}{...}
{p 4 6 2}
{opt by}, {opt bysort} and {opt statsby} are allowed; see {help prefix}.{p_end}
{p 4 6 2}
{opt fweight}s and {opt aweight}s are allowed; see {help weight}.{p_end}


{marker description}{...}
{title:Description}

{p 4 4 2}
{cmd:predperf} computes two classical predictive performance indices resulting from the comparison of one or two predictors with corresponding 'true' observations: the first one describes the {it:bias} of the predictor, 
i.e. its systematic departure from trueness, and the second one describes its {it:imprecision}, 
i.e. the average error by which individual predictions randomly diverge from trueness.
The approach is directly inspired from Sheiner's and Beal's suggestions for measuring predictive performance (see {it:{help predperf##references:references}}).
These simple, rudimentary indices are still widely used in many areas of applied sciences during the process of validation of predictive models with respect to true observations. {p_end}

{p 4 4 2}
The indices are computed according to one of three possible types of metrics: {p_end}

{p 4 4 2}
- by default, or if the option {cmd:metrics(1)} is specified, an {it:additive} approach is used to compute the {it}Mean Error{sf} (ME) and the {it}Root Mean Square Error{sf} (RMSE), 
which are thus expressed in the units of the observations and predictions;
(RMSE is computed by STATA for most regression analyses to quantify the average lack-of-fit between predictions and observations; 
it corresponds to Roy Wada's command {it:{help rmse:rmse Yobs Ypred, raw}})  {p_end}

{p 16 16 2}
ME = mean[Ypred - Yobs]   and   RMSE = sqrt(mean[(Ypred - Yobs)^2]) {p_end}

{p 4 4 2}
- specifying the option {cmd:rel} or {cmd:metrics(2)} will apply a {it:relative} approach in the computation of {it}Mean Percent Error{sf} (MPE) and {it}Root Mean Square Percent Error{sf} (RMSPE), both expressed in percentage ratios; {p_end}

{p 16 16 2}
MPE = mean[(Ypred - Yobs)/Yobs]   and   RMSPE = sqrt(mean[(Ypred - Yobs)^2 / Yobs^2]) {p_end}

{p 4 4 2}
- specifying the option {cmd:log} or {cmd:metrics(3)} will apply a {it:logarithmic} approach in the computation of {it}Mean Log Error{sf} (MLE), which will be expressed as geometric mean ratio, 
while {it}Root Mean Square Log Error{sf} (RMSLE) is expressed as a log-based coefficient of variation. {p_end}

{p 16 16 2}
MLE = exp(mean[(Log(Ypred) - Log(Yobs))]   and   RMSLE = sqrt(mean[(Log(Ypred) - Log(Yobs))^2]) {p_end}

{p 4 4 2}
The calculated values of the indices are complemented by {it}confidence intervals{sf} that give a clue on the precision of their estimation, under the assumption of independence and normality (or log-normality) of the prediction errors. 
The {cmd:sig} option displays {it}p-levels{sf} indicating whether  ME or MPE depart significantly from 0, or of MLE from 1, 
and whether RMSE, RMSPE or RMSLE differ significantly from the raw dispersion of observations (i.e. SD, CV or logarithmic SD), 
i.e. whether the predictor predicts the observations better than purely random values with a similar distribution would. 
In addition, if two predictors are evaluated, {cmd:predperf} will estimate the differences between respective bias and imprecision indices, and their significance (with {cmd:sig}). {p_end}

{p 4 4 2}
Eventually, {cmd:predperf} produces a graph illustrating the prediction performance of the predictor(s), showing a  scatterplot of observations versus predictions along the identity line (y=x), 
complemented with prediction bands encompassing ±1 and ±2 RMSE (or RMSPE or RMSLE) and a line indicating the level of ME (or MPE or MLE). {p_end}


{marker options}{...}
{title:Options}

{dlgtab:Main}

{p 4 8 2}
{opt me:trics(#)} specifies the type of performance indices to compute: (see {it:{help predperf##description:description}}){p_end}
{p 4 8 2}
 - 1 (default): absolute bias (ME) and imprecision (RMSE) in native observation units{p_end}
{p 4 8 2}
 - 2: relative bias (MPE) and imprecision (RMSPE), both as percentage ratios {p_end}
{p 4 8 2}
 - 3: relative bias (MLE) as geometric mean ratio, and relative imprecision (RMSLE) as logarithm{p_end}

{p 4 8 2}
{opt re:l}  is equivalent to metrics(2), requesting the estimation of relative bias (MPE) and imprecision (RMSPE), both expressed as percentage ratios {p_end}

{p 4 8 2}
{opt lo:g}  is equivalent to metrics(3), requesting the estimation of relative bias (MLE) as geometric mean ratio, and relative imprecision (RMSLE) as logarithm {p_end}

{p 4 8 2}
{opt le:vel(cilevel)}  specifies the confidence level for the estimation of confidence intervals around estimated performance indices; the default value is the confidence level set in STATA (usually 95){p_end}

{p 4 8 2}
{opt df(#)} (or {opt df(# #)} if two predictors are compared) specifies the degrees of freedom for correcting the computation of RMSE (or RMSPE or RMSLE). 
The default value is 0. 
It is appropriate to leave the df value set to 0 as long as the predictions have been obtained from a model developed without reference to the observations used to validate its predictive performance. 
Conversely, if the predictions have been calculated with a model based on the observations, e.g. by linear or non-lineaar regression, 
it would by appropriate to set a df value equal to the number of estimated parameters of the model to calculate unbiased values for RMSE (or RMSPE or RMSLE).
When the option df(k) is specified, the following formula is used to correct RMSE calculation:{p_end}

{p 16 16 2}
RMSE = sqrt(mean[(Ypred - Yobs)^2] * N/(N - k)) {p_end}

{p 4 8 2}
{opt si:g}  displays significance levels associated with the departure of ME or MPE from 0, or of MLE from 1, 
and the difference of RMSE, RMSPE, or RMSLE from the raw dispersion of observations (i.e. respectively SD, SDP = percentage SD, or SDL = logarithmic SD).
If two predictors are evaluated, the significance of differences between respective bias and imprecision indices will be displayed as well. {p_end}

{p 4 8 2}
{opt fl:oor(#)}  is used only with metrics(3). It specifies to add a constant value to observations and predictions before their Log-transormation, to make logarithmic transformation possible in case of negative or zero values. 
The default floor value is 0.{p_end}

{p 4 8 2}
{opt no:graph}  will omit the production of a graph illustrating the predictive performance. {p_end}


{marker example}{...}
{title:Example}

{p 4 8 2}
The dataset 'sheinerbealdata.dta' contains the data serving as example in the article of Sheiner and Beal (see {it:{help predperf##references:references}}).  {p_end}
{p 8 16 2}{cmd:. use sheinerbealdata.dta} {p_end}

{p 4 8 2}Evaluate the predictive performance of predictor A compared to observations Y, expressed as absolute bias (ME) and imprecision (RMSE):{p_end}
{p 8 16 2}{cmd:. predperf y a} {p_end}

{p 4 8 2}Evaluate the predictive performance of predictor A compared to observations Y, expressed as relative bias (MPE) and imprecision (RMSPE), 
testing whether MPE differs significantly from zero and RMSPE from the CV of the set of observations:{p_end}
{p 8 16 2}{cmd:. predperf y a, rel sig} {p_end}

{p 4 8 2}Compare the predictive performances of predictors A and B versus observations Y, expressed as logarithmis bias (MLE) and imprecision (RMSLE), testing whether they differ significantly.
The lower limit of quantification of 0.1 for both predictors is used to replace zero values:{p_end}
{p 8 16 2}{cmd:. predperf y a b, log sig floor(0.1)} {p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:predperf} stores the following values in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}  number of pairs of observations-predictions included in the calculations{p_end}
{synopt:{cmd:r(level)}}  confidence level used in confidence interval calculations{p_end}
{synopt:{cmd:r(df_1)}}  degrees of freedom substracted fom N in RMSE/RSMPE/RSMLE calculation for predictor 1{p_end}
{synopt:{cmd:r(me_1)}}  ME/MPE/MLE estimate for predictor 1{p_end}
{synopt:{cmd:r(me_lb_1)}}  lower bound of the confidence interval of ME/MPE/MLE for predictor 1{p_end}
{synopt:{cmd:r(me_ub_1)}}  upper bound of the confidence interval of ME/MPE/MLE for predictor 1{p_end}
{synopt:{cmd:r(p_me_1)}}  significance level associated with ME/MPE/MLE for predictor 1{p_end}
{synopt:{cmd:r(rmse_1)}}  RMSE/RMSPE/RMSLE estimate for predictor 1{p_end}
{synopt:{cmd:r(rmse_lb_1)}}  lower bound of the confidence interval of RMSE/RMSPE/RMSLE for predictor 1{p_end}
{synopt:{cmd:r(rmse_ub_1)}}  upper bound of the confidence interval of RMSE/RMSPE/RMSLE for predictor 1{p_end}
{synopt:{cmd:r(p_rmse_1)}}  significance level associated with RMSE/RMSPE/RMSLE for predictor 1{p_end}

{p2col 5 15 19 2: Scalars computed for two predictors}{p_end}
{synopt:{cmd:r(df_2)}}  degrees of freedom substracted fom N in RMSE/RSMPE/RSMLE calculation for predictor 2{p_end}
{synopt:{cmd:r(me_2)}}  ME/MPE/MLE estimate for predictor 2{p_end}
{synopt:{cmd:r(me_lb_2)}}  lower bound of the confidence interval of ME/MPE/MLE for predictor 2{p_end}
{synopt:{cmd:r(me_ub_2)}}  upper bound of the confidence interval of ME/MPE/MLE for predictor 2{p_end}
{synopt:{cmd:r(p_me_2)}}  significance level associated with ME/MPE/MLE for predictor 2{p_end}
{synopt:{cmd:r(rmse_2)}}  RMSE/RMSPE/RMSLE estimate for predictor 2{p_end}
{synopt:{cmd:r(rmse_lb_2)}}  lower bound of the confidence interval of RMSE/RMSPE/RMSLE for predictor 2{p_end}
{synopt:{cmd:r(rmse_ub_2)}}  upper bound of the confidence interval of RMSE/RMSPE/RMSLE for predictor 2{p_end}
{synopt:{cmd:r(p_rmse_2}}  significance level associated with RMSE/RMSPE/RMSLE for predictor 2{p_end}
{synopt:{cmd:r(me_12)}}  difference of ME/MPE or ratio of MLE between predictors 1 and 2{p_end}
{synopt:{cmd:r(me_lb_12)}}  lower bound of the confidence interval of ME/MPE/MLE difference or ratio{p_end}
{synopt:{cmd:r(me_ub_12)}}  upper bound of the confidence interval of ME/MPE/MLE difference or ratio{p_end}
{synopt:{cmd:r(p_me_12)}}  significance level associated with the difference or ration of ME/MPE/MLE{p_end}
{synopt:{cmd:r(rmse_12)}}  difference of RMSE/RMSPE/RMSLE between predictors 1 and 2{p_end}
{synopt:{cmd:r(rmse_lb_12)}}  lower bound of the confidence interval of RMSE/RMSPE/RMSLE difference{p_end}
{synopt:{cmd:r(rmse_ub_12)}}  upper bound of the confidence interval of RMSE/RMSPE/RMSLE difference{p_end}
{synopt:{cmd:r(p_rmse_12}}  significance level associated with the difference in RMSE/RMSPE/RMSLE{p_end}

{p2colreset}{...}

{title:Author}
{p 4 8 2}
Thierry Buclin, Clinical Pharmacology Service, University Hospital of Lausanne (CHUV) and Faculty of Biology and Medicine of the University of Lausanne (Switzerland) [e-mail address: Thierry.Buclin_at_chuv.ch] {p_end}


{marker references}{...}
{title:References}
{p 4 8 2}
Sheiner LB, Beal SL. Some suggestions for measuring predictive performance. {it}Journal of Pharmacokinetics and Biopharmaceutics{sf}. 1981;9(4):503-12. DOI: 10.1007/BF01060893.  {p_end}

