{smcl}
{right:version:  1.1}
{hi:help for ras} {right:Dec. 22nd, 2021}
{hline}

{title:Title}

{p 4 2 2}{hi:ras}  -  Use RAS Method (Biproportional Scaling Method) to update input-output matrices.{p_end}

{title:Syntax}

{p 4 2 2}{cmd:ras} {it:{help varlist:varlist} }, {it:n(#)} [{it:options}]{p_end}

{p 6 12 2}{it:varlist}  - The varlist's data must be equal to matrix [A X U V] and have no missing-value. A is the base year's matrix of inter-industry input-output cofficients (the technical input coefficients matrix or input-output matrix, n*n), and it can be calculated from the matrix of internal demand (internal consumption) and total output. X is the updated year's total output, which is a column vector (n*1). U is column vector (n*1) which is equal to the row sums of the updated year's internal demand matrix. V is column vector (n*1) whose transpose is equal to the column sums of the updated year's internal demand matrix.{p_end}
{p 12 12 2}You can use "var*", "var1-var100", "var2 var3 var5-var98" to refer to a varlist in Stata. For more details, see {help varlist:varlist}.{p_end}

{p 6 12 2}{it:n(#)} - Number of iterations of RAS technology. A row iteration and a column iteration are considered a complete iteration. # must be an integer greater than 0. If you want only execute row iteration in the last iteration, please see option "half".{p_end}

{p 6 12 2}{it:options}{p_end}
{txt}{space 6}{hline}
{p 9 15 2}a{space 5}Generate several variables containing the upgrade year's expected inter-industry input-output cofficients matrix (the technical input coefficients matrix).{p_end}
{p 9 15 2}r{space 5}Generate several variables containing the matrix R of RAS method. R is a diagonal matrix.{p_end}
{p 9 15 2}s{space 5}Generate several variables containing the matrix S of RAS method. S is a diagonal matrix.{p_end}
{p 9 15 2}half{space 2}The last RAS iteration will be executed a half (only execute row iteration, only R). {p_end}

{p 6 6 2}(If you do not select any options of "a r s", the program will choose "a" by default.){p_end}

{p 6 6 2}(Expected internal demand matrix of the updated year Z=RZ{c 176}S. Z{c 176} is preliminary expected internal demand matrix of the updated year, which is calculated based on the base year's inter-industry input-output cofficients matrix A and the upgraded year's total output X, Z{c 176}=A*diag(X). The upgrade year's expected inter-industry input-output cofficients matrix is equal to Z multiplied by the inverse matrix of diag(X).){p_end}


{title:Description}

{p 4 2 2}{hi:Ras} module helps you use RAS Method (Biproportional Scaling Method) to update the input-output matrices.{p_end}

{title:RAS Method}

{p 4 2 2}RAS Method (Biproportional Scaling Method) is a method to update input-output matrices. Before using the RAS method, you need to calculate preliminary expected internal demand matrix of the updated year through the formula "A*diag(X)". A is the base year's matrix of inter-industry input-output cofficients and X is the updated year's total output. In one iteration RAS multiplies rows in a way that their totals would be the same as some desired row totals U and then it multiplies columns in a way that their totals would be the same as some desired column totals V. The multiplication of columns will lead to violation of row totals and vice versa so the multiple iterations must be performed. If the row and column totals are consistent, the results of RAS will converge to a matrix with row totals U and column totals X. {p_end}

{title:Example}

{p 4 2 2}Suppose a country has the following Input-Output Table (IOT) in the base year.{p_end}
{txt} {c TLC}{hline 12}{c TT}{hline 12}{hline 12}{hline 12}{hline 12}{hline 12}{col 76}{c TRC}
{txt} {c |}{col 3}{col 15}{c |} Industry 1{col 27} Industry 2{col 39} Industry 3{col 51}    Final{col 63}    output{col 76}{c |}
{txt} {c |}{col 15}{c |}{col 51} Expenditure{col 76}{c |}
{txt} {c LT}{hline 12}{c +}{hline 12}{hline 12}{hline 12}{hline 12}{hline 12}{col 76}{c RT}
{txt} {c |}{col 3}Industry 1{col 15}{c |}{space 2}1389.98{col 27}{space 2}6747.85{col 39}{space 2}621.37{col 51}{space 2}1946.43{col 63}{space 3}10705.64{col 76}{c |}
{txt} {c |}{col 3}Industry 2{col 15}{c |}{space 2}2565.57{col 27}{space 2}80134.15{col 39}{space 2}11773.03{col 51}{space 2}38863.81{col 63}{space 3}133336.56{col 76}{c |}
{txt} {c |}{col 3}Industry 3{col 15}{c |}{space 2}459.68{col 27}{space 2}18771.27{col 39}{space 2}17656.34{col 51}{space 2}27215.17{col 63}{space 3}64102.46{col 76}{c |}
{txt} {c |}{col 3}Value-added{col 15}{c |}{space 2}6290.41{col 27}{space 2}27683.29{col 39}{space 2}34051.71{col 76}{c |}
{txt} {c |}{col 3}output{col 15}{c |}{space 2}10705.64{col 27}{space 2}133336.56{col 39}{space 2}64102.46{col 76}{c |}
{txt} {c BLC}{hline 12}{c BT}{hline 12}{hline 12}{hline 12}{hline 12}{hline 12}{col 76}{c BRC}
{p 4 2 2}Its internal demand (internal consumption) matrix in the base year is{p_end}
{txt}{col 15}{c TLC}{col 50}{c TRC}
{txt}{col 15}{c |}{space 2}1389.98{col 27}{space 2}6747.85{col 39}{space 2}621.37{col 50}{c |}
{txt}{col 15}{c |}{space 2}2565.57{col 27}{space 2}80134.15{col 39}{space 2}11773.03{col 50}{c |}
{txt}{col 15}{c |}{space 2}459.68{col 27}{space 2}18771.27{col 39}{space 2}17656.34{col 50}{c |}
{txt}{col 15}{c BLC}{col 50}{c BRC}
{p 4 2 2} Then we can calculate the base year's inter-industry input-output cofficients matrix A{p_end}
{txt}{col 15}{c TLC}{col 50}{c TRC}
{txt}{col 15}{c |}{space 2}0.129836{col 27}{space 2}0.050608{col 39}{space 2}0.009693{col 50}{c |}
{txt}{col 15}{c |}{space 2}0.239646{col 27}{space 2}0.600992{col 39}{space 2}0.183660{col 50}{c |}
{txt}{col 15}{c |}{space 2}0.042938{col 27}{space 2}0.140781{col 39}{space 2}0.275439{col 50}{c |}
{txt}{col 15}{c BLC}{col 50}{c BRC}
{p 4 2 2}(Vector X) Suppose the total output in the upgrated year is{p_end}
{txt}{col 15}{c TLC}{col 29}{c TRC}
{txt}{col 15}{c |}{space 2}11012.40{col 29}{c |}
{txt}{col 15}{c |}{space 2}135535.31{col 29}{c |}
{txt}{col 15}{c |}{space 2}79225.64{col 29}{c |}
{txt}{col 15}{c BLC}{col 29}{c BRC}
{p 4 2 2}(Vector U) Suppose the sum of each department's products used for internal consumption in the upgrated year is{p_end}
{txt}{col 15}{c TLC}{col 29}{c TRC}
{txt}{col 15}{c |}{space 2}8506.69{col 29}{c |}
{txt}{col 15}{c |}{space 2}91331.67{col 29}{c |}
{txt}{col 15}{c |}{space 2}43613.43{col 29}{c |}
{txt}{col 15}{c BLC}{col 29}{c BRC}
{p 4 2 2}(Vector V') Suppose the sum of each department's internal consumption in the upgrated year is{p_end}
{txt}{col 15}{c TLC}{col 51}{c TRC}
{txt}{col 15}{c |}{space 2}4467.17{col 27}{space 2}102264.78{col 39}{space 2}36719.84{col 51}{c |}
{txt}{col 15}{c BLC}{col 51}{c BRC}
{p 4 2 2} Then you can get a series of variables as follows.{p_end}
{txt}{col 10}{space 4}var1{col 22}{space 4}var2{col 34}{space 4}var3{col 46}{space 4}var4{col 58}{space 4}var5{col 70}{space 4}var6{col 82}
{txt}{col 10}{space 2}0.129836{col 22}{space 2}0.050608{col 34}{space 2}0.009693{col 46}{space 2}11012.40{col 58}{space 2}8506.69{col 70}{space 2}4467.17{col 82}
{txt}{col 10}{space 2}0.239646{col 22}{space 2}0.600992{col 34}{space 2}0.183660{col 46}{space 2}135535.31{col 58}{space 2}91331.67{col 70}{space 2}102264.78{col 82}
{txt}{col 10}{space 2}0.042938{col 22}{space 2}0.140781{col 34}{space 2}0.275439{col 46}{space 2}79225.64{col 58}{space 2}43613.43{col 70}{space 2}36719.84{col 82}
{p 4 2 2} According to Syntax, the order of variables needs to meet the order "A X U V". {p_end}
{p 4 2 2} If we want to do two RAS iterations, we can execute the command "{it:{cmd:ras var1 var2 var var4 var5 var6, n(2) a r s}}" or the command "{it:{cmd:ras var1-var6, n(2) a r s}}".{p_end}
{p 4 2 2} The program will generate new variables _RAS_A*, _RAS_R*, _RAS_S* to store the matrix A, R, S.{p_end}
{p 4 2 2} And the screen will print some informations as follows.{p_end}
{p 10 10 2}Error & Error Rate:{p_end}
{txt}{col 11}6.809756{col 22}.0800517654318655%
{txt}{col 11}30.19754{col 22}.0330636007547902%
{txt}{col 11}-37.00827{col 22}-.084855220164759%
{p 10 10 2}Error (Max Abs.): -37.00827{p_end}
{p 10 10 2}Error_rate (Max Abs.): -.084855220164759%{p_end}
{p 4 4 2}Error is the difference between the row totals of the internal consumer matrix obtained after the last iteration and the row totals U we input. Error_rate is the ratio of Error to row totals U.{p_end}


{title:References}

{p 4 2 2}[1] Bacharach, Michael. Biproportional matrices and input-output change. Vol. 16. CUP Archive, 1970.{p_end}
{p 4 2 2}[2] Parikh, Ashok. "Forecasts of input-output matrices using the RAS method." The review of economics and statistics (1979): 477-481.{p_end}
{p 4 2 2}[3] V Holý, and K Šafr. "The Use of Multidimensional RAS Method in Input-Output Matrix Estimation." (2017).{p_end}
{p 4 2 2}[4] OECD: Input-Output Tables https://www.oecd.org/sti/ind/input-outputtables.htm{p_end}

{title:Author}

{p 4 2 2}Xia P.S.{p_end}
{p 4 2 2}University of Chinese Academy of Sciences{p_end}
{p 4 2 2}Email: xia_ps@yeah.net{p_end}