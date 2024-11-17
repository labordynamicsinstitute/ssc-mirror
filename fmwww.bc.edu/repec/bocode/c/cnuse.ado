
program define cnuse

    version 14
    syntax [anything(name = FileName)] [, CLEAR noDesc Save REPLACE Url(string)]

    // 检查是否提供了文件名
    if "`FileName'" == "" {
        di as err "Error: No file name specified."
        exit 1
    }

    // 设置默认数据URL路径
    if "`url'" == "" {
        local DataURL "https://gitee.com/econometric/data/raw/master"
    }
    else {
        local DataURL "`url'"
    }

    // 获取文件名和扩展名
    local extension = ""
    if length("`FileName'") > 3 {
        local extension = lower(substr("`FileName'", -3, 3))
    }

    // 检查文件名是否没有扩展名
    local LocalFilePath "`FileName'"
    if "`extension'" == "" {
        // 默认使用 .dta 扩展名
        local FileNameWithExtension "`FileName'.dta"
        local extension = "dta"
    }
    else if "`extension'" == "shp" {
        // 处理 Shapefile 文件
        local FileNameWithExtension "`FileName'"
    }
    else {
        local FileNameWithExtension "`FileName'"
    }

    // 检查本地文件是否已经存在，避免重复下载
    capture confirm file "`LocalFilePath'"
    if _rc == 0 {
        di as text "File `LocalFilePath' already exists locally. Loading data..."
    }
    else {
        // 文件不存在则尝试从URL下载
        di as text "Downloading `FileNameWithExtension' from `DataURL'..."
        capture copy "`DataURL'/`FileNameWithExtension'" ., replace
        if _rc != 0 {
            di as err "Error: `FileNameWithExtension' not found or could not be downloaded."
            exit 1
        }
    }

    // 根据文件扩展名设置导入命令
    if "`extension'" == "csv" {
        local import_cmd "import delimited"
    }
    else if "`extension'" == "xls" | "`extension'" == "lsx" {
        local import_cmd "import excel"
    }
    else if "`extension'" == "dta" {
        local import_cmd "use"
    }
    else if "`extension'" == "txt" {
        local import_cmd "import delimited"
    }
    else if "`extension'" == "shp" {
        local import_cmd "spshape2dta"
    }
    else if "`extension'" == "zip" {
        local import_cmd "unzip_and_use"
    }
    else {
        di as err "Error: Unsupported file format. Only .dta, .csv, .xls, .xlsx, .txt, .zip, .gz, and .shp formats are supported."
        exit 1
    }

    // 根据文件类型使用相应的导入命令
    if "`import_cmd'" == "use" {
        capture use "`LocalFilePath'", `clear'
    }
    else if "`import_cmd'" == "import delimited" {
        capture import delimited using "`LocalFilePath'", clear
    }
    else if "`import_cmd'" == "import excel" {
        capture import excel "`LocalFilePath'", clear firstrow
    }
    else if "`import_cmd'" == "spshape2dta" {
        // 确保下载shp和dbf文件，并使用spshape2dta导入
        di as text "Ensuring both .shp and .dbf files are present in the current directory..."
        local baseName = substr("`LocalFilePath'", 1, length("`LocalFilePath'") - 4)
        local shpFile = "`baseName'.shp"
        local dbfFile = "`baseName'.dbf"

        // 检查shp文件是否存在
        capture confirm file "`shpFile'"
        if _rc != 0 {
            di as err "Error: `shpFile' could not be found or downloaded."
            exit 1
        }

        // 检查dbf文件是否存在
        capture confirm file "`dbfFile'"
        if _rc != 0 {
            di as err "Error: Matching .dbf file (`dbfFile') for the .shp file could not be found."
            exit 1
        }

        // 执行spshape2dta命令导入数据
        di as text "Importing shapefile using spshape2dta..."
        spshape2dta `baseName'
    }
    else if "`import_cmd'" == "unzip_and_use" {
        // 解压zip文件并加载.dta数据
        di as text "Unzipping the zip file..."
        local unzippedFile = substr("`LocalFilePath'", 1, length("`LocalFilePath'") - 4) + ".dta"
        unzipfile "`LocalFilePath'", replace
        capture confirm file "`unzippedFile'"
        if _rc != 0 {
            di as err "Error: `unzippedFile' could not be found after unzipping."
            exit 1
        }
        di as text "Loading unzipped data..."
        capture use "`unzippedFile'", `clear'
    }

    // 错误处理：如果加载失败则提示用户
    if _rc != 0 {
        if _rc == 4 {
            di as err "Error: Data in memory would be lost. Use 'aistata `FileName', clear' to discard changes."
        }
        else {
            di as err "Error: Failed to load `LocalFilePath'. Please ensure the file exists and is in the correct format."
        }
        exit 1
    }

    // 如果 'nodesc' 选项未指定，则显示数据描述信息
    if "`desc'" != "nodesc" {
        describe
    }

    // 自动进行时间序列设置，如果适用
    capture tsset
    if _rc == 0 {
        tsset
    }

    // 如果指定了 'save' 选项，则保存数据到本地文件
    if "`save'" != "" {
        capture save "`LocalFilePath'"
        if _rc == 602 {
            if "`replace'" == "" {
                di as err "Warning: file `LocalFilePath' already exists, no file saved. Specify -replace- to overwrite."
            }
            else {
                save "`LocalFilePath'", replace
            }
        }
    }
end