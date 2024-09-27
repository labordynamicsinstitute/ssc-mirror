*! sample do.file for xtvar.ado v1.0.1 
*! Friedrich-Alexander University Erlangen-Nürnberg
*! Copyright Tobias Cagala & Ulrich Glogowsky October 2012. May be distributed free.

*general stuff
	set mat 500													//use Monte-Carlo for huge datasets (because of matsize restriction)
	adoupdate
	
*globals
	global path = ""			//specify dataset-containing folder
	
*use dataset
	clear all
	use "$path/xtvar2.dta"
	
*xtset your data
	xtset i t

*estimates var with contemporaneous effect of y1 on y2
*confidence intervals with Monte-Carlo   
	xtvar2 y1 y2, mc lags(1)
	
*estimates var with contemporaneous effect of y1 on y2
*confidence intervals with Double Bootstrapping
	xtvar2 y1 y2, dbsn lags(1)
	
*estimates var with contemporaneous effect of y1 on y2
*confidence intervals with Monte-Carlo
*save results
	xtvar2 y1 y2, mc lags(1)ssaving($path/results, replace) 	
	
*estimates var with contemporaneous effect of y1 on y2
*confidence intervals with Monte-Carlo
*no graphs
*300 repetitions
*10 steps
	xtvar2 y1 y2, mc lags(1) nodraw reps(300) step(10)
	