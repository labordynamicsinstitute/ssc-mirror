/*

					   Developed by E. F. Haghish (2014)
			  Center for Medical Biometry and Medical Informatics
						University of Freiburg, Germany
						
						  haghish@imbi.uni-freiburg.de
								        
                       * MarkDoc comes with no warranty *

	
	
	MarkDoc Package
	===============
	
	This ado file is a part of MarkDoc package and is called within markdoccheck.ado
	file to check if wkhtmltopdf printer is installed on the system correctly and is 
	accessible for MarkDoc package
	
	
	Engine
	------
	
	wkhtmltopdf is an open source freeware for Windows, Mac, and Unix operating 
	systems and converts HTML to PDF documents. The Automatic Version of 
	wkhtmltopdf software will be downloaded from http://www.haghish.com/. 
	
	
	MarkDoc Versions
	----------------
	
	3.0.0  August, 2015
	3.3.0  September, 2015
*/
	
	
	
program define markdocwkhtmltopdf
	version 11
	
	********************************************************************
	*MICROSOFT WINDOWS 32BIT & 64BIT
	********************************************************************
	if "`c(os)'" == "Windows" {
			
		*save the current working directory
		qui local location "`c(pwd)'"
		qui cd "`c(sysdir_plus)'"
		cap qui mkdir Weaver
		qui cd Weaver
		local d : pwd
		
		di as txt "{hline}" _n
		di as txt 																///
		" ____  _                      __        __    _ _   " _n 				///
		"|  _ \| | ___  __ _ ___  ___  \ \      / /_ _(_) |_ " _n 				///
		"| |_) | |/ _ \/ _` / __|/ _ \  \ \ /\ / / _` | | __|" _n 				///
		"|  __/| |  __/ (_| \__ \  __/   \ V  V / (_| | | |_ " _n 				///
		"|_|   |_|\___|\__,_|___/\___|    \_/\_/ \__,_|_|\__|" _n 
		
		di as txt "{p}{ul: {bf:Installing wkhtmltopdf Software}}" _n
			
		di as txt "{p}Required software packages are getting installed " 		///
		"in {browse `d'} directory. make sure you are " 						///
		"connected to internet. This may take a while. Pay attention to " 		///
		"the download bar of Stata below and when the download is done, " 		///
		"rerun MarkDoc command."_n
			
		di as txt "{hline}" _n(4)
	
			
		*DOWNLOAD WKHTMLTOPDF AND UNZIP IT
		cap qui copy "http://www.haghish.com/software/wkhtmltopdf_0.12.1.txt" 	///
		"wkhtmltopdf_0.12.1.txt", replace
			
		if "`c(bit)'" == "32" {
			cap qui copy "http://www.haghish.com/software/Win/32bit/wkhtmltopdf.zip" ///
			"wkhtmltopdf.zip", replace
		}
			
		if "`c(bit)'" == "64" {
			cap qui copy "http://www.haghish.com/software/Win/64bit/wkhtmltopdf.zip" ///
			"wkhtmltopdf.zip", replace
		}
			
		cap qui unzipfile wkhtmltopdf, replace
		cap qui erase wkhtmltopdf.zip
			
		*GETTING THE PATH TO WKHTMLTOPDF
		cap qui cd wkhtmltopdf
		cap qui cd bin
		local d : pwd
		global setpath : di "`d'\wkhtmltopdf.exe"
		
		//Go back to the Working Directory
		qui cd "`location'"	
		
	}

		
		
	********************************************************************
	*MAC 32BIT & 64BIT
	********************************************************************
	if "`c(os)'" == "MacOSX" {
			
		*save the current working directory
		qui local location "`c(pwd)'"
		qui cd "`c(sysdir_plus)'"
		cap qui mkdir Weaver
		qui cd Weaver
		local d : pwd
			
		di as txt "{hline}" _n
		di as txt 																///
		" ____  _                      __        __    _ _   " _n 				///
		"|  _ \| | ___  __ _ ___  ___  \ \      / /_ _(_) |_ " _n 				///
		"| |_) | |/ _ \/ _` / __|/ _ \  \ \ /\ / / _` | | __|" _n 				///
		"|  __/| |  __/ (_| \__ \  __/   \ V  V / (_| | | |_ " _n 				///
		"|_|   |_|\___|\__,_|___/\___|    \_/\_/ \__,_|_|\__|" _n 
		
		di as txt "{p}{ul: {bf:Installing wkhtmltopdf Software}}" _n
			
		di as txt "{p}Required software packages are getting installed " 		///
		"in {browse `d'} directory. make sure you are " 						///
		"connected to internet. This may take a while. Pay attention to " 		///
		"the download bar of Stata below and when the download is done, " 		///
		"rerun MarkDoc command."_n
			
		di as txt "{hline}" _n(4)
			
			
		*DOWNLOAD WKHTMLTOPDF AND UNZIP IT
		cap qui copy "http://www.haghish.com/software/wkhtmltopdf_0.12.1.txt" 	///
		"wkhtmltopdf_0.12.1.txt", replace
			
		cap qui copy "http://www.haghish.com/software/Mac/wkhtmltopdf.zip" 		///
		"wkhtmltopdf.zip", replace
			
		cap qui unzipfile wkhtmltopdf, replace
		cap qui erase wkhtmltopdf.zip
			
		*GETTING THE PATH TO WKHTMLTOPDF
		cap qui cd wkhtmltopdf
		local d : pwd
		global setpath : di "`d'/wkhtmltopdf"
		cap qui shell chmod +x "$setpath"
			
		//Go back to the Working Directory
		qui cd "`location'"	
	}
		
		
	********************************************************************
	*UNIX 32BIT & 64BIT
	********************************************************************
	if "`c(os)'" == "Unix" {
			
		*save the current working directory
		qui local location "`c(pwd)'"
		qui cd "`c(sysdir_plus)'"
		cap qui mkdir Weaver
		qui cd Weaver
		local d : pwd
			
		di as txt "{hline}" _n
		di as txt 																///
		" ____  _                      __        __    _ _   " _n 				///
		"|  _ \| | ___  __ _ ___  ___  \ \      / /_ _(_) |_ " _n 				///
		"| |_) | |/ _ \/ _` / __|/ _ \  \ \ /\ / / _` | | __|" _n 				///
		"|  __/| |  __/ (_| \__ \  __/   \ V  V / (_| | | |_ " _n 				///
		"|_|   |_|\___|\__,_|___/\___|    \_/\_/ \__,_|_|\__|" _n 
		
		di as txt "{p}{ul: {bf:Installing wkhtmltopdf Software}}" _n
			
		di as txt "{p}Required software packages are getting installed " 		///
		"in {browse `d'} directory. make sure you are " 						///
		"connected to internet. This may take a while. Pay attention to " 		///
		"the download bar of Stata below and when the download is done, " 		///
		"rerun MarkDoc command."_n
			
		di as txt "{hline}" _n(4)
			
			
		*DOWNLOAD WKHTMLTOPDF AND UNZIP IT
		cap qui copy "http://www.haghish.com/software/wkhtmltopdf_0.12.1.txt" 	///
		"wkhtmltopdf_0.12.1.txt", replace
			
		if "`c(bit)'" == "32" {
			cap qui copy "http://www.haghish.com/software/Unix/32bit/wkhtmltopdf.zip" ///
			"wkhtmltopdf.zip", replace
		}
			
		if "`c(bit)'" == "64" {
			cap qui copy "http://www.haghish.com/software/Unix/64bit/wkhtmltopdf.zip" ///
			"wkhtmltopdf.zip", replace
		}
			
		cap qui unzipfile wkhtmltopdf, replace
		cap qui erase wkhtmltopdf.zip
			
			
		*GETTING THE PATH TO WKHTMLTOPDF
		cap qui cd wkhtmltopdf
		local d : pwd
		global setpath : di "`d'/wkhtmltopdf"
		
		cap qui shell chmod +x "$setpath"
			
		//Go back to the Working Directory
		qui cd "`location'"	
		
	}

	
end
	
	
	
	
