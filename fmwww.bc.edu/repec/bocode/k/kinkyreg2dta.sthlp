{smcl}
{* *! version 1.1.1  16mar2021}{...}
{* *! Sebastian Kripfganz, www.kripfganz.de}{...}
{* *! Jan F. Kiviet, sites.google.com/site/homepagejfk/}{...}
{vieweralsosee "kinkyreg" "help kinkyreg"}{...}
{vieweralsosee "kinkyreg postestimation" "help kinkyreg_postestimation"}{...}
{viewerjumpto "Syntax" "kinkyreg2dta##syntax"}{...}
{viewerjumpto "Description" "kinkyreg2dta##description"}{...}
{viewerjumpto "Options" "kinkyreg2dta##options"}{...}
{viewerjumpto "Remarks" "kinkyreg2dta##remarks"}{...}
{viewerjumpto "Example" "kinkyreg2dta##example"}{...}
{viewerjumpto "Authors" "kinkyreg##authors"}{...}
{title:Title}

{p2colset 5 21 23 2}{...}
{p2col :{bf:kinkyreg2dta} {hline 2}}kinkyreg results to Stata data set{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}{cmd:kinkyreg2dta} {depvar} [{it:{help varlist:varlist1}}] {cmd:(}{it:{help varlist:varlist2}} [{cmd:=} {it:{help varlist:varlist_iv}}]{cmd:)} {ifin} [{cmd:,} {it:options}]

{phang}
{it:varlist1} is a list of exogenous variables.{p_end}

{phang}
{it:varlist2} is a list of endogenous variables.{p_end}

{phang}
{it:varlist_iv} is a list of excluded instrumental variables.{p_end}


{synoptset 29 tabbed}{...}
{synopthdr:options}
{synoptline}
{syntab:Model}
{synopt:{opt r:ange}{cmd:(}{it:{help numlist}}{cmd:)}}admissible range for endogeneity{p_end}
{synopt:{opt step:size}{cmd:(}{it:{help numlist}}{cmd:)}}admissible range for endogeneity{p_end}
{synopt:{it:{help kinkyreg2dta##kinkyreg_options:kinkyreg_options}}}other options for {cmd:kinkyreg} estimation{p_end}

{syntab:Results}
{synopt:{opt coef}{cmd:(}{it:{help kinkyreg2dta##options_spec:coef_spec}}{cmd:)}}specify estimation results to be saved; can be specified more than once{p_end}
{synopt:{opt estat}{cmd:(}{it:{help kinkyreg2dta##options_spec:estat_spec}}{cmd:)}}specify postestimation results to be saved; can be specified more than once{p_end}
{p2coldent :* {opt fr:ame}{cmd:(}{it:{help frame:framename}} [{cmd:, replace}]{cmd:)}}generate data in new frame{p_end}
{p2coldent :* {opt replace}}replace data in current frame{p_end}
{p2coldent :* {opt saving}{cmd:(}{it:{help filename}} [{cmd:, replace}]{cmd:)}}save data to file{p_end}
{synopt:{opt double}}use storage type {cmd:double}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}* At least one of the options {cmd:frame()}, {cmd:replace}, or {cmd:saving()} is required.
Option {cmd:frame()} requires Stata version 16 or higher. Option {cmd:replace} is required under Stata version 15 or lower.{p_end}

{marker options_spec}{...}
{p 4 6 2}
{it:coef_spec} is

{p 8 12 2}
[{cmd:b}] [{cmd:se}] [{cmd:ciub}] [{cmd:cilb}]{cmd::} [{varlist}] [{it:{help numlist}}]

{p 4 6 2}
{it:estat_spec} is

{p 8 12 2}
{it:#} [{cmd:chi2}|{cmd:F}] [{cmd:p}]{cmd::} {it:{help kinkyreg_postestimation##estat:estat_cmdline}}

{p 4 6 2}
See {helpb kinkyreg} for estimation options and {helpb kinkyreg postestimation} for features available after estimation.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:kinkyreg2dta} creates a data set with the KLS estimation and postestimation results that can be used for further analysis and reporting. Multiple endogenous regressors are supported.
{cmd:kinkyreg2dta} neither produces any graphs nor estimation or postestimation output.


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{cmd:range(}{it:#_1} {it:#_2} [{it:#_3} {it:#_4} ...]{cmd:)} requests to compute the KLS estimator for all feasible endogeneity correlations in the joint intervals [{it:#_1} {it:#_2}] for the first endogenous variable in {it:varlist2},
[{it:#_3} {it:#_4}] for the second endogenous variable in {it:varlist2}, and so on. {opt range(#_1 #_2)} with only two elements yields identical intervals for all endogenous variables. The default is {cmd:range(-1 1)}.

{phang}
{cmd:stepsize(}{it:#_1} [{it:#_2} ...]{cmd:)} sets the step size for the intervals over which the KLS estimator is computed. Separate step sizes can be specified for each endogenous variable in the order in which they appear in {it:varlist2}.
{opt stepsize(#_1)} with only one element yields identical step sizes for all endogenous variables. The default is {cmd:stepsize(0.01)}.

{marker kinkyreg_options}{...}
{phang}
{it:kinkyreg_options}: {opt ek:urtosis(#)}, {opt xk:urtosis(#)}, {opt nocons:tant}, {opt l:evel(#)}, {opt sm:all}, and {cmd:lincom(}{it:#}{cmd::} {it:exp}{cmd:)}; see {helpb kinkyreg}.

{dlgtab:Results}

{phang}
{cmd:coef(}[{cmd:b}] [{cmd:se}] [{cmd:ciub}] [{cmd:cilb}]{cmd::} [{varlist}] [{it:{help numlist}}]{cmd:)} specifies the {cmd:kinkyreg} estimation results to be saved.
These can be coefficient estimates ({cmd:b}), standard errors ({cmd:se}), confidence interval upper bounds ({cmd:ciub}), and confidence interval lower bounds ({cmd:cilb}).
The respective results are saved for the coefficients of all variables in {it:varlist} and linear combinations with reference numbers {it:#} in {it:numlist}.
These linear combinations must be specified with the {cmd:kinkyreg} option {cmd:lincom(}{it:#}{cmd::} {it:exp}{cmd:)}; see {helpb kinkyreg}.
If neither {it:varlist} nor {it:numlist} are specified, the results are saved for all endogenous variables in {it:varlist2}. You may specify as many sets of estimation results as you need.

{phang}
{cmd:estat(}{it:#} [{cmd:chi2}|{cmd:F}] [{cmd:p}]{cmd::} {it:{help kinkyreg_postestimation##estat:estat_cmdline}}{cmd:)} specifies the {cmd:kinkyreg} postestimation estimation results to be saved.
These can be the values of the test statistic ({cmd:chi2} or {cmd:F}) and the p-values ({cmd:p}). {it:estat_cmdline} is the full syntax of the {cmd:estat} subcommand, including any options. The word {cmd:estat} is optional.
You may specify as many postestimation results, with different reference number {it:#}, as you need.

{phang}
{cmd:frame(}{it:{help frame:framename}} [{cmd:, replace}]{cmd:)} requests to create a new frame with name {it:framename} in which the new variables are generated. The new frame is made the current frame;
see {helpb frames:[D] frames}. {cmd:replace} specifies that the frame may be replaced if it already exists.

{phang}
{cmd:replace} specifies that the data in memory shall be replaced with the newly generated data, even if the current data have not been saved to disk.

{phang}
{cmd:saving(}{it:{help filename}} [{cmd:, replace}]{cmd:)} requests to save the newly generated data to disk under the name {it:filename}. {cmd:replace} permits to overwrite an existing data set.

{phang}
{opt double} requests to use the storage type {cmd:double} for the variables in the new data set.


{marker remarks}{...}
{title:Remarks}

{pstd}
If multiple endogenous variables are specified in {it:varlist2}, the {cmd:kinkyreg2dta} command calls the {cmd:kinkyreg} command and its postestimation commands in a loop
to obtain estimates for all points on the specified grid of endogeneity correlations. The number of grid points is restricted to the matrix dimension limit of the installed Stata flavor.
Variables in the new data set that identify the correlation values for each grid point are named {cmd:_rho_}{it:varname}, where {it:varname} is the name of an endogenous variable.

{pstd}
Variables for the estimation results requested to be saved with option {cmd:coef()} are named {cmd:_}{it:result}{cmd:_}{it:varname}|{it:#}, where {it:result} is one of {cmd:b}, {cmd:se}, {cmd:ciub}, or {cmd:cilb}.
{it:varname} is the name of a regressor, and {it:#} is a reference number of a linear combination.

{pstd}
Variables for the postestimation results requested to be saved with option {cmd:estat()} are named {cmd:_}{it:test}{cmd:_}{it:#}{cmd:_}{it:result}{cmd:_}{it:coln},
where {it:test} is one of {cmd:test}, {cmd:excl}, {cmd:reset}, {cmd:hett}, or {cmd:dur}, according to the minimum abbreviation of the respective {cmd:estat} subcommand,
and where {it:result} is one of {cmd:chi2}, {cmd:F}, or {cmd:p}. The reference number {it:#} and the column name {it:coln} are used to uniquely identify the postestimation results.


{marker example}{...}
{title:Example}

{pstd}Setup{p_end}
{phang2}. {stata "use http://www.stata-press.com/data/imeus/griliches"}{p_end}

{pstd}Create new frame with KLS estimation and postestimation results{p_end}
{phang2}. {stata "kinkyreg2dta lw s expr tenure rns smsa _I* (iq kww), range(-0.2 0) coef(b se:) estat(1 chi2 p: estat test iq = kww) frame(kinkyreg)"}{p_end}

{pstd}Twoway contour plot for the KLS postestimation test p-values{p_end}
{phang2}. {stata twoway contour _test_1_p_1 _rho_iq _rho_kww, ccuts(0.01 0.05 0.1)}{p_end}

{marker authors}{...}
{title:Authors}

{pstd}
Sebastian Kripfganz, University of Exeter, {browse "http://www.kripfganz.de"}

{pstd}
Jan F. Kiviet, University of Amsterdam, {browse "https://sites.google.com/site/homepagejfk/"}
