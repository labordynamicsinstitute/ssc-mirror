{smcl}{* *! version 1.1  04may2010}{cmd:help mata runningprod()}{hline}{title:Title}{p 4 8 2}{bf:runningprod()} {hline 2} Running product of vector{title:Syntax}{p 8 12 2}{it:numeric vector}{bind:    }{cmd:runningprod(}{it:numeric vector x}[{cmd:,} {it:missing}]{cmd:)}{p 4 4 2}where optional argument {it:missing} is a {it:real scalar} that determines howmissing values in {it:x} are treated.{title:Description}{p 4 4 2}{cmd:runningprod(}{it:x}{cmd:)} returns a vector of the same dimension as{it:x} containing the running product of {it:x}. By default, missing values turn the product tomissing.{title:Remarks}{p 4 4 2}The running product of (2, 4, 6) is (2, 8, 48).{p 4 4 2}All functions return the same type as the argument, real if argument is real, complex if complex.{title:Conformability}{p 4 4 2}{cmd:runningprod(}{it:x}{cmd:,} {it:missing}{cmd:)}:{p_end}		{it:x}:  {it:r x} 1  or  1 {it:x} c	  {it:missing}:  1 {it:x} 1                (optional)	   {it:result}:  {it:r x} 1  or  1 {it:x} c{title:Diagnostics}{p 4 4 2}If {it:missing} is not specified, missing values turn the product tomissing. Specifying {it:missing} as 1 specifies that missing values in {it:x}are to be treated as 1, and so on.{title:Author}
	
	We would like to thank Nick Cox for his useful advices

	Federico Belotti 	Faculty of Economics  	Department of Financial and Quantitative Economics  	Tor Vergata University  	federico.belotti@uniroma2.it

  	Silvio Daidone
  	Health Policy team
  	Centre for Health Economics
	The University of York
{title:Also see}{p 4 13 2}Manual:  {manlink M-5 runningsum()}{p 4 13 2}{space 2}Help:   {bf:{help mf_sum:[M-5] sum()}};{bf:{help m4_mathematical:[M-4] mathematical}},{bf:{help m4_utility:[M-4] utility}}{p_end}