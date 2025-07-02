{smcl}
{hline}
help testvec 
{hline}

{title:Title} 

{p2col :{hi:testvec} {hline 2}}Retrieve cointegrating vectors after vec {p_end}

{title:Description} 

{p 4 4 2}This program can be run after a {cmd:vec} command to retrieve the estimated cointegrating 
vectors and place them in the e-returns. This permits commands such as {cmd:test}, {cmd:testparm}
and {cmd:lincom} to be applied to the point and interval estimates of the cointegrating vectors.

{p 4 4 2}The only option is {opt print}, which displays the cointegrating vectors and 
their VCE.

{title:Example of use}

{phang2}{bf:. {stata "webuse urates":webuse urates}}{p_end}

{phang2}{bf:. {stata "vec missouri indiana kentucky illinois arkansas,  rank(2)":vec missouri indiana kentucky illinois arkansas,  rank(2)}}{p_end}

{phang2}{bf:. {stata "testvec":testvec}}{p_end}

{phang2}{bf:. {stata "test [_ce2]illinois = [_ce2]kentucky ":test [_ce2]illinois = [_ce2]kentucky }}{p_end}

{phang2}{bf:. {stata "lincom [_ce1]kentucky + [_ce1]illinois + [_ce1]arkansas":lincom [_ce1]kentucky + [_ce1]illinois + [_ce1]arkansas}}{p_end}

{title:Author} 

{p 4 4 2}Kit Baum, Boston College{break} 
         baum@bc.edu

