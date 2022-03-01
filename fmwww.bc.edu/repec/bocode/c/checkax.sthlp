{smcl}
{* *! version 2.00 31january2022}{...}
{viewerjumpto ”Syntax” "checkax##syntax"}{...}
{viewerjumpto ”Description” "checkax##description"}{...}
{viewerjumpto ”Options” "checkax##options"}{...}
{viewerjumpto ”Stored results” "checkax##results"}{...}
{viewerjumpto "Examples" "checkax##examples"}{...}
{viewerjumpto ”Authors” "checkax##authors"}{...}
{title:Title}

{pstd}checkax{hline 2}Testing Axioms of Revealed Preference{p_end}
{p2colreset}{...}

{marker syntax}
{title:Syntax}

{p 8 15 2}
{cmd:checkax}{cmd:,}
{it: price(mname) quantity(mname)} [{it: options}]
{p_end}


{synoptset 26 tabbed}{...}
{synopthdr:options}
{synoptline}

{synopt :{opth ax:iom(checkax##options:axiom)}} axiom for testing data; default is {bf: axiom(eGARP)}.
Axioms that can be tested: eGARP, eSGARP, eWARP, eWGARP, eSARP, eHARP and eCM.{p_end}

{synopt :{opth eff:iciency(checkax##options:efficiency)}} efficiency level for testing data, where 0 < efficiency <= 1; default is {bf:efficiency(1)}.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{opt checkax} allows the user to test whether consumer demand data satisfy certain revealed preference axioms at a given efficiency level.

{pstd}
{opt checkax} is the first in a series of three commands for testing axioms of revealed preference.
The other two commands are {opt aei} (which calculates measures of goodness-of-fit when the data violates the axioms) and {opt powerps} (which 
calculates the power against uniform random behavior and predictive success for the axioms at any given efficienecy level).

{pstd}
For further details on the commands, please see {bf: Demetry, Hjertstrand and Polisson (2020) {browse "https://www.ifn.se/media/xf4bpowg/wp1342.pdf" :"Testing Axioms of Revealed Preference in Stata"}. IFN Working Paper No. 1342}.

{marker options}{...}
{dlgtab: Options }

{synopt :axiom}  specifies which axiom the user would like to use in testing the data for consistency.
The default is {bf: axiom(eGARP)}. In total, there are six axioms that can be tested: eGARP, eWARP, eWGARP, eSARP, eHARP and eCM.{p_end}

{synopt :efficiency} specifies the efficiency 
level at which the user would like to test the data. The default efficiency level is {bf:efficiency(1)}.
Efficiency must be greater than zero and less than or equal to one.{p_end}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:checkax} stores the following in {cmd:r()}. Notice that results are suffixed by the {it:axiom} being tested except for results that apply to all axioms, i.e. number of goods and observations, and efficiency level.

{synoptset 20 tabbed}{...}
{p2col 5 20 19 2: Scalars}{p_end}
{synopt:{cmd:r(PASS_{it:axiom})}}indicator for whether data pass the axiom or not{p_end}
{synopt:{cmd:r(NUM_VIO_{it:axiom})}}number of violations{p_end}
{synopt:{cmd:r(FRAC_VIO_{it:axiom})}}fraction of violations{p_end}
{synopt:{cmd:r(GOODS)}}number of goods in the data{p_end}
{synopt:{cmd:r(OBS)}}number of observations in the data{p_end}
{synopt:{cmd:r(EFF)}}efficiency level at which the axiom is tested{p_end}

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
{phang2}. {stata checkax, price(P) quantity(X)}{p_end}

{pstd}Run command with eGarp and eHARP, at efficiency level 0.95{p_end}
{phang2}. {stata checkax, price(P) quantity(X) ax(eGARP eHARP) eff(0.95)}{p_end}


{title:Examples: Interpreting the results}
Running the last line above produces the following results:

              Number of obs           =      20 
              Number of goods         =       5 
              Efficiency level        =     .95 

-----------------------------------------------
       Axiom |      Pass       #vio       %vio 
-------------+---------------------------------
       eGARP |         0        104      .2737 
       eHARP |         0         20          1 
-----------------------------------------------


{pstd}Regardless of which (or how many) {opt axiom}(s) are tested, in your results window you will always
see the number of observations and goods as well as the efficiency level in the top-right corner.{p_end}

{pstd}In the table, you will find four columns - {it: Axiom}, Pass, #vio and %vio.
The column {it: Axiom} specifies which axioms are being tested. 
The column {it: Pass} specifies whether the data satisfy respective axiom.
The column {it: #vio} specifies the number of violations of respective axiom.
The column {it: %vio} specifies the share of violations (as a share of the total possible number of violations).{p_end}

{pstd}In this example, we allow a ‘margin of error’ of 5%, meaning that we will only count bundles whose
cost is less than 95% of an observed choice as being revealed worse than that choice.{p_end}

{pstd}When checking if GARP is satisfied at this efficiency level, we find that 27.37% of all comparisons
indicate a violation of GARP. Hence, taking this number as fairly large, we may conclude that these
data cannot be rationalized by a continuous, strictly increasing and concave utility function.
Testing the data for HARP, which in addition to continuity, monotonicity and concavity also ensures
that the rationalizing utility function is homothetic, we find that all comparisons (100%) indicate
a violation of HARP. Thus, using the fraction of violations as a measure of the degree of
violations, these results show compelling evidence against that the data can be rationalized by a
well-behaved and homothetic utility function.{p_end}

{title:Examples: Looping over efficiency levels and storing output}

{pstd}Let's say you want to plot the fraction of violations of eGARP over different efficiency levels - specifically,
between efficiency(0.9) and efficiency(1) at increments of 0.001. Using the same data as in the first example,
we could do the following:{p_end}

	{hline}
{phang2}{cmd:. matrix results = J(101, 2, .)}{p_end}
{phang2}{cmd:. local row_nr = 1}{p_end}

{phang2}{cmd:. forvalues i = 0.90(0.001)1.00 {c -(} }{p_end}
{phang2}{cmd:. 			quietly checkax, price(P) quantity(X) axiom(eGARP) efficiency(`i')}{p_end}
{phang2}{cmd:. 			matrix results[`row_nr', 1] = `r(EFF)'}{p_end}
{phang2}{cmd:. 			matrix results[`row_nr', 2] = `r(FRAC_VIO_eGARP)'}{p_end}
{phang2}{cmd:. 			local row_nr = `row_nr' + 1}{p_end}
{phang2}{cmd:. {c )-} }{p_end}
{phang2}{cmd:. matlist results}{p_end}
	{hline}



{marker authors}{...}
{title:Authors}

- Marcos Demetry, PhD student at Linnaeus University, Sweden, and affiliated doctoral student at
 the Research Institute of Industrial Economics, Sweden.
- Per Hjertstrand, Associate Professor and Research Fellow at the Research Institute 
of Industrial Economics, Sweden.
- Matthew Polisson, Senior Lecturer and Researcher at University of Bristol, UK.

