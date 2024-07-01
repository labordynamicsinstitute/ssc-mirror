{smcl}
{* 26jun2024}{...}
{hline}
help for {hi:kappalate}
{hline}

{title:Title}

{phang}
{bf:kappalate} {hline 2} Estimating the local average treatment effect (LATE) using Abadie's kappa approach and other weighting estimators

{marker syntax}
{title:Syntax}

{p 8 17 2}
{cmdab:kappalate}
{depvar} [{it:{indepvars}}] {cmd:(}{it:treatment} {cmd:=} {it:instrument}{cmd:)} {ifin} [{cmd:,} {it:options}]


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt zmodel(string)}}select the approach to estimating the instrument propensity score;
options include {opt logit} to fit a logit model by maximum likelihood (ML),
{opt probit} to fit a probit model by maximum likelihood (ML),
and {opt cbps} to fit a logit model by covariate balancing (CB);
default is {opt cbps}{p_end}
{synopt:{opt vce(vcetype)}}{it:vcetype} is passed on to Stata's {cmd:gmm} command and specifies the type of standard error reported (see {helpb gmm} for details); default is {opt robust}{p_end}
{synopt:{opt std(string)}}{it:string} may be {opt on} or {opt off}, which determines whether nonbinary covariates are standardized prior to estimation; default is {opt on}{p_end}
{synopt:{opt which(string)}}{it:string} may be {opt all} or {opt norm}, which determines whether all estimates or only normalized estimates are displayed; default is {opt norm}{p_end}
{synoptline}


{title:Description}

{pstd} {cmd:kappalate} estimates the local average treatment effect (LATE) using methods based on inverse probability weighting, most of which can be motivated by Abadie's (2003) kappa theorem.
See Słoczyński, Uysal, and Wooldridge (2024) for a detailed treatment of the underlying theoretical results.

{pstd} The following variables should be designated.
{it:depvar} is the outcome variable.
{it:indepvars} is a list of control variables.
{it:treatment} is the treatment variable.
{it:instrument} is the instrumental variable, which must be binary and take on only the values 0, 1, or missing.
{it:instrument} is assumed to be valid conditional on {it:indepvars} and needs to satisfy the monotonicity assumption.

{pstd} {cmd:kappalate} displays up to five estimates of the LATE, dependent on the options chosen.
The naming convention for the alternative estimates follows Słoczyński, Uysal, and Wooldridge (2024), who recommend normalized estimators (option {cmd:which(norm)}),
and especially the estimator in Uysal (2011), referred to as {it:tau_u}, with covariate balancing propensity scores (option {cmd:zmodel(cbps)}), as in Heiler (2022).
We also recommend standardizing nonbinary covariates before estimation (option {cmd:std(on)}), as this may improve the performance of Stata's optimization process without affecting the estimation results.

{pstd} {cmd:kappalate} allows for multivalued treatments, even though this case is not explicitly discussed by Słoczyński, Uysal, and Wooldridge (2024).
The fact that, with a multivalued treatment, {it:tau_u} can be used to estimate the average causal response (ACR), a variant of the LATE, follows from Frölich (2007).

{pstd} If you use this program in your work, please cite Słoczyński, Uysal, and Wooldridge (2024).


{title:References}

{phang}
Abadie, Alberto (2003). "Semiparametric Instrumental Variable Estimation of Treatment Response Models." {it:Journal of Econometrics} 113(2), 231{c 150}263.

{phang}
Frölich, Markus (2007). "Nonparametric IV Estimation of Local Average Treatment Effects with Covariates." {it:Journal of Econometrics} 139(1), 35{c 150}75.

{phang}
Heiler, Phillip (2022). "Efficient Covariate Balancing for the Local Average Treatment Effect." {it:Journal of Business & Economic Statistics} 40(4), 1569{c 150}1582.

{phang}
Słoczyński, Tymon, S. Derya Uysal, and Jeffrey M. Wooldridge (2024). "Abadie's Kappa and Weighting Estimators of the Local Average Treatment Effect." {it:Journal of Business & Economic Statistics}, forthcoming.
Available at {browse "https://doi.org/10.1080/07350015.2024.2332763"}.

{phang}
Uysal, S. Derya (2011). "Three Essays on Doubly Robust Estimation Methods." PhD dissertation, University of Konstanz.


{title:Examples}

        {com}. {stata "use https://people.brandeis.edu/~tslocz/sipp.dta, clear"}

        . {stata "drop if kwage==. | educ==. | rsncode==999"}

        . {stata "generate double lwage = ln(kwage)"}

        . {stata "kappalate lwage (nvstat=rsncode) age_5, zmodel(cbps) which(norm)"}

        . {stata "kappalate lwage (nvstat=rsncode) age_5, zmodel(cbps) which(all)"}

        . {stata "kappalate lwage (nvstat=rsncode) age_5, zmodel(logit) which(all)"}
        {txt}

{title:Stored results}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations
    {p_end}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Macros}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed
    {p_end}
{synopt:{cmd:e(cmd)}}{cmd:kappalate}
    {p_end}
{synopt:{cmd:e(vce)}}{it:vcetype} specified in {cmd:vce()}
    {p_end}
{synopt:{cmd:e(zmodel)}}estimation method for the instrument propensity score specified in {cmd:zmodel()}
    {p_end}
{synopt:{cmd:e(zvar)}}name of instrumental variable
    {p_end}
{synopt:{cmd:e(tvar)}}name of treatment variable
    {p_end}
{synopt:{cmd:e(depvar)}}name of dependent (outcome) variable
    {p_end}
{synopt:{cmd:e(title)}}title in estimation output
    {p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}
    {p_end}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}point estimate(s)
    {p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix
    {p_end}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}


{title:Acknowledgments}

{phang} We thank Alex Torgovitsky for helpful comments on this program.


{title:Authors}

{phang} Derya Uysal, LMU Munich{p_end}
{pstd}Email: {browse "mailto:derya.uysal@econ.lmu.de":derya.uysal@econ.lmu.de}{p_end}

{phang} Tymon Słoczyński, Brandeis University{p_end}
{pstd}Email: {browse "mailto:tslocz@brandeis.edu":tslocz@brandeis.edu}{p_end}

{phang} Jeffrey M. Wooldridge, Michigan State University{p_end}
{pstd}Email: {browse "mailto:wooldri1@msu.edu":wooldri1@msu.edu}{p_end}
