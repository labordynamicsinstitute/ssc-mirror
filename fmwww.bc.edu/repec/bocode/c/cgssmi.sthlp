{smcl}
{* *! version 1.0  9 Feb 2023}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "cgssm##syntax"}{...}
{viewerjumpto "Description" "cgssm##description"}{...}
{viewerjumpto "Examples" "cgssm##examples"}{...}
{viewerjumpto "Stored results" "cgssm##results"}{...}
{viewerjumpto "Author and support" "cgssm##author"}{...}
{title:Title}
{phang}
{bf:cgssm} {hline 2} The contrasting groups' standard setting method

{marker syntax}{...}
{title:Syntax}

{pstd}{cmdab:cgssm} for datasets in wide format

{p 8 17 2}{cmdab:cgssm} varlist(min=2 max=2 numeric fv) [{help if}] [{help in}]
[{cmd:,} {it:options}]

{pstd}{cmdab:cgssm} for datasets in long format

{p 8 17 2}{cmdab:cgssm} varlist(min=1) [{help if}] [{help in}]{cmd:,} 
{it:{opt by(varname numeric  fv)}} [{it:options}]

{pstd}Immediate version of {cmdab:cgssm}

{p 8 17 2}{cmdab:cgssmi}{cmd:,} {it:{opt msd:rowmatrix(matrixname)}} [{it:options}]


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:{cmdab:cgssm}, required}

{synopt:{opt by(varname)}}Name for the categorising variable when the data are 
in a long format. Factor variables are allowed. 
{red:Note that the missing values for a factor variable are set to zeroes}

{syntab:{cmdab:cgssmi}, required}

{synopt:{opt msd:rowmatrix(string)}}A 2 by 2 matrix of (mean, sd)-rows as a string. 
First row is the reference group. It can be either as text "m1, sd1 \ m2, sd2" 
or the name of a matrix

{syntab:{cmdab:cgssm} and {cmdab:cgssmi}, optional}

{synopt:{opt r:efname(string)}}Alternative text for the reference group name  

{synopt:{opt c:ompname(string)}}Alternative text for the comparison group name  

{synopt:{opt h:eader(string)}}Alternative text for legend header

{synopt:{opt cpf:ormat(string)}}Format the cut-off in the graph. 
The default is %6.0f

{synopt:{opt pf:ormat(string)}}Format the theoretical false positives and 
the theoretical true negatives in the graph. 
The default is %6.1f

{synopt:{opt g:raph}}Option for drawing a graph. Not necessary if some 
{twoway:twoway} graph options are added

{synopt:{opt *}}Any {twoway:twoway} graph option. Implies that a graph is drawn{p_end}

{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}

{pstd}Establishing a competency standard for when a certain level of expertise 
is reached by identifying cut-off points on different performance measures based 
on rating scores or simulator metrics is an important issue in competency-based 
learning.

{pstd}One method to set such standards, is {bf:the contrasting groups' standard 
setting method}. 
It is a participant-based method where the performance of a certain procedure 
is evaluated between participants of different expertise levels, e.g., novices 
and experts.

{pstd}Using the contrasting groups' method, the cut-off point is set by 
identifying the intercept of two normally distributed curves that represent the 
score distributions of the groups defined by their level of expertise. 
After a pass/fail score is defined, the percentage of false positives and 
negatives can be calculated to explore the consequences of the test.

{pstd}Traditionally, these false positives and false negatives are calculated 
based on the observed number of individuals who passes or fails a test. 
However, validity studies often include only a small number of participants. 
These small numbers make the rate of false positives and false negatives 
sensitive to outliers.

{pstd}Instead, using the normally distributed curves that represent the score 
distributions of the groups defined by their level of expertise, the theoretical 
false negatives, and theoretical false positives can be calculated.

{pstd}What is new in {cmd:cgssm} and {cmd:cgssmi} is that the cut-off is found 
using an exact formula based on solving a polynomial of first or second 
order degree. 


{marker examples}{...}
{title:Examples}

{phang}Suppose that variable bwt is a score and the variable smoke is the 
grouping variable.

{phang}{stata `"webuse lbw"'}{p_end}

{phang}With the mothers smoking during pregnanacy as a reference

{phang}{stata `"cgssm bwt, by(smoke) name(smkref, replace)"'}{p_end}

{phang}With the mothers not smoking during pregnanacy as a reference using a 
factor variable

{phang}{stata `"cgssm bwt, by(0.smoke) refname(non-smoker) compname(smoker) name(nonsmkref, replace)"'}{p_end}

{phang}A typed matrix as argument

{phang}{stata `"cgssmi, msd(50, 10 \ 20, 5) graph"'}{p_end}

{phang}A named matrix as argument

{phang}{stata `"matrix a = 50, 5 \ 40, 5"'}{p_end}

{phang}{stata `"cgssmi, msd(a) g"'}{p_end}


    
{marker results}{...}
{title:Stored results}

{pstd}
{cmd:cgssm} and {cmd:cgssmi} stores the following in {cmd:r()}:
{synoptset 15 tabbed}{...}

{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(fp)}}The theoretical false positive rate.{p_end}
{synopt:{cmd:r(fn)}}The theoretical false negative rate.{p_end}
{synopt:{cmd:r(cutoff)}}The calculated cut-off.{p_end}

{p2col 5 15 19 2: Macros}{p_end}
{synopt:{cmd:r(graph_text)}}If a graph is requested, the code behind the graph.{p_end}

{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:r(meansd)}} A 2 by 2 of the mean's and sd's used for the 
calculations. Top row is the mean and sd for the reference group.{p_end}


{marker author}{...}
{title:Authors and support}

{phang}{bf:Author:}{break}
 	Niels Henrik Bruun, {break}
	Aalborg University Hospital
{p_end}
{phang}{bf:Support:} {break}
	{browse "mailto:niels.henrik.bruun@gmail.com":niels.henrik.bruun@gmail.com}
{p_end}

{title:References}

{phang}Jørgensen, M., Konge, L. & Subhi, Y. {break}
Contrasting groups' standard setting for consequences analysis in validity studies: reporting considerations.{break}
Adv Simul 3, 5 (2018). https://doi.org/10.1186/s41077-018-0064-7
{p_end}