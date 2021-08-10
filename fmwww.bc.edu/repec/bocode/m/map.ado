*******************************************************************************
* map.ado
* version 5.0

* Dictionaries can be defined on any Stata frame.
* Optionally install -dict- to facilitate the creation of dictionaries:
* ssc install dict

* author: Daniel Alves Fernandes
* contact: daniel.fernandes@eui.eu
*******************************************************************************

capture: program drop map
program define map

syntax varlist, DICTionary(string) [Values(string)]

  version 16

  confirm frame `dictionary'
  quietly: frame
  local current_frame: display "`r(currentframe)'"
  if ("`dictionary'" == "`current_frame'"){
    n: display as error ///
    "map cannot run when the dictionary list is in the active frame"
    exit 198
  }

  frame `dictionary': confirm variable `varlist'
  quietly frame `dictionary': ds `varlist', not
  local notkeys: display r(varlist)
  local size: list sizeof not_keys
  if("`values'" == ""){
    if (`size' == 0){
      n: display as error "frame `dictionary' does not contain values"
      exit 498
    }
    if (`size' > 1){
      n: display as error "ambiguous values column in frame `dictionary'"
      exit 498
    }
    else local values `not_keys'
  }
  if("`values'" != ""){
    frame `dictionary': confirm variable `values'
  }
  confirm new variable `values'

  quietly: ds `varlist', not(type string int)
  if ("`r(varlist)'" != ""){
    n: display as error "matching variables must be strings or integers"
    exit 109
  }
  foreach type in string int{
      quietly: ds `varlist', has(type `type')
      local `type'_in_current_frame: display r(varlist)
      quietly frame `dictionary': ds `varlist', has(type `type')
      local `type'_in_dict_frame: display r(varlist)
      local `type'_eq: list `type'_in_current_frame === `type'_in_dict_frame
  }
  if (`string_eq' == 0) | (`int_eq' == 0){
    display as error "type mismatch in matching variables"
    exit 109
  }

  tempvar dict_link
  capture: frlink m:1 `varlist', frame(`dictionary') gen(`dict_link')
  if (_rc != 0){
    n: display as error ///
    "the matching variables do not uniquely identify observations"
    exit
    498
  }

  quietly: frget `values', from(`dict_link')
  local match_size: list sizeof varlist
  if (`match_size' == 1) order `values', after(`varlist')
end
