#delim ;
program define esetran;
version 10.0;
/*
 Transform estimates and standard errors in parmest resultssets
 using one of a range of Normalizing
 and variance-stabilizing transformations,
 promoting them to double precision
 and recoding non-missing values beyond system limits
 to system limits.
*!Author: Roger Newson
*!Date: 14 April 2015
*/

syntax varlist(numeric min=2 max=2) [if] [in] , TRansformation(string);
/*
 varlist is a list of 2 numeric variables,
 assumed to be the estimate and standard error variables
 in a parmest resultsset.
*/

*
 Check transformation
*;
cap assert inlist(`"`transformation'"',"log","logit","atanh","asin");
if _rc {;
  disp as error "Unrecognised transf(" `"`transformation'"' ")";
  error 498;
};

*
 Recast estimate and standard error variables to double
*;
local estimate: word 1 of `varlist';
local stderr: word 2 of `varlist';
qui recast double `estimate' `stderr';

marksample touse;

*
 Do transformation
*;
if "`transformation'"=="log" {;
  qui {;
    replace `estimate'=. if `touse' & `estimate'<0;
    replace `estimate'=c(smallestdouble) if `touse' & `estimate'>=0 & estimate<c(smallestdouble);
    replace `estimate'=c(maxdouble) if `touse' & estimate>c(maxdouble);
    replace `stderr'=`stderr'/`estimate' if `touse';
    replace `estimate'=log(`estimate') if `touse';
  };
};
else if "`transformation'"=="logit" {;
  qui {;
    replace `estimate'=. if `touse' & `estimate'<0;
    replace `estimate'=. if `touse' & `estimate'>1;
    replace `estimate'=c(smallestdouble) if `touse' & `estimate'>=0 & `estimate'<c(smallestdouble);
    replace `estimate'=1-c(epsdouble) if `touse' & `estimate'<=1 & `estimate'>1-c(epsdouble);
    replace `stderr'=`stderr'*( 1/`estimate' + 1/(1-`estimate') ) if `touse';
    replace `estimate'=logit(`estimate') if `touse';
  };
};
else if "`transformation'"=="atanh" {;
  qui {;
    replace `estimate'=. if `touse' & `estimate'<-1;
    replace `estimate'=. if `touse' & `estimate'>1;
    replace `estimate'=c(epsdouble)-1 if `touse' & `estimate'>=-1 & `estimate'<c(epsdouble)-1;
    replace `estimate'=1-c(epsdouble) if `touse' & `estimate'<=1 & `estimate'>1-c(epsdouble);
    replace `stderr'=`stderr'/(1-`estimate'*`estimate') if `touse';
    replace `estimate'=atanh(`estimate') if `touse';
  };
};
else if "`transformation'"=="asin" {;
  qui {;
    replace `estimate'=. if `touse' & `estimate'<-1;
    replace `estimate'=. if `touse' & `estimate'>1;
    replace `estimate'=c(epsdouble)-1 if `touse' & `estimate'>=-1 & `estimate'<c(epsdouble)-1;
    replace `estimate'=1-c(epsdouble) if `touse' & `estimate'<=1 & `estimate'>1-c(epsdouble);
    replace `stderr'=`stderr'/(sqrt(1-`estimate'*`estimate')) if `touse';
    replace `estimate'=asin(`estimate') if `touse';
  };
};

end;
