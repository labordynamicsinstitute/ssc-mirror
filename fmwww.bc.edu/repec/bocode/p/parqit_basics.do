* parqit_basics.do
* A first, self-contained course in reading, writing and lazy Parquet work.
* It creates a small artificial labour panel with familiar NLS-style variables.
* All files are written under Stata's temporary directory.
* The do-file starts with -clear all-: save any unsaved work before running it.
version 16.0
clear all
set more off
set varabbrev off
set linesize 100

* In GUI Stata, type -parqit menu- once. Each block below names the matching
* User > parqit dialog. A dialog writes the same command to the Results and
* Review windows, so point-and-click and scripted work leave the same trail.

global PARQIT_EXAMPLE_DIR "`c(tmpdir)'/parqit_ssc_examples"
global PARQIT_WORKERS     "$PARQIT_EXAMPLE_DIR/nlswork_like.parquet"
global PARQIT_INDUSTRIES  "$PARQIT_EXAMPLE_DIR/industries.parquet"
global PARQIT_EARLY       "$PARQIT_EXAMPLE_DIR/workers_early.parquet"
global PARQIT_LATE        "$PARQIT_EXAMPLE_DIR/workers_late.parquet"
global PARQIT_SELECTED    "$PARQIT_EXAMPLE_DIR/selected_workers.parquet"
global PARQIT_BY_YEAR     "$PARQIT_EXAMPLE_DIR/selected_by_year"
global PARQIT_CSV         "$PARQIT_EXAMPLE_DIR/nlswork_like.csv"
global PARQIT_FROM_CSV    "$PARQIT_EXAMPLE_DIR/nlswork_from_csv.parquet"
capture mkdir "$PARQIT_EXAMPLE_DIR"

display as text _newline "PARQIT BASICS: CHECK THE INSTALLATION"
parqit version
parqit selftest

* --------------------------------------------------------------------------
* 1. Create an NLS-style worker panel and write the data in memory to Parquet
* Menu: User > parqit > Collect into memory or save as Parquet...
* Select "Write the pipeline result to Parquet ... (save)", tick "Write the
* dataset in memory instead of the view (data)" and pick zstd as Compression.
clear
set obs 1440
generate long   idcode     = ceil(_n / 6)
generate int    year       = 1980 + mod(_n - 1, 6)
generate byte   age        = 18 + mod(idcode, 18) + year - 1980
generate float  tenure     = max(year - 1980 + mod(idcode, 4) - 1, 0)
generate float  ttl_exp    = age - 17 - mod(idcode, 3)
generate byte   hours      = 30 + mod(idcode + year, 16)
generate byte   union      = mod(idcode + year, 4) == 0
generate byte   married    = mod(idcode + year, 3) != 0
generate byte   collgrad   = mod(idcode, 5) == 0
generate byte   race       = 1 + mod(idcode, 3)
generate byte   industry   = 1 + mod(idcode, 8)
generate byte   occupation = 1 + mod(2*idcode + year, 6)
generate double ln_wage    = 1.35 + .025*age + .015*tenure +          ///
    .090*collgrad + .055*union + .002*hours + .010*mod(idcode, 7)
replace ln_wage = . if mod(_n, 47) == 0
replace hours   = . if mod(_n, 89) == 0
replace union   = . if mod(_n, 113) == 0
sort idcode year
isid idcode year

label data "Artificial NLS-style worker panel for the parqit examples"
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

parqit save "$PARQIT_WORKERS", replace data compression(zstd)

* --------------------------------------------------------------------------
* 2. Inspect a file and, when it is small enough, read it eagerly into Stata
* Menu: User > parqit > Read Parquet data (lazy view or into memory)...
* The Describe button runs -parqit describe- on the file named in the dialog.
parqit path "$PARQIT_WORKERS"
parqit describe "$PARQIT_WORKERS"
parqit glimpse "$PARQIT_WORKERS"
clear
parqit use "$PARQIT_WORKERS", clear
describe
list idcode year age ln_wage union in 1/6, noobs

* Values and Stata metadata make the round trip with the Parquet file.
assert "`: variable label ln_wage'" == "Log hourly wage"
assert "`: value label union'" == "yesno"

* --------------------------------------------------------------------------
* 3. Open a lazy view: the source stays on disk and memory stays untouched
* Menu: User > parqit > Read Parquet data (lazy view or into memory)...
* Leave "Read the data into memory now ... (clear)" unticked: a view opens.
clear
set obs 1
generate str40 memory_note = "This dataset remains until collect"

parqit use using "$PARQIT_WORKERS"

* Menu: User > parqit > Describe and explore data...
parqit describe
parqit head 5
parqit count

* Menu: User > parqit > Summary statistics, tables, and correlations...
parqit summarize ln_wage hours

* These commands queried the view; they did not replace the dataset in memory.
assert _N == 1
assert memory_note[1] == "This dataset remains until collect"

* Build a plan using Stata-flavoured verbs. Nothing runs yet: each verb adds
* one stage to a single query, so the same script scales to files far larger
* than memory.
* Menu: User > parqit > Keep or drop observations, or draw a sample...
parqit keep if year >= 1983 & !missing(ln_wage)

* Menu: User > parqit > Keep, drop, order, sort, or rename variables...
parqit keep idcode year age tenure hours ln_wage union collgrad industry

* Menu: User > parqit > Create or change variables...
parqit gen double wage = exp(ln_wage)
parqit gen double hourly_wage = wage / hours
parqit sort idcode year

* Menu: User > parqit > Views, SQL, and engine settings...
* show prints the single query the plan compiles to.
parqit show

* Menu: User > parqit > Collect into memory or save as Parquet...
* Only now does the result replace Stata's current dataset.
parqit collect, clear
list idcode year wage hourly_wage in 1/6, noobs
parqit close

* A first look at a large file: prototype on a reproducible engine-side sample
* (a percentage by default, a number of rows with the count option).
* Menu: User > parqit > Keep or drop observations, or draw a sample...
parqit use using "$PARQIT_WORKERS"
parqit sample 10, seed(20260825)
parqit count
parqit collect, clear
summarize ln_wage hours
parqit close

* --------------------------------------------------------------------------
* 4. Run the same kind of plan from Parquet straight back to Parquet
* The selected result never needs to enter Stata's memory.
* Menu: User > parqit > Collect into memory or save as Parquet...
parqit use using "$PARQIT_WORKERS"
parqit keep if year >= 1983 & !missing(ln_wage)
parqit keep idcode year age tenure hours ln_wage union collgrad industry
parqit gen double wage = exp(ln_wage)
parqit save "$PARQIT_SELECTED", replace compression(zstd)
parqit close
parqit describe "$PARQIT_SELECTED"

* partition_by() writes a Hive directory tree (one subdirectory per value),
* which the same commands read back as one table.
parqit use using "$PARQIT_SELECTED"
parqit save "$PARQIT_BY_YEAR", replace partition_by(year)
parqit close
parqit use using "$PARQIT_BY_YEAR"
parqit describe
parqit count
parqit close

* --------------------------------------------------------------------------
* 5. Combine files: lazy merge and append, many files as one table, and the
*    native route when the data are already in memory
* First create a tiny industry lookup in memory and write it to Parquet.
clear
set obs 8
generate byte industry = _n
generate str18 sector = cond(inrange(industry, 1, 2), "Manufacturing",  ///
    cond(inrange(industry, 3, 4), "Trade",                             ///
    cond(inrange(industry, 5, 6), "Services", "Public and other")))
generate double productivity = 90 + 7*industry
label variable sector "Broad industry group"
label variable productivity "Industry productivity index"
parqit save "$PARQIT_INDUSTRIES", replace data compression(zstd)

* Menu: User > parqit > Combine datasets (merge, append, joinby)...
parqit use using "$PARQIT_SELECTED"
parqit merge m:1 industry using "$PARQIT_INDUSTRIES",                 ///
    keep(match) keepusing(sector productivity) nogenerate
parqit collect, clear
list idcode year industry sector productivity in 1/8, noobs
parqit close

* Split one source into two disk results, then append them as one lazy table.
parqit use using "$PARQIT_WORKERS"
parqit keep if year <= 1982
parqit save "$PARQIT_EARLY", replace compression(zstd)
parqit close

parqit use using "$PARQIT_WORKERS"
parqit keep if year >= 1983
parqit save "$PARQIT_LATE", replace compression(zstd)
parqit close

parqit use using "$PARQIT_EARLY"
parqit append using "$PARQIT_LATE"
parqit count
assert r(N) == 1440
parqit close _all

* Many files, one table: a glob (or a Hive directory) opens as a single view,
* so a dataset stored as hundreds of Parquet files needs no append at all.
parqit use using "$PARQIT_EXAMPLE_DIR/workers_*.parquet"
parqit count
assert r(N) == 1440
parqit close

* When the data are already in memory and the lookup lives on disk, keep the
* data put: mergein and appendin run Stata's native merge and append against
* a file that parqit reads, taking only the columns you ask for.
* Menu: User > parqit > Combine datasets (merge, append, joinby)...
parqit use "$PARQIT_EARLY", clear
parqit mergein m:1 industry using "$PARQIT_INDUSTRIES",               ///
    keep(match) keepusing(sector productivity) nogenerate
parqit appendin using "$PARQIT_LATE"
assert _N == 1440
list idcode year industry sector productivity in 1/4, noobs

* --------------------------------------------------------------------------
* 6. Other inputs: a delimited text file converted to Parquet without loading it
* parqit also opens .csv/.tsv/.txt, Stata .dta and Excel sources as lazy views.
* Text carries no storage types or labels, so the converted file holds plain
* numbers; the Parquet written in section 1 keeps the typed, labelled data.
* Menu: User > parqit > Read Parquet data (lazy view or into memory)...
parqit use "$PARQIT_WORKERS", clear
export delimited using "$PARQIT_CSV", replace nolabel
clear
parqit use using "$PARQIT_CSV"
parqit describe
parqit count
parqit save "$PARQIT_FROM_CSV", replace compression(zstd)
parqit close
parqit describe "$PARQIT_FROM_CSV"

display as result _newline "parqit_basics.do complete"
display as text "Example files are in $PARQIT_EXAMPLE_DIR"
display as text "Next: run parqit_tour.do for lazy exploration, statistics and SQL."
