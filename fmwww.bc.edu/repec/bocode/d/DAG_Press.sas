/**********************************************************************************
Author: Roger L. Goodwin
Date: May 25,2008
Program Name: DAG_Press.sas
Program Description: The following program calculated the deleted residual (PRESS) statistic 
                     in regression using SAS. Instead of using the INFLUENCE option in PROC REG, 
                     this program calculates the PRESS statistic by deleting an observation,
                     calculating the residual, then making the final compuation for the 
                     sum of the d_i^2's. The program prints the statistic to the output 
                     window. The results of this program match those of the SAS system.
                     Precision from this program is more accurate since SAS prints integers 
                     only.

                     Assumptions:  1. There is only one dependent variable.
                                   2. The intercept is always part of the model.
                                   3. SAS v9.1 is used.

References:        

                  1. Bowerman, Bruce L. and O'Connell (1990), Richard T., Linear Statistical Models, 
                     an Applied Approach, 2nd edition,  Duxbury Press. 

Modification Date: June 15, 2008
Modified By: Roger L. Goodwin
Modification Code: rog06152008-1
Modification Description: Code did not correctly identify the number of independent variables. Removed the data step
                          for identifying the number of independent variables and replaced it with a DO-WHILE loop.

Modification Date: June 15, 2008
Modified By: Roger L. Goodwin
Modification Code: rog06152008-2
Modification Description: Added an option to print SAS' PROC REG results to the Output Window. The option is is named
                          DEBUG and is assigned the values YES and NO. YES means print the PROC REG results to the Output
                          Window. NO means do not print the PROC REG results to the Output Window.
***********************************************************************************/


options mprint;
/* set up the input library and the input data set */

data mydata; /* hypothetical data */
input rice cotton;
cards;
14.06 5.75
5.26  1.90
3.50  11.70
1.90  2.85
2.16  10.30
1.50  14.00
;

data labor; /* bowerman, o'connell page 507 table 11.5 */
input x1 x2 x3 x4 x5 y;
cards;
15.57 2463 472.92 18.0 4.45 566.52
44.02 2048 1339.75 9.5 6.92 696.82
20.42 3940 620.25 12.8 4.28 1033.15
18.74 6505 568.33 36.7 3.90 1603.62
49.20 5723 1497.60 35.70 5.50 1611.37
44.92 11520 1365.83 24.0 4.60 1613.27
55.48 5779 1687.00 43.3 5.62 1854.17
59.28 5969 1639.92 46.7 5.15 2160.55
94.39 8461 2872.33 78.7 6.18 2305.58
128.02 20106 3655.08 180.5 6.15 3503.93
96.00 13313 2912.00 60.9 5.88 3571.89
131.42 10771 3921.00 103.7 4.88 3741.40
127.21 15543 3865.67 126.8 5.50 4026.52
252.90 36194 7684.10 157.7 7.00 10343.81
409.20 34703 12446.33 169.4 10.78 11732.17
463.70 39204 14098.40 331.4 7.05 15414.94
510.22 86533 15524.00 371.6 6.35 18854.45
;
run;




%macro PRESS(library = c:\2007\, dataset = labor, y = y, x= x1 x2 x3 x4 x5, debug = no);

/* the following macro performs delete an observation jackknife estimation */

%if %trim(&library) ne %then %do; /* make sure the library name is not blank. */

libname in "&library";

data in_put;
set in.&dataset;
obs = _n_;
call symput('n',_n_); /* store the number of observations */
run;
%end; /* of reading the input data set */

%else %do; /* no library name given. use the WORK library. */

data in_put;
set &dataset;
obs = _n_;
call symput('n',_n_); /* store the number of observations */
run;

proc sort data = in_put; by obs; run;

%end; /* of reading the input data set */

/* rog06152008-1: get the number of independent variables */

%let i = 1;
%let temp = a;
%do %while(&temp ne );
  %let temp = %qscan(&x, &i);
  %let i = %eval(&i+1);
%end;


%put *************** number of dependend variables = i = %eval(&i-2);
%let num = %eval(&i);

/* rog06152008-1: end of getting the number of independent variables */

/* end of getting the number of independent variables */


/* model the full data set */

/* rog06152008-2: optional to print SAS' results using the DEBUG option */

%if %upcase(&debug) eq YES %then %do; 
proc reg data = in_put;
model &y = &x/influence;
output out = full p=&y._full;
run;

%end; 

%if %upcase(&debug) eq NO %then %do;

proc reg data = in_put noprint;
model &y = &x/influence;
output out = full p=&y._full;
run;

%end; 

/* rog06152008-2: end of printing SAS' results */

data full;
set full;
obs = _n_;
run;


%do i = 1 %to &n; /* delete an observation and calculate the mean loop. */


data in&i;
set in_put;
    obs = &i.;
	if _n_ eq &i then delete; 
run;



/* end of deleting an observation */

/* model the data with an observation deleted */

proc reg data = in&i outest = reg_out&i. ;
id obs;
model &y = &x/noprint;
run;

/* end of modeling the deleted data set */

/* calculate the PRESS statistic */

data model_data;
set full;
if obs eq &i;
run;

data reg_out&i.;
set reg_out&i.;
obs = &i.;
	%do k = 1 %to %eval(&num-2); 
	     %scan(&x, &k)_beta = %scan(&x, &k);	
	%end; 
run;


data PRESS&i.;
merge reg_out&i. model_data;
by obs;
dsqr_i = (&y - (intercept + %scan(&x, 1)_beta * %scan(&x, 1) %do k = 2 %to %eval(&num-2); 
	     + %scan(&x, &k)_beta * %scan(&x, &k)	%end;) )**2;
run;

%end; /* of looping thru the observations */



/* end of calculating the PRESS statistic */

/* stack the data sets, make the final summation, and print the data */

data PRESS;
set %do k = 1 %to &n; PRESS&k %end; end = eof ;
sum_dsqr + dsqr_i;
if eof;
run;

proc print data = PRESS l;
var sum_dsqr;
title "PRESS Statistic in Regression";
label sum_dsqr = "PRESS";
run;

/* end of stacking the data sets  */

%mend PRESS;

%PRESS(library = , dataset = labor, y = y, x= x2 x3 x5, debug=yes);

*%PRESS(library = , dataset = mydata, y = cotton, x= rice, debug = yes);
