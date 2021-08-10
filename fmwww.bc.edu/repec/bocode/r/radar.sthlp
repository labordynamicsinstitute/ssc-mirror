{smcl}
{* 10 Mar 2017}{...}
{cmd:help radar}
{hline}

{title:Title}

    {hi: Radar plots or Spider plots}

{title:Syntax}

{p 8 17 2}
{cmdab:radar} {it:axes_labels var1 }[{it:var2 ... }] 
[{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt lc}({help colorstyle}list)} specifies a list of colors for the observations (not axes).{p_end}
{synopt:{opt lp}({help linepatternstyle}list)} specifies a list of patterns for the observations (not axes).{p_end}
{synopt:{opt lw}({help linewidthstyle}list)} specifies a list of line widths for the observations (not axes).{p_end}
{synopt:{opt ms}({help symbolstyle}list)} specifies a list of marker symbols to use for observations BUT must be used in conjunction with the connected option (not axes).{p_end}
{synopt:{opt mc:olor}({help symbolstyle}list)} specifies a list of marker colors to use for observations BUT must be used in conjunction with the connected option (not axes).{p_end}
{synopt:{opt axelc}(colorlist)} specifies a list of colors for the axes.{p_end}
{synopt:{opt axelp}(patternlist)} specifies a list of patterns for the axes.{p_end}
{synopt:{opt axeslw}(linewidthlist)} specifies a list of line widths for the axes.{p_end}
{synopt:{opt labsize}({help textsizestyle})} specifies the text size of the node labels (not axes).{p_end}
{synopt:{opt radial}({help varname})} specifies a variable is to plotted as spikes along the spokes of the plot.{p_end}
{synopt:{opt connected}} specifies that rather than a line graph of observations but a connected line graph is drawn.{p_end}
{synopt:{opt r:label}(numlist)} specifies the ticks and labels of the spokes.{p_end}
{synopt:{help twoway_options} } specifies additional twoway options (not all of them area allowed), for example titles() and notes().{p_end}
{synoptline}
{p2colreset}{...}

{title:Description}

{pstd}
{cmd:radar} produces a radar plot from at least two variables. The first variable must always contain the label for the axes
and the second variable must be numeric. For example the dataset below,

. list food level
     +----------------+
     |   food   level |
     |----------------|
  1. |   beer      12 |
  2. | crisps       5 |
  3. |  bread       3 |
  4. |    veg      44 |
  5. |  fruit       7 |
     +----------------+

{pstd}
The axes of the radar plot will start at the top of the diagram and proceed in a clockwise direction. With the above dataset
the first axes will be labelled beer.

{pstd}
Missing values are included in the radar plot as gaps in the line joining observations.
This option is implemented using the {opt cmiss(n)} option of the twoway line graph, see help {help connect_options}.

{title:Options}

{dlgtab:Main}

{phang}
{opt lc}({help colorstyle}list) specifies a list of colors for the observations (not axes).

{phang}
{opt lp}({help linepatternstyle}list) specifies a list of patterns for the observations (not axes).

{phang}
{opt lw}({help linewidthstyle}list) specifies a list of line widths for the observations (not axes).

{phang}
{opt ms}({help symbolstyle}list)} specifies a list of marker symbols to use for observations BUT must be used in conjunction with the connected option (not axes).{p_end}

{phang}
{opt mc:olor}({help symbolstyle}list)} specifies a list of marker colors to use for observations BUT must be used in conjunction with the connected option (not axes).{p_end}

{phang}
{opt axelc}(colorstylelist) specifies a list of colors for the axes.

{phang}
{opt axelp}(linepatternstylelist) specifies a list of patterns for the axes.

{phang}
{opt axelw}(linewidthstylelist) specifies a list of line widths for the axes.

{phang}
{opt labsize}(textsizestyle) specifies the text size of the node labels (not axes).

{phang}
{opt radial}(varname) specifies that the variable in the option be plotted as "spikes" along the spokes.

{phang}
{opt connected} specifies that rather than a line graph of observations but a connected line graph is drawn.{p_end}

{phang}
{opt r:label}(numlist) specifies the ticks and labels of the spokes. The default is to have 5 values displayed, note that the 
value that is the centre or smallest tick is suppressed but the value is included as a note below the graph. The note can
be overwritten by using the {hi: note()} option.

{phang}
{opt {help twoway_options}} specifies additional twoway options, for example titles() and notes().


{title:Examples}

{pstd}
The examples below highlight the use of the {hi:radar} plot on the Auto dataset. The only limitation
is the number of "spokes" hence the commands are limited to just the foreign cars. Technical note: the limitation on
the number of spokes is unknown because the limit is due to the size of macros being returned as
part of a rclass program.

{pstd}
Click below to load dataset 

{phang} 
{stata sysuse auto}

{pstd}
Click below (after the dataset is loaded to see the distribution of weight for the foreign makes of car

{phang}
{stata radar make weight if foreign}

{pstd}
Click below to see the distribution of turn mpg and trunk for each foreign make of car.

{phang}
{stata radar make turn mpg trunk if foreign} {p_end}
{phang}
{stata radar make turn mpg trunk if foreign, title(Nice Radar graph)} {p_end}
{phang}
{stata radar make turn mpg trunk if foreign, title(Nice Radar graph) lc(red blue green) lp(dash dot dash_dot)}

{phang}
{stata radar make turn mpg trunk if foreign, title(Nice Radar graph) lc(red blue green) r(0 12 14 18 50)}

{phang}
{stata radar make turn mpg trunk if foreign, title(Nice Radar graph) lc(red blue green) lw(*1 *2 *4) r(0 12 14 18 50)}

{phang}
{stata radar make turn mpg trunk if foreign, title(Nice Radar graph) lc(red blue green) lw(*1 *2 *4) r(0 12 14 18 50) labsize(*.5)}

{phang}
{stata radar make turn mpg trunk if foreign, title(Nice Radar graph) lc(red blue green) lw(*1 *2 *4) r(0 12 14 18 50) connected ms(D Oh S) labsize(*.5)}

{pstd}
There is no real advantage of a radar diagram compared to a scatter plot unless there was some sort of directional data.


{phang}
To add extra spikes for trunk instead of the contour

{phang}
{stata radar make turn mpg if foreign,radial(trunk) title(Nice Radar graph) lc(red blue green) lw(*1 *2 *4) r(0 12 14 18 50) labsize(*.5)}

{title:Author}

{pstd}
Adrian Mander, MRC Biostatistics Unit, Cambridge, UK.

{pstd}
Email {browse "mailto:adrian.mander@mrc-bsu.cam.ac.uk":adrian.mander@mrc-bsu.cam.ac.uk}

{title:See Also}

{pstd}
Other Graphic Commands I have written: {p_end}

{synoptset 27 }{...}
{synopt:{help batplot} (if installed)} {stata ssc install batplot}   (to install) {p_end}
{synopt:{help cdfplot} (if installed)} {stata ssc install cdfplot}   (to install) {p_end}
{synopt:{help contour} (if installed)}   {stata ssc install contour}     (to install) {p_end}
{synopt:{help drarea}  (if installed)}   {stata ssc install drarea}      (to install) {p_end}
{synopt:{help graphbinary} (if installed)}   {stata ssc install graphbinary} (to install) {p_end}
{synopt:{help metagraph} (if installed)}   {stata ssc install metagraph}   (to install) {p_end}
{synopt:{help palette_all} (if installed)}   {stata ssc install palette_all} (to install) {p_end}
{synopt:{help plotbeta} (if installed)}   {stata ssc install plotbeta}    (to install) {p_end}
{synopt:{help plotmatrix} (if installed)}   {stata ssc install plotmatrix}  (to install) {p_end}
{synopt:{help surface}  (if installed)}   {stata ssc install surface}     (to install) {p_end}
{synopt:{help trellis}  (if installed)}   {stata ssc install trellis}     (to install) {p_end}
{p2colreset}{...}

