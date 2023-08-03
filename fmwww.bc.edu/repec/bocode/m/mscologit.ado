*! version 1.21, 16 Jan 2023, mg

***
*** mscologit -- multi-scale ordered logit
*** ML estimation for single-level model
*** and wrapper for logit // runmlwin // meglm/melogit // gllamm for generalized and multilevel specifications
***

program define mscologit
	version 17
	syntax varlist [if], [IDvar(varlist) INDvar(varlist numeric fv ts) or vce(string) /*
		   */ lo lowcut(real .25) lowvar(varlist numeric fv ts) /*
		   */ up upcut(real .75) upvar(varlist numeric fv ts) altpar acc logit /*
	       */ mlwin level2(string) level3(string) level4(string) level5(string) MLWOPtions(string) /*
		   */ MELOGit MELOGOPtions(string) gllamm GLLAMMOPtions(string)]

	if ("`mlwin'"~="" | "`melogit'"~="" | "`gllamm'"~="") /*
	 */ & ("`level2'"=="" & "`level3'"=="" & "`level4'"=="" & "`level5'"=="") {
		di in red "Error -- requested multilevel estimation not possible:"
		di in red "please at least specify a level2 option, otherwise use single-level estimation"
		di
		exit
	}
	if ("`mlwin'"~="" & "`melogit'"~="") | ("`mlwin'"~="" & "`gllamm'"~="") /*
	 */ | ("`melogit'"~="" & "`gllamm'"~="") {
		di in red "Error -- requested multilevel estimation not possible:"
		di in red "please employ only one of the multilevel wrappers at the same time, not two or all of them"
		di
		exit
	}
	if "`altpar'"~="" & "`lo'"=="" & "`up'"=="" {
		di in red "Error -- requested mscologit estimation not possible:"
		di in red "option altpar requires either the lo or the up option to request the generalized model"
		di
		exit
	}
	*** set logit/expanded dataset estimation for generalized single-level model with lo or up option
	if "`logit'"=="" & ("`lo'"~="" | "`up'"~="") {
		local logit = "logit"
	}
	*** correct potential mistakes (gaps) in levels specification for mlwin estimation
	forval i=4 (-1) 2 {
		if "`mlwin'"~="" & "`level`i''"=="" {
				forval j=`i'/4 {
					local k = `j'+1
					local level`j' = "`level`k''"
				}
		}
	}

	*** determine no. of different scales to be handled
	tokenize `varlist'
	local i = 1
	while `i'>0 {
		if "``i''"~="" {
			local mxscale = `i'
			local i = `i'+1
		}
		else {
			local i=0
		}
	}
	noi di "dependent variable captured on `mxscale' different scales"
	preserve
	quietly {
		if "`if'"~="" {
			keep `if'
		}

		*** determine scale range
		*** dv - threshold depvar
		*** scv - scale type var, ntr - no. of thresholds in scale type (categories-1)
		tokenize `varlist'
		tempvar dv scv ntr
		gen `dv' = .
		gen `scv' = .
		gen `ntr' = .
	
		forval i=1/`mxscale' {
			tempvar scv`i'
			egen `scv`i'' = group(``i'')
			sum `scv`i''
			local mxs`i' = r(max)
			replace `scv' = `i' if ``i''<.
			replace `ntr' = `mxs`i''-1 if ``i''<.
		}
	
		*** keep only obs with valid dv information (on one scale)
		tempvar dvvalid
		egen `dvvalid' = rowmax(`scv1'-`scv`mxscale'')
		keep if `dvvalid'<.
	}
	
	*** estimation from expanded dataset
	if ("`logit'"~="" | "`mlwin'"~="" | "`melogit'"~="" | "`gllamm'"~="") {
		quietly {
			*** retain analysis variables only to speed up dataset expansion (unless fv or ts notation is used)
			local levvars = ""
			if ("`mlwin'"~="" | "`melogit'"~="") {
				forval i=5 (-1) 2 {
					if "`level`i''"~="" {
						local colpos = strpos("`level`i''", ":")-1
						local levvars = "`levvars'" + " " + substr("`level`i''", 1, `colpos')
					}
				}
			}
			if "`gllamm'"~="" {
				forval i=2/5 {
					if "`level`i''"~="" {
						local colpos = strpos("`level`i''", ":")-1
						local levvars = "`levvars'" + " " + substr("`level`i''", 1, `colpos')
					}
				}
			}
			if "`vce'"~="" {
				tokenize `vce'
				if "`1'"=="cluster" {
					local vcevar = "`2'"
				}
			}
			
			local fvars = ""
			if strpos("`indvar'", "i.")~=0 | strpos("`indvar'", "c.")~=0 /*
			*/ | strpos("`indvar'", "#")~=0 | strpos("`indvar'", "L.")~=0 {
				local fvars = "fvarnotation"
			}
			if "`fvars'"=="" {
				keep `varlist' `idvar' `indvar'	`levvars' `vcevar' `dv' `scv' `ntr' `scv1'-`scv`mxscale''
			}
		
			*** check if lo/up options compatible with scale ranges
			local lo_prob = 0
			local up_prob = 0
			local jt_prob = 0
			local gen_prob = 0
			forval i=1/`mxscale' {
				if `mxs`i''==1 {
					local gen_prob = 1
				}
				if `mxs`i''<=2 {
					local lo_prob = 1
					local up_prob = 1
				}
				if `mxs`i''<=3 {
					local jt_prob = 1
				}
			}
			if `gen_prob'==1 {
				di in red "Error -- ologit estimation not possible:"
				di in red "at least one of the dependent variables does not vary (has only 1 category)"
				di
				exit
			}
			if ("`lo'"~="" & `lo_prob'==1 & "`up'"=="") | /*
				*/ ("`up'"~="" & `up_prob'==1 & "`lo'"=="") {
				di in red "Error -- generalized ologit estimation not possible with chosen specifications:"
				di in red "at least one of the dependent variables is binary only (has only 2 categories),"
				di in red "whereas generalized estimation requires all scales to have at least 3 categories"
				di
				exit
			}
			if "`lo'"~="" & "`up'"~="" & `jt_prob'==1 {
				di in red "Error -- generalized ologit estimation not possible with chosen specifications:"
				di in red "at least one of the dependent variables has 3 categories only,"
				di in red "generalized estimation with simultaneous relaxation of the proportional odds assumption"
				di in red "at the lower and upper tail requires all scales to have at least 4 categories"
				di
				exit
			}
		
			*** expand dataset to person-threshold data structure
			*** set idvar
			if "`idvar'"~="" {
				egen _id = group(`idvar')
			}
			else {
				gen _id = _n
			}
			
			sort _id
			expand `ntr'
			
			*** threshold/cutpoint counter
			bysort _id: gen cutp = _n
			
			*** cutpoint-specific depvar
			gen cut = .
			forval i=1/`mxscale' {
				replace cut = `scv`i''>cutp if `scv'==`i' & `scv`i''<.
			}

			*** scale-specific cutpoint covariates
			local accsgn = 1
			if "`acc'"~="" {
				local accsgn = -1
			}
			
			forval i=1/`mxscale' {
				local k = `mxs`i''-1
				forval j=1/`k' {
					gen cutp_`i'_`j' = `accsgn'*(`scv'==`i' & cutp==`j')
				}
			}
			local mxsfcat = `mxs`mxscale''-1
				
			*** iweight as N of categories, correct s.e. computation in single-level logit
			tempvar iw
			gen `iw' = 1/(`ntr'+1)
		
			local lo_cov = ""
			local up_cov = ""
			if "`lo'"~="" | "`up'"~="" {
				*** determine relevant cutpoints (conditional cutpoints, from single-level model)
				logit cut `indvar' cutp_1_1-cutp_`mxscale'_`mxsfcat' [iw=`iw'], nocons
				if "`lo'"~="" {
					cap drop lowcut
					gen byte lowcut = 0
					forval i=1/`mxscale' {
						local k = `mxs`i''-1
						forval j=1/`k' {
							if `j'==1 {
								replace lowcut = 1 if cutp_`i'_`j'==`accsgn'
							}
							else {
								replace lowcut = 1 ///
									if cutp_`i'_`j'==`accsgn' & invlogit(`accsgn'*_b[cutp_`i'_`j'])>=(1-`lowcut')
							}
						}
					}
					if "`lowvar'"~="" {
						foreach i of varlist `lowvar' {
							gen lo_`i' = lowcut*`i'
							local lo_cov = "`lo_cov'" + " " + "lo_`i'"
						}
					}
					else {
						foreach i of varlist `indvar' {
							gen lo_`i' = lowcut*`i'
							local lo_cov = "`lo_cov'" + " " + "lo_`i'"
						}
					}
					noi di "Lower tail cutoff: P(Y=1|X)<=" %8.6g `lowcut'
					noi di "Cutpoints affected:"
					noi table cutp `scv', stat(mean lowcut) nototals
				}
				if "`up'"~="" {
					cap drop upcut
					gen byte upcut = 0
					forval i=1/`mxscale' {
						local k = `mxs`i''-1
						forval j=`k' (-1) 1 {
							if `j'==`k' {
								replace upcut = 1 if cutp_`i'_`j'==`accsgn'
							}
							else {
								replace upcut = 1 ///
									if cutp_`i'_`j'==`accsgn' & invlogit(`accsgn'*_b[cutp_`i'_`j'])<(1-`upcut')
							}
						}
					}
					if "`upvar'"~="" {
						foreach i of varlist `upvar' {
							gen up_`i' = upcut*`i'
							local up_cov = "`up_cov'" + " " + "up_`i'"
						}
					}
					else {
						foreach i of varlist `indvar' {
							gen up_`i' = upcut*`i'
							local up_cov = "`up_cov'" + " " + "up_`i'"
						}
					}
					noi di "Upper tail cutoff: P(Y=1|X)>" %8.6g `upcut'
					noi di "Cutpoints affected:"
					noi table cutp `scv', stat(mean upcut) nototals
				}
				if "`altpar'"~="" {
					if "`lo'"~="" {
						if "`lowvar'"~="" {
							foreach i of varlist `lowvar' {
								replace `i' = 0 if lowcut==1
							}
						}
						else {
							foreach i of varlist `indvar' {
								replace `i' = 0 if lowcut==1
							}
						}
					}
					if "`up'"~="" {
						if "`upvar'"~="" {
							foreach i of varlist `upvar' {
								replace `i' = 0 if upcut==1
							}
						}
						else {
							foreach i of varlist `indvar' {
								replace `i' = 0 if upcut==1
							}
						}
					}
				}
			}

			*** single-level estimation // logit wrapper
			*** multilevel estimation // runmlwin wrapper
			if ("`mlwin'"=="" & "`melogit'"=="" & "`gllamm'"=="") {
				noi di "mscologit single-level estimation"
				noi di
				if "`vce'"=="" {
					local vce = "cluster _id"
				}
				noi logit cut `indvar' `lo_cov' `up_cov' /*
					*/ cutp_1_1-cutp_`mxscale'_`mxsfcat' [iw=`iw'], nocons vce(`vce') `or' 
			}
			else {
				noi di "mscologit multilevel estimation"
				noi di
				sum cutp
				local mxc = r(max)
				gen double _idn = _id*(10^(int(log(`mxc'))+1)) + cutp
				local level = ""
				local storder = ""
				forval i=5 (-1) 2 {
					if "`level`i''"~="" {
						if "`lo'"~="" | "`up'"~="" {
							if "`lo'"~="" {
								local altlo = ""
							}
							if "`up'"~="" {
								local altup = ""
							}
						}
						if "`mlwin'"~="" {
							if (strpos("`level`i''", ":")+strlen(" cons"))==strlen("`level`i''") {
								local level = "`level'" + " " + "level`i'(`level`i'')"
							}
							else {
								local cmmpos = strpos("`level`i''", ",")
								if `cmmpos'==0 {
									local fstpart = strlen("`level`i''")
								}
								else {
									local fstpart = `cmmpos'-1
								}
								if "`lo'"~="" | "`up'"~="" {								
									local colpos = strpos("`level`i''", ":")+1
									local endvar = `fstpart'-`colpos'+1
									local varstr = substr("`level`i''", `colpos', `endvar')
									tokenize "`varstr'"
									local vi = 1
									while `vi'>0 {
										if ("``vi''"~="" & "``vi''"~="cons") {
											if "`lo'"~="" {
													local altlo = "`altlo'" + " " + "lo_``vi''"
											}
											if "`up'"~="" {
												local altup = "`altup'" + " " + "up_``vi''"
											}
											local vi = `vi'+1
										}
										else {
											local vi=0
										}
									}
								}
								local level = "`level'" + " " + "level`i'(" /*
								*/ + substr("`level`i''", 1, `fstpart') + "`altlo' `altup'"
								if `cmmpos'~=0 {
									local level = "`level'" + " " + substr("`level`i''", `cmmpos', .) 
								}
								local level = "`level'" + ")"
							}
						}
						if "`melogit'"~="" {
							if strpos("`level`i''", ":")==strlen("`level`i''") {
								local level = "`level'" + " " + "|| `level`i''"
							}
							else {
								local cmmpos = strpos("`level`i''", ",")
								if `cmmpos'==0 {
									local fstpart = strlen("`level`i''")
								}
								else {
									local fstpart = `cmmpos'-1
								}
								if "`lo'"~="" | "`up'"~="" {								
									local colpos = strpos("`level`i''", ":")+1
									local endvar = `fstpart'-`colpos'+1
									local varstr = substr("`level`i''", `colpos', `endvar')
									tokenize "`varstr'"
									local vi = 1
									while `vi'>0 {
										if "``vi''"~="" {
											if "`lo'"~="" {
												local altlo = "`altlo'" + " " + "lo_``vi''"
											}
											if "`up'"~="" {
												local altup = "`altup'" + " " + "up_``vi''"
											}
											local vi = `vi'+1
										}
										else {
											local vi=0
										}
									}
								}
								local level = "`level'" + " " + "|| " + substr("`level`i''", 1, `fstpart') /*
								*/ + "`altlo' `altup'"
								if `cmmpos'~=0 {
									local level = "`level'" + " " + substr("`level`i''", `cmmpos', .) 
								}
							}
						}
						local colpos = strpos("`level`i''", ":")-1
						local storder = "`storder'" + " " + substr("`level`i''", 1, `colpos')
					}
				}
				sort `storder' _id _idn
				cap drop cons
				gen byte cons = 1
				
				if "`mlwin'"~="" {
					noi runmlwin cut `indvar' `lo_cov' `up_cov' /*
					*/ cutp_1_1-cutp_`mxscale'_`mxsfcat', `level' level1(_id:, weightvar(`iw')) /*
					*/ discrete(distribution(binomial) link(logit) denominator(cons)) /*
					*/ `or' `mlwoptions' weights(nos)
				}
				if "`melogit'"~="" {
					noi meglm cut `indvar' `lo_cov' `up_cov' /*
					*/ cutp_1_1-cutp_`mxscale'_`mxsfcat' [iw=`iw'], nocons /*
					*/ `level', family(bernoulli) link(logit) diff dnumerical `or' `melogoptions'
				}
				if "`gllamm'"~="" {
					if "`or'"~="" {
						local or = "eform"
					}
					cap drop _gwt*
					gen _gwt1 = `iw'
					*** define eqs to allow random coefficients specifications
					local eqs = ""
					local eqsreq = 0
					forval i=2/5 {
						if "`level`i''"~="" {
							if strpos("`level`i''", ":")<strlen("`level`i''") {
								local varpos = strpos("`level`i''", ":")+1
								local eqvars = substr("`level`i''", `varpos', .)
								if "`lo'"~="" | "`up'"~="" {
									local cmmpos = strpos("`level`i''", ",")
									local fstpart = `cmmpos'-1
									local varstr = substr("`level`i''", `varpos', `fstpart')
									tokenize `varstr'
									local vi = 1
									while `vi'>0 {
										if "``vi''"~="" {
											if "`lo'"~="" {
												local altlo = "`altlo'" + " " + "lo_``vi''"
											}
											if "`up'"~="" {
												local altup = "`altup'" + " " + "up_``vi''"
											}
											local vi = `vi'+1
										}
										else {
											local vi=0
										}
									}
								}
								eq eq`i': `eqvars' `altlo' `altup'
								local eqsreq = 1
							}
							else {
								eq eq`i': cons
							}
							local eqs = "`eqs'" + " " + "eq`i'"
							gen _gwt`i' = 1
						}
					}
					if `eqsreq'==0 {
						local eqs = ""	
					}
					else {
						local eqs = "eqs(" + "`eqs'" +")"
					}
				
					noi gllamm cut `indvar' `lo_cov' `up_cov' /*
					*/ cutp_1_1-cutp_`mxscale'_`mxsfcat', nocons /*
					*/ i(`levvars') family(binomial) link(logit) pw(_gwt) /*
					*/ `eqs' `or' diff adapt `gllammoptions'
				}
			}
		}
	}
	else {
		*** ML estimation of single-level model
		*** define essentials in globals and newvars

		cap drop _sc*
		quietly{
			gen _sc = `scv'
			global mxscale = `mxscale'
			forval i=1/`mxscale' {
				gen _sc`i' = `scv`i''
				if `i'==1 {
					local dvl = "_sc`i'"
				}
				else {
					local dvl = "`dvl'" + " _sc`i'"
				}
				replace _sc`i' = 1 if `scv`i''==. & `scv'~=`i'
				global mxs`i' = `mxs`i''
				forval j=2/`mxs`i'' {
					local k = `j'-1
					if `i'==1 & `k'==1 {
						global cutp = "c`i'_`k'"
						local cutl = "/c`i'_`k'"
					}
					else {
						global cutp = "$cutp" + " c`i'_`k'"
						local cutl = "`cutl'" + " /c`i'_`k'"
					}
				}
			}

			*** determine starting values / null model
			tempname mdv
			forval i=1/`mxscale' {
				tab _sc`i' if _sc==`i', matcell(`mdv')
				local sdv = 0
				forval j=1/`mxs`i'' {
					local sdv = `sdv' + `mdv'[`j',1]
					matrix `mdv'[`j',1] = `sdv'
				}
				local k = `mxs`i''-1
				forval j=1/`k' {
					matrix `mdv'[`j',1] = `mdv'[`j',1]/`sdv'
					local c`i'_`j' = ln(`mdv'[`j',1]/(1-`mdv'[`j',1]))
					if `i'==1 & `j'==1 {
						local nb0 = "/:c`i'_`j'"
						local cb0 = "b0 = (`c`i'_`j''"
					}
					else {
						local nb0 = "`nb0'" + " /:c`i'_`j'"
						local cb0 = "`cb0'" + ", `c`i'_`j''"
					}
				}
			}
			local cb0 = "`cb0'" + ")"

			matrix input `cb0'
			matrix colnames b0 = `nb0'
		}

		if "`vce'"~="" {
			local vcexp = "vce(`vce')"
		}

		ml model lf mscolog_ll (`dvl' = `indvar', nocons) `cutl', /*
		 */ maximize search(off) init(b0, skip) `vcexp'
		ml display, title(Multiscale ordered logit model) `or'
	}
	restore
end
