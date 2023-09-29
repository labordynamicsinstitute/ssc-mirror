********************************************************
* Commands from Section 6, Outputs: Application to ROSSINI 2 trial Example
* Command from Appendix A: Example of MAMS designs with an I outcome 
********************************************************

capture log close
set trace off
version 17.0
clear

loc startdate "$S_DATE"
loc starttime "$S_TIME"
loc logname "nstagebin_manuscript_and_helpfile_examples_27June23"
log using `logname', replace text
window manage maintitle "Running `logname'.do"

set more off

nois di "File run: `logname'.do"
nois di "Output file produced: $S_DATE $S_TIME"
nois di "--------------------------------------"


* Commands from Section 6, Outputs: Application to ROSSINI 2 trialExample

nstagebinopt, nstage(3) arms(8) alpha(0.025) power(0.85) theta0(0) theta1(-0.05) ///
ctrlp(0.15) ltfu(0.04) fu(4) accrate(118 248 248) aratio(0.5) fwer plot 

nstagebin, nstage(3) arms(8 6 4) alpha(0.40 0.14 0.005) power(0.94 0.94 0.91) theta0(0) ///
theta1(-0.05) ctrlp(0.15) ltfu(0.04) fu(4) accrate(118 248 248) aratio(0.5) tunit(4) seed(123)



* Appendix A: Example of MAMS designs with an I outcome

nstagebin, nstage(2) arms(2 2) alpha(0.5 0.025) power(0.9 0.9) theta0(0 -0.06) ///
    theta1(0.13 0) ctrlp(0.75 0.9) ppvc(0.95) ppve(0.95) accrate(200 800) ///
    fu(0.27 1.5) extrat(0.075) ltfu(0.15 0.2) tunit(1) 


*** Examples in nstagebin helpfile
	
nstagebin, nstage(3) accrate(10 10 10) alpha(0.3 0.15 0.025) ///
             power(0.95 0.95 0.90) arms(4 4 2) theta0(0) ///
             theta1(0.15) ctrlp(0.8) fu(1) ltfu(0.1) tunit(4) 


nstagebin, nstage(4) accrate(200 200 300 600) alpha(0.5 0.25 0.1 0.05) ///
             power(0.95 0.95 0.95 0.90) arms(6 5 4 2) theta0(0 0) ///
             theta1(0.15 0.1) ctrlp(0.7 0.6) fu(0.25 1) ltfu(0.1 0.2) ///
             aratio(0.5) ppvc(0.8) ppve(0.8) 

			 
*** Examples in nstagebinopt helpfile			 
			 
nstagebinopt, nstage(3) arms(4) alpha(0.025) power(0.90) ///
                theta0(0) theta1(0.15) ctrlp(0.4) ltfu(0.1) ///
                fu(1) accrate(10 10 10) aratio(1) 
				

nstagebinopt, nstage(4) arms(6) alpha(0.05) power(0.8) ///
                theta0(0 0) theta1(0.15 0.1) ctrlp(0.7 0.6) ///
                fu(0.25) ltfu(0.1 0.2) aratio(0.5) ///
                ppv(0.8) accrate(200 200 300 600) fwer  

				
				

nstagebinopt, nstage(4) arms(6) alpha(0.05) power(0.8) ///
                theta0(0 0) theta1(0.15 0.1) ctrlp(0.7 0.6) ///
                fu(0.25) ltfu(0.1 0.2) aratio(0.5) ///
                ppv(0.8) accrate(200 200 300 600) fwer  

								