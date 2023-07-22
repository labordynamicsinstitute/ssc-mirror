{smcl}
{* 2August2022}{...}
{hline}
help for {hi:pcm}{right:Jean-Benoit Hardouin, Myriam Blanchin}
{hline}

{title:Estimation of the parameters of a Partial Credit Model (PCM) or a Rating Scale Model (RSM) and specific graphs}

{title:Syntax for Rasch analysis}

{p 8 14 2}{cmd:pcm} {it:varlist} [{it:if}] [{it:in}]
[, {cmdab:rsm} {cmdab:it:erate}({it:#})   {cmdab:model}  {cmdab:diff:iculties}({it:matrix}) {cmdab:var:iance}({it:real}) {cmdab:minsize}({it:#})
{cmdab:cont:inuous}({it:varlist}) {cmdab:cat:egorical}({ir:varlist})  
{cmdab:G:raphs} {cmdab:nographi:tems} {cmdab:dim:name}({it:string}) {cmdab:nocorr:ected} {cmdab:alpha}({it:#})
{cmdab:filesave} {cmdab:extension}({it:string}) {cmdab:dirsave}({it:directory} {cmdab:docx}({it:string}) 
{cmdab:genlt}({it:string}) {cmdab:geninf}({it:string}) {cmdab:rep:lace}

{title:Syntax for Rasch equating}
{p 8 14 2}{cmd:pcm} {it:varlist} [{it:if}] [{it:in}] [, {cmdab:rsm} {cmdab:it:erate}({it:#})   {cmdab:model}  {cmdab:diff:iculties}({it:matrix}) {cmdab:var:iance}({it:real}) {cmdab:minsize}({it:#}) {cmdab:G:raphs}  {cmdab:dim:name}({it:string}) {cmdab:eqset1}({it:varlist}) {cmdab:eqset2}({it:varlist}) {cmdab:eqset1name}({it:string}) {cmdab:eqset2name}({it:string}) {cmdab:EQG:raph} {cmdab:eqaddset1}({it:#}) {cmdab:eqaddset2}({it:#}) {cmdab:eqmultset1}({it:#) {cmdab:eqmultset2}({it:#}) {cmdab:eqwithic} {cmdab:eqgenscore}({it:string})  {cmdab:rep:lace}  ]


{p 8 14 2}{it:varlist} is a list of two existing categorical variables or more.

{title:Description}

{p 4 8 2}{cmd:pcm} estimates the parameters of a Partial Credit Model (PCM) or of a Rating Scale Model (RSM).  Parameters are estimated using Marginal Maximum Likelihood (MML). Several graphical representations can be easily obtained: comparison of the observed and theorical Item Characteristic Curves (ICC), Map difficulty parameters/Scores, results of the split tests, and information function (for the scale and by item). {cmd:pcm} allow equating two sets of items.

{title:Options for a Rasch analysis}

{p 4 8 2}{cmdab:rsm} estimates a Rating Scale Model instead of a Partial Credit Model.

{p 4 8 2}{cmdab:it:erate} defines the maximal number of iterations of the maximisation algorithm.
By default, this number is fixed to 100.

{p 4 8 2}{cmd:model} displays the outputs of the maximisation alogorithm .

{p 4 8 2}{cmdab:diff:iculties}({it:matrix}) fixes the values of the difficulties parameters of the items (by default, these values are estimated).
The vector must be a matrix containing as many rows as items, and a column for each threshold parameter (number of answer categories minus 1). 
A missing value (.) replaces unexisting difficulty paremeters in the matrix.

{p 4 8 2}{cmdab:var:iance}({it:#}) fixes the value of the variance of the latent trait (by default, this value is estimated).

{p 4 8 2}{cmdab:minsize}({it:#}) fixes the minimal value of the groups (30 individuals by default).

{p 4 8 2}{cmdab:cont:inuous}({it:varlist}) defines a list of continuous variables explaining the latent trait.

{p 4 8 2}{cmdab:cat:egorical}({it:varlist}) defines a list of categorical variables explaining the latent trait.

{p 4 8 2}{cmdab:G:raphs} displays the graphs.

{p 4 8 2}{cmdab:nographi:tems} avoids displaying the graphs by items.

{p 4 8 2}{cmdab:dim:name}({it:string}) defines the name of the analysed dimension (this name appears on the graphs).

{p 4 8 2}{cmdab:nocorr:ected} avoids using corrected latent trait estimates on the graphs.

{p 4 8 2}{cmdab:alpha}({it:#}) defines the level of confidence of the interval presented on the graphs of residuals.

{p 4 8 2}{cmdab:filesave} save the graph files.

{p 4 8 2}{cmdab:extension}({it:string}) defines the extension of the graph files.

{p 4 8 2}{cmdab:dirsave}({it:directory}  defines the directory to save the graph files and the docx file.

{p 4 8 2}{cmdab:docx}({it:string}) creates a docx file with the main results and graphs.

{p 4 8 2}{cmdab:genlt}({it:string}) creates several variables. The new variables {it:string} contains Expected A Posteriori estimates of the latent trait and {it:string_se} their standard deviations. The new variable {it:string_corr} contains estimates of the latent traits allowing obtaining the closer estimations of the item-sum scores. The new variables {it:string_opt} contains estimated of the latent traits obtained by searching, for each observed item to maximize the probability to obtain the observed answer (the obtained value is the mean of all these estimates).

{p 4 8 2}{cmd:geninf}({it:string}) contains the information associated for each individual.

{p 4 8 2}{cmdab:rep:lace} specifies that the existing  files or  variables will be replaced.

{title:Options for a Rasch equating}


{p 4 8 2}{cmdab:rsm} estimates a Rating Scale Model instead of a Partial Credit Model.

{p 4 8 2}{cmdab:it:erate} defines the maximal number of iterations of the maximisation algorithm.
By default, this number is fixed to 100.

{p 4 8 2}{cmd:model} displays the outputs of the maximisation alogorithm .

{p 4 8 2}{cmdab:diff:iculties}({it:matrix}) fixes the values of the difficulties parameters of the items (by default, these values are estimated).
The vector must be a matrix containing as many rows as items, and a column for each threshold parameter (number of answer categories minus 1). 
A missing value (.) replaces unexisting difficulty paremeters in the matrix.

{p 4 8 2}{cmdab:var:iance}({it:#}) fixes the value of the variance of the latent trait (by default, this value is estimated).

{p 4 8 2}{cmdab:minsize}({it:#}) fixes the minimal value of the groups (30 individuals by default).

{p 4 8 2}{cmdab:G:raphs} displays the graphs.

{p 4 8 2}{cmdab:dim:name}({it:string}) defines the name of the analysed dimension (this name appears on the graphs).

{p 4 8 2}{cmdab:eqset1}({it:varlist}) and {cmdab:eqset2}({it:varlist}) define the items containing in the two sets of items to equate (disjoint or not sets of items)

{p 4 8 2}{cmdab:eqset1name}({it:string}) and {cmdab:eqset2name}({it:string}) define the names of the two sets of items (set1 and set2 by default)

{p 4 8 2}{cmdab:EQG:raph} displays graphs  

{p 4 8 2}{cmdab:eqaddset1}({it:#}) and {cmdab:eqaddset2}({it:#}) allows adding a real to the row score to obtain a linear transformed score for each set of items (0 by default)

{p 4 8 2}{cmdab:eqmultset1}({it:#) and {cmdab:eqmultset2}({it:#}) allows multiplying the row score by a real to obtain a linear transformed score for each set of items (1 by default)

{p 4 8 2}{cmdab:eqwithic} allows representing the 95% confidence interval of the equated score on the graph

{p 4 8 2}{cmdab:eqgenscore}({it:string}) create several variables containing the center (_mean_), the minimal (_min_) and the maximal (_max_) values of the 95% confidence interval and a random value (_random_) drawn in this interval

{p 4 8 2}{cmdab:rep:lace} specifies that the existing  files or  variables will be replaced.


{title:Outputs}

{p 4 8 2}{cmd:e()}: Output of the gsem procedure

{p 4 8 2}{cmd:r(ll)}: Marginal Log-likelihood

{p 4 8 2}{cmd:r(PSI)}: Personal Separation Index

{p 4 8 2}{cmd:r(difficulties)}: Estimates of the threshold parameters

{p 4 8 2}{cmd:r(matscorelt)} : estimates of the latent trait associated to each complete item-sum score 

{p 4 8 2}{cmd:r(matgroupscorelt)} : estimates of the latent trait associated to each complete item-sum score and to each group of individuals used for graphical fit tests 

{p 4 8 2}{cmd:r(covariates)} : estimates of the variance of the latent trait and of the parameters associates to covariates

{p 4 8 2}{cmd:r(bestest)}: estimates of the latent trait obtained for each item by searching the value maximizing the response to each answer category

{p 4 8 2}{cmd:r(score2_to_1)} : gives the results to equate the raw scores of the set2 to set1

{p 4 8 2}{cmd:r(score1_to_2)}: gives the results to equate the raw scores of the set1 to set2



{title:Examples of Rasch analysis}

{p 4 8 2}{cmd: . pcm item1-item9} 

{p 4 8 2}{cmd: . pcm item*, graph dirsave(c:\graphs) filesave genlt(lt) docx(report)}

{p 4 8 2}{cmd: . matrix diff=(-1,-0.8,0.2\-.5,0,0.5\0,1,.\0.2,1,1.2\0.5,.,.)}{p_end}
{p 4 8 2}{cmd: . pcm item1-item5 , diff(diff) cat(sex) cont(age) }

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

