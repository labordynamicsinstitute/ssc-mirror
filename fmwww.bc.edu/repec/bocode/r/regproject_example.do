/* =========================================================
   regproject — Example Do-File
   Dr Noman Arshed, Sunway University
   nouman.arshed@gmail.com
   github.com/nomanarshed/regproject
   =========================================================
   1. Cross-sectional  — 14 named Asian economies
   2. Time series      — sysuse uslifeexp (1900-1999)
   3. Panel data       — 10 countries × 5 periods
   ========================================================= */

version 14
clear all
set more off

/* --------------------------------------------------------- */
/*  MODE 1 — CROSS-SECTIONAL                                 */
/*  14 named Asian economies (synthetic data)                */
/*  Model: fdi = f(gdp_growth, trade, inflation)             */
/* --------------------------------------------------------- */

di as text _n "{hline 60}"
di as text "  EXAMPLE 1 — Cross-sectional  (14 countries)"
di as text "{hline 60}"

clear
set obs 14

/* country names as string label variable */
generate str15 country = ""
replace country = "Malaysia"    in 1
replace country = "Thailand"    in 2
replace country = "Indonesia"   in 3
replace country = "Philippines" in 4
replace country = "Vietnam"     in 5
replace country = "Singapore"   in 6
replace country = "Cambodia"    in 7
replace country = "Myanmar"     in 8
replace country = "Bangladesh"  in 9
replace country = "Pakistan"    in 10
replace country = "SriLanka"    in 11
replace country = "India"       in 12
replace country = "China"       in 13
replace country = "Japan"       in 14

generate gdp_growth = .
replace gdp_growth =  5.8 in 1
replace gdp_growth =  4.2 in 2
replace gdp_growth =  5.1 in 3
replace gdp_growth =  6.2 in 4
replace gdp_growth =  6.8 in 5
replace gdp_growth =  3.4 in 6
replace gdp_growth =  7.0 in 7
replace gdp_growth =  6.5 in 8
replace gdp_growth =  7.3 in 9
replace gdp_growth =  3.8 in 10
replace gdp_growth =  3.2 in 11
replace gdp_growth =  6.9 in 12
replace gdp_growth =  6.6 in 13
replace gdp_growth =  1.0 in 14

generate trade = .
replace trade = 130.2 in 1
replace trade = 122.5 in 2
replace trade =  50.3 in 3
replace trade =  68.4 in 4
replace trade =  93.7 in 5
replace trade = 326.5 in 6
replace trade =  89.2 in 7
replace trade =  40.1 in 8
replace trade =  38.6 in 9
replace trade =  29.4 in 10
replace trade =  54.7 in 11
replace trade =  42.1 in 12
replace trade =  37.8 in 13
replace trade =  32.6 in 14

generate inflation = .
replace inflation = 2.1 in 1
replace inflation = 1.8 in 2
replace inflation = 3.4 in 3
replace inflation = 2.9 in 4
replace inflation = 3.8 in 5
replace inflation = 1.2 in 6
replace inflation = 4.1 in 7
replace inflation = 5.7 in 8
replace inflation = 5.2 in 9
replace inflation = 8.1 in 10
replace inflation = 4.8 in 11
replace inflation = 4.3 in 12
replace inflation = 2.3 in 13
replace inflation = 0.5 in 14

generate fdi = .
replace fdi =  4.8 in 1
replace fdi =  3.6 in 2
replace fdi =  3.1 in 3
replace fdi =  2.7 in 4
replace fdi =  6.1 in 5
replace fdi =  9.8 in 6
replace fdi =  7.3 in 7
replace fdi =  4.2 in 8
replace fdi =  1.8 in 9
replace fdi =  1.1 in 10
replace fdi =  1.6 in 11
replace fdi =  2.8 in 12
replace fdi =  2.9 in 13
replace fdi =  0.8 in 14

label variable gdp_growth  "GDP Growth (%)"
label variable trade       "Trade Openness (% GDP)"
label variable inflation   "Inflation (%)"
label variable fdi         "FDI Inflows (% GDP)"

/* OLS regression */
regress fdi gdp_growth trade inflation

/* order in e(b): gdp_growth  trade  inflation */
regproject gdp_growth,              ///
    ivmins(-2   25   0)             ///
    ivmaxs(10  350  10)             ///
    ymin(0) ymax(12)                ///
    combine saving(cs_example)

/* --------------------------------------------------------- */
/*  MODE 2 — TIME SERIES                                     */
/*  sysuse uslifeexp: US life expectancy 1900–1999           */
/*  Model: le_wmale = f(le_wfemale, le_bmale)               */
/* --------------------------------------------------------- */

di as text _n "{hline 60}"
di as text "  EXAMPLE 2 — Time series  (sysuse uslifeexp)"
di as text "{hline 60}"

sysuse uslifeexp, clear
tsset year

regress le_wmale le_wfemale le_bmale

/* order in e(b): le_wfemale  le_bmale */
regproject le_wfemale,              ///
    ivmin(55) ivmax(95)             ///
    ymin(55)  ymax(85)              ///
    combine saving(ts_example)

/* --------------------------------------------------------- */
/*  MODE 3 — PANEL DATA                                      */
/*  10 countries × 5 biennial periods (2010-2018)           */
/*  Model: poverty = f(gdp, trade, govexp)                   */
/* --------------------------------------------------------- */

di as text _n "{hline 60}"
di as text "  EXAMPLE 3 — Panel data  (10 countries × 5 years)"
di as text "{hline 60}"

clear
set obs 50   /* 10 countries × 5 periods */

generate cid  = ceil(_n / 5)
generate year = 2010 + (mod(_n-1, 5)) * 2

/* country name string variable */
generate str15 cname = ""
replace cname = "Malaysia"    if cid == 1
replace cname = "Thailand"    if cid == 2
replace cname = "Indonesia"   if cid == 3
replace cname = "Philippines" if cid == 4
replace cname = "Vietnam"     if cid == 5
replace cname = "Cambodia"    if cid == 6
replace cname = "Bangladesh"  if cid == 7
replace cname = "Pakistan"    if cid == 8
replace cname = "SriLanka"    if cid == 9
replace cname = "India"       if cid == 10

/* GDP growth — varies by country and time */
generate gdp = .
local g1  "5.8 5.1 6.2 4.4 4.7"
local g2  "7.5 6.5 0.9 3.4 4.1"
local g3  "6.2 6.0 5.0 5.1 5.2"
local g4  "7.6 6.8 6.1 6.9 6.2"
local g5  "6.4 5.2 5.9 6.2 7.1"
local g6  "6.0 7.3 7.1 6.9 7.5"
local g7  "5.6 6.5 6.1 7.1 7.9"
local g8  "3.1 4.4 4.0 5.7 5.5"
local g9  "7.1 6.4 5.0 4.4 3.2"
local g10 "8.5 5.5 7.4 8.2 6.8"

forvalues c = 1/10 {
    local vals "`g`c''"
    forvalues t = 1/5 {
        local v : word `t' of `vals'
        replace gdp = `v' if cid == `c' & year == 2010 + (`t'-1)*2
    }
}

/* trade openness */
generate trade = .
local t1  "130 128 126 120 122"
local t2  " 93  95  89  90  92"
local t3  " 50  52  51  48  49"
local t4  " 68  70  70  73  73"
local t5  " 94  96 100 103 106"
local t6  " 89  95  97 100 103"
local t7  " 39  40  41  43  45"
local t8  " 29  30  30  32  31"
local t9  " 55  56  57  56  54"
local t10 " 42  44  45  46  47"

forvalues c = 1/10 {
    local vals "`t`c''"
    forvalues t = 1/5 {
        local v : word `t' of `vals'
        replace trade = `v' if cid == `c' & year == 2010 + (`t'-1)*2
    }
}

/* government expenditure */
generate govexp = .
local e1  "22.1 23.0 22.8 24.1 23.5"
local e2  "19.4 20.2 21.0 20.8 21.3"
local e3  "16.2 16.8 17.1 18.4 18.8"
local e4  "16.8 17.3 17.9 18.4 18.9"
local e5  "25.4 26.1 26.8 27.3 27.1"
local e6  "18.3 19.1 19.8 20.4 21.0"
local e7  "11.2 11.8 12.3 12.9 13.5"
local e8  "16.5 17.1 17.4 17.9 18.2"
local e9  "16.8 17.3 18.0 18.6 19.1"
local e10 "12.1 12.6 13.1 13.8 14.3"

forvalues c = 1/10 {
    local vals "`e`c''"
    forvalues t = 1/5 {
        local v : word `t' of `vals'
        replace govexp = `v' if cid == `c' & year == 2010 + (`t'-1)*2
    }
}

/* poverty rate — DV */
generate poverty = .
local p1  " 3.8  3.2  2.9  2.6  2.3"
local p2  " 7.8  7.1  7.6  7.3  6.9"
local p3  "11.1 10.5 10.9 10.3  9.7"
local p4  "18.4 17.9 17.1 16.5 16.0"
local p5  "14.5 13.8 13.1 12.4 11.8"
local p6  "17.7 16.9 16.2 15.6 14.9"
local p7  "31.5 30.8 29.9 28.4 26.7"
local p8  "21.9 21.5 22.1 21.0 20.6"
local p9  "11.0 10.3  9.8  9.5  9.2"
local p10 "21.9 20.8 19.6 18.3 17.4"

forvalues c = 1/10 {
    local vals "`p`c''"
    forvalues t = 1/5 {
        local v : word `t' of `vals'
        replace poverty = `v' if cid == `c' & year == 2010 + (`t'-1)*2
    }
}

label variable gdp     "GDP Growth (%)"
label variable trade   "Trade Openness (% GDP)"
label variable govexp  "Govt Expenditure (% GDP)"
label variable poverty "Poverty Rate (%)"

xtset cid year

/* FE panel regression */
xtreg poverty gdp trade govexp, fe

/* order in e(b): gdp  trade  govexp */
regproject gdp,                     ///
    ivmins(-2   25  10)             ///
    ivmaxs(10  150  35)             ///
    ymin(0) ymax(40)                ///
    combine saving(pan_example)

di as text _n "{hline 60}"
di as text "  regproject examples complete."
di as text "  cs_example_*.gph   ts_example_*.gph   pan_example_*.gph"
di as text "{hline 60}"
