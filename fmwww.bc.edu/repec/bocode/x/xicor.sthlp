{smcl}
{* *! version 2.0.1  19may2026}{...}
{vieweralsosee "[R] correlate" "help correlate"}{...}
{vieweralsosee "[R] spearman" "help spearman"}{...}
{viewerjumpto "Syntax" "xicor##syntax"}{...}
{viewerjumpto "Description" "xicor##description"}{...}
{viewerjumpto "Options" "xicor##options"}{...}
{viewerjumpto "Examples" "xicor##examples"}{...}
{viewerjumpto "Stored results" "xicor##results"}{...}
{viewerjumpto "Acknowledgements" "xicor##acknowledgements"}{...}
{viewerjumpto "References" "xicor##references"}{...}
{viewerjumpto "Support" "xicor##support"}{...}
{...}
{bf:[Community-contributed] xicor} {hline 2} Chatterjee's rank correlation


{marker syntax}{...}
{title:Syntax}

{p 8 18 2}
{cmd:xicor}
{varlist}
{ifin}
[{cmd:,} {it:options}]


{marker description}{...}
{title:Description}

{pstd}
{cmd:xicor}
estimates Chatterjee's (2021) rank correlation coefficient xi
for all pairs of variables in {it:{help varlist}}.

{pstd}
The estimated correlation matrix is not symmetric. 
The rows of the matrix represent Xs 
and the columns of the matrix represent Ys. 
Thus, the correlation coefficient xi(X{it:i},Y{it:j}) 
is found in the {it:i}th row and {it:j}th column. 

{pstd}
Ties in the values of {it:varlist} are broken randomly. 
To reproduce results, set the random-number seed;
see {helpb set_seed:[R] seed}.


{synoptset 15 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt pv:alue}}compute asymptotic two-sided {it:p}-values{p_end}
{synopt:{opt normalize}}display normalized xi correlation matrix{p_end}
{synopt:{opt sym:metric}}display symmetric xi correlation matrix{p_end}
{synopt:{opt rseed(#)}}set random-number seed to {it:#}{p_end}
{synopt:{opth for:mat(%fmt)}}display format; default is {cmd:format(%8.4f)}{p_end}
{synoptline}
{p2colreset}{...}


{marker options}{...}
{title:Options}

{phang}
{opt pvalue}
computes asymptotic two-sided {it:p}-values for testing independence.
{opt pvalue} 
may not be combined with 
{opt normalize} 
or 
{opt symmetric}.

{phang}
{opt normalize}
displays the normalized xi correlation matrix 
proposed by Dalitz et al. (2024).
Each xi correlation coefficient xi(X,Y) 
is divided by its upper bound xi(Y,Y).
Normalization generally reduces finite sample bias 
but may increase the mean squared error, especially for small xi.
{opt normalize} 
may not be combined with 
{opt pvalue}.

{phang}
{opt symmetric}
displays a symmetric xi correlation matrix.
For each pair of variables X and Y, 
the reported coefficient is the maximum of xi(X,Y) and xi(Y,X),
where xi() is the xi coefficient. 
If 
{opt normalize} 
is also specified, 
the normalization is applied before the symmetrization step.
{opt symmetric}
may not be combined with 
{opt pvalue}.

{phang}
{opt rseed(#)}
sets the random-number seed. 
{opt rseed(#)}
is equivalent to typing 

{phang3}
{cmd:. set seed} {it:#}

{phang2}
prior to calling {cmd:xicor}; see {helpb set_seed:[R] seed}.

{phang}
{opt format(%fmt)}
specifies the format for displaying the individual elements of the matrix.  
The default is {cmd:format(%8.4f)}.


{marker examples}{...}
{title:Example}

{pstd}Setup (see {helpb correlate}){p_end}
{phang2}{cmd:. webuse census13}{p_end}

{pstd}Estimate xi correlation matrix{p_end}
{phang2}{cmd:. xicor mrgrate dvcrate medage}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:xicor} stores the following in {cmd:r()}:

{synoptset 25 tabbed}{...}
{p2col 5 25 27 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(xi_coef)}}raw xi correlation coefficient (last two variables){p_end}

{synoptset 25 tabbed}{...}
{p2col 5 25 27 2: Macros}{p_end}
{synopt:{cmd:r(rngstate)}}random-number state used{p_end}

{synoptset 25 tabbed}{...}
{p2col 5 25 27 2: Matrices}{p_end}
{synopt:{cmd:r(xi)}}xi correlation matrix{p_end}
{synopt:{cmd:r(xi_normalized)}}normalized xi correlation matrix ({opt normalize} only){p_end}
{synopt:{cmd:r(xi}[{cmd:_normalized}]{cmd:_sym)}}symmetric (normalized) xi correlation matrix ({opt symmetric} only){p_end}
{synopt:{cmd:r(pvalue)}}asymptotic two-sided {it:p}-values ({opt pvalue} only){p_end}
{synopt:{cmd:r(z)}}z statistics ({opt pvalue} only){p_end}


{marker acknowledgement}{...}
{title:Acknowledgements}

{pstd}
R code from
{browse "https://cran.r-project.org/web/packages/XICOR/index.html":Chatterjee & Holmes (2023)} 
was helpful for clarifying some details in Chatterjee (2021).

{pstd}
Part of the code is adapted from StataCorp 
{help mf_uniqrows:uniqrows()}.

{pstd}
A request from Eric Melse on 
{browse "https://www.statalist.org/forums/forum/general-stata-discussion/general/1751355-xicor-a-new-coefficient-of-correlation":Statalist}
led to this package. 


{marker references}{...}
{title:References}

{pstd}
Chatterjee, S. (2021). A new coefficient of correlation. {it:Journal of the American Statistical Association}, 116(536), 2009--2022. {browse "https://doi.org/10.1080/01621459.2020.1758115"}

{pstd}
Chatterjee, S., & Holmes, S. (2023). XICOR: Robust and generalized correlation coefficients. 
{browse "https://github.com/spholmes/XICOR"}, {browse "https://CRAN.R-project.org/package=XICOR"}

{pstd}
Dalitz, C., Arning, J., & Goebbels, S. A. (2024). Simple bias reduction for Chatterjee's correlation. {it: Journal of Statistical Theory and Practice}, 18(51), 1--19. 
{browse "https://doi.org/10.1007/s42519-024-00399-y"}


{marker support}{...}
{title:Support}

{pstd}
Daniel Klein{break}
klein.daniel.81@gmail.com
