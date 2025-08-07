* 指定输出路径
cd "E:\益友学术\鼎园会计125期\report"

* 调用数据集	
sysuse auto, clear
sumtex price mpg weight, stats(mean sd) saving("table1.tex") replace
sumtex price mpg weight, stats(mean sd) rotate saving("table2.tex") replace
sumtex price, saving(price_stats.tex) stats(count mean sd p25 p50 p75) replace
sumtex price mpg, saving(table3.tex) rotate landscape title("Vehicle Characteristics")
sumtex, saving(full.tex) stats(count mean sd min max) threeline replace
* 测试最小简写
sumtex price mpg weight, stats(mean sd) sav("table4.tex") replace
sumtex price mpg weight, stat(mean sd) rotate saving("table5.tex") replace
sumtex price mpg weight, stats(mean sd) rot saving("table6.tex") replace
sumtex price mpg weight, stats(mean sd) rotate saving("table7.tex") rep
sumtex price mpg, saving(table8.tex) rotate landscape ti("Vehicle Characteristics")
sumtex, saving(full2.tex) stats(count mean sd min max) three replace
sumtex price mpg, saving(table9.tex) rotate land title("Vehicle Characteristics")

* 调用用户数据集asure.dta
cd "E:\益友学术\鼎园会计125期\report"
use "E:\益友学术\鼎园会计125期\data\asure.dta", clear
label var ESG "ESG"    // Comprehensive score
sumtex ESG NCSKEW DUVOL, saving("asure_stats.tex") ///
     stats(count mean sd min max p25 p50 p75 p90 p99) ///
     title("ESG Dataset Summary") ///
     threeline replace
sumtex ESG E得分 S得分 G得分 NCSKEW DUVOL soe cg dz up, saving("asure_stats2.tex") ///
    stats(count mean sd min max p25 p50 p75 p90 p99 skewness kurtosis) ///
    title("ESG Dataset Summary") rotate ///
    threeline replace
	