* parqit_tour.do
* An intuitive tour of lazy tables, engine-side statistics, richer pipelines,
* reshaping, joins between views, raw SQL and engine settings.
* It is self-contained and creates artificial NLS-style labour-panel data.
* The do-file starts with -clear all-: save any unsaved work before running it.
version 16.0
clear all
set more off
set varabbrev off
set linesize 100

* In GUI Stata, type -parqit menu- once. The menu comments below identify the
* dialog that generates each group of commands in the Review window.

global PARQIT_TOUR_DIR     "`c(tmpdir)'/parqit_ssc_tour"
global PARQIT_TOUR_WORKERS "$PARQIT_TOUR_DIR/nlswork_like.parquet"
global PARQIT_TOUR_WIDE    "$PARQIT_TOUR_DIR/wages_wide.parquet"
global PARQIT_TOUR_EVENTS  "$PARQIT_TOUR_DIR/industry_events.parquet"
global PARQIT_TOUR_RESULT  "$PARQIT_TOUR_DIR/worker_industry_result.parquet"
capture mkdir "$PARQIT_TOUR_DIR"

display as text _newline "PARQIT TOUR: BUILD THE TEACHING FILE"
parqit version
parqit selftest

clear
set obs 2400
generate long   idcode     = ceil(_n / 8)
generate int    year       = 1978 + mod(_n - 1, 8)
generate byte   age        = 18 + mod(idcode, 20) + year - 1978
generate float  tenure     = max(year - 1978 + mod(idcode, 5) - 2, 0)
generate float  ttl_exp    = age - 17 - mod(idcode, 4)
generate byte   hours      = 28 + mod(idcode + year, 19)
generate byte   union      = mod(idcode + year, 4) == 0
generate byte   married    = mod(idcode + year, 3) != 0
generate byte   collgrad   = mod(idcode, 5) == 0
generate byte   race       = 1 + mod(idcode, 3)
generate byte   industry   = 1 + mod(idcode, 10)
generate byte   occupation = 1 + mod(3*idcode + year, 7)
generate double ln_wage    = 1.30 + .026*age + .016*tenure +           ///
    .095*collgrad + .060*union + .002*hours + .008*mod(idcode, 9)
replace ln_wage = . if mod(_n, 41) == 0
replace hours   = . if mod(_n, 73) == 0
replace union   = . if mod(_n, 101) == 0
sort idcode year
isid idcode year

label data "Artificial NLS-style worker panel for the parqit tour"
label variable idcode     "Worker identifier"
label variable year       "Survey year"
label variable ln_wage    "Log hourly wage"
label variable ttl_exp    "Total labour-market experience"
label variable tenure     "Tenure with current employer"
label variable hours      "Usual weekly hours"
label variable union      "Union member"
label variable married    "Married"
label variable collgrad   "College graduate"
label variable race       "Race"
label variable industry   "Industry code"
label variable occupation "Occupation code"
label define yesno 0 "No" 1 "Yes"
label define race_lbl 1 "White" 2 "Black" 3 "Other"
label values union married collgrad yesno
label values race race_lbl
notes _dta: Artificial teaching data; no real people are represented.

* Menu: User > parqit > Collect into memory or save as Parquet...
parqit save "$PARQIT_TOUR_WORKERS", replace data compression(zstd)
clear
display as text "Observations in memory: " _N

* --------------------------------------------------------------------------
* 1. Explore first, without loading the panel
* Menu: User > parqit > Read Parquet data (lazy view or into memory)...
parqit use using "$PARQIT_TOUR_WORKERS", name(workers)

* Menu: User > parqit > Describe and explore data...
parqit describe
parqit ds
parqit lookfor wage experience
parqit head 6
parqit count
parqit count if missing(ln_wage)
parqit list idcode year age ln_wage union in 1/8
parqit codebook ln_wage hours union race
parqit misstable ln_wage hours union
parqit misstable patterns ln_wage hours union
parqit levelsof industry
parqit distinct idcode year, joint
parqit duplicates report idcode year

* Menu: User > parqit > Summary statistics, tables, and correlations...
parqit summarize ln_wage age tenure hours
parqit summarize ln_wage, detail
parqit tabulate race
parqit tabulate union collgrad, row col
parqit tabstat ln_wage age tenure, statistics(n mean sd p25 p50 p75)
parqit tabstat ln_wage, statistics(n mean sd p50) by(race)
parqit correlate ln_wage age tenure ttl_exp
parqit pwcorr ln_wage age tenure ttl_exp, obs sig

* The bins are computed by the engine; only the bin table reaches Stata.
* In GUI work, omit -nodraw- to display the graph.
parqit histogram ln_wage, bins(20) nodraw
return list

* Comparisons with missing values follow SQL by default, so a missing hours
* value is excluded by hours > 40. Stata treats missing as larger than any
* number; switch to that rule when a do-file written for Stata relies on it.
* Menu: User > parqit > Views, SQL, and engine settings...
parqit count if hours > 40
parqit set statamissing on
parqit count if hours > 40
parqit set statamissing off

* Every command above returned bounded output. No panel was loaded into Stata.
display as text "Observations in memory: " _N
assert _N == 0

* --------------------------------------------------------------------------
* 2. Build a richer lazy pipeline
* Menu: User > parqit > Keep or drop observations, or draw a sample...
parqit keep if inrange(age, 25, 45) & !missing(ln_wage, hours)

* Menu: User > parqit > Keep, drop, order, sort, or rename variables...
parqit keep idcode year age tenure ttl_exp hours ln_wage union married     ///
    collgrad race industry occupation
parqit drop occupation
parqit rename ttl_exp experience

* Menu: User > parqit > Create or change variables...
parqit gen double wage = exp(ln_wage)
parqit gen double hourly_wage = wage / hours
parqit egen double person_mean = mean(ln_wage), by(idcode)
parqit gen double within_person = ln_wage - person_mean
parqit replace hourly_wage = . if hours <= 0
parqit order idcode year ln_wage wage hourly_wage within_person
parqit sort idcode year

* Menu: User > parqit > Views, SQL, and engine settings...
* show prints the single query (-parqit explain- would print the engine's
* execution plan). The plan still has not replaced Stata's data.
parqit show
parqit count
parqit list idcode year ln_wage wage within_person in 1/6

* Menu: User > parqit > Collect into memory or save as Parquet...
parqit collect, clear
list idcode year ln_wage person_mean within_person in 1/8, noobs
parqit close

* --------------------------------------------------------------------------
* 3. Statistical operators and reshaping inside a lazy transformation
* Menu: User > parqit > Collapse, contract, pivot table, or reshape...
parqit use using "$PARQIT_TOUR_WORKERS"
parqit keep if !missing(ln_wage, union)
parqit collapse (mean) mean_lnwage=ln_wage                             ///
    (sd) sd_lnwage=ln_wage (p50) median_lnwage=ln_wage                ///
    (count) n=ln_wage, by(year union)
parqit sort year union
parqit collect, clear
list, sepby(year) noobs
parqit close

* A pivot performs the aggregation and the wide reshape as one lazy verb.
parqit use using "$PARQIT_TOUR_WORKERS"
parqit keep if !missing(ln_wage, union)
parqit pivot (mean) mean_lnwage=ln_wage (count) n=ln_wage,             ///
    rows(year) cols(union)
parqit collect, clear
list, noobs
parqit close

* Contract is the lazy equivalent of a frequency dataset.
parqit use using "$PARQIT_TOUR_WORKERS"
parqit contract year race, freq(workers)
parqit collect, clear
list in 1/10, noobs
parqit close

* reshape converts between wide and long without loading either shape:
* four years of wages go wide straight to disk, then come back long.
parqit use using "$PARQIT_TOUR_WORKERS"
parqit keep if inrange(year, 1978, 1981)
parqit keep idcode year ln_wage
parqit reshape wide ln_wage, i(idcode) j(year)
parqit save "$PARQIT_TOUR_WIDE", replace compression(zstd)
parqit close
parqit describe "$PARQIT_TOUR_WIDE"

parqit use using "$PARQIT_TOUR_WIDE"
parqit reshape long ln_wage, i(idcode) j(year)
parqit count
assert r(N) == 1200
parqit collect, clear
list in 1/8, sepby(idcode) noobs
parqit close

* --------------------------------------------------------------------------
* 4. Multiple lazy tables: derive a lookup view and join it to another view
* No intermediate table is loaded into Stata or written to disk.
* Menu: User > parqit > Read Parquet data (lazy view or into memory)...
parqit use using "$PARQIT_TOUR_WORKERS", name(analysis)
parqit keep if year >= 1982 & !missing(ln_wage)
parqit keep idcode year age tenure ln_wage union collgrad industry

parqit use using "$PARQIT_TOUR_WORKERS", name(industry_stats)
parqit keep if !missing(ln_wage)
parqit collapse (mean) industry_mean=ln_wage                           ///
    (p50) industry_median=ln_wage (count) industry_n=ln_wage,          ///
    by(industry)

* Menu: User > parqit > Views, SQL, and engine settings...
parqit views
parqit view analysis

* Menu: User > parqit > Combine datasets (merge, append, joinby)...
parqit merge m:1 industry using view:industry_stats, keep(match)       ///
    keepusing(industry_mean industry_median industry_n) nogenerate

* Menu: User > parqit > Create or change variables...
parqit gen double industry_premium = ln_wage - industry_mean
parqit sort industry idcode year

* Menu: User > parqit > Collect into memory or save as Parquet...
* This materialises the joined plan directly to Parquet, not to Stata memory.
parqit save "$PARQIT_TOUR_RESULT", replace compression(zstd)
parqit close _all
parqit describe "$PARQIT_TOUR_RESULT"

* --------------------------------------------------------------------------
* 5. joinby: all pairwise combinations within groups of key variables
* A small event file with two events per industry, written from memory.
clear
set obs 20
generate byte  industry   = 1 + mod(_n - 1, 10)
generate int   event_year = cond(_n <= 10, 1982, 1985)
generate str12 event      = cond(_n <= 10, "Minimum wage", "Trade reform")
label variable event_year "Year of the industry event"
parqit save "$PARQIT_TOUR_EVENTS", replace data compression(zstd)
clear

* Menu: User > parqit > Combine datasets (merge, append, joinby)...
parqit use using "$PARQIT_TOUR_WORKERS"
parqit keep if year == 1985
parqit keep idcode industry ln_wage
parqit joinby industry using "$PARQIT_TOUR_EVENTS"
parqit count
parqit sort idcode event_year
parqit collect, clear
list in 1/6, sepby(idcode) noobs
parqit close

* --------------------------------------------------------------------------
* 6. Escape hatches and engine settings
* Menu: User > parqit > Views, SQL, and engine settings...
* query appends a raw DuckDB clause to the current pipeline: here it keeps
* each worker's first observed year.
parqit use using "$PARQIT_TOUR_WORKERS"
parqit sort idcode year
parqit query "qualify row_number() over (partition by idcode order by year) = 1"
parqit count
parqit list idcode year age in 1/5
parqit close

* sql opens a lazy view over any DuckDB query; a Parquet file is a table.
parqit sql "select industry, avg(ln_wage) as mean_lnwage, count(*) as n from read_parquet('$PARQIT_TOUR_WORKERS') group by industry order by industry"
parqit head 10
parqit collect, clear
parqit close

* Engine settings for shared servers and HPC nodes: a memory ceiling, the
* thread count and the spill directory. They last for the plugin session;
* -discard- resets them.
parqit set memory_limit 2GB
parqit set threads 2
parqit set tempdir "$PARQIT_TOUR_DIR"

* --------------------------------------------------------------------------
* 7. Read only a small final result into memory when ordinary Stata work is next
* Menu: User > parqit > Read Parquet data (lazy view or into memory)...
parqit use idcode year ln_wage industry_mean industry_premium           ///
    using "$PARQIT_TOUR_RESULT", clear
summarize industry_premium
list in 1/8, noobs

display as result _newline "parqit_tour.do complete"
display as text "The source and final result are in $PARQIT_TOUR_DIR"
display as text "Core habit: explore first, build one lazy plan, materialise last."
