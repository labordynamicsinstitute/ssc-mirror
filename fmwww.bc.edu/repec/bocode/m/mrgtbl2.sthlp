{smcl}
{* *! version 1.1 2025-12-31}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "mrgtbl2##syntax"}{...}
{viewerjumpto "Description" "mrgtbl2##description"}{...}
{viewerjumpto "Examples" "mrgtbl2##examples"}{...}
{viewerjumpto "Authors and support" "mrgtbl2##author"}{...}
{title:Title}
{phang}
{bf:mrgtbl2} {hline 2} A margin-based approach to table 2 from a {it:regname} regression

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:mrgtbl2}
[allowed_regression_command (default is mixed)]
[{help if}]
[{cmd:,}
{it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Required }
{synopt:{opt o:utcome(varname)}}Specify the outcome for the report table 2

{synopt:{opt e:xposure(varname)}}Specify the exposure for the report table 2

{syntab:Optional}
{synopt:{opt b:y1(varname)}}Specify the eventual first stratification variable for the report table 2

{synopt:{opt by2(varname)}}Specify the eventual second stratification variable for the report table 2

{synopt:{opt a:djustments(varlist)}}Specify the eventual adjustment variables for the report table 2  

{synopt:{opt c:luster(varname)}}Specify the eventual random intercept variable for the report table 2

{synopt:{opt const:raints(numlist)}}apply specified linear constraints

{synopt:{opt boot:strap(string)}}Specify {help bootstrap: bootstrap} estimation

{synopt:{opt vce(string)}}Specify vce estimation

{synopt:{opt r:egopts(passthru)}}Additional regression options

{synopt:{opt m:rgopts(passthru)}}Additional {help margin:margin} options  

{synopt:{opt btext(string)}}Alternative title for the reported margins

{synopt:{opt roweq(string)}}Add row equation text when possible

{synopt:{opt nol:abel}}Ignore variable and value labels in the report table 2

{synopt:{opt EF:orm}}Report table 2 in exponential form, see {help lincom:lincom}

{synopt:{opt w:ide}}Switch to wide format for the report table 2

{synopt:{opt noq:uietly}}Show the log output for the used regression and margin 
commands

{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}The output from the mrgtbl2 command is based on {help margins:margins} 
from the regression model: outcome = constant + i.exposure[#i.by1][#i.by2] + 
adjustment variables.

{pstd}The user specifies the regression method as one of {help regress:regress}, 
{help cnsreg:cnsreg}, {help mixed:mixed}, {help glm:glm}, {help poisson:poisson}, 
{help nbreg:nbreg}, {help logit:logit}, {help probit:probit}, 
{help cloglog:cloglog}, {help binreg:binreg}, {help meprobit:meprobit}, 
{help melogit:melogit}, {help mepoisson:mepoisson}, {help menbreg:menbreg}, 
{help meglm:meglm}, or {help mecloglog:mecloglog}

{pstd}Margins calculates metrics, such as linear predictions, probabilities, or 
risk differences, based on a fitted model's response over a dataset where 
some or all covariates are fixed at specific values. 
Margins answers the question: "What does my model have to say about such-and-such scenario?" 
The scenario in mrgtbl2 is the standard table 2, including confounding by the 
option adjustments and stratification by the options by1 and by2.

{pstd}There is a conceptual and numerical relationship between the {help margins:margins} 
command and the Mantel–Haenszel method, as both tools are used to adjust for 
confounding factors and provide comparable estimates across stratified groups.

{pstd}In the absence of adjustments and stratifications, the output table is 
applicable for reporting in RCTs.


{marker examples}{...}
{title:Examples}

{phang}Analyzing the effect of whether mothers are smoking on the birthweight
stratified by race and hypertension using the mixed regression command 
(the default), adjusted for age, and with robust variance estimation in wide 
format. A row equation label is added.{p_end}
{phang}{stata `". webuse lbw, clear"'}{p_end}
{phang}{stata `". mrgtbl2, o(bwt) e(smoke) by(race) by2(ht) a(age) vce(robust) roweq(First) w"'}{p_end}
{phang}The same as above, with the report in long format (the default) and the 
Option noquietly to display the regression and margin logging behind the Table 2 report.{p_end}
{phang}{stata `". mrgtbl2, o(bwt) e(smoke) by(race) by2(ht) a(age) vce(robust) noq"'}{p_end}
{phang}The command returns a list of allowed regressions, the applied regression 
command, the applied margins commands, and the Table 2 matrix{p_end}
{phang}{stata `". return list"'}{p_end}
{phang}The estimates of the margins command are stored in _mrgtbl2 for further analysis.
A marginsplot of Table 2 is, for example, easily produced{p_end}
{phang}{stata `". marginsplot, x(race ht) horiz"'}{p_end}
{phang}If the result estimates _mrgtbl2 isn't active, it can be retrieved{p_end}
{phang}{stata `". estimates restore _mrgtbl2"'}{p_end}
{phang}And a list of estimates are found using estimates dir{p_end}
{phang}{stata `". estimates dir"'}{p_end}

{phang}Reporting the risk difference from smoking of giving birth to a child 
with low birthweight based on a logistic regression adjusted for the mother's 
age using bootstrap with 100 replications in the long report format{p_end}
{phang}{stata `". mrgtbl2 logit, o(low) e(smoke) a(age) bootstrap(reps(100) bca nodots) noq"'}{p_end}
{phang}Reporting the risk difference from smoking of giving birth to a child 
with low birthweight based on a probit regression adjusted for the mother's 
age, stratified by race, and using robust variance estimation{p_end}
{phang}{stata `". mrgtbl2 probit, o(low) e(smoke) by(race) a(age) vce(robust)"'}{p_end}
{phang}The same as above, using binreg and stratifying further for the prevalence 
of hypertension{p_end}
{phang}{stata `". mrgtbl2 binreg, o(low) e(smoke) by(race) by2(ht) a(age) vce(robust)"'}{p_end}

{phang}Analyzing the effect of maternal smoking on birthweight using logistic 
regression with robust variance estimation, reporting odds and odds ratios{p_end}
{phang}{stata `". mrgtbl2 logit, o(low) e(smoke) vce(robust) mrgopts(predict(xb)) eform roweq(crd)"'}{p_end}
{phang}Table 2 can be saved for further reporting{p_end}
{phang}{stata `". matrix tbl = r(mrgtbl2)"'}{p_end}
{phang}The same Table 2 as before, but now adjusted for maternal age.{p_end}
{phang}{stata `". mrgtbl2 logit, o(low) e(smoke) a(age) vce(robust) mrgopts(predict(xb)) eform roweq(age adj)"'}{p_end}
{phang}Combining the two Table 2's{p_end}
{phang}{stata `". matrix tbl = tbl \ r(mrgtbl2)"'}{p_end}
{phang}The combined Table 2{p_end}
{phang}{stata `". matlist tbl"'}{p_end}

{phang}Reporting incidence rates and rate differences on the effect of smoking on 
dying using a Poisson regression, adjusting for age groups, and having 
person-years in the exposure option{p_end}
{phang}{stata `". webuse dollhill3, clear"'}{p_end}
{phang}{stata `". mrgtbl2 poisson, o(deaths) e(smokes) a(i.agecat) regopts(exposure(pyears)) mrgopts(predict(ir))"'}{p_end}
{phang}To get the incidence rate ratio of smoking on dying, use the returned 
estimates (estimates _mrgtbl2 is active){p_end}
{phang}{stata `". nlcom (IRR: _b[1.smokes] / _b[0.smokes])"'}{p_end}

{phang}An RCT adjusted for baseline outcome measurements is often modelled as a 
random intercept mixed regression with no baseline treatment effect. 
This can also be reported using the mrgtbl2.{p_end}

{phang}A dataset is simulated for the demonstration. 
The baseline outcome is Gaussian with a mean of 50 and a standard deviation of 3. 
The time effect is 25, the correlation between baseline and follow-up is 0.6, 
and the treatment effect is 5. The standard deviation at follow-up is 2.{p_end}
{phang}{stata `". clear"'}{p_end}
{phang}{stata `". set seed 123"'}{p_end}
{phang}{stata `". set obs 500"'}{p_end}
{phang}{stata `". g id = _n"'}{p_end}
{phang}Generating the baseline and follow-up values of the outcome{p_end}
{phang}{stata `". g y0 = 50 + rnormal(0, 3)"'}{p_end}
{phang}{stata `". g treat = rbinomial(1, 0.5)"'}{p_end}
{phang}{stata `". label define treat 0 "ctrl" 1 "treatment (+5)""'}{p_end}
{phang}{stata `". label values treat treat"'}{p_end}
{phang}{stata `". g y1 = 25 + 0.6 * y0 + 5 * treat + rnormal(0, 2)"'}{p_end}
{phang}Making the dataset long for the mixed random intercept regression{p_end}
{phang}{stata `". reshape long y, i(id treat) j(tm)"'}{p_end}
{phang}{stata `". label define tm 0 "BA" 1 "FU""'}{p_end}
{phang}{stata `". label values tm tm"'}{p_end}
{phang}The constraint is no treatment effect at baseline{p_end}
{phang}{stata `". constraint 1 _b[1.treat#0.tm] = 0"'}{p_end}
{phang}{p_end}
{phang}{stata `". mrgtbl2, o(y) e(treat) by1(tm) constraints(1) cluster(id)"'}{p_end}
{phang}The Stata versions 15.1 and 16.1 can only do the constrained random 
intercept regression using the glm command for this analysis.
The glm command with constraints is around 50-60 times slower than the mixed 
regression command with constraints. {p_end}
{phang}{stata `". mrgtbl2 meglm, o(y) e(treat) by1(tm) constraints(1) cluster(id)"'}{p_end}
{phang}Alternatively, this simplified analysis, based on cnsreg, returns similar but faster results{p_end}
{phang}{stata `". mrgtbl2 cnsreg, o(y) e(treat) by1(tm) constraints(1) vce(cluster id)"'}{p_end}



{title:Stored results}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Locals}{p_end}
{synopt:{cmd:r(poscmds)}} A list of accepted regressions {p_end}
{synopt:{cmd:r(mrgcmd)}} The base margin command {p_end}
{synopt:{cmd:r(regcmd)}} The base regression command {p_end}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:r(mrgtbl2)}} The tabel 2 matrix {p_end}


{marker author}{...}
{title:Authors and support}

{phang}{bf:Author:}{break}
 	Niels Henrik Bruun, {break}
	Aalborg University Hospital
{p_end}
{phang}{bf:Support:} {break}
	{browse "mailto:niels.henrik.bruun@gmail.com":niels.henrik.bruun@gmail.com}
{p_end}
{p}



