{smcl}


{title:Title}


{pstd}
{bf:number_exporting} - number_exporting formats a given numeric value (numeric_value) based on user specifications. It outputs the formatted number into a LaTeX compatible .tex file that can then called directly into the paper. 
The function can handle absolute values, percentages, and specific decimal formatting, making it suitable for saving numeric data for reports or publications in LaTeX format and automatized the description of regression coefficients in the main text of a paper.



{marker syntax}{...}
{title:Syntax}

{phang}
{cmd: number_exporting} {it:numeric_value} [{cmd:,} {help number_exporting##options:options}]
{p_end}

{marker description}{...}
{title:Description}

{pstd}
{bf:number_exporting} number_exporting formats a given numeric value (numeric_value) based on user specifications and outputs the formatted number into a LaTeX compatible .tex file.
{p_end}




{marker options}{...}
{title:Options}

{phang}{opt name(string)}: Specifies the name of the output .tex file (there is no need to add the extension). This is a required option and determines the file name of the output.
{p_end}

{phang}{opt percent}: If specified, the number is treated as a percentage. This means the number will be multiplied by 100 and formatted with a percentage sign at the end for the LaTex output.
{p_end}

{phang}{opt absolute}: If specified, the absolute value of 'numeric_value' is taken before formatting.
{p_end}

{phang}{opt digits(integer)}: Determines the number of decimal places in the formatted output. If not specified, the default is 2 decimal places.
{p_end}

{marker usage}{...}
{title:Usage Examples}

Assume that you estimate a regression of the form: Y = DiD 
and the output is: _b[DiD] = -0.04568

 {bf:1) Formatting a standard number without percentage or absolute transformations.} 
	Typing:
	{cmd:number_exporting `_b[DiD]', Name(example) digits(3)}
	Produces an output file `example.tex' with the content "-0.046"


  {bf:2) Formatting a number as a percentage with absolute value transformation.} 
	Typing:
        {cmd:number_exporting `_b[DiD]', Name(percentage) percent digits(1) absolute}
	Produces an output file `example.tex' with the content "5%"


{marker note}{...}
{title:Note}
All the output.tex files end with a ``%'' sign. This is because otherwise, inputting the .tex in a Latex document creates an extra space and include ``%'' at the end of the output.tex deals with this problem.

{marker author}{...}
{title:Authors}

{pstd}
Olena Bogdan (obogdan@g.harvard.edu), Adrien Matray (matray@stanford.edu), Pablo E. Rodriguez (pablo6@mit.edu), Chenzi Xu (chenzixu@berkeley.edu).

{title:Comments}

Send any suggestions or feedback to Pablo E. Rodriguez (pablo6@mit.edu).


