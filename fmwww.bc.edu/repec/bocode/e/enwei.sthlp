{smcl}
{* *! version 1.0.0  01Sep2024}{...}
{cmd:help enwei}
{hline}

{title:Entropy Method}

{p 8 14}

{title:Title}

{p2colset 7 20 20 2}{...}
{p2col:{hi:enwei} {hline 2}}Calculation of Weights and Comprehensive Scores Using the Entropy Method{p_end}
{p2colreset}{...}


{title:description}

{p}{cmd:enwei} uses the entropy method to calculate index weights and Comprehensive scores. The output results include entropy, Divergence, weights, composite scores, and individual variable scores.

{title:Syntax}

{p 8 14 2}
{cmd:enwei} {varlist} {cmd:,}
{cmdab:o:rder}{cmd:(}{help numlist}{cmd:)}
[{cmdab:gen:erate(varname)}
{cmdab:dim:ension(varname)}
{cmdab:rep:lace}
{cmdab:b:iase}{cmd:(}{help numlist}{cmd:)}]


 
{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {cmdab:o:rder}{cmd:(}{help numlist}{cmd:)}}{help numlist} is a set of values that indicate the positive or negative direction of the variable, {hi:non-zero} indicates that the corresponding variable is {hi:positive}, and {hi:0} indicates that the corresponding indicator is {hi:negative}. The variables that need to be weighted are v1, v2, v3, v4,{help numlist} are 1, 0, 0, 1, then v1 and v4 are positive variables, v2 and v3 are negative variables.{p_end}

{synopt:{cmdab:gen:erate(varname)}}{hi:varname} is the variable name of the Comprehensive score using the entropy method, and the default variable name is {hi:entropy}.{p_end}

{synopt:{cmdab:dim:ension(varname)}}{hi:varname} is the variable name prefix of the score of each variable calculated by entropy method. If this parameter is not set, the score of each variable is not generated separately.{p_end}

{synopt:{cmdab:rep:lace}}{cmdab:rep:lace} indicates that variables with the same name that already exist in the data will be overwritten.{p_end}

{synopt:{cmdab:b:iase}{cmd:(}{help numlist}{cmd:)}}Since one of the observed values must be 0 when using normalization, the amount of translation needs to be set. {help numlist} is a custom translation; If not set, the translation is the reciprocal of the number of samples multiplied by 1000.{p_end}



{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:sysuse citytemp4.dta , clear}
{p_end}

{phang2}{cmd:drop if missing(heatdd)}
{p_end}

{phang2}{cmd:enwei heatdd cooldd tempjan tempjuly , order(1 0 0 1) gen(I) dim(d) replace}

{title:Output the Weights to word}

{phang2}{cmd:collect:enwei heatdd cooldd tempjan tempjuly , order(1 0 0 1) gen(I) dim(d) replace}

{phang2}{cmd:collect layout (rowname[W]) (colname) (result[W]), name(default)}

{phang2}{cmd:collect export "Weights", as(docx) replace}

{marker results}{...}
{title:enwei results}

{pstd}
{cmd:enwei} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:r(OrderM)}}direction{p_end}
{synopt:{cmd:r(E)}}Entropy{p_end}
{synopt:{cmd:r(D)}}Divergence Coefficient{p_end}
{synopt:{cmd:r(W)}}Weights{p_end}
{synopt:{cmd:r(Index)}}Comprehensive Score{p_end}
{synopt:{cmd:r(DIM)}}the score of each variable{p_end}



{title:Authors}

{phang}Jiang Qi{p_end}
{phang}微信公众号:Zscholar Data Scientist{p_end}
{phang}{browse "deeptravonearth@gmail.com":deeptravonearth@gmail.com}


{p2colreset}{...}
