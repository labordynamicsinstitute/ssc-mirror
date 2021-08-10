/*MV-ARCH.prg*/

/*This GAUSS module implements the multivariate ARCH test developed by Hacker and  Hatemi-J (2005). It provides p-values based on assymptotic as well as boostrap distributions.

Applications are allowed only if proper reference is provided. For non-Commercial applications only.

No performance guarantee is made. Bug reports are welcome. 
Authors: Scott Hacker and Abdulnasser Hatemi-J */	

@This is an applied version of 
the software used for the paper 
"A Test for Multivariate ARCH"
by R Scott Hacker and Abdulnasser Hatemi-J @

 load rawdata[]  = dat.txt; 			 /* dat.txt is your data file in text format.  */


Numvars = v;            			/*  v is the number of variables in the VAR model.*/
numobs = (rows(rawdata)/Numvars);
y = Reshape(rawdata, numobs, Numvars);

     format /rd 10,6; 

bootsimmax =500;          	@the maximum # of bootstrapped simulations per regular simulation@
					   	@should be a multiple of 20 @

Smax = k;			   	@ k is the maximum order of ARCH to test for @

earlyzeros = 1;    /* If one, set early lags of residuals equal to zero if unavailable; if zero, truncate residual series to accommodate early lags */

lags = p; 			@ p is the lag order of the VAR model @


      						  /* homosc. case */
                                                 {yadj, ylags} = varlags(y,lags);
                                                  T=rows(yadj);
                                                  X = ones (T,1) ~ylags;
						  InvXTXXT = Inv(X'X)*X';
 						  Ahat = (InvXTXXT*yadj)';

 						  H =      X*InvXTXXT;
						  /* leverage = diag(H); */
                                                  leverage = 0;
                               
    						  varres = yadj - X*Ahat';
                                                  varres2 = varres^2;

    					          /* INVCOV00 = INVPD(((varres2[1:T,.])'*(varres2[1:T,.]))/(T)); */
					          /*Covariance calculated from Eviews would have T-5 
                                                  in the divisor rather than T, but that does not affect Portmanteau Q-stats.
 					          Perhaps that's because the dividing by T cancels out 
  						  in the final formula of the Q-Stat */ 
                                             
					          teststat = zeros(1,Smax);
					          pvalue =  zeros(1,Smax);

                                                   S=1;
                                                   do until S > Smax;

							  numrestns = S*(numvars^2);                  

                                                          {MLMstat}= MLM(S, varres2, lags, numvars,numrestns,earlyzeros);

							  MLMstatpv = cdfchic(MLMstat[1,1],numrestns);
						
                                                        teststat[.,S] = MLMstat;
							pvalue[.,S] =  MLMstatpv;



                                                    S = S +1;
                                                   endo;

						   Xstart = X[1,.];
/*"teststat=";;teststat;*/
						   {MLMpvboot} = Boot_pvals(Smax, Ahat, Xstart, varres,leverage,T,teststat,lags,numvars,bootsimmax);	

                                                   "pvalues based on asymptotics, for ARCH orders of 1, 2, 3, ..... respectively:";
                                                      pvalue;
                                                   "pvalues based on bootstrapping, for ARCH orders of 1, 2, 3, ..... respectively:";
                                                      MLMpvboot;

 



/*************************************************************************
----PROC MLM 
----AUTHOR: Scott Hacker
----INPUT:     
      S  - order of multivariate ARCH to test for
      varres2 -  squared residuals from VAR regression
      lags - order of VAR model
      numvars - number of variables 
      numrestns - number of restrictions (ARCHorder * (number of variables in VAR)^2)
      earlyzeros - If one, set early lags of residuals equal to zero if unavailable;
                          if zero, truncate residual series to accommodate early lags
      

----OUTPUT:
      MLMstat - Multivariate LM test statistic 
  
----GLOBAL VARIABLES: none
----EXTERNAL PROCEDURES: VARLAGS, by Alan G. Isaac
----NB: none.
************************************************************************/
proc (1) = MLM(S, varres2,  lags, numvars,numrestns, earlyzeros);
   local varres2use, varres2lagsuse,ylagsadj,Tadj,Z,Ahat,resr,SR,resu,
           SU,U,tracematrix,BGLMC,q,x,BGRAO,BGLMCpv,BGRAOpv,varres2lags0s,varres2lags0sall,
                                      BGLMC2,BGRAO2,BGLMC2pv,BGRAO2pv,BG,BGPV,df,dfe,lagindx,
                                      Zall, Ahatall, resuall, SUall, VCVAR, VCUall,
HJvarcovvar,
HJvarcovunr,
HJvarcovvardet,
HJvarcovunrdet,
SHtester,
ZallR, AhatallR, RESRall;

 
            If earlyzeros == 0;
             {varres2use, varres2lagsuse} = varlags(varres2,S);
            else;
              /*  This section creates varreslags2use with early zeros */
              varres2use = varres2;
	      varres2lagsuse = zeros(1,numvars)|varres2[1:(rows(varres2) - 1), .];
              lagindx = 2;
              do until lagindx > S; 
                   varres2lagsuse = varres2lagsuse~(zeros(lagindx,numvars)|varres2[1:(rows(varres2) - lagindx), .]);
	           lagindx = lagindx + 1; 
	      endo;

            /*end of varres2lagsuse section */
             endif;

              Tadj=rows(varres2use);
              ZallR = ones (Tadj,1);
              AhatallR = (Inv(ZallR'*ZallR)*(ZallR'*varres2use))';
    	      RESRall = varres2use - ZallR*AhatallR';
              SR = RESRall'*RESRall;

              Zall = ones (Tadj,1)~varres2lagsuse;

              Ahatall = (Inv(Zall'*Zall)*(Zall'*varres2use))';
    	      RESUall = varres2use - Zall*Ahatall';
	      SUall = RESUall'*RESUall;

              dfe = Tadj - 1 - (S)*numvars + 0.5*(numvars*(S-1) - 1); 

              MLMstat = dfe*ln(det(SR)/det(SUall));   

   retp(MLMstat);
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
----PROC Bootstrap_pvals
----AUTHOR: Scott Hacker
----INPUTS:      
       Smax- maximum number for ARCH order considered.
        Ahat- estimated A matrix
        Xstart - starting values for X in bootsrap, based on raw data
        varres - residuals from VAR model using raw data
         leverage- based on VAR model using raw data
         T - number of observations after adjusting for lags
         teststat - test statistics based on raw dta
          lags - number of lags in VAR model
         numvars - number of variables
        bootsimmax - maximum number of bootstraps considered
----OUTPUT: 
     MLMpvboot - matrix of bootstrapped p-values for the multivariate LM test
----GLOBAL VARIABLES: none
----EXTERNAL PROCEDURES: MLM;
----NB: none.
************************************************************************/
 proc(1) = Boot_pvals(Smax,Ahat,Xstart,varres,leverage,T,teststat,lags,numvars,bootsimmax);
 local adjRES, bootsim, Xhat, obspull, randomnumbers, index, simerr,yhatrow,
 yhat, Ahatboot, varresboot, varres2boot, INVCOV00,LBSboot,S, LBSpvboot,numrestns,MLMboot,MLMpvboot,
numvarsindx,q;


 adjRES = (varres) ./ (Sqrt(ones(T,1) - leverage));


 LBSpvboot = zeros(1,Smax);
 MLMpvboot = zeros(1,Smax);
 simerr = zeros(T,numvars);
  
bootsim = 1;  
 do until bootsim > bootsimmax;

       obspull = 1;
       do until obspull > T;
          randomnumbers = rndu(1,numvars);
          index = 1+ trunc(T*randomnumbers);

          numvarsindx = 1;
          do until numvarsindx > numvars;
               simerr[obspull,numvarsindx] = adjRES[index[1,numvarsindx],numvarsindx];
               numvarsindx = numvarsindx + 1;
          endo;
          obspull = obspull +1;
       endo;

       numvarsindx = 1;
       do until numvarsindx > numvars;
            simerr[.,numvarsindx] = simerr[.,numvarsindx] - (meanc(simerr[.,numvarsindx])) ;
            numvarsindx = numvarsindx + 1;
       endo;

      Xhat = Xstart;
      obspull = 1;
      do until obspull > T;
        
          yhatrow = Xhat[obspull,.]*Ahat' + simerr[obspull,.];

          if lags > 1;
               Xhat= Xhat|(1~yhatrow~Xhat[obspull,2:1+numvars*(lags-1)]);
          else; @lags assumed to be 1@
               Xhat = Xhat|(1~yhatrow);
          endif;
          obspull = obspull + 1;
      endo;     
      yhat = Xhat[2:rows(Xhat), 2:(numvars+1)];
      Xhat = Xhat[1:rows(Xhat)-1,.];

     Ahatboot = (yhat/Xhat)';
     varresboot = yhat - Xhat*Ahatboot';
     varres2boot  = varresboot^2;

     LBSboot = 0;
     S=1;
     do until S > Smax;

	     numrestns = S*(numvars^2);    
             {MLMboot}= MLM(S, varres2boot, lags, numvars,numrestns,earlyzeros);

              MLMpvboot[.,S] = MLMpvboot[.,S]+(teststat[.,S] .< MLMboot);

 	     S = S + 1;
      endo;
      bootsim = bootsim +1;
 endo; 

 MLMpvboot = MLMpvboot/bootsimmax;

retp(MLMpvboot); 
endp;        					