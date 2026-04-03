{smcl}
{* *! version 2.0.0  31mar2026}{...}
{vieweralsosee "[R] midas" "help midas"}{...}
{vieweralsosee "[R] midas metareg" "help midas_metareg"}{...}
{viewerjumpto "Syntax" "midas_subgroup##syntax"}{...}
{viewerjumpto "Description" "midas_subgroup##description"}{...}
{viewerjumpto "Options" "midas_subgroup##options"}{...}
{viewerjumpto "Stored results" "midas_subgroup##results"}{...}
{viewerjumpto "Examples" "midas_subgroup##examples"}{...}

{title:Title}

{phang}
{bf:midas subgroup} {hline 2} Stratified subgroup analysis with comparative SROC for DTA meta-analysis


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:midas subgroup} {it:tp fp fn tn}
{cmd:,} {opt id(varname)} {opt by(varname)}
[{it:options}]

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt id(varname)}}study identifier variable{p_end}
{synopt:{opt by(varname)}}subgroup variable (2{hline 1}10 levels){p_end}

{syntab:Estimation}
{synopt:{opt est:imator(name)}}estimation method; default {cmd:mle}{p_end}
{synopt:}{it:name} is one of {cmd:mle}, {cmd:qrsim}, {cmd:hmc}, or {cmd:inla}{p_end}

{syntab:INLA options (when estimator(inla))}
{synopt:{opt rpath(string)}}full path to {cmd:Rscript} executable{p_end}

{syntab:HMC options (when estimator(hmc))}
{synopt:{opt standir(string)}}path to CmdStan installation{p_end}
{synopt:{opt modelfile(string)}}Stan model filename{p_end}
{synopt:{opt outputfile(string)}}HMC output file prefix{p_end}
{synopt:{opt chains(#)}}number of MCMC chains; default {cmd:4}{p_end}
{synopt:{opt warmup(#)}}warmup iterations per chain; default {cmd:1000}{p_end}
{synopt:{opt iter(#)}}total iterations per chain; default {cmd:10000}{p_end}
{synopt:{opt thin(#)}}thinning interval; default {cmd:10}{p_end}
{synopt:{opt seed(#)}}random seed; default {cmd:12345}{p_end}
{synopt:{opt covariance(name)}}prior covariance family for HMC{p_end}

{syntab:Output}
{synopt:{opt level(#)}}confidence level; default {cmd:95}{p_end}
{synopt:{opt het:stats}}include heterogeneity statistics{p_end}
{synopt:{opt hsroc}}include HSROC parameterization{p_end}
{synopt:{opt nog:raph}}suppress the comparative SROC plot{p_end}
{synopt:{opt save:table(filename)}}save comparison table as LaTeX{p_end}
{synopt:{opt plot:type(name)}}plot type; default {cmd:sroc}{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:midas subgroup} performs stratified subgroup analysis by fitting a
separate bivariate random-effects model within each level of {opt by()}.
It produces:

{phang2}1. A summary comparison table (console + optional LaTeX){p_end}
{phang2}2. A comparative SROC plot with summary operating points, 95%
confidence ellipses (solid lines), and 95% prediction ellipses
(dashed lines) for each subgroup{p_end}
{phang2}3. An embedded summary table in the graph note{p_end}

{pstd}
The confidence ellipses are computed on the logit scale using the
Cholesky decomposition of the fixed-effects variance-covariance
matrix, then mapped to probability space via the inverse logit
transform.  The prediction ellipses add between-study heterogeneity
(tau-squared) to the confidence variance, reflecting the expected
range of a new study.


{marker options}{...}
{title:Options}

{dlgtab:Estimation}

{phang}
{opt estimator(name)} specifies the method for fitting the bivariate
model within each subgroup.  {cmd:mle} (default) uses maximum likelihood
via {cmd:meglm}.  {cmd:qrsim} uses quasi-random simulated likelihood.
{cmd:inla} uses integrated nested Laplace approximation via R-INLA.
{cmd:hmc} uses Hamiltonian Monte Carlo via CmdStan.

{phang}
{opt rpath(string)} specifies the full path to the {cmd:Rscript}
executable.  Required when {cmd:estimator(inla)} is specified.
Example: {cmd:rpath("C:/Program Files/R/R-4.5.2/bin/x64/Rscript.exe")}.

{phang}
{opt standir(string)} specifies the path to the CmdStan installation
directory.  Required when {cmd:estimator(hmc)} is specified.

{phang}
{opt covariance(name)} specifies the prior covariance family for HMC.
Options include {cmd:cholesky}, {cmd:iwishart}, {cmd:spherical}, etc.

{dlgtab:Output}

{phang}
{opt nograph} suppresses the comparative SROC plot.

{phang}
{opt savetable(filename)} saves the subgroup comparison table as a
LaTeX file that can be included in an Overleaf document via
{cmd:\input{c -(}tables/filename{c )-}}.


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:midas subgroup} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(ngroups)}}number of subgroups{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(groups)}}subgroup level values{p_end}
{synopt:{cmd:r(grpnames)}}subgroup label names{p_end}
{synopt:{cmd:r(by)}}name of the subgroup variable{p_end}
{synopt:{cmd:r(estimator)}}estimation method used{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(subgroup)}}k x 7 matrix: N, Se, Sp, LR+, LR-, DOR per group{p_end}


{marker examples}{...}
{title:Examples}

{pstd}Setup:{p_end}
{phang2}{cmd:. use http://fmwww.bc.edu/repec/bocode/m/midas_example_data.dta, clear}{p_end}
{phang2}{cmd:. label define lblblinded 0 "Not blinded" 1 "Blinded"}{p_end}
{phang2}{cmd:. label values blinded lblblinded}{p_end}

{pstd}Subgroup by blinding (MLE):{p_end}
{phang2}{cmd:. midas subgroup tp fp fn tn, id(author) by(blinded) estimator(mle)}{p_end}

{pstd}Subgroup by blinding (INLA, better for small k):{p_end}
{phang2}{cmd:. midas subgroup tp fp fn tn, id(author) by(blinded) estimator(inla) rpath("C:/Program Files/R/R-4.5.2/bin/x64/Rscript.exe")}{p_end}

{pstd}Subgroup by blinding (HMC):{p_end}
{phang2}{cmd:. midas subgroup tp fp fn tn, id(author) by(blinded) estimator(hmc) standir("C:/Users/dwame/.cmdstan/cmdstan-2.38.0") modelfile("midas.stan") outputfile("sg") covariance(cholesky)}{p_end}

{pstd}Save LaTeX table:{p_end}
{phang2}{cmd:. midas subgroup tp fp fn tn, id(author) by(blinded) estimator(mle) savetable(tables/tab_sg_blind.tex)}{p_end}

{hline}

{title:Also see}

{psee}
{helpb midas}, {helpb midas_metareg}, {helpb midas_mle}, {helpb midas_inla}, {helpb midas_hmc}

{title:Author}

{pstd}
Ben Adarkwa Dwamena, MD{break}
University of Michigan / BennyBeauBooks{break}
