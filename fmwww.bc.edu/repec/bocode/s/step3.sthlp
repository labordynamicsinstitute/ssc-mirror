{smcl}
{* *! version 1.2 21oct2023}{...}
{viewerdialog step3 "dialog step3"}{...}
{viewerjumpto "Syntax" "step3##syntax"}{...}
{viewerjumpto "Description" "step3##description"}{...}
{viewerjumpto "Options" "step3##options"}{...}
{viewerjumpto "Example" "step3##example"}{...}
{viewerjumpto "Reference" "step3##reference"}{...}
{viewerjumpto "Author" "step3##author"}{...}
 
{p2col:{bf:step3}} Bias-Adjusted 3Step Latent Class Analysis
 
{marker syntax}{...}
{title:Syntax}
{p}

{cmd:step3} {varlist}{cmd:,} {opt posterior(stub)} {opt id(varname)} [{opt distal} {opt uneq} {opt base(#)} {opt rrr} {opt pval} {opt diff} {opt iter(#)}]
 
{marker description}{...}
{title:Description}

{pstd}
{cmd:step3} is a bias-adjusted method to relate latent class membership to external variables, which can be either covariates or distal outcomes.

{pstd}
The command performs the ML three-step procedure described by Vermunt (2010) with modal assignment.
The first step - latent class analysis without covariates/distal outcomes - must be performed separately.
This can be done with any command, as long as it produces membership posterior probabilities.

{pstd}
In addition, the program quietly runs a test to ensure that the composition of the classes does not change after adding covariates/distal outcomes to the model.
If the composition does change, the command will execute the analysis with classical proportional assignment, estimating the variances with the sandwich estimator.

{marker options}{...}
{title:Options}

{phang}{opt posterior(stub)} is required. It specifies the prefix for the membership posterior probabilities estimated in the first step.
To avoid errors, it is advisable to choose a prefix that only returns the posterior probability variables when followed by {it:*}.

{phang}{opt id(varname)} is required. It specifies the identifier variable for observations.

{phang}{opt distal} specifies that the variable in {varlist} is the outcome of latent classes rather than a covariate.
In {varlist} it is advisable to use the appropriate {it:i.} operator before a factor variable to prevent errors.

{phang}{opt uneq} specifies to relax the assumption of equal variances across classes.

{phang}{opt base(#)} specifies the reference class that will be used as the base outcome; default is {opt base(1)}.
 
{phang}{opt rrr} will report the results in relative risk ratios.

{phang}{opt pval} will report the exact p-value instead of stars.

{phang}{opt diff} specifies to use a different stepping algorithm in nonconcave regions.

{phang}{opt iter(#)} specifies the maximum number of iterations; default is {opt iter(20)}.

{marker example}{...}
{title:Example}

{phang}Setup

{phang2}{cmd:. webuse gsem_lca2.dta, clear}

{phang}Three categories of diabetes based on glucose, insulin, and sspg

{phang2}{cmd:. gsem (glucose insulin sspg <-), lclass(C 3) lcinvariant(none) covstructure(e._OEn, un)}

{phang}Posterior class membership probabilities

{phang2}{cmd:. predict pr_*, classposteriorpr}

{phang}Use relwgt as predictor of class membership with classic modal assignment

{phang2}{cmd:. egen max = rowmax(pr_*)}

{phang2}{cmd:. generate modal_class = 1}

{phang2}{cmd:. replace modal_class = 2 if max == pr_2}

{phang2}{cmd:. replace modal_class = 3 if max == pr_3}

{phang2}{cmd:. mlogit modal_class relwgt}

{phang}Use relwgt as predictor of class membership with step3

{phang2}{cmd:. step3 relwgt, posterior(pr_) id(patient)}

{phang}Although the latent profiles are well differentiated (Entropy > 0.8), the results of the analysis using the classic modal assignment are slightly underestimated.
This phenomenon is more evident and problematic at lower entropy levels.

{marker reference}{...}
{title:Reference}

{phang}Vermunt, J. K. (2010).
{browse "https://jeroenvermunt.nl/lca_three_step.pdf":Latent class modeling with covariates: Two improved three-step approaches}.
{it:Political Analysis}, {it:18}, 450–469.

{marker author}{...}
{title:Author}

{pstd}Giovanbattista Califano{p_end}
{pstd}University of Naples Federico II{p_end}
{pstd}Dept. Agricultural Sciences – Economics and Policy Group{p_end}
{pstd}giovanbattista.califano@unina.it{p_end}

