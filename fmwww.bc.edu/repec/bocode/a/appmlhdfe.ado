* Version 1.0 - 9 January 2025
* By Matt Clance and J.M.C. Santos Silva
* Please email jmcss@surrey.ac.uk for help and support

* The software is provided as is, without warranty of any kind, express or implied, including 
* but not limited to the warranties of merchantability, fitness for a particular purpose and 
* noninfringement. In no event shall the authors be liable for any claim, damages or other 
* liability, whether in an action of contract, tort or otherwise, arising from, out of or in 
* connection with the software or the use or other dealings in the software.

program define appmlhdfe, eclass                                                                                    
version 11.1                                                                                                                                                                 
syntax varlist(numeric min=1 fv ts) [if] [in]  [, Expectile(real 0.5)  Absorb(string) NOlog STrict vce(string) start(string) RESidual(string) ///
TOLerance(real 1e-7) ITERate(integer 50)  maxiter(integer 200) SEParation(string) ]         
                                                 
marksample touse                                                                                               
tempname  y _rhs _rhss  res  w wold fit smpl kappa negative b bold cvm kappa                                                             
gettoken y _rhs: varlist                                                                                     

capture findfile ppmlhdfe.ado		
if _rc==601 {
di
di as error "appmlhdfe requires the ppmlhdfe and reghdfe commands, and the ftools package;"
di "please make sure these are installed."
exit
}

if `expectile'<0|`expectile'>1 {
di as error "Expectile must be between 0 and 1"
exit
}

if (`expectile' == 0.5) {
                      capture ppmlhdfe `y' `_rhs'  if `touse', d a(`absorb') sep(`separation') vce(`vce') maxiter(`maxiter')
                      if _rc!=0 di "ppmlhdfe did not converge"
                      else {
                      mat `kappa'=colsof(e(b))
                      local k=`kappa'[1,1]
                      qui predict double `res'  if `touse', xbd
                      qui replace `res'=`y'-exp(`res')
                      if "`residual'"!=""  qui g double `residual'=`res' if `touse'   
                      local conv=e(converged) 
                      local cv=0
                      local count=1
                      }
                      }
else {
if "`start'"=="" {  
qui ppmlhdfe `y' `_rhs'  if `touse', d a(`absorb') sep(`separation') vce(`vce')
mat `bold'=e(b)
qui predict double `res'  if `touse', xbd
qui replace `res'=`y'-exp(`res')
}
else qui g double `res'=`start' if `touse'  


local cv=100
local count=0
qui g double `w'= abs(`expectile' - (`res'<0)) if `touse'
qui g double `wold'=`w'  if `touse'
if ("`nolog'" == "") di
while (`cv' > `tolerance')&(`count'<`iterate') {
local count=`count'+1
capture drop `res' 
if ("`strict'" != "") {
                      capture ppmlhdfe `y' `_rhs' [pw=`w']  if `touse', d a(`absorb') sep(`separation') vce(`vce') maxiter(`maxiter')
                      if _rc!=0 di "ppmlhdfe did not converge"
                      mat `kappa'=colsof(e(b))
                      local k=`kappa'[1,1]
                      }
else {
if `count'==1 {
                      capture ppmlhdfe `y' `_rhs' [pw=`w']  if `touse', d a(`absorb') sep(`separation') vce(`vce') maxiter(`maxiter')
                      if _rc!=0 di "ppmlhdfe did not converge"
                      g `smpl'=e(sample)
                      mat `kappa'=colsof(e(b))
                      local k=`kappa'[1,1]
              }
      else {
                      capture ppmlhdfe `y' `_rhs' [pw=`w']  if (`touse')&(`smpl'==1), d a(`absorb') sep(none) vce(`vce')  maxiter(`maxiter')  
                      if _rc!=0 di "ppmlhdfe did not converge"
           }
}
qui predict double `res'  if `touse', xbd
mat `b'=e(b)
if "`absorb'"!="" mat `b'[1,`k']=0
if (`count'==1)&("`start'"!="") mat `bold'=`b'*0
mat `cvm'=(`b'-`bold')*invsym(e(V))*(`b'-`bold')'
local cv=`cvm'[1,1]
mat `bold'=`b'
qui replace `res'=`y'-exp(`res')
qui replace `wold'=`w'  if `touse'
qui replace `w'=abs(`expectile' - (`res'<0)) if `touse'
if ("`nolog'" == "") di "Iteration " `count' ": objective function = " `cv'
}
if "`residual'"!=""  qui g double `residual'=`res' if `touse'  
local conv = 1
if (`cv'>`tolerance') {
    di as error "Convergence not achieved"
    local conv =0
    }

}
                      

qui g double `fit' = `y'-`res' if `touse'
qui corr `y' `fit' if `touse'
if `k'==1 local r2=0
else local r2=r(rho)^2
ereturn scalar R2 = `r2'
qui g double `negative' = (`res' < 0) if `touse'
su `negative' if `touse', meanonly
local png=r(mean)
ereturn scalar negative = r(mean)
ereturn repost , esample(`touse')
ereturn scalar converged = `conv'
ereturn scalar Q = `cv'

   
di
di as txt " Number of obs = "  _continue
di as result  e(N)
di as txt " Iterations = " _continue
di as result `count'
di as txt " Tolerance = " _continue
di as result `tolerance'
di as txt " Objective function = " _continue
di as result `cv'  
di as txt " % of negative residuals = "  _continue
di as result  int(1000*`png')/1000
di as txt " R-squared: "  _continue
di as result `r2'
di as result `expectile' _continue
di as txt " expectile regression"
ereturn display

if "`absorb'"!=""{
	tempname table
	local width=13
	matrix `table' = e(dof_table)
	mata: st_local("var_width", strofreal(max(strlen(st_matrixrowstripe("`table'")[., 2]))))
	if (`var_width' > `width') loc width = `var_width'
	loc rows = rowsof("`table'")
	loc cols = rowsof("`table'")
	local vars : rownames `table'

	// Setup table
	di as text _n "Absorbed degrees of freedom:"
	tempname mytab
	.`mytab' = ._tab.new, col(5) lmargin(0)
	.`mytab'.width	 `width'  | 12  	    12    		14 			1 |
	.`mytab'.pad		.		 1     		 1		   	 1			0
	.`mytab'.numfmt		.		%9.0g		%9.0g		%9.0g	  	.
	.`mytab'.numcolor	.		text 		text		result		.
	.`mytab'.sep, top

	local explain_exact 0
	local explain_nested 0
	
	// Header
	.`mytab'.titles "Absorbed FE" "Categories" " - Redundant" "  = Num. Coefs" ""
	.`mytab'.sep, middle

	// Body	
	forval i = 1/`rows' {
		local var : word `i' of `vars'
		loc var = subinstr("`var'", "1.", "", .)
		loc note " "
		if (`=`table'[`i', 4]'==1) {
			loc note "?"
			loc explain_exact 1
		}
		if (`=`table'[`i', 5]'==1) {
			loc note "*"
			loc explain_nested 1
		}

		// noabsorb
		if (`rows'==1 & `=`table'[`i', 1]'==1 & strpos("`var'", "__")==1) loc var "_cons"

		.`mytab'.row "`var'" `=`table'[`i', 1]' `=`table'[`i', 2]' `=`table'[`i', 3]' "`note'"
	}

	// Bottom
	.`mytab'.sep, bottom
	if (`explain_exact') di as text "? = number of redundant parameters may be higher"
	if (`explain_nested') di as text `"* = FE nested within cluster; treated as redundant for DoF computation"'
}
end
