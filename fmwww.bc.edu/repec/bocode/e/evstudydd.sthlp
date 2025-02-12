{smcl}
{vieweralsosee "reghdfe" "help reghdfe"}{...}
{vieweralsosee "ppmlhdfe" "help ppmlhdfe"}{...}

{title:Title}


{pstd}
{bf:evstudydd} - estimate event studies in D-i-D settings using the {help reghdfe} or {help ppmlhdfe} packages. 
{bf:evstudydd} produces all the point estimates and standard errors, together with a time indicator, and saves them in a .dta file, which can then be merged or appended with other files to produce more flexible graphs. 


{marker syntax}{...}
{title:Syntax}

{phang}
{cmd: evstudydd} {it: Y t} [if] [in], {ul:t}reated(name) {ul:shockt}ime(string) {ul:p}eriod(string) {ul:cl}uster(string) {ul:fe}(string) {ul:n}ame(string) [{ul:w}eight(name)] [{ul:contr}ols(string)] [{ul:e}stimator(string)] [{ul:int}eraction(varname)]
{p_end}


{synoptset 8 tabbed}{...}
{synopt : {it:Y}}outcome variable {p_end}
{synopt : {it:t}}variable for calendar period {p_end}


{marker description}{...}
{title:Description}

{pstd}
{bf: evstudydd} produces the event study for any D-i-D setting, generates variables for the point estimates, standard errors, and time indicators, and saves these three variables in a .dta file.
{p_end}

{pstd}
The command saves the following variables in the output dataset:
{p_end}

{phang2}B: Point estimates for the treatment effects{p_end}
{phang2}SE: Standard errors of the estimates{p_end}
{phang2}time: Time indicators relative to the event (-k to +j){p_end}


{marker options}{...}
{title:Options}

{phang}{opt treated(name)}: Specifies the cross-sectional variable that identifies the treated group. This variable should be time-invariant. This is a required option.
{p_end}


{phang}{opt shocktime(string)}: Specifies the time of reference used for the event study. It can either be a variable in your dataset that records the time where the shock happens, or you can directly enter a value. {bf: evstudydd} can accommodate staggered treatment provided that the variable you use contains different time of treatment for different units.  
The variable should be time invariant within each unit. The interaction of {it: treated} and {it: shocktime} gives the D-i-D variable. {cmd:shocktime} is a required option.
{p_end}


{phang}{opt period(string)}: Specifies the window to use for the event study. It should contain two values (e.g., 3 and 3) that will determine the time t-j and t+k of the event study (where t is the time of the shock as specified by the option {cmd:shocktime(string)}). The outcome will be an event study that produces j+1 coefficients in the pre-shock period and k+1 coefficients in the post-shock period. The extra time before and after the shock ensures that if the working sample has a longer time span around the shock than the window specified, the event study will include a dummy ``all the years prior to t-j'' and a dummy ``all the years after t+k.'' {cmd:period} is a required option.
{p_end}


{phang}{opt cluster(string)}: Specifies the level at which standard errors should be clustered. This is a required option.
{p_end}


{phang}{opt fe(string)}: Specifies the variables that will be included as fixed effects (FE) in the absorb() part of reghdfe or ppmlhdfe. This is a required option. Let id be the variable identifying units (treated or not) and t the time period variable. Writing  {cmd:fe(id t)} yields the standard D-i-D (two-way FE) model. You can include fewer FEs: for example, only period FE by writing {cmd:fe(t)}. You can also include more FEs, or interactions: for example, assume that all units id can be assigned to a variable called geography, then you can write {cmd:fe(id geography#t)}.
{p_end}


{phang}{opt name(string)}: Specifies the name of the file where the point estimates, standard errors, and time indicators are saved after the event study is conducted. The name of the variables are B for point estimates, SE for standard errors, and time for time indicators. This is a required option. You can include the .dta extension in the command, but if not, the command will automatically add it. Thus, writing {cmd:name("example.dta")} and {cmd:name("example")} is equivalent. You can specify a full path. For example: {cmd:name("/Users/janedoe/project/example")}. You can also use globals. For example, after defining {cmd:global folder "/Users/janedoe/project"}, you can write {cmd:name("$folder/example")}.
{p_end}


{phang}{opt weight(name)}: Specifies the variable that will be used to weight the regression. This is not a required option. If not specified, the command automatically assumes that the regression is equally weighted. Weights can only be used with the reghdfe package.
{p_end}


{phang}{opt controls(string)}: List of continuous time-varying controls. This is not a required option. 
{p_end}


{phang}{opt estimator(string)}: Estimator used in the regression. It is either the reghdfe or the ppmlhdfe package. Default is reghdfe. Thus, if not specified, the command uses reghdfe. Writing {cmd:estimator(reghdfe)} or {cmd:estimator(ols)} uses the reghdfe package. Writing {cmd:estimator(ppmlhdfe)} or {cmd:estimator(poisson)} uses the ppmlhdfe package. This is not a required option. 
{p_end}


{phang}{opt interaction(varname)}: Allows specifying a continuous variable that interacts with the treatment timing indicators. When specified, the command estimates both the base treatment effects and interaction effects for each period. The output dataset will include additional variables B_int and SE_int containing the interaction term coefficients and their standard errors respectively. The interaction is created for all event-time dummies, including pre-treatment periods, the reference period (which is set to zero), and post-treatment periods. For example, if you want to study heterogeneous treatment effects by firm size, you could specify {cmd:interaction(firm_size)}. This will create interactions between the treatment timing indicators and firm size, allowing you to examine how the treatment effect varies with firm size over time.
{p_end}


{marker example}{...}
{title:Example}


{phang}{bf:1)} D-i-D estimation for three periods before and after the shock. The outcome is the variable Y. The variable for the calendar period is year. Treated units are identified by the variable treat. The time of the shock is identified by the variable yrshock. Standard errors are clustered at the id level. Units and year fixed effects are included. The output file is called example.dta. Here the packaged used is reghdfe because the option estimator is not specified. The regression is equally weighted because the option weights is not specified. 
{p_end}

	{cmd:evstudydd Y year, treated(treat) shocktime(yrshock) period(3 3) cluster(id) fe(id year) name("example")}


{phang}{bf:2)} Same but here the regression is weighted by the variable w. 
{p_end}

	{cmd:evstudydd Y year, treated(treat) shocktime(yrshock) period(3 3) cluster(id) fe(id year) name("example") weight(w)}


{phang}{bf:3)} Same but include time-varying controls. The age of the unit, for example. 
{p_end}

	{cmd:evstudydd Y year, treated(treat) shocktime(yrshock) period(3 3) cluster(id) fe(id year) name("example") weight(w) controls(age)}


{phang}{bf:4)} Assume that all units id can be assigned to a variable called geography. D-i-D estimation for 6 periods before and  5 after the shock. The outcome is the variable Y. The variable for the calendar period is t. Treated units are identified by the variable treat. The time of the shock is identified by the variable tshock. Standard errors are clustered at the id level. Unit and geography by year fixed effects are included. The output file is called example.dta. Here the regression is equally weighted because the option weights is not specified.
{p_end}
	
        {cmd:evstudydd Y t, treated(treat) shocktime(tshock) period(6 5) cluster(id) fe(id geography#year) name("example")}


{phang}{bf:5)} Same but use the ppmlhdfe package. Here the regression is equally weighted because the option estimator(ppmlhdfe) is used (remember that ppmlhdfe does not accept analytical weights). Writing estimator(ppmlhdfe) or estimator(poisson) here is equivalent. 
{p_end}
	
        {cmd:evstudydd Y t, treated(treat) shocktime(tshock) period(6 5) cluster(id) fe(id geography#year) name("example") estimator(ppmlhdfe)}


{phang}{bf:6)} Same but specify the reghdfe package instead. Here the regression is equally weighted because the option weights is not specified. Writing estimator(reghdfe) or estimator(ols) here is equivalent. 
{p_end}
	
        {cmd:evstudydd Y t, treated(treat) shocktime(tshock) period(6 5) cluster(id) fe(id geography#year) name("example") estimator(reghdfe)}
	

{phang}{bf:7)} Similar to example 1 but including heterogeneous effects by firm size:
{p_end}

       {cmd:evstudydd Y year, treated(treat) shocktime(yrshock) period(3 3) cluster(id) fe(id year) name("example") interaction(firm_size)}


{marker author}{...}
{title:Authors}

{pstd}
Adrien Matray (adrien.matray@gmail.com), Pablo E. Rodriguez (pablo6@mit.edu)
{p_end}

{title:Comments}

{pstd}
Send any suggestions or feedback to Adrien Matray (adrien.matray@gmail.com).
{p_end}




