*! version 1.2.0 13Nov2022 MLB
program define mkproject
    version 10
    syntax name(id="project abbreviation" name=abbrev), ///
           [ DIRectory(string)                          /// 
		     smclpres git opendata]

	
	if "`opendata'" != "" & "`git'" == "" {
		di as err "{p}the option opendata can only be specified with the option git{p_end}"
		exit 198
	}
	if "`directory'" == "" local directory = c(pwd)
		   
    qui cd `"`directory'"'
    if `"`: dir . dirs "`abbrev'"'"' != "" {
        di as err "{p}directory " as result `"`abbrev'"' as err " already exists in " as result `"`directory'{p_end}"'
            exit 693
    }
	
	if "`smclpres'" == "" {
		normalproj, abbrev(`abbrev') `git'
	}
	else {
		smclproj, abbrev(`abbrev')
	}
	
	if "`git'" != "" git, `opendata'
	
	if "`smclpres'" == "" {
		qui cd work
		if c(stata_version)>=13{
			projmanager ../`abbrev'.stpr
		}
		else{
			doedit `abbrev'_main.do	
		}
	}
	else {
		qui cd source
		doedit `abbrev'.do
	}
	
end

program define git
	syntax , [opendata]
	
	if "`opendata'" == "" {
		local fn = ".ignore"
		tempname ign
		file open `ign' using `fn', write text
		file write `ign' "*.dta"_n
		file close `ign'
	}
	
	local fn = "readme.md"
	tempname readme
	file open `readme' using `fn', write text
	file write `readme' `"# <Project name>"'_n
	file write `readme' _n
	file write `readme' `"## Description"'_n
	file write `readme' _n
	file write `readme' `"## Requirements"'_n
	file write `readme' _n
	file write `readme' `"These .do files require Stata version `c(version)'."'_n
	if "`opendata'" == "" {
		file write `readme' `"For legal/privacy reasons the raw data is not included in this repository."' _n
		file write `readme' `"To run these .do files one must first obtain the raw data separately from <website>"'_n
	}
	file close `readme'
	
	!git init --initial-branch=main
	!git add .
	!git commit -m "initial commit"
end

program define normalproj
	syntax, abbrev(string) [git]

	mkdir `abbrev'
    mkdir `abbrev'/docu
    mkdir `abbrev'/admin
	if "`git'" == "" {
		mkdir `abbrev'/posted
		mkdir `abbrev'/posted/data
	}
	else {
		mkdir `abbrev'/protected
		mkdir `abbrev'/protected/data
	}
	mkdir `abbrev'/work
    
    qui cd `abbrev'/work
    write_main `abbrev'
    boilerplate `abbrev'_dta01.do, dta noopen `git'
	boilerplate `abbrev'_ana01.do, ana noopen `git'
    qui cd ../docu
    write_log 
    qui cd ..
end

program define smclproj
	syntax, abbrev(string)
	
	mkdir `abbrev'
	mkdir `abbrev'/source
	mkdir `abbrev'/presentation
	mkdir `abbrev'/handout
    cd `abbrev'
	write_readme
	qui cd source
	boilerplate `abbrev'.do, smclpres noopen
	qui cd ..
end

program define write_main
	version 10
    syntax name(id="project abbreviation" name=abbrev)
    
    local fn = "`abbrev'_main.do"
    tempname main
    file open `main' using `fn', write text
    file write `main' "version `c(stata_version)'"_n    
    file write `main' "clear all"_n
    file write `main' "macro drop _all"_n
    file write `main' `"cd "`c(pwd)'""'_n
    file write `main' _n
    file write `main' "do `abbrev'_dta01.do // some comment"_n
    file write `main' "do `abbrev'_ana01.do // some comment"_n
    file write `main' _n
    file write `main' "exit"_n
    file close `main'
end

program define write_log
    version 10
	local fn = "research_log.txt"
    tempname log
    file open  `log' using `fn', write text
    file write `log' "============================"_n
    file write `log' "Research log: <Project name>"_n
    file write `log' "============================"_n
    file write `log' _n _n
    file write `log' "`c(current_date)': Preliminaries"_n
    file write `log' "=========================="_n
    file write `log' _n
    file write `log' "Author(s):"_n
    file write `log' "----------"_n
    file write `log' "Authors with affiliation and email"_n
    file write `log' _n _n
    file write `log' "Preliminary research question:"_n
    file write `log' "------------------------------"_n
    file write `log' _n _n
    file write `log' "Data:"_n
    file write `log' "-----"_n
    file write `log' "data, where and how to get it, when we got it, version"_n
    file write `log' _n _n
    file write `log' "Intended conference:"_n
    file write `log' "--------------------"_n
    file write `log' "conference, deadline"_n
    file write `log' _n _n
    file write `log' "Intended journal:"_n
    file write `log' "-----------------"_n
    file write `log' "journal, requirements, e.g. max word count"_n
	file close `log'
end

program define write_readme
    version 10
	local fn = "readme.txt"
    tempname readme
    file open  `readme' using `fn', write text
    file write `readme' `"Readme"'_n
    file write `readme' `"======"'_n
    file write `readme' `""'_n
    file write `readme' `"This .zip file contains 3 folders:"'_n
    file write `readme' `""'_n
    file write `readme' `"presentation"'_n
    file write `readme' `"------------"'_n
    file write `readme' `""'_n
    file write `readme' `"This is the folder contains the .smcl presentation. To view this:"'_n
    file write `readme' `"o open Stata,"'_n 
    file write `readme' `"o use -cd- to change to this directory"'_n
    file write `readme' `"o type -view presentation.smcl- "'_n
    file write `readme' `""'_n
    file write `readme' `"handout"'_n
    file write `readme' `"-------"'_n
    file write `readme' `""'_n
    file write `readme' `"This contains the .html handout created for this presentation. This"'_n 
    file write `readme' `"is particularly useful for quickly looking things up and if you do not "'_n
    file write `readme' `"have Stata installed on your current devise."'_n
    file write `readme' `""'_n
    file write `readme' `"source"'_n
    file write `readme' `"------"'_n
    file write `readme' `""'_n
    file write `readme' `"This folder contains the source used to create the presentation. To "'_n
    file write `readme' `"create the presentation from this source:"'_n
    file write `readme' `""'_n
    file write `readme' `"o open Stata"'_n
    file write `readme' `"o Install smclpres by typing -ssc install smclpres-"'_n
    file write `readme' `"o use -cd- to change to this directory"'_n
    file write `readme' `"o make the presentation by typing "'_n
    file write `readme' `"  -smclpres using presentation.do , dir(../presentation) replace-"'_n
	file close `readme'
end
