{smcl}
{vieweralsosee "opendf_read" "help opendf_read"}{...}
{vieweralsosee "opendf_write" "help opendf_write"}{...}
{vieweralsosee "opendf_docu" "help opendf_docu"}{...}
{vieweralsosee "opendf_csv2dta" "help opendf_csv2dta"}{...}
{viewerjumpto "Syntax" "opendf_csv2zip##syntax"}{...}
{viewerjumpto "Description" "opendf_csv2zip##description"}{...}
{viewerjumpto "Options" "opendf_csv2zip##options"}{...}
{viewerjumpto "Examples" "opendf_csv2zip##examples"}{...}
help for {cmd:opendf csv2zip (opendf_csv2zip)}{right: version 2.0.2 (28 August 2024)}
{hline}

{phang}
{bf:opendf_csv2zip} {hline 2} generates an opendf-format zip-file from csv files containing data meta data for survey data. {p_end}


{marker syntax}
{title:Syntax}
{p 8 17 2}
{cmd:opendf_csv2zip}, 
{opt output()} [{opt input()} {opt variables_arg()} {opt export_data()} {opt verbose}]

{synoptset 20 tabbed}{...}
{marker options}{synopthdr:options}
{synoptline}
{synopt :{opt output(string)}}(Path and) Name of the output-zip-folder. {p_end}
{synopt :{opt input(string)}}Indicates location of csvs. {p_end}
{synopt :{opt variables_arg(string)}}Specifies whether variable metadata should be exported. Default is "yes". {p_end}
{synopt :{opt export_data(string)}}Indicates whether the data.csv should be exported to the opendf-zip file. Default is "yes".{p_end}
{synopt :{opt verbose}}More warnings are displayed. {p_end}
{synoptline}


{marker description}
{title:Description}

{pstd}
{cmd:opendf_csv2zip} Transforms survey data from several csv files into dta-format including metadata saved in labels and characteristics. {p_end}
{pstd}The file containing the data has to be named data.csv {p_end}
{pstd}The file containing the metadata for the datset has to be named dataset.csv {p_end}
{pstd}The file containing the metadata for the variables has to be named variables.csv {p_end}
{pstd}The file containing the metadata for the values has to be named categories.csv {p_end}

{pstd}{opt output} Name of the output-zip-folder. Can also include a path where to save the output. {p_end}
{pstd}{opt input} is a path to a folder where 4 csvs have to be included that contain data and metadata. {p_end}
{pstd}If you are exporting the entire dataset, you can choose whether or not to export all available metadata (labels and descriptions of the dataset and the variables). {p_end}
{pstd}By default all metadata is exported ({opt variables_arg("yes")}): information describing the dataset itself, as well as information describing all variables in the dataset. {p_end}
{pstd}If you set {opt variables_arg("no")}, only the information describing the dataset is exported. {p_end}
{pstd}Option {opt export_data} indicates whether the data.csv should be exported to the opendf-zip file. Default is {opt export_data("yes")}. To save a dataset in opendf-format "yes" is necessary. Otherwise only the xml with the metadata is created. {p_end}


{marker remarks}
{title:Remarks}

{pstd}
This command from the opendf package is part of the Open Data Format Project bundle, written to assist with survey data files in the open data format(.zip).{p_end}


{marker examples}
{title:Examples}

{phang}Builds and saves the datafile out.zip in the current working directory in opendf-format (.zip) from the four csvs located in "C:/Documents/Data". {p_end}
{phang}{cmd:. opendf_csv2zip, output("out.zip") input("C:/Documents/Data")}{p_end}


{marker author}
{title:Author}

{pstd}
Tom Hartl ({browse "mailto:thartl@diw.de":thartl@diw.de}), Deutsches Institut für Wirtschaftsforschung Berlin. 


{marker alsosee}
{title:Also see}

{psee}
{space 2}Help: {help opendf_read}, {help opendf_write}, {help opendf_docu}, {help opendf_csv2dta}{p_end}
