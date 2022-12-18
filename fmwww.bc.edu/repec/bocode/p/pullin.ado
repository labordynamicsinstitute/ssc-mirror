cap program drop pullin

program pullin
	version 11
	syntax varlist using
	merge m:1 `varlist' `using', keep(1 3) nogen
end