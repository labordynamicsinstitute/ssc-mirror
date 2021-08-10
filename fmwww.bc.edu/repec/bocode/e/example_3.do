cd "C:\subsim2\examples\"
use example.dta, clear
cd ex3                                                         
asubini example_3

/* Using the Stata commands */
                                
pschset iflour , nblock(2) tr1( 0.09000 ) sub1( 0.940 ) tr2( 1.03000 ) mxb1( 36 ) bun( 2 )
pschset iflour_bread , nblock(1) tr1( 0.03700 ) sub1( 0.922 )   bun( 2 )
pschset isemolina , nblock(2) tr1( 0.08000 ) sub1( 0.831 ) tr2( 0.91100 ) mxb1( 12 ) bun( 2 )
pschset irice , nblock(2) tr1( 0.14000 ) sub1( 1.419 ) tr2( 1.55900 ) mxb1( 30 ) bun( 2 )
pschset isugar , nblock(2) tr1( 0.25000 ) sub1( 1.068 ) tr2( 1.31800 ) mxb1( 24 ) bun( 2 )
pschset itea , nblock(2) tr1( 1.50000 ) sub1( 3.597 ) tr2( 5.09700 ) mxb1( 2.4 ) bun( 2 )
pschset imacaroni, nblock(2) tr1( 0.20000 ) sub1( 1.194 ) tr2( 1.39400 ) mxb1( 18 ) bun( 2 )
pschset ioil , nblock(2) tr1( 0.60000 ) sub1( 2.802 ) tr2( 3.40200 ) mxb1( 18 ) bun( 2 )
pschset itomato , nblock(2) tr1( 0.60000 ) sub1( 1.541 ) tr2( 2.14100 ) mxb1( 12 ) bun( 2 )
pschset imilk_children , nblock(2) tr1( 7.50000 ) sub1( 4.750 ) tr2( 12.25000 ) mxb1( 38.4 ) bun( 2 )
pschset imilk_concentrated , nblock(2) tr1( 0.97500 ) sub1( 1.647 ) tr2( 2.62200 ) mxb1( 14.76 ) bun( 2 )
                   

                               
/* S1: -30% of sub   */                              
                                
                  
pschset f1_flour , nblock(2) tr1( 0.3720000 ) sub1( 0.6580000 ) tr2( 1.03000 ) mxb1( 36 ) bun( 2 )
pschset f1_flour_bread , nblock(1) tr1( 0.3136000 ) sub1( 0.6454000 )  bun( 2 )
pschset f1_semolina , nblock(2) tr1( 0.3293000 ) sub1( 0.5817000 ) tr2( 0.91100 ) mxb1( 12 ) bun( 2 )
pschset f1_rice , nblock(2) tr1( 0.5657000 ) sub1( 0.9933000 ) tr2( 1.55900 ) mxb1( 30 ) bun( 2 )
pschset f1_sugar , nblock(2) tr1( 0.5704000 ) sub1( 0.7476000 ) tr2( 1.31800 ) mxb1( 24 ) bun( 2 )
pschset f1_tea , nblock(2) tr1( 2.5791000 ) sub1( 2.5179000 ) tr2( 5.09700 ) mxb1( 2.4 ) bun( 2 )
pschset f1_macaroni, nblock(2) tr1( 0.5582000 ) sub1( 0.8358000 ) tr2( 1.39400 ) mxb1( 18 ) bun( 2 )
pschset f1_oil , nblock(2) tr1( 1.4406000 ) sub1( 1.9614000 ) tr2( 3.40200 ) mxb1( 18 ) bun( 2 )
pschset f1_tomato , nblock(2) tr1( 1.0623000 ) sub1( 1.0787000 ) tr2( 2.14100 ) mxb1( 12 ) bun( 2 )
pschset f1_milk_children , nblock(2) tr1( 8.9250000 ) sub1( 3.3250000 ) tr2( 12.25000 ) mxb1( 38.4 ) bun( 2 )
pschset f1_milk_concentrated , nblock(2) tr1( 1.4691000 ) sub1( 1.1529000 ) tr2( 2.62200 ) mxb1( 14.76 ) bun( 2 )
                   
                
                                                        
/* S2: -100% of sub   */                             
                                
                                                 
pschset f2_flour , nblock(1) tr1( 1.03000 )            
pschset f2_flour_bread , nblock(1) tr1( 0.95900 )            
pschset f2_semolina , nblock(1) tr1( 0.91100 )            
pschset f2_rice , nblock(1) tr1( 1.55900 )            
pschset f2_sugar , nblock(1) tr1( 1.31800 )            
pschset f2_tea , nblock(1) tr1( 5.09700 )            
pschset f2_macaroni, nblock(1) tr1( 1.39400 )            
pschset f2_oil , nblock(1) tr1( 3.40200 )            
pschset f2_tomato , nblock(1) tr1( 2.14100 )            
pschset f2_milk_children , nblock(1) tr1( 12.25000 )            
pschset f2_milk_concentrated , nblock(1) tr1( 2.62200 ) 
  
#delimit ; 
asubsim pc_exp_tot, hsize(hhsize) pline(pline) nitems(11) wappr(2) 
xfil(example3.xml) inisave(example_3) 
aggr(1 2 : SUM_FLOUR | 10 11 : SUM_MILK) 
cname(MyCountry) ysvy(2008) ysim(2013) lcur(Dinar LYD) gvimp(0) 
snames(snames) itnames(itnames) ipsch(ipsch) unit(unit) nscen(2) fpsch1(fpsch1) elas1(elas1) fpsch2(fpsch2) elas2(elas2) 
oinf(2) 
opgr1( min(0.01) max(0.95) )
opgr2( min(0.01) max(0.95) )
opgr9( min(0) max(100) )
opgr10( min(0) max(100) )
;
