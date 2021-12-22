******************************************
*** generate examples for flexpaneldid ***
******************************************
set more off
/* path definitions */
global path_P "p:\Projekte\Matching_Ado"
global path_SJ "$path_P\Paper\Stata_Journal_Revision_01\"

adopath + "$path_P\github\"
discard
which flexpaneldid
cd $path_SJ

*** example 0: preprocessing
use flexpaneldid_example_data.dta, clear
sjlog using example_preprocessing, replace
flexpaneldid_preprocessing , id(cusip) treatment(treatment) time(year) ///
	matchvars(employ stckpr rnd sales return pats_cat rndstck_cat rndeflt_cat) ///
	matchvarsexact(sic_cat) matchtimerel(-1) ///
	prepdataset("preprocessed_data.dta") replace
sjlog close, replace

*** example 1: statmatching, 1:1, outcometimerelstart, outcome-development, test
sjlog using example_flexpaneldid_1, replace
use flexpaneldid_example_data.dta, clear 
set seed 13
flexpaneldid patents, id(cusip) treatment(treatment) time(year) ///
	statmatching(con(employ stckpr rnd sales) cat(pats_cat rndstck_cat)) ///
	outcometimerelstart(3) outcomedev(-2 -1) ///
	prepdataset("preprocessed_data.dta") test
sjlog close, replace
* change the look of the qq-plot manually	
graph save $path_SJ/example_flexpaneldid_1_qq_plot.gph, replace
run change_qq_plots 
graph export $path_SJ/example_flexpaneldid_1_qq_plot.pdf, replace 
erase $path_SJ/example_flexpaneldid_1_qq_plot.gph

*** example 2: statmatching, radius, outcometimerelend, outcome-level, outcomemissing, different matching vars
sjlog using example_flexpaneldid_2, replace
use flexpaneldid_example_data.dta, clear 
set seed 13
flexpaneldid patents, id(cusip) treatment(treatment) time(year) ///
	statmatching(con(employ stckpr return) cat(rndeflt_cat rndstck_cat) radius(0.1)) ///
	outcometimerelend(2) outcomedev(-2) outcomemissing didmodel ///
	prepdataset("preprocessed_data.dta") 
sjlog close, replace
	
*** example 3: cem-matching k2k; variables and options like example 2 
sjlog using example_flexpaneldid_3, replace
use flexpaneldid_example_data.dta, clear 
set seed 13
flexpaneldid patents, id(cusip) treatment(treatment) time(year) ///
	cemmatching(employ (#5) stckpr(100 200 300) rnd sales pats_cat(#0) rndstck_cat(#0) k2k) ///
	outcometimerelend(2) outcomedev(-2) outcomemissing test ///
	prepdataset("preprocessed_data.dta")
sjlog close, replace
* change the look of the qq-plot manually	
graph save $path_SJ/example_flexpaneldid_3_qq_plot.gph, replace
run change_qq_plots 
graph export $path_SJ/example_flexpaneldid_3_qq_plot.pdf, replace 
erase $path_SJ/example_flexpaneldid_3_qq_plot.gph
