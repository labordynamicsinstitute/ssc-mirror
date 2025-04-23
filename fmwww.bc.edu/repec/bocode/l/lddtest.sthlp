{smcl}
{it:v. 1.0.0} 


{title:lddtest}

{p 4 4 2}
Logarithmic density discontinuity equivalence testing for regression discontinuity designs in Stata

{title:Syntax}

{p 8 8 2} {bf:lddtest} {it:runvar} [if] [in], breakpoint({it:real}) epsilon({it:real}) [ b({it:real}) h({it:real}) alpha({it:real}) at({it:string}) graphname({it:string}) noGRaph]

{title:Description}

lddtest performs equivalence testing on logarithmic density discontinuities of running variables at the cutoff
in regression discontinuity designs, as described in Fitzgerald (2024). lddtest is functionally a wrapper for McCrary's (2008)
classical DCdensity command. The DCdensity code upon which this command is based can be found at
https://eml.berkeley.edu/~jmccrary/DCdensity/ (accessed 30 June 2024).

{p 4 4 2}{bf:Arguments}

{col 5}{it:Argument}{col 21}{it:Description}
{space 4}{hline}
{col 5}{it:runvar}{col 21}The running variable. Must be a name for a numeric variable in memory.
{col 5}{it:breakpoint}{col 21}The cutoff value of the running variable for treatment assignment. Required, must be a real number.
{col 5}{it:epsilon}{col 21}Largest ratio between running variable density estimates on each side of the cutoff
{col 5}{col 21}that would be considered 'practically equal to 1'. Required, must be a real number > 1.
{space 4}{hline}

{p 4 4 2}{bf:Options}

{col 5}{it:Option}{col 21}{it:Description}
{space 4}{hline}
{col 5}{it:b}{col 21}Width of histograms used to initialize the DCdensity estimation.
{col 5}{col 21}If not specified, bin width defaults to that specified in Section 3.2 of McCrary (2008).
{col 5}{it:h}{col 21}Width of symmetric bandwidth used to compute the DCdensity estimation.
{col 5}{col 21}If not specified, bandwidth defaults to that specified in Section 3.2 of McCrary (2008).
{col 5}{it:alpha}{col 21}Significance level. Defaults to 0.05. If specified, must be a real number strictly between 0 and 0.5.
{col 5}{it:at}{col 21}Name of variable with values at which to compute initial density estimates. If not specified, 
{col 5}{col 21}defaults to the equi-spaced grid specified in Section 3.1 of McCrary (2008). If specified, must be a string.
{col 5}{it:graphname}{col 21}Denotes file to which the plot is saved. If not specified, the graph is not saved.
{col 5}{it:nograph}{col 21}If specified, suppresses the graph.
{space 4}{hline}

{title:Author}

{p 4 4 2}
Jack Fitzgerald     {break}
Vrije Universiteit Amsterdam     {break}
j.f.fitzgerald@vu.nl    {break}
{browse "https://jack-fitzgerald.github.io":https://jack-fitzgerald.github.io} 

{title:References}
Fitzgerald, Jack (2024). "Manipulation Tests in Regression Discontinuity Design: The Need for Equivalence Testing in Economics". 
Working paper. https://jack-fitzgerald.github.io/files/RDD_Equivalence.pdf.

McCrary, Justin (2008). Manipulation of the running variable in the regression discontinuity design: A density test. Journal of Econometrics 142(2), 698-714.
