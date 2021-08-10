/*******************************************************************************	
	
	Author: Sebastien Fontenay (UCL - sebastien.fontenay@uclouvain.be)
	Version: 1.0.0
	Last update: August, 2016
	
	This program uses the package "moss" by Robert Picard & Nicholas J. Cox
	You can install it from SSC: ssc install moss
	
*******************************************************************************/

program define sdmxuse
version 13.0
syntax namelist(min=2 max=2) [, clear dataset(string) dimensions(string) attributes start(string) end(string) timeseries panel(string)]

quietly {

// Check wether the package "moss" by Robert Picard & Nicholas J. Cox is installed

which moss

// Create local macros

tokenize `namelist'
local resource "`1'"
local provider "`2'"

if "`provider'"=="ECB" {
	local url "http://sdw-wsrest.ecb.europa.eu/service/"
}
if "`provider'"=="ESTAT" {
	local url "http://ec.europa.eu/eurostat/SDMX/diss-web/rest/"
}
if "`provider'"=="IMF" {
	local url "http://sdmxws.imf.org/SDMXRest/"
}
if "`provider'"=="OECD" {
	local url "http://stats.oecd.org/restsdmx/sdmx.ashx//"
}
if "`provider'"=="WB" {
	local url "http://api.worldbank.org/"
}

// Error message

if ("`resource'"=="datastructure" & "`dataset'"=="") | ("`resource'"=="data" & "`dataset'"=="") {
	noisily display in red "You must specify the dataset identifier with the following option [, dataset()]"
	exit
}

// Clear data

if `"`clear'"' == "clear" {
	clear
} 
if (c(changed) == 1) & (`"`clear'"' == "" ) {
	error 4
}

/***********************************************************************
Dataflow
************************************************************************/

if "`resource'"=="dataflow" {

	// Build and send query
	
	if "`provider'"=="ECB" {
		copy "`url'dataflow/ECB/" sdmxdataflow.txt, replace
	}
	if "`provider'"=="ESTAT" {
		copy "`url'dataflow/ESTAT/" sdmxdataflow.txt, replace
	}
	if "`provider'"=="IMF" {
		copy "`url'GetKeyFamily/ALL/" sdmxdataflow.txt, replace
	}
	if "`provider'"=="OECD" {
		copy "`url'GetDataStructure/ALL/" sdmxdataflow.txt, replace
	}
	if "`provider'"=="WB" {
		noisily di in red "Only WDI (World Development Indicators) are available from the World Bank"
		exit
	}

	// Import data into Stata

	if "`provider'"=="OECD" | "`provider'"=="IMF" {
		local dataflow_id="<KeyFamily id="
	}
	if "`provider'"=="ESTAT" | "`provider'"=="ECB" {
		local dataflow_id="<Dataflow id="
	}
	if "`provider'"=="ESTAT" | "`provider'"=="ECB" {
		filefilter sdmxdataflow.txt sdmxdataflow2.txt, from("str:") to ("") replace
		erase sdmxdataflow.txt
		!rename sdmxdataflow2.txt sdmxdataflow.txt
		filefilter sdmxdataflow.txt sdmxdataflow2.txt, from("com:") to ("") replace
		erase sdmxdataflow.txt
		!rename sdmxdataflow2.txt sdmxdataflow.txt
	}
	filefilter sdmxdataflow.txt sdmxdataflow2.txt, from("\n") to ("") replace
	erase sdmxdataflow.txt
	!rename sdmxdataflow2.txt sdmxdataflow.txt
	filefilter sdmxdataflow.txt sdmxdataflow2.txt, from("\r") to ("") replace
	erase sdmxdataflow.txt
	!rename sdmxdataflow2.txt sdmxdataflow.txt
	filefilter sdmxdataflow.txt sdmxdataflow2.txt, from("`dataflow_id'") to ("\r\n`dataflow_id'") replace
	erase sdmxdataflow.txt
	!rename sdmxdataflow2.txt sdmxdataflow.txt

	import delimited sdmxdataflow.txt, clear delimiters("|||", asstring) rowrange(2) varnames(nonames)

	// Format dataset

	replace v1=substr(v1, 1, strpos(v1, "</Name>")+6)
	moss v1, match(`"`dataflow_id'"([a-zA-Z0-9_-]+)"') regex
	rename _match1 dataflow_id
	drop _*
	moss v1, match(`"<Name xml:lang="en">(.*)</Name>"') regex
	rename _match1 dataflow_description
	drop _* v1

	// Erase text file with raw data

	cap erase sdmxdataflow.txt
}

/***********************************************************************
Datastructure
************************************************************************/

if "`resource'"=="datastructure" {

	// ECB dataflow_id does not match datastructure_id
	
	if "`provider'"=="ECB" {
		copy "`url'dataflow/ECB/`dataset'" sdmxdataflow.txt, replace
		import delimited sdmxdataflow.txt, clear varnames(nonames)
		keep if regexm(v1, "<Ref id=")
		moss v1, match(`"<Ref id="([a-zA-Z0-9_-]+)"') regex
		rename _match1 datastructure_id
		drop _* v1
		local dataset=datastructure_id[1]
		cap erase sdmxdataflow.txt
	}

	// Build and send query

	if "`provider'"=="ECB" {
		copy "`url'datastructure/ECB/`dataset'/?references=children" sdmxdatastructure.txt, replace
	}
	if "`provider'"=="ESTAT" {
		copy "`url'datastructure/ESTAT/DSD_`dataset'" sdmxdatastructure.txt, replace
	}
	if "`provider'"=="IMF" {
		copy "`url'sdmx.ashx/GetKeyFamily/`dataset'" sdmxdatastructure.txt, replace
	}
	if "`provider'"=="OECD" {
		copy "`url'GetDataStructure/`dataset'" sdmxdatastructure.txt, replace
	}
	if "`provider'"=="WB" {
		copy "`url'KeyFamily?id=`dataset'" sdmxdatastructure.txt, replace
	}

	// Import data into Stata

	if "`provider'"=="ESTAT" | "`provider'"=="ECB" {
		filefilter sdmxdatastructure.txt sdmxdatastructure2.txt, from("str:") to ("") replace
		erase sdmxdatastructure.txt
		!rename sdmxdatastructure2.txt sdmxdatastructure.txt
		filefilter sdmxdatastructure.txt sdmxdatastructure2.txt, from("com:") to ("") replace
		erase sdmxdatastructure.txt
		!rename sdmxdatastructure2.txt sdmxdatastructure.txt
	}
	if "`provider'"=="WB" {
		filefilter sdmxdatastructure.txt sdmxdatastructure2.txt, from("structure:") to ("") replace
		erase sdmxdatastructure.txt
		!rename sdmxdatastructure2.txt sdmxdatastructure.txt
	}
	if "`provider'"=="OECD" | "`provider'"=="IMF" | "`provider'"=="WB" {
		filefilter sdmxdatastructure.txt sdmxdatastructure2.txt, from("<CodeList id=") to ("<Codelist id=") replace
		erase sdmxdatastructure.txt
		!rename sdmxdatastructure2.txt sdmxdatastructure.txt
	}
	filefilter sdmxdatastructure.txt sdmxdatastructure2.txt, from("\n") to ("") replace
	erase sdmxdatastructure.txt
	!rename sdmxdatastructure2.txt sdmxdatastructure.txt
	filefilter sdmxdatastructure.txt sdmxdatastructure2.txt, from("\r") to ("") replace
	erase sdmxdatastructure.txt
	!rename sdmxdatastructure2.txt sdmxdatastructure.txt
	copy sdmxdatastructure.txt codelists.txt, replace

	// Data structure

	if "`provider'"=="ESTAT" | "`provider'"=="ECB" {
	local id "id"
	}
	if "`provider'"=="IMF" | "`provider'"=="WB" {
	local id "conceptRef"
	}
	if "`provider'"=="OECD" {
	local id "codelist"
	}
	filefilter sdmxdatastructure.txt sdmxdatastructure2.txt, from("<Dimension `id'=") to ("\r\n<Dimension `id'=") replace
	erase sdmxdatastructure.txt
	!rename sdmxdatastructure2.txt sdmxdatastructure.txt
	import delimited sdmxdatastructure.txt, clear delimiters("|||", asstring) rowrange(2) varnames(nonames)

	tempfile dimensions
	if "`provider'"=="ESTAT" | "`provider'"=="ECB" {
		replace v1=substr(v1, 1, strpos(v1, "</Dimension>")+11)
	}
	if "`provider'"=="IMF" | "`provider'"=="OECD" | "`provider'"=="WB" {
		replace v1=substr(v1, 1, strpos(v1, "/>")+1)
	}
	if "`provider'"!="OECD" {
		moss v1, match(`"<Dimension `id'="([a-zA-Z0-9_-]+)"') regex
		rename _match1 concept
		drop _*
	}
	if "`provider'"=="OECD" {
		moss v1, match(`"conceptRef="([a-zA-Z0-9_-]+)"') regex
		rename _match1 concept
		drop _*
	}
	if "`provider'"=="ESTAT" {
		gen codelist=concept
	}
	if "`provider'"=="ECB" {
		gen enumeration=substr(v1, strpos(v1, "<Enumeration>"), .)
		moss enumeration, match(`"<Ref id="CL_([a-zA-Z0-9_-]+)"') regex
		rename _match1 codelist
		drop _*	enumeration
	}
	if "`provider'"=="IMF" | "`provider'"=="WB" {
		moss v1, match(`"codelist="CL_([a-zA-Z0-9_-]+)"') regex
		rename _match1 codelist
		drop _*
	}
	if "`provider'"=="OECD" {
		moss v1, match(`"<Dimension `id'="CL_([a-zA-Z0-9_-]+)"') regex
		rename _match1 codelist
		drop _*
	}
	if "`provider'"=="ESTAT" | "`provider'"=="ECB" {
		moss v1, match(`"position="([0-9]+)"') regex
		rename _match1 position
		destring position, replace
		drop _*
		sort position
	}
	if "`provider'"=="IMF" | "`provider'"=="OECD" {
		gen position=_n
	}
	if "`provider'"=="WB" {
		gen position=1 if concept=="REF_AREA"
		replace position=2 if concept=="SERIES"
		drop if concept=="FREQ"
		sort position
	}
	drop v1

	local _concept ""
	qui count
	forvalues i=1/`r(N)' {
		if `i'!=`r(N)'{
			local _concept="`_concept'"+concept[`i']+"."
		}
		if `i'==`r(N)' {
			local _concept="`_concept'"+concept[`i']
		}
	}
	noisily di "Order of dimensions: (`_concept')"
	sum position
	local position_nb=r(N)
	save `dimensions', replace

	// Codelists

	if "`provider'"=="OECD" | "`provider'"=="IMF" | "`provider'"=="WB" {
		local dataset_id="<Code value="
	}
	if "`provider'"=="ESTAT" | "`provider'"=="ECB" {
		local dataset_id="<Code id="
	}
	filefilter codelists.txt codelists2.txt, from("<Codelist id=") to ("\r\n<Codelist id=") replace
	erase codelists.txt
	!rename codelists2.txt codelists.txt
	filefilter codelists.txt codelists2.txt, from("`dataset_id'") to ("\r\n`dataset_id'") replace
	erase codelists.txt
	!rename codelists2.txt codelists.txt

	import delimited codelists.txt, clear delimiters("|||", asstring) rowrange(2) varnames(nonames)

	// Format dataset

	if "`provider'"=="ESTAT" {
		replace v1=substr(v1, 1, strpos(v1, "<Concepts>")-1) if regexm(v1, "<Concepts>")
	}
	if "`provider'"=="ECB" {
		replace v1=substr(v1, 1, strpos(v1, "</Name>")+13) if regexm(v1, "</Name>")
	}
	if "`provider'"=="OECD" | "`provider'"=="IMF" | "`provider'"=="WB" {
		replace v1=substr(v1, 1, strpos(v1, "</Description>")+13) if regexm(v1, "</Description>")
	}
	if "`provider'"=="OECD" {
		replace v1=substr(v1, 1, strpos(v1, "</Name>")+6) if regexm(v1, "<Codelist id=")
	}

	gen series=regexm(v1, "<Codelist")
	replace series=sum(series)

	preserve
	tempfile concept
	keep if regexm(v1, "<Codelist id=")
	moss v1, match(`"<Codelist id="CL_([a-zA-Z0-9_-]+)"') regex
	rename _match1 concept
	drop _* v1
	save `concept', replace

	restore
	tempfile codes
	keep if !regexm(v1, "<Codelist id=")
	moss v1, match(`"`dataset_id'"([a-zA-Z0-9_-]+)"') regex
	rename _match1 code
	drop _*
	if "`provider'"=="ESTAT" | "`provider'"=="ECB" {
		moss v1, match(`"xml:lang="en">(.*)</Name>"') regex
	}
	if "`provider'"=="WB" {
		replace v1=subinstr(v1, "<![CDATA[", "", .)
		replace v1=subinstr(v1, "]]>", "", .)
	}
	if "`provider'"=="OECD" | "`provider'"=="IMF" | "`provider'"=="WB" {
		moss v1, match(`"xml:lang="en">(.*)</Description>"') regex
	}
	rename _match1 code_lbl
	drop _* v1
	save `codes', replace

	use `concept', clear
	merge 1:m series using `codes', nogenerate
	drop series
	rename concept codelist
	save `concept', replace

	forvalues i=1/`position_nb' {
		use `dimensions' if position==`i', clear
		merge 1:m codelist using `concept', nogenerate keep(3)
		tempfile dim`i'
		save `dim`i'', replace
	}
	use `dim1', clear
	forvalues i=2/`position_nb' {
		append using `dim`i''
	}
	replace codelist=concept if codelist!=concept & concept!=""
	drop concept
	rename codelist concept
	if "`provider'"=="IMF" | "`provider'"=="OECD" {
		replace concept=subinstr(concept, "`dataset'_", "", 1)	
	}
	if "`provider'"=="WB" {
		replace concept=subinstr(concept, "_`dataset'", "", 1)	
	}
	order position, after(concept)
	sort position concept code

	// Erase text file with raw data

	cap erase sdmxdatastructure.txt
	cap erase codelists.txt
}

/***********************************************************************
Data
************************************************************************/

if "`resource'"=="data" {

	// Build and send query

	if "`provider'"!="IMF" & "`dimensions'"!="" {
		local dimensions "/`dimensions'"
	}
	if ("`provider'"=="OECD" | "`provider'"=="IMF") & "`start'"!="" {
		local start "&startTime=`start'"
	}
	if ("`provider'"=="ESTAT" | "`provider'"=="ECB" | "`provider'"=="WB") & "`start'"!="" {
		local start "&startPeriod=`start'"
	}
	if ("`provider'"=="OECD" | "`provider'"=="IMF") & "`end'"!="" {
		local end "&endTime=`end'"
	}
	if ("`provider'"=="ESTAT" | "`provider'"=="ECB" | "`provider'"=="WB") & "`end'"!="" {
		local end "&endPeriod=`end'"
	}

	local detail "dataonly"
	if "`attributes'"!="" {
		local detail "full"
	}
	
	if "`provider'"=="ECB" {
		copy "`url'data/`dataset'`dimensions'/all?&detail=`detail'`start'`end'" sdmxfile.txt, replace
	}
	if "`provider'"=="ESTAT" {
		copy "`url'data/`dataset'`dimensions'/all?&detail=`detail'`start'`end'" sdmxfile.txt, replace
	}
	if "`provider'"=="IMF" {
		copy "`url'sdmx.ashx/GetData?dataflow=`dataset'&key=`dimensions'&detail=`detail'`start'`end'" sdmxfile.txt, replace
	}
	if "`provider'"=="OECD" {
		copy "`url'GetData/`dataset'`dimensions'/all?&detail=`detail'`start'`end'" sdmxfile.txt, replace
	}
	if "`provider'"=="WB" {
		copy "`url'v2/data/`dataset'`dimensions'/?&detail=`detail'`start'`end'" sdmxfile.txt, replace
	}

	// Import data into Stata

	if "`provider'"=="ESTAT" | "`provider'"=="ECB" | "`provider'"=="WB" {
		filefilter sdmxfile.txt sdmxfile2.txt, from("generic:") to ("") replace
		erase sdmxfile.txt
		!rename sdmxfile2.txt sdmxfile.txt
	}
	filefilter sdmxfile.txt sdmxfile2.txt, from("\n") to ("") replace
	erase sdmxfile.txt
	!rename sdmxfile2.txt sdmxfile.txt
	filefilter sdmxfile.txt sdmxfile2.txt, from("\r") to ("") replace
	erase sdmxfile.txt
	!rename sdmxfile2.txt sdmxfile.txt
	filefilter sdmxfile.txt sdmxfile2.txt, from("<Obs>") to ("\r\n<Obs>") replace
	erase sdmxfile.txt
	!rename sdmxfile2.txt sdmxfile.txt
	filefilter sdmxfile.txt sdmxfile2.txt, from("<Series>") to ("\r\n<Series>") replace
	erase sdmxfile.txt
	!rename sdmxfile2.txt sdmxfile.txt
	import delimited sdmxfile.txt, clear delimiters("|||", asstring) rowrange(2) varnames(nonames)
	if "`provider'"!="ESTAT"  {
		count
		if r(N)==0  {
			noisily display in red "The query did not match any time series - check again the dimensions' values or download the full dataset"
			cap erase sdmxfile.txt
			exit
		}
	}
	* ESTAT's query limitation
	if "`provider'"=="ESTAT"  {
		count
		if r(N)==0 {
			import delimited sdmxfile.txt, clear delimiters("|||", asstring) varnames(nonames)
			if regexm(v1, "Query size exceeds maximum") {
				noisily di in red "Query size exceeds maximum limit set by Eurostat: 1,000,000 entries - Try to refine the query by using the option [, dimensions()]"
				cap erase sdmxfile.txt
				exit
			}
			if regexm(v1, "Due to the large query the response") {
				moss v1, match(`"<common:Text xml:lang="en">http://ec.europa.eu/eurostat/SDMX/diss-web/file/(.*)</common:Text><common:Text xml:lang="en">"') regex
				rename _match1 estat_url
				local estat_url=estat_url[1]
				noisily di in green "Due to the large query (above 30,000 cells), Eurostat will post the file to a different repository - the processing of the file may take up to 5 minutes"
				sleep 100000
				cap copy  "http://ec.europa.eu/eurostat/SDMX/diss-web/file/`estat_url'" estat_bigdataflow.zip, replace
				cap confirm file "estat_bigdataflow.zip"
				if _rc {
					sleep 100000
					copy  "http://ec.europa.eu/eurostat/SDMX/diss-web/file/`estat_url'" estat_bigdataflow.zip, replace
					cap confirm file "estat_bigdataflow.zip"
						if _rc {
							sleep 100000
							copy  "http://ec.europa.eu/eurostat/SDMX/diss-web/file/`estat_url'" estat_bigdataflow.zip, replace
							cap confirm file "estat_bigdataflow.zip"
						}
							if _rc {
								sleep 100000
								copy  "http://ec.europa.eu/eurostat/SDMX/diss-web/file/`estat_url'" estat_bigdataflow.zip, replace
								cap confirm file "estat_bigdataflow.zip"
							}
								if _rc {
									sleep 100000
									copy  "http://ec.europa.eu/eurostat/SDMX/diss-web/file/`estat_url'" estat_bigdataflow.zip, replace
									cap confirm file "estat_bigdataflow.zip"
								}
				}
				unzipfile estat_bigdataflow.zip, replace
				erase estat_bigdataflow.zip
				cap erase sdmxfile.txt
				!rename "DataResponse-`estat_url'.xml" "sdmxfile.txt"
				filefilter sdmxfile.txt sdmxfile2.txt, from("generic:") to ("") replace
				erase sdmxfile.txt
				!rename sdmxfile2.txt sdmxfile.txt
				filefilter sdmxfile.txt sdmxfile2.txt, from("\n") to ("") replace
				erase sdmxfile.txt
				!rename sdmxfile2.txt sdmxfile.txt
				filefilter sdmxfile.txt sdmxfile2.txt, from("\r") to ("") replace
				erase sdmxfile.txt
				!rename sdmxfile2.txt sdmxfile.txt
				filefilter sdmxfile.txt sdmxfile2.txt, from("<Obs>") to ("\r\n<Obs>") replace
				erase sdmxfile.txt
				!rename sdmxfile2.txt sdmxfile.txt
				filefilter sdmxfile.txt sdmxfile2.txt, from("<Series>") to ("\r\n<Series>") replace
				erase sdmxfile.txt
				!rename sdmxfile2.txt sdmxfile.txt
				import delimited sdmxfile.txt, clear delimiters("|||", asstring) rowrange(2) varnames(nonames)
			}
			else {
				noisily display in red "The query did not match any time series - check again the dimensions' values or download the full dataset"
				cap erase sdmxfile.txt
				exit
			}
		}
	}
	
	// Format dataset

	if "`provider'"=="OECD" | "`provider'"=="IMF" | "`provider'"=="WB" {
		local value_id="<Value concept="
	}
	if "`provider'"=="ESTAT" | "`provider'"=="ECB"  {
		local value_id="<Value id="
	}
	
	tempfile data
	gen series=regexm(v1, "SeriesKey")
	replace series=sum(series)
	sum series
	noisily display in green "`r(max)' serie(s) imported"
	preserve
	drop if !regexm(v1, "Obs")

	* Time
	if "`provider'"=="OECD" | "`provider'"=="IMF" | "`provider'"=="WB" {
		gen time=substr(v1, strpos(v1, "<Time>")+6, strpos(v1, "</Time>")-strpos(v1, "<Time>")-6)
	}
	if "`provider'"=="ESTAT" | "`provider'"=="ECB" {
		gen time=substr(substr(v1, strpos(v1, "<ObsDimension value=")+21, .), 1, strpos(substr(v1, strpos(v1, "<ObsDimension value=")+21, .), `"""')-1)
	}

	* Values
	gen value=substr(substr(v1, strpos(v1, "<ObsValue value=")+17, .), 1, strpos(substr(v1, strpos(v1, "<ObsValue value=")+17, .), `"""')-1)
	replace value="" if value=="NaN"
	destring value, replace

	* Attributes
	if "`attributes'"!="" {
		tempvar Attributes
		gen `Attributes'=substr(substr(v1, strpos(v1, "<Attributes>")+12,.), 1, strpos(substr(v1, strpos(v1, "<Attributes>")+12,.), "</Attributes>")-1)
		capture assert missing(`Attributes')
		if _rc {
			moss `Attributes', match(`"`value_id'"([a-zA-Z0-9_]+)""') regex
			sum _count
			local macroconcept ""
			forvalues i=1/`r(max)' {
				levelsof _match`i', clean
				local macroconcept="`macroconcept' `r(levels)'"
			}
			local macroconceptuniq : list uniq macroconcept
			foreach var of local macroconceptuniq {
				gen `var'=substr(substr(`Attributes', strpos(`Attributes', `""`var'""'), .), strpos(substr(`Attributes', strpos(`Attributes', `""`var'""'), .), "value=")+7, strpos(substr(substr(`Attributes', strpos(`Attributes', `""`var'""'), .), strpos(substr(`Attributes', strpos(`Attributes', `""`var'""'), .), "value=")+7, .), `"""')-1)
			}
			drop _*
		}
	}
	drop v1
	save `data', replace

	// Separate dimensions

	restore
	tempfile dimensions
	drop if regexm(v1, "Obs")

	* Values
	tempvar SeriesKey
	gen `SeriesKey'=substr(substr(v1, strpos(v1, "<SeriesKey>")+11,.), 1, strpos(substr(v1, strpos(v1, "<SeriesKey>")+11,.), "</SeriesKey>")-1)
	moss `SeriesKey', match(`"`value_id'"([a-zA-Z0-9_]+)""') regex
	sum _count
	local macroconcept ""
	forvalues i=1/`r(max)' {
		levelsof _match`i', clean
		local macroconcept="`macroconcept' `r(levels)'"
	}
	local macroconceptuniq : list uniq macroconcept
	foreach var of local macroconceptuniq {
		gen `var'=substr(substr(`SeriesKey', strpos(`SeriesKey', `""`var'""'), .), strpos(substr(`SeriesKey', strpos(`SeriesKey', `""`var'""'), .), "value=")+7, strpos(substr(substr(`SeriesKey', strpos(`SeriesKey', `""`var'""'), .), strpos(substr(`SeriesKey', strpos(`SeriesKey', `""`var'""'), .), "value=")+7, .), `"""')-1)
	}
	drop _*

	* Create variable serieskey if dataset needs to be reshaped
	if "`timeseries'"!="" {
		egen serieskey=concat(`macroconceptuniq'),  maxlength(32) punct("_")
		replace serieskey=lower(serieskey)
		replace serieskey=subinstr(serieskey, "-", "_", .)
		order serieskey
	}
	if "`panel'"!="" {
		capture confirm variable `panel'
		if _rc {
			local panel=strupper("`panel'")
			capture confirm variable `panel'
			if _rc {
				noisily di in red "Variable `panel' not found"
				cap erase sdmxfile.txt
				exit				
			}
		}
		local nogeo : subinstr local macroconceptuniq "`panel'" ""
		egen serieskey=concat(`nogeo'),  maxlength(32) punct("_")
		replace serieskey=lower(serieskey)
		replace serieskey=subinstr(serieskey, "-", "_", .)
		order serieskey
		local panel=strlower("`panel'")
	}

	if "`attributes'"=="" {
		drop v1
		save `dimensions', replace
	}

	* Attributes
	if "`attributes'"!="" {
		tempvar Attributes2
		gen `Attributes2'=substr(substr(v1, strpos(v1, "<Attributes>")+12,.), 1, strpos(substr(v1, strpos(v1, "<Attributes>")+12,.), "</Attributes>")-1)
		capture assert missing(`Attributes2')
		if _rc {
			moss `Attributes2', match(`"`value_id'"([a-zA-Z0-9_]+)""') regex
			sum _count
			local macroconcept ""
			forvalues i=1/`r(max)' {
				levelsof _match`i', clean
				local macroconcept="`macroconcept' `r(levels)'"
			}
			local macroconceptuniq : list uniq macroconcept
			foreach var of local macroconceptuniq {
				gen `var'=substr(substr(`Attributes2', strpos(`Attributes2', `""`var'""'), .), strpos(substr(`Attributes2', strpos(`Attributes2', `""`var'""'), .), "value=")+7, strpos(substr(substr(`Attributes2', strpos(`Attributes2', `""`var'""'), .), strpos(substr(`Attributes2', strpos(`Attributes2', `""`var'""'), .), "value=")+7, .), `"""')-1)
			}
			drop _*
		}
		drop v1
		save `dimensions', replace
	}

	// Merge data and dimensions' identifiers

	merge 1:m series using `data', nogenerate
	drop series
	rename _all, lower
	
	// Reshape dataset
	
	if "`timeseries'"!="" {
		keep serieskey time value
		reshape wide value, i(time) j(serieskey, string)
		rename value* *
		sort time
	}
		if "`panel'"!="" {
		keep serieskey time value `panel'
		reshape wide value, i(time `panel') j(serieskey, string)
		rename value* *
		sort `panel' time
	}
		
	// Erase text file with raw data

	cap erase sdmxfile.txt

	}
}

end
