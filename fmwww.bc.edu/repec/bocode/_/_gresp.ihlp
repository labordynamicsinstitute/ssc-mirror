{* *! version 0.5.1 07oct2021}{...}

{phang} 
{hi:[D] egen: resp} {hline 2} RESP for {help egen}.
{p_end}

{marker syntax}{...}
{title:Syntax}

{phang} 
Generate a new variable with AI, AOER, RIC, RPA, RSI or RESP values{...}
    using Stata's {help egen} command.
{p_end}

{pmore}
[{help by:{bf:by} {it:varlist}{bf::}}]
{cmd:egen}
{dtype}
{newvar}
{cmd:=}
{cmd:resp}{cmd:(}{varname}{cmd:)}
{ifin}{cmd:,}
{cmdab:d:im(}{var:1} {var:2}{cmd:)}
[{cmdab:m:ode(}{help strings:string}{cmd:)}
{cmdab:dup:licates}]
{p_end}

{phang} 
There is a wrapper for the above function.
{p_end}

{pmore}
[{help by:{bf:by} {it:varlist}{bf::}}]
{cmd:resp}
{newvar}
{varname}
{ifin}{cmd:,}
{cmdab:d:im(}{var:1} {var:2}{cmd:)}
[{cmdab:m:ode(}{help strings:string}{cmd:)}
{cmdab:dup:licates}]
{p_end}



{synoptset 30 tabbed}{...}
{synopthdr:Option}
{synoptline}
{synopt:{cmdab:d:im(}{var:1} {var:2}{cmd:)}}{...}
    defines the variables for aggregation (see below);{p_end}
{synopt:{cmdab:m:ode(}{help strings:string}{cmd:)}}{...}
    {help strings:string} is one of {cmd:[ai|aoer|ric|rpa|rsi|resp]};{...}
	default is {cmd:ai};{p_end}
{synopt:{cmdab:dup:licates}} tests for duplicates; default is {hi:no} testing;{p_end}
{synoptline}
{p2colreset}{...}



{marker description}{...}
{title:Description}

{pstd} 
{cmd:resp} is an extended function for {help egen}. It calculates the activity
index or one of its forks for a variable. The activity index is a fraction of
shares, where the first share (the dividend) is the share of {varname} in the sum of all observations
with the same value for {var:1} and the second share (the divisor) is the sum of all observations
with the same value for {var:2} in the sum of all observations.{break}
Symbolically:
{p_end}

{center:{cmd:ai(}{it:x}{cmd:)} = {it:x}/{it:sum}(x|{var:1}) : {it:sum}(x|{var:2})/{it:sum}({it:x})}
{center: with {it:x} uniquely identified by the tuple ({var:1} {var:2}).}

The indices AEOR and RIC are used to messure collaborations in networks and are constructed slightly different:

{center:{cmd:aeor(}{it:x}{cmd:)} = {it:x}/{it:sum}(x|{var:1}) : {it:sum}(x|{var:2})/({it:sum}({it:x}) - {it:sum}(x|{var:1}))}
{center: with {it:x} uniquely identified by the tuple ({var:1} {var:2}).}

{center:{cmd:ric(}{it:x}{cmd:)} = {it:x}/{it:sum}(x|{var:1}) : ({it:sum}(x|{var:2}) - x)/({it:sum}({it:x}) - {it:sum}(x|{var:1}))}
{center: with {it:x} uniquely identified by the tuple ({var:1} {var:2}).}

{marker options}{...}
{title:Options (extended)}

{phang} 
{cmdab:d:im(}{var:1} {var:2}{cmd:)} defines the two dimensions for which the
{hi:Activity Index} is calculated. Therefore, three different sum variables
are calculated temporarily, by {var:1}, by {var:2} and overall.
Afterwards, every observation of {varname} is divided
by the first sum sharing the same value in {var:1}, 
divided by the quotient of the second sum sharing the 
same value in {var:2} as {varname} and the overall sum.
(This holds for the {hi:AI} and its scalings.
Analogue usage of the two dimensions for {hi:AOER} and {hi:RIC}.)
{p_end}

{phang} 
{cmdab:m:ode(}{help strings:string}{cmd:)} controlls the kind of index, which is
retrieved. Possible options for {help strings:string} are 
{cmd:[ai|aoer|ric|rpa|rsi|resp]}. Thereby {cmd:ai} stands for the {hi:Activity Index} (see
above); {cmd:aoer} stands for the {hi:Asymmetric Observed to Expected Ratio} (ibid.);
{cmd:ric} stand for the {hi:Relative Intensity of Collaboration} (ibid.);
{cmd:rpa} is equal to the natural logarithm of the {hi:AI} or {cmd:ln(ai(}{it:x}{cmd:))} and stands for
the {hi:Relative Patent Activity} (see also {help ln}); {cmd:rsi} stands for
the {hi:Relative Specialization Index} defined as {bind:({it:ai} - 1)/({it:ai} + 1)}; and
{cmd:resp} is equal to the hyperbolic tangent of the {hi:RPA} scaled by 100 and stands for
the {hi:Index of Relative Specialization} defined as
{bind:100 * ({it:ai^2} - 1)/({it:ai^2} + 1)}. {cmd:ai} is the default.
{p_end}

{phang} 
{cmdab:dup:licates} tests, if any tuple of {cmd:(}{var:1} {var:2}{cmd:)} is
unique in every group defined by [{help by:{bf:by} {it:varlist}}]. Is this condition
not fullfilled, the program aborts. Because of the aggregation along {var:1},
{var:2} and all observations, the uniqueness of the tuples is not required.
Nevertheless it is often assumed and sensible. The default is to {hi:not} test
on duplicates.
{p_end}

{marker remarks}{...}
{title:Remarks}

{pstd} 
In the second half of the 20th century economists tried to measure comparative
advantages. It was observed, that simple relations could not reveal all 
informations about partitions of ressources. For example, neither the relation
of exported cars from Belgium to all exports of Belgium, nor the relation of 
exported cars from Belgium to all exported cars worldwide gives us a degree
of competitiveness of Belgiums car industry. The first relation is an internal
one. The second one does not consider, that Belgium is not capable of producing
numbers of cars like larger countries.  The
{hi:Activity Index} combines the two relations in the way, that the country
internal relation of exported cars to all exports of a country is compared
to the external relation of exported cars to all exports worldwide. For more
informations about this subject, see {help _gresp##references:the references}
(especially {help _gresp##ref_grupp1994:Grupp 1994}, {help _gresp##ref_grupp1998:Grupp 1998}
and {help _gresp##ref_narin1987:Narin et al. 1987}).
{p_end}

{pstd} 
The {hi:Activity Index (AI)} lacks some essential properties, so some common 
transformations have been established. For statistic calculations the 
{hi:Relative Patent Activity (RPA)} Index has proven to be usefull. It is the
natural logarithm of the {hi:AI} and is motivated by the fact that the values of the {hi:AI} often
follow a log-normal distribution. Both, {hi:AI} and {hi:RPA} are not easy to 
comprehend for a reader as a result of missing bounds on the indexes,
so in presentations or papers two other transformations
are often used instead: the {hi:Relative Specialization Index (RSI)} and the
{hi:Index of Relative Specialization (RESP)} also known as
the {hi:Scientific Specialization Index (SSI)}. The latter is the hyperbolic
tangent of the {hi:RPA} scaled by {it:100}, the former the hyperbolic tangent of
half of the {hi:RPA} without scaling at the end.
{p_end}

{pstd} 
While {hi:RPA}, {hi:RSI} and {hi:RESP} are scalings of {hi:AI} -- all four indexes
can be converted in each other -- {hi:AOER} and {hi:RIC} are folks of the {hi:AI},
but measuring not the importance of a field at a country in comparison to the average
field share, but the importance of the collaboration of two authors/sources for
the second author of this pair in a network in comparison to the importance of
the network for the second author without the first one. For more details on this
subject, see {help _gresp##ref_fuchs2021: Fuchs et al. 2021}.
{p_end}

{marker results}{...}
{title:Stored results}

{pstd} 
{cmd:resp} stores the following in {cmd:r()}:
{p_end}

{synoptset 15 tabbed}{...}
{p2col 5 15 0 0: Macros}{p_end}
{synopt:{cmd:r(cmdline)}}exact command passed to {cmd:egen}{p_end}
{p2colreset}{...}

{marker author}{...}
{title:Author}

{pstd} 
Joel E. H. Fuchs a.k.a Fantastic Cpt. Fox{break}
Organizational Sociology, University of Wuppertal.{break}
jfuchs{cmd:(}at{cmd:)}uni-wuppertal.de
{p_end}

{marker references}{...}
{title:References}

{marker ref_abramo2014}
{pstd}
Abramo, G., D'Angelo, C. A., & Di Costa, F. 2014. 
"A new bibliometric approach to assess the scientific specialization of regions."
Research Evaluation, 23(2), 183-194.
{p_end}

{marker ref_fachprof}{...}
{pstd} 
Chair of Organizational Sociology, 2019.
Research and teaching profiles of public universities in Germany. 2019. URL:
{browse "https://fachprofile.uni-wuppertal.de/en.html":{it:fachprofile.uni-wuppertal.de}}.
{p_end}

{marker ref_fuchs2021}{...}
{pstd}
Fuchs, J.E., Sivertsen, G., Rousseau, R., 2021. 
"Measuring the relative intensity of collaboration within a network"
Scientometrics, Springer Science and Business Media {LLC}. (DOI: 10.1007/s11192-021-04110-x)
{p_end}

{marker ref_grupp1994}{...}
{pstd} 
Grupp, H. 1994. "The Measurement of Technical Performance of Innovations
by Technometrics and Its Impact on Established Technology Indicators."
Research Policy 23, Pp. 175-193.
{p_end}

{marker ref_grupp1998}{...}
{pstd} 
Grupp, H. 1998. "Measurement with Patent and Bibliometric Indicators."
Pp. 141-188 in Foundations of the Economics of Innovation. Theory, Measurement,
Practice, edited by H. Grupp. Cheltenham: Edward Elgar.
{p_end}

{marker ref_heinze2019}{...}
{pstd} 
Heinze, T., Tunger, D., Fuchs, J.E., Jappe, A., Eberhardt, P. 2019.
"Research and teaching profiles of public universities in Germany.
A mapping of selected fields." Wuppertal: BUW. (DOI: 10.25926/9242-ws58).
{p_end}

{marker ref_narin1987}{...}
{pstd} 
Narin, F., Carpenter, M.P. and Woolf, P. 1987.
"Technological Assessments Based on Patents and Patent Citations."
Pp. 107-119 in Problems of Measuring Technological Change,
edited by H. Grupp. Köln: TÜV Rheinland.
{p_end}

{marker ref_piro2011}{...}
{pstd} 
Piro, F.N., Aksnes, D.W, Christensen, K.K., Finnbjörnsson, Þ.,
Fröberg, J., Gunnarsdottir, O., Karlsson, S., Klausen, P.H., Kronman, U., Leino,
Y., Magnusson, M.L., Miettinen, M., Nuutinen, A., Poropudas, O.,
Schneider, J.W. and Sivertsen, G. 2011.
"Comparing Research at Nordic Universities Using Bibliometric Indicators."
Policy Brief 4/2011. Oslo: NordForsk.
{p_end}

{marker ref_piro2014}{...}
{pstd} 
Piro, F.N., Aldberg, H., Finnbjörnsson, P., Gunnarsdottir, O.,
Karlsson, S., Larsen, K.S., Leino, Y., Nuutinen, A., Schneider, J.W.,
and Sivertsen, G. 2014.
"Comparing Research at Nordic Universities Using Bibliometric Indicators
– Second Report, Covering the Years 2000-2012." Policy Paper 2/2014.
Oslo: NordForsk.
{p_end}

{marker ref_piro2017}{...}
{pstd} 
Piro, F.N., Aldberg, H., Aksnes, D.W., Staffan, K.,
Leino, Y., Nuutinen, A., Overballe-Petersen, M.V.,
Sigurdsson, S.O. and Sivertsen, G. 2017.
"Comparing Research at Nordic Higher Education Institutions
Using Bibliometric Indicators Covering the Years 1999-2014."
Policy Paper 4/2017. Oslo: NIFU.
{p_end}

