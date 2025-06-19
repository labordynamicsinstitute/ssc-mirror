{smcl}

{hline}
{cmd:help baiduweather2}
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

{viewerjumpto "Title" "baiduweather2##title"}{...}
{viewerjumpto "Syntax" "baiduweather2##syntax"}{...}
{viewerjumpto "Description" "baiduweather2##description"}{...}
{viewerjumpto "Examples" "baiduweather2##examples"}{...}
{viewerjumpto "Alsosee" "baiduweather2##alsosee"}{...}

{title:Title}

    baiduweather2 - Query Baidu Weather Data by Administrative Division Code

{marker syntax}{...}
{title:Syntax}

    baiduweather2, ak(string) district_id(varname) ///
        [saving(string) replace clear ]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required Parameters}
{synopt :{opt ak}(string)}Baidu Map API key (required){p_end}
{synopt :{opt district_id}(varname)}Variable containing administrative division codes (required){p_end}

{syntab:Optional Parameters}
{synopt :{opt saving}(string)}Path to save resulting dataset{p_end}
{synopt :{opt replace}}Overwrite existing save file{p_end}
{synopt :{opt clear}}Keep weather data in current dataset{p_end}
{synoptline}

{marker description}{...}
{title:Description}

    {cmd:baiduweather2} queries weather data in bulk using Baidu Map Weather API with administrative division codes. This command:
    - Uses administrative division codes instead of coordinates
    - Ideal for scenarios with existing division codes but lacking coordinates
    - Automatically processes each observation in the dataset
    - Provides comprehensive real-time weather information

    - The Baidu Map Weather API with administrative division codes can be downloaded and viewed through {stata "cnuse weather_district_id.dta,clear":cnuse weather_district_id.dta,clear }!

		
{title:Options}

{phang}
{opt ak}(string) specifies Baidu Map developer key, available at {browse "https://lbsyun.baidu.com/":Baidu Map Open Platform}.

{phang}
{opt district_id}(varname) specifies variable containing administrative division codes (e.g., 110000 for Beijing, 310000 for Shanghai).

{phang}
{opt saving}(string) saves new dataset with weather results to specified path. Use with {opt replace}.

{phang}
{opt clear} preserves weather data in current workspace after execution (default restores original data).

{title:Generated Variables}

    The command creates these meteorological variables (all prefixed with {bf:weather_}):

{col 5}Variable{col 25}Description{col 65}Type
{col 5}{hline 70}
{col 5}weather_status{col 25}API request status{col 65}String
{col 5}weather_location{col 25}Location(province/city/district){col 65}String
{col 5}weather_text{col 25}Weather description (e.g., "Sunny"){col 65}String
{col 5}weather_temp{col 25}Current temperature (°C){col 65}Numeric
{col 5}weather_feels_like{col 25}Feels-like temperature (°C){col 65}Numeric
{col 5}weather_humidity{col 25}Humidity (%){col 65}Numeric
{col 5}weather_wind{col 25}Wind direction and force description{col 65}String
{col 5}weather_timestamp{col 25}Data query timestamp{col 65}Date-time
{col 5}weather_response{col 25}Raw API response (JSON){col 65}Long string
{col 5}{hline 70}

{marker examples}{...}
{title:Examples}

0. View help documentation
{phang2}{stata "help baiduweather2":. help baiduweather2}{p_end}

{bf:Example 1: Basic query}
{phang}1. Create test dataset with administrative codes:{p_end}
{phang2}{stata "clear":. clear}{p_end}
{phang2}{stata "input district":. input district}{p_end}
{phang2}{stata "110100":. 110100  // Beijing}{p_end}
{phang2}{stata "310100":. 310100  // Shanghai}{p_end}
{phang2}{stata "440300":. 440300  // Shenzhen}{p_end}
{phang2}{stata "end":. end}{p_end}

{phang}Click {it:({stata runby_run baiduweather_example2 using baiduweather2.sthlp:here to run})}:{p_end}

{space 4}{hline 27} {it:example do-file content} {hline 27}
{cmd}{...}
{* example_start - baiduweather_example2}{...}
      clear
      input district
      110100 // Beijing
      310100 // Shanghai
      440300 // Shenzhen
      end
{* example_end}{...}
{txt}{...}
{space 4}{hline 80}
{space 8}{it:({stata runby_run baiduweather_example2 using baiduweather2.sthlp:click to run})}

{phang}2. Execute weather query:{p_end}
{phang2}{stata `"global key1 "Your_Baidu_API_Key"':. global key1 "Your_Baidu_API_Key"}{p_end}

{phang2}{stata `"baiduweather2, ak($key1) district_id(district) saving("baiduweather2.dta")"':. baiduweather2, ak($key1) district_id(district) saving("baiduweather2.dta")}{p_end}

{phang}3. View results:{p_end}
{phang2}{stata `"use baiduweather2.dta, clear"':. use baiduweather2.dta, clear}{p_end}
{phang2}{stata "describe":. describe}{p_end}
{phang2}{stata "list district weather_location weather_text weather_temp, noobs":. list district weather_location weather_text weather_temp, noobs}{p_end}


{bf:Example 2: Baidu Map - Query weather by administrative codes}

{phang}* Prepare sample dataset{p_end}

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


{phang}* Save results to file{p_end}
{phang2}{stata `"baiduweather2, ak($key1) district_id(district_id) saving("baiduweather2-2.dta") replace"':. baiduweather2, ak($key1) district_id(district_id) saving("baiduweather2-2.dta") replace}{p_end}

{phang}* View weather results{p_end}
{phang2}{stata `"use baiduweather2-2.dta, clear"':. use baiduweather2-2.dta, clear}{p_end}

{phang2}{stata `"list district weather_location weather_text weather_temp weather_feels_like, sep(0)"':. list district weather_location weather_text weather_temp weather_feels_like, sep(0)}{p_end}



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


