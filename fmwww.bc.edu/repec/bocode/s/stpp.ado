*! version 1.3.4 2025-01-18
  
program define stpp, rclass sortpreserve
  version 16.0
  syntax newvarlist(max=1) using/                                       ///
                                                                        ///
                   [if] [in]                                            ///
                   ,                                                    ///
                   AGEDiag(varname)                                     ///
                   DATEDiag(varname)                                    ///
                   [                                                    /// 
                   ALLCause(namelist max=1)                             ///
                   BY(varlist)                                          ///
                   CONTrast(passthru)                                   ///
                   CRUDEProb(namelist min=1 max=2)                      ///
                   DEATHProb                                            ///
                   DISPLay(string)                                      ///
                   dropexpected                                         ///
                   EDerer2                                              ///
                   FH                                                   ///
                   FRame(string)                                        ///
                   LEVel(real `c(level)')                               ///
                   INCCENS                                              ///
                   INDWeights(varname)                                  ///
                   LIST(numlist ascending >=0)                          ///
                   MINEXPsurv(string)                                   ///
                   PMAGE(string)                                        ///
                   PMOTHER(string)                                      ///
                   PMRATE(string)                                       ///
                   PMYEAR(string)                                       ///
                   pmmaxage(real 99)                                    ///
                   pmmaxyear(real 10000)                                ///
                   POPmort2(string)                                     ///
                   STANDSTrata(varname)                                 ///            
                   STANDWeights(numlist >=0 <=1)                        ///
                   USING2(string)                                       ///
                   VERBOSE                                              ///
                   GRAPHName(string)                                    /// 
                   GRAPH                                                ///	
                   GRAPHCode(string)                                    ///
                   *                                                    ///
                   ]
  st_is 2 analysis
  marksample touse, novarlist
  qui replace `touse' = 0  if _st==0 | _st==. 	
	
  local otheroptions `options'
  
  // extract allowed graph options
  _get_gropts, graphopts(`otheroptions') getallowed(legend xtitle ytitle title)
  if "`s(graphopts)'" ! = "" {
    di as error "Illegal option(s), `s(graphopts)'"
    exit 198
  }
  if `"`s(ytitle)'"' == "" local ytitle ytitle("Marginal Relative Survival")
  if `"`s(xtitle)'"' == "" local xtitle xtitle("Time since diagnosis (years)")
  if `"`s(legend)'"' !=""  local haslegend haslegend
  
// id variable
  if `"`_dta[st_id]'"' == "" {
  di as err "stpp requires that you have previously stset an id() variable"
    exit 198
  }

  cap bysort `_dta[st_id]' : assert _N==1
  if _rc {
    di as err "stpp requires that the data are stset with only one observation per individual"
    exit 198
  } 
	
************
// Checks //	
************
  confirm var `agediag' `datediag'
  confirm var `pmother'
  foreach var in `agediag' `datediag' `pmother' {
    qui count if missing(`var') & `touse'
    if `r(N)' >0 {
      di as error "`var' has missing values"
    }
  }
  local RS_newvarname `varlist'

  if "`indweights'" != "" {
    confirm var `indweights'    
    quietly count if missing(`indweights') & `touse'
    if `r(N)'>0 {
      di as err "You have missing values in `indweights'"
      exit 198
    }
    di as error
  }
  if "`by'"         != "" confirm var `by'    

  if "`standstrata'" != "" {
  	qui count if missing(`standstrata') & `touse'
    if `r(N)' > 0 {
    	display as error "Missing values not allowed for standstrata."
    	display as error "You can exclude using an if statement."
      exit 198
    }
    qui levelsof `standstrata' if `touse'
    local Nstandlevels `r(r)'
    if "`standweights'" == "" {
      di as error  "You need to specify weights using the standweights() option when you standardize"
      exit 198
    }
    else {
      if wordcount("`standweights'") != `Nstandlevels' {
        di as error "You must give as many weights as there are levels of `standstrata'"
        exit 198
      }
    }
    if "`crudeprob'`allcause'" != "" {
      di as error "You can't use the standstrata option with all-cause or crude probabilities"       
      di as error "You could use the indweight() options as an alternative"
      exit 198
    }
    if `: list standstrata in by' {
      di as error "The same variable can't be given in both standstrata() and by()."
      exit 198
    }
  }
  
  if "`allcause'" != "" {
  	local AC_newvarname `allcause'
  	confirm new var `AC_newvarname' `AC_newvarname'_lci	`AC_newvarname'_uci
  }
  
  if "`crudeprob'" != "" {
  	local CP_newvarnames `crudeprob'
    foreach v in `CP_newvarnames' {
      confirm new var `v' `v'_lci	`v'_uci
    }
  }

  
  if "`popmort2'" != "" & "`using2'" != ""{
    di as error "You can't use both the using2() and popmort2() options."
    exit 198
  }
  
  if "`popmort2'" != "" local using2 `popmort2'

  if "`ederer2'" != "" & "`using2'" != ""{
    di as error "You can't use the ederer2 option and using2()/popmort2() options together"
    exit 198
  }

// contrast option
  if "`contrast'" != "" {
    if "`by'" == "" {
      di as error "You must specify the by() option when using contrast()."
      exit 198
    }
    Parse_contrast_option if `touse', `contrast' by(`by')
  }  
  
  if("`display'" == "") local display RS
  local display = strupper("`display'")
  if !inlist("`display'","RS","AC","CP","NONE") {
    display as error "Invalid option for display()"
    exit 198
  }
  if "`display'" == "AC" & "`allcause'" == "" {
    di as error "You have asked to display all cause estimates without using the allcause option."
    exit 198
  }
  if "`display'" == "CP" & "`crudeprob'" == "" {
    di as error "You have asked to display crude probabilities without using the crudeprob option."
    exit 198
  }
  
  
  /// checks that at least one observation and 1 event. (within standstrata???)
  if "`by'" != "" | "`standstrata'" != "" {
    tempvar bygroups eventtab
    qui egen `bygroups' = group(`by' `standstrata') if `touse'
    qui tab `bygroups' _d if `touse', matcell(`eventtab')
    matrix `eventtab' =  `eventtab'[1...,2]
    mata:st_local("zeroevents",strofreal(sum(st_matrix("`eventtab'"):==0):>0))
    if `zeroevents' {
    	di as error "There are zero events in one of the groups defined by the"
    	di as error "by() and/or standstrata() options"
      exit 198
    }
    qui replace `touse' = 0 if `bygroups' == .
  }
  else {
    quietly count if _d==1 &`touse'
    if `r(N)' == 0 {
    	di as error "There are zero events" 
      exit 198
    }
  }

// frames
  if "`frame'" != "" {
    getframeoptions `frame'    
  } 
  mata: st_local("frameexists",strofreal(st_frameexists(st_local("resframe"))))
  if `frameexists' & "`framereplace'" != "" {
    frame drop `resframe'
  }  
  

*******************	
// popmort file ///
*******************
  if "`pmage'" == "" local pmage _age
  if "`pmyear'" == "" local pmyear _year
  if "`pmrate'" == "" local pmrate rate
  local usingfilename `using'
  qui describe using "`usingfilename'", varlist short
  local popmortvars `r(varlist)'
  foreach var in `pmage' `pmyear' `pmother' `pmrate' {
    local varinpopmort:list posof "`var'" in popmortvars
    if !`varinpopmort' {
      di as error "`var' is not in popmort file"
      exit 198
    }
  }
  // using2 for time-dependent weights
  if "`using2'" != "" {
    local 0 `using2'
    syntax anything(id="filename" name=using2filename), [   ///
      pmage2(string)   ///
      pmother2(string) ///
      pmrate2(string)  ///
      pmyear2(string)  ///
      ]

    mata: st_local("using2exists",strofreal(fileexists(st_local("using2filename"))))
    if !`using2exists' {
      di as error "File `using2' does not exist"
      exit 198
    }
    local pmage2 = cond("`pmage2'"== ".","",cond("`pmage2'"== "","`pmage'","`pmage2'")) 
    local pmyear2 = cond("`pmyear2'"== ".","",cond("`pmyear2'"== "","`pmyear'","`pmyear2'"))
    local pmother2 = cond("`pmother2'"== ".","",cond("`pmother2'"== "","`pmother'","`pmother2'"))
    local pmrate2  = cond("`pmrate2'" == "","`pmrate'","`pmrate2'") 
    
    if "`minexpsurv'" != "" {
      confirm number `minexpsurv'
    }
    
    qui describe using "`using2filename'", varlist short
    local popmort2vars `r(varlist)'
    foreach var in `pmage2' `pmyear2' `pmother2' `pmrate2' {
      local varinpopmort2:list posof "`var'" in popmort2vars
      if !`varinpopmort2' {
        di as error "`var' is not in popmort2() file"
        exit 198
      }
    }    
  }

  // restrict popmort file to necessary ages and years
  tempvar attage yeardiag attyear

  summ `agediag' if `touse', meanonly
  local minage = floor(`r(min)')
  qui gen `attage' = `agediag' + _t + 1 if `touse'
  summ `attage' if `touse', meanonly
  local maxattage = min(ceil(`r(max)'),`pmmaxage')
  qui gen `yeardiag' = year(`datediag') if `touse'
  summ `yeardiag'  if `touse', meanonly
  local minyear = `r(min)'
  qui gen `attyear' = year(`datediag' + (_t+1)*365.241)  if `touse'
  summ `attyear' if `touse', meanonly
  local maxattyear = min(`r(max)',`pmmaxyear')	

  tempname popmortframe
  frame create `popmortframe'
  frame `popmortframe': qui use "`usingfilename'" if           ///
	                   inrange(`pmage',`minage',`maxattage') &   ///
	                   inrange(`pmyear',`minyear',`maxattyear') 
                     
  // check pm other levels
  if "`pmother'" != "" {
    Check_popmort_levels if `touse', pmother(`pmother') popmortframe(`popmortframe')
  }
                   
  if "`using2'" != "" {
    tempname popmort2frame
    frame create `popmort2frame'
    if "`pmyear2'" != "" {
      local inrangepmyear2 "& inrange(`pmyear2',`minyear',`maxattyear')"
    }
    frame `popmort2frame': qui use "`using2filename'" if                ///
	                     inrange(`pmage2',`minage',`maxattage') `inrangepmyear2'
    frame `popmort2frame': qui count
    if `r(N)'==0 {
      di as error "popmort2() file has no observation after restrictions - check syntax."
      di as error "You may want to use pmyear2(.) and/or pmother2(.) if"              
      di as error "popmort file does not vary by year / other covariates."
      exit 198
    }
    if "`pmother2'" != "" {
      Check_popmort_levels if `touse', pmother(`pmother2') popmortframe(`popmort2frame')
    }
  } 
	
  mata: stpp()

  return add
  
  if "`list'" != ""  {
  	quietly {
  	  matrix colnames PP=`by' time PP PP_lci PP_uci	
  	  return matrix PP=PP
  	  if "`allcause'"  != "" {
  	  	matrix colnames AC=`by' time AC AC_lci AC_uci	
  	    return matrix AC=AC
  	  }
	    if "`crudeprob'" != "" {
	      matrix colnames CP_can=`by' time CP_can CP_can_lci CP_can_uci	
	      return matrix CP_can=CP_can
	  	  if wordcount("`crudeprob'")>1 {
	  	    matrix colnames CP_oth=`by' time CP_oth CP_oth_lci CP_oth_uci	
	        return matrix CP_oth=CP_oth		
	  	  }
	    }
	  }
  }  
  

  // merge in results  
  tempvar tmplink
  if "`inccens'" == "" local add_d _d
  quietly {
    frlink m:1 _t `add_d' `by' `touse', frame(stpp_tmpdataframe) generate(`tmplink')
    frget *, from(`tmplink')
    frame drop stpp_tmpdataframe
  }
  
  
  
// add further details to frame
if "`frame'" != "" {
  tempfile Natrisk
  
  summ _t if `touse', meanonly
  local tmax `r(max)'
  foreach n in `list' {
    if `n'<=`tmax' local list2 `list2' `n'
  }
  qui sts list if `touse', by(`by') atrisk0 risktable(`list2') saving(`Natrisk')
  
  tempname Natrisk_frame
  frame create `Natrisk_frame'
  frame `Natrisk_frame' {
    use `Natrisk'
    keep `by' time at_risk
  }  
  frame `resframe' {
    qui frlink 1:1 `by' time, frame(`Natrisk_frame')
    qui frget Natrisk = at_risk, from(`Natrisk_frame')
    qui replace Natrisk = 0 if Natrisk ==.
    order `by' time Natrisk
  }
  char _dta[cmd] stpp `0'
  qui findfile stpp.ado
}  
  
  

*******************
// fill in gaps	///
*******************	
if "`inccens'"=="" {
  local newvarlist `RS_newvarname' `RS_newvarname'_lci `RS_newvarname'_uci
  if "`allcause'"  != "" local newvarlist `newvarlist' `AC_newvarname' `AC_newvarname'_lci `AC_newvarname'_uci
  if "`crudeprob'" != "" {
  	tokenize "`crudeprob'"
    local newvarlist `newvarlist' `1' `1'_lci `1'_uci
    if "`2'" != "" {
      local newvarlist `newvarlist' `2' `2'_lci `2'_uci
    }
  }
  tempvar d0
  qui gen byte `d0' = 1 - _d
  if "`by'" == "" {
    tempvar cons
    qui gen `cons' = 1
    local by `cons'
  }
	
  foreach v in `newvarlist' {
    quietly bysort `by' `touse'  (_t `d0'): replace `v' = `v'[_n-1] if `v' >= . & `touse' 
  }
}


  
*******************
// graphs     	///
*******************	
  if "`graph'"!="" | "`graphname'"!="" | "`graphcode'"!="" {
    quietly {
	  
      preserve
        keep if `touse'
        tempvar group
        qui egen `group'=group(`by') if `touse'
        levelsof `group', local(grouplevs)
        local Nofgroups=wordcount("`grouplevs'")
        local Nofby=wordcount("`by'")
			
        forvalues i=1/`Nofgroups' {
          local bybit `bybit' risktable(, failevents group(#`i') size(small) rowtitle(,  color("scheme p`i'")) title("N (deaths)", size(medsmall) ))
        }
			
        tempname KM
        sts graph, by(`by') name(`KM') nodraw `bybit'
			
        **GET GRAPH COMMAND**	
        graph describe `KM'
        local command=r(command)
			
        **STEAL RISKTABLE**
        local xlabelpart = substr(`"`command'"', strpos(`"`command'"', "xlabel("), .)
        local xlabelpart =substr(`"`xlabelpart'"', 1 ,strpos(`"`xlabelpart'"',"xoverhang")+9)
			
        **MAKE BF*
        local xlabelpart=subinstr(`"`xlabelpart'"',"`"+char(34),"`"+char(34)+"{bf:", . )
        local xlabelpart=subinstr(`"`xlabelpart'"',char(34)+"'","}"+char(34)+"'", . )
		
        if "`indweights'" != "" {
          local note note(" " "{bf:Note:}Standardised using `indweights'.")
        }
        
        forvalues i=1/`Nofgroups' {
          forvalues j=1/`Nofby' {
            if `Nofby'>1 {
              if `j'!=`Nofby' {
                local comma ,
              }
              else {
                local comma
              }
            }
            else {
              local comma
            }
            local currentby: word `j' of `by'
            su `currentby' if `group'==`i', meanonly
            local bytext`i' `bytext`i'' `currentby'=`r(mean)'`comma'
         }
				
         local graphareatext `graphareatext' (rarea `RS_newvarname'_lci `RS_newvarname'_uci _t if `group'==`i', sort connect(stairstep) ///
                             color("%30") pstyle("") lwidth(none) fintensity(100) )
				 
         local graphareatextforwrite=`"`graphareatextforwrite'"'+"(rarea `RS_newvarname'_lci `RS_newvarname'_uci _t if __group==`i', sort connect(stairstep) color("+char(34)+"%30"+char(34)+") pstyle("+char(34)+char(34)+") lwidth(none) fintensity(100) )"
				   
         if `i'==1 {
           local xlabelpart1 `xlabelpart'
           local xlabelpart1forwrite=`"`xlabelpart'"'		
          } 
          else {
            local xlabelpart1
            local xlabelpart1forwrite
          }

		      local graphlinetext `graphlinetext' (line `RS_newvarname' _t  if `group'==`i', sort connect(J ...) pstyle(p`i'line) color("%80") `xlabelpart1')

          local graphlinetextforwrite=`"`graphlinetextforwrite'"'+"(line `RS_newvarname' _t  if __group==`i', sort connect(J ...) pstyle(p`i'line) color("+char(34)+"%80"+char(34)+") "+`"`xlabelpart1forwrite'"'+")"
				  
				  
           local legendtext `legendtext' `=`Nofgroups'+`i'' `"`bytext`i''"' 
         }
	     // DROP LEGEND IF NO BY??
		 if "`haslegend'" == "" {
           if `Nofgroups'>1 {
             local legend legend(order(`legendtext') region(color(none)) ring(0) pos(7) cols(1))
           }
           else {
             local legend legend(off)
           }
		 }
         tempvar new
         bys `by': gen `new'=1 if _n==1
		 expand 2 if `new'==1, gen(new)
		 replace _t=0 if new==1
		 local repvalue = cond("`deathprob'"=="",1,0)
		 replace `RS_newvarname'=`repvalue'     if new==1
		 replace `RS_newvarname'_lci=`repvalue' if new==1
		 replace `RS_newvarname'_uci=`repvalue' if new==1
		 
		 if "`graphname'"!="" {
           local namepart name(`graphname')
         }
         else {
           local namepart
         }

         twoway `graphareatext' `graphlinetext',  ylabel(0(.25)1, angle(h) ///
         format(%3.2f) grid) /// 
         `otheroptions' `ytitle' `xtitle'   ///
         `legend'	plotregion(margin(zero)) `note' `namepart' 
			
       restore
		
       if "`graphcode'"!="" {		
         local subtitle = cond("`ederer2'" != "","Ederer II", "Pohar Perme")
         if "`using2'" != "" local subtitle "Sasieni and Brentnall"
         if "`standstrata'" != "" local ytitle (Standardized by `standstrata')

         //WRITE FILE TO RECREATE GRAPH
         tokenize "`graphcode'", parse(",") 
         if "`2'" == "," & "`3'" == "replace" {
           local replace replace
           local dofilename `1'
         }
         else local dofilename `graphcode'
         
         file open graphcode using "`dofilename'", write `replace' 
         file write graphcode "//WILL CHANGE THE DATA, SO WITHIN PRESERVE RESTORE - RUN ALL CODE TOGETHER"	_n
         file write graphcode "preserve" _n
         file write graphcode "//BETTER TO MATCH IF STATEMENT FROM ORIGINAL STPP COMMAND, BUT THIS TAKES NON-MISSING VALUES FOR THE GENERATED VARIABLE AS A PROXY" _n
         file write graphcode _tab(1) "keep if `RS_newvarname'!=." _n
         file write graphcode "//GROUP VARIABLE FOR ORIGINAL BY STATEMENT"	_n	
         file write graphcode _tab(1) "egen __group=group(`by')" _n		
         file write graphcode "//ADD A VALUE OF 1 AT TIME 0 FOR EACH GROUP"	_n
         file write graphcode _tab(1) "tempvar new new2" _n	
         file write graphcode _tab(1) "bys `by': gen \`new'=1 if _n==1" _n	
         file write graphcode _tab(1) "expand 2 if \`new'==1, gen(\`new2')" _n	
         file write graphcode _tab(1) "replace _t=0 if \`new2'==1" _n	
         file write graphcode _tab(1) "replace `RS_newvarname'=`repvalue' if \`new2'==1" _n	
         file write graphcode _tab(1) "replace `RS_newvarname'_lci=`repvalue' if \`new2'==1" _n	
         file write graphcode _tab(1) "replace `RS_newvarname'_uci=`repvalue' if \`new2'==1 " _n		
         file write graphcode "//GRAPH TEXT - RAREA FOR CIs, LINE FOR POINT ESTIMATES, XLABELS FOR THE RISKTABLE" _n		
         file write graphcode "//MODIFY THIS TEXT TO MAKE CHANGES TO THE GRAPH" _n
         file write graphcode `"//E.G DELETE FROM THE FIRST XLABEL UP TO AND INCLUDING "XOVERHANG" TO REMOVE THE RISKTABLE"' _n				
         file write graphcode _tab(1) `"twoway `graphareatextforwrite' `graphlinetextforwrite',  ylabel(0(.25)1, angle(h) ///"' _n 
         file write graphcode _tab(1) "format(%3.2f) grid) ///" _n 
         file write graphcode _tab(1) `"`ytitle' ///"' _n 
         file write graphcode _tab(1) `"`xtitle' ///"'	_n
         file write graphcode _tab(1) `"`legend' plotregion(margin(zero)) `note' `namepart'"' _n 		
         file write graphcode "restore" _n
         file close graphcode
         //doedit ".\__stpp_graph_code_.do"
         di as input "File `dofilename' has been created"

       }
    }
  }
end


program define Check_popmort_levels
  syntax [if], popmortframe(string) [pmother(varlist)]
  marksample touse
  
  foreach v in `pmother' {
    qui levelsof `v' if `touse'
    local levelsindata `r(levels)'
    qui frame `popmortframe': levelsof `v'
    local levelsinpopmort `r(levels)'
    foreach lev in `levelsindata' {
      if !`:list lev in levelsinpopmort' {
        di as error "Level `lev' of variable `v' not found in popmort file"
        exit 198
      }
    }
  }
end



program define getframeoptions
  syntax [anything], [replace ]
  c_local resframe       `anything'
  c_local framereplace   `replace'
end

program define Parse_contrast_option
  syntax [if], contrast(string) by(string) 
  marksample touse
  
  Extract_contrast_option `contrast'
  
  if "`contrasttype'" != "difference" {
    di as error "Only contrast type difference currently allowed."
    exit 198
  }
  
  // ADD ERROR CHECKS
  // ADD to HELP FILE

  if !`: list contrast_basevar in by' { 
    di as error "contrast() base level variable must be listed in by() option."
    exit 198
  }

  quietly levelsof `contrast_basevar'
  local levels `r(levels)' if `touse' 
  if !`: list contrast_baselevel in levels' {
    di as error "contrast() error: `contrast_baselevel' not a level of `contrast_basevar'"
    exit 198
  }
  
  c_local contrast_basevar `contrast_basevar'
  c_local contrast_baselevel `contrast_baselevel'
  
  c_local contrasttype `contrasttype'
  c_local contrast_per `per'
end

program define Extract_contrast_option
  syntax anything(name=contrasttype id="contrast type"), baselevel(string) [per(real 1)]
  tokenize `baselevel'
  confirm var `1'
  local contrast_basevar `1'
  confirm number `2'
  local contrast_baselevel `2'
  
  c_local contrasttype `contrasttype'
  c_local contrast_basevar `contrast_basevar'
  c_local contrast_baselevel `contrast_baselevel'
  c_local per `per'
end

version 16.0
set matastrict on
mata:
////////////////////////////////
// stpp.mata
//
// Main mata file
//
////////////////////////////////

void function stpp()
{
// define structure
  struct stpp_info scalar S  

// Get relevant info into stucture 
  S = PP_Get_stpp_info()

// Generate_estimates 
  PP_Gen_estimates(S)
 
// Generate cumulative estimates 
  PP_Gen_cumulative_estimates(S)

// Create results at specific time in list() option.
  PP_Write_list_results(S)

// Save new variables
  PP_Write_new_variables(S)  
}




// Main structure 
struct stpp_info {
// various options
  real         scalar   hasindweights,         // has individual weights
                        hasallcause,           // has allcause option
                        hasby,                 // calculate by subgroups
                        hascontrast,           // calculate contrasts
                        hascrudeprob,          // calculate crude probabilities
                        hasdeathprob,          // calculate net and All-cause death probs 
                        haslist,               // display at specific time points
                        hasframe,              // write result to a frame
                        hasflemhar,            // Fleming Harrington   
                        hasminexpsurv,         // has minimum expected survival
                        hasinccens,            // include censored observations
                        minexpsurv,            // values of minimum expected survival  
                        pmmaxage,              // maximum age in popmort file
                        pmmaxyear,             // maximum year in popmort file
                        ederer2,               // ederer2 option
                        level,                 // level for confidence intervals
                        hasstandstrata,        // has strata to standardize over
                        verbose,               // print out details
                        dropexpected,          // drop expected rates (trick for CS)
                        haspopmort2,           // has second popmort file
                        haspmother2,           // popmort2 file straified by other
                        haspmyear2,            // popmort2 file straified by year
                        Nlist,                 // Number of time points to display
                        CP_calcother           // calc CP for other causes                        
                  
  string       scalar   pmage,                 // age variable in popmort file
                        pmyear,                // year variable in popmort file
                        pmrate,                // rate variable in popmort file
                        pmage2,                // age variable in popmort2 file
                        pmyear2,               // year variable in popmort2 file
                        pmrate2,               // rate vatriable in popmort2 file                  
                        resframe,              // name of results frame
                        display                // displat option 
                  
  real         matrix   list                   // list of times to display                  
  
  string       scalar   contrasttype,          // contrasy type
                        contrast_basevar       // contrast base variable

  real         scalar   contrast_baselevel,    // contrast base level
                        contrast_per           // multiply contrasts
  
  string       matrix   pmother,               // other variables in popmort file
                        pmother2,              // other variables in popmort2 file
                        RS_newvarname,         // new RS variable name
                        AC_newvarname,         // new AC variable name
                        CP_newvarnames         // new CP variable names

// popmort info
  string scalar         pmvars,                // variables in popmort file
                        pmvars2                // variables in popmort2 file

                  
  real         matrix   popmort,               // data from popmort file (view)
                        popmort2,              // data from popmort2 file (view)
                        Npmother,              // Number of other variables in popmort file
                        Npmoth_levels          // Number of levels of pm other variables

                  
  real         scalar   ageplus,               // value to add (subtract) so match row1 of matrix
                        yearplus               // value to add (subtract) so match col1 of matrix
  
  transmorphic matrix   pm,                    // array for popmort files by other levels
                        pm2,                   // array for popmort file by other levels
                        Nyears_pm,             // array for Number of year columns
                        pmoth_levels           // levels
 
// data from Stata
  real         scalar   Nobs                   // Number of observations
  
  string       scalar   touse,                 // Name of touse variable
                        currentframe           // current frame
  
  real         matrix   datediag,              // date of diagnosis
                        agediag,               // age at diagnosis
                        t,                     // event/censoring times
                        t0,                    // entry times
                        d,                     // event indicator
                        standstrata,           // standstrata data 
                        indweights             // individual level weights
                             
                        
  transmorphic matrix   pmothervars,           // other variables
                        pmotherselect          // which pmother group

// standstrata options
  real         scalar   Nstandlevels           // Number of levels in standstrata

  real         matrix   standweights,          // weights for externally standardizing 
                        standlevels            // unique levels for standstrata
  
  string       scalar   standstrata_var,       // name of standstrata variable     
                        indweights_var         // name of indweights variable
  
                  
// by options
  string       matrix   byvars                 // name of variable in by options
  
  real         matrix   by,                    // matrix containg by variables
                        bylevels               // unique levels of by variables
                  
  real         scalar   Nbylevels,             // number of by levels
                        Nbyvars                // number of by variables
                  
// unique value of t
  transmorphic matrix   unique_t_sk,           // unique values of t by stand and by levels
                        unique_t_k,            // unique values of t by by levels
                        mint_k,                // minimum value of t by by levels
                        maxt_k ,               // maximum value of t by by levels
                        maxtall_k              // maximum value of t (all) by by levels
  
  real         matrix   Nunique_t_sk,          // No. of unique t for stand and by levels
                        Nunique_t_k,           // No. of unique t for by levels
                        Nobs_by_sk             // Total obs bystand and by levels
// estimates
  transmorphic matrix   lambda_e_t,            // contribution to PP at each time
                        lambda_e_t_var,        // contribution to PP var at each time
                        lambda_all_t,          // contribution to all cause each time
                        lambda_all_t_var,      // contribution to all cause var each time
                        lambda_pop1_t,         // contribution to exp mort each time (popmort1)
                        lambda_pop2_t          // contribution to exp mort each time (popmort2)
                        

// Needed by other functions
  real         matrix   attage,                // attained agediag
                        attyear,               // attained year 
                        atrisk_all,            // those still (or will be) at risk
                        atrisk_all_index,      // index for atrisk2
                        atrisk_delentry        // exclude inidviduals if delayed entry
                        
  real         scalar   yj                     // risk time for jth interval
  
  transmorphic matrix   pmothervars_by         // othervars by 

// Results
  real         matrix   returnmat_pp           // results for PP in matrix
  
  transmorphic matrix   RS_PP,                 // PP results
                        RS_PP_var,             // PP variance
                        AC,                    // AC results
                        AC_var,                // AC variance
                        CP_can,                // Crude Prob (cancer) results
                        CP_can_var,            // Crude Prob (cancer) variance
                        CP_oth,                // Crude Prob (other)  results
                        CP_oth_var             // Crude Prob (other)  variance

// Results for list
  transmorphic matrix   RS_list_matrix,        // RS results at list values
                        RS_list_var,           // RS var at list values
                        AC_list_matrix,        // AC results at list values
                        AC_list_var,           // RS var at list values
                        CP_can_list_matrix,    // CP_can results at list values
                        CP_can_list_var,       // CP_can var at list values
                        CP_oth_list_matrix,    // CP_oth results at list values
                        CP_oth_list_var,       // CP_oth var at list values
                        RS_list_contrast,      // RS contrast results
                        AC_list_contrast,      // AC contrast results
                        CP_can_list_contrast,  // CP_can contrast results
                        CP_oth_list_contrast   // CP_oth contrast results
                        
  real colvector        bylevel_isref          // bylevels that are reference levels                        
                        
// Results for frame
  transmorphic matrix   RS_frame_results,      // RS results for frame
                        AC_frame_results,      // AC results for frame
                        CP_can_frame_results,  // CP_can results for frame
                        CP_oth_frame_results,  // CP_oth results for frame
                        RS_frame_contrast,     // RS contrast info for frame
                        AC_frame_contrast,     // AC contrast info for frame
                        CP_can_frame_contrast, // CP_can contrast info for frame
                        CP_oth_frame_contrast  // CP_oth contrast info for frame
}




////////////////////////////////
// Get_stpp_info.mata
//
// Read data into structure
//
////////////////////////////////

function PP_Get_stpp_info()
{
  real   scalar k, s
 
  struct stpp_info scalar S
  
  S.verbose = st_local("verbose") != ""
  if(S.verbose) display("Reading in things to set up structure")

// various options  
  S.hasindweights  = st_local("indweights") != ""
  S.hasallcause    = st_local("allcause") != ""
  S.hasby          = st_local("by") != ""
  S.hascontrast    = st_local("contrast")  != ""
  S.hascrudeprob   = st_local("crudeprob") != ""
  S.hasdeathprob   = st_local("deathprob") != ""
  S.hasflemhar     = st_local("fh") != ""
  S.hasminexpsurv  = st_local("minexpsurv") != ""
  S.hasframe       = st_local("frame") != ""
  S.hasinccens     = st_local("inccens") != ""
  S.pmage          = st_local("pmage")
  S.pmyear         = st_local("pmyear")
  S.pmother        = tokens(st_local("pmother"))
  S.pmrate         = st_local("pmrate")
  S.pmmaxage       = strtoreal(st_local("pmmaxage"))
  S.pmmaxyear      = strtoreal(st_local("pmmaxyear"))
  S.ederer2        = st_local("ederer2") != ""
  S.level          = strtoreal(st_local("level"))/100  
  S.hasstandstrata = st_local("standstrata") != ""
  S.haspopmort2    = st_local("using2") != ""
  S.dropexpected   = st_local("dropexpected") != ""
  S.display        = st_local("display")

  if(S.hasframe) S.resframe = st_local("resframe")  
  
// read in popmort2 options  
  if(S.haspopmort2) {
    S.pmage2         = st_local("pmage2")
    S.pmyear2        = st_local("pmyear2")
    S.pmother2       = tokens(st_local("pmother2"))

    if(cols(S.pmother2)==0) S.pmother2 = ""
    S.pmrate2        = st_local("pmrate2")    
    S.haspmyear2    = S.pmyear2  != ""    
    S.haspmother2   = S.pmother2 != ""  
  }   

// list option
  S.haslist = st_local("list") != ""
  if(S.haslist) {
    S.list    = strtoreal(tokens(st_local("list")))
    S.Nlist   = cols(S.list)
  }  

// contrast options
  if(S.hascontrast) {
    S.contrasttype       = st_local("contrasttype")
    S.contrast_basevar   = st_local("contrast_basevar")
    S.contrast_baselevel = strtoreal(st_local("contrast_baselevel"))
    S.contrast_per = strtoreal(st_local("contrast_per"))
  }  

// minexpsurv options
  if(S.hasminexpsurv) S.minexpsurv = strtoreal(st_local("minexpsurv"))  
  
// variables in poport files  
  S.pmvars  = tokens(invtokens((S.pmage,S.pmyear,S.pmother,S.pmrate)))
  if(S.haspopmort2) {
    S.pmvars2 = tokens(invtokens((S.pmage2,S.pmyear2,S.pmother2,S.pmrate2)))
  }
  
// new variable names
  S.RS_newvarname = st_local("RS_newvarname")
  if(S.hasallcause) S.AC_newvarname = st_local("AC_newvarname")
  if(S.hascrudeprob) {
    S.CP_newvarnames = tokens(st_local("CP_newvarnames"))
  }
  S.CP_calcother = cols(S.CP_newvarnames)==2 :& S.hascrudeprob

// popmort files as a view
  if(S.verbose) printf("Reading in popmort file(s)\n")
  S.currentframe = st_framecurrent()
  st_framecurrent(st_local("popmortframe"))
  st_view(S.popmort=.,.,S.pmvars,.)

// popmort2 file as a view
  if(S.haspopmort2) {
    st_framecurrent(st_local("popmort2frame"))
    st_view(S.popmort2=.,.,S.pmvars2,.)    
  }
  st_framecurrent(S.currentframe)

// read in data from Stata
  S.touse         = st_local("touse")
  S.datediag      = st_data(., st_local("datediag"), S.touse)
  S.agediag       = st_data(., st_local("agediag"), S.touse)
  S.t             = st_data(.,"_t",S.touse)
  S.t0            = st_data(.,"_t0",S.touse)
  S.d             = st_data(.,"_d",S.touse)
  S.Nobs          = rows(S.t)
  
  S.pmothervars   = asarray_create("real",1)
  asarray(S.pmothervars,1,st_data(.,(S.pmother),S.touse))
  if(S.haspopmort2) {
    if(S.haspmother2) asarray(S.pmothervars,2,st_data(.,(S.pmother2),S.touse))
    else asarray(S.pmothervars,2,J(S.Nobs,1,1))
  }
 
// individual weights
  if(S.hasindweights) {
    S.indweights     = st_data(.,st_local("indweights"),S.touse)
    S.indweights_var = st_local("indweights")
  }
  else                S.indweights    = J(S.Nobs,1,1)
  
// standstrata data
  if(S.hasstandstrata) {
    S.standstrata_var = st_local("standstrata")
    S.standstrata     = st_data(., S.standstrata_var, S.touse)
    S.standweights    = strtoreal(tokens(st_local("standweights")))	
    S.Nstandlevels    = strtoreal(st_local("Nstandlevels"))
    S.standlevels     = uniqrows(S.standstrata)
  } 
  else {
    S.Nstandlevels = 1
    S.standlevels  = 1
    S.standstrata = J(S.Nobs,1,1)
  }  
  
// by variables
  if(S.hasby) {
    S.byvars     = tokens(st_local("by"))
    S.by         = st_data(.,S.byvars,S.touse)
    S.bylevels   = uniqrows(S.by)
    S.Nbylevels  = rows(S.bylevels)
    S.Nbyvars    = cols(S.by)
  }
  else {
    S.byvars     = J(1,0,"")
    S.by         = J(S.Nobs,1,1)
    S.bylevels   = 1
    S.Nbylevels  = 1
    S.Nbyvars    = 1
  }
  
// unique values of t
// calculated separately for by and standstrata levels
  S.unique_t_sk  = asarray_create("real",2)
  S.unique_t_k   = asarray_create("real",1)
  S.Nunique_t_sk = J(S.Nstandlevels,S.Nbylevels,.)
  S.Nobs_by_sk   = J(S.Nstandlevels,S.Nbylevels,.)  
  S.Nunique_t_k  = J(1,S.Nbylevels,.)
  S.maxt_k       = asarray_create("real",1)
  S.mint_k       = asarray_create("real",1)
  S.maxtall_k    = asarray_create("real",1)
 

  for(k=1;k<=S.Nbylevels;k++) {
    for(s=1;s<=S.Nstandlevels;s++) {
      if(S.hasinccens) {
        asarray(S.unique_t_sk,(s,k), uniqrows(S.t[selectindex(rowsum(S.by:==S.bylevels[k,]):==S.Nbyvars :& S.standstrata:==S.standlevels[s])]))
      }
      else {
        asarray(S.unique_t_sk,(s,k), uniqrows(S.t[selectindex(S.d :& rowsum(S.by:==S.bylevels[k,]):==S.Nbyvars :& S.standstrata:==S.standlevels[s])]))
      }
      S.Nunique_t_sk[s,k] = rows(asarray(S.unique_t_sk,(s,k)))
      S.Nobs_by_sk[s,k]   = sum(S.by:==S.bylevels[k,] :& S.standstrata:==S.standlevels[s])
    }
    if(S.hasinccens) {
      asarray(S.unique_t_k,(k),uniqrows(S.t[selectindex(rowsum(S.by:==S.bylevels[k,]):==S.Nbyvars)]))
    }
    else {
      asarray(S.unique_t_k,(k),uniqrows(S.t[selectindex(S.d :& rowsum(S.by:==S.bylevels[k,]):==S.Nbyvars)]))
    }
    S.Nunique_t_k[k] = rows(asarray(S.unique_t_k,(k)))
    asarray(S.mint_k,k,min(asarray(S.unique_t_k,(k))))
    asarray(S.maxt_k,k,max(asarray(S.unique_t_k,(k))))
    asarray(S.maxtall_k,k,max(S.t[selectindex(rowsum(S.by:==S.bylevels[k,]):==S.Nbyvars)]))
  }  

// Read in popmort files  
  PP_read_popmort(S)  
  
// contribution to PP at each time point
  S.lambda_e_t       = asarray_create("real",S.Nbyvars:+1)
  S.lambda_e_t_var   = asarray_create("real",S.Nbyvars:+1)
  S.lambda_all_t     = asarray_create("real",S.Nbyvars:+1)
  S.lambda_all_t_var = asarray_create("real",S.Nbyvars:+1)
  S.lambda_pop1_t    = asarray_create("real",S.Nbyvars:+1)
  S.lambda_pop2_t    = asarray_create("real",S.Nbyvars:+1)

  if(S.verbose) display("Finished setting up structure")
  return(S)  
}


////////////////////////////////
// PP_read_popmort.mata
//
// Read in popmort files
//
////////////////////////////////

// a bit messy as second popmort file added later
void function PP_read_popmort(struct stpp_info scalar S)
{
  real scalar Npmvars, Npmvars2, ratevarcol, ratevarcol2, i, j
  real scalar pm_endcol, pm_minage, pm_maxage, pm_minyear, pm_maxyear
  real scalar pm_startcol2, pm_endcol2, ageindex, yearindex

  real scalar Nrows_tmppm

  real matrix tmppm, tmp_ageyear, cols_pmother
  
// poport file
  S.Npmother = J(1,2,.)
  S.Npmoth_levels = J(1,2,.)
  S.Nyears_pm = asarray_create("real",1)  
  S.pmoth_levels = asarray_create("real",1)
  
  S.Npmother[1] = cols(S.pmother)
  Npmvars       = 2 :+ S.Npmother[1]
  ratevarcol    = Npmvars + 1
  
// store popmort file in array
// for each pm strata from matrix for ages(rows) and columns(years)
  asarray(S.pmoth_levels,1,uniqrows(asarray(S.pmothervars,1)))
  
  S.Npmoth_levels[1] = rows(asarray(S.pmoth_levels,1))

  S.pm = asarray_create("real",S.Npmother[1]) //- appropriate dimensions
 
  cols_pmother = J(1,S.Npmoth_levels[1],.)
  pm_endcol = 3 :+ (S.Npmother[1]:-1)

  pm_minage   = min(S.popmort[,1])
  pm_maxage   = max(S.popmort[,1])
  pm_minyear  = min(S.popmort[,2])
  pm_maxyear  = max(S.popmort[,2])
  S.ageplus   = 1 - pm_minage
  S.yearplus  = 1 - pm_minyear 
 
// error checks
  if(rows(S.popmort) != rows(uniqrows(S.popmort[,1..pm_endcol]))) {
    errprintf(S.pmage + ", " + S.pmyear + ", " + invtokens(S.pmother,", ") + " do not uniquely represent observations in using file\n")
    exit(198)
  } 
 
 
  for(j=1;j<=S.Npmoth_levels[1];j++) {
    tmppm = S.popmort[selectindex(rowsum(S.popmort[,3..pm_endcol]:==asarray(S.pmoth_levels,1)[j,]):==S.Npmother[1]),]
    tmp_ageyear = J((pm_maxage:-pm_minage:+1),(pm_maxyear:-pm_minyear:+1),.)
    tmppm[,1] = tmppm[,1] :+ S.ageplus
    tmppm[,2] = tmppm[,2] :+ S.yearplus

    Nrows_tmppm = rows(tmppm)
    for(i=1;i<=Nrows_tmppm;i++) {
      tmp_ageyear[tmppm[i,1],tmppm[i,2]] = tmppm[i,ratevarcol]
    }
    asarray(S.pm,asarray(S.pmoth_levels,1)[j,],tmp_ageyear)
    cols_pmother[j] = cols(asarray(S.pm,asarray(S.pmoth_levels,1)[j,]))
  }
  asarray(S.Nyears_pm,1,cols_pmother)

// popmort2 file 
  if(S.haspopmort2) { 
    Npmvars2         = cols(S.popmort2) :-1 
    S.Npmother[2]    = rowsum(S.pmother2:!="")
    ratevarcol2      = Npmvars2 + 1

//   store popmort file in array
//   for each pm strata from matrix for ages(rows) and columns(years)
    if(S.haspmother2) {
     asarray(S.pmoth_levels,2,uniqrows(asarray(S.pmothervars,2)))
     S.Npmoth_levels[2] = rows(asarray(S.pmoth_levels,2))
    }
    else {
      asarray(S.pmoth_levels,2,1) 
      S.Npmoth_levels[2] = 1
      S.Npmother[2] = 1
    }

    S.pm2 = asarray_create("real",S.Npmother[2]) //- appropriate dimensions
    cols_pmother = J(1,S.Npmoth_levels[2],.)
  
    pm_startcol2  = 2 :+ S.haspmyear2
    pm_endcol2    = Npmvars2
   
// error checks
    if(rows(S.popmort2) != rows(uniqrows(S.popmort2[,1..pm_endcol2]))) {
      errprintf(S.pmage2 + ", " + S.pmyear2 + ", " + invtokens(S.pmother2,", ") + " do not uniquely represent observations in using2 file\n")
      exit(198)
    }     

    for(j=1;j<=S.Npmoth_levels[2];j++) {
      if(S.haspmother2) {
        tmppm = S.popmort2[selectindex(rowsum(S.popmort2[,pm_startcol2..pm_endcol2]:==asarray(S.pmoth_levels,2)[j,]):==S.Npmother[2]),]
      }
      else tmppm = S.popmort2

      Nrows_tmppm = rows(tmppm)

      if(S.haspmyear2) tmp_ageyear = J((pm_maxage:-pm_minage:+1),(pm_maxyear:-pm_minyear:+1),.)
      else tmp_ageyear = J((pm_maxage:-pm_minage:+1),1,.)

      ageindex = tmppm[,1] :+ S.ageplus
      if(S.pmyear2 != "") yearindex = tmppm[,2] :+ S.yearplus
      else yearindex = J(Nrows_tmppm,1,1)

      for(i=1;i<=Nrows_tmppm;i++) {
        tmp_ageyear[ageindex[i],yearindex[i]] = tmppm[i,ratevarcol2]
      }

      asarray(S.pm2,asarray(S.pmoth_levels,2)[j,],tmp_ageyear)
      cols_pmother[j] = cols(asarray(S.pm2,asarray(S.pmoth_levels,2)[j,]))
    }
    asarray(S.Nyears_pm,2,cols_pmother)
  }
}


////////////////////////////////
// PP_Gen_estimates
//
// Generate Estimates
//
////////////////////////////////
void function PP_Gen_estimates(struct stpp_info scalar   S)
{
  real matrix byselect, byselect_ind, lambda_e_tmp, lambda_e_tmp_var,
              lambda_all_tmp, lambda_all_tmp_var, lambda_pop1_tmp_var,
              lambda_pop1_tmp, lambda_pop2_tmp,
              t_rates_start, y, 
              expcumhaz, expcumhaz2,
              t_by, t0_by, d_by, agediag_by, datediag_by,
              indweights_by, 
              exprates,exprates2,
              expsurv_tj, expsurv2_tj,
              died_tj, atrisk, atrisk_index, exprates_index,
              wt_atrisk, N_wt, Y_wt, v1, v2,
              died_tj_select, Ndied_tj,
              tmpattyear, tmpselect, bob
 
  real scalar Nuniq, tj, tstart_j,
              s, k, j, sumatrisk 

// loop over by groups and standstrata levels 
  for(k=1;k<=S.Nbylevels;k++) {
    for(s=1;s<=S.Nstandlevels;s++) {
      if(S.verbose) PP_verbose_print_by_strata(S,k,s)
      byselect     = rowsum(S.by:==S.bylevels[k,]):==S.Nbyvars :& S.standstrata:==S.standlevels[s]
      byselect_ind = selectindex(byselect)

      lambda_e_tmp     = J(S.Nunique_t_sk[s,k],1,.)
      lambda_e_tmp_var = J(S.Nunique_t_sk[s,k],1,.)

      if(S.hascrudeprob | S.hasallcause) {
        lambda_all_tmp      = J(S.Nunique_t_sk[s,k],1,.)
        lambda_all_tmp_var  = J(S.Nunique_t_sk[s,k],1,.)
        lambda_pop1_tmp     = J(S.Nunique_t_sk[s,k],1,.)
        lambda_pop1_tmp_var = J(S.Nunique_t_sk[s,k],1,.)
      }
      if(S.haspopmort2) lambda_pop2_tmp = J(S.Nunique_t_sk[s,k],1,.)
      else expsurv2_tj = 1
      
      if(S.Nunique_t_sk[s,k]:==1) t_rates_start = 0
      else t_rates_start = (0\asarray(S.unique_t_sk,(s,k))[|1 \ (S.Nunique_t_sk[s,k]:-1)|])
      y = asarray(S.unique_t_sk,(s,k)) :- t_rates_start
      expcumhaz     = J(S.Nobs_by_sk[s,k],1,0)
      if(S.haspopmort2) expcumhaz2 = J(S.Nobs_by_sk[s,k],1,0)

      t_by           = S.t[byselect_ind]
      t0_by          = S.t0[byselect_ind]
      d_by           = S.d[byselect_ind]
      agediag_by     = S.agediag[byselect_ind] 
      datediag_by    = S.datediag[byselect_ind]
      indweights_by  = S.indweights[byselect_ind]

      S.pmothervars_by = asarray_create("real",1)
      asarray(S.pmothervars_by,1,asarray(S.pmothervars,1)[byselect_ind,])
      if(S.haspopmort2) asarray(S.pmothervars_by,2,asarray(S.pmothervars,2)[byselect_ind,])

// loop over time points
      Nuniq = S.Nunique_t_sk[s,k]
      for(j=1;j<=Nuniq;j++) {
        if(S.verbose) PP_verbose_print_dots()
        tj       = asarray(S.unique_t_sk,(s,k))[j]
        tstart_j = t_rates_start[j]
        S.yj     = y[j]
        S.atrisk_all  = (t_by:>=tj)
        S.atrisk_all_index  = selectindex(S.atrisk_all) // keeps those who will be at risk in future (delayed entry)
        atrisk_index  = selectindex(S.atrisk_all :& (t0_by:<tj))
        exprates_index = selectindex(t0_by[S.atrisk_all_index]:<tj) // needed to reduce exprates with delayentry

// attained age (note quicker than using rowmin)
        S.attage = floor(agediag_by[S.atrisk_all_index] :+ tstart_j)
        tmpselect = selectindex(S.attage:>S.pmmaxage)
        if(cols(tmpselect)) S.attage[tmpselect] = J(rows(tmpselect),1,S.pmmaxage) 
        S.attage = S.attage :+ S.ageplus
        
// attained year (note quicker than using rowmin)
        S.attyear = year(datediag_by[S.atrisk_all_index] :+ tstart_j*365.241)
        tmpselect = selectindex(S.attyear:>S.pmmaxyear)
        if(cols(tmpselect)) S.attyear[tmpselect] = J(rows(tmpselect),1,S.pmmaxyear) 
        S.attyear = S.attyear :+ S.yearplus

        exprates = PP_gen_exprates(S,1,S.pm,S.attyear):*S.yj  

        expcumhaz[S.atrisk_all_index] = expcumhaz[S.atrisk_all_index] + exprates
        expsurv_tj = exp(-(expcumhaz[atrisk_index]))

        if(S.hasminexpsurv) {
          tmpselect = selectindex(expsurv_tj:<S.minexpsurv)
          expsurv_tj[tmpselect] = J(rows(tmpselect),1,S.minexpsurv)
        }
        if(S.haspopmort2) {
          if(S.haspmyear2) tmpattyear = S.attyear
          else tmpattyear = J(rows(S.atrisk_all_index),1,1)

          exprates2 = PP_gen_exprates(S,2,S.pm2,tmpattyear):*S.yj
	  
          expcumhaz2[S.atrisk_all_index] = expcumhaz2[S.atrisk_all_index] + exprates2
          expsurv2_tj = exp(-(expcumhaz2[atrisk_index])) 
          if(S.hasminexpsurv) {
            tmpselect = selectindex(expsurv2_tj:<S.minexpsurv)
            expsurv2_tj[tmpselect] = J(rows(tmpselect),1,S.minexpsurv)
          }
        }

        died_tj = (t_by[atrisk_index]:==tj) :& d_by[atrisk_index]  
        died_tj_select = selectindex(died_tj)
	
        if(!S.ederer2) wt_atrisk = (indweights_by[atrisk_index]:*expsurv2_tj):/expsurv_tj        
        else wt_atrisk = indweights_by[atrisk_index]:*expsurv2_tj     

        if(cols(died_tj_select)) {
          N_wt = quadcolsum(wt_atrisk[died_tj_select])
          v1   = quadcolsum((wt_atrisk[died_tj_select]:^2))
        }
        else {
          N_wt = 0
          v1   = 0
        }
        Y_wt = quadcolsum(wt_atrisk)	

        if(!S.dropexpected) lambda_e_tmp[j] = (N_wt - quadcolsum(wt_atrisk:*exprates[exprates_index]))/Y_wt
        else lambda_e_tmp[j] = (N_wt)/Y_wt

        if(!S.dropexpected) lambda_e_tmp[j] = (N_wt - quadcolsum(wt_atrisk:*exprates[exprates_index]))/Y_wt
        else lambda_e_tmp[j] = (N_wt)/Y_wt
        lambda_e_tmp_var[j] = (v1/(Y_wt:^2))

// Crude probabilities and allcause
        if(S.hascrudeprob | S.hasallcause) {
          if(!S.haspopmort2) { 
            sumatrisk             =  quadcolsum(indweights_by[atrisk_index])

            if(sum(died_tj_select)) {
              Ndied_tj  =  quadcolsum((indweights_by[atrisk_index])[died_tj_select])
              v2        =  quadcolsum((indweights_by[atrisk_index])[died_tj_select]:^2)
            }
            else {
              Ndied_tj = 0
              v2 = 0
            }
            lambda_all_tmp[j]     =  Ndied_tj/sumatrisk
            lambda_all_tmp_var[j] =  v2/sumatrisk:^2
            lambda_pop1_tmp[j]    =  quadcolsum(exprates[exprates_index]:*indweights_by[atrisk_index])/sumatrisk
          }
          else {
            sumatrisk             =  quadcolsum(indweights_by[atrisk_index])
            lambda_all_tmp[j]     =  N_wt/Y_wt
            lambda_all_tmp_var[j] =  v1/((Y_wt:^2))
            lambda_pop1_tmp[j]    =  quadcolsum(wt_atrisk:*exprates[exprates_index]:*indweights_by[atrisk_index])/Y_wt
            lambda_pop2_tmp[j]    =  quadcolsum(wt_atrisk:*exprates2[exprates_index]:*indweights_by[atrisk_index])/Y_wt
          }
        }
      }

// Store contribution to cumulative hazards      
      asarray(S.lambda_e_t,    (s,S.bylevels[k,]),(lambda_e_tmp))
      asarray(S.lambda_e_t_var,(s,S.bylevels[k,]),(lambda_e_tmp_var))
      if(S.hascrudeprob | S.hasallcause) {
      	asarray(S.lambda_all_t, (s,S.bylevels[k,]),(lambda_all_tmp))
      	asarray(S.lambda_all_t_var, (s,S.bylevels[k,]),(lambda_all_tmp_var))
        asarray(S.lambda_pop1_t, (s,S.bylevels[k,]),(lambda_pop1_tmp))
        if(S.haspopmort2) asarray(S.lambda_pop2_t, (s,S.bylevels[k,]),(lambda_pop2_tmp))
      }
    }
  }
}







///////////////f/////////////////
// PP_gen_exprates.mata
//
// Generate expected rates
//
////////////////////////////////

real matrix PP_gen_exprates(struct stpp_info scalar   S,
                            real             scalar   pmnumber,
                            transmorphic     matrix   pm,
                            real             matrix   tmpattyear)

{  
  real matrix  exprates, rateindex, pmotherselect 
  real scalar  p, b, yminmax, ymin, ymax
  
  real matrix tmpexprates, tmpattage, tmpattyear_pmo
  
  exprates = J(rows(S.atrisk_all_index),1,.)
  
  yminmax=minmax(tmpattyear)
  ymin = yminmax[1]
  ymax = yminmax[2]

  for(p=1;p<=S.Npmoth_levels[1,pmnumber];p++) {
    pmotherselect = rowsum(asarray(S.pmothervars_by,pmnumber)[S.atrisk_all_index,] :== 
                    asarray(S.pmoth_levels,pmnumber)[p,]):==S.Npmother[pmnumber] //:& S.atrisk_all[S.atrisk_all_index]

    pmotherselect = selectindex(pmotherselect) 
    tmpexprates = exprates[pmotherselect] 
    tmpattage = S.attage[pmotherselect]

    // some speed gains counting backwards
    tmpattyear_pmo = tmpattyear[pmotherselect]
    for(b=ymax;b>=ymin;b--) {
       rateindex = selectindex((tmpattyear_pmo:==b))
       if(cols(rateindex)) tmpexprates[rateindex] = asarray(pm,asarray(S.pmoth_levels,pmnumber)[p,])[tmpattage[rateindex] , b]
     } 
   
    exprates[pmotherselect] = tmpexprates
   } 
  return(exprates)
}   


/*
Note - pmotherselect is slow - could form an array and just update using S.atrisk_all
Some speed gains by 
  -- counting backwards in loop
  -- select subset of exprates (tmpexprates)
*/


////////////////////////////////
// PP_Gen_results.mata
//
// Gen_cumulative_estimates
//
////////////////////////////////


// TO ADD
//  -- crudeprobs/allcause for standstrata?

void function PP_Gen_cumulative_estimates(struct stpp_info scalar S)
{
  if(S.hasstandstrata) PP_Gen_cumulative_standstrata(S)
  else                 PP_Gen_cumulative_indweights(S)
}


///////////////////////////////////
// PP_Gen_cumulative_standstrata //
///////////////////////////////////

void function PP_Gen_cumulative_standstrata(struct stpp_info scalar S)
{
  real scalar zz, k, s, Nuniq, j, tj
  
  real matrix allcause, 
              tmpmat, tmpmat_v, closesttindex, RS_tmp, RS_tmp_v,
              allcause_lag, lambda_c,
              tmp_CP_t_s, lambda_all_t_var  
              
  S.RS_PP      = asarray_create("real",1)
  S.RS_PP_var  = asarray_create("real",1)
  S.AC     = asarray_create("real",1)
  S.CP_can = asarray_create("real",1)
  S.CP_oth = asarray_create("real",1)
  zz = invnormal(0.5*(1+S.level))              
              
  for(k=1;k<=S.Nbylevels;k++) {
    Nuniq  = S.Nunique_t_k[k]
    tmpmat   = J(Nuniq,S.Nstandlevels,.)
    tmpmat_v = J(Nuniq,S.Nstandlevels,.)
    for(s=1;s<=S.Nstandlevels;s++) {
      for(j=1;j<=Nuniq;j++) {
        tj = asarray(S.unique_t_k,k)[j]
        closesttindex = selectindex(asarray(S.unique_t_sk,(s,k)):==tj)
        if(rows(closesttindex)!=0) {
          tmpmat[j,s]   = asarray(S.lambda_e_t,(s,S.bylevels[k,]))[closesttindex] 
          tmpmat_v[j,s] = asarray(S.lambda_e_t_var,(s,S.bylevels[k,]))[closesttindex]  
        }
      }
      tmpmat[,s]   = quadrunningsum(tmpmat[,s])
      tmpmat_v[,s] = ((exp(-tmpmat[,s]):^2):*quadrunningsum(tmpmat_v[,s]))
  }
  // ADD AC AND CP HERE??
  
  RS_tmp   = J(Nuniq,1,0)
  RS_tmp_v = J(Nuniq,1,0)

  for(s=1;s<=S.Nstandlevels;s++) {
    RS_tmp   = RS_tmp   :+ S.standweights[s]:*exp(-(tmpmat[,s]))
    RS_tmp_v = RS_tmp_v :+ S.standweights[s]:^2:*(tmpmat_v[,s])
   }
   // transform to log scale
   asarray(S.RS_PP_var,k,RS_tmp_v:/(RS_tmp:^2))
   asarray(S.RS_PP,k,(RS_tmp, 
                      exp(ln(RS_tmp):- zz:*sqrt(asarray(S.RS_PP_var,k))), 
                      exp(ln(RS_tmp):+ zz:*sqrt(asarray(S.RS_PP_var,k)))))
  }
}

///////////////////////////////////
// PP_Gen_cumulative_indweights  //
///////////////////////////////////
void function PP_Gen_cumulative_indweights(struct stpp_info scalar S)
{
  real scalar zz, k, s, Nuniq, j, tj
  
  real matrix allcause, 
              tmpmat, tmpmat_v, qqq, RS_tmp, RS_tmp_v,
              allcause_lag, lambda_c,
              tmp_CP_t_s, lambda_all_t_var

              
  S.RS_PP      = asarray_create("real",1)
  S.RS_PP_var  = asarray_create("real",1)
  S.AC         = asarray_create("real",1)
  S.AC_var     = asarray_create("real",1)
  S.CP_can     = asarray_create("real",1)
  S.CP_can_var = asarray_create("real",1)
  S.CP_oth     = asarray_create("real",1)
  S.CP_oth_var = asarray_create("real",1)
  zz = invnormal(0.5*(1+S.level))       
  
  
  for(k=1;k<=S.Nbylevels;k++) {
    asarray(S.RS_PP_var,k,quadrunningsum(asarray(S.lambda_e_t_var,(1,S.bylevels[k,]))))
    
    // Marginal RS
    if(S.hasflemhar) {
      tmpmat = quadrunningsum(asarray(S.lambda_e_t,(1,S.bylevels[k,])))
      
      if(S.hasdeathprob) {
        asarray(S.RS_PP, k, 1:-exp(-(tmpmat, 
                                     tmpmat :- zz:*sqrt(asarray(S.RS_PP_var,k)), 
                                     tmpmat :+ zz:*sqrt(asarray(S.RS_PP_var,k)))))
      }
      else {
        asarray(S.RS_PP, k, exp(-(tmpmat, 
                                  tmpmat :+ zz:*sqrt(asarray(S.RS_PP_var,k)), 
                                  tmpmat :- zz:*sqrt(asarray(S.RS_PP_var,k)))))
      }
    }
    else {
      tmpmat = -quadrunningsum(log(1:-asarray(S.lambda_e_t,(1,S.bylevels[k,]))))
      if(S.hasdeathprob) {
        asarray(S.RS_PP, k, 1:-exp(-(tmpmat, 
                                     tmpmat :- zz:*sqrt(asarray(S.RS_PP_var,k)), 
                                     tmpmat :+ zz:*sqrt(asarray(S.RS_PP_var,k)))))
      }
      else {
        asarray(S.RS_PP, k, exp(-(tmpmat, 
                                  tmpmat :+ zz:*sqrt(asarray(S.RS_PP_var,k)), 
                                  tmpmat :- zz:*sqrt(asarray(S.RS_PP_var,k)))))
      }
    }

    // Marginal all cause    
    if(S.hasallcause | S.hascrudeprob) {
      if(S.haspopmort2) lambda_c = asarray(S.lambda_all_t, (1,S.bylevels[k,])) :- asarray(S.lambda_pop1_t,(1,S.bylevels[k,]))
      
      asarray(S.AC_var,k,quadrunningsum(asarray(S.lambda_all_t_var,(1,S.bylevels[k,]))))
      if(S.hasflemhar) {
        if(S.haspopmort2) allcause = quadrunningsum(lambda_c :+ asarray(S.lambda_pop2_t,(1,S.bylevels[k,])))
        else allcause   = quadrunningsum(asarray(S.lambda_all_t,(1,S.bylevels[k,])))
      }
      else {
        if(S.haspopmort2) allcause = -quadrunningsum(log(1:-(lambda_c :+ asarray(S.lambda_pop2_t,(1,S.bylevels[k,])))))
        else allcause   = -quadrunningsum(log(1:-asarray(S.lambda_all_t,(1,S.bylevels[k,]))))          
      }
      asarray(S.AC,k,PP_log_tran_var(S,allcause, asarray(S.AC_var,k), zz))
    }

    // Marginal crude probs
    if(S.hascrudeprob) {
      if(S.hasdeathprob) {
      	allcause_lag = 1\(1:-asarray(S.AC,k)[,1])[|1,1 \ (S.Nunique_t_k[k]-1),1|]
      }        
      else {
      	allcause_lag = 1\(asarray(S.AC,k)[,1])[|1,1 \ (S.Nunique_t_k[k]-1),1|]
      }   

      if(S.haspopmort2) lambda_c = asarray(S.lambda_all_t,(1,S.bylevels[k,])) :- asarray(S.lambda_pop1_t,(1,S.bylevels[k,]))
      else lambda_c = asarray(S.lambda_all_t,(1,S.bylevels[k,])) :- asarray(S.lambda_pop1_t,(1,S.bylevels[k,]))

      
   	  tmpmat   = quadrunningsum(allcause_lag:*lambda_c)
      Nuniq  = S.Nunique_t_k[k]
      lambda_all_t_var=asarray(S.lambda_all_t_var,(1,S.bylevels[k,])) 
      tmpmat_v = J(Nuniq,1,0)        

      for(j=1;j<=Nuniq;j++) {
        tmpmat_v[j]=quadsum((allcause_lag[1::j,.]):^2 :*(1:-((tmpmat[j]:-tmpmat[1::j,.]):/allcause_lag[1::j,.])):^2:*lambda_all_t_var[1::j,.]) 
       }        
      asarray(S.CP_can_var,k,tmpmat_v) 
      asarray(S.CP_can, k, PP_loglog_tran_var(tmpmat,asarray(S.CP_can_var,k),zz))

      if(S.CP_calcother) {
        tmpmat_v = J(Nuniq,1,0)        
        if(S.haspopmort2) tmpmat = runningsum(allcause_lag:*asarray(S.lambda_pop2_t,(1,S.bylevels[k,])))
    	  else tmpmat = runningsum(allcause_lag:*asarray(S.lambda_pop1_t,(1,S.bylevels[k,])))
        for(j=1;j<=Nuniq;j++) {
          tmpmat_v[j]=quadsum((tmpmat[j]:-tmpmat[1::j,.]):^2:*lambda_all_t_var[1::j,.]) 
        }      
        asarray(S.CP_oth_var,k,tmpmat_v) 
        asarray(S.CP_oth, k, PP_loglog_tran_var(tmpmat,asarray(S.CP_oth_var,k),zz))
      }
    }
  }
}




// PP_log_tran_var
real matrix function PP_log_tran_var(struct stpp_info scalar   S,
                                     real matrix x,
                                     real matrix x_var,
                                     real scalar zz)
{
  real matrix lnx, lnx_se  
  
  lnx    = ln(x)
  lnx_se = sqrt(x_var):/x

  if(S.hasdeathprob) return(1:-exp(-exp((lnx, lnx:-zz:*lnx_se, lnx:+zz:*lnx_se))))
  else return(exp(-exp((lnx, lnx:+zz:*lnx_se, lnx:-zz:*lnx_se))))
}

// PP_log_log_tran_var
real matrix function PP_loglog_tran_var(real matrix x,
                                     real matrix x_var,
                                     real scalar zz)
{
  real matrix lnlnx, lnlnx_se  
  
  lnlnx    = ln(-ln(x))
  lnlnx_se = sqrt(x_var):/(ln(x):*x)

  return(exp(-exp((lnlnx, lnlnx:-zz:*lnlnx_se, lnlnx:+zz:*lnlnx_se))))
}




////////////////////////////////
// PP_Write_list_results      //
//                            //
// Write list results         //
//                            //
////////////////////////////////

void function PP_Write_list_results(struct stpp_info scalar   S)
{
  real matrix         RS_tmplist, AC_tmplist, CP_can_tmplist, CP_oth_tmplist, 
                      tindex, tminindex, tmp,
                      RS_tmplist_var, AC_tmplist_var, 
                      CP_can_tmplist_var, CP_oth_tmplist_var

  real scalar         i, k, j, zz
  
  string matrix       newvars
 
  if(!S.haslist) return
  zz = invnormal(0.5*(1+S.level))              

// create output list
  S.RS_list_matrix = asarray_create("real",1)
  S.RS_list_var    = asarray_create("real",1)
  if(S.hasallcause)  {
    S.AC_list_matrix     = asarray_create("real",1)
    S.AC_list_var    = asarray_create("real",1)
  }
  if(S.hascrudeprob) {
    S.CP_can_list_matrix = asarray_create("real",1)
    S.CP_can_list_var    = asarray_create("real",1)    
  }
  if(S.CP_calcother) {
    S.CP_oth_list_matrix = asarray_create("real",1)
    S.CP_oth_list_var    = asarray_create("real",1)        
  }

  if(S.hascontrast) {
    S.RS_list_contrast = asarray_create("real",1)
    if(S.hasallcause)  S.AC_list_contrast     = asarray_create("real",1)
    if(S.hascrudeprob) S.CP_can_list_contrast = asarray_create("real",1)
    if(S.CP_calcother) S.CP_oth_list_contrast = asarray_create("real",1)
  }

// create upper and lower bounds at list times
// Note variance is stored, so can be used later for contrasts
  for(k=1;k<=S.Nbylevels;k++) {
    RS_tmplist         = J(S.Nlist,4,.)
    RS_tmplist_var     = J(S.Nlist,1,.)
    AC_tmplist         = J(S.Nlist,4,.)
    AC_tmplist_var     = J(S.Nlist,1,.)
    CP_can_tmplist     = J(S.Nlist,4,.)
    CP_can_tmplist_var = J(S.Nlist,1,.)
    CP_oth_tmplist     = J(S.Nlist,4,.)
    CP_oth_tmplist_var = J(S.Nlist,1,.)
    for(i=1;i<=S.Nlist;i++) {
      tindex = selectindex(asarray(S.unique_t_k,k):<=S.list[i])
      minindex(S.list[i]:-asarray(S.unique_t_k,k)[tindex],1,tminindex,tmp=.)
      if(S.list[i]<=asarray(S.maxt_k,k) & S.list[i]>=asarray(S.mint_k,k)) {
        RS_tmplist[i,]    = (S.list[i],asarray(S.RS_PP, k)[tminindex,])
        RS_tmplist_var[i] = asarray(S.RS_PP_var, k)[tminindex,]
        if(S.hasallcause)  {
          AC_tmplist[i,]     = (S.list[i],asarray(S.AC, k)[tminindex,])    
          AC_tmplist_var[i] = asarray(S.AC_var, k)[tminindex,]
        }
        if(S.hascrudeprob) {
          CP_can_tmplist[i,] = (S.list[i],asarray(S.CP_can, k)[tminindex,])  
          CP_can_tmplist_var[i] = asarray(S.CP_can_var, k)[tminindex,]
        }
        if(S.CP_calcother) {
          CP_oth_tmplist[i,]    = (S.list[i],asarray(S.CP_oth, k)[tminindex,])
          CP_oth_tmplist_var[i] = asarray(S.CP_oth_var, k)[tminindex,]
        }
      }
      else if(S.list[i]<asarray(S.mint_k,k)) {
        if(S.hasdeathprob) RS_tmplist[i,] = (S.list[i],0,0,0)
        else RS_tmplist[i,] = (S.list[i],1,1,1)
        RS_tmplist_var[i] = 0
        if(S.hasallcause)  {
          AC_tmplist_var[i] = 0
          if(S.hasdeathprob) AC_tmplist[i,] = (S.list[i],0,0,0)    
          else AC_tmplist[i,] = (S.list[i],1,1,1)    
        }
        if(S.hascrudeprob) CP_can_tmplist[i,] = (S.list[i],0,0,0)  
        if(S.CP_calcother) CP_oth_tmplist[i,] = (S.list[i],0,0,0)        
      }
      else {
        RS_tmplist[i,1] = (S.list[i])
        if(S.hasallcause)  AC_tmplist[i,1]     = (S.list[i])    
        if(S.hascrudeprob) CP_can_tmplist[i,1] = (S.list[i])  
        if(S.CP_calcother) CP_oth_tmplist[i,1] = (S.list[i])
      }

      if(S.list[i]>asarray(S.maxt_k,k) & S.list[i]<=asarray(S.maxtall_k,k)) {
        RS_tmplist[i,] = (S.list[i],asarray(S.RS_PP, k)[tminindex,])
        RS_tmplist_var[i] = asarray(S.RS_PP_var, k)[tminindex,]
        if(S.hasallcause)  {
          AC_tmplist[i,]     = (S.list[i],asarray(S.AC, k)[tminindex,])  
          AC_tmplist_var[i] = asarray(S.AC_var, k)[tminindex,]
        }
        if(S.hascrudeprob) {
          CP_can_tmplist[i,] = (S.list[i],asarray(S.CP_can, k)[tminindex,])  
          CP_can_tmplist_var[i] = asarray(S.CP_can_var, k)[tminindex,]
        }
        if(S.CP_calcother) {
          CP_oth_tmplist[i,] = (S.list[i],asarray(S.CP_oth, k)[tminindex,])
          CP_oth_tmplist_var[i] = asarray(S.CP_oth_var, k)[tminindex,]          
        }
      }
    }
    
    asarray(S.RS_list_matrix,k,RS_tmplist)
    if(S.hasallcause)  asarray(S.AC_list_matrix ,k,AC_tmplist)
    if(S.hascrudeprob) asarray(S.CP_can_list_matrix,k,CP_can_tmplist)
    if(S.CP_calcother) asarray(S.CP_oth_list_matrix,k,CP_oth_tmplist)
    if(S.hascontrast) {
      if(S.contrasttype=="difference") {
        asarray(S.RS_list_var,k,((asarray(S.RS_list_matrix,k)[,2]):^2):*RS_tmplist_var)
        if(S.hasallcause) {
          asarray(S.AC_list_var,k,((asarray(S.AC_list_matrix,k)[,2]):^2):*AC_tmplist_var)
        }
        if(S.hascrudeprob)  {
          asarray(S.CP_can_list_var,k,((asarray(S.CP_can_list_matrix,k)[,2]):^2):*CP_can_tmplist_var)          
        }
        if(S.CP_calcother)  {
          asarray(S.CP_oth_list_var,k,((asarray(S.CP_oth_list_matrix,k)[,2]):^2):*CP_oth_tmplist_var)          
        }        
      }
    }    
  }

// Calc contrasts
  if(S.hascontrast) PP_calc_list_contrast(S)


// List results
// Also creates results to store in matrices/frame
  if(S.haslist) {
    PP_calc_return_matrices(S)
    PP_print_list_results(S)
  }
// Write results to a frame  
  if(S.hasframe) PP_write_frame_results(S)
}


///////////////////////////
// PP_calc_list_contrast //
///////////////////////////
void function PP_calc_list_contrast(struct stpp_info scalar S)
{
  real scalar refindex, k, tmpreflevel, tmprefindex, zz

  real colvector diff, diff_se, diff_lci, diff_uci
  
  zz = invnormal(0.5*(1+S.level))              
  
  S.bylevel_isref = J(0,1,.)
  refindex = selectindex(S.byvars:==S.contrast_basevar)
  for(k=1;k<=S.Nbylevels;k++) {
    tmpreflevel = S.bylevels[k,]
    tmpreflevel[,refindex] = S.contrast_baselevel
    tmprefindex = selectindex(rowsum(S.bylevels :== tmpreflevel):==J(S.Nbylevels,1,S.Nbyvars))
    S.bylevel_isref = S.bylevel_isref \ tmprefindex
    
    
    if(k==tmprefindex) {
      asarray(S.RS_list_contrast,k,J(S.Nlist,3,.))
      if(S.hasallcause)  asarray(S.AC_list_contrast,k,J(S.Nlist,3,.))
      if(S.hascrudeprob) asarray(S.CP_can_list_contrast,k,J(S.Nlist,3,.)) 
      if(S.CP_calcother) asarray(S.CP_oth_list_contrast,k,J(S.Nlist,3,.))     
    }
    else {
      diff     = asarray(S.RS_list_matrix ,k)[,2] :- asarray(S.RS_list_matrix ,tmprefindex)[,2]
      diff_se  = sqrt(asarray(S.RS_list_var ,k) :+ asarray(S.RS_list_var ,tmprefindex))
      diff_lci = diff :- zz:*diff_se
      diff_uci = diff :+ zz:*diff_se
      asarray(S.RS_list_contrast,k,(diff,diff_lci,diff_uci))
      if(S.hasallcause) {
        diff     = asarray(S.AC_list_matrix ,k)[,2] :- asarray(S.AC_list_matrix ,tmprefindex)[,2]
        diff_se  = sqrt(asarray(S.AC_list_var ,k) :+ asarray(S.AC_list_var ,tmprefindex))
        diff_lci = diff :- zz:*diff_se
        diff_uci = diff :+ zz:*diff_se
        asarray(S.AC_list_contrast,k,(diff,diff_lci,diff_uci))        
      }
      if(S.hascrudeprob) {
        diff     = asarray(S.CP_can_list_matrix ,k)[,2] :- asarray(S.CP_can_list_matrix ,tmprefindex)[,2]
        diff_se  = sqrt(asarray(S.CP_can_list_var ,k) :+ asarray(S.CP_can_list_var ,tmprefindex))
        diff_lci = diff :- zz:*diff_se
        diff_uci = diff :+ zz:*diff_se
        asarray(S.CP_can_list_contrast,k,(diff,diff_lci,diff_uci))              
      }
      if(S.CP_calcother) {
        diff     = asarray(S.CP_oth_list_matrix ,k)[,2] :- asarray(S.CP_oth_list_matrix ,tmprefindex)[,2]
        diff_se  = sqrt(asarray(S.CP_oth_list_var ,k) :+ asarray(S.CP_oth_list_var ,tmprefindex))
        diff_lci = diff :- zz:*diff_se
        diff_uci = diff :+ zz:*diff_se
        asarray(S.CP_oth_list_contrast,k,(diff,diff_lci,diff_uci))                      
      }
    }
  }
  // remove repeats
  S.bylevel_isref = uniqrows(S.bylevel_isref)
}  


/////////////////////////////
// PP_calc_return_matrices //
/////////////////////////////
void function PP_calc_return_matrices(struct stpp_info scalar S)
{
  string scalar  rmatname, bytext
  
  real matrix tempPP, tempAC, tempCP_can, tempCP_oth
  real matrix tempPP_contrast, tempAC_contrast, 
              tempCP_can_contrast, tempCP_oth_contrast
  
  real scalar k
  
  
  st_rclear()
  
  tempPP = J(0,S.Nbyvars+4,.)
  if(S.hasallcause) tempAC = J(0,S.Nbyvars+4,.)
  if(S.hascrudeprob) tempCP_can = J(0,S.Nbyvars+4,.)
  if(S.CP_calcother) tempCP_oth = J(0,S.Nbyvars+4,.)       
  if(S.hascontrast) {
    tempPP_contrast = J(0,3,.)    
    if(S.hasallcause) tempAC_contrast = J(0,3,.)    
    if(S.hascrudeprob) tempCP_can_contrast = J(0,3,.)    
    if(S.CP_calcother) tempCP_oth_contrast = J(0,3,.)           
  }

// tempPP, tempAC, tempCP_can, tempCP_oth store information for
// return matrices and frame
// temppPP_con etc do the same for contrasts for frames
  for(k=1;k<=S.Nbylevels;k++) {
    if(S.hasby) {
      tempPP = tempPP \ (J(rows(asarray(S.RS_list_matrix,k)),1,S.bylevels[k,]),asarray(S.RS_list_matrix,k))
      rmatname = "r(PP" + strofreal(k) + ")"
      st_matrix(rmatname,tempPP)
      if(S.hascontrast) tempPP_contrast = tempPP_contrast \ asarray(S.RS_list_contrast,k)
    }
    else {
      tempPP = asarray(S.RS_list_matrix,k) 
    }

    if(S.hasallcause) {
      if(S.hasby) {
        tempAC = tempAC \ (J(rows(asarray(S.AC_list_matrix,k)),1,S.bylevels[k,]),asarray(S.AC_list_matrix,k))
        rmatname = "r(AC" + strofreal(k) + ")"
        st_matrix(rmatname,tempAC)
        if(S.hascontrast) tempAC_contrast = tempAC_contrast \ asarray(S.AC_list_contrast,k)
      }
      else tempAC = asarray(S.AC_list_matrix,k)
    }

    if(S.hascrudeprob) {
    	if(!S.hasby) rmatname = "r(CP_can)"
      else rmatname = "r(CP_can" + strofreal(k) + ")"
      if(S.hasby) {
         tempCP_can = tempCP_can \ (J(rows(asarray(S.CP_can_list_matrix,k)),1,S.bylevels[k,]),asarray(S.CP_can_list_matrix,k))
         if(S.hascontrast) tempCP_can_contrast = tempCP_can_contrast \ asarray(S.CP_can_list_contrast,k)
      }
      else tempCP_can = asarray(S.CP_can_list_matrix,k) 
      st_matrix(rmatname,tempCP_can)
     
      if(S.CP_calcother) {
    	  if(!S.hasby) rmatname = "r(CP_oth)"
        else rmatname = "r(CP_oth" + strofreal(k) + ")"
        if(S.hasby) {
           tempCP_oth = tempCP_oth \ (J(rows(asarray(S.CP_oth_list_matrix,k)),1,S.bylevels[k,]),asarray(S.CP_oth_list_matrix,k))
           if(S.hascontrast) tempCP_oth_contrast = tempCP_oth_contrast \ asarray(S.CP_oth_list_contrast,k)
        }        	
        else tempCP_oth = asarray(S.CP_oth_list_matrix,k) 
        st_matrix(rmatname,tempCP_oth)
      }
    }
  }

  // return results to store in frame  
  S.RS_frame_results = tempPP
  if(S.hasallcause) S.AC_frame_results = tempAC
  if(S.hascrudeprob) {
    S.CP_can_frame_results = tempCP_can
    if(S.CP_calcother) S.CP_oth_frame_results = tempCP_can
  }
  if(S.hascontrast) {
    S.RS_frame_contrast = tempPP_contrast
    if(S.hasallcause)  S.AC_frame_contrast = tempAC_contrast
    if(S.hascrudeprob) S.CP_can_frame_contrast = tempCP_can_contrast
    if(S.CP_calcother) S.CP_oth_frame_contrast = tempCP_oth_contrast   
  }
  
  // SHOULD REALLY WRITE THESE straight to R matrices
  st_matrix("PP",tempPP)
  if(S.hasallcause) st_matrix("AC",tempAC)
  if(S.hascrudeprob) st_matrix("CP_can",tempCP_can)  
  if(S.CP_calcother) st_matrix("CP_oth",tempCP_oth)  
}

////////////////////////////
// PP_print_list_results  //
////////////////////////////
void function PP_print_list_results(struct stpp_info scalar S)
{
  pointer scalar  outtype, conttype
  
  string scalar   method, methodshort, bytext, title1
  real   scalar   i,j,k
  
  if(S.display == "NONE") return
  
  if(S.display == "RS") {
    outtype = &S.RS_list_matrix
    conttype = &S.RS_list_contrast   
    if(S.ederer2) {
      method = "Ederer II"
      methodshort = "E2"
    }
    else {
      method = "Pohar Perme"
      methodshort = "PP"
    }
    if(S.haspopmort2) {
      method = "Sasieni and Brentnall"
      methodshort = "SB"
    }
    title1 = "Marginal Relative Survival (" + method + ")"
  }  
  
  
  
  

  else if(S.display=="AC") {
    outtype = &S.AC_list_matrix
    conttype = &S.AC_list_contrast
    methodshort = "AC"
    if(S.hasdeathprob) title1 = "Marginal all cause probability of death"
    else title1 = "Marginal all cause probability of survival"
    if(S.haspopmort2) title1 = title1 + 
                      " (Reference Adjusted)"
    title1 = title1 + "."
    
  }
  else if(S.display=="CP") {
    outtype = &S.CP_can_list_matrix
    conttype = &S.CP_can_list_contrast
    methodshort = "CP"
    title1 = "Marginal crude probability of death"
    if(S.haspopmort2) title1 = title1 + 
                      " (Reference Adjusted)"
    title1 = title1 + "."    
  }
  if(S.hasstandstrata) title1 = title1 +
                       "\n(Standardized by " + S.standstrata_var + ")."
  if(S.hasindweights) title1 = title1 +    
                       "\n(Incorporating individual weights, " + S.indweights_var + ")."
  if(S.hascontrast)   title1 = title1 +    
                       "\nFor contrasts, reference is " + S.contrast_basevar + " = " +
                      strofreal(S.contrast_baselevel) + "." 
  title1 = title1 + "\n\n"
  

  printf(title1)
  
  
  for(k=1;k<=S.Nbylevels;k++) {

    if(S.hasby) {
  	  bytext = ""
  	  for(j=1;j<=S.Nbyvars;j++) {
  	    bytext = bytext + S.byvars[j] + " = " + strofreal(S.bylevels[k,j])  + (j!=S.Nbyvars):*", "
  	  }
  	printf("{txt}-> %s\n\n",bytext)
    }
   
    printf("{txt}{space   2}Time{space   5}{c |}   " + methodshort+"{space 3}(%s{txt}%% CI)" ,strofreal(S.level*100))
    if(S.hascontrast) printf("{space 9} {c |}{space 3}Difference (%s{txt}%% CI)",strofreal(S.level*100))
    printf("\n")
    printf("{hline 11}{c +}{hline 26}")		
    if(S.hascontrast) printf("{c +}{hline 30}")
    printf("\n")
    
    for(i=1;i<=S.Nlist;i++) {
      printf("{res}%6.3g{space 5}{txt}{c |}{space 2}{res}%5.3f (%5.3f to %5.3f)",
      asarray(*outtype,k)[i,1],
      asarray(*outtype,k)[i,2],
      asarray(*outtype,k)[i,3],
      asarray(*outtype,k)[i,4])
      if(S.hascontrast) {
        if(sum(k:==S.bylevel_isref)) {
          printf("{space 2}{txt}{c |}{space 10}-")
        }
        else {
          printf("{space 2}{txt}{c |}{space 3}{res}%6.3f (%6.3f to %6.3f)",
                  asarray(*conttype,k)[i,1],
                  asarray(*conttype,k)[i,2],
                  asarray(*conttype,k)[i,3])
        }
      }
      printf("\n")
  
    }
    printf("{txt}{hline 11}{c +}{hline 26}")
    if(S.hascontrast) printf("{c +}{hline 30}")
    printf("\n\n")  
  }
}


////////////////////////////
// PP_write_frame_results //
////////////////////////////
void function PP_write_frame_results(struct stpp_info scalar S)
{
  string   scalar     currentframe, RSname
  string rowvector    newvars
  
  if(S.hasframe) {
    currentframe = st_framecurrent()
    st_framecreate(S.resframe)
    st_framecurrent(S.resframe)
    
    if(S.haspopmort2) RSname = "SB"
    else if(S.ederer2) RSname = "E2"
    else RSname = "PP"

    newvars = (S.byvars,"time",RSname,RSname+"_lci",RSname+"_uci")
    (void) st_addvar("double", newvars)
    st_addobs(rows(S.RS_frame_results)) 
    st_store(.,newvars,.,S.RS_frame_results)

    if(S.hasallcause) {
      newvars = ("AC","AC_lci","AC_uci")
      (void) st_addvar("double", newvars)
      st_store(.,newvars,.,S.AC_frame_results[,(2+S.Nbyvars:*S.hasby)..cols(S.RS_frame_results)])
    }
    if(S.hascrudeprob) {
      newvars = ("CP_can","CP_can_lci","CP_can_uci")
      (void) st_addvar("double", newvars)
      st_store(.,newvars,.,S.CP_can_frame_results[,(2+S.Nbyvars:*S.hasby)..cols(S.RS_frame_results)])
      if(S.CP_calcother) {
        newvars = ("CP_oth","CP_oth_lci","CP_oth_uci")
        (void) st_addvar("double", newvars)        
        st_store(.,newvars,.,S.CP_oth_frame_results[,(2+S.Nbyvars:*S.hasby)..cols(S.RS_frame_results)])
      }
    } 
    
    if(S.hascontrast) {
      newvars = (RSname+"_diff",RSname+"_diff_lci",RSname+"_diff_uci")
      (void) st_addvar("double", newvars)
      st_store(.,newvars,.,S.RS_frame_contrast:*S.contrast_per)
      if(S.hasallcause) {
        newvars = ("AC_diff","AC_diff_lci","AC_diff_uci")
        (void) st_addvar("double", newvars)
        st_store(.,newvars,.,S.AC_frame_contrast:*S.contrast_per)        
      }
      if(S.hascrudeprob) {      
        newvars = ("CP_can_diff","CP_can_diff_lci","CP_can_diff_uci")
        (void) st_addvar("double", newvars)
        st_store(.,newvars,.,S.CP_can_frame_contrast:*S.contrast_per)                
      }
      if(S.CP_calcother) {      
        newvars = ("CP_oth_diff","CP_oth_diff_lci","CP_oth_diff_uci")
        (void) st_addvar("double", newvars)
        st_store(.,newvars,.,S.CP_oth_frame_contrast:*S.contrast_per)    
      }
    }
    st_framecurrent(currentframe)
  }
}


////////////////////////////////
// PP_Write_new_variables
//
// Write list results
//
////////////////////////////////


void function PP_Write_new_variables(struct stpp_info scalar  S) 
{
  real scalar k
  real matrix data_k, return_data
  string scalar framename, newvars, newvars_merge
  
  framename = "stpp_tmpdataframe"
  
  if(st_frameexists(framename)) st_framedrop(framename)  	
  st_framecreate(framename)
  for(k=1;k<=S.Nbylevels;k++) {
    data_k = asarray(S.unique_t_k,k),              // _t 
             J(S.Nunique_t_k[k],1,1)               // _d
    if(S.hasby) data_k = data_k, J(S.Nunique_t_k[k],1,S.bylevels[k,]) // by vars
    data_k = data_k, J(S.Nunique_t_k[k],1,1)
    data_k = data_k, asarray(S.RS_PP, k)
    if(S.hasallcause) data_k = data_k, asarray(S.AC, k)
    if(S.hascrudeprob) {
    	data_k = data_k, asarray(S.CP_can, k)
      if(S.CP_calcother) data_k = data_k, asarray(S.CP_oth, k)
    }

    if(k==1) return_data = J(0,cols(data_k),.)
    return_data = return_data \ data_k
  }
  newvars_merge = "_t", "_d", S.byvars, S.touse
  newvars = S.RS_newvarname,S.RS_newvarname+"_lci", S.RS_newvarname+"_uci"
  if(S.hasallcause) newvars = newvars, S.AC_newvarname,S.AC_newvarname+"_lci", S.AC_newvarname+"_uci"
  if(S.hascrudeprob) {
  	newvars = newvars, S.CP_newvarnames[1],S.CP_newvarnames[1]+"_lci", S.CP_newvarnames[1]+"_uci"
    if(S.CP_calcother) newvars = newvars, S.CP_newvarnames[2],S.CP_newvarnames[2]+"_lci", S.CP_newvarnames[2]+"_uci"
  }
  
  st_framecurrent(framename)
  (void) st_addvar("double", (newvars_merge,newvars))
  st_addobs(rows(return_data)) 
  st_store(.,(newvars_merge,newvars),.,return_data)
  st_framecurrent(S.currentframe)
  if(S.verbose) printf("\nVariables " + invtokens(newvars) + " created")
}



////////////////////////////////
// PP_Utility
//
// Utility functions for stpp
//
////////////////////////////////


// cumulative product of a matrix
function PP_cumproduct(real matrix X)
{
  real scalar Ncols, i
  real matrix retmat
  
  Ncols = cols(X)
  
  retmat = J(Nrows(X),Ncols,.)
  for(i=1;i<=Ncols;i++) {
    retmat[,i] = exp(quadrunningsum(log(X[,i])))
  }
  return(retmat)
}  


////////////////////////////////
// PP_verbose_print.mata
//
// Print some verbose info
//
////////////////////////////////

// print details of by and standstrata level
void function PP_verbose_print_by_strata(struct stpp_info scalar   S,
                                         real             scalar   k,
                                         real             scalar   s)
{
  string scalar bytext
  real scalar b  
  if(S.hasby) {
    bytext = ""
    for(b=1;b<=S.Nbyvars;b++) {
      bytext = bytext + S.byvars[b] + " = " + strofreal(S.bylevels[k,b])  + (b!=S.Nbyvars):*", "
    }	
    if(S.hasstandstrata) printf("\nStratum: %s = %3.0f",S.standstrata_var,s)
    printf("\n%s\n",bytext)
  }
  printf("\nLooping over Risksets\n")
}


// print dots
void function PP_verbose_print_dots()
{
  printf(".")
  displayflush()
}   


end

