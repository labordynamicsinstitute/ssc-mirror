* Version 1.1 - 08/08/16
* By J.M.C. Santos Silva 
* Please email jmcss@surrey.ac.uk for help and support

* The software is provided as is, without warranty of any kind, express or implied, including 
* but not limited to the warranties of merchantability, fitness for a particular purpose and 
* noninfringement. In no event shall the authors be liable for any claim, damages or other 
* liability, whether in an action of contract, tort or otherwise, arising from, out of or in 
* connection with the software or the use or other dealings in the software.


program define aextlogit, eclass                                                                                   
version 11.0

syntax varlist(fv) [if] [in] [iweight] [, Betas NOlog vce(string)  ///  
                   TECHnique(string) ITERate(integer 16000) TRace difficult GRADient showstep HESSian /// 
                   SHOWTOLerance TOLerance(real 1e-4) LTOLerance(real 1e-7) NRTOLerance(real 1e-5) ///
                   NONRTOLerance from(string) ]
                                                                   
marksample touse  
markout `touse'                                              
tempname  _y  _rhs sb v
gettoken _y _rhs: varlist  


qui su `_y' if `touse' [`weight'`exp'], mean 
local yb=r(mean)
local vy=r(mean)*(1-r(mean))/r(sum_w)
local ny=r(sum_w)
xtlogit `_y' `_rhs' if (`touse') [`weight'`exp'], fe technique(`technique') iterate(`iterate') vce(`vce') `nolog'  /// 
`trace' `difficult'  `gradient' `showstep' `hessian' `showtolerance' tolerance(`tolerance') ///
ltolerance(`ltolerance') nrtolerance(`nrtolerance') `nonrtolerance' from(`from')  nodisplay
  
  di 
  di "Conditional fixed-effects logistic regression" _continue
  di _column(49) "Number of obs      =" %10.0g e(N)
  di "Group variable: "  e(group) _continue
  di _column(49) "Number of groups   =" %10.0g e(N_g)
  di _column(49) "Obs per group: min =" %10.0g e(g_min)    
  di _column(49) "               avg =" %10.0g e(g_avg)    
  di "Log likelihood  = " e(ll) _continue
  di _column(49) "               max =" %10.0g e(g_max)  
  
   
  if "`betas'" == "betas" ereturn display, first 
    
  matrix `v'=((1-`yb')^2)*e(V)+(`vy')*(e(b)')*e(b)
  matrix `sb'=(1-`yb')*e(b)
  ereturn repost  b = `sb'
  ereturn repost  V = `v'
  ereturn local cmd2 "aextlogit"
  ereturn local marginsok ""
  ereturn local marginsdefault ""
  ereturn local predict ""
  ereturn scalar ybar = `yb'  
  ereturn scalar N_ybar = `ny'  
  di
  di "                   Average (semi) elasticities of Pr(y=1|x,u)"
  ereturn display, first 
  di "Average of `_y' = " `yb' " (Number of obs = " `ny' ")"
  
 end
