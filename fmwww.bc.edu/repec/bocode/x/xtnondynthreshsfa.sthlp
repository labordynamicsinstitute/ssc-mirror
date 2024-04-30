{smcl}
{* version 1.0.0, 25Apr2024 }{...}
{cmd:help xtnondynthreshsfa}
{hline}

{title:Title}

{pstd}
    {hi: Performs Estimations of Threshold Effects in Non-Dynamic Panel Data Stochastic Frontier Models}
	
	

{title:Syntax}

{pstd}
{cmd:xtnondynthreshsfa}
{depvar}
[{indepvars}] 
{ifin}
{cmd:,} {it:options}



{synoptset 27 tabbed}{...}
{synopthdr}
{synoptline}
{synopt: {it:{help xthreg:xthreg_options}}}all options of the command {bf:{help xthreg}} (if installed) can be used{p_end}
{synopt :{it:{help xtreg:xtreg_fe_options}}}all options of the command {hi:xtreg, fe} ({bf:{manhelp xtreg XT}}) can be used{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
where {depvar} is the dependent variable and {indepvars} are the regime-independent variables. {p_end}



{title:Description}

{pstd}
{cmd:xtnondynthreshsfa} performs estimations of threshold effects in non-dynamic panel data stochastic 
frontier models. This command estimates fixed-effects non-dynamic panel data stochastic frontier models 
with threshold effects. It allows to obtain both single and multiple thresholds estimates alongside the 
slope coefficients. It also tests for the existence of threshold effects. After estimation, the command 
permits to calculate both the time-invariant technical inefficiency and the individual-specific efficiency 
scores. {cmd:xtnondynthreshsfa} is an extension of Wang (The Stata Journal, 2015) {cmd:xthreg} command to 
the world of panel data stochastic frontier models in the presence of threshold effects. The theory behind 
the command {cmd:xtnondynthreshsfa} is provided by Yelou, Larue and Tran (Economic Modelling, 2010).



{title:Important Advice}

{pstd}
The package {bf:xtnondynthreshsfa} rely on the package {bf:xthreg}. 
Hence you must install {bf:xthreg} to make {bf:xtnondynthreshsfa} work. 
To install the package {bf:xthreg} from within {bf:Stata}, please proceed as follows. 
First, connect your computer to the Internet, and second, click on these two lines successively:

{p 4 8 2}{stata `"quietly net from http://www.stata-journal.com/software/sj15-1"'}{p_end}

{p 4 8 2}{stata `"net install st0373, replace"'}{p_end}



{title:Options for xtnondynthreshsfa}

{phang}
{it:{help xthreg:xthreg_options}} all options of the command {bf:{help xthreg}} (if installed) can be 
used. Assuming that you have correctly installed the command {bf:xthreg} by following the instructions 
above, you can view the {it:options} for the command {bf:xthreg} by clicking on: {bf:{help xthreg}}. You 
can form the {it:options} for the command {bf:xtnondynthreshsfa} in exactly the same way as you would do 
with the command {bf:xthreg}. Simply enter them as if you were using the 
command {bf:xthreg}.  Please, see {bf:{help xthreg}} for more details.

{phang}
{it:{help xtreg:xtreg_fe_options}} all options of the command {hi:xtreg, fe} ({bf:{manhelp xtreg XT}}) can 
be used. In addition to the {it:options} of the command {bf:xthreg}, you can use all the {it:options} for 
the command {hi:xtreg, fe}: meaning all options available with the command {hi:xtreg} with the fixed-effects 
estimator option but not the {hi:fe} {it:option} itself. This, because the {hi:fe} {it:option} is already 
internally used by the command  {bf:xtnondynthreshsfa}.  But all the other ones are allowed to be used 
like, for example, the {hi:vce(robust)} {it:option}. The command {hi:xtreg, fe} is already part 
of {hi:Official Stata}, so you do not have to install it. To view the {it:options} of the 
command {hi:xtreg, fe}, please click on: {bf:{manhelp xtreg XT}}. 



{title:Syntax for xtnondynthreshsfacomps}

{p 8 16 2}{cmd:xtnondynthreshsfacomps}
{cmd:,} {cmdab:stub:(}string{cmd:)}



{title:Description for xtnondynthreshsfacomps}

{pstd}
{cmd:xtnondynthreshsfacomps} allows us to calculate both the time-invariant technical inefficiency and 
the individual-specific efficiency scores after we perform the estimations with the command {cmd:xtnondynthreshsfa}. 



{title:Options for xtnondynthreshsfacomps}

{phang}
{opt stub(string)} designates a string name from which new variable names will be 
created. To form this option, you put inside the parentheses a string name (without the 
double quotes). Then new variable names will be created from this string. You must 
specify this option in order to get a result. Hence this option is required.



{title:Warnings}

{pstd}
Since the command {cmd:xtnondynthreshsfa} is based on the command {bf:{help xthreg}}, it requires strongly 
balanced panel data to work. Hence, you need to strongly balance your data before using the 
command {cmd:xtnondynthreshsfa}. If you want to balance your panel data in {hi:Stata}, you can 
use, for example, the following commands, if installed: {bf:{help xtbalance}} and/or {bf:{help xtbalance2}}.  

{pstd}
The command {cmd:xtnondynthreshsfa}, like many panel data threshold effects estimation techniques, is 
highly computationally intensive and may for that reason take a very long time to run on a sluggish machine. 
So, please, be patient when using this command.



{title:Return values for xtnondynthreshsfa}

{pstd}
{cmd:xtnondynthreshsfa} saves the following in {cmd:e()}. The command {cmd:xtnondynthreshsfa} saves all the 
Stored Results returned by the commands {bf:{help xthreg}} and {hi:xtreg, fe} ({bf:{manhelp xtreg XT}}). 
So, I advise you to look at the Stored Results of these two commands to see the descriptions and the 
explanations of all the Stored Results returned by the command {cmd:xtnondynthreshsfa}, please.



{title:Examples}

{p 4 8 2} Before beginning the estimations, we use the {hi:set more off} instruction to tell
{hi:Stata} not to pause when displaying the output. {p_end}

{p 4 8 2}{stata "set more off"}{p_end}

{p 4 8 2} We illustrate the use of the command {cmd:xtnondynthreshsfa} with the dataset {hi:xtnondynthreshsfadata.dta}. This 
dataset contains a sample of strongly balanced panel data for developed and developing countries in the World. It contains 
yearly panel data for 15 years from 2005 to 2019. {p_end}

{p 4 8 2}{stata "use http://fmwww.bc.edu/repec/bocode/x/xtnondynthreshsfadata.dta, clear"}{p_end}

{p 4 8 2} Next we describe the dataset to see the definition of each variable. {p_end}

{p 4 8 2}{stata "describe"}{p_end}

{p 4 8 2} Now, we estimate a single threshold model. We start by writing the name of the 
command {cmd:xtnondynthreshsfa}, followed by the dependent variable {hi:lggdpcstd}. Then, we specify the 
regime-independent variables: {hi:lgcapital} and {hi:lgpoptot}. After that, we indicate the options of 
the command: we specify the regime-dependent variable in {hi:rx(lgnatresrenlev)}, the threshold variable 
in {hi:qx(lgdomcredpslev)}, the number of thresholds in {hi:thnum(1)} (one threshold in this case), the 
trimming proportion to estimate each threshold in {hi:trim(0.01)}, the number of grid points 
in {hi:grid(400)} and the number of bootstrap replications in {hi:bs(300)}. Please, see the help 
file of the command {bf:{help xthreg}} for further details on how to specify the regressions. {p_end}

{p 4 8 2}{stata "xtnondynthreshsfa lggdpcstd lgcapital lgpoptot, rx(lgnatresrenlev) qx(lgdomcredpslev) thnum(1) trim(0.01) grid(400) bs(300)"}{p_end}

{p 4 8 2} Let us interpret the results we just found in this estimation. As explained in Wang (2015), page 131, the 
results given by the command {cmd:xtnondynthreshsfa} are composed of four parts. The first part gives the estimation 
and bootstrap results. The second part provides the threshold estimators and their confidence intervals. {hi:Th-1} 
represents the estimator in single threshold models. The third part presents the threshold effect test, including 
the {hi:RSS}, the mean squared error {hi:(MSE)}, the F statistic {hi:(Fstat)}, the probability value of 
the F statistic {hi:(Prob)}, and critical values at 10%, 5%, and 1% significance 
levels ({hi:Crit10}, {hi:Crit5}, and {hi:Crit1}, respectively). The fourth part exhibits the 
fixed-effect regression. {p_end}

{p 4 8 2} Thus, in this estimation, we see that the single threshold is equal to {hi:22.8782}. This threshold is 
statistically significant because {hi:0} ({hi:zero}) is not included in its 95% confidence interval. Remember that 
this threshold corresponds to the variable {it:Log of Domestic Credit Private Sector Constant 2015 USD}, 
meaning {it:financial development}. In this estimation, we also see that the threshold effect exists since 
the probability value of the F statistic {hi:(Prob)} is significant at the 5% statistical significance 
level. In this estimation, we finally see that the Fixed-effects (within) regression shows that the 
coefficients of capital ({it:Log of Physical Capital Stock Constant 2015 USD}) and 
labor ({it:Log of Population Total}) are positive and statistically significant at 
the 1% significance level. The next two coefficients are for the 
interaction {it:_cat#c.lgnatresrenlev}. They show that below the threshold 
of {hi:22.8782} for {it:financial development}, the 
variable {it:Log of Total Natural Resources Rents Constant 2015 USD} has a positive and 
significant impact on the {it:Log of GDP Constant 2015 USD}. We also see that above the 
threshold of {hi:22.8782} for {it:financial development}, the 
variable {it:Log of Total Natural Resources Rents Constant 2015 USD} has a positive and significant impact 
on the {it:Log of GDP Constant 2015 USD}. Both of these impacts are significant at the 1% significance 
level. But the magnitude of the impact above the threshold is bigger than that below the threshold. {p_end}

{p 4 8 2} Next, we demonstrate how to utilize 
an {hi:xtreg, fe} option (please, see the help file of the command {bf:{manhelp xtreg XT}}). In particular 
the {hi:vce(robust)} option. {p_end}

{p 4 8 2}{stata "xtnondynthreshsfa lggdpcstd lgcapital lgpoptot, rx(lgnatresrenlev) qx(lgdomcredpslev) thnum(1) trim(0.01) grid(400) bs(300) vce(robust)"}{p_end}

{p 4 8 2} In the following line, we estimate a triple threshold model directly. {p_end}

{p 4 8 2}{stata "xtnondynthreshsfa lggdpcstd lgcapital lgpoptot, rx(lgnatresrenlev) qx(lgdomcredpslev) thnum(3) trim(0.01 0.01 0.05) bs(300 300 300) vce(robust)"}{p_end}

{p 4 8 2} The probability value of the F statistic {hi:(Prob)} shows us that there exists a single threshold but 
there does not exist a double and triple threshold for our sample of data that we are using in 
this {hi:Examples} section. Hence, in the subsequent regressions, we will stick to the single threshold model. {p_end}

{p 4 8 2} Now, we illustrate how to calculate both the time-invariant technical inefficiency and 
the individual-specific efficiency scores. First, we run the following regression.  {p_end}

{p 4 8 2}{stata "xtnondynthreshsfa lggdpcstd lgcapital lgpoptot, rx(lgnatresrenlev) qx(lgdomcredpslev) thnum(1) trim(0.01) grid(400) bs(300)"}{p_end}

{p 4 8 2} Second, we use the command {cmd:xtnondynthreshsfacomps} to compute the both the time-invariant technical 
inefficiency and the individual-specific efficiency scores. In this command, we put the string {hi:mesc} without 
the double quotes in the option {cmd:stub()}. {p_end}

{p 4 8 2}{stata "xtnondynthreshsfacomps, stub(mesc)"}{p_end}

{p 4 8 2} We describe all the previously created variables to see their labels. {p_end}

{p 4 8 2}{stata "describe Inefficiency_mesc Efficiency_mesc"}{p_end}

{p 4 8 2} We summarize these variables. {p_end}

{p 4 8 2}{stata "summarize Inefficiency_mesc Efficiency_mesc"}{p_end}

{p 4 8 2} We observe that, estimated average inefficiency is 152.09% and estimated average efficiency is 27.81%. Keep in 
mind that, by construction, one country is 100% efficient and therefore efficiency scores are dependent 
to dropping or adding outlier countries. {p_end}

{p 4 8 2} Third, we plot a histogram of the efficiency scores. {p_end}

{p 4 8 2}{stata "histogram Efficiency_mesc, bin(100) normal"}{p_end}

{p 4 8 2} We notice that, we have a right-skewed or positively-skewed distribution for the efficiency 
scores. Hence, the mean efficiency is greater than the median efficiency scores. {p_end}

{p 4 8 2} Fourth, we only keep the World Bank codes, the countries and the efficiency scores. {p_end}

{p 4 8 2}{stata "keep pbm lbpbm Efficiency_mesc"}{p_end}

{p 4 8 2} Fifth, we keep only the first observation in each country. {p_end}

{p 4 8 2}{stata "bysort pbm lbpbm: keep if _n == 1"}{p_end}

{p 4 8 2} Sixth, we sort by descending order of the efficiency sores and by ascending order of the World Bank codes and 
the countries. {p_end}

{p 4 8 2}{stata "gsort -Efficiency_mesc pbm lbpbm"}{p_end}

{p 4 8 2} Seventh, we list the World Bank codes, the countries and the efficiency sores from the most efficient 
country and the least efficient country in our dataset. {p_end}

{p 4 8 2}{stata "list pbm lbpbm Efficiency_mesc, separator(0)"}{p_end}

{p 4 8 2} We see that the classification of the efficiency scores is, generally, plausible and close to what 
is expected, with developed countries or developed administrative areas ranked first, followed by developing 
countries ranked second. {p_end}

{p 4 8 2} Now, we show how to plot the confidence interval using the likelihood-ratio (LR) statistics. We start, by 
reloading our examples dataset we described above. {p_end}

{p 4 8 2}{stata "use http://fmwww.bc.edu/repec/bocode/x/xtnondynthreshsfadata.dta, clear"}{p_end}

{p 4 8 2} Then, we run the following regression.  {p_end}

{p 4 8 2}{stata "xtnondynthreshsfa lggdpcstd lgcapital lgpoptot, rx(lgnatresrenlev) qx(lgdomcredpslev) thnum(1) trim(0.01) grid(400) bs(300)"}{p_end}

{p 4 8 2} Finally, we use the {hi:Stata} command {bf:{help _matplot}} to plot the confidence interval using the 
likelihood-ratio (LR) statistics stored in {hi:e(LR)} for the single threshold model. The quantile for which 
we plot the confidence interval is equal to {hi:7.35} corresponding to the 5% critical value in this 
regression. These quantiles are tabulated by Hansen (1999) and Wang (2015). Please, see these references and 
the help file of the command {bf:{help _matplot}} for further details. {p_end}

{p 4 8 2}{stata `"_matplot e(LR), columns(1 2) yline(7.35, lpattern(dash)) connect(direct) msize(small) mlabp(0) mlabs(zero) ytitle("LR Statistics") xtitle("First Threshold") recast(line)"'}{p_end}

{p 4 8 2} The graphic indicates the confidence interval construction for the single threshold model. In this 
graphic, the blue curve represents the likelihood-ratio (LR) statistics. The red dashed horizontal line 
represents the quantile {hi:7.35}. The intersection of the two curves in this graphic correspond to the 
confidence interval. The point at which the blue curve touches the x-axis corresponds to the estimated 
threshold parameter. {p_end}

{p 4 8 2} Let us explain how to use the {cmd:xtnondynthreshsfa} command with the {bf:{manhelp if U}} 
qualifier. We run the regressions for {it:year >= 2006}. {p_end}

{p 4 8 2}{stata "xtnondynthreshsfa lggdpcstd lgcapital lgpoptot if year >= 2006 , rx(lgnatresrenlev) qx(lgdomcredpslev) thnum(1) trim(0.01) grid(400) bs(300)"}{p_end}

{p 4 8 2} To finish this {hi:Examples} section, we now illustrate how to include a {it:Time Trend} when using the 
command {cmd:xtnondynthreshsfa}. For this, we include the variable {hi:trend} in our usual Cobb-Douglas production 
function with threshold effects specification. {p_end}

{p 4 8 2}{stata "xtnondynthreshsfa lggdpcstd lgcapital lgpoptot trend, rx(lgnatresrenlev) qx(lgdomcredpslev) thnum(1) trim(0.01) grid(400) bs(300) vce(robust)"}{p_end}

{p 4 8 2} The coefficient of the variable {hi:trend} {it:(0.0100663)} indicates that total factor 
productivity (meaning, GDP for a given level of capital and labor) has augmented in real 
terms by 1% annually, on average, through all countries in the period 2005-2019. {p_end}

{p 4 8 2} {hi:EPILOGUE} {p_end}

{p 4 8 2} In writing this {hi:Examples} section, we had two goals. The first, was to show how to 
effectively use the command {cmd:xtnondynthreshsfa} through simple and clear examples. The second, was to 
undertake an original study on stochastic frontier models with threshold effects for panel data and 
contribute to this literature. But, despite our efforts, we have only scratched the surface of what can be 
done with the commands {cmd:xtnondynthreshsfa} and {cmd:xtnondynthreshsfacomps}, the accompanying 
dataset, and the use of the command {cmd:xtnondynthreshsfa} in conjunction with 
other {hi:Stata} commands. We leave these avenues of research to the reader/user to explore 
at her/his will !  {p_end}



{title:References}

{pstd}
{hi:Hansen Bruce E.: 1999,} "Threshold Effects in Non-Dynamic Panels: Estimation, Testing, and Inference", {it:Journal of Econometrics} {bf:93}(2), 345-368.
{p_end}

{pstd}
{hi:Wang Qunyong: 2015,} "Fixed-Effect Panel Threshold Model using Stata", {it:The Stata Journal} {bf:15}(1), 121-134.
{p_end}

{pstd}
{hi:Yelou Clement, Larue Bruno and Tran Kien C.: 2010,} "Threshold Effects in Panel Data Stochastic Frontier Models of Dairy Production in Canada", {it:Economic Modelling} {bf:27}(3), 641-647.
{p_end}



{title:Citation}

{pstd}
The commands {cmd:xtnondynthreshsfa} and {cmd:xtnondynthreshsfacomps} are not {hi:Official Stata} 
commands. Like a paper, they are a free contribution to the research community. If you find the 
commands {cmd:xtnondynthreshsfa} and {cmd:xtnondynthreshsfacomps} and their accompanying dataset 
useful and utilize them in your works, please cite them like a paper as it is explained in 
the {hi:Suggested Citation} section of the {hi:IDEAS/RePEc} {it:webpage} of the 
commands. Please, also cite {hi:Hansen (1999)}, {hi:Wang (2015)} and {hi:Yelou, Larue and Tran (2010)} in your 
works.{it:Thank you infinitely, in advance, for doing all these gestures!} Please, note that citing these 
commands and these references are a good way to disseminate their use and their discovery by other 
researchers and analysts. Doing these actions, could also, potentially, help us, as a community, to solve 
challenging current problems and those that lie ahead in the future.



{title:Acknowledgements}

{pstd}
I thank Bruce E. Hansen; Qunyong Wang; Clement Yelou, Bruno Larue and Kien C. Tran; and StataCorp LLC for writing 
and making their programs, data and articles available through official and commercial 
channels. This current {hi:Stata} package is based and inspired by their works. The usual disclaimers 
apply: all errors and imperfections in this package are mine and all comments are very welcome.



{title:Author}

{p 4}Diallo Ibrahima Amadou {p_end}
{p 4 4}FERDI (Fondation pour les Etudes et Recherches sur le Developpement International) {p_end}
{p 4}63 Boulevard Francois Mitterrand  {p_end}
{p 4}63000 Clermont-Ferrand   {p_end}
{p 4}France {p_end}
{p 4}{hi:E-Mail}: {browse "mailto:zavren@gmail.com":zavren@gmail.com} {p_end}



{title:Also see}

{psee}
Online: help for {bf:{manhelp xtreg XT}}, {bf:{manhelp xtfrontier XT}}, {bf:{help _matplot}}, 
{bf:{help xthreg}} (if installed), {bf:{help xtendothresdpd}} (if installed), {bf:{help xthenreg}} (if installed), 
{bf:{help xtbalance}} (if installed), {bf:{help xtbalance2}} (if installed)
{p_end}


