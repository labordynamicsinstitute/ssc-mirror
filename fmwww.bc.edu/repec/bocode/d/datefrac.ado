/*

datefrac 1.0.1 -- 11 October 2023
Tommy Morgan - labhours@tmorg.org
a Stata command that takes any variable that represents an exact date and generates a numeric variable representing the fraction of that year that has passed at the beginning of that date by taking the number of days since 1 January of a given year, dividing that number by 365, and adding the resulting fraction to the given year. For example, datefrac assigns the value 2020.000 (2020 + 0/365) to the date 1 January 2020 and the value 1999.17260 (1999 + 63/365) to the date 4 March 1999. It also accounts for leap years if the year is a multiple of 4, assigning the value 2000.17486 (2000 + 64/366) to the date 4 March 2000.

*/

program define datefrac
	version 10
	
	syntax varname, GENerate(string) [ORDER(string)]
	
		
	*make sure they're using generate
	if "`generate'" == "" {
		di as err "must specify option generate()"
		exit 198
	}
	
	*make sure their newvar is valid
	if "`generate'" != "" {
		capture confirm new variable `generate'
		if _rc { 
			di as err "generate() contains existing variable(s) and/or illegal variable name(s)" 
			exit _rc 
		}
	}
	
	*check if the variable is a string to do date stuff:
	capture confirm string variable `varlist'
	if _rc == 0 {
			rename `varlist' superyeehaw`varlist'
			gen `varlist' = date(superyeehaw`varlist',"`order'")
	}
	
	
	*do the actual command!
	quietly {
		
		*get the year, month, and day from the existing date variable
		gen supermegayeehawyear = year(`varlist')
		gen supermegayeehawmonth = month(`varlist')
		gen supermegayeehawday = day(`varlist')
		
		*build the lookup matrix
		mat supermegadatefracker=J(366,4,.)
		loc dy 31 29 31 30 31 30 31 31 30 31 30 31
		loc i 0
		loc m 0
		foreach d of loc dy {
			loc m=`m'+1
			forv j=1/`d' {
				loc i=`i'+1
				mat supermegadatefracker[`i',3] = `m'
				mat supermegadatefracker[`i',4] = `j'
			}
		}
		mat supermegadatefracker[`i',1]=0
		mat supermegadatefracker[`i',2]=0
		forv i=2/366 {
			mat supermegadatefracker[`i',2] = `=`i'-1'/366
		}
		forv i=2/59 {
			mat supermegadatefracker[`i',1] = `=`i'-1'/365
		}
		forv i=61/366 {
			mat supermegadatefracker [`i',1] = `=`i'-2'/365
		}
		mat supermegadatefracker[1,1]=0
		mat supermegadatefracker[1,2]=0

		*bring in the fractional values from the lookup table
		gen double supermegayeehawfraction = .
		gen double supermegayeehawleapyearfraction = .
		forval i = 1/366 {
			quietly replace supermegayeehawfraction = supermegadatefracker[`i', 1] if supermegayeehawmonth == supermegadatefracker[`i', 3] & supermegayeehawday == supermegadatefracker[`i', 4]
		}
		forval i = 1/366 {
			quietly replace supermegayeehawleapyearfraction = supermegadatefracker[`i', 2] if supermegayeehawmonth == supermegadatefracker[`i', 3] & supermegayeehawday == supermegadatefracker[`i', 4]
		}
		
		
		*build the actual variable
		gen double `generate' = supermegayeehawyear + supermegayeehawfraction
		replace `generate' = supermegayeehawyear + supermegayeehawleapyearfraction if mod(supermegayeehawyear,4)==0
		format `generate' %12.7f
		
		capture confirm string variable superyeehaw`varlist'
		if _rc == 0 {
			drop `varlist'
			rename superyeehaw`varlist' `varlist'
		}
		
		drop supermegayeehaw*
		mat drop supermegadatefracker
		
	} // end of quietly
	
	*check if the new variable is all missing values and warn if so:
	cap assert `generate'==.
	if _rc==0 {
		cap drop `generate'
		di as error "`generate' would contain all missing values, so it was not generated." 
		di in smcl "{bf:order()} of `varlist' may not be specified correctly;"
		di in smcl "see {it:s2} section of {help f_date} for help, treating `varlist' as {it:s1}."
		exit 198
	}
	
end