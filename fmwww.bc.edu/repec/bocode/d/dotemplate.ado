*! version 2.0		<22Dec2015>			Andres Castaneda
*! version 1.0		<18Dec2013>			Andres Castaneda
/*===========================================================================
Program Name: dotemplate.ado
Author:		  Andres Castaneda
project:	  Create templates for do-files and ado-files
Dependencies: The World Bank - LCSPP
---------------------------------------------------------------------------
Creation Date: 		December 18, 2013
Modification Date:	January 07, 2013
					December 22, 2015
version:			01
References:	
Output:		dotemplate.ado
===========================================================================*/

cap program drop dotemplate
program define dotemplate

syntax , [ File(string) 						/// Name of the do-file
           Path(string) 						/// directory path where do-file will be placed
           TYpe(string) 						/// Type of template to create. Default 
           AUThor(string) 						/// Author name
           DEPend(string) 						/// institutions/s working for in the project
           PROject(string) 						/// Objective of the do-file
           OUTput(string) 						/// list of files produced with the do-file
           DIRectory(string) 					/// list of files produced with the do-file
           SECtions(string)						/// Number of sections in do-file
           STEPs(string)						/// number of steps with sections
           log  								/// produced log file with the same name as the do-file
           replace								/// replace
           ]
  
version 10
*================================
* Section 1: create locals
*===============================

* 1.1: Default locals


* type of template
if ("`type'" == "") {
	disp in y  "Type of template: " _n in smcl ///
		"({ul:B}asic or {ul:C}omplete)" _request(_type)
	if ("`type'" == "" | regexm("`type'", "^[Cc]")) local type "complete"
	if (regexm("`type'", "^[Bb]")) local type "basic"
}

* Project
if ("`project'" == "") disp in y  "Objective of the project:" _request(_project)

* name
if ("`file'" == "") {
	disp in y  "Name of do-file:" _request(_file)
	if ("`file'" == "") local file "dofile1"
}

* Author
if ("`author'" == "") {
	disp in y  "Author Name:" _request(_author)
	if ("`author'" == "") local author = "`c(username)'"
}

* Dependencies
if ("`depend'" == "" & "`type'" == "complete" ) {
	disp in y  "Institution/s working in the project:" _request(_depend)
}



* sections
if ("`sections'" == "" & "`type'" == "complete" ) {
	disp in y  "Estimated number of sections:" _request(_sections)
	if ("`sections'" == "") local sections = 3
}

* steps
if ("`steps'" == "" & "`type'" == "complete" ) {
	disp in y  "Estimated number of sub-sections:" _request(_steps)
	if ("`steps'" == "") local steps = 1
}

* Output
if ("`output'" == "" & "`type'" == "complete") disp in y  ///
	"Expected output from the do-file:" _n ///
	"(Ex: Excel file, database, etc.)" _request(_output)


* Path
if ("`path'" == "") {
	disp in y  "Directory path to place do-file" _n   ///
		"(current directory is default):" _request(_path)
	if (`"`path'"' == `""') local path = "`c(pwd)'"
}

* Directories
if ("`directory'" == "" & "`type'" == "complete") disp in y  ///
	"Global macros for directories paths:" _request(_directory)


* log
if ("`log'" == "") {
	disp in y  "Do you want to create a log-file in your template? Y/N" ///
		_request(_log)
}



* 1.2: Temporal files and names

tempfile dofile
tempname do
file open `do' using `dofile', write `replace'


*================================
* Section 2: Create do-file
*===============================

* 2.1 Header

if (inlist("`log'", "log", "Y")) {						// if log file is desired
	file write `do' `"capture log close"' _n  //
	file write `do' `"log using "`path'/`file'.txt", replace text"' _n  
}

file write `do' `"/*"' _dup(68) `"="' _n 
file write `do' `"project:"'  _col(16) `"`project'"' _n 			
file write `do' `"Author: "'  _col(16) `"`author' "' _n  		
*file write `do' `"Program Name: `file'.do"' _n 

* dependencies is not a "must"
if ("`type'" != "basic") file write `do' `"Dependencies:"' _col(16) `"`depend'"' _n  

file write `do' _dup(70) `"-"' _n  
file write `do' `"Creation Date:"' _col(18) ///
	`" `c(current_date)' - `c(current_time)'"' _n  
* `"`: di %tdMonth_dd,_CCYY date("$S_DATE", "DMY")' "' _n  

if ("`type'" != "basic") {					// No basic template
	file write `do' `"Modification Date:"' _col(21) `" "' _n  			
	file write `do' `"Do-file version:"' _col(21) `"01"' _n  			
	file write `do' `"References:"' _col(21) `" "' _n  		
	file write `do' `"Output:"' _col(21) `"`output'"' _n 	
}
file write `do' _dup(68) `"="' `"*/"' _n 


* 2.2 Page set up
file write `do' `""' _n  
file write `do' `"/*"' _dup(68) "=" _n  
file write `do' _col(25) `"0: Program set up"' _n  		
file write `do' _dup(68) "=" `"*/"' _n 	

* Directories of dta, do-files and excel files
if ("`type'" != "basic") {
	file write `do' `"version `c(stata_version)'"' _n  	
	file write `do' `"drop _all"' _n  				
}

* Create globals for each directory that will be used in the project
if ("`directory'" != "") {
	file write `do' `""' _n  					
	file write `do' `"* Directory Paths"' _n  	
	foreach dir of local directory {
		file write `do' `"global `dir'"' _col(20) `""""' _n 	
	}
}

file write `do' `""' _n   
file write `do' `""' _n


*2.3 Sections
if ( "`type'" == "complete" ) {
	foreach section of numlist 1/`sections' {
		file write `do' `"/*"' _dup(68) "=" _n 	
		file write `do' _col(25) `"`section': "' _n  		
		file write `do' _dup(68) "=" `"*/"' _n 	
		file write `do' `""' _n    
		file write `do' `""' _n 
		
		if (`steps' > 1) {
			foreach step of numlist 1/`steps' {
				file write `do' `"*"' _dup(20) "-" `"`section'.`step':"'  _n  
				file write `do' `""' _n
				file write `do' `""' _n 
			}
		}		// end of step loop
	}			//  end of Sections loop
}	//  end of type condition

* Few spaces before closing
file write `do' `""' _n  
file write `do' `""' _n  
file write `do' `""' _n  

* In case log file is selected
if (inlist("`log'", "log", "Y")) file write `do' `"log close"' _n  


* 2.4 Closing lines
file write `do' `"exit"' _n  
file write `do' `"/* End of do-file */"' _n
file write `do' `""' _n  
file write `do' ">" _dup(39) "<>" "<" _n  

if ("`type'" != "basic") {
	file write `do' `""' _n  
	file write `do' `"Notes:"' _n  
	file write `do' `"1."' _n  
	file write `do' `"2."' _n  
	file write `do' `"3."' _n  
	file write `do' `""' _n  
	file write `do' `""' _n  
	file write `do' `"Version Control:"' _n  
	file write `do' `""' _n  
	file write `do' `""' _n  
}

*================================
* Section 3: Closing file
*===============================

file close `do'
cap confirm new file "`path'/`file'.do"
if _rc {
	cap window stopbox rusure `"The file "`path'/`file'.do" "' ///
		"already exists." "Do you want to replace it?"
	if (_rc == 0) copy `dofile' "`path'/`file'.do", replace
	else exit
	di as txt "Click" as smcl `"{browse `""`path'/`file'.do""': here }"' ///
		`"to open template "`file'.do" with your default software"'
}

else {
	copy `dofile' "`path'/`file'.do"
	di as txt "Click" as smcl `"{browse `""`path'/`file'.do""': here }"' ///
		`"to open template "`file'.do" with your default software"'
}

end

exit 
----------------------------------------------------------------------------------------------------

Notes:
1.
2.
3.
.....

Version Control:



dotemplate, project("Program to create Templates for do-file") ///
         file(detemplate)              ///
         author(Andres Castaneda)      ///
         type(complete)                ///
         depend(The World Bank-LCSPP)  ///
         output(dotemplate.ado)        ///
         sections(2)                   ///
         steps(2)                      ///
         log


    dotemplate, project("Program to create Templates for do-file") ///
         file(detemplate)              ///
         author(Andres Castaneda)      ///
         type(basic)                   ///
         sections(1)   



