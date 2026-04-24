

discard 
clear 

sysdir set PERSONAL "/Users/juanalamotedegrignonperez/Dropbox (Personal)/ONGOING/STATA/NEXT/timealloc_programs"
global data "/Users/juanalamotedegrignonperez/Dropbox (Personal)/ONGOING/STATA/NEXT/timealloc_programs/data"

cd "/Users/juanalamotedegrignonperez/Dropbox (Personal)/ONGOING/STATA/NEXT/timealloc_programs/data/"



set scheme s1mono

capture log close
capture log using examples_manuscript, replace

/* EXAMPLES INCLUDED IN THE MANUSCRIPT */

* Example 1: Time spent across activities [timealloc] *

*a) Primary activity only
use MTUS_hef, clear
m69tom4 main, gen(main4)
timealloc main4, did(hldid persid id)
sum main4_1-main4_4

*b) Primary and secondary activities 
use MTUS_hef, clear
m69tom4 main, gen(main4)
m69tom4 sec, gen(sec4)
timealloc main4 sec4, did(hldid persid id)
sum main4_1-main4_4

*c) Using the option shares()
use MTUS_hef, clear
m69tom4 main, gen(main4)
m69tom4 sec, gen(sec4)
timealloc main4 sec4, did(hldid persid id) shares(90 10)
sum main4_1-main4_4



* Example 2: Meals timing in Canada [timeallocx] *

use Canada2022, clear 

/* The original timing vars come in a format that looks like a clock but
the : were missing. we just added them, now the variable looks truly like
a clock and it can be transformed with clock2min */

gen str5 clock_start = substr(STARTIME,1,2) + ":" + substr(STARTIME,3,2)
gen str5 clock_end = substr(ENDTIME,1,2) + ":" + substr(ENDTIME,3,2)

clock2min clock_start clock_end, did(PUMFID) dst(4) clockt(hm)

list STARTIME clock_start start in 1/5, nolabel

gen eating=0
replace eating=1 if ACTIVITY==150 // 150 is "Eating or drinking"

timeallocx eating, did(PUMFID) dst(4)

list PUMFID total episodes start1 end1 start_last end_last ///
in 5/8, noobs

/* respondent 5 spends 105 minutes eating, time divided into 2 episodes
breakfast takes place between 07:45 and 08:00 and, the last eating episode 
reported, beggins at 17:00 
respondent 8 does not report any eating or drinking that day. 
this is probably missreporting. */

sum start_last 
whattime 892, dst(04:00) // on average, dinner time beggins at 18:52.


* Example 3: Defining episodes using all diary fields [epigen] *

use Georgia2020, clear

list uid ad4 time activity in 1/5, noobs sepby(uid ad4)

*a) creating the variable TSLOT

bysort uid ad4: gen xtslot=_n
list uid ad4 time xtslot activity in 1/3, noobs sepby(uid ad4)
list uid ad4 time xtslot activity in 25/27, noobs sepby(uid ad4)
gen tslot=xtslot-24 if x>=25
replace tslot=120+x if x<25
tslotcheck, did(uid ad4)

order uid ad4 time tslot tslot 
list uid ad4 time xtslot tslot activity in 1/3, noobs sepby(uid ad4) 

sort uid ad4 tslot
list uid ad4 time tslot activity in 1/3, noobs sepby(uid ad4) 

count 
//the file has 144 x 10 (n of diaries)=1440

*b) running epigen on all diary fields
epigen activity activity2 transport alone partner parent kids ///
households other sleep it forme forkids forothers forhouseholds ///
forwork forsociety forpets, did(uid ad4) dst(4)

//the file has considerably fewer observations now.

list epnum start end time activity in 1/5, noobs sepby(uid ad4)

 

* Example 4: Simplifying an episode file [epigenx] *

use UK2014, clear 

gen start=tid*10-10
gen end=start+eptime

epicheck, did(serial pnum daynum)

fre Enjoy

epigenx Enjoy, did(serial pnum daynum) dst(4)

format Enjoy %20.0f 
list epnum start end Enjoy in 9/13, noobs sepby(serial pnum daynum)



* Example 5: A tempogram for all activities [calgen] *

use mtus_hef, clear 

calgen, did(hldid persid id) dst(4) slotd(10) 

m69tom4 main, gen(mtus4)

tabulate mtus4, gen(x)	
recode x* (1=100)
collapse x*, by(start)

gen l0=0
gen l1=x1 // Personal care
gen l2=l1+x2 // Personal care + Work
gen l3=l2+x3 // Personal care + Work + Unpaid
gen l4=l3+x4 // Personal care + Work + Unpaid + Leisure

set scheme s1mono

twoway ///
    (rarea l0 l1 start, sort fcolor(gs13) lcolor(%0)) ///
    (rarea l1 l2 start, sort fcolor(gs1)  lcolor(%0)) ///
    (rarea l2 l3 start, sort fcolor(gs6)  lcolor(%0)) ///
    (rarea l3 l4 start, sort fcolor(gs15) lcolor(%0)), ///
    xlabel(0(120)1440, valuelabel angle(45)) ///
    ylabel(0(20)100, angle(0)) ///
    xtitle("Time of day") ///
    ytitle("Percent") ///
    title("") ///
    legend(col(1) ring(1) pos(3) order(1 "Personal" 2 "Work" 3 "Unpaid" 4 "Leisure"))
		
graph export "$data/tempo2.pdf", replace 



* Example 6: Error detection [epicheck] *

use mtus_hef, clear
epicheck, did(hldid persid id)

drop if _n==1 // removing the 1st epi of one diary
replace start=start+10 if _n==6 // creating a gap 
replace end=1430 if end==1440 & hldid==7 & persid==3 & id==1 // making one diary not end at min 1440

epicheck, did(hldid persid id)
	


* Example 7: From clock strings to minute-of-day [clock2min] *

use us2020, clear
desc tustarttim tustoptime
list tustarttim tustoptime in 1/5, noobs
clock2min tustarttim tustoptime, did(tucaseid) dst(4) clockt(hms)
order tustarttim start tustoptime end 
list tustarttim start tustoptime end in 1/5, noobs 
list tustarttim start tustoptime end in 1/5, noobs nolabel



* Example 8 Transforming wide-interval data in episode format [epitrans] *
	
use India2019, clear 

rename var05_1 hid // renaming is not necessary but convenient
rename var05_4 pid
rename var05_6 serial
rename var05_7 timefrom
rename var05_8 timeto
rename var05_9 multiple
rename var05_10 simult
rename var05_11 major
rename var05_12 act

*1) 'Looking' at the data to see the wide-interval structure
list serial timefrom timeto multiple simult major act if hid=="10", noobs sepby(hid pid)

/* There are inconsistencies between the variables serial and major. In episodes
with identical start–end, we shoudl expect to find the major activities (major==1) 
to have the lowest serial number, but this was not always the case. I think that 
major should should take precedence. Therefore, we create a blockid for each 
(diary, start, end) group and, within each block, order activities by major 
(using serial only as a tie-breaker when needed). */

destring serial, replace
destring major, replace
sort hid pid serial 
egen blockid=group(hid pid timefrom timeto)
sort blockid major serial

/* Something else we notice when lookig at the data is that the simultaneity 
flag is only flagging one of the episodes within the block of episodes with 
identical start-end. Epitrans needs all of them to be flagged so we propagate 
the simultaneity info across episodes within the block. We also take the opportunity
to recode simult to take values 0/1 as required by epitrans, and we label the 
variable to facilitate inspection. */

destring simult, replace
bysort blockid: egen mean=mean(simult)
replace simult=mean
replace simult=0 if simult==2 
lab define simult 1"yes" 0"No", replace
lab value simult simult 

list serial timefrom timeto simult major act if hid=="10" & serial>=12, noobs sepby(hid pid)

*2) Looking at the data using EPICHECK.ado

/* first we have to convert the timing vars to the minute-of-day format. 
timefrom and timeto are string variables that look like a clock. */

desc timefrom timeto   
list timefrom timeto in 1/5, noobs

clock2min timefrom timeto, did(hid pid) dst(4) clockt(hm) // the diary starts at 4am.

list timefrom timeto start end in 1/5 // the conversion works perfectly.
list timefrom timeto start end in 1/5, nolabel // note the new format.

epicheck, did(hid pid)
/* As expected in data coming from wide-interval diaries, the data has a large number
of fully overlapping epsiodes. Next we show how the flag variable created by epicheck 
looks like. */

list start end major simult act __flag_case in 21/24, noobs 


* 3) Transforming the data

epitrans act, did(hid pid) sim(simult) napi(3)

list hid pid start end __pri __sec if hid=="10" & serial>=12, noobs sepby(hid pid)

/* The formerly fully overlapping pair between 05:30–06:00 is now split into 
two sequential episodes with adjusted boundaries: activity 722 runs 05:30–05:45 
and activity 110 runs 05:45–06:00. The original 30-minute span is preserved 

The simultaneous block from 06:00–08:00 keeps the same total duration, but we 
now represent it as a single episode with a primary and a secondary activity.*/

epicheck, did(hid pid) // to be sure we dealt with all the fully overlapping episodes...

log close 

aaa


capture log using examples_appendix, replace


* EXAMPLES INCLUDED IN THE ONLINE APPENDIX *


* Example 1: Number of times people go out in a day *

use UK2014, clear 
recode WhereWhen (11=1) (else=0), gen(outofhome)
lab define outofhome 0"Out of home" 1"At home", replace
lab value outofhome outofhome 
fre outofhome
gen start=tid*10-10
gen end=start+eptime
sum start end 
epicheck, did(serial pnum daynum)
timealloc outofhome, did(serial pnum daynum)
sum outofhome_0_n 


* Example 2: Solitary screen timing by gender *

use MTUS_hef, clear // this is a calebadr file!!
gen screenalone=0
replace screenalone=1 if ict==1 & alone==1
timeallocx screenalone, did(hldid persid id) dst(4)

twoway (kdensity end_last if sex==1, lwidth(thick)) ///
(kdensity end_last if sex==2, lwidth(thick) lpattern(dash)), ///
 xlabel(0 "04:00" 240 "08:00" 480 "12:00" 720 "16:00" ///
 960 "20:00" 1200 "00:00" 1440 "04:00") ///
 xscale(range(0 1440)) xtitle("Clock time") ///
 ytitle("Density") ylabel(, angle(horizontal)) ///
 legend(order(1 "Men" 2 "Women") pos(11) ring(0))
 
//graph export "$data/ScreenByGender.pdf", replace


* Example 3: A tempogram for a single activity *

use mtus_hef, clear 
calgen , did(hldid persid id) dst(4) slotd(10) 
gen paid=0
replace paid=1 if core==4|core==17
collapse paid, by(start)
replace paid=paid*100
gen l0=0
twoway (rarea l0 paid start, sort fcolor(gs3)), xlabel(0(120)1440, ///
valuelabel angle(45)) ylabel(0(10)40, angle(0)) ///
title("") xtitle("Time of day") ytitle("Percent") legend(off)

graph export "$data/tempo1.pdf", replace

* Example 4: prevalence of evening work. *

use mtus_hef, clear 
calgen, did(hldid persid id) dst(4) slotd(10) 

gen paid=0
replace paid=1 if core==4|core==17

whatmin 18:00, dst(04:00)

gen latewk=0
replace latewk=1 if paid==1 & start>=`r(minute)' 
collapse (sum) latewk, by(hldid persid id)
replace latewk=latewk*10 // to get minutes rather than slots.
recode latewk (0=0) (else=100), gen(lateworkP)

sum lateworkP // percent of the sample doing any work after 6pm.
sum latewk if lateworkP==100 // avg mins of late work for participants only. 


* Example 5: From non-string clocks to minute-of-day *

use Luxemburg2014, clear
desc heuredeb heurefin // start and end are numerical this time.
list heuredeb heurefin in 1/5, noobs 
gen clock_start= string(heuredeb, "%tc")
gen clock_end = string(heurefin, "%tc")
split clock_start, parse(" ")
split clock_end, parse(" ")
list clock_start2 in 1/5, noobs
clock2min clock_start2 clock_end2, did(id_men id_ind id_jour) dst(4) clockt(hms)
order heuredeb clock_start2 start
list heuredeb clock_start2 start in 1/5, noobs 
list heuredeb clock_start2 start in 1/5, noobs nolabel


* Example 6: Transforming wide-interval data in fixed-slots * 

use SouthAfrica2010, clear 

* 1. Visual inspection using list.
lab drop Activity_code // very long labels that hider data listing
list Timeslot Act Sametime Fulltime Timeper Activity_code if UQNO=="5" ///
& PERSONNO==1 & Timeslot>=11 & Timeslot<=17, noobs sepby(UQNO PERSONNO) 
/* Inspecting the data shows it is organized in fixed-length 
time slots of 30 minutes. The variable Sametime indicates whether 
activities within a slot are simultaneous. As expected, the listing 
reveals blocks of fully overlapping episodes.
The variable Act gives the order of the activities within the 
interval. Although the data seems to be already sorted, we sort 
again, just in case. */
sort UQNO PERSONNO Timeslot Act

* 2. Inspection using epicheck.
// we need to have start and end to be able to use epicheck
gen start=(Timeslot-1)*30
gen end=start+30
// we create value labels for start and end
clocklabel 4, name(label4) replace 
lab value start label4
lab value end label4
epicheck, did(UQNO PERSONNO)

* 3. Transforming the data 
//epitrans Activity_code, did(UQNO PERSONNO) sim(Sametime) napi(3)
//the code aboveshould produce error. it was intentional

recode Sametime (2=0)
epitrans Activity_code, did(UQNO PERSONNO) sim(Sametime) napi(5)
epicheck , did(UQNO PERSONNO)


* Example 7: using epitrans with dur() to transform India 1998

use India1998, clear

drop B3_q5_c1 
drop B3_q5_c2

rename Key_hhold hid 
rename Key_membno pid 
rename B3_c0a did
rename B3_c0b hour 
rename B3_c0c serial
destring serial, replace

rename B3_q5_c3 sim 
destring sim, replace
recode sim (1=1) (2=0)
lab define sim 0"No" 1"Yes"
lab value sim sim

rename B3_q5_c5 time
rename B3_q5_c6 location
rename B3_q5_c7 activity

sort hid pid did hour serial

//checking that all durations add up to 1440.
bysort hid pid did: egen x=total(time)
sum x 

//we create start and end.
destring hour, replace
replace hour=hour-1
gen start=hour*60
gen end=start+60
sum start end 

epicheck, did(hid pid did) // note the full overlapps
epitrans activity, did(hid pid did) sim(sim) napi(6) dur(time)
epicheck, did(hid pid did) 


* Example 8: Fixing errors automatically *

use mtus_hef, clear

*we create some errors:
drop if _n==1 // diary start!=0
replace start=start+10 if _n==6 // gap between two episodes
replace end=1430 if end==1440 & hldid==2 & persid==1 & id==1 // diary end!=1440
expand 2 if epnum==8 & hldid==8 & persid==1 & id==1 // fully overlapping episode

epicheck, did(hldid persid id)
epifix main sec, did(hldid persid id) attrib(inout eloc mtrav alone child sppart oad ict)
epicheck, did(hldid persid id)
epifix main sec, did(hldid persid id) fullfix attrib(inout eloc mtrav alone child sppart oad ict)


* Example 9: Converting Between Minute-of-Day and Clock Time (whatmin and whattime) *


clear // no data needs to be loaded

whatmin 06:00, dst(04:00)

whattime 500, dst(06:00)



log close
