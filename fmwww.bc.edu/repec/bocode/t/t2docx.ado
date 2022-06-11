* Authors:
* Chuntao Li, Ph.D. , China Stata Club(爬虫俱乐部)(chtl@hust.edu.cn)
* Zijian LI, China Stata Club(爬虫俱乐部)(jeremylee_41@163.com)
* Yuan Xue, China Stata Club(爬虫俱乐部)(xueyuan@hust.edu.cn)
* Updated on June 9th, 2022
program define t2docx

	if _caller() < 15.0 {
		disp as error "this is version `=_caller()' of Stata; it cannot run version 15.0 programs"
		exit 9
	}

	syntax varlist(numeric) [if] [in] using/, [append APPEND2(string asis) replace title(string) ///
		fmt(string) NOSTAr STAR STAR2(string asis) staraux starsps noT p se note(string asis) ///
		pagesize(string) font(string) landscape UNEqual Welch diff(string asis) ///
		varname varlabel layout(string) *] by(varname)
	
	tokenize `"`0'"', parse(",")

	marksample touse, strok nov
	qui count if `touse'
	if `r(N)' == 0 exit 2000
	
	local 0 `1', `options'
	local margins
	syntax varlist(numeric) [if] [in] using/, [margin(passthru) *]
	while `"`margin'"' != "" {
		local margins `margins' `margin'
		local 0 `1', `options'
		syntax varlist(numeric) [if] [in] using/, [margin(passthru) *]
	}
	
	if `"`options'"' != "" {
		di as err "option " `"{bf:`options'}"' " not allowed"
		exit 198
	}

	if ("`append'" != "" | `"`append2'"' != "") & "`replace'" != "" {
		disp as error "you could not specify both append and replace"
		exit 198
	}
	
	if `"`append2'"' != "" & `"`append2'"' != "pagebreak" & c(stata_version) < 16 {
		disp as error "you could only specify append or append(pagebreak) in the version before 16"
		exit 198
	}
	
	if "`varname'" != "" & "`varlabel'" != "" {
		disp as error "you could not specify both varname and varlabel"
		exit 198
	}

	if ("`nostar'" != "") & ("`star'" != "" | "`star2'" != "" | "`staraux'" != "" | "`starsps'" != "") {
		disp as error "you could not specify both nostar and star[()]|staraux|starsps"
		exit 198
	}

	if "`t'" != "" & "`staraux'" != "" {
		disp as error "you could not specify both not and staraux"
		exit 198
	}

	if "`p'" != "" & "`se'" != "" {
		disp as error "you could not specify both p and se"
		exit 198
	}
	
	if `"`diff'"' != "" {
		mata splitdiff(`"`diff'"')
		if `diff_num' != 2 {
			disp as error "only 2 groups allowed in the option diff()"
			exit 198
		}
	}

	mata var_number(`"`varlist'"')
	qui tab `by'
	local by_num = r(r)
	if `by_num' > 2 & `"`diff'"' == "" {
		disp as error "more than 2 groups found, only 2 allowed, you could specify 2 groups in the option diff()"
		exit 420
	}
	local by_type: type `by'
	
	local rownum = scalar(var_number) + 1
	local colnum = `by_num' * 2 + 3
	if "`t'" != "" & "`p'" == "" & "`se'" == "" local colnum = `colnum' - 1

	qui {
		if `"`pagesize'"' == "" local pagesize = "A4"
		if `"`font'"' == "" local font = "Times New Roman"
		putdocx clear
		if c(stata_version) < 16 & "`append2'" == "pagebreak" {
			putdocx begin, font(`font')
			putdocx sectionbreak, pagesize(`pagesize') `landscape' `margins'
		}
		else {
			putdocx begin, font(`font') pagesize(`pagesize') `landscape' `margins'
		}
		
		putdocx paragraph, spacing(after, 0) halign(center)

		if `"`title'"' == "" local title = "T-test Table"
		if "`layout'" == "" local layout = "autofitwindow"
		
		putdocx text (`"`title'"')

		if `"`note'"' != "" {
			putdocx table ttbl = (`rownum', `colnum'), border(all, nil) border(top) halign(center) note(`note') layout(`layout')
			putdocx table ttbl(`rownum', .), border(bottom)
		}
		else {
			putdocx table ttbl = (`rownum', `colnum'), border(all, nil) border(top) border(bottom) halign(center) layout(`layout')
		}

		putdocx table ttbl(1, .), border(bottom)
		
		tabstat `varlist' if `touse', by(`by') save statistics(n mean)
		forvalues vi = 1/`by_num' {
			if `vi' == 1 mat stat = r(Stat`vi')'
			else mat stat = stat, r(Stat`vi')'
		}
		putdocx table ttbl(1, 1) = ("varname"), halign(left)
		
		forvalues vi = 1/`by_num' {
			putdocx table ttbl(1, `= `vi' * 2') = ("obs(`r(name`vi')')"), halign(right)
			putdocx table ttbl(1, `= `vi' * 2 + 1') = ("mean(`r(name`vi')')"), halign(right)
		}
		putdocx table ttbl(1, `= `by_num' * 2 + 2') = ("mean-diff"), halign(right)
		if "`t'" == "" & "`p'" == "" & "`se'" == "" putdocx table ttbl(1, `colnum') = ("t"), halign(right)
		else if "`p'" != "" putdocx table ttbl(1, `colnum') = ("p"), halign(right)
		else if "`se'" != "" putdocx table ttbl(1, `colnum') = ("se"), halign(right)
		
		if "`fmt'" == "" local fmt %9.3f

		if `"`star2'"' == "" {
			local star_1 *
			local star_2 **
			local star_3 ***
			local siglevel1 = 0.1
			local siglevel2 = 0.05
			local siglevel3 = 0.01
			local siglevel4 = 0
			local levelnum = 3
		}
		else {
			mata var_number(`"`star2'"')
			local levelcount = scalar(var_number)
			if mod(`levelcount', 2) == 1 {
				disp as error "you specify the option star() incorrectly"
				exit 198
			}
			else {
				token `"`star2'"'
				local levelnum = `levelcount'/2
				forvalue i = 1(1)`levelnum' {
					local star_`i' ``=`i'*2-1''
					local siglevel`i' ``=`i'*2''
				}
			}
			local siglevel`=`levelnum'+1' = 0
		}

		local row = 2
		foreach v of varlist `varlist'{
			if "`varlabel'" == "" putdocx table ttbl(`row', 1) = (`"`v'"'), halign(left)
			else {
				cap local lab: var label `v'
				if _rc == 0 {
					if "`lab'" == "" putdocx table ttbl(`row', 1) = (`"`v'"'), halign(left)
					else putdocx table ttbl(`row', 1) = (`"`lab'"'), halign(left)
				}
				else putdocx table ttbl(`row', 1) = (`"`v'"'), halign(left)
			}
			local row = `row' + 1
		}

		local row = 2
		
		foreach v of varlist `varlist'{
			if `"`diff'"' == "" ttest `v' if `touse', by(`by') `welch' `unequal'
			else if index("`by_type'", "str") ttest `v' if `touse' & inlist(`by', `"`diff1'"', `"`diff2'"'), by(`by') `welch' `unequal'
			else ttest `v' if `touse' & inlist(`by', `diff1', `diff2'), by(`by') `welch' `unequal'

			local staroutput = ""
			local bstar = ""
			local tstar = ""
			forvalues i = 1/`levelnum' {
				if `r(p)' < `siglevel`i'' & `r(p)' >= `siglevel`=`i'+1'' {
					local staroutput `star_`i''
				}
			}

			if "`staraux'" == "" local bstar `staroutput'
			else local tstar `staroutput'
			
			if "`nostar'" != "" {
				local bstar = ""
				local tstar = ""
			}

			forvalues vi = 1/`by_num' {
				putdocx table ttbl(`row', `= `vi' * 2') = (string(scalar(stat[`= `row' - 1', `= `vi' * 2 - 1']))), halign(right)
				putdocx table ttbl(`row', `= `vi' * 2 + 1') = (`"`=subinstr("`: disp `fmt' scalar(stat[`= `row' - 1', `= `vi' * 2'])'", " ", "", .)'"'), halign(right)
			}

			if "`starsps'" == "" {
				putdocx table ttbl(`row', `= `by_num' * 2 + 2') = (`"`=subinstr("`: disp `fmt' r(mu_1)-r(mu_2)'", " ", "", .)'`bstar'"'), halign(right)
				if "`t'" == "" & "`p'" == "" & "`se'" == "" putdocx table ttbl(`row', `= `by_num' * 2 + 3') = (`"`=subinstr("`: disp `fmt' r(t)'", " ", "", .)'`tstar'"'), halign(right)
				else if "`p'" != "" putdocx table ttbl(`row', `= `by_num' * 2 + 3') = (`"`=subinstr("`: disp `fmt' r(p)'", " ", "", .)'`tstar'"'), halign(right)
				else if "`se'" != "" putdocx table ttbl(`row', `= `by_num' * 2 + 3') = (`"`=subinstr("`: disp `fmt' r(se)'", " ", "", .)'`tstar'"'), halign(right)
			}
			else {
				putdocx table ttbl(`row', `= `by_num' * 2 + 2') = (`"`=subinstr("`: disp `fmt' r(mu_1)-r(mu_2)'", " ", "", .)'"'), halign(right)
				if "`bstar'" != "" putdocx table ttbl(`row', `= `by_num' * 2 + 2') = (`"`bstar'"'), append script(super) halign(right)
				if "`t'" == "" & "`p'" == "" & "`se'" == "" putdocx table ttbl(`row', `= `by_num' * 2 + 3') = (`"`=subinstr("`: disp `fmt' r(t)'", " ", "", .)'"'), halign(right)
				else if "`p'" != "" putdocx table ttbl(`row', `= `by_num' * 2 + 3') = (`"`=subinstr("`: disp `fmt' r(p)'", " ", "", .)'"'), halign(right)
				else if "`se'" != "" putdocx table ttbl(`row', `= `by_num' * 2 + 3') = (`"`=subinstr("`: disp `fmt' r(se)'", " ", "", .)'"'), halign(right)
				if "`tstar'" != "" putdocx table ttbl(`row', `= `by_num' * 2 + 3') = (`"`tstar'"'), append script(super) halign(right)
			}
			local row = `row' + 1
		}

		if "`replace'" == "" & "`append'" == "" & "`append2'" == "" {
			putdocx save `"`using'"'
		}
		else if "`append2'" == ""{
			putdocx save `"`using'"', `replace'`append'
		}
		else if c(stata_version) < 16 {
			putdocx save `"`using'"', append
		}
		else {
			putdocx save `"`using'"', append(`append2')
		}
	}
	di as txt `"t-test table have been written to file {browse "`using'"}"'
end

mata
	void function var_number(string scalar var_list) {

		string rowvector var_vector

		var_vector = tokens(var_list)
		st_numscalar("var_number", cols(var_vector))
	}
	
	void function splitdiff(string scalar diff) {
	
		string rowvector diff_vector
		
		diff_vector = tokens(diff)
		st_local("diff_num", strofreal(cols(diff_vector)))
		st_local("diff1", diff_vector[1, 1])
		st_local("diff2", diff_vector[1, 2])	
	}
end


