{smcl}
{* *! version 1.0 25June2015}
{cmd:help mint}
{hline}

{title:Title}


{p2colset 3 12 18 12}{...}
{p2col :{hi:mint }{hline 2}}{bf:M}easurement {bf:in}variance {bf:t}est{p_end}
{p2colreset}{...}


{title:Description}

{bf:mint} examines across-groups equivalence of confirmatory factor 
  analysis (CFA) measurement model parameters as well as testing 
  the equality of factor means among groups. The sequence of 
  measurement invariance followed by{bf: mint} is:

1){bf:Equal form} solution has the same form/structure with the same 
  indicators loading on the latent variables for each group. It
  does not impose any equality constraints on the parameters. 

2){bf:Equal loadings} solution constrains the loadings to be equal (+ 
  assumes equal form solution). In other words, it tests whether
  the latent variables have the same meaning for the groups.

3){bf:Equal intercepts} solution constrains the intercepts to be 
  equal (+ assumes equal loadings solution). When the latent 
  means are fixed to be 0, the intercepts represent the means 
  of the indicators. If the loadings and intercepts are both 
  shown to be equal, it would then be unlikely for the latent 
  variables to have different means.

4){bf:Equal error variances} solution constrains the error 
  variances to be equal (+ assumes equal loadings solution). 
  This test does not often support both equal error variances 
  and loadings. Thus, many scholars continue with the equal 
  loading solution.

5){bf:Equal factor variances and covariances} solution constrains 
  the variances and covariances to be equal (+ assumes equal 
  loadings and error variances).  
	 
6){bf:Equal factor means} solution constrains the latent means to 
  be equal (+ assumes equal loadings solution).  
  
  
KW: latent
KW: cfa
KW: measurement
KW: invariance
KW: constraints


{title:Examples}

{phang}{stata "use http://www.stata-press.com/data/r14/sem_2fmmby,clear": . use http://www.stata-press.com/data/r14/sem_2fmmby,clear}{p_end}

{phang}{stata "qui sem (Peer -> peerrel1 peerrel2 peerrel3 peerrel4)(Par -> parrel1 parrel2 parrel3 parrel4), group(grade)": . qui sem (Peer -> peerrel1 peerrel2 peerrel3 peerrel4)(Par -> parrel1 parrel2 parrel3 parrel4), group(grade)}{p_end}
{phang}{stata "mint": . mint}{p_end}

{phang}{stata "qui sem(Appear->appear1 appear2 appear3)(Phy->phyab1 phyab2 phyab3),group(grade)": . qui sem(Appear->appear1 appear2 appear3)(Phy->phyab1 phyab2 phyab3),group(grade)}{p_end}
{phang}{stata "mint": . mint}{p_end}


{title:Author}
Mehmet Mehmetoglu
Department of Psychology
Norwegian University of Science and Technology
mehmetm@svt.ntnu.no


{title:Reference}
Acock, A. C. (2013). Discovering structural equation modeling 
using Stata. College Station, Texas: Stata press.


	

  
