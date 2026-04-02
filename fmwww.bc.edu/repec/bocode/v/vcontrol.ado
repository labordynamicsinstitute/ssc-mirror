*! vcontrol v1.0 (01 Apr 2026)
*! Asjad Naqvi (asjadnaqvi@gmail.com)

* v1.0 (01 Apr 2026): Beta release. return lists added. if SSC does not exist then install from Github. Better checks for missing packages.      

program define vcontrol, rclass
	version 11
	syntax anything [, url(string) update replace]
	

	if "`anything'" == "" {
		di as error "A package name is required."
		exit 198
	}

		
	local package `anything'
	local firstletter = substr("`package'", 1, 1)
	local sscurl "http://fmwww.bc.edu/repec/bocode/`firstletter'/`package'.pkg"
	
	if "`url'" == "" {
		local giturl "https://raw.githubusercontent.com/asjadnaqvi/stata-`package'/refs/heads/main/installation"
	}
	else {
		local giturl "`url'"
	}
	
	preserve
		
		// SSC
		quietly {
			cap import delimited using "`sscurl'", clear case(lower) delim("***")
			if _rc {
				local sscdate = 0
				*noi display in yellow "Package does not exist on SSC."
			}
			else {
				keep if regexm(v1, "d Distribution-Date:")
				replace v1 = ustrregexra(v1, "d Distribution-Date: ", "")
				destring v1, replace
				local sscdate = v1[1]
			}
		}
		
		return local ssc	`sscdate'
		
		// GitHub
		quietly {
			cap import delim "`giturl'/`package'.pkg", clear case(lower) delim("***")
			if _rc {
				local githubdate = 0
				*noi display in yellow "Package does not exist on GitHub."
			}
			else {
				keep if regexm(v1, "d Distribution-Date:")
				replace v1 = ustrregexra(v1, "d Distribution-Date: ", "")
				destring v1, replace
				local githubdate = v1[1]
			}
		}
		
		return local github `githubdate'
		
		
		// local date
		quietly {		
			
			import delim using "`c(sysdir_plus)'stata.trk", clear delim("***") case(lower)
			
			drop v2 // just contains junk

			gen _tracker = .

			local firstletter = substr("`package'", 1, 1)
			replace _tracker = 0 if v1=="e"
			replace _tracker = 1 if regexm(v1, "^N `package'.pkg$")==1
			
			summ _tracker, meanonly
			
			if `r(max)' == 0 {
				local localdate = 0
				*display in yellow "Package does not exist locally."			
			}
			else {
			
				carryforward _tracker, replace
				keep if _tracker==1

				keep if regexm(v1, "d Distribution-Date:")
				replace v1 = ustrregexra(v1, "d Distribution-Date: ", "")
				destring v1, replace

				summ v1, meanonly
				local localdate = `r(max)'
			}
			
		}
		
		return local local  `localdate'
		
	restore
	
	
	
	if `localdate'==0 & `githubdate'==0 & `sscdate'==0 {
		no display in yellow "No package named {ul:`package'} installed locally, or found on SSC or GitHub. Check syntax."
		exit
	}
	
	
	if "`update'" == "" { 
		if `localdate' == max(`sscdate', `githubdate') {
			di in yellow "Latest version of {ul:`package'} (`localdate') already installed."
		}
		else {
			if `githubdate' > `sscdate'  {
				di in yellow "SSC   : `sscdate' `ssctxt'"
				di in yellow "GitHub: `githubdate' (latest) `gittxt'" 
			}
			else if `sscdate' > `githubdate' {
				di in yellow "SSC   : `sscdate' (latest) `ssctxt'" 
				di in yellow "GitHub: `githubdate' `gittxt'" 
			}
		
			di as smcl "Click here to {stata vcontrol `package', update replace:install} the latest version."
		}
	}
	else {
	
	*if "`update'" != "" &`localdate' == max(`sscdate', `githubdate') {
		if `githubdate' > `sscdate' {
			di as result "Updating from GitHub:"
			net install `package', from("`giturl'") `replace'
		}
		else {
			di as result "Updating from SSC:"	
			ssc install `package', `replace'
		}
	}
	
	
	
	
	
	
end
