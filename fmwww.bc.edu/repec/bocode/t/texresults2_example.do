////
///last edited 6/13/23 by Gabrielle Sorresso 
///purpose: explain updates of texresults 2 


clear 
sysuse auto, clear


//basic ols regression 
reg price mpg rep78 headroom trunk weight length turn displacement gear_ratio foreign

//------------------------------------------------------------------------------

//CHANGE 1: ROUNDING FEATURE -

// due to the use of the round command in the original texresults
//occasionally an error is produced where stata is unable to correctly hold certain decimals
//as a byte and can no longer round them effectively 
//texresults2 fixes this by rounding results in string form using string formats

//original error
texresults using results.txt, texmacro(coeflength) coef(length) replace 
//corrected using texresults2
texresults2 using results.txt, texmacro(coeflength2) coef(length) append
//display results 
cat results.txt

//Given this change - texresults2 has a slightly different syntax for rounding 
//Texresults2 still uses the round option but instead of using 0.001 to specify 
//rounding to the hundreths place, texresults2 uses 3. Below are some examples. 
//The default rounding is 2 decimal places. 

//example - 3 decimal places  
texresults2 using results.txt, texmacro(coefweight3) coef(weight) round(3) replace 
//example - 0 decimal places 
texresults2 using results.txt, texmacro(coeflweight0) coef(weight) round(0) append 

//display results 
cat results.txt


//------------------------------------------------------------------------------


//CHANGE 2: ADDITIONAL FUNCTIONALITY FOR PVALUE EXPORTS 

//the original texresults2 could not calculate pvalues when a z-distribution is used 
//IE logit or probit regressions 
//texresults2 has an additional command meant to calculate these values called 
//pvaluez. In texresults2 the original command pvalue still caclulates pvalues for
//regressions used a t-distribution, while pvaluez does this for regressions
//using a z-distribution 

//logit regression 
logit foreign mpg   

//texresults inability to calculate pvalue 
texresults2 using results.txt, texmacro(pvaluempg) pvalue(mpg) replace 
//texresults2 completes this task using pvaluez option 
texresults2 using results.txt, texmacro(pvaluezmpg) pvaluez(mpg) append 
//display results 
cat results.txt

//------------------------------------------------------------------------------

//CHANGE 3: ADDITION OF UPPER AND LOWER BOUND FEATURES

//texresults2 also adds optionality to automatically export the 95% confidence 
//upper and lower bound values using a t or z distribution 

//t distribution -  ols  
reg price mpg rep78 headroom trunk weight length turn displacement gear_ratio foreign

//upper bound - tdist 
texresults2 using results.txt, texmacro(ublength) ub(length) replace 
//lower bound
texresults2 using results.txt, texmacro(lblength) lb(length) append
//display results - tdist 
cat results.txt

//z ditribution - logit 
logit foreign mpg  

//upper bound 
texresults2 using results.txt, texmacro(ubmpgz) ubz(mpg) replace 
//lower bound
texresults2 using results.txt, texmacro(lbmpgz) lbz(mpg) append
//display results 
cat results.txt










