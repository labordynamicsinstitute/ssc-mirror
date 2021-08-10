/*** DO NOT EDIT THIS LINE -----------------------------------------------------
Version: 2.1.2
Title: rcall
Description: seamless interactive __[R](https://cran.r-project.org/)__ in Stata.
The command automatically returns {help return:rclass} R objects with 
_integer_, _numeric_, _character_, _logical_, _matrix_, _data.frame_, _list_, and _NULL_ 
classes to Stata. It also allows passing Stata variable, dataset, 
macro, scalar, and matrix to R as well as load a dataframe from R 
to Stata automatically, 
which provides an automated reciprocal communication between Stata and R. For
more information and examples visit [rcall homepage](http://www.haghish.com/packages/Rcall.php).
----------------------------------------------------- DO NOT EDIT THIS LINE ***/

/***
Syntax
======

To call R from Stata use the following syntax

{p 8 16 2}
rcall [{help rcall##modes:{it:mode}}] [{cmd::}] [{it:R-command}]
{p_end}

the package also includes a few subcommands to facilitate integrating R in Stata

{p 8 16 2}
rcall [{help rcall##subcommand:{it:subcommand}}]
{p_end}

the following functions can be used to communicate data from Stata to R: 

{synoptset 22 tabbed}{...}
{synopthdr:Function}
{synoptline}
{synopt:{opt st.scalar(name)}}passes a scalar to R{p_end}
{synopt:{opt st.matrix(name)}}passes a matrix to R{p_end}
{synopt:{opt st.var(varname)}}passes a numeric or string variable to R{p_end}
{synopt:{opt st.data(filename)}}passes Stata data to R. without _filename_, the currently loaded data is used. {p_end}
{synopt:{opt st.load(dataframe)}}loads data from R dataframe to Stata{p_end}
{synoptline}
{p2colreset}{...}

programmers can use __rcall_check__ to evaluate the required version of R or R packages: 

{p 8 16 2}
{browse "http://www.haghish.com/packages/Rcall.php#check":{bf:rcall_check}} [{it:pkgname>=ver}] [{it:pkgname>=ver}] [...] , {opt r:version(ver)}
{p_end}

{marker modes}{...}
Modes
=====

The _mode_ changes the behavior of the package and it can be __vanilla__ or __sync__. 
When the _mode_ is not specified, R is called interactively which is the default 
mode. Finally, when the [{it:R-command}] is not specified, the console mode 
will be executed which simulates R console within Stata results window for interactive 
use. In all of these modes, __rcall__ returns _rclass_ objects from R to Stata. These 
modes are summarized below:

{* the new Stata help format of putting detail before generality}{...}
{synoptset 22 tabbed}{...}
{synopthdr:Mode}
{synoptline}
{synopt: __[vanilla](http://www.haghish.com/packages/Rcall.php#vanilla_mode)__ }Calls R non-interactively. This mode is advised for programmers 
who wish to embed R in Stata packages{p_end}

{synopt: __[sync](http://www.haghish.com/packages/Rcall.php#sync_mode)__ }executes R interactively and 
synchronizes _matrices_ and _scalars_ between 
R and Stata. Making a change in any of these objects in either Stata or 
R will change the object in the other environment.  
{p_end}

{synopt:[interactive](http://www.haghish.com/packages/Rcall.php#interactive_mode)}when the mode is not specified, R is called interactively 
which memorizes the actions, objects available in the R memory, the attached 
datasets, and the loaded packages. {p_end}

{synopt:[console](http://www.haghish.com/packages/Rcall.php#console_mode)}when the R command is not specified, R is called interactively 
and in addition, R console is simulated within the results windows of Stata. 
In the console mode users can type R commands directly in Stata and get the 
results back interactively. Similarly, the results are returned to Stata 
in the background and can be accessed in Stata when quiting the console 
mode. {p_end}
{synoptline}
{p2colreset}{...}

{marker subcommand}{...}
Subcommands
=================

__rcall__ allows a few subcommands which provide several features to facilitate 
working with the package interactivey. The subcommands are summarized in the 
table below: 

{* the new Stata help format of putting detail before generality}{...}
{synoptset 22 tabbed}{...}
{synopthdr:Subcommand}
{synoptline}
{synopt:[setpath](http://www.haghish.com/packages/Rcall.php#setpath_subcommand) {it:"path/to/R"}}permanently defines the path to executable 
R on the machine.{p_end}
{synopt:[clear](http://www.haghish.com/packages/Rcall.php#clear_subcommand)}erases 
the R memory and history in the interactive mode. {p_end}
{synopt:[describe](http://www.haghish.com/packages/Rcall.php#describe_subcommand)}returns 
the R version and paths to R, RProfile, and Rhistory {p_end}
{synopt:[history](http://www.haghish.com/packages/Rcall.php#history_subcommand)}opens
__Rhistory.do__ in do-file editor which stores the history of the 
interactive R session. {p_end}
{synopt:[site](http://www.haghish.com/packages/Rcall.php#site_subcommand)}opens
__Rprofile.site__ in do-file editor which is 
used for customizing R when is called from Stata. {p_end}
{synoptline}
{p2colreset}{...}

Description
===========

__[R statistical language](https://cran.r-project.org/)__ is a free software 
and programming langage for statistical computing and graphics. 
The rcall package combines the power of R with Stata, allowing the 
Stata users to call R interactively within Stata and communicate 
data and analysis results between R and Stata simultaniously. 

In other words, anytime an R code is executed, the R objects are available 
for further manipulation in Stata. 
R objects with 
_numeric_, _integer_, _character_, _logical_, _matrix_, _list_, and _NULL_ 
classes are automatically returned to Stata as {help return:rclass}. 

R objects with _data.frame_ class can be automatically loaded from R to 
Stata using the __st.load()__ function (see below).

__rcall__ uses the __try__ function to evaluate the R code and 
returns __r(rc)__ scalar which is an indicator for errors occuring in R. if __r(rc)__ 
equals zero, R has successfully executed the code. Otherwise, if __r(rc)__ equals 
one an error has occured and __rcall__ will return the error message and break the 
execution. 
 

Communication from R to Stata
======================================

Stata automatically receives R objects as {help return:rclass} anytime 
the rcall is executed. If R is running interactively 
(i.e. without __vanilla__ subcommand), the previous objects still remain accessable 
to Stata, unless they are changed or erased from R. Moreover, the packages 
that you load from Stata in R remain loaded until you detach them. 

Accessing R objects in Stata is simultanious which makes working with 
rcall convenient. For example a _numeric_, or _string_ vector which is 
defined in R, can be accessed in Stata as simple as calling the name of that 
object withing {help rclass} i.e. __r(_objectname_)__.  

A _numeric_ object example:

        . rcall: a <- 100 
        . display r(a)  	
        100 	
		
Without the __vanilla__ subcommand, the defined object remains in the memory of 
R and consequently, returned to Stata anytime R is called.

        . rcall: a 
        [1] 100 
		
A _string_ object example:
		
        . rcall: str <- "Hello World" 
        . display r(str)  	
        Hello World
		
        . rcall: str <- c("Hello", "World") 
        . display r(str)  	
        "Hello"  "World"
		
A _vector_ example:

        . rcall: v <- c(1,2,3,4,5)
        . display r(v)  	
        1 2 3 4 5

A _matrix_ example:

        . rcall: A = matrix(1:6, nrow=2, byrow = TRUE) 
        . mat list r(A) 
        r(A)[2,3]
            c1  c2  c3  	
        r1   1   2   3
        r2   4   5   6
		
A _list_ example:

        . rcall: mylist <- list(a=c(1:10))
        . display r(mylist_a) 
        1 2 3 4 5 6 7 8 9 10

A _logical_ example:

        . rcall: l <- T 
        . display r(l)
        TRUE
		
A _NULL_ example:

        . rcall: n <- NULL
        . display r(n)
        NULL	
		
Regarding communicating R data set to Stata automatically, see the 
__st.load(_dataframe_)__ function below. 
		
Communication from Stata to R
======================================

For an ideal reciprocation between Stata and R, Stata should also easily 
communicate variables to R. Local and global {help macro:macros} can be passed 
within R code, since Stata automatically interprets them while it passes the 
code to rcall command, as shown in the example below:

        . global a 99 
        . rcall: (a <- $a)  	
        [1] 99 		

In order to pass a {help scalar} from Stata to R, you can 
use the __st.scalar()__ function as shown below:

        . scalar a = 50 
        . rcall: (a <- st.scalar(a))  	
        [1] 50 		

Similarly, Stata {help matrix:matrices} can be seamlessly passed to R using 
the __st.matrix()__ function as shown below:

        . matrix A = (1,2\3,4) 
        . matrix B = (96,96\96,96) 		
        . rcall: C <- st.matrix(A) + st.matrix(B)
        . rcall: C 
             [,1] [,2]
        [1,]   97   98
        [2,]   99  100
 
And of course, you can access the matrix from R in Stata as well: 

        . mat list r(C) 
        r(C)[2,2]
             c1   c2
        r1   97   98
        r2   99  100

Passing variables from Stata to R is convenient, using the 
__st.var(_varname_)__ function. Therefore, any analysis can be executed in R 
simply by passing the variables required for the analysis from Stata to R:

        . sysuse auto, clear 
        . rcall: dep <- st.var(price)		
        . rcall: pre <- st.var(mpg)	
        . rcall: lm(dep~pre)
        
        Call:
        lm(formula = dep ~ pre)
        
        Coefficients:
        (Intercept)          pre  
            11267.3       -238.3

The rcall package also allows to pass Stata data to R within 
__st.data(_{help filename}_)__ function. This function relies on the __readstata13__ 
package in R to load Stata data sets, without converting them to CSV or alike. 
The __readstata13__ package 
[is faster and more acurate then __foreign__ and __haven__ packages](http://www.haghish.com/stata-blog/?p=21) 
and read Stata 13 and 14 datasets. This R package can be installed within Stata as follows:

        . rcall: install.packages("readstata13", repos="http://cran.uk.r-project.org")

Specify the relative or absolute path to the data set to transporting data 
from Stata to R. For example: 

        . rcall: data <- st.data(/Applications/Stata/ado/base/a/auto.dta) 
        . rcall: dim(data)

If the _filename_ is not specified, the function passes the currently loaded 
data to R. 

        . sysuse auto, clear 
        . rcall: data <- st.data() 
        . rcall: dim(data) 
        [1] 74 12
		
Finally, the data can be imported from R to Stata automatically, using the 		
__st.load(_dataframe_)__ function. This function will automatically save a 
Stata data set from R and load it in Stata by clearing the current data set, 
if there is any. Naturally, you can have more control over converting variable 
types if you write a proper code in R for exporting Stata data sets. Nevertheless, 
the function should work just fine in most occasions: 

        . clear 
        . rcall: st.load(cars) 
        . list in 1/2
        {c TLC}{hline 14}{c TRC}
        {c |} speed   dist {c |}
        {c LT}{hline 14}{c RT}
     1. {c |}     4      2 {c |}
     2. {c |}     4     10 {c |}
        {c BLC}{hline 14}{c BRC}

Remarks
=======

You should be careful with using Stata symbols in R. For example, the __$__ 
sign in Stata is preserved for global macros. To use this sign in R, you 
should place a backslash before it to pass it to R. For example:

        . rcall: head(cars\$speed)

Also, the object name in R can include a dot, for example:
 
        . rcall: a.name <- "anything" 
		
The rcall package returns scalars and locals which can only include 
underscore in the names (e.g. a_name). rcall automatically converts 
dots to underscore in the name. In the example above, if you type {cmd:return list} 
in Stata, you would get a macro as follos:

        . return list 
        r(a_name) : "anything"
		
To maximize the speed of calling R from Stata, 
detach the packages that are no longer needed and also, drop all the objects 
that are of no use for you. The more objects you keep in R memory, 
the more time needed to automatically communicate those objects between 
R and Stata.		

Example
=================

Visit [rcall homepage](http://www.haghish.com/packages/Rcall.php) for more examples and 
documentation. 

Author
======

__E. F. Haghish__     
Center for Medical Biometry and Medical Informatics     
University of Freiburg, Germany     
_and_        
Department of Mathematics and Computer Science       
University of Southern Denmark     
haghish@imbi.uni-freiburg.de     
      
[rcall Homepage](www.haghish.com/packages/Rcall.php)         
Package Updates on [Twitter](http://www.twitter.com/Haghish)     

- - -

This help file was dynamically produced by {help markdoc:MarkDoc Literate Programming package}
***/





*cap prog drop rcall
program define rcall , rclass
	
	*version 12
	
	// =========================================================================
	// Syntax processing
	//   - if the [:] appears first, it means the rest are not modes or subcommands
	//   - Process the rcall inputs
	//   - If R path not defined, and "setpath" not specified, search R path
	// =========================================================================
	
	if "$rcallwarning" == "" {
		di "{err:Warning}: rcall is no longer updated on SSC after version 2.1.2. visit" _n ///
        `"{browse "https://github.com/haghish/rcall/"}"' ///
        " to reinstall the package from GitHub"  
		
		global rcallwarning 1
	}
	
	macro drop RcallError								
	
	// -------------------------------------------------------------------------
	// Search R path, if not specified
	// =========================================================================
	capture prog drop Rpath
	capture Rpath
	tokenize `"`macval(0)'"'
	
	if `"`macval(1)'"' != "setpath" & `"`macval(1)'"' != "setpath:" {
		if missing("$Rpath") {
			
			if "`c(os)'" == "Windows" {
				
				// 1- try both "Program Files" and "Program Files (86)" 
				// 2- Get the list of directories that begin with R-*
				// 3- select the last one
				
				local wd : pwd
				capture quietly cd "C:\Program Files\R"
				if _rc != 0 {
					capture quietly cd "C:\Program Files (x86)\R"
					if _rc != 0 {
						display as err "R was not found on your system. Setup R path manually"
						exit 198
					}
				}
				local folder : pwd
				local Rdir : dir "`folder'" dirs "R-*", respectcase
				tokenize `"`Rdir'"'
				while `"`1'"' != "" {
					local newest_R `"`1'"'
					macro shift
				}
				quietly cd `"`newest_R'\bin"'
				local path : pwd
				local path : display "`path'\R.exe"	
				*global Rpath : display "`path'"  
				quietly cd "`wd'"
			}
			
			// for linux and Mac try 2 possible default paths
			else {
				local path "/usr/bin/r"
				capture confirm file "`path'"
				if _rc != 0 {
					local path "/usr/local/bin/R"
					global Rpath : display "`path'"
				}	
			}
			if !missing("`debug'") {
				di _n "{title:Path to R}" _n								///
				"The path to R was {err:guessed} to be:"  _n
				display `"{err:`path'}"'
			}
		}
		else {
			local path = "$Rpath"
			if !missing("`debug'") {
				di _n "{title:Path to R}" _n								///
				"The path to R was obtained from {err:Rpath.ado} to be:"  _n
				display `"{err:`path'}"'
			}
		}	

		capture confirm file "`path'"
		if _rc != 0 {
			di as txt "{p}R was expected in:    `path'"
			display as err "{bf:rcall} could not find R on your system"
			err 198
		}
	}
	
	// -------------------------------------------------------------------------
	// Input processing
	// =========================================================================
			
	// Check if the command includes Colon in the beginning or not
	// -----------------------------------------------------------
	if substr(trim(`"`macval(0)'"'),1,1) == ":" {
		local 0 : subinstr local 0 ":" ""
	}
	
	else {
		//check WHY windows version requierd this tokenize here and Mac doesn't!
		tokenize `"`macval(0)'"'

		// debug mode (begining)
		// ================
		*if substr(trim(`"`macval(0)'"'),1,5) == "debug" {
		if `"`macval(1)'"' == "debug" | `"`macval(1)'"' == "debug:" {
			local 0 : subinstr local 0 "debug" ""
			di as err `"02: `macval(0)'"'
			tokenize `"`macval(0)'"'						//reset
			local debug debug
			global debug 1
			if !missing("`debug'") {
				di _n "{title:[1/5] Debug mode}" _n									///
				"Running rcall in debug mode"
			}	
		}

		// clear R memory
		// ================
		if `"`macval(0)'"' == "clear" | `"`macval(0)'"' == "clear:" {
			capture erase .RData
			capture findfile RProfile.R, path("`c(sysdir_plus)'r")
			if _rc == 0 {
				capture erase "`r(fn)'"
			}
			capture findfile Rhistory.do, path("`c(sysdir_plus)'r")
			if _rc == 0 {
				capture erase "`r(fn)'"
				tempfile history
				tempname knot
				qui file open `knot' using "`history'", write text append
				file write `knot' "// Rhistory initiated on `c(current_date)'  `c(current_time)'" _n
				qui file close `knot'
				quietly copy "`history'" "`c(sysdir_plus)'r/Rhistory.do"
			}
			display as txt "(R memory cleared)"
			exit
		}
		
		// describe R
		// ================
		if `"`macval(0)'"' == "describe" | `"`macval(1)'"' == "describe:" {
			
			di as txt "{hline 79}"
			di _col(10) "{bf:R path}:" _col(20) _c 
			di as txt `"{browse "`path'$Rpath"}"' 
			
			rcall vanilla: version = R.Version()\$version.string;				///
				lst <- ls(globalenv());											
				
			di _col(7) "{bf:R version}:" _col(20) _c 
			if !missing("`r(version)'") di as txt "`r(version)'"
			else di as err "R was not accessed!"
			
			capture findfile RProfile.site, path("`c(sysdir_plus)'r")
			if _rc == 0 {
				di _col(7) "{bf:R profile}:" _col(20) _c 
				di as txt `"{browse "`r(fn)'"}"'
			}
			
			capture findfile Rhistory.do, path("`c(sysdir_plus)'r")
			if _rc == 0 {
				di _col(7) "{bf:R history}:" _col(20) _c 
				di as txt `"{browse "`r(fn)'"}"'
			}
			else {
				tempfile history
				tempname knot
				qui file open `knot' using "`history'", write text append
				file write `knot' "// Rhistory initiated on `c(current_date)'  `c(current_time)'" _n
				qui file close `knot'
				quietly copy "`history'" "`c(sysdir_plus)'r/Rhistory.do"
				
				di _col(7) "{bf:R History}:" _col(20) _c 
				di as txt "{browse `c(sysdir_plus)'r/Rhistory.do}"
			}
			
			di as txt "{hline 79}"
			exit
		}
	
		// Synchronize mode
		// ================
		if `"`macval(1)'"' == "sync" | `"`macval(1)'"' == "sync:" {
			local 0 : subinstr local 0 "sync" ""
			global Rcall_synchronize_mode on
			local mode sync
		}

		// Vanilla mode
		// ============
		*if substr(trim(`"`macval(0)'"'),1,7) == "vanilla" {
		if `"`macval(1)'"' == "vanilla" | `"`macval(1)'"' == "vanilla:" {
			local 0 : subinstr local 0 "vanilla" ""		
			local vanilla --vanilla
			if !missing("`debug'") {
				di _n "{title:Vanilla}" _n										///
				"Running R in non-interactive batch mode"
			}
			local mode vanilla
		}
		
		// debug mode AGAIN (ending)
		// =========================
		*if substr(trim(`"`macval(0)'"'),1,5) == "debug" {
		tokenize `"`macval(0)'"'
		if `"`macval(1)'"' == "debug" | `"`macval(1)'"' == "debug:" {
			local 0 : subinstr local 0 "debug" ""
			di as err `"02: `macval(0)'"'
			tokenize `"`macval(0)'"'						//reset
			local debug debug
			global debug 1
			if !missing("`debug'") {
				di _n "{title:[1/5] Debug mode}" _n								///
				"Running rcall in debug mode"
			}	
		}
		
		// Setpath
		// =======
		*else if substr(trim(`"`macval(0)'"'),1,7) == "setpath" {
		if `"`macval(1)'"' == "setpath" | `"`macval(1)'"' == "setpath:" {
			local 0 : subinstr local 0 "setpath" ""
			confirm file `0'
			tempfile Rpath
			tempname knot
			qui file open `knot' using "`Rpath'", write text replace
			file write `knot' "program define Rpath" _n
			file write `knot' `"	global Rpath `macval(0)'"' _n
			file write `knot' "end" _n
			qui file close `knot'
			qui copy "`Rpath'" "`c(sysdir_plus)'r/Rpath.ado", replace
			if !missing("`debug'") {
				di "{title:Memorizing R path}" _n									///
				`"the {bf:Rpath.ado} was created to memorize the path to `macval(0)'"' 
			}
			exit
		}
		
		// HISTORY
		// =======
		if `"`macval(1)'"' == "history" {
			local 0 : subinstr local 0 "history" ""
			capture findfile Rhistory.do, path("`c(sysdir_plus)'r")
			if _rc == 0 {
				*copy "`r(fn)'" Rhistory.do, replace
				*display as txt `"(Rhistory coppied to {browse "./Rhistory.do"})"'
				doedit "`r(fn)'"
			}
			else {
				display as txt "(Rhistory is empty)"
			}
			exit
		}
		
		// SITE
		// =======
		if `"`macval(1)'"' == "site" {
			local 0 : subinstr local 0 "site" ""
			capture findfile Rprofile.site, path("`c(sysdir_plus)'r")
			if _rc == 0 {
				doedit "`r(fn)'"
			}
			else {
				display as err "{bf:Rprofile.site} was not found!"
			}
			exit
		}
		
		
		
	

	
		// Check if the command includes Colon in the end
		if substr(trim(`"`macval(0)'"'),1,1) == ":" {
			local 0 : subinstr local 0 ":" ""
		}
	}	
	
	// -------------------------------------------------------------------------
	// Execute interactive mode (including sync)
	// =========================================================================
	if trim(`"`0'"') == "" {
		local mode interactive
		global Rcall_interactive_mode on
		
		// avoid the sync mode to get repeated in each trial
		*if "$Rcall_synchronize_mode" == "on" {	
		*	Rcall_synchronize
		*	global Rcall_synchronize_mode2 "on"
		*	macro drop Rcall_synchronize_mode
		*}
		
		if missing("`vanilla'") {
			Rcall_interactive
		}
		else {
			di as err "the {bf:vanilla} mode cannot be called interactively"
			err 198
		}
	}
	if !missing("`debug'") {
		di _n "{title:R command}" _n											///
		"The command that you wish to execute in {bf:R} is:" _n(2) 				///
		`"{err:`macval(0)'}"' 
	}
	
	// -------------------------------------------------------------------------
	// Create and update the history file
	// =========================================================================
	if missing("`vanilla'") {
		
		capture findfile Rhistory.do, path("`c(sysdir_plus)'r")
		if _rc == 0 {
			tempname knot
			qui file open `knot' using "`r(fn)'", write text append	
			if !missing(`"`macval(0)'"') {
				file write `knot' `"rcall `mode': `macval(0)'"' _n
			}
			qui file close `knot'
		}
		else {
			tempfile history
			tempname knot
			qui file open `knot' using "`history'", write text append
			file write `knot' "// Rhistory initiated on `c(current_date)'  `c(current_time)'" _n
			if !missing(`"`macval(0)'"') {
				file write `knot' `"rcall `mode': `macval(0)'"' _n
			}
			qui file close `knot'
			quietly copy "`history'" "`c(sysdir_plus)'r/Rhistory.do"
		}
	}
	
	
	
	// -------------------------------------------------------------------------
	// Searching for Matrix
	// =========================================================================
	while strpos(`"`macval(0)'"',"st.matrix(") != 0 {
		local br = strpos(`"`macval(0)'"',"st.matrix")
		local l1 = substr(`"`macval(0)'"',1, `br'-1)
		local l2 = substr(`"`macval(0)'"',`br',.)
		local l2 : subinstr local l2 "st.matrix(" ""
		local mt = strpos(`"`macval(l2)'"',")") 
		local mat = substr(`"`macval(l2)'"',1, `mt'-1)
		local l2 = substr(`"`macval(l2)'"',`mt'+1, .)
		if !missing("`debug'") {
			di _n "{title:st.matrix() function}" _n								///
			"You wish to pass Matrix {bf:`mat'} to {bf:R}. This will call "  	///
			"the {bf:matconvert.ado} function, which returns:"
			matconvert `mat'
		}
		qui matconvert `mat'
		local l2 = `"`r(`mat')'"' + "`l2'"		
		local 0 = `"`macval(l1)'"' + `"`macval(l2)'"'
	}
	
	// -------------------------------------------------------------------------
	// Searching for Scalar
	// =========================================================================
	while strpos(`"`macval(0)'"',"st.scalar(") != 0 {
		local br = strpos(`"`macval(0)'"',"st.scalar")
		local l1 = substr(`"`macval(0)'"',1, `br'-1)
		local l2 = substr(`"`macval(0)'"',`br',.)
		local l2 : subinstr local l2 "st.scalar(" ""
		local mt = strpos(`"`macval(l2)'"',")") 
		local sca = substr(`"`macval(l2)'"',1, `mt'-1)
		local l2 = substr(`"`macval(l2)'"',`mt'+1, .)
 		
		if !missing("`debug'") {
			di _n "{title:st.scalar() function}" _n								///
			"You wish to pass Scalar {bf:`sca'} to {bf:R}. This value is: "   
			display `sca'
		}
		
		local sca : display `sca'
		
		//If scalar is string, add double quote
		capture local test : display int(`sca')		
		if missing("`test'") & "`sca'" != "" {							
			local sca : display `"`sca'"'
			local l2 = `"""' + `"`macval(sca)'"' + `"""' + `"`l2'"'
		}
		else if "`sca'" != "" {
			local l2 = "`sca'" + "`l2'"
		}
		else {
			local l2 = `"`sca'"' + "`l2'"
		}
		local 0 = `"`macval(l1)'"' + `"`macval(l2)'"'
	}
	
	// -------------------------------------------------------------------------
	// Searching for Data
	// =========================================================================
	while strpos(`"`macval(0)'"',"st.data(") != 0 {
		local br = strpos(`"`macval(0)'"',"st.data")
		local l1 = substr(`"`macval(0)'"',1, `br'-1)
		local l2 = substr(`"`macval(0)'"',`br',.)
		local l2 : subinstr local l2 "st.data(" ""
		local mt = strpos(`"`macval(l2)'"',")") 
		local filename = substr(`"`macval(l2)'"',1, `mt'-1)
		local l2 = substr(`"`macval(l2)'"',`mt'+1, .)
		local foreign 1 						//load foreign package
		
		//IF THE NAME HAS A PRANTHESIS...
		if strpos(`"`macval(filename)'"',"(") != 0 {
			local filename : di `"`macval(filename)')"'
			local mt = strpos(`"`macval(l2)'"',")") 
			local filename2 = substr(`"`macval(l2)'"',1, `mt'-1)
			local l2 = substr(`"`macval(l2)'"',`mt'+1, .)
			local filename : di `"`macval(filename)'`macval(filename2)'"'
		}
		if !missing("`debug'") {
			di _n "{title:st.data() function}" _n								///
			"You wish to pass Stata data {bf:`filename'} to {bf:R}..."   
		}
		
		// Get rid of double quotes or add them! 
		cap local filename : display "`macval(filename)'"
		if _rc != 0 local filename : display `macval(filename)'
		
		//IF FILENAME IS MISSING
		if missing("`filename'") {
			if "`c(version)'" >= "14" {
				qui saveold _st.data.dta, version(11) replace
			}	
			else {
				qui saveold _st.data.dta, replace
			}	
			
			local dta : di "read.dta13(" `"""' "_st.data.dta" `"""' ")"    		
		}
		else {
			confirm file "`filename'"
			preserve
			qui use "`filename'", clear
			if "`c(version)'" >= "14" qui saveold _st.data.dta, version(11) replace 
			else qui saveold _st.data.dta, replace
			local dta : di "read.dta13(" `"""' "_st.data.dta" `"""' ")"
			restore
		}
		
		local l2 = `"`macval(dta)'"' + `"`macval(l2)'"'
		local 0 = `"`macval(l1)'"' + `"`macval(l2)'"'	
	}
	
	// make sure readstata13 is installed and updated regularly
	// -------------------------------------------------------------------------
	if "`foreign'" == "1" {
		capture rcall_check readstata13>=0.8.5 
		if _rc != 0 display as err "R package {bf:readstata13} version 0.8.3 "	///
		"is required. Type:" _n "{p}R: install.packages("												///
		`""readstata13", repos="http://cran.uk.r-project.org")"'
		
		// avoid slowing down rcall
		global Rcall_check 1
	}
	
	// -------------------------------------------------------------------------
	// Searching for Load Data
	// =========================================================================
	while strpos(`"`macval(0)'"',"st.load(") != 0 {
		local br = strpos(`"`macval(0)'"',"st.load")
		local l1 = substr(`"`macval(0)'"',1, `br'-1)
		local l2 = substr(`"`macval(0)'"',`br',.)
		local l2 : subinstr local l2 "st.load(" ""
		local mt = strpos(`"`macval(l2)'"',")") 
		local loaddata = substr(`"`macval(l2)'"',1, `mt'-1)
		local l2 = substr(`"`macval(l2)'"',`mt'+1, .)
		
		local foreign 1 						//load foreign package
		local forceload 1 						//load data to stata
		
		if !missing("`debug'") {
			di as txt _n "{title:st.load() function}" _n						///
			"You wish to force loading R data {bf:`loaddata'} to {bf:Stata}..." _n  
		}
		
		//IF FILENAME IS MISSING
		if missing("`loaddata'") {
			display as err "data frame is not specified"
			err 198
		}
		local 0 = `"`macval(l1)'"' + `"`macval(l2)'"'
		if !missing("`debug'") di _n `"`macval(0)'"'
	}
	
	// -------------------------------------------------------------------------
	// Searching for variable
	// =========================================================================
	while strpos(`"`macval(0)'"',"st.var(") != 0 {
		local br = strpos(`"`macval(0)'"',"st.var")
		local l1 = substr(`"`macval(0)'"',1, `br'-1)
		local l2 = substr(`"`macval(0)'"',`br',.)
		local l2 : subinstr local l2 "st.var(" ""
		local mt = strpos(`"`macval(l2)'"',")") 
		local mat = substr(`"`macval(l2)'"',1, `mt'-1)
		local l2 = substr(`"`macval(l2)'"',`mt'+1, .)
 		
		if !missing("`debug'") {
			di _n "{title:st.var() function}" _n								///
			"You wish to pass variable {bf:`mat'} to {bf:R}. This will call "  	///
			"the {bf:varconvert.ado} function, which returns:"
			varconvert `mat'
		}
		qui varconvert `mat'
		if "`r(type)'" == "numeric" {
			local l2 = "`r(`mat')'" + "`l2'"
			local 0 = `"`macval(l1)'"' + `"`macval(l2)'"'
		}
		if "`r(type)'" == "string" {
			local l2 = `"`r(`mat')'"' + "`l2'"
			local 0 = `"`macval(l1)'"' + `"`macval(l2)'"'
		}
	}
	
	
	*local line : subinstr local line "$" "_", all //avoid "$" in name
	// -------------------------------------------------------------------------
	// Create temporary Rscript file
	// =========================================================================
	capture findfile stata.output.R, path("`c(sysdir_plus)'s")
	if _rc != 0 {
		di as err "stata.output.R script file not found. reinstall the package"
		err 198
	}
	local source `r(fn)'
	
	//Change the stata.output.R path in Windows
	if "`c(os)'" == "Windows" {
		local source : subinstr local source "\" "/", all				 
	}
	
	
	capture findfile Rprofile.site, path("`c(sysdir_plus)'r")
	if _rc == 0 {
		local RSite `r(fn)'
	}
	
	capture findfile RProfile.R, path("`c(sysdir_plus)'r")
	if _rc == 0 {
		local RProfile `r(fn)'
	}
	
	// get the path to PLUS/r
	local plusR "`c(sysdir_plus)'r"
	
	//Change the stata.output.R path in Windows
	if "`c(os)'" == "Windows" {
		local RProfile : subinstr local RProfile "\" "/", all
		local RSite : subinstr local RProfile "\" "/", all
		local plusR : subinstr local plusR "\" "/", all
	}

	
	
	
	tempfile Rscript
	tempfile Rout
	tempname knot
	qui file open `knot' using "`Rscript'", write text replace
	
	if "$Rcall_interactive_mode" != "on" {
		if "$Rcall_synchronize_mode" == "on" {	
			Rcall_synchronize
			file write `knot' "source('Rcall_synchronize')" _n
		}
	}
	
	if !missing("`vanilla'") file write `knot' "rm(list=ls())" _n 				// erase memory temporarily
	if !missing("`foreign'") file write `knot' "library(readstata13)" _n		// load the readstata13 package
	if !missing("`RSite'") & missing("`vanilla'") 								///
			file write `knot' "source('`RSite'')" _n			
	if !missing("`RProfile'") & missing("`vanilla'") 							///
			file write `knot' "source('`RProfile'')" _n							// load the libraries 
	
	// -------------------------------------------------------------------------
	// Handling Errors
	//
	// catch the errors and return proper error
	// and only procede if the "rc" object is not missing
	// =========================================================================

	*file write `knot' `"`macval(0)'"' _n
	if trim(`"`macval(0)'"') != "" {
		file write `knot' "try({" `"`macval(0)'"' "})" _n
	}	
	
	
	
	// if there was an error in R...
	// -------------------------------------------------------------------------
	file write `knot' `"if (class(.Last.value) != "try-error" ) {"' _n					/// there was an error
	///"    print(.Last.value)" _n																	///
	"    rc = 0" _n																
	
	if missing("`vanilla'") file write `knot' "save.image()" _n  				// save if mode is not vanilla
	
	file write `knot' "} else {"	_n											///
	"    rc = 1" _n																///
	"    error = geterrmessage()" _n											///
	`"    error = gsub("Error in try({ :", "Error:", error, fixed = T)"' _n		///
	"}" _n(2)
	
	// if R does not fail, it continues...
	// -------------------------------------------------------------------------

	
	file write `knot' "source('`source'')" _n
	
	*file write `knot' `"plusR <- "`plusR'""' _n		//source stata.output() before exit
	file write `knot' `"stata.output("`plusR'", "`vanilla'")"' _n
	//file write `knot' "rm(stata.output)" _n	
	//file write `knot' `"try(rm(stata.output, RProfile), silent=TRUE)"' _n	
	
	*if missing("`vanilla'") file write `knot' "save.image()" _n 
	
	if !missing("`forceload'") {
		file write `knot' `"save.dta13(`loaddata', "'							///
		`"file = "_load.data.dta", version = 11) "' _n
	} 	
	
	qui file close `knot'
	
	
	
	if !missing("`debug'") {
		di _n "{title:[2/5] Temporary R script}" _n								///
		"{p}A temporary Rscript file was created to execute your command in "		///
		"{bf:R}. The path to the temporary file is: "  _n				
		display `"`Rscript'"'
		
		di _n "{title:Investigate R script}" _n									///
		"You can investigate the temporary R script file in debug mode." _n
		
		capture erase _temporary_R_script.R
		copy "`Rscript'" _temporary_R_script.R, replace 
		di "{browse _temporary_R_script.R}"
	}
		
	*cap erase 0PROCESS0.txt
	*copy "`Rscript'" 0PROCESS0.txt, replace
	
	
	// -------------------------------------------------------------------------
	// Execute the command in R
	// =========================================================================
	
	//By default, the input commands are printed along with the output. 
	//To suppress this behavior, add options(echo = FALSE) at the beginning of 
	//infile, or use option --slave. 
	
	
	
	
	if missing("`vanilla'") local save "--save"
	else local save "--no-save"
	
	local Rcommand `""`path'" `vanilla' --slave `save' < "`Rscript'" > "`Rout'" "'
	
	*local Rcommand `""`path'" `vanilla' --save  < "`Rscript'" > "`Rout'" "'
	
	if !missing("`debug'") {
		di _n "{title:[3/5] Running R in batch mode}" _n								///
		"The following command is executed in Stata:"  _n
		display `"{p}{err:shell `Rcommand'}"'
	}
	
	quietly shell `Rcommand'
	
	capture confirm file stata.output
	if _rc != 0 {
		shell `Rcommand'
		exit
	}
	
	if !missing("`debug'") {
		di _n "{title:[4/5] R Output}" _n								///
		"R output was generated. A copy is made in the debug mode..." _n
		
		capture erase _temporary_R_output.txt
		copy "`Rout'" _temporary_R_output.txt, replace 
		di "{browse _temporary_R_output.txt}"
	}
	
	// If data was loaded automatically, remove the temporary data file
	if !missing("`foreign'") capture qui erase _st.data.dta
	
	
	type "`Rout'"
	
	if !missing("`debug'") {
		di _n "{title:[5/5] rclass return}" _n								///
		"The final step is returning objects from R to Stata" _n
		
		di "{browse stata.output}"
	}
	
	
	
	// This has to be an engine for itself
	
	
	// -------------------------------------------------------------------------
	// Returning objects to Stata
	// =========================================================================
	// ???: AVOID returning in console mode
	call_return using "stata.output" , `debug'
	return add


	// If data was loaded automatically, remove the temporary data file
	if !missing("`forceload'") {
		capture confirm file _load.data.dta
		if _rc != 0 {
			di as err "{bf:R} failed to export Stata data set"
			exit
		}
		else {
			quietly use _load.data.dta, clear
			capture qui erase _load.data.dta
		}
	}
	
	// Erase globals
	macro drop Rpath
	macro drop Rcall_synchronize_mode
	
	
	// stop rcall execution if error has occured
	// -------------------------------------------------------------------------
	if "$RcallError" == "1" {
		macro drop RcallError
		if "$Rcall_interactive_mode" != "on" {
			error 1
		}
	}
	
	macro drop debug
	
end


// -------------------------------------------------------------------------
// CREATE help file
// =========================================================================

*markdoc rcall.ado, export(sthlp) replace


