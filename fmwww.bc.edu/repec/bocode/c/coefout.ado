//Author: @Niranjan Kumar, CAFRAL
//regression post-estimation application; quite useful in counter-factual analysis 
//First Application: Bank Entry, New Loans, and Misallocation by Dr. Nirvana Mitra and Dr. Pavel Chakraborty 

cap prog drop coefout
program define coefout

   version 10.0 //minimum stata version required for the stata-command to work 
   
   syntax varlist(min = 1), [pmin(string) pmax(string)] [labelname(string)] [keep(string)]
   
   //save the coefficient vector 
   mat coef = e(b) 
   
   //save the variance-covariance vector 
   mat cov  = e(V)
   
   //residual degrees of freedom
   scalar df= e(df_r)    

   
   
*****************************************************************************
//first cut: syntax checkers
*****************************************************************************
   
   //check if both varlist and labelname are not empty
   if "`varlist'" == "" & "`labelname'" == ""{
   	 di in bl "Nothing to do here since option varname and variable list both are empty"
	 exit 0 
   }
   
   
   local keepval = ""
   //check the option keep and create a default version for it 
   if "`keep'" ==""{
   	
	  local keepval= "def"
	  
   }
   else{
   	
	 local keepval: di "`keep'"
	
   }
   
   
*****************************************************************************
// part-1 : calculate standard-errors, t-stats, p-values 
*****************************************************************************
   
   //variance-covariance matrix : number of rows 
   local n = rowsof(cov)
   
   //row and column size of coeficient vector 
   local num_rows1 = rowsof(coef) //It is 1 but in case if multiple regressions saved for same variable names 
   local num_cols1= colsof(coef)
   

   //create a matrix to store the diagonal elements
   matrix cov_diag = J(`n', 1, .)
 
   //loop over the diagonal elements and copy them to the se_diag matrix
   forval m = 1/`n' {
      matrix cov_diag[`m', 1] = cov[`m', `m']
   }
  
  //a blank standard error vector generated 
    matrix se= J(`n', 1, .)

  // take a square root of the covariance-variance diagonal vector 
  forval m = 1/`n' {
    matrix se[`m', 1] = sqrt(cov_diag[`m', 1])
	
  } 
  
  
   //number of rows and columns of standard error vector 
   matrix coef_new = coef'
   
   //compute the t-stats 
   matrix t = J(`n', 1, .)
   
   forval m = 1/`n'{
   	
      if se[`m', 1] != . & coef_new[`m', 1] !=. {
	  	
        matrix t[`m', 1] = coef_new[`m', 1]/se[`m', 1]
      }
      else {
        matrix t[`m', 1] = 0.0
      }
}
   

  //compute the p-value
   matrix p = J(`n', 1, .)

   forval m = 1/`n' {
	
     scalar t_stat = t[`m', 1]
	
     scalar p_val = 2*ttail(df, abs(t_stat))
	
     matrix p[`m', 1] = p_val
   }


   matrix p1 = p
 
   global num_rows1 : rowfullnames coef_new
 
   matrix rownames p1 = $num_rows1
   
   matrix rownames se = $num_rows1
   
   matrix rownames t = $num_rows1
   
   

   

********************************************************************************
//part-2 : syntax analysis  
********************************************************************************
   
   //option pmin and pmax syntax check: 
   
   if "`pmin'" != "" & "`pmax'" == ""{
   	 di in r "Define the range for p-values. pmax value is missing. "
	 exit 498
   }
   else if "`pmin'" == "" & "`pmax'" != ""{
   	
   	 di in r "Define the range for p-values. pmin value is missing. "
	 exit 498
   }
   
   
   local pmin_val = ""
   local pmax_val = ""

   // handle pmin 
   if "`pmin'" != ""{
	   local pmin_val: di "`pmin'"
   }
   else if "`pmin'" == "" {
	   local pmin_val = "default_pmin"
   }

   //handle pmax
   if "`pmax'" != ""{
   	
	   local pmax_val: di "`pmax'"
	   
   }
   
   else if "`pmax'" == ""{
   	
	  local pmax_val = "default_pmax"
   }

   //handle varlist 
   local varlist1 = ""
   
   if "`varlist'" != ""{
      local varlist1: di "`varlist'"
      scalar var_count = `:word count `varlist1''
   }
   else {
	  scalar var_count = 0.0
   }

   
   //handle labelname 
   local varnamelist = ""
   
   if "`labelname'" != ""{
   	
      local varnamelist: di "`labelname'"
	  	  
      scalar varname_count = `:word count `varnamelist''
	}
	
   else{
	   scalar varname_count = 0.0 
   }

   //total number of variables (varlist and varnames-interaction terms)
   
   scalar total_count = varname_count + var_count
   
   
   
   //combine the total variables and variable labels and save them in a local 
   if "`varlist1'" != "" & "`varnamelist'" != "" {
       
	 local final_varlist = "`varlist1'" + " " + "`varnamelist'" 
	 
   }
   
   else if "`varlist1'" != "" & "`varnamelist'" == ""{
       
	 local final_varlist = "`varlist1'" 
   }
   
   else {
       
   	 local final_varlist = "`varnamelist'" 
   }
   
   
   
********************************************************************************
//part-3 output and error handling 

//It also checks if any variable name or variable label is incorrect or not matched 
********************************************************************************
 
 
//case-1. 

if strpos("`keepval'", "p")>0 & strpos("`keepval'", "t")==0 & strpos("`keepval'", "se")==0 {
			
 //result matrix; initialized as blank 
 mat A=  J(total_count, 2, .)
 
			   
 scalar shift = 1
 
 foreach var of local final_varlist{
			 	
		if strpos("$num_rows1", "`var'")>0 {
		 
		       if strpos("`pmin_val'", "default_pmin")>0 & strpos("`pmax_val'", "default_pmax")>0 {
		 
		           mat A[shift, 1] = coef_new["`var'", 1]
		 
		           mat A[shift, 2] = p1["`var'", 1]
		           }
			 
		       else {
	             //filter based on range of p-value 
				if (p1["`var'", 1] >= `pmin_val' & p1["`var'", 1] <= `pmax_val'){ 
		             mat A[shift, 1] = coef_new["`var'", 1] 
				}	
				
		        mat A[shift, 2] = p1["`var'", 1] 
				
			   }
		}
	 	 
		else{
		
		di in r "Specified variable name or variable label are not correct."
		exit 498
	        }
			
		scalar shift = shift+ 1
	}	
	
 mat colnames A = coef p
 mat rownames A = `final_varlist'
	
}

//case-2		
else if strpos("`keepval'", "t")>0 & strpos("`keepval'", "p")==0 & strpos("`keepval'", "se")==0  {

//result matrix; initialized as blank 
		
 mat A=  J(total_count, 2, .)
			   
 scalar shift = 1
 
 foreach var of local final_varlist{
			 	
		if strpos("$num_rows1", "`var'")>0 {
		 
		       if strpos("`pmin_val'", "default_pmin")>0 & strpos("`pmax_val'", "default_pmax")>0 {
		 
		           mat A[shift, 1] = coef_new["`var'", 1]
		 
		           mat A[shift, 2] = t["`var'", 1]
		           }
			 
		       else {
		        	//filter based on range of p-value 
				   if (p1["`var'", 1] >= `pmin_val' & p1["`var'", 1] <= `pmax_val'){ 
					
		                  mat A[shift, 1] = coef_new["`var'", 1] 
						  
				     }
		 
		        mat A[shift, 2] = t["`var'", 1] 
				
			         }
		}
	 	 
		else{
		
		di in r "Specified variable name or variable label are not correct."
		exit 498
	        }
			
		scalar shift = shift+ 1
	}	
	
 mat colnames A = coef t
 mat rownames A = `final_varlist'
	 
}

//case-3 
else if strpos("`keepval'", "se")>0 & strpos("`keepval'", "t")==0 & strpos("`keepval'", "p")==0 {
		
		 
	//result matrix; initialized as blank 
		
 mat A=  J(total_count, 2, .)
			   
 scalar shift = 1
 
 foreach var of local final_varlist{
			 	
		if strpos("$num_rows1", "`var'")>0 {
		 
		       if strpos("`pmin_val'", "default_pmin")>0 & strpos("`pmax_val'", "default_pmax")>0 {
		 
		           mat A[shift, 1] = coef_new["`var'", 1]
		 
		           mat A[shift, 2] = se["`var'", 1]
		           }
			 
		       else {
		        	//filter based on range of p-value 
				if (p1["`var'", 1] >= `pmin_val' & p1["`var'", 1] <= `pmax_val'){ 
		        mat A[shift, 1] = coef_new["`var'", 1] 
				}
		        mat A[shift, 2] = se["`var'", 1] 
				
			         }
		}
	 	 
		else{
		
		di in r "Specified variable name or variable label are not correct."
		exit 498
	        }
			
		scalar shift = shift+ 1
	}	
	
 mat colnames A = coef se 
 mat rownames A = `final_varlist'
	 
}


//case-4
else if (strpos("`keepval'", "p t")> 0 | strpos("`keepval'",  "t p")>0 ) & (strpos("`keepval'",  "se t p")==0 & strpos("`keepval'",  "t se p")==0 & strpos("`keepval'",  "se p t")==0 & strpos("`keepval'",  "p se t")==0 & strpos("`keepval'",  "p t se")==0 & strpos("`keepval'",  "t p se")==0){

 //result matrix; initialized as blank 
		
 mat A=  J(total_count, 3, .)
			   
 scalar shift = 1
 
 foreach var of local final_varlist{
			 	
		if strpos("$num_rows1", "`var'")>0 {
		 
		       if strpos("`pmin_val'", "default_pmin")>0 & strpos("`pmax_val'", "default_pmax")>0 {
		 
		           mat A[shift, 1] = coef_new["`var'", 1]
				   
				   mat A[shift, 2] = t["`var'", 1]
		 
		           mat A[shift, 3] = p1["`var'", 1]
				   
		           }
			 
		       else {
		        	//filter based on range of p-value 
				if (p1["`var'", 1] >= `pmin_val' & p1["`var'", 1] <= `pmax_val'){ 
		               mat A[shift, 1] = coef_new["`var'", 1] 
				}
				
		        mat A[shift, 2] = t["`var'", 1] 
				
				mat A[shift, 3] = p1["`var'", 1]
				
				
			    }
		}
	 	 
		else{
		    di in r "Specified variable name or variable label are not correct."
		    exit 498
	        }
			
		scalar shift = shift+ 1
	}	
	
 mat colnames A = coef t p 
 mat rownames A = `final_varlist'
	 
}

//case-5
else if (strpos("`keepval'", "p se")> 0 |  strpos("`keepval'", "se p")>0) & (strpos("`keepval'",  "se t p")==0 & strpos("`keepval'",  "t se p")==0 & strpos("`keepval'",  "se p t")==0 & strpos("`keepval'",  "p se t")==0 & strpos("`keepval'",  "p t se")==0 & strpos("`keepval'",  "t p se")==0){
		
	//result matrix; initialized as blank 
		
 mat A=  J(total_count, 3, .)
			   
 scalar shift = 1
 
 foreach var of local final_varlist{
			 	
		if strpos("$num_rows1", "`var'")>0 {
		 
		       if strpos("`pmin_val'", "default_pmin")>0 & strpos("`pmax_val'", "default_pmax")>0 {
		 
		           mat A[shift, 1] = coef_new["`var'", 1]
				   
				   mat A[shift, 2] = se["`var'", 1]
		 
		           mat A[shift, 3] = p1["`var'", 1]
				   
		           }
			 
		       else {
		        	//filter based on range of p-value 
				if (p1["`var'", 1] >= `pmin_val' & p1["`var'", 1] <= `pmax_val'){ 
		           mat A[shift, 1] = coef_new["`var'", 1] 
				}
		        mat A[shift, 2] = se["`var'", 1]  
				
				mat A[shift, 3] = p1["`var'", 1]
			         }
		}
	 	 
		else{
		
		di in r "Specified variable name or variable label are not correct."
		exit 498
	        }
			
		scalar shift = shift+ 1
	}	
	
 mat colnames A = coef se p 
 mat rownames A = `final_varlist'
	 
}	

//case-6	
else if (strpos("`keepval'", "t se")> 0 |  strpos("`keepval'", "se t")>0) & (strpos("`keepval'",  "se t p")==0 & strpos("`keepval'",  "t se p")==0 & strpos("`keepval'",  "se p t")==0 & strpos("`keepval'",  "p se t")==0 & strpos("`keepval'",  "p t se")==0 & strpos("`keepval'",  "t p se")==0){
//result matrix; initialized as blank 
		
 mat A=  J(total_count, 3, .)
			   
 scalar shift = 1
 
 foreach var of local final_varlist{
			 	
		if strpos("$num_rows1", "`var'")>0 {
		 
		       if strpos("`pmin_val'", "default_pmin")>0 & strpos("`pmax_val'", "default_pmax")>0 {
		 
		           mat A[shift, 1] = coef_new["`var'", 1]
				   
				   mat A[shift, 2] = se["`var'", 1]
		 
		           mat A[shift, 3] = t["`var'", 1]
				   
		           }
			 
		       else {
		        	//filter based on range of p-value 
				if (p1["`var'", 1] >= `pmin_val' & p1["`var'", 1] <= `pmax_val'){ 
		           mat A[shift, 1] = coef_new["`var'", 1] 
				}
	
		        mat A[shift, 2] = se["`var'", 1]  
				
				mat A[shift, 3] = t["`var'", 1]
			         }
		}
	 	 
		else{
		
		di in r "Specified variable name or variable label are not correct."
		exit 498
	        }
			
		scalar shift = shift+ 1
	}	
	
 mat colnames A = coef se t  
 mat rownames A = `final_varlist'
	 
}
		
//case-7
else if strpos("`keepval'", "p t se")> 0 | strpos("`keepval'", "p se t")>0 | strpos("`keepval'", "t se p")>0 | strpos("`keepval'", "t p se")>0 |strpos("`keepval'", "se t p")>0 | strpos("`keepval'", "se p t")>0 {

//result matrix; initialized as blank 
		
 mat A=  J(total_count, 4, .)
			   
 scalar shift = 1
 
 foreach var of local final_varlist{
			 	
		if strpos("$num_rows1", "`var'")>0 {
		 
		       if strpos("`pmin_val'", "default_pmin")>0 & strpos("`pmax_val'", "default_pmax")>0 {
		 
		           mat A[shift, 1] = coef_new["`var'", 1]
				   
				   mat A[shift, 2] = se["`var'", 1]  
				   
				   mat A[shift, 3] = t["`var'", 1]
		 
		           mat A[shift, 4] = p1["`var'", 1]
				   
		           }
			 
		       else {
			   	
				//filter based on range of p-value 
				if (p1["`var'", 1] >= `pmin_val' & p1["`var'", 1] <= `pmax_val'){ 
		           mat A[shift, 1] = coef_new["`var'", 1] 
				}
					   
				 mat A[shift, 2] = se["`var'", 1]  
				   
				 mat A[shift, 3] = t["`var'", 1]
		 
		         mat A[shift, 4] = p1["`var'", 1]
				   
			      }
		}
	 	 
		else{
		
		di in r "Specified variable name or variable label are not correct."
		exit 498
	        }
			
		scalar shift = shift+ 1
	}	
	
 mat colnames A = coef se t p 
 mat rownames A = `final_varlist'
	 
}

//case-8 default 
else if strpos("`keepval'", "def")>0 {
//result matrix; initialized as blank 
		
mat A=  J(total_count, 1, .)


scalar shift = 1

 
foreach var of local final_varlist{	

 	
	if strpos("$num_rows1", "`var'")>0 {
		
		 
		    if strpos("`pmin_val'", "default_pmin")>0 & strpos("`pmax_val'", "default_pmax")>0 {
			   	
			   	   mat A[shift, 1] = coef_new["`var'", 1]
				   
			   }
			   
			   else {
			     
				//filter based on range of p-value 
				if (p1["`var'", 1] >= `pmin_val' & p1["`var'", 1] <= `pmax_val'){
			   	
		                  mat A[shift, 1] = coef_new["`var'", 1] 
				  }
				
			   }
			  	   
	   }
	
	  else{
		di in r "Specified variable name or variable label are not correct."
		exit 498
	    }	
		
    scalar shift = shift + 1	
 }

  mat colnames A =  coef 
  
  mat rownames A = `final_varlist'
  
}	

//case-9: In case if there is anything else in the specification
else{
	di in r "Incorrect specification"
	exit 498
}
	
matrix A = A

matlist A 
 
end 