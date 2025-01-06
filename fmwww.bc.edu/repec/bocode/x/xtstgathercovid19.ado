*! xtstgathercovid19 version 1.0.0
*! Downloads COVID-19 Data from Our World in Data 
*! Diallo Ibrahima Amadou
*! All comments are welcome, 03Jan2025



capture program drop xtstgathercovid19
program xtstgathercovid19, rclass
	version 17.0
	syntax , pathz(string asis) [ SAVing(string asis) ]
	quietly cd `pathz'
		display
		display _dup(78) "="
		display "Downloading COVID-19 Dataset"
		display "from Our World in Data."
		display "This may take some time. Please wait!"
		display _dup(78) "="
		display
		quietly import delimited "https://catalog.ourworldindata.org/garden/covid/latest/compact/compact.csv", clear
		if `"`saving'"' != "" {
			quietly save `saving'
		}	
	
end


