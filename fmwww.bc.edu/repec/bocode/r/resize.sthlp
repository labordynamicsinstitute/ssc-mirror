{smcl}
{* 18jun2022}{...}
{* *! version 1.0.1  25jul2022}{...}
{hi:help resize}{...}
{right:}
{hline}

{title:Title}

{pstd}{hi:resize} {hline 2} Change the graph size but keep the font size unchanged {p_end}

{title:Syntax}

{pstd}{cmd:resize} [{it:name}] , {cmd:xsize(}{it:{help grstyle_set##size:sizelist}}{cmd:)}  {cmd:ysize(}{it:{help grstyle_set##size:sizelist}}{cmd:)} [{it:{help graph display:graph_display_options}}] 

{pstd}{cmd: resizecombine} [{it:namelist}] , {cmd:xsize(}{it:{help grstyle_set##size:sizelist}}{cmd:)}  {cmd:ysize(}{it:{help grstyle_set##size:sizelist}}{cmd:)} [{it:{help graph combine:graph_combine_options}}] 

{pstd}{cmd: resizec1leg} [{it:namelist}] , {cmd:xsize(}{it:{help grstyle_set##size:sizelist}}{cmd:)}  {cmd:ysize(}{it:{help grstyle_set##size:sizelist}}{cmd:)} [{it:{help grc1leg:grc1leg_options}}] 

{* {it:{help graph display:graph_display_options}}}
{synoptset 25}{...}
{p2col:{it:options}}Description{p_end}
{p2line}
{p2col:{cmd:ysize(}{it:{help grstyle_set##size:sizelist}}{cmd:)}}change height of graph. Enter in in cm (e.g. "9cm"), inch (e.g. "3.54inch") or other measures (see {it:{help grstyle_set##size:sizelist}}). This option is required.{p_end}
{p2col:{cmd:xsize(}{it:{help grstyle_set##size:sizelist}}{cmd:)}}change height of graph. This option is required.{p_end}
{p2line}
{p2colreset}{...}


{title:Description}

{pstd}
    {cmd:resize}, {cmd:resizecombine}, and {cmd:resizec1leg} keep the absolute font size (usually defined in pt) constant when changing the height and/or width of figures. 
These commands help you control font sizes and keep them coherent across all your figures. 

{pstd}
{cmd:resize} is an extension of {help graph display}, {cmd:resizecombine} an extension of {help graph combine} and {cmd:resizec1leg} an extension of {help grc1leg}.

{pstd}
    I recommend using these commands in combination with {help grstyle:{bf:grstyle}}, in particular, {help grstyle_set##size:{bf:grstyle set size}}. There, you can define the font sizes for all graph elements, see examples 2-4 below.

{pstd}{hi:Background of the ado:}{break}
If you change the size of a figure using graph display or similar commands, Stata automatically rescales the font size in proportion to the minimum out of the figure's height and width. However, this is not desired in many situations.
When we want to increase the size of a figure, we often do so to fit more content into the figure. Stata's default rescaling counters that. 
The new commands keep the {it:absolute} font size constant, meaning that we can increase (decrease) the figure's size if we want to show more (less) information in the figure. 

{pstd}
Books, articles and other texts are usually coherent in their font size.
If different paragraphs or chapters were written in different font sizes, this would seem rather odd.
In figures, however, such inconsistencies in font size are common.
At least in social science journals, one often finds figures with very different font sizes, even in the same article.
As a result, some figures with small type are difficult to decipher, while other figures with too large type consume an unnecessary amount of space.
In publications in the natural science, such as Science or Nature, font sizes tend to be coherent within and between articles, which improves the reading experience.
The commands {cmd:resize}, {cmd:resizecombine}, and {cmd:resizec1leg} make it easier for researchers to control font sizes and create a set of figures that are coherent in their font sizes. 

{title:Options}

{phang}
{cmd:ysize(}{it:{help grstyle_set##size:sizelist}}{cmd:)}
and
{cmd:xsize(}{it:{help grstyle_set##size:sizelist}}{cmd:)}
    specify the height and width of the entire graph. Internally, Stata uses inch, but you can specify sizes in centimeters (e.g. "9cm") or several other units.
For more information, see {it:{help grstyle_set##size:sizelist}} (package {search grstyle:{bf:grstyle}} is required).
Both {cmd:ysize(}{it:{help grstyle_set##size:sizelist}}{cmd:)} and {cmd:xsize(}{it:{help grstyle_set##size:sizelist}}{cmd:)} need to be specified. 

{title:Remarks}

{dlgtab:Which font size to use?}

{pstd}
Most social science journals have requirements concerning the font size of the main text, but not of the text in the figures. Journals in the natural sciences often require text in figures to be between 5 and 8pt. 
Social science tend to use larger fonts for their main text than natural science journals.
To match that, figures for the social sciences might also use slightly larger fonts, for example between 7 and 9pt. 

{dlgtab:Which font to use?}

{pstd}
Sans-serifs fonts, such as Arial or Helvetica, are preferable for figures because they are more readable in smaller font sizes.

{title:Examples}

{pstd}
    {hi:Example 1:}{break} An example for {hi:resize}. Stata's default font sizes remain unchanged:{break}
{stata sysuse auto, clear}
{p_end}
{phang}
{stata scatter price mpg, name(example1, replace)}
{p_end}
{phang}
{stata resize example1, xsize(15cm) ysize(8cm)}
{p_end}

{pstd}
    {hi:Example 2:}{break} Another example for {hi:resize}. Now, we change Stata's default font size and add more text elements (package {search grstyle:{bf:grstyle}} is required):{break} 
First, define the desired font sizes (8pt for all text in this example):{break}
{stata `"grstyle init"'}
{p_end}
{phang}
{stata `"grstyle set size 8pt: heading subheading body small_body text_option axis_title tick_label minortick_label 	key_label"'}
{p_end}

{phang}
Then, create and resize the figure:
{p_end}
{phang}
{stata `"sysuse auto, clear"'}
{p_end}
{phang}
{stata `"twoway (scatter price mpg) , title("All text has the same font size") subtitle("Same font size") text(8000 32 "Same font size", placement(west))  text(8000 32 "♥", placement(east) color(red)) name(example2, replace) note("8pt")"'}
{p_end}
{phang}
{stata `"resize example2, xsize(10cm) ysize(15cm)"'}
{p_end}
{pstd}
After resizing the figure, all text is still in 8pt. You can test this by exporting the figure to PDF or by copying it into programs like Word or PowerPoint and preserving the original figure size. 

{pstd}
    {hi:Example 3:}{break} Combine two graphs using {hi:resizecombine}. We change Stata's default font size (package {search grstyle:{bf:grstyle}} is required):{break} 
First, define the desired font sizes (8pt for the title and 6pt for all other text in this example):
{p_end}
{phang}
{stata `"grstyle init"'}
{p_end}
{phang}
{stata `"grstyle set size 8pt: heading"'}
{p_end}
{phang}
{stata `"grstyle set size 6pt: subheading body small_body text_option axis_title tick_label minortick_label key_label"'}
{p_end}

{phang}
Then, create and resize the figure. 
{p_end}
{phang}
{stata `"sysuse auto, clear"'}
{p_end}
{phang}
{stata `"twoway (scatter price mpg) , title("This is 8pt") subtitle("This is 6pt") text(8000 32 "6pt", placement(west))  text(8000 32 "♥", placement(east) color(red)) name(example3a, replace) note("6pt")"'}
{p_end}
{phang}
{stata `"twoway (scatter price mpg) if foreign==1, title("This is 8pt") subtitle("This is 6pt") text(8000 32 "6pt", placement(west))  text(8000 32 "♥", placement(east) color(red)) name(example3b, replace) note("6pt")"'}
{p_end}
{phang}
{stata `"resizecombine example3a example3b, xsize(12cm) ysize(12cm) note("also 6pt") "'}
{p_end}

{pstd}
    {hi:Example 4:}{break} Combine two graphs that have legends using {hi:resizec1leg}. We change Stata's default font size (package {search grstyle:{bf:grstyle}} is required):{break} 
First, define the desired font sizes (8pt for the title and 6pt for all other text in this example):
{p_end}

{phang}
{stata `"grstyle init"'}
{p_end}
{phang}
{stata `"grstyle set size 8pt: heading"'}
{p_end}
{phang}
{stata `"grstyle set size 6pt: subheading body small_body text_option axis_title tick_label minortick_label key_label"'}
{p_end}

{phang}
Then, create and resize the figure. 
{p_end}
{phang}
{stata `"sysuse auto, clear"'}
{p_end}
{phang}
{stata `"twoway (scatter price mpg) (lpoly price mpg) , title("This is 8pt") subtitle("This is 6pt") text(8000 32 "6pt", placement(west))  text(8000 32 "♥", placement(east) color(red)) name(example3a, replace) note("6pt")"'}
{p_end}
{phang}
{stata `"twoway (scatter price mpg) (lpoly price mpg) if foreign==1, title("This is 8pt") subtitle("This is 6pt") text(8000 32 "6pt", placement(west))  text(8000 32 "♥", placement(east) color(red)) name(example3b, replace) note("6pt")"'}
{p_end}
{phang}
{stata `"resizec1leg example3a example3b, xsize(12cm) ysize(12cm) note("also 6pt") "'}
{p_end}

{title:Author}

{pstd}
    Ansgar Hudde, University of Cologne, ansgar.hudde@wiso.uni-koeln.de

