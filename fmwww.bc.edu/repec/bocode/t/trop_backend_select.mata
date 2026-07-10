/*──────────────────────────────────────────────────────────────────────────────
  trop_backend_select.mata

  Native-plugin availability checks and diagnostic output.

  All numerical computation (distance matrices, weight construction, LOOCV
  grid search, estimation, and bootstrap) is delegated to a compiled plugin.
  This module verifies that the plugin is loadable before estimation begins
  and provides a diagnostic display of the runtime environment.

  Contents
    select_backend()       check plugin availability (soft)
    check_backend()        assert plugin availability (hard)
    print_backend_info()   display OS, architecture, and plugin status
──────────────────────────────────────────────────────────────────────────────*/

version 17
mata:
mata set matastrict on

/*──────────────────────────────────────────────────────────────────────────────
  select_backend()

  Tests whether the native plugin can be loaded.

  Returns
    real scalar   1 if the plugin is available, 0 otherwise
──────────────────────────────────────────────────────────────────────────────*/
real scalar select_backend()
{
    if (trop_rust_available()) {
        return(1)
    }

    errprintf("TROP plugin not found. Please reinstall the package.\n")
    return(0)
}

/*──────────────────────────────────────────────────────────────────────────────
  check_backend()

  Asserts that the native plugin is available.  Exits with error 198
  (invalid syntax / specification) if the plugin cannot be loaded.
──────────────────────────────────────────────────────────────────────────────*/
void check_backend()
{
    if (!trop_rust_available()) {
        errprintf("TROP plugin not found. Please reinstall the package.\n")
        exit(198)
    }
}

/*──────────────────────────────────────────────────────────────────────────────
  print_backend_info([verbose])

  Displays the operating system, architecture, plugin file name, and
  availability status.

  Arguments
    verbose   real scalar  -- 1 = print (default), 0 = suppress output
──────────────────────────────────────────────────────────────────────────────*/
void print_backend_info(| real scalar verbose)
{
    string scalar plugin_name, os, machine

    if (args() < 1) verbose = 1

    if (verbose == 0) return

    plugin_name = _trop_get_plugin_name()
    os = c("os")
    machine = c("machine_type")

    printf("{txt}========== TROP Backend Info ==========\n")
    printf("{txt}  OS:      %s\n", os)
    printf("{txt}  Arch:    %s\n", machine)
    printf("{txt}  Plugin:  %s\n", plugin_name)
    if (trop_rust_available()) printf("{txt}  Status:  available\n")
    else printf("{txt}  Status:  unavailable\n")
    printf("{txt}=======================================\n")
}

end
