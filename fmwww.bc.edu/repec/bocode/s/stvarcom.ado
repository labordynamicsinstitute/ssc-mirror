*! Version 1.1.0 2020-12-19
*! Author: Dejin Xie (Nanchang University, China)

** Version 1.1.0 2020-12-19, option "order" and "compress" added
** Version 1.0.0 2019-10-27, the initial version

****** Subset Combinations of String Variable ******

program define stvarcom, rclass
version 13

syntax varname (string) [if] [in] , [ Parse(str asis) Generate(string) Replace ///
                Number(integer 1) Conditionals(string) Unique Order COMpress NOtrim ]

if `c(stata_version)'>=14 {
  local ustr "ustr"
}
if `"`parse'"' == `""' | `"`parse'"' == `""""' {
  local parse " "
}
else {
  local parse : list clean parse
}

if `number'<=0 {
  dis as error "Number of values in combinations (i.e. {it:number(#)}) must be positive integer!"
  exit
}
if "`generate'"~="" & "`replace'"~="" {
  dis as error "option {it:generate(newvars)} or {it:replace} should be set at most one!"
  exit
}
if "`generate'"=="" {
  local generate "`varlist'_Comb"
}
if "`replace'"=="" {
  capture drop `generate'
}
if "`conditionals'"~="" {
  local ConDiOp "conditionals(`conditionals')"
}

marksample touse, novarlist strok

quietly {
tempvar STVaComID STVComnew STVarCom
gen `STVaComID'=_n

if "`notrim'"=="" {
  gen `STVComnew'=`ustr'trim(itrim(`varlist'))
  if `"`parse'"' ~= `"" ""' {
    local Nparse : word count `parse'
    if `Nparse'==1 {
      replace `STVComnew'=subinstr(`STVComnew', `" `parse'"',`"`parse'"',.)
      replace `STVComnew'=subinstr(`STVComnew', `"`parse' "',`"`parse'"',.)
    }
    if `Nparse'>1 {
      tokenize `"`parse'"'
      forvalues j=1/`Nparse' {
        replace `STVComnew'=subinstr(`STVComnew', `" ``j''"',`"``j''"',.)
        replace `STVComnew'=subinstr(`STVComnew', `"``j'' "',`"``j''"',.)
      }
    }
  }
}
else {
  gen `STVComnew'=`varlist'
}
if "`unique'"~="" {
  local Nparse : word count `parse'
  if `Nparse'<=1 {
    forvalues k=1/`c(N)' {
      local STVComL`k'=`STVComnew'[`k']
      if `"`parse'"' ~= `"" ""' {
        local STVComL`k' : subinstr local STVComL`k' "`parse'" " ", all
      }
      local STVComL`k' : list uniq STVComL`k'
      replace `STVComnew'=`"`STVComL`k''"' in `k'
    }
    if `"`parse'"' ~= `"" ""' {
      replace `STVComnew'=subinstr(`STVComnew'," ",`"`parse'"',.)
    }
  }
  if `Nparse'>1 {
    tokenize `"`parse'"'
    forvalues j=1/`Nparse' {
      forvalues k=1/`c(N)' {
        local STVComL`k'=`STVComnew'[`k']
        local STVComL`k' : subinstr local STVComL`k' "``j''" " ", all
        local STVComL`k' : list uniq STVComL`k'
        replace `STVComnew'=`"`STVComL`k''"' in `k'
        replace `STVComnew'=subinstr(`STVComnew'," ","``j''",.)
      }
    }
  }
}

split `STVComnew' if `touse' , parse(`parse') generate(`generate') `notrim'
local SPLNM=`r(nvars)'

if `number'==1 {
  reshape long `generate', i(`STVaComID') j(`STVarCom')
  drop if `generate'==""
  if "`order'"~="" {
    sort `STVaComID' `generate'
  }
  if "`replace'"~="" {
    replace `varlist'=`generate'
    drop `generate'
  }
  else {
    label var `generate' "Combinations (`number' item) of `varlist'"
  }
}
if `number'>1 {
  tuples `generate'* , min(`number') max(`number') `ConDiOp'
  capture drop StvaCombs*
  if `"`parse'"' == `"" ""' {
    local Fparse "-._.-"
  }
  else {
    local Fparse : word 1 of `parse'
  }
  forvalues i=1/`ntuples' {
    gen StvaCombs`i'=`ustr'trim(itrim("`tuple`i''"))
    replace StvaCombs`i'=subinstr(StvaCombs`i'," ",`"+"`Fparse'"+"',.)
    replace StvaCombs`i'=`=StvaCombs`i''
    replace StvaCombs`i'="" if strpos(StvaCombs`i',"`Fparse'")==1 | "`Fparse'"==substr(StvaCombs`i',-length("`Fparse'"),.)
    if `number'>2 {
      replace StvaCombs`i'="" if strpos(StvaCombs`i',"`Fparse'`Fparse'")>0
    }
  }
  reshape long StvaCombs, i(`STVaComID') j(`STVarCom')
  drop if StvaCombs==""
  if `"`Fparse'"' == "-._.-" {
    replace StvaCombs=subinstr(StvaCombs,"-._.-"," ",.)
  }
  if "`order'"~="" {
    sort `STVaComID' StvaCombs
  }
  drop `generate'*
  if "`replace'"~="" {
    replace `varlist'=StvaCombs
    drop StvaCombs
  }
  else {
    rename StvaCombs `generate'
    if `number'<=`SPLNM' {
      label var `generate' "Combinations (`number' items) of `varlist'"
    }
    else {
      label var `generate' "Combinations (`SPLNM' items) of `varlist'"    
    }
  }
}

if "`compress'"~="" {
  if "`replace'"=="" {
    compress `varlist' `generate'
  }
  else {
    compress `varlist'
  }
}
}    /* Close brace of quietly */
end
