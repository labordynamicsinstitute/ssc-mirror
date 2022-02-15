{smcl}
{* 10Feb2022}{...}
{cmd:help hibi}
{hline}

{title:Title}

{pstd} {cmd:hibi} {hline 2} Harms index and benefits index (Hi-Bi) for measuring the impact of zero-cases studies in evidence synthesis practice 



{title:Syntax}

{p 8 14 2} {cmd: hibi} {it:varlist} {ifin} [, options]
	
{pstd} As in {helpb admetan}, {it:varlist} should contain four variables in the form of:

{p2col 9 52 44 2:{it:t_cases} {it:t_non-cases} {it:c_cases} {it:c_non-cases}} cell counts from 2x2 contingency table



{title:Description}

{pstd} {cmd:hibi} generates the Hi-Bi plot and estimates the Hi and Bi metrics to detect the potential impacts of double-zero studies on the results of a meta-analysis.{p_end}
{pstd} The Hi and Bi metrics are defined by the minimal number of cases added to the treatment arm (Hi) or control arm (Bi) of studies with no cases in a meta-analysis that lead to a change of the direction of the effect or its statistical significance. This idea is inspired by the fragility index discussed by Atal et al. {p_end}
{pstd} In evidence synthesis of rare events, there is debate on whether double-zero studies should be included for the synthesis when odds ratio (OR) or risk ratio (RR)is used as effect estimator. Current standard methods (e.g. inverse variance, Peto, Mantel-Haenszel) routinely excluded double-zero studies as such studies add nothing information on the pooled effect. While based on the one-stage framework (e.g. generalized linear mixed model), such studies are found not necessarily non-informative. {p_end}
{pstd} Here we propose the Hi-Bi method, by measuring the potential impact of studies with no cases on the pooled effect. The key proposal is that when there is no impact of studies with no cases on the pooled effect, researchers can discard these studies in the formal synthesis but need to mention their existence when reporting the systematic review and meta-analysis. On the other hand, when these studies impact the pooled effect, researchers need to routinely include them in the formal synthesis. {p_end}
{pstd} Based on the estimates on Hi and Bi, the impact of studies with no cases could be divided into three categories: 1) have no impact on the results of meta-analysis (Hi/Bi = 0); 2) almost have no impact impacting the results of meta-analysis (Hi/Bi > 3); 3) have potential impact on the results (0 < Hi/Bi <= 3). {p_end}



{title:Options}

{pstd} {cmd:or} (the default for binary data) uses odds ratios as the effect estimate of interest.

{pstd} {cmd:rr} specifies that risk ratios rather than odds ratios as the effect estimate. 

{pstd} {cmd:twostage} specifies that using two-stage approaches (the default method is Peto) for the data synthesis. 

{pstd} {cmd:onestage} specifies that using one-stage approaches (the default method is GLMM) for the data synthesis. 

{pstd} {cmd:ap} specifies that using an approximating method to estimate the Hi-Bi metrics. This is highly recommended when there are 7 or more double-zero studies or it would be time-consuming due to the huge amounts of computations.

{pstd} {cmd:nograph} suppresses the Hi-Bi plot. 



{title:Examples}

{pstd} The data for the example is a simulated meta-analytic data. {p_end}
{phang2} {stata "use http://fmwww.bc.edu/repec/bocode/h/hibi_example_data, clear":. use http://fmwww.bc.edu/repec/bocode/h/hibi_example_data, clear} {p_end}

{pstd} Using OR. {p_end}
{phang2}{stata "hibi a b c d, or":. hibi a b c d, or} {p_end}

{pstd} Using RR. {p_end}
{phang2}{stata "hibi a b c d, rr":. hibi a b c d, rr} {p_end}

{pstd} Using one-stage method with OR. {p_end}
{phang2}{stata "hibi a b c d, or onestage":. hibi a b c d, or onestage} {p_end}


{pstd} Using two-stage method with OR. {p_end}
{phang2}{stata "hibi a b c d, or twostage":. hibi a b c d, or twostage} {p_end}


{pstd} Using two-stage method with OR based on approximating method. {p_end}
{phang2}{stata "hibi a b c d, or twostage ap":. hibi a b c d, or twostage ap} {p_end}



{title:Authors}

{pstd} Chang Xu, Ministry of Education Key Laboratory for Population Health Across-life Cycle, Anhui Medical University, China{p_end}
{pstd} {browse "mailto:xuchang2016@runbox.com?subject=X.C Stata enquiry":xuchang2016@runbox.com}{p_end}

{pstd} Luis Furuya-Kanamori, UQ Centre for Clinical Research, The University of Queensland, Australia


	
{title:Reference}

{pstd} Xu C, Furuya-Kanamori L, Zorzela L, Lin L, Vohra S. A proposed framework to guide evidence synthesis practice for meta-analysis with zero-events studies. J Clin Epidemiol. 2021: 135:70-78. {p_end}
{pstd} Atal I, Porcher R, Boutron I, Ravaud P. The statistical significance of meta-analyses is frequently fragile: definition of a fragility index for meta-analyses. J Clin Epidemiol. 2019: 111:32-40. {p_end}
{pstd} Xu C, Zhou X, Zorzela L, et al. Utilization of the evidence from studies with no events in meta-analyses of adverse events: an empirical investigation. BMC Med. 2021;19(1):141.{p_end}
{pstd} Xu C, Li L, Lin L, et al. Exclusion of studies with no events in both arms in meta-analysis impacted the conclusions. J Clin Epidemiol. 2020;123:91-99.{p_end}
{pstd} Xu C, Furuya-Kanamori L, Lin L. Synthesis of evidence from zero-events studies: A comparison of one-stage framework methods. Res Synth Methods. 2021;10.1002/jrsm.1521.{p_end}
