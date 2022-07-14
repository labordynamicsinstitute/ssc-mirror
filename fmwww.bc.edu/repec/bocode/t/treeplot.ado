*! "treeplot" - Plotting regression and classification trees with Stata/Python
*! G.Cerulli, 13July2022
program treeplot , eclass
    version 16
    syntax varlist [if] [in] , h(name) predict(name) ///
	tree_depth(numlist integer max=1) type(string) save_gr(name) ///
	fig_size(numlist integer max=1) dpi(numlist integer max=1)
	qui{ // start quietly
	tempvar ID
	gen `ID'=_n
	preserve
    gettoken label feature : varlist
	marksample touse 
	qui reg `label' `feature' if `touse'
	tempvar _sample
	gen `_sample'=e(sample)
	qui keep if e(sample)
	markout `touse' `_sample'
	tempvar `h'
	gen `h'= `touse'
    //call the Python function
di _newline(2)	

di in red "=== Begin Python warnings ==========================================================================="
    python: _pylot("`label'", "`feature'", "`predict'","`touse'","`type'","`save_gr'")
di in red "=== End Python warnings ============================================================================="
di _newline	
	tempfile mydata
	qui save `mydata' , replace
	restore
	qui merge 1:1 `ID' using `mydata'
	qui drop _merge
	ereturn local sample `touse'
	} // end quietly
********************************************************************************
di as result "------------------------------------------------------------------"
di as result "Tree graph correctly generated as: '`save_gr''.png"
di as result "------------------------------------------------------------------"
********************************************************************************
end


version 16
python:
def _pylot(label, features, predict, touse, type, save_gr):

	# IMPORT DEPENDENCIES
	from sfi import Data , Macro , Scalar
	from sklearn import tree
	import matplotlib.pyplot as plt
	import numpy as np
	import pandas as pd
	from sklearn import preprocessing
	from sfi import ValueLabel

	# IMPORT DATASET AND FORM (X,y)
	y = Data.get(label,None,selectvar=touse,missingval=np.nan)
	X = pd.DataFrame(Data.get(features,None,selectvar=touse,missingval=np.nan))
	
	# GIVE VARIABLE NAMES TO THE COLUMNS OF "X"
	colnames = []
	for var in features.split():
		 colnames.append(var)
	X.columns = colnames
	
	if type=="class":
	
		# ENCODE "y"
		lab_enc = preprocessing.LabelEncoder()
		y2=lab_enc.fit_transform(y) 

		# FIT DECISION TREE
		depth=int(Macro.getLocal('tree_depth'))
		clf = tree.DecisionTreeClassifier(max_depth=depth)
		clf = clf.fit(X, y2)
		
		# GENERATE PREDICTION
		X2 = Data.get(features,None,selectvar=None)
		y_pred = clf.predict(X2)
		print(len(y_pred))
		Data.addVarByte(predict)
		Data.store(predict, None, y_pred)

		# PLOT TREE
		# PUT INTO TWO LISTS THE NAMES OF THE FEATURES AND OF THE CLASSES
		# NAME OF THE FEATURES
		fn=X.columns.values.tolist()
		
		# NAME OF THE CLASSES
		A=ValueLabel.getVarValueLabel(label)
		B=ValueLabel.getValueLabels(A)
		cn = list(B.values())

		# PREPARE FRAME FOR PLOT
		f_size=int(Macro.getLocal('fig_size'))
		_dpi=int(Macro.getLocal('dpi'))
		fig, axes = plt.subplots(nrows = 1,ncols = 1,figsize = (f_size,f_size), dpi=_dpi)

		# GENERATE PLOT
		tree.plot_tree(clf,
					   feature_names = fn, 
					   class_names=cn,
					   filled = True);

		# SAVE THE PLOT
		fig.savefig(save_gr+".png")	
		
	if type=="reg":
	
		# FIT DECISION TREE
		depth=int(Macro.getLocal('tree_depth'))
		rgr = tree.DecisionTreeRegressor(max_depth=depth)
		rgr = rgr.fit(X, y)
		
		# GENERATE PREDICTION
		X2 = Data.get(features,None,selectvar=None)
		y_pred = rgr.predict(X2)
		print(len(y_pred))
		Data.addVarByte(predict)
		Data.store(predict, None, y_pred)

		# PLOT TREE
		# PUT INTO TWO LISTS THE NAMES OF THE FEATURES AND OF THE CLASSES
		# NAME OF THE FEATURES
		fn=X.columns.values.tolist()

		# PREPARE FRAME FOR PLOT
		f_size=int(Macro.getLocal('fig_size'))
		_dpi=int(Macro.getLocal('dpi'))
		fig, axes = plt.subplots(nrows = 1,ncols = 1,figsize = (f_size,f_size), dpi=_dpi)

		# GENERATE PLOT
		tree.plot_tree(rgr,
					   feature_names = fn, 
					   filled = True);

		# SAVE THE PLOT
		fig.savefig(save_gr+".png")	
		
end
