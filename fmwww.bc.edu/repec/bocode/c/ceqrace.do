


*ADO FILE FOR CEQ ETHNO RACIAL WORKBOOK

*VERSION AND NOTES (changes between versions described under CHANGES)
*! v1.0 30jun2015 For use with June 1 2015 version of Ethno Racial Workbook
*! (beta version; please report any bugs), written by Rodrigo Aranda raranda@tulane.edu

*CHANGES

*NOTES

*TO DO


#delimit;
*******************
* ceqrace PROGRAM *
*******************;

cap program drop ceqrace ;
forvalues tt=1/28{;
cap program drop f`tt'_race;
};

*Tables:
F3. Ethno-Racial Populations
F5. Population Composition											
F6. Income Distribution											
F7. Summary Poverty Rates											
F8. Summary Poverty Gap Rates											
F9. Summary Poverty Gap Squared Rates											
F10. Summary Inequality Indicators											
F11. Mean Incomes											
F12. Incidence by Decile											
F13. Incidence by Socioeconomic Group											
F14. Cross-Race Incidence (Not necessary to program here)											
F15. Horizontal Equity											
F16. Fiscal Profile											
F17. Coverage Rates (Totals)											
F18. Coverage Rates (Targets)											
F19. Leakages											
F20. Mobility Matrices											
F21. Education (Totals)											
F22. Education (Rates)											
F23. Household Decision											
F24. Infrastructure Access											
F25. Theil Disaggregation											
F26. Inequality of Opportunity											
F27. Significance											
;


#delimit;
program define ceqrace, rclass;
version 13.0;
syntax   [if] [in] [using/] [pweight/] [,table(string) Market(varname) race1(varname) race2(varname) race3(varname) race4(varname) race5(varname)
		   Netmarket(varname) 
		   MPLUSPensions(varname)
		   Gross(varname)
		   TAXABle(varname)
		   Disposable(varname) 
		   Postfiscal(varname) 
		   FStar(varname)
		   Consumable(varname)
		   Final(varname) 
		   PL125(string)				
			PL250(string)               
			PL400(string) 
		   NEXTreme(string)
		   NMODerate(string)
		   WHite(varname)
		   AFRicandescendant(varname)
		   indigenous(varname)
		   psu(varname)   
		   strata(varname) 
		   dtax(varname)
		   CONTributions(varname)
		   CONTPensions(varname)
		   CONYPensions(varname)
		   NONContributory(varname)
		   flagcct(varname)
		   OTRANsfers(varname)
		   ISUBsidies(varname)
		   itax(varname)
		   IKEducation(varname)
		   IKHealth(varname)
		   HUrban(varname)
		   age(varname) 
		   edpre(varname)
		   redpre(string)
		   edpri(varname) 
		   edsec(varname) 
		   edter(varname) 
		   redpri(string) 
		   redsec(string) 
		   redter(string) 
		   hhe(varname) 
		   hhid(varname)
		   CCT(varname)
		   SCHolarships(varname)
		   UNEMPloyben(varname)
		   FOODTransfers(varname)
		   HEALTH(varname)
		   PENSions(varname)
		   TARCCT(varname)
		   TARNCP(varname)
		   TARPENsions(varname)
		   PSU(varname) 
			Strata(varname)
			water(varname)
		   electricity(varname)
		   walls(varname)
		   floors(varname)
		   roof(varname)
		   sewage(varname)
		   roads(varname)
		   OPEN
		   		   ];

*******General Options**************************************************************************;
* general programming locals;
	local dit display as text in smcl;
	local die display as error in smcl;
	local command ceqrace;
	local version 1.0;
	`dit' "Running version `version' of `command' on `c(current_date)' at `c(current_time)'" _n "(please report this information if reporting a bug to raranda@tulane.edu)";
	local versionprint ("Results produced by version `version' of `command' on `c(current_date)' at `c(current_time)'");
	
#delimit cr
	* make sure using is xls or xlsx
	cap putexcel clear
	if `"`using'"'!="" {
		local period = strpos("`using'",".")
		if `period'>0 { // i.e., if `"`using'"' contains .
			local ext = substr("`using'",`period',.)
			if "`ext'"!=".xls" & "`ext'"!=".xlsx" {
				`die' "File extension must be .xls or .xlsx to write to an existing CEQ Master Workbook (requires Stata 13 or newer)"
				exit 198
			}
		}
		else {
			local using `"`using'.xlsx"'
			qui di "
			`dit' "File extension of {bf:using} not specified; .xlsx assumed"
		}
		// give error if file doesn't exist:
		confirm file `"`using'"'
		qui di "
	}
	else { // if "`using'"==""
		`dit' "Warning: No file specified with {bf:using}; results not exported to Ethno Racial Tables"
	}
	if strpos(`"`using'"'," ")>0 & "`open'"!="" { // has spaces in filename
		qui di "
		`dit' `"Warning: `"`using'"' contains spaces; {bf:open} option will not be executed. File can be opened manually after dII runs."'
		local open "" // so that it won't try to open below
	}
	
#delimit;	
forvalues x=1/5{;
if "`race`x''"==""{;
local cc=`cc'+1;
tempvar race`x';
gen `race`x''=.;
};
};
if `cc'>3{;
display as error "Must specify at least two ethnic groups or races";
exit;
};
 *if `"`weight'"' != "" {;
   *             local wght `"[`weight'`exp']"';
    *    };
	#delimit cr
	cap svydes
	scalar no_svydes = _rc
	tempvar ones
	gen `ones'=1
	if !_rc qui svyset // gets the results saved in return list
	if "`r(wvar)'"=="" & "`exp'"=="" {
		`dit' "Warning: weights not specified in svydes or the command"
		`dit' "Hence, equal weights (simple random sample) assumed"
	}
	else {
		if "`exp'"=="" & "`r(wvar)'"!="" local w `r(wvar)'
		if "`exp'"!="" local w `exp'
		if "`w'"!="" {
			tempvar weightvar
			qui gen `weightvar' = `w'
			local w `weightvar'
		}
		else local w "`ones'"
		
		if "`w'"!="" {
			local pw "[pw = `w']"
			local aw "[aw = `w']"
		}
		if "`exp'"=="" & "`r(wvar)'"!="" {
			local weight "pw"
			local exp "`r(wvar)'"
		}
	}		
	
	#delimit;
		

forvalues tt=1/18{;//Run each particular program;
if "`table'"=="f`tt'"{;
f`tt'_race `0';
};
};

	
end;
*******TABLE F3: ETHNO-RACIAL POPULATIONS**************************************************************************;

program define f3_race;
syntax  [if] [in] [pweight/] [using/] [,table(string) race1(varname) race2(varname) race3(varname) race4(varname) race5(varname) OPEN];
di "Populations `'";
local sheet="F3. Ethno-Racial Populations";
local version 1.0;
local command ceqrace;
local versionprint ("Results produced by version `version' of `command' on `c(current_date)' at `c(current_time)'");


  *if `"`weight'"' != "" {;
   *             local wght `"[`weight'`exp']"';
    *    };
	#delimit cr
	cap svydes
	scalar no_svydes = _rc
	tempvar ones
	gen `ones'=1
	if !_rc qui svyset // gets the results saved in return list
	if "`r(wvar)'"=="" & "`exp'"=="" {
		`dit' "Warning: weights not specified in svydes or the command"
		`dit' "Hence, equal weights (simple random sample) assumed"
	}
	else {
		if "`exp'"=="" & "`r(wvar)'"!="" local w `r(wvar)'
		if "`exp'"!="" local w `exp'
		if "`w'"!="" {
			tempvar weightvar
			qui gen `weightvar' = `w'
			local w `weightvar'
		}
		else local w "`ones'"
		
		if "`w'"!="" {
			local pw "[pw = `w']"
			local aw "[aw = `w']"
		}
		if "`exp'"=="" & "`r(wvar)'"!="" {
			local weight "pw"
			local exp "`r(wvar)'"
		}
	}		
	
	#delimit;
	
forvalues x=1/5{;
	if "`race`x''"==""{;
		local cc=`cc'+1;
		tempvar race`x';
		gen `race`x''=.;
		};
	};

	qui{;
		matrix f3_1=J(6,1,.);
		matrix f3_2=J(6,1,.);
		tempvar tot;
		gen `tot'=1;
		matrix colnames f3_1="Survey unweighted";
		matrix colnames f3_2="Survey weighted";
		matrix rownames f3_1=race1 race2 race3 race4 race5 tot;
		matrix rownames f3_2=race1 race2 race3 race4 race5 tot;
		forvalues x=1/5{;
			local c=`c'+1;
			summ `race`x'' ;
			matrix f3_1[`c',1]=r(sum);

			summ `race`x'' `wght';
			matrix f3_2[`c',1]=r(sum);
		};
		summ `tot' ;
		matrix f3_1[6,1]=r(sum);

		summ `tot' `wght';
		matrix f3_2[6,1]=r(sum);

		noisily di "Population totals Survey-unweighted";
		noisily matrix list f3_1;
		noisily di "Population totals Survey-weighted";
		noisily matrix list f3_2;
		putexcel C8=matrix(f3_1) using `using', modify sheet("`sheet'") keepcellformat;
		putexcel D8=matrix(f3_2) using `using', modify sheet("`sheet'") keepcellformat;
		putexcel A3=`versionprint' using `using', modify sheet("`sheet'") keepcellformat;
	};
	********
	* OPEN *
	********;
	if "`open'"!="" {;
		!start `using'; // doesn't work with "" or `""' so I already changed `open' to "" if using has spaces, ;
	};

end;
*******TABLE F5: Composition**************************************************************************;

program define f5_race;
syntax  [if] [in]  [pweight/] [using/] [,table(string) Market(varname) Disposable(varname) race1(varname) race2(varname) race3(varname) race4(varname) race5(varname) OPEN
			PL125(string)
			PL250(string)
			PL400(string)];
di "Composition `'";
local sheet="F5. Composition";
local version 1.0;
local command ceqrace;
local versionprint ("Results produced by version `version' of `command' on `c(current_date)' at `c(current_time)'");


   *if `"`weight'"' != "" {;
   *             local wght `"[`weight'`exp']"';
    *    };
	#delimit cr
	cap svydes
	scalar no_svydes = _rc
	tempvar ones
	gen `ones'=1
	if !_rc qui svyset // gets the results saved in return list
	if "`r(wvar)'"=="" & "`exp'"=="" {
		`dit' "Warning: weights not specified in svydes or the command"
		`dit' "Hence, equal weights (simple random sample) assumed"
	}
	else {
		if "`exp'"=="" & "`r(wvar)'"!="" local w `r(wvar)'
		if "`exp'"!="" local w `exp'
		if "`w'"!="" {
			tempvar weightvar
			qui gen `weightvar' = `w'
			local w `weightvar'
		}
		else local w "`ones'"
		
		if "`w'"!="" {
			local pw "[pw = `w']"
			local aw "[aw = `w']"
		}
		if "`exp'"=="" & "`r(wvar)'"!="" {
			local weight "pw"
			local exp "`r(wvar)'"
		}
	}		
	
	#delimit;
		forvalues x=1/5{;
	if "`race`x''"==""{;
		local cc=`cc'+1;
		tempvar race`x';
		gen `race`x''=.;
		};
	};

	****Poverty variables****;
	if "`table'"=="f5"{;
		if "`market'"=="" {;
		display as error "Must specify Market(varname) option";
		exit;
		};
		if "`disposable'"=="" {;
		display as error "Must specify Disposable(varname) option";
		exit;
		};
		
		if "`pl125'"=="" | "`pl250'"=="" | "`pl400'"=="" {;
		display as error "Must specify Poverty lines for 1.25, 2.50 and 4.00 PPP";
		exit;
		};
		
		local pl1000=`pl250'*4;
		local pl5000=`pl250'*20;
		
		tempvar g_m;
	gen `g_m'=. ;
	replace `g_m'=1 if `market'<`pl125';
	replace `g_m'=2 if `market'>=`pl125' & `market'<`pl250';
	replace `g_m'=3 if `market'>=`pl250' & `market'<`pl400';
	replace `g_m'=4 if `market'>=`pl400' & `market'<`pl1000';
	replace `g_m'=5 if `market'>=`pl1000' & `market'<`pl5000';
	replace `g_m'=6 if `market'>=`pl5000';


	tempvar d_m;
	xtile `d_m'= `market' `wght',nq(10);
	
	tempvar g_d;
	gen `g_d'=. ;
	replace `g_d'=1 if `disposable'<`pl125';
	replace `g_d'=2 if `disposable'>=`pl125' & `disposable'<`pl250';
	replace `g_d'=3 if `disposable'>=`pl250' & `disposable'<`pl400';
	replace `g_d'=4 if `disposable'>=`pl400' & `disposable'<`pl1000';
	replace `g_d'=5 if `disposable'>=`pl1000' & `disposable'<`pl5000';
	replace `g_d'=6 if `disposable'>=`pl5000';


	tempvar d_d;
	xtile `d_d'= `disposable' `wght',nq(10);
	};
	qui{;
		matrix f5_1=J(10,5,.);
		matrix f5_2=J(6,5,.);
		matrix colnames f5_1=race1 race2 race3 race4 race5;
		matrix colnames f5_2=race1 race2 race3 race4 race5;
		matrix rownames f5_1=d1 d2 d3 d4 d5 d6 d7 d8 d9 d10;
		matrix rownames f5_2=y125 y250 y4 y10 y50 ym50;
		
		matrix f5_3=J(10,5,.);
		matrix f5_4=J(6,5,.);
		matrix colnames f5_3=race1 race2 race3 race4 race5;
		matrix colnames f5_4=race1 race2 race3 race4 race5;
		matrix rownames f5_3=d1 d2 d3 d4 d5 d6 d7 d8 d9 d10;
		matrix rownames f5_4=y125 y250 y4 y10 y50 ym50;

		forvalues x=1/5{;
			forvalues y=1/10{;

				summ `race`x'' `wght' if `d_m'==`y';
				matrix f5_1[`y',`x']=round(r(sum));
				summ `race`x'' `wght' if `d_d'==`y';
				matrix f5_3[`y',`x']=round(r(sum));
				};

			forvalues y=1/6{;

				summ `race`x'' `wght' if `g_m'==`y';
				matrix f5_2[`y',`x']=round(r(sum));
				summ `race`x'' `wght' if `g_d'==`y';
				matrix f5_4[`y',`x']=round(r(sum));
				};
			};
		noisily di "Population by decile (Market income)";
		noisily matrix list f5_1;
		noisily di "Population by socioeconomic group (Market income)";
		noisily matrix list f5_2;
		noisily di "Population by decile (Disposable income)";
		noisily matrix list f5_3;
		noisily di "Population by socioeconomic group (Disposable income)";
		noisily matrix list f5_3;
		putexcel C11=matrix(f5_1) using `using', modify sheet("`sheet'") keepcellformat;
		putexcel C27=matrix(f5_2) using `using', modify sheet("`sheet'") keepcellformat;
		putexcel C42=matrix(f5_3) using `using', modify sheet("`sheet'") keepcellformat;
		putexcel C58=matrix(f5_4) using `using', modify sheet("`sheet'") keepcellformat;
		putexcel A3=`versionprint' using `using', modify sheet("`sheet'") keepcellformat;
	
	********
	* OPEN *
	********;
	if "`open'"!="" {;
		!start `using'; // doesn't work with "" or `""' so I already changed `open' to "" if using has spaces, ;
	};
	};
end;

*******TABLE F6: Distribution**************************************************************************;

program define f6_race;
syntax  [if] [in] [pweight/] [using/] [,table(string) Market(varname) Disposable(varname)  race1(varname) race2(varname) race3(varname) race4(varname) race5(varname) OPEN
			PL125(string)
			PL250(string)
			PL400(string)];
	di "Distribution `'";
	local sheet="F6. Distribution";
	local version 1.0;
local command ceqrace;
local versionprint ("Results produced by version `version' of `command' on `c(current_date)' at `c(current_time)'");

	 *if `"`weight'"' != "" {;
   *             local wght `"[`weight'`exp']"';
    *    };
	#delimit cr
	cap svydes
	scalar no_svydes = _rc
	tempvar ones
	gen `ones'=1
	if !_rc qui svyset // gets the results saved in return list
	if "`r(wvar)'"=="" & "`exp'"=="" {
		`dit' "Warning: weights not specified in svydes or the command"
		`dit' "Hence, equal weights (simple random sample) assumed"
	}
	else {
		if "`exp'"=="" & "`r(wvar)'"!="" local w `r(wvar)'
		if "`exp'"!="" local w `exp'
		if "`w'"!="" {
			tempvar weightvar
			qui gen `weightvar' = `w'
			local w `weightvar'
		}
		else local w "`ones'"
		
		if "`w'"!="" {
			local pw "[pw = `w']"
			local aw "[aw = `w']"
		}
		if "`exp'"=="" & "`r(wvar)'"!="" {
			local weight "pw"
			local exp "`r(wvar)'"
		}
	}		
	
	#delimit;
	forvalues x=1/5{;
		if "`race`x''"==""{;
			local cc=`cc'+1;
			tempvar race`x';
			gen `race`x''=.;
		};
	};
****Poverty variables****;

		if "`market'"=="" {;
			display as error "Must specify Market(varname) option";
			exit;
		};
		if "`disposable'"=="" {;
			display as error "Must specify Disposable(varname) option";
			exit;
		};
		if "`pl125'"=="" | "`pl250'"=="" | "`pl400'"=="" {;
			display as error "Must specify Poverty lines for 1.25, 2.50 and 4.00 PPP";
			exit;
		};
		
		local pl1000=`pl250'*4;
		local pl5000=`pl250'*20;
	tempvar g3_m;
	gen `g3_m'=. ;
	replace `g3_m'=1 if `market'<`pl125';
	replace `g3_m'=2 if `market'>=`pl125' & `market'<`pl250';
	replace `g3_m'=3 if `market'>=`pl250' & `market'<`pl400';
	replace `g3_m'=4 if `market'>=`pl400' & `market'<`pl1000';
	replace `g3_m'=5 if `market'>=`pl1000' & `market'<`pl5000';
	replace `g3_m'=6 if `market'>=`pl5000';

	tempvar g3_d;
	gen `g3_d'=. ;
	replace `g3_d'=1 if `disposable'<`pl125';
	replace `g3_d'=2 if `disposable'>=`pl125' & `disposable'<`pl250';
	replace `g3_d'=3 if `disposable'>=`pl250' & `disposable'<`pl400';
	replace `g3_d'=4 if `disposable'>=`pl400' & `disposable'<`pl1000';
	replace `g3_d'=5 if `disposable'>=`pl1000' & `disposable'<`pl5000';
	replace `g3_d'=6 if `disposable'>=`pl5000';
	
	tempvar d3_m;
	*quantiles  `market' `wght', gen(`d3_m') n(10) ;
	xtile `d3_m'= `market' `wght',nq(10);

	tempvar d3_d;
	*quantiles  `market' `wght', gen(`d3_d') n(10) ;
	xtile `d3_d'= `disposable' `wght',nq(10);
	
	qui{;
		matrix f6_1=J(10,5,.);
		matrix f6_2=J(6,5,.);
		matrix colnames f6_1=race1 race2 race3 race4 race5;
		matrix colnames f6_2=race1 race2 race3 race4 race5;
		matrix rownames f6_1=d1 d2 d3 d4 d5 d6 d7 d8 d9 d10;
		matrix rownames f6_2=y125 y250 y4 y10 y50 ym50;

		matrix f6_3=J(10,5,.);
		matrix f6_4=J(6,5,.);
		matrix colnames f6_3=race1 race2 race3 race4 race5;
		matrix colnames f6_4=race1 race2 race3 race4 race5;
		matrix rownames f6_3=d1 d2 d3 d4 d5 d6 d7 d8 d9 d10;
		matrix rownames f6_4=y125 y250 y4 y10 y50 ym50;
		
		forvalues x=1/5{;
			forvalues y=1/10{;

				summ `market' `wght' if `d3_m'==`y' & `race`x''==1;
				matrix f6_1[`y',`x']=r(sum);
				
				summ `disposable' `wght' if `d3_d'==`y' & `race`x''==1;
				matrix f6_3[`y',`x']=r(sum);

			};

			forvalues y=1/6{;

				summ `market' `wght' if `g3_m'==`y' & `race`x''==1;
				matrix f6_2[`y',`x']=r(sum);

				summ `disposable' `wght' if `g3_d'==`y' & `race`x''==1;
				matrix f6_4[`y',`x']=r(sum);
			
			};
		};
		noisily di "Income by decile (Market Income)";
		noisily matrix list f6_1;
		noisily di "Income by socioeconomic group (Market Income)";
		noisily matrix list f6_2;
		noisily di "Income by decile (Disposable Income)";
		noisily matrix list f6_3;
		noisily di "Income by socioeconomic group (Disposable Income)";
		noisily matrix list f6_4;
		
		putexcel C11=matrix(f6_1) using `using', modify sheet("`sheet'") keepcellformat;
		putexcel C27=matrix(f6_2) using `using', modify sheet("`sheet'") keepcellformat;
		putexcel C41=matrix(f6_3) using `using', modify sheet("`sheet'") keepcellformat;
		putexcel C57=matrix(f6_4) using `using', modify sheet("`sheet'") keepcellformat;
		putexcel A3=`versionprint' using `using', modify sheet("`sheet'") keepcellformat;
	********
	* OPEN *
	********;
	if "`open'"!="" {;
		!start `using'; // doesn't work with "" or `""' so I already changed `open' to "" if using has spaces, ;
	};
	};
end;

*******TABLE F7: Poverty**************************************************************************;

program define f7_race;
syntax  [if] [in] [pweight/] [using/] [,table(string) Market(varname) race1(varname) race2(varname) race3(varname) race4(varname) race5(varname) OPEN 
		   Netmarket(varname) 
		   MPLUSPensions(varname)
		   Gross(varname)
		   TAXABle(varname)
		   Disposable(varname) 
		   Postfiscal(varname) 
		   FStar(varname)
		   Consumable(varname)
		   Final(varname) 
		   
		   PL250(string)
			PL400(string)
		   NEXTreme(string)
		   NMODerate(string)];
	di "Poverty `'";
	local sheet="F7. Poverty";
	local version 1.0;
local command ceqrace;
local versionprint ("Results produced by version `version' of `command' on `c(current_date)' at `c(current_time)'");

	 *if `"`weight'"' != "" {;
   *             local wght `"[`weight'`exp']"';
    *    };
	#delimit cr
	cap svydes
	scalar no_svydes = _rc
	tempvar ones
	gen `ones'=1
	if !_rc qui svyset // gets the results saved in return list
	if "`r(wvar)'"=="" & "`exp'"=="" {
		`dit' "Warning: weights not specified in svydes or the command"
		`dit' "Hence, equal weights (simple random sample) assumed"
	}
	else {
		if "`exp'"=="" & "`r(wvar)'"!="" local w `r(wvar)'
		if "`exp'"!="" local w `exp'
		if "`w'"!="" {
			tempvar weightvar
			qui gen `weightvar' = `w'
			local w `weightvar'
		}
		else local w "`ones'"
		
		if "`w'"!="" {
			local pw "[pw = `w']"
			local aw "[aw = `w']"
		}
		if "`exp'"=="" & "`r(wvar)'"!="" {
			local weight "pw"
			local exp "`r(wvar)'"
		}
	}		
	
	#delimit;
		forvalues x=1/5{;
			if "`race`x''"==""{;
				local cc=`cc'+1;
				tempvar race`x';
				gen `race`x''=.;
			};
		};
****Poverty variables****;

	if "`market'"=="" {;
		display as error "Must specify Market(varname) option";
		exit;
	};
if  "`pl250'"=="" | "`pl400'"=="" | "`nextreme'"==""  | "`nmoderate'"==""{;
			display as error "Must specify Poverty lines for 1.25, 2.50 and 4.00 PPP";
			exit;
		};
		
		
	local p1=`pl250';
	local p2=`pl400';
	local p3=`nextreme'*30;
	local p4=`nmoderate'*30;

	local incomes `market' `mpluspensions' `netmarket' `gross' `taxable' `disposable' `consumable' `final';
	local lines `p1' `p2' `p3' `p4';

	di `incomes';
	

	qui{;
		matrix f7_1=J(4,8,.);
		matrix f7_2=J(4,8,.);
		matrix f7_3=J(4,8,.);
		matrix f7_4=J(4,8,.);
		matrix colnames f7_1=market mpluspensions netmarket gross taxable disposable consumable final;
		matrix colnames f7_2=market mpluspensions netmarket gross taxable disposable consumable final;
		matrix colnames f7_3=market mpluspensions netmarket gross taxable disposable consumable final;
		matrix colnames f7_4=market mpluspensions netmarket gross taxable disposable consumable final;
		matrix rownames f7_1=indig white afro national;
		matrix rownames f7_2=indig white afro national;
		matrix rownames f7_3=indig white afro national;
		matrix rownames f7_4=indig white afro national;
		
		forvalues z=1/4{;//poverty lines;
			local c=0;
			
			foreach y in `incomes'{;
				local c=`c'+1;
					forvalues x=1/3{;
						tempvar pov`z'_`y';
						gen `pov`z'_`y''=cond(`y'<`p`z'',1,0);

						summ `pov`z'_`y'' `wght' if `race`x''==1;
						matrix f7_`z'[`x',`c']=r(mean);
					};
				tempvar pov`z'_`y';
				gen `pov`z'_`y''=cond(`y'<`p`z'',1,0);

				summ `pov`z'_`y'' `wght';
				matrix f7_`z'[4,`c']=r(mean);

			};
		};
		noisily di "Extreme Poverty";
		noisily matrix list f7_1;
		noisily di "Moderate Poverty";
		noisily matrix list f7_2;
		noisily di "National Extreme Poverty";
		noisily matrix list f7_3;
		noisily di "National Moderate Poverty";
		noisily matrix list f7_3;

		putexcel C7=matrix(f7_1) using `using', modify sheet("`sheet'") keepcellformat;
		putexcel C21=matrix(f7_2) using `using', modify sheet("`sheet'") keepcellformat;
		putexcel C35=matrix(f7_3) using `using', modify sheet("`sheet'") keepcellformat;
		putexcel C49=matrix(f7_4) using `using', modify sheet("`sheet'") keepcellformat;
		putexcel A3=`versionprint' using `using', modify sheet("`sheet'") keepcellformat;
	********
	* OPEN *
	********;
	if "`open'"!="" {;
		!start `using'; // doesn't work with "" or `""' so I already changed `open' to "" if using has spaces, ;
	};
	};
end;
*******TABLE F8: Poverty Gap**************************************************************************;

program define f8_race;
syntax  [if] [in] [pweight/] [using/] [,table(string) Market(varname) race1(varname) race2(varname) race3(varname) race4(varname) race5(varname) OPEN 
		   Netmarket(varname) 
		   MPLUSPensions(varname)
		   Gross(varname)
		   TAXABle(varname)
		   Disposable(varname) 
		   Postfiscal(varname) 
		   FStar(varname)
		   Consumable(varname)
		   Final(varname) 
			PL250(string)
			PL400(string)
		   NEXTreme(string)
		   NMODerate(string)];
	di "Poverty Gap`'";
	local sheet="F8. Poverty Gap";
	local version 1.0;
local command ceqrace;
local versionprint ("Results produced by version `version' of `command' on `c(current_date)' at `c(current_time)'");

	 *if `"`weight'"' != "" {;
   *             local wght `"[`weight'`exp']"';
    *    };
	#delimit cr
	cap svydes
	scalar no_svydes = _rc
	tempvar ones
	gen `ones'=1
	if !_rc qui svyset // gets the results saved in return list
	if "`r(wvar)'"=="" & "`exp'"=="" {
		`dit' "Warning: weights not specified in svydes or the command"
		`dit' "Hence, equal weights (simple random sample) assumed"
	}
	else {
		if "`exp'"=="" & "`r(wvar)'"!="" local w `r(wvar)'
		if "`exp'"!="" local w `exp'
		if "`w'"!="" {
			tempvar weightvar
			qui gen `weightvar' = `w'
			local w `weightvar'
		}
		else local w "`ones'"
		
		if "`w'"!="" {
			local pw "[pw = `w']"
			local aw "[aw = `w']"
		}
		if "`exp'"=="" & "`r(wvar)'"!="" {
			local weight "pw"
			local exp "`r(wvar)'"
		}
	}		
	
	#delimit;
	forvalues x=1/5{;
		if "`race`x''"==""{;
		local cc=`cc'+1;
		tempvar race`x';
		gen `race`x''=.;
		};
	};

	****Poverty variables****;

	if "`market'"=="" {;
		display as error "Must specify Market(varname) option";
		exit;
	};

	local p1=`pl250';
	local p2=`pl400';
	local p3=`nextreme'*30;
	local p4=`nmoderate'*30;
	local incomes `market' `mpluspensions' `netmarket' `gross' `taxable' `disposable' `consumable' `final';
	local lines `p1' `p2' `p3' `p4';

	di `incomes';

	qui{;
		matrix f8_1=J(4,8,.);
		matrix f8_2=J(4,8,.);
		matrix f8_3=J(4,8,.);
		matrix f8_4=J(4,8,.);
		matrix colnames f8_1=market mpluspensions netmarket gross taxable disposable consumable final;
		matrix colnames f8_2=market mpluspensions netmarket gross taxable disposable consumable final;
		matrix colnames f8_3=market mpluspensions netmarket gross taxable disposable consumable final;
		matrix colnames f8_4=market mpluspensions netmarket gross taxable disposable consumable final;
		matrix rownames f8_1=indig white afro national;
		matrix rownames f8_2=indig white afro national;
		matrix rownames f8_3=indig white afro national;
		matrix rownames f8_4=indig white afro national;
		forvalues z=1/4{;
			local c=0;
			
			foreach y in `incomes'{;
				local c=`c'+1;
				
				forvalues x=1/3{;
					tempvar gap`z'_`y';
					gen `gap`z'_`y''=0;
					replace `gap`z'_`y''=(`p`z''-`y')/`p`z'' if `race`x''==1 & `y'<`p`z'';

					summ `gap`z'_`y'' `wght' if `race`x''==1;
					matrix f8_`z'[`x',`c']=r(mean);
				};
				tempvar gap`z'_`y';
				gen `gap`z'_`y''=0;
				replace `gap`z'_`y''=(`p`z''-`y')/`p`z'' if `y'<`p`z'';

				summ `gap`z'_`y'' `wght';
				matrix f8_`z'[4,`c']=r(mean);

			};
		};
		noisily di "Extreme Poverty Gap";
		noisily matrix list f8_1;
		noisily di "Moderate Poverty Gap";
		noisily matrix list f8_2;
		noisily di "National Extreme Poverty Gap";
		noisily matrix list f8_3;
		noisily di "National Moderate Poverty Gap";
		noisily matrix list f8_3;

		putexcel C7=matrix(f8_1) using `using',keepcellformat modify sheet("`sheet'") ;
		putexcel C21=matrix(f8_2) using `using',keepcellformat modify sheet("`sheet'");
		putexcel C35=matrix(f8_3) using `using',keepcellformat modify sheet("`sheet'");
		putexcel C49=matrix(f8_4) using `using',keepcellformat modify sheet("`sheet'");
		putexcel A3=`versionprint' using `using', modify sheet("`sheet'") keepcellformat;

	********
	* OPEN *
	********;
	if "`open'"!="" {;
		!start `using'; // doesn't work with "" or `""' so I already changed `open' to "" if using has spaces, ;
	};
	};
end;

*******TABLE F9: Poverty Gap Squared**************************************************************************;

program define f9_race;
syntax  [if] [in] [pweight/] [using/] [,table(string) Market(varname) race1(varname) race2(varname) race3(varname) race4(varname) race5(varname) OPEN 
		   Netmarket(varname) 
		   MPLUSPensions(varname)
		   Gross(varname)
		   TAXABle(varname)
		   Disposable(varname) 
		   Postfiscal(varname) 
		   FStar(varname)
		   Consumable(varname)
		   Final(varname) 
		   	PL250(string)
			PL400(string)
		   NEXTreme(string)
		   NMODerate(string)];

	di "Poverty Gap Squared `'";
	local sheet="F9. Poverty Gap Sq.";
	local version 1.0;
local command ceqrace;
local versionprint ("Results produced by version `version' of `command' on `c(current_date)' at `c(current_time)'");

	 *if `"`weight'"' != "" {;
   *             local wght `"[`weight'`exp']"';
    *    };
	#delimit cr
	cap svydes
	scalar no_svydes = _rc
	tempvar ones
	gen `ones'=1
	if !_rc qui svyset // gets the results saved in return list
	if "`r(wvar)'"=="" & "`exp'"=="" {
		`dit' "Warning: weights not specified in svydes or the command"
		`dit' "Hence, equal weights (simple random sample) assumed"
	}
	else {
		if "`exp'"=="" & "`r(wvar)'"!="" local w `r(wvar)'
		if "`exp'"!="" local w `exp'
		if "`w'"!="" {
			tempvar weightvar
			qui gen `weightvar' = `w'
			local w `weightvar'
		}
		else local w "`ones'"
		
		if "`w'"!="" {
			local pw "[pw = `w']"
			local aw "[aw = `w']"
		}
		if "`exp'"=="" & "`r(wvar)'"!="" {
			local weight "pw"
			local exp "`r(wvar)'"
		}
	}		
	
	#delimit;
	forvalues x=1/5{;
		if "`race`x''"==""{;
			local cc=`cc'+1;
			tempvar race`x';
			gen `race`x''=.;
		};
	};
****Poverty variables****;

	if "`market'"=="" {;
		display as error "Must specify Market(varname) option";
		exit;
	};

	local p1=`pl250';
	local p2=`pl400';
	local p3=`nextreme'*30;
	local p4=`nmoderate'*30;

	local incomes `market' `mpluspensions' `netmarket' `gross' `taxable' `disposable' `consumable' `final';
	local lines `p1' `p2' `p3' `p4';

	di `incomes';

	qui{;
		matrix f9_1=J(4,8,.);
		matrix f9_2=J(4,8,.);
		matrix f9_3=J(4,8,.);
		matrix f9_4=J(4,8,.);
		matrix colnames f9_1=market mpluspensions netmarket gross taxable disposable consumable final;
		matrix colnames f9_2=market mpluspensions netmarket gross taxable disposable consumable final;
		matrix colnames f9_3=market mpluspensions netmarket gross taxable disposable consumable final;
		matrix colnames f9_4=market mpluspensions netmarket gross taxable disposable consumable final;
		matrix rownames f9_1=indig white afro national;
		matrix rownames f9_2=indig white afro national;
		matrix rownames f9_3=indig white afro national;
		matrix rownames f9_4=indig white afro national;
			
		forvalues z=1/4{;
			local c=0;
			
			foreach y in `incomes'{;
				local c=`c'+1;
				
				forvalues x=1/3{;
					tempvar gap2`z'_`y';
					gen `gap2`z'_`y''=0;
					replace `gap2`z'_`y''=((`p`z''-`y')/`p`z'')^2 if `race`x''==1 & `y'<`p`z'';

					summ `gap2`z'_`y'' `wght' if `race`x''==1;
					matrix f9_`z'[`x',`c']=r(mean);
				};
				tempvar gap2`z'_`y';
				gen `gap2`z'_`y''=0;
				replace `gap2`z'_`y''=((`p`z''-`y')/`p`z'')^2 if `y'<`p`z'';

				summ `gap2`z'_`y'' `wght';
				matrix f9_`z'[4,`c']=r(mean);

			};
		};
		noisily di "Extreme Poverty Gap";
		noisily matrix list f9_1;
		noisily di "Moderate Poverty Gap";
		noisily matrix list f9_2;
		noisily di "National Extreme Poverty Gap";
		noisily matrix list f9_3;
		noisily di "National Moderate Poverty Gap";
		noisily matrix list f9_3;

		putexcel C7=matrix(f9_1) using `using',keepcellformat modify sheet("`sheet'") ;
		putexcel C21=matrix(f9_2) using `using',keepcellformat modify sheet("`sheet'");
		putexcel C35=matrix(f9_3) using `using',keepcellformat modify sheet("`sheet'");
		putexcel C49=matrix(f9_4) using `using',keepcellformat modify sheet("`sheet'");
		putexcel A3=`versionprint' using `using', modify sheet("`sheet'") keepcellformat;
	********
	* OPEN *
	********;
	if "`open'"!="" {;
		!start `using'; // doesn't work with "" or `""' so I already changed `open' to "" if using has spaces, ;
	};
	};
end;
*******TABLE F10: Inequality**************************************************************************;

program define f10_race;
syntax  [if] [in] [pweight/] [using/] [,table(string) Market(varname) race1(varname) race2(varname) race3(varname) race4(varname) race5(varname) OPEN 
		    Netmarket(varname) 
		   MPLUSPensions(varname)
		   Gross(varname)
		   TAXABle(varname)
		   Disposable(varname) 
		   Postfiscal(varname) 
		   FStar(varname)
		   Consumable(varname)
		   Final(varname)  
		   psu(varname)   
		   strata(varname) 
		  ];
	di "Inequality `'";
	local sheet="F10. Inequality";
	local version 1.0;
	local command ceqrace;
	local versionprint ("Results produced by version `version' of `command' on `c(current_date)' at `c(current_time)'");

	
	 *if `"`weight'"' != "" {;
   *             local wght `"[`weight'`exp']"';
    *    };
	#delimit cr
	cap svydes
	scalar no_svydes = _rc
	tempvar ones
	gen `ones'=1
	if !_rc qui svyset // gets the results saved in return list
	if "`r(wvar)'"=="" & "`exp'"=="" {
		`dit' "Warning: weights not specified in svydes or the command"
		`dit' "Hence, equal weights (simple random sample) assumed"
	}
	else {
		if "`exp'"=="" & "`r(wvar)'"!="" local w `r(wvar)'
		if "`exp'"!="" local w `exp'
		if "`w'"!="" {
			tempvar weightvar
			qui gen `weightvar' = `w'
			local w `weightvar'
		}
		else local w "`ones'"
		
		if "`w'"!="" {
			local pw "[pw = `w']"
			local aw "[aw = `w']"
		}
		if "`exp'"=="" & "`r(wvar)'"!="" {
			local weight "pw"
			local exp "`r(wvar)'"
		}
	}		
	
	#delimit;
		
***Svy options;
	cap svydes;
	scalar no_svydes = (c(rc)!=0);
	qui svyset;
	if "`r(wvar)'"=="" & "`exp'"=="" {;
		di as text "WARNING: weights not specified in svydes or the ceqrace command";
		di as text "Hence, equal weights (simple random sample) assumed";
	};
	else if "`r(su1)'"=="" & "`psu'"=="" {;
		di as text "WARNING: primary sampling unit not specified in svydes or the ceqrace command's psu() option";
		di as text "P-values will be incorrect if sample was stratified";
	};
	if "`psu'"=="" & "`r(su1)'"!="" {;
		local psu `r(su1)';
	};
	if "`strata'"=="" & "`r(strata1)'"!="" {;
		local strata `r(strata1)';
	};
	if "`exp'"=="" & "`r(wvar)'"!="" {;
		local weight "pw";
		local exp "= `r(wvar)'";
	};
	if "`strata'"!="" {;
		local opt strata(`strata');
	};
	
	* now set it:;
	if "`exp'"!="" qui svyset `psu' `pw', `opt';
	else           qui svyset `psu', `opt';
		

	forvalues x=1/5{;
		if "`race`x''"==""{;
			local cc=`cc'+1;
			tempvar race`x';
			gen `race`x''=.;
		};
	};

	if "`market'"=="" {;
		display as error "Must specify Market(varname) option";
		exit;
	};


	local incomes `market' `mpluspensions' `netmarket' `gross' `taxable' `disposable' `consumable' `final';

	di `incomes';

	qui{;
	matrix f10_1=J(4,8,.);
	matrix f10_2=J(4,8,.);
	matrix f10_3=J(4,8,.);

	matrix colnames f10_1=market mpluspensions netmarket gross taxable disposable consumable final;
	matrix colnames f10_2=market mpluspensions netmarket gross taxable disposable consumable final;
	matrix colnames f10_3=market mpluspensions netmarket gross taxable disposable consumable final;
	matrix rownames f10_1=indig white afro national;
	matrix rownames f10_2=indig white afro national;
	matrix rownames f10_3=indig white afro national;
	
	forvalues z=1/3{;
		local c=0;
		
		foreach y in `incomes'{;
			local c=`c'+1;
			
			forvalues x=1/3{;
				if `z'==1{;
					digini `y' `market' ,cond1(`race`x'');
					matrix d`x'`y'`z'=e(d1);
					scalar r`x'`y'`z'=d`x'`y'`z'[1,1];
					matrix f10_`z'[`x',`c']=r`x'`y'`z';
				};
				
				if `z'==2{;
					dientropy `y' `market' , cond1(`race`x'') theta(1);
					matrix d`x'`y'`z'=e(d1);
					scalar r`x'`y'`z'=d`x'`y'`z'[1,1];
					matrix f10_`z'[`x',`c']=r`x'`y'`z';
				};
				
				if `z'==3{;
					dinineq `y' `market'  , p1(.9) p2(.1) cond1(`race`x'');
					matrix d`x'`y'`z'=e(d1);
					scalar r`x'`y'`z'=d`x'`y'`z'[1,1];
					matrix f10_`z'[`x',`c']=r`x'`y'`z';
				};
			};
				if `z'==1{;
					digini `y' `market'  ;
					matrix d`y'`z'=e(d1);
					scalar r`y'`z'=d`y'`z'[1,1];
					matrix f10_`z'[4,`c']=r`y'`z';
				};
				
				if `z'==2{;
					dientropy `y' `market'  , theta(1);
					matrix d`y'`z'=e(d1);
					scalar r`y'`z'=d`y'`z'[1,1];
					matrix f10_`z'[4,`c']=r`y'`z';
				};
				
				if `z'==3{;
					dinineq `y' `market' , p1(.9) p2(.1);
					matrix d`y'`z'=e(d1);
					scalar r`y'`z'=d`y'`z'[1,1];
					matrix f10_`z'[4,`c']=r`y'`z';
				};


			};
		};
		
		noisily di "Gini";
		noisily matrix list f10_1;
		noisily di "Theil";
		noisily matrix list f10_2;
		noisily di "90/10 Ratio";
		noisily matrix list f10_3;

		putexcel C7=matrix(f10_1) using `using',keepcellformat modify sheet("`sheet'") ;
		putexcel C21=matrix(f10_2) using `using',keepcellformat modify sheet("`sheet'");
		putexcel C35=matrix(f10_3) using `using',keepcellformat modify sheet("`sheet'");
		putexcel A3=`versionprint' using `using', modify sheet("`sheet'") keepcellformat;
	********
	* OPEN *
	********;
	if "`open'"!="" {;
		!start `using'; // doesn't work with "" or `""' so I already changed `open' to "" if using has spaces, ;
	};
	};
end;

*******TABLE F11: Mean income**************************************************************************;

program define f11_race;
syntax  [if] [in] [pweight/] [using/] [,table(string) Market(varname) race1(varname) race2(varname) race3(varname) race4(varname) race5(varname) OPEN 
		   Netmarket(varname) 
		   MPLUSPensions(varname)
		   Gross(varname)
		   TAXABle(varname)
		   Disposable(varname) 
		   Postfiscal(varname) 
		   FStar(varname)
		   Consumable(varname)
		   Final(varname) ];
	local sheet="F11. Mean Income";
	local version 1.0;
	local command ceqrace;
	local versionprint ("Results produced by version `version' of `command' on `c(current_date)' at `c(current_time)'");

	 *if `"`weight'"' != "" {;
   *             local wght `"[`weight'`exp']"';
    *    };
	#delimit cr
	cap svydes
	scalar no_svydes = _rc
	tempvar ones
	gen `ones'=1
	if !_rc qui svyset // gets the results saved in return list
	if "`r(wvar)'"=="" & "`exp'"=="" {
		`dit' "Warning: weights not specified in svydes or the command"
		`dit' "Hence, equal weights (simple random sample) assumed"
	}
	else {
		if "`exp'"=="" & "`r(wvar)'"!="" local w `r(wvar)'
		if "`exp'"!="" local w `exp'
		if "`w'"!="" {
			tempvar weightvar
			qui gen `weightvar' = `w'
			local w `weightvar'
		}
		else local w "`ones'"
		
		if "`w'"!="" {
			local pw "[pw = `w']"
			local aw "[aw = `w']"
		}
		if "`exp'"=="" & "`r(wvar)'"!="" {
			local weight "pw"
			local exp "`r(wvar)'"
		}
	}		
	
	#delimit;
		forvalues x=1/5{;
			if "`race`x''"==""{;
				local cc=`cc'+1;
				tempvar race`x';
				gen `race`x''=.;
			};
		};
****Income variables****;

	if "`market'"=="" {;
		display as error "Must specify Market(varname) option";
		exit;
	};


	local incomes `market' `mpluspensions' `netmarket' `gross' `taxable' `disposable' `consumable' `final';
	*di `incomes';


	qui{;
		matrix f11_1=J(4,8,.);
		matrix colnames f11_1=market mpluspensions netmarket gross taxable disposable consumable final;
		matrix rownames f11_1=indig white afro national;
		
		
		
		local c=0;
		
		foreach y in `incomes'{;
			local c=`c'+1;
			
			forvalues x=1/3{;
					summ `y' `wght' if `race`x''==1;
					matrix f11_1[`x',`c']=r(mean);
				};
				
					summ `y' `wght';
					matrix f11_1[4,`c']=r(mean);
			};	
	
		noisily di "Mean income in LCU";
		noisily matrix list f11_1;
		
		putexcel C7=matrix(f11_1) using `using', modify sheet("`sheet'") keepcellformat;
		putexcel A3=`versionprint' using `using', modify sheet("`sheet'") keepcellformat;
	********
	* OPEN *
	********;
	if "`open'"!="" {;
		!start `using'; // doesn't work with "" or `""' so I already changed `open' to "" if using has spaces, ;
	};		
	};
end;
*******TABLE F12: Incidence (decile)**************************************************************************;

program define f12_race;
syntax  [if] [in] [pweight/] [using/] [,table(string) Market(varname) race1(varname) race2(varname) race3(varname) race4(varname) race5(varname) OPEN 
		   Netmarket(varname) 
		   MPLUSPensions(varname)
		   Gross(varname)
		   TAXABle(varname)
		   Disposable(varname) 
		   Postfiscal(varname) 
		   FStar(varname)
		   Consumable(varname)
		   Final(varname) 
		   dtax(varname)
		   CONTributions(varname)
		   CONTPensions(varname)
		   CONYPensions(varname)
		   NONContributory(varname)
		   flagcct(varname)
		   OTRANsfers(varname)
		   ISUBsidies(varname)
		   itax(varname)
		   IKEducation(varname)
		   IKHealth(varname)
		   HUrban(varname)];
	di "Incidence (Decile) `'";
	local sheet="F12. Incidence (Decile)";
	local version 1.0;
	local command ceqrace;
	local versionprint ("Results produced by version `version' of `command' on `c(current_date)' at `c(current_time)'");

	
	qui{;
	
	 *if `"`weight'"' != "" {;
   *             local wght `"[`weight'`exp']"';
    *    };
	#delimit cr
	cap svydes
	scalar no_svydes = _rc
	tempvar ones
	gen `ones'=1
	if !_rc qui svyset // gets the results saved in return list
	if "`r(wvar)'"=="" & "`exp'"=="" {
		`dit' "Warning: weights not specified in svydes or the command"
		`dit' "Hence, equal weights (simple random sample) assumed"
	}
	else {
		if "`exp'"=="" & "`r(wvar)'"!="" local w `r(wvar)'
		if "`exp'"!="" local w `exp'
		if "`w'"!="" {
			tempvar weightvar
			qui gen `weightvar' = `w'
			local w `weightvar'
		}
		else local w "`ones'"
		
		if "`w'"!="" {
			local pw "[pw = `w']"
			local aw "[aw = `w']"
		}
		if "`exp'"=="" & "`r(wvar)'"!="" {
			local weight "pw"
			local exp "`r(wvar)'"
		}
	}		
	
	#delimit;
	
	forvalues x=1/5{;
		if "`race`x''"==""{;
			local cc=`cc'+1;
			tempvar race`x';
			gen `race`x''=.;
		};
	}; 

	if "`market'"=="" {;
		display as error "Must specify Market(varname) option";
		exit;
	};

	foreach x in market contpensions conypensions dtax contributions  netmarket noncontributory  flagcct otransfers gross taxable disposable isubsidies itax consumable ikeducation ikhealth hurban final{;
		if "``x''"==""{;
			tempvar `x';
			gen ``x''=.;
		};
	};

	local vlist1  `market' `contpensions' `conypensions';
	local vlist2  `dtax' `contributions' ;
	local vlist3  `netmarket' `noncontributory' `flagcct' `otransfers' ;
	local vlist4  `gross' `taxable' `disposable' `isubsidies' `itax'  
	local vlist5  `consumable' `ikeducation' `ikhealth' `hurban';
	local vlist6  `final'; 
		   
 
	qui{;
		forvalues x=1/6{;
			matrix f12_`x'_1=J(10,3,.);
			matrix colnames f12_`x'_1=market contpensions conypensions;
			matrix rownames f12_`x'_1=d1 d2 d3 d4 d5 d6 d7 d8 d9 d10;
			matrix f12_`x'_2=J(10,2,.);
			matrix colnames f12_`x'_2=dtax cont;
			matrix rownames f12_`x'_2=d1 d2 d3 d4 d5 d6 d7 d8 d9 d10;
			matrix f12_`x'_3=J(10,4,.);
			matrix colnames f12_`x'_3=netmarket nonc fcct otran;
			matrix rownames f12_`x'_3=d1 d2 d3 d4 d5 d6 d7 d8 d9 d10;

			matrix f12_`x'_4=J(10,5,.);
			matrix colnames f12_`x'_4=gross taxable disposable isub itax;
			matrix rownames f12_`x'_4=d1 d2 d3 d4 d5 d6 d7 d8 d9 d10;
			matrix f12_`x'_5=J(10,4,.);
			matrix colnames f12_`x'_5=consumable ike ikh hurban;
			matrix rownames f12_`x'_5=d1 d2 d3 d4 d5 d6 d7 d8 d9 d10;
			matrix f12_`x'_6=J(10,1,.);
			matrix colnames f12_`x'_6= final;
			matrix rownames f12_`x'_6=d1 d2 d3 d4 d5 d6 d7 d8 d9 d10;
		};

		tempvar race6;
		gen `race6'=1;
		forvalues z=1/6{;
			sum `market' if `race`z''==1;
			
			if r(N)!=0{;
				tempvar d_m;
				xtile `d_m'= `market' `wght',nq(10); 
				};
			else{;
				tempvar d_m;
				gen `d_m'=.;
			};

			forvalues y=1/6{;
				local c=0;
					
					foreach x in `vlist`y''{;
						local c=`c'+1;
							
							forvalues w=1/10{;
								sum `x' `wght' if `race`z''==1 & `d_m'==`w';
									matrix f12_`z'_`y'[`w',`c']=r(sum);

			};};};};};
			
		forvalues x=1/6{;
			noisily di "Incidence by decile `race`x''";
			noisily matrix list f12_`x'_1;
			noisily matrix list f12_`x'_2;
			noisily matrix list f12_`x'_3;
			noisily matrix list f12_`x'_4;
			noisily matrix list f12_`x'_5;
			noisily matrix list f12_`x'_6;
		};

	*National;
	putexcel D9=matrix(f12_6_1) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel I9=matrix(f12_6_2) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel L9=matrix(f12_6_3) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel Q9=matrix(f12_6_4) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel W9=matrix(f12_6_5) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel AF9=matrix(f12_6_6) using `using',keepcellformat modify sheet("`sheet'") ;

	*Indigenous;
	putexcel D25=matrix(f12_1_1) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel I25=matrix(f12_1_2) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel L25=matrix(f12_1_3) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel Q25=matrix(f12_1_4) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel W25=matrix(f12_1_5) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel AF25=matrix(f12_1_6) using `using',keepcellformat modify sheet("`sheet'") ;
		
	*White/Non-Ethnic;
	putexcel D41=matrix(f12_2_1) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel I41=matrix(f12_2_2) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel L41=matrix(f12_2_3) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel Q41=matrix(f12_2_4) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel W41=matrix(f12_2_5) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel AF41=matrix(f12_2_6) using `using',keepcellformat modify sheet("`sheet'") ;

	*African Descendant;
	putexcel D57=matrix(f12_3_1) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel I57=matrix(f12_3_2) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel L57=matrix(f12_3_3) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel Q57=matrix(f12_3_4) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel W57=matrix(f12_3_5) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel AF57=matrix(f12_3_6) using `using',keepcellformat modify sheet("`sheet'") ;

	
	*Others;
	putexcel D73=matrix(f12_4_1) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel I73=matrix(f12_4_2) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel L73=matrix(f12_4_3) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel Q73=matrix(f12_4_4) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel W73=matrix(f12_4_5) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel AF73=matrix(f12_4_6) using `using',keepcellformat modify sheet("`sheet'") ;


	*Non-responses;
	putexcel D89=matrix(f12_5_1) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel I89=matrix(f12_5_2) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel L89=matrix(f12_5_3) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel Q89=matrix(f12_5_4) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel W89=matrix(f12_5_5) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel AF89=matrix(f12_5_6) using `using',keepcellformat modify sheet("`sheet'") ;
	
	putexcel A3=`versionprint' using `using', modify sheet("`sheet'") keepcellformat;
	********
	* OPEN *
	********;
	if "`open'"!="" {;
		!start `using'; // doesn't work with "" or `""' so I already changed `open' to "" if using has spaces, ;
	};
	};
end;


*******TABLE 10: Incidence (Income Groups)**************************************************************************;

program define f13_race;
syntax  [if] [in] [pweight/] [using/] [,table(string) Market(varname) race1(varname) race2(varname) race3(varname) race4(varname) race5(varname) OPEN 
		     Netmarket(varname) 
		   MPLUSPensions(varname)
		   Gross(varname)
		   TAXABle(varname)
		   Disposable(varname) 
		   Postfiscal(varname) 
		   FStar(varname)
		   Consumable(varname)
		   Final(varname) 
		   dtax(varname)
		   CONTributions(varname)
		   CONTPensions(varname)
		   CONYPensions(varname)
		   NONContributory(varname)
		   flagcct(varname)
		   OTRANsfers(varname)
		   ISUBsidies(varname)
		   itax(varname)
		   IKEducation(varname)
		   IKHealth(varname)
		   HUrban(varname)];
	di "Incidence (Income groups) `'";
	local sheet="F13. Incidence (Income groups)";
	local version 1.0;
	local command ceqrace;
	local versionprint ("Results produced by version `version' of `command' on `c(current_date)' at `c(current_time)'");

	qui{;
		 *if `"`weight'"' != "" {;
   *             local wght `"[`weight'`exp']"';
    *    };
	#delimit cr
	cap svydes
	scalar no_svydes = _rc
	tempvar ones
	gen `ones'=1
	if !_rc qui svyset // gets the results saved in return list
	if "`r(wvar)'"=="" & "`exp'"=="" {
		`dit' "Warning: weights not specified in svydes or the command"
		`dit' "Hence, equal weights (simple random sample) assumed"
	}
	else {
		if "`exp'"=="" & "`r(wvar)'"!="" local w `r(wvar)'
		if "`exp'"!="" local w `exp'
		if "`w'"!="" {
			tempvar weightvar
			qui gen `weightvar' = `w'
			local w `weightvar'
		}
		else local w "`ones'"
		
		if "`w'"!="" {
			local pw "[pw = `w']"
			local aw "[aw = `w']"
		}
		if "`exp'"=="" & "`r(wvar)'"!="" {
			local weight "pw"
			local exp "`r(wvar)'"
		}
	}		
	
	#delimit;
		
		forvalues x=1/5{;
			if "`race`x''"==""{;
				local cc=`cc'+1;
				tempvar race`x';
				gen `race`x''=.;
			};
		}; 
		if "`market'"=="" {;
			display as error "Must specify Market(varname) option";
			exit;
		};

	foreach x in market contpensions conypensions dtax contributions  netmarket noncontributory  flagcct otransfers gross taxable disposable isubsidies itax consumable ikeducation ikhealth hurban final{;
			if "``x''"==""{;
				tempvar `x';
				gen ``x''=.;
			};
		};

			if "`pl125'"=="" | "`pl250'"=="" | "`pl400'"=="" {;
			display as error "Must specify Poverty lines for 1.25, 2.50 and 4.00 PPP";
			exit;
		};
		
		local pl1000=`pl250'*4;
		local pl5000=`pl250'*20;
		local vlist1  `market' `contpensions' `conypensions';
		local vlist2  `dtax' `contributions' ;
		local vlist3  `netmarket' `noncontributory' `flagcct' `otransfers' ;
		local vlist4  `gross' `taxable' `disposable' `isubsidies' `itax'  
		local vlist5  `consumable' `ikeducation' `ikhealth' `hurban';
		local vlist6  `final'; 
		
		tempvar g_m;
		gen `g_m'=. ;
		replace `g_m'=1 if `market'<`pl125';
		replace `g_m'=2 if `market'>=`pl125' & `market'<`pl250';
		replace `g_m'=3 if `market'>=`pl250' & `market'<`pl400';
		replace `g_m'=4 if `market'>=`pl400' & `market'<`pl1000';
		replace `g_m'=5 if `market'>=`pl1000' & `market'<`pl5000';
		replace `g_m'=6 if `market'>=`pl5000';

		   
 
	qui{;
		forvalues x=1/6{;
			matrix f13_`x'_1=J(6,3,.);
			matrix colnames f13_`x'_1=market contpensions conypensions;
			matrix rownames f13_`x'_1=y125 y250 y4 y10 y50 ym50;
			matrix f13_`x'_2=J(6,2,.);
			matrix colnames f13_`x'_2=dtax cont;
			matrix rownames f13_`x'_2=y125 y250 y4 y10 y50 ym50;
			matrix f13_`x'_3=J(6,4,.);
			matrix colnames f13_`x'_3=netmarket nonc fcct otran;
			matrix rownames f13_`x'_3=y125 y250 y4 y10 y50 ym50;

			matrix f13_`x'_4=J(6,5,.);
			matrix colnames f13_`x'_4=gross taxable disposable isub itax;
			matrix rownames f13_`x'_4=y125 y250 y4 y10 y50 ym50;
			matrix f13_`x'_5=J(6,4,.);
			matrix colnames f13_`x'_5=consumable ike ikh hurban;
			matrix rownames f13_`x'_5=y125 y250 y4 y10 y50 ym50;
			matrix f13_`x'_6=J(6,1,.);
			matrix colnames f13_`x'_6= final;
			matrix rownames f13_`x'_6=y125 y250 y4 y10 y50 ym50;

		};

		tempvar race6;
		gen `race6'=1;
		
		forvalues z=1/6{;

			forvalues y=1/6{;
				local c=0;
				
				foreach x in `vlist`y''{;
					local c=`c'+1;
					
					forvalues w=1/6{;
						sum `x' `wght' if `race`z''==1 & `g_m'==`w';
						matrix t10_`z'_`y'[`w',`c']=r(sum);

};};};};};

		forvalues x=1/6{;
			noisily di "Incidence by Socioeconomic Group `race`x''";
			noisily matrix list f13_`x'_1;
			noisily matrix list f13_`x'_2;
			noisily matrix list f13_`x'_3;
			noisily matrix list f13_`x'_4;
			noisily matrix list f13_`x'_5;
		};

*National;
	putexcel D10=matrix(f13_6_1) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel I10=matrix(f13_6_2) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel L10=matrix(f13_6_3) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel Q10=matrix(f13_6_4) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel W10=matrix(f13_6_5) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel AF10=matrix(f13_6_6) using `using',keepcellformat modify sheet("`sheet'") ;

	*Indigenous;
	putexcel D24=matrix(f13_1_1) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel I24=matrix(f13_1_2) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel L24=matrix(f13_1_3) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel Q24=matrix(f13_1_4) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel W24=matrix(f13_1_5) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel AF24=matrix(f13_1_6) using `using',keepcellformat modify sheet("`sheet'") ;
		
	*White/Non-Ethnic;
	putexcel D38=matrix(f13_2_1) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel I38=matrix(f13_2_2) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel L38=matrix(f13_2_3) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel Q38=matrix(f13_2_4) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel W38=matrix(f13_2_5) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel AF38=matrix(f13_2_6) using `using',keepcellformat modify sheet("`sheet'") ;

	*African Descendant;
	putexcel D52=matrix(f13_3_1) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel I52=matrix(f13_3_2) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel L52=matrix(f13_3_3) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel Q52=matrix(f13_3_4) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel W52=matrix(f13_3_5) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel AF52=matrix(f13_3_6) using `using',keepcellformat modify sheet("`sheet'") ;

	
	*Others;
	putexcel D66=matrix(f13_4_1) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel I66=matrix(f13_4_2) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel L66=matrix(f13_4_3) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel Q66=matrix(f13_4_4) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel W66=matrix(f13_4_5) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel AF66=matrix(f13_4_6) using `using',keepcellformat modify sheet("`sheet'") ;

	*Non-responses;
	putexcel D80=matrix(f13_5_1) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel I80=matrix(f13_5_2) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel L80=matrix(f13_5_3) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel Q80=matrix(f13_5_4) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel W80=matrix(f13_5_5) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel AF80=matrix(f13_5_6) using `using',keepcellformat modify sheet("`sheet'") ;
	
	putexcel A3=`versionprint' using `using', modify sheet("`sheet'") keepcellformat;

	********
	* OPEN *
	********;
	if "`open'"!="" {;
		!start `using'; // doesn't work with "" or `""' so I already changed `open' to "" if using has spaces, ;
	};
	};
end;

*******TABLE F16: Fiscal Profile**************************************************************************;
program define f16_race;

syntax  [if] [in] [pweight/] [using/] [,table(string) Market(varname) race1(varname) race2(varname) race3(varname) race4(varname) race5(varname) OPEN 
		   Disposable(varname) 
		   Consumable(varname)
		   Final(varname) 
		   age(varname)
		   PL125(string)				
			PL250(string)               
			PL400(string) 
			PENSions(varname)
			hhe(varname) 
		    hhid(varname)];
	local sheet="F16. Fiscal Profile";
	local version 1.0;
	local command ceqrace;
	local versionprint ("Results produced by version `version' of `command' on `c(current_date)' at `c(current_time)'");

	qui{;
		 *if `"`weight'"' != "" {;
   *             local wght `"[`weight'`exp']"';
    *    };
	#delimit cr
	cap svydes
	scalar no_svydes = _rc
	tempvar ones
	gen `ones'=1
	if !_rc qui svyset // gets the results saved in return list
	if "`r(wvar)'"=="" & "`exp'"=="" {
		`dit' "Warning: weights not specified in svydes or the command"
		`dit' "Hence, equal weights (simple random sample) assumed"
	}
	else {
		if "`exp'"=="" & "`r(wvar)'"!="" local w `r(wvar)'
		if "`exp'"!="" local w `exp'
		if "`w'"!="" {
			tempvar weightvar
			qui gen `weightvar' = `w'
			local w `weightvar'
		}
		else local w "`ones'"
		
		if "`w'"!="" {
			local pw "[pw = `w']"
			local aw "[aw = `w']"
		}
		if "`exp'"=="" & "`r(wvar)'"!="" {
			local weight "pw"
			local exp "`r(wvar)'"
		}
	}		
	
	#delimit;
		
		forvalues x=1/5{;
			if "`race`x''"==""{;
				local cc=`cc'+1;
				tempvar race`x';
				gen `race`x''=.;
			};
			};
			
		//national;
		tempvar race6;
		gen `race6'=1;
		
		if "`market'"=="" {;
			display as error "Must specify Market(varname) option";
			exit;
		};
if "``hhid'"=="" {;
			display as error "Must specify the household id.";
			exit;
		};

	//Poverty lines;
	local p1=`pl250';
	local p2=`pl400';
	local pl1000=`pl250'*4;
	local pl5000=`pl250'*20;
		
	
	forvalues x=1/6{;
		****Table for individuals;
		matrix f16_`x'_1_i=J(6,1,.);//number of individuals (sample);
		matrix colnames f16_`x'_1_i=indivs;
		matrix rownames f16_`x'_1_i=y125 y250 y4 y10 y50 ym50;
	
		matrix f16_`x'_2_i=J(6,1,.);//number of individuals (population);
		matrix colnames f16_`x'_2_i=indivp;
		matrix rownames f16_`x'_2_i=y125 y250 y4 y10 y50 ym50;
	
		matrix f16_`x'_3_i=J(6,4,.);//total incomes;
		matrix colnames f16_`x'_3_i=market disposable consumable final;
		matrix rownames f16_`x'_3_i=y125 y250 y4 y10 y50 ym50;
		
		matrix f16_`x'_4_i=J(6,4,.);//age pensions,etc;
		matrix colnames f16_`x'_4_i=age hsize pens agefive;
		matrix rownames f16_`x'_4_i=y125 y250 y4 y10 y50 ym50;
	
		****Table for households;
	
		matrix f16_`x'_1_h=J(6,1,.);//number of households (sample);
		matrix colnames f16_`x'_1_h=hhs;
		matrix rownames f16_`x'_1_h=y125 y250 y4 y10 y50 ym50;
	
		matrix f16_`x'_2_h=J(6,1,.);//number of individuals (sample);
		matrix colnames f16_`x'_2_h=indivs;
		matrix rownames f16_`x'_2_h=y125 y250 y4 y10 y50 ym50;
		
		matrix f16_`x'_3_h=J(6,1,.);//number of households (population);
		matrix colnames f16_`x'_3_h=hhp;
		matrix rownames f16_`x'_3_h=y125 y250 y4 y10 y50 ym50;
	
		matrix f16_`x'_4_h=J(6,1,.);//number of individuals (population);
		matrix colnames f16_`x'_4_h=indivp;
		matrix rownames f16_`x'_4_h=y125 y250 y4 y10 y50 ym50;	
		
		matrix f16_`x'_5_h=J(6,4,.);//total incomes;
		matrix colnames f16_`x'_5_h=market disposable consumable final;
		matrix rownames f16_`x'_5_h=y125 y250 y4 y10 y50 ym50;
		
		matrix f16_`x'_6_h=J(6,5,.);//age pensions,etc;
		matrix colnames f16_`x'_6_h=age hsize pens agefive mixrace;
		matrix rownames f16_`x'_6_h=y125 y250 y4 y10 y50 ym50;
	};
			
	*Poverty values;	
	tempvar  g_m;
	gen `g_m'=. ;
	replace `g_m'=1 if `market'<`pl125';
	replace `g_m'=2 if `market'>=`pl125' & `market'<`pl250';
	replace `g_m'=3 if `market'>=`pl250' & `market'<`pl400';
	replace `g_m'=4 if `market'>=`pl400' & `market'<`pl1000';
	replace `g_m'=5 if `market'>=`pl1000' & `market'<`pl5000';
	replace `g_m'=6 if `market'>=`pl5000';
	
	*household size;
	tempvar hhsize;
	egen `hhsize'=sum(`race6'),by(`hhid');
	*Pensioners;
	tempvar id_pensioners;
	gen `id_pensioners'=cond(`pensions'>0 & `pensions'!=.,1,0);
	*Less than 5 years;
	tempvar less5;
	gen `less5'=cond(`age'<5,1,0);
	*Table for individuals;
	forvalues x=1/6{;//races;
		forvalues z=1/6{;//socioeconomic groups;
			*matrix 1;
			sum `race6' if `race`x''==1 & `g_m'==`z';
			matrix f16_`x'_1_i[`z',1]=r(sum);
			*matrix 2;
			sum `race6' `wght' if `race`x''==1 & `g_m'==`z';
			matrix f16_`x'_2_i[`z',1]=r(sum);		
			*matrix 3;
			sum `market' `wght' if `race`x''==1 & `g_m'==`z';
			matrix f16_`x'_3_i[`z',1]=r(sum);	
			sum `disposable' `wght' if `race`x''==1 & `g_m'==`z';
			matrix f16_`x'_3_i[`z',2]=r(sum);
			sum `consumable' `wght' if `race`x''==1 & `g_m'==`z';
			matrix f16_`x'_3_i[`z',3]=r(sum);
			sum `final' `wght' if `race`x''==1 & `g_m'==`z';
			matrix f16_`x'_3_i[`z',4]=r(sum);
			sum `age' `wght' if `race`x''==1 & `g_m'==`z';
			matrix f16_`x'_4_i[`z',1]=r(mean);
			sum `hhsize' `wght' if `race`x''==1 & `g_m'==`z';
			matrix f16_`x'_4_i[`z',2]=r(mean);
			sum `id_pensioners' `wght' if `race`x''==1 & `g_m'==`z';
			matrix f16_`x'_4_i[`z',3]=r(mean)*100;
			sum `less5' `wght' if `race`x''==1 & `g_m'==`z';
			matrix f16_`x'_4_i[`z',4]=r(mean)*100;  
			
			
		};
	

	};
	*Put in excel;
	*Indigenous;
	putexcel C11=matrix(f16_1_1_i) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel E11=matrix(f16_1_2_i) using `using',keepcellformat modify sheet("`sheet'") ;	
	putexcel G11=matrix(f16_1_3_i) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel S11=matrix(f16_1_4_i) using `using',keepcellformat modify sheet("`sheet'") ;
	*White/Non-Ethnic;
	putexcel C18=matrix(f16_2_1_i) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel E18=matrix(f16_2_2_i) using `using',keepcellformat modify sheet("`sheet'") ;	
	putexcel G18=matrix(f16_2_3_i) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel S18=matrix(f16_2_4_i) using `using',keepcellformat modify sheet("`sheet'") ;
	*African Descendant;
	putexcel C25=matrix(f16_3_1_i) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel E25=matrix(f16_3_2_i) using `using',keepcellformat modify sheet("`sheet'") ;	
	putexcel G25=matrix(f16_3_3_i) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel S25=matrix(f16_3_4_i) using `using',keepcellformat modify sheet("`sheet'") ;
	*Other;
	putexcel C32=matrix(f16_4_1_i) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel E32=matrix(f16_4_2_i) using `using',keepcellformat modify sheet("`sheet'") ;	
	putexcel G32=matrix(f16_4_3_i) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel S32=matrix(f16_4_4_i) using `using',keepcellformat modify sheet("`sheet'") ;
	*Non-Responses;
	putexcel C39=matrix(f16_5_1_i) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel E39=matrix(f16_5_2_i) using `using',keepcellformat modify sheet("`sheet'") ;	
	putexcel G39=matrix(f16_5_3_i) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel S39=matrix(f16_5_4_i) using `using',keepcellformat modify sheet("`sheet'") ;
	*Total Population;
	putexcel C46=matrix(f16_6_1_i) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel E46=matrix(f16_6_2_i) using `using',keepcellformat modify sheet("`sheet'") ;	
	putexcel G46=matrix(f16_6_3_i) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel S46=matrix(f16_6_4_i) using `using',keepcellformat modify sheet("`sheet'") ;
	
	*Table for households;
	*Race of the household head;
	tempvar racehh1;
	gen `racehh1'=.;
	forvalues x=1/5{;
		replace `racehh1'= `x' if `race`x''==1 & `hhe'==1;
		};	
	tempvar racehh;
	*Race of the household;
	egen `racehh'=mean(`racehh1'),by(`hhid');
	
	tempvar age_hh;
	*Average age in HH;
	egen `age_hh'=mean(`age'),by(`hhid');
		*HH with Pensioners;
	tempvar pensioners_hh;
	egen `pensioners_hh'= sum(`id_pensioners'),by(`hhid'); 
	replace `pensioners_hh'=1 if `pensioners_hh'>0 & `pensioners_hh'!=.;
	*HH with Children under 5 years;
	tempvar less5_hh;
	egen `less5_hh'= sum(`less5'),by(`hhid'); 
	replace `less5_hh'=1 if `less5_hh'>0 & `less5_hh'!=.;
	*% of mixed race households;
	tempvar r_ind;
	gen `r_ind'=.;
	forvalues x=1/5{;
		replace `r_ind'= `x' if `race`x''==1;
	};
	tempvar r_mix;
	egen `r_mix'=mean(`r_ind'), by(`hhid'); //average categorical value';
	replace `r_mix'=0 if `r_mix'==1 | `r_mix'==2 | `r_mix'==3 | `r_mix'==4 | `r_mix'==5;//Households with same race;
	replace `r_mix'=1 if `r_mix'>0 & `r_mix'!=.;//Households with different race;
	
	
	forvalues x=1/6{;//races;
		forvalues z=1/6{;//socioeconomic groups;
			*matrix 2;
			sum `race6' if `racehh'==`x' & `g_m'==`z';
			matrix f16_`x'_2_h[`z',1]=r(sum);
			*matrix 4;
			sum `race6' `wght' if `racehh'==`x' & `g_m'==`z';
			matrix f16_`x'_4_h[`z',1]=r(sum);		
			
			preserve;
			keep if `hhe'==1; //Only HH information;
			*matrix 1;
			sum `race6' if `racehh'==`x' & `g_m'==`z';
			matrix f16_`x'_1_h[`z',1]=r(sum);
			*matrix 3;
			sum `race6' `wght' if `racehh'==`x' & `g_m'==`z';
			matrix f16_`x'_3_h[`z',1]=r(sum);		
			*matrix 5;
			sum `market' `wght' if `racehh'==`x' & `g_m'==`z';
			matrix f16_`x'_5_h[`z',1]=r(sum);	
			sum `disposable' `wght' if `racehh'==`x' & `g_m'==`z';
			matrix f16_`x'_5_h[`z',2]=r(sum);
			sum `consumable' `wght' if `racehh'==`x' & `g_m'==`z';
			matrix f16_`x'_5_h[`z',3]=r(sum);
			sum `final' `wght' if `racehh'==`x' & `g_m'==`z';
			matrix f16_`x'_5_h[`z',4]=r(sum);
			
			*matrix 6;
			sum `age_hh' `wght' if `race`x''==1 & `g_m'==`z';
			matrix f16_`x'_6_h[`z',1]=r(mean);
			sum `hhsize' `wght' if `race`x''==1 & `g_m'==`z';
			matrix f16_`x'_6_h[`z',2]=r(mean);
			sum `pensioners_hh' `wght' if `race`x''==1 & `g_m'==`z';
			matrix f16_`x'_6_h[`z',3]=r(mean)*100;
			sum `less5_hh' `wght' if `race`x''==1 & `g_m'==`z';
			matrix f16_`x'_6_h[`z',4]=r(mean)*100;  
			sum `r_mix' `wght' if `race`x''==1 & `g_m'==`z';
			matrix f16_`x'_6_h[`z',5]=r(mean)*100; 
			restore;
			
	};
	
	};
	
	*Put in excel;
	*Indigenous;
	putexcel C59=matrix(f16_1_1_h) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel E59=matrix(f16_1_2_h) using `using',keepcellformat modify sheet("`sheet'") ;	
	putexcel G59=matrix(f16_1_3_h) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel I59=matrix(f16_1_4_h) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel K59=matrix(f16_1_5_h) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel W59=matrix(f16_1_6_h) using `using',keepcellformat modify sheet("`sheet'") ;

	*White/Non-Ethnic;
	putexcel C66=matrix(f16_2_1_h) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel E66=matrix(f16_2_2_h) using `using',keepcellformat modify sheet("`sheet'") ;	
	putexcel G66=matrix(f16_2_3_h) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel I66=matrix(f16_2_4_h) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel K66=matrix(f16_2_5_h) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel W66=matrix(f16_2_6_h) using `using',keepcellformat modify sheet("`sheet'") ;
	
	*African Descendant;
	putexcel C73=matrix(f16_3_1_h) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel E73=matrix(f16_3_2_h) using `using',keepcellformat modify sheet("`sheet'") ;	
	putexcel G73=matrix(f16_3_3_h) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel I73=matrix(f16_3_4_h) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel K73=matrix(f16_3_5_h) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel W73=matrix(f16_3_6_h) using `using',keepcellformat modify sheet("`sheet'") ;
	
	*Other;
	putexcel C80=matrix(f16_4_1_h) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel E80=matrix(f16_4_2_h) using `using',keepcellformat modify sheet("`sheet'") ;	
	putexcel G80=matrix(f16_4_3_h) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel I80=matrix(f16_4_4_h) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel K80=matrix(f16_4_5_h) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel W80=matrix(f16_4_6_h) using `using',keepcellformat modify sheet("`sheet'") ;
	
	*Non-Responses;
	putexcel C87=matrix(f16_5_1_h) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel E87=matrix(f16_5_2_h) using `using',keepcellformat modify sheet("`sheet'") ;	
	putexcel G87=matrix(f16_5_3_h) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel I87=matrix(f16_5_4_h) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel K87=matrix(f16_5_5_h) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel W87=matrix(f16_5_6_h) using `using',keepcellformat modify sheet("`sheet'") ;
	
	*Total Population;
	putexcel C94=matrix(f16_6_1_h) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel E94=matrix(f16_6_2_h) using `using',keepcellformat modify sheet("`sheet'") ;	
	putexcel G94=matrix(f16_6_3_h) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel I94=matrix(f16_6_4_h) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel K94=matrix(f16_6_5_h) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel W94=matrix(f16_6_6_h) using `using',keepcellformat modify sheet("`sheet'") ;
	
	putexcel A3=`versionprint' using `using', modify sheet("`sheet'") keepcellformat;
	
};
noisily di as text "Results for Individuals";
	forvalues x=1/6{;//races;
		forvalues y=1/4{;//Matrices;
			noisily di "race `x', matrix `y'";
			noisily matrix list f16_`x'_`y'_i;

		};
	};
noisily di as text "Results for Households";
	forvalues x=1/6{;//races;
		forvalues y=1/6{;//Matrices;
			noisily di "race `x', matrix `y'";
			noisily matrix list f16_`x'_`y'_h;

		};
	};
	********
	* OPEN *
	********;
	if "`open'"!="" {;
		!start `using'; // doesn't work with "" or `""' so I already changed `open' to "" if using has spaces, ;
	};
	end;

*******TABLE F16: Coverage (total)**************************************************************************;
program define f17_race;

syntax   [if] [in] [using/] [pweight/] [,table(string) Market(varname) race1(varname) race2(varname) race3(varname) race4(varname) race5(varname) OPEN
		   PL125(string)
			PL250(string)
			PL400(string)
		   dtax(varname)
		   OTRANsfers(varname)
		   NONContributory(varname)
		   hhe(varname) 
		   hhid(varname)
		   CCT(varname)
		   SCHolarships(varname)
		   UNEMPloyben(varname)
		   FOODTransfers(varname)
		   HEALTH(varname)
		   PENSions(varname)
		   		   ];
	di "Coverage (Total)";
	local sheet="F17. Coverage (Total)";
	local version 1.0;
	local command ceqrace;
	local versionprint ("Results produced by version `version' of `command' on `c(current_date)' at `c(current_time)'");

qui{;
  *if `"`weight'"' != "" {;
   *             local wght `"[`weight'`exp']"';
    *    };
	#delimit cr
	cap svydes
	scalar no_svydes = _rc
	tempvar ones
	gen `ones'=1
	if !_rc qui svyset // gets the results saved in return list
	if "`r(wvar)'"=="" & "`exp'"=="" {
		`dit' "Warning: weights not specified in svydes or the command"
		`dit' "Hence, equal weights (simple random sample) assumed"
	}
	else {
		if "`exp'"=="" & "`r(wvar)'"!="" local w `r(wvar)'
		if "`exp'"!="" local w `exp'
		if "`w'"!="" {
			tempvar weightvar
			qui gen `weightvar' = `w'
			local w `weightvar'
		}
		else local w "`ones'"
		
		if "`w'"!="" {
			local pw "[pw = `w']"
			local aw "[aw = `w']"
		}
		if "`exp'"=="" & "`r(wvar)'"!="" {
			local weight "pw"
			local exp "`r(wvar)'"
		}
	}		
	
	#delimit;
		forvalues x=1/5{;
		if "`race`x''"==""{;
			local cc=`cc'+1;
			tempvar race`x';
			gen `race`x''=.;
		};
		}; 
	tempvar race6;
	gen `race6'=1;
	


	if "`market'"=="" {;
		display as error "Must specify Market(varname) option";
	exit;
	};

	if "`pl125'"=="" | "`pl250'"=="" | "`pl400'"=="" {;
		display as error "Must specify Poverty lines for 1.25, 2.50 and 4.00 PPP";
		exit;
		};
	if "`hhe'"=="" | "`hhid'"==""{;
		display as error "Must specify who is the household head and the household ID";
		exit;
		};
				
	local pl1000=`pl250'*4;
	local pl5000=`pl250'*20;
	
	*Race of the household head;
	tempvar racehh1;
	gen `racehh1'=.;
	forvalues x=1/5{
		replace `racehh'= `x' if `race`x''==1 & `hhe'==1;
		};	
	tempvar racehh;
	*Race of the household;
	egen `racehh'=mean(`racehh'),by(`hhid');
	
	local vlist  `cct' `scholarships' `noncontributory' `unemployben' `foodtransfers' `otransfers' `health' `pensions' `dtax';
		
	tempvar g_m;
	gen `g_m'=. ;
	replace `g_m'=1 if `market'<`pl125';
	replace `g_m'=2 if `market'>=`pl125' & `market'<`pl250';
	replace `g_m'=3 if `market'>=`pl250' & `market'<`pl400';
	replace `g_m'=4 if `market'>=`pl400' & `market'<`pl1000';
	replace `g_m'=5 if `market'>=`pl1000' & `market'<`pl5000';
	replace `g_m'=6 if `market'>=`pl5000';
	
	*Variables for total benefits;
	forvalues x=1/11{;
	tempvar g_m_`x';
	};
	gen `g_m_1'=cond(`market'<`pl125',1,0);
	gen `g_m_2'=cond(`market'>=`pl125' & `market'<`pl250',1,0);
	gen `g_m_3'=cond(`market'<`pl250',1,0);
	gen `g_m_4'=cond(`market'>=`pl250' & `market'<`pl400',1,0);
	gen `g_m_5'=cond(`market'<`pl400',1,0);
	gen `g_m_6'=cond(`market'>=`pl400' & `market'<`pl1000',1,0);
	gen `g_m_7'=cond(`market'>=`pl1000' & `market'<`pl5000',1,0);
	gen `g_m_8'=cond(`market'>=`pl5000' & `market'!=.,1,0);
	gen `g_m_9'=cond(`market'>=`pl1000' & `market'!=.,1,0);
	gen `g_m_10'=cond(`market'>=`pl400' & `market'!=.,1,0);
	gen `g_m_11'=1;
	
	*Results for individuals;
	*Population;

	matrix f17_1_1=J(2,6,.);
	matrix colnames f17_1_1=national indig white african other nonresp;
	matrix rownames f17_1_1=y125 y250;
	matrix f17_1_2=J(1,6,.);
	matrix colnames f17_1_2=national indig white african other nonresp;
	matrix rownames f17_1_2=y4;		
	matrix f17_1_3=J(3,6,.);
	matrix colnames f17_1_3=national indig white african other nonresp;
	matrix rownames f17_1_3=y10 y50 ym50;
			
	tempvar tot;
	gen `tot'=1;
	forvalues y=1/6{;*Sociodemographic group;
	summ `tot' `wght' if `g_m'==`y';
	if `y'==1 matrix f17_1_1[1,1]=r(sum);
	if `y'==2 matrix f17_1_1[2,1]=r(sum);
	if `y'==3 matrix f17_1_2[1,1]=r(sum);
	if `y'==4 matrix f17_1_3[1,1]=r(sum);
	if `y'==5 matrix f17_1_3[2,1]=r(sum);
	if `y'==6 matrix f17_1_3[3,1]=r(sum);
	local c=1;
	forvalues x=1/5{;*Race;
	summ `tot' `wght' if `g_m'==`y' & `race`x''==1;
		local c=`c'+1;
	if `y'==1 matrix f17_1_1[1,`c']=r(sum);
	if `y'==2 matrix f17_1_1[2,`c']=r(sum);
	if `y'==3 matrix f17_1_2[1,`c']=r(sum);
	if `y'==4 matrix f17_1_3[1,`c']=r(sum);
	if `y'==5 matrix f17_1_3[2,`c']=r(sum);
	if `y'==6 matrix f17_1_3[3,`c']=r(sum);
	};
	};
	*National;
	putexcel D22=matrix(f17_1_1) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel G22=matrix(f17_1_2) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel I22=matrix(f17_1_3) using `using',keepcellformat modify sheet("`sheet'") ;

	*Results for Households;
	*Households;
	preserve;
	keep if `hhe'==1;//In this case we can do it because we are not linking programs yet;
	matrix f17_2_1=J(2,6,.);
	matrix colnames f17_2_1=national indig white african other nonresp;
	matrix rownames f17_2_1=y125 y250;
	matrix f17_2_2=J(1,6,.);
	matrix colnames f17_2_2=national indig white african other nonresp;
	matrix rownames f17_2_2=y4;		
	matrix f17_2_3=J(3,6,.);
	matrix colnames f17_2_3=national indig white african other nonresp;
	matrix rownames f17_2_3=y10 y50 ym50;
			
	tempvar tot;
	gen `tot'=1;
	forvalues y=1/6{;*Sociodemographic group;
	summ `tot' `wght' if `g_m'==`y';
	if `y'==1 matrix f17_2_1[1,1]=r(sum);
	if `y'==2 matrix f17_2_1[2,1]=r(sum);
	if `y'==3 matrix f17_2_2[1,1]=r(sum);
	if `y'==4 matrix f17_2_3[1,1]=r(sum);
	if `y'==5 matrix f17_2_3[2,1]=r(sum);
	if `y'==6 matrix f17_2_3[3,1]=r(sum);
	local c=1;
	forvalues x=1/5{;*Race;
	summ `tot' `wght' if `g_m'==`y' & `race`x''==1;
		local c=`c'+1;
	if `y'==1 matrix f17_2_1[1,`c']=r(sum);
	if `y'==2 matrix f17_2_1[2,`c']=r(sum);
	if `y'==3 matrix f17_2_2[1,`c']=r(sum);
	if `y'==4 matrix f17_2_3[1,`c']=r(sum);
	if `y'==5 matrix f17_2_3[2,`c']=r(sum);
	if `y'==6 matrix f17_2_3[3,`c']=r(sum);
	};
	};
	*National;
	putexcel D28=matrix(f17_1_1) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel G28=matrix(f17_1_2) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel I28=matrix(f17_1_3) using `using',keepcellformat modify sheet("`sheet'") ;
	restore;
	
	
	foreach z in `vlist'{;
	local nz=`nz'+1;
		if "`z'"==""{;
			tempvar "`z'";
			gen ``z''=.;
		};
		*Direct beneficiaries;
		tempvar d_b_`z';
		gen `d_b_`z''=cond(`z'>0 &`z'!=0,1,0);
		*Households;
		tempvar hh_b_`z'1;
		egen `hh_b_`z'1'=mean(`x'),by(`hhid');
		tempvar hh_b_`z';
		gen `hh_b_`z''=cond(`hh_b_`z'1'>0 & `hhe'==1,1,0);
		replace `hh_b_`z''=. if `hhe'!=1;
		*Direct and indirect beneficiaries;
		tempvar di_b_`z';
		egen `di_b_`z''=sum(`hh_b_`z''),by(`hhid');
		replace `di_b_`z''=1 if `di_b_`z''>0 & `di_b_`z''!=.;
	*****Beneficiaries Matrices;
		*Direct;
		matrix f17_`z'_1=J(11,6,.);
		matrix colnames f17_`z'_1=national indig white african other nonresp;
		matrix rownames f17_`z'_1=yL125 yM125L250 yL250 yM250L400 yL400 yM400L1000 yM1000L5000 yM5000 YM1000 YM4000 YT;
		matrix f17_`z'_2=J(1,6,.);
		matrix colnames f17_`z'_2=national indig white african other nonresp;
		matrix rownames f17_`z'_2=yL125 yM125L250 yL250 yM250L400 yL400 yM400L1000 yM1000L5000 yM5000 YM1000 YM4000 YT;;		
		matrix f17_`z'_3=J(3,6,.);
		matrix colnames f17_`z'_3=national indig white african other nonresp;
		matrix rownames f17_`z'_3=yL125 yM125L250 yL250 yM250L400 yL400 yM400L1000 yM1000L5000 yM5000 YM1000 YM4000 YT;;
	*****Total Benefits (in LCU) Matrices;
		matrix f17_`z'_tb=J(11,6,.);
		matrix colnames f17_`z'_tb=national indig white african other nonresp;
		matrix rownames f17_`z'_tb=yL125 yM125L250 yL250 yM250L400 yL400 yM400L1000 yM1000L5000 yM5000 YM1000 YM4000 YT;;
		
		*Total Benefits;
	
	 forvalues x=1/11{;//groups of income;
	 
		summ `z' `wght' if `g_m_`x''==1;
		matrix f17_`z'_tb[1,`x']=r(sum);
		local c=1;
		forvalues y=1/5{;//Ethnic groups;	
			local c=`c'+1;
			summ `z' `wght' if `g_m_`x''==1 & `race`y''==1;
			matrix f17_`z'_tb[`c',`x']=r(sum);
	};
	};	
	noisily di "Total benefits `z'";
	noisily matrix list f17_`z'_tb;
	if `nz'==1	putexcel C84=matrix(f17_`z'_tb) using `using',keepcellformat modify sheet("`sheet'") ;
	if `nz'==2	putexcel C156=matrix(f17_`z'_tb) using `using',keepcellformat modify sheet("`sheet'") ;
	if `nz'==3	putexcel C228=matrix(f17_`z'_tb) using `using',keepcellformat modify sheet("`sheet'") ;
	if `nz'==4	putexcel C300=matrix(f17_`z'_tb) using `using',keepcellformat modify sheet("`sheet'") ;
	if `nz'==5	putexcel C372=matrix(f17_`z'_tb) using `using',keepcellformat modify sheet("`sheet'") ;
	if `nz'==6	putexcel C444=matrix(f17_`z'_tb) using `using',keepcellformat modify sheet("`sheet'") ;
	if `nz'==7	putexcel C516=matrix(f17_`z'_tb) using `using',keepcellformat modify sheet("`sheet'") ;
	if `nz'==8	putexcel C588=matrix(f17_`z'_tb) using `using',keepcellformat modify sheet("`sheet'") ;
	if `nz'==9	putexcel C660=matrix(f17_`z'_tb) using `using',keepcellformat modify sheet("`sheet'") ;
	
	
	*Beneficiaries;
	
	forvalues x=1/11{;//groups of income;
		*Direct beneficiaries;
		summ  `d_b_`z'' `wght' if `g_m_`x''==1;
		matrix f17_`z'_1[1,`x']=r(sum);
		
		*Households;
		summ  `hh_b_`z'' `wght' if `g_m_`x''==1;
		matrix f17_`z'_2[1,`x']=r(sum);
		
		*Direct and indirect beneficiaries;
		summ  `di_b_`z'' `wght' if `g_m_`x''==1;
		matrix f17_`z'_3[1,`x']=r(sum);
		
		local c=1;
		forvalues y=1/5{;//Ethnic groups;	
			local c=`c'+1;
			*Direct beneficiaries;
			summ  `d_b_`z'' `wght' if `g_m_`x''==1 & `race`y''==1;
			matrix f17_`z'_1[`c',`x']=round(r(sum));
			
			*Households;
			summ  `hh_b_`z'' `wght' if `g_m_`x''==1 & `racehh'==`y';
			matrix f17_`z'_2[`c',`x']=round(r(sum));
		
			*Direct and indirect beneficiaries;
			summ  `di_b_`z'' `wght' if `g_m_`x''==1 & `racehh'==`y';
			matrix f17_`z'_3[`c',`x']=round(r(sum));
			
	};
	};	
	noisily di "Beneficiaries `z': Direct Beneficiaries";
	noisily matrix list f17_`z'_1;
	noisily di "Beneficiaries `z': Households";
	noisily matrix list f17_`z'_2;
	noisily di "Beneficiaries `z': Direct and Indirect Beneficiaries";
	noisily matrix list f17_`z'_3;
	
		if `nz'==1{;
	putexcel D40=matrix(f17_`z'_1) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel D46=matrix(f17_`z'_2) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel D52=matrix(f17_`z'_3) using `using',keepcellformat modify sheet("`sheet'") ;
	};
		if `nz'==2{;
	putexcel D112=matrix(f17_`z'_1) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel D118=matrix(f17_`z'_2) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel D124=matrix(f17_`z'_3) using `using',keepcellformat modify sheet("`sheet'") ;
	};
		if `nz'==3{;
	putexcel D184=matrix(f17_`z'_1) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel D190=matrix(f17_`z'_2) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel D196=matrix(f17_`z'_3) using `using',keepcellformat modify sheet("`sheet'") ;
	};
		if `nz'==4{;
	putexcel D256=matrix(f17_`z'_1) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel D262=matrix(f17_`z'_2) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel D268=matrix(f17_`z'_3) using `using',keepcellformat modify sheet("`sheet'") ;
	};
		if `nz'==5{;
	putexcel D328=matrix(f17_`z'_1) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel D334=matrix(f17_`z'_2) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel D340=matrix(f17_`z'_3) using `using',keepcellformat modify sheet("`sheet'") ;
	};
		if `nz'==6{;
	putexcel D400=matrix(f17_`z'_1) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel D406=matrix(f17_`z'_2) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel D412=matrix(f17_`z'_3) using `using',keepcellformat modify sheet("`sheet'") ;
	};
		if `nz'==7{;
	putexcel D472=matrix(f17_`z'_1) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel D478=matrix(f17_`z'_2) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel D484=matrix(f17_`z'_3) using `using',keepcellformat modify sheet("`sheet'") ;
	};
		if `nz'==8{;
	putexcel D544=matrix(f17_`z'_1) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel D550=matrix(f17_`z'_2) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel D556=matrix(f17_`z'_3) using `using',keepcellformat modify sheet("`sheet'") ;
	};
		if `nz'==9{;
	putexcel D616=matrix(f17_`z'_1) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel D622=matrix(f17_`z'_2) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel D628=matrix(f17_`z'_3) using `using',keepcellformat modify sheet("`sheet'") ;
	};
	putexcel A3=`versionprint' using `using', modify sheet("`sheet'") keepcellformat;
	
};
	********
	* OPEN *
	********;
	if "`open'"!="" {;
		!start `using'; // doesn't work with "" or `""' so I already changed `open' to "" if using has spaces, ;
	};
};
end;

*******TABLE F18: Coverage (target)**************************************************************************;
program define f18_race;

syntax   [if] [in] [using/] [pweight/] [,table(string) Market(varname) race1(varname) race2(varname) race3(varname) race4(varname) race5(varname) OPEN
		   PL125(string)
			PL250(string)
			PL400(string)
		    NONContributory(varname)
		   hhe(varname) 
		   hhid(varname)
		   CCT(varname)
		   PENSions(varname)
		   TARCCT(varname)
		   TARNCP(varname)
		   TARPENsions(varname)
		   		   ];
	di "Coverage (Target)";
	local sheet="F18. Coverage (Target)";
	local version 1.0;
	local command ceqrace;
	local versionprint ("Results produced by version `version' of `command' on `c(current_date)' at `c(current_time)'");

qui{;
   *if `"`weight'"' != "" {;
   *             local wght `"[`weight'`exp']"';
    *    };
	#delimit cr
	cap svydes
	scalar no_svydes = _rc
	tempvar ones
	gen `ones'=1
	if !_rc qui svyset // gets the results saved in return list
	if "`r(wvar)'"=="" & "`exp'"=="" {
		`dit' "Warning: weights not specified in svydes or the command"
		`dit' "Hence, equal weights (simple random sample) assumed"
	}
	else {
		if "`exp'"=="" & "`r(wvar)'"!="" local w `r(wvar)'
		if "`exp'"!="" local w `exp'
		if "`w'"!="" {
			tempvar weightvar
			qui gen `weightvar' = `w'
			local w `weightvar'
		}
		else local w "`ones'"
		
		if "`w'"!="" {
			local pw "[pw = `w']"
			local aw "[aw = `w']"
		}
		if "`exp'"=="" & "`r(wvar)'"!="" {
			local weight "pw"
			local exp "`r(wvar)'"
		}
	}		
	
	#delimit;
		forvalues x=1/5{;
		if "`race`x''"==""{;
			local cc=`cc'+1;
			tempvar race`x';
			gen `race`x''=.;
		};
		}; 
	tempvar race6;
	gen `race6'=1;
	


	if "`market'"=="" {;
		display as error "Must specify Market(varname) option";
	exit;
	};

	if "`pl125'"=="" | "`pl250'"=="" | "`pl400'"=="" {;
		display as error "Must specify Poverty lines for 1.25, 2.50 and 4.00 PPP";
		exit;
		};
	if "`hhe'"=="" | "`hhid'"==""{;
		display as error "Must specify who is the household head and the household ID";
		exit;
		};
				
	local pl1000=`pl250'*4;
	local pl5000=`pl250'*20;
	
	*Race of the household head;
	tempvar racehh1;
	gen `racehh1'=.;
	forvalues x=1/5{
		replace `racehh'= `x' if `race`x''==1 & `hhe'==1;
		};	
	tempvar racehh;
	*Race of the household;
	egen `racehh'=mean(`racehh'),by(`hhid');
	
	local vlist  `cct' `noncontributory' `pensions';
	local cond`cct'="`tarcct'";
	local cond`noncontributory'= "`tarncp'";
	local cond`pensions'="`tarpensions'";  
	
	tempvar g_m;
	gen `g_m'=. ;
	replace `g_m'=1 if `market'<`pl125';
	replace `g_m'=2 if `market'>=`pl125' & `market'<`pl250';
	replace `g_m'=3 if `market'>=`pl250' & `market'<`pl400';
	replace `g_m'=4 if `market'>=`pl400' & `market'<`pl1000';
	replace `g_m'=5 if `market'>=`pl1000' & `market'<`pl5000';
	replace `g_m'=6 if `market'>=`pl5000';
	
	*Variables for total benefits;
	forvalues x=1/11{;
	tempvar g_m_`x';
	};
	gen `g_m_1'=cond(`market'<`pl125',1,0);
	gen `g_m_2'=cond(`market'>=`pl125' & `market'<`pl250',1,0);
	gen `g_m_3'=cond(`market'<`pl250',1,0);
	gen `g_m_4'=cond(`market'>=`pl250' & `market'<`pl400',1,0);
	gen `g_m_5'=cond(`market'<`pl400',1,0);
	gen `g_m_6'=cond(`market'>=`pl400' & `market'<`pl1000',1,0);
	gen `g_m_7'=cond(`market'>=`pl1000' & `market'<`pl5000',1,0);
	gen `g_m_8'=cond(`market'>=`pl5000' & `market'!=.,1,0);
	gen `g_m_9'=cond(`market'>=`pl1000' & `market'!=.,1,0);
	gen `g_m_10'=cond(`market'>=`pl400' & `market'!=.,1,0);
	gen `g_m_11'=1;
		
	foreach z in `vlist'{;
	local nz=`nz'+1;
		if "`z'"==""{;
			tempvar "`z'";
			gen ``z''=.;
		};
		*Direct beneficiaries;
		tempvar d_b_`z';
		gen `d_b_`z''=cond(`z'>0 &`z'!=0,1,0);
		*Households;
		tempvar hh_b_`z'1;
		egen `hh_b_`z'1'=mean(`x'),by(`hhid');
		tempvar hh_b_`z';
		gen `hh_b_`z''=cond(`hh_b_`z'1'>0 & `hhe'==1,1,0);
		replace `hh_b_`z''=. if `hhe'!=1;
		*Direct and indirect beneficiaries;
		tempvar di_b_`z';
		egen `di_b_`z''=sum(`hh_b_`z''),by(`hhid');
		replace `di_b_`z''=1 if `di_b_`z''>0 & `di_b_`z''!=.;
	*****Target Population;
		*Direct;
		matrix f18_`z'_1t=J(11,6,.);
		matrix colnames f18_`z'_1t=national indig white african other nonresp;
		matrix rownames f18_`z'_1t=yL125 yM125L250 yL250 yM250L400 yL400 yM400L1000 yM1000L5000 yM5000 YM1000 YM4000 YT;
		*Households;
		matrix f18_`z'_2t=J(1,6,.);
		matrix colnames f18_`z'_2t=national indig white african other nonresp;
		matrix rownames f18_`z'_2t=yL125 yM125L250 yL250 yM250L400 yL400 yM400L1000 yM1000L5000 yM5000 YM1000 YM4000 YT;		
		*Direct and indirect beneficiatries;
		matrix f18_`z'_3t=J(3,6,.);
		matrix colnames f18_`z'_3t=national indig white african other nonresp;
		matrix rownames f18_`z'_3t=yL125 yM125L250 yL250 yM250L400 yL400 yM400L1000 yM1000L5000 yM5000 YM1000 YM4000 YT;
	*****Beneficiaries Matrices;
		*Direct;
		matrix f18_`z'_1b=J(11,6,.);
		matrix colnames f18_`z'_1b=national indig white african other nonresp;
		matrix rownames f18_`z'_1b=yL125 yM125L250 yL250 yM250L400 yL400 yM400L1000 yM1000L5000 yM5000 YM1000 YM4000 YT;
		*Households;
		matrix f18_`z'_2b=J(1,6,.);
		matrix colnames f18_`z'_2b=national indig white african other nonresp;
		matrix rownames f18_`z'_2b=yL125 yM125L250 yL250 yM250L400 yL400 yM400L1000 yM1000L5000 yM5000 YM1000 YM4000 YT;		
		*Direct and indirect beneficiatries;
		matrix f18_`z'_3b=J(3,6,.);
		matrix colnames f18_`z'_3b=national indig white african other nonresp;
		matrix rownames f18_`z'_3b=yL125 yM125L250 yL250 yM250L400 yL400 yM400L1000 yM1000L5000 yM5000 YM1000 YM4000 YT;		
		
	
		*****Total Benefits (in LCU) Matrices;
		matrix f18_`z'_tb=J(11,6,.);
		matrix colnames f18_`z'_tb=national indig white african other nonresp;
		matrix rownames f18_`z'_tb=yL125 yM125L250 yL250 yM250L400 yL400 yM400L1000 yM1000L5000 yM5000 YM1000 YM4000 YT;
		
		*Total Benefits;
	
	 forvalues x=1/11{;//groups of income;
	 
		summ `z' `wght' if `g_m_`x''==1 & `cond`z''==1;
		matrix f18_`z'_tb[1,`x']=r(sum);
		local c=1;
		forvalues y=1/5{;//Ethnic groups;	
			local c=`c'+1;
			summ `z' `wght' if `g_m_`x''==1 & `race`y''==1 & `cond`z''==1;
			matrix f18_`z'_tb[`c',`x']=r(sum);
	};
	};	
	noisily di "Total benefits `z'";
	noisily matrix list f18_`z'_tb;
	if `nz'==1	putexcel C63=matrix(f18_`z'_tb) using `using',keepcellformat modify sheet("`sheet'") ;
	if `nz'==2	putexcel C135=matrix(f18_`z'_tb) using `using',keepcellformat modify sheet("`sheet'") ;
	if `nz'==3	putexcel C207=matrix(f18_`z'_tb) using `using',keepcellformat modify sheet("`sheet'") ;
		
	
	*Target Population;
	
	forvalues x=1/11{;//groups of income;
		*Direct beneficiaries;
		summ  `cond`z'' `wght' if `g_m_`x''==1;
		matrix f18_`z'_1t[1,`x']=r(sum);
		
		*Households;
		summ  `cond`z'' `wght' if `g_m_`x''==1;
		matrix f18_`z'_2t[1,`x']=r(sum);
		
		*Direct and indirect beneficiaries;
		summ  `cond`z'' `wght' if `g_m_`x''==1;
		matrix f18_`z'_3t[1,`x']=r(sum);
		
		local c=1;
		forvalues y=1/5{;//Ethnic groups;	
			local c=`c'+1;
			*Direct beneficiaries;
			summ  `cond`z'' `wght' if `g_m_`x''==1 & `race`y''==1;
			matrix f18_`z'_1t[`c',`x']=round(r(sum));
			
			*Households;
			summ  `cond`z'' `wght' if `g_m_`x''==1 & `racehh'==`y';
			matrix f18_`z'_2t[`c',`x']=round(r(sum));
		
			*Direct and indirect beneficiaries;
			summ  `cond`z'' `wght' if `g_m_`x''==1 & `racehh'==`y';
			matrix f18_`z'_3t[`c',`x']=round(r(sum));
			
	};
	};	
	noisily di "Beneficiaries `z': Direct Beneficiaries";
	noisily matrix list f18_`z'_1t;
	noisily di "Beneficiaries `z': Households";
	noisily matrix list f18_`z'_2t;
	noisily di "Beneficiaries `z': Direct and Indirect Beneficiaries";
	noisily matrix list f18_`z'_3t;
	
		if `nz'==1{;
	putexcel D19=matrix(f18_`z'_1t) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel D25=matrix(f18_`z'_2t) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel D31=matrix(f18_`z'_3t) using `using',keepcellformat modify sheet("`sheet'") ;
	};
		if `nz'==2{;
	putexcel D91=matrix(f18_`z'_1t) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel D97=matrix(f18_`z'_2t) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel D103=matrix(f18_`z'_3t) using `using',keepcellformat modify sheet("`sheet'") ;
	};
		if `nz'==3{;
	putexcel D163=matrix(f18_`z'_1t) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel D169=matrix(f18_`z'_2t) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel D175=matrix(f18_`z'_3t) using `using',keepcellformat modify sheet("`sheet'") ;
	};
	
	};

	*Beneficiaries;
	
	forvalues x=1/11{;//groups of income;
		*Direct beneficiaries;
		summ  `d_b_`z'' `wght' if `g_m_`x''==1 & `cond`z''==1;
		matrix f18_`z'_1b[1,`x']=r(sum);
		
		*Households;
		summ  `hh_b_`z'' `wght' if `g_m_`x''==1 & `cond`z''==1;
		matrix f18_`z'_2b[1,`x']=r(sum);
		
		*Direct and indirect beneficiaries;
		summ  `di_b_`z'' `wght' if `g_m_`x''==1 & `cond`z''==1;
		matrix f18_`z'_3b[1,`x']=r(sum);
		
		local c=1;
		forvalues y=1/5{;//Ethnic groups;	
			local c=`c'+1;
			*Direct beneficiaries;
			summ  `d_b_`z'' `wght' if `g_m_`x''==1 & `race`y''==1 & `cond`z''==1;
			matrix f18_`z'_1b[`c',`x']=round(r(sum));
			
			*Households;
			summ  `hh_b_`z'' `wght' if `g_m_`x''==1 & `racehh'==`y' & `cond`z''==1;
			matrix f18_`z'_2b[`c',`x']=round(r(sum));
		
			*Direct and indirect beneficiaries;
			summ  `di_b_`z'' `wght' if `g_m_`x''==1 & `racehh'==`y' & `cond`z''==1;
			matrix f18_`z'_3b[`c',`x']=round(r(sum));
			
	};
	};	
	noisily di "Beneficiaries `z': Direct Beneficiaries";
	noisily matrix list f18_`z'_1b;
	noisily di "Beneficiaries `z': Households";
	noisily matrix list f18_`z'_2b;
	noisily di "Beneficiaries `z': Direct and Indirect Beneficiaries";
	noisily matrix list f18_`z'_3b;
	
		if `nz'==1{;
	putexcel R19=matrix(f18_`z'_1b) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel R25=matrix(f18_`z'_2b) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel R31=matrix(f18_`z'_3b) using `using',keepcellformat modify sheet("`sheet'") ;
	};
		if `nz'==2{;
	putexcel R91=matrix(f18_`z'_1b) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel R97=matrix(f18_`z'_2b) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel R103=matrix(f18_`z'_3b) using `using',keepcellformat modify sheet("`sheet'") ;
	};
		if `nz'==3{;
	putexcel R163=matrix(f18_`z'_1b) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel R169=matrix(f18_`z'_2b) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel R175=matrix(f18_`z'_3b) using `using',keepcellformat modify sheet("`sheet'") ;
	};
			
	putexcel A3=`versionprint' using `using', modify sheet("`sheet'") keepcellformat;
	
	********
	* OPEN *
	********;
	if "`open'"!="" {;
		!start `using'; // doesn't work with "" or `""' so I already changed `open' to "" if using has spaces, ;
	};
	};

end;



*******TABLE F20: Mobility**************************************************************************;

program define f20_race;
syntax  [if] [in] [pweight/] [using/] [,table(string) Market(varname) race1(varname) race2(varname) race3(varname) race4(varname) race5(varname) OPEN 
		   Disposable(varname) 
		   Postfiscal(varname)
		   Final(varname) 
		   PL125(string)
			PL250(string)
			PL400(string)
		   ];
di "Mobility `'";
local sheet="F20. Mobility";
local version 1.0;
local command ceqrace;
local versionprint ("Results produced by version `version' of `command' on `c(current_date)' at `c(current_time)'");

qui{;
  *if `"`weight'"' != "" {;
   *             local wght `"[`weight'`exp']"';
    *    };
	#delimit cr
	cap svydes
	scalar no_svydes = _rc
	tempvar ones
	gen `ones'=1
	if !_rc qui svyset // gets the results saved in return list
	if "`r(wvar)'"=="" & "`exp'"=="" {
		`dit' "Warning: weights not specified in svydes or the command"
		`dit' "Hence, equal weights (simple random sample) assumed"
	}
	else {
		if "`exp'"=="" & "`r(wvar)'"!="" local w `r(wvar)'
		if "`exp'"!="" local w `exp'
		if "`w'"!="" {
			tempvar weightvar
			qui gen `weightvar' = `w'
			local w `weightvar'
		}
		else local w "`ones'"
		
		if "`w'"!="" {
			local pw "[pw = `w']"
			local aw "[aw = `w']"
		}
		if "`exp'"=="" & "`r(wvar)'"!="" {
			local weight "pw"
			local exp "`r(wvar)'"
		}
	}		
	
	#delimit;
		forvalues x=1/5{;
if "`race`x''"==""{;
local cc=`cc'+1;
tempvar race`x';
gen `race`x''=.;
};
}; 
tempvar race6;
gen `race6'=1;

if "`market'"=="" {;
display as error "Must specify Market(varname) option";
exit;
};


		if "`pl125'"=="" | "`pl250'"=="" | "`pl400'"=="" {;
			display as error "Must specify Poverty lines for 1.25, 2.50 and 4.00 PPP";
			exit;
		};
		
		local pl1000=`pl250'*4;
		local pl5000=`pl250'*20;

local vlist1  `market' `disposable' `consumable' `final' ;


foreach x in `vlist1'{;
tempvar g_`x';
gen `g_`x''=. ;
replace `g_`x''=1 if `x'<`pl125';
replace `g_`x''=2 if `x'>=`pl125' & `x'<`pl250';
replace `g_`x''=3 if `x'>=`pl250' & `x'<`pl400';
replace `g_`x''=4 if `x'>=`pl400' & `x'<`pl1000';
replace `g_`x''=5 if `x'>=`pl1000' & `x'!=.;
};

		   
 local vlist2 `disposable' `consumable' `final';


forvalues x=1/6{;
foreach y in `vlist2'{;
matrix f20_`x'_`y'=J(5,5,.);
matrix colnames f20_`x'_`y'=yd_125 yd_250 yd_4 yd_10 yd_m10;
matrix rownames f20_`x'_`y'=ym_125 ym_250 ym_4 ym_10 ym_m10;
};
};


forvalues w=1/6{;
foreach x in `vlist2'{; *non market incomes;
forvalues y=1/5{;*market categories;
forvalues z=1/5{;*other income categories;
tempvar g_`x'_`y'_`z';
gen `g_`x'_`y'_`z''=cond(`g_`market''==`y' & `g_`x''==`z',1,0);
sum `g_`x'_`y'_`z'' `wght' if `race`w''==1;
matrix f20_`w'_`x'[`y',`z']=round(r(sum));
};};};};

forvalues x=1/6{;
foreach y in `vlist2'{;
noisily di "Mobility by Socioeconomic Group `race`x''";
noisily matrix list f20_`x'_`y';
noisily matrix list f20_`x'_`y';
noisily matrix list f20_`x'_`y';
};
};
*National Disposable;
putexcel C101=matrix(f20_6_`disposable') using `using',keepcellformat modify sheet("`sheet'") ;
*National Post-Fiscal; 
putexcel C109=matrix(f20_6_`consumable') using `using',keepcellformat modify sheet("`sheet'") ;
*National Final;
putexcel C117=matrix(f20_6_`final') using `using',keepcellformat modify sheet("`sheet'") ;

*Indigenous Disposable;
putexcel C23=matrix(f20_1_`disposable') using `using',keepcellformat modify sheet("`sheet'") ;
*Indigenous Post-Fiscal; 
putexcel C31=matrix(f20_1_`consumable') using `using',keepcellformat modify sheet("`sheet'") ;
*Indigenous Final;
putexcel C39=matrix(f20_1_`final') using `using',keepcellformat modify sheet("`sheet'") ;

*White Disposable;
putexcel C49=matrix(f20_2_`disposable') using `using',keepcellformat modify sheet("`sheet'") ;
*White Post-Fiscal; 
putexcel C57=matrix(f20_2_`consumable') using `using',keepcellformat modify sheet("`sheet'") ;
*White Final;
putexcel C65=matrix(f20_2_`final') using `using',keepcellformat modify sheet("`sheet'") ;

*African Descendant Disposable;
putexcel C75=matrix(f20_3_`disposable') using `using',keepcellformat modify sheet("`sheet'") ;
*African Descendant Post-Fiscal; 
putexcel C83=matrix(f20_3_`consumable') using `using',keepcellformat modify sheet("`sheet'") ;
*African Descendant Final;
putexcel C91=matrix(f20_3_`final') using `using',keepcellformat modify sheet("`sheet'") ;

*Others Disposable;
putexcel C127=matrix(f20_4_`disposable') using `using',keepcellformat modify sheet("`sheet'") ;
*Others Post-Fiscal; 
putexcel C135=matrix(f20_4_`consumable') using `using',keepcellformat modify sheet("`sheet'") ;
*Others Final;
putexcel C143=matrix(f20_4_`final') using `using',keepcellformat modify sheet("`sheet'") ;

*Non-responses Disposable;
putexcel C153=matrix(f20_5_`disposable') using `using',keepcellformat modify sheet("`sheet'") ;
*Non-responses Post-Fiscal; 
putexcel C161=matrix(f20_5_`consumable') using `using',keepcellformat modify sheet("`sheet'") ;
*Non-responses Final;
putexcel C169=matrix(f20_5_`final') using `using',keepcellformat modify sheet("`sheet'") ;

putexcel A3=`versionprint' using `using', modify sheet("`sheet'") keepcellformat;

	********
	* OPEN *
	********;
	if "`open'"!="" {;
		!start `using'; // doesn't work with "" or `""' so I already changed `open' to "" if using has spaces, ;
	};
};
end;


*******TABLE F21: Education (populations)**************************************************************************;

program define f21_race;
syntax  [if] [in] [pweight/] [using/] [,table(string) Market(varname) race1(varname) race2(varname) race3(varname) race4(varname) race5(varname) OPEN 
		   PL125(string)
			PL250(string)
			PL400(string)
		   age(age) 
		   edpre(varname) 
		   edpri(varname) 
		   edsec(varname) 
		   edter(varname) 
		   hhe(varname) 
		   hhid(varname)
		   redpre(string) 
		   redpri(string) 
		   redsec(string) 
		   redter(string)  ];
di "Education (populations) `'";
local sheet="F21. Education (populations)";
local version 1.0;
local command ceqrace;
local versionprint ("Results produced by version `version' of `command' on `c(current_date)' at `c(current_time)'");

qui{;
  *if `"`weight'"' != "" {;
   *             local wght `"[`weight'`exp']"';
    *    };
	#delimit cr
	cap svydes
	scalar no_svydes = _rc
	tempvar ones
	gen `ones'=1
	if !_rc qui svyset // gets the results saved in return list
	if "`r(wvar)'"=="" & "`exp'"=="" {
		`dit' "Warning: weights not specified in svydes or the command"
		`dit' "Hence, equal weights (simple random sample) assumed"
	}
	else {
		if "`exp'"=="" & "`r(wvar)'"!="" local w `r(wvar)'
		if "`exp'"!="" local w `exp'
		if "`w'"!="" {
			tempvar weightvar
			qui gen `weightvar' = `w'
			local w `weightvar'
		}
		else local w "`ones'"
		
		if "`w'"!="" {
			local pw "[pw = `w']"
			local aw "[aw = `w']"
		}
		if "`exp'"=="" & "`r(wvar)'"!="" {
			local weight "pw"
			local exp "`r(wvar)'"
		}
	}		
	
	#delimit;
		forvalues x=1/5{;
if "`race`x''"==""{;
local cc=`cc'+1;
tempvar race`x';
gen `race`x''=.;
};
}; 
tempvar race6;
gen `race6'=1;

if "`market'"=="" {;
display as error "Must specify Market(varname) option";
exit;
};


local allter=`edpre' +`edpri'+ `edsec';
local totaled=`edpre' +`edpri'+ `edsec'+`edter';
local vlist0  `edpre' `edpri' `edsec' `edter' ;
local vlist1  `edpre' `edpri' `edsec' `allter' `edter' `totaled' ;
local vlist2  `redpre' `redpri' `redsec' `redter' ;

matrix f21=J(6,1,.);

foreach x in `vlist0'{;
local c=0;
foreach y in `r`vlist2''{;
local c=`c'+1;
local range`x'_`c'=`y';
};
};
local rallter `range`edpre'_1' `range`edsec'_2';
local rtotaled `range`edpre'_1' `range`edter'_2';


local vlist3  `redpre' `redpri' `redsec' `rallter' `redter' `rtotaled' ;
foreach x in `vlist3'{;
local c=`c'+1;
matrix f21[`c',1]=`x'; 
};


if "`pl125'"=="" | "`pl250'"=="" | "`pl400'"=="" {;
			display as error "Must specify Poverty lines for 1.25, 2.50 and 4.00 PPP";
			exit;
		};
		
		local pl1000=`pl250'*4;
		local pl5000=`pl250'*20;


tempvar g_`market';
gen `g_`market''=. ;
replace `g_`market''=1 if `market'<`pl125';
replace `g_`market''=2 if `market'>=`pl125' & `market'<`pl250';
replace `g_`market''=3 if `market'>=`pl250' & `market'<`pl400';
replace `g_`market''=4 if `market'>=`pl400' & `market'<`pl1000';
replace `g_`market''=5 if `market'>=`pl1000' & `market'<`pl5000';;
replace `g_`market''=6 if `market'>=`pl5000' & `market'!=.;


foreach x in 1/8{;
tempvar y_`x';
};
gen `y_1'=cond(`g_`market''==1,1,0);
gen `y_2'=cond(`g_`market''==2,1,0);
gen `y_3'=cond(`g_`market''==1 | `g_`market''==2,1,0);
gen `y_4'=cond(`g_`market''==3,1,0);
gen `y_5'=cond(`g_`market''==1 | `g_`market''==2 | `g_`market''==3,1,0);
gen `y_6'=cond(`g_`market''==4,1,0);
gen `y_7'=cond(`g_`market''==5,1,0);
gen `y_8'=cond(`g_`market''==6,1,0);

********************************Target Population***************************;

forvalues x=1/6{;*race;
matrix f21_`x'_1=J(6,8,.);
matrix colnames f21_`x'_1=yd_125 yd_250 yl250 yd_4 yl4 yd_10 yd_50 yd_m10;
matrix rownames f21_`x'_1=pre primary secondary allbuter tertiary total;
};



forvalues w=1/6{;*race;
local c=0;
foreach x in `vlist1'{; *schooling;
local c=`c'+1;
forvalues y=1/8{;*income groups;
tempvar id_`x';
gen `id_`x''=cond(`age'>=`range`x'_1' & `age'<=`range`x'_2',1,0);
sum `id_`x'' `wght' if `race`w''==1 & `y_`y''==`y';
matrix f21_`w'_1[`c',`y']=round(r(sum));
};};};

forvalues x=1/6{;
noisily di "Target Population `race`x''";
noisily matrix list f21_`x'_1;
};
*Age ranges;
putexcel C11=matrix(f21) using `using',keepcellformat modify sheet("`sheet'") ;
putexcel C20=matrix(f21) using `using',keepcellformat modify sheet("`sheet'") ;
putexcel C29=matrix(f21) using `using',keepcellformat modify sheet("`sheet'") ;
putexcel C37=matrix(f21) using `using',keepcellformat modify sheet("`sheet'") ;
putexcel C45=matrix(f21) using `using',keepcellformat modify sheet("`sheet'") ;
putexcel C53=matrix(f21) using `using',keepcellformat modify sheet("`sheet'") ;


*Target Population;
putexcel D11=matrix(f21_6_1) using `using',keepcellformat modify sheet("`sheet'") ;
putexcel D20=matrix(f21_1_1) using `using',keepcellformat modify sheet("`sheet'") ;
putexcel D29=matrix(f21_2_1) using `using',keepcellformat modify sheet("`sheet'") ;
putexcel D37=matrix(f21_3_1) using `using',keepcellformat modify sheet("`sheet'") ;
putexcel D45=matrix(f21_4_1) using `using',keepcellformat modify sheet("`sheet'") ;
putexcel D53=matrix(f21_5_1) using `using',keepcellformat modify sheet("`sheet'") ;

********************************Total Population Attending School***************************;

tempvar national;
gen `national'=1;
local opt `public' `private' `national'; 
forvalues x=1/6{;*race;
foreach y in `opt'{;*schooling option;
matrix f21_`x'_2_`y'=J(6,8,.);
matrix colnames f21_`x'_2_`y'=yd_125 yd_250 yl250 yd_4 yl4 yd_10 yd_50 yd_m10;
matrix rownames f21_`x'_2_`y'=pre primary secondary allbuter tertiary total;
};
};

foreach z in `opt'{;
forvalues w=1/6{;*race;
local c=0;
foreach x in `vlist1'{; *schooling;
local c=`c'+1;
forvalues y=1/8{;*income groups;
tempvar id_`x';
gen `id_`x''=cond(`age'>=`range`x'_1' & `age'<=`range`x'_2',1,0);
sum `x' `wght' if `race`w''==1 & `z'==1 & `y_`y''==`y';
matrix f21_`w'_`z'[`c',`y']=round(r(sum));
};};};};


forvalues x=1/6{;
foreach z in `opt'{;*schooling option;

noisily di "Total population attending school `race`x'', level: `z'";
noisily matrix list f21_`x'_`z';
};
};
*Public School;
putexcel Q11=matrix(f21_6_`public') using `using',keepcellformat modify sheet("`sheet'") ;
putexcel Q39=matrix(f21_1_`public') using `using',keepcellformat modify sheet("`sheet'") ;
putexcel Q67=matrix(f21_2_`public') using `using',keepcellformat modify sheet("`sheet'") ;
putexcel Q95=matrix(f21_3_`public') using `using',keepcellformat modify sheet("`sheet'") ;
putexcel Q123=matrix(f21_4_`public') using `using',keepcellformat modify sheet("`sheet'") ;
putexcel Q151=matrix(f21_5_`public') using `using',keepcellformat modify sheet("`sheet'") ;
*Private School;
putexcel Q20=matrix(f21_6_`private') using `using',keepcellformat modify sheet("`sheet'") ;
putexcel Q48=matrix(f21_1_`private') using `using',keepcellformat modify sheet("`sheet'") ;
putexcel Q76=matrix(f21_2_`private') using `using',keepcellformat modify sheet("`sheet'") ;
putexcel Q104=matrix(f21_3_`private') using `using',keepcellformat modify sheet("`sheet'") ;
putexcel Q132=matrix(f21_4_`private') using `using',keepcellformat modify sheet("`sheet'") ;
putexcel Q160=matrix(f21_5_`private') using `using',keepcellformat modify sheet("`sheet'") ;
*Total private and public School;
putexcel Q29=matrix(f21_6_`national') using `using',keepcellformat modify sheet("`sheet'") ;
putexcel Q57=matrix(f21_1_`national') using `using',keepcellformat modify sheet("`sheet'") ;
putexcel Q85=matrix(f21_2_`national') using `using',keepcellformat modify sheet("`sheet'") ;
putexcel Q113=matrix(f21_3_`national') using `using',keepcellformat modify sheet("`sheet'") ;
putexcel Q141=matrix(f21_4_`national') using `using',keepcellformat modify sheet("`sheet'") ;
putexcel Q169=matrix(f21_5_`national') using `using',keepcellformat modify sheet("`sheet'") ;

putexcel A3=`versionprint' using `using', modify sheet("`sheet'") keepcellformat;

	********
	* OPEN *
	********;
	if "`open'"!="" {;
		!start `using'; // doesn't work with "" or `""' so I already changed `open' to "" if using has spaces, ;
	};
};
end;
*******TABLE F23: Educational Probability**************************************************************************;

program define f23_race;
syntax  [if] [in] [pweight/] [using/] [,table(string) Market(varname) race1(varname) race2(varname) race3(varname) race4(varname) race5(varname) OPEN 
		   PL125(string)
			PL250(string)
			PL400(string)
		   age(age) 
		   edpre(varname) 
		   edpri(varname) 
		   edsec(varname) 
		   edter(varname) 
		   hhe(varname) 
		   hhid(varname)
		   redpre(string) 
		   redpri(string) 
		   redsec(string) 
		   redter(string)  ];
di "Educational Probability `'";
local sheet="F23. Educational Probability";
local version 1.0;
local command ceqrace;
local versionprint ("Results produced by version `version' of `command' on `c(current_date)' at `c(current_time)'");

qui{;
tempfile temp1;
   *if `"`weight'"' != "" {;
   *             local wght `"[`weight'`exp']"';
    *    };
	#delimit cr
	cap svydes
	scalar no_svydes = _rc
	tempvar ones
	gen `ones'=1
	if !_rc qui svyset // gets the results saved in return list
	if "`r(wvar)'"=="" & "`exp'"=="" {
		`dit' "Warning: weights not specified in svydes or the command"
		`dit' "Hence, equal weights (simple random sample) assumed"
	}
	else {
		if "`exp'"=="" & "`r(wvar)'"!="" local w `r(wvar)'
		if "`exp'"!="" local w `exp'
		if "`w'"!="" {
			tempvar weightvar
			qui gen `weightvar' = `w'
			local w `weightvar'
		}
		else local w "`ones'"
		
		if "`w'"!="" {
			local pw "[pw = `w']"
			local aw "[aw = `w']"
		}
		if "`exp'"=="" & "`r(wvar)'"!="" {
			local weight "pw"
			local exp "`r(wvar)'"
		}
	}		
	
	#delimit;
		forvalues x=1/5{;
if "`race`x''"==""{;
local cc=`cc'+1;
tempvar race`x';
gen `race`x''=.;
};
}; 
tempvar race6;
gen `race6'=1;

if "`market'"=="" {;
display as error "Must specify Market(varname) option";
exit;
};
if "`hhead'"=="" {;
display as error "Must specify HHEad(varname) option";
exit;
};


local allter=`edpre' +`edpri'+ `edsec';
local totaled=`edpre' +`edpri'+ `edsec'+`edter';
local vlist0  `edpre' `edpri' `edsec' `edter' ;
local vlist1  `edpre' `edpri' `edsec' `allter' `edter' `totaled' ;
local vlist2  `redpre' `redpri' `redsec' `redter' ;

matrix f23=J(6,1,.);

foreach x in `vlist0'{;
local c=0;
foreach y in `r`vlist2''{;
local c=`c'+1;
local range`x'_`c'=`y';
};
};
local rallter `range`edpre'_1' `range`edsec'_2';
local rtotaled `range`edpre'_1' `range`edter'_2';


local vlist3  `redpre' `redpri' `redsec' `rallter' `redter' `rtotaled' ;
foreach x in `vlist3'{;
local c=`c'+1;
matrix f23[`c',1]=`x'; 
};



foreach x in `vlist1'{; *schooling;
local c=`c'+1;
tempvar id1_`x';
gen `id1_`x''=cond(`age'>=`range`x'_1' & `age'<=`range`x'_2',1,0);
tempvar tot_id_`x';
egen `tot_id1_`x''=sum(`id1_`x'') , by(`hhid');
tempvar id2_`x';
gen `id2_`x''=cond((`age'>=`range`x'_1' & `age'<=`range`x'_2') & `x'==1,1,0);
tempvar tot_id2_`x';
egen `tot_id2_`x''=sum(`id2_`x'') , by(`hhid');
tempvar net_`x';
gen `net_`x''=`tot_id2_`x''/`tot_id1_`x'';
tempvar id3_`x';
gen `id3_`x''=cond(`x'==1,1,0);
tempvar tot_id3_`x';
egen `tot_id3_`x''=sum(`id3_`x'') , by(`hhid');
tempvar gross_`x';
gen `gross_`x''=`tot_id3_`x''/`tot_id1_`x'';
};

keep if `hhead'==1;


		if "`pl125'"=="" | "`pl250'"=="" | "`pl400'"=="" {;
			display as error "Must specify Poverty lines for 1.25, 2.50 and 4.00 PPP";
			exit;
		};
		
		local pl1000=`pl250'*4;
		local pl5000=`pl250'*20;
tempvar g_`market';
gen `g_`market''=. ;
replace `g_`market''=1 if `market'<`pl125';
replace `g_`market''=2 if `market'>=`pl125' & `market'<`pl250';
replace `g_`market''=3 if `market'>=`pl250' & `market'<`pl400';
replace `g_`market''=4 if `market'>=`pl400' & `market'<`pl1000';
replace `g_`market''=5 if `market'>=`pl1000' & `market'<`pl5000';;
replace `g_`market''=6 if `market'>=`pl5000' & `market'!=.;


foreach x in 1/8{;
tempvar y_`x';
};
gen `y_1'=cond(`g_`market''==1,1,0);
gen `y_2'=cond(`g_`market''==2,1,0);
gen `y_3'=cond(`g_`market''==1 | `g_`market''==2,1,0);
gen `y_4'=cond(`g_`market''==3,1,0);
gen `y_5'=cond(`g_`market''==1 | `g_`market''==2 | `g_`market''==3,1,0);
gen `y_6'=cond(`g_`market''==4,1,0);
gen `y_7'=cond(`g_`market''==5,1,0);
gen `y_8'=cond(`g_`market''==6,1,0);

********************************Net and Gross Educational Probability***************************;

forvalues x=1/6{;*race;
forvalues y=1/2{;
matrix f23_`x'_`y'=J(6,8,.);
matrix colnames f23_`x'_`y'=yd_125 yd_250 yl250 yd_4 yl4 yd_10 yd_50 yd_m10;
matrix rownames f23_`x'_`y'=pre primary secondary allbuter tertiary total;
};
};


forvalues w=1/6{;*race;
local c=0;
foreach x in `vlist1'{; *schooling;
local c=`c'+1;
forvalues y=1/8{;*income groups;
sum `net_`x'' `wght' if `race`w''==1 & `y_`y''==`y';
matrix f23_`w'_1[`c',`y']=r(mean);
sum `gross_`x'' `wght' if `race`w''==1 & `y_`y''==`y';
matrix f23_`w'_2[`c',`y']=r(mean);

};};};

forvalues x=1/6{;
forvalues y=1/2{;

noisily di "Educational Probability `race`x'' 1=Net, 2=Gross";
noisily matrix list f23_`x'_`y';
};
};
*Age ranges;
putexcel C11=matrix(f23) using `using',keepcellformat modify sheet("`sheet'") ;
putexcel C20=matrix(f23) using `using',keepcellformat modify sheet("`sheet'") ;
putexcel C29=matrix(f23) using `using',keepcellformat modify sheet("`sheet'") ;
putexcel C38=matrix(f23) using `using',keepcellformat modify sheet("`sheet'") ;



*Net Educational Probability;
putexcel D11=matrix(f23_6_1) using `using',keepcellformat modify sheet("`sheet'") ;
putexcel D20=matrix(f23_1_1) using `using',keepcellformat modify sheet("`sheet'") ;
putexcel D29=matrix(f23_2_1) using `using',keepcellformat modify sheet("`sheet'") ;
putexcel D38=matrix(f23_3_1) using `using',keepcellformat modify sheet("`sheet'") ;

*Gross Educational Probability;
putexcel Q11=matrix(f23_6_2) using `using',keepcellformat modify sheet("`sheet'") ;
putexcel Q20=matrix(f23_1_2) using `using',keepcellformat modify sheet("`sheet'") ;
putexcel Q29=matrix(f23_2_2) using `using',keepcellformat modify sheet("`sheet'") ;
putexcel Q38=matrix(f23_3_2) using `using',keepcellformat modify sheet("`sheet'") ;

putexcel A3=`versionprint' using `using', modify sheet("`sheet'") keepcellformat;

	********
	* OPEN *
	********;
	if "`open'"!="" {;
		!start `using'; // doesn't work with "" or `""' so I already changed `open' to "" if using has spaces, ;
	};
};
end;

*******TABLE F24: Infraestructure Access**************************************************************************;
program define f24_race;

syntax   [if] [in] [pweight/] [aw iw fw] [,table(string) Market(varname) race1(varname) race2(varname) race3(varname) race4(varname) race5(varname) OPEN
		   PL125(string)
			PL250(string)
			PL400(string)
		   hhe(varname) 
		   hhid(varname)
		   water(varname)
		   electricity(varname)
		   walls(varname)
		   floors(varname)
		   roof(varname)
		   sewage(varname)
		   roads(varname)
		   		   ];
	di "F24. Infrastructure Access";
	local sheet="F24. Infrastructure Access";
	local version 1.0;
	local command ceqrace;
	local versionprint ("Results produced by version `version' of `command' on `c(current_date)' at `c(current_time)'");

qui{;
   *if `"`weight'"' != "" {;
   *             local wght `"[`weight'`exp']"';
    *    };
	#delimit cr
	cap svydes
	scalar no_svydes = _rc
	tempvar ones
	gen `ones'=1
	if !_rc qui svyset // gets the results saved in return list
	if "`r(wvar)'"=="" & "`exp'"=="" {
		`dit' "Warning: weights not specified in svydes or the command"
		`dit' "Hence, equal weights (simple random sample) assumed"
	}
	else {
		if "`exp'"=="" & "`r(wvar)'"!="" local w `r(wvar)'
		if "`exp'"!="" local w `exp'
		if "`w'"!="" {
			tempvar weightvar
			qui gen `weightvar' = `w'
			local w `weightvar'
		}
		else local w "`ones'"
		
		if "`w'"!="" {
			local pw "[pw = `w']"
			local aw "[aw = `w']"
		}
		if "`exp'"=="" & "`r(wvar)'"!="" {
			local weight "pw"
			local exp "`r(wvar)'"
		}
	}		
	
	#delimit;
		forvalues x=1/5{;
		if "`race`x''"==""{;
			local cc=`cc'+1;
			tempvar race`x';
			gen `race`x''=.;
		};
		}; 
	tempvar race6;
	gen `race6'=1;
	


	if "`market'"=="" {;
		display as error "Must specify Market(varname) option";
	exit;
	};

		if "`pl125'"=="" | "`pl250'"=="" | "`pl400'"=="" {;
		display as error "Must specify Poverty lines for 1.25, 2.50 and 4.00 PPP";
		exit;
		};
	if "`hhe'"=="" | "`hhid'"==""{;
		display as error "Must specify who is the household head and the household ID";
		exit;
		};
				
	local pl1000=`pl250'*4;
	local pl5000=`pl250'*20;
	
	*Race of the household head;
	tempvar racehh1;
	gen `racehh1'=.;
	forvalues x=1/5{
		replace `racehh'= `x' if `race`x''==1 & `hhe'==1;
		};	
	tempvar racehh;
	*Race of the household;
	egen `racehh'=mean(`racehh'),by(`hhid');
	
	local vlist  `water' `electricity' `walls' `floors' `roof' `sewage' `roads';
	local vlist1  water electricity walls floors roof sewage roads;
	
	foreach x in `vlist1'{;//make sure variable exists;
		if "``x''"==""{;
			tempvar `x';
			gen ``x''=.;
		};
	};
	
	tempvar g_m;
	gen `g_m'=. ;
	replace `g_m'=1 if `market'<`pl125';
	replace `g_m'=2 if `market'>=`pl125' & `market'<`pl250';
	replace `g_m'=3 if `market'>=`pl250' & `market'<`pl400';
	replace `g_m'=4 if `market'>=`pl400' & `market'<`pl1000';
	replace `g_m'=5 if `market'>=`pl1000' & `market'<`pl5000';
	replace `g_m'=6 if `market'>=`pl5000';
	
	*Variables for total benefits;
	forvalues x=1/11{;
	tempvar g_m_`x';
	};
	gen `g_m_1'=cond(`market'<`pl125',1,0);
	gen `g_m_2'=cond(`market'>=`pl125' & `market'<`pl250',1,0);
	gen `g_m_3'=cond(`market'<`pl250',1,0);
	gen `g_m_4'=cond(`market'>=`pl250' & `market'<`pl400',1,0);
	gen `g_m_5'=cond(`market'<`pl400',1,0);
	gen `g_m_6'=cond(`market'>=`pl400' & `market'<`pl1000',1,0);
	gen `g_m_7'=cond(`market'>=`pl1000' & `market'<`pl5000',1,0);
	gen `g_m_8'=cond(`market'>=`pl5000' & `market'!=.,1,0);
	gen `g_m_9'=cond(`market'>=`pl1000' & `market'!=.,1,0);
	gen `g_m_10'=cond(`market'>=`pl400' & `market'!=.,1,0);
	gen `g_m_11'=1;
	
	*Results for individuals;
	*Population;

	matrix f24_p=J(11,6,.);
	matrix colnames f24_p=national indig white african other nonresp;
	matrix rownames f24_p=yL125 yM125L250 yL250 yM250L400 yL400 yM400L1000 yM1000L5000 yM5000 YM1000 YM4000 YT;
	
			
	tempvar tot;
	gen `tot'=1;
	
	forvalues y=1/11{;//Sociodemographic group;
	summ `tot' `wght' if `g_m_`y''==1;
	matrix f24_p[`y',1]=r(sum);
	
	local c=1;
	forvalues x=1/5{;//Race;
		summ `tot' `wght' if `g_m_`y''==1 & `race`x''==1;
		local c=`c'+1;
		matrix f24_p[`y',`c']=r(sum);
		};
	};
	
	*National;
	putexcel D21=matrix(f24_p) using `using',keepcellformat modify sheet("`sheet'") ;
	

	*Results for Households;
	*Households;
	preserve;
	keep if `hhe'==1;//Keep only the household head;
	matrix f24_h=J(11,6,.);
	matrix colnames f24_h=national indig white african other nonresp;
	matrix rownames f24_h=yL125 yM125L250 yL250 yM250L400 yL400 yM400L1000 yM1000L5000 yM5000 YM1000 YM4000 YT;
				
	tempvar tot;
	gen `tot'=1;
	forvalues y=1/11{;//Sociodemographic group;
	summ `tot' `wght' if `g_m_`y''==1;
	matrix f24_h[`y',1]=r(sum);
	
	local c=1;
	forvalues x=1/5{;//Race;
		summ `tot' `wght' if `g_m_`y''==1 & `race`x''==1;
		local c=`c'+1;
		matrix f24_h[`y',`c']=r(sum);
	};
	};
	*National;
	putexcel D27=matrix(f24_h) using `using',keepcellformat modify sheet("`sheet'") ;
	
	restore;
	
	
	foreach z in `vlist'{;
	local nz=`nz'+1;
		if "`z'"==""{;
			tempvar "``z''";
			gen ``z''=.;
		};
		
		*Weighted households: Beneficiaries;
		tempvar d_b_`z';
		gen `d_b_`z''=cond(`z'==1,1,0);
		replace `d_b_`z''=. if `z'==.;
		*Households;
		tempvar hh_b_`z';
		gen `hh_b_`z''=`d_b_`z'';
		replace `hh_b_`z''=. if `hhe'!=1;
		
		
	*****Beneficiaries Matrices;
		*Weighted households;
		matrix f24_`z'_w=J(11,6,.);
		matrix colnames f24_`z'_w=national indig white african other nonresp;
		matrix rownames f24_`z'_w=yL125 yM125L250 yL250 yM250L400 yL400 yM400L1000 yM1000L5000 yM5000 YM1000 YM4000 YT;
		
		*Households;
		matrix f24_`z'_h=J(11,6,.);
		matrix colnames f24_`z'_h=national indig white african other nonresp;
		matrix rownames f24_`z'_h=yL125 yM125L250 yL250 yM250L400 yL400 yM400L1000 yM1000L5000 yM5000 YM1000 YM4000 YT;
	
	
	
	
	 forvalues x=1/11{;//groups of income;
		*Households;
		summ `hh_b_`z'' `wght' if `g_m_`x''==1 & `hhid'==1;
		matrix f24_`z'_h[1,`x']=r(sum);
		*Weighted households;
		summ `d_b_`z'' `wght' if `g_m_`x''==1;
		matrix f24_`z'_w[1,`x']=r(sum);
		
		local c=1;
		forvalues y=1/5{;//Ethnic groups;	
			local c=`c'+1;
			*Households;
			summ `hh_b_`z'' `wght' if `g_m_`x''==1 & `race`y''==1  & `hhid'==1;
			matrix f24_`z'_h[`c',`x']=r(sum);
			*Weighted households;			
			summ `d_b_`z'' `wght' if `g_m_`x''==1 & `race`y''==1;
			matrix f24_`z'_w[`c',`x']=r(sum);
	};
	};	
	noisily di "Total Beneficiaries Households: `z'";
	noisily matrix list 24_`z'_h;
	noisily di "Total Beneficiaries Weighted Households: `z'";
	noisily matrix list 24_`z'_w;
	if `nz'==1	putexcel D39=matrix(f24_`z'_h) using `using',keepcellformat modify sheet("`sheet'") ;
	if `nz'==2	putexcel D73=matrix(f24_`z'_h) using `using',keepcellformat modify sheet("`sheet'") ;
	if `nz'==3	putexcel D107=matrix(f24_`z'_h) using `using',keepcellformat modify sheet("`sheet'") ;
	if `nz'==4	putexcel D141=matrix(f24_`z'_h) using `using',keepcellformat modify sheet("`sheet'") ;
	if `nz'==5	putexcel D175=matrix(f24_`z'_h) using `using',keepcellformat modify sheet("`sheet'") ;
	if `nz'==6	putexcel D209=matrix(f24_`z'_h) using `using',keepcellformat modify sheet("`sheet'") ;
	if `nz'==7	putexcel D243=matrix(f24_`z'_h) using `using',keepcellformat modify sheet("`sheet'") ;
	
	if `nz'==1	putexcel D45=matrix(f24_`z'_w) using `using',keepcellformat modify sheet("`sheet'") ;
	if `nz'==2	putexcel D79=matrix(f24_`z'_w) using `using',keepcellformat modify sheet("`sheet'") ;
	if `nz'==3	putexcel D113=matrix(f24_`z'_w) using `using',keepcellformat modify sheet("`sheet'") ;
	if `nz'==4	putexcel D147=matrix(f24_`z'_w) using `using',keepcellformat modify sheet("`sheet'") ;
	if `nz'==5	putexcel D181=matrix(f24_`z'_w) using `using',keepcellformat modify sheet("`sheet'") ;
	if `nz'==6	putexcel D215=matrix(f24_`z'_w) using `using',keepcellformat modify sheet("`sheet'") ;
	if `nz'==7	putexcel D249=matrix(f24_`z'_w) using `using',keepcellformat modify sheet("`sheet'") ;
	
	putexcel A3=`versionprint' using `using', modify sheet("`sheet'") keepcellformat;
		};
	
	********
	* OPEN *
	********;
	if "`open'"!="" {;
		!start `using'; // doesn't work with "" or `""' so I already changed `open' to "" if using has spaces, ;
	};	
};

end;

*******TABLE F25: Theil Decomposition**************************************************************************;

program define f25_race;
syntax  [if] [in] [pweight/] [using/] [,table(string) Market(varname) race1(varname) race2(varname) race3(varname) race4(varname) race5(varname) OPEN 
		   Netmarket(varname) 
		   MPLUSPensions(varname)
		   Gross(varname)
		   TAXABle(varname)
		   Disposable(varname) 
		   Postfiscal(varname) 
		   FStar(varname)
		   Consumable(varname)
		   Final(varname)  
		   gender(varname)
		   urban(varname)
           edpar(varname)
		  ];
di "F25. Theil Decomposition";
local sheet="F25. Theil Decomposition";
local version 1.0;
local command ceqrace;
local versionprint ("Results produced by version `version' of `command' on `c(current_date)' at `c(current_time)'");

qui{;
cap ssc install ineqdeco;

   *if `"`weight'"' != "" {;
   *             local wght `"[`weight'`exp']"';
    *    };
	#delimit cr
	cap svydes
	scalar no_svydes = _rc
	tempvar ones
	gen `ones'=1
	if !_rc qui svyset // gets the results saved in return list
	if "`r(wvar)'"=="" & "`exp'"=="" {
		`dit' "Warning: weights not specified in svydes or the command"
		`dit' "Hence, equal weights (simple random sample) assumed"
	}
	else {
		if "`exp'"=="" & "`r(wvar)'"!="" local w `r(wvar)'
		if "`exp'"!="" local w `exp'
		if "`w'"!="" {
			tempvar weightvar
			qui gen `weightvar' = `w'
			local w `weightvar'
		}
		else local w "`ones'"
		
		if "`w'"!="" {
			local pw "[pw = `w']"
			local aw "[aw = `w']"
		}
		if "`exp'"=="" & "`r(wvar)'"!="" {
			local weight "pw"
			local exp "`r(wvar)'"
		}
	}		
	
	#delimit;
		forvalues x=1/5{;
if "`race`x''"==""{;
local cc=`cc'+1;
tempvar race`x';
gen `race`x''=.;
};
};
if "`edpar'"==""{;

tempvar edpar;
gen `edpar'=.;
};

*Race involves every group that has no ethnicity;
tempvar race;
gen `race'=.;
replace `race'=0 if `race1'==1;
replace `race'=1 if `race2'==1 | `race3'==1 | `race4'==1;

if "`market'"=="" {;
display as error "Must specify Market(varname) option";
exit;
};


	local incomes `market' `mpluspensions' `netmarket' `gross' `taxable' `disposable' `consumable' `final';

foreach x in `incomes'{;
matrix f25_`x'=J(4,1,.);
matrix colnames f25_`x'="Portion of Theil";
matrix rownames f25_`x'=race gender urban edpar;
};
local vlist `race' `gender' `urban' `edpar';

foreach x in `incomes'{;
ineqdeco `x' `wght';
matrix f25_`x'[1,1]=r(ge1);
local c=1;
foreach y in `vlist'{;
local c=`c'+1;
ineqdeco `x' `wght',by(`vlist');
matrix f25_`x'[`c',1]=r(between_ge1);
};
};

local L`market'="C";
local L`mpluspensions'="E" `netmarket' `gross' `taxable' `disposable' `consumable' `final'
local L`netmarket'="G";
local L`gross'="I";
local L`taxable'="K";
local L`disposable'="M";
local L`consumable'="O";
local L`final'="Q";

foreach x in `incomes'{;

noisily di "Theil `x'";
noisily matrix list f25_`x';


putexcel `L`x''8=matrix(f25_`x') using `using',keepcellformat modify sheet("`sheet'") ;
};
putexcel A3=`versionprint' using `using', modify sheet("`sheet'") keepcellformat;

	********
	* OPEN *
	********;
	if "`open'"!="" {;
		!start `using'; // doesn't work with "" or `""' so I already changed `open' to "" if using has spaces, ;
	};
};
end;

*******TABLE F26: Inequality of Opportunity**************************************************************************;

program define f26_race;
syntax  [if] [in] [pweight/] [using/] [,table(string) Market(varname) race1(varname) race2(varname) race3(varname) race4(varname) race5(varname) OPEN 
		   Netmarket(varname) 
		   MPLUSPensions(varname)
		   Gross(varname)
		   TAXABle(varname)
		   Disposable(varname) 
		   Postfiscal(varname) 
		   FStar(varname)
		   Consumable(varname)
		   Final(varname)  
		   gender(varname)
		   urban(varname)
           edpar(varname)
		  ];
di "IneqOfOpportunity `'";
local sheet="F26. IneqOfOpportunity";
local version 1.0;
local command ceqrace;
local versionprint ("Results produced by version `version' of `command' on `c(current_date)' at `c(current_time)'");

qui{;
cap ssc install ceq;

   *if `"`weight'"' != "" {;
   *             local wght `"[`weight'`exp']"';
    *    };
	#delimit cr
	cap svydes
	scalar no_svydes = _rc
	tempvar ones
	gen `ones'=1
	if !_rc qui svyset // gets the results saved in return list
	if "`r(wvar)'"=="" & "`exp'"=="" {
		`dit' "Warning: weights not specified in svydes or the command"
		`dit' "Hence, equal weights (simple random sample) assumed"
	}
	else {
		if "`exp'"=="" & "`r(wvar)'"!="" local w `r(wvar)'
		if "`exp'"!="" local w `exp'
		if "`w'"!="" {
			tempvar weightvar
			qui gen `weightvar' = `w'
			local w `weightvar'
		}
		else local w "`ones'"
		
		if "`w'"!="" {
			local pw "[pw = `w']"
			local aw "[aw = `w']"
		}
		if "`exp'"=="" & "`r(wvar)'"!="" {
			local weight "pw"
			local exp "`r(wvar)'"
		}
	}		
	
	#delimit;
		forvalues x=1/5{;
if "`race`x''"==""{;
local cc=`cc'+1;
tempvar race`x';
gen `race`x''=.;
};
};
*Race involves every group that has no ethnicity;
tempvar race;
gen `race'=.;
replace `race'=0 if `race1'==1;
replace `race'=1 if `race2'==1 | `race3'==1 | `race4'==1;
local vlist0=`gender' `urban' `race';

foreach x in `vlist0'{;
if "`x'"==""{;
tempvar `x';
gen ``x''=.;
};
};

tempvar rural;
gen `rural'=cond(`urban'==1,0,1);
tempvar gender_rural;
gen `gender_rural'=`gender' + `rural';

local vlist=`gender' `rural' `race' `gender_rural';
if "`market'"=="" {;
display as error "Must specify Market(varname) option";
exit;
};


local incomes `market' `mpluspensions' `netmarket' `gross' `taxable' `disposable' `consumable' `final';

oppincidence `incomes' `wght',groupby(`vlist');

matrix f26_1=r(levels);
matrix f26_2=r(ratios);
noisily di "Levels"; 
noisily matrix list f26_1;
noisily di "Ratios";
noisily matrix list f26_2;


putexcel C9=matrix(f26_1) using `using',keepcellformat modify sheet("`sheet'") ;
putexcel C21=matrix(f26_2) using `using',keepcellformat modify sheet("`sheet'") ;
putexcel A3=`versionprint' using `using', modify sheet("`sheet'") keepcellformat;

	********
	* OPEN *
	********;
	if "`open'"!="" {;
		!start `using'; // doesn't work with "" or `""' so I already changed `open' to "" if using has spaces, ;
	};
};
end;

*******TABLE F27: Significance**************************************************************************;


program define f27_race;
syntax  [if] [in] [pweight/] [using/] [,table(string) Market(varname) race1(varname) race2(varname) race3(varname) race4(varname) race5(varname) OPEN 
		   Netmarket(varname) 
		   MPLUSPensions(varname)
		   Gross(varname)
		   TAXABle(varname)
		   Disposable(varname) 
		   Postfiscal(varname) 
		   FStar(varname)
		   Consumable(varname)
		   Final(varname)  
		   psu(varname)   
		   strata(varname) 
		   PL250(string)
		   PL400(string)
		  ];
	di "F27. Significance";
	local sheet="F27. Significance";
	local version 1.0;
	local command ceqrace;
	local versionprint ("Results produced by version `version' of `command' on `c(current_date)' at `c(current_time)'");

	
	 *if `"`weight'"' != "" {;
   *             local wght `"[`weight'`exp']"';
    *    };
	#delimit cr
	cap svydes
	scalar no_svydes = _rc
	tempvar ones
	gen `ones'=1
	if !_rc qui svyset // gets the results saved in return list
	if "`r(wvar)'"=="" & "`exp'"=="" {
		`dit' "Warning: weights not specified in svydes or the command"
		`dit' "Hence, equal weights (simple random sample) assumed"
	}
	else {
		if "`exp'"=="" & "`r(wvar)'"!="" local w `r(wvar)'
		if "`exp'"!="" local w `exp'
		if "`w'"!="" {
			tempvar weightvar
			qui gen `weightvar' = `w'
			local w `weightvar'
		}
		else local w "`ones'"
		
		if "`w'"!="" {
			local pw "[pw = `w']"
			local aw "[aw = `w']"
		}
		if "`exp'"=="" & "`r(wvar)'"!="" {
			local weight "pw"
			local exp "`r(wvar)'"
		}
	}		
	
	#delimit;
		
***Svy options;
	cap svydes;
	scalar no_svydes = (c(rc)!=0);
	qui svyset;
	if "`r(wvar)'"=="" & "`exp'"=="" {;
		di as text "WARNING: weights not specified in svydes or the ceqrace command";
		di as text "Hence, equal weights (simple random sample) assumed";
	};
	else if "`r(su1)'"=="" & "`psu'"=="" {;
		di as text "WARNING: primary sampling unit not specified in svydes or the ceqrace command's psu() option";
		di as text "P-values will be incorrect if sample was stratified";
	};
	if "`psu'"=="" & "`r(su1)'"!="" {;
		local psu `r(su1)';
	};
	if "`strata'"=="" & "`r(strata1)'"!="" {;
		local strata `r(strata1)';
	};
	if "`exp'"=="" & "`r(wvar)'"!="" {;
		local weight "pw";
		local exp "= `r(wvar)'";
	};
	if "`strata'"!="" {;
		local opt strata(`strata');
	};
	* now set it:;
	if "`exp'"!="" qui svyset `psu' [`weight' `exp'], `opt';
	else           qui svyset `psu', `opt'		;
		
		

	forvalues x=1/5{;
		if "`race`x''"==""{;
			local cc=`cc'+1;
			tempvar race`x';
			gen `race`x''=.;
		};
	};
	tempvar race6;
	gen `race6'=1;
	
	if "`market'"=="" {;
		display as error "Must specify Market(varname) option";
		exit;
	};


	local incomes `market' `mpluspensions' `netmarket' `gross' `taxable' `disposable' `consumable' `final';
	di `incomes';
	local races `race1' `race2' `race3' `race4' `race5' `race6';
	foreach x in `incomes'{;
	matrix f27_`x'_p250=J(6,6,.);
	matrix colnames f27_`x'_p250=indig white african other nonresp national ;
	matrix rownames f27_`x'_p250=indig white african other nonresp national ;
	matrix f27_`x'_p400=J(6,6,.);
	matrix colnames f27_`x'_p400=indig white african other nonresp national ;
	matrix rownames f27_`x'_p400=indig white african other nonresp national ;
	matrix f27_`x'_g=J(6,6,.);
	matrix colnames f27_`x'_g=indig white african other nonresp national ;
	matrix rownames f27_`x'_g=indig white african other nonresp national ;
	matrix f27_`x'_t=J(6,6,.);
	matrix colnames f27_`x'_t=indig white african other nonresp national ;
	matrix rownames f27_`x'_t=indig white african other nonresp national ;
	
	foreach y in `races'{;
	tempvar rr_`x'_`y';
	gen `rr_`x'_`y''=`x'*`y';
		};};
	
	*Indicators;
	foreach x in `incomes'{;
	local c=`c'+1;
	foreach y in `races'{;
	foreach z in `races'{;
	noisily difgt `rr_`x'_`z'' `rr_`x'_`y'', pline1(`pl250') pline2(`pl250') test(0);//$2.5ppp;
	matrix dr=e(di);
	local d_m=dr[1,1];
	local d_e=dr[1,2];
	local t=`d_m'/`d_e';
	if `t'>0{;
	local v=normalden(1-`t');
	};
	else{;
	local v=normalden(`t');
	};
	matrix f27_`x'_p250[`z',`y']=`v'; 
	
	noisily difgt `rr_`x'_`z'' `rr_`x'_`y'', pline1(`pl400') pline2(`pl400') test(0);//$4ppp;
	matrix dr=e(di);
	local d_m=dr[1,1];
	local d_e=dr[1,2];
	local t=`d_m'/`d_e';
	if `t'>0{;
	local v=normalden(1-`t');
	};
	else{;
	local v=normalden(`t');
	};
	matrix f27_`x'_p400[`z',`y']=`v'; 
	
	noisily digini `rr_`x'_`z'' `rr_`x'_`y'',  test(0);//GINI;
	matrix dr=e(di);
	local d_m=dr[1,1];
	local d_e=dr[1,2];
	local t=`d_m'/`d_e';
	if `t'>0{;
	local v=normalden(1-`t');
	};
	else{;
	local v=normalden(`t');
	};
	matrix f27_`x'_g[`z',`y']=`v'; 
	
	noisily dientropy `rr_`x'_`z'' `rr_`x'_`y'',  test(0);//Theil;
	matrix dr=e(di);
	local d_m=dr[1,1];
	local d_e=dr[1,2];
	local t=`d_m'/`d_e';
	if `t'>0{;
	local v=normalden(1-`t');
	};
	else{;
	local v=normalden(`t');
	};
	matrix f27_`x'_t[`z',`y']=`v';
	
	};
	if `c'==1 {;
	putexcel C13=matrix(f27_`x'_p250) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel C33=matrix(f27_`x'_p400) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel C53=matrix(f27_`x'_g) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel C74=matrix(f27_`x'_g) using `using',keepcellformat modify sheet("`sheet'") ;
	};
	if `c'==2 {;
	putexcel K13=matrix(f27_`x'_p250) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel K33=matrix(f27_`x'_p400) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel K53=matrix(f27_`x'_g) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel K74=matrix(f27_`x'_g) using `using',keepcellformat modify sheet("`sheet'") ;
	};
	if `c'==3 {;
	putexcel S13=matrix(f27_`x'_p250) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel S33=matrix(f27_`x'_p400) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel S53=matrix(f27_`x'_g) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel S74=matrix(f27_`x'_g) using `using',keepcellformat modify sheet("`sheet'") ;
	};
	if `c'==4 {;
	putexcel AA13=matrix(f27_`x'_p250) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel AA33=matrix(f27_`x'_p400) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel AA53=matrix(f27_`x'_g) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel AA74=matrix(f27_`x'_g) using `using',keepcellformat modify sheet("`sheet'") ;
	};
	if `c'==5 {;
	putexcel C22=matrix(f27_`x'_p250) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel C42=matrix(f27_`x'_p400) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel C62=matrix(f27_`x'_g) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel C83=matrix(f27_`x'_g) using `using',keepcellformat modify sheet("`sheet'") ;
	};
	if `c'==6 {;
	putexcel K22=matrix(f27_`x'_p250) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel K42=matrix(f27_`x'_p400) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel K62=matrix(f27_`x'_g) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel K83=matrix(f27_`x'_g) using `using',keepcellformat modify sheet("`sheet'") ;
	};
	if `c'==7 {;
	putexcel S22=matrix(f27_`x'_p250) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel S42=matrix(f27_`x'_p400) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel S62=matrix(f27_`x'_g) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel S83=matrix(f27_`x'_g) using `using',keepcellformat modify sheet("`sheet'") ;
	};
	if `c'==8 {;
	putexcel AA22=matrix(f27_`x'_p250) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel AA42=matrix(f27_`x'_p400) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel AA62=matrix(f27_`x'_g) using `using',keepcellformat modify sheet("`sheet'") ;
	putexcel AA83=matrix(f27_`x'_g) using `using',keepcellformat modify sheet("`sheet'") ;
	};
	putexcel A3=`versionprint' using `using', modify sheet("`sheet'") keepcellformat;
	

	
		};};};
		
	********
	* OPEN *
	********;
	if "`open'"!="" {;
		!start `using'; // doesn't work with "" or `""' so I already changed `open' to "" if using has spaces, ;
	};
		end;