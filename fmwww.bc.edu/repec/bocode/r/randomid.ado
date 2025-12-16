*! version 1 -- developed by RT 10/16/2014

capture program drop randomid
program define randomid
  version 13
  syntax name(id="newvar name"), [LENgth(integer 8)]


qui {
preserve //<--preserve in case the algorithm fails, we automatically restore the original dataset

gen ___origsort = _n

if 62^`length'<_N {
  if _N>9999 noi di as error "error: impossible to create unique ID of length `length' with " _N " observations; please select a length of at least " `=length(string(_N))+2'
  else       noi di as error "error: impossible to create unique ID of length `length' with " _N " observations; please select a length of at least " `=ceil((log(_N)/log(62)))+2'
  exit 121
}

/* NOTE: 26 lower +26 upper +10 numbers =62.
         the next greater integer of log base 62 of _N is the minimum length needed to identify every observation with 62 characters.
         Mathematically: log(_N)/log(62)
         However, by choosing the minimum integer needed, you run the highly probable risk of randomly selecting duplicate ids,
         making the command enter a very lengthy --or even infinite!-- loop.
         I, thus, recommend choosing a length of length(string(_N)) +2.
*/

if `length'<`=length(string(_N))+2' & _N>9999 {
  noi di as error "error: high risk of entering a very lengthy loop; please select a length of at least " `=length(string(_N))+2'
  exit 121
}

if `length'<`=ceil((log(_N)/log(62)))+2' & _N<10000 {
  noi di as error "error: high risk of entering a very lengthy loop; please select a length of at least " `=ceil((log(_N)/log(62)))+2'
  exit 121
}

*** sort randomly
gen __u1 =runiform()
gen __u2 =runiform()
local n=2
capt isid __u?
while _rc!=0 {
  local n = `n' +1
  gen __u`n' =runiform()
  capt isid __u?
}
sort __u?

*** make the `name' string
gen `namelist'=""

*** create random id
local distinct=1
local total=2

while `distinct'!=`total' {

  while length(`namelist')!=`length' {

    *** generate random integers from [65,90] which maps to uppercase [See help function char]
    gen __upper= char(65+int((90-65+1)*runiform()))

    *** generate random integers from [97,122] which maps to lowercase [See help function char]
    gen __lower= char(97+int((122-97+1)*runiform()))

    *** generate random integers [0,9]
    gen __integer09= string(0+int((9-0+1)*runiform()))

    *** concatenate random characters
    replace `namelist' = `namelist' + `:word `=1+int((3-1+1)*runiform())' of __upper __lower __integer09'
    drop __upper __lower __integer09
  }

    *** make sure the id is unique
  qui distinct `namelist'
  local distinct =r(ndistinct)
  local total =r(N)
  if `distinct'!=`total' {
       local length =`length'+1
       noi di "character length is now `length' to ensure `namelist' is unique"
       }
}

*** finalizing
compress `namelist'
drop __u?
restore, not
sort ___origsort
drop ___origsort


} // end qui
end
