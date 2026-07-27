{smcl}
{* 23jul2026}{...}
{vieweralsosee "ffrals" "help ffrals"}{...}
{vieweralsosee "ffadf" "help ffadf"}{...}
{vieweralsosee "fflm2" "help fflm2"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "flexur (single-series library)" "help flexur"}{...}
{vieweralsosee "xtpdroot (panel library)" "help xtpdroot"}{...}
{vieweralsosee "xtflexur (panel library)" "help xtflexur"}{...}
{title:Title}

{phang}
{bf:ffrals} {hline 2} Flexible-Fourier form + RALS unit-root tests for
non-normal errors

{title:Description}

{pstd}
{bf:ffrals} is a library of single-series unit-root tests that combine the
{it:flexible Fourier form} for an unknown number of smooth structural breaks with
{it:residual-augmented least squares} (RALS) corrections for non-normal errors,
following Lee, Islam, Tieslau, Payne and Nazlioglu. Each test is available in a
plain, a RALS, and a factor-augmented (RALS2) variant.

{title:Commands}

{synoptset 20 tabbed}{...}
{synopthdr:command}
{synoptline}
{synopt:{helpb ffrals}}Flexible-Fourier LM test ({cmd:rals(0/1/2)}){p_end}
{synopt:{helpb ffadf}}Flexible-Fourier ADF test ({cmd:rals(0/1/2)}, {cmd:det()}){p_end}
{synopt:{helpb fflm2}}Two-break LM test ({cmd:rals(0/1/2)}){p_end}
{synoptline}
{p2colreset}{...}

{pstd}
All three share the {cmd:rals()} interface (plain / RALS / factor-augmented).
{helpb ffrals} and {helpb ffadf} obtain p-values by Monte-Carlo simulation of the
null distribution; {helpb fflm2} uses tabulated (deterministic) critical values.

{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
