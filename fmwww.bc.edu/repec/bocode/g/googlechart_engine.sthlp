/* googlechart_engine.js -- Google Charts (Visualization API) renderer for the
   `googlechart` Stata package.  Loads the Google Charts CDN, applies a
   Texas 2036 brand theme, and dispatches per type() to a small per-chart
   renderer.

   Designed as a SIBLING (not a replacement) for sparkta2.  Trade-off
   vs sparkta2:
     - sparkta2 ships d3 + topojson inline; works offline.
     - googlechart uses Google Charts loader.js + per-package fetches
       from gstatic.com; CDN-only by Google ToS, requires network at view.
       In return: native filter controls (CategoryFilter, ChartRangeFilter,
       NumberRangeFilter), 14 chart types, polished default tooltips.

   The engine reads `window.__GOOGLECHART__` (emitted by
   googlechart_writehtml.ado) and renders into #chart.

   Supported types (v0.1):
     column, bar, line, area, combo, pie, donut, scatter, bubble, geo,
     timeline, table, histogram, divbar (Pew-style via sign-flip).

   Cross-cutting features (apply to every type that supports them):
     - tx2036style:    Montserrat + brand palette baked into chart options
     - download menu:  PNG (getImageURI), SVG (serialize), CSV
                       (dataTableToCsv), View data table toggle
     - datatable:      collapsible HTML table beneath the chart
     - animate:        IntersectionObserver gates chart.draw() until the
                       container scrolls into view (deferred-draw pattern,
                       not d3-transition pattern)
     - downloadpos:    side (default) | below | none
     - filters():      builds a google.visualization.Dashboard with
                       CategoryFilter / NumberRangeFilter per filter var
*/
(function () {
  "use strict";

  // ---- Brand palettes ------------------------------------------------------
  // tx2036 = Texas 2036 brand cycle.  Sequential / diverging palettes
  // mirror sparkta2's scheme names so existing users find them familiar.
  var PALETTES = {
    tx2036:   ["#1B2D55","#D44500","#2B6CB0","#6C7A8D","#7A9D54","#A67B36","#9C5BA5","#3F8A8C","#C0392B","#F1A208"],
    blues:    ["#deebf7","#9ecae1","#3182bd","#08519c","#08306b","#2171b5","#4292c6","#6baed6","#9ecae1","#c6dbef"],
    reds:     ["#fee5d9","#fcbba1","#fc9272","#fb6a4a","#ef3b2c","#cb181d","#a50f15","#67000d"],
    greens:   ["#e5f5e0","#c7e9c0","#a1d99b","#74c476","#41ab5d","#238b45","#006d2c","#00441b"],
    oranges:  ["#feedde","#fdd0a2","#fdae6b","#fd8d3c","#f16913","#d94801","#a63603","#7f2704"],
    purples:  ["#efedf5","#dadaeb","#bcbddc","#9e9ac8","#807dba","#6a51a3","#54278f","#3f007d"],
    rdbu:     ["#b2182b","#d6604d","#f4a582","#fddbc7","#f7f7f7","#d1e5f0","#92c5de","#4393c3","#2166ac"],
    rdylgn:   ["#a50026","#d73027","#f46d43","#fdae61","#fee08b","#d9ef8b","#a6d96a","#66bd63","#1a9850","#006837"],
    viridis:  ["#440154","#482878","#3e4989","#31688e","#26828e","#1f9e89","#35b779","#6ece58","#b5de2b","#fde725"]
  };

  // ---- Helpers -------------------------------------------------------------
  function esc(s) {
    return String(s == null ? "" : s)
      .replace(/&/g, "&amp;").replace(/</g, "&lt;")
      .replace(/>/g, "&gt;").replace(/"/g, "&quot;");
  }
  function fmt(v) {
    if (v == null || !isFinite(+v)) return "";
    var n = +v;
    if (Math.abs(n) >= 1000) return n.toLocaleString(undefined, { maximumFractionDigits: 0 });
    if (Math.abs(n) >= 1)    return n.toLocaleString(undefined, { maximumFractionDigits: 1 });
    return n.toLocaleString(undefined, { maximumFractionDigits: 2 });
  }
  function uniqueOrdered(items) {
    var seen = {}; var out = [];
    for (var i = 0; i < items.length; i++) {
      var k = String(items[i]);
      if (!seen[k]) { seen[k] = 1; out.push(items[i]); }
    }
    return out;
  }
  function paletteFor(meta) {
    var name = (meta.scheme || (meta.tx2036style ? "tx2036" : "blues")).toLowerCase();
    return PALETTES[name] || PALETTES.tx2036;
  }
  function brandOptions(meta) {
    // Common chart options used as the base; per-type renderers spread their
    // own overrides on top.
    var fontName = meta.tx2036style ? "Montserrat" : "Roboto, Arial, sans-serif";
    return {
      colors: paletteFor(meta),
      fontName: fontName,
      backgroundColor: "transparent",
      titleTextStyle: { color: "#1B2D55", bold: true, fontName: fontName, fontSize: 16 },
      legend: { position: "bottom", alignment: "center",
                textStyle: { color: "#6C7A8D", fontName: fontName, fontSize: 11 } },
      tooltip: { textStyle: { fontName: fontName, fontSize: 12 } },
      hAxis: { textStyle: { color: "#6C7A8D", fontName: fontName, fontSize: 11 },
               titleTextStyle: { color: "#1B2D55", fontName: fontName, fontSize: 12, italic: false },
               gridlines: { color: "#E4E7EB", count: -1 } },
      vAxis: { textStyle: { color: "#6C7A8D", fontName: fontName, fontSize: 11 },
               titleTextStyle: { color: "#1B2D55", fontName: fontName, fontSize: 12, italic: false },
               gridlines: { color: "#E4E7EB", count: -1 } },
      chartArea: { left: 80, top: 50, width: "75%", height: "70%" }
    };
  }

  // Deep merge for option objects (engine defaults <- user title/axes etc.)
  function deepMerge(a, b) {
    if (b == null) return a;
    if (typeof a !== "object" || Array.isArray(a)) return b;
    var out = {}; var k;
    for (k in a) out[k] = a[k];
    for (k in b) {
      if (b[k] && typeof b[k] === "object" && !Array.isArray(b[k])) {
        out[k] = deepMerge(a[k] || {}, b[k]);
      } else {
        out[k] = b[k];
      }
    }
    return out;
  }

  // Reshape long form [{name, value, series}, ...] to wide rows
  // [[<x>, <s1>, <s2>, ...], ...] keyed by name across series order.
  function longToWide(rows, xKey, valueKey, seriesKey) {
    var xs = uniqueOrdered(rows.map(function (r) { return r[xKey]; }));
    var series = seriesKey
      ? uniqueOrdered(rows.map(function (r) { return r[seriesKey]; }))
      : [valueKey];
    var byX = {};
    xs.forEach(function (x) {
      byX[x] = {};
      series.forEach(function (s) { byX[x][s] = null; });
    });
    rows.forEach(function (r) {
      var s = seriesKey ? r[seriesKey] : valueKey;
      var v = r[valueKey];
      byX[r[xKey]][s] = (v === "" || v == null) ? null : +v;
    });
    var out = xs.map(function (x) {
      var row = [x];
      series.forEach(function (s) { row.push(byX[x][s]); });
      return row;
    });
    return { xs: xs, series: series, rows: out };
  }

  // ---- Module load ---------------------------------------------------------
  function packagesNeeded(type, hasFilters, hasTime) {
    var base = ["corechart"];
    if (type === "table")     return hasFilters ? ["table","controls"] : ["table"];
    if (type === "geo")       return ["geochart"];
    if (type === "timeline")  base = ["timeline"];
    if (type === "sankey")    base = ["sankey"];
    if (type === "treemap")   base = ["treemap"];
    if (type === "calendar")  base = ["calendar"];
    if (type === "gauge")     base = ["gauge"];
    // Bubble with a time dimension also drives a Dashboard + ControlWrapper
    // for the Play button, so it needs controls too.
    if (hasFilters || (type === "bubble" && hasTime)) base.push("controls");
    return base;
  }

  function bootstrap(cfg) {
    var meta = cfg.meta || {};
    var hasFilters = !!(cfg.filters && cfg.filters.length);
    var hasTime = !!(meta.time && cfg.data && cfg.data.some(function (r) { return r.t != null; }));
    var pkgs = packagesNeeded((meta.type || "column").toLowerCase(), hasFilters, hasTime);
    if (typeof google === "undefined" || !google.charts) {
      // Loader hasn't arrived yet; retry on next frame
      setTimeout(function () { bootstrap(cfg); }, 50);
      return;
    }
    google.charts.load("current", { packages: pkgs });
    google.charts.setOnLoadCallback(function () { setup(cfg); });
  }

  // ---- Top-level setup -----------------------------------------------------
  function setup(cfg) {
    var meta = cfg.meta || {};
    var data = cfg.data || [];
    var filterDefs = cfg.filters || [];
    var tipvars = cfg.tooltipvars || [];

    // Build controls panel (Export + Filters), regardless of chart type.
    buildControlsPanel(meta, data, tipvars, filterDefs);

    // The actual chart instance + DataTable are constructed inside the
    // type-specific renderer.  Each renderer returns { chart, dataTable,
    // dashboard?, redraw } so the export menu can call back into them.
    var ctx = renderByType(meta, data, filterDefs);
    if (!ctx) return;

    // Hook the export-menu actions up to the just-built chart.
    wireExportMenu(meta, ctx, data, tipvars);

    // IntersectionObserver-gated initial draw.  Sparkta2 fades in elements
    // that already exist; Google Charts has to defer the .draw() itself.
    setupAnimateOnView(meta, ctx);
  }

  // ---- Dispatch by chart type ---------------------------------------------
  function renderByType(meta, data, filterDefs) {
    var type = (meta.type || "column").toLowerCase();
    switch (type) {
      case "column":     return renderXYChart(meta, data, "ColumnChart", filterDefs);
      case "bar":        return renderXYChart(meta, data, "BarChart",    filterDefs);
      case "line":       return renderXYChart(meta, data, "LineChart",   filterDefs);
      case "area":       return renderXYChart(meta, data, "AreaChart",   filterDefs);
      case "combo":      return renderCombo(meta, data, filterDefs);
      case "scatter":    return renderScatter(meta, data);
      case "pie":        return renderPie(meta, data, false);
      case "donut":      return renderPie(meta, data, true);
      case "bubble":     return renderBubble(meta, data);
      case "geo":        return renderGeo(meta, data);
      case "timeline":   return renderTimeline(meta, data);
      case "table":      return renderTable(meta, data, filterDefs);
      case "histogram":  return renderHistogram(meta, data);
      case "divbar":     return renderDivbar(meta, data);
      default:
        renderError("type(" + type + ") not recognised by googlechart_engine.js");
        return null;
    }
  }

  function renderError(msg) {
    var el = document.getElementById("chart");
    if (el) el.innerHTML = "<div style='padding:24px;color:#b34a3a;font:14px sans-serif'>"
      + esc(msg) + "</div>";
  }

  // ============================================================
  //                       XY-AXIS CHARTS
  //   column / bar / line / area / scatter share enough plumbing
  //   that one function handles all five with class-name swap.
  // ============================================================
  function renderXYChart(meta, data, className, filterDefs) {
    var W = +meta.width  || 980;
    var H = +meta.height || 560;
    var xKey  = "name";      // category / time
    var yKey  = "value";     // numeric value
    var sKey  = meta.over ? "g" : null;  // multi-series via Stata `over()`
    var wide  = longToWide(data, xKey, yKey, sKey);

    // Build DataTable from the wide reshape.
    var header = [meta.namelabel || meta.name || "x"];
    if (sKey) wide.series.forEach(function (s) { header.push(String(s)); });
    else      header.push(meta.xvar || meta.valuelabel || "value");

    var dt = new google.visualization.DataTable();
    // Column 0 type: detect if all xs are numbers (number axis) else string.
    var allNumeric = wide.xs.every(function (x) { return x !== "" && isFinite(+x); });
    dt.addColumn(allNumeric ? "number" : "string", header[0]);
    for (var i = 1; i < header.length; i++) dt.addColumn("number", header[i]);
    wide.rows.forEach(function (row) {
      var clean = row.slice();
      if (allNumeric) clean[0] = +clean[0];
      dt.addRow(clean);
    });

    // Direct-labels: for ColumnChart / BarChart, wrap in a DataView that
    // appends a stringify'd annotation column after each numeric series.
    // Classic corechart only -- material charts ignore the role.
    var drawSource = dt;
    if (meta.directlabels && (className === "ColumnChart" || className === "BarChart")) {
      var ncols = dt.getNumberOfColumns();
      var viewCols = [0];
      for (var ci = 1; ci < ncols; ci++) {
        viewCols.push(ci);
        viewCols.push({ calc: "stringify", sourceColumn: ci, type: "string", role: "annotation" });
      }
      var dv = new google.visualization.DataView(dt);
      dv.setColumns(viewCols);
      drawSource = dv;
    }

    var opts = deepMerge(brandOptions(meta), {
      title: meta.title || "",
      width: W, height: H,
      hAxis: {
        title: meta.xlabel || "",
        slantedText: (className === "ColumnChart" || className === "BarChart") && !allNumeric,
        slantedTextAngle: 30
      },
      vAxis: {
        title: meta.ylabel || "",
        baseline: 0
      },
      legend: { position: sKey ? "bottom" : "none" },
      isStacked: meta.stacked ? (meta.normalize ? "percent" : true) : false,
      animation: { startup: !!meta.animate, duration: 900, easing: "out" },
      // Make line and area charts readable -- thicker stroke + visible point markers
      // (Google's defaults are 2px stroke and zero markers, which can vanish at small sizes).
      lineWidth: (className === "LineChart" || className === "AreaChart") ? 3 : 2,
      pointSize: (className === "LineChart" || className === "AreaChart") ? 5
                 : (className === "ScatterChart" ? 6 : 0),
      areaOpacity: className === "AreaChart" ? 0.35 : undefined,
      annotations: {
        // alwaysOutside places the label outside the bar end.  The
        // `stem' is the short line Google draws from the bar to the
        // label; on a horizontal bar it renders as a leading dash that
        // makes positive values read as negative.  Hide the stem by
        // colouring it transparent but keep its length so the label
        // stays offset from the bar end.
        alwaysOutside: true,
        textStyle: {
          fontName: meta.tx2036style ? "Montserrat" : undefined,
          fontSize: 14, bold: true, color: "#1B2D55", auraColor: "none"
        },
        stem: { color: "transparent", length: 12 },
        highContrast: false,
        style: "point"
      }
    });
    // Bar charts read better with the title on hAxis (data dimension);
    // ColumnChart reads better with the title on vAxis.
    if (className === "BarChart") {
      opts.hAxis.title = meta.ylabel || opts.hAxis.title;
      opts.vAxis.title = meta.xlabel || opts.vAxis.title;
    }

    var container = document.getElementById("chart");
    var chart = new google.visualization[className](container);

    // If filters are requested, wire a Dashboard so the chart redraws
    // whenever filter state changes.
    var dashboard = null, chartWrapper = null;
    if (filterDefs && filterDefs.length) {
      dashboard = buildDashboardWithFilters(meta, dt, filterDefs, className, opts);
      // dashboard.draw is the entry point in dashboard mode; the chart
      // instance is owned by the wrapper.
      return {
        type: "dashboard", className: className, dashboard: dashboard, dataTable: dt, opts: opts,
        draw: function () { dashboard.draw(dt); }
      };
    }
    return {
      type: "chart", className: className, chart: chart, dataTable: dt, opts: opts,
      draw: function () { chart.draw(drawSource, opts); }
    };
  }

  // ============================================================
  //                          COMBO CHART
  //   Same as XY but with per-series chartType overrides via
  //   meta.combo_types ("line|bars|area").
  // ============================================================
  function renderCombo(meta, data, filterDefs) {
    var W = +meta.width  || 980;
    var H = +meta.height || 560;
    var wide = longToWide(data, "name", "value", meta.over ? "g" : null);
    var dt = new google.visualization.DataTable();
    dt.addColumn("string", meta.namelabel || meta.name || "x");
    wide.series.forEach(function (s) { dt.addColumn("number", String(s)); });
    wide.rows.forEach(function (r) { dt.addRow(r); });

    // combo_types pipe-list maps to series:{0:{type},1:{type},...}
    var defaultType = (meta.combo_default || "bars").toLowerCase();
    var perSeries = (meta.combo_types || "").split("|").filter(Boolean);
    var seriesOpts = {};
    wide.series.forEach(function (s, i) {
      var t = perSeries[i] || defaultType;
      // For line-type combo series, default to thicker stroke + visible
      // point markers so the line stands apart from the bars and isn't
      // lost against the chart background.
      var sOpt = { type: t };
      if (t === "line" || t === "area") {
        sOpt.lineWidth = 3;
        sOpt.pointSize = 6;
      }
      seriesOpts[i] = sOpt;
    });

    var opts = deepMerge(brandOptions(meta), {
      title: meta.title || "",
      width: W, height: H,
      seriesType: defaultType,
      series: seriesOpts,
      hAxis: { title: meta.xlabel || "", slantedText: true, slantedTextAngle: 30 },
      vAxis: { title: meta.ylabel || "" },
      legend: { position: "bottom" },
      animation: { startup: !!meta.animate, duration: 900, easing: "out" }
    });
    var container = document.getElementById("chart");
    var chart = new google.visualization.ComboChart(container);
    return {
      type: "chart", className: "ComboChart", chart: chart, dataTable: dt, opts: opts,
      draw: function () { chart.draw(dt, opts); }
    };
  }

  // ============================================================
  //                       PIE / DONUT
  // ============================================================
  function renderPie(meta, data, isDonut) {
    var dt = new google.visualization.DataTable();
    dt.addColumn("string", meta.namelabel || meta.name || "slice");
    dt.addColumn("number", meta.valuelabel || "value");
    data.forEach(function (r) {
      dt.addRow([String(r.name), r.value == null ? null : +r.value]);
    });
    // PieChart does NOT honor animation.startup (Google has never
    // shipped it for pie -- confirmed by their docs + issue #330).
    // Instead, fade the container in via CSS once the chart fires
    // 'ready', which gives a startup-animation feel without the
    // unsupported option.
    // Pie / donut layout: legend sits BELOW by default so the pie itself
    // is centred in a square-ish frame.  The previous "right" default
    // reserved a wide legend column that pushed the pie left and left a
    // visible empty band on the right of the card.  `chartArea' is
    // expanded so the pie nearly fills the SVG.
    var legendPos = meta.labelwrap === "outside" ? "labeled"
                   : (meta.legendpos || "bottom");
    var opts = deepMerge(brandOptions(meta), {
      title: meta.title || "",
      width: +meta.width || 640, height: +meta.height || 520,
      pieHole: isDonut ? (+meta.innerradius || 0.45) : 0,
      legend: { position: legendPos, alignment: "center",
                textStyle: { fontSize: 11 } },
      chartArea: { left: "6%", right: "6%", top: "12%",
                   width: "88%", height: legendPos === "bottom" ? "70%" : "78%" },
      pieSliceText: meta.directlabels ? "percentage" : "value",
      pieSliceTextStyle: { fontSize: 12, color: "#FFFFFF" },
      sliceVisibilityThreshold: 0.005
    });
    var container = document.getElementById("chart");
    var chart = new google.visualization.PieChart(container);
    if (meta.animate) {
      // Pie / donut don't honor Google's animation.startup (issue #330);
      // substitute a fade + scale-up pop on the chart's 'ready' event.
      // 1100 ms is long enough to be perceptible on first view but
      // short enough to feel snappy.
      container.style.opacity = "0";
      container.style.transform = "scale(0.88)";
      container.style.transformOrigin = "center center";
      container.style.transition = "opacity 1100ms ease-out, transform 1100ms cubic-bezier(.22,1.1,.36,1)";
      google.visualization.events.addListener(chart, "ready", function () {
        // setTimeout instead of requestAnimationFrame because rAF can
        // be throttled by the browser when the iframe document isn't
        // fully visible (sparkta2_dashboard embeds these in iframes).
        setTimeout(function () {
          container.style.opacity = "1";
          container.style.transform = "scale(1)";
        }, 16);
      });
    }
    return {
      type: "chart", className: "PieChart", chart: chart, dataTable: dt, opts: opts,
      draw: function () { chart.draw(dt, opts); }
    };
  }

  // ============================================================
  //                       SCATTER CHART
  //   Inputs in long form: { x, y, g (optional series) }
  //   Each row is one point.  When `g' (series) is present, reshape so
  //   each series gets its own numeric Y column.
  // ============================================================
  function renderScatter(meta, data) {
    var hasSeries = data.length > 0 && data.some(function (r) { return r.g != null; });
    var dt = new google.visualization.DataTable();
    dt.addColumn("number", meta.xlabel || "x");
    if (hasSeries) {
      var seriesList = uniqueOrdered(data.map(function (r) { return String(r.g || ""); }));
      seriesList.forEach(function (s) { dt.addColumn("number", s); });
      data.forEach(function (r) {
        var row = [r.x == null ? null : +r.x];
        seriesList.forEach(function (s) {
          row.push(String(r.g || "") === s ? (r.y == null ? null : +r.y) : null);
        });
        dt.addRow(row);
      });
    } else {
      dt.addColumn("number", meta.ylabel || "y");
      data.forEach(function (r) {
        dt.addRow([r.x == null ? null : +r.x, r.y == null ? null : +r.y]);
      });
    }
    var opts = deepMerge(brandOptions(meta), {
      title: meta.title || "",
      width:  +meta.width  || 980,
      height: +meta.height || 644,
      hAxis: { title: meta.xlabel || "" },
      vAxis: { title: meta.ylabel || "" },
      legend: { position: hasSeries ? "bottom" : "none" },
      pointSize: 8,
      animation: { startup: !!meta.animate, duration: 900, easing: "out" }
    });
    var container = document.getElementById("chart");
    var chart = new google.visualization.ScatterChart(container);
    return {
      type: "chart", className: "ScatterChart", chart: chart, dataTable: dt, opts: opts,
      draw: function () { chart.draw(dt, opts); }
    };
  }

  // ============================================================
  //                       BUBBLE CHART
  //   Inputs in long form: { name, x, y, g (group/color), size }
  // ============================================================
  function renderBubble(meta, data) {
    var dt = new google.visualization.DataTable();
    dt.addColumn("string", "ID");
    dt.addColumn("number", meta.xlabel || "x");
    dt.addColumn("number", meta.ylabel || "y");
    // Column 3 type controls how Google Charts colours the bubbles:
    //   string -> categorical legend colours
    //   number -> continuous colorAxis gradient
    var groupIsNumeric = data.length > 0 && data.every(function (r) {
      return r.g == null || r.g === "" || isFinite(+r.g);
    });
    if (groupIsNumeric) dt.addColumn("number", meta.over || "color");
    else                dt.addColumn("string", meta.over || "group");
    dt.addColumn("number", "size");
    // Time column lives in the DataTable when meta.time is set, but is
    // HIDDEN from the chart via a DataView so BubbleChart doesn't try to
    // use it as series/color/size.
    var hasTime = !!meta.time && data.some(function (r) { return r.t != null; });
    if (hasTime) dt.addColumn("number", meta.time || "time");
    data.forEach(function (r) {
      var row = [
        String(r.name || ""),
        r.x == null ? null : +r.x,
        r.y == null ? null : +r.y,
        groupIsNumeric ? (r.g == null ? null : +r.g) : String(r.g || ""),
        r.size == null ? null : +r.size
      ];
      if (hasTime) row.push(r.t == null ? null : +r.t);
      dt.addRow(row);
    });

    // Fixed axis windows so motion is interpretable across time slices.
    var xs = data.map(function (r) { return +r.x; }).filter(isFinite);
    var ys = data.map(function (r) { return +r.y; }).filter(isFinite);
    function padded(arr) {
      var lo = Math.min.apply(null, arr), hi = Math.max.apply(null, arr);
      var pad = (hi - lo) * 0.08 || 1;
      return { min: lo - pad, max: hi + pad };
    }
    var xw = xs.length ? padded(xs) : null;
    var yw = ys.length ? padded(ys) : null;

    var opts = deepMerge(brandOptions(meta), {
      title: meta.title || "",
      width: +meta.width || 980, height: +meta.height || 560,
      hAxis: { title: meta.xlabel || "", viewWindow: xw },
      vAxis: { title: meta.ylabel || "", viewWindow: yw },
      bubble: { textStyle: { auraColor: "transparent",
                              color: "#1B2D55", fontName: meta.tx2036style ? "Montserrat" : "sans-serif",
                              fontSize: 10 },
                opacity: 0.78, stroke: "#1B2D55" },
      sizeAxis: { minSize: 3, maxSize: 36 },
      legend: { position: "right" }
    });
    // BubbleChart in plain (non-dashboard) mode does support
    // `animation.startup`, but inside a Dashboard / ChartWrapper the
    // same option throws "Cannot read properties of undefined (reading
    // 'Do')" on draw.  Apply animation only outside the dashboard path.
    if (!hasTime) {
      opts.animation = { startup: !!meta.animate, duration: 900, easing: "out" };
    }
    var container = document.getElementById("chart");

    if (hasTime) {
      // Build a Dashboard with a one-thumb NumberRangeFilter as the year
      // slider + a Play button that advances the filter through the
      // distinct time values to animate motion across time.
      var times = uniqueOrdered(data.map(function (r) { return +r.t; }))
                    .filter(isFinite).sort(function (a, b) { return a - b; });
      var tMin = times[0], tMax = times[times.length - 1];

      var dashRoot = document.getElementById("dashboard");
      if (!dashRoot) {
        dashRoot = document.createElement("div");
        dashRoot.id = "dashboard";
        container.parentNode.insertBefore(dashRoot, container);
      }
      var dash = new google.visualization.Dashboard(dashRoot);

      var filterHost = document.getElementById("gc-filters");
      if (!filterHost) {
        filterHost = document.createElement("div");
        filterHost.id = "gc-filters"; filterHost.className = "gc-filters";
        container.parentNode.insertBefore(filterHost, container);
      }
      filterHost.innerHTML = "";
      var slot = document.createElement("div");
      slot.id = "gc-filter-time";
      // The NumberRangeFilter renders its own label from filterColumnLabel, so
      // the wrapper does not add a second <label> here: doing so printed the
      // time variable's name twice above the slider.
      filterHost.appendChild(slot);
      var playBtn = document.createElement("button");
      playBtn.id = "gc-play"; playBtn.textContent = "▶ Play";
      playBtn.className = "gc-play";
      filterHost.appendChild(playBtn);

      var tFilter = new google.visualization.ControlWrapper({
        controlType: "NumberRangeFilter",
        containerId: slot.id,
        options: {
          filterColumnLabel: meta.time || "time",
          ui: { format: { pattern: "####" }, step: 1, labelStacking: "vertical" }
        },
        state: { lowValue: tMin, highValue: tMin }
      });
      var hideTimeCol = dt.getNumberOfColumns() - 1;
      var visibleCols = [];
      for (var ci = 0; ci < hideTimeCol; ci++) visibleCols.push(ci);
      var chartWrapper = new google.visualization.ChartWrapper({
        chartType: "BubbleChart",
        containerId: "chart",
        options: opts,
        view: { columns: visibleCols }
      });
      dash.bind(tFilter, chartWrapper);

      var playing = false, iv = null;
      playBtn.onclick = function () {
        if (playing) {
          clearInterval(iv); playing = false; playBtn.textContent = "▶ Play"; return;
        }
        playing = true; playBtn.textContent = "⏸ Pause";
        var idx = times.indexOf(+tFilter.getState().lowValue);
        if (idx < 0) idx = 0;
        iv = setInterval(function () {
          idx = (idx + 1) % times.length;
          tFilter.setState({ lowValue: times[idx], highValue: times[idx] });
          tFilter.draw();
          if (idx === times.length - 1) {
            clearInterval(iv); playing = false; playBtn.textContent = "▶ Play";
          }
        }, 900);
      };

      return {
        type: "dashboard", className: "BubbleChart", dashboard: dash, dataTable: dt, opts: opts,
        draw: function () { dash.draw(dt); }
      };
    }

    var chart = new google.visualization.BubbleChart(container);
    return {
      type: "chart", className: "BubbleChart", chart: chart, dataTable: dt, opts: opts,
      draw: function () { chart.draw(dt, opts); }
    };
  }

  // ============================================================
  //                          GEO CHART
  //   IMPORTANT: country and US state level only -- no county FIPS,
  //   no school-district shapes, no custom GeoJSON.  For sub-state
  //   Texas work, use sparkta2 instead.
  // ============================================================
  function renderGeo(meta, data) {
    var dt = new google.visualization.DataTable();
    dt.addColumn("string", "Region");
    dt.addColumn("number", meta.valuelabel || meta.xvar || "value");

    var region = (meta.geo_region || "world").toUpperCase();
    // Resolution alias map -- people reach for 'us-states' but Google
    // Charts spells it 'provinces' (the ISO 3166-2 spelling).  Translate.
    var rawRes = (meta.geo_resolution || "countries").toLowerCase();
    var resolution = rawRes;
    if (rawRes === "us-states" || rawRes === "states") resolution = "provinces";
    if (rawRes === "country" || rawRes === "world")    resolution = "countries";

    data.forEach(function (r) {
      var code = String(r.name == null ? "" : r.name).trim();
      // If region is US + resolution is provinces, accept bare postal
      // codes ('TX') and synthesize the ISO 3166-2 form ('US-TX').
      if (region === "US" && resolution === "provinces"
          && /^[A-Z]{2}$/.test(code.toUpperCase())) {
        code = "US-" + code.toUpperCase();
      }
      dt.addRow([code, r.value == null ? null : +r.value]);
    });

    var opts = deepMerge(brandOptions(meta), {
      title: meta.title || "",
      width: +meta.width || 980, height: +meta.height || 560,
      region: region === "WORLD" ? "world" : region,
      resolution: resolution,
      colorAxis: { colors: paletteFor(meta).slice(0, 5) },
      datalessRegionColor: "#E4E7EB",
      backgroundColor: "transparent"
    });
    var container = document.getElementById("chart");
    var chart = new google.visualization.GeoChart(container);
    return {
      type: "chart", className: "GeoChart", chart: chart, dataTable: dt, opts: opts,
      draw: function () { chart.draw(dt, opts); }
    };
  }

  // ============================================================
  //                          TIMELINE
  //   Gantt-style swimlanes.  Long-form input: { name (row label),
  //   g (bar label, optional), start (Date or year), end (Date or year) }.
  //   The wrapper converts to Date objects here.
  // ============================================================
  function renderTimeline(meta, data) {
    var dt = new google.visualization.DataTable();
    dt.addColumn("string", "Row");
    dt.addColumn("string", "Bar");
    dt.addColumn("date",   "Start");
    dt.addColumn("date",   "End");
    data.forEach(function (r) {
      var s = toDate(r.start); var e = toDate(r.end);
      if (!s || !e) return;
      dt.addRow([String(r.name || ""), String(r.g || r.name || ""), s, e]);
    });
    var opts = deepMerge(brandOptions(meta), {
      title: meta.title || "",
      width: +meta.width || 980, height: +meta.height || 560,
      backgroundColor: "transparent",
      timeline: { showRowLabels: true, colorByRowLabel: false,
                  rowLabelStyle: { fontName: meta.tx2036style ? "Montserrat" : "sans-serif", fontSize: 12, color: "#1B2D55" },
                  barLabelStyle: { fontName: meta.tx2036style ? "Montserrat" : "sans-serif", fontSize: 11 } }
    });
    var container = document.getElementById("chart");
    var chart = new google.visualization.Timeline(container);
    return {
      type: "chart", className: "Timeline", chart: chart, dataTable: dt, opts: opts,
      draw: function () { chart.draw(dt, opts); }
    };
  }
  function toDate(v) {
    if (v == null || v === "") return null;
    if (v instanceof Date) return v;
    // Allow plain year integers (treat as Jan 1 of that year).
    if (/^-?\d+(\.\d+)?$/.test(String(v))) {
      var n = +v;
      if (n >= 1000 && n <= 9999) return new Date(n, 0, 1);
      // Unix timestamp (seconds or ms)?
      return new Date(n);
    }
    var d = new Date(String(v));
    return isNaN(d.getTime()) ? null : d;
  }

  // ============================================================
  //                           TABLE
  //   Pure tabular view; no chart.  Inherits the dashboard +
  //   filter pattern so users can build filterable spreadsheets.
  // ============================================================
  function renderTable(meta, data, filterDefs) {
    // Build a wide DataTable from the row payload.  If `over` is set,
    // pivot to wide; otherwise show every row's full record.
    var cols = inferTableColumns(data);
    var dt = new google.visualization.DataTable();
    cols.forEach(function (c) { dt.addColumn(c.type, c.label); });
    data.forEach(function (r) {
      dt.addRow(cols.map(function (c) {
        var v = r[c.key];
        if (v == null || v === "") return null;
        if (c.type === "number") return +v;
        return String(v);
      }));
    });

    // Wrap the chart container so we can attach a search overlay + a
    // bordered card around the rendered table.  We only build the wrap
    // when there are no dashboard filters -- the dashboard owns #chart
    // directly via ChartWrapper(containerId:"chart") and wouldn't see
    // the wrapper's interior tableHost.
    var hasDashFilters = !!(filterDefs && filterDefs.length);
    var container = document.getElementById("chart");
    var wrap = null;
    var tableHost = container;
    var searchHost = null;
    var countHost = null;
    if (!hasDashFilters) {
      container.innerHTML = "";
      wrap = document.createElement("div");
      wrap.className = "gc-table-wrap";
      if (meta.table_search) {
        searchHost = document.createElement("div");
        searchHost.className = "gc-table-search";
        var inp = document.createElement("input");
        inp.type = "search";
        inp.placeholder = "Search rows…";
        inp.setAttribute("aria-label", "Search the table");
        countHost = document.createElement("span");
        countHost.className = "count";
        countHost.textContent = data.length + " rows";
        searchHost.appendChild(inp);
        searchHost.appendChild(countHost);
        wrap.appendChild(searchHost);
      }
      tableHost = document.createElement("div");
      wrap.appendChild(tableHost);
      container.appendChild(wrap);
    }

    var numericCols = [];
    cols.forEach(function (c, i) { if (c.type === "number") numericCols.push(i); });

    var opts = {
      title: meta.title || "",
      // Intentionally NOT setting `width' for tables -- Google's default
      // is to fill the container, which then plays nicely with the
      // per-cell min-widths + .gc-table-wrap overflow-x:auto.  When a
      // fixed width IS set on a Table, Google's inner host carves a
      // narrower scroll region that doesn't fill the card; the user
      // sees an odd empty strip to the right of the rendered table.
      height: +meta.height || 560,
      page: data.length > 25 ? "enable" : "disable",
      pageSize: meta.table_pagesize > 0 ? +meta.table_pagesize : 25,
      sort: "enable",
      allowHtml: true,
      sortAscending: true,
      cssClassNames: {
        headerRow: "gc-table-head",
        tableRow: "gc-table-row",
        oddTableRow: "gc-table-row gc-table-row-odd",
        selectedTableRow: "gc-table-row-sel",
        hoverTableRow: "gc-table-row-over",
        headerCell: "gc-table-cell-head",
        tableCell: "gc-table-cell",
        rowNumberCell: "gc-table-rownum"
      }
    };

    // Right-align + tabular-num the numeric columns once the chart fires
    // 'ready' -- Google Charts injects fresh <td>s on every redraw so we
    // re-apply the class instead of relying on a CSS :nth-child rule.
    function classifyNumericCells() {
      if (!numericCols.length) return;
      var tds = tableHost.querySelectorAll(".google-visualization-table-table tr td");
      var ncols = cols.length;
      tds.forEach(function (td, i) {
        if (numericCols.indexOf(i % ncols) >= 0) td.classList.add("gc-num");
      });
    }

    var chart = new google.visualization.Table(tableHost);
    google.visualization.events.addListener(chart, "ready", classifyNumericCells);
    google.visualization.events.addListener(chart, "sort",  function () { setTimeout(classifyNumericCells, 0); });
    google.visualization.events.addListener(chart, "page",  function () { setTimeout(classifyNumericCells, 0); });

    // Client-side search: filter the underlying DataView on each
    // keystroke.  We rebuild a DataView with setRows() so pagination +
    // sort still work on the filtered subset.
    if (searchHost) {
      var inputEl = searchHost.querySelector("input");
      var allRows = [];
      for (var i = 0; i < dt.getNumberOfRows(); i++) allRows.push(i);
      var view = new google.visualization.DataView(dt);
      view.setRows(allRows);
      var debounce = null;
      inputEl.addEventListener("input", function () {
        clearTimeout(debounce);
        debounce = setTimeout(function () {
          var q = inputEl.value.trim().toLowerCase();
          var matched = q === "" ? allRows.slice() : allRows.filter(function (rowIdx) {
            for (var ci = 0; ci < cols.length; ci++) {
              var v = dt.getValue(rowIdx, ci);
              if (v != null && String(v).toLowerCase().indexOf(q) >= 0) return true;
            }
            return false;
          });
          view.setRows(matched);
          countHost.textContent = matched.length + (matched.length === 1 ? " row" : " rows") +
                                   (q ? " (filtered from " + allRows.length + ")" : "");
          chart.draw(view, opts);
        }, 120);
      });
      // First draw uses the view so the chart and the view stay coupled.
      if (filterDefs && filterDefs.length) {
        // Dashboard mode below owns the draw; the search overlay coexists
        // with the dashboard's filters (search refines the view further).
        var dashboard = buildDashboardWithFilters(meta, dt, filterDefs, "Table", opts);
        return { type: "dashboard", className: "Table", dashboard: dashboard, dataTable: dt, opts: opts,
                 draw: function () { dashboard.draw(dt); } };
      }
      return { type: "chart", className: "Table", chart: chart, dataTable: dt, opts: opts,
               draw: function () { chart.draw(view, opts); } };
    }

    if (filterDefs && filterDefs.length) {
      var dashboard2 = buildDashboardWithFilters(meta, dt, filterDefs, "Table", opts);
      return { type: "dashboard", className: "Table", dashboard: dashboard2, dataTable: dt, opts: opts,
               draw: function () { dashboard2.draw(dt); } };
    }
    return { type: "chart", className: "Table", chart: chart, dataTable: dt, opts: opts,
             draw: function () { chart.draw(dt, opts); } };
  }
  function inferTableColumns(data) {
    if (!data.length) return [];
    // Union of keys across all rows -- the first row may have fewer keys
    // than later rows when some fields are conditional in the Stata emit.
    var keySet = {}, keys = [];
    data.forEach(function (r) {
      Object.keys(r).forEach(function (k) {
        if (!keySet[k]) { keySet[k] = 1; keys.push(k); }
      });
    });
    // Filter out the placeholder `_' field the Stata wrapper writes so
    // type(table) rows have valid JSON when no varlist is supplied.
    keys = keys.filter(function (k) { return k !== "_"; });
    return keys.map(function (k) {
      // Tooltip-prefixed columns get a cleaner label
      var label = k;
      if (k.indexOf("t__") === 0) label = k.slice(3);
      // Sniff type from the first non-null observation
      var isNum = true;
      for (var i = 0; i < data.length; i++) {
        var v = data[i][k];
        if (v == null || v === "") continue;
        if (!isFinite(+v) || /^[\-+]?\d+(\.\d+)?$/.test(String(v)) === false && typeof v !== "number") {
          isNum = false; break;
        }
      }
      return { key: k, label: label, type: isNum ? "number" : "string" };
    });
  }

  // ============================================================
  //                         HISTOGRAM
  //   Pass raw observations.  For large n we pre-bin in Stata
  //   (the wrapper toggles this), so the engine just renders.
  // ============================================================
  function renderHistogram(meta, data) {
    var dt = new google.visualization.DataTable();
    // If data has a `g` (group) we treat as a labeled multi-series histogram;
    // otherwise a single-series flat histogram.
    var hasGroup = data.length > 0 && data[0].g != null;
    if (hasGroup) {
      dt.addColumn("string", meta.over || "group");
      dt.addColumn("number", meta.xvar || "value");
      data.forEach(function (r) { dt.addRow([String(r.g || ""), +r.value]); });
    } else {
      dt.addColumn("string", "obs");
      dt.addColumn("number", meta.xvar || "value");
      data.forEach(function (r, i) { dt.addRow([String(r.name || i+1), +r.value]); });
    }
    var opts = deepMerge(brandOptions(meta), {
      title: meta.title || "",
      width: +meta.width || 980, height: +meta.height || 560,
      legend: { position: hasGroup ? "bottom" : "none" },
      histogram: { bucketSize: meta.bucketsize > 0 ? +meta.bucketsize : "auto" },
      hAxis: { title: meta.xlabel || "" },
      vAxis: { title: meta.ylabel || "Count" },
      // Histogram IS in Google's animation table; startup grows bars
      // from 0 to height.  1200 ms makes the rise perceptible without
      // dragging.
      animation: { startup: !!meta.animate, duration: 1200, easing: "out" }
    });
    var container = document.getElementById("chart");
    var chart = new google.visualization.Histogram(container);
    return { type: "chart", className: "Histogram", chart: chart, dataTable: dt, opts: opts,
             draw: function () { chart.draw(dt, opts); } };
  }

  // ============================================================
  //                          DIVBAR
  //   Pew-style diverging stacked bar.  Google Charts has no
  //   native diverging mode; we fake it with isStacked:true and
  //   sign-flipped negative-side series.  Center level (e.g.
  //   "Neutral") is split 50/50 across the midline via an
  //   invisible "spacer" series.
  // ============================================================
  function renderDivbar(meta, data) {
    var levels = (meta.levelorder || "").split("|").filter(Boolean);
    if (!levels.length) {
      // Fall back to first-seen order from the data
      var seen = {}; levels = [];
      data.forEach(function (r) {
        var lv = r.lev; if (!seen[lv]) { seen[lv] = 1; levels.push(lv); }
      });
    }
    var centerLevel = meta.centerlevel || (levels.length % 2 === 1 ? levels[Math.floor(levels.length/2)] : null);
    // Partition levels into negative (left of center) and positive (right).
    var negs = [], pos = [], hitCenter = false;
    levels.forEach(function (lv) {
      if (lv === centerLevel) { hitCenter = true; return; }
      if (!hitCenter) negs.push(lv); else pos.push(lv);
    });

    // Reshape to wide: item x level -> share
    var items = uniqueOrdered(data.map(function (r) { return r.name; }));
    var byItem = {};
    items.forEach(function (it) { byItem[it] = {}; });
    data.forEach(function (r) { byItem[r.name][r.lev] = +r.value; });

    // Optional pre-wrap of long item labels.  Google Charts has no built-in
    // category-label wrapping (issue #690); the only mechanism that works
    // is embedded newlines in the row string.  Default to 50 chars for
    // divbar (where item labels are often full survey items); explicit
    // integer in labelwrap() overrides; off if labelwrap == "none".
    var wrapW = 50;
    if (meta.labelwrap === "none") wrapW = 0;
    else if (meta.labelwrap && /^\d+$/.test(String(meta.labelwrap))) wrapW = +meta.labelwrap;
    function wrapLabel(s, w) {
      if (!w || !s || s.length <= w) return s;
      var words = String(s).split(/\s+/), line = "", out = [];
      for (var i = 0; i < words.length; i++) {
        if ((line + " " + words[i]).trim().length > w) {
          out.push(line.trim()); line = words[i];
        } else { line = (line ? line + " " : "") + words[i]; }
      }
      if (line) out.push(line.trim());
      return out.join("\n");
    }
    var displayItems = items.map(function (it) { return wrapLabel(it, wrapW); });

    // Build the wide row layout.  Order: negs (in reverse so dark-neg
    // sits at the far left), center-half, then pos.  Negatives are
    // sign-flipped so they stack to the left of baseline.
    var negOrder = negs.slice().reverse();
    var dt = new google.visualization.DataTable();
    dt.addColumn("string", meta.namelabel || "Item");
    negOrder.forEach(function (lv) { dt.addColumn("number", String(lv)); });
    if (centerLevel) {
      dt.addColumn("number", String(centerLevel));
    }
    pos.forEach(function (lv) { dt.addColumn("number", String(lv)); });

    items.forEach(function (it, idx) {
      var row = [String(displayItems[idx])];
      negOrder.forEach(function (lv) {
        var v = byItem[it][lv]; row.push(v == null ? 0 : -Math.abs(+v));
      });
      if (centerLevel) {
        var v = byItem[it][centerLevel]; row.push(v == null ? 0 : +v);
      }
      pos.forEach(function (lv) {
        var v = byItem[it][lv]; row.push(v == null ? 0 : +v);
      });
      dt.addRow(row);
    });

    // Compute chartArea.left from the widest wrapped-label line so labels
    // don't truncate.  Approximate width: 6.5 px per character at 11pt.
    var maxLineLen = 0;
    displayItems.forEach(function (s) {
      String(s).split("\n").forEach(function (ln) {
        if (ln.length > maxLineLen) maxLineLen = ln.length;
      });
    });
    var leftPad = Math.min(Math.max(80, Math.ceil(maxLineLen * 6.5) + 20), 380);

    // Build the diverging palette: reds for negatives (darker at extreme),
    // a neutral grey for center, blues for positives.
    var palette = paletteFor(meta);
    function divColors(n, isLeft) {
      // pick n colors from the palette ends
      var bank = isLeft
        ? ["#8c0d25","#cf3535","#ec7c66","#f7c6b1"]
        : ["#bbd8eb","#7eb0d2","#3b86ba","#10487f"];
      var out = [];
      for (var i = 0; i < n; i++) out.push(bank[Math.min(i, bank.length-1)]);
      return out;
    }
    var colors = []
      .concat(divColors(negOrder.length, true))
      .concat(centerLevel ? ["#e2e8f0"] : [])
      .concat(divColors(pos.length, false));

    var opts = deepMerge(brandOptions(meta), {
      title: meta.title || "",
      width: +meta.width || 980, height: +meta.height || 560,
      isStacked: true,
      colors: colors,
      legend: { position: "top" },
      hAxis: {
        title: "",
        baseline: 0,
        // Show absolute values on the axis (so the negative-flipped scale
        // doesn't display negative numbers to the reader).
        format: "#'%'",
        ticks: buildDivbarTicks(items, byItem, negOrder, centerLevel, pos)
      },
      vAxis: { title: "" },
      chartArea: { left: leftPad, top: 50, width: ((+meta.width || 980) - leftPad - 40), height: "75%" },
      bars: "horizontal",
      bar: { groupWidth: "70%" },
      animation: { startup: !!meta.animate, duration: 900, easing: "out" }
    });
    var container = document.getElementById("chart");
    var chart = new google.visualization.BarChart(container);
    return { type: "chart", className: "BarChart", chart: chart, dataTable: dt, opts: opts,
             draw: function () { chart.draw(dt, opts); } };
  }
  function buildDivbarTicks(items, byItem, negOrder, centerLevel, pos) {
    // Compute the symmetric outer bound across items so the axis is
    // centered on the zero line.  Returns explicit ticks with formatted
    // absolute labels.
    var maxAbs = 0;
    items.forEach(function (it) {
      var negSum = negOrder.reduce(function (s, lv) { return s + Math.abs(+(byItem[it][lv] || 0)); }, 0);
      var posSum = pos.reduce(function (s, lv) { return s + Math.abs(+(byItem[it][lv] || 0)); }, 0);
      var ctr   = centerLevel ? Math.abs(+(byItem[it][centerLevel] || 0)) / 2 : 0;
      maxAbs = Math.max(maxAbs, negSum + ctr, posSum + ctr);
    });
    var bound = Math.ceil(maxAbs / 10) * 10 || 10;
    return [
      { v: -bound, f: bound + "%" },
      { v: -bound/2, f: (bound/2) + "%" },
      { v: 0, f: "0%" },
      { v:  bound/2, f: (bound/2) + "%" },
      { v:  bound, f: bound + "%" }
    ];
  }

  // ============================================================
  //                   DASHBOARD + FILTERS
  // ============================================================
  function buildDashboardWithFilters(meta, dt, filterDefs, chartTypeName, opts) {
    var dashRoot = document.getElementById("dashboard");
    if (!dashRoot) {
      // Create one inline if writehtml didn't allocate it.
      dashRoot = document.createElement("div"); dashRoot.id = "dashboard";
      document.getElementById("chart").parentNode.insertBefore(dashRoot, document.getElementById("chart"));
    }
    var dashboard = new google.visualization.Dashboard(dashRoot);

    // Filter container
    var filterHost = document.getElementById("gc-filters");
    if (!filterHost) {
      filterHost = document.createElement("div"); filterHost.id = "gc-filters";
      filterHost.className = "gc-filters";
      var chartEl = document.getElementById("chart");
      chartEl.parentNode.insertBefore(filterHost, chartEl);
    }
    filterHost.innerHTML = "";

    var ctrls = filterDefs.map(function (f, i) {
      var slot = document.createElement("div");
      slot.id = "gc-filter-" + i;
      slot.className = "gc-filter-slot";
      var label = document.createElement("label");
      label.textContent = f.label || f.var;
      label.htmlFor = slot.id;
      filterHost.appendChild(label);
      filterHost.appendChild(slot);
      var controlType = f.numeric ? "NumberRangeFilter" : "CategoryFilter";
      var ui = f.numeric
        ? { labelStacking: "vertical" }
        : { allowMultiple: f.allowMultiple !== false,
            allowTyping: false,
            labelStacking: "vertical",
            caption: "All",
            selectedValuesLayout: "belowStacked" };
      return new google.visualization.ControlWrapper({
        controlType: controlType,
        containerId: slot.id,
        options: {
          filterColumnLabel: f.label || f.var,
          ui: ui
        }
      });
    });

    var chartWrapper = new google.visualization.ChartWrapper({
      chartType: chartTypeName,
      containerId: "chart",
      options: opts
    });
    dashboard.bind(ctrls, chartWrapper);
    return dashboard;
  }

  // ============================================================
  //                   CONTROLS PANEL (sidebar)
  // ============================================================
  function buildControlsPanel(meta, data, tipvars, filterDefs) {
    var root = document.getElementById("controls");
    if (!root) return;
    root.innerHTML = "";
    var dlpos = (meta.downloadpos || "side").toLowerCase();
    var hideExport = (dlpos === "none");
    var exportInFooter = (dlpos === "below");

    // Filters (if any) live in the sidebar -- the engine builds the
    // ControlWrappers in buildDashboardWithFilters().  Here we just
    // reserve the slot.
    if (filterDefs && filterDefs.length) {
      var h3f = document.createElement("h3");
      h3f.textContent = "Filters";
      root.appendChild(h3f);
      var fh = document.createElement("div"); fh.id = "gc-filters"; fh.className = "gc-filters";
      root.appendChild(fh);
    }

    if ((meta.download || meta.datatable) && !hideExport && !exportInFooter) {
      var h3 = document.createElement("h3");
      h3.textContent = "View";
      root.appendChild(h3);
      buildExportMenu(root, meta);
    }
    var meta_div = document.createElement("div");
    meta_div.id = "metabox"; meta_div.className = "meta";
    meta_div.textContent = data.length + " rows";
    root.appendChild(meta_div);

    if (exportInFooter && !hideExport && (meta.download || meta.datatable)) {
      var foot = document.getElementById("chart-footer");
      if (foot) {
        foot.classList.add("active");
        foot.innerHTML = "";
        buildExportMenu(foot, meta);
      }
    }
    // Collapse the sidebar if it's empty after the Export was moved out.
    var nonMeta = 0;
    for (var i = 0; i < root.children.length; i++) {
      if (root.children[i].id !== "metabox") nonMeta++;
    }
    if (nonMeta === 0) {
      root.classList.add("empty");
      var panels = document.querySelector(".panels");
      if (panels) panels.classList.add("no-sidebar");
    }
  }

  // ---- Export menu (the burger button inside the View / footer block) -----
  function buildExportMenu(parent, meta) {
    var wrap = document.createElement("div"); wrap.className = "exportmenu";
    var btn = document.createElement("button"); btn.type = "button"; btn.className = "exportbtn";
    btn.setAttribute("aria-haspopup", "true"); btn.setAttribute("aria-expanded", "false");
    btn.innerHTML = "Export &#9662;";
    var menu = document.createElement("div"); menu.className = "exportlist"; menu.style.display = "none";
    wrap.appendChild(btn); wrap.appendChild(menu); parent.appendChild(wrap);
    function openMenu()  { menu.style.display = "block"; btn.setAttribute("aria-expanded", "true"); }
    function closeMenu() { menu.style.display = "none";  btn.setAttribute("aria-expanded", "false"); }
    btn.addEventListener("click", function (ev) {
      ev.stopPropagation();
      if (menu.style.display === "none") openMenu(); else closeMenu();
    });
    document.addEventListener("click", closeMenu);
    menu.addEventListener("click", function (ev) { ev.stopPropagation(); });
    function addItem(label) {
      var b = document.createElement("button"); b.type = "button"; b.textContent = label;
      menu.appendChild(b); return b;
    }
    if (meta.download) {
      var bPng = addItem("Download PNG"); bPng.dataset.action = "png";
      var bSvg = addItem("Download SVG"); bSvg.dataset.action = "svg";
    }
    if (meta.datatable) {
      var bCsv = addItem("Download CSV"); bCsv.dataset.action = "csv";
      var bView = addItem("View data table"); bView.dataset.action = "viewdata";
    }
    parent.__exportCloseMenu = closeMenu;
  }

  // ---- Wire menu clicks to the live chart instance ------------------------
  function wireExportMenu(meta, ctx, data, tipvars) {
    // Selector covers both the sidebar menu and the under-chart footer menu.
    var menus = document.querySelectorAll(".exportlist");
    menus.forEach(function (menu) {
      menu.addEventListener("click", function (ev) {
        var b = ev.target;
        if (b.tagName !== "BUTTON") return;
        var action = b.dataset.action;
        if (action === "png")      downloadPNG(ctx, meta);
        else if (action === "svg") downloadSVG(meta);
        else if (action === "csv") downloadCSV(ctx);
        else if (action === "viewdata") toggleDataTable(ctx, meta, data, tipvars);
      });
    });
  }

  function triggerDownload(blob, filename) {
    var url = URL.createObjectURL(blob);
    var a = document.createElement("a"); a.href = url; a.download = filename;
    document.body.appendChild(a); a.click(); document.body.removeChild(a);
    setTimeout(function () { URL.revokeObjectURL(url); }, 5000);
  }
  function downloadPNG(ctx, meta) {
    // chart.getImageURI() works on corechart classes and GeoChart.  For
    // chart types where it isn't supported, fall back to SVG serialization.
    var chart = ctx.chart || (ctx.dashboard && ctx.dashboard.getChart && ctx.dashboard.getChart());
    if (!chart || typeof chart.getImageURI !== "function") {
      return downloadSVG(meta);
    }
    var uri = chart.getImageURI();
    fetch(uri).then(function (r) { return r.blob(); }).then(function (blob) {
      triggerDownload(blob, "googlechart_" + (meta.type || "chart") + ".png");
    }).catch(function () {
      // Inline data-URI fallback (older browsers / blob: scheme blocked)
      var a = document.createElement("a");
      a.href = uri;
      a.download = "googlechart_" + (meta.type || "chart") + ".png";
      document.body.appendChild(a); a.click(); document.body.removeChild(a);
    });
  }
  function downloadSVG(meta) {
    var container = document.getElementById("chart");
    var svg = container.getElementsByTagName("svg")[0];
    if (!svg) { alert("This chart type does not render an SVG (try PNG instead)."); return; }
    var clone = svg.cloneNode(true);
    if (!clone.getAttribute("xmlns")) clone.setAttribute("xmlns", "http://www.w3.org/2000/svg");
    clone.setAttribute("width",  svg.getAttribute("width")  || svg.clientWidth);
    clone.setAttribute("height", svg.getAttribute("height") || svg.clientHeight);
    var text = new XMLSerializer().serializeToString(clone);
    var blob = new Blob([text], { type: "image/svg+xml;charset=utf-8" });
    triggerDownload(blob, "googlechart_" + (meta.type || "chart") + ".svg");
  }
  function downloadCSV(ctx) {
    if (!ctx.dataTable) { alert("No data table to export."); return; }
    var csv = google.visualization.dataTableToCsv(ctx.dataTable);
    var blob = new Blob([csv], { type: "text/csv;charset=utf-8" });
    triggerDownload(blob, "googlechart_data.csv");
  }

  // ---- Collapsible data-table panel ---------------------------------------
  function toggleDataTable(ctx, meta, data, tipvars) {
    var host = document.getElementById("datatable");
    if (!host) return;
    if (host.classList.contains("open")) {
      host.classList.remove("open");
      host.style.display = "none";
      host.innerHTML = "";
      return;
    }
    var dt = ctx.dataTable;
    var nCols = dt.getNumberOfColumns();
    var nRows = dt.getNumberOfRows();
    var html = "<div class='dt-header'><strong>Data behind the chart</strong> "
      + "<span class='dt-count'>" + nRows + " rows</span>"
      + "<button type='button' class='dt-close' aria-label='Close'>&times;</button></div>";
    html += "<div class='dt-scroll'><table class='dt-table'><thead><tr>";
    for (var c = 0; c < nCols; c++) html += "<th>" + esc(dt.getColumnLabel(c)) + "</th>";
    html += "</tr></thead><tbody>";
    var MAX = 500;
    for (var r = 0; r < Math.min(nRows, MAX); r++) {
      html += "<tr>";
      for (var c = 0; c < nCols; c++) {
        var v = dt.getFormattedValue(r, c);
        if (v === "" || v == null) v = dt.getValue(r, c);
        html += "<td>" + esc(v == null ? "" : v) + "</td>";
      }
      html += "</tr>";
    }
    html += "</tbody></table></div>";
    if (nRows > MAX) {
      html += "<div class='dt-truncated'>Showing first " + MAX + " of " + nRows
        + " rows -- use <em>Download CSV</em> for the full set.</div>";
    }
    host.innerHTML = html;
    host.classList.add("open");
    host.style.display = "block";
    host.querySelector(".dt-close").addEventListener("click", function () {
      toggleDataTable(ctx, meta, data, tipvars);
    });
  }

  // ---- IntersectionObserver-gated initial draw ----------------------------
  function setupAnimateOnView(meta, ctx) {
    if (typeof IntersectionObserver === "undefined" || !meta.animate) {
      ctx.draw();
      return;
    }
    var target = document.getElementById("chart");
    if (!target) { ctx.draw(); return; }
    // Reserve the slot now so the page layout doesn't jump when the chart
    // finally draws into the empty container.
    target.style.minHeight = (+meta.height || 560) + "px";
    var fired = false;
    function fire() {
      if (fired) return;
      fired = true;
      ctx.draw();
    }

    // When this page is loaded inside an iframe (e.g. via sparkta2_dashboard
    // embedding the chart HTML), the chart container is ALWAYS in the
    // iframe's viewport from the moment the iframe loads -- the local
    // IntersectionObserver would fire immediately and the animation
    // would play before the user has scrolled near it in the parent
    // page.  Observe the iframe element from the PARENT's viewport
    // instead so the animation fires when the reader actually sees it.
    // Only works for same-origin parents (which sparkta2_dashboard is).
    var inIframe = false;
    var frameEl = null;
    var parentWin = null;
    try {
      if (window.frameElement) {  // throws on cross-origin
        frameEl = window.frameElement;
        parentWin = window.parent;
        inIframe = !!(frameEl && parentWin && parentWin.IntersectionObserver);
      }
    } catch (e) { inIframe = false; }

    if (inIframe) {
      // Cross-context IntersectionObserver behaviour is uneven
      // (Chrome devtools-protocol renderers in particular don't fire
      // events on iframe elements observed from inside the frame).
      // Use a poll instead: 4x/sec we ask the parent window where the
      // iframe sits and fire when ~15% of the frame's height is on
      // screen.  Same wall-clock effect as IO, more predictable.
      var pollIv = setInterval(function () {
        if (fired) { clearInterval(pollIv); return; }
        try {
          var prect = frameEl.getBoundingClientRect();
          var pvh = parentWin.innerHeight || parentWin.document.documentElement.clientHeight;
          var visible = Math.min(prect.bottom, pvh) - Math.max(prect.top, 0);
          if (visible > prect.height * 0.15) {
            clearInterval(pollIv);
            fire();
          }
        } catch (e) {
          // Cross-origin or other access failure -- fall back to local
          clearInterval(pollIv);
          fire();
        }
      }, 250);
      // Final safety net: 30 s out, fire regardless so nothing sits idle.
      setTimeout(function () { if (!fired) { clearInterval(pollIv); fire(); } }, 30000);
      return;
    }

    // Standalone (non-iframed) page: observe in the local document.  If
    // the chart is already in viewport at setup time, fire immediately.
    var rect = target.getBoundingClientRect();
    var viewH = window.innerHeight || document.documentElement.clientHeight;
    if (rect.top < viewH && rect.bottom > 0) {
      fire();
      return;
    }
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (e.isIntersecting && !fired) { io.disconnect(); fire(); }
      });
    }, { threshold: 0.2 });
    io.observe(target);
    setTimeout(function () { if (!fired) { try { io.disconnect(); } catch(e){} fire(); } }, 1500);
  }

  // ---- Entry point --------------------------------------------------------
  function render(cfg) { bootstrap(cfg); }
  window.googlechartRender = render;
})();
