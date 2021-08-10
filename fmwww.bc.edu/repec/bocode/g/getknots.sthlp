{smcl}
{* 15March2008}
help for {hi:getknots}
{hline}

{title:Title}

{p2colset 5 17 19 2}{...}
{p2col :{hi: getknots} {hline 2}}Stores the location of knots in a local macro.{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 15 2}
{cmd:getknots} 

{title:Description}

{pstd}
{cmd:getknots} can be used after the {help mkspline} command using the 
{cmd:cubic} option. It stores the location of the knots in a local macro 
called `knots'.


{title:Example}

{cmd}
{phang}{stata "sysuse uslifeexp, clear"}{p_end}
{phang}{stata "drop if year == 1918"} /// spanish flu {p_end}
{phang}{stata "mkspline ys = year, cubic"}{p_end}
{phang}{stata "getknots"}{p_end}
{phang}{stata `"di "`knots'""'}{p_end}
{txt}


{title:Author}

{p 4 4}
Maarten L. Buis{break}
Vrije Universiteit Amsterdam{break}
Department of Social Research Methodology{break}
m.buis@fsw.vu.nl 
{p_end}


{title:Also see}


{psee}Online:  {helpb mkspline} {p_end}
{psee}If installed: {helpb mfxrcspline}{p_end}
