********************************************************************************
*! Version 0.63, 8jul2020, Michael Droste, mdroste@fas.harvard.edu
*! More info and latest version: github.com/mdroste/stata-pylearn
********************************************************************************

cap program drop nnls_predict
program define nnls_predict, eclass
	version 16.0
	syntax anything(id="argument name" name=arg) [if] [in], [xb]
	
	* Mark sample with if/in
	marksample touse, novarlist
	
	* Count number of variables
	local numVars : word count `arg'
	if `numVars'!=1 {
		di as error "Error: More than 1 prediction variable specified"
		exit 1
	}
	
	* Define locals prediction, features
	local predict_var "`arg'"
	local features "`e(features)'"
	local weights "`e(Weights)'"
	
	* Check to see if variable exists
	cap confirm new variable `predict_var'
	if _rc>0 {
		di as error "Error: prediction variable `predict_var' already exists in dataset."
		di as error "Choose another name for the prediction."
		exit 1
	}
	
	* Generate an index variable for merging
	tempvar temp_index
	gen `temp_index' = _n
	tempfile t1
	qui save `t1'
	
	* Keep joint nonmissing over features
	foreach v of varlist `features'{
		qui drop if mi(`v')
	}
	
	* Get predictions
	python: post_prediction("`features'", "`weights'","`predict_var'")
	
	* Keep only prediction and index
	keep `predict_var' `temp_index'
	tempfile t2
	qui save `t2'
		
	* Load original dataset, merge prediction on
	qui use `t1', clear
	qui merge 1:1 `temp_index' using `t2', nogen

	* Keep only if touse
	qui replace `predict_var'=. if `touse'==0
end

python:

# Import SFI, always with stata 16
from sfi import Data,Matrix,Scalar
from pandas import DataFrame
import numpy as np

from __main__ import weights as W
from __main__ import X as X

def post_prediction(_features, _weights, prediction):
    
	_features = X
	_weights = W

	# Generate predictions
	pred = np.dot(_features, _weights)

	# Export predictions back to Stata
   	Data.addVarFloat(prediction)
	Data.store(prediction,None,pred)
end
