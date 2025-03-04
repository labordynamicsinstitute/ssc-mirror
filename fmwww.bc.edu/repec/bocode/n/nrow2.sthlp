{smcl}
{* 12Apr2024}{...}
{hline}
help for {hi:nrow2}
{hline}

{title:Rename Variables as Their nth Row Values}

{cmd:nrow2} rename variables as their nth row values.


{title:Syntax}

{p 4 16 2}
{cmd:nrow2} [{varlist}] [ , {opt n:row(integer)} {opt p:refix(string)} {opt o:nlynum} {opt i:gnore(string)}
 {opt t:rim} {opt s:pace} {opt k:eep} {opt d:estring} {opt c:ompress} ]
{p_end}

{pstd}If {varlist} is not specified or specified as _all, it means all variables in the database.


{title:Options}

{phang}
{opt n:row(integer)} is optional, specify nth rows for using their contents to rename the variables; if not specified, the first row is used.{p_end}

{phang}
{opt p:refix(string)} is optional, supplles a prefix for new variables.

{phang}
{opt o:nlynum} is optional, only supplles a prefix for numeric variables, needs to worked with option {opt p:refix(string)}.

{phang}
{opt i:gnore(string)} is optional, removes specified nonnumeric characters when renaming variables.

{phang}
{opt t:rim} is optional, is optional, removes specified nonnumeric characters when renaming variables.

{phang}
{opt s:pace} is optional, removes white spaces when renaming variables. It is not allowed with option {opt t:rim}.

{phang}
{opt k:eep} is optional, keeps the {opt row#} row. The default is to drop the relevant rows. {p_end}

{phang}
{opt d:estring} is optional, converts string variables to numeric variables. It may be not worked with option {opt k:eep}.
See {helpb destring} for details.

{phang}
{opt c:ompress} is optional, compresses the variables.


{title:(1) Basic Examples}

{phang}
{cmd:. nrow2}

{phang}
{cmd:. nrow2 var3-var9}

{phang}
{cmd:. nrow2 var* , keep}

{phang}
{cmd:. nrow2, nrow(3) prefix(gdp) trim}

{phang}
{cmd:. nrow2, prefix(gdp) space}

{phang}
{cmd:. nrow2, prefix(gdp) destring compress}

{phang}
{cmd:. nrow2, prefix(gdp) onlynum}

{phang}
{cmd:. nrow2, prefix(gdp) onlynum space}

{phang}
{cmd:. nrow2, prefix(gdp) onlynum ignore(定)}

{phang}
{cmd:. nrow2, prefix(gdp) onlynum ignore(定-)}

{phang}
{cmd:. nrow2, prefix(gdp) onlynum ignore(定) trim}

{phang}
{cmd:. nrow2, prefix(gdp) onlynum ignore(定) space destring compress}


{title:(2) A Specific Example}

{p 4 8 2}. {stata clear}{p_end}
{p 4 8 2}. {stata input str6 var1 str8(var2 var3) str9 var4 str8(var5 var6 var7)}{p_end}
{p 4 8 2}. {stata `"""       "2018定"   "2019定"   "2020定"    "2021定"   "2022定"   "2023定""'}{p_end}
{p 4 8 2}. {stata `""Beijing"      "33106"    "35445.1"  "36102.6"   "41045.6"  "41610.9"  "43760.7""'}{p_end}
{p 4 8 2}. {stata `""Tianjin"      "13362.9"  "14055.5"  "14083.7"   "15695"    "16311.3"  "16737.30""'}{p_end}
{p 4 8 2}. {stata `""Hebei"        "32494.6"  "34978.6"  "36013.8"   "40397.1"  "42370.4"  "43944.1""'}{p_end}
{p 4 8 2}. {stata `""Shanxi"       "15958.1"  "16961.6"  "17835.6"   "22870.4"  "25642.6"  "25698.18""'}{p_end}
{p 4 8 2}. {stata `""Liaoning"     "23510.5"  "24855.3"  "25011.4"   "27569.5"  "28975.1"  "30209.4""'}{p_end}
{p 4 8 2}. {stata `""Jilin"        "11253.8"  "11726.8"  "12256"     "13235.5"  "13070.2"  "13531.19""'}{p_end}
{p 4 8 2}. {stata `""Heilongjiang" "12846.5"  "13544.4"  "13633.4"   "14858.2"  "15901"    "15883.9""'}{p_end}
{p 4 8 2}. {stata `""Shanghai"     "36011.82" "37987.55" "38963.2"   "43653.2"  "44652.8"  "47218.66""'}{p_end}
{p 4 8 2}. {stata `""Jiangsu"      "92595.4"  "98656.82" "102807.68" "116364.2" "122875.6" "128222.2""'}{p_end}
{p 4 8 2}. {stata `""Zhejiang"     "58003"    "62462"    "64689"     "74041"    "77715.36" "82553""'}{p_end}
{p 4 8 2}. {stata `""Anhui"        "34010.91" "36845.49" "38061.51"  "42565.2"  "45045"    "47050.6""'}{p_end}
{p 4 8 2}. {stata end}{p_end}

{p 4 8 2}. {stata nrow2 , ignore(定) prefix(gdp) onlynum destring}{p_end}


{title:Acknowledgements}
{p 4 14 2}Codes from {help nrow} by Alvaro Carril (acarril@fen.uchile.cl) have been incorporated.{p_end}


{title:Authors}

{phang}
{cmd:Dejin Xie}, School of Economics and Management, Nanchang University, China.{break}
 E-mail: {browse "mailto:xiedejin@ncu.edu.cn":xiedejin@ncu.edu.cn}. {break}


{title:Also see}

{p 4 14 2}Help: {helpb rename} ; {helpb nrow}, {helpb renvarlab}, {helpb lab2varn}, {helpb labvars} (if they are installed).{p_end}

