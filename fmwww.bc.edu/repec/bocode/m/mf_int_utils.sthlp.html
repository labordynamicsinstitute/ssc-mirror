{smcl}
{* 8aug2014}{...}
{cmd:help int_utils}
{hline}

{title:Title}

{p 4 4 2}
{bf:int_utils -- Tools for interval analysis and computation}

{title:Contents}

{col 5}{bf:help entry{col 41}Purpose}
{col 5}{hline}

{col 5}   {c TLC}{hline 27}{c TRC}
{col 5}{hline 3}{c RT}{it: Basic arithmetic functions}{c LT}{hline}
{col 5}   {c BLC}{hline 27}{c BRC}

{col 5}{bf:{help int_utils##int_add:int_add()}{col 41} Add intervals}{...}


{col 5}{bf:{help int_utils##int_sub:int_sub()}{col 41} Subtract intervals}{...}


{col 5}{bf:{help int_utils##int_mult:int_mult()}{col 41} Multiply intervals}{...}


{col 5}{bf:{help int_utils##int_pow:int_pow()}{col 41} Raise intervals to a power}{...}


{col 5}   {c TLC}{hline 30}{c TRC}
{col 5}{hline 3}{c RT}{it: Expanded arithmetic functions}{c LT}{hline}
{col 5}   {c BLC}{hline 30}{c BRC}

{col 5}{bf:{help int_utils##int_matmult:int_matmult()}{col 41} Multiply interval matrices}{...}


{col 5}{bf:{help int_utils##int_rowmult:int_rowmult()}{col 41} Multiply rows of intervals}{...}


{col 5}{bf:{help int_utils##int_rowadd:int_rowadd()}{col 41} Add rows of intervals}{...}


{col 5}{bf:{help int_utils##int_transpose:int_transpose()}{col 41} Transpose an interval matrix}{...}


{col 5}   {c TLC}{hline 46}{c TRC}
{col 5}{hline 3}{c RT}{it: Expanded arithmetic row-form matrix functions}{c LT}{hline}
{col 5}   {c BLC}{hline 46}{c BRC}

{col 5}{bf:{help int_utils##int_rowmatmult:int_rowmatmult()}{col 41} Multiply interval matrices listed as rows}{...}


{col 5}{bf:{help int_utils##int_rowmatvecmult:int_rowmatvecmult()}{col 41} Multiply interval matrices listed as rows with interval (row) vector}{...}


{col 5}{bf:{help int_utils##int_rowtranspose:int_rowtranspose()}{col 41} Transpose interval matrix listed as a row}{...}


{col 5}   {c TLC}{hline 24}{c TRC}
{col 5}{hline 3}{c RT}{it: Interval set operations}{c LT}{hline}
{col 5}   {c BLC}{hline 24}{c BRC}

{col 5}{bf:{help int_utils##int_int:int_int()}{col 41} Intersection of intervals}{...}


{col 5}{bf:{help int_utils##int_rowint:int_rowint()}{col 41} Rowwise intersection of intervals}{...}


{col 5}{bf:{help int_utils##int_hun:int_hun()}{col 41} Interval hull}{...}


{col 5}{bf:{help int_utils##int_rowhull:int_rowhull()}{col 41} Columnwise interval hull}{...}


{col 5}{bf:{help int_utils##int_collect:int_collect()}{col 41} Collect intervals}{...}


{col 5}   {c TLC}{hline 27}{c TRC}
{col 5}{hline 3}{c RT}{it: Various interval utilities}{c LT}{hline}
{col 5}   {c BLC}{hline 27}{c BRC}

{col 5}{bf:{help int_utils##int_mid:int_mid()}{col 41} Interval midpoint (returned as interval)}{...}


{col 5}{bf:{help int_utils##mid:mid()}{col 41} Interval midpoint (scalar)}{...}


{col 5}{bf:{help int_utils##int_mince:int_mince()}{col 41} Divide intervals into smaller intervals}{...}


{col 5}{bf:{help int_utils##int_mesh:int_mesh()}{col 41} Make a series of intervals covering a region}{...}


{col 5}{bf:{help int_utils##int_widths:int_widths()}{col 41} Compute interval widths}{...}


{col 5}{bf:{help int_utils##radius:radius()}{col 41} Radii of intervals}{...}


{col 5}{bf:{help int_utils##r_up:r_up()}{col 41} Round interval upwards}{...}


{col 5}{bf:{help int_utils##r_down:r_down()}{col 41} Round interval downwards}{...}


{title:Description}

{p 4 4 2}
The functions above provide a means of doing interval computations, along these lines described in texts such as  Jaulin et. al. (2001) or
Moore et. al. (2009). Interval computations bear much resemblance to computations using convex sets. 
The idea is to develop sums, products, differences, etc. that concatenate the possibilities of two intervals. As examples, consider
the intervals [1,3] and [4,6]. The convenience is that often set computations can be performed by manipulating the 
upper and lower bounds of the sets.{p_end}

{p 4 4 2}
Another salient feature of interval arithmetic is the use of outward rounding; lower bounds are rounded down, while
upper bounds are rounded up. This convention allows the user to retain
control over numerical features of the problem, and also ensures that intervals are not inadvertently shrunk in the course
of computation by numerical problems. The examples in {help int_utils##int_add:int_add()} presents an example as to how this works.

With a slight abuse of notation, consider:

{col 5}Interval Addition:{col 41}[1,3]+[4,6]=[5,9]{...}

{col 5}Interval Subtraction:{col 41}[1,3]-[4,6]=[-3,-1]{...}

{col 5}Interval Multiplication:{col 41}[1,3]*[4,6]=[4,18]

{p 4 4 2}
For examples as to how the above operations work, see the individual help entries. The above-mentioned citations describe in detail
how interval operations work in more complex cases. Unlike most packages that do interval computations, the above functions do not
rely on description of an "interval class" but instead simply rely on standard mata matrices (for examples, see the individual help
entries). 

{title: Detailed descriptions of operations}

{col 5}{hline}
{marker int_add}
{bf:int_add() -- Addition of intervals for interval computations}

{title:Syntax}

{p 11 18 2}
{it:real matrix} {cmd:int_add(}{it:real matrix X, real matrix Y [, real scalar digits]})

{p 4 4 2}
where

{p 12 18 2}
  {it:X}:  {it:real matrix} containing data (each pair of rows {it:i,i+1} of which represent intervals)
  {p_end}
{p 12 18 2}
  {it:Y}:  {it:real matrix} containing data (each pair of rows {it:i,i+1} of which represent intervals)
  {p_end}
  
{pstd}
where

{p 12 18 2}
{it:digits}:  {it:real scalar} containing desired rounding. Default is {it:1e-8}.

{title:Description}

{pstd}
{cmd:int_add()} computes interval sums of vectors or matrices. Rows of the input matrices {it: X,Y} are treated as usual, while
each {it: pair} of columns are treated as intervals. Thus, an N-by-1 interval (row) vector should be represented in mata as an N-by-2 matrix,
with lower limits appearing in the first column and upper limits appearing in the second column.
An interval r-by-(2c) matrix would have lower limits in columns 1,3,5, etc. and upper limits appearing in columns 2,4,6, etc. 

{pstd}
Conceptually, interval addition is described by  adding all possible members of two interval sets together, creating another 
interval. For example, adding the 
two intervals [-1,5] and [2,4] gives the result [1,9]. {cmd:int_add()} can perform addition of any conformable matrices. 

{title: Options}

{pstd}
The option {it: digits} specifies the minimal roundoff error used in interval computations. In effect, this sets the size of the
smallest interval recognizable by the interval addition operation and is necessary for so as not to get misleading results in the
course of interval computations.  The second example below shows how {cmd: int_add()} automatically rounds lower limits down
and upper limits up according to {it: digits}. See {help int_utils##r_up:r_up()} or {help int_utils##r_down:r_down()} for further details concerning rounding.

{title: Remarks}

{pstd}
{cmd: int_add()} does not check if it is in fact true that the lower limits of intervals are less than or equal to upper limits; hence, 
users must exert care that this is in fact the case. 

{pstd}Examples:

Consider the addition of two interval vectors: 

{com}. mata: X=(-1,1) \ (2,4)
{com}. mata: Y=(2,3) \ (4,5) 
{com}. mata: int_add(X,Y)
{res}           {txt}   1   2     
            {c TLC}{hline 7}{c TRC}
          1 {c |}{res} 1   4 {c    |}
          2 {c |}{res} 6   9 {c    |}
            {c BLC}{hline 7}{c BRC}
{txt}

{pstd}
An example featuring outward rounding:
{p_end}

{com}. mata: X=(-.123456799,-.123456798) 
{com}. mata: Y=(0,0) 
{com}. mata: int_add(X,Y)
{res}           {txt}           1           2     
            {c TLC}{hline 23}{c TRC}
          1 {c |}{res} -.1234568   -.1234567 {c    |}
            {c BLC}{hline 23}{c BRC}
{txt}
{com}. mata: int_add(X,Y,1e-10)
{res}           {txt}             1             2     
            {c TLC}{hline 27}{c TRC}
          1 {c |}{res} -.123456799   -.123456798 {c    |}
            {c BLC}{hline 27}{c BRC}
{txt}
			
{title:Conformability}

{pstd}
{it:X} and {it:Y} must be conformable (i. e., vectors of the same length). Moreover, lower limits (entries in odd columns) should be 
less than upper limits (entries in even columns). Some care must be exercised in assuring this, as {cmd: int_add()} does not check
whether or not it is true.
{p_end}

{col 5}{hline}
{marker int_sub}
{bf:int_sub() -- Subtraction of intervals for interval computations}


{title:Syntax}

{p 11 18 2}
{it:real matrix} {cmd:int_sub(}{it:real matrix X, real matrix Y [, real scalar digits]})

{p 4 4 2}
where

{p 12 18 2}
  {it:X}:  {it:real matrix} containing data (each pair of rows {it:i,i+1} of which represent intervals)
  {p_end}
{p 12 18 2}
  {it:Y}:  {it:real matrix} containing data (each pair of rows {it:i,i+1} of which represent intervals)
  {p_end}
  
{pstd}
where

{p 14 18 2}
{it:digits}:  {it:real scalar} containing desired rounding. Default is {it:1e-8}.

{title:Description}

{pstd}
{cmd:int_sub()} computes interval sums of vectors or matrices. Rows of the input matrices {it: X,Y} are treated as they 
usually are with vectors, while
each {it: pair} of columns are treated as intervals. Thus, an N-by-1 interval (row) vector should be stored in mata as an N-by-2 matrix,
with lower limits appearing in the first column and upper limits appearing in the second column. {cmd: int_sub()} subtracts the
interval matrix {it: Y} from the interval matrix {it: X}, or perhaps more correctly, the interval matrix represented by {it: Y} is 
subtracted from the interval matrix represented by {it: X}.

{pstd}
Roughly speaking, interval subtraction can be viewed as the result of collecting all possible results when one interval is
subtracted from another. For example, subtracting the 
interval [-1,5] from the interval [2,4] gives the result [-3,5]. {cmd:int_sub()} can perform subtraction of any conformable 
interval matrices. 

{title: Options}

{pstd}
The option {it: digits} specifies the minimal roundoff error used in interval computations. In effect, this sets the size of the
smallest interval recognizable by the interval addition operation and is necessary so as not to get misleading results in the
course of interval computations.  The second example below shows how {cmd: int_sub()} automatically rounds lower limits down
and upper limits up according to {it: digits}. See {help int_utils##r_up:r_up()} or {help int_utils##r_down:r_down()} for further details concerning rounding.

{title: Remarks}

{pstd}
{cmd: int_sub()} does not check if it is in fact true that the lower limits of intervals are less than or equal to upper limits; hence, 
users must exert care that this is in fact the case. 

{pstd}Examples:

Consider the sets of (interval) vectors: 

{com}. mata: X=(-1,1) \ (2,4)
{com}. mata: Y=(2,3) \ (4,5) 
{com}. mata: int_sub(X,Y)
{res}           {txt}    1    2     
            {c TLC}{hline 9}{c TRC}
          1 {c |}{res} -4   -1 {c    |}
          2 {c |}{res} -3    0 {c    |}
            {c BLC}{hline 9}{c BRC}
{txt}

{com}. mata: X=(-.123456799,-.123456798) 
{com}. mata: Y=(0,0) 
{com}. mata: int_sub(X,Y)
{res}           {txt}           1           2     
            {c TLC}{hline 23}{c TRC}
          1 {c |}{res} -.1234568   -.1234567 {c    |}
            {c BLC}{hline 23}{c BRC}
{txt}
{com}. mata: int_sub(X,Y,1e-10)
{res}           {txt}             1             2     
            {c TLC}{hline 27}{c TRC}
          1 {c |}{res} -.123456799   -.123456798 {c    |}
            {c BLC}{hline 27}{c BRC}
{txt}


			
{title:Conformability}

{pstd}
{it:X} and {it:Y} must be conformable (i. e., matrices of the same dimension). Lower limits (entries in odd columns) should be 
less than upper limits (entries in even columns); once again, this is not checked by {cmd: int_sub()} (or any 
other command in {bf:int_utils}.   
{p_end}

{hline}
{marker int_mult}
{bf:int_mult() -- Multiplication of intervals for interval computations}


{title:Syntax}

{p 11 18 2}
{it:real matrix} {cmd:int_mult(}{it:real matrix X, real matrix Y [, real scalar digits]})

{p 4 4 2}
where

{p 12 18 2}
  {it:X}:  {it:real matrix} containing data (each pair of rows {it:i,i+1} of which represent intervals)
  {p_end}
{p 12 18 2}
  {it:Y}:  {it:real matrix} containing data (each pair of rows {it:i,i+1} of which represent intervals)
  {p_end}
  
{pstd}
where

{p 14 18 2}
{it:digits}:  {it:real scalar} containing desired rounding. Default is {it:1e-8}.

{title:Description}

{pstd}
{cmd:int_mult()} computes term-by-term interval products of interval vectors (that is, it works like the ":*" operator). Rows of the input matrices {it: X,Y} are treated as usual, while
the two columns are treated as lower and upper bounds of intervals. Thus, an N-by-1 interval (row) vector should be written as an N-by-2 matrix,
with lower limits appearing in the first column and upper limits appearing in the second column. {cmd: int_mult()} multiplies the
interval vector {it: Y} wiht the interval matrix {it: X}. The computed product is element-by-element.

{pstd}
Roughly speaking, interval multiplication is described by concatinating all possible ways of multiplying one interval
by another. For example, multiplying the 
interval [-1,5] with the interval [2,4] gives the result [-4,20].

{title: Options}

{pstd}
The option {it: digits} specifies the minimal roundoff error used in interval computations. In effect, this sets the size of the
smallest interval recognizable by the interval addition operation and is necessary for so as not to get misleading results in the
course of interval computations.  The second example below shows how {cmd:int_mult()} automatically rounds lower limits down
and upper limits up according to {it: digits}. See {help int_utils##r_up:r_up()} or {help int_utils##r_down:r_down()} for further details concerning rounding.

{title: Remarks}

{pstd}
{cmd:int_mult()} does not check if it is in fact true that the lower limits of intervals are less than or equal to upper limits; hence, 
users must exert care that this is in fact the case. 

{pstd}Examples:

Consider the sets of (interval) vectors: 

{com}. mata: X=(-1,1) \ (2,4)
{com}. mata: Y=(2,3) \ (4,5) 
{com}. mata: int_mult(X,Y)
{res}           {txt}    1   2     
            {c TLC}{hline 8}{c TRC}
          1 {c |}{res} -3   3 {c    |}
          2 {c |}{res} -3  20 {c    |}
            {c BLC}{hline 8}{c BRC}
{txt}

{com}. mata: X=(-.123456799,-.123456798) 
{com}. mata: Y=(1,1) 
{com}. mata: int_mult(X,Y)
{res}           {txt}           1           2     
            {c TLC}{hline 23}{c TRC}
          1 {c |}{res} -.1234568   -.1234567 {c    |}
            {c BLC}{hline 23}{c BRC}
{txt}
{com}. mata: int_mult(X,Y,1e-10)
{res}           {txt}             1             2     
            {c TLC}{hline 27}{c TRC}
          1 {c |}{res} -.123456799   -.123456798 {c    |}
            {c BLC}{hline 27}{c BRC}
{txt}


			
{title:Conformability}

{pstd}
{it:X} and {it:Y} must be conformable (i. e., vectors of the same length, each with two columns). 
Lower limits (entries in the first column) should be 
less than upper limits (entries in even columns), but once again, whether or not this is true is not checked by {cmd:int_mult()} (or any 
other command in {bf:int_utils}).   
{p_end}

{marker int_pow}

{hline}
{bf:int_pow() -- Raise an interval to a (scalar) power}

{title:Syntax}

{p 11 18 2}
{it:real matrix} {cmd:int_pow(}{it:real matrix X, real scalar power [, real scalar digits]})

{p 12 18 2}
  {it:X}:  {it:real matrix} containing data (each pair of rows {it:i,i+1} of which represent intervals)
  {p_end}
{p 12 18 2}
  {it:power}:  {it:real scalar} power to raise interval to)
  {p_end}
  
{pstd}
where

{p 14 18 2}
{it:digits}:  {it:real scalar} containing desired rounding. Default is {it:1e-8}.


{title:Description}

{pstd}
{cmd:int_pow()} raises a collection of intervals into powers. The matrix {it:X} must be of dimension {it:D} by 2,
where lower interval bounds appear in the first column and upper bounds in the second column. 
The scalar {it:power} is the power to which the intervals are to be raised, and may be either
integral or fractional, positive or negative.  The scalar {it:digits} controls outward rounding, as discussed in {help int_utils##r_up:r_up()} or {help int_utils##r_down:r_down()}. If 
the user attempts to raise an interval with a negative component to a negative power, missing is returned.

{pstd}Example:

{com}. mata: X=(0,1 \ 1,2)
{com}. mata: int_pow(X,2)
{res}           {txt}    1    2   
            {c TLC}{hline 10}{c TRC}
          1 {c |}{res}  0    1  {c |}
          2 {c |}{res}  1    8  {c |}
            {c BLC}{hline 10}{c BRC}
{txt}	

{hline}
{marker int_matmult}
{bf:int_matmult() -- Multiplication of intervals for interval computations}


{title:Syntax}

{p 11 18 2}
{it:real matrix} {cmd:int_matmult(}{it:real matrix X, real matrix Y [, real scalar digits]})

{p 4 4 2}
where

{p 12 18 2}
  {it:X}:  {it:real matrix} containing data (each pair of rows {it:i,i+1} of which represent intervals)
  {p_end}
{p 12 18 2}
  {it:Y}:  {it:real matrix} containing data (each pair of rows {it:i,i+1} of which represent intervals)
  {p_end}
  
{pstd}
where

{p 12 18 2}
{it:digits}:  {it:real scalar} containing desired rounding. Default is {it:1e-8}.

{title:Description}

{pstd}
{cmd:int_matmult()} computes matrix products of interval matrices. Rows of the input matrices {it: X,Y} are treated as usual, while
{it: pairs} of columns are treated as lower and upper bounds of intervals. Thus, an r-by-c interval matrix should be written as an r-by-2c matrix,
with lower limits appearing in the first column and upper limits appearing in the second column. {cmd:int_matmult()} multiplies the
interval matrix {it: Y} with the interval matrix {it: X}. The computations are done using the textbook brute-force matrix multiplication approach.

{pstd}
Interval matrix multiplication is done by concatinating all possible ways of multiplying the entries of two matrices, and collecting results. 
Consider multiplying the 1-by-2 interval matrix [(1,2),(3,4)] with the 2-by-1 interval matrix [(-1,1),(0,2)]'. This requires performing the computation
(1,2)*(-1,1)+(3,4)*(0,2). This first gives (-2,2)+(0,8), and then reduces to (-2,10). This amounts to an application of 
{bf:{help int_utils##int_add:int_add()}} and {bf:{help int_utils##int_mult:int_mult()}}. In terms of these functions, the calculation would be carried out
as {bf: int_add(int_mult((1,2),(-1,1)),int_mult((3,4),(0,2)))}.

{title: Options}

{pstd}
The option {it: digits} specifies the minimal roundoff error used in interval computations. In effect, this sets the size of the
smallest interval recognizable by the interval addition operation and is necessary for so as not to get misleading results in the
course of interval computations.  Illustrations of how {it:digits} works are given in the help entries {bf:{help int_utils##int_add:int_add()}},
{bf:{help int_utils##int_sub:int_sub()}}, and {bf:{help int_utils##int_mult:int_mult()}}.

{title: Remarks}

{pstd}
{cmd:int_matmult()} does not check if it is in fact true that the lower limits of intervals are less than or equal to upper limits; hence, 
users must exert care in assuring that this is in fact the case. 

{pstd}Examples:

Multiplication of two 2-by-2 interval matrices (which are represented as 2-by-4 matrices): 

{com}. mata: X=(0,1,2,4) \ (1,2,5,7)
{com}. mata: Y=(-1,1,4,6) \ (3,4,7,8) 
{com}. mata: int_matmult(X,Y)
{res}           {txt}    1    2    3    4 
            {c TLC}{hline 19}{c TRC}
          1 {c |}{res}  5   17   14   38 {c    |}
          2 {c |}{res} 13   30   39   68 {c    |}
            {c BLC}{hline 19}{c BRC}
{txt}

{title:Conformability}

{pstd}
{it:X} and {it:Y} must be conformable matrices. Usually, if {it: X} is a r1-by-c1 matrix, and Y is r2-by-c2, then it must be the case that c1=r2. 
In the case of interval computations, {it: X} is a matrix of intervals held in a r1-by-(2*c1) matrix, and {it: Y} is a matrix of intervals held in a
r2-by-(2*c2) matrix. Hence, for interval computations executed in this fashion, it is required that {it: Y} has half as many rows as {it: X} has columns. 
For example, if {it: X} is a 3-by-6 interval matrix (implying that {it: X} is really a 3-by-3 matrix of intervals), then {it: Y} should be 3-by-(2*c2). 
As a final note, {cmd:int_matmult()} can be used to compute standard inner (dot) products of vectors; in this case {it: X} is 1-by-(2*N) and {it: Y} is N-by-2.
{p_end}

{marker int_rowmult}
{hline}
{bf:int_rowmult() -- Row-wise products of intervals for interval computations}


{title:Syntax}

{p 11 18 2}
{it:real matrix} {cmd:int_rowmult(}{it:real matrix X [, real scalar digits]}{cmd:)}{txt}

{p 4 4 2}
where

{p 12 18 2}
  {it:X}:  {it:real matrix} containing data (each pair of rows {it:i,i+1} of which represent intervals)
  {p_end}
  
{pstd}
where

{p 14 18 2}
{it:digits}:  {it:real scalar} containing desired rounding. Default is {it:1e-8}.

{title:Description}

{pstd}
{cmd:int_rowmult()} computes rowwise products of intervals. Rows of the input matrix {it: X} are treated as usual, while
each pair of columns are treated as lower and upper bounds, respectively, of intervals. Thus, an N-by-1 interval (row) 
vector should be written as an N-by-2 matrix,
with lower limits appearing in the first column and upper limits appearing in the second column. {cmd:int_rowmult()} treats 
each pair of columns as intervals, and computes a single N-by-2 matrix representing the interval product of all represented intervals.
For details as to how interval multiplication is defined, see {bf:{help int_utils##int_mult: int_mult()}}.

{title: Options}

{pstd}
The option {it: digits} specifies the minimal roundoff error used in interval computations. In effect, this sets the size of the
smallest interval recognizable by the interval addition operation and is necessary for so as not to get misleading results in the
course of interval computations.  For details, see the help entries {bf:{help int_utils##int_add:int_add()}}, {bf:{help int_utils##int_sub: int_sub()}}, 
or {bf:{help int_utils##int_mult:int_mult()}}.

{title: Remarks}

{pstd}
{cmd: int_rowmult()} does not check if it is in fact true that the lower limits of intervals are less than or equal to upper limits; hence, 
users must exert care that this is in fact the case. 

{pstd}Examples:

Consider the rows of a matrix {it: X} which are successive intervals: 

{com}. mata: X=(-1,1),(2,4) \ (2,3),(4,5)
{com}. mata: int_rowmult(X)
{res}           {txt}    1   2     
            {c TLC}{hline 8}{c TRC}
          1 {c |}{res} -4   4 {c    |}
          2 {c |}{res}  8  15 {c    |}
            {c BLC}{hline 8}{c BRC}
{txt}
			
{title:Conformability}

{pstd}
As it is a sequence of intervals {it:X} should have an even number of entries, where odd entries are lower limits and even entries are upper limits.    
{p_end}


{marker int_rowadd}
{hline}
{bf:int_rowadd() -- Row-wise sums of intervals for interval computations}


{title:Syntax}

{p 11 18 2}
{it:real matrix} {cmd:int_rowadd(}{it:real matrix X [, real scalar digits]})

{p 4 4 2}
where

{p 12 18 2}
  {it:X}:  {it:real matrix} containing data (each pair of rows {it:i,i+1} of which represent intervals)
  {p_end}
  
{pstd}
where

{p 14 18 2}
{it:digits}:  {it:real scalar} containing desired rounding. Default is {it:1e-8}

{title:Description}

{pstd}
{cmd:int_rowadd()} computes rowwise sums of intervals. Rows of the input matrix {it: X} are treated as usual, while
each pair of columns are treated as lower and upper bounds, respectively, of intervals. Thus, an N-by-1 interval (row) 
vector should be written as an N-by-2 matrix,
with lower limits appearing in the first column and upper limits appearing in the second column. {cmd: int_rowadd()} treats 
each pair of columns as intervals, and computes a single N-by-2 matrix representing the interval sum of all represented intervals.
For details as to how interval addition is defined, see {bf:{help int_utils##int_add: int_add()}}.

{title: Options}

{pstd}
The option {it: digits} specifies the minimal roundoff error used in interval computations. In effect, this sets the size of the
smallest interval recognizable by the interval addition operation and is necessary for so as not to get misleading results in the
course of interval computations.  For details, see the help entries {bf:{help int_utils##int_add:int_add()}}, {bf:{help int_utils##int_sub:int_sub()}}, 
or {bf:{help int_utils##int_mult:int_mult()}}.

{title: Remarks}

{pstd}
{cmd:int_rowadd()} does not check if it is in fact true that the lower limits of intervals are less than or equal to upper limits; hence, 
users must exert care that this is in fact the case. 

{pstd}Examples:

Consider the rows of a matrix {it: X} which are successive intervals: 

{com}. mata: X=(-1,1),(2,4) \ (2,3),(4,5)
{com}. mata: int_rowadd(X)
{res}           {txt}   1  2     
            {c TLC}{hline 6}{c TRC}
          1 {c |}{res} 1  5 {c    |}
          2 {c |}{res} 6  8 {c    |}
            {c BLC}{hline 6}{c BRC}
{txt}
			
{title:Conformability}

{pstd}
As it is a sequence of intervals {it:X} should have an even number of entries, where odd entries are lower limits and even entries are upper limits.    
{p_end}

{marker int_transpose}
{hline}
{bf:int_transpose() -- Transposition of interval matrices}


{title:Syntax}

{p 11 18 2}
{it:real matrix} {cmd:int_transpose(}{it:real matrix X})

{p 4 4 2}
where

{p 12 18 2}
  {it:X}:  {it:real matrix} containing data (each pair of rows {it:i,i+1} of which represent intervals)
  {p_end}
  
{title:Description}

{pstd}
{cmd:int_transpose()} transposes interval matrices. Rows of the input matrix {it:X} are treated as usual, while
{it: pairs} of columns are treated as lower and upper bounds of intervals. Thus, an r-by-c interval matrix should be written as an r-by-2c matrix,
with lower limits appearing in the first column and upper limits appearing in the second column.


{title: Remarks}

{pstd}
{cmd: int_transpose()} does not check if it is in fact true that the lower limits of intervals are less than or equal to upper limits; hence, 
users must exert care in assuring that this is in fact the case. 

{pstd}Examples:

Transposition of an interval matrix: 

{com}. mata: X=(0,1,2,4) \ (1,2,5,7)
{com}. mata: int_transpose(X)
{res}           {txt}    1    2    3    4 
            {c TLC}{hline 19}{c TRC}
          1 {c |}{res}  0    1    1    2 {c    |}
          2 {c |}{res}  2    4    5    7 {c    |}
            {c BLC}{hline 19}{c BRC}
{txt}

{title:Conformability}

{pstd}
{it:X} and {it:Y} must be conformable matrices. Usually, if {it: X} is a r1-by-c1 matrix, and Y is r2-by-c2, then it must be the case that c1=r2. 
In the case of interval computations, {it: X} is a matrix of intervals held in a r1-by-(2*c1) matrix, and {it: Y} is a matrix of intervals held in a
r2-by-(2*c2) matrix. Hence, for interval computations executed in this fashion, it is required that {it: Y} has half as many rows as {it: X} has columns. 
For example, if {it: X} is a 3-by-6 interval matrix (implying that {it: X} is really a 3-by-3 matrix of intervals), then {it: Y} should be 3-by-(2*c2). 
As a final note, {cmd: int_matmult()} can be used to compute standard inner (dot) products of vectors; in this case {it: X} is 1-by-(2*N) and {it: Y} is N-by-2.
{p_end}

{marker int_rowmatmult}
{hline}
{bf:int_rowmatmult() -- (Square) matrix-interval products in parallel, where matrices are in single row form}


{title:Syntax}

{p 11 18 2}
{it:real matrix} {cmd:int_rowmatmult(}{it:real matrix X, real matrix Y [, real scalar digits]})

{p 4 4 2}
where

{p 12 18 2}
  {it:X}:  {it:real matrix} containing data (each pair of rows {it:i,i+1} of which represent entries in order of an interval)
  {p_end}
{p 12 18 2}
  {it:Y}:  {it:real matrix} containing data (each pair of rows {it:i,i+1} of which represent entries in order of an interval matrix)
  {p_end}
  
{pstd}
where

{p 14 18 2}
{it:digits}:  {it:real scalar} containing desired rounding. Default is {it:1e-8}

{title:Description}

{pstd}
{cmd:int_rowmatmult()} computes rowwise products of interval matrices, where each row of {it:X} and {it:Y} holds all matrix entries.
Ignoring the interval component of the problem for the moment, consider the case of multiplying two 3-by-3 matrices. {cmd:int_rowmatmult()}
would correspond to reshaping (see, e.g., {bf:{help mf_rowshape: rowshape()}} each matrix into single 1-by-9 rows and stacking them. The advantage
is that now matrix multiplication can proceed in parallel, observation by observation. 

{pstd}
{cmd:int_rowmatmult()} executes this sort of operation using interval computations. Square in this case are represented by a r-by-2r setting,
where each pair of columns represents an interval; see {bf:{help int_utils##int_matmult: int_matmult()}} for more discussion. In the case of {cmd:int_rowmatmult()},
each interval matrix is held in a single row of dimension 1-by-(2r^2). 

{title: Options}

{pstd}
The option {it: digits} specifies the minimal roundoff error used in interval computations. In effect, this sets the size of the
smallest interval recognizable by the interval addition operation and is necessary for so as not to get misleading results in the
course of interval computations.  For details, see the help entries {bf:{help int_utils##int_add: int_add()}}, {bf:{help int_utils##int_sub:int_sub()}}, 
or {bf:{help int_utils##int_mult: int_mult()}}.

{title: Remarks}

{pstd}
{cmd: int_rowmatmult()} does not check if it is in fact true that the lower limits of intervals are less than or equal to upper limits; hence, 
users must exert care that this is in fact the case. Moreover, {cmd:int_rowmatmult()} does not check if the represented matrices are square, so care must
also be exerted that matrices are of correct dimension.

{pstd}Examples:

Multiplication of two 2-by-2 interval matrices (which are represented as 2-by-4 matrices): 

{com}. mata: X=(0,1,2,4) \ (1,2,5,7)
{com}. mata: Y=(-1,1,4,6) \ (3,4,7,8) 
{com}. mata: int_matmult(X,Y)
{res}           {txt}    1    2    3    4 
            {c TLC}{hline 19}{c TRC}
          1 {c |}{res}  5   17   14   38 {c    |}
          2 {c |}{res} 13   30   39   68 {c    |}
            {c BLC}{hline 19}{c BRC}
			
{com}. mata: X=rowshape(X,1)
{com}. mata: Y=rowshape(Y,1)
{com}. mata: int_rowmatmult(X,Y)
{res}           {txt}    1    2    3    4    5    6    7    8  
            {c TLC}{hline 39}{c TRC}
          1 {c |}{res}  5   17   14   38   13   30   39   68 {c    |}
            {c BLC}{hline 39}{c BRC}
			
			{txt}	
{title:Conformability}

{pstd}
As {it:X,Y} represent a collection of {it:m} square matrices, they should have dimension m-by-(2*r^2),
where odd entries are lower limits and even entries are upper limits.    
{p_end}

{marker int_rowmatvecmult}
{hline}
{bf:int_rowmatvecmult() -- (Square) matrix-vector interval products in parallel, where matrices and vectors are in single row form}


{title:Syntax}

{p 11 18 2}
{it:real matrix} {cmd:int_rowmatvecmult(}{it:real matrix X, real matrix y [, real scalar digits]})

{p 4 4 2}
where

{p 12 18 2}
  {it:X}:  {it:real matrix} containing data (each pair of rows {it:i,i+1} of which represent entries in order of an interval)
  {p_end}
{p 12 18 2}
  {it:y}:  {it:real matrix} containing data (each pair of rows {it:i,i+1} of which represent entries in order of an interval matrix)
  {p_end}
  
{pstd}
where

{p 14 18 2}
{it:digits}:  {it:real scalar} containing desired rounding. Default is {it:1e-8}.

{title:Description}

{pstd}
{cmd:int_rowmatvecmult()} is a companion to {bf:{help int_utils##int_matmult:int_matmult()}}. It computes rowwise products of interval matrices
and interval vectors, where each row of {it:X} holds an interval matrix and each row of {it: y} holds an interval vector.
Ignoring the interval component of the problem for the moment, consider the case of multiplying a sequence of
3-by-3 matrices and 3-by-1 column vectors. 
{cmd:int_rowmatvecmult()} would correspond to reshaping (see, e.g., {bf:{help mf_rowshape:rowshape()}}) each matrix into 1-by-9 rows 
and stacking them, and reshaping each vector into 1-by-3 rows and stacking them. 
The advantage is that now matrix multiplication can proceed in parallel rather than through looping.  

{pstd}
{cmd:int_rowmatvecmult()} executes this sort of operation using interval computations. Square matrices in this case are represented 
by a r-by-2r collection of intervals, where each pair of columns represents an interval; see {bf:{help int_utils##int_matmult:int_matmult()}} for more discussion. 
A conformable interval vector written in row form is of dimension 1-by-(2r). 

{title: Options}

{pstd}
The option {it: digits} specifies the minimal roundoff error used in interval computations. In effect, this sets the size of the
smallest interval recognizable by the interval addition operation and is necessary for so as not to get misleading results in the
course of interval computations.  For details, see the help entries {bf:{help mf_int_add: int_add()}}, {bf:{help mf_int_sub: int_sub()}}, 
or {bf:{help int_utils##int_mult: int_mult()}}.

{title: Remarks}

{pstd}
{cmd: int_rowmatvecmult()} does not check if it is in fact true that the lower limits of intervals are less than or equal to upper limits; hence, 
users must exert care that this is in fact the case. Moreover, {cmd:int_rowmatmult()} does not check if the represented matrices are square, so care must
also be exerted that matrices are of correct dimension.

{pstd}Examples:

Multiplication of two 2-by-2 interval matrices (which are represented as 2-by-4 matrices): 

{com}. mata: X=(0,1,2,4) \ (1,2,5,7)
{com}. mata: Y=(-1,1) \ (4,6)  
{com}. mata: int_matmult(X,Y)
{res}           {txt}    1    2 
            {c TLC}{hline 9}{c TRC}
          1 {c |}{res}  7   25 {c    |}
          2 {c |}{res} 18   44 {c    |}
            {c BLC}{hline 9}{c BRC}
			
{com}. mata: X=rowshape(X,1)
{com}. mata: Y=rowshape(Y,1)
{com}. mata: int_rowmatvecmult(X,Y)
{res}           {txt}    1    2    3    4  
            {c TLC}{hline 19}{c TRC}
          1 {c |}{res}  7   25   18   44 {c    |}
            {c BLC}{hline 19}{c BRC}
			
			{txt}	
{title:Conformability}

{pstd}
As {it:X} represents a collection of {it:m} square (interval) matrices, and {it: y} represents a collection of 
{it: X} should have dimension m-by-(2*r^2), and {it: y} should have dimension m-by-(2r). In each case, 
Odd column entries are lower limits of intervals and even entries are upper limits of intervals.    
{p_end}

{marker int_rowtranspose}

{hline}
{bf:int_rowtranpose() -- Transpose of a (square) interval matrix written in single row form}


{title:Syntax}

{p 11 18 2}
{it:real matrix} {cmd:int_rowtranspose(}{it:real matrix X})

{p 4 4 2}
where

{p 12 18 2}
  {it:X}:  {it:real matrix} containing data (each pair of rows {it:i,i+1} of which represent entries in order of an interval)
  {p_end}


{title:Description}

{pstd}
{cmd:int_rowtranspose()} is a companion to {bf:{help int_utils##int_rowmatmult:int_rowmatmult()}}. It computes rowwise transposes of interval matrices
and may help in performing rowwise interval computations.

{pstd}Examples:

Reshaping and transposing a 2-by-2 interval matrix: 

{com}. mata: X=(0,1,2,4) \ (1,2,5,7)
{com}. mata: X=rowshape(X,1)
{com}. mata: int_rowtranspose(X)
{res}           {txt}    1    2    3    4    5    6    7    8 
            {c TLC}{hline 39}{c TRC}
          1 {c |}{res}  0    1    1    2    2    4    5    7 {c    |}
            {c BLC}{hline 39}{c BRC}
			
			{txt}	
{title:Conformability}

{pstd}
As {it:X} represents a collection of {it:m} square (interval) matrices, 
{it: X} should have dimension m-by-(2*r^2). In each case, 
Odd column entries are lower limits of intervals and even entries are upper limits of intervals.    
{p_end}

{marker int_int}
{hline}
{bf:int_int() -- Intersection of intervals for interval computations}


{title:Syntax}

{p 11 18 2}
{it:real matrix} {cmd:int_int(}{it:real matrix X, real matrix Y})

{p 4 4 2}
where

{p 12 18 2}
  {it:X}:  {it:real matrix} containing data (pairs of rows of which represent intervals)
  {p_end}
{p 12 18 2}
  {it:Y}:  {it:real matrix} containing data (pairs of rows of which represent intervals)
  {p_end}
  
{title:Description}

{pstd}
{cmd:int_int()} computes row-by-row interval intersections of two interval vectors. Rows of the input matrices {it: X,Y} are treated as usual, while
the first column of {it: X} and {it: Y} is treated as the lower limit of an interval, and the second column of {it: X} and {it: Y}
are treated as upper limits. An N-by-1 interval (column) vector should be represented in mata as an N-by-2 matrix. 

{pstd}
Interval intersection is simply returns the range of common elements for two interval vectors. For example, the intervals 
[-1,1] and [0,4] have intersection [0,1]. 

{title: Remarks}

{pstd}
{cmd: int_int()} does not check if it is in fact true that the lower limits of intervals are less than or equal to upper limits; hence, 
users must exert care that this is in fact the case. {cmd: int_int()} returns missing values if the intervals do not intersect.

{pstd}Examples:

{com}. mata: X=(-1,1) \ (2,4)
{com}. mata: Y=(0,3) \ (5,6) 
{com}. mata: int_int(X,Y)
{res}           {txt}   1   2     
            {c TLC}{hline 7}{c TRC}
          1 {c |}{res} 0   1 {c    |}
          2 {c |}{res} .   . {c    |}
            {c BLC}{hline 7}{c BRC}
{txt}
			
{title:Conformability}

{pstd}
{it:X} and {it:Y} must be of the same length, each with two columns.  Moreover, lower limits (entries in the first column) should be 
less than upper limits (entries in the second column). Some care must be exercised in assuring this, as {cmd:int_int()} does not check
whether or not it is true.
{p_end}

{marker int_rowint}
{hline}
{bf:int_int() -- Rowwise intersection of intervals for interval computations}


{title:Syntax}

{p 11 18 2}
{it:real matrix} {cmd:int_int(}{it:real matrix X, real matrix Y})

{p 4 4 2}
where

{p 12 18 2}
  {it:X,Y}:  {it:real matrix} containing data (each pair of columns {it:i,i+1} of which represent intervals)
  {p_end}
  
{title:Description}

{pstd}
{cmd:int_rowint()} computes interval intersections of a set of row-interval vectors, arranged as columns of the matrices {it: X}
and {it: Y}.
Each pair of columns of both matrices {it: i,i+1} is treated as a separate interval. Effectively, {cmd: int_rowint()} applies 
{bf:{help int_utils##int_int:int_int()}} repeatedly to each pair of columns of {it: X} and {it: Y}. For the definition of interval intersection, see 
{bf:{help int_utils##int_int:int_int()}}. 

{title: Remarks}

{pstd}
{cmd:int_rowint()} does not check if it is in fact true that the lower limits of intervals are less than or equal to upper limits; hence, 
users must exert care that this is in fact the case. {cmd:int_rowint()} returns missing values if intervals do not intersect.

{pstd}Examples:

Consider the addition of two interval vectors: 

{com}. mata: X=-1,1,0,3 \ 2,4,5,6
{com}. mata: Y=0,1,2,3 \ 1,2,3,4
{com}. mata: int_rowint(X,Y)
{res}           {txt}   1   2   3   4
            {c TLC}{hline 15}{c TRC}
          1 {c |}{res} 0   1   2   3 {c    |}
          2 {c |}{res} 2   2   .   . {c    |}
            {c BLC}{hline 15}{c BRC}
{txt}
			
{title:Conformability}

{pstd}
{it:X} and {it:Y} must be of the same length, each with the same number of columns.  Moreover, lower limits (entries in the first column) should be 
less than upper limits (entries in the second column). Some care must be exercised in assuring this, as {cmd: int_int()} does not check
whether or not it is true.
{p_end}

{marker int_hun}
{hline}
{bf:int_hun() -- Interval hull (union) for interval computations}


{title:Syntax}

{p 11 18 2}
{it:real matrix} {cmd:int_hun(}{it:real matrix X, real matrix Y  [, real scalar digits]})

{p 4 4 2}
where

{p 12 18 2}
  {it:X}:  {it:real matrix} containing data (first column represents lower bounds, the second upper bounds) of an interval)
  {p_end}
{p 12 18 2}
  {it:Y}:  {it:real matrix} containing data (first column represents lower bounds, the second upper bounds) of an interval)
  {p_end}

{pstd}
where

{p 14 18 2}
{it:digits}:  {it:real scalar} containing desired rounding. Default is {it:1e-8}
  
  
{title:Description}

{pstd}
{cmd:int_hun()} computes the interval hull of two interval (column) vectors. Rows of the input matrices {it: X,Y} are treated as usual, while
the first column of {it: X} and {it: Y} is treated as the lower limit of an interval, and the second column of {it: X} and {it: Y}
are treated as upper limits. An N-by-1 interval (column) vector should be represented in mata as an N-by-2 matrix. 

{pstd}
The interval hull is, roughly speaking, the largest interval that contains the intervals in the rows of {it: X} and {it: Y}. 
For example, the interval hull
of (-1,3) and (-2,2) is (-2,3). While this is seemingly the same as the union of two intervals, the hull fills in gaps. So, for example, the
interval hull of (-2,-1) and (0,1) is the interval (-2,1). 

{title: Options}

{pstd}
The option {it: digits} specifies the minimal roundoff error used in interval computations. In effect, this sets the size of the
smallest interval recognizable by the interval addition operation and is necessary for so as not to get misleading results in the
course of interval computations.  Illustrations of how {it: digits} works are given in the help entries {bf:{help int_utils##int_add:int_add()}},
{bf:{help int_utils##int_sub:int_sub()}}, and {bf:{help int_utils##int_mult:int_mult()}}.

{pstd} 
In the case of interval hull computations, the idea is to get the smallest interval that contains all the elements of two intervals. Hence, 
lower limits are rounded {it: down} to the lower bound suggested by {it: digits}, and upper limits are rounded up to the upper bound suggested
by {it: digits}.

{title: Remarks}

{pstd}
{cmd: int_hun()} does not check if it is in fact true that the lower limits of intervals are less than or equal to upper limits; hence, 
users must exert care that this is in fact the case. {cmd: int_hun()} returns missing values if the intervals do not intersect.

{pstd}Examples:

{com}. mata: X=(-1,1) \ (2,4)
{com}. mata: Y=(0,3) \ (5,6) 
{com}. mata: int_hun(X,Y)
{res}           {txt}    1   2     
            {c TLC}{hline 8}{c TRC}
          1 {c |}{res} -1   3 {c    |}
          2 {c |}{res}  2   6 {c    |}
            {c BLC}{hline 8}{c BRC}
{txt}
			
{title:Conformability}

{pstd}
{it:X} and {it:Y} must be of the same length, each with two columns.  Moreover, lower limits (entries in the first column) should be 
less than upper limits (entries in the second column). Some care must be exercised in assuring this, as {cmd: int_hun()} does not check
whether or not it is true.
{p_end}

{marker int_rowhull}
{hline}
{bf:int_rowhull() -- Rowwise interval hulls for interval computations}


{title:Syntax}

{p 11 18 2}
{it:real matrix} {cmd:int_rowhull(}{it:real matrix X})

{p 4 4 2}
where

{p 12 18 2}
  {it:X}:  {it:real matrix} containing data (each pair of columns {it:i,i+1} of which represent intervals)
  {p_end}
  
{title:Description}

{pstd}
{cmd:int_rowhull()} computes column-wise interval hull unions for a set of row-interval vectors, arranged as columns of the matrices {it: X}.
Each pair of columns {it: i,i+1} of {it: X} is treated as a separate interval. Effectively, {cmd: int_rowhull()} applies 
{bf:{help mf_int_hun: int_hun()}} successively to each row of {it: X} and returns a single row of entries comprising the interval hull
of each interval in {it: X}. For the definition of the interval hull, see 
{bf:{help mf_int_hun: int_hun()}}. 

{title: Remarks}

{pstd}
{cmd: int_rowhull()} does not check if it is in fact true that the lower limits of intervals are less than or equal to upper limits; hence, 
users must exert care that this is in fact the case. 

{pstd}Examples:

Consider the addition of two interval vectors: 

{com}. mata: X=-1,1,0,3 \ 2,4,5,6
{com}. mata: int_rowhull(X)
{res}           {txt}    1   2   3   4
            {c TLC}{hline 16}{c TRC}
          1 {c |}{res} -1   4   0   6 {c    |}
            {c BLC}{hline 16}{c BRC}
{txt}
			
{title:Conformability}

{pstd}
{it:X} should have an even number of columns, where each pair of columns represents an interval vector. 
 Moreover, lower limits (entries in the first column) should be 
less than upper limits (entries in the second column). Some care must be exercised in assuring this, as {cmd:int_int()} does not check
whether or not it is true.
{p_end}

{marker int_collect}
{hline}
{bf:int_collect() -- Collection of intervals into distinct disjoint intervals}


{title:Syntax}

{p 11 18 2}
{it:real matrix} {cmd:int_collect(}{it:real matrix X})

{p 4 4 2}
where

{p 12 18 2}
  {it:X}:  {it:real matrix} containing data (each pair of columns {it:i,i+1} of which represent intervals)
  {p_end}
  
{title:Description}

{pstd}
{cmd:int_collect()} sweeps a matrix containing column-vector intervals and assembles these intervals in to 
the smallest possible number of disjoint intervals. To be more specific, {cmd:int_collect()} takes a group of intervals and
checks to see whether there are common points of intersection among those intervals by applying {cmd: int_rowint()} (see
{bf:{help mf_int_rowint: int_rowint()}}). In the event that intervals overlap, {cmd: int_collect()} then combines these
intervals by applying {cmd:int_rowhull()} (see {bf:{help mf_int_rowint: int_rowint()}}). The idea is to resolve a set of intervals
into the smallest possible group of disjoint yet all-inclusive intervals.  

{title: Remarks}

{pstd}
{cmd: int_collect()} does not check if it is in fact true that the lower limits of intervals are less than or equal to upper limits; hence, 
users must exert care that the numbers appearing in the odd columns {it: i} are less than their counterparts in even columns {it: i+1}.

{pstd}Examples:

{com}. mata: X=.1,.2,.4,.5 \ .15,.18,3,4 \10,11,12,13
{com}. mata: int_collect(X)
{res}           {txt}    1    2    3    4
            {c TLC}{hline 19}{c TRC}
          1 {c |}{res} .1   .2   .4    4 {c    |}
          1 {c |}{res} 10   11   12   13 {c    |}		  
            {c BLC}{hline 19}{c BRC}
{txt}
			
{title:Conformability}

{pstd}
{it:X} should have an even number of columns, where each pair of columns represents an interval vector. 
 Moreover, lower limits (entries in the first column) should be 
less than upper limits (entries in the second column). Some care must be exercised in assuring this, as {cmd: int_collect()} does not check
whether or not it is true.
{p_end}

{marker int_mid}
{hline}
{bf:int_mid() -- Midpoints of intervals returned as intervals}


{title:Syntax}

{p 11 18 2}
{it:real matrix} {cmd:int_mid(}{it:real matrix X [, digits]})

{p 4 4 2}
where

{p 12 18 2}
  {it:X}:  {it:real matrix} containing data (each pair of columns {it:i,i+1} of which represent intervals)
  {p_end}
  
{title:Description}

{pstd}
{cmd:int_mid()} computes the interval midpoints of the collection of intervals represented by {it:X}. It differs from the related command
{cmd:mid()} (see {bf:{help mf_mid: mid()}} in that it returns results in interval form. The midpoint of an interval is defined in the obvious 
way; the midpoint of an interval is simply the average of its lower and upper bound. {cmd: int_mid()} returns results in interval form so as
to ease conformability with other interval functions. So, when confronted with the interval (4,6), {cmd: int_mid()} returns the result (5,5).

{title: Options}

{pstd}
The option {it: digits} specifies the minimal roundoff error used in interval computations. In effect, this sets the size of the
smallest interval recognizable by the interval addition operation and is necessary for so as not to get misleading results in the
course of interval computations.  Illustrations of how {it: digits} works are given in the help entries {bf:{help int_utils##int_add:int_add()}},
{bf:{help int_utils##int_sub:int_sub()}}, and {bf:{help int_utils##int_mult:int_mult()}}. This can be important when executing {cmd: int_mid()}; if the 
result of the midpoint calculation has more decimal places than recognized by {cmd: int_mid()}, it will return the smallest possible interval
bracketing the middle point of the interval.

{title: Remarks}

{pstd}
{cmd: int_mid()} does not check if it is in fact true that the lower limits of intervals are less than or equal to upper limits; hence, 
users must exert care that the numbers appearing in the odd columns {it: i} are less than their counterparts in even columns {it: i+1}.

{pstd}Examples:

Consider the addition of two interval vectors: 

{com}. mata: X=.1,.4 \ .15,3 \10,12
{com}. mata: int_mid(X)
{res}           {txt}       1    2 
            {c TLC}{hline 14}{c TRC}
          1 {c |}{res}   .25    .25 {c |}
          2 {c |}{res} 1.575  1.575 {c |}		  
          3 {c |}{res}    11     11 {c |}		  
{txt}            {c BLC}{hline 14}{c BRC}
{txt}
			
{title:Conformability}

{pstd}
{it:X} should have an even number of columns, where each pair of columns represents an interval vector. 
 Moreover, lower limits (entries in the first column) should be 
less than upper limits (entries in the second column). Some care must be exercised in assuring this, as {cmd: int_mid()} does not check
whether or not it is true.
{p_end}

{marker mid}
{hline}
{bf:mid() -- Midpoints of intervals}


{title:Syntax}

{p 11 18 2}
{it:real matrix} {cmd:mid(}{it:real matrix X})

{p 4 4 2}
where

{p 12 18 2}
  {it:X}:  {it:real matrix} containing data (each pair of columns {it:i,i+1} of which represent intervals)
  {p_end}
  
{title:Description}

{pstd}
{cmd:mid()} computes the midpoints of the collection of intervals represented by {it:X}. It differs from the related command
{bf:{help mf_int_mid:int_mid()}} in that it returns results in scalar form. The midpoint of an interval is defined in the obvious 
way; the midpoint of an interval is simply the average of its lower and upper bound. When confronted with the interval (4,6), 
{cmd: mid()} returns the result 5.

{title: Remarks}

{pstd}
{cmd: mid()} does not check if it is in fact true that the lower limits of intervals are less than or equal to upper limits; hence, 
users must exert care that the numbers appearing in the odd columns {it: i} are less than their counterparts in even columns {it: i+1}.

{pstd}Examples:

Consider the addition of two interval vectors: 

{com}. mata: X=.1,.4 \ .15,3 \10,12
{com}. mata: mid(X)
{res}           {txt}       1  
            {c TLC}{hline 8}{c TRC}
          1 {c |}{res}   .25  {c |}
          2 {c |}{res} 1.575  {c |}		  
          3 {c |}{res}    11  {c |}		  
{txt}            {c BLC}{hline 8}{c BRC}
{txt}
			
{title:Conformability}

{pstd}
{it:X} should have an even number of columns, where each pair of columns represents an interval vector. 
 Moreover, lower limits (entries in the first column) should be 
less than upper limits (entries in the second column). Some care must be exercised in assuring this, as {cmd: int_mid()} does not check
whether or not it is true.
{p_end}

{marker int_mince}
{hline}
{bf:int_mince() -- Split a series of intervals in a larger list of intervals}


{title:Syntax}

{p 11 18 2}
{it:real matrix} {cmd:int_mince(}{it:real matrix X, real scalar t, real scalar n})

{title:Description}

{pstd}
{cmd:int_mince()} resolves a specific component of a collection of intervals into smaller intervals. 
The scalar {it: t} points In {cmd:int_mince()} to the interval represented by columns {it:2t-1,2t} of {it: X},
while the scalar {it: n} tells  {cmd:int_mince()} how many smaller intervals to break this interval into. 

{pstd}Example:

{com}. mata: X=(0,1,1,2)
{com}. mata: int_mince(X,2,4)
{res}           {txt}    1    2     3      4  
            {c TLC}{hline 22}{c TRC}
          1 {c |}{res}  0   .5     1   1.25 {c  |}
          2 {c |}{res} .5    1  1.25    1.5 {c  |}
          3 {c |}{res}  0   .5   1.5   1.75 {c  |}
          4 {c |}{res} .5    1  1.75      2 {c  |}
            {c BLC}{hline 22}{c BRC}
{txt}	

{marker int_mesh}
{hline}
{bf:int_mesh() -- Create a mesh of intervals covering {it: [0,1]^n}}


{title:Syntax}

{p 11 18 2}
{it:real matrix} {cmd:int_mesh(}{it:real scalar n, real scalar t})

{title:Description}

{pstd}
{cmd:int_mesh()} creates disjoint intervals that cover the n-dimensional unit space {it: [0,1]}. The first argument {it: n} is the number
of desired dimensions, and {it: t} describes the number of desired points per dimension. The odd-numbered columns are the lower limits of
the intervals, while the even-numbered columns are upper limits.  Be wary: the size of the resulting matrix expands rapidly in {it: n} and {it: t}!

{pstd}Example:

{com}. mata: int_mesh(3,2)
{res}           {txt}    1    2    3    4    5    6 
            {c TLC}{hline 29}{c TRC}
          1 {c |}{res}  0   .5    0   .5    0   .5 {c    |}
          2 {c |}{res} .5    1    0   .5    0   .5 {c    |}
          3 {c |}{res}  0   .5   .5    1    0   .5 {c    |}
          4 {c |}{res} .5    1   .5    1    0   .5 {c    |}
          5 {c |}{res}  0   .5    0   .5   .5    1 {c    |}
          6 {c |}{res} .5    1    0   .5   .5    1 {c    |}
          7 {c |}{res}  0   .5   .5    1   .5    1 {c    |}
          8 {c |}{res} .5    1   .5    1   .5    1 {c    |}		  
            {c BLC}{hline 29}{c BRC}
{txt}	



{marker int_widths}
{hline}
{bf:int_widths() -- Widths of intervals}


{title:Syntax}

{p 11 18 2}
{it:real matrix} {cmd:int_widths(}{it:real matrix X})

{p 4 4 2}
where

{p 12 18 2}
  {it:X}:  {it:real matrix} containing data (each pair of columns {it:i,i+1} of which represent intervals)
  {p_end}
  
{title:Description}

{pstd}
{cmd:int_widths()} computes the widths of the collection of interval column vectors represented by {it:X}. 
The midpoint of an interval is defined in the obvious way; the distance between the upper limit and the lower limit. 
When confronted with the interval (4,6), 
{cmd: int_widths()} returns the result 2.

{title: Remarks}

{pstd}
{cmd: int_widths()} does not check if it is in fact true that the lower limits of intervals are less than or equal to upper limits; hence, 
users must exert care that the numbers appearing in the odd columns {it: i} are less than their counterparts in even columns {it: i+1}.

{pstd}Examples:

Consider the addition of two interval vectors: 

{com}. mata: X=.1,.4 \ .15,.3 \10,12
{com}. mata: mid(X)
{res}           {txt}    1    2    3  
            {c TLC}{hline 14}{c TRC}
          1 {c |}{res} .3  .15    2 {c |}
{txt}            {c BLC}{hline 14}{c BRC}
{txt}
			
{title:Conformability}

{pstd}
{it:X} should have an even number of columns, where each pair of columns represents an interval vector. 
 Moreover, lower limits (entries in the first column) should be 
less than upper limits (entries in the second column). Some care must be exercised in assuring this, as {cmd: int_widths()} does not check
whether or not it is true.
{p_end}

{marker radius}
{hline}
{bf:radius() -- Radii of intervals}


{title:Syntax}

{p 11 18 2}
{it:real matrix} {cmd:radius(}{it:real matrix X})

{p 4 4 2}
where

{p 12 18 2}
  {it:X}:  {it:real matrix} containing data (each pair of columns {it:i,i+1} of which represent intervals)
  {p_end}
  
{title:Description}

{pstd}
{cmd:radius()} computes the radius of the collection of interval column vectors represented by {it:X}. 
The radius is simply the distance from the center of an interval to its upper (and lower) limit.
When confronted with the interval (4,6), for example, radius((4,6)) returns the result 1.

{title: Remarks}

{pstd}
{cmd: radius()} does not check if lower limits of intervals are less than or equal to upper limits; hence, 
users must exert care that the numbers appearing in the odd columns {it: i} are less than their counterparts 
in even columns {it: i+1}.

{pstd}Example:

{com}. mata: X=.1,.4 \ .15,.3 \10,12
{com}. mata: radius(X)
{res}           {txt}     1     2   3  
            {c TLC}{hline 15}{c TRC}
          1 {c |}{res} .15  .075   2 {c |}
{txt}            {c BLC}{hline 15}{c BRC}
{txt}
			
{title:Conformability}

{pstd}
{it:X} should have an even number of columns, where each pair of columns represents an interval vector. 
 Moreover, lower limits (entries in the first column) should be 
less than upper limits (entries in the second column). Some care must be exercised in assuring this, as {cmd:radius()} does not check
whether or not it is true.
{p_end}

{marker r_up}
{hline}
{bf:r_up() -- Round numbers up}


{title:Syntax}

{p 11 18 2}
{it:real matrix} {cmd:r_up(}{it:real matrix X, real scalar digits})

{p 4 4 2}
where

{p 12 18 2}
  {it:X}:  {it:real matrix} containing data. 
  {p_end}
  
{title:Description}

{pstd}
{cmd:r_up()} rounds numbers up according to the decimal places indicated by {it: digits}. 


{pstd}Example:

{com}. mata: X=.1234567891234
{com}. mata: r_up(X,1e-4)
{res}   .124
{txt}
			
{title:Conformability}

{pstd}
{it:X} can be any real matrix.
{p_end}

{marker r_down}
{hline}
{bf:r_down() -- Round numbers down}


{title:Syntax}

{p 11 18 2}
{it:real matrix} {cmd:r_down(}{it:real matrix X, real scalar digits})

{p 4 4 2}
where

{p 12 18 2}
  {it:X}:  {it:real matrix} containing data. 
  {p_end}
  
{title:Description}

{pstd}
{cmd:r_down()} rounds numbers down according to the decimal places indicated by {it: digits}. 


{pstd}Example:

{com}. mata: X=.1234567891234
{com}. mata: r_down(X,1e-4)
{res}   .123
{txt}
			
{title:Conformability}

{pstd}
{it:X} can be any real matrix.
{p_end}

{title:Author}

{p 4 4 2}
Matthew Baker, Hunter College and the Graduate Center, CUNY, mjbaker@hunter.cuny.edu{p_end}

{title:References}

{p 4 4 2}
Jaulin, Luc, Michel Kieffer, Oliver Didrit, and Eric Walter. 2001. {it:Applied Interval Analysis}. London: Springer. 
{p_end}

{p 4 4 2}
Moore, Ramon E., R. Baker Kearfott, and Michael J. Cloud. 2009. {it:Introduction to Interval Analysis}. Philadelphia: SIAM.
{p_end}
