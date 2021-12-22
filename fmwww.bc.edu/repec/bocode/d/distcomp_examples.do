* Author: David M. Kaplan
* Updated: 05aug2021
* Purpose: examples of distcomp.ado
* 1. NLSW (sysuse dataset)
* 2. Simulated data
* 3. Experiment: Gneezy and List (2006)
* 4. Regression discontinuity: Cattaneo, Frandsen, and Titiunik (2015)
* 5. Many "tie" values appearing in both samples: appears conservative


* To install:
*net from https://kaplandm.github.io/stata
*net describe distcomp
*net install distcomp
*net get distcomp


* Specify directory w/ distcomp.ado (if not already in a standard directory; use command
*    sysdir   to check standard directories.
*cd "C:\Users\kaplandm\code"

*.tex output:  sjlog do distcomp_examples , clear replace

local SAVEFILES 1 // 1=save graphs; 0=do not
set more off
set linesize 67



*********
* 0. Example of poor tail sensitivity of ksmirnov
*********
clear
set obs 69
gen grp = (_n>49)
gen y = (_n<=49)*(_n/50) + (_n>49)*(_n-49)/21
distcomp y , by(grp) alpha(0.01)
replace y = 10^6+_n if _n>63
distcomp y , by(grp) alpha(0.01) p
ksmirnov y , by(grp) exact


*********
* 1. Example from   help distcomp
*********
set scheme sj
sysuse nlsw88 , clear
distcomp wage , by(union) alpha(0.10)
if (`SAVEFILES') capture graph export distcomp_ex_wage.eps , replace
* now focus on only black individuals (race==2)
distcomp wage if race==2 , by(union) noplot
* compare w/ group means
sort union race
by union : su wage
by union : su wage if race==2
* verify that it's "byable"
bysort race : distcomp wage , by(union) p

* Demonstrate graphical options
distcomp wage , by(union) alpha(0.10) groptline0(lcolor(cyan)) groptline1(lcolor(green)) gropttwoway(title(Dave's picture)) groptrej(lwidth(vthick) lcolor(blue) lpattern(solid))
distcomp wage , by(union) alpha(0.10) saving(distcomp.gph , replace)

* Reset scheme
set scheme sj



*********
* 2. Example with simulated data
*********
* Set RNG seed for replication
* (Note: I usually use 112358, but for some reason
*  that makes it seem like a negative treatment effect
*  even when both groups are N(0,1)!)
set seed 1


* Set up DGP, dataset
clear
local nt 50
local nc 50
disp `=`nc'+`nt''
set obs `=`nc'+`nt''
gen treated = 0
replace treated=1 if _n<=`nt'


* Generate outcomes: untreated N(0,1), treated differs
* Case 1: treated~N(0,1) too
gen y1 = rnormal(0,1)
* Case 2: treatment effect above median
gen y2 = y1
replace y2 = y2+2 if treated==1 & y2>0
* Case 3: treated~N(0,sd=3)
gen y3 = y1
replace y3 = 3*y1 if treated==1


* Run distcomp
distcomp y1 , by(treated) p // no actual effect (but alpha probability of error)
if (`SAVEFILES') capture graph export distcomp_ex_y1.eps , replace

distcomp y2 , by(treated) p // effect only above median (0)
if (`SAVEFILES') capture graph export distcomp_ex_y2.eps , replace

distcomp y3 , by(treated) p // bigger in tails, 0 at median
if (`SAVEFILES') capture graph export distcomp_ex_y3.eps , replace
* Smaller significance levels: rejects less, but still some
distcomp y3 , by(treated) alpha(0.05)
distcomp y3 , by(treated) alpha(0.01)




*********
* 3. Example from paper: gift exchange experiment
*********
* Data from Gneezy and List (2006)
// Input data
clear
set obs 23
gen treated = (_n>10)
gen ylib = .
gen yfun = .
replace ylib = 56 if _n== 1
replace ylib = 52 if _n== 2
replace ylib = 46 if _n== 3
replace ylib = 45 if _n== 4
replace ylib = 41 if _n== 5
replace ylib = 38 if _n== 6
replace ylib = 37 if _n== 7
replace ylib = 34 if _n== 8
replace ylib = 32 if _n== 9
replace ylib = 26 if _n==10
*
replace ylib = 75 if _n==11
replace ylib = 64 if _n==12
replace ylib = 63 if _n==13
replace ylib = 58 if _n==14
replace ylib = 54 if _n==15
replace ylib = 47 if _n==16
replace ylib = 42 if _n==17
replace ylib = 37 if _n==18
replace ylib = 25 if _n==19
*
replace yfun =  6 if _n== 1
replace yfun =  6 if _n== 2
replace yfun = 20 if _n== 3
replace yfun = 35 if _n== 4
replace yfun =  6 if _n== 5
replace yfun =  8 if _n== 6
replace yfun =  0 if _n== 7
replace yfun = 41 if _n== 8
replace yfun = 49 if _n== 9
replace yfun = 21 if _n==10
*
replace yfun = 35 if _n==11
replace yfun = 32 if _n==12
replace yfun = 31 if _n==13
replace yfun = 14 if _n==14
replace yfun = 27 if _n==15
replace yfun = 42 if _n==16
replace yfun = 31 if _n==17
replace yfun = 26 if _n==18
replace yfun = 15 if _n==19
replace yfun = 42 if _n==20
replace yfun = 77 if _n==21
replace yfun = 29 if _n==22
replace yfun = 28 if _n==23
// Run distcomp
distcomp ylib , by(treated) alpha(0.05) p noplot
distcomp yfun , by(treated) a(0.05) p noplot
distcomp ylib , by(treated) a(0.10) p
if (`SAVEFILES') capture graph export distcomp_ex_ylib_a10.eps , replace
distcomp yfun , by(treated) a(0.10) p
if (`SAVEFILES') capture graph export distcomp_ex_yfun_a10.eps , replace



*********
* 4. Example from paper: regression discontinuity
*********
* Example from Cattaneo, Frandsen, and Titiunik (2015)
* U.S. Senate incumbency advantage
// Input data
use https://raw.githubusercontent.com/rdpackages/rdlocrand/master/stata/rdlocrand_senate.dta , clear
// Determine bandwidth: 0.75 from balance tests (see original paper, Sec. 5.1)
scalar h = 0.75
// Run distcomp
* Y: demvoteshfor2
* R: demmv
* R0: 0
* D: (R>=R0)
scalar R0 = 0
gen D_incumbent = (demmv>=R0)
distcomp demvoteshfor2 if demmv>=R0-h & demmv<=R0+h , by(D_incumbent) a(0.10) p
if (`SAVEFILES') capture graph export distcomp_ex_demvoteshfor2.eps , replace




*********
* 5. Discrete distribution, tie values appear in both samples
*********
set seed 1
local nt 50
local nc 50
disp `=`nc'+`nt''
local NREP = 100
local ALPHAperc = 10
local p1 = 0.5
local p2 = (`p1'+1)/2
scalar rej1 = 0 // # rejections for y1 (equal distributions)
scalar rej2 = 0 // # rejections for y2 (unequal)
forv irep = 1/`NREP' {
 clear
 qui set obs `=`nc'+`nt''
 qui gen treated = 0
 qui replace treated=1 if _n<=`nt'
 qui gen y1 = rbinomial(5,`p1')
 qui distcomp y1 , by(treated) noplot
 scalar rej1 = rej1 + `=r(rej_gof`ALPHAperc')'
 qui gen y2 = y1
 qui replace y2 = rbinomial(5,`p2') if treated
 qui distcomp y2 , by(treated) noplot
 scalar rej2 = rej2 + `=r(rej_gof`ALPHAperc')'
}
disp rej1 / `NREP' // should be <= ALPHAperc%
disp rej2 / `NREP' // should be as close to 1 as possible

* End of file
