{smcl}
{* *! version 2.1.0 09mar2026}{...}
{viewerjumpto "Syntax" "stanrun##syntax"}{...}
{viewerjumpto "Description" "stanrun##description"}{...}
{viewerjumpto "Options" "stanrun##options"}{...}
{viewerjumpto "Variational Inference" "stanrun##vi"}{...}
{viewerjumpto "Examples" "stanrun##examples"}{...}
{viewerjumpto "Companion programs" "stanrun##companion"}{...}
{viewerjumpto "Stored results" "stanrun##results"}{...}
{viewerjumpto "References" "stanrun##references"}{...}
{title:Title}

{phang}
{bf:stanrun} {hline 2} Run Bayesian models via CmdStan with HMC/NUTS and Variational Inference

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:stanrun}
{varlist}
{ifin}
[{cmd:,} {it:options}]

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt model:file(filename)}}Stan model file (must end in .stan){p_end}

{syntab:File Specifications}
{synopt:{opt data:file(filename)}}data file name; default {bf:stanrun_data.R}{p_end}
{synopt:{opt output:file(basename)}}output CSV base name; default {bf:output}{p_end}
{synopt:{opt chain:file(filename)}}combined chains file; default {bf:stanrun_chains.csv}{p_end}
{synopt:{opt inits:file(filename)}}initial values file{p_end}
{synopt:{opt cmdstandir(path)}}path to CmdStan installation{p_end}

{syntab:Model Specification}
{synopt:{opt inline}}read Stan model from comment block in do-file{p_end}
{synopt:{opt thisfile(path)}}path to do-file with inline model{p_end}
{synopt:{opt rerun}}skip compilation, use existing executable{p_end}

{syntab:MCMC Sampling}
{synopt:{opt chains(#)}}number of chains; default {bf:4}{p_end}
{synopt:{opt warmup(#)}}warmup iterations; default {bf:1000}{p_end}
{synopt:{opt iter(#)}}sampling iterations; default {bf:1000}{p_end}
{synopt:{opt thin(#)}}thinning interval; default {bf:1}{p_end}
{synopt:{opt seed(#)}}random seed{p_end}

{syntab:HMC Tuning}
{synopt:{opt stepsize(#)}}HMC step size{p_end}
{synopt:{opt stepsizejitter(#)}}step size jitter; default {bf:0}{p_end}
{synopt:{opt adaptdelta(#)}}target acceptance rate (0-1){p_end}
{synopt:{opt maxtreedepth(#)}}maximum NUTS tree depth{p_end}

{syntab:Variational Inference}
{synopt:{opt var:iational}}use ADVI instead of MCMC{p_end}
{synopt:{opt vialgorithm(string)}}{bf:meanfield} (default) or {bf:fullrank}{p_end}
{synopt:{opt viiter(#)}}max VI iterations; default {bf:10000}{p_end}
{synopt:{opt vioutput_samples(#)}}posterior draws from VI; default {bf:1000}{p_end}
{synopt:{opt vieta(#)}}step size for VI; default auto{p_end}
{synopt:{opt vitol_rel_obj(#)}}convergence tolerance; default {bf:0.01}{p_end}

{syntab:Operations}
{synopt:{opt load}}import posterior draws into Stata{p_end}
{synopt:{opt diagnose}}run basic convergence diagnostics{p_end}
{synopt:{opt mode}}find posterior mode via optimization{p_end}

{syntab:Data Handling}
{synopt:{opt skip:missing}}variable-wise missing deletion{p_end}
{synopt:{opt mat:rices(list|all)}}pass Stata matrices to Stan{p_end}
{synopt:{opt globals(list|all)}}pass global macros to Stan{p_end}

{syntab:Display}
{synopt:{opt verbose}}detailed execution output{p_end}
{synopt:{opt log}}synonym for {cmd:verbose}{p_end}
{synopt:{opt nopywarn}}suppress Python integration note{p_end}
{synopt:{opt keep:files}}preserve intermediate files{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:stanrun} is a modern interface to CmdStan for running Bayesian models in Stata.
It supports both full MCMC via Hamiltonian Monte Carlo (HMC) with the No-U-Turn
Sampler (NUTS), and fast approximate inference via Automatic Differentiation
Variational Inference (ADVI).

{pstd}
Key features include:

{phang2}{bf:-} Synchronous shell execution (reliable on StataNow 19.5){p_end}
{phang2}{bf:-} Automatic RTools detection (4.2-4.5) for compilation{p_end}
{phang2}{bf:-} Skip recompilation when executable exists{p_end}
{phang2}{bf:-} CmdStan CSV import with automatic variable renaming{p_end}
{phang2}{bf:-} Variational Inference (ADVI) for fast approximate posteriors{p_end}
{phang2}{bf:-} Quiet mode by default; verbose CmdStan output with {cmd:verbose}{p_end}
{phang2}{bf:-} Divergent transition and tree depth diagnostics{p_end}

{pstd}
Requires CmdStan 2.26+ and RTools (Windows). Tested with CmdStan 2.38 and
StataNow 19.5 MP on Windows.

{marker options}{...}
{title:Options}

{dlgtab:File Specifications}

{phang}
{opt modelfile(filename)} specifies the Stan model file. Must end in {bf:.stan}.
The executable is derived from this name (e.g. {bf:mymodel.stan} -> {bf:mymodel.exe}).

{phang}
{opt cmdstandir(path)} specifies the path to CmdStan. If omitted, the global
macro {bf:$CMDSTAN} is used. Example: {cmd:cmdstandir("C:\Users\me\.cmdstan\cmdstan-2.38.0")}.

{phang}
{opt outputfile(basename)} base name for chain CSV files. With 4 chains, creates
{it:basename}1.csv through {it:basename}4.csv. Default is {bf:output}.

{dlgtab:MCMC Sampling}

{phang}
{opt chains(#)} number of MCMC chains. Default is {bf:4}. Chains run sequentially.

{phang}
{opt warmup(#)} warmup (burn-in) iterations per chain. Default is {bf:1000}.

{phang}
{opt iter(#)} post-warmup sampling iterations per chain. Default is {bf:1000}.

{phang}
{opt thin(#)} thinning interval. Default is {bf:1} (keep all samples).

{phang}
{opt seed(#)} random number seed for reproducibility.

{dlgtab:HMC Tuning}

{phang}
{opt adaptdelta(#)} target acceptance rate (0-1). Default is {bf:0.8}. Increase
to 0.95 or 0.99 if you see divergent transitions.

{phang}
{opt maxtreedepth(#)} maximum NUTS tree depth. Default is {bf:10}. Increase if
sampling hits the tree depth limit.

{marker vi}{...}
{dlgtab:Variational Inference}

{phang}
{opt variational} uses Automatic Differentiation Variational Inference (ADVI)
instead of HMC/NUTS. This is much faster but provides approximate posteriors.
ADVI fits a Gaussian approximation to the posterior; the quality of this
approximation depends on the model.

{phang}
{opt vialgorithm(string)} specifies {bf:meanfield} (default; diagonal covariance)
or {bf:fullrank} (dense covariance). Fullrank captures correlations but is slower
and may not converge for high-dimensional models.

{phang}
{opt viiter(#)} maximum iterations for VI optimization. Default is {bf:10000}.

{phang}
{opt vioutput_samples(#)} number of posterior draws from the fitted approximation.
Default is {bf:1000}.

{phang}
{opt vitol_rel_obj(#)} convergence tolerance for the ELBO. Default is {bf:0.01}.

{dlgtab:Operations}

{phang}
{opt load} imports posterior draws into Stata memory after sampling. The CmdStan
CSV files are stripped of comment lines, combined across chains, and variable
names are automatically mapped (e.g. {bf:Sigma.1.1} -> {bf:sigma11}).

{phang}
{opt diagnose} reports divergent transitions and tree depth warnings after loading.

{dlgtab:Display}

{phang}
{opt verbose} (or {opt log}) shows full CmdStan output including iteration progress,
adaptation details, and timing. Without this option, CmdStan output is redirected
to a log file and only progress dots are shown.

{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. global CMDSTAN "C:\Users\me\.cmdstan\cmdstan-2.38.0"}{p_end}

{pstd}Basic usage with 4 chains and automatic loading{p_end}
{phang2}{cmd:. stanrun y x1 x2, modelfile(mymodel.stan) load}{p_end}

{pstd}Detailed output with seed{p_end}
{phang2}{cmd:. stanrun y x, modelfile(model.stan) chains(4) iter(2000) seed(123) load diagnose verbose}{p_end}

{pstd}High-precision sampling for difficult posteriors{p_end}
{phang2}{cmd:. stanrun y x, modelfile(hier.stan) adaptdelta(0.99) maxtreedepth(15) load}{p_end}

{pstd}Fast approximate inference via ADVI{p_end}
{phang2}{cmd:. stanrun y x, modelfile(model.stan) variational load}{p_end}

{pstd}ADVI with full-rank approximation{p_end}
{phang2}{cmd:. stanrun y x, modelfile(model.stan) variational vialgorithm(fullrank) load}{p_end}

{pstd}Pass matrices and globals to Stan{p_end}
{phang2}{cmd:. matrix priors = (0, 10)}{p_end}
{phang2}{cmd:. global K = 5}{p_end}
{phang2}{cmd:. stanrun y x, modelfile(model.stan) matrices(priors) globals(K) load}{p_end}

{pstd}Rerun without recompilation{p_end}
{phang2}{cmd:. stanrun y x, modelfile(model.stan) rerun load}{p_end}

{marker companion}{...}
{title:Companion programs}

{pstd}
{cmd:stanrun_extract} {hline 2} Compute posterior summaries (mean, SD, quantiles,
R-hat, ESS) from a stanrun draws file. Optional trace and density plots.

{phang2}{cmd:. stanrun_extract, drawfile(stanrun_chains.csv)}{p_end}
{phang2}{cmd:. stanrun_extract, drawfile(stanrun_chains.csv) parameters(mu sigma) trace(mu sigma)}{p_end}

{pstd}
{cmd:stanrun_diagnostics} {hline 2} Flag parameters with R-hat > 1.01 or ESS
below a threshold (default 100).

{phang2}{cmd:. stanrun_diagnostics, drawfile(stanrun_chains.csv)}{p_end}
{phang2}{cmd:. stanrun_diagnostics, drawfile(stanrun_chains.csv) essmin(400)}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}
When {cmd:load} is specified, posterior samples are loaded into Stata memory with:

{synoptset 25 tabbed}{...}
{p2col 5 25 29 2: Variable}{Description}{p_end}
{synoptline}
{synopt:{it:parameter names}}Posterior draws for each model parameter{p_end}
{synopt:{cmd:lp__}}Log-posterior density (unnormalized){p_end}
{synopt:{cmd:accept_stat__}}HMC acceptance statistic{p_end}
{synopt:{cmd:stepsize__}}Step size used{p_end}
{synopt:{cmd:treedepth__}}Tree depth reached{p_end}
{synopt:{cmd:divergent__}}Divergent transition indicator (0/1){p_end}
{synopt:{cmd:energy__}}Hamiltonian energy{p_end}
{synopt:{cmd:chain}}Chain identifier{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
Files created in the working directory:

{synoptset 25 tabbed}{...}
{p2col 5 25 29 2: File}{Description}{p_end}
{synoptline}
{synopt:{it:chainfile}}Combined posterior draws (.csv or .dta){p_end}
{synopt:{it:datafile}}Data in R/S dump format{p_end}
{synopt:{it:modelfile}}Stan model (.stan){p_end}
{synopt:{it:execfile}}Compiled model (.exe){p_end}
{synoptline}
{p2colreset}{...}

{marker references}{...}
{title:References}

{phang}
Carpenter, B., et al. 2017. Stan: A probabilistic programming language.
{it:Journal of Statistical Software} 76(1). doi:10.18637/jss.v076.i01

{phang}
Hoffman, M. D. and A. Gelman. 2014. The No-U-Turn Sampler: Adaptively setting
path lengths in Hamiltonian Monte Carlo.
{it:Journal of Machine Learning Research} 15: 1593-1623.

{phang}
Kucukelbir, A., et al. 2017. Automatic Differentiation Variational Inference.
{it:Journal of Machine Learning Research} 18(14): 1-45.

{phang}
Stan Development Team. 2025. {it:CmdStan User's Guide}.
{browse "https://mc-stan.org/users/documentation/"}

{title:Author}

{pstd}
Ben A. Dwamena, MD{break}
Clinical Associate Professor Emeritus of Radiology{break}
Division of Nuclear Medicine and Molecular Imaging{break}
University of Michigan{break}
{browse "mailto:info@creedghana.org":info@creedghana.org}

{pstd}
Original StataStan by Robert Grant and Mustafa Ascha.

{title:Also see}

{psee}
Online: {browse "https://mc-stan.org":mc-stan.org},
{browse "https://mc-stan.org/cmdstan/":CmdStan documentation}

{psee}
If installed: {help stanrun_extract}, {help stanrun_diagnostics}, {help bayesmh}
{p_end}
