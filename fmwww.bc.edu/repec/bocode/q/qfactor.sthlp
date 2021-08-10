{smcl}
{* *! Version 2.0 21Jun2017}{...}

{title:Title}

{phang}
{bf:qfactor} {hline 2} Q Factor analysis
    

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:qfa:ctor} {varlist} {ifin}
{cmd:,}
{cmdab:nfa:ctor(#)} [{cmdab:ext:raction(string)} {cmdab:rot:ation(string)} 
{cmdab:tra:nspose(string)} {cmdab:sta:tement(string)} {cmdab:sco:re(string)} 
{cmdab:es:ize(string)} {cmdab:bip:olar(string)}] 

{p}
{bf:varlist} includes Q-sorts that need to be factor-analyzed, it can include both transposed (inverted) or non-transposed Q-sorts.

{title: Description}

{pstd}
{cmd:qfactor} performs factor analysis on Q-sorts.  The command performs factor analysis based on principal 
factor, iterated principal factor, principal-component factor, and maximum-likelihood factor extraction methods. 
{cmd:qfactor} also rotate factors based on all factor rotation techniques available in Stata (orthogonal and oblique)
including varimax, quartimax, equamax, obminin, and promax. 
{cmd:qfactor} displays the eigenvalues of the correlation matrix, the factor loadings, and the uniqueness of the variables. 
It also provides number of Q-sorts loaded on each factor, distinguishing statements for each factor, and consensus statements. 
{cmd:qfactor} is able to handle bipolar factors and identify distinguishing statements based on {it:Cohen's effect size (d)}.

{pstd}
{cmd:qfactor} expects data in the form of variables and can be run for subgroups using “if” and “in” options. 

{marker options}{...}
{synoptset 29 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt nfactor(#)}}maximum number of factors to be retained{p_end}
{synopt :{opt extraction(string)}}factor extraction method which includes:{p_end}
{synoptline}
      {bf:pf}             principal factor
      {bf:pcf}            principal-component factor
      {bf:ipf}            iterated principal factor; the default
      {bf:ml}             maximum-likelihood factor 

{synopt :{opt rotation(string)}}{cmd:qfactor} accommodates almost every rotation technique in Stata including:{p_end}
{synoptline}
{synopt:{opt none}}this option is used if no rotation is required{p_end}
{synopt:{opt varimax}}varimax; {ul:varimax is the default option}{p_end}
{synopt:{opt quartimax}}quartimax{p_end}
{synopt:{opt equamax}}equamax{p_end}
{synopt:{opt promax(#)}}promax power # (implies oblique); default is promax(3){p_end}
{synopt:{opt oblimin(#)}}oblimin with gamma=#; default is oblimin(0){p_end}
{synopt:{opt target(Tg)}}rotate toward matrix Tg; this option accommodates theoretical rotation{p_end}

{synopt :{opt tra:nspose(string)}}whether the data file needs to be transposed (inverted), options include:{p_end}
{synoptline}
{synopt:{opt no}}the data file does not need to be transposed, “no” is the default option. In this case, besides the Q-sorts the data file should include two additional variables, “StatNo” and “statement”.{p_end}
{synopt:{opt yes}}the data file needs to be transposed. In this case you need to have another Stata file in your working directory which includes “StatNo” and “statement” as only variables.{p_end}

{synopt :{opt sta:tement(string)}}this option is only used if “transpose” is “yes”. Otherwise, it is not needed{p_end}
{synoptline}
{synopt:{opt no}}the data file does not need to be transposed and Q-statements are included in the original file, “no” is the default option. In this case, besides the Q-sorts the data file should include two additional variables, “StatNo” and “statement”{p_end}
{synopt:{opt filename}} {it:filename} is a Stata file in your working directory with two variables; “StatNo” and “statement”.{p_end}

{synopt :{opt sco:re(string)}}it identifies how the factor scores to be calculated. The options include:{p_end}
{synoptline}
{synopt:{opt brown}}factor scores are calculated as described by Brown (1980); brown is the default approach.{p_end}
{synopt:{opt r:egression }}regression scoring method{p_end}
{synopt:{opt b:artlett}}Bartlett scoring method{p_end}
{synopt:{opt t:hompson}}Thompson scoring method{p_end}

{synopt :{opt es:ize(string)}}it specifies how the distinguishing statements to be identified for each factor. The options include:{p_end}
{synoptline}
{synopt:{opt stephenson}}distinguishing statements are identified based on Stephenson's formula as described by Brown (1980); {ul:this is the default option}.{p_end}
{synopt:{opt any #}}for any # between zero and one (0<#<1) distinguishing statements are identified based on Cohen's d.{p_end}

{synopt :{opt bip:olar(string)}}it identifies the criteria for bipolar factor and calculates the factor scores for any bipolar factor. The options include:{p_end}
{synoptline}
{synopt:{opt 0 or no}}indicates no assessment of a bipolar factor; the default option{p_end}
{synopt:{opt any #}}any number more than 0 indicates number of negative loadings required for a bipolar factor.{p_end}

{title: Options for factor extraction}

{phang}
{opt pf}, {opt pcf}, {opt ipf}, and {opt ml}
indicate the type of extraction to be used. The default is {opt ipf}.

{phang2}
{opt pf} 
specifies that the principal-factor method be used to analyze the correlation matrix. 
The factor loadings, sometimes called the factor patterns, are computed using the 
squared multiple correlations as estimates of the communality.  

{phang2}
{opt pcf} 
specifies that the principal-component factor method be used to analyze the correlation matrix. 
The communalities are assumed to be 1.

{phang2}
{opt ipf} 
specifies that the iterated principal-factor method be used to analyze the correlation matrix. 
This reestimates the communalities iteratively. ipf is the default.

{phang2}
{opt ml} 
specifies the maximum-likelihood factor method, assuming multivariate normal observations. 
This estimation method is equivalent to Rao's canonical-factor method and maximizes 
the determinant of the partial correlation matrix.  Hence, this solution is also 
meaningful as a descriptive method for nonnormal data.  ml is not available for 
singular correlation matrices.  At least three variables must be specified with method ml.


{title:Saved files}

{phang}
In addition to the common results, qfactor saves two files in your working directory for subsequent use;

{phang2}
{bf:FactorLoadings:} this file includes the following variables; Qsort (Qsort number), unrotated and rotated factor 
loadings, unique (for the uniqueness of each Qsort), h2 (communality of the extracted factors), 
Factor (which indicates which Q-sort was loaded on which factor). This file can be used for 
subsequent analysis, e.g. producing loading-based graphs.

{phang2}
{bf:FactorScores:} this file includes the following variables; StatNo (statement number), 
statement, zscore (composite zscores of statements for each factor), and rank (composite ranking of statements for each factor). 


{title:Examples of qfactor}

{phang} 
1-mldataset.dta: This dataset includes 40 participants on their views on marijuana legalization. 
The study was conducted using 19 statements. Suppose the dataset is transposed 
(each column represents a Q-sort) and Q-sorts are named v1, v2,…, v40. The following 
commands will conduct qfactor analysis to extract 3 principal component factors using varimax:{p_end}

{phang2}
{bf:qfactor v1-v40, nfa(3) ext(pcf)}

{phang}
or

{phang2}
{bf:qfactor v*, nfa(3) ext(pcf)}

{phang}
The same as above using quartimax rotation:

{phang2}
{bf:qfactor v*, nfa(3) ext(pcf) rot(quartimax)}

{phang}
Same as above with varimax rotation but if there is 2 or more negative loadings on any factor it treats it as bipolar factor:

{phang2}
{bf:qfactor v1-v30, nfa(3) ext(pcf) bip(2)}

{phang}
Same as above without bipolar option but Cohen's d=0.80:

{phang2}
{bf:qfactor v1-v30, nfa(3) ext(pcf) es(0.80)}

{phang}
The following command runs qfactor on only 30 Q-sorts and uses iterated principal factors (ipf) to extract 3 factors using varimax rotation:

{phang2}
{bf:qfactor v1-v30, nfa(3) ext(ipf)}

{phang2}
{bf:qfactor v1-v30, nfa(3)} 

{phang}
The same as above but with 40 Q-sorts and promax(3) rotation:

{phang2}
{bf:qfactor v1-v40, nfa(3) rot(promax(3))}

{phang}
2-	With some non-transposed dataset: Suppose your non-transposed Q-sorts are named v1, v2,…, v30 (you have 30 statements) and 40 Q-sorts. Also suppose your statement file is named exmstat.dta. 
    The following commands will conduct qfactor analysis to extract 5 principal component factors and varimax rotation:{p_end}

{phang2}
{bf:qfactor v*, nfa(5) ext(pcf) tra(yes) sta(exmstat)}

{phang}
Same as above with principal axis factor extraction and quartimax rotation:

{phang2}
{bf:qfactor v*, nfa(5) ext(pf) rot(quartimax) tra(yes) sta(exmstat)}


{title:Stored results: Useful for Stata programmers}

    {bf:qfactor} stores the following in e():

    {bf:Scalars}        
      e(f)                number of retained factors
      e(evsum)            sum of all eigenvalues
      e(df_m)             model degrees of freedom
      e(df_r)             residual degrees of freedom
      e(chi2_i)           likelihood-ratio test of "independence vs. saturated"
      e(df_i)             degrees of freedom of test of "independence vs.  saturated"
      e(p_i)              p-value of "independence vs. saturated"
      e(ll_0)             log likelihood of null model (ml only)
      e(ll)               log likelihood (ml only)
      e(aic)              Akaike's AIC (ml only)
      e(bic)              Schwarz's BIC (ml only)
      e(chi2_1)           likelihood-ratio test of "# factors vs. saturated" (ml only)
      e(df_1)             degrees of freedom of test of "# factors vs. saturated" (ml only)

    {bf:Macros}         
      e(cmd)              factor
      e(cmdline)          command as typed
      e(method)           pf, pcf, ipf, or ml
      e(wtype)            weight type (factor only)
      e(wexp)             weight expression (factor only)
      e(title)            Factor analysis
      e(mtitle)           description of method (e.g., principal factors)
      e(heywood)          Heywood case (when encountered)
      e(factors)          specified factors() option
      e(properties)       nob noV eigen
      e(rotate_cmd)       factor_rotate
      e(estat_cmd)        factor_estat
      e(predict)          factor_p
      e(marginsnotok)     predictions disallowed by margins

    {bf:Matrices}       
      e(sds)              standard deviations of analyzed variables
      e(means)            means of analyzed variables
      e(C)                analyzed correlation matrix
      e(Phi)              variance matrix common factors
      e(L)                factor loadings
      e(Psi)              uniqueness (variance of specific factors)
      e(Ev)               eigenvalues

	  
{title:Author}

{pstd}
{bf:Noori Akhtar-Danesh} ({ul:daneshn@mcmaster.ca}), McMaster University, Hamilton, CANADA
