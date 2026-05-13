{smcl}
{* *! version 1.1.0  2026-05-11}{...}
{title:Title}

{p2colset 5 20 22 2}{...}
{p2col:{bf:lwavelet} {hline 2}}Wavelet analysis for time series (package){p_end}
{p2colreset}{...}


{title:Description}

{pstd}
{bf:lwavelet} is the name of this package on SSC. The main user-facing
command and dispatcher is {cmd:wavelet}. The full documentation —
syntax, options, stored results, methods, examples — lives at
{help wavelet}.

{pstd}
Click through to:

{p2colset 8 22 24 2}{...}
{p2col :{help wavelet}}main help (overview, syntax, examples){p_end}
{p2col :{help lmodwt}}MODWT decomposition (discrete){p_end}
{p2col :{help wt}}Continuous wavelet transform{p_end}
{p2col :{help xwt}}Cross-wavelet transform{p_end}
{p2col :{help wtc}}Wavelet coherence + Monte Carlo{p_end}
{p2col :{help wmcorr}}Wavelet multiple correlation{p_end}
{p2col :{help wmreg}}Wavelet multiple regression{p_end}
{p2col :{help wmxcorr}}Wavelet multiple cross-correlation{p_end}
{p2colreset}{...}


{title:Quick start}

{phang2}{cmd:. ssc install lwavelet}{p_end}
{phang2}{cmd:. help wavelet}{p_end}
{phang2}{cmd:. do example_lwavelet.do}     // full worked example{p_end}


{title:Author}

{pstd}
Dr. Merwan Roudane{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}
{p_end}
