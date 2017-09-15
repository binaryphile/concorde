Change Log
==========

The format is based on [Keep a Changelog] and this project adheres to
[Semantic Versioning].

Latest Changes
==============

[v0.2.1] - 2017-09-15
---------------------

### Fixed

-   `strict_mode` was still calling deprecated `get_str`, changed to
    `get`

### Removed

-   `in_scope`, `get_ary`

[v0.2.0] - 2017-09-14
---------------------

### Changed

-   removed parentheses from array and hash literal formats

-   `get_here_str` renamed to `get`

-   `get_str` renamed to `get_raw`

-   all functions refactored to use `get` and new literal format

### Removed

-   `get_here_ary` removed

[v0.1.0] - 2017-08-23
---------------------

### Changed

-   features and macros merged into namespaces

-   namespaces are literal instead of hash at top level

-   `bring` no longer requires emission

### Removed

-   `from_feature` from `grab`

### Added

-   namespace operations for stuff and grab

### Fixed

-   `bring` erroneously escaped characters

### Refactored

-   migrated features to use namespaces

-   private functions are prefixed with double-underscore rather than
    single-

Older Changes
=============

[v0.0.5] - 2017-08-13
---------------------

### Changed

-   `die` exits with the last return code by default instead of 1

-   renamed global hashes to be simpler since user-visible and could be
    used much

-   `local_hsh` accepts blank as empty literal `()`

### Removed

-   succinct hash literals

### Added

-   keyword arguments in place of succinct hash literals

-   `escape_items` to escape strings

-   `raise` - like `die` but `return` instead of `exit`

-   macros for commands in `__macros`

-   `greadlink` compatibility for macs

-   `is_literal`, `is_feature` functions

### Refactored

-   use `escape_items` instead of `printf` where appropriate

### Documented

-   tutorial is its own document

-   readme updated with better description of features, sample template
    script

[v0.0.4] - 2017-08-01
---------------------

### Added

-   succinct hash literals for `local_hsh` et. al.

-   `grab` has `from_feature` argument

### Refactored

-   "\_\_feature\_hsh" implementation

-   use `local_ary` and `local_hsh` where appropriate

### Documented

-   readme tutorial

[v0.0.3] - 2017-07-25
---------------------

### Fixed

-   `feature` syntax error

[v0.0.2] - 2017-07-25
---------------------

### Changed

-   changed `return_if_sourced` to `sourced`

-   changed `library` to `feature`

-   removed nonsensical `local_str`

-   removed search of current directory from `require`

-   removed "\_\_load" variable used by `feature` in favor of "reload"
    argument

### Added

-   `load` function - uses new "reload" argument to `require` instead of
    "\_\_load" variable

### Fixed

-   `local_ary` and `local_hsh` were broken

-   `require_relative` didn't work for second caller - only used caller
    dir from first caller

### Documented

-   readme tutorial (work-in-progress)

### Refactored

-   coding style for array vs array literal naming - \_ary for arrays,
    plural for literals, similar for hashes

-   switched to using `local_ary` and `local_hsh` where appropriate

-   implementation of `return_if_sourced`, now `sourced`

[v0.0.1] - 2017-07-19
---------------------

### Changed

-   refactored option parsing

[v0.0.0] - 2017-07-18
---------------------

### Added

-   tons of stuff

  [Keep a Changelog]: http://keepachangelog.com/
  [Semantic Versioning]: http://semver.org/
  [v0.2.1]: https://github.com/binaryphile/concorde/compare/v0.2.0...v0.2.1
  [v0.2.0]: https://github.com/binaryphile/concorde/compare/v0.1.0...v0.2.0
  [v0.1.0]: https://github.com/binaryphile/concorde/compare/v0.0.5...v0.1.0
  [v0.0.5]: https://github.com/binaryphile/concorde/compare/v0.0.4...v0.0.5
  [v0.0.4]: https://github.com/binaryphile/concorde/compare/v0.0.3...v0.0.4
  [v0.0.3]: https://github.com/binaryphile/concorde/compare/v0.0.2...v0.0.3
  [v0.0.2]: https://github.com/binaryphile/concorde/compare/v0.0.1...v0.0.2
  [v0.0.1]: https://github.com/binaryphile/concorde/compare/v0.0.0...v0.0.1
  [v0.0.0]: https://github.com/binaryphile/concorde/tree/v0.0.0
