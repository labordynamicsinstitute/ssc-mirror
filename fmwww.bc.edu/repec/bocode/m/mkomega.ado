********************************************************************************
* PROGRAM "mkomega_2", 16May2022
* G.Cerulli
********************************************************************************
program mkomega_2, rclass
version 14
#delimit ;     
syntax varlist [if] [in] , sim_measure(string) out(varlist max=1 numeric)
;
#delimit cr
********************************************************************************
* IMPUTATION
********************************************************************************
marksample touse , novarlist
tokenize `varlist'
local w `1'
macro shift
local xvars `*'
tokenize `xvars'
local x1 `1'
macro shift
local xrest `*'
local mxvars `xrest'
local B ","
local xvars2 `x1'
foreach v of local mxvars{
local xvars2 `xvars2' `B'`v'
}
********************************************************************************
tempvar sample
gen `sample'=missing(`xvars2' , `w' , `out') 
********************************************************************************
preserve
keep if `sample'==0
********************************************************************************
tempvar ___ID // NEW
gen `___ID'=_n // NEW
gsort - `w' `___ID' // NEW
********************************************************************************
qui tab `w' , mis
local N = r(N)
qui count if `w'==1
local N1 = r(N)
local N0 = `N'-`N1'
********************************************************************************
* b. PROVIDE THE MATRIX "OMEGA" (THAT I CALL HERE "dist")
********************************************************************************
if "`sim_measure'" == "corr"{
tempname dist
matrix dissimilarity `dist' = `xvars' if `touse', `sim_measure'
}
else if "`sim_measure'" == "L2"{
tempname dist
matrix dissimilarity `dist' = `xvars' if `touse', `sim_measure' 
mata: mksim("`dist'") 
tempname dist
mat `dist'=M3
}
********************************************************************************
tempname dist_abs
matewmf `dist' `dist_abs', f(abs) // take the absolute values of the correlation matrix
tempname M
mat `M' = `dist_abs'*100
********************************************************************************
local N1plus1 = `N1'+1
forvalues i=1/`N'{
forvalues j=`N1plus1'/`N'{
mat `M'[`i',`j']=0
}
}
********************************************************************************
tempname SUM
mat def `SUM'=J(_N,1,0)
forvalues i=1/`N'{
forvalues j=1/`N1'{
mat `SUM'[`i',1] = `SUM'[`i',1] + `M'[`i',`j']
}
}
********************************************************************************
forvalues i=1/`N'{
forvalues j=1/`N1'{
mat `M'[`i',`j']=`M'[`i',`j']/`SUM'[`i',1]
}
}
********************************************************************************
* Check that the sum of numbers along each row is = 1
********************************************************************************
mat def `SUM'=J(_N,1,0)
forvalues i=1/`N'{
forvalues j=1/`N1'{
mat `SUM'[`i',1] = `SUM'[`i',1] + `M'[`i',`j']
}
}
********************************************************************************
return scalar N0=`N'-`N1'
return scalar N1=`N1'
return scalar N=`N'
return matrix RowSumM=`SUM'
return matrix M=`M'
********************************************************************************
restore
********************************************************************************
end  // end of "mkomega"
********************************************************************************
*
********************************************************************************
* MATA FUNCTION "mksim()"
********************************************************************************
capture mata mata drop mksim()
version 14
mata:
void mksim(string scalar mdist)
{
M=.
M=st_matrix(mdist)
Nr=rows(M)
Nc=cols(M)
I=I(Nr)
M2=I+M
ONE=J(Nr,Nr,1)
M3=(ONE:/M2)
st_matrix("M3",M3) // Matrix M3 is now in Stata
}
end
********************************************************************************
