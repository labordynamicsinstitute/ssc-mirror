{smcl}
{* version 1.0.2 14nov2010}
{cmd:help lookfor_val}
{hline}

{title:Title}

{p 5}
{cmd:lookfor_val} {hline 2} Search for value patterns in current data set

{title:Syntax}

{p 8}
{cmd:lookfor_val} [{varlist}] [{cmd:,}{it:options}]

{synoptset 21 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt p:attern(pattern)}}specify value pattern to be searched for{p_end}
{synopt:{opt val:ues}}display and save values that match {it:pattern}; default is to 
display and save variable names{p_end}
{synopt:{opt num:eric}}only search in numeric variables{p_end}
{synopt:{opt str:ing}}only search in string variables{p_end}
{synopt:{opt inse:nsitive}}perform case-insensitive search{p_end}
{synopt:{opt miss:ing}}treat missing values as valid{p_end}
{synopt:{opt d:escribe}}{help describe} variables if variables match the specified 
{it:pattern}{p_end}
{synopt:{opt ta:bulate}}{help tabulate} variables if variables match the specified 
{it:pattern}{p_end}
{synopt:{opt l:ist}}{help list} variables if variables match the specified 
{it:pattern}{p_end}
{synopt:{opt nop:rint}}do not display list(s){p_end}
{synopt:{opt sep:arate(sep)}}use {it:sep} as separator in returned list(S){p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:lookfor_val} searches the current data set for values that match a specified 
{it:pattern}. Variable names are displayed and stored in {hi:r(varlist)} if any value of a 
variable matches the {it:pattern} specified. Numeric and string variables are searched. If 
{varlist} is not specified it defaults to {hi:_all}.

{pstd}
{hi:Caution:} the program loops over every single level of every variable specified. This 
process may take a long time if your data set is large.

{title:Options}

{dlgtab:Options}

{phang}
{opt pattern(pattern)} specifies the value pattern to be searched for. Wildcards like 
{hi:"*"} and {hi:"?"} may be used, where the former means zero or more characters and the 
latter means exactly one character. If not specified, {it:pattern} defaults to {hi:*}, 
meaning that all variables specified in {it:varlist} will be listet. If {opt values} is 
specified all non-missing values of every variable in {it:varlist} will be listet.

{phang}
{opt values} displays the values of every variable in {it:varlist} that match the specified 
{it:pattern}. The values are returned in {hi:r(}{it:values_varname}{hi:)}. If specified 
{cmd:lookfor_val} does neither display nor save a list of variable names.

{phang}
{opt numeric} specifies that only numeric variables will be searched. If {opt pattern()} 
is not specified, only numeric variables will be listet.

{phang}
{opt string} specifies that only string variables will be searched. If {opt pattern()} 
is not specified, only string variables will be listet.

{phang}
{opt insensitive} performs case-insensitve search. This option will only affect the search 
performed in string variables of course.

{phang}
{opt missing} treats missing values as valid. Specifiy {opt missing} if you wish to search 
for missing values (i.e. {hi:.},{hi: .a},{hi: .b}, ...,{hi: .z} or {hi:""}) in variables. 
If {opt missing} is specified without the {opt pattern()} option, {it:pattern} will be set 
to {hi:""} (or {hi:.} if {opt numeric} is also specified).

{phang}
{opt describe} describe variables if variables match the specified {it:pattern}. This 
option may not be used with {opt values}.

{phang}
{opt tabulate} tabulates variables if variables match the specified {it:pattern}. This 
option implies the {opt values} option and values will be returned in 
{hi:r(}{it:values_varname}{hi:)} but will not be displayed.

{phang}
{opt list} lists variables if variables match the specified {it:pattern}. This option 
implies the {opt values} option and values will be returned in 
{hi:r(}{it:values_varname}{hi:)} but will not be displayed.

{phang}
{opt noprint} does not display the list(s) returned in {hi:r()}. 

{phang}
{opt separate(sep)} uses {it:sep} as separator between elements in the returned list(s). 
The default is {hi:" "}. If {help inlist} is to be used with the lists, specify 
{opt separate(,)}. 

{title:Example}

	. sysuse auto ,clear
	(1978 Automobile Data)

	{cmd:. lookfor_val ,pattern(*v*)}
	make

	{cmd:. lookfor_val make ,pattern(*v*) values insensitive tabulate}

	-> tabulation of make if make has value pattern *v*

	    Make and Model |      Freq.     Percent        Cum.
	-------------------+-----------------------------------
	     Buick Riviera |          1        5.56        5.56
	      Cad. Deville |          1        5.56       11.11
	      Cad. Seville |          1        5.56       16.67
	    Chev. Chevette |          1        5.56       22.22
	      Chev. Impala |          1        5.56       27.78
	      Chev. Malibu |          1        5.56       33.33
	 Chev. Monte Carlo |          1        5.56       38.89
	       Chev. Monza |          1        5.56       44.44
	        Chev. Nova |          1        5.56       50.00
	       Honda Civic |          1        5.56       55.56
	      Linc. Mark V |          1        5.56       61.11
	  Linc. Versailles |          1        5.56       66.67
	      Plym. Volare |          1        5.56       72.22
	         VW Dasher |          1        5.56       77.78
	         VW Diesel |          1        5.56       83.33
	         VW Rabbit |          1        5.56       88.89
	       VW Scirocco |          1        5.56       94.44
	         Volvo 260 |          1        5.56      100.00
	-------------------+-----------------------------------
	             Total |         18      100.00
	
	Please note that the {opt values} option may be omitted, since 
	it is implied by {opt tabulate}. 


	{cmd:. lookfor_val ,pattern(199*) values noprint}

	. return list

	macros:
	      r(values_length) : "199"
	      r(values_weight) : "1990"
 
{title:Saved results}

{pstd}
{cmd:lookfor_val} saves one of the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{synopt:{cmd:r(varlist)}}list of variables with specified value pattern{p_end}
{synopt:{cmd:r(values_varname)}}values in varname that match {it:pattern} 
(option {opt values})

{title:Author}

{pstd}Daniel Klein, University of Bamberg, daniel1.klein@gmx.de

{title:Also see}

{psee}
Online: {helpb ds}, {helpb lookfor}{p_end}
{psee}
if installed: {help lookfor_all}{p_end}

