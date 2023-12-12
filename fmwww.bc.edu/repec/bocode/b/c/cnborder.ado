capture program drop cnborder

program cnborder
	version 14.0
	syntax,baidukey(string) address(string) [province_border(string) city_border(string) county_border(string) RADius(real 20)]
	
if "`baidukey'" == "" {
	di as error "error:must specify `baidukey'"
	exit 198
}

if "`address'" == "" {
	di as error "error:must specify `address' "
	exit 198
}
qui cap findfile cngcode.ado
    if  _rc>0 {
		disp as error "command cngcode is unrecognized,you need install cngcode from ssc "
		exit 601
	} 


tempvar eastlat eastlong westlat westlong northlat northlong southlat southlong northeastlat northeastlong northwestlat northwestlong southeastlat southeastlong southwestlat southwestlong prov_border1 prov_border2 prov_border3 prov_border4 prov_border5 prov_border6 prov_border7 prov_border8 city_border1 city_border2 city_border3 city_border4 city_border5 city_border6 city_border7 city_border8 county_border1 county_border2 county_border3 county_border4 county_border5 county_border6 county_border7 county_border8

if "`province_border'" == "" local province_border province_border
if "`city_border'" == "" local city_border city_border
if "`county_border'" == "" local county_border county_border



qui gen `eastlat' = .
qui gen `eastlong' = .
qui gen `westlat' = .
qui gen `westlong' = .
qui gen `northlat' = .
qui gen `northlong' = .
qui gen `southlat' = .
qui gen `southlong' = .
qui gen `northeastlat' = .
qui gen `northeastlong' = .
qui gen `northwestlat' = .
qui gen `northwestlong' = .
qui gen `southeastlat' = .
qui gen `southeastlong' = .
qui gen `southwestlat' = .
qui gen `southwestlong' = .	

qui gen `province_border' = 0
qui gen `prov_border1' = 0
qui gen `prov_border2' = 0
qui gen `prov_border3' = 0
qui gen `prov_border4' = 0
qui gen `prov_border5' = 0
qui gen `prov_border6' = 0
qui gen `prov_border7' = 0
qui gen `prov_border8' = 0

qui gen `city_border' = 0
qui gen `city_border1' = 0
qui gen `city_border2' = 0
qui gen `city_border3' = 0
qui gen `city_border4' = 0
qui gen `city_border5' = 0
qui gen `city_border6' = 0
qui gen `city_border7' = 0
qui gen `city_border8' = 0


qui gen `county_border' = 0
qui gen `county_border1' = 0
qui gen `county_border2' = 0
qui gen `county_border3' = 0
qui gen `county_border4' = 0
qui gen `county_border5' = 0
qui gen `county_border6' = 0
qui gen `county_border7' = 0
qui gen `county_border8' = 0


cngcode,baidukey(`baidukey') fulladdress(`address') lat(yes1) long(yes2)
cnaddress,baidukey(`baidukey') latitude(yes1) longitude(yes2) country(couyesss) province(provyesss) city(ciyesss) district(disyesss) street(stryesss) address(addyesss)

drop couyesss stryesss addyesss


qui forvalues i = 1/`=_N'{
	replace `eastlat' = yes1[`i'] in `i'
	replace `eastlong' = yes2[`i'] +`radius'/(111*cos(yes1[`i']*_pi/180)) in `i'
	replace `westlat' = yes1[`i'] in `i'
	replace `westlong' = yes2[`i']-`radius'/(111*cos(yes1[`i']*_pi/180)) in `i'
	replace `northlat' = yes1[`i'] + `radius'/111 in `i'
	replace `northlong' = yes2[`i'] in `i'
	replace `southlat' = yes1[`i']-`radius'/111 in `i'
	replace `southlong' = yes2[`i'] in `i'

	replace `northeastlat' = yes1[`i'] + `radius'/2^0.5/111 in `i'
	replace `northeastlong' = yes2[`i'] + `radius'/2^0.5/(111*cos((yes1[`i'] + `radius'/2^0.5/111)*_pi/180)) in `i'
	replace `northwestlat' = yes1 + `radius'/2^0.5/111 in `i'
	replace `northwestlong' = yes2 - `radius'/2^0.5/(111*cos((yes1[`i'] + `radius'/2^0.5/111)*_pi/180)) in `i'
	replace `southeastlat' = yes1 - `radius'/2^0.5/111 in `i'
	replace `southeastlong' = yes2 + `radius'/2^0.5/(111*cos((yes1[`i'] + `radius'/2^0.5/111)*_pi/180)) in `i'
	replace `southwestlat' = yes1[`i'] - `radius'/2^0.5/111 in `i'
	replace `southwestlong' = yes2[`i'] - `radius'/2^0.5/(111*cos((yes1[`i'] + `radius'/2^0.5/111)*_pi/180)) in `i'
}


cnaddress,baidukey(`baidukey') latitude(`eastlat') longitude(`eastlong') country(counnooo) province(provnooo) city(citnooo) district(disnooo) street(strnooo) address(addnooo)
local retypgq counnooo provnooo citnooo disnooo strnooo addnooo
qui forvalues i = 1/`=_N'{
	if provyesss[`i']!=provnooo[`i']{
		replace `prov_border1' = 1 in `i'
	}
	if ciyesss[`i']!=citnooo[`i']{
		replace `city_border1' = 1 in `i'
	}
	if disyesss[`i']!=disnooo[`i']{
		replace `county_border1' = 1 in `i'
	}
	
}

drop `retypgq'
cnaddress,baidukey(`baidukey') latitude(`westlat') longitude(`westlong') country(counnooo) province(provnooo) city(citnooo) district(disnooo) street(strnooo) address(addnooo)
qui forvalues i = 1/`=_N'{
	if provyesss[`i']!=provnooo[`i']{
		replace `prov_border2' = 1 in `i'
	}
	if ciyesss[`i']!=citnooo[`i']{
		replace `city_border2' = 1 in `i'
	}
	if disyesss[`i']!=disnooo[`i']{
		replace `county_border2' = 1 in `i'
	}	

}
drop `retypgq'

cnaddress,baidukey(`baidukey') latitude(`northlat') longitude(`northlong') country(counnooo) province(provnooo) city(citnooo) district(disnooo) street(strnooo) address(addnooo)
qui forvalues i = 1/`=_N'{
	if provyesss[`i']!=provnooo[`i']{
		replace `prov_border3' = 1 in `i'
	}
	if ciyesss[`i']!=citnooo[`i']{
		replace `city_border3' = 1 in `i'
	}
	if disyesss[`i']!=disnooo[`i']{
		replace `county_border3' = 1 in `i'
	}	

}
drop `retypgq'

cnaddress,baidukey(`baidukey') latitude(`southlat') longitude(`southlong') country(counnooo) province(provnooo) city(citnooo) district(disnooo) street(strnooo) address(addnooo)
qui forvalues i = 1/`=_N'{
	if provyesss[`i']!=provnooo[`i']{
		replace `prov_border4' = 1 in `i'
	}
	if ciyesss[`i']!=citnooo[`i']{
		replace `city_border4' = 1 in `i'
	}
	if disyesss[`i']!=disnooo[`i']{
		replace `county_border4' = 1 in `i'
	}	

}
drop `retypgq'

cnaddress,baidukey(`baidukey') latitude(`northeastlat') longitude(`northeastlong') country(counnooo) province(provnooo) city(citnooo) district(disnooo) street(strnooo) address(addnooo)
qui forvalues i = 1/`=_N'{
	if provyesss[`i']!=provnooo[`i']{
		replace `prov_border5' = 1 in `i'
	}
	if ciyesss[`i']!=citnooo[`i']{
		replace `city_border5' = 1 in `i'
	}
	if disyesss[`i']!=disnooo[`i']{
		replace `county_border5' = 1 in `i'
	}	

}
drop `retypgq'

cnaddress,baidukey(`baidukey') latitude(`northwestlat') longitude(`northwestlong') country(counnooo) province(provnooo) city(citnooo) district(disnooo) street(strnooo) address(addnooo)
qui forvalues i = 1/`=_N'{
	if provyesss[`i']!=provnooo[`i']{
		replace `prov_border6' = 1 in `i'
	}
	if ciyesss[`i']!=citnooo[`i']{
		replace `city_border6' = 1 in `i'
	}
	if disyesss[`i']!=disnooo[`i']{
		replace `county_border6' = 1 in `i'
	}	

}
drop `retypgq'

cnaddress,baidukey(`baidukey') latitude(`southeastlat') longitude(`southeastlong') country(counnooo) province(provnooo) city(citnooo) district(disnooo) street(strnooo) address(addnooo)
qui forvalues i = 1/`=_N'{
	if provyesss[`i']!=provnooo[`i']{
		replace `prov_border7' = 1 in `i'
	}
	if ciyesss[`i']!=citnooo[`i']{
		replace `city_border7' = 1 in `i'
	}
	if disyesss[`i']!=disnooo[`i']{
		replace `county_border7' = 1 in `i'
	}	

}
drop `retypgq'

cnaddress,baidukey(`baidukey') latitude(`southwestlat') longitude(`southwestlong') country(counnooo) province(provnooo) city(citnooo) district(disnooo) street(strnooo) address(addnooo)
qui forvalues i = 1/`=_N'{
	if provyesss[`i']!=provnooo[`i']{
		replace `prov_border8' = 1	 in `i'						
	}
	if ciyesss[`i']!=citnooo[`i']{
		replace `city_border8' = 1 in `i'						
	}
	if disyesss[`i']!=disnooo[`i']{
		replace `county_border8' = 1	 in `i'						
	}	

}
drop `retypgq' yes1 yes2 provyesss ciyesss disyesss




qui forvalues i = 1/`=_N'{
	replace `province_border' = `prov_border1'[`i']+ `prov_border2'[`i']+ `prov_border3'[`i']+ `prov_border4'[`i']+ `prov_border5'[`i']+ `prov_border6'[`i']+ `prov_border7'[`i']+ `prov_border8'[`i']  in `i'
	replace `city_border' = `city_border1'[`i']+ `city_border2'[`i']+ `city_border3'[`i']+ `city_border4'[`i']+ `city_border5'[`i']+ `city_border6'[`i']+ `city_border7'[`i']+ `city_border8'[`i']  in `i'
	replace `county_border' = `county_border1'[`i']+ `county_border2'[`i']+ `county_border3'[`i']+ `county_border4'[`i']+ `county_border5'[`i']+ `county_border6'[`i']+ `county_border7'[`i']+ `county_border8'[`i']  in `i'
	
	if `province_border'[`i']!=0{
	replace `province_border' = 1 in `i'
	}
	if `city_border'[`i']!=0{
	replace `city_border' = 1 in `i'
	}
	if `county_border'[`i']!=0{
	replace `county_border' = 1 in `i'
	}
		
}



end









