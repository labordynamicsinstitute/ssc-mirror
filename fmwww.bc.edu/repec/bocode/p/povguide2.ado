/*-----------------------------------------------------------------------------
POVGUIDE2
by Reginald Hebert (reginald.hebert@yale.edu)
(Update to POVGUIDE, originally written by David Kantor)
*******************************************************************************
17 January 2025		- Updated using 2025 tables
24 January 2024		- Updated help file to amend a typo; added 2024 tables
20 September 2023 	- Code cleanup
20 August 2023 		- Added Alaska and Hawaii tables, plus option for enabling 
				state FIPS as an argument
4 August 2023 		- Added years 2009 through 2023
-------------------------------------------------------------------------------
Original module: 
https://econpapers.repec.org/software/bocbocode/s456935.htm

Data from: 
https://aspe.hhs.gov/topics/poverty-economic-mobility/poverty-guidelines

Data for pre-1983 tables comes from Annual Statistical Supplement to the Social 
Security Bulletin, table 3.E8
e.g. https://www.ssa.gov/policy/docs/statcomps/supplement/2014/supplement14.pdf

For additional details see:
Fisher, Gordon M. "Poverty Guidlines for 1992." Soc. Sec. Bull. 55 (1992): 43.
-----------------------------------------------------------------------------*/



program def povguide2
version 17

syntax , gen(string) famsize(string) year(string) [fips(string)]
/*
We allow the addition of an optional FIPS code to identify Alaska and Hawaii

Omitting this argument generates the standard contiguous 48-states FPG for 
all observations.
*/

capture confirm new var `gen'
if _rc~=0 {
  disp as err "gen must be new var"
  exit 198
}


tempname povtable

#delimit ;
matrix input `povtable' = (
/*      	base  incr */
/*1973*/	2200,  700  \
/*1974*/	2330,  740  \
/*1975*/	2590,  820  \
/*1976*/	2800,  900  \
/*1977*/	2970,  960  \
/*1978*/	3140, 1020  \
/*1979*/	3400, 1100  \
/*1980*/	3790, 1220  \
/*1981*/	4310, 1380  \
/*1982*/	4680, 1540  \  /* 1982 applies to nonfarm only */
/*1983*/	4860, 1680  \
/*1984*/	4980, 1740  \
/*1985*/	5250, 1800  \
/*1986*/	5360, 1880  \
/*1987*/	5500, 1900  \
/*1988*/	5770, 1960  \
/*1989*/	5980, 2040  \
/*1990*/	6280, 2140  \
/*1991*/	6620, 2260  \
/*1992*/	6810, 2380  \
/*1993*/	6970, 2460  \
/*1994*/	7360, 2480  \
/*1995*/	7470, 2560  \
/*1996*/	7740, 2620  \
/*1997*/	7890, 2720  \
/*1998*/	8050, 2800  \
/*1999*/	8240, 2820  \
/*2000*/	8350, 2900  \
/*2001*/	8590, 3020  \
/*2002*/	8860, 3080  \
/*2003*/	8980, 3140  \
/*2004*/	9310, 3180  \
/*2005*/	9570, 3260  \
/*2006*/	9800, 3400  \
/*2007*/	10210, 3480 \
/*2008*/	10400, 3600 \
/*2009*/	10830, 3740 \
/*2010*/	10830, 3740 \
/*2011*/	10890, 3820 \
/*2012*/	11170, 3960 \
/*2013*/	11490, 4020 \
/*2014*/	11670, 4060 \
/*2015*/	11770, 4160 \
/*2016*/	11880, 4140 \
/*2017*/	12060, 4180 \
/*2018*/	12140, 4320 \
/*2019*/	12490, 4420 \
/*2020*/	12760, 4480 \
/*2021*/	12880, 4540 \
/*2022*/	13590, 4720 \
/*2023*/	14850, 5140 \
/*2024*/	15060, 5380 \
/*2025*/	15650, 5500
);
#delimit cr


tempname povtableAK

#delimit ;
matrix input `povtableAK' = (
/*      	 base  incr */
/*1973*/	2200,	700	\
/*1974*/	2330,	740	\
/*1975*/	2590,	820	\
/*1976*/	2800,	900	\
/*1977*/	2970,	960	\
/*1978*/	3140,	1020	\
/*1979*/	3400,	1100	\
/*1980*/	4760,	1520	\
/*1981*/	5410,	1720	\
/*1982*/	5870,	1920	\
/*1983*/	6080,	2100	\
/*1984*/	6240,	2170	\
/*1985*/	6560,	2250	\
/*1986*/	6700,	2350	\
/*1987*/	6860,	2380	\
/*1988*/	7210,	2450	\
/*1989*/	7480,	2550	\
/*1990*/	7840,	2680	\
/*1991*/	8290,	2820	\
/*1992*/	8500,	2980	\
/*1993*/	8700,	3080	\
/*1994*/	9200,	3100	\
/*1995*/	9340,	3200	\
/*1996*/	9660,	3280	\
/*1997*/	9870,	3400	\
/*1998*/	10070,	3500	\
/*1999*/	10320,	3520	\
/*2000*/	10430,	3630	\
/*2001*/	10730,	3780	\
/*2002*/	11080,	3850	\
/*2003*/	11210,	3930	\
/*2004*/	11630,	3980	\
/*2005*/	11950,	4080	\
/*2006*/	12250,	4250	\
/*2007*/	12770,	4350	\
/*2008*/	13000,	4500	\
/*2009*/	13530,	4680	\
/*2010*/	13530,	4680	\
/*2011*/	13600,	4780	\
/*2012*/	13970,	4950	\
/*2013*/	14350,	5030	\
/*2014*/	14580,	5080	\
/*2015*/	14720,	5200	\
/*2016*/	14840,	5180	\
/*2017*/	15060,	5230	\
/*2018*/	15180,	5400	\
/*2019*/	15600,	5530	\
/*2020*/	15950,	5600	\
/*2021*/	16090,	5680	\
/*2022*/	16990,	5900	\
/*2023*/	18210,	6430	\
/*2024*/	18810,  6730	\
/*2025*/	19550,  6880
);
#delimit cr




tempname povtableHI

#delimit ;
matrix input `povtableHI' = (
/*       	base  incr */
/*1973*/	2200,	700	\
/*1974*/	2330,	740	\
/*1975*/	2590,	820	\
/*1976*/	2800,	900	\
/*1977*/	2970,	960	\
/*1978*/	3140,	1020	\
/*1979*/	3400,	1100	\
/*1980*/	4370,	1400	\
/*1981*/	4980,	1580	\
/*1982*/	5390,	1770	\
/*1983*/	5600,	1930	\
/*1984*/	5730,	2000	\
/*1985*/	6040,	2070	\
/*1986*/	6170,	2160	\
/*1987*/	6310,	2190	\
/*1988*/	6650,	2250	\
/*1989*/	6870,	2350	\
/*1990*/	7230,	2460	\
/*1991*/	7610,	2600	\
/*1992*/	7830,	2740	\
/*1993*/	8040,	2820	\
/*1994*/	8470,	2850	\
/*1995*/	8610,	2940	\
/*1996*/	8910,	3010	\
/*1997*/	9070,	3130	\
/*1998*/	9260,	3220	\
/*1999*/	9490,	3240	\
/*2000*/	9590,	3340	\
/*2001*/	9890,	3470	\
/*2002*/	10200,	3540	\
/*2003*/	10330,	3610	\
/*2004*/	10700,	3660	\
/*2005*/	11010,	3750	\
/*2006*/	11270,	3910	\
/*2007*/	11750,	4000	\
/*2008*/	11960,	4140	\
/*2009*/	12460,	4300	\
/*2010*/	12460,	4300	\
/*2011*/	12540,	4390	\
/*2012*/	12860,	4550	\
/*2013*/	13230,	4620	\
/*2014*/	13420,	4670	\
/*2015*/	13550,	4780	\
/*2016*/	13670,	4760	\
/*2017*/	13860,	4810	\
/*2018*/	13960,	4970	\
/*2019*/	14380,	5080	\
/*2020*/	14680,	5150	\
/*2021*/	14820,	5220	\
/*2022*/	15630,	5430	\
/*2023*/	16770,	5910	\
/*2024*/	17310,  6190	\
/*2025*/	17990,  6330
);
#delimit cr


local yearlo "1973"
local yearhi "2025"



tempvar year1
capture gen int `year1' = (`year')
if _rc ~=0 {
    disp in red "invalid expression for year: `year'"
    exit 198
}

capture assert (`year1' >= `yearlo' & `year1' <= `yearhi') | mi(`year1')
if _rc ~=0 {
    disp as error  "Warning: year expression has out-of-bounds values"
    /* Does not exit. Out-of-bounds values yield missing. */
}

capture assert ~mi(`year1')
if _rc ~=0 {
    disp as error  "Warning: year expression yields some missing values"
    /* Does not exit. Yields missing. */
}

tempvar index1 /* index for year */

gen int `index1' = (`year1' - `yearlo') + 1

tempvar fips1
if (mi("`fips'")) local fips "22"
capture gen int `fips1' = (`fips')
if _rc ~=0 {
	disp in red "invalid expression for FIPS code: `fips'"
	exit 198
}

capture assert (`fips1' >= 1 & `fips1' <= 56) | mi(`fips1')
if _rc ~=0 {
    disp as error  "Warning: year expression has out-of-bounds values"
    /* Does not exit. Out-of-bounds values yield missing. */
}

tempvar base incr
gen int `base' = `povtable'[`index1', 1]
gen int `incr' = `povtable'[`index1', 2]
quietly replace `base' = `povtableAK'[`index1', 1] if `fips1' == 2
quietly replace `incr' = `povtableAK'[`index1', 2] if `fips1' == 2
quietly replace `base' = `povtableHI'[`index1', 1] if `fips1' == 15
quietly replace `incr' = `povtableHI'[`index1', 2] if `fips1' == 15




tempvar famsiz1
capture gen int `famsiz1' = (`famsize')
/* Note that that is loaded into an int; will be truncated if non-integer.*/
if _rc ~=0 {
    disp in red "invalid expression for famsize: `famsize'"
    exit 198
}

capture assert `famsiz1' >= 1
if _rc ~=0 {
    disp as error  "Warning: famsize expression has out-of-bounds values (<1)"
    /* Does not exit. */
}

capture assert ~mi(`famsiz1')
if _rc ~=0 {
    disp as error  "Warning: famsize expression yields some missing values"
    /* Does not exit. */
}

/* bottom-code  famsiz1 at 1. */
quietly replace `famsiz1' = 1 if `famsiz1' < 1

gen long `gen' = `base' + (`famsiz1' - 1)* `incr'
quietly compress `gen'
end

