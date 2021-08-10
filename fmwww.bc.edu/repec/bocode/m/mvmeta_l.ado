prog def mvmeta_l
/* 
derived from mvmeta_loglik: 
   work with matrices
   takes 4 or 5 arguments
   transformed or not
mvmeta_loglik_chol, 11 June 2007:
   ignore MVMETA_trans
   no gradient
   use MVMETA_p
   parms beta1, beta2, 
*/

args todo b lnf

local y $MVMETA_y
local S $MVMETA_S
local n $MVMETA_n
local p $MVMETA_p
local names $MVMETA_names
local bsest $MVMETA_bsest

tempname BETA SIGMA chol

* form BETA and SIGMA from parameters b
matrix `BETA'=`b'[1,1..`p']
mat `chol' = J(`p',`p',0)
local k `p'
forvalues i=1/`p' {
   forvalues j=1/`i' {
      local ++k
      mat `chol'[`i',`j']=`b'[1,`k']
   }
}
matrix `SIGMA'=`chol'*`chol''

tempname W dev minustwoll Wsum
if "`bsest'"=="reml" mat `Wsum' = J(`p',`p',0)
local ll 0
forvalues i = 1/`n' {
   cap mat `W' = invsym(`S'`i'+`SIGMA')
   if _rc {
      di as error "Problem at observation `i':"
      mat l `b'
      mat l `S'`i'
      mat l `SIGMA'
      pause
      exit 498
   }
   mat `dev' = `y'`i'-`BETA'
   mat `minustwoll' = `p'*log(2*_pi) - log(det(`W')) + `dev' * `W' * `dev''
   local ll = `ll' - `minustwoll'[1,1]/2
   if "`bsest'"=="reml" mat `Wsum' = `Wsum' + `W'
}
if "`bsest'"=="reml" local ll = `ll' - log(det(`Wsum'))/2 + `p'*log(2*_pi)/2

scalar `lnf' = `ll'

mat colnames `BETA' = `names'
mat rownames `SIGMA' = `names'
mat colnames `SIGMA' = `names'

mat MVMETA_BETA = `BETA'
mat MVMETA_SIGMA = `SIGMA'

end
