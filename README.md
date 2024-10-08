[![Mirror workflow](https://github.com/labordynamicsinstitute/ssc-mirror/actions/workflows/mirror.yml/badge.svg)](https://github.com/labordynamicsinstitute/ssc-mirror/actions/workflows/mirror.yml)

# A mirror of the Statistical Software Components archive at BC

This repository contains a sequence of updates from the SSC Archive at BC.

## How the mirror is created

See [mirror.repec.sh](mirror.repec.sh). The process can take up to 60 minutes. The downloaded mirror is in the [releases branch](https://github.com/labordynamicsinstitute/ssc-mirror/tree/releases).

## Date-stamped tags

Tags are created every time the archive is mirrored. See [https://github.com/labordynamicsinstitute/ssc-mirror/tags](https://github.com/labordynamicsinstitute/ssc-mirror/tags).

- The oldest tags are [2017-08-10](https://github.com/labordynamicsinstitute/ssc-mirror/releases/tag/2017-08-10), [2021-04-15](https://github.com/labordynamicsinstitute/ssc-mirror/releases/tag/2021-04-15), and [2021-08-10](https://github.com/labordynamicsinstitute/ssc-mirror/releases/tag/2021-08-10).
- The oldest tag with continuous daily snapshots is [2021-12-23](https://github.com/labordynamicsinstitute/ssc-mirror/releases/tag/2021-12-23)

## Using the mirror

While the `ssc` command in Stata will continue to go to the original location, you can leverage versioned packages from this mirror:

```{stata}
global sscdate "2021-12-21"
global sscmirror "raw.githubusercontent.com/labordynamicsinstitute/ssc-mirror/$sscdate/" 
net install a2reg, from(https://${sscmirror}fmwww.bc.edu/repec/bocode/a)
```

where the date `2021-12-21` corresponds to an existing tag. Also see [`ssc2`](https://github.com/labordynamicsinstitute/stata-ssc2/) for more streamlined functionality:

```
* ssc2 may be installed directly from GitHub
net install ssc2, all replace from("https://raw.githubusercontent.com/labordynamicsinstitute/stata-ssc2/master")
```

## How to clone this repository

This repository can get big (over 20,000 objects, approx. 320 MB for a shallow clone). You are encouraged, if cloning to your local workspace, to do a "shallow" clone:

    git clone --depth 1 https://github.com/labordynamicsinstitute/ssc-mirror.git

## Contributing

Fork, and create a pull request.

## License

The code that creates this repository is under a BSD-3 license. All other code (the mirror) is under whatever license the original authors granted.

