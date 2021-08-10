{smcl}
{* 20mar2010}{...}
{cmd:help mata rtnorm()}
{hline}

{title:Title}

{p 4 14 2}
{bf:rtnorm() -- Truncated normal pseudorandom variates.}


{title:Syntax}

{p 8 30 2}
{it:real matrix}{bind:  }
{cmd:rtnorm(}{it:real scalar r}{cmd:,} {it:real scalar c}{cmd:,}{it:real rowvector m}{cmd:,}{it:real rowvector s}{cmd:,}{break}
{it:real rowvector lower}{cmd:,} {it:real rowvector upper}{cmd:)}



{title:Description}

{p 4 4 2}
{cmd:rtnorm(}{it:r}{cmd:,}{it:c}{cmd:,} {it:m}{cmd:,} {it:s}{cmd:,} {it:lower}{cmd:,} {it:upper}{cmd:)} 
returns an {it:r x cj} real matrix containing truncated normal
random variates. The real-valued rowvectors {it:m} and {it:s} containthe mean and standard deviation parameters before truncation, respectively.
The real-valued rowvectors {it:lower} and {it:upper} contain parameters defining the two-sided truncation of the distribution.The matrices {it:m},{it:s},{it:lower} and {it:upper} must be {help m6_glossary:c-conformable}.{p_end}


{title:Conformability}

	{cmd:rtnorm(}{it:r}{cmd:,}{it:c}{cmd:,} {it:m}{cmd:,} {it:s}{cmd:,} {it:lower}{cmd:,} {it:upper}{cmd:)}:
		{it:r}:  1 {it:x} 1
		{it:c}:  1 {it:x} 1
		{it:m}:  1 {it:x} 1 or 1 {it:x} j
		{it:s}:  1 {it:x} 1 or 1 {it:x} j
	    {it:lower}:  1 {it:x} 1 or 1 {it:x} j
	    {it:upper}:  1 {it:x} 1 or 1 {it:x} j
	   {it:result}:  {it:r x c} or {it:r x cj} 


{title:Diagnostics}

	{p 4 4 2}
	The random-variate generator abort with error if {it:r<=0} or {it:c<=0}.

	{p 4 4 2} 
	{cmd:rtnorm(}{it:r}{cmd:,}{it:c}{cmd:,} {it:m}{cmd:,} {it:s}{cmd:,} {it:lower}{cmd:,} {it:upper}{cmd:)} 
	abort with an error if the parameter rowvectors do not conform.  See 
	{help m6_glossary:c-conformable} for rules on matrix conformability.


{title:Author}

	Federico Belotti 	Faculty of Economics  	Department of Financial and Quantitative Economics  	Tor Vergata University  	federico.belotti@uniroma2.it

  	Giuseppe Ilardi
  	Economic and Financial Statistics Department
  	Bank of Italy


{title:Also see}

	{p 4 13 2}
	Manual:  {manlink M-5 runiform()}

	{p 4 13 2}
	Help:   
	{bf:{help m4_standard:[M-4] standard}},
	{bf:{help m4_statistical:[M-4] statistical}}
	{p_end}
	