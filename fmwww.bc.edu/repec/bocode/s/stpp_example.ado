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
`". stpp R_pp2 using "https://pclambert.net/data/popmort.dta" , ///"' _newline ///
"                  agediag(age) datediag(dx)                    ///" _newline  ///
"                  pmother(sex) list(1 5 10)                    ///" _newline  ///
"                  by(sex) graphname(R_pp2, replace)                                       ///"
 
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
"recode ICSSagegrp (1=0.28) (2=0.17) (3=0.21) (4=0.20) (5=0.14), gen(ICSSwt)" _newline ///
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
  
end   