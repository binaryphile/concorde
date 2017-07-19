Message For You, Sir
====================

Bash scripting in my own particular...[sigh]...

Concorde: "Idiom, sir?"

Idiom!

Concorde is a small-ish library for virtually all of my bash scripting.
It relies heavily on my own particular stylized way of writing bash, so
be prepared for some of my eccentricities.  They all have good reason.

Concorde provides some basic data structure and namespace manipulation
functions, along with tools for making bash into a friendly environment
for writing reusable code (libraries).

Libraries need to be written idiomatically (i.e. my way) in order to
work in this system, but concorde solves most of the issues which
normally prevent bash libraries from working well with each other (a
misfeature of bash which is perhaps why there aren't a lot of canonical
bash libraries?)

Features
========

-   an option parser

-   namespace manipulation using hashes and arrays

-   library packaging functions

-   utilitarian string and array manipulations

-   ruby-style tracebacks

-   strict mode

Prerequisites
=============

GNU readlink in your PATH, as `readlink`.

Installation
============

Clone this repo (or copy concorde.bash) and make it avaiable in your
$PATH.  Then use `source concorde.bash` in your scripts.

Reserved Variables
==================

Concorde reserves the following global variables for its own use:

-   `CONCO_CALR`
-   `CONCO_ROOT`
-   `__` (double-underscore)
-   `__conco`
-   `__dependencies`
-   `__instanceh`

API
===

Internal-use functions, of which there are but a couple, start with an
underscore.  The rest form the public API.

Names which appear to be a little esoteric were typically chosen that
way in order to avoid conflicts with similarly-named programs that you
might find on a system.  For example, `wed` instead of the more standard
`join` for arrays.

Some functions incorporate data types in their names when they deal with
such types, such as:

-   `ary`: arrays
-   `str`: strings
-   `hsh`: hashes (associative arrays)

Functions which return string values (which are almost all of them) do
so in the global variable `__` (double-underscore).  This is very
important to understand since it is used everywhere.  Additionally, this
means that, like `$?`, you can't rely on its value remaining the same
after you call another function.  Hence you need to save `__` off to
another variable if you intend to make more use of its value.

A reference is simply a string variable which happens to hold either the
name of another string variable or the name and index of an item in an
array or hash (e.g.  `my_hash[key]`).  Only references to the variable
`__instanceh` or the names of array or hash variables may be passed to
functions written in concorde's idiom.  Other uses of references may
result in namespace clashes.

All parameters designated as "_array" or "_hash" in function signatures
described below actually require the literal representation of the array
or hash as a string, e.g. "(three item list)" or "([key]=value
[pairs]="")", since bash can't pass actual arrays or hashes.  If you
already have such a literal stored in a variable, the API usually allows
you to pass the un-expanded variable name (no dollar sign) instead and
the value will be automatically extrapolated.

The usual way to obtain such a literal from an active array or hash is
via `repr` (short for "representation", a la Python):

```
repr my_array
function_requiring_an_array_literal "$__"
```

Usually the above function would take the reference `__` as a valid
alternative for `$__`.

Option Parsing
--------------

-   **`options_new`** *`definitions_array`* - creates a new instance of
    an options data structure

    Options definitions are in the form of an array literal, with each
    item containing a sub-array (literal) of four elements:

        -   *short option* (including hyphen) - may be ommitted (with ''
            in its place) if *long option* is defined

        -   *long option* (including double-hyphen) - may be ommitted
            (with '' in its place) if *short option* is defined

        -   *argument name* - if the option takes an argument, the name
            of the variable in which to store the value

            -   if ommitted with '' in its place, the option becomes a
                flag with the name `flag_[option]`, where [option] is
                the long name, if available, otherwise the short name.
                It receives either the value 1 if the flag is supplied,
                or does not exist if it wasn't

        -   *help string* - currently unused but can still be a useful
            reminder

    *definitions_array* is usually supplied via `get_here_str`.  Example:

        get_here_str <<'EOS'
          ( -o --option1            ''      'a flag'  )
          ( '' --option2 argument_name 'an argument'  )
        EOS

        options_new __

*Returns*: a reference to the option data structure

-   **`options_parse`** *`options_ref [options]`* - parses a list of
    options provided as-is from the command-line (i.e. "$@")

    Requires an options data structure reference as the first argument,
    as generated by `options_new`
