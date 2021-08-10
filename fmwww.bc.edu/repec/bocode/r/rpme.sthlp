{smcl}
{* 20APR2012}{...}
{hi:help rpme}
{hline}

{title:Title}


{pstd}{hi:rpme} {hline 2} Robust Pareto midpoint estimator

{title:Syntax}
{p 8 16 2}
{cmd:rpme} {cases} {min} {max} {ifin}, [saving(dataset) by(id) {it:options}]
{p_end}

{synoptset 25 tabbed}{...}
{marker opt}{synopthdr:options}
{synoptline}
{synopt :{opt pareto_stat}} statistic used instead of the midpoint in the top bin. The default value is harmonic, for harmonic mean.  Alternatives include arithmetic, geometric, and median, for the arithmetic mean, geometric mean, and median, respectively.
{p_end}

{synopt :{opt alpha_min}} minimum value for the Pareto shape parameter alpha. The default value of 1 is appropriate if the pareto_stat option  is harmonic, geometric, or median. If pareto_stat is arithmetic, then alpha_min should be 2. See von Hippel, Scarpino, and Holas (2014) for simulation results and theoretical arguments justifying these recommendations. 
    {p_end} 
     
	
{title:Description}

{pstd} {cmd:rpme} implements the robust Pareto midpoint estimator described by von Hippel, Scarpino, and Holas (2014). 
 {cmd:rpme} assumes that the data are "binned" (a.k.a. grouped, bracketed, interval-censored) so that each row reports how many cases have values in the interval (min,max).
 Binned data are commonly used to summarize the distribution of income or wealth across individuals, households, or families.
 From the binned data, {cmd:rpme} estimates summary statistics including the mean, median, standard deviation, Gini, Theil, 
 and other inequality statistics.

 {pstd} rpme assumes that the command egen_inequal has already been installed. To install that command, type "ssc install egen_inequal".

{title:Estimation Details}

{pstd} {cmd:rpme} accepts three arguments in order cases (number of cases per bin), min (lower limit of bin), max (upper limit of bin) and assigns each case to 
the midpoint of the interval (min,max). 
If max is missing from the top bin, {cmd:rpme} assigns cases to a bin mean estimated by fitting a Pareto curve to the top two populated bins.

{pstd} The estimator is described by von Hippel, Scarpino, and Holas (2015). It is a robust version of an estimator proposed by Henson (1967).
The robustness comes from the following modifications: (1) omitting unpopulated bins, (2) constraining the Pareto shape parameter to be at least alpha_min,
 and (3) replacing the sensitive arithmetic mean with a more robust statistic such as the harmonic mean.
Without these modifications, the estimator would be unusable in small samples. With these modifications, and at least 8 bins, the {cmd:rpme} estimator is approximately as accurate --
 and much faster -- than more complex estimators based on fitting distributions from the generalized beta family (von Hippel, Scarpino, and Holas 2014). 
With fewer than 8 bins, the {cmd:rpme} estimator does not perform as well. 

{title:Example}

{pstd} The following example uses binned data from every US county in 2006-10. It estimates the Gini and other statistics, and then compares the Gini estimates to the "true" Gini values for each county.
For details, see von Hippel, Scarpino, and Holas (2014).

. use county_bins, clear
/* Don't save estimates. */
. rpme households bin_min bin_max, by(fips)

/* Now save estimates and compare to true values. */
. rpme households bin_min bin_max, by(fips) saving(county_ests)
. use county_ests, clear
. merge 1:1 fips using county_true 
. twoway scatter gini gini_true  

{title:Saved Results}

{pstd}{cmd:rpme} saves estimates to the output file designated by the saving() option. Estimates include the mean, median, standard deviation, various inequality statistics, and the Pareto shape parameter alpha estimated from the binned data.

{title:Authors}

{p 4 4 2}
Paul T. von Hippel, University of Texas at Austin(paulvonhippel.utaustin@gmail.com).
{p_end}{p 4 4 2}
Daniel A. Powers, University of Texas at Austin(dpowers@austin.utexas.edu).
{p_end}

{title:References}

{p 4 4 2} von Hippel, P.T., Scarpino, S.W., and Holas, I. 2015 "Robust estimation of inequality from binned incomes." 
          {it: arXiv} working paper, http://arxiv.org/abs/1402.4061.

{p 4 4 2} Henson, Mary F. 1967. Trends in the Income of Families and Persons in the United States, 1947-1964. U. S. Dept. of Commerce, Bureau of the Census.


