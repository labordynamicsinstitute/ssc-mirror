*! 1.03, Yongli Chen, Yujun Lian, 2023/5/11
*         2023/5/11 14:25  ihelp
*         2023/2/17 14:25  hhelp

/*
    < hhelp cmd, opts >  
      is a short version of  
    < ihelp cmd, opts web >
*/

cap program drop hhelp 
program define hhelp 
version 8
    if strpos(`"`0'"', ","){  // with option 
		local colon ""
	}
	else{                     // without option 
		local colon ","
	}
	
    ihelp `0' `colon' web
   
end 
