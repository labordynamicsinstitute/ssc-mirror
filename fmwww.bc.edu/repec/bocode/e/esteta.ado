*! esteta 1.0 5Jan2022

cap program drop esteta
program define esteta, eclass
	version 10
	syntax varlist [if], instruments(varlist fv ts) t_y(real) t_x2(real) t_x1(real) t_eta(real) [controls(varlist numeric fv ts)]

	quietly {

		cap which ivreg2
		if _rc==111 {
			di as err "Error: esteta requires ivreg2"
			di as err "To install, type " _c
			di in smcl "{stata ssc install ivreg2 :ssc install ivreg2}"
			exit 601
			}

		tokenize `varlist'
		
		if "`partial'" != "" {
			local partial = "partial(`partial')"
		}

		marksample touse
		markout `touse' `1' `2' `3' `controls' `instruments', strok
		qui count if `touse'
		local samplesize=r(N)
		
		preserve
			generate ___i=_n
			expand 2
			bysort ___i: generate ___n1 = _n-1
			generate ___n2	= 1-___n1
			
			replace `1' = `2' if ___n2

			foreach var in `instruments' {
				generate ___inst_`var'_1 = `var'*___n1
				generate ___inst_`var'_2 = `var'*___n2
			}
			if "`controls'" != "" {
				foreach var in `controls' {
					generate ___cont_`var'_1 = `var'*___n1
					generate ___cont_`var'_2 = `var'*___n2
					}
				}
			replace `2' = `2'*___n1
			replace `3' = `3'*___n2

			if "`controls'" != "" {
				ivreg2 `1' ___n1 ___cont_* (`2' `3' = ___inst_*) if `touse', cl(___i) noid partial(___cont_*)
				}
			else {
				ivreg2 `1' ___n1           (`2' `3' = ___inst_*) if `touse', cl(___i) noid
			}

			nlcom (eta`etayear': _b[`2']*_b[`3']^((`t_y'-`t_eta')/(`t_x2'-`t_x1')))
		restore
			
		cap matrix drop eta
		cap matrix drop variance

		matrix eta = r(b)'
		matrix variance = vecdiag(r(V))

		matrix b = eta[1,1]
		matrix V = variance[1,1]

		matrix colnames b = "eta`etayear'"
		matrix colnames V = "eta`etayear'"
		matrix rownames V = "eta`etayear'"

	    ereturn post b V, obs(`samplesize')
	}
    ereturn display
end