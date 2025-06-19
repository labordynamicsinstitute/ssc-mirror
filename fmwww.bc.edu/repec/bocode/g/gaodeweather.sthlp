{smcl}
{hline}
{cmd:help gaodeweather}
{hline}
{p 4 4 2}
{vieweralsosee "cnuse" "help cnuse"}{p_end}
{p 4 4 2}
{vieweralsosee "topsis" "help topsis"}{p_end}
{p 4 4 2}
{vieweralsosee "log2md" "help log2md"}{p_end}
{p 4 4 2}
{vieweralsosee "sj1" "help sj1"}{p_end}
{p 4 4 2}
{vieweralsosee "cie" "help cie"}{p_end}
{p 4 4 2}
{vieweralsosee "jqte" "help jqte"}{p_end}
{p 4 4 2}
{vieweralsosee "" "--"}{p_end}

{viewerjumpto "Title" "gaodeweather##title"}{...}
{viewerjumpto "Syntax" "gaodeweather##syntax"}{...}
{viewerjumpto "Description" "gaodeweather##description"}{...}
{viewerjumpto "Examples" "gaodeweather##examples"}{...}
{viewerjumpto "Alsosee" "gaodeweather##alsosee"}{...}

{title:Title}

    gaodeweather - Batch query weather data using Amap API

{marker syntax}{...}
{title:Syntax}

    gaodeweather, key(string) city(varname) [extensions(string) saving(string) replace ]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required Parameters}
{synopt :{opt key}(string)}Amap API key (required){p_end}
{synopt :{opt city}(varname)}Numeric variable containing city codes (required){p_end}

{syntab:Optional Parameters}
{synopt :{opt extensions}(string)}Query type: {opt base} (current weather),default is base. Currently, only real-time weather query is supported{p_end}
{synopt :{opt saving}(string)}Path to save resulting dataset{p_end}
{synopt :{opt replace}}Overwrite existing save file{p_end}
{synoptline}


{marker description}{...}
{title:Description}

    {cmd:gaodeweather}  queries weather data in bulk through Amap Weather API (v3). This command:
    - Automatically processes each observation in the dataset
    - Supports current weather ({opt base}) and weather forecast ({opt all}) modes
    - Automatically creates a structured dataset with 11 meteorological variables
		
    {cmd:gaodeweather}  requires an Amap API secret key to perform weather queries. To properly call the web service API:
    - 1. Register as a developer on the {browse "https://lbs.amap.com/":Amap Open Platform}
    - 2. Obtain your API key by following the steps in the {browse "https://lbs.amap.com/api/webservice/create-project-and-key":guide}
	
    According to the introduction, weather query only supports city code query, that is, entering the adcode of the city. 	
    - Regarding the city code table, it is mainly used to query the corresponding codes of different cities.	
    - It can be downloaded and viewed through {stata "cnuse AMap_adcode_citycode.dta,clear":cnuse AMap_adcode_citycode.dta,clear }!
	
    In addition, for weather queries through the Baidu Map API, you can learn through {stata "help baiduweather":baiduweather} and {stata "help baiduweather2":baiduweather2}
	

{title:Options}

{phang}
{opt key}(string) specifies the Amap developer key, which should be applied for at {browse "https://lbs.amap.com/api/webservice/create-project-and-key":Amap Developer Platform}.

{phang}
{opt city}(varname) specifies the numeric variable containing administrative division codes (e.g., 110000 for Beijing). These codes can be obtained through Amap administrative queries.
It can be downloaded and viewed through ({stata "cnuse AMap_adcode_citycode.dta,clear":cnuse AMap_adcode_citycode.dta,clear })

{phang}
{opt extensions}(string) controls query type:
   {bf:base} - Returns current weather data (default)，Currently, only real-time weather query is supported

{phang}
{opt saving}(string) saves the new dataset with weather results to specified path. Use with {opt replace}.


{title:Generated Variables}

    The command creates these meteorological variables (all prefixed with {bf:gd_}):

{col 5}Variable{col 25}Description{col 50}Type
{col 5}{hline 65}
{col 5}gd_status{col 25}API request status{col 50}String
{col 5}gd_province{col 25}Province name{col 50}String
{col 5}gd_city{col 25}City name{col 50}String
{col 5}gd_adcode{col 25}Area code{col 50}String
{col 5}gd_weather{col 25}Weather condition{col 50}String
{col 5}gd_temperature{col 25}Current temperature (°C){col 50}Numeric
{col 5}gd_winddirection{col 25}Wind direction{col 50}String
{col 5}gd_windpower{col 25}Wind force level{col 50}String
{col 5}gd_humidity{col 25}Humidity (%){col 50}Numeric
{col 5}gd_reporttime{col 25}Data report time{col 50}String
{col 5}gd_response{col 25}Raw API response (JSON){col 50}Long string
{col 5}{hline 65}

{marker examples}{...}
{title:Examples}

{pstd}0. View help documentation{p_end}
{phang}{stata "help gaodeweather":. help gaodeweather}{p_end}

{phang}1. Create test dataset with city codes:{p_end}
{phang}{stata "clear":. clear}{p_end}
{phang}{stata "input adcode":. input adcode}{p_end}
{phang}{stata "110000":. 110000  // Beijing}{p_end}
{phang}{stata "310000":. 310000  // Shanghai}{p_end}
{phang}{stata "440300":. 440300  // Shenzhen}{p_end}
{phang}{stata "end":. end}{p_end}


{space 4}{hline 27} {it:example do-file content} {hline 27}
{cmd}{...}
{* example_start - gaodeweather_example}{...}
      clear
      input adcode
      110000 // Beijing
      310000 // Shanghai
      440300 // Shenzhen
      end

{* example_end}{...}
{txt}{...}
{space 4}{hline 80}
{space 8}{it:({stata runby_run gaodeweather_example using gaodeweather.sthlp:click to run})}
    If you want to click {it:({stata runby_run gaodeweather_example using gaodeweather.sthlp:click to run})} to execute all the above code at once, please make sure that you have installed the command {stata help runby: runby}


{phang}2. Execute weather query and save results:{p_end}
{phang}{stata `"global key "Your_Amap_API_Key"':. global key "Your_Amap_API_Key"}{p_end}
{phang}{stata `"gaodeweather, key($key) city(adcode) extensions(base) saving(weather_data.dta)"':. gaodeweather, key($key) city(adcode) extensions(base) saving("weather_data.dta")}{p_end}

{phang}3. View results:{p_end}
{phang}{stata `"use weather_data.dta, clear"':. use weather_data.dta, clear}{p_end}
{phang}{stata "describe":. describe}{p_end}
{phang}{stata "list adcode gd_province-gd_reporttime in 1/3, noobs":. list adcode gd_province-gd_reporttime in 1/3, noobs}{p_end}



{title:Author & Questions and Suggestions}

{p 4 4 2}
{cmd:Wang Qiang}, Xi'an Jiaotong University, China{p_end}

{p 4 4 2}
    If you encounter any issues or have suggestions while using the tool, we will address them promptly. 
	
    Email: {browse "mailto:740130359@qq.com":740130359@qq.com}	

{marker alsosee}{...}
{title:Also see}
{p 4 4 2}

{psee}{help cnuse} (if installed),  {help topsis} (if installed),  {help log2md} (if installed),  {help sj1} (if installed),  {help jqte} (if installed),  {help cie} (if installed){p_end}

{hline}


