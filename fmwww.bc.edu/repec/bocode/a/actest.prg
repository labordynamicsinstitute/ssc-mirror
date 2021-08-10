/*ACtest.prg*/ 	@Author: Abdulnasser Hatemi-J @
Print " This program performs an asymmetric causality test developed by Hatemi-J (2012). 
Reference: Hatemi-J (2012) Asymmetric Causality Tests with an Application, Empirical Economics, forthcoming";
Print " ";
Print " This program code is the copyright of the authors. Applications are allowed only if proper reference and acknowledgments are provided. For non-Commercial applications only.";
Print "No performance guarantee is made. Bug reports are welcome. ";
Print " ";

/*You need to input information where you see the ? sign.*/  
/*The program tests the hypothesis that the second variable in your data file do not cause the first one. Change the order of the variables in the data file in oder to test other hypotheses of interest.*/

outwidth 200;
/*output file = mdlslOUTregret.asc reset; 
screen off; */  screen on; 

load YZlevel[]  = ?.txt; 					/* The data file. */

Numvars = ?;							/* The number of variables in the VAR model. */

Levnumobs = (rows(YZlevel)/Numvars);
YZlevel = Reshape(YZlevel, Levnumobs, Numvars);

/*  YZlevel=ln(YZlevel); 	*/					/*This line, if activated, will use the origional data in log form. */

dYZ = YZlevel[2:Levnumobs,.] -  YZlevel[1:(Levnumobs-1),.];
numobs = Levnumobs - 1;
notpositive = DYZ .le 0;
notnegative= DYZ .ge 0;

DYZpc = zeros(numobs,Numvars);
DYZnc = zeros(numobs,Numvars);

colnum = 1;
do until colnum > Numvars;
    DYZpc[.,colnum] = recode(DYZ[.,colnum],notpositive[.,colnum],0);
    DYZnc[.,colnum] = recode(DYZ[.,colnum],notnegative[.,colnum],0);
    colnum = colnum + 1;
endo;
    CumDYZpc = cumsumc(DYZpc);
    CumDYZnc = cumsumc(DYZnc);

/*"positives"; */
z=CUMDYZpc; 				/* This line, if activated, will allow for causality test between positive components. */

/*"negatives";			
z=CUMDYZnc;	*/	/* This line , if activated, will allow for causality test between negative components. Disactivate z=CUMDYZpc also*/

rndseed 30540; 
                                        
bootsimmax = 1000;    @the maximum # of simulations for computing bootstrapped critical values. It should be a multiple of 20 @
infocrit = 5; 	  @ Information criterion used: 1=AIC, 2=AICC, 3=SBC, 4=HQC, 5=HJC, 6=use maxlags @

maxlags = 4;	@Maximum lag order in the VAR model (without additional lags for unit roots). The value can be changed.@
intorder =1;	@ This value allows for one addition unrestricted lag in the VAR model in order to account for the unit root.@


addlags = intorder;
 numvars = cols(z);

                                        {aiclag, aicclag, sbclag, hqclag, hjiclag, aicA, aiccA, sbcA, hqcA, hjicA, onelA, nocando} = lag_length2(z,1,maxlags);

		                        If infocrit == 1;
 			 		    ICOrder = aiclag;
		                       elseif infocrit == 2;
 			 		    ICOrder = aicclag;
                                       elseif infocrit == 3;
					    ICOrder = sbclag;
 				       elseif infocrit == 4; 
				            ICOrder = hqclag;
 				       elseif infocrit == 5; 
				            ICOrder = hjiclag;
 				       elseif infocrit == 6; 
				            ICOrder = maxlags;
				        endif;	

                                        {yT, ylags} = varlags(z, (ICorder + addlags));
                                         numobs = rows(yT);
                                         xT = ones(numobs,1)~ylags;

                                        {yS, ylags} = varlags(z, ICorder);
                                         numobs = rows(yS);
                                         xS = ones(numobs,1)~ylags;                     

					{Rvector1, Rmatrix1} = rstrctvm(numvars, ICorder, addlags);

 				       {AhatTU,leverageTU} = estvar_params(yT, XT,0,0,ICorder,addlags);
                                       {AhatTR,leverageTR} = estvar_params(yT, XT,1,Rvector1,ICorder,addlags);
                                       {AhatSR,leverageSR} = estvar_params(yS, XS,1,Rvector1[.,1:(1+numvars*ICorder)],ICorder,0);
                                        If addlags > 0;
                                            AhatSR  = AhatSR~zeros(numvars,numvars*addlags);
                                       endif;
"AhatTU=";;AhatTU;
"AhatTR=";;AhatTR;


                                       {Wstat} = W_Test(yT, XT, AhatTU, Rmatrix1);
                                       {WcriticalvalsS} = Bootstrap_Toda(yT, XT, z[1:(ICorder + addlags),.], AhatSR,leverageSR,ICorder,addlags,bootsimmax,Rmatrix1);
                                       rejectnullchi= (cdfchic(Wstat,ICorder).<0.01) | (cdfchic(Wstat,ICorder).<0.05) | (cdfchic(Wstat,ICorder).<0.10);
                                       rejectnullbootS=(Wstat.>WcriticalvalsS[1,.]) | (Wstat.>WcriticalvalsS[2,.]) | (Wstat.>WcriticalvalsS[3,.]); 
                      
   "-----------------------------------------";
{Azdsys} = Azd(ICorder);
format /rd 5,3;
"Information criterion used; lags based on that =";;
If infocrit == 1;
   "AIC ";;aiclag;
elseif infocrit == 2; 
   "AICC ";;aicclag;
elseif infocrit ==3;
   "SBC ";;sbclag;
elseif infocrit ==4;
   "HQC ";;hqclag;
elseif infocrit ==5;
   "Hatemi-J Criterion (HJC) ";;hjiclag;
elseif infocrit ==6;
   "user given:";;maxlags;
endif;
"Varorder chosen by information criterion (excluding augmentation lag(s)) is ";;ICorder;
"additional lags=";;addlags;
"Wstat = ";; Wstat;
"Wcriticalvals=";;WcriticalvalsS;
/*"rejectnullchi=";;rejectnullchi;
"rejectnullbootS=";;rejectnullbootS; */


/**********************  PROC RSTRCTVM *****************************
----PROC rstrctvm
----AUTHOR: Scott Hacker (in cooperation with A. Hatemi-J)
----INPUT:     
      numvars: number of variables in VAR sytem
      varorder: order of the VAR system
      addlags: number of additional lags 
----OUTPUT: 
     Rvector1: a row vector corresponding to the coefficients in the the first row of a VAR system,
                      with 1 indicating where a 0 restriction is placed and 0 indicating not.
     Rmatrix1: a matrix with each row indicating where one constraint is placed on
                      a vectorization of the coefficients in a VAR system. A 1 indicates which coefficient is
                      restricted to zero; 0 is given otherwise.
----GLOBAL VARIABLES: none
----EXTERNAL PROCEDURES: none
----NB: none.
**********************************************************************/
proc(2)=rstrctvm(numvars, varorder, addlags);
    local rvector1, rmatrix1, restnum, ordrcntr, varcntr;

    rvector1 = zeros(1,1+numvars*(varorder + addlags));
    rmatrix1 = zeros(varorder,(1+numvars*(varorder+addlags))*numvars);

    ordrcntr = 1;
    do until ordrcntr > varorder;
        rvector1[1,1+(ordrcntr-1)*numvars+2] = 1;
        rmatrix1[ordrcntr,1+((ordrcntr-1)*numvars+2)*numvars]=1;
        ordrcntr = ordrcntr +1;
    endo;

    retp(rvector1,rmatrix1);
endp;


/**********************  PROC Azd *****************************
----PROC azd
----AUTHOR: Scott Hacker
----INPUT:     
       Addlags
----NB: none.
**********************************************************************/
proc(1)=azd(addlags);
    local indx;
    indx= 1;
    do until indx > 2;
         indx = indx+1;
    endo; 
  retp(indx);
endp;

/**********************  PROC VARLAGS  *****************************
**   Author: Alan G. Isaac
**   last update: 5 Dec 95      previous: 15 June 94
**   FORMAT
**          { x,xlags } = varlags(var,lags)
**   INPUT
**        var  - T x K matrix
**        lags - scalar, number of lags of var (a positive integer)
**   OUTPUT
**          x -     (T - lags) x K matrix, the last T-lags rows of var
**          xlags - (T - lags) x lags*cols(var) matrix,
**                  being the 1st through lags-th
**                  values of var corresponding to the values in x
**                  i.e, the appropriate rows of x(-1)~x(-2)~etc.
**   GLOBAL VARIABLES: none
**********************************************************************/
proc(2)=varlags(var,lags);
    local xlags;
    xlags = shiftr((ones(1,lags) .*. var)',seqa(1-lags,1,lags)
                                            .*. ones(cols(var),1),miss(0,0))';
    retp(trimr(var,lags,0),trimr(xlags,0,lags));
endp;


/*************************************************************************
----PROC EstVar_Params
----AUTHOR: Scott Hacker
----INPUT:      
      y  - data matrix adjusted for lags. Each column is a vector of observations on one
             endogenous variable. Currently only works for 2 endog. variables.
      X - a column of ones appended to a matrix of lagged values for y.
      restrict - 1 means restrict the coefficient estimates so there is no Granger causality
                    0 means don't do that restriction
      rvector1 - row vector noting which variable coefficients are restricted to zero (1 indicates
                       where the restriction is);
      order  - order of var system. This should be = 1 or 2.
      addlags - additional lags (should be equal to maximum integration order);
----OUTPUT: 
     Ahat - estimated matrix of coefficient parameters
      leverage - this is calculated appropriately only for restricted cases (for bootstraps)
----GLOBAL VARIABLES: none
----EXTERNAL PROCEDURES: Insrtzero
----NB: none.
************************************************************************/

proc (2) = estvar_params (y, X, restrict, rvector1, order, addlags);
   local numvars, maxlag, T, Xrestr1, Ahatrestr1, INVXTXXT2, H2, leverage2, INVXTXXTrest1,  Hrestr1, leverage, Ahat, Ahat2,i;
    numvars = cols(y);                 		@ # endog vars- currently this program only works for 2 @
     maxlag = order + addlags;
       T=rows(y);
     If restrict == 1;
        INVXTXXT2 = Inv(X'*X)*X';
        Ahat2 = (INVXTXXT2*Y[.,2:numvars])';
     /*   H2 = X*INVXTXXT2;
        leverage2 = diag(H2); */
        leverage2= zeros(rows(X),1);
        i = 1;
        do until i > rows(X);
            leverage2[i,1] = X[i,.]*INVXTXXT2[.,i];
            i = i+1;
        endo;
        Xrestr1 = (delif(X',rvector1'))';
        INVXTXXTrest1 =  Inv(Xrestr1'*Xrestr1)*Xrestr1';
        Ahatrestr1 =  (INVXTXXTrest1*Y[.,1])';
/*        Hrestr1 = Xrestr1*INVXTXXTrest1;
         leverage = diag(Hrestr1)~leverage2;*/
  
        leverage= zeros(rows(Xrestr1),1);
        i = 1;
        do until i > rows(Xrestr1);
            leverage[i,1] = Xrestr1[i,.]*INVXTXXTrest1[.,i];
            i = i+1;
        endo;
        leverage = leverage~leverage2;
        
        Ahat = (Insrtzero(Ahatrestr1',rvector1'))'|Ahat2;
       
   else;
       Ahat = (Inv(X'*X)*(X'*Y))';
       leverage = ones(1,2);  /* this statement just provides some arbitrary (meaningless) values for the leverage;
                                               leverage is not expected to be used under these circumstances (the unrestricted case). */
   endif;
   retp(Ahat, leverage);
endp;        

/**********************  PROC INSRTZERO *****************************
----PROC insrtzero
----AUTHOR: Scott Hacker
----INPUT:     
      orig: the original vector in which zeros will be placed.
      pattern: a vector denoting which elements in the new vector will have the inserted zeros
----OUTPUT: 
      new: the new vector with zeros inserted according the pattern vector
----GLOBAL VARIABLES: none
----EXTERNAL PROCEDURES: none
----NB: none.
**********************************************************************/
proc(1)=insrtzero(orig, pattern);
    local indx, newv, insrtpts;
    insrtpts = indexcat(pattern,1);
    newv = orig;
    indx= 1;
    do until indx > rows(insrtpts);
         if insrtpts[indx] == 1;
             newv = 0;
             else;
             if insrtpts[indx] > rows(newv);
                 newv = newv|0;
                 else;
                     newv = newv[1:(insrtpts[indx]-1),.]|0|newv[insrtpts[indx]:rows(newv),.];
             endif;
         endif;
         indx = indx+1;
    endo; 
    retp(newv);
endp;


/*************************************************************************
----PROC W_test
----AUTHOR: Scott Hacker
----INPUT:      
      Y  - data matrix adjusted for lags. Each column is a vector of observations on one
             endogenous variable. 
      X - a column of ones appended to a matrix of lagged values for y.
      Ahat - matrix of unrestricted coefficient estimates
      Rmatrix1 - matrix of restrictions
----OUTPUT: 
     Wstat - vector of Wald statistics
----GLOBAL VARIABLES: none
----EXTERNAL PROCEDURES: none
----NB: none.
************************************************************************/
proc (1) = W_test(Y, X, Ahat, Rmatrix1);
   local RESunrestr, Estvarcov, zerosvector, vecAhat, f1, f2, InvXprX, Wstat;


     RESunrestr = Y - X*Ahat';
     Estvarcov = (RESunrestr'RESunrestr)/(rows(Y)-cols(Ahat));
     vecAhat = (vecr(Ahat'));
     InvXprX = Inv(X'X);
     f1 = (Rmatrix1*vecAhat);

     Wstat = f1'(inv(Rmatrix1*(InvXprX.*.Estvarcov)*Rmatrix1'))*f1;

   retp(Wstat);
endp;        

/*************************************************************************
----PROC Bootstrap_Toda
----AUTHOR: Scott Hacker
----INPUT:      
      y  - data matrix adjusted for lags. Each column is a vector of observations on one
             endogenous variable. 
      X - ones column vector appended to a matrix of lagged values for y.
      zlags - first elements of original data matrix up to the number of lags.
      order  - order of var system. 
      Ahat - estimated coefficient matrix for the VAR system
      leverage
      addlags - additional lags (should be equal to maximum integration order);
      order  - order of var system. This should be = 1 or 2.
      addlags - additional lags (should be equal to maximum integration order);
      bootsimmax - number of simulations for bootstrapping critical values
      Rmatrix1, Rmatrix2 - matrices of restrictions, tested separately
----OUTPUT: 
     Wcriticalvals - matrix of critical values for Wald statistics
----GLOBAL VARIABLES: none
----EXTERNAL PROCEDURES: estvar_params, W_test;
----NB: none.
************************************************************************/
 proc(1) = Bootstrap_Toda(y, X, zlags, Ahat, leverage, order, addlags,bootsimmax, Rmatrix1);
 local RES, adjRES, bootsim, numobs, maxlag, Wstatv, yhatrow, Xhat, obspull, index, 
          simerr, zhat, yhat, AhatTU, Wstat, randomnumbers,
          onepct_index, fivepct_index, tenpct_index, critical_W, critical_Wpl1,
          Wcriticalvals, unneededleverage,numvars,varindx,adjuster;
 numobs = rows(y);
 numvars = cols(y);
 maxlag = order + addlags;
 RES = Y - X*Ahat';

/*ones(numobs,2);
leverage[1,2];
sqrt(ones(numobs,1) - leverage[1,1])~sqrt(ones(numobs,1) - leverage[1,2]);
RES;
*/
 adjuster =  sqrt(ones(numobs,1) - leverage[1,1]);
 varindx = 2;
 do until varindx > numvars; 
      adjuster = adjuster~sqrt(ones(numobs,1) - leverage[1,2]);  /*leverage the same (leverage[1,2]) for all variables except first */
      varindx = varindx + 1;
 endo;
 adjRES = RES ./adjuster;
 Wstatv = zeros(bootsimmax,1);
 bootsim = 1;  
 simerr=zeros(numobs,numvars);

 do until bootsim > bootsimmax;
       
       obspull = 1;
       do until obspull > numobs;
          randomnumbers = rndu(1,numvars);
          index = 1+ trunc(numobs*randomnumbers);
          simerr[obspull,1] = adjRES[index[1,1],1];
          varindx = 2;
          do until varindx > numvars;
                simerr[obspull,varindx] = adjRES[index[1,varindx],varindx];
                 varindx = varindx +1;
          endo;
          obspull = obspull +1;
       endo;
       varindx = 1;
       do until varindx > numvars;
             simerr[.,varindx] = simerr[.,varindx] - (meanc(simerr[.,varindx])) ;
             varindx = varindx + 1;
       endo;
 
       /* Method 1 for creating Wstat and Yhat: Xhat derived*/
      Xhat = X[1,.];
      obspull = 1;
      do until obspull > numobs;
          yhatrow = Xhat[obspull,.]*Ahat' + simerr[obspull,.];
          If maxlag > 1;
             Xhat= Xhat|(1~yhatrow~Xhat[obspull,2:1+numvars*(maxlag-1)]);
          else;
             Xhat= Xhat|(1~yhatrow);
          endif;
          obspull = obspull + 1;
      endo;     
      yhat = Xhat[2:rows(Xhat), 2:(numvars + 1)];
      Xhat = Xhat[1:rows(Xhat)-1,.];


      {AhatTU,unneededleverage} = estvar_params(yhat, Xhat,0, 0, order,addlags);
      {Wstat} = W_Test(yhat, Xhat, AhatTU, Rmatrix1); 

      Wstatv[bootsim, 1] = Wstat;
      bootsim = bootsim + 1;
 endo;

 Wstatv=SORTMC(Wstatv[.,1],1);
 onepct_index = bootsimmax - trunc(bootsimmax/100);
 fivepct_index = bootsimmax - trunc(bootsimmax/20);
 tenpct_index = bootsimmax - trunc(bootsimmax/10);




 critical_W = Wstatv[onepct_index,.]|Wstatv[fivepct_index,.]|Wstatv[tenpct_index,.];
 critical_Wpl1 = Wstatv[onepct_index+minc(1|trunc(bootsimmax/100)),.]|
                          Wstatv[fivepct_index+minc(1|trunc(bootsimmax/20)),.]|
                          Wstatv[tenpct_index+minc(1|trunc(bootsimmax/10)),.];

 Wcriticalvals = (critical_W + critical_Wpl1)/2; 

    
 retp(Wcriticalvals);
endp;

/*************************************************************************
----PROC lag_length2 
----AUTHOR: Scott Hacker
----ATTRIBUTION: Parts of this code are taken from proc LR_LAG
    written by David Rapach (may 27 1996 version).
----INPUT:      
      Z  - data matrix. Each column is a vector of observations on one
             endogenous variable
      minlag - minimum lag length
      p  - maximum lag length. This should be >= 2

----OUTPUT: aiclag  - Lag length suggested by Akaike info criterion.
                    aicclag - Lag length suggessted by corrected Akaike infoc criterion
                    sbclag -  Lag length suggested by Schwarz-Bayesian criterion.
                    hqclag - Lag length suggested by Hannon-Quinn criterion.
                    hjclag - Lag length suggested by Hatermi-J criterion.
                    aicA - Matrix of coefficient estimates based on aiclag.
                    aiccA - Matrix of coefficient estimates based on aicclag.
                    scbA - Matrix of coefficient estimates based on sblag.
                    hqcA - Matrix of coefficient estimates based on hqlag.
		    hjcA - Matrix of coefficient estimates based on hjlag.
                    actlA - Matrix of coefficient estimates based on actual lag.
                    onelA -Matrix of coefficient estimates based on one lag.
      nocando - 1 if not possible to find suggested lag lengths for the given Z,
                       0 otherwise. 
----GLOBAL VARIABLES: none
----EXTERNAL PROCEDURES: VARLAGS, by Alan G. Isaac
----NB: none.
************************************************************************/

proc (12) = lag_length2(z, minlag, p);
   local M, Y, ylags, T,i, j, lag_guess,X, Ahat, RES, VARCOV,
            aic, aicc, sbc, hqc, hjc, aicmin, aiclag, aiccmin, aicclag, sbcmin, sbclag, hqcmin, hqclag, hjcmin, hjclag, HJCA,
            aicfnd;
    M = cols(z);                 		@ # endog vars @
      {Y, ylags} = varlags(z,p);
       T=rows(y);
    lag_guess = p;				@ initialization  of lag_guess @
    j = 0;
    aicfnd = 0;
    do until (lag_guess < minlag);
       if (lag_guess > 0);
          X = ones (T,1) ~ylags[ . , 1:lag_guess*M];
       else;
          X = ones (T,1);
       endif;
/*If abs(Z[T,1]) > 100000000000000000 or abs(Z[T,2]) > 100000000000000000; 
     print "Z(T,.)=";Z[T,1]; Z[T,2];
     print "det(X'X)";;det(X'X);
endif; */
 /*    If ((det(X'X)) > 100000000000000000 or (det(X'X)) < -100000000000000000); */
  /*  If ((det(X'X)/10000) >  99999999999999999 or (det(X'X)/10000) <   -99999999999999999); */
/*   print "Z(T,.)=";Z[T,1]; Z[T,2]; 
   print "det(X'X)";;det(X'X); */
    If 2 < 1;                    /*    never true of course--I'm just commenting out the above if statements */
         nocando = 1;
         aiclag = -1;
         aicclag = -1;
         sbclag = -1;
         hqclag = -1;
         hjclag = -1;
         lag_guess = -1;
    else;
         nocando = 0;
          Ahat = (Y/X)';
          RES = Y - X*Ahat';
          VARCOV = RES'RES/T;
          aic =   ln(det(VARCOV)) + (2/T)*(M*M*lag_guess +M)+ M*(1+ln(2*pi));  /* Original AIC definition used */
          aicc =   ln(det(VARCOV)) + ((T + (1+lag_guess*M))*M)/(T - (1+lag_guess*M) - M -1); /* AICC*/
          sbc = ln(det(VARCOV)) + (1/T)*(M*M*lag_guess+M)*ln(T)+ M*(1+ln(2*pi)); 
          hqc = ln(det(VARCOV)) + (2/T)*(M*M*lag_guess+M)*ln(ln(T))+ M*(1+ln(2*pi));
          hjc = (sbc + hqc)/2;

    /* print "aic=";; aic;; print "lag_guess=";; lag_guess; 
     print "sbc=";; sbc;; print "lag_guess=";; lag_guess; 
     print "hqc=";; hqc;; print "lag_guess=";; lag_guess; */
          if (lag_guess==p);
             aicmin = aic; 
             aiclag = lag_guess;
             aicA = Ahat;      
             aiccmin = aic; 
             aicclag = lag_guess;
             aiccA = Ahat;     
             sbcmin = sbc;  
             sbclag = lag_guess;
             sbcA = Ahat;     
             hqcmin = hqc;
             hqclag = lag_guess;
             hqcA = Ahat;   
             hjcmin = hjc;
             hjclag = lag_guess;
             hjcA = Ahat;   
          else;
             if (aic <= aicmin);
                aicmin = aic; 
                aiclag = lag_guess; 
                aicA = Ahat;  
             endif; 

             if (aicc <= aiccmin);
                aiccmin = aicc; 
                aicclag = lag_guess; 
                aiccA = Ahat;  
             endif; 


          /*   aicfnd;;" ";;aic;;" ";;aicmin; */
          /*   if ((aicfnd == 0) and (aic > aicmin));
                aiclag = lag_guess +1;
                aicA = Ahat;
                aicfnd = 1;
             else;
                aicmin = aic;
             endif;
       */

             if (sbc <= sbcmin);
                sbcmin = sbc;
                sbclag = lag_guess;
             sbcA = Ahat;  
             endif;

             if (hqc <= hqcmin);
                hqcmin = hqc;
                hqclag = lag_guess;
                hqcA = Ahat;  
             endif;

             if (hjc <= hjcmin);
                hjcmin = hjc;
                hjclag = lag_guess;
                hjcA = Ahat;  
             endif;
          endif;
      /*    if (lag_guess == lags);
               actlA = Ahat;  
          endif; */
          if (lag_guess == 1);
               onelA = Ahat; 
          endif; 
          lag_guess = lag_guess - 1; 
       endif;
   endo;
   retp(aiclag, aicclag, sbclag, hqclag, hjclag, aicA, aiccA, sbcA, hqcA, hjcA, onelA, nocando);
endp;