{smcl}
{* *! version 1.0.0  06jun2026}{...}
{vieweralsosee "xtfpss" "help xtfpss"}{...}
{vieweralsosee "xtcipsm" "help xtcipsm"}{...}
{vieweralsosee "xtpgc" "help xtpgc"}{...}
{viewerjumpto "Overview" "xtpdlib##overview"}{...}
{viewerjumpto "Commands" "xtpdlib##commands"}{...}
{viewerjumpto "Common setup" "xtpdlib##setup"}{...}
{viewerjumpto "Quick examples" "xtpdlib##examples"}{...}
{viewerjumpto "Origin" "xtpdlib##origin"}{...}
{viewerjumpto "Author" "xtpdlib##author"}{...}
{title:Title}

{phang}
{bf:xtpdlib} {hline 2} A library of second-generation panel data tests
(panel unit root, panel stationarity and bootstrap panel causality)

{marker overview}{...}
{title:Overview}

{pstd}
{cmd:xtpdlib} is a Stata library that brings several modern panel time-series tests
{hline 1} accounting for {it:cross-section dependence}, {it:structural shifts} and
{it:heterogeneity} {hline 1} from Saban Nazlioglu's GAUSS {bf:TSPDLIB} into Stata, with
journal-quality output tables, publication-style graphs, and fully cross-linked help.

{pstd}
All commands require the data to be declared as a balanced panel with {helpb xtset}.


{marker commands}{...}
{title:Commands}

{synoptset 14 tabbed}{...}
{synopt:{helpb xtfpss}}Fourier panel stationarity test with gradual/smooth structural
shifts and cross-section dependence (Nazlioglu & Karul, 2017). H0: stationarity.
Produces the Fig.1-style series-and-Fourier-approximation plot.{p_end}

{synopt:{helpb xtcipsm}}Modified CADF / CIPS panel unit-root test with standard
chi-squared and normal limiting distributions (Westerlund & Hosseinkouchack, 2016;
Pesaran, 2007). H0: unit root. Reports the standard CIPS as a by-product.{p_end}

{synopt:{helpb xtpgc}}Bootstrap panel Granger causality in heterogeneous mixed panels:
Fisher (Emirmahmutoglu & Kose, 2011) and SUR-Wald (Konya, 2006), with cross-section
dependence handled by bootstrap critical values.{p_end}
{synoptline}

{pstd}Related community commands (not part of this library):{p_end}
{phang2}{helpb xtcips} {hline 1} standard Pesaran (2007) CIPS.{p_end}
{phang2}{helpb pescadf} {hline 1} single-series Pesaran (2007) CADF/CIPS.{p_end}
{phang2}{helpb xtgcause} {hline 1} Dumitrescu-Hurlin (2012) Zbar panel causality.{p_end}


{marker setup}{...}
{title:Common setup}

{pstd}Every command expects a balanced panel declared with {helpb xtset}:{p_end}
{phang2}{cmd:. xtset panelid timevar}{p_end}

{pstd}The unit root / stationarity commands take a single {varname}; the causality
command takes a {varlist} of two or more variables.{p_end}


{marker examples}{...}
{title:Quick examples}

{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. xtset company year}{p_end}

{phang2}{cmd:. xtfpss invest, model(level) freq(1) graph}{p_end}
{phang2}{cmd:. xtcipsm invest, model(constant) graph}{p_end}
{phang2}{cmd:. xtpgc invest mvalue, method(fisher) breps(200) seed(1) graph}{p_end}


{marker origin}{...}
{title:Origin and citation}

{pstd}
These commands are Stata translations of routines from the GAUSS {bf:TSPDLIB} library by
Saban Nazlioglu (Pamukkale University). Please cite the original methodological papers
(listed in each command's help) and, where appropriate, the application papers such as
Kar, Nazlioglu and Agir (2011).


{marker author}{...}
{title:Author}

{pstd}Stata library {cmd:xtpdlib} {hline 1} implementation and packaging:{p_end}
{pmore}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}

{pstd}Original GAUSS code (TSPDLIB):{p_end}
{pmore}Saban Nazlioglu, snazlioglu@pau.edu.tr{p_end}
