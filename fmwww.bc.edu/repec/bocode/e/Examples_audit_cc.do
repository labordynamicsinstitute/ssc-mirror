*** Examples for audit_cc

use auditdata, clear


* example 1
audit_cc case, groupid(matchgrp) id(woman_id) caseddiag(case_ddiag) casedob(case_dbirth) ///
  scrdate(testdate) res(testresult) agec(25 50 65) tlc(0 5 10)
	 	 
audit_cc case if case_age<65, groupid(matchgrp) id(woman_id) caseddiag(case_ddiag) ///
  casedob(case_dbirth) scrdate(testdate) res(testresult) tlc(0 5 10)
  
  
* example 2
set showbaselevels on
audit_cc case if case_age<50, groupid(matchgrp) id(woman_id) caseddiag(case_ddiag) casedob(case_dbirth)  ///
  scrdate(testdate) res(testresult) anythr(9) noheader sav(myresults, replace)
  
audit_cc case if case_age<50, groupid(matchgrp) id(woman_id) caseddiag(case_ddiag) casedob(case_dbirth) ///
  scrdate(testdate) res(testresult) anythr(9) noheader sav(myresults, replace) data(mydata, replace)

use mydata, clear
clogit Case_status i.Time_since_last_test if agegroup==1, group(matchgrp) or
