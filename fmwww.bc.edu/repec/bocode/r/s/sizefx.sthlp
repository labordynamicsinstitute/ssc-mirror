{smcl}
{cmd:help sizefx}
{hline}

{title:Title}

{cmd:sizefx} -- Calculate Cohen's {it:d}, Hedges' {it:g}, and the effect size (ES) correlation ({it:r})


{title:Syntax}

        {cmd:sizefx}  {varlist}  {ifin}


{title:Description}


{p}{cmd:sizefx} computes Cohen's {it:d}, Hedges' {it:g}, and effect size (ES) correlations ({it:r}) for the two variables specified in {helpb comments:varlist}. The two variables specified correspond to the variables in a {helpb comments:ttest}, although the "==" operator is not used in the {cmd:sizefx} syntax.

{p}The command displays Cohen's {it:d} statistic (Cohen 1988) using the pooled variance of the variables and Hedges' {it:g} statistic. The pooled variance for an unpaired t-test is used to calculate effect size even when using a dependent sample or correlated designs (Dunlap et al. 1996).

{p}Additionally, it displays the effect size (ES) correlation ({it:r}) using the value of Cohen's {it:d}.


{title:Examples}

        . {cmd:sizefx} age1 age2
        . {cmd:sizefx} before after
        

{title:References}

{phang}Cohen, J. (1988) {it:Statistical power analysis for the behavioral sciences, 2nd ed}. Hillsdale, NJ: Lawrence Earlbaum Associates.

{phang}Dunlap, William P., Cortina, Jose M., Vaslow, Joel B., and Burke, 
	Michael J. (1996) Meta-analysis of experiments with matched 
	groups or repeated measures designs. {it:Psychological Methods} 1 
	no. 2, 170-177.
	
{phang}Thalheimer, W., and Cook, S. (2002, August) {it:How to calculate effect sizes from published research articles: A simplified methodology}. Retrieved 01 Apr 2010 from http://work-learning.com/effect_sizes.htm.	

Additional resources may be found at:
     http://www.gseis.ucla.edu/courses/ed230a2/notes/effect.html
     http://web.uccs.edu/lbecker/Psy590/es.htm
     

Links active as of 01 Apr 2010.


{title:Author}

        Matthew S. Openshaw, The University of Texas at Dallas, USA
        openshaw@utdallas.edu

    {p}Please send comments, suggestions or constructive criticism to the above email address.

    	sizefx
	v1.3
	Update 01 Apr 2010

