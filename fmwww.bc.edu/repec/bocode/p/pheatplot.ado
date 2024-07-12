
*! pheatplot 1.1.0 02 July, 2024 Nicolai Topstad Borgen (n.t.borgen@isp.uio.no)
*! pheatplot 1.0.0 27 September, 2023 Nicolai Topstad Borgen (n.t.borgen@isp.uio.no)
		
program define pheatplot, rclass

	version 17 
	
	syntax varlist(max=1), 	 									///
		[interaction(varname fv) frame(string) 					///
		BName(string asis) PName(string asis) 					///
		heatoptsp(string asis) heatoptsb(string asis)			///
		pvalues(string) SAVETable(string asis) 					///
		SAVEGraph(string asis)									///
		hexplot differences mono threshold(real .10)] 
	
	local xvar `varlist'
	
	if "`hexplot'"=="hexplot" local plot hexplot 
	if "`hexplot'"==""        local plot heatplot

		
	* Package dependency: heatplot *
	
	capture which heatplot 
	if _rc {
		di as result in smcl "Please install user-contributed package {it:heatplot} from SSC;"		///
			_newline `"click the following link to install package: {stata "ssc install heatplot":ssc install heatplot}"'
			exit 498
	}
	
	capture which colorpalette
	if _rc {
		di as result in smcl "Please install user-contributed package {it:colorpalette} from SSC;"		///
			_newline `"click the following link to install package: {stata "ssc install palettes":ssc install palettes}"'
			exit 498
	}	
	
	tempname errormata errorstata
	mata: `errormata'=findexternal("ColrSpace()") != J(1,1,NULL)
	mata: st_matrix("`errorstata'",`errormata')
	if `errorstata'[1,1]==0 {
		di as result in smcl "Please install user-contributed package {it:ColrSpace} from SSC;"		///
			_newline `"click the following link to install package: {stata "ssc install colrspace":ssc install colrspace}"'
			exit 498
	}	
	
	
	* Error messages *	
	if "`differences'"=="" & "`heatoptsb'"!="" {
		di as error in smcl "Option {it:heatoptsb()} is not allowed without option {it:differences}." 
		exit 498
	}
	
	if "`differences'"=="" & "`bname'"!="" {
		di as error in smcl "Option {it:bname()} is not allowed without option {it:differences}." 
		exit 498
	}
	
	if !inrange(`threshold',0.01,0.99) {
		di as error in smcl "Option {it:threshold()} must be a real number between 0.01 and 0.99." 
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
	
	tempname p coefficients frame pcolorclr bcolorclr pmonoclr bmonoclr
	
	local pmatrix `p'
	local bmatrix `coefficients'
	
	if "`frame'"==""		local frame `frame'
	if "`pname'"==""		local pname pvalues, replace
	if "`bname'"==""		local bname differences, replace

	
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
		
		* Error message if use has not used factor variables *
		if `r'==1 {
			capture di _b[`i'.`xvar']
			if _rc {
				di as error in smcl "Variable `xvar' was not included using factor variable notation in the previous regression model." 	///
				_newline "Run regression again using factor variable notation (i.e., i.`xvar'), and then use {it:pheatplot}." 								///
				_newline `"For information about factor variables, see {stata "help fvvarlist":help fvvarlist}."'
				exit 498
			}
		}
		
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
	
	* Default colors *
	
	mata: `pmonoclr'=ColrSpace()
	mata: `pmonoclr'.colors("#FFFFFF #C7C7C7 #A6A6A6 #242424")
	mata: `pmonoclr'.ipolate(100, "", ., ., (0, `threshold'-.01, `threshold', 1))
	
	mata: `pcolorclr'=ColrSpace()
	mata: `pcolorclr'.colors("#3A90FE #EDEDED #A89008")
	mata: `pcolorclr'.ipolate(100, "", ., ., (0, `threshold', 1))
	
	mata: `bmonoclr'=ColrSpace()
	mata: `bmonoclr'.colors("#FFFFFF #242424")
	mata: `bmonoclr'.ipolate(100)
	
	mata: `bcolorclr'=ColrSpace()
	mata: `bcolorclr'.colors("#3A90FE #EDEDED #A89008")
	mata: `bcolorclr'.ipolate(100)
	
	if "`mono'"=="" {
		local pcolor color(mata(`pcolorclr'), intensity(.90))
		local bcolor color(mata(`bcolorclr'))
	}
	if "`mono'"=="mono" {
		local pcolor color(mata(`pmonoclr'), intensity(.8))
		local bcolor color(mata(`bmonoclr'))
	}
	
	
	* Default options * 
	
	local pramp ramp(right space(20) label(0(.1)1) subtitle(P-value) format(%9.2f) length(55))
	local paspectratio aspectratio(1)
	local pylabel ylabel(`ylabs',nogrid)
	local pxlabel xlabel(`xlabs', nogrid angle(25))
	local pxtitle xtitle("") 
	local pytitle ytitle("") 
	local plower lower 
	local pdiagonal nodiagonal
	local pcuts cuts(0(.01)1)
	if "`pvalues'"=="off" local values 
	if "`pvalues'"=="" local values values(format(%9.2f)) 
		
	local bramp ramp(right space(15) label(#10) subtitle(Diff) length(55))
	local baspectratio aspectratio(1)
	local bylabel ylabel(`ylabs',nogrid)
	local bxlabel xlabel(`xlabs', nogrid angle(25))
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
		if substr("`opt'",1,1)=="" local opt "``c''"
			
		if "`opt'"=="ramp" 					local pramp
		if substr("`opt'",1,6)=="aspect" 	local paspectratio
		if substr("`opt'",1,4)=="ylab"		local pylabel 
		if substr("`opt'",1,4)=="xlab"		local pxlabel 
		if substr("`opt'",1,1)=="c"			local pcolor 
		if substr("`opt'",1,3)=="xti"		local pxtitle 
		if substr("`opt'",1,3)=="yti"		local pytitle 
		if "`opt'"=="upper"					local plower 
		if "`opt'"=="diagonal"				local pdiagonal 
		if substr("`opt'",1,3)=="val"		local pvalues
		if substr("`opt'",1,3)=="cut"		local pcuts
	
		if "``c''"=="" local c -1	
		
	}
	
	tokenize `useroptsb'
	local c=0 
	while `c'!=-1 {
		local ++c 
		
		local opt=substr("``c''",1,strpos("``c''","(")-1)
		if substr("`opt'",1,1)=="" local opt "``c''"
		
		if "`opt'"=="ramp" 					local bramp
		if substr("`opt'",1,6)=="aspect" 	local baspectratio
		if substr("`opt'",1,4)=="ylab"		local bylabel 
		if substr("`opt'",1,4)=="xlab"		local bxlabel 
		if substr("`opt'",1,1)=="c"			local bcolor 
		if substr("`opt'",1,3)=="xti"		local bxtitle 
		if substr("`opt'",1,3)=="yti"		local bytitle 
		if "`opt'"=="upper"					local blower 
		if "`opt'"=="diagonal"				local bdiagonal 
		if substr("`opt'",1,3)=="val"		local bvalues
	
		if "``c''"=="" local c -1	
		
	}
	
	
	* Heatplots * 
	
	if "`differences'"=="differences" {
		`plot' `bmatrix', `heatoptsb'  `bramp' `baspectratio'				///
			`bylabel' `bxlabel' `bcolor' `bxtitle' `bytitle' `blower'		///
			`bdiagonal' name(`bname')	
	}
	
	`plot' `pmatrix', `heatoptsp' `values' `pramp'  `paspectratio' 			///
		`pylabel' `pxlabel' `pcolor' `pxtitle' `pytitle' `plower'			///
		`pdiagonal' `pcuts' name(`pname') 

	
	* Table (optional) *
		
	if `"`savetable'"'!="" {
		frame `frame' {
			putdocx clear
			putdocx begin, font(,10) 
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
			putdocx save `savetable'
		}
	}

	* Graph (optional) *
	if `"`savegraph'"'!="" {
		graph export `savegraph'
	}
	
		
	* Return matrices *
	
	return matrix differences=`bmatrix'
	return matrix pvalues=`pmatrix'
		
end	

