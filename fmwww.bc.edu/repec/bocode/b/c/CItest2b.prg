/* CItest2b */

/* This Gauss module implements tests for cointegration with two 
unknown structural breaks as suggested by Hatemi-J (2008, Empirical Economics). The module provides also the cointegration vector with the breaks.
For critical values see the published paper. */


load z[obs,var] =b22.txt;  /* Where obs is the number of your observations, 
				var is the number of your variables, and
 				b22 is your data file saved in text format.*/

/*z=ln(z);*/

y = z[1:obs,1];
x = z[1:obs,2:var];
obs = rows(y);

n = obs;

call main(y,x,4,2,12);
end;

/*************************************************************************
----  PROC MAIN
----FORMAT: call  main(y,x,model,choice,k)
----INPUT:      y - depend variable
        x - data matrix for independent variables (first row is
first observation)
                model - choice for model        =2  C
                        =3  C/T
                        =4  C/S
        choice - only in ADF test,  =1  pre-specified AR lag
                        =2  AIC-chosen AR lag
                        =3  BIC-chosen AR lag
                        =4  downward-t-chosen AR lag
        k - maximum lag for ADF test
----OUTPUT: print automatically Za*, breakpoint for Za*, Zt*, breakpoint for Zt*
, ADF*,                        breakpoint for ADF* and AR lag chosen for ADF*
----GLOBAL VARIABLES: none
----EXTERNAL PROCEDURES: adf,  phillips
----NB: Constant included in regression
************************************************************************/

/*
****************  Main procedure *******************
*/

proc(0)=main(y,x,model,choice,k);
   local t1,t2,n,final1,final2,begin,tstat,x1,lag,j,dummy1,dummy2,temp1,temp2,temp3,temp4;
   local tstatminc,minlag1ind,bpt1,bpt2,breakpta1,breakpta2,zaminc,za,breakptza1,breakptza2,ztminc,zt,breakptzt1,breakptzt2;
   local b, e1,sig2,se;
   n=rows(y);
   begin=round(0.15*n);
   final1=round(0.70*n);
   final2=round(0.85*n);
   temp1=999*ones(final1-begin+1,final2-begin*2+1);
   temp2=temp1;
   temp3=temp1;
   temp4=temp1;
   t1=begin;
   do while t1<=final1;
     t2 = t1 + begin;
     do while t2 <= final2;
	dummy1=zeros(t1,1)|ones(n-t1,1);
        dummy2=zeros(t2,1)|ones(n-t2,1);
        @ adjust regressors for different models @
        if model==3;
           x1=ones(n,1)~dummy1~dummy2~seqa(1,1,n)~x;
        elseif model==4;
           x1=ones(n,1)~dummy1~dummy2~x~(dummy1).*x~(dummy2).*x;
        elseif model==2;
           x1=ones(n,1)~dummy1~dummy2~x;
        endif;

        @ computer ADF for each t  @
       {temp1[t1-begin+1,t2-begin*2+1],temp2[t1-begin+1,t2-begin*2+1]}=adf(y,x1,k,choice);
  
        @ compute Za or Zt for each t  @
        {temp3[t1-begin+1,t2-begin*2+1],temp4[t1-begin+1,t2-begin*2+1]}=phillips(y,x1);
        t2=t2+1;
      endo;
      t1 = t1 +1;
   endo;


   @  ADF test @
   tstatminc=minc(temp1);
   minlag1ind = minindc(temp1);
   tstat = minc(tstatminc);
   bpt2 = minindc(tstatminc);
   bpt1 = minlag1ind[bpt2];
   breakpta1 = (bpt1+begin-1)/n;
   breakpta2 = (bpt2+begin-1)/n;
   lag=temp2[bpt1,bpt2];
   print "******** Modified ADF Test ***********";
   print "t-statistic = " tstat;
   print "AR lag = " lag;
   print "first break point(ADF) = " breakpta1;
   print "second break point(ADF) = " breakpta2;
   print " ";

   @  Phillips test @
format /rd 5,3;
/*"temp3=";;temp3;*/
   zaminc=minc(temp3);
   minlag1ind = minindc(temp3);
   za = minc(zaminc);
   bpt2 = minindc(zaminc);
   bpt1 = minlag1ind[bpt2];
   breakptza1 = (bpt1+begin-1)/n;
   breakptza2 = (bpt2+begin-1)/n;

   ztminc=minc(temp4);
   minlag1ind = minindc(temp4);
   zt = minc(ztminc);
   bpt2 = minindc(ztminc);
   bpt1 = minlag1ind[bpt2];
/*"bpt1=";;bpt1;
"bpt2=";;bpt2;
"begin=";;begin;
"n=";;n;
"rows";;rows(temp3);
"cols";;cols(temp3);
*/
   breakptzt1 = (bpt1+begin-1)/n;
   breakptzt2 = (bpt2+begin-1)/n;
   print "********  Modified Phillips Test ********";
   print "Zt =              " zt;
   print "First breakpoint(Zt) =  " breakptzt1;
   print "Second breakpoint(Zt) =  " breakptzt2;
   print "Za =              " za;
   print "First breakpoint(Za) =  " breakptza1;
   print "Second breakpoint(Za) =  " breakptza2;
   print " ";


        dummy1=zeros(bpt1+begin-1,1)|ones(n-(bpt1+begin-1),1);
        dummy2=zeros(bpt2+begin-1,1)|ones(n-(bpt2+begin-1),1);
        @ adjust regressors for different models @
        if model==3;
           x1=ones(n,1)~dummy1~dummy2~seqa(1,1,n)~x;
        elseif model==4;
           x1=ones(n,1)~dummy1~dummy2~x~(dummy1).*x~(dummy2).*x;
        elseif model==2;
           x1=ones(n,1)~dummy1~dummy2~x;
        endif;
        "if model==3;
           x1=ones(n,1)~dummy1~dummy2~seqa(1,1,n)~x;
        elseif model==4;
           x1=ones(n,1)~dummy1~dummy2~(dummy1).*x~(dummy2).*x;
        elseif model==2;
           x1=ones(n,1)~dummy1~dummy2~x;";
        {b, e1,sig2,se} = estimate(y,x1);
        "b,se,t";;b~se~(b./se); 
/*dummy1~dummy2;*/
retp;
endp;
@ -------------------------------------------------------------- @


/**********************  PROC ADF  *****************************
**   FORMAT
**          { stat,lag } = adf(y,x)
**   INPUT
**        y - dependent variable
**        x - independent variables
**   OUTPUT
**  stata - ADF statistic
**  lag - the lag length
**   GLOBAL VARIABLES: none
**   EXTERNAL PROCEDURES: estimate
**********************************************************************/

/*
*************** Modified ADF for each breakpoint ********************
*/
proc(2) = adf(y,x,kmax,choice);
   local b,m,e,e1,n,n1,sig2,se,xe,yde,j,tstat,de,temp1,temp2;
   local lag,k,ic,aic,bic;
   @ compute ADF  @
   n=rows(y);
   {b,e,sig2,se}=estimate(y,x);
   de=e[2:n]-e[1:n-1]; @ difference of residuals @

   ic=0;
   k=kmax;
   temp1=zeros(kmax+1,1);
   temp2=zeros(kmax+1,1);
   do while k>=0;
      yde=de[1+k:n-1];
      n1=rows(yde);
      @  set up matrix for independent variable(lagged residuals)  @
      xe=e[k+1:n-1];
      j=1;
      do while j <= k;
         xe=xe~de[k+1-j:n-1-j];
         j=j+1;
      endo;
      {b,e1,sig2,se}=estimate(yde,xe);
      if choice==1;  @ K is pre-specified @
          temp1[k+1]=-1000;   @ set an random negative constant @
          temp2[k+1]=b[1]/se[1];
          break;
      elseif choice==2;  @ K is determined by AIC @
         aic=ln(e1'e1/n1)+2*(k+2)/n1;
         ic=aic;
      elseif choice==3;  @ K is determined by BIC @
         bic=ln(e1'e1/n1)+(k+2)*ln(n1)/n1;
         ic=bic;
      elseif choice==4; @K is determined by downward t @
         if abs(b[k+1]/se[k+1]) >= 1.96 or k==0;
        temp1[k+1]=-1000;    @ set an random negative constant @
            temp2[k+1]=b[1]/se[1];
            break;
    endif;
      endif;
      temp1[k+1]=ic;
      temp2[k+1]=b[1]/se[1];
      k=k-1;
   endo;

   lag=minindc(temp1);
   tstat=temp2[lag];
   retp(tstat,lag-1);
endp;
@ ------------------------------------------------------------ @



/**********************  PROC PHILLIPS  *****************************
**   FORMAT
**  { za,zt } = phillips(y,x)
**   INPUT
**  y  - dependent variable
**  x - independent variables
**   OUTPUT
**  za - the Phillips test statistic
**  zt -  the Phillips test statistic
**   GLOBAL VARIABLES: none
**********************************************************************/

/*
*************** Modified Za or Zt for each breakpoint ********************
*/
proc(2)=phillips(y,x);
   local n,b,e,be,ue,nu,bu,uu,su,a2,bandwidth,m,j;
   local c,lemda,gama,w,p,sigma2,s,za,zt;
   n=rows(y);

   @  OLS regression  @
   b=y/x;
   e=y-x*b;

   @  OLS regression on residuals @
   be=e[2:n]/e[1:n-1];
   ue=e[2:n]-e[1:n-1]*be;

   @ calculate bandwidth number @
   nu=rows(ue);
   bu=ue[2:nu]/ue[1:nu-1];
   uu=ue[2:nu]-ue[1:nu-1]*bu;
   su=meanc(uu.^2);
   a2=(4*bu^2*su/(1-bu)^8)/(su/(1-bu)^4);
   bandwidth=1.3221*((a2*nu)^0.2);

   m=bandwidth;
   j=1;
   lemda=0;
   do while j<=m;
      gama=ue[1:nu-j]'ue[j+1:nu]/nu;
      c=j/m;
      w=(75/(6*pi*c)^2)*(sin(1.2*pi*c)/(1.2*pi*c)-cos(1.2*pi*c));
      lemda=lemda+w*gama;
      j=j+1;
   endo;

   @ calculate Za and Zt for each t @
   p=sumc(e[1:n-1].*e[2:n]-lemda)/sumc(e[1:n-1].^2);
   za=n*(p-1);
   sigma2=2*lemda+ue'ue/nu;
   s=sigma2/(e[1:n-1]'e[1:n-1]);
   zt=(p-1)/sqrt(s);
   retp(za,zt);
endp;
@ ------------------------------------------------------------ @


/**********************  PROC ESTIMATE  *****************************
**   FORMAT
**          { b,e,sig2,se } = estimate(y,x)
**   INPUT
**        y  - dependent variable
**        x - independent variables
**   OUTPUT
**  b - OLS estimates
**  e - residuals
**  sig2 - variance
**  se - standard error for coefficients
**   GLOBAL VARIABLES: none
** Procedure written by Bruce Hansen
**********************************************************************/
/* *****  ols regression ****** */
proc(4) = estimate(y,x);
   local m, b, e, sig2, se;
   m=invpd(moment(x,0));
   b=m*(x'y);
   e=y-x*b;
   sig2=(e'e)/(rows(y)-cols(x));
   se=sqrt(diag(m)*sig2);
   retp(b,e,sig2,se);
endp;
@ ---------------------------------------------------------------- @   