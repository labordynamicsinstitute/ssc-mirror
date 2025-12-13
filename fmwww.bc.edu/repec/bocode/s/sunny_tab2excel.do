* Example 1: Basic usage with default options
	sysuse auto, clear
	tab2excel price mpg weight

* Example 2: Custom statistics with Chinese output
	tab2excel price mpg weight, language(chinese) ///
		statistics(n mean sd skew kurt min max) ///
		title("汽车数据统计摘要") filename("car_stats.xlsx") replace

* Example 3: English output with custom title
	tab2excel price mpg weight, language(english) ///
		statistics(n mean p25 p50 p75) ///
		title("Automobile Data Summary") filename("auto_summary.xlsx") replace

* Example 4: Using if condition
	tab2excel price mpg weight if foreign == 1, ///
		language(english) filename("foreign_cars.xlsx") replace

