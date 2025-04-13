{smcl}
{* *! version 1.0.0  10mar2015}{...}
{* revised: }{...}
{cmd:help spsfe postestimation}{right:also see: {help spsfe}}
{hline}

{title:Title}

{p2colset 5 32 38 2}{...}
{p2col :{hi:spsfe postestimation} {hline 2}}Postestimation tools for spsfe{p_end}
{p2colreset}{...}


{title:Description}

{pstd}
The following postestimation commands are available for {cmd:spsfe}.

{synoptset 13}{...}
{p2coldent :command}description{p_end}
{synoptline}
{synopt:{bf:{help estat}}}AIC, BIC, VCE, and estimation sample summary{p_end}
INCLUDE help post_estimates
INCLUDE help post_lincom
INCLUDE help post_lrtest
INCLUDE help post_nlcom
{synopt :{helpb spsfe postestimation##predict:predict}}predictions, residuals, influence statistics, and other diagnostic measures{p_end}
INCLUDE help post_predictnl
INCLUDE help post_test
INCLUDE help post_testnl
{synoptline}
{p2colreset}{...}


{marker predict}{...}
{title:Syntax for predict}

{p 8 16 2}{cmd:predict} {dtype} {newvar} {ifin} [{cmd:,} {it:statistic}]

{synoptset 15 tabbed}{...}
{synopthdr :statistic}
{synoptline}
{syntab:Main}
{synopt :{opt xb}}linear prediction; the default{p_end}
{synopt :{opt residuals}}estimates of residuals (depvar - xb) {p_end}
{synopt :{opt u}}estimates of (technical or cost) inefficiency via {it:E}(u|e) (Jondrow et al., 1982){p_end}
{synopt :{opt te}}estimates of (technical or cost) efficiency via exp[-E(u|e)]{p_end}
{synopt :{opt su}}estimates of spatial-corrected inefficiency{p_end}
{synopt :{opt ste}}estimates of spatial-corrected efficiency{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
These statistics are only available for the estimation sample.


INCLUDE help menu_predict


{title:Options for predict}

{dlgtab:Main}

{phang}
{opt xb}, the default, calculates the linear prediction.

{phang}
{opt residuals} calculates the composite residuals (depvar - xb).

 
{phang}
{opt u} produces estimates of (technical or cost) inefficiency via E(u|e) using the Jondrow et al. (1982) estimator.

{phang}
{opt te} produces estimates of (technical or cost) efficiency via exp[-E(u|e)]. 


{phang}
{opt su} produces estimates of spatial-corrected inefficiency as Kultu et al.(2020). 


{phang}
{opt ste} produces estimates of spatial-corrected efficiency as Kultu et al.(2020). 


{title:Remarks}

{pstd} For the postestimation, the option {cmd:genwvars} should be specified in {cmd:spsfe} when estimating the models with spatial dependence. When the {cmd:spsfe} command is used to estimate 
production frontiers, {cmd:predict} will provide the post-estimation of technical (in)efficiency, 
while when the {cmd:spsfe} command is used to estimate cost frontiers, {cmd:predict} will provide the post-estimation of cost (in)efficiency.{p_end}



    {marker examples}{...}
    {title:Examples}
    
        {title:SP-SF model with time-constant spatial weight matrix}
    
    {pstd}
    Setup{p_end}
    {phang2}{bf:. {stata "mata mata matuse w_ex1,replace"}}{p_end}
    {phang2}{bf:. {stata "use sdsfbc_ex1.dta"}}{p_end}
    
    {pstd}
    Stochastic Durbin production model {p_end}
    {phang2}{bf:. {stata "spsfe y x, id(id) time(t) noconstant wmat(wm,mata) mu(z) wxvars(x) wmuvars(z) genwvars "}}{p_end}
    {phang2}{bf:. {stata "predict uhat,u"}}{p_end}
    {phang2}{bf:. {stata "predict te_bc,bc"}}{p_end}
    {phang2}{bf:. {stata "predict te_jlms,jlms"}}{p_end}
    

{marker author}{...}
{title:Author}

{pstd}
Kerui Du{break}
Xiamen University{break}
School of Management{break}
China{break}
{browse "kerrydu@xmu.edu.cn":kerrydu@xmu.edu.cn}{break}


{pstd}
Federica Galli{break}
University of Bologna{break}
Department of Statistical Sciences “Paolo Fortunati”{break}
Italy{break}
{browse "federica.galli14@unibo.it":federica.galli14@unibo.it}{break}


{pstd}
Luojia Wang{break}
Xiamen University{break}
School of Management{break}
China{break}
{browse "ljwang@stu.xmu.edu.cn":ljwang@stu.xmu.edu.cn}{break}


{title:Also see}

{psee}
{space 2}Help:  {help spsfe}.
{p_end}
