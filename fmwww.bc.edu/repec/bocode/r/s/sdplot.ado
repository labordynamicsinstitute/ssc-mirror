// Jun 28 2022 21:49:49
// Single program to do sdchronoplot and sdindexplot
program define sdplot
syntax varlist(min=2) [if] [in], PLOTtype(string) [ORDer(string) BY(string) LEGend(string) * PROPortional YDF(real 1.0)]

capture which heatplot
if _rc != 0 {
  di in red "Command requires heatplot package. Do 'ssc install heatplot'"
  error 999
}

marksample touse

if "`plottype'" == "chron" {
  if "`order'" != "" {
    di in red "ORDER not possible with chronogram"
    error 999
    }
}
if "`plottype'" == "index" {
  if "`proportional'" != "" {
    di in red "PROPORTIONAL not possible with indexplot"
    error 999
    }
}

if `"`by'"' != `""' {
  gettoken byvars byopts: by, parse(",")
  local bycom `"by(`byvars' `byopts')"'
}


// Assume statevars are m1-mXX and that m1 has the full label list
local state : word 1 of `varlist'
local statelab: value label `state'
local state = regexr("`state'","[0-9]+$","")

preserve
keep if `touse'
keep `varlist' `byvars' `order'
tempvar idvar idvar2 tvar

gen `idvar' = _n
gen `idvar2' = _n

// Indexplot setup (before reshape)
if "`plottype'" == "index" {
  if "`order'" != "" {
    sort `order'
    qui replace `idvar2' = _n
  }
  if "`by'" != "" {
    sort `byvars' `order'
    qui by `byvars' : replace `idvar2' = _n
  }
}

qui reshape long `state', i(`idvar') j(`tvar')

// Chronogram setup (after reshape)
if "`plottype'" == "chron" {
  bysort `byvars' `tvar' (`state'): replace `idvar2' = _n
  sort `tvar' `state'
  
  if "`by'" != "" & "`proportional'" != "" {
    tempvar propn maxn
    egen `maxn' = max(`idvar2'), by(`byvars')
    replace `idvar2' = 100 * `idvar2' / `maxn'
  }
}

qui su `state'
local statemax = r(max)

forval i = 1/`statemax' {
    local rowlab  `"`rowlab' `i' "`: label (`state') `i''" "' 
}

qui su `idvar2'
local nrows = r(max)
qui su `tvar'
local ncols = r(max)
if "`xlabel'"=="" {
  local xlabel  xlabel(0(`=ceil((`ncols'-1)/4)')`ncols')
}
if "`ylabel'"=="" {
  local ylabel  ylabel(0(`=ceil((`nrows'-1)/4)')`nrows')
}

local ytitle "Cases"
if "`proportional'" != "" {
  local ytitle "Percentage"
}

heatplot `state' `idvar2' `tvar', `xlabel' `ylabel' levels(`statemax') ///
  xdiscrete(1) ydiscrete(`ydf') legend(order(`rowlab') `legend') ///
  `bycom' `options' xtitle("Time") ytitle(`ytitle')

restore

end
