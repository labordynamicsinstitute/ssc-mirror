#!/usr/bin/env python3
"""make_example_varlabels.py -- build the example workbook shipped with applyvarlabels.

Writes example_varlabels.xlsx with two worksheets:

  * "data"        -- a small unlabeled dataset: the first row is the variable
                     names, the rows below are raw values.  This stands in for
                     the "100+ variables, none of which have labels" dataset a
                     user is handed.
  * "var_labels"  -- the crosswalk: one row per variable, column "Variable"
                     holding the variable name and column "Label" holding the
                     (multi-word) variable label to apply.

The crosswalk is intentionally imperfect so the example exercises the whole
inventory that applyvarlabels prints:

  * every data variable except `notes` has a crosswalk row (so `notes` appears
    in the "variables in memory with no crosswalk label" list);
  * two crosswalk rows -- `q7_other` and `income_2019` -- name variables that
    are NOT in the data (so they appear in the "crosswalk rows with no such
    variable" list);
  * labels include an apostrophe, an ampersand, and one deliberately longer
    than Stata's 80-character variable-label limit, to show the cautions.

Run:  python3 make_example_varlabels.py
"""

import openpyxl

# ---- the data sheet: header row = variable names, then a few rows of values --
data_headers = [
    "id", "wave", "age", "female", "race", "educ", "employed",
    "income", "hhsize", "region", "urban", "health", "q7", "notes",
]
data_rows = [
    [1001, 1, 34, 1, 3, 4, 1, 52000, 3, "South",     1, 4, 2, "callback"],
    [1002, 1, 51, 0, 1, 2, 1, 38000, 5, "West",      0, 3, 1, ""],
    [1003, 1, 27, 1, 2, 5, 0, 0,     1, "Northeast", 1, 5, 3, "refused q9"],
    [1004, 2, 43, 0, 3, 3, 1, 74500, 4, "Midwest",   1, 2, 2, ""],
    [1005, 2, 66, 1, 4, 1, 0, 21000, 2, "South",     0, 3, 4, "proxy"],
]

# ---- the crosswalk sheet: Variable | Label, one variable per row -------------
# Order is deliberately NOT the data order, and NOT alphabetical, to make the
# point that applyvarlabels matches BY NAME, never by position.
crosswalk = [
    ("income",      "Annual household income in dollars"),
    ("age",         "Respondent's age at last birthday"),          # apostrophe
    ("female",      "Respondent is female (1 = yes)"),
    ("educ",        "Highest level of education completed"),
    ("employed",    "Currently employed for pay (1 = yes)"),
    ("race",        "Race and ethnicity, self-reported"),          # ampersand-ish phrase
    ("hhsize",      "Number of people in the household"),
    ("region",      "Census region of residence"),
    ("urban",       "Lives in an urban area (1 = yes)"),
    ("health",      "Self-rated health, 1 (poor) to 5 (excellent)"),
    ("wave",        "Survey wave"),
    ("id",          "Respondent identifier"),
    ("q7",          "Q7: satisfaction with local schools & services"),  # ampersand
    ("q7_other",    "Q7 open-ended 'other' response"),             # NOT in data
    ("income_2019", "Prior-year household income, used only in the 2019 supplement and kept here for reference"),  # NOT in data + >80 chars
]

wb = openpyxl.Workbook()

ws_data = wb.active
ws_data.title = "data"
ws_data.append(data_headers)
for r in data_rows:
    ws_data.append(r)

ws_lab = wb.create_sheet("var_labels")
ws_lab.append(["Variable", "Label"])
for v, l in crosswalk:
    ws_lab.append([v, l])

wb.save("example_varlabels.xlsx")
print("wrote example_varlabels.xlsx (sheets: data, var_labels)")
