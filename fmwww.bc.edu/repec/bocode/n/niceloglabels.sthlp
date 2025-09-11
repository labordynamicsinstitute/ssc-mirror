{smcl}
{* 23oct2017/29jan2018/24aug2020/5sep2025}{...}
{cmd:help niceloglabels}{right:({browse "!!!":SJ25-4: gr0072_2})}
{hline}

{title:Title}

{p2colset 5 22 24 2}{...}
{p2col :{cmd:niceloglabels} {hline 2}}Nice axis labels for logarithmic
scales{p_end}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:niceloglabels}
{it:varname}
{ifin}{cmd:,}
{cmdab:l:ocal(}{it:macname}{cmd:)}
{cmdab:s:tyle(}{it:style}{cmd:)} 
[{cmdab:p:owers}
{cmdab:unit:fraction}]

{p 8 17 2}
{cmd:niceloglabels}
{it:#}1 {it:#}2{cmd:,}
{cmdab:l:ocal(}{it:macname}{cmd:)}
{cmdab:s:tyle(}{it:style}{cmd:)} 
[{cmdab:p:owers}
{cmdab:unit:fraction}] 


{title:Description}

{p 4 4 2}
{cmd:niceloglabels} suggests axis labels that would look nice on a graph using
a logarithmic scale.  It can help when you choose {cmd:yscale(log)} or
{cmd:xscale(log)}, or both, and wish to show nicer labels than the default.
Results are put in a local macro for later use.


{title:Options}

{p 4 8 2}
{cmd:local(}{it:macname}{cmd:)} inserts the specification of labels in local
macro {it:macname} within the calling program's space.  Hence, that macro will
be accessible after {cmd:niceloglabels} has finished.  This is helpful for
later use with {helpb graph} or other graphics commands.  {cmd:local()} is
required.

{p 8 8 2}
Anyone new to the idea and use of local macros should study the examples
carefully.  {cmd:niceloglabels} creates a local macro, which is a kind of bag
holding the text to be inserted in a {cmd:graph} command.  The local macro is
referred to in that graph command using the punctuation {cmd:` '} around the
macro name.  Note that the opening (left) single quote and the closing (right)
single quote are different.  Other single quotation marks will not work.  Do
not be troubled by the closing single quote ({cmd:'}) appearing as upright in
many fonts.

{p 4 8 2}
{cmd:style(}{it:style}{cmd:)} specifies a style for axis labels.
{cmd:style()} is required.  See {it:Remarks} below.

{p 4 8 2}
{cmd:powers} specifies that labels be specified using syntax interpreted by
{helpb graph} as superscripts and ready to be used within a {cmd:ylabel()} or
{cmd:xlabel()} option call.  Thus, if the labels were 100, 1,000, and 10,000,
the output would be 
{cmd:100 "10{c -(}sup:2{c )-}" 1000 "10{c -(}sup:3{c )-}" 10000 "10{c -(}sup:4{c )-}"}.

{p 4 8 2}
{cmd:unitfraction} specifies that labels for values below 1 be shown as
unit fractions with numerator 1.  For example, with style 2 you might
prefer seeing 1/2 1/4 1/8 1/16 rather than 0.5 0.25 0.125 0.0625 and
with style 1 you might prefer seeing 1/10 1/100 and so forth.  This
option is supported only for styles for which it seems attractive,
namely, styles 1 and 2.  Inspiration for this option came from an example
in Wilke (2019, 215). 


{title:Remarks}

{p 4 4 2}
There are two syntaxes.  In the first, the name of a numeric variable must be
given.  The values selected must all be positive.  In the second, two numeric
values are given, which will be interpreted as indicating minimum and maximum
of an axis range.  Those two values can be given in any order, but as before,
values must both be positive.

{p 4 4 2}
"Nice" is a little hard to define but easier to recognize.  For example, it is
a bonus if labels are exactly or approximately equally spaced on a logarithmic
scale (or conversely, on the original scale), and it is a bonus if numbers are
powers of 10 or 2 multiplied by small integers.  Users must specify their
preferred {it:style}, one from the following list: 

    1 means powers of 10 such as ..., 0.1, 1, 10, 100, 1,000, ...
    13 means cycling such as ..., 0.3, 1, 3, 10, 30, 100, 300, ...
    15 means cycling such as ..., 0.5, 1, 5, 10, 50, 100, 500, ...
    125 means cycling such as ..., 0.1, 0.2, 0.5, 1, 2, 5, 10, ...
    147 means cycling such as ..., 0.1, 0.4, 0.7, 1, 4, 7, 10, ...

    2 means powers of 2 such as ..., 1, 2, 4, 8, 16, ...

{p 4 4 2}
When the ratio of maximum (max) and minumum (min) is an order of magnitude
(power of 10) or less, none of these styles will suggest more than a few
labels.  In that case, you are almost certainly better off with labels equally
spaced on the original scale, which is what Stata gives you anyway.

{p 4 4 2}
To make this concrete, here are the numbers of labels suggested when the
minimum is 10 = 1e1 = 10^1 and the power of the maximum is as tabulated in
rows.  Thus, the first row is for min = 10 and max = 100 = 1e2 = 10^2, for
which the labels suggested, for styles 2 147 125 15 13 1, are, respectively,
16 32 64; 10 40 70 100; 10 20 50 100; 10 50 100; 10 30 100; 10 100;  hence,
the numbers of labels are 3 4 4 3 3 2.

                     style 
            {c |}   2  147  125  15  13   1
          {hline 2}{c +}{hline 26}
          2 {c |}   3    4    4   3   3   2
          3 {c |}   7    7    7   5   5   3
    power 4 {c |}  10   10   10   7   7   4
    of    5 {c |}  13   13   13   9   9   5
    max   6 {c |}  17   16   16  11  11   6
          7 {c |}  20   19   19  13  13   7
          8 {c |}  23   22   22  15  15   8
          9 {c |}  27   25   25  17  17   9

{p 4 4 2}
Powers of 2 make most sense in practice when the amounts to be shown are small
positive integers or the problem has some combinatorial flavor, or both.

{p 4 4 2}
{cmd:niceloglabels} is conservative in that it typically will not suggest
labels outside the data range.  You could add such on the fly in your calls to
later graphics commands.  Technical hint: The small print behind "typically"
is a fudging of minimum and maximum as a workaround for precision problems.

{p 4 4 2}
For an example of 147, see Dupont (2009, 270).

{p 4 4 2}
Note the suggestion by Cleveland (1985, 39; 1994, 39) of 3-10 labels on any
axis.


{title:Examples}

{p 4 8 2}{cmd:. sysuse census}{p_end}
{p 4 8 2}{cmd:. summarize}{p_end}
{p 4 8 2}{cmd:. set scheme s1color}{p_end}

{p 4 8 2}{cmd:. niceloglabels pop, local(yla) style(125)}{p_end}
{p 4 8 2}{cmd:. quantile pop, yscale(log) ylabel(`yla', angle(horizontal)) rlopts(lcolor(none))}{p_end}

{p 4 8 2}{cmd:. niceloglabels pop, local(yla) style(125) powers}{p_end}
{p 4 8 2}{cmd:. quantile pop, yscale(log) ylabel(`yla', angle(horizontal)) rlopts(lcolor(none))}

{p 4 8 2}{cmd:* log scale does not rule out change of units too}{p_end}
{p 4 8 2}{cmd:. generate pop2 = pop/1e6}{p_end}
{p 4 8 2}{cmd:. label var pop2 "Population (m)"}{p_end}
{p 4 8 2}{cmd:. niceloglabels pop2, local(yla) style(125)}{p_end}
{p 4 8 2}{cmd:. quantile pop2, yscale(log) ylabel(`yla', angle(horizontal)) rlopts(lcolor(none))}{p_end}

{p 4 8 2}{cmd:. niceloglabels 2e2 2e4, local(yla) style(125)}{p_end}
{p 4 8 2}{cmd:. niceloglabels 1e1 1e9, local(yla) style(1) powers}{p_end}

{p 4 8 2}{cmd:. niceloglabels 0.1 1000, local(yla) style(1) unitfraction}{p_end}
{p 4 8 2}{cmd:. niceloglabels 0.1 1000, local(yla) style(2) unitfraction}{p_end}


{title:Author}

{pstd}
Nicholas J. Cox{break}
Department of Geography{break}
Durham University{break}
Durham, UK{break}
n.j.cox@durham.ac.uk


{title:Acknowledgments}

{p 4 4 2}
Thanks to Chuck Huber, Ariel Linden, Tim Morris, Patrick Royston, and Vince
Wiggins for helpful discussion and encouragement.

{p 4 4 2}
Thanks to William Dupont for telling me about 147. Thanks also to Ian White 
for discussion that led to an attempt to provide better error messages 
for those confused by the syntax. 


{title:References}

{phang}
Cleveland, W. S. 1985.  {it:The Elements of Graphing Data}. Monterey, CA:
Wadsworth.

{phang}
------. 1994. 
{it:The Elements of Graphing Data}. Rev. ed.
Summit, NJ: Hobart.

{p 4 8 2}
Dupont, W. D. 2009.  
{it:Statistical Modeling for Biomedical Researchers: A Simple Introduction to the Analysis of Complex Data}. 2nd ed.
Cambridge: Cambridge University Press.

{p 4 8 2}
Wilke, C. O. 2019. 
{it:Fundamentals of Data Visualization: A Primer on Making Informative and Compelling Figures}.
Sebastopol, CA: O'Reilly. 


{title:Also see}

{p 4 14 2}
Article:  {it:Stata Journal}, volume 20, number 4: {browse "https://doi.org/10.1177/1536867X20976342":gr0072_1}{break}
          {it:Stata Journal}, volume 18, number 1: {browse "http://www.stata-journal.com/article.html?article=gr0072":gr0072}{p_end}

{p 7 14 2}
help:  {manhelpi axis_label_options G-3}{p_end}
