# A mirror of the Statistical Software Components archive at BC

This repository contains a sequence of updates from the SSC Archive at BC.

## How the mirror is created

See [mirror.repec.sh](mirror.repec.sh)

## Date-stamped tags

Tags are created every time the archive is mirrored. See [https://github.com/labordynamicsinstitute/ssc-mirror/tags](https://github.com/labordynamicsinstitute/ssc-mirror/tags).

## Using the mirror

While the `ssc` command in Stata will continue to go to the original location, you can leverage versioned packages from this mirror:

```{stata}
net install a2reg, from(https://raw.githubusercontent.com/labordynamicsinstitute/ssc-mirror/2021-12-21/fmwww.bc.edu/repec/bocode/a)
```

where the date `2021-12-21` corresponds to an existing tag. More streamlined functionality is forthcoming.

## How to clone this repository

This repository can get big (over 20,000 objects, approx. 320 MB for a shallow clone). You are encouraged, if cloning to your local workspace, to do a "shallow" clone:

    git clone --depth 1 https://github.com/labordynamicsinstitute/ssc-mirror.git

## Contributing

Fork, and create a pull request.

## License

The code that creates this repository is under a BSD-3 license. All other code (the mirror) is under whatever license the original authors granted.

