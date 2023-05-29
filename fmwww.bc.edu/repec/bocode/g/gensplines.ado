*! version 1.00 2023-05-22
program define gensplines, rclass
  version 16.1
  syntax anything [if][in], [                                      ///
                            ALLKnots(string)                       /// 
                            BKnots(numlist ascending min=2 max=2)  ///
                            CENTer                                 ///
                            CENterv(string)                        ///
                            DEGree(integer 3)                      ///
                            DGEN(string)                           ///
                            DF(string)                             ///
                            FW(varname)                            ///
                            GEN(string)                            ///
                            INTercept                              ///
                            IW(varname)                            ///
                            KNots(numlist ascending)               ///
                            TYPE(string)                           ///
                            SUBCentile(string)                     ///
                            WINsor(string)                         ///
                            ]
  
  marksample touse
  
  // error checks
  if wordcount("`df' `knots' `allknots' `pknots'") == 0 {
    di as error "One of the df(), knots(), allknots() or pknots() options must be specified"
    exit 198
  }
  if (("`df'" != "") + ("`knots'" !="") + ("`allknots'" != "") + ("`pknots'" != ""))>1 {
    di as error "Only one of the df(), knots() or allknots() options must be specified"
    exit 198
  }
  if "`gen'" == "" &  "`dgen'" == "" {
    di as error "At least one of the gen() or dgen() options must be specified"
    exit 198
  }
  if "`fw'" != "" {
    //if "`knots'`allknots'" != "" {
    //  di as error "You can't use the fw() option with knots() or allknots() options."
    //  exit 198
    //}
    local fw [fw=`fw']
  }
  
  if "`iw'" != "" {
    //if "`knots'`allknots'" != "" {
    //  di as error "You can't use the fw() option with knots() or allknots() options."
    //  exit 198
    //}
    local iw [iw=`iw']
  }  
  if "`iw'" != "" & "`fw'" != "" {
  	di as error "Only one of the iw() and fw() options can be specified"
	exit 198
  }
  

// check if variable or scalar

  capture confirm variable `anything'
  if !_rc local xvar `anything'
  else {
    capture confirm number `anything'
    if !_rc local xvalue `anything'
    else {
      di as error "No variable or value given"
      exit 198
    }
  }
  local xvar_orginal `xvar'
  local hasxvar = "`xvar'" != ""

  // Add error checks for scalar
  if "`xvalue'" != "" {
    if "`allknots'" == "" & ("`knots'" == "" & "`bknots'" == "") {
      di as error "You must specify the knots when generating spline for a scalar."
      exit 198
    }
    if "`subcentile'" != "" {
      di as error "The subcentile() option cannot be used for a scalar."
      exit 198
    }
    if "`fw'" != "" {
      di as error "The fw() option cannot be used for a scalar."
      exit 198
    }    
  }
  
  if "`type'"=="" {
    di as error "You must specify the type() option."
    exit 198
  }
  if inlist("`type'","ns","rcs") & `degree' != 3 {
    di as error "You can only use degree(3) when using type(ns) or type(rcs)."
    exit 198
  }
  
  if ("`df'") != "" {
    capture confirm integer number `df'
    if _rc {
      di as error "df() option must give be an integer."
      exit 198
    }
  }
  
  if "`dgen'" != "" {
    if "`type'" == "is" {
      di as error "The dgen() opption is not available for Isplines"
      di as error "You can use Msplines, i.e. type(ms)"
      exit 198
    }
  }
  
  if "`center'" != "" {
    summ `xvar'  if `touse' `fw', meanonly
    local centerv `r(mean)'
  }
  
  if "`centerv'" != "" confirm number `centerv'

  // subcentile option
  if "`subcentile'" != "" {
    capture count if `subcentile'
    if _rc {
      di as error "Illegal subcentile() option"
      exit 198
    }
    local subcentile "& `subcentile'"
  }
  
// winsor options
  if "`winsor'" != "" {
    if strpos("`winsor'",",") == 0 local winsor `winsor',
    GetWinsorOpts `winsor' xvar(`xvar')  touse(`touse')
    if "`xvar'" != "" {
      tempvar xvar_winsor
      local vartype: type `xvar'
      gen `vartype' `xvar_winsor' = cond(`xvar'<=`winsor_low', ///
                                      `winsor_low',        ///
                                      cond(`xvar'>=`winsor_high',`winsor_high',`xvar'))
      local xvar `xvar_winsor'
    }
    else {
      local xvalue_winsor = cond(`xvaluw'<=`winsor_low', ///
                                      `winsor_low',        ///
                                      cond(`xvalue'>=`winsor_high',`winsor_high',`xvalue'))
      local xvalue `xvalue_winsor'
    }
  }  

// Parse allknots
  if "`allknots'" != "" Parseallknots `allknots'
  
// percentiles  
  if "`percentiles'" != "" {
    numlist "`percentiles'", ascending min(0) max(100)
    summ `xvar' if `touse' `subcentile', meanonly
    local minx `r(min)'
    local maxx `r(max)'
    local Np = wordcount("`percentiles'")
    local p1 = word("`percentiles'",1)
    local pN = word("`percentiles'",`Np')
    if `p1'==0 local allknots `minx'
    else {
      _pctile `xvar' if `touse' `subcentile' `fw', p(`p1')
      local allknots `r(r1)'
    }
    forvalues i = 2/`=`Np'-1' {
      local p=word("`percentiles'",`i')
      _pctile `xvar' if `touse' `subcentile' `fw', p(`p')
      local allknots `allknots' `r(r1)'
    }
    if `pN'==100 local allknots `allknots' `maxx'
    else {
      _pctile `xvar' if `touse' `subcentile' `fw', p(`pN')
      local allknots `allknots' `r(r1)'
    }    
  }
  
// bknots, pbknots, & allknots  
  if "`type'" != "tp" {
    if "`bknots'" == "" & "`pbknots'" == "" & "`allknots'" == ""  {
      summ `xvar' if `touse' `subcentile', meanonly
      local bknots `r(min)' `r(max)'
    }
    else if "`allknots'" != "" {
      local bknots `=word("`allknots'",1)' `=word("`allknots'",wordcount("`allknots'"))'
      forvalues k=2/`=wordcount("`allknots'")-1' {
        local knots `knots' `=word("`allknots'",`k')'
      }
    }
  }
  else {
    local knots `allknots'
  }
  
/////////////////////////////////////
// Bsplines / Msplines / Isplines ///
////////////////////////////////////
  if inlist("`type'","bs","ms","is","ibs") { 
    if ("`df'") != "" {
      if (`=`df' - `degree'') <1 {
        di as error "B-splines  / M-splines / Isplines with degree `degree' has a miniumum of df of `=`degree'+1'"
        exit 198
      }
      local Nknots = `df' - `degree' + 1
      _pctile `xvar' if `touse' `subcentile' `fw'`iw', nquantiles(`Nknots')
      forvalues i = 1/`=`Nknots'-1' {
        local knots `knots' `r(r`i')'
      }
      local Nknots = wordcount("`knots'") 

    }
    else {
      local Nknots = wordcount("`knots'") 
      local df     = `Nknots' + `degree' 
    }
  }

////////////////////////////
// Truncated Power Basis ///
////////////////////////////
  if  "`type'" == "tp" { 
    if ("`df'") != "" {
      if (`=`df' - `degree'') <1 {
        di as error "TP-splines with degree `degree' has a miniumum of df of `=`degree'+1'"
        exit 198
      }
      local Nknots = `df' - `degree' + 1
      _pctile `xvar' if `touse' `subcentile' `fw'`iw', nquantiles(`Nknots')
      forvalues i = 1/`=`Nknots'-1' {
        local knots `knots' `r(r`i')'
      }
    }
    else {
      local Nknots = wordcount("`knots'") 
      local df     = `Nknots' + `degree' 
    }
  }  
  
  
////////////////////////////
// Natural Cubic Splines ///
////////////////////////////

  if inlist("`type'","ns","rcs","ins") {
    if ("`df'") != "" {
      if `df'>1 {
        local Nknots = `df' - 1
        _pctile `xvar' if `touse' `subcentile' `fw'`iw', nquantiles(`=`Nknots'+1')
        forvalues i = 1/`=`Nknots'' {
          local knots `knots' `r(r`i')'
        }
      }
      else {
        local centerval = cond("`centerv'" == "","0","`centerv'")
        if "`gen'" != ""  {
          qui gen double `gen'1 = `xvar' - `centerval' if `touse'
        }  
        if "`dgen'" != "" {
          qui gen double `dgen'1 = 1 if `touse'
        }
      }
    }
    else {
      local Nknots = wordcount("`knots'")
      local df     = `Nknots' + 1
    }
  }

  // check duplicates
  local checkdup: list dups knots
  if "`checkdup'" != "" {
    di as error "You have duplicate knot positions"
    exit 198
  }
  // check boundary knots
  if `df' > 1 & "`type'" != "tp" {
    local b1 = word("`bknots'",1)
    local b2 = word("`bknots'",2)
    local mink = word("`knots'",1)
    local maxk = word("`knots'",`Nknots')
    if `b1'>`mink' {
      di as err "Lower boundary is greater than lower internal knot"
      exit 198
    }
    if `b2'<`maxk' {
      di as err "Upper Boundary knot is less than upper internal knot"
      exit 198
    } 

    // for natural splines / restricted cubic splines - boundary knots 
    // cannot be equal to internal knots
    if inlist("`type'","ns","rcs","ins") {
      if `b1'>=`mink' {
        di as err "Lower boundary is greater or equal to lower internal knot"
        exit 198
      }
      if `b2'<=`maxk' {
        di as err "Upper Boundary knot is less than or equal to upper internal knot"
        exit 198
      }   
    }
  }
  
  // returned variables
  local Nnewvar = `df' + `="`intercept'"!=""'
  if "`gen'" != "" {
    forvalues i = 1/`Nnewvar' {
      local splinevarlist `splinevarlist' `gen'`i'
    }
  }
  if "`dgen'" != "" {
    forvalues i = 1/`Nnewvar' {
      local dsplinevarlist `dsplinevarlist' `dgen'`i'
    }
  }
  
  if `df'>1 mata: GS_setup()
    
  return local varname `xvar_orginal'  
  return local value `xvalue'  
  return local type   `type'
  return local center `centerv'
  if `df' > 1 {
    return local knots  `=word("`bknots'",1)' `knots' `=word("`bknots'",2)'
    return local internal_knots `knots'
    return local bknots `bknots' 
  }
  if "`xvar'" != "" {
    return local splinevarlist  `splinevarlist'
    return local dsplinevarlist `dsplinevarlist'
  }
  else {
    return local splinescalarlist  `splinevarlist'
    return local dsplinescalarlist `dsplinevarlist'    
  }
  return local winsor `winsor_low' `winsor_high'
end

program define GetWinsorOpts
  syntax anything [if][in], xvar(string) [values] touse(varname)
  marksample touse
  numlist "`anything'", ascending min(2) max(2)
  
  capture confirm number `xvar'
  if !_rc & "`values'" == "" {
    di as error "If usig the winsor() option with a scalar you need to use the values option."
    exit 198
  }
  
  if "`values'" == "" {
    _pctile `xvar' if `touse' `fw', percentiles(`r(numlist)') 
    c_local winsor_low  `r(r1)'
    c_local winsor_high `r(r2)'
  }
  else {
    tokenize `r(numlist)'
    c_local winsor_low  `1'
    c_local winsor_high `2'
  }
end

program define Parseallknots
  syntax anything, [Percentiles ]
  if "`percentiles'" != "" {
    numlist "`anything'", ascending min(0) max(100)
    c_local percentiles `r(numlist)'
  }
  else {
    numlist "`anything'", ascending
    c_local allknots `anything'
  }
end  