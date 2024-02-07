{smcl}
{* *! version 1.4.2  06feb2024}{...}
{* *! Sebastian Kripfganz, www.kripfganz.de}{...}
{* *! Vasilis Sarafidis, sites.google.com/view/vsarafidis}{...}
{vieweralsosee "spxtivdfreg postestimation" "help spxtivdfreg_postestimation"}{...}
{vieweralsosee "xtivdfreg" "help xtivdfreg"}{...}
{vieweralsosee "xtivdfreg postestimation" "help xtivdfreg_postestimation"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] regress" "help regress"}{...}
{vieweralsosee "[R] ivregress" "help ivregress"}{...}
{vieweralsosee "[XT] xtreg" "help xtreg"}{...}
{vieweralsosee "[XT] xtivreg" "help xtivreg"}{...}
{vieweralsosee "[XT] xtset" "help xtset"}{...}
{vieweralsosee "[SP] SP Intro" "help sp_intro"}{...}
{viewerjumpto "Syntax" "spxtivdfreg##syntax"}{...}
{viewerjumpto "Description" "spxtivdfreg##description"}{...}
{viewerjumpto "Options" "spxtivdfreg##options"}{...}
{viewerjumpto "Remarks" "spxtivdfreg##remarks"}{...}
{viewerjumpto "Example" "spxtivdfreg##example"}{...}
{viewerjumpto "Saved results" "spxtivdfreg##results"}{...}
{viewerjumpto "Authors" "spxtivdfreg##authors"}{...}
{viewerjumpto "References" "spxtivdfreg##references"}{...}
{title:Title}

{p2colset 5 20 22 2}{...}
{p2col :{bf:spxtivdfreg} {hline 2}}Defactored IV estimation of large spatial panel data models{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}{cmd:spxtivdfreg} {depvar} [{indepvars}] {ifin} [{cmd:,} {it:options}]


{synoptset 21 tabbed}{...}
{synopthdr:options}
{synoptline}
{syntab:Model}
{p2coldent :* {opt spmat:rix}{cmd:(}{it:{help spxtivdfreg##options_spec:spmat_spec}}{cmd:)}}specify spatial weights matrix{p_end}
{synopt:{opt spl:ag}}include spatial lag of {depvar}{p_end}
{synopt:{opt tl:ags(#)}}include time lags of {depvar}{p_end}
{synopt:{opt sptl:ags(#)}}include spatial time lags of {depvar}{p_end}
{synopt:{opth spind:epvars(varlist)}}include spatially lagged {indepvars}{p_end}
{synopt:{opt iv}{cmd:(}{it:{help spxtivdfreg##options_spec:iv_spec}}{cmd:)}}instruments; can be specified more than once{p_end}
{synopt:{it:{help spxtivdfreg##xtivdfreg_options:xtivdfreg_options}}}other options for {cmd:xtivdfreg} estimation{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}* The option {opt spmatrix()} is required.{p_end}

{marker options_spec}{...}
{p 4 6 2}
{it:spmat_spec} is

{p 8 12 2}
{it:matname}|{it:{help filename}} [{cmd:,} {opt sp:matrix}|{opt m:ata}|{opt st:ata}|{opt import} {it:import_options}]

{p 4 6 2}
{it:iv_spec} is

{p 8 12 2}
{varlist} [{cmd:,} {opt spl:ags} {opt sp:iv(spvarlist)} {opt fvar(fvars)} {opt l:ags(#)} {opt fact:max(#)} [{cmdab:no:}]{opt eig:ratio} [{cmd:no}]{opt std} [{cmdab:no:}]{opt double:defact}]

{p 4 6 2}
You must {cmd:xtset} your data before using {cmd:spxtivdfreg}; see {helpb xtset:[XT] xtset}. The panel data set must be strongly balanced.{p_end}
{p 4 6 2}
All {it:varlists} may contain factor variables; see {help fvvarlist}. This requires the community-contributed package {cmd:ftools} to be installed; see {helpb ftools}.{p_end}
{p 4 6 2}
{it:depvar} and all {it:varlists} may contain time-series operators; see {help tsvarlist}.{p_end}
{p 4 6 2}
{cmd:spxtivdfreg} is a wrapper for {helpb xtivdfreg}. See {helpb spxtivdfreg postestimation} for features available after estimation.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:spxtivdfreg} implements the instrumental variables (IV) estimator for large spatial panel data models, as developed by Cui, Sarafidis, and Yamagata (2023) and Chen, Cui, Sarafidis, and Yamagata (2023)
as an extension of Norkute, Sarafidis, Yamagata, and Cui (2021) and Cui, Norkute, Sarafidis, and Yamagata (2022) to models with spatial lags of the dependent and independent variables.
The instruments are defactored to control for a multifactor error structure. Heterogeneous slope coefficients can be allowed using a mean-group (MG) estimator.

{pstd}
The defactorization procedure and related options are explained in detail by Kripfganz and Sarafidis (2021, 2024); see {helpb xtivdfreg}.


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{cmd:spmatrix(}{it:matname}|{it:{help filename}} [{cmd:,} {opt sp:matrix}|{opt m:ata}|{opt st:ata}|{opt import} {it:import_options}]{cmd:)} specifies the spatial weights matrix.
The suboptions {opt spmatrix}, {opt mata}, or {opt stata} declare {it:matname} to be an SP matrix, a Mata matrix, or a Stata matrix, respectively.
Suboption {opt import} requests to import a matrix from {it:filename} (requires Stata version 14 or higher), which must be an Excel file or a delimited text file. {it:import_options} can be any options allowed with
{helpb import excel} or {helpb import delimited}, depending on the file type. {cmd:spmatrix} is the default; see {helpb spmatrix:[SP] spmatrix} (requires Stata version 15 or higher).

{phang}
{opt splag} requests to include a spatial lag of {it:depvar} as an additional regressor.

{phang}
{opt tlags(#)} requests to include {it:#} time lags of {it:depvar} as additional regressors. The default is {cmd:tlags(0)}.

{phang}
{opt sptlags(#)} requests to include {it:#} spatial time lags of {it:depvar} as additional regressors. The default is {cmd:sptlags(0)}.

{phang}
{opth spindepvars(varlist)} requests to include spatial lags of {it:varlist} as additional independent variables.

{phang}
{cmd:iv(}{varlist} [{cmd:,} {opt spl:ags} {opt sp:iv(spvarlist)} {opt fvar(fvars)} {opt l:ags(#)} {opt fact:max(#)} [{cmdab:no:}]{opt eig:ratio} [{cmd:no}]{opt std} [{cmdab:no:}]{opt double:defact}]{cmd:)} specifies instrumental variables.
One can specify as many sets of instruments as required. Variables in the same set are defactored jointly. External variables that are not part of the regression model can also be used as instruments in {it:varlist}.

{pmore}
{opt splags} adds spatial lags of all variables in {it:varlist} as additional instrumental variables. {opt splags} is equivalent to {opt spiv(varlist)}.

{pmore}
{opt spiv(spvarlist)} adds spatial lags of {it:spvarlist} as additional instrumental variables.

{pmore}
{opt fvar(fvars)} specifies that factors are extracted from the variables in {it:fvars}. The default is to extract factors from all variables in {it:varlist}.

{pmore}
{opt lags(#)} specifies the {it:#} of lags of {it:varlist} to be added to the set of instruments.
The variables at each lag order are defactored separately with factors extracted from the corresponding lag of {it:fvars}. The default is {cmd:lags(0)}.

{pmore}
{opt factmax(#)} specifies the maximum number of factors to be extracted from {it:fvars}. The default is set by the global option {opt factmax(#)}.

{pmore}
{opt noeigratio} and {opt eigratio} request to either use a fixed number of factors as specified with suboption {opt factmax(#)} or to use the Ahn and Horenstein (2013) eigenvalue ratio test to compute the number of factors.
{cmd:eigratio} is the default unless otherwise specified with the global option {cmd:noeigratio}.

{pmore}
{opt std} and {opt nostd} request to compute factors from either standardized or nonstandardized variables. {cmd:nostd} is the default unless otherwise specified with the global option {cmd:std}.

{pmore}
{opt doubledefact} requests to include {it:fvars} in a further defactorization stage of the entire model for the first-stage estimator. All sets of instruments that are included in this defactorization stage are jointly defactored,
excluding lags of {it:fvars} specified with suboption {opt lags(#)}. {opt nodoubledefact} requests to avoid implementing a further defactorization stage of the entire model for the first-stage estimator.
The default is set by the global option [{cmd:no}]{cmd:doubledefact}.

{marker xtivdfreg_options}{...}
{phang}
{it:xtivdfreg_options}: {cmd:absorb(}{it:{help xtivdfreg##absorb:absvars}}{cmd:)}, {opt fact:max(#)}, [{cmdab:no:}]{opt double:defact}, {opt fstage}, {opt mg}, and {opt nocons:tant}; see {helpb xtivdfreg}.

{dlgtab:Reporting}

{phang}
{it:xtivdfreg_options}: {opt level(#)}, {opt coeflegend}, {opt noheader}, {opt notable}, and other {it:{help xtivdfreg##display_options:display_options}}; see {helpb xtivdfreg}.

{dlgtab:Optimization}

{phang}
{it:xtivdfreg_options}: {opt noeigratio} and {opt std}; see {helpb xtivdfreg}.


{marker remarks}{...}
{title:Remarks}

{pstd}
Factors are extracted from the specified instruments excluding their spatial lags, because the latter are driven by the same factors. The user is encouraged to become familiar with the details on the defactorization stages by studying
the {helpb xtivdfreg##remarks:xtivdfreg} help file and the discussion in Kripfganz and Sarafidis (2021, 2024).

{pstd}
After the estimation, the command leaves the spatial weights matrix in memory as a Mata matrix named {cmd:spxtivdfreg_spmat}.
If the spatial weights matrix was initially imported from a file, this Mata matrix can subsequently be used to re-estimate the same or other model specifications without the need of re-importing the spatial weights matrix.
However, this Mata matrix is overwritten each time the command is run. If this is undesired, a copy of it needs to be made manually.

{pstd}
It is the user's responsibility to check that the ordering of the elements in the specified spatial weights matrix is the same as that of the cross-sectional groups in the data set.


{marker example}{...}
{title:Example}

{pstd}Setup (requires Stata version 15 or higher){p_end}
{pstd}(The data set and spatial weights matrix are available as ancillary files for the {cmd:xtivdfreg} package. The spatial weights matrix files will be copied to the current working directory.){p_end}
{phang2}. {stata "use http://www.kripfganz.de/stata/spxtivdfreg_example"}{p_end}
{phang2}. {stata "copy http://www.kripfganz.de/stata/spxtivdfreg_example_spmat.stswm ."}{p_end}
{phang2}. {stata "copy http://www.kripfganz.de/stata/spxtivdfreg_example_spmat.csv ."}{p_end}

{pstd}Defactored IV estimation with spatial lag and time lag, homogeneous slopes{p_end}
{pstd}Spatial weights matrix from {cmd:spmatrix}{p_end}
{phang2}. {stata spmatrix use W using spxtivdfreg_example_spmat}{p_end}
{phang2}. {stata spxtivdfreg NPL INEFF CAR SIZE BUFFER PROFIT QUALITY LIQUIDITY, absorb(ID) splag tlags(1) spmatrix(W) iv(INTEREST CAR SIZE BUFFER PROFIT QUALITY LIQUIDITY, splags lag(1)) std}{p_end}
{pstd}Spatial weights matrix from Excel or delimited file{p_end}
{phang2}. {stata spxtivdfreg NPL INEFF CAR SIZE BUFFER PROFIT QUALITY LIQUIDITY, absorb(ID) splag tlags(1) spmatrix("spxtivdfreg_example_spmat.csv", import) iv(INTEREST CAR SIZE BUFFER PROFIT QUALITY LIQUIDITY, splags lag(1)) std}{p_end}

{pstd}Defactored IV estimation with spatial lag and time lag, heterogeneous slopes{p_end}
{phang2}. {stata spxtivdfreg NPL INEFF CAR SIZE BUFFER PROFIT QUALITY LIQUIDITY, absorb(ID) splag tlags(1) spmatrix(W) iv(INTEREST CAR SIZE BUFFER PROFIT QUALITY LIQUIDITY, splags lag(1)) std mg}{p_end}

{pstd}IV estimation with spatial lag and time lag, no common shocks{p_end}
{phang2}. {stata spxtivdfreg NPL INEFF CAR SIZE BUFFER PROFIT QUALITY LIQUIDITY, absorb(ID) splag tlags(1) spmatrix(W) iv(INTEREST CAR SIZE BUFFER PROFIT QUALITY LIQUIDITY, splags lag(1)) std factmax(0)}{p_end}

{pstd}Defactored IV estimation with spatial lag, time lag, and spatial time lag{p_end}
{phang2}. {stata spxtivdfreg NPL INEFF CAR SIZE BUFFER PROFIT QUALITY LIQUIDITY, absorb(ID) splag tlags(1) sptlags(1) spmatrix(W) iv(INTEREST CAR SIZE BUFFER PROFIT QUALITY LIQUIDITY, splags lag(1)) std}{p_end}

{pstd}Defactored IV estimation with spatial lag, time lag, and spatially lagged independent variable (dynamic spatial Durbin model){p_end}
{phang2}. {stata spxtivdfreg NPL INEFF CAR SIZE BUFFER PROFIT QUALITY LIQUIDITY, absorb(ID) splag tlags(1) spindepvars(PROFIT) spmatrix(W) iv(INTEREST CAR SIZE BUFFER PROFIT QUALITY LIQUIDITY, splags lag(1)) std}{p_end}

{pstd}Defactored IV estimation with time lag but no spatial lags{p_end}
{phang2}. {stata spxtivdfreg NPL INEFF CAR SIZE BUFFER PROFIT QUALITY LIQUIDITY, absorb(ID) tlags(1) spmatrix(W) iv(INTEREST CAR SIZE BUFFER PROFIT QUALITY LIQUIDITY, lag(1)) std}{p_end}

{pstd}See Kripfganz and Sarafidis (2024) for a detailed discussion of some of these examples.{p_end}


{marker results}{...}
{title:Saved results}

{pstd}
In addition to results saved by {helpb xtivdfreg##results:xtivdfreg}, {cmd:spxtivdfreg} saves the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(splag)}}spatial lag of {it:depvar}{p_end}
{synopt:{cmd:e(tlags)}}time lags of {it:depvar}{p_end}
{synopt:{cmd:e(sptlags)}}spatial time lags of {it:depvar}{p_end}
{synopt:{cmd:e(maxeig)}}maximum eigenvalue of spatial weights matrix{p_end}


{marker authors}{...}
{title:Authors}

{pstd}
Sebastian Kripfganz, University of Exeter, {browse "http://www.kripfganz.de"}

{pstd}
Vasilis Sarafidis, Brunel University London, {browse "https://sites.google.com/view/vsarafidis"}


{marker references}{...}
{title:References}

{phang}
Ahn, S. C., and A. R. Horenstein. 2013.
Eigenvalue ratio test for the number of factors.
{it:Econometrica} 81: 1203-1227.

{phang}
Chen, J., G. Cui, V. Sarafidis, and T. Yamagata. 2023.
IV estimation of heterogeneous spatial dynamic panels with interactive effects.
{it:Manuscript}.

{phang}
Cui, G., M. Norkute, V. Sarafidis, and T. Yamagata. 2022.
Two-stage instrumental variable estimation of linear panel data models with interactive effects.
{it:Econometrics Journal} 25: 340-361.

{phang}
Cui, G., V. Sarafidis, and T. Yamagata. 2023.
IV estimation of spatial dynamic panels with interactive effects: Large sample theory and an application on bank attitute toward risk.
{it:Econometrics Journal}: 26: 124-146.

{phang}
Kripfganz, S., and V. Sarafidis. 2021.
Instrumental-variable estimation of large-T panel-data models with common factors.
{it:Stata Journal} 21: 659-686.

{phang}
Kripfganz, S., and V. Sarafidis. 2024.
Estimating spatial dynamic panel data models with unobserved common factors in Stata.
{it:Manuscript}.

{phang}
Norkute, M., V. Sarafidis, T. Yamagata, and G. Cui. 2021.
Instrumental variable estimation of dynamic linear panel data models with defactored regressors and a multifactor error structure.
{it:Journal of Econometrics} 220: 416-446.
