{smcl}
{* *! version 1.1.1  31mar2022}{...}
{findalias asfradohelp}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] help" "help help"}{...}
{viewerjumpto "Syntax" "examplehelpfile##syntax"}{...}
{viewerjumpto "Description" "examplehelpfile##description"}{...}
{viewerjumpto "Options" "examplehelpfile##options"}{...}
{viewerjumpto "Remarks" "examplehelpfile##remarks"}{...}
{viewerjumpto "Examples" "examplehelpfile##examples"}{...}
{viewerjumpto "References" "examplehelpfile##references"}{...}
{viewerjumpto "Authors" "examplehelpfile##authors"}{...}
{title:Title}

{phang}
{bf:pzms} {hline 2} implements the Placebo Zone optimal Model Selection algorithm for regression discontinuity and kink designs proposed in Kettlewell & Siminski (2022).


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:pzms}
{it: depvar runvar}
{ifin}
{cmd:, maxbw(real)} [{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt maxbw:(#)}}the maximum bandwidth considered for estimation{p_end}
{syntab:Optional}
{synopt:{opt c:(#)}}the cut-off threshold for the treatment{p_end}
{synopt:{opt minbw:(#)}}the minimum bandwidth considered for estimation{p_end}
{synopt:{opt pzrange:(# #)}}the range for the placebo zone{p_end}
{synopt:{opt p:(#)}}the polynomial orders to be considered for estimation{p_end}
{synopt:{opt deriv:(#)}}specifies the order of the derivative of the regression functions to be estimated{p_end}
{synopt:{opt pzstepnum:(#)}}the number of placebo zone iterations to be performed{p_end}
{synopt:{opt pzstepsize:(#)}}the distance between consecutive placebo thresholds{p_end}
{synopt:{opt bwstepnum:(#)}}the number of bandwidths to be considered between {bf:minbw} and {bf:maxbw}{p_end}
{synopt:{opt bwstepsize:(#)}}the increase in bandwidth between candidate estimators{p_end}
{synopt:{opt nolog:}}suppresses the display of iterations count{p_end}
{synopt:{opt vce:(string)}}specifies the vce type for standard errors{p_end}
{synopt:{opt covs:(varlist)}}covariates that will be included in the models compared{p_end}
{synopt:{opt kernel:(string)}}specifies the type of kernel weights to be applied{p_end}
{synopt:{opt weight:(varname)}}specifies the analytical weights to be applied{p_end}
{synopt:{opt collapse:(string)}}allows the dataset to be collapsed at the level of runvar before estimation{p_end}
{synopt:{opt bwlfix:(#)}}fixes the bandwidth on the left of the cut-off to this value{p_end}
{synopt:{opt bwrfix:(#)}}fixes the bandwidth on the right of the cut-off to this value{p_end}
{synopt:{opt donut:(# #)}}drops observations within the specified range of the cut-off{p_end}
{synopt:{opt pzplot:}}generate a kernel density plot of the placebo zone estimates{p_end}
{synopt:{opt mcustom#:(# #, mcustom_options)}}allows the user to specify custom candidate specifications{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:pzms} implements the placebo zone model selection algorithm for regression discontinuity (RDD) and kink (RKD) designs proposed in 
{browse "https://drive.google.com/file/d/1V4KmmPs_DX8Iv8p-eYYapXEoUd1LflgW/view":Kettlewell & Siminski (2022)}. It also reports regression estimates using the model specification selected by the algorithm.
The pzms algorithm works by estimating treatment effects for candidate RDD or RKD specifications at various 'placebo thresholds'. These placebo 
thresholds are cut-off points along the range of the running variable where there is no actual discrete change in treatment (this region is described 
as the placebo zone). Treatment effects are assumed to be zero at these thresholds. Candidate models can vary by combinations of bandwidth, polynomial 
order, kernel weighting, analytical weighting and covariates. The candidate specification with the lowest root mean squared error of placebo estimates 
is selected as the preferred specification.
{p_end}   

{marker options}{...}
{title:Options}

{phang}
{opt maxbw(#)} the maximum bandwidth considered when comparing specifications throughout the placebo zone. There is no default.

{phang}
{opt c(#)} the cut-off threshold for the treatment. The default is zero.

{phang}
{opt minbw(#)} the minimum bandwidth considered when comparing specifications throughout the placebo zone. 
If this is not specified, it will be set at 0.1*{bf:maxbw}.

{phang}
{opt pzrange(# #)} the range of the placebo zone, which must include {bf:c(#)} in its interior. The default is the full range of the running variable.

{phang}
{opt p(#)} polynomial order for the RDD/RKD candidate specifications. Under the default (1) pzms will consider linear candidate specifications. If 2 
is specified, pzms will consider both linear and quadratic specifications.

{phang}
{opt deriv(#)} specifies the order of the derivative of the candidate specifications. 0 (default) is for sharp RDD 
and 1 is for sharp RKD. 

{phang}
{opt pzstepnum(#)} specifies the number of placebo zone iterations to be performed. There may be less iterations than specified by {bf:pzstepnum(#)} if some 
steps are too small to move to a new placebo threshold (this may occur when the running variable is sparse, or when {bf:pzstepnum} is very high). It is 
therefore a maximum number of iterations. {bf:pzstepnum} cannot be used if {bf:pzstepsize} is also specified.  The default is 50 if neither {bf:pzstepnum} or {bf:pzstepsize} 
are specified.

{phang}
{opt pzstepsize(#)} specifies the the distance between consecutive placebo thresholds. {bf:pzstepsize} cannot be used if {bf:pzstepnum} is also specified. 
See also {bf:pzstepnum}.

{phang}
{opt bwstepnum(#)} the number of bandwidths to be considered between {bf:minbw} and {bf:maxbw}. The default is 20 if neither {bf:bwstepnum} or 
{bf:bwstepsize} are specified.

{phang}
{opt bwstepsize(#)} the increase in bandwidth (in units of the running variable) between the candidate estimators considered. See also {bf:bwstepnum}. 

{phang}
{opt nolog} if specified, an iteration log will not be displayed as the algorithm works through the placebo zone.

{phang}
{opt vce(vce type)} this allows the user to specify the type of standard errors. Any vce that is available for the Stata command {stata help regress:regress} can 
be used (ols, robust, cluster {it:clustvar}, bootstrap, jackknife, hc2, or hc3). The default is homoscedastic standard errors. 

{phang}
{opt covs(varlist)} specifies the covariates to include in the candidate specifications. If this option is chosen, the algorithm 
will estimate a model for each level of polynomial {bf:p(#)}, with and without the covariates. For example, if {bf:p(2)} is specified, there will be 
four models compared – linear without covariates, linear with covariates, quadratic without covariates and quadratic with covariates.

{phang}
{opt kernel(kernel type)} allows the user to choose what sort of kernel weights to apply. {bf:uniform} and {bf:triangular} are 
supported. The default is uniform.

{phang}
{opt weight(varname)} is used to specify {stata help weight:analytical weights} [aweights]. The weights will apply to every model considered 
except the models specified in {bf:mcustom#}.

{phang}
{opt collapse(string)} this will collapse the data at the level of the running variable before implementing the algorithm. If {bf:collapse(weight)} 
is specified, the estimates will be weighted by the number of observations corresponding to the collapsed bins. This will usually be desired. Use 
{bf:collapse(noweight)} if you do not want to use weights for observation frequency when the data are collapsed. The collapse option can greatly 
improve speed when the running variable is discrete and there are many observations and/or placebo zone iterations, without affecting the estimates. 
The {bf:collapse} option can be combined with the {bf:weight} option if you want to apply additional analytical weights, even if {bf:collapse(weight)} is specified.

{phang}
{opt bwlfix(#)} this option allows the user to fix the length of the bandwidth on the left hand side of the threshold. It may be helpful if the 
candidate set of specifications is constrained by the data such that you can only accommodate short bandwidths on the left but much longer on the 
right, or to explore the performance of asymmetric bandwidths.

{phang}
{opt bwrfix(#)} this option allows the user to fix the length of the bandwidth on the right hand side of the threshold. It may be helpful if the candidate 
set of specifications is constrained by the data such that you can only accommodate short bandwidths on the right but much longer on the left, or to 
explore the performance of asymmetric bandwidths.

{phang}
{opt pzplot} a kernel density plot will be produced that summarises the distribution of placebo estimates from the winning specification. The plot 
uses Stata's {cmd:kdensity} command with default settings.

{phang}
{opt donut(# #)} drops observations within the specified range of the cut-off. The first # specifies that observations within this value of the running 
variable to the left of the cut-off be dropped. The second # specifies that observations within this value of therunning variable to the right of the 
cut-off be dropped. This option can be used as an ad hoc solution to threshold bunching or other non-compliance issues.

{phang}
{opt mcustom#:(# #, mcustom_options)} this allows the user to include additional specifications in the candidate set with custom features. You can 
specify up to 10 custom models by using mcustom1(), mcustom2() etc. This first argument in {bf:mcustom} is the polynomial order on the left of the 
treatment threshold and the second argument is the polynomial order on the right. For example, if we wanted to estimate a model that is linear on the 
left and quadratic on the right, we would specify {bf:mcustom(1 2)}. Polynomials of any order (including zero) up to 10 are allowed.

{title:mcustom_options}

{phang}
{opt covs(varlist)} specifies covariates that you would like to include in the custom specification.

{phang}
{opt kernel(kernal type)} allows the user to choose what sort of kernel weights to apply in the custom specification. {bf:uniform} and 
{bf:triangular} are supported. The default is uniform.

{phang}
{opt weight(varname)} is used to specify {stata help weight:analytical weights} [aweights] in the custom specification.

{marker remarks}{...}
{title:Remarks}

{pstd}
If you find any bugs, have questions, or want to provide feedback, please get in touch with us at Nathan.Kettlewell@uts.edu and Peter.Siminski@uts.edu.au.

{pstd}
Warning regarding default settings: While we have tried to select defaults that are reasonable, based on our experience with the algorithm, we strongly 
recommend you consider whether these are appropriate for your application. In particular, you may want to specify {bf:pzstepsize} to be equal to the 
minimum change in the value of the running variable across the placebo zone, if it is feasible to do so. For example, if the running variable is measured 
in days, and there are observations for every day, specifying {bf:pzstepsize(1)} will ensure you are considering the maximum number of placebo 
thresholds. You may also want to apply the same criteria in specifying {bf:bwstepsize}. If computation is slow, the {bf:collapse} option might help. 


{marker examples}{...}
{title:Examples}

{phang}Load example dataset.{p_end}

{phang}{cmd:. use pzms_example_data.dta, clear}{p_end}

{phang}Perform model selection and estimation using default settings.{p_end}

{phang}{cmd:. pzms y x, maxbw(0.99)}{p_end}

{phang}Now consider polynomials up to order 2 and cluster standard errors.{p_end}

{phang}{cmd:. pzms y x, maxbw(0.99) p(2) vce(cluster x)}{p_end}

{phang}Increase the number of bandwidths considered and plabebo thresholds used.{p_end}

{phang}{cmd:. pzms y x, maxbw(0.99) p(2) vce(cluster x) bwstepnum(25) pzstepsize(0.02)}

{phang}Also consider a custom linear specification with triangular kernel, and plot placebo estimates from winning specification.{p_end}

{phang}{cmd:. pzms y x, maxbw(0.99) p(2) vce(cluster x) bwstepnum(25) pzstepsize(0.02) mcustom(1 1, kernel(triangular)) pzplot}{p_end}

{marker examples}{...}
{title:Stored results}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{opt e(pz_est):}}the treatment effect estimate from the optimal specification{p_end}
{synopt:{opt e(pz_se):}}the conventional standard error for the treatment effect estimate{p_end}
{synopt:{opt e(pz_p):}}the p-value for the treatment effect using conventional standard error{p_end}
{synopt:{opt e(pz_ess):}}the lower bound estimated effective sample size of the placebo estimates{p_end}
{synopt:{opt e(pz_ess_sum):}}the upper bound estimated effective sample size of the placebo estimates{p_end}
{synopt:{opt e(pz_altp):}}lower bound p-value using Kettlewell & Siminksi (2022) randomization inference method{p_end}
{synopt:{opt e(pz_alt_se):}}the standard error using Kettlewell & Siminksi (2022) randomization inference method{p_end}
{synopt:{opt e(pz_altp_sum):}}upper bound p-value using Kettlewell & Siminksi (2022) randomization inference method{p_end}
{synopt:{opt e(pz_rmse):}}RMSE of optimal specification in the placebo trials{p_end}
{synopt:{opt e(pz_winbw):}}the bandwidth of the optimal specification{p_end}
{synopt:{opt e(pz_bwstepsize):}}the value used for {bf:bwstepsize}{p_end}
{synopt:{opt e(pz_pzstepsize):}}the value used for {bf:pzstepsize}{p_end}
{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{opt e(pz_winmodels):}}stores the RMSE and optimal bandwidth for the optimal model within each combination of polynomial and covariates{p_end}
{synopt:{opt e(pz_rep_results):}}stores the estimates and conventional standard errors and p-values for the optimal specification at each placebo threshold{p_end}

{phang}In addition, {cmd:pzms} retains all of the e(class) results saved by the {stata help regress:regress} command.{p_end}

{marker references}{...}
{title:References}

{phang}Kettlewell N. & Siminski P. (2022). {browse "https://drive.google.com/file/d/1V4KmmPs_DX8Iv8p-eYYapXEoUd1LflgW/view":Optimal Model Selection in RDD and Related Settings Using Placebo Zones}, mimeo{p_end}

{marker references}{...}
{title:Authors}

{phang}Nathan Kettlewell, Economics Discipline Group, University of Technology Sydney: email: Nathan.Kettlewell@uts.edu.au{p_end}

{phang}Peter Siminski, Economics Discipline Group, University of Technology Sydney: email: Peter.Siminski@uts.edu.au{p_end}
