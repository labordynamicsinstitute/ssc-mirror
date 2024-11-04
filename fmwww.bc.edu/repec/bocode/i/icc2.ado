*! Package cci2 v. 1.0
*! Support: Niels Henrik Bruun, niels.henrik.bruun@gmail.com
* 2024-10-27 > v. 1.0 Created

program define icc2, rclass
	
	version 13.1

	syntax varlist(min=2 max=3) [if] [in], /* 
		*/[ /* 
			*/Reps(numlist integer max=1 >0) /* 
			*/Seed(passthru) /* 
			*/ROweq(string) /* 
		*/]
	tokenize `varlist'
	
	if "`reps'" != "" local reps reps(`reps')
	capture confirm format `format'
	if _rc local format format(%8.3f)
	
	if "`3'" != "" {
		local icca exp(2*_b[lns2_1_1:_cons]) / (exp(2*_b[lns2_1_1:_cons]) + exp(2*_b[lns1_1_1:_cons]) + exp(2*_b[lnsig_e:_cons]))
		local iccc exp(2*_b[lns2_1_1:_cons]) / (exp(2*_b[lns2_1_1:_cons]) + exp(2*_b[lnsig_e:_cons]))
		if "`reps'`seed'" != "" {
			qui bootstrap icca=(`icca') iccc=(`iccc'), `seed'`reps' : mixed `1' `if' `in', reml ||_all: R.`3' ||`2':
			*mata: st_matrix("icc2", st_matrix("r(table)")[(1,5,6,4), .]')
			mata: r_table("icc2")
		}
		else {
			qui mixed `1' `if' `in', reml ||_all: R.`3' ||`2':
			qui nlcom ///
			( icc_i_abs: (`icca') ) ///
			( icc_i_con: (`iccc') ) ///
				, noheader post
			*mata: st_matrix("icc2", st_matrix("r(table)")[(1,5,6,4), .]')
			mata: r_table("icc2")
		}
		matrix rownames icc2 = absolute consistency
	}
	else {
		local icca exp(2*_b[lns1_1_1:_cons]) / (exp(2*_b[lns1_1_1:_cons]) + exp(2*_b[lnsig_e:_cons]))
		if "`reps'`seed'" != "" {
			qui bootstrap icca=(`icca'), `seed'`reps' : mixed `1' `if' `in', reml ||`2':
			*mata: st_matrix("icc2", st_matrix("r(table)")[(1,5,6,4), .]')
			mata: r_table("icc2")
		}
		else {
			qui mixed `1' `if' `in', reml ||`2':
			qui nlcom ///
			( icc_i_abs: `icca' ) ///
				, noheader post
			*mata: st_matrix("icc2", st_matrix("r(table)")[(1,5,6,4), .]')
			mata: r_table("icc2")
		}
		matrix rownames icc2 = absolute
	}
	matrix colnames icc2 = ICC [`c(level)'% CI] P(ICC=0)
	if "`roweq'" != "" matrix roweq icc2 = `=abbrev(`"`roweq'"', 32)'
	matlist icc2, `format'
	return matrix icc2 = icc2
end

mata:
	void r_table(string scalar mname)
	{
		real b, sd, z
		b = st_matrix("e(b)")'
		sd = sqrt(diagonal(st_matrix("e(V)")))
		z = invnormal( (100+`c(level)')/200)
		st_matrix(mname, (b, b :- z :* sd, b :+ z :* sd, (1 :- normal(b :/ sd)) :* 2)) 
	}
end
