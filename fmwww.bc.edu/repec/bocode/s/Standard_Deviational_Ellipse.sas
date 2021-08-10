/*******************************************
Author:        Roger L. Goodwin
Email:         roger_goodwin@dc-sug.org
SAS File Name: Standard_Deviational_Ellipse.sas
Purpose:       This a GIS progam. This program calculates the statistics that accompany the weighted,
               standard deviational ellipse outlined in Yuill. It also calculates unweigted
               standard deviational ellipses.
Date Created:  December 19, 2009

References:


1. J. Gong, "Clarifying the Standard Deviational Ellipse," Geographical Analysis, Vol. 34, No. 2 
(April 2002), pp. 155-167.

2. J. Lee and D. W. S. Wong, Statistical Analysis with Arc View GIS, John Wiley & Sons, Inc., New York, 2001.

3. D. W. Lefever, "Measuring Geographic Concentration by Means of the Standard Deviational
Ellipse," The American Journal of Sociology, Vol. 32, No. 1. Jul., 1926, pp. 88-94.

4. G. B. Thomas and R. L. Finney, Calculus and Analytic Geometry, Fifth Edition, Addison-Wesley Publishing Company,
Reading, Massachusetts, June, 1981, p. 415.

5. R. S. Yuill, "The Standard Deviational Ellipse: An Updated Tool for Spatial Description," Geografisker Annaler, 
Series B, Human Geography, Vol 53, No. 1, Blackwell Publishing on behalf of the Swedish Society for Anthropology 
and Geography, 1971, pp. 28-39.



Macro Name: wellipse
Input Variables: 

1. Library name --- a permanent library name on a hard disk where the data file resides. 
2. Data file name --- the data file must contain the latitude, longitude, and the weights.
3. Weight variable --- this is the random variable. 
4. Latitude variable --- observed latitude of the random variable.
5. Longitude variable --- observed longitude of the random variable.
6. Debug --- this option is extremely limited. The intercept estimates are correct.
             However, the error terms and other statistics do not match those in the literature.
             To run the debug code, set this option to YES.

Programming Notes:

1. For unweighted data, set the weight variable to blank. A value of 1.0 will automatically be placed on the latitude
   and longitude data.

2. As stated, the debug option is limited. This option will take upper or lower case YES and NO. It will not accept 
   Y or N.

3. The eccentricity calculation can be found in Thomas and Finney. This calculus book is also referenced in the literature.

4. This program was developed using SAS v9.1.

********************************************/


data raw_data; /* sample data file. the "Planted" variable is the weight. */
input COFIPS COUNTY $ latitude longitude Planted;
cards;
1	Adair	37.076403	-85.313622	7800
3	Allen	37.610934	-82.728358	3000
7	Ballard	37.035987	-89.017933	26100
9	Barren	36.967684	-85.848624	15700
11	Bath	38.106816	-83.719914	2600
15	Boone	38.994057	-84.731556	2200
17	Bourbon	38.217055	-84.22788	3800
21	Boyle	37.652603	-84.815078	2300
23	Bracken	38.711702	-84.059029	1500
27	Breckinridge	37.7982	-86.459209	11700
29	Bullitt	37.984211	-85.684578	2200
31	Butler	38.788421	-84.368833	12900
33	Caldwell	37.150102	-87.894245	24400
35	Calloway	36.640277	-88.285042	38300
39	Carlisle	38.312181	-84.027644	23100
41	Carroll	38.674836	-85.064907	800
43	Campbell	38.895189	-84.396254	600
45	Casey	37.315745	-84.898478	4100
47	Christian	36.841059	-87.466397	75200
49	Clark	37.959945	-84.143514	1500
53	Clinton	36.665277	-88.993619	1200
55	Crittenden	38.780098	-84.606196	9000
57	Cumberland	36.980875	-82.98533	1600
59	Daviess	37.730798	-87.102375	56000
61	Edmonson	37.194168	-86.21585	2600
67	Fayette	38.060648	-84.480261	2500
69	Fleming	38.398763	-83.677393	4300
73	Franklin	36.73108	-86.578338	1200
75	Fulton	36.512814	-88.881761	26300
77	Gallatin	38.729507	-84.877639	700
79	Garrard	37.641323	-84.564147	1600
83	Graves	36.688773	-88.710896	60400
85	Grayson	38.332041	-82.945534	7200
87	Green	37.257012	-85.56121	4800
89	Greenup	38.572558	-82.831375	1600
91	Hancock	37.828091	-86.761749	6500
93	Hardin	36.76887	-88.302898	24500
97	Harrison	38.433304	-84.354205	3300
99	Hart	37.31013	-85.848624	4400
101	Henderson	37.842109	-87.583193	63900
103	Henry	38.426838	-85.147936	3500
105	Hickman	36.567659	-89.186603	38800
107	Hopkins	37.315309	-87.579129	27100
111	Jefferson	38.19381	-85.643487	1100
113	Jessamine	37.895573	-84.564147	900
121	Knox	36.926058	-83.889706	800
123	Larue	37.518955	-85.725637	15200
125	Laurel	37.069349	-84.185712	1400
135	Lewis	38.507969	-83.378939	1600
137	Lincoln	37.475126	-84.647912	8600
139	Livingston	37.298601	-84.21464	7000
141	Logan	36.869834	-86.862183	56900
143	Lyon	37.024726	-88.090076	6000
145	McCracken	37.033061	-88.710896	12500
149	McLean	37.564435	-87.261833	34800
151	Madison	37.7143	-84.312126	2500
155	Marion	37.332986	-88.08132	11100
157	Marshall	36.857377	-88.401604	9300
161	Mason	38.61941	-83.889706	5600
163	Meade	37.96015	-86.21585	10700
167	Mercer	37.82586	-84.898478	2600
169	Metcalfe	37.003244	-85.643487	4900
171	Monroe	36.748492	-85.725637	5000
173	Montgomery	38.031458	-83.889706	1600
177	Muhlenberg	37.17725	-87.142289	12100
179	Nelson	37.329117	-87.051391	12500
181	Nicholas	38.376763	-84.059029	1200
183	Ohio	37.510852	-86.822034	24300
185	Oldham	38.356002	-85.478806	4100
191	Pendleton	38.462467	-85.30417	1400
199	Pulaski	37.085351	-84.522219	8800
203	Rockcastle	37.374306	-84.312126	1300
205	Rowan	38.177068	-83.464355	1100
207	Russell	38.505459	-82.69882	4800
209	Scott	38.317236	-84.564147	2200
211	Shelby	38.177808	-85.230841	14300
213	Simpson	36.777201	-86.620794	36100
215	Spencer	38.012317	-85.313622	3200
217	Taylor	37.332884	-85.313622	8200
219	Todd	36.833864	-87.142289	44700
221	Trigg	36.847364	-87.776333	21300
223	Trimble	38.601328	-85.313622	1100
225	Union	38.952494	-84.681051	77300
227	Warren	36.988604	-86.499655	27900
229	Washington	37.751614	-85.147936	3900
231	Wayne	36.757191	-84.856793	5500
233	Webster	37.489219	-87.736961	30800
235	WhitleyCity	36.72281	-84.471059	800
237	Wolfe	37.755087	-83.464355	600
239	Woodford	38.072166	-84.731556	1700
;
run;

/* end of the sample data file */


/* define the macro routine. place a call to the routine at the end of the file. */

%macro wellipse(library = c:\2007\, infile=raw_data, weight=planted, latitude=latitude, longitude=longitude, debug=NO);

%if %trim(&library) ne %then %do; /* make sure the library name is not blank. */

libname in "&library";


data reg_data;
set in.&infile.;
	%if &weight. eq %then %do; /* if no weight set to 1, otherwise, set to the variable */
		weight = 1.0;
	%end;
	%else %do;
		weight = &weight.;
	%end;  /* end of setting weight variable */
	latitude = &latitude.;
	longitude = &longitude.;
run;

%end; /* of reading the input data set */

%else %do; /* no library name given. use the WORK library. */

data reg_data;
set &infile.;
	%if &weight. eq %then %do; /* if no weight set to 1, otherwise, set to the variable */
		weight = 1.0;
	%end;
	%else %do;
		weight = &weight.;
	%end;  /* end of setting weight variable */
	latitude = &latitude.;
	longitude = &longitude.;
run;


%end; /* of reading the input data set */

/* 1. calculate the weighted mean centers for the standard deviational ellipse */

/* run the debug code */

%if %upcase(&debug.) eq YES %then %do;

	proc glm data = reg_data;
	model latitude =;
	weight weight;
	title "Weighted Mean Latitude Under the Standard Deviational Ellipse: intercept estimate";
	output out = lat ;
	run;
	quit;


	proc glm data = reg_data;
	model longitude =;
	weight weight;
	title "Weighted Mean Longitude Under the Standard Deviational Ellipse: intercept estimate";
	output out = long ;
	run;
	quit;

%end; /* of debuging */

/* else do not run the debug code */

%if %upcase(&debug.) ne YES %then %do;

	proc glm data = reg_data noprint;
	model latitude =;
	weight weight;
	title "Weighted Mean Latitude Under the Standard Deviational Ellipse: intercept estimate";
	output out = lat ;
	run;
	quit;


	proc glm data = reg_data noprint;
	model longitude =;
	weight weight;
	title "Weighted Mean Longitude Under the Standard Deviational Ellipse: intercept estimate";
	output out = long ;
	run;
	quit;

%end; /* end of not debuging */


/* 2. calculate the tan(theta), the angle of rotation, under the standard deviational ellipse */

data reg_data; * mean center;
set reg_data;
	wixi = weight*latitude;
	wiyi = weight*longitude;
run;

proc means data = reg_data sum n noprint;
var weight wixi wiyi;
output out = reg_sums sum = w_sum wixi_sum wiyi_sum;
run;

data reg_sums;
set reg_sums;
	mean_lat = wixi_sum / w_sum;
	mean_long = wiyi_sum / w_sum;
	call symput('meanlat', mean_lat);
	call symput('meanlong', mean_long);
run;

%put ************ the weighted mean latitude is &meanlat;
%put ************ the weighted mean longitude is &meanlong;

data reg_data;
set reg_data(drop = wixi wiyi);
	xi_prime_sq_wi = (latitude - &meanlat)**2 * weight;
	yi_prime_sq_wi = (longitude - &meanlong)**2 * weight;
	xiyi_prime_wi = (latitude - &meanlat)*(longitude - &meanlong) * weight;
run;

proc means data = reg_data sum n noprint;
var xi_prime_sq_wi yi_prime_sq_wi xiyi_prime_wi;
output out = std_ellipse sum = x y xy;
run;

data std_ellipse;
set std_ellipse;
	tan_theta1 = -1* (x-y)/(2*xy) + sqrt((x-y)**2 + 4*xy**2)/(2*xy);
	tan_theta2 = -1* (x-y)/(2*xy) - sqrt((x-y)**2 + 4*xy**2)/(2*xy);
	theta1 = atan(tan_theta1)*57.2957795; *convert to degrees and choose the positive angle over theta2;
	theta2 = atan(tan_theta2)*57.2957795; *convert to degrees and choose the positvie angle over theta1;

	if theta1> theta2 then do;
		call symput('atheta', theta1); *major axis angle;
		call symput('itheta', theta2); *minor axis angle;
	end;
	if theta1 le theta2 then do;
		call symput('atheta', theta2); *major axis angle;
		call symput('itheta', theta1); *minor axis angle;
end;

	call symput('x', x);
	call symput('y', y);
	call symput('xy', xy);
	call symput('n', _freq_);
run;

%put ********** the value of the major axis theta is &atheta;
%put ********** the value of the minor axis theta is &itheta;

/* end of calculating the angle of rotation theta */

/* 3. calculate the delta_x and the delta_y */

data reg_data3;
set &infile.;
	%if &weight. eq %then %do; /* if no weight set to 1, otherwise, set to the variable */
		weight = 1.0;
	%end;
	%else %do;
		weight = &weight.;
	%end; /* end of setting weight variable */
	longitude = &longitude.;
	latitude = &latitude.;
	delta_xi = ((longitude - &meanlong)*sin(&atheta./57.2957795) - (latitude - &meanlat)*cos(&atheta./57.2957795))**2 * weight;
	delta_yi = ((longitude - &meanlong)*cos(&itheta./57.2957795) - (latitude - &meanlat)*sin(&itheta./57.2957795))**2 * weight;
run;


proc means data = reg_data3 sum n noprint;
var delta_xi delta_yi weight;
output out = delta sum = error_x error_y sum_w;
run;

data delta;
set delta;
	delta_x = sqrt(error_x/sum_w); *standard errors on the x axis;
	delta_y = sqrt(error_y/sum_w); *standard errors on the y axis;
	call symput('delta_x', delta_x);
	call symput('delta_y', delta_y);
run;


/* 4. Calculate the semi-major axis and the semi-minor axis lenghts. */

data area;
    meanlat = &meanlat.;
	meanlong = &meanlong.;
	delta_x = &delta_x.; 
	delta_y = &delta_y.;
	atheta = &atheta.; *angle of rotation along the major axis;
	itheta = &itheta.; *angle of rotation along the minor axis;
	F = 1/&n*3.141592*sqrt(&x*&y- (&xy)**2); /* area. see Lefever (1926) and Yuill. */
	%if &x >= &y %then %do;
		a = sqrt(&y/&n + 2*(&xy)**2/(&n * (-1 * (&x - &y) + sqrt( (&x-&y )**2 + 4* (&xy)**2 ) )  )); *semi major axis length;
		b = sqrt(&x/&n - 2*(&xy)**2/(&n * (-1 * (&x - &y) + sqrt( (&x-&y )**2 + 4* (&xy)**2 ) )  )); *semi minor axis length;
	%end;
	%if &x < &y %then %do;
		a = sqrt(&x/&n + 2*(&xy)**2/(&n * (-1 * (&y - &x) + sqrt( (&y-&x )**2 + 4* (&xy)**2 ) )  )); *semi minor axis length;
		b = sqrt(&y/&n - 2*(&xy)**2/(&n * (-1 * (&y - &x) + sqrt( (&y-&x )**2 + 4* (&xy)**2 ) )  )); *semi major axis length;
	%end;
	if a >= b then e = sqrt(a**2 - b**2)/a; *calculate the eccentricity;
	if a < b then  e = sqrt(b**2 - a**2)/b;  *calculate the eccentricity;
	area = 3.141592 * a * b;   /* area = pi()*a*b. see Lefever (1926). */
	call symput('area', area); /* save the area check by Lefever */
run;

proc print data = area L;
	label delta_x = "Delta X";
	label delta_y = "Delta Y";
	label atheta = "Angle of Rotation on the Major Axis";
	label itheta = "Angle of Rotation on the Minor Axis";
    label meanlat = "Weighted Mean Latitude";
	label meanlong = "Weighted Mean Longitude";
	label F = "Area";
	label a = "Semi-Major Axis Length";
	label b = "Semi-Minor Axis Length";
	label e = "Eccentricity";
	var meanlat meanlong delta_x delta_y atheta itheta F a b e;
title "Weighted Standard Deviational Ellipse Output Statistics";
run;

%put ************* area check = &area;

%mend wellipse;

/* end of defining the macro routine */

/* set the defaults and call the routine wellipse */
%wellipse(library=, infile=raw_data, weight=planted, latitude=latitude, longitude=longitude, debug = no);
