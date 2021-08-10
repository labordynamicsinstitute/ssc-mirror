* Read in Mplus output file and load parameter estimtes

version 10

capture program drop read_residual_variance
program define read_residual_variance , rclass 


syntax , out(string) 

if _N==0 {
   set obs 1
   tempvar thud
   gen `thud'=1
}

qui tempfile origdat
qui save `origdat', replace

set more off


qui infix str line 1-85 ///
      str name 1-19 ///
      str value 20-67 ///
      using `out' , clear
format line %85s


qui {


        * CONFIRM THERE IS AN R-SQUARE SECTION
        gen _foo1=_n if trim(line)=="R-SQUARE"
        su _foo1
        if r(N)==0 {
           exit
        }
        drop _foo1
        * CONFIRM THERE IS AN VARIANCE COLUMN 
        gen _foo1=_n if regexm(trim(lower(line)),"variance")==1
        su _foo1
        if r(N)==0 {
           exit
        }
        drop _foo1
        * IDENTIFY START AND END OF Parameter estimates
        gen linenum=_n
        gen x1=_n if (trim(line)=="R-SQUARE")|(trim(line)=="QUALITY OF NUMERICAL RESULTS")
        summarize x1
        keep if inrange(linenum,r(min)+1,r(max)-1)
        drop if trim(line)==""
        drop x1
        drop linenum
        gen linenum = _n
       
        * cleanup
        drop if substr(trim(line),1,8)=="Observed"
        drop if substr(trim(line),1,8)=="Variable"
        replace line=subinstr(line,"Latent Class","Class",.)
        list linenum line , clean
        * suffix
        gen suffix= lower(word(trim(line),2)) if wordcount(line)==2 & (substr(trim(line),1,5)=="Group"|substr(trim(line),1,5)=="Class")
        replace suffix=suffix[_n-1] if _n>1 & suffix==""

        *prefix
        gen prefix=line if (wordcount(line)==2|wordcount(line)==1) & (wordcount(line)==2 & (substr(trim(line),1,5)=="Group"|substr(trim(line),1,5)=="Class"))~=1
        replace prefix=lower(prefix)
        replace prefix=prefix[_n-1] if _n>1 & prefix==""
        
        * Second prefix
        gen eset =""
        replace eset = line if substr(trim(line),1,21)=="STDYX Standardization"
        replace eset = line if substr(trim(line),1,20)=="STDY Standardization"
        replace eset = line if substr(trim(line),1,19)=="STD Standardization"
        replace eset = "residual_variance" if substr(trim(line),1,8)=="R-SQUARE"
        replace eset = lower(eset)
        replace eset = subinstr(eset,"standardization","",.)
        replace eset = eset[_n-1] if _n>1 & eset==""
     
        * parameter
        gen parameter = lower(word(trim(line),1)) if (wordcount(line)==2 & substr(trim(line),1,5)=="Group")~=1
        
        * estimate
        gen estimate=word(trim(line),3) // word 3 only applies to residual variance
        replace estimate="" if estimate=="Undefined" 
        destring estimate, replace
       
        gen x = eset + " " + prefix + " " + parameter + " " + suffix
        replace x= eset + " " + word(line,1) + suffix if eset=="r-square"
        replace x=lower(x)
        
        replace x=trim(x)
        replace x = subinstr(x,"     "," ",.)
        replace x = subinstr(x,"    "," ",.)
        replace x = subinstr(x,"   "," ",.)
        replace x = subinstr(x,"  "," ",.)
        replace x = subinstr(x,"  "," ",.)
        replace x = subinstr(x,"observed two-tailed","",.)
        replace x = subinstr(x,"  "," ",.)
        replace x = subinstr(x,"  "," ",.)
        replace x = subinstr(x,"  "," ",.)
        replace x = subinstr(x,"new/additional parameters","new",.)
        
        * added 1/2/2009 by Frances Yang
        drop if regexm(x,"category")==1
        destring estimate , replace
      
       
        keep x estimate 
        rename estimate residual_variance
        
        capture matrix drop residual_variance
       
        local MS=_N
        capture set matsize `MS'
        if _rc==0 {
         set matsize `MS'
        }
        
             
        mkmat residual_variance , rownames(x)
        
        return matrix residual_variance = residual_variance
        
        qui use `origdat' , replace
        
}




end

