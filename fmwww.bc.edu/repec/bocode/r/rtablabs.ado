#delim ;
program rtablabs;
version 16.0;
/*
 Label variables in a xsvmat resultsset
 from a transposed r(table) matrix.
 *!Author: Roger Newson
*!Date: 02 September 2026
*/

cap lab var b "coefficient value";
cap lab var se "standard error";
cap lab var t "test statistic for coefficient";
cap lab var z "test statistic for coefficient";
cap lab var pvalue "observed significance level for t/z";
cap lab var ll "lower limit of confidence interval";
cap lab var ul "upper limit of confidence interval";
cap lab var df "degrees of freedom associated with coefficient";
cap lab var crit "critical value associated with t/z";
cap lab var eform "indicator for exponentiated coefficients";

end;
