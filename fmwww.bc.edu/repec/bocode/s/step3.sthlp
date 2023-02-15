{smcl}
{* *! version 1.0 13feb2023}{...}
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

{cmd:step3} {varlist}{cmd:,} {opt posterior(stub)} [{opt base(#)} {opt rrr} {opt diff} {opt iter(#)} {opt distal} {opt id(varname)}]
 
{marker description}{...}
{title:Description}

{pstd}
{cmd:step3} is a bias-adjusted method to relate latent class membership to external variables, which can be either covariates or distal outcomes.

{pstd}
For the analysis of covariates, the command performs the third step of the ML procedure described by Vermunt (2010).
Conversely, for distal outcomes the command uses the BCH method (Bolck et al., 2004), which is more robust in most cases (Bakk & Kuha, 2021), especially for continuous and count outcomes.

{pstd}
Although {cmd:step3} also executes the second step of these stepwise procedures (with modal assignment), the first step (i.e., latent class or latent profile analysis without covariates/distal outcomes) must be performed separately.
This can be done with any command, as long as it produces membership posterior probabilities.

{marker options}{...}
{title:Options}

{phang}{opt posterior(stub)} is required. It specifies the prefix of the membership posterior probabilities estimated in the first step.
To avoid errors, it is advisable to use a prefix in the first step that followed by {it:*} only returns the posterior probability variables.

{phang}{opt base(#)} specifies the class that will be the base outcome; default is {opt base(1)}.
 
{phang}{opt rrr} will report the results in relative risk ratios.

{phang}{opt diff} specifies to use a different stepping algorithm in nonconcave regions.

{phang}{opt iter(#)} specifies the maximum number of iterations; default is {opt iter(20)}.

{phang}{opt distal} specifies that the variables in {varlist} are outcomes of latent classes rather than covariates.

{phang}{opt id(varname)} is required when the option {opt distal} is on. It specifies the identifier variable for cases/subjects.

{marker example}{...}
{title:Example}

{phang}Setup

{phang2}{cmd:. webuse mus03sub, clear}

{phang2}{cmd:. gen obs = _n}

{phang}Mixture of three distributions of totchr

{phang2}{cmd:. gsem (totchr <-), lclass(Class 3) emopts(iter(250))}

{phang}Posterior class membership probabilities

{phang2}{cmd:. predict p_*, classposteriorpr}

{phang}Use age, income, and sex as predictors of class membership

{phang2}{cmd:. step3 age income i.sex, posterior(p_) rrr}

{phang}Use lmedexp as outcome of class membership

{phang2}{cmd:. step3 lmedexp, posterior(p_) distal id(obs)}

{marker reference}{...}
{title:Reference}

{phang}Bakk, Z., & Kuha, J. (2021).
{browse "https://doi.org/10.1111/bmsp.12227": Relating latent class membership to external variables: An overview}.
{it:British Journal of Mathematical and Statistical Psychology}, {it:74}(2), 340–362.

{phang}Bolck, A., Croon, M., & Hagenaars, J. (2004).
{browse "https://www.jstor.org/stable/25791751":Estimating Latent Structure Models with Categorical Variables: One-Step Versus Three-Step Estimators}.
{it:Political Analysis}, {it:12}(1), 3–27.

{phang}Vermunt, J. K. (2010).
{browse "https://jeroenvermunt.nl/lca_three_step.pdf":Latent class modeling with covariates: Two improved three-step approaches}.
{it:Political Analysis}, {it:18}, 450–469.

{marker author}{...}
{title:Author}

{pstd}Giovanbattista Califano{p_end}
{pstd}University of Naples "Federico II"{p_end}
{pstd}Dept. Agricultural Sciences – Economics and Policy Group{p_end}
{pstd}giovanbattista.califano@unina.it{p_end}

