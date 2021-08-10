/*MV-AR.prg*/

/*This GAUSS module implements three multivariate tests for autocorrelation-namely the multivariate LM test, the multivariate F-test and the multivariate portmanteau test-in the VAR model. 
The output of the module is the corresponding p-value of each test for each autocorrelation order. Among these tests, the modified LM test suggested by Hatemi-J (2004) has the best performance. 
The modification is based on an Edgeworth expansion. 
Reference: Hatemi-J A. (2004) Multivariate tests for autocorrelation in the stable and unstable VAR models, Economic Modelling, 21, 661-683.

Applications are allowed only if proper reference is provided. For non-Commercial applications only.

No performance guarantee is made. Bug reports are welcome. 
@Authors: Scott Hacker and Abdulnasser Hatemi-J@ */


 load rawdata[]  = dat.txt; 			 /* dat.txt is your data file in text format.  */


Numvars = v;            			/*  v is the number of variables in the VAR model.*/
numobs = (rows(rawdata)/Numvars);
y = Reshape(rawdata, numobs, Numvars);

     format /rd 10,6; 



Smax =k;			   	@ k is the maximum order of AR to test for @

earlyzeros = 0;    /* If one, set early lags of residuals equal to zero if unavailable;
			 if zero, truncate residual series to accommodate early lags */

lags = p; 			@ p is the lag order of the VAR model @


                                                 {yadj, ylags} = varlags(y,lags);
                                                  T=rows(yadj);
                                                  X = ones (T,1) ~ylags;
     						  Ahat = (yadj/X)';
    						  varres = yadj - X*Ahat';
    					           INVCOV00 = INVPD(((varres[1:T,.])'*(varres[1:T,.]))/(T));

                                                   LBS = 0;


					          teststat = zeros(3,Smax);
					          pvalue =  zeros(3,Smax);
                                                  S=1;

                                                   do until S > Smax;
/*subr. call */                                   {LBS} = LBPort (S, varres,T,LBS,INVCOV00);

                                                        LBSpv = cdfchic(LBS,numvars^2*(S-lags));                    
                                                        {BG,BGpv}= BreuschG(S, varres, ylags, lags, numvars);
							teststat[.,S] = LBS|BG;
							pvalue[.,S] =   LBSpv|BGpv;
                                                        S = S +1;
                                                   endo;                                             
                       	     					
     "Pvalues based on Multivariate Q-test, for AR orders of 1, 2, 3, ..... respectively:";
      S = 1;
      do until S > lags;
           "        NA       ";;
            S = S + 1;   
      endo;              

      pvalue[1,S:Smax];
                 " ";

     "Pvalues based on adjusted LM test, for AR orders of 1, 2, 3, ..... respectively:";
        pvalue[2,.];
                 " ";
     "Pvalues based on Multivariate F-test, for AR orders of 1, 2, 3, ..... respectively:";
         pvalue[3,.];                                              



/*************************************************************************
----PROC LBPort 
----AUTHOR: Scott Hacker (in cooperation with Hatemi-J) 
----INPUT:      
      S  - order of autocorrelation to test for
      varres -  residuals from VAR regression
      T - number of observations
      LBS - LBS statistic for  S -1
      INVCOV00 - var-cov matrix for residuals
----OUTPUT: Ljeung-Box Statistic:
       LBS = T(T) x sum (j=1 to S) of (1/(T-j)) x trace(C(0,j)inv[C(0,0)]C'(0,j)inv[C(0,0)])
       where C(0,j) = sum(t = j+1 to T) for e(t)e'(t-j), and
       e(t) is the residual from the estimation of 
       y(t) = v + A(1)y(t-1) + . . . + A(k)y(t-k) + error(t)
     Note this definition is used rather than
        LBS = T(T+2) x sum (j=1 to S) of (1/(T-j)) x trace(C(0,j)inv[C(0,0)]C'(0,j)inv[C(0,0)])
     as the first definition matches equation 4.4.23 in Lutkepohl's textbook on
     Multivariate Time Series.
----GLOBAL VARIABLES: none
----NB: none.
************************************************************************/
proc (1) = LBPort(S, varres,T,LBS,INVCOV00);
   local cov0S,tracematrix,pvalue, RESNOW, RESLAGGED, j, COV0J;
          COV0S = ( (varres[S+1:T,.])'*(varres[1:T-S,.]) )/T;
          j = S;
          RESNOW = varRES[j+1:T,.];
/*print "line 662 RESNOW=";; RESNOW;*/
          RESLAGGED = varRES[1:T-j,.];
          COV0j = (RESNOW'*RESLAGGED)/T;
/*format /rd 12,7; print "line 654 COV0S";; COV0S;" S=";; S; "COV0J=";; cov0j;*/
          tracematrix = COV0S*INVCOV00*COV0S'*INVCOV00;
          LBS = LBS + (T*(T)/(T-S))*ones(1,rows(tracematrix))*diag(tracematrix);
        /*  print " line 667! LBS=";LBS; */
          retp(LBS);
endp;        


/*************************************************************************
----PROC BreuschG 
----AUTHOR: Scott Hacker (in cooperation with Hatemi-J) 
----INPUT:     
      S  - order of autocorrelation to test for
      varres -  residuals from VAR regression
      ylag - original y lag series for VAR regression
      numvars - number of variables 

----OUTPUT:
      BG vector made up of
          BGLMC2 - Breusch-Godfrey LM statistic (df corrected) (zeroed early lagged residuals)
          BGRAO2 - Breusch-Godfrey Rao statistic (zeroed early lagged residuals)
  
      BGpv made up of pvalues for each of elements in BG vector
----GLOBAL VARIABLES: none
----EXTERNAL PROCEDURES: VARLAGS, by Alan G. Isaac
----NB: none.
************************************************************************/
proc (2) = BreuschG(S, varres, ylags, lags, numvars);
   local numrestns, varresadj, varreslags,ylagsadj,Tadj,Z,Ahat,resr,SR,resu,
           SU,U,tracematrix,BGLMC,q,x,BGRAO,BGLMCpv,BGRAOpv,varreslags0s,varreslags0sall,
                                      BGLMC2,BGRAO2,BGLMC2pv,BGRAO2pv,BG,BGPV,df,dfe,lagindx,
                                      Zall, Ahatall, resuall, SUall, VCVAR, VCUall,
HJvarcovvar,
HJvarcovunr,
HJvarcovvardet,
HJvarcovunrdet,
SHtester;
              numrestns = S*(numvars^2);
             {varresadj, varreslags} = varlags(varres,S);

            /*Non-starred cases: early lagged residuals not provided zeros */
              ylagsadj = trimr(ylags,S,0);
              Tadj=rows(varresadj);

/*              Z = ones (Tadj,1) ~ylagsadj;
     	      Ahat = (varresadj/Z)';
    	      RESR = varresadj - Z*Ahat';
              SR = RESR'*RESR;

              Z = ones (Tadj,1) ~ylagsadj~varreslags;
              Ahat = (Inv(Z'*Z)*(Z'*varresadj))';
    	      RESU = varresadj - Z*Ahat';
	      SU = RESU'*RESU;

              U = det(SR)/det(SU);

	      df = Tadj - (1+lags + S)*numvars;
              dfe = Tadj - 1 - (lags + S)*numvars + 0.5*(numvars*(S-1) - 1);


              tracematrix = INVPD(SR)*SU;
*/
/*             BGLMC = Tadj*(numvars - ones(1,rows(tracematrix))*diag(tracematrix)); */   @uncorrected LM @
/*              BGLMC = df*(numvars - ones(1,rows(tracematrix))*diag(tracematrix)); */		 @corrected LM @
/*                 BGLMC = dfe*ln(det(varres'*varres)/det(SU)); */@Johansen method @
/*                 BGLMC = dfe*ln(det(SR)/det(SU));   */

/*              x = ( (numrestns^2 -4)/((S^2 +1)*numvars^2 - 5)     )^0.5;
              q = dfe* x -  (( numrestns/2) -1 ) ;
              BGRAO =  (q/numrestns )*(U^(1/x) - 1 );
             
              BGLMCpv = cdfchic(BGLMC,numrestns);
 	      BGRAOpv = cdffc(BGRAO,numrestns, q); 
*/           
            /*starred cases: early lagged residuals provided zeros */
               
/*	     varreslags0s = (zeros(S,cols(varreslags))|varreslags); 
             print "line 1031 varreslags0s=";;varreslags0s; */


/*  This section creates varreslags0s keeping all lagged residuals up to the that being tested */
	      varreslags0sall = zeros(1,numvars)|varres[1:(rows(varres) - 1), .];
              lagindx = 2;
              do until lagindx > S; 
                   varreslags0sall = varreslags0sall~(zeros(lagindx,numvars)|varres[1:(rows(varres) - lagindx), .]);
	           lagindx = lagindx + 1; 
	      endo;

/*end of varreslags0s section */

/*  This section creates varreslags0s keeping lagged residuals for only that being tested */

      varreslags0s = (zeros(S,numvars)|varres[1:(rows(varres) - S), .]);

/*end of varreslags0s section */


/*print "varres=";;varres;
print "varreslags0s=";;varreslags0s; */
              Tadj=rows(varres);

 /*              Z = ones (Tadj,1) ~ylags;
     	      Ahat = (varres/Z)';
    	      RESR = varres - Z*Ahat';
              SR = RESR'*RESR;*/
              SR = varres'*varres;

 /*             Z = ones (Tadj,1) ~ylags~varreslags0s;
     	      Ahat = (varres/Z)';
    	      RESU = varres - Z*Ahat';
	      SU = RESU'*RESU;*/

              Zall = ones (Tadj,1) ~ylags~varreslags0sall;
/*     	      Ahatall = (varres/Zall)'; */
              Ahatall = (Inv(Zall'*Zall)*(Zall'*varres))';
    	      RESUall = varres - Zall*Ahatall';
	      SUall = RESUall'*RESUall;

              U = det(SR)/det(SUall);

	      df = Tadj - (1+lags + S)*numvars;
              dfe = Tadj - 1 - (lags + S)*numvars + 0.5*(numvars*(S-1) - 1);
/*print "line 1082 df = ";;df;
print "line 1083 dfe = ";;dfe;*/
 /*             tracematrix = INVPD(SR)*SU; */
 /*             BGLMC2 = Tadj*(numvars - ones(1,rows(tracematrix))*diag(tracematrix));  */@uncorrected LM @
 /*             BGLMC2 = df*(numvars - ones(1,rows(tracematrix))*diag(tracematrix));   */        @corrected LM @
 /*                BGLMC2 = dfe*ln(det(varres'*varres)/det(SU));  */@Johansen method @
                 BGLMC2 = dfe*ln(det(SR)/det(SUall));   


             x = ( (numrestns^2 -4)/((S^2 +1)*numvars^2 - 5)     )^0.5;
              q = dfe * x -  (( numrestns/2) -1 ) ;
/*print "line 1113 q=";;q;;"   numrestns=";;numrestns;;"    x=";;x;;"  S=";;S;*/
              BGRAO2 =  (q/numrestns )*(U^(1/x) - 1 );
/*print "line 1114 BGRAO2=";;BGRAO2;*/
              BGLMC2pv = cdfchic(BGLMC2,numrestns);
 	      BGRAO2pv = cdffc(BGRAO2,numrestns, q); 

/*              BG = BGLMC|BGRAO|BGLMC2|BGRAO2;
              BGpv = BGLMCpv|BGRAOpv|BGLMC2pv|BGRAO2pv;*/
               BG = BGLMC2|BGRAO2;
              BGpv = BGLMC2pv|BGRAO2pv;

   retp(BG, BGpv);
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