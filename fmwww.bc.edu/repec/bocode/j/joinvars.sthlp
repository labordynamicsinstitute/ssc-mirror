{smcl}
{* version 1.0.2 28dec2010}
{cmd:help joinvars}
{hline}

{title:Title}

{p 5}
{cmd:joinvars} {hline 2} Join values of variables

{title:Syntax}

{p 8}
{cmd:joinvars} {newvar} [=] {varlist} {ifin} [{cmd:,} {it:options}]

{synoptset 21 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt u:pdate}}replace non-missing values with non-missing values{p_end}
{synopt:{opt miss:ok}}replace non-missing values with missing values{p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:joinvars} creates variable {it:newvar} containing joined values of {it:varlist}. 
Starting with a copy of the first variable in {it:varlist}, missing values in {it:newvar} 
are replaced with values of the next variable(s) in {it:varlist}.

{title:Options}

{dlgtab:Options}

{phang}
{opt u:pdate} replaces non-missing values in {it:newvar} with values of variables 
in {it:varlist}. Default is to replace missing values only.

{phang}
{opt miss:ok} replaces non-missing values in {it:newvar} with missing values of variables 
in {it:varlist}. May only be specified with {opt update}.

{title:Example}

{pstd}
First, I separate wages by race in the NLSW 1988 dataset using {help separate}.

	. sysuse nlsw88 ,clear
	(NLSW, 1988 extract)

	. separate wage ,by(race)

	[output omitted]

{pstd}
Now suppose the original variable {it:wage} is missing in this dataset. It can be created 
using {cmd: joinvars}.

	. drop wage

	. list race wage* in 516/520

	     +----------------------------------------+
	     |  race      wage1      wage2      wage3 |
	     |----------------------------------------|
	516. | white   4.428341          .          . |
	517. | white   15.09662          .          . |
	518. | black          .   6.843801          . |
	519. | other          .          .   6.513685 |
	520. | white   5.072463          .          . |
	     +----------------------------------------+

	{cmd:. joinvars wage = wage1 wage2 wage3}

	. list race wage1 wage2 wage3 wage in 516/520

	     +---------------------------------------------------+
	     |  race      wage1      wage2      wage3       wage |
	     |---------------------------------------------------|
	516. | white   4.428341          .          .   4.428341 |
	517. | white   15.09662          .          .   15.09662 |
	518. | black          .   6.843801          .   6.843801 |
	519. | other          .          .   6.513685   6.513685 |
	520. | white   5.072463          .          .   5.072463 |
	     +---------------------------------------------------+

{pstd}
{ul:The options}

	{cmd:. joinvars nonsense = wage1 wage2 wage3 ,update missok}

	. list race wage1 wage2 wage3 nonsense in 516/520

	     +---------------------------------------------------+
	     |  race      wage1      wage2      wage3   nonsense |
	     |---------------------------------------------------|
	516. | white   4.428341          .          .          . |
	517. | white   15.09662          .          .          . |
	518. | black          .   6.843801          .          . |
	519. | other          .          .   6.513685   6.513685 |
	520. | white   5.072463          .          .          . |
	     +---------------------------------------------------+

 
{title:Author}

{pstd}Daniel Klein, University of Bamberg, klein.daniel.81@gmail.com

{title:Also see}

{psee}
Online: {help separate}, {help egen}, {help reshape}
{p_end}