/**********************************************************************************
Author: Roger L. Goodwin
Date: February 8, 2007
Program Name: Estimation.sas
Program Description: The following SAS program calculates the delete-an-observation jackknife mean, total
                     and standard error for a set of given variables.
                     The macro JACKKNIFE has three macro variables: 
                        1. the library name which contains the input file, 
                        2. the data set name with the data, 
                        3. the variable list. 
                    The final output file from the JACKKNIFE macro is the data set called JACK.
                    The final output is also printed to the SAS Output Window, although the user
                    might want to reformat it before printing. This program has been tested on live
                    data and verified using PROC SURVEYMEANS.

                    Should the user wish to modify the program to perform Miller delete-an-observation estimation,
                    simply take natural logarithms of the sample variances before computing the final jackknife
                    variance.

                    Should the user wish to modify the program to perform delete-a-group jackknife estimation,
                    simply integrate your group variable with the observation variable in this code. Sequentially 
                    numbered groups are easier to integrate, but not a requirement.

References:        1. Conover, W. J. (1999), Practicing Non-Parametric Statistics, Third Edition, 
                      John Wiley & Sons, Inc., New York, New York. 
         
                   2. Hajek, Jaroslav, Sidak, Zbynek, and Sen, Pranab K. (1999), Theory of Rank Tests, 
                      Academic Press, San Diego, California. 

                   3. Hollander, Myles and Wolfe, Douglas A. (1999), Nonparametric Statistical Methods, 
                      Second Edition, John Wiley & Sons, Inc., New York, New York. 

                   4. Lehmann, E. L. and D'Abrera, H. J. M. (1975), Nonparametrics, Statistical Methods Based on 
                      Ranks, Holden-Day, Inc., Oakland, California. 

***********************************************************************************/



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


%macro jackknife(library = c:\2007\, dataset = mydata, variables = rice cotton);

/* the following macro performs delete an observation jackknife estimation */

%if %trim(&library) ne %then %do; /* make sure the library name is not blank. */

libname in "&library";

data in_put;
set in.&dataset;
call symput('n',_n_);
run;
%end; /* of reading the input data set */

%else %do; /* no library name given. use the WORK library. */

data in_put;
set &dataset;
call symput('n',_n_);
run;

%end; /* of reading the input data set */

/* calculate the mean of the full data set */


proc means data = in_put noprint;
var &variables;
output out = out_full_means mean=;
run;

data vars;
set out_full_means;
keep &variables;
run;

data _null_;
set sashelp.vcolumn;
if upcase(trim(memname)) eq "VARS";
n+1;
call symput('num',n);
run;

data _null_;
set out_full_means;
	%do i = 1 %to &num;
		call symput("var&i", %scan(&variables, &i));
	%end;
run;




/* end of calculating the mean of the full data set */



%do i = 1 %to &n; /* delete an observation and calculate the mean loop. */


data in&i;
set in_put;
	if _n_ eq &i then delete; 
	if _n_ ne &i then do;
		%do k = 1 %to &num;
			%scan(&variables, &k)_mean = &&var&k * 1.0;
		%end;
	end;

	%do m = 1 %to &num;
		%scan(&variables, &m)_sum + %scan(&variables, &m);
	%end;
run;

/* end of deleting an observation */

/* calculate the mean of each data set */

data in&i;
set in&i end=eof;
keep %do k = 1 %to &num; %scan(&variables, &k)_mean %scan(&variables, &k)_i	%end; ;

if eof;
	%do m = 1 %to &num;
		%scan(&variables, &m)_i = %scan(&variables, &m)_sum/(&n-1);
	%end;

run;

%end; /* of calculating the mean and deleting an observation loop . */

/* stack the data sets and calculate the final jackknife standard error */


data jack;
set %do k = 1 %to &n; in&k %end; ;
%do k=1 %to &num;
	sumsqs_%scan(&variables, &k) = (%scan(&variables, &k)_i - %scan(&variables, &k)_mean)**2;
%end;
run;


data jack;
set jack end = eof;
	%do k = 1 %to &num;
		var_jack_%scan(&variables, &k) +sumsqs_%scan(&variables, &k);
	%end;
	if eof;
	%do k = 1 %to &num;
		var_jack_%scan(&variables, &k) = var_jack_%scan(&variables, &k)*(&n-1)/&n;
		std_jack_%scan(&variables, &k) = sqrt(var_jack_%scan(&variables, &k));
	%end;
	%do j = 1 %to &num;
		mean_%scan(&variables, &j) = &&var&j;
		total_%scan(&variables, &j) = &&var&j*&n;
	%end;
run;
/* end of stacking the data sets and calculating the jackknife standard error */

/* print the JACK data set to the SAS Output Window */

proc print data = jack;
var %do j = 1 %to &num;
		mean_%scan(&variables, &j) 
		total_%scan(&variables, &j) std_jack_%scan(&variables, &j)
	%end; ;
run;

/* end of printing the JACK data set to the SAS Output Window */

%mend jackknife;

%jackknife(library=, dataset= mydata, variables= rice cotton);
