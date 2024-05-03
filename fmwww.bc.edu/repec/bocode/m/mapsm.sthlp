{smcl}
{* *! version 1.3 1May2024}{...}
{viewerdialog mapsm "dialog mapsm"}{...}
{viewerjumpto "Syntax" "mapsm##syntax"}{...}
{viewerjumpto "Description" "mapsm##description"}{...}
{viewerjumpto "Options" "mapsm##options"}{...}
{viewerjumpto "Examples" "mapsm##examples"}{...}
{viewerjumpto "Author" "mapsm##authors"}{...}

{p2col:{bf:mapsm}}Multiple arms propensity score matching 

{marker syntax}{...}
{title:Syntax}

{phang}{cmd:mapsm}{cmd:,} {opt gr:oup(varname)} [{opt s:eed(numlist)} {opt n:ame(string)} {opt si:ze(numlist)} {opt smd:(varlist)} {opt it:erate(numlist)} {opt replace:} {opt notab:le} {opt log:} {opt ap:pend}]

{marker description}{...}
{title:Description}

{p 10 5 3}
The {cmd:mapsm} command; stands for “Multiple Arms Propensity Score Matching”, matches the propensity scores
 predicted from binary logistic regression (or multinomial logistic regression), which indicates the
 likeliness of choosing or being assigned to one among other treatment arms for each subject. In case
 of two-treatment arms study, the propensity score (probability of 0-1.0) derived from binary logistic
 regression will be divided into 10 strata, 0-0.1, 0.1-0.2 until 0.9-1.0. Study subjects from either
 of the two arms will be sampled to match with the opposite arm within the same propensity score
 strata, with 1:1 ratio.

{p 10 5 3}
In case of three or more arms, the propensity scores will be derived from multinomial logistic 
regression, yielding sets of propensity scores equal to number of arms, indicating the likeliness of 
choosing or being assigned to one among other treatment arms for each subject. Each set of the
 propensity scores will be divided into 10 strata similar to the two-treatment arms. Subjects from
 each arm within the same strata of the propensity score will be sampled to obtain a matched set of
 1:1:1 ratio in case of three arms, and 1:1:1:1 in case of four arms, and so on.

{p 10 5 3}
In order to obtain the most similar post-matched contrast groups, the command also rerun the matching
 process and reported the best post-matched contrast groups which has the best balance diagnostic 
property, such as standardized mean difference. The best seed-setting number (among those selected)
 will be reported in order to re-obtain the best post-matched cohort.

{marker options}{...}
{title:Options}

{p2colset 10 30 31 0}{...}
{p2col:{opt gr:oup(varlist)}} Specify the treatment arms. Must be specify. {p_end}

{p2col:{opt s:eed(numlist)}} Specify the seeding number. Default is 1234. Commonly use to re-specify 
from imaginary matched cohort.{p_end}

{p2col:{opt n:ame(string)}} Specify the strata name. Default is strata. {p_end}

{p2col:{opt si:ze(numlist)}} Specify the strata size. Default is ten.{p_end}

{p2col:{opt smd:(varlist)}} Specify the pre-treatment confounder from propensity score model. Optional.{p_end}

{p2col:{opt it:erate(numlist)}} In case of smd option is specified, the iteration round should be 
determined. Default is 100. {p_end}

{p2col:{opt replace:}} Replace the existing strata variable. Commonly use to overwrite the strata 
variable from imaginary cohort. {p_end}

{p2col:{opt notab:le}} Suppress the strata tabulation across the treament arms. {p_end}

{p2col:{opt log:}} Report the iteration seeding number and the imaginary cohort mean or maximum 
standardized difference. {p_end}

{p2col:{opt ap:pend}} Append the postmatched cohort to the original dataset. Create an {cmd:append} variable to specify the original cohort for balance diagnostic reporting and illustration.{p_end} 
{p2colreset}{...}

{marker examples}{...}
{title:Examples}

{p2colset 10 30 31 0}{...}
{p2col:{opt Two arms: }} {p_end}
{p2colreset}{...}

{p 5 5 3}
Import chocolate cyst example dataset. The surgeon was choosing between the laparoscopic approach 
(MIS) and laparotomy approach (Open) to diagnose, stage, and eradicate the endometrioma.{p_end}

{phang2}{stata `"use https://raw.githubusercontent.com/Suppachai-Lawanaskol/mapsm/main/chocolate_cyst.dta,clear"': Download chocolate_cyst.dta}

{p 5 5 3}
Estimate propensity score with binary logistic regression{p_end}

{phang2}{stata logit optype age wt bmi bilat size: logit optype age wt bmi i.bilat size}

{p 5 5 3}
Predict the probability. (propensity score){p_end}

{phang2}{stata predict pscore: predict pscore}

{p 5 5 3}
Create an imaginary matched cohort and record the seeding number. Report the smallest balance 
diagnostic value and its seeding number. Input the probability variable. Binary treatment groups. 
Specify initiation seeding number to {cmd:1234}. Strata variable name, {cmd:"Block"}. 
Strata size of {cmd:10}. The iteration round of {cmd:200}. The covariates accountable for the 
balance diagnostic are {bf}age, body weight, body mass index, bilaterality, and 
preoperative endometriotic diameter.{sf} Strata tabulation across the treatment groups is suppressed.{p_end}

{phang2}{stata mapsm pscore, group(optype) seed(1234) name(block) size(10) smd(age wt bmi i.bilat size) iterate(200) notab: mapsm pscore, group(optype) seed(1234) name(block) size(10) smd(age wt bmi i.bilat size) iterate(200) notab}

{p 5 5 3}
After the 200 iterations, the mean standardized difference is {cmd:.011}, and the seeding number is {cmd:1301}. 
Now, we are matching. Without {cmd:"notable"} option, Pre-match and post-match cohort tabulations will be shown.

{phang2}{stata mapsm pscore, group(optype) seed(1301) name(block) replace: mapsm pscore, group(optype) seed(1301) name(block) replace}


{p2colset 10 30 31 0}{...}
{p2col:{opt Three arms: }} {p_end}
{p2colreset}{...}

{p 5 5 3}
Import coronary artery bypass grafting example dataset. The surgeon was choosing among the 
conventional coronary artery bypass grafting (CABG),the off-pump CABG (OPCAB), and the on-pump beating heart CABG (ONBHCAB). The study focuses on comparing the short- and long-term outcomes of different CABG techniques.

{phang2}{stata `"use https://raw.githubusercontent.com/Suppachai-Lawanaskol/mapsm/main/cabg.dta,clear"': Download cabg.dta}

{p 5 5 3}
Estimate propensity score with multinomial logistic regression{p_end}

{phang2}{stata mlogit sxtype sex age i.nyfc i.ccs aceiarb asa clopidogrel ckd5esrd i.cadtype lm: mlogit sxtype sex age i.nyfc i.ccs aceiarb asa clopidogrel ckd5esrd i.cadtype lm}

{p 5 5 3}
Predict the probability. (propensity score){p_end}

{phang2}{stata predict cabg opcab onbhcab: predict cabg opcab onbhcab}

{p 5 5 3}
Create an imaginary matched cohort and record the seeding number. Report the smallest balance 
diagnostic value and its seeding number. Input the probability variable. Multiple treatment groups.
Specify the initiation seeding number to {cmd:1234}. Strata variable name is{cmd: "Block"}. 
Strata size of {cmd:10}. The iteration round of {cmd:50}. The covariates accountable for 
the balance diagnostic are {bf}sex, age, New York Heart Association (NYHA) functional class, 
Canadian Cardiovascular Society (CCS) angina grade, ACEI/ARB, aspirin, clopidogrel, 
chronic kidney disease stage V, coronary artery disease type (e.g. single, double, triple vessel disease),
and left main disease.{sf} Strata tabulation across the treatment groups is suppressed.{p_end}

{phang2}{stata mapsm cabg opcab onbhcab, group(sxtype) seed(1234) name(block) size(10) smd(sex age i.nyfc i.ccs aceiarb asa clopidogrel ckd5esrd i.cadtype lm) iterate(50) notab}

{p 5 5 3}
After the 50 iterations, the maximum standardized difference is {cmd:0.0661}, and 
the seeding number is {cmd:1255}. Now, we are matching. Without {cmd:"notable"} option, 
pre-match and post-match cohort tabulations will be shown. With {cmd:replace} option, Stata replace the existing strata variable.{p_end} 

{phang2}{stata mapsm cabg opcab onbhcab, group(sxtype) seed(1255) name(block) size(10) replace: mapsm cabg opcab onbhcab, group(sxtype) seed(1255) name(block) size(10) replace}{p_end}

{p 5 5 3}In actual matching, report the diagnostic balance by adding {cmd: smd} and {cmd: log} options.{p_end}

{phang2}{stata mapsm cabg opcab onbhcab, group(sxtype) smd(sex age i.nyfc i.ccs aceiarb asa clopidogrel ckd5esrd i.cadtype lm) log}{p_end}

{p 5 5 3}In actual matching, we append the original cohort next to the last observation of matched cohort. 
Generate the default name {cmd:append} variable to specify the cohort type. For the next steps of diagnostic balance checking and illustration, use standardized difference command with {cmd:if} condition on the append variable value.{p_end}

{phang2}{stata mapsm cabg opcab onbhcab, group(sxtype) append}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:mapsm} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 15 2: Scalars}{p_end}
{synopt:{cmd:r(seed)}} The best seeding number{p_end}
{synopt:{cmd:r(smallest)}} The smallest diagnostic balance (Mean/Max Standardized difference){p_end}
{synopt:{cmd:r(size)}} Strata size{p_end}


{p2col 5 15 15 2: Macros}{p_end}
{synopt:{cmd:r(strata)}} Strata variable name{p_end}
{synopt:{cmd:r(group)}} Treatment group variable name{p_end}

{p2col 5 15 15 2: Matrix}{p_end}
{synopt:{cmd:r(I)}} Iteration matrix{p_end}


{marker author}{...}
{title:Authors}

{p 5 5 3}
Suppachai Lawanaskol, MD{p_end}
{p 5 5 3}
Chaiprakarn hospital, Chiang Mai, Thailand{p_end}
{p 5 5 3}
Email suppachai.lawanaskol@gmail.com{p_end}

{p 5 5 3}
Phichayut Phinyo, MD, PhD{p_end}
{p 5 5 3}
Center of Clinical Epidemiology and Clinical Statistics, Faculty of Medicine, Chiang Mai University, Chiang Mai, Thailand{p_end}
{p 5 5 3}
Email phichayut.phinyo@gmail.com{p_end}

{p 5 5 3}
Jayanton Patumanond, MD, DSc{p_end}
{p 5 5 3}
Center of Clinical Epidemiology and Clinical Statistics, Faculty of Medicine, Chiang Mai University, Chiang Mai, Thailand{p_end}
{p 5 5 3}
Email jpatumanond@gmail.com{p_end}
