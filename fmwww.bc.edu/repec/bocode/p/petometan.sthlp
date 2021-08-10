{smcl}
{* *! version 2.0  David Fisher  11may2017}{...}
{vieweralsosee "sts test" "help sts test"}{...}
{vieweralsosee "ipdmetan" "help ipdmetan"}{...}
{vieweralsosee "ipdover" "help ipdover"}{...}
{vieweralsosee "forestplot" "help forestplot"}{...}
{vieweralsosee "admetan" "help admetan"}{...}
{vieweralsosee "admetani" "help admetani"}{...}
{vieweralsosee "metan" "help metan"}{...}
{title:Title}

{phang}
{cmd:petometan} {hline 2} Perform meta-analysis using the Peto (log-rank) method


{title:Notes}

{pstd}
This command is deprecated as of {cmd:ipdmetan} version 2.0.

{pstd}
The basic {cmd:petometan} syntax:

{p 8 18 2}
{cmd:petometan} {it:trt_var} [{cmd:,} {opt study(varname)} {opt strata(varlist)} {it:options}]

{pstd}
has been superseded by {bf:{help ipdmetan}} Syntax 2, as follows:

{p 8 18 2}
{cmd:ipdmetan} {it:trt_var} {cmd:,} {opt logrank} [{opt study(varname)} {opt strata(varlist)} {it:options}]


{title:Author}

{pstd}
David Fisher, MRC Clinical Trials Unit at UCL, London, UK.

{pstd}
Email {browse "mailto:d.fisher@ucl.ac.uk":d.fisher@ucl.ac.uk}
