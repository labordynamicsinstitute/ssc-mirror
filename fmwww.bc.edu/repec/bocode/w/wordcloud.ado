*===================================================================================*
* Ado-file: 	WordCloud Version 1.0 
* Author: 		Shutter Zor(左祥太)
* Affiliation: 	Accounting Department, Xiamen University
* E-mail: 		Shutter_Z@outlook.com 
* Date: 		2024/7/23                                          
*===================================================================================*



capture program drop wordcloud_rgb_generator
program define wordcloud_rgb_generator, rclass
	version 14
	
	forvalues color_num = 1/`=_N' {
		local rgb_color_`color_num' = "rgb(" + string(int(runiform()*16)*10) ///
									+ "," + string(int(runiform()*16)*10) ///
									+ "," + string(int(runiform()*16)*10) + ")"
		return local rgb_color_`color_num' "`rgb_color_`color_num''"
	}
end

capture program drop wordcloud
program define wordcloud
	version 14
	
	if `=_N' == 0 {
		dis as error "You must loading you word frequency data first"
	}
	
	syntax, Name(varname) Value(varname) File(string) [Title(string) Label(string)]
	
	*- generate rgb color
	wordcloud_rgb_generator
	
	*- generate data
	forvalues data_index = 1/`=_N' {
		local word_name = `name'[`data_index']
		local word_value = `value'[`data_index']
		local wordcloud_data_`data_index' = "{'name':'`word_name'','value':'`word_value'','textStyle':{'normal':{'color':'`r(rgb_color_`data_index')''}}},"
	}
	
	*- generate html file
	qui file open wordcloud using `file', write replace
	file write wordcloud "<!DOCTYPE html>"
	file write wordcloud "<html>"
	file write wordcloud "<head>"
	file write wordcloud "<meta charset='UTF-8'>"
	file write wordcloud "<title>Awesome-wordcloud</title>"
	file write wordcloud "<script type='text/javascript' src='https://assets.pyecharts.org/assets/echarts.min.js'></script>"
	file write wordcloud "<script type='text/javascript' src='https://assets.pyecharts.org/assets/echarts-wordcloud.min.js'></script>"
	file write wordcloud "</head>"
	file write wordcloud "<body>"
	file write wordcloud "<div id='shutterzor' class='chart-container' style='width:1600px; height:900px;'></div>"
	file write wordcloud "<script>"
	file write wordcloud "var chart_option_by_shutter_zor = echarts.init("
	file write wordcloud "document.getElementById('shutterzor'), 'white', {renderer: 'canvas'});"
	file write wordcloud "var option_by_shutter_zor = {"
	file write wordcloud "'animation': true,"
	file write wordcloud "'animationThreshold': 2000,"
	file write wordcloud "'animationDuration': 1000,"
	file write wordcloud "'animationEasing': 'cubicOut',"
	file write wordcloud "'animationDelay': 0,"
	file write wordcloud "'animationDurationUpdate': 300,"
	file write wordcloud "'animationEasingUpdate': 'cubicOut',"
	file write wordcloud "'animationDelayUpdate': 0,"
	file write wordcloud "'color': ['#c23531','#2f4554','#61a0a8','#d48265','#749f83','#ca8622','#bda29a','#6e7074','#546570','#c4ccd3','#f05b72','#ef5b9c','#f47920','#905a3d','#fab27b','#2a5caa','#444693','#726930','#b2d235','#6d8346','#ac6767','#1d953f','#6950a1','#918597'],"
	
	if "`label'" == "" {
		file write wordcloud "'series': [{'type': 'wordCloud','name': 'Hot Analysis','shape': 'circle','rotationRange': [-90,90],'rotationStep': 45,'girdSize': 20,'sizeRange': [6,66],"
	}
	else {
		file write wordcloud "'series': [{'type': 'wordCloud','name': '`label'','shape': 'circle','rotationRange': [-90,90],'rotationStep': 45,'girdSize': 20,'sizeRange': [6,66],"
	}
	
	file write wordcloud "'data': ["

	forvalues data_index = 1/`=_N' {
		local wordcloud_data = "`wordcloud_data_`data_index''"
		file write wordcloud "`wordcloud_data'"
	}

	file write wordcloud "],"
	file write wordcloud "'drawOutOfBound': false,"
	file write wordcloud "'textStyle': {'emphasis': {}}}],"
	file write wordcloud "'legend': [{'data': [],'selected': {},'show': true,'padding': 5,'itemGap': 10,'itemWidth': 25,'itemHeight': 14}],"
	file write wordcloud "'tooltip': {'show': true,'trigger': 'item','triggerOn': 'mousemove|click','axisPointer': {'type': 'line'},'showContent': true,'alwaysShowContent': false,'showDelay': 0,'hideDelay': 100,'textStyle': {'fontSize': 14},'borderWidth': 0,'padding': 5},"
	
	if "`title'" == "" {
		file write wordcloud "'title': [{'text': 'Word Cloud in Stata','padding': 5,'itemGap': 10,'textStyle': {'fontSize': 23}}]};"
	}
	else {
		file write wordcloud "'title': [{'text': '`title'','padding': 5,'itemGap': 10,'textStyle': {'fontSize': 23}}]};"
	}

	file write wordcloud "chart_option_by_shutter_zor.setOption(option_by_shutter_zor);"
	file write wordcloud "</script>"
	file write wordcloud "</body>"
	file write wordcloud "</html>"
	file close wordcloud
	
	dis as result "You wordcloud file has been saved in `file'"
end


