{smcl}
{* *! version 1.0 19 Mar 2024}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install stfform" "ssc install stfform"}{...}
{vieweralsosee "Help stfform (if installed)" "help stfform"}{...}
{viewerjumpto "Syntax" "stfform##syntax"}{...}
{viewerjumpto "Description" "stfform##description"}{...}
{viewerjumpto "Options" "stfform##options"}{...}
{viewerjumpto "Remarks" "stfform##remarks"}{...}
{viewerjumpto "Examples" "stfform##examples"}{...}
{title:Title}
{phang}
{bf:stfform} {hline 2} Functional form test for Cox Models

{marker syntax}{...}
{title:Syntax}
{p 8 15 2}
{cmdab:stfform} [{it:{help varlist:varlist}}] [
{cmd:,}
{it:options}]

{pstd}
should be used afer {cmd: stcox}, the current dataset should be {cmd: stset} before using {cmd: stfform}. 
If {it:varlist} is not specified, {cmd: stfform} performs the functional form test for all the numeric covariates used in the previous call of {cmd: stcox}. 
Numeric covariates and categorical covariates are classified internally using {cmd: vl set}. 
If {it:varlist} is specified {cmd: stfform} discards variables not included in the previous call of {cmd: stcox}.

{synoptset 29 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Optional}
{synopt:{opt nsim:ulation(#)}}  sets the number of simulated values for the cumulative martingale residuals. Default value is 1000.

{synopt:{opt nog:raph}}  forces {cmd: stfform} not to display the plots. 

{synopt:{opt nplot(#)}}  sets the number of simulations displayed in the plot. Default value is 20.

{synopt:{opt saving(filename [, replace])}}  save the simulation data to filename; use {opt replace} to overwrite existing {it:filename}.

{synopt:{opt noxb}}  forces {cmd: stfform} not to test the functional form of the link function. 

{synopt:{opt novars}}  forces {cmd: stfform} not to test the functional form of the variables. 

{synopt:{opt nolog}}  forces {cmd: stfform} not to display the progress bar during the execution. 

{synopt:{opt graphnames(stub)}}  sets the prefix of the graph names to be saved for future use. 

{synopt:{opt obscolor(string)}}  sets the line color of observed process in the graphs. 

{synopt:{opt simcolor(string)}}  sets the line color of simulated process in the graphs.

{synoptline}
{p2colreset}{...}
{p 8 15 2}

{marker description}{...}
{title:Description} 

{pstd}
{cmd: stfform} performs test for the functional form and the adequacy of the exponential link function of a previously fit Cox model. The command is based on Lin, Wei and Ying (1993) . 

{pstd}

{marker options}{...}
{title:Options}
{dlgtab:Main}

{phang}
{opt nsim:ulation(#)} sets the number of simulations for the cumulative martingale residuals. Default value is 1000.

{phang}
{opt nog:raph} forces {cmd: stfform} not to display the plots. This option is overridden if {bf:nisimulation}> {bf: maxvar} - 3.

{phang}
{opt nplot(#)} sets the number of simulations displayed in the plot. Default value is 20.

{phang}
{opt saving(filename [, replace])}   creates a Stata data file (.dta file) in long format. This dataset contains, for each variable, the values (variable {it: z}), the cumulative martingale residuals (variable {it: M}) and the simulated realizations of the null process  (varlist {it: W*}). Variables are identified by variable {it: var}. This option is overridden if {bf:nisimulation}> {bf: maxvar} - 3. Use {opt replace} to overwrite existing {it:filename}.

{phang} 
{opt noxb} forces {cmd: stfform} not to test the functional form of the link function. 

{phang} 
{opt noxb} forces {cmd: stfform} not to test the functional form of the variables. 

{phang} 
{opt nolog} forces {cmd: stfform} not to display the progress bar during the execution. 

{phang}
{opt graphnames(stub)} sets the prefix of the graph names to be saved for future use. {cmd: stfform} saves one graph for each of the requested tests. This option is overridden if {opt nograph} is specified, the default is {it:_stff_}. Existing graphs are overwritten.

{phang}
{opt obsc:olor(string)}  sets the line color of observed process in the graphs. The default is {bf: orange}.

{phang}
{opt simc:olor(string)}  sets the line color of simulated process in the graphs. The default is {bf: gs7}.

{marker examples}{...}
{title:Examples}
    Setup
        {cmd: . webuse drugtr}
    Show st settings
        {cmd: . stset}
    Fit Cox proportional hazards model
        {cmd: . stcox drug age}
    Test the functional form 
        {cmd: . stfform}

{title:Author}
	Daniele Spinelli
	Department of Statistics and Quantitative Methods
	University of Milano-Bicocca, Italy
	daniele.spinelli@unimib.it
{p}



