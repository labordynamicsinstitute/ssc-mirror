program cdfquantreg01 , eclass  
version 15.0
   gettoken y 0 : 0
   unab y : `y'
   ** check that y is a variable
   confirm numeric variable `y'
   syntax [varlist(default=none ts fv)] [if] [in] , cdf(string) quantile(string) pos(string) func(string) twothree(string) ///
   [Zvarlist(varlist ts fv)] [Wvarlist(varlist ts fv)] [nolog] [Robust]
   marksample touse
   
   ** allowable cdf/quantile distributions, including strange name-shifts
   if !inlist(`"`cdf'"', "asinh", "cauchit", "t2") {
      display as error `"Bad cdf distribution: `cdf'"'
      exit 198
      }
   if !inlist(`"`quantile'"', "asinh", "cauchy", "t2") {
      display as error `"Bad quantile distribution: `quantile'"'
      exit 198
      }
   if !inlist(`"`pos'"', "inner", "outer") {
      display as error `"Bad quantile distribution: `pos'"'
      exit 198
      }
   if !inlist(`"`func'"', "v", "w") {
      display as error `"Bad quantile distribution: `func'"'
      exit 198
      }
   if !inlist(`"`twothree'"', "2", "3") {
      display as error `"Bad quantile distribution: `twothree'"'
      exit 198
      }
   local dist  `"`cdf'`quantile'`pos'`func'`twothree'"'

if inlist(`"`twothree'"', "2") {
ml model lf `dist' (`y' = `varlist') (`zvarlist') if `touse', vce(`robust')
   quietly ml search
   ml max, `log'
}
if inlist(`"`twothree'"', "3") {
ml model lf `dist' (`y' = `varlist') (`zvarlist') (`wvarlist') if `touse', vce(`robust')
   quietly ml search
   ml max, `log' 
}

      ** Specify what marginals should and should not do
   ereturn local marginsok xb stdp predict qtile pctle default
   ereturn local marginsnotok Residuals   
   ereturn local  predict "cdfquantreg01_p"
end
