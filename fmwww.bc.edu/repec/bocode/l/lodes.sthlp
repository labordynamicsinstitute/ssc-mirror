{smcl}
{* *! version 1.1.4 june242026}{...}
{vieweralsosee "[D] frames" "help frames"}{...}
{vieweralsosee "[SP] spshape2dta" "help spshape2dta"}{...}
{viewerjumpto "Syntax" "lodes##syntax"}{...}
{viewerjumpto "Description" "lodes##description"}{...}
{viewerjumpto "Requirements" "lodes##requirements"}{...}
{viewerjumpto "Subcommands" "lodes##subcommands"}{...}
{viewerjumpto "Examples" "lodes##examples"}{...}
{viewerjumpto "Author" "lodes##author"}{...}
{hline}
help for {cmd:lodes}
{hline}

{title:Title}

{p 4 4 2}
	{hi:lodes} {hline 2} Command to obtain and process US Census {browse "https://lehd.ces.census.gov/applications/help/onthemap.html#!what_is_onthemap":Longitudinal Employer-Household Dynamics}
	(LEHD) 
	{browse "https://lehd.ces.census.gov/data/#lodes":Origin-Destination Employment Statistics}
	(LODES) data.

{marker syntax}{...}
{title:Syntax}

{p 4 4 2}
	{cmd:lodes} {it:{help lodes##subcmd:subcommand}} [{it:...}]

{synoptset 25 tabbed}{...}
{marker subcmd}{synopthdr:subcommand}
{synoptline}
{synopt :{helpb lodes##get:get}}Imports a LODES data file (i.e., od, wac, rac) for a specified state, along with its respective geography crosswalk file into Stata frames. 
	{p_end}

{synopt :{helpb lodes##destination:destination}}Performs data analysis mirroring what can be manually done using the using the {browse "https://onthemap.ces.census.gov/":OnTheMap} web-based tool by running {it:Destination Analysis}. 
	{p_end}
	
{synopt :{helpb lodes##inflow_outflow:inflow_outflow}}Performs data analysis mirroring what can be manually done using the {browse "https://onthemap.ces.census.gov/":OnTheMap} web-based tool by running {it:Inflow-Outflow Analysis}. 
	{p_end}

{synopt :{helpb lodes##area_profile:area_profile}}Performs data analysis mirroring what can be manually done using the {browse "https://onthemap.ces.census.gov/":OnTheMap} web-based tool by running {it:Area Profile Analysis}. 
	{p_end}
	
{marker description}{...}
{title:Description}

{pstd}
{cmd:lodes} imports and processes LEHD LODES data, mirroring the analysis
that can be manually done using the
{browse "https://onthemap.ces.census.gov/":OnTheMap} web-based tool.
{cmd:lodes} eliminates the manual steps required by the online tool, with
the added value of running within the Stata environment. {cmd:lodes} can
use {browse "https://doc.arcgis.com/en/arcgis-online/reference/shapefiles.htm":ESRI}
shapefiles to define a custom geographic area of interest to selectively
obtain data and run analysis.

{marker requirements}{...}
{title:Requirements}

{pstd}
{cmd:lodes} relies on the following user-written packages. If any are
missing when {cmd:lodes get} is run, the command stops with a clear
message listing the install commands; install the missing packages and
re-run. (Earlier versions installed dependencies silently; this is now
the user's choice so nothing is added to your ado-path without consent.)

{phang2} • {bf:fframeappend} (SSC) - appends frames row-wise.
{break}  Install with: {cmd:. ssc install fframeappend} {p_end}

{phang2} • {bf:geoinpoly} (SSC) - tests point-in-polygon for shapefile
polygons.
{break}  Install with: {cmd:. ssc install geoinpoly} {p_end}

{phang2} • {bf:gzimport} (not on SSC) - reads gzipped delimited files
directly. Author: M. Droste.
{break}  Install with: {cmd:. net install gzimport, from(https://raw.githubusercontent.com/mdroste/stata-gzimport/master/)} {p_end}

{pstd}
{cmd:lodes} also requires Stata 16.1 or later (for native frame support)
and an active Internet connection to retrieve LODES CSV files from the
U.S. Census LEHD server.

{marker get}{...}
{dlgtab:lodes get}

{title:Syntax}

{pstd} {cmd:lodes get} {it:state} [,{it: options}]

{pstd}
Imports data for an entire state and for a minimum of one year. Data are
provided at the block level and can be aggregated at different geography
levels using the corresponding geography reference file. See LODES
{browse "https://lehd.ces.census.gov/doc/help/onthemap/LODESTechDoc.pdf": Dataset Structure documentation}
for the detailed description of datasets. The data file and crosswalk
reference file are set up as Stata frames.

{pstd}	
{cmd:state} – a string representing a state abbreviation (e.g., fl or FL). 
	
{pstd}
{cmd:data_type} – a string representing the LODES dataset type to be imported:

{phang2} • OD – Origin-Destination data, job totals are associated with both a home Census Block and work Census Block.{p_end}
{phang2} • RAC – Residence Area Characteristics data, jobs are summed at the home Census Block.{p_end}
{phang2} • WAC – Workplace Area Characteristics data, jobs are summed at the work Census Block.{p_end}

{pstd}
If the user does not specify {cmd:data_type}, the default is {it:OD}.
Note: the {cmd:segment} option below applies only to {it:WAC} and
{it:RAC} data and is ignored (with a notice) for {it:OD}, whose CSV
files are not segmented.

{pstd}
{cmd:job_type} - A string defining the job type, which can be any of the following:

{phang2} • JT00 – All jobs{p_end}
{phang2} • JT01 – Primary jobs{p_end}
{phang2} • JT02 – All private jobs{p_end}
{phang2} • JT03 – All private primary jobs{p_end}
{phang2} • JT04 – All federal jobs{p_end}
{phang2} • JT05 – Federal primary jobs{p_end}

{pstd}
If the user does not specify {cmd:job_type}, the default JT00 – All jobs is used. 

{pstd}
{cmd:segment} – a string defining jobs by either age (SA--), earning
(SE--), or industry sector (SI--). Only applies to {it:WAC} and {it:RAC}
data; the option is ignored (with a notice) for {it:OD}, whose CSV files
are not segmented. When using {it:WAC} or {it:RAC}, the default is
{it:S000} (Total Number of Jobs).

{pstd}
{cmd:year} – a string indicating the year or years of data to be imported.
Multiple years can be indicated. If the user does not specify a value, the
default lates data release is used. Note that for some states some years are
unavailable (see:
{browse "https://lehd.ces.census.gov/doc/help/onthemap/OnTheMapDataOverview.pdf":OnTheMap Data Overview}).

{pstd}
{cmd:od_part} – this string defines which part of the OD file to include.
The {it:main} part includes jobs with both workplace and residence in the
state and the {it:aux} part includes jobs with the workplace in the state
and the residence outside the state. The default is both part files
({it:main} and {it:aux}).

{pstd}
{cmd:lodes_version} – this string specifies which release of the LODES dataset to import. The default is {it:LODES8}.

{pstd}
{cmd:clear} – allow {cmd:lodes get} to overwrite its output frames if they
already exist in memory (typically from a previous {cmd:lodes get} run).
The output frames are the state crosswalk (e.g., {it:fl_xwalk}) and the
main data frame (e.g., {it:fl_od_JT00}). Without {cmd:clear}, the command
aborts with an error rather than overwriting. Other frames in memory are
never affected in either case; this option is safe to use even with
unrelated frames open. {cmd:lodes get} no longer drops the user's default
frame, so any data loaded before the call is preserved.

{pstd}
{cmd:saveas} – save output as a Stata dataset.

{pstd}
{cmd:replace} – if {it:saveas()} is specified, overwrite the existing files.

{pstd}
{cmd:saveframes} – if {it:saveas()} is specified, save the imported data as a Stata frame. This option saves two data frames, 
the main data imported for analysis (e.g., {it:od}) and the selected state geography cross walk frame (e.g., {it:fl_xwalk}). 

{pstd}
{cmd:deleteframe} – remove the generated output frames.

{pstd}
{cmd:browse} – browse the output data frame.


{marker destination}{...}
{dlgtab:lodes destination}

{title:Syntax}

{pstd} {cmd:lodes destination} {it:geography} [,{it: options}]

{pstd}
Performs origin-destination analysis that replicates what
{browse "https://onthemap.ces.census.gov/":OnTheMap}
does when running {cmd:Analysis Type: Destination}. It uses the {it:OD}
dataset and provides a full analysis of either where workers residing in
a given area go to work ({it:home}), or a full analysis of where workers
come from to work in a specific area ({it:work}). {it:Note}: you must
first import data using the {cmd:lodes get} command and {bf:OD}
{cmd:data_type}.

{pstd}
{cmd:geography} – this string specifies the name of the geography of origin. One of the following geographies can be selected:

{phang2} • {it:bgrp} – US Census Block Group{p_end}
{phang2} • {it:trct} – US Census Tract{p_end}
{phang2} • {it:zcta} – US Census Zip Code Tabulation Area{p_end}
{phang2} • {it:cty} – US County{p_end}
{phang2} • {it:stplc} – US Census Place{p_end}
{phang2} • {it:cbsa} – US Census Combined Statistical Area{p_end}
{phang2} • {it:cty} – US County{p_end}
{phang2} • {it:st} – US State{p_end}
{phang2} • {it:polygon} - custom shapefile polygon{p_end}

{pstd}
{cmd:polygon} represents the name of the zipped file containing the {browse "https://doc.arcgis.com/en/arcgis-online/reference/shapefiles.htm":ESRI} shapefile defining a polygon that must be supplied.

{pstd}
{cmd:shapedir} – this string must be supplied if the oname geography is {cmd:polygon}. It points the directory where the {browse "https://doc.arcgis.com/en/arcgis-online/reference/shapefiles.htm":ESRI} zipped shapefile is located. 

{pstd}
{cmd:origin} – By specifying {it:home}, it means you are analyzing where resident workers in the selected geography go to work. 
By specifying {it:work}, it means you are analyzing where workers working in the selected geography reside. 
The default is {it:home}.

{pstd}
{cmd:dname} – geography of destination. Can be any of the geographies listed above. 

{pstd}
{cmd:oname_id} – This string allows selecting to retain output only for a specific geography id.

{pstd}
{cmd:top_loc} – This string allows selecting to retain only the {it:top x} output locations ranked by number of jobs by job type. 
 
{pstd}
{cmd:saveas} – save output as a Stata dataset.

{pstd}
{cmd:exportexcel} – if {cmd:saveas()} is specified, export output to an Excel spreadsheet.

{pstd}
{cmd:replace} – if {it:saveas()} is specified, overwrite the existing files.

{pstd}
{cmd:saveframes} – if {it:saveas()} is specified, save the imported data as a Stata frame. 
This option saves two data frames, the main data imported for analysis (e.g., {it:od}) 
and the selected state geography cross walk frame (e.g., {it:fl_xwalk}). 

{pstd}
{cmd:deleteframe} – remove the generated output frames.

{pstd}
{cmd:browse} – browse the output data frame.

{marker inflow_outflow}{...}
{dlgtab:lodes inflow_outflow}

{title:Syntax}

{pstd} {cmd:lodes inflow-outflow} {it:geography} [,{it: options}]

{pstd}
Performs origin-destination analysis that replicates what
{browse "https://onthemap.ces.census.gov/":OnTheMap}
does when running Analysis Type: Destination. It uses the {it:OD} dataset
and provides a full analysis of either where workers residing in a given
area go to work (home) or a full analysis of where workers come from to
work in a specific area (work). {it:Note}: you must first import data
using the {cmd:lodes get} command and {bf:OD} {cmd:data_type}.

{pstd}
{cmd:geography} – this string specifies the name of the geography of reference. One of the following geographies can be selected:

{phang2} • {it:bgrp} – US Census Block Group{p_end}
{phang2} • {it:trct} – US Census Tract{p_end}
{phang2} • {it:zcta} – US Census Zip Code Tabulation Area{p_end}
{phang2} • {it:cty} – US County{p_end}
{phang2} • {it:stplc} – US Census Place{p_end}
{phang2} • {it:cbsa} – US Census Combined Statistical Area{p_end}
{phang2} • {it:cty} – US County{p_end}
{phang2} • {it:st} – US State{p_end}
{phang2} • {it:polygon} - custom shapefile polygon{p_end}

{pstd}
{cmd:polygon} represents the name of the zipped file containing the {browse "https://doc.arcgis.com/en/arcgis-online/reference/shapefiles.htm":ESRI} shapefile defining a polygon that must be supplied.

{pstd}
{cmd:shapedir} – this string must be supplied if the oname geography is {cmd:polygon}. It points the directory where the {browse "https://doc.arcgis.com/en/arcgis-online/reference/shapefiles.htm":ESRI} zipped shapefile is located.

{pstd}
{cmd:geo_id} - This string allows selecting to retain output only for a specific geography id. When using a shapefile polygon, 
this feature is automatically activated to retain only data for the polygon. 

{pstd}
{cmd:work_seg} - this string specifies which job cohorts or types. Following the {browse "https://lehd.ces.census.gov/doc/help/onthemap/LODESTechDoc.pdf":LODES Technical Documentation}, the analysis can be done for the following job cohorts/types:

{phang2} • {it:S000} – Total number of jobs{p_end}
{phang2} • {it:SA01} – Number of jobs of workers age 29 or younger {p_end}
{phang2} • {it:SA02} – Number of jobs for workers age 30 to 54{p_end}
{phang2} • {it:SA03} – Number of jobs for workers age 55 or older{p_end}
{phang2} • {it:SE01} – UNumber of jobs with earnings $1250/month or less{p_end}
{phang2} • {it:SE02} – Number of jobs with earnings $1251/month to $3333/month{p_end}
{phang2} • {it:SE03} – Number of jobs with earnings greater than $3333/month{p_end}
{phang2} • {it:SI01} – Number of jobs in Goods Producing industry sectors{p_end}
{phang2} • {it:SI02} – Number of jobs in Trade, Transportation, and Utilities industry sectors{p_end}
{phang2} • {it:SI03} – Number of jobs in All Other Services industry sectors{p_end}

{pstd}
{cmd:saveas} – save output as a Stata dataset.

{pstd}
{cmd:exportexcel} – if {cmd:saveas()} is specified, export output to an Excel spreadsheet.

{pstd}
{cmd:replace} – if {it:saveas()} is specified, overwrite the existing files.

{pstd}
{cmd:saveframes} – if {it:saveas()} is specified, save the imported data as a Stata frame. 
This option saves two data frames, the main data imported for analysis (e.g., {it:od}) 
and the selected state geography cross walk frame (e.g., {it:fl_xwalk}). 

{pstd}
{cmd:deleteframe} – remove the generated output frames.

{pstd}
{cmd:browse} – browse the output data frame.

{marker area_profile}{...}
{dlgtab:lodes area_profile}

{title:Syntax}

{pstd} {cmd:lodes area_profile} {it:geography} [,{it: options}]

{pstd}
Performs detailed profile analysis of any geographic area, replicating
what {browse "https://onthemap.ces.census.gov/":OnTheMap} does when
running Analysis Type: Area Analysis. It uses either the {it:WAC} or
{it:RAC} datasets and provides a full profile analysis based on either
where workers reside ({it:WAC}), or where they work ({it:RAC}) in the
selected geography.

{pstd}
{cmd:geography} – this string specifies the name of the geography of reference. One of the following geographies can be selected:

{phang2} • {it:bgrp} – US Census Block Group{p_end}
{phang2} • {it:trct} – US Census Tract{p_end}
{phang2} • {it:zcta} – US Census Zip Code Tabulation Area{p_end}
{phang2} • {it:cty} – US County{p_end}
{phang2} • {it:stplc} – US Census Place{p_end}
{phang2} • {it:cbsa} – US Census Combined Statistical Area{p_end}
{phang2} • {it:cty} – US County{p_end}
{phang2} • {it:st} – US State{p_end}
{phang2} • {it:polygon} - custom shapefile polygon{p_end}

{pstd}
{cmd:polygon} represents the name of the zipped file containing the {browse "https://doc.arcgis.com/en/arcgis-online/reference/shapefiles.htm":ESRI} shapefile defining a polygon that must be supplied.

{pstd}
{cmd:shapedir} – this string must be supplied if the oname geography is {cmd:polygon}. It points the directory where the {browse "https://doc.arcgis.com/en/arcgis-online/reference/shapefiles.htm":ESRI} zipped shapefile is located.

{pstd}
{cmd:geo_id} – This string allows selecting to retain output only for a specific geography id. 
When using a shapefile polygon, this feature is automatically activated to retain only data for the polygon. 

{pstd}
{cmd:work_seg} – this string specifies which job types, cohorts, and industry sectors. 
Refer to the {browse "https://lehd.ces.census.gov/doc/help/onthemap/LODESTechDoc.pdf":LODES Technical Documentation} 
for a full list job types, cohorts, and industry sectors. 

{pstd}
{cmd:saveas} – save output as a Stata dataset.

{pstd}
{cmd:exportexcel} – if {cmd:saveas()} is specified, export output to an Excel spreadsheet.

{pstd}
{cmd:replace} – if {it:saveas()} is specified, overwrite the existing files.

{pstd}
{cmd:saveframes} – if {it:saveas()} is specified, save the imported data as a Stata frame. 
This option saves two data frames, the main data imported for analysis (e.g., {it:od}) 
and the selected state geography cross walk frame (e.g., {it:fl_xwalk}). 

{pstd}
{cmd:deleteframe} – remove the generated output frames.

{pstd}
{cmd:browse} – browse the output data frame.

{marker examples}{...}
{dlgtab:Examples}

{title:Importing data}

{phang} {bf: Example 1:} {bf:. lodes get FL}

{pstd}
imports Origin-Destination (OD) data for the state of Florida using default values: latest data release, and all jobs (JT00). 
Note: some states do not have data for latest data release. In this instance, the program stops and tells you what is available. 

{pstd}
{bf: Example 2:} {bf:. lodes get CA, data_type(RAC) years(2018-2023) job_type(JT03)saveas({it:[your_directory]}/ca_rac_jt03_2018_2023)}
		
{pstd}
imports data resident area characteristics (RAC) for California, Private Jobs (JT03), years 2018-2023 - saves data frames 
		
{title: Performing Destination Analysis}

{pstd}
{it:Note}: to run the example below, you must first obtain the data using {cmd:lodes get fl}.

{phang} {bf: Example 1:} {bf:. lodes destination zcta, dname(stplc)}

{pstd}
Analyzes in which US Census places workers residing in the zip codes go to work using the latest data release, all jobs (JT00). 

{phang} {bf: Example 2:} {bf:. lodes destination zcta, dname(zcta) oname_id(33617) top_loc(20) saveas({it:[your_directory]}/zcta_33617_dest_example) replace saveframes}
		
{pstd}
Analyses in which US zip codes workers residing in zip code 33617 go to work, focusing on the top 20 zip codes by total employment. 
Data are saved and frames exported. 


{title:Performing Inflow-Outflow Analysis}

{pstd}
{it:Note}: to run the example below, you must first obtain the data using {cmd:lodes get fl}.

{phang} {bf: Example 1:} {bf:. lodes inflow_outflow zcta, work_seg(SA01 SA02 SA03)}

{pstd}
Analyses inflow-outflow of workers at zip code level by age cohorts 
(see {browse "https://lehd.ces.census.gov/doc/help/onthemap/LODESTechDoc.pdf":LODES Technical Documentation}).

{phang} {bf: Example 2:} {bf:. lodes inflow_outflow tampa_cbd, shapedir({it:[shapefile_directory]}) work_seg (S000 SA01 SA02 SA03 SE01 SE02 SE03) saveas({it:[your_directory]}/tampa_cbd_inflow_outflow_example) exportexcel replace deleteframes saveframes}

{pstd}
{it:Note}: to run the example above, you must first obtain the data using {cmd: lodes get fl, data_type(od)  years(2021-2023) od_part(main)}

{pstd}
Analyses inflow-outflow of workers using a custom polygon (here, the Tampa CBD, Florida) focusing on all jobs 
and for years 2021-2023 to conduct trend analysis. Data are saved as Stata file and exported as Excel. Data frame is deleted. 

{title:Performing Area Profile Analysis}

{pstd}
{it:Note}: to run the example below, you must first obtain the data using  {cmd:lodes get FL, data_type(wac) years(2021-2023)}

{phang} {bf: Example 1:} {bf:. lodes area_profile cbsa, geo_id(45300) work_seg(C000 CNS16) browse}

{pstd}
runs a profile analysis of workers area characteristics years 2021-2023
for the Tampa-St.Petersburg-Clearwater Metropolitan Statistical Area,
focusing on total jobs (C000) and jobs in the Health Care and Social
Assistance industry sector (CNS16). See
{browse "https://lehd.ces.census.gov/doc/help/onthemap/LODESTechDoc.pdf":LODES Technical Documentation}
for WAC file structure.

{phang} {bf: Example 2:} {bf:. lodes area_profile tampa_cbd, shapedir({it:[shapefile_directory]}) saveas({it:[your_directory]}/tampa_cbd_profile_example) exportexcel replace browse}

{pstd}
Runs a profile analysis of workers area characteristics for the years
2021-2023 using a custom ESRI shapefile called {it:tampa_cbd}
representing the Tampa Central Business District, Florida, obtaining data
on all jobs by age cohort and industry sectors. Data are saved as a Stata
file and exported as Excel. See
{browse "https://lehd.ces.census.gov/doc/help/onthemap/LODESTechDoc.pdf":LODES Technical Documentation}
for WAC and RAC file structure.


	
{marker author}{...}
{title:Author & Maintainer}

{pstd}
Sisinnio Concas{break}
email: {browse "mailto:concas@usf.edu":concas@usf.edu}{break}
{browse "https://cutr.usf.edu/":Center for Urban Transportation Research}
{p_end}