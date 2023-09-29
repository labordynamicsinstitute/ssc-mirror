
*! pheatplot 1.0.0 27September2023 Nicolai Topstad Borgen (n.t.borgen@isp.uio.no)


program define pheatplot, rclass

	version 17 
	
	syntax varlist(max=1), 	 									///
		[interaction(varname fv) frame(string) 					///
		bname(string) pname(string) 							///
		heatoptsp(string asis) heatoptsb(string asis)			///
		pvalues(string) save(string) hexplot differences] 
	
	local xvar `varlist'
	
	if "`hexplot'"=="hexplot" local plot hexplot 
	if "`hexplot'"==""        local plot heatplot

		
	* Package dependency: heatplot (Jann, B. 2009)*
	
	capture which heatplot 
	if _rc {
		di as result in smcl "Please install user-contributed package {it:heatplot} from SSC;"		///
			_newline `"click the following link to install package: {stata "ssc install heatplot":ssc install heatplot}"'
			exit 498
	}
		
	* Identify type of factor variables *  	
		
	if substr("`interaction'",2,1)=="." {
		local pre=substr("`interaction'",1,1)
		local ivar=substr("`interaction'",3,.)
	}
	else {
		local ivar `interaction'
	}
	
	if "`interaction'"!="" {
		qui margins i.`xvar', dydx(`ivar') post
	}
			
	
	* Names of matrices, frame, and graphs *
	
	tempname p coefficients frame
	
	local pmatrix `p'
	local bmatrix `coefficients'
	
	if "`frame'"==""		local frame `frame'
	if "`pname'"==""		local pname pvalues
	if "`bname'"==""		local bname differences

	* Create frame and matrices (to be filled below) * 
		
	frame create `frame' y x str50 Y str50 X pvalue estimate se 
	
	qui levelsof `xvar' if e(sample), local(l)
	matrix `pmatrix'=J(r(r),r(r),.)
	matrix `bmatrix'=J(r(r),r(r),.)
	local num=r(r)
		
	* Fill frame and matrices * 
	
	local labs 
	
	local r=0
	foreach i of local l {
		local ++r
		
		local labs `labs' `r' "`: label (`xvar') `i''"
		if `r'!=1 local ylabs `ylabs' `r' "`: label (`xvar') `i''"
		if `r'!=`num' local xlabs `xlabs' `r' "`: label (`xvar') `i''"
		
		local c=0
		foreach j of local l {
			local ++c
			if `i'==`j' continue
			local lab1 `: label (`xvar') `i''
			local lab2 `: label (`xvar') `j''
			if "`interaction'"=="" {
				qui lincom `i'.`xvar'-`j'.`xvar' 
			}
			if "`interaction'"!="" {
				if "`pre'"=="i" {
					qui lincom [1.`ivar']`i'.`xvar'-[1.`ivar']`j'.`xvar' 
				}
				if "`pre'"=="" {
					qui lincom [`ivar']`i'.`xvar'-[`ivar']`j'.`xvar' 
				}
			}
			frame post `frame' (`i') (`j') ("`lab1'") ("`lab2'")	///
				(r(p)) (r(estimate)) (r(se))
			matrix `pmatrix'[`r',`c']=r(p)
			matrix `bmatrix'[`r',`c']=r(estimate)
		}
	}

	
	* Default options * 
	
	local pramp ramp(right space(20) label(#10) subtitle(P-value) format(%9.2f))
	local paspectratio aspectratio(1)
	local pylabel ylabel(`ylabs',nogrid)
	local pxlabel xlabel(`xlabs', nogrid angle(25))
	local pcolor color(plasma, reverse intensity(.6))
	local pxtitle xtitle("") 
	local pytitle ytitle("") 
	local plower lower 
	local pdiagonal nodiagonal
	if "`pvalues'"=="off" local values 
	if "`pvalues'"=="" local values values(format(%9.2f)) 
		
	local bramp ramp(right space(15) label(#10) subtitle(Diff))
	local baspectratio aspectratio(1)
	local bylabel ylabel(`ylabs',nogrid)
	local bxlabel xlabel(`xlabs', nogrid angle(25))
	local bcolor color(plasma, reverse intensity(.6))
	local bxtitle xtitle("") 
	local bytitle ytitle("") 
	local blower lower 
	local bdiagonal nodiagonal
		
	* Parse user-written options (takes precedence over default options) * 
	
	if "`heatoptsb'"!="" local useroptsb: subinstr local heatoptsb "," "", all
	if "`heatoptsp'"!="" local useroptsp: subinstr local heatoptsp "," "", all
	
	tokenize `useroptsp'
	local c=0 
	while `c'!=-1 {
		local ++c 
		
		local opt=substr("``c''",1,strpos("``c''","(")-1)
		if "`opt'"=="legend" 		local pramp
		if "`opt'"=="ramp" 			local pramp
		if "`opt'"=="aspectratio" 	local paspectratio
		if "`opt'"=="ylabel"	 	local pylabel 
		if "`opt'"=="xlabel" 		local pxlabel 
		if "`opt'"=="color"			local pcolor 
		if "`opt'"=="xtitle"		local pxtitle 
		if "`opt'"=="ytitle"		local pytitle 
		if "`opt'"=="lower"			local plower 
		if "`opt'"=="diagonal"		local pdiagonal 
		if "`opt'"=="values"		local pvalues
	
		if "``c''"=="" local c -1	
		
	}
	
	tokenize `useroptsb'
	local c=0 
	while `c'!=-1 {
		local ++c 
		
		local opt=substr("``c''",1,strpos("``c''","(")-1)
		if "`opt'"=="legend" 		local bramp
		if "`opt'"=="ramp" 			local bramp
		if "`opt'"=="aspectratio" 	local baspectratio
		if "`opt'"=="ylabel"	 	local bylabel 
		if "`opt'"=="xlabel" 		local bxlabel 
		if "`opt'"=="color"			local bcolor 
		if "`opt'"=="xtitle"		local bxtitle 
		if "`opt'"=="ytitle"		local bytitle 
		if "`opt'"=="lower"			local blower 
		if "`opt'"=="diagonal"		local bdiagonal 
		if "`opt'"=="values"		local bvalues
	
		if "``c''"=="" local c -1	
		
	}
	
	
	
	* Heatplots * 
	
	if "`differences'"=="differences" {
		`plot' `bmatrix', `heatoptsb'  `bramp' `baspectratio'				///
			`bylabel' `bxlabel' `bcolor' `bxtitle' `bytitle' `blower'		///
			`bdiagonal' name(`bname', replace)	
	}
	
	`plot' `pmatrix', `heatoptsp' `values' `pramp'  `paspectratio' 			///
		`pylabel' `pxlabel' `pcolor' `pxtitle' `pytitle' `plower'			///
		`pdiagonal' name(`pname', replace)

	
	* Table (optional) *
		
	if "`save'"!="" {
		frame `frame' {
			putdocx clear
			putdocx begin, font(,10) /*landscape */
			putdocx table tbl=data(Y X estimate se pvalue), border(all,nil)	///
				layout(autofitcontents) varnames							///
				note("Note: The difference is calculated as the coefficient for group 1 minus the coefficient for group 2 using lincom, while the standard error is the standard error of this difference.")
			putdocx table tbl(1,1) = ("Group 1")
			putdocx table tbl(1,2) = ("Group 2")
			putdocx table tbl(1,3) = ("Difference")
			putdocx table tbl(1,4) = ("Standard error")
			putdocx table tbl(1,5) = ("P-value")
			putdocx table tbl(1/1,.), bold border(top) border(bottom)
			putdocx table tbl(.,3), nformat(%9.4f)
			putdocx table tbl(.,4), nformat(%9.4f)
			putdocx table tbl(.,5), nformat(%9.3f)
			local last=_N+1 
			putdocx table tbl(`last',.), border(bottom)
			putdocx save `save'
		}
	}
		
	* Return matrices *
	
	return matrix differences=`bmatrix'
	return matrix pvalues=`pmatrix'
		
end	

