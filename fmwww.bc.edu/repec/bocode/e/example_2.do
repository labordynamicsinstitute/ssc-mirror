
/* Using the dialog box */
use "C:\subsim2\examples\example.dta", clear
cd C:\subsim2\examples\ex2                                                           
asubini example_2


/* using the Stata commands */
#delimit ;
use "C:\subsim2\examples\example.dta", clear ;
pschset i_psch1 , nblock(2) bun(2) mxb1(36) sub1(.3) tr1(.1) sub2(0) tr2(.4);
pschset f_psch1 , nblock(2) bun(2) mxb1(36) sub1(.2) tr1(.2) sub2(0) tr2(.4);


asubsim pc_exp_tot, hsize(hhsize) pline(pline) nitems(2) 
xfil(C:\subsim2\examples\ex2\MyCountry2.xml) 
inisave(C:\subsim2\examples\ex2\example_2) 
folgr(C:\subsim2\examples\ex2) 
cname(MyCountry) ysvy(2008) ysim(2013) lcur(LocCur) gvimp(0) 
opr1( sn(Flour) qu(kg) it(pc_exp_flour) ps(2) el(-0.3) ) 
opr2( sn(Rice) qu(kg) it(pc_exp_rice) ps(1) ip(0.14) su(0.4) fp(0.24) el(-0.5) ) 
opgr1( min(0.01) max(0.95) ogr(title(Figure 01: The expenditures on the good relatively to the total expenditures (%))) )
opgr2( min(0.01) max(0.95) ogr(title(Figure 02: The per capita benefits through the items)) )
opgr9( min(0) max(100) )
opgr10( min(0) max(100) )
;



