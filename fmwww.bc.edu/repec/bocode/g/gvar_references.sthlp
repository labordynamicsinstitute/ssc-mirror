{smcl}
{* *! version 1.0.1  21aug2026}{...}
{vieweralsosee "gvar" "help gvar"}{...}
{vieweralsosee "gvar methods" "help gvar_methods"}{...}
{vieweralsosee "gvar bayes" "help gvar_bayes"}{...}
{vieweralsosee "gvar estimate" "help gvar_estimate"}{...}
{vieweralsosee "gvar irf" "help gvar_irf"}{...}
{vieweralsosee "gvar spillover" "help gvar_spillover"}{...}
{vieweralsosee "gvar stability" "help gvar_stability"}{...}
{viewerjumpto "The GVAR model" "gvar_references##gvar"}{...}
{viewerjumpto "Estimation and inference" "gvar_references##est"}{...}
{viewerjumpto "Bayesian methods" "gvar_references##bayes"}{...}
{viewerjumpto "Connectedness" "gvar_references##conn"}{...}
{viewerjumpto "Structural change" "gvar_references##break"}{...}
{viewerjumpto "Software this package follows" "gvar_references##software"}{...}
{title:Title}

{phang}
{bf:gvar references} {hline 2} works cited in the {cmd:gvar} documentation


{pstd}
Every author-year citation in this package's help files resolves here. Entries
are grouped by what they are cited for, and each carries the digital object
identifier where one exists, so a reader can go from a claim in a help page to
the paper that supports it in one step.


{marker gvar}{...}
{title:The GVAR model}

{phang}
Pesaran, M. H., T. Schuermann and S. M. Weiner. 2004.
Modeling regional interdependencies using a global error-correcting
macroeconometric model.
{it:Journal of Business & Economic Statistics} 22(2): 129-162.
{browse "https://doi.org/10.1198/073500104000000019":doi:10.1198/073500104000000019}.

{pmore}
The original GVAR: country-specific error-correcting models linked by
trade-weighted foreign variables. The construction of {it:x*} in
{helpb gvar_foreign:gvar foreign} and the link matrices in
{helpb gvar_weights:gvar weights} follow this paper.

{phang}
Dees, S., F. di Mauro, M. H. Pesaran and L. V. Smith. 2007.
Exploring the international linkages of the euro area: a global VAR analysis.
{it:Journal of Applied Econometrics} 22(1): 1-38.
{browse "https://doi.org/10.1002/jae.932":doi:10.1002/jae.932}.

{pmore}
Referred to throughout as DdPS(2007). The source of the weak-exogeneity F test
in {helpb gvar_wetest:gvar wetest}, of the device that makes a global variable
endogenous in one country ({opt gendog()} in {helpb gvar_setup:gvar setup}), and
of the 26-country specification shipped as the demo.


{marker est}{...}
{title:Estimation and inference}

{phang}
Pesaran, M. H., Y. Shin and R. J. Smith. 2000.
Structural analysis of vector error correction models with exogenous I(1)
variables.
{it:Journal of Econometrics} 97(2): 293-343.

{pmore}
The VECMX* framework: reduced-rank ML with weakly exogenous I(1) regressors, and
the cointegration critical values used by {helpb gvar_coint:gvar coint}. The
five deterministic cases of {opt case()} are this paper's.

{phang}
Pesaran, M. H. and Y. Shin. 1998.
Generalized impulse response analysis in linear multivariate models.
{it:Economics Letters} 58(1): 17-29.

{pmore}
The generalized impulse responses of {helpb gvar_irf:gvar irf} and the
generalized decompositions of {helpb gvar_fevd:gvar fevd}, which do not require
an ordering of the variables.


{marker bayes}{...}
{title:Bayesian methods}

{phang}
Crespo Cuaresma, J., M. Feldkircher and F. Huber. 2016.
Forecasting with global vector autoregressive models: a Bayesian approach.
{it:Journal of Applied Econometrics} 31(7): 1371-1391.
{browse "https://doi.org/10.1002/jae.2504":doi:10.1002/jae.2504}.

{phang}
Boeck, M., M. Feldkircher and F. Huber. 2022.
BGVAR: Bayesian global vector autoregressions with shrinkage priors in R.
{it:Journal of Statistical Software} 104(9): 1-28.
{browse "https://doi.org/10.18637/jss.v104.i09":doi:10.18637/jss.v104.i09}.

{pmore}
The companion paper to the R package this package's Bayesian branch follows.
The Minnesota, SSVS, Normal-Gamma and Horseshoe priors of
{helpb gvar_bayes:gvar bayes} are the four it implements.

{phang}
Kastner, G. and S. Fruehwirth-Schnatter. 2014.
Ancillarity-sufficiency interweaving strategy (ASIS) for boosting MCMC
estimation of stochastic volatility models.
{it:Computational Statistics & Data Analysis} 76: 408-423.
{browse "https://doi.org/10.1016/j.csda.2013.01.002":doi:10.1016/j.csda.2013.01.002}.

{pmore}
The target for {opt sv} in {helpb gvar_bayes:gvar bayes}. This package uses the
standard mixture sampler rather than the interweaved one, so mixing may be
slower -- which is what {helpb gvar_bconv:gvar bconv} is for.

{phang}
Geweke, J. 1992.
Evaluating the accuracy of sampling-based approaches to calculating posterior
moments. In {it:Bayesian Statistics 4}, ed. J. M. Bernardo, J. O. Berger,
A. P. Dawid and A. F. M. Smith. Oxford: Clarendon Press.

{pmore}
The convergence diagnostic reported by {helpb gvar_bconv:gvar bconv}.

{phang}
Spiegelhalter, D. J., N. G. Best, B. P. Carlin and A. van der Linde. 2002.
Bayesian measures of model complexity and fit.
{it:Journal of the Royal Statistical Society, Series B} 64(4): 583-639.

{pmore}
The deviance information criterion and the effective number of parameters
computed by {helpb gvar_bdic:gvar bdic}.


{marker conn}{...}
{title:Connectedness}

{phang}
Diebold, F. X. and K. Yilmaz. 2014.
On the network topology of variance decompositions: measuring the connectedness
of financial firms.
{it:Journal of Econometrics} 182(1): 119-134.
{browse "https://doi.org/10.1016/j.jeconom.2014.04.012":doi:10.1016/j.jeconom.2014.04.012}.

{pmore}
The connectedness table of {helpb gvar_spillover:gvar spillover}: directional
to and from each unit, and the total connectedness index.


{marker break}{...}
{title:Structural change}

{phang}
Zeileis, A., F. Leisch, K. Hornik and C. Kleiber. 2002.
strucchange: an R package for testing for structural change in linear
regression models.
{it:Journal of Statistical Software} 7(2): 1-38.
{browse "https://doi.org/10.18637/jss.v007.i02":doi:10.18637/jss.v007.i02}.

{phang}
Zeileis, A., C. Kleiber, W. Kraemer and K. Hornik. 2003.
Testing and dating of structural changes in practice.
{it:Computational Statistics & Data Analysis} 44(1-2): 109-123.
{browse "https://doi.org/10.1016/S0167-9473(03)00030-6":doi:10.1016/S0167-9473(03)00030-6}.

{pmore}
The empirical fluctuation process family behind
{helpb gvar_stability:gvar stability}.


{marker software}{...}
{title:Software this package follows}

{pstd}
This package is a port. Where a computation could be read from a reference
implementation rather than inferred from a paper, it was; the help page for each
command names the file it follows under its {bf:Source} heading.

{p 8 8 2}
{bf:GVAR Toolbox 2.0} (August 2014), L. V. Smith and A. Galesi. MATLAB. The
source for estimation, the weak-exogeneity test, the dominant unit model and the
bootstrap.{p_end}

{p 8 8 2}
{bf:BGVAR} 2.6.0, M. Boeck, M. Feldkircher and F. Huber. R. The source for the
Bayesian branch -- priors, stochastic volatility, and the DIC.{p_end}

{p 8 8 2}
{bf:GVARX} 1.2. R. Consulted for the GVAR estimation interface.{p_end}

{p 8 8 2}
{bf:vars} 1.6-1, B. Pfaff. R. See Pfaff, B. 2008. VAR, SVAR and SVEC models:
implementation within R package vars. {it:Journal of Statistical Software}
27(4). Consulted for the VAR diagnostics.{p_end}

{p 8 8 2}
{bf:strucchange} 1.6-0, A. Zeileis et al. R. The source for the fluctuation
tests, as cited above.{p_end}

{pstd}
Where this package's output does not reproduce a reference implementation's,
that is documented rather than hidden: see
{help gvar_methods##wedev:gvar methods, "Weak exogeneity: a known deviation"}.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
