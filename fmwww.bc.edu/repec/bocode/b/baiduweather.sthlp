{smcl}

{hline}
{cmd:help baiduweather}
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

{viewerjumpto "Title" "baiduweather##title"}{...}
{viewerjumpto "Syntax" "baiduweather##syntax"}{...}
{viewerjumpto "Description" "baiduweather##description"}{...}
{viewerjumpto "Examples" "baiduweather##examples"}{...}
{viewerjumpto "Alsosee" "baiduweather##alsosee"}{...}


{title:Title}

    baiduweather - Batch query weather data using Baidu Maps API with longitude and latitude coordinates

{marker syntax}{...}
{title:Syntax}


    baiduweather, ak(string) longitude(varname) latitude(varname) ///
        [saving(string) replace clear ]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt :{opt ak}(string)}Baidu Maps API key (required){p_end}
{synopt :{opt longitude}(varname)}Numeric variable containing longitude values (required){p_end}
{synopt :{opt latitude}(varname)}Numeric variable containing latitude values (required){p_end}

{syntab:Optional}
{synopt :{opt saving}(string)}Path to save the resulting dataset{p_end}
{synopt :{opt replace}}Overwrite existing save file{p_end}
{synopt :{opt clear}}Keep weather data in the current dataset{p_end}
{synoptline}


{marker description}{...}
{title:Description}

    {cmd:baiduweather} queries weather data in bulk using the Baidu Maps Weather API. This command:
    - Automatically processes each longitude/latitude record in the dataset
    - Supports real-time weather 
    - Automatically creates a structured dataset with comprehensive meteorological information
 
{title:Options}

{phang}
{opt ak}(string) specifies the Baidu Maps developer API key. Apply on {browse "https://lbsyun.baidu.com/":Baidu Maps Open Platform}.

{phang}
{opt longitude}(varname) specifies the numeric variable containing longitude values (e.g., 116.4074 for Beijing).

{phang}
{opt latitude}(varname) specifies the numeric variable containing latitude values (e.g., 39.9042 for Beijing).

{phang}
{opt saving}(string) saves the new dataset with weather results to the specified path. Use with {opt replace}.

{phang}
{opt clear} keeps weather data in the current workspace after execution (default restores original data).


{title:Generated Variables}

    The command creates the following weather variables (prefixed with {bf:weather_}):

{col 5}Variable{col 25}Description{col 60}Type
{col 5}{hline 65}
{col 5}weather_status{col 25}API request status{col 60}String
{col 5}weather_location{col 25}Location (Province/City/District){col 60}String
{col 5}weather_text{col 25}Weather description{col 60}String
{col 5}weather_temp{col 25}Temperature (°C){col 60}Numeric
{col 5}weather_feels_like{col 25}Feels-like temperature (°C){col 60}Numeric
{col 5}weather_humidity{col 25}Humidity (%){col 60}Numeric
{col 5}weather_wind{col 25}Wind direction and force{col 60}String
{col 5}weather_timestamp{col 25}Data query timestamp{col 60}Datetime
{col 5}weather_response{col 25}Raw API response (JSON){col 60}Long string
{col 5}{hline 65}

{marker examples}{...}
{title:Examples}

0. View help documentation
{phang}{stata "help baiduweather":. help baiduweather}{p_end}

{phang}1. Create test data:{p_end}
{phang2}{stata "clear":. clear}{p_end}
{phang2}{stata "input longitude latitude":. input longitude latitude}{p_end}
{phang2}{stata "116.4074 39.9042":. 116.4074 39.9042  // Beijing}{p_end}
{phang2}{stata "121.4737 31.2304":. 121.4737 31.2304  // Shanghai}{p_end}
{phang2}{stata "114.0579 22.5431":. 114.0579 22.5431  // Shenzhen}{p_end}
{phang2}{stata "end":. end}{p_end}

{phang}Run via {it:({stata runby_run baiduweather_example using baiduweather.sthlp:click to run})}:{p_end}

{space 4}{hline 27} {it:example do-file content} {hline 27}
{cmd}{...}
{* example_start - baiduweather_example}{...}
      clear
      input longitude latitude
      116.4074 39.9042 // Beijing
      121.4737 31.2304 // Shanghai
      114.0579 22.5431 // Shenzhen
      end
{* example_end}{...}
{txt}{...}
{space 4}{hline 80}
{space 8}{it:({stata runby_run baiduweather_example using baiduweather.sthlp:click to run})}


{phang}2. Execute query and save results:{p_end}
{phang2}{stata `"global key1 "YOUR_BAIDU_API_KEY"':. global key1 "YOUR_BAIDU_API_KEY"}{p_end}
{phang2}{stata `"baiduweather, ak($key1) longitude(longitude) latitude(latitude) saving("baiduweather.dta")"':. baiduweather, ak($key1) longitude(longitude) latitude(latitude) saving("baiduweather.dta")}{p_end}

{phang}3. View results:{p_end}
{phang2}{stata `"use baiduweather.dta, clear"':. use baiduweather.dta, clear}{p_end}
{phang2}{stata "describe":. describe}{p_end}
{phang2}{stata "list longitude latitude weather_location weather_text weather_temp in 1/3, noobs":. list longitude latitude weather_location weather_text weather_temp in 1/3, noobs}{p_end}

{bf:Example 2: Query with saving/replace}

{phang}{stata "cnuse 百度地图西安数据.dta,clear":cnuse 百度地图西安数据.dta,clear }

{space 4}{hline 27} {it:example do-file content} {hline 27}
{cmd}{...}
{* example_start - baiduweather_example-2}{...}
      clear
      input long district_id str9(province city) long city_geocode str9 district long district_geocode float(lon lat)
      610100 "陕西省" "西安市" 610100 "西安"    610100  108.948 34.26316
      610102 "陕西省" "西安市" 610100 "新城区" 610102 108.9599 34.26927
      610103 "陕西省" "西安市" 610100 "碑林"    610103  108.947 34.25106
      610104 "陕西省" "西安市" 610100 "莲湖"    610104 108.9332  34.2656
      610111 "陕西省" "西安市" 610100 "灞桥"    610111 109.0673 34.26745
      610112 "陕西省" "西安市" 610100 "未央"    610112  108.946 34.30823
      610113 "陕西省" "西安市" 610100 "雁塔"    610113 108.9266 34.21339
      610114 "陕西省" "西安市" 610100 "阎良"    610114  109.228 34.66214
      610115 "陕西省" "西安市" 610100 "临潼"    610115  109.214 34.37207
      610116 "陕西省" "西安市" 610100 "长安"    610116 108.9416  34.1571
      end  
{* example_end}{...}
{txt}{...}
{space 4}{hline 80}
{space 8}{it:({stata runby_run baiduweather_example-2 using baiduweather.sthlp:click to run})}


{phang}* Define API keys{p_end}
{phang2}{stata `"global key1 "YOUR_API_KEY" "':. global key1 "YOUR_API_KEY"}{p_end}

{phang}* Save to file with replace{p_end}
{phang2}{stata `"baiduweather, ak($key1) longitude(lon) latitude(lat) saving("baiduweather_data.dta") replace"':. baiduweather, ak($key1) longitude(lon) latitude(lat) saving("baiduweather_data.dta") replace}{p_end}

{phang}* View results:{p_end}
{phang2}{stata `"use baiduweather_data.dta, clear"':. use baiduweather_data.dta, clear}{p_end}
{phang2}{stata "describe":. describe}{p_end}
{phang2}{stata "list lon lat weather_location weather_text weather_temp in 1/10, noobs":. list lon lat weather_location weather_text weather_temp in 1/10, noobs}{p_end}


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


