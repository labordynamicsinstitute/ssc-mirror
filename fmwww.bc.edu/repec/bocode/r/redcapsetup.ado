*! version 1.0  2026-04-21
*! Author: m.chatfield@uq.edu.au

*change isid bits?


program define redcapsetup
version 17.0  // otherwise get CSV UTF-8 BOM leakage problems
syntax [, smart]  // smart option not described in help file

global smartvariable "`smart'"
tempfile idlongdta formeventsdta idmixdta  alertsdta asidta fdldta  completevarsdta DataDictionarydta

preserve

qui {

***Instrument-Event Designations
local idcsv : dir . files "*InstrumentDesignations*.csv", respectcase
global wcidcsv : word count `idcsv'
if $wcidcsv == 0 {
	noi di as err "redcapsetup requires a *InstrumentDesignations*.csv file in the working directory."
	exit
}
if $wcidcsv > 1 {
	noi di as err `"redcapsetup requires just one *InstrumentDesignations*.csv file in the working directory. You have: `idcsv'"'
	exit
}

	noi di as txt `"Using `idcsv'"' 
	import delimited `idcsv', clear
	drop arm_num
	save "`idlongdta'", replace  // has 2 vars:  unique_event_name form


	**this is one way of going wide
	tempname here
	postfile `here' str80 formname  str800 formevents using "`formeventsdta'", replace 
	levelsof form, clean local(forms)
	foreach form of local forms {
		qui levelsof unique_event_name if form=="`form'", clean local(events)
		post `here' ("`form'") ("`events'")
	}
	levelsof unique_event_name, clean local(events)
	post `here' ("_all") ("`events'")
	postclose `here'
	
	
	keep form
	rename form formname
	duplicates drop
	gen variablefieldname = formname + "_complete"
	save "`completevarsdta'", replace
		

	use "`formeventsdta'", clear
	split formevents, gen(fevent)
	save "`formeventsdta'", replace

    rename formname form
	gen unique_event_name = ""
	append using "`idlongdta'"
	save "`idmixdta'", replace
	



***Alerts
*it is completely normal and expected for unique-form-name to be unspecified or blank in an Alerts CSV.
*Alerts are project-level constructs
*instrument linkage is implicit via fieldnames, not via a unique-form-name column. Hmm. I may not have processed this well enough.
local alertscsv : dir . files "*Alerts_*.csv", respectcase
global wcalertscsv : word count `alertscsv'
if $wcalertscsv > 1 {
	noi di as err `"redcapsetup requires no more than one *Alerts_*.csv file in the working directory. You have: `alertscsv'"' 
	exit
}
if $wcalertscsv == 1 {
	noi di as txt `"Using `alertscsv'"' 
	import delimited `alertscsv', clear bindquote(strict)
	*tab1 *
	ds alertcondition - alertdeactivated, has(type string)
	egen combinedvars = concat(`r(varlist)')
	
	rename uniqueformname form
	rename uniqueeventname unique_event_name
	ds unique_event_name, has(type string)
	if "`r(varlist)'" == "" {
		drop unique_event_name
		gen unique_event_name = ""
	}
	
	gen row = _n
	gen variableorform = "#" + string(row) + " " + form + " (" + unique_event_name + ")"
	replace row = row + 1
	drop if alertdeactivated=="Y"   // ignore deactivated alerts
	
	merge m:1 form unique_event_name using "`idmixdta'"
	count if _merge==1 & form!=""
	if `=r(N)' >0  {
		noi di " "
		noi di as err "Below: (unique-form-name, unique-event-name) in Alerts is invalid"
		noi list form unique_event_name if _merge==1, noobs ab(30)
	} 	
	drop if _merge==2
	replace unique_event_name = formevents if unique_event_name == ""
	drop formevents
	rename unique_event_name formevents	
	
	keep variableorform combinedvars row form formevents
	gen source = "ALERT"	
	save "`alertsdta'", replace
}



***ASI - Automated Survey Invitations
local asicsv : dir . files "asi_*.csv", respectcase
global wcasicsv : word count `asicsv'
if $wcasicsv > 1 {
	noi di as err `"redcapsetup requires no more than one asi_*.csv file in the working directory. You have: `asicsv'"'
	exit
}
if $wcasicsv == 1 {
	noi di as txt `"Using `asicsv'"' 
	import delimited `asicsv', clear bindquote(strict)
	
	*tab1 *
	ds , has(type string) 
	*condition_logic email_content condition_send_time_lag_field
	egen combinedvars = concat(`r(varlist)')
	gen row = _n + 1

	rename form_name form
	rename event_name unique_event_name
	ds unique_event_name, has(type string)
	if "`r(varlist)'" == "" {
		drop unique_event_name
		gen unique_event_name = ""
	}

	drop if active==0  // ignore inactive
	
	gen variableorform = " " + form + " (" + unique_event_name + ")"  // should be unique here, and when combined with FDL (hence space at start)
	isid form unique_event_name, missok  // harsh?   
		
	merge m:1 form unique_event_name using "`idmixdta'"
	count if _merge==1
	if `=r(N)' >0  {
		noi di " "
		noi di as err "Below: (form_name, event_name) in Automated Survey Invitations is invalid"
		noi list form unique_event_name if _merge==1, noobs ab(30)
	} 	
	keep if _merge==3
	replace unique_event_name = formevents if unique_event_name == ""
	drop formevents
	rename unique_event_name formevents
	
	keep variableorform combinedvars row form formevents
	gen source = "ASI"
	save "`asidta'", replace
}





***FDL - Form Display Logic 
local fdlcsv : dir . files "fdl_*.csv", respectcase
global wcfdlcsv : word count `fdlcsv'
if $wcfdlcsv > 1 {
	noi di as err `"redcapsetup requires no more than one fdl_*.csv file in the working directory. You have: `fdlcsv'"'
	exit
}
if $wcfdlcsv == 1 {
	noi di as txt `"Using `fdlcsv'"'
	import delimited `fdlcsv', clear bindquote(strict) varnames(1)
	isid form_name event_name, missok   // harsh? 	
	*tab1 *
	gen combinedvars = control_condition
	
	rename form_name form
	rename event_name unique_event_name
	ds unique_event_name, has(type string)
	if "`r(varlist)'" == "" {
		drop unique_event_name
		gen unique_event_name = ""
	}
	
	gen variableorform =  form + " (" + unique_event_name + ")"  
	gen row = _n + 1

	merge m:1 form unique_event_name using "`idmixdta'"
	count if _merge==1
	if `=r(N)' >0  {
		noi di " "
		noi di as err "Below: (form_name, event_name) in Form Display Logic is invalid"
		noi list form unique_event_name if _merge==1, noobs ab(30)
	} 	
	keep if _merge==3
	replace unique_event_name = formevents if unique_event_name == ""
	drop formevents
	rename unique_event_name formevents
	
	keep variableorform combinedvars row form formevents
	gen source = "FDL"	
	save "`fdldta'", replace
}





***DataDictionary
*REDCap will fail & give error if you upload a data dictionary that references a non-existent form
local ddcsv : dir . files "*DataDictionary*.csv", respectcase
global wcddcsv : word count `ddcsv'
if $wcddcsv == 0 {
	noi di as err "redcapsetup requires a *DataDictionary*.csv file in the working directory."
	exit
}
if $wcddcsv > 1 {
	noi di as err `"redcapsetup requires just one *DataDictionary*.csv file in the working directory. You have: `ddcsv'"'
	exit
}
noi di as txt `"Using `ddcsv'"' 
import delimited `ddcsv', clear bindquote(strict) maxquotedrows(180)
d
replace formname = "_all" in 1   // for record_id  (or whatever it has been renamed to)
gen source = "DD"
append using "`completevarsdta'"
gen row = _n + 1
merge m:1 formname using "`formeventsdta'" 
drop _merge
save "`DataDictionarydta'", replace



*Combine information from columns with potential references to variable names and event names
*codebook branchinglogicshowfieldonly fieldlabel choicescalculationsorslider fieldannotation sectionheader textvalidationmin textvalidationmax 
ds branchinglogicshowfieldonly fieldlabel choicescalculationsorslider fieldannotation sectionheader textvalidationmin textvalidationmax, has(type string) 
egen combinedvars = concat(`r(varlist)')


rename variablefieldname variableorform


if $wcalertscsv == 1 {
	append using "`alertsdta'"
}	

if $wcasicsv == 1 {
	append using "`asidta'"
}

if $wcfdlcsv == 1 {
	append using "`fdldta'"
}


*Extract contents inside square brackets: "[contents1]...[contents2]...[contents3]..." 
quietly {
	*Create output columns called contents1, contents2, contents3 etc.
	gen nrightbrackets = length(combinedvars) - length(subinstr(combinedvars, "]", "", .))
	su nrightbrackets
	local max = r(max)
	forvalues k = 1/`max' {
		gen contents`k' = ""
	}

	*Put text in the output columns, row-by-row
    forvalues i = 1/`=_N' {
        local cell = combinedvars[`i']
        local k = 0
        while ustrregexm(`"`cell'"', "\[([^\]]+)\]") {
			local ++k
            replace contents`k' = ustrregexs(1) in `i'
            *Now remove the matched "[...]" so the next match can be found
            local cell = usubinstr(`"`cell'"', ustrregexs(0), "", 1)
        }
    }
}



reshape long contents, i(variableorform) j(bracket_num)
drop if contents ==""
*tab contents


*Store "eventname" on the same row as the "variablename" that follows
gen isevent = 1 if regexm(contents, "_arm_[1-9]$")
bysort variableorform (bracket_num): gen eventname = contents[_n-1] if isevent[_n-1]==1
 

*Delete some rows and adjust contents
drop if isevent==1  // as that info is now on the next line


*"Smart variables" (see https://kb.wisc.edu/smph/informatics/88571) are not listed in variablefieldname
count if ustrregexm(contents, "\-")
if `=r(N)' > 0  {
	if "$smartvariable" !="" {
		noi di " "
		noi di as txt "Dropping the following [contents]:"
		noi tab contents if ustrregexm(contents, "\-")
	}
	*count if ustrregexm(contents, "event-name") & row!=.
	*if `=r(N)' > 0 {
	*	noi di " "
	*	noi di as res "Recommendation: search Codebook for [event-name] and check what follows is OK, e.g. if([event-name]='baseline_arm_1'..."
	*}
	drop if ustrregexm(contents, "\-")  // code may need tweaking if the table does not exclusively contain only "smart variables"
}


*When Field Type = checkbox,  recover variable names by losing e.g. "(2)" from "bci_services(2)" etc.
replace contents = regexreplaceall(contents, "\([^)]+\)", "")


*field annotations (also called action tags in newer REDCap terminology)
replace contents = regexreplaceall(contents, ":value", "")  
replace contents = regexreplaceall(contents, ":inline", "")
replace contents = regexreplaceall(contents, ":label", "")
replace contents = regexreplaceall(contents, ":hideunderscore", "")



keep eventname contents formevents variableorform source row

rename formevents completed_at
rename contents variablefieldname
gen source_row = source + " " + string(row)
rename row zrow

merge m:1 variablefieldname using "`DataDictionarydta'"

rename variablefieldname refvar
rename row refvar_row
rename zrow row
rename formevents refvar_events
rename formname refvar_formname


sort source row variableorform  

gen match = 0
foreach fevent of var fevent* {
	replace match = 1 if eventname == `fevent'
}


*completed_at is not a subset of refvar_events if s_formevents_wc>0
gen s_formevents = completed_at
foreach fevent of var fevent* {
	replace s_formevents = subinword(s_formevents,`fevent',"",1) 
}
gen s_formevents_wc = wordcount(s_formevents)
*tab s_formevents_wc



****Obviously wrong eventname specified before referenced variable
noi di " "
count if _merge==3 & eventname!="" & match==0
if `=r(N)' ==0  noi di as res "Good news: No instances of [obviously-wrong-eventname][variablename] found."
else {
	noi di as err "There are instances of [obviously-wrong-eventname][refvar]:"
	noi list source_row variableorform eventname refvar_events refvar refvar_row if _merge==3 & eventname!="" & match==0, noobs ab(30)
    noi di as err "Recommendation: Specify an event in refvar_events in place of eventname when variableorform references refvar." 
} 
noi di " " 



****No eventname specified before referenced variable when there should be
count if _merge==3 & eventname=="" & s_formevents_wc!=0 & refvar_row!=2
if `=r(N)' ==0  noi di as res "Good news: No instances of [variablename] which need to be [eventname][variablename] found."
else {
	noi di as err "There are instances of [refvar] which perhaps need to be [eventname][refvar]:"
	noi list source_row variableorform completed_at refvar_events refvar refvar_formname if _merge==3 & eventname=="" & s_formevents_wc!=0 & refvar_row!=2, noobs ab(30)
    noi di as err "Recommendation: For variableorform, you might need to specify an event in refvar_events if still want to reference refvar." 
}
*(unless completed_at is a subset of refvar_events)
noi di " "



****References to variables that don't exist 
*(or what is in [] that is not a variable in the data dictionary?)
count if _merge==1
if `=r(N)' ==0  noi di as res "Good news: No references to [non-existent variables] found."
else {
	noi di as err "This list may include references to [non-existent variables] in the last column:"
	noi list source_row variableorform refvar if _merge==1, noobs ab(30)
    noi di as err "Recommendation: For variableorform, you may need to change [refvar]." 
} 


drop if _merge==2
}


restore

end
