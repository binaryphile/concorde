Message For You, Sir
====================

Bash scripting in my own particular...\[sigh\]...

Concorde: "Idiom, sir?"

Idiom!

Concorde is a small-ish library which distills some of the most useful
things I've done in bash.

Goals
=====

-   encourage development of reusable scripts and libraries

-   encourage testable code

-   encourage use of functions

-   encourage use of local variables and reduce dependence on globals;
    generally reduce namespace clutter

-   make arrays and hashes (associative arrays) friendlier

-   make debugging easier

-   make option parsing standard

-   reduce visual noise (quotes, braces, dollar-signs)

-   encourage patterns with some of the advantages of object-orientation

With this toolset, it is simple to create bash scripts which:

-   are more readable

-   can be developed in a test-driven manner

-   are able to receive and parse GNU-style options

-   automatically stop on unexpected errors and produce tracebacks

-   are easily refactorable into shared libraries of functions

Features
========

-   a GNU-style option parser

-   strict mode

-   ruby-style tracebacks

-   ruby-style require/load

-   namespace manipulation functions

-   string, array and hash utility functions

Prerequisites
=============

-   GNU readlink in your PATH, as `readlink`

-   `sed` in your PATH

Installation
============

Clone this repo or copy `lib/concorde.bash`. Make the location of
`concorde.bash` (e.g. `~/concorde/lib`) available in your PATH. Then use
`source concorde.bash` in your scripts.

Reserved Variables
==================

Concorde reserves the following global variables for its own use:

-   `__` - double-underscore, used for returning strings from functions

-   `__featureh` - a hash for feature (i.e. library) meta-data

-   `__instanceh` - a hash for holding object-like data structures

-   `__load` - a flag to indicate reloading of an already loaded feature

Tutorial
========

Let's start with a simple script, developed in a test-driven fashion.

I use \[shpec\] and \[entr\] to run my tests. If you want to follow
along, install those first.

The script and shpec file start in the same directory.  In one window I
fire up vim on `myscript_shpec.bash` and start with:

    source myscript

    describe hello_world
      it "outputs 'Hello, world!'"
        result=$(hello_world)
        assert equal "Hello, world!" "$result"
      end
    end

Don't worry about the shpec syntax for a moment.  It's really just
regular bash.  Shpec tries to make itself look like ruby by providing
ruby-like function names as well as encouraging ruby-like indentation.
Bash doesn't care about the indentation and the functions are just
regular bash.

Now I switch to editing `myscript`:

    #!/usr/bin/env bash

Now I save it.

In another window, I run:

    echo myscript | entr bash -c 'shpec myscript_shpec.bash'

This will monitor the `myscript` file and re-run the test suite whenever
it changes.

I save `myscript` again and the test runs and fails. That's a good
thing, since it shows that the test isn't providing a false positive.

Now to add the function:

    #!/usr/bin/env bash

    hello_world () {
      echo "Hello, world!"
    }

I save and now the test suite passes. Our first green!

However, `myscript` isn't all that exciting. In fact, if you make it
executable and run it, it doesn't do anything!

    > chmod +x myscript
    > ./myscript
    >

That's because the `hello_world` function exists, but nothing's calling
it. So I call it:

    #!/usr/bin/env bash

    hello_world () {
      echo "Hello, world!"
    }

    hello_world

Now it runs correctly:

    > ./myscript
    Hello, world!
    >

But something's wrong in the test window. Now the test shows passing,
but it also shows the "Hello, world!" output, which it's not supposed
to.

That's because the test is running the script when it gets to its
`source myscript` line, and that causes all of the actions in the script
to occur. When testing, we just want to test the functions, not run the
script!

So we add:

    #!/usr/bin/env bash

    source concorde.bash

    hello_world () {
      echo "Hello, world!"
    }

    sourced? && return

    hello_world

Now the test runs and passes, but the output doesn't occur.  That's
because `sourced?` detects that the script is being read with bash's
`source` command and not being run from the command line as a script.
(don't mind the question mark)

The `return` stops the sourcing of the file there, so the interpreter
never reaches the line which calls `hello_world`.  Instead, control is
returned to the shpec file.

If being run as a script from the command-line, however, the `sourced?`
call will return false and the script will continue to run past that
line, fulfilling the call to `hello_world`.

The implication for the structure of your scripts is that, for testing
purposes, you want all of the functions to be defined in the front
portion. Before invoking any of them, for example by calling `main`, you
want `return_if_sourced` to intervene so the test framework can
short-circuit that when just testing the functions.

Let's go back to the script. How about some refactoring, now that we've
got a function that we might want to use in other scripts as well?

First, let's create a couple subdirectories; `lib` for a library we'll
be creating and `bin` for our script. Let's also move the shpec file to
a `shpec` directory.

Here's `lib/hello_world.bash`:

    hello_world () {
      echo "Hello, world!"
    }

And here's `bin/myscript`:

    #!/usr/bin/env bash

    source concorde.bash
    source hello_world.bash

    $(return_if_sourced)

    hello_world

We'll stop the entr window with ctrl-c, since the files have moved
anyway. We've also split the source files, so now having two
corresponding shpec files makes sense.

`shpec/hello_world_shpec.bash`:

    source hello_world.bash

    describe hello_world
      it "outputs 'Hello, world!'"
        result=$(hello_world)
        assert equal "Hello, world!" "$result"
      end
    end

This should work even though `hello_world.bash` doesn't use
`return_if_source`, since `hello_world.bash` just defines a function and
never runs it.

`shpec/myscript_shpec.bash`:

    source myscript

Hmm. There's nothing really to test here, is there, since there are no
functions defined by `myscript`. Perhaps we should change that by making
a formal `main` function which is responsible for taking the actions
requested by the user:

    #!/usr/bin/env bash

    source concorde.bash
    source hello_world.bash

    main () {
      hello_world
    }

    $(return_if_sourced)

    main

Now we could test `main` in `myscript_shpec.bash`, but I think we'll
hold off until it does something more than just call `hello_world`,
since we've already got that covered.

In a regular script, you might not choose to use functions at all,
instead just writing a list of commands that need to go together. That's
fine, but concorde won't help with that much. I'd encourage you to start
writing functions in order to make them testable.

So if you want to make use of concorde's features, you'll want to write
functions. They don't require that you change much; just wrap the entire
script in a `main` function, then call `main` in the same manner as we
called `hello_world` above.

Let's run one of the shpecs now. `cd`ing to the `lib` directory, I run:

    > shpec ../shpec/hello_world_shpec.bash

and see that the test runs correctly. Now I `cd` up one level to the
root of my project. Proud of my code but humble enough to know that you
can never do enough testing, I decide to run the test once more for good
measure:

    > shpec shpec/hello_world_shpec.bash
    shpec/hello_world_shpec.bash: line 1: hello_world.bash: No such file or directory

What? It failed? Oh yeah, when `hello_world_shpec.bash` runs `source
hello_world.bash`, bash looks for `hello_world.bash` in the current
directory (and then in the PATH, but `hello_world.bash` isn't there
either), so the current directory determines whether the test is able to
run. Darn it.

I could just change the line to `source lib/hello_world.bash`, but then
the test would only work when I run the command from this directory and
I'd like it to work anywhere.

Let's update `hello_world_shpec.bash`:

    source concorde.bash
    $(require_relative ../lib/hello_world)

    describe hello_world
    [...]

From the project root (just above `bin` et. al.):

    > shpec shpec/hello_world_shpec.bash

Everything's happy again!

`require_relative` is a function which sources another file, but takes
the current directory out of the equation.  It finds the sourced file
relative to the location of your file, not your shell's current
directory.

`require_relative` also doesn't require a file extension when you name
the file, if the file's extension is `.bash` or `.sh`.  Hence the
`../lib/hello_world` above.

Looking back at `bin/myscript`, notice that we are sourcing
`hello_world.bash` there as well, but now we know that that will not
work.

If we want to use `require_relative` to solve the problem, that will
work fine.  However, we could also put our project's `lib` directory in
the PATH.  If we did so, then `source` would work after all.

However, `source` does have a problem 

`require_relative` has a close cousin in the `require` function, which
also sources a file.  `require` is meant as a replacement for most uses
of `source`.

For bare filename arguments, `require` searches for the file in the
PATH.  Unlike `source`, it doesn't check the current directory first.

`require` may also be given an absolute path, in which case it doesn't
search the PATH for the file.

Like `require_relative`, `require` allows you to omit the file
extension.

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
of the array or hash as a string, e.g. "(three item list)" or
"(\[key\]=value \[pairs\]="")", since bash can't pass actual arrays or
hashes. If you already have such a literal stored in a variable, the API
usually allows you to pass the un-expanded variable name (no dollar
sign) instead and the value will be automatically extrapolated.

The usual way to obtain such a literal from an active array or hash is
via `repr` (short for "representation", a la Python):

    repr my_array
    function_requiring_an_array_literal "$__"

Usually the above function would take the reference `__` as a valid
alternative for `$__`.

Option Parsing
--------------

-   **`parse_options`** *`definitions_array`* - creates a new instance
    of an options data structure

*Returns*: a reference to the option data structure

-   **`options_parse`** *`options_ref [options]`* - parses a list of
    options provided as-is from the command-line (i.e. "$@")

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

        get_here_str <<'EOS'
          ( -o --option1            ''      'a flag'  )
          ( '' --option2 argument_name 'an argument'  )
        EOS

        options_new __


