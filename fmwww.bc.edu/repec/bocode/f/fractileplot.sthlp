{smcl}
{* 11oct2006/13oct2006/19dec2023/20dec2023}{...}
{hline}
help for {hi:fractileplot}
{hline}

{title:Smoothing with respect to distribution function predictors}

{p 8 12 2} 
{cmd:fractileplot} 
{it:yvar xvarlist} 
{ifin}
[{cmd:,}
{cmd:a(}{it:#}{cmd:)}
{cmdab:bw:idth(}{it:#}{cmd:)}
{cmdab:deg:ree(}{it:#}{cmd:)}
{cmdab:k:ernel(}{it:kernel_name}{cmd:)}
{break}
{cmdab:cyc:les(}{it:#}{cmd:)}
{cmd:log}
{break}
{cmd:combine(}{it:combine_options}{cmd:)} 
{cmdab:dr:aw(}{it:numlist}{cmd:)}
{cmd:nograph}
{cmdab:nopt:s}
{cmdab:om:it(}{it:numlist}{cmd:)}
{cmdab:sc:atter(}{it:scatter_options}{cmd:)} 
{it:line_options}
{break}
{cmdab:gen:erate(}{it:stub}{cmd:)} 
{cmdab:p:redict(}{it:newvar}{cmd:)}
{cmd:replace}]


{title:Description}

{p 4 4 2} 
{cmd:fractileplot} computes smooths of {it:yvar} on all predictors in
{it:xvarlist} simultaneously; that is, each smooth is adjusted for the others.
Each predictor x_j is treated on the scale of its distribution function,
F(x_j), estimated for a sample of n as (rank of x_j - a) / (n - 2a + 1).  a
defaults to 0.5. Smoothing is with {helpb lpoly}. 
Fitted values may be saved in new variables with names
beginning with {it:stub}, as specified in the {cmd:generate()} option. 

{p 4 4 2}By default, for each {it:xvar} in {it:xvarlist} adjusted
values of {it:yvar} and the smooth for F({it:xvar}) are plotted against
F({it:xvar}).  See {hi:Remarks} for more details.


{title:Options} 

{p 4 4 2}{it:Smoothing}

{p 4 8 2}{cmd:a(}{it:#}{cmd:)} specifies a in the formula for F.  The default
is a = 0.5, giving (i - 0.5) / n. Other choices include a = 0, giving i / (n +
1), and a = 1/3, giving (i - 1/3) / (n + 1/3). More discussion on this 
is available at {browse "http://www.stata.com/support/faqs/stat/pcrank.html"}. 

{p 4 8 2}
{cmd:bwidth(}{it:#}{cmd:)} specifies the halfwidth of the kernel. 
The default is 0.2. 
Note that each distribution function has values in (0, 1). The choice 
of default has no more sanction than that and some experience that it 
works quite well. 

{p 4 8 2}
{cmd:degree(}{it:#}{cmd:)} specifies the degree of the polynomial to be 
used in the smoothing.  0 is the default, meaning local mean smoothing.

{p 4 8 2}{cmd:kernel()} specifies the kernel. {cmd:biweight} is the default.

{p 4 4 2}{it:Fitting}

{p 4 8 2}{cmd:cycles(}{it:#}{cmd:)} sets the number of cycles. The default is
{cmd:cycles(3)}.

{p 4 8 2}{cmd:log} displays the squared correlation coefficient between the
overall fitted values and {it:yvar} at each cycle for monitoring convergence.
This option is provided mainly for pedagogic interest.

{p 4 4 2}{it:Graphics}

{p 4 8 2}{cmd:combine(}{it:combine_options}{cmd:)} specifies any of the
options allowed by the {helpb graph combine} command.  Useful examples are
{cmd:combine(ycommon)} and {cmd:combine(saving(}{it:graphname}{cmd:))}.

{p 4 8 2} {cmd:draw(}{it:numlist}{cmd:)} specifies that smooths for a subset of
the variables in {it:xvarlist} be plotted. The elements of {it:numlist} are
indexes determined by the order of the variables in {it:xvarlist}.  For
example, {cmd:fractileplot y x1 x2 x3, draw(2 3)} would plot smooths only for
F({cmd:x2}) and F({cmd:x3}). By default results for all variables in
{it:varlist} are plotted. {cmd:draw()} takes precedence over {cmd:omit()} in
the sense that results for variables included (by index) in {it:numlist} are
plotted, even if they are excluded by {cmd:omit()}. See also {cmd:omit()}.

{p 4 8 2}{cmd:nograph} suppresses the graph.  

{p 4 8 2}{cmd:omit(}{it:numlist}{cmd:)} specifies that smooths for a subset of
the variables in {it:xvarlist} not be plotted. The elements of {it:numlist} are
indexes determined by the order of the variables in {it:varlist}. For example,
{cmd:fractileplot y x1 x2 x3, omit(3)} would plot smooths only for F({cmd:x1}) and
F({cmd:x2}). By default results for no variables in {it:varlist} are omitted.
{cmd:draw()} takes precedence over {cmd:omit()}.  See also {cmd:draw()}.

{p 4 8 2}{cmd:nopts} suppresses the points in the plots. Only the lines
representing the smooths are drawn.

{p 4 8 2}{cmd:scatter(}{it:scatter_options}{cmd:)} specifies any of the options
allowed by the {helpb scatter} command.  These should be specified to control
the rendering of the data points.  The default includes {cmd:msymbol(oh)}, or
{cmd:msymbol(p)} with over 299 observations. 

{p 4 8 2}{it:line_options} are any of the options allowed with {helpb line}.
These should be specified to control the rendering of the smoothed lines or the
overall graph. 

{p 4 4 2}{it:Results}

{p 4 8 2} {cmd:generate(}{it:stub}{cmd:)} specifies that fitted values for each
member of {it:xvarlist} be saved in new variables with names beginning with
{it:stub}.

{p 4 8 2}{cmd:predict(}{it:newvar}{cmd:)} specifies that the predicted values
be saved in new variable {it:newvar}. 

{p 4 8 2}{cmd:replace} allows variables specified by any of the
{cmd:generate()} and {cmd:predict()} options to be replaced if they already
exist.


{title:Remarks}

{p 4 4 2}The intent of this command is exploratory. It may help in signalling 
dependence structure, or its lack, given an outcome and a bundle of (potential) predictors.

{p 4 4 2}Smoothing with respect to distribution functions has various
elementary attractions. An F scale provides a common scale for variables with
different level and spread and even different units.  Subject to the occurrence
of ties, values are equally spaced on the F scale and so in good condition for
smoothing. This can be especially useful when predictors are highly skewed.  F
is invariant under strictly increasing transformations, so that for example
F(log x) is identical to F(x) so long as x > 0. This can be useful when it is
not clear whether predictors should be transformed. 

{p 4 4 2}At users' discretion, the predictors may include binary, ordinal or 
even nominal predictors. For example, a binary predictor will produce two 
clusters of points spaced 0.5 apart on the corresponding plot.  

{p 4 4 2}Sen (2005) gives a useful account of kernel smoothing of
responses with respect to distribution functions of predictors. The canonical
reference is Mahalanobis (1960), which introduced the term "fractile graphical
analysis". Mahalanobis plotted means of one variable for bins defined by
selected fractiles of the other variable.  Binning and averaging now appear
arbitrary and awkward, and some kind of kernel-based smoothing is more
appealing. The approach in {cmd:fractileplot} is based on methodology for
generalised additive models (Hastie and Tibshirani 1990). 

{p 4 4 2}The idea of plotting the values of one or more variables versus 
the rank of another can be found in Wallace (1889), Lock (1906) and 
Fisher (1925). See Edwards (2013) for commentary. 

{p 4 4 2}For one independent invention, see Van Kerm (2006) on income mobility
profiles. 

{p 4 4 2}Terminology is a little problematic here.  Terms such as "fractile graph" (Sen
2005) and "fractile plot" (Nordhaus 2006) persist in recent literature for
modern versions of Mahalanobis' plots, even though neither ordinate nor
abscissa in the resulting graphs is a fractile.  The term "fractile" was
introduced to the English literature by Hald (1952) with the sense of
"quantile", but it has never supplanted "quantile" and is sometimes misunderstood
to mean fraction or cumulative probability or plotting position (e.g. Nordhaus
2006). Hald used "fractile diagram" as a name for plots of observed quantiles against reference 
(e.g. normal) distributions. In Stata
terms, many of his examples are equivalent to {cmd:qnorm} with axes reversed. 
This usage also continues in recent literature (e.g. Bl{c ae}sild and 
Granfeldt 2003). 

{p 4 4 2}An R-square (squared correlation coefficient) is provided as a
goodness of fit indicator. However, this R-square can typically be increased simply
by just smoothing less, which is often likely to be unhelpful. As the resulting
predictions come closer to interpolating the data, R-square will approach 1,
but scientific usefulness and the possibility of insight will usually diminish. 

{p 4 4 2}Note that you do not need the machinery here to do this for just 
one predictor. The following is a basic recipe: 

{p 8 8 2}{cmd:. gen touse = (y < .) & (x < .)}{p_end}
{p 8 8 2}{cmd:. egen abscissa = rank(x) if touse}{p_end}
{p 8 8 2}{cmd:. count if touse}{p_end}
{p 8 8 2}{cmd:. replace abscissa = (abscissa - 0.5) / r(N)}{p_end}
{p 8 8 2}{cmd:. lpoly y abscissa, xti("fraction of data")} 

{p 4 4 2} 
Suppose that there are p >= 1 predictors.  {cmd:fractileplot} estimates the
smooths f_1,...,f_p by using a backfitting algorithm and a local 
polynomial smoother S[y|F(x_j)] for each predictor, as follows:

{p 4 8 2} 
1.  Initialize: alpha = mean(y), f_1,...,f_p 
estimated by multiple linear regression.

{p 4 8 2} 
2.  Cycle: j = 1,...,p, 1,...,p, ...

{p 8 8 2} 
f_j = S[y - alpha - sum_{i != j} f_i|F(x_j)]

{p 4 8 2} 
3.  Continue for {cmd:cycles()} rounds.

{p 4 4 2}
No convergence criterion is applied. In practice, three cycles are
usually more than sufficient to get results adequate for exploratory work. 

{p 4 4 2} 
The smooths are adjusted so that the mean of each equals the mean of {it:yvar}.

{p 4 4 2}
The points in the plots provided by {cmd:fractileplot}
depict y - sum_{i != j} f_i|F(x_j), i.e., the partial residuals plus alpha.


{title:Examples} 

{p 4 8 2}
{cmd:. sysuse auto, clear}

{p 4 8 2} 
{cmd:. fractileplot mpg weight displ length}

{p 4 8 2}
{cmd:. fractileplot mpg weight displ length, bwidth(0.3)}

{p 4 8 2}
{cmd:. fractileplot mpg weight displ length, degree(1) bwidth(0.4)}

{p 4 8 2}
{cmd:. fractileplot mpg weight displ length, generate(S) nograph}

{p 4 8 2}
{cmd:. fractileplot mpg weight displ length, omit(2) combine(saving(graph1))}

{p 4 4 2}For comparison, bivariate smooths may be compared like this: 

{p 4 8 2}{cmd:. foreach v in weight displ length {c -(}}{p_end}
{p 4 8 2}{cmd:. {space 8}fractileplot mpg `v', combine(saving(fl_`v'))}{p_end}
{p 4 8 2}{cmd:. {c )-}}{p_end}
{p 4 8 2}{cmd:. graph combine "fl_weight" "fl_displ" "fl_length"} 


{title:Author} 

{p 4 4 2}Nicholas J. Cox{break} 
         Durham University{break} 
	 n.j.cox@durham.ac.uk 


{title:Acknowledgements} 

{p 4 4 2}The main features of the implementation here depend on the work of 
Patrick Royston, as reported by Royston and Cox (2005). Thanks to Philippe
Van Kerm for telling me about his work. 


{title:References}

{p 4 8 2}Bl{c ae}sild, P. and Granfeldt, J. 2003. 
{it:Statistics with Applications in Geology and Biology.} 
Boca Raton, FL: Chapman & Hall/CRC. 

{p 4 8 2}
Edwards, A.W.F. 2013. Robert Heath Lock and his textbook of genetics, 1906. 
{it:Genetics} 194: 529{c –}537. 
{browse "https://doi.org/10.1534/genetics.113.151266"} 

{p 4 8 2}Fisher, R.A. 1925. 
{it:Statistical Methods for Research Workers.}
Edinburgh: Oliver and Boyd. 

{p 4 8 2} 
Hald, A. 1952. 
{it:Statistical Theory with Engineering Applications.} 
New York: John Wiley. 

{p 4 8 2}
Hastie, T. and Tibshirani, R. 1990.
{it:Generalized Additive Models.} 
London: Chapman and Hall. 

{p 4 8 2}
Lock, R.H. 1906. 
{it:Recent Progress in the Study of Variation, Heredity, and Evolution.}
London: John Murray. 

{p 4 8 2}
Mahalanobis, P.C. 1960. A method of fractile graphical analysis. 
{it:Econometrica} 28: 325{c -}351. Reprinted 1961. 
{it:Sankhya} Series A 23: 41{c -}64.

{p 4 8 2}
Nordhaus, W.D. 2006. Geography and macroeconomics: new data and new
findings. {it:Proceedings, National Academy of Sciences} 103(10): 3510{c -}3517.

{p 4 8 2}
Royston, P. and Cox, N.J. 2005. 
A multivariable scatterplot smoother. 
{it:Stata Journal} 5(3): 405{c -}412. 

{p 4 8 2}
Sen, B. 2005. Estimation and comparison of fractile graphs using kernel
smoothing techniques. {it:Sankhya} 67: 305{c -}334. 
{browse "https://www.jstor.org/stable/pdf/25053435.pdf"} 

{p 4 8 2}
Van Kerm, P. 2006. Comparisons of income mobility profiles. IRISS 
Working Paper 2006-03, CEPS/INSTEAD. 
{browse "http://ideas.repec.org/p/irs/iriswp/2006-03.html"} 

{p 4 8 2}
Wallace, A.R. 1889. 
{it:Darwinism: An Exposition of the Theory of Natural Selection with Some of its Applications.}
London: Macmillan. 

{p 4 4 2}Note: {it:Sankhya} should carry a bar accent on 
its final "a". 


{title:Also see}

{p 4 13 2}Online:  {helpb lpoly}{p_end}

