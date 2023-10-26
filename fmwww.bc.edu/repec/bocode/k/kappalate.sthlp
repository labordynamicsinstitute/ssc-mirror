{smcl}
{* 21oct2023}{...}
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
{synopt:{opt zmodel(string)}}select the approach to estimating the instrument propensity score; options include {opt logit}, {opt probit}, and {opt cbps}; default is {opt cbps}{p_end}
{synopt:{opt vce(vcetype)}}{it:vcetype} is passed on to Stata's {cmd:gmm} command and specifies the type of standard error reported (see {helpb gmm} for details); default is {opt robust}{p_end}
{synopt:{opt std(string)}}{it:string} may be {opt on} or {opt off}, which determines whether nonbinary covariates are standardized prior to estimation; default is {opt on}{p_end}
{synopt:{opt which(string)}}{it:string} may be {opt all} or {opt norm}, which determines whether all estimates or only normalized estimates are displayed; default is {opt norm}{p_end}
{synoptline}


{title:Description}

{pstd} {cmd:kappalate} estimates the local average treatment effect (LATE) using methods based on inverse probability weighting, including (but not limited to) Abadie's (2003) kappa approach.  See Słoczyński, Uysal, and Wooldridge (2023) for a detailed treatment of the underlying theoretical results.

{pstd} The following variables should be designated.  {it:depvar} is the outcome variable.  {it:indepvars} is a list of control variables.  {it:treatment} and {it:instrument} are the treatment and the instrumental variable, respectively, both of which must be binary and take on only the values 0, 1, or missing.  {it:instrument} is assumed to be valid conditional on {it:indepvars} and needs to satisfy the monotonicity assumption.

{pstd} {cmd:kappalate} displays up to five estimates of the LATE, dependent on the options chosen.  The naming convention for the alternative estimates follows Słoczyński, Uysal, and Wooldridge (2023), who recommend normalized estimators ({cmd:which(norm)}) and estimating the instrument propensity score using the covariate balancing approach ({cmd:zmodel(cbps)}) of Imai and Ratkovic (2014).  We also recommend standardizing nonbinary covariates prior to estimation ({cmd:std(on)}), as this may improve the performance of Stata's optimization process without affecting the estimation results.

{pstd} If you use this program in your work, please cite Słoczyński, Uysal, and Wooldridge (2023).


{title:References}

{phang}
Abadie, Alberto (2003). "Semiparametric Instrumental Variable Estimation of Treatment Response Models." {it:Journal of Econometrics} 113(2), 231{c 150}263.

{phang}
Imai, Kosuke and Marc Ratkovic (2014). "Covariate Balancing Propensity Score." {it:Journal of the Royal Statistical Society, Series B} 76(1), 243{c 150}263.

{phang}
Słoczyński, Tymon, S. Derya Uysal, and Jeffrey M. Wooldridge (2023). "Abadie's Kappa and Weighting Estimators of the Local Average Treatment Effect." arXiv:2204.07672. Available at {browse "https://arxiv.org/abs/2204.07672"}.


{title:Examples}

        {com}. {stata "use https://economics.mit.edu/sites/default/files/inline-files/sipp2.dta, clear"}

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


{title:Authors}

{phang} Derya Uysal, LMU Munich{p_end}
{pstd}Email: {browse "mailto:derya.uysal@econ.lmu.de":derya.uysal@econ.lmu.de}{p_end}

{phang} Tymon Słoczyński, Brandeis University{p_end}
{pstd}Email: {browse "mailto:tslocz@brandeis.edu":tslocz@brandeis.edu}{p_end}

{phang} Jeffrey M. Wooldridge, Michigan State University{p_end}
{pstd}Email: {browse "mailto:wooldri1@msu.edu":wooldri1@msu.edu}{p_end}
