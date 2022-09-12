/***
{hline}
help for {hi:exbsample}{right:P. Van Kerm (September 2022)}
{hline}

Title
===== 

__exbsample__  {hline 2} Exchangeably weighted (or Bayesian) bootstraps

Syntax
------ 

> __exbsample__ _#_  [_if_] [_in_]  [_weight_]  [using _filename_] [, _options_]

_#_ is the desired number of bootstrap replicates. 


| _option_                                   |  _Description_                                             |
|:-------------------------------------------|:-----------------------------------------------------------|
| stub(_name_)                               | prefix of bootstrap weight variables generated             | 
| **d**istribution(poisson _or_ exponential) | choice of bootstrap weight distribution                    |
| norescale                                  | disable scaling of weights to unit mean                    |
| **bal**ance(_#_)                           | request balancing of bootstrap weights (in _#_ iterations) |
| seed(_#_)                                  | set random-number seed to  _#_                             |
| **str**ata(_varlist_)                      | variables identifying strata                               |
| **cl**uster(_varlist_)                     | variables identifying clusters                             |
| **svy**setttings                           | reads strata and cluster identifiers from __svyset__       |
| **id**vars(_varlist_)	 	                 | variables uniquely identifying bootrapped units in new frame or data file |
| **fr**ame(_name_ [, **link**varname(_varname_) replace nofrlink])	 |     |
| 	 |  save bootstrap weight variables in a separate frame _name_ and links to the current frame using variable _varname_  (unless _nofrlink_ is specified)  |
| replace                                    | replace frame _name_ or file _filename_ or variables _stub*_  if they exist |
| nodots                                     | do not display dots                                        |

__fweight__, __pweight__ or __iweight__ are allowed.

Description
-----------

__exbsample__ generates bootstrap replication weights for implementation of 
exchangeably weighted bootstrap schemes, also known as the Bayesian bootstrap. It can be used as an alternative to __bsample__. 
 
Exchangeably weighted bootstrap schemes (or weighted, or exchangeable bootstraps) are 
alternatives to the traditional non-parametric (paired) bootstrap. Standard bootstrap 
replications involve generating bootstrap samples of size _N_ by drawing with replacement 
from the original data. Such a bootstrap resample can be seen as a frequency weighted 
version of the original data, with integer weights representing the number of times each observation
is drawn in a resample. (See the __weight__ option of Stata's bootstrap drawing command __bsample__.)
Exchangeably weighted bootstrap schemes can be seen as extensions of this representation: 
bootstrap resamples are created by generating replication weights directly from appropriate distribution functions. 
See Praestgaard and Wellner (1993) for details. This technique is also known as the Bayesian bootstrap (Rubin, 1981).

__exbsample__ generates weights based on draws from a Poisson distribution or from an exponential distribution (both with unit mean).
Drawing from the Poisson distribution generates integer weights 0, 1, 2, ... the distribution of which approximates the multinomial 
distribution that standard resampling weights effectively follow. 
Drawing from the exponential distribution generates strictly positive, non-integer weights. Draws from the exponential distribution 
can be seen as continuous (smoothed) versions of the Poisson draws. The advantage of exponential draws is the absence of 
zero weights: all observations from the original data are kept in the bootstrap resamples, albeit with possibly small weights. 
This can have practical computational advantages. In both cases, replication weights are, by default, scaled to sum to the sample size _N_.

Once replication weight variables are generated, they can be used by __svy bootstrap__ for bootstrap inference. (__svyset__ __,bsrweight(...)__ needs to be set accordingly.) 
Also see J. Pitblado's __bs4rw__. 

Stratified and/or clustered sampling is handled by specifying strata and cluster
identifiers (as in {cmd:bsample}); samples of clusters are `drawn' independently
across strata -- observations from the same cluster all have the same weight and weights sum to the number of clusters.

Observations that do not meet the optional _if_ and _in_ criteria are excluded from the bootstrap replications. 

If an __fweight__, __pweight__ or __iweight__ is given, the Poisson or exponential bootstrap replication weights are multiplied by the weight expression.

The replication weight variables generated are added to the data in memory by default. They can alternatively be saved in a separate file if __using__ _filename_ is specified or in a separate frame with the option __frame__.

Options
-------

{phang}
{opth stub(name)} determines the name of the bootstrap weight variables generated. Replication weight variables are named {it:name1}, {it:name2}, etc. Default is _bootvar1_, bootvar2_, etc. 

{phang}
{opth distribution(name)} selects the bootstrap weight distribution; name is __exponential__ (the default) or __poisson__.

{phang}
{opt norescale} disable scaling of replication weight variables to sum to the number of observations (or clusters). 

{phang}
{opth balance(#)} requests balancing of weights across all replications. Standard bootstrap balancing ensures that each observation in the data is drawn the same number of times in the overall set of resamples. Balancing is implemented here by scaling resampling weights `horizontally' (i.e., across replications for each observation) so that they sum to the number of bootstrap replications. To obtain both balancing (horizontal) and scaling (vertical), the two scaling steps are iterated _#_ number of times. (Default is 0 which implies _no_ balancing.)

{phang}
{opt seed(#)} sets the random number generator seed to _#_ prior to generating replication weight draw. 

{phang}
{opth strata(varlist)} specifies the variables identifying strata. If {opt strata()} is specified, bootstrap replication weights are scaled to sum to the number of clusters in each stratum. 

{phang}
{opth cluster(varlist)} specifies the variables identifying resampling clusters (primary sampling units).  If {opt cluster()} is specified, one replication weight is drawn per cluster and is shared across all observations in the cluster.

{phang}
{opt svysettings} requests that strata and cluster information is read from the settings of the dataset, as determined by __svyset__.

{phang}
{opth idvars(varlist)} identifies variables that uniquely identify the bootrapped units. This is required when replication weights are stored in a separate frame or data file: the variables in __idvars__ are saved alongside the replication weights to allow matching to the dataset in memory.

{phang}
{opth frame(name)}  requests that bootstrap replication weight variables are stored in a new, separate frame named _name_ (and not in the current frame in memory). A frame linkage is created to the current frame unless the _nofrlink_ sub-option is specified. The link variable is given in {cmd:linkvarname(}{it:varname}{cmd:)} (BOOTSTRAPLINK by default). 

{phang}
{opt replace} requests that frame _name_ or file _filename_ or variables _stubX_  are replaced if they already exist.

{phang}
{opt nodots} disables display of dots.

Examples
--------

    Generate simple replication weights from exponential distribution:

        . sysuse auto 
        . exbsample 499 , stub(rw)
        . summarize rw1 rw2 rw499
        . svyset , bsrweight(rw1-rw499) 
        . svy bootstrap : regress price trunk i.foreign
		
    Select Poisson weights and save weights in separate dataset:

        . sysuse auto 
        . exbsample 499   using replications-weights.dta   , stub(rw)  distribution(poisson) idvars(make) 

    Select Poisson weights, disable weight scaling and save weights in separate frame:

        . sysuse auto 
        . exbsample 499  , stub(rw)  distribution(poisson) norescale frame(replications , link(bootvarlink))  idvars(make)
        . frget rw1, from(bootvarlink)
        . regress price trunk i.foreign [iw=rw1]
        . frame change replications 
        . summarize rw1 rw2 rw499 
 
See Van Kerm (2022) for more examples.		

Citation suggestion
-------------------

Van Kerm, P. (2022). exbsample {c -} Stata module for exchangeably weighted (or Bayesian) bootstraps, Statistical Software Components, Boston College Department of Economics.

Also see
--------

{psee}
Online:  {manhelp bsample R}, {helpb rhsbsample} (if installed), {helpb gsample} (if installed), {helpb bsweights} (if installed), {helpb bs4rw} (if installed)
{p_end}

Author
------

Philippe Van Kerm   
Luxembourg Institute of Socio-Economic Research and University of Luxembourg

References
----------

Praestgaard, J. and Wellner, J. A. (1993), Exchangeably weighted bootstraps of the general empirical process, The Annals of Probability 21(4), 2053–2086.

Rubin, D. (1981), The Bayesian bootstrap, The Annals of Probability 21(4), 2053–2086.

Van Kerm, P. (2022). [Exchangeably weighted bootstrap schemes](http://ideas.repec.org/p/boc/usug22/). 2022 London Stata Users Group meeting, September 8-9 2022, University College London.


- - -

This help file was dynamically produced by 
[MarkDoc Literate Programming package](http://www.haghish.com/markdoc/) 
***/

** To build help file:  mini exbsample.ado , export(sthlp) replace 

*! v1.0.0, 2022-09-08, Philippe Van Kerm, Exchangeably Weighted Bootstrap
pr def exbsample  , sortpreserve sclass

  version 9.2
  syntax  [anything(name=N)]  [if] [in] [fw pw iw]  [using/] [,                  ///
				/// bootstrap choice 
				Distribution(string)			///
				norescale				///
				BALance(integer 0)  ///
                /// unique id, strata and cluster 
				CLuster(varlist)        ///
                STRata(varlist)         ///
                SVYsettings             ///
				/// storage options
				stub(name)				///
				IDvars(varlist) 			///
				FRame(string)				///
				replace					///
				/// misc
				seed(integer -1) ///
				nodots					///
                ]
				
	// 1. --- PARSING AND INITALIZATION ----
	
		// check non-empty file 
		if (_N==0) {
			di as error "No observations."
			exit 198
		}
		
		// number of replications
		if (`'"`N'"'=="") loc N 1
		confirm integer number `N'
				
		// draw type 
		if (!inlist("`distribution'","exponential","poisson","")) {
			di as error "name must be exponential or poisson in option distribution(name)"
			exit 198
		}
		if ("`distribution'"=="")  loc distribution exponential 
		
		// scaleing
		if ("`rescale'"=="")    loc adjust 1
		else 					loc adjust 0
		
		// nodots 
		if ("`dots'"!="")  loc quidots quietly 
		
        // mark observations
        marksample touse  
        qui markout `touse' `strata' `cluster' , strok
                
        // read svy settings if -svysettings- specified:
        if ("`svysettings'" != "") {
          if ("`: char _dta[_svy_version]'" == "") {
            di as error "svy settings not available"
            exit 198
          }
          if ("`cluster'" != "") {
            di as error "svysettings and cluster() options are mutually exclusive"
            exit 198
          }
          if ("`strata'" != "") {
            di as error "svysettings and strata() options are mutually exclusive"
            exit 198
          }
          local strata  : char _dta[_svy_strata1]
          local cluster : char _dta[_svy_su1]
        }
		
        // set strata and cluster if unspecidied 
		if ("`strata'"=="") {
			tempvar strata
			qui gen byte `strata' = 1 if `touse'
        }
        if (`"`cluster'"' == "") {
			tempvar cluster
			qui gen double `cluster' = _n if `touse'
        }          

		// `base' weight
		tempvar baseweight 
		if (`"`weight'"'!="") {
			qui gen double `baseweight' `exp'
			qui replace `baseweight' = `baseweight' * `touse'
			
		}   
		else {
			qui gen byte `baseweight' = `touse'  
		}
		
		// check stub and set default
		if ("`stub'"=="")  {
			di as text "No stub specified. Default is bootvar."
			local stub  bootvar 
		}
		
		// check that ID is passed if using or frame are used
		if  (  ( (`"`using'"'!="") | (`"`frame'"'!="") )  & ("`idvars'"=="") )    {
			di as error "Option idvars() is required if the replication weights are saved outside current dataset or frame." 
			exit 198
		}

		// check existing using file
		if ((`"`using'"'!="") & ("`replace'"==""))   confirm new file `using' 
		
		// parse frame and check existing frame
		_parse_frame `frame'
		if (`"`frame'"'!="") {
			if ("`replace'"=="")    confirm new frame `frame'
			else   					cap frame drop `frame'
		}	
		
		// check existing variables		
		if  ((`"`using'"'=="") & ("`frame'"=="")) {
			if ("`replace'"=="") {
				forvalues i = 1/`N' {
					confirm new variable `stub'`i' 
				}
			}	
			else {
				forvalues i = 1/`N' {
					cap drop `stub'`i' 
				}
			}	
		}

	// 2. --- GETTING FRAMES OR FILENAME IN SHAPE ----
		// prepare frame
		if ("`frame'"!="") {
			// create and move into new frame
			qui frame pwf
			loc currentframe	 `r(currentframe)'
			//frame create `frame' 
			qui frame put `idvars' `strata' `cluster' `baseweight' `touse'  if `touse' , into(`frame')
			qui frame change `frame' 
		}
		else {
			if ("`using'"!="") {
				// prepare empty file
				preserve 
				qui keep if `touse'
				keep `idvars' `strata' `cluster' `baseweight' `touse'
			}	
		}	
		
	// 3. --- GENERATE REPLICATION WEIGHTS   ----
	
		// create replication variables
		if (`seed'>-1) set seed `seed' 
		tempvar onecobs mndraw
		sort `touse' `strata' `cluster'
		qui egen `onecobs' = tag(`touse' `strata' `cluster')
		
		forvalues i = 1/`N' {
			`quidots' di "." _c
			qui gen double `stub'`i' = r`distribution'(1)  if `onecobs' & `touse' 
			if (`adjust'==1) {
				qui by `touse' `strata' : egen `mndraw' = mean(`stub'`i')  if `onecobs'
				qui replace `stub'`i' = `stub'`i'/`mndraw'
				drop `mndraw'
			}	
		}

		// balancing iterations (if balance>0 is specified)
		tempvar rowmn 
		forvalues biter=1/`balance' {
			qui egen `rowmn' = rowmean(`stub'*)  if `onecobs'
			forvalues i = 1/`N' {
				qui replace `stub'`i' = `stub'`i'/`rowmn'
				if (`adjust'==1) {
					qui by `touse' `strata' : egen `mndraw' = mean(`stub'`i')  if `onecobs'
					qui replace `stub'`i' = `stub'`i'/`mndraw'
					drop `mndraw'
				}	
			}
			drop `rowmn'
		}
		
		// copy values across clusters and mulitply base weights 
		forvalues i = 1/`N' {
			// copy to all in cluster 
			qui bys  `touse' `strata' `cluster' (`onecobs') : replace `stub'`i' = `stub'`i'[_N]  
			// mutliply base weights 
			qui replace `stub'`i' = `baseweight' * `stub'`i'
		}

		
	// 4. --- CLOSING  ----
		// wrap up frames and saved datasets
		if (`"`frame'`using'"'!="") {
			keep `idvars' `stub'1-`stub'`N'	
		}
		if (`"`using'"'!="")  {
			save `"`using'"' ,  `replace'
			if ("`frame'"=="") 	restore
		}
		if ("`frame'"!="") {
			qui frame change `currentframe'
			if ("`frlink'"=="") qui frlink m:1 `idvars' , frame(`frame') generate(`linkvarname')
		 }
		
		sreturn local N = `N'

end
		
pr def _parse_frame
	syntax [name] [ ,  LINKvarname(name) REPLACE noFRLINK ]
	if ("`namelist'"!="") {
		if ("`frlink'"=="") {
			if ("`linkvarname'"=="")  loc linkvarname  BOOTSTRAPLINK
			if ("`replace'"=="") confirm new var `linkvarname'
			else 				 cap drop `linkvarname'
		}
		c_local frame `namelist'
		c_local linkvarname `linkvarname'
		c_local frlink `frlink'
	}
end		

exit
Philippe Van Kerm
Luxembourg Institute of Socio-Economic Research and University of Luxembourg  
        


