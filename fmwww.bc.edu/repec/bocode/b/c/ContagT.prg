/* ContagT.PRG */
Print "***********************************************************************************************************************************";
Print "This Gauss program performs Hatemi-J and Hacker (2005) pairwise bootstrap test for contagion and it also gives pairwise bootstrap estimators and bootstrap P-values as suggested by the authors! 
Applied Financial Economics Letters, 1(6)";
Print "OBS!!! Using this program in any format without explicit aknowledgment and relevant reference is not allowed!";
Print " This program code is the copyright of the authors. For non-Commercial applications only.";
/*Print "No performance guarantee is made. Bug reports are welcome. ";*/
Print " ";
Print "***********************************************************************************************************************************";


load w[obs,2] = ?.txt;  		/* Your data file, obs is the number of time periods (observations). The number of variables in the model is 2.*/

rnds =45438;
rndseed rnds;

obslow = ? ; 				/* The number of observation for the period before the crisis.*/
obshigh = ?; 				/* The number of observation for the period after the crisis. Note that obslow +obshigh =total number of observations.*/
obstot = obslow + obshigh;

Y= w[.,1];
X =w[.,2];


D = zeros(obslow,1)|ones(obshigh,1);


rmax = 10000; 		/* The number of pairwise bootstrap simulations.*/


	/* Perform Regular OLS and process that information*/
	Z = ones(obstot,1)~D~X~(X.*D);
        coeff = zeros(rmax,cols(Z));
        InvZTZ= Inv(Z'Z);
	Ahat = InvZTZ*(Z'*Y);
/* "Ahat=";;Ahat; */
        varres = Y - Z*Ahat;
    /*    aii = InvZTZ[4,4];*/
/*        t = Ahat[4,1]/(sqrt((varres'varres/(obstot-4))*aii));*/
         t = Ahat./(sqrt((varres'varres/(obstot-cols(Z)))*diag(InvZTZ)));
/*	Significantlydifffrom0OLS = Significantlydifffrom0OLS + (t>1.96 or t < -1.96); */
/*"t=";;t;;"Sign";;Significantlydifffrom0OLS ;*/
/*        Significantlydifffrom0OLS = Significantlydifffrom0OLS + (cdftc(abs(t),obstot-4)<=0.05);*/
	adjres =varres;
	/* End of OLS and processing of that information*/


        Coeff1 = 0;
 	Coeff2 = 0;
	Coeff3 = 0;

	/* Start of Boostrapping Loop: r counts it */
	r = 1;
	Do until r > rmax;
	  randomnumbers = rndu(1,obstot);
          index = 1+ trunc(obstot*randomnumbers);
          Yboot = Y[index,1];
          Xboot = X[index,1];
	  Dboot = D[index,1];

          Zboot = ones(obstot,1)~Dboot~Xboot~(Xboot.*Dboot);

        /* Ahatboot = (Yboot/Zboot)';*/
	  Ahatboot = (Inv(Zboot'Zboot)*(Zboot'Yboot))';
	  Coeff1 = Coeff1 + Ahatboot[1,1];
	  Coeff2 = Coeff2 + Ahatboot[1,2];
/*	  Coeff3 = Coeff3 + Ahatboot[1,3]; */
	  Coeff[r,1] = Ahatboot[1,1];
	  Coeff[r,2] = Ahatboot[1,2];
	  Coeff[r,3] = Ahatboot[1,3];
	  Coeff[r,4] = Ahatboot[1,4];
/*	Coeff[r,5] = Ahatboot[1,5];  
	  Coeff[r,6] = Ahatboot[1,6];  */      

/*	  Simerr = adjRES[index,1];*/
      
	  r = r + 1;
	Endo;
	/* End of Bootstrapping Loop */



        /*Process Bootstrapping information */

        Sortedcoeff1 = Sortc(Coeff[.,1],1);
        Sortedcoeff2 = Sortc(Coeff[.,2],1);
        Sortedcoeff3 = Sortc(Coeff[.,3],1);
        Sortedcoeff4 = Sortc(Coeff[.,4],1);
  /*  Sortedcoeff5 = Sortc(Coeff[.,5],1);
        Sortedcoeff6 = Sortc(Coeff[.,6],1); */

/*	Significantlydifffrom01 = Significantlydifffrom01+
                                                      ((Sortedcoeff[index2_5pct,1]>0) or (Sortedcoeff[(rmax - index2_5pct),1]<0));*/


  /*print "Sortedcoeffs";;Sortedcoeff~Sortedcoeff2; Significantlydifffrom01;; Significantlydifffrom02; */

	/*End processing of bootstrapping inforamation*/

meansortedcoeff = meanc(sortedcoeff4);

medianc1 = median(sortedcoeff1);
medianc2 = median(sortedcoeff2);
medianc3 = median(sortedcoeff3);
medianc4 = median(sortedcoeff4);
/* medianc5 = median(sortedcoeff5);
medianc6 = median(sortedcoeff6);*/

"OLS estimates=";;Ahat; 
Print "***********************************************************************************************************************************";
Print "************Mean Bootstrap coefficients";

"mean Bootstrap coefficient 1 = ";; Coeff1/rmax;; "median Bootstrap coefficient 1=";; medianc1;
"mean Bootstrap coefficient 2 = ";; Coeff2/rmax;; "median Bootstrap coefficient 2=";; medianc2;
"mean Bootstrap coefficient 3 = ";; Coeff3/rmax;; "median Bootstrap coefficient 3 =";; medianc3;
"mean Bootstrap coefficient 4 = ";; meansortedcoeff ;; "median Bootstrap coefficient 4 =";; medianc4;
/*"mean Bootstrap coefficient 5 = ";; meansortedcoeff ;; "median Bootstrap coefficient 5 =";; medianc5;
"mean Bootstrap coefficient 6 = ";; meansortedcoeff ;; "median Bootstrap coefficient 6 =";; medianc6;*/


Print "***********************************************************************************************************************************";
Print "**********P-value based on empirical distribution";

/*"Sortedcoeff, lowest 2.5% (significant if > 0)";;Sortedcoeff[index2_5pct,1];
"Sortedcoeff, highest 2.5% (significant if < 0)";;Sortedcoeff[(rmax - index2_5pct),1];*/
If medianc1  < 0;
  /* "version 1 bootstrap p-value=";;(2*(rmax - counts(Sortedcoeff,0))/rmax);*/
   "Bootstrap p-value==";;(((rmax - counts(Sortedcoeff1,0)) + counts(Sortedcoeff1,(2*medianc1)) )  /rmax);
else;
  /* "version 1 bootstrap p-value=";;(2*(counts(Sortedcoeff,0))/rmax);*/
   " Bootstrap p-value=";;(((counts(Sortedcoeff1,0)) + rmax - counts(Sortedcoeff1,(2*medianc1)) )  /rmax); /* version 2*/
endif;

If medianc2  < 0;
  /* "version 1 bootstrap p-value=";;(2*(rmax - counts(Sortedcoeff2,0))/rmax);*/
   "Bootstrap p-value==";;(((rmax - counts(Sortedcoeff2,0)) + counts(Sortedcoeff2,(2*medianc2)) )  /rmax);
else;
  /* "version 1 bootstrap p-value=";;(2*(counts(Sortedcoeff2,0))/rmax);*/
   " Bootstrap p-value=";;(((counts(Sortedcoeff2,0)) + rmax - counts(Sortedcoeff2,(2*medianc2)) )  /rmax); /* version 2*/
endif;

If medianc3  < 0;
  /* "version 1 bootstrap p-value=";;(2*(rmax - counts(Sortedcoeff3,0))/rmax);*/
   "Bootstrap p-value==";;(((rmax - counts(Sortedcoeff3,0)) + counts(Sortedcoeff3,(2*medianc3)) )  /rmax);
else;
  /* "version 1 bootstrap p-value=";;(2*(counts(Sortedcoeff3,0))/rmax);*/
   " Bootstrap p-value=";;(((counts(Sortedcoeff3,0)) + rmax - counts(Sortedcoeff3,(2*medianc3)) )  /rmax); /* version 2*/
endif;

If medianc4  < 0;
  /* "version 1 bootstrap p-value=";;(2*(rmax - counts(Sortedcoeff4,0))/rmax);*/
   "Bootstrap p-value==";;(((rmax - counts(Sortedcoeff4,0)) + counts(Sortedcoeff4,(2*medianc4)) )  /rmax);
else;
  /* "version 1 bootstrap p-value=";;(2*(counts(Sortedcoeff4,0))/rmax);*/
   " Bootstrap p-value=";;(((counts(Sortedcoeff4,0)) + rmax - counts(Sortedcoeff4,(2*medianc4)) )  /rmax); /* version 2*/
endif;

/* If medianc5  < 0;
  /* "version 1 bootstrap p-value=";;(2*(rmax - counts(Sortedcoeff5,0))/rmax);*/
   "Bootstrap p-value==";;(((rmax - counts(Sortedcoeff5,0)) + counts(Sortedcoeff5,(2*medianc5)) )  /rmax);
else;
  /* "version 1 bootstrap p-value=";;(2*(counts(Sortedcoeff5,0))/rmax);*/
   " Bootstrap p-value=";;(((counts(Sortedcoeff5,0)) + rmax - counts(Sortedcoeff5,(2*medianc5)) )  /rmax); /* version 2*/
endif;

If medianc6  < 0;
  /* "version 1 bootstrap p-value=";;(2*(rmax - counts(Sortedcoeff6,0))/rmax);*/
   "Bootstrap p-value==";;(((rmax - counts(Sortedcoeff6,0)) + counts(Sortedcoeff6,(2*medianc6)) )  /rmax);
else;
  /* "version 1 bootstrap p-value=";;(2*(counts(Sortedcoeff6,0))/rmax);*/
   " Bootstrap p-value=";;(((counts(Sortedcoeff6,0)) + rmax - counts(Sortedcoeff6,(2*medianc6)) )  /rmax); /* version 2*/      
endif;															 */