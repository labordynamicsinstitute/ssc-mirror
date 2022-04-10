{smcl}
{* 08April2022}{...}
{hi:help streamplot}{...}
{right:{browse "https://github.com/asjadnaqvi/stata-streamplot":streamplot v1.1 (GitHub)}}

{hline}

{title:streamplot}: A Stata package for streamplots. 

{p 4 4 2}
The command is based on the following guide on Medium: {browse "https://medium.com/the-stata-guide/covid-19-visualizations-with-stata-part-10-stream-graphs-9d55db12318a":Stream plots}.


{marker syntax}{title:Syntax}
{p 8 15 2}

{cmd:streamplot} {it:y x} {ifin}, {cmd:by}(varname) {cmd:[} {cmd:color}(string) {cmd:smooth}(num) {cmd:labcond}(string) {cmdab:lc:olor}(string) {cmdab:lw:idth}(string) 
			{cmdab:xlabs:ize}({it:num}) {cmdab:ylabs:ize}({it:num}) {cmd:xticks}(string) {cmd:xtitle}(string) {cmd:ytitle}(string) {cmd:title}(string) {cmd:subtitle}(string) {cmd:note}(string) {cmd:]}


{p 4 4 2}
The options are described as follows:

{synoptset 36 tabbed}{...}
{synopthdr}
{synoptline}

{p2coldent : {opt streamplot y x}}The command requires a numeric {it:y} variable and a numeric {it:x} variable. Usually the x variable is the date.{p_end}

{p2coldent : {opt by(group variable)}}This is the group variable that defines the layers.{p_end}

{p2coldent : {opt smooth(value)}}The data is smoothed based on a number of past observations. The default value 6. A value of 0 implies no smoothing.{p_end}

{p2coldent : {opt labcond(string)}}Here the label condition can be defined. For example if we want to label only values which are greater than a certain threhold, then we can write {it:labcond(>= 10000)}. Currently only one condition is supported and the main aim is to clean up the labels especially if they are bunched on top of each other. See example below.{p_end}

{p2coldent : {opt color(string)}}Color name is any named scheme defined in the {stata help colorpalette:colorpalette} package. Default is {stata colorpalette CET C6:{it:CET C6}}.{p_end}

{p2coldent : {opt xticks(string)}}This option can be used to customize the x-axis ticks. See example below.{p_end}

{p2coldent : {opt lwidth(value)}}The line width of the area stroke. The default is {it:0.02}.{p_end}

{p2coldent : {opt lcolor(string)}}The line color of the area stroke. The default is {it:white}.{p_end}

{p2coldent : {opt xlabsize(value)}, {opt ylabsize(value)}}The size of the x and y-axis labels. Defaults are {it:2} and {it:1.4} respectively.{p_end}

{p2coldent : {opt xlabc(string)}, {opt ylabc(string)}}This option can be used to customize the x and y-axis label colors especially if non-standard graph schemes are used. Default is {it:black}.{p_end}

{p2coldent : {opt xtitle, ytitle, title, subtitle, note}}These are standard twoway graph options if additional labels are required. The default is no labels.{p_end}

{synoptline}
{p2colreset}{...}


{title:Dependencies}

The package requires the {stata "http://repec.sowi.unibe.ch/stata/palettes/index.html":palette} package (Jann 2018):

{stata ssc install colorpalette, replace}
{stata ssc install colrspace, replace}


{title:Examples}


Load the data and clean it up:
use "https://github.com/asjadnaqvi/The-Stata-Guide/blob/master/data/OWID_data.dta?raw=true", clear

keep region date new_cases country

gen region = .
	replace region = 1 if group29==1 & country=="United States" // North America
	replace region = 2 if group29==1 & country!="United States" // North America
	replace region = 3 if group20==1 & country=="Brazil" // Latin America and Carribean
	replace region = 4 if group20==1 & country!="Brazil" // Latin America and Carribean
	replace region = 5 if group10==1 & country=="Germany" // Germany
	replace region = 6 if group10==1 & country!="Germany" // Rest of EU
	replace region = 7 if  group8==1 & group10!=1 & country=="United Kingdom" // Rest of Europe and Central Asia
	replace region = 8 if  group8==1 & group10!=1 & country!="United Kingdom" // Rest of Europe and Central Asia
	replace region = 9 if group26==1 // MENA
	replace region = 10 if group37==1 // Sub-saharan Africa
	replace region = 11 if group35==1 & country=="India" // South Asia
	replace region = 12 if group35==1 & country!="India" // South Asia
	replace region = 13 if  group6==1 // East Asia and Pacific


lab de region  1 "United States" 2 "Rest of North America" 3 "Brazil" 4 "Rest of Latin America" 5 "Germany" ///
		6 "Rest of European Union" 7 "United Kingdom" 8 "Rest of Europe" 9 "MENA" 10 "Sub-Saharan Africa" ///
		11 "India" 12 "Rest of South Asia" 13 "East Asia and Pacific"

lab val region region

- Basic example:

streamplot new_cases date, by(region)


- With additional options:

streamplot new_cases date if date > 22600, by(region) smooth(5) ///
	title("My stream plot") note("Note here") ///
	labcond(> 100000) ylabsize(1.8) lc(black) lw(0.08)


qui summ date if date > 22600
	local xmin = r(min)
	local xmax = r(max) + 40

streamplot new_cases date if date > 22600, by(region) smooth(3) ///
	title("My stream plot") subtitle("Subtitle here") note("Note here") ///
	labcond(> 100000) ylabsize(1.5) xlabc(blue) lc(white) lw(0.08) ///
	xticks(`xmin'(20)`xmax')


{hline}

{title:Package details}

Version      : {bf:streamplot} v1.1
This release : 08 Apr 2022
First release: 06 Aug 2021
Repository   : {browse "https://github.com/asjadnaqvi/streamplot":GitHub}
Keywords     : Stata, graph, stream plot
License      : {browse "https://opensource.org/licenses/MIT":MIT}

Author       : {browse "https://github.com/asjadnaqvi":Asjad Naqvi}
E-mail       : asjadnaqvi@gmail.com
Twitter      : {browse "https://twitter.com/AsjadNaqvi":@AsjadNaqvi}



{title:References}

{p 4 8 2}Jann, B. (2018). {browse "https://www.stata-journal.com/article.html?article=gr0075":Color palettes for Stata graphics}. The Stata Journal 18(4): 765-785.


