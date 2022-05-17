{smcl}
{* 10 May 2022}{...}
{hline}
help for {hi:rdiff}
{hline}


{title:Title}

{pstd}
{bf:rdiff} —— Calculating 95% confidence intervals for the differences of 
binomial proportions.


{title:Syntax}

{p 8 18 2}
{cmd:rdiff}
{it:#n1}
{it:#succ1}
{it:#n2}
{it:#succ2}
[{cmd:,}
{opt c:orrect}] 


{title:Description}

{pstd}
{cmd:rdiff} is an immediate command that constructs a 95% confidence interval 
for the difference between two independent binomial proportions. Besides the most 
well-known method —— normal approximation method —— which may produce undesirable 
results in extreme cases, the more remarkable method, Wilson score method, is also 
available. Note that {cmd:rdiff} is recommended only for the case where the 
proportion of #succ1 for #n1 is equal to or greater than the proportion of 
#succ2 for #n2.


{title:Options}

{phang}
{opt c:orrect} specifies with continuity correction when calculating.


{title:Examples}

{pstd}
Suppose that sample A shows 23 'successes' among 30 subjects and sample B shows 
9 'successes' among 30 subjects. Calculating the 95% confidence interval for the 
rate difference without continuity correction:

{phang2}
{bf:.rdiff 30 23 30 9}

{pstd}
or with continuity correction:

{phang2}
{bf:.rdiff 30 23 30 9, correct}


{title:Stored results}

{pstd}
{cmd:rdiff} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(rd)}}rate difference{p_end}
{synopt:{cmd:r(ll_a)}}lower limit calculated by normal approximation method{p_end}
{synopt:{cmd:r(ul_a)}}upper limit calculated by normal approximation method{p_end}
{synopt:{cmd:r(ll_w)}}lower limit calculated by Wald score method{p_end}
{synopt:{cmd:r(ul_w)}}upper limit calculated by Wald score method{p_end}


{title:References}

{phang}
Beal, S. L. 1987. Asymptotic confidence intervals for the difference between two 
binomial parameters for use with small samples. {it:Biometrics}, 43: 941{c -}950.

{phang}
Newcombe, R. 1998. Interval estimation for the difference between independent 
proportions: Comparison of eleven methods. {it:Statistics in Medicine}, 17: 873{c -}890.


{title:Author}

{phang}
{cmd:Xiaokun Yang}, Lanzhou University, China.{break}
E-mail: {browse "mailto:yangxk19@lzu.edu.cn":yangxk19@lzu.edu.cn}.{break}


{title:Also see}

{phang2}
Help: {help immed}, {help ci}, {help epitab}
