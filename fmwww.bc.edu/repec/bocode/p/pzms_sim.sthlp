{smcl}
{* *! version 1.2  2dec2025}{...}
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
{bf:pzms_sim} {hline 2} conducts Monte Carlo simulations to evaluate the placebo zone model selection algorithm proposed in Kettlewell & Siminski (forthcoming).


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:pzms_sim}
{it: depvar runvar}
{ifin}
{cmd:, maxbw(numlist)} [{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt maxbw:(numlist)}}the set of maximum bandwidths considered for estimation{p_end}
{syntab:Optional}
{synopt:{opt c:(#)}}the cut-off threshold for the treatment{p_end}
{synopt:{opt sims:(#)}}the number of Monte Carlo simulations to perform{p_end}
{synopt:{opt pzms_opts:(string)}}specify any other options available for {cmd:pzms}{p_end}
{synopt:{opt cct_opts:(string)}}specify any other options available for {cmd:rdrobust}{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:pzms_sim} is a companion program for {cmd:pzms}, which implements the placebo zone model selection algorithm for regression discontinuity (RDD) 
and kink (RKD) designs proposed in Kettlewell & Siminski (forthcoming). The performance of the pzms algorithm is compared to the performance of AMSE minimizing bandwidth estimator, estimated using the user-written command {cmd:rdrobust} (the code in pzms_sim.ado can easily be modified to compare the outcomes of alternate model selection approaches). Each approach is compared according to the root mean squared error across simulated datasets that are designed to be similar to the true dataset. pzms_sim creates simulated versions of your dataset according to the approach outlined in Section 3.2 of Kettlewell & Siminski (forthcoming).
{p_end}   

{pstd}
The program first fits a 5th order global polynomial through the support of the data, allowing a discontinuity and a kink at the threshold. Second, it
fits a beta distribution to the same data to summarize the distribution of the running variable. Then for each iteration of the simulation, the sample 
size is set equal to the original sample. Randomly drawn values of the running variable are taken from the beta distribution. Finally, a simulated dependent
variable is set such that y = f(x) + e, where e is normally distributed with zero mean and variance equal to the variance of the residuals from the 
regression in the first step. 
{p_end}   

{marker options}{...}
{title:Options}

{phang}
{opt maxbw(numlist)} the maximum bandwidths considered when comparing specifications throughout the placebo zone. You can select multiple maximum bandwidths to trial by specifying {bf:maxbw(# # # etc)}. {cmd:pzms_sim} wil assess the performance of each of the maximum bandwidths you input. This may be helpful for selecting an appropriate maximum bandwith for your application (e.g., by adopting a maximum bandwidth where the RMSE is low). There is no default.

{phang}
{opt c(#)} the cut-off threshold for the treatment. The default is zero.

{phang}
{opt sims(#)} the number of Monte Carlo simulations to perform. The default is 50.

{phang}
{opt pzms_opts(string)} any options that are available in {cmd:pzms} can be speficied here. 

{phang}
{opt pzms_opts(string)} any options that are available in {cmd:rdrobust} can be speficied here. 

{marker remarks}{...}
{title:Remarks}

{pstd}
If you find any bugs, have questions, or want to provide feedback, please get in touch with us at Nathan.Kettlewell@uts.edu and Peter.Siminski@uts.edu.au.

{pstd}
Please read the {cmd:pzms} help file before using {cmd:pzms_sim} so that you understand the default options. If computation is slow, the {bf:collapse} option might help.

{marker examples}{...}
{title:Examples}

{phang}Load example dataset.{p_end}

{phang}{cmd:. use pzms_example_data.dta, clear}{p_end}

{phang}Perform model comparison using default settings.{p_end}

{phang}{cmd:. pzms_sim y x, maxbw(0.99)}{p_end}

{phang}Now consider polynomials up to order 2 for pzms and increase the number of simulations.{p_end}

{phang}{cmd:. pzms_sim y x, maxbw(0.99) sims(100) pzms_opts(p(2))}{p_end}

{phang}Now also consider a few different maximum bandwidths.{p_end}

{phang}{cmd:. pzms_sim y x, maxbw(0.33 0.66 0.99 1.32) sims(100) pzms_opts(p(2))}{p_end}

{marker examples}{...}
{title:Stored results}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{opt e(cct_rmse):}}the RMSE (across simulations) of the treatment effect estimates generated by the {cmd:rdrobust} command{p_end}
{synopt:{opt e(cct_bw):}}the mean (across simulations) bandwidth of the estimator selected by the {cmd:rdrobust} command{p_end}
{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{opt e(pzms_rmse):}}stores the RMSE (across simulations) of the treatment effect estimates, and the mean (across simulations) bandwidth of the estimator, selected using the cmd:pzms} command, for each maximum bandwidth in {bf:maxbw(numlist)}{p_end}
{marker references}{...}
{title:References}

{phang}Kettlewell N. & Siminski P (forthcoming). Placebo Zones in Discontinuity-Based Designs: Estimation, Inference, and Implementation, {it:Economic Inquiry}{p_end}

{marker references}{...}
{title:Authors}

{phang}Nathan Kettlewell, Economics Discipline Group, University of Technology Sydney: email: Nathan.Kettlewell@uts.edu.au{p_end}

{phang}Peter Siminski, Economics Discipline Group, University of Technology Sydney: email: Peter.Siminski@uts.edu.au{p_end}
