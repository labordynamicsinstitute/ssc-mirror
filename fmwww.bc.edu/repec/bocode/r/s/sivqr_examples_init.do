* Example of initial(matname) option for sivqr.ado
*   based on Example 4 of https://www.stata.com/manuals13/rivregress.pdf

* timers 1-3: plug-in bandwidth
* timers 4-6: b(0.01), smaller than plug-in
* timers 1,4: run separately for quantiles 0.1,0.2,...,0.9
* timers 2,5: best approach, start at median, work away into tails using init("e(b)")
* timers 3,6: next-best, start at 0.1 and use init("e(b)") to proceed iteratively to 0.9

* To install:
*net from https://kaplandm.github.io/stata
*net describe sivqr
*net install sivqr
*net get sivqr
version 14.2
which sivqr

webuse nlswork , clear
timer clear
timer on 1
forv q = 10(10)90 {
  sivqr ln_wage c.age##c.age birth_yr grade (tenure = union wks_work msp) , q(`q') reps(0)
}
timer off 1
*
timer on 2
sivqr ln_wage c.age##c.age birth_yr grade (tenure = union wks_work msp) , q(50) reps(0)
matrix init50 = e(b)
forv q = 60(10)90 {
  sivqr ln_wage c.age##c.age birth_yr grade (tenure = union wks_work msp) , q(`q') reps(0) init("e(b)")
}
sivqr ln_wage c.age##c.age birth_yr grade (tenure = union wks_work msp) , q(40) reps(0) init("init50")
forv q = 30(-10)10 {
  sivqr ln_wage c.age##c.age birth_yr grade (tenure = union wks_work msp) , q(`q') reps(0) init("e(b)")
}
timer off 2
*
timer on 3
sivqr ln_wage c.age##c.age birth_yr grade (tenure = union wks_work msp) , q(10) reps(0)
forv q = 20(10)90 {
  sivqr ln_wage c.age##c.age birth_yr grade (tenure = union wks_work msp) , q(`q') reps(0) init("e(b)")
}
timer off 3
*
timer on 4
forv q = 10(10)90 {
  sivqr ln_wage c.age##c.age birth_yr grade (tenure = union wks_work msp) , q(`q') reps(0) b(0.01)
}
timer off 4
*
timer on 5
sivqr ln_wage c.age##c.age birth_yr grade (tenure = union wks_work msp) , q(50) reps(0) b(0.01)
matrix init50 = e(b)
forv q = 60(10)90 {
  sivqr ln_wage c.age##c.age birth_yr grade (tenure = union wks_work msp) , q(`q') reps(0) init("e(b)") b(0.01)
}
sivqr ln_wage c.age##c.age birth_yr grade (tenure = union wks_work msp) , q(40) reps(0) init("init50") b(0.01)
forv q = 30(-10)10 {
  sivqr ln_wage c.age##c.age birth_yr grade (tenure = union wks_work msp) , q(`q') reps(0) init("e(b)") b(0.01)
}
timer off 5
*
timer on 6
sivqr ln_wage c.age##c.age birth_yr grade (tenure = union wks_work msp) , q(10) reps(0) b(0.01)
forv q = 20(10)90 {
  sivqr ln_wage c.age##c.age birth_yr grade (tenure = union wks_work msp) , q(`q') reps(0) init("e(b)") b(0.01)
}
timer off 6
*
timer list

/* on Dave's computer (standard University-issue...circa 2017):
. timer list
   1:     82.89 /        1 =      82.8950
   2:     23.76 /        1 =      23.7580
   3:     69.33 /        1 =      69.3350
   4:    346.14 /        1 =     346.1380
   5:     69.90 /        1 =      69.9000
   6:    209.80 /        1 =     209.8030
*/

* End of file
