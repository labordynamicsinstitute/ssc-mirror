*! version 1.0.1 05jan2012 Daniel Klein

pr labundef ,rclass
	vers 9.2
	syntax [, Detach Detach_p(varlist)]
	
	* get labels in memory
	qui la di
	loc lbllist `r(names)'
	
	* check for undefined labels
	foreach v of varlist * {
		loc lbl : val l `v'
		if !(`: list lbl in lbllist') {
			if !(`: list lbl in undef') loc undef `undef' `lbl'
			loc `lbl' ``lbl'' `v'
		}
	}
	
	* report and drop
	loc n : word count `undef'
	di as txt `"`n' undefined value `= plural(`n', "label")'"'
	if !(`n') e 0 // done
	loc dtch = !("`detach'`detach_p'" == "")
	foreach l of loc undef {
		di as res "`l'" as txt " (" as res "``l''" as txt ")"
		if (`dtch') {
			foreach v of loc `l' {
				if ("`detach_p'" == "") la val `v'
				else if (`: list v in detach_p') la val `v'
			}
		}
	}
	ret loc labels `undef'
	foreach u of loc undef {
		ret loc `u' ``u''
	}
end
e

1.0.1	05jan2012	code polish
1.0.0	07oct2011	first version on SSC (labutil2)
