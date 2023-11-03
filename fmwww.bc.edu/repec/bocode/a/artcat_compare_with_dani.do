// Validation code for the STATA program -artcat- (NI trials, sample size) compared to R's -dani- (results are on the odds ratio scale)
// Note: -dani- gives ss calculations (not power) for non-inferiority trials (not superiority)
// Created by Ella Marley-Zagar, 9 July 2020
// Updated 15 July 2020, changed artcat ologit to artcat ologit(AA)
// Updated 22 July 2020, changed -nolist- to -noprobtable- for artcat v 0.6
// Last updated 7 Jan 2021, added in favourable/unfavourable options
// renamed compare_with_dani.do 1jun2022

clear all
set more off

which artcat


********************************************************************************

* p = 99%, margin=1.33, α = 5% (2-sided), β = 20%, OR
artcat, pc(0.01) or(1) margin(1.33) alpha(0.05) power(.8) ologit(AA) noprobtable unfav
* gives 2n sample size:  38994

/* -dani- code in R:

install.packages("devtools")
library(devtools)
devtools::install_github("Matteo21Q/dani")
library(dani)
p0.expected<-0.01 # Expected control event rate
p1.expected<-p0.expected # Same as expected active event rate
NI.marg.OR<-1.33  # Non-inferiority margin on odds ratio scale
r<-1       # Allocation ratio
power<-0.8 # Power
alph<-0.025 # one-sided significance level
sample.size.OR<-sample.size.NI(sig.level=alph, power=power,  p0.expected=p0.expected, p1.expected=p1.expected, NI.margin=NI.marg.OR, r=r, scale="OR")
*/

* gives n sample size of 19497 so 2n = 38994
* same as artcat


********************************************************************************

* p=10%, margin=2, α = 10% (2-sided), β = 10%, OR
artcat, pc(0.1) or(1) margin(2) alpha(0.1) power(.9) ologit(AA) noprobtable unfav
* gives 2n sample size:  794

/* -dani- code in R:

p0.expected<-0.1 # Expected control event rate
p1.expected<-p0.expected # Same as expected active event rate
NI.marg.OR<-2  # Non-inferiority margin on odds ratio scale
r<-1       # Allocation ratio
power<-0.9 # Power
alph<-0.05 # one-sided significance level
sample.size.OR<-sample.size.NI(sig.level=alph, power=power,  p0.expected=p0.expected, p1.expected=p1.expected, NI.margin=NI.marg.OR, r=r, scale="OR")

*/

* gives n sample size of 397 so 2n = 794
* very close to artcat

********************************************************************************

* p=5%, margin=0.5, α = 5% (2-sided), β = 10%, OR
artcat, pc(0.05) or(1) margin(0.5) alpha(0.05) power(.9) ologit(AA) noprobtable fav
* gives 2n sample size: 1842

/* -dani- code in R:

p0.expected<-0.05 # Expected control event rate
p1.expected<-p0.expected # Same as expected active event rate
NI.marg.OR<-0.5  # Non-inferiority margin on odds ratio scale
r<-1       # Allocation ratio
power<-0.9 # Power
alph<-0.025 # one-sided significance level
sample.size.OR<-sample.size.NI(sig.level=alph, power=power,  p0.expected=p0.expected, p1.expected=p1.expected, NI.margin=NI.marg.OR, r=r, scale="OR")

*/

* gives n sample size of 921 so 2n = 1842
* same as artcat


********************************************************************************


artcat, pc(0.04) or(1) margin(1.5) alpha(0.05) power(.8) ologit(AA) noprobtable unfav
* gives 2n sample size: 4974

/* -dani- code in R:

p0.expected<-0.04 # Expected control event rate
p1.expected<-p0.expected # Same as expected active event rate
NI.marg.OR<-1.5  # Non-inferiority margin on odds ratio scale
r<-1       # Allocation ratio
power<-0.8 # Power
alph<-0.025 # one-sided significance level
sample.size.OR<-sample.size.NI(sig.level=alph, power=power,  p0.expected=p0.expected, p1.expected=p1.expected, NI.margin=NI.marg.OR, r=r, scale="OR")

*/

* gives n sample size of 2487 so 2n = 4974
* same as artcat


********************************************************************************


artcat, pc(0.8) or(1) margin(0.05) alpha(0.05) power(.95) ologit(AA) noprobtable fav
* gives 2n sample size: 38

/* -dani- code in R:

p0.expected<-0.8 # Expected control event rate
p1.expected<-p0.expected # Same as expected active event rate
NI.marg.OR<-0.05  # Non-inferiority margin on odds ratio scale
r<-1       # Allocation ratio
power<-0.95 # Power
alph<-0.025 # one-sided significance level
sample.size.OR<-sample.size.NI(sig.level=alph, power=power,  p0.expected=p0.expected, p1.expected=p1.expected, NI.margin=NI.marg.OR, r=r, scale="OR")

*/


* gives n sample size of 19 so 2n = 38
* very close to artcat                                              


