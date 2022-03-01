{smcl}
{* *! version 2.00 31january2022}{...}
{viewerjumpto "Syntax" "aei##syntax"}{...}
{viewerjumpto ”Description” ”aei##description”}{...}
{viewerjumpto ”Options” ”aei##options”}{...}
{viewerjumpto ”Stored results” ”aei##results”}{...}
{viewerjumpto "Examples" "aei##examples"}{...}
{viewerjumpto "Speed tests" "aei##speed"}{...}
{viewerjumpto ”Authors” ”aei##authors”}{...}
{title:Title}

{pstd}aei{hline 2}Testing Axioms of Revealed Preference{p_end}
{p2colreset}{...}

{marker syntax}
{title:Syntax}

{p 8 15 2}
{cmd:aei}{cmd:,}
{it: price(mname) quantity(mname)} [{it: options}]
{p_end}


{synoptset 26 tabbed}{...}
{synopthdr:options}
{synoptline}

{synopt :{opth ax:iom(aei##options:axiom)}} axiom for testing data; default is {bf: axiom(eGARP)}.
In total, there are six axioms that can be tested: eGARP, eSGARP, eWARP, eWGARP, eSARP, eHARP and eCM.{p_end}

{synopt :{opth tol:erance(aei##options:tolerance)}} tolerance level in termination criterion 10^-2{it:n}}; default is {bf:tolerance(6)}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd: aei} calculates measures of goodness-of-fit when the data violates the revealed preference axiom.

{pstd}
{cmd: aei} is the second in a series of three commands for testing axioms of revealed preference.
The other two commands are {cmd: checkax} (which tests whether consumer demand data satisfy certain revealede preference axioms at a given efficiency level) and {cmd: powerps} (which 
calculates the power against uniform random behavior and predictive success for the axioms at any given efficienecy level).

{pstd}
{cmd: aei} is dependent on {cmd: checkax}.

{pstd}
For further details on the commands, please see {bf: Demetry, Hjertstrand and Polisson (2020) {browse "https://www.ifn.se/media/xf4bpowg/wp1342.pdf" :"Testing Axioms of Revealed Preference in Stata"}. IFN Working Paper No. 1342}.

{marker options}{...}
{dlgtab: Options }

{synopt :axiom}  specifies which axiom the user would like to use in testing the data for consistency. The default is {bf: axiom(eGARP)}.
In total, there are six axioms that can be tested: eGARP, eWARP, eWGARP, eSARP, eHARP and eCM. Axiom(all) uses all six axioms.{p_end}

{synopt :tolerance} sets the tolerance level in the termination criterion 10^-{it:n} by specifying the integer number {it: n}.
For example, {bf: tolerance(10)} sets the tolerance level in the termination criterion to 10^-10. The default is 
{bf: tolerance(6)}, which gives the default tolerance level 10^-6. The integer {it: n} in the termination criterion 10^-{it:n}
cannot be smaller than 1 or larger than 18.{p_end}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:aei} stores the following in {cmd:r()}. Notice that results are suffixed by the {it:axiom} being tested except for results that apply to all axioms, i.e. number of goods and observations, and tolerance level.

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(AEI_{it:axiom})}}AEI for the axiom being tested{p_end}
{synopt:{cmd:r(TOL)}}tolerance level for termination criterion{p_end}
{synopt:{cmd:r(GOODS)}}number of goods in the data{p_end}
{synopt:{cmd:r(OBS)}}number of observations in the data{p_end}

{p2col 5 15 19 2: Macros}{p_end}
{synopt:{cmd:r(AXIOM)}}axiom(s) being tested{p_end}


{marker examples}{...}
{title:Examples: Loading data and running the command}

{pstd}Install package{p_end}
{phang2}. {stata ssc install rpaxioms}{p_end}

{pstd}Download example data (from ancillary files){p_end}
{pstd}Note: the downloaded file is in your current working directory{p_end}
{phang2}. {stata net get rpaxioms}{p_end}

{pstd}Load example data {p_end}
{phang2}. {stata use rpaxioms_example_data.dta, clear}{p_end}

{pstd}In the example dataset provided, we have 20 observations of the prices and quantities of five goods.
These have variable names p1, ..., p5 for prices, and x1, ..., x5 for quantities.{p_end}

{pstd}In order to use the command, we need to create a matrix for prices
(where each column is a good and each row is an observation).
Likewise, we need to create a matrix for quantities.{p_end}
{pstd}Make matrices P and X from variables{p_end}
{phang2}. {stata mkmat p1-p5, matrix(P)}{p_end}
{phang2}. {stata mkmat x1-x5, matrix(X)}{p_end}

{pstd}We now have two 20x5 matrices; one for prices and one for quantities.{p_end}
{phang2}. {stata matlist P}{p_end}
{phang2}. {stata matlist X}{p_end}

{pstd}Run command with default settings{p_end}
{phang2}. {stata aei, price(P) quantity(X)}{p_end}

{pstd}Run command with eGarp and eHARP, at tolerance level 10^-8{p_end}
{phang2}. {stata aei, price(P) quantity(X) ax(eGARP eHARP) tol(8)}{p_end}

{pstd}Run command with all axioms, at tolerance level 10^-8{p_end}
{phang2}. {stata aei, price(P) quantity(X) ax(all) tol(8)}{p_end}

{title:Examples: Interpreting the results}
Running the last line above produces the following results:


    Number of obs           =         20 
    Number of goods         =          5 
    Tolerance level         =    1.0e-08 

-------------------------
       Axiom |       AEI 
-------------+-----------
       eGARP |  .9055851 
      eSGARP |  .7672872 
      eWGARP |  .9055851 
       eSARP |  .9055851 
       eWARP |  .9055851 
       eHARP |  .8449687 
         eCM |  .8473896 
-------------------------


Regardless of which (or how many) {opt axiom}(s) are tested, in your results window you will always
see the number of observations and goods as well as the tolerance level in the top-right corner.

In the table, you will find two columns - {it: Axiom} and AEI.
The column {it: Axiom} specifies which axioms are being tested. 
The column {it: AEI} specifies the efficiency level at which the data would satisfy respective axiom.

The AEI gives the largest efficiency level such that the data satisfies a certain revealed preference axiom.
Looking, for instance, at eGARP, the results indicate that the consumer can obtain the same level of utility
by spending approximately 10% less of her budget. Alternatively, looking at eCM, these results says that the 
consumer can obtain the same level of quasilinear utility by spending approximately 15% less of her budget. If 
these numbers are small or large is subjective. The literature has suggested cut-off levels at 80% up to 95%, 
but it has also been argued that this level should depend on the problem at hand, that is, the number of 
observations, the power of the test, and the model (axiom) under consideration. Therefore, we encourage users
to decide for themselves whether they consider a reported efficiency level to be small or large.


{marker speed}{...}
{title:Speed tests}
Using the example dataset provided with the package, 100 iterations of
{cmd: aei, price(P) quantity(X) axiom(eGARP)} yields the following
average execution time in seconds (per tolerance level).

--------------------------------------------
Tolerance |   Seconds  |  Seconds (M1 Pro)  
----------+------------+--------------------
        1 |    .02862  |     .02066 
        2 |    .04477  |     .03477
        3 |    .06498  |     .04557
        4 |    .07968  |     .05636
        5 |    .09584  |     .06917
        6 |    .13889  |     .08139
        7 |    .13237  |     .09679
        8 |    .14709  |     .10281
        9 |    .1907   |     .11897
       10 |    .18423  |     .13022
       11 |    .21832  |     .14077
       12 |    .22341  |     .15464
       13 |    .25624  |     .16714
       14 |    .25038  |     .18041
       15 |    .28749  |     .1889
----------+------------+--------------------


The first speed test was performed on a MacBook Pro 15-inch, 2018 with a 2,6GHz 6-Core Intel Core i7
running on macOS Catalina version 10.15.4, and Stata/MP version 15.1.

The second speed test was performed on a Macbook Pro 16-inch, 2021 with 32GB memory and an Apple M1 Pro chip
running on macOS Monterey version 12.2.1, and Stata/MP version 17.0.

{marker authors}{...}
{title:Authors}

- Marcos Demetry, PhD student at Linnaeus University, Sweden, and affiliated doctoral student at
 the Research Institute of Industrial Economics, Sweden.
- Per Hjertstrand, Associate Professor and Research Fellow at the Research Institute 
of Industrial Economics, Sweden.
- Matthew Polisson, Senior Lecturer and Researcher at University of Bristol, UK.



