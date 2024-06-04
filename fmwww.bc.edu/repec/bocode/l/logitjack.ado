/*-----------------------------*/
/*ADO file*/
/* logitjack  - logit jack(knife) estimation */
/* implements procedures found in this paper: */
/* logit-jack */ 
/* written by Matt Webb */
/* version 3.3 */
/* date 05/29/24 */
/*-----------------------------*/


capture program drop logitjack
program define logitjack, rclass
	syntax varlist(min = 2) , CLUSter(varname) [fevar(varlist) VARiables(real 1) BOOTstrap reps(real 999)  JACKknife  SAMple(string) NOnull ]
	
	version 13
	
	local SMPL "`sample'"
	
	/*add if to sample*/
	if "`sample'" != "" {
	    local SMPL = "if `sample'"
	}
	
	/*flag for linearized or boot*/
	local flagboot = 0
	if "`bootstrap'" != "" {
		local flagboot = 1
	}
	if "`nonull'" != "" {
		local flagboot = 1
	}
	if `reps' != 999 {
		local flagboot = 1
	}
	
	local flaglinear = 0 
	if "`linear'"!=""{
		local flaglinear = 1
	}
	local flagboth = `flagboot'+`flaglinear'
	
	mata cvstuff = J(1,6,.)
	mata linstuff = J(1,6,.)
	mata bootstuff = J(2,4,.)
	mata: bootci = J(4,4,.)
	
	/*fevar setup*/
	local FEVAR "`fevar'"
	local countfevar = 0 
	local catvars = " "
	foreach catvar in `FEVAR' {
	    local catvars = " `catvars' " +  "i.`catvar'"
	}
	
	/*sort the data by the clustering variable*/
		/*make a sequential-numeric cluster indicator*/
		
	tempvar temp_sample
	mark `temp_sample'
	markout `temp_sample' `varlist' `absorb' `cluster',strok
	
	/*impose the "sample option" restriction*/
	if "`sample'" != "" {
		
		tempvar temp_samp
		qui gen `temp_samp' = 0
		qui replace `temp_samp' = 1 `SMPL' 
		qui replace `temp_sample' = `temp_sample'*`temp_samp'
	}
	
	/*sort the data by the clustering variable*/
	*make a sequential-numeric cluster indicator*/
		
	tempvar temp_indexa	 
	qui egen `temp_indexa' = group(`cluster') if `temp_sample'==1
	qui summ `temp_indexa'
	local G = r(max)
			
	qui sort `temp_indexa'
	qui putmata CVAR=`temp_indexa' if `temp_sample'==1, replace
		
	mata: numobs = rows(CVAR)
	mata: st_numscalar("numobs", numobs)
	mata: st_local("numobs", strofreal(numobs))	
		
	mata: info = panelsetup(CVAR,1)
	mata: ng = info[.,2] - info[.,1] :+ 1
	mata: G = rows(ng)
	
	if `variables' == 1{
		local x = word("`varlist'",2)
		local y = word("`varlist'",1)
	}
	
	*to impose null
	if "`nonull'" == "" {
		local newvarlist = subinstr("`varlist'","`x'","",1)
	}

	/*when fevar specified*/
	if "`fevar'" != ""{
		
		local tempvars = " "
		local j=0
		
		local q = 0 
		
		foreach fvar in `FEVAR' {
			
			local q = `q' + 1
			
			local countfevar = `countfevar' + 1
			qui levelsof `fvar' if `temp_sample'==1, local(fevarlevel)
			
			local jstart = `j'+1
			
			foreach flevel in `fevarlevel' {
			    
				local j = `j'+1
				local tj = "t_`j'"
				
				tempvar `tj'
				qui gen ``tj'' = `fvar'==`flevel'
				
				/*create labels for these variables for regtable*/
				local name_tj = "`fvar'_`flevel'"
								
				local names_fe = "`names_fe' `name_tj'"	
			
			} /*end of flevel*/
			
					
			/*drop the last fe */
			local jend = `j'-1
			
			local fevars = "`fevars' `t_`jstart'' - `t_`jend''  "
			
		} /*end of fvar*/ 
		
		local allti = "`fevars'"
		
		qui logit `varlist' `allti',  cluster(`cluster')
		
		local beta = _b[`x']
		mata: beta = `beta'
		
		local se =  _se[`x']
		mata: cv1se = `se'
		
		local yhat = "yhat"
		tempvar yhat
		qui predict `yhat' if `temp_sample'==1
		
		qui putmata yhat = `yhat' if `temp_sample'==1, replace
				
		if "`nonull'" == ""{ 
		
			qui logit `newvarlist' `allti',  cluster(`cluster')
					
			local yhatr = "yhatr"
			tempvar yhatr
			qui predict `yhatr' if `temp_sample'==1
			
			qui putmata yhatr = `yhatr' if `temp_sample'==1, replace
			
			/*dump everything to mata*/
			qui putmata ALLR = (`newvarlist' `allti') if `temp_sample'==1, replace
			
			mata: ones = J(rows(ALLR),1,1)
			
			mata ALLR = ALLR, ones
			
			mata numall = cols(ALLR)
			mata XR = ALLR[.,2::numall]
			
		}
		
		/*dump everything to mata*/
		qui putmata ALL = (`varlist' `allti') if `temp_sample'==1, replace
		
		mata: ones = J(rows(ALL),1,1)
		
		mata ALL = ALL, ones
	
		mata numall = cols(ALL)
		mata Y = ALL[.,1]
		mata X = ALL[.,2::numall]
		
		mata: cv1se = sqrt(cv1se*cv1se* (((rows(X)-1)/(rows(X)-cols(X)))))
		
		mata: st_numscalar("cv1se", cv1se)
		mata: st_local("cv1se", strofreal(cv1se))
		
		* correct the factor from Stata's output
		mata: tcv1 = beta/cv1se
		mata: st_numscalar("tcv1", tcv1)
		mata: st_local("tcv1", strofreal(tcv1))
		
		local p1 = 2*min(ttail(`G'-1,`tcv1'), 1 -ttail(`G'-1,`tcv1'))
		
		local cv1lci = `beta' - invttail(`G'-1,0.025) * `cv1se'
		local cv1uci = `beta' + invttail(`G'-1,0.025) * `cv1se'
		
		mata: cvstuff[1,1] = `beta'
		mata: cvstuff[1,2] = `cv1se'
		mata: cvstuff[1,3] = `tcv1'
		mata: cvstuff[1,4] = `p1'
		mata: cvstuff[1,5] = `cv1lci'
		mata: cvstuff[1,6] = `cv1uci'
		
	
		/*brute force jackknife*/

		if "`jackknife'" != "" {
			
			mata: betas= J(`G',1,.)

			forvalues g = 1 / `G' {
				
				 qui logit `varlist' `allti' if `temp_indexa'!=`g',  cluster(`cluster')
				 local betas = _b[`x']
				 mata: betas[`g',1]= `betas'
				 
			} /*end of j*/
			
			mata: cv3diff = betas:-beta
			mata: cv3diffsqsum = (`G'-1)/(`G')* sum(cv3diff:*cv3diff)
			mata: cv3se= sqrt(cv3diffsqsum)
			mata: st_numscalar("cv3se", cv3se)
			mata: st_local("cv3se", strofreal(cv3se))
						
			local tcv3 = `beta'/`cv3se'
			mata: tcv3 = beta/cv1se
		
			local p3 = 2*min(ttail(`G'-1,`tcv3'), 1 -ttail(`G'-1,`tcv3'))
	
			local cv3lci = `beta' - invttail(`G'-1,0.025) * `cv3se'
			local cv3uci = `beta' + invttail(`G'-1,0.025) * `cv3se'	
			
			mata: cvstuffjack = J(1,6,.)
			mata: cvstuffjack[1,1] = `beta'
			mata: cvstuffjack[1,2] = `cv3se'
			mata: cvstuffjack[1,3] = `tcv3'
			mata: cvstuffjack[1,4] = `p3'
			mata: cvstuffjack[1,5] = `cv3lci'
			mata: cvstuffjack[1,6] = `cv3uci'
		
		} /* end of jackknife if */ 
		
	}/*end of fevar*/
	
	/*when absorb not specified*/
	if "`fevar'" == ""{
	
		*estimate logit 
		qui logit `varlist', cluster(`cluster')
		
		local beta = _b[`x']
		mata: beta = `beta'
		
		local se =  _se[`x']
		
		local yhat = "yhat"
		tempvar yhat
		qui predict `yhat' if `temp_sample'==1
		
		qui putmata yhat = `yhat' if `temp_sample'==1, replace

		/*dump everything to mata*/
		qui putmata ALL = (`varlist') if `temp_sample'==1, replace
		
		*add a constant to X
		qui mata: ones = J(rows(ALL),1,1)
		
		mata numall = cols(ALL)
		mata Y = ALL[.,1]
		mata X = (ALL[.,2::numall], ones)
		
		mata: cv1se = `se'
		mata: cv1se = sqrt(cv1se*cv1se* (((rows(X)-1)/(rows(X)-cols(X)))))
		
		mata: st_numscalar("cv1se", cv1se)
		mata: st_local("cv1se", strofreal(cv1se))
		
		* correct the factor from Stata's output
		mata: tcv1 = beta/cv1se
		mata: st_numscalar("tcv1", tcv1)
		mata: st_local("tcv1", strofreal(tcv1))		
		
		local p1 = 2*min(ttail(`G'-1,`tcv1'), 1 -ttail(`G'-1,`tcv1'))
	
		local cv1lci = `beta' - invttail(`G'-1,0.025) * `cv1se'
		local cv1uci = `beta' + invttail(`G'-1,0.025) * `cv1se'
		
		mata: cvstuff[1,1] = `beta'
		mata: cvstuff[1,2] = `cv1se'
		mata: cvstuff[1,3] = `tcv1'
		mata: cvstuff[1,4] = `p1'
		mata: cvstuff[1,5] = `cv1lci'
		mata: cvstuff[1,6] = `cv1uci'
				
		
		if "`nonull'" == "" {
			*estimate logit 
			qui logit `newvarlist', cluster(`cluster')
			
			local yhatr = "yhatr"
			tempvar yhatr
			qui predict `yhatr' if `temp_sample'==1
			
			qui putmata yhatr = `yhatr' if `temp_sample'==1, replace

			/*dump everything to mata*/
			qui putmata ALLR = (`newvarlist') if `temp_sample'==1, replace
			
			*add a constant to X
			qui mata: ones = J(rows(ALLR),1,1)
			
			mata numall = cols(ALLR)
			mata XR = (ALLR[.,2::numall], ones)
			
		} /*end of nonull */
		
		if "`jackknife'" != ""  {
			
			*bruteforce jackknife
			mata: betas= J(`G',1,.)

			forvalues g = 1 / `G' {
				 
				 qui logit `varlist' if `temp_indexa'!=`g',  cluster(`cluster')
				 local betas = _b[`x']
				 mata: betas[`g',1]= `betas'
				 
			} /*end of g*/
			
			mata: cv3diff = betas:-beta
			mata: cv3diffsqsum = (`G'-1)/(`G')* sum(cv3diff:*cv3diff)
			mata: cv3se= sqrt(cv3diffsqsum)
			mata: st_numscalar("cv3se", cv3se)
			mata: st_local("cv3se", strofreal(cv3se))
						
			local tcv3 = `beta'/`cv3se'
			mata: tcv3 = beta/cv1se
		
			local p3 = 2*min(ttail(`G'-1,`tcv3'), 1 -ttail(`G'-1,`tcv3'))
	
			local cv3lci = `beta' - invttail(`G'-1,0.025) * `cv3se'
			local cv3uci = `beta' + invttail(`G'-1,0.025) * `cv3se'
			
			mata: cvstuffjack = J(1,6,.)
			mata: cvstuffjack[1,1] = `beta'
			mata: cvstuffjack[1,2] = `cv3se'
			mata: cvstuffjack[1,3] = `tcv3'
			mata: cvstuffjack[1,4] = `p3'
			mata: cvstuffjack[1,5] = `cv3lci'
			mata: cvstuffjack[1,6] = `cv3uci'
		
		} /* end of jackknife if */ 

	} /*end of no-fevar*/
		
		mata: scores = (Y :- yhat):*X
		mata: score_g =  panelsum(scores, info)
		
		if "`nonull'" == "" {
			
			mata: scoresr = (Y :- yhatr):*XR
			mata: score_rg =  panelsum(scoresr, info)
			mata: scoresr2 = (Y :- yhatr):*X
			mata: score_r2g =  panelsum(scoresr2, info)
		}

		forvalues g = 1 / `G' {
			
			mata: firstrow = info[`g',1]
			mata: st_numscalar("firstrow", firstrow)
			mata: st_local("firstrow", strofreal(firstrow))
			mata: lastrow = info[`g',2]
			mata: st_numscalar("lastrow", lastrow)
			mata: st_local("lastrow", strofreal(lastrow))
			
			local f = `firstrow'
			mata: infomat_g`g' = yhat[`f',1]*(1 - yhat[`f',1]):*X[`f',.]'X[`f',.]
			
			if "`nonull'" == "" {
				mata: infomat_rg`g' = yhatr[`f',1]*(1 - yhatr[`f',1]):*XR[`f',.]'XR[`f',.]
				
				mata: infomat_r2g`g' = yhatr[`f',1]*(1 - yhatr[`f',1]):*X[`f',.]'X[`f',.]
			}
			
			local next = `firstrow'+1
			forvalues i = `next'/`lastrow'{
				
				mata: infomat_g`g' = infomat_g`g' + yhat[`i',1]*(1 - yhat[`i',1]):*X[`i',.]'X[`i',.]
				
				if "`nonull'" == "" {
				
					mata: infomat_rg`g' = infomat_rg`g' + yhatr[`i',1]*(1 - yhatr[`i',1]):*XR[`i',.]'XR[`i',.]
				
					mata: infomat_r2g`g' = infomat_r2g`g' + yhatr[`i',1]*(1 - yhatr[`i',1]):*X[`i',.]'X[`i',.]
					
				}
				
			} /*end of i*/
			
		}/*end of g*/
		
		mata: score_all = colsum(score_g)
		mata: infomat_all = infomat_g1
		
		forvalues g = 2/`G'{
			mata: infomat_all = infomat_all + infomat_g`g'
		}
		
		mata: invinfomat_all = invsym(infomat_all)

		mata: linbeta = invinfomat_all*score_all'
		mata: linbetax = linbeta[1,1]
		
		mata: st_numscalar("linbetax", linbetax)
		mata: st_local("linbetax", strofreal(linbetax))	
		
		*if "`nonull'" != ""{ 
			mata: score_us = J(`G',cols(X),.)
		*}
		if "`nonull'" == ""{ 
			mata: score_rall = colsum(score_rg)
			mata: score_r2all = colsum(score_r2g)

			mata: infomat_rall = infomat_rg1
			mata: infomat_r2all = infomat_r2g1

			forvalues g = 2/`G'{
				mata: infomat_rall = infomat_rall + infomat_rg`g'
				mata: infomat_r2all = infomat_r2all + infomat_r2g`g'
			}
			
			mata: invinfomat_rall = invsym(infomat_rall)
			mata: invinfomat_r2all = invsym(infomat_r2all)

			mata: nm1 =cols(infomat_all)
			mata: st_numscalar("nm1", nm1)
			mata: st_local("nm1", strofreal(nm1))	
			
			mata: linbetar = invinfomat_rall*score_rall'
		
			mata: score_rs = J(`G',cols(X)-1,.)
			mata: score_r2s = J(`G',cols(X),.)
		
		} /*end of nonull*/
		
		/*-----------------------*/
		/*cv3l*/
		/*-----------------------*/
		
		mata: cv3lsum = J(rows(linbeta),rows(linbeta),0)
		
		mata: betaog = J(`G',1,.)
		
		forvalues g = 1 / `G' {
			
			*unrestricted
			mata: beta_o`g' = invsym(infomat_all - infomat_g`g')*(score_all'-score_g[`g',.]')
			
			mata: cv3lsum = cv3lsum + (beta_o`g':-linbeta)*(beta_o`g'':-linbeta')
			
			*transform the scores
				
				*unrestricted - equation 33
				
				mata: score_us[`g',.] = score_g[`g',.] - (infomat_g`g'* beta_o`g')' 
			
			if "`nonull'" == ""{ 
				
				*restricted  - equation 34
				mata: beta_ro`g' = invsym(infomat_rall - infomat_rg`g')*(score_rall'-score_rg[`g',.]')
				mata: score_rs[`g',.] = score_rg[`g',.] - (infomat_rg`g'* beta_ro`g')'
				
				mata: score_r2s[`g',.] = score_r2g[`g',.] - (infomat_r2g`g'[.,2::cols(infomat_r2g`g')]* beta_ro`g')' 
				
			}
			
			mata: betaog[`g',1] = 	beta_o`g'[1,1]
			
		} /*end of g*/
		
		mata: cv3l = ((`G'-1)/`G'):*cv3lsum
		
		mata: cv3lse = sqrt(cv3l[1,1])
		mata: st_numscalar("cv3lse", cv3lse)
		mata: st_local("cv3lse", strofreal(cv3lse))	
		
		mata: tcv3l = `beta' / cv3lse
		
		mata: st_numscalar("tcv3l", tcv3l)
		mata: st_local("tcv3l", strofreal(tcv3l))	
							
		local p3l = 2*min(ttail(`G'-1,`tcv3l'), 1 -ttail(`G'-1,`tcv3l'))
		
		local cv3llci = `beta' - invttail(`G'-1,0.025) * `cv3lse'
		local cv3luci = `beta' + invttail(`G'-1,0.025) * `cv3lse'
	
		mata: linstuff[1,1] = `beta'
		mata: linstuff[1,2] = cv3lse
		mata: linstuff[1,3] = tcv3l
		mata: linstuff[1,4] = `p3l'
		mata: linstuff[1,5] = `cv3llci'
		mata: linstuff[1,6] = `cv3luci'
		
		/*summary statistics*/
		
		if "`jackknife'" == "" {
			local SUMVAR "ng betalg "
			
			mata: clustsum= J(7,2,.)
		}
		
		if "`jackknife'" != "" {
			local SUMVAR "ng betalg betas"
			
			mata: clustsum= J(7,3,.)
		}
		
		local s = 0
		
		mata: betalg = betaog:+beta
		
		foreach svar in `SUMVAR' {
			
			  local s = `s' + 1
			  
			  local tempsvar = "temp_`svar'"
			  
			  tempvar `tempsvar'
		
			  qui getmata ``tempsvar'' = `svar', force
			  
			  qui summ ``tempsvar'', det
			  			  
			  /*min*/ 
				local min = r(min)
				mata: clustsum[1,`s'] = `min'
			 
			  /*q1*/
				local q1 = r(p25)
				mata: clustsum[2,`s'] = `q1'
			  
			  /*median*/
				local median = r(p50)
				mata: clustsum[3,`s'] = `median'
			 
			  /*mean*/
				local mean = r(mean)
				mata: clustsum[4,`s'] = `mean'
				
				local graph_`s' = `mean'
			 
			   /*q3*/
				local q1 = r(p75)
				mata: clustsum[5,`s'] = `q1'

			  /*max*/ 
				local max = r(max)
				mata: clustsum[6,`s'] = `max'
			  
			  /*coeff of variation*/
			  
				  mata: meandiff = `svar' :- `mean'
				  mata: meandiff2 = meandiff:*meandiff
				  mata: meandiffsum = colsum(meandiff2)
				  mata: denom= 1/((`G'-1)*(`mean'^2))
				  mata: scalvar = denom*meandiffsum
				  mata: scalvar = sqrt(abs(scalvar))
				  
				  mata: clustsum[7,`s'] = scalvar
				  
				
		  } /*end of svars if*/
		  
		 	mata: st_matrix("clustsum", clustsum)
			matrix rownames clustsum = min q1 median mean q3 max coefvar	
			
			if "`jackknife'" == "" {
				matrix colnames clustsum = Ng "Lin beta no g" 
			}
			else {
				
				matrix colnames clustsum = Ng "Lin beta no g" "beta no g" 
			}
			
			
	
	*} /*end of flag*/
	
	/*----------------*/
	/* bootstrap */ 
	/*----------------*/
	
	if `flagboot' == 1 {
		
		mata: w_sum = J(cols(score_g),cols(score_g),0)
		
		forvalues g = 1 / `G'{
			mata: w_g = score_g[`g',.]' - infomat_g`g' * linbeta
			mata: w_sum = w_sum + w_g*w_g'
		}
			
		*variance
		mata: var_cv1 = ((`G')/(`G'-1)):* invinfomat_all * w_sum * invinfomat_all
		
		mata: t = linbeta[1,1]/sqrt(var_cv1[1,1])
		
		mata: tboots = J(`reps',1,.)
		mata: tbootss = J(`reps',1,.)
		mata: betabootc = J(`reps',1,.)
		mata: betaboots = J(`reps',1,.)
		
		mata: tbootnewc = J(`reps',1,.)
		mata: tbootnews = J(`reps',1,.)
		
		
		forvalues b = 1 / `reps' {
			
			*switch to six-point if G is less than 12

			if `G' > 12 {
				
				*draw a G-vector of rademacher weights
				mata  e = runiform(`G',1)

				mata v = 2:* (e :> 0.5) :- 1
				
				local BOOTSTRING "P-values calculated with `reps' replications and Rademacher weights."
			}
			if `G' <= 12 {
				
				*draw a G-vector of six point weights
				mata  e = runiform(`G',1)
				mata: st_matrix("e", e)
				
				matrix vh = J(`G',1,.)
				
				forvalues h = 1 / `G' {
					
					if inrange(e[`h',1],0/6,6/6) {	
						matrix vh[`h',1] = -sqrt(3/2)
					}
					if inrange( e[`h',1],1/6,2/6){ 
						matrix vh[`h',1] = -sqrt(2/2)
					}
					if inrange( e[`h',1],2/6,3/6) {
						matrix vh[`h',1] = -sqrt(1/2)
					}
					if inrange( e[`h',1],3/6,4/6) {
						matrix vh[`h',1] =  sqrt(1/2)
					}
					if inrange( e[`h',1],4/6,5/6) {
						matrix vh[`h',1] =  sqrt(2/2)
					}
					if inrange( e[`h',1],5/6,6/6) {
						matrix vh[`h',1] =  sqrt(3/2)
					}
					
				}
				mata v = st_matrix("vh")
				
				local BOOTSTRING "P-values calculated with `reps' replications and Webb weights."

				
			} /*end of six point*/
						
			/*unrestricted*/
			if "`nonull'" != "" {
				
				******************************
				/*classic - C*/
				
				*transform the scores, then sum them			
				mata: sum_score_b = colsum(v:*score_g)
				
				*bootstrap beta
				mata beta_boot = invinfomat_all * sum_score_b'
				mata: betabootc[`b',1] = beta_boot[1,1]
				
				*bootstrap empirical scores
				mata: w_sum = J(cols(score_g),cols(score_g),0)
				forvalues g = 1 / `G'{
					mata: w_g = v[`g',1]:*score_g[`g',.]' - infomat_g`g' * beta_boot
					mata: w_sum = w_sum + w_g*w_g'
				}
				
				*bootstrap variance			
				 mata: var_boot = ((`G')/(`G'-1))*((rows(X)-1)/(rows(X)-cols(X))):* invinfomat_all * w_sum * invinfomat_all
				
				*bootstrap t 
				mata: tboots[`b',.] = beta_boot[1,1]/sqrt(var_boot[1,1])
				
				********************
				/*scores - S*/
				*transform the scores, then sum them			
				mata: sum_score_sb = colsum(v:*score_us)
				
				*bootstrap beta
				mata beta_boot = invinfomat_all * sum_score_sb'
				mata: betaboots[`b',1] = beta_boot[1,1]
				
				*bootstrap empirical scores
				mata: w_sum = J(cols(score_g),cols(score_g),0)
				forvalues g = 1 / `G'{
					mata: w_g = v[`g',1]:*score_us[`g',.]' - infomat_g`g' * beta_boot
					mata: w_sum = w_sum + w_g*w_g'
				}
				
				*bootstrap variance
				 mata: var_boot = ((`G')/(`G'-1))*((rows(X)-1)/(rows(X)-cols(X))):* invinfomat_all * w_sum * invinfomat_all
				
				*bootstrap t 
				mata: tbootss[`b',.] = beta_boot[1,1]/sqrt(var_boot[1,1])
					
			} /* end of unrestricted */
			
			********************
			/*restricted*/
			if "`nonull'" == "" {
							
				/*classic - C*/
				*transform the scores, then sum them			
				mata: sum_score_b = colsum(v:*score_r2g)
				
				*bootstrap beta
				mata beta_boot = invinfomat_r2all * sum_score_b'
				
				*beta - for variance 			
					mata: sum_score_b = colsum(v:*score_r2g)
					mata beta_boot_var = invinfomat_r2all * sum_score_b'
				
				*bootstrap empirical scores
				mata: w_sum = J(cols(score_r2g),cols(score_r2g),0)
				forvalues g = 1 / `G'{
					mata: w_g = v[`g',1]:*score_r2g[`g',.]' - infomat_r2g`g' * beta_boot_var
					mata: w_sum = w_sum + w_g*w_g'
				}
				
				*bootstrap variance
				 mata: var_boot = ((`G')/(`G'-1))*((rows(X)-1)/(rows(X)-cols(X))):* invinfomat_r2all * w_sum * invinfomat_r2all
				
				*bootstrap t 
				mata: tbootnewc[`b',.] = beta_boot[1,1]/sqrt(var_boot[1,1])
				
				************************
				/*score - S*/
				*transform the scores, then sum them			
				mata: sum_score_sb = colsum(v:*score_r2s)
				
				*bootstrap beta
				mata beta_boot = invinfomat_r2all * sum_score_sb'
				
				*beta for variance
					mata: sum_score_sb = colsum(v:*score_r2s)
					mata beta_boot_var = invinfomat_r2all * sum_score_sb'
				
				*bootstrap empirical scores
				mata: w_sum = J(cols(score_r2g),cols(score_r2g),0)
				forvalues g = 1 / `G'{
					mata: w_g = v[`g',1]:*score_r2s[`g',.]' - infomat_r2g`g' * beta_boot_var
					mata: w_sum = w_sum + w_g*w_g'
				}
				
				*bootstrap variance
				 *mata: var_boot = ((`G'-1)):* invinfomat_rall * w_sum * invinfomat_rall
				 mata: var_boot = ((`G')/(`G'-1))*((rows(X)-1)/(rows(X)-cols(X))):* invinfomat_r2all * w_sum * invinfomat_r2all
				 
				*bootstrap t 
				mata: tbootnews[`b',.] = beta_boot[1,1]/sqrt(var_boot[1,1])
				
			
			} /* end of restricted */
	
		} /*end of bootstrap*/
		
		*bootstrap p
			
		*classic
		mata: bootc_p = mean(abs(tcv1[1,1]):<abs(tboots))
		
		mata: st_numscalar("bootc_p", bootc_p)
		mata: st_local("bootc_p", strofreal(bootc_p))
				
		*scores
		mata: boots_p = mean(abs(tcv1[1,1]):<abs(tbootss))
		
		mata: st_numscalar("boots_p", boots_p)
		mata: st_local("boots_p", strofreal(boots_p))
		
		*new
		mata: bootnews_p = mean(abs(tcv1[1,1]):<abs(tbootnews))
		mata: bootnewc_p = mean(abs(tcv1[1,1]):<abs(tbootnewc))
				
		mata: bootstuff[1,1] = `beta'
		mata: bootstuff[1,2] = `cv1se'
		mata: bootstuff[1,3] = `tcv1'
		
		mata: bootstuff[2,1] = `beta'
		mata: bootstuff[2,2] = `cv1se'
		mata: bootstuff[2,3] = `tcv1'
		
		if  "`nonull'" != "" {
			mata: bootstuff[1,4] = bootc_p
			mata: bootstuff[2,4] = boots_p  
		}
		
		if  "`nonull'" == "" {
			mata: bootstuff[1,4] = bootnewc_p  
			mata: bootstuff[2,4] = bootnews_p
		}
		

		/*calculate bootstrap confidence intervals*/
		if "`nonull'" != "" {
			
			*bootstrap quantiles
			mata: qlower = ceil(0.025*rows(tboots))
			mata: qupper = ceil(0.975*rows(tboots))
			
			mata: sortc = sort(tboots,1)
			mata: sorts = sort(tbootss,1)
			
			mata: tlowerc = sortc[qlower,1]
			mata: tupperc = sortc[qupper,1]
			
			mata: tlowers = sorts[qlower,1]
			mata: tuppers = sorts[qupper,1]
			
			
			mata: cilowc = `beta' - abs(tlowerc)*`cv1se'
			mata: ciupc = `beta' + abs(tupperc)*`cv1se'
						
			mata: cilows = `beta' - abs(tlowers)*`cv1se'
			mata: ciups = `beta' + abs(tuppers)*`cv1se'
			
			
			*second sets of CIs
			mata: bootsec = sqrt(1/(rows(betabootc)-1)*sum((betabootc:-mean(betabootc)):*(betabootc:-mean(betabootc))))
			
			mata: bootses = sqrt(1/(rows(betaboots)-1)*sum((betaboots:-mean(betaboots)):*(betaboots:-mean(betaboots))))
			
			local critval = invttail(`G'-1,0.025)
			
			mata: cilowbootc = `beta' - `critval'*bootsec
			mata: ciupbootc = `beta' + `critval'*bootsec
						
			mata: cilowboots = `beta' - `critval'*bootses
			mata: ciupboots = `beta' + `critval'*bootses
						
			*"CLASSIC-CV1-se"
			mata: bootci[1,1] = `beta'
			
			mata: bootci[1,2] = `cv1se'
			
			mata: bootci[1,3] = cilowc
			
			mata: bootci[1,4] = ciupc
			
			*"CLASSIC-boot-se"
			mata: bootci[2,1] = `beta'
			
			mata: bootci[2,2] = bootsec
			
			mata: bootci[2,3] = cilowbootc
			
			mata: bootci[2,4] = ciupbootc
			
			*"SCORE-CV1-se"
			mata: bootci[3,1] = `beta'
			
			mata: bootci[3,2] =  `cv1se'
			
			mata: bootci[3,3] = cilows
			
			mata: bootci[3,4] = ciups
			
			*"SCORE-boot-se"
			mata: bootci[4,1] = `beta'
			
			mata: bootci[4,2] = bootses 
			
			mata: bootci[4,3] = cilowboots
			
			mata: bootci[4,4] = ciupboots
			
		}
		
		
	} /*end of boots if*/
	
	
	/*output display*/
		disp ""
		disp ""
		disp "LOGITJACK - MacKinnon, Nielsen, and Webb"
		disp " "
		disp "Jackknife cluster statistics for binary response models."
		disp "Estimates for `x' when clustered by `cluster'."
		disp "There are `numobs' observations within `G' `cluster' clusters."
	
	if "`jackknife'"!="" {
		
		mata: cvtable  = cvstuff \ cvstuffjack \ linstuff
	
		
		mata: st_matrix("cvtable",cvtable)
		matrix rownames cvtable = CV1 CV3 CV3L
		local RSPECCV "&|&&|"
			
		matrix colnames cvtable = "Coeff" "Sd. Err." "t-stat" "P value" CI-lower CI-upper
			
		matlist cvtable, title(Logistic Regression Output) rowtitle(s.e.) ///
			cspec(& %-4s w6 | %9.6f w10 & %9.6f & %6.4f w7 & %6.4f w7 & %9.6f w10 & %9.6f w10 &) ///
			rspec("`RSPECCV'")
	}
	
		if "`jackknife'"=="" {
		
		mata: cvtable  = cvstuff \ linstuff
	
		
		mata: st_matrix("cvtable",cvtable)
		matrix rownames cvtable = CV1  CV3L
		local RSPECCV "&|&|"
			
		matrix colnames cvtable = "Coeff" "Sd. Err." "t-stat" "P value" CI-lower CI-upper
			
		matlist cvtable, title(Logistic Regression Output) rowtitle(s.e.) ///
			cspec(& %-4s w6 | %9.6f w10 & %9.6f & %6.4f w7 & %6.4f w7 & %9.6f w10 & %9.6f w10 &) ///
			rspec("`RSPECCV'")
	}
	
		/*summary statistic output*/
		if "`jackknife'"=="" {  
			
			matlist clustsum , title("Cluster Variability") rowtitle(Statistic) ///
			cspec(& %-10s | %8.2f o2 & %9.6f  w14 & ) ///
			rspec(&-&&&&&-&)
		}
		else  {
			matlist clustsum , title("Cluster Variability") rowtitle(Statistic) ///
			cspec(& %-10s | %8.2f o4 & %9.6f  w14 & %9.6f  w10 &) ///
			rspec(&-&&&&&-&)
		}
		
	
	
	if `flagboot'== 1{
		
		if "`nonull'" == "" {
			local BOOTTITLE "Restricted Bootstrapped Linearized Regression Output"
			local BOOTROW "WCLR"
		}
		
		if "`nonull'" != ""{
			local BOOTTITLE "Unrestricted Bootstrapped Linearized Regression Output"
			local BOOTROW "WCLU"
		}
		
		mata: st_matrix("bootstuff",bootstuff)
		
		matrix rownames bootstuff = CLASSIC SCORE
		local RSPECBOOT "&|&|"

		matrix colnames bootstuff = "Coeff" "Sd. Err." "t-stat" "P value"
			
		matlist bootstuff, title(`BOOTTITLE') rowtitle(`BOOTROW') ///
			cspec(& %-10s w6 | %9.6f w10 & %9.6f & %6.4f w7 & %6.4f w7 &) ///
			rspec("`RSPECBOOT'")
			disp "`BOOTSTRING'"
		
		
		
		if "`nonull'" != ""{
			
			/* bootstrap confidence intervals  */
			
			mata: st_matrix("bootci",bootci)
		
			matrix rownames bootci = "CLASSIC-CV1-se" "CLASSIC-WB-se" "SCORE-CV1-se" "SCORE-WB-se"
			local RSPECBOOT "&|&|&|"

			matrix colnames bootci = "Coeff" "std.er." "WCLU CI-low" "WCLU CI-up"
			
			local BOOTCITITLE "Unrestricted Bootstrapped Confidence Intervals"

				
			matlist bootci, title(`BOOTCITITLE') rowtitle(`BOOTROW') ///
				cspec(& %-14s w14 | %9.6f w10 & %9.6f & %6.4f w15 & %6.4f w15 &) ///
				rspec("`RSPECBOOT'")
				
		} /*end of no null*/
		
	} /*end of flag boot*/
		
end

/*----------------------------------------*/
/*version history*/
*v1 - absorb cv3
*v1.1 - bootstraps
*v1.2 - nonull
*v1.3 - cleaned up display output
*v2 - confidence intervals
*v2.1 - correct absorb error
*v2.2 - added six point, changed var-factor issue
*v3 - corrected WCLR and more CIs
*v3.1 - changes to output and CI formula
*v3.2 - minor bug fixes
*v3.3 - added summary statistics
