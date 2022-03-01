{smcl}
{* *! version 1.00 23november2020}{...}
{viewerjumpto "Syntax" "powerps##syntax"}{...}
{viewerjumpto ”Description” ”powerps##description”}{...}
{viewerjumpto ”Options” ”powerps##options”}{...}
{viewerjumpto ”Stored results” ”powerps##results”}{...}
{viewerjumpto "Examples" "powerps##examples"}{...}
{viewerjumpto ”Authors” ”powerps##authors”}{...}
{title:Title}

{pstd}powerps{hline 2}Testing Axioms of Revealed Preference{p_end}
{p2colreset}{...}

{marker syntax}
{title:Syntax}

{p 8 15 2}
{cmd:powerps}{cmd:,}
{it: price(mname) quantity(mname)} [{it: options}]
{p_end}


{synoptset 26 tabbed}{...}
{synopthdr:options}
{synoptline}

{synopt :{opth ax:iom(powerps##options:axiom)}} axiom for testing data; default is {bf: axiom(eGARP)}.
In total, there are six axioms that can be tested: eGARP, eSGARP, eWARP, eWGARP, eSARP, eHARP and eCM.
To test all axioms at once, specify {bf: axiom(all)}.{p_end}

{synopt :{opth eff:iciency(powerps##options:efficiency)}} efficiency level for testing data, where 0 < efficiency =< 1; default is {bf:efficiency(1)}.{p_end}

{synopt :{opth sim:ulations(powerps##options:simulations)}} number of repititions of the simulated uniformly random data; default is {bf:simulations(1000)}.{p_end}

{synopt :{opth seed:(powerps##options:seed)}} seed in generation of Dirichlet random numbers; default is {bf:seed(12345)}.{p_end}

{synopt :{opth aei:(powerps##options:aei)}} compute AEI for each simulated uniformly random data set and every specified axiom; default is {bf:aei} {it:not} specifiede.{p_end}

{synopt :{opth tol:erance(powerps##options:tolerance)}} tolerance level in termination criterion 10^-{it:n}; default is {bf:tolerance(6)}.{p_end}

{synopt :{opth progress:bar(powerps##options:progress)}} displays number of repititions that have been executed; default is {bf: progressbar} {it: not} specified.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd: powerps} calculates the power against uniform random behavior and predictive success for the axioms at any given efficiency level.

{pstd}
{cmd: powerps} is the third in a series of three commands for testing axioms of revealed preference.
The other two commands are {cmd: checkax} (which tests whether consumer demand data satisfy certain revealede preference axioms at a given efficiency level) and 
{opt aei} (which calculates measures of goodness-of-fit wheen the data violates the axioms).

{pstd}
{cmd: powerps} is dependent on {cmd: checkax} and {cmd: aei}.

{pstd}
For further details on the commands, please see {bf: Demetry, Hjertstrand and Polisson (2020) {browse "https://www.ifn.se/media/xf4bpowg/wp1342.pdf" :"Testing Axioms of Revealed Preference in Stata"}. IFN Working Paper No. 1342}.

{marker options}{...}
{dlgtab: Options }

{synopt :axiom}  specifies which axiom the user would like to use in testing the data for consistency. The default is {bf: axiom(eGARP)}.
In total, there are six axioms that can be tested: eGARP, eWARP, eWGARP, eSARP, eHARP and eCM. To test all axioms at once, specify {bf: axiom(all)}.{p_end}

{synopt :efficiency} specifies the efficiency 
level at which the user would like to test the data. The default efficiency level is {bf:efficiency(1)}.
Efficiency must be greater than zero and less than or equal to one.{p_end}

{synopt :simulations} specifies the number of repititions of the simulated uniformly random data; default is {bf:simulations(1000)}.{p_end}

{synopt :seed} specifies the random seed in generation of Dirichlet random numbers; default is {bf:seed(12345)}.{p_end}

{synopt :aei} specifies whether the user wants to compute the AEI for each simulated uniformly random data set and every specified axiom;
    default is {bf:aei} {it:not} specified.{p_end}

{synopt :tolerance} sets the tolerance level in the termination criterion 10^-{it:n} by specifying the integer number {it: n}.
    For example, {bf: tolerance(10)} sets the tolerance level in the termination criterion to 10^-10. The default is 
    {bf: tolerance(6)}, which gives the default tolerance level 10^-6. The integer {it: n} in the termination criterion 10^-{it:n}
    cannot be smaller than 1 or larger than 18.{p_end}

{synopt :progressbar} displays number of repititions that have been executed. The default is {bf: progressbar} {it: not} specified.{p_end}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:powerps} stores the following in {cmd:r()}. Notice that results are suffixed by the {it:axiom} being tested except for results that apply to all axioms, i.e. number of goods and observations, as well as efficiency and tolerance levels.

{synoptset 20 tabbed}{...}
{p2col 5 20 19 2: Scalars}{p_end}
{synopt:{cmd:r(POWER_{it:axiom})}}computed power for each axiom{p_end}
{synopt:{cmd:r(PS_{it:axiom})}}computed predictive success for each axiom{p_end}
{synopt:{cmd:r(PASS_{it:axiom})}}indicator for whether data pass the axiom or not{p_end}
{synopt:{cmd:r(AEI_{it:axiom})}}AEI for the axiom being tested{p_end}
{synopt:{cmd:r(SIM)}}number of repeitions in the simulatede uniformly random data{p_end}
{synopt:{cmd:r(TOL)}}tolerance level for termination criterion, if option {opt aei} is specified{p_end}
{synopt:{cmd:r(EFF)}}efficiency level at which the axiom is tested{p_end}
{synopt:{cmd:r(GOODS)}}number of goods in the data{p_end}
{synopt:{cmd:r(OBS)}}number of observations in the data{p_end}

{p2col 5 20 19 2: Macros}{p_end}
{synopt:{cmd:r(AXIOM)}}axiom(s) being tested{p_end}

{p2col 5 20 19 2: Matrices}{p_end}
{synopt:{cmd:r(SUMSTATS_{it:axiom})}}summary statistics for random data: Num_vio, Frac_Vio (and {opt aei} if specified).{p_end}
{synopt:{cmd:r(SIMRESULTS_{it:axiom})}}Num_vio, Frac_Vio (and {opt aei} if specified) for every simulated uniformly random data set.{p_end}


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
{phang2}. {stata powerps, price(P) quantity(X)}{p_end}

This has an approximate runtime of six seconds.

{pstd}Run command with eGARP and eHARP{p_end}
{phang2}. {stata powerps, price(P) quantity(X) ax(eGARP eHARP) aei tol(6)}{p_end}

Note that running this command may take up to five minutes.
This is mainly due to including the option aei.

{title:Examples: Interpreting the results}

                       Number of obs           =        20 
                       Number of goods         =         5 
                       Simulations             =      1000 
                       Efficiency level        =         1 

----------------------------------------------------------
      Axioms |     Power         PS       Pass        AEI 
-------------+--------------------------------------------
       eGARP |      .995      -.005          0   .9055848 
       eHARP |         1          0          0   .8449683 
----------------------------------------------------------
 
Summary statistics for simulations:

-----------------------------------------------
       eGARP |      #vio       %vio        AEI 
-------------+---------------------------------
        Mean |    47.339   .1245762    .842074 
   Std. Dev. |  29.45589   .0775135   .0814885 
         Min |         0          0   .5616641 
          Q1 |        24      .0632   .7924724 
      Median |        45      .1184   .8516641 
          Q3 |      68.5     .18025   .9015746 
         Max |       143      .3763          1 
-----------------------------------------------

-----------------------------------------------
       eHARP |      #vio       %vio        AEI 
-------------+---------------------------------
        Mean |        20          1   .7268926 
   Std. Dev. |         0          0   .0760639 
         Min |        20          1   .4819741 
          Q1 |        20          1   .6767941 
      Median |        20          1   .7307339 
          Q3 |        20          1   .7845821 
         Max |        20          1   .8955998 
-----------------------------------------------


These results indicate that GARP at an efficiency level of 1 has power against uniformly random
behavior equal to 99.5%. This means that the GARP test has enough empirical bite to reject the
notion of uniformly random behavior would the ‘true’ consumer behavior be generated as such.
Since GARP is necessary for HARP, the latter will always have higher power. The predictive
success (PS) suggests that HARP marginally dominates GARP as a measure of model fit, i.e.,
the homothetic utility maximization model weakly dominates the standard utility
maximization model for these data.


{marker authors}{...}
{title:Authors}

- Marcos Demetry, PhD student at Linnaeus University, Sweden, and affiliated doctoral student at
 the Research Institute of Industrial Economics, Sweden.
- Per Hjertstrand, Associate Professor and Research Fellow at the Research Institute 
of Industrial Economics, Sweden.
- Matthew Polisson, Senior Lecturer and Researcher at University of Bristol, UK.

