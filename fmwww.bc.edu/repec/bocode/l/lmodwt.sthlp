{smcl}
{* *! version 1.1.0  2026-05-11}{...}
{viewerjumpto "Syntax" "lmodwt##syntax"}{...}
{viewerjumpto "Description" "lmodwt##description"}{...}
{viewerjumpto "Options" "lmodwt##options"}{...}
{viewerjumpto "Examples" "lmodwt##examples"}{...}
{viewerjumpto "Stored results" "lmodwt##results"}{...}
{title:Title}

{p2colset 5 17 19 2}{...}
{p2col:{bf:lmodwt} {hline 2}}Maximal Overlap Discrete Wavelet Transform{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:lmodwt} {it:varname} [{cmd:if}] [{cmd:in}]{cmd:,}
[{opt l:evels(#)}
{opt f:ilter(name)}
{opt mra}
{opt gen:erate(prefix)}
{opt nod:isplay}]


{marker description}{...}
{title:Description}

{pstd}
{cmd:lmodwt} computes the Maximal Overlap Discrete Wavelet Transform (MODWT)
of a time series variable. The MODWT is a non-decimated variant of the DWT
that produces N coefficients at each decomposition level (unlike the DWT
which downsamples by a factor of 2 at each level).

{pstd}
The MODWT is the standard tool for wavelet-based time series analysis in
economics and finance. It decomposes a time series into frequency bands
corresponding to different time horizons (e.g., short-run fluctuations
vs. long-run trends).

{pstd}
With the {opt mra} option, {cmd:lmodwt} also performs a Multiresolution
Analysis (MRA), decomposing the original signal into additive detail
(D1,...,DJ) and smooth (SJ) components that sum to the original series.

{pstd}
{bf:Note:} This command is named {cmd:lmodwt} to avoid a naming clash with
the {cmd:modwt} built-in introduced in Stata 18.


{marker options}{...}
{title:Options}

{phang}
{opt levels(#)} specifies the number of decomposition levels J.
Default is 4.  Maximum is floor(log2(N/(L-1)+1)) where L is the
filter length.

{phang}
{opt filter(name)} specifies the wavelet filter.  Default is {bf:la8}
(Least Asymmetric, length 8).  Available filters:

{p2colset 9 22 24 2}{...}
{p2col:{bf:Daubechies:}}haar (d2), d4, d6, d8, d10, d12, d14, d16, d18, d20{p_end}
{p2col:{bf:Least Asym:}}la8, la10, la12, la14, la16, la18, la20{p_end}
{p2col:{bf:Best Local:}}bl14, bl18, bl20{p_end}
{p2col:{bf:Coiflet:}}c6, c12, c18, c24, c30{p_end}
{p2colreset}{...}

{phang}
{opt mra} performs the Multiresolution Analysis and generates detail
and smooth component variables.

{phang}
{opt generate(prefix)} specifies the prefix for generated MRA variables.
Default is {bf:_wv}.  Creates variables {it:prefix}_D1,...,{it:prefix}_DJ
and {it:prefix}_SJ.

{phang}
{opt nodisplay} suppresses the results display.


{marker examples}{...}
{title:Examples}

{pstd}{bf:Basic MODWT decomposition}{p_end}
{phang2}{cmd:. lmodwt gdp, levels(4) filter(la8)}{p_end}

{pstd}{bf:MODWT with MRA and generated variables}{p_end}
{phang2}{cmd:. lmodwt gdp, levels(4) filter(haar) mra generate(_gdp)}{p_end}
{phang2}{cmd:. tsline _gdp_D1 _gdp_D2 _gdp_D3 _gdp_D4 _gdp_S4}{p_end}

{pstd}{bf:Using Daubechies filter}{p_end}
{phang2}{cmd:. lmodwt returns, levels(6) filter(d10)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:lmodwt} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(J)}}number of decomposition levels{p_end}
{synopt:{cmd:e(L)}}maximum decomposition level for this filter/sample{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:lmodwt}{p_end}
{synopt:{cmd:e(varname)}}name of decomposed variable{p_end}
{synopt:{cmd:e(filter)}}wavelet filter used{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(W}{it:j}{cmd:)}}wavelet coefficients at level {it:j}{p_end}
{synopt:{cmd:e(VJ)}}final-level scaling coefficients (V is reserved by ereturn post){p_end}
{synopt:{cmd:e(wvar)}}wavelet variance per level{p_end}


{title:Also see}

{psee}
{space 2}Help:  {helpb wavelet}, {helpb wmcorr}, {helpb wt}
{p_end}
