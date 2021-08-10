{smcl}
{* *! version 1.0.0 14Jul017}
{cmd:help cptest}
{hline}

{title:Title}

{p2colset 5 15 15 2}{...}
{p2col :{hi:cptest} {hline 2}}Perform clustered permutation test
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}


{p 8 17 2}
{cmd:cptest} {it:{help varlist}}{cmd:, }{cmd:clustername(}{it:{help varname}}) {cmd:directory(}{it:string}) {cmd:outcometype(}{it:integer}) [{cmd:cspacedatname(}{it:string})}]

{synoptset 27 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt :{cmd:clustername(}{it:{help varname}})}variable specifying cluster name{p_end}
{synopt :{cmd:directory(}{it:string})}directory where the constrained randomization space (saved by program {help cvcrand}) Stata dataset is stored{p_end}
{synopt :{cmd:cspacedatname(}{it:string})}name of Stata dataset containing the saved constrained randomization space{p_end}
{synopt :{cmd:outcometype(}{it:string})}specifies the type of regression to run{p_end}

{syntab:Optional}
{synopt :{cmd:categorical(}{it:{varlist}})}Specify categorical (including binary) adjustment variables{p_end}

{synoptline}
{p2colreset}{...}

{it:{help varlist}} is passed to a regression function, and thus should contain an outcome (dependent variable) followed by independent variables

{marker description}{...}
{title:Description}

{pstd}
{cmd:cptest} performs clustered permutation tests after covariate constrained randomization.

{pstd}
After performing covariate constrained randomization to balance cluster-level characteristics in the design of a CRT, an appropriate analysis technique should be selected to analyze the data collected 
during the implementation phase of the CRT.

{pstd}
In a permutation test, the data are first analyzed using an appropriate regression method, and the average cluster-level residuals are saved. From these residuals, we calculate the null 
distribution test statistic by multiplying this vector of residuals by the vector of the selected scheme with -1 substituted for 0. Next, we calculate the permutational distribution by computing 
the value of the test statistic under all possible other allocation schemes in the randomization space.  Under simple randomization, this space consists of all [N choose x] allocation schemes; 
under constrained randomization, the space includes only those allocation schemes where the balance score was below the cutoff (i.e., the space from which the final allocation scheme was chosen).  
The observed (null) test statistic is referenced against  this permutational distribution to obtain a p-value for the intervention effect that accounts for both the clustered design of the CRT 
and the constrained randomization used in selecting the allocation.  For an adjusted permutation test, we simply add as adjustors in the regression model the relevant cluster-level and individual-level 
covariates to obtain an adjusted test statistic.  {help cptest##G1996:Gail et al. (1996)} show that if the number of clusters randomized to intervention is not the same as the number randomized to control, 
the test may be anti-conservative. See {help cptest##G1996:Gail et al. (1996)} for more technical details.   


{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{cmd:clustername(}{it:varname}) specifies the name of the variable that is the identification variable of the cluster.

{phang}
{cmd:directory(}{it:string}) specifies the directory where the constrained randomization space (saved by 
program {help cvcrand}) Stata data set is saved.

{phang}
{cmd:cpsacedat(}{it:string}) gives the name of the dataset containing the saved randomization space.  
This dataset contains the permutation matrix, as well as a variable indicating which row of the permutation matrix was saved as the final scheme.

{phang}
{cmd:outcometype(}{it:string}) specifies the type of regression model that should be run.  
Options are "continuous" for linear regression fit by Stata's program {help regress} command 
(suitable for continuous outcomes) and "binary" for logistic regression fit by 
Stata's  program {help logit} command (suitable for binary outcomes).

{dlgtab:Optional}

{phang}
{cmd:categorical(}{it:{varlist}}) specifies categorical variables.  Categorical variables 
will be turned into {it:p-1} dummy variables, where {it:p} is the number of levels of the categorical variable.  
The user must ensure that the same level of the cateogrical variable is excluded as was excluded when running 
{cmd:cvcrand}, for example by using the {cmd:fvset} command.


{marker example}{...}
{title:Example}
 
{pstd}The example comes from data published in {help cptest##D2015:Dickinson et al. (2015)}  The researchers wished
to randomize 16 counties in Colorado to two different reminder/recall methods (population vs
practice-based) with the goal of increasing up-to-date immunization rates in children.
We will be constraining up a subset of the available baseline cluster-level data.  In addition,
we made a few changes to the data.  The variable indicating percentage of children who had
at least 2 immunization records in the Colorado Immunization Information System was
truncated at 100, and we split income into tertiles (low, middle, high) in order to
illustrate the program's use when a three-level categorical variable is used.  We simulated 
up-to-date immunization outcome data at the individual level for analysis. The data can
be downloaded from SSC.

	{hline}
	Open simulated outcome data
{phang2}{cmd:. use Dickinson_Data_corr_outcome.dta}

	Run cptest
{phang2}{cmd:. cptest outcome inciis uptodate hispanic location incomecat, clustername(county) directory(P:\Program\) cspacedatname(dickinson_constrained) outcometype(Binary) categorical(location incomecat)}{p_end}



{marker reference}{...}
{title:Reference}

{marker G1996}{...}
{phang}
Gail, M. H., Mark, S. D., Carroll, R. J., Green, S. B., & Pee, D. (1996).
On design considerations and randomization-based inference for community intervention trials.
{it:Statistics in Medicine}, 15(11), 1069-1092.
{p_end}

{marker L2015}{...}
{phang}
Li, F., Lokhnygina, Y., Murray, D. M., Heagerty, P. J., & DeLong, E. R. (2015). 
An evaluation of constrained randomization for the design and analysis of group-randomized trials.
{it:Statistics in Medicine}, 35(10), 1565-1579.
{p_end}

{marker D2015}{...}
{phang}
Dickinson, L. M., Beaty, B., Fox, C., Pace, W., Dickinson, W. P., Emsermann, C., Kempe, A. (2015). 
Pragmatic Cluster Randomized Trials Using Covariate Constrained Randomization: A Method for Practice-based Research Networks (PBRNs)
{it:The Journal of the American Board of Family Medicine}, 28(5), 663-672.
{p_end}

{marker author}{...}
{title:Authors}
 John A. Gallis
 Duke University Department of Biostatistics and Bioinformatics
 Duke Global Health Institute
 Durham, NC
 john.gallis@duke.edu
  
 Fan Li
 Duke University Department of Biostatistics and Bioinformatics
 Durham, NC
 frank.li@duke.edu
 
 Hengshi Yu
 University of Michigan Department of Biostatistics
 Ann Arbor, MI
 hengshi@umich.edu

 Elizabeth L. Turner
 Duke University Department of Biostatistics and Bioinformatics
 Duke Global Health Institute
 Durham, NC
 liz.turner@duke.edu
