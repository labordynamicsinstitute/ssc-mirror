.-
help for ^coefout^                                         
.-


Regression postestimation command coefout filters the coefficients for input variables and, or interaction terms with the labelname including for a range of p-value. 
The output matrix has an option to keep p-value,t-stats and standard errors to be included in filteration. 
------------------------------------------------------------------------------------------------------------------------------------------------------------------------

^coefout^ ^varlist(min = 1)^, [^pmin(string)^ ^pmax(string)^] [^labelname(string)^] [^keep(string)^]

^Description^
-------------

Post regression, ^coefout^ saves the beta coefficients for all specified variables and, or labelnames(given for any interaction terms). The ^coefout^ has options to save 
the regressors' coefficients for a range of p-value. The output using this command can be saved in matrix for further usage. 


^coefout^ has the following options. 

^Options^
--------

^varlist(string)^ specifies variable list (minimum one variable required) without comma as input to produce coefficient vector. 


^pmin(^string^)^ takes the minimum input for p-value. In case if ^pmin^ is not specified then it will take default value. 


^pmin(^string^)^ takes the maximum input for p-value. In case if ^pmax^ is not specified then it will also take default value. 

Note: ^pmin^ and ^pmax^ both can be either specified together or not provided by the user. Only one out of two for p-value range can not be given for ^coefout^. 

^labelname(^names^)^ takes the multiple names without comma (interaction terms as regressors) as input to keep the beta coefficients in ^coefout^. 

^keep(^p se t^)^ takes 3 options : p-value and, or t-stats and, or Standard Errors. Any combination of all three can be specified in the option. If none of them are
specified then ^coefout^ will only provided ^coefficient^ column as default option. 


^Output^
---------

Once the command ^coefout^ is applied, the output can be saved in a ^matrix^. See below to check this out. 


^Example 1^
---------

     
	 . webuse regsmpl, clear
	 
	 . regress ln_wage age c.age#c.age tenure, vce(cluster id)
	 
	 . coefout age, labelname(c.age#c.age) 
	 
	 . coefout age, pmin(0.0) pmax(0.10) labelname(c.age#c.age)
	 
	 . coefout age, pmin(0.0) pmax(0.10) labelname(c.age#c.age) keep(p se)
	 
	   In case if any of the output should be saved. Use the following: 
	   
	 . matrix define B = A 
	 
	 

^Example 2^
---------
   Get the 1-p weighted beta coefficients for some regressors and save the output in a matrix. 
   
   	 . webuse regsmpl, clear
	 
	 . regress ln_wage grade age ttl_exp c.age#c.age tenure, vce(cluster id)
	 
	 . coefout age grade ttl_exp, labelname(c.age#c.age) keep(p)
	 
	 . matrix B = A
	 
	 . scalar num_rows = rowsof(B)
	 
	 . matrix C = J(num_rows, 1, .)
	 
	  forvalues i = 1/`=num_rows' {
        
        matrix C[`i', 1] = B[`i', 1] * (1 - B[`i', 2])
	   
       }
	   
	 . matlist C
	 
	   
	  
	   
	  

	  
	  
NOTE: There are several other use cases of ^coefout^ such as plotting bar graph for some regressors out of many from a regression specification. 
	
Author
------
Niranjan Kumar
Centre for Advanced Financial Research and Learning
niranjan.kumar@cafral.org.in
nirnajanducic@gmail.com


	
Acknowledgement
---------------
I thank Dr. Nirupama Kulkarni and Dr. Nirvana Mitra for their academic support and guidance. 

   
   


	 
	  


























































	 
	 
	 
	 
	