*! 1.0.2 NJC 15may2022 
*! 1.0.1 NJC 11may2022 
*! 1.0.0 NJC 31aug2015 
program logistic_scores 
	version 9 
	syntax varname(numeric) [fweight aweight] [if] [in] ///
	, GENerate(str) [SYMMetric *] 

	tokenize "`generate'" 
	if "`2'" != ""  {
		args type generate
		if !inlist("`type'", "float", "double") { 
			di as err "{p}syntax is {cmd:generate(double {it:newvar})} or " _c 
			di as err "{cmd:generate(float {it:newvar})}{p_end}" 
			exit 498
		}  
	} 
		
	confirm new var `generate' 

	quietly { 
		marksample touse
		count if `touse' 
		if r(N) == 0 error 2000 
		if r(N) == 1 error 2001 

		local y `varlist' 
		tempname vals freq scores   
		tabulate `y' if `touse' [`weight' `exp'] ///
		, matrow(`vals') matcell(`freq') 
		local I = r(r) 

		if "`symmetric'" != "" { 
			mata : symmat("`freq'") 
		} 

		gen `type' `generate' = . 
		mata: work("`freq'", "`scores'") 
		forval i = 1/`I' { 
			replace `generate' = `scores'[`i', 1] ///
			if `y' == `vals'[`i', 1] & `touse'  
		}
		count if missing(`generate') 
	} 

	if r(N) { 
		di "(`r(N)' missing " plural(`r(N)', "value") " generated)" 
	} 

	tabdisp `y' if `touse', c(`generate') `options' 
end 

mata : 

void symmat(string scalar freq) 
{ 
	real colvector P 
	P = st_matrix(freq) 
	st_matrix(freq, (P + P[rows(P)..1])/2)
} 


// NJC 16mar2007/31aug2015 
// cf. Mosteller, F. and Tukey, J.W. 1977. Data analysis and regression. 
// Reading, MA: Addison-Wesley. Chs 5F, 5H, 11F, 11G. 
void work(string scalar freq, string scalar scores)
{ 
	real colvector P, p, zero, z  
	real scalar k 

	P = st_matrix(freq) 
	k = rows(P) 
	
	for(i = 2; i <= k; i++) { 
		P[i] = P[i - 1] + P[i]     
	}

	P = P / P[k] 
	zero = J(k, 1, 0) 
	z = rowmin((zero, P :* ln(P) + (1 :- P) :* ln(1 :- P)))
	p = 0 \ P[1..k-1] 
	z = z - rowmin((zero, p :* ln(p) + (1 :- p) :* ln(1 :- p)))
	z = z :/ (P - p) 

	st_matrix(scores, z) 
}	

end

