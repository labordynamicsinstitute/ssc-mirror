{smcl}
{* *! version 1.0.0  31mar2026}{...}
{vieweralsosee "[R] midas" "help midas"}{...}
{vieweralsosee "[R] midas metareg" "help midas_metareg"}{...}
{viewerjumpto "Syntax" "midas_subgroup##syntax"}{...}
{viewerjumpto "Description" "midas_subgroup##description"}{...}
{viewerjumpto "Options" "midas_subgroup##options"}{...}
{viewerjumpto "Stored results" "midas_subgroup##results"}{...}
{viewerjumpto "Examples" "midas_subgroup##examples"}{...}

{title:Title}

{phang}
{bf:midas subgroup} {hline 2} Stratified subgroup analysis for DTA meta-analysis


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:midas subgroup} {it:tp fp fn tn}
{cmd:,} {opt id(varname)} {opt by(varname)}
[{it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt id(varname)}}study identifier variable{p_end}
{synopt:{opt by(varname)}}subgroup variable (2-10 levels){p_end}

{syntab:Estimation}
{synopt:{opt est:imator(string)}}estimation method: {bf:mle} (default), {bf:qrsim}, {bf:hmc}, {bf:inla}{p_end}
{synopt:{opt het:stats}}report heterogeneity statistics per subgroup{p_end}
{synopt:{opt hs:roc}}report HSROC parameters per subgroup{p_end}
{synopt:{opt level(#)}}confidence level; default is 95{p_end}

{syntab:Output}
{synopt:{opt nog:raph}}suppress the SROC overlay plot{p_end}
{synopt:{opt plot:type(string)}}plot type: {bf:sroc} (default){p_end}
{synopt:{opt save:table(filename)}}save comparison table as LaTeX file{p_end}
{synoptline}

{pstd}
Additional options are passed through to the underlying estimator.


{marker description}{...}
{title:Description}

{pstd}
{cmd:midas subgroup} performs a stratified DTA meta-analysis by running
the chosen estimator separately for each level of the {opt by()} variable.
It produces a comparison table showing summary sensitivity, specificity,
likelihood ratios, and diagnostic odds ratio for each subgroup, and
optionally overlays the SROC curves from each subgroup on a single plot.

{pstd}
This command provides a descriptive comparison of subgroups.  For formal
statistical testing of covariate effects, use {helpb midas_metareg:midas metareg}.

{pstd}
Each subgroup must have at least 4 studies for estimation to proceed.
Subgroups with fewer studies are skipped with a warning.


{marker options}{...}
{title:Options}

{phang}
{opt estimator(string)} specifies the MIDAS estimator.  The default is
{bf:mle} (maximum likelihood via {cmd:meglm}).  Other choices are
{bf:qrsim} (quasi-random simulated ML), {bf:hmc} (Hamiltonian MC via CmdStan),
and {bf:inla} (integrated nested Laplace approximation via R-INLA).

{phang}
{opt savetable(filename)} saves the comparison table as a LaTeX file
with {cmd:\toprule}/\{cmd:midrule}/\{cmd:bottomrule} formatting
(requires {cmd:\usepackage{c -(}booktabs{c -)}} in the LaTeX preamble).


{marker results}{...}
{title:Stored results}

{synoptset 25 tabbed}{...}
{p2col 5 25 29 2: Matrices}{p_end}
{synopt:{cmd:r(subgroup)}}k x 7 matrix of subgroup results
(k, Se, Sp, LR+, LR-, DOR, tau2_Se){p_end}

{p2col 5 25 29 2: Scalars}{p_end}
{synopt:{cmd:r(ngroups)}}number of subgroups{p_end}

{p2col 5 25 29 2: Macros}{p_end}
{synopt:{cmd:r(byvar)}}name of the subgroup variable{p_end}
{synopt:{cmd:r(estimator)}}estimation method used{p_end}


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. midas subgroup tp fp fn tn, id(author) by(modality)}{p_end}
{phang2}{cmd:. midas subgroup tp fp fn tn, id(author) by(quality) estimator(qrsim)}{p_end}
{phang2}{cmd:. midas subgroup tp fp fn tn, id(author) by(region) estimator(mle) savetable(tables/tab_sg.tex)}{p_end}


{title:Author}

{pstd}
Ben Adarkwa Dwamena, MD{break}
University of Michigan / BennyBeauBooks{break}
{browse "mailto:ben@bennybeaubooks.com":ben@bennybeaubooks.com}
{p_end}
