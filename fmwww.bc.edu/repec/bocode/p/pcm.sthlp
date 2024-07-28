{smcl}
{* 21July2024}{...}
{hline}
help for {hi:pcm}{right:Jean-Benoit Hardouin, Myriam Blanchin}
{hline}

{title:Estimation of the parameters of a Partial Credit Model (PCM) or a Rating Scale Model (RSM) and specific graphs}

{title:Syntax for Rasch analysis}


{p 8 14 2}{cmd:pcm} {it:varlist} [{it:if}] [{it:in}]
[, {cmdab:rsm} {cmdab:it:erate}({it:#})   {cmdab:model}  {cmdab:diff:iculties}({it:matrix}) {cmdab:var:iance}({it:real}) {cmdab:minsize} {cmdab:pca}({it:#}) {cmdab:pcas:im}({it:#}) {cmdab:pcac:entile}({it:#}) 
{cmdab:cont:inuous}({it:varlist}) {cmdab:cat:egorical}({ir:varlist})  
{cmdab:difv:ars}({it:varlist}) {cmdab:difi:tems}({it:matrix})
{cmdab:G:raphs} {cmdab:nographi:tems} {cmdab:dim:name}({it:string}) {cmdab:noobs} {cmdab:nocorr:ected}  {cmdab:nores:iduals} {cmdab:alpha}({it:#}) {cmdab:jit:ter}({it:#}) {cmdab:wccc} 
{cmdab:filesave} {cmdab:extension}({it:string}) {cmdab:dirsave}({it:directory} {cmdab:docx}({it:string}) 
{cmdab:genlt}({it:string}) {cmdab:geninf}({it:string}) {cmdab:rep:lace}

{title:Syntax for Rasch equating}
{p 8 14 2}{cmd:pcm} {it:varlist} [{it:if}] [{it:in}] [, {cmdab:rsm} {cmdab:it:erate}({it:#})   {cmdab:model}  {cmdab:diff:iculties}({it:matrix}) {cmdab:var:iance}({it:real}) {cmdab:minsize}({it:#}) {cmdab:G:raphs}  {cmdab:dim:name}({it:string}) {cmdab:eqset1}({it:varlist}) {cmdab:eqset2}({it:varlist}) {cmdab:eqset1name}({it:string}) {cmdab:eqset2name}({it:string}) {cmdab:EQG:raph} {cmdab:eqaddset1}({it:#}) {cmdab:eqaddset2}({it:#}) {cmdab:eqmultset1}({it:#) {cmdab:eqmultset2}({it:#}) 
{cmdab:eqwithci} {cmdab:eqgenscore}({it:string})  {cmdab:rep:lace}  ]


{p 8 14 2}{it:varlist} is a list of two existing categorical variables or more. The answer categories must be coded by a list of integers begining to 0.

{title:Description}

{p 4 8 2}{cmd:pcm} estimates the parameters of a Partial Credit Model (PCM) or of a Rating Scale Model (RSM).  Parameters are estimated using Marginal Maximum Likelihood (MML). Several graphical representations can be easily obtained: Category Characteristics Curves (CCC), comparison of the observed and theorical Item Characteristic Curves (ICC), Map difficulty parameters/Scores and information function. DIF can be tested using one or two variables. More, {cmd:pcm} allows equating two sets of items.

{title:Options for a Rasch analysis}

{p 4 8 2}{cmdab:rsm} estimates a Rating Scale Model instead of a Partial Credit Model.

{p 4 8 2}{cmdab:it:erate} specifies the maximum number of iterations for the maximization algorithm, which defaults to 100.

{p 4 8 2}{cmd:model} displays the outputs of the maximization alogorithm.

{p 4 8 2}{cmdab:diff:iculties}({it:matrix})  sets the values for the difficulty parameters of the items (these are estimated by default). 
The matrix should have a number of rows equal to the number of items, with a column for each threshold parameter (number of response categories minus one). 
Missing values (.) should be used to indicate non-existent difficulty parameters in the matrix.

{p 4 8 2}{cmdab:var:iance}({it:#}) specifies the variance of the latent trait (default is to estimate this value).

{p 4 8 2}{cmdab:minsize}({it:#}) sets the minimum size for the groups (default is 30 individuals). This value may be automatically adjusted to optimize graph outputs.

{p 4 8 2}{cmdab:pca} performs a Principal Component Analysis (PCA) on standardized residuals.

{p 4 8 2}{cmdab:pcas:sim}({it:#}) performs a Parallel Analysis in which {it:#} sets of simulated data, composed of independent standardized normal variables matching the number of residuals and with a number of individuals equal to the sample size, are analyzed to extract the first eigenvalues of the PCA. A specific percentile of the distribution of the first eigenvalues is displayed. By default, no simulation is performed.

{p 4 8 2}{cmdab:pcac:entile}({it:#}) specifies the percentile of the distribution of the first eigenvalues in the parallel analysis to display. By default, the 95th percentile is shown.

{p 4 8 2}{cmdab:cont:inuous}({it:varlist}) specifies a list of continuous variables that explain the latent trait.

{p 4 8 2}{cmdab:cat:egorical}({it:varlist}) specifies a list of categorical variables that explain the latent trait.

{p 4 8 2}{cmdab:difv:ars}({it:varlist}) identifies one or two categorical variables for testing Differential Item Functioning (DIF) on the items. With one variable, up to four levels can be used. With two variables, only binary variables are allowed.

{p 4 8 2}{cmdab:difi:tems}({it:matrix}) specifies a matrix with rows equal to the number of items and columns equal to the number of DIF variables. The matrix contains 0s (indicating no DIF for the item with the DIF variable) or 1s (indicating DIF for the item with the DIF variable).

{p 4 8 2}{cmdab:G:raphs} displays the graphs.

{p 4 8 2}{cmdab:nographi:tems} suppresses the display of item-specific graphs.

{p 4 8 2}{cmdab:dim:name}({it:string}) specifies the name of the dimension or questionnaire being analyzed (this name will appear on the graphs).

{p 4 8 2}{cmdab:noobs} prevents the display of observed points on Item Characteristics Curves (ICCs).

{p 4 8 2}{cmdab:nocorr:ected} avoids using corrected latent trait estimates (values that best predict the individual scores) on the graphs. Instead, Expected A Posteriori (EAP) estimates are used.

{p 4 8 2}{cmdab:nores:iduals} omits the display of residuals graphs for each item.

{p 4 8 2}{cmdab:jit:ter}({it:#}) perturbs the position of points on residuals graphs to better represent all individuals. 
By default, this parameter is set to 0, which means individuals with the same scores are represented by the same point. 
Increasing this parameter adds more perturbation to the points' locations. The value should be an integer.

{p 4 8 2}{cmdab:alpha}({it:#}) specifies the confidence level for the intervals shown on residuals graphs.

{p 4 8 2}{cmdab:wccc} displays the Weighted Category Characteristics Curves (CCCs). In this case, the CCCs are weighted by the density of the latent trait.

{p 4 8 2}{cmdab:filesave} save the graph files.

{p 4 8 2}{cmdab:extension}({it:string}) specifies the extension of the graph files (default is png).

{p 4 8 2}{cmdab:dirsave}({it:directory} specifies the directory where the graph files and the docx file will be saved.

{p 4 8 2}{cmdab:docx}({it:string}) creates a docx file with the main results and graphs.

{p 4 8 2}{cmdab:genlt}({it:string}) generates several variables. The new variables {it:string} contains Expected A Posteriori estimates of the latent trait and {it:string_se} contains their standard deviations. The variable {it:string_corr} includes estimates of the latent traits that provide the closest match to the item-sum scores. The variable {it:string_ml} contains most likely estimates obtained by optimizing the probability of each observed item response (the value is the mean of all these estimates).

{p 4 8 2}{cmd:geninf}({it:string}) provides information associated with each individual.

{p 4 8 2}{cmdab:rep:lace}  indicates that existing files or variables will be replaced.

{title:Options for a Rasch equating}


{p 4 8 2}{cmdab:rsm} estimates a Rating Scale Model rather than a Partial Credit Model.

{p 4 8 2}{cmdab:it:erate} sets the maximum number of iterations for the maximization algorithm, defaulting to 100.

{p 4 8 2}{cmd:model} displays the output from the maximization algorithm.

{p 4 8 2}{cmdab:diff:iculties}({it:matrix}) specifies the difficulty parameters for the items (default is estimation). 
The matrix should have rows equal to the number of items and columns equal to the number of threshold parameters (number of categories minus one). 
Use a missing value (.) for any non-existent difficulty parameters.

{p 4 8 2}{cmdab:var:iance}({it:#}) sets the variance of the latent trait (default is estimation).

{p 4 8 2}{cmdab:minsize}({it:#}) defines the minimum group size (default is 30 individuals).

{p 4 8 2}{cmdab:G:raphs} displays the graphs.

{p 4 8 2}{cmdab:dim:name}({it:string}) specifies the name of the dimension being analyzed (this name will appear on the graphs).

{p 4 8 2}{cmdab:eqset1}({it:varlist}) and {cmdab:eqset2}({it:varlist}) define two sets of items for equating (which may be disjoint).

{p 4 8 2}{cmdab:eqset1name}({it:string}) and {cmdab:eqset2name}({it:string}) name the two sets of items (default are set1 and set2). Note: if using Stata version 17 or earlier, the string must not contain spaces.

{p 4 8 2}{cmdab:EQG:raph} generates graphs of the equated scores. 

{p 4 8 2}{cmdab:eqaddset1}({it:#}) and {cmdab:eqaddset2}({it:#}) add a constant to the row scores to produce a linearly transformed score for each item set (default is 0).

{p 4 8 2}{cmdab:eqmultset1}({it:#) and {cmdab:eqmultset2}({it:#}) multiply the row scores by a constant to obtain a linearly transformed score for each item set (default is 1).

{p 4 8 2}{cmdab:eqwithci} includes the 95% confidence interval for the equated scores on the graph.

{p 4 8 2}{cmdab:eqgenscore}({it:string}) creates several variables with the mean (_mean_, minimum (_min_), and maximum (_max_) of the 95% confidence interval, plus a random value (_random_) within this interval.

{p 4 8 2}{cmdab:rep:lace} specifies that the existing  files or  variables will be replaced.


{title:Outputs}

{p 4 8 2}{cmd:e()}: Output from the {cmd:gsem} procedure (only if the {cmd:pca} option is not used).

{p 4 8 2}{cmd:r(ll)}: Marginal Log-likelihood.

{p 4 8 2}{cmd:r(PSI)}: Personal Separation Index.

{p 4 8 2}{cmd:r(difficulties)}: Estimates of the threshold parameters.

{p 4 8 2}{cmd:r(matscorelt)}: Estimates of the latent trait associated with each complete response pattern for each item-sum score. 

{p 4 8 2}{cmd:r(matgroupscorelt)}: Estimates of the latent trait for each group of individuals used in graphical fit tests.

{p 4 8 2}{cmd:r(matgroupscoremdlt)}: Estimates of the latent trait for each incomplete response pattern within groups used for graphical fit tests.

{p 4 8 2}{cmd:r(diftest)}: Differential Item Functioning (DIF) tests for each item and DIF variable.

{p 4 8 2}{cmd:r(fit)}: OUTFIT and INFIT indices of each item.

{p 4 8 2}{cmd:r(covariates)}: Estimates of the variance of the latent trait and the parameters associated with covariates (predictors of the latent regression).

{p 4 8 2}{cmd:r(mostlikely)}: Estimates of the latent trait for each response category of each item, derived by maximizing the category characteristic curves (CCC). Unweighted values use the CCC directly, while weighted values adjust the CCC by the density function of the latent trait.

{p 4 8 2}{cmd:r(score2_to_1)}: gives the results to equate the raw scores of the set2 to set1

{p 4 8 2}{cmd:r(score1_to_2)}: gives the results to equate the raw scores of the set1 to set2


{title:Examples of Rasch analysis}

{p 4 8 2}{cmd: . pcm item1-item9} 

{p 4 8 2}{cmd: . pcm item*, graph dirsave(c:\graphs) filesave genlt(lt) docx(report)}

{p 4 8 2}{cmd: . matrix diff=(-1,-0.8,0.2\-.5,0,0.5\0,1,.\0.2,1,1.2\0.5,.,.)}{p_end}
{p 4 8 2}{cmd: . pcm item1-item5 , diff(diff) cat(sex) cont(age) }

{p 4 8 2}{cmd: . matrix dif=(0,1\1,1\0,0\1,0\0,0)}{p_end}
{p 4 8 2}{cmd: . pcm item1-item5 , difitems(dif) difvars(sex age)}

{title:Example of Rasch equating}

{p 4 8 2}{cmd: . pcm item1-item9, eqset1(item1-item5) eqset2(item6-item9) eqnameset1(First part) eqnameset2(Second part) eqaddset1(5) eqmultset1(-1) graph} 


{title:Author}

{p 4 8 2}Jean-Benoit Hardouin, PhD-HDR, Associate professor - Hospital Practitioner{p_end}
{p 4 8 2}Myriam Blanchin, PhD, Research engineer{p_end}
{p 4 8 2}INSERM UMR 1246-SPHERE "Methods in Patients Centered Outcomes and Health Research"{p_end}
{p 4 8 2}Nantes University - Faculty of Medicine{p_end}
{p 4 8 2}Intitute of Research in Health 2{p_end}
{p 4 8 2}22 boulevard Bénoni-Goullin{p_end}
{p 4 8 2}44200 Nantes - FRANCE{p_end}
{p 4 8 2}Email:
{browse "mailto:jean-benoit.hardouin@univ-nantes.fr":jean-benoit.hardouin@univ-nantes.fr}, {browse "mailto:myriam.blanchin@univ-nantes.fr":myriam.blanchin@univ-nantes.fr}{p_end}


{title:Also see}

{p 4 13 2}Online: help for {help raschtest} and {help gsem}  if installed.{p_end}

