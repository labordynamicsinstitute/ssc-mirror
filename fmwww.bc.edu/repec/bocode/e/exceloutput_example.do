*example of how to place multiple columns of output across different regressions using exceloutput


local regs "price mpg rep78"
local titles "Price Mpg Rep78"
local cells "B1 D1 F1"


sysuse auto

quietly {
putexcel set example.xlsx, replace

putexcel A2="Trunk"
putexcel A4="Weight"
putexcel A6="Length"
putexcel A8="Ymean"
putexcel A9="R2"
putexcel A10="N"
}


foreach var of local regs { 
	gettoken title titles : titles
	gettoken cell cells : cells
	reg `var' trunk weight length
	exceloutput `cell', be(3) ti("`title'") d
	}




 