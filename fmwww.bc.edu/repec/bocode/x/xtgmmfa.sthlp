{smcl}
{* *! version 1.0  30dec2025}{...}
{* *! Manh Hoang Ba, hbmanh9492@gmail.com}{...}

{title:Title}

{p2colset 5 17 19 2}{...}
{p2col :{bf:xtgmmfa} {hline 2}}performs GMM estimation for fixed-T factor-augmented panel data model{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}{cmd:xtgmmfa} {depvar} [{indepvars}] {ifin} [{cmd:,} {it:options}]


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtgmmfa} performs GMM estimation for fixed-T panel data model with multifactor structural errors and the presence of endogenous variables.
The underlying methodology involves approximating the unobserved common factors using observed factor proxies. The resulting moment conditions are linear in the parameters. See Joudis and Sarafidis (2022) for more details.


{synoptset 20 tabbed}{...}
{synopthdr:options}
{synoptline}
{syntab:Model}
{p2coldent :* {opt gmm:vars}{cmd:(}{varlist} [{cmd:, mlag(}#{cmd:)}]{cmd:)}}specifies variables with lags used to construct the GMM-style collumns in instrument matrix. {cmd:mlag(#)} specifies the maximum lag order used for all variables.{p_end}
{synopt:{opt iv:vars}{cmd:(}{varlist}{cmd:)}}specifies variables used to construct the IV-style collumns in instrument matrix.{p_end}
{synopt:{opt unof:actors}{cmd:(}{it:unof_spec}{cmd:)}}specifies the specification of the factor proxies selection or estimation step.{p_end}
{synopt:{opt obsf:actors}{cmd:(}{varlist}{cmd:)}}specifies observed factors with unit-specific factor loadings. Specifying too many observed factors may lead to identification problems.{p_end}
{synopt:{opt wmat:rix}{cmd:(}1|2{cmd:)}}specifies initial weighting matrix: 1 = indentity matrix, 2 = Z'Z matrix (default).{p_end}
{synopt:{opt one:step}}use the one-step estimator.{p_end}
{synopt:{opt nocons:tant}}suppress constant term.{p_end}

{syntab:SE/Robust}
{synopt:{opt r:obust}}use robust standard errors; for two-step GMM, apply the Windmeijer (2005) correction.{p_end}
{synopt:{opt cl:uster}{cmd:(}{varname}{cmd:)}}computes cluster-robust standard errors. This option does not affect one-step coefficients, but affects one-step standard errors and both coefficients and standard errors in two-step GMM.{p_end}
{synopt:{opt sm:all}}make degrees-of-freedom adjustment and report small-sample statistics.{p_end}

{syntab:Reporting}
{synopt:{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}.{p_end}

{synoptline}
{p2colreset}{...}
{p 4 6 2}* These options is required.{p_end}


{marker options_spec}{...}
{p 4 6 2}
{it:unof_spec} is

{p 8 12 2}
{it: Vlist} [{cmd:,} {opt wvar(varname)} {opt regu} {opt bss} {opt type(1|2|3)} {opt lmax(#)} {opt seed(#)} {opt power(#)} {opt er} {opt noreg:ressor}]{p_end}

{synoptset 20 tabbed}{...}
{synopthdr:unof_spec}
{synoptline}
{synopt:{it:Vlist}}includes time-varying variables, assumed to be drived by factors inside (as well as outside) the model. These variables are used to construct the vector v_i in equation (11) and V_i in equation (17) in Joudis and Sarafidis (2022). In addition, {cmd:xtgmmfa} automatically adds time-varying regressors (y, X) after {it:Vlist}. Therefore, {it:Vlist} can be empty.{p_end}
{synopt:{opt wvar(varname)}}specifies a variable to be used in constructing the weight vector wi in formulas (12) and (16) in Joudis and Sarafidis (2022). When wvar is empty, xtgmmfa automatically uses the dependent variable.{p_end}
{synopt:{opt regu}}uses the Regularization method to estimate the number of factor proxies. This is default.{p_end}
{synopt:{opt bss}}uses the Best-Subset Selection method (BSS) instead of the Regularization. {cmd:bss} selects the factor proxies vector and the number of factor proxies from a set of available factors, by estimating feasible models and finding the model with the smallest BIC. This procedure is time-consuming when using {cmd:type(3)} options.{p_end}
{synopt:{opt type}{cmd:(}#{cmd:)}}specifies how to combines V_i and W_i in constructing the set of available factors. {cmd:type(1)} uses the first variable in {it:Vlist} and multiple weights w_i, {cmd:type(2)} uses all variables in {it:Vlist} and single weight, {cmd:type(3)} combines both.{p_end}
{synopt:{opt lmax}{cmd:(}#{cmd:)}}specifies the maximum number of factor proxies to be searched in the BSS method; default is {cmd:lmax(2)}.{p_end}
{synopt:{opt seed}{cmd:(}#{cmd:)}}seed specifies the seed used to generate the Rademacher random variable when {cmd:regu} is specified; default is {cmd:seed(120)}.{p_end}
{synopt:{opt power}{cmd:(}#{cmd:)}}specifies the power to calculate the single weights from the variable in {cmd:wvar}; default is {cmd:seed(120)}.{p_end}
{synopt:{opt er}}uses the Eigenvalue Ratio statistic instead of the Growth Ratio (default) in estimating the number of factor proxies when the {cmd:regu} is specified.{p_end}
{synopt:{opt noreg:ressor}}prevents {cmd:xtgmmfa} from automatically adding regression variables to {it:Vlist}.{p_end}
{synoptline}
{p2colreset}{...}

{p 4 6 2}
You must {cmd:xtset} your data before using {cmd:xtgmmfa}; see {helpb xtset:[XT] xtset}.{p_end}
{p 4 6 2}
All {it:varlists} may contain factor variables; see {help fvvarlist}.{p_end}
{p 4 6 2}
{it:depvar} and all {it:varlists} may contain time-series operators; see {help tsvarlist}.{p_end}
{p 4 6 2}
{cmd:xtgmmfa} is a community-contributed program. The current version requires Stata version 11 or higher.{p_end}


{marker example}{...}

{title:Example}

{pstd}Water data (Joudis and Sarafidis, 2022){p_end}
{phang2}. {stata use js22data, clear}{p_end}

{pstd}Regularization: column M_F of table 1 in Joudis and Sarafidis (2022){p_end}
{phang2}. {stata xtgmmfa l(0/1).lcons price rain temp, gmm(l.lcons l.price rain temp) unof(smi, type(1)) nocons wmat(1)}{p_end}

{pstd}Best-Subset Selection: column M1_c of table 1 in Joudis and Sarafidis (2022){p_end}
{phang2}. {stata xtgmmfa l(0/1).lcons price rain temp, gmm(l.lcons l.price rain temp) unof(smi, bss type(1) lmax(4)) nocons wmat(1)}{p_end}

{pstd} Arellano-Bond data{p_end}
{phang2}. {stata webuse abdata, clear}{p_end}

{pstd}One-step GMM with robust standard errors{p_end}
{phang2}. {stata xtgmmfa l(0/1).n k w ys, gmm(l.n l.k l.w l.ys) one r}{p_end}

{pstd}Two-step GMM with Windmeijer-corrected robust standard errors{p_end}
{phang2}. {stata xtgmmfa l(0/1).n k w ys, gmm(l.n l.k l.w l.ys) r}{p_end}


{marker results}{...}

{title:Saved results}

{pstd}
{cmd:xtgmmfa} saves the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(N_g)}}number of groups{p_end}
{synopt:{cmd:e(Tmin)}}smallest group size{p_end}
{synopt:{cmd:e(Tavg)}}average group size{p_end}
{synopt:{cmd:e(Tmax)}}largest group size{p_end}
{synopt:{cmd:e(k)}}number of interested parameters{p_end}
{synopt:{cmd:e(r_ga)}}number of estimated parameters{p_end}
{synopt:{cmd:e(j)}}number of instruments{p_end}
{synopt:{cmd:e(j_s)}}Sargan/Hansen's J statistic{p_end}
{synopt:{cmd:e(j_p)}}Sargan/Hansen's J p-value{p_end}
{synopt:{cmd:e(j_df)}}Sargan/Hansen's J degrees-of-freedom{p_end}
{synopt:{cmd:e(df_m)}}Model degrees of freedom{p_end}
{synopt:{cmd:e(df_r)}}residual degrees of freedom (if {cmd:small} not specified){p_end}
{synopt:{cmd:e(chi2)}}Wald chi-squared statistic (if {cmd:small} not specified){p_end}
{synopt:{cmd:e(chi2p)}}chi-squared p-value (if {cmd:small} not specified){p_end}
{synopt:{cmd:e(F)}}F statistic (if {cmd:small} specified){p_end}
{synopt:{cmd:e(F_p)}}F p-value (if {cmd:small} specified){p_end}
{synopt:{cmd:e(Le)}}Le is estimated/selected{p_end}
{synopt:{cmd:e(bic)}}Bayesian information criterion{p_end}
{synopt:{cmd:e(type)}}Type of method to constructing factor proxies{p_end}
{synopt:{cmd:e(N_clust)}}number of clusters{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xtgmmfa}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(ivar)}}variable denoting groups{p_end}
{synopt:{cmd:e(tvar)}}variable denoting time{p_end}
{synopt:{cmd:e(method)}}method to determine the number of factor proxies{p_end}
{synopt:{cmd:e(stat_note)}}statistic to determine the number of factor proxies{p_end}
{synopt:{cmd:e(gmmstep)}}one-step or two-steps GMM{cmd:teffects}{p_end}
{synopt:{cmd:e(vcetype)}}title used to label Std. Err.{p_end}
{synopt:{cmd:e(clustvar)}}name of cluster variable{p_end}
{synopt:{cmd:e(small)}}"small" for {cmd:small}{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}interested coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the interested estimators{p_end}
{synopt:{cmd:e(theta)}}coefficient vector{p_end}
{synopt:{cmd:e(Vtheta)}}variance-covariance matrix of the estimators{p_end}
{synopt:{cmd:e(S)}}lag selection matrix to contruct instrument matrix{p_end}
{synopt:{cmd:e(Fe_hat)}}factor proxies matrix{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}


{marker update}{...}
{title:Version updates}

{pstd}To update the {cmd:xtgmmfa} package to the latest version, run either of the following commands{p_end}
{phang2}. {stata `"ssc install xtgmmfa, replace"'}{p_end}
{phang2}. {stata `"net install xtgmmfa, from("https://raw.githubusercontent.com/ManhHB94/xtgmmfa/main/") replace"'}{p_end}


{marker author}{...}

{title:Author}

{pstd}
Manh Hoang Ba, {browse "https://manhb94econometrics.wordpress.com/"}

{pstd}
hbmanh9492@gmail.com


{title:Acknowledgement}

{pstd}
I would like to express my sincere gratitude to Arturas Joudis and Vasilis Sarafidis, who developed the linear GMM approach for this class of models. The implementation of {cmd:xtgmmfa} benefited substantially from the MATLAB code provided with their research.


{marker references}{...}

{title:References}

{phang}
Arellano, M., and S. R. Bond. 1991.
Some tests of specification for panel data: Monte Carlo evidence and an application to employment equations.
{it:Review of Economic Studies} 58: 277-297.

{phang}
Juodis, A., & Sarafidis, V. (2022). A linear estimator for factor-augmented fixed-T panels with endogenous regressors. {it:Journal of Business & Economic Statistics}, 40(1), 1-15.

{phang}
Roodman, D. 2009.
A note on the theme of too many instruments.
{it:Oxford Bulletin of Economics and Statistics} 71: 135-158.

{phang}
Windmeijer, F. 2005.
A finite sample correction for the variance of linear efficient two-step GMM estimators.
{it:Journal of Econometrics} 126: 25-51.
