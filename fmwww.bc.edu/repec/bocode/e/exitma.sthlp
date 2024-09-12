{smcl}
{* 11september2024}{...}
{cmd:help exitma}
{hline}

{title:Title}

{pstd} {cmd:exitma} {hline 2} Defining the exit status of a meta-analysis



{title:Syntax}

{p 8 14 2} {cmd: exitma} {it:varlist} {ifin}, {opt sequence(varname)} {opt samplesize(varname)} [options]
	
{pstd} {it:varlist} must contain two, three, or four variables in the form of:

{pstd} Two variables:{p_end}
{p2col 9 52 44 2:{it:ES} {it:seES}} effect size and standard error{p_end}
{p 8 8} 

{pstd} Three variables:{p_end}
{p2col 9 52 44 2:{it:ES} {it:lci} {it:uci}} effect size and 95% confidence limits{p_end}
{p 8 8} 

{pstd} Four variables:{p_end}
{p2col 9 52 53 2:{it:event_treat} {it:noevent_treat} {it:event_ctrl} {it:noevent_ctrl}} cell counts from a 2x2 contingency table. Only odds ratios are supported{p_end} 
	                   
{pstd} In addition to {it:varlist}, {cmd:sequence} and {cmd:samplesize} variables need to be specified.{p_end}
{p 6 8} - {cmd:sequence}({it:varname}) specifies the sequence of the studies (in ascending order: 1, 2 to {it:k}) in the cumulative meta-analysis.{p_end}
{p 6 8} - {cmd:samplesize}({it:varname}) specifies the sample size in each study. Only applicable when data have been entered using the two ({it:ES} {it:seES}) or three ({it:ES} {it:lci} {it:uci}) variables form.{p_end}



{title:Description}

{pstd} {cmd:exitma} performs a cumulative meta-analysis, computes a convergence index (DAts - Doi-Abdulmajeed trial stability index), and displays a convergence plot to assess stability and ‘exit' status of the meta-analysis.  
An exit meta-analysis implies that there is no need to update the meta-analysis and there are no future primary studies required on this question.{p_end}
{pstd} DAts values of:{p_end}
{p 6 8} - <0 implies exit status{p_end}
{p 6 8} - between 0 and 0.05 is possibly exit{p_end}
{p 6 8} - >0.05 is not exit{p_end}
{pstd} The convergence plot should have all values of delta C, on and after the steps that include 50% of participants, falling within the shaded area for the plot to be deemed to have an exit appearance. 
The only binary effect measure supported via the 2x2 table input is the log odds ratio and only models under the common parameters assumption that also address heterogeneity (IVhet and QE) are supported for the cumulative meta-analysis. 
The latter two restrictions improve the robustness of the index and the convergence plot.{p_end}



{title:Modules required}

{pstd} Users need to install {stata ssc install admetan:admetan} and {stata ssc install metan:metan}



{title:Options}

{pstd} {cmd:Meta-analysis model}

{p 8 14 2} {cmd:ivhet} uses the inverse variance heterogeneity model (default model).

{p 8 14 2} {cmd:qe}({it:varname}) uses the quality effects model. A variable containing quality scores or ranks for each study needs to be specified.

{pstd} {cmd:Other options}

{p 8 14 2} {cmd:nograph} suppresses the convergence plot.



{title:Saved results}

{pstd} {cmd:exitma} stores the following in r()

{synoptset 25 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(dats)}} value of DAts index{p_end}
{synopt:{cmd:r(nstudy)}} total number of studies{p_end}
{synopt:{cmd:r(nstudy50)}} number of cumulative meta-analysis steps that contain 50% or more of the participants{p_end}



{title:Examples}

{pstd} The data for the example was taken from the methodological paper cited below (Abdulmajeed J et al).{p_end}
{phang2} {stata "use http://fmwww.bc.edu/repec/bocode/e/exitma_example_data.dta":. use http://fmwww.bc.edu/repec/bocode/e/exitma_example_data.dta} {p_end}

{pstd} Generate sequence and effect sizes{p_end}
{phang2} {stata "sort year total":. sort year total}{p_end}
{phang2} {stata "gen seq = _n":. gen seq = _n}{p_end}
{phang2} {stata "qui metan c1 nc1 c0 nc0, ivhet or nograph notable nohet":. qui metan c1 nc1 c0 nc0, ivhet or nograph notable nohet}{p_end}

{pstd} Two variables entry and IVhet model (by default) {p_end}
{phang2} {stata "exitma _ES _seES, sequence(seq) samplesize(total)":. exitma _ES _seES, sequence(seq) samplesize(total)}{p_end}

{pstd} Four variables entry and QE model {p_end}
{phang2} {stata "exitma c1 nc1 c0 nc0, sequence(seq) qe(qi)":. exitma c1 nc1 c0 nc0, sequence(seq) qe(qi)}{p_end}



{title:Authors}

{pstd} Luis Furuya-Kanamori, UQ Centre for Clinical Research, The University of Queensland, Australia {p_end}
{pstd} {browse "mailto:l.furuya@uq.edu.au?subject=EXITMA Stata enquiry":l.furuya@uq.edu.au} {p_end}

{pstd} Jazeel Abdulmajeed, Department of Population Medicine, College of Medicine, Qatar University, Qatar

{pstd} Suhail AR Doi, Department of Population Medicine, College of Medicine, Qatar University, Qatar



{title:Reference}

{pstd} Abdulmajeed J, Furuya-Kanamori L, Chivese T, Xu C, Thalib L, Doi SA. Defining the exit meta-Analysis. JBI Evidence Synthesis | DOI: 10.11124/JBIES-24-00155.{p_end}

{pstd} Doi SA, Barendregt JJ, Khan S, Thalib L, Williams GM. Advances in the meta-analysis of heterogeneous clinical trials I: The inverse variance heterogeneity model. Contemp Clin Trials. 2015;45(Pt A):130-8.{p_end}

{pstd} Doi SA, Barendregt JJ, Khan S, Thalib L, Williams GM. Advances in the meta-analysis of heterogeneous clinical trials II: The quality effects model. Contemp Clin Trials. 2015;45(Pt A):123-9.{p_end}



{title:Funding}

{pstd} This work was supported by Program Grant #BSRA01-0406-210030 from the Qatar National Research Fund. The findings herein reflect the work and are solely the responsibility of the authors.
