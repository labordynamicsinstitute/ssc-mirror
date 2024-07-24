{smcl}


{title:Title}


{pstd}
{bf:evstudydd} - evstudydd is a command to estimate event studies in D-i-D settings using the reghdfe routine. 
It produces all the point estimates and standard errors, together with a time indicator, and save them in a .dta, which can them be merged or appended with other files to produce more flexible graphs. 


{marker syntax}{...}
{title:Syntax}

{phang}
{cmd: evstudydd} {it: numeric} [if] [in], {ul:t}reated(name) {ul:shocky}ear(string) {ul:p}eriod(string) {ul:cl}uster(string) {ul:fe}(string) [{ul:w}eight(name)] [{ul:n}ame(string)] 
{p_end}


{marker description}{...}
{title:Description}

{pstd}
{bf: evstudydd} evstudydd produces the event study for any DiD setting, generates variables for the point estimates and standard errors, and save the coefficients in a .dta
{p_end}




{marker options}{...}
{title:Options}

{phang}{opt treated(name)}: Specifies the cross-sectional variable that identifies the treated group. This variable should be time-invariant. This is a required option.
{p_end}


{phang}{opt shockyear(string)}: Specifies the year of reference used for the event study. It can either be a variable in your dataset that records the time where the shock happens, or you can directly enter a value. {bf: evstudyDD} can accommodate staggered treatment provided that the variable you use contains different time of treatment for different units.  
The variable should be time invariant within each unit. The interaction of {it: treated} and {it: shockyear} gives the DiD variable. {cmd:shockyear} is a required option.
{p_end}



{phang}{opt period(string)}: Specifies the window to use for the event study. It should contain two values (e.g., 3 and 3) that will determine the time t-k and t+k of the event study (where t is the year of the shock as specified by the option {cmd:shockyear(string)}. The outcome will be an event study that produces k+1 coefficients in the pre-shock period and t+k coefficients in the post-shock period. The extra time before and after the shock ensures that if the working sample has a longer time span around the shock than the window specified, the event study will include a dummy ``all the years prior to t-k'' and a dummy ``all the years after t+k''.{cmd:period} is a required option.
{p_end}



{phang}{opt cluster(string)}: Specifies the level of which the regression should be clustered. This is a required option.
{p_end}


{phang}{opt fe(string)}: Specifies the variables that will be included as fixed effects in the absorb() part of reghdfe. This is a required option.
{p_end}


{phang}{opt weight(name)}: Specifies the variable that will be used to weight the regression. This is not a required option. If not specified, the command automatically assumes that the regression is equally weighted. 


{phang}{opt name(string)}: Specifies the name of the file where the point estimates and standard errors are saved after the event study is conducted. This is not a required option. 


{marker author}{...}
{title:Authors}

{pstd}
Adrien Matray (adrien.matray@gmail.com), Pablo E. Rodriguez (pablo6@mit.edu)
{title:Comments}

Send any suggestions or feedback to Adrien Matray (adrien.matray@gmail.com)).


