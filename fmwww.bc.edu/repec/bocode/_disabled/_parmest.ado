*! This is just a copy of parmest.ado version 3.01 featured in STB-58 dm65.3
* The only difference is that it has been renamed _parmest.
* The reason for this is that was to avoid the possibility of incompatibility
* with subsequent versions of parmest.
program define _parmest,rclass
version 6.0
/*
 If current estimation matrices exist,
 then extract the parameter names, estimates,
 standard errors and confidence limits
 and reformat them as a data set with 1 observation per parameter,
 (replacing the current one, in the manner of the collapse command).
 This program calls programs estse, svroweq and svrown.
 Author: Roger Newson
 Date: 6 October 2000
*/
syntax [, Label EForm Dof(real -1) LEvel(int $S_level) /*
    */ FAST SAving(string asis) noREstore]
/*
 Dof contains residual DF for t-based confidence limits.
 In default, it is set to the value
 from the currently stored estimation results.
 If dof is zero, then normal confidence limits are calculated.
 Label indicates that the new data set
 should contain a variable named label,
 containing labels corresponding to variables named in parm
 (wherever such variables exist in the pre-existing data set).
 EForm indicates that the estimates and confidence limits
 are to be exponentiated, and the standard errors multiplied
 by the exponentiated estimate.
 FAST specifies that parmest not preserve the original data set
 so that it can be restored if the user presses Break
 (intended for use by programmers).
 SAving specifies a data set in which to save the output data set.
 noREstore specifies whether or not the pre-existing data set
 is restored after the new data set has been produced
 (ignored and set to norestore
 if FAST is present or SAving() is absent,
 and defaulting to restore if SAving() is present).
*/


/*
 Set restore to norestore
 if fast is present or saving() is absent
*/
if(("`fast'"!="")|("`saving'"=="")){
    local restore="norestore"
}


/*
  Reset dof to current estimates if negative
*/
if(`dof'<0){
    if "`e(df_r)'" == "" {
        local dof=0
    }
    else {
        local dof=`e(df_r)'
    }
}


/*
 Create matrix of estimates and SEs if possible,
 and extract observations and degrees of freedom into local macros
 for creation of confidence limits
*/

tempname estse
capture estse `estse'
if _rc != 0 {
        di in r "Data will not be replaced"
        if _rc == 301 { error 301 }
        else {
                di in r "Estimates and SEs could not be extracted"
                exit 498
        }
}

/*
 Store variable labels in macros with names of form labi1
 if label requested
*/

if "`label'" != "" {
        local xvlist : rownames(`estse')
        local nxv : word count `xvlist'
        local i1 = 0
        while `i1' < `nxv' {
                local i1 = `i1' + 1
                local xvcur : word `i1' of `xvlist'
                local lab`i1' ""
                capture local lab`i1' : variable label `xvcur'
        }
}

/*
 Preserve old data set if restore is set or fast unset
*/
if("`fast'"==""){
    preserve
}

* Create new data set *
drop _all
svroweq `estse' eq
svrown `estse' parm
svmat double `estse', name(col)
local nparm=_N
label variable eq "Equation name"
label variable parm "Parameter name"
label variable estimate "Parameter estimate"
label variable stderr "SE of parameter estimate"

* Add label if requested *
if "`label'" != "" {
        qui gene str1 label = ""
        local i1 = 0
        while `i1' < `nxv' {
                local i1 = `i1' + 1
                qui replace label = "`lab`i1''" in `i1'
        }
        order eq parm label
        label variable label "Parameter label"
}


* Drop variable eq if it contains only underscores *

qui {
        count if eq == "_"
        if r(N) == _N { drop eq }
}

* Add confidence limits *
local cimin  "min`level'"
local cimax  "max`level'"
tempvar hwid
if `dof' <= 0 {
    qui gene double z = estimate / stderr
    qui gene double p = 2 * normprob(-abs(z))
    qui gene double `hwid'= stderr*invnorm(1-(100-`level')/200)
    label variable z "Standard normal deviate"
    label variable p "P-value"
}
else {
    qui gene double t = estimate / stderr
    qui gene double p = tprob(`dof',t)
    qui gene double `hwid' = stderr*invt(`dof',`level'/100)
    label variable t "t-test statistic"
    label variable p "P-value"
}
qui gene double `cimin' = estimate - `hwid'
qui gene double `cimax' = estimate + `hwid'
drop `hwid'
label variable `cimin' "Lower `level'% confidence limit"
label variable `cimax' "Upper `level'% confidence limit"

* EForm transformation if requested *
if "`eform'" != "" {
        qui {
                replace estimate = exp(estimate)
                replace stderr = stderr * estimate
                replace `cimin' = exp(`cimin')
                replace `cimax' = exp(`cimax')
        }
}

/*
 Save data set if requested
*/
if(`"`saving'"'!=""){
    capture noisily save `saving'
    if(_rc!=0){
        disp in red "saving(`saving') invalid"
        exit 498
    }
}

/*
 Restore old data set if restore is set
 or if program fails when fast is unset
*/
if(("`fast'"=="")&("`restore'"=="norestore")){
    restore,not
}

/*
 Return saved results
*/
return local eform "`eform'"
return scalar level=`level'
return scalar nparm=`nparm'
return scalar dof=`dof'

end

program define estse
version 6.0
/*
 Create output matrix
 with rows corresponding to parameters of last model
 and 1 column each for estimates and standard errors
*/
args estse
if "`estse'" == "" { local estse "estse"}

tempname esti cov stderr
* Temporary matrices *
matrix `esti' = e(b)
matrix `cov' = e(V)
matrix `esti' = `esti''
matrix `stderr' = vecdiag(`cov')
matrix `stderr' = `stderr''
local nparm = rowsof(`stderr')
local i1 = 0
while `i1' < `nparm' {
        local i1 = `i1' + 1
        matrix `stderr'[`i1',1] = sqrt(`stderr'[`i1',1])
}
matrix `estse' = `esti', `stderr'
matrix coln `estse' = estimate stderr
end

program define svroweq
version 6.0
/*
 Save row equation names from `matrix' in string variable `roweq'.
 (This routine is designed to be used with svmat.)
*/
args matrix roweq

if "`matrix'" == "" {
        di in r "No matrix specified"
        error 498
}
if "`roweq'" == "" {
        di in r "No variable name specified"
        error 498
}
local nrow = rowsof(`matrix')

* Create variable `roweq' *
tempname tempmat
qui capture drop `roweq'
qui set obs `nrow'
qui gen str1 `roweq' = ""
local rowind = 0
while `rowind' < `nrow'{
        local rowind = `rowind' + 1
        matr def `tempmat'=`matrix'[`rowind'..`rowind',1..1]
        local namec : roweq(`tempmat')
        qui replace `roweq' = "`namec'" in `rowind'
}

end

program define svrown
version 6.0
/*
 Save row names from `matrix' in string variable `rowname'.
 (This routine is designed to be used with svmat.)
*/
args matrix rowname

if "`matrix'" == "" {
        di in r "No matrix specified"
        error 498
}
if "`rowname'" == "" {
        di in r "No variable name specified"
        error 498
}
local nrow = rowsof(`matrix')

* Create variable `rowname' *
tempname tempmat
qui capture drop `rowname'
qui set obs `nrow'
qui gene str1 `rowname' = ""
local rowind = 0
while  `rowind' < `nrow' {
        local rowind = `rowind' + 1
        matr def `tempmat'=`matrix'[`rowind'..`rowind',1..1]
        local namec : rownames(`tempmat')
        qui replace `rowname' = "`namec'" in `rowind'
}

end
