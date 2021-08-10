*Auxiliary file for hlp2winpdf
program define eraseps
	version 9.2
	syntax anything
	foreach file of local anything {
		erase `file'.ps
	}
end
