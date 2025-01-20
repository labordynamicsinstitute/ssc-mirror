*! version 0.2 2024-12-05
program define genindweights, rclass sortpreserve
  syntax newvarlist(max=1)  [if][in], [                            ///
                                        AGEGroup(varname)          ///
                                        BY(varlist)                ///
                                        NAGEGroups(integer 5)      ///
                                        OBSproportion(string)      ///
                                        REFConditional(string)     ///
                                        REFEXTernal(string)        ///
                                        REFFRame(string)           /// 
                                        REFProportion(string)      ///
                                        SAVEREFFrame(string)       ///
                                        STIGnore                   ///
                                        noSUMmary                  ///
                                      ]
  
  marksample touse, novarlist
    
  local newvarname `varlist'
// Error checks 
  if "`stignore'" == "" {
    st_is 2 analysis
    
    qui count if _st==0 & `touse'
    if `r(N)'>0 {
      di as error "You have values of _st=0." ///
                  "Either drop these of use an if statement."
                  exit 198
    }
  }
  
  if "`agegroup'"=="" & ("`refexternal'" != "") {
    di as error "You must specify the agegroup() option when" ///
                "using refexternal()"
    exit 198
  } 
  

  if "`agegroup'" !="" & ("`refconditional'`refframe'" != "") {
    di as error "Do not use the agegroup() option when using refconditional() or refframe()."
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
    qui gen `cons' = 1 if `touse'
    local by `cons'
    local nobyoption nobyoption
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
    local refwtname refp
  }
  if "`refframe'" != "" {
    Parse_refframe `refframe'
    local refframetmp `r(refframename)'
    local refwtname `r(refframe_refwtname)'
    local refframe_strata `r(refframe_strata)'
    qui frlink m:1 `refframe_strata', frame(`refframetmp')

  }

  if "`refconditional'" != "" {
    // check for comma or do some parsing first?  
    GetRefcond `refconditional' touse(`touse')  ///
                         refframetmp(`refframetmp')
    qui frlink m:1 `refcond_strata', frame(`refframetmp')
    local refwtname refp
  }

// calculate observed proportions in by/agegroup combinations
  tempvar bygrouptotal bygrouptotal_agegrp obsby_proportion
  qui bysort `by':  egen `bygrouptotal' = total(`touse') if `touse'   
  qui bysort `by' `refframe_strata' `refcond_strata' `agegroup':  egen `bygrouptotal_agegrp' = total(`touse') if `touse'   
  qui gen double `obsby_proportion' = `bygrouptotal_agegrp'/`bygrouptotal' if `touse'
  
  // Now merge in reference proportions & calculate indweight
  
  tempvar refproportion
  qui frget `refproportion' = `refwtname', from(`refframetmp')
  qui gen double `newvarname' = `refproportion'/`obsby_proportion' if `touse'
 
  if "`summary'" == "" {
    tempvar first
    tempname summframe
    qui bysort `touse' `by' `refframe_strata' `refcond_strata' `agegroup': gen `first'=_n==1
    frame put `by' `refframe_strata' `refcond_strata' `agegroup' `obsby_proportion' `refproportion' `newvarname' if `first' & `touse', into(`summframe')
    frame `summframe' {
      qui rename `obsby_proportion' obs
      qui rename `refproportion' ref
      di "Summary of weights" _continue
      local addby = cond("`nobyoption'"=="","`by'","")
      list `addby' `refframe_strata' `refcond_strata' `agegroup' obs ref `newvarname', noobs abbrev(30) sepby(`by')
      di as result  "Observed proportions (obs): reference proportions (ref) and relative weights (`newvarname')"
    }
  }
 
// save obsproportion / refproportion and frame
  if "`newobsproportion'" != "" {
    qui gen double `newobsproportion' = `obsby_proportion' if `touse'
  }
  if "`newrefproportion'" != "" {
    qui gen double `newrefproportion' = `refproportion' if `touse'
  }  
  if "`saverefframe'" != "" {
    Parse_saverefframe `saverefframe'
    local saverefframename `r(saverefframename)'
    local saverefframevarname `r(saverefframe_refwtname)'
    frame copy `refframetmp' `saverefframename', `r(saverefframereplace)'
    if "`refwtname'" != "`saverefframevarname'" {
      frame `saverefframename': rename `refwtname' `saverefframevarname'
    }
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
  syntax anything(name=refframe id="frame name"), strata(string) [refwtname(string)]
  if "`refwtname'" == "" local refwtname refp
  
  frame `refframe': capture confirm var `refwtname'
  if _rc {
    di as err "Variable `refwtname' not found in frame `refframe'."
    exit 198
  }
  frame `refframe': qui duplicates report `strata'
  if `r(unique_value)' != `r(N)' {
    di as error "Variables listed in strata() suboption of refframe()" ///
       _newline "do not uniquely identify observations in frame `refframe'"
    exit 198
  }
  
  return local refframename `refframe'
  return local refframe_refwtname `refwtname'
  return local refframe_strata `strata'
end

////////////////////////
///   Parse_saverefframe ///
////////////////////////
program define Parse_saverefframe, rclass
  syntax anything(name=refframename id="frame name"), [replace refwtname(string)]
  if "`refwtname'" == "" local refwtname refp
  return local saverefframereplace `replace'
  return local saverefframename `refframename'
  return local saverefframe_refwtname `refwtname'
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
    qui gen double refp = .
    get`reftype', refproportion(refp) nagegroups(`nagegroups')
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
  mata st_store(.,"refp",(0.07,0.12,0.23,0.29,0.29)')
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
  mata st_store(.,"refp",(0.11906,0.16735,0.27593,0.28897,0.14869)')
end

///////////////////
///  getICSS2_5 ///
///////////////////
program define getICSS2_5
  syntax , refproportion(varname) nagegroups(string)
  if `nagegroups' != 5 {
    di as error "ICCS2_5 should have 5 levels for agegroup"
    exit 198
  }
  mata st_store(.,"refp",(0.28,0.17,0.21,0.20,0.14)')
end

///////////////////
///  getICSS2_5N ///
///////////////////
program define getICSS2_5N
  syntax , refproportion(varname) nagegroups(string)
  if `nagegroups' != 5 {
    di as error "ICCS2_5N should have 5 levels for agegroup"
    exit 198
  }
  mata st_store(.,"refp",(0.36283,0.18611,0.22098,0.16262,0.06746)')
end

///////////////////
///  getICSS3_5 ///
///////////////////
program define getICSS3_5
  syntax , refproportion(varname) nagegroups(string)
  if `nagegroups' != 5 {
    di as error "ICCS3_5 should have 5 levels for agegroup"
    exit 198
  }  
  mata st_store(.,"refp",(0.60,0.10,0.10,0.10,0.10)')
end


///////////////////
///  GetRefcond ///
///////////////////
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
    qui gen `refcondexp' = 1 if `touse'
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
  qui bysort `strata': egen `bygrouptotal' = total(`refcondexp' & `touse') if  `touse'  
  qui gen double `refproportion' = `bygrouptotal'/`Nrefexp' if `touse'
  qui gen byte `tousereverse' = 1 - `touse'
  qui bysort `strata' (`tousereverse'): gen `firstrow' = _n==1
  frame put `strata' `refproportion' if `touse' & `firstrow', into(`refframetmp')
  frame `refframetmp': rename `refproportion' refp
  
  c_local refcond_strata `strata'
    
end