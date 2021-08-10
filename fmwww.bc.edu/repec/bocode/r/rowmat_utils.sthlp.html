{smcl}
{* Matthew J. Baker}
{* 8aug2014}{...}
{cmd:help rowmat_utils}
{hline}

{title:Title}
aug
{p 4 4 2}
{bf:rowmat_utils -- Mata functions to manipulate (square) matrices in parallel collected as rows of a larger matrix}

{title:Contents}

{col 5}{bf:help entry{col 41}Purpose}
{col 5}{hline}

{col 5}{bf:{help rowmat_utils##rm_matmult:rm_matmult()}{col 41} Multiply (row) matrices}{...}


{col 5}{bf:{help rowmat_utils##rm_matvecmult:rm_matvecmult()}{col 41} Multiply (row) matrices and vectors}{...}


{col 5}{bf:{help rowmat_utils##rm_vecvecmult:rm_vecvecmult()}{col 41} Multiply (row) vectors}{...}


{col 5}{bf:{help rowmat_utils##rm_newtinv:rm_newtinv()}{col 41} Invert (row) matrices}{...}


{col 5}{bf:{help rowmat_utils##rm_transpose:rm_transpose()}{col 41} Transpose (row) matrices}{...}


{col 5}{bf:{help rowmat_utils##rm_absrowsums:rm_absrowsums()}{col 41} Compute (row) matrices' absolute value row sums}{...}


{col 5}{bf:{help rowmat_utils##rm_absrowsums:rm_abscolsums()}{col 41} Compute (row) matrices' absolute value column sums}{...}


{col 5}{bf:{help rowmat_utils##rm_alpha0:rm_alpha0()}{col 41} Compute initial matrices for (newton) inversion}{...}


{title:Description}

{p 4 4 2}
The functions above are designed for use in situations in which one wishes to do a large number of 
matrix operations in parallel. For example, suppose that one has a data set consisting of N observations,
where N is a large number, and, for each observation, matrix multiplication, transposition, inversion, etc. of some
n -by- n matrix is required. Rather than looping over N observations and inverting a matrix for each observation, the routines above might 
instead be employed by rendering each nXn matrix as a 1-by-(n^2) row vector and applying the above operations.
 The above-listed operations perform
the listed operations {it: in parallel}, looping over matrix entries, and therefore might run a bit faster than looping over observations. 
For example, {com: newtinv()} could be used to compute inverses for a large
number of observations in parallel. 

{p 4 4 2}
 
For examples as to how the above operations work, see the individual help entries.

{hline}

{title:Description of individidual operations}

{hline}
{marker rm_matmult}
{bf:rm_matmult() -- Multiply in parallel square matrices with entries written as single rows}


{title:Syntax}

{p 11 18 2}
{it:real matrix} {cmd:rm_matmult(}{it:real matrix X, real matrix Y})

{p 4 4 2}
where

{p 12 18 2}
  {it:X}:  {it:real matrix} containing data (each row of which represents the entries, in order, of a square matrix)
  {p_end}
{p 12 18 2}
  {it:Y}:  {it:real matrix} containing data (each row of which represents the entries, in order, of a square matrix)
  {p_end}

{title:Description}

{pstd}
{cmd:rm_matmult()} multiplies sequences of matrices in parallel. The idea is, in situations in which a large number
of similar matrix multiplications must be carried out, to do so in parallel.

{pstd}{it:X} and {it:Y} provide the sequences of matrices to be multiplied and must be of the same dimension. 

{title:Remarks}

{pstd}Examples:

Consider the sets of matrices: 

{com}. mata: X1=1,2,3 \ 4,5,6 \ 7,8,9 
{com}. mata: X2=2,3,4 \ 5,6,7 \ 8,9,10
{com}. mata: Y1=3,4,5 \  6,7,8 \ 9,10,11
{com}. mata: Y2=4,5,6 \ 7,8,9 \ 10,11,12 
{com}. mata: X1*Y1
        {res}      {txt}   1    2    3
            {c TLC}{hline 17}{c TRC}
          1 {c |}{res}   42   48   54{txt}  {c |}
          2 {c |}{res}   96  111  126{txt}  {c |}
          3 {c |}{res}  150  174  198{txt}  {c |}
            {c BLC}{hline 17}{c BRC}

{com}. mata: X2*Y2
        {res}      {txt}   1    2    3
            {c TLC}{hline 17}{c TRC}
          1 {c |}{res}   69   78   87{txt}  {c |}
          2 {c |}{res}  132  150  168{txt}  {c |}
          3 {c |}{res}  195  222  249{txt}  {c |}
            {c BLC}{hline 17}{c BRC}

{com}. mata: X1=rowshape(X1,1)
{com}. mata: X2=rowshape(X2,1)
{com}. mata: X=X1\X2
{com}. mata: Y1=rowshape(Y1,1)
{com}. mata: Y2=rowshape(Y2,1)
{com}. mata: Y=Y1\Y2
{com}. mata: rm_matmult(X,Y)
{res}              {txt}   1    2    3    4    5    6    7    8    9   
            {c TLC}{hline 47}{c TRC}
          1 {c |}{res}   42   48   54   96  111  126  150  174  198 {txt} {c  |}
          2 {c |}{res}   69   78   87  132  150  168  195  222  249 {txt} {c  |}
            {c BLC}{hline 47}{c BRC}
		
			
{title:Conformability}

{pstd}
The rows of {it:X} and {it:Y} must be conformable square matrices. Thus, in general {it: X,Y} should 
have 1,4,9,16,etc. rows and N columns. 
{p_end}

{title:Additional Comments}

{pstd}
No special attempt at efficiently multiplying the matrices has been made; 
like other {bf:{help rowmat_utils}}, {com: rm_matmult()}
might be useful in situations where the primary need is to do a large number of matrix multiplications and doing
them in parallel conveys an advantage over looping over matrices. That is, looping is over entries of the matrix, not over matrices. 
{p_end}

{hline}
{marker rm_matvecmult}

{bf:rm_matvecmult() -- Multiply in parallel (square) matrices and vectors with entries written as single rows}

{title:Syntax}

{p 11 18 2}
{it:real matrix} {cmd:rm_matvecmult(}{it:real matrix X, real matrix y})

{p 4 4 2}
where

{p 12 18 2}
  {it:X}:  {it:real matrix} containing data (each row of which represents the entries, in order, of a square matrix)
  {p_end}
{p 12 18 2}
  {it:y}:  {it:real matrix} containing data (each row of which represents the entries, in order, of a vector)
  {p_end}

{title:Description}

{pstd}
{cmd:rm_matvecmult()} multiplies sequences of matrices and vectors in parallel. The idea is, in situations in which a large number
of similar matrix-vector multiplications must be carried out, to do so in parallel.

{pstd}{it:X} and {it:y} provide the sequences of matrices and vectors, respectively, 
to be multiplied and must be conformable. 

{title:Remarks}

{pstd}Examples:

Consider the sets of matrices and (column) vectors: 

{com}. mata: X1=1,2,3 \ 4,5,6 \ 7,8,9 
{com}. mata: X2=2,3,4 \ 5,6,7 \ 8,9,10
{com}. mata: y1=3 \4 \ 5
{com}. mata: y2=4\ 5 \ 6  
{com}. mata: X1*Y1
        {res}      {txt}  1 
            {c TLC}{hline 6}{c TRC}
          1 {c |}{res}  26{txt}  {c |}
          2 {c |}{res}  62{txt}  {c |}
          3 {c |}{res}  98{txt}  {c |}
            {c BLC}{hline 6}{c BRC}

{com}. mata: X2*Y2
        {res}      {txt}   1 
            {c TLC}{hline 6}{c TRC}
          1 {c |}{res}   47{txt} {c |}
          2 {c |}{res}   92{txt} {c |}
          3 {c |}{res}  137{txt} {c |}
            {c BLC}{hline 6}{c BRC}

{com}. mata: X1=rowshape(X1,1)
{com}. mata: X2=rowshape(X2,1)
{com}. mata: X=X1\X2
{com}. mata: y1=y1'
{com}. mata: y2=y2'
{com}. mata: Y=y1\y2
{com}. mata: rm_matvecmult(X,y)
{res}              {txt}   1    2    3     
            {c TLC}{hline 17}{c TRC}
          1 {c |}{res}   26   62   98 {txt} {c  |}
          2 {c |}{res}   47   92  137 {txt} {c  |}
            {c BLC}{hline 17}{c BRC}
		
			
{title:Conformability}

{pstd}
{it:X} and {it:y} must be conformable; if the individual matrices represented by {it: X} is n-by-n (and therefore 1 -by- n^2 
when written as a row, {it: y} should represent vectors that are n-by-1 (or 1 -by- n when
represented as a row). Thus, {it: X} should be of dimension N-by-n^2 and y should be
of dimension N-by-n.  
{p_end}

{title:Additional Comments}
{pstd}
No special attempt at efficiently executing matrix-vector multiplication has
been attempted. Like other {bf:{help rowmat_utils}}, {com: rm_matvecmult()}
will be used in situations where the primary need is to do a large number of matrix-vector multiplications and doing
them in parallel conveys an advantage over looping. Looping is over entries of the matrix, not over matrices. 
{p_end}

{hline}
{marker rm_vecvecmult}

{bf:rm_vecvecmult() -- Scalar (dot) products of vectors in parallel, with entries written as single rows}


{title:Syntax}

{p 11 18 2}
{it:real matrix} {cmd:rm_vecvecmult(}{it:real matrix x, real matrix y})

{p 4 4 2}
where

{p 12 18 2}
  {it:x}:  {it:real matrix} containing data (each row of which represents the entries of a vector)
  {p_end}
{p 12 18 2}
  {it:y}:  {it:real matrix} containing data (each row of which represents the entries of a vector)
  {p_end}

{title:Description}

{pstd}
{cmd:rm_vecvecmult()} multiplies sequences of vectors in parallel. The idea is, in situations in which a large number
of similar vector-vector multiplications must be carried out, to do so in parallel.

{pstd}{it:x} and {it:y} provide the sequences of vectors to be multiplied and must be conformable. 

{title:Remarks}

{pstd}Examples:

Consider the sets of matrices and (column) vectors: 

{com}. mata: x1=1 \2 \ 3 
{com}. mata: x2=2 \3 \ 4
{com}. mata: y1=3 \4 \ 5
{com}. mata: y2=4 \5 \ 6  
{com}. mata: x1'y1
 {res}  26 

{com}. mata: x2'y2
 {res}  47 
 
{com}. mata: x1=x1'
{com}. mata: x2=x2'
{com}. mata: x=x1\x2
{com}. mata: y=y1\y2
{com}. mata: rm_vecvecmult(x,y)
{res}           {txt}   1      
            {c TLC}{hline 4}{c TRC}
          1 {c |}{res} 26 {c    |}
          2 {c |}{res} 47 {c    |}
            {c BLC}{hline 4}{c BRC}
{txt}
			
{title:Conformability}

{pstd}
{it:x} and {it:y} must be conformable (i. e., vectors of the same length). Thus, {it: x} should be of  dimension N-by-n 
and y should be of dimension N-by-n.  
{p_end}

{title:Additional Comments}

{pstd}
No special attempt at efficiently executing vector-vector multiplication has
been attempted. Like other {bf:{help rowmat_utils}}, {com: rm_vecvecmult()}
will be useful in situations where the primary need is to do a large number of matrix-vector multiplications and doing
them in parallel conveys an advantage over looping. In fact, {com: rm_vecvecmult()} is identical to computing the row products
using the colon operator; in the example, this would be, {bf: rowsum(X:*Y)}.
{p_end}

{hline}
{marker rm_newtinv}

{bf:rm_newtinv() -- Invert a sequence of matrices written as rows of a larger matrix in parallel using Newton iteration}

{title:Syntax}

{p 8 21 2}{it:real matrix} {cmd:rm_newtinv(}{it:A}{cmd:,} {it:maxiter}{cmd:,}
{it:crit})

{p 4 4 2}
where

{p 11 21 2}
  {it:A}:  {it:real matrix} containing data (each row of which represents the entries, in order, of a square matrix)
  {p_end}
{p 5 21 2}
  {it:maxiter}:  {it:real scalar} containing the number of maximum iterations {cmd: rm_newtinv()} will do in finding inverses. Often, a relatively 
  small number of iterations is sufficient (i.e., in the neighborhood of 20 maximum iterations)
  {p_end}
{p 8 21 2}
  {it:crit}: {it:real scalar} containing the convergence criterion; when improvements across all matrices are smaller than this value,
  {cmd: rm_newtinv()} stops. A suitable criterion might be something in the neighborhoood of 1e-12.

{title:Description}

{pstd}
{cmd:rm_newtinv()} carries out simultaneous matrix inversion of a sequence of matrices which are all written as rows of a larger data matrix. 
{cmd:rm_newtinv()} uses all the mata functions listed in {bf:{help rowmat_utils}} to accomplish this. The idea is to accomplish matrix inversion
of the sequence of matrices in parallel, avoiding having to loop over matrices to find inverses. 

{title:Remarks}

{pstd}The approach followed by {cmd: rm_newtinv()} is outlined in Pan and Schreiber (1990), who build on Shulz (1933), which originally proposed newton iteration
for computing the inverse of a nonsingular matrix A. 

{pstd}Consider a sequence of matrices, X[k],k=0,1,3,...,n. The inverse of A is sought. Newton inversion proceeds by iterating 

{p 8 21 2}X[k+1]=X[k](2I-AX[k])

{pstd}Until convergence of the sequence of matrices X[k]. The resulting matrix X[k] is an (arbitrarily close) approximation of the inverse of A. 
While there are more efficient and stable ways to invert a single matrix, Newton iteration has the advantage in that it is easily applied to many
matrices in parallel, and is relatively stable. 

{pstd}Of course, any iterative procedure requires a starting point, and convergence often depends upon good starting values. Pan and Schreiber (1990)
note that Ben-Israel and Cohen (1966) show that for a sufficiently small value of a scalar a0, X[0]=a0*A', results in convergence. While one can achieve more rapid
convergence with other choices of a, Pan and Schreiber (1990) show that choosing:

{p 8 21 2}a0=1/(A_1*A_inf)

{pstd}where A_1 denotes the largest of the absolute value of the row sums of the matrix, and A_inf is the largest of the absolute value of the column sums of
the matrix A (the p=1 norm and the p=infinity norm of the matrix A, respectively). The companion function {bf:{help rowmat_utils##rm_alpha0:rm_alpha0()}} calculates this starting value
for matrices written in row form. 

{pstd}Examples:

Consider the sets of matrices: 

{com}. mata: A1=2,5,1 \ 3,4,5 \ 4,4,2 
{com}. mata: A2=3,3,1 \ 1,2,3 \ 4,5,2
{com}. mata: luinv(A1)
        {res}      {txt}           1              2              3
            {c TLC}{hline 45}{c TRC}
          1 {c |}{res} -.2857142857   -.1428571429             .5{txt}  {c |}
          2 {c |}{res}  .3333333333              0   -.1666666667{txt}  {c |}
          3 {c |}{res} -.0952380952    .2857142857   -.1666666667{txt}  {c |}
            {c BLC}{hline 45}{c BRC}

{com}. mata: luinv(A2)
        {res}      {txt}           1              2              3
            {c TLC}{hline 45}{c TRC}
          1 {c |}{res}  1.833333333    .1666666667   -1.666666667{txt}  {c |}
          2 {c |}{res} -1.666666667   -.3333333333    1.333333333{txt}  {c |}
          3 {c |}{res}           .5             .5            -.5{txt}  {c |}
            {c BLC}{hline 45}{c BRC}

{com}. mata: A1=rowshape(A1,1)
{com}. mata: A2=rowshape(A2,1)
{com}. mata: A=A1\A2
{com}. mata: rm_newtinv(A,30,1e-12)
        {res}      {txt}           1              2              3              4             5              6              7             8              9
            {c TLC}{hline 133}{c TRC}
          1 {c |}{res} -.2857142857   -.1428571429             .5    .3333333333   1.27202e-17   -.1666666667   -0.952380952   .2857142857   -.1666666667{txt}  {c |}
          2 {c |}{res}  1.833333333    .1666666667   -1.166666667   -1.666666667   -.333333333    1.333333333             .5            .5             .5{txt}  {c |}
            {c BLC}{hline 133}{c BRC}

		
			
{title:Conformability}

{pstd}
The rows of {it:A} must be conformable square matrices. Thus, in general {it: A} should 
have 1,4,9,16,etc. rows and N columns, where N is some number of matrices that need to be inverted. 
{p_end}

{title:Additional Comments}
{pstd}
No special attempt at performing the necessary matrix operations has been made; if one is interested in how multiplication, transposition, 
norm computation, etc. are carried out, see the entries in {help: rowmat_utils}. {cmd: rm_newtinv()} is not efficient for small jobs, but is intended for use
in situations where one must quickly invert a large number of relatively small matrices. Essentially {cmd: rm_newtinv()} replaces the task of looping over matrices
and inverting each one, with the combined tasks of successive iterations and looping over entries of the matrix. 
{p_end}

{hline}
{marker rm_transpose}
{bf:rm_transpose() -- Transposes of an array of matrices written in single-row form}


{title:Syntax}

{p 11 18 2}
{it:real matrix} {cmd:rm_transpose(}{it:real matrix X})

{p 4 4 2}
where

{p 12 18 2}
  {it:X}:  {it:real matrix} containing data (each row of which represents the entries of a vector)
  {p_end}

{title:Description}

{pstd}
{cmd:rm_transpose()} computes the transposes of a group of matrices, each of which is written in single-row form, in parallel. The
idea is to avoid looping over a large number of matrices.

{pstd}Examples:

Consider the sets of matrices: 

{com}. mata: X1=1,2,3 \ 4,5,6 \ 7,8,9 
{com}. mata: X2=2,3,4 \ 5,6,7 \ 8,9,10
{com}. mata: X1'
        {res}   {txt}    1   2   3
            {c TLC}{hline 12}{c TRC}
          1 {c |}{res}  1   4   7{txt} {c |}
          2 {c |}{res}  2   5   8{txt} {c |}
          3 {c |}{res}  3   6   9{txt} {c |}
            {c BLC}{hline 12}{c BRC}
{com}. mata: X2'
        {res}   {txt}    1   2   3
            {c TLC}{hline 12}{c TRC}
          1 {c |}{res}  2   5   8{txt} {c |}
          2 {c |}{res}  3   6   9{txt} {c |}
          3 {c |}{res}  4   7  10{txt} {c |}
            {c BLC}{hline 12}{c BRC}
{com}. mata: X1=rowshape(X1,1)
{com}. mata: X2=rowshape(X2,1)
{com}. mata: X=X1 \ X2
{com}. mata: rm_transpose(X)
{res}              {txt}  1   2   3   4   5   6   7   8   9   
            {c TLC}{hline 38}{c TRC}
          1 {c |}{res}   1   4   7   2   5   8   3   6   9 {txt} {c  |}
          2 {c |}{res}   2   5   8   3   6   9   4   7  10 {txt} {c  |}
            {c BLC}{hline 38}{c BRC}
{txt}
			
{title:Conformability}

{pstd}
{it:X} must be a list of square n-by-n matrices, which then occupy together a single N-by-n^2 matrix.  
{p_end}

{title:Additional Comments}

{pstd}
The intent is that,
like other {bf:{help rowmat_utils}}, {cmd: rm_transpose()}
will be useful in situations where the primary need is to do a large number of matrix computations and doing
them in parallel conveys an advantage over looping. Essentially, {cmd: rm_transpose()} replaces the task of looping over matrices
with the task of looping over the entries of many matrices simultaneously. 
{p_end}

{hline}
{marker rm_absrowsums}

{bf:rm_absrowsums() -- Row sums of absolute values of a sequence of matrices written in single-row form}


{title:Syntax}

{p 11 18 2}
{it:real matrix} {cmd:absrowsums(}{it:real matrix X})

{p 4 4 2}
where

{p 12 18 2}
  {it:X}:  {it:real matrix} containing data (each row of which represents the entries of a square matrix)
  {p_end}

{title:Description}

{pstd}
{cmd:rm_absrowsums()} computes the row sums of the absolute values of a matrix, where each matrix is written in single-row form,
 in parallel. The idea is to perform the operation while avoiding looping over a large number of matrices.

{pstd}Examples:

Consider the sets of matrices and (column) vectors: 

{com}. mata: X1=1,-2,3 \ 4,5,-6 \ 7,-8,9 
{com}. mata: X2=2,-3,4 \ 5,-6,7 \ 8,-9,10
{com}. mata: rowsum(abs(X1))
        {res}   {txt}    1 
            {c TLC}{hline 4}{c TRC}
          1 {c |}{res}  6{txt} {c |}
          2 {c |}{res} 15{txt} {c |}
          3 {c |}{res} 24{txt} {c |}
            {c BLC}{hline 4}{c BRC}
{com}. mata: rowsum(abs(X2))
        {res}   {txt}    1 
            {c TLC}{hline 4}{c TRC}
          1 {c |}{res}  9{txt} {c |}
          2 {c |}{res} 18{txt} {c |}
          3 {c |}{res} 27{txt} {c |}
            {c BLC}{hline 4}{c BRC}


{com}. mata: X1=rowshape(X1,1)
{com}. mata: X2=rowshape(X2,1)
{com}. mata: X=X1 \ X2
{com}. mata: rm_absrowsums(X)
{res}            {txt}  1   2   3     
            {c TLC}{hline 11}{c TRC}
          1 {c |}{res} 6  15  24{txt} {c |}
          2 {c |}{res} 9  18  27{txt} {c |}
            {c BLC}{hline 11}{c BRC}
{txt}
			
{title:Conformability}

{pstd}
{it:X} must be a list of square n-by-n matrices, which then occupy together a single N-by-n^2 matrix.  
{p_end}

{title:Additional Comments}

{pstd}
Like other {bf:{help rowmat_utils}}, {com: rm_absrowsums()}
will be useful in situations where the primary need is to do a large number of matrix computations and doing
them in parallel conveys an advantage over looping. Looping is over entries in the matrix, not over matrices.
{p_end}

{hline}
{marker rm_abscolsums}

{bf:rm_abscolsums() -- Column sums of absolute values of a sequence of matrices written in single-row form}


{title:Syntax}

{p 11 18 2}
{it:real matrix} {cmd:rm_abscolsums(}{it:real matrix X})

{p 4 4 2}
where

{p 12 18 2}
  {it:X}:  {it:real matrix} containing data (each row of which represents the entries of a square matrix)
  {p_end}

{title:Description}

{pstd}
{cmd:rm_abscolsums()} computes the row sums of the absolute values of a matrix, where each matrix is written in single-row form,
 in parallel. The idea is to perform the operation while avoiding looping over a large number of matrices.

{pstd}Examples:

Consider the sets of matrices and (column) vectors: 

{com}. mata: X1=1,-2,3 \ 4,5,-6 \ 7,-8,9 
{com}. mata: X2=2,-3,4 \ 5,-6,7 \ 8,-9,10
{com}. mata: colsum(abs(X1))
{res}            {txt}   1   2   3     
            {c TLC}{hline 12}{c TRC}
          1 {c |}{res} 12  15  18{txt} {c |}
            {c BLC}{hline 12}{c BRC}
{com}. mata: colsum(abs(X2))
{res}            {txt}   1   2   3     
            {c TLC}{hline 12}{c TRC}
          1 {c |}{res} 15  18  21{txt} {c |}
            {c BLC}{hline 12}{c BRC}

{com}. mata: X1=rowshape(X1,1)
{com}. mata: X2=rowshape(X2,1)
{com}. mata: X=X1 \ X2
{com}. mata: rm_abscolsums(X)
{res}            {txt}   1   2   3     
            {c TLC}{hline 12}{c TRC}
          1 {c |}{res} 12  15  18{txt} {c |}
          2 {c |}{res} 15  18  21{txt} {c |}
            {c BLC}{hline 12}{c BRC}
{txt}
			
{title:Conformability}

{pstd}
{it:X} must be a list of square n-by-n matrices, which then occupy together a single N-by-n^2 matrix.  
{p_end}

{title:Additional Comments}

{pstd}
Like other {bf:{help rowmat_utils}}, {com: rm_abscolsums()}
might be useful in situations where the primary need is to do a large number of matrix computations and doing
them in parallel conveys an advantage over looping. The operation is performed by looping over entries in the matrix, and not
looping over matrices. 
{p_end}

{hline}
{marker rm_alpha0}
{bf:rm_alpha0() -- Provides starting values for {cmd: rm_newtinv()}.}

{pstd}
For details and description see {bf:{help mf_rm_newtinv:rm_newtinv()}} and {bf:{help rowmat_utils}}.

{title:References}

{phang}Ben-Israel, A. and D. Cohen. 1966. "On iterative computation of generalized inverses and associated projections," SIAM Journal on Numerical Analysis 3: 410-9.

{phang}Pan, V. and R. Schreiber. 1991. "An improved Newton iteration for the generalized inverse of a matrix, with applications," SIAM Journal of Scientific and Statistical Computing 12:1109-31.

{phang}Schultz, G. 1933. "Iterative berechnung der Reziproken Matrix," Zeitschrift fuer Angewandte Mathematik and Mechanik 13: 57-9.

{title:Author}

{p 4 4 2} Matthew Baker, Hunter College and the Graduate Center, CUNY, mjbaker@hunter.cuny.edu
