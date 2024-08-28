{smcl}
{vieweralsosee "opendf write" "help opendf write"}{...}
{vieweralsosee "opendf docu" "help opendf docu"}{...}
{viewerjumpto "Syntax" "opendf read##syntax"}{...}
{viewerjumpto "Options" "opendf read##options"}{...}
{viewerjumpto "Description" "opendf read##description"}{...}
{viewerjumpto "Remarks" "opendf read##remarks"}{...}
{viewerjumpto "Examples" "opendf read##examples"}{...}
help for  {cmd:opendf read (opendf_read)}{right: version 2.0.0 (27 August 2024)}
{hline}

{phang}
{bf:opendf read} {hline 2} builds a Stata dataset (.dta) from open data format dataset (.zip) {p_end}


{marker syntax}
{title:Syntax}

{p 8 17 2}
{cmd:opendf read} {it: input} [,{opt rowrange}([start][:end]) {opt colrange}([start][:end]) {opt clear} {opt save()} {opt replace} {opt verbose}]

{synoptset 20 tabbed}{...}
{marker options}{synopthdr:options}
{synoptline}
{synopt :{opt rowrange}([start][:end])}Indicates the range of rows to read. {p_end}
{synopt :{opt colrange}([start][:end])}Indicates the range of columns to read. {p_end}
{synopt :{opt clear}} Clears any existing datsaet in the memory. {p_end}
{synopt :{opt save(string)}} Save data to desired filepath and filename. {p_end}
{synopt :{opt replace}} Overwrite any existing file. {p_end}
{synopt :{opt verbose}} More warnings are displayed. {p_end}
{synoptline}


{marker description}
{title:Description}

{pstd}
{cmd:opendf read} Loads data from ODF file (zip-folder) into Stata including metadata saved in labels and characteristics. {p_end}

{pstd}
The dataset is stored in the format of the original dataset. Metadata is saved as labels or in the characteristics. {p_end}

{pstd}
{it: input} path to zip file or name of zip file in working directory.

{pstd}
{opt "rowrange([start][:end])"} specifies a range of rows within the data to load (excluding the header). {it: start} and {it: end} are integer row numbers.

{pstd}
{opt "colrange([start][:end])"} specifies a range of variables within the data to load.  {it: start} and {it: end} are integer column numbers.

{pstd}
{opt clear} specifies that it is okay to replace the data in memory, even though the current data have not been saved to disk.{p_end}

{pstd}
{opt replace} overwrite existing reshaped competency dataset.{break}
If option {opt replace} is specified, a former saved file will be overwritten.
{p_end}

{pstd}
{opt save} stores data to a desired filepath and filename.{break}
If option {opt replace} is specified, a former saved file will be overwritten.
{p_end}


{marker remarks}
{title:Remarks}

{pstd}This command from the opendf package is part of the Open Data Format Project bundle, written to assist with survey data files in the open data format(.zip).{p_end}
{pstd}Due to cross-plattform compability of the Open Data Format some Stata-specific features are not supported by the ODF.{p_end}
{pstd}There are no value label names in the ODF. Therefore, value label names are lost when a datset is written to ODF. Value labels reveice generic names when an ODF file is read in Stata.{p_end}
{pstd}Extended missings for numeric variables (.a, .b, ..., .z) are not available in ODF specification. Therefore, extended missings are converted to ordinary missings (.) {p_end}
{pstd}Value Labels of extended missings er not written to ODF file.{p_end}


{marker examples}
{title:Examples}

{phang}Read the opendf-file testdata.zip from "https://thartl-diw.github.io/opendf/testdata.zip" into Stata. The clear ensures, that the old dataset is removed from Stata cache.{p_end}
{phang}With the save()-option the dataset is saved as testdata.dta in the working directory. If it already exists, it testdata.dta is replaced, verbose option is set on.{p_end}
{phang}{cmd:. opendf read "https://thartl-diw.github.io/opendf/testdata.zip", clear save("testdata") replace verbose}{p_end}

{phang}Read the opendf-file testdata.zip from "https://thartl-diw.github.io/opendf/testdata.zip" into Stata. {opt clear} ensures, that the old dataset is removed from Stata cache.{p_end}
{phang}{cmd:. opendf read "https://thartl-diw.github.io/opendf/testdata.zip", clear}{p_end}

{phang}Read the first 10 lines of the opendf-file testdata.zip from "https://thartl-diw.github.io/opendf/testdata.zip" into Stata. Since the first line is also the header, the range has to be set to 11. {p_end}
{phang}{cmd:. opendf read "https://thartl-diw.github.io/opendf/testdata.zip", rowrange(:11)}{p_end}

{marker author}
{title:Author}

{pstd}
Tom Hartl ({browse "mailto:thartl@diw.de":thartl@diw.de}), Deutsches Institut für Wirtschaftsforschung Berlin. 


{marker alsosee}
{title:Also see}

{psee}
{space 2}Help: {help opendf write}, {help opendf docu}{p_end}
