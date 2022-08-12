{smcl}
{* *! version 1.00 16june2022}{...}
{viewerjumpto "Syntax" "hmindex##syntax"}{...}
{viewerjumpto ”Description” ”hmindex##description”}{...}
{viewerjumpto ”Options” ”hmindex##options”}{...}
{viewerjumpto ”Stored results” ”hmindex##results”}{...}
{viewerjumpto "Examples" "hmindex##examples"}{...}
{viewerjumpto ”Authors” ”hmindex##authors”}{...}
{title:Title}

{pstd}hmindex{hline 2}Houtman-Maks Index{p_end}
{p2colreset}{...}

{marker syntax}
{title:Syntax}

{p 8 15 2}
{cmd:hmindex}{cmd:,}
{it: price(mname) quantity(mname)} [{it: options}]
{p_end}


{synoptset 26 tabbed}{...}
{synopthdr:options}
{synoptline}

{synopt :{opth ax:iom(hmindex##options:axiom)}}axiom for testing data; default is {bf: axiom(WGARP)} {p_end}

{synopt :{opth dist:ribution(hmindex##options:distribution)}}calculates Houtman-Maks index for every simulated uniformly random data set {p_end}

{synopt :{opth sim:ulations(hmindex##options:simulations)}}number of simulated uniformly random data sets; default is {bf:simulations(1000)} {p_end}

{synopt :{opth seed:(hmindex##options:seed)}}seed in generation of uniformly random data sets; default is {bf:seed(12345)} {p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd: hmindex} calculates the Houtman-Maks Index.

{pstd}
For further details, see {bf: Demetry and Hjertstrand (2022) "Consistent subsets: Computing the Houtman-Maks index in Stata". Mimeo}.

{marker options}{...}
{dlgtab: Options }

{synopt :axiom}  specifies which axiom the user would like to use in testing the data for consistency. The default is {bf: axiom(WGARP)}.
The two axioms that can be tested are WGARP and WARP. To test both axioms at once, specify {bf: axiom(all)} {p_end}

{synopt :distribution} computes the Houtman-Maks index for every simulated uniformly random data set {p_end}

{synopt :simulations} number of simulated uniformly random data sets; default is {bf:simulations(1000)} {p_end}

{synopt :seed} specifies the random seed in generation of uniformly random data sets; default is {bf:seed(12345)} {p_end}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:hmindex} stores the following in {cmd:r()}. Notice that results are suffixed by the {it:axiom} being tested except for results that apply to all axioms, i.e. number of goods and observations, and number of simulations

{synoptset 20 tabbed}{...}
{p2col 5 20 19 2: Scalars}{p_end}
{synopt:{cmd:r(GOODS)}}number of goods in the data{p_end}
{synopt:{cmd:r(OBS)}}number of observations in the data{p_end}
{synopt:{cmd:r(HM_NUM_{it:axiom})}}maximal number of observations in the data satisfying the axiom{p_end}
{synopt:{cmd:r(HM_FRAC_{it:axiom})}}maximal fraction of observations in the data satisfying the axiom (calculated as maximal number of observations satisfying the axiom divided by total number of observations){p_end}
{synopt:{cmd:r(SIM)}}number of simulated uniformly random data sets (if option {it: distribution} is specified) {p_end}

{p2col 5 20 19 2: Macros}{p_end}
{synopt:{cmd:r(AXIOM)}}axiom(s) being tested{p_end}

{p2col 5 20 19 2: Matrices}{p_end}
{synopt:{cmd:r(INDICATOR_{it:axiom})}}T-dimensional binary array indicating whether the observation is in the consistent set (1) or violator set(0){p_end}
{synopt:{cmd:r(OBSDROP_{it:axiom})}}list of observations in the violator set, i.e., what observations that are dropped from the dataset {p_end}
{synopt:{cmd:r(CS_price_{it:axiom})}}price matrix of the data in the consistent set for the specified axiom, i.e., the price data corresponding to the goods in the consistent set {p_end}
{synopt:{cmd:r(CS_quantity_{it:axiom})}}quantity matrix of the data in the consistent set for the specified axiom, i.e., the quantity data corresponding to the goods in the consistent set {p_end}
{synopt:{cmd:r(VS_price_{it:axiom})}}price matrix of the data in the violator set for the specified axiom, i.e., the price data corresponding to the goods in the violator set {p_end}
{synopt:{cmd:r(VS_quantity_{it:axiom})}}quantity matrix of the data in the violator set for the specified axiom, i.e., the quantity data corresponding to the goods in the violator set {p_end}
{synopt:{cmd:r(SUMSTATS_{it:axiom})}}summary statistics over all HM-indices calculated for every simulated uniformly random data set: mean (mean), standard deviation (Std. Dev.), minimum (Min), first quartile (Q1), median (Median), third quartile (Q3), and maximum (Max) {p_end}
{synopt:{cmd:r(SIMRESULTS_{it:axiom})}}HM_NUM and HM_FRAC for every simulated uniformly random data set.{p_end}

{marker examples}{...}
{title:Examples: Loading data and running the command}

{pstd}Install package{p_end}
{phang2}. {stata ssc install hmindex}{p_end}

{pstd}Download example data (from ancillary files){p_end}
{pstd}Note: the file downloads to your current working directory{p_end}
{phang2}. {stata net get hmindex}{p_end}

{pstd}Load example data {p_end}
{phang2}. {stata use hmindex_example_data.dta, clear}{p_end}

{pstd}In the example dataset provided, we have 20 observations of the prices and quantities of two goods.
These have variable names p1 and p2 for prices, and x1 and x2 for quantities.{p_end}

{pstd}In order to use the command, we need to create a matrix for prices
(where each column is a good and each row is an observation).
Likewise, we need to create a matrix for quantities.{p_end}

{pstd}Make matrices P and X from variables{p_end}
{phang2}. {stata mkmat p1 p2, matrix(P)}{p_end}
{phang2}. {stata mkmat x1 x2, matrix(X)}{p_end}

{pstd}We now have two 20x2 matrices; one for prices and one for quantities.{p_end}
{phang2}. {stata matlist P}{p_end}
{phang2}. {stata matlist X}{p_end}

{pstd}Run command with default settings{p_end}
{phang2}. {stata hmindex, price(P) quantity(X)}{p_end}

    Number of obs           =        20 
    Number of goods         =         2 

------------------------------------
       Axiom |       #HM        %HM 
-------------+----------------------
       WGARP |        15        .75 
------------------------------------

This has an approximate runtime of .12 seconds.

{pstd}Run command with WGARP and WARP{p_end}
{phang2}. {stata hmindex, price(P) quantity(X) ax(WGARP WARP)}{p_end}

    Number of obs           =        20 
    Number of goods         =         2 

------------------------------------
       Axiom |       #HM        %HM 
-------------+----------------------
       WGARP |        15        .75 
        WARP |        15        .75 
------------------------------------

{title:Examples: Interpreting the results}

{pstd}The result shows that 5 observations of the original 20 observations in the data need to 
be removed in order for the maximal subset of the data to be consistent with utility maximizing behavior. 
That is, removing the 5 observations gives a data set which satisfies WGARP and WARP. 
Put differently, the consistent set consists of 15 observations, or 75% of the total number of observations. 
The second example shows that this holds irrespective of the axiom being tested.{p_end}

{title:Examples: Visualizing the HM-Index for all subjects in Choi et al. (2007)}

{bf: Data and background}
{pstd}The Choi et al. (2007) data consists of portfolio choice allocations in a two-dimensional setting
from 93 experimental subjects, over 50 decision rounds (T = 50). Each subject split her 
budget between two Arrow-Debreu securities, with each security paying 1 token if the 
corresponding state was realized, and 0 otherwise. The experiment consisted of two treatments.
In the first (symmetric) treatment with 47 subjects, each state of the world occured 
with probability 1/2, which were objectively known to the subjects. The second 
(asymmetric) treatment was applied to 46 subjects, where they faced states occuring with 
probabilities 1/3 and 2/3. All state prices were chosen at random and varied 
across all decision rounds and subjects.{p_end}

{pstd}Here, we show how to calculate the HM-index for every subject from the actual data. In addition to that,
for each subject, we calculate the HM-index in every simulated uniformly random data set.{p_end}

{pstd}From the simulations, we are interested in the mean, minimum, and maximum values of the HM-index, and
how that compares to the HM-index calculated from the actual data.{p_end}

{bf: Code}
{pstd}For the sake of time, we use 10 simulations. See Section 4 in {bf: Demetry and Hjertstrand (2022)} for 
this same exercise but with 1000 simulations.{p_end}

    local subjects = 93
    matrix results = J(`T',4,0)
    matrix colnames results = "HM" "Mean" "Min" "Max"  

    local simulations = 10

    forvalues subject = 1/`subjects' {

        quietly hmindex, price(P`subject') quantity(X`subject') dist sim(`simulations') 

        matrix sumstats = r(SUMSTATS_WGARP)
        
        matrix results[`subject', 1] = r(HM_NUM_WGARP)		/* Actual HM */
        matrix results[`subject', 2] = sumstats[1, 1]		/* Mean */
        matrix results[`subject', 3] = sumstats[3, 1]		/* Min */
        matrix results[`subject', 4] = sumstats[7, 1]		/* Max */

    }

We can inspect this matrix containing the results as follows:
{phang2}. {stata matlist results}{p_end}

However, a more intuitive way to inspect the results may be by visualizing it in a figure. 
The following code replicates Figure 1 in {bf: Demetry and Hjertstrand (2022)}:
 
#delimit ;
twoway rcap Max Min Subject, lstyle(ci) || 
	   scatter HM Subject, msymbol(T) msize(small) mcolor(red) ||
	   scatter Mean Subject, mstyle(p1) msize(vsmall) mcolor(dknavy)
	   ytitle("HM-index") xtitle("Subject")
	   ylabel(20(5)50) xlabel(1 "1" 10(10)90)
       legend(order(2 "Actual HM-index" 3 "Mean HM-index for simulated uniformly random data") rows(2))
       name(rcap, replace) scheme(sj) ;
#delimit cr

{bf: Interpretation}
{pstd}The red-colored triangle markers represent the calculated HM-index for each subject.
Also for each subject, the connected intervals give the maximum and minimum values of the HM-index calculated from 
the simulated uniformly random data, while the black dots give the mean HM-index calculated 
over all simulations.{p_end}

{marker authors}{...}
{title:Authors}

- Marcos Demetry, PhD student at Linnaeus University, Sweden, and affiliated doctoral student at
 the Research Institute of Industrial Economics, Sweden.
- Per Hjertstrand, Associate Professor and Research Fellow at the Research Institute 
of Industrial Economics, Sweden.