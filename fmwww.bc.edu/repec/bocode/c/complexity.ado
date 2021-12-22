*! Date        : 23 june 2021
*! Version     : 4.0
*! Author      : Charlie Joyez, Universite Cote d'Azur
*! Email	   : charlie.joyez@univ-cotedazur.fr

* Computes Complexity indexes. See Haussman & Hidalgo Atlas for Economic Complexity (2012)
* or simply the website https://oec.world/fr/resources/methodology/ for the methodology followed
* See Tachela et al (2012) for fitness method.


*Major changes :  v2.0 Add MR computation and fitness one. Method() option is added to chose the computation technique
			   *  v2.1 Add the sign correction for Eigenvector method by correlating with MR
			   *  v3.0 method() option added, including both MR and fitness. Bug fix for small values, and iteration choice for MR method
			   *  v3.0 Returns EV Stata matrix
			   *  v3.1 In fitness method : Returns a product complexity score, reverse to the initial fitness score (cf Tachela et al (2012) : "Finally inverting the sum makes Q coherent with its positive meaning of complexity")
			   *  v4.0 allows Stata variables as inputs. Therefore removes the .dta possibility for matsource (no longer useful)
			   *  v4.0 introduces RCA option, and makes default input non RCA matrix
	
			 
capture program drop complexity
program complexity, rclass
	version 9
	syntax , [ VARlist(varlist) Matrix(string) MATSource(string) Projection(string) METhod(string) ITERations(string) Xvar Transpose RCA]

	*****************
*Options

*Source 
	if (mi(`"`matsource'"')) & "`varlist'"=="" & "`matrix'"=="" {
	 display as err "invalid options : varlist() or matsource() required."
	 exit 198
	}
	
	*Varlist : use varlist as specilisation inputs
	if "`varlist'"!="" {
capture matrix drop A
mkmat `varlist' ,mat(A)
mata comp_M=st_matrix("A")
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
		/*
		if "`matsource'"=="dta" | "`matsource'"==".dta" {
			preserve
			use `"`matrix'"',clear 
			mata comp_M=st_data(.,.)
			restore
		}
		*/
		}
	else{
	mata comp_M=`matrix'
	}
}


****
*Computation options

	*Projection individuals (e.g countries) / Nodes (e.g Products)
		if (mi(`"`projection'"')){
        local projection="indiv"
    }
	    if !inlist(`"`projection'"', "", "indiv", "nodes") {
        display as err "invalid option projection(), only {res}nodes {err}or  {res}indiv {txt}(default) arguments are possible"
        exit 198
    }	

	*Alternative methods (MR, eingenvalue, fitness)
		if (mi(`"`method'"')){
        local method="eigenvalue"
    }
	    if !inlist(`"`method'"', "", "eigenvalue", "mr", "fitness") {
        display as err "invalid option {res}method() {err}, only {res}mr {err} (Method of Reflections), {res}fitness {err}  or  {res}eigenvalue {txt}(default) arguments are possible"
        exit 198
    }	

	*Iterations (for MR only (and sign correction in Eigenvalue))
if "`method'"=="fitness"{
	if (mi(`"`iterations'"')){
	}
	else{
	noi di "note: iteration option not considered. Only for MR method"
	}
}

*if "`method'"!="fitness"{
	if (mi(`"`iterations'"')){
        local it=20 /*default nb of iteration : 20 as recommended by Hidalgo for the Economic Complexity*/
    }
	else{
	local it=`"`iterations'"'
	*di `it'
	}
	*noi di "iteration nb:" `it'
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
if "`rca'"==""{ 
mata T=comp_M
mata comp_M=(T:/rowsum(T)):/(colsum(T):/sum(T))
}

mata comp_M=mm_cond(comp_M:<1,0,1) /*make binary matrix if not initially, requires more_mata from SSC*/
	
	mata comp_D=rowsum(comp_M) /*Diversification*/

	mata comp_U=rowsum(comp_M') /*ubiquity*/
	

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
forvalues j=2 (2)`it'{
	local jm2=`j'-2
	mata st_matrix("_newiter",kc`j')
	mata st_matrix("_olditer",kc`jm2')	
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
					noi di "note : MR's optimal iteration reached at the `j'th"
				}
				local optiter=`j'
			mata mkc`optiter'=sum(kc`optiter')/rows(kc`optiter')
			mata dkc`optiter'=(kc`optiter':-mkc`optiter')
			mata sdkc`optiter'=sqrt((1/rows(kc`optiter'))*(sum(dkc`optiter':^2)))
			mata comp_i_MR=(kc`optiter' :- mkc`optiter') :/sdkc`optiter'
			}
		}
			
		if `s'!=0 & `j'==`it' { 
			if"`method'"=="mr"{ /*rank still changes but max iter reached*/
				noi di "note : MR's optimal iteration is of higher order than specified" 
			}
		mata mkc`it'=sum(kc`it')/rows(kc`it')
		mata dkc`it'=(kc`it':-mkc`it')
		mata sdkc`it'=sqrt((1/rows(kc`it'))*(sum(dkc`it':^2)))
		mata comp_i_MR=(kc`it' :- mkc`it') :/sdkc`it'
		}
	}
	

	*pci is of odd order and normalized as in the Atlas
		local itm1=`optiter'-1 /*takes optimal iteration level if reached, or `it' otherwise*/
		mata mkp`itm1'=sum(kp`itm1')/rows(kp`itm1')
		mata dkp`itm1'=(kp`itm1':-mkp`itm1')
		mata sdkp`itm1'=sqrt((1/rows(kp`itm1'))*(sum(dkp`itm1':^2)))
		mata comp_n_MR=(kp`itm1' :- mkp`itm1') :/sdkp`itm1'	
	


*EigenValue Method 
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
		 /*Eigenvector of M~cc′\tilde{M}_{c{c}'}​M​~​​​cc​′​​​​ associated with the second largest eigenvalue.*/
		mata comp_k=sum(comp_K)/rows(comp_K)
		mata comp_d=(comp_K:-comp_k):^2
		mata comp_std=sqrt((1/rows(comp_R))*sum(comp_d))
		mata Comp_i=(comp_K:-comp_k):/comp_std
		 
	mata comp_i=Re(Comp_i)
	mata st_matrix("Complexity_i", comp_i)		 

	
	*Complexity of nodes
 
		mata comp_V=(comp_M':/comp_U)*(comp_M:/comp_D)
		mata eigensystemselecti(comp_V, (1,2), comp_X=., comp_L=.)
		mata	mis=missing(eigenvalues(comp_V))
		mata inflate_V=0
		mata		 if (mis>0) comp_V=comp_V:*1e+100 ; inflate_V=0 ;
		mata if (mis>0) inflate_V=1; ;
		mata		 eigensystemselecti(comp_V, (1,2), comp_X=., comp_L=.)
		mata comp_Q=comp_X[.,2] 
		/*Eigenvector of M~cc′\tilde{M}_{c{c}'}​M​~​​​cc​′​​​​ associated with the second largest eigenvalue.*/
		mata comp_q=sum(comp_Q)/rows(comp_Q)
		mata comp_d=(comp_Q:-comp_q):^2
		mata comp_stdev=sqrt((1/rows(comp_Q))*sum(comp_d))
		mata Comp_n=(comp_Q:-comp_q):/comp_stdev
		 

	mata comp_n=Re(Comp_n)
	mata st_matrix("Complexity_n", comp_n)		 
	

*Correct ECI/PCI sign if required : Correlate with MR
	quietly{
		mata st_matrix("comp_i_MR", comp_i_MR)
		mata st_matrix("comp_n_MR", comp_n_MR)
		
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
		quie svmat Complexity_n 
		quie svmat comp_n_MR
		corr Complexity_n1 comp_n_MR1
		local r=r(rho)
		if `r'<0 {
		mata comp_n = - comp_n
		mata st_matrix("Complexity_n", comp_n)
		}
		drop Complexity_n1 comp_n_MR1	
		capture rename Complexity_n1 Complexity_n
		drop if _n>`n'
	}
}

	
	if "`xvar'"==""{
	
	if "`method'"!="mr"{
		if "`projection'"!="nodes"{
		 quie count
		 local N=r(N)
		 mata n=rows(comp_M)
		 *mata n
		 mata st_local("n", strofreal(n))
		 *noi di `n'
		 
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
		 *mata n
		 mata st_local("n", strofreal(n))
		 *noi di `n'
		 
		 if `n'>`N'{
		 set obs `n'
		 }
		 capture drop Complexity_n
		 svmat Complexity_n
		 capture rename Complexity_n1 Complexity_n
	   }
	}
 	if "`method'"=="mr"{ 
	mata st_matrix("comp_i_MR", comp_i_MR)
    mata st_matrix("comp_n_MR", comp_n_MR) 

		if "`projection'"!="nodes"{
		 quie count
		 local N=r(N)
		 mata n=rows(comp_M)
		 *mata n
		 mata st_local("n", strofreal(n))
		 *noi di `n'
		 
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
		 *mata n
		 mata st_local("n", strofreal(n))
		 *noi di `n'
		 
		 if `n'>`N'{
		 set obs `n'
		 }
		 capture drop MR_Complexity_n
		 svmat comp_n_MR
		 capture rename comp_n_MR MR_Complexity_n
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
	return matrix Complexity_node_EV=Complexity_n
	}
	if "`method'"=="mr"{
	return matrix Complexity_individualMR=comp_i_MR
	return matrix Complexity_nodeMR=comp_n_MR
	}
	return scalar iterations=`it'
}	
	

		*Fitness
if "`method'"=="fitness"{
	mata fkc0=comp_D
	mata fkp0=comp_U
	
	forvalues j=1/`it'{
	local k=`j'-1
	mata fkc`j'=(comp_M*fkp`k')
	mata mfkc`j'=sum(fkc`j')/rows(fkc`j')
	mata fkc`j' = fkc`j':/mfkc`j'
	 
	mata fkp`j'=(comp_M'*(1:/fkc`k'))
	mata mfkp`j'=sum(fkp`j')/rows(fkp`j')
	mata fkp`j' = fkp`j':/mfkp`j'
	}
	mata st_matrix("fitness_i", fkc`it')
	mata st_matrix("fitness_n", fkp`it')

	if "`projection'"!="nodes"{
		capture drop fitness_i
		if "`xvar'"==""{
			capture drop fitness_i
			svmat fitness_i
			capture rename fitness_i1 fitness_i
			}
		}
	else{
		capture drop fitness_n
		if "`xvar'"==""{
			capture drop fitness_n
			svmat fitness_n
			capture rename fitness_n1 fitness_n
			}
		}
	capt drop complexity_n
	capture replace fitness_n=1/fitness_n
	mata fitness_i=fkc`it'
	mata fitness_n=1:/fkp`it'
	*mata complexity_n=1:/fkp`it'
	mata st_matrix("fitness_n", fitness_n)
	mata st_matrix("Ubiquity", fkp0)
	mata st_matrix("Diversity", fkc0)
	return matrix Ubiquity=Ubiquity
	return matrix Diversity=Diversity
	return matrix Fitness_individual=fitness_i
	return matrix Fitness_node=fitness_n
	*return matrix Complexity_node=complexity_n
	return scalar iterations=`it'
}
if "`method'"=="eigenvalue"{
	if "`projection'"=="indiv"{
		su Complexity_i
	}
	if "`projection'"=="nodes"{
		su Complexity_n
	}
}
if "`method'"=="mr"{
	if "`projection'"=="indiv"{
		su MR_Complexity_i
	}
	if "`projection'"=="nodes"{
		su MR_Complexity_n
	}
}

if "`method'"=="fitness"{
	if "`projection'"=="indiv"{
		su fitness_i
	}
	if "`projection'"=="nodes"{
		su fitness_n
	}
}
	end

