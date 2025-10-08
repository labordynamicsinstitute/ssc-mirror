{smcl}
{* 26sep2025}{...}
{hline}
help for {hi:fejiv}
{hline}

{title:Title}

{phang}
{bf:fejiv} {hline 2} Fixed effect jackknife IV (FEJIV) estimation

{marker syntax}
{title:Syntax}

{p 8 17 2}
{cmdab:fejiv}
{depvar} [{indepvars}] {cmd:(}{it:treatment} {cmd:=} {it:instruments}{cmd:)} {ifin} [{cmd:,} {it:options}]


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth absorb(varname)}}specify a categorical variable to be absorbed{p_end}
{synoptline}


{title:Description}

{pstd} {cmd:fejiv} implements the fixed effect jackknife IV (FEJIV) estimator
of Chao, Swanson, and Woutersen (2023), which enables consistent IV estimation
with many (possibly weak) instruments, cluster fixed effects, heteroskedastic
errors, and possibly many exogenous explanatory variables.

{pstd} The variables should be specified as follows.
{it:depvar} is the dependent variable.
{it:indepvars} is a list of exogenous explanatory variables.
{it:treatment} is the endogenous explanatory variable.
{it:instruments} is a list of instrumental variables.
In addition, if the user specifies the option {cmd:absorb()}, the values of
the designated categorical variable are used to create cluster indicators
("fixed effects"), which are then partialed out in estimation.  Each such
cluster should consist of at least three observations.

{pstd} Consistency of the FEJIV estimator requires that instrument strength
satisfies a key growth condition: the concentration parameter must grow faster
than the square root of the number of instruments.  Mikusheva and Sun (2022) show
that this condition is necessary for the existence of a consistent test and also
propose a test of this condition, implemented in the Stata command
{cmd:manyweakivpretest}, available at Liyang Sun's GitHub.

{pstd} Słoczyński (2024) recommends the FEJIV estimator as an alternative to
two-stage least squares (2SLS) when estimating the fully interacted specification
of Angrist and Imbens (1995).  Within the local average treatment effect (LATE)
framework, when strong monotonicity is doubtful but weak monotonicity is plausible,
the fully interacted specification eliminates the problem of "negative weights."

{pstd} This is a companion software package for Słoczyński (2024).  If you use it,
please cite both Słoczyński (2024) and Chao, Swanson, and Woutersen (2023).


{title:References}

{phang}
Angrist, Joshua D., and Guido W. Imbens (1995). "Two-Stage Least Squares Estimation of Average Causal Effects in Models with Variable Treatment Intensity." {it:Journal of the American Statistical Association} 90(430), 431{c 150}442.

{phang}
Chao, John C., Norman R. Swanson, and Tiemen Woutersen (2023). "Jackknife Estimation of a Cluster-Sample IV Regression Model with Many Weak Instruments." {it:Journal of Econometrics} 235(2), 1747{c 150}1769.

{phang}
Mikusheva, Anna, and Liyang Sun (2022). "Inference with Many Weak Instruments." {it:Review of Economic Studies} 89(5), 2663{c 150}2686.

{phang}
Słoczyński, Tymon (2024). "When Should We (Not) Interpret Linear IV Estimands as LATE?" arXiv preprint arXiv:2011.06695. Available at {browse "https://arxiv.org/abs/2011.06695"}.

{title:Examples}

        {com}. {stata "use https://tslocz.github.io/card.dta, clear"}

        . {stata "generate college = educ>12"}

        . {stata "egen group = group(black smsa smsa66 south south66)"}

        . {stata "bysort group: generate gsize = _N"}

        . {stata "drop if gsize<3"}

        . {stata "ivregress 2sls lwage (college = nearc4) i.group, vce(robust)"}

        . {stata "ivregress 2sls lwage (college = nearc4#group) i.group, vce(robust)"}

        . {stata "fejiv lwage (college = nearc4#group), absorb(group)"}
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
{synopt:{cmd:e(cmd)}}{cmd:fejiv}
    {p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable
    {p_end}
{synopt:{cmd:e(treat)}}name of endogenous explanatory variable (treatment)
    {p_end}
{synopt:{cmd:e(instr)}}names of instrumental variables
    {p_end}
{synopt:{cmd:e(covar)}}names of exogenous explanatory variables
    {p_end}
{synopt:{cmd:e(clust)}}name of variable used to create cluster indicators
    {p_end}
{synopt:{cmd:e(title)}}title in estimation output
    {p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}
    {p_end}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}point estimate
    {p_end}
{synopt:{cmd:e(V)}}estimated variance
    {p_end}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}


{title:Acknowledgments}

{phang} This command is based on MATLAB code for the estimators of Chao, Swanson, and Woutersen (2023), generously shared by Tiemen Woutersen.


{title:License}

{phang} This package is licensed under the MIT License.  See the LICENSE file included with the distribution.


{title:Authors}

{phang} Qihui Lei, University of Wisconsin{p_end}
{pstd}Email: {browse "mailto:qlei9@wisc.edu":qlei9@wisc.edu}{p_end}

{phang} Tymon Słoczyński, Brandeis University{p_end}
{pstd}Email: {browse "mailto:tslocz@brandeis.edu":tslocz@brandeis.edu}{p_end}
