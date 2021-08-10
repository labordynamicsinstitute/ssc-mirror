/**********************************************************************************
Author: Roger L. Goodwin
Date: June 26,2008
Program Name: DAG_CooksD.sas
Program Description: The following program calculated the Cook's D statistic 
                     in regression using SAS. Instead of using the INFLUENCE option in 
                     PROC REG, this program calculates the difference in fits statistic by 
                     deleting an observation, calculating the difference between the predicted 
                     value of the model using all of the observations and the predicted value 
                     of the model using the deleted observation i.

			         The advantages of this program include:

                     1. More precision to the Cook's D statistic.
                     2. A cut-off value and a comment on whether the observation is an outlier.
                     3. An option to change the cut-off value.

                     Assumptions:  1. There is only one dependent variable.
                                   2. The intercept is always part of the model.
                                   3. SAS v9.1 is used.

References:        

                  1. Bowerman, Bruce L. and O'Connell (1990), Richard T., Linear Statistical Models, 
                     an Applied Approach, 2nd edition,  Duxbury Press, page 467. 

***********************************************************************************/


options mprint;
/* set up the input library and the input data set */


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




%macro CooksD(library = c:\2007\, dataset = labor, y = y, x= x1 x2 x3 x4 x5, prob=0.50, debug=no);

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

/* get the number of independent variables */


%let i = 1;
%let temp = a;
%do %while(&temp ne );
   %let temp = %qscan(&x, &i);
   %let i = %eval(&i+1);
%end;

%put **************** number of independent variables = %eval(&i-2);
%let num = %eval(&i); /* number of independent variables */

/* end of getting the number of independent variables */


/* model the full data set */

%if %upcase(&debug) eq YES %then %do;
proc reg data = in_put;
model &y = &x/influence p r ;
output out = full p=&y._full stdp = stdp;
run;
%end;

%if %upcase(&debug) eq NO %then %do;
proc reg data = in_put noprint;
model &y = &x/influence p r ;
output out = full p=&y._full stdp = stdp;
run;
%end;

/* need to store the observation number and the MSE of the predicted values (from PROC REG) */

data full; 
set full;
obs = _n_;
run;

%do i = 1 %to &n; /* delete an observation and model the data loop. */


data in&i;
set in_put;
    obs = &i.;
	if _n_ eq &i then delete; 
run;



/* end of deleting an observation */

/* model the data with an observation deleted */

proc reg data = in&i outest = reg_out&i. noprint;
id obs;
model &y = &x/ p r;
title "model &i";
output out = errors&i. p = pred r = resid;
run;

/* end of modeling the deleted data set */

/* calculate the difference in fits statistic */

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


data Cook&i.;
merge reg_out&i.(in=ina) model_data;
by obs;
	f_isqr = (&y._full -
	         (intercept + %scan(&x, 1)_beta * %scan(&x, 1) %do k = 2 %to %eval(&num-2); 
		     + %scan(&x, &k)_beta * %scan(&x, &k)	%end;) 
	       )**2 ; * full data set minus one observation deleted ;
	cook_stat = f_isqr/stdp**2/(&num-1); * includes the intercept term in the count;
run;




/* end of calculating the difference in fits statistic */

%end; /* of looping thru the observations */

/* stack the data sets and print the data */

data COOK;
set %do k = 1 %to &n; Cook&k. %end; end = eof ;
	cutoff = finv(&prob, &num - 1, &n - (&num - 1));
	if cook_stat > cutoff then comment = "Reject";
	else                       comment = "Accept";
run;




proc print data = COOK l;
format cook_stat best32.;
var cook_stat cutoff comment;
title "Cook's Distance Statistic in Regression";
label cook_stat = "Cook's D";
label cutoff = "Cut-Off Value";
label comment = "Comment";
run;

/* end of stacking the data sets  */

%mend CooksD;

%CooksD(library = , dataset = labor, y = y, x= x2 x3 x5, prob = 0.5, debug=no);

