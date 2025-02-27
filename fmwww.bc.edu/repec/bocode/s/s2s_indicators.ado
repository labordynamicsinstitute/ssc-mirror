*! version 1.0  20Feb2025
*! Minh Cong Nguyen - mnguyen3@worldbank.org
*! Hai-Anh Hoang Dang - hdang@worldbank.org
*! Kseniya Abanokova - kabanokova@worldbank.org

* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.

* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with this program. If not, see <http://www.gnu.org/licenses/>.

cap program drop s2s_indicators
program define s2s_indicators
                 
	syntax, [welfare(varname numeric) weight(varname numeric) pline(varname numeric) pline2(varname numeric) method(string) ///
	cluster(varname numeric) strata(varname numeric) VLine(varname numeric) INDicators(string) resmat(string) Alpha(integer 1) STD]
	
	version 12, missing
	if c(more)=="on" set more off
    local version : di "version " string(_caller()) ", missing:"
	
	tempname ph ph_var p1h p1h_var p2h p2h_var p3h p3h_var p4h p4h_var p5h p5h_var p6h p6h_var	
    tempvar poorh gaph epoorh vpoorh 
	local method `=lower("`method'")'
	*if "`std'"=="" local optstd *
	*svyset `cluster' [w= `weight'], strata(`strata') singleunit(centered)
	svyset `cluster' [w= `weight'], strata(`strata') singleunit(certainty)
	
	//condition list on indicator later
	*USE POVERTY LINE IN 1ST PERIOD
	qui if "`method'"=="empirical" | "`method'"=="normal" {
		gen double `poorh' = (`welfare' < `pline') if `welfare'~=.			
		svy: mean `poorh'
		mat `p1h'     = e(b)
		mat `p1h_var' = e(V)
	}
	
	qui if "`method'"=="probit" {
		gen double `poorh' = normal(`welfare') if `welfare'~=.
	    svy: mean `poorh'
	    mat `p1h'     = e(b)
	    mat `p1h_var' = e(V)
	}
	
	qui	if "`method'"=="logit" {
		gen double `poorh' = invlogit(`welfare') if `welfare'~=.
	    svy: mean `poorh'
	    mat `p1h'     = e(b)
	    mat `p1h_var' = e(V)
	}

	qui gen double `gaph'   = `poorh'*((`pline'- `welfare')/`pline')^(`alpha') if `welfare'~=.  
	svy: mean `gaph'
	mat `p2h'     = e(b)
	mat `p2h_var' = e(V)
	  
	svy, subpop(`poorh'): mean `gaph' 
	mat `p3h'     = e(b)
	mat `p3h_var' = e(V)
	  
	if "`pline2'"~="" {
		qui gen double `epoorh' = (`welfare' < `pline2') if `welfare'~=.
		svy: mean `epoorh'
		mat `p4h'     = e(b)
		mat `p4h_var' = e(V)
	}
	else {
		mat `p4h'     = .
		mat `p4h_var' = .
	}
	
	if "`vline'"~="" {
		qui gen double `vpoorh' = (`welfare' >= `pline' & `welfare'< `vline') if `welfare'~=.
		svy: mean `vpoorh'
		mat `p5h'     = e(b)
		mat `p5h_var' = e(V)
	}
	else {
		mat `p5h'     = .
		mat `p5h_var' = .
	}
	  
	svy: mean `welfare'
	mat `p6h'     = e(b)
	mat `p6h_var' = e(V)
	  
	*CONSUMPTION DISTRIBUTION
	epctile `welfare', p(5 10 25 50 75 90 95) svy		   
	mat `ph'     = e(b)
	mat `ph_var' = e(V)
	
	if "`method'"=="probit" | "`method'"=="logit" {	    
		if "`std'"=="" {
		     mat `resmat' = nullmat(`resmat') \ (`p1h'[1,1])
		}	    
		else {
		     mat `resmat' = nullmat(`resmat') \ (`p1h'[1,1], `p1h_var'[1,1])	
	    }
    }

	if "`method'"=="empirical" | "`method'"=="normal" {
		if "`std'"=="" {
			mat `resmat' = nullmat(`resmat') \ (`p1h'[1,1], `p2h'[1,1], `p3h'[1,1], `p4h'[1,1], `p5h'[1,1], `p6h'[1,1], `ph'[1,1], `ph'[1,2], `ph'[1,3], `ph'[1,4], `ph'[1,5], `ph'[1,6], `ph'[1,7])
		}
		else {
			mat `resmat' = nullmat(`resmat') \ (`p1h'[1,1], `p1h_var'[1,1], `p2h'[1,1], `p2h_var'[1,1], `p3h'[1,1], `p3h_var'[1,1], `p4h'[1,1], `p4h_var'[1,1], `p5h'[1,1], `p5h_var'[1,1], `p6h'[1,1], `p6h_var'[1,1], `ph'[1,1], `ph_var'[1,1], `ph'[1,2], `ph_var'[2,2], `ph'[1,3], `ph_var'[3,3], `ph'[1,4], `ph_var'[4,4], `ph'[1,5], `ph_var'[5,5], `ph'[1,6], `ph_var'[6,6], `ph'[1,7], `ph_var'[7,7])	
		}
	}
	
	cap drop `poorh' `gaph' `epoorh' `vpoorh'
end