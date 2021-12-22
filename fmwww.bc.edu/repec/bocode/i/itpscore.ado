program define itpscore , rclass
syntax , treat(varname) cand(varlist) [base(varlist) thr1(real 2.71) thr2(real 3.84) rand(int 0) keepint viewiter ]
version 17

*args depvar [if] [in]
*args outcome base_covs cand_covs
*Authored by Ravaris Moore (Presidential Postdoctoral Research Fellow, Princton University; Assistant Professor of Sociology, Loyola Marymount University)
*			 Jennie Brand (UCLA, Professor of Sociology and Statistics)
*			 Tanvi Shinkre (UCLA)
*Updated  10.26.2021

*Note: use "set seed" option to make results of random covariates replicable;





*Start program timer
timer clear 1
timer on 1

display as text "{hline 95}"
display as text "Iterative Propensity Score Program Output"
display as text "{hline 95}"

capture quietly logit `treat' `base'


*Make local for all interactions;
#delimit ;
*Define threshold 1 or linear terms and threshold 2 for higher order terms for model improvment;
	*-Threshold 1 (Applies to linear terms);
	

*Run  Logit models and save ll2;
capture postclose tabresults;
tempfile tabfile;

postfile tabresults str30 round str30 test_cov double ll  max_ll  str50 best_var double iterations str300 full_model double converged using "_iterative.dta",replace ;


*Run initial logit model and save log likelihood;
dis as text _column(6) "ROUND 0: Initial Model: logit `treat' `base'";
capture quietly logit `treat' `base';
local  ll_0= `e(ll)';

*Initialize max_ll measure to some value below ll_0;
local max_ll=`ll_0';

*Generate random normal candidate covariates according to specification of rand_cov local variable;
if "`rand'"==""{;
  local rand_list ;
};
else if `rand'<=0{;
  local rand_list ;
};
else if `rand'>0{;
	local rand_list ;
         forvalues k=1(1)`rand'{;
            *-Check whether a variable named _itpsrand already exists;
            capture confirm  variable _itpsrand`k';

              if !_rc {;
                 drop _itpsrand`k';
         	     gen _itpsrand`k' =rnormal(0,1);
         	
                 label variable _itpsrand`k' "Standard normal random covariate `k' generated by itpscore package";
         	     local rand_list `rand_list' _itpsrand`k';
         	  };
         	  else if _rc {;
         	
         	     gen _itpsrand`k' =rnormal(0,1);
         	
                  label variable _itpsrand`k' "Standard normal random covariate generated by itpscore package";
         	     local rand_list `rand_list' _itpsrand`k';
              };
         };

};



local best_cov ;
local covlist `base';
local round=0;
local first_order `cand' `rand_list};
local cov_num =0;
local total_regs=0;


*-Run loop on FIRST ORDER controls;
*-Run a loop that continues adding interactions until the model is no longer improved;
*------------------------------------------------------------------------------------;
while (2*(`max_ll'-`ll_0')> `thr1' |`round'==0){;	
	
	*Keep round counter;
	local round=`round'+1;
	dis as text _column(6) "---> Linear Round `round'";
	
	*-Set update ll of previous best model;
	local ll_0 = `max_ll';

		*Run a logit model with each interaction to identify variable that leads to greatest model improvement.;
		foreach var of local first_order{;
		if "`viewiter'"=="viewiter" {;
			dis as text _column(6) "First Order: Round `round', cov=`cov_num': quietly  logit `treat' `var'  `covlist'" ;
		};	
			 capture quietly logit `treat' `var' `covlist';
			
			
			local ll = `e(ll)';
			
		if "`viewiter'"=="viewiter" {;
			dis as text _column(6) "---> Improvement? =";
			dis as text _column(6) "(2*(`ll'-`ll_0'))";
			dis = round((2*(`ll'-`ll_0')),0.000000001);
		};
		
			*-Update count of total logit regressions;
			local total_regs=`total_regs'+1;
			
			
	        *-Identify best covariate in this round of iterations. Compare loglikelihood to ;
			*-log likelihood of other models in loop to see if current covariate beats previous best;
			if ((`ll'-`max_ll')>0){;
				local best_cov `var';
				local max_ll = `ll';
				dis as text _column(14)     "Updated Best:  `var'"  _column(61)    "Log Likelihood = `e(ll)'";
			};
	
			
			post tabresults ("`round'") ("`var'") (`ll')  (`max_ll')  ("`best_cov}") ( `e(ic)' ) ("`e(cmdline)'") (`e(converged)');
	    local cov_num=`cov_num'+1;
		
		};



	*Pull best cov out of list of eligible interactions;
	foreach var of local first_order{;
	
		if ("`var'"== "`best_cov}"){;
			local new_ias `new_ias' ;
		};
		
		else if  ("`var'"!= "`best_cov}"){;
			local new_ias `new_ias' `var';
		};
	};
	
	local first_order `new_ias';
	local new_ias ;
	local cov_num=1;
    local covlist `covlist' `best_cov';
	

*End of round (First Order Loop);


};

*-START---Create interactions out of variables chosen in the first round;




     local second_order ;
     *-Create interaction terms from cand_covs and base_covs;
     local cand_list2 `covlist';
	 local cand_list3 `covlist';


	*-Uncommented this block of code;
	
	 *Construct cand_list2 when rand_cov = 0;
	 if  "`rand'"==""  {;
	     local cand_list2 `covlist' ;
	 };
	 else if `rand'==0   {;
	     local cand_list2 `covlist' ;
	 };
     *Add an option that can add a random normal variable to the covariate list;
     else if `rand'>0{;

         forvalues k=1(1)`rand'{;
            *-Check whether a variable named _itpsrand already exists;
            capture confirm  variable _itpsrand`k';

              if !_rc {;
                 drop _itpsrand`k';
         	     gen _itpsrand`k' =rnormal(0,1);
         	
                 label variable _itpsrand`k' "Standard normal random covariate `k' generated by itpscore package";
         	     local cand_list2 `covlist' _itpsrand`k';
         	  };
         	  else if _rc {;
         	
         	     gen _itpsrand`k' =rnormal(0,1);
         	
                  label variable _itpsrand`k' "Standard normal random covariate generated by itpscore package";
         	     local cand_list2 `covlist' _itpsrand`k';
            };
         };
     };
	
	 local cand_list3 `cand_list2';
	
	




	 foreach var1 of local cand_list2{;

     	    *Generate second order terms;
     	foreach var2 of local cand_list3{;
     		capture drop x_`var1'`var2';
     		quietly gen x_`var1'`var2'=`var1' * `var2';
     		label variable x_`var1'`var2' "Auto Interaction: `var1'*`var2'";
     	
     	
     		local second_order `second_order' x_`var1'`var2' ;
     	};


     		*-All Var1 second order terms are generated. Omit var1 from loop 2 to avoid redundant second order terms;
     		foreach testvar of local cand_list3{;
     			if "`testvar'"=="`var1'" {;
     				*dis as text "Variable match `testvar'==`var1'";
     				local cand_list4 `cand_list4';
     			};
     	
     			else{;
     				*dis as text "No variable match `testvar'!=`var1'";
     				local cand_list4 `cand_list4' `testvar';
     			};
     			
     		};

     *Update loop two variable;
     local cand_list3 `cand_list4';
     local cand_list4;

     };

     *dis as text "Local Second_order = `second_order}";


*-END-----Create interactions out of variables chosn in the first round;


*-Run loop on SECOND ORDER controls;
*-Run a loop that continues adding interactions until the model is no longer improved;
*------------------------------------------------------------------------------------;
local best_cov ;
local cov_num=0;
local round=0;



while (2*(`max_ll'-`ll_0') > `thr2' | `round' ==0){;
	


	
	local ll_0 =`max_ll';
	
	
	local round=`round'+1;
	

	dis as text _column(6) "---> Interaction Round `round'";

	
	*-Set update ll of previous best model;
	
	

		*Run a logit model with each interaction to identify variable that leads to greatest model improvement.;
		foreach var of local second_order{;
		if "`viewiter'"=="viewiter" {;
			dis as text _column(6) "Second Order: Round `round', cov=`cov_num}: quietly  logit `treat' `var'  `covlist'" ;
		};
			capture quietly logit `treat' `var' `covlist';
			
			local ll=`e(ll)';
		if "`viewiter'"=="viewiter" {;	
			dis as text _column(6) "---> Improvement? =" ;
			dis as text _column(6) "(2*(`ll'-`ll_0'))" ;
			dis = (2*(`ll'-`ll_0')) ;
		};	
			*-Update count of total logit regressions;
			local total_regs =`total_regs'+1;
			
			
	        *-Identify best covariate in this round of iterations. Compare loglikelihood to ;
			*-log likelihood of other models in loop to see if current covariate beats previous best;
			if ((`ll'-`max_ll')>0){;
				local best_cov `var';
				local max_ll=`ll';
				dis as text _column(14)     "Updated Best:  `var'"  _column(61)    "Log Likelihood = `e(ll)'";

			};
	
			
            post tabresults ("`round'") ("`var'") (`ll')  (`max_ll')  ("`best_cov'") ( `e(ic)' ) ("logit `treat' `var' `covlist'") (`e(converged)');
			
	    local cov_num=`cov_num'+1;
		
		};



	*Pull best cov out of list of eligible interactions;
	foreach var of local second_order{;
	
		if ("`var'"== "`best_cov'"){;
			local new_ias `new_ias' ;
		};
		
		else if  ("`var'"!= "`best_cov'"){;
			local new_ias `new_ias' `var';
		};
	};
	
	local first_order `new_ias';
	local new_ias ;
	local cov_num=1;
	
    local covlist `covlist' `best_cov';	

*End of round (Second Order Loop);


};
*dis as text "New ias=`new_ias'";
postclose tabresults;



timer off 1;
quietly timer list;
local hours = floor(`r(t1)' / 3600);
local mins = floor(mod(`r(t1)', 3600)/60);
local seconds = mod(`r(t1)', 60);
*display as result "----------------------------------------------------------------------------------------";
display as text "{hline 95}";
display as text _column(6)  "Iterative Propensity Score Process Complete. ";
display as text _column(6)  "Total Run Time  : `hours' hours `mins' minutes `seconds' seconds";
display as text _column(6)  "Program Executed: `c(current_date)' `c(current_time)'";
*display as result "----------------------------------------------------------------------------------------";
display as text "{hline 95}";
display as text _column(6)  "Dependent Variable"          _column(45)       "`treat'" ;
display as text _column(6)  "Base Model"                  _column(45)       "`base'" ;

if "`rand'"=="" {;
display as text _column(6)  "Random Covariate(s)"         _column(45)       "No";
display as text _column(6)  "Candidate Covariates"        _column(45)       "`cand'";
};

else if `rand'==0 {;
display as text _column(6)  "Random Covariate(s)"         _column(45)       "No";
display as text _column(6)  "Candidate Covariates"        _column(45)       "`cand'";
};

else if `rand'==1 {;
display as text _column(6)  "Random Covariate(s)"         _column(45)       "Yes, 1";
display as text _column(6)  "Candidate Covariates"        _column(45)       "`cand'";

};
else if `rand'>1 {;
display as text _column(6)  "Random Covariates"           _column(45)       "Yes, `rand'";
display as text _column(6)  "Candidate Covariates"        _column(45)       ;

foreach var of local cand{;
dis as text _column(45) "`var'";
};
dis as text " ";

};
display as text _column(6)  "Total Models Estimated/Compared" _column(45)   "`total_regs'";


display as text _column(6)  "LL Improvement Threshold 1"      _column(45)   "`thr1'  (Applies to linear terms.)";

display as text _column(6)  "LL Improvement Threshold 2"      _column(45)   "`thr2' (Applies to interaction terms.)";

*display as result "Second Order Candidate Covariates : `second_order'";
display as text   "";

display as text "{hline 95}";
display as text _column(6) "Iterative Model Covariates"         _column(45)   ;
foreach var of local covlist{;
dis as text _column(45) "`var'";
};

display as text "{hline 95}";
logit `treat' `covlist';
display as text "{hline 95}";

display as text _column(6) "Description and Summary Statistics of Iterative Model Covariates";
*display as text "{hline 95}";


des `covlist';
su `covlist';
if ("`second_order'"~="" & "`'keepint"~="keepint" ){;
drop `second_order';
};
if `rand'>=1{;
drop _itpsrand* ;
};
*use "_iterative.dta";
*list ;

display as text   "";
display as text   "";
dis as text _column(6) "Iterative Propensity Score (itpscore) program output complete.";
dis as text "{hline 95}";
return scalar n_regs = `total_regs';
return scalar ll     = `ll';
return scalar max_ll = `max_ll';
return scalar ll_0   = `ll_0';
return scalar thresh1 = `thr1' ;
return scalar thresh2 = `thr2';
return scalar rand_cov = `rand';


return local cand_covs  = "`cand'";
return local base_covs  = "`base'";
return local treat      = "`treat'";
return local covlist    = "`covlist'";
global covlist `covlist';

*macro drop max_ll;

end;
