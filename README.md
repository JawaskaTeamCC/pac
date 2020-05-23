# Jawaska team Computercraft programs

Jawaska Team's Computercraft code repository.

Contains programs and libraries.

## Structure

The repository is divided in library folders, containing the version:

Example: `libraries/my-lib/1.0.0`

Inside we should find at least:
+ Library's entry point at `init.lua`
+ A file called `package.info` which contains a key-value file.

Example of `package.info` file:
```properties
name=my-lib
description=A simple library!
author=me
contact=some@contact
site=some.site
version=1.0.0
files=init.lua
deps.other-lib=1.0.0
deps.some-other-lib=1.5.0
```

Implementing package managers should be able to parse this simple key-value
format, which follows the basic shape of a Java's properties file.

All files must be listed as `files=coma,separated,files` in order to implementing
package managers to download.

### Dependency versioning

Implementing package managers should note that dependencies use semantic
versioning. This means that package version should be the latest always inside
the major version.

Normal versions (Eg: `1.0.0`) are looked up in each repository by order.
Repositories in order to be valid **must** have an `index.info` file, that is
a key-value pair file with the names of the packages and their location in the
folder.

Example of `index.info` file:
```properties
my-lib=libraries/my-lib
```

### About the package.info file

Why a custom format? Initially a lua file exposing a table was thought to be
used, but malicious code can be easily injected.

To avoid that, package data is provided in a very simplistic file.
