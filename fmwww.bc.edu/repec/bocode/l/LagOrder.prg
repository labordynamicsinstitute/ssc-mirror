*LagOrder.prg*/

/*This GAUSS module calculates the multivariate AIC, SBC, HQC and HJC to determine the optimal lag order in a vector autoregressive (VAR) model. 

Applications are allowed only if proper reference is provided. For non-Commercial applications only.

No performance guarantee is made. Bug reports are welcome. */


load Z[n,v]=dat.txt;	/* n is the number of observations, v is the number of variables in the VAR model, and dat is your data file in text format. */
p=?;				/* p is the maximum lag order to be considered.*/   /*  */

{aiclag, sbclag, hqclag, hjclag, aicA, sbcA, hqcA, hjcA} = lag_length2(z, p);

     format /rd 10,4;

"Suggested lag length using AIC:"; aiclag;
"Suggested lag length using SBC:"; sbclag;
"Suggested lag length using HQC:"; hqclag;
 "Suggested lag length using HJC"; hjclag;

"Matrix of coefficients based on suggested lag length by AIC";aicA;
"Matrix of coefficients based on suggested lag length by SBC";sbcA;
"Matrix of coefficients based on suggested lag length by HQC";hqcA;
"Matrix of coefficients based on suggested lag length by HJC";hjcA;
/*
aicmin;; " ";; sbcmin;; " ";; hqcmin;; "  ";; hjcmin; */


/*************************************************************************
----PROC lag_length2 
----AUTHOR: Scott Hacker in cooperation with Abdulnasser Hatemi-J
----ATTRIBUTION: Parts of this code are taken from proc LR_LAG
    written by David Rapach (may 27 1996 version).
----INPUT:      
      Z  - data matrix. Each column is a vector of observations on one
             endogenous variable
      p  - maximum lag length. This should be >= 2
      lags - actual lag length.
----OUTPUT: aiclag  - Lag length suggested by Akaike info criterion.
                    sbclag -  Lag length suggested by Schwarz-Bayesian criterion.
                    hqclag - Lag length suggested by Hannon-Quinn criterion.
                    hjclag - Lag length suggested by Hatermi-J criterion.
                    aicA - Matrix of coefficient estimates based on aiclag.
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

proc (8) = lag_length2 (z, p);
   local M, Y, ylags, T,i, j, lag_guess,X, Ahat, RES, VARCOV,
            aic, sbc, hqc, hjc, aicmin, aiclag, sbcmin, sbclag, hqcmin, hqclag, hjcmin, hjclag,
            aicfnd;
    M = cols(z);                 		@ # endog vars @
      {Y, ylags} = varlags(z,p);
       T=rows(y);
    lag_guess = p;				@ initialization  of lag_guess @
    j = 0;
    aicfnd = 0;
    do until (lag_guess < 0);
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

          Ahat = (Y/X)';
          RES = Y - X*Ahat';
          VARCOV = RES'RES/T;
/*          aic =   ln(det(VARCOV)) + (2/T)*(M*M*lag_guess +M)+ M*(1+ln(2*pi)); */ /* Original AIC definition used */
          aic =   ln(det(VARCOV)) + ((T + (1+lag_guess*M))*M)/(T - (1+lag_guess*M) - M -1);
          sbc = ln(det(VARCOV)) + (1/T)*(M*M*lag_guess+M)*ln(T)+ M*(1+ln(2*pi)); 
          hqc = ln(det(VARCOV)) + (2/T)*(M*M*lag_guess+M)*ln(ln(T))+ M*(1+ln(2*pi));
          hjc = (sbc + hqc)/2;
     format /rd 10,4;
     print "aic=";; aic;; print "lag_guess=";; lag_guess; 
     print "sbc=";; sbc;; print "lag_guess=";; lag_guess; 
     print "hqc=";; hqc;; print "lag_guess=";; lag_guess; 
     print "hjc=";; hjc;; print "lag_guess=";; lag_guess; 
          if (lag_guess==p);
             aicmin = aic; 
             aiclag = lag_guess;
             aicA = Ahat;         
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

          lag_guess = lag_guess - 1; 

   endo;
"aicmin=";;aicmin;
"sbcmin=";;sbcmin; 
"hqcmin=";;hqcmin;
"hjcmin=";;hjcmin;

   retp(aiclag, sbclag, hqclag, hjclag, aicA, sbcA, hqcA, hjcA);
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