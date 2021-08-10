*! version 5.2 28JUL2017  Kristoffer Bjarkefur kbjarkefur@worldbank.org

cap program drop 	iefolder
	program define	iefolder

qui {	
	
	syntax anything, PROJectfolder(string) [ABBreviation(string)]
	
	version 11
	
	***Todo
	*Test that old master do file exist
	*give error message if divisor is changed

	*Create an empty line before error message or output
	noi di ""
	
	/***************************************************
	
		Parse input
	
	***************************************************/	
	
	*Parse out the sub-command
	gettoken subcommand item : anything
	
	*Parse out the item type and the item name
	gettoken itemType itemName : item
    
	*Make sure that the item name is only one word
	gettoken itemName rest : itemName
	
	*Clean up the input
	local subcomand 	= trim("`subcommand'")
	local itemType 		= trim("`itemType'")
	local itemName 		= trim("`itemName'")
	local abbreviation 	= trim("`abbreviation'")
	
	*noi di "SubCommand 	`subcommand'"
	*noi di "ItemType 	`itemType'"
	*noi di "ItemName	`itemName'"

	 /***************************************************
	
		Test input
	
	***************************************************/
	
	*Test that the type is correct
	local sub_commands "new"
	local itemTypes "project round unitofobs"
	
	*Test if subcommand is valid
	if `:list subcommand in sub_commands' == 0 {

		noi di as error "{phang}You have not used a valid subcommand. See help file for details.{p_end}"
		error 198
	}	
	
	*Test if item type is valid
	if `:list itemType in itemTypes' == 0 {

		noi di as error "{phang}You have not used a valid item type. See help file for details.{p_end}"
		error 198
	} 
	
	*Test that item name is used when item type is anything but project
	else if ("`itemType'" != "project" & "`itemName'" == "" ) {
		
		noi di as error "{phang}You must specify a name of the `itemType'. See help file for details.{p_end}"
		error 198
	}
	
	
		*test that there is no space in itemname
	local space_pos = strpos(trim("`itemName'"), " ")
	if "`rest'" != ""  | `space_pos' != 0 {

		noi di as error `"{pstd}You have specified to many words in: [{it:iefolder `subcommand' `itemType' `itemName'`rest'}] or used a space in {it:itemname}. Spaces are not allowed in the {it:itemname}. Use underscores or camel case.{p_end}"'
		error 198
	}
	
	** Test that item name only includes numbers, letter, underscores and does 
	*  not start with a number. These are simplified requirements for folder 
	*  names on disk.
	if !regexm("`itemName'", "^[a-zA-Z][a-zA-Z0-9_]*[a-zA-Z0-9_]$") & "`itemType'" != "project" {
		
		noi di as error `"{pstd}Invalid {it:itemname}. The itemname [`itemName'] can only include letters, numbers or underscore and the first character must be a letter.{p_end}"'
		error 198
	}
	
	** Test that also the abbreviation has valid characters
	if !regexm("`abbreviation'", "^[a-zA-Z][a-zA-Z0-9_]*[a-zA-Z0-9_]$") & "`abbreviation'" != "" {
		
		noi di as error `"{pstd}Invalid name in the option {it:abbreviation()}. The name [`abbreviation'] can only include letters, numbers or underscore and the first character must be a letter.{p_end}"'
		error 198
	}	
	
	/***************************************************
	
		Start making updates to the project folder
	
	***************************************************/

	*Create a temporary textfile
	tempname 	newHandle	
	tempfile	newTextFile
	
	cap file close 	`newHandle'	
		file open  	`newHandle' using "`newTextFile'", text write append	
	
	
	*Create a global pointing to the main data folder
	global projectFolder	"`projectfolder'"
	global dataWorkFolder 	"$projectFolder/DataWork"
	global encryptFolder 	"$dataWorkFolder/EncryptedData"

	if "`subcommand'" == "new" {
	
		di "Subcommand: New"
		
		*Creating a new project
		if "`itemType'" == "project" {
			
			di "ItemType: Project"
			iefolder_newProject "$projectFolder" `newHandle'
			
			*Produce success output
			noi di "{pstd}Command ran succesfully, a new DataWork folder was created here:{p_end}"
			noi di "{phang2}1) [${dataWorkFolder}]{p_end}"
			
		}
		*Creating a new round
		else if "`itemType'" == "round" {
			
			*Use the full item name if abbrevaition was not specified
			if "`abbreviation'" == "" local abbreviation "`itemName'"
			
			di "ItemType: round"
			iefolder_newRound `newHandle' "`itemName'" "`abbreviation'"	
			
			*Produce success output
			noi di "{pstd}Command ran succesfully, for the round [`itemName'] the following folders and master dofile were created:{p_end}"
			noi di "{phang2}1) [${`abbreviation'}]{p_end}"
			noi di "{phang2}2) [${encryptFolder}/Round `itemName' Encrypted]{p_end}"
			noi di "{phang2}3) [${`abbreviation'}/`itemName'_MasterDofile.do]{p_end}"
		}
		*Creating a new level of observation for master data set
		else if "`itemType'" == "unitofobs" {
			
			di "ItemType: untiofobs/unitofobs"
			di `"iefolder_newMaster	`newHandle' "`itemName'""'
			iefolder_newUnitOfObs	`newHandle' "`itemName'"
			
			*Produce success output
			noi di "{pstd}Command ran succesfully, for the unit of observation [`itemName'] the following folders were created:{p_end}"
			noi di "{phang2}1) [${dataWorkFolder}/MasterData/`itemName']{p_end}"
			noi di "{phang2}2) [${encryptFolder}/Master `itemName' Encrypted]{p_end}"
		}
	}
	
	*Closing the new main master dofile handle
	file close 		`newHandle'
	
	*Copy the new master dofile from the tempfile to the original position
	copy "`newTextFile'"  "$dataWorkFolder/Project_MasterDofile.do" , replace
}	
end 	

/************************************************************

	Primary functions : creating each itemtype

************************************************************/

cap program drop 	iefolder_newProject
	program define	iefolder_newProject
		
		noi di "command ok" 
		
		args projectfolder newHandle
		
		noi di "args ok"
		*Test if folder where to create new folder exist
		checkFolderExists "$projectFolder" "parent"

		*Test that the new folder does not already exist
		checkFolderExists "$dataWorkFolder" "new"				
		
		noi di "folder check ok"
		
		mkdir "$dataWorkFolder"
		
		******************************
		*Writing master do file header
		******************************

		*Write intro part with description of project, 
		mdofle_p0 `newHandle' project

		*Write folder globals section header and the root folders
		mdofle_p1 `newHandle' "$projectFolder"

		*Write constant global section here
		mdofle_p2 `newHandle'

		*Write section that runs sub-master dofiles
		mdofle_p3 `newHandle' project	
		
		******************************
		*Create Global Setup Dofile
		******************************		
		
		*See this sub command below
		global_setup
		
end 


cap program drop 	iefolder_newRound
	program define	iefolder_newRound
	
	args subHandle rndName rndAbb 
	
	di "new round command"
	
	*Not encrypted branch
	
	*Test if folder where to create new folder exist
	checkFolderExists "$dataWorkFolder" "parent"
	*Test that the new folder does not already exist
	checkFolderExists "$dataWorkFolder/`rndName'" "new"		

	*Encrypted branch
	
	*Test if folder where to create new fodler exist
	checkFolderExists "$encryptFolder" "parent"
	*Test that the new folder does not already exist
	checkFolderExists "$encryptFolder/Round `rndName' Encrypted" "new"		
	
	*Old file reference
	tempname 	oldHandle
	local 		oldTextFile 	"$dataWorkFolder/Project_MasterDofile.do"

	file open `oldHandle' using `"`oldTextFile'"', read
	file read `oldHandle' line
	
	*Locals needed for the section devider
	local partNum 		= 0 //Keeps track of the part number
	
	while r(eof)==0 {
		
		*Do not interpret macros
		local line : subinstr local line "\$"  "\\$"
		local line : subinstr local line "\`"  "\\`"
		
		**Run funtion to read old project master dofile to check if any 
		* infomration should be added before this line
		parseReadLine `"`line'"'
	
		if `r(ief_line)' == 0 {

			*This is a regular line of code. It should be copied as-is. No action needed. 
			file write	`subHandle' `"`line'"' _n
		
		}
		else if `r(ief_line)' == 1 {

			di `"`line'"'
			**This is a line of code with a devisor written by 
			* iefodler. New additions to a section are always added right before an end of section line. 
			
			return list
			
			**This is NOT an end of section line. Nothing will be written here 
			* but we test that there is no confict with previous names
			if `r(ief_end)' == 0 {

					*Test if it is an end of globals section as we are writing a new 
					if "`r(sectionName)'" == "endRounds" {
					
					*Write devisor for this section
					writeDevisor 			`subHandle' 1 RoundGlobals rounds `rndName' `rndAbb' 
					
					*Write the globals for this round to the proejct master dofile
					newRndFolderAndGlobals 	`rndName' `rndAbb' "dataWorkFolder" `subHandle' project
				
					*Create the round master dofile and create the subfolders for this round
					createRoundMasterDofile "$dataWorkFolder/`rndName'" "`rndName'" "`rndAbb'"

					*Write an empty line before the end devisor
					file write		`subHandle' "" _n	
					
				}
				else {
				
					*Test that the folder name about to be used is not already in use 
					if "`r(itemName)'" == "`rndName'" {
						noi di as error "{phang}The new round name `rndName' is already in use. No new folders are creaetd and the master do-files has not been changed.{p_end}"
						error 507
					}
					
					*Test that the folder name about to be used is not already in use 
					if "`r(itemAbb)'" == "`rndAbb'" {
						noi di as error "{phang}The new round abbreviation `rndAbb' is already in use. No new folders are creaetd and the master do-files has not been changed.{p_end}"
						error 507
					}
				}
				
				*Copy the line as is
				file write		`subHandle' `"`line'"' _n
			}
			
			**This is an end of section line. We will add the new content here 
			* before writing the end of section line
			else if `r(ief_end)' == 1 {
				
				*Test if it is an end of globals section as we are writing a new 
				if "`r(partName)'" == "End_RunDofiles" {
					
					*Write devisor for this section
					writeDevisor 			`subHandle' 3 RunDofiles `rndName' `rndAbb' 
					
					*Write the 
					file write  `subHandle' ///
						_col(4)"if (0) { //Change the 0 to 1 to run the `rndName' master dofile" _n ///
						_col(8) `"do ""' _char(36) `"`rndAbb'/`rndName'_MasterDofile.do" "' _n ///
						_col(4)"}" ///
						_n
					
					*Write an empty line before the end devisor
					file write		`subHandle' "" _n	
					
				}
				
				*Write the end of section line
				file write		`subHandle' `"`line'"' _n	
			}
		}
		
		*Read next file and repeat the while loop
		file read `oldHandle' line
	}

	*Close the old file. 
	file close `oldHandle'

end


cap program drop 	iefolder_newUnitOfObs
	program define	iefolder_newUnitOfObs
	
	args subHandle obsName 
	
	di "new unitofobs command"

	global mastData 		"$dataWorkFolder/MasterData"
	
	*********************************************
	*Test if folder can be created where expected
	*********************************************
	
	*Not encrypted branch
	
	*Test if folder where to create new folder exist
	checkFolderExists "$mastData" "parent"
	*Test that the new folder does not already exist
	checkFolderExists "$mastData/`obsName'" "new"
	
	
	*Encrypted branch
	
	*Test if folder where to create new fodler exist
	checkFolderExists "$encryptFolder" "parent"
	*Test that the new folder does not already exist
	checkFolderExists "$encryptFolder/Master `obsName' Encrypted" "new"				
	
	*************
	*create folder in masterdata
	
	
	*Old file reference
	tempname 	oldHandle
	local 		oldTextFile 	"$dataWorkFolder/Project_MasterDofile.do"

	file open `oldHandle' using `"`oldTextFile'"', read
	file read `oldHandle' line
	
	*Locals needed for the section devider
	local partNum 		= 0 //Keeps track of the part number
	
	
	while r(eof)==0 {
		
		*Do not interpret macros
		local line : subinstr local line "\$"  "\\$"
		local line : subinstr local line "\`"  "\\`"
		
		parseReadLine `"`line'"'
		
		*Test if this is the location to write the new master data globals
		if `r(ief_line)' == 1 & `r(ief_line)' == 1 & `r(ief_end)' == 0  & "`r(sectionName)'" == "rawData" {
			
			*Create unit of observation data folder and add global to folder in master do file
			cap createFolderWriteGlobal "`obsName'"    "mastData"  	mastData_`obsName'	`subHandle' 

			if _rc == 693 {
			
				*If that folder exist, problem 
				noi di as error "{phang}could not create new folder, folder name might already exist "
				error _rc
		
			}
			else if _rc != 0 {
				
				*Unexpected error, run the exact command name again and throw the error to user
				createFolderWriteGlobal "`obsName'"   "mastData"  	mastData_`obsName'	`subHandle' 
			}
	
			*After adding new lines, keep adding the old line to the new file.
			file write		`subHandle' `"`line'"' _n
		}
		else {
			
			*Do not add new lines here, keep adding the old line to the new file.
			file write		`subHandle' `"`line'"' _n
		}
		
		*Read next file and repeat the while loop
		file read `oldHandle' line
	}
	
	*Close the old file. 
	file close `oldHandle'	
	
	*************
	*Create unit of observation data subfolders
	createFolderWriteGlobal "DataSet"  						"mastData_`obsName'"  	masterDataSets	
	createFolderWriteGlobal "Dofiles"  	 					"mastData_`obsName'"  	mastDataDo
	
	*************
	*create folder in encrypred ID key master	
	createFolderWriteGlobal "Master `obsName' Encrypted"  	"encryptFolder"  		mastData_E_`obsName'
	createFolderWriteGlobal "DataSet"  	 					"mastData_E_`obsName'"  mastData_E_data
	createFolderWriteGlobal "Sampling"   					"mastData_E_`obsName'"  mastData_E_Samp
	createFolderWriteGlobal "Treatment Assignment"			"mastData_E_`obsName'"  mastData_E_Treat	

end 



/************************************************************

	Sub-functions : functionality

************************************************************/

cap program drop 	parseReadLine 
	program define	parseReadLine, rclass
		
		args line
		
		*Tokenize each line 
		tokenize  `"`line'"' , parse("*")
		
		**Parse the beginning of the line to 
		* test if this line is an iefolder line
		local divisorStar  		"`1'"
		local divisorIefoldeer  "`2'"

		if `"`divisorStar'`divisorIefoldeer'"' != "*iefolder" {
			
			*This is not a iefolder divisor
			return scalar ief_line 	= 0
			return scalar ief_end 	= 0
		}
		else {
		
			*This is a iefolder divisor, 
			return scalar ief_line 	= 1		
			
			*parse the rest of the line (from tokenize above)
			local partNum  		"`4'"
			local partName 		"`6'"
			local sectionName 	"`8'"
			local itemName 		"`10'"
			local itemAbb	 	"`12'"
			
			*Return the part name and number. All iefolder divisor lines has this
			return local partNum  "`partNum'"
			return local partName "`partName'" 			
			
			*Get the prefix of the section name
			local sectPrefix = substr("`partName'",1,4)
			
			*Test if it is an end of section divisor
			if "`sectPrefix'" == "End_" {
			
				return scalar ief_end 	= 1
			}
			else {
				
				return scalar ief_end 	= 0
				
				*These are returned empty if they do not apply
				return local sectionNum 	"`sectionNum'" 
				return local sectionName	"`sectionName'" 
				return local sectionAbb 	"`sectionAbb'" 
				return local itemName		"`itemName'" 
				return local itemAbb 		"`itemAbb'" 
			}
		}

end
	
	
	
cap program drop 	newRndFolderAndGlobals 
	program define	newRndFolderAndGlobals 
		
		args rndName rnd dtfld_glb subHandle masterType
		
		*Write title to the folder globals to this round
		file write  `subHandle'	_col(4)"*`rndName' folder globals" _n

		*Round main folder	
		if "`masterType'" == "round"  	createFolderWriteGlobal "`rndName'" "`dtfld_glb'" "`rnd'" 	`subHandle'
		if "`masterType'" == "project"  writeGlobal 			"`rndName'" "`dtfld_glb'" "`rnd'" 	`subHandle'
		
		*Sub folders
		if "`masterType'" == "round"  	createFolderWriteGlobal "DataSets" 	"`rnd'" 	"`rnd'_dt" 	`subHandle'
		if "`masterType'" == "project"  writeGlobal 			"DataSets" 	"`rnd'" 	"`rnd'_dt" 	`subHandle'

		if "`masterType'" == "round"  	createFolderWriteGlobal "Dofiles" 	"`rnd'"		"`rnd'_do" 	`subHandle'
		if "`masterType'" == "project"  writeGlobal 			"Dofiles" 	"`rnd'"		"`rnd'_do" 	`subHandle'

		if "`masterType'" == "round"  	createFolderWriteGlobal "Output" 	"`rnd'"		"`rnd'_out"	`subHandle'
		if "`masterType'" == "project"  writeGlobal 			"Output" 	"`rnd'"		"`rnd'_out"	`subHandle'
		
		*This are never written to the master dofile, only created 
		if "`masterType'" == "round" createFolderWriteGlobal "Documentation"  "`rnd'"	"`rnd'_doc"	
		if "`masterType'" == "round" createFolderWriteGlobal "Questionnaire"  "`rnd'"	"`rnd'_quest"		
	

end
	
cap program drop 	createRoundMasterDofile 
	program define	createRoundMasterDofile 	
	
		args roundfolder rndName rnd
		
		*Create a temporary textfile
		tempname 	roundHandle
		tempfile	roundTextFile
		file open  `roundHandle' using "`roundTextFile'", text write replace	
		
		*Write intro part with description of round, 
		mdofle_p0 	`roundHandle' round
		mdofle_p1	`roundHandle' "$projectFolder" `rndName' `rnd'
		
		*Encrypted round sub-folder
		file write  `roundHandle'	_n	_col(4)"*Encrypted round sub-folder globals" _n 
		createFolderWriteGlobal "Round `rndName' Encrypted" 	"encryptFolder" "`rnd'_encrypt" `roundHandle'
		createFolderWriteGlobal "Raw Identified Data"  			"`rnd'_encrypt" "`rnd'_dtRaw" 	`roundHandle'
		createFolderWriteGlobal "Dofiles Import"				"`rnd'_encrypt" "`rnd'_doImp" 	`roundHandle'
		createFolderWriteGlobal "High Frequency Checks"			"`rnd'_encrypt" "`rnd'_HFC" 	`roundHandle'
		
		*DataSets sub-folder
		file write  `roundHandle' _n	_col(4)"*DataSets sub-folder globals" _n
		createFolderWriteGlobal "Intermediate" 					"`rnd'_dt" 		"`rnd'_dtInt" 	`roundHandle'
		createFolderWriteGlobal "Final"  						"`rnd'_dt" 		"`rnd'_dtFin" 	`roundHandle'
		
		*Dofile sub-folder
		file write  `roundHandle' _n	_col(4)"*Dofile sub-folder globals" _n
		createFolderWriteGlobal "Cleaning"				 		"`rnd'_do" 		"`rnd'_doCln" 	`roundHandle'
		createFolderWriteGlobal "Construct"				 		"`rnd'_do" 		"`rnd'_doCon" 	`roundHandle'
		createFolderWriteGlobal "Analysis"				 		"`rnd'_do" 		"`rnd'_doAnl" 	`roundHandle'
		
		*Output subfolders
		file write  `roundHandle' _n	_col(4)"*Output sub-folder globals" _n
		createFolderWriteGlobal "Raw" 							"`rnd'_out"	 	"`rnd'_outRaw"	`roundHandle'		
		createFolderWriteGlobal "Final" 						"`rnd'_out"		"`rnd'_outFin"	`roundHandle'
	
		*Questionnaire subfolders
		file write  `roundHandle' _n	_col(4)"*Questionnaire sub-folder globals" _n
		createFolderWriteGlobal "Questionnaire Develop" 		"`rnd'_quest"	"`rnd'_qstDev"			
		createFolderWriteGlobal "Questionnaire Final" 			"`rnd'_quest"	"`rnd'_qstFin"	
		createFolderWriteGlobal "PreloadData"	 				"`rnd'_quest"	"`rnd'_prld"	`roundHandle'
		createFolderWriteGlobal "Questionnaire Documentation"	"`rnd'_quest"	"`rnd'_doc"		`roundHandle'
		
		*Write sub devisor starting master and monitor data section section
		writeDevisor 	`roundHandle' 1 End_FolderGlobals	
		
		*Write constant global section here
		mdofle_p2 `roundHandle'
		
		mdofle_p3 `roundHandle' round `rndName' `rnd'
		
		*Closing the new main master dofile handle
		file close 		`roundHandle'

		*Copy the new master dofile from the tempfile to the original position
		copy "`roundTextFile'"  "`roundfolder'/`rndName'_MasterDofile.do" , replace
	
end
	
cap program drop 	createFolderWriteGlobal 
	program define	createFolderWriteGlobal 

		args  folderName parentGlobal globalName subHandle 

		*Create a global for this folder
		global `globalName' "$`parentGlobal'/`folderName'"
		
		*If a subhandle is specified then write the global to the master file
		if ("`subHandle'" != "") {
			writeGlobal "`folderName'" `parentGlobal' `globalName' `subHandle'
		}

		mkdir "${`parentGlobal'}/`folderName'"
				
end

cap program drop 	writeGlobal 
	program define	writeGlobal 

	args  folderName parentGlobal globalName subHandle 

	*Create a global for this folder
	global `globalName' "$`parentGlobal'/`folderName'"

	*Write global in round master dofile if subHandle is specified
	file write  `subHandle' 							///
		_col(4) `"global `globalName'"' _col(34) `"""' 	///
		_char(36)`"`parentGlobal'/`folderName'" "' _n 

end 



cap program drop 	writeDevisor 
	program define	writeDevisor , rclass
		
		args  subHandle partNum partName sectionName itemName itemAbb 
		
		local devisor "*iefolder*`partNum'*`partName'*`sectionName'*`itemName'*`itemAbb'*"
		
		local devisorLen = strlen("`devisor'")
		
		*Make all devisors at least 80 characters wide by adding stars
		if (`devisorLen' < 80) {
			
			local numStars = 80 - `devisorLen'
			local addedStars _dup(`numStars') _char(42)
		}
		
		file write  `subHandle' _n "`devisor'" `addedStars'
		file write  `subHandle' _n "*iefolder will not work properly if the line above is edited"  _n _n
		
end
	
*Program that checks if folder exist and provide errors if not. 
cap program drop 	checkFolderExists 
	program define	checkFolderExists , rclass	
	
		args folder type
		
		*Returns 0 if folder does not exist, 1 if it does
		mata : st_numscalar("r(dirExist)", direxists("`folder'"))
		
		** If type is parent folder, i.e. the folder in which we are creating a 
		*  new folder, then the parent folder should exist. Throw an error if it doesn't
		if `r(dirExist)' == 0 & "`type'" == "parent" {
		
			noi di as error `"{phang}A new folder cannot be created in "`folder'" as that folder does not exist. iefolder will not work properly if the names of the folders it depends on are changed.{p_end}"' 
			error 693
			exit
		}
		
		** If type is new folder, i.e. the folder we are creating, 
		*  then that folder should not exist. Throw an error if it does		
		if `r(dirExist)' == 1 & "`type'" == "new" {
			
			noi di as error `"{phang}The new folder cannot be created since the folder "`folder'" already exist. You may not use the a name twice for the same type of folder.{p_end}"' 
			error 693
			exit
		}
	
end
	
/************************************************************

	Sub-functions : writing master dofiles

************************************************************/
	
cap program drop 	mdofle_p0
	program define	mdofle_p0 
		
		args subHandle itemType rndName task
		
		file write  `subHandle' ///
			_col(4)"* ******************************************************************** *" _n ///
			_col(4)"* ******************************************************************** *" _n ///
			_col(4)"*" _col(75) "*" _n ///
			_col(4)"*" _col(20) "your_`itemType'_name" _col(75) "*" _n ///
			_col(4)"*" _col(20) "MASTER DO_FILE" _col(75) "*" _n ///
			_col(4)"*" _col(75) "*" _n ///
			_col(4)"* ******************************************************************** *" _n ///
			_col(4)"* ******************************************************************** *" _n ///
			_n _col(8)"/*" _n 
		
		if "`itemType'" == "project" { 
		
			file write  `subHandle'	/// 
				_col(8)"** PURPOSE:" _col(25) "Write intro to project here" _n ///
				_n ///					
				_col(8)"** OUTLINE:" _col(25) "PART 0: Standardize settings and install packages" _n ///
				_col(25) "PART 1: Set globals for dynamic file paths" _n ///
				_col(25) "PART 2: Set globals for constants and varlist" _n ///
				_col(32) "used across the project. Intall custom" _n ///
				_col(32) "commands needed." _n ///
				_col(25) "PART 3: Call the task specific master do-files " _n ///
				_col(32) "that call all do-files needed for that " _n ///
				_col(32) "tas. Do not include Part 0-2 in a task" _n ///
				_col(32) "specific master do-file" _n ///
				_n _n
		} 
		else if "`itemType'" == "round" {
			
			file write  `subHandle'	/// 
				_col(8)"** PURPOSE:" _col(25) "Write intro to survey round here" _n ///
				_n ///					
				_col(8)"** OUTLINE:" _col(25) "PART 0: Standardize settings and install packages" _n ///
				_col(25) "PART 1: Preparing folder path globals" _n ///
				_col(25) "PART 2: Run the master do files for each high level task" _n _n 
		}
				
		file write  `subHandle'	/// 
			_col(8)"** IDS VAR:" _col(25) "list_ID_var_here		//Uniquely identifies households (update for your project)" _n ///
			_n	///				  
			_col(8)"** NOTES:" _n /// 	  
			_n ///				  
			_col(8)"** WRITEN BY:" _col(25) "names_of_contributors" _n ///
			_n ///
			_col(8)"** Last date modified: `c(current_date)'" _n /// 
			_col(8)"*/" _n
		
		*Write devisor starting setting standardize section
		writeDevisor  `subHandle' 0 StandardSettings 
				
				
		file write  `subHandle'	/// 		
			_col(4)"* ******************************************************************** *" _n ///
			_col(4)"*" _n ///
			_col(4)"*" _col(12) "PART 0:  INSTALL PACKAGES AND STANDARDIZE SETTINGS" _n ///
			_col(4)"*" _n ///
			_col(4)"*" _col(16) "-Install packages needed to run all dofiles called" _n ///
			_col(4)"*" _col(17) "by this master dofile." _n ///
			_col(4)"*" _col(16) "-Use ieboilstart to harmonize settings across users" _n ///
			_col(4)"*" _n ///								
			_col(4)"* ******************************************************************** *" _n  

		*Write devisor ending setting standardize section
		writeDevisor `subHandle' 0 End_StandardSettings
		
		file write  `subHandle' 	///							
			_col(8)"*Install all packages that this project requires:" _n ///
			_col(8)"ssc install ietoolkit, replace" _n ///
			_n	 ///
			_col(8)"*Standardize settings accross users" _n ///
			_col(8)"ieboilstart, version(12.1)" _col(40) "//Set the version number to the oldest version used by anyone in the project team" _n ///
			_col(8) _char(96)"r(version)'" 		_col(40) "//This line is needed to actually set the version from the command above" _n
			
		
end
	

cap program drop 	mdofle_p1
	program define	mdofle_p1

		args   subHandle projectfolder rndName rndAbb

		*Write devisor starting globals section
		writeDevisor  `subHandle' 1 FolderGlobals

		file write  `subHandle' 	///
			_col(4)"* ******************************************************************** *" _n ///
			_col(4)"*" _n ///	
			_col(4)"*" _col(12) "PART 1:  PREPARING FOLDER PATH GLOBALS" _n ///
			_col(4)"*" _n ///			
			_col(4)"*" _col(16) "-Set the global box to point to the project folder" _n ///
			_col(4)"*" _col(17) "on each collaborators computer." _n /// 
			_col(4)"*" _col(16) "-Set other locals that point to other folders of interest." _n /// 
			_col(4)"*" _n ///	
			_col(4)"* ******************************************************************** *" _n
					
		file write  `subHandle' ///
			_n ///	
			_col(4)"* Users" _n ///
			_col(4)"* -----------" _n ///
			_n ///
			_col(4)"*User Number:" _n ///
			_col(4)"* You" _col(30) "1" _col(35) `"//Replace "You" with your name"' _n ///
			_col(4)"* Next User" _col(30) "2" _col(35) "//Assign a user number to each additional collaborator of this code" _n ///
			_n ///
			_col(4)"*Set this value to the user currently using this file" _n ///
			_col(4)"global user  1" _n ///
			_n ///
			_col(4)"* Root folder globals" _n ///
			_col(4)"* ---------------------" _n ///
			_n ///	
			_col(4)"if "_char(36)"user == 1 {" _n ///
			_col(8)`"global projectfolder "$projectFolder""' _n ///
			_col(4)"}" _n ///	
			_n ///		
			_col(4)"if "_char(36)"user == 2 {" _n ///
			_col(8)`"global projectfolder ""  //Enter the file path to the projectfolder of next user here"' _n ///
			_col(4)"}" _n ///
			_n ///
			_n ///
			_col(4)"* Project folder globals" _n ///
			_col(4)"* ---------------------" _n _n ///
			_col(4)"global dataWorkFolder " _col(34) `"""' _char(36)`"projectfolder/DataWork""' _n
		
		*Write sub devisor starting master and monitor data section section
		writeDevisor `subHandle' 1 FolderGlobals master	
		
		*Create master data folder and add global to folder in master do file
		if "`rndName'" == "" createFolderWriteGlobal "MasterData" "dataWorkFolder" mastData	`subHandle' 
		if "`rndName'" != "" writeGlobal 			 "MasterData" "dataWorkFolder" mastData	`subHandle' 

		*Write sub devisor starting master and monitor data section section
		writeDevisor `subHandle' 1 FolderGlobals rawData	
		
		*Create master data folder and add global to folder in master do file
		if "`rndName'" == "" createFolderWriteGlobal "EncryptedData"  "dataWorkFolder"  encryptFolder `subHandle' 
		if "`rndName'" != "" writeGlobal 			 "EncryptedData"  "dataWorkFolder"  encryptFolder `subHandle' 

		
		if "`rndName'" == "" {
			*Write sub devisor starting master and monitor data section section
			writeDevisor `subHandle' 1 FolderGlobals endRounds	
			
			*Write sub devisor starting master and monitor data section section
			writeDevisor `subHandle' 1 End_FolderGlobals
			
		}

		if "`rndName'" != "" {

			*Write sub devisor starting master and monitor data section section
			writeDevisor `subHandle' 1 FolderGlobals `rndName'		
			
			*Write all main folders for this round
			newRndFolderAndGlobals 	`rndName' `rndAbb' "dataWorkFolder" `subHandle' round
		}
		


end	

	
cap program drop 	mdofle_p2
	program define	mdofle_p2
		
		args   subHandle 

		di "masterDofilePart2 start"
		
		*Write devisor starting standardization globals section
		writeDevisor  `subHandle' 2 StandardGlobals		
		
		file write  `subHandle'  ///
			_col(4)"* Set all non-folder path globals that are constant accross" _n ///
			_col(4)"* the project. Examples are conversion rates used in unit" _n  	///		
			_col(4)"* standardization, differnt set of control variables," _n 		///		
			_col(4)"* ado file paths etc." _n _n 									///		
			_col(4) `"do ""' _char(36) `"dataWorkFolder/global_setup.do" "' _n _n
		
		*Write devisor ending standardization globals section
		writeDevisor  `subHandle' 2 End_StandardGlobals	
		
		di "masterDofilePart2 end"
		
end	

cap program drop 	global_setup
program define		global_setup
	
	*Create a temporary textfile
	tempname 	glbStupHandle	
	tempfile	glbStupTextFile
	
	cap file close 	`glbStupHandle'	
	file open  		`glbStupHandle' using "`glbStupTextFile'", text write append	
	
		
	file write  `glbStupHandle' 	///
		_col(4)"* ******************************************************************** *" _n 	///
		_col(4)"*" _n 																			///	
		_col(4)"*" _col(12) "SET UP STANDARDIZATION GLOBALS AND OTHER CONSTANTS" _n 			///
		_col(4)"*" _n 																			///			
		_col(4)"*" _col(16) "-Set globals used all across the projects" _n 						///
		_col(4)"*" _col(16) "-It is bad practice to define these at mutliple locations" _n		///
		_col(4)"*" _n 																			///	
		_col(4)"* ******************************************************************** *" _n
						
	file write  `glbStupHandle' 																///
		_n 																						///	
		_col(4)"* ******************************************************************** *" _n 	///
		_col(4)"* Set all conversion rates used in unit standardization " _n 					///
		_col(4)"* ******************************************************************** *" _n 	///
		_n 																						///
		_col(4)"**Define all your conversion rates here instead of typing them each " _n 		///
		_col(4)"* time you are converting amounts, for example - in unit standardization. " _n 	///
		_col(4)"* We have already listed common conversion rates below, but you" _n 			/// 
		_col(4)"* might have to add rates specific to your project, or change the target " _n 	///
		_col(4)"* unit if you are standardizing to other units than meters, hectares," _n 		///
		_col(4)"* and kilograms." 		_n														///
		_n 																						///
		_col(4)"*Standardizing length to meters" _n 											///
		_col(8)"global foot" _col(24) "= 0.3048" _n 											///
		_col(8)"global mile" _col(24) "= 1609.34" _n 											///
		_col(8)"global km" 	 _col(24) "= 1000" _n 												///
		_col(8)"global yard" _col(24) "= 0.9144" _n 											///
		_col(8)"global inch" _col(24) "= 0.0254" _n 											///
		_n 																						///	
		_col(4)"*Standardizing area to hectares" _n 											///
		_col(8)"global sqfoot"	_col(24) "= (1 / 107639)" _n 									///
		_col(8)"global sqmile"	_col(24) "= (1 / 258.999)" _n 									///
		_col(8)"global sqmtr" 	_col(24) "= (1 / 10000)" _n 									///
		_col(8)"global sqkmtr"	_col(24) "= (1 / 100)" _n 										///
		_col(8)"global acre" 	_col(24) "= 0.404686" _n 										///
		_n 																						///	
		_col(4)"*Standardizing weight to kilorgrams" _n 										///
		_col(8)"global pound" 	_col(24) "= 0.453592" _n 										///
		_col(8)"global gram" 	_col(24) "= 0.001" _n 											///
		_col(8)"global impTon" 	_col(24) "= 1016.05" _n 										///
		_col(8)"global usTon" 	_col(24) "= 907.1874996" _n 									///
		_col(8)"global mtrTon" 	_col(24) "= 1000" _n 											///
		_n 																						/// 
		_col(4)"* ******************************************************************** *" _n 	///
		_col(4)"* Set global lists of variables" _n 											///
		_col(4)"* ******************************************************************** *" _n 	///
		_n 																						///
		_col(4)"**This is a good location to create lists of variables to be used at " _n 		///
		_col(4)"* multiple locations across the project. Examples of such lists might " _n 		///
		_col(4)"* be different list of controls to be used across multiple regressions. " _n		///
		_col(4)"* By defining these lists here, you can easliy make updates and have " _n		///
		_col(4)"* those updates being applied to all regressions without a large risk " _n		///
		_col(4)"* of copy and paste errors." _n 												///
		_n 																						///	
		_col(8)"*Control Variables" _n 															///
		_col(8)"*Example: global household_controls" _col(50) "income female_headed" _n 		///
		_col(8)"*Example: global country_controls" 	 _col(50) "GDP inflation unemployment" _n 	///
		_n 																						///	
		_col(4)"* ******************************************************************** *" _n 	///
		_col(4)"* Set custom ado file path" _n 													///
		_col(4)"* ******************************************************************** *" _n 	///
		_n																						///
		_col(4)"**It is possible to control exactly which version of each command that " _n 	///
		_col(4)"* is used in the project. This prevents that different versions in " _n 		///
		_col(4)"* installed commands leads to different results." _n _n							///
		_col(4)"/*"_n																			///
		_col(8)"global ado" 	_col(24) `"""' _char(36) `"dataWorkFolder/your_ado_folder""' _n	///
		_col(12)"adopath ++"	_col(24) `"""' _char(36) `"ado" "'	 _n							///
		_col(12)"adopath ++"	_col(24) `"""' _char(36) `"ado/m" "' _n							///
		_col(12)"adopath ++"	_col(24) `"""' _char(36) `"ado/b" "' _n							///
		_col(4)"*/"_n																			///
		_n 																						///	
		_col(4)"* ******************************************************************** *" _n 	///
		_col(4)"* Anything else" _n 													///
		_col(4)"* ******************************************************************** *" _n 	///
		_n																						///		
		_col(4)"**Everything that is constant may be included here. One example of" _n 			///
		_col(4)"* something not constant that should be included here is exchange" _n 			///
		_col(4)"* rates. It is best practice to have one global with the exchange rate" _n 		///
		_col(4)"* here, and reference this each time a currency conversion is done. If " _n 	///
		_col(4)"* the currency exchange rate needs to be updated, then it only has to" _n 		///
		_col(4)"* be done at one place for the whole project." _n 								///		
		
	*Closing the new main master dofile handle
	file close 		`glbStupHandle'
	
	*Copy the new master dofile from the tempfile to the original position
	copy "`glbStupTextFile'"  "$dataWorkFolder/global_setup.do" , replace	
		
end
	

cap program drop 	mdofle_p3
	program define	mdofle_p3
		
		args   subHandle itemType rndName rnd

		di "masterDofilePart3 start"
		
		*Part number
		local partNum = 3
		
		*Write devisor starting the section running sub-master dofiles
		writeDevisor  `subHandle' `partNum' RunDofiles	
		
			file write  `subHandle' 	///
				_col(4)"* ******************************************************************** *" _n 	///
				_col(4)"*" _n 																			///	
				_col(4)"*" _col(12) "PART `partNum': - RUN DOFILES CALLED BY THIS MASTER DO FILE" _n 	///
				_col(4)"*" _n 
				
			if "`itemType'" == "project" {	
				file write  `subHandle' 																///
					_col(4)"*" _col(16) "-When survey rounds are added, this section will" _n 			///
					_col(4)"*" _col(17) "link to the master dofile for that round." _n 					/// 
					_col(4)"*" _col(16) "-The default is that these dofiles are set to not"  _n 		///
					_col(4)"*" _col(17) "run. It is rare that all round specfic master dofiles"  _n 	///
					_col(4)"*" _col(17) "are called at the same time, the round specific master"  _n 	///
					_col(4)"*" _col(17) "dofiles are almost always called individually. The"  _n 		///
					_col(4)"*" _col(17) "exception is when reviewing or replicating a full project." _n 
			} 
			else if "`itemType'" == "round" {	
				file write  `subHandle' 																///
					_col(4)"*" _col(16) "-A task master dofile has been created for each high"  _n 		///
					_col(4)"*" _col(17) "level task (cleaning, construct, analyze). By "  _n 			///
					_col(4)"*" _col(17) "running all of them all data work associated with the "  _n 	///
					_col(4)"*" _col(17) "`rndName' should be replicated, including output of "  _n 		///
					_col(4)"*" _col(17) "tablets, graphs, etc." _n 										/// 
					_col(4)"*" _col(16) "-Feel free to add to this list if you have other high"  _n 	/// 
					_col(4)"*" _col(17) "level tasks relevant to your project." _n 
			}
			
			file write  `subHandle' 	///
				_col(4)"*" _n ///	
				_col(4)"* ******************************************************************** *" _n
		
		if "`itemType'" == "round" {	
			
			file write  `subHandle' 	_n ///
				_col(4)"**Set the locals corresponding to the taks you want" _n ///
				_col(4)"* run to 1. To not run a task, set the local to 0." _n ///
				_col(4)"local importDo" _col(25) "0" _n ///
				_col(4)"local cleaningDo" _col(25) "0" _n ///
				_col(4)"local constructDo" _col(25) "0" _n ///
				_col(4)"local analysisDo" _col(25) "0" _n ///
			
			*Create the references to the high level task 
			highLevelTask `subHandle'  "`rndName'" "`rnd'" "import"
			highLevelTask `subHandle'  "`rndName'" "`rnd'" "cleaning"
			highLevelTask `subHandle'  "`rndName'" "`rnd'" "construct"
			highLevelTask `subHandle'  "`rndName'" "`rnd'" "analysis"
		
		}
		
		*Write devisor ending the section running sub-master dofiles
		writeDevisor  `subHandle' `partNum' End_RunDofiles
						
		di "masterDofilePart3 end"
		
end	
		
cap program drop 	highLevelTask 
	program define	highLevelTask
		
		args roundHandle rndName rnd task  
		
		di "highLevelTask start"
		
		*Import folder is in differnt location, in the encrypted folder
		if "`task'" != "import" {
			
			*The location of all the task master dofile apart from import master
			local taskdo_fldr "`rnd'_do"
		}
		else {
			
			**The import master dofile is in the encryption folder as it is 
			* likely to have identifying information
			local taskdo_fldr "`rnd'_doImp"
		}
		
		*Write section where task master files are called
		file write  `roundHandle' 	_n ///
			_col(4)"if (" _char(96) "`task'Do' == 1) { //Change the local above to run or not to run this file" _n ///
			_col(8) `"do ""' _char(36) `"`taskdo_fldr'/`rnd'_`task'_MasterDofile.do" "' _n ///
			_col(4)"}" _n
		
		*Create the task dofiles
		highLevelTaskMasterDofile `rndName' `task' `rnd'
	
end
		
cap program drop 	highLevelTaskMasterDofile
	program define	highLevelTaskMasterDofile
		
		di "highLevelTaskMasterDofile start"
		
		args rndName task rnd
		
		*Write the round dofile
		
		*Create a temporary textfile
		tempname 	taskHandle
		tempfile	taskTextFile
		file open  `taskHandle' using "`taskTextFile'", text write replace
		
		mdofle_task `taskHandle' `rndName' `rnd' `task' 
		
		*Closing the new main master dofile handle
		file close 		`taskHandle'

		*Import folder is in differnt location, in the encrypted folder
		if "`task'" != "import" {
			
			*Copy the new task master dofile from the tempfile to the original position
			copy "`taskTextFile'"  "${`rnd'_do}/`rnd'_`task'_MasterDofile.do" , replace
		}
		else {
		
			*Copy the import task master do file in to the Dofile import folder. 
			copy "`taskTextFile'"  "${`rnd'_doImp}/`rnd'_`task'_MasterDofile.do" , replace		
		}
				
end		
		
cap program drop 	mdofle_task
	program define	mdofle_task
		
		args subHandle rndName rnd task
		
		**Create local with round name and task in 
		* upper case for the titel of the master dofile
		local caps = upper("`rndName' `task'")
		
		*Differnt global suffix for different tasks
		local suffix 
		if "`task'" == "import" {
			local suffix "_doImp"
		}
		if "`task'" == "cleaning" {
			local suffix "_doCln"
		}
		if "`task'" == "construct" {
			local suffix "_doCon"
		}
		if "`task'" == "analysis" {
			local suffix "_doAnl"
		}
		
		file write  `subHandle' ///
			_col(4)"* ******************************************************************** *" _n ///
			_col(4)"* ******************************************************************** *" _n ///
			_col(4)"*" _col(75) "*" _n ///
			_col(4)"*" _col(20) "`caps' MASTER DO_FILE" _col(75) "*" _n ///
			_col(4)"*" _col(20) "This master dofile calls all dofiles related" _col(75) "*" _n ///
			_col(4)"*" _col(20) "to `task' in the `rndName' round." _col(75) "*" _n ///
			_col(4)"*" _col(75) "*" _n ///
			_col(4)"* ******************************************************************** *" _n ///
			_col(4)"* ******************************************************************** *" _n ///
			 _n 	/// 
			_col(4)"** IDS VAR:" _col(25) "list_ID_var_here		//Uniquely identifies households (update for your project)" _n ///			  
			_col(4)"** NOTES:" _n /// 	  			  
			_col(4)"** WRITEN BY:" _col(25) "names_of_contributors" _n ///
			_col(4)"** Last date modified: `c(current_date)'" _n _n /// 
			_n ///
			_col(4)"* ***************************************************** *" _n ///
			_col(4)"*" _col(60) "*" _n ///
			
		
		*Create the sections with placeholders for each dofile for this task
		mdofle_task_dosection `subHandle' "`rnd'" "`task'" "`suffix'" 1
		mdofle_task_dosection `subHandle' "`rnd'" "`task'" "`suffix'" 2
		mdofle_task_dosection `subHandle' "`rnd'" "`task'" "`suffix'" 3

	file write  `subHandle' ///
		_col(4)"* ************************************" _n ///
		_col(4)"*" _col(8) "Keep adding sections for all additional dofiles needed" _n ///
			
end

cap program drop 	mdofle_task_dosection
	program define	mdofle_task_dosection
	
	*Write the task master do-file section
	
	args subHandle rnd task suffix number
	
	file write  `subHandle' ///
		_col(4)"* ***************************************************** *" _n ///
		_col(4)"*" _n ///
		_col(4)"*" _col(8) "`task' dofile `number'" _n ///
		_col(4)"*" _n ///
		_col(4)"*" _col(8) "The purpose of this dofiles is:" _n ///
		_col(4)"*" _col(10) "(The ideas below are examples on what to include here)" _n ///
		_col(4)"*" _col(11) "-what additional data sets does this file require" _n ///
		_col(4)"*" _col(11) "-what variables are created" _n ///
		_col(4)"*" _col(11) "-what corrections are made" _n ///
		_col(4)"*" _n ///
		_col(4)"* ***************************************************** *"  _n ///
		_n ///
		_col(8) `"*do ""' _char(36) `"`rnd'`suffix'/dofile`number'.do" //Give your dofile a more informative name, this is just a place holder name"' _n _n
		
end
