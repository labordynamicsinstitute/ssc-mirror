
********************************************************************************
*** DATA SETUP
********************************************************************************

clear
set seed 12345

// 1. Generate years from 1500 to 3000
set obs 1501

gen date = 1500 + _n - 1

// 2. Create Stata internal daily date representing January 1 of each year
// Stata date = number of days since 01jan1960
// So calculate difference between gregorian year Jan 1 and 01jan1960

replace date = mdy(1, 1, date)
format date %td

// 3. Generate Ethiopian date variables (approximate)
// Ethiopian year = Gregorian year - 8 (approx.)
gen eth_year = year(date) - 8

// Ethiopian month: 1 to 13
gen eth_month = ceil(runiform()*13)

// Ethiopian day:
gen eth_day = cond(eth_month < 13, ceil(runiform()*30), ceil(runiform()*6))

// 4. Introduce missing values randomly in Ethiopian date vars (5%)
gen byte miss_flag = (runiform() < 0.05)
replace eth_year = . if miss_flag == 1
replace eth_month = . if miss_flag == 1
replace eth_day = . if miss_flag == 1

// 5. Introduce invalid Ethiopian dates randomly (5%)
gen byte invalid_flag = (runiform() < 0.05)
replace eth_month = 15 if invalid_flag == 1 & eth_month < 13
replace eth_day = 40 if invalid_flag == 1 & eth_month < 13
replace eth_day = 10 if invalid_flag == 1 & eth_month == 13

// 6. Introduce missing values randomly in date (~5%)
gen byte miss_flag_date = (runiform() < 0.05)
replace date = . if miss_flag_date == 1

// 7. Clean up
drop miss_flag invalid_flag miss_flag_date

********************************************************************************
*** TEST
********************************************************************************
	
	to_ethiopian date, eth_year(eyear) eth_month(emonth) eth_day(eday)
	to_gregorian eyear emonth eday, gre_date(new_date)

	count if !missing(date)
	local old_date `r(N)'
	count if !missing(new_date)
	local new_date `r(N)'
	if `old_date' != `new_date' {
		di as error "The number of observation has changed during conversion."
		}
	
	gen test_conv = date == new_date
	summarize test_conv
	if `r(sum)' != _N {
		di as error "Date conversion was not correct."
	}
	
	to_gregorian eth_year eth_month eth_day






