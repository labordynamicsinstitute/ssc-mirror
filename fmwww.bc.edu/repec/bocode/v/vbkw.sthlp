{smcl}
{hline}
help for {hi:vbkw}
{hline}

{title:Vector-Based Kernel Weighting}

{p 8 21 2}{cmdab:vbkw}
{it:depvar}
[{it:indepvars}]
[{cmd:if} {it:exp}]
[{cmd:in} {it:range}]
{cmdab:out:come}{cmd:(}{it:varlist}{cmd:)}
[{cmd:,}    
    {cmdab:kernel:type}{cmd:(}{it:string}{cmd:)}
    {cmdab:bw:idth}{cmd:(}{it:string}{cmd:)}
    {cmdab:sdbw:idth}{it:string}{cmd:)}
    {cmdab:nocom:mon}
    {cmdab:mpr:obit}
    {cmdab:logitps}
	{cmdab:bstrap}
	{cmdab:n:reps}{cmd:(}{it:numeric}{cmd:)}
	{cmdab:no:save}]
    
{p 8 21 2}where {it:indepvars} may contain factor variables; see {cmd:fvvarlist}.

{title:Description}

{pstd}
{cmd:vbkw} implements vector-based kernel weighting to adjust for pre-treatment observable differences between treatment groups in a multiple-treatment setting.
Treatment status is identified by {it:depvar}.
{p_end}

{pstd}
{cmd:vbkw} is being continuously improved and developed. Make sure to keep your version up-to-date as follows

    {inp: . ssc install vbkw, replace}  

{pstd}
If you want to be able to replicate your bootstrapped standard errors, you should set {help seed}
before calling {cmd:vbkw}.

{pstd}
The propensity scores - the conditional treatment probabilities - are estimated by the program on the {it:indepvars}. 

{title:Generated Variables}

{pstd}
{cmd:vbkw} creates a number of variables for the convenience of the user:

{pmore}
{inp:ps*} are the propensity score vectors generated for each observation in the analytic sample.

{pmore}
{inp:_support} is an indicator variable with equals 1 if the observation is on the common support
and 0 if the observation is off the support.

{pmore}
{inp:_pscore} is the estimated propensity score or a copy of the one provided by {cmdab:p:score()}.

{pmore}
{inp:ATTsupport*} are the variables that indicate which observations were used in estimation of treatment effects for each comparison.

{pmore}
{inp:ATTweight*, ATEweight*} are the vbkw weights.

{pmore}
{inp:ATT*, ATE*} are the vbkw ATT and ATE estimates.


{title:Options}

{phang}
{cmdab:out:come}{cmd:(}{it:varlist}{cmd:)} the outcome variable(s). 
When evaluating multiple outcomes vbkw reduces to the min common number of observations 
with non-missing values on ALL outcomes, because otherwise the matching weights will not sum 
to the right number. If you have multiple outcomes with widely differing missing values 
you may wish to run vbkw separately for each of the outcomes.

{phang}
{cmdab:bstrap} calculates complex-bootstrapped standard errors by re-estimating the propensity scores, 
applying the minimax common support restriction, and recalculating the treatment effect estimates. Users can specify 
the how many replications to be used for bootstrapping. The ols vcetype is the default if bstrap is not specified.

{phang}
{cmdab:kernel:type}{cmd:(}{it:kernel_type}{cmd:)} specifies the type of kernel:

{p 8 8 2}{inp:normal} the gaussian kernel.

{p 8 8 2}{inp:biweight} the biweight kernel.

{p 8 8 2}{inp:epan} the epanechnikov kernel (Default).

{p 8 8 2}{inp:uniform} the uniform kernel.

{p 8 8 2}{inp:tricube} the tricube kernel.

{phang}
{cmdab:bw:idth}{cmd:(}{it:real}{cmd:)} the bandwidth used for matching if the user desires a fixed bandwidth. 
Only one of {cmdab:bw:idth}{cmd:(}{it:real}{cmd:)} or {cmdab:sdbw:idth}{cmd:(}{it:real}{cmd:)} may be specified at a time.
If none are specified, the default bandwidth is 0.2*standard deviation of the propensity score, or 0.2*standard deviation of the logit of the propensity score (if {cmdab:logitps} is specified).

{phang}
{cmdab:sdbw:idth}{cmd:(}{it:real}{cmd:)} the bandwidth used for matching if the user desires a bandwidth based on the standard deviation of the ps or the logit of the ps.
Default bandwidth is 0.2*standard deviation of the propensity score, or logit of the propensity score (if specified).
Only one of {cmdab:bw:idth}{cmd:(}{it:real}{cmd:)} or {cmdab:sdbw:idth}{cmd:(}{it:real}{cmd:)} may be specified at a time.
If none are specified, the default bandwidth is 0.2*standard deviation of the propensity score, or 0.2*standard deviation of the logit of the propensity score (if {cmdab:logitps} is specified).

{phang}
{cmdab:nocom:mon} User may use this option so that the common support restriction is not applied. 
The default option is to apply the common support restriction based on the minimum of the maxima, and the maximum of the minima of the propensity scores. (See Section 3.3 Overlap and Common Support in Caliendo & Kopeinig, 2008).  
	
{phang}	
{cmdab:mpr:obit} The default is for the generalized propensity scores to be estimated with mlogit. Use this to estimate them with mprobit instead. 

{phang}		
{cmdab:logitps} Use the logit of the propensity scores instead of the raw propensity scores (default). 

{phang}		
{cmdab:n:reps}{cmd:(}{it:numeric}{cmd:)} Specifies the number of replications to be used in calculating bootstrapped standard errors. The default replications is 300

{phang}
{cmdab:no:save} This command automatically creates a separate dataset where the observations off common support dropped and the generated variables mentioned above are stored.
	

{title:Examples}

{inp: . vbkw treat x1 x2 x3 x4, kerneltype(biweight) logitps outcome(Y) nocommon sdbwidth(0.4) bstrap nreps(200)}
{inp: . use "vbkwdta_commonsupportonly.dta", clear // use the dataset that contains the generated variables after estimating with {cmdab:vbkw}}
	
	
	
{title:Thanks for citing {cmd:vbkw} as follows}

{pstd}
J. Lum and M. M. Garrido (2021). "vbkw: Stata module to perform vector-based kernel weighting in multiple treatment settings ".
http://ideas.repec.org/c/boc/bocode/?.html. This version INSERT_VERSION_HERE.

where you can check your version as follows:

    {inp: . which vbkw}


{title:Disclaimer}

{pstd}
THIS SOFTWARE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU. SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

{pstd}
IN NO EVENT WILL THE COPYRIGHT HOLDERS OR THEIR EMPLOYERS, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THIS SOFTWARE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

{title:Background Reading}

{p 0 2}Abadie, A., Drukker, D., Herr, J. L., & Imbens, G. W. (2004). "Implementing matching estimators for average treatment effects in Stata", {it:Stata journal 4}, 290-311.

{p 0 2}Abadie A. and Imbens, G. (2006), "Large sample properties of matching estimators for average treatment effects", {it:Econometrica 74}(1), 235-267.

{p 0 2}Austin, P. C., and Small, D. S. (2014), "The use of bootstrapping when using propensity-score matching without replacement: a simulation study", {it:Statistics in Medicine 33}, 4306– 4319.
https://doi.org/10.1002/sim.6276

{p 0 2}Caliendo, M. and Kopeinig, S. (2008), "SOME PRACTICAL GUIDANCE FOR THE IMPLEMENTATION OF PROPENSITY SCORE MATCHING". {it: Journal of Economic Surveys 22} 31-72. https://doi.org/10.1111/j.1467-6419.2007.00527.x

{p 0 2}Cochran, W. and Rubin, D.B. (1973), "Controlling Bias in Observational Studies", {it:Sankyha 35}, 417-446.

{p 0 2}Dehejia, R.H and Wahba, S. (1999), "Causal Effects in Non-Experimental Studies: Re-Evaluating the Evaluation of Training Programmes", {it:Journal of the American Statistical Association 94}, 1053-1062.

{p 0 2}Garrido, MM, Lum, J, Pizer, SD. (2021) "Vector-based kernel weighting: A simple estimator for improving precision and bias of average treatment effects in multiple treatment settings". {it:Statistics in Medicine 40}, 1204–1223. 
https://doi.org/10.1002/sim.8836 

{p 0 2}Heckman, J.J., Ichimura, H. and Todd, P.E. (1997), "Matching As An Econometric Evaluation Estimator: Evidence from Evaluating a Job Training Programme", {it:Review of Economic Studies 64}, 605-654.

{p 0 2}Heckman, J.J., Ichimura, H. and Todd, P.E. (1998), "Matching as an Econometric Evaluation Estimator", {it:Review of Economic Studies 65}, 261-294.

{p 0 2}Heckman, J.J., Ichimura, H., Smith, J.A. and Todd, P. (1998), "Characterising Selection Bias Using Experimental Data", {it:Econometrica 66}, 5.

{p 0 2}Imbens, G. (2000), "The Role of Propensity Score in Estimating Dose-Response Functions", {it:Biometrika 87(3)}, 706-710.

{p 0 2}Lechner, M. (2001), "Identification and Estimation of Causal Effects of Multiple Treatments under the Conditional Independence Assumption", in: Lechner, M., Pfeiffer, F. (eds), {it:Econometric Evaluation of Labour Market Policies}, Heidelberg: Physica/Springer, p. 43-58.

{p 0 2}Rosenbaum, P.R. and Rubin, D.B. (1983), "The Central Role of the Propensity Score in Observational Studies for Causal Effects", {it:Biometrika 70}, 1, 41-55.

{p 0 2}Rosenbaum, P.R. and Rubin, D.B. (1985), "Constructing a Control Group Using Multivariate Matched Sampling Methods that Incorporate the Propensity Score", {it:The American Statistician 39(1)}, 33-38.

{p 0 2}Rubin, D.B. (1974), "Estimating Causal Effects of Treatments in Randomised and Non-Randomised Studies", {it:Journal of Educational Psychology 66}, 688-701.

{pstd} note to self: add in reading for 1. our vbkw paper, 2. p.c. austin's paper on simple and complex bootstrapping, 3. lopez and gutman's vector matching. 

{title:Author}

{pstd}
Jessica Lum, Department of Veterans Affairs. If you observe any problems {browse "mailto:jlum917@gmail.com"}.

{pstd}
Melissa M. Garrido, Boston Univeristy School of Public Health, MA, USA. Department of Veterans Affairs. 

