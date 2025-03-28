{smcl}
{* *! version 1.0.1}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "gmd##syntax"}{...}
{viewerjumpto "Description" "gmd##description"}{...}
{viewerjumpto "Options" "gmd##options"}{...}
{viewerjumpto "Examples" "gmd##examples"}{...}
{title:Title}

{phang}
{bf:gmd} {hline 2} Download and analyze Global Macro Database with version control

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:gmd} [{it:varlist}] [{cmd:,} {cmdab:v:ersion(}{it:YYYY_QQ|current}{cmd:)} {cmdab:co:untry(}{it:string}{cmd:)} {cmdab:r:aw} {cmdab:i:so} {cmdab:var:s}]

{marker description}{...}
{title:Description}

{pstd}
This command downloads and loads the Global Macro Database. Users can specify which version to load, 
which variables to keep, and filter for specific countries. The dataset is available in quarterly 
versions (YYYY_QQ format) or as raw data. Visit {browse "https://www.globalmacrodata.com/data.html"} 
to see available version dates. The command automatically clears any data in memory before loading.

{marker options}{...}
{title:Options}

{phang}
{cmd:version(}{it:YYYY_QQ|current}{cmd:)} specifies which version of the dataset to load (e.g., 2025_03). 
You can also specify "current" to explicitly request the latest version.{p_end}
{pmore}
Visit {browse "https://www.globalmacrodata.com/data.html"} to see all available version dates.

{phang}
{cmd:country(}{it:string}{cmd:)} specifies a country to filter by using its ISO3 code 
(e.g., USA, GBR). Case-insensitive.{p_end}

{phang}
{cmd:raw} pulls the raw data underlying the combined series in addition to the processed dataset. Requires specifying exactly one variable (not more, not less).{p_end}

{phang}
{cmd:iso} display a complete list of available countries with their names and ISO3 codes.{p_end}

{phang}
{cmd:vars} display a complete list of available variables with descriptions.{p_end}

{marker arguments}{...}
{title:Arguments}

{phang}
{it:varlist} optional list of variables to keep in addition to ISO3, year, and countryname. If not specified, all variables are retained. 
When used with the {cmd:raw} option, specifies the sheet name to import from the raw data.

{marker examples}{...}
{title:Examples}

{phang}Load the latest version:{p_end}
{phang2}{cmd:. gmd}

{phang}Load a specific version:{p_end}
{phang2}{cmd:. gmd, version(2025_03)}

{phang}Display a complete list of available variables with descriptions:{p_end}
{phang2}{cmd:. gmd, vars}

{phang}Display a complete list of available countries with their names and ISO3 codes:{p_end}
{phang2}{cmd:. gmd, iso}

{phang}Load specific variables:{p_end}
{phang2}{cmd:. gmd nGDP pop}

{phang}Load data for a specific country:{p_end}
{phang2}{cmd:. gmd, country(SGP)}

{phang}Combine options:{p_end}
{phang2}{cmd:. gmd nGDP pop, country(SGP) version(2025_03)}

{phang}Access raw data for a specific variable:{p_end}
{phang2}{cmd:. gmd nGDP, raw}

{phang}Combine options with raw data:{p_end}
{phang2}{cmd:. gmd nGDP pop, country(SGP) version(2025_03) raw}


{title:Author}

{pstd}
Mohamed Lehbib{break}
Email: {browse "mailto:lehbib@nus.edu.sg":lehbib@nus.edu.sg}{break}
Website: {browse "https://www.globalmacrodata.com/data.html"} 

{title:Citation}

{pstd}
To cite this dataset, please use:

{pstd}
Müller, Karsten, Chenzi Xu, Mohamed Lehbib, and Ziliang Chen. 2025.{break}
"The Global Macro Database: A New Historical Dataset of Macroeconomic Statistics."{break}
Working Paper.

{pstd}
BibTeX:

{phang}
@techreport{mueller2025global,{break}
    title = {The Global Macro Database: A New Historical Dataset of Macroeconomic Statistics},{break}
    author = {Müller, Karsten and Xu, Chenzi and Lehbib, Mohamed and Chen, Ziliang},{break}
    year = {2025},{break}
    type = {Working Paper}{break}
}

{title:Version}

{pstd}
This is version 1.1 of {cmd:gmd}.
{p_end}