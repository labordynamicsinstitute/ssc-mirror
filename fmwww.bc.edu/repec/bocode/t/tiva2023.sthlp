{smcl}
{* *! version 28 décembre 8, 2023 @ 13:05:39}{...}
{* delete if no dialog box}{...}
{viewerdialog "tiva2023" "dialog tiva2023"}{...}
{* link to manual entries (really meant for stata to link to its own docs}{...}
	{vieweralsosee "[?] whatever" "mansection ? whatever"}{...}
	{* a divider if needed}{...}
	{vieweralsosee "" "--"}{...}
	{* link to other help files which could be of use}{...}
	{vieweralsosee "[?] whatever" "help whatever "}{...}
	{viewerjumpto "Syntax" "tiva2023##syntax"}{...}
	{viewerjumpto "Description" "tiva2023##description"}{...}
	{viewerjumpto "Options" "tiva2023##options"}{...}
	{viewerjumpto "Indicator List" "tiva2023##indList"}{...}
	{viewerjumpto "Remarks" "tiva2023##remarks"}{...}
	{viewerjumpto "Examples" "tiva2023##examples"}{...}
	{viewerjumpto "Stored Results" "tiva2023##stored_results"}{...}
	{viewerjumpto "Acknowledgements" "tiva2023##acknowledgements"}{...}
	{viewerjumpto "Author" "tiva2023##author"}{...}
	{viewerjumpto "References" "tiva2023##references"}{...}
	{...}
	{title:tiva2023}

	{phang}
	{cmd:tiva2023} {hline 2} Manipulate OECD TiVA database (version 2023)
	{p_end}

	{marker syntax}{...}
	{title:Syntax}

	{text} Do not forget to run {bf:tiva2023_compile} for a first use after a "clear/clear mata/clear all" (see example).

	{* put the syntax in what follows. Don't forget to use [ ] around optional items}{...}
	{p 8 16 2}
   {cmd: tiva2023}
   main
   {cmd:,}
   {it:path(string) indicator(string) [year(string)] [cou(string)] par(string) [ind(string)]}
	{p_end}

	{* the new Stata help format of putting detail before generality}{...}
	{synoptset 20 tabbed}{...}
	{synopthdr}
	{synoptline}
	{syntab:main}
	{synopt:{opt calc}}Calculates the indicator in indicator() {p_end}
	{synopt:{opt load}}Loads the TiVA2023 elements into mata format (see mata: mata describe after running the command){p_end}
	{synoptline}
	{syntab:options}
	{synopt:{opt path}}path of the .zip ICIO files{p_end}
	{synopt:{opt indicator}}Indicator that should be calculated{p_end}
	{synopt:{opt year}}For which year(s)?{p_end}
	{synopt:{opt cou}}For which countries?{p_end}
	{synopt:{opt par}}For which partners?{p_end}
	{synopt:{opt ind}}For which industries?{p_end}
	{synoptline}

	{p2colreset}{...}


	{marker description}{...}
	{title:Description}

	{pstd}
	{cmd:tiva2023} tiva2023 imports OECD's TiVA database into mata objects and calculates indicators.
	{p_end}

	{marker indList}{...}
	{title:Indicator list}

	{phang}{cmd:GOP} Gross output.{p_end}
	{phang}{cmd:GVA} Gross value added.{p_end}
	{phang}{cmd:Y} Final demand.{p_end}
	{phang}{cmd:Z} Intermediate inputs matrix.{p_end}
	{phang}{cmd:B} Global Leontief matrix.{p_end}
	{phang}{cmd:L} Local Leontief matrix.{p_end}
	{phang}{cmd:EXGR} Gross exports.{p_end}
	{phang}{cmd:EXGR_INT} Gross exports.{p_end}
	{phang}{cmd:EXGR_FNL} Gross exports.{p_end}
	{phang}{cmd:IMGR} Gross imports.{p_end}
	{phang}{cmd:IMGR_INT} Gross imports.{p_end}
	{phang}{cmd:IMGR_FNL} Gross imports.{p_end}
	{phang}{cmd:BACKWARD} Foreign value added in exports.{p_end}
	{phang}{cmd:FORWARD} Domestic value added in foreign countries' exports.{p_end}

	{synoptline}

   {phang} Unit value indicators (unit: 1 USD) {p_end}

	{phang}{cmd:UV_DOWNSTREAMNESS} Downstreamness measure where UV stands for unit value (see Chor, Fally,... (2017)).{p_end}
	{phang}{cmd:UV_UPSTREAMNESS} Upstreamness measure where UV stands for unit value (see Chor, Fally,... (2017)).{p_end}
	{phang}{cmd:UV_DOM_DOWNSTREAMNESS} Domestic Downstreamness measure where UV stands for unit value (see Chor, Fally,... (2017)).{p_end}
	{phang}{cmd:UV_DOM_UPSTREAMNESS} Domestic Upstreamness measure (UV_DOWNSTREAMNESS for domestic inputs).{p_end}
	{phang}{cmd:UV_FOR_DOWNSTREAMNESS} Foreign Downstreamness measure (UV_DOWNSTREAMNESS for foreign inputs).{p_end}
	{phang}{cmd:UV_FOR_UPSTREAMNESS} Foreign Upstreamness measure (UV_DOWNSTREAMNESS for foreign inputs).{p_end}
	{phang}{cmd:UV_PII} Production import intensity (see Timmer et al. (2016)).{p_end}

	{synoptline}

	{phang}{cmd:OECD_DFD_DVA} Domestic value-added in domestic final demand.{p_end}
	{phang}{cmd:OECD_FFD_DVA} Domestic value-added in foreign final demand.{p_end}
	{phang}{cmd:OECD_DFD_FVA} Foreign value-added in domestic final demand.{p_end}
	{phang}{cmd:OECD_FFD_FVA} Foreign value-added in foreign final demand.{p_end}
	{phang}{cmd:OECD_EXGR_DVA} Domestic value-added in exports.{p_end}
	{phang}{cmd:OECD_EXGR_FVA} Foreign value-added in exports.{p_end}
	{phang}{cmd:OECD_BACKWARD} Backward indicator.{p_end}
	{phang}{cmd:OECD_FORWARD} Forward indicator as calculated in OECD.Stat.{p_end}
	{synoptline}
	{phang}{cmd:wp_MY} Export decomposition based on on MY (2020) -- world perspective.{p_end}
	{phang}{cmd:cp_MY} Export decomposition based on on MY (2020) -- country perspective.{p_end}
	{phang}{cmd:bp_MY} Export decomposition based on on MY (2020) -- bilateral perspective.{p_end}

	{marker remarks}{...}
	{title:Remarks}

	{pstd}
	tiva2023 creates .mmat files where ICIO elements of OECD's TiVA database are retrieved.
	The major elements are the intermediate inputs and the final demand matrices as well as the
	gross value added and gross output vectors. Also, it creates dimensions, descriptions (year, countries, industries), element-wise multiplication and transition matrices to facilitate the calculations.

	{pstd}
	When {cmd:load} is the option, those vectors are only loaded (see example).
	Otherwise, the option must be {cmd:calc} to calculate the indicator in the indicator() option (see example).
	{p_end}

	{marker examples}{...}
	{title:Examples}

	{phang}{cmd:. clear mata}{break}{p_end}
	{phang}{cmd:. tiva2023_compile}{break}
	Produces the tiva2023() mata class that stores all the necessary objects.
	{break}
	{p_end}
	{phang}
	{cmd:. tiva2023 calc, path(V:/Cadestin_C/BACKUP/raw/TiVA2023/RELEASE/) indicator(GVA) year(2015) cou(FRA) ind(D01T03) clear}
	{break}
	Imports the data, calculates "GVA" for 2015, FRA, D01T03 and stores in as a database.
	{p_end}

	{phang}{cmd:. tiva2023 load, path(V:/Cadestin_C/BACKUP/raw/TiVA2023/RELEASE/)}{break}
	mata:{break}
	mata describe{break}
	data = tiva2023(){break}
	data.importMatrices("V:/Cadestin_C/BACKUP/raw/TiVA2023/RELEASE/"){break}
	data.GVA(2015)[1..5]{break}
	end{break}
	First five observations of the gross value added vector.
	{p_end}

	{marker author}{...}
	{title:Author}

	{pstd}
	charles.cadestin@oecd.org


	{marker references}{...}
	{title:References}

	{pstd}
	{marker indCov}{...}
	{browse "http://www.oecd.org/sti/ind/inter-country-input-output-tables.htm":{it:TiVA ICIO webpage}.}

	{pstd}
	{marker couCov}{...}
	{browse "http://stats.oecd.org/wbos/fileview2.aspx?IDFile=ff21d24e-e9ec-473d-9fcf-a33a9651bf52":{it:TiVA geographical coverage}.}

	{pstd}
	{marker indCov}{...}
	{browse "http://stats.oecd.org/wbos/fileview2.aspx?IDFile=ffa98d43-add6-4d6b-ab5d-efdcb84f1bf8":{it:TiVA industry coverage}.}


