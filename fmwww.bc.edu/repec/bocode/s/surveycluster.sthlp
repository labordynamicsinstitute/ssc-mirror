{smcl}
{* *! version 1.0.0  10aug2025}{...}
{viewerdialog surveycluster "dialog surveycluster"}{...}
{vieweralsosee "[SVY] svyset" "mansection SVY svyset"}{...}
{vieweralsosee "[SVY] svydesign" "help svydesign"}{...}
{vieweralsosee "[R] sampsi" "mansection R sampsi"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "clustersampsi" "help clustersampsi"}{...}
{vieweralsosee "[R] sample" "help sample"}{...}
{viewerjumpto "Syntax" "surveycluster##syntax"}{...}
{viewerjumpto "Description" "surveycluster##description"}{...}
{viewerjumpto "Options" "surveycluster##options"}{...}
{viewerjumpto "Examples" "surveycluster##examples"}{...}
{viewerjumpto "Remarks" "surveycluster##remarks"}{...}
{viewerjumpto "Comparison with clustersampsi" "surveycluster##comparison"}{...}
{viewerjumpto "Stored results" "surveycluster##results"}{...}
{viewerjumpto "Authors" "surveycluster##authors"}{...}
{title:Title}

{phang}
{bf:surveycluster} {hline 2} Calculate sample size for cluster-based surveys to achieve desired precision


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:surveycluster}
[{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt co:nfidence(#)}}confidence level as percentage; default is {cmd:confidence(95)}{p_end}
{synopt:{opt mo:e(#)}}margin of error in standard deviations; default is {cmd:moe(0.10)}{p_end}
{synopt:{opt ic:c(#)}}intraclass correlation coefficient; default is {cmd:icc(0.20)}{p_end}
{synopt:{opt cl:uster_size(#)}}average cluster size; default is {cmd:cluster_size(25)}{p_end}
{synopt:{opt pop:ulation(#)}}finite population size for correction; default is infinite{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:surveycluster} calculates the required sample size and number of clusters for
survey designs where the goal is to estimate a population mean with a specified
margin of error (precision). This command is designed for single-arm surveys using
cluster sampling, not for comparing groups or hypothesis testing.

{pstd}
The calculation accounts for the design effect due to clustering and optionally
applies finite population correction when sampling from small populations. The
design effect is calculated as DE = 1 + ICC × (cluster_size - 1).

{pstd}
Unlike {cmd:clustersampsi} (which is designed for cluster randomized controlled
trials), {cmd:surveycluster} focuses on achieving a desired precision for
estimating a single population parameter, making it ideal for survey planning
and monitoring & evaluation studies.


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt confidence(#)} specifies the confidence level as a percentage between 10 and 99.99.
The default is {cmd:confidence(95)} for 95% confidence intervals.

{phang}
{opt moe(#)} specifies the desired margin of error in standard deviations, which must be
between 0 and 1. The default is {cmd:moe(0.10)}, meaning the estimate will be within
±0.10 standard deviations of the true mean. Smaller values require larger sample sizes.

{phang}
{opt icc(#)} specifies the intraclass correlation coefficient, which must be between 0 and 1.
The default is {cmd:icc(0.20)}. This measures how similar observations within the same
cluster are compared to observations in different clusters.

{phang}
{opt cluster_size(#)} specifies the average number of observations per cluster.
The default is {cmd:cluster_size(25)}. This should reflect your actual study design.

{phang}
{opt population(#)} specifies the total population size for finite population correction.
By default, the population is assumed to be infinite. When specified, the command applies
finite population correction, potentially reducing the required sample size.


{marker examples}{...}
{title:Examples}

{pstd}Basic usage with default settings:{p_end}
{phang2}. {stata surveycluster}{p_end}

{pstd}Typical health facility survey (10 patients per clinic):{p_end}
{phang2}. {stata surveycluster, confidence(95) moe(0.15) icc(0.20) cluster_size(10)}{p_end}

{pstd}School-based survey with higher cluster size:{p_end}
{phang2}. {stata surveycluster, conf(90) moe(0.10) icc(0.15) cluster_size(30)}{p_end}

{pstd}Using abbreviated syntax:{p_end}
{phang2}. {stata surveycluster, co(95) mo(0.20) ic(0.10) cl(20)}{p_end}

{pstd}Finite population correction for 200 total clinics:{p_end}
{phang2}. {stata surveycluster, moe(0.20) icc(0.05) cluster_size(15) population(200)}{p_end}

{pstd}Accessing stored results:{p_end}
{phang2}. {stata surveycluster, moe(0.15) icc(0.20)}{p_end}
{phang2}. {stata "* Number of clusters needed:"}{p_end}
{phang2}. {stata di r(clusters)}{p_end}
{phang2}. {stata "* Actual margin of error achieved:"}{p_end}
{phang2}. {stata di %5.3f r(actual_moe)}{p_end}

{pstd}Comparing different scenarios for cost planning:{p_end}
{phang2}. {stata surveycluster, moe(0.10) icc(0.05) cluster_size(10)}{p_end}
{phang2}. {stata local cost1 = r(actual_n) * 50}{p_end}
{phang2}. {stata surveycluster, moe(0.10) icc(0.05) cluster_size(20)}{p_end}
{phang2}. {stata local cost2 = r(actual_n) * 50}{p_end}
{phang2}. {stata "* Cost difference ($):"}{p_end}
{phang2}. {stata di %8.0fc abs(`cost1' - `cost2')}{p_end}


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:surveycluster} is designed for planning surveys where observations are naturally
grouped into clusters, such as patients within clinics, students within schools, or
households within villages. The command calculates sample sizes for estimating a
population mean with specified precision.

{pstd}
{bf:Intraclass Correlation Coefficient (ICC)} measures the similarity of observations within
clusters. Typical values vary by domain:

{phang2}• Health facilities: 0.01-0.10{p_end}
{phang2}• Schools/education: 0.10-0.20{p_end}
{phang2}• Households/neighborhoods: 0.01-0.05{p_end}
{phang2}• Agricultural plots: 0.05-0.30{p_end}

{pstd}
{bf:Design Effect} quantifies the efficiency loss from cluster sampling compared to simple
random sampling. A design effect of 2.0 means you need twice as many observations as you
would with simple random sampling.

{pstd}
{bf:Actual vs. Requested MOE}: Because the number of clusters must be a whole number, the
actual sample size may exceed what's minimally required, resulting in better precision
(smaller margin of error) than requested.

{pstd}
The command issues warnings for unusual parameter combinations but allows them, recognizing
that some study designs may have atypical characteristics.

{pstd}
If the required sample size exceeds the population, the program caps the sample at the population size. In such cases, the final cluster may be incomplete, so num_clusters × cluster_size may be greater than actual_n.


{marker comparison}{...}
{title:Comparison with clustersampsi}

{pstd}
{cmd:surveycluster} and {cmd:clustersampsi} serve different purposes:

{pstd}
{bf:surveycluster} (this command):

{phang2}• For {bf:single-arm surveys} - estimating one population mean{p_end}
{phang2}• Calculates sample size to achieve a specific {bf:precision (margin of error)}{p_end}
{phang2}• No hypothesis testing or group comparisons{p_end}
{phang2}• Simple interface focused on survey design{p_end}
{phang2}• Includes finite population correction{p_end}
{phang2}• Shows actual margin of error achieved{p_end}

{pstd}
{bf:clustersampsi} (Hemming & Marsh):

{phang2}• For {bf:cluster randomized controlled trials} - comparing two groups{p_end}
{phang2}• Calculates power, sample size, or detectable difference between groups{p_end}
{phang2}• Requires specifying two means/proportions/rates to compare{p_end}
{phang2}• Complex options for varying cluster sizes, baseline correlations{p_end}
{phang2}• Designed for clinical trials and intervention studies{p_end}

{pstd}
Choose {cmd:surveycluster} when you want to estimate a population parameter with
desired precision. Choose {cmd:clustersampsi} when you want to test whether two
groups differ significantly.


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:surveycluster} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(n)}}required sample size{p_end}
{synopt:{cmd:r(n_original)}}sample size before finite population correction{p_end}
{synopt:{cmd:r(clusters)}}number of clusters needed{p_end}
{synopt:{cmd:r(actual_n)}}actual total sample size (clusters × cluster_size){p_end}
{synopt:{cmd:r(de)}}design effect{p_end}
{synopt:{cmd:r(confidence)}}confidence level{p_end}
{synopt:{cmd:r(moe)}}requested margin of error{p_end}
{synopt:{cmd:r(actual_moe)}}actual margin of error achieved{p_end}
{synopt:{cmd:r(icc)}}intraclass correlation coefficient{p_end}
{synopt:{cmd:r(cluster_size)}}average cluster size{p_end}
{synopt:{cmd:r(z_value)}}critical z-value used{p_end}
{synopt:{cmd:r(population)}}population size (if specified){p_end}
{synopt:{cmd:r(sampling_fraction)}}proportion of population sampled (if population specified){p_end}
{p2colreset}{...}


{marker authors}{...}
{title:Authors}

{pstd}
Kabira Namit{break}
World Bank{break}
Email: knamit@worldbank.org

{pstd}
Cooper Allton{break}
Program Management and Information Director{break}
Samaritan's Purse{break}



