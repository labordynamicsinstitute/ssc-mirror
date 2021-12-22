
 /* MSITA.PRG: Gauss Module for Model Selection in Time Series Analysis*/ @Authors 2021: Scott Hacker and Abdulnasser Hatemi-J@


Print "***********************************************************************************************************************************";
Print "The current module implements the method explained in 'Model Selection in Time Series Analysis: Using Information Criteria as an Alternative to Hypothesis Testing' (forthcoming  in Journal of Economic Studies)";
Print "by R. Scott Hacker and Abdulnasser Hatemi-J. This method selects the best time series model among various potential ones using some common information criteria.";
Print "In addition, model weights based upon these information criteria are provided to consider the weight of evidence support one model or set of models over others.";
Print "These weights could possibly be used for averaging the estimated parameters across models in order to account for model uncertainty.";
Print "For technical details, see the paper noted above.";
Print " ";
Print "Note, that using this program in any format without explicit aknowledgment and relevant reference is not allowed!";
Print "This program code is the copyright of the authors of the associated paper, R. Scott Hacker and Abdulnasser Hatemi-J. For non-commercial applications only.";
Print "No performance guarantee is made. Bug reports are welcome. ";
Print " ";
Print "***********************************************************************************************************************************";
Print" ";

/*
The program requires All_Models_Paper.txt be available for loading.
The example data for loading is in Case_d_example.txt.
*/

outwidth 200;
/*output file = gmsita.asc reset; 
screen off; */  screen on; 


@Case_d_example text provides 53 observations on Y and Z, randomly generated according to
   dY = 0.5dY[t-1] + dZ[t-1]  - 0.3(Y[t-1] - (1 + Z[t-1]) + error. That results in 52 observations on dY, and
   if two augmentation lags are used, 50 observations overall to work with in relating
   dY to dY[1-1] and dY[t-2].
 @ 


@The example dataset below provides some example simulated data based on Case 3d from Figure 3 in the paper, with
b[10] = 0.3 as the true model, i.e. dY[t] = 0.5dY[t-1] + dZ[t-1] - 0.3(Y[t-1] - 1 - Z[t-1]) + u[t] . Therefore model 13.01 from Table 1 in
the paper is the "true model." The number of observations including those needed for initial lags is 53. If up to 2 lags of differenced variables
are among the models considered 3 startup lags are needed, so then 50 lags excluding initial lags are available.  @

@Note that in the txt file that there are two columns, but the load statement reads a single column @
@The Reshape statement later makes the YZlevel matrix have the intended two columns, each representing one variable,
and each row shows an observation for the two variables. @


load YZlevel[]  = Case_d_example.txt;

/*The following file has the data from the Woolridge dataset on fertility, gfr, and personal exemptions, pe: */  @!!@
/*load YZlevel[] = Woolridge_fertil3_1917-1984.txt; */                                                                                          @!!@

"Prior to reshape: rows(YZlevel)=";;rows(YZlevel);
YZlevel = Reshape(YZlevel, (rows(YZlevel)/2), 2);
"After reshape: rows(YZlevel)= ";;rows(YZlevel);; "  cols((YZlevel)) ";; cols(YZlevel);

seasonal_dummies =0;  @ 0 = no seasonal dummies,
                                           1 = quarterly dummies,
                                           2 = monthly dummies @

@ The choice of "quarterly dummies" above creates 3 quarter dummy variables that are always included in models.
The choice of "monthly dummies" above creates 11 month dummy variables that are always included in models. If you wish to apply dummies for less months, 
you can set seasonal_dummies equal to 0 intead and use the incude_monthdummy vector below. 
It is recommended that you print the Xall matrix later (before the IC_Investigate procedure is called) to make sure the matrix is formed the way you expect. @

   include_monthdummy = {0,0,0,0,0,0,0,0,0,0,0,0}; @The aim of include_monthdummy is to allow the user to apply dummies to particular months.@

   maxauglags = 2;            @maximum number of augmentation lags to consider. 
                                            14 is highest allowed@
   If maxauglags < 12;
     include_monthdummy = include_monthdummy[(maxauglags+1):12,1]|
                                          include_monthdummy[1:maxauglags,1]; 
   elseif maxauglags > 12;
     include_monthdummy = include_monthdummy[(maxauglags-12+1):12,1]|
                                             include_monthdummy[1:(maxauglags-12),1]; 
   endif;

@ end include_monthdummy section @


trendstatus = 0;            @trend status cases:
					     	0 = unknown trend
 						1 = known there is trend
						2 =  known there is no trend @
if trendstatus == 0;
   "trend status unknown";
elseif trendstatus == 1;
   "known there is a trend";
elseif trendstatus == 2;
   "known there is no trend";
endif;
                                     
numcriteria = 7; /*Maximum that can report; this typically should not be changed.*/
@ methods available are 1 = AIC, 2 = AICC, 3 = AICU, 4 = SIC, 5 = HQC, 6 =HJC, 7 = CV @

default_methodstorpt = {1,2,3,4,5,6,7}; 
methodstorpt = {1,2,3,4,5,6,7}; @One can choose less models to report, or change their order, but the column titles are removed.@
                                                  @ CV, if used, should be the last method in list. @
CVislast = methodstorpt[rows(methodstorpt),.]==7;
sortIC = 4; @ Sorts models from highest to lowest weight based on the method noted in the sortIC'th method noted in methodstorpt.
                      Model averaging is also based on the sortIC'th method noted in methodstorpt. @

cointvec_est_with_numobs = 1; @ If 1, then in estimating cointegrating vector, the first (maxauglags +1) are excluded.
                                                         The estimates should be identical from the ones achieved through model 11 then.
                                                         This is how it is handled in the paper, but setting this equal to 0 instead seems 
                                                         reasonable, to take advantage of the observations at the beginning that are otherwise
                                                         just being used for lags. @
report_IC = 1; @ if 1, then information criterion values are reported. @

/*
 In model number the following system is used:
"*Number after decimal pt is number of augmentation lags in dY, incl. those in dX if dif relation in model";
"Number before decimal point represents one of following:";
"  1= RW: dY = (+auglags in dY if any) + u ";
"  2= RW drift:dY = b1  (+ auglags in dY if any) + u ";
"  3= Statnry: dY= b1 + b3*Y(-1)  (+ auglags in dY if any) + u (b3 < 0)";
"  4 = Statnry trend: dY= b1 + b2*t + b3*Y(-1)   (+ auglags in dY if any) + u (b3 < 0)";
"  5 = WN: Y = b1 (+ auglags in dY if any) + u ";
"  6 = WN trend: Y = b1 + b2*t  (+ auglags in dY if any) + u";
"  7 = Diffrel no int:  dY= b8*dZ  + u";
"  8 = Diff rel, with int:  dY=b1 + b8*dZ  + u ";
"  9 = Diff GC, no int:  dY= (auglags in both dY and dZ) + u  ";
"10 = Diff GC no int:  dY=  b1 + (auglags in both dY and dZ) + u  ";
"11 = Crrnt lvl rltn: Y = b1 + b6*Z + u";
"12 = Crrnt lvl rltn trend: Y = b1 + b2*t + b6*Z + u";
"13 = EC no drift:   dY = b11*(Y(-1) - (c1 + c2*Z(-1)) + (auglags in both dY and dZ) + u";
"14 = EC with drift: dY = b1 + b11*(Y(-1) - (c1 + c2*Z(-1)) + (auglags in both dY and dZ) + u "; 
"15: dY= b3*Y(-1)  (+ auglags in both dY and DdZ ) + u";
"16: like 15 w/ intrcpt"; 
*/

/* Valid models for two-variable relation model choosing */

load All_Models_Paper[241,39] = All_Models_Paper.txt;
RW_models = All_Models_Paper[1:15,.];
RWdrift_models = All_Models_Paper[16:30,.];
Stationaryaroundconstant_models =All_Models_Paper[31:45,.];
Stationaryaroundtrend_models = All_Models_Paper[46:60,.];
Whitenoise_models =  All_Models_Paper[61:75,.];
Whitenoisetrend_models = All_Models_Paper[76:90,.];
Differencerelationnoint_models = All_Models_Paper[91:105,.];
Differencerelationwithint_models = All_Models_Paper[106:120,.];
DifferenceGCnoint_models =  All_Models_Paper[121:135,.];
DifferenceGCwithint_models = All_Models_Paper[136:150,.];
Currentlevelrelnotrend_models = All_Models_Paper[151:165,.];
Currentlevelreltrend_models = All_Models_Paper[166:180,.];
Errorcorrectionnodrift_models = All_Models_Paper[181:195,.];
Errorcorrectionwithdrift_models =  All_Models_Paper[196:210,.];
Mixnoint_models =  All_Models_Paper[211:225,.];
Mixwithint_models = All_Models_Paper[226:240,.];


@The following system in used in All_models_paper. The "." columns are unused. @
                                                    @dylags@                                                            @dzlags@
                   @c1 . c2 . @
                                @b1 b2 b3@
                                                @b4 b5 ..............................@
                                                                                                           @b6 . b7@     @b8 b9 ............................     b10@                                                                                                                                                                              
/*
                        0 0 0 0  0 0 0       0 0 0 0 0 0 0 0 0 0 0 0 0 0                   0 0 0            0 0 0 0 0 0 0 0 0 0 0 0 0 0     0, 
                        0 0 0 0  0 0 0       1 0 0 0 0 0 0 0 0 0 0 0 0 0                   0 0 0            0 0 0 0 0 0 0 0 0 0 0 0 0 0     0, 
                        0 0 0 0  0 0 0       1 1 0 0 0 0 0 0 0 0 0 0 0 0                   0 0 0            0 0 0 0 0 0 0 0 0 0 0 0 0 0     0, 
                        0 0 0 0  0 0 0       1 1 1 0 0 0 0 0 0 0 0 0 0 0                   0 0 0            0 0 0 0 0 0 0 0 0 0 0 0 0 0     0, 
                        0 0 0 0  0 0 0       1 1 1 1 0 0 0 0 0 0 0 0 0 0                   0 0 0            0 0 0 0 0 0 0 0 0 0 0 0 0 0     0,                        
                        0 0 0 0  0 0 0       1 1 1 1 1 0 0 0 0 0 0 0 0 0                   0 0 0            0 0 0 0 0 0 0 0 0 0 0 0 0 0     0,  
                        0 0 0 0  0 0 0       1 1 1 1 1 1 0 0 0 0 0 0 0 0                   0 0 0            0 0 0 0 0 0 0 0 0 0 0 0 0 0     0,  
                        0 0 0 0  0 0 0       1 1 1 1 1 1 1 0 0 0 0 0 0 0                   0 0 0            0 0 0 0 0 0 0 0 0 0 0 0 0 0     0,  
                        0 0 0 0  0 0 0       1 1 1 1 1 1 1 1 0 0 0 0 0 0                   0 0 0            0 0 0 0 0 0 0 0 0 0 0 0 0 0     0,  
                        0 0 0 0  0 0 0       1 1 1 1 1 1 1 1 1 0 0 0 0 0                   0 0 0            0 0 0 0 0 0 0 0 0 0 0 0 0 0     0,  
                        0 0 0 0  0 0 0       1 1 1 1 1 1 1 1 1 1 0 0 0 0                   0 0 0            0 0 0 0 0 0 0 0 0 0 0 0 0 0     0,  
                        0 0 0 0  0 0 0       1 1 1 1 1 1 1 1 1 1 1 0 0 0                   0 0 0            0 0 0 0 0 0 0 0 0 0 0 0 0 0     0, 
                        0 0 0 0  0 0 0       1 1 1 1 1 1 1 1 1 1 1 1 0 0                   0 0 0            0 0 0 0 0 0 0 0 0 0 0 0 0 0     0,
                        0 0 0 0  0 0 0       1 1 1 1 1 1 1 1 1 1 1 1 1 0                   0 0 0            0 0 0 0 0 0 0 0 0 0 0 0 0 0     0,
                        0 0 0 0  0 0 0       1 1 1 1 1 1 1 1 1 1 1 1 1 1                   0 0 0            0 0 0 0 0 0 0 0 0 0 0 0 0 0     0};

  */


   specificrelation =    RW_models | 
                                RWdrift_models | 
                                Stationaryaroundconstant_models | 
                                Stationaryaroundtrend_models | 
                                Whitenoise_models | 
                                Whitenoisetrend_models | 
                                Differencerelationnoint_models | 
                                Differencerelationwithint_models | 
                                DifferenceGCnoint_models[2:15,.] | 
                                DifferenceGCwithint_models[2:15,.] | 
                                Currentlevelrelnotrend_models |
                                Currentlevelreltrend_models |
                                Errorcorrectionnodrift_models[2:15,.] | 
                                Errorcorrectionwithdrift_models[2:15,.] | 
                                Mixnoint_models[2:15,.] | 
                                Mixwithint_models[2:15,.];


   If trendstatus  == 0;
      Xsformodel =        
                                RW_models[1:(maxauglags+1),.]| 
                                RWdrift_models[1:(maxauglags+1),.] | 
                                Stationaryaroundconstant_models[1:(maxauglags+1),.] | 
                                Stationaryaroundtrend_models[1:(maxauglags+1),.] | 
                                Whitenoise_models[1:(maxauglags+1),.] | 
                                Whitenoisetrend_models[1:(maxauglags+1),.] |
                                Differencerelationnoint_models[1,.] | 
                                Differencerelationwithint_models[1,.] |
                                DifferenceGCnoint_models[2:(maxauglags+1),.]  | 
                                DifferenceGCwithint_models[2:(maxauglags+1),.] | 
                                Currentlevelrelnotrend_models[1,.] |
                                Currentlevelreltrend_models[1,.] |
                                Errorcorrectionnodrift_models[2:(maxauglags+1),.] | 
                                Errorcorrectionwithdrift_models[2:(maxauglags+1),.] |
                                Mixnoint_models[2:(maxauglags+1),.] | 
                                Mixwithint_models[2:(maxauglags+1),.]
                                ;
 
   elseif trendstatus  == 1;
     Xsformodel=         RWdrift_models[1:(maxauglags+1),.] | 
                                Stationaryaroundtrend_models[1:(maxauglags+1),.] | 
                                Whitenoisetrend_models[1:(maxauglags+1),.] |
                                Differencerelationwithint_models[1,.] | 
                                DifferenceGCwithint_models[2:(maxauglags+1),.] | 
                                Currentlevelreltrend_models[1,.] |
                                Errorcorrectionwithdrift_models[2:(maxauglags+1),.] | 
                                Mixwithint_models[2:(maxauglags+1),.];

    elseif trendstatus  == 2;
     Xsformodel=          RW_models[1:(maxauglags+1),.]| 
                                Stationaryaroundconstant_models[1:(maxauglags+1),.] | 
                                Whitenoise_models[1:(maxauglags+1),.] | 
                                Differencerelationnoint_models[1,.] | 
                                DifferenceGCnoint_models[2:(maxauglags+1),.] | 
                                Currentlevelrelnotrend_models[1,.] |
                                Errorcorrectionnodrift_models[2:(maxauglags+1),.] | 
                                Mixnoint_models[2:(maxauglags+1),.]; 
    endif;


   specificrelation  = specificrelation[.,1:7]~specificrelation[.,8:(7+maxauglags)]~specificrelation[.,22:24]~specificrelation[.,25:(24+maxauglags)]~specificrelation[.,39];
   Xsformodel = Xsformodel[.,1:7]~Xsformodel[.,8:(7+maxauglags)]~Xsformodel[.,22:24]~Xsformodel[.,25:(24+maxauglags)]~Xsformodel[.,39];

                            
actualrelationkey = {

4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,
4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,
4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,
4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,
4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,
4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,
2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
   2,2,2,2,2,2,2,2,2,2,2,2,2,2,
   2,2,2,2,2,2,2,2,2,2,2,2,2,2,
1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
   1,1,1,1,1,1,1,1,1,1,1,1,1,1,
   1,1,1,1,1,1,1,1,1,1,1,1,1,1,
   3,3,3,3,3,3,3,3,3,3,3,3,3,3,
   3,3,3,3,3,3,3,3,3,3,3,3,3,3};

modelnumberkey = {
 1.0, 1.01, 1.02, 1.03, 1.04, 1.05, 1.06, 1.07, 1.08, 1.09, 1.10, 1.11, 1.12, 1.13, 1.14,
 2.0, 2.01, 2.02, 2.03, 2.04, 2.05, 2.06, 2.07, 2.08, 2.09, 2.10, 2.11, 2.12, 2.13, 2.14,
 3.0, 3.01, 3.02, 3.03, 3.04, 3.05, 3.06, 3.07, 3.08, 3.09, 3.10, 3.11, 3.12, 3.13, 3.14,
 4.0, 4.01, 4.02, 4.03, 4.04, 4.05, 4.06, 4.07, 4.08, 4.09, 4.10, 4.11, 4.12, 4.13, 4.14,
 5.0, 5.01, 5.02, 5.03, 5.04, 5.05, 5.06, 5.07, 5.08, 5.09, 5.10, 5.11, 5.12, 5.13, 5.14,
 6.0, 6.01, 6.02, 6.03, 6.04, 6.05, 6.06, 6.07, 6.08, 6.09, 6.10, 6.11, 6.12, 6.13, 6.14,
 7.0, 7.01, 7.02, 7.03, 7.04, 7.05, 7.06, 7.07, 7.08, 7.09, 7.10, 7.11, 7.12, 7.13, 7.14,
 8.0, 8.01, 8.02, 8.03, 8.04, 8.05, 8.06, 8.07, 8.08, 8.09, 8.10, 8.11, 8.12, 8.13, 8.14,
         9.01, 9.02, 9.03, 9.04, 9.05, 9.06, 9.07, 9.08, 9.09, 9.10, 9.11, 9.12, 9.13, 9.14,
       10.01, 10.02, 10.03, 10.04, 10.05, 10.06, 10.07, 10.08, 10.09, 10.10, 10.11, 10.12, 10.13, 10.14,
 11.0, 11.01, 11.02, 11.03, 11.04, 11.05, 11.06, 11.07, 11.08, 11.09, 11.10, 11.11, 11.12, 11.13, 11.14,
 12.0, 12.01, 12.02, 12.03, 12.04, 12.05, 12.06, 12.07, 12.08, 12.09, 12.10, 12.11, 12.12, 12.13, 12.14,
       13.01, 13.02, 13.03, 13.04, 13.05, 13.06, 13.07, 13.08, 13.09, 13.10, 13.11, 13.12, 13.13, 13.14,
       14.01, 14.02, 14.03, 14.04, 14.05, 14.06, 14.07, 14.08, 14.09, 14.10, 14.11, 14.12, 14.13, 14.14,
       15.01, 15.02, 15.03, 15.04, 15.05, 15.06, 15.07, 15.08, 15.09, 15.10, 15.11, 15.12, 15.13, 15.14,
       16.01, 16.02, 16.03, 16.04, 16.05, 16.06, 16.07, 16.08, 16.09, 16.10, 16.11, 16.12, 16.13, 16.14
};
                       
modelnumbers = zeros(1,rows(Xsformodel));
spectoXs = zeros(1,rows(specificrelation));
i = 1;
 do until i > rows(Xsformodel);
       j= 1;
       do until Xsformodel[i,.] == specificrelation[j,.];
            j = j +1;
       endo;        
       modelnumbers[1,i] = j;
       spectoXs[1,j] = i;
       i = i + 1;
  endo;

nummodels= rows(Xsformodel);


quarterlydummies = {0 0 0,
                                   1 0 0,
                                    0 1 0,
                                    0 0 1};
 monthlydummies = 
{0 0 0 0 0 0 0 0 0 0 0,
 1 0 0 0 0 0 0 0 0 0 0,
 0 1 0 0 0 0 0 0 0 0 0,
 0 0 1 0 0 0 0 0 0 0 0,
 0 0 0 1 0 0 0 0 0 0 0,
 0 0 0 0 1 0 0 0 0 0 0,
 0 0 0 0 0 1 0 0 0 0 0,
 0 0 0 0 0 0 1 0 0 0 0,
 0 0 0 0 0 0 0 1 0 0 0,
 0 0 0 0 0 0 0 0 1 0 0,
 0 0 0 0 0 0 0 0 0 1 0,
 0 0 0 0 0 0 0 0 0 0 1}; 

mdummy = eye(12);


/* End of creation of valid models for two-variable relation model choosing */                                               

                       
/**************************************** End of User Input Section *************************************************************************/
/**********************************************************************************************************************************************/

/************************************** Some calculations and prints based on user inputs       ***************/


nummethods = rows(methodstorpt);



/*********************************** End of Initiliazing of variables *********************************************************/

/************************************ Creating X for Cross-Sectional Data **************************************************/






/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/
    numactualmodels = 0;


     format /rd 5,2;


"nummodels=";;nummodels;

          methodchoicesum = zeros(nummethods,nummodels);
          bootmodelchoicepctsum = zeros(nummethods,nummodels);
          relationchoicesum = zeros(nummethods,5);

                    dYZ = YZlevel[2:rows(YZlevel),.] - YZlevel[1:(rows(YZlevel)-1),.];
                    {dYapp,dYlags} = varlags(dYZ[.,1],maxauglags);
                    {dZapp,dZlags} = varlags(dYZ[.,2],maxauglags);
                     numobs = rows(DYapp); 
"number of observations, excluding needed initial lags for explanatory variables = ";;numobs;
if cointvec_est_with_numobs;
                   CointX = (ones(numobs,1)~YZlevel[(maxauglags+2):rows(YZlevel),2]);
                   Chat = (YZlevel[maxauglags+2:rows(YZlevel),1]/CointX);
else;
                    CointX = (ones(rows(YZlevel),1)~YZlevel[.,2]); 
                    Chat = (YZlevel[.,1]/CointX);
endif;
CointX = (ones(rows(YZlevel),1)~YZlevel[.,2]); 

                    Cointresiduals =  YZlevel[.,1] - CointX*Chat;
                    Xall = ones(numobs,1)~seqA(1,1,numobs)~YZlevel[(maxauglags+1):(rows(YZlevel)-1),1]
                    ~dYlags~YZlevel[(maxauglags+2):rows(YZlevel),2]~YZlevel[(maxauglags+1):(rows(YZlevel)-1),2]~dZapp~dZlags~Cointresiduals[(maxauglags+1):(rows(Cointresiduals)-1),1];

                    quarterlydummiesorig = quarterlydummies;
                    monthlydummiesorig = monthlydummies;


                    If seasonal_dummies == 1;
                         "Seasonal adjustment: 3 quarterly dummies";
                         i = 4;
                         do until i > numobs;
                             i = i + 4;
                            quarterlydummies = quarterlydummies|quarterlydummiesorig;
                         endo;
                         Xall = Xall~quarterlydummies[1:numobs,.];
                         Xsformodel = Xsformodel~ones(rows(Xsformodel),3);
                   elseif seasonal_dummies == 2;
                        "Seasonal adjustment: 11 month dummies";
                         i = 12;
                        do until i > numobs;
                             i = i + 12;
                             monthlydummies = monthlydummies|monthlydummiesorig;
                        endo;
                            Xall = Xall~monthlydummies[1:numobs,.];
                            Xsformodel = Xsformodel~ones(rows(Xsformodel),11);
                   endif;     
                   
                   monthindex = 1;
                   do until monthindex > 12;
                      If include_monthdummy[monthindex,1] == 1;
                            mdummyorig = mdummy[.,monthindex];
                            monthdummy = mdummyorig; 
                            i = 12;
                           do until i > numobs;
                                i = i + 12;
                                monthdummy = monthdummy|mdummyorig;
                           endo;
                               Xall = Xall~monthdummy[1:numobs,.];
                               Xsformodel = Xsformodel~ones(rows(Xsformodel),1);
                       endif;
                       monthindex = monthindex +1;
                    endo; 

                    {origchoice,origICdif,origICweight,Bhatm,criterion}=IC_Investigate(dYapp, Xall, nummodels, Xsformodel, methodstorpt, numobs, numcriteria); 
                     relationchoicepct = zeros(nummethods,5);
                       i = 1;
                          do until i > nummodels;
                             relationchoicepct[.,actualrelationkey[modelnumbers[1,i]]] = relationchoicepct[.,actualrelationkey[modelnumbers[1,i]]] + origICweight[.,i];
                             i = i + 1;
                           endo;

if report_IC;
   " ";"Information criterion values:";
   if rows(methodstorpt) == rows(default_methodstorpt);
     if (methodstorpt == default_methodstorpt);
        "model: (AIC,  AICC,  AICU,  SIC, HQC, HJC, CV)";;
     endif;
   endif;
   modelnumberkey[modelnumbers]~criterion';" ";
endif;


                     "Model chosen by each criterion is shown below:";
                     if rows(methodstorpt) == rows(default_methodstorpt);
                        if (methodstorpt == default_methodstorpt);
                     "            AIC   AICC  AICU  SIC  HQC  HJC  CV";
                        endif;
                    endif;
                     "         ";;modelnumberkey[modelnumbers[.,maxindc(origchoice')],.]';

                     ICevidenceweight = (((modelnumberkey[modelnumbers,.]'))|((origICweight)))';

                     Bhatm = ICevidenceweight[.,(1+sortIC)]~ICevidenceweight[.,1]~Bhatm;   @1 is added to sortIC since the 1st column is modelnumber.!@

                     ICevidenceweight = rev(sortc(ICevidenceweight,(1+sortIC)));        @1 is added to sortIC since the 1st column is modelnumber.@
                   
                     Bhatm = rev(sortc(Bhatm,1)); @sorted on the 1st column in Bhatm, which is connected to the information criterion determined by sortIC above.@

                     Bhatm = Bhatm[.,2:cols(Bhatm)];
     format /rd 6,3;
                     " ";
                     "Information criteria evidence weights:";
                      if rows(methodstorpt) == rows(default_methodstorpt);
                          if (methodstorpt == default_methodstorpt);
                             "model    AIC    AICC    AICU    SIC    HQC   HJC";;
                          endif;
                      endif;
                      ICevidenceweight[.,1:(cols(ICevidenceweight)-CVislast)]; 
/*
"*Number after decimal pt is number of augmentation lags in dY, incl. those in dX if dif relation in model";
"Number before decimal point represents one of following:";*/

"  1= RW, 2= RW drift, 3= Statnry, 4 = Statnry trend, 5 = WN, 6 = WN trend";
"  7 = Diffrel no int, 8 = Diff rel, with int., 9 = Diff GC, no int, 10 = Diff GC with int. ";
" 11 = Crrnt lvl rltn, 12 = Crrnt lvl rltn trend, 13 = Coint no drift, 14 = Coint with drift "; 
"15: dY= b3*Y(-1)  (+ auglags in both dY and DdZ ) + u, 16: like 15 w/ intrcpt"; 

              
                     relationids = {1,2,3,4};
                     " ";
                     "IC evidence weights for various relations:";
                     if rows(methodstorpt) == rows(default_methodstorpt);
                          if (methodstorpt == default_methodstorpt);
                             "relation    AIC    AICC   AICU   SIC   HQC    HJC";;
                          endif;
                     endif;
                     relationids~relationchoicepct[1:6,1:4]';
"*rltn=1 means level relation,  rltn=2 means difference relation, rltn=3 means relation in mixed order of integration, rltn=4 means no relation";
" ";
"Cointegrating vec params: ";;Chat';
"(1st: intercept in cointegrating vector, 2nd: slope in cointegrating vector)";
" ";
"Model   R^2     bhats:";
"                        int        t        Y[t-1]     {DY[t-1]...   } Z[t]   Z[t-1]   DZ[t]  {DZ[t-1]...}         error correction term, followed by dummies for quarters or months (if any)";
                                                                                                                   Bhatm;

If not(CVislast and sortIC == rows(methodstorpt));
     format /rd 3,0;
    "Model Average Bhat (based on information criterion in column";;sortIC;; " in the 'Information criteria evidence weights' table, excluding the model column):";
format /rd 6,3;
"                       ";;sumc(Bhatm[.,3:(cols(Bhatm))].*ICevidenceweight[.,1+sortIC])';                  
                                                              @Again 1 is added to sortIC since the 1st column is modelnumber.@
endif;


output off;
screen on;

/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@@@@@@@        END OF MAIN PROGRAM       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/


/***********************************************
* proc Modelformat
*
* Used in Create_data & Model_choosing procedures
*
* Input: Xcols, Xall
* Output: 
*             X: The variables used in the regression
*             k: The number of parameters to be estimated excluding the variance
*
************************************************/
proc(2) = modelformat(Xcols,Xall);
local X, k;
                    if Xcols == zeros(1,cols(Xcols));
                        X = -999;
                        K = 0;
                    else;
                        X = (delif(Xall',Xcols'.<=0))';
                        k = cols(X);             
                    endif;
 
   retp(X, k);
endp;  



/**********************  PROC VARLAGS  *****************************
**   author: Alan G. Isaac
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
----PROC lag_length
----AUTHOR: Scott Hacker
----ATTRIBUTION: Parts of this code are taken from proc LR_LAG
    written by David Rapach (may 27 1996 version).
----INPUT:      
      Z  - data matrix. Each column is a vector of observations on one
             endogenous variable
      p  - maximum lag length. This should be >= 2
      minlag - minimum lag for consideration
      intercept - 1 = yes, 0 = no
----OUTPUT: aiclag  - Lag length suggested by Akaike info criterion.
                    sbclag. -  Lag length suggested by Schwarz-Bayesian criterion.
                    hqclag - Lag length suggested by Hannon-Quinn criterion.
                    hjiclag - Lag length suggested by Hatemi-J criterion.
----GLOBAL VARIABLES: none
----EXTERNAL PROCEDURES: VARLAGS, by Alan G. Isaac
----NB: none.
************************************************************************/

proc (4) = lag_length (z, p, minlag, intercept);
   local M, Y, ylags, T,i, j, lag_guess,X, Ahat, RES, VARCOV,
            aic, sbc, hqc, hjic, aicmin, aiclag, sbcmin, hjicmin, sbclag, hqcmin, hqclag, hjiclag;
    M = cols(z);                 		@ # endog vars @
      {Y, ylags} = varlags(z,p);
       T=rows(y);
    lag_guess = p;				@ initialization  of lag_guess @
    j = 0;
    do until (lag_guess < minlag);
       If intercept == 1;
          if (lag_guess > 0);
             X = ones (T,1) ~ylags[ . , 1:lag_guess*M];
          else;
             X = ones (T,1);
          endif;
          Ahat = (Y/X)';
          RES = Y - X*Ahat';
          VARCOV = RES'RES/T;
          aic =   ln(det(VARCOV)) + (2/T)*(M*M*lag_guess +M)+ M*(1+ln(2*pi)); 
          sbc = ln(det(VARCOV)) + (1/T)*(M*M*lag_guess+M)*ln(T)+ M*(1+ln(2*pi)); 
          hqc = ln(det(VARCOV)) + (2/T)*(M*M*lag_guess+M)*ln(ln(T))+ M*(1+ln(2*pi));
       else;
         if (lag_guess > 0);
             X = ylags[ . , 1:lag_guess*M];
             Ahat = (Y/X)';
             RES = Y - X*Ahat';
          else;
             RES = Y;
          endif;
          VARCOV = RES'RES/T;
          aic =   ln(det(VARCOV)) + (2/T)*(M*M*lag_guess)+ M*(1+ln(2*pi)); 
          sbc = ln(det(VARCOV)) + (1/T)*(M*M*lag_guess)*ln(T)+ M*(1+ln(2*pi)); 
          hqc = ln(det(VARCOV)) + (2/T)*(M*M*lag_guess)*ln(ln(T))+ M*(1+ln(2*pi));
       endif;
       hjic =sbc + hqc;
       if (lag_guess==p);
          aicmin = aic; 
          aiclag = lag_guess;
          sbcmin = sbc;
          sbclag = lag_guess;
          hqcmin = hqc;
          hqclag = lag_guess;
          hjicmin = hjic;
          hjiclag = lag_guess;
       else;
          if (aic <= aicmin);
             aicmin = aic; 
             aiclag = lag_guess; 
          endif; 
          if (sbc <= sbcmin);
             sbcmin = sbc;
             sbclag = lag_guess;
          endif;
          if (hqc <= hqcmin);
             hqcmin = hqc;
             hqclag = lag_guess;
          endif;
          if (hjic <= hqcmin);
             hjicmin = hqc;
             hjiclag = lag_guess;
          endif;
       endif;
       lag_guess = lag_guess - 1;
   endo;
   retp(aiclag, sbclag, hqclag, hjiclag);
endp;


/*****************************************
*proc IC_Investigate
*
* Inputs: 
* dY, Xall
* nummodels, Xsformodel,
* methodstorpt, numobs, numcriteri
* Outputs:
*        criterionchoice[methodstorpt,.]
***************************************************************************************/
proc(5)=IC_Investigate(dY, Xall,
                                         nummodels, Xsformodel,
					 methodstorpt, numobs, numcriteria);

local criterionchoice, Lrelation, Drelation, choicebycriterion, L2disc, PREDDISC, KLDISC,
         criterion, kmodel, Yest, RESM, ERES, simmodelerror, VARestMG, F,
         RSS, ERESSQRD, FGLSERESSQRD,  KLdiscrepancy, model_guess, X, k,
         leverage, RES, Bhat, INVXTX, INVXTXXT, H, Varest, Varestunbiased,
         Ydifffrommean, SST, Rsquare, Rsquarelevel, AdjRsq, i, j, tvalues, DELRES, SQRDELRES,
         assmnt, CVVARCOV, CVVARCOV2, removevector, Ytrain, Xtrain, CVRES, GDELRES,
         ki, criterionindx, sizecat, L2discforchoice, GCV, MRICPENALTY, choice, choosableintercept,
         V1, V2, RSSDF,XsforDFmodelpl0, BHATDF, ChoiceY, ChoiceZ, tvaluesDF, Htestsindx,
         laglength, alm, alm2, atr, atr2, aeval, abet, aalp, alrpi, aomeg, arestY, arestpY, arestZ, arestpZ, arsqs,
         EngleGranger_choice,EngleGranger_choiceY,
         AuglagYpl1, Auglag, RSSDF1,RSSDF3,RSSDF4,RSSDF6, BhatDF3,BhatDF4,BhatDF6, tvaluesDF3,tvaluesDF4,tvaluesDF6,
         Xmin,ICminlags,RSSmin,tvaluesmin,aiclag,sbclag,hqclag,hjiclag,RSSBIDAR2,RSSUNDAR2,Kadd,
         CLX, tCLX, CDX, tCDX, EKchoice,ResLRelation, BGX,  BGRes, BGstat,Rhoestimate, FGLSY,FGLSX,INVFGLSXTX, FGLSB,FGLSRES, FGLStvalue,
         FGLS, FGLSERES, Tlarge, Oneandtime, Oneandtimebar, alphabar, YZbar, ERSYbeta, ERSZbeta, ERSYlevel, ERSZlevel,
         CointDRES, Cointexpl, CointICminlags,CointRSSmin,Cointtvaluesmin, test1stdifs, trending, laglength1stdifs,AuglagZ, 
         univarchoice,RSSDFZ,tvaluesDFZ,ResDRelation,DWstat,sizecatEK,BhatDFZ,
          dYest, DZ, DYDIFFFROMMEAN ,dYtrain, dYlags, dZlags, dYZ, CointX, Cointresiduals, ICdif,Expmhalfdif,ICweight,Bhatm ;


        choosableintercept = 1;
        criterion = zeros((numcriteria),nummodels);
        ICdif = zeros((numcriteria),nummodels);
        ICweight = zeros((numcriteria),nummodels);
        Kmodel = zeros(1,nummodels);
        criterionchoice = zeros((numcriteria),nummodels);
        choicebycriterion = zeros((numcriteria),1);
        dYest = zeros(numobs,nummodels);
        RESm= zeros(numobs, nummodels);
	VarestMG = zeros(1,nummodels);
        RSS = zeros(1,nummodels);
        Rsquare  = zeros(1,nummodels);
        Bhatm = zeros(nummodels,(cols(Xsformodel)  -  4));

         model_guess = 1; 
                 do until (model_guess > nummodels);

                    Kadd = 0;

                     V1 = {1 0 1};
                     If Xsformodel[model_guess,1:3] == V1;
                          Kadd = 2; @intercept and slope of cointegrating vector increase parameters to be estimated. @
                     endif;
                 
                     {X, K} = Modelformat(Xsformodel[model_guess,5:cols(Xsformodel)], Xall);
                      K = K + Kadd;
 
                    Kmodel[.,model_guess] = K;
                    If X == -999; /*no explanatory variables and no intercept */
                       leverage = zeros(rows(X),1);
                       dYest[.,model_guess]  = zeros(numobs,1);
                       RES = dY; 
                       Bhat = 0;
                    else;
                       INVXTX =Inv(X'*X);
                       INVXTXXT =  INVXTX*X';
                       Bhat = (INVXTXXT*(dY+Xall[.,3]*(Xsformodel[model_guess,7]==-1)))'; @note Xall index 3 is for b3
                                                                                                                                       whereas columns of Xsformodel
 																       starts c1 c2 c3 c4 b1 b1 b3, 
	                                                                                                                               so for Xsformodel b3 is in 7th position@
  		       H =      X*InvXTXXT;
		       leverage = diag(H);
                       dYest[.,model_guess]  = X*Bhat' - Xall[.,3]*(Xsformodel[model_guess,7]==-1) ;
                       RES = dY - dYest[.,model_guess]; 
                   endif;

                   i = 0;
                   j = 1;
                   do until j > (cols(Xsformodel) -  4);
                         if Xsformodel[model_guess,(j+4)]  == 1; 
                         i = i + 1;
                               Bhatm[model_guess,j] = Bhat[1,i];
                         else;
                               Bhatm[model_guess,j] = 0;
                         endif;   
                         j = j +1;
                   endo; 

                    RESm[.,model_guess] = RES;

		    RSS[1,model_guess] = RES'RES;
                    Varest = RSS[.,model_guess] /numobs;
                    Varestunbiased = RSS[.,model_guess] /(numobs-k);
		    VarestMG[1,model_guess] = Varest;
		    dYdifffrommean = dY - meanc(dY);
		    SST = dYdifffrommean'dYdifffrommean;
                   
		    Rsquare[1,model_guess] = (SST-RSS[.,model_guess] )/SST;
                    AdjRsq = 1- (1-Rsquare[1,model_guess])*(numobs-1)/(numobs-(K-1));


/*********************** INFO CRITERIA ******************************************************************/
  
                /*1: original AIC, Akaike (1973)
 		       (k+1) refers to k coeficient estimates plus 1 variance estimate */
                    criterion[1,model_guess] = 
                          numobs*(ln(Varest))+ 2*(k+1);

                /*2: AICC in Burnham and Anderson, p. 51;
                   Also in McQuarrie and Tsai, (2.14)  subtracting (n - k - 2) / (n - k -2) 
                    from right side prior to multipling through by n*/
                    criterion[2,model_guess] = 
                           numobs*(ln(Varest)) + 2*(k+1)*numobs/(numobs - k - 2); 

               /* 3: AICU in McQuarrie and Tsai, equation before (2.18) */
                    criterion[3,model_guess] =
                           numobs*ln(Varestunbiased) + 2*(k+1)*numobs/(numobs - k - 2);

               /*4: original SIC, Schwarz (1978), equivalent in performance to BIC of Akaike (1978)*/
                   criterion[4,model_guess] = 
                          numobs*ln(Varest) + k*ln(numobs);

               /*5: original HQ, Hannan & Quinn (1979), in McQuarrie and Tsai (2.16) */
                    criterion[5,model_guess]  = 
                          numobs*ln(Varest) + 2*k*ln(ln(numobs)); 

               /* 6: Hatemi-J Information Criterion */
		     criterion[6,model_guess] =
                          (numobs*ln(Varest) + k*ln(numobs) +
                           numobs*ln(Varest) + 2*k*ln(ln(numobs)))/2;

                /*7: cross validation*/
      		       DELRES =  RES ./ ((ones(numobs,1) - leverage));
                       SQRDELRES = DELRES'DELRES;
	               criterion[7,model_guess] = SQRDELRES/numobs;            
                                         


												  
/**********************END INFO CRITERIA ********************************************************/

                    model_guess = model_guess + 1;
                 endo;

/****************** Loop through criteria and make choice*********/
   criterionindx=1;

	do until criterionindx > (numcriteria); 

                  choice = minindc((criterion[criterionindx,.])');        
                  criterionchoice[criterionindx,choice] = criterionchoice[criterionindx,choice]+1;

                  ICdif[criterionindx,.]  =  criterion[criterionindx,.]  - criterion[criterionindx,choice];
                  Expmhalfdif = exp(-0.5*ICdif[criterionindx,.]); 
                  ICweight[criterionindx,.] = Expmhalfdif/sumc(Expmhalfdif');  
     
              criterionindx = criterionindx + 1;
       endo; /* on criterionindx */

                  Bhatm = Rsquare'~Bhatm;
   retp(criterionchoice[methodstorpt,.],ICdif[methodstorpt,.],ICweight[methodstorpt,.],bhatm,criterion);
endp;   
