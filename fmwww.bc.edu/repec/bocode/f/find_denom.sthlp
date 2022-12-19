{smcl}
{* 18dec2022}{...}
{hline}
help for {hi:find_denom}
{hline}

{title:Finding the denominator: minimum sample size from percentages} 

{p 8 8 2}{cmd:find_denom} #1 [#2 ...] {cmd:,} {opt eps:ilon(precision)}


{title:Description}

{pstd}
{cmd:find_denom} reports minimum sample size and minimum frequencies
given one or more percentages rounded to some precision or resolution. 

{title:Options}

{pstd}
{cmd:epsilon()} is a required option indicating half the perceived
precision or resolution. Thus if percentages are rounded to integers,
specify {cmd:epsilon(0.5)}; if rounded to 1 decimal place, specify
{cmd:epsilon(0.05)}. The thinking is that a report of # means that the
true value is brtween # - epsilon and # + epsilon. 
 
{title:Remarks} 

{pstd}
An old joke with many variants has the following flavour. A naive
researcher is reporting on a rather small project: 33% of the sample
said A, 33% said B, but the other person refused to answer. It is
immediate that the sample size is 3. Only a twist more challenging: What
denominator or sample size underlies a percentage breakdown of 40, 40,
20? That breakdown is consistent with a sample size of 5, with 2, 2, 1
as class frequencies. It is also consistent with any multiple of 5 and,
dependent on amount of rounding, reportably consistent with other
percentage breakdowns too. Thus 2001, 1999, 1000 is exactly 40.02,
39.98, 20.00 as a percentage breakdown and so rounds to 40.0, 40.0, 20.0
to 1 decimal place, as would 2002, 1998 and 1000, and as would many
other possibilities.

{pstd}
Every researcher should know that sample size should always be reported.
Every researcher with any experience knows that does not always happen,
and the culprits are not confined to advertising, journalism, or
politics. Having flagged that this is an ethical issue, we now
concentrate on the technicalities of trying to guess the minimum sample
size consistent with a reported percentage breakdown. We assume honest
and accurate reporting, other than the sample size being suppressed. 

{pstd} 
The problem was discussed by Wallis and Roberts (1956, pp.185{c -}189)
(hereafter WR) and in much more technical detail by Becker, Chambers,
and Wilks (1988) (hereafter BCW). Two ideas arise immediately. First, a
complete set of percentages is not needed to say something about minimum
sample size.  Thus a single percentage reported as 33% implies that the
sample size cannot be 2 and must be at least 3.  Second, the smallest
percentage reported, or if smaller the smallest positive difference
between two percentages reported, gives another handle on the minimum
sample size.  Thus with a percentage breakdown of 40, 30, 30, the
smallest positive difference is 10 and equivalently 100/10 = 10 is the
minimum sample size. 

{pstd}
WR (p.186) report a fictitious percentage breakdown 

{space 4}23.1 
{space 4}15.4 
{space 4}30.8 
{space 4}19.2 
{space 4} 7.7
{space 4} 3.8

{pstd}-- from which both the smallest percentage and the smallest positive
difference are 3.8, suggesting a minimum sample size of 100/3.8, which
rounds as an integer to 26. The implied frequencies are thus 

{space 4}6 
{space 4}4 
{space 4}8 
{space 4}5 
{space 4}2 
{space 4}1   

{pstd}WR (1956, pp.187{c -}188) report percentage breakdowns of movie
ratings from {it:Consumer Reports} August 1949, p.383. The categories
are in turn percentages reporting Excellent, Good, Fair, and Poor. Some
examples are 

{space 4}Alias Nick Beal       6 27 47 20
{space 4}Bride of Vengeance   11 22 56 11 

{pstd}BCW (p.272) report these percentages for considering vendor for
1986 from a personal computer magazine: 

{space 4}Ours  14.6 
{space 4}A     12.2 
{space 4}B     12.2
{space 4}C      7.3
{space 4}D      7.3 

{pstd}They report an algorithm and S code with this recipe for
proportions (my wording). The idea is just to bump up the sample size
until implied percentages are all consistent with the stated precision. 

{space 4}f   <- vector of proportions
{space 4}eps <- precision
{space 4}n   <- 1 

{space 4}repeat {c -(}
{space 4}i <- f * n rounded to integers 
{space 8}if each i is in [(# - eps) * this i, (# + eps) * this i]  
{space 12}break with result 
{space 8}n <- n + 1
{space 4}{c )-} 

{pstd}It is this algorithm, translated from S to Stata, but adapted for
percentage input, that is implemented here. 

{pstd}BCS (pp.274{c -}277) further discuss speeding-up computations
and allowing a certain number of outliers, in essence percentages that do
not fit, say because they were reported incorrectly. These elaborations
are not implemented here, but should be of interest for a deeper study. 

{pstd}
On the problem of how often rounded percentages sum to exactly 100, see 
Mosteller, Youtz, and Zahn (1967) and Diaconis and Freedman (1979).  


{title:Examples}

{p 4 8 2}{cmd:. find_denom 23.1 15.4 30.8 19.2 7.7 3.8, eps(0.05)}{p_end}

{p 4 8 2}{cmd:. find_denom 6 27 47 20, eps(0.5)}{p_end}

{p 4 8 2}{cmd:. find_denom 11 22 56 11, eps(0.5)}{p_end}

{p 4 8 2}{cmd:. find_denom 14.6 12.2 12.2 7.3 7.3, eps(0.05)}{p_end}


{title:Author}

{p 4 4 2}Nicholas J. Cox, Durham University{break}
n.j.cox@durham.ac.uk


{title:References} 

{phang}
Becker, R. A., J. M. Chambers and A. R. Wilks. 1988. 
{it:The New S Language: A Programming Environment for Data Analysis and Graphics.} 
Pacific Grove, CA: Wadsworth & Brooks-Cole. 

{phang}
Diaconis, P. and D. Freedman. 
1979. 
On rounding percentages. 
{it:Journal of the American Statistical Association} 74: 359{c -}364.

{phang}
Mosteller, F., C. Youtz and D. Zahn. 1967. 
The distribution of sums of rounded percentages. 
{it:Demography} 4: 850{c -}858. 
Reprinted in Fienberg, S. E. and D. C. Hoaglin (eds) 2006. 
{it:Selected Papers of Frederick Mosteller}. New York: Springer, 399{c -}411.

{phang}
Wallis, W. A. and H. V. Roberts. 1956. 
{it:Statistics: A New Approach.} 
Glencoe, IL: Free Press.  

