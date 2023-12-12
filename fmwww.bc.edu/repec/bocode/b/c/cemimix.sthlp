{smcl}
{* *! cemimix version 1.0 19Dec2019}{...}
{cmd:help cemimix}
{hline}

{title:Title}

{p2colset 5 14 16 2}{...}
{p2col :{cmd:cemimix} {hline 2}} Reference-based multiple imputation of continuous
cost and effectiveness data in clinical trials {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 13 2}
{cmdab:cemimix}{cmd:,} {opth effectv(varlist)} {opth costv(varlist)} {opth treatv(varname)} [{it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opth effectv(varlist)}}Effectiveness variables{p_end}
{p2coldent:* {opth costv(varlist)}}Cost variables{p_end}
{p2coldent:* {opth treatv(varname)}}Numeric variable identifying the trial arms{p_end}
{synopt: {opt emethod(string)}}Imputation method for the effectiveness variables{p_end}
{synopt: {opt cmethod(string)}}Imputation method for the cost variables{p_end}
{synopt:{opt ref:group(string)}}Reference group, for CIR and J2R imputation{p_end}
{synopt:{opth cov:ariates(varlist)}}Additional baseline variables used 
in the imputation model{p_end}
{synopt:{opt inter:im_mar(string)}}Impute interim-missing data under MAR{p_end}
{synopt:{opt restrict:to(string)}}Restrict reference-based imputation to 
a subgroup, other individuals imputed under MAR{p_end}
{synopt:{opth idv(varname)}}Variable identifying individuals{p_end}
{synopt:{opt m(#)}}Number of imputations; default is m(5) {p_end}
{synopt:{opt burnb:etween(#)}}Number of iterations between imputations
 in the Markov Chain Monte Carlo (MCMC) procedure{p_end}
{synopt:{opt burn:in(#)}}Number of iterations for the burn-in period 
in the MCMC procedure{p_end}
{synopt:{opt rseed(#)}}Set random-number seed{p_end}
{synopt:{cmdab:sav:ing(}{it:{help filename}}[{cmd:, replace}]{cmd:)}}Save 
imputed dataset{p_end}
{synopt:{opt restore}}Restore original dataset{p_end}
{synoptline}
{p2colreset}{...}
{pstd}* {cmd:treatv()} is required. Either {cmd:effectv()} or {cmd:costv()} is
required.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:cemimix} imputes missing cost-effectiveness data following 
a reference-based multiple imputation approach.
It follows the method described in 
{help cemimix##R2020:Leurent et al. (2020)}, based on the work by  
{help mimix##R2013:Carpenter, Roger, and Kenward (2013)}.

{pstd}
It allows for various missing data assumptions, including 'Missing at random' 
(MAR, the default), 'Jump to reference' (J2R), 
'Copy increments in reference' (CIR), 'Last mean carried forward (LMCF), 
and 'Baseline mean carried forward' (BMCF). Different MNAR mechanisms for cost 
and effectiveness varaibles are not allowed, but one could be MAR and the other MNAR.

{pstd}
The data need to be stored in a 'wide' format (one row per individual). The 
resulting multiply-imputed data are {helpb mi set}, ready 
to analyze using {helpb mi estimate}.

{pstd}
It was developed for the analysis of cost-effectiveness data in randomised
controlled trials, but can be used more generally for the imputation of multiple 
(repeatedly-measured) continous outcomes.


{marker options}{...}
{title:Options}

{phang}
{opth effectv(varlist)} specifies the effectiveness variable(s),
 in consecutive order. Must be numeric.

{phang}
{opth costv(varlist)} specifies the cost variable(s),
 in consecutive order. Must be numeric.

{phang}
{opth treatv(varname)} specifies the trial treatment arm variable. Needs
to be a numeric variable. Multiple arms are allowed.

{phang}
{opt emethod(string)} specifies the imputation method for the
 effectiveness variable(s). May be {opt MAR}, {opt J2R},
{opt CIR}, {opt LMCF}, or {opt BMCF}. The default is {opt emethod(MAR)}.{p_end}

{phang}
{opt cmethod(string)} specifies the imputation method for the 
cost variable(s). May be {opt MAR}, {opt J2R},
{opt CIR}, {opt LMCF}, or {opt BMCF}. The default is {opt cmethod(MAR)}.{p_end}

{phang}
{opt ref:group(string)} specifies the reference group number
 or name (as coded in {it:treatv});
required with {opt J2R} and {opt CIR} imputation.

{phang}
{opth cov:ariates(varlist)} Additional variables used in the imputation model.
 Covariates need to be complete and numerical. Categorical variables
 need to be split in dummy (binary) variables.{p_end}

{phang}
{opt inter:im_mar(string)} imputes interim-missing data under MAR. {it:string} may 
be {opt cost}, {opt effect}, or {opt cost effect}. If nothing specified, uses the 
imputation method from {opt emethod()}  and {opt cmethod()} .{p_end}

{phang}
{opt restrict:to(string)} indicates a subgroup on which to restrict
 the reference-based imputation. Other individuals 
 are imputed under MAR. For example, could restrict MNAR imputation
 to a single arm, or to participants who dropped-out for a specific reason.
 E.g. {opt restrictto(arm==1 & reason=="withdraw")}.{p_end}

{phang}
{opth idv(varname)} specifies the variable identifying individuals 
in the dataset. May be either a numeric or a string variable.

{phang}
{opt m(#)} specifies the number of imputations; default is {opt m(5)}.

{phang}
{opt burnb:etween(#)} specifies the number of iterations between pulls for the
posterior in the MCMC.  The default is {opt burnbetween(100)}.

{phang}
{opt burn:in(#)} specifies the number of iterations in the MCMC burn-in.  The
default is {opt burnin(100)}.

{phang}
{opt rseed(#)} sets the random-number seed for the imputation procedure. If 
nothing is specified, a random seed is used and different runs 
will result in a different set of imputed data. If a seed is specified, 
cemimix will return the same set of imputed data on 
 separate runs (if applied applied to the exactly same sorted dataset, and 
 with the variables specified in the same order). 
 
{phang}
{cmdab:sav:ing(}{it:{help filename}}[{cmd:, replace}]{cmd:)}} saves the 
dataset of imputed values in {it:filename.dta}. A new {it:filename} is required 
unless {opt replace}  is also specified.
 {p_end}

{phang}
{opt restore} reloads the original dataset in memory at the end of the 
imputation. If not used, the newly imputed dataset will be in memory
at the end of the imputation {p_end}


{marker examples}{...}
{title:Examples}

{pstd}
Analyzing Ten Top Tips trial data{p_end}
{phang2}{cmd:. use 10TT, clear}{p_end}

{pstd}
Imputation assuming effectiveness and cost variables are 
MAR, with age and sex as covariates{p_end}
{phang2}{cmd:. cemimix, effectv(qol_0 qol_3 qol_6 qol_12 qol_18 qol_24) costv(totalcost) covariates(age sex) treatv(arm) m(50)}{p_end}

{pstd}
Assuming missing effectiveness values jump to control arm values {p_end}
{phang2}{cmd:. cemimix, effectv(qol_0 qol_3 qol_6 qol_12 qol_18 qol_24) costv(totalcost) covariates(age sex) emethod(J2R) ref(0) cmethod(MAR) treatv(arm) m(50)}{p_end}

{pstd}
Assuming effectiveness go back to baseline values after drop-out. Interim
missing assumed MAR{p_end}
{phang2}{cmd:. cemimix, effectv(qol_0 qol_3 qol_6 qol_12 qol_18 qol_24) costv(totalcost) covariates(age sex) emethod(BMCF) interim_mar(effect) cmethod(MAR) treatv(arm) m(50)}{p_end}

{pstd}
Then generate imputed quality-adjusted life years and compare between arms {p_end}
{phang2}{cmd:. mi passive: generate qaly=0.125*qol_0 + 0.25*qol_3 + 0.375*qol_6 + 0.5*qol_12 + 0.5*qol_18 + 0.25*qol_24}{p_end}
{phang2}{cmd:. mi estimate: regress qaly arm}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:mimix} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}total sample size in original dataset{p_end}
{synopt:{cmd:r(m)}}number of imputations{p_end}

{p2col 5 15 19 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:cemimix}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:r(effectv)}}effectiveness variables {p_end}
{synopt:{cmd:r(costv)}}cost variables{p_end}
{synopt:{cmd:r(covariates)}}imputation covariate variables{p_end}
{synopt:{cmd:r(emethod)}}main imputation method for effectiveness variables{p_end}
{synopt:{cmd:r(cmethod)}}main imputation method for cost variables{p_end}
{synopt:{cmd:r(eintmeth)}}imputation method for interim missing effectiveness variables{p_end}
{synopt:{cmd:r(cintmeth)}}imputation method for interim missing cost variables{p_end}
{synopt:{cmd:r(restrictto)}}MNAR imputation subgroup{p_end}
{synopt:{cmd:r(rseed)}}random-number seed{p_end}


{title:Acknowledgments}

{pstd}
This program is an adaptation of the mimix Stata program, developed by 
Suzie Cro and Tim Morris, and itself based on the SAS macro, 
miwithd, written by James Roger.


{marker references}{...}
{title:References}

{marker R2013}{...}
{phang}
Carpenter, J. R., J. H. Roger, and M. G. Kenward. 2013. Analysis of longitudinal 
trials with protocol deviation: A framework for relevant, accessible assumptions, 
and inference via multiple imputation. 
{it:Journal of Biopharmaceutical Statistics} 23: 1352-1371.

{marker R2020}{...}
{phang}
Leurent, B., Gomes, M., Cro, S., Wiles, N. and Carpenter, J.R., 2020. 
Reference‐based multiple imputation for missing data sensitivity analyses 
in trial‐based cost‐effectiveness analysis.
{it: Health economics} 29(2), pp.171-184.


{title:Author}

{pstd}
Baptiste Leurent{break}
University College London, UK{break}
baptiste.leurent@ucl.ac.uk
{p_end}

{pstd}
Suzie Cro{break}
Imperial College London, UK{break}
s.cro@imperial.ac.uk
{p_end}

