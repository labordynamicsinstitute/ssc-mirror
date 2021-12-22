{smcl}
{* *! version 2.0.2 03jun2021}{...}
{findalias asfradohelp}{...}
{title:censusapi}

{phang}
{bf:censusapi} {hline 2} Stata command to download Census data through the Census API


{marker syntax}{...}
{title:Syntax}

{p 4 17 2}
{cmd: censusapi }
{cmd:,} [url(string)] [{ul:dest}ination(string)] [dataset(string) {ul:var}iables(string) predicate(string)] [key(string) savekey]

{synoptset 20 tabbed}{...}
{synoptline}
{synopt:{opt url(string)}} most basic option, simply paste the url here you'd normally enter in the browser{p_end}
{synopt:{opt destination(string)}} where you want to save the data you retrieved, include the .txt suffix{p_end}
{synoptline}
{synopt:{opt dataset(string)}} dataset you want to access, e.g. sf1{p_end}
{synopt:{opt variables(string)}} variables you want to retrieve, things such as P0100001-P0100022 are allowed{p_end}
{synopt:{opt predicate(string)}} the predicate part which determines your datasplit, e.g. "for=place:*&in=state:12"{p_end}
{synoptline}
{synopt:{opt key(string)}} your Census API key (required for larger requests){p_end}
{synopt:{opt savekey}} saves your API key, so you don't need to enter it again{p_end}

{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:censusapi} is a simple tool to access the US Census data. It facilitates the whole "API" part, and provides some functionality to make variable selection easier. 
Note that you need to have cURL installed for this command to work. It should be installed by default in recent versions of Windows, Mac OS and Linux. 
If you are running an older version, you can download cURL at https://curl.haxx.se/download.html .

There are two ways of using this command.

{phang}
{opt url(string)} You can use {cmd:censusapi} merely as an API toolkit. In this case, you simply supply the correct URL in the {opt url(string)} option and run the program.
Example 1 (see below) illustrates this method. The command will then simply send your request to the Census website, download whatever it gets back and load this data. 
You can also use the {opt destination(string)} option to immediately save the cleaned csv file to disk.

{phang}
Alternatively, you can use the {opt dataset(string)}, {opt variables(string)} and {opt predicate(string)} options to make your life a bit easier.
This essentially cuts the url up into its constituent parts. Example 2 (see below) illustrates this method.
Now, you first specify the link to the {opt dataset} you are downloading from, then which {opt variables} you are interested in and 
finally the {opt predicate} part, which determines which geographic regions you'll be downloading information on. {break}
One nifty advantage of the {cmd:censusapi} command is that it parses variable lists for you. 
Say, you want to download all age shares. With this command, you can simply specify P0110001-P0110031 and it will immediately convert this to P0110001,P0110002,...,P0110031 for you.
It will also split your census call if you are requesting more than 50 variables (the maximum allowed by one call) and combine the data afterwards.

{phang}
You might need a census API key to complete your download (at the time of writing these could be requested for free). 
You can add this to your request through the {opt key(string)} option. If you are as lazy and forgetful as I am, then you will be happy
to hear that there is also a {opt savekey} option. This will save the key in your profile.do (google it). 
From that points onwards, {cmd:censusapi} will always use that key. Specifying a different key will overwrite this setting. Specifying {opt key(overwrite)} will run
censusapi without a key.

{marker examples}{...}
{title:Examples}

{pstd}Example 1: the url() way: count number of people below poverty level by US county{p_end}
{phang2}{cmd:. censusapi, url(https://api.census.gov/data/2019/acs/acs5?get=B17001_001E,B17001_002E&for=county:*)}{p_end}

{pstd}Example 2: the alternative method, illustrating also the variable parsing and saving capacities {p_end}
{phang2}{cmd:. censusapi, dataset(https://api.census.gov/data/2019/acs/acs5) variables(B17001_001E B17001_002E) predicate("for=county:*") destination("2019_acs_data.txt")}{p_end}

{pstd}Example 3: using the url() way to access the QWI {p_end}
{phang2}{cmd:. censusapi, url("https://api.census.gov/data/timeseries/qwi/sa?get=Emp&for=county:*&in=state:02&time=from 1990-Q1 to 2010-Q3&sex=0&agegrp=A00&ownercode=A05&seasonadj=U&industry=44-45")}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:censusapi} stores the following in {cmd:r()}:

{p2col 5 15 19 2: Locals}{p_end}
{synoptset 15 tabbed}{...}
{synopt:{cmd:r(requestUrl)}}The URL sent to the API after parsing, includes key.{p_end}
{synopt:{cmd:r(curlCommand)}}The curl command, useful for bug fixing{p_end}
{p2colreset}{...}

{marker notes}{...}
{title:Notes}

{pstd}The census requires zero prefixed state codes, here's a list:{p_end}
{phang2}{cmd:. global states "01 02 04 05 06 08 09 10 11 12 13 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 44 45 46 47 48 49 50 51 53 54 55 56"}{p_end}

{pstd}The QWI allows time ranges, here's an example query{p_end}
{phang2}{cmd:. censusapi, url("https://api.census.gov/data/timeseries/qwi/sa?get=Emp&for=county:*&in=state:02&time=from 1990-Q1 to 2010-Q3&sex=0&agegrp=A00&ownercode=A05&seasonadj=U&industry=44-45")}{p_end}


{title:Author}

{space 4}Jesse Wursten
{space 4}Faculty of Economics and Business
{space 4}KU Leuven
{space 4}{browse "mailto:jesse.wursten@kuleuven.be":jesse.wursten@kuleuven.be} 

{space 4}Other commands by the same author

{synoptset 14 tabbed}{...}
{synopt:{cmd:sendtoslack}} Stata Module to send notifications from Stata to your smartphone through Slack{p_end}
{synopt:{cmd:xtqptest}} Bias-corrected LM-based test for panel serial correlation{p_end}
{synopt:{cmd:xthrtest}} Heteroskedasticity-robust HR-test for first order panel serial correlation{p_end}
{synopt:{cmd:xtistest}} Portmanteau test for panel serial correlation{p_end}
{synopt:{cmd:xtcdf}} CD-test for cross-sectional dependence{p_end}
{synopt:{cmd:timeit}} Easy to use single line version of timer on/off, supports incremental timing{p_end}
{synopt:{cmd:stop}} Alternative to exit/error 1 that facilitates log closure and links up with sendtoslack{p_end}
{synopt:{cmd:pwcorrf}} Faster version of pwcorr, with builtin reshape option{p_end}
{p2colreset}{...}

{space 4}Thanks to Evan Galloway for providing the ACS example.