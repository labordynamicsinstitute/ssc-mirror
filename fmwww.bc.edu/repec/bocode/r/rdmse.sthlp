{smcl}
{* *! version 2.3 22MAR2023}{...}

{title:Title}

{p 4 8}{cmd:rdmse} {hline 2} Mean Squared Error Estimation for Local Polynomial Regression Discontinuity and Regression Kink Estimators.{p_end}

{marker syntax}{...}
{title:Syntax}

{p 4 15 2}{cmd:rdmse} {it:depvar} {it:runvar} {ifin} 
[{cmd:,} 
{cmd:c(}{it:#}{cmd:)} 
{cmd:p(}{it:#}{cmd:)} 
{cmd:deriv(}{it:#}{cmd:)}
{cmd:fuzzy(}{it:fuzzyvar}{cmd:)}
{cmd:kernel(}{it:kernelfn}{cmd:)}
{cmd:h(}{it:#}{cmd:)} 
{cmd:b(}{it:#}{cmd:)}
{cmd:scalepar(}{it:#}{cmd:)}
{cmd:twosided}
{cmd:pl(}{it:#}{cmd:)}
{cmd:pr(}{it:#}{cmd:)}
{cmd:hl(}{it:#}{cmd:)} 
{cmd:hr(}{it:#}{cmd:)} 
{cmd:bl(}{it:#}{cmd:)} 
{cmd:br(}{it:#}{cmd:)} 
]{p_end}

{p 4 15 2}{cmd:rdmse_cct2014} {it:depvar} {it:runvar} {ifin} 
[{cmd:,} 
{cmd:c(}{it:#}{cmd:)} 
{cmd:p(}{it:#}{cmd:)} 
{cmd:deriv(}{it:#}{cmd:)}
{cmd:fuzzy(}{it:fuzzyvar}{cmd:)}
{cmd:kernel(}{it:kernelfn}{cmd:)}
{cmd:h(}{it:#}{cmd:)} 
{cmd:b(}{it:#}{cmd:)}
{cmd:scalepar(}{it:#}{cmd:)}
]{p_end}

{synoptset 28 tabbed}{...}

{marker description}{...}
{title:Description}

{p 4 8 8}{cmd:rdmse} computes the (asymptotic) mean squared error (MSE) of a local polynomial RD/RK estimator as proposed in Pei, Lee, Card, Weber (2022). 
It displays and returns the estimated MSE for the conventional estimator and its bias corrected counterpart as defined in Calonico, Cattaneo, Titiunik (2014a).{p_end}

{p 4 8 8}{cmd:rdmse_cct2014} computes the (A)MSE for a conventional RD/RK estimator by gathering the relevant quantities calculated by the 2014 implementation of {bf}rdrobust{sf}, {bf}rdrobust_2014{sf} by Calonico, Cattaneo and Titiunik. 
It does not estimate the (A)MSE for the bias corrected estimator because some of the quantities required for the calculation are not computed by {bf}rdrobust_2014{sf} (nor {bf}rdrobust{sf}). 
For the conventional estimator, {bf}rdmse_cct2014{sf} and {bf}rdmse {sf}implement variance estimation slightly differently. 
Both commands employ a nearest neighbor estimator and set the number of neighbors to three. 
However, in the event of a tie {bf}rdmse_cct2014{sf} selects all of the closest neighbors following {bf}rdrobust_2014{sf}. 
In contrast, {bf}rdmse{sf} randomly selects three neighbors and speeds up the computation in doing so.{p_end}

{marker options}{...}
{title:Options}

{p 4 8}{cmd:c(}{it:#}{cmd:)} specifies the RD cutoff in {it:runvar}.
Default is {cmd:c(0)}{sf}.

{p 4 8}{cmd:p(}{it:#}{cmd:)} specifies the order of the local polynomial. 
Default is {cmd:p(1)} (local linear regression). Consistent with the implementation in {cmd:rdrobust}, the maximum value allowed for {cmd:p()} is 8. A local polynomial of order ({it:p}+1) is used to estimate the bias of the estimator.

{p 4 8}{cmd:deriv(}{it:#}{cmd:)} specifies the order of the derivative of the regression functions to be estimated.
Default is {cmd:deriv(0)} (RD estimator). Use {cmd:deriv(1)} for an RK estimator.

{p 4 8}{cmd:fuzzy(}{it:fuzzyvar}{cmd:)} specifies the treatment variable in a fuzzy RD/RK design. Leave the option unspecified if the underlying design is sharp.

{p 4 8}{cmd:kernel(}{it:kernelfn}{cmd:)} specifies the kernel function used to construct the local polynomial estimator. Options are {cmd:triangular} or {cmd:uniform}{sf}.

{p 4 8}{cmd:h(}{it:#}{cmd:)} specifies the main bandwidth used to construct the RD/RK estimator. The user has to specify this bandwidth.

{p 4 8}{cmd:b(}{it:#}{cmd:)} specifies the bias bandwidth for estimating the bias of the RD/RK estimator. The user has to specify this bandwidth.

{p 4 8}{cmd:scalepar(}{it:#}{cmd:)} specifies a scaling factor for the RD/RK parameter of interest. The same option is available in {cmd:rdrobust} as per Calonico, Cattaneo, Titiunik (2014b).
Default is {cmd:scalepar(1)}.

{p 4 8}{cmd:twosided}. If specified, the program looks for separate polynomial orders and bandwidths on two sides of the threshold, which need to be specified in {cmd:pl()}, {cmd:pr()}, {cmd:hl()}, {cmd:hr()}, {cmd:bl()}, and {cmd:br()}. The program returns the estimated mean squared error for the conventional and bias-corrected estimator of the left and right derivatives of order {it:deriv}, respectively. The two-sided bandwidths can be obtained by specifing the {cmd:bwselect(}{it:msetwo}{cmd:)} option in {cmd:rdrobust}. The twosided option can only be used in a sharp RD/RK design (more in Additional Notes below). See Calonico, Cattaneo, Farrell, Titiunik (2017, 2019) for details.

{p 4 8}{cmd:pl(}{it:#}{cmd:)} and {cmd:pr(}{it:#}{cmd:)} specify the orders of the local polynomials on the left and right sides of the threshold, respectively. Default is {cmd:pl(1)} and {cmd:pr(1)} (local linear regressions). Consistent with the implementation in {cmd:rdrobust}, the maximum value allowed is 8 for both orders. Local polynomials of order ({it:pl}+1) and ({it:pr}+1) are used to estimate the biases of the left- and right-side estimators.

{p 4 8}{cmd:hl(}{it:#}{cmd:)} and {cmd:hr(}{it:#}{cmd:)} specify the main bandwidths used to construct the estimators of the left and right derivatives of order {it:deriv}. The user has to supply these bandwidths if the option {cmd:twoside} is specified.

{p 4 8}{cmd:bl(}{it:#}{cmd:)} and {cmd:br(}{it:#}{cmd:)} specify the bias bandwidths used to estimate the biases of the left- and right-side estimators. The user has to supply these bandwidths if the option {cmd:twoside} is specified.

    {hline}

{marker examples}{...}

{title:Example: Cattaneo, Frandsen and Titiunik (2015) Incumbency Data}

{p 4 8}This is the same demo dataset as that included in the {cmd: rdrobust} package. Load data{p_end}
{p 8 8}{cmd:. use rdrobust_senate.dta}{p_end}

{p 4 8}MSE estimation for local linear sharp RD estimator with uniform kernel and CCT bandwidths (Calonico, Cattaneo, Titiunik 2014a, 2014b){p_end}
{p 4 8}First estimate the CCT bandwidths using {cmd:altrdbwselect} included in the package{p_end}
{p 8 12}{cmd:. altrdbwselect vote margin, c(0) deriv(0) p(1) q(2) kernel(uniform) bwselect(CCT)}{p_end}
{p 8 12}{cmd:. local bw_h=r(h_CCT)}{p_end}
{p 8 12}{cmd:. local bw_b=r(b_CCT)}{p_end}
{p 4 8}Then estimate the MSE by passing the CCT bandwidths as arguments{p_end}
{p 8 12}{cmd:. rdmse vote margin, deriv(0) c(0) p(1) h(`bw_h') b(`bw_b') kernel(uniform)}{p_end}

{p 4 8}Estimate the MSE of a sharp local linear RD estimator with manual bandwidths{p_end}
{p 8 12}{cmd:. rdmse vote margin, deriv(0) c(0) p(1) h(10) b(20) kernel(uniform)}{p_end}

{p 4 8}Estimate the MSEs of the left- and right- intercept estimators constructed with different polynomial orders and bandwidths on two sides of the threshold{p_end}
{p 8 12}{cmd:. rdmse vote margin, c(0) deriv(0) twosided pl(1) pr(2) hl(10) hr(15) bl(20) br(30) kernel(uniform)}{p_end}  

{title:Generic Examples:}

{p 4 8}Let {cmd:Y} be the outcome variable and {cmd:x} the running variable:{p_end}

{p 4 8}Estimate the MSE of a sharp local linear RK estimator{p_end}
{p 8 12}{cmd:. rdmse Y x, deriv(1) c(0) p(1) h(10) b(20) kernel(uniform)}{p_end}

{p 4 8}Let {cmd:T} be the treatment variable.{p_end}

{p 4 8}MSE estimation for local linear fuzzy RD estimator with uniform kernel and "fuzzy CCT" bandwidths (Card, Lee, Pei, Weber 2015){p_end}
{p 4 8}First estimate the fuzzy CCT bandwidths using {cmd:altfrdbwselect} included in the package{p_end}
{p 8 12}{cmd:. altfrdbwselect Y x, c(0) fuzzy(T) deriv(0) p(1) q(2) kernel(uniform) bwselect(CCT)}{p_end}
{p 8 12}{cmd:. local fbw_h=r(h_F_CCT)}{p_end}
{p 8 12}{cmd:. local fbw_b=r(b_F_CCT)}{p_end}
{p 4 8}Then estimate the MSE by passing the "fuzzy CCT" bandwidths as arguments{p_end}
{p 8 12}{cmd:. rdmse Y x, c(0) fuzzy(T) deriv(0) p(1) h(`fbw_h') b(`fbw_b') kernel(uniform)}{p_end}

{p 4 8}Estimate the MSE of a fuzzy local linear RD estimator with manual bandwidths{p_end}
{p 8 12}{cmd:. rdmse Y x, fuzzy(T) deriv(0) c(0) p(1) h(10) b(20) kernel(uniform)}{p_end}

{p 4 8}Estimate the MSE of a fuzzy local linear RK estimator{p_end}
{p 8 12}{cmd:. rdmse Y x, fuzzy(T) deriv(1) c(0) p(1) h(10) b(20) kernel(uniform)}{p_end}

{marker saved_results}{...}
{title:Saved results}

{p 4 8}If {cmd:fuzzy()} and {cmd:twosided} are unspecified, {cmd:rdmse} saves the scalars:{p_end}
{synopt:{cmd:r(amse_cl)}}estimated (asymptotic) MSE of the conventional sharp estimator{p_end}
{synopt:{cmd:r(amse_bc)}}estimated (asymptotic) MSE of the bias-corrected sharp estimator{p_end} 

{p 4 8}If {cmd:twosided} is specified, {cmd:rdmse} saves the scalars:{p_end}
{synopt:{cmd:r(amse_l_cl)}}estimated (asymptotic) MSE of the conventional left-side estimator{p_end}
{synopt:{cmd:r(amse_l_bc)}}estimated (asymptotic) MSE of the bias-corrected left-side estimator{p_end}
{synopt:{cmd:r(amse_r_cl)}}estimated (asymptotic) MSE of the conventional right-side estimator{p_end}
{synopt:{cmd:r(amse_r_bc)}}estimated (asymptotic) MSE of the bias-corrected right-side estimator{p_end} 
	
{p 4 8}If {cmd:fuzzy()} is specified, {cmd:rdmse} saves the scalars:{p_end}
{synopt:{cmd:r(amse_F_cl)}}estimated (asymptotic) MSE of the conventional fuzzy estimator{p_end}
{synopt:{cmd:r(amse_F_bc)}}estimated (asymptotic) MSE of the bias-corrected fuzzy estimator{p_end}

{p 4 4}Since {cmd:rdmse_cct2014} only estimates the (asymptotic) MSE of the conventional estimator, it returns {cmd:r(amse_cl)} in the sharp case and {cmd:r(amse_F_cl)} in the fuzzy case.{p_end}

{title:Additional Notes}

{p 4 4}{cmd:altrdbwselect} is an alternative implementation of the CCT bandwidth selector from Calonico, Cattaneo, Titiunik (2014a). 
As with {cmd:rdmse}, it speeds up the computation in Calonico, Cattaneo, Titiunik (2014b) by adopting a random tie breaking scheme in variance estimation. The syntax is the same as {cmd:rdbwselect} in Calonico, Cattaneo, Titiunik (2014b).{p_end}

{p 4 4}In the current implementation of {cmd:rdrobust}, the two-sided bandwidths in a fuzzy design are optimal for estimating the left and right derivatives of order {it:deriv} in the the reduced-form relationship between the outcome variable and the running variable. In this spirit, we do not allow {cmd:twosided} to be specified in conjunction with {cmd:fuzzy()}, and the user should apply the {cmd:twosided} option to the reduced-form only by treating it as a sharp design.{p_end}

    {hline}
	
{title:References}

{p 4 8}Calonico, S., M. D. Cattaneo, and R. Titiunik. 2014a. Robust Nonparametric Confidence Intervals for Regression Discontinuity Designs. {it:Econometrica} 82(6): 2295-2326.
{browse "https://onlinelibrary.wiley.com/doi/abs/10.3982/ECTA11757"}.

{p 4 8}Calonico, S., M. D. Cattaneo, and R. Titiunik. 2014b. Robust Data Driven Inference in the Regression Discontinuity Design. {it:Stata Journal} 14(4): 909-946. 
{browse "https://journals.sagepub.com/doi/abs/10.1177/1536867X1401400413"}.

{p 4 8}Card, D., D. S. Lee, Z. Pei, and A. Weber. 2015. Inference on Causal Effects in a Generalized Regression Kink Design. {it:Econometrica} 83(6): 2453-2483.
{browse "https://onlinelibrary.wiley.com/doi/abs/10.3982/ECTA11224"}.

{p 4 8}Calonico, S., M. D. Cattaneo, M. H. Farrell, and R. Titiunik. 2017. {cmd:rdrobust}: Software for Regression-Discontinuity Designs. {it:Stata Journal} 17(2): 372-404. 
{browse "https://journals.sagepub.com/doi/abs/10.1177/1536867X1701700208"}.

{p 4 8}Calonico, S., M. D. Cattaneo, M. H. Farrell, and R. Titiunik. 2019. Regression Discontinuity Designs Using Covariates. {it:Review of Economics and Statistics} 101(3): 442-451.
{browse "https://www.mitpressjournals.org/doi/abs/10.1162/rest_a_00760"}.

{p 4 8}Cattaneo, M. D., B. Frandsen, and R. Titiunik. 2015. Randomization Inference in the Regression Discontinuity Design: An Application to Party Advantages in the U.S. Senate. {it:Journal of Causal Inference} 3(1): 1-24.
{browse "https://www.degruyter.com/document/doi/10.1515/jci-2013-0010"}.

{p 4 8}Pei, Z., D. S. Lee, C. Card, and A. Weber. 2022. Local Polynomial Order in Regression Discontinuity Designs. {it: Journal of Business and Economic Statistics} 40(3): 1259-1267.
{browse "https://www.tandfonline.com/doi/full/10.1080/07350015.2021.1920961"}.

{title:Author}

{p 4 8}Zhuan Pei, Cornell University, Ithaca, NY.
{browse "mailto:zhuan.pei@cornell.edu":zhuan.pei@cornell.edu}.



