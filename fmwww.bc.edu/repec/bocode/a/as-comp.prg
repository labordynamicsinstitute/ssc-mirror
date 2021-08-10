/*AS-Comp.prg*/ 	@Author: Abdulnasser Hatemi-J@

Print " This program transforms the data into cumulative positive and negative cumulative components. These components can be used for testing asymmetric causality (see Hatemi-J, 2012) or asymmetric generalized impulses and variance decompositions (see Hatemi-J, 2014). 
References: 1. Hatemi-J A.(2012) Asymmetric Causality Tests with an Application, Empirical Economics, Volume 43, Issue 1, pp 447-456.";
Print " 2. Hatemi-J A.(2014) Asymmetric generalized impulse responses with an application in finance, Economic Modelling, Volume 36, January 2014, Pages 18–22.";
Print " ";
Print " This program code is the copyright of the authors. Applications are allowed only if proper reference and acknowledgments are provided. For non-Commercial applications only.";
Print "No performance guarantee is made. Bug reports are welcome. ";
Print " ";
/*For public, non-commercial use only.
If this code is used for research or in other code, please include proper attribution.
The author makes no guarantee about performance.*/

outwidth 200;
/*output file = mdlslOUTregret.asc reset; 
screen off; */  screen on; 

load YZlevel[]  = ??.txt;		 /* Indicate your data file in txt format. */

Numvars = #;							/* Indicate the number of variables in the VAR model. */
Levnumobs = (rows(YZlevel)/Numvars);
YZlevel = Reshape(YZlevel, Levnumobs, Numvars);

/*  YZlevel=ln(YZlevel); */						/*This line, if activated, will use the origional data in log form. */
/*yzlevel;*/
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

/*"positives";	*/
z=CUMDYZpc;	  		/* This line, if activated, will provide the positive components. */

/*"negatives";				
z=CUMDYZnc;*/   	/* This line , if activated, will provide the negative components. */

z;
 