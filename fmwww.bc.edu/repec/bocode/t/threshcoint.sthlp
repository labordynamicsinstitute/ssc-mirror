{smcl}
{* *! version 1.2  16may2026}{...}
{viewerjumpto "Syntax"             "threshcoint##syntax"}{...}
{viewerjumpto "Description"        "threshcoint##description"}{...}
{viewerjumpto "Unit-root tests"    "threshcoint##unitroot"}{...}
{viewerjumpto "Threshold tests"    "threshcoint##tests"}{...}
{viewerjumpto "Models"             "threshcoint##models"}{...}
{viewerjumpto "Utilities"          "threshcoint##utils"}{...}
{viewerjumpto "Visualization"      "threshcoint##plots"}{...}
{viewerjumpto "Examples"           "threshcoint##examples"}{...}
{viewerjumpto "Stored results"     "threshcoint##stored"}{...}
{viewerjumpto "References"         "threshcoint##refs"}{...}
{viewerjumpto "Author"             "threshcoint##author"}{...}

{title:Title}

{phang}
{bf:threshcoint} {hline 2} Threshold cointegration tests and models for Stata


{marker syntax}{...}
{title:Syntax}

{pstd}
Each individual command is callable as {cmd:tc_<name>} (for example
{helpb tc_es}, {helpb tc_glsmtar}, {helpb tc_tvecm}).
All commands are {bf:rclass} -- results are returned in {cmd:r()}.

{marker description}{...}
{title:Description}

{pstd}
{cmd:threshcoint} is a Stata implementation of every major threshold
cointegration test and model from the econometrics literature. All
numerics run in Mata. No bootstrap is required for the tabulated tests --
asymptotic / finite-sample critical values are bundled.

{pstd}
The library is a direct port of the Python {bf:threshcoint} library by
Dr Merwan Roudane and consolidates methods from twelve academic papers
and three R packages ({bf:tsDyn}, {bf:NonlinearTSA}, plus the original
{it:supF.r} script).


{marker unitroot}{...}
{title:Unit-root and linear cointegration tests}

{synoptset 18 tabbed}{...}
{synopt:{helpb tc_adf}}Augmented Dickey-Fuller unit-root test{p_end}
{synopt:{helpb tc_pp}}Phillips-Perron unit-root test{p_end}
{synopt:{helpb tc_eg}}Engle-Granger residual-based cointegration test{p_end}
{synoptline}


{marker tests}{...}
{title:Threshold cointegration tests}

{synoptset 18 tabbed}{...}
{synopt:{helpb tc_es}}Enders & Siklos (2001) TAR / MTAR{p_end}
{synopt:{helpb tc_glsmtar}}Cook (2007) GLS-MTAR{p_end}
{synopt:{helpb tc_exes}}Extended Enders-Siklos (Osinska & Galecki 2022){p_end}
{synopt:{helpb tc_covaug}}Covariates-augmented (Oh, Lee & Meng 2017){p_end}
{synopt:{helpb tc_bf}}Balke-Fomby (1997) sup-Wald{p_end}
{synopt:{helpb tc_adlbdm}}Li & Lee (2010) ADL-BDM{p_end}
{synopt:{helpb tc_adlbo}}Li & Lee (2010) ADL-BO (Boswijk){p_end}
{synopt:{helpb tc_sysadl}}Li (2016) system-equation ADL{p_end}
{synopt:{helpb tc_supf}}Schweikert (2019) supF* with structural break{p_end}
{synopt:{helpb tc_hs}}Hansen-Seo (2002) supLM (linear vs threshold VECM){p_end}
{synopt:{helpb tc_kss}}KSS (2006) nonlinear cointegration (ESTAR){p_end}
{synopt:{helpb tc_bbc}}Bec-Ben Salem-Carrasco (2004) unit root vs SETAR{p_end}
{synoptline}


{marker models}{...}
{title:Threshold models}

{synoptset 18 tabbed}{...}
{synopt:{helpb tc_tar}}TAR / MTAR model fit on cointegrating residuals{p_end}
{synopt:{helpb tc_eqtar}}EQ-TAR / Band-TAR / RD-TAR (3-regime Balke-Fomby){p_end}
{synopt:{helpb tc_setar}}SETAR(2) self-exciting threshold AR{p_end}
{synopt:{helpb tc_tvecm}}TVECM -- Threshold Vector Error-Correction Model{p_end}
{synoptline}


{marker utils}{...}
{title:Utilities}

{synoptset 18 tabbed}{...}
{synopt:{helpb tc_compare}}Run a panel of tests and print a comparison table{p_end}
{synopt:{helpb tc_plot}}Regime, grid-search and ECT visualizations{p_end}
{synoptline}


{marker plots}{...}
{title:Visualization}

{p 8 16 2}
{helpb tc_plot##regime:tc_plot regime} {it:resvar} [{cmd:,} {opt threshold(#)} {opt model(tar|mtar)} {opt title()} {opt saving()}]

{p 8 16 2}
{helpb tc_plot##grid:tc_plot grid}   [{cmd:,} {opt title()} {opt saving()}]

{p 8 16 2}
{helpb tc_plot##ect:tc_plot ect}    {it:ectvar} [{cmd:,} {opt threshold(#)} {opt title()} {opt saving()}]


{marker examples}{...}
{title:Examples}

{phang}{stata "use https://www.stata-press.com/data/r17/lutkepohl2.dta, clear"}{p_end}
{phang}{stata "tsset qtr"}{p_end}
{phang}{stata "tc_adf ln_inv, case(c)"}{p_end}
{phang}{stata "tc_eg ln_inv ln_inc, case(c)"}{p_end}
{phang}{stata "tc_es ln_inv ln_inc, model(mtar) maxlag(6)"}{p_end}
{phang}{stata "tc_glsmtar ln_inv ln_inc, case(c)"}{p_end}
{phang}{stata "tc_supf ln_inv ln_inc, breaktype(4) maxlag(4) model(tar)"}{p_end}
{phang}{stata "tc_hs ln_inv ln_inc, lag(2)"}{p_end}
{phang}{stata "tc_tvecm ln_inv ln_inc, lag(1)"}{p_end}
{phang}{stata "tc_compare ln_inv ln_inc, maxlag(6)"}{p_end}
{phang}{stata "tc_plot grid"}{p_end}


{marker stored}{...}
{title:Stored results}

{pstd}
All commands store results in {cmd:r()}:

{synoptset 26 tabbed}{...}
{synopt:{cmd:r(stat)} / {cmd:r(phi_stat)} / {cmd:r(f_star)} / ...}primary test statistic{p_end}
{synopt:{cmd:r(rho1)}, {cmd:r(rho2)}}regime-specific adjustment coefficients{p_end}
{synopt:{cmd:r(threshold)}}estimated or specified threshold{p_end}
{synopt:{cmd:r(lags)}}selected lag order{p_end}
{synopt:{cmd:r(nregime1)}, {cmd:r(nregime2)}}observations per regime{p_end}
{synopt:{cmd:r(cv)}}row vector of critical values {it:(cv01, cv05, cv10)}{p_end}
{synopt:{cmd:r(grid_values)}, {cmd:r(grid_stats)}}grid for sup-type tests{p_end}
{synopt:{cmd:r(coint_vec)}}cointegrating vector ({helpb tc_eg}){p_end}
{synopt:{cmd:r(ect)}}lagged ECT vector ({helpb tc_tvecm}){p_end}
{synoptline}


{marker refs}{...}
{title:References}

{phang}Balke N.S. & Fomby T.B. (1997). Threshold cointegration. {it:Int. Econ. Review} 38, 627-645. ({helpb tc_bf}){p_end}
{phang}Bec F., Ben Salem M. & Carrasco M. (2004). Tests for unit-root versus threshold specification. {it:JBES} 22(4). ({helpb tc_bbc}){p_end}
{phang}Cook S. (2007). A threshold cointegration test with increased power. {it:Math & Comput. Simul.} 73, 386-392. ({helpb tc_glsmtar}){p_end}
{phang}Enders W. & Siklos P.L. (2001). Cointegration and threshold adjustment. {it:JBES} 19(2), 166-176. ({helpb tc_es}){p_end}
{phang}Hansen B.E. & Seo B. (2002). Testing for two-regime threshold cointegration in VECMs. {it:J. Econometrics} 110, 293-318. ({helpb tc_hs}){p_end}
{phang}Kapetanios G., Shin Y. & Snell A. (2006). Testing for cointegration in nonlinear STAR ECM. {it:Econometric Theory} 22, 279-303. ({helpb tc_kss}){p_end}
{phang}Li J. & Lee J. (2010). ADL tests for threshold cointegration. {it:J. Time Series Analysis} 31, 241-254. ({helpb tc_adlbdm}, {helpb tc_adlbo}){p_end}
{phang}Li J. (2016). System-equation ADL test for threshold cointegration. {it:OBES}. ({helpb tc_sysadl}){p_end}
{phang}Oh D.Y., Lee H. & Meng M. (2017). More powerful threshold cointegration tests. {it:Empirical Economics}. ({helpb tc_covaug}){p_end}
{phang}Osinska M. & Galecki J. (2022). Extended Enders and Siklos test. {it:Statistical Review} 69(1), 1-20. ({helpb tc_exes}){p_end}
{phang}Schweikert K. (2019). Testing for cointegration with threshold adjustment in the presence of structural breaks. {it:SNDE}. ({helpb tc_supf}){p_end}


{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{p_end}
{pstd}Email: merwanroudane920@gmail.com{p_end}
{pstd}GitHub: {browse "https://github.com/merwanroudane/threshcoint":merwanroudane/threshcoint}{p_end}
