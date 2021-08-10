use telomerase, clear
format y1 s1 y2 s2 %6.3f
l, noo clean
gen S11=s1^2
gen S22=s2^2

* UNIVARIATE
mvmeta y S, vars(y1) bscov
mvmeta y S, vars(y2) bscov
mvmeta y S, vars(y2) bscov nouncertainv

* BIVARIATE
mvmeta y S, corr(0) bscov

