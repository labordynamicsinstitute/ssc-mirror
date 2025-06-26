{smcl}
{* 15aug2004/19mar2007/25sep2008/27jan2009/6feb2009/9feb2009/28aug2020/24jun2025}{...}
{hline}
help for {cmd:triplot}
{hline}

{title:Triangular plot}

{p 8 17 2} 	
{cmd:triplot}
{it:leftvar rightvar botvar}
[{cmd:if} {it:exp}] 
[{cmd:in} {it:range}]
[{weight}] 

{p 17 17 2} 
[ 
{cmd:,}
{cmd:max(}{it:#}{cmd:)} 
{cmdab:sep:arate(}{it:varname}{cmd:)} 
{cmd:by(}{it:byvar} [{cmd:,} {it:by_options}]{cmd:)} 

{p 17 17 2} 
{cmdab:la:bel(}{it:numlist}{cmd:)}
{cmd:grid(}{it:grid_options}{cmd:)} 

{p 17 17 2} 
{cmdab:vert:ices(}{it:#}{cmd:)} 
{cmd:frame(}{it:frame_options}{cmd:)} 

{p 17 17 2}
{cmd:y} 
{cmd:y(}{it:y_options}{cmd:)} 

{p 17 17 2}
{cmd:centre(}{it:#left #right #bottom}{cmd:)} 

{p 17 17 2} 
{cmd:ltext(}{it:string}{cmd:)}
{cmd:rtext(}{it:string}{cmd:)}
{cmd:btext(}{it:string}{cmd:)}
{cmd:bltext(}{it:string}{cmd:)}
{cmd:ttext(}{it:string}{cmd:)}
{cmd:brtext(}{it:string}{cmd:)}
{cmd:text(}{it:text_options}{cmd:)}

{p 17 17 2} 
{it:scatter_options} 
]

{p 4 4 2}{cmd:aweight}s, {cmd:fweight}s and {cmd:pweight}s are allowed: 
see {help weight}. 


{title:Description} 

{p 4 4 2} 
{cmd:triplot} produces a triangular plot of the three variables {it:leftvar},
{it:rightvar} and {it:botvar}, which are plotted on the left, right and bottom
sides of an equilateral triangle. Each should have values between 0 and some
maximum value (default 1) and the sum of the three variables should be equal to
that maximum (within rounding error). Most commonly, three fractions or
proportions add to 1, or three percents add to 100.

{p 4 4 2} 
The constraint that the three variables have a constant sum means that there
are just two independent pieces of information. Hence it is possible to plot
observations in two dimensions within a triangle, which is a 2-simplex.

{p 4 4 2}
Triangular plots appear under various names in the literature, including
tripolar, 
trinomial, 
trilinear, 
triaxial, 
three-element maps, 
ternary, 
simplex, 
reference triangles,
percentage triangles, 
mixture, 
barycentric. 
Common geological applications are to sedimentary facies or particle form: 
hence more specific terms such as facies and form triangles. 
In genetics, applications are often called de Finetti diagrams. 


{title:Remarks} 

{p 4 4 2}The author recommends for Stata 18 up the {cmd:stcolor} scheme,
and for earlier versions the {cmd:s1color} scheme, for defaults 
congenial with these plots.

{p 4 4 2}
Howarth (1996) describes the use of ternary diagrams in the physical
sciences in the 18th and 19th centuries, with applications in the study
of colour mixing, photoelasticity and the behaviour of three-component
systems in metallurgy and physical chemistry.  Scientists using the
ideas included Tobias Mayer (1723{c -}1762), Georg Christoph Lichtenberg
(1742{c -}1799), Thomas Young (1773{c -}1829), James David Forbes
(1809{c -}1868), James Clerk Maxwell (1831{c -}1879), Josiah Willard
Gibbs (1839{c -}1903) and George Gabriel Stokes (1819{c-}1903).  Printed
graph paper for ternary diagrams has been available since 1897. 
 
{title:Options} 

{p 4 8 2}{cmd:max()} indicates the upper limit of each variable, and the
sum of all three variables. Default value is 1. {cmd:max(100)}
indicates percents.

{p 4 8 2}{cmd:separate()} indicates that observations are to be
subdivided into classes according to a specified variable. A legend will
be shown if and only if more than one class is so defined. Each class is
plotted as if it defined a single variable. Thus if {cmd:separate()}
subdivides into two classes, and you want points for each class to be 
connected and have different marker colours of your choice, specify also 
options such as {cmd:c(l l) mcolor(pink blue)}. 

{p 4 8 2}{cmd:by()} specifies that plots are to be shown separately according to
the categories of a specified variable. 

{p 4 8 2}{cmd:label()} specifies a list of numeric labels to be shown on each
side of the triangle, which imply a grid of reference lines within the
triangle.  The default is {cmd:0(0.2)1}, or {cmd:0(20)100} if {cmd:max(100)} is
specified, or {cmd:0(200)1000} if {cmd:max(1000)} is specified.  As a special
case, {cmd:label(nolabels)} specifies no labels and no reference lines.

{p 4 8 2}{cmd:grid()} specifies options controlling the rendering of the labels
and grid lines.  Know that {help twoway_connected:twoway connected} is used for 
rendering and that the labels are shown as marker labels: hence use 
{help connect_options:connect options} or {help marker_label_options:marker label options} 
to make changes from the default. Example: {cmd:grid(lpat(shortdash))} changes 
the line pattern to shortdash. 

{p 4 8 2}{cmd:vertices()} specifies that only the vertices should be shown and
not the complete triangular frame. The argument is the fraction of each side
that is shown. {cmd:vertices(0.1)} means that 0.1 or 10% of each side will be
shown.

{p 4 8 2}{cmd:frame()} specifies options controlling the rendering of the
triangular frame.  Know that {help line} is used for rendering: hence use 
{help connect_options:connect options} to make changes from the default.
Example: {cmd:frame(lpat(dot))} changes the line pattern to dot. 

{p 4 8 2}{cmd:y} specifies that the Y is to be drawn that divides the triangle
into regions in which each variable is greater than the other two. Some
political scientists call the spokes of the Y 'win lines'. 
Unless {cmd:centre()} is specified, each spoke connects
the midpoint of each side to the centroid of the triangle (which, by virtue of
symmetry, is also the incentre, the circumcentre, the orthocentre and the
Fermat point of the triangle). 

{p 4 8 2}{cmd:y()} specifies options controlling the rendering of the Y. Know
that {help line} is used for rendering: hence use 
{help connect_options:connect options} to make changes from the default.
Example: {cmd:y(lcolor(green))} changes the line colour to green. 

{p 4 8 2}{cmd:centre()} specifies three numbers to be used as centre 
for the triangle, referring in order to left, right and bottom variables. 
Suppose three percent variables {it:p}, {it:q}, {it:r}
are being shown, and three numbers {it:P}, {it:Q} and {it:R} are specified
as centre, with sum 100. Then data are transformed to 

	({it:p/P}) / ({it:p/P}  + {it:q/Q}  + {it:r/R}) 
	({it:q/Q}) / ({it:p/P}  + {it:q/Q}  + {it:r/R}) 
	({it:r/R}) / ({it:p/P}  + {it:q/Q}  + {it:r/R}) 

{p 8 8 2}Vertices remain vertices and contours of {it:p}, {it:q}, {it:r} 
remain straight. See Upton (2001). 

{p 8 8 2}As a convenience to users who do not use standard English 
spelling, the synonym {cmd:center()} is also allowed. 

{p 4 8 2}{cmd:ltext()}, {cmd:rtext()} and {cmd:btext()} control text on the
left, right and bottom sides of the plot. They default to the variable labels
(or if those do not exist, the names) of {it:leftvar}, {it:rightvar} and
{it:botvar}. In each case, specifying {cmd:" "} blanks out the text.

{p 4 8 2}{cmd:bltext()}, {cmd:ttext()}, {cmd:brtext()} control text by the
bottom left, top and bottom right vertices of the triangle.  These options are
intended as an alternative to numeric labels at the vertices.

{p 4 8 2}{cmd:text()} specifies options controlling the rendering of the text
specified by the {cmd:*text()} options.  Know that {help scatter} is used for
rendering the text as marker labels: hence use 
{help marker_label_options:marker label options} to make changes from the
default.  Example: {cmd:text(mlabsize(medium))} changes the label text size
pattern to medium. 

{p 4 8 2}{it:scatter_options} are options of {help scatter}. 


{title:Examples} 

{p 4 8 2}{cmd:. * graph scheme and colours assume Stata 18 up is in use}

{p 4 8 2}{cmd:. * US civilian labour force composition, from Beniger (1996) }{p_end}
{p 4 8 2}{cmd:. clear}{p_end}
{p 4 8 2}{cmd:. input float(year agriculture industry tertiary)}{p_end}
{p 4 8 2}{cmd:1800 87.2  1.4      11.5}{p_end}
{p 4 8 2}{cmd:1810   81  6.5      12.5}{p_end}
{p 4 8 2}{cmd:1820   73   16      11.1}{p_end}
{p 4 8 2}{cmd:1830 69.7 17.6      12.6}{p_end}
{p 4 8 2}{cmd:1840 58.8 24.4      16.8}{p_end}
{p 4 8 2}{cmd:1850 49.5 33.8      16.7}{p_end}
{p 4 8 2}{cmd:1860 40.6   37      22.4}{p_end}
{p 4 8 2}{cmd:1870   47   32        21}{p_end}
{p 4 8 2}{cmd:1880 43.7 25.2      31.1}{p_end}
{p 4 8 2}{cmd:1890 37.2 28.1      34.7}{p_end}
{p 4 8 2}{cmd:1900 35.3 26.8      37.9}{p_end}
{p 4 8 2}{cmd:1910 31.1 36.3      32.6}{p_end}
{p 4 8 2}{cmd:1920 32.5   32      35.5}{p_end}
{p 4 8 2}{cmd:1930 20.4 35.3      44.3}{p_end}
{p 4 8 2}{cmd:1940 15.4 37.2      47.4}{p_end}
{p 4 8 2}{cmd:1950 11.9 38.3      49.8}{p_end}
{p 4 8 2}{cmd:1960    6 34.8      59.2}{p_end}
{p 4 8 2}{cmd:1970  3.1 28.6      68.3}{p_end}
{p 4 8 2}{cmd:1980  2.1 22.5      75.4}{p_end}
{p 4 8 2}{cmd:end}{p_end}

{p 4 8 2}{cmd:. label var tertiary "services and information"}{p_end}

{p 4 8 2}{cmd:. set scheme stcolor }{p_end}
{p 4 8 2}{cmd:. generate pos = 3}{p_end}
{p 4 8 2}{cmd:. replace pos = 9 if inlist(year, 1900, 1920)}{p_end}
{p 4 8 2}{cmd:. replace pos = 10 if inlist(year, 1870, 1980)}{p_end}
{p 4 8 2}{cmd:. replace pos = 12 if inlist(year, 1880, 1970)}{p_end}
{p 4 8 2}{cmd:. triplot agriculture industry tertiary, c(l) max(100)
mcolor(stc1) mlabel(year) mlabsize(*0.7) mlabc(stc1) clpat(solid) mlabvpos(pos)}{p_end}


{title:Author}

{p 4 4 2}Nicholas J. Cox, Durham University, U.K.{break}
n.j.cox@durham.ac.uk


{title:Acknowledgments} 

{p 4 4 2}Friedrich Huebler pointed to some bugs and posed some useful 
questions. 
Scott Merryman and Thomas Steichen found other bugs. 
Vince Wiggins provided encouragement. 
In 2025, questions from Julia Mueller prompted the unearthing code
for supporting weights. 


{title:References}

{p 4 8 2}
Beniger, J.R. 1986. 
{it:The Control Revolution: Technological and Economic Origins of the Information Society.}
Cambridge, MA: Harvard University Press.

{p 4 8 2}Cox, N.J. 2004. Graphing categorical
and compositional data. {it:Stata Journal} 4: 190{c -}215.
{browse "http://www.stata-journal.com/article.html?article=gr0004":http://www.stata-journal.com/article.html?article=gr0004}

{p 4 8 2}Gray, J. 1993. M{c o:}bius's geometrical mechanics. In Fauvel, J., R. Flood and R. Wilson (eds)
{it:M{c o:}bius and his band: mathematics and astronomy in nineteenth-century Germany.} 
Oxford: Oxford University Press, pp.79{c -}103.

{p 4 8 2} 
Howarth, R.J. 1996. Sources for a history of the ternary diagram. 
{it:British Journal for the History of Science} 29: 337{c -}356. 

{p 4 8 2}M{c o:}bius, August Ferdinand. 1827. {it:Der barycentrische Calcul: ein neues H{c u:}lfsmittel zur analytischen Behandlung der Geometrie} 
{it:dargestellt und insbesondere auf die Bildung neuer Classen von Aufgaben und die Entwicklung mehrerer Eigenschaften der Kegelschnitte.} 
Leipzig: Johann Ambrosius Barth. [1790{c -}1868] 

{p 4 8 2}Rollinson, H.R. 1993. 
{it:Using Geochemical Data: Evaluation, Presentation, Interpretation.} 
London: Longman. 

{p 4 8 2}Upton, G.J.G. 2001. A toroidal scatter diagram for ternary variables.
{it:The American Statistician} 55: 247{c -}250. 

