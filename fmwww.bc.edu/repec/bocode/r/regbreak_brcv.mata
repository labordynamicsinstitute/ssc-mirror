// regbreak_brcv.mata -- brcvcase() coefficient/variance break labelings
// dumped exactly from Perron-Yamamoto-Zhou brcvcase.m. Author: Dr Merwan Roudane.
version 14.0
mata:
void rb_brcvcase(real scalar m, real scalar n, real scalar idx,
                 real scalar K, real colvector cbrind, real colvector vbrind)
{
    if (m==0) {
        K=n ; cbrind=J(n,1,0) ; vbrind=J(n,1,1) ; return
    }
    if (n==0) {
        K=m ; cbrind=J(m,1,1) ; vbrind=J(m,1,0) ; return
    }
    if (m==1 & n==1 & idx==1) {
        K=1 ; cbrind=(1) ; vbrind=(1) ; return
    }
    if (m==1 & n==1 & idx==2) {
        K=2 ; cbrind=(1\0) ; vbrind=(0\1) ; return
    }
    if (m==1 & n==1 & idx==3) {
        K=2 ; cbrind=(0\1) ; vbrind=(1\0) ; return
    }
    if (m==1 & n==2 & idx==1) {
        K=2 ; cbrind=(1\0) ; vbrind=(1\1) ; return
    }
    if (m==1 & n==2 & idx==2) {
        K=2 ; cbrind=(0\1) ; vbrind=(1\1) ; return
    }
    if (m==1 & n==2 & idx==3) {
        K=3 ; cbrind=(1\0\0) ; vbrind=(0\1\1) ; return
    }
    if (m==1 & n==2 & idx==4) {
        K=3 ; cbrind=(0\1\0) ; vbrind=(1\0\1) ; return
    }
    if (m==1 & n==2 & idx==5) {
        K=3 ; cbrind=(0\0\1) ; vbrind=(1\1\0) ; return
    }
    if (m==1 & n==3 & idx==1) {
        K=3 ; cbrind=(1\0\0) ; vbrind=(1\1\1) ; return
    }
    if (m==1 & n==3 & idx==2) {
        K=3 ; cbrind=(0\1\0) ; vbrind=(1\1\1) ; return
    }
    if (m==1 & n==3 & idx==3) {
        K=3 ; cbrind=(0\0\1) ; vbrind=(1\1\1) ; return
    }
    if (m==1 & n==3 & idx==4) {
        K=4 ; cbrind=(1\0\0\0) ; vbrind=(0\1\1\1) ; return
    }
    if (m==1 & n==3 & idx==5) {
        K=4 ; cbrind=(0\1\0\0) ; vbrind=(1\0\1\1) ; return
    }
    if (m==1 & n==3 & idx==6) {
        K=4 ; cbrind=(0\0\1\0) ; vbrind=(1\1\0\1) ; return
    }
    if (m==1 & n==3 & idx==7) {
        K=4 ; cbrind=(0\0\0\1) ; vbrind=(1\1\1\0) ; return
    }
    if (m==1 & n==4 & idx==1) {
        K=4 ; cbrind=(1\0\0\0) ; vbrind=(1\1\1\1) ; return
    }
    if (m==1 & n==4 & idx==2) {
        K=4 ; cbrind=(0\1\0\0) ; vbrind=(1\1\1\1) ; return
    }
    if (m==1 & n==4 & idx==3) {
        K=4 ; cbrind=(0\0\1\0) ; vbrind=(1\1\1\1) ; return
    }
    if (m==1 & n==4 & idx==4) {
        K=4 ; cbrind=(0\0\0\1) ; vbrind=(1\1\1\1) ; return
    }
    if (m==1 & n==4 & idx==5) {
        K=5 ; cbrind=(1\0\0\0\0) ; vbrind=(0\1\1\1\1) ; return
    }
    if (m==1 & n==4 & idx==6) {
        K=5 ; cbrind=(0\1\0\0\0) ; vbrind=(1\0\1\1\1) ; return
    }
    if (m==1 & n==4 & idx==7) {
        K=5 ; cbrind=(0\0\1\0\0) ; vbrind=(1\1\0\1\1) ; return
    }
    if (m==1 & n==4 & idx==8) {
        K=5 ; cbrind=(0\0\0\1\0) ; vbrind=(1\1\1\0\1) ; return
    }
    if (m==1 & n==4 & idx==9) {
        K=5 ; cbrind=(0\0\0\0\1) ; vbrind=(1\1\1\1\0) ; return
    }
    if (m==2 & n==1 & idx==1) {
        K=2 ; cbrind=(1\1) ; vbrind=(1\0) ; return
    }
    if (m==2 & n==1 & idx==2) {
        K=2 ; cbrind=(1\1) ; vbrind=(0\1) ; return
    }
    if (m==2 & n==1 & idx==3) {
        K=3 ; cbrind=(0\1\1) ; vbrind=(1\0\0) ; return
    }
    if (m==2 & n==1 & idx==4) {
        K=3 ; cbrind=(1\0\1) ; vbrind=(0\1\0) ; return
    }
    if (m==2 & n==1 & idx==5) {
        K=3 ; cbrind=(1\1\0) ; vbrind=(0\0\1) ; return
    }
    if (m==2 & n==2 & idx==1) {
        K=2 ; cbrind=(1\1) ; vbrind=(1\1) ; return
    }
    if (m==2 & n==2 & idx==2) {
        K=3 ; cbrind=(1\1\0) ; vbrind=(1\0\1) ; return
    }
    if (m==2 & n==2 & idx==3) {
        K=3 ; cbrind=(1\1\0) ; vbrind=(0\1\1) ; return
    }
    if (m==2 & n==2 & idx==4) {
        K=3 ; cbrind=(1\0\1) ; vbrind=(1\1\0) ; return
    }
    if (m==2 & n==2 & idx==5) {
        K=3 ; cbrind=(1\0\1) ; vbrind=(0\1\1) ; return
    }
    if (m==2 & n==2 & idx==6) {
        K=3 ; cbrind=(0\1\1) ; vbrind=(1\1\0) ; return
    }
    if (m==2 & n==2 & idx==7) {
        K=3 ; cbrind=(0\1\1) ; vbrind=(1\0\1) ; return
    }
    if (m==2 & n==2 & idx==8) {
        K=4 ; cbrind=(1\1\0\0) ; vbrind=(0\0\1\1) ; return
    }
    if (m==2 & n==2 & idx==9) {
        K=4 ; cbrind=(1\0\1\0) ; vbrind=(0\1\0\1) ; return
    }
    if (m==2 & n==2 & idx==10) {
        K=4 ; cbrind=(1\0\0\1) ; vbrind=(0\1\1\0) ; return
    }
    if (m==2 & n==2 & idx==11) {
        K=4 ; cbrind=(0\1\1\0) ; vbrind=(1\0\0\1) ; return
    }
    if (m==2 & n==2 & idx==12) {
        K=4 ; cbrind=(0\1\0\1) ; vbrind=(1\0\1\0) ; return
    }
    if (m==2 & n==2 & idx==13) {
        K=4 ; cbrind=(0\0\1\1) ; vbrind=(1\1\0\0) ; return
    }
    if (m==2 & n==3 & idx==1) {
        K=3 ; cbrind=(1\1\0) ; vbrind=(1\1\1) ; return
    }
    if (m==2 & n==3 & idx==2) {
        K=3 ; cbrind=(1\0\1) ; vbrind=(1\1\1) ; return
    }
    if (m==2 & n==3 & idx==3) {
        K=3 ; cbrind=(0\1\1) ; vbrind=(1\1\1) ; return
    }
    if (m==2 & n==3 & idx==4) {
        K=4 ; cbrind=(1\1\0\0) ; vbrind=(1\0\1\1) ; return
    }
    if (m==2 & n==3 & idx==5) {
        K=4 ; cbrind=(1\1\0\0) ; vbrind=(0\1\1\1) ; return
    }
    if (m==2 & n==3 & idx==6) {
        K=4 ; cbrind=(1\0\1\0) ; vbrind=(1\1\0\1) ; return
    }
    if (m==2 & n==3 & idx==7) {
        K=4 ; cbrind=(1\0\1\0) ; vbrind=(0\1\1\1) ; return
    }
    if (m==2 & n==3 & idx==8) {
        K=4 ; cbrind=(1\0\0\1) ; vbrind=(1\1\1\0) ; return
    }
    if (m==2 & n==3 & idx==9) {
        K=4 ; cbrind=(1\0\0\1) ; vbrind=(0\1\1\1) ; return
    }
    if (m==2 & n==3 & idx==10) {
        K=4 ; cbrind=(0\1\1\0) ; vbrind=(1\1\0\1) ; return
    }
    if (m==2 & n==3 & idx==11) {
        K=4 ; cbrind=(0\1\1\0) ; vbrind=(1\0\1\1) ; return
    }
    if (m==2 & n==3 & idx==12) {
        K=4 ; cbrind=(0\1\0\1) ; vbrind=(1\1\1\0) ; return
    }
    if (m==2 & n==3 & idx==13) {
        K=4 ; cbrind=(0\1\0\1) ; vbrind=(1\0\1\1) ; return
    }
    if (m==2 & n==3 & idx==14) {
        K=4 ; cbrind=(0\0\1\1) ; vbrind=(1\1\1\0) ; return
    }
    if (m==2 & n==3 & idx==15) {
        K=4 ; cbrind=(0\0\1\1) ; vbrind=(1\1\0\1) ; return
    }
    if (m==2 & n==3 & idx==16) {
        K=5 ; cbrind=(1\1\0\0\0) ; vbrind=(0\0\1\1\1) ; return
    }
    if (m==2 & n==3 & idx==17) {
        K=5 ; cbrind=(1\0\1\0\0) ; vbrind=(0\1\0\1\1) ; return
    }
    if (m==2 & n==3 & idx==18) {
        K=5 ; cbrind=(1\0\0\1\0) ; vbrind=(0\1\1\0\1) ; return
    }
    if (m==2 & n==3 & idx==19) {
        K=5 ; cbrind=(1\0\0\0\1) ; vbrind=(0\1\1\1\0) ; return
    }
    if (m==2 & n==3 & idx==20) {
        K=5 ; cbrind=(0\1\1\0\0) ; vbrind=(1\0\0\1\1) ; return
    }
    if (m==2 & n==3 & idx==21) {
        K=5 ; cbrind=(0\1\0\1\0) ; vbrind=(1\0\1\0\1) ; return
    }
    if (m==2 & n==3 & idx==22) {
        K=5 ; cbrind=(0\1\0\0\1) ; vbrind=(1\0\1\1\0) ; return
    }
    if (m==2 & n==3 & idx==23) {
        K=5 ; cbrind=(0\0\1\1\0) ; vbrind=(1\1\0\0\1) ; return
    }
    if (m==2 & n==3 & idx==24) {
        K=5 ; cbrind=(0\0\1\0\1) ; vbrind=(1\1\0\1\0) ; return
    }
    if (m==2 & n==3 & idx==25) {
        K=5 ; cbrind=(0\0\0\1\1) ; vbrind=(1\1\1\0\0) ; return
    }
    if (m==3 & n==1 & idx==1) {
        K=3 ; cbrind=(1\1\1) ; vbrind=(1\0\0) ; return
    }
    if (m==3 & n==1 & idx==2) {
        K=3 ; cbrind=(1\1\1) ; vbrind=(0\1\0) ; return
    }
    if (m==3 & n==1 & idx==3) {
        K=3 ; cbrind=(1\1\1) ; vbrind=(0\0\1) ; return
    }
    if (m==3 & n==1 & idx==4) {
        K=4 ; cbrind=(0\1\1\1) ; vbrind=(1\0\0\0) ; return
    }
    if (m==3 & n==1 & idx==5) {
        K=4 ; cbrind=(1\0\1\1) ; vbrind=(0\1\0\0) ; return
    }
    if (m==3 & n==1 & idx==6) {
        K=4 ; cbrind=(1\1\0\1) ; vbrind=(0\0\1\0) ; return
    }
    if (m==3 & n==1 & idx==7) {
        K=4 ; cbrind=(1\1\1\0) ; vbrind=(0\0\0\1) ; return
    }
    if (m==3 & n==2 & idx==1) {
        K=3 ; cbrind=(1\1\1) ; vbrind=(1\1\0) ; return
    }
    if (m==3 & n==2 & idx==2) {
        K=3 ; cbrind=(1\1\1) ; vbrind=(1\0\1) ; return
    }
    if (m==3 & n==2 & idx==3) {
        K=3 ; cbrind=(1\1\1) ; vbrind=(0\1\1) ; return
    }
    if (m==3 & n==2 & idx==4) {
        K=4 ; cbrind=(1\0\1\1) ; vbrind=(1\1\0\0) ; return
    }
    if (m==3 & n==2 & idx==5) {
        K=4 ; cbrind=(0\1\1\1) ; vbrind=(1\1\0\0) ; return
    }
    if (m==3 & n==2 & idx==6) {
        K=4 ; cbrind=(1\1\0\1) ; vbrind=(1\0\1\0) ; return
    }
    if (m==3 & n==2 & idx==7) {
        K=4 ; cbrind=(0\1\1\1) ; vbrind=(1\0\1\0) ; return
    }
    if (m==3 & n==2 & idx==8) {
        K=4 ; cbrind=(1\1\1\0) ; vbrind=(1\0\0\1) ; return
    }
    if (m==3 & n==2 & idx==9) {
        K=4 ; cbrind=(0\1\1\1) ; vbrind=(1\0\0\1) ; return
    }
    if (m==3 & n==2 & idx==10) {
        K=4 ; cbrind=(1\1\0\1) ; vbrind=(0\1\1\0) ; return
    }
    if (m==3 & n==2 & idx==11) {
        K=4 ; cbrind=(1\0\1\1) ; vbrind=(0\1\1\0) ; return
    }
    if (m==3 & n==2 & idx==12) {
        K=4 ; cbrind=(1\1\1\0) ; vbrind=(0\1\0\1) ; return
    }
    if (m==3 & n==2 & idx==13) {
        K=4 ; cbrind=(1\0\1\1) ; vbrind=(0\1\0\1) ; return
    }
    if (m==3 & n==2 & idx==14) {
        K=4 ; cbrind=(1\1\1\0) ; vbrind=(0\0\1\1) ; return
    }
    if (m==3 & n==2 & idx==15) {
        K=4 ; cbrind=(1\1\0\1) ; vbrind=(0\0\1\1) ; return
    }
    if (m==3 & n==2 & idx==16) {
        K=5 ; cbrind=(0\0\1\1\1) ; vbrind=(1\1\0\0\0) ; return
    }
    if (m==3 & n==2 & idx==17) {
        K=5 ; cbrind=(0\1\0\1\1) ; vbrind=(1\0\1\0\0) ; return
    }
    if (m==3 & n==2 & idx==18) {
        K=5 ; cbrind=(0\1\1\0\1) ; vbrind=(1\0\0\1\0) ; return
    }
    if (m==3 & n==2 & idx==19) {
        K=5 ; cbrind=(0\1\1\1\0) ; vbrind=(1\0\0\0\1) ; return
    }
    if (m==3 & n==2 & idx==20) {
        K=5 ; cbrind=(1\0\0\1\1) ; vbrind=(0\1\1\0\0) ; return
    }
    if (m==3 & n==2 & idx==21) {
        K=5 ; cbrind=(1\0\1\0\1) ; vbrind=(0\1\0\1\0) ; return
    }
    if (m==3 & n==2 & idx==22) {
        K=5 ; cbrind=(1\0\1\1\0) ; vbrind=(0\1\0\0\1) ; return
    }
    if (m==3 & n==2 & idx==23) {
        K=5 ; cbrind=(1\1\0\0\1) ; vbrind=(0\0\1\1\0) ; return
    }
    if (m==3 & n==2 & idx==24) {
        K=5 ; cbrind=(1\1\0\1\0) ; vbrind=(0\0\1\0\1) ; return
    }
    if (m==3 & n==2 & idx==25) {
        K=5 ; cbrind=(1\1\1\0\0) ; vbrind=(0\0\0\1\1) ; return
    }
    if (m==3 & n==3 & idx==1) {
        K=3 ; cbrind=(1\1\1) ; vbrind=(1\1\1) ; return
    }
    if (m==3 & n==3 & idx==2) {
        K=4 ; cbrind=(0\1\1\1) ; vbrind=(1\1\1\0) ; return
    }
    if (m==3 & n==3 & idx==3) {
        K=4 ; cbrind=(1\0\1\1) ; vbrind=(1\1\1\0) ; return
    }
    if (m==3 & n==3 & idx==4) {
        K=4 ; cbrind=(1\1\0\1) ; vbrind=(1\1\1\0) ; return
    }
    if (m==3 & n==3 & idx==5) {
        K=4 ; cbrind=(0\1\1\1) ; vbrind=(1\1\0\1) ; return
    }
    if (m==3 & n==3 & idx==6) {
        K=4 ; cbrind=(1\0\1\1) ; vbrind=(1\1\0\1) ; return
    }
    if (m==3 & n==3 & idx==7) {
        K=4 ; cbrind=(1\1\1\0) ; vbrind=(1\1\0\1) ; return
    }
    if (m==3 & n==3 & idx==8) {
        K=4 ; cbrind=(0\1\1\1) ; vbrind=(1\0\1\1) ; return
    }
    if (m==3 & n==3 & idx==9) {
        K=4 ; cbrind=(1\1\0\1) ; vbrind=(1\0\1\1) ; return
    }
    if (m==3 & n==3 & idx==10) {
        K=4 ; cbrind=(1\1\1\0) ; vbrind=(1\0\1\1) ; return
    }
    if (m==3 & n==3 & idx==11) {
        K=4 ; cbrind=(1\0\1\1) ; vbrind=(0\1\1\1) ; return
    }
    if (m==3 & n==3 & idx==12) {
        K=4 ; cbrind=(1\1\0\1) ; vbrind=(0\1\1\1) ; return
    }
    if (m==3 & n==3 & idx==13) {
        K=4 ; cbrind=(1\1\1\0) ; vbrind=(0\1\1\1) ; return
    }
    if (m==3 & n==3 & idx==14) {
        K=5 ; cbrind=(0\0\1\1\1) ; vbrind=(1\1\1\0\0) ; return
    }
    if (m==3 & n==3 & idx==15) {
        K=5 ; cbrind=(0\1\0\1\1) ; vbrind=(1\1\1\0\0) ; return
    }
    if (m==3 & n==3 & idx==16) {
        K=5 ; cbrind=(1\0\0\1\1) ; vbrind=(1\1\1\0\0) ; return
    }
    if (m==3 & n==3 & idx==17) {
        K=5 ; cbrind=(1\0\1\0\1) ; vbrind=(1\1\0\1\0) ; return
    }
    if (m==3 & n==3 & idx==18) {
        K=5 ; cbrind=(0\1\1\0\1) ; vbrind=(1\1\0\1\0) ; return
    }
    if (m==3 & n==3 & idx==19) {
        K=5 ; cbrind=(0\0\1\1\1) ; vbrind=(1\1\0\1\0) ; return
    }
    if (m==3 & n==3 & idx==20) {
        K=5 ; cbrind=(0\1\0\1\1) ; vbrind=(1\0\1\1\0) ; return
    }
    if (m==3 & n==3 & idx==21) {
        K=5 ; cbrind=(0\1\1\0\1) ; vbrind=(1\0\1\1\0) ; return
    }
    if (m==3 & n==3 & idx==22) {
        K=5 ; cbrind=(1\1\0\0\1) ; vbrind=(1\0\1\1\0) ; return
    }
    if (m==3 & n==3 & idx==23) {
        K=5 ; cbrind=(1\0\0\1\1) ; vbrind=(0\1\1\1\0) ; return
    }
    if (m==3 & n==3 & idx==24) {
        K=5 ; cbrind=(1\0\1\0\1) ; vbrind=(0\1\1\1\0) ; return
    }
    if (m==3 & n==3 & idx==25) {
        K=5 ; cbrind=(1\1\0\0\1) ; vbrind=(0\1\1\1\0) ; return
    }
    if (m==3 & n==3 & idx==26) {
        K=5 ; cbrind=(0\0\1\1\1) ; vbrind=(1\1\0\0\1) ; return
    }
    if (m==3 & n==3 & idx==27) {
        K=5 ; cbrind=(0\1\1\1\0) ; vbrind=(1\1\0\0\1) ; return
    }
    if (m==3 & n==3 & idx==28) {
        K=5 ; cbrind=(1\0\1\1\0) ; vbrind=(1\1\0\0\1) ; return
    }
    if (m==3 & n==3 & idx==29) {
        K=5 ; cbrind=(1\1\0\1\0) ; vbrind=(1\0\1\0\1) ; return
    }
    if (m==3 & n==3 & idx==30) {
        K=5 ; cbrind=(0\1\1\1\0) ; vbrind=(1\0\1\0\1) ; return
    }
    if (m==3 & n==3 & idx==31) {
        K=5 ; cbrind=(0\1\0\1\1) ; vbrind=(1\0\1\0\1) ; return
    }
    if (m==3 & n==3 & idx==32) {
        K=5 ; cbrind=(1\0\0\1\1) ; vbrind=(0\1\1\0\1) ; return
    }
    if (m==3 & n==3 & idx==33) {
        K=5 ; cbrind=(1\0\1\1\0) ; vbrind=(0\1\1\0\1) ; return
    }
    if (m==3 & n==3 & idx==34) {
        K=5 ; cbrind=(1\1\0\1\0) ; vbrind=(0\1\1\0\1) ; return
    }
    if (m==3 & n==3 & idx==35) {
        K=5 ; cbrind=(0\1\1\0\1) ; vbrind=(1\0\0\1\1) ; return
    }
    if (m==3 & n==3 & idx==36) {
        K=5 ; cbrind=(0\1\1\1\0) ; vbrind=(1\0\0\1\1) ; return
    }
    if (m==3 & n==3 & idx==37) {
        K=5 ; cbrind=(1\1\1\0\0) ; vbrind=(1\0\0\1\1) ; return
    }
    if (m==3 & n==3 & idx==38) {
        K=5 ; cbrind=(1\0\1\0\1) ; vbrind=(0\1\0\1\1) ; return
    }
    if (m==3 & n==3 & idx==39) {
        K=5 ; cbrind=(1\0\1\1\0) ; vbrind=(0\1\0\1\1) ; return
    }
    if (m==3 & n==3 & idx==40) {
        K=5 ; cbrind=(1\1\1\0\0) ; vbrind=(0\1\0\1\1) ; return
    }
    if (m==3 & n==3 & idx==41) {
        K=5 ; cbrind=(1\1\0\0\1) ; vbrind=(0\0\1\1\1) ; return
    }
    if (m==3 & n==3 & idx==42) {
        K=5 ; cbrind=(1\1\0\1\0) ; vbrind=(0\0\1\1\1) ; return
    }
    if (m==3 & n==3 & idx==43) {
        K=5 ; cbrind=(1\1\1\0\0) ; vbrind=(0\0\1\1\1) ; return
    }
    if (m==3 & n==3 & idx==44) {
        K=6 ; cbrind=(0\0\0\1\1\1) ; vbrind=(1\1\1\0\0\0) ; return
    }
    if (m==3 & n==3 & idx==45) {
        K=6 ; cbrind=(0\0\1\0\1\1) ; vbrind=(1\1\0\1\0\0) ; return
    }
    if (m==3 & n==3 & idx==46) {
        K=6 ; cbrind=(0\1\0\0\1\1) ; vbrind=(1\0\1\1\0\0) ; return
    }
    if (m==3 & n==3 & idx==47) {
        K=6 ; cbrind=(1\0\0\0\1\1) ; vbrind=(0\1\1\1\0\0) ; return
    }
    if (m==3 & n==3 & idx==48) {
        K=6 ; cbrind=(0\0\1\1\0\1) ; vbrind=(1\1\0\0\1\0) ; return
    }
    if (m==3 & n==3 & idx==49) {
        K=6 ; cbrind=(0\1\0\1\0\1) ; vbrind=(1\0\1\0\1\0) ; return
    }
    if (m==3 & n==3 & idx==50) {
        K=6 ; cbrind=(1\0\0\1\0\1) ; vbrind=(0\1\1\0\1\0) ; return
    }
    if (m==3 & n==3 & idx==51) {
        K=6 ; cbrind=(0\0\1\1\1\0) ; vbrind=(1\1\0\0\0\1) ; return
    }
    if (m==3 & n==3 & idx==52) {
        K=6 ; cbrind=(0\1\0\1\1\0) ; vbrind=(1\0\1\0\0\1) ; return
    }
    if (m==3 & n==3 & idx==53) {
        K=6 ; cbrind=(1\0\0\1\1\0) ; vbrind=(0\1\1\0\0\1) ; return
    }
    if (m==3 & n==3 & idx==54) {
        K=6 ; cbrind=(0\1\1\0\0\1) ; vbrind=(1\0\0\1\1\0) ; return
    }
    if (m==3 & n==3 & idx==55) {
        K=6 ; cbrind=(1\0\1\0\0\1) ; vbrind=(0\1\0\1\1\0) ; return
    }
    if (m==3 & n==3 & idx==56) {
        K=6 ; cbrind=(1\1\0\0\0\1) ; vbrind=(0\0\1\1\1\0) ; return
    }
    if (m==3 & n==3 & idx==57) {
        K=6 ; cbrind=(0\1\1\0\1\0) ; vbrind=(1\0\0\1\0\1) ; return
    }
    if (m==3 & n==3 & idx==58) {
        K=6 ; cbrind=(1\0\1\0\1\0) ; vbrind=(0\1\0\1\0\1) ; return
    }
    if (m==3 & n==3 & idx==59) {
        K=6 ; cbrind=(1\1\0\0\1\0) ; vbrind=(0\0\1\1\0\1) ; return
    }
    if (m==3 & n==3 & idx==60) {
        K=6 ; cbrind=(0\1\1\1\0\0) ; vbrind=(1\0\0\0\1\1) ; return
    }
    if (m==3 & n==3 & idx==61) {
        K=6 ; cbrind=(1\0\1\1\0\0) ; vbrind=(0\1\0\0\1\1) ; return
    }
    if (m==3 & n==3 & idx==62) {
        K=6 ; cbrind=(1\1\0\1\0\0) ; vbrind=(0\0\1\0\1\1) ; return
    }
    if (m==4 & n==1 & idx==1) {
        K=4 ; cbrind=(1\1\1\1) ; vbrind=(1\0\0\0) ; return
    }
    if (m==4 & n==1 & idx==2) {
        K=4 ; cbrind=(1\1\1\1) ; vbrind=(0\1\0\0) ; return
    }
    if (m==4 & n==1 & idx==3) {
        K=4 ; cbrind=(1\1\1\1) ; vbrind=(0\0\1\0) ; return
    }
    if (m==4 & n==1 & idx==4) {
        K=4 ; cbrind=(1\1\1\1) ; vbrind=(0\0\0\1) ; return
    }
    if (m==4 & n==1 & idx==5) {
        K=5 ; cbrind=(0\1\1\1\1) ; vbrind=(1\0\0\0\0) ; return
    }
    if (m==4 & n==1 & idx==6) {
        K=5 ; cbrind=(1\0\1\1\1) ; vbrind=(0\1\0\0\0) ; return
    }
    if (m==4 & n==1 & idx==7) {
        K=5 ; cbrind=(1\1\0\1\1) ; vbrind=(0\0\1\0\0) ; return
    }
    if (m==4 & n==1 & idx==8) {
        K=5 ; cbrind=(1\1\1\0\1) ; vbrind=(0\0\0\1\0) ; return
    }
    if (m==4 & n==1 & idx==9) {
        K=5 ; cbrind=(1\1\1\1\0) ; vbrind=(0\0\0\0\1) ; return
    }
    K=. ; cbrind=J(0,1,.) ; vbrind=J(0,1,.)
}
end
