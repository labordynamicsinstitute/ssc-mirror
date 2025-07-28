{smcl}
{* 24Jul2025}{…}
{hline}
help for {hi:area} {right:(Wu LiangHai, Wu XinZhuo)}
{hline}

{title:Generating the regional dummy variable}

{p 8 12} {cmd:area} {it:varname}

{title:Description}

{p}{cmd:area} When you open a dataset，perhaps you want to generate the regional dummy variable based a variable of your current working dataset(such as province, one string variable)，and well you can use the {cmd:area} command. {p_end}

{title:Examples}

{p 8 12}{inp:.  use asure, clear}{p_end}
{p 8 12}{inp:.  area 省份} {p_end}
{p 8 12}{inp:.  area 省市} {p_end}
{p 8 12}{inp:.  area 省自治区直辖市} {p_end}
{p 8 12}{inp:.  area province} {p_end}


{title:References}

{p 0 4}{it:Hamilton Lawrence C}, 2009,
{browse  "http://www.stata.com/bookstore/sws.html":Statistics with Stata}.
Pacific Grove, CA： Duxbury.{p_end}

{p 0 4}{it:Christopher F Baum}, 2009, 2016 " An Introduction to Stata Programming "{p_end}

{p 0 4}{it:Chuanbo Chen }, "18 Speeches of STATA(Renmin University of China ) "{p_end}

{title:Author}

{p 0 4}Wu LiangHai, Wang LinXi, Hu Qiong, 2019. An Introduction to Positive Accounting. Department of Accounting, Business of School, Anhui University of Technology（AHUT）.{p_end}

{title:Also see}

{p 4 13 2}
Manual:  {hi:[R] onetext}

{p 4 13 2}
On-line:  help for {help onetext}
