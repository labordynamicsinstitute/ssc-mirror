{smcl}
{* 14Dec2025}{...}
{hline}
help for {hi:area} {right:(Wu Lianghai, Wu Xinzhuo, Wu Hanyan)}
{hline}

{title:Title}

{p 4 4}{cmd:area} {hline 2} Generate regional dummy variables with province name standardization{p_end}

{title:Syntax}

{p 8 12}{cmd:area} {it:varname}{p_end}

{title:Description}

{p 4 4}{cmd:area} generates regional dummy variables (Eastern, Central, Western China) based on a province variable in your dataset. The program:{p_end}

{p 8 12}1. Automatically detects and converts non-string province variables{p_end}
{p 8 12}2. Standardizes province names by removing administrative suffixes{p_end}
{p 8 12}3. Creates an ordinal variable with proper value labels{p_end}
{p 8 12}4. Provides descriptive statistics of the regional distribution{p_end}
{p 8 12}5. Automatically saves the updated dataset{p_end}

{title:Regional classification}

{p 4 4}{bf:Eastern Region (东部地区):}{p_end}
{p 8 12}Beijing (北京), Tianjin (天津), Hebei (河北), Liaoning (辽宁), Jilin (吉林), Heilongjiang (黑龙江), Shanghai (上海), Jiangsu (江苏), Zhejiang (浙江), Fujian (福建), Shandong (山东), Guangdong (广东), Hainan (海南), and all other provinces not listed in Central or Western regions.{p_end}

{p 4 4}{bf:Central Region (中部地区):}{p_end}
{p 8 12}Anhui (安徽), Hubei (湖北), Hunan (湖南), Henan (河南), Jiangxi (江西), Shanxi (山西){p_end}

{p 4 4}{bf:Western Region (西部地区):}{p_end}
{p 8 12}Sichuan (四川), Shaanxi (陕西), Chongqing (重庆), Xinjiang (新疆), Yunnan (云南), Guangxi (广西), Guizhou (贵州), Gansu (甘肃), Inner Mongolia (内蒙古), Tibet (西藏), Ningxia (宁夏), Qinghai (青海){p_end}

{title:Options}

{p 4 4}None. The program accepts one variable name as input.{p_end}

{title:Examples}

{p 8 12}{stata "use asure, clear":. use asure, clear}{p_end}
{p 8 12}{stata "area 省份":. area 省份}{p_end}
{p 8 12}{stata "area province":. area province}{p_end}
{p 8 12}{stata "area 省自治区直辖市":. area 省自治区直辖市}{p_end}

{title:Output}

{p 4 4}After running the command, the dataset will contain:{p_end}

{p 8 12}{ul:{bf:region}} - A string variable with values: 东部地区 (Eastern Region), 中部地区 (Central Region), 西部地区 (Western Region){p_end}
{p 8 12}{ul:{bf:area}} - An ordinal variable with value labels:{p_end}
{p 12 16}1 = 东部地区 (Eastern Region){p_end}
{p 12 16}2 = 中部地区 (Central Region){p_end}
{p 12 16}3 = 西部地区 (Western Region){p_end}

{p 4 4}The program displays the following on screen:{p_end}
{p 8 12}- A tabulation of the regional distribution{p_end}
{p 8 12}- Summary statistics of the generated area variable{p_end}
{p 8 12}- A confirmation that the dataset has been saved{p_end}

{title:Stored results}

{p 4 4}{cmd:area} stores the following scalars in {cmd:r()}:{p_end}

{p 8 12}{cmd:r(N)}         - number of observations{p_end}
{p 8 12}{cmd:r(mean)}      - mean of area (1-3){p_end}
{p 8 12}{cmd:r(sd)}        - standard deviation of area{p_end}
{p 8 12}{cmd:r(min)}       - minimum value of area{p_end}
{p 8 12}{cmd:r(max)}       - maximum value of area{p_end}
{p 8 12}{cmd:r(east_N)}    - number of observations in Eastern region{p_end}
{p 8 12}{cmd:r(east_prop)} - proportion of observations in Eastern region{p_end}
{p 8 12}{cmd:r(central_N)} - number of observations in Central region{p_end}
{p 8 12}{cmd:r(central_prop)} - proportion of observations in Central region{p_end}
{p 8 12}{cmd:r(west_N)}    - number of observations in Western region{p_end}
{p 8 12}{cmd:r(west_prop)} - proportion of observations in Western region{p_end}

{title:Remarks}

{p 4 4}The program automatically standardizes province names by removing administrative suffixes such as 省, 市, 自治区, etc. It also handles special cases like Inner Mongolia, Tibet, Ningxia, Xinjiang, and the special administrative regions.{p_end}

{p 4 4}If the variables {cmd:area} or {cmd:region} already exist in the dataset, the program will display an error message and exit. You must drop or rename these variables before running the command.{p_end}

{p 4 4}The program automatically saves the dataset after adding the regional variables. Make sure your dataset is saved before running the command, or the program will display a warning.{p_end}

{title:Authors}

{p 4 4}Wu Lianghai{p_end}
{p 8 12}School of Business, Anhui University of Technology (AHUT){p_end}
{p 8 12}Ma'anshan, China{p_end}
{p 8 12}Email: {browse "mailto:agd2010@yeah.net":agd2010@yeah.net}{p_end}

{p 4 4}Wu Xinzhuo{p_end}
{p 8 12}University of Bristol (UB){p_end}
{p 8 12}Email: {browse "mailto:2957833979@qq.com":2957833979@qq.com}{p_end}

{p 4 4}Wu Hanyan{p_end}
{p 8 12}School of Economics and Management, Nanjing University of Aeronautics and Astronautics (NUAA){p_end}
{p 8 12}Nanjing, China{p_end}
{p 8 12}Email: {browse "mailto:2325476320@qq.com":2325476320@qq.com}{p_end}

{title:Version}

{p 4 4}Version 2.0.3 - 14 December 2025{p_end}

{title:Also see}

{p 4 4}Manual: {help encode}, {help tabulate}, {help summarize}{p_end}
{*}