{smcl}
{* 05Mar2024}{...}
{hline}
help for {hi:ewm}
{hline}

{title:The Entropy Weight Method (EWM)}

{cmd:ewm}  is a command about evaluation by the entropy weight method (EWM).

{marker syntax}{...}
{title:Syntax}

{p 4 10 2}
{cmd:ewm} {varlist} {ifin} , [ {opt s:core(newvar)} {opt un:des(varlist)} {opt b:y(varlist)}
{opt n:orm(method)} {opt sh:ift(#)} {opt sm:ooth(#)} {opt r:aw} {opt p:v} {opt ba:se} {opt l:ist} {opt k:eep} ]

{synoptset 15 tabbed}{...}
{synopthdr}
{synoptline}

{synopt :{opt s:core(newvar)}}is optional, creats a new variable which is the comprehensive score evaluated by ewm. The default new name is "{cmd:EW_Score}".{p_end}
{synopt :{opt un:des(varlist)}}is optional, defines undesirable variable sets. These variables should be the subset of {varlist}.{p_end}
{synopt :{opt b:y(varlist)}}is optional, defines group (time) variable(s). The option is applied to panel, longitudinal or multidimensional data.{p_end}
{synopt :{opt n:orm(method)}}is optional, specifies normalization method such as {res:MM}, {res:MX}, {res:L1} or {res:L2}. The default method is the Min-Max normalization (i.e. {opt n:orm}{cmd:(}{res:MM}{cmd:)}).{p_end}
{synopt :{opt sh:ift(#)}}is optional, adds a number (range is {cmd:(0, 1}{res:]}) to standardized values. This option is not allowed with {cmd:smooth(#)}.{p_end}
{synopt :{opt sm:ooth(#)}}is optional, smooths standardized values with a parameter (range is {cmd:(0, 1}{res:)}). The formula is {cmd:a+(1-a)*x} , a{c 126}(0,1).{p_end}
{synopt :{opt r:aw}}is optional, uses raw data to calculating the comprehensive score. The default is using the {cmd:Min-Max} normalized data.{p_end}
{synopt :{opt p:v}}is optional, uses proportional data to calculating the comprehensive score. This option is not allowed with option {opt r:aw}.{p_end}
{synopt :{opt ba:se}}is optional, uses the maximum and minimum values of the base period for standardization; must be set with {opt b:y(varlist)}.{p_end}
{synopt :{opt l:ist}}is optional, lists the entropy weight of {varlist} (their suffixes are {cmd:_EW}).{p_end}
{synopt :{opt k:eep}}is optional, keeps the entropy weight variables of {varlist} (their suffixes are {cmd:_EW}). The default is dropped.{p_end}

{synoptline}

{p 4}{res:*** Important Notes:}{p_end}
{p 4 7 2}1. Option {opt sh:ift(#)}, {opt sm:ooth(#)} or {opt ba:se} should work if option {opt n:orm(method)} is "{res:MM}" or "{res:MX}".{p_end}
{p 4 7 2}2. The formulas for normalization methods in option {opt n:orm(method)} are as follows:{break}
(1) {res:MM}, i.e. max-min normalization, {cmd:(Xi-Xmin)/(Xmax-Xmin)} or {cmd:(Xmax-Xi)/(Xmax-Xmin)} (for undesirable variables) ;{break}
(2) {res:MX}, i.e. maximization, {cmd:Xi/Xmax} or {cmd:1-Xi/Xmax} (for undesirable variables) ;{break}
(3) {res:L1}, i.e. sum normalization, {cmd:Xi/SUM(Xi)} or {cmd:1-Xi/SUM(Xi)} (for undesirable variables)  ;{break}
(4) {res:L2}, i.e. vector normalization, {cmd:Xi/SUM(Xi^2)} or {cmd:1-Xi/SUM(Xi^2)} (for undesirable variables) .{p_end}
{p 4 7 2}3. The command {cmd:ewm} may generate some variables named with preffixes or suffixes as follows:{break}
{cmd:EW_ , _EW , _SCOR , _ET , _MNRM , _MAXM , _MINM , _pc , _NMS , _EJ .}{break}
So, you should avoid to including variables names with these prefixes or suffixes.{p_end}


{marker examples}{...}
{title:Examples}

{phang}
1. Basic command example (the comprehensive score evaluated based on the Min-Max Normalized data):

{phang}
{cmd: . ewm x1-x10}

{phang}
{cmd: . mat list r(EW)}

{phang}
{cmd: . mat list r(EW) format(%6.4f)}

{phang}
2. Basic command example (the comprehensive score evaluated based on the raw data):
			
{phang}
{cmd: . ewm x1-x10, raw}

{phang}
{cmd: . dis r(ew)}

{phang}
{cmd: . local ew=r(ew)}

{phang}
3. Basic command example (the comprehensive score evaluated based on the proportional data, their sum is 1):
			
{phang}
{cmd: . ewm x1-x10, pv}

{phang}
6. Example of various normalization methods:

{phang}
{cmd: . ewm x1-x10, norm(MX) list}

{phang}
{cmd: . ewm x1-x10, norm(L1) list}

{phang}
{cmd: . ewm x1-x10, norm(L2) list}

{phang}
5. Extended command example:

{phang}
{cmd: . ewm x1-x10, sc(new_sc) undes(x3 x6 x8) list keep}

{phang}
{cmd: . ewm x1-x10, sc(new_sc) shift(0.01) list keep}

{phang}
{cmd: . ewm x1-x10, sc(new_sc) smooth(0.01) list keep}

{phang}
6. Example of panel, longitudinal or multidimensional data:

{phang}
{cmd: . ewm x1-x10, by(year) list keep}

{phang}
{cmd: . ewm x1-x10, by(year) base list keep}


{marker results}{...}
{title:Saved Results}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(EW)}}Entropy weight matrix{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(ew)}}Entropy weight ; if option {opt b:y(varlist)} is {cmd:not} set{p_end}


{title:Authors}

{phang}
{cmd:Dejin Xie}, School of Economics and Management, Nanchang University, China.{break}
 E-mail: {browse "mailto:xiedejin@ncu.edu.cn":xiedejin@ncu.edu.cn}.{break}


{title:Also see}

{p 4 14 2}Help:  {helpb egen}, {helpb entropyetc} (if installed).{p_end}
