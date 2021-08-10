{smcl}
{* *! version 3 DEC2013}{...}
{cmd:help pisaqreg} {right:also see:  {help pisareg} {help pisastats} {help pisacmd} {help pisaoaxaca} {help pisadeco} {help pv}}
{hline}

{title:Title}

{p2colset 5 17 20 2}{...}
{p2col :{hi: pisaqreg} {hline 2}} Quantile regression with PISA data and plausible values{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 18 2}
{cmd:pisaqreg}
{depvar} [{indepvars}] {ifin}
   [{cmd:,} {it:options}]
   
{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main options}

{synopt :{opt cnt(string)}} Specifies a list of countries for which results will be calculated.
If OECD is specified, then results are provided for all OECD countries participating in this cycle. 
Similarly, specifying PARTNERS will produce results for all partner countries and economies participating in this cycle.
Specifying PISA will produce similar results for all countries participating in this cycle. 
If ALL is specified, then results are provided for all countries currently in your dataset. 
Results can be provided for distinct groups of countries by specifying a list with three letter ISO codes. 
For example, option cnt("AUS DEU POL") will produce results for Australia, Germany and Poland. 
The OECD average is calculated only when OECD or PISA is specified.
Otherwise simple average is calculated.
If you don't specify this option, the results will be produced for all values of the variable cnt. 
This variable must exist in the dataset.
{p_end}

{synopt :{help prefix_saving_option:{bf:{ul:save}(}{it:filename}{bf:, ...)}}}save
	results to {it:filename}. You have to specify this option {p_end}
	
{syntab: Optional}

{synopt :{opt q(int)}}  Estimates # quantile; default is q(5) which corresponds to the median {p_end}

{synopt :{opt over(var)}} Specifies a categorical variable for which you want to obtain statistics by each category. 
The variable must be numerical with a sequence of integers denoting each category. {p_end}

{synopt :{opt round(int)}} Specifies how many decimal places you want to see in results tables. Default is 2. {p_end}

{synopt :{opt cycle(int)}} Specifies which PISA cycle you analyze.
This affects the list of countries recognized as OECD, PISA or PARTNERS in option cnt() 
as well as which names of plausible values will be recognized when given as dependent variable. 
Default is 2012. {p_end}

{synopt :{opt fast}} Specifying this option dramatically speeds up calculations at the cost of not fully valid estimates of standard errors. 
Statistic itself is calculated properly, however, standard errors are calcuated analytically.
These standard errors are usually overstimated comparing to the original BRR method. {p_end}

{synoptline}


{title:Description}

{pstd}
You can use {cmd:pisaqreg} to run quantile regression with PISA data.
First variable listed after {cmd:pisadeco} is the dependent variable.
You can use any plausible value as the dependent variable but just specify last letters after pv*.
Thus, for pv*read just type read.
For any dataset you can type read, math, scie in which case the regression will be run 5 times on plausible values in reading, mathematics or science, respectively.
For any dataset you can also use proflevel which will run regression 5 times on dummy indicator (or any other variable) that is based on any plausible value.
You can also use any plausible value existing in PISA dataset.
For PISA 2000 you can type: math, scie, read, read1, read2, read3, math1, math2, proflevel.
For PISA 2003 you can type: math, scie, read, math1, math2, math3, math4, prob, proflevel.
For PISA 2006 you can type: math, scie, read, intr, supp, eps, isi, use, proflevel.
For PISA 2009 you can type: math, scie, read, era, read1, read2, read3, read4, read5, proflevel.
For PISA 2012 you can type: math, scie, read, macc, macq, macs, macu, mape, mapf, mapi, proflevel.
The final result will be calculated as a mean of these five regressions.
You can also specify other variables as dependent variables.
In this case the command will perform a standard quantile regression with one dependent variable.
Standard errors are obtained by the BRR method unless fast option is specified.
With fast option standard errors are not correct but point estimates are.
The command uses survey information provided in the original publicly available PISA datasets.
You need to keep variables like cnt or w_fstuwt and w_fstr* unless you specify your own weight prefix.
{cmd: pisaqreg} returns matrices with point estimates and standard errors, separately for each over() category.
Type return list after executing {cmd: pisaqreg} to see what is available.

{title:Examples}

{pstd}

{phang2}{cmd:. pisaqreg scie intscie, over(gender) cnt(POL) save(example1)} {p_end}

{phang2}{cmd:. pisaqreg read escs gender, q(0.8) cnt(AUS) save(example2) round(5)} {p_end}

{phang2}{cmd:. pisaqreg scieeff escs, q(0.2) over(gender) cnt(AUS POL GBR) save(example3)}  {p_end}

{phang2}{cmd:. pisaqreg math escs scieeff gender, q(0.2) fast cnt(OECD) cycle(2006) save(example4)} {p_end}
