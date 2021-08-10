{smcl}
{* version 1.0.1 28mar2011}
{cmd:help misum}
{hline}

{title:Title}

{p 5}
{cmd:misum} {hline 2} Summary statistics in MI dataset 

{title:Syntax}

{p 8 44}
{cmd:misum} [{varlist}] {ifin} {weight} [{cmd:, m(}{it:numlist}{cmd:)} {opt d:etail} 
{cmd:{ul:for}}{cmd:mat(}{help format:%fmt}{cmd:)} {opt mat:rix(name)}]


{p 12}
{helpb by} is allowed

{p 12 12}{cmd:aweights}, {cmd:fweights} and {cmd:iweights} are allowed. However, 
{cmd:iweights} are not allowed with {opt detail}. See {help summarize}


{title:Description}

{pstd}
{cmd:misum} calculates summary statistics in MI datasets. The program combines results from 
{help summarize}, applying Rubin's combination rules.

{title:Remarks}

{pstd}{cmd:misum} requires mi data to be {it:flong} {help mi_styles:{it:style}}. To 
change the style of mi data use {help mi convert} {it:flong}.


{title:Options}

{dlgtab:Options}

{phang}
{opt m(numlist)} combines results from imputed datasets {it:numlist}.

{phang}
{opt d:etail} calculates additional statistics. Median, skewness and kurtosis are 
displayed for each variable in an additional matrix.

{phang}
{opt for:mat(%fmt)} displays results in specified format.

{phang}
{opt mat:rix(name)} returns result matrix in {cmd:r(}{it:name}{cmd:)}. If {opt detail} is 
also specified, matrix {cmd:r(}{it:name}{hi:{it:_d}}{cmd:)} is returned additionaly.


{title:Example}

	. sysuse auto
	(1978 Automobile Data)

	. mi set flong

	. mi register imputed rep78
	
	. mi impute regress rep78 price mpg weight foreign ,add(5)

	[output omitted]

	{cmd:. misum price weight rep78}

	m=1/5 data

	    Variable |      Mean         SD        min        max          N 
	-------------+-------------------------------------------------------
	       price |  6165.257   2949.496       3291      15906         74 
	      weight |  3019.459   777.1936       1760       4840         74 
	       rep78 |  3.405173   .9874648          1   5.105155         74 


	{cmd:. misum rep78 ,detail}

	m=1/5 data

	    Variable |      Mean         SD        min        max          N 
	-------------+-------------------------------------------------------
	       rep78 |  3.405173   .9874648          1   5.105155         74 

	    Variable |       p50   Skewness   Kurtosis 
	-------------+---------------------------------
	       rep78 |         3  -.0418277   2.654632 

	. return list

	scalars:
	          r(rep78_p99) =  5.105155181884766
	          r(rep78_p95) =  5
	          r(rep78_p90) =  5
	          r(rep78_p75) =  4
	          r(rep78_p25) =  3
	          r(rep78_p10) =  2
	           r(rep78_p5) =  2
	           r(rep78_p1) =  1
	     r(rep78_kurtosis) =  2.654631682655315
	     r(rep78_skewness) =  -.0418276860909651
	          r(rep78_p50) =  3
	          r(rep78_sum) =  251.9827878952027
	        r(rep78_sum_w) =  74
	          r(rep78_Var) =  .9753773811180893
	            r(rep78_N) =  74
	          r(rep78_max) =  5.105155181884766
	          r(rep78_min) =  1
	           r(rep78_sd) =  .9874648279159382
	         r(rep78_mean) =  3.40517280939463


{title:Saved results}

{pstd}
{cmd:misum} calls {help summarize} and saves any results returned for each variable. It 
therefore saves the following in {cmd:r()}:

{pstd}
Scalars{p_end}
	{cmd:r({it:varname_stat})}	{it:stat} returned by {help summarize} for {it:varname}

{pstd}
Matrices{p_end}
	{cmd:r({it:name})}		result matrix ({opt matrix} only)

{title:Author}

{pstd}Daniel Klein, University of Bamberg, klein.daniel.81.@gmail.com

{title:Also see}

{psee}
Online: {helpb mi}, {help summarize}{p_end}
