# version 2.0.2 (28 August 2024)

#########################
# MODULES
#########################

import csv
import os
import shutil
import xml.etree.ElementTree as ET
import zipfile

#########################
# MAIN FUNCTION
#########################

def make_csvs(input_zip, output_dir, languages):
  global root
  root = load(input_zip, output_dir)
  make_dir(output_dir)
  write_dataset_csv(output_dir, languages)
  write_variables_csv(output_dir, languages)
  write_categories_csv(output_dir, languages)
  

#########################
# HELPER FUNCTIONS
#########################

# load zip and make root
def load(input_zip, output_dir):
  with zipfile.ZipFile(input_zip, 'r') as zip_ref: # unzip and get tree
    zip_ref.extractall(output_dir)
    tree=ET.parse(output_dir+'/metadata.xml')
  root=tree.getroot() #  get root
  for i in root.iter(): # cut namespace
    i.tag=i.tag.split('}')[-1]
  return root

# get language codes
def get_lang(xpath):
  lang = []
  for ele in root.findall(xpath):
    lang.append(ele.get('{http://www.w3.org/XML/1998/namespace}lang'))
  lang = set(list(filter(None, lang)))
  return lang

# make output directory
def make_dir(output_dir):
  if not os.path.exists(output_dir):        
    os.makedirs(output_dir)

# unique
def get_unique(my_list):
  unique = []
  for my_list in my_list:
    if my_list in unique:
      continue
    else:
      unique.append(my_list)
  return unique

# check if element exists
def header_if_exists(element, xpath):
  items = []
  for ele in root.findall(xpath):
    if ele.tag is not None:
      items.append(element)
  return items

# check for language specific elements 
def header_lang_spec(element, xpath, languages='all'):
  items = []
  if languages == "all":
    for ele in root.findall(xpath):
      if ele.get('{http://www.w3.org/XML/1998/namespace}lang') is None:
        items.append(element)
      if ele.get('{http://www.w3.org/XML/1998/namespace}lang') is not None:
        items.append(element + '_' + ele.get('{http://www.w3.org/XML/1998/namespace}lang'))
  if languages == "default":
    for ele in root.findall(xpath):
      if ele.get('{http://www.w3.org/XML/1998/namespace}lang') is None:
        items.append(element)
  if languages in get_lang(xpath):
    for ele in root.findall(xpath):
      if ele.get('{http://www.w3.org/XML/1998/namespace}lang') == languages:
        items.append(element + '_' + ele.get('{http://www.w3.org/XML/1998/namespace}lang'))
  if languages not in get_lang(xpath) and languages != "default" and languages != "all":
    print("Your language selection is not availabel. Try languages = 'all'")
  return items    

#########################
# DATASET FUNCTIONS
#########################

# dataset header
def make_dataset_header(languages):
  header = ['study', 'dataset']
  header.extend(get_unique(header_lang_spec(
    'label', './/fileDscr/fileTxt/fileCitation/titlStmt/titl', languages)))
  header.extend(get_unique(header_lang_spec(
    'label', './/fileDscr/fileTxt/fileCitation/titlStmt/parTitl', languages)))
  header.extend(get_unique(header_lang_spec(
    'description', './/fileDscr/fileTxt/fileCont', languages)))
  header.extend(get_unique(header_if_exists(
    'url', './/fileDscr/notes/ExtLink')))
  return header

# dataset dictionary using header as keys
def make_dataset_dictionary(languages):
  header = make_dataset_header(languages)
  ## header as keys
  dictionary = {key:"" for key in header}
   ## study name
  if root.findtext(".//stdyDscr/citation/titlStmt/titl") is not None:
    dictionary['study'] = root.findtext(".//stdyDscr/citation/titlStmt/titl")
  if root.findtext(".//stdyDscr/citation/titlStmt/titl") is None:  
    dictionary['study'] = "study"
  ## dataset name
  if root.findtext(".//fileDscr/fileTxt/fileName") is not None:
    dictionary['dataset'] = root.findtext(".//fileDscr/fileTxt/fileName")
  if root.findtext(".//fileDscr/fileTxt/fileName") is None:  
    dictionary['dataset'] = "dataset"
  if languages == "all":
    ### dataset label all
    for ele in root.findall('.//fileDscr/fileTxt/fileCitation/titlStmt/titl'):
      if ele.get('{http://www.w3.org/XML/1998/namespace}lang') is None:
        dictionary['label'] = ele.text
      if ele.get('{http://www.w3.org/XML/1998/namespace}lang') is not None:  
        dictionary['label' + '_' + ele.get('{http://www.w3.org/XML/1998/namespace}lang')] = ele.text 
    for ele in root.findall('.//fileDscr/fileTxt/fileCitation/titlStmt/parTitl'):
      if ele.get('{http://www.w3.org/XML/1998/namespace}lang') is None:
        dictionary['label'] = ele.text
      if ele.get('{http://www.w3.org/XML/1998/namespace}lang') is not None:  
        dictionary['label' + '_' + ele.get('{http://www.w3.org/XML/1998/namespace}lang')] = ele.text
    ### dataset description all    
    for ele in root.findall('.//fileDscr/fileTxt/fileCont'):
      if ele.get('{http://www.w3.org/XML/1998/namespace}lang') is None:
        dictionary['description'] = ele.text
      if ele.get('{http://www.w3.org/XML/1998/namespace}lang') is not None:  
        dictionary['description' + '_' + ele.get('{http://www.w3.org/XML/1998/namespace}lang')] = ele.text  
  if languages == "default":
    ### dataset label default
    for ele in root.findall('.//fileDscr/fileTxt/fileCitation/titlStmt/titl'):
      if ele.get('{http://www.w3.org/XML/1998/namespace}lang') is None:
        dictionary['label'] = ele.text
    for ele in root.findall('.//fileDscr/fileTxt/fileCitation/titlStmt/parTitl'):
      if ele.get('{http://www.w3.org/XML/1998/namespace}lang') is None:
        dictionary['label'] = ele.text
    ### dataset description default    
    for ele in root.findall('.//fileDscr/fileTxt/fileCont'):
      if ele.get('{http://www.w3.org/XML/1998/namespace}lang') is None:
        dictionary['description'] = ele.text
  if languages in (get_lang('.//fileDscr/fileTxt/fileCitation/titlStmt/titl') | get_lang('.//fileDscr/fileTxt/fileCitation/titlStmt/parTitl')):
    ### dataset label code
    for ele in root.findall('.//fileDscr/fileTxt/fileCitation/titlStmt/titl'):
      if ele.get('{http://www.w3.org/XML/1998/namespace}lang') == languages:
        dictionary['label' + '_' + languages] = ele.text
    for ele in root.findall('.//fileDscr/fileTxt/fileCitation/titlStmt/parTitl'):
      if ele.get('{http://www.w3.org/XML/1998/namespace}lang') == languages:
        dictionary['label' + '_' + languages] = ele.text
        
    ### dataset description code
    for ele in root.findall('.//fileDscr/fileTxt/fileCont'):
      if ele.get('{http://www.w3.org/XML/1998/namespace}lang') == languages:
        dictionary['description' + '_' + languages] = ele.text
  ## dataset url
  for ele in root.findall('.//fileDscr/notes/ExtLink'):
    if ele.tag is not None:
      dictionary['url'] = ele.get('URI')        
  return dictionary

# dataset CSV file
def write_dataset_csv(output_dir, languages):
  with open(output_dir+'/dataset.csv', 'w', encoding='utf-8', newline='') as csvfile:
    writer = csv.DictWriter(csvfile, 
      fieldnames = make_dataset_header(languages), 
      quoting = csv.QUOTE_ALL)
    writer.writeheader()
    writer.writerow(make_dataset_dictionary(languages))

#########################
# VARIABLE FUNCTIONS
#########################

# make variables header
def make_variables_header(languages):
  header = ['variable']
  header.extend(get_unique(header_lang_spec(
    'label', './/dataDscr/var/labl', languages)))
  header.extend(get_unique(header_if_exists(
    'type', './/dataDscr/var/varFormat')))
  header.extend(get_unique(header_lang_spec(
    'description', './/dataDscr/var/txt',languages)))
  header.extend(get_unique(header_if_exists(
    'url', './/dataDscr/var/notes/ExtLink')))
  return header

# variables dictionary using header as keys
def make_variables_dictionary(languages):
  ## header as keys
  header = make_variables_header(languages)
  ## make list of dictionaries
  list_of_dictionaries=[]
  ## index for variables with no name
  i = 1
  for var in root.findall('.//dataDscr/var'):
    ### header as keys
    dictionary = {key:"" for key in header}
    ### variable name
    if var.attrib.get('name') is not None:
      dictionary['variable'] = var.attrib.get('name')
    if var.attrib.get('name') is None:         
      dictionary['variable'] = "no_name_" + str(i)
    ### variable label  
    if languages == "all":
      for ele in var.findall('labl'):
        if ele.get('{http://www.w3.org/XML/1998/namespace}lang') is None:
          dictionary['label'] = ele.text
        if ele.get('{http://www.w3.org/XML/1998/namespace}lang') is not None:  
          dictionary['label' + '_' + ele.get('{http://www.w3.org/XML/1998/namespace}lang')] = ele.text
    if languages == "default":
      for ele in var.findall('labl'):
        if ele.get('{http://www.w3.org/XML/1998/namespace}lang') is None:
          dictionary['label'] = ele.text
    if languages in get_lang('.//dataDscr/var/labl'):
      for ele in var.findall('labl'):
        if ele.get('{http://www.w3.org/XML/1998/namespace}lang') == languages:
          dictionary['label' + '_' + ele.get('{http://www.w3.org/XML/1998/namespace}lang')] = ele.text
    ### variable type
    for ele in var.findall('varFormat'):
      if ele.tag is not None:
        dictionary['type'] = (ele.attrib.get('type')) 
    ### variable description
    if languages == "all":
      for ele in var.findall('txt'):
        if ele.get('{http://www.w3.org/XML/1998/namespace}lang') is None:
          dictionary['description'] = ele.text
        if ele.get('{http://www.w3.org/XML/1998/namespace}lang') is not None:  
          dictionary['description' + '_' + ele.get('{http://www.w3.org/XML/1998/namespace}lang')] = ele.text
    if languages == "default":
      for ele in var.findall('txt'):
        if ele.get('{http://www.w3.org/XML/1998/namespace}lang') is None:
          dictionary['description'] = ele.text
    if languages in get_lang('.//dataDscr/var/txt'):
      for ele in var.findall('txt'):
        if ele.get('{http://www.w3.org/XML/1998/namespace}lang') == languages:
          dictionary['description' + '_' + ele.get('{http://www.w3.org/XML/1998/namespace}lang')] = ele.text      
    ### variable url
    for ele in var.findall('.//notes/ExtLink'): 
      if ele.tag is not None:
        dictionary['url'] = ele.get('URI')
      if ele.tag is None:
        dictionary['url'] = ""
    ### append dictionary for variable to list of dictionaries    
    list_of_dictionaries.append(dictionary)
    ## add 1 for variable numeration if no name is available
    i = i + 1  
  return list_of_dictionaries

# variables CSV file
def write_variables_csv(output_dir, languages):
  with open(output_dir+'/variables.csv', 'w', encoding='utf-8', newline='') as csvfile:
    writer = csv.DictWriter(csvfile, 
      fieldnames = make_variables_header(languages), 
      quoting = csv.QUOTE_ALL)
    writer.writeheader()
    writer.writerows(make_variables_dictionary(languages))

#########################
# CATEGORIES FUNCTIONS
#########################

# categories header
def make_categories_header(languages):
  header = ['variable', 'value']
  header.extend(get_unique(header_lang_spec(
    'label', './/dataDscr/var/catgry/labl', languages)))
  return header

# categories dictionary using header as keys
def make_categories_dictionary(languages):
  ## index for variables with no name
  i = 1
  ## make header
  header = make_categories_header(languages)
  ## make list of dictionaries
  list_of_dictionaries=[]
  for var in root.findall('.//dataDscr/var'):
    lang_list = get_lang('.//dataDscr/var/catgry/labl')
    for cat in var.findall('catgry'):
      #### header as keys
      dictionary = {key:"" for key in header}
      #### variable name  
      if var.attrib.get('name') is not None:
        dictionary['variable'] = var.attrib['name']
      if var.attrib.get('name') is None:
        dictionary['variable'] = "no_name_" + str(i)
      #### category value
      for val in cat.findall('catValu'): # value
        dictionary['value'] = val.text
      #### category label
      if languages == "all":
        for lab in cat.findall('labl'):
          if lab.get('{http://www.w3.org/XML/1998/namespace}lang') is None:
            dictionary['label'] = lab.text
          if lab.get('{http://www.w3.org/XML/1998/namespace}lang') is not None:
            dictionary['label' + '_' + lab.get('{http://www.w3.org/XML/1998/namespace}lang')] = lab.text
      if languages == "default":
        for lab in cat.findall('labl'):
          if lab.get('{http://www.w3.org/XML/1998/namespace}lang') is None:
            dictionary['label'] = lab.text
      if languages in lang_list:      
        for lab in cat.findall('labl'):
          if lab.get('{http://www.w3.org/XML/1998/namespace}lang') == languages:
            dictionary['label' + '_' + lab.get('{http://www.w3.org/XML/1998/namespace}lang')] = lab.text
      #### append dictionary to list of dictionaries
      list_of_dictionaries.append(dictionary) 
    ### add 1 for variable numeration if no name is available
    i = i + 1
  return list_of_dictionaries

# categories CSV file
def write_categories_csv(output_dir, languages):
  with open(output_dir+"/categories.csv", 'w', encoding='utf-8', newline='') as csvfile:
    writer = csv.DictWriter(csvfile, 
    fieldnames = make_categories_header(languages), 
    quoting = csv.QUOTE_ALL)
    writer.writeheader()
    writer.writerows(make_categories_dictionary(languages))


if __name__ == '__main__':
  make_csvs(input_zip, output_dir, languages)   
