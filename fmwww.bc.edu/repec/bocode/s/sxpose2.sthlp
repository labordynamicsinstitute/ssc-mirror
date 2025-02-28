{smcl}
{* *! version 1.1.0 26feb2025}{...}
{vieweralsosee "[D] xpose" "mansection D xpose"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[D] reshape" "help reshape"}{...}
{vieweralsosee "[D] stack" "help stack"}{...}
{viewerjumpto "Syntax" "sxpose2##syntax"}{...}
{viewerjumpto "Description" "sxpose2##description"}{...}
{viewerjumpto "Options" "xpose##options"}{...}
{viewerjumpto "Examples" "xpose##examples"}{...}
{p2colset 1 14 16 2}{...}

{p2col:{bf: sxpose2} {hline 2}}Transpose of String (and Numeric) Variable Dataset {p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 14 2}{cmd:sxpose2, clear} [{it:options}]

{synoptset 15 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent :* {opt clear}}reminder that untransposed data will be lost if not previously saved{p_end}
{synopt :{opt de:string}}tries to destring variables after the transpose has happened{p_end}
{synopt :{opt first:names}}uses the values of the first variable to name the transposed variables{p_end}
{synopt :{opt force}}allows  to transpose numeric variables{p_end}
{synopt :{opth f:ormat(%fmt)}}apply specified format to all variables in the transposed data{p_end}
{synopt :{opt varl:abel}}add variable {opt _varlabel} containing original variable label{p_end}
{synopt :{opt varn:ame}}add variable {opt _varname} containing original variable names{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
* {cmd:clear} is required.
{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:sxpose2} transposes the data, converting variables into observations and observations into variables. 
In contrast to the implemented command {cmd:xpose}, it also allows string variables to be transposed. 
It is built upon the well-received user-written command {cmd:sxpose} and adds the ability to retain variable names and/or variable labels.

{title:Remarks}

{phang}
{cmd:sxpose2} has the same functionality as {cmd:xpose} and {cmd:sxpose}, with added capabilities. 
It can retain variable names like {cmd:xpose}, 
transpose both string and numeric variables like {cmd:sxpose}, 
and does not drop integer values like {cmd:sxpose} when the values of the first variable of the existing dataset are taken as the new variable names of the transposed dataset, 
i.e., when both the {opt first:names} and {opt force} options are specified.

{marker options}{...}
{title:Options}

{phang}
{opt clear} is required, reminding you that untransposed data will be lost (unless you have saved the data previously).

{phang}
{opt de:string} specifies that {cmd:destring, replace} will be run on the new dataset to attempt to convert variables that are unambiguously numeric in content to numeric. No force will be applied. See help on {help destring}.

{phang}
{opt first:names} specifies that the values of the first variable of the existing dataset should appear as the new variable names of the transposed dataset. 
If the values are integers, a leading underscore will be added to the variable name. 
Other non-conforming variable names will be replaced by a numbered placeholder.

{phang}
{opt force} is required when the dataset contains numeric variables. 
Numeric values will be saved as strings using the format %12.0g by default. 
Other formats can be specified using the format() option. 
Please be aware that you may lose precision using this option. The {cmd:xpose} command allows transposition of a numeric dataset with higher precision.

{phang}
{opt f:ormat} specifies a numeric format to use in coercing numeric values to string. See the force option.

{phang}
{opt varn:ame} adds the new variable {cmd:_varname} to the transposed data containing the original variable names.

{phang}
{opt varl:abel} adds the new variable {cmd:_varlabel} to the transposed data containing the original variable labels.

{marker examples}{...}
{title:Examples}

    Setup data

{col 10}{inp:{stata clear all}}
{col 10}{inp:{stata set obs 3}}
{col 10}{inp:{stata generate v_a = "a" in 1}}
{col 10}{inp:{stata replace v_a = "2.1" in 2}}
{col 10}{inp:{stata replace v_a = "33" in 3}}
{col 10}{inp:{stata generate v_b = 4 in 1}}
{col 10}{inp:{stata replace v_b = 5 in 2}}
{col 10}{inp:{stata replace v_b = 6 in 3}}
{col 10}{inp:{stata generate v_c = "c_1" in 1}}
{col 10}{inp:{stata replace v_c = "c_2" in 2}}
{col 10}{inp:{stata replace v_c = "9" in 3}}
{col 10}{inp:{stata label var v_b "Label of v_b"}}
{col 10}{inp:{stata label var v_c "Label of v_c"}}
{col 10}{inp:{stata list}}
             +-----------------+
             | v_a   v_b   v_c |
             |-----------------|
          1. |   a     4   c_1 |
          2. | 2.1     5   c_2 |
          3. |  33     6     9 |
             +-----------------+

    Transpose 

{col 10}{inp:{stata sxpose2, clear force}}
{col 10}{inp:{stata list}}
             +-----------------------+
             | _var1   _var2   _var3 |
             |-----------------------|
          1. |     a     2.1      33 |
          2. |     4       5       6 |
          3. |   c_1     c_2       9 |
             +-----------------------+


    Transpose using the same data and all options
    
{col 10}{inp:{stata sxpose2, clear force varname varlabel firstnames destring}}
{col 10}{inp:{stata list}}
	     +---------------------------------------------+
	     | _varname      _varlabel     a   _var2   _33 |
	     |---------------------------------------------|
	  1. |      v_b   Label of v_b     4       5     6 |
	  2. |      v_c   Label of v_c   c_1     c_2     9 |
	     +---------------------------------------------+


{title:Acknowledgements} 

{pstd}Nicholas J. Cox who wrote {cmd:sxpose}. See: {rnethelp "http://fmwww.bc.edu/RePEc/bocode/s/sxpose.hlp"}

{title:Author} 

{p 4 4 6}Stephan Huber{p_end}
{p 4 4 6}stephan.huber@hs-fresenius.de {p_end}

{title:Also see}

{psee}
Online: help for {help xpose} 
{p_end}
