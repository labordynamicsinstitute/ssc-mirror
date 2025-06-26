*! Date        : June 2025
*! Version     : 6.0
*! Author      : Charlie Joyez, Universite Cote d'Azur
*! Email	   : charlie.joyez@univ-cotedazur.fr

* Computes Complexity indexes. See Haussman & Hidalgo Atlas for Economic Complexity (2012)
* or simply the website https://oec.world/fr/resources/methodology/ for the methodology followed
* See Tachela et al (2012) for fitness method.


*Major changes :  v2.0 Add MR computation and fitness. Method() option is added to chose the computation technique
			   *  v2.1 Add the sign correction for Eigenvector method by correlating with MR
			   *  v3.0 method() option added, including both MR and fitness. Bug fix for small values, and iteration choice for MR method
			   *  v3.0 Returns EV Stata matrix
			   *  v3.1 In fitness method : Returns a product complexity score, reverse to the initial fitness score (cf Tachela et al (2012) : "Finally inverting the sum makes Q coherent with its positive meaning of complexity")
			   *  v4.0 allows Stata variables as inputs. Therefore removes the .dta possibility for matsource (no longer useful)
			   *  v4.0 introduces RCA option, and makes default input non RCA matrix
			   *  v5.0 introduces Relatedness and Potential options. Changes the nodes names to activities.
			   *  v5.1 generates actlist, the list of activities when proj(activities) is chosen. Only when input is Stata variables.
			   *  v6.0 Replace Relatedness and Potential by Coherence and Outlook, more aligned with the literature.
	
			 
capture program drop complexity
program complexity, rclass
	version 11
	syntax , [ VARlist(varlist) Matrix(string) MATSource(string) Projection(string) METhod(string) ITERations(string) Xvar Transpose RCA COHerence OUTlook Diversity Ubiquity target]

	*****************
*Options

*Source 
	if (mi(`"`matsource'"')) & "`varlist'"=="" & "`matrix'"=="" {
	 display as err "invalid options : varlist() or matsource() required."
	 exit 198
	}
		
	*Varlist : use varlist as specilisation inputs
	if "`varlist'"!="" {
quie describe
local k=r(k)
local N=r(N)
if `k'>`N' & `k'>400{
	capture set matsize `k'
}
if `k'<=`N' & `k'>400{
	capture set matsize `N'
}
capture matrix drop A
mkmat `varlist' ,mat(A)
mata comp_M=st_matrix("A")
preserve 
keep `varlist'
quie des
local k=r(k)
mata actlist=st_varname((1..`k'))'
restore
}

	***MATSource if not Varlist
	* mata by default
	if (mi(`"`matsource'"')) & "`varlist'"=="" & "`matrix'"!="" {
        local matsource="mata"
    }
	*If something else is type : error.
    if !inlist(`"`matsource'"', "", "mata", "dta", ".dta", "matrix") & "`varlist'"=="" {
		noi display "matsource() only accepts following arguments : {res}dta {err}(stata .dta file), {res}matrix {err}(stata matrix) or {res}mata {err}(mata matrix, default)"
        exit 198
    }	

	*Load Matrix into mata
if "`matsource'"!=""{
	if "`matsource'"!="mata"{
		if "`matsource'"=="matrix"{ /*Stata matrix*/
			 mata comp_M=st_matrix(`"`matrix'"')
		}
	}
	else{
	mata comp_M=`matrix'
	}
}


****
*Computation options

	*Projection individuals (e.g countries) / activities (e.g Products)
		if (mi(`"`projection'"')){
        local projection="indiv"
    }
	    if !inlist(`"`projection'"', "", "indiv", "activities") {
        display as err "invalid option projection(), only {res}activities {err}or  {res}indiv {txt}(default) arguments are possible"
        exit 198
    }	

	*Alternative methods (MR, eingenvector, fitness)
		if (mi(`"`method'"')){
        local method="eigenvector"
    }
	    if !inlist(`"`method'"', "", "eigenvector", "mr", "fitness") {
        display as err "invalid option {res}method() {err}, only {res}mr {err} (Method of Reflections), {res}fitness {err}  or  {res}eigenvector {txt}(default) arguments are possible"
        exit 198
    }	

	*Iterations (for MR only (and sign correction in eigenvector))
if "`method'"=="fitness"{
	if (mi(`"`iterations'"')){
	}
	else{
	noi di "note: iteration option not considered in eigenvector method."
	}
}

	if (mi(`"`iterations'"')){
        local it=20 /*default nb of iteration : 20 as recommended by Hidalgo for the Economic Complexity*/
    }
	else{
	local it=`"`iterations'"'
	}
	
	capture set obs 1
	capture drop _iterisodd_
	gen _iterisodd_=mod(`it',2)
		if _iterisodd_[1]==1{
		noi di as error "iteration should be of even order"
		exit
		}
		else{
		drop _iterisodd_
		}
*}	

	*Transpose RCA matrix if required
	if "`transpose'"!=""{
		mata comp_M=comp_M'
	}
	

**********************	
***** Core of program
**********************
*Transform specialization data in RCA if not yet.	
mata T=comp_M
mata t=(T:/rowsum(T)):/(colsum(T):/sum(T))
if "`rca'"==""{ 
mata comp_M=t
}

mata comp_M=comp_M:>1 
	
	mata comp_D=rowsum(comp_M) /*Diversification*/

	mata comp_U=rowsum(comp_M') /*ubiquity*/

if "`xvar'"==""{
	if "`diversity'"!=""{
	capt drop Diversity
	capt drop comp_D
	getmata comp_D,force
	rename comp_D Diversity
	su Diversity
	}
	if "`ubiquity'"!=""{
	capt drop Ubiquity
	capt drop comp_U
	getmata comp_U,force
	rename comp_U Ubiquity
	capt drop actlist
	capture getmata actlist, force
	su Ubiquity
    capt order actlist, before(Ubiquity)
	}
}
if "`xvar'"!=""{
noi di "note : Xvar option specified. No Stata variable created"
}
	

if "`method'"!="fitness"{

*Method of Reflection
	
	mata kc0=comp_D
	mata kp0=comp_U
	
	forvalues j=1/`it'{
	local k=`j'-1
	mata kc`j'=(comp_M*kp`k'):/kc0
	mata kp`j'=(comp_M'*kc`k'):/kp0
}
	*eci is of even order (because iteration starts from 1) and normalized as in the Atlas : 
*Stop iteration before it if ranking stops to vary
local optiter=`it'  /*optimal iteration set to max iteration initialy, changes if optimal iteration found*/
local ns=0
forvalues j=4 (2)`it'{
	local jm2=`j'-2
	local km2=`k'-2
		if "`projection'"!="activities"{
		mata st_matrix("_newiter",kc`j')
		mata st_matrix("_olditer",kc`jm2')	
		}
		if "`projection'"=="activities"{
		mata st_matrix("_newiter",kp`k')
		mata st_matrix("_olditer",kp`km2')		
		}	
	capture drop _newiter _olditer 
	capture drop _old_rank _new_rank _drank
		svmat _newiter 
		svmat _olditer
		gen _ini_rank = _n
		sort _newiter
		gen _new_rank=_n
		sort _olditer
		gen _old_rank=_n
		gen _drank=_new_rank-_old_rank
		sort _ini_rank
		qui su _drank
		local s=r(max) /*s captures max changes in rank*/
			drop _newiter _olditer 
			drop _old_rank _new_rank _drank _ini_rank
		if `s'==0 { /*rank stops to change (max delta rank=0)*/
		local ns=`ns'+1
			if `ns'==1 {
				if  "`method'"=="mr"{
					noi di "note : MR's ranking stable after `j' iteration. Iterations stopped."
				}
				local optiter=`j'
			mata mkc`optiter'=sum(kc`optiter')/rows(kc`optiter')
			mata dkc`optiter'=(kc`optiter':-mkc`optiter')
			mata sdkc`optiter'=sqrt((1/rows(kc`optiter'))*(sum(dkc`optiter':^2)))
			mata comp_i_MR=(kc`optiter' :- mkc`optiter') :/sdkc`optiter'
			mata comp_i_MR=editmissing(comp_i_MR,0)
			}
		}
		
		if `ns'==0 & `s'!=0 & `j'==`it' { 
			if"`method'"=="mr"{ /*rank still changes but max iter reached*/
				noi di "note : MR's optimal iteration is of higher order than the `it' specified" 
			}
		mata mkc`it'=sum(kc`it')/rows(kc`it')
		mata dkc`it'=(kc`it':-mkc`it')
		mata sdkc`it'=sqrt((1/rows(kc`it'))*(sum(dkc`it':^2)))
		mata comp_i_MR=(kc`it' :- mkc`it') :/sdkc`it'
		mata comp_i_MR=editmissing(comp_i_MR,0)
		}
	}
	

	*pci is of odd order and normalized as in the Atlas
		local itm1=`optiter'-1 /*takes optimal iteration level if reached, or `it' otherwise*/
		mata mkp`itm1'=sum(kp`itm1')/rows(kp`itm1')
		mata dkp`itm1'=(kp`itm1':-mkp`itm1')
		mata sdkp`itm1'=sqrt((1/rows(kp`itm1'))*(sum(dkp`itm1':^2)))
		mata comp_a_MR=(kp`itm1' :- mkp`itm1') :/sdkp`itm1'	
		mata comp_a_MR=editmissing(comp_a_MR,0)

		

*Eigenvector Method 
if "`method'"!="mr"{
	
	*Problem in mata with very small numbers, sometimes return missing eigensystem: Solved with inflate if missing values.
	*If eingensystem missing, then inflate square matrix by a fixed value. Doesn't change the selected eigenvector
			
	*Complexity of individuals		
	
		mata comp_R=(comp_M:/comp_D)*(comp_M':/comp_U) 
		mata eigensystemselecti(comp_R, (1,2), comp_X=., comp_L=.)
		mata	mis=missing(eigenvalues(comp_R))
		mata inflate=0 /*inflate matrix to avoid mata issue with eigenvalues of large matrices with low values*/
		mata if (mis>0) comp_R=comp_R:*1e+100  ; ;
		mata if (mis>0) inflate=1  ; ;
		mata eigensystemselecti(comp_R, (1,2), comp_X=., comp_L=.) 
		mata comp_K=comp_X[.,2]
		 /*Hidalgo : Eigenvector of M~cc′\tilde{M}_{c{c}'}​M​~​​​cc​′​​​​ associated with the second largest eigenvalue.*/
		mata comp_k=sum(comp_K)/rows(comp_K)
		mata comp_d=(comp_K:-comp_k):^2
		mata comp_std=sqrt((1/rows(comp_R))*sum(comp_d))
		mata Comp_i=(comp_K:-comp_k):/comp_std
		 
	mata comp_i=Re(Comp_i)
	mata st_matrix("Complexity_i", comp_i)		 


	*Complexity of activities
 
		mata comp_V=(comp_M':/comp_U)*(comp_M:/comp_D)
		mata eigensystemselecti(comp_V, (1,2), comp_X=., comp_L=.)
		mata	mis=missing(eigenvalues(comp_V))
		mata inflate_V=0
		mata		 if (mis>0) comp_V=comp_V:*1e+100 ; inflate_V=0 ;
		mata if (mis>0) inflate_V=1; ;
		mata		 eigensystemselecti(comp_V, (1,2), comp_X=., comp_L=.)
		mata comp_Q=comp_X[.,2] 
		/*Hidalgo : Eigenvector of M~cc′\tilde{M}_{c{c}'}​M​~​​​cc​′​​​​ associated with the second largest eigenvalue.*/
		mata comp_q=sum(comp_Q)/rows(comp_Q)
		mata comp_d=(comp_Q:-comp_q):^2
		mata comp_stdev=sqrt((1/rows(comp_Q))*sum(comp_d))
		mata Comp_a=(comp_Q:-comp_q):/comp_stdev
		 

	mata comp_a=Re(Comp_a)
	mata st_matrix("Complexity_a", comp_a)		 

*Correct ECI/PCI sign if required : Correlate with MR : comp_a real complexity vector
	quietly{
		mata st_matrix("comp_i_MR", comp_i_MR)
		mata st_matrix("comp_a_MR", comp_a_MR)
		 mata comp_i_MR=editmissing(comp_i_MR,0)
		 mata comp_a_MR=editmissing(comp_a_MR,0)
		count
		local n=r(N)
		svmat Complexity_i
		svmat comp_i_MR
		corr Complexity_i1 comp_i_MR1
		local r=r(rho)
		mata signcor=0
		if `r'<0 {
		mata comp_i = - comp_i
		mata st_matrix("Complexity_i", comp_i)
		mata signcor=1 
		/*stores info whether the sign has been corrected*/
		}
															
		drop Complexity_i1
		drop comp_i_MR1
		drop if _n>`n'
		
		
		count
		local n=r(N)
		quie svmat Complexity_a 
		quie svmat comp_a_MR
		corr Complexity_a1 comp_a_MR1
		local r=r(rho)
		if `r'<0 {
		mata comp_a = - comp_a
		mata st_matrix("Complexity_a", comp_a)
		}
		drop Complexity_a1 comp_a_MR1	
		capture rename Complexity_a1 Complexity_a
		drop if _n>`n'
	
}
}

	
	if "`xvar'"==""{
	
	if "`method'"!="mr"{
		if "`projection'"!="activities"{
		 quie count
		 local N=r(N)
		 mata n=rows(comp_M)
		 mata st_local("n", strofreal(n))
		 if `n'>`N'{
		 set obs `n'
		 }
		capture drop Complexity_i
		svmat Complexity_i
		capture rename Complexity_i1 Complexity_i
		}
		
	   else{
		 quie count
		 local N=r(N)
		 mata n=rows(comp_M')
		 mata st_local("n", strofreal(n))
		 
		 if `n'>`N'{
		 set obs `n'
		 }
		 capture getmata actlist, force
		
		 capture drop Complexity_a
		 svmat Complexity_a
		 capture rename Complexity_a1 Complexity_a
	   }
	}
 	if "`method'"=="mr"{ 
	mata st_matrix("comp_i_MR", comp_i_MR)
    mata st_matrix("comp_a_MR", comp_a_MR) 

		if "`projection'"!="activities"{
		 quie count
		 local N=r(N)
		 mata n=rows(comp_M)
		 mata st_local("n", strofreal(n))

		 
		 if `n'>`N'{
		 set obs `n'
		 }

		capture drop MR_Complexity_i
		svmat comp_i_MR
		capture rename comp_i_MR MR_Complexity_i

		}
		
	   else{
		 quie count
		 local N=r(N)
		 mata n=rows(comp_M')
		 mata st_local("n", strofreal(n)) 
		 
		 if `n'>`N'{
		 set obs `n'
		 }
		 capture getmata actlist, force

		 capture drop MR_Complexity_a
		 svmat comp_a_MR
		 capture rename comp_a_MR MR_Complexity_a
	   }
    }
   }
   mata Ubiquity=comp_U
   mata Diversity=comp_D
	mata st_matrix("Ubiquity", Ubiquity)
	mata st_matrix("Diversity", Diversity)

	return matrix Ubiquity=Ubiquity
	return matrix Diversity=Diversity
	if "`method'"!="mr"{
	return matrix Complexity_indiv_EV=Complexity_i
	return matrix Complexity_activity_EV=Complexity_a
	}
	if "`method'"=="mr"{
	return matrix Complexity_individualMR=comp_i_MR
	return matrix Complexity_activityMR=comp_a_MR
	}
	return scalar iterations=`it'
}	
	
		
		*Fitness
if "`method'"=="fitness"{
	mata fkc0=comp_D:/comp_D
	mata fkp0=comp_U:/comp_U
	mata fkc0=editmissing(kc0,1)
	mata fkp0=editmissing(kp0,1)
	
	forvalues j=1/`it'{
	local k=`j'-1
	mata fkc`j'=(comp_M*fkp`k')
	mata mfkc`j'=sum(fkc`j')/rows(fkc`j')
	mata fkc`j' = fkc`j':/mfkc`j'
	quie mata fkc`j'=editmissing(fkc`j',0)
	 
	mata fkp`j'=(comp_M'*(1:/fkc`k'))
	mata mfkp`j'=sum(fkp`j')/rows(fkp`j')
	mata fkp`j' = fkp`j':/mfkp`j'
	quie mata fkp`j'=editmissing(fkp`j',0)
	}
	
			*Convergence 
			
	local optiter=`it'  /*optimal iteration set to max iteration initialy, changes if optimal iteration found*/
	local ns=0
	forvalues j=1/`it'{
		local jm1=`j'-1
		if "`projection'"!="activities"{
		mata st_matrix("_newiter",fkc`j')
		mata st_matrix("_olditer",fkc`jm1')	
		}
		if "`projection'"=="activities"{
		mata st_matrix("_newiter",fkp`j')
		mata st_matrix("_olditer",fkp`jm1')		
		}
		capture drop _newiter _olditer 
		capture drop _old_rank _new_rank _drank
			svmat _newiter 
			svmat _olditer
			gen _ini_rank = _n
			sort _newiter
			gen _new_rank=_n
			sort _olditer
			gen _old_rank=_n
			gen _drank=_new_rank-_old_rank
			sort _ini_rank
			qui su _drank
			local s=r(max) /*s captures max changes in rank*/
			
				drop _newiter _olditer 
				drop _old_rank _new_rank _drank _ini_rank
			if `s'==0 { /*rank stops to change (max delta rank=0)*/
			local ns=`ns'+1
				if `ns'==1 {
						noi di "note : Fitness ranking stable after `j' iteration. Iterations stopped."
				local optiter=`j'
				mata fitness_i=fkc`optiter'
				mata fitness_a=1:/fkp`optiter'	
				mata fitness_a=editmissing(fitness_a,0)
				}
			}
				
			if `ns'==0 & `s'!=0 & `j'==`it' { /*rank still changes but max iter reached*/
					noi di "note : Fitness optimal iteration is of higher order than the `it' specified" 
				mata fitness_i=fkc`it'
				mata fitness_a=1:/fkp`it'
				mata fitness_a=editmissing(fitness_a,0)

			}
		}
	
	if "`projection'"!="activities"{
		capture drop fitness_i
		if "`xvar'"==""{
			getmata fitness_i,force
			}
		}
	else{
		capture drop fitness_a
		if "`xvar'"==""{
			getmata fitness_a,force
			capture getmata actlist, force
		    capt order actlist, before(fitness_a)
			}
		}

	mata st_matrix("fitness_i", fitness_i)	
	mata st_matrix("fitness_a", fitness_a)
	mata st_matrix("Ubiquity", fkp0)
	mata st_matrix("Diversity", fkc0)
	
	return matrix Ubiquity=Ubiquity
	return matrix Diversity=Diversity
	return matrix Fitness_individual=fitness_i
	return matrix Fitness_a=fitness_a
	return scalar iterations=`it'
}

if "`xvar'"==""{
if "`method'"=="eigenvector"{
	if "`projection'"=="indiv"{
		su Complexity_i
	}
	if "`projection'"=="activities"{
		su Complexity_a
		capt order actlist, before(Complexity_a)
	}
}
if "`method'"=="mr"{
	if "`projection'"=="indiv"{
		su MR_Complexity_i
	}
	if "`projection'"=="activities"{
		su MR_Complexity_a
		capt order actlist, before(MR_Complexity_a)
	}
}

if "`method'"=="fitness"{
	if "`projection'"=="indiv"{
		su fitness_i
	}
	if "`projection'"=="activities"{
		su fitness_a
	}		
}
}

*** Coherence
if "`coherence'"!=""{ 
	mata P1n=(comp_M'*comp_M):/comp_U /*Conditional Probability of being specialized in i knowing specoalization in j, see Hidalgo et al. 2007*/
	mata P2n=P1n' /*proba of the reverse*/
	mata Prox_a=P1n:*(P1n:<P2n)+P2n:*(P2n:<P1n)  /*minimum of the two*/
	mata Prox_a=Prox_a:-diag(Prox_a) /*remove self loops*/

	mata P1i=(comp_M*comp_M'):/comp_D 
	mata P2i=P1i' 
	mata Prox_i=P1i:*(P1i:<P2i)+P2i:*(P2i:<P1i) /*minimum of the two*/
	mata Prox_i=Prox_i:-diag(Prox_i) 


	quie mata t=editmissing(t, 0)
	
	mata  coherence_i = diagonal(t * Prox_a * t') 

	 mata coherence_a = diagonal(t' * Prox_i * t)
	 
	 	if "`projection'"=="activities"{
			capture drop coherence_a
			if "`xvar'"==""{
				getmata coherence_a, force
				quie su coherence_a
	
			}
		}
	 
		if "`projection'"=="indiv"{
			capture drop coherence_i
			if "`xvar'"==""{
				getmata coherence_i, force
				quie su coherence_i
			}
		}
	}		

	
	***COI
	if "`outlook'"!=""{
		mata P1n=(comp_M'*comp_M):/comp_U /*Conditional Probability of being specialized in i knowing specoalization in j, see Hidalgo et al. 2007*/
		mata P2n=P1n' /*proba of the reverse*/
		mata Prox_a=P1n:*(P1n:<P2n)+P2n:*(P2n:<P1n)  /*minimum of the two*/
		mata Prox_a=Prox_a:-diag(Prox_a) /*remove self loops*/
	
		mata dist=(1:-comp_M)
		mata d=(dist*Prox_a):/colsum(Prox_a)

		mata COI=((1:-d):*dist)*comp_a /*see https://atlas.hks.harvard.edu/glossary*/
		
		capt drop COI
		if "`xvar'"==""{
			getmata COI
		}
		
		mata invMcp=dist
		mata Target=(((T:/rowsum(T))*Prox_a):*invMcp):*comp_a' /*complexity of a good not yet exported weighted by its proximity to current specialization*/
		mata Target=Target:*(Target:>=0)
			if "`xvar'"=="" & "`target'"!=""{
				getmata (target*)=Target,force
			}
		}
		


	end

