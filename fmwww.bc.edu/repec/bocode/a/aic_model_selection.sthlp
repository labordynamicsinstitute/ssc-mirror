{smcl}
{* *! version 0.0.1  30 April 2021}{...}

{...}{* NB: these hide the newlines }
{...}
{...}
{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{cmd:aic_model_selection} {hline 2}} Forward Model Selection using AIC or BIC  {p_end}


{title:Syntax}

{p 8 16 2}
{cmd:aic_model_selection} 
{it: command_name}
{it:varlist}
,
[
{cmdab:bic}
]
{p2colreset}{...}


{title:Description}

{pstd}
{cmd:aic_model_selection} performs a regression on a sequence of models adding one x-variable (in the order specified) at a time. For example, when specifying 
{cmd: aic_model_selection regress y x1 x2 x3} the following regression models are computed: 

{pmore}
regress y x1

{pmore}
regress y x1 x2

{pmore}
regress y x1 x2 x3 

{pstd}
For each model {cmd:aic_model_selection} outputs the AIC value. 


{pstd}
Why is this useful? Often, it is not possible to conduct all possible subsets regression 
because there are too many models to consider.
The traditional alternative has been forward/stepwise/backward model selection.
While the sequence of models generated this way is unproblematic, 
the p-values are not valid because they do not take the selection procedure into account.
One solution is to compute AIC for the sequence of models generated, and to choose the model with the smallest AIC.
(see, for example, James et al. (2013, Section 6.1).

{pstd}
{cmd:aic_model_selection} facilitates this computation: First, run a forward selection ("stepwise , pe(.5)"). 
Next,  use {cmd:aic_model_selection} to compute the AIC (or BIC) values of the same sequence of models.
Then, choose the model with lowest AIC (or BIC) value.

{pstd}
{it: command_name} is intended for all commands that are allowed for {cmd:sw} including {cmd:regress} and {cmd:logistic}.


{title:Options}

{phang}
{opt bic} Display the BIC criterion instead of the AIC criterion. Note that {cmd:bic} is not capitalized. {p_end}


{title:Examples}

{pstd}Example:  First, we run a forward selection with a generous p-value (here 0.5). The p-value is generous to avoid missing the model with the lowest AIC value. 
We need a list of variables added in the order they were added during forward selection. The list can be created by looking at the output of {cmd:sw}. 
Alternatively, 
Stata saves the variables added in the right sequence in {cmd:r(table)} and one can copy and paste the sequence of variables.
Next, we run {cmd:aic_model_selection} with this ordered list of variables. We choose the model with the smallest AIC value. Here, the model with the smallest AIC includes variables up to {cmd: mpg}.  

{marker examples}{...}

{phang}{cmd: .sysuse auto}

{phang}{cmd: .sw, pe(0.5): logistic foreign mpg rep78 headroom trunk weight length turn displacement gear_ratio}

{phang}{cmd: .matrix list r(table)}

{phang}{cmd: .aic_model_selection logistic foreign weight gear_ratio rep78 mpg headroom turn}

{pstd}{it:({stata aic_model_selection_examples aic:click to run})}{p_end}


{marker authors}{...}
{title:Authors}

{pmore} Matthias Schonlau <schonlau@uwaterloo.ca>{p_end}


{marker reference}{...}
{title:References}

{pstd} James, Witten, Hastie, Tibshirani. 2013. An introduction to statistical learning, Section 6.1 {p_end}

