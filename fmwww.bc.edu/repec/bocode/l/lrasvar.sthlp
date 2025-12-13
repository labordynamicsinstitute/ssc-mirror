{smcl}
{* 05Feb2024}{...}
{hline}
help for {hi:lrasvar}
{hline}

{title:Label or Rename Varlist as the Contents of the Specified Variable}

{cmd:lrasvar} labelling or renaming varlist as the contents of the specified variable in turn.

{marker syntax}{...}
{title:Syntax}

{p 4 32 2}{cmd:lrasvar} [{varlist}] , {opt a:s(varname)} [ {opt f:orce} {opt r:ename} {opt b:oth} {opt t:rim} {opt d:rop} ]{p_end}

{pstd} Where if the {varlist} is not specified, it means all string varlist in the database.


{synoptset 15 tabbed}{...}
{marker options}{...}
{synopthdr}
{synoptline}
{synopt :{opt a:s(varname)}}specifies the variable whose contents Assigned to {varlist} as labels (or names) in turn.{p_end}
{synopt :{opt f:orce}}is optional, runs the command when the number of {varlist} is more than obs of the specified variable.{p_end}
{synopt :{opt r:ename}}is optional, olny renames {varlist} as contents of {opt a:s(varname)} in turn. The default is only to label {varlist}.{p_end}
{synopt :{opt b:oth}}is optional, both renames and labels {varlist} as contents of {opt a:s(varname)} in turn; not allowed with option {opt r:ename}.{p_end}
{synopt :{opt t:rim}}is optional, trims leading or trailing spaces of variable in {opt a:s(varname)}, and collapses consecutive internal spaces to one.{p_end}
{synopt :{opt d:rop}}is optional, drop the variable in option {opt a:s(varname)}.{p_end}

{synoptline}


{title:Examples}

{p 4 8 2}{cmd:. lrasvar, as(new)}{p_end}

{p 4 8 2}{cmd:. lrasvar var*, as(new)}{p_end}

{p 4 8 2}{cmd:. lrasvar var*, as(new) force}{p_end}

{p 4 8 2}{cmd:. lrasvar var*, as(new) rename}{p_end}

{p 4 8 2}{cmd:. lrasvar var*, as(new) both}{p_end}

{p 4 8 2}{cmd:. lrasvar var*, as(new) both trim}{p_end}

{p 4 8 2}{cmd:. lrasvar var*, as(new) drop}{p_end}


{title:Authors}
{phang}
{cmd:Dejin Xie}, School of Economics and Management, Nanchang University, China.{break}
 E-mail: {browse "mailto:xiedejin@ncu.edu.cn":xiedejin@ncu.edu.cn}. {break}


{title:Also see}
{p 4 14 2}Help: {helpb label}; {helpb labone}, {helpb nrow2} (if they are installed).{p_end}
