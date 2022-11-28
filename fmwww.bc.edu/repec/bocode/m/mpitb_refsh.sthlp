{smcl}
{* *! version 0.1.3  16 May 2022}{...}
{vieweralsosee "mpitb" "help mpitb"}{...}
{viewerjumpto "Syntax" "mpitb_refsh##syntax"}{...}
{viewerjumpto "Description" "mpitb_refsh##description"}{...}
{viewerjumpto "Options" "mpitb_refsh##options"}{...}
{viewerjumpto "Remarks" "mpitb_refsh##remarks"}{...}
{viewerjumpto "Examples" "mpitb_refsh##examples"}{...}
{p2colset 1 16 18 2}{...}
{p2col:{bf:mpitb refsh} {hline 2}} creates or updates the reference sheet{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:mpitb refsh using} 
{it:{help filename}} {cmd:, id(}{it:name}{cmd:) path(}{it:string}{cmd:)} 
[{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent :* {opt id(name)}}country ID in reference sheet{p_end}
{p2coldent :† {opt p:ath(path)}}path to cleaned micro data{p_end}
{p2coldent :† {opt f:ile(filename)}}filename of cleaned micro data{p_end}
{synopt:{opt c:har(clist)}}data characteristics to collect{p_end}
{synopt:{opt k:eep(keeplist)}}variables to keep{p_end}
{synopt:{opt sid(name)}}ID for sub-national units within countries{p_end}
{synopt:{opt clear}}replace only potentially existing reference sheet{p_end}
{synopt:{opt newf:iles}}search for new files and add to reference sheet{p_end}
{synopt:{opt upd:ate(ctylist)}}update reference sheet{p_end}
{synopt:{opt dep:ind(dlist)}}collect information on deprivation indicators{p_end}
{synopt:{opt gent:var(year)}}generate time variable{p_end}

{synoptline}
{p2colreset}{...}
{p 4 6 2}* required options; † one of these options is required.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:mpitb refsh} creates or updates the reference sheet, a key feature of the 
global MPI workflow. The reference sheet contains basic information about the 
countries covered by the current project. The reference may be used (i) to control 
estimation and other production routines efficiently, (ii) for merging external 
data easily, (iii) reducing the amount of information that estimates are passed 
through the estimation routine. See the {help mpitb##workflow:workflow} for more 
details.{p_end}

{pstd}
Essentially, {cmd:mpitb refsh} examines all micro datasets in the specified folder 
and collects certain information (data characteristics or variables). Afterwards 
{cmd:mpitb refsh} creates the reference sheet comprising this information for each 
country.{p_end}



{marker options}{...}
{title:Options}

{phang}
{opt id(name)} specifies the identifier of a particular dataset and is usually an 
ISO country code. By default, {it:name} is assumed to be a variable name. If, however,
 option {opt char(clist)} is set, {it:name} may be a data characteristic, too.
The reference sheet will contain at least one observation for each ID (or dataset).

{phang}
{opt p:ath(path)} specifies the path to the cleaned micro datasets. Note that {it:path}
 has to be specified as {it:folder/subfolder} using slashes "/" and not backslashes "\".{p_end}

{phang}
{opt f:ile(filename)} specifies the file of the cleaned micro dataset. 
This option may not be combined with options {opt path(path)}, {opt update(clist)} 
or {opt newfiles}.{p_end}
 
{phang}
{opt clear} examines every dta file in the specified path for being included into 
the reference sheet and replaces any potentially already existing reference sheet.
Usually, this option is the most convenient.{p_end}

{phang}
{opt newf:iles} searches for new files in the specified path and adds them to the reference 
sheet if encountered. The old entries for this country will be replaced. This option 
is rarely used.{p_end}

{phang}
{opt upd:ate(clist)} updates the reference for selected countries. Usually {it:clist}
would be country codes and refer to values of the variable specified in {opt id(name)}
This option is rarely used.{p_end}

{phang}
{opt sid(sid)} specifies a secondary ID for subgroups within a country (or dataset),
which is usually the subnational region variable. Unlike most other subgroups,
coding and labels of regions tend to vary across countries. The reference sheet will
contain one observation for each region of a given country.{p_end}

{pmore} 
If {cmd: mpitb refsh} encounters a region variable containing only missing values, 
it only adds a single entry for this country to the reference sheet, whereas a dataset 
is entirely skipped if the specified variable is not found at all. This convention 
allows to distinguish countries for which the survey does not allow subnational
disaggregation from countries which are not supposed to be included in particular 
analysis.{p_end}

{phang}
{opt k:eep(namelist)} allows to specify variables in the micro dataset, which are kept 
and stored in the reference sheet. These variables are assumed to be constant across
all observations in the micro dataset (and missing values will be ignored). This 
option allows to pass further information from the micro data files to the reference 
sheet (and from there to the results file). Use cases may be country codes, survey 
names or years. Usually, using the option {opt char} is preferable, though.{p_end}

{phang}
{opt c:har(clist)} specifies a list of data characteristics (see {helpb char}) 
of the micro data, which will be retained and added as variables to the reference sheet.{p_end}

{phang}
{opt dep:ind(dlist)} collects information on deprivation indicators, where {it:dlist}
is a list of all deprivation indicators supposed to be covered. If this option is set
the {cmd:mpitb refsh} adds the number of indicators found in each dataset and the 
names of missing indicators.{p_end}

{phang}
{opt gent:var(year)} generates an integer time variable, which identifies the data 
rounds for each country based on the variable (or characteristic) {it:year}.{p_end}

{marker remarks}{...}
{title:Remarks}

{pstd}
1. Data characteristics are convenient to store information with a dataset that does 
not vary across observation as it may reduce file sizes significantly. If you wanted 
your reference sheet to include a variable {it:ccty} holding an ISO country code, 
you could store this information with the micro dataset itself as follows:{p_end}

{phang2}
{cmd: char _dta[ccty] "XYZ"}

{pstd}
2. If some of your countries cannot be disaggregated by region, create the 
{it:region} variable with missing values for all observations. {cmd:mpitb refsheet} 
will include a single observation for the national level into the reference sheet.{p_end}

{marker examples}{...}
{title:Examples}

    {hline}
{pstd}
1. Assume you have all micro data files stored in the folder {it:cdta}, which contains 
data characteristics {it:ccty}, {it:survey} and {it:year}, and a variable {it:region}.
To create the reference sheet for this setup, you may issue{p_end}

{phang2}{cmd:mpitb refsh using refsh.dta , clear char(ccty survey year) id(ccty) sid(region) path(cdta)}{p_end}
	
    {hline}
