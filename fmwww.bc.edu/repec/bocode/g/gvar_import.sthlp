{smcl}
{* *! version 1.0.1  21aug2026}{...}
{vieweralsosee "gvar" "help gvar"}{...}
{vieweralsosee "gvar setup" "help gvar_setup"}{...}
{vieweralsosee "gvar datasets" "help gvar_datasets"}{...}
{vieweralsosee "gvar weights" "help gvar_weights"}{...}
{vieweralsosee "gvar dominant" "help gvar_dominant"}{...}
{viewerjumpto "Syntax" "gvar_import##syntax"}{...}
{viewerjumpto "Description" "gvar_import##description"}{...}
{viewerjumpto "Options" "gvar_import##options"}{...}
{viewerjumpto "The workbook layout" "gvar_import##layout"}{...}
{viewerjumpto "Remarks" "gvar_import##remarks"}{...}
{viewerjumpto "Examples" "gvar_import##examples"}{...}
{viewerjumpto "Stored results" "gvar_import##results"}{...}
{title:Title}

{phang}
{bf:gvar import} {hline 2} read a GVAR Toolbox 2.0 data workbook into a long panel


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:gvar import} {cmd:using} {it:filename} [{cmd:,} {it:options}]

{synoptset 34 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt dom:estic(varlist)}}the domestic variables, one worksheet each.{p_end}
{synopt:{opt glo:bal(varlist)}}the global variables, one worksheet each with a single data column.{p_end}
{synopt:{opt unit(name)}}name for the unit identifier. Default {cmd:country}.{p_end}
{synopt:{opt time(name)}}name for the time identifier. Default {cmd:period}.{p_end}
{synopt:{opt sheet:s(string)}}{it:var=sheet} pairs, where a worksheet title differs from the variable name.{p_end}
{synopt:{opt freq:uency(string)}}{cmd:quarterly}, {cmd:monthly}, {cmd:yearly} or {cmd:none}.{p_end}
{synopt:{opt clear}}replace the data in memory.{p_end}
{synopt:{opt nosum:mary}}suppress the report.{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:gvar import} reads a GVAR Toolbox workbook and turns it into the long
panel that {helpb gvar_setup:gvar setup} expects. It exists so that a Toolbox
dataset can be brought over without being retyped or reshaped by hand.

{pstd}
It is a data-preparation command. It does not declare a model; run
{helpb gvar_setup:gvar setup} afterwards, and the report tells you the exact
command to type.


{marker layout}{...}
{title:The workbook layout}

{pstd}
The Toolbox keeps its data {bf:one worksheet per variable}, with countries
across the columns and dates down column A:

{p 8 8 2}{it:row 1} {space 6}a header of country codes{p_end}
{p 8 8 2}{it:column A} {space 4}the dates, from row 2 down{p_end}

{pstd}
That is the transpose of what every Stata command wants, which is one row per
{it:(unit, period)}. So each sheet is read, reshaped long, and merged on
{it:(unit, period)}.

{pstd}
A {bf:global} variable has one data column rather than one per country, since
it is the same series for every unit. Those sheets are merged {it:m:1} on the
time identifier instead.


{marker options}{...}
{title:Options}

{phang}
{opt domestic(varlist)} names the domestic variables. Each becomes one
worksheet read and one variable in the result. Required in practice: with none
given there is nothing to read.

{phang}
{opt global(varlist)} names the global variables -- oil and commodity prices in
the standard Toolbox setup. Each is expected to have a single data column.

{phang}
{opt unit(name)} and {opt time(name)} name the two panel identifiers that get
created. The defaults, {cmd:country} and {cmd:period}, are what the shipped
examples use.

{phang}
{opt sheets(string)} maps a variable name onto a worksheet title when the two
differ, as {it:var=sheet} pairs separated by spaces. Without it the worksheet
title must equal the variable name.

{phang}
{opt frequency(string)} says how to read column A. {cmd:quarterly} parses the
Toolbox's own {it:YYYYQn} form, {cmd:monthly} parses {it:YYYYMnn},
{cmd:yearly} reads a year, and {cmd:none} keeps the sheet's own row order as a
running index.

{phang}
{opt clear} is required if there are unsaved data in memory, exactly as for
{helpb use}.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:A partly parsed date column is refused, not patched.} The Toolbox writes
column A in whatever form Excel handed it -- a real Excel serial number, a
string like {it:1979Q2}, or a plain running index -- so each form is tried and
the one that parses {bf:every} row wins. A column that parses for only some
rows would silently reorder the panel, which is far worse than an error, so it
exits instead and suggests {cmd:frequency(none)}.

{pstd}
{bf:Missing values after the merge are counted and reported.} A country
present in one sheet and absent from another leaves gaps once the sheets are
merged. That is precisely the case that goes on to estimate and solve without
complaint, so the report states how many gaps there are and in which
variables. A ragged panel is legal -- {helpb gvar_setup:gvar setup} accepts it
and {helpb gvar_estimate:gvar estimate} works around it unit by unit -- but it
is something to check rather than discover later in the fit.

{pstd}
{bf:Sheets that could not be read are named.} They are listed rather than
skipped quietly, with a reminder that {opt sheets()} exists for the case where
worksheet titles do not match variable names.

{pstd}
{bf:Verification.} The import was checked against the shipped
{cmd:gvar_demo26} data, which came from the same Toolbox workbook by a
different route: all nine series agree to {it:0.0000e+00} over the 3400 shared
rows. The 1088 import-only rows are the eight individual euro-area members,
and the 136 reference-only rows are the aggregate that replaces them -- which
is a difference in how the region is treated, not a discrepancy in the data.


{marker examples}{...}
{title:Examples}

{pstd}
The standard Toolbox workbook, quarterly, with three global variables:{p_end}
{phang2}{cmd:. gvar import using "GVAR_Data.xls", domestic(y Dp eq ep r lr) global(poil pmat pmetal) frequency(quarterly) clear}{p_end}
{phang2}{cmd:. gvar setup y Dp eq ep r lr, unit(country) time(period) global(poil pmat pmetal)}{p_end}

{pstd}
Where two worksheet titles do not match the variable names:{p_end}
{phang2}{cmd:. gvar import using "GVAR_Data.xls", domestic(y Dp eq) global(poil) sheets(Dp=inflation poil=oilprice) frequency(quarterly) clear}{p_end}

{pstd}
Keeping the sheet's own row order, when column A is not a date at all:{p_end}
{phang2}{cmd:. gvar import using "mydata.xlsx", domestic(y Dp) frequency(none) clear}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gvar import} stores the following in {cmd:r()}:

{synoptset 26 tabbed}{...}
{synopt:{cmd:r(nunits)}}units found{p_end}
{synopt:{cmd:r(nperiods)}}periods spanned{p_end}
{synopt:{cmd:r(nsheets)}}domestic sheets successfully read{p_end}
{synopt:{cmd:r(nmissing)}}missing values left by the merge{p_end}
{synopt:{cmd:r(units)}}the unit identifiers{p_end}
{synopt:{cmd:r(notread)}}sheets that could not be read{p_end}
{synoptline}


{marker source}{...}
{title:Source}

{pstd}
Toolbox {it:gvar.m}:191, the {cmd:xlsread} calls and the {it:'A2:A65536'}
range that skips the header row.

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
