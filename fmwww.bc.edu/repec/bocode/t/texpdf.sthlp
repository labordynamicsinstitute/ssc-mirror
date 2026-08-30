{smcl}
{* *! version 0.1.0 28aug2026}{...}
{title:Title}

{phang}
{bf:texpdf} {hline 2} compile a LaTeX document to PDF with a standalone embedded Tectonic engine

{title:Syntax}

{p 8 16 2}
{cmd:texpdf using} {it:filename.tex}
[{cmd:,} {opt saving(filename.pdf)} {opt replace} {opt view}]

{p 8 16 2}
{cmd:texpdf, version}

{title:Description}

{pstd}
{cmd:texpdf} compiles one complete LaTeX document. The released package contains
Tectonic and its supported TeX resources inside one native Stata plugin. No
system TeX installation or network connection is used at runtime.

{pstd}
Relative inputs, figures, and bibliography files are resolved from the primary
source directory. If {opt saving()} is omitted, a final {cmd:.tex} suffix is
replaced by {cmd:.pdf}; otherwise {cmd:.pdf} is appended.

{title:Requirements}

{pstd}
{cmd:texpdf} is tested with Stata 18 and 19. It does not require a system TeX
installation or another community-contributed Stata package. The optional
{cmd:latexlog} package is suggested for constructing reports and is used only
by Example 2 below. Example 3 uses Stata's built-in {cmd:etable} command.

{title:Options}

{phang}{opt saving(filename.pdf)} specifies the output PDF.

{phang}{opt replace} permits replacement of an existing output PDF.

{phang}{opt view} opens the PDF after successful compilation. It uses the
operating system's default PDF application. Failure to launch a viewer does not
remove or invalidate the compiled PDF.

{phang}{opt version} reports embedded engine and bundle metadata.

{marker examples}
{title:Examples}

{pstd}
Each example is self-contained and can be run with one click. Generated TeX,
table, figure, and PDF files remain under {cmd:./texpdf_examples/} for
inspection. Re-running an example replaces its earlier outputs.

{space 4}{hline 10} {it:Example 1 - Build a report with file write} {hline 23}
{cmd}{...}
{* example_start - manual}{...}
    local root "./texpdf_examples/manual"
    capture mkdir "./texpdf_examples"
    capture mkdir "`root'"

    sysuse auto, clear
    table foreign, statistic(mean price) statistic(mean mpg) nototals
    collect export "`root'/table.tex", as(tex) tableonly replace

    twoway scatter price mpg, mcolor(navy) ///
        title("Price and mileage") legend(off)
    graph export "`root'/price-mpg.pdf", replace

    tempname tex
    file open `tex' using "`root'/report.tex", write text replace
    file write `tex' "\documentclass{c -(}article{c )-}" _n
    file write `tex' "\usepackage{c -(}booktabs,graphicx{c )-}" _n
    file write `tex' "\title{c -(}A report constructed in Stata{c )-}" _n
    file write `tex' "\date{c -(}{c )-}" _n
    file write `tex' "\begin{c -(}document{c )-}" _n
    file write `tex' "\maketitle" _n
    file write `tex' "\section*{c -(}Summary table{c )-}" _n
    file write `tex' "\input{c -(}table.tex{c )-}" _n
    file write `tex' "\section*{c -(}Figure{c )-}" _n
    file write `tex' "\begin{c -(}figure{c )-}[htbp]" _n
    file write `tex' "\centering" _n
    file write `tex' "\includegraphics[width=.75\textwidth]{c -(}price-mpg.pdf{c )-}" _n
    file write `tex' "\caption{c -(}Price and mileage in the auto data{c )-}" _n
    file write `tex' "\end{c -(}figure{c )-}" _n
    file write `tex' "\end{c -(}document{c )-}" _n
    file close `tex'

    texpdf using "`root'/report.tex", ///
        saving("`root'/report.pdf") replace view
{* example_end}{...}
{txt}{...}
{space 4}{hline 80}
{space 4}{it:({stata texpdf_run manual using texpdf.sthlp, preserve:click to run and open the PDF})}

{space 4}{hline 10} {it:Example 2 - Build a report with latexlog} {hline 22}
{pstd}
This example uses the suggested but optional {help latexlog} package to create
the document. The document is compiled by {cmd:texpdf}.

{cmd}{...}
{* example_start - latexlog}{...}
    capture which latexlog
    if _rc {c -(}
        display as error "Example 2 requires the optional latexlog package."
        display as text `"net install latexlog, replace from("https://raw.githubusercontent.com/johannes-schmieder/latexlog/v0.5.0/")"'
        exit 499
    {c )-}

    local root "./texpdf_examples/latexlog"
    capture mkdir "./texpdf_examples"
    capture mkdir "`root'"
    local report "`root'/report.tex"

    latexlog `report': open, replace
    latexlog `report': title "A report constructed with latexlog"
    latexlog `report': section "Wages and experience"
    latexlog `report': writeln "The document is created by latexlog and compiled by texpdf."

    sysuse nlsw88, clear
    scatter wage ttl_exp, mcolor(navy) ///
        title("Wage and experience") legend(off)
    latexlog `report': addfig, filename(figures/wage-experience.pdf) ///
        float title(Wage and total experience) ///
        notes(Source: Stata nlsw88 example data.) width(.75)

    table occupation union, nototals
    latexlog `report': collect export, ///
        title(Occupation and union status) booktabs novert threeparttable ///
        notes(Source: Stata nlsw88 example data.)
    latexlog `report': close

    texpdf using "`report'", ///
        saving("`root'/report.pdf") replace view
{* example_end}{...}
{txt}{...}
{space 4}{hline 80}
{space 4}{it:({stata texpdf_run latexlog using texpdf.sthlp, preserve:click to run and open the PDF})}

{space 4}{hline 10} {it:Example 3 - Build a regression table with etable} {hline 12}
{pstd}
This example estimates three nested models and uses Stata's built-in
{help etable} command to create a publication-style regression table.

{cmd}{...}
{* example_start - etable}{...}
    local root "./texpdf_examples/etable"
    capture mkdir "./texpdf_examples"
    capture mkdir "`root'"

    sysuse auto, clear
    label variable price "Price"
    label variable mpg "Mileage (mpg)"
    label variable weight "Weight (lbs.)"
    label variable foreign "Foreign car"

    estimates clear
    quietly regress price mpg
    estimates store model1
    quietly regress price mpg weight
    estimates store model2
    quietly regress price mpg weight foreign
    estimates store model3

    etable, estimates(model1 model2 model3) column(index) ///
        keep(mpg weight foreign _cons) ///
        cstat(_r_b, nformat(%9.2f)) ///
        cstat(_r_se, nformat(%9.2f)) ///
        mstat(N, label("Observations")) ///
        mstat(r2_a, label("Adjusted R-squared") nformat(%9.3f)) ///
        stars(.10 "*" .05 "**" .01 "***") showstars showstarsnote ///
        title("Price regressions") ///
        note("Dependent variable: price. Standard errors in parentheses.") ///
        export("`root'/regression-table.tex", tableonly replace)

    tempname tex
    file open `tex' using "`root'/report.tex", write text replace
    file write `tex' "\documentclass{c -(}article{c )-}" _n
    file write `tex' "\usepackage[margin=1in]{c -(}geometry{c )-}" _n
    file write `tex' "\begin{c -(}document{c )-}" _n
    file write `tex' "\input{c -(}regression-table.tex{c )-}" _n
    file write `tex' "\end{c -(}document{c )-}" _n
    file close `tex'

    texpdf using "`root'/report.tex", ///
        saving("`root'/report.pdf") replace view
{* example_end}{...}
{txt}{...}
{space 4}{hline 80}
{space 4}{it:({stata texpdf_run etable using texpdf.sthlp, preserve:click to run and open the PDF})}

{title:Stored results}

{synoptset 24 tabbed}{...}
{synopt:{cmd:r(pdf)}}absolute output PDF path after compilation{p_end}
{synopt:{cmd:r(engine)}}{cmd:tectonic}{p_end}
{synopt:{cmd:r(engine_version)}}embedded Tectonic version{p_end}
{synopt:{cmd:r(bundle_version)}}embedded resource-bundle version{p_end}
{synopt:{cmd:r(bundle_digest)}}Tectonic bundle content digest{p_end}
{synopt:{cmd:r(bundle_zip_sha256)}}SHA-256 of the embedded ZIP{p_end}
{synopt:{cmd:r(warnings)}}number of warning diagnostics{p_end}

{title:Remarks}

{pstd}
Version 1 is a compiler only. Shell escape and arbitrary external helper
programs are disabled. This version provides English-language hyphenation and
internal BibTeX.

{pstd}
The bundled LaTeX package, class, and bibliography-style interfaces are:

{p 4 8 2}
{cmd:adjcalc.sty}, {cmd:adjustbox.sty}, {cmd:aer.bst}, {cmd:amsbsy.sty},
{cmd:amsfonts.sty}, {cmd:amsgen.sty}, {cmd:amsmath.sty}, {cmd:amsopn.sty},
{cmd:amssymb.sty}, {cmd:amstext.sty}, {cmd:array.sty}, and {cmd:article.cls}.

{p 4 8 2}
{cmd:atbegshi-ltx.sty}, {cmd:atbegshi.sty}, {cmd:atveryend-ltx.sty},
{cmd:atveryend.sty}, {cmd:auxhook.sty}, {cmd:bigintcalc.sty}, {cmd:bitset.sty},
{cmd:booktabs.sty}, {cmd:calc.sty}, {cmd:caption.sty}, {cmd:caption3.sty}, and
{cmd:cleveref.sty}.

{p 4 8 2}
{cmd:collectbox.sty}, {cmd:color.sty}, {cmd:colortbl.sty}, {cmd:dcolumn.sty},
{cmd:enumitem.sty}, {cmd:environ.sty}, {cmd:etexcmds.sty}, {cmd:etoolbox.sty},
{cmd:expl3.sty}, {cmd:fancyhdr.sty}, {cmd:float.sty}, and {cmd:geometry.sty}.

{p 4 8 2}
{cmd:gettitlestring.sty}, {cmd:graphics.sty}, {cmd:graphicx.sty},
{cmd:hycolor.sty}, {cmd:hyperref.sty}, {cmd:ifoddpage.sty}, {cmd:iftex.sty},
{cmd:ifthen.sty}, {cmd:ifvtex.sty}, {cmd:infwarerr.sty}, {cmd:intcalc.sty}, and
{cmd:keyval.sty}.

{p 4 8 2}
{cmd:kvdefinekeys.sty}, {cmd:kvoptions.sty}, {cmd:kvsetkeys.sty},
{cmd:l3keys2e.sty}, {cmd:letltxmacro.sty}, {cmd:lmodern.sty},
{cmd:longtable.sty}, {cmd:lscape.sty}, {cmd:ltcaption.sty}, {cmd:ltxcmds.sty},
{cmd:mathtools.sty}, and {cmd:mhsetup.sty}.

{p 4 8 2}
{cmd:microtype.sty}, {cmd:multirow.sty}, {cmd:nameref.sty}, {cmd:natbib.sty},
{cmd:pdfescape.sty}, {cmd:pdflscape.sty}, {cmd:pdftexcmds.sty},
{cmd:placeins.sty}, {cmd:plainnat.bst}, {cmd:refcount.sty},
{cmd:rerunfilecheck.sty}, and {cmd:rotating.sty}.

{p 4 8 2}
{cmd:setspace.sty}, {cmd:siunitx.sty}, {cmd:stringenc.sty},
{cmd:subcaption.sty}, {cmd:subfigure.sty}, {cmd:tabularx.sty},
{cmd:threeparttable.sty}, {cmd:threeparttablex.sty}, {cmd:titlesec.sty},
{cmd:translations.sty}, {cmd:trig.sty}, and {cmd:trimclip.sty}.

{p 4 8 2}
{cmd:trimspaces.sty}, {cmd:uniquecounter.sty}, {cmd:url.sty},
{cmd:varwidth.sty}, {cmd:xcolor.sty}, and {cmd:xkeyval.sty}.

{title:Acknowledgements}

{pstd}
This package is only possible due to the amazing work of the
{browse "https://tectonic-typesetting.github.io/":Tectonic project} and its
contributors. Tectonic makes the formidable TeX ecosystem available as a
modern, embeddable, and reproducible engine. {cmd:texpdf} is a small Stata
bridge and distribution layer built on top of that achievement. I am deeply
grateful to everyone who has designed, maintained, documented, and tested
Tectonic and the upstream TeX software on which it builds.

{title:Also see}

{p 0 21}
Online: {help table}, {help collect export}, {help graph export}, {help latexlog}, {help etable}
{p_end}

{title:Author}

{pstd}Johannes Schmieder

{pstd}
Website: {browse "https://johannes-schmieder.com/":johannes-schmieder.com}
{break}GitHub: {browse "https://github.com/johannes-schmieder":johannes-schmieder}
{break}Email: {browse "mailto:johannes@bu.edu":johannes@bu.edu}

{pstd}Suggestions welcome.
