* Testing the artbin dialogue box, VERSION 2.1 EMZ 16sep2021
* Corresponds to Item 9 in the artbin Stata Journal Software Testing Section
* last test 16/06/2022

clear all
set more off
prog drop _all

db artbin

* Enter into box proportions 0.1 0.2, select local.  Output as required:
* artbin, pr(0.1 0.2) local alpha(0.05) power(0.8) fav

* Enter into box proportions 0.1 0.2, select local and do not round.  Output as required:
* artbin, pr(0.1 0.2) local alpha(0.05) power(0.8) fav noround

* Enter into box proportions 0.1 0.2, select local and do not round, ltfu=0.2.  Output as required:
* artbin, pr(0.1 0.2) ltfu(0.2) local alpha(0.05) power(0.8) fav noround 

* Enter into box 3 proportions 0.1 0.2 0.3, unselect local and do not round, remove ltfu.  Output as required:
* artbin, pr(0.1 0.2 0.3) alpha(0.05) power(0.8) fav

* Enter into box proportions 0.1 0.2 margin(-0.05), select onesided, output as required:
* artbin, pr(0.1 0.2) margin(-0.05) alpha(0.05) power(0.8) fav onesided