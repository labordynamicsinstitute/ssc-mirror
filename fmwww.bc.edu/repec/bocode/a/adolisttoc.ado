*! version 1.0.0  21aug2007  Ben Jann

program adolisttoc
    version 9.2

*    local path      "D:\Home\jannb\Projekte\Stata\tools\adolist\test\0"
    local path      "/volumes/fmwww/repec/bocode/0"
    local tocname   "stata.toc"

    mata: adolisttoc()

end

version 9.2

local PKLFILE_HEADER  `""*! Stata package list""'

mata:
mata set matastrict on

void adolisttoc()
{
    real scalar         i, fh
    string scalar       dir, fn, line
    string colvector    toc
    string matrix       pkls

    dir = st_local("path")
    fn  = pathjoin(dir,st_local("tocname"))

// gather package lists (and titles) from directory
    pkls = dir(dir,"files","*.pkl")
    pkls = pkls, J(rows(pkls),1,"")
    for (i=1;i<=rows(pkls);i++) {
        fh = fopen(pathjoin(dir,pkls[i,1]), "r")
        line = fget(fh)
        if (substr(line,1,21)!=`PKLFILE_HEADER') {
            display("{txt}("+pkls[i,1]+" is not a Stata package list)")
            pkls[i,1] = ""
            fclose(fh)
            continue
        }
        if ((line = fget(fh))!=J(0,0,"")) {
            line = strtrim(line)
            if (substr(line, 1, 2)=="*!")
                pkls[i,2] = strtrim(substr(line,3,.))
            else if (substr(line, 1, 1)=="*")
                pkls[i,2] = strtrim(substr(line,2,.))
        }
        fclose(fh)
    }
    if (rows(pkls)>0) pkls = select(pkls,pkls[,1]:!="")
    // pkls = sort(pkls,1)

// compile new stata.toc
    if (rows(pkls)>0) {
        pkls[,1] = substr(pkls[,1], 1,strlen(pkls[,1]):-4) // get rid of .pkl
        toc = `"d {col 5}{stata "adolist ssc "' :+ pkls[,1] :+ `"":"' :+
            pkls[,1] :+ "} {col 23}" :+ pkls[,2]
            // => d {col 5}{stata "adolist ssc name":name} {col 23}title
    }
    toc = "v 3" \
          "d Ado package lists" \
          "d PACKAGE LISTS you could describe:" \
          toc \
          "t ../"
    if (fileexists(fn)) unlink(fn)
    fh = fopen(fn, "w")
    for (i=1;i<=rows(toc);i++) fput(fh,toc[i])
    fclose(fh)
}

end
