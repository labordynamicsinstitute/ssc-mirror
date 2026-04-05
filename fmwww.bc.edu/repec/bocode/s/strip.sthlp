{smcl}
{* 5jul2004/28nov2005/24jun2007/26jul2007/26aug2007/8nov2007/30nov2007/27feb2008/7nov2008/22apr2009/2may2009/15may2009/30nov2009/8dec2009/4feb2010/19feb2010/15mar2010/26apr2010/21may2010/2dec2010}{...}
{* 23mar2011/6apr2011/30aug2011/20jul2012/20feb2013/16apr2013/2sept2013/10nov2013/17nov2013/18dec2013/29jan2014/27mar2014/7apr2014/24apr2014/2may2014/14may2014/21may2014/13jun2014/14aug2014/4sep2014/23sep2014/6oct2014/21oct2014/9dec2014}{...}
{* 2jan2015/30mar2015/4may2015/25may2015/9jul2015/4sep2015/15oct2015/14dec2015/26jan2016/22mar2016/9may2016/9aug2016/18aug2016/31oct2016/20dec2016/22feb2017/24feb2017/2mar2017/8mar2017/21mar2017/26mar2017/4apr2017/13apr2017/13jun2017}{...}
{* 12jul2017/25sep2017/18oct2017/14nov2017/21dec2017/24feb2018/26mar2018/2may2018/11may2018/14may2018/10jun2018/4jul2018/30jul2018/8aug2018/22aug2018/25sep2018/3oct2018/15oct2018/22oct2018/15nov2018/3dec2018/11dec2018/13dec2018}{...}
{* 8jan2019/22feb2019/13mar2019/23apr2019/19may2019/12jun2019/24jun2019/12jul2019/17jul2019/29jul2019/9aug2019/25sep2019/7oct2019/14oct2019/31oct2019/13dec2019/23dec2019/21jan2020/20feb2020/10mar2020/19jun2020/28jun2020/11oct2020}{...}
{* 19nov2020/5dec2020/19dec2020/4jan2021/8feb2021/27feb2021/9apr2021/13jun2021/22jun2021/10jul2021/16jul2021/28jul2021/5aug2021/3sep2021/13sep2021/11oct2021/3dec2021/18jan2022/31ja/n2022/28feb2022/17mar2022/27apr2022/29jun2022/6aug2022}{...}
{* 3sep2022/12nov2022/6dec2022/18dec2022/16jan2023/8feb2023/2mar2023/10mar2023/14mar2023/31mar2023/5apr2023/19apr2023/13may2023/6jun2023/16jun2023/3aug2023/17sep2023/1oct2023/10dec2023/11dec2023/19dec2023}{...}
{* 5jan2024/28jan2024/17feb2024/10mar2024/15mar2024/21mar2024/3apr2024/11apr2024/19may2024/7jun2024/9jul2024/2aug2024/27aug2024/3sep2024/17sep2024/7oct2024/10oct2024/26oct2024/31oct2024/4nov2024/15nov2024/20nov2024/25nov2024}{...}
{* 3dec2024/14dec2024/22dec2024/17jan2025/14mar2025/25mar2025/28apr2025/21may2025/15jun2025/10jul2025/12jul2025/17jul2025/3aug2025/13aug2025/18aug2025/1sep2025/29oct2025/26nov2025/10dec2025/8jan2026/11feb2026/12mar2026}{...}
{* strip 4apr2026}{...}
{hline}
help for {hi:strip}
{hline}

{title:Strip plots: oneway dot plots}

{p 8 17 2}
{cmd:strip}
{it:varlist} 
[{cmd:if} {it:exp}] 
[{cmd:in} {it:range}] 

{p 12 17 2} 
[ 
{cmd:,}
{cmdab:vertical} 
{c -(}
{cmdab:stack}
{c |}
{cmdab:quantile} 
{cmdab:trscale(}{it:trans}{cmd:)} 
{c )-}
{cmdab:height(}{it:#}{cmd:)}
{c -(} 
{cmdab:centre}
{c |} 
{cmdab:center}
{c )-} 

{p 12 17 2} 
{cmdab:width(}{it:#}{cmd:)}
{c -(}
{cmd:floor}
{c |}
{cmdab:ceiling} 
{c )-}

{p 12 17 2} 
{cmdab:separate(}{it:varname}{cmd:)} {cmd:variablelabels} 

{p 12 17 2} 
{cmd:addplot(}{it:plot}{cmd:)}
{it:graph_options} ]


{p 8 17 2}
{cmd:strip}
{it:varname} 
[{cmd:if} {it:exp}] 
[{cmd:in} {it:range}] 

{p 12 17 2} 
[ 
{cmd:,}
{cmdab:vertical} 
{c -(}
{cmdab:stack}
{c |}
{cmdab:quantile} 
{c )-}
{cmdab:height(}{it:#}{cmd:)}
{c -(} 
{cmdab:centre}
{c |} 
{cmdab:center}
{c )-}

{p 12 17 2} 
{cmdab:width(}{it:#}{cmd:)} 
{c -(}
{cmd:floor}
{c |}
{cmdab:ceiling} 
{c )-}

{p 12 17 2} 
{cmdab:over(}{it:groupvar}{cmd:)}
{cmdab:separate(}{it:varname}{cmd:)} 

{p 12 17 2} 
{cmd:addplot(}{it:plot}{cmd:)} 
{it:graph_options} 
]


{title:Description}

{p 4 4 2}
{cmd:strip} plots data as a series of marks against a single magnitude
axis. By default this axis is horizontal. With the option {cmd:vertical}
it is vertical.  Optionally, data points may be stacked or cumulated
into histogram- or {cmd:dotplot}-like or distribution or quantile
function displays.    

{p 4 4 2}
The default results of {cmd:strip} are fairly trivial, as if you had 
called up a scatter plot of a variable of interest and a variable 
created as some constant. The power of the command lies in its options.
To that end, run the examples: the code for the examples is included 
in a do-file alongside this help file and the ado file. 


{title:Options}

{it:General appearance}

{p 4 8 2}
{cmd:vertical} specifies that the magnitude axis should be vertical. 

{p 4 8 2}
{cmd:stack} specifies that data points with identical values are to be
stacked, as in {cmd:dotplot}, except that by default there is no binning
of data.

{p 4 8 2}
{cmd:quantile} specifies that data points are to be plotted with 
respect to an implicit cumulative probability scale. 
By default displays resemble cumulative distribution plots; otherwise with 
{cmd:vertical} displays resemble quantile plots. Note that with
{cmd:quantile} specifying {cmd:connect(L)} [sic] to join points within groups
may be helpful. 

{p 4 8 2}
Given {cmd:quantile}, the further option {cmd:trscale()} specifies use
of a transformed scale for cumulative probability. The argument
{it:trans} is Stata syntax specifying the transformation. For example,
{cmd:trscale(invnormal(@))} specifies a normal quantile scale. Here
{cmd:@}, which must be specified, is a placeholder for the name of the
temporary variable holding cumulative probability. Otherwise, the syntax
must mention one or more Stata functions and may mention pertinent
operators or numeric constants. Note that calculations are separate for
each variable and group plotted and that for graphical purposes, each
transformed set is transformed back to the interval [0, 1].

{p 8 8 2}
{cmd:stack} and {cmd:quantile} may not be combined. 

{p 4 8 2}
{cmd:height(}{it:#}{cmd:)} controls the amount of graph space taken up
by stacked data points under the {cmd:stack} or {cmd:quantile} options
above. The default is 0.8.  This option will not by itself change the
appearance of a plot for a single variable. Note that the height may
need to be much smaller or much larger than 1 with {cmd:over()}, given
that the latter takes values literally. For example, if your classes are
0(45)360, 36 might be a suitable height. 

{p 4 8 2}
{cmd:centre} or {cmd:center} centres or centers markers for each
variable or group on a hidden line.

{it:Binning} 

{p 4 8 2}
{cmd:width(}{it:#}{cmd:)} specifies that values are to be rounded in
classes of specified width. Classes are defined by default by
{cmd:round(}{it:varname}{cmd:,}{it:width}{cmd:)}. See also the
{cmd:floor} and {cmd:ceiling} options just below. 

{p 8 8 2}
{cmd:floor} or {cmd:ceiling} in conjunction with {cmd:width()} specifies
rounding by {it:width} {cmd:* floor(}{it:varname/width}{cmd:)} or
{it:width} {cmd:* ceil(}{it:varname/width}{cmd:)} respectively. Only one
may be specified. (These options are included to give some users the
minute control they may desire, but if either option produces a marked
difference in your plot, you may be rounding too much.)  

{it:Grouping} 

{p 4 8 2}
{cmd:over(}{it:groupvar}{cmd:)} specifies that values of {it:varname}
are to be shown separately by groups defined by {it:groupvar}. This
option may only be specified with a single variable.  If {cmd:stack} is
also specified, then note that distinct values of any numeric
{it:groupvar} are assumed to differ by at least 1. Tuning {cmd:height()}
or the prior use of {cmd:egen, group() label} will fix any problems. See
help on {help egen} if desired. 

{p 8 8 2}
Note that {cmd:by()} is also available as an alternative or complement
to {cmd:over()}. See the examples for detail on how {cmd:over()} and
{cmd:by()} could be used to show data subdivided by a cross-combination
of categories. 

{p 4 8 2}
{cmd:separate()} specifies that data points be shown separately
according to the distinct classes of the variable specified. Commonly,
but not necessarily, this option will be specified together with
{cmd:stack} or {cmd:quantile}.  

{it:Other details} 

{p 4 8 2}
{cmd:variablelabels} specifies that multiple variables be
labelled by their variable labels. The default is to use variable names. 

{p 4 8 2}
{cmd:addplot(}{it:plot}{cmd:)} provides a way to add other
plots to the generated graph; see help {help addplot_option}. 

{p 4 8 2}
{it:graph_options} are options of {help scatter}, including {cmd:by()},
on which see {help by_option}.  

{p 8 8 2}
{cmd:jitter()} is among those options, but (personal opinion) jittering 
is only rarely as helpful as stacking or cumulating as a way to show 
identical or close values clearly.  


{title:Remarks}

{it:Meta-remarks}

{p 4 4 2}
The very large list of references here has just grown over several years
from a much shorter set of more usual length. A rationale for its
length, beyond the amusement of the program author, might include:
providing overwhelming evidence of how long and how widely these plots
have been invented, or re-invented; documenting explicitly the variety
of plot forms (and the variety of plot names) in more detail than in
other sources; maximising the scope for people to find congenial
references in literature accessible to them; challenging people to
suggest other earlier and/or excellent examples.  Equally, there is here
neither intent nor claim to produce a comprehensive list.  

{p 4 4 2}
The need for and utility of the plots produced by this command may vary with 
the number of variables shown (1 or more); 
the number of groups shown (1 or more); 
and the number of observations in each group for each variable. 
However, such dependence is in my view weaker than is often stated.  At
one extreme, with a few variables or groups and small samples, you
should have space to show all data points directly. At another extreme,
many data points often blur into each other, but that doesn't make strip
plots useless, if only because marked outliers, gaps, spikes and so
forth are likely to be evident when they are present. With large
samples, cumulative or quantile versions of strip plots are likely to be
especially helpful.

{p 4 4 2}
There is not a sharp distinction in the literature or in software
implementations between {it:dot plots} and {it:strip plots}.  Commonly,
but with many exceptions, a dot plot is drawn as a pointillist analogue
of a histogram. Sometimes, dot plot is used as the name when data points
are plotted in a line, or at most a narrow strip, against a magnitude
axis. Strip plot implementations, as here, usually allow stacking
options, so that dot plots may be drawn as one choice. 

{it:Early history}

{p 4 4 2}
Such plots under these and yet other names go back at least as far as
Langren (1644): see Tufte (1997, p.15) and in much more detail Friendly
{it:et al.} (2010) and Friendly and Wainer (2021).  

{p 4 4 2}
Galton (1869, pp.27{c -}28; 1892, pp.27{c -}28) gave a schematic dot
diagram showing how the heights of a million men might be plotted.  G.H.
Darwin (1873) invoked the same idea: "If one were to draw a vertical
line on a wall, and were to measure the heights of several thousand men
of the same race against this line, recording the height of each by
driving in a pin, the pins would be densely clustered about a certain
height, and the density of their distribution would diminish above and
below." (I owe the Darwin reference to Pritchard (2018). It is not
included in, or even cited within, the 5 volumes of (Sir George)
Darwin's {it:Scientific Papers}.)

{p 4 4 2} 
Jevons (1884), Wallace (1889), Bateson and Brindley (1892), Bateson
(1894), Brunt (1917, 1931), Gause (1930), Shewhart (1931, 1939), Pearson
(1931, 1938), Pearson and Chandra Sekhar (1936), Shaw (1936), Brinton
(1939), Tippett (1943) and Zipf (1949) are other early sources.  Pearson
(1939) shows evidence of private use by Student [W.S. Gosset].  C.B.
Williams often used such diagrams in his papers (e.g.  1940, 1944) and
books (1964, 1970).

{p 4 4 2}
In his now famous paper introducing the {it:Iris} data to statistical
science, Fisher (1936) gave a histogram in which each value is
represented by a rectangle of constant area, hence using essentially the
same principle.  The same idea was used by Karsten (1923, p.348), McCall
(1939, p.488), Svendsen (1940), on which see Murphy (1997, p.341), Dixon
and Massey (1951, 1957, 1969, 1983), Eddy (1979), Murphy (1985, p.61)
and Wilks (2006, 2011, 2019, p.34 in all editions).

{it:General discussions} 

{p 4 4 2}
Sasieni and Royston (1996) and Wilkinson (1999a) give general
discussions: see Sasieni and Royston (1994) for the first Stata
implementation. 

{it:Dot diagram can mean scatter plot!} 

{p 4 4 2}
Fisher (1925 and later editions) used {it:dot diagram} in the sense of
scatter plot, as did Draper and Smith (1966). Similarly the term 
{it:dot plot} is sometimes used that way (Yau 2011, 202, 2024; Desbarats 2023a). 

{it:Examples and variations of dot and strip plots} 

{p 4 4 2}
Wilks (1948), Hald (1952) and Box {it:et al.} (1978) used the term
{it:dot frequency diagram} or {it:dot diagram}, as did Rowntree (1981),
Berry and Lindgren (1990, 1996), Bajpai {it:et al.} (1992), Harris
(1999), Armitage {it:et al.} (2002), Bl{c ae}sild and Granfeldt (2003),
Bartholomew (2016), Naghettini (2016) and Bianconi (2024).  Monkhouse
and Wilkinson (1952) used the term {it:dispersion diagram}, as did
McGrew and Monroe (1993, 2000) and Morrocco and Ballantyne (2008); the
term is also used for box plot-like displays (e.g. Hogg 1948; Ottaway
1973).  Miller (1953, 1964) used the terms {it:dispersion graph} and
{it:dispersion diagram}.  Truran (1975), Silk (1979), White (1984) and
Slocum {it:et al.} (2010) used the term {it:dispersion graph} for
stacked dotplots.  Pearson (1956) gives several examples.  Dickinson
(1963) used the term {it:dispersal graph}.  Tukey (1974) used the term
{it:dot pattern}.  Tukey (1977, p.50) showed a dot plot for an example
in which a box plot works poorly. See also examples in Tukey (1970a,
1970b) and Mosteller and Tukey (1977, p.456).  Harris (1999) used the
term {it:dot array chart}.  Kendall (1971), Kleiner and Graedel (1980),
Chambers {it:et al.} (1983), Becker and Chambers (1984), Becker 
{it:et al.} (1988), Fox (1990), Thompson (1992), Cleveland (1994), Lee and Tu
(1997), Wilkinson (1999b, 2005), Reimann {it:et al.} (2008) and
Rousselet {it:et al.} (2017) used the term {it:one-dimensional plot} or
{it:one-dimensional scatter plot}.  H{c a:}rdle (1991) used the term
{it:needle plot}.  Wennberg and Cooper (1996) used the term
{it:distribution graph}.  Jacoby (1997) used the term 
{it:univariate scatter plot}, as did Edwards (2000), Weissgerber {it:et al.} (2015),
Kirk (2016), Filzmoser {it:et al.} (2018) and Humphreys and Ruxton
(2022).  Jacoby also used the term {it:unidimensional scatter plot}.
Gerbing (2020) used the term {it:one-variable scatterplot}.  Harris
(1999) used {it:one-axis} and {it:one-dimensional} terms such as
one-axis data distribution, percentile, point and scatter graphs and
one-dimensional data distribution graphs.  Woloshin (2000) used the term
{it:turnip graphs}, attributing it to J.E. Wennberg.  Ryan {it:et al.}
(1985) discuss their Minitab implementation using the term {it:dotplot}.
Note also later editions such as Ryan {it:et al.} (2013).  Krieg 
{it:et al.} (1988), Velleman (1989), Staudte and Sheather (1990), Hoaglin
{it:et al.} (1991), Gonick and Smith (1993), Swan and Sandilands (1995),
Wilkinson (1992, 1999b, 2005) Wild and Seber (2000), Utts and Heckard
(2002), Dodge (2008), Burt {it:et al.} (2009), Ryan (2009), Wilcox
(2009), Doane and Seward (2011),  Janert (2011), Peacock and Peacock
(2011), Cook {it:et al.} (2016), Rousselet {it:et al.} (2017); Albert
(2018), Weissgerber {it:et al.} (2019), Wilks (2019), De Veaux 
{it:et al.} (2021), Diez {it:et al.} (2022), Correll (2023) and Unwin (2024)
are among many others also using the term {it: dot plot} or
{it:dotplot}.  Yandell (2007), Thas (2010), Janert (2011), Sleeper
(2018, 2020), Wexler (2021) and Desbarats (2023b) used the terms
{it:jittered plots} or {it:jitter plot} or {it:jittered strip plot} for
jittered versions.  Cumming (2012) used {it:dotplot} for unstacked and
{it:dot histogram} for stacked plots.  The latter term also appears in
Wright and London (2009),  Koponen and Hild{c e'}n (2019), Schwabish
(2021), Butler (2022) and Wilkinson (2023).  McGrew {it:et al.} (2014)
and Lembo and McGrew (2024) used {it:individual value plot} and
{it:individual point distribution}. Atkinson (1985), Stuetzle (1987),
Madansky (1988), Thi{c e'}baux (1994), Draper and Smith (1998) and Goos
and Meintrup (2015, 2016) used {it:histogram}.  Wexler {it:et al.}
(2017) and Sleeper (2020) used {it:unit histogram}.  Bradstreet (2012),
Rice and Lumley (2016) and Cairo (2019) used {it:dot chart}.  Cleveland
(1985) used the term {it:point graph}, as did Harris (1999) and Slocum
{it:et al.} (2010).  Computing Resource Center (1985) and Hamilton
(1992) used the terms {it:oneway plot} and {it:oneway scatterplot}.
Pagano and Gauvreau (1993) used the term {it:one-way scatter plot}.
Feinstein (2002, pp.67, 167) used the term {it:one-way graph}.  The term
{it:line plot} appears in Hill and Dixon (1982), Cooper and Weekes
(1983), Benjamini (1988), Klemel{c a:} (2009), Christensen {it:et al.}
(2011) and Schuenemeyer and Drew (2011), that of {it:line chart} appears
in Robertson (1988), and that of {it:linear plot} appears in Hay (1996).
The term {it:strip plot} (or {it:strip chart}) (e.g.  Millard 1998,
2013; Millard and Neerchal 2001; Dalgaard 2002; Venables and Ripley
2002; Maindonald and Braun 2003; Robbins 2005; Faraway 2005, 2014;
Sarkar 2008; Sawitzki 2009; Thas 2010; Harris and Jarvis 2011; Few 2009,
2012, 2015, 2020; Cairo 2013, 2016; Cam{c o~}es 2016; Friendly and Meyer
2016;   Harris 2016; Hilfiger 2016; Rousselet {it:et al.} 2016, 2017;
Carlson 2017; Spiegelhalter 2019; Afifi {it:et al.} 2020; Schwabish
2021, 2023; Wexler 2021; Humphreys and Ruxton 2022; Correll 2023;
Desbarats 2023b; Bianconi 2024) appears traceable to work by J.W. and
P.A. Tukey (1990).  The term {it:dot strip plot} appears in Smith
(2022).  The term {it:blob chart} appears in Adams (1992).  The term
{it:dit plot} appears in Ellison (1993, 2001) and Wilkinson {it:et al.}
(1996).  The terms {it:number line}, {it:number-line plot} and
{it:number axis} appear in Helsel and Hirsch (1992), McGrew and Monroe
(1993, 2000), Monmonier (1991, 1993), Dent (1996), Harris (1999) and
Wolfram (2017).  The term {it:bar-dot graph} appears in Wilkinson 
{it:et al.} (1996) for a dot plot superimposed on bars showing means.  People
in neuroscience often plot event times for multiple trials as 
{it:raster plots}: Brillinger and Villa (1997) is a token reference from the
statistical literature. See Kass {it:et al.} (2014) for more.  The term
{it:stripe graph} appears in Harris (1999).  The term {it:stripes plot}
or {it:stripe plot} appears in Wilkinson (1994, 2023), Leisch (2010) and
Everitt and Skrondal (2010).  Doane and Tracy (2000) combined dotplots,
a beam to indicate data range and a fulcrum to indicate mean as centre
of gravity, as one kind of {it:beam and fulcrum display}.  The term
{it:data distribution graph} appears in Robbins (2005).  The term
{it:column scatter graph or plot} for vertical strip plots appears in
Motulsky (1995, 2010, 2014, 2018) and in Girgis and Mohanty (2012).  The
term {it:barcode plot} or {it:bar code plot} or {it:barcode chart}
appears in Keen (2010, 2018), Thas (2010), Kirk (2012) and Smith (2022).
The term {it:circle plot} appears in McDaniel and McDaniel (2012a,
2012b).  The term {it:Wilkinson dot plot} appears in Chang (2013, 2019),
Koponen and Hild{c e'}n (2019), Sleeper (2020), Schwabish (2021) and
Wexler (2021).  The term {it:swarm} or {it:beeswarm plot} appears in
Eklund (2013), Martinez {it:et al.} (2017), Andrews (2019), Holmes and
Huber (2019), Koponen and Hild{c e'}n (2019), Field (2021), Schwabish
(2021), Smith (2022), Bianconi (2024), Doggett and Way (2024), Yau
(2024) and Kirk (2025).  The term {it:instance chart} appears in Kirk
(2016).  The term {it:wheat plot} appears in Few (2017) and Schwabish
(2021).  The term {it:SinaPlot} appears in Sidiropoulos {it:et al.}
(2018) for a hybrid of violin plot and strip chart.  The term
{it:raincloud plot} appears in Allen {it:et al.} (2019) and Schwabish
(2021) for a hybrid of strip chart, box plot and violin plot and in
Schwabish (2023) for a hybrid of strip chart and box plot with whiskers
to 10% and 90% points. Correll (2023) documents and discusses numerous
variants appearing under that name.  The term {it:spread-plot} appears
in Vail and Wilkinson (2020).  The term {it:SuperPlots} was used by Lord
{it:et al.} (2020) for displays showing two kinds of replication.
Stacked dot and strip plots appear to qualify as one kind of
{it:gatherplot} (Park {it:et al.} 2023). 

{p 4 4 2}
Wigglesworth (1954), Moroney (1956), Wallis and Roberts (1956, p.178),
Clement and Robertson (1961), Youden (1962), Gregory (1963),  Haggett
(1965, 1972), Draper and Smith (1966), Cole and King (1968), Cormack
(1971), Koch and Link (1971), Moore (1971), Williamson (1972), Davis
(1973, 1986, 2002), Agterberg (1974), Hammond and McCullagh (1974),
Tufte (1974, 2020), Lehmann (1975, 1998), Lewis (1977), Wright (1977),
Barnett and Lewis (1978), Johnston (1978), Mardia {it:et al.} (1979),
Murphy (1979, 1982), Smith (1979), Brown and Hu (1980), Bertin (1981,
1983), Green (1981),  Wetherill (1981, 1982), Dobson (1983 and later),
Bentley and Kernighan (1984), Light and Pillemer (1984), Mosteller and
Wallace (1984), Bentley (1985, 1988), Aitchison (1986), Clark and
Hosking (1986), Colinvaux (1986, 1993), Ibrekk and Morgan (1987), Jones
and Moon (1987), Chatfield (1988), Flury and Riedwyl (1988), Siegel
(1988), Sprent (1988), Hald (1990), Morgan and Henrion (1990),
Hutchinson (1993), Baxter (1994),  Kent and Coker (1994), Daly 
{it:et al.} (1995), Guttorp (1995),  Henry (1995), Jongman {it:et al.} (1995),
Berry (1996), Cliff (1996). McNeil (1996), Siegel and Morgan (1996),
Behrens (1997), Flury (1997), Yandell (1997), Cobb (1998), Griffiths
{it:et al.} (1998), Bland (2000), Nolan and Speed (2000), Manly (2001),
Spence (2001, 2007, 2014), Dupont (2002), Field (2003, 2010, 2016), Good
and Hardin (2003), Mead, Curnow and Hasted (2003), Barnett (2004),
Heiberger and Holland (2004, 2015),  van Belle {it:et al.} (2004),
Wasserman (2004), Robbins (2005), Hammer and Harper (2006, 2024),
Maronna {it:et al.} (2006, 2019), Young {it:et al.} (2006), Agresti and
Franklin (2007), Cook and Swayne (2007), Morgenthaler (2007), Freeman
{it:et al.} (2008), Urbanek (2008), Warton (2008, 2022), Yamamoto 
{it:et al.} (2008), Schneider (2009), Theus and Urbanek (2009), Wainer (2009,
2016), Whitlock and Schluter (2009, 2015, 2020), Andersen and Skovgaard
(2010), Keen (2010, 2018), Zar (2010), Drummond and Vowler (2011), Kent
(2012), Sokal and Rohlf (2012), Wills (2012), Greenacre and Primicerio
(2013),  Ramsey and Schafer (2013), Yau (2013, 2024), Amaratunga 
{it:et al.} (2014), Hector (2015, 2021), Berinato (2016; who also uses the term
in another sense: p.30), Goos and Meintrup (2016), Greenacre (2016),
Irizarry and Love (2017), Wolfe and Schneider (2017), Agresti (2018),
Kriebel and Murray (2018),  Pearson (2018), Standage (2018, 2019, 2020),
Greenacre (2019), Grant (2019), Healy (2019),  Koponen and Hild{c e'}n
(2019), Selvin (2019), Irizarry (2020, 2025), Mudelsee (2020) Vanderplas
{it:et al.} (2020), DelSole and Tippett (2022), Alexander (2023),
Kabacoff (2024), Yu and Barter (2024) and Kirk (2025) are some other
references with examples of strip plots. 

{p 4 4 2}
The Federal Reserve publishes predictions of interest rates using dot
plots.  See for illustration and discussion (e.g.) the Economist (2015). 

{it:Compare stem-and-leaf plots} 

{p 4 4 2} 
Siegel (1988) gives an especially lucid discussion of stem-and-leaf
plots presented to maximise their resemblance to both histograms and
strip plots (in the present sense).  His first edition is preferable on
this point to the second edition, Siegel and Morgan (1996). Other lucid
explanations were given by Berry (1996) and Berry and Lindgren (1996).   

{it:Rugs} 

{p 4 4 2}
Strip plot-like displays on the margins of other graphs (e.g.
histograms, density plots, scatter plots) are now often known as
{it:rugs} or {it:rug plots}, although their use predates this term. See
(e.g.) Brunt (1917, 1931), Wallis and Roberts (1956, p.178),  Boneva
{it:et al.} (1971), Binford (1972), Box and Tiao (1973),  Davis (1973,
1986, 2002), Daniel (1976), Lewis (1977),  Brier and Fienberg (1980),
Brown and Hu (1980), Tukey and Tukey (1981), Chambers {it:et al.}
(1983), Tufte (1983, 2006, 2020), Bentley and Kernighan (1984), Murphy
(1985, p.61), Aitchison (1986), Hastie and Tibshirani (1986), Rousseeuw
and Leroy (1987), Fox (1990), Berry and Lindgren (1990, 1996), Hastie
and Tibshirani (1990) (who do use the term), H{c a:}rdle (1990, 1991),
Hastie (1992), Clark and Pregibon (1992), Scott (1992, 2015), Cleveland
(1993), Pitman (1993), Jongman {it:et al.} (1995), Wand and Jones
(1995),  Wilks (1995, 2006, 2011, 2019), Fan and Gijbels (1996), Gasser
(1996), Ripley (1996), Simonoff (1996, 2003), Bowman and Azzalini
(1997), Flury (1997), Reiss and Thomas (1997, 2001, 2007), Millard
(1998), Gershenfeld (1999), Harris (1999) (who uses the term 
{it:border plot}), Johnson and Albert (1999), Friendly (2000), Schimek (2000), Utts
and Heckard (2002), Baxter (2003), Good and Hardin (2003), Barnett
(2004), Jewell (2004), Wasserman (2004, 2006), Aitkin {it:et al.} (2005,
2009), Gelman and Hill (2007), Bolker (2008), Bowman (2008), Friendly
(2008), H{c a:}rdle {it:et al.} (2008), Minnotte {it:et al.} (2008),
Sarkar (2008), Hastie {it:et al.} (2009), Sawitzki (2009), Sheather
(2009), Barnett and Dobson (2010), Everitt and Skrondal (2010), Keen
(2010, 2018), Maindonald and Braun (2010), Christensen {it:et al.}
(2011), Everitt {it:et al.} (2011), Gower {it:et al.} (2011), Harris and
Jarvis (2011), Matthiopoulos (2011), Schuenemeyer and Drew (2011),
Feigelson and Babu (2012), Lee (2012), Legendre and Legendre (2012),
Weigel (2012),  Chang (2013, 2019), Fahrmeir {it:et al.} (2013),
Greenacre and Primicerio (2013),  James {it:et al.} (2013), Faraway
(2014), Perpi{c n~}{c a'}n Lamigueiro (2014, 2018), Harrell (2015),
Heiberger and Holland (2015), Efron and Hastie (2016), Friendly and
Meyer (2016), Harris (2016),  Carlson (2017), Martinez {it:et al.}
(2017), Wood (2017), Albert (2018), Field (2018),  Bouveyron {it:et al.}
(2019), Koponen and Hild{c e'}n (2019), Racine (2019),  Irizarry (2020,
2025), Gerbing (2020), Friendly and Wainer (2021), Setlur and Cogley
(2022), Shen and North (2023), Wimberly (2023), Kabacoff (2024),
Maindonald {it:et al.} (2024) and Yu and Barter (2024).  See Cox (2025)
for a miniature review of adding rugs in Stata.  Tufte (1983, p.135)
uses the term differently, for a series of plots linked together using
their marginal distributions.

{it:Hybrid dot-box plots}

{p 4 4 2}
Hybrid dot-box or box-dot plots were used by Crowe (1933, 1936, 1971)
(on whose work see Johnston 2019),  Matthews (1936), Hogg (1948),
Monkhouse and Wilkinson (1952), Farmer (1956), Gregory (1963), Hammond
and McCullagh (1974), Lewis (1975), Matthews (1981), Wilkinson (1992,
1994, 1999b, 2005, 2023),  Ellison (1993, 2001), McGrew and Monroe
(1993, 2000),  Wilkinson {it:et al.} (1996) (who also call them dox
plots), Curry (1999), Harris (1999), Wild and Seber (2000), Quinn and
Keough (2002, 2024), Young {it:et al.} (2006), Hendry and Nielsen
(2007), Morrocco and Ballantyne (2008), Motulsky (2010, 2014, 2018),
Christensen {it:et al.} (2011), Krause and O'Connell (2012),  Chang
(2013, 2019), Davino {it:et al.} (2014), McGrew {it:et al.} (2014), Goos
and Meintrup (2015), Friendly and Meyer (2016), Gierlinski (2016),
Greenacre (2017), Irizarry and Love (2017),  Wexler {it:et al.} (2017),
Chiou and Bergey (2018), Keen (2018), Kriebel and Murray (2018), Sleeper
(2018) (whose explanation is singularly confused), Holmes and Huber
(2019), Weissgerber {it:et al.} (2019), Irizarry (2020, 2025), Gerbing
(2020), Wexler (2021), Diez {it:et al.} (2022), Alexander (2023),
Bianconi (2024), Kabacoff (2024), Maindonald {it:et al.} (2024), Unwin
(2024), Yu and Barter (2024) and Desbarats (2025).  See also Miller
(1953, 1964).

{it:Boxplots} 

{p 4 4 2}
Boxplots in widely current forms are best known through the work of
Tukey (1970a, 1970b, 1972, 1977).  Various mutations were suggested or
documented by McGill {it:et al.} (1978),  Frigge {it:et al.} (1989),
Potter (2006) (ranging from elementary confusions to some original
suggestions), Keen (2010, 2018) and Martinez {it:et al.} (2011).
Drawing whiskers to particular percentiles, rather than to data points
within so many IQR of the quartiles, was emphasised by Cleveland (1985),
but anticipated by Matthews (1936) and Grove (1956) who plotted the
interoctile range, meaning between the first and seventh octiles, as
well as the range and interquartile range.  Dury (1963), Johnson (1975),
Cressie (1991), Pagano and Gauvreau (1993), Harris (1999), Feinstein
(2002), Utts and Heckard (2002), Bl{c ae}sild and Granfeldt (2003), Good
and Hardin (2003), Myatt (2007), Lane and S{c a'}ndor (2009), Myatt and
Johnson (2009, 2011), Draghici (2012), Davino {it:et al.} (2014), Chang
(2013, 2019), McGrew {it:et al.} (2014), Goos and Meintrup (2015, 2016),
Wickham and Grolemund (2017), Agresti (2018), Afifi {it:et al.} (2020)
and Lembo and McGrew (2024) showed means as well as minimum, quartiles,
median and maximum.  Schmid (1954) showed summary graphs with median,
quartiles and 5 and 95% points. Schmid and Schmid (1979) used 10% and
90% points instead.  Bentley (1985, 1988), Davis (2002), Spence (2007,
2014), Few (2009),  Motulsky (2010, 2014, 2018), Gierlinski (2016) and
Smith (2022) plotted whiskers to 5 and 95% points.  Crowe (1971, 
pp.70{c -}71) plotted median, quartiles and 10% and 90% points on the margins of
histograms.  Moore and McCabe (1989, suggestion on p.35),  Morgan and
Henrion (1990, pp.221, 241), Helsel and Hirsch (1992, p.26) Dent (1996,
p.3), Fauth and Resetarits (1999), Spence (2001, p.36),  Gotelli and
Ellison (2004, 2013, pp.72, 110, 213, 416),  Wilks (2011, p.280; 2019,
p.365) and Schwabish (2021, p.198; 2023, p.313) plotted whiskers to 10%
and 90% points, as was also mentioned by Ramsey and Schafer (2013,
p.19). See also Feinstein (2002, p.308).  Harris (1999) showed examples
of both 5 and 95% and 10 and 90% points.  Altman (1991, pp.34, 63),
Feinstein (2002, p.301) and Greenacre (2016) plotted whiskers to 2.5%
and 97.5% points.  Reimann {it:et al.} (2008, pp.46{c -}47) plotted
whiskers to 5% and 95% and 2% and 98% points.  Humphreys and Ruxton
(2022, p.80) mention use elsewhere of 2% and 98% and 9% and 91% points. 

{it:Quartile or midgap plots} 

{p 4 4 2}
A variant design was called a {it:quartile plot} by Tufte (1983, p.124f;
2001, p.124f; 1990a, p.62; 1990b, p.131f) and Wright and London (2009)
and a {it:midgap plot} by Seheult (1986) and Stock and Behrens (1991).
It consists of a point symbol for the median, no visible box, and
whiskers between each quartile and the extreme beyond. See also
Wilkinson {it:et al.} (1996, p.742), Tufte (2020, p.100) and Quinn and
Keough (2024, p.348).

{it:Quantile-box plots and their kin} 

{p 4 4 2}
Parzen (1979a, 1979b, 1982, 1997) hybridised box and quantile plots as
quantile-box plots. See also (e.g.) Shera (1991), Militk{c y'} and
Meloun (1993), Meloun and Militk{c y'} (1994),  Nair {it:et al.} (2013),
Evans and Cox (2017) and Cox (2020).  Shelly (1996), Guevara and 
Avil{c e'} (2007), Feigelson and Babu (2012, p.208) and Holmes and Huber (2019,
p.129) plotted quantile plots and box plots side by side.  Note,
however, that the quantile box plot of Keen (2010, 2018) is just a box
plot with whiskers extending to the extremes.  In contrast, the quantile
box plots of JMP are evidently box plots with marks at 0.5%, 2.5%, 10%,
90%, 97.5%, 99.5%: see Sall {it:et al.} (2014, pp.143{c -}4).  

{p 4 4 2}
Here are some notes on variants of quantile-box plots.  (A) The
box-percentile plot of Esty and Banfield (2003) plots the same
information differently, plotting data as continuous lines and producing
a symmetric display in which the vertical axis shows quantiles and the
horizontal axis shows not plotting position {it:p}, but both
{bind:min({it:p}, 1 - {it:p})} and its mirror image 
{bind:-min({it:p}, 1 - {it:p})}. Minor detail: in their paper plotting positions are
  misdescribed as "percentiles". See also Martinez {it:et al.} (2011,
2017), which perpetuates that confusion. 

{p 4 4 2}
The idea of plotting {bind:min({it:p}, 1 - {it:p})} (or  its percent
equivalent) appears independently in (B) "mountain plots"  (Krouwer
1992; Monti 1995; Krouwer and Monti 1995; Goldstein 1996) and in (C)
plots of the "flipped empirical distribution function" (Huh 1995).  See
also Xue and Titterington (2011) for a detailed analysis of folding a
distribution function at any quantile.  From literature seen by me, it
seems that none of these threads -- quantile-box plots or the later
variants (A) (B) (C) -- cites each other.  Note that the mountain plot
of Urbanek (2008) is a different idea. 

{it:Precursors of box plots} 

{p 4 4 2}
Ideas similar to box plots go back much further.  Cox (2009) gives
various references. Bibby (1986, pp.56, 59) gave even earlier references
to their use by A.L. Bowley in his lectures about 1897 and to his
recommendation (Bowley, 1910, p.62; 1952, p.73) to use minimum and
maximum and 10, 25, 50, 75 and 90% points as a basis for graphical
summary. Range-bar plots as in Spear (1952, 1969) are often cited, but
see also the earlier work of Haemer (1948) and the slightly later work
of Schmid (1954). 

{it:Deviations from means} 

{p 4 4 2}
Plots showing values as deviations from means were given by Shewhart
(1931), Pearson (1956),  Davis (2002, p.81), Grafen and Hails (2002,
pp.4{c -}7), McKillup (2005, 2012), Klemel{c a:} (2009), Whitlock and
Schluter (2009, pp.396, 519; 2015, p.464 and cf.p.609; 2020, p.468),
McKillup and Dyar (2010), Welham {it:et al.} (2015) and Hector (2015,
2021).  A related plot, which seems especially popular in clinical
oncology, is the waterfall plot (or waterfall chart). Common examples
show variations in change in tumour dimensions during clinical trials.
See (e.g.) Gilder (2012). Note, however, that waterfall plots or charts
also refer to at least two quite different plots in business and in the
analysis of spectra. See (e.g.) Desbarats (2023a) and Kabacoff (2024). 

{it:Quantile plots} 

{p 4 4 2}
Quantile plots were discussed by Cox (1999, 2005), including historical
comments. Further examples long in use for environmental applications
are hypsometric curves (Clarke 1966) and flow duration curves (Searcy
1959).  

{it:Cleveland dot charts} 

{p 4 4 2}
Dot charts (also sometimes called dot plots) in the sense of Cleveland
(1984, 1994) and Cleveland and McGill (1984), as implemented in 
{help graph dot}, are quite distinct. Various authors (e.g. Lang and Secic
2006, Zuur {it:et al.} 2007, Sarkar 2008, Mitchell 2010, Chang
2013/2019, Kirk 2016, Healy 2019, Afifi {it:et al.} 2020, Gerbing 2020,
Wexler 2021, Kabacoff 2024) call these Cleveland dot charts or dot
plots.  For an early variant see Snedecor (1937) and also later
editions.  Examples continued to Snedecor and Cochran (1967).  See also
(e.g.) Bentley and Kernighan (1984, 1986), Becker {it:et al.} (1988),
Bentley (1988), Helsel and Hirsch (1992), Singer and Feinstein (1993),
Henry (1995), Dent (1996). Jacoby (1997, 2006), Sinacore (1997), Millard
(1998), Wilkinson (1999b, 2005), Harrell (2001, 2015), Millard and
Neerchal (2001), Feinstein (2002), Heiberger and Holland (2004, 2015),
Morgenthaler (2007), Cox (2008, 2024), Few (2009, 2012, 2015, 2020),
Myatt and Johnson (2009), Wainer (2009, 2014, 2016), Wickham (2009,
2016), Carr and Pickle (2010), Everitt and Skrondal (2010), Keen (2010,
2018), Martinez {it:et al.} (2011, 2017), Robinson and Hamann (2011),
Feigelson and Babu (2012), Krause and O'Connell (2012), Cairo (2013),
Yau (2013, 2024), Berinato (2016), Cook {it:et al.} (2016), Harris
(2016), Hilfiger (2016), Carlson (2017), Hoffmann (2017), Kubina 
{it:et al.} (2017), Rahlf (2017, 2019), Wexler {it:et al.} (2017), Wickham and
Grolemund (2017), Albert (2018) Kriebel and Murray (2018), Standage
(2018, 2019, 2020), Nolan and Stoudt (2021), Schwabish (2021), Smith
(2022), Alexander (2023), Wickham {it:et al.} (2023) and Yu and Barter
(2024).  

{it:Other Stata references} 

{p 4 4 2}
See also Cox (2004) for a general discussion of graphing distributions
in Stata; Cox (2007) for an implementation of stem-and-leaf plots that
bears some resemblance to what is possible with {cmd:stripplot}; and Cox
(2009, 2013) on how to draw box plots using {help twoway}. 


{title:Examples} 

{p 4 8 2}{cmd:. // (Stata's auto data)}{p_end}
{p 4 8 2}{cmd:. sysuse auto, clear}{p_end}
{p 4 8 2}{cmd:. strip mpg, name(STRIP1, replace)}{p_end}
{p 4 8 2}{cmd:. strip mpg, aspect(0.05) name(STRIP2, replace)}{p_end}
{p 4 8 2}{cmd:. strip mpg, over(rep78) name(STRIP3, replace)}{p_end}
{p 4 8 2}{cmd:. strip mpg, over(rep78) by(foreign, note("")) name(STRIP4, replace)}{p_end}
{p 4 8 2}{cmd:. strip mpg, over(rep78) vertical yla(, ang(h)) name(STRIP5, replace)}{p_end}
{p 4 8 2}{cmd:. strip mpg, over(rep78) vertical stack yla(, ang(h)) name(STRIP6, replace)}{p_end}
{p 4 8 2}{cmd:. strip mpg, over(rep78) vertical stack yla(, ang(h)) height(0.4) name(STRIP7, replace)}{p_end}

{p 4 8 2}{cmd:. gen pipe = "|"}{p_end}
{p 4 8 2}{cmd:. strip mpg, ms(none) mlabpos(0) mlabel(pipe) mlabsize(*2) stack name(STRIP8, replace) }{p_end}
{p 4 8 2}{cmd:. label var price "Price (USD)"}{p_end}
{p 4 8 2}{cmd:. strip price, over(rep78) xla(3000(3000)15000) ms(none) mla(pipe) mlabpos(0) name(STRIP9, replace)}{p_end}
{p 4 8 2}{cmd:. strip price, over(rep78) xla(3000(3000)15000) width(200) stack height(0.4) name(STRIP10, replace)}{p_end}

{p 4 8 2}{cmd:. // (5 here is empirical: adjust for your variable)}{p_end}
{p 4 8 2}{cmd:. gen price1 = price - 5}{p_end}
{p 4 8 2}{cmd:. gen price2 = price + 5}{p_end}
{p 4 8 2}{cmd:. strip price, over(rep78) xla(3000(3000)15000) ms(none) addplot(rbar price1 price2 rep78, horizontal barw(0.2) bcolor(gs6)) name(STRIP11, replace)}{p_end}

{p 4 8 2}{cmd:. gen digit = mod(mpg, 10)}{p_end}
{p 4 8 2}{cmd:. strip mpg, stack vertical mla(digit) mlabpos(0) ms(i) over(foreign) height(0.2) yla(, ang(h)) xla(, ang(-0.001) tlength(*2) tlcolor(none)) subtitle(stem-and-leaf plot) name(STRIP12, replace)}{p_end}
{p 4 8 2}{cmd:. strip mpg, stack vertical mla(digit) mlabpos(0) ms(i) by(foreign, note("") subtitle(stem-and-leaf plot)) yla(, ang(h)) name(STRIP13, replace)}{p_end}

{p 4 8 2}{cmd:. strip mpg, over(rep78) separate(foreign) stack name(STRIP14, replace)}{p_end}
{p 4 8 2}{cmd:. strip mpg, by(rep78) separate(foreign) stack name(STRIP15, replace)}{p_end}

{p 4 8 2}{cmd:. // (fulcrums to mark means as centres of gravity)}{p_end}
{p 4 8 2}{cmd:. gen rep78_1 = rep78 - 0.1}{p_end}
{p 4 8 2}{cmd:. egen mean = mean(mpg), by(foreign rep78)}{p_end}
{p 4 8 2}{cmd:. strip mpg, over(rep78) by(foreign, compact note("")) yla(, glp(solid)) addplot(scatter rep78_1 mean, ms(T)) stack name(STRIP16, replace)}{p_end}

{p 4 8 2}{cmd:. egen mean_2 = mean(mpg), by(rep78)}{p_end}
{p 4 8 2}{cmd:. gen rep78_L = rep78 - 0.1}{p_end}
{p 4 8 2}{cmd:. gen rep78_U = rep78 - 0.02}{p_end}
{p 4 8 2}{cmd:. strip mpg, over(rep78) stack addplot(pcarrow rep78_L mean_2 rep78_U mean_2, msize(medlarge) barbsize(medlarge)) yla(, grid glp(solid)) name(STRIP17, replace)}{p_end}

{p 4 8 2}{cmd:. clonevar rep78_2 = rep78}{p_end}
{p 4 8 2}{cmd:. replace rep78_2 = cond(foreign, rep78 + 0.15, rep78 - 0.15)}{p_end}
{p 4 8 2}{cmd:. strip mpg, over(rep78_2) separate(foreign) yla(1/5) jitter(1 1) name(STRIP18, replace)}{p_end}

{p 4 8 2}{cmd:. logit foreign mpg}{p_end}
{p 4 8 2}{cmd:. predict pre}{p_end}
{p 4 8 2}{cmd:. strip mpg, over(foreign) stack ms(sh) height(0.15) subtitle(logit model) addplot(mspline pre mpg, bands(20)) name(STRIP19, replace)}{p_end}

{p 4 8 2}{cmd:. // (reference lines where by() would seem natural)}{p_end}
{p 4 8 2}{cmd:. // (labmask (Cox 2008) would be another solution for label fix)}{p_end}
{p 4 8 2}{cmd:. egen group = group(foreign rep78)}{p_end}
{p 4 8 2}{cmd:. replace group = cond(group <= 5, group, group + 1)}{p_end}
{p 4 8 2}{cmd:. label def group 7 "3" 8 "4" 9 "5", modify}{p_end}
{p 4 8 2}{cmd:. lab val group group}{p_end}
{p 4 8 2}{cmd:. strip mpg, over(group) vertical quantile centre mcolor(blue) xmla(3 "Domestic" 8 "Foreign", tlength(*7) tlc(none) labsize(medium)) yla(, ang(h)) xtitle("") xli(6, lc(gs12) lw(vthin)) name(STRIP20, replace)}{p_end}

{p 4 8 2}{cmd:. sysuse auto, clear }{p_end}
{p 4 8 2}{cmd:. egen median = median(mpg), by(foreign)}{p_end}
{p 4 8 2}{cmd:. egen loq = pctile(mpg), by(foreign) p(25)}{p_end}
{p 4 8 2}{cmd:. egen upq = pctile(mpg) , by(foreign) p(75)}{p_end}
{p 4 8 2}{cmd:. egen mean = mean(mpg), by(foreign)}{p_end}
{p 4 8 2}{cmd:. egen min = min(mpg)}{p_end}
{p 4 8 2}{cmd:. egen n = count(mpg), by(foreign)}{p_end}
{p 4 8 2}{cmd:. gen shown = "{it:n = }" + string(n)}{p_end}
{p 4 8 2}{cmd:. gen foreign2 = foreign + 0.15}{p_end}
{p 4 8 2}{cmd:. gen foreign3 = foreign - 0.15}{p_end}
{p 4 8 2}{cmd:. gen showmean = string(mean, "%2.1f")}{p_end}
{p 4 8 2}{cmd:. local box scatter median loq upq foreign2, ms(none ..) mla(median loq upq) mlabc(blue ..) mlabsize(*1.2 ..)}{p_end}
{p 4 8 2}{cmd:. local mean scatter mean foreign3, ms(none) mla(showmean) mlabc(orange) mlabsize(*1.2) mlabpos(9)}{p_end}
{p 4 8 2}{cmd:. local min scatter min foreign, ms(none) mla(shown) mlabc(black) mlabsize(*1.2) mlabpos(6)}{p_end}
{p 4 8 2}{cmd:. strip mpg, over(foreign) centre quantile vertical height(0.4) addplot(`box' || `mean' || `min') xsc(r(. 1.2)) yla(, ang(h)) xla(, noticks) name(STRIP21, replace) note("mean on left, median and quartiles on right")}{p_end}

{p 4 8 2}{cmd:. // (Stata's blood pressure data)}{p_end}
{p 4 8 2}{cmd:. sysuse bplong, clear}{p_end}
{p 4 8 2}{cmd:. egen group = group(age sex), label}{p_end}
{p 4 8 2}{cmd:. strip bp*, over(when) by(group, compact col(1) note("") subtitle(Systolic blood pressure (mm Hg))) ysc(reverse) subtitle(, pos(9) ring(1) nobexpand bcolor(none) placement(e)) ytitle("") xtitle("")  xsc(alt) name(STRIP22, replace)}{p_end}

{p 4 8 2}{cmd:. // (Stata's US city temperature data)}{p_end}
{p 4 8 2}{cmd:. sysuse citytemp, clear}{p_end}
{p 4 8 2}{cmd:. label var tempjan "Mean January temperature ({&degree}F)"}{p_end}
{p 4 8 2}{cmd:. strip tempjan, over(region) subtitle(quantile plots) quantile vertical yla(14 32 50 68 86, ang(h)) xla(, noticks) centre name(STRIP23, replace)}{p_end}

{p 4 8 2}{cmd:. gen id = _n}{p_end}
{p 4 8 2}{cmd:. reshape long temp, i(id) j(month) string}{p_end}
{p 4 8 2}{cmd:. replace month = cond(month == "jan", "January", "July")}{p_end}
{p 4 8 2}{cmd:. label var temp "Mean temperature ({&degree}F)"}{p_end}
{p 4 8 2}{cmd:. strip temp, over(region) by(month, note("") subtitle(quantile plots)) quantile vertical yla(14 32 50 68 86, ang(h)) centre name(STRIP24, replace)}{p_end}
{p 4 8 2}{cmd:. strip temp, over(region) by(month, note("") subtitle(normal quantile plots)) quantile trscale(invnormal(@)) centre vertical yla(14 32 50 68 86, ang(h)) name(STRIP25, replace)}{p_end}

{p 4 8 2}{cmd:. egen mean = mean(temp), by(region month)}{p_end}
{p 4 8 2}{cmd:. gen regionL = region - 0.4}{p_end}
{p 4 8 2}{cmd:. gen regionR = region + 0.4}{p_end}
{p 4 8 2}{cmd:. strip temp, over(region) by(month, note("") subtitle(normal quantile plots with means)) quantile trscale(invnormal(@)) centre vertical yla(14 32 50 68 86, ang(h))}{p_end}
{p 8 8 2}{cmd:  addplot(rspike  regionL regionR mean, horizontal) name(STRIP26, replace)}{p_end}

{p 4 4 2}
The following examples use datasets from Whitlock and Schluter (2020)
and require (1) internet access to download the data; (2) previous
installation of {cmd:pctilesets}; (3) Stata 18 up to allow use of
{cmd:stc2} (but just change the {cmd:local} macro otherwise).

{p 4 8 2}{cmd:. import delimited using https://whitlockschluter3e.zoology.ubc.ca/Data/chapter02/chap02e3bHumanHemoglobinElevation.csv, clear}{p_end}
{p 4 8 2}{cmd:. label var hemoglobin "Hemoglobin concentration (g dl{sup:-1})"}{p_end}
{p 4 8 2}{cmd:. egen mean = mean(hemoglobin), by(population)}{p_end}
{p 4 8 2}{cmd:. egen n = count(hemoglobin), by(population)}{p_end}
{p 4 8 2}{cmd:. gen shown = "{c -(}it:n{c )-}  = " + strofreal(n)}{p_end}
{p 4 8 2}{cmd:. gen where = 9}{p_end}
{p 4 8 2}{cmd:. encode population, gen(x)}{p_end}
{p 4 8 2}{cmd:. gen xL = x - 0.4}{p_end}
{p 4 8 2}{cmd:. gen xR = x + 0.4}{p_end}
{p 4 8 2}{cmd:. strip hemoglobin, over(population) vertical quantile centre trscale(invnormal(@)) xla(, tlength(0)) xtitle("") addplot(scatter where x, ms(none) mla(shown) mlabpos(0) mlabsize(medium)}{p_end}
{p 8 8 2}{cmd:  || rspike xL xR mean, horizontal lc(black)) subtitle(normal quantile plots with added means) name(STRIP27, replace)}{p_end}

{p 4 8 2}{cmd:. import delimited using https://whitlockschluter3e.zoology.ubc.ca/Data/chapter12/chap12q17StalkieEyespan.csv, clear}{p_end}
{p 4 8 2}{cmd:. gen diet = food + " diet"}{p_end}
{p 4 8 2}{cmd:. label var eyespan "Eye span (mm)"}{p_end}
{p 4 8 2}{cmd:. save eyespan, replace }{p_end}
{p 4 8 2}{cmd:. pctilesets eyespan, over(diet) pctile(25 50 75) min max saving(eyespan_pctiles, replace)}{p_end}
{p 4 8 2}{cmd:. clonevar origgvar=diet }{p_end}
{p 4 8 2}{cmd:. merge m:1 origgvar using eyespan_pctiles }{p_end}
{p 4 8 2}{cmd:. gen xbox = cond(food == "Corn", 0.9, 1.9)}{p_end}
{p 4 8 2}{cmd:. local color stc2 }{p_end}
{p 4 8 2}{cmd:. strip eyespan , over(diet) quantile vertical height(0.25) xla(, tlcolor(none)) addplot(rbar p25 p75 xbox, barwidth(0.16) lcolor(`color') fcolor(none) || scatter p50 xbox, ms(Dh) mcolor(`color') msize(medium)}{p_end}
{p 8 8 2}{cmd:  || rspike p75 max xbox, lcolor(`color') || rspike p25 min xbox, lcolor(`color')) aspect(1.2) yla(1 1.2 1.4 1.6 1.8 2 2.2) xtitle("") name(STRIP28, replace)}{p_end}

{p 4 8 2}{cmd:. import delimited using https://whitlockschluter3e.zoology.ubc.ca/Data/chapter13/chap13e1MarineReserve.csv, clear }{p_end}
{p 4 8 2}{cmd:. label var biomassratio "Biomass rato"}{p_end}
{p 4 8 2}{cmd:. means biomassratio}{p_end}
{p 4 8 2}{cmd:. scalar gmean = r(mean_g)}{p_end}
{p 4 8 2}{cmd:. su biomassratio}{p_end}
{p 4 8 2}{cmd:. strip biomassratio, vertical quantile ysc(log) yli(`=gmean', lp(solid)) aspect(1) text(`=gmean + 0.1' 1.1 "geometric mean") yla(`r(min)' 1/4 `r(max)') name(STRIP29, replace)}{p_end}

{p 4 8 2}{cmd:. import delimited using https://whitlockschluter3e.zoology.ubc.ca/Data/chapter15/chap15q09HippocampalVolumeRatio.csv, clear}{p_end}
{p 4 8 2}{cmd:. encode group, gen(GROUP)}{p_end}
{p 4 8 2}{cmd:. label define GROUP 1 "febrile" 2 "non-febrile" 3 none, modify}{p_end}
{p 4 8 2}{cmd:. label var GROUP "Childhood seizures"}{p_end}
{p 4 8 2}{cmd:. label var hippovolumeratio "Hippocampal volume ratio (%)"}{p_end}
{p 4 8 2}{cmd:. egen median = median(hippovolumeratio), by(group)}{p_end}
{p 4 8 2}{cmd:. gen GROUPL = GROUP - 0.4}{p_end}
{p 4 8 2}{cmd:. gen GROUPR = GROUP + 0.4}{p_end}
{p 4 8 2}{cmd:. su hippovolumeratio}{p_end}
{p 4 8 2}{cmd:. gen where = r(min) - 5}{p_end}
{p 4 8 2}{cmd:. egen count = count(hippovolumeratio), by(GROUP)}{p_end}
{p 4 8 2}{cmd:. gen shown = "{it:n} = " + strofreal(count)}{p_end}
{p 4 8 2}{cmd:. strip hippovolumeratio , over(GROUP) vertical quantile center xla(, tlc(none)) ms(O ..)}{p_end}
{p 8 8 2}{cmd: addplot(rspike GROUPL GROUPR median, horizontal || scatter where GROUP, ms(none) mla(shown) mlabsize(medium) mlabpos(0) mlabcolor(black))}{p_end}
{p 8 8 2}{cmd: yla(47 50(10)100) note(horizontal lines show medians, pos(11)) name(STRIP30, replace)}{p_end}


{title:Acknowledgments}

{p 4 4 2}
Philip Ender helpfully identified a bug. 
William Dupont offered encouragement. 
Kit Baum nudged me into implementing {cmd:separate()}. 
Maarten Buis made a useful suggestion about this help. 
Ron{c a'}n Conroy suggested adding whiskers. He also found two bugs. 
Marc Kaulisch asked a question which led to more emphasis on the use of 
{cmd:by()} and the blood pressure example.
David Airey found another bug. 
Oliver Jones asked a question which led to an example of the use 
of {cmd:twoway rbar} to mimic pipe or barcode symbols. 
Fredrik Norstr{c o:}m found yet another bug. 
Marcello Pagano verified the 1966 Draper and Smith reference. 
Dionyssios Mintzopoulos and Judith Abrams underlined the value of reference lines like those in {cmd:dotplot}, but drawn as such. 
Vince Wiggins and David Airey gave helpful and encouraging 
suggestions on a related program. 
Frank Harrell also made encouraging remarks. 
Alona Armstrong provided the 2015 Weissgerber {it:et al.} reference.  
James Sanders, William Lisowski, Eric Booth and Chinh Nguyen helped to  
identify and solve a problem with box line widths that were 
sometimes much too small to be visible.
David Airey found yet another bug. Nitish Upadhyaya tickled and Eddy 
Simms located a further bug. Antony Unwin provided the gatherplot reference.  
Richard Goldstein supplied the 2018 Chiou and Bergey reference. 
Pete Taylor tickled a bug if the variables specified in {cmd:by()} and {cmd:separate()} were the same variable. 


{title:Author}

{p 4 4 2}Nicholas J. Cox, Durham University, U.K.{break} 
n.j.cox@durham.ac.uk


{title:References} 

{p 4 8 2}Adams, M.J. 1992. 
Errors and detection limits. 
In Hewitt, C.N. (ed.) {it:Methods of Environmental Data Analysis.} 
London: Chapman and Hall, 181{c -}212. 

{p 4 8 2}Afifi, A., S. May, R.A. Donatello and V.A. Clark. 2020. 
{it:Practical Multivariate Analysis.}
Boca Raton, FL: CRC Press. 

{p 4 8 2}Agresti, A. 2018. 
{it:Statistical Methods for the Social Sciences.}
Harlow: Pearson. (stripplot pp.49, 371; box plot with means pp.62, 263, 386)

{p 4 8 2}Agresti, A. and C. Franklin. 2007. 
{it:Statistics: The Art and Science of Learning from Data.} 
Upper Saddle River, NJ: Pearson Prentice Hall. (later editions 2009, 2013, 2016, 2021, from 2016 with B. Klingenberg)   

{p 4 8 2}Agterberg, F.P. 1974. 
{it:Geomathematics: Mathematical Background and Geo-Science Applications.} 
Amsterdam: Elsevier. See p.178. 

{p 4 8 2}Aitchison, J. 1986. 
{it:The Statistical Analysis of Compositional Data.}
London: Chapman and Hall. 

{p 4 8 2}Aitkin, M., B. Francis and J. Hinde. 2005. 
{it:Statistical Modelling in GLIM 4.} 
Oxford: Oxford University Press. 

{p 4 8 2}Aitkin, M., B. Francis, J. Hinde and R. Darnell. 2009. 
{it:Statistical Modelling in R.} 
Oxford: Oxford University Press. 

{p 4 8 2}Albert, J. 2018. 
{it:Visualizing Baseball.} 
Boca Raton, FL: CRC Press.

{p 4 8 2}Alexander, R. 2023. 
{it:Telling Stories about Data : With Applications in R.} 
Boca Raton, FL: CRC Press.
stripplot 134, 377; box plot with jittered dots 137, 203; 
Cleveland dot chart 173, 229, 259. 

{p 4 8 2} 
Allen, M., D. Poggiali, K. Whitaker, T.R. Marshall and R.A. Kievit. 
2019. 
Raincloud plots: a multi-platform tool for robust data visualization. 
{it:Wellcome Open Research} 4: 63. 
doi: 10.12688/wellcomeopenres.15191.1. 

{p 4 8 2}Altman, D.G. 1991. 
{it:Practical Statistics in Medical Research.} 
London: Chapman and Hall. 

{p 4 8 2}Amaratunga, D., J. Cabrera and Z. Shkedy. 2014. 
{it:Exploration and Analysis of DNA Microarray and Other High-Dimensional Data.}
Hoboken, NJ: John Wiley. 

{p 4 8 2}Andersen, P.K. and L.T. Skovgaard. 2010. 
{it:Regression with Linear Predictors.} New York: Springer. 

{* RJ is the form he uses, with no stops.}{...}
{p 4 8 2}Andrews, RJ. 2019. 
{it:Info We Trust: How to Inspire the World with Data.} 
Hoboken, NJ: John Wiley. 

{p 4 8 2}Armitage, P., G. Berry and J.N.S. Matthews. 2002. 
{it:Statistical Methods in Medical Research.} 
Malden, MA: Blackwell. 

{p 4 8 2}Atkinson, A.C. 1985. 
{it:Plots, Transformations and Regression: An Introduction to Graphical Methods of Diagnostic Regression Analysis.}
Oxford: Oxford University Press. 

{p 4 8 2}Bajpai, A.C., I.M. Calus and J.A. Fairley. 1992. 
Descriptive statistical techniques. 
In Hewitt, C.N. (ed.) {it:Methods of Environmental Data Analysis.} 
London: Chapman and Hall, 1{c -}35.

{p 4 8 2}Barnett, A.G. and A.J. Dobson. 2010.
{it:Analysing Seasonal Health Data.} 
Berlin: Springer. Rugs on pp.65, 118.  

{p 4 8 2}Barnett, V. 2004. 
{it:Environmental Statistics: Methods and Applications.} 
Chichester: John Wiley. 

{p 4 8 2}Barnett, V. and T. Lewis. 1978. 
{it:Outliers in Statistical Data.} 
Chichester: John Wiley [later editions 1984, 1994] 

{p 4 8 2}Bartholomew, D.J. 2016. 
{it:Statistics Without Mathematics.} London: SAGE.

{p 4 8 2}Bateson, W. 1894. 
{it:Materials for the Study of Variation Treated with Especial Regard to Discontinuity in the Origin of Species.} 
London: Macmillan (Reprint 1992. Baltimore: Johns Hopkins University Press) 
(see p.39, repeating one graph from Bateson and Brindley).  

{p 4 8 2}Bateson, W. and H.H. Brindley. 1892. On some cases of 
variation in secondary sexual characters, statistically examined. 
{it:Proceedings of the Zoological Society of London} 
60: 585{c -}594  (see pp.591{c -}593). 

{p 4 8 2}Baxter, M.J. 1994. 
{it:Exploratory Multivariate Analysis in Archaeology.} 
Edinburgh: Edinburgh University Press. Reprinted 2015. 
Clinton Corners, NY: Percheron Press. 

{p 4 8 2}Baxter, M. 2003. {it:Statistics in Archaeology.} 
London: Hodder Arnold. 

{p 4 8 2}Becker, R. A. and J. M. Chambers. 1984. 
{it:S: An Interactive Environment for Data Analysis and Graphics.} 
Belmont, CA: Wadsworth. 

{p 4 8 2}Becker, R.A., J.M. Chambers and A.R. Wilks. 1988. 
{it:The New S language: A Programming Environment for Data Analysis and Graphics.} 
Pacific Grove, CA: Wadsworth and Brooks/Cole. 

{p 4 8 2} 
Behrens, J.T. 1997. 
Principles and procedures of exploratory data analysis. 
{it:Psychological Methods} 2: 131{c -}160. 

{p 4 8 2}
Benjamini, Y. 1988. 
Opening the box of a boxplot. 
{it:American Statistician} 42: 257{c -}262

{p 4 8 2}Bentley, J.L. 1985. 
Programming pearls: selection. 
{it:Communications of the ACM} 28: 1121{c -}1127.  

{p 4 8 2}Bentley, J.L. 1988. 
{it:More Programming Pearls: Confessions of a Coder.} 
Reading, MA: Addison-Wesley.  

{p 4 8 2}Bentley, J.L. and B.W. Kernighan. 1984. 
GRAP {c -} A language for typesetting graphs: Tutorial and user manual. 
AT & T Bell Laboratories Computing Science Technical Report 114. 

{p 4 8 2}Bentley, J.L. and B.W. Kernighan. 1986. 
GRAP {c -} A language for typesetting graphs.
{it:Communications of the Association for Computing Machinery} 29: 782{c -}792. 

{p 4 8 2}Berinato, S. 2016. 
{it:Good Charts: The HBR Guide to Making Smarter, More Persuasive Data Visualizations.} 
Boston, MA: Harvard Business Review Press. 

{p 4 8 2}Berry, D.A. 1996. {it:Statistics: A Bayesian Perspective.} 
Belmont, CA: Duxbury.

{p 4 8 2}Berry, D.A. and B.W. Lindgren. 1990. 
{it:Statistics: Theory and Methods.} 
Pacific Grove, CA: Brooks/Cole. 
dot diagram 322, 339, 460; rug plot 566, 571, 589  

{p 4 8 2}Berry, D.A. and B.W. Lindgren. 1996. 
{it:Statistics: Theory and Methods.} 
Belmont, CA: Duxbury. 
data plot 291; dot diagram 260, 419; dot plot 485; rug plot 531, 538  

{p 4 8 2}Bertin, J. 1981.
{it:Graphics and Graphic Information Processing}.
Berlin: De Gruyter.

{p 4 8 2}Bertin, J. 1983.
{it:Semiology of Graphics: Diagrams, Networks, Maps}.
Madison: University of Wisconsin Press.

{p 4 8 2}Bianconi, F. 2024. 
{it:Data and Process Visualization for Graphic Communication: A Hands-on Approach with Python.}
Cham: Springer. See pp.70, 83, 84, 87. 

{p 4 8 2}Bibby, J. 1986. 
{it:Notes Towards a History of Teaching Statistics.} 
Edinburgh: John Bibby (Books). 

{p 4 8 2}Binford, L.R. 1972. 
Contemporary model building: paradigms and the current state of 
Palaeolithic research. In Clarke, D.L. (ed.) 
{it:Models in Archaeology.} 
London: Methuen, 109{c -}166. 

{p 4 8 2}
Bl{c ae}sild, P. and J. Granfeldt. 2003. 
{it:Statistics with Applications in Biology and Geology.} 
Boca Raton, FL: Chapman and Hall/CRC. 

{p 4 8 2}Bland, M. 2000. 
{it:An Introduction to Medical Statistics.}
Oxford: Oxford University Press. (fourth edition 2015)  

{p 4 8 2}Bolker, B.M. 2008. 
{it:Ecological Models and Data in R.} 
Princeton, NJ: Princeton University Press. 
See rugs on pp.177, 218, 241, 

{p 4 8 2}Boneva, L.I., D.G. Kendall and I. Stefanov. 1971. 
Spline transformations: three new diagnostic aids for the statistical 
data-analyst. 
{it:Journal of the Royal Statistical Society Series B} 
33: 1{c -}71. (See p.35.)                               

{p 4 8 2}Bouvreyron, C., G. Celeux, T.B. Murphy and A.E. Raftery. 
2019. 
{it:Model-based Clustering and Classification for Data Science With Applications in R.} 
Cambridge: Cambridge University Press. 

{p 4 8 2}Bowley, A.L. 1910. 
{it:An Elementary Manual of Statistics.} 
London: Macdonald and Evans. (seventh edition 1952)

{p 4 8 2}Bowman, A.W. 2008. 
Smoothing techniques for visualization. 
In Chen, C., W. H{c a:}rdle and A. Unwin (eds) 
{it:Handbook of Data Visualization.} 
Berlin: Springer, 493{c -}514.  

{p 4 8 2}Bowman, A.W. and A. Azzalini. 1997. 
{it:Applied Smoothing Techniques for Data Analysis: The Kernel Approach with S-PLus Illustrations.} 
Oxford: Oxford University Press. See pp.55, 56, 152, 158, 164, 165.  

{p 4 8 2}Box, G.E.P., W.G. Hunter and J.S. Hunter. 1978. 
{it: Statistics for Experimenters: An Introduction to Design, Data Analysis, and Model Building.}
New York: John Wiley. (second edition 2005)

{p 4 8 2}Box, G.E.P. and G.C. Tiao. 1973. 
{it:Bayesian Inference in Statistical Analysis.} 
Reading, MA: Addison-Wesley. Rugs on pp.68, 154, 161, 169, 370. 

{p 4 8 2}Bradstreet, T.E. 2012.
Grables: Visual displays that combine the best attributes of graphs 
and tables. 
In Krause, A. and O'Connell, M. (eds) 
{it:A Picture is Worth a Thousand Tables: Graphics in Life Sciences.} 
New York: Springer, 41{c -}69.  

{p 4 8 2}Brier, S.S. and S.E. Fienberg. 1980.  
Recent econometric modelling of crime and punishment: 
support for the deterrence hypothesis? 
In Fienberg, S.E. and A.J. Reiss Jr (eds)
{it:Indicators of Crime and Criminal Justice: Quantitative Studies.} 
Washington, DC: US Department of Justice Bureau of Justice Statistics, 
82{c -}97.  

{p 4 8 2}Brillinger, D.R. and A.E.P. Villa. 1997. 
Assessing connections in networks of biological neurons. 
In Brillinger, D.R., L.T. Fernholz and S. Morgenthaler (eds) 
{it:The Practice of Data Analysis: Essays in Honor of John W. Tukey.}
Princeton, NJ: Princeton University Press, 77{c -}92. 

{p 4 8 2}Brinton, W.C. 1939. 
{it:Graphic Presentation.} 
New York: Brinton Associates. See p.317.

{p 4 8 2}Brown, B.W., Jr and M.S.J. Hu. 1980. 
Setting dose levels for the treatment of testicular cancer. 
In Miller, R.G., Jr, B. Efron, B.W. Brown, Jr and L.E. Moses (eds)
{it:Biostatistics Casebook.} New York: John Wiley, 

{p 4 8 2}Brunt, D. 1917. 
{it:The Combination of Observations.} 
London: Cambridge University Press. (2nd edition 1931)  

{p 4 8 2}Burt, J.E., G.M. Barber and D.L. Rigby. 2009. 
{it:Elementary Statistics for Geographers.} 
New York: Guilford Press. 

{p 4 8 2}Butler, R.C. 2022. 
Popularity leads to bad habits: Alternatives to "the statistics" routine 
of significance, "alphabet soup" and dynamite plots. 
{it:Annals of Applied Biology} 180: 182{c -}195. 

{p 4 8 2}Cairo, A. 2013.  
{it:The Functional Art: An Introduction to Information Graphics and Visualization.} 
Berkeley, CA: New Riders.

{p 4 8 2}Cairo, A. 2016. 
{it:The Truthful Art: Data, Charts, and Maps for Communication.} 
San Francisco, CA: New Riders. 

{p 4 8 2}Cairo, A. 2019. 
{it:How Charts Lie: Getting Smarter about Visual Information.} 
New York: W.W. Norton. 

{p 4 8 2}Cam{c o~}es, J. 2016. 
{it:Data at Work: Best Practices for Creating Effective Charts and Information Graphics in Microsoft Excel.} San Francisco, CA: New Riders. 

{p 4 8 2}Carlson, D.L. 2017. 
{it:Quantitative Methods in Archaeology Using R.}
Cambridge: Cambridge University Press. 

{p 4 8 2}
Carr, D.B. and L.W. Pickle. 2010. 
{it:Visualizing Data Patterns with Micromaps.}
Boca Raton, FL: CRC Press. p.85.

{p 4 8 2}Chambers, J.M., W.S. Cleveland, B. Kleiner and P.A. Tukey. 1983. 
{it:Graphical Methods for Data Analysis.} Belmont, CA: Wadsworth. 

{p 4 8 2}Chang, W. 2019. 
{it:R Graphics Cookbook: Practical Recipes for Visualizing Data.} 
Sebastopol, CA: O'Reilly. 1st edition 2013 
[same subtitle on cover but not on title page]. 

{p 4 8 2}Chatfield, C. 1988. 
{it:Problem Solving: A Statistician's Guide.} London: Chapman and Hall.
(second edition 1995)

{p 4 8 2}Chiou, K.L. and C.M. Bergey. 2018.
Methylation-based enrichment facilitates low-cost, noninvasive genomic scale sequencing of populations from feces. 
{it:Scientific Reports} 8, 1975. 
{browse "https://doi.org/10.1038/s41598-018-20427-9":https://doi.org/10.1038/s41598-018-20427-9} 

{p 4 8 2}
Christensen, R., W. Johnson. A. Branscum and T.E. Hanson. 2011. 
{it:Bayesian Ideas and Data Analysis: An Introduction for Scientists and Statisticians.}
Boca Raton, FL: CRC Press. 

{p 4 8 2}Clark, L.A. and D. Pregibon. 1992. Tree-based models. 
In Chambers, J.M. and T. Hastie (eds) 
{it:Statistical Models in S.} 
Pacific Grove, CA: Wadsworth and Brooks/Cole, 377{c -}419. 

{p 4 8 2}Clark, W.A.V. and P.L. Hosking. 1986. 
{it:Statistical Methods for Geographers.} 
New York: John Wiley. See p.39. 

{p 4 8 2}Clarke, J.I. 1966. 
Morphometry from maps. 
In Dury, G.H. (ed.) {it:Essays in Geomorphology.}
London: Heinemann, 235{c -}274. 

{p 4 8 2}Clement, A.G. and R.H.S. Robertson. 1961. 
{it:Scotland's Scientific Heritage.} Edinburgh: Oliver and Boyd. 

{p 4 8 2}Cleveland, W.S. 1984. Graphical methods for data presentation: full
scale breaks, dot charts, and multibased logging. 
{it:American Statistician} 38: 270{c -}80.

{p 4 8 2}Cleveland, W.S. 1985. {it:The Elements of Graphing Data.} 
Monterey, CA: Wadsworth.

{p 4 8 2}Cleveland, W.S. 1993. {it:Visualizing Data.}  
Summit, NJ: Hobart Press. See p.115 for use of rugs.  

{p 4 8 2}Cleveland, W.S. 1994. {it:The Elements of Graphing Data.} 
Summit, NJ: Hobart Press. 

{p 4 8 2}Cleveland, W.S. and R. McGill. 1984. 
Graphical perception: Theory, experimentation, and application to the 
development of graphical methods.
{it:Journal, American Statistical Association} 79: 531{c -}554. 

{p 4 8 2}Cliff, N. 1996. 
{it:Ordinal Methods for Behavioral Data Analysis.}
Mahwah, NJ: Lawrence Erlbaum Associates. 

{p 4 8 2}Cobb, G.W. 1998. 
{it:Introduction to Design and Analysis of Experiments.} 
New York: Springer.

{p 4 8 2}Cole, J.P. and C.A.M. King. 1968. 
{it:Quantitative Geography: Techniques and Theories in Geography.} 
London: John Wiley. See pp.4, 6, 72. 

{p 4 8 2}Colinvaux, P.A. 1986. 
{it:Ecology.}
New York: John Wiley. 

{p 4 8 2}Colinvaux, P.A. 1993. 
{it:Ecology 2.}
New York: John Wiley. 

{p 4 8 2}Computing Resource Center. 1985. {it:STATA/Graphics User's Guide.} 
Los Angeles, CA: Computing Resource Center. 

{p 4 8 2}Cook, D., E. Lee and M. Majumder. 2016. 
Data visualization and statistical graphics in big data analysis. 
{it:Annual Review of Statistics and its Applications} 3: 133{c -}159. 

{p 4 8 2}Cook, D. and D. Swayne. 2007. 
{it:Interactive and Dynamic Graphics for Data Analysis With R and GGobi.}
New York: Springer. 

{p 4 8 2}Cooper, R.A. and A.J. Weekes. 1983. 
{it:Data, Models and Statistical Analysis.} 
Deddington, Oxford: Philip Allan.

{p 4 8 2}Correll, M. 2023. 
Teru teru bōzu: Defensive raincloud plots. 
{it:Computer Graphics Forum} 42: 235{c -}246.
[macron accent uchar(333) on o of bozu]   

{p 4 8 2}Cormack, R.M. 1971. 
{it:The Statistical Argument.} 
Edinburgh: Oliver and Boyd. 

{p 4 8 2}Cox, N.J. 1999. 
Quantile plots, generalized. 
{it:Stata Technical Bulletin} 51: 16{c -}18. 

{p 4 8 2}Cox, N.J. 2004. 
Speaking Stata: Graphing distributions. 
{it:Stata Journal} 4(1): 66{c -}88. 

{p 4 8 2}Cox, N.J. 2005. 
Speaking Stata: The protean quantile plot. 
{it:Stata Journal} 5(3): 442{c -}460. 
 
{p 4 8 2}Cox, N.J. 2007. 
Speaking Stata: Turning over a new leaf. 
{it:Stata Journal} 7(3): 413{c -}433. 

{p 4 8 2}Cox, N.J. 2008. 
Speaking Stata: Between tables and graphs. 
{it:Stata Journal} 8(2): 269{c -}289. 

{p 4 8 2}Cox, N.J. 2009. 
Speaking Stata: Creating and varying box plots. 
{it:Stata Journal} 9(3): 478{c -}496. 

{p 4 8 2}Cox, N.J. 2013. 
Speaking Stata: Creating and varying box plots: correction. 
{it:Stata Journal} 13(2): 398{c -}400. 

{p 4 8 2}Cox, N.J. 2014. 
How can I calculate percentile ranks? How can I calculate plotting positions?
{browse "https://www.stata.com/support/faqs/statistics/percentile-ranks-and-plotting-positions":/https://www.stata.com/support/faqs/statistics/percentile-ranks-and-plotting-positions/}

{p 4 8 2}Cox, N.J. 2020. 
Speaking Stata: More ways for rowwise. 
{it:Stata Journal} 20(2): 481{c -}488.

{p 4 8 2}Cox, N.J. 2024. 
Speaking Stata: Getting by without the by() option: Some graphics for
unequal groups. 
{it:Stata Journal} 24: 766--776   

{p 4 8 2}Cox, N.J. 2025. 
Add marginal rugs using marker symbols or axis ticks. 
{it:Stata Journal} 25: 491{c -}497. 

{p 4 8 2}Cressie, N.A.C. 1991. 
{it:Statistics for Spatial Data.} 
New York: John Wiley.  

{p 4 8 2}Crowe, P.R. 1933. 
The analysis of rainfall probability: A graphical method and its application to European data. 
{it:Scottish Geographical Magazine} 49: 73{c -}91.

{p 4 8 2}Crowe, P.R. 1936. 
The rainfall regime of the Western Plains. 
{it:Geographical Review} 26: 463{c -}484.  

{p 4 8 2}Crowe, P.R. 1971. 
{it:Concepts in Climatology.} 
London: Longman.

{p 4 8 2}Cumming, G. 2012. 
{it:Understanding the New Statistics: Effect Sizes, Confidence Intervals, and Meta-analysis.} 
New York: Routledge. 

{p 4 8 2} 
Curry, A.M. 1999. 
Paraglacial modification of slope form. 
{it:Earth Surface Processes and Landforms} 24: 1213{c -}1228. 

{p 4 8 2}Dalgaard, P. 2002. {it:Introductory Statistics with R.} 
New York: Springer.

{p 4 8 2}Daly, F., D.J. Hand, M.C. Jones, A.D. Lunn and K.J. McConway. 1995. 
{it:Elements of Statistics.} Wokingham: Addison-Wesley.  

{p 4 8 2}Daniel, C. 1976. 
{it:Applications of Statistics to Industrial Experimentation.} 
New York: John Wiley. 

{p 4 8 2}Darwin, G.H. 1873. 
Variations of organs. {it:Nature} 8: 505.

{p 4 8 2}Davino, C., M. Furno and D. Vistocco. 2014. 
{it:Quantile Regression: Theory and Applications.} 
Chichester: John Wiley. See pp.10, 16{c -}17.  

{p 4 8 2}Davis, J.C. 2002. 
{it:Statistics and Data Analysis in Geology.} 
New York: John Wiley. (previous editions 1973, 1986) 

{p 4 8 2}DelSole, T.D. and M.K. Tippett. 2022. 
{it:Statistical Methods for Climate Scientists.} 
Cambridge: Cambridge University Press. 

{p 4 8 2}Dent, B. D. 1996. 
{it:Cartography: Thematic Map Design.}
Dubuque, IA: Wm C. Brown. 
See number line p.175; box plot with 10 and 90% points p.376; dot chart p.376. 

{p 4 8 2}Desbarats, N.P. 2023a. 
{it:Practical Charts.}
Ottawa: Practical Reporting, Inc. 

{p 4 8 2}Desbarats, N.P. 2023b. 
{it:More Practical Charts.}
Ottawa: Practical Reporting, Inc. 

{p 4 8 2}Desbarats, N.P. 2025. 
I stopped Using box plots: The aftermath.
{browse "https://nightingaledvs.com/i-stopped-using-box-plots-the-aftermath/":https://nightingaledvs.com/i-stopped-using-box-plots-the-aftermath/}

{p 4 8 2}De Veaux, R.D., P.F. Velleman and D.E. Bock. 2019. 
{it:Stats: Data and Models.} 
Harlow: Pearson. Note also previous editions and related texts
under different titles. 

{p 4 8 2}Dickinson, G.C. 1963. 
{it:Statistical Mapping and the Presentation of Statistics.} 
London: Edward Arnold. (second edition 1973)

{p 4 8 2}Diez, D.M., M. {c C,}etinskaya-Rundel, M. and C.D. Barr. 2022. 
{it:OpenIntro Statistics}. openintro.org

{p 4 8 2}Dixon, W.J. and F.J. Massey. 1951. 
{it:An Introduction to Statistical Analysis.} 
New York: McGraw-Hill. See pp.6{c -}7 and 37.
 
{p 4 8 2}Dixon, W.J. and F.J. Massey. 1957. 
{it:An Introduction to Statistical Analysis.} 
New York: McGraw-Hill. See pp.5{c -}7 and 37.
 
{p 4 8 2}Dixon, W.J. and F.J. Massey. 1969. 
{it:An Introduction to Statistical Analysis.} 
New York: McGraw-Hill. See pp.7{c -}8 and 45. 

{p 4 8 2}Dixon, W.J. and F.J. Massey. 1983. 
{it:An Introduction to Statistical Analysis.} 
New York: McGraw-Hill. See pp.6{c -}7 and 47. 

{p 4 8 2}Doane, D.P. and L.E. Seward. 2011. 
Measuring skewness: A forgotten statistic?
{it:Journal of Statistics Education}  19(2)  
{browse "www.amstat.org/publications/jse/v19n2/doane.pdf":www.amstat.org/publications/jse/v19n2/doane.pdf} 

{p 4 8 2}Doane, D.P. and R.L. Tracy. 2000. 
Using beam and fulcrum displays to explore data. 
{it:American Statistician} 54: 289{c -}290.

{p 4 8 2}Dobson, A.J. 1983. 
{it:An Introduction to Statistical Modelling.} 
London: Chapman and Hall. 

{p 4 8 2}Dobson, A.J. 1990. 
{it:An Introduction to Generalized Linear Models.} 
London: Chapman and Hall. 

{p 4 8 2}Dobson, A.J. 2002. 
{it:An Introduction to Generalized Linear Models.}
Boca Raton, FL: Chapman and Hall/CRC Press. 

{p 4 8 2}Dobson, A.J. and A.G. Barnett. 2008. 
{it:An Introduction to Generalized Linear Models.}
Boca Raton, FL: CRC Press. 

{p 4 8 2}Dobson, A.J. and A.G. Barnett. 2018. 
{it:An Introduction to Generalized Linear Models.}
Boca Raton, FL: CRC Press. 

{p 4 8 2}Dodge, Y. 2008. 
{it:The Concise Encyclopedia of Statistics.}
New York: Springer. 

{p 4 8 2}Doggett, T.J. and C. Way. 2024. 
Dynamite plots in surgical research over 10 years: 
a meta-study using machine learning analysis. 
{it:Postgraduate Medical Journal} 100: 262{c -}266.

{p 4 8 2}Draghici, S. 2012. 
{it:Statistics and Data Analysis for Microarrays Using R and Bioconductor.} 
Boca Raton, FL: CRC Press. 
[breve accent on a of Draghici] 

{p 4 8 2}Draper, N.R. and H. Smith. 1966. 
{it:Applied Regression Analysis.} 
New York: John Wiley. Dot plots not named as such pp.87, 92.
Dot diagram used as synonym of scatter diagram p.5.
Later editions 1981, 1998.  In 1998, dot plot called histogram p.62.

{p 4 8 2}Drummond, G.B. and S.L. Vowler. 2011. 
Show the data, don't conceal them. {it:British Journal of Pharmacology} 
163: 208{c -}210. Also published in 
{it:Journal of Physiology}, {it:Advances in Physiology Education}, 
{it:Microcirculation} and 
{it:Clinical and Experimental Pharmacology and Physiology}. 

{p 4 8 2}Dupont, W.D. 2002. 
{it:Statistical Modelling for Biomedical Researchers.} 
Cambridge: Cambridge University Press (second edition 2009) 

{p 4 8 2}Dury, G.H. 1963. 
{it:The East Midlands and the Peak.} 
London: Thomas Nelson. 

{p 4 8 2}The Economist. 2015. 
The Fed's interest-rate projections: Dotty. June 13, p.74 UK edition. 
{browse "http://www.economist.com/news/finance-and-economics/21654095-chart-intended-provide-insight-actually-sows-confusion-dotty":online}

{p 4 8 2}Eddy, W.F. 1979. 
Comment.
{it:Journal, American Statistical Association} 74: 124{c -}126. 

{p 4 8 2}Edwards, D. 2000. 
{it:Introduction to Graphical Modelling.} 
New York: Springer. 

{p 4 8 2}Efron, B. and T. Hastie. 2016.
{it:Computer Age Statistical Inference.} 
New York: Cambridge University Press. 

{p 4 8 2}Eklund, A. 2013. 
Package beeswarm. 
{browse "http://cran.r-project.org/web/packages/beeswarm/beeswarm.pdf":http://cran.r-project.org/web/packages/beeswarm/beeswarm.pdf}
[accessed 16 April 2013] 

{p 4 8 2}Ellison, A.M. 1993. 
Exploratory data analysis and graphic display. 
In Scheiner, S.M. and J. Gurevitch (eds) 
{it:Design and Analysis of Ecological Experiments.} 
New York: Chapman and Hall, 14{c -}45. 

{p 4 8 2}Ellison, A.M. 2001. 
Exploratory data analysis and graphic display. 
In Scheiner, S.M. and J. Gurevitch (eds) 
{it:Design and Analysis of Ecological Experiments.} 
New York: Oxford University Press, 37{c -}62. 

{p 4 8 2}Esty, W.W. and J.D. Banfield. 2003. The box-percentile plot. 
{it:Journal of Statistical Software} 8(17) 
{browse "https://www.jstatsoft.org/index.php/jss/article/view/v008i17/BoxPercentilePlot.pdf":https://www.jstatsoft.org/index.php/jss/article/view/v008i17/BoxPercentilePlot.pdf}

{p 4 8 2}Evans, I.S. and N.J. Cox. 2017. Comparability of cirque size and 
shape measures between regions and between researchers.  
{it:Zeitschrift f{c u:}r Geomorphologie} 61 SupplementBand 2: 81{c -}103.  

{p 4 8 2}Everitt, B.S., S. Landau, M. Leese and D. Stahl. 2011. 
{it:Cluster Analysis}. Chichester: John Wiley. See p.23. 

{p 4 8 2}Everitt, B.S. and A. Skrondal. 2010. 
{it:The Cambridge Dictionary of Statistics.}
Cambridge: Cambridge University Press. 

{p 4 8 2}Fahrmeir, L., T. Kneib, S. Lang and B. Marx. 2013. 
{it:Regression: Models, Methods and Applications.} 
Berlin: Springer. 

{p 4 8 2}Fan, J. and I. Gijbels. 1996. 
{it:Local Polynomial Modelling and Its Applications.} 
London: Chapman and Hall. See pp.2, 6, 16, 48, 134, 140, 141, 198, 270, 282.  

{p 4 8 2}Faraway, J.J. 2005. {it:Linear Models with R.} 
Boca Raton, FL: Chapman and Hall/CRC. [2nd edition 2014] 

{p 4 8 2}Farmer, B.H. 1956. 
Rainfall and water-supply in the Dry Zone of Ceylon. 
In Steel, R.W. and C.A. Fisher (eds) 
{it:Geographical Essays on British Tropical Lands.}
London: George Philip, 227{c -}268. 

{p 4 8 2}Fauth, J.E. and W.J. Resetarits. 1999. 
Biting in the salamander {it:Siren intermedia intermedia}: 
Courtship component or agonistic behavior?  
{it:Journal of Herpetology} 33: 493{c -}496. 

{p 4 8 2}Feigelson, E. D. and G. J. Babu. 2012. 
{it:Modern Statistical Methods for Astronomy with R Applications}. 
Cambridge: Cambridge University Press. 

{p 4 8 2}Feinstein, A.R. 2002. {it:Principles of Medical Statistics.} 
Boca Raton, FL: Chapman and Hall/CRC.
 
{p 4 8 2}Few, S. 2009.
{it:Now You See It: Simple Visualization Techniques for Quantitative Analysis}.
Oakland, CA: Analytics Press.

{p 4 8 2}Few, S. 2012. 
{it:Show Me the Numbers: Designing Tables and Graphs to Enlighten.} 
Burlingame, CA: Analytics Press. 

{p 4 8 2}Few, S. 2015. 
{it:Signal: Understanding What Matters in a World of Noise.} 
Burlingame, CA: Analytics Press.

{p 4 8 2}Few, S. 2017. 
The DataVis jitterbug: let’s improve an old dance.  
{browse "https://www.perceptualedge.com/articles/visual_business_intelligence/the_datavis_jitterbug.pdf":https://www.perceptualedge.com/articles/visual_business_intelligence/the_datavis_jitterbug.pdf}

{p 4 8 2}Few, S. 2020. 
{it:Now You See It: An Introduction to Visual Sensemaking.}.
El Dorado Hills, CA: Analytics Press.

{p 4 8 2}Field, K. 2018. 
{it:Cartography.} 
Redlands, CA: Esri Press. See pp.19, 159. 

{p 4 8 2}Field, K. 2021. 
{it:Thematic Cartography: 101 Inspiring Ways to Visualise Empirical Data.}
Redlands, CA: Esri Press. See p.141. 

{p 4 8 2}Field, R. 2003. The handling and presentation of geographical 
data. In Clifford, N. and G. Valentine (eds) 
{it:Key Methods in Geography}. 
London: SAGE, 309{c -}341. 

{p 4 8 2}Field, R. 2010. Data handling and representation. 
In Clifford, N., S. French and G. Valentine (eds) 
{it:Key Methods in Geography}. 
London: SAGE, 317{c -}349. 

{p 4 8 2}Field, R. 2016. Exploring and presenting geographical data. 
In Clifford, N., M. Cope, T. Gillespie and S. French (eds) 
{it:Key Methods in Geography}. 
London: SAGE, 550{c -}580. 

{p 4 8 2}Filzmoser, P., K. Hron and M. Templ. 2018.
{it:Applied Compositional Data Analysis: With Worked Examples in R.} 
Cham: Springer.

{p 4 8 2}Fisher, R.A. 1925. 
{it:Statistical Methods for Research Workers.}
Edinburgh: Oliver and Boyd. Later editions to 1973. New York: Hafner. 

{p 4 8 2}Fisher, R.A. 1936. 
The use of multiple measurements in taxonomic problems. 
{it:Annals of Eugenics} 7: 179{c -}188.  

{p 4 8 2}
Flury, B. 1997. {it:A First Course in Multivariate Analysis.}
New York: Springer. See pp.4-5. 

{p 4 8 2}
Flury, B. and H. Riedwyl. 1988. 
{it:Multivariate Statistics: A Practical Approach.} 
London: Chapman and Hall. See p.134 

{p 4 8 2}
Fox, J. 1990. Describing univariate distributions. 
In Fox, J. and J.S. Long (eds) 
{it:Modern Methods of Data Analysis.} 
Newbury Park, CA: SAGE, 58{c -}125. 

{p 4 8 2}Freeman, J.V., S.J. Walters and M.J. Campbell. 2008. 
{it:How to Display Data.}
Malden, MA: BMJ Books/Blackwell Publishing. 

{p 4 8 2}Friendly, M. 2000. 
{it:Visualizing Categorical Data.} 
Cary, NC: SAS Institute.

{p 4 8 2}Friendly, M. 2008. 
A brief history of data visualization. 
In Chen, C., W. H{c a:}rdle and A. Unwin (eds) 
{it:Handbook of Data Visualization.} 
Berlin: Springer, 15{c -}56.  

{p 4 8 2}Friendly, M. and D. Meyer. 2016. 
{it:Discrete Data Analysis with R: Visualization and Modeling Techniques for Categorical and Count Data.}
Boca Raton, FL: CRC Press. 

{p 4 8 2}Friendly, M., P. Valero-Mora and J.I. Ulargui. 2010.
The first (known) statistical graph: Michael Florent van Langren and the "secret" of longitude.
{it:American Statistician} 64: 174{c -}184. (supplementary materials online)

{p 4 8 2}Friendly, M. and H. Wainer. 2021. 
{it:A History of Data Visualization and Graphic Communication.} 
Cambridge, MA: Harvard University Press.  

{p 4 8 2}Frigge, M., D.C. Hoaglin and B. Iglewicz. 1989. 
Some implementations of the boxplot.  
{it:American Statistician} 43: 50{c -}54. 

{p 4 8 2}Galton, F. 1869. 
{it:Hereditary Genius: An Inquiry into its Laws and Consequences.}
London: Macmillan. (second edition 1892) 

{p 4 8 2}Gasser, T. 1996. Advances in nonparametric function estimation. 
In Rieder, A. (ed.) 
{it:Robust Statistics, Data Analysis, and Computer Intensive Methods: In Honor of Peter Huber's 60th Birthday.} 
New York: Springer, 173{c -}184.

{p 4 8 2}
Gause, G.F. 1930. Studies on the ecology of the Orthoptera. 
{it:Ecology} 11: 307{c -}325.

{p 4 8 2}Gelman, A. and J. Hill. 2007.
{it:Data Analysis Using Regression and Multilevel/Hierarchical Models.}
Cambridge: Cambridge University Press. 
rug plots 80, 91, 94, 99, 149, 217, 467

{p 4 8 2}Gerbing, D.W. 2020. 
{it:R Visualizations: Derive Meaning from Data.}
Boca Raton, FL: CRC Press. 

{p 4 8 2}Gershenfeld, N. 1999. 
{it:The Nature of Mathematical Modeling.} 
Cambridge: Cambridge University Press. Rug on p.174.

{p 4 8 2}Gierlinski, M. 2016. 
{it:Understanding Statistical Error: A Primer for Biologists.} 
Chichester: John Wiley. [acute accent on "n"]

{p 4 8 2}Gilder, K. 2012.
Statistical graphics in clinical oncology.                        
In Krause, A. and O'Connell, M. (eds) 
{it:A Picture is Worth a Thousand Tables: Graphics in Life Sciences.} 
New York: Springer, 173{c -}198.  

{p 4 8 2}Girgis, I.G. and S. Mohanty. 2012.
Graphical data exploration in QT model building and cardiovascular drug safety. 
In Krause, A. and O'Connell, M. (eds) 
{it:A Picture is Worth a Thousand Tables: Graphics in Life Sciences.} 
New York: Springer, 255{c -}271.  

{p 4 8 2}Goldstein, R. 1996. 
Mountain plots. {it:Stata Technical Bulletin} 33: 9{c -}10. 

{p 4 8 2}Gonick, L. and W. Smith. 1993. 
{it:The Cartoon Guide to Statistics.} 
New York: HarperCollins. See pp.9, 20, 24, 25, 177.

{p 4 8 2}Good, P.I. and J.W. Hardin. 2003. 
{it:Common Errors in Statistics (and How to Avoid Them).} 
Hoboken, NJ: John Wiley. strip plots pp.46, 99 [uses term rug plot], 114. box plot with mean p.98  
[4th edition 2012] 

{p 4 8 2}Goos, P. and D. Meintrup. 2015. 
{it:Statistics with JMP: Graphs, Descriptive Statistics and Probability.} 
Chichester: John Wiley. 

{p 4 8 2}Goos, P. and D. Meintrup. 2016. 
{it:Statistics with JMP: Hypothesis Tests, ANOVA and Regression.} 
Chichester: John Wiley. 

{p 4 8 2}Gotelli, N.J. and A.M. Ellison. 2004 (second edition 2013). 
{it:A Primer of Ecological Statistics.} Sunderland, MA: Sinauer. 

{p 4 8 2}
Gower, J.C., S.G. Lubbe and N. le Roux. 2011. 
{it:Understanding Biplots.} 
Chichester: John Wiley. 

{p 4 8 2}
Grafen, A. and R. Hails. 2002. 
{it:Modern Statistics for the Life Sciences.} 
Oxford: Oxford University Press. 

{p 4 8 2}
Grant, R. 2019. 
{it:Data Visualization: Charts, Maps, and Interactive Graphics.} 
Boca Raton, FL: CRC Press. 

{p 4 8 2}
Green, P.J. 1981. 
Peeling bivariate data. 
In Barnett, V. (ed.) {it:Interpreting Multivariate Data.} 
Chichester: John Wiley, 3{c -}19. 

{p 4 8 2}
Green, P.J. 2020. 
Allan Henry Seheult, 1942{c -}2019. 
{it:Journal, Royal Statistical Society Series A} 183: 1318{c -}1319. 

{p 4 8 2}
Greenacre, M. 2016. 
Data reporting and visualization in ecology. 
{it:Polar Biology} 39: 2189{c -}2205.

{p 4 8 2}
Greenacre, M. 2017. 
{it:Correspondence Analysis in Practice.} 
Boca Raton, FL: CRC Press. See p.234.  

{p 4 8 2}
Greenacre, M. 2019. 
{it:Compositional Data Analysis in Practice.} 
Boca Raton, FL: CRC Press. 

{p 4 8 2}
Greenacre, M. and R. Primicerio. 2013. 
{it:Multivariate Analysis of Ecological Data.} 
Bilbao: Fundaci{c o'}n BBVA.   
 
{p 4 8 2}Gregory, S. 1963. {it:Statistical Methods and the Geographer.} 
London: Longmans. (later editions 1968, 1973, 1978; publisher later Longman)

{p 4 8 2}Griffiths, D., W.D. Stirling and K.L. Weldon. 1998. 
{it:Understanding Data: Principles and Practice of Statistics.} 
Brisbane: John Wiley. 

{p 4 8 2}
Grove, A.T. 1956. Soil erosion in Nigeria. In Steel, R.W. and C.A. Fisher (eds)
{it:Geographical Essays on British Tropical Lands.}
London: George Philip, 79{c -}111.

{p 4 8 2}Guevara, J. and L. Avil{c e'}s. 2007. 
Multiple techniques confirm elevational differences in insect size that may influence spider sociality. 
{it:Ecology} 88: 2015{c -}2023. 

{p 4 8 2}Guttorp, P. 1995. 
{it:Stochastic Modeling of Scientific Data.}
London: Chapman and Hall. 

{p 4 8 2}
Haemer, K.W. 1948. 
Range-bar charts.  
{it:American Statistician} 2(2): 23.

{p 4 8 2}
Haggett, P. 1965. 
{it:Locational Analysis in Human Geography.} 
London: Edward Arnold. 

{p 4 8 2}
Haggett, P. 1972. 
{it:Geography: A Modern Synthesis.} 
New York: Harper and Row. 

{p 4 8 2}Hald, A. 1952. 
{it:Statistical Theory with Engineering Applications.} 
New York: John Wiley.

{p 4 8 2}Hald, A. 1990. 
{it:A History of Probability and Statistics and Their Applications before 1750.}
New York: John Wiley. See p.158. 

{p 4 8 2}Hamilton, L.C. 1992. 
{it:Regression with Graphics: A Second Course in Applied Statistics.} 
Belmont, CA: Duxbury. 

{p 4 8 2}Hammer, {c O/}. and D.A.T. Harper. 2006. 
{it:Paleontological Data Analysis.} 
Malden, MA: Blackwell. See p.284.

{p 4 8 2}Hammer, {c O/}. and D.A.T. Harper. 2024. 
{it:Paleontological Data Analysis.} 
Hoboken, NJ: John Wiley. See p.304. 

{p 4 8 2}Hammond, R. and P.S. McCullagh. 1974. 
{it:Quantitative Techniques in Geography: An Introduction.} 
London: Oxford University Press. 

{p 4 8 2}H{c a:}rdle, W. 1990. 
{it:Applied Nonparametric Regression.} 
Cambridge: Cambridge University Press. 

{p 4 8 2}H{c a:}rdle, W. 1991. 
{it:Smoothing Techniques with Implementation in S.}
New York: Springer.

{p 4 8 2}H{c a:}rdle, W., R.A. Moro and D. Sch{c a:}fer. 2008. 
Graphical data representation in bankruptcy analysis. 
In Chen, C., W. H{c a:}rdle and A. Unwin (eds) 
{it:Handbook of Data Visualization.} 
Berlin: Springer, 853{c -}872.  

{p 4 8 2}Harrell, F.E. 2001. 
{it:Regression Modeling Strategies: With Applications to Linear Models, Logistic Regression, and Survival Analysis}.
New York: Springer. 
    
{p 4 8 2}Harrell, F.E. 2015. 
{it:Regression Modeling Strategies: With Applications to Linear Models, Logistic and Ordinal Regression, and Survival Analysis}.
Cham: Springer. 

{p 4 8 2}
Harris, R. 2016. 
{it:Quantitative Geography: The Basics.} 
London: SAGE. 

{p 4 8 2}Harris, R. and C. Jarvis. 2011. 
{it:Statistics for Geography and Environmental Science.} 
Harlow: Prentice Hall. 

{p 4 8 2}Harris, R.L. 1999. 
{it:Information Graphics: A Comprehensive Illustrated Reference.} 
New York: Oxford University Press. 

{p 4 8 2}Hastie, T. 1992. Generalized additive models. 
In Chambers, J.M. and T. Hastie (eds) 
{it:Statistical Models in S.} 
Pacific Grove, CA: Wadsworth and Brooks/Cole, 249{c -}307. 

{p 4 8 2}Hastie, T.J. and R.J. Tibshirani. 1986. 
Generalized additive models. 
{it:Statistical Science} 1: 297{c -}310.
https://doi.org/10.1214/ss/1177013604

{p 4 8 2}Hastie, T.J. and R.J. Tibshirani. 1990. 
{it:Generalized Additive Models.} 
London: Chapman and Hall. 

{p 4 8 2}Hastie, T.J., R.J. Tibshirani and J.H. Friedman. 2009. 
{it:The Elements of Statistical Learning: Data Mining, Inference, and Prediction.} 
New York: Springer. 

{p 4 8 2}Hay, I. 1996. 
{it:Communicating in Geography and the Environmental Sciences.}
Melbourne: Oxford University Press. (later editions 2002, 2006, 2012) 

{p 4 8 2}Healy, K. 2019. 
{it:Data Visualization: A Practical Introduction.} 
Princeton, NJ: Princeton University Press. 

{p 4 8 2}Hector, A. 2015. 
{it:The New Statistics with R: An Introduction for Biologists.}
Oxford: Oxford University Press. 

{p 4 8 2}Hector, A. 2021. 
{it:The New Statistics with R: An Introduction for Biologists.}
Oxford: Oxford University Press. 

{p 4 8 2}Heiberger, R.M. and B. Holland. 2004. 
{it:Statistical Analysis and Data Display: An Intermediate Course with Examples in S-PLUS, R, and SAS.}
New York: Springer. 

{p 4 8 2}Heiberger, R.M. and B. Holland. 2015. 
{it:Statistical Analysis and Data Display: An Intermediate Course with Examples in R.}
New York: Springer. 

{p 4 8 2}Helsel, D.R. and R.M. Hirsch. 1992. 
{it:Statistical Methods in Water Resources.} 
Amsterdam: Elsevier. 

{p 4 8 2}Hendry, D.F. and B. Nielsen. 2007. 
{it:Econometric Modeling: A Likelihood Approach.} 
Princeton, NJ: Princeton University Press. 

{p 4 8 2}Henry, G.T. 1995. 
{it:Graphing Data: Techniques for Display and Analysis.}
Thousand Oaks, CA: SAGE. 
See pp.5, 133, 137, 139, 141 (strip plots); 42, 68 (Cleveland dot charts). 
See p.82 for an example in which a histogram is better than a box plot 
for a bimodal distribution. 

{p 4 8 2}Hilfiger, J.J. 2016.
{it:Graphing Data with R.} 
Sebastopol, CA: O'Reilly. 

{p 4 8 2}Hill, M. and W.J. Dixon. 1982. 
Robustness in real life: a study of clinical laboratory data.
{it:Biometrics} 38: 377{c -}396.

{p 4 8 2}Hoaglin, D.C., F. Mosteller and J.W. Tukey (eds). 1991. 
{it:Fundamentals of Exploratory Analysis of Variance.} 
New York: John Wiley. 

{p 4 8 2}Hoffmann, J.P. 2017. 
{it:Principles of Data Management and Presentation.} 
Oakland, CA: University of California Press. 

{p 4 8 2}Hogg, W.H. 1948. 
Rainfall dispersion diagrams: a discussion of their advantages and
disadvantages. 
{it:Geography} 33: 31{c -}37. 

{p 4 8 2}Holmes, S. and W. Huber. 2019. 
{it:Modern Statistics for Modern Biology.} 
Cambridge: Cambridge University Press. 

{p 4 8 2}Huh, M.Y. 1995. 
Exploring multidimensional data with the flipped empirical distribution 
function. 
{it:Journal of Computational and Graphical Statistics} 
4: 335{c -}343. 

{p 4 8 2}Humphreys, R.K. and G.D. Ruxton. 2022.
{it:Presenting Scientific Data in R: Creating Effective Graphs and Figures.}
Oxford: Oxford University Press. 

{p 4 8 2}Hutchinson, T.P. 1993. 
{it:Essentials of Statistical Methods, in 41 Pages.} 
Sydney: Rumsby Scientific Publishing. 

{p 4 8 2}Ibrekk, H. and M.G. Morgan. 1987. 
Graphical communication of uncertain quantities to nontechnical people. 
{it:Risk Analysis} 7: 519{c -}529.

{p 4 8 2}Irizarry, R.A. 2020.
{it:Introduction to Data Science: Data Analysis and Prediction Algorithms with R.}
Boca Raton, FL: CRC Press.

{p 4 8 2}Irizarry, R.A. 2025.
{it:Introduction to Data Science: Data Wrangling and Visualization with R.}
Boca Raton, FL: CRC Press.
 
{p 4 8 2}Irizarry, R.A. and M.I. Love. 2017. 
{it:Data Analysis for the Life Sciences with R.}
Boca Raton, FL: CRC Press. 

{p 4 8 2}
Jacoby, W.G. 1997. 
{it:Statistical Graphics for Univariate and Bivariate Data.} 
Thousand Oaks, CA: SAGE. 

{p 4 8 2}
Jacoby, W.G. 2006. 
The dot plot: a graphical display for labeled quantitative values.
{it:The Political Methodologist} 14(1): 6{c -}14.

{p 4 8 2}
James, G., D. Witten, T. Hastie and R. Tibshirani. 2013. 
{it:An Introduction to Statistical Learning with Applications in R.} 
New York: Springer. 

{p 4 8 2}
Janert, P.K. 2011. 
{it:Data Analysis with Open Source Tools.} 
Sebastopol, CA: O'Reilly. 

{p 4 8 2}
Jevons, W.S. 1884. 
{it:Investigations in Currency and Finance.} 
London: Macmillan. 

{p 4 8 2}
Jewell, N.P. 2004. 
{it:Statistics for Epidemiology.}
Boca Raton, FL: Chapman & Hall/CRC. rugs pp.286, 287. 

{p 4 8 2}
Johnson, B.L.C. 1975. 
{it:Bangladesh.} London: Heinemann Educational.

{p 4 8 2}
Johnson, V.E. and J.H. Albert. 1999. 
{it:Ordinal Data Modeling.} 
New York: Springer. 

{p 4 8 2}
Johnston, R.J. 1978. 
{it:Multivariate Statistical Analysis in Geography: A Primer on the General Linear Model.}
London: Longman.  

{p 4 8 2}
Johnston, R.J. 2019. 
Percy Crowe: A forgotten pioneer quantitative geographer and climatologist. 
{it:Progress in Physical Geography} 
43: 586{c -}600. 
DOI:10.1177/0309133319843430. 

{p 4 8 2}
Jongman, R.H.G., C.J.F. ter Braak and O.F.R. van Tongeren (eds) 1995. 
{it:Data Analysis in Community and Landscape Ecology.} 
Cambridge: Cambridge University Press. 

{p 4 8 2}
Jones, K. and G. Moon. 1987. 
{it:Health, Disease and Society: A Critical Medical Geography.} 
London: Routledge and Kegan Paul.

{p 4 8 2}
Kabacoff, R. 2024.
{it:Modern Data Visualization with R.}
Boca Raton, FL: CRC Press. 

{p 4 8 2}
Karsten, K.G. 1923. 
{it:Charts and Graphs: An Introduction to Graphic Methods in the Control and Analysis of Statistics.}
New York: Prentice-Hall.  

{p 4 8 2}
Kass, R.E., U.T. Eden and E.N. Brown. 2014. 
{it:Analysis of Neural Data.} 
New York: Springer. 

{p 4 8 2}Keen, K.J. 2010. 
{it:Graphics for Statistics and Data Analysis with R.} 
Boca Raton, FL: CRC Press. (second edition 2018)

{p 4 8 2}Kendall, D.G. 1971. 
Seriation from abundance matrices. 
In Kendall, D.G., F.R. Hodson and P. Tautu (eds) 
{it:Mathematics in the Archaeological and Historical Sciences.} 
Edinburgh: Edinburgh University Press, 215{c -}252. See p.236. 
[breve accent on a of Tautu] 

{p 4 8 2}
Kent, M. 2012. 
{it:Vegetation Description and Data Analysis.} 
Chichester: John Wiley. 

{p 4 8 2}
Kent, M. and P. Coker. 1994. 
{it:Vegetation Description and Analysis.} 
Chichester: John Wiley. 

{p 4 8 2}Kirk, A. 2012. 
{it:Data Visualization: A Successful Design Process.} 
Birmingham: Packt. 

{p 4 8 2}Kirk, A. 2016. 
{it:Data Visualization: A Handbook for Data Driven Design.} 
London: SAGE. 

{p 4 8 2}Kirk, A. 2025. 
{it:Data Visualisation: A Handbook for Data Driven Design.} 
London: Sage. 

{p 4 8 2}Kleiner, B. and T.E. Graedel. 1980. 
Exploratory data analysis in the geophysical sciences. 
{it:Reviews of Geophysics and Space Physics} 18: 699{c -}717. 

{p 4 8 2}Klemel{c a:}, J. 2009. 
{it:Smoothing of Multivariate Data: Density Estimation and Visualization.} 
Hoboken, NJ: John Wiley.

{p 4 8 2}Koch, G.S. and R.F. Link. 1971. 
{it:Statistical Analysis of Geological Data.}
New York: John Wiley. See p.78. 

{p 4 8 2}Koponen, J. and J. Hild{c e'}n. 2019. 
{it:The Data Visualization Handbook.} 
Espoo: Aalto ARTS Books. 

{p 4 8 2}Krause, A. and M. O'Connell. (eds) 2012. 
{it:A Picture is Worth a Thousand Tables: Graphics in Life Sciences.} 
New York: Springer.  

{p 4 8 2} 
Kriebel, A. and E. Murray. 2018. 
{it:#MakeoverMonday: Improving How We Visualize and Analyze Data, One Chart at a Time.} 
Hoboken, NJ: John Wiley. 

{p 4 8 2}Krieg, A.F., J.R. Beck and M.B. Bongiovanni. 1988. 
The dot plot: a starting point for evaluating test performance. 
{it:Journal, American Medical Association} 260: 3309{c -}3312. 

{p 4 8 2}Krouwer, J.S. 1992. 
Estimating total analytical error and its sources. Techniques to improve method evaluation. 
{it:Archives of Pathology and Laboratory Medicine} 116: 726{c -}731. 

{p 4 8 2}
Krouwer, J.S. and K.L. Monti. 1995. 
A simple, graphical method to evaluate laboratory assays. 
{it:European Journal of Clinical Chemistry and Clinical Biochemistry}
33: 525{c -}528.

{p 4 8 2}
Kubina, R.M., D.E. Kostewicz, K.M. Brennan and S.A. King. 2017. 
A crtical review of line graphs in behavior analytic journals. 
{it:Educational Psychology Review} 20: 583{c -}598. 

{p 4 8 2}
Lane, D.M. and A. S{c a'}ndor. 2009. 
Designing better graphs by including distributional information and integrating words, numbers, and images. 
{it:Psychological Methods} 14: 239{c -}257. 
{browse "https://doi.org/10.1037/a0016620":https://doi.org/10.1037/a0016620} 

{p 4 8 2}Lang, T.A. and M. Secic. 2006. 
{it:How to Report Statistics in Medicine: Annotated Guidelines for Authors, Editors, and Reviewers.} 
Philadelphia: American College of Physicians. 

{p 4 8 2}Langren, Michael Florent van. 1644. 
{it:La Verdadera Longitud por Mar y Tierra.} Antwerp. 

{p 4 8 2}Lee, J.J. and Z.N. Tu. 1997. 
A versatile one-dimensional distribution plot: the BLiP plot. 
{it:American Statistician}
51: 353{c -}358.

{p 4 8 2}
Lee, P.M. 2012. 
{it:Bayesian Statistics: An Introduction.} 
Chichester: John Wiley. p.331 

{p 4 8 2}
Legendre, P. and L. Legendre. 2012. 
{it:Numerical Ecology.} 
Amsterdam: Elsevier. See p.585.  

{p 4 8 2}
Lehmann, E.L. 1975. 
{it:Nonparametrics: Statistical Methods Based on Ranks.} 
San Francisco, CA: Holden-Day.
 
{p 4 8 2}
Lehmann, E.L. 1998. 
{it:Nonparametrics: Statistical Methods Based on Ranks.} 
Englewood Cliffs, NJ: Prentice-Hall. 

{p 4 8 2}Leisch, F. 2010.  
Neighborhood graphs, stripes and shadow plots for cluster visualization. 
{it:Statistics and Computing} 20: 457{c -}469. 
[Friedrich Leisch 1968{c -}2024]

{p 4 8 2}Lembo, A.J. Jr and J.C. McGrew, Jr. 2024. 
{it:An Introduction to Statistical Problem Solving in Geography.} 
Long Grove, IL: Waveland Press. 

{p 4 8 2}Lewis, C.R. 1975. 
The analysis of changes in urban status: a case study in Mid-Wales and the 
middle Welsh borderland. 
{it:Transactions of the Institute of British Geographers}
64: 49{c -}65. 

{p 4 8 2}Lewis, P. 1977. 
{it:Maps and Statistics.} 
London: Methuen. 

{p 4 8 2}Light, R.J. and D.B. Pillemer. 1984. 
{it:Summing Up: The Science of Reviewing Research.}
Cambridge, MA: Harvard University Press. 

{p 4 8 2}
Lord, S.J., K.B. Velle, R.D. Mullins, and L.K. Fritz-Laylin. 2020. 
SuperPlots: Communicating reproducibility and variability in cell biology. 
{it:Journal of Cell Biology} 219(6): e202001064. doi: 10.1083/jcb.202001064. 

{p 4 8 2}Madansky, A. 1988. 
{it:Prescriptions for Working Statisticians.} 
New York: Springer. 

{p 4 8 2}Maindonald, J.H. and W.J. Braun. 2003. 
{it:Data Analysis and Graphics Using R {c -} An Example-based Approach.} 
Cambridge: Cambridge University Press. (later editions 2007, 2010) 

{p 4 8 2}Maindonald, J.H., W.J. Braun and J.L. Andrews. 2024. 
{it:A Practical Guide to Data Analysis Using R: An Example-Based Approach.}
Cambridge: Cambridge University Press.

{p 4 8 2}Manly, B.F.J. 2001. 
{it:Statistics for Environmental Science and Management.} 
Boca Raton, FL: Chapman and Hall/CRC Press. 

{p 4 8 2}Mardia, K.V., J.T. Kent and J.M. Bibby. 1979. 
{it:Multivariate Analysis.}
London: Academic Press. 

{p 4 8 2}Maronna, R.A., R.D. Martin, and V.J. Yohai. 
2006. {it:Robust Statistics: Theory and Methods.} 
Hoboken, NJ: John Wiley. 

{p 4 8 2}Maronna, R.A., R.D. Martin, V.J. Yohai and M. Salibi{c a'}n-Barrera. 
2019. {it:Robust Statistics: Theory and Methods (With R).} 
Hoboken, NJ: John Wiley.
 
{p 4 8 2}Martinez, W.L., A.R. Martinez and J.L. Solka. 2011. 
{it:Exploratory Data Analysis with MATLAB.} 
Boca Raton, FL: CRC Press.

{p 4 8 2}Martinez, W.L., A.R. Martinez and J.L. Solka. 2017. 
{it:Exploratory Data Analysis with MATLAB.} 
Boca Raton, FL: CRC Press. 

{p 4 8 2}Matthews, H.A. 1936.
A new view of some familiar Indian rainfalls.
{it:Scottish Geographical Magazine} 52: 84{c -}97. 

{p 4 8 2}Matthews, J.A. 1981. 
{it:Quantitative and Statistical Approaches to Geography: A Practical Manual.} 
Oxford: Pergamon. 

{p 4 8 2}Matthiopoulos, J. 2011. 
{it:How to be a Quantitative Ecologist: The 'A to R' of Green Mathematics and Statistics.} 
Chichester: John Wiley. 

{p 4 8 2}McCall, W.A. 1939. 
{it:Measurement.} New York: Macmillan. 

{p 4 8 2}McDaniel, E. and S. McDaniel. 2012a. 
{it:The Accidental Analyst: Show Your Data Who's Boss.}
Seattle, WA: Freakalytics.

{p 4 8 2}McDaniel, S. and E. McDaniel. 2012b. 
{it:Rapid Graphs with Tableau 7: Create Intuitive, Actionable Insights in Just 15 Days.}
Seattle, WA: Freakalytics.

{p 4 8 2}
McGill, R., J.W. Tukey and W.A. Larsen. 1978. 
Variations of box plots.  
{it:American Statistician} 32: 12{c -}16. 

{p 4 8 2}McGrew, J.C. Jr and C.B. Monroe. 1993. 
{it:An Introduction to Statistical Problem Solving in Geography.} 
Dubuque, IA: Wm. C. Brown. 

{p 4 8 2}McGrew, J.C. Jr and C.B. Monroe. 2000. 
{it:An Introduction to Statistical Problem Solving in Geography.} 
Boston, MA: McGraw-Hill. 

{p 4 8 2}McGrew, J.C. Jr, A.J. Lembo Jr, and C.B. Monroe. 2014. 
{it:An Introduction to Statistical Problem Solving in Geography.} 
Long Grove, IL: Waveland Press. 

{p 4 8 2}McKillup, S. 2005. 
{it:Statistics Explained: An Introductory Guide for Life Scientists.} 
Cambridge: Cambridge University Press. (second edition 2012) 

{p 4 8 2}McKillup, S. and M.D. Dyar. 2010. 
{it:Geostatistics Explained: An Introductory Guide for Earth Scientists.} 
Cambridge: Cambridge University Press. 

{p 4 8 2}McNeil, D. 1996. 
{it:Epidemiological Research Methods.} 
Chichester: John Wiley. 

{p 4 8 2}Mead, R., R. N. Curnow and A. M. Hasted. 2003. 
{it:Statistical Methods in Agriculture and Experimental Biology.} 
Boca Raton, FL: Chapman and Hall/CRC. See pp.162, 427. 

{p 4 8 2}Meloun, M. and J. Militk{c y'}. 1994. 
Computer-assisted data treatment in analytical chemometrics.
I. Exploratory analysis of univariate data. 
{it:Chemical Papers} 48: 151{c -}157. 

{p 4 8 2}Militk{c y'}, J. and M. Meloun. 1993. 
Some graphical aids for univariate exploratory data analysis. 
{it:Analytica Chimica Acta} 277: 215{c -}221. 

{p 4 8 2}Millard, S.P. 1998. 
{it:EnvironmentalStats for S-Plus: User's Manual for Windows and UNIX.}
New York: Springer. [2nd edition 2002] 

{p 4 8 2}Millard, S.P. 2013. 
{it:EnvStats: An R Package for Environmental Statistics.} 
New York: Springer. 

{p 4 8 2}Millard, S.P. and N.K. Neerchal. 2001. 
{it:Environmental Statistics with S-Plus}.  
Boca Raton, FL: CRC Press. 

{p 4 8 2}Miller, A.A. 1953. 
{it:The Skin of the Earth.} 
London: Methuen. (2nd edition 1964) See 1953, p.130. 
 
{p 4 8 2}Minnotte, M.C., S.R. Sain and D.W. Scott. 2008. 
Multivariate visualization by density estimation. 
In Chen, C., W. H{c a:}rdle and A. Unwin (eds) 
{it:Handbook of Data Visualization.} 
Berlin: Springer, 389{c -}413.  

{p 4 8 2}Mitchell, P.L. 2010. 
Replacing the pie chart, and other graphical grouses. 
{it:Bulletin of the British Ecological Society} 41(1): 58{c -}60. 

{p 4 8 2}Monkhouse, F.J. and H.R. Wilkinson. 1952. 
{it:Maps and Diagrams: Their Compilation and Construction.} 
London: Methuen. (later editions 1963, 1971)

{p 4 8 2}Monmonier, M. 1991. 
{it:How to Lie with Maps.} 
Chicago: University of Chicago Press. (later editions 1996, 2018)

{p 4 8 2}Monmonier, M. 1993. 
{it:Mapping It Out: Expository Cartography for the Humanities and Social Sciences.} 
Chicago: University of Chicago Press. 

{p 4 8 2}
Monti, K.L. 1995. 
Folded empirical distribution function curves{c -}mountain plots. 
{it:American Statistician} 49: 342{c -}345.

{p 4 8 2}
Moore, D.S. and G.P. McCabe. 1989. 
{it:Introduction to the Practice of Statistics.} 
New York: W.H. Freeman. Many later editions, latterly with B.A. Craig as third
author, but none checked to see whether mention of boxplot whiskers to 10% and
90% points persists.

{p 4 8 2}Moore, R.E.N. 1971. 
A relationship observed between mosaic units and the sizes of Roman mosaic stones. 
In Kendall, D.G., F.R. Hodson and P. Tautu (eds) 
{it:Mathematics in the Archaeological and Historical Sciences.} 
Edinburgh: Edinburgh University Press, 445{c -}452. See p.448. 
[breve accent on a of Tautu] 

{p 4 8 2}Morgan, M.G. and M. Henrion. 1990. 
{it:Uncertainty: A Guide to Dealing with Uncertainty in Quantitative Risk and Policy Analysis.} 
Cambridge: Cambridge University Press. 

{p 4 8 2}Morgenthaler, S. 2007. 
{it:Introduction {c a'g} la Statistique}. 
Lausanne: Presses polytechniques et universitaires romandes. 

{p 4 8 2}Moroney, M.J. 1956. 
{it:Facts from Figures.} 
Harmondsworth: Penguin. (previous editions 1951, 1953) 

{p 4 8 2}Morrocco, S.M. and C.K. Ballantyne. 2008. 
Footpath morphology and terrain sensitivity on high plateaux: 
the Mamore Mountains, Western Highlands of Scotland. 
{it:Earth Surface Processes and Landforms} 33: 40{c -}54. 

{p 4 8 2}Mosteller, F. and J.W. Tukey. 1977. 
{it:Data Analysis and Regression: A Second Course in Statistics.} 
Reading, MA: Addison-Wesley. 

{p 4 8 2}Mosteller, F. and D.L. Wallace. 1984. 
{it:Applied Bayesian and Classical Inference: The Case of the Federalist Papers.} 
New York: Springer. 

{p 4 8 2}Mosteller, F. and D.L. Wallace. 2007.
{it:Inference and Disputed Authorship: The Federalist.}
Stanford, CA: CSLI Publications. 

{p 4 8 2}Motulsky, H. 1995. 
{it:Intuitive Biostatistics.}
New York: Oxford University Press. (later editions 2010, 2014, 2018 
add subtitle {it:A Nonmathematical Guide to Statistical Thinking}) 

{p 4 8 2}Mudelsee, M. 2020. 
{it:Statistical Analysis of Climate Extremes.} 
Cambridge: Cambridge University Press. 

{p 4 8 2}Murphy, E.A. 1979. 
{it:Probability in Medicine.} 
Baltimore: Johns Hopkins University Press. See p.67.

{p 4 8 2}Murphy, E.A. 1982. 
{it:Biostatistics in Medicine.}  
Baltimore: Johns Hopkins University Press. See p.267.

{p 4 8 2}Murphy, E.A. 1985. 
{it:A Companion to Medical Statistics.}
Baltimore: Johns Hopkins University Press. See p.61. 

{p 4 8 2}Murphy, E.A. 1997. 
{it:The Logic of Medicine.} 
Baltimore: Johns Hopkins University Press. 

{p 4 8 2}Myatt, G.J. 2007. 
{it:Making Sense of Data: A Practical Guide to Exploratory Data Analysis and Data Mining.}
Hoboken, NJ: John Wiley. 

{p 4 8 2}Myatt, G.J. and Johnson, W.P. 2009. 
{it:Making Sense of Data II: A Practical Guide to Data Visualization, Advanced Data Mining Methods, and Applications.}
Hoboken, NJ: John Wiley. 

{p 4 8 2}Myatt, G.J. and Johnson, W.P. 2011. 
{it:Making Sense of Data III: A Practical Guide to Designing Interactive Data Visualizations.}
Hoboken, NJ: John Wiley. 

{p 4 8 2}Naghettini, M. (ed.) 2016. 
{it:Fundmentals of Statistical Hydrology.} 
Cham: Springer. 

{p 4 8 2}Nair, N.U., Sankaran, P.G. and Balakrishnan, N. 2013. 
{it:Quantile-based Reliability Analysis.} 
New York: Springer. 

{p 4 8 2}Nolan, D. and Speed, T. 2000. 
{it:Stat Labs: Mathematical Statistics through Applications.} 
New York: Springer.

{p 4 8 2}Nolan, D. and Stoudt, S. 2021. 
{it:Communicating with Data: The Art of Writing for Data Science.} 
Oxford: Oxford University Press.  

{p 4 8 2}Ottaway, B. 1973. 
Dispersion diagrams: a new approach to the display of carbon-14 dates. 
{it:Archaeometry} 15: 5{c -}12.

{p 4 8 2}Pagano, M. and K. Gauvreau. 1993. 
{it:Principles of Biostatistics.} Belmont, CA: Duxbury.
one-way scatter plot: pp.20, 22, 57; 
box plot with mean: p.42. 
{* Need to check 2nd edition 2000 from Pacific Grove, CA: Duxbury and 3rd edition 2022 with H. Mattie from Boca Raton, FL: CRC Press.}{...}

{p 4 8 2}Park, D., S.-H. Kim and N. Elmqvist. 2023. 
Gatherplot: a non-overlapping scatterplot. 
{browse "https://arxiv.org/abs/2301.10843":https://arxiv.org/abs/2301.10843} 

{p 4 8 2}Parzen, E. 1979a. 
Nonparametric statistical data modeling. 
{it:Journal, American Statistical Association}  
74: 105{c -}121. 

{p 4 8 2}Parzen, E. 1979b. 
A density-quantile function perspective on robust estimation. 
In Launer, R.L. and G.N. Wilkinson (eds) {it:Robustness in Statistics.} 
New York: Academic Press, 237{c -}258. 

{p 4 8 2}Parzen, E. 1982. 
Data modeling using quantile and density-quantile functions. 
In Tiago de Oliveira, J. and B. Epstein (eds) 
{it:Some Recent Advances in Statistics.} London: Academic Press, 
23{c -}52.

{p 4 8 2}Parzen, E. 1997. 
Concrete statistics. In 
Ghosh, S., W.R. Schucany, and W.B. Smith (eds) 
{it:Statistics of Quality}. New York: Marcel Dekker, 309{c -}332. 

{p 4 8 2}Pattie, C. 2020. 
Ron Johnston obituary. 
{browse "https://www.theguardian.com/science/2020/jul/16/ron-johnston-obituary":https://www.theguardian.com/science/2020/jul/16/ron-johnston-obituary}

{p 4 8 2}Peacock, J.L. and P.J. Peacock. 2011. 
{it:Oxford Handbook of Medical Statistics.} 
Oxford: Oxford University Press. See p.197.  

{p 4 8 2}Pearson, E.S. 
1931. The analysis of variance in cases of non-normal variation. 
{it:Biometrika} 23: 114{c -}133. 

{p 4 8 2}Pearson, E.S. 
1938. The probability integral transformation for testing goodness of fit and combining independent tests of significance. 
{it:Biometrika} 30: 134{c -}148. 

{p 4 8 2}Pearson, E. S. 
1939. "Student" as Statistician. 
{it:Biometrika} 30: 210{c -}250. https://doi.org/10.2307/2332648

{p 4 8 2}Pearson, E.S. 1956.
Some aspects of the geometry of statistics: the use of visual 
presentation in understanding the theory and application of mathematical 
statistics. 
{it:Journal of the Royal Statistical Society Series A} 
119: 125{c -}146.

{p 4 8 2}Pearson, E.S. and C. Chandra Sekhar. 
1936. The efficiency of statistical tools and a criterion for the rejection of outlying observations. 
{it:Biometrika} 28: 308{c -}320. 

{p 4 8 2}Pearson, R.K. 2018. 
{it:Exploratory Data Analysis Using R.} 
Boca Raton, FL: CRC Press. See p.239. 

{p 4 8 2}Perpi{c n~}{c a'}n Lamigueiro, O. 2014. 
{it:Displaying Time Series, Spatial, and Space-Time Data with R.} 
Boca Ration, FL: CRC Press. (second edition 2018) 

{p 4 8 2}Pitman, J. 1993. 
{it:Probability.} New York: Springer.

{p 4 8 2}
Potter, K. 2006. 
Methods for presenting statistical information: The box plot.
In Hagen, H., A. Kerren, and P. Dannenmann (Eds.)
{it: Visualization of Large and Unstructured Data Sets, GI-Edition Lecture Notes in Informatics (LNI)} 
S{c -}4: 97{c -}106.

{p 4 8 2}Pritchard, C. 2018. 
{it:A Common Family Weakness for Statistics: Essays on Francis Galton, George Darwin and the Normal Curve of Evolutionary Biology.} 
Leicester: Mathematical Association. 

{p 4 8 2}Quinn, G.P. and M.J. Keough. 2002. 
{it:Experimental Design and Data Analysis for Biologists.} 
Cambridge: Cambridge University Press. See p.60 (dotplot). 

{p 4 8 2}Quinn, G.P. and M.J. Keough. 2024. 
{it:Experimental Design and Data Analysis for Biologists.} 
Cambridge: Cambridge University Press. See pp.64 (dotplot) and 348 (Tufte).

{p 4 8 2}Racine, J.S. 2019. 
{it:An Introduction to the Advanced Theory and Practice of Nonparametric Econometrics: A Replicable Approach Using R.} 
Cambridge: Cambridge University Press. 

{p 4 8 2}Rahlf, T. 2017. 
{it:Data Visualization with R: 100 Examples.}
Cham: Springer. See pp.11, 127.

{p 4 8 2}Rahlf, T. 2019. 
{it:Data Visualization with R: 111 Examples.}
Cham: Springer. See pp.11, 127.

{p 4 8 2}Ramsey, F.L. and D.W. Schafer. 2013. 
{it:The Statistical Sleuth: A Course in Methods of Data Analysis.} 
Boston, MA: Brooks/Cole (previous editions 1996, 2002) 

{p 4 8 2}Reimann, C., P. Filzmoser, R.G. Garrett and R. Dutter. 2008. 
{it:Statistical Data Analysis Explained: Applied Environmental Statistics with R.}
Chichester: John Wiley. 

{p 4 8 2}Reiss, R.-D. and M. Thomas. 1997, 2001, 2007. 
{it:Statistical Analysis of Extreme Values with Applications to Insurance, Finance, Hydrology and other Fields.} 
Basel: Birkh{c a:}user. 

{p 4 8 2}Rice, K. and T. Lumley. 2016. 
Graphics and statistics for cardiology: comparing categorical and continuous
variables.  {it:Heart} 102: 349{c -}355 doi:10.1136/heartjnl-2015-308104

{p 4 8 2}Ripley, B.D. 1996. 
{it:Pattern Recognition and Neural Networks.} 
Cambridge: Cambridge University Press. See p.115.

{p 4 8 2}Robertson, B. 1988.
{it:Learn to Draw Charts and Diagrams Step-by-step.}
London: Macdonald Orbis. See pp.34{c -}5.

{p 4 8 2}Robbins, N.B. 2005. 
{it:Creating More Effective Graphs.} 
Hoboken, NJ: John Wiley. (2013 edition: Wayne, NJ: Chart House) 

{p 4 8 2}Robinson, A.P. and J.D. Hamann. 2011. 
{it:Forest Analytics withJ.R: An Introduction.} 
New York: Springer. See p.123.

{p 4 8 2}Rousseeuw, P.J. and A.M. Leroy. 1987. 
{it:Robust Regression and Outlier Detection.}
New York: John Wiley. See p.7. 

{p 4 8 2}Rousselet, G.A., J.J. Foxe and J.P. Bolam. 2016. 
A few simple steps to improve the description of group results in neuroscience. {it:European Journal of Neuroscience} 44: 2647{c -}2651. 
doi: 10.1111/ejn.13400. 

{p 4 8 2}Rousselet, G.A., C.H. Pernet and R.R. Wilcox. 2017.
Beyond differences in means: robust graphical methods to compare two 
groups in neuroscience. 
{it:European Journal of Neuroscience} 46: 1738{c -}1748. 
doi: 10.1111/ejn.13610. 

{p 4 8 2}Rowntree, D. 1981. 
{it:Statistics Without Tears: A Primer for Non-mathematicians.}
Harmondsworth: Penguin. 

{p 4 8 2}Ryan, B.F., B.L. Joiner and J.D. Cryer. 2013. 
{it:Minitab Handbook: Updated for Release 16.} 
Boston, MA: Brooks/Cole.  

{p 4 8 2}Ryan, B.F., B.L. Joiner and T.A. Ryan. 1985. 
{it:Minitab Handbook.} 
Boston, MA: Duxbury.
{* Thomas Arthur Ryan Jr 1940-2017}{...} 
{* Barbara Falkenbach Ryan PhD 1968 divorced 1988}{...}
{* Brian Lyon Joiner PhD 1968 1937-2023}{...} 

{p 4 8 2}Ryan, T.P. 2009. 
{it:Modern Regression Methods.} 
Hoboken, NJ: John Wiley. See p.166.  

{p 4 8 2}Sall, J., A. Lehman, M. Stephens and L. Creighton. 2014. 
{it:JMP Start Statistics: A Guide to Statistics and Data Analysis Using JMP.} 
Cary, NC: SAS Institute. 

{p 4 8 2}
Sarkar, D. 2008. 
{it:Lattice: Multivariate Data Visualization with R.}
New York: Springer.

{p 4 8 2}
Sasieni, P. and P. Royston. 1994. 
dotplot: Comparative scatterplots. 
{it:Stata Technical Bulletin} 19: 8{c -}10. 

{p 4 8 2}Sasieni, P.D. and P. Royston. 1996. 
Dotplots. 
{it:Applied Statistics} 45: 219{c -}234.

{p 4 8 2}Sawitzki, G. 2009. 
{it:Computational Statistics: An Introduction to R.} 
Boca Raton, FL: CRC Press.

{p 4 8 2}Schimek, M.G. (ed.) 2000. 
{it:Smoothing and Regression: Approaches, Computation, and Application.} 
New York: John Wiley. 

{p 4 8 2}Schneider, D.C. 2009. 
{it:Quantitative Ecology: Measurement, Models, and Scaling.} 
London: Academic Press. See p.7.
 
{p 4 8 2}Schmid, C.F. 1954. 
{it:Handbook of Graphic Presentation.} 
New York: Ronald Press. 

{p 4 8 2}Schmid, C.F. and S.E. Schmid. 1979. 
{it:Handbook of Graphic Presentation.} 
New York: John Wiley. 

{p 4 8 2}Schuenemeyer, J.H. and L.J. Drew. 2011. 
{it:Statistics for Earth and Environmental Scientists.}
Hoboken, NJ: John Wiley.

{p 4 8 2}Schwabish, J. 2021. 
{it:Better Data Visualizations: A Guide for Scholars, Researchers, and Wonks.}
New York: Columbia University Press. 

{p 4 8 2}Schwabish, J. 2023. 
{it:Data Visualization in Excel: A Guide for Beginners, Intermediates, and Wonks.}
Boca Raton, FL: CRC Press. 

{p 4 8 2}Scott, D.W. 1992. 
{it:Multivariate Density Estimation: Theory, Practice, and Visualization.} 
New York: John Wiley. 

{p 4 8 2}Scott, D.W. 2015. 
{it:Multivariate Density Estimation: Theory, Practice, and Visualization.} 
Hoboken, NJ: John Wiley. 

{p 4 8 2}Searcy, J.K. 1959. 
Flow-duration curves. 
{it:Geological Survey Water-Supply Paper} 1542-A. 
{browse "http://pubs.usgs.gov/wsp/1542a/report.pdf":http://pubs.usgs.gov/wsp/1542a/report.pdf} 

{p 4 8 2}Seheult, A. 1986.
Simple graphical methods for data analysis. 
In Lovie, A.D. (ed.) 
{it:New Developments in Statistics for Psychology and the Social Sciences.} 
London: British Psychological Society and Methuen, 3{c -}21. 

{p 4 8 2}Selvin, S. 2019. 
{it:The Joy of Statistics: A Treasury of Elementary Statistical Tools and Their Appications.} 
Oxford: Oxford University Press. 

{p 4 8 2}Setlur, V. and B. Cogley. 2022. 
{it:Functional Aesthetics for Data Visualization.}
Hoboken, NJ: John Wiley. See pp.195{c -}196.

{p 4 8 2}Shaw, N. 1936. 
{it:Manual of Meteorology. Volume II: Comparative Meteorology.} 
Cambridge: Cambridge University Press. See pp.102{c -}105, 420. 

{p 4 8 2}Sheather, S.J. 2009.
{it:A Modern Approach to Regression with R.}
New York: Springer. 

{p 4 8 2}Shelly, M. 1996. 
Exploratory data analysis: data visualization or torture? 
{it:Infection Control and Hospital Epidemiology} 17: 605{c -}612.

{p 4 8 2}Shen, S.S.P. and G.R. North. 2023. 
{it:Statistics and Data Visualization In Climate Science with R and Python.}
Cambridge: Cambridge University Press. 

{p 4 8 2}Shera, D.M. 1991. 
Some uses of quantile plots to enhance data presentation. 
{it:Computing Science and Statistics} 23: 50{c -}53.
{browse "http://www.dtic.mil/dtic/tr/fulltext/u2/a252938.pdf":http://www.dtic.mil/dtic/tr/fulltext/u2/a252938.pdf} 

{p 4 8 2}Shewhart, W.A. 1931. 
{it:Economic Control of Quality of Manufactured Product.}
New York: Van Nostrand. 

{p 4 8 2}Shewhart, W.A. 1939. 
{it:Statistical Method from the Viewpoint of Quality Control.} 
Washington, DC: Graduate School of the Department of Agriculture. 

{p 4 8 2}Siegel, A.F. 1988.                        
{it:Statistics and Data Analysis: An Introduction.} 
New York: John Wiley. 

{p 4 8 2}Siegel, A.F. and C.J. Morgan. 1996.                        
{it:Statistics and Data Analysis: An Introduction.} 
New York: John Wiley. 

{p 4 8 2}Sidiropoulos, N., S.H. Sohi, T.L. Pedersen, B.T. Porse, O. Winther,  
N. Rapin and F.O. Bagger. 2018. SinaPlot: 
An enhanced chart for simple and truthful representation of single observations over multiple classes. 
{it:Journal of Computational and Graphical Statistics}
DOI: 10.1080/10618600.2017.1366914

{p 4 8 2}Silk, J.A. 1979. 
{it:Statistical Concepts in Geography.} 
London: George Allen & Unwin. 

{p 4 8 2}Simonoff, J.S. 1996. 
{it:Smoothing Methods in Statistics.} 
New York: Springer.
 
{p 4 8 2}Simonoff, J.S. 2003. 
{it:Analyzing Categorical Data.} 
New York: Springer. 

{p 4 8 2}Sinacore, J.M. 1997.
Beyond double bar charts: The value of dot charts with ordered category
clustering for reporting change in evaluation research. 
{it:New Directions for Evaluation} 73: 43{c -}49.
 
{p 4 8 2}Singer, P.A., and A.R. Feinstein. 1993. 
Graphical display of categorical data. 
{it:Journal of Clinical Epidemiology} 46(3):231{c -}236.
 
{p 4 8 2}Sleeper, R. 2018. 
{it:Practical Tableau: 100 Tips, Tutorials, and Strategies from a Tableau Zen Master.} 
Sebastopol, CA: O'Reilly. 

{p 4 8 2}Sleeper, R. 2020. 
{it:Innovative Tableau: 100 More Tips, Tutorials, and Strategies.} 
Sebastopol, CA: O'Reilly. 

{p 4 8 2}Slocum, T.A., R.B. McMaster, F.C. Kessler and H.H. Howard. 2010. 
{it:Thematic Cartography and Geovisualization.} 
Upper Saddle River, NJ: Pearson Prentice Hall. 

{p 4 8 2}Smith, A. 2022. 
{it:How Charts Work: Understand and Explain Data with Confidence.} 
Harlow: Pearson. 

{p 4 8 2}Smith, D.M. 1979. 
{it:Where the Grass is Greener: Living in an Unequal World.} 
Harmondsworth: Penguin. See p.270. 

{p 4 8 2}Snedecor, G.W. 1937. 
{it:Statistical Methods Applied to Experiments in Agriculture and Biology.}  
Ames, IA: Collegiate Press. See Figures 2.1, 2.3 (pp.24, 39). 
See also 1938 edition from Iowa State College Press (pp.27, 42). 
See also 1940 edition from Iowa State College Press (pp.27, 42).
See also 1946 edition from Iowa State College Press (pp.33, 51).
See also 1956 edition from Iowa State University Press (p.39).

{p 4 8 2}Snedecor, G.W. and W.G. Cochran. 1967. 
{it:Statistical Methods.}
Ames, IA: Iowa State University Press (p.41) 
Note for completeness: Such graphs do not appear in 7th edition 1980 
or 8th edition 1989.

{p 4 8 2}Sokal, R.R. and F.J. Rohlf. 2012. 
{it:Biometry: The Principles and Practice of Statistics in Biological Research.}
New York: W.H. Freeman (previous editions 1969, 1981, 1995) 

{p 4 8 2}Spear, M.E. 1952.
{it:Charting Statistics.} 
New York: McGraw-Hill. See p.166. 

{p 4 8 2}Spear, M.E. 1969.
{it:Practical Charting Techniques.} 
New York: McGraw-Hill. See p.224. 

{p 4 8 2}Spence, R. 2001. 
{it:Information Visualization.} 
Harlow, UK: Pearson.

{p 4 8 2}Spence, R. 2007. 
{it:Information Visualization: Design for Interaction.} 
Harlow, UK: Pearson. 

{p 4 8 2}Spence, R. 2014. 
{it:Information Visualization: An Introduction.} 
Cham: Springer. 

{p 4 8 2}Spiegelhalter, D. 2019. 
{it:The Art of Statistics: Learning from Data.}
London: Penguin Books. pp.42, 45, 64.

{p 4 8 2}Sprent, P. 1988. 
{it:Taking Risks: The Science of Uncertainty.} 
Harmondsworth: Penguin Books. p.203. 

{p 4 8 2}Standage, T. (ed.) 2018. 
{it:Seriously Curious: The Economist Explains: The Facts and Figures That Turn Your World Upside Down.} 
London: Profile Books. pp.94, 141, 223. 

{p 4 8 2}Standage, T. (ed.) 2019. 
{it:Uncommon Knowledge: The Economist Explains: Extraordinary Things That Few People Know.} 
London: Profile Books. pp.45, 79, 95, 110, 113, 140, 185. 

{p 4 8 2}Standage, T. (ed.) 2020. 
{it:Unconventional Wisdom: The Economist Explains: Adventures in the Surprisingly True.} 
London: Profile Books. pp.49, 62, 68, 70, 154. 

{p 4 8 2}Staudte, R.G. and S.J. Sheather. 1990. 
{it:Robust Estimation and Testing.} 
Mew York: John Wiley. 

{p 4 8 2}
Stock, W.A. and J.T. Behrens. 1991. 
Box, line, and midgap plots: effects of display characteristics on the
accuracy and bias of estimates of whisker length. 
{it:Journal of Educational Statistics}
16: 1{c -}20. 

{p 4 8 2}
Stuetzle, W. 1987. 
Plot windows.
{it:Journal, American Statistical Association}
82: 466{c -}475. 

{p 4 8 2}
Svendsen, N. 1940. 
Are supernormal cholesterol-values in serum caused by a dominantly 
inherited factor? Report of a family investigation of 34 individuals. 
{it:Acta Medica Scandinavica} 104: 235{c -}244. 

{p 4 8 2}Swan, A.R.H. and M. Sandilands. 1995. 
{it:An Introduction to Geological Data Analysis.} 
Oxford: Blackwell Science.

{p 4 8 2}Thas, O. 2010.  
{it:Comparing Distributions.} 
New York: Springer.  

{p 4 8 2}Theus, M. and S. Urbanek. 2009. 
{it:Interactive Graphics for Data Analysis: Principles and Examples.}
Boca Raton, FL: CRC Press.

{p 4 8 2}Thi{c e'}baux, H.J. 1994.
{it:Statistical Data Analysis for Ocean and Atmospheric Sciences.} 
San Diego, CA: Academic Press. See pp.39, 40, 120.  

{p 4 8 2}Thompson, J.M. 1992. 
Visual representation of data including graphical exploratory data analysis. 
In Hewitt, C.N. (ed.) 
{it:Methods of Environmental Data Analysis.} 
London: Chapman and Hall, 213{c -}258. 

{p 4 8 2}Tippett, L.H.C. 1943. 
{it:Statistics.} London: Oxford University Press. See p.97 in 1956 edition.
 
{p 4 8 2}Truran, H.C. 1975. 
{it:A Practical Guide to Statistical Maps and Diagrams.} 
London: Heinemann Educational Books.

{p 4 8 2}Tufte, E.R. 1974. 
{it:Data Analysis for Politics and Policy.} 
Englewood Cliffs, NJ: Prentice-Hall. 

{p 4 8 2}Tufte, E.R. 1983. 
{it:The Visual Display of Quantitative Information.} 
Cheshire, CT: Graphics Press. (2nd edition 2001) 

{p 4 8 2}Tufte, E.R. 1990a. 
{it:Envisioning Information}.
Cheshire, CT: Graphics Press.

{p 4 8 2}Tufte, E.R. 1990b. 
Data-ink maximization and graphical design. 
{it:Oikos} 58: 130{c -}144. 

{p 4 8 2}Tufte, E.R. 1997. 
{it:Visual Explanations: Images and Quantities, Evidence and Narrative.} 
Cheshire, CT: Graphics Press. 

{p 4 8 2}Tufte, E.R. 2006. 
{it:Beautiful Evidence.} 
Cheshire, CT: Graphics Press.

{p 4 8 2}
Tufte, E.R. 2020. 
{it:Seeing with Fresh Eyes: Meaning, Space, Data, Truth.}
Cheshire, CT: Graphics Press.
See pp.99{c -}101. 
"Detailed data moves closer to the truth. No more binning, less
cherry-picking, less truncation." (p.100) 
"To improve learning from data, credibility, and integrity, show the data." 
(p.101)

{p 4 8 2}Tukey, J.W. 1970a.  
{it:Exploratory data analysis. Limited Preliminary Edition. Volume I.}
Reading, MA: Addison-Wesley.

{p 4 8 2}Tukey, J.W. 1970b.  
{it:Exploratory data analysis. Limited Preliminary Edition. Volume II.}
Reading, MA: Addison-Wesley.

{p 4 8 2}Tukey, J.W. 1972.
Some graphic and semi-graphic displays.
In Bancroft, T.A. and Brown, S.A. (eds)
{it:Statistical Papers in Honor of George W. Snedecor.}
Ames, IA: Iowa State University Press, 293{c -}316.
(also accessible at {browse "http://www.edwardtufte.com/tufte/tukey":http://www.edwardtufte.com/tufte/tukey})

{p 4 8 2}
Tukey, J.W. 1974. 
Named and faceless values: an initial exploration in memory of Prasanta C. Mahalanobis. 
{it:Sankhya: The Indian Journal of Statistics} Series A 36: 125{c -}76. 
http://www.jstor.org/stable/25049924. NB: last character of journal title is a with macron, uchar(257) from Stata 14 up. 

{p 4 8 2}Tukey, J.W. 1977. 
{it:Exploratory Data Analysis.} 
Reading, MA: Addison-Wesley. 

{p 4 8 2}Tukey, J.W. and P.A. Tukey. 1990. Strips displaying 
empirical distributions: I. Textured dot strips. Bellcore Technical Memorandum. 

{p 4 8 2}Tukey, P.A. and Tukey, J.W. 1981. 
Data-driven view selection; Agglomeration and sharpening. 
In Barnett, V. (ed.) {it:Interpreting Multivariate Data.} 
Chichester: John Wiley, 215{c -}243. See p.235. 

{p 4 8 2}Uman, M.A. 1969. 
{it:Lightning.} 
New York: McGraw-Hill. See p.86.

{p 4 8 2}
Unwin, A. 2024. 
{it:Getting (more out of) Graphics: Practice and Principles of Data Visualization.}
Boca Raton, FL: CRC Press. p.113.

{p 4 8 2}Urbanek, S. 2008. 
Visualizing trees and forests. 
In Chen, C., W. H{c a:}rdle and A. Unwin (eds) 
{it:Handbook of Data Visualization.} 
Berlin: Springer, 243{c -}264.  

{p 4 8 2}Utts, J.M. and R.F. Heckard. 2002. 
{it:Mind on Statistics.} 
Pacific Grove, CA: Duxbury. 
dotplots pp.2, 29, 360, 418, 498, 501, 513; rug p.478; 
boxplot with means pp.491, 513

{p 4 8 2}Vail, A. and J. Wilkinson. 2020. 
Bang goes the detonator plot! 
{it:Reproduction} 159: E3{c -}E4.

{p 4 8 2}van Belle, G., L.D. Fisher, P.J. Heagerty and T. Lumley. 2004. 
{it:Biostatistics: A Methodology for the Health Sciences.} 
Hoboken, NJ: John Wiley. 

{p 4 8 2}Vanderplas, S., D. Cook and H. Hofmann. 2020. 
Testing statistical charts: What makes a good graph?
{it:Annual Review of Statistics and Its Applications} 7: 61{c -}88. 

{p 4 8 2}Velleman, P.F. 1989. 
{it:Learning Data Analysis with Data Desk.} 
New York: W.H. Freeman. (later editions 1993, etc.) 

{p 4 8 2}Venables, W.N. and B.D. Ripley. 2002. 
{it:Modern Applied Statistics with S.} New York: Springer. 

{p 4 8 2}Wainer, H. 2009. 
{it:Picturing the Uncertain World: How to Understand, Communicate, and Control Uncertainty through Graphical Display.} 
Princeton, NJ: Princeton University Press. 

{p 4 8 2}Wainer, H. 2014. 
{it:Medical Illuminations: Using Evidence, Visualization and Statistical Thinking to Improve Healthcare.} 
Oxford: Oxford University Press. 

{p 4 8 2}Wainer, H. 2016. 
{it:Truth or Truthiness: Distinguishing Fact from Fiction by Learning to Think Like a Data Scientist.} 
Cambridge: Cambridge University Press. 

{p 4 8 2}
Wallace, A.R. 1889. 
{it:Darwinism: An Exposition of the Theory of Natural Selection with some of its Applications.}
London: Macmillan. See pp.63{c -}65. 

{p 4 8 2}Wallis, W.A. and H.V. Roberts. 1956. 
{it:Statistics: A New Approach.} Glencoe, IL: Free Press.

{p 4 8 2}Wand, M.P. and M.C. Jones. 1995. 
{it:Kernel Smoothing.} London: Chapman and Hall. See esp. p.168.  

{p 4 8 2}Warton, D.I. 2008. 
Raw data graphing: an informative but under-utilized tool for the analysis of multivariate abundances.
{it:Austral Ecology} 33: 290{c -}300. 

{p 4 8 2}Warton, D.I. 2022. 
{it:Eco-Stats: Data Analysis in Ecology: From t-tests to Multivariate Abundances.}
Cham: Springer. 

{p 4 8 2}Wasserman, L. 2004. 
{it:All of Statistics: A Concise Course in Statistical Inference.} 
New York: Springer. 

{p 4 8 2}Wasserman, L. 2006. 
{it:All of Nonparametric Statistics.} 
New York: Springer.

{p 4 8 2}Weigel, A.P. 2012. 
Ensemble forecasts. 
In Jolliffe, I.T. and D.B. Stephenson (eds) 
{it:Forecast Verification: A Practitioner's Guide in Atmospheric Science.} 
Chichester: Wiley-Blackwell, 141{c -}166.  

{p 4 8 2}Weissgerber, T.L., N.M. Milic, S.J. Winham and V.D. Garovic. 2015. 
Beyond bar and line graphs: time for a new data presentation paradigm. 
{it:PLoS Biology} 13(4): e1002128. doi:10.1371/journal.pbio.1002128

{p 4 8 2}Weissgerber, T.L., S.J. Winham, E.P. Heinzen, J.S. Milin-Lazovic,
O. Garcia-Valencia, Z. Bukumiric, M.D. Savic, V.D. Garovic and N.M. Milic. 
2019. Reveal, don't conceal: Transforming data visualization to improve 
transparency. {it:Circulation} 140: 1506{c -}1518.

{p 4 8 2}Welham, S.J., S.A. Gezan, S.J. Clark and A. Mead. 2015. 
{it:Statistical Methods in Biology: Design and Analysis of Experiments and Regression.}
Boca Raton, FL: CRC Press. 

{p 4 8 2}Wennberg, J.E. and M.M. Cooper (eds) 1996. 
{it:The Dartmouth Atlas of Health Care in the United States.}
Chicago: American Hospital Publishing.
{browse "http://www.dartmouthatlas.org/downloads/atlases/96Atlas.pdf":http://www.dartmouthatlas.org/downloads/atlases/96Atlas.pdf} 

{p 4 8 2}Wetherill, G.B. 1981. 
{it:Intermediate Statistical Methods.} 
London: Chapman and Hall. See p.2. 

{p 4 8 2}Wetherill, G.B. 1982. 
{it:Elementary Statistical Methods.} 
London: Chapman and Hall. See p.68.

{p 4 8 2}Wexler, S. 2021. 
{it:The Big Picture: How to Use Data Visualization to Make Better Decisions{c -}Faster.} 
New York: McGraw Hill. 

{p 4 8 2}Wexler, S., J. Shaffer and A. Cotgreave. 2017. 
{it:The Big Book of Dashboards: Visualizing Your Data Using Real-World Business Scenarios.} 
Hoboken, NJ: John Wiley. 

{p 4 8 2}White, R. 1984. 
{it:Physical Geography.} London: Macmillan. See p.159.

{p 4 8 2}
Whitlock, M.C. and D. Schluter. 2009. 
{it:The Analysis of Biological Data.} 
Greenwood Village, CO: Roberts and Company. 
(Second edition 2015; third edition 2020 New York: Macmillan.) 

{p 4 8 2}
Wickham, H. 2009. 
{it:ggplot2: Elegant Graphics for Data Analysis.}
New York: Springer. Dot chart p.124. 

{p 4 8 2}
Wickham, H. 2016. 
{it:ggplot2: Elegant Graphics for Data Analysis.}
Cham: Springer. Dot charts pp.154, 233, 237. 

{p 4 8 2}
Wickham, H., M. {c C,}etinskaya-Rundel and G. Grolemund. 2023. 
{it:R for Data Science: Import, Tidy, Transform, Visualize, and Model Data.} 
Sebastopol, CA: O'Reilly. Dot charts pp.286{c -}289.    

{p 4 8 2}
Wickham, H. and G. Grolemund. 2017. 
{it:R for Data Science: Import, Tidy, Transform, Visualize, and Model Data.} 
Sebastopol, CA: O'Reilly. Dot charts pp.228{c -}230. Box plots with means 
pp.386, 392.   

{p 4 8 2}
Wigglesworth, V.B. 1954.
{it:The Physiology of Insect Metamorphosis.} 
London: Cambridge University Press. See p.71. 

{p 4 8 2}
Wilcox, R.R. 2009. 
{it:Basic Statistics: Understanding Conventional Methods and Modern Insights.}
New York: Oxford University Press. Dotplot p.208

{p 4 8 2}Wild, C.J. and G.A.F. Seber. 2000. 
{it:Chance Encounters: A First Course in Data Analysis and Inference.} 
New York: John Wiley. 

{p 4 8 2}Wilkinson, L. 1992. Graphical displays. 
{it:Statistical Methods in Medical Research} 1: 3{c -}25. 

{p 4 8 2}Wilkinson, L. 1994.
Less is more: Two- and three-dimensional graphics for data display. 
{it:Behavior Research Methods, Instruments & Computers} 
26: 172{c -}176. https://doi.org/10.3758/BF03204612

{p 4 8 2}Wilkinson, L. 1999a. Dot plots. {it:American Statistician} 
53: 276{c -}281. 

{p 4 8 2}Wilkinson, L. 1999b. {it:The Grammar of Graphics.} 
New York: Springer. 

{p 4 8 2}Wilkinson, L. 2005. {it:The Grammar of Graphics.} 
New York: Springer.  

{p 4 8 2}
Wilkinson, L. 2023. 
Graphic displays of data. In Cooper, H. (ed.) 
{it:APA Handbook of Research Methods in Psychology. Volume 3: Data Analysis and Research Publication.}
Washington, DC: American Psychological Association, 77{c -}110. 

{p 4 8 2}
Wilkinson, L., G. Blank and C. Gruber. 1996. 
{it:Desktop Data Analysis using SYSTAT.}
Upper Saddle River, NJ: Prentice-Hall. See Chapters 8, 13, 14, 22, 24.

{p 4 8 2}Wilks, D.S. 1995. 
{it:Statistical Methods in the Atmospheric Sciences: An Introduction.} 
San Diego, CA: Academic Press. 

{p 4 8 2}Wilks, D.S. 2006. 
{it:Statistical Methods in the Atmospheric Sciences.} 
Burlington, MA: Academic Press. 2nd edition.  

{p 4 8 2}Wilks, D.S. 2011. 
{it:Statistical Methods in the Atmospheric Sciences.} 
Oxford: Academic Press. 3rd edition. 

{p 4 8 2}Wilks, D.S. 2019. 
{it:Statistical Methods in the Atmospheric Sciences.} 
Amsterdam: Elsevier. 4th edition. 

{p 4 8 2}Wilks, S.S. 1948. {it:Elementary Statistical Analysis.} 
Princeton, NJ: Princeton University Press. 

{p 4 8 2}Williams, C.B. 1940. 
A note on the statistical analysis of sentence-length as a criterion of 
literary style. {it:Biometrika} 31: 356{c -}361. 

{p 4 8 2}Williams, C.B. 1944. 
Some applications of the logarithmic series and the index of diversity
to ecological problems.  {it:Journal of Ecology} 32: 1{c -}44. 

{p 4 8 2}Williams, C.B. 1964. {it:Patterns in the Balance of Nature.} 
London: Academic Press. See pp.43, 51, 84, 155, 170, 208, 213, 286, 290. 

{p 4 8 2}Williams, C.B. 1970. {it:Style and Vocabulary: Numerical Studies.} 
London: Charles Griffin. See pp.57, 61, 77. 

{p 4 8 2}Williamson, M.H. 1972. {it:The Analysis of Biological Populations.}
London: Edward Arnold. See p.120. 

{p 4 8 2}Wills, G. 2012. 
{it:Visualizing Time: Designing Graphical Representations for Statistical Data.} 
New York: Springer. 

{p 4 8 2}Wimberly, M.C. 2023.
{it:Geographic Data Science with R: Visualizing and Analyzing Environmental Change.}
Boca Raton, FL: CRC Press. 
See p.238 for rugplots. 

{p 4 8 2}Wolfe, D.A. and G. Schneider. 2017. 
{it:Intuitive Introductory Statistics.} 
Cham: Springer. 

{p 4 8 2}Wolfram, S. 2017. 
{it:An Elementary Introduction to the Wolfram Language.} 
Champaign, IL: Wolfram Media. 

{p 4 8 2}Woloshin, S. 2000. 
A turnip graph engine. 
{it:Stata Technical Bulletin} 58: 5{c -}8.

{p 4 8 2}Wood, S.N. 2017. 
{it:Generalized Additive Models: An Introduction with R.}
Boca Raton, FL: CRC Press.
Rugs: pp.184, 189, 240, 266, 296, 314, 344, 345, 348, 349, 351, 352, 354, 358,
376, 377, 379, 381, 383, 386, 388, 389, 390, 395, 396. 

{p 4 8 2}Wright, D.B. and K. London. 2009. 
{it:First (and Second) Steps in Statistics.} 
London: SAGE.  

{p 4 8 2}Wright, S. 1977. 
{it:Evolution and the Genetics of Populations. Volume 3:  Experimental Results and Evolutionary Deductions.}
Chicago: University of Chicago Press. p.64. 

{p 4 8 2}Xue, J.-H. and D.M. Titterington. 2011.
The {it:p}-folded cumulative distribution function and the mean 
absolute deviation from the {it:p}-quantile. 
{it:Statistics & Probability Letters} 81: 1179{c -}1182.

{p 4 8 2}Yamamoto, Y., M. Iizuka and T. Fujino. 2008. 
Web-based statistical graphics using XML technologies. 
In Chen, C., W. H{c a:}rdle and A. Unwin (eds) 
{it:Handbook of Data Visualization.} 
Berlin: Springer, 757{c -}789.  

{p 4 8 2}Yandell, B.S. 1997. 
{it:Practical Data Analysis for Designed Experiments.}
London: Chapman and Hall. See p.54 

{p 4 8 2}Yandell, B.S. 2007. 
Graphical data presentation, with emphasis on genetic data.  
{it:HortScience} 42: 1047{c -}1051. 

{p 4 8 2}Yau, N. 2011. 
{it:Visualize This: The FlowingData Guide to Design, Visualization, and Statistics.} 
Indianapolis, IN: John Wiley. See p.261 for {it:dot plot} meaning {it:scatter plot}. 
The term {it:scatterplot} is also used many times in its usual sense. 

{p 4 8 2}Yau, N. 2013. 
{it:Data Points: Visualization That Means Something.} 
Indianapolis, IN: John Wiley. See pp.126{c -}127, 194. 

{p 4 8 2}Yau, N. 2024. 
{it:Visualize This: The FlowingData Guide to Design, Visualization, and Statistics.} 
Hoboken, NJ: John Wiley. 

{p 4 8 2}Youden, W.J. 1962. 
{it:Experimentation and Measurement.} 
New York: Scholastic Book Services. See p.108. 

{p 4 8 2}Young, F.W., P.M. Valero-Mora and M. Friendly. 2006. 
{it:Visual Statistics: Seeing Data with Interactive Graphics.} 
Hoboken, NJ: John Wiley. 

{p 4 8 2}Yu, B. and R.L. Barter. 2024. 
{it:Veridical Data Science: The Practice of Responsible Data Analysis and Decision Making.}
Cambridge, MA: MIT Press. See pp.129, 317 (rugs), 145 (Cleveland dot), 160 (strip plot236 (box-dot)

{p 4 8 2}Zar, J.H. 2010. 
{it:Biostatistical Analysis.} 
Upper Saddle River, NJ: Pearson Education. See p.5. 

{p 4 8 2}Zipf, G.K. 1949.
{it: Human Behavior and the Principle of Least Effort: An Introduction to Human Ecology.}
Cambridge, MA: Addison-Wesley. 

{p 4 8 2}Zuur, A.F., E.N. Ieno and G.M. Smith. 2007.
{it:Analysing Ecological Data.} 
New York: Springer.


{title:Also see}

{p 4 13 2} 
On-line: help for {help dotplot}, {help histogram}, 
{help distplot} (if installed), {help qplot} (if installed),
{help cisets} (if installed), 
{help pctilesets} (if installed), 
{help quantilesets} (if installed)


