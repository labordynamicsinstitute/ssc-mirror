{smcl}
{* *! version 1.1.0  21jan2026}{...}
{viewerjumpto "Syntax" "urall##syntax"}{...}
{viewerjumpto "Description" "urall##description"}{...}
{viewerjumpto "Options" "urall##options"}{...}
{viewerjumpto "Examples" "urall##examples"}{...}
{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{hi:urall} {hline 2}}Unified Unit Root Tests Table (ADF, PP, ERS, ZA){p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:urall} {varlist} {ifin} {cmd:,} {opt test(test_name)} [{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt :{opt test(name)}}Required. Specify the test: {cmd:adf}, {cmd:pp}, {cmd:ers}, or {cmd:za}.{p_end}
{synopt :{opt crit(criteria)}}Information criteria for ADF lag selection: {cmd:BIC} (default) or {cmd:AIC}.{p_end}
{synopt :{opt maxlag(#)}}Maximum lag search for ADF/ERS tests. Default is 12.{p_end}

{syntab:Phillips-Perron}
{synopt :{opt pplag(#)}}Set fixed lags for PP test. Default is 4.{p_end}
{synopt :{opt ppmatch}}Match PP lags to the optimal lags selected by ADF.{p_end}

{syntab:ERS (DF-GLS)}
{synopt :{opt ersmethod(method)}}Lag selection method for ERS: {cmd:SIC} (default), {cmd:AIC}, {cmd:FIX}, {cmd:GTS05}, {cmd:GTS10}.{p_end}

{syntab:Zivot-Andrews}
{synopt :{opt zlagmethod(method)}}Lag selection for ZA: {cmd:BIC} (default), {cmd:AIC}, {cmd:TTEST}, or {cmd:INPUT}.{p_end}
{synopt :{opt ztrim(real)}}Trim fraction for break search. Default is 0.15.{p_end}

{syntab:Formatting}
{synopt :{opt title(string)}}Specify a custom title for the table.{p_end}
{synopt :{opt footnote(string)}}Add a custom footnote.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{opt varlist} may contain time-series operators.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:urall} performs unit root tests for a list of variables and displays the results in a single, compact table. 
The table includes results for Level (Intercept, Intercept+Trend) and First Difference (Intercept, Intercept+Trend).

{pstd}
It supports four types of tests:
{p_end}
{phang}1. {cmd:test(adf)}: Augmented Dickey-Fuller.{p_end}
{phang}2. {cmd:test(pp)}: Phillips-Perron.{p_end}
{phang}3. {cmd:test(ers)}: DF-GLS (Elliott-Rothenberg-Stock). Requires {cmd:ersur}.{p_end}
{phang}4. {cmd:test(za)}: Zivot-Andrews with structural break. Requires {cmd:zandrews}.{p_end}

{marker examples}{...}
{title:Examples}

{phang}{cmd:. tsset year}{p_end}
{phang}{cmd:. urall gdp inf unemp, test(adf)}{p_end}
{phang}{cmd:. urall gdp inf unemp, test(pp) ppmatch}{p_end}
{phang}{cmd:. urall gdp inf unemp, test(za) ztrim(0.10)}{p_end}

{title:Author}

{pstd}
Prof. Imadeddin Almosabbeh{break}
Arab East Collegs, Saudi Arabia, Riyadh{break}
msbbh68@hotmail.com
iaalmosabbeh@arabeast.edu.sa
{p_end}