*! xtnondynthreshsfa version 1.0.0
*! Performs Estimations of Threshold Effects 
*! in Panel Data Stochastic Frontier Models
*! Diallo Ibrahima Amadou
*! All comments are welcome, 25Apr2024



capture program drop xtnondynthreshsfa
program xtnondynthreshsfa, eclass
	version 17.0
	syntax anything [if] [in] [, * ]
	capture {
		which xthreg
	}
	if _rc {
		display as error "The package {bf:xtnondynthreshsfa} rely on the package {bf:xthreg}." 
		display as error "Hence you must install {bf:xthreg} to make {bf:xtnondynthreshsfa} work." 
		display as error "To install the package {bf:xthreg} from within {bf:Stata}, please click on these two lines successively:"
		display as error `"{stata "quietly net from http://www.stata-journal.com/software/sj15-1"}"'
		display as error `"{stata "net install st0373, replace"}"'
		exit 199
	}
	xthreg `0'

end


