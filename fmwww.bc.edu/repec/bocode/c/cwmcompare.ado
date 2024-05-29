*! v1 29 Nov 2023
 pro def cwmcompare, rclass sortpreserve
 syntax namelist (min=2)
 
 tempname esample esample2 table 

 local i=1
 foreach name of local namelist {
	quietly estimates restore `name'
	if (e(cmd)!="cwmglm") {
		di as error "estimation result `name' is not obtained using {bf: cwmglm}"
		exit 144
	}
	if (`i'==1) {
		gen byte `esample'=e(sample)
		local i=2
		}
		
	cap drop `esample2'
	gen byte `esample2'=e(sample)
	cap assert `esample2'==`esample'
	if _rc {
		di as error "estimation samples are not the same, please check estimation results `name'"
		exit 459
	}
	local xnormal `xnormal' `e(xnormal)'
	local xpoisson `xpoisson' `e(xpoisson)'
	local xbinomial `xbinomial' `e(xbinomial)'
	local xmultinomial_fv `xmultinomial_fv' `e(xmultinomial_fv)'
	local depvar `depvar' `e(depvar)'
	local glmfamily `glmfamily' `e(glmfamily)'
 }
  local depvar : list uniq depvar
    local glmfamily : list uniq glmfamily
  if (wordcount("`depvar'")>1 | wordcount("`glmfamily'")>1)  {
  	di as error "regression models should have the same dependent variable and the same family, please check the estimates"
	exit 459
  }
  local xnormal : list uniq xnormal
  local xbinomial : list uniq xbinomial
  local xpoisson : list uniq xpoisson
  local xmultinomial_fv : list uniq xmultinomial_fv
  local submodels xnormal xbinomial xpoisson xmultinomial_fv
   tempvar ones
   gen `ones'=1 if `esample'
 foreach name of local namelist {

	quietly estimates restore `name'
	 	local LL=e(ll)
	local DOF=e(dof)
	local diff_xnormal
	local diff_xpoisson
	local diff_xbinomial
	local diff_xmultinomial_fv
	local diff_depvar
	if ("`xnormal'"!="") {
		local cs "`e(xnormal)'"
		local diff_xnormal: list xnormal - cs
	} 
	if ("`xpoisson'"!="") {
		local cs "`e(xpoisson)'"
		local diff_xpoisson: list xpoisson - cs
	}
	if ("`xbinomial'"!="") {
		local cs "`e(xbinomial)'"
		local diff_xbinomial: list xbinomial - cs
	}
	if ("`xmultinomial_fv'"!="") {
		local cs "`e(xmultinomial_fv)'"
		local diff_xmultinomial_fv: list xmultinomial_fv - cs
	}
	if ("`depvar'"!="") {
		local cs "`e(depvar)'"
		local diff_depvar: list depvar - cs
	}
	
	if ("`diff_xnormal'`diff_xpoisson'`diff_xbinomial'`diff_xmultinomial_fv'`diff_depvar'"!="") {
	quie mata: _cwmglm_main(1,"custom",1,`e(iterate)', "`esample'" ,"`ones'","`diff_depvar'","","`glmfamily'" , "`diff_xnormal'","vvv" , "`diff_xbinomial'", "`diff_xmultinomial_fv'","`diff_xpoisson'", `e(iterate)',`e(convcrit)',"off")
	local LL=`LL'+`ll'
	local DOF=`DOF'+`dof'
		quietly estimates restore `name'
		}
	/*foreach s of local submodels {
		local cs `"e(`s')"'
		local diff: list `s' - `cs'
		di "`diff'"
		}*/
		matrix `table'=nullmat(`table')\(`LL', `DOF')
		cap drop _est_`name'
	}

	matrix rownames `table'=`namelist'
	matrix `table'=( 2*(`table'[1..rowsof(`table'),2]-`table'[1..rowsof(`table'),1]), ///
	`table'[1..rowsof(`table'),2]*ln(`e(N)')-2*`table'[1..rowsof(`table'),1] ///
	)
		matrix colnames `table'=AIC  BIC
	//	mata: colmin(st_matrix("`table'"))
	matlist `table', title("information criteria for cwmglm estimates") 

 mata _cwmglm_bestaic_bic("`table'")
 di _newline "the model with the minimum AIC is {bf: `bestAIC'}" _newline   "the model with the minimum BIC is {bf: `bestBIC'}"
return local bestAIC= "`bestAIC'"
return local bestBIC= "`bestBIC'"

  return matrix table=`table'
 end