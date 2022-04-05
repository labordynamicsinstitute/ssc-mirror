{smcl}
{* *! version 1.0  25mar2022}{...}
{vieweralsosee "twoway scatter" "help twoway scatter"}{...}
{viewerjumpto "Syntax" "waffle##syntax"}{...}
{viewerjumpto "Menu" "waffle##menu"}{...}
{viewerjumpto "Description" "waffle##description"}{...}
{viewerjumpto "Options" "waffle##options"}{...}
{viewerjumpto "Examples" "waffle##examples"}{...}
{viewerjumpto "Author" "waffle##author"}{...}
{viewerjumpto "Reference" "waffle##reference"}{...}

{p2colset 6 16 18 2}{...}
{p2col:{bf:waffle} {hline 2}}Draw waffle charts{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:waffle} {varlist} {ifin} [{cmd:,} {it:options}]

{synoptset 35 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Waffle Design}
{synopt :{opt wide}}change square shape to wide rectangle{p_end}
{synopt :{opt by(varlist)}}produce multiple waffle charts by categorical {varlist}{p_end}
{synopt :{opt color:s(colorlist)}}specify colors of each category separated by a space; default colors are Tableau palette{p_end}
{synopt :{opt empty:colors(colorlist)}}specify the color of empty squares; default is (gs14){p_end}
{synopt :{opt outl:inecolors(colorlist)}}specify the color of the square outlines; default is (none){p_end}
{synopt :{opt emptyoutl:inecolors(colorlist)}}specify the color of the empty square outlines; default is (none){p_end}
{synopt :{opt mark:ersize(numlist)}}change the size of the squares; defaults have been determined by other options specified{p_end}
{synopt :{opt sch:eme(schemename)}}set the scheme for your chart{p_end}

{syntab: Add Information}
{synopt :{opt t:itle(tinfo)}}overall title, can use title options from {opt twoway}{p_end}
{synopt :{opt n:ote(tinfo)}}include a note at the bottom of your chart{p_end}
{synopt :{opt name(tinfo)}}name your chart to reference later. Can be used the same way as twoway naming options{p_end}
{synopt :{cmdab:leg:end:(}[{it:{help legend_options##contents:contents}}] [{it:{help legend_options##location:location}}]{cmd:)}}include and format a legend; available only if multiple variables specified{p_end}

{syntab:Misc.}
{synopt :{opt cools:graph}}draw a Cool S Graph instead!!{p_end}
{synoptline}

{marker menu}{...}
{title:Menu}
{phang}{bf:Graphics > Twoway graph (scatter, line, etc.)}

{marker description}{...}
{title:Description}

{pstd}
{cmd:waffle} is a wrapper for {helpb twoway scatter} and draws waffle charts based on variables containing percents or decimals. The standard waffle chart will be a 10x10 grid with colored squares indicating the percent value; specifying 
{opt wide} will make the grid 5x20. 
If only one variable is listed in {varlist}, {opt by()} is allowed and will make a different waffle chart for each category of {opt by()}. You can specify up to 5 variables in {varlist} and indicate the colors of each category.
Other {opt twoway} options not listed here are not allowed because waffle charts rely on specific options of {opt twoway} being specified.

{marker options}{...}
{title:Options}

{dlgtab:Waffle Design}

{phang}
{opt wide} transforms the 10x10 grid default to a 5x20 grid for all waffles being drawn.

{phang}
{opt by(varlist)} produces a waffle chart for each category in {varlist}. This option is not allowed if more than one variable is listed in by() and is also not allowed with more than one percent/decimal specified. 
This feature will hopefully be resolved soon! If you would like multiple waffle charts with multiple color categories, I recommend drawing multiple individually and combining using {cmd: graph combine} or
the user-written command {opt grc1leg}. Can be used with select {cmd: twoway} {opt by()} options, such as {opt rows()}.

{phang}
{opt color:s(colorlist)} allows you to specify the colors of your percent/decimal variables. Colors will be assigned in order of your specified {varlist}. Default colors are based on the Tableau scheme from {opt schemepack}.

{phang}
{opt empty:colors(colorlist)} allows you to specify the colors of the "empty" squares in the waffle. The empty squares are all squares up to 100 not included in your defined percent/decimal variables. The default is {opt gs14}.

{phang}
{opt outl:inecolors(colorlist)} allows you to specify the outline colors of your filled in waffle squares. The default is {opt none}.

{phang}
{opt emptyoutl:inecolors(colorlist)} allows you to specify the outline colors of the "empty" squares in the waffle. This is separated from {opt outlinecolors} in the event that you would like to make the empty squares white with an outline, etc.

{phang}
{opt mark:ersize(numlist)} allows you to alter the size of the markers. The default sizes are based on other options, designed to adjust for number of categories in {opt by()} and whether or not {opt wide} is specified. The size is also dependent on the aspect ratio, which changes depending on the {opt wide} specification.

{phang}
{opt sch:eme(schemename)} allows you to change the scheme of the chart. Because other graph aspects, such as axes, are not allowed, this mostly determines the look of the background and the legend. 
A recommended scheme is {opt white_tableau} from {opt schemepack} (available on ssc).

{dlgtab:Add Information}

{phang}
{opt t:itle(tinfo)} allows you give your chart a title. If {opt by()} is specified, this will be the overall title, with individual waffle titles being identified by the value labels in {opt by(varlist)}.

{phang}
{opt n:ote(tinfo)} adds a note at the bottom left of the chart.

{phang}
{opt name(name [, replace])} gives the chart a name Stata will recognize, which is important if you would like to {opt combine} multiple graphs.

{phang}
{cmd:legend(}{it:{help legend_options##contents:contents}}{cmd:,} {it:{help legend_options##location:location}}{cmd:)} determines the look of a legend. All legend options allowed in {helpb twoway} are allowed here. 
This option is only available if multiple categories are specified.

{dlgtab:Misc.}

{phang}
{opt cools:graph} transports you back in time!

{marker examples}{...}
{title:Examples}

{pstd}{opt Example 1: Recreate example from Asjad Naqvi's original post}{p_end}

{pstd}First pull in data and create percent variables and other data cleaning{p_end}
{phang2}{cmd:. ssc install schemepack, replace}{p_end}
{phang2}{cmd:. set scheme white_tableau}{p_end}
{phang2}{cmd:. graph set window fontface "Arial Narrow"}{p_end}
{phang2}{cmd:. import delim using "https://covid.ourworldindata.org/data/owid-covid-data.csv", clear}{p_end}
{phang2}{cmd:. gen date2 = date(date, "YMD")}{p_end}
{phang2}{cmd:. format date2 %tdDD-Mon-yy}{p_end}
{phang2}{cmd:. drop date}{p_end}
{phang2}{cmd:. ren date2 date}{p_end}
{phang2}{cmd:. ren location country}{p_end}
{phang2}{cmd:. keep iso_code continent country date people_fully_vaccinated population}{p_end}
{phang2}{cmd:. keep if length(iso_code) > 3}{p_end}
{phang2}{cmd:. drop if inlist(iso_code,"OWID_KOS","OWID_CYN","OWID_HIC","OWID_LIC","OWID_LMC","OWID_UMC")}{p_end}
{phang2}{cmd:. bysort country: egen last = max(date) if people_fully_vaccinated != .}{p_end}
{phang2}{cmd:. keep if date == last}{p_end}
{phang2}{cmd:. summ date}{p_end}
{phang2}{cmd:. global dateval: di %tdd_m_y `r(max)'}{p_end}
{phang2}{cmd:. di "$dateval"}{p_end}
{phang2}{cmd:. gen share = people_fully_vaccinated / population}{p_end}
{phang2}{cmd:. gen country2 = country + " (" + string(share * 100, "%9.1f") + "%)"}{p_end}

{pstd} Now we can use the {opt waffle} command for the rest{p_end}
{phang2}{cmd:. waffle share,}{p_end}
{phang2}{cmd:. by(country2, rows(2)) markersize(2)}{p_end}
{phang2}{cmd:. title("{fontface Arial Bold:Share of population fully vaccinated}", margin(medlarge))}{p_end}
{phang2}{cmd:. note("Source: Our World in Data. Data updated: $dateval.")}{p_end}

{pstd}{opt Example 2: Using Stata's Census 2000 data to show whole range of waffle command}{p_end}

{pstd}First pull in and prep data{p_end}
{phang2}{cmd:. sysuse pop2000, clear}{p_end}
{pstd}create another category variable{p_end}
{phang2}{cmd:. gen small_age_cat = 0}{p_end}
{phang2}{cmd:. replace small_age_cat = 1 if inrange(agegrp,1,6)}{p_end}
{phang2}{cmd:. replace small_age_cat = 2 if inrange(agegrp,7,13)}{p_end}
{phang2}{cmd:. replace small_age_cat = 3 if inrange(agegrp,14,17)}{p_end}
{phang2}{cmd:. label define age_cat 1 "Under 30" 2 "30-64" 3 "65 & up"}{p_end}
{phang2}{cmd:. lab val small_age_cat age_cat}{p_end}
{pstd}create total percents, regardless of category{p_end}
{phang2}{cmd:. foreach x in black white asian total}{p_end}
{phang3}{cmd:. egen tot_`x' = sum(`x')}{p_end}
{phang2}{cmd:. gen pct_tot_black = tot_black / tot_total}{p_end}
{phang2}{cmd:. gen pct_tot_white = tot_white / tot_total}{p_end}
{phang2}{cmd:. gen pct_tot_asian = tot_asian / tot_total}{p_end}
{pstd}create percents based on two different age categories{p_end}
{phang2}{cmd:. egen small_age_tot_total = sum(total), by(small_age_cat)}{p_end}
{phang2}{cmd:. foreach x in white black asian}{p_end}
{phang3}{cmd:. gen pct_`x'_age = `x' / total}{p_end}
{phang3}{cmd:. egen small_age_tot_`x' = sum(`x'), by(small_age_cat)}{p_end}
{phang3}{cmd:. gen pct_`x'_small_age = small_age_tot_`x' / small_age_tot_total}{p_end}
{phang3}{cmd:. drop small_age_tot_`x'}{p_end}
{pstd}keep just categorical variables and percents{p_end}
{phang2}{cmd:. drop total-femisland tot_black-tot_total small_age_tot_total}{p_end}

{pstd}{opt Create a simple waffle chart of the total share of Black population in Census 2000}{p_end}
{phang2}{cmd:. waffle pct_tot_black}{p_end}
{pstd}try it in wide mode{p_end}
{phang2}{cmd:. waffle pct_tot_black, wide}{p_end}
{pstd}add a title with correct margins, a note, and change the colors, outlines, and size of the squares{p_end}
{phang2}{cmd:. waffle pct_tot_black, ///}{p_end}
{phang3}{cmd:. title("Share of Black U.S. population in 2000 Census", margin(medlarge)) ///}{p_end}
{phang3}{cmd:. note("Data from the U.S. 2000 Census") ///}{p_end}
{phang3}{cmd:. markersize(6) colors(teal) emptycolors(white) outlinecolors(gs5) emptyoutlinecolors(gs5)}{p_end}
{pstd}look at share of Black population by age group{p_end}
{phang2}{cmd:. waffle pct_black_age, by(agegrp)}{p_end}
{pstd}works with string category variables too{p_end}
{phang2}{cmd:. waffle pct_black_age, by(agestr)}{p_end}
{pstd}now smaller age group{p_end}
{phang2}{cmd:. waffle pct_black_small_age, by(small_age_cat)}{p_end}
{pstd}let's put them on one row{p_end}
{phang2}{cmd:. waffle pct_black_small_age, by(small_age_cat, rows(1))}{p_end}
{pstd}now add title, note, size and color adjustments{p_end}
{phang2}{cmd:. waffle pct_black_small_age, by(small_age_cat, rows(1)) ///}{p_end}
{phang3}{cmd:. title("Share of Black U.S. population in 2000 Census by Age", margin(medlarge)) ///}{p_end}
{phang3}{cmd:. note("Data from the U.S. 2000 Census") ///}{p_end}
{phang3}{cmd:. markersize(4) colors(teal) emptycolors(white) outlinecolors(gs5) emptyoutlinecolors(gs5)}{p_end}
{pstd}now look at a multi-waffle in wide mode{p_end}
{phang2}{cmd:. waffle pct_black_small_age, by(small_age_cat, rows(3)) ///}{p_end}
{phang3}{cmd:. title("Share of Black U.S. population in 2000 Census by Age", margin(medlarge)) ///}{p_end}
{phang3}{cmd:. note("Data from the U.S. 2000 Census") ///}{p_end}
{phang3}{cmd:. markersize(3) colors(teal) emptycolors(white) outlinecolors(gs5) emptyoutlinecolors(gs5) wide}{p_end}

{pstd}{opt Create a multi-category waffle chart}{p_end}
{phang2}{cmd:. waffle pct_tot_black pct_tot_white pct_tot_asian}{p_end}
{pstd}add a legend, title, note, size and color adjustments{p_end}
{phang2}{cmd:. waffle pct_tot_black pct_tot_white pct_tot_asian, ///}{p_end}
{phang3}{cmd:. title("Racial/ethnic composition of the U.S. in 2000", margin(medlarge)) ///}{p_end}
{phang3}{cmd:. note("Data from the U.S. 2000 Census") ///}{p_end}
{phang3}{cmd:. markersize(5) colors(ltblue teal navy) emptycolors(white) outlinecolors(gs5) emptyoutlinecolors(gs5) ///}{p_end}
{phang3}{cmd:. legend(order(1 "Black" 2 "White" 3 "Asian" 4 "Other") pos(6) rows(1))}{p_end}
{pstd}create this multi_category waffle for a specific age range{p_end}
{phang2}{cmd:. waffle pct_black_small_age pct_white_small_age pct_asian_small_age if small_age_cat == 1, ///}{p_end}
{phang3}{cmd:. title("Racial/ethnic composition of the U.S. in 2000 under age 30", margin(medlarge)) ///}{p_end}
{phang3}{cmd:. note("Data from the U.S. 2000 Census") ///}{p_end}
{phang3}{cmd:. markersize(5) colors(ltblue teal navy) emptycolors(white) outlinecolors(gs5) emptyoutlinecolors(gs5) ///}{p_end}
{phang3}{cmd:. legend(order(1 "Black" 2 "White" 3 "Asian" 4 "Other") pos(6) rows(1))}{p_end}
{pstd}try it in wide mode{p_end}
{phang2}{cmd:. waffle pct_black_small_age pct_white_small_age pct_asian_small_age if small_age_cat == 1, ///}{p_end}
{phang3}{cmd:. title("Racial/ethnic composition of the U.S. in 2000 under age 30", margin(medlarge)) ///}{p_end}
{phang3}{cmd:. note("Data from the U.S. 2000 Census") ///}{p_end}
{phang3}{cmd:. markersize(6) colors(ltblue teal navy) emptycolors(white) outlinecolors(gs5) emptyoutlinecolors(gs5) ///}{p_end}
{phang3}{cmd:. legend(order(1 "Black" 2 "White" 3 "Asian" 4 "Other") pos(6) rows(1)) wide}{p_end}
{pstd}store the charts and use graph combine to create a multi-waffle with multiple categories{p_end}
{phang2}{cmd:. preserve}{p_end}
{phang3}{cmd:. duplicates drop pct_black_small_age pct_white_small_age pct_asian_small_age small_age_cat, force}{p_end}
{phang3}{cmd:. forvalues i = 1/3}{p_end}
{pmore3}{cmd:. local l = small_age_cat[`i']}{p_end}
{pmore3}{cmd:. local lbe : value label small_age_cat}{p_end}
{pmore3}{cmd:. local title : label `lbe' `l'}{p_end}
{pmore3}{cmd:. waffle pct_black_small_age pct_white_small_age pct_asian_small_age if small_age_cat == `i', ///}{p_end}
{pmore3}{cmd:. title("`title'", margin(medsmall)) ///}{p_end}
{pmore3}{cmd:. note("Data from the U.S. 2000 Census") ///}{p_end}
{pmore3}{cmd:. markersize(3) colors(ltblue teal navy) emptycolors(white) outlinecolors(gs5) emptyoutlinecolors(gs5) ///}{p_end}
{pmore3}{cmd:. legend(order(1 "Black" 2 "White" 3 "Asian" 4 "Other") pos(6) rows(1)) wide name(waffle_`i', replace)}{p_end}
{phang2}{cmd:. restore}{p_end}
{phang2}{cmd:. graph combine waffle_1 waffle_2 waffle_3}{p_end}
{pstd}combine using a single legend with user-written grc1leg{p_end}
{phang2}{cmd:. ssc install grc1leg, replace}{p_end}
{phang2}{cmd:. grc1leg waffle_1 waffle_2 waffle_3, cols(1) imargin(zero) ///}{p_end}
{phang3}{cmd:. title("Racial/ethnic composition of the U.S. in 2000 by age")}{p_end}


{marker author}{...}
{title:Author}

{phang}
Jared Colston {p_end}
{phang}
Educational Leadership & Policy Analysis, University of Wisconsin-Madison {p_end}
{phang}
colston@wisc.edu {p_end}
{phang}
jaredcolston.com {p_end}
{phang}
March 2022 {p_end}

{marker reference}{...}
{title:Reference}

{phang}
Initial code for developing waffle charts in Stata come from Asjad Naqvi, found here: 
{p_end}
{phang}
https://medium.com/the-stata-guide/stata-graphs-waffle-charts-32afc7d6f6dd
{p_end}
