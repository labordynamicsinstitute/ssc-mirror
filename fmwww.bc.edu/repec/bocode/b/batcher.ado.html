*! Version 1.4.0 04jan2021
* Contact jesse.wursten@kuleuven.be for bug reports/inquiries.

* Changelog
** 04jan2021: Now a bit more robust to delayed log files creation
** 15dec2020: Max parallel option, timestamps
** 09dec2020: Now minimises new windows to save space and better delay management
** 22aug2019: Fixed sleepduration issue
** 19aug2019: Added middleman finder
** 25jan2019: Changed Y:/middleman to G:/middleman (will break usage on pc)
** 04oct2018: Made file more robust to whitespaces in dofilenames
** 25jul2018: Added "`'-stripping to avoid errors on evaluating last line of log file
** 23jul2018: Changed to dofile middleman structure
** 23jan2018: Better folder management (creation and wd reset) and cleaner output.
** 08dec2017: Added notification when particular iteration finishes


cap program drop batcher
cap program drop batcher_saveoption
program define batcher
	* Syntax parsing
	version 8.0
	syntax anything(name=dofileName), [Tempfolder(string)] [STataexe(string)] Iter(numlist) [notrack] [BEtweendelay(integer 10) TRackdelay(integer 60) UPdatedelay(integer 30)] [sts(string) sts_exceptsuccess] [SAVEoptions(string)] [nostop noquit] [test] [SLeepduration(integer 60)] [MAXparallel(string)] [notimestamp]
	
	** Name of sleep duration in syntax changed to trackdelay, keeping sleepduration as internal name for backwards compatibility
	if `trackdelay' != 60 & `sleepduration' == 60 local sleepduration = `trackdelay'
	
	** Verify parallel is integer
	if "`maxparallel'" != "" {
	    capture confirm integer number `maxparallel'
		if _rc != 0 {
		    di as error "`maxparallel' is not recognised as integer"
			error 198
		}
	}
	
	** Saving options (to profile.do)
	if `"`saveoptions'"' != "" {
		if `"`sts'"' != ""				& strpos("`saveoptions'", "sts") > 0				batcher_saveoption, name(sts) 					value(`"`sts'"')
		if `"`sts_exceptsuccess'"' != ""& strpos("`saveoptions'", "sts_exceptsuccess") > 0	batcher_saveoption, name(sts_exceptsuccess) 	value(`"`sts_exceptsuccess'"')
		if `"`tempfolder'"' != "" 		& strpos("`saveoptions'", "tempfolder") > 0			batcher_saveoption, name(tempfolder) 			value(`"`tempfolder'"')
		if `"`sleepduration'"' != "60"	& strpos("`saveoptions'", "sleepduration") > 0		batcher_saveoption, name(sleepduration) 		value(`"`sleepduration'"')
		if `"`betweendelay'"' != "10"	& strpos("`saveoptions'", "betweendelay") > 0		batcher_saveoption, name(betweendelay) 		value(`"`betweendelay'"')
		if `"`updatedelay'"' != "30"	& strpos("`saveoptions'", "updatedelay") > 0		batcher_saveoption, name(updatedelay) 		value(`"`updatedelay'"')
		if `"`maxparallel'"' != ""	& strpos("`saveoptions'", "maxparallel") > 0		batcher_saveoption, name(maxparallel) 		value(`"`maxparallel'"')
		if `"`timestamp'"' != ""	& strpos("`saveoptions'", "timestamp") > 0			batcher_saveoption, name(timestamp) 		value(`"`timestamp'"')
		if `"`stop'"' != ""			& strpos("`saveoptions'", "nostop") > 0				batcher_saveoption, name(stop) 				value(`"`stop'"')
		if `"`quit'"' != ""			& strpos("`saveoptions'", "noquit") > 0				batcher_saveoption, name(quit) 				value(`"`quit'"')
	}
	
	** Loading options
	*** sts
												local stsDefined ""					// 3. Default is empty
	if "${batcher_sts}" != "" 					local stsDefined `"${batcher_sts}"'	// 2. Saved sts url
	if `"`sts'"' != "" 							local stsDefined `"`sts'"'			// 1. Specified sts url
	if `"`sts'"' == "overwrite" 				local stsDefined ""					// 0. Empty if user wants to overwrite saved sts url
	*** sts_exceptsuccess
												local sts_exceptsuccessDefined ""								// 3. Default is empty
	if "${batcher_sts_exceptsuccess}" != "" 	local sts_exceptsuccessDefined `"${batcher_sts_exceptsuccess}"'	// 2. Saved sts_exceptsuccess
	if `"`sts_exceptsuccess'"' != "" 			local sts_exceptsuccessDefined `"`sts_exceptsuccess'"'			// 1. Specified sts_exceptsuccess
	if `"`sts_exceptsuccess'"' == "overwrite" 	local sts_exceptsuccessDefined ""								// 0. Empty if user wants to overwrite saved sts_exceptsuccess
	
	*** tempfolder
											local tempfolderDefined ""							// 3. Default is empty
	if "${batcher_tempfolder}" != "" 		local tempfolderDefined `"${batcher_tempfolder}"'	// 2. Saved tempfolder
	if `"`tempfolder'"' != "" 				local tempfolderDefined `"`tempfolder'"'			// 1. Specified tempfolder
	if `"`tempfolder'"' == "overwrite" 		local tempfolderDefined ""							// 0. Empty if user wants to overwrite saved tempfolder
	
	*** sleepduration
											local sleepdurationDefined "60"							// 3. Default is 60
	if "${batcher_sleepduration}" != "" 	local sleepdurationDefined `"${batcher_sleepduration}"'	// 2. Saved sleepduration url
	if `"`sleepduration'"' != "60" 			local sleepdurationDefined `"`sleepduration'"'			// 1. Specified sleepduration url
	if `"`sleepduration'"' == "overwrite" 	local sleepdurationDefined "60"							// 0. 60 if user wants to overwrite saved sleepduration with default
	
	*** betweendelay
											local betweendelayDefined "10"							// 3. Default is 10
	if "${batcher_betweendelay}" != "" 		local betweendelayDefined `"${batcher_betweendelay}"'	// 2. Saved betweendelay
	if `"`betweendelay'"' != "10" 			local betweendelayDefined `"`betweendelay'"'			// 1. Specified betweendelay
	if `"`betweendelay'"' == "overwrite" 	local betweendelayDefined "10"							// 0. 10 if user wants to overwrite saved betweendelay with default
	
	*** updatedelay
											local updatedelayDefined "30"							// 3. Default is 30
	if "${batcher_updatedelay}" != "" 		local updatedelayDefined `"${batcher_updatedelay}"'	// 2. Saved updatedelay
	if `"`updatedelay'"' != "30" 			local updatedelayDefined `"`updatedelay'"'			// 1. Specified updatedelay
	if `"`updatedelay'"' == "overwrite" 	local updatedelayDefined "30"							// 0. 30 if user wants to overwrite saved updatedelay with default
	
	*** maxparallel
											local maxparallelDefined ""							// 3. Default is ""
	if "${batcher_maxparallel}" != "" 		local maxparallelDefined `"${batcher_maxparallel}"'	// 2. Saved maxParallel
	if `"`maxparallel'"' != "" 				local maxparallelDefined `"`maxparallel'"'			// 1. Specified maxParallel
	if `"`maxparallel'"' == "overwrite" 	local maxparallelDefined ""							// 0. if user wants to overwrite saved maxParallel with default ("")
	
	*** notimestamp
										local timestampDefined ""						// 3. Default is to timestamp
	if "${batcher_timestamp}" != "" 	local timestampDefined `"${batcher_timestamp}"'	// 2. Saved timestamp url
	if `"`timestamp'"' != "" 			local timestampDefined `"`timestamp'"'			// 1. Specified timestamp url
	if `"`timestamp'"' == "overwrite" 	local timestampDefined ""						// 0. Empty if user wants to overwrite saved timestamp
	
	*** nostop
										local stopDefined "stop"					// 3. Default is to stop on errors
	if "${batcher_stop}" != "" 			local stopDefined `"${batcher_stop}"'	// 2. Saved stop url
	if `"`stop'"' != "" 				local stopDefined `"`stop'"'			// 1. Specified stop url
	if `"`stop'"' == "overwrite" 		local stopDefined ""						// 0. Empty if user wants to overwrite saved stop
	
	*** noquit
										local quitDefined "quit"					// 3. Default is to quit on errors
	if "${batcher_quit}" != "" 			local quitDefined `"${batcher_quit}"'	// 2. Saved quit url
	if `"`quit'"' != "" 				local quitDefined `"`quit'"'			// 1. Specified quit url
	if `"`quit'"' == "overwrite" 		local quitDefined ""						// 0. Empty if user wants to overwrite saved quit url
	
	** Parsing options
	if `"`tempfolderDefined'"' == "" {
		di as text "No tempfolder specified nor saved. Using current working directory: " as result c(pwd)
		local tempfolderDefined = c(pwd)
	}
	local dofileName : subinstr local dofileName `"""' "", all
	local sleepduration_ms = `sleepdurationDefined'*1000
	local betweendelay_ms = `betweendelayDefined'*1000
	local updatedelay_ms = `updatedelayDefined'*1000

	if "`stataexe'" == "" {
		if c(flavor) == "IC" local flavor "IC"
		if c(SE) == 1 local flavor "SE"
		if c(MP) == 1 local flavor "MP"
		
		if c(bit) == 64 local bit "64"
		else local bit "32"
	}
	local stataexe "`c(sysdir_stata)'Stata`flavor'-`bit'"
	local numberOfIterations = wordcount("`iter'")

	* Find middleman
	qui findfile batcher.ado
	local middlemanPath = r(fn)
	local middlemanPath = subinstr("`middlemanPath'", "batcher.ado", "batcher_middleman.do", .)
	if "`test'" == "test" local middlemanPath = "G:\Other\SSC programs\batcher\Versions\toEdit\batcher_middleman.do"
	
	* Test report
	if "`test'" == "test" {
		di as text "Using test ado"
	}
	
	* Identify iterations (limit-aware)
	** Is there a concurrency limit (e.g. due to number of processors)
	/* 2: # processors 	*/ 		if c(processors_mach) 		!= . 	local limit = c(processors_mach)
	/* 1: option set	*/ 		if "`maxparallelDefined'" 	!= "" 	local limit = `maxparallelDefined'
	/* 0: overwrite 	*/		if "`maxparallelDefined'" 	== "0" 	local limit = .
	
	** Does concurrency bind?
	numlist "`iter'"
	local iterationsAll = r(numlist)
	local iterationsAllCount : list sizeof iterationsAll
	
	*** If so, split into initial and remainder batch
	if `limit' != . & `iterationsAllCount' > `limit'{
		local iterationsCurrent = ""
		local iterationsRemainder = "`iterationsAll'"
		forvalues i = 1/`limit' {
		    local iterationToConsider : word `i' of `iterationsAll'
		    local iterationsCurrent   : list iterationsCurrent   | iterationToConsider
			local iterationsRemainder : list iterationsRemainder - iterationToConsider
		}
	}
	
	*** Else, it's all initial batch
	else {
		local iterationsCurrent = "`iterationsAll'"
		local iterationsRemainder = ""
	}
	
	
	* Start dofiles
	cap mkdir "`tempfolderDefined'"
	noisily di as result `"Starting `dofileName'"'
	foreach iteration of local iterationsCurrent {
		* Start new stata process to perform the dofile (note, repeated twice below)
		if "`timestamp'" == "" 	noisily di _col(3) as text "iteration `iteration' (`c(current_date)' `c(current_time)')"
		else 					noisily di _col(3) as text "iteration `iteration'"
		winexec "`stataexe'" do "`middlemanPath'" "0`dofileName'0" `iteration' "`tempfolderDefined'" "`stopDefined'" "`quitDefined'"
		
		sleep `betweendelay_ms'
	}


	* Assess whether finished
	if "`track'" != "notrack" {
		noisily di as result "Starting tracking in `sleepdurationDefined' seconds. Refreshing every `updatedelayDefined' seconds."
		sleep `sleepduration_ms'
		local true "false"
		noisily di as text _col(4) "Finished: " _continue
		local finishedCount = 0
		local somethingFailed = 0
		local failures ""
		while "`true'" != "true" {
			foreach iteration of local iterationsCurrent {
				tempname log
				** Try to open log
				capture confirm file `"`tempfolderDefined'/iteration`iteration'.log"'
				if _rc == 0 file open `log' using `"`tempfolderDefined'/iteration`iteration'.log"', read
				else {
				    local counter = 0
					while `counter' <= 4 {
					    capture confirm file `"`tempfolderDefined'/iteration`iteration'.log"'
						if _rc == 0 {
						    file open `log' using `"`tempfolderDefined'/iteration`iteration'.log"', read
							local counter = 999
						}
						else {
						    local counter = `counter' + 1
							sleep 10000
						}
					}
					if `counter' > 4 & `counter' != 999 {
					    di as error "Could not find logfile of iteration `iteration'"
						error 999
					}
				}
				
				file seek `log' eof
				local posToStart = `r(loc)' - 27
				file seek `log' `posToStart'
				file read `log' line
				file close `log'
				local line = subinstr(`"`macval(line)'"', char(34), "", .)
				local line = subinstr(`"`macval(line)'"', char(39), "", .)
				local line = subinstr(`"`macval(line)'"', char(96), "", .)
				
				* Success
				if `"`line'"' == "Execution report: Success" & "`finished_`iteration''" != "1" {
					* Update tracker to say iteration is done
					local finished_`iteration' = 1
					local finishedCount = `finishedCount' + 1
					local iterationsCurrent : list iterationsCurrent - iteration
					noisily di as result " `iteration' " _continue
					if "`stsDefined'" != "" & "`sts_exceptsuccessDefined'" == "" qui sendtoslack, url(`stsDefined') message("Iteration `iteration' finished.")
					
					* Optionally start new iteration
					if "`iterationsRemainder'" != "" {
					    ** Identify new iteration
						local newIteration : word 1 of `iterationsRemainder'
						
						** Update lists
						local iterationsRemainder : list iterationsRemainder - newIteration
						local iterationsCurrent   : list iterationsCurrent   | newIteration
						
						** Start it
					    if "`timestamp'" == "" 	noisily di _col(3) as text `" -starting `newIteration' (`c(current_date)' `c(current_time)')- "'  _continue
						else 					noisily di _col(3) as text `" -starting `newIteration'- "'  _continue
						winexec "`stataexe'" do "`middlemanPath'" "0`dofileName'0" `newIteration' "`tempfolderDefined'" "`stopDefined'" "`quitDefined'"
						sleep `betweendelay_ms'
						local startedNewIteration "yes"
					}
				}
				
				* Failure
				if `"`line'"' == "Execution report: Failure" & "`finished_`iteration''" != "1" {
					local finished_`iteration' = 1
					local finishedCount = `finishedCount' + 1
					local iterationsCurrent : list iterationsCurrent - iteration
					local somethingFailed = 1
					local failures = trim("`failures' `iteration'")
					noisily di as error " `iteration' " _continue
					if "`stsDefined'" != "" qui sendtoslack, url(`stsDefined') message("ERROR! Iteration `iteration' failed!")
					
					* Optionally start new iteration
					if "`iterationsRemainder'" != "" {
					    ** Identify new iteration
						local newIteration : word 1 of `iterationsRemainder'
						
						** Update lists
						local iterationsRemainder : list iterationsRemainder - newIteration
						local iterationsCurrent   : list iterationsCurrent   | newIteration
						
						** Start it
					    if "`timestamp'" == "" 	noisily di _col(3) as text `" -starting `newIteration' (`c(current_date)' `c(current_time)')- "'  _continue
						else 					noisily di _col(3) as text `" -starting `newIteration'- "'  _continue
						winexec "`stataexe'" do "`middlemanPath'" "0`dofileName'0" `newIteration' "`tempfolderDefined'" "`stopDefined'" "`quitDefined'"
						sleep `betweendelay_ms'
						local startedNewIteration "yes"
					}
				}
				
				if "`startedNewIteration'" == "yes" {
				    local startedNewIteration "no"
					sleep `sleepduration_ms'
				}
			}
			if "`finishedCount'" == "`numberOfIterations'" local true "true"
			
			if "`true'" != "true" {
				noisily di as txt "x" _continue
				sleep `updatedelay_ms'
			}
		}
		if "`somethingFailed'" == "0" {
			noisily di as result " OK"
			noisily di _newline as result "Batch job has finished."
			if "`stsDefined'" != "" sendtoslack, url(`stsDefined') message("Batch job has finished.") col(4)
		}
		if "`somethingFailed'" == "1" {
			noisily di as error " Something failed!"
			noisily di _newline as result "Batch job has finished, but with " as error "failures" as result "!"
			noisily di as result "Failed iterations: " as error "`failures'"
			if "`stsDefined'" != "" sendtoslack, url(`stsDefined') message("Batch job has finished with failures: iterations `failures'.") col(4)
		}
	}
end

program define batcher_saveoption
	syntax, name(string) value(string)

	* Determine whether profile.do exists
	cap findfile profile.do

	** If profile.do does not exist yet
	** Create profile.do (asking permission)
	if _rc == 601 {
		di "Profile.do does not exist yet."
		di "Do you want to allow this program to create one for you? y: yes, n: no" _newline "(enter below)" _request(_createPermission)
		
		if "`createPermission'" == "y" {
			di "Creating profile.do as `c(sysdir_oldplace)'profile.do"
			tempname createdProfileDo
			
			file open `createdProfileDo' using `"`c(sysdir_oldplace)'profile.do"', write
			file close `createdProfileDo'
		}
		
		if "`createPermission'" != "y" {
			di "User did not give permission to create profile.do, aborting program."
			exit
		}
	}

	* Write in global for url
	** Verify if global is already defined (if so, give warning)
	*** Find location of profile.do
	qui findfile profile.do
	local profileDofilePath "`r(fn)'"

	*** Open
	tempname profileDofile
	file open `profileDofile' using "`profileDofilePath'", read text
	file read `profileDofile' line

	*** Loop over profile.do until ...
	***		you reached the end
	***		found the global we want to define
	local keepGoing = 1
	while `keepGoing' == 1 {
		if strpos(`"`macval(line)'"', "sts_`name'") > 0 {
			di as error  "Global was already defined in profile.do"
			di as result "The program will add the new definition at the bottom."
			di "You might want to open profile.do and remove the old entry."
			di "This is not required, but prevents clogging your profile.do."
			di "To do so, type: " as txt "doed `profileDofilePath'" _newline
			
			local keepGoing = 0
		}
		
		file read `profileDofile' line
		if r(eof) == 1 local keepGoing = 0
	}
	file close `profileDofile'

	** Write in the global
	file open `profileDofile' using "`profileDofilePath'", write text append
	file write `profileDofile' _newline `"global batcher_`name' `"`value'"'"'
	file close `profileDofile'
	
	** Define it now too, as profile.do changes only take place once it has ran
	global batcher_`name' `"`value'"'

	* Report back to user
	di as text "Added a default " as result "`name'" as text " to " as result "`profileDofilePath'"
	di as text "On this PC, " as result `"`name'(`value')"' as text " will now be used even if no " as result "`name'" as text " option was specified for the batcher command."
	di as text "In other words, you can now type " as result "batcher" as text " and it will execute " as result `"batcher, `name'(`value')"' as text " (+ any other saved options)." _newline
end
