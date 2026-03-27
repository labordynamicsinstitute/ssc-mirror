******************************************************************************
* LESLIE: v1.0, Mar. 25, 2026. Computes one-, two-sexes, and multistate      *
* population projections using extended Leslie matrices. Projections         *
* incorporate future trajectories of fertility and survival, net migrants,   *
* derive intrinsic rates, stable equivalent age structures, the net rep.     *
* rate (NRR), mean age of the maternity schedule, years of population growth *
* before declining, TFR, e0, pop. momentum, and others. The program also     *
* generates graphs of future asfr and survival probabilities                 *
* of the actual, intrinsic and stable equivalent age structures.             *
*
* First variable of the dataset must have the lower limit of the age group   *
* as observations. 															 *
*
* Author: Jeronimo O. Muniz, PhD. Professor of Sociology at UFMG, Brazil     * 
******************************************************************************

/*
 leslie.ado – Copyright (C) 2026 Jeronimo Oliveira Muniz

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY...
 */

window menu clear
window menu append item "stUserStatistics" ///
	"Demographic projections (&leslie)" "db leslie"

if `c(version)' > 18 { //sets the graph scheme of newer Stata versions to be backward compatible with the program, written in version 15
	set scheme stsj
					}	

*! 1.0.0 JOM, 25mar2026
program define leslie, rclass 
	version 15 //Program developed in this version of Stata
	syntax, Period(integer) [, SRb(real 1.05) male total l0(integer 100000) ///
		ExtraT(numlist max=2) Two Fert(numlist>0 max=1) Baseline(integer 0) ///
		PLace(string) SURv(numlist>40 max=2 miss) SIgma(numlist>0 max=2) /// 
		nmr(string) mig1(string) mig2 MUltistate Nomobility Stable SUmmary ///
		Tolerance(real 1e-6) Keyfitz Ygual(integer 14) GRopts(string asis)] 

	tempname radix
	qui matrix input `radix'= (`period')
	mata: period= st_matrix(st_local("radix"))
	loc period= `radix'[1,1]+1

mata: n = st_data(.,1)[3]-st_data(.,1)[2] // interval length
mata: st_local("n", strofreal(n)) //local `n'
mata: a = st_data(.,1):+(n/2) // age-group midpoints
mata: p = st_data(.,2)  // population count by age	
	
*******************************************************************************
*Error messages:
	*if period(integer) is higher than 99 or lower than 1
capture {
	local z= `period'-1
	if (`z'>99 | `z'<1) error 103
		}
if _rc == 103 {
	display as err "{p}"
	di "Please specify a number between 1 and 99 in {opt period()}."
	di "If you requested more than 99 projections in your syntax of"
	di "{cmd: leslie}, remember J. M. Keynes's (1923) words: 'The long run is" 
	di "a misleading guide to current affairs. In the long run we are all dead'."
	exit 103
				}
	*if dataset has just one population but the user adds option "two" 
capture {
	qui ds
	tokenize `r(varlist)'
	duplicates report `1'
	if "`two'"=="two" & (`r(unique_value)'==`r(N)') error 503
		}
if _rc == 503 {
	display as err "{p}"
	di "Your dataset seems to have just one population."
	di "Aren't you equivocally adding option {opt two} to the command line?"
	exit 503
				}
	*if dataset has just one population but the user adds option "multistate" 
capture {
	qui ds
	tokenize `r(varlist)'
	duplicates report `1'
	if "`multistate'"=="multistate" & (`r(unique_value)'==`r(N)') error 3300
		}
if _rc == 3300 {
	display as err "{p}"
	di "Your dataset seems to have just one population. Aren't you equivocally"
	di " adding option {opt multistate} to the command line?"
	exit 3300
				}
	*if dataset has more than one population but the user forgets option "two" 
capture {
	qui ds
	tokenize `r(varlist)'
	duplicates report `1'
	if "`two'"=="" & "`multistate'"=="" & (`r(unique_value)'<`r(N)') error 119
		}
if _rc == 119 {
	display as err "{p}"
	di "Your dataset seems to have more than one population."
	di "Aren't you forgetting to add option {opt two} or {opt multistate}?"
	exit 119
				}
	*if data is probably multistate but that option is not included
capture{
	qui des
	if `r(k)'>4 & "`multistate'"=="" error 3200
		}
if _rc== 3200 {
	display as err "{p}"
	di "Your dataset has more than four variables (or columns). If it is"
	di "{opt multistate} please add this option to your command line."
	exit 3200
				}
	*if data is for two-sex populations but multistate is included
capture {
	qui des
	if "`multistate'"=="multistate" & `r(k)'==4 error 3300
		}
if _rc== 3300 {
	display as err "{p}"
	di "Your dataset is not adequate for multistate analysis. Please remove"
	di "the {opt multistate} option from your command line."
	exit 3300
				}
	*just one value within extraT() but "two" option
capture {
	local count: word count `extraT' 
	if "`two'"=="two" & "`extraT'"!= "" & `count'<2 error 3000
		}
if _rc== 3000	{
	display as err "{p}"
	di "You must specify two values within the {opt extraT()} option if"
	di "you request the {opt two} option."
	exit 3000			
				}
	*if the "keyfitz" option is specified with the "multistate" option
capture {
	if ("`multistate'"!=""| "`two'"!="") & "`keyfitz'"!="" error 3000
		}
if _rc == 3000 {
	display as err "{p}"		  
	di "Keyfitz's Delta cannot be used as a criterion of distance to stability"
	di "when the {opt multistate} or {opt two} options are also specified."
	exit 3000
			   }
*if the "keyfitz" option is specified without the "summary" option
capture {
	if "`keyfitz'"!="" & "`summary'"=="" error 3000
		}
if _rc == 3000 {
	display as err "{p}"		  
	di "The {opt keyfitz} option must be jointly specified with"
	di " the {opt summary} option."
	exit 3000
			   }			   
*if the "tolerance" option is specified without the "summary" option
capture {
	if "`tolerance'"!="1.00000000000e-06" & "`summary'"=="" error 3000
		}
if _rc == 3000 {
	display as err "{p}"		  
	di "The {it: default} level of tolerance to achieve stability is set to 1e-6."
	di " Please specify the {opt tolerance()} and {opt summary} options together"
	di " if you want to change this level."
	exit 3000
			   }			   
	*just one value in surv(), but "two" option is specified 
capture {
	local s_count: word count `surv'
	if "`two'"!="" & "`surv'"!="" & `s_count'<2 error 3000
		}
if _rc== 3000 {
	display as err "{p}"
	di "Specify two consecutive values in {opt surv()} (i.e., female and"
	di "male expected life expectancies) when you simultaneously specify the"
	di "{opt two} option."
	exit 3000
			  }			  
*if mig2 is requested without mig1()
capture {
if "`mig2'"== "mig2" & "`mig1'"== "" error 3000
		}
if _rc== 3000 {
	display as err "{p}"
	di "The {opt mig2} option must be simultaneously entered with the"
	di "{opt mig1()} option."
	exit 3000
			  }
*if the "extraT()" option is specified with the "multistate" option
capture {
	if "`multistate'"!="" & "`extraT'"!="" error 3000
		}
if _rc == 3000 {
	display as err "{p}"		  
	di "{opt extraT()} cannot be used"
	di "when the {opt multistate} option is also specified."
	exit 3000
			   }
*if the "mig1()" option is specified with the "multistate" option
capture {
	if "`multistate'"!="" & "`mig1'"!="" error 601
		}
if _rc == 601 {
	display as err "{p}"		  
	di "The {opt mig1()} option cannot be requested"
	di "when the {opt multistate} option is also specified."
	exit 601
			   }
*if the "nomobility" option is specified without the "multistate" option
capture {
	if "`multistate'"=="" & "`nomobility'"!="" error 601
		}
if _rc == 601 {
	display as err "{p}"		  
	di "The {opt nomobility} option can only be requested "
	di "when the {opt multistate} option is also specified."
	exit 601
			   }
*if "male" and "total" options are simultaneously specified 
capture {
	if "`male'"!="" & "`total'"!="" error 119
		}
if _rc == 119 {
	display as err "{p}"
	di "Are you projecting the single {opt male} population or the {opt total}"
	di " population (combining females and males in a single vector)?"
	di " You cannot specify both options at the same time."
	exit 119
				}			   
*if "baseline()" and "place()" options are specified without each other 
capture {
	if ("`baseline'"!="0" & "`place'"=="" & ("`fert'"=="" & "`surv'"=="")) | ///
	("`baseline'"=="0" & "`place'"!="") | ("`baseline'"!="0" & ///
	"`place'"!="" & "`fert'"!="") error 119
		}
if _rc == 119 {
	display as err "{p}"
	di "You must simultaneously specify the {opt baseline()} and {opt fert()}"
	di " (or {opt surv()}) options {bf:OR} {opt baseline()} and {opt place()} to"
	di " predict the future trajectory of fertility (or survival) using the"
	di " probabilistic median variant of the United Nations (2024)."
	exit 119
				}		   
*if "baseline()" and `baseline'+(`period'-1)*`n'< 2023  
capture {
	if "`baseline'"!="0" & (`baseline'+(`period'-1)*`n')<2024 error 119
		}
if _rc == 119 {
	display as err "{p}"
	di "If you specify {opt baseline()}, your final projection year, derived"
	di " from {opt period()}, must be later than 2024."
	exit 119
				}
*if "baseline()", "place()" and "surv()" are simultaneusouly defined 
capture {
	if "`baseline'"!="0" & "`place'"!="" & ("`surv'"!="." & "`surv'"!="") ///
		& "`two'"=="" error 119 	
		}				
if _rc== 119 {
	display as err "{p}"
	di "Set {opt surv(.)} to choose the life expectancy expected in the last"
	di "projection period from the United Nations (2024)."
	di " Alternatively, if you set a future value in the {opt surv()} option,"
	di "  do not specify the {opt place()} option."
		exit 119
			  }
*if "surv(.)" & "baseline()" OR just "surv(.)"
capture {
	if ("`surv'"=="." | "`surv'"==". .") & "`baseline'"=="0" & "`place'"=="" ///
		| ("`surv'"=="." | "`surv'"==". .") & "`baseline'"!="0" & ///
		"`place'"=="" error 119
		}
if _rc==119 {
	display as err "{p}"
	di "Enter a valid value for life expectancy in the {opt surv()} option."
		exit 119	
			}		

*******************************************************************************

if "`multistate'"=="" {
mata: L = st_data(.,3)/`l0'
					  }
if "`two'" == "" & "`multistate'"=="" {
	mata: T= flipud(runningsum(flipud(L))) //running sum of L(x)
									  }
if "`two'" != "" & "`multistate'"=="" {
mata: T=J(length(L),1,0) // females in the top, males in the bottom 
mata: T[1..length(L)/2]= flipud(runningsum(flipud(L[1..length(L)/2])))
mata: T[(length(L)/2)+1..length(L)]= ///
		flipud(runningsum(flipud(L[(length(L)/2)+1..length(L)])))						   
									   }
									   
*ERROR msg: the last value of T must be lower than in the previous age group
capture {
	mata: st_local("Tlast", strofreal(T[length(T)]))
	if "`two'"== "two" {
	mata: st_local("Tlastf", strofreal(T[length(T)/2]))
						}
	tokenize `extraT'
	if ("`extraT'"!="" & "`two'"=="") & `1'>`Tlast' error 3000
	if ("`extraT'"!="" & "`two'"=="two") & `2'>`Tlast' error 3000
	if ("`extraT'"!="" & "`two'"=="two") & `1'>`Tlastf' error 3000
		}
if _rc== 3000 {
	display as err "{p}"
	di "The extra value(s) of {it:T} specified for the open-ended age group, typed"
	di " within the {opt extraT()} option, cannot be higher than"
	di " the value of {it:T} observed in the previous/last age group."
	di " To verify the value of {it:T} in the last age group type: {cmd:.mata T}."
exit 3000
			}
									   
*Maternity rates (female births)
mata: f = st_data(.,4) // ASFRs
mata: m= f/(1+`srb') // The default is srb= 105/100, for female proj.

if "`male'"!="" {
	mata: m= f*(`srb'/(1+`srb'))
				}	//The default sets srb= 100/105= 0.95238095 for male proj.		

if "`total'"!="" {
	mata: m= f
				 } //For both sexes combined in a single total pop., sets srb=0.
							 
if "`two'" == "" & "`multistate'"=="" {
mata: nrr= sum(L:*m) //Net reproduction rate
									  }
if "`two'" != "" & "`multistate'"=="" {
mata: mm= f/(1+1/`srb') //male-fertility rate (male births), male-dominant proj. 
mata: fnrr= sum(L[1..(length(L)/2)]:*m[1..(length(L)/2)]) //females
mata: mnrr= sum(L[(length(L)/2)+1..length(L)]:*mm[1..(length(L)/2)]) //males
									  }								

*************
*PROJECTIONS*
*************
if "`two'" == "" & "`multistate'"=="" {
mata: M= Leslie(L,m) // Leslie(1945) matrix, one-sex
if "`extraT'"!= "" {
mata: M[rows(M),cols(M)-1]= (T[length(T)]-`extraT')/L[length(L)-1]
mata: M[rows(M),cols(M)]= `extraT'/((T[length(T)]-`extraT')+`extraT')
				   }
									  }
if "`two'" != "" { //no migration
*Female block
mata: fM=Leslie(L[1..length(L)/2],m[1..length(L)/2])
if "`extraT'"!= "" {
tokenize `extraT'
mata: fM[rows(fM),cols(fM)-1]= (T[length(T)/2]-`1')/L[length(L)/2-1]
mata: fM[rows(fM),cols(fM)]= `1'/((T[length(T)/2]-`1')+`1')
					}
//Male block
mata: mM= Lesliem(L[1..length(L)/2],L[(length(L)/2)+1..length(L)],mm[1..length(L)/2])
if "`extraT'"!= "" {
mata: mM[rows(mM),cols(mM)-1]= (T[length(T)]-`2')/L[length(L)-1]
mata: mM[rows(mM),cols(mM)]= `2'/((T[length(T)]-`2')+`2')
				   }

mata: M= blockdiag(fM,mM) //Two-sex combined (without migration)
mata: F_m= mM[1,.],J(1,cols(mM),0)
mata: M[length(p)/2+1,.]= F_m // places male births to be multiplied by women
					}
if "`nmr'"!="" {
	preserve
		qui use `nmr'
		mata: nmr= st_data(.,1) 
	restore
	if "`two'" == "" {
mata: P= diag(nmr)
if "`mig2'" == "" {
mata: M = M + P*M  // replaces one-sex proj. matrix without mig. by one with mig. 
				  }
*Approach 2: assumes that residual migrants are split over the proj. period 
* (referee's suggestion based on Preston et al 2001, 125-127).							 
if "`mig2'" != "" {
mata: M= M + M*P*M/2 + P*M/2
				   }
					  }			
if "`two'" != "" {
*Female migration block
mata: Pf= diag(nmr[1..length(nmr)/2])
*Male migration block
qui des
mata: Pm= diag(nmr[length(nmr)/2+1..`r(N)'])

*Matrices including migration, two-sexes
*Approach1: adds migrants at the beggining of the interval
if "`mig2'" == "" {
loc size= `r(N)'/2
mata: Sm= mM-(F_m[1..`size']\J(`size'-1,`size',0)) // male survival matrix
mata: M=blockdiag((I(`size')+Pf)*fM, Sm+Pm*mM) // two-sexes w/ net migration
*Puts male births in lower left block to be multiplied by women
mata: M[(`size'+1)..`r(N)',1..`size']= F_m[1..`size']\J(`size'-1,`size',0) 					
				   }
*Approach2: splits migrants over the proj. period, Preston et al(2001, 125-127) 
if "`mig2'" != "" {
mata: Sm= mM-(F_m[1..`size']\J(`size'-1,`size',0)) // male survival matrix
mata: M=blockdiag(fM, Sm)
mata: M[(`size'+1)..`r(N)',1..`size']= F_m[1..`size']\J(`size'-1,`size',0) 					
mata: M= M+ M*blockdiag(Pf*fM/2, Pm*mM/2)+ blockdiag(Pf*fM/2, Pm*mM/2)
				   }
					}
				}					
if "`mig1'" != "" {
preserve
	qui use `mig1'
	mata: op=st_data(.,1) //adds pop. in t-5 to Mata
restore
mata: res= p-(M*op) //Residual migrants from past pop. proj. forward
mata: nmr=J(length(p),1,0) //Probs. of migration for age group x-n
qui su
if "`two'" == "" {
*Net migration "RATES": Denominator represents proj. pop. (natural growth), 
*			following Thomlinson (1962) and Johnson et al (2005) 
forval x=2/`r(N)' {
mata: nmr[`x']=res[`x']/(M*op)[`x']
				  }
*mata: nmr[`r(N)']=res[`r(N)']/((M*op)[`r(N)'])
mata: nmr[1]= p[1]:/(M*op)[1]-1 //first element of the nmr vector (P matrix)
*mata: mfert= (M[1,.]/rowsum(M[1,.])*res[1])':/(M*op) //Migrants' ASFR adj.
*mata: P=Leslie2(nmr,mfert)
mata: P= diag(nmr)

*Matrices including migration, one-sex
*Approach 1: adds migrants at at the start of the interval
if "`mig2'" == "" {
mata: M=M + P*M  // replaces one-sex proj. matrix without mig. by one with mig. 
				  }
*Approach 2: assumes that residual migrants are split over the proj. period 
* (referee's suggestion based on Preston et al 2001, 125-127).							 
if "`mig2'" != "" {
mata: M= M + M*P*M/2 + P*M/2
				   }
					}
if "`two'" != "" {
*Female migration block
qui des
loc size= `r(N)'/2
forval x=2/`size' {
	mata: nmr[`x']=res[`x']/(M*op)[`x']
				  }
mata: nmr[1]= p[1]:/(M*op)[1]-1
mata: Pf= diag(nmr[1..length(nmr)/2])

*Male migration block
loc sizem= (`r(N)'/2)+2
forval x=`sizem'/`r(N)' {
	mata: nmr[`x']=res[`x']/(M*op)[`x']
						}
mata: nmr[length(p)/2+1]= p[length(p)/2+1]:/(M*op)[length(p)/2+1]-1 

mata: Pm= diag(nmr[length(nmr)/2+1..`r(N)'])

*Matrices including migration, two-sexes
*Approach1: adds migrants at the beggining of the interval
if "`mig2'" == "" {
mata: Sm= mM-(F_m[1..`size']\J(`size'-1,`size',0)) // male survival matrix
mata: M=blockdiag((I(`size')+Pf)*fM, Sm+Pm*mM) // two-sexes w/ net migration
*Puts male births in lower left block to be multiplied by women
mata: M[(`size'+1)..`r(N)',1..`size']= F_m[1..`size']\J(`size'-1,`size',0) 					
				   }
*Approach2: splits migrants over the proj. period, Preston et al(2001, 125-127) 
if "`mig2'" != "" {
mata: Sm= mM-(F_m[1..`size']\J(`size'-1,`size',0)) // male survival matrix
mata: M=blockdiag(fM, Sm)
mata: M[(`size'+1)..`r(N)',1..`size']= F_m[1..`size']\J(`size'-1,`size',0) 					
mata: M= M+ M*blockdiag(Pf*fM/2, Pm*mM/2)+ blockdiag(Pf*fM/2, Pm*mM/2)
				   }
					}
					}				
if "`multistate'" != "" {
*Conversion of qxi (prob. that an individual in state i at age x will be in 
*state j at age x+n) to sij(x,n) - survivorship proportions: the proportion 
*of persons in state i of the model population between ages x and x+n who are in 
*state j exactly n years later. Note that sij(x,n) are the elements that will 
*be placed in the subdiagonal of the multistate Leslie matrix.

*Step 1: age-specific transition matrices, P(x), a la Rogers (1995: 96)
preserve
if "`nomobility'" !="" { //zeros the transition probabilities in the dataset
	qui des
	loc last=`r(k)'-1
	forval c=5/`last' {
		loc to `to' `c'
						}
	qui ds
	tokenize `r(varlist)'
	foreach var of local to {
		qui replace ``var''=0
							} 
	 					}

	qui des
	mata: rates= st_data(.,5..(`r(k)'-1))
	mata: q= st_data(.,3)
	mata: v1= st_data(.,`r(k)')
	mata: info= panelsetup(v1,1)
	qui su
	loc max= `r(max)' // local macro for the number of states
	forval x=1/`r(max)' {
		mata pan`x'= panelsubmatrix(rates,`x',info)[.,1..`r(max)']
						}
	clear
	forval x=1/`max' {
		getmata (var`x'*)=pan`x'
					 }		 
	foreach var of varlist * {
		summ `var', meanonly
		if missing(r(mean)) drop `var'
							 }
	if "`nomobility'" !="" {
		drop var1*					
							}
	qui des
	forval x= 1/`r(N)' {
		mata: N`x'= N(colshape(st_data(`x',(1..st_nvar())),`max'-1)) //fun. N()
		mata: q`x'= diag(colshape(rowshape(q,`r(N)'),`r(N)')'[`x',.])					 
		mata: P`x'= (N`x'-q`x')'					 
		mata: M`x'=	2/n*luinv(I(`max')+P`x')*(I(`max')-P`x')				 
		 			   }
	loc j=`r(N)'-1
	forval x=1/`j' {
		loc y = `x'+1
	*Rogers (1995: 101)
		*mata: S`x'M = luinv(I(`max')+n/2*M`y')*(I(`max')-n/2*M`x')
		mata: S`x'P = (I(`max')+P`y')*P`x'*luinv(I(`max')+P`x')
					}	
restore

*Step 2: calculation of survivorship ratios, S(x)
mata: l1=diag(J(`max',1,`l0')) //puts the l0s from mu() in their proper place
forval x=2/`r(N)' {
	loc y= `x'+1
	loc z=`x'-1
	mata: l`x'=P`z'*l`z'
	mata: l`y'= P`x'*l`x'
	mata: d`z'= l`z'-l`x'
	mata: d`x'= l`x'-l`y'
	mata: L`z'=	luinv(M`z')*d`z'
	mata: L`x'=luinv(M`x')*d`x'
	mata: S`z'=L`x'*luinv(L`z')	//same as S`x'P and S`x'M	
					}
*Calculation of L(x) in the last open-ended age group
* Following Ortega(1982, 25) and UN(1956,23), apud Muniz(2023,footnote 6)
mata: L`r(N)'= l`r(N)'*luinv(M`r(N)')
*l`r(N)':*log10(l`r(N)')


/*mata: values = J(0,0,.)
	mata: vectors = J(0,0,.)
	mata: eigensystem(l`r(N)', vectors, values)
	mata: L`r(N)'=vectors:*diag(log10(values))*luinv(vectors)
*/
if "`nomobility'"!= "" { //gets rid of 0 values to execute log10
	mata: L`r(N)'=  l`r(N)'*luinv(M`r(N)')
	*l`r(N)':*diag(log10(diagonal(l`r(N)')))
						}
*Calculation of S(x) in the next-to-last age group
*mata: S`r(N)'P= I(`max')-n/2*(I(`max')+P`r(N)')*M`r(N)' //Rogers(1995:106)
*mata: S`r(N)'P= L`r(N)'*luinv(L`r(N)'+L`j')
mata: S`j'P= luinv(I(`max')+n/2*M`r(N)')*(I(`max')-n/2*M`j')
*Re(L`r(N)':/(L`r(N)'+L`j'))
*luinv(I(`max')+n/2*M`r(N)')*(I(`max')-n/2*M`j')
mata: S`r(N)'P= S`j'P
*diag(J(rows(S1P),cols(S1P),0)) //zero matrix
*S`j'P
					
*Step 3: Place the elements of S(x) in vectors/ matrices
qui su
loc cols=`r(max)'
loc agel=`r(N)'/`r(max)'
forvalues c=1/`cols' {
	local state `state' `c' 
					  }
foreach a of local state {
	mata: s`a'=J(`agel', `r(max)',0)
	forval x=1/`agel' {
		mata: s`a'[`x',.]=S`x'P'[`a',.]			
					   }
					   }
mata: s=s1
forval a=2/`r(max)'	{
		mata: s= s\s`a'	//structured as v2		  
					}
mata: sd=s1[.,1] //pii in a single column vector similar to v3
forval a=2/`r(max)'	{
		mata: sd= sd\s`a'[.,`a']	//structured as v2		  
					}	
qui des
mata: v2= st_data(.,(5..(`r(k)'-1)))
mata: v3= st_data(.,3..4) //Mortality and reproduction Leslie matrices
mata: v3[.,1]= 1:-(st_data(.,3)+rowsum(v2)) //Stayers' prob. of surv. in i
mata: vpsurv= 1:-st_data(.,3) //prob. of surviving
qui su ``r(k)''
forval x=1/`r(max)' {
	mata: surv`x'= panelsubmatrix(v3,`x',info)[.,1] //stayers prob of surv. in i
	mata: prsurv`x'=panelsubmatrix(vpsurv,`x',info)[.,1] //prob of surv. in i
	mata: sd`x'=panelsubmatrix(sd,`x',info)[.,1]
	mata: tft`x' =panelsubmatrix(v3,`x',info)[.,2]
					}				
mata: Mob= panelsubmatrix(s,1,info)[.,1]
forval x=2/`r(max)' {
	mata: Mob= blockdiag(Mob, panelsubmatrix(sd,`x',info)[.,1]) //Surv. in diag.
					}				
mata: v2= Mob+editmissing(v2,0) //input for mobility matrices below
qui su
loc length= `r(N)'/`r(max)'-1
forval x=1/`r(max)' {
	mata: ave_tft`x'=J(length(tft`x'),1,.)
	forval z= 1/ `length' {
		mata: ave_tft`x'[`z']= (tft`x'[`z']+tft`x'[`z'+1]:*prsurv`x'[`z'+1])/2
						  }
		mata: ave_tft`x'= editmissing(ave_tft`x',0) //Average ASFR
					}
*Mobility matrices
qui ds
tokenize "`r(varlist)'"
qui su ``r(k)''
forval x=1/`r(max)'  {
	forval y=1/`r(max)' { //ASFRs
		mata: M`x'`y' = diag(panelsubmatrix(s,`x',info)[.,`y'])
		mata: M`x'`y'[rows(M`x'`y')-1,cols(M`x'`y')] = ///
					M`x'`y'[rows(M`x'`y'),cols(M`x'`y')]
		mata: M`x'`y' = J(1,cols(M`x'`y'),0)\M`x'`y'[1..(cols(M`x'`y')-1),.]
		mata: mob`x'`y'=panelsubmatrix(v2,`x',info)[.,`y']
		mata: M`x'`y'[1,.]= n/(1+`srb'):*(ave_tft`x':*prsurv`x'[1]:* ///
												mob`x'`y':/prsurv`x')' 
			 			}
					  }

*Assembling block matrix with mobility matrices a 
*la Rogers(1966, 1968: 13, 1995:117, (A))
mata: Mmig= M11
forval i= 1/`r(max)' {
	forval j=1/`r(max)' {
		mata: Mmig= Mmig\ M`i'`j'				
						}
					  }
mata: Mmig=Mmig[cols(M11)+1..rows(Mmig),.]
mata: Mmig2=Mmig[1..rows(s),.]
loc max=`r(N)'*(`r(max)'-1)
forval l=`r(N)'(`r(N)')`max'	{				
		mata: Mmig2=Mmig2, Mmig[(`l'+1)..(`l'+`r(N)'),.] //Mobility matrices
								}
mata: M=editmissing(Mmig2,0)
							}
if "`multistate'" != "" & "`nomobility'" !="" {
qui su 
forval x=1/`r(max)' {
	mata: M`x'=Lesliems(sd`x', prsurv`x', tft`x')
					}
mata: Mb=M1
forval x=2/`r(max)' {
	mata: Mb=blockdiag(Mb, M`x') //Mortality and fertility Leslie matrices
					}
mata: M=Mb
											   }											
											   
************************************************************
*Last step of POPULATION PROJECTIONS: matrix multiplication*
************************************************************
*Assuming constant rates
mata: fp=J(st_nobs(),`period',0) //creates a null matrix of future pops.
mata: fp[.,1]=p
/*if "`extraT'" == "" {
	mata: fp[st_nobs(),1]=p[st_nobs()]+p[st_nobs()-1]
					}
if "`two'"!="" & "`extraT'"=="" {
	mata: fp[st_nobs(),1]=p[st_nobs()]+p[st_nobs()-1]
	mata: fp[st_nobs()/2,1]=p[st_nobs()/2]+p[st_nobs()/2-1]
								}
*/
if "`fert'" == "" {
	forval x=2/`period' {
	mata: fp[.,`x']=M*fp[.,`x'-1]
						}
				  }

**********************
*PROJECTION SCENARIOS*
**********************
*********
*ONE-SEX*
*********
/*FERTILITY: depends on the ultimate TFR level defined by the user and assumes 
that the change happens equally in all age groups (no change in the fertility
pattern). The rhythm/speed of change is derived from the formula of 
compound interest rates.*/
if "`two'" == "" {
	if "`baseline'" =="0" & "`fert'" != "" { //constant ASFR drop over time
mata: r_fert= (`fert'/(colsum(f)*n))^(1/period)-1 //compound interest rate					
mata: fF=J(period+1,cols(M),.)
mata: fF[1,.]=M[1,.] // first row of projection matrix M
forval x=2/`period' { // future net female ASFRs levels, same age pattern
	mata: fF[`x',.]=fF[`x'-1,.]+fF[`x'-1,.]*r_fert
					}
*Conversion of fF values (i.e., first row of M) to ASFRs
mata: mat_rate=flipud(fF')
mata: start=diag0cnt(diag(select(mat_rate,a:>10)[.,1]))+1
mata: mat_rate[start,.]=flipud(fF')[start,.]:/L[1]*2 //last reproductive age
mata: st_local("start", strofreal(start+1))
mata: start2=rows(fF')-diag0cnt(diag(select(fF',a:<50)[.,1]))
mata: st_local("start2", strofreal(start2))
forval x=`start'/`start2' {
mata: mat_rate[`x',.]=2*flipud(fF')[`x',.]:/L[1]-mat_rate[`x'-1,.]* ///
	flipud(L)[`x'-1]/flipud(L)[`x']
						  }
mata: mat_rate=flipud(mat_rate) // future female ASFRs

*Graph showing ASFR future scenarios
mata: st_local("tfr", strofreal(colsum(f)*n, "%4.2f")) //current/first tfr
mata: st_local("tfr2", strofreal(colsum(mat_rate[.,cols(mat_rate)])* ///
		(1+`srb')*n, "%4.2f")) //last tfr
mata: st_local("fc_rate", strofreal(r_fert*100, "%4.2f")) //speed of change
mata: st_local("interval", strofreal(n, "%4.0f")) //length of age group
preserve
	forval x=1/`period' { //Generates variables of predicted ASFRs
	mata: st_store(.,st_addvar("float","fF`x'"), mat_rate[.,`x']:*(1+`srb'))
						 }
	qui des //Graphs age structure of age-specific fertility rates
	loc pn=`r(k)'
	qui ds
	tokenize "`r(varlist)'"
	qui keep if `1'<=50 & `1'>=10 // restricts graph to reproductive ages
	loc last_p =`period'+1
	line `5'-``pn'' `1', lwidth(vthick) ///
	|| line ``pn'' `1',  lp(dash_dot) lwidth(vthick) ///
	, graphregion(fcolor(white)) ytitle(ASFR) ti(Predicted Trajectory of Age ///
	Specific Fertility Rates) leg(on order(1 "Current" "period (TFR= `tfr')" ///
	`last_p' "Last" "period (TFR= `tfr2')") region(lc(%0)) pos(6) col(2) ///
	all) name(asfr, replace) note({it:Note}: Convergence speed corresponds ///
	to a `fc_rate'% change in TFR per `interval'-year period., span) `gropts'
restore
												}
	
	if "`baseline'" != "0" {
		if "`place'" != "" & ("`surv'"=="" | "`surv'"==".") { //defines a final specific ASFR standard
preserve
	use "wpp2024_median_fert.dta", replace
	loc fyear=`baseline'+(`period'-1)*`n'
	list Place Year TFR if Place== "`place'" & Year==`fyear', clean noobs
	qui putmata asfr_std=(asfr_10-asfr_50) if Place== "`place'" & ///
		Year==`fyear', replace
restore
mata: fasfr=J(1,rows(a),0)
mata: fasfr[3..11]=asfr_std/1000*n
															}	
	
	if "`fert'" != "" { //defines a final ASFR standard according to min(TFRt-TFR)
preserve
	use "wpp2024_median_fert.dta", replace
	mata: st_local("n", strofreal(n))
	loc fyear=`baseline'+(`period'-1)*`n'
	qui drop if Year!=`fyear'
	qui gen Abs_diff= abs(`fert'-TFR)
	sort Abs_diff
	list Place Year TFR Abs_diff in 1/5, clean
	qui gen asfr_std=1 in 1 // choosen pattern
	qui putmata asfr_std=(asfr_10-asfr_50) if asfr_std==1, replace
restore
mata: asfr_std=asfr_std/1000*n
mata: asfr_std=asfr_std:/rowsum(asfr_std) //Shares of future TFR
mata: fasfr=J(1,rows(a),0)
mata: fasfr[3..11]=asfr_std*`fert' //future ultimate asfr borrowing 
		// the age pattern from a place in the WPP with the closest TFR value
							}
if "`fert'"!="" | ("`baseline'"!="0" & "`place'"!="" & ///
	"`surv'"=="." | "`surv'"== "") 							{
mata: rfert=(fasfr':/(f*n)):^(1/period):-1	//age-specific growth rate of ASFR

*Future trajectory of the first row of the Leslie matrix
mata: fF=J(period+1,cols(M),.)
mata: fF[1,.]=M[1,.] //female ASFR in the first period
forval x=2/`period' { //future female ASFR levels, borrowed pattern
	mata: fF[`x',.]=editmissing(fF[`x'-1,.]+fF[`x'-1,.]:*rfert',0)
					}

*ASFRs future trajectory
mata: f_asfr=J(period+1,cols(fasfr),.)
mata: f_asfr[1,.]=(f*n)' //female ASFR in the first period
forval x=2/`period' { //future female ASFR levels, borrowed pattern
	mata: f_asfr[`x',.]=f_asfr[`x'-1,.]+f_asfr[`x'-1,.]:*rfert'
					}
mata: f_asfr=editmissing(f_asfr',0)
					
*Graph showing ASFR future scenarios
mata: st_local("tfr", strofreal(colsum(f)*n, "%4.2f")) //current/first tfr
mata: st_local("tfr2", strofreal(colsum(f_asfr[.,cols(f_asfr)]),"%4.2f")) //last tfr
mata: st_local("fc_rate", strofreal(mean(rfert)*100, "%4.2f")) //speed of change
mata: st_local("interval", strofreal(n, "%4.0f")) //length of age group
preserve
	forval x=1/`period' { //Generates variables of predicted ASFRs
	mata: st_store(.,st_addvar("float","fF`x'"), f_asfr[.,`x'])
						 }
	qui des //Graphs age structure of age-specific fertility rates
	loc pn=`r(k)'
	qui ds
	tokenize "`r(varlist)'"
	qui keep if `1'<=50 & `1'>=10 // restricts graph to reproductive ages
	loc last_p =`period'+1
	line `5'-``pn'' `1', lwidth(vthick) ///
	|| line ``pn'' `1',  lp(dash_dot) lwidth(vthick) ///
	, graphregion(fcolor(white)) ytitle(ASFR) ti(Predicted Trajectory of Age ///
	Specific Fertility Rates) leg(on order(1 "Current" "period (TFR= `tfr')" ///
	`last_p' "Last" "period (TFR= `tfr2')") region(lc(%0)) pos(6) col(2) ///
	all) name(asfr, replace) note({it:Note}: Convergence speed: ///
	`fc_rate'% average change in TFR per `interval'-year period., span) `gropts'
restore					
																}		
							}
							
*Execute forward projections with varying net female ASFRs					 
	if  ("`place'"!="" & "`surv'"=="") | "`fert'" != "" {
		forval x=2/`period' { //projections
			mata: M[1,.]= fF[`x',.]
			mata: fp[.,`x']= M*fp[.,`x'-1] //changing net female ASFRs
							}
														}
					}

/*SURVIVAL: Calculation of future survival using a logistic curve based on three
 parameters: alfa, sigma and future life expectancy at birth. Sigma defines how steep
 the gains in survival will be. Higher values of sigma implies in increased 
 survival at older ages, lower values implies higher gains in intermediate ages.
 Sigma, in other words, defines the rectangularization of the survival curve*/

*Gets final life expectancy from the World Population Prospects (WPP) file
if "`two'" == "" & "`surv'"!="" & "`surv'"!="." & "`baseline'"!="0" ///
	& "`place'"=="" {
	preserve
		if "`male'"=="" { //if female
			use "wpp2024_median_e0F.dta", replace
						 }
		if "`male'"!= "" { // if male
			use "wpp2024_median_e0M.dta", replace
						 }
		if "`total'"!="" { //if total
			use "wpp2024_median_e0.dta", replace
						 }
		loc fyear=`baseline'+(`period'-1)*`n'
		qui keep Index-Type e0_`fyear'
		qui gen Abs_diff= abs(e0_`fyear'-`surv')
		sort Abs_diff
		list Place e0_`fyear' in 1/5, clean 
	restore
					}
if "`two'" == "" & "`surv'"=="." & "`baseline'"!="0" & "`place'"!="" {
	preserve
		if "`male'"=="" { //if female
			use "wpp2024_median_e0F.dta", replace
						}
		if "`male'"!= "" { // if male
			use "wpp2024_median_e0M.dta", replace	 
						 }
		if "`total'"!="" { //if total
			use "wpp2024_median_e0.dta", replace
						 }
		loc fyear=`baseline'+(`period'-1)*`n'
		qui keep Index-Type e0_`fyear'
		list Place e0_`fyear' if Place=="`place'", clean noobs
		qui su e0_`fyear' if Place=="`place'" 
		loc surv `r(mean)'
	restore
	mata: surv= `surv'
																	}					   
if "`two'" == "" & "`surv'"!="" {
*Age-specific survival curve 
mata: s= L/n //Sx
mata: surv= `surv'
*Sigma represents the dynamic ratio required to rectangularize the survival
* curve. It varies as a function of the future value ex0, informed in `surv'.
* Sigma and alfa are optimized to predict a survival curve compatible with 
* the current age structure of Sx
preserve
	getmata s a
	mata: st_local("e0", strofreal(T[1], "%4.2f"))
	qui nl (s=1/(1+(a/(`e0'+{alfa}))^{sigma})), init(alfa 0) //nonlinear LS
restore
if "`sigma'"== "" {
	mata: st_local("sig1", strofreal(st_matrix("e(b)")[2], "%4.2f")) // sigma 
	mata: st_local("alf1", strofreal(st_matrix("e(b)")[1], "%4.2f")) // alfa
	mata: sigma=st_matrix("e(b)")[2]/T[1]*`surv' //future sigma
					}
if "`sigma'" != "" {
	mata: st_local("sig1", strofreal(`sigma', "%4.2f")) // sigma 
	mata: sigma=`sigma'/(T[1])*`surv' //future sigma
	preserve
		getmata s a
		mata: st_local("e0", strofreal(T[1], "%4.2f"))
		qui nl (s=1/(1+(a/(`e0'+{alfa}))^`sigma')), init(alfa 0) //nonlinear LS
	restore				
	mata: st_local("alf1", strofreal(st_matrix("e(b)")[1], "%4.2f")) // alfa
					}					
qui mata: alfa=optimize_alfa(sigma, surv) // future alfa providing `surv'

mata: Sf=1:/(1:+(a:/(`surv'+alfa)):^sigma) // adapted from Wilson (1994, 17). 		  
				  
*Linear Interpolation of age-specific probabilities of survival, which implies
*in linear gains in life expectancy over time
mata: fsurv=J(rows(M), period+1,.)
mata: fsurv[.,period+1]=Sf
mata: fsurv[.,1]=s
loc periodo= `period'-1
forval x=2/`periodo' { //Interpolation: Brass (1974), Celade (1984, 96)
	mata: fsurv[.,`x']=(`x'-1)/(period+1-1)*fsurv[.,period+1]+ ///
		(period+1-`x')/(period+1-1)*fsurv[.,1]		
					 }
mata: sf=J(rows(fsurv),cols(fsurv),.) //Proj. age-specific probs. of survival
forval x=1/`period' {
	mata: sf[.,`x']=fsurv[.,`x'] 
					 }

*Graph showing predicted survival scenarios= f(expected_e0)
//Current e0: approximated by the area under the survival curve
mata: st_local("e0", strofreal(sum(sf[.,1])*n, "%4.2f")) 
//last expected e0: also approximated by the area under the survival curve
mata: st_local("e02", strofreal(sum(sf[.,cols(sf)])*n, "%4.2f"))
mata: st_local("sig2", strofreal(sigma, "%4.2f")) //future sigma
mata: st_local("alf2", strofreal(alfa,  "%4.2f")) // future alfa
				  				  
preserve
	forval x=1/`period' { //Generates variables of projected sx
	mata: st_store(.,st_addvar("float","s`x'"),sf[.,`x'])
						 }
	qui des //Graphs age structure of survival probabilities
	loc pn=`r(k)'
	qui ds
	tokenize "`r(varlist)'"
	loc last_p =`period'+1
	line `5'-``pn'' `1', lwidth(vthick) ///
	|| line ``pn'' `1',  lp(dash_dot) lwidth(vthick) ///
	, ti() graphregion(fcolor(white)) ///
	ytitle(Age-specific Prob. of Survival (s{sub:x})) ///
	leg(on order(1 "{bf:Current period}" ///
	"(e{sub:0}{sup:}= `e0', {&alpha}= `alf1', {&sigma}= `sig1')" `last_p' ///
	"{bf:Last period}" "(e{sub:0}{sup:f}= `e02', {&alpha}{sup:f}= `alf2', {&sigma}{sup:f}= `sig2')") ///
	region(lc(%0)) pos(6) col(2) all) name(prob_surv, replace) ///
	note({it:Note}: Life expectancy at birth (e{sub:0}{sup:}) estimated ///
	as the area under the survival curve (S{sub:x})., span) `gropts'
restore 

*Execute forward projections with varying survival (i.e. fixed m)
forval z=1/`periodo' { //projections
	mata: M= subd(sf[.,`z'],sf[.,`z']*n,m) //places surv. ratios in off diagonal
	mata: fp[.,`z'+1]= M*fp[.,`z'] //assumes that only survival is changing
					 }
									}

*Fertility and Survival changing at the same time (i.e., varying m)
if "`two'"=="" & ("`fert'" != "" & "`surv'"!="") {
forval y=1/`periodo' { //projections
	mata: M= subd(sf[.,`y'],sf[.,`y']*n,f_asfr[`y']/n/(1+`srb'))
	if "`male'"!="" {
		mata: M= subd(sf[.,`y'],sf[.,`y']*n,f_asfr[`y']/n*(`srb'/(1+`srb')))				
					}
	mata: M[1,.]=fF[`y'+1,.]
	mata: fp[.,`y'+1]= M*fp[.,`y'] 	// assumes varying fertility and survival							
					  }
												 }

***********************************
*TWO-SEXES simultaneous projection*
***********************************
*FERTILITY*
***********
if "`two'" != "" & ("`fert'"!="" | "`baseline'"!="0") {
*Future net female ASFR rates in rows of fF
	mata: fF=J(period+1,cols(M),.)
	mata: fF[1,.]=M[1,.] // first row of projection matrix F^f (eq. 7)
	loc periodo= `period'-1
*Future net male ASFR rates in rows of fFm
	mata: fFm=J(period+1,cols(M),.)
	mata: fFm[1,.]=M[length(p)/2+1,.] // first row of proj. matrix F^m (eq. 7)

*Future ASFR rates in rows of fasfr_t
	mata: fasfr_t=J(length(f)/2,period+1,.)
	mata: fasfr_t[.,1]=f[1..length(f)/2,.] // ASFRs	
	
	if "`baseline'"=="0" & "`fert'" != "" {
		mata: r_fert= (`fert'/(colsum(f)*n))^(1/period)-1 //compound growth rate
	forval x=2/`period' { // future net female ASFR levels, same age pattern
		mata: fF[`x',.]=fF[`x'-1,.]+fF[`x'-1,.]*r_fert
						}
	forval x=2/`period' { // future net male ASFR, same age pattern
		mata: fFm[`x',.]=fFm[`x'-1,.]+fFm[`x'-1,.]*r_fert
						}
											}
	if "`baseline'"!="0" {
		if "`place'"!= "" {
		preserve
			use "wpp2024_median_fert.dta", replace
			loc fyear=`baseline'+(`period'-1)*`n'
			l Place Year TFR if Place== "`place'" & Year==`fyear', clean noobs
			qui putmata asfr_std=(asfr_10-asfr_50) if Place== "`place'" & ///
			Year==`fyear', replace
		restore
		mata: fasfr=J(1,rows(a),0)
		mata: fasfr[3..11]=asfr_std/1000*n //final ASFR values
							}
		if "`fert'"!="" {
		preserve
			use "wpp2024_median_fert.dta", replace
			mata: st_local("n", strofreal(n))
			loc fyear=`baseline'+(`period'-1)*`n'
			qui drop if Year!=`fyear'
			qui gen Abs_diff= abs(`fert'-TFR)
			sort Abs_diff
			l Place Year TFR Abs_diff in 1/5, clean
			qui gen asfr_std=1 in 1 // choosen pattern
			qui putmata asfr_std=(asfr_10-asfr_50) if asfr_std==1, replace
		restore
			mata: asfr_std=asfr_std/1000*n
			mata: asfr_std=asfr_std:/rowsum(asfr_std) //Shares of future TFR
			mata: fasfr=J(1,rows(a),0)
			mata: fasfr[3..11]=asfr_std*`fert' //final ASFR values
						}

		mata: r_fert= (fasfr':/(f*n)):^(1/period):-1
		forval x=2/`period' { //future female ASFR levels, borrowed pattern
			mata: fF[`x',.]=editmissing(fF[`x'-1,.]+fF[`x'-1,.]:*r_fert',0)
							}
		forval x=2/`period' { //future male ASFR levels, borrowed pattern
			mata: fFm[`x',.]=editmissing(fFm[`x'-1,.]+fFm[`x'-1,.]:*r_fert',0)
							}
																			
forval x=2/`period' { //future female ASFR levels, borrowed pattern
		mata: fasfr_t[.,`x']= editmissing(fasfr_t[.,`x'-1]+fasfr_t[.,`x'-1]:* ///
			r_fert[1..length(f)/2],0)
					}					
							}

if "`baseline'"=="0" & "`fert'" != "" {
	forval x=2/`period' { // future net female ASFR levels, same age pattern
		mata: fasfr_t[.,`x']=fasfr_t[.,`x'-1]+fasfr_t[.,`x'-1]*r_fert
						}
										}

*Graph of future net female/male ASFRs
mata: st_local("tfr", strofreal(colsum(f)*n, "%4.2f")) //current/first tfr
mata: st_local("tfr2", strofreal(colsum(fasfr_t[.,cols(fasfr_t)])*n,"%4.2f")) //last tfr
mata:st_local("fc_rate", strofreal(mean(r_fert)*100, "%4.2f")) //speed of change
mata:st_local("interval", strofreal(n, "%4.0f")) //length of age group

preserve
	qui des
	loc size=`r(N)'/2
	qui keep in 1/`size'
	forval x=1/`period' { //Generates variables of predicted ASFRs
	mata: st_store(.,st_addvar("float","fF`x'"), fasfr_t[.,`x'])
						 }
	qui des //Graphs age structure of age-specific fertility rates
	loc pn=`r(k)'
	qui ds
	tokenize "`r(varlist)'"
	qui keep if `1'<=50 & `1'>=10 // restricts graph to reproductive ages
	loc last_p =`period'+1
	line `5'-``pn'' `1', lwidth(vthick) ///
	|| line ``pn'' `1',  lp(dash_dot) lwidth(vthick) ///
	, graphregion(fcolor(white)) ytitle(ASFR) ti(Predicted Trajectory of Age ///
	Specific Fertility Rates) leg(on order(1 "Current" "period (TFR= `tfr')" ///
	`last_p' "Last" "period (TFR= `tfr2')") region(lc(%0)) pos(6) col(2) ///
	all) name(asfr, replace) note({it:Note}: Convergence speed corresponds ///
	to a `fc_rate'% change in TFR per `interval'-year period., span) `gropts'
restore

mata: fF_both= (select(a,fF'[.,1]:>0),J(rows(select(fF', fF'[.,1]:>0)),1,0), ///
	select(fF',fF'[.,1]:>0))\(select(a,fF'[.,1]:>0), ///
	J(rows(select(fFm'[1..rows(fFm')/2,.], fFm'[1..rows(fFm')/2,1]:>0)),1,1), ///
	select(fFm'[1..rows(fFm')/2,.], fFm'[1..rows(fFm')/2,1]:>0))
preserve
	drop *
	mata: st_local("obs", strofreal(rows(fF_both), "%4.0f")) 
	qui set obs `obs'
	loc last_p1 = `period'+1
	loc last_p =`period'+2
	forval x=1/`last_p' { //Gen vars. of predicted female/male ASFRs
	mata: st_store(.,st_addvar("float","m`x'"),fF_both[.,`x'])
						 }
	lab var m1 "Lower limit of the age group"
	lab define sex 0 "Net female ASFRs (f{sub:x})" ///
				   1 "Net male ASFRs (f{sub:x}{sup:m})"
	lab values m2 sex
	qui des
	loc pn=`r(k)'
	qui ds
	tokenize "`r(varlist)'"
	line `3'-``pn'' `1', by(m2, ti() ///
	note({it:Note}: Convergence speed: `fc_rate'% average change ///
	in TFR per `interval'-year period., span)) lwidth(vthick) ///
	|| line ``pn'' `1', by(m2) lp(dash_dot) lwidth(vthick) ///
	,  graphregion(fcolor(white)) yti("Average number of female/male births" ///
	"born to women of reproductive age") ///
	leg(off order(1 "{bf:Current period}" "(TFR= `tfr')" ///
	`last_p1' "{bf:Last period}" "(TFR= `tfr2')") ///
	region(lc(%0)) pos(6) col(2) all) name(asfr_both, replace)  `gropts'
restore				
															}
																			
*Execute forward projections with varying net female and male ASFRs
	if "`two'"!="" & (("`place'"!="" & "`surv'"=="") | "`fert'" != "") {					 
		forval x=2/`period' { //projections
			mata: M[1,.]= fF[`x',.]
			mata: M[length(p)/2+1,.]=fFm[`x',.]
			mata: fp[.,`x']= M*fp[.,`x'-1] // assumes that only TFR is changing
							}
																	  } 

**********
*SURVIVAL*
**********
*Gets final life expectancy from the World Population Prospects (WPP) file
if "`two'"!= "" & "`surv'"!="" & "`surv'"!="." & "`baseline'"!="0" ///
	& "`place'"=="" {
	tokenize `surv'
	preserve
		use "wpp2024_median_e0F.dta", replace
		loc fyear=`baseline'+(`period'-1)*`n'
		qui keep Index-Type e0_`fyear'
		qui gen Abs_diff= abs(e0_`fyear'-`1')
		sort Abs_diff
		rename e0_`fyear' Female_e0_`fyear'
		list Place Female_e0_`fyear' in 1/5, clean ab(14)
		
		use "wpp2024_median_e0M.dta", replace
		loc fyear=`baseline'+(`period'-1)*`n'
		qui keep Index-Type e0_`fyear'
		qui gen Abs_diff= abs(e0_`fyear'-`2')
		sort Abs_diff
		rename e0_`fyear' Male_e0_`fyear'
		list Place Male_e0_`fyear' in 1/5, clean ab(12)
	restore
					}
if "`two'"!= "" & "`surv'"==". ." & "`baseline'"!="0" & "`place'"!="" {
	preserve
		use "wpp2024_median_e0F.dta", replace
		loc fyear=`baseline'+(`period'-1)*`n'
		qui keep Index-Type e0_`fyear'
		rename e0_`fyear' Female_e0_`fyear'
		list Place Female_e0_`fyear' if Place=="`place'", clean noo ab(14) 
		qui su Female_e0_`fyear' if Place=="`place'" 
		loc surv_f `r(mean)'
		
		use "wpp2024_median_e0M.dta", replace
		loc fyear=`baseline'+(`period'-1)*`n'
		qui keep Index-Type e0_`fyear'
		rename e0_`fyear' Male_e0_`fyear'
		list Place Male_e0_`fyear' if Place=="`place'", clean noo ab(14) 
		qui su Male_e0_`fyear' if Place=="`place'" 
		loc surv_m `r(mean)'
	restore
	loc surv "`surv_f' `surv_m'"
																	}
if "`two'" != "" & "`surv'" != "" {
	mata: s= L/n //Sx
	
*Sex-specific sigma, alfa and survival curves
tokenize `surv'

*Females
qui des
loc fsize =`r(N)'/2	
mata: s_f=s[1..`r(N)'/2]
preserve
	getmata s a
	mata: st_local("e0_f", strofreal(T[1], "%4.2f"))
	qui nl (s=1/(1+(a/(`e0_f'+{alfa}))^{sigma})) in f/`fsize', init(alfa 0)
restore
if "`sigma'"== "" {
	mata: st_local("alf1_f", strofreal(st_matrix("e(b)")[1], "%4.2f")) // alfa
	mata: st_local("sig1_f", strofreal(st_matrix("e(b)")[2], "%4.2f")) // sigma 
	mata: sigma_f=st_matrix("e(b)")[2]/(T[1])*`1' //future sigma
	qui mata: alfa_f=optimize_alfat(sigma_f, `1') //future fem. alfa 				
mata: Sf_f=1:/(1:+(a[1..length(a)/2]:/(`1'+alfa_f)):^sigma_f) //fem. surv. curve				
					}
if "`sigma'" != "" {
	loc surv_f= `1' 
	loc surv_m= `2' 
	tokenize `sigma'
	mata: st_local("sig1_f", strofreal(`1', "%4.2f")) // sigma 
	mata: sigma_f=`1'/(T[1])*`surv_f' //future sigma
	preserve
		getmata s a
		mata: st_local("e0_f", strofreal(T[1], "%4.2f"))
		qui nl (s=1/(1+(a/(`e0_f'+{alfa}))^`1')) in f/`fsize', init(alfa 0) 
	restore				
	mata: st_local("alf1_f", strofreal(st_matrix("e(b)")[1], "%4.2f")) //alfa
	qui mata: alfa_f=optimize_alfat(sigma_f, `surv_f') //future fem. alfa				
mata: Sf_f=1:/(1:+(a[1..length(a)/2]:/(`surv_f'+alfa_f)):^sigma_f) //fem. surv. curve					
					}					
*Males
qui des
mata: s_m=s[`r(N)'/2+1..`r(N)']
preserve
	getmata s a
	mata: st_local("e0_m", strofreal(T[length(T)/2+1], "%4.2f"))
	qui des
	loc msize =`r(N)'/2+1
	qui nl (s=1/(1+(a/(`e0_m'+{alfa}))^{sigma})) in `msize'/l, init(alfa 0) //nonlinear LS
restore
if "`sigma'"== "" {
	mata: st_local("alf1_m", strofreal(st_matrix("e(b)")[1], "%4.2f")) // alfa
	mata: st_local("sig1_m", strofreal(st_matrix("e(b)")[2], "%4.2f")) // sigma 
	mata: sigma_m=st_matrix("e(b)")[2]/(T[length(T)/2+1])*`2' //future sigma
	qui mata: alfa_m=optimize_alfat(sigma_m, `2') //future male alfa
mata: Sf_m=1:/(1:+(a[1..length(a)/2]:/(`2'+alfa_m)):^sigma_m) //male surv. curve
				   }
				   
if "`sigma'" != "" {
	mata: st_local("sig1_m", strofreal(`2', "%4.2f")) // sigma 
	mata: sigma_m=`2'/(T[length(T)/2+1])*`surv_m' //future sigma
	preserve
		getmata s a
		mata: st_local("e0_m", strofreal(T[length(T)/2+1], "%4.2f"))
		qui nl (s=1/(1+(a/(`e0_m'+{alfa}))^`2')) in `msize'/l, init(alfa 0) 
	restore				
	mata: st_local("alf1_m", strofreal(st_matrix("e(b)")[1], "%4.2f")) //alfa
	qui mata: alfa_m=optimize_alfat(sigma_m, `surv_m') //future male alfa				
mata: Sf_m=1:/(1:+(a[1..length(a)/2]:/(`surv_m'+alfa_m)):^sigma_m) //male surv. curve
					}					

*Interpolation of survival curves
*Females
	mata: fsurv_f=J(rows(M)/2, period+1,.)
	mata: fsurv_f[.,period+1]=Sf_f
	mata: fsurv_f[.,1]=s_f
	loc periodo= `period'-1
forval x=2/`periodo' { // Brass (1974), Celade (1984, 96)
	mata: fsurv_f[.,`x']=(`x'-1)/(period+1-1)*fsurv_f[.,period+1]+ ///
		(period+1-`x')/(period+1-1)*fsurv_f[.,1]		
					 }
mata: sf_f=J(rows(fsurv_f),cols(fsurv_f),.) //Proj. age-specific probs. of surv.
forval x=1/`period' {
	mata: sf_f[.,`x']=fsurv_f[.,`x'] 
					 }
*Males
	mata: fsurv_m=J(rows(M)/2, period+1,.)
	mata: fsurv_m[.,period+1]=Sf_m
	mata: fsurv_m[.,1]=s_m
forval x=2/`periodo' { // Brass (1974), Celade (1984, 96)
	mata: fsurv_m[.,`x']=(`x'-1)/(period+1-1)*fsurv_m[.,period+1]+ ///
		(period+1-`x')/(period+1-1)*fsurv_m[.,1]		
					 }
mata: sf_m=J(rows(fsurv_m),cols(fsurv_m),.) //Proj. age-specific probs. of surv.
forval x=1/`period' {
	mata: sf_m[.,`x']=fsurv_m[.,`x'] 
					}
*Execute simultaneous two-sex projection only with varying survival
qui des
forval z=1/`periodo' { //projections
	mata: M[1..`r(N)'/2,1..`r(N)'/2]= subd(sf_f[.,`z'],sf_f[.,`z']*n, ///
														m[1..`r(N)'/2]) //M^f
	mata: M[`r(N)'/2+1..`r(N)',`r(N)'/2+1..`r(N)']= subd(sf_m[.,`z'], ///
								 sf_f[.,`z']*n,mm[1..`r(N)'/2]) //M^m
	mata: M[`r(N)'/2+1,1..`r(N)'/2]= M[`r(N)'/2+1,`r(N)'/2+1..`r(N)'] //F^m
	mata: M[`r(N)'/2+1,`r(N)'/2+1..`r(N)']= J(1,`r(N)'/2,0) //S^m
	mata: fp[.,`z'+1]= M*fp[.,`z'] //assumes that only survival is changing
					 }
									
*Graph of predicted survival scenarios, for females and males
*FEMALES
//Current female e0: area under the survival curve
mata: st_local("e0_f", strofreal(sum(sf_f[.,1])*n, "%4.2f")) 
//last expected female e0
mata:st_local("e02_f",strofreal(sum(sf_f[.,cols(sf_f)])*n,"%4.2f"))
mata: st_local("sig2_f", strofreal(sigma_f, "%4.2f")) //future fem. sigma
mata: st_local("alf2_f", strofreal(alfa_f, "%4.2f")) //future fem. alfa 				  
*MALES
//Current male e0: area under the survival curve
mata: st_local("e0_m", strofreal(sum(sf_m[.,1])*n, "%4.2f")) 
//last expected female e0
mata:st_local("e02_m",strofreal(sum(sf_m[.,cols(sf_m)])*n,"%4.2f"))
mata: st_local("sig2_m", strofreal(sigma_m, "%4.2f")) //future male sigma
mata: st_local("alf2_m", strofreal(alfa_m, "%4.2f")) //future fem. alfa 

mata: sf_both=J(rows(sf_f),1,0),sf_f\J(rows(sf_m),1,1),sf_m
preserve
	loc last_p =`period'+1
	forval x=1/`last_p' { //Generates variables of projected female and male sx
	mata: st_store(.,st_addvar("float","sf`x'"),sf_both[.,`x'])
						 }
	label define sex 0 "Female" 1 "Male"
	label values sf1 sex
	qui des //Graphs age structure of survival probabilities
	loc pn=`r(k)'
	qui ds
	tokenize "`r(varlist)'"
	line `6'-``pn'' `1', by(sf1, ti() ///
	note({it:Note}: Life expectancy at birth (e{sub:0}{sup:}) estimated as ///
	the area under the survival curve (S{sub:x})., span)) lwidth(vthick) ///
	|| line ``pn'' `1', by(sf1) lp(dash_dot) lwidth(vthick) ///
,  graphregion(fcolor(white)) ytitle(Age-specific Prob. of Survival (s{sub:x})) ///
	leg(off order(1 "{bf:Current period}" ///
	"Females: e{sub:0}{sup:}= `e0_f'" ///
	          "({&alpha}= `alf1_f', {&sigma}= `sig1_f')" ///
	"Males:   e{sub:0}{sup:}= `e0_m'" ///
							"({&alpha}= `alf1_m', {&sigma}= `sig1_m')" ///
	`last_p' "{bf:Last period}" ///
	"Females: e{sub:0}{sup:f}= `e02_f'" ///
			  "({&alpha}{sup:f}= `alf2_f', {&sigma}{sup:f}= `sig2_f')" ///
	"Males:   e{sub:0}{sup:f}= `e02_m'" ///
			  "({&alpha}{sup:f}= `alf2_m', {&sigma}{sup:f}= `sig2_m')") ///
	region(lc(%0)) pos(6) col(2) all) name(pr_surv_both, replace)  `gropts'
restore
									}

*Fertility and Survival changing at the same time, for both sexes

if "`two'" != "" & ("`fert'" != "" & "`surv'"!= "") {
qui des
forval z=1/`periodo' { //both-sexes simultaneous projections
	mata: M[1..`r(N)'/2,1..`r(N)'/2]= subd(sf_f[.,`z'],sf_f[.,`z']*n, ///
								fasfr_t[.,`z']/(1+`srb')) //M^f
	mata: M[`r(N)'/2+1..`r(N)',`r(N)'/2+1..`r(N)']= subd(sf_m[.,`z'], ///
								sf_f[.,`z']*n,fasfr_t[.,`z']/(1+1/`srb')) //M^m
	mata: M[1,.]= fF[`z'+1,.]
	mata: M[length(p)/2+1,.]=fFm[`z'+1,.]
	mata: fp[.,`z'+1]= M*fp[.,`z'] 	// assumes varying fertility and survival							
					  }
												    }
*******************************
*GRAPHS: projected populations*
*******************************
if "`two'" == "" & "`multistate'" == "" {
preserve
	forval x=2/`period' { // generates variables of projected pops.
	mata: st_store(.,st_addvar("float","fp`x'"),fp[.,`x'])
						}
	qui des //Graphs size of projected populations
	loc pn=`r(k)'
	qui ds
	tokenize "`r(varlist)'"
	line `5'-``pn'' `1', lwidth(vthick) ///
	|| line ``pn'' `1',  lp(dash_dot) lwidth(vthick) ///
	, graphregion(fcolor(white)) ytitle(Size of projected population) ///
	  legend(on order(1 "First projection" `period' "Last projection") ///
	  region(lc(%0)) pos(6) col(2) all) name(proj, replace) `gropts'
restore

mata: fpt=fp\colsum(fp)
mata: st_matrix("fp_x", round(fpt)[.,2..`period'])
preserve
	gen str_age=string(`1')
	gen str_age_1=string(`1'[_n+1]-1)
	gen row_label=str_age + "-" + str_age_1
	qui replace row_label=str_age[_N]+"+" in l
	forval i=1/`=_N' {
		loc row_lab "`row_lab' `=row_label[`i']'"			
					 }
restore

if "`baseline'"!="0" {
preserve 
	drop _all 
	loc periodo= `period'-1
	qui set obs `periodo'
	qui gen col_label= `baseline'+`n' in 1
	forval c=2/`periodo' {
		qui replace col_label=col_label[_n-1]+`n' in `c'
						  }
forval c= 1/`=_N' {
	loc col_lab "`col_lab' `=col_label[`c']'"			
				  }
restore
					  }
					  
matrix rownames fp_x= `row_lab' Total
matrix colnames fp_x= `col_lab'

matlist fp_x, tit("Projected population in each age group") ///
	format(%10.0f) row(Age group) aligncolnames(r) tw(9) lin(rowt)
return mat proj = fp_x // Returns projected pop. as a system matrix
											}
if "`two'" != "" {
preserve
	gen count=_n
	qui su
	gen pyra=cond(count<=`r(N)'/2,1,-1) // vector 1,-1 to generate pyramid
	forval x=2/`period' {
		mata: st_store(.,st_addvar("float","fp`x'"),fp[.,`x'])
		qui replace fp`x'= pyra*fp`x'/1000
						}
	drop count pyra		
	qui des //Graphs size of projected populations
	loc pn=`r(k)'
	loc size = `r(N)'/2
	loc size1 = `r(N)'/2+1
	qui ds
	tokenize "`r(varlist)'"
	line `5'-``pn'' `1' in f/`size', lc(black) lwidth(vthick) lp(solid) ///
	|| line ``pn'' `1' in f/`size',  lc(gray) lwidth(vthick) lp(dash_dot) ///
	|| line `5'-``pn'' `1' in `size1'/l, lc(black) lw(vthick) lp(solid) ///
	|| line ``pn'' `1' in `size1'/l, lc(gray) lw(vthick) lp(dash_dot) ///
	|| line ``pn'' `1' in `size1'/l, yscale(ax(2)) ylabel(none,axis(2)) ///
	yti("Female                 Male", axis(2) orient(rvertical)) ///
	yaxis(2) lc(blue%15) lw(none)  yline(0) ///
		, xlabel(#`size', angle(rvertical) value) xscale(extend nolin) ///
		ylabel(, angle(rvertical)) graphregion(fcolor(white)) ///
		ytitle(Size of projected population (per 1000), orient(rvertical)) ///
	  legend(on order(1 "First projections" `period' "Last projections") ///
	  region(lc(%0)) pos(6) col(2) all) name(projtwo, replace) `gropts'
restore

mata: ffp= fp[1..length(p)/2,.] //female projected population
mata: mfp= fp[(length(p)/2)+1..length(p),.] //male projected population
mata: ffpt=ffp\colsum(ffp) // female pop. w/ totals
mata: mfpt=mfp\colsum(mfp) // male pop. w/ totals

*Females
mata: st_matrix("ffp_x", round(ffpt)[.,2..`period'])
qui levelsof `1', local(rows)
preserve
	gen str_age=string(`1')
	gen str_age_1=string(`1'[_n+1]-1)
	gen row_label=str_age + "-" + str_age_1
	qui replace row_label=str_age[_N]+"+" in l
	forval i=`size1'/`=_N' {
		loc row_lab "`row_lab' `=row_label[`i']'"			
					 }
restore

if "`baseline'"!="0" {
preserve 
	drop _all 
	loc periodo= `period'-1
	qui set obs `periodo'
	qui gen col_label= `baseline'+`n' in 1
	forval c=2/`periodo' {
		qui replace col_label=col_label[_n-1]+`n' in `c'
						  }
forval c= 1/`=_N' {
	loc col_lab "`col_lab' `=col_label[`c']'"			
				  }
restore
						}

mata: st_local("n", strofreal(n))
matrix rownames ffp_x= `row_lab' Total
matrix colnames ffp_x= `col_lab'
matlist ffp_x, tit("Projected female population in each age group") ///
	format(%10.0f) row(Age group) aligncolnames(r) tw(9) lin(rowt)
return mat fproj = ffp_x // Returns proj. pop. as a system matrix

*Males
mata: st_matrix("mfp_x", round(mfpt)[.,2..`period'])
*qui levelsof `1', local(rows)
matrix rownames mfp_x= `row_lab' Total
matrix colnames mfp_x= `col_lab'
matlist mfp_x, tit("Projected male population in each age group") ///
	format(%10.0f) row(Age group) aligncolnames(r) tw(9) lin(rowt)
return mat mproj = mfp_x // Returns proj. pop. as a system matrix
				  }		  
if "`multistate'" != "" {
preserve 
	qui ds
	tokenize "`r(varlist)'"
	qui des
	keep `1' ``r(k)''
	qui su
	loc ageg=round(`r(N)'/`r(max)'/2)
	forval x=2/`period' {
		mata: st_store(.,st_addvar("float","fp`x'"),fp[.,`x'])
		qui replace fp`x'= fp`x'/1000	
						}
	qui des //Graphs size of projected pops. by state
	loc pn=`r(k)'
	loc last=`pn'-1
	qui ds
	tokenize "`r(varlist)'"
	line `3'-``pn'' `1', lw(vthick) ///
	|| line ``pn'' `1',  lw(vthick) lp(dash_dot) ///
	, by(`2', style(stata7) noedgelabel) legend(region(lc(%0)) pos(6) ///
	col(2) all order(1 "First" "projections" `last' "Last" "projections")) ///
	ytitle(Size of projected population (per 1000)) ///
	xlabel(#`ageg') name(multi, replace) `gropts'
restore
qui ds
tokenize "`r(varlist)'"
*qui levelsof `1', local(rows)

preserve
	qui su
	gen str_age=string(age)
	gen str_age_1=string(age[_n+1]-1)
	gen row_label=str_age + "-" + str_age_1
	qui replace row_label=str_age[_N]+"+" in l
	loc init_last=`r(N)'-`r(N)'/`r(max)'+1
	forval i=`init_last'/`=_N' {
		loc row_lab "`row_lab' `=row_label[`i']'"			
							   }
restore

qui su ``r(k)''
*mata: st_local("n", strofreal(n))
forval x=1/`r(max)' {
	mata: st_matrix("fps`x'",round(panelsubmatrix(fp,`x',info)\ ///
		colsum(panelsubmatrix(fp,`x',info)))[.,2..`period'])
	matrix rownames fps`x'= `row_lab' Total				
	matlist fps`x', tit("Projected population by age group in state `x'") ///
		format(%10.0f) row(Age group) aligncolnames(c) tw(9) lin(rowt) 				
	return mat mproj`x'= fps`x'				
					 }
						}

*****************
*STABLE ANALYSIS*
*****************
if "`stable'" == "stable" {
mata: values = J(0,0,.)
mata: vectors = J(0,0,.)
mata: eigensystem(M, vectors, values) //Stable analysis using eigenvalues
if "`two'" == "" & "`multistate'"=="" {
mata: r0= log(values[1])/n //Intrinsic yearly growth rate
mata: stable0= Re(vectors[,1]/sum(vectors[,1])) //Stable age structure   
mata: r1= newton(nrr,a,L,m)[.,1] //Newton's approximation
mata: stable1= 1/sum(exp(-r1*a):*L)*exp(-r1*a):*L				   
mata: no= no(r0,M) //projection periods to stability
mata: st_local("no",strofreal(no))
loc no=`no'+1
mata: fps=J(st_nobs(),`no',0) // projected population to stability
mata: fps[.,1] = p
mata: cs=J(st_nobs(),`no',0)				 
mata: cs[.,1] = p/colsum(p)
forval x=2/`no' {
mata: fps[.,`x']= M*fps[.,`x'-1] // population projections
mata: cs[.,`x']= fps[.,`x']/colsum(fps[.,`x']) //age structure of proj pops.
				}
mata: stable2= cs[.,`no']
mata: statio= L/T[1]
mata: ytos= no*n // approximate # of years to stability, given set tolerance
mata: stables= cs[.,1], stable0, stable1, stable2, statio
mata: st_matrix("stables",stables*100)
mat colnames stables= Current Eigen Newton Projected* Stationary
mat rownames stables=`rows' 
mata: st_local("n", strofreal(n))
matlist stables, tit("Age structure of current and stable-equivalent" ///
	"populations: percent between ages x and x+`n'") ///
	format(%10.4f) row(Age x) aligncolnames(r) tw(5) border(bottom)
mata: st_local("x", strofreal(ytos))
loc note= "*Convergence to stability achieved after about `x' years."
di "`note'"
return mat stable = stables //Returns pop. struct. as a sys. matrix	
preserve
	forval x=1/5 { // generates variables of stable age structures
	mata: st_store(.,st_addvar("float","stable`x'"),stables[.,`x']*100)
				 }
	qui des //Graphs size of projected populations
	loc var=`r(k)'
	qui ds
	tokenize "`r(varlist)'"
	line `5'-``var'' `1', lc(black%75 gs12%65 gs8%75 gs4%85 gs0%95) ///
		lwidth(vvthick vvthick vthick thick medthick) lpat(solid solid dash dot ///
		solid) , graphregion(fcolor(white)) ytitle(Age structure (%)) ///
		legend(on order(1 "Current" 2 "Stable (Eigen)" 3 "Stable (Newton)" ///
		4 "Stable (Projected)" 5 "Stable (Stationary)") region(lc(%0)) ///
		pos(6) col(2) all) name(stable, replace) `gropts'
restore				 
										}
if "`two'" != "" {
mata: mr0= log(values[1])/n // intrinsic male rate
mata: fr0= log(values[2])/n // intrinsic female rate
mata: stable0= J(length(p),1,.) // females on top and males at the bottom
mata: stable0[1..(length(p)/2)]= Re(vectors[1..length(p)/2,1]/ ///
								sum(vectors[1..length(p)/2,1])) 
mata: stable0[(length(p)/2)+1..length(p)]= Re(vectors[(length(p)/2)+ ///
			1..length(p),1]/sum(vectors[(length(p)/2)+1..length(p),1]))
mata: fps= J(st_nobs(),50,0) // projected pop. to stability (50 periods)
mata: fps[.,1] = p
mata: cs= J(st_nobs(),50,0) // females on top and males at the bottom	 
mata: cs[1..length(p)/2,1]= p[1..length(p)/2]/colsum(p[1..length(p)/2])
mata: cs[(length(p)/2)+1..length(p),1]=p[(length(p)/2)+1..length(p)]/ ///
									colsum(p[(length(p)/2)+1..length(p)])
forval x=2/50 { //age structures of projected populations
	mata: fps[.,`x']=M*fps[.,`x'-1] // population projections
	mata: cs[1..length(p)/2,`x']=fps[1..length(p)/2,`x']/ /// //female
				colsum(fps[1..length(p)/2,`x']) 
	mata: cs[(length(p)/2)+1..length(p),`x']=fps[(length(p)/2)+ /// //male 
				1..length(p),`x']/colsum(fps[(length(p)/2)+1..length(p),`x'])	
			  }
mata: stable2=cs[.,50]
mata: statio=J(length(L),1,0)
mata: statio[1..length(L)/2]=L[1..length(L)/2]/T[1] //females
mata: statio[(length(L)/2)+1..length(L)]=L[(length(L)/2)+1..length(L)]/ ///
											T[(length(L)/2)+1] //males
mata: stables= cs[.,1], stable0, stable2, statio
*Female stable-equivalent
mata: st_matrix("fstables",stables[1..length(p)/2,.]*100)
mat colnames fstables= Current Eigen Projected* Stationary
mat rownames fstables=`rows'
mata: st_local("n", strofreal(n))
matlist fstables, tit("Female age structure of current and" ///
	"stable-equivalent populations: percent between ages x and x+`n'") ///
	format(%10.4f) row(Age x) aligncolnames(r) tw(5) border(bottom)
return mat fstable= fstables
*Male stable-equivalent
mata: st_matrix("mstables",stables[(length(p)/2)+1..length(p),.]*100)
mat colnames mstables= Current Eigen Projected* Stationary
mat rownames mstables=`rows'
mata: st_local("n", strofreal(n))
matlist mstables, tit("Male age structure of current and" ///
	"stable-equivalent populations: percent between ages x and x+`n'") ///
	format(%10.4f) row(Age x) aligncolnames(r) tw(5) border(bottom)
mata: st_local("x", strofreal(50*n))
loc note= "*After `x' years."
di "`note'"
return mat mstable= mstables //Returns pop. structures as a system matrix	
preserve
	mata: stables=stables[1..length(p)/2,.]\ ///
					stables[(length(p)/2)+1..length(p),.]*-1
	forval x=1/4 { // generates variables of stable age structures
		mata: st_store(.,st_addvar("float","stable`x'"),stables[.,`x']*100)
				 }
	qui des //Graphs size of projected populations
	loc var=`r(k)'
	qui ds
	tokenize "`r(varlist)'"
	qui su
	loc size= `r(N)'/2
	loc size1=`r(N)'/2+1
	line `5'-``var'' `1' in 1/`size', ///
		lc(black%75 gs12%65 gs8%75 gs4%85 gs0%95) ///
		lwid(vvthick vvthick vthick thick medthick) ///
		lp(solid solid dash dot solid) ///
	|| line `5'-``var'' `1' in `size1'/`r(N)',  ///
		lc(black%75 gs12%65 gs8%75 gs4%85 gs0%95) ///
		lwid(vvthick vvthick vthick thick medthick) ///
		lp(solid solid dash dot	solid) ///
	|| line ``var'' `1' in `size1'/`r(N)', yscal(ax(2)) ylabe(none,axis(2)) ///
		yti("Female                 Male", axis(2) orient(rvertical)) ///
		yaxis(2) lc(blue%15) lw(none)  yline(0) ///
		, xlabel(#`size', angle(rvertical) value) xscale(extend nolin) ///
		, graphregion(fcolor(white)) ylabel(, angle(rvertical)) ///
		ytitle(Age structure (%), orient(rvertical)) ///
		leg(on order(1 "Current" 2 "Stable (Eigen)" 3 "Stable (Projected)" ///
		4 "Stable (Stationary)") region(lc(%0)) ///
		pos(6) col(2) all) name(stabletwo, replace) `gropts'
restore
					}
if "`multistate'" != "" {
mata: r0= log(values[1])/n //intrinsic growth rate 
qui des
*mata: stable0=J(length(p)/max(st_data((1,st_nobs()),`r(k)')),1,.)
mata: fps=J(st_nobs(),50,0) //projected pop. to stability (50 periods)
mata: fps[.,1]= p
forval x=2/50 { //pop. projections for 50 periods
	mata: fps[.,`x']= M*fps[.,`x'-1] 
			  }
qui su			  
forval x=1/`r(max)' {
	mata: stable0`x'=panelsubmatrix(vectors,`x',info)[.,1]/ ///
			colsum(panelsubmatrix(vectors,`x',info)[.,1])
	mata: cs`x'= panelsubmatrix(p,`x',info)/colsum(panelsubmatrix(p,`x',info))
	mata: csp`x'=panelsubmatrix(fps[.,50],`x',info)/ ///
					colsum(panelsubmatrix(fps[.,50],`x',info))			
	mata: stables`x'=cs`x',Re(stable0`x'),csp`x'			
	mata: st_matrix("stables`x'",stables`x'*100)
	mat rownames stables`x'= `rows'
	mat colnames stables`x'= Current Eigen Projected*
	mata: st_local("n", strofreal(n))
	matlist stables`x', tit("Age structure of current and" ///
	"stable-equivalent populations in state `x': percent between ages x and x+`n'") ///
		format(%10.4f) row(Age x) aligncolnames(r) tw(5) border(bottom) 				
	mata: st_local("z", strofreal(50*n))
	loc note= "*After `z' years."
	di "`note'"
	return mat mstable`x'= stables`x'
					}			
preserve 
	mata: age= st_data((1,st_nobs()),1)
	qui des
	mata: state= st_data((1,st_nobs()),`r(k)')
	clear
	getmata age state
	qui su
	loc ageg=round(`r(N)'/`r(max)'/2)
	
	mata: pilems= J(0,cols(stables1),.)
	forval x=1/`r(max)' {
		mata: pilems=pilems\stables`x'
						}
	forval x=1/3 {
	mata: st_store(.,st_addvar("float","pilems`x'"),pilems[.,`x']*100)
				 }
	qui des //Graphs size of projected populations by state
	loc pn=`r(k)'
	*loc last=`pn'-1
	qui ds
	tokenize "`r(varlist)'"
	line `3'-``pn'' `1', lc(black%75 gs12%65 gs8%75) ///
		lwidth(vthick vthick thick) lp(solid solid dot) ///
		, by(state, style(stata7) noedgelabel) legend(region(lc(%0)) pos(6) ///
		col(2) all order(1 "Current" 2 "Stable (Eigen)" 3 "Stable (Projected)")) ///
		ytitle(Age structure (%), orient(rvertical)) ///
		xlabel(#`ageg') name(stablemulti, replace) `gropts'
restore
						}					     
						   }

******************
*SUMMARY MEASURES*
******************
if "`summary'" == "summary" {
if "`two'"=="" & "`multistate'"=="" {
mata: m1= T[1] //Life expec. at birth, e0= Mean age at death in stationary pop.
qui des
loc temp= `r(N)'-1
mata: deaths=J(`temp',1,0)
forval x=1/`temp' {
	mata: deaths[`x',.]=fp[`x',1]-fp[`x'+1,2] //Cohort estimates
				  }
mata: deaths[`temp',.]= fp[`r(N)'-1,1]+fp[`r(N)',1]-fp[`r(N)',2]
mata: m2= sum(range(n,max(st_data(.,1)),n):*deaths)/sum(deaths) //Mean age at death
mata: m3= colsum(a:*p)/colsum(p) //Mean age of the population
mata: m4=ln(nrr)/newton(nrr, a, L, m)[.,1] //T(Preston et al 2001: 152).
		/*"(...)the length of time needed for a population to increase
		by a factor equal to its NRR" (Schoen 1988: 45).*/
mata: m5= sum(a:*(m/nrr):*L) //Mean age of the maternity schedule
mata: m6= newton(nrr, a, L, m)[.,2] //Mean age of childbear. in stable pop.
mata: m7= colsum(f)*n //Period TFR
mata: m8= colsum(m)*n //Gross reproduction rate (GRR) 
mata: m9= sum (L :* m) //Net reproduction rate (NRR)
mata: m10= sum(p:*m)/sum(p) //Crude birth rate (CBR), assuming a fem. pop.(p)
mata: m11= 1/sum(exp(-newton(nrr,a,L,m)[.,1]*a):*L) //Intrinsic birth rate (b)
mata: m12= m11-newton(nrr, a, L, m)[.,1] //Intrinsic death rate (d)
mata: m13= newton(nrr, a, L, m)[.,1] //Intrinsic growth rate (r)
mata:	values = J(0,0,.)
mata:	vectors = J(0,0,.)
mata:	eigensystem(M, vectors, values) //Stable analysis using eigenvalues
mata:	r0= log(values[1])/n //Intrinsic yearly growth rate
mata:	stable0= Re(vectors[,1]/sum(vectors[,1])) //Stable age structure
mata: m14= colsum(abs((p:/colsum(p))-stable0))*.5 //Keyfitz's delta (1968:47)
if "`keyfitz'"== "" {
	mata: m15= no(r0,M)*n //Years to stability
					}
if "`keyfitz'"!= "" {
	mata: m15= no2(stable0,M)*n				
					}
mata:	gr=J(2,4,.)
mata:	gr(r0,M,gr)
*mata: m16= gr[2,1]*n // Years to stability (upper band)
mata: m16=(sum(select(p,st_data(.,1):<=`ygual'))+ ///
			sum(select(p,st_data(.,1):>=65)))/(sum(p)- ///
			(sum(select(p,st_data(.,1):<=`ygual'))+ ///
		   sum(select(p,st_data(.,1):>=65))))*100 // total age dependency ratio
mata: m17= gr[1,1]*n // Years of growth before first decline
mata: m18= gr[1,2] // Pop. relative(%) size when decline starts
mata: m19= gr[2,2] // Pop. relative(%) size in stability
mata: m20= m11*T[1]/sqrt(nrr) // Momentum (Frauenthal 1975)
mata:	ba=m/nrr:*L
mata:	w=n*(ba/2+(sum(ba):-runningsum(ba))):/(sum(a:*ba))
mata:	m21=sum(w:*(p/colsum(p)):/(L/T[1])) //Momentum (Preston-Guillot 1997)
mata:	measures=J(21,1,.) //places measures in a matrix
	 
forval x=1/21 {
	mata: measures[`x',.]=m`x'
			   }
mata: st_matrix("su",measures)
mat colnames su= Value
mat rownames su= "Life_expectancy_at_birth(e0)" "Mean_age_at_death" ///
	"Mean_age_of_the_population" "Mean_length_of_generation" ///
	"Mean_age_at_maternity" "Mean_age_at_maternity*" ///
	"Total_fertility_rate(TFR)" "Gross_reproduction_rate(GRR)" ///
	"Net_reproduction_rate(NRR)" "Crude_birth_rate(CBR)"  ///
   "Intrinsic_birth_rate(b)" "Intrinsic_death_rate(d)" ///
   "Intrinsic_growth_rate(r)" "Keyfitz's_delta" "Years_to_stability" ///
   "Total_age_dependency_ratio(%)" "Years_of_positive_growth" /// 
   "Proj./obs._when_decline_starts" "Proj./obs._in_stability" ///
   "Momentum_(Frauenthal_1975)" "Momentum_(Preston-Guillot_1997)" 
matlist su, tit("Summary measures for the baseline population") row(Measure) ///
	aligncolnames(c) underscore border(bottom)  ///
	cspec(& L %32s|%10.4f &) rspec(--&&&&&&&&&&&&&&&&&&&&-)
loc note= "*In the stable population."
di "`note'"
return mat summary = su // Returns measures as a system matrix	
										}
if "`two'"!="" {
mata: fm1= T[1] //Life expec. at birth
mata: mm1= T[(length(L)/2)+1]
qui su
loc temp= `r(N)'/2-2
*Female deaths and mean age at death
mata: f_deaths=J(`temp',1,0)
forval x=1/`temp' {
	mata: f_deaths[`x',.]=fp[`x',1]-fp[`x'+1,2] //Cohort estimates
				  }
mata: f_deaths= f_deaths\ fp[`r(N)'/2-1,1]+fp[`r(N)'/2,1]-fp[`r(N)'/2,2]
mata: fm2= mean(range(n,max(st_data(.,1)),n),f_deaths)
*Male deaths and mean age at death
mata: m_deaths=J(`temp',1,0)
forval x=1/`temp' {
	mata: m_deaths[`x',.]=fp[`x'+`r(N)'/2,1]-fp[`x'+`r(N)'/2+1,2] //Cohort estimates
				  }
mata: m_deaths= m_deaths\ fp[`r(N)'-1,1]+fp[`r(N)',1]-fp[`r(N)',2]  
mata: mm2= mean(range(n,max(st_data(.,1)),n),m_deaths)

mata: fm3= colsum(a[1..(length(p)/2)]:*p[1..(length(p)/2)])/ ///
			colsum(p[1..(length(p)/2)]) //Female mean age of the population
mata: mm3= colsum(a[(length(p)/2)+1..(length(p))]:* /// Male mean age
			p[(length(p)/2)+1..(length(p))])/colsum(p[(length(p)/2)+1..(length(p))])
mata: fm4= ln(fnrr)/newton(fnrr, a[1..(length(p)/2)], L[1..(length(p)/2)], ///
			m[1..(length(p)/2)])[.,1] //female T(Preston et al 2001: 152)
mata: mm4=ln(mnrr)/newton(mnrr, a[(length(a)/2)+1..(length(a))], ///
			L[(length(L)/2)+1..(length(L))], mm[1..(length(p)/2)])[.,1] //T
mata: fm5= sum(a[1..(length(p)/2)]:*(m[1..(length(p)/2)]/fnrr):* ///
			L[1..(length(p)/2)]) //Mean age of the maternity schedule
mata: mm5= sum(a[(length(a)/2)+1..(length(a))]:*(mm[1..(length(p)/2)]/mnrr):* ///
			L[(length(L)/2)+1..(length(L))]) //Mean age of the maternity
mata: fm6= newton(fnrr, a[1..(length(a)/2)], L[1..(length(L)/2)], ///
			m[1..(length(p)/2)])[.,2] //Mean age of childbear. in stable pop.
mata: mm6= newton(mnrr, a[(length(a)/2)+1..(length(a))], L[(length(L)/ ///
			2)+1..(length(L))],	mm[1..(length(p)/2)])[.,2] //Male child's mean age 
mata: fm7= colsum(f)*n //Period TFR
mata: mm7= colsum(f)*n //Period TFR
mata: fm8= colsum(m)*n //female Grr(GRR) 
mata: mm8= colsum(mm)*n //male Grr(GRR)
mata: fm9= sum(L[1..(length(L)/2)]:*m[1..(length(p)/2)]) //female NRR
mata: mm9= sum(L[(length(L)/2)+1..(length(L))]:*mm[1..(length(p)/2)]) //male NRR
mata: fm10= sum(p[1..(length(p)/2)]:*m[1..(length(p)/2)])/ ///
			sum(p[1..(length(p)/2)]) //CBR, female pop.
mata: mm10=sum(p[(length(p)/2)+1..(length(p))]:*mm[1..(length(p)/2)])/ ///
			sum(p[(length(p)/2)+1..(length(p))]) //CBR, male pop.
mata: fm11= 1/sum(exp(-newton(fnrr,a[1..(length(a)/2)],L[1..(length(L)/2)], ///
			m[1..(length(p)/2)])[.,1]*a[1..(length(a)/2)]):* ///
			L[1..(length(L)/2)]) //female b
mata: mm11= 1/sum(exp(-newton(mnrr,a[(length(a)/2)+1..(length(a))], ///
		L[(length(L)/2)+1..(length(L))],mm[1..(length(p)/2)])[.,1]* ///
		a[(length(a)/2)+1..(length(a))]):*L[(length(L)/2)+1..(length(L))]) //male b
mata: fm12= fm11-newton(fnrr, a[1..(length(p)/2)], L[1..(length(p)/2)], ///
		m[1..(length(p)/2)])[.,1] //female (d)
mata: mm12= mm11-newton(mnrr, a[(length(a)/2)+1..(length(a))], ///
		L[(length(L)/2)+1..(length(L))], mm[1..(length(p)/2)])[.,1] //male (d)
mata: fm13= newton(fnrr, a[1..(length(p)/2)], L[1..(length(p)/2)], ///
		m[1..(length(p)/2)])[.,1] //female (r)
mata: mm13= newton(mnrr, a[(length(a)/2)+1..(length(a))], ///
		L[(length(L)/2)+1..(length(L))], mm[1..(length(p)/2)])[.,1] //male (r)
mata: values = J(0,0,.)
mata: vectors = J(0,0,.)
mata: eigensystem(M, vectors, values) //Stable analysis using eigenvalues
mata: mr0= log(values[1])/n //male Intrinsic yearly growth rate 
mata: fr0= log(values[2])/n //female Intrinsic yearly growth rate
mata: stable0=J(length(p),1,.)
mata: stable0[1..(length(p)/2)]= Re(vectors[1..(length(p)/2),1]/ ///
								sum(vectors[1..(length(p)/2),1])) //female
mata: stable0[(length(p)/2)+1..(length(p))]= Re(vectors[(length(p)/2)+ ///
		1..(length(p)),1]/sum(vectors[(length(p)/2)+1..(length(p)),1])) //male
mata: fm14= .5*sum(abs(p[1..length(p)/2]:/sum(p[1..length(p)/2])- ///
	stable0[1..length(p)/2])) // female Keyfitz's delta (1968:47)
mata: mm14= sum(abs(p[length(p)/2+1..(length(p))]:/sum(p[length(p)/ ///
	2+1..length(p)])-stable0[length(p)/2+1..length(p)]))*.5 // male Keyfitz's D
mata: fm15= fm11*T[1]/sqrt(fnrr) //female Momentum (Frauenthal 1975)
mata: mm15= mm11*T[(length(L)/2)+1]/sqrt(mnrr) //male Momentum (Frauenthal 1975)
mata: fba=m[1..(length(p)/2)]/fnrr:*L[1..(length(p)/2)]
mata: mba=mm[1..(length(p)/2)]/mnrr:*L[(length(L)/2)+1..(length(L))]
mata: fw=n:*(fba:/2+(sum(fba):-runningsum(fba))):/ ///
			(sum(a[1..(length(p)/2)]:*(m[1..(length(p)/2)]/fnrr):* ///
			L[1..(length(p)/2)]))
mata: mw=n:*(mba:/2+(sum(mba):-runningsum(mba))):/ ///
			(sum(a[(length(a)/2)+1..(length(a))]:* ///
			(mm[1..(length(p)/2)]/mnrr):*L[(length(L)/2)+1..(length(L))]))
mata: fm16=sum(fw:*(p[1..(length(p)/2)]/colsum(p[1..(length(p)/2)])):/ ///
			(L[1..(length(p)/2)]/T[1])) // female Momentum(Preston-Guillot 1997)
mata: mm16=sum(mw:*(p[(length(p)/2)+1..(length(p))]/ ///
		colsum(p[(length(p)/2)+1..(length(p))])):/ ///
		(L[(length(L)/2)+1..(length(L))]/T[(length(L)/2)+1])) //male Momentum
			
mata: fm17=(sum(select(p[1..length(p)/2], ///
	st_data(.,1)[1..(length(p)/2)]:<=`ygual'))+ sum(select(p[1..length(p)/2], ///
	st_data(.,1)[1..(length(p)/2)]:>=65)))/(sum(p[1..length(p)/2])- ///
	(sum(select(p[1..length(p)/2],st_data(.,1)[1..(length(p)/2)]:<=`ygual'))+ ///
	sum(select(p[1..length(p)/2], ///
	st_data(.,1)[1..(length(p)/2)]:>=65))))*100 //female age dep.ratio
mata: mm17=(sum(select(p[(length(p)/2)+1..(length(p))], ///
	st_data(.,1)[(length(p)/2)+1..(length(p))]:<=`ygual'))+ ///
	sum(select(p[(length(p)/2)+1..(length(p))], ///
	st_data(.,1)[(length(p)/2)+1..(length(p))]:>=65)))/ ///
	(sum(p[(length(p)/2)+1..(length(p))])- ///
	(sum(select(p[(length(p)/2)+1..(length(p))], ///
	st_data(.,1)[(length(p)/2)+1..(length(p))]:<=`ygual'))+ ///
	sum(select(p[(length(p)/2)+1..(length(p))], ///
	st_data(.,1)[(length(p)/2)+1..(length(p))]:>=65))))*100 //male age dep.ratio

mata: measures=J(17,2,.) //places measures in a matrix						
forval x=1/17 { 
	mata: measures[`x',1]=fm`x' //female measures
	mata: measures[`x',2]=mm`x' //male measures
			  }
mata: st_matrix("su",measures)
mat colnames su= Female Male
mat rownames su= "Life_expectancy_at_birth(e0)" "Mean_age_at_death" ///
	"Mean_age_of_the_population" "Mean_length_of_generation" ///
	"Mean_age_at_maternity" "Mean_age_at_maternity*" ///
	"Total_fertility_rate(TFR)" "Gross_reproduction_rate(GRR)" ///
	"Net_reproduction_rate(NRR)" "Crude_birth_rate(CBR)"  ///
   "Intrinsic_birth_rate(b)" "Intrinsic_death_rate(d)" ///
   "Intrinsic_growth_rate(r)" "Keyfitz's_delta" ///
   "Momentum_(Frauenthal_1975)" "Momentum_(Preston-Guillot_1997)" ///
   "Total_age_dependency_ratio(%)"
matlist su, tit("Summary measures for the baseline populations") row(Measure) ///
	aligncolnames(c)  underscore border(bottom)	///
	cspec(& L %32s|%10.4f|%10.4f &) rspec(--&&&&&&&&&&&&&&&&-)
loc note= "*In the stable population."
di "`note'"
return mat summary = su // Returns measures as a system matrix
				}											
if "`multistate'"!="" {
*Life expectancies according to Rogers: T(x)l(x)^-1 (1995, 91)
*Calculating T(x)
qui su
loc n=`r(N)'/`r(max)'
forval x=1/`n' {
	mata: T`n'= L`n'
	loc index =`n'-`x'
	loc index2=`index'+1
	mata: L0=J(rows(T`n'), cols(T`n'),0) //calculated but ignored
	mata: T`index'= T`index2'+L`index' 
				}
*Multistate life expectancies by STATE OF BIRTH (uncond. or population-based)
 mata: e0_b= Re(T1*luinv(l1))
 mata: e0_b= e0_b\colsum(e0_b)

/*Life expectancies (for stayers and for those who were in a given state).*/
/*Calculations use the summation of the conditional probabilties of survival.*/				
mata: v4=abs(st_data(.,3):-1) //Prob. of surviving in a given state
*mata: e_cond=J(`r(max)',`r(max)',.)

*Calculation of ASD
preserve  //zeros the transition probabilities in the dataset
	qui des
	loc last=`r(k)'-1
	forval c=5/`last' {
		loc to `to' `c'
						}
	qui ds
	tokenize `r(varlist)'
	foreach var of local to {
		qui replace ``var''=0
							} 

	qui des
	mata: rates_nomob= st_data(.,5..(`r(k)'-1))
	mata: q_nomob= st_data(.,3)
	mata: v1_nomob= st_data(.,`r(k)')
	mata: info_nomob= panelsetup(v1,1)
	qui su
	loc max= `r(max)' // local macro for the number of states
	forval x=1/`r(max)' {
		mata pan`x'_nomob= panelsubmatrix(rates_nomob,`x',info_nomob)[.,1..`r(max)']
						}
	clear
	forval x=1/`max' {
		getmata (var`x'*)=pan`x'_nomob
					 }		 
	foreach var of varlist * {
		summ `var', meanonly
		if missing(r(mean)) drop `var'
							 }
		drop var1*					
	qui des
	forval x= 1/`r(N)' {
	mata: N`x'_nomob= N(colshape(st_data(`x',(1..st_nvar())),`max'-1)) //fun. N()
	mata: q`x'_nomob= diag(colshape(rowshape(q_nomob,`r(N)'),`r(N)')'[`x',.])					 
	mata: P`x'_nomob= (N`x'_nomob-q`x'_nomob)'					 
	mata: M`x'_nomob=	2/n*luinv(I(`max')+P`x'_nomob)*(I(`max')-P`x'_nomob)				 
		 			   }
	loc j=`r(N)'-1
restore
preserve
*Step 2: calculation of survivorship ratios, S(x)
	mata: l1_nomob=diag(J(`max',1,`l0')) //puts the l0s from mu() in their proper place
	forval x=2/`r(N)' {
		loc y= `x'+1
		loc z=`x'-1
		mata: l`x'_nomob=P`z'_nomob*l`z'_nomob
		mata: l`y'_nomob= P`x'_nomob*l`x'_nomob
		mata: d`z'_nomob= l`z'_nomob-l`x'_nomob
		mata: d`x'_nomob= l`x'_nomob-l`y'_nomob
		mata: L`z'_nomob=	luinv(M`z'_nomob)*d`z'_nomob
		mata: L`x'_nomob=luinv(M`x'_nomob)*d`x'_nomob	
						}
*Calculation of L(x) in the last open-ended age group
 //gets rid of 0 values to execute log10
	mata: L`r(N)'_nomob= l`r(N)'_nomob*luinv(M`r(N)'_nomob)
	*l`r(N)'_nomob:*diag(log10(diagonal(l`r(N)'_nomob)))

	qui su
	loc n=`r(N)'/`r(max)'
	forval x=1/`n' {
		mata: T`n'_nomob= L`n'_nomob
		loc index =`n'-`x'
		loc index2=`index'+1
		mata: L0_nomob=J(rows(T`n'_nomob), cols(T`n'_nomob),0) //calculated but ignored
		mata: T`index'_nomob= T`index2'_nomob+L`index'_nomob 
					}
*Multistate life expectancies by STATE assuming ASD 
	mata: e0_asd= colsum(Re(T1_nomob*luinv(l1_nomob)))
restore	

forval  x=1/`r(max)' {
	mata: m1`x'=e0_asd[.,`x']
	*mata: m1`x'= sum(runningprod(panelsubmatrix(v4,`x',info)))*n //e0 in state i

/*Expected length of sojourn time in state j(or i) - in columns- given 
//	occupancy of state i - in rows.
	mata: eij`x'=J(length(panelsubmatrix(v2,`x',info)[.,1]),`r(max)',.)
	forval s=1/`r(max)' {
		mata: eij`x'[.,`s']=runningprod(panelsubmatrix(v2,`x',info)[.,`s'])
						}
		mata: e_cond[`x',.]=colsum(eij`x')*n */

//Mean ages at transfer from state i			
	/*mata: m2`x'=sum(panelsubmatrix(a,`x',info)[.,1]:* ///
		ln(abs(panelsubmatrix(v4,`x',info)[.,1]))/-n:* ///
		panelsubmatrix(p,`x',info)[.,1])/ ///
		sum(ln(abs(panelsubmatrix(v4,`x',info)[.,1]))/-n:* ///
		panelsubmatrix(p,`x',info)[.,1])
*/
		
qui su
loc temp= `r(N)'/`r(max)'
*Deaths and mean age at transfer from state i
mata: m2`x'=colsum(panelsubmatrix((1:-sd):*p,`x',info)[2..`temp']:* ///
	range(n,max(st_data(.,1)),n))/colsum(panelsubmatrix((1:-sd):* ///
	p,`x',info)[2..`temp'])
		
//Mean ages of the population	
	mata: m3`x'= sum(panelsubmatrix(a,`x',info)[.,1]:* ///
				panelsubmatrix(p,`x',info)[.,1])/ ///
				sum(panelsubmatrix(p,`x',info)[.,1]) //Mean age of the pop.					
//TFRs
	mata: m4`x'=colsum(panelsubmatrix(v3,`x',info)[.,2])*n
//Gross reproduction rates (GRR)
	mata: m5`x'= colsum(panelsubmatrix(m,`x',info)[.,1])*n 
//Crude birth rates (CBR)
	mata: m6`x'= sum(panelsubmatrix(p,`x',info)[.,1]:* ///
				panelsubmatrix(f,`x',info)[.,1])/ ///
				sum(panelsubmatrix(p,`x',info)[.,1]) 
	mata: values = J(0,0,.)
	mata: vectors = J(0,0,.)
	mata: eigensystem(M, vectors, values) //Stable analysis using eigenvalues
	mata: m1= log(values[1])/n //Intrinsic yearly growth rate
//Stable age structure
	mata: stable0`x'= panelsubmatrix(Re(vectors[,1]/ ///
				sum(vectors[,1])),`x',info)[.,1]
// Keyfitz's delta (1968: 47)
	mata: m7`x'= colsum(abs((panelsubmatrix(p,`x',info)[.,1]:/ ///
				colsum(panelsubmatrix(p,`x',info)[.,1]))-stable0`x'))*.5  
// Total age dependency ratio (%)
	mata: m8`x'= (sum(select(panelsubmatrix(p,`x',info)[.,1], /// 
		panelsubmatrix(st_data(.,1),`x',info)[.,1]:<=`ygual'))+ ///
		sum(select(panelsubmatrix(p,`x',info)[.,1], ///
		panelsubmatrix(st_data(.,1),`x',info)[.,1]:>=65))) / ///
		(sum(select(panelsubmatrix(p,`x',info)[.,1], ///
		panelsubmatrix(st_data(.,1),`x',info)[.,1]))- ///
		(sum(select(panelsubmatrix(p,`x',info)[.,1], ///
		panelsubmatrix(st_data(.,1),`x',info)[.,1]:<=`ygual'))+ ///
		sum(select(panelsubmatrix(p,`x',info)[.,1], ///
		panelsubmatrix(st_data(.,1),`x',info)[.,1]:>=65))))*100
	mata: m2= no(m1,M)*n // Years to stability
	mata: gr=J(2,4,.)
	mata: gr(m1,M,gr)
	*mata: m3= gr[2,1]*n // Years to stability (upper band)
	mata: m3= gr[1,1]*n // Years of growth before first decline
	mata: m4= gr[1,2] // Pop. relative(%) size when decline starts
	mata: m5= gr[2,2] // Pop. relative(%) size in stability					 
						}
mata: measures2=J(5,1,.)
forval l=1/5 {
	mata: measures2[`l',1]= Re(m`l')		  
			 }
mata: st_matrix("su2",measures2)
mat colnames su2= Value
mat rownames su2= "Intrinsic_growth_rate(r)" "Years_to_stability" ///
   "Years_of_positive_growth" /// 
   "Proj./obs._when_decline_starts" "Proj./obs._in_stability"
matlist su2, tit("Summary measures for the total population") row(Measure) ///
	aligncolnames(c) underscore border(bottom) format(%10.4f) tw(31)
return mat summary2 = su2 //Returns measures as a system matrix

mata: measures=J(8,`r(max)',.) //places measures in a matrix
forval l=1/8 {
	forval c=1/`r(max)' {
		mata: measures[`l',`c']= m`l'`c'
						}
			  }
mata: st_matrix("su",measures)
forval c=1/`r(max)' {
		loc State `State' `c' 
					}
foreach a of local State {
		loc colu `colu' State_`a' 
						 }
mat colnames su= `colu'
mat rownames su= "ASD_life_expectancy*" "Mean_age_at_transfer" ///
	"Mean_age_of_the_population" "Total_fertility_rate(TFR)" ///
	"Gross_reproduction_rate(GRR)" "Crude_birth_rate(CBR)" ///
    "Keyfitz's_delta" "Total_age_dependency_ratio(%)"
matlist su, tit("Summary measures by state of occupancy") row(Measure) ///
	aligncolnames(c) underscore border(bottom) format(%10.4f) tw(30)
loc notem ="* Associated Single Decrement (ASD) life expectancy assumes that" ///
	+ " death is the only cause of decrement operating to diminish a cohort."
di "`notem'"
return mat summary = su //Returns measures as a system matrix

mata: st_matrix("su3",e0_b)
mat colnames su3= `colu'
mat rownames su3= `colu' Total
matlist su3, tit("Life expectancies at birth by state: sojourn time in state" ///
"j (in columns) given occupancy of state i (in rows)") ///
 row(State-specific e0)aligncolnames(c) underscore border(bottom) ///
 format(%10.4f) tw(17) lin(rowt)
return mat summary3 = su3
						   }
						}

*Gets rid of intermediate/acessory vectors/matrices in Mata global namespace
if "`two'"=="" & "`multistate'"=="" {
	*mata mata drop L a f fp fpt m n nrr p period
	if "`stable'" != "" & "`summary'" == "" {
		mata mata drop r0 r1 stable* statio values vectors ytos cs fps no
											}
	if "`summary'" != "" & "`stable'" == "" {
		mata mata drop ba deaths gr m* r0 stable0 values vectors w				 
											}
	if "`summary'" != "" & "`stable'"!="" {			
		mata mata drop ba deaths gr m* w cs fps r* st* v* ytos no								  
										  }
	if "`mig1'" != "" {
		mata mata drop P nmr op res			  
					  }
	if "`fert'" != "" {
		mata mata drop fF mat_rate r_fert start start2			  
					  }
	if "`surv'" != "" {
		*mata mata drop Sf fsurv s sf sigma			  
					  }				  
									}
if "`two'"!="" {
	mata mata drop F_m L a f* m* n p period
	if "`stable'" != "" & "`summary'" == "" {
		mata mata drop cs s* v*
											}
	if "`summary'" != "" & "`stable'" == "" {
		mata mata drop f_deaths m_deaths stable0 v*				 
											}
	if "`summary'" != "" & "`stable'"!="" {			
		mata mata drop cs s* v*								  
										  }
	if "`mig1'" != "" {
		mata mata drop P* Sm nmr op res			  
					  }
	if "`fert'" != "" {
		mata mata drop r_fert
					  }
	if "`surv'" != "" {
		mata mata drop S*			  
					  }				  
				}

if "`multistate'"!="" {
	mata: jM=M
	mata mata drop M* a* f* info m* n p* s* t* v* d* l* q* L* N* P* S* rat*
	mata: M=jM
	mata mata drop jM
	if "`stable'"!="" & "`summary'" == "" {
		mata mata drop c* r0			
										  }
	if "`summary'" != "" & "`stable'" == "" {
		mata mata drop m* e* gr				 
											}
	if "`summary'" != "" & "`stable'"!="" {			
		mata mata drop c* e* gr r0								  
										  }
					  }

end //Ends the program

****************
*MATA FUNCTIONS*
****************
{
*Puts the matrix upside down. Taken from Stata Journal(2006)6,n.4,pp.588–589
mata:
	matrix function flipud(matrix X) { 
    return(rows(X)>1 ? X[rows(X)..1,.] : X)
									  }
end

*LESLIE MATRIX for one-sex population projection, by G. Rodríguez / 28feb2017
*https://grodri.github.io/demography/project
mata:
	real matrix Leslie(real vector L, real vector m) {
		n = length(L)
		M = J(n,n,0)
  //Lower diagonal has survivorship ratios
	for (i=1; i < n; i++) {
		M[i+1,i] = L[i+1]/L[i]
						  }
		M[n,n-1] = M[n,n]=L[n]/(L[n-1]+L[n])
  //First row has net female /male contributions
    for (i=1; i < n; i++) {
        if(m[i]==0 & m[i+1]==0) continue
        M[1,i] = L[1]*(m[i]+m[i+1]*L[i+1]/L[i])/2
						   }
        if (m[n] > 0) M[1,n] = L[1]*m[n]
        return(M)
													 }
end

*LESLIE MATRIX for males in a two-sex population projection
mata:
	real matrix Lesliem(real vector L, real vector s, real vector m) {
		n = length(L)
		M = J(n,n,0)
  //Lower diagonal has survivorship ratios
	for (i=1; i < n; i++) {
		M[i+1,i] = s[i+1]/s[i]
						  }
		M[n,n-1] = M[n,n]= s[n]/(s[n-1]+s[n])
  //First row has net paternity contributions
    for (i=1; i < n; i++) {
        if(m[i]==0 & m[i+1]==0) continue
        M[1,i] = s[1]*(m[i]+m[i+1]*L[i+1]/L[i])/2
						   }
        if (m[n] > 0) M[1,n] = s[1]*m[n]
        return(M)
																		}
end

*Leslie for MULTISTATE PROJECTION matrices without mobility
mata:
real matrix Lesliems(real vector sd, prsurv, tft) {
		n = length(sd)
		M = J(n,n,0)
		il= st_data(.,1)[3]-st_data(.,1)[2] // interval length
		srb=strtoreal(st_local("srb")) // sex ratio at birth
  //Lower diagonal has survivorship ratios
	for (i=1; i < n; i++) {
		M[i+1,i] = sd[i]
						  }
		M[n,n] = sd[i]
  //First row has stayers' net fertility contributions
    for (i=1; i < n; i++) {
        if(tft[i]==0 & tft[i+1]==0) continue
        M[1,i] = il/(1+srb)*(tft[i]+tft[i+1]*prsurv[i+1])/2*prsurv[1]
						   }
        if (tft[n] > 0) M[1,n] = (il/(1+srb))*prsurv[1]*tft[n]
        return(M)
													}
end

* NEWTON'S METHOD to calculate intrinsic growth rate and mean age of 
* childbearing in the stable population, by G. Rodríguez / 28feb2017 
mata:
function f (real scalar r, real vector a, real vector L, real vector m) {
   return(sum(exp(-r:*a):*L:*m))
																		}
function g(r, a, L, m) {
   return(-sum(a:*exp(-r:*a):*L:*m))
						}
function newton(nrr, a, L, m) {
   r = log(nrr)/27
   delta = 1
   while(delta > 1e-8) {
     r0 = r
     f0 = f(r0, a, L, m)
     g0 = g(r0, a, L, m)                      
     r = r0 + (1 - f0)/g0
     delta = abs(r - r0)
     A = -g0/f0 
						}
   return(r,A)
								}
end
			
*Function to find the approximate number of years to achieve stability
mata:
function no(complex scalar r0, real matrix M) {
 cusp = 1
 tolerance= strtoreal(st_local("tolerance")) //tolerance set in syntax
 c0 = st_data(.,2):/colsum(st_data(.,2)) //Current age distribution
 no = 0
 n=st_data(.,1)[3]-st_data(.,1)[2]
 while (cusp > tolerance) {
	c1 = M*c0
	r3 = ln(sum(c1)/sum(c0)):/n
	cusp = abs(r3-r0)
	no++
	c0 = c1
						  }
return(no)
											 }
end

*Alternative function to find # of years to stability (using Keyfitz' delta)
mata:
function no2(real vector stable0, real matrix M) {
 cusp = 1
 tolerance= strtoreal(st_local("tolerance"))
 c0 = st_data(.,2) //Current population
 no2 = 0
 while (cusp > tolerance) {
	c1 = M*c0:/colsum(M*c0)
	cusp = .5*colsum(abs(c1-stable0))
	no2++
	c0 = c1
						  }
return(no2)
											 }
end

*Function to generate measures m16 to m19
mata:
void gr(complex scalar r0,real matrix M, gr) {
delta = 1
	c0 = st_data(.,2):/colsum(st_data(.,2))
	nu=0
	first = 1
	gr=J(2,4,.)
	 	while (delta > 1e-8) {
		c1 = M*c0
		r2 = ln(sum(c1)/sum(c0)):/(st_data(.,1)[3]-st_data(.,1)[2])
		delta = abs(r2-r0)
		nu++
		if(r2 < 0 & first) {
			gr[1,.]=nu, sum(c1), r2, delta
				first = 0
							}
		c0 = c1
							  }
			gr[2,.]=nu, sum(c1), r2, delta				
				return
												}
end

*Function to create Leslie matrix for migrants
mata:
real matrix Leslie2(real vector mprob, real vector mfer) {
	n=length(mprob)
	M2=J(n,n,0)
	//Sub-diagonal has residual net migration probabilities
	for (i=1; i < n; i++) {
		M2[i+1,i] = mprob[i+1]
						  }
		M2[n,n]= 0
	//First row has migrants' net maternity contributions
	for (i=1; i < n; i++) {
        if(mfer[i]==0 & mfer[i+1]==0) continue
        M2[1,i] = mfer'[i]
						   }
        return(M2)
														}
end

*Function to calculate the running product of a vector, by Federico Belotti
*and Silvio Daidone (net describe runningprod)
mata:
numeric vector runningprod(numeric vector vec, | real scalar missing) {
	numeric vector rp 
    real scalar i
		if (missing == .) tmp = vec
        else              tmp = editmissing(vec, missing)
        rp = tmp
    for (i=2; i <= length(vec); i++)  {
		rp[i] = rp[i-1] * tmp[i] 
									  }
		return(rp)
																		}
end

*Function to calculate the running quotient of a vector
mata:
numeric vector runningquo(numeric vector vec) {
	numeric vector rp
	real scalar i
	tmp=vec
	rp=tmp
	for (i=2; i <= length(vec); i++)  {
		rp[i] = rp[i] / tmp[i-1] 
									  }
		return(rp)
	
											  }
end

*Function to place age-specific survivorship ratios in the subdiagonal
mata:
real matrix subd(real vector s, real vector L, real vector m) {
		n = length(L)
		M = J(n,n,0)
		il= st_data(.,1)[3]-st_data(.,1)[2] // interval length
  //Lower diagonal has survivorship ratios
	for (i=1; i < n; i++) {
		M[i+1,i] = s[i+1]/s[i]
						  }
		M[n,n-1]=M[n,n]=s[n]/(s[n-1]+s[n])
	//First row has net maternity/paternity contributions
    for (i=1; i < n; i++) {
        if(m[i]==0 & m[i+1]==0) continue
        M[1,i] = il*s[1]*(m[i]+m[i+1]*L[i+1]/L[i])/2
						   }
        if (m[n] > 0) M[1,n] = il*s[1]*m[n]
    return(M)
																}
end

*Functions to define the parameter sigma. 
* Sigma shapes the future rectangularization of the survival curve. 
* Sigma minimizes the mean of two Keyfitz's distances:  
* 1. the difference btw./ obs. and predicted survival curves (Sx), and 
* 2. the difference btw./ obs. and predicted probs. of survival (sx).

********************
*for ONE-SEX models*
********************
mata:
//Define the objective function y to minimize alfa in the final proj. period
	void alfa(todo, real scalar x, real scalar n, real vector a, ///
		 real scalar surv, real scalar sigma, real scalar y, ///
		 real vector g, real matrix H)
		{
		y=(sum(1:/(1:+(a/(surv+x)):^sigma))*n-surv)^2
		}
end

//Initialize optimization of alfa for one-sex models
mata:
real scalar optimize_alfa(real scalar sigma, real scalar surv) {
    
	S = optimize_init()
	optimize_init_verbose(S, 0)
    optimize_init_tracelevel(S, "none")
    optimize_init_evaluator(S, &alfa())
	optimize_init_evaluatortype(S, "d0")
    optimize_init_params(S, 0) //Initial parameter guesses = 0
	optimize_init_technique(S, "nr 10000")
n= st_data(.,1)[3]-st_data(.,1)[2] // interval length
a= st_data(.,1):+(n/2)
//Pass additional arguments
	optimize_init_argument(S, 1, n)
	optimize_init_argument(S, 2, a)
	optimize_init_argument(S, 3, surv)
	optimize_init_argument(S, 4, sigma)
    optimize_init_which(S, "min") //Set optimization to minimize
return(optimize(S))	//Performs the optimization					
																}
end

//Initialize optimization of alfa for two-sex models
mata:
real scalar optimize_alfat(real scalar sigma, real scalar surv) {
    
	S = optimize_init()
	optimize_init_verbose(S, 0)
    optimize_init_tracelevel(S, "none")
    optimize_init_evaluator(S, &alfa())
	optimize_init_evaluatortype(S, "d0")
    optimize_init_params(S, 0) //Initial parameter guesses = 0
	optimize_init_technique(S, "nr 10000")
n= st_data(.,1)[3]-st_data(.,1)[2] // interval length
a= st_data(.,1)[1..length(st_data(.,1))/2]:+(n/2)
//Pass additional arguments
	optimize_init_argument(S, 1, n)
	optimize_init_argument(S, 2, a)
	optimize_init_argument(S, 3, surv)
	optimize_init_argument(S, 4, sigma)
    optimize_init_which(S, "min") //Set optimization to minimize
return(optimize(S))	//Performs the optimization					
																}
end

*****************************************************************************
*Generates matrix of transition PROBABILITIES according to 
*Schoen (1988: 65, eq. 4.4)
mata matrix function N(real matrix b) {
	x=diag(J(rows(b),1,1)- rowsum(b))
	external b
		for(i=1; i<=rows(x); i++) {
			for(j=1; j<=cols(x); j++) {
			if (i<j) x[i,j]=b[i,j-1]
			if (i>j) x[i,j]=b[i,j] 
									   }
								  }
	return(x)
										}

}
