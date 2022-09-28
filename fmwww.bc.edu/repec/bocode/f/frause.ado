*! v 0.1 Loads data from my PWS site
program frause, 
	version 9
	syntax [anything(everything)], [* version]
	if "`0'"=="" | "`version'"!="" {
		display "version: 1"
		addr scalar version = 1
		exit
	}
	qui:webuse set https://friosavila.github.io/playingwithstata/data2
	webuse `0'
	qui:webuse set
end
 
program addr, rclass
	return `0'
end
 