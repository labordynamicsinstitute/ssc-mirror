{smcl}
{* 29jul2026}{...}
{hline}
help for {hi:logistic_scores}
{hline}

{title:Logistic scores from grade variables}

{p 8 17 2}{cmd:logistic_scores}
{it:varname}	
{weight}
{ifin}
{cmd:,} 
{opt gen:erate(newvar)}
[
{cmdab:symm:etric}
{help tabdisp:tabdisp_options} 
]

{p 4 4 2}{cmd:fweights} and {cmd:aweights} are allowed. 


{title:Description}

{p 4 4 2}{cmd:logistic_scores} calculates logistic scores in the sense
of Mosteller and Tukey (1977) from a graded ordinal variable. 


{title:Remarks}

{p 4 4 2}For concreteness consider a graded ordinal variable with
possible values 1, 2, 3, 4, 5. Here the numbering conveys order but
strictly nothing else. In particular, equal spacing is a convention for
convenience and not meant to imply anything else.  Graded variables like
these abound in assessment of movies, hotels, courses, teachers, and
much else. 

{p 4 4 2}If you have an ordinal variable expressed only as text (e.g.
"strongly disagree", ..., "strongly agree") such a variable should first
be mapped to consecutive integers.  See help on {help label} and 
{help encode}. 

{p 4 4 2}Suppose that we calculate proportions of the data at each grade, 
say {it:p}_1, {it:p}_2, {it:p}_3, {it:p}_4, {it:p}_5. 
Given those we can calculate cumulative proportions 
{it:P}_1 = {it:p}_1, 
{it:P}_2 = {it:P}_1 + {it:p}_2, 
{it:P}_3 = {it:P}_2 + {it:p}_3, 
{it:P}_4 = {it:P}_3 + {it:p}_4, 
{it:P}_5 = {it:P}_4 + {it:p}_5. 
The last is always identically 1, but otherwise we have 4 breakpoints
{it:P}_1 to {it:P}_4. 

{p 4 4 2}More generally, {it:J} grades running {it:j} = 1,...,{it:J}
lead to that many probabilities {it:p}_{it:j} and that many cumulative
probabilities {it:P}_{it:j}. Define additionally {it:P}_0 := 0.

{p 4 4 2}The idea of logistic scores is to invoke a latent variable that
has a standard logistic distribution with mean zero and quantile
function logit {it:P} = ln [{it:P} / (1 - {it:P})] = ln {it:P} - ln (1
- {it:P}). Such a distribution is conveniently simple and tractable. It
 has mean 0, skewness 0, and kurtosis 4.2. Incidentally in mean,
skewness and kurtosis the logistic resembles Student's {it:t}
distribution with 9 df.

{p 4 4 2}Given that, the distribution is considered divided into slices
by breakpoints on the cumulative probability scale {it:P}_1 to
{it:P}_{it:J}-1 with corresponding breakpoints on the logit scale
defined by logit {it:P}. The logistic scores are the centres of gravity
of each slice. The centre of gravity of a slice bounded by lower limit
{it:P}_{it:j-1} =: {it:A} and upper limit {it:P}_{it:j} =:
{it:B} is [phi({it:B}) - phi({it:A})] / ({it:B} - {it:A}) where
phi({it:x}) is {it:x} ln {it:x} - (1 - {it:x}) ln (1 - {it:x}), noting
that 0 ln 0 is to be returned as 0.  

{p 4 4 2}The derivation of the precise recipe for centres of gravity 
is not given by Mosteller and Tukey (1977), perhaps as being too 
trivial for mathematical readers and too technical for other readers.
The argument is sketched in an accompanying .pdf document. 


{title:Options}

{p 4 8 2}{cmd:generate()} is a required option and specifies the name of 
a new variable to hold the logistic scores. The forms 
{cmd:generate(float }{it:newvar}{cmd:)} and 
{cmd:generate(double }{it:newvar}{cmd:)}
are allowed to specify storage type. 

{p 4 8 2}{cmd:symmetric} insists on scores symmetric about a middle
value. For example, with five levels, scores for 1 and 5 are identical,
as are those for 2 and 4; or with six levels, scores for 1 and 6 are
identical, as are those for 2 and 5 and for 3 and 4. Calculation
proceeds by averaging the corresponding probabilities and using each
average twice instead of the original probabilities. 

{p 4 8 2}{it:tabdisp_options} are options of {help tabdisp}.  


{title:Examples}

{p 4 8 2}{cmd:. * repair record }{p_end}
{p 4 8 2}{cmd:. sysuse auto, clear}{p_end}
{p 4 8 2}{cmd:. logistic_scores rep78, gen(lgstc)}{p_end}
{p 4 8 2}{cmd:. logistic_scores rep78, symmetric gen(lgstc_s)}{p_end}

{p 4 8 2}{cmd:. * another way to do it }{p_end}
{p 4 8 2}{cmd:. local text : variable label rep78}{p_end}
{p 4 8 2}{cmd:. contract rep78, nomiss }{p_end}
{p 4 8 2}{cmd:. logistic_scores rep78 [fw=_freq], gen(lgstc)}{p_end}

{p 4 8 2}{cmd:. gen cufreq = sum(_freq) }{p_end}
{p 4 8 2}{cmd:. gen cuprob = cufreq / cufreq[_N]}{p_end}
{p 4 8 2}{cmd:. gen X = logit(cuprob)}{p_end}

{p 4 8 2}{cmd:. set obs 1000}{p_end}
{p 4 8 2}{cmd:. range x -6 6}{p_end}
{p 4 8 2}{cmd:. gen density = exp(x) / (1 + exp(x))^2}{p_end}
{p 4 8 2}{cmd:. gen where = -0.007}{p_end}

{p 4 8 2}{cmd:. foreach y in 0.05 0.1 0.15 0.2 0.25 {c -(}}{p_end}
{p 4 8 2}{cmd:. 	local ylabel `ylabel' `y' "`y'"}{p_end}
{p 4 8 2}{cmd:. {c )-}}{p_end}

{p 4 8 2}{cmd:. twoway mspline density x, color(black) lw(thick) bands(200) ///}{p_end}
{p 4 8 2}{cmd:|| area density x if x < X[1], color(red*0.8) ///}{p_end}
{p 4 8 2}{cmd:|| area density x if inrange(x, X[1], X[2]), color(red*0.4) ///}{p_end}
{p 4 8 2}{cmd:|| area density x if inrange(x, X[2], X[3]), color(white) ///}{p_end}
{p 4 8 2}{cmd:|| area density x if inrange(x, X[3], X[4]), color(blue*0.4) ///}{p_end}
{p 4 8 2}{cmd:|| area density x if x > X[4], color(blue*0.8) ///}{p_end}
{p 4 8 2}{cmd:|| scatter where lgstc, ms(T) msize(large) mc(black) ///}{p_end}
{p 4 8 2}{cmd:mlabel(rep78) mlabpos(6) mlabcolor(black) mlabsize(medium) /// }{p_end}
{p 4 8 2}{cmd:|| scatteri 0 -6 0 6, recast(line) lcolor(black) ysc(r(-0.025, .)) /// }{p_end}
{p 4 8 2}{cmd:ytitle(density) yla(0 `ylabel' ) ///}{p_end}
{p 4 8 2}{cmd:xtitle(logistic scores) xla(-6/6) legend(off) ///}{p_end}
{p 4 8 2}{cmd:subtitle("`text'", place(left)) ///}{p_end}
{p 4 8 2}{cmd:note("cumulative probabilities define slices;" "centres of gravity define scores") ///}{p_end}
{p 4 8 2}{cmd:name(G1, replace)}{p_end}

{p 4 8 2}{cmd:. * Mosteller and Tukey 1977 p.106 }{p_end}
{p 4 8 2}{cmd:. clear }{p_end}
{p 4 8 2}{cmd:. set obs 5}{p_end}
{p 4 8 2}{cmd:. gen MT106 = _n }{p_end}
{p 4 8 2}{cmd:. label def MT106 1 A 2 B 3 C 4 D 5 E }{p_end}
{p 4 8 2}{cmd:. label val MT106 MT106 }{p_end}
{p 4 8 2}{cmd:. decode MT106, gen(letters)}{p_end}
{p 4 8 2}{cmd:. gen freq = real(word("127 497 3243 231 74", MT106))}{p_end}
{p 4 8 2}{cmd:. logistic_scores MT106 [fw=freq], gen(lgstc_MT)}{p_end}

{p 4 8 2}{cmd:. gen cufreq = sum(freq) }{p_end}
{p 4 8 2}{cmd:. gen cuprob = cufreq / cufreq[_N]}{p_end}
{p 4 8 2}{cmd:. gen X = logit(cuprob)}{p_end}

{p 4 8 2}{cmd:. set obs 1000}{p_end}
{p 4 8 2}{cmd:. range x -6 6}{p_end}
{p 4 8 2}{cmd:. gen density = exp(x) / (1 + exp(x))^2}{p_end}
{p 4 8 2}{cmd:. gen where = -0.007}{p_end}

{p 4 8 2}{cmd:. foreach y in 0.05 0.1 0.15 0.2 0.25 {c -(}}{p_end}
{p 4 8 2}{cmd:. 	local ylabel `ylabel' `y' "`y'"}{p_end}
{p 4 8 2}{cmd:. {c )-}}{p_end}

{p 4 8 2}{cmd:. twoway mspline density x, color(black) lw(thick) bands(200) ///}{p_end}
{p 4 8 2}{cmd:|| area density x if x < X[1], color(red*0.8) ///}{p_end}
{p 4 8 2}{cmd:|| area density x if inrange(x, X[1], X[2]), color(red*0.4) ///}{p_end}
{p 4 8 2}{cmd:|| area density x if inrange(x, X[2], X[3]), color(white) ///}{p_end}
{p 4 8 2}{cmd:|| area density x if inrange(x, X[3], X[4]), color(blue*0.4) ///}{p_end}
{p 4 8 2}{cmd:|| area density x if x > X[4], color(blue*0.8) ///}{p_end}
{p 4 8 2}{cmd:|| scatter where lgstc_MT, ms(T) msize(large) mc(black) ///}{p_end}
{p 4 8 2}{cmd:mlabel(letters) mlabpos(6) mlabcolor(black) mlabsize(medium) /// }{p_end}
{p 4 8 2}{cmd:|| scatteri 0 -6 0 6, recast(line) lcolor(black) ysc(r(-0.025, .)) /// }{p_end}
{p 4 8 2}{cmd:ytitle(density) yla(0 `ylabel' ) ///}{p_end}
{p 4 8 2}{cmd:xtitle(logistic scores) xla(-6/6) legend(off) ///}{p_end}
{p 4 8 2}{cmd:subtitle("Mosteller and Tukey 1977 p.106", place(left)) ///}{p_end}
{p 4 8 2}{cmd:note("cumulative probabilities define slices;" "centres of gravity define scores") ///}{p_end}
{p 4 8 2}{cmd:name(G2, replace)}{p_end}

{p 4 8 2}{cmd:. * Lake District cirques Evans and Cox 1995; Evans 2015 }{p_end}
{p 4 8 2}{cmd:. clear }{p_end}
{p 4 8 2}{cmd:. set obs 5}{p_end}
{p 4 8 2}{cmd:. gen grade = _n }{p_end}
{p 4 8 2}{cmd:. * reverses 1995 order }{p_end}
{p 4 8 2}{cmd:. label def grade 1 poor 2 marginal 3 definite 4 "well-defined" 5 classic}{p_end}
{p 4 8 2}{cmd:. label val grade grade }{p_end}
{p 4 8 2}{cmd:. decode grade, gen(words)}{p_end}
{p 4 8 2}{cmd:. gen freq = real(word("35 36 44 31 11", grade))}{p_end}
{p 4 8 2}{cmd:. logistic_scores grade [fw=freq], gen(lgstc_grade)}{p_end}

{p 4 8 2}{cmd:. gen cufreq = sum(freq) }{p_end}
{p 4 8 2}{cmd:. gen cuprob = cufreq / cufreq[_N]}{p_end}
{p 4 8 2}{cmd:. gen X = logit(cuprob)}{p_end}

{p 4 8 2}{cmd:. set obs 1000}{p_end}
{p 4 8 2}{cmd:. range x -6 6}{p_end}
{p 4 8 2}{cmd:. gen density = exp(x) / (1 + exp(x))^2}{p_end}
{p 4 8 2}{cmd:. gen where = -0.007}{p_end}

{p 4 8 2}{cmd:. foreach y in 0.05 0.1 0.15 0.2 0.25 {c -(}}{p_end}
{p 4 8 2}{cmd:. 	local ylabel `ylabel' `y' "`y'"}{p_end}
{p 4 8 2}{cmd:. {c )-}}{p_end}

{p 4 8 2}{cmd:. twoway mspline density x, color(black) lw(thick) bands(200) ///}{p_end}
{p 4 8 2}{cmd:|| area density x if x < X[1], color(red*0.8) ///}{p_end}
{p 4 8 2}{cmd:|| area density x if inrange(x, X[1], X[2]), color(red*0.4) ///}{p_end}
{p 4 8 2}{cmd:|| area density x if inrange(x, X[2], X[3]), color(white) ///}{p_end}
{p 4 8 2}{cmd:|| area density x if inrange(x, X[3], X[4]), color(blue*0.4) ///}{p_end}
{p 4 8 2}{cmd:|| area density x if x > X[4], color(blue*0.8) ///}{p_end}
{p 4 8 2}{cmd:|| scatter where lgstc_grade, ms(T) msize(large) mc(black) ///}{p_end}
{p 4 8 2}{cmd:mlabel(words) mlabpos(6) mlabcolor(black) mlabsize(small) /// }{p_end}
{p 4 8 2}{cmd:|| scatteri 0 -6 0 6, recast(line) lcolor(black) ysc(r(-0.025, .)) /// }{p_end}
{p 4 8 2}{cmd:ytitle(density) yla(0 `ylabel' ) ///}{p_end}
{p 4 8 2}{cmd:xtitle(logistic scores) xla(-6/6) legend(off) ///}{p_end}
{p 4 8 2}{cmd:subtitle("Lake District cirques", place(left)) ///}{p_end}
{p 4 8 2}{cmd:note("cumulative probabilities define slices;" "centres of gravity define scores") ///}{p_end}
{p 4 8 2}{cmd:name(G3, replace)}{p_end}


{title:Author}

{p 4 4 2}Nicholas J. Cox, Durham University, U.K.{break} 
n.j.cox@durham.ac.uk


{title:References}

{p 4 8 2}Balakrishnan, N. (ed.) 1992. 
{it:Handbook of the Logistic Distribution.}
New York: Marcel Dekker. 

{p 4 8 2}Evans, I.S. 2015. The Lake District cirque inventory: updated. In 
McDougall, D.A. and Evans, D.J.A. (eds)
{it:The Quaternary of the Lake District: Field Guide.} 
London: Quaternary Research Association, 83{c -}95.

{p 4 8 2}Evans, I.S. and Cox, N.J. 1995. 
The form of glacial cirques in the English Lake District, Cumbria. 
{it:Zeitschrift f{c u:}r Geomorphologie} 39: 175{c -}202.  

{p 4 8 2}Mosteller, F. and Tukey, J.W. 1977. 
{it:Data Analysis and Regression: A Second Course in Statistics.}
Reading, MA: Addison-Wesley. Chapters 5F, 5H, 11F, 11G. 

{p 4 8 2}Tukey, J.W. 1961. Data analysis and behavioral science or learning
to bear the quantitative man's burden by shunning badmandments. In 
Jones, L.V. (ed) {it: The Collected Works of John W. Tukey.} 
{it:Volume III: Philosophy and Principles of Data Analysis 1949{c -}1964.}
Monterey, CA: Wadsworth, 187{c -}389. 



