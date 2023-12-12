capture program drop tiva2023_compile
program define tiva2023_compile
	
	local package_files = "tiva2023_matainitclass.mata tiva2023_mataimportfunctions.mata tiva2023_matacommoniciofunctions.mata tiva2023_mataoecdindicators.mata tiva2023_mataMYindicators.mata tiva2023_matastore.mata tiva2023_mataUpDownIndicators.mata"
	foreach f of local package_files {
		findfile `f'
		qui run `r(fn)'
		}

	mata: mata mlib create ltiva2023, replace dir(PLUS)
	mata: mata mlib add ltiva2023 tiva2023() tiva2023_oecdindicators() tiva2023_commonICIO() tiva2023_MYindicators() tiva2023_UpDownIndicators(), dir(PLUS) 
	
end


