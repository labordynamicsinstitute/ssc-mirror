{smcl}
{* 22aug2016}{...}
{hline}
help for {hi:x11as}
{hline}

{title:Perform X-11 seasonal adjustment on monthly or quarterly time series}

{title:Syntax}

{p 8 16 2}{cmd:x11as}
{varname}
{ifin}
{cmd:,}[{cmd:double}]

{p}{cmd:x11as} performs the X-11 seasonal adjustment procedure developed by the
US Census Bureau by calling a Mac OSX or Linux binary executable. It currently handles a single
timeseries.

{p}For more information on the X-13ARIMA-SEATS program executed by this command, 
see {browse "https://www.census.gov/srd/www/x13as/"}.

{title:Author}

{p 0 4}Christopher F Baum, Boston College, USA{p_end}
{p 0 4}baum@bc.edu{p_end}


