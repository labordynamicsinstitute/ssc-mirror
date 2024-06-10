{smcl}
{* 10may2024}{...}
{hi:help matstat}
{hline}

{p 1}{bf:{ul on}Title{ul off}}{p_end}

{p 6}{bf:matstat} {hline 2} {cmd:tabstat}, with assembling of results in one matrix


{p 1}{bf:{ul on}Syntax{ul off}}{p_end}

{p 6 15 2}
{cmd:matstat} {varlist} {ifin} {weight} , {opth stats(string)} {opth mat(string)}
   [ {help matstat##comopt:{it:options}} ]

{synoptset 21 tabbed}{...}
{marker comopt}{synopthdr:Options}
{synoptline}
{synopt :{opth stats(statnames)}}statistic(s) to be calculated for each variable; required
  {p_end}
{synopt :{opth mat(string)}}name for matrix to be constructed; required
  {p_end}
{synopt :{opth by(varname)}}stratifying variable
  {p_end}
{synopt :{opth layout(string)}}structure of matrix ("horizontal" vs. "vertical")
  {p_end}
{synopt :{opth total(string)}}treatment of Total 
  {p_end}
{synopt :{opt missing}}treatment of missing on "by()" variable 
  {p_end}
{synopt :{opt xpose}}transpose matrix
  {p_end}
{synopt :{opt names}}use value labels for stratifying variable
  {p_end}
{synopt :{opth tabshow(%fmt)}}display {cmd:tabstat} table, with format specified
  {p_end}
{synopt :{opth outfile(string)}}write out matrix to Excel file
  {p_end}


{p 1}{bf:{ul on}Description{ul off}}{p_end}

{pstd} {cmd:matstat} executes Stata procedure {cmd:tabstat} and then assembles results in one matrix - {cmd:tabstat}
table becomes {cmd:matstat} matrix.{p_end}

{pstd} Rationale:  {cmd:tabstat}, with the "save" option, saves the results in a set of {bf:r()} matrices, one
matrix for each category of the "by( )" variable.  {cmd:tabstat} denotes these matrices "r(Stat1)", 
"r(Stat2)", and so forth.  {cmd:matstat} constructs one matrix that combines these separate matrices.
The goal is to make results from {cmd:tabstat} available in convenient form for further use
(for example {cmd:putdocx}, {cmd:putexcel}, {cmd:estout}, or author's procedure {cmd:mswtable}).{p_end}

{pstd} Note that it is {ul:not} necessary to first execute {cmd:tabstat}.
{cmd:matstat} does this.{p_end}


{p 1}{bf:{ul on}Standard Features{ul off}}{p_end}

{phang} {it:varlist} are the variables for which {cmd:stats}() are to be
calculated.  Separate by space, adhering to usual {cmd:tabstat} syntax.  {it:varlist} is required.{p_end}

{phang} {it:if} specifies selection criteria (if any).

{phang} {it:weight} specifies weighting (if any).  {cmd:tabstat} supports {bf:aweight} and {bf:fweight}.{p_end}


{p 1}{bf:{ul on}Options{ul off}}{p_end}

{phang} {opth stats(statnames)} specifies the statistic(s) to be calculated for each variable in {it:varlist}.  
This can be any of the statistics available in {cmd:tabstat}.  
More than one statistic can be requested; if so, separate by space or comma, and see {cmd:layout}() below.
This option is required.{p_end}

{phang} {opth mat(string)} provides a name for the matrix to be constructed.  This option is required.{p_end}

{phang} {opth by(varname)} identifies stratifying variable.  
Standard Stata syntax for "by( )".{p_end}

{phang} {opth layout(string)} defines the structure of the matrix.
This is applicable only if {bf:stats}() requests more than one statistic.
One of two layouts can be chosen: "horizontal" (default) or "vertical".
See discussion below {ul:Matrix Structure}.{p_end}

{phang} {opth total(string)} determines the treatment of the Total vector.
"no" requests omission; default is inclusion.  "top" requests placement as
top row; default is bottom row.  Either, but not both, may be specified.{p_end}

{phang} {opt missing} requests inclusion of missing on {cmd:by}() variable as
separate category.  The default is to discard this set of observations.  {cmd:matstat}
labels this category "missing", and ordinarily it is placed at the bottom of the matrix.{p_end}

{phang} {opt xpose} transposes the matrix once it is assembled.{p_end}

{phang} {opt names} asks that the constructed matrix {cmd:mat}() use as row names the value labels
of the categories of the stratifying variable.  The total row is labeled "Total".{p_end}

{phang} {opth tabshow(%fmt)} asks for screen display of the {cmd:tabstat} table,
with the format of the cells specified within parentheses.  Default is no display.
This option does {ul:not} affect the format of the elements of the contructed matrix.{p_end}

{phang} {opth outfile(string)} requests that the matrix be saved as an Excel file.
Full file specification should be provided (exact directory + file name), and within quotes, but
no file extension ({cmd:matstat} imposes "xlsx").  {cmd:matstat} uses {cmd:putexcel} to accomplish this.
Row names and column names are preserved.
Matrix {cmd:mat}() remains available whether or not {cmd:outfile} is requested.{p_end}


{p 1}{bf:{ul on}Matrix Structure{ul off}}{p_end}

{phang} The simplest request is one variable in {it:varlist} and one statistic in {bf:stat}();
{cmd:matstat} will construct a one-column vector.
This can be transformed to one-row vector via option {bf:xpose}.{p_end}

{phang} If the request is one variable in {it:varlist} and two+ statistics in {bf:stat}(),
{cmd:matstat} will construct either a multi-column matrix or a one-column vector, depending
on whether specified {cmd:layout}() is "horizontal" (default) or "vertical", respectively.  (See below.){p_end}

{phang}If the request is two variables in {it:varlist} and one statistic in {bf:stat}(),
{cmd:matstat} will construct a two-column matrix.  A request for three variables will 
yield a three-column matrix.  And so forth.
Note that the same matrix for two+ variables and one statistic can be produced by executing {cmd:matstat}
successively for each variable and then combining the matrices via "column join"
(see "matrix basics" below).{p_end}

{phang} If {it:varlist} contains more than one variable and {bf:stats}() requests more than one statistic, 
the matter is more complicated.
{cmd:matstat} offers two structures via option {cmd:layout}(): "horizontal (default) and 
"vertical".  With the default placement of Total at the bottom, these layouts are as follows:{p_end}
{asis}


        Horizontal  (default)
        ----------
                                Variable1              Variable2
                           Stat1  Stat2  Stat3    Stat1  Stat2  Stat3
               Stratum1
               Stratum2
               Stratum3
                  Total


        Vertical
        --------
                                  Variable1   Variable2
               Stratum1  Stat1
                         Stat2
                         Stat3
               Stratum2  Stat1
                         Stat2
                         Stat3
               Stratum3  Stat1
                         Stat2
                         Stat3
                  Total  Stat1
                         Stat2
                         Stat3
{smcl}


{p 8 8} Note that two further layouts are easily obtained by transposing (option {bf:xpose}) either of the above two layouts:{p_end}
{asis}


        Horizontal, transposed
        ----------------------
                                   Stratum1   Stratum2   Stratum3   Total
               Variable1  Stat1
                          Stat2
                          Stat3
               Variable2  Stat1
                          Stat2
                          Stat3


        Vertical, transposed
        --------------------
                               Stratum1            Stratum2            Stratum3             Total
                          Stat1 Stat2 Stat3   Stat1 Stat2 Stat3   Stat1 Stat2 Stat3   Stat1 Stat2 Stat3  
               Variable1
               Variable2
{smcl}


{phang} Names under option {bf:names}:
{it:horizontal layout}: column names are an amalgam of the variable name and the statistic shorthand.
{it:vertical layout}: row names are an amalgam of the stratum name (value label) and the statistic shorthand.
These names often will be long and unwieldy, but they have the virtue of being precise and unambiguous.{p_end}


{p 1}{bf:{ul on}Examples{ul off}}{p_end}
{asis}

    matstat unwant n_unwant, stats(mean) by(Region) total(no) xpose mat(R)

    matstat unwant n_unwant  if v024==1  [aw=v005], stats(p50 n) by(Region) mat(A) names

    matstat unwant n_unwant, stats(mean,sd) by(Region) layout(vertical) total(top) mat(X) names tabshow(%4.2f)
{smcl}


{p 1}{bf:{ul on}Similar procedures{ul off}}{p_end}

{pstd} {cmd:statsmat} and {cmd:tabstatmat} are community-written procedures that offer some of the same functionality
as {cmd:matstat}.  However:{p_end}
{p 7 9} - while both can be employed to construct matrix with "horizontal" layout (this entails successive executions, 
then joining matrices), neither command can be wielded to produce matrix with "vertical" layout{p_end}
{p 7 9} - {cmd:statsmat} does not include Total category in the resulting matrix, and category value labels
are not fully preserved{p_end}


{p 1}{bf:{ul on}Some matrix basics{ul off}}{p_end}
{asis}    
     List existing matrices:  matrix dir

     Examine contents of matrix:  matrix list A

     Create 5x3 matrix with cell contents ".":  matrix A = J(5,3,.)

     Create matrix from results:  matrix A = r(table)

     Combine matrices side-by-side:  matrix C = A,B  ("column join")

     Stack matrices:  matrix D = A\B\C  ("row join")

     Transpose matrix:  matrix B = A'

     Extract sub-matrix:
        matrix B = A[2,1...]      2nd row, all columns
        matrix B = A[1...,3]      All rows, 3rd column
        matrix B = A[2...,2]      2nd to last row, 2nd column
        matrix B = A[3,3...]      3rd row, 3rd to last column
        matrix B = A[1..3,1...]   1st through 3rd row, all columns
        matrix B = A[2..4,1..3]   2nd through 4th row, 1st through 3rd column

     Sub-matrix substitution:
        matrix B[1,1] = A         Copy in matrix A, upper left corner at row 1 and column 1
        matrix B[2,3] = A         Copy in matrix A, upper left corner at row 2 and column 3


{smcl}
{p 1}{bf:{ul on}Author{ul off}}{p_end}

{pstd} John Casterline, Ohio State University, casterline.10@osu.edu

