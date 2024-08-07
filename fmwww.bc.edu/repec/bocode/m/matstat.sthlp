{smcl}
{* 3august2024}{...}
{hi:help matstat}
{hline}

{p 1}{bf:{ul on}Title{ul off}}{p_end}

{p 6}{bf:matstat} {hline 2} {cmd:tabstat}, with assembling of results in one matrix


{p 1}{bf:{ul on}Syntax{ul off}}{p_end}

{p 6 15 2}
{cmd:matstat} {varlist} {ifin} {weight} ,  {opth mat(string)} {opth stats(string)}
   [ {help matstat##comopt:{it:options}} ]

{synoptset 21 tabbed}{...}
{marker comopt}{synopthdr:Options}
{synoptline}
{synopt :{opth mat(string)}}name for matrix to be constructed; required
  {p_end}
{synopt :{opth stats(statnames)}}statistic(s) to be calculated for each variable in {varlist}; required
  {p_end}
{synopt :{opth dist(string)}}requests percentage distribution of "by()" variable
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
{synopt :{opth tabshow(%fmt)}}display {cmd:tabstat} table, with format specified
  {p_end}
{synopt :{opth outfile(string)}}write out matrix to Excel file
  {p_end}


{p 1}{bf:{ul on}Description{ul off}}{p_end}

{pstd} {cmd:matstat} executes Stata procedure {cmd:tabstat} and then assembles results in one matrix - {cmd:tabstat}
table becomes {cmd:matstat} matrix.  {it:note}: it is {ul:not} necessary to first execute {cmd:tabstat}, {cmd:matstat}
does this.{p_end}

{pstd} Rationale:  {cmd:tabstat}, with the "save" option, saves the results in a set of {bf:r()} matrices, one
matrix for each category of the "by( )" variable.  {cmd:tabstat} denotes these matrices "r(Stat1)", 
"r(Stat2)", and so forth.  {cmd:matstat} constructs one matrix that combines these separate matrices.
The goal is to make results from {cmd:tabstat} available in convenient form for further use
(for example {cmd:putdocx}, {cmd:putexcel}, {cmd:estout}, or author's procedure {cmd:mswtable}).{p_end}


{p 1}{bf:{ul on}Standard Features{ul off}}{p_end}

{phang} {varlist} are the variables for which {cmd:stats}() are to be
calculated.  Separate by space (usual {cmd:tabstat} syntax).  {varlist} is required.{p_end}

{phang} {ifin} specifies selection criteria (if any).

{phang} {weight} specifies weighting (if any).  {cmd:tabstat} supports {bf:aweight} and {bf:fweight}.{p_end}


{p 1}{bf:{ul on}Options{ul off}}{p_end}

{phang} {opth mat(string)} provides a name for the matrix to be constructed.  This option is required.{p_end}

{phang} {opth stats(statnames)} specifies the statistic(s) to be calculated for each variable in {varlist}.  
This can be any of the statistics available in {cmd:tabstat}.  
More than one statistic can be requested; if so, separate by space or comma, and see {cmd:layout}() below.
This option is required.{p_end}

{phang} {opth dist(string)} requests percentage distribution of {cmd:by}() variable, in addition to 
statistics requested in {cmd:stats}().  This is not available for all matrix structures; see discussion
below {ul:Percentage Distribution Vector}.  Options are "first" and "last", to place this vector left/top or 
right/bottom, respectively, depending on matrix orientation.{p_end}

{phang} {opth by(varname)} identifies stratifying variable.  
Standard Stata syntax for "by( )".{p_end}

{phang} {opth layout(string)} defines the structure of the matrix.
This is applicable only if {bf:stats}() requests more than one statistic.
Three layouts are available: "horizontal1" (default), "horizontal2", or "vertical".
See discussion below {ul:Matrix Structure}.{p_end}

{phang} {opth total(string)} determines the treatment of the Total vector.
"no" requests omission; default is inclusion.  "top" requests placement as
top row; default is bottom row.  Either, but not both, may be specified.{p_end}

{phang} {opt missing} requests inclusion of missing on {cmd:by}() variable as a
separate category.  The default is to discard this set of observations.  {cmd:matstat}
labels this category "missing", and ordinarily it is placed at the bottom of the matrix.{p_end}

{phang} {opt xpose} transposes the matrix once it is assembled.{p_end}

{phang} {opth tabshow(%fmt)} asks for screen display of the {cmd:tabstat} table,
with the format of the cells specified within parentheses.  (If {cmd:dist}() is 
requested, this tabulation too is displayed.){space 2}Default is no display.  This
option does {ul:not} affect the format of the elements of the contructed matrix.{p_end}

{phang} {opth outfile(string)} requests that the matrix be saved as an Excel file.
Provide full file specification (exact directory + file name), and within quotes, without
file extension ({cmd:matstat} imposes "xlsx").  {cmd:matstat} uses {cmd:putexcel} to accomplish this.
Row names and column names are preserved.
Matrix {cmd:mat}() remains available whether or not {cmd:outfile} is requested.{p_end}


{p 1}{bf:{ul on}Matrix Structure{ul off}}{p_end}

{phang} A {cmd:by}() variable is assumed under all scenarios below.{p_end}

{phang} Possible requests are as follows:{p_end}

{phang}{it:One variable in {varlist}, one statistic in {bf:stats}}(): {cmd:matstat} will construct
a one-column vector, with categories of the {cmd:by}() variable constituting the rows.{p_end}

{phang}{it:One variable in {varlist}, two+ statistics in {bf:stats}}(): {cmd:matstat} will construct
either a multi-column matrix or a one-column vector, depending on whether specified {cmd:layout}() is
"horizontal" (default) or "vertical", respectively.{p_end}

{phang}{it:Two variables in {varlist}, one statistic in {bf:stats}}(): {cmd:matstat} will construct
a two-column matrix.  Three variables in {varlist} will yield a three-column matrix.  And so
forth.  Option {bf:layout}() is not available; effectively the layout is "vertical".{p_end}

{phang}{it:Two+ variables in {varlist}, two+ statistics in {bf:stats}}(): the matter is more
complicated.  {cmd:matstat} offers three structures via option {cmd:layout}(): "horizontal1"
(default), "horizontal2", and "vertical".  With the default placement of Total at the bottom, 
these layouts are as follows:{p_end}
{asis}


        horizontal1  (default)
        -----------
                                Variable1              Variable2
                           Stat1  Stat2  Stat3    Stat1  Stat2  Stat3
               Stratum1
               Stratum2
               Stratum3
                  Total


        horizontal2  
        -----------
                                   Variable1                              Variable2
                        Stratum1  Stratum2  Stratum3  Total    Stratum1  Stratum2  Stratum3  Total
               Stat1
               Stat2
               Stat3


        vertical
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


{p 8 8} Note that three further layouts are easily obtained by transposing (option {bf:xpose}) 
the above layouts:{p_end}
{asis}


        horizontal1, transposed
        -----------------------
                                   Stratum1   Stratum2   Stratum3   Total
               Variable1  Stat1
                          Stat2
                          Stat3
               Variable2  Stat1
                          Stat2
                          Stat3


        horizontal2, transposed
        -----------------------
                                     Stat1   Stat2   Stat3
               Variable1  Stratum1
                          Stratum2
                          Stratum3
                             Total
               Variable2  Stratum1
                          Stratum2
                          Stratum3
                             Total


        vertical, transposed
        --------------------
                               Stratum1            Stratum2            Stratum3             Total
                          Stat1 Stat2 Stat3   Stat1 Stat2 Stat3   Stat1 Stat2 Stat3   Stat1 Stat2 Stat3  
               Variable1
               Variable2
{smcl}


{p 1}{bf:{ul on}Labeling of Matrix Rows/Columns{ul off}}{p_end}

{p 4 10} (i){space 3}{varlist} variables: variable names are used{p_end}
{p 4 10} (ii){space 2}{cmd:stats}(): statistic shorthands, as required by {cmd:tabstat}, are used{p_end}
{p 4 10} (iii){space 1}{cmd:by}() variable: value labels are carried over from {cmd:tabstat}; these
are the macros "r(Name1)", "r(Name2)", and so forth{p_end}
{p 4 10} (iv){space 2}{cmd:dist} vector is labeled simply "dist"{p_end}

{phang} Composite labels:{p_end}
{p 6 8} - {it:horizontal1}: column labels are an amalgam of the variable name and the statistic shorthand{p_end}
{p 6 8} - {it:horizontal2}: column labels are an amalgam of the variable name and the stratum label (value label){p_end}
{p 6 8} - {it:vertical}: row labels are an amalgam of the stratum label (value label) and the statistic shorthand{p_end}
{p 6 6} These labels often will be long and unwieldy, but they have the virtue of being precise and unambiguous.{p_end}

{p 6 6} {it:note}: Stata has a limit of 32 characters for value labels.  There's a risk of exceeding
this limit, specifically:{p_end}
{p 6 8} - column label under the {it:horizontal2} layout (variable name + stratum label){p_end}
{p 6 8} - row label under the {it:vertical} layout (stratum label + statistic shorthand){p_end}
{p 6 6} {cmd:matstat} checks whether these labels are too long and, if so, truncates the stratum label.{p_end}


{p 1}{bf:{ul on}Percentage Distribution Vector{ul off}}{p_end}

{pstd} This vector is {ul on}not{ul off} available with "vertical" layout.{p_end}

{pstd} More specifically, {bf:dist}() adds vectors as follows:{p_end}
{p 6 8} - {it:One variable in {varlist}, one statistic in {bf:stats}}(): additional column{p_end}
{p 6 8} - {it:One variable in {varlist}, two+ statistic in {bf:stats}}(): additional column
("horizontal1") or additional row ("horizontal2"){p_end}
{p 6 8} - {it:Two+ variables in {varlist}, one statistic in {bf:stats}}(): additional column{p_end}
{p 6 8} - {it:Two+ variables in {varlist}, two+ statistics in {bf:stats}}(): additional column (layout
{ul:must} be "horizontal1"){p_end}


{p 1}{bf:{ul on}Examples{ul off}}{p_end}
{asis}

    matstat tfr unwant, stats(mean) by(Region) total(no) xpose mat(R)

    matstat tfr unwant  if v024==1  [aw=v005], stats(p50 n) by(Region) mat(A)

    matstat tfr unwant, stats(mean,sd) by(Region) layout(vertical) total(top) mat(X) tabshow(%4.2f)

    matstat tfr unwant, stats(mean) by(Region) dist(last) mat(X) tabshow(%4.2f)
{smcl}


{p 1}{bf:{ul on}Similar procedures{ul off}}{p_end}

{pstd} {cmd:statsmat} and {cmd:tabstatmat} are community-written procedures that offer some 
of {cmd:matstat}'s functionality.  However:{p_end}
{p 6 8} - while both can be employed to construct matrix with either "horizontal" layout (this 
entails successive executions, then joining matrices), neither command can be wielded to produce
matrix with "vertical" layout{p_end}
{p 6 8} - {cmd:statsmat} does not include Total category in the resulting matrix, and category labels
are not fully preserved{p_end}
{p 6 8} - neither offers the equivalent of {cmd:dist} option{p_end}


{p 1}{bf:{ul on}Some matrix basics{ul off}}{p_end}
{asis}    
     List existing matrices:  matrix dir

     Examine contents of matrix:  matrix list A

     Create 5x3 matrix with cell contents ".":  matrix A = J(5,3,.)

     Create matrix from results:  matrix A = r(table)

     Combine matrices side-by-side:  matrix C = A,B  ("column join")

     Stack matrices:  matrix D = A \ B \ C  ("row join")

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

