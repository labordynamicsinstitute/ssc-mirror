.-
help for ^matdrop^                                         
.-


Deletion of multiple row and/or column using labels from matrix
---------------------------------------------------------------

^matdrop^ matrix [ , ^r^(^rownames^) ^c^(^columnnames^)]


Description
-----------

Given a matrix, ^matdrop^ deletes all specified row names, or all specified
column names, or both together. 

^matdrop^ command will not delete (i.e. annihilate) entire row vectors or
entire column vectors.


Options
-------
r(^rownames^) specifies rownames or row labels. ^rownames^ should be a list of
row names (no need to specify as string) without comma.

c(^columnnames^) specifies columnnames or column labels. ^columnnames^ should be a list of 
column names (no need to specify as string)  without comma.



Example 
-------

    .matrix define A = (1, 2, 3 \ 4, 5, 6 \ 7, 8, 9)
	
	.matrix rownames A = r1 r2 r3
	
	.matrix colnames A = c1 c2 c3
	
	.^matdrop A, c(c3)^
	 
	 Also, 
	 
	.^matdrop A, r(r1 r3) c(c2)^
	
	
Author
------
         Niranjan Kumar
         Centre for Advanced Financial Research and Learning 
	     niranjan.kumar@cafral.org.in
	     nirnajanducic@gmail.com



   
   

