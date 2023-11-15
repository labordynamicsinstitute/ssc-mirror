program define xeq		// Modified version of "Xeq" from gr_example2.ado
	di as res
	di as res _asis `". `0'"'
	`0'
end

program define ivcloglog_ex
	version 8.2
	if (_caller() < 8.2)  version 8
	else                  version 8.2

	set more off
	di as text
	di as text "{bf:******************************************************************************}"
	di as text "{bf:*****************************BEGINNING OF EXAMPLE*****************************}"
	di as text "{bf:******************************************************************************}"
	di as res ". preserve"		// Cannot use -xeq- here because then -restore- will happen at the end of -xeq-
	preserve
	`0'
	di as res
	di as res ". restore"
	restore
	di as text "{bf:******************************************************************************}"
	di as text "{bf:********************************END OF EXAMPLE********************************}"
	di as text "{bf:******************************************************************************}"
end

program define ivcloglog_ex1
	xeq use "https://www.stata-press.com/data/r18/laborsup", clear
	xeq ivcloglog fem_work fem_educ kids, auxiliary(other_inc = male_educ) vhatname(vhat) vce(robust) nogenerate
end

program define ivcloglog_ex2
	xeq use "https://www.stata-press.com/data/r18/laborsup", clear
	xeq gen high_other_inc = (other_inc > 50)
	xeq ivcloglog fem_work fem_educ kids, auxiliary(other_inc = male_educ) endogenous(high_other_inc other_inc) vhatname(vhat) vce(robust) nogenerate
end

program define ivcloglog_ex3
	xeq sysuse cancer, clear
	
	xeq gen id = _n
	xeq recode drug 1=0 2=1 3=.
	xeq label values drug .
	
	xeq expand studytime
	xeq bysort id: gen time = _n
	xeq bysort id: gen event = (died & _n == _N)
	xeq gen external_instrument = drug 
	
	xeq ivcloglog event ibn.time age, auxiliary(drug = external_instrument, noconstant) vhatname(vhat) noconstant order(2) vce(cluster id) nogenerate
end
