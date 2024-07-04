


program epichecks, rclass

	version 11 
	
	syntax, diaryid(string) 
	
	*disp as text "epichecks .... looks for missing values in START and END"
	
	epicheck1, diaryid(`diaryid')
	epicheck2, diaryid(`diaryid')
	epicheck3, diaryid(`diaryid')
	epicheck4, diaryid(`diaryid')
			
end

	
