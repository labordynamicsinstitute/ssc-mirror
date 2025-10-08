{smcl}
{* *! version 5.0.0 11aug2025}{...}

{cmd:help ggt}
{hline}

{title:Title}

{p2colset 5 12 12 2}{...}
{p2col :{hi:ggt} {hline 2}}Geweke, Gowrisankaran, and Town Model Quality Estimator{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 18 2}
{cmdab:ggt,}
outcomevar({it:varname})
orgchoice({it:varname})
indID({it:varname})
orgID({it:varname})
choicechar({it:varlist})
[{it:options}]
{p_end}

{title:Description}

{pstd}
The GGT model estimates the posterior distribution of organizational performance in settings where many organizations provide services that individuals can choose among.
Individuals may select organizations based, in part, on information unobserved to the researcher that is correlated with the binary outcome.
In such cases, standard approaches to measuring organizational performance yield biased estimates.
The GGT model corrects for this unobserved selection, allowing flexible correlation in the error structure across the organizational choice and outcome equations.
The estimation approach is Bayesian. 
{p_end}

{pstd}
In short, the model combines an organizational choice multinomial probit with an individual outcome binary probit, allowing for correlation across equations at the individual level.
Applications include estimating hospital quality (mortality), school performance (graduation rates), prison rehabilitation programs (recidivism rates), and job training programs (harassment complaint rates).
{p_end}

{pstd}
Parameters are estimated using Bayesian inference via Markov chain Monte Carlo (MCMC) methods.
For details of the model and understanding of program output, see the auxiliary file {bf:ggt_documentation.pdf} (accessible with {cmd:ssc desc ggt} or at {bf:www.kellimarquardt.com/research}).
Users are strongly encouraged to read the original GGT paper for full understanding of the model, assumptions, and estimation parameters.
{p_end}

{pstd}
To improve computational speed, the program calls a bundled C plugin that performs MCMC Gibbs sampling.
{p_end}

{title:Methods and Equations}

{pstd}
A concise description of the GGT model is provided in {bf:ggt_documentation.pdf} (accessible with {cmd:ssc desc ggt} or at {bf:www.kellimarquardt.com/research}).
This file explains the variables and parameters referenced when calling the {cmd:ggt} program.
{p_end}

{pstd}
{bf:Technical note:} Prior distribution descriptions differ slightly from those in GGT Section 2.2.
These modifications make the Stata code more tractable but do not change the model.
Details are in {bf:ggt_documentation.pdf}.
{p_end}

{title:Options}

{dlgtab:Required model variables}

{phang}
{opt outcomevar(varname)} specifies the binary outcome variable. Must take values 0 or 1.

{phang}
{opt orgchoice(varname)} specifies the organizational choice variable. It should equal 1 for the chosen organization and 0 otherwise, with each individual choosing exactly one organization. 

{phang}
{opt indID(varname)} specifies a unique identifier for each individual.

{phang}
{opt orgID(varname)} specifies a unique identifier for each organization.

{phang}
{opt choicechar(varlist)} specifies variables included in the choice equation (the Z variables in {bf:ggt_documentation.pdf}). Must be numeric. Less than 10 variables recommended. 

{dlgtab:Optional model variables}

{phang}
{opt orgchar(varlist)} specifies organization characteristics (the k and l variables in {bf:ggt_documentation.pdf}). Up to 10 variables may be provided. Must be string categorical, with consistent values within each organization.

{phang}
{opt indchar(varlist)} specifies variables for the individual outcome equation (the X variables in {bf:ggt_documentation.pdf}). Up to 100 numeric variables may be provided. Must be consistent within each individual.

{dlgtab:Optional model specifications}

{phang}
{opt niter(integer)} specifies the number of Gibbs sampling iterations. Default is 100000. Must be a multiple of 100.

{phang}
{opt alphapriorvar(real)} sets the diagonal elements of the alpha prior variance-covariance matrix. Default is 1.

{phang}
{opt gammapriorvar(real)} sets the diagonal elements of the gamma prior variance-covariance matrix. Default is 1.

{phang}
{opt deltapriorvar(real)} specifies sigma_gamma^2 in the prior distribution of delta (see GGT footnote 17). Default is 0.038416.

{phang}
{opt priortau(numlist)} sets the hyperparameters (s2, v) of the hierarchical prior distribution for organization characteristics: s2 / tau_o^2 ~ chi2(v). Default is priortau(1.25,5). Both elements must be specified if used.

{phang}
{opt noselection} suppresses the selection correction, i.e. restricting delta=0.

{phang}
{opt noconstant} omits the constant from the outcome probit equation.

{dlgtab:Output naming option}

{phang}
{opt savedraws(str)} specifies the name of the CSV file to save every 100th MCMC draw. Default is ''temp_GGT_output.csv''.

{title:Examples}

{pstd}
This section outlines required data structure and examples. Note that {bf:ggt_documentation.pdf} has additional details, summary of program output, and quality calculations. 
Sample data are in {bf:ggt_test_data.dta}. The full documentation and sample data are available for download with {cmd:ssc desc ggt} or at {bf:www.kellimarquardt.com/research}.
{p_end}

{bf:Data structure}

{pstd}
Example: hospital quality. {bf:ggt_test_data.dta} contains 300 patients and 8 hospitals.
Variables include patient ID ({it:indnumber}), hospital ID ({it:hospnum}), patient outcomes ({it:mortality}), patient risk score ({it:risk_score}), and choice variables ({it:dist}, {it:dist2}).
Hospital characteristics are {it:hosp_size} and {it:hosp_ownership}.
{p_end}

{pstd}
Each patient-hospital pair must be observed (e.g. 300x8=2400 rows).
{p_end}

{pstd}{cmd:. use ggt_test_data.dta}{p_end}

{bf:Example 1}

{pstd}
Estimate selection-corrected hospital quality with default settings:
{p_end}

{pstd}{cmd:. ggt, outcomevar(mortality) orgchoice(hosp_choice) indID(indnumber) orgID(hospnum) choicechar(dist dist2)}{p_end}
{pstd}{txt}complete. Success=1 {p_end}

{pstd}
This estimates the full selection model with {it:dist} and {it:dist2} as choice variables.
Defaults are used for priors and iterations. Output is saved to user's directory with the default file name, ''temp_GGT_output.csv''.
See {bf:ggt_documentation.pdf} (accessible with {cmd:ssc desc ggt} or at {bf:www.kellimarquardt.com/research}) for description of program output.
{p_end}

{bf:Example 2}

{pstd}
Add patient risk score to the outcome equation, allow correlation based on hospital size and ownership, and rescale priors. Use 50000 iterations and save to ggt_example2.csv:
{p_end}

{pstd}{cmd:. ggt, outcomevar(mortality) orgchoice(hosp_choice) indID(indnumber) orgID(hospnum) choicechar(dist dist2)}
{cmd: indchar(risk_score) orgchar(hosp_size hosp_ownership) alphapriorvar(5) gammapriorvar(3) deltapriorvar(.1) priortau(1,5) niter(50000) savedraws(''ggt_example2.csv'')}{p_end}
{pstd}{txt}complete. Success=1 {p_end}



{bf:Example 3}

{pstd}
Estimate without selection correction, saving results to ggt_example3.csv:
{p_end}

{pstd}{cmd:. ggt, outcomevar(mortality) orgchoice(hosp_choice) indID(indnumber) orgID(hospnum) choicechar(dist dist2)}
{cmd: indchar(risk_score) orgchar(hosp_size hosp_ownership) alphapriorvar(5) gammapriorvar(3) priortau(1,5) niter(50000) savedraws(''ggt_example3.csv'') noselection}{p_end}
{pstd}{txt}complete. Success=1 {p_end}


{title:References}

Geweke, J., Gowrisankaran, G., & Town, R. J. (2003). Bayesian inference for hospital quality in a selection model. {it:Econometrica}, 71(4), 1215–1238.

{p2colreset}{...}
