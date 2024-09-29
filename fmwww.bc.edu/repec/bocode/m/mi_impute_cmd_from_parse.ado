// parser
capture program drop mi_impute_cmd_from_parse
program mi_impute_cmd_from_parse
      version 18
      syntax anything [if]  ,  b(namelist min=1) v(namelist min=1) IModel(string)  [ * ]
	
      gettoken ivar xvars : anything
	  
	  capture confirm numeric variable `ip'
	  local eqnames: coleq `b'
	  local rownames: colfullnames `b'	  
	  global MI_IMPUTE_user_ib  `b'
	  global MI_IMPUTE_user_iV  `v'	  
	  global MI_IMPUTE_user_imodel `imodel'
	  global MI_IMPUTE_user_ipred `ip'
 
	  if "`imodel'" == "qreg" {
			    tempname sub 
				mat `sub' = $MI_IMPUTE_user_ib[1,"q50:"]
				local names: colnames `sub'
				global MI_IMPUTE_user_np : word count `names'	
				local indepv : subinstr local names "_cons" ""
				global MI_IMPUTE_user_indepv `indepv'
	  }
	   
	  if ("`imodel'" == "logit") {
				tempname sub 
				mat `sub' = $MI_IMPUTE_user_ib
				local names: colnames `sub'
				global MI_IMPUTE_user_np : word count `names'	
				local indepv : subinstr local names "_cons" ""
				global MI_IMPUTE_user_indepv `indepv'
	  }
	  
	  if ("`imodel'" == "mlogit") {

				tempname sub 
				mat `sub' = $MI_IMPUTE_user_ib
				local names: colnames `sub'
				local eqnames: coleq `sub'
				local k : colnlfs `sub'
				local k_1 = `k'-1
				local nrw: word count `names'
				local stop = 0
				local i = 1
				while `stop' != 1 {
					local pick: word `i' of `names'
					if `sub'[1, `i']==0 {
								local baseout: word `i' of `eqnames'
								local stop = 1 
					}
					local i = `i' + 1
				}
				local list_v_m ""
				forv s = 1/`nrw' {
					local pick: word `s' of `eqnames'
					if regexm("`list_v_m'", "`pick'") != 1 local list_v_m "`list_v_m' `pick'"
				}

				local no_base_list_v : subinstr local list_v_m "`baseout'" ""
				local no_base_list_v = stritrim("`no_base_list_v'")
 
				global MI_IMPUTE_mogit_lv "`list_v_m'"
				global MI_IMPUTE_mogit_lv_nb "`no_base_list_v'"
				global MI_IMPUTE_mogit_ref "`baseout'"
				global MI_IMPUTE_logit_nl = `k'

				local s = 1
				local pick: word `s' of `no_base_list_v'
				tempname pick1
				mat `pick1' = `sub'[1, "`pick':"]
				local names: colnames `pick1'
				global MI_IMPUTE_user_np : word count `names'	
				local indepv : subinstr local names "_cons" ""
				global MI_IMPUTE_user_indepv `indepv'
	  }
	 * local xvars "`indepv'"
      u_mi_impute_user_setup `if', ivars(`ivar') xvars(`xvars') `options'  title1("External imputation using `imodel'")
 end
