program define stpp_example
  version 16.0
  syntax [, EGNUMBER(integer 1)]
  
  if `egnumber' == 1 {
 
display ///
`". stpp R_pp1 using "https://pclambert.net/data/popmort.dta" , ///"' _newline ///
"                  agediag(age) datediag(dx)                    ///" _newline  ///
"                  pmother(sex) list(1 5 10)" _newline  
 
stpp R_pp1 using "https://pclambert.net/data/popmort.dta", ///
                  agediag(age) datediag(dx)                  ///
                  pmother(sex) list(1 5 10) graphname(R_pp1, replace)                  
  }
  else if `egnumber' == 2 {
  	
display ///
`"stpp R_pp2 using "https://pclambert.net/data/popmort.dta" ,    ///"' _newline ///
"                  agediag(age) datediag(dx)                    ///" _newline  ///
"                  pmother(sex) list(1 5 10)                    ///" _newline  ///
"                  by(sex) graphname(R_pp2, replace)            ///"
 
stpp R_pp2 using "https://pclambert.net/data/popmort.dta", ///
                  agediag(age) datediag(dx)                ///
                  pmother(sex) list(1 5 10)                ///
                  by(sex) graphname(R_pp2, replace) 
                
  }
  else if `egnumber' == 3 {

display ///
". recode age (min/44=1) (45/54=2) (55/64=3) (65/74=4) (75/max=5), gen(ICSSagegrp)" _newline ///
`". stpp R_pp3 using "https://pclambert.net/data/popmort.dta" , ///"' _newline ///
"                  agediag(age) datediag(dx)                    ///" _newline  ///
"                  pmother(sex) list(1 5 10)                    ///" _newline  ///
"                  by(sex)                                      ///" _newline  ///
"                  standstrata(ICSSagegrp)                      ///" _newline  ///
"                  graphname(R_pp3, replace)                    ///" _newline  ///
"                  standweight(0.07 0.12 0.23 0.29 0.29)        ///" 
 
recode age (min/44=1) (45/54=2) (55/64=3) (65/74=4) (75/max=5), gen(ICSSagegrp)
stpp R_pp3 using "https://pclambert.net/data/popmort.dta", ///
                  agediag(age) datediag(dx)                ///
                  pmother(sex) list(1 5 10)                ///
                  by(sex)                                  ///
                  standstrata(ICSSagegrp)                  ///
                  graphname(R_pp3, replace)                ///
                  standweight(0.07 0.12 0.23 0.29 0.29)   
                
  }
  else if `egnumber' == 4 {
  	
display ///
"recode ICSSagegrp (1=0.07) (2=0.12) (3=0.23) (4=0.29) (5=0.29), gen(ICSSwt)" _newline ///
"bysort sex: gen sextotal= _N"                                             _newline    ///
"bysort ICSSagegrp sex:gen a_age = _N/sextotal"                       _newline         ///
"gen double wt_age = ICSSwt/a_age"	                                _newline       ///
`". stpp R_pp4 using "https://pclambert.net/data/popmort.dta" , ///"' _newline ///
"                  agediag(age) datediag(dx)                    ///" _newline  ///
"                  pmother(sex) list(1 5 10)                    ///" _newline  ///
"                  by(sex)                                      ///" _newline  ///
"                  graphname(R_pp4, replace)                    ///" _newline  ///
"                  indweights(wt_age)"                     

 
recode ICSSagegrp (1=0.07) (2=0.12) (3=0.23) (4=0.29) (5=0.29), gen(ICSSwt)
bysort sex: gen sextotal= _N
bysort ICSSagegrp sex:gen a_age = _N/sextotal
gen double wt_age = ICSSwt/a_age	
stpp R_pp4 using "https://pclambert.net/data/popmort.dta", ///
                  agediag(age) datediag(dx)                ///
                  pmother(sex) list(1 5 10)                ///
                  by(sex)                                  ///
                  graphname(R_pp4, replace)                ///
                  indweights(wt_age)                          
  }  

  
  else if `egnumber' == 5 {
  	
        

display as text ///
"genindweights iw, by(sex) agegroup(ICSSagegrp) refexternal(ICSS1_5)" 
genindweights iw, by(sex) agegroup(ICSSagegrp) refexternal(ICSS1_5)
display as text ///
`"stpp R_pp4 using "https://pclambert.net/data/popmort.dta" , ///"' _newline ///
"                  agediag(age) datediag(dx)                    ///" _newline  ///
"                  pmother(sex) list(1 5 10)                    ///" _newline  ///
"                  by(sex)                                      ///" _newline  ///
"                  indweights(wt)                               ///" _newline  ///
"                  frame(stpp_results, replace)"  _newline                         
stpp R_pp5 using "https://pclambert.net/data/popmort.dta", ///
                  agediag(age) datediag(dx)                ///
                  pmother(sex) list(0 1 5 10)              ///
                  by(sex)                                  ///
                  indweights(iw)                           ///
                  frame(stpp_results, replace)
display as text "frame stpp_results: list, noobs sepby(sex)"
frame stpp_results: list, noobs sepby(sex)                  
}  
  
  
end   