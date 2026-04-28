program define tomarkstat

cap which pathutil
if _rc ssc install pathutil
version 17.0

syntax anything ,[save(string) replace]

local anything `anything'

confirm file "`anything'"

pathutil split "`anything'"

local fname =  s(filename)   //  filename (without extension/suffix)
local suffix = s(extension)  // extension of filename (same as s(suffix))
local path =   s(directory)  //  directory

if "`suffix'" != ".md" {
    display as error "File `anything' is not a markdown file"
    exit 198
}

if "`save'" == "" {
    local save `path'/`fname'.stmd
}
else{
    pathutil split "`save'"
    if "`s(extension)'"=="" local save `save'.stmd
    else if "`s(extension)'"!=".stmd"{
        display as error "File `save' is not a stmd file"
        exit 198
    }
}


cap confirm file "`save'"
if _rc == 0 & "`replace'" == "" {
    display as error "File `save' already exists, use replace option to overwrite"
    exit 198
}

 if "`replace'" == ""  local replace 0
 else local replace 1


mata: rewrite_md3("`anything'","`save'",`replace',"`path'","`fname'")


end


mata:


void function rewrite_md3(string scalar ofi, string scalar tfi, real scalar replace, string scalar rpath, string scalar llp)
{
    // 1. 读取文件
    fcon = cat(ofi)
    fcon2 = strtrim(fcon)
    n = rows(fcon2)
    idx = select((1::n),substr(fcon2,1,3):=="```")
    fcon = fcon2[1::n] 
    if(length(idx)>0){
        blockflag = 1::length(idx)
        i0 = select(idx,mod(blockflag,2):==1)
        if (length(i0)>0){
             fcon[i0] = usubinstr(fcon[i0],"```","```s",1)
            }
    }
    ftemp = subinstr(fcon2," ","",.)
    idx = select((1::n),substr(ftemp,1,length("isheredisplay")):!="isheredisplay")
    if (length(idx)>0){
        fcon= fcon[idx]
    }
    fcon =  "--------------" \ fcon
    fcon =  " Stata Markdown" \ fcon

    // 8. 输出
    if (replace == 0) {
        mm_outsheet(tfi, fcon)
    } else {
        mm_outsheet(tfi, fcon, "replace")
    }
    // print created file results
    printf("File %s created successfully\n", tfi)
}


end