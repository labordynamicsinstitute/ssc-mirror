*! version 0.1 2024-11-17
program define genindweights, rclass sortpreserve
  st_is 2 analysis
  syntax newvarlist(max=1)  [if][in], [                            ///
                                        AGEGroup(varname)          ///
                                        BY(varlist)                ///
                                        NAGEGroups(integer 5)      ///
                                        REFConditional(string)     ///
                                        REFEXTernal(string)        ///
                                        REFFRame(string)           /// 
                                        REFProportion(string)      ///
                                        OBSproportion(string)      ///
                                        SAVEREFFrame(string)       ///
                                      ]
  
  marksample touse, novarlist
    
  local newvarname `varlist'
// Error checks  
  qui count if _st==0 & `touse'
  if `r(N)'>0 {
    di as error "You have values of _st=0." ///
                "Either drop these of use an if statement."
                exit 198
  }
  
  if "`agegroup'"=="" & ("`refexternal'`refframe'" != "") {
    di as error "You must specify the agegroup() option when" ///
                "using refexternal() or refframe()"
    exit 198
  } 
  

  if "`agegroup'" !="" & ("`refconditional'" != "") {
    di as error "Do not use the agegroup() option when using refconditional()"
    exit 198
  }   
  
  if (("`refframe'"!="") +  ("`refconditional'"!="") +  ("`refexternal'"!=""))>1 {
    di as error "Only one of the refframe(), refconditional() and refexternal() can be specified."
    exit 198
  }  

  if wordcount("`refframe' `refconditional' `refexternal'")==0 {
    di as error "You must use one of the refframe(), refconditional() and refexternal() options."
    exit 198
  }    
  
  if "`resframe'" != "" {
    mata: st_local("frameexists",frameexists(st_local("resframe")))
    if !`frameexists' {
      di as error "Frame `resframe' does not exists"
      exit 198
    }
  }
 
  if "`obsproportion'" != "" {
    confirm new var `obsproportion'
    local newobsproportion `obsproportion'
  }
  if "`refproportion'" != "" {
    confirm new var `refproportion'
    local newrefproportion `refproportion'
  }
 

  // check agegroup is an integer
  if "`agegroup'" != "" {
    qui levelsof `agegroup' if `touse', local(agegroup_levels)
    local Nagegroups `r(r)'
  }
// if no by variables define a constant
  if "`by'" == "" {
    tempvar cons
    gen `cons' = 1 if `touse'
    local by `cons'
  }  
  
// check age group not listed in by
 if "`agegroup'" != "" {
   foreach byvar in `by' { 
     if "`byvar'" == "`agegroup'" {
       di as error "Do not include age group in the by variables."
       exit 198
     }
   }
 }
 
// check no missing values in by() opion & all are integers
  foreach var in `by' {
    qui count if missing(`var') & `touse'
    if `r(N)'>0 {
      di as error "There are missing values for `var'." ///
                  "Either drop rows with missing values or use an if statement."
    }
    CheckInteger `var'
  }      
      
// Reference proportions
  tempname refframetmp
  if "`refexternal'" != "" {
    frame create `refframetmp'  
    GetExternalRef, agegroup(`agegroup')  reftype(`refexternal') ///
                    nagegroups(`Nagegroups') agegrouplevels(`agegroup_levels') ///
                    refframetmp(`refframetmp')
    qui frlink m:1 `agegroup', frame(`refframetmp')
    local refwtname refproportion
  }
  if "`refframe'" != "" {
    Parse_refframe `refframe'
    local refframetmp `r(refframename)'
    local refwtname `r(refframe_wtname)'
    local refframe_strata `r(refframe_strata)'
    qui frlink m:1 `refframe_strata', frame(`refframetmp')

  }
  if "`refconditional'" != "" {
    // check for comma or do some parsing first?  
    GetRefcond `refconditional' touse(`touse')  ///
                         refframetmp(`refframetmp')
    qui frlink m:1 `refcond_strata', frame(`refframetmp')
    local refwtname refproportion
  }
  

// calculate observed proportions in by/agegroup combinations
  tempvar bygrouptotal bygrouptotal_agegrp obsby_proportion
  bysort `by': egen `bygrouptotal' = total(`touse') if `touse'   
  bysort `by' `refframe_strata' `refcond_strata' `agegroup': egen `bygrouptotal_agegrp' = total(`touse') if `touse'   
  gen double `obsby_proportion' = `bygrouptotal_agegrp'/`bygrouptotal'
  
  // Now merge in reference proportions & calculate indweight
  tempvar refproportion
  qui frget `refproportion' = `refwtname', from(`refframetmp')
  qui gen double `newvarname' = `refproportion'/`obsby_proportion'
 
// save obsproportion / refproportion and frame
  if "`newobsproportion'" != "" {
    gen double `newobsproportion' = `obsby_proportion'
  }
  if "`newrefproportion'" != "" {
    gen double `newrefproportion' = `refproportion'
  }  
  if "`saverefframe'" != "" {
    frame copy `refframetmp' `saverefframe'
  }
end

/////////////////////
///  CheckInteger ///
/////////////////////
program define CheckInteger 
  syntax varname [if][in]
  marksample touse
  capture assert `varlist'==floor(`varlist') if `touse'
    if _rc {
      di as error "`varlist' should only contain integers"
      exit 198
    }
end

////////////////////////
///   Parse_refframe ///
////////////////////////
program define Parse_refframe, rclass
  syntax anything(name=refframe id="frame name"), strata(string) [wtname(string)]
  if "`wtname'" == "" local wtname refproportion
  
  frame `refframe': capture confirm var `wtname'
  if _rc {
    di as err "Variable `wtname' not found in frame `refframe'."
    exit 198
  }
  frame `refframe': qui duplicates report `strata'
  if `r(unique_value)' != `r(N)' {
    di as error "Variables listed in strata() suboption of refframe()" ///
       _newline "do not uniquely identify observations in frame `refframe'"
    exit 198
  }
  
  return local refframename `refframe'
  return local refframe_wtname `wtname'
  return local refframe_strata `strata'
end

///////////////////////
///  GetExternalRef ///
///////////////////////
program define GetExternalRef
  syntax , agegroup(varname) reftype(string) NAGEGROUPS(string) ///
           agegrouplevels(numlist) refframetmp(string)
  local extreflist ICSS1_5 ICSS1_5N ICSS2_5 ICSS2_5N ICSS3_5
  foreach type in `extreflist' {
    if "`type'" == "`reftype'" local refok ok
  }
  if "`refok'" == "" {
    di as error "`reftype' not valid option for refexternal()."
    exit 198
  }

  frame `refframetmp' {
    qui set obs `nagegroups'
    qui gen `agegroup' = .
    forvalues i = 1/`nagegroups' {
      qui replace `agegroup' = real(word("`agegrouplevels'",`i')) in `i'
    }
    qui gen double refproportion = .
    get`reftype', refproportion(refproportion) nagegroups(`nagegroups')
  }
end

///////////////////
///  getICSS1_5 ///
///////////////////
program define getICSS1_5
  syntax , refproportion(varname) nagegroups(string)
  if `nagegroups' != 5 {
    di as error "ICCS1_5 should have 5 levels for agegroup"
    exit 198
  }
  mata st_store(.,"refproportion",(0.07,0.12,0.23,0.29,0.29)')
end

////////////////////
///  getICSS1_5N ///
////////////////////
program define getICSS1_5N
  syntax , refproportion(varname) nagegroups(string)
  if `nagegroups' != 5 {
    di as error "ICCS1_5N should have 5 levels for agegroup"
    exit 198
  }
  mata st_store(.,"refproportion",(0.11906,0.16735,0.27593,0.28897,0.14869)')
end

///////////////////
///  getICSS2_5 ///
///////////////////
program define getICSS2_5
  if `nagegroups' != 5 {
    di as error "ICCS2_5 should have 5 levels for agegroup"
    exit 198
  }
  mata st_store(.,"refproportion",(0.28,0.17,0.21,0.20,0.14)')
end

///////////////////
///  getICSS2_5N ///
///////////////////
program define getICSS2_5N
  if `nagegroups' != 5 {
    di as error "ICCS2_5N should have 5 levels for agegroup"
    exit 198
  }
  mata st_store(.,"refproportion",(0.36283,0.18611,0.22098,0.16262,0.06746)')
end

///////////////////
///  getICSS3_5 ///
///////////////////
program define getICSS3_5
  if `nagegroups' != 5 {
    di as error "ICCS3_5 should have 5 levels for agegroup"
    exit 198
  }  
  mata st_store(.,"refproportion",(0.60,0.10,0.10,0.10,0.10)')
end

program define GetRefcond, rclass sortpreserve
  syntax [anything(name=refcondexp everything)],  touse(string)         ///
                                                    refframetmp(string)   ///
                                                    strata(varlist)                   
                                                
  foreach var in `strata' {
    CheckInteger `var'
    quietly count if missing(`var') & `touse'
    if `r(N)'>0 {
      di as error "There are missing values for `var'."
      exit 198
    }
  }
  if inlist("`refcondexp'","","."," ") {
    local refcondexp
    tempvar refcondexp
    gen `refcondexp' = 1 if `touse'
    quietly count if `refcondexp'
    local Nrefexp `r(N)'
  }
  else {
    capture count if `refcondexp' & `touse'
    if _rc {
       di as error "Illegal refconditional() expression."
       exit 198
    }
    local Nrefexp `r(N)'
  }
  
  tempvar bygrouptotal refproportion firstrow tousereverse
  bysort `strata': egen `bygrouptotal' = total(`refcondexp' & `touse') if  `touse'  
  gen double `refproportion' = `bygrouptotal'/`Nrefexp' if `touse'
  gen byte `tousereverse' = 1 - `touse'
  bysort `strata' (`tousereverse'): gen `firstrow' = _n==1
  frame put `strata' `refproportion' if `touse' & `firstrow', into(`refframetmp')
  frame `refframetmp': rename `refproportion' refproportion
  
  c_local refcond_strata `strata'
    
end