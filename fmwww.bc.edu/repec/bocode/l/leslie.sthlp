{smcl}
{* *! version 1.0.0 25mar2026}{...}
{vieweralsosee "[ST] ltable " "help ltable"}{...}
{vieweralsosee "[ST] mslt " "help mslt"}{...}
{vieweralsosee "[ST] ilt " "help ilt"}{...}
{viewerjumpto "Syntax" "leslie##syntax"}{...}
{viewerjumpto "Description" "leslie##description"}{...}
{viewerjumpto "Arguments" "leslie##arguments"}{...}
{viewerjumpto "Output" "leslie##output"}{...}
{viewerjumpto "Saved results" "leslie##results"}{...}
{viewerjumpto "Remarks" "leslie##remarks"}{...}
{viewerjumpto "Examples" "leslie##examples"}{...}
{viewerjumpto "References" "leslie##References"}{...}
{cmd:help leslie}
{hline}
{title:Title}

{phang}{bf:leslie} {hline 2} Computes demographic projections, stable analysis,
	and summary measures for one-sex, two-sex and multistate populations

{marker syntax}{...}
{title:Syntax}

{p 8 17 2} {cmdab: leslie}{cmd:, period({it:{help integer}})} [{it:options}]

{synoptset 20 tabbed}{...}
{marker options}{...}
{synopthdr :Options}
{synoptline}
{synopt:{opt sr:b(real)}} ratio of boys to girls at birth{p_end}
{synopt:{opt male}} include this option for male-dominant projections{p_end}
{synopt:{opt total}} include this option to project the total population 
	(females and males combined){p_end}
{synopt:{opt l0(integer)}} radix of the life table{p_end}
{synopt:{opt e:xtraT(numlist)}} person-years remaining in the extra last open age 
	group{p_end}
{synopt:{opt t:wo}} if the input data refers to two-sex populations{p_end}
{synopt:{opt f:ert(numlist)}} expected tfr in the last projection period{p_end}
{synopt:{opt b:aseline(integer)}} baseline year of the projection{p_end}
{synopt:{opt pl:ace(string)}} region, subregion, country or area  from which 
	the final age-specific fertility standard is borrowed{p_end}
{synopt:{opt sur:v(numlist)}} expected {it:e0} in the last projection 
	period{p_end}
{synopt:{opt si:gma(numlist)}} expected slope of the ultimate survival curve{p_end}
{synopt:{opt nmr(string)}} get net migration rates from an external dataset 
specified in parentheses{p_end}
{synopt:{opt mig1(string)}} computes the residual number of net migrants 
	by age and includes them in the projections{p_end}
{synopt:{opt mig2}} splits migrants over the projection period{p_end}
{synopt:{opt mu:ltistate}} if the input data refers to multistate 
	populations{p_end}
{synopt:{opt n:omobility}} excludes mobility from the projections{p_end}
{synopt:{opt s:table}} computes stable-equivalent age structures{p_end}
{synopt:{opt su:mmary}} calculates summary demographic measures{p_end}
{synopt:{opt t:olerance(real)}} threshold of stability{p_end}
{synopt:{opt k:eyfitz}} implements Keyfitz's delta  in the calculation of 
	distance to stability{p_end}
{synopt:{opt y:gual(integer)}} young group upper age limit{p_end}
{synopt:{opt gr:opts(string)}} options for twoway graphs{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd} {cmd:leslie} forward projects populations structured by age, sex, and 
other states of interest using matrix models. The program implements the methods
 and procedures first introduced by Leslie (1945), and later developed by 
 Rogers (1966, 1995). The program produces projections for one- or 
 two-sex populations, with or without net migration, and also performs 
 multistate projections, with or without considering mobility between 
 subpopulations. The {opt s:table} option calculates the age structure of 
 stable-equivalent populations, and {opt su:mmary} computes several demographic 
 measures characterizing the current population (tfr, nrr, {it:e0}, grr, mean age 
 at death and of the population, intrinsic rates, momentum etc.). The inputs 
 for one-sex and two-sex projections are:  

{pin}1) the population aged {it:x} to {it:x+n} at a base year at time {it:t};{p_end}
{pin}2) the number of person-years ({it:L_x});{p_end}
{pin}3) age-specific fertility rates for women of reproductive age; and{p_end}
{pin}4) a file containing the population in the previous period ({it:t-5}), 
	if the user chooses to include the residual number of net migrants in the 
	projections.{p_end}

{pstd}For multistate projections, the inputs are:

{pin}1) the populations aged {it:x} to {it:x+n} in the initial year; {p_end}
{pin}2) the probability of dying in state {it:i} at age {it:x} ({it:qi_x});{p_end}
{pin}3) age-specific fertility rates;{p_end}
{pin}4) transition probabilities between states of origin {it:i} and destination
 {it:j} at age {it:x}; and{p_end}
{pin}5)	a categorical variable identifying each state {it:i}.{p_end}

{pstd}An adequate dataset should have variables in this order before being 
entered into Stata. For two-sex projections, the first half of the rows must 
refer to women (with age-specific fertility rates), and the second half to men. 
Female data must be stacked on top of males. For multistate populations, 
each subpopulation should be on top of each other, and the last variable in the
 dataset should identify their state of occupancy. 

{marker arguments}{...}
{title:Arguments}

{dlgtab:Main}

{phang}{cmd:period({it:{help integer}})} specifies the number of projection 
periods. One period is equal to the length of the age groups ({it:n}). For 
example, if {it:n=5}, specifying period{bf:(10)} will project the population 
for 50 years. {cmd:period( )} is required.

{dlgtab:Options}

 
{phang}{opt s:rb(real)} represents the ratio of boys over girls at birth. 
By {it: default}, this scalar is set to 1.05, suitable for female-dominant and
 multistate projections.

{phang}{opt male} include this option for male-dominant projections.

{phang}{opt total} include this option to project the total population (females 
and males combined in a single vector). 
 
{phang}{opt l0(integer)} denotes the arbitrary radix of the life table. This scalar is 
used in one-sex and two-sex population projections to calculate the survival 
probability of births in the first age group. By convention, the {it: default}
 value is 100,000. It should only be altered if the number of entered 
 person-years lived (L_x) derives from a number of survivors (l_x) with a life
 table radix different from 100,000.

{phang}{opt e:xtraT(numlist)} allows expert users to define an extra value for 
the person-years remaining ({it:T}) in the last age open age group. Specifying 
this option affects the probabilities of survival in the last two age groups in 
the last row of the Leslie projection matrix. These values can be defined for 
one-sex or two-sex projection models.  
 
{phang}{opt t:wo} indicates that the input data refers to two-sex populations 
and simultaneously projects the future size of the age-specific female and male
 populations. It also produces a graph highlighting the age structure of the 
 first and last projections.

{phang}{opt f:ert(numlist)} sets the total fertility rate expected in the last 
projection period. This value corresponds to the analyst's expectation of how
many children women will bear in the future and defines the rhythm of fertility
 change throughout the projection period.   

{phang}{opt b:aseline(integer)} specifies the baseline year of the projection. 
Use this option with {opt fert()} or {opt place()} to determine and borrow the
 age-specific fertility standard for the final projection period. The standard 
 is sourced from median variant data in the {it: World Population Prospects} 
 (e.g., United Nations 2024). When used with {opt fert()}, it selects the 
 fertility standard with the closest total fertility rate in the ultimate 
 projection year. When used with {opt place()}, it retrieves the exact 
 fertility standard of the specified location for the final projection year.

{phang}{opt pl:ace(string)} must be used with {opt baseline()}. Specifies the 
region, subregion, country, or area from which the final life expectancy 
and/or age-specific fertility standard is borrowed.  
 
{phang}{opt sur:v(numlist)} sets the life expectancy at birth expected in the last 
projection period. For two-sex projection models, the user must consecutively 
enter one value for females and one for males. Setting these values defines the
 dynamics of convergence between current and future levels of survival.  

{phang}{opt si:gma(numlist)} sets alternative values for the slope of the survival 
curve expected in the last projection period. This option allows expert users 
to investigate the consequences of different survival patterns on future 
demographic projections. For two-sex projection models, the user must enter two
 expected values: one for females and one for males.

{phang}{opt mig1(string)} computes the residual number of net migrants by age
 from the difference between the observed and projected populations at time 
 {it:t}. A dataset containing a single variable with age-specific populations 
 at time {it:t-5} must be enclosed in parentheses for the program to calculate
 the expected population. This option includes residual migrants in the 
 projections, assuming movements occur at the beggining of the period. 
 Example: {cmd: leslie, p(10) mig1(sweden_1988_female.dta)}.

{phang}{opt mig2} must be used with with the {opt mig1()} option to include 
half of the migrants at the beginning and half at the end of the projection 
interval (Preston el al. 2001, 125). 
 
{phang}{opt mu:ltistate} indicates that the input data refers to multistate 
populations and assembles a block matrix to simultaneously project the future 
size of age- and state-specific populations. It also produces a graph 
highlighting the age structure of the first and last projected populations in 
each state.

{phang}{opt n:omobility} produces state-specific projections considering 
survival and fertility rates, but zeroing off-diagonal matrices in the 
"growth" block-matrix used for multistate projections.

{phang}{opt s:table} displays a graph and a comparative table of current, 
stationary and stable-equivalent age structures.
 
{phang}{opt su:mmary} calculates demographic measures related to the current 
 population and its future dynamics. These measures include tfr, nrr, grr, 
 life expectancy at birth, population momentum, intrinsic rates, mean ages at 
 death and maternity, Keyfitz's delta, time to reach stability, length of a 
 generation, total dependency ratio, and others. For multistate populations, 
 this option additionally calculates conditional state-specific life 
 expectancies at birth.
 
{phang}{opt t:olerance(real)} set the tolerance level used to define the 
criterion of proximity to the stable equivalent age structure, influencing the
 calculation of the number of years to stability. The {it: default} value is 
 1e-6.

{phang}{opt k:eyfitz} tells {cmd:leslie} to use Keyfitz's delta to calculate 
the number of years to stability in one-sex projection models.

{phang}{opt y:gual(integer)} sets the young group upper age limit in the 
calculation of the total age dependency ratio. The {it: default} is 14 years 
old.

{phang}{opt gr:opts(twoway_options)} allows the inclusion of options for 
twoway graphs, such as {it: scheme(schemename)}, {it:nodraw}, 
{it:saving(filename, ...)}, and others.
 
{marker output}{...}
{title:Output}

{pstd} As a minimum, {cmd:leslie} displays a table and a graph of populations  
projected by age, sex or occupancy states ({opt multistate} option).

{pstd} In single state projections the program optionally includes the number 
of residual net migrants ({opt mig1()} and {opt mig2} options). It is also able
to generate stable-equivalent age structures ({opt stable} option) and several key 
demographic measures ({opt summary} option) for one-sex, two-sex, and multistate 
populations.

{marker results}{...}
{title:Saved Results}

{pstd} {cmd: leslie} returns projected populations, age-structures, and 
 summary measures as system matrices under the following names:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Stata matrices}{p_end}
{synopt:{cmd:r(proj)}}The rows represent the lower bounds of the age groups and 
the columns show the successive projected one-sex populations. If migrants are
included in the projection ({opt bmigration} option), the results are stored in
 the same matrix{p_end}
{synopt:{cmd:r(mproj)}} For a two-sex population ({opt two} option), this matrix
returns the future size of the age-specific male population. Projections with 
migration are also stored in this matrix{p_end}
{synopt:{cmd:r(fproj)}}For a two-sex population ({opt two} option), this matrix
returns the future size of the age-specific female population. Projections with 
migration are also stored in this matrix{p_end}
{synopt:{cmd:r(mproj{it:i})}}Returns a matrix of successive projected 
populations by age for each state {it:i} equal to {it: 1, 2, 3...} if the 
{opt multistate} option is specified. Projections with the additional option 
{opt nomobility} are saved under the same name {p_end}
{synopt:{cmd:r(mstable{it:i})}}This matrix returns stable-equivalent age 
structures of the population in state {it:i} when options {opt multistate} and 
{opt stable} are specified at the same time{p_end}
{synopt:{cmd:r(stable)}}This matrix returns stable-equivalent age 
structures of one-sex poulations when option {opt stable} is included{p_end}
{synopt:{cmd:r(mstable)}}Stable-equivalent age structures of male populations
when options {opt two} and {opt stable} are simultaneously specified{p_end}
{synopt:{cmd:r(fstable)}}Stable-equivalent age structures of female 
populations when options {opt two} and {opt stable} are simultaneously 
specified{p_end}
{synopt:{cmd:r(summary)}}Returns a matrix with 21 measures for one-sex, 16 for 
two-sex, and eight for multistate populations if the {opt summary} option is
specified{p_end}
{synopt:{cmd:r(summary2)}}Returns a matrix containing six measures about the 
future dynamics of a multistate population. This matrix is generated whenever
the options {opt multistate} and {opt summary} are invoked simultaneously{p_end}
{synopt:{cmd:r(summary3)}}Simultaneously invoking the {opt multistate} and 
{opt summary} options generates a matrix with conditional state-specific life 
expectancies: the sojourn time in state {it:j} given occupancy of state {it:i}{p_end}


{p2col 5 15 19 2: Mata matrices}{p_end}
{synopt:{cmd:M}}Is the (block) matrix assembled to project input populations. 
For one- and two-sex populations its elements follow the structure of a 
conventional Leslie matrix (Leslie 1945). For multistate projections, the matrix
{bf:M} is structured according to the "multiregional matrix growth operator 
model" (Rogers 1995, 117){p_end}
{synopt:{cmd:T}}Is a column vector with the age-specific number of person-years 
remaining. It also represents life expectancies. It is computed for one- and 
two-sex population projection models{p_end}

{marker remarks}{...}
{title:Remarks}

{phang} I developed and tested {cmd:leslie} having in mind the most prevalent 
type of demographic data: populations organized into 5-year age groups.
The recommendation is to structure the data in this fashion before entering them 
into Stata. 

{marker examples}{...}
{title:Examples}

{pstd}1. To project the female population for 10 periods, one should type:  

{phang}{cmd:. leslie, period(10)}

{pstd}2. To project the male population five periods forward, assuming a 
radix for the life table of 150,000:

{phang} {cmd:. leslie, period(5) male l0(150000)}

{pstd}3. To project female and male populations entered at the same time for 15
periods:

{phang} {cmd:. leslie, period(15) two}

{pstd}4. To include residual net migrants in the projections, the user must 
specify a file containing the population observed in the previous period. For 
example, to include female Swedish migrants in a 10-years projection of the 
1993 population, type: 

{phang} {cmd:. leslie, period(10) mig1(sweden_1988_female.dta)}

{pstd}5. For multistate projections type:

{phang} {cmd:. leslie, period(10) multistate}

{pstd}6. To request a table and a graph of multistate projections without 
mobility but with stability analysis:

{phang} {cmd:. leslie, period(10) multistate nomobility stable}

{pstd}7. To request summary demographic measures for one-sex, two-sex, and 
multistate populations projected for 20 periods, respectively type:

{phang} {cmd:. leslie, period(20) summary}

{phang} {cmd:. leslie, period(20) two summary}

{phang} {cmd:. leslie, period(20) multistate summary}

{pstd}8. To simultaneously project female and male populations assuming that 
the total fertility rate and life expectancies at birth in the 20th projection 
period will respectively be 2.01 children, 85 years for females, and 80 years 
for males, type:

{phang} {cmd:. leslie, two period(20) fert(2.01) surv(85 80)} 

{pstd}9. To simultaneously project female and male populations assuming that 
the total fertility rate and life expectancies at birth in the 20th projection 
period will respectively be 2.01 children, 85 years for females, and 80 years 
for males, type:

{phang} {cmd:. leslie, two period(20) fert(2.01) surv(85 80)} 



{marker References}{...}
{title: References}

{pstd}Indispensable references on matrix models for demographic projections
 are:{p_end}

{phang} Leslie, P. H. 1945. On the use of matrices in certain population 
mathematics. {it:Biometrika} 33(3): 183-212.
 
{phang} Rogers, A. 1966. The multiregional matrix growth operator and the stable
interregional age structure. {it: Demography} 3(2): 537-544.

{phang} Rogers, A. 1995. Multiregional demography: principles, methods and 
extensions. England: John Wiley and Sons Ltd.


{pstd} Please contact {bf:Jer{c o^}nimo O. Muniz <jeronimo@ufmg.br>} to report bugs
 and to suggest future improvements.

