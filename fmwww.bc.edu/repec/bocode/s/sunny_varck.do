 sysuse conservatism, clear 
 varck roa roe LEV SIZE bm
 if r(all_exist) {
         reg roa roe LEV SIZE bm
 }
 else {
        di as error "Missing variables: " r(notexist)
 }
 
 varck Score C_SCORE 
 if r(all_exist) {
         reg Score C_SCORE
 }
 else {
        di as error "Missing variables: " r(notexist)
 }

 sysuse auto, clear
 varck price mpg turn displacement foreign
 if r(all_exist) {
         reg price mpg turn displacement foreign
 }
 else {
        di as error "Missing variables: " r(notexist)
 }