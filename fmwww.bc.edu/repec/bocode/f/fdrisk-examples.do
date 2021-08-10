*!fdrisk-examples
*Allow easier execution of the examples for fdrisk
version 12.0
args argument
*False discovery risk with 95% confidence level:
if "`argument'"=="example1"{
	noisily disp `"fdrisk, nulllo(log(1/1.1)) nullhi(log(1.1))  stderr(0.8) nullspace(log(1/1.1) log(1.1)) altspace("2-1*invnorm(1-0.05/2)*0.8" "2+1*invnorm(1-0.05/2)*0.8") level(95)"'
	noisily fdrisk, nulllo(log(1/1.1)) nullhi(log(1.1))  stderr(0.8) nullspace(log(1/1.1) log(1.1))  ///
		   altspace("2-1*invnorm(1-0.05/2)*0.8" "2+1*invnorm(1-0.05/2)*0.8") level(95) 
	}
	
	*False discovery risk with 1/8 likelihood support level:
if "`argument'"=="example2a"{
	noisily disp `"fdrisk, nulllo(log(1/1.1)) nullhi(log(1.1)) stderr(0.8) nullspace(0) altspace("2-1*invnorm(1-0.041/2)*0.8" "2+1*invnorm(1-0.041/2)*0.8") likelihood(0.125)"'	
	noisily fdrisk, nulllo(log(1/1.1)) nullhi(log(1.1)) stderr(0.8) nullspace(0) /// 
		 altspace("2-1*invnorm(1-0.041/2)*0.8" "2+1*invnorm(1-0.041/2)*0.8") likelihood(0.125)
	}
	
	*with truncated normal weighting distribution:
if "`argument'"=="example2b"{
	noisily disp `"fdrisk, nulllo(log(1/1.1)) nullhi(log(1.1)) stderr(0.8) nullspace(0) alttruncnormal altspace("2-1*invnorm(1-0.041/2)*0.8" "2+1*invnorm(1-0.041/2)*0.8") likelihood(0.125)"'
	noisily fdrisk, nulllo(log(1/1.1)) nullhi(log(1.1)) stderr(0.8) nullspace(0) alttruncnormal ///
		altspace("2-1*invnorm(1-0.041/2)*0.8" "2+1*invnorm(1-0.041/2)*0.8") likelihood(0.125)
}

*False discovery risk with LSI and wider null hypothesis:
if "`argument'"=="example3"{
	noisily disp `"fdrisk, nulllo(log(1/1.5)) nullhi(log(1.5)) stderr(0.8) nullspace(0) altspace("2.5-1*invnorm(1-0.041/2)*0.8" "2.5+1*invnorm(1-0.041/2)*0.8")  likelihood(0.125)"'
	noisily fdrisk, nulllo(log(1/1.5)) nullhi(log(1.5)) stderr(0.8) nullspace(0) ///
	altspace("2.5-1*invnorm(1-0.041/2)*0.8" "2.5+1*invnorm(1-0.041/2)*0.8")  likelihood(0.125)
}
*False confirmation risk example:
if "`argument'"=="example4"{
	noisily disp `"fdrisk, fcr nulllo(log(1/1.5)) nullhi(log(1.5)) stderr(0.15) nullspace("0.01 - 1*invnorm(1-0.041/2)*0.15" "0.01 + 1*invnorm(1-0.041/2)*0.15") altspace(log(1.5) 1.25*log(1.5))  likelihood(0.125)"'
	noisily fdrisk, fcr nulllo(log(1/1.5)) nullhi(log(1.5)) stderr(0.15) /// 
	nullspace("0.01 - 1*invnorm(1-0.041/2)*0.15" "0.01 + 1*invnorm(1-0.041/2)*0.15") altspace(log(1.5) 1.25*log(1.5))  likelihood(0.125)
	}
		