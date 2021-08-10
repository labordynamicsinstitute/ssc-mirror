{smcl}
{* *! version 1.0.0  30aug2016}{...}
{viewerjumpto "Syntax" "sdmxuse##syntax"}{...}
{viewerjumpto "Description" "sdmxuse##description"}{...}
{viewerjumpto "Options" "sdmxuse##options"}{...}
{viewerjumpto "Remarks" "sdmxuse##remarks"}{...}
{viewerjumpto "Examples" "sdmxuse##examples"}{...}
{viewerjumpto "Author" "sdmxuse##author"}{...}

{title:Title}

{phang}
{bf:sdmxuse} {hline 2} Import data from statistical agencies using the SDMX standard

{marker syntax}{...}
{title:Syntax}

{p 8 8 2}
{cmdab:sdmxuse} dataflow {it:provider}

{p 8 8 2}
{cmdab:sdmxuse} datastructure {it:provider}, dataset({it:identifier})

{p 8 8 2}
{cmdab:sdmxuse} data {it:provider}, dataset({it:identifier})

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{bf:attributes}}download attributes (e.g. observations' flags) {p_end}
{synopt:{bf:clear}}clears data in memory {p_end}

{syntab:Select data}
{synopt:{bf:dimensions()}}allows customizing requests for data {p_end}
{synopt:{bf:start()}}defines start period {p_end}
{synopt:{bf:end()}}defines end period {p_end}

{syntab:Reshape data}
{synopt:{bf:timeseries}}reshapes dataset to obtain time series {p_end}
{synopt:{bf:panel()}}reshapes dataset to obtain a panel {p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:sdmxuse} imports data from statistical agencies using the SDMX standard. Available providers are European Central Bank (ECB), Eurostat (ESTAT),
International Monetary Fund (IMF), Organisation for Economic Co-operation and Development (OECD) and World Bank (WB).

{pstd}
You can get a complete list of publicly available datasets from a provider by specifying the resource: dataflow.
Then, you can obtain the Data Structure Definition (DSD) of a given dataset by specifying the resource: datastructure.
Finally, you can download the dataset by specifying the resource: data.

{pstd}
You can also find the dataset identifier on some providers' website. Eurostat, for instance, refers to the dataset identifier as 'product code',
indicated between brackets after the titles in the navigation tree: {browse "http://ec.europa.eu/eurostat/data/database"}

{marker options}{...}
{title:Options}
{dlgtab:Main}

{phang}
{opt attributes} gives additional information about the series or the observations, but does not affect the dataset structure itself. E.g. observations' flags. {p_end}

{phang}
{opt clear} clears data memory before proceeding. {p_end}

{dlgtab:Select data}

{phang}
{opt dimensions()} allows customizing requests for data. You can choose which dimensions with which values you want to retrieve data for.
The dimensions are separated with a dot "." character and must respect the order specified in the Data Structure Definition. 
If a dimension is left blank, it will not be used to filter the series and all possible values will be provided. 
If several values for a given dimension are chosen, they must be separated with a "+" character.{p_end}

{phang}
{opt start()} defines the start period. You can specify the exact value (e.g. 2010-01) or just the year (e.g. 2010). {p_end}

{phang}
{opt end()} defines the end period. {p_end}

{dlgtab:Reshape data}

{phang}
{opt timeseries} reshapes the dataset so that each series is stored in a single variable. The variables' names are made of the values of the series for each dimension. {p_end}

{phang}
{opt panel(panelvar)} reshapes the dataset into a panel. {it:panelvar} must be specified, it will often be the geographical dimension.  {p_end}

{marker remarks}{...}
{title:Remarks}

{pstd}
This program uses the package "moss" by Robert Picard & Nicholas J. Cox. You can install it from SSC: {stata ssc install moss} {p_end}

{pstd}
For queries larger than 30,000 cells, Eurostat will post the file to a different repository. 
{cmd:sdmxuse} can accommodate this but processing time will be longer. 
You can try with the following dataset: {cmd:sdmxuse} data ESTAT, clear dataset(nama_gdp_k) {p_end}

{marker examples}{...}
{title:Examples}

{phang}
{cmd:. sdmxuse} dataflow OECD, clear {p_end}

{phang}
{cmd:. sdmxuse} datastructure OECD, clear dataset(EO) {p_end}

{phang}
{cmd:. sdmxuse} data OECD, clear dataset(EO) dimensions(FRA+DEU.GDPV_ANNPCT.A) start(1993) {p_end}

{phang}
{cmd:. sdmxuse} data OECD, clear dataset(EO) dimensions(FRA+DEU.GDPV_ANNPCT.A) start(1993) timeseries {p_end}

{phang}
{cmd:. sdmxuse} data OECD, clear dataset(EO) dimensions(.GDPV_ANNPCT+CPIH.A) panel(location) {p_end}

{marker author}{...}
{title:Author}

{pstd}
	Sebastien Fontenay{break}
	UCL - ESL & IRES{break}
	sebastien.fontenay@uclouvain.be {p_end}
