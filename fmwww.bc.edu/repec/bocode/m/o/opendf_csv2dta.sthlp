{smcl}
{vieweralsosee "opendf_read" "help opendf_read"}{...}
{vieweralsosee "opendf_write" "help opendf_write"}{...}
{vieweralsosee "opendf_docu" "help opendf_docu"}{...}
{vieweralsosee "opendf_csv2zip" "help opendf_csv2zip"}{...}
{viewerjumpto "Syntax" "opendf_csv2dta##syntax"}{...}
{viewerjumpto "Options" "opendf_csv2dta##options"}{...}
{viewerjumpto "Description" "opendf_csv2dta##description"}{...}
{viewerjumpto "Examples" "opendf_csv2dta##examples"}{...}
help for {cmd:opendf csv2dta (opendf_csv2dta)}{right: version 2.0.21 (28 August 2024)}
{hline}

{phang}
{bf:opendf_csv2dta} {hline 2} builds a Stata dataset (.dta) from csv files containing meta data for survey data. {p_end}


{marker syntax}
{title:Syntax}
{p 8 17 2}
{cmd:opendf_csv2dta}, 
{it:csv_loc()}
[{cmd:} {opt rowrange}([start][:end]) {opt colrange}([start][:end])} {opt clear} {opt save()} {opt replace} {opt verbose}]

{synoptset 20 tabbed}{...}
{marker options}{synopthdr:options}
{synoptline}
{synopt :{opt csv_loc(string)}}Indicates location of csvs. {p_end}
{synopt :{opt rowrange}([start][:end])}Indicates the range of rows to read. {p_end}
{synopt :{opt colrange}([start][:end])}Indicates the range of columns to read. {p_end}
{synopt :{opt clear}}allows you to clear dataset in memory {p_end}
{synopt :{opt save(string)}}save data to desired filepath and filename. {p_end}
{synopt :{opt replace}}overwriting former saved file {p_end}
{synopt :{opt verbose}}More warnings are displayed. {p_end}
{synoptline}


{marker description}
{title:Description}

{pstd}
{cmd:opendf_csv2dta} Transforms survey data from several csv files into dta-format including metadata saved in labels and characteristics. {p_end}
{pstd}
{opt csv_loc} is a path to a folder where 4 csvs have to be included that contain data and metadata. {p_end}
{pstd}The file containing the data has to be named data.csv {p_end}
{pstd}The file containing the metadata for the datset has to be named dataset.csv {p_end}
{pstd}The file containing the metadata for the variables has to be named variables.csv {p_end}
{pstd}The file containing the metadata for the values has to be named categories.csv {p_end}
{pstd} Metadata information is saved as labels or characteristics. {p_end}
{pstd}{opt rowrange([start][:end])}} specifies a range of rows within the data to load (excluding the header). {it: start} and {it: end} are integer row numbers.{p_end}
{pstd}{opt colrange([start][:end])}} specifies a range of variables within the data to load.  {it: start} and {it: end} are integer column numbers.{p_end}
{pstd}{opt clear} specifies that it is okay to replace the data in memory, even though the current data have not been saved to disk.{p_end}
{pstd}{opt replace} overwrite existing file.{p_end}
{pstd}{opt replace} indicates that any existing file should be overwritten.{p_end}
{pstd}{opt save} stores data to a desired filepath and filename.{p_end}
{pstd}{opt verbose} display more warnings.{p_end}


{marker remarks}
{title:Remarks}

{pstd}
This command from the opendf package is part of the Open Data Format Project bundle, written to assist with survey data files in the open data format(.zip).{p_end}


{marker examples}
{title:Examples}

{phang}Builds a Stata dataset containing metadata in the characteristics and the labels from the four csvs located in "C:/Documents/Data". {p_end}
{phang}{cmd:. opendf_csv2dta, csv_loc("C:/Documents/Data")}{p_end}


{marker author}
{title:Author}

{pstd}
Tom Hartl ({browse "mailto:thartl@diw.de":thartl@diw.de}), Deutsches Institut für Wirtschaftsforschung Berlin. 


{marker alsosee}
{title:Also see}

{psee}
{space 2}Help: {help opendf_read}, {help opendf_write}, {help opendf_docu} {help opendf_csv2zip}{p_end}
