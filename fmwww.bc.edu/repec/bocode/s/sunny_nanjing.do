cd "E:\益友学术\鼎园会计124期\report"
sysuse auto, clear

* Basic correlation matrix
sysuse auto, clear
corr2tex price mpg weight, saving("table1.tex") replace

* Matrix with significance stars
corr2tex price mpg headroom trunk, saving("corr.tex") ///
	star decimal(2) replace

* Publication-ready table with all options
corr2tex price mpg headroom trunk length, ///
	saving("corr_matrix.tex") replace ///
	star decimal(3) landscape threeline ///
	label title("Vehicle Characteristics Correlation Matrix") ///
	note("Data from 1978 Automobile Survey; N = 74")

