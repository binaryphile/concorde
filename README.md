Message For You, Sir [![Build Status](https://travis-ci.org/binaryphile/concorde.svg?branch=master)](https://travis-ci.org/binaryphile/concorde)
====================

Bash scripting in my own particular...\[sigh\]...

Concorde: "Idiom, sir?"

Idiom!

Concorde is a distillation of techniques I've picked up from
[StackOverflow], the [Bash Hacker's Wiki] and to a lesser extent
[GreyCat's Wiki], as well as my own personal stylings with bash.

Goals
=====

The overall goal of concorde is to include all of the must-have features
necessary to both create command-line executable scripts as well as
reusable library scripts.

That includes making it easy to:

-   parse command-line options

-   load a library from the PATH or from a path relative to the current
    file

-   do [test-driven development]

-   pass arrays and hashes (a.k.a. associative arrays) to functions
    without using global variables or [namerefs]

-   import specific functions from a library rather than requiring all
    functions in the file

-   store and access related variables outside of the global namespace

-   use the safest options for common system commands such as `rm` by
    default

-   reduce visual clutter from special characters such as quotes and
    dollar signs where possible

In support of these goals, concorde attempts to address some of my
perceived shortcomings of bash, namely:

-   [variable scoping] and reliance on globals

-   singular function namespace

-   directory-location dependent behavior of the `source` command

-   lack of protection from sourcing files with circular dependencies

-   all-or-nothing loading of library functions

-   lack of testing facilities

-   default behavior of not stopping on errors

-   no tracebacks on errors

Prerequisites
=============

-   Bash 4.3 or 4.4 - concorde is tested against:

    -   4.3.11

    -   4.3.33

    -   4.3.42

    -   4.4.12

-   GNU `readlink` in your PATH - for Mac users, `greadlink` is also
    acceptable

-   `sed` in your PATH

Installation
============

Clone this repo or copy `lib/concorde.bash`. Make the location of
`concorde.bash` (e.g. `~/concorde/lib`) available in your PATH. Then use
`source concorde.bash` in your scripts.

Reserved Variables
==================

Concorde reserves the following global variables for its own use:

-   `__` - double-underscore, used for returning values from functions

-   `__ns` - for storing namespaced data

Sample Script Template
======================

See the [tutorial] for a walkthrough on the thought process behind this
example:

``` bash
#!/usr/bin/env bash

source concorde.bash

get <<'EOS'
  Detailed usage message goes here
EOS
printf -v usage '\n%s\n' "$__"

script_main () {
  $(grab 'opt1 opt2_flag' from "$1"); shift

  do_something_with_option "$opt1"

  (( opt2_flag )) && do_something_with_flag

  # consume positional arguments
  while (( $# )); do
    do_something_with_arg "$1"
    shift
  done
}

other_functions () {
  ...
}

sourced && return   # stop here if testing with shpec
strict_mode on      # stop on errors and issue traceback

# option fields:
#
# short     long      var name   help
# -----   ------      --------   ------------------
get <<'EOS'
  -o      --opt1      opt1       "a named argument"
  ''      --opt2      ''         "a long flag"
EOS

$(parse_options __ "$@") || die "$usage" 0
script_main     __ "$@"
```

A few points for understanding the template:

-   any `source` or `require` statements come right after the shebang
    line

-   the first part of the script only defines functions, up until
    `sourced && return`; this is so the test framework can test those
    functions

-   the second part tests whether the script is being run or is being
    sourced and does three things if it is being run:

    -   turn on strict mode

    -   define and parse options

    -   call the main function of the script with an options hash and
        the remaining positional arguments

-   `get` and `parse_options` place their output in the global variable
    "$__", which is fed to `script_main`

-   `parse_options` also removes the parsed options from the rest of the
    script's positional arguments, so the "$@" in `script_main __ "$@"`
    only contains the remaining unparsed positional arguments

-   the first thing `script_main` does is use `grab` to create local
    variables of the keys "opt1" (a named argument) and "opt2\_flag" (a
    flag) from the hash passed in the first argument

-   "opt1" is a named argument holding a value from the user's
    invocation

-   "opt2\_flag" is a flag from the "opt2" definition, which
    automatically has "\_flag" appended to its name by `parse_options`

-   if "opt2\_flag" is *true*, then `(( opt2_flag ))` evaluates as true;
    this is the standard way to test a flag

-   `(( $# ))` is true so long as the number of positional arguments is
    greater than 0 - `shift` removes the first positional argument, so
    the loop will eventually end

Features
========

Option Parser
-------------

A basic parser, aimed at the features of [enhanced getopt].

Example:

``` bash
source concorde.bash

# short   long    argument  help
# -----   ----    --------  ----
get <<'EOS'
  -o      --opt1  ''        "a flag"
  -p      --opt2  value     "an option argument"
EOS

$(parse_options __ "$@") || die "$usage" 0
```

Features:

-   single-dash short options - e.g. `-o`

-   double-dash long options - e.g. `--option`

-   boolean flag options - e.g. `-f` or `--flag` - results in *true* or
    unset

-   named arguments (a.k.a. option arguments) - e.g. `-a <value>` or
    `--argument <value>` - result stored in variable named for option

-   multiple short flags condensed to a single dash - e.g. for `-a`,
    `-b` and `-c`: `-abc`

-   named argument allowed at the end of condensed options - e.g. for
    named argument `-d <value>`: `-abcd "d's value"`

-   long named arguments with or without equals sign - e.g.
    `--option <value>` or `--option=<value>`

-   automatic removal of options and values processed by the parser from
    the calling script's own positional arguments (`$1`, etc.), leaving
    just the actual positional arguments from the user

Variables which store boolean flags always hold *true* when the flag is
provided on the command-line.

`parse_options` notably **doesn't** provide:

-   the ability to specify a flag that sets a value of *false*

-   concatenation of an option argument to its short option - e.g.
    `-o<value>` is not allowed, a space is required as in:

        -o <value>

-   an automatic `--no-<flag>` form of long flag negation

-   automatic shortening of long option names to minimal unambiguous
    prefixes

-   built-in `--help` or `--version` implementations

[Strict Mode] With Tracebacks
-----------------------------

Typically enabled when your script is a command rather than a library.

``` bash
sourced && return
strict_mode on
script_main "$@"
```

-   can be turned on and off

-   stops on most errors - uses options:

    -   [nounset] - no unset variables

    -   [errexit][nounset] - exit on (most) errors

    -   [pipefail][nounset] - return any error encountered in a pipeline
        as the pipeline's return value

-   stops when encountering an unset variable

-   issues ruby-style tracebacks of the call stack, including file and
    line numbers, as well as the offending line of code such as:

``` bash
Traceback:  my_intentionally_erroring_function "$my_argument"
  bin/myscript:193:in erroring_function_caller
  bin/myscript:1:in main
```

Strict mode *does* require more careful coding style to avoid
unintentional errors, so it is suggested that you have practice with it
before enabling it on legacy code.

I will add some recommended coding hygeine when working with strict
mode, but until then, you can learn more [here] and at [Aaron Maxwell's
page][Strict Mode].

Ruby-style "Features" a.k.a. Libraries
--------------------------------------

At the beginning of each library, for example `my_lib.bash`:

``` bash
source concorde.bash
$(feature my_lib)
```

Libraries are written so that they are not loaded more than once, even
if sourced multiple times.  Protects from circular dependencies as well.

-   `bring` - python-style import of only specified functions from a
    library to keep function namespace uncluttered

-   `feature` - protect a library file from being loaded multiple times
    and register its metadata, such as its location on the filesystem

-   `load` - source a filename even if it has been loaded already -
    searches PATH but not current directory

-   `require` - like `source` but only searches PATH, not current
    directory - does not require file extension, searches for `.bash`,
    `.sh` and no extension, in that order

-   `require_relative` - source a file relative to the location of the
    sourcing file - does not require file extension

Hash Operations
---------------

Most functions operate on hash literals rather actual hashes, with the
exception of `with`.  Literals are the same syntax used inside the
parentheses of [compound array assignment], which is the syntax used to
initialize entire hashes at once.

-   `grab` - create local variables from key/values in a hash or a
    namespace

-   `local_hsh` - create a local hash from a hash literal or variable
    reference

-   `stuff` - add key/values to a hash or a namespace using local
    variables

-   `update` - update a hash with the contents of another hash

-   `with` - expand all hash keys into local variables - operates on
    true hashes rather than literals

Array Operations
----------------

-   `assign` - multiple assignment of array values to local variables

-   `local_ary` - create a local array from an array literal or variable
    reference

-   `wed` - join array elements into a string with the specified
    delimiter

String Operations
-----------------

-   `get` - get a string from stdin (usually a heredoc) and strip
    leading whitespace indentation

-   `get_raw` - get a raw (un-de-indented) string from stdin

-   `part` - split a string into an array with the specified delimiter

-   `repr` - return string literal representation of hash or array

Contextual Operations
---------------------

-   `instantiate` - evaluate a string containing unevaluated variable
    references in order to interpolate them

-   `is_set` - determine whether the named variable is set or not

-   `sourced` - determine whether the current file is being sourced or
    not

Input/Output
------------

-   `die` - output message on stderr and exit

-   `put` - replacement for `echo` which uses printf, behaves like ruby
    `puts` - see [this explanation] for why you might want to use it

-   `puterr` - output message on stderr

-   `raise` - output message on stderr and return

Rules and Techniques for Using Concorde
=======================================

1.  **test**

    Write tests for bash functions. Employ [red-green-refactor]. Keep
    functions focused on a single task.

2.  **minimize [side-effects]**

    Side-effects are changes to variables outside of scope or other
    observable interactions with calling functions, other than returning
    a value.

    This means a lot of things, but for functions, it specifically means
    that they are self-contained to as great an extent as possible:

    -   all variables are declared local

    -   global variables are, for the most part, not employed or
        modified ("\_\_" being one notable exception)

    -   arguments should be values - variable references may be passed
        for arrays and hashes but are simply expanded and not used to
        return values

3.  **arrays and hashes are passed and returned as string
    representations**

    Bash is much better at working with strings as arguments than with
    other data structures. The rules explained so far mean that you
    really have to use strings for arrays and hashes, since you want to
    pass them rather than rely on globals, and they can only be passed
    as strings.

    While this sounds like extra work, it actually ends up being
    convenient when coupled with the other functions in concorde. You
    don't often need to work with native hashes when you can extract
    keys directly into your namespace, and multiple assignment makes
    array items available as locals as well. And the rest of concorde's
    functions expect arrays as strings in the first place, so once
    converted, the arrays rarely need to be converted back to native
    form.

    The format of the string representations is simply the text format
    used in [compound array assignments], without parentheses on the
    outside. Array items are separated by spaces. Quotes are used to put
    spaces into values:

        "zero \"item one\" 'item two'"

    I call these array and hash literals, even though bash does not
    define them as such and they are only interpreted into arrays by the
    `local_hsh` and `local_ary` functions.

    In many places, this documentation refers to "passing an array" or a
    hash. This is simply shorthand for "passing an array literal".

    For hashes, the format always includes indices (minus brackets),
    which looks like:

        "zero=0 one=1 two='et cetera'"

    Notice that quotes are still needed around it as a whole, since it
    is a string.

4.  **arrays and hashes may be passed by variable name as well**

    Functions which expect an array or hash literal can use the
    functions `local_ary` or `local_hsh`, which create a local
    array/hash from the literal.

    Because array/hash literal strings are unambiguously distinct from
    variable names (which are restricted to single-word
    underscore/alphanumerics), those functions can tell the difference
    and will automatically dereference a variable name.

    The reason for this is that it results in fewer quotes and dollar
    signs, which makes things more readable.

5.  **string return values, as opposed to return codes, are put in the
    global variable "\_\_" (double-underscore)**

    Rather than relying on [command substitution] to save returned
    strings in a variable, concorde prefers to store them in a global
    variable. This has a couple benefits:

    -   no subshell is required, improving performance

    -   unintentional output is rarely captured (a hazard with command
        substitution)

    -   intermediate values in a chain of string operations don't
        usually require a temporary or accumulator variable to be
        declared, since they are already stored in "\_\_"

    There are a couple downsides as well, however:

    -   "\_\_", much like "$?", can't be relied on to stay the same from
        function call to function call, so any value that needs to be
        saved must *immediately* be assigned - e.g. `myvalue=$__`

    -   therefore most assignments which were one line when using
        command substitution now require two lines, one for the call and
        one for the assignment

    -   functions following this rule can't be used in pipelines, since
        pipelines automatically run them in a subshell and the global
        context is thrown away when the function ends

    -   the code looks strange if you aren't used to the concept

6.  **functions use positional parameters for required arguments and a
    keyword hash for optional arguments**

    Optional arguments are ones that have defaults. An example:

          my_function () {
            local mandatory=$1; shift
            local optional="default value"
            $(grab optional from "$@")
            [...]
          }

          my_function "required string" optional="optional value"

    When using "$@" with `grab` like that, all of the "$@" arguments
    must be in keyword format (var=value).

Examples
========

Testing
-------

I use [shpec] and [entr] for testing.  See the [tutorial] and the
`all-shpecs` file for details.

Testing works equally well for commands as it does for libraries.
Since libraries typically only consist of functions, nothing special
needs to be done when writing them.

Commands, however, should be structured with all function definitions
first, then a line stopping execution if the file is being source rather
than run.  Finally, the invocation of the main function can occur, such
as the following:

```
my_function () {
  ...
}

sourced && return
script_main
```

In the test file which loads the command or library, you typically set
the `nounset` option and `require_relative` the file you are testing:

```
set -o nounset

source concorde.bash
$(require_relative ../myfile)

describe mytest
  it "..."
    <test my_function>
  end
end
```

If you are making directories and files in your tests with `mktemp`, you
may want to set TMPDIR as well:

```
export TMPDIR=$HOME/tmp
mkdir -p "$TMPDIR"

set -o nounset
...
```

Writing a Library (Feature)
---------------------------

Concorde borrows the concept of a "feature" from ruby.  A library is
declared a feature by calling concorde's `feature` function.  The
feature typically has the same name as its filename.  However, the
filename may include an extension, such as `.sh` or `.bash`.  When the
feature is loaded with `require` or `require_relative`, the extension is
not required when naming the feature to load.

Feature names must not include spaces, but may include underscores.

Simply add the following to the beginning of the feature file:

```
source concorde.bash
$(feature my_feature)
```

This will:

-   prevent the feature from being loaded again if sourced or required
    again

-   register a concorde namespace for the feature

-   add the root location of the feature's project directory to the
    metadata in the namespace


### Feature Root

The root location of the project's directory defaults to one directory
above the feature file itself (for example, when the file is located in
the `lib` subdirectory).  If the file depth is different, you can
specify it thusly:

```
$(feature my_feature depth=0)
```

0 would be if the file is in the root directory of the project.  If
deeper, use the number of directories down instead.

To use the feature's root location (for example, to add it to the PATH),
load it from the namespace like so:

```
$(grab root fromns my_feature)
PATH+=:$root/bin:$root/lib
```

Working With a Hash
-------------------

### Pass a Hash to a Function

```
my_function () {
  $(local_hsh received_hash=$1)
  echo "${received_hash[zero]}"
}

declare -A my_hash=( [zero]=0 )
repr my_hash
my_function __
```

Functions such as `my_function` use the `local_hsh` function to turn a
received hash literal into an actual hash.

In order pass the hash literal to the function, the `repr` function
takes the name of an actual hash and returns the literal in the global
`__` variable.  The `local_hsh` function on the receiving side can take
either the literal string itself, in which case you could call
`my_function "$__"`. Alternatively, it can dereference the variable name
itself (`__` in this case), which give the call above as `my_function
__`.

`local_hsh` is specifically written so that quotes are not required
around the parameter on the right-hand side of the assignment, so
`received_hash=$1` does not have them around `$1` above.

API
===

Internal-use functions, of which there are but a couple, start with an
underscore. The rest form the public API.

Names which appear to be a little esoteric were typically chosen that
way in order to avoid conflicts with similarly-named programs that you
might find on a system. For example, `wed` instead of the more standard
`join` for arrays.

Some functions incorporate data types in their names when they deal with
such types, such as:

-   `ary`: arrays
-   `str`: strings
-   `hsh`: hashes (associative arrays)

Functions which return string values (which are almost all of them) do
so in the global variable `__` (double-underscore). This is very
important to understand since it is used everywhere. Additionally, this
means that, like `$?`, you can't rely on its value remaining the same
after you call another function. Hence you need to save `__` off to
another variable if you intend to make more use of its value.

A reference is simply a string variable which happens to hold either the
name of another string variable or the name and index of an item in an
array or hash (e.g. `my_hash[key]`). Only references to the variable
`__instanceh` or the names of array or hash variables may be passed to
functions written in concorde's idiom. Other uses of references may
result in namespace clashes.

All parameters designated as "\_array" or "\_hash" in function
signatures described below actually require the literal representation
of the array or hash as a string, e.g. "three item list" or
'\[key\]=value \[pairs\]=""', since bash can't pass actual arrays or
hashes. If you already have such a literal stored in a variable, the API
usually allows you to pass the un-expanded variable name (no dollar
sign) instead and the value will be automatically extrapolated.

The usual way to obtain such a literal from an active array or hash is
via `repr` (short for "representation", a la Python):

``` bash
repr my_array
function_requiring_an_array_literal "$__"
```

Usually the above function would take the reference `__` as a valid
alternative for `$__`.

Option Parsing
--------------

-   **`parse_options`** *`definitions_array`* - creates a new instance
    of an options data structure

    Options definitions are in the form of an array literal, with each
    item containing a sub-array (literal) of four elements:

    -   *short option* (including hyphen) - may be omitted (with `''` in
        its place) if *long option* is defined

    -   *long option* (including double-hyphen) - may be omitted (with
        `''` in its place) if *short option* is defined

    -   *argument name* - if the option takes an argument, the name of
        the variable in which to store the value.

    -   if omitted with '' in its place, the option becomes a flag with
        the name `flag_[option]`, where \[option\] is the long name, if
        available, otherwise the short name. It receives either the
        value 1 if the flag is supplied, or does not exist if it wasn't

    -   *help string* - currently unused but can still be a useful
        reminder

    *definitions\_array* is usually supplied via `get_here_str`.
    Example:

``` bash
get <<'EOS'
  -o --option1            ''      'a flag'
  '' --option2 argument_name 'an argument'
EOS

$(parse_options __ "$@") || die "$usage" 0
```

  [shpec]: https://github.com/rylnd/shpec/tree/0.2.2
  [entr]: http://entrproject.org/
  [nounset]: http://wiki.bash-hackers.org/commands/builtin/set
  [variable scoping]: http://wiki.bash-hackers.org/scripting/basics#variable_scope
  [namerefs]: http://wiki.bash-hackers.org/commands/builtin/declare#nameref
  [compound array assignment]: http://wiki.bash-hackers.org/syntax/arrays#storing_values
  [StackOverflow]: https://stackoverflow.com/
  [Bash Hacker's Wiki]: http://wiki.bash-hackers.org/
  [GreyCat's Wiki]: http://mywiki.wooledge.org/
  [test-driven development]: https://www.agilealliance.org/glossary/tdd
  [enhanced getopt]: https://linux.die.net/man/1/getopt
  [Strict Mode]: http://redsymbol.net/articles/unofficial-bash-strict-mode/
  [here]: http://fvue.nl/wiki/Bash:_Error_handling
  [this explanation]: https://unix.stackexchange.com/questions/65803/why-is-printf-better-than-echo
  [tutorial]: share/doc/tutorial.md
  [red-green-refactor]: http://www.jamesshore.com/Blog/Red-Green-Refactor.html
  [side-effects]: https://en.wikipedia.org/wiki/Side_effect_%28computer_science%29
  [command substitution]: http://wiki.bash-hackers.org/syntax/expansion/cmdsubst
