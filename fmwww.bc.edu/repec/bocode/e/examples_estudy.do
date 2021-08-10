





use examples_estudy.dta

log using examples_estudy.log, replace

/* Event study on common event date (case: event day clustering) using returns, with (i) two varlists, (ii) 3 event windows and (iii) the BMP test with Multi-Factor Model */
estudy ret_ibm ret_cocacola ret_boa ret_ford ret_boeing ///
(ret_apple ret_netflix ret_google ret_facebook) , ///
datevar(date) evdate(12042016) dateformat(MDY) /// 
modt(MFM) indexlist(ret_mkt ret_smb ret_hml) diagn(BMP) ///
lb1(-3) ub1(0) lb2(0) ub2(5)  lb3(-3) ub3(3) dec(4)

/* Event study on common event date (case: firm-specifc events clustering) using returns, with (i) two varlists, (ii) 3 event windows and (iii) the BMP test with Multi-Factor Model */
gen fs_events = date("12042016", "MDY") if security_names != ""
format %td fs_events

estudy ret_ibm ret_cocacola ret_boa ret_ford ret_boeing ///
(ret_apple ret_netflix ret_google ret_facebook) , ///
datevar(date) evdate(security_names fs_events) dateformat(MDY) /// 
modt(MFM) indexlist(ret_mkt ret_smb ret_hml) diagn(BMP) ///
lb1(-3) ub1(0) lb2(0) ub2(5)  lb3(-3) ub3(3) dec(4)

/* Event study on firm-specific event dates (case: multiple event days) using returns, with (i) two varlists, (ii) 2 event windows and (iii) the Adj. Patell test with Single Index Model  */
estudy ret_ibm-ret_boeing ///
(ret_apple ret_netflix ret_google ret_facebook) , ///
datevar(date) evdate(security_names event_dates) /// 
modt(SIM) indexlist(ret_sp500) diagn(ADJPatell) ///
lb1(-3) ub1(3) lb2(-5) ub2(5) dec(4) showpv

/* Event study on firm-specific event dates (case: multiple event days) using prices, with (i) two varlists, (ii) 2 event windows and (iii) the Adj. Patell test with Single Index Model  */
estudy pr_ibm-pr_boeing ///
(pr_apple pr_netflix pr_google pr_facebook) , ///
datevar(date) evdate(security_names event_dates) /// 
modt(SIM) indexlist(pr_sp500) pri diagn(ADJPatell) ///
lb1(-3) ub1(3) lb2(-5) ub2(5) dec(4) showpv

/* Event study on firm-specific event dates (case: multiple event days) using prices, with (i) two varlists, (ii) 2 event windows, (iii) the KP test and (iv) the tex output with Historical Mean Model  */
estudy pr_ibm-pr_boeing ///
(pr_apple pr_netflix pr_google pr_facebook) , ///
datevar(date) evdate(security_names event_dates) /// 
modt(HMM) indexlist(pr_sp500) pri diagn(KP) ///
lb1(-3) ub1(0) lb2(0) ub2(5) dec(4) tex

/* Event study on firm-specific event dates (case: multiple event days) using returns, with (i) one varlists, (ii) 3 event windows, (iii) suppress option, (iv) the KP test and (v) the graph of CARs in the 20 obs leading to the event and the 20 after it */
estudy ret_ibm-ret_amazon , ///
datevar(date) evdate(security_names event_dates) /// 
modt(HMM) indexlist(ret_mkt ret_smb ret_hml) diagn(KP) supp(ind) ///
lb1(-3) ub1(0) lb2(-20) ub2(20) ///
dec(4) graph(-20 20)
