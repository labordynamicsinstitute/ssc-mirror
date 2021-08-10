*! version 1.1.0  16/02/2015
version 11
cap program drop rctable
program define rctable
set more off
	syntax [anything]  [if] [pw aw fw], TREATment(varlist) [CONTrol(varlist fv) save(string asis) CLUSTer(varlist)  ESTimator(namelist) treated(varlist) pval keep sd]
 dis   "`subcmd'"


if "`keep'"=="" {
preserve 
quiet for any  VAR LAB  N_ind N_clust M C COEF : cap drop X 
}
foreach i in VAR LAB  N_ind N_clust M C COEF  {
	gen `i'=""
}


local j=1
	foreach i in `anything' {
	dis ""
	dis "`i'"
	dis ""
	if "`estimator'"=="" | "`estimator'"=="ITT"{
		dis "Intent-to-treat estimation"
		xi:reg  `i' `treatment'  `control' [`weight'`exp'] `if' , cluster(`cluster')  r
		local coef="`treatment'"
	}
	if "`estimator'"=="TOT" {
	dis "Treatment on the treated estimation"
		if "`treated'"=="" {
			dis as error  "treated variable is missing"
			exit 100
			}
		else {
		xi:ivregress 2sls  `i'  [`weight'`exp'] `control' (`treated'=`treatment') `if', cluster(`cluster')  r
		local coef="`treated'"
		}
	}

		quiet {
		local t:  variable label `i'
		replace VAR="`i'" if _n==`j'
		replace LAB="`t'" if _n==`j'
		
		if "`if'"=="" {
			sum `i' [`weight'`exp'] if `treatment'==0, d
			replace C=string(round(r(mean),0.001)) if _n==`j'
				if "`sd'" !="" {
				replace C=string(round(r(sd),0.001)) if _n==`j'+1
				replace C="0"+C if substr(C,1,1)=="." & _n==`j'+1
				replace C="["+C+"]" if  _n==`j'+1
				replace C="(.)" if C=="(0)" & _n==`j'+1
				}
			replace C="0"+C if substr(C,1,1)=="." & _n==`j'
			replace C=subinstr(C,"-.","-0.",.) if  _n==`j'
			sum `i' [`weight'`exp'], d
			replace M=string(round(r(mean),0.001)) if _n==`j'
				if "`sd'" !="" {
				replace M=string(round(r(sd),0.001)) if _n==`j'+1
				replace M="0"+M if substr(M,1,1)=="." & _n==`j'+1
				replace M="["+M+"]" if  _n==`j'+1
				replace M="(.)" if M=="(0)" & _n==`j'+1
				}
			replace M="0"+M if substr(M,1,1)=="." & _n==`j'
			replace M=subinstr(M,"-.","-0.",.) if  _n==`j'
			}
		else {
			sum `i' [`weight'`exp'] `if' & `treatment'==0 , d
			replace C=string(round(r(mean),0.001)) if _n==`j'
				if "`sd'" !="" {
				replace C=string(round(r(sd),0.001)) if _n==`j'+1
				replace C="0"+C if substr(C,1,1)=="." & _n==`j'+1
				replace C="["+C+"]" if  _n==`j'+1
				replace C="(.)" if COEF=="(0)" & _n==`j'+1
				}
			replace C="0"+C if substr(C,1,1)=="." & _n==`j'
			replace C=subinstr(C,"-.","-0.",.) if  _n==`j'
			sum `i' [`weight'`exp'] `if' , d
				if "`sd'" !="" {
				replace M=string(round(r(sd),0.001)) if _n==`j'+1
				replace M="0"+M if substr(M,1,1)=="." & _n==`j'+1
				replace M="["+M+"]" if  _n==`j'+1
				replace M="(.)" if M=="(0)" & _n==`j'+1
				}
			replace M=string(round(r(mean),0.001)) if _n==`j'
			replace M="0"+M if substr(M,1,1)=="." & _n==`j'
			replace M=subinstr(M,"-.","-0.",.) if  _n==`j'
		}

		replace N_ind=string(e(N)) if _n==`j'
		replace N_clust=string(e(N_clust)) if _n==`j'
		
		replace COEF=string(round(_b[`coef'],0.001)) if _n==`j'
		replace COEF="0"+COEF if substr(COEF,1,1)=="." & _n==`j'
		replace COEF=subinstr(COEF,"-.","-0.",.) if   _n==`j' 
		replace COEF=COEF+"*" if   _n==`j' & 2*ttail(e(N)-e(df_m)-1,abs(_b[`coef']/_se[`coef']))<=0.1
		replace COEF=COEF+"*" if   _n==`j' & 2*ttail(e(N)-e(df_m)-1,abs(_b[`coef']/_se[`coef']))<=0.05
		replace COEF=COEF+"*" if   _n==`j' & 2*ttail(e(N)-e(df_m)-1,abs(_b[`coef']/_se[`coef']))<=0.01
		replace COEF=string(round(_se[`coef'],0.001)) if _n==`j'+1
		replace COEF="0"+COEF if substr(COEF,1,1)=="." & _n==`j'+1
		replace COEF=subinstr(COEF,"-.","-0.",.) if  _n==`j'+1
		replace COEF="("+COEF+")" if  _n==`j'+1
		replace COEF="(.)" if COEF=="(0)" & _n==`j'+1

		if "`pval'" !="" {
			local t=_b[`coef']/_se[`coef']
			dis "`t'"
			replace COEF=string(round(2*ttail(e(N)-e(df_m)-1,abs(`t')),0.001)) if _n==`j'+2
			replace COEF="0"+ COEF if substr(COEF,1,1)=="." & _n==`j'+2
			replace COEF="["+ COEF + "]" if _n==`j'+2

			local j= `j'+3
		}
		else{
			local j= `j'+2
		}	
	
	
		if "`save'"!="" {
			dis "save"
			outsheet   VAR LAB   N_ind N_clust M C COEF    using `"`save'"', delimiter(";") replace
		}
	}
}
if "`keep'"=="" {
restore
}
end

