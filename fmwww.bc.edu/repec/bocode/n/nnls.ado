********************************************************************************
* "nnls": Nonnegative Least Squares in Stata using Python
* GCerulli, 6 May 2024
* Version: 4
********************************************************************************

cap program drop nnls
program nnls , eclass
    version 16
    syntax varlist [if] [in] , [graph graph_save(string) STANDardize]  
	
	* Pass varlist into varlists called "y" and "X"
    gettoken y X: varlist
	local num_features: word count `X'
	
	* Generate an index of "original data" so we can easily merge back on the results
	tempvar index
	gen `index' = _n
	
	* Restrict sample with "if" and "in" conditions
	marksample touse, strok novarlist
	tempvar touse2
	gen `touse2' = `touse'
	ereturn post, esample(`touse2')
	
	* If requested, generate standardized variables
	if "`standardize'"!=""{
		
		* Check to see if variable exists
		foreach v of local varlist{
		cap confirm new variable z_`v'
		if _rc>0 {
			di as error "Error: variable z_`v' already exists in dataset."
			exit 1
		}	
		}	
	* Generate the standardized variables
	center `varlist' ,  prefix(z_) replace standardize
	local z_varlist ""
	foreach v of local varlist{
		local z_varlist `z_varlist' z_`v'
	}
	gettoken y X: z_varlist
	}
	
	* Preserve original data
	preserve
	
	* Eliminate label values
	label drop _all
	
	* Keep only if/in
	qui drop if `touse'==0

	* Restrict sample to jointly nonmissing observations
	foreach v of varlist `varlist'{
	qui drop if mi(`v')
	}
	
	* Call Python function "_nnls"
    python: _nnls("`y'", "`X'")
	tempname M
	tempname B
	tempname C
	mat `M'=M
	matrix rownames `M'=`X'
	matrix colnames `M'=Weights
	matlist `M' , title(WEIGHTS: not summing up to 1)
	mata : st_matrix("`B'", colsum(st_matrix("`M'")))
    scalar _s=`B'[1,1]
	mat `C'=`M'/_s
	matrix rownames `C'=`X'
	matrix colnames `C'=Unit_Weights
	matlist `C' , title(WEIGHTS: summing up to 1)

	* Keep the index and prediction, then merge onto original data
	keep `index' `prediction'
	tempfile t1
	qui save `t1'
	restore
	qui merge 1:1 `index' using `t1', nogen
	drop `index'
	
	* Ereturn objects
	ereturn local predict "nnls_predict"
	ereturn local features "`X'"
	ereturn local depvar "`y'"
	ereturn local num_features "`num_features'"
	ereturn local cmd "_nnls"
	ereturn matrix Weights=`M'
	ereturn matrix Unit_Weights=`C'
	ereturn scalar VERSION=5
	
	* Importance graph
	if "`graph'"!=""{
	preserve
	* Convert the matrix to a variable
	tempname M
	matrix `M'=e(Unit_Weights)
	tempvar imp
	svmat2 `M' , names(col) r(`imp')
	*Graph the results
	qui graph hbar (mean) Unit_Weights , over(`imp', sort(1)) ytitle(Importance) saving(`graph_save',replace)
	restore
	}

end


python:

from sfi import Data , Matrix
import numpy as np
from scipy.optimize import nnls
import __main__

def _nnls(y, X):
  X = np.array(Data.get(X))
  y = np.array(Data.get(y)) 
  
  # Estimate the non-negative least squares
  coefficients, _ = nnls(X, y)
  
  # Get the estimated coefficients (weights)
  weights = coefficients
  
  # Create a Stata matrix "M" containing the "weights" 
  Matrix.store("M",weights)
  
  # Pass objects back to __main__ namespace for later interaction
  __main__.weights = weights
  __main__.X = X
  
end
********************************************************************************
