#!/usr/bin/env python3
"""
googlesheets_helper.py -- Python backend for the Stata `googlesheets` package.

The Stata side writes a JSON args file, shells into this script with the args
file as the first argument and an output file as the second, then reads the
JSON the script writes back.  All Google Sheets / Drive API calls happen here.

Auth: OAuth 2.0 Desktop client.  On first run, opens a browser for the user
to consent to the Sheets + Drive scopes; afterward, a cached refresh token
in `token_json` is used silently.

Subcommands (set via args.subcommand):
    read_range, write_range, append_range, clear_range,
    list_sheets, add_sheet, delete_sheet, rename_sheet,
    format_range, get_metadata, ping

This file is bundled with the Stata package; it is not on the user's PATH
and is invoked exclusively by the googlesheets_*.ado wrappers.
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import traceback
from pathlib import Path

# -- Dependency auto-install -------------------------------------------------
# The Stata caller toggles whether we auto-install missing libraries via the
# `auto_install` flag in the args JSON.  Defaulting to True keeps the
# first-run experience friction-free; users who manage their own Python
# environment can pass auto_install=False from the ado wrapper.

_REQUIRED = [
    ("google.oauth2.credentials", "google-auth"),
    ("google_auth_oauthlib.flow",  "google-auth-oauthlib"),
    ("googleapiclient.discovery",  "google-api-python-client"),
]


def _venv_dir() -> Path:
    """Where we keep our private venv.  One location per user, OS-aware."""
    if sys.platform == "win32":
        base = os.environ.get("APPDATA") or os.environ.get("USERPROFILE", "")
        return Path(base) / "stata-googlesheets" / "venv"
    return Path.home() / ".config" / "stata-googlesheets" / "venv"


def _venv_python(venv: Path) -> Path:
    if sys.platform == "win32":
        return venv / "Scripts" / "python.exe"
    return venv / "bin" / "python3"


def _ensure_libs(auto_install: bool) -> None:
    """If our deps are already importable in the current interpreter, we're
    done.  Otherwise create (or re-use) a private venv, install the deps
    into it, and re-exec ourselves so the rest of the script runs inside
    that venv.  This avoids PEP-668 ("externally-managed-environment")
    errors on system Pythons like Homebrew's, and keeps the user's
    system site-packages untouched.
    """
    # Fast path: already importable in current interpreter.
    try:
        for module, _ in _REQUIRED:
            __import__(module)
        return
    except ImportError:
        pass

    venv = _venv_dir()
    vpy  = _venv_python(venv)

    # If we are already running inside our own venv but imports still
    # failed, the venv is broken -- nuke and rebuild.
    in_our_venv = (Path(sys.executable).resolve() == vpy.resolve()) if vpy.exists() else False

    if vpy.exists() and not in_our_venv:
        # Re-exec into venv; deps may already be installed there.
        os.execv(str(vpy), [str(vpy)] + sys.argv)

    if not auto_install:
        raise RuntimeError(
            "Missing Python libraries.  Either install them globally with "
            "`pip install google-auth google-auth-oauthlib google-api-python-client', "
            "or pass auto_install=True so the wrapper creates a private venv at "
            + str(venv) + "."
        )

    print(f"[googlesheets] creating private venv at {venv} (one-time setup)...",
          file=sys.stderr, flush=True)
    venv.parent.mkdir(parents=True, exist_ok=True)
    subprocess.check_call([sys.executable, "-m", "venv", str(venv)])

    print("[googlesheets] installing google-api-python-client + auth libraries...",
          file=sys.stderr, flush=True)
    subprocess.check_call(
        [str(vpy), "-m", "pip", "install", "--quiet", "--upgrade", "pip"]
    )
    subprocess.check_call(
        [str(vpy), "-m", "pip", "install", "--quiet"] +
        [pkg for _, pkg in _REQUIRED]
    )

    # Re-exec into the venv with the same args.
    os.execv(str(vpy), [str(vpy)] + sys.argv)


# -- ID / URL parsing --------------------------------------------------------

_SHEETID_RE = re.compile(r"/spreadsheets/d/([a-zA-Z0-9_-]+)")


def parse_spreadsheet_id(s: str) -> str:
    """Accept a bare spreadsheet ID or a full URL; return the ID."""
    s = s.strip()
    m = _SHEETID_RE.search(s)
    if m:
        return m.group(1)
    return s


# -- Auth --------------------------------------------------------------------

SCOPES = [
    "https://www.googleapis.com/auth/spreadsheets",
    "https://www.googleapis.com/auth/drive.file",
    "https://www.googleapis.com/auth/drive.metadata.readonly",
]


def get_credentials(client_json: str, token_json: str):
    """OAuth 2.0 Desktop flow with token caching.

    First call: opens a browser, asks the user to consent, writes a refresh
    token to `token_json`.  Subsequent calls: load and refresh silently.
    """
    from google.oauth2.credentials import Credentials
    from google.auth.transport.requests import Request
    from google_auth_oauthlib.flow import InstalledAppFlow

    creds = None
    if token_json and Path(token_json).exists():
        try:
            creds = Credentials.from_authorized_user_file(token_json, SCOPES)
        except Exception:
            creds = None  # corrupt cache -> redo flow

    if creds and creds.valid:
        return creds

    if creds and creds.expired and creds.refresh_token:
        try:
            creds.refresh(Request())
            _save_token(creds, token_json)
            return creds
        except Exception:
            creds = None

    if not Path(client_json).exists():
        raise FileNotFoundError(
            f"OAuth client JSON not found at: {client_json}.  "
            "Download the Desktop OAuth client from Google Cloud Console and "
            "point GS_CLIENT (or the keyfile() option) at the file."
        )

    flow = InstalledAppFlow.from_client_secrets_file(client_json, SCOPES)
    # run_local_server starts a tiny localhost listener that catches the
    # OAuth redirect; the user's default browser opens automatically.
    print("[googlesheets] opening browser for OAuth consent (one-time)...",
          file=sys.stderr, flush=True)
    creds = flow.run_local_server(
        port=0, open_browser=True, prompt="consent",
        authorization_prompt_message="",
        success_message="Authorization complete -- you can close this tab and return to Stata.",
    )
    _save_token(creds, token_json)
    return creds


def _save_token(creds, token_json: str) -> None:
    if not token_json:
        return
    Path(token_json).parent.mkdir(parents=True, exist_ok=True)
    with open(token_json, "w") as f:
        f.write(creds.to_json())
    try:
        os.chmod(token_json, 0o600)
    except OSError:
        pass


def get_service(creds, api: str, version: str):
    from googleapiclient.discovery import build
    return build(api, version, credentials=creds, cache_discovery=False)


# -- Subcommand implementations ---------------------------------------------


def cmd_ping(args, sheets, drive):
    """Sanity check: confirm the OAuth flow + Sheets API both work."""
    spreadsheet_id = parse_spreadsheet_id(args["spreadsheet"])
    meta = sheets.spreadsheets().get(
        spreadsheetId=spreadsheet_id,
        includeGridData=False,
        fields="properties.title,sheets.properties(title,sheetId,gridProperties)",
    ).execute()
    return {
        "title": meta.get("properties", {}).get("title"),
        "sheets": [s["properties"]["title"] for s in meta.get("sheets", [])],
    }


def cmd_get_metadata(args, sheets, drive):
    spreadsheet_id = parse_spreadsheet_id(args["spreadsheet"])
    meta = sheets.spreadsheets().get(
        spreadsheetId=spreadsheet_id,
        includeGridData=False,
        fields=("properties.title,namedRanges,"
                "sheets.properties(title,sheetId,index,gridProperties)"),
    ).execute()
    return {
        "title":   meta.get("properties", {}).get("title"),
        "sheets":  [
            {
                "title":     s["properties"]["title"],
                "sheetId":   s["properties"]["sheetId"],
                "index":     s["properties"].get("index"),
                "rowCount":  s["properties"].get("gridProperties", {}).get("rowCount"),
                "colCount":  s["properties"].get("gridProperties", {}).get("columnCount"),
            }
            for s in meta.get("sheets", [])
        ],
        "named_ranges": [
            {"name": nr.get("name"),  "range": nr.get("range")}
            for nr in meta.get("namedRanges", [])
        ],
    }


def cmd_list_sheets(args, sheets, drive):
    """Lighter wrapper around get_metadata."""
    md = cmd_get_metadata(args, sheets, drive)
    return {"sheets": md["sheets"]}


def _build_range(sheet, rng):
    if sheet and rng:
        return f"'{sheet}'!{rng}"
    if sheet:
        return f"'{sheet}'"
    if rng:
        return rng
    raise ValueError("Either sheet() or range() must be supplied.")


def _parse_dt(s, fmts):
    from datetime import datetime
    for f in fmts:
        try:
            return datetime.strptime(s, f)
        except ValueError:
            continue
    return None


def _since_ge(cell, threshold):
    """True if cell >= threshold, comparing as numbers or datetimes when both
    sides parse that way, else as strings.  A naive string compare is wrong for
    timestamps because Google returns dates with unpadded hours (e.g.
    '2026-07-04 9:00:00'), so '9' sorts after '12'; parsing to datetime fixes
    it, and numeric parsing keeps since() correct for ratings, counts, and ids."""
    a, b = str(cell), str(threshold)
    try:
        return float(a) >= float(b)
    except ValueError:
        pass
    _FMTS = ("%Y-%m-%d %H:%M:%S", "%Y-%m-%d %H:%M", "%Y-%m-%d",
             "%m/%d/%Y %H:%M:%S", "%m/%d/%Y %H:%M", "%m/%d/%Y",
             "%Y/%m/%d %H:%M:%S", "%Y/%m/%d")
    da, db = _parse_dt(a, _FMTS), _parse_dt(b, _FMTS)
    if da is not None and db is not None:
        return da >= db
    return a >= b


def cmd_read_range(args, sheets, drive):
    spreadsheet_id = parse_spreadsheet_id(args["spreadsheet"])
    a1 = _build_range(args.get("sheet"), args.get("range"))
    resp = sheets.spreadsheets().values().get(
        spreadsheetId=spreadsheet_id,
        range=a1,
        valueRenderOption=args.get("value_render", "UNFORMATTED_VALUE"),
        dateTimeRenderOption=args.get("datetime_render", "FORMATTED_STRING"),
    ).execute()
    values = resp.get("values", [])

    # -- post-read filters (Form-data helpers) --
    since = args.get("since")
    if since and values:
        col_spec  = since.get("column")
        threshold = since.get("value")
        header = values[0] if values else []
        try:
            col_idx = int(col_spec)
        except (TypeError, ValueError):
            try:
                col_idx = header.index(col_spec)
            except ValueError:
                raise ValueError(f"since(column='{col_spec}'): column not found in header row")
        body = [row for row in values[1:]
                if len(row) > col_idx and _since_ge(row[col_idx], threshold)]
        values = [header] + body

    tail = args.get("tail")
    if tail and tail > 0 and len(values) > 1:
        values = [values[0]] + values[1:][-int(tail):]

    # Write the rows to a TSV path the caller passed in args.  Stata
    # picks the file up with `import delimited' to materialise the table
    # without parsing JSON.  We also write a tiny ncols/nrows summary
    # via the regular result dict so the wrapper can report stats.
    data_out = args.get("data_out_path")
    if data_out:
        import csv
        with open(data_out, "w", newline="") as f:
            w = csv.writer(f, delimiter="\t", lineterminator="\n",
                            quoting=csv.QUOTE_MINIMAL)
            for row in values:
                # Coerce non-string cells to strings; preserve numeric form.
                w.writerow(["" if c is None else c for c in row])

    return {
        "data_out_path": data_out or "",
        "nrows":         len(values),
        "ncols":         max((len(r) for r in values), default=0),
        "range":         resp.get("range"),
    }


def _read_values_from_args(args):
    """For write/append: either inline values[] or read from a TSV path."""
    if "values" in args and args["values"]:
        return args["values"]
    data_in = args.get("data_in_path")
    if not data_in or not Path(data_in).exists():
        raise ValueError("write/append: provide values[] or data_in_path.")
    import csv
    rows = []
    with open(data_in, "r", newline="") as f:
        for row in csv.reader(f, delimiter="\t"):
            # Convert numeric-looking cells to numbers so the Sheet stores
            # them as numbers (USER_ENTERED still applies but pre-typed
            # cells render cleaner).
            out = []
            for c in row:
                if c == "":
                    out.append("")
                else:
                    try:
                        if "." in c or "e" in c.lower():
                            out.append(float(c))
                        else:
                            out.append(int(c))
                    except (TypeError, ValueError):
                        out.append(c)
            rows.append(out)
    return rows


def cmd_write_range(args, sheets, drive):
    spreadsheet_id = parse_spreadsheet_id(args["spreadsheet"])
    a1 = _build_range(args.get("sheet"), args.get("range"))
    values = _read_values_from_args(args)
    resp = sheets.spreadsheets().values().update(
        spreadsheetId=spreadsheet_id,
        range=a1,
        valueInputOption=args.get("value_input", "USER_ENTERED"),
        body={"values": values},
    ).execute()
    return {
        "updatedCells":   resp.get("updatedCells"),
        "updatedRange":   resp.get("updatedRange"),
        "updatedRows":    resp.get("updatedRows"),
        "updatedColumns": resp.get("updatedColumns"),
    }


def cmd_append_range(args, sheets, drive):
    spreadsheet_id = parse_spreadsheet_id(args["spreadsheet"])
    a1 = _build_range(args.get("sheet"), args.get("range"))
    values = _read_values_from_args(args)
    resp = sheets.spreadsheets().values().append(
        spreadsheetId=spreadsheet_id,
        range=a1,
        valueInputOption=args.get("value_input", "USER_ENTERED"),
        insertDataOption=args.get("insert_data", "INSERT_ROWS"),
        body={"values": values},
    ).execute()
    return {
        "updatedRange": resp.get("updates", {}).get("updatedRange"),
        "updatedRows":  resp.get("updates", {}).get("updatedRows"),
    }


def cmd_clear_range(args, sheets, drive):
    spreadsheet_id = parse_spreadsheet_id(args["spreadsheet"])
    a1 = _build_range(args.get("sheet"), args.get("range"))
    sheets.spreadsheets().values().clear(
        spreadsheetId=spreadsheet_id, range=a1, body={}
    ).execute()
    return {"cleared": a1}


def _sheet_id_by_title(sheets, spreadsheet_id, title):
    md = sheets.spreadsheets().get(
        spreadsheetId=spreadsheet_id, includeGridData=False,
        fields="sheets.properties(title,sheetId)",
    ).execute()
    for s in md.get("sheets", []):
        if s["properties"]["title"] == title:
            return s["properties"]["sheetId"]
    raise KeyError(f"sheet '{title}' not found in spreadsheet")


def cmd_add_sheet(args, sheets, drive):
    spreadsheet_id = parse_spreadsheet_id(args["spreadsheet"])
    title = args["title"]
    add_req = {"addSheet": {"properties": {"title": title}}}
    if "rows" in args:
        add_req["addSheet"]["properties"].setdefault("gridProperties", {})["rowCount"] = int(args["rows"])
    if "cols" in args:
        add_req["addSheet"]["properties"].setdefault("gridProperties", {})["columnCount"] = int(args["cols"])
    if args.get("index") is not None:
        add_req["addSheet"]["properties"]["index"] = int(args["index"])
    resp = sheets.spreadsheets().batchUpdate(
        spreadsheetId=spreadsheet_id, body={"requests": [add_req]},
    ).execute()
    new = resp["replies"][0]["addSheet"]["properties"]
    return {"title": new["title"], "sheetId": new["sheetId"]}


def cmd_delete_sheet(args, sheets, drive):
    spreadsheet_id = parse_spreadsheet_id(args["spreadsheet"])
    if "sheet_id" in args:
        sid = int(args["sheet_id"])
    else:
        sid = _sheet_id_by_title(sheets, spreadsheet_id, args["title"])
    sheets.spreadsheets().batchUpdate(
        spreadsheetId=spreadsheet_id,
        body={"requests": [{"deleteSheet": {"sheetId": sid}}]},
    ).execute()
    return {"deleted_sheet_id": sid}


def cmd_rename_sheet(args, sheets, drive):
    spreadsheet_id = parse_spreadsheet_id(args["spreadsheet"])
    sid = _sheet_id_by_title(sheets, spreadsheet_id, args["old_title"])
    sheets.spreadsheets().batchUpdate(
        spreadsheetId=spreadsheet_id,
        body={"requests": [{
            "updateSheetProperties": {
                "properties": {"sheetId": sid, "title": args["new_title"]},
                "fields": "title",
            }
        }]},
    ).execute()
    return {"sheetId": sid, "title": args["new_title"]}


def _hex_to_rgb(h):
    h = h.lstrip("#")
    if len(h) == 3:
        h = "".join(c * 2 for c in h)
    if len(h) != 6:
        raise ValueError(f"bad hex colour: '{h}'")
    return {
        "red":   int(h[0:2], 16) / 255.0,
        "green": int(h[2:4], 16) / 255.0,
        "blue":  int(h[4:6], 16) / 255.0,
    }


def _parse_a1_range(a1):
    """Return (sheetTitle, startCol, startRow, endCol, endRow) -- 0-based,
    end-exclusive.  Used to build GridRange requests.
    """
    m = re.match(r"^(?:'?([^'!]+)'?!)?([A-Z]+)(\d+)(?::([A-Z]+)(\d+))?$", a1.strip())
    if not m:
        raise ValueError(f"can't parse A1 range: '{a1}'")
    sheet, c1, r1, c2, r2 = m.groups()

    def col_to_idx(col):
        n = 0
        for ch in col:
            n = n * 26 + (ord(ch) - 64)
        return n - 1

    start_col = col_to_idx(c1)
    start_row = int(r1) - 1
    end_col   = col_to_idx(c2) + 1 if c2 else start_col + 1
    end_row   = int(r2)         if r2 else start_row + 1
    return sheet, start_col, start_row, end_col, end_row


def cmd_format_range(args, sheets, drive):
    """Apply background, font weight, font color, and number format to a range.

    Args:
        range: A1 notation (e.g. "Sheet1!A1:E1")
        bgcolor: "#1B2D55" hex (optional)
        fgcolor: "#FFFFFF" hex (optional)
        bold:    bool (optional)
        font:    str  (optional, e.g. "Montserrat")
        font_size: int (optional)
        number_format: str (optional, e.g. "0.0%", "#,##0", "yyyy-mm-dd")
    """
    spreadsheet_id = parse_spreadsheet_id(args["spreadsheet"])
    a1 = args["range"]
    if not re.match(r"^.+!", a1):
        if args.get("sheet"):
            a1 = f"'{args['sheet']}'!{a1}"
    sheet_title, sc, sr, ec, er = _parse_a1_range(a1)
    if not sheet_title:
        raise ValueError("format_range requires a sheet name in the range or as sheet()")
    sid = _sheet_id_by_title(sheets, spreadsheet_id, sheet_title)

    cell_format = {}
    text_format = {}
    if args.get("bgcolor"):
        cell_format["backgroundColor"] = _hex_to_rgb(args["bgcolor"])
    if args.get("fgcolor"):
        text_format["foregroundColor"] = _hex_to_rgb(args["fgcolor"])
    if args.get("bold") is not None:
        text_format["bold"] = bool(args["bold"])
    if args.get("italic") is not None:
        text_format["italic"] = bool(args["italic"])
    if args.get("font"):
        text_format["fontFamily"] = args["font"]
    if args.get("font_size"):
        text_format["fontSize"] = int(args["font_size"])
    if text_format:
        cell_format["textFormat"] = text_format
    if args.get("number_format"):
        cell_format["numberFormat"] = {"type": "NUMBER", "pattern": args["number_format"]}
    if args.get("horizontal_align"):
        cell_format["horizontalAlignment"] = args["horizontal_align"].upper()
    if args.get("wrap"):
        cell_format["wrapStrategy"] = "WRAP"

    if not cell_format:
        raise ValueError("format_range: nothing to apply (pass at least one styling arg).")

    grid_range = {
        "sheetId":          sid,
        "startRowIndex":    sr,
        "endRowIndex":      er,
        "startColumnIndex": sc,
        "endColumnIndex":   ec,
    }
    # Compute the `fields' mask -- only update the fields we actually set.
    fields = []
    if "backgroundColor" in cell_format:
        fields.append("userEnteredFormat.backgroundColor")
    if "numberFormat" in cell_format:
        fields.append("userEnteredFormat.numberFormat")
    if "horizontalAlignment" in cell_format:
        fields.append("userEnteredFormat.horizontalAlignment")
    if "wrapStrategy" in cell_format:
        fields.append("userEnteredFormat.wrapStrategy")
    if text_format:
        fields.append("userEnteredFormat.textFormat")
    req = {
        "repeatCell": {
            "range": grid_range,
            "cell":  {"userEnteredFormat": cell_format},
            "fields": ",".join(fields),
        }
    }
    sheets.spreadsheets().batchUpdate(
        spreadsheetId=spreadsheet_id, body={"requests": [req]},
    ).execute()
    return {"formatted_range": a1, "fields": fields}


def _parse_grid_range(sheet_id, a1):
    """Convert 'A1:B5' (or '$A$1:$B$5') to a Sheets API GridRange dict.
    sheet_id is the integer sheet id of the SOURCE sheet."""
    m = re.match(r"^\$?([A-Z]+)\$?(\d+)(?::\$?([A-Z]+)\$?(\d+))?$", a1.strip())
    if not m:
        raise ValueError(f"can't parse A1 range '{a1}'")
    c1, r1, c2, r2 = m.groups()
    def col_idx(s):
        n = 0
        for ch in s: n = n*26 + (ord(ch) - 64)
        return n - 1
    return {
        "sheetId":          sheet_id,
        "startColumnIndex": col_idx(c1),
        "endColumnIndex":   col_idx(c2 or c1) + 1,
        "startRowIndex":    int(r1) - 1,
        "endRowIndex":      int(r2 or r1),
    }


def cmd_add_chart(args, sheets, drive):
    """Insert a chart object via spreadsheets.batchUpdate.addChart.

    Args:
        spreadsheet:    spreadsheet id or URL
        sheet:          source sheet title (where data lives)
        chart_type:     column | bar | stacked_column | stacked_bar |
                        line | area | scatter | pie | donut
        domain_range:   A1 of the domain (category / x-axis) cells, e.g. "A3:A8"
        series_ranges:  list of A1 ranges, one per series, e.g. ["B3:B8","C3:C8"]
        series_names:   optional list of legend labels (per series)
        series_colors:  optional list of hex strings (#1B2D55) per series
        title:          chart title
        subtitle:       chart subtitle (basic charts only)
        legend_position: TOP / RIGHT / BOTTOM / LEFT / NONE / LABELED_LEGEND  (default BOTTOM)
        target_sheet:   sheet title where the chart should be placed; defaults to sheet
        target_cell:    anchor cell on target_sheet (e.g. "H1"); offsets the chart there
        pie_hole:       float 0-1, donut hole fraction (only for pie)
        font_family:    string ("Montserrat" if tx2036style)
        title_color:    string ("#1B2D55" if tx2036style)
        is_horizontal:  bool -- for basicChart: true makes bars horizontal (BAR vs COLUMN)
    """
    spreadsheet_id = parse_spreadsheet_id(args["spreadsheet"])
    sheet_title    = args["sheet"]
    sid            = _sheet_id_by_title(sheets, spreadsheet_id, sheet_title)
    chart_type     = args.get("chart_type", "column").lower()

    domain_a1   = args["domain_range"]
    series_a1s  = args.get("series_ranges", [])
    if isinstance(series_a1s, str):
        series_a1s = [s.strip() for s in series_a1s.split("|") if s.strip()]
    series_names  = args.get("series_names", [])
    if isinstance(series_names, str):
        series_names = [s for s in series_names.split("|")]
    series_colors = args.get("series_colors", [])
    if isinstance(series_colors, str):
        series_colors = [s for s in series_colors.split("|") if s.strip()]

    domain_grid = _parse_grid_range(sid, domain_a1)
    series_grids = [_parse_grid_range(sid, a) for a in series_a1s]

    title          = args.get("title", "")
    subtitle       = args.get("subtitle", "")
    legend_pos     = args.get("legend_position", "BOTTOM_LEGEND")
    font_family    = args.get("font_family")
    title_color    = args.get("title_color")

    # Title text format
    title_fmt = {}
    if font_family: title_fmt["fontFamily"] = font_family
    if title_color: title_fmt["foregroundColor"] = _hex_to_rgb(title_color)
    title_fmt.setdefault("bold", True)
    title_fmt.setdefault("fontSize", 14)

    # -- Build the type-specific chart spec --
    spec = {"title": title}
    if subtitle: spec["subtitle"] = subtitle
    spec["titleTextFormat"] = title_fmt

    if chart_type in ("pie", "donut"):
        spec["pieChart"] = {
            "legendPosition": legend_pos,
            "domain": {"sourceRange": {"sources": [domain_grid]}},
            "series": {"sourceRange": {"sources": [series_grids[0]]}},
        }
        if chart_type == "donut" or args.get("pie_hole"):
            spec["pieChart"]["pieHole"] = float(args.get("pie_hole", 0.5))
    else:
        # basicChart: column / bar / stacked / line / area / scatter
        basic_type = {
            "column":          "COLUMN",
            "stacked_column":  "COLUMN",
            "bar":             "BAR",
            "stacked_bar":     "BAR",
            "line":            "LINE",
            "area":            "AREA",
            "scatter":         "SCATTER",
        }.get(chart_type, "COLUMN")
        stacked = "STACKED" if chart_type.startswith("stacked_") else "NOT_STACKED"

        # Bar charts (horizontal) require series on BOTTOM_AXIS;
        # column / line / area use LEFT_AXIS.
        target_axis = "BOTTOM_AXIS" if basic_type == "BAR" else "LEFT_AXIS"
        series_objs = []
        for i, gr in enumerate(series_grids):
            so = {"series": {"sourceRange": {"sources": [gr]}},
                   "targetAxis": target_axis}
            if i < len(series_colors) and series_colors[i]:
                so["colorStyle"] = {"rgbColor": _hex_to_rgb(series_colors[i])}
            series_objs.append(so)

        spec["basicChart"] = {
            "chartType":      basic_type,
            "legendPosition": legend_pos,
            "headerCount":    1 if args.get("has_header") else 0,
            "axis": [
                {"position": "BOTTOM_AXIS", "title": args.get("xlabel", "")},
                {"position": "LEFT_AXIS",   "title": args.get("ylabel", "")},
            ],
            "domains": [{"domain": {"sourceRange": {"sources": [domain_grid]}}}],
            "series":  series_objs,
        }
        # stackedType is rejected by the API for LINE / SCATTER charts;
        # only attach it for chart families that actually stack.
        if basic_type in ("COLUMN", "BAR", "AREA"):
            spec["basicChart"]["stackedType"] = stacked

    # -- Position the chart object --
    target_sheet_title = args.get("target_sheet") or sheet_title
    target_sid = _sheet_id_by_title(sheets, spreadsheet_id, target_sheet_title)
    target_cell = args.get("target_cell", "H1")
    tg = _parse_grid_range(target_sid, target_cell)
    width  = int(args.get("width", 540))
    height = int(args.get("height", 360))

    add_chart_req = {
        "addChart": {
            "chart": {
                "spec": spec,
                "position": {
                    "overlayPosition": {
                        "anchorCell": {
                            "sheetId":     target_sid,
                            "rowIndex":    tg["startRowIndex"],
                            "columnIndex": tg["startColumnIndex"],
                        },
                        "widthPixels":  width,
                        "heightPixels": height,
                    }
                }
            }
        }
    }
    resp = sheets.spreadsheets().batchUpdate(
        spreadsheetId=spreadsheet_id, body={"requests": [add_chart_req]},
    ).execute()
    new_chart = resp["replies"][0]["addChart"]["chart"]
    return {
        "chartId":       new_chart.get("chartId"),
        "target_sheet":  target_sheet_title,
        "target_cell":   target_cell,
        "chart_type":    chart_type,
    }


def cmd_create_spreadsheet(args, sheets, drive):
    """Create a new spreadsheet in the user's Drive; optionally name its first
    tab via 'sheet_title'.  Returns the new spreadsheetId and spreadsheetUrl so
    the caller can immediately write to it."""
    title = args.get("title") or "Untitled spreadsheet"
    body = {"properties": {"title": title}}
    if args.get("sheet_title"):
        body["sheets"] = [{"properties": {"title": args["sheet_title"]}}]
    resp = sheets.spreadsheets().create(
        body=body,
        fields="spreadsheetId,spreadsheetUrl,properties.title",
    ).execute()
    return {
        "spreadsheetId":  resp["spreadsheetId"],
        "spreadsheetUrl": resp.get("spreadsheetUrl", ""),
        "title":          resp.get("properties", {}).get("title", title),
    }


SUBCOMMANDS = {
    "create_spreadsheet": cmd_create_spreadsheet,
    "ping":           cmd_ping,
    "read_range":     cmd_read_range,
    "write_range":    cmd_write_range,
    "append_range":   cmd_append_range,
    "clear_range":    cmd_clear_range,
    "list_sheets":    cmd_list_sheets,
    "add_sheet":      cmd_add_sheet,
    "delete_sheet":   cmd_delete_sheet,
    "rename_sheet":   cmd_rename_sheet,
    "format_range":   cmd_format_range,
    "get_metadata":   cmd_get_metadata,
    "add_chart":      cmd_add_chart,
}


def main():
    if len(sys.argv) < 3:
        sys.stderr.write("usage: googlesheets_helper.py <args.json> <out.json>\n")
        sys.exit(2)
    args_path, out_path = sys.argv[1], sys.argv[2]

    try:
        with open(args_path, "r") as f:
            args = json.load(f)

        _ensure_libs(args.get("auto_install", True))

        sub = args.get("subcommand")
        if sub not in SUBCOMMANDS:
            raise ValueError(f"unknown subcommand '{sub}'. Known: {sorted(SUBCOMMANDS)}")

        creds  = get_credentials(args["client_json"], args["token_json"])
        sheets = get_service(creds, "sheets", "v4")
        drive  = get_service(creds, "drive",  "v3")

        result = SUBCOMMANDS[sub](args, sheets, drive)
        payload = {"status": "ok", "result": result}

    except Exception as e:
        payload = {
            "status":    "error",
            "error":     type(e).__name__,
            "message":   str(e),
            "traceback": traceback.format_exc(),
        }

    # Write a flat key=value summary that the Stata side reads line-by-line.
    # The "=" separator is reliable because (a) Stata's tokenize parses on
    # it natively, and (b) "=" is rarer than tab/colon inside spreadsheet
    # titles or row content (which is escaped to "_eq_" if present).
    def _safekey(s):  return str(s).replace("=", "_eq_").replace("\n", " ").replace("\r", " ")
    def _safeval(s):  return str(s).replace("\n", " ").replace("\r", " ")
    with open(out_path, "w") as f:
        f.write(f"status={payload['status']}\n")
        if payload["status"] == "ok":
            r = payload.get("result", {})
            for k, v in r.items():
                f.write(f"{_safekey(k)}={_safeval(_flatten(v))}\n")
        else:
            for k in ("error", "message"):
                if k in payload:
                    f.write(f"{k}={_safeval(_flatten(payload[k]))}\n")

    # Also write a sidecar JSON for callers who want the full payload.
    try:
        with open(out_path + ".json", "w") as f:
            json.dump(payload, f)
    except Exception:
        pass

    sys.exit(0 if payload["status"] == "ok" else 1)


def _flatten(v):
    if v is None:
        return ""
    if isinstance(v, (str, int, float, bool)):
        # Strip newlines / tabs so the key=value contract stays single-line.
        return str(v).replace("\t", " ").replace("\n", " ").replace("\r", " ")
    if isinstance(v, list):
        # Lists of scalars -> "|"-joined.  Lists of dicts -> the first
        # scalar field per dict ("title" preferred); good enough for
        # list_sheets -> "|"-joined titles.
        parts = []
        for item in v:
            if isinstance(item, dict):
                if "title" in item:
                    parts.append(str(item["title"]))
                else:
                    for vv in item.values():
                        if isinstance(vv, (str, int, float, bool)):
                            parts.append(str(vv))
                            break
            else:
                parts.append(str(item))
        return "|".join(p.replace("|", " ") for p in parts)
    if isinstance(v, dict):
        return json.dumps(v, separators=(",", ":"))
    return str(v)


if __name__ == "__main__":
    main()
