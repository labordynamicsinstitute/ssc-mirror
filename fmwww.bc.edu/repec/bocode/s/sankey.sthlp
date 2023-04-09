{smcl}
{* 04Apr2023}{...}
{hi:help sankey}{...}
{right:{browse "https://github.com/asjadnaqvi/stata-sankey":sankey v1.31 (GitHub)}}

{hline}

{title:sankey}: A Stata package for Sankey diagrams.

{marker syntax}{title:Syntax}
{p 8 15 2}

{cmd:sankey} {it:value} {ifin}, {cmdab:f:rom}({it:var}) {cmdab:t:o}({it:var}) {cmd:by}({it:var}) 
                {cmd:[} 
                  {cmd:palette}({it:str}) {cmd:colorby}({it:layer}|{it:level}) {cmd:smooth}({it:1-8}) {cmd:gap}({it:num}) {cmdab:recen:ter}({it:mid}|{it:bot}|{it:top}) 
                  {cmdab:laba:ngle}({it:str}) {cmdab:labs:ize}({it:str}) {cmdab:labpos:ition}({it:str}) {cmdab:labg:ap}({it:str}) {cmdab:showtot:al}
                  {cmdab:vals:ize}({it:str}) {cmdab:valcond:ition}({it:num}) {cmd:format}({it:str}) {cmdab:valg:ap}({it:str}) {cmdab:noval:ues}
                  {cmdab:lw:idth}({it:str}) {cmdab:lc:olor}({it:str}) {cmd:alpha}({it:num}) {cmd:offset}({it:num}) {cmd:sortby}({it:value}|{it:name}) {cmdab:boxw:idth}({it:str})
                  {cmd:title}({it:str}) {cmd:subtitle}({it:str}) {cmd:note}({it:str}) {cmd:scheme}({it:str}) {cmd:name}({it:str}) {cmd:xsize}({it:num}) {cmd:ysize}({it:num}) 
                {cmd:]}


{p 4 4 2}
Please note that {opt sankey} is under active development and not all possible combinations and variations have been added.
Please report errors/bugs/enhancement requests on {browse "https://github.com/asjadnaqvi/stata-sankey/issues":GitHub}. 


{synoptset 36 tabbed}{...}
{synopthdr}
{synoptline}

{p2coldent : {opt sankey value, from() to() by()}}The command requires a numeric variable. Both {cmd:from()} and {cmd:to()} can contain numeric, labeled or string variables.
The {cmd:by()} variable contains a layer variable which ideally should be numeric. If strings are used, then 
please make sure that the spellings for categories are consistent since each unique name is assumed a separate category.{p_end}

{p2coldent : {opt palette(name)}}Color name is any named scheme defined in the {stata help colorpalette:colorpalette} package. Default is {stata colorpalette tableau:{it:tableau}}.{p_end}

{p2coldent : {opt sortby(option)}}Users can sort the data by {ul:value} or {ul:name}. The {opt sortby(value)} arranges the data using a numerical sort, while {opt sortby(name)}
arranges them alphabetically.{p_end}

{p2coldent : {opt colorby(option)}}Users can color the diagram by {ul:layer} instead of the default where each unique name is taken as a unique color category.
The {it:layer} option is determined by the {cmd:by()} variable, and it will give each 
layer a unique color.{p_end}

{p2coldent : {opt smooth(num)}}This option allows users to smooth out the spider plots connections. It can take on values between 1 to 8, where 1 is for straight lines, while 
is 8 shows steps. The middle range between 3-6 gives more curvy links. The default value is {opt smooth(4)}.{p_end}

{p2coldent : {opt gap(num)}}Gap between categories is defined as a percentage of the highest y-axis range across the layers. Default value is {opt gap(2)} for 2%.{p_end}

{p2coldent : {opt recen:ter(option)}}Users can recenter the graph {ul:middle} ({ul:mid} or {ul:m} also accepted), {ul:top} (or {ul:t}), or {ul:bottom} (or {ul:bot} or {ul:b}).
This is mostly an aesthetic choice. Default value is {opt recen(mid)}.{p_end}

{p2coldent : {opt alpha(num)}}The transparency control of the area fills. The value ranges from 0-100, where 0 is no fill and 100 is fully filled.
Default value is {opt alpha(75)} for 75% transparency.{p_end}

{p2coldent : {opt lw:idth(str)}}The outline width of the area fills. Default is {cmd:lw(none)}. This implies that they are turned off by default.{p_end}

{p2coldent : {opt lc:olor(str)}}The outline color of the area fills. Default is {cmd:lc(white)}.{p_end}

{p2coldent : {opt labs:ize(str)}}The size of the category labels. Default is {cmd:labs(2)}.{p_end}

{p2coldent : {opt laba:ngle(str)}}The angle of the category labels. Default is {cmd:laba(90)} for vertical labels.{p_end}

{p2coldent : {opt labc:olor(str)}}The color of the category labels. Default is {cmd:labc(black)}.{p_end}

{p2coldent : {opt labpos:ition(str)}}The position of the category labels. Default is {cmd:labpos(0)} for centered.{p_end}

{p2coldent : {opt labg:ap(str)}}The gap of the category labels from the mid point of the wedges. Default is {cmd:labg(0)} for no gap.
If the label angle is change to horitzontal or the label position is changed from 0, then {cmd:labg()} can be used to fine-tune the placement.{p_end}

{p2coldent : {opt showtot:al}}Display the category totals on the node boxes.{p_end}

{p2coldent : {opt boxw:idth(str)}Width of the node boxes. Default is {boxw(3.2)}.{p_end}

{p2coldent : {opt vals:ize(str)}}The size of the displayed values. Default is {cmd:vals(1.5)}.{p_end}

{p2coldent : {opt valcond:ition(num)}}This option can be specified to only display values >={it:num}, e.g. {opt valcond(100)} implies >= 100.
This option can be used to reduce the number of labels displayed especially if there are many very small categories that make the figure look messy.{p_end}

{p2coldent : {opt format(str)}}The format of the displayed values. Default is {opt format(%12.0f)}.{p_end}

{p2coldent : {opt noval:ues}}Hide the values.{p_end}

{p2coldent : {opt offset(num)}}The value, in percentage of x-axis width, to extend the x-axis on the right-hand side. Default is {cmd:offset(0)}.
This option is highly useful especially if labels are rotated with custom positions.{p_end}

{p2coldent : {opt title()}, {opt subtitle()}, {opt note()}}These are standard twoway graph options.{p_end}

{p2coldent : {opt scheme()}, {opt name()}}These are standard twoway graph options.{p_end}

{p2coldent : {opt xsize()}, {opt ysize()}}These standard twoway options can be used to space out the layers.
This is particularly helpful if several layers are plotted.{p_end}

{synoptline}
{p2colreset}{...}


{title:Dependencies}

The {browse "http://repec.sowi.unibe.ch/stata/palettes/index.html":palette} package (Jann 2018, 2022) is required for {cmd:sankey}:

{stata ssc install palettes, replace}
{stata ssc install colrspace, replace}

Even if you have these installed, it is highly recommended to update the dependencies:
{stata ado update, update}

{title:Examples}

See {browse "https://github.com/asjadnaqvi/stata-sankey":GitHub} for examples.



{hline}

{title:Version history}

- {bf:1.3}  : Node bundling added to align nodes across groups. Options {opt sortby()} and {opt boxwidth()} added.
- {bf:1.21} : Bug fixes for 1.2. {opt labcolor()} added.
- {bf:1.2}  : Unbalanced in-coming and out-going groups now properly displace. Groups ending and starting in the middle now allowed.
- {bf:1.1}  : Enhancements. {opt valformat()} renamed to {opt format()}. {opt offset} added to displace x-axis range.
- {bf:1.0}  : First version.


{title:Package details}

Version      : {bf:sankey} v1.31
This release : 04 Apr 2023
First release: 08 Dec 2022
Repository   : {browse "https://github.com/asjadnaqvi/stata-sankey":GitHub}
Keywords     : Stata, graph, sankey
License      : {browse "https://opensource.org/licenses/MIT":MIT}

Author       : {browse "https://github.com/asjadnaqvi":Asjad Naqvi}
E-mail       : asjadnaqvi@gmail.com
Twitter      : {browse "https://twitter.com/AsjadNaqvi":@AsjadNaqvi}



{title:Feedback}

Please submit bugs, errors, feature requests on {browse "https://github.com/asjadnaqvi/stata-alluvial/issues":GitHub} by opening a new issue.

{title:References}

{p 4 8 2}Jann, B. (2018). {browse "https://www.stata-journal.com/article.html?article=gr0075":Color palettes for Stata graphics}. The Stata Journal 18(4): 765-785.

{p 4 8 2}Jann, B. (2022). {browse "https://ideas.repec.org/p/bss/wpaper/43.html":Color palettes for Stata graphics: an update}. University of Bern Social Sciences Working Papers No. 43. 


{title:Other visualization packages}

{psee}
    {helpb arcplot}, {helpb alluvial}, {helpb bimap}, {helpb circlebar}, {helpb circlepack}, {helpb clipgeo}, {helpb delaunay}, {helpb joyplot}, 
	{helpb marimekko}, {helpb sankey}, {helpb schemepack}, {helpb spider}, {helpb streamplot}, {helpb sunburst}, {helpb treecluster}, {helpb treemap}