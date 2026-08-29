// ============================================================================
// latexlog Test Suite
// ============================================================================
// This file provides comprehensive tests for all latexlog subcommands and options.
// Run with: do latexlog_test.do
// ============================================================================

version 18
program drop _all
which latexlog

set more off

capture mata: mata drop _latexlog_test_filesize()
mata:
real scalar _latexlog_test_filesize(string scalar path)
{
    real scalar fh, bytes

    fh = fopen(path, "r")
    fseek(fh, 0, 1)
    bytes = ftell(fh)
    fclose(fh)
    return(bytes)
}
end

cap mkdir ./log/

// ============================================================================
// SECTION 1: Document Structure Tests (open/close with all options)
// ============================================================================

local log ./log/logtest.tex

// Test: open with custom geometry, predocopen, and postdocopen options
latexlog `log': open, ///
	geometry(lmargin=2.5cm,rmargin=2.5cm,tmargin=2cm,bmargin=2cm) ///
	predocopen(\newcommand{\testnote}[1]{\textit{Note: #1}}) ///
	postdocopen(\noindent)

// ============================================================================
// SECTION 2: Text Element Tests (title, section, sections, subsection, writeln)
// ============================================================================

latexlog `log': title "Comprehensive Test of the latexlog Package"
latexlog `log': writeln "This document tests all latexlog subcommands and options."
latexlog `log': writeln ""

// Test: section (numbered)
latexlog `log': section "Introduction (Numbered Section)"
latexlog `log': writeln "This is a numbered section created with the \textbf{section} subcommand."

// Test: sections (unnumbered)
latexlog `log': sections "Background (Unnumbered Section)"
latexlog `log': writeln "This is an unnumbered section created with the \textbf{sections} subcommand."
latexlog `log': writeln "Note that this section does not have a number in the output."

// Test: subsection
latexlog `log': subsection "A Subsection"
latexlog `log': writeln "This is a subsection created with the \textbf{subsection} subcommand. \\\\"

// Test custom command from predocopen
latexlog `log': subsection "Test Custom Command defined in predocopen"
latexlog `log': writeln "\testnote{This note uses the custom command defined in predocopen.}"
latexlog `log': writeln ""

// ============================================================================
// SECTION 3: Figure Tests (addfig with all options)
// ============================================================================

latexlog `log': section "Figure Tests"

sysuse nlsw88, clear

// Test: addfig with float (standard usage)
latexlog `log': subsection "Figure with Float Environment"
scatter wage ttl_exp
latexlog `log': addfig, filename(./figures/scatter_wage_float.pdf) ///
	float title(Wage vs. Experience - Float Environment) ///
	notes(Based on nlsw88.dta data) width(.8)

// Test: addfig WITHOUT float (inline)
latexlog `log': subsection "Figure Inline (No Float)"
latexlog `log': writeln "The following figure is inline (no float environment):"
scatter hours ttl_exp
latexlog `log': addfig, filename(./figures/scatter_hours_inline.pdf) ///
	width(.4) eol

// Test: addfig with notes(, center)
latexlog `log': subsection "Figure with Centered Notes"
scatter tenure ttl_exp
latexlog `log': addfig, filename(./figures/scatter_tenure_centered.pdf) ///
	float title(Tenure vs. Experience) ///
	notes(These notes are centered below the figure, center) width(.75)

// Test: addfig with title(, tabular)
latexlog `log': subsection "Figure with Title in Tabular"
scatter grade ttl_exp
latexlog `log': addfig, filename(./figures/scatter_grade_tabular.pdf) ///
	float title(Grade vs. Experience - Title in Tabular Format, tabular) ///
	notes(Using title tabular sub-option) width(.75)

// Test: another floating figure
latexlog `log': subsection "Another Floating Figure"
scatter wage tenure
latexlog `log': addfig, filename(./figures/scatter_wage_tenure.pdf) ///
	float title(Wage vs. Tenure) width(.7)

// ============================================================================
// SECTION 4: Subfigure Tests (all options)
// ============================================================================

latexlog `log': section "Subfigure Tests"

// Test: Basic subfigure usage
latexlog `log': subsection "Basic Subfigures"
latexlog `log': subfigure, open ///
	title(Four Variables vs. Experience - Basic Subfigures)
foreach var in wage hours tenure grade {
	scatter `var' ttl_exp, ylabel(,angle(vertical))
	local cap : variable label `var'
	latexlog `log': subfigure, addfig filename(./figures/subfig_`var'.pdf) ///
		caption("`cap' vs. experience") width(.45)
}
latexlog `log': subfigure, close notes(Based on nlsw88.dta data)

// Test: subfigure with notes(, center)
latexlog `log': subsection "Subfigures with Centered Notes"
latexlog `log': subfigure, open ///
	title(Two Variables - Centered Notes)
foreach var in wage hours {
	scatter `var' ttl_exp
	local cap : variable label `var'
	latexlog `log': subfigure, addfig filename(./figures/subfig_centered_`var'.pdf) ///
		caption("`cap'") width(.45)
}
latexlog `log': subfigure, close notes(These notes are centered, center)

// Test: subfigure with title(, tabular)
latexlog `log': subsection "Subfigures with Title in Tabular"
latexlog `log': subfigure, open ///
	title(Subfigure Example with Tabular Title - This is particularly useful for Figures with very long titles so that the title breaks nicely over multiple lines, tabular)
foreach var in tenure grade {
	scatter `var' ttl_exp
	local cap : variable label `var'
	latexlog `log': subfigure, addfig filename(./figures/subfig_tabular_`var'.pdf) ///
		caption("`cap'") width(.45)
}
latexlog `log': subfigure, close notes(Title uses tabular formatting)

// Test: subfigure with eol
latexlog `log': subsection "Subfigures with EOL"
latexlog `log': subfigure, open ///
	title(Two-Row Subfigure Layout Using EOL)
scatter wage ttl_exp
latexlog `log': subfigure, addfig filename(./figures/subfig_eol1.pdf) ///
	caption("Wage - Row 1") width(.45)
scatter hours ttl_exp
latexlog `log': subfigure, addfig filename(./figures/subfig_eol2.pdf) ///
	caption("Hours - Row 1") width(.45) eol
scatter tenure ttl_exp
latexlog `log': subfigure, addfig filename(./figures/subfig_eol3.pdf) ///
	caption("Tenure - Row 2") width(.45)
scatter grade ttl_exp
latexlog `log': subfigure, addfig filename(./figures/subfig_eol4.pdf) ///
	caption("Grade - Row 2") width(.45)
latexlog `log': subfigure, close notes(Using eol to create two rows)

latexlog `log': writeln "\clearpage\pagebreak"

// ============================================================================
// SECTION 5: Table/Collection Tests (collect with all options)
// ============================================================================

latexlog `log': section "Table and Collection Tests"

// Test: Basic table with booktabs and novert
latexlog `log': subsection "Basic Table Export"
table occupation union, nototals
latexlog `log': collect export, ///
	title(Occupation by Union Status - Basic) ///
	booktabs novert notes(Command: table occupation union, nototals) threeparttable

// Test: collect with fontsize
latexlog `log': subsection "Table with Custom Font Size"
table race married, nototals
latexlog `log': collect export, ///
	title(Race by Marital Status - Font Size 10) ///
	booktabs novert fontsize(10) threeparttable ///
	notes(Using fontsize(10) option)

// Test: collect with landscape
latexlog `log': subsection "Table in Landscape Mode and using Tabularx (Auto-width Columns)"
table occupation industry, nototals
latexlog `log': collect export, ///
	title(Occupation by Industry - Landscape Mode and using Tabularx (Auto-width Columns)) ///
	booktabs novert landscape threeparttable ///
	tabularx( 2 3 4 5 6 7 8 9 10 11 12 13, width(1.5\textwidth)) ///
	notes(This table is displayed in landscape orientation and uses tabularx to automatically wrap the columns)

// Test: Regression table with etable
latexlog `log': subsection "Regression Table with etable"
g logwage = log(wage)
label var logwage "Log Wage"
capture which etable
if !_rc {
	estimates clear
	qui: regress logwage ttl_exp
	estimates store model1
	qui: regress logwage ttl_exp grade married
	estimates store model2
	qui: regress logwage ttl_exp grade married tenure
	estimates store model3
	etable, estimates(model1 model2 model3) mstat(N) mstat(r2_a)
	latexlog `log': collect export, ///
		title(Regression Results - Three Models) ///
		booktabs novert threeparttable ///
		notes(Dependent variable: log(wage). Standard errors in parentheses.)
}
else {
	latexlog `log': writeln "\textit{Note: etable unavailable. Skipping etable integration test.}"
}

// Test: esttab integration (if available)
capture which esttab
if !_rc {
	latexlog `log': subsection "Integration with esttab"
	latexlog `log': writeln "The following table uses esttab to append directly to the log file:"
	latexlog `log': writeln "\vspace{10pt}"
	eststo clear
	eststo: regress logwage ttl_exp
	eststo: regress logwage ttl_exp grade
	esttab using `log', booktabs append float ///
		title(`"Regression Table via esttab (direct append)"')
	latexlog `log': writeln ""
	latexlog `log': writeln "\vspace{10pt}"
}
else {
	latexlog `log': writeln "\textit{Note: esttab not installed. Skipping esttab integration test.}"
}

// ============================================================================
// SECTION 6: Close with predocclose option
// ============================================================================

latexlog `log': section "Document Conclusion"
latexlog `log': writeln "This concludes the comprehensive test of the latexlog package."
latexlog `log': writeln "All subcommands and major options have been exercised."

// Test: close with predocclose option
latexlog `log': close, predocclose(\vfill\noindent\textit{End of test document.})

// ============================================================================
// SECTION 7: PDF Compilation
// ============================================================================

latexlog `log': pdf

capture confirm file "./log/logtest.pdf"
if _rc {
	di as error "latexlog integration test did not create log/logtest.pdf"
	exit 9
}
mata: st_local("pdfbytes", strofreal(_latexlog_test_filesize("./log/logtest.pdf")))
if `pdfbytes' <= 0 {
	di as error "latexlog integration test created an empty PDF"
	exit 9
}
di as result "LATEXLOG_INTEGRATION_TEST_PASS"

// ============================================================================
// End of Test Suite
// ============================================================================
