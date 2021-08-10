.-
help for ^dissim_index^
.-

Dissimilarity index
-------------------

    ^dissim_index^ varlist [^if^ exp] [^in^ range] [ ^,^ ^m^atrix^(^matname^)^ ]

Description
-----------

^dissim_index^ displays the dissimilarity index D for each pair of variables
in varlist. If x and y are >= 0, form the proportions

    p = x / SUM x   and   q = y / SUM y

and calculate D = 1/2 SUM ( | p - q | ). D lies in [0, 1].

Remark: ^dissim_index^ is a new name for a program originally called ^dissim^. 
Calls to ^help dissim^ now call up an official Stata help file. 
Thanks to Chen Samulsion, who pointed this out on Statalist.


Options
-------

^matrix(^matname^)^ specifies that results are to be placed in matrix
    matname.


Examples
--------

        . ^dissim_index a b c^


Author
------

         Nicholas J. Cox, University of Durham, U.K.
         n.j.cox@@durham.ac.uk

