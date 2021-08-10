{smcl}
{* *! version 1.0.0 14Jul2017}
{cmd:help cvcrand}
{hline}

{title:Title}

{p2colset 5 15 15 2}{...}
{p2col :{hi:cvcrand} {hline 2}}Performs covariate constrained randomization
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}


{p 8 17 2}
{cmd:cvcrand} {it:{help varlist}}{cmd:, }{cmd:clusternum(}{it:#}) {cmd:treatmentnum(}{it:#}) [{it:options}]

{synoptset 27 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt :{cmd:clusternum(}{it:#})}specify total number of clusters; must be a positive integer{p_end}
{synopt :{cmd:treatmentnum(}{it:#})}specify number of clusters in treatment arm; must be a positive integer less than {cmd:clusternum}{p_end}

{syntab:Optional}
{synopt :{cmd:clustername(}{it:varname})}variable specifying cluster name{p_end}
{synopt :{cmd:categorical(}{it:{varlist})}}Specify categorical (including binary) variables{p_end}
{synopt :{cmd:balancemetric(}{it:string})}Balance metric to use; choices are L1 and L2; default is L2{p_end}
{synopt :{cmd:cutoff(}{it:#})}Cutoff of distribution of balance scores below which a randomization scheme is sampled; default is 0.1; must be between 0 and 1{p_end}
{synopt :{cmd:numschemes(}{it:#})}Number of schemes to sample; if specified, overrides cutoff; must be a positive integer{p_end}
{synopt :{cmd:nosim}}Enumerate all randomization schemes, regarless of number{p_end}
{synopt :{cmd:size(}{it:#})}number of simulated schemes when simulation is invoked; default is 50,000; must be a positive integer{p_end}
{synopt :{cmd:weights(}{it:numlist})}User-specified weights; seldom used{p_end}
{synopt :{cmd:seed(}{it:#})}Randomization seed; default is 12345{p_end}
{synopt :{cmd:savedata(}{it:string})}Save the constrained randomization space, and an indicator of the final chosen scheme, as a Stata dataset; needed for later analysis{p_end}
{synopt :{cmd:savebscores(}{it:string})}Save the vector of all balance scores (across entire randomization space) as a Stata dataset; produces a histogram of these scores with a red line indicating the cutoff{p_end}

{synoptline}
{p2colreset}{...}

{it:{help varlist}} will contain the baseline cluster-level variables it is wished to constrain on

{marker description}{...}
{title:Description}

{pstd}
{cmd:cvcrand} performs covariate constrained randomization, especially suited for
cluster randomized trials (CRTs) with a small number of clusters (e.g., 20 or fewer).
Constrained randomization is describe in, for example, {help cvcrand##RB2001:Raab and Butcher (2001)} and
{help cvcrand##L2015:Li et al. (2015)}. Covariate constrained randomization is a form of
restricted randomization that can be used to achieve baseline covariate balance in CRTs.

{pstd}
In covariate constrained randomization, a randomization scheme (unique way of assigning clusters to intervention and control) is randomly sampled from a subset of all possible 
randomization schemes based on the value of a balance metric.  To carry out a covariate constrained randomization design, a researcher will 
(i) specify important cluster-level covariates; (ii) either enumerate all or simulate a large number of potential randomization schemes; 
(iii) remove the duplicate randomization schemes if any; (iv) choose a constrained space containing a subset of schemes where sufficient 
balance across covariates is achieved according to some pre-specified balance metric; and (v) randomly sample one randomization scheme from this constrained space. 
This randomly sampled scheme will be used to assign clusters to study arms. Note that cluster-level data supplied for constrained randomization may also be aggregated 
from individual-level data. In practice, however, it is not always possible to obtain individual-level data at the design phase.

{pstd}
In {help cvcrand##RB2001:Raab and Butcher (2001)},
the authors describe a balance metric which is the sum of the weighted squared difference in mean levels
of covariates between the treatment and control arms.  When the weight is defined as the inverse of the
square root of the difference, we call this the L2 balance metric.  When we take the absolute value rather than
squaring the difference, we call this the L1 balance metric.

{pstd}
In the analysis stage, constrained randomization may be followed up by a clustered permutation test.  See the associated analysis
program {help cptest} for more information.

{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{cmd:clusternum(}{it:#}) specifies the total number of clusters to be randomized. This value
must be a positive integer and must be equal to the number of rows in the data set.

{phang}
{cmd:treatmentnum(}{it:#}) specifies the number of clusters that the researcher desires to assign
to the treatment (intervention) arm. It must be a positive integer less than the total
number of clusters. Often, this is equal to half the number of total clusters.

{dlgtab:Optional}
{phang}
{cmd:clustername(}{it:varname}) specifies the name of the variable that is the identification
variable of the cluster. This is used when the program summarizes the variables
after constrained randomization. If no cluster identification variable is specified, the
default is to label the clusters by the order they appear in the data set (i.e., 1, 2,
3,...).

{phang}
{cmd:categorical(}{it:{varlist}}) specifies categorical variables. Each categorical variable will be
turned into {it:p-1} dummy variables, where {it:p} is the number of levels of the categorical
variable. Note that the results are sensitive to which level is excluded. The fvset
command may be used to specify which level to exclude. If the weights option is
used, then all categorical variables must be specified last in {it:varlist} in order for the
program to work correctly.

{phang}
{cmd:balancemetric(}{it:string}) specifies the balance metric to use. The default is the L2 balance
metric. The L1 metric may be specified instead, if desired. These balance metrics are defined in the {bf:Description} section
above.

{phang}
{cmd:cutoff(}{it:#}) specifies the percentile cutoff of the distribution of the balance score below
which we randomly sample the final randomization scheme. The value will range
between 0 and 1. The default is 0.1 (that is, 10%). A smaller balance score indicates
better balance based on our balancing criterion. Therefore, we are "constraining"
the randomization space and only sampling from the set of randomization schemes
corresponding to the "best" values of balance score. The cutoff can be overridden by the {cmd:numschemes} option.

{phang}
{cmd:numschemes(}{it:#}) specifies the number of randomization schemes to form the constrained
space from which the final randomization scheme is selected. This overrides the
cutoff option. If this option is specified, the program will randomly sample the final randomization 
scheme from the randomization schemes corresponding to the {it:S}
smallest balance scores,, as in {cmd:numschemes(}{it:S}).

{phang}
{cmd:nosim} overrides the program's default procedure of simulating when the number of
randomization schemes is over 50,000, and will instead enumerate all randomization
schemes, regardless of the size of the randomization space. Note: this can consume
a lot of memory and may cause Stata to crash. 
For example, with 30 clusters and 15 assigned to treatment, the randomization space
is a 155,117,520 row by 30 column matrix.

{phang}
{cmd:size(}{it:#}) specifies the number of randomization schemes to to simulate if the total randomization
space is greater than 50,000 unique schemes (as happens when, for example, there are 20 clusters and
10 assigned to treatment [20 choose 10 = 184,756]).  The default is to simulate 50,000 schemes.  Simulation
can be overridden by the {cmd:nosim} option.

{phang}
{cmd:weights(}{it:numlist}) allows the specification of user-defined weights.  Note that these weights
could be used to induce stratification on variables. For instance, if one variable is
given a large weight, say 1000, and all other variables are given a weight of 1, the
randomization scheme chosen will be stratified by the variable with the large weight,
assuming a reasonably low cutoff value has been chosen.

{pmore}Weights must be replicated for categorical variables (e.g., a three-category variable must be
given two weights, one for each dummy variable), and categorical variables should be specified first
in {it:{help varlist}} if {cmd:weights} is specified.


{phang}
{cmd:seed(}{it:#}) specifies the seed for simulation and random sampling, needed so that the
randomization can be replicated, if desired.  The default seed is 12345.

{phang}
{cmd:savedata(}{it:string}) saves the constrained randomization space into a Stata data set spec-
ified by string. The data set will be saved into the current working directory, and
will also contain an indicator variable specifying which row of the constrained space
was chosen as the final randomization space. The constrained randomization space
will be needed for the permutation test analysis once the CRT is completed.

{phang}
{cmd:savebscores(}{it:string})} saves the vector of all balance scores (across entire randomization space) as a Stata dataset
specified by {it:string}.  When this option is specified, a histogram is also produced which displays the distribution
of all balance scores with a red line on the graph indicating the selected cutoff{p_end}


{marker example}{...}
{title:Examples}
 
{pstd}The example comes from data published in {help cvcrand##D2015:Dickinson et al. (2015)}  The researchers wished
to randomize 16 counties in Colorado to two different reminder/recall methods (population vs
practice-based) with the goal of increasing up-to-date immunization rates in children.
We will be constraining up a subset of the available baseline cluster-level data.  In addition,
we made a few changes to the data.  The variable indicating percentage of children who had
at least 2 immunization records in the Colorado Immunization Information System was
truncated at 100, and we split income into tertiles (low, middle, high) in order to
illustrate the program's use when a three-level categorical variable is used.  The data can be downloaded from SSC. 

	{hline}
	
	Open data set
{phang2}{cmd:. use Dickinson_Data.dta}
	
	
	Run cvcrand
{phang2}{cmd:. cvcrand inciis uptodate hispanic location incomecat, categorical(location incomecat) clusternum(16) treatmentnum(8) clustername(county) seed(10125) cutoff(0.1) balancemetric(l2) savedata(dickinson_constrained) savebscores(dickinson_bscores)}{p_end}



{marker reference}{...}
{title:Reference}

{marker RB2001}{...}
{phang}
Raab, G.M., &  Butcher, I. (2001) Balance in cluster randomized trials.
{it:Statistics in Medicine}, 20(3), 351-365.
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

