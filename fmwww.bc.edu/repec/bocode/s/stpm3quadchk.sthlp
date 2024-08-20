{smcl}
{vieweralsosee "stpm3" "help stpm3"}{...}
{p2colset 1 17 19 2}{...}
{p2col:{bf:stpm3quadchk} {hline 2}}Check sensitivity of quadrature approximation in stpm3 models{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}{cmd:stpmquadchk} [{it:numlist}] [{opt survival} {opt hazard} ]

{pstd}
{it:numlist} specifies the number of nodes (quadrature points) to use when
comparing to the current model.  

{pstd}
{cmd:stpmquadchk} can only be used after fitting an {cmd:stpm3} model using
the {cmd: scale(lnhazard)} option. When fitting the model numerical integration
is used. {cmd:stpmquadchk} allows you to investigate stability of the likelihood
function, parameter estimates and predictions of hazard and survival functions.


{marker options}{...}
{title:Options}

{phang}
{opt hazard} compares predictions of the hazard function at values of {cmd:_t}

{phang}
{opt survival} compares predictions of the survival function at values of {cmd:_t}


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. use https://www.pclambert.net/data/rott3}{p_end}
{phang2}{cmd:. stset os, f(osi=1)}

{pstd}Fit survival model{p_end}
{phang2}{cmd:. stpm3 i.hormon @ns(age,df(3)), scale(lnhazard) df(3) nodes(10)}{p_end}

{pstd}Check stability of quadrature calculation{p_end}
{phang2}{cmd:. stpm3quadchk 20 30 50 100, hazard survival}{p_end}

{title:Author}

{p 5 12 2}{bf:Paul C. Lambert}{p_end}        
{p 5 12 2}Cancer Registry of Norway{p_end}
{p 5 12 2}National Institute of Public Health{p_end}
{p 5 12 2}Oslo, Norway{p_end}
{p 5 12 2}{it: and}{p_end}
{p 5 12 2}Department of Medical Epidemiology and Biostatistics{p_end}
{p 5 12 2}Karolinska Institutet{p_end}
{p 5 12 2}Stockholm, Sweden{p_end}
{p 5 12 2}pclt@kreftregisteret.no{p_end}