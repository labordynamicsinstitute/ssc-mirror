*! example_dashboardbuilder.do — worked examples for -dashboardbuilder-
*! ----------------------------------------------------------------------------
*!  Builds FOUR dashboards from datasets that ship with Stata (no downloads,
*!  except one optional web example at the end), exercising every panel type
*!  and most options. Outputs land in ./dashboard_examples/ next to wherever
*!  you run this from. Open the .html files by double-clicking; no server or
*!  internet needed.
*!
*!  Run top-to-bottom:   do example_dashboardbuilder.do
*!  Requires: dashboardbuilder.ado on the adopath (or in the same folder),
*!            Stata 16+, and a Python 3 visible to Stata (see -help dashboardbuilder-).
*! ----------------------------------------------------------------------------
version 16
clear all
set more off

capture mkdir "dashboard_examples"

* ═══════════════════════════════════════════════════════════════════════════
* DASHBOARD 1 — two-minute minimal (auto data, default "simple" theme)
*   The smallest useful call pattern: init -> panels -> build.
* ═══════════════════════════════════════════════════════════════════════════
sysuse auto, clear
collapse (mean) price mpg weight, by(foreign)

dashboardbuilder init , title("Auto quick look") ///
    subtitle("mean price, mileage, and weight by origin (1978 autos)")
dashboardbuilder panel bar , x(foreign) y(price) ///
    title("Domestic cars cost less on average") ytitle("mean price (USD)")
dashboardbuilder panel table , title("The numbers behind the chart")
* A finished build AUTO-OPENS in your browser by default. This first dashboard
* shows that; the later three pass -noopen- so running the whole file opens just
* one tab (every receipt still prints clickable open/folder links either way).
dashboardbuilder build using "dashboard_examples/auto_quick.html", replace

* r() is populated after build:
di as txt "built: " as res r(file) as txt " (" r(bytes) " bytes)"


* ═══════════════════════════════════════════════════════════════════════════
* DASHBOARD 2 — the "County Explorer" pattern: selector + reference unit
*   sysuse census: 50 states. We hand-build a synthetic "United States" row
*   (population-weighted where appropriate) and declare it the REFERENCE unit.
*   Every panel whose data carry a variable named -state- becomes filterable;
*   line/compare panels then show the US as the dashed line / | marker.
*   Also shows: tx2036 branding, tabs, per-panel CSV, save-as-PDF, callout.
* ═══════════════════════════════════════════════════════════════════════════
sysuse census, clear

* rates per 1,000 residents so the compare panel's rows share one scale
gen double death_rt = 1000 * death    / pop
gen double marr_rt  = 1000 * marriage / pop
gen double div_rt   = 1000 * divorce  / pop
label var pop      "Population"
label var medage   "Median age (years)"
label var death_rt "Deaths per 1,000"
label var marr_rt  "Marriages per 1,000"
label var div_rt   "Divorces per 1,000"

* ---- build the reference row: a synthetic United States aggregate ----------
* NOTE: do NOT put [aw=pop] on this collapse — Stata would apply the weight to
* the (sum) totals too and roughly double the US population. Sum the counts
* plainly; medage is a simple mean of the state medians (fine for a demo row).
preserve
    collapse (sum) pop death marriage divorce (mean) medage
    gen double death_rt = 1000 * death    / pop
    gen double marr_rt  = 1000 * marriage / pop
    gen double div_rt   = 1000 * divorce  / pop
    gen str28 state = "United States"
    tempfile us
    save `us'
restore
append using `us'
tempfile censusplus
save `censusplus'

dashboardbuilder init , title("State explorer") ///
    subtitle("every state against the national picture (1980 census)") ///
    tx2036 selector(state) sellabel("Choose a state") refvalue("United States")

dashboardbuilder tab , name(today) label("Where states stand")
dashboardbuilder tab , name(rank)  label("Rankings")

* -- KPI tiles: one row per state, so collapse is already done ---------------
use `censusplus', clear
keep state pop medage death_rt
dashboardbuilder panel kpi , tab(today) values(pop medage death_rt) ///
    title("Headline numbers") ///
    interp("Pick a state above; tiles and bars update. 'United States' is the reference.")

* -- compare bullet bars: reshape metrics long; the US row supplies | markers -
use `censusplus', clear
keep state death_rt marr_rt div_rt
rename (death_rt marr_rt div_rt) (v1 v2 v3)
reshape long v, i(state) j(metric)
label define metric 1 "Deaths per 1,000" 2 "Marriages per 1,000" 3 "Divorces per 1,000"
label values metric metric
dashboardbuilder panel compare , tab(today) x(metric) y(v) ///
    title("Vital rates vs. the United States") ///
    note("Bar = selected state; | marker = United States. Rates share one scale.") ///
    ytitle("per 1,000 residents")

* -- a STATIC ranking: rename the selector column so it does NOT filter ------
use `censusplus', clear
drop if state == "United States"
gsort -medage
keep in 1/10
rename state stname                    // <- different name => panel stays static
dashboardbuilder panel hbar , tab(rank) x(stname) y(medage) ///
    title("Ten oldest states by median age") ytitle("median age (years)")

* -- full leaderboard table, also STATIC. With BOTH Rankings panels static, this
*    tab is a selection-independent overview, so dashboardbuilder auto-hides the
*    "choose a state" dropdown while you are on the Rankings tab. --------------
use `censusplus', clear
drop if state == "United States"
keep state region pop medage death_rt marr_rt div_rt
rename state stname                    // <- static, like the hbar: show all states
label var stname "State"
dashboardbuilder panel table , tab(rank) title("Every state, every metric")

dashboardbuilder describe        // show the registered plan before building

* CSV + PNG per-panel buttons and hover tooltips are ON by default (all offline-safe).
* -pdf- adds an offline Save-as-PDF (print) button; -truepdf- adds a one-click PDF
* button that pulls a JS library from a CDN (so it needs internet — the receipt says so).
* Auto-open is ON by default; -noopen- suppresses it (used here so the demo opens
* just one tab). Click the open/folder links in the receipt to view it.
dashboardbuilder build using "dashboard_examples/state_explorer.html", replace ///
    pdf truepdf noopen ///
    callout("A teaching example on 1980 census extracts; the point is the layout, not the vintage.") ///
    sourcenote("Source: sysuse census (1980 US census extract shipped with Stata).")


* ═══════════════════════════════════════════════════════════════════════════
* DASHBOARD 3 — time series + tabs + feeding SUBSETS between panel calls
*   sysuse uslifeexp: US life expectancy 1900-1999. Note how the second panel
*   captures a RESTRICTED subset (keep if year>=1950) — each panel embeds its
*   own snapshot of whatever is in memory at that moment.
* ═══════════════════════════════════════════════════════════════════════════
sysuse uslifeexp, clear

dashboardbuilder init , title("A century of US life expectancy") ///
    subtitle("1900-1999, from the National Center for Health Statistics")

dashboardbuilder tab , name(overview) label("Overview")
dashboardbuilder tab , name(gaps)     label("Gaps")

dashboardbuilder panel line , tab(overview) x(year) y(le) ///
    title("Life expectancy rose about 30 years in one century") ///
    interp("The 1918 flu pandemic is the sharp notch; everything after 1950 is a slower grind.") ///
    ytitle("years at birth")

dashboardbuilder panel line , tab(gaps) x(year) y(le_male le_female) ///
    title("The male-female gap opened, then narrowed") ytitle("years at birth")

keep if year >= 1950                     // <- subset feeding: panel captures this
dashboardbuilder panel line , tab(gaps) x(year) y(le_wm le_bm) ///
    title("White vs. Black men, postwar era") ///
    note("Series restricted to 1950 onward at capture time.") ytitle("years at birth")

dashboardbuilder build using "dashboard_examples/lifeexp.html", replace pdf noopen ///
    sourcenote("Source: sysuse uslifeexp (NCHS life tables shipped with Stata).")


* ═══════════════════════════════════════════════════════════════════════════
* DASHBOARD 4 (OPTIONAL) — health survey example, needs internet once
*   webuse nhanes2: NHANES II microdata. Guarded so the do-file still runs
*   offline; delete the -capture- guard if you want a hard error instead.
* ═══════════════════════════════════════════════════════════════════════════
capture webuse nhanes2, clear
if _rc {
    di as txt "(skipping the NHANES example — no internet or webuse failed)"
}
else {
    dashboardbuilder init , title("Blood pressure in NHANES II") ///
        subtitle("systolic and diastolic by age group, 1976-1980") tx2036

    preserve
        collapse (mean) bpsystol bpdiast, by(agegrp)
        dashboardbuilder panel bar , x(agegrp) y(bpsystol) ///
            title("Systolic pressure climbs with age") ytitle("mean mmHg")
        dashboardbuilder panel line , x(agegrp) y(bpsystol bpdiast) ///
            title("Systolic rises faster than diastolic") ytitle("mean mmHg")
    restore

    preserve
        collapse (mean) bpsystol, by(agegrp sex)
        reshape wide bpsystol, i(agegrp) j(sex)
        label var bpsystol1 "Men"
        label var bpsystol2 "Women"
        dashboardbuilder panel line , x(agegrp) y(bpsystol1 bpsystol2) ///
            title("Men run higher until the oldest groups") ytitle("mean systolic mmHg")
    restore

    dashboardbuilder build using "dashboard_examples/nhanes_bp.html", replace noopen ///
        sourcenote("Source: webuse nhanes2 (NHANES II, 1976-1980).")
}

di as res _n "done — open the files in dashboard_examples/ by double-clicking."
