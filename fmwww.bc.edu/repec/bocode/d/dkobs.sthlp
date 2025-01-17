{smcl}
{* 22Feb2024}{...}
{hline}
help for {hi:dkobs}
{hline}

{title:Drop or Keep A Range of Observations}

{cmd:dkobs}  is a command about dropping or keeping a range (irregular ranges are allowed) of observations.

{marker syntax}{...}
{title:Syntax}

{p 4 10 2}
{cmd:dkobs} {help numlist} {ifin}, [ {opt b:y(varlist)} {opt k:eep} {opt l:ast} {opt q:uietly} ]

{synoptset 18 tabbed}{...}
{synopthdr}
{synoptline}

{synopt :{opt b:y(varlist)}}is optional, defines group variable(s) including individuals.{p_end}
{synopt :{opt k:eep}}is optional, keeps a range of observations. The default is to drop a range of observations.{p_end}
{synopt :{opt l:ast}}is optional, specifies the last range of observations. The default is the first range of observations.{p_end}
{synopt :{opt q:uietly}}is optional, suppresses the result of the command execution. The default is to display the result.{p_end}

{synoptline}


{marker examples}{...}
{title:Examples}

{phang}
{cmd: . dkobs 1}
		
{phang}
{cmd: . dkobs 1/3 16 27}

{phang}
{cmd: . dkobs 1/3 16 27, k quietly}

{phang}
{cmd: . dkobs 1 `c(N)'}

{phang}
{cmd: . dkobs 1(2)l}

{phang}
{cmd: . dkobs 1(2)`c(N)', k}

{phang}
{cmd: . dkobs 1, by(id) keep}  // keep the first duplicate observation 

{phang}
{cmd: . dkobs 1, by(id) keep last}  // keep the last duplicate observation

{phang}
{cmd: . dkobs 1/3 16 27, by(id)}

{phang}
{cmd: . dkobs 1/3 16 27, by(id) keep}

{phang}
{cmd: . dkobs 1/3 16 27, by(id) keep last}

{phang}
{cmd: . dkobs 1/3 16 27, by(id) keep last quietly}

{phang}
{cmd: . quietly bysort id : count}

{phang}
{cmd: . dkobs 1(2)`r(N)', by(id)}

{phang}
{cmd: . dkobs 1(2)l, by(id)}


{title:Authors}

{phang}
{cmd:Dejin Xie}, School of Economics and Management, Nanchang University, China.{break}
 E-mail: {browse "mailto:xiedejin@ncu.edu.cn":xiedejin@ncu.edu.cn}. {break}


{title:Also see}

{p 4 14 2}Help: {helpb drop}, {helpb keep}.{p_end}
