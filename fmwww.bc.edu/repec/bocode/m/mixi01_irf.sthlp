{smcl}
{* *! version 1.0.0  20may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)}{...}
{vieweralsosee "mixi01" "help mixi01"}{...}
{vieweralsosee "mixi01_fmols" "help mixi01_fmols"}{...}
{vieweralsosee "mixi01_fmvar" "help mixi01_fmvar"}{...}
{vieweralsosee "mixi01_fmiv" "help mixi01_fmiv"}{...}
{vieweralsosee "mixi01_acl"  "help mixi01_acl"}{...}
{vieweralsosee "mixi01_svar" "help mixi01_svar"}{...}
{vieweralsosee "mixi01_vecm" "help mixi01_vecm"}{...}
{vieweralsosee "mixi01_test" "help mixi01_test"}{...}
{viewerjumpto "Syntax" "mixi01_irf##syntax"}{...}
{viewerjumpto "Description" "mixi01_irf##description"}{...}
{viewerjumpto "Options" "mixi01_irf##options"}{...}
{viewerjumpto "Remarks" "mixi01_irf##remarks"}{...}
{viewerjumpto "Examples" "mixi01_irf##examples"}{...}
{viewerjumpto "Stored results" "mixi01_irf##stored"}{...}
{viewerjumpto "References" "mixi01_irf##references"}{...}
{viewerjumpto "Author"     "mixi01_irf##author"}{...}
{viewerjumpto "Also see"   "mixi01_irf##alsosee"}{...}

{title:Title}

{p2colset 5 24 26 2}{...}
{p2col :{hi:mixi01_irf} {hline 2}}Impulse responses and variance decompositions{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 20 2}
{cmd:mixi01_irf}
[{cmd:,}
{it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Horizon}
{synopt :{opt step(#)}}forecast horizon; default: {cmd:step(40)}{p_end}

{syntab:Selection}
{synopt :{opt shock(numlist)}}which shock(s) to plot (equation indices){p_end}
{synopt :{opt response(numlist)}}which response variable(s) to plot{p_end}

{syntab:Confidence intervals}
{synopt :{opt ci}}compute bootstrap confidence intervals{p_end}
{synopt :{opt nreps(#)}}number of bootstrap replications; default: {cmd:nreps(500)}{p_end}
{synopt :{opt l:evel(real 95)}}CI level{p_end}

{syntab:Display}
{synopt :{opt fevd}}plot FEVD instead of IRF{p_end}
{synopt :{opt perm:anent}}overlay permanent component{p_end}
{synopt :{opt com:bine}}combine all subplots into one graph{p_end}
{synopt :{opt nograph}}suppress graphical output{p_end}

{syntab:Graph appearance}
{synopt :{opt scheme(string)}}graph scheme; default: {cmd:s2color}{p_end}
{synopt :{opt save(string)}}save graph to file{p_end}
{synopt :{opt title(string)}}overall graph title{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:mixi01_irf} is a post-estimation command that computes and plots impulse
response functions (IRFs) and forecast error variance decompositions (FEVDs)
using results stored by {helpb mixi01_svar} or {helpb mixi01_fmvar}.

{pstd}
{bf:IRF computation.}  IRFs are computed via the companion-matrix recursion:

{p 8 8 2}
Phi_h = J * C^h * J' * P

{pstd}
where C is the (np × np) companion matrix of the VAR, J = [I_n, 0] selects the
first n rows, and P is the structural impact matrix (A_0^{−1} if structural
identification is available, or the Cholesky factor of Sigma otherwise).

{pstd}
{bf:FEVD computation.}  The contribution of shock s to the h-step-ahead
forecast error variance of variable r is:

{p 8 8 2}
FEVD_{r,s}(h) = sum_{l=0}^{h} Phi_l(r,s)^2 / sum_{j=1}^{n} sum_{l=0}^{h} Phi_l(r,j)^2

{pstd}
{bf:Bootstrap CIs.}  When {cmd:ci} is specified, bootstrap confidence intervals
are computed using a residual resampling procedure.  For each of {cmd:nreps()}
replications, residuals are redrawn (with replacement), the data are
reconstructed, the FM-VAR/SVAR is re-estimated, and IRFs are recomputed.
Percentile bands are then reported at the specified confidence level.


{marker options}{...}
{title:Options}

{dlgtab:Horizon}

{phang}
{opt step(#)} sets the forecast horizon for the IRF/FEVD.

{dlgtab:Selection}

{phang}
{opt shock(numlist)} specifies which shocks to plot by equation index.
Default: all shocks.

{phang}
{opt response(numlist)} specifies which response variables to plot.
Default: all variables.

{dlgtab:Confidence intervals}

{phang}
{opt ci} activates bootstrap confidence intervals.

{phang}
{opt nreps(#)} sets the number of bootstrap replications.

{phang}
{opt level(#)} sets the CI level.

{dlgtab:Display}

{phang}
{opt fevd} plots FEVDs instead of IRFs.  The FEVD is displayed as stacked
area charts, with different colours for each shock type (P1, T1, P0, T0).

{phang}
{opt permanent} overlays the permanent component Delta y^P_t on the IRF
plot.  Requires prior estimation via {helpb mixi01_svar} with the permanent
component stored.

{phang}
{opt combine} places all response–shock subplots into a single combined
graph arranged in a grid.

{phang}
{opt nograph} suppresses graphical output; only the IRF/FEVD data are
computed and stored.

{dlgtab:Graph appearance}

{phang}
{opt scheme(string)} specifies the graph scheme.

{phang}
{opt save(string)} saves the combined graph to the specified file.
Supported formats: .png, .pdf, .eps, .wmf.

{phang}
{opt title(string)} sets the main title for the combined graph.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:IRF plot design.}  Each subplot shows:

{p 8 12 2}
• A {it:navy} line for the point estimate of the impulse response.{break}
• A {it:gray} shaded area ({cmd:rarea}) for the bootstrap confidence band.{break}
• A dashed horizontal line at zero.{break}
• A subtitle indicating the shock type (P1, T1, P0, T0) from the Fisher–Huh–Pagan classification.

{pstd}
{bf:FEVD plot design.}  Each subplot is a stacked area chart showing the
decomposition of forecast error variance across shocks over the horizon.
Colours distinguish the four shock types:

{p 8 12 2}
P1 shocks: navy{break}
T1 shocks: maroon{break}
P0 shocks: forest green{break}
T0 shocks: dark orange

{pstd}
{bf:Data access.}  After running {cmd:mixi01_irf}, the IRF/FEVD data are
available in the current (preserved) dataset.  Variables are named
{cmd:irf_}{it:r}_{cmd:_}{it:s}, {cmd:irf_lo_}{it:r}_{cmd:_}{it:s}, and
{cmd:irf_hi_}{it:r}_{cmd:_}{it:s} for response {it:r} to shock {it:s}.
Use {cmd:restore} to return to the original dataset.


{marker examples}{...}
{title:Examples}

{dlgtab:Example 1: Basic IRFs with bootstrap CIs}

{phang2}{cmd:. mixi01_svar y1 y2 y3 y4, lags(2) i1(y1 y2 y3) i0(y4) p1(1) t1(2 3) p0(4) cholesky}{p_end}
{phang2}{cmd:. mixi01_irf, step(40) ci nreps(500) combine}{p_end}

{dlgtab:Example 2: FEVD plot}

{phang2}{cmd:. mixi01_irf, step(40) fevd combine save("fevd_plot.png")}{p_end}

{dlgtab:Example 3: Selected shocks and responses}

{phang2}{cmd:. mixi01_irf, step(24) shock(1 4) response(1 2) ci nreps(200) combine}{p_end}

{dlgtab:Example 4: IRF without graph (data only)}

{phang2}{cmd:. mixi01_irf, step(60) nograph}{p_end}
{phang2}{cmd:. list horizon irf_1_1 irf_2_1 in 1/10}{p_end}


{marker stored}{...}
{title:Stored results}

{pstd}
{cmd:mixi01_irf} stores the following in {cmd:e()}:

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt :{cmd:e(irf_step)}}forecast horizon{p_end}
{synopt :{cmd:e(irf_nreps)}}number of bootstrap replications{p_end}
{synopt :{cmd:e(irf_level)}}CI level{p_end}

{p2col 5 24 28 2: Macros}{p_end}
{synopt :{cmd:e(irf_cmd)}}{cmd:mixi01_irf}{p_end}

{pstd}
IRF/FEVD data are stored in the current dataset as variables:

{synoptset 24 tabbed}{...}
{synopt :{cmd:horizon}}time horizon (0, 1, ..., step){p_end}
{synopt :{cmd:irf_}{it:r}{cmd:_}{it:s}}IRF of response {it:r} to shock {it:s}{p_end}
{synopt :{cmd:irf_lo_}{it:r}{cmd:_}{it:s}}lower CI bound{p_end}
{synopt :{cmd:irf_hi_}{it:r}{cmd:_}{it:s}}upper CI bound{p_end}
{synopt :{cmd:fevd_}{it:r}{cmd:_}{it:s}}FEVD contribution of shock {it:s} to variable {it:r}{p_end}


{marker references}{...}
{title:References}

{phang}
Fisher, L. A., H.-S. Huh and A. R. Pagan (2016).  Econometric methods for
modelling systems with a mixture of I(1) and I(0) variables.
{it:Journal of Applied Econometrics}, 31(5), 892–911.
{p_end}

{phang}
Lütkepohl, H. (2006).  {it:New Introduction to Multiple Time Series
Analysis}.  Berlin: Springer.
{p_end}

{phang}
Phillips, P. C. B. (1995).  Fully modified least squares and vector
autoregression.  {it:Econometrica}, 63(5), 1023–1078.
{p_end}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
Department of Economics (Independent Researcher){break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}
{p_end}


{marker alsosee}{...}
{title:Also see}

{pstd}
Master help — {helpb mixi01}.
{p_end}

{pstd}
Sibling commands — {helpb mixi01_fmols}, {helpb mixi01_fmvar},
{helpb mixi01_fmiv}, {helpb mixi01_acl}, {helpb mixi01_svar},
{helpb mixi01_vecm}, {helpb mixi01_irf}, {helpb mixi01_test}.
{p_end}
