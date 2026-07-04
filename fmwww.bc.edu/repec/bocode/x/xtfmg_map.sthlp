{smcl}
{* *! version 1.0.0  03jul2026}{...}
{vieweralsosee "xtfmg" "help xtfmg"}{...}
{vieweralsosee "xtfmg fccemg" "help xtfmg_fccemg"}{...}
{vieweralsosee "xtfmg fsurmg" "help xtfmg_fsurmg"}{...}
{vieweralsosee "xtfmg breaks" "help xtfmg_breaks"}{...}
{viewerjumpto "Syntax" "xtfmg_map##syntax"}{...}
{viewerjumpto "Description" "xtfmg_map##description"}{...}
{viewerjumpto "Stored results" "xtfmg_map##results"}{...}
{viewerjumpto "Examples" "xtfmg_map##examples"}{...}

{title:Title}

{phang}
{bf:xtfmg map} {hline 2} cross-sectional dependence diagnostics and
regime-map estimator recommendation


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xtfmg map} {depvar} {indepvars} {ifin}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtfmg map} runs the Mean Group regressions, computes from their
residuals the Pesaran CD statistic and the Bailey-Kapetanios-Pesaran (2016)
exponent of cross-sectional dependence alpha (simple estimator on
standardized residuals), classifies the panel's dependence regime, and
prints the regime map of Guliyev (2026) together with the recommended
estimator:

{phang2}o{space 2}{bf:weak} dependence (alpha < 0.5): with very small N
(< 10), F-SURMG gives the best-calibrated inference; otherwise F-CCEMG is
already the most accurate.{p_end}
{phang2}o{space 2}{bf:moderate} dependence (0.5 <= alpha < 0.85): F-CCEMG
attains the lowest RMSE at every sample size and near-nominal coverage once
N >= 10. This is the regime of the paper's G7 application
(alpha = 0.732).{p_end}
{phang2}o{space 2}{bf:strong} dependence (alpha >= 0.85): non-filtering
estimators fail; with large N, plain CCEMG is fully competitive and F-CCEMG
adds an accuracy refinement.{p_end}

{pstd}
If alpha cannot be estimated, the classification falls back on the CD test:
a CD p-value above 0.05 is classified as weak dependence.

{pstd}
The classification thresholds are working conventions consistent with the
discussion in Bailey, Kapetanios and Pesaran (2016) and the simulation
regimes of Guliyev (2026); they are a guide, not a formal test.


{marker results}{...}
{title:Stored results}

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(N)}, {cmd:r(Tbar)}, {cmd:r(n)}}panel dimensions{p_end}
{synopt:{cmd:r(cd)}, {cmd:r(cd_p)}}Pesaran CD statistic and p-value{p_end}
{synopt:{cmd:r(alpha)}}CSD exponent{p_end}

{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(regime)}}{cmd:weak}, {cmd:moderate} or {cmd:strong}{p_end}
{synopt:{cmd:r(recommend)}}recommended estimator{p_end}


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. xtset company year}{p_end}
{phang2}{cmd:. xtfmg map invest mvalue kstock}{p_end}
{phang2}{cmd:. di "`r(recommend)'"}{p_end}


{title:References}

{phang}Bailey, N., G. Kapetanios, and M. H. Pesaran. 2016. Exponent of
cross-sectional dependence: Estimation and inference.
{it:Journal of Applied Econometrics} 31: 929-960.{p_end}
{phang}Guliyev, H. 2026. Second-generation heterogeneous panel data model
with individual and common shocks. arXiv:2606.29063.{p_end}


{title:Author}

{pstd}
Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane"}
{p_end}
