{smcl}
{* *! version 1.0.0 23aug2026}{...}
{vieweralsosee "preserve" "help preserve"}{...}
{vieweralsosee "restore" "help restore"}{...}
{vieweralsosee "frames" "help frames"}{...}
{vieweralsosee "save" "help save"}{...}

{title:Title}

{phang}
{bf:nestpreserve} {hline 2} Preserve, inspect, and restore multiple nested dataset states{p_end}

{title:Description}

{pstd}
NESTPRESERVE is a disk-backed, last-in–first-out stack of dataset-state checkpoints.
It lets each Stata frame save, inspect, and restore multiple analytical states;
it manages the dataset, not the complete Stata session.{p_end}

{title:When preserve/restore is not enough}

{pstd}
Official {cmd:preserve}/{cmd:restore} is ideal for one temporary data state. Use NESTPRESERVE when states must be nested, destructive work must roll back automatically, or checkpoint changes, ownership, cleanup, and recovery must be inspectable rather than managed through temporary files and repeated {cmd:save}/{cmd:use} calls. The main differences are summarized below.{p_end}

{center:{bf:{ul:Official preserve/restore and nestpreserve}}}

{col 75}{bf:Feature}{col 113}{bf:preserve/restore}{col 135}{bf:nestpreserve}
{col 75}{hline 82}
{col 75}One active saved dataset state{col 113}Yes{col 135}Yes
{col 75}Multiple active checkpoints{col 113}No{col 135}Yes
{col 75}Nested LIFO checkpoint restoration{col 113}No{col 135}Yes
{col 75}Restore while retaining a checkpoint{col 113}{cmd:restore, preserve}{col 135}{cmd:nestrestore, preserve}
{col 75}Frame-ownership protection{col 113}No{col 135}Yes
{col 75}Inspect active checkpoints{col 113}No{col 135}{cmd:neststatus}
{col 75}Clear an abandoned checkpoint stack{col 113}Not applicable{col 135}{cmd:nestclear}
{col 75}Maximum-depth control{col 113}Fixed at one level{col 135}{cmd:maxdepth()}
{col 75}Automatic transactional rollback{col 113}No{col 135}{cmd:nesttransaction:}
{col 75}Manifest-based recovery{col 113}No{col 135}{cmd:nestrecover}
{col 75}{hline 82}

{title:Key features}

{p 4 8 2}• {bf:Rollback.} {cmd:nesttransaction:} returns the dataset to its checkpoint after success or failure.{p_end}
{p 4 8 2}• {bf:Audit.} {cmd:neststatus} reports stack health, sample and variable changes, and transaction history.{p_end}
{p 4 8 2}• {bf:Safe recovery.} {cmd:nestrecover} and {cmd:nestclear} act automatically only on one safely identifiable abandoned stack; uncertainty is refused.{p_end}

{title:Syntax}

{p 4 4 2}{cmd:nestpreserve} [{cmd:,} {opt maxdepth(#)} {opt quiet}]{break}
Save the current dataset as the next checkpoint. {opt maxdepth(#)} limits stack
depth (default 100); {opt quiet} suppresses confirmation. Each checkpoint is a
complete dataset copy, so disk use grows with dataset size and stack depth.{p_end}

{p 4 4 2}{cmd:nestrestore} [{cmd:,} {opt preserve} {opt quiet}]{break}
Restore and remove the newest checkpoint. {opt preserve} restores it without
removing it; the next {cmd:nestrestore} restores the same checkpoint and
removes it. Restore only in the frame that created the checkpoint. If official
{cmd:preserve}/{cmd:restore} is also used, restore both mechanisms in strict
reverse order.{p_end}

{p 4 4 2}{cmd:neststatus} [{cmd:,} {opt detail}]{break}
Show stack health, state changes, and transaction history; {opt detail} adds
frames, dimensions, paths, and file status.{p_end}

{p 4 4 2}{cmd:nesttransaction} [{cmd:,} {opt quiet}]{cmd::} {it:command}{break}
Run one command and roll back its dataset changes.{p_end}

{p 4 4 2}{cmd:nestrecover}{break}
Recover the latest checkpoint from the unique safely identifiable crashed
session. Expert inspection syntax is documented in {help nestrecover}.{p_end}

{p 4 4 2}{cmd:nestclear} [{cmd:,} {opt force} {opt quiet}]{break}
Delete owned checkpoints without restoring them. With no active stack, the
one-word command cleans only one safely identifiable crashed session;
{opt force} applies only to an adopted current stack.{p_end}

{title:Practical applications}

{pstd}
The following examples apply nested dataset states, rollback, inspection, and
restoration to substantive research workflows.{p_end}

{title:Example 1. Diagnosing, Rolling Back, and Recovering Dataset States}

{pstd}{bf:Part A. Find and undo unintended sample and variable changes}{p_end}
{p 4 4 2}sysuse auto, clear{p_end}
{p 4 4 2}nestpreserve{p_end}
{p 4 4 2}keep if foreign == 0{p_end}
{p 4 4 2}keep make price mpg{p_end}
{p 4 4 2}neststatus, detail{p_end}
{p 4 4 2}nestrestore{p_end}
{pstd}
{cmd:neststatus, detail} reports 22 observations removed, nine variables
removed, and the checkpoint to be restored. {cmd:nestrestore} then returns to
the complete 74-observation, 12-variable automobile data.{p_end}

{pstd}{bf:Part B. Roll back a destructive analysis automatically}{p_end}
{p 4 4 2}sysuse auto, clear{p_end}
{p 4 4 2}nesttransaction: collapse (mean) price mpg, by(foreign){p_end}
{p 4 4 2}describe{p_end}
{p 4 4 2}neststatus{p_end}
{pstd}
The command temporarily collapses the data to two group-level observations
containing mean price and mpg. {cmd:nesttransaction:} then restores all 74 cars
automatically. {cmd:neststatus} confirms that both the command and the rollback
completed successfully.{p_end}

{pstd}{bf:Part C. Recover or discard a checkpoint after Stata ends}{p_end}
{pstd}
A researcher begins a repair-record summary, but Stata ends before the saved
74-car dataset is restored. To reproduce this safely, run {bf:only} the following
block in the first Stata process; its final command deliberately ends that
process without {cmd:nestrestore}:{p_end}
{p 4 4 2}sysuse auto, clear{p_end}
{p 4 4 2}nestpreserve{p_end}
{p 4 4 2}keep if !missing(rep78){p_end}
{p 4 4 2}collapse (mean) price mpg (count) cars=price, by(foreign rep78){p_end}
{p 4 4 2}exit, clear{p_end}
{pstd}
After the first process has fully closed, start a {bf:new Stata process}. Load a
different working dataset, then recover and verify the checkpoint:{p_end}
{p 4 4 2}sysuse census, clear{p_end}
{p 4 4 2}nestrecover{p_end}
{p 4 4 2}describe{p_end}
{p 4 4 2}neststatus, detail{p_end}
{p 4 4 2}nestrestore{p_end}
{pstd}
{cmd:nestrecover} replaces the census data with the saved 74-car dataset and
adopts its checkpoint stack;
{cmd:nestrestore} removes the recovered top checkpoint after verification. If
recovery is not wanted, type {cmd:nestclear} instead of {cmd:nestrecover}; it
deletes the abandoned stack without changing the working data. Automatic
recovery or cleanup proceeds only for one intact abandoned stack whose owner is
proven dead; otherwise it refuses without changing data or deleting files.{p_end}

{title:Example 2. Regional Climate Burden and Seasonal Extremes}

{pstd}{bf:Research question:} How is climate-related energy demand distributed across U.S. census regions and divisions, and what seasonal temperature patterns are associated with the greatest annual demand?{p_end}

{p 4 4 2}* Part 1. Preparing complete city-level climate analysis data.{p_end}
{p 4 4 2}sysuse citytemp, clear{p_end}
{p 4 4 2}nestpreserve{p_end}
{p 4 4 2}drop if missing(division, region, heatdd, cooldd, tempjan, tempjuly){p_end}
{p 4 4 2}egen division_id = group(division), label{p_end}
{p 4 4 2}egen region_id = group(region), label{p_end}
{p 4 4 2}g double annual_range = tempjuly-tempjan{p_end}
{p 4 4 2}g double total_degree_days = heatdd+cooldd{p_end}
{p 4 4 2}g byte demand_type = cond(heatdd>cooldd, 1, 2){p_end}
{p 4 4 2}lab def demand_type 1 "Heating-dominant" 2 "Cooling-dominant"{p_end}
{p 4 4 2}lab val demand_type demand_type{p_end}
{p 4 4 2}nestpreserve{p_end}

{p 4 4 2}* Part 2. Creating regional climate-demand summaries.{p_end}
{p 4 4 2}collapse (count) cities=total_degree_days ///{p_end}
{p 8 8 2}(mean) tempjan tempjuly annual_range heatdd cooldd total_degree_days, ///{p_end}
{p 8 8 2}by(region_id){p_end}
{p 4 4 2}gsort -total_degree_days{p_end}
{p 4 4 2}list region_id cities tempjan tempjuly annual_range heatdd cooldd total_degree_days, noobs{p_end}
{p 4 4 2}nestrestore, preserve{p_end}

{p 4 4 2}* Part 3. Identifying extreme seasonal climate conditions.{p_end}
{p 4 4 2}* For the purpose of illustration, an extreme winter condition is defined as an average January temperature of 10°F or lower, and an extreme summer condition as an average July temperature of 85°F or higher.{p_end}
{p 4 4 2}keep if tempjan<=10 | tempjuly>=85{p_end}
{p 4 4 2}gsort tempjan -tempjuly{p_end}
{p 4 4 2}list division region tempjan tempjuly annual_range heatdd cooldd, noobs{p_end}
{p 4 4 2}nestrestore, preserve{p_end}

{p 4 4 2}* Part 4. Summarizing heating- versus cooling-dominant regions.{p_end}
{p 4 4 2}contract region_id demand_type{p_end}
{p 4 4 2}bys region_id: egen region_total = total(_freq){p_end}
{p 4 4 2}g double percentage = 100*_freq/region_total{p_end}
{p 4 4 2}format percentage %6.1f{p_end}
{p 4 4 2}sort region_id demand_type{p_end}
{p 4 4 2}list region_id demand_type _freq percentage, sepby(region_id) noobs{p_end}
{p 4 4 2}nestrestore, preserve{p_end}

{p 4 4 2}* Part 5. Comparing division-level climate demand patterns.{p_end}
{p 4 4 2}collapse (count) cities=total_degree_days ///{p_end}
{p 8 8 2}(mean) mean_degree_days=total_degree_days ///{p_end}
{p 8 8 2}(p50) median_degree_days=total_degree_days, by(division_id){p_end}
{p 4 4 2}gsort -mean_degree_days{p_end}
{p 4 4 2}list division_id cities mean_degree_days median_degree_days, noobs{p_end}
{p 4 4 2}nestrestore, preserve{p_end}

{p 4 4 2}* Part 6. Modeling climate demand using temperature interactions.{p_end}
{p 4 4 2}reg total_degree_days c.tempjan##c.tempjuly i.region_id, vce(robust){p_end}
{p 4 4 2}margins, at(tempjan=(10 30 50) tempjuly=(65 75 85)){p_end}
{p 4 4 2}marginsplot, xdimension(tempjan) plotdimension(tempjuly) ///{p_end}
{p 8 8 2}title("Annual Climate-Related Energy Demand", size(medsmall) margin(b+4)) ///{p_end}
{p 8 8 2}ytitle("Annual Total Degree Days", size(small)) ///{p_end}
{p 8 8 2}xtitle("January Temperature", size(small)) ///{p_end}
{p 8 8 2}legend(title("July Temperature", size(vsmall)) ///{p_end}
{p 12 12 2}size(vsmall) order(1 "65°F" 2 "75°F" 3 "85°F") ///{p_end}
{p 12 12 2}position(2) ring(1) cols(1) rowgap(0.5) symysize(*.65) region(lstyle(none))) ///{p_end}
{p 8 8 2}xlabel(10 "10°F" 30 "30°F" 50 "50°F", labsize(vsmall) nogrid) ///{p_end}
{p 8 8 2}ylabel(2000(2000)10000, labsize(small) nogrid) ///{p_end}
{p 8 8 2}note("{c -(}it:Note.{c )-} Annual total degree days equal heating degree days plus cooling degree days.", ///{p_end}
{p 12 12 2}size(vsmall) span margin(t+4)) ///{p_end}
{p 8 8 2}graphregion(color(white)) plotregion(color(white)) ///{p_end}
{p 8 8 2}name(climate_demand, replace){p_end}
{p 4 4 2}nestrestore{p_end}
{p 4 4 2}nestrestore{p_end}

{pstd}{bf:Illustrative interpretation}{p_end}
{pstd}The regional summary shows substantial geographic variation in climate-related energy demand. The North Central region has the highest average annual total of 7,268 degree days, followed by the Northeast with 6,525 degree days. Average annual totals are considerably lower in the South at 4,845 degree days and in the West at 4,143 degree days. Using the illustrative thresholds defined above, extremely cold winter conditions occur primarily in the North Central region, whereas extremely hot summer conditions are concentrated in the South and parts of the West. The demand-composition summary shows that every city in both the Northeast and North Central regions is heating-dominant. In the South, 54.8 percent of cities are heating-dominant and 45.2 percent are cooling-dominant, whereas 88.7 percent of cities in the West remain heating-dominant. Division-level comparisons show that the West North Central division has the greatest average annual climate-related energy demand at 7,697 degree days, followed by the East North Central division at 7,106 degree days. The predictive margins further show that annual climate-related energy demand reaches approximately 9,849 degree days when the average January temperature is 10°F and the average July temperature is 65°F. Across all representative July temperatures, annual climate-related energy demand generally declines as January temperatures become warmer, although the magnitude of that decline differs across summer temperature conditions.{p_end}

{title:Example 3. Concurrent Multi-Frame Analysis of Systolic Blood Pressure}

{pstd}{bf:Research question:} What factors are associated with systolic blood pressure at the individual level, and how do regional sex-specific patterns appear when the same survey population is summarized across geographic groups?{p_end}

{p 4 4 2}clear all{p_end}
{p 4 4 2}webuse nhanes2, clear{p_end}
{p 4 4 2}frame rename default individual{p_end}
{p 4 4 2}frame copy individual profile{p_end}

{p 4 4 2}* Part 1. Preparing concurrent analytical states across frames.{p_end}
{p 4 4 2}frame change individual{p_end}
{p 4 4 2}svyset psu [pweight=finalwgt], strata(strata){p_end}
{p 4 4 2}nestpreserve{p_end}
{p 4 4 2}keep if !missing(bpsystol, age, sex, race, bmi, ///{p_end}
{p 8 8 2}psu, strata, finalwgt){p_end}
{p 4 4 2}g double ln_bpsystol = ln(bpsystol){p_end}

{p 4 4 2}frame change profile{p_end}
{p 4 4 2}svyset psu [pweight=finalwgt], strata(strata){p_end}
{p 4 4 2}nestpreserve{p_end}
{p 4 4 2}keep if !missing(bpsystol, region, sex, ///{p_end}
{p 8 8 2}psu, strata, finalwgt){p_end}

{p 4 4 2}* Part 2. Conducting regional descriptive analysis by sex.{p_end}
{p 4 4 2}svy: mean bpsystol, over(region sex){p_end}
{p 4 4 2}collapse (mean) mean_bpsystol=bpsystol [pweight=finalwgt], by(region sex){p_end}
{p 4 4 2}reshape wide mean_bpsystol, i(region) j(sex){p_end}
{p 4 4 2}list region mean_bpsystol1 mean_bpsystol2, noobs{p_end}

{p 4 4 2}* Part 3. Restoring the profile-frame analytical state.{p_end}
{p 4 4 2}nestrestore{p_end}

{p 4 4 2}* Part 4. Estimating individual-level blood-pressure models.{p_end}
{p 4 4 2}frame change individual{p_end}
{p 4 4 2}svy: reg bpsystol c.age i.sex i.race c.bmi{p_end}
{p 4 4 2}svy: reg ln_bpsystol c.age i.sex i.race c.bmi{p_end}

{p 4 4 2}* Part 5. Restoring the individual-frame analytical state.{p_end}
{p 4 4 2}nestrestore{p_end}
{p 4 4 2}neststatus{p_end}


{pstd}{bf:Illustrative interpretation}{p_end}
{pstd}The first survey-weighted regression examines adjusted associations with systolic blood pressure at the individual level. Older age and higher body mass index are positively associated with systolic blood pressure after adjustment for sex and race. Specifically, each additional year of age is associated with a 0.57 mmHg increase in systolic blood pressure, and each one-unit increase in BMI is associated with a 1.26 mmHg increase. Female participants have systolic blood pressure that is approximately 5.62 mmHg lower than male participants, whereas Black participants have systolic blood pressure that is approximately 1.54 mmHg higher than White participants in the adjusted model.{p_end}

{pstd}The second individual-level analysis evaluates the same analytical population using a logarithmic transformation of systolic blood pressure. The direction of associations remains substantively consistent with the original model: age and body mass index remain positively associated with systolic blood pressure, while female participants have lower expected systolic blood pressure than male participants.{p_end}

{pstd}The regional descriptive analysis represents the same survey population from a geographic and sex-specific perspective. Across all four U.S. census regions, men have higher average systolic blood pressure than women. Male mean systolic blood pressure ranges from 129.2 to 131.4 mmHg, whereas female mean systolic blood pressure ranges from 123.5 to 124.8 mmHg.{p_end}

{pstd}The workflow maintains two concurrently preserved analytical states: an individual-level survey state in the {cmd:individual} frame and a regional descriptive state in the {cmd:profile} frame. Because both snapshots coexist on the same preservation stack, restoration follows both LIFO order and frame ownership. The profile-frame state is restored first, followed by the individual-frame state. This frame-aware workflow prevents a snapshot created in one frame from being restored into and overwriting another frame.{p_end}

{pstd}Together, the example shows how the same survey population can support individual-level modeling and regional descriptive analysis while maintaining separate, recoverable analytical states across frames. The final {cmd:neststatus} confirms that both preserved states have been restored and that no active stack remains.{p_end}

{title:Example 4. Nested Transactions for Multi-Scale Spatiotemporal Analysis}

{pstd}{bf:Research question:} How did county homicide rates in the Southern United States vary spatially across 1960, 1970, 1980, and 1990 and change over time, and how do the estimated associations of income inequality, population size, and population density with homicide rates differ across state-year, county long-run, 1990 spatial cross-sectional, and county-year spatial-panel representations?{p_end}

{p 4 4 2}* Part 1. Preparing county-level spatiotemporal data and mapping homicide rates across benchmark years.{p_end}
{p 4 4 2}clear all{p_end}
{p 4 4 2}spmatrix clear{p_end}
{p 4 4 2}graph set window fontface "Times New Roman"{p_end}
{p 4 4 2}graph set pdf fontface "Times New Roman"{p_end}
{p 4 4 2}copy https://www.stata-press.com/data/r19/homicide_1960_1990.dta ., replace{p_end}
{p 4 4 2}copy https://www.stata-press.com/data/r19/homicide_1960_1990_shp.dta ., replace{p_end}
{p 4 4 2}use homicide_1960_1990, clear{p_end}
{p 4 4 2}xtset _ID year{p_end}
{p 4 4 2}spset{p_end}
{p 4 4 2}spmatrix create contiguity W if year == 1990{p_end}
{p 4 4 2}* Install grc1leg2 from SSC to give the four maps one shared legend.{p_end}
{p 4 4 2}ssc install grc1leg2, replace{p_end}
{p 4 4 2}foreach y in 1960 1970 1980 1990 {c -(}{p_end}
{p 4 4 2}    grmap hrate, ///{p_end}
{p 4 4 2}        t(`y') ///{p_end}
{p 4 4 2}        clmethod(custom) ///{p_end}
{p 4 4 2}        clbreaks(0 5 10 15 65) ///{p_end}
{p 4 4 2}        fcolor(eltblue emidblue midblue edkblue) ///{p_end}
{p 4 4 2}        ocolor(gs8 gs8 gs8 gs8) ///{p_end}
{p 4 4 2}        osize(vthin vthin vthin vthin) ///{p_end}
{p 4 4 2}        title("`y'", size(medsmall) position(12) ring(0) margin(t+8)) ///{p_end}
{p 4 4 2}        legend( ///{p_end}
{p 4 4 2}            order(1 "4.9 or lower" 2 "5.0–9.9" 3 "10.0–14.9" 4 "15.0 or higher") ///{p_end}
{p 4 4 2}                        size(small) ///{p_end}
{p 4 4 2}            rows(1) ///{p_end}
{p 4 4 2}            symxsize(4) ///{p_end}
{p 4 4 2}            keygap(1) ///{p_end}
{p 4 4 2}            colgap(2) ///{p_end}
{p 4 4 2}            region(lcolor(none) fcolor(none)) ///{p_end}
{p 4 4 2}        ) ///{p_end}
{p 4 4 2}        graphregion(color(white)) ///{p_end}
{p 4 4 2}        plotregion(margin(zero)) ///{p_end}
{p 4 4 2}        name(map`y', replace){p_end}
{p 4 4 2}{c )-}{p_end}
{p 4 4 2}grc1leg2 map1960 map1970 map1980 map1990, ///{p_end}
{p 4 4 2}    rows(2) ///{p_end}
{p 4 4 2}    legendfrom(map1960) ///{p_end}
{p 4 4 2}    position(6) ///{p_end}
{p 4 4 2}    ring(1) ///{p_end}
{p 4 4 2}    imargin(0 0 0 0) ///{p_end}
{p 4 4 2}    graphregion(color(white)) ///{p_end}
{p 4 4 2}    title("County Homicide Rates, 1960–1990", size(medsmall) margin(b+8)) ///{p_end}
{p 4 4 2}    note("{c -(}it:Note.{c )-} Rates are expressed per 100,000 persons.", size(vsmall) position(7)) ///{p_end}
{p 4 4 2}    name(homicide_maps, replace){p_end}
{p 4 4 2}graph export "County_Homicide_Rates_1960_1990.pdf", replace{p_end}
{p 4 4 2}graph export "County_Homicide_Rates_1960_1990.png", width(3600) replace{p_end}
{p 4 4 2}nestpreserve{p_end}

{p 4 4 2}* Part 2. Estimating annual average county homicide trends.{p_end}
{p 4 4 2}program define southern_county_trend_model{p_end}
{p 4 4 2}    collapse (mean) mean_hrate=hrate, by(year){p_end}
{p 4 4 2}    twoway connected mean_hrate year, ///{p_end}
{p 4 4 2}        msymbol(O) ///{p_end}
{p 4 4 2}        msize(medsmall) ///{p_end}
{p 4 4 2}        lwidth(medthick) ///{p_end}
{p 4 4 2}        xlabel(1960 1970 1980 1990, labsize(small) nogrid) ///{p_end}
{p 4 4 2}        ylabel(7(1)11, angle(horizontal) labsize(small) nogrid format(%3.1f)) ///{p_end}
{p 4 4 2}        xtitle("") ///{p_end}
{p 4 4 2}        ytitle("Rates", size(small)) ///{p_end}
{p 4 4 2}        title("Average County Homicide Rates, 1960–1990", size(medsmall)) ///{p_end}
{p 4 4 2}        note("{c -(}it:Note.{c )-} Rates are expressed per 100,000 persons.", ///{p_end}
{p 4 4 2}            size(vsmall) position(7)) ///{p_end}
{p 4 4 2}        legend(off) ///{p_end}
{p 4 4 2}        graphregion(color(white)) ///{p_end}
{p 4 4 2}        plotregion(color(white) lcolor(black) lwidth(thin)) ///{p_end}
{p 4 4 2}        name(homicide_trend, replace){p_end}
{p 4 4 2}    graph export "Average_County_Homicide_Rate_Trend.pdf", replace{p_end}
{p 4 4 2}    graph export "Average_County_Homicide_Rate_Trend.png", width(2400) replace{p_end}
{p 4 4 2}end{p_end}
{p 4 4 2}nesttransaction: southern_county_trend_model{p_end}

{p 4 4 2}* Part 3. Estimating state-year fixed-effects panel models.{p_end}
{p 4 4 2}program define state_year_model{p_end}
{p 4 4 2}    egen state_id = group(sname){p_end}
{p 4 4 2}    g double homicide_equiv = hrate*population/100000{p_end}
{p 4 4 2}    g double gini_weighted = gini*population{p_end}
{p 4 4 2}    collapse (sum) population homicide_equiv gini_weighted, ///{p_end}
{p 4 4 2}        by(state_id sname year){p_end}
{p 4 4 2}    g double hrate = 100000*homicide_equiv/population{p_end}
{p 4 4 2}    g double gini = gini_weighted/population{p_end}
{p 4 4 2}    g double ln_population = ln(population){p_end}
{p 4 4 2}    xtset state_id year{p_end}
{p 4 4 2}    xtreg hrate ln_population gini i.year, fe vce(cluster state_id){p_end}
{p 4 4 2}    est sto state_year{p_end}
{p 4 4 2}end{p_end}
{p 4 4 2}nesttransaction: state_year_model{p_end}

{p 4 4 2}* Part 4. Estimating county long-run average models.{p_end}
{p 4 4 2}program define county_long_run_model{p_end}
{p 4 4 2}    collapse (mean) hrate ln_population ln_pdensity gini, by(_ID){p_end}
{p 4 4 2}    reg hrate ln_population ln_pdensity gini, vce(robust){p_end}
{p 4 4 2}    est sto county_long_run{p_end}
{p 4 4 2}end{p_end}
{p 4 4 2}nesttransaction: county_long_run_model{p_end}

{p 4 4 2}* Part 5. Estimating 1990 spatial cross-sectional models.{p_end}
{p 4 4 2}program define cross_section_1990_model{p_end}
{p 4 4 2}    keep if year == 1990{p_end}
{p 4 4 2}    spregress hrate ln_population ln_pdensity gini, ///{p_end}
{p 4 4 2}        gs2sls dvarlag(W) errorlag(W){p_end}
{p 4 4 2}    est sto cross_section_1990{p_end}
{p 4 4 2}end{p_end}
{p 4 4 2}nesttransaction: cross_section_1990_model{p_end}

{p 4 4 2}* Part 6. Estimating county-year spatial panel models.{p_end}
{p 4 4 2}spxtregress hrate ln_population ln_pdensity gini, ///{p_end}
{p 4 4 2}    fe dvarlag(W) errorlag(W){p_end}
{p 4 4 2}est sto county_year_spatial_panel{p_end}
{p 4 4 2}estat impact{p_end}
{p 4 4 2}est table state_year county_long_run cross_section_1990 ///{p_end}
{p 4 4 2}    county_year_spatial_panel, ///{p_end}
{p 4 4 2}    b(%9.3f) se(%9.3f) stats(N){p_end}
{p 4 4 2}spmatrix drop W{p_end}
{p 4 4 2}nestrestore{p_end}
{p 4 4 2}neststatus{p_end}

{pstd}{bf:Illustrative interpretation}{p_end}
{pstd}The county maps describe the spatial distribution of homicide rates across the benchmark years 1960, 1970, 1980, and 1990. They show how the geographic concentration and intensity of county homicide rates changed over time. The annual trend then summarizes the average county homicide rate at each benchmark year, providing a temporal representation that complements the spatial maps. The four inferential models evaluate whether the associations of income inequality, population size, and population density with homicide rates remain consistent when the same underlying data are represented as a state-year fixed-effects panel, county long-run averages, a 1990 spatial cross-section, and a county-year spatial panel.{p_end}

{pstd}Income inequality is positively and statistically significantly associated with homicide rates in every inferential model, although the estimated magnitude varies markedly. The Gini coefficient is 74.655 in the state-year fixed-effects model, 65.507 in the county long-run model, 82.069 in the 1990 spatial cross-section, and 16.906 in the county-year spatial panel. In the spatial panel, the estimated average direct, indirect, and total effects of income inequality are 18.599, 27.311, and 45.910, respectively, and all are statistically significant.{p_end}

{pstd}The findings for population size and population density are not stable across analytical scales. In the state-year fixed-effects model, population size is negative but not statistically significant (b = -19.269, p = 0.212). In the county long-run model, both population size (b = 0.620, p = 0.001) and population density (b = 0.659, p < 0.001) are positively associated with homicide rates. In the 1990 spatial cross-section, population density remains positive and statistically significant (b = 1.081, p < 0.001), whereas population size is not significant (b = 0.103, p = 0.713). In the county-year spatial panel, neither population size (b = -0.714, p = 0.640) nor population density (b = 0.025, p = 0.987) is statistically significant.{p_end}

{pstd}Both spatial models also show strong spatial dependence. In the 1990 cross-section, the spatial lag coefficient is 0.194 (p = 0.003) and the spatial error coefficient is 0.356 (p < 0.001). In the county-year spatial panel, the corresponding coefficients are 0.699 and -0.690, and both are statistically significant at p < 0.001.{p_end}

{pstd}The central substantive conclusion is therefore conditional on scale and model specification. Income inequality remains a robust positive correlate of homicide rates, but conclusions about population size and population density change when the analysis moves from between-county long-run differences to a single-year spatial comparison or to within-county change over time. The benchmark-year maps and annual average county trend are presented graphically because they describe complementary spatial and temporal patterns, whereas the regression comparison table summarizes the four inferential representations.{p_end}

{title:Example 5. Union Exposure and Wages Across Nested Analytical States}

{pstd}{bf:Research question:} How are union exposure, age, and job tenure associated with women’s log wages when the same longitudinal data are examined as descriptive differences between workers who were ever versus never observed in a union, as long-run differences between workers, and as wage changes occurring within the same worker over time?{p_end}

{p 4 4 2}clear all{p_end}
{p 4 4 2}webuse nlswork, clear{p_end}
{p 4 4 2}keep idcode year ln_wage age tenure union{p_end}

{p 4 4 2}* Part 1. Preparing worker-level longitudinal wage data.{p_end}
{p 4 4 2}nestpreserve{p_end}
{p 4 4 2}drop if missing(ln_wage, age, tenure, union){p_end}
{p 4 4 2}g double age2 = age^2{p_end}
{p 4 4 2}bys idcode: egen byte ever_union = max(union){p_end}
{p 4 4 2}xtset idcode year{p_end}
{p 4 4 2}nestpreserve{p_end}

{p 4 4 2}* Part 2. Creating worker-level long-run summaries.{p_end}
{p 4 4 2}collapse ///{p_end}
{p 4 4 2}    (mean) mean_ln_wage=ln_wage ///{p_end}
{p 4 4 2}    mean_age=age ///{p_end}
{p 4 4 2}    mean_tenure=tenure ///{p_end}
{p 4 4 2}    union_share=union ///{p_end}
{p 4 4 2}    (max) ever_union, ///{p_end}
{p 4 4 2}    by(idcode){p_end}
{p 4 4 2}nestpreserve{p_end}

{p 4 4 2}* Part 3. Comparing ever-union and never-union workers.{p_end}
{p 4 4 2}collapse ///{p_end}
{p 4 4 2}    (mean) mean_ln_wage mean_age mean_tenure union_share ///{p_end}
{p 4 4 2}    (count) workers=idcode, ///{p_end}
{p 4 4 2}    by(ever_union){p_end}
{p 4 4 2}list{p_end}
{p 4 4 2}nestrestore{p_end}

{p 4 4 2}* Part 4. Estimating between-worker associations.{p_end}
{p 4 4 2}reg mean_ln_wage mean_age mean_tenure union_share{p_end}
{p 4 4 2}est sto worker_level{p_end}
{p 4 4 2}nestrestore{p_end}

{p 4 4 2}* Part 5. Estimating within-worker fixed-effects models.{p_end}
{p 4 4 2}xtreg ln_wage union age age2 tenure i.year, fe vce(cluster idcode){p_end}
{p 4 4 2}est sto panel_level{p_end}
{p 4 4 2}nestrestore{p_end}
{p 4 4 2}neststatus{p_end}

{pstd}{bf:Illustrative interpretation}{p_end}
{pstd}At the deepest descriptive level, 1,625 workers were ever observed as union members and 2,509 were never observed as union members. Workers ever observed in a union had a higher mean log wage (1.812 versus 1.650) and greater mean tenure (3.970 versus 2.742 years). Their mean union exposure was 0.548, indicating that they were union members in about 55% of their observed person-years.{p_end}

{pstd}After restoring the worker-level long-run dataset, average union exposure is positively associated with average log wages after adjustment for average age and tenure (b = 0.215, p < 0.001). Average tenure is also positively associated with average log wages (b = 0.051, p < 0.001), while the association with average age is positive but small (b = 0.003, p = 0.031). These estimates describe persistent differences between workers and should not be interpreted as within-worker wage changes.{p_end}

{pstd}After restoring the prepared person-year panel, the worker fixed-effects model shows that a worker’s log wage is higher during union than nonunion observations (b = 0.101, p < 0.001), controlling for age, age squared, tenure, and survey year. Tenure remains positively associated with within-worker wage change (b = 0.017, p < 0.001). The positive age coefficient and negative age-squared coefficient indicate a concave age–wage pattern rather than a constant linear age effect.{p_end}

{pstd}The three analytical states therefore answer related but distinct questions. The group summary describes raw differences by ever-union status, the worker-level regression describes long-run between-worker associations, and the fixed-effects model estimates associations from changes within the same worker over time. The final {cmd:neststatus} confirms that the original 28,534-observation panel has been restored with no active checkpoints.{p_end}

{title:Example 6. Nested Transactions for Multi-Level Firm Analysis}

{pstd}{bf:Research question:} During 1946–1954, how do the associations of market value and capital stock with firms' investment rates differ across long-run between-company comparisons, aggregate annual variation, and changes occurring within the same company over time?{p_end}

{p 4 4 2}clear all{p_end}
{p 4 4 2}webuse grunfeld, clear{p_end}
{p 4 4 2}xtset company year{p_end}

{p 4 4 2}* Part 1. Preparing firm-year investment panel data.{p_end}
{p 4 4 2}nestpreserve{p_end}
{p 4 4 2}keep if year >= 1946{p_end}
{p 4 4 2}g double invest_rate = invest/kstock{p_end}
{p 4 4 2}g double ln_mvalue = ln(mvalue){p_end}
{p 4 4 2}g double ln_kstock = ln(kstock){p_end}

{p 4 4 2}* Part 2. Estimating between-company investment model.{p_end}
{p 4 4 2}program define between_company_model{p_end}
{p 4 4 2}collapse (mean) invest_rate ln_mvalue ln_kstock, by(company){p_end}
{p 4 4 2}reg invest_rate ln_mvalue ln_kstock{p_end}
{p 4 4 2}est sto between_companies_model{p_end}
{p 4 4 2}end{p_end}
{p 4 4 2}nesttransaction: between_company_model{p_end}
   
{p 4 4 2}* Part 3. Estimating annual aggregate investment model.{p_end}
{p 4 4 2}program define annual_trend_model{p_end}
{p 4 4 2}collapse (mean) invest_rate ln_mvalue ln_kstock, by(year){p_end}
{p 4 4 2}tsset year{p_end}
{p 4 4 2}newey invest_rate ln_mvalue ln_kstock, lag(1){p_end}
{p 4 4 2}est sto annual_trend_model{p_end}
{p 4 4 2}end{p_end}
{p 4 4 2}nesttransaction: annual_trend_model{p_end}

{p 4 4 2}* Part 4. Estimating within-company fixed-effects model.{p_end}
{p 4 4 2}xtreg invest_rate ln_mvalue ln_kstock, fe vce(cluster company){p_end}
{p 4 4 2}est sto within_companies_model{p_end}

{p 4 4 2}* Part 5. Comparing analytical levels.{p_end}
{p 4 4 2}est table between_companies_model annual_trend_model within_companies_model, ///{p_end}
{p 4 4 2}b(%9.3f) se(%9.3f) stats(N){p_end}
{p 4 4 2}nestrestore{p_end}
{p 4 4 2}neststatus{p_end}

{pstd}{bf:Illustrative interpretation}{p_end}
{pstd}The long-run between-company model uses one mean observation for each of the 10 companies. Companies with a 1-unit higher average log market value have an estimated investment rate that is 0.299 units higher, controlling for average log capital stock ({it:p} = 0.042). Average log capital stock is negatively associated with investment rate ({it:b} = -0.212), although the estimate does not reach the 0.05 significance level ({it:p} = 0.090).{p_end}

{pstd}The annual aggregate model uses nine yearly observations and describes common movement across firms from 1946 through 1954. A 1-unit increase in annual mean log market value is associated with a 0.654-unit higher annual mean investment rate, whereas annual mean log capital stock is associated with a 0.616-unit lower investment rate; both estimates are statistically significant with Newey-West standard errors ({it:p} < 0.001).{p_end}

{pstd}The company fixed-effects model retains all 90 company-year observations and estimates associations from changes within the same company over time. Within a company, a 1-unit increase in log market value is associated with a 0.539-unit increase in investment rate ({it:p} = 0.019), while a 1-unit increase in log capital stock is associated with a 0.590-unit decrease ({it:p} = 0.021).{p_end}

{pstd}The direction of both associations is consistent across the three analytical levels, but their magnitudes and statistical precision differ. The market-value coefficient ranges from 0.299 in the between-company model to 0.654 in the annual aggregate model, and the capital-stock coefficient ranges from -0.212 to -0.616. The results therefore show that long-run differences between firms, aggregate changes shared across firms, and changes within the same firm are distinct quantities and should not be interpreted interchangeably.{p_end}

{pstd}The two {cmd:nesttransaction} calls are essential to the workflow because each model destructively collapses the same prepared firm-year panel in a different way and then automatically returns to that panel. The outer {cmd:nestpreserve} checkpoint remains active throughout, allowing the within-company model to be estimated afterward and the original 200-observation panel to be restored at the end. Replacing this structure mechanically with official single-level {cmd:preserve} and {cmd:restore} would fail when a transaction attempts another preservation inside the active outer checkpoint; reproducing the workflow would instead require manually managed temporary files, frames, or repeated data reconstruction.{p_end}

{title:Selected stored results}

{pstd}
The results most useful in interactive work are shown below. Type
{cmd:return list} after any command for its complete machine-readable record;
individual command help files document specialized diagnostics.{p_end}

{synoptset 44 tabbed}{...}
{synopt:{cmd:nestpreserve: r(depth)}}stack depth after saving{p_end}
{synopt:{cmd:nestpreserve: r(N), r(k)}}observations and variables saved{p_end}
{synopt:{cmd:nestrestore: r(depth)}}stack depth after restoring{p_end}
{synopt:{cmd:nestrestore: r(preserved)}}whether the checkpoint was retained{p_end}
{synopt:{cmd:neststatus: r(valid)}}whether active metadata are valid{p_end}
{synopt:{cmd:neststatus: r(files_ok)}}whether all active snapshots exist{p_end}
{synopt:{cmd:neststatus: r(current_N_change)}}observation change from the top checkpoint{p_end}
{synopt:{cmd:neststatus: r(current_changed)}}whether current data differ from the top checkpoint{p_end}
{synopt:{cmd:nesttransaction: r(command_rc)}}wrapped command return code{p_end}
{synopt:{cmd:nesttransaction: r(rollback_rc)}}dataset rollback return code{p_end}
{synopt:{cmd:nestclear: r(files_deleted)}}snapshot files deleted{p_end}
{synopt:{cmd:nestrecover: r(adopted)}}whether a crashed stack was safely adopted{p_end}

{title:Compatibility}

{pstd}
NESTPRESERVE requires Stata 16 or newer.{p_end}

{title:Author}

{pstd}
Hao Ma, PhD{p_end}

{pstd}
Email: {browse "mailto:shouhuoxiwang2027@gmail.com":shouhuoxiwang2027@gmail.com}{p_end}

{title:Version}

{pstd}
1.0.0{p_end}

{title:License}

{pstd}
nestpreserve is free software licensed under the GNU General Public License version 3 (GPL-3.0).{p_end}
