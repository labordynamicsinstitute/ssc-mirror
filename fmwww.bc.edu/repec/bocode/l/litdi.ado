*! litdi 1.0  17may2026
*! Convenience alias for litdiscover. Forwards every argument to
*! litdiscover and propagates returned scalars and macros back to the
*! caller. See `help litdiscover' for full documentation.

capture program drop litdi

program define litdi, rclass
    version 19

    litdiscover `0'
    return add
end
