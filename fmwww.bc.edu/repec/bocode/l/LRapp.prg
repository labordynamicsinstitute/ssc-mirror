/*LRapp.prg*/

/*This GAUSS module calculates the multivariate information criteria with the LR test used in conflict to determine the optimal lag order in a VAR model. 

Applications are allowed only if proper reference is provided. For non-Commercial applications only.

No performance guarantee is made. Bug reports are welcome. 
@Authors: R. Scott Hacker and Abdulnasser Hatemi-J@
Reference: 
Hatemi-J A and Hacker R.S (2009) Can the LR test be helpful in choosing the optimal lag order in the VAR model when information criteria suggest different lag orders?,
Applied Economics, vol. 41(9), 1121-1125.
*/


load Z[n,v]=dat.txt;	/* n is the number of observations, v is the number of variables in the VAR model, and dat is your data file in text format. */
p=?;				/* p is the maximum lag order to be considered.*/   /*  */


{aiclag, sbclag, hqclag, ssclag, aicA, sbcA, hqcA, sscA} 
                                                    = lag_length3(Z,p);


     format /rd 10,4;

"Suggested lag length using AIC:"; aiclag;
"Suggested lag length using SBC:"; sbclag;
"Suggested lag length using HQC:"; hqclag;
"Suggested lag length using SBC and HQC, with LR test used in conflicts"; ssclag;

"Matrix of coefficients based on suggested lag length by AIC";aicA;
"Matrix of coefficients based on suggested lag length by SBC";sbcA;
"Matrix of coefficients based on suggested lag length by HQC";hqcA;
"Matrix of coefficients based on suggested lag length by SBC and HQC, with LR test used in conflicts";sscA;



/*************************************************************************
----PROC lag_length3 
----AUTHOR: Scott Hacker
----ATTRIBUTION: Parts of this code are taken from proc LR_LAG
    written by David Rapach (may 27 1996 version).
----INPUT:      
      Z  - data matrix. Each column is a vector of observations on one
             endogenous variable
      p  - maximum lag length. This should be >= 2

----OUTPUT: aiclag  - Lag length suggested by Akaike info criterion.
                    sbclag -  Lag length suggested by Schwarz-Bayesian criterion.
                    hqclag - Lag length suggested by Hannon-Quinn criterion.
                    ssclag - Second-step "criterion"
                    aicA - Matrix of coefficient estimates based on aiclag.
                    sbcA - Matrix of coefficient estimates based on sblag.
                    hqcA - Matrix of coefficient estimates based on hqlag.
                    sscA - Matrix of coefficient estimates based on ssclag. 

----GLOBAL VARIABLES: none
----EXTERNAL PROCEDURES: VARLAGS, by Alan G. Isaac
----NB: none.
************************************************************************/

proc (8) = lag_length3 (z, p);
   local M, Y, ylags, T,i, j, lag_guess,X, Ahat, RES, VARCOV,
            aic, sbc, hqc, aicmin, aiclag, sbcmin, sbclag, hqcmin, hqclag,
            aicfnd, ldvc, aicldvc, sbcldvc, hqcldvc, ldvcnonadj,
            YLR, TLR, XLRhqc, XLRsbc, AhatLRhqc, AhatLRsbc, 
            RESLRhqc, RESLRsbc, ylagsLR, LRcriticalval,LR;
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

          Ahat = (Inv(X'*X)*(X'*Y))';
          RES = Y - X*Ahat';
          VARCOV = RES'RES/T;
          ldvcnonadj = ln(det(VARCOV));
 /*          ldvc = ln(det(RES'RES/(T-(M*M*lag_guess +M)))); */ /*k adjusted for full system */
 /*         ldvc = ln(det(RES'RES/(T-(M*lag_guess +1)))); */    /* k adjusted for single equation */
           ldvc = ldvcnonadj; 
          aic =   ldvcnonadj + (2/T)*(M*M*lag_guess +M)+ M*(1+ln(2*pi)); 
          sbc =  ldvcnonadj + (1/T)*(M*M*lag_guess+M)*ln(T)+ M*(1+ln(2*pi)); 
          hqc =  ldvcnonadj + (2/T)*(M*M*lag_guess+M)*ln(ln(T))+ M*(1+ln(2*pi)); 
          if (lag_guess==p);
             aicmin = aic; 
             aiclag = lag_guess;
             aicA = Ahat;      
             aicldvc = ldvc;   
             sbcmin = sbc;  
             sbclag = lag_guess;
             sbcA = Ahat;     
             sbcldvc = ldvc;   
             hqcmin = hqc;
             hqclag = lag_guess;
             hqcA = Ahat;   
             hqcldvc = ldvc;   
          else;
             if (aic <= aicmin);
                aicmin = aic; 
                aiclag = lag_guess; 
                aicA = Ahat;  
                aicldvc = ldvc;   
             endif;

             if (sbc <= sbcmin);
                sbcmin = sbc;
                sbclag = lag_guess;
                sbcA = Ahat;  
                sbcldvc = ldvc;   
             endif;
             if (hqc <= hqcmin);
                hqcmin = hqc;
                hqclag = lag_guess;
                hqcA = Ahat;
                hqcldvc = ldvc;     
             endif;
          endif;
          lag_guess = lag_guess - 1; 

   endo;
   if sbclag == hqclag;
      ssclag = sbclag;
      sscA = sbcA;
   else;
      if sbclag < hqclag;
          if sbcldvc > hqcldvc;  
            {YLR, ylagsLR} = varlags(z,hqclag);
             TLR=rows(YLR);
 
             XLRhqc = ones (TLR,1) ~ylagsLR;
             AhatLRhqc = (YLR/XLRhqc)';
             RESLRhqc = YLR - XLRhqc*AhatLRhqc';
             hqcldvc = ln(det(RESLRhqc'RESLRhqc/TLR));

             If sbclag >0;
                  XLRsbc = ones (TLR,1) ~ylagsLR[ . , 1:sbclag*M];
             else;
                  XLRsbc = ones (TLR,1);
             endif;
             AhatLRsbc = (YLR/XLRsbc)';
             RESLRsbc = YLR - XLRsbc*AhatLRsbc';
             sbcldvc = ln(det(RESLRsbc'RESLRsbc/TLR));
             LR  = TLR*(sbcldvc - hqcldvc);
             if ssclag == hqclag;
                sscA = hqcA;
             else;
                sscA = sbcA;
             endif;
          else;
              ssclag = sbclag;
              sscA = sbcA;
          endif;
       else;
           if cdfchic((TLR-(1+M*hqclag))*(hqcldvc - sbcldvc) ,M*M*(sbclag-hqclag)) < 0.05;
                ssclag = sbclag;
                sscA = sbcA;
           else;
                ssclag = hqclag;
                sscA = hqcA;
           endif;   
       endif;          
   endif;
   retp(aiclag, sbclag, hqclag, ssclag, aicA, sbcA, hqcA, sscA);
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
