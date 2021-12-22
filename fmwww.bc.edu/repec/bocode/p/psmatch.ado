*! psmatch version 2.0.3Ê Barbara Sianesi  August 29, 2001
* added option logit in bs

* first version Februay 10, 2001


program define psmatch, rclass

	version 7.0

   # delimit ;


	syntax varname , 
	[ON(varlist numeric min=1 max=3)          ESTimate(varlist)    LOGit    INDex 
	ID(varname numeric)  CALiper(real 1000)   OUTcome(varname numeric) 
	KERnel(varname)      EPan 
	SPline(varname)      NKnots(integer 0) 
	MEan(varname)        NEIghbour(integer 0) NEIGHBOR(integer 0) 
	TRicube(varname)     LOWess(varname)      LIne(varname)        BWidth(real 0) 
	BOth                 noCOMMON 
	QUAlity(varlist numeric)            
	SAving(str) noCount

	BOOTstrap
	Reps(int 50)         SIze(int -9)         Dots
	Level(real $S_level) 
	DOUBle               EVery(integer 1)     REPLACE
	];                                        


   # delimit cr


   *** CHECKS


      if `"`id'"' != `""'  { 
	      sort `id'
	      qui count if `id'==`id'[_n-1]
		      if r(N)!=0  {
			      di in red "more than one obs per `id'"
			      exit
		      }
		 }

      
      if (`"`on'"' == `""' & `"`estimate'"' == `""') | (`"`on'"' != `""' & `"`estimate'"' != `""') {  
			di in red "either ON or ESTIMATE has to be specified"
			exit
		} 

      if `"`kernel'"' != `""' & `bwidth' == 0 { 
      	local bwidth = 0.06                                               
      }                                                     

      if `"`kernel'"' == `""' & (`bwidth'>1 | `bwidth'<0) {
      	di in red "bandwidth here between 0 and 1 only"
      	exit       
      }             

      if `"`kernel'"' != `""' & (`"`spline'"' != `""' | `"`tricube'"' != `""' | `"`mean'"' != `""' | `"`line'"' != `""' | `"`lowess'"' != `""') {  
			di in red "only one smoothing method may be specified"
			exit
		} 

      if `"`spline'"' != `""' & (`"`kernel'"' != `""' | `"`tricube'"' != `""' | `"`mean'"' != `""' | `"`line'"' != `""' | `"`lowess'"' != `""') {  
			di in red "only one smoothing method may be specified"
			exit
		} 

      if `"`mean'"' != `""' & (`"`spline'"' != `""' | `"`tricube'"' != `""' | `"`kernel'"' != `""' | `"`line'"' != `""' | `"`lowess'"' != `""') {  
			di in red "only one smoothing method may be specified"
			exit
		} 

      if `"`lowess'"' != `""' & (`"`spline'"' != `""' | `"`tricube'"' != `""' | `"`mean'"' != `""' | `"`line'"' != `""' | `"`kernel'"' != `""') {  
			di in red "only one smoothing method may be specified"
			exit
		} 

      if `"`tricube'"' != `""' & (`"`spline'"' != `""' | `"`lowess'"' != `""' | `"`mean'"' != `""' | `"`line'"' != `""' | `"`kernel'"' != `""') {  
			di in red "only one smoothing method may be specified"
			exit
		} 

      if `"`line'"' != `""' & (`"`spline'"' != `""' | `"`tricube'"' != `""' | `"`mean'"' != `""' | `"`lowess'"' != `""' | `"`kernel'"' != `""') {  
			di in red "only one smoothing method may be specified"
			exit
		} 

      if `"`quality'"' != `""' & (`"`spline'"' != `""' | `"`kernel'"' != `""' | `"`tricube'"' != `""' | `"`mean'"' != `""' | `"`line'"' != `""' | `"`lowess'"' != `""') {  
			di in red "quality cannot be specified"
			exit
		} 

      if `"`quality'"' != `""' & `"`saving'"' == `""' {
      	di in red "need to specify the filename"
      	exit       
      }             

      if `"`bootstrap'"' != `""' & `"`estimate'"' == `""' {
      	di in red "to bootstrap, need to specify the regressors in estimate()" 
      	exit       
      }             

      if `"`bootstrap'"' != `""' & `"`outcome'"' == `""' & `"`spline'"' == `""' & `"`kernel'"' == `""' & `"`tricube'"' == `""' & `"`mean'"' == `""' & `"`line'"' == `""' & `"`lowess'"' == `""' {
      	di in red "to bootstrap, need to specify the outcome variable either via outcome()" 
      	di in red "or by specifying a smoothing type of matching"
      	exit       
      }             

      if `"`bootstrap'"' != `""' & `"`quality'"' != `""' {
      	di in red "cannot specify quality() when bootstrapping" 
      	exit       
      }             
                          


	set more off

   local treated `varlist' 

   if `neighbor' != 0  {  
      local neighbour `neighbor'
   }
    

if `"`bootstrap'"' != `""'  {  

   if `"`outcome'"' != `""'  {
      local type "outcome"
      local outcvar `outcome'
   }

   if `"`kernel'"' != `""'  {
      local type "kernel"
      local outcvar `kernel'
   }

   if `"`spline'"' != `""'  {
      local type "spline"
      local outcvar `spline'
   }

   if `"`mean'"' != `""'  {
      local type "mean"
      local outcvar `mean'
   }

   if `"`line'"' != `""'  {
      local type "line"
      local outcvar `line'
   }

   if `"`lowess'"' != `""'  {
      local type "lowess"
      local outcvar `lowess'
   }

   if `"`tricube'"' != `""'  {
      local type "tricube"
      local outcvar `tricube'
   }



   # delimit ;

   if `"`saving'"' != `""'  { ;

      bs "psmatch `treated', estimate(`estimate') `index' `logit' caliper(`caliper') bwidth(`bwidth') 
         `epan' `both' nknots(`nknots') neighbour(`neighbour') `nocommon' `type'(`outcvar') noc"  
         "r(effect)", reps(`reps') level(`level') `dots' size(`size')
         saving(`"`saving'"') `replace' every(`every') `double' ; 
      
   } ;

   else if `"`saving'"' == `""'  { ;

      bs "psmatch `treated', estimate(`estimate') `index' `logit' caliper(`caliper') bwidth(`bwidth') 
         `epan' `both' nknots(`nknots') neighbour(`neighbour') `nocommon' `type'(`outcvar') noc"  
         "r(effect)", reps(`reps') level(`level') `dots' size(`size') `double' ; 

   } ;

   # delimit cr
}


else if `"`bootstrap'"' == `""' {





   *** GETTING the PROPENSITY SCORE(S)


   if `"`estimate'"' != `""'  {   
      tempvar score

      if `"`logit'"' != `""'  { 
         logit `treated' `estimate', nolog      
      }
      else {
         probit `treated' `estimate', nolog
      }


      if `"`index'"' != `""'  { 
         qui predict double `score', index
      }
      else {
         qui predict double `score'
      }

   }                        



   if `"`on'"' != `""'  {
      tokenize `on'  
      local score `1'
      local score2 `2'
      local score3 `3'
   }

   if `"`score2'"' != `""' & `"`score3'"' == `""'  { 

      if `"`spline'"' != `""' | `"`mean'"' != `""' | `"`tricube'"' != `""' | `"`line'"' != `""'| `"`lowess'"' != `""'  {                                                                                                                        
  	      n di in red "only one matchvar may be specified"                                                                                                                                                            
  	      exit                                                                                                                                                                                                               
      }                                                                                                                                                                                                                     


      qui {

         preserve 
      
         drop if `score'==. | `score2'==.

         tempname N1 N0 sigma1 sigma2 sigma12

         mat ac A0=`score' `score2' if `treated'==0
         mat XX0=A0[1..2, 1..2]
         mat ac A1=`score' `score2' if `treated'==1
         mat XX1=A1[1..2, 1..2]
         qui tabstat `score' `score2', by(`treated') save
         mat xx0=r(Stat1)'*r(Stat1)
         mat xx1=r(Stat2)'*r(Stat2)
         qui count if `treated'==1
         scalar `N1'=r(N)
         qui count if `treated'==0
         scalar `N0'=r(N)
         mat Sinv=(`N1'+`N0'-2)*syminv(XX1-`N1'*xx1+XX0-`N0'*xx0)
         scalar `sigma1' =Sinv[1,1]
         scalar `sigma2' =Sinv[2,2]
         scalar `sigma12'=Sinv[2,1]

         restore

      }

  }


   if `"`score3'"' != `""'  { 

      if `"`spline'"' != `""' | `"`mean'"' != `""' | `"`tricube'"' != `""' | `"`line'"' != `""'| `"`lowess'"' != `""'  {                                                                                                                        
  	      n di in red "only one matchvar may be specified"                                                                                                                                                            
  	      exit                                                                                                                                                                                                               
      }                                                                                                                                                                                                                     


      qui {

         preserve 
      
         drop if `score'==. | `score2'==. | `score3'==.

         tempname N1 N0 sigma1 sigma2 sigma3 sigma12 sigma13 sigma23

         mat ac A0=`score' `score2' `score3' if `treated'==0
         mat XX0=A0[1..3, 1..3]
         mat ac A1=`score' `score2' `score3' if `treated'==1
         mat XX1=A1[1..3, 1..3]
         qui tabstat `score' `score2' `score3', by(`treated') save
         mat xx0=r(Stat1)'*r(Stat1)
         mat xx1=r(Stat2)'*r(Stat2)
         qui count if `treated'==1
         scalar `N1'=r(N)
         qui count if `treated'==0
         scalar `N0'=r(N)
         mat Sinv=(`N1'+`N0'-2)*syminv(XX1-`N1'*xx1+XX0-`N0'*xx0)
         scalar `sigma1'=Sinv[1,1]
         scalar `sigma2'=Sinv[2,2]
         scalar `sigma3'=Sinv[3,3]
         scalar `sigma12'=Sinv[1,2]
         scalar `sigma13'=Sinv[1,3]
         scalar `sigma23'=Sinv[2,3]

         restore

      }

  }



	*** ONE-TO-ONE MATCHING


	if `"`kernel'"'== `""' & `"`lowess'"' == `""' & `"`tricube'"' == `""' & `"`line'"' == `""' & `"`spline'"' == `""' & `"`mean'"' == `""'  { 

         quietly {
            		
            cap drop _times
            cap drop _matchdif

            tempvar newid
            gsort -`treated'
            gen `newid'=_n  

            local identifier `"`id'"'  
            

       if `"`score2'"' == `""'  { 

			  tempvar fdif bdif fym bym fid bid

           sort `score' `treated' `id' `newid'

           local i = 1
           local fstop = 0
           local fcount = 0
           gen `fdif' =.
           gen `fym' =.
           gen `fid' =.

           while `fstop' == 0   {
               local lastfcount = `fcount'
               count if `fdif'==. & `treated'==1    
               local fcount = r(N)   
               
               if `fcount' == `lastfcount' {      
                  local fstop = 1  
               }

               else  {      
                 if r(N) != 0   {

                     replace `fdif' = `score' - `score'[_n+`i'] if `treated'==1 & `treated'[_n+`i']==0  & `fdif'==.
                     
                     if `"`outcome'"' != `""'  {
                        replace `fym' = `outcome'[_n+`i']       if `treated'==1 & `treated'[_n+`i']==0  & `fym'==.
                     }

                     if `"`id'"' != `""'  { 
                        replace `fid'  = `id'[_n+`i']           if `treated'==1 & `treated'[_n+`i']==0  & `fid'==.
                     }
                     else if `"`id'"' == `""'  { 
                        replace `fid'  = `newid'[_n+`i']        if `treated'==1 & `treated'[_n+`i']==0  & `fid'==.
                     }

                     local i = `i' + 1
                 }      
            
                 else if r(N)== 0  {        
                   local fstop = 1      
                 }   
           
              }
           }


           local i = 1
           local bstop = 0
           local bcount = 0
           gen `bdif' =.
           gen `bym' =.
           gen `bid' =.

           while `bstop' == 0   {
               local lastbcount = `bcount'
               count if `bdif'==. & `treated'==1    
               local bcount = r(N)   
               
               if `bcount' == `lastbcount' {      
                  local bstop = 1  
               }

               else  {      
                 if r(N) != 0   {

                     replace `bdif' = `score' - `score'[_n-`i'] if `treated'==1 & `treated'[_n-`i']==0  & `bdif'==.
                     
                     if `"`outcome'"' != `""'  {
                        replace `bym' = `outcome'[_n-`i']       if `treated'==1 & `treated'[_n-`i']==0  & `bym'==.
                     }

                     if `"`id'"' != `""'  { 
                        replace `bid'  = `id'[_n-`i']           if `treated'==1 & `treated'[_n-`i']==0  & `bid'==.
                     }
                     else if `"`id'"' == `""'  { 
                        replace `bid'  = `newid'[_n-`i']        if `treated'==1 & `treated'[_n-`i']==0  & `bid'==.
                     }

                     local i = `i' + 1
                 }      
            
                 else if r(N)== 0  {        
                   local bstop = 1      
                 }   
           
              }
           }


           gen _matchdif = min(abs(`fdif'), abs(`bdif')) if min(abs(`fdif'), abs(`bdif'))<`caliper' & `treated'==1

           if `"`outcome'"' != `""'  { 
              cap drop _m`outcome'
              gen _m`outcome' = `fym' if abs(`fdif')<abs(`bdif') & abs(`fdif')<`caliper' & `treated'==1
              replace _m`outcome' = `bym' if abs(`fdif')>=abs(`bdif') & abs(`bdif')<`caliper' & `treated'==1 
           }

           tempvar tmid t1 t2 t3

           gen `tmid' = `fid' if abs(`fdif')<abs(`bdif') & abs(`fdif')<`caliper' & `treated'==1 
           replace `tmid' = `bid' if abs(`fdif')>=abs(`bdif') & abs(`bdif')<`caliper' & `treated'==1 
   
           sort `tmid'
           gen byte `t1'=1 if `tmid'!=`tmid'[_n-1] & `treated'==1
           egen `t2'=count(`tmid'), by(`tmid')
           replace `t2'=. if `t1'!=1
           if `"`id'"' == `""'  {     
              gen `t3'=`newid' if `treated'==0 
           }                          
           if `"`id'"' != `""'  {     
              gen `t3'=`id' if `treated'==0 
           }                          

           replace `t3'=`tmid' if `treated'==1 & `tmid'!=.
           sort `t3' `treated' `t1'

           cap drop _times
           gen _times=1 if `treated'==1 & `tmid'!=.
           replace _times=`t2'[_n+1] if `treated'==0 & `t1'[_n+1]==1

           if `"`id'"' != `""'  { 
              cap drop _matchedid
              gen _matchedid = `tmid'
           }
   

       }




       else  if `"`score2'"' != `""'  { 

				cap log off

				tempvar  indic dif mid
            tempname maxid		
            
				count if `treated'==1
				scalar `maxid'=r(N)

				gen byte _times=0
				gen _matchdif=0 if `treated'==1
            gen `mid'=.


            if `"`id'"' != `""'  { 
				   cap drop _matchedid
               gen _matchedid=0 if `treated'==1
            }


            local i = 1
				while `i'<= `maxid'   {

					cap drop `indic'
				   gen byte `indic' = 1 if `newid'==`i' 
               sort `indic'
				   cap drop `dif'

               if `"`score2'"' != `""' & `"`score3'"' == `""'  {
                  gen `dif'=`sigma1'*(`score'[1]-`score')^2+`sigma2'*(`score2'[1]-`score2')^2+2*`sigma12'*(`score'[1]-`score')*(`score2'[1]-`score2') if `treated'==0
               }

               if `"`score2'"' != `""' & `"`score3'"' != `""' {
                  # delimit ;
                  gen `dif'=`sigma1'*(`score'[1]-`score')^2+`sigma2'*(`score2'[1]-`score2')^2+
                     `sigma3'*(`score3'[1]-`score3')^2+
                     2*`sigma12'*(`score'[1]-`score')*(`score2'[1]-`score2')+
                     2*`sigma13'*(`score'[1]-`score')*(`score3'[1]-`score3')+
                     2*`sigma23'*(`score2'[1]-`score2')*(`score3'[1]-`score3')   if `treated'==0;
                  # delimit cr
               }

					sort `dif' `id'
					replace _times=_times+1 if `dif'[1]<`caliper' & (`indic'==1 | _n==1)
					replace _matchdif=`dif'[1] if _times==1 & `indic'==1 
					replace `mid'=`newid'[1]  if _times==1 & `indic'==1

					if `"`id'"' != `""'  { 
					   replace _matchedid=`id'[1] if _times==1 & `indic'==1 
               }
					    

               if `"`count'"' == `""'  { 
					   n di _skip(6) `maxid'-`i'
               }

               local i = `i'+1
				
				} 

				replace _times=. if _times==0
            replace _matchdif=. if _times==.
				replace _times=1 if `treated'==1 & _matchdif!=.
            
            if `"`outcome'"' != `""'  {      
               cap drop _m`outcome'
               sort `newid'
               gen _m`outcome' = `outcome'[`mid'] if `treated'==1
            }

       }


				lab var _times "no. of times used"
				lab var _matchdif "difference in score"
            cap lab var _matchedid "`identifier' of matched control"  
            cap lab var _m`outcome' "`outcome' of the matched control"  

            if `"`count'"' == `""'  { 
				   n di _newline(3) _skip(3) in w "Now use _times~=. to identify the matched treated and matched controls"
				   n di _skip(3) in w "Use [fw=_times] in later analyses, or else type: expand _times"
            }

            cap log on

            if `"`outcome'"' != `""'  {      
            		
               tempname mean1 mean0 number weight var1 var0 stderr

               sum `outcome' if `treated' == 1 [fw=_times]  
               scalar `mean1'  = r(mean)
               scalar `number' = r(N)
               scalar `var1'   = r(Var)
               sum `outcome' if `treated' == 0 [fw=_times]  
               scalar `mean0' =  r(mean)
               sum `outcome' if `treated' == 0 & _times!=.
               scalar `var0'   = r(Var)

               tempvar we
               gen `we'=_times^2 if `treated'==0
               sum `we'
               scalar `weight' = r(sum)
               scalar `stderr' = sqrt( (`var1')/`number' + (`weight'/(`number'^2))*`var0' )

               n di _newline(3) _skip(3) in g "Mean " in w "`outcome'" in g " of matched treated  = " in y `mean1'
               n di _newline(1) _skip(3) in g "Mean " in w "`outcome'" in g " of matched controls = " in y `mean0'
               n di _newline(1) _skip(3) in g "Effect  = " in y `mean1'-`mean0'
               n di _newline(1) _skip(3) in g "Std err = " in y `stderr' 
               n di _newline(1) _skip(3) in w "Note: takes account of possibly repeated use of control observations" 
               n di _skip(3) in w "      but NOT of estimation of propensity score."
               n di _newline(1) _skip(3) in g "T-statistics for " in w "H0: effect=0" in g " is " in y (`mean1'-`mean0')/`stderr'

               return scalar mean1 = `mean1'
               return scalar mean0 = `mean0'
               return scalar effect= `mean1'-`mean0'

            }



            if `"`quality'"' != `""'  { 

            preserve
            tempfile user
            save `user'

            drop _all
            gen byte temp=1
            cap save `"`saving'"', replace

            foreach bit of local quality {
   
               use `user'
               gen str15 regressor=substr("`bit'", 1, 15)

               sum `bit' if `treated'==1
               gen mean1 = r(mean)
               gen var1  = r(Var)

               sum `bit' if `treated'==1 [fw=_times]
               gen mean1m = r(mean)
               gen var1m  = r(Var)

               sum `bit' if `treated'==0
               gen mean0 = r(mean)
               gen var0  = r(Var)

               sum `bit' if `treated'==0 [fw=_times]
               gen mean0m = r(mean)
               gen var0m  = r(Var)

               keep in 1
               keep regressor mean* var*

               append using `"`saving'"'
               save `"`saving'"', replace
            }

            drop if temp==1
            drop temp
            gen biasbef=100*(mean1-mean0)/sqrt((var1+var0)/2)
            gen biasaft=100*(mean1m-mean0m)/sqrt((var1+var0)/2)
            gen abiasbef=abs(biasbef)
            gen abiasaft=abs(biasaft)
            gen absreduc=-100*(abiasaft-abiasbef)/abiasbef
            drop var*
            lab var mean1 "mean in full treated group"
            lab var mean0 "mean in full non-treated group"
            lab var mean1m "mean in matched treated group"
            lab var mean0m "mean in matched control group"
            lab var biasbef "standardised % bias before matching"
            lab var biasaft "standardised % bias after matching"
            lab var abiasbef "absolute std % bias before matching"
            lab var abiasaft "absolute std % bias after matching"
            lab var absreduc "% reduction in absolute bias"
            save, replace

            restore
            n di _newline(1) _skip(3) in w "Dataset with match quality information " in g "`saving'.dta" in w " has been created!"

            }


         }
	}



   *** SMOOTHING


	* KERNEL MATCHING


	if `"`kernel'"' != `""' { 

			quietly  {

            local outcome `"`kernel'"'
			   cap drop _m`outcome'
            cap drop _s`outcome'

            tempvar newid
            gsort -`treated'   
            gen `newid'=_n if `treated'==1    

				tempvar  dif weight 
				tempname min max min2 max2 maxid	

				count if `treated'==1
				scalar `maxid'=r(N)

				gen _m`outcome'=.
            if `"`both'"' != `""'  { 
               gen _s`outcome'=.
            }

            cap log off

	         local i=1
				while `i'<=`maxid'   {


					cap drop `dif'

               if `"`score2'"' != `""' & `"`score3'"' == `""'  {
                  if `"`both'"' != `""'  {  
                     gen `dif'=`sigma1'*(`score'[`i']-`score')^2+`sigma2'*(`score2'[`i']-`score2')^2+2*`sigma12'*(`score'[`i']-`score')*(`score2'[`i']-`score2') 
                  }
                  else  {  
                     gen `dif'=`sigma1'*(`score'[`i']-`score')^2+`sigma2'*(`score2'[`i']-`score2')^2+2*`sigma12'*(`score'[`i']-`score')*(`score2'[`i']-`score2') if `treated'==0
                  }
               }

               if `"`score2'"' != `""' & `"`score3'"' != `""' {
                  if `"`both'"' != `""'  {
                     # delimit ;
                     gen `dif'=`sigma1'*(`score'[`i']-`score')^2+`sigma2'*(`score2'[`i']-`score2')^2+
                        `sigma3'*(`score3'[`i']-`score3')^2+
                        2*`sigma12'*(`score'[`i']-`score')*(`score2'[`i']-`score2')+
                        2*`sigma13'*(`score'[`i']-`score')*(`score3'[`i']-`score3')+
                        2*`sigma23'*(`score2'[`i']-`score2')*(`score3'[`i']-`score3');   
                     # delimit cr
                   }

                  else  {
                     # delimit ;
                     gen `dif'=`sigma1'*(`score'[`i']-`score')^2+`sigma2'*(`score2'[`i']-`score2')^2+
                        `sigma3'*(`score3'[`i']-`score3')^2+
                        2*`sigma12'*(`score'[`i']-`score')*(`score2'[`i']-`score2')+
                        2*`sigma13'*(`score'[`i']-`score')*(`score3'[`i']-`score3')+
                        2*`sigma23'*(`score2'[`i']-`score2')*(`score3'[`i']-`score3')   if `treated'==0;
                     # delimit cr
                   }
               }

               if `"`score2'"' == `""' & `"`score3'"' == `""' {
                  gen `dif'=abs(`score'-`score'[`i']) 
               }


					if `"`epan'"'!= `""'  {
						gen `weight' = 1-(`dif'/ `bwidth')^2 if abs(`dif'/`bwidth')<=1 
					}
					else  {
						gen `weight' = normden(`dif'/ `bwidth') 
					}

              su `kernel' [aw=`weight'] if `treated'==0, meanonly
              replace _m`outcome' = r(mean) in `i'    


               if `"`both'"' != `""'  {          
                  su `kernel' [aw=`weight'] if `treated'==1, meanonly
                  replace _s`outcome' = r(mean) in `i'    
                }

					drop `weight' 
					
					if `"`count'"' == `""'  {       
					   n di _skip(6) `maxid'-`i'
					}

					local i = `i'+1

            } 

            
			  if `"`common'"' == `""'  {

				      **** imposing COMMON SUPPORT -- on the treated only

				      sum `score' if `treated'==0
				      scalar `min'=r(min)
				      sum `score' if `treated'==0
				      scalar `max'=r(max)

				      replace _m`outcome' = . if (`score'>`max' | `score'<`min') & `treated'==1
                  if `"`both'"' != `""'  { 
                     replace _s`outcome'=. if (`score'>`max' | `score'<`min') & `treated'==1                                 
                  }                       

                  if `"`score2'"' != `""'  { 
   			         sum `score2' if `treated'==0
				         scalar `min'=r(min)
				         sum `score2' if `treated'==0
				         scalar `max'=r(max)
				         replace _m`outcome' = . if (`score2'>`max' | `score2'<`min') & `treated'==1
                     if `"`both'"' != `""'  { 
                        replace _s`outcome'=. if (`score2'>`max' | `score2'<`min') & `treated'==1                                 
                     }                       
				      }      

                  if `"`score3'"' != `""'  { 
   			         sum `score3' if `treated'==0
				         scalar `min'=r(min)
				         sum `score3' if `treated'==0
				         scalar `max'=r(max)
				         replace _m`outcome' = . if (`score3'>`max' | `score3'<`min') & `treated'==1
                     if `"`both'"' != `""'  { 
                        replace _s`outcome'=. if (`score3'>`max' | `score3'<`min') & `treated'==1                                 
                     }                       
				      }      
				      
                  count if `treated'==1

                  if r(N)==0  {                                
	                  n di in red "none of the treated lies within the common support"  
	                  exit                                      
                  }                                            
                                             
            }

				lab var _m`outcome' "matched smoothed `outcome'"
				cap lab var _s`outcome' "treated smoothed `outcome'"

			}

   if `"`count'"' == `""'  { 
	   n di _newline(3) _skip(3) in g "_m`outcome'" in w " is defined only for treated (and within the common support);"
	   n di _skip(3) in w "It should be compared to the " in g `"`kernel'"' in w " (or" in g "_s`outcome'" in w ") for those treated only," 
	   n di _skip(3) in w "i.e. with _m`outcome'~=.
   }


   tempname mean1 mean0

   if `"`both'"' != `""'  {          
	   qui sum _s`outcome' if _m`outcome'!=.
      scalar `mean1'  = r(mean)
   }                              
   else  {
	   qui sum `kernel'  if `treated'==1 & _m`outcome'!=.
      scalar `mean1'  = r(mean)
   }

   cap log on

	qui sum _m`outcome' 
   scalar `mean0'  = r(mean)
   n di _newline(3) _skip(3) in g "Mean " in w "`outcome'" in g " of matched treated  = " in y `mean1'                        
   n di _newline(1) _skip(3) in g "Mean " in w "`outcome'" in g " of matched controls = " in y `mean0'                        
   n di _newline(1) _skip(3) in g "Effect  = " in y `mean1'-`mean0'                                                           

   return scalar mean1 = `mean1'          
   return scalar mean0 = `mean0'          
   return scalar effect= `mean1'-`mean0'  
                                          


	}


   * OTHER 

   quietly  {

       if `"`lowess'"' != `""' | `"`tricube'"' != `""' | `"`spline'"' != `""' | `"`line'"' != `""'| `"`mean'"' != `""' {
         
       * SPLINE

         if `"`spline'"' != `""' {

            local outcome `"`spline'"'
    			cap drop _m`outcome'
            cap drop _s`outcome'
            spline `outcome' `score' if `treated'==0, gen(_m`outcome') nknots(`nknots') nograph

            if `"`both'"' != `""'  {  
                spline `outcome' `score' if `treated'==1, gen(_s`outcome') nknots(`nknots') nograph
            }                         
              
         }


       * MEAN

         if `"`mean'"' != `""' {

            local outcome `"`mean'"'
            cap drop _m`outcome'
            cap drop _s`outcome'

            if `neighbour' != 0 {
               qui count if `treated' == 0
               local bwidth = `neighbour'/r(N)
            }

            ksm `outcome' `score' if `treated'==0, gen(_m`outcome') bwidth(`bwidth') nograph

            if `"`both'"' != `""'  {  
                ksm `outcome' `score' if `treated'==1, gen(_s`outcome') bwidth(`bwidth') nograph   
            }                         
              
         }



       * TRICUBE KERNEL

         if `"`tricube'"' != `""' {

            local outcome `"`tricube'"'
            cap drop _m`outcome'
            cap drop _s`outcome'
            ksm `outcome' `score' if `treated'==0, weight gen(_m`outcome') bwidth(`bwidth') nograph

            if `"`both'"' != `""'  {  
                ksm `outcome' `score' if `treated'==1, weight gen(_s`outcome') bwidth(`bwidth') nograph   
            }                         
              
         }



       * LINE

         if `"`line'"' != `""' {

            local outcome `"`line'"'
            cap drop _m`outcome'
            cap drop _s`outcome'
            ksm `outcome' `score' if `treated'==0, line gen(_m`outcome') bwidth(`bwidth') nograph

            if `"`both'"' != `""'  {  
                ksm `outcome' `score' if `treated'==1, line gen(_s`outcome') bwidth(`bwidth') nograph   
            }                         
              
         }


       * LOWESS

         if `"`lowess'"' != `""' {

            local outcome `"`lowess'"'
	   		cap drop _m`outcome'
            cap drop _s`outcome'
            ksm `outcome' `score' if `treated'==0, lowess gen(_m`outcome') bwidth(`bwidth') nograph

            if `"`both'"' != `""'  {  
                ksm `outcome' `score' if `treated'==1, lowess gen(_s`outcome') bwidth(`bwidth') nograph
            }                         
            
         }



			tempvar fdif bdif fym bym 

         sort `score' `treated' `id' 

         local i = 1
         local fstop = 0
         local fcount = 0
         gen `fdif' =.
         gen `fym' =.

         while `fstop' == 0   {
             local lastfcount = `fcount'
             count if `fdif'==. & `treated'==1    
             local fcount = r(N)   
             
             if `fcount' == `lastfcount' {      
                local fstop = 1  
             }

             else  {      
               if r(N) != 0   {

                   replace `fdif' = `score' - `score'[_n+`i'] if `treated'==1 & `treated'[_n+`i']==0  & `fdif'==.
                   replace `fym' = _m`outcome'[_n+`i']        if `treated'==1 & `treated'[_n+`i']==0  & `fym'==.

                   local i = `i' + 1
               }      
          
               else if r(N)== 0  {        
                 local fstop = 1      
               }   
         
            }
         }


         local i = 1
         local bstop = 0
         local bcount = 0
         gen `bdif' =.
         gen `bym' =.

         while `bstop' == 0   {
             local lastbcount = `bcount'
             count if `bdif'==. & `treated'==1    
             local bcount = r(N)   
             
             if `bcount' == `lastbcount' {      
                local bstop = 1  
             }

             else  {      
               if r(N) != 0   {

                   replace `bdif' = `score' - `score'[_n-`i'] if `treated'==1 & `treated'[_n-`i']==0  & `bdif'==.
                   replace `bym' = _m`outcome'[_n-`i']        if `treated'==1 & `treated'[_n-`i']==0  & `bym'==.

                   local i = `i' + 1
               }      
          
               else if r(N)== 0  {        
                 local bstop = 1      
               }   
         
            }
         }


            replace _m`outcome' = `fym' if abs(`fdif')<abs(`bdif') & `treated'==1
            replace _m`outcome' = `bym' if abs(`fdif')>=abs(`bdif') & `treated'==1 
            replace _m`outcome' =. if `treated'==0

            cap replace _s`outcome'=. if _m`outcome'==.
			   lab var _m`outcome' "matched smoothed `outcome'"
			   cap lab var _s`outcome' "treated smoothed `outcome'"



			  if `"`common'"' == `""'  {

				      **** imposing COMMON SUPPORT -- on the treated only
                  tempname min max
				      sum `score' if `treated'==0
				      scalar `min'=r(min)
				      sum `score' if `treated'==0
				      scalar `max'=r(max)

				      replace _m`outcome'=. if (`score'>`max' | `score'<`min') & `treated'==1
                  cap replace _s`outcome'=. if (`score'>`max' | `score'<`min') & `treated'==1

                  count if _m`outcome'!=.

                  if r(N)==0  {                                
	                  n di in red "none of the treated lies within the common support"  
	                  exit                                      
                  }                                            
            }

 
   if `"`count'"' == `""'  { 
	   n di _newline(3) _skip(3) in g "_m`outcome'" in w " is defined only for treated (and within the common support);"
	   n di _skip(3) in w "It should be compared to the " in g `"`kernel'"' in w " (or" in g "_s`outcome'" in w ") for those treated only," 
	   n di _skip(3) in w "i.e. with _m`outcome'~=.
   }


   tempname mean1 mean0

   if `"`both'"' != `""'  {          
	   qui sum _s`outcome'
      scalar `mean1'  = r(mean)
   }                              
   else  {
	   qui sum `outcome'  if `treated'==1 & _m`outcome'!=.
      scalar `mean1'  = r(mean)
   }

   cap log on

	qui sum _m`outcome' 
   scalar `mean0'  = r(mean)
   n di _newline(3) _skip(3) in g "Mean " in w "`outcome'" in g " of matched treated  = " in y `mean1'                        
   n di _newline(1) _skip(3) in g "Mean " in w "`outcome'" in g " of matched controls = " in y `mean0'                        
   n di _newline(1) _skip(3) in g "Effect  = " in y `mean1'-`mean0'                                                           

   return scalar mean1 = `mean1'          
   return scalar mean0 = `mean0'          
   return scalar effect= `mean1'-`mean0'  
                                          


   }



set more on

	}

 }

end








