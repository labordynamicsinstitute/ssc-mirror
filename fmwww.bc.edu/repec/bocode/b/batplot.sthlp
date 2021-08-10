{smcl}
{* *! version 1.0 23 Mar 2021}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install command2" "ssc install command2"}{...}
{vieweralsosee "Help command2 (if installed)" "help command2"}{...}
{viewerjumpto "Syntax" "batplot##syntax"}{...}
{viewerjumpto "Description" "batplot##description"}{...}
{viewerjumpto "Options" "batplot##options"}{...}
{viewerjumpto "Remarks" "batplot##remarks"}{...}
{viewerjumpto "Examples" "batplot##examples"}{...}
{title:Title}
{phang}
{bf:batplot} {hline 2} Produces a Bland-Altman plot when there is a relationship between paired differences and their    average

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:batplot}
varlist
(min=2
max=2)
[{help if}]
[{help in}]
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Optional}
{synopt:{opt no:trend}} specifies that the original Bland-Altman plot (without a trend) be plotted.

{synopt:{opt info}} specifies that the percentage of points outside the limits of agreement are
displayed as a subtitle.

{synopt:{opt val:abel(varname)}} pecifies that the points outside the limits of agreement be labelled using
the variable varname.

{synopt:{opt moptions(string asis)}} specifies options for the markers that lie outside the limits of agreement.

{synopt:{opt shading(numlist min=2  max=2)}} specifies the extent of shading beyond the range of the data.

{synopt:{opt sc:atter(string asis)}} specifies options for the scatter part of the final plot.

{synopt:{opt nog:raph}} specifies that the graph is not displayed to the graphics window.

{synopt:{opt dp(#)}} specifies the precision of the numbers in the title of the graph.

{synopt:{opt rarea(string asis)}} specifies options for the rarea part of the final plot.

{synopt:{opt *}}  specifies other twoway options, for example titles and labels.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}

{pstd}
    batplot produces a Bland-Altman plot adjusted (or not) for trend.

{pstd}
    The standard Bland-Altman plot is between the difference of paired variables versus the average,
    this is produced using the notrend option. The main addition that this command handles is when
    there is a linear relationship between the the paired difference and the paired average. A
    regression model is used to adjust the limits of agreement accordingly.  This is particularly
    useful when the two variables might be measured on different scales and hence a straight conversion
    factor would recalibrate the two variables.

{marker options}{...}
{title:Options}
{dlgtab:Main}

{phang}
{opt no:trend} specifies that the original Bland-Altman plot (without a trend) be plotted.

{phang}
{opt info} specifies that the percentage of points outside the limits of agreement are displayed as a
subtitle. Additionally when using the notrend option the limits of agreement and mean
difference are included in the subtitle.

{phang}
{opt val:abel(varname)} specifies that the points outside the limits of agreement be labelled using the
variable varname.

{phang}
{opt moptions(string asis)} specifies options for the markers that lie outside the limits of agreement, the options
can be anything from the scatter marker options.

{phang}
{opt shading(numlist min=2  max=2)} specifies the extent of shading beyond the range of the data. The default is that
the limits of shading is determined by the values in the xlabel option.

{phang}
{opt sc:atter(string asis)} specifies options for the scatter part of the final plot.

{phang}
{opt nog:raph}  specifies that the graph is not displayed to the graphics window.

{phang}
{opt dp(#)} specifies the precision of the numbers in the title of the graph. The default is 2 decimal
places.

{phang}
{opt rarea(string asis)}  specifies options for the rarea part of the final plot.

{phang}
{opt *}  specifies other twoway options, for example titles and labels.


{marker examples}{...}
{title:Examples}

    {pstd}
    Using the auto.dta dataset supplied with STATA 8 this command can check whether there is agreement
    between turning circle (ft) and miles per gallon, click the highlighted text in order,

    {stata sysuse auto, clear}

    {stata batplot mpg turn}

    This is the most basic graphic and using twoway options the look can be improved by clicking below,

    {stata batplot mpg turn, title(Agreement between mpg and turn) xlab(26(4)38)}

    By specifying extra options the outlying points can be labelled and identified by the car make,

    {stata batplot mpg turn, title(Agreement between mpg and turn) info valabel(make) xlab(26(4)38)}

    To obtain the original Bland Altman plot use the notrend option,

    {stata batplot mpg turn, title(Agreement between mpg and turn) info valabel(make) notrend xlab(26(4)38)}

    To improve the labelling of the point VW it may be preferable to change the clock position of the
    label i.e.  labels could appear to the left of the point. This is handled below with moptions().

    {pstd}
    {stata batplot mpg turn, title(Agreement between mpg and turn) info valabel(make) notrend xlab(26(4)38) moptions(mlabp(9))}

    Additionally in the case of multiple scatter points by using the scatter() option the user can
    specify to "jitter" datapoints

    {stata batplot mpg turn, notrend xlab(26(4)38) moptions(mlabp(9)) sc(jitter(4))}

    {pstd}
    Add a line at 0 to the above plot and also changes the transparency in the area plot so the 
    yline() option can be seen.
    
    {pstd}
    {stata batplot mpg turn, notrend xlab(26(4)38) moptions(mlabp(9)) sc(jitter(4)) rarea(bc(gs13%50)) yline(0, lc(black))}



{title:Stored results}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Locals}{p_end}
{synopt:{cmd:r(mean)}}  is the mean. {p_end}
{synopt:{cmd:r(b0)}}  is the intercept. {p_end}
{synopt:{cmd:r(b1)}}  is the slope. {p_end}
{synopt:{cmd:r(c0)}}  is the intercept for the trend line. {p_end}
{synopt:{cmd:r(c1)}}  is the slope for the trend line. {p_end}
{synopt:{cmd:r(eqn)}}  is the equation. {p_end}
{synopt:{cmd:r(upper)}}  is the upper limit equation. {p_end}
{synopt:{cmd:r(lower)}}  is the lower limit equation. {p_end}


{title:References}
{pstd}

{pstd}
Bland JM, Altman DG. (1999) Measuring agreement in method comparison studies. Statistical Methods in Medical Research 8, 135-160.

{pstd}

{pstd}


{title:Author}
{p}

Prof Adrian Mander, Cardiff University.

Email {browse "mailto:mandera@cardiff.ac.uk":mandera@cardiff.ac.uk}



