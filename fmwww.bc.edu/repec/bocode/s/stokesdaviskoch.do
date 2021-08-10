*! stokesdaviskoch.do  Version 1.0  2004-05-07 JRC
*  Example from M. E. Stokes, C. S. Davis and
*  G. G. Koch, _Categorical Data Analysis Using The
*  SAS(R) System_ Second Edition. (Cary, N. Carolina:
*  SAS Institute, 2000), pp. 73-75, citing (on p. 67) 
*  G. G. Koch & S. Edwards, Clinical efficacy trials
*  with categorical data, in _Biopharmaceutical 
*  Statistics for Drug Development_, K. E. Pearce (ed.)
*  (New York: Marcel Dekker, 1988), pp. 403-51.
clear
set more off
input str6 gender str7 treat str6 response byte count
female test    none    6  
female test    some    5  
female test    marked 16
female placebo none   19 
female placebo some    7  
female placebo marked  6
male   test    none    7  
male   test    some    2  
male   test    marked  5
male   placebo none   10 
male   placebo some    0  
male   placebo marked  1
end
*
drop if count == 0
expand count
drop count
*
label define Group 0 placebo 1 test
encode treat, generate(trt) label(Group)
label define Group 0 C 1 E, modify
drop treat
label variable trt "Treatment"
note trt: C–Control treatment group; E–Experimental treatment group
*
label define Response 0 none 1 some 2 marked
encode response, generate(res) label(Response)
label define Response 0 None 1 Some 2 Marked, modify
drop response
label variable res "Response"
*
vanelteren res, by(trt) st(gender)
display r(z)^2
*  The result reported for van Elteren's test as
*  implemented in PROC FREQ . . . SCORES=MODRIDIT 
*  is chi-square = 15.0041, df = 1, P = 0.0001
*  (p. 75).
*
label define Female 0 male 1 female
encode gender, generate(sex) label(Female)
label define Female 0 M 1 F, modify
drop gender
label variable sex "Sex (is-female)"
tabodds trt res, adj(sex)
display chi2tail(2, r(chi2_tr))
*  With a second degree of freedom assigned to the
*  chi-square test statistic, this gives the result
*  for "Statistic 3 General Association" of the PROC FREQ printout
*  shown on p. 75.
exit
