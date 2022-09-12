/*==================================================================================
Program to implement placebo zone model selection algorithm for RDD/RKD designs.
See Kettlewell & Siminski 'Optimal Model Selection for RDD and Related Designs'

Authors: Nathan Kettlewell & Peter Siminski
Updated: 4 September 2022
Version: 1.1
==================================================================================*/

capture program drop pzms
program define pzms, eclass
version 12.1
#delimit ;
syntax varlist(min=2 max=2) [if] [in], MAXBW(real) [MINBW(real 0) C(real 0) PZRANGE(numlist min=2 max=2) 
P(int 1) DERIV(integer 0) PZSTEPNUM(integer 0) PZSTEPSIZE(real 0) BWSTEPNUM(integer 0) BWSTEPSIZE(real 0) VCE(string) 
COVS(varlist) WEIGHT(varname) PZPLOT NOLOG COLLAPSE(string)
Kernel(string) BWLFIX(real 0) BWRFIX(real 0) DONUT(numlist min=2 max=2) MCUSTOM1(string) MCUSTOM2(string)
MCUSTOM3(string) MCUSTOM4(string) MCUSTOM5(string) MCUSTOM6(string) MCUSTOM7(string) MCUSTOM8(string)
MCUSTOM9(string) MCUSTOM10(string) nodisplay(integer 0)] ;
#delimit cr

tokenize "`varlist'"
tempvar rv treat kweight n //These will be used as we step through the placebo estimates later
//n will be used for collapse option as frequency variable
qui g double `rv' = .
qui g double `treat' = .
qui g double `kweight' = .

*Preserve dataset so it can be altered by if, in and collapse
preserve
capture keep `if'
capture keep `in'

*Error messages
foreach f in maxbw minbw pzstepnum pzstepsize bwstepsize bwlfix bwrfix {
	if ``f'' < 0 {
		di as error "`f' must be a positive number"
		exit 198
	}
}

if `p' != 1 & `p' != 2 {
	di as error "Only polynomial order 1 and 2 allowed in p(#). For higher order polynomials, use the mcustom option"
	exit 198
}

if `deriv' != 0 & `deriv' != 1 {
	di as error "Only derivative orders 1 and 2 allowed in deriv(#)."
	exit 198
}


if (`pzstepnum' > 0 & `pzstepsize' > 0) {
	di as err "You must specify either pzstepnum OR pzstepsize, not both"
	exit 198
}

if `minbw' > `maxbw' {
	di as err "maxbw must not be less than minbw"
	exit 198
}

if "`collapse'" != "weight" & "`collapse'" != "noweight" & "`collapse'" != "" {
	di as err "Option collapse incorrectly specified."
	exit 198
}

local pz1 `: word 1 of `pzrange''   //left end of placebo zone
local pz2 `: word 2 of `pzrange''   //right end of placebo zone

if "`pz1'" == "" { //nothing specified, use full range of running variable
	qui sum `2', detail
	local pz1 = r(min)
	local pz2 = r(max)
}

qui sum `2', detail
if `pz1' < r(min) {
	local pz1 = r(min)
	di as text _newline "Note: lower value specified in pzrange exceds the support of the running variable. Default value used."
}
if `pz2' > r(max) {
	local pz2 = r(max)
	di as text _newline "Note: upper value specified in pzrange exceds the support of the running variable. Default value used."
}

capture reg `1' `2' if `2' > r(max), vce(`vce')   //this is just to check whether vce is correctly specified, there will be no observations
if _rc == 198 {
	di as err "Option vce incorrectly specified."
	exit 198
}

if (`c' < `pz1') | (`c' > `pz2') {
	di as err "Threshold must be within the range specified by pzrange"
	exit 198
}

if (`pz2' - `maxbw')-(`c' + `maxbw') <= 0 & (`c' - `maxbw') <= (`pz1' + `maxbw') {
	di as error "maxbw is too large - there will be no placebo thresholds."
	exit 198
}

if (`bwlfix' > `c'-`pz1') {
	local bwlfix = `c'-`pz1'
	di as text _newline "bwlfix exceeds pzrange on left hand side. bwlfix changed to `bwlfix'."
	local lcap "LHS bandwidths are restricted to `bwlfix'."  //used later in table results display
}

if (`bwrfix' > `pz2'-`c') {
	local bwrfix = > `pz2'-`c'
	di as text _newline "bwrfix exceeds pzrange on right hand side. bwrfix changed to `bwrfix'."
	local rcap "RHS bandwidths are restricted to `bwrfix'."  //used later in table results display
}

local Lbw = `maxbw'  //these macros are used in case user specifies bw outside pzrange. Will utilise asymmetric bws once the canditade bw
local Rbw = `maxbw'  //becomes larger than the largest possible on the L/R of the real threshold

if (`c'-`maxbw' < `pz1') | (`bwlfix' > `c'-`pz1') {
	local Lbw = `c'-`pz1'
	di as text _newline "maxbw exceeds pzrange on left hand side. maxbw will be `Lbw' on LHS and `maxbw' on RHS."
	di as text _newline "This trial includes models with bandwidths exceeding `Lbw' (which is the maximum feasible symmetric bandwidth, given the support of the running variable). For those models, the bandwidth is asymmetrical. To allow only symmetric bandwidths, set the maxbw to `Lbw' (or smaller)."	
	local lcap "LHS bandwidths are capped at `Lbw'."  //used later in table results display
}

if (`pz2'-`c' < `maxbw') | (`bwrfix' > `pz2'-`c') {
	local Rbw = `pz2'-`c'
	di as text _newline "maxbw exceeds pzrange on right hand side. maxbw will be `Rbw' on RHS and `maxbw' on LHS."
	di as text _newline "This trial includes models with bandwidths exceeding `Rbw' (which is the maximum feasible symmetric bandwidth, given the support of the running variable). For those models, the bandwidth is asymmetrical. To allow only symmetric bandwidths, set the maxbw to `Rbw' (or smaller)."		
	local rcap "RHS bandwidths are capped at `Rbw'."  //used later in table results display
}

if ("`: word 1 of `vce''"  == "bootstrap" | "`: word 1 of `vce''"  == "jackknife") & ("`weight'" != "" | "`kernel'" == "triangular" | "`collapse'" == "`weight'") {
	di as err "Chosen vce option cannot be used with weights."
	exit 198
}	

if "`kernel'" == "" {
	local kernel = "uniform"  //default kernel is uniform
}

if "`mckernel'" == "" {
	local mckernel = "uniform"  //default kernel is uniform
}

if ("`kernel'" != "uniform" & "`kernel'" != "triangular") | ("`mckernel'" != "uniform" & "`mckernel'" != "triangular") {
	di as err "Invalid kernel weights. Only uniform and triangular allowed"
	exit 198
}

if "`weight''" != "" & "`collapse'" != "" & "`mcustom1'" != "" {
			di as text "Note: weight(`weight') will be applied to mcustom models. If this is not intended, omit the collapse option."
		}

*Define macros
if `minbw' == 0 {
	local minbw = 0.1*`maxbw'  //default minbw
}

local dn1 `: word 1 of `donut''   //left donut
local dn2 `: word 2 of `donut''   //right donut

if "`dn1'" == "" { //nothing specified, use set left donut to zero
	local dn1 = 0
}

if "`dn2'" == "" { //nothing specified, use set right donut to zero
	local dn2 = 0
}

if (`dn1' >= `minbw') | (`dn2' >= `minbw')  {
	di as err "Donut must be less than minbw"  //error for if donut is too large
	exit 198
}


if "`weight'" != "" & "`kernel'" == "triangular"  {
	local aweight = "[aweight=`weight'*`kweight']"
}
else if "`weight'" == "" & "`kernel'" == "triangular"  {
	local aweight = "[aweight=`kweight']"
}
else if "`weight'" != "" & "`kernel'" == "uniform" {
	local aweight = "[aweight=`weight']"
}

*Collapse data if option invoked
if "`collapse'" != "" {
	*preserve
	forvalues q = 1/10 {
	if "`mcustom`q''" != "" {
		pzms_custom `mcustom`q''  //run this subprogram to extraxct mcustom options
		local mccovs`q' = e(custom_covs)
			if `mccovs`q'' == . { 
				local mccovs`q' = "" 
			}
			local custom_weight`q' = e(custom_weight)
			if `custom_weight`q'' == . {
				local custom_weight`q' = ""
			}
		}
	}
	qui g `n' = 1
	order `1' `treat' `kweight' `covs' `weight' `mccovs1' `mccovs2' `mccovs3' `mccovs4' `mccovs5' `mccovs6' ///
	`mccovs7' `mccovs8' `mccovs9' `mccovs10' `custom_weight1' `custom_weight2' `custom_weight3' `custom_weight4' ///
	`custom_weight5' `custom_weight6' `custom_weight7' `custom_weight8' `custom_weight9' `custom_weight10' `rv' `n'
	if "`weight'" != "" {
		qui collapse `1'-`rv' (sum) `n' [iw=`weight'], by(`2')  
		qui replace `weight' = `n'	
	}
	else {
		qui collapse `1'-`rv' (sum) `n', by(`2') 
		if "`kernel'" == "triangular" & "`collapse'" != "noweight"  {
			local aweight = "[aweight=`n'*`kweight']"
		}
		else if "`kernel'" == "uniform" & "`collapse'" != "noweight" {
			local aweight = "[aweight=`n']"
		}
	}
}

if `bwlfix' > 0 & `bwrfix' > 0 {
	local maxbw = max(`bwlfix',`bwrfix')  //if fixed on both sides, ensure max is the highest. Makes things faster and avoid errors
	local minbw = min(`bwlfix',`bwrfix')
}

if `bwlfix' == 0 {  
	local bwlfix ""  //set to nothing if not specified 
}

if `bwrfix' == 0 {
	local bwrfix ""  //set to nothing if not specified 
}

if `pzstepnum' == 0 & `pzstepsize' == 0 {
	local pzstepnum = 50
	di as text _newline "Warning: PZMS will use the default 50 placebo zone thresholds." 
	di as text "You may want to increase this using pzstepnum or pzstepsize."
}	

if `bwstepnum' == 0 & `bwstepsize' == 0 {
	local bwstepnum = 20
}	

if `bwstepnum' > 0 {	
	local bwstepsize = ((`maxbw'-`minbw')/(`bwstepnum'-1))-0.0000000000000001  //the tiny amount deducted from the step size is to ensure that when looping through bandwidths by step size, the maxbw gets used. Otherwise, steps will be just over maxbw due to rounding in some cases 
}	

if `pzstepnum' > 0 {
	local pzstepsize = (max(`c'-`Rbw'-`Lbw'-`pz1',0)+max(`pz2'-`c'-`Rbw'-`Lbw',0))/(`pzstepnum'-1)-0.0000000000000001  //note this does not guarantee no. of steps, as some steps could be too small to move to new PZ threshold.
}	//the tiny amount deducted from the step size is to ensure that when looping through placebo range by step size, the last threshold gets used. Otherwise, steps will be just over last threshold (e.g., rendob) due to rounding 

if `pzstepnum' == 0 & `pzstepsize' == 0 {
	local pzstepsize = (max(`c'-`Rbw'-`Lbw'-`pz1',0)+max(`pz2'-`c'-`Rbw'-`Lbw',0))/(`pzstepnum'-1)-0.0000000000000001   //note this does not guarantee no. of steps, as some steps could be too small to move to new PZ threshold
}	

local maxiter = round(1+(max(`c'-`Rbw'-`Lbw'-`pz1',0)+max(`pz2'-`c'-`Rbw'-`Lbw',0))/(`pzstepsize'))  //maximium number of iterations, for display later

if `deriv' == 0 & `p' ==1 & "`covs'" == "" {  // RDD, linear, no covariates
	local nmodels = 1
	local m1 = "regress `1' `treat' `rv' c.`rv'#c.`treat' `aweight'"
	
	local m1_model = "RDD"
	local m1_poly = "1"
	local m1_covs = "none"
}

if `deriv' == 0 & `p' ==2 & "`covs'" == "" {  // RDD, linear and quadratic, no covariates
	local nmodels = 2
	local m1 = "regress `1' `treat' `rv' c.`rv'#c.`treat' `aweight'"
	local m2 = "regress `1' `treat' `rv' c.`rv'#c.`treat' c.`rv'#c.`rv' c.`rv'#c.`rv'#c.`treat' `aweight'"
	
	local m1_model = "RDD"
	local m1_poly = "1"
	local m1_covs = "none"
	local m2_model = "RDD"
	local m2_poly = "2"
	local m2_covs = "none"
}

if `deriv' == 0 & `p' ==1 & "`covs'" != "" {  // RDD, linear, with covariates
	local nmodels = 2
	local m1 = "regress `1' `treat' `rv' c.`rv'#c.`treat' `aweight'"
	local m2 = "regress `1' `treat' `rv' c.`rv'#c.`treat' `covs' `aweight'"
	
	local m1_model = "RDD"
	local m1_poly = "1"
	local m1_covs = "none"
	local m2_model = "RDD"
	local m2_poly = "1"
	local m2_covs = "`covs'"	
}

if `deriv' == 0 & `p' ==2 & "`covs'" != "" {  // RDD, linear and quadratic, with covariates
	local nmodels = 4
	local m1 = "regress `1' `treat' `rv' c.`rv'#c.`treat' `aweight'"
	local m2 = "regress `1' `treat' `rv' c.`rv'#c.`treat' c.`rv'#c.`rv' c.`rv'#c.`rv'#c.`treat' `aweight'"
	local m3 = "regress `1' `treat' `rv' c.`rv'#c.`treat' `covs' `aweight'"
	local m4 = "regress `1' `treat' `rv' c.`rv'#c.`treat' c.`rv'#c.`rv' c.`rv'#c.`rv'#c.`treat' `covs' `aweight'"
	
	local m1_model = "RDD"
	local m1_poly = "1"
	local m1_covs = "none"
	local m2_model = "RDD"
	local m2_poly = "2"
	local m2_covs = "none"
	local m3_model = "RDD"
	local m3_poly = "1"
	local m3_covs = "`covs'"
	local m4_model = "RDD"
	local m4_poly = "2"
	local m4_covs = "`covs'"	
}

if `deriv' == 1 & `p' ==1 & "`covs'" == "" {  // RKD, linear, no covariates
	local nmodels = 1
	local m1 = "regress `1'  `rv' c.`rv'#c.`treat' `aweight'"
	
	local m1_model = "RKD"
	local m1_poly = "1"
	local m1_covs = "none"
}

if `deriv' == 1 & `p' ==2 & "`covs'" == "" {  // RKD, linear and quadratic, no covariates
	local nmodels = 2
	local m1 = "regress `1' `rv' c.`rv'#c.`treat' `aweight'"
	local m2 = "regress `1' `rv' c.`rv'#c.`treat' c.`rv'#c.`rv' c.`rv'#c.`rv'#c.`treat' `aweight'"
	
	local m1_model = "RKD"
	local m1_poly = "1"
	local m1_covs = "none"
	local m2_model = "RKD"
	local m2_poly = "2"
	local m2_covs = "none"
}

if `deriv' == 1 & `p' ==1 & "`covs'" != "" {  // RKD, linear, with covariates
	local nmodels = 2
	local m1 = "regress `1' `rv' c.`rv'#c.`treat' `aweight'"
	local m2 = "regress `1' `rv' c.`rv'#c.`treat' `covs' `aweight'"
	
	local m1_model = "RKD"
	local m1_poly = "1"
	local m1_covs = "none"
	local m2_model = "RKD"
	local m2_poly = "1"
	local m2_covs = "`covs'"
}

if `deriv' == 1 & `p' ==2 & "`covs'" != "" {  // RKD, linear and quadratic, with covariates
	local nmodels = 4
	local m1 = "regress `1' `rv' c.`rv'#c.`treat' `aweight'"
	local m2 = "regress `1' `rv' c.`rv'#c.`treat' c.`rv'#c.`rv' c.`rv'#c.`rv'#c.`treat' `aweight'"
	local m3 = "regress `1' `rv' c.`rv'#c.`treat' `covs' `aweight'"
	local m4 = "regress `1' `rv' c.`rv'#c.`treat' c.`rv'#c.`rv' c.`rv'#c.`rv'#c.`treat' `covs' `aweight'"
	
	local m1_model = "RKD"
	local m1_poly = "1"
	local m1_covs = "none"
	local m2_model = "RKD"
	local m2_poly = "2"
	local m2_covs = "none"
	local m3_model = "RKD"
	local m3_poly = "1"
	local m3_covs = "`covs'"
	local m4_model = "RKD"
	local m4_poly = "2"
	local m4_covs = "`covs'"
}

forvalues q = 1/10 {
	if "`mcustom`q''" != "" {
		local non_cust_models = `nmodels'
		local nmodels = `nmodels'+1
		pzms_custom `mcustom`q''  //run this subprogram to extraxct mcustom options
		local mccovs`nmodels' = e(custom_covs)
		if `mccovs`nmodels'' == . { 
			local mccovs`nmodels' = "" 
		}
		local custom_weight`nmodels' = e(custom_weight)
		if `custom_weight`nmodels'' == . { 
			local custom_weight`nmodels' = "" 
		}
		local mckernel`nmodels' = e(custom_kernel)
		if "`mckernel`nmodels''" == "." { 
			local mckernel`nmodels' = "" 
		}
		
		if "`custom_weight`nmodels''" != "" & "`collapse'" != "" {
			di as text "Warning: weight not availble inside mcustom`q' if the collapse option is used. mcustom`q' weights will not be used."
		}

		local m`nmodels' = "regress `1'"
		local m`nmodels'_model = "User supplied"
		local ndiff = `nmodels'-`non_cust_models'
		local m`nmodels'_custom_num = "mcustom`ndiff'"  //just used in results table later
		
		local lp = e(lp)
		local rp = e(rp)
		local m`nmodels'_poly = "."
		local m`nmodels'_covs = "."
		if `lp' > 10 | `rp' > 10 {
			di as err "Polynomial order greater than 10 not allowed in mcustom`q'"
			exit  198
		}
		if `deriv' == 1 {
			local m`nmodels' = "`m`nmodels'' c.`rv'#c.`treat'"
		}
		if `deriv' == 0 {
			local m`nmodels' = "`m`nmodels'' `treat'"
		}
		if `lp' > 0 {
			local m`nmodels' = "`m`nmodels'' c.`rv'"
		}
		if `lp' > 1 {
			local m`nmodels' = "`m`nmodels'' c.`rv'#c.`rv'"
		}
		if `lp' > 2 {
			local m`nmodels' = "`m`nmodels'' c.`rv'#c.`rv'#c.`rv'"
		}
		if `lp' > 3 {
			local m`nmodels' = "`m`nmodels'' c.`rv'#c.`rv'#c.`rv'#c.`rv'"
		}
		if `lp' > 4 {
			local m`nmodels' = "`m`nmodels'' c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'"
		}
		if `lp' > 5 {
			local m`nmodels' = "`m`nmodels'' c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'"
		}
		if `lp' > 6 {
			local m`nmodels' = "`m`nmodels'' c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'"
		}
		if `lp' > 7 {
			local m`nmodels' = "`m`nmodels'' c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'"
		}
		if `lp' > 8 {
			local m`nmodels' = "`m`nmodels'' c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'"
		}
		if `lp' > 9 {
			local m`nmodels' = "`m`nmodels'' c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'"
		}
		if `rp' > 0 & `deriv' == 0 {
			local m`nmodels' = "`m`nmodels'' c.`rv'#c.`treat'"
		}
		if `rp' > 1 {
			local m`nmodels' = "`m`nmodels'' c.`rv'#c.`rv'#c.`treat'"
		}
		if `rp' > 2 {
			local m`nmodels' = "`m`nmodels'' c.`rv'#c.`rv'#c.`rv'#c.`treat'"
		}
		if `rp' > 3 {
			local m`nmodels' = "`m`nmodels'' c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`treat'"
		}
		if `rp' > 4 {
			local m`nmodels' = "`m`nmodels'' c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`treat'"
		}
		if `rp' > 5 {
			local m`nmodels' = "`m`nmodels'' c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`treat'"
		}
		if `rp' > 6 {
			local m`nmodels' = "`m`nmodels'' c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`treat'"
		}
		if `rp' > 7 {
			local m`nmodels' = "`m`nmodels'' c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`treat'"
		}
		if `rp' > 8 {
			local m`nmodels' = "`m`nmodels'' c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`treat'"
		}
		if `rp' > 9 {
			local m`nmodels' = "`m`nmodels'' c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`rv'#c.`treat'"
		} 
		local mc_aweight = ""
		if "`collapse'" == "" {
			tempvar cweight`nmodels'
			capture qui g `cweight`nmodels'' = `e(custom_weight)'
			if "`custom_weight`nmodels''" != "" & "`mckernel`nmodels''" == "triangular"  {
				local mc_aweight = "[aweight=`cweight`nmodels''*`kweight']"
			}
			else if "`custom_weight`nmodels''" == "" & "`mckernel`nmodels''" == "triangular"  {
				local mc_aweight = "[aweight=`kweight']"
			}
			else if "`custom_weight`nmodels''" != "" & "`mckernel`nmodels''" != "triangular" {
				local mc_aweight = "[aweight=`cweight`nmodels'']"
			}
		}
		if "`collapse'" == "weight" & "`mckernel`nmodels''" == "triangular" {
			local mc_aweight = "[aweight=`n'*`kweight']"
		}
		if "`collapse'" == "weight" & "`mckernel`nmodels''" != "triangular" {
			local mc_aweight = "[aweight=`n']"
		}
		if "`collapse'" == "noweight" & "`mckernel`nmodels''" == "triangular" {
			local mc_aweight = "[aweight=`kweight']"
		}
		local m`nmodels' = "`m`nmodels'' `mccovs`nmodels'' `mc_aweight'"  //in case weights are specified
	}
}

if "`bwlfix'" != "" {
	local Lbw = `bwlfix'  //this ensures that with asymmetric bandwidths, maximum placebo thresholds used when defining following macros for interations
}
if "`bwrfix'" != "" {
	local Rbw = `bwrfix'  //this ensures that with asymmetric bandwidths, maximum placebo thresholds used when defining following macros for interations
}

local rstart = `c' + `Lbw'  //This will be where we start for pz to right of cutoff
local rendob = `pz2' - `Rbw'  //This will be the last pz threshold to the right of cut-off
local lstart = `pz1' + `Rbw'  //This will be where we start for pz to left of cutoff
local lendob = `c' - `Lbw'  //This will be the last pz threshold  to the left of cut-off
local iter = 0  //iteration counter (how many estimators with different BWs we have for each model)
local move = 0  //used later to identify when the pzstep is actually large enough to move to a new pz threshold

if `c' - `Rbw' > `pz1' + `Lbw' {
	local LHS = 1  //flag for if will be using LHS of threshold in placebo zone
}
else {
	local LHS = 0
}

if `pz2' - `Rbw' > `c' + `Lbw' {
	local RHS = 1  //flag for if will be using RHS of threshold in placebo zone
}
else {
	local RHS = 0
}

if `bwstepsize' == 0 {
	local bwstepsize = `pzstepsize'  //if no step size through bandwidths specified, then use same as for placebo thrsholds
}

local j = 0
forvalues x = `minbw'(`bwstepsize')`maxbw' {
	local j = `j'+1  
	forvalues q = 1/`nmodels' {  
		local m`q'_ssqe_`j' = 0  //will be used as running sum for each pz iteration for each possible BW
	}
}

*Placebo zone estimations
if `LHS' == 1 {
	forvalues i = `lendob'(-`pzstepsize')`lstart' {
		qui {
			replace `rv' = `2'-`i' //running variable
			replace `treat' = `rv' > 0  //treatment variable
			count if `treat' == 1
			local move = r(N) - `move'
			if `move' != 0 {  //only progress if the step actually takes us to a new placebo threshold
				local move = r(N)
				local iter = `iter' + 1
				local j = 0
				forvalues x = `minbw'(`bwstepsize')`maxbw' {	
					local j = `j'+1
					if `deriv' == 0 { //RDD class
						forvalues q = 1/`nmodels' {
							if "`m`q'_model'" != "User supplied" & "`kernel'" == "triangular" {  //generate triangular kernel weights if option is specified
								replace `kweight' = max(1-(1/`x')*`rv',0) if `rv'>=0
								replace `kweight' = max(1-(1/`x')*-`rv',0) if `rv'<=0
							}
							if "`m`q'_model'" == "User supplied" & "`mckernel`q''" == "triangular" {  //generate triangular kernel weights if option is specified
								replace `kweight' = max(1-(1/`x')*`rv',0) if `rv'>=0
								replace `kweight' = max(1-(1/`x')*-`rv',0) if `rv'<=0
							}
							if "`bwlfix'" != "" {
								local xL = `bwlfix'  //setting the left and right bandwidths - will use x unless a fixed option is specified
							} 
							else {
								local xL = `x'
							}
							if "`bwrfix'" != "" {
								local xR = `bwrfix'
							} 
							else {
								local xR = `x'
							}
							`m`q'' if `rv' >= -`xL' & `rv' <= `xR' & `rv' >= -`Lbw' & `rv' <= `Rbw' & (`rv' <= -`dn1' | `rv' >= `dn2'),  //regression model q 
							local m`q'_est1_bw_`j' = _b[`treat']
							local m`q'_ssqe_`j' = `m`q'_ssqe_`j'' + (_b[`treat'])^2 
						}
					}
					if `deriv' == 1 { //RKD class
						forvalues q = 1/`nmodels' {
							if "`m`q'_model'" != "User supplied" & "`kernel'" == "triangular" {  //generate triangular kernel weights if option is specified
								replace `kweight' = max(1-(1/`x')*`rv',0) if `rv'>=0
								replace `kweight' = max(1-(1/`x')*-`rv',0) if `rv'<=0
							}
							if "`m`q'_model'" == "User supplied" & "`mckernel`q''" == "triangular" {  //generate triangular kernel weights if option is specified
								replace `kweight' = max(1-(1/`x')*`rv',0) if `rv'>=0
								replace `kweight' = max(1-(1/`x')*-`rv',0) if `rv'<=0
							}
							if "`bwlfix'" != "" {
								local xL = `bwlfix'  //setting the left and right bandwidths - will use x unless a fixed option is specified
							} 
							else {
								local xL = `x'
							}
							if "`bwrfix'" != "" {
								local xR = `bwrfix'
							} 
							else {
								local xR = `x'
							}
							`m`q'' if `rv' >= -`xL' & `rv' <= `xR' & `rv' >= -`Lbw' & `rv' <= `Rbw' & (`rv' <= -`dn1' | `rv' >= `dn2'),   //regression model q 
							local m`q'_est1_bw_`j' = _b[c.`rv'#c.`treat']
							local m`q'_ssqe_`j' = `m`q'_ssqe_`j'' + (_b[c.`rv'#c.`treat'])^2 
						}
					}
				}
			}
		}
		local iter = round(`iter',0.1) 
		if "`nolog'" == "" {
			noisily di "" "`iter' of maximum `maxiter' iterations"
		}
	}
}

local titer = `iter'

if `RHS' == 1 {
	forvalues i = `rstart'(`pzstepsize')`rendob' {
		qui {
			replace `rv' = `2'-`i' //running variable
			replace `treat' = `rv' > 0  //treatment variable
			count if `treat' == 1
			local move = r(N) - `move'
			if `move' != 0 {  //only progress if the step actually takes us to a new placebo threshold
				local move = r(N)
				local iter = `iter' + 1
				local j = 0
				forvalues x = `minbw'(`bwstepsize')`maxbw' {	
					local j = `j'+1
					if `deriv' == 0 { //RDD class
						forvalues q = 1/`nmodels' {
							if "`m`q'_model'" != "User supplied" & "`kernel'" == "triangular" {  //generate triangular kernel weights if option is specified
								replace `kweight' = max(1-(1/`x')*`rv',0) if `rv'>=0
								replace `kweight' = max(1-(1/`x')*-`rv',0) if `rv'<=0
							}
							if "`m`q'_model'" == "User supplied" & "`mckernel`q''" == "triangular" {  //generate triangular kernel weights if option is specified
								replace `kweight' = max(1-(1/`x')*`rv',0) if `rv'>=0
								replace `kweight' = max(1-(1/`x')*-`rv',0) if `rv'<=0
							}
							if "`bwlfix'" != "" {
								local xL = `bwlfix'  //setting the left and right bandwidths - will use x unless a fixed option is specified
							} 
							else {
								local xL = `x'
							}
							if "`bwrfix'" != "" {
								local xR = `bwrfix'
							} 
							else {
								local xR = `x'
							}
							`m`q'' if `rv' >= -`xL' & `rv' <= `xR' & `rv' >= -`Lbw' & `rv' <= `Rbw' & (`rv' <= -`dn1' | `rv' >= `dn2'),   //regression model q 
							local m`q'_est1_bw_`j' = _b[`treat']
							local m`q'_ssqe_`j' = `m`q'_ssqe_`j'' + (_b[`treat'])^2 
						}
					}
					if `deriv' == 1 { //RKD class
						forvalues q = 1/`nmodels' {
							if "`m`q'_model'" != "User supplied" & "`kernel'" == "triangular" {  //generate triangular kernel weights if option is specified
								replace `kweight' = max(1-(1/`x')*`rv',0) if `rv'>=0
								replace `kweight' = max(1-(1/`x')*-`rv',0) if `rv'<=0
							}
							if "`m`q'_model'" == "User supplied" & "`mckernel`q''" == "triangular" {  //generate triangular kernel weights if option is specified
								replace `kweight' = max(1-(1/`x')*`rv',0) if `rv'>=0
								replace `kweight' = max(1-(1/`x')*-`rv',0) if `rv'<=0
							}
							if "`bwlfix'" != "" {
								local xL = `bwlfix'  //setting the left and right bandwidths - will use x unless a fixed option is specified
							} 
							else {
								local xL = `x'
							}
							if "`bwrfix'" != "" {
								local xR = `bwrfix'
							} 
							else {
								local xR = `x'
							}
							`m`q'' if `rv' >= -`xL' & `rv' <= `xR' & `rv' >= -`Lbw' & `rv' <= `Rbw' & (`rv' <= -`dn1' | `rv' >= `dn2'),   //regression model q 
							local m`q'_est1_bw_`j' = _b[c.`rv'#c.`treat']
							local m`q'_ssqe_`j' = `m`q'_ssqe_`j'' + (_b[c.`rv'#c.`treat'])^2 
						}
					}
				}
			}
		}
		local iter = round(`iter',0.1)
		if "`nolog'" == "" {
			noisily di "" "`iter' of maximum `maxiter' iterations"
		}
	}
}

local titer = `iter'

forvalues q = 1/`nmodels' {
	local m`q'_low_ssqe = .
}

local j = 0
forvalues x = `minbw'(`bwstepsize')`maxbw' {
	local j = `j'+1
	forvalues q = 1/`nmodels' {
		if `m`q'_ssqe_`j'' < `m`q'_low_ssqe' {
			local m`q'_low_ssqe = `m`q'_ssqe_`j''
			local m`q'_low_bw = `x'
		}
	}
}

tempname WINNERS
matrix `WINNERS' = J(`nmodels',5,0)
matrix colnames `WINNERS' = "Deriv" "Poly" "Covs." "RMSE" "BW"
forvalues q = 1/`nmodels' {
	matrix `WINNERS'[`q',1] = `deriv'
	matrix `WINNERS'[`q',2] = `m`q'_poly'
	if "`m`q'_covs'" == "none" {
		matrix `WINNERS'[`q',3] = 0
	}
	else if "`m`q'_covs'" == "." {
		matrix `WINNERS'[`q',3] = .
	}
	else {
		matrix `WINNERS'[`q',3] = 1
	}
	matrix `WINNERS'[`q',4] = sqrt(`m`q'_low_ssqe'/`iter')
	matrix `WINNERS'[`q',5] = `m`q'_low_bw'
}

local win_model_ssq = .
forvalues q = 1/`nmodels' {
	if `m`q'_low_ssqe' < `win_model_ssq' {
		local win_model_ssq = `m`q'_low_ssqe'
		local best "m`q'"
		local w = `q'
	}
}

*Execute the optimal model across the placebo zone to store results
if c(matsize) < `iter' {
	set matsize `iter'  //increase matsize if not already large enough to save iterations
}

tempname R
matrix `R' = J(`iter',5,0) 
local i2 = 0
local move = 0  

if `LHS' == 1 {
	forvalues i = `lendob'(-`pzstepsize')`lstart' {
		qui {
			replace `rv' = `2'-`i' //running variable
			replace `treat' = `rv' > 0  //treatment variable
			count if `treat' == 1
			local move = r(N) - `move'
			if `move' != 0 {  //only progress if the step actually takes us to a new placebo threshold
				local move = r(N)
				if "`m`w'_model'" != "User supplied" & "`kernel'" == "triangular" {  //generate triangular kernel weights if option is specified
					replace `kweight' = max(1-(1/``best'_low_bw')*`rv',0) if `rv'>=0
					replace `kweight' = max(1-(1/``best'_low_bw')*-`rv',0) if `rv'<=0
				}
				if "`m`w'_model'" == "User supplied" & "`mckernel`w''" == "triangular" {  //generate triangular kernel weights if option is specified
					replace `kweight' = max(1-(1/``best'_low_bw')*`rv',0) if `rv'>=0
					replace `kweight' = max(1-(1/``best'_low_bw')*-`rv',0) if `rv'<=0
				}
				if "`bwlfix'" != "" {
					local xL = `bwlfix'  //setting the left and right bandwidths - will use x unless a fixed option is specified
				} 
				else {
					local xL = ``best'_low_bw'
				}
				if "`bwrfix'" != "" {
					local xR = `bwrfix'
				} 
				else {
					local xR = ``best'_low_bw'
				}
				``best'' if `rv' >= -`xL' & `rv' <= `xR' & `rv' >= -`Lbw' & `rv' <= `Rbw' & (`rv' <= -`dn1' | `rv' >= `dn2'), vce(`vce')
				local i2 = `i2' + 1
				if `deriv' == 0 {
					matrix `R'[`i2',1] = _b[`treat']
					matrix `R'[`i2',2] = _se[`treat']
					test `treat'
				}
				if `deriv' == 1 {
					matrix `R'[`i2',1] = _b[c.`rv'#c.`treat']
					matrix `R'[`i2',2] = _se[c.`rv'#c.`treat']
					test c.`rv'#c.`treat'
				}
				matrix `R'[`i2',4] = r(p)  //p-value of TE est
				sum `2' if `rv' >=0
				matrix `R'[`i2',3] = r(min)
				matrix `R'[`i2',5] = 1  //for tracking whether est is LHS of placebo zone
			}
		}
	}
}

local move = 0

if `RHS' == 1 {
	forvalues i = `rstart'(`pzstepsize')`rendob' {
		qui {
			replace `rv' = `2'-`i' //running variable
			replace `treat' = `rv' > 0  //treatment variable
			count if `treat' == 1
			local move = r(N) - `move'
			if `move' != 0 {  //only progress if the step actually takes us to a new placebo threshold
				local move = r(N)
				if "`m`w'_model'" != "User supplied" & "`kernel'" == "triangular" {  //generate triangular kernel weights if option is specified
					replace `kweight' = max(1-(1/``best'_low_bw')*`rv',0) if `rv'>=0
					replace `kweight' = max(1-(1/``best'_low_bw')*-`rv',0) if `rv'<=0
				}
				if "`m`w'_model'" == "User supplied" & "`mckernel`w''" == "triangular" {  //generate triangular kernel weights if option is specified
					replace `kweight' = max(1-(1/``best'_low_bw')*`rv',0) if `rv'>=0
					replace `kweight' = max(1-(1/``best'_low_bw')*-`rv',0) if `rv'<=0
				}
				if "`bwlfix'" != "" {
					local xL = `bwlfix'  //setting the left and right bandwidths - will use x unless a fixed option is specified
				} 
				else {
					local xL = ``best'_low_bw'
				}
				if "`bwrfix'" != "" {
					local xR = `bwrfix'
				} 
				else {
					local xR = ``best'_low_bw'
				}
				``best'' if `rv' >= -`xL' & `rv' <= `xR' & `rv' >= -`Lbw' & `rv' <= `Rbw' & (`rv' <= -`dn1' | `rv' >= `dn2'), vce(`vce')
				local i2 = `i2' + 1
				if `deriv' == 0 {
					matrix `R'[`i2',1] = _b[`treat']
					matrix `R'[`i2',2] = _se[`treat']
					test `treat'
				}
				if `deriv' == 1 {
					matrix `R'[`i2',1] = _b[c.`rv'#c.`treat']
					matrix `R'[`i2',2] = _se[c.`rv'#c.`treat']
					test c.`rv'#c.`treat'
				}
				matrix `R'[`i2',4] = r(p)  //p-value of TE est
				sum `2' if `rv' >=0
				matrix `R'[`i2',3] = r(min)
				matrix `R'[`i2',5] = 0  //for tracking whether est is LHS of placebo zone
			}
		}
	}
}
matrix colnames `R' = "Est." "Std. err." "PZ cutoff" "P-val" "PZ LHS"
	
*Estimate the optimal model at the real threshold
qui replace `rv' = `2' - `c' //running variable
qui replace `treat' = `rv' > 0  //treatment variable
if "`m`w'_model'" != "User supplied" & "`kernel'" == "triangular" {  //generate triangular kernel weights if option is specified
	qui replace `kweight' = max(1-(1/``best'_low_bw')*`rv',0) if `rv'>=0
	qui replace `kweight' = max(1-(1/``best'_low_bw')*-`rv',0) if `rv'<=0
}
if "`m`w'_model'" == "User supplied" & "`mckernel`w''" == "triangular" {  //generate triangular kernel weights if option is specified
	qui replace `kweight' = max(1-(1/``best'_low_bw')*`rv',0) if `rv'>=0
	qui replace `kweight' = max(1-(1/``best'_low_bw')*-`rv',0) if `rv'<=0
}
if "`bwlfix'" != "" {
	local xL = `bwlfix'  //setting the left and right bandwidths - will use x unless a fixed option is specified
} 
else {
	local xL = ``best'_low_bw'
}
if "`bwrfix'" != "" {
	local xR = `bwrfix'
} 
else {
	local xR = ``best'_low_bw'
}

qui ``best'' if `rv' >= -`xL' & `rv' <= `xR' & `rv' >= -`Lbw' & `rv' <= `Rbw' & (`rv' <= -`dn1' | `rv' >= `dn2'), vce(`vce')

if `deriv' == 0 {
	local pzms_est = _b[`treat']
	local pzms_se = _se[`treat']
	qui test `treat'
	local pzms_p = r(p)
	local tstat = r(F)^0.5
}
if `deriv' == 1 {
	local pzms_est = _b[c.`rv'#c.`treat']
	local pzms_se = _se[c.`rv'#c.`treat']
	qui test c.`rv'#c.`treat'
	local pzms_p = r(p)
	local tstat = r(F)^0.5
}

*Alternate inference and ESS
svmat `R', names(___)
label variable ___1 "Placebo zone estimates" 
label variable ___2 "Placebo zone estimates standard errors" 
label variable ___3 "Placebo zone estimates cut-off points" 
label variable ___4 "Placebo zone estimates p-values" 
label variable ___5 "=1 if placebo estimate from left of true cut-off" 

local pzms_ame = `pzms_est'
qui sum ___1, detail
local alt_sd = r(sd)
qui count if ___1 !=.
local bn = r(N)
tempvar n
qui g `n' = _n
qui tsset `n'
capture qui corrgram ___1 if ___5 ==1, lags(1)  //for LHS of cutoff
local rhoL = max(r(ac1),0)  //autocorrelation coeffient
capture qui corrgram ___1 if ___5 ==0, lags(1)  //for RHS of cutoff
local rhoR = max(r(ac1),0)  //autocorrelation coeffient
qui count if ___5 ==1 
local wL = r(N)
qui count if ___5 ==0 
local wR = r(N)
local rho = `rhoL'*(`wL'-1)/(`wL'+`wR'-2)+`rhoR'*(`wR'-1)/(`wL'+`wR'-2)  //weighted average rho, treating placebo zone as contiguous
local bn_minus1 = `bn'-1

*ESS and alt-p - first as contiguous
local B = 1
forvalues r = 1/`bn_minus1' {
	local A = (1-`r'/`bn')*`rho'^`r'
	local B = `B'+`A'
}	
local ess = `bn'/(1+2*`B')  //effective sample size
local alt_t_df = `ess'-1  //alternative p-value degrees of freedom
local alt_p = 2 * t(`alt_t_df',-abs((`pzms_ame')/`alt_sd'))  //alternative p-value
local alt_t = abs((`pzms_ame')/`alt_sd')
local alt_se = abs(`pzms_est'/`alt_t')
local t_crit_alt = abs(invt(`alt_t_df',0.025))

if `LHS'==1 & `RHS'==1 {
	qui count if ___5 ==1
	local bn = r(N)
	local bn_minus1 = `bn'-1
	local B = 1
	forvalues r = 1/`bn_minus1' {
		local A = (1-`r'/`bn')*`rhoL'^`r'
		local B = `B'+`A'
	}
	local essL = `bn'/(1+2*`B')  //effective sample size
	local alt_t_dfL = `essL'-1  //alternative p-value degrees of freedom
	local alt_pL = 2 * t(`alt_t_dfL',-abs((`pzms_ame')/`alt_sd'))  //alternative p-value

	qui count if ___5 ==0
	local bn = r(N)
	local bn_minus1 = `bn'-1
	local B = 1
	forvalues r = 1/`bn_minus1' {
		local A = (1-`r'/`bn')*`rhoR'^`r'
		local B = `B'+`A'
	}
	local essR = `bn'/(1+2*`B')  //effective sample size
	local ess_SUM = `essL'+`essR'
	local alt_t_dfSUM = `ess_SUM'-1  //alternative p-value degrees of freedom
	local alt_pSUM = 2 * t(`alt_t_dfSUM',-abs((`pzms_ame')/`alt_sd'))  //alternative p-value
}

foreach w in weight covs {
	if "``w''" == "" {
		local `w' = "none"  //this just changes locals so can report these options as none in results table
	}
}

local t_crit = abs(invt(e(df_r),0.025))  //for constructing conventional confidence intervals  
local stat = "t"
local ci_L = `pzms_est'-`t_crit'*`pzms_se'
local ci_U = `pzms_est'+`t_crit'*`pzms_se'

if "`e(vcetype)'" == "Bootstrap" & `deriv' == 0 {
	matrix C = e(se)
	local pzms_se = C[1,1]
	matrix C = e(ci_normal)
	local ci_L = C[1,1]
	local ci_U = C[2,1]
	local stat = "z"
	local tstat = `pzms_est'/`pzms_se'
}

if "`e(vcetype)'" == "Bootstrap" & `deriv' == 1 {
	matrix C = e(se)
	local pzms_se = C[1,2]
	matrix C = e(ci_normal)
	local ci_L = C[1,2]
	local ci_U = C[2,2]
	local stat = "z"
	local tstat = `pzms_est'/`pzms_se'
}	

if "`e(vcetype)'" == "" {
	ereturn local vcetype = "Homoscedastic"
}

if `nodisplay' == 0 {  //nodisplay is an undocumented option that suppresses the main results table. Invoked in our companion program pzms_sim

	di _newline(1)  //here we display the results
	di as result "KS Placebo Zone Model Selection Procedure"
	di as text "Placebo zone trial summary results"
	di as text "Dependent variable:" _col(25) as result "`1'"    
	di as text "Running variable:" _col(25) as result "`2'"
	di as text "Range of running variable used in trial:" _col(25) as result "(`pz1', `pz2')"
	di as text "Model type:" _col(25) as result "`m1_model'" 
	if `p' == 1 {
		di as text "Poly. order(s):" _col(25) as result "1"
	}
	if `p' == 2 {
		di as text "Poly. order(s):" _col(25) as result "1, 2"
	}
	di as text "Kernel:" _col(25) as result "`kernel'"
	di as text "Weight:" _col(25) as result "`weight'"
	di as text "Covariates:" _col(25) as result "`covs'"
	if `Lbw' != `maxbw' {
		di as text "Bandwidths considered in trial: bandwidths between " as result `minbw' as text " and " as result `maxbw' as text " in steps of " as result `bwstepsize' as text ". LHS bandwidths are capped at " as result %5.3f `Lbw'
	}
	else if `Rbw' != `maxbw' {
		di as text "Bandwidths considered in trial: bandwidths between " as result `minbw' as text " and " as result `maxbw' as text " in steps of " as result `bwstepsize' as text ". RHS bandwidths are capped at " as result %5.3f `Rbw'
	}
	else if `Rbw' != `maxbw' & `Lbw' != `maxbw' {
		di as text "Bandwidths considered in trial: bandwidths between " as result `minbw' as text " and " as result `maxbw' as text " in steps of " as result `bwstepsize' as text ". LHS bandwidths are capped at " as result %5.3f `Lbw' as text ". RHS bandwidths are capped at " as result %5.3f `Rbw' 
	}
	else { 
		di as text "Bandwidths considered in trial: bandwidths between " as result `minbw' as text " and " as result `maxbw' as text " in steps of " as result `bwstepsize'
	}
	di as text "Number of placebo thresholds used in trial: " as result `titer' as text ", with step size of " as result `pzstepsize' as text " units between thresholds"
	if `RHS' ==1 & `LHS' ==1 {
		di as text "Placebo thresholds on both sides of the actual threshold were used in the trial"
		di as text "Placebo thresholds range from " as result "`2' = " `lstart' as text " to " as result "`2' = " `lendob' as text " on LHS and from " as result "`2' = " `rstart' as text " to " as result "`2' = " `rendob' as text " on RHS"
	}
	if `RHS' ==1 & `LHS' ==0 {
		di as text "Placebo thresholds on RHS only of the actual threshold were used in the trial"
		di as text "Placebo thresholds range from " as result "`2' = " `rstart' as text " to " as result "`2' = " `rendob'
	}
	if `RHS' ==0 & `LHS' ==1 {
		di as text "Placebo thresholds on LHS only of the actual threshold were used in the trial"
		di as text "Placebo thresholds range from " as result "`2' = " `lstart' as text " to " as result"`2' = " `lendob'
	}
	di _newline(1)
	di as result "Results of Trial"
	if "`bwlfix'" != "" & "`bwrfix'" == "" {
		di as text "Optimal RHS bandwidth: " as result _col(25) %5.3f ``best'_low_bw' 
	}
	else if "`bwrfix'" != "" & "`bwlfix'" == "" {
		di as text "Optimal LHS bandwidth: " as result _col(25) %5.3f ``best'_low_bw' 
	}
	else if "`bwrfix'" != "" & "`bwlfix'" != "" {
		di as text "Optimal bandwidth: " as result _col(25) %5.3f "Fixed" 
	}
	else {
		di as text "Optimal bandwidth: " as result _col(25) %5.3f ``best'_low_bw' 
	}
	if ``best'_poly' != . {
		di as text "Polynomial order: " as result _col(25) ``best'_poly'
	}
	else {
		di as text "Optimal specification:" as result _col(24) " ``best'_custom_num'"
	}
	di as text "RMSE: " as result _col(23) sqrt(`win_model_ssq'/`iter')

	if `RHS' ==1 & `LHS' ==1 { 
		di as text "Effective sample size of placebo estimates from optimal model: "  
		di as text "  Lower bound: " as result _col(25) %5.3f `ess' 
		di as text "  Upper Bound: " as result _col(25) %5.3f `ess_SUM'
	}
	if (`RHS' ==1 & `LHS' ==0) | (`RHS' ==0 & `LHS' ==1)  { 
		di as text "Effective sample size of placebo estimates from optimal model: " as result %5.3f `ess' 
	}

	di _newline(1)
	di as result "Estimated Treatment Effect Using Optimal Model" as text _col(53) "Observations:" as result "{ralign 15:`e(N)'}"
	di as text _col(53) "Threshold:" as result "{ralign 18:`c'}"
	di as text _col(53) "vce:" as result "{ralign 24:`vce'}"
	di as text "{hline 19}{c TT}{hline 60}"
	di as text "{ralign 18:Inference method}"  _col(19) " {c |} " _col(24) "Coef."  _col(33) `"Std. Err."'  _col(46) "`stat'"    _col(52) "P>|`stat'|"   _col(61) `"[95% Conf. Interval]"'
	di as text "{hline 19}{c +}{hline 60}"

	di as text "{ralign 18:`e(vcetype)'}" as result _col(19) " {c |} " _col(22) %7.0g `pzms_est' _col(33) %7.0g `pzms_se' _col(43) %7.0g `tstat' _col(52) %5.4f `pzms_p' _col(60) %5.4f `ci_L' _col(73) %5.4f `ci_U'
	di as text "{ralign 18:KS rand. infer.}" as result _col(19) " {c |} " _col(22) %7.0g `pzms_est' _col(33) %7.0g `alt_se' _col(43) %7.0g `alt_t' _col(52) %5.4f `alt_p' _col(60) %5.4f `pzms_est'-`t_crit_alt'*`alt_se' _col(73) %5.4f `pzms_est'+`t_crit_alt'*`alt_se'

	di as text "{hline 19}{c BT}{hline 60}"
	if "`bwlfix'" != "" {
		di as text "Note: left bandwidth is fixed at value `bwlfix'"
	} 
	if "`bwrfix'" != "" {
		di as text "Note: right bandwidth is fixed at value `bwrfix'"
	} 

	if "`pzplot'" != "" {  //for drawing plot of placebo estimates
		local alt_ci_L = `pzms_est'-`t_crit_alt'*`alt_se'
		local alt_ci_U = `pzms_est'+`t_crit_alt'*`alt_se'
		qui sum ___1
		local min = min(r(min),`ci_L',`alt_ci_L')
		local max = max(r(max),`ci_U',`alt_ci_U') 
		local gap = (`max'-`min')/3
		kdensity ___1, xlabel(`min'(`gap')`max', format(%5.3f)) xline(`pzms_est', lcolor(red) lpattern(dash)) scheme(s1mono) ///
		title(Kernel density estimate of placebo treatment effects) xtitle("") xline(`ci_L', lcolor(gs1)) ///
		xline(`ci_U', lcolor(gs1)) xline(`alt_ci_L', lcolor(gs12)) xline(`alt_ci_U', lcolor(gs12)) ///
		note("Dashed line is the estimated true treatment effect." "Dark lines are the conventional CI" "Gray lines are the KS randomization inference CI")
	}
}

qui drop ___*

capture ereturn scalar pz_est = `pzms_est'
capture ereturn scalar pz_se = `pzms_se'
capture ereturn scalar pz_p = `pzms_p'
capture ereturn scalar pz_ess = `ess'
capture ereturn scalar pz_ess_sum = `ess_SUM'
capture ereturn scalar pz_altp = `alt_p'
capture ereturn scalar pz_alt_se = `alt_se'
capture ereturn scalar pz_altp_sum = `alt_pSUM'
capture ereturn scalar pz_rmse = sqrt(`win_model_ssq'/`iter')
capture ereturn matrix pz_rep_results = `R'
ereturn scalar pz_winbw = ``best'_low_bw'
ereturn matrix pz_winmodels = `WINNERS'
ereturn scalar pz_pzstepsize = `pzstepsize'
ereturn scalar pz_bwstepsize = `bwstepsize'

capture restore

end
