{smcl}
{* 17 July 2017}{...}
{hline}
help for {hi:multidot}
{hline}

{title:Multiple panel dot charts}

{p 8 17 2}
{cmd:multidot} 
{it:yvars} 
[{cmd:if} {it:exp}] 
[{cmd:in} {it:range}] 
{cmd:,}
{opt over(varname)} 
[
{opt sort(varlist)} 
{opt desc:ending} 
{opt miss:ing} 
{opt by(by_options)}
{opt recast(twoway_command)}
{cmd:savedata(}{it:filename} [{cmd:, replace}]{cmd:)}
{it:twoway_options} 
]  


{title:Description}

{p 4 4 2}
{cmd:multidot} plots two or more {it:yvars} for different levels of a
(numeric or string) identifier variable specified by the required
{cmd:over()} option.  Each {it:yvar} is by default plotted in a dot
chart in a separate panel using {help twoway scatter}. A common
application is to plot variables measured in different units and/or on
very different scales. 

{p 4 4 2}
{cmd:multidot} works with a temporarily restructured dataset in which
different {it:yvars} are {help stack}ed into one. The graph then is
based on use of {cmd:twoway, by()}. The original variable labels (or, if
labels are not defined, variable names) become the value labels of the
stacking variable. 

{p 4 4 2}
By default 

{p 8 8 2} 
The vertical axis shows rank, with low ranks at the bottom
and high ranks at the top. The order can be reversed using the
{cmd:descending} option. 

{p 8 8 2}
Rank is defined by the sort order
of {it:yvars}, so that ordering of values from top to bottom of the
display is in the first instance determined by the first variable
mentioned, with any ties broken in the usual way according to the values
of other variables.  The option {cmd:sort()} may be used to specify
another sort order.  

{p 4 4 2} 
The {cmd:recast()} option opens the door to using the same design for
other kinds of plots, for example bar charts. In each such case, the
command is based on some other {help twoway} plot.

{p 4 4 2}
Default options include 
{cmd:by(_stack, note("") xrescale subtitle(, fcolor(green*0.2) xtitle("") yla(, grid glw(vthin) glc(gs12) valuelabel ang(h) tl(0)))} for all cases; 
{cmd:ms(Oh) mc(dkgreen)} for default dot charts; 
and {cmd:horizontal barw(0.7) blcolor(dkgreen) bfcolor(none) base(0)} for bar
charts. 

{p 4 4 2}
It perhaps deserves emphasis that although plots produced by
{cmd:multidot} have much of the look and feel of those produced by 
{help graph dot} or {help graph hbar} they are produced entirely by 
{help twoway}. Talking of {it:yvars} is a nod to this hybrid flavour: 
as with {cmd:graph dot} and its siblings, the variables concerned are 
in essence regarded as outcomes or responses, even when they are plotted
horizontally. 


{title:Options}

{p 4 8 2}{cmd:over()} specifies an identifier variable defining distinct
or unique observations to be shown on the vertical axis. This is a
required option. 

{p 4 8 2}{cmd:sort()} specifies one or more variables defining the sort
order of observations in the graph. This option may be used to override
the default ordering, as when a user is perverse enough to prefer
alphabetical order by name or desires an idiosyncratic order defined by
a previously constructed variable.  

{p 4 8 2}{cmd:descending} reverses sort order on the vertical axis from
the default. 

{p 4 8 2}{cmd:missing} specifies that observations with some missing values on 
{it:yvars} be included in the sample. The default is to ignore 
observations with any missing values. 

{p 4 8 2}
{cmd:by()} specifies options of the {help by_option:by()} option.  Note
that {cmd:_stack} produced temporarily by the program is already wired
in as {it:varlist} for a {cmd:by()} option. 

{p 4 8 2} 
{cmd:recast()} specifies that the graph be recast to another
{cmd:twoway} type. See help on {help advanced_options:advanced options}. 

{p 4 8 2}{cmd:savedata()} specifies that data used to produce the graph be
saved as a separate dataset. The axis variables will be named {cmd:_y}
and {cmd:_rank}. 

{p 4 8 2}{it:twoway_options} are options of {help twoway}. 


{title:Examples}

{p 4 8 2}{cmd:. sysuse auto, clear}{p_end}
{p 4 8 2}{cmd:. multidot price mpg if foreign, over(make)}{p_end}
{p 4 8 2}{cmd:. multidot price mpg if foreign, over(make) recast(bar)}{p_end}
{p 4 8 2}{cmd:. multidot price mpg if foreign, over(make) recast(bar) desc}{p_end}
{p 4 8 2}{cmd:. multidot price mpg weight if foreign, over(make) recast(bar) desc by(row(1)) xla(, ang(v))}{p_end}
{p 4 8 2}{cmd:. multidot price mpg weight if foreign, over(make) recast(bar) desc by(row(1)) xla(, ang(v)) blcolor(blue)}{p_end}
{p 4 8 2}{cmd:. multidot price mpg weight if foreign, over(make) desc by(row(1)) xla(, ang(v)) recast(dropline) lw(thick) lc(orange_red) mc(orange_red) }{p_end}
{p 4 8 2}{cmd:. multidot price mpg weight if foreign, over(make) desc by(row(1)) xla(, ang(v)) recast(spike) lw(vthick)}{p_end}
{p 4 8 2}{cmd:. multidot price mpg weight if foreign, over(make) desc by(row(1)) xla(, ang(v)) recast(spike) lw(vthick) lc(orange_red*0.5)}{p_end}
{p 4 8 2}{cmd:. multidot price mpg weight if foreign, over(make) sort(make) desc by(row(1))   }{p_end}
{p 4 8 2}{cmd:. foreach v in mpg turn trunk headroom {c -(} }{p_end}
{p 4 8 2}{cmd:. 	local lbl`v' "`: var label `v''" }{p_end}
{p 4 8 2}{cmd:. {c )-}}{p_end}

{p 4 8 2}{cmd:. collapse mpg turn trunk headroom, by(rep78) }{p_end}

{p 4 8 2}{cmd:. foreach v in mpg turn trunk headroom {c -(} }{p_end}
{p 4 8 2}{cmd:. 	label var `v' "`lbl`v''" }{p_end}
{p 4 8 2}{cmd:. {c )-}}{p_end}

{p 4 8 2}{cmd:. multidot mpg turn trunk headroom, over(rep78) sort(rep78) desc by(row(1)) ms(O) }{p_end}
 
{p 4 8 2}{cmd:. clear }{p_end}
{p 4 8 2}{cmd:. input str13 country budget active reservists }{p_end}
{p 4 8 2}{cmd:. "United States"     604.5   1347        865}{p_end}
{p 4 8 2}{cmd:. "India"              51.1   1395       1155}{p_end}
{p 4 8 2}{cmd:. "China"             145.0   2183        510}{p_end}
{p 4 8 2}{cmd:. "Malaysia"            4.2    109         52 }{p_end}
{p 4 8 2}{cmd:. "Singapore"          10.2     73        313}{p_end}
{p 4 8 2}{cmd:. "Vietnam"             4.0    482       5000}{p_end}
{p 4 8 2}{cmd:. "Indonesia"           8.2    396        400}{p_end}
{p 4 8 2}{cmd:. "Philippines"         2.5    125        131}{p_end}
{p 4 8 2}{cmd:. "Taiwan"              9.8    215       1657}{p_end}
{p 4 8 2}{cmd:. "S. Korea"           33.8    630       4500}{p_end}
{p 4 8 2}{cmd:. "Japan"              47.3    247         56}{p_end}
{p 4 8 2}{cmd:. "N. Korea"              .   1190        600}{p_end}
{p 4 8 2}{cmd:. "Australia"          24.2     58         21 }{p_end}
{p 4 8 2}{cmd:. end }{p_end}

{p 4 8 2}{cmd:. label var budget "Defence budget ($ billion)"}{p_end}
{p 4 8 2}{cmd:. label var active "Active forces ('000)"}{p_end}
{p 4 8 2}{cmd:. label var reservists "Reservists ('000)" }{p_end}
{p 4 8 2}{cmd:. note : "Source: The Economist, April 22 2017"}{p_end}
{p 4 8 2}{cmd:. note : "Their source: IISS, 2016"}{p_end}

{p 4 8 2}{cmd:. multidot b a r, over(c) by(row(1) compact) recast(hbar) subtitle(, size(medsmall)) ytitle("") missing bfcolor(eltgreen)}{p_end}

{p 4 8 2}{cmd:. multidot a r b, over(c) by(row(1) compact) recast(hbar) subtitle(, size(medsmall)) ytitle("") xla(#5, labsize(small)) missing bfcolor(eltgreen)}{p_end}


{title:Author} 

{p 4 4 2}Nicholas J. Cox, University of Durham, U.K.{break} 
        n.j.cox@durham.ac.uk


{title:Also see}

{p 4 13 2}On-line:  help for {help graph dot}, {help graph bar}                                   

