{smcl}
{* 28Mar2025}{...}
{hline}
help for {hi:stvarag}
{hline}

{title:Aggregated Values of String Variable(s)}

{cmd:stvarag} collects aggregated values of string variable(s) by vertical way (i.e. row-by-row).

{marker syntax}{...}
{title:Syntax}

{p 4 32 2}{cmd:stvarag} {it:strvarlist} {ifin} {cmd:,} [ {opt b:y(varlist)} {opth g:enerate(newvarlist)} {opt s:uffix(string)} {opt d:ups} {opt u:niq} {opt n:ogen} {opt p:arse(parse_strings)} {opt o:rder}  {opt no:trim} ] {p_end}

{pstd} Where the type of {it:strvarlist} must be string.


{synoptset 21 tabbed}{...}
{marker options}{...}
{synopthdr}
{synoptline}
{synopt :{opt b:y(varlist)}} is optional, defines group (time) variable(s). It is applied to panel, longitudinal or multidimensional data.{p_end}
{synopt :{opth g:enerate(newvarlist)}} is optional, defines the name(s) of new aggregated variable(s), and not allow with option {opt s:uffix(string)} or {opt n:ogen}.{p_end}
{synopt :{opt s:uffix(string)}} is optional, supplles a suffix for new variable(s). The default is to replace the original variable(s).{p_end}
{synopt :{opt d:ups}} is optional, generates a new variable on duplicate values of {it:strvarlist}, named with suffix as {res:_dups}.{p_end}
{synopt :{opt u:niq}} is optional, generates a new variable on unique values of {it:strvarlist}, named with suffix as {res:_uniq}.{p_end}
{synopt :{opt n:ogen}} is optional, not generate new aggregated variables; should be set with {opt d:ups} or {opt u:niq}, but not wtih {opt g:enerate(newvars)} or {opt s:uffix(string)}.{p_end}
{synopt :{opt p:arse(parse_strings)}} is optional, parses on specified strings; The default is to parse on spaces (i.e. {opt p:arse}{cmd:(" ")}).{p_end}
{synopt :{opt o:rder}} is optional, sorts contents of the new variable(s) in ascending order. The default is keeping the original order.{p_end}
{synopt :{opt no:trim}} is optional, doesn't trim leading or trailing spaces of original and new variable(s). The default is to trim them.{p_end}
{synoptline}
{p2colreset}{...}

{p 4}{res:*** Important Notes:}{p_end}
{p 4 7 2}1. The option {opth g:enerate(newvarlist)}, {opt s:uffix(string)} or {opt n:ogen} should be set at most one, and if neither is set, the default is replacing original variable(s);{p_end}
{p 4 7 2}2. If the option {opth g:enerate(newvarlist)} is set, its {err:number} and {err:order} must be correspond one-to-one with {it:strvarlist};{p_end}
{p 4 7 2}3. If the option {opt d:ups} is set, a string appears n times in the variable with suffix {res:_dups}, which means n + 1 times in the original variable;{p_end}
{p 4 7 2}4. If the option {opt p:arse(parse_strings)} is "{res:null}", it means no parse string (i.e. null space) are used for joining;{p_end}
{p 4 7 2}5. The command {cmd:stvarag} may generate some variables named with suffixes as follows: {cmd:_dups , _uniq ,}{p_end}
{p 7}So, you should avoid to including variables names with these suffixes.{p_end}


{title:Examples}

{phang}
Basic examples:

{p 4 8 2}. {stata clear}{p_end}

{p 4 8 2}. {stata input double year str43 nball}{p_end}

{p 4 8 2}. {stata 2019	"Antetokounmpo,	George,	Jokic,	Harden,	Curry"}{p_end}

{p 4 8 2}. {stata 2018 "James, Durant, Davis, Harden, Lillard"}{p_end}

{p 4 8 2}. {stata 2017 "James, Leonard, Davis, Harden, Westbrook"}{p_end}

{p 4 8 2}. {stata end}{p_end}

{p 4 8 2}. {stata stvarag nball}{p_end}

{p 4 8 2}. {stata stvarag nball, p(;) g(new)}{p_end}

{p 4 8 2}. {stata stvarag nball, p(,) n d}{p_end}

{p 4 8 2}. {stata stvarag nball, p(,) s(N)}{p_end}

{p 4 8 2}. {stata stvarag nball, p(,) s(N) d u}{p_end}

{p 4 8 2}. {stata stvarag nball, p(,) s(N) d u o}{p_end}

{p 4 8 2}. {stata fdtax ,f(,) t(" ")}{p_end}

{p 4 8 2}. {stata stvarag nball, s(N) d u o}{p_end}

{p 4 8 2}. {stata stvarag nball, p(null)}{p_end}

{phang}
Run the command row-by-row (non-aggregate), similar to the command {helpb stvarud}:

{p 4 8 2}. {stata gen id=_n}{p_end}

{p 4 8 2}. {stata replace nball = "James, Durant, Davis, Harden, Lillard, James" in 2}{p_end}

{p 4 8 2}. {stata stvarag nball, by(id) p(,) u n}{p_end}



{title:Authors}
{phang}
{cmd:Dejin Xie}, School of Economics and Management, Nanchang University, China.{break}
 E-mail: {browse "mailto:xiedejin@ncu.edu.cn":xiedejin@ncu.edu.cn}.{break}


{title:Also see}
{p 4 14 2}Help: {helpb local}, {helpb functions}; {helpb stvarcom}, {helpb ecollapse} (if they are installed).{p_end}
