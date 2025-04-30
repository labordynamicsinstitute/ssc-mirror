{smcl}
{* 9jul2020/28april2025}{...}
{hline}
help for {hi:codensity}
{hline}

{title:Kernel density estimation for one or more variables or groups} 


{title:Syntax} 

{p 8 17 2}{cmd:codensity} {cmdab:g:enerate} {it:varlist} {ifin}
{weight} [ {cmd:,} {it:generate_options} ] {space 4} 
({cmd:generate} syntax 1) 

{p 8 17 2}{cmd:codensity} {cmdab:g:enerate} {it:varname} {ifin}
{weight} [ {cmd:,} {it:generate_options} ] {space 4} 
({cmd:generate} syntax 2) 

{p 8 17 2}{cmd:codensity} {cmdab:su:per} [ {cmd:,} {it:super_options}
] 

{p 8 17 2}{cmd:codensity} {cmdab:j:uxta} [ {cmd:,} {it:juxta_options}
] 

{p 8 17 2}{cmd:codensity} {cmdab:b:ystyle} [ {cmd:,}
{it:bystyle_options} ] 

{p 8 17 2}{cmd:codensity} {cmdab:st:ack} [ {cmd:,}
{it:stack_options} ] 

{p 8 17 2}{cmd:codensity} {cmd:clear} [ {cmd:,} {it:clear_options} ] 

{p 4 4 2}{cmd:fweights} and {cmd:aweights} are allowed; see {help weight}. 


{title:Description} 

{p 4 4 2}{cmd:codensity} is a convenience command for creating and
plotting kernel estimates of univariate probability density for one or
(especially) more variables or for one or (especially) more groups of a
specified variable. It is variously a wrapper for 
{help twoway__kdensity_gen} and {help graph twoway}. 

{p 4 4 2}In addition to its more obvious use for probability density
estimates, for either different variables or different groups of a
single variable, {cmd:codensity} is designed to accommodate tasks such
as exploring the effects of different kernel choices or of different
bandwidths with the same data. {cmd:codensity} is also unusual in
supporting estimates of probability density on various transformed
scales, back-transformed to be shown against the original scale. 

{p 4 4 2}{cmd:codensity} hinges on using {cmd:codensity generate} to
generate new variables. Once those are in memory, you can draw whatever
graphs you want or even export the results beyond Stata.  However,
{cmd:codensity} offers four kinds of graphs through subcommands:  

{p 8 8 2}{cmd:codensity super} superimposes density traces in a single
panel. It is often a good choice if you are looking at distributions
with identical units of measurement, or even the same data analysed in
different ways.  

{p 8 8 2}{cmd:codensity juxta} draws separate graphs for each variable
or group and then uses {help graph combine} to produce a combined
display in which graphs are juxtaposed. It is a better choice if you are
looking at distributions with very different magnitudes and/or units of
measurement. 

{p 8 8 2}{cmd:codensity bystyle} is an alternative in which panels are
presented juxtaposed as if using a {help by_option} for different groups
of a single variable. That is not an illusion, as the dataset is
temporarily {help reshape}d to allow such a plot. The result can
sometimes look better than that from {cmd:codensity juxta}. 

{p 8 8 2}{cmd:codensity stack} is an alternative in which densities are
stacked within a single graph panel. It is also often a good choice if
you are looking at distributions with identical units of measurement.

{p 4 4 2}Note that these subcommands, {cmd:super}, {cmd:juxta}.
{cmd:bystyle} and {cmd:stack}, are unusual in not expecting (or even
allowing) a {it:varlist} to be specified. They depend on variables left
in memory by a previous {cmd:codensity generate}. 

{p 4 4 2}It is natural to change your mind about what is a good idea, so
{cmd:codensity clear} is a quick way to clear results out of the way,
allowing a fresh start.


{title:Options}

{it:Options of codensity generate} 

{p 4 8 2}{opt fstub(string)} specifies a stub or prefix for names of
variables containing kernel estimates of probability density for each
specified variable or group. The default is {cmd:fstub(_density)}. Thus
if 4 variables are specified in {it:varlist}, or 4 groups of values are
specified by {it:varname} {cmd:, over(}{it:overvar}{cmd:)}, then by
default density estimates will be returned in variables
{cmd:_density1-_density4}. 

{p 4 8 2}{opt xstub(string)} specifies a stub or prefix for names of
variables containing values on a grid approximating the range of each
specified variable or group, or a greater range. The default is
{cmd:xstub(_x)}.  Thus if 4 variables or 4 groups are specified, by
default grid values will be returned in new variables {cmd:_x1-_x4}.
Such values will be equally spaced on the scale used for estimation. If
estimates are calculated on a transformed scale, grid values will be
equally spaced on that scale, but returned back-transformed to the
original scale. 

{p 4 8 2}{opt over(overvar)} (allowed with one {it:varname} only: see
{cmd:generate} syntax 2 above) specifies the name of a grouping
variable. Density estimates will be produced separately for each
distinct value of {it:overvar}. String variables are allowed for
{it:overvar}. Missing values of {it:overvar} will be ignored unless the
{cmd:missing} option is also specified (see immediately below). 

{p 4 8 2}{opt miss:ing} (allowed with one {it:varname} only: see
{cmd:generate} syntax 2 above) specifies that missing values of
{it:overvar} be included in calculations for distinct values specified
by {cmd:over(}{it:overvar}{cmd:)}.  

{p 4 8 2}{opt n(#)} specifies the number of values to be included in
each grid for estimation of probability density. The default is
{cmd:min(_N, 100)}, where {cmd:_N} is the number of observations in the
entire dataset. If {cmd:n()} is specified to exceed {cmd:_N}, it is
reset to {cmd:_N} with a warning. 

{p 4 8 2}{opt min:imum(#)} specifies that the range of each grid be
extended to a minimum of {it:#} if (and only if) {it:#} is smaller than
the observed minimum. 

{p 4 8 2}{opt max:imum(#)} specifies that the range of each grid be
extended to a maximum of {it:#} if (and only if) {it:#} is larger than
the observed maximum. 

{p 4 8 2}{opt bw:idth(numlist)} specifies one or more bandwidths to
override the default chosen by {help twoway__kdensity_gen}. If one
bandwidth is specified, it is applied to all variables or groups of
values specified. If {cmd:trans()} is also specified, the bandwidth must
be on the transformed scale. That may require some experimentation or at
least some prior experience. For the default bandwidth, which depends on
standard deviation, interquartile range and sample size, find the manual
entry for {help kdensity}. 

{p 4 8 2}{opt k:ernel(kernel_list)} specifies one or more kernels to
override the default chosen by {help twoway__kdensity_gen}, which is
always the Epanechnikov kernel. If one kernel is specified, it is
applied to all variables or groups of values specified. 

{p 4 8 2}{opt trans(transformation_list)} specifies one or more
transformations to be applied as follows. Data will be transformed as
specified, probability density estimated on that scale,  and then
estimates will be back-transformed. For a monotone transformation
{it:T}({it:x}) the principle is that for densities {it:f} the estimate
of {it:f}({it:x}) is the estimate of {it:f}({it:T}({it:x})) multiplied
by |{it:dT/dx}| = |{it:T'}({it:x})|.  For discussion and references, see
Cox (2004, pp.76{c -}78). On cube roots, see also Cox (2011). Allowed
transformations are 

{p 8 8 2}{cmd:reciprocal} or {cmd:-1}, noting that all values must be
positive for this transformation to be applied; 

{p 8 8 2}{cmd:log} or {cmd:ln}, meaning natural logarithm, noting that
all values must be positive for this transformation to be applied;  

{p 8 8 2}{cmd:cube_root} or {cmd:1/3} (type without spaces), noting that
this is implemented for positive, zero and negative values alike; 

{p 8 8 2}{cmd:root} or {cmd:square_root} or {cmd:1/2} (type without
spaces}, noting that all values must be positive or zero for this
transformation to be applied;  

{p 8 8 2}{cmd:logit}, noting that all values must be strictly between 0
and 1 for this transformation to be applied; 

{p 8 8 2}{cmd:identity} or {it:@}, noting that this specification is
needed if (and only if) other transformations are used in the same
command. 

{p 4 8 2}{opt labelwith(specification)} controls the variable labels to
be used for grid variables. By default the variable label of the
original variable is used, or its variable name if no label is attached,
or the value label or value of the distinct group if {cmd:over()} is
used.  None of these choices is a good idea if the same data are
supplied, but different kernels, bandwidths or transformations are to be
used.  {cmd:labelwith()} allows any or all of {cmd:kernel}, {cmd:bwidth}
or {cmd:trans} to be specified (either in full or as any abbreviation,
but separated by spaces) to indicate use of such elements in variable
labels. 

{p 4 8 2}{opt densitylabel(string)} specifies an alternative variable
label for all generated density variables. The default is
{cmd:"Density"}. 

{p 4 8 2}{opt showchar} specifies that the contents be shown of
characteristics recording kernel type and width and any transformation
applied. The main reason for specifying this option is that you want to
see bandwidths chosen by default, so that you can report or change those
bandwidths. These characteristics will persist so long as the associated
variables persist.  

{it:Options of codensity super}

{p 4 8 2}{cmd:fstub()} and {cmd:xstub()}: see above under 
{it:Options of codensity generate}. 

{p 4 8 2}{opt vert:ical} specifies that axes should be flipped so that
the variable in question is plotted vertically and its density is
plotted horizontally. One reason for doing that is if the variable is
naturally or conventionally regarded as vertical, say that it is an
altitude, elevation, height or depth, as may be encountered in the Earth
or environmental sciences or archaeology.  

{p 4 8 2}{opt recast(newplottype)} is flagged as a particularly useful
option. In practice, {cmd:recast(area)} is by far the most useful possibility,
so long as you are using Stata 15 up and can exploit the scope to tune
opacity or transparency. See also {help advanced options}.  

{p 4 8 2}{opt optall(twoway_options)} is a catch-all for options to be
applied to all plotted curves or areas. 

{p 4 8 2}{opt opt1(twoway_options)} ... {opt opt20(twoway_options)}
specify particular options for the 1st density, ..., 20th density
plotted. For example, if the 7th density plotted was especially
interesting or important, you might want to assign a special colour or
line thickness using {cmd:opt7()}. The number of 20 such options is
plucked out of the air as more than the number of densities that might
comfortably be distinguished. Any of these options overrides
{cmd:optall()} whenever that is practicable.  

{p 4 8 2}{cmd:addplot()}: see {help addplot_option}. 

{p 4 8 2}{it:twoway_options} are other options of {help twoway}. 

{it:Options of codensity juxta} 

{p 4 8 2}{cmd:fstub()} and {cmd:xstub()}: see above under 
{it:Options of codensity generate}. 

{p 4 8 2}{cmd:vertical}: see above under {it:Options of codensity super}.

{p 4 8 2}{cmd:recast()}: see above under {it:Options of codensity super}. 

{p 4 8 2}{cmd:optall()} and {cmd:opt1()} to {cmd:opt20()}: see above under 
{it:Options of codensity super}. 

{p 4 8 2}{opt combine:opts()} are options of {help graph combine}. For
example, this is where to specify a name or filename for a saved graph. 

{p 4 8 2}{it:twoway_options} are other options of {help twoway}. 

{it:Options of codensity bystyle}

{p 4 8 2}{cmd:fstub()} and {cmd:xstub()}: see above under 
{it:Options of codensity generate}. 

{p 4 8 2}{cmd:vertical}: see above under {it:Options of codensity super}. 

{p 4 8 2}{cmd:recast()}: see above under {it:Options of codensity super}. 

{p 4 8 2}{cmd:byopts()} are options of {help by_option}. 

{p 4 8 2}{cmd:addplot()}: see {help addplot_option}. 

{p 4 8 2}{it:twoway_options} are other options of {help twoway}.

{it:Options of codensity stack}

{p 4 4 2}Note that density traces each have a base on the density scale at
integers 1 up. For example, three traces or areas have bases 1, 2, 3.
So density traces are spaced 1 unit apart. Densities are scaled to fit 
within the available space. See also the {opt height(#)} option below. 

{p 4 8 2}{cmd:fstub()} and {cmd:xstub()}: see above under 
{it:Options of codensity generate}. 

{p 4 8 2}{cmd:vertical}: see above under {it:Options of codensity super}. 

{p 4 8 2}{opt recast(newplottype)} is flagged as a particularly useful
option. In practice, {cmd:recast(area)} is by far the most useful
possibility for horizontal layout and {cmd:recast(rarea)} [NB!] is by
far the most useful possibility for vertical layout. See also 
{help advanced options}. 

{p 4 8 2}{opt opt1(twoway_options)} ... {opt opt20(twoway_options)}
specify particular options for the 1st density, ..., 20th density
plotted. For example if the 7th density plotted was especially
interesting or important, you might want to assign a special colour or
line thickness using {cmd:opt7()}. The number of 20 such options is
plucked out of the air as more than the number of densities that might
comfortably be distinguished. 

{p 4 8 2}{cmd:height(#)} specifies the maximum height of densities given
spacing of 1 unit. Densities are scaled so the maximum density, across
all densities shown, is plotted at this height above its baseline. The
default is 0.8. 

{p 4 8 2}{it:twoway_options} are other options of {help twoway}.
	
{it:Options of codensity clear}

{p 4 8 2}{cmd:fstub()} and {cmd:xstub()}: see above under 
{it:Options of codensity generate}. 


{title:Remarks}

{p 4 4 2}What's in a name? A distinct Stata command needs a distinct
name, regardless of whether what it does is standard or original in any
sense.  The name {cmd:codensity} is at least concise. The goals of
{cmd:codensity} include comparison of different estimates and
convenience in calculating and graphing them. Whatever other
connotations appear congenial or convincing are at your discretion. 

{p 4 4 2}{cmd:codensity} is indicative, not definitive. It encapsulates 
some mild prejudices on how its task is best done and does not purport to
address all possible uses of probability density estimates. In
particular, as {cmd:codensity} tries to make it as easy as possible
to generate a bundle of variables for graphing, so also its attitude is
that such variables may be {cmd:replace}d on each use. The user can
easily protect result variables thought to be interesting or useful by
careful choice of variable names or a {help save} of the dataset. 

{p 4 4 2}If two or more of {cmd:kernel()}, {cmd:bwidth()} and
{cmd:trans()} are specified, choices are made in parallel, not
nested. Thus {cmd:kernel(biweight epan) bwidth(100 20)} produces two
plots, not four. 

{p 4 4 2}Density estimates are plotted if positive and not plotted if
zero.  This is not a bug. You are at liberty to disagree that it is a
feature. 

{p 4 4 2}The use of transformations here is distinct from the often
sound and sensible idea that a variable should be transformed and
analysed on that scale, period. 

{p 4 4 2}Densities can often helpfully be plotted as areas. Although
dimensional inflation should usually be resisted (above all, by not
showing volumes where areas will serve), densities as areas can be
effective visually and match the statistical principle that area under
each density trace denotes probability. Wilke (2019) is articulate on
the merits of plotting density estimates as areas. My review at
Amazon.com may be of interest:
{browse "https://www.amazon.com/gp/customer-reviews/R22MWD7RJ6QAFP":https://www.amazon.com/gp/customer-reviews/R22MWD7RJ6QAFP} 

{p 4 4 2}There are many helpful accounts of density estimation at
various technical levels. The books of Silverman (1986), Scott (1992,
2015) and Simonoff (1996) are especially useful. 

{p 4 4 2}There is much ingenious and intricate literature on how to
choose bandwidth. Automated choice of bandwidth is of importance if you
are obliged to produce a large number of estimates without agonising in
detail about each variable or group. 

{p 4 4 2}Turn and turn about, some simple points deserve emphasis: 

{p 8 8 2}* Kernel and bandwidth choices are just that, choices,
regardless of whether you delegate the choice to a command, or more
precisely to the choices made by whoever programmed that command. 

{p 8 8 2}* What no formal rule can do is make choices that match the
scientific judgment of the researcher as summarizing and exposing what
is of interest or importance in the data in a particular project. 

{p 8 8 2}* Serious reports will include explicit detail on the kernel(s)
and bandwidth(s) used. Whether that detail is given on the graph or in
accompanying text is at choice. 

{p 8 8 2}* A marginal rug of distinct values can often be helpful. For
more on rugs in Stata see Cox (2025).  

{p 8 8 2}* Adding a marker for the mean as the centre of gravity of 
each distribution can often be helpful. If you do that, a triangle 
marker conveys the idea of a pivot, natural in this context.


{title:Examples}

{p 4 8 2}{cmd:. local default = cond(c(version) >= 18, "stcolor", "s1color")}{p_end}
{p 4 8 2}{cmd:. set scheme `default'}{p_end}

{p 4 8 2}{cmd:. sysuse auto, clear}{p_end}
{p 4 8 2}{cmd:. label var price "Price (USD)"}{p_end}

{p 4 8 2}{cmd:. codensity gen price, over(foreign) min(0) max(18000)}{p_end}
{p 4 8 2}{cmd:. codensity super, xtitle("`: var label price'") name(DE1, replace)}{p_end}

{p 4 8 2}{cmd:. codensity super, recast(area) opt1(lcolor(orange) color(orange%40)) opt2(lcolor(blue) color(blue%40)) title("Price (USD)") name(DE2, replace)}{p_end}

{p 4 8 2}{cmd:. su _density1, meanonly}{p_end}
{p 4 8 2}{cmd:. local max = r(max)}{p_end}
{p 4 8 2}{cmd:. su _density2, meanonly}{p_end}
{p 4 8 2}{cmd:. local max = max(`max', r(max))}{p_end}
{p 4 8 2}{cmd:. gen where1 = -`max'/15}{p_end}
{p 4 8 2}{cmd:. gen where0 = -`max'/30}{p_end}
{p 4 8 2}{cmd:. local rugcode addplot(scatter where0 price if !foreign, ms(|) mc(orange) || scatter where1 price if foreign, ms(|) mc(blue))}{p_end}
{p 4 8 2}{cmd:. codensity super, recast(area) opt1(lcolor(orange) color(orange%40)) opt2(lcolor(blue) color(blue%40)) title("Price (USD)") ytitle(Density) `rugcode' name(DE3, replace)}{p_end}

{p 4 8 2}{cmd:. codensity clear}{p_end}
{p 4 8 2}{cmd:. codensity gen price, kernel(biweight) bw(400 600 800 1000) labelwith(bwidth)}{p_end}
{p 4 8 2}{cmd:. codensity super, title(Price (USD)) opt1(lp(dash)) opt3(lp(dash)) xla(4000(4000)16000) name(DE4, replace)}{p_end}

{p 4 8 2}{cmd:. codensity bystyle, byopts(title(Price (USD)) note("biweight kernels, different bandwidth")) name(DE5, replace)}{p_end}

{p 4 8 2}{cmd:. codensity clear}{p_end}
{p 4 8 2}{cmd:. codensity gen price, trans(identity root cube_root log) labelwith(trans)}{p_end}
{p 4 8 2}{cmd:. codensity bystyle, byopts(title(Price (USD)) note("transform, estimate and back-transform")) name(DE6, replace)}{p_end}

{p 4 8 2}{cmd:. codensity clear}{p_end}
{p 4 8 2}{cmd:. codensity gen price weight mpg length}{p_end}
{p 4 8 2}{cmd:. codensity juxta, combineopts(name(DE7, replace))}{p_end}

{p 4 8 2}{cmd:. codensity bystyle, name(DE8, replace)}{p_end}

{p 4 8 2}{cmd:. codensity clear}{p_end}
{p 4 8 2}{cmd:. codensity generate mpg, over(foreign) kernel(biweight) bwidth(4) min(8) max(45)}{p_end}
{p 4 8 2}{cmd:. gen where = foreign + 0.97}{p_end}
{p 4 8 2}{cmd:. egen mean = mean(mpg), by(foreign)}{p_end}
{p 4 8 2}{cmd:. codensity stack, recast(area) xtitle(Miles per gallon) xla(10(5)45)  ///}{p_end}
{p 8 8 2}{cmd: note("means are centres of gravity" "biweight kernel: bandwidth 4")  ///}{p_end}
{p 8 8 2}{cmd: addplot(scatter where mean if foreign, ms(T) mc(stc2) msize(*2) ||  ///}{p_end}
{p 8 8 2}{cmd: scatter where mean if !foreign, ms(T) mc(stc1) msize(*2)) name(DE9, replace)}{p_end}

{p 4 8 2}{cmd:. codensity stack, vertical recast(rarea) ytitle(Miles per gallon) yla(10(5)45) name(DE10, replace)}{p_end}

{p 4 8 2}{cmd:. use palmer_penguins, clear}{p_end}
{p 4 8 2}{cmd:. * myaxis is from Stata Journal (Cox 2021)}{p_end}
{p 4 8 2}{cmd:. myaxis SPECIES=species, sort(mean bill_depth)}{p_end}
{p 4 8 2}{cmd:. codensity generate bill_depth, over(SPECIES) min(12) max(22)}{p_end}
{p 4 8 2}{cmd:. codensity super, name(DE11, replace) xtitle("`: var label bill_depth'") legend(row(1) pos(12))}{p_end}


{title:Author}

{p 4 4 2}Nicholas J. Cox, Durham University{break}
n.j.cox@durham.ac.uk


{title:References} 

{p 4 8 2}
Cox, N.J. 2004. 
Graphing distributions. 
{it:Stata Journal} 2: 66{c -}88. See esp. pp.76{c -}78. 

{p 4 8 2}
Cox, N.J. 2007.
Kernel estimation as a basic tool for geomorphological data analysis. 
{it:Earth Surface Processes and Landforms} 32: 1902{c -}1912. (doi:10.1002/esp.1518) 

{p 4 8 2}
Cox, N.J. 2011. 
Stata tip 96: Cube roots. 
{it:Stata Journal} 11: 149{c -}154. 

{p 4 8 2}
Cox, N.J. 2021. 
Ordering or ranking groups of observations.
{it:Stata Journal} 21: 818{c -}837. 

{p 4 8 2}
Cox, N.J. 2025.
Add marginal rugs using marker symbols or axis ticks. 
{it:Stata Journal} 25: in press. 

{p 4 8 2} 
Scott, D.W. 1992.  
{it:Multivariate Density Estimation: Theory, Practice, and Visualization.}
New York: John Wiley.

{p 4 8 2}
Scott, D.W. 2015.  
{it:Multivariate Density Estimation: Theory, Practice, and Visualization.}
Hoboken, NJ: John Wiley.

{p 4 8 2}
Silverman, B.W. 1986. 
{it:Density Estimation for Statistics and Data Analysis.}
London: Chapman and Hall. 
[British curiosum: author is Sir Bernard Silverman since 2018] 

{p 4 8 2}Simonoff, J.S. 1996. 
{it:Smoothing Methods in Statistics.} 
New York: Springer. 

{p 4 8 2}
Wilke, C.O. 2019. 
{it:Fundamentals of Data Visualization: A Primer on Making Informative and Compelling Figures.}
Sebastopol, CA: O'Reilly. 


{title:Also see} 

{p 4 4 2}
{help kdensity}, {help twoway kdensity}, {help twoway__kdensity_gen}  

