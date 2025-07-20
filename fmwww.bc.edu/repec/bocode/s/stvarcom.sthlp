{smcl}
{* 27Oct2019}{...}
{hline}
help for {hi:stvarcom}
{hline}

{title:Subset Combinations of String Variable}

{cmd:stvarcom} generating subset combinations of string variable.

{marker syntax}{...}
{title:Syntax}

{p 4 38 2}{cmd:stvarcom} {it:strvarname} {ifin} {cmd:,} [ {opt p:arse(parse_strings)} {opt g:enerate(newvar)} {opt r:eplace} {opt n:umber(integer)} {opt c:onditionals(string)} {opt u:nique} {opt o:rder} {opt com:press} {opt no:trim} ] {p_end}

{pstd} Where the type of {it:strvarname} must be string, and number of {it:strvarname} must be 1.


{synoptset 21 tabbed}{...}
{marker options}{...}
{synopthdr}
{synoptline}
{synopt :{opt p:arse(parse_strings)}} is optional, parses on specified strings; The default is to parse on spaces (i.e. {opt p:arse}{cmd:(" ")}).{p_end}
{synopt :{opt g:enerate(newvar)}} is optional, generates a new variable about subset of combinations. The default new name includes a suffix as {res:_Comb}.{p_end}
{synopt :{opt r:eplace}} is optional, replaces the old {it:strvarname} with subset combinations. The default is to generate the new variable.{p_end}
{synopt :{opt n:umber(integer)}} is optional, specifies number of items in a subsets of.
The default is {opt n:umber}{cmd:(}{res:1}{cmd:)}. The option requires command {helpb tuples}. {p_end}
{synopt :{opt c:onditionals(string)}} is optional, eliminates subsets of combinations (i.e. tuples) according to specified conditions.{p_end}
{synopt :{opt u:nique}} is optional, uses unique values of variable {it:strvarname} to combinate subsets.{p_end}
{synopt :{opt o:rder}} is optional, sorts contents of the new variable(s) in ascending order. The default is keeping the original order.{p_end}
{synopt :{opt com:press}} is optional, compresses {it:strvarname} and the new variable(s).{p_end}
{synopt :{opt no:trim}} is optional, doesn't trim leading or trailing spaces of the new variable. The default is trim them.{p_end}
{synoptline}
{p2colreset}{...}

{p 4}{res:*** Important Notes:}{p_end}
{p 4 7 2}1. The value {it:#1} in option {opt n:umber(integer)} must be positive integer, and if {it:#1} is greater than 
the maximum number {it:#2} of strings in {it:strvarname}, the command defaults to {it:#2} instead of {it:#1};{p_end}
{p 4 7 2}2. If there are more than 1 {it:parse_strings} in {opt p:arse(parse_strings)} and {opt n:umber(integer)} larger than 1, 
the contents of the new variables are separated by the first {it:parse_strings} in {opt p:arse(parse_strings)};{p_end}
{p 4 7 2}3. The command {cmd:stvarcom} may generate some variables named with suffixes or prefixes as follows: {cmd:_Comb , StvaCombs ,}{p_end}
{p 7}So, you should avoid to including variables names with these suffixes or prefixes.{p_end}


{title:Examples}

{phang}
Basic examples:

{p 4 8 2}. {stata clear}{p_end}

{p 4 8 2}. {stata input double id str22 x}{p_end}

{p 4 8 2}. {stata 1 "dpq,WLVG,Gtul,Fp,T,NTe"}{p_end}

{p 4 8 2}. {stata 2 "GXFY,eF,y,ITp"}{p_end}

{p 4 8 2}. {stata 3 "oco,Sv,lVjM,Sv,L,nyE"}{p_end}

{p 4 8 2}. {stata end}{p_end}

{p 4 8 2}. {stata stvarcom x, p(,)}{p_end}

{p 4 8 2}. {stata dkobs 1, by(x) k}{p_end}

{p 4 8 2}. {stata stvarcom x, p(,) o}{p_end}

{p 4 8 2}. {stata dkobs 1, by(x) k}{p_end}

{p 4 8 2}. {stata stvarcom x, p(,) n(2)}{p_end}

{p 4 8 2}. {stata dkobs 1, by(x) k}{p_end}

{p 4 8 2}. {stata stvarcom x, p(,) n(2) u}{p_end}

{p 4 8 2}. {stata dkobs 1, by(x) k}{p_end}

{p 4 8 2}. {stata stvarcom x, p(,) n(2) u com}{p_end}

{p 4 8 2}. {stata dkobs 1, by(x) k}{p_end}

{p 4 8 2}. {stata stvarcom x, p(,) n(5) u}{p_end}

{p 4 8 2}. {stata dkobs 1, by(x) k}{p_end}

{p 4 8 2}. {stata stvarcom x, p(,) n(10) u}{p_end}



{title:Authors}
{phang}
{cmd:Dejin Xie}, School of Economics and Management, Nanchang University, China.{break}
 E-mail: {browse "mailto:xiedejin@ncu.edu.cn":xiedejin@ncu.edu.cn}. {break}


{title:Also see}
{p 4 14 2}Help: {helpb local}, {helpb reshape}, {helpb split}; {helpb tuples}, {helpb dkobs} (if they are installed).{p_end}
