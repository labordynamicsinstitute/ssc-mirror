{smcl}
{vieweralsosee "opendf read" "help opendf read"}{...}
{vieweralsosee "opendf write" "help opendf write"}{...}
{vieweralsosee "opendf docu" "help opendf docu"}{...}
{viewerjumpto "Syntax" "opendf##functions"}{...}
{viewerjumpto "Description" "opendf##description"}{...}
{viewerjumpto "Remarks" "opendf##remarks"}{...}
help for {cmd:opendf}{right: version 2.0.2 (28 August 2024)}
{hline}

{phang}
{bf:opendf} {hline 2} Stata package to work with Open Data Format files (ODF/.zip). Provides import end export filters for ODF files and a function to display metadata.{p_end}

{marker functions}{...}
{title:Functions and Syntax}
{p} {bf:Main Functions}{p_end}

    Read data

{p 8 16 2}{cmd:opendf} {cmd:read} {it:input} [,{opt rowrange()} {opt colrange()} {opt clear} {opt save()} {opt replace} {opt verbose}]


    Write data

{p 8 16 2}{cmd:opendf} {cmd:write} {it:output} [,{opt input()} {opt languages()} {opt variables()} {opt verbose}]


    Display metadata of dataset or variable

{p 8 16 2}{cmd:opendf} {cmd:docu} [{it: varname}, {opt languages()}]


{p} {bf:Functions to Install/Remove Python for Opendf Package}{p_end}

    Download a portable Python version for a working Python integration in Stata for the opendf package.

{p 8 16 2}{cmd:opendf} {cmd:installpython} [, {opt version()} {opt location()}]


    Delete the portable Python version installed with opendf installpython.

{p 8 16 2}{cmd:opendf} {cmd:removepython} [, {opt version()} {opt location()}]


{p}{bf:Functions for Data Providers}{p_end}

    Build a Stata dataset (.dta) with metadata from the opendf specification from csv files containing meta data for survey data.

{p 8 16 2}{cmd:opendf} {cmd:csv2dta} , {opt csv_loc()} [{opt rowrange}([start][:end]) {opt colrange}([start][:end])} {opt clear} {opt save()} {opt replace} {opt verbose}]


    Write data in open data format (.zip) from csv files containing meta data for survey data.

{p 8 16 2}{cmd:opendf} {cmd:csv2zip}, {opt output()} [{opt input()} {opt variables_arg()} {opt export_data()} {opt verbose}]


    Write four CSV-files with data and meta data from Stata ODF dataset.

{p 8 16 2}{cmd:opendf} {cmd:dta2csv}, {opt output_dir()} [{opt languages()} {opt input()}]


    Write four CSV-files with data and meta data from ODF zip-file.

{p 8 16 2}{cmd:opendf} {cmd:zip2csv}, {opt input_zip()} {opt output_dir()} {opt languages()} [{opt verbose}]


{marker description}{...}
{title:Description}

{pstd}
{cmd:opendf read} {hline 2} builds a Stata dataset (.dta) from open data format dataset (.zip) {p_end}
{pstd}
{cmd:opendf write} {hline 2} Saves data in the opendf-format as opendf-zip folder containing a csv(data) and a xml(metadate) file.{p_end}
{pstd}
{cmd:opendf docu} {hline 2} Display information about the dataset or a variable. {p_end}
{pstd}
{cmd:opendf installpython} {hline 2} Downloads a portable Python installation to some directory (default: Stata ado plus folder) on your computer. {p_end}
{pstd}
{cmd:opendf removepython} {hline 2} Removes portable Python that was installed with opendf installpython. {p_end}
{pstd}
{cmd:opendf csv2dta} {hline 2} Build a Stata dataset (.dta) with metadata from the opendf specification from four csv files containing meta data for survey data. {p_end}
{pstd}
{cmd:opendf csv2zip} {hline 2}  Write data in open data format (.zip) from four csv files containing meta data for survey data. {p_end}
{pstd}
{cmd:opendf dta2csv} {hline 2} Write four CSV-files containing meta data for survey data from Stata ODF dataset. {p_end}
{pstd}
{cmd:opendf zip2csv} {hline 2}  Write four CSV-files containing meta data for survey data from ODF zip-file. {p_end}


{marker remarks}
{title:Remarks}

{pstd}The opendf commands in the opendf package from the Open Data Format Project are written to assist with survey data files in the open data format (ODF/.zip).{p_end}
{pstd}Due to cross-plattform compability of the Open Data Format some Stata-specific features are not supported by the ODF.{p_end}
{pstd}There are no value label names in the ODF. Therefore, value label names are lost when a datset is written to ODF. Value labels reveice generic names when an ODF file is read in Stata.{p_end}
{pstd}Extended missings for numeric variables (.a, .b, ..., .z) are not available in ODF specification. Therefore, extended missings are converted to ordinary missings (.) {p_end}
{pstd}Value Labels of extended missings er not written to ODF file.{p_end}


{marker author}
{title:Author}

{pstd}
Tom Hartl ({browse "mailto:thartl@diw.de":thartl@diw.de}), Deutsches Institut für Wirtschaftsforschung Berlin. 


{marker alsosee}
{title:Also see}

{psee}
{space 2}Help: {help opendf read}, {help opendf write}, {help opendf docu}, {help opendf installPython}, {help opendf removePython} {help opendf csv2dta}, {help opendf csv2zip}, {help opendf dta2csv}, {help opendf zip2csv} {p_end}
