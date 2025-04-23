{smcl}
{it:v. 1.0.0} 


{title:tsti}

{p 4 4 2}
{bf:tsti} Immediate application of the three-sided testing (TST) framework in Stata (Goeman, Solari, and Stijnen 2010)


{title:Syntax}

{p 8 8 2} {bf:tsti} {it:estimate} {it:se} {it:rope_lb} {it:rope_ub} [, df({it:real}) alpha({it:real})]


{p 4 4 2}{bf:Arguments}

{col 5}{it:Argument}{col 21}{it:Description}
{space 4}{hline}
{col 5}{it:estimate}{col 21}The estimate of interest.
{col 5}{it:se}{col 21}The standard error of the estimate of interest. Must be > 0.
{col 5}{it:rope_lb}{col 21}Lower bound of the region of practical equivalence (ROPE). Must be < rope_ub.
{col 5}{it:rope_lb}{col 21}Upper bound of the region of practical equivalence (ROPE). Must be > rope_lb.
{space 4}{hline}

{p 4 4 2}{bf:Options}

{col 5}{it:Option}{col 21}{it:Description}
{space 4}{hline}
{col 5}df({it:real}){col 21}Degrees of freedom of the estimate of interest. If specified, must be > 0.
{col 5}{col 21}Exact (rather than asymptotically approximate) bounds and testing results are produced if this option is specified.
{col 5}alpha({it:real}){col 21}The significance level of the test. Defaults to 0.05. If specified, it must be true that 0 < alpha < 0.5.
{space 4}{hline}

{title:Examples}

*Load Natinal Longitudinal Survey of Young Women, 14-24 in 1968, and set up for imputation DID
webuse nlswork, clear
cap ssc install did_imputation
gen year_u = year if union == 1
bysort idcode: egen union_year = min(year_u)

*Run imputation DID and store effect of obtaining union membership on inflation-adjusted log wages and weekly work hours
did_imputation ln_wage idcode year union_year, fe(idcode year) autosample
local beta_ln_wage = r(table)[1, 1]
local se_ln_wage = r(table)[2, 1]
did_imputation hours idcode year union_year, fe(idcode year) autosample
local beta_hours = r(table)[1, 1]
local se_hours = r(table)[2, 1]

*If we think that the smallest effect of unionization on weekly working hours that is practically meaningful is four hours...
tsti `beta_ln_wage' `se_ln_wage' -4 4

*If we think that the smallest effect of unionization on wages that is practically meaningful is 5%...
tsti `beta_ln_wage' `se_ln_wage' -.05129329 .05129329
*.05129329 = ln(1.05); mathematical expressions must be pre-evaluated as tsti only accepts numerics

{title:Author}

{p 4 4 2}
Jack Fitzgerald     {break}
Vrije Universiteit Amsterdam and Tinbergen Institute    {break}
j.f.fitzgerald@vu.nl    {break}
{browse "https://jack-fitzgerald.github.io":https://jack-fitzgerald.github.io} 

{title:References}
Fitzgerald, J. (2025). "The Need for Equivalence Testing in Economics". MetaArXiv, https://doi.org/10.31222/osf.io/d7sqr_v1.
Goeman, J. J., Solari, A., and Stijnen, T. (2010). "Three-sided hypothesis testing: Simultaneous testing of superiority, equivalence and inferiority." Statistics in Medicine 29(20), 2117-2125.
Isager, P. & Fitzgerald, J. (2024). "Three-Sided Testing to Establish Practical Significance: A Tutorial." PsyArXiv, https://doi.org/10.31234/osf.io/8y925.
