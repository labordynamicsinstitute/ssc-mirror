{smcl}
{* *! version 3.3.0  12oct2024}{...}
{viewerjumpto "Syntax" "eurostatuse##syntax"}{...}
{viewerjumpto "Dialogue box" "eurostatuse##dialogue"}{...}
{viewerjumpto "Description" "eurostatuse##description"}{...}
{viewerjumpto "Options" "eurostatuse##options"}{...}
{viewerjumpto "Remarks" "eurostatuse##remarks"}{...}
{viewerjumpto "Examples" "eurostatuse##examples"}{...}
{viewerjumpto "Install" "eurostatuse##install"}{...}
{viewerjumpto "Authors" "eurostatuse##authors"}{...}
{title:Title}

{phang}
{bf:eurostatuse} {hline 2} Import Eurostat data

{marker syntax}{...}
{title:Syntax}

{p 8 8 2}
{cmdab:eurostatuse} {it:table_name} [{cmd:,} {it:options}]

{p 8 8 2}
{it:table_name} is the Eurostat data file to be downloaded, unzipped and processed.

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{bf:long}}creates output in the long format (e.g. time in rows) {p_end}
{synopt:{bf:[no]label}}drops the label variables {p_end}
{synopt:{bf:[no]flags}}drops the flag variables {p_end}
{synopt:{bf:[no]erase}}saves the original .tsv file in the active folder {p_end}
{synopt:{bf:uncompressed}}downloads uncompressed .tsv file (no need for 7-zip on Windows) (new) {p_end}
{synopt:{bf:save}}saves output in a Stata data (.dta) file {p_end}
{synopt:{bf:clear}}clears data in memory {p_end}

{syntab:Select data}
{synopt:{bf:start()}}defines start period {p_end}
{synopt:{bf:end()}}defines end period {p_end}
{synopt:{bf:geo()}}set a list of countries to be kept {p_end}
{synopt:{bf:keepdim()}}limits by other dimensions {p_end}
{synoptline}
{p2colreset}{...}

{marker dialogue}{...}
{title:Dialogue box}

{pstd}
{stata db eurostatuse}
{p_end}

{pstd}
You can access the dialogue box by clicking on the link above or by entering {cmd: db eurostatuse} in the command line.
{p_end}

{marker description}{...}
{title:Description}

{pstd}{cmd:eurostatuse} imports data from the Eurostat repository into Stata. It also provides information on the data set, downloads labels, separates flags and values, implements the reshape to long format, and fixes time formats.
{p_end}

{pstd}{it:table_name} should include just one Eurostat data file. You should only specify the name ("Eurostat code"), not the .tsv or .gz extension, indicated between brackets after the titles in the navigation tree.
{p_end}

{pstd}
Eurostat navigation tree: {browse "https://ec.europa.eu/eurostat/data/database"}.
{p_end}

{pstd}
See also: {browse "https://ec.europa.eu/eurostat/databrowser/bulk?lang=en"}.
{p_end}

{marker options}{...}
{title:Options}
{dlgtab:Main}

{phang}
{opt long} creates output in the long format (time in rows). Default is wide. Depending on the size of the data set the reshaping could take a while.
{p_end}

{phang}
{opt [no]erase} saves the original .tsv file in the working directory. Note that {cmd:eurostatuse} will use this file instead of a new download if it exists.
{p_end}

{phang}
{opt [no]label} removes the label variables. The codes may be self-explanatory.
{p_end}

{phang}
{opt [no]flags} removes the flags Eurostat uses to comment on the data.
{p_end}

{phang}
{opt [uncompressed} downloads the uncompressed .tsv file (larger and slower, but no need for 7-zip on Windows).
{p_end}

{phang}
{opt save} saves output in a Stata data (.dta) file.
{p_end}

{phang}
{opt clear} clears data memory before proceeding.
{p_end}

{dlgtab:Select data}

{phang} These options significantly reduce processing time of long data requests. {p_end}

{phang}
{opt start()} defines the start period (e.g. 2008, 2010Q3, 2012M09). If not sure about the time code, download the full table first for a small sample depending on geo() or keepdim().
{p_end}

{phang}
{opt end()} defines the end period (as above). You do not have to specify both end and start period.
{p_end}

{phang}
{opt geo()} selects data by {it:country_abbreviations} (see below). For an aggregate, use area codes (EA, EU28 etc.) for a list of member states and other countries, use EU 2-digit codes separated by a space and don't use quotes.
{p_end}

{phang}
{opt keepdim()} selects by other dimensions. Multiple dimensions have to be separated by a semicolon but need not be named. Just enter the desired values within a dimension, each separated by a space. The ordering of the dimensions is not important and you should not use quotes for the values. {p_end}

{marker remarks}{...}
{title:Remarks}

{pstd}
The Eurostat repository at {browse "https://ec.europa.eu/eurostat/data/database"} contains a large number of EU policy data sets, generally time series (monthly, quarterly, annually). Each series is stored in a separate file that also contains a string-date variable and header with information about the series.  {p_end}

{pstd}
{cmd:eurostatuse} imports data series into a Stata dataset. The output is a file with the same name as the data set, but always in lower case. The same goes for the variables in the data set. If you specify the {opt noerase} option to save the original download, the .tsv file will have the data set name in upper case.
{p_end}

{pstd}
The following country abbreviations are used by Eurostat and can be used as {it:country_abbreviations} in {hi:geo()}:
{p_end}

{p 8}Table: Geographical regions and country abbreviations {p_end}
{col 9}{dup 66:{c -}}
{col 9}Aggregates
{col 9}{bf:EU27_2020}{col 20}European Union (27 countries - 2020)
{col 9}{bf:EU28}{col 20}European Union (28 countries - 2008/2019)
{col 9}{bf:EU27_2007}{col 20}EEuropean Union (27 countries - 2007)
{col 9}{bf:EU}{col 20}European Union (changing composition)
{col 9}{bf:EA19}{col 20}Euro area (19 countries)
{col 9}{bf:EA}{col 20}Euro area (changing composition)

{col 9}EU Member States (2020)
{col 9}{bf:BE}{col 20}Belgium
{col 9}{bf:BG}{col 20}Bulgaria
{col 9}{bf:CZ}{col 20}Czech Republic
{col 9}{bf:DK}{col 20}Denmark
{col 9}{bf:DE}{col 20}Germany
{col 9}{bf:EE}{col 20}Estonia
{col 9}{bf:IE}{col 20}Ireland
{col 9}{bf:EL}{col 20}Greece
{col 9}{bf:ES}{col 20}Spain
{col 9}{bf:FR}{col 20}France
{col 9}{bf:HR}{col 20}Croatia
{col 9}{bf:IT}{col 20}Italy
{col 9}{bf:CY}{col 20}Cyprus
{col 9}{bf:LV}{col 20}Latvia
{col 9}{bf:LT}{col 20}Lithuania
{col 9}{bf:LU}{col 20}Luxembourg
{col 9}{bf:HU}{col 20}Hungary
{col 9}{bf:MT}{col 20}Malta
{col 9}{bf:NL}{col 20}Netherlands
{col 9}{bf:AT}{col 20}Austria
{col 9}{bf:PL}{col 20}Poland
{col 9}{bf:PT}{col 20}Portugal
{col 9}{bf:RO}{col 20}Romania
{col 9}{bf:SI}{col 20}Slovenia
{col 9}{bf:SK}{col 20}Slovakia
{col 9}{bf:FI}{col 20}Finland
{col 9}{bf:SE}{col 20}Sweden

{col 9}Other countries
{col 9}{bf:IS}{col 20}Iceland
{col 9}{bf:LI}{col 20}Liechtenstein
{col 9}{bf:NO}{col 20}Norway
{col 9}{bf:CH}{col 20}Switzerland
{col 9}{bf:ME}{col 20}Montenegro
{col 9}{bf:TR}{col 20}Turkey
{col 9}{bf:UK}{col 20}United Kingdom
{col 9}{bf:US}{col 20}United States
{col 9}{dup 66:{c -}}

{marker examples}{...}
{title:Examples}

{phang}
{cmd:. eurostatuse} sdg_05_20, noflags nolabel uncompressed clear
{p_end}

{phang}
{cmd:. eurostatuse} une_ltu_a, noflags nolabel long geo(BE DE FR) clear
{p_end}

{phang}
{cmd:. eurostatuse} namq_10_gdp, noflags start(2000Q1) keepdim(CLV_PCH_PRE ; SCA ; B1GQ P3 P51G) clear
{p_end}

{phang}
{cmd:. eurostatuse} nama_10r_3gdp, flags label long noerase clear
{p_end}

{marker install}{...}
{title:Install}

{pstd}
Download or update eurostatuse over SSC (ssc install eurostatuse, replace) or put the eurostatuse.ado file in your personal ado folder (by default, on Windows, the folder is C:\ado\personal\, on macOS it is found within the Stata folder in the library). Put it in the subfolder e\ to keep the folder orderly. Stata will automatically search this directory for programs on the next run and have the command ready when you call it.
{p_end}

{pstd}
On Windows, to use the default compressed file transfer, you need to have 7-zip installed into the program files directory (C:\Program Files\7-Zip\7zG.exe). If you install it elsewhere, the ado needs to be changed - you can do that. Mac users don't need to do anything. A Linux shell should also be straightforward to add but it is currently not in the ado.
{p_end}

{pstd}
You can download 7-zip from {browse "http://www.7-zip.org/download.html"}.
{p_end}


{marker authors}{...}
{title:Authors}

{pstd}
	Sebastien Fontenay {break}
	UAH Universidad de Alcalá {break}
	sebastien.fontenay@uah.es
{p_end}

{pstd}
	Sem Vandekerckhove (contact) {break}
	HIVA-KU Leuven {break}
	sem.vandekerckhove@kuleuven.be
{p_end}