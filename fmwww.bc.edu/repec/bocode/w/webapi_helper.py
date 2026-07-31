#!/usr/bin/env python3
"""webapi_helper.py -- the network + JSON-to-table worker behind `webapi'.

Usage (called by webapi.ado, not by hand):
    python3 webapi_helper.py <args.json> <out.json>

Reads a request spec from <args.json>, performs one authenticated HTTP
request with the Python standard library only (no pip, no virtualenv),
parses the JSON reply, selects the array of records named by records(),
flattens each record's nested scalars into dotted column names, and writes
the result as a TSV that Stata materialises with `import delimited'.  A tiny
key=value status file is written to <out.json> for the ado to read.

Standard library only, so the package has no external dependencies: a working
python3 on PATH (which Stata 16+ ships or can point at) is all it needs.
"""
import sys, json, csv, ssl, base64
import urllib.request, urllib.parse, urllib.error


def _kv(raw, sep):
    """Parse a pipe-delimited 'key<sep>value|key<sep>value' string into a dict."""
    out = {}
    if not raw:
        return out
    for part in str(raw).split("|"):
        part = part.strip()
        if not part or sep not in part:
            continue
        k, v = part.split(sep, 1)
        out[k.strip()] = v.strip()
    return out


def _get_path(obj, path):
    """Navigate a dot path (e.g. 'data.items') to the array/object of records.
    An empty path returns the whole payload."""
    if not path:
        return obj
    cur = obj
    for part in path.split("."):
        if isinstance(cur, dict):
            cur = cur.get(part)
        elif isinstance(cur, list):
            try:
                cur = cur[int(part)]
            except (ValueError, IndexError):
                return None
        else:
            return None
    return cur


def _flatten(d, prefix=""):
    """Flatten a record's nested scalar fields into dotted column names.
    Nested arrays are kept as compact JSON strings so no data is silently lost."""
    out = {}
    if isinstance(d, dict):
        for k, v in d.items():
            key = prefix + str(k)
            if isinstance(v, dict):
                out.update(_flatten(v, key + "."))
            elif isinstance(v, list):
                out[key] = json.dumps(v, separators=(",", ":"))
            elif isinstance(v, bool):
                out[key] = int(v)
            else:
                out[key] = v
    else:
        out[prefix.rstrip(".") or "value"] = d
    return out


def _read_args(path):
    """Read the tab-separated key<TAB>value request spec written by webapi.ado.
    Using a flat key/value file (rather than JSON from the ado) means URLs,
    tokens, and parameter values need no escaping on the Stata side."""
    args = {}
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.rstrip("\n").rstrip("\r")
            if "\t" in line:
                k, v = line.split("\t", 1)
                args[k] = v
    return args


def run(args):
    url = args["url"]

    params = _kv(args.get("params_raw"), "=")
    if params:
        url += ("&" if "?" in url else "?") + urllib.parse.urlencode(params)

    headers = _kv(args.get("headers_raw"), ":")
    if args.get("bearer"):
        headers["Authorization"] = "Bearer " + args["bearer"]
    if args.get("basic"):
        u, _, p = str(args["basic"]).partition(":")
        headers["Authorization"] = "Basic " + base64.b64encode(f"{u}:{p}".encode()).decode()
    akh = _kv(args.get("apikey_header"), ":")
    for k, v in akh.items():
        headers[k] = v
    akp = _kv(args.get("apikey_param"), "=")
    if akp:
        url += ("&" if "?" in url else "?") + urllib.parse.urlencode(akp)

    data = None
    method = (args.get("method") or "GET").upper()
    body = args.get("body")
    if body is not None and body != "":
        data = str(body).encode("utf-8")
        headers.setdefault("Content-Type", "application/json")

    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    ctx = ssl.create_default_context()
    with urllib.request.urlopen(req, timeout=int(args.get("timeout", 30)), context=ctx) as resp:
        raw = resp.read().decode("utf-8", "replace")
        http_status = resp.getcode()

    payload = json.loads(raw)
    recs = _get_path(payload, args.get("records", ""))
    if isinstance(recs, dict):
        recs = [recs]
    if not isinstance(recs, list):
        got = type(recs).__name__
        raise ValueError(
            f"records('{args.get('records','')}') did not resolve to a JSON array "
            f"(got {got}); check the path against the API's reply"
        )

    rows = [_flatten(r) if isinstance(r, dict) else {"value": r} for r in recs]
    cols = []
    for r in rows:
        for k in r.keys():
            if k not in cols:
                cols.append(k)

    with open(args["out_tsv"], "w", newline="") as f:
        w = csv.writer(f, delimiter="\t", lineterminator="\n")
        w.writerow(cols)
        for r in rows:
            w.writerow(["" if r.get(c) is None else r.get(c) for c in cols])

    return {"status": "ok", "nrows": len(rows), "ncols": len(cols),
            "http_status": http_status}


def main():
    if len(sys.argv) < 3:
        sys.stderr.write("usage: webapi_helper.py <args.json> <out.json>\n")
        sys.exit(2)
    args_path, out_path = sys.argv[1], sys.argv[2]
    try:
        args = _read_args(args_path)
        result = run(args)
    except urllib.error.HTTPError as e:
        detail = ""
        try:
            detail = " -- " + e.read().decode("utf-8", "replace")[:300]
        except Exception:
            pass
        result = {"status": "error", "error": "HTTPError",
                  "message": f"{e.code} {e.reason}{detail}"}
    except urllib.error.URLError as e:
        result = {"status": "error", "error": "URLError", "message": str(e.reason)}
    except Exception as e:
        result = {"status": "error", "error": type(e).__name__, "message": str(e)}

    with open(out_path, "w") as f:
        for k, v in result.items():
            f.write(f"{k}={str(v).replace(chr(10), ' ').replace(chr(13), ' ')}\n")
    sys.exit(0 if result.get("status") == "ok" else 1)


if __name__ == "__main__":
    main()
