*! xtstfetchcovid19 version 1.0.1
*! Downloads Data from COVID-19 Data Hub 
*! Diallo Ibrahima Amadou
*! All comments are welcome, 23Jun2023



capture program drop xtstfetchcovid19
program xtstfetchcovid19, rclass
	version 17.0
	syntax , pathz(string asis) [ granulev(integer 1) SAVing(string asis) ]
	quietly cd `pathz'
    if `granulev'==1 {
		display
		display _dup(78) "="
		display "Downloading Worldwide Country-Level Data"
		display "(level 1) from COVID-19 Data Hub."
		display "This may take some time. Please wait!"
		display _dup(78) "="
		display		
        quietly unzipfile "https://storage.covid19datahub.io/level/1.csv.zip", replace
		quietly import delimited "1.csv", clear
		if `"`saving'"' != "" {
			quietly save `saving'
		}
		quietly erase "1.csv"
    }
    else if `granulev'==2 {
		display
		display _dup(78) "="
		display "Downloading Worldwide State-Level Data"
		display "(level 2) from COVID-19 Data Hub."
		display "This may take some time. Please wait!"
		display _dup(78) "="
		display		
        quietly unzipfile "https://storage.covid19datahub.io/level/2.csv.zip", replace
		quietly import delimited "2.csv", clear
		if `"`saving'"' != "" {
			quietly save `saving'
		}
		quietly erase "2.csv"
    }
    else if `granulev'==3 {
		display
		display _dup(78) "="
		display "Downloading Worldwide City-Level Data"
		display "(level 3) from COVID-19 Data Hub."
		display "This may take some time. Please wait!"
		display _dup(78) "="
		display		
        quietly unzipfile "https://storage.covid19datahub.io/level/3.csv.zip", replace
		quietly import delimited "3.csv", clear
		if `"`saving'"' != "" {
			quietly save `saving'
		}
		quietly erase "3.csv"
    }
    else {
        display as err "Wrong level. The values must be: 1, 2 or 3. Thanks."
		exit 198
	}
	
end


 