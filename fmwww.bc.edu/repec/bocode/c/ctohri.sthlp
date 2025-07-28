{smcl}
{* 22072025}{...}
{hline}
help for {hi:ctohri}
{hline}

{title:From Counts to Hazard Ratio}

{p 4 14 10}{cmd:ctohri} {it:#n1} {it:#c1} {it:#t1} {it:#n0} {it:#c0} {it:#t0} {p_end}

{p 4 14 10} where  {p_end}

{p 4 14 10}{it:#n1}   is the sample size in the treatment group {p_end}
{p 4 14 10}{it:#c1} is the total events in the treatment group {p_end}
{p 4 14 10}{it:#t1} is the follow-up period in the treatment group {p_end}

{p 4 14 10}{it:#n0}   is the sample size in the control group {p_end}
{p 4 14 10}{it:#c0} is the total events in the control group {p_end}
{p 4 14 10}{it:#t0} is the follow-up period in the control group {p_end}

{title:Description}

{pstd}{cmd:ctohri} estimates the hazard ratio along with a confidence interval and Wald-type hypothesis test under the assumptions (constant baseline hazard and proportional hazards) of an Exponential (or Poisson) survival model. 
The force underlying censoring should be similar in both groups. 
Specifically, it requires six inputs: the number of participants, number of events, and total follow-up time for both the treatment and control groups. 
It can be used for meta-analyses when individual-level survival data are not available.

{title:Example #1}

	{title:Open and setup the survival data}

	{stata "use http://www.stats4life.se/data/data_ctohri.dta, clear"}
	{stata "stset time, failure(event)"}

	{title:Use individual data to estimate the hazard ratio under the assumptions of an Exponential survival model}

	{stata "streg trt , dist(exponential)"}

	{title:Use summary data under the assumptions of an Exponential survival model}
	{p 5 5 20}Over 2 years of follow-up, 795 of the 1,554 patients assigned to the treatment group died, compared to 870 of the 1,446 patients assigned to the control group.{p_end}

	{stata "ctohri 1554 795 2 1446 870 2"}
	
{title:Example #2}

{p 5 5 20}Over 4 years of follow-up, 306 of the 3,051 patients assigned to the treatment group died, compared to 319 of the 3,054 patients assigned to the control group.{p_end}

	{title:Use summary data under the assumptions of an Exponential survival model}

	{stata "ctohri 3051 306 4 3054 319 4"}

{cmd:ctohri} stores in {cmd:r()}, just type return list.

{title:Author}

{p 4 8 2}Nicola Orsini, Biostatistics Team,
Department of Global Public Health, Karolinska Institutet, Sweden{p_end}

{title:Support}

{p 4 12}{browse "https://ki.se/en/people/nicola-orsini"}{p_end}
{p 4 12}{browse "mailto:nicola.orsini@ki.se?subject=info ctohrci":nicola.orsini@ki.se}
