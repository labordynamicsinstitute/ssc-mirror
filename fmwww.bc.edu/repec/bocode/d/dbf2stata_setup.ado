*! dbf2stata_setup 0.1.0 14aug2026
*! Author: William Dormechele
*! Repository: https://github.com/WilliamDormechele/dbf2stata
*! Python package: https://pypi.org/project/dbf2stata/

capture program drop dbf2stata_setup

program define dbf2stata_setup, rclass
    version 16.0

    syntax [, UPGRADE]

    local dbf2stata_setup_upgrade = cond("`upgrade'" == "", "0", "1")
    local dbf2stata_setup_ready "0"
    local dbf2stata_python_version ""
    local dbf2stata_python_executable ""
    local dbf2stata_package_version ""

    capture noisily python: dbf2stata_setup_run()

    if _rc != 0 {
        display as error ""
        display as error "dbf2stata_setup could not run Stata's Python integration."
        display as text ""
        display as text "Run:"
        display as result "    python query"
        display as text ""
        display as text "Stata must have Python 3.10 or newer configured before setup can continue."
        exit _rc
    }

    if "`dbf2stata_setup_ready'" != "1" {
        display as error ""
        display as error "dbf2stata setup did not complete successfully."
        display as text "Review the messages above and type:"
        display as result "    help dbf2stata_setup"
        exit 499
    }

    return scalar ready = 1
    return local python_version `"`dbf2stata_python_version'"'
    return local python_executable `"`dbf2stata_python_executable'"'
    return local package_version `"`dbf2stata_package_version'"'

end


version 16.0

python:

import importlib
import importlib.metadata
import os
import subprocess
import sys

from sfi import Macro, SFIToolkit


_PACKAGE_SPEC = "dbf2stata>=0.1.0,<0.2.0"


def _show_process_text(text):
    """Display subprocess output in Stata without excessive blank lines."""

    if not text:
        return

    for line in text.splitlines():
        line = line.rstrip()

        if line:
            SFIToolkit.displayln(line)


def _installed_version():
    """Return installed package version, or an empty string."""

    try:
        return importlib.metadata.version("dbf2stata")
    except importlib.metadata.PackageNotFoundError:
        return ""


def _can_import_engine():
    """Return True only if the conversion engine imports successfully."""

    try:
        importlib.invalidate_caches()
        from dbf2stata.core import convert_directory  # noqa: F401
        return True
    except Exception:
        return False


def dbf2stata_setup_run():

    upgrade = (
        Macro.getLocal("dbf2stata_setup_upgrade") == "1"
    )

    python_version = sys.version.split()[0]
    python_executable = sys.executable
    package_version = _installed_version()

    Macro.setLocal(
        "dbf2stata_python_version",
        python_version,
    )

    Macro.setLocal(
        "dbf2stata_python_executable",
        python_executable,
    )

    SFIToolkit.displayln("")
    SFIToolkit.displayln("dbf2stata setup")
    SFIToolkit.displayln("----------------")
    SFIToolkit.displayln(
        f"Python version:    {python_version}"
    )
    SFIToolkit.displayln(
        f"Python executable: {python_executable}"
    )
    SFIToolkit.displayln("")

    if sys.version_info < (3, 10):

        SFIToolkit.displayln(
            "ERROR: dbf2stata requires Python 3.10 or newer."
        )

        SFIToolkit.displayln(
            "Configure a supported Python version in Stata and rerun dbf2stata_setup."
        )

        Macro.setLocal(
            "dbf2stata_setup_ready",
            "0",
        )

        return

    if package_version and _can_import_engine() and not upgrade:

        SFIToolkit.displayln(
            f"dbf2stata Python package: {package_version}"
        )

        SFIToolkit.displayln(
            "Status: READY"
        )

        SFIToolkit.displayln("")
        SFIToolkit.displayln(
            "You can now type:"
        )
        SFIToolkit.displayln(
            "    dbf2stata"
        )

        Macro.setLocal(
            "dbf2stata_package_version",
            package_version,
        )

        Macro.setLocal(
            "dbf2stata_setup_ready",
            "1",
        )

        return

    SFIToolkit.displayln(
        "Checking pip..."
    )

    pip_check = subprocess.run(
        [
            sys.executable,
            "-m",
            "pip",
            "--version",
        ],
        capture_output=True,
        text=True,
    )

    if pip_check.returncode != 0:

        SFIToolkit.displayln(
            "ERROR: pip is not available in Stata's Python environment."
        )

        _show_process_text(
            pip_check.stderr
        )

        SFIToolkit.displayln("")
        SFIToolkit.displayln(
            "Run 'python query' in Stata and ensure pip is available for that Python."
        )

        Macro.setLocal(
            "dbf2stata_setup_ready",
            "0",
        )

        return

    SFIToolkit.displayln(
        "pip: OK"
    )

    command = [
        sys.executable,
        "-m",
        "pip",
        "install",
        "--disable-pip-version-check",
        _PACKAGE_SPEC,
    ]

    if upgrade:
        command.insert(
            5,
            "--upgrade",
        )

    if package_version:
        SFIToolkit.displayln(
            f"Installed dbf2stata version: {package_version}"
        )
    else:
        SFIToolkit.displayln(
            "dbf2stata Python package: NOT INSTALLED"
        )

    if upgrade:
        SFIToolkit.displayln(
            "Upgrading the dbf2stata Python package..."
        )
    else:
        SFIToolkit.displayln(
            "Installing the dbf2stata Python package..."
        )

    SFIToolkit.displayln(
        "Source: Python Package Index (PyPI)"
    )

    install_env = os.environ.copy()
    install_env["PIP_DISABLE_PIP_VERSION_CHECK"] = "1"

    completed = subprocess.run(
        command,
        capture_output=True,
        text=True,
        env=install_env,
    )

    if completed.returncode != 0:

        SFIToolkit.displayln("")
        SFIToolkit.displayln(
            "ERROR: pip could not install dbf2stata."
        )

        _show_process_text(
            completed.stdout
        )

        _show_process_text(
            completed.stderr
        )

        SFIToolkit.displayln("")
        SFIToolkit.displayln(
            "No system-wide Python path is hard-coded by dbf2stata."
        )

        SFIToolkit.displayln(
            "The setup command uses the exact Python executable currently used by Stata."
        )

        Macro.setLocal(
            "dbf2stata_setup_ready",
            "0",
        )

        return

    importlib.invalidate_caches()

    package_version = _installed_version()

    if not package_version or not _can_import_engine():

        SFIToolkit.displayln("")
        SFIToolkit.displayln(
            "ERROR: installation finished, but the dbf2stata engine could not be imported."
        )

        Macro.setLocal(
            "dbf2stata_setup_ready",
            "0",
        )

        return

    SFIToolkit.displayln("")
    SFIToolkit.displayln(
        f"dbf2stata Python package: {package_version}"
    )

    SFIToolkit.displayln(
        "Status: READY"
    )

    SFIToolkit.displayln("")
    SFIToolkit.displayln(
        "Setup complete."
    )

    SFIToolkit.displayln(
        "You can now type:"
    )

    SFIToolkit.displayln(
        "    dbf2stata"
    )

    Macro.setLocal(
        "dbf2stata_package_version",
        package_version,
    )

    Macro.setLocal(
        "dbf2stata_setup_ready",
        "1",
    )


end