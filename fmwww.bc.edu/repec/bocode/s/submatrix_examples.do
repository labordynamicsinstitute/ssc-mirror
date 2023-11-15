cscript
set varabbrev off
version 17.0

log using submatrix_examples, replace
//EXAMPLE 1
matrix A=(1,3,4,6,7,8,10 \ 1,3,4,6,7,8,10) 
submatrix A, colnum(1 5 7)
matlist r(mat)
submatrix A, dropcolnum(2(1)4 6 )
matlist r(mat)
submatrix A, colnames(c1 c5 c7)
matlist r(mat)

//EXAMPLE 2
webuse nlswork, clear
quietly xtreg ln_wage grade age c.age#c.age ttl_exp c.ttl_exp#c.ttl_exp tenure c.tenure#c.tenure 2.race not_smsa south i.year##(i.msp i.ind_code), be
return list


quietly xtreg, coeflegend
matlist ( r(table)["b" ,"tenure".."c.tenure#c.tenure"] \ r(table)["pvalue" ,"tenure".."c.tenure#c.tenure"] ) ',  twidth(20) 
matlist ( r(table)["b" ,"south"] \  r(table)["pvalue" ,"south"] )',  twidth(20) 
matlist ( r(table)["b" ,"69.year#1.msp".."88.year#1.msp"] \   r(table)["pvalue" ,"69.year#1.msp".."88.year#1.msp"] ) ',  twidth(20) 

  
webuse nlswork, clear
quietly xtreg ln_wage grade age c.age#c.age ttl_exp c.ttl_exp#c.ttl_exp tenure c.tenure#c.tenure 2.race not_smsa south i.year##(i.msp i.ind_code), be
matrix results=r(table)
submatrix results, rownames(b pvalue) colnames(tenure c.tenure#c.tenure south i.year#1.msp) colvarlist ignore
matlist r(mat)',  twidth(20)    
matrix drop _all

//EXAMPLES 3 AND 4
matrix C = (.25, .5*.25 \ .5*.25, .25)
set seed 12345
drawnorm u0 u1, n(2000) cov(C) 
generate son = exp(u1) 
generate dad = exp(u0)
drop u*
matrix drop C
cap net install st0437, replace
quietly igmobil son dad, matrix(transition) classes(20)
matrix dir
matrix transition2=( transition[1..5, 1..5], transition[1..5, 16..20] ) \ ( transition[16..20, 1..5], transition[16..20, 16..20] )
matlist transition2


submatrix transition, dropcolnum(6(1)15) droprownum(6(1)15)
matlist r(mat)


submatrix transition, dropcolnum(1(1)7 14(1)20) rownames(r5 r10 r15 r20)
matlist r(mat)


//EXAMPLE 5
matrix drop _all
webuse sysdsn1, clear
mlogit insure age male nonwhite i.site, base(3)
matrix b=e(b)
submatrix b, dropcolnames("Uninsure:") colnames(age male)
matlist r(mat)
matrix b1=r(mat)
submatrix b1, colnames( Indemnity: Prepaid:)
matlist r(mat)
log close
 