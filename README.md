Message For You, Sir
====================

Bash scripting in my own particular...\[sigh\]...

Concorde: "Idiom, sir?"

Idiom!

Concorde is a library which distills some of the most useful things (to
me) I've done in bash.

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

-   can be developed in a [test-driven] manner

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

-   `__feature_hsh` - a hash for feature (i.e. library) meta-data

-   `__instance_hsh` - a hash for holding object-like data structures

Tutorial
========

Let's start with a simple script, developed in a test-driven fashion.

I use [shpec] and [entr] to run my tests. If you want to follow along,
install those first.

Basic Test-Driven Development with Bash
---------------------------------------

The script and shpec file start in the same directory. In one window I
fire up vim on `myscript_shpec.bash` and start with:

``` bash
source myscript

describe hello
  it "outputs 'Hello, world!'"
    result=$(hello)
    assert equal "Hello, world!" "$result"
  end
end
```

Don't worry about the shpec syntax for the moment. It's just regular
bash. Shpec tries to make itself look like ruby by providing ruby-like
function names as well as encouraging ruby-like indentation. However,
bash doesn't care about the indentation.

Now I switch to editing `myscript`:

``` bash
#!/usr/bin/env bash
```

I save it and in another window, I run:

``` bash
> echo myscript | entr bash -c 'shpec myscript_shpec.bash'
```

This will monitor the `myscript` file and re-run the test suite whenever
it changes.

I save `myscript` again and the test runs and fails. That's a good
thing, since it shows that the test isn't providing a false positive.

Now to add the function to `myscript`:

``` bash
#!/usr/bin/env bash

hello () {
  echo "Hello, world!"
}
```

I save and now the test suite passes. Our first green!

Doing More than Just Passing the Test
-------------------------------------

However, `myscript` isn't all that exciting. In fact, if you make it
executable and run it, it doesn't do anything!

``` bash
> chmod +x myscript
> ./myscript
```

That's because the `hello` function exists, but nothing's calling it. So
I call it:

``` bash
#!/usr/bin/env bash

hello () {
  echo "Hello, world!"
}

hello
```

Now it runs correctly:

``` bash
> ./myscript
Hello, world!
```

But something's wrong in the test window. Now the test shows passing,
but it also shows the "Hello, world!" output, which it's not supposed
to.

That's because the test runs the script when it gets to its
`source myscript` line, and that causes *all* of the actions in the
script to occur. When testing, we just want to load the functions, not
run the script!

Treating the Same File as Both Script and Library
-------------------------------------------------

A script runs and accomplishes a task. A library provides functions for
scripts but doesn't usually do anything itself.

Shpec needs to treat the script as a library however. Can we have a
script that acts like a library too? (Spoiler: yes)

I'll add concorde and call one of its functions:

``` bash
#!/usr/bin/env bash

source concorde.bash

hello () {
  echo "Hello, world!"
}

sourced && return

hello
```

Now the test runs and passes, but the output doesn't occur. That's
because `sourced` detects that the script is being read with bash's
`source` command and not being run from the command line as a script.

The `return` stops the sourcing of the file there, so the interpreter
never reaches the line which calls `hello`. Instead, control is returned
to the shpec file.

If the script is being run from the command-line, however, the `sourced`
call will return false and the script will continue to run past that
line, fulfilling the call to `hello`.

The implication for the structure of your scripts is that, for testing
purposes, you want all of the functions to be defined before calling any
of them. Before you do call them, you want to intervene with `sourced`
so the test framework can short-circuit the script's actions.

Introducing Some Structure
--------------------------

Let's go back to the script. How about some refactoring, now that we've
got a function that we may want to use in other scripts as well?

First I'll stop the `entr` window with ctrl-c, since we'll be moving the
files anyway.

Then, I'll create a couple subdirectories; `lib` for a library we'll be
creating and `bin` for our script. I'll also make a `shpec` directory
for shpec files.

``` bash
> mkdir bin lib shpec
```

Here's `lib/hello.bash`:

``` bash
hello () {
  echo "Hello, world!"
}
```

And here's `bin/myscript`:

``` bash
#!/usr/bin/env bash

source concorde.bash
source hello.bash

sourced && return

hello
```

We've split the source files, so now having two corresponding shpec
files makes sense.

`shpec/hello_shpec.bash`:

``` bash
source hello.bash

describe hello
  it "outputs 'Hello, world!'"
    result=$(hello)
    assert equal "Hello, world!" "$result"
  end
end
```

And `shpec/myscript_shpec.bash`:

``` bash
source myscript
```

Hmm. There's nothing really to test for `myscript`, since it defines no
functions. Perhaps we should change that by making a formal "main"
function which is responsible for taking the actions requested by the
user.

Using `mymain`
--------------

Unfortunately, bash has a special purpose for "main" as a context name,
so I'll use "mymain" instead:

``` bash
#!/usr/bin/env bash

source concorde.bash
source hello.bash

mymain () {
  hello
}

sourced && return

mymain "$@"
```

By convention, I'll pass the script's arguments (`"$@"`) to `mymain` for
parsing, even though they aren't currently needed.

Now we could test `mymain` in `myscript_shpec.bash`, but I think we'll
hold off until it does something more than just call `hello`. We've
already got `hello`'s tests covered.

Sourcing Features Correctly
---------------------------

I'm using the word "feature" here as a fancy name for a library, such as
our `hello` library.

First let's run one of the shpecs. I run:

``` bash
> cd lib
> shpec ../shpec/hello_shpec.bash
```

and see that the test runs correctly, as it does. Proud of my code, but
humble enough to know that you can never do enough testing, I decide to
run the test once more for good measure. I'll just change directory
first, that couldn't hurt anything, could it?

``` bash
> cd ..
> shpec shpec/hello_shpec.bash
shpec/hello_shpec.bash: line 1: hello.bash: No such file or directory
```

What? It failed?

Oh yeah...`hello_shpec.bash` contains the line `source hello.bash`. When
bash looks for `hello.bash`, first it searches the PATH (hint: it's not
there) and then the current directory. When I was in the directory with
`hello.bash`, that made it work, but only there. The current directory
determines whether the test is able to run. Darn it.

I could just change the line to `source lib/hello.bash`, but then the
test would only work when I run the command from this directory and I'd
basically have the same problem. I want it to work from anywhere.

I know! Let's update `hello_shpec.bash`:

``` bash
source concorde.bash
$(require_relative ../lib/hello)

describe hello
[...]
```

From the project root, where I just was:

``` bash
> shpec shpec/hello_shpec.bash
```

Everything's happy again!

`require_relative`
------------------

`require_relative` is a function which sources another file, but takes
the current directory out of the equation. It finds the sourced file
relative to the location of your file, not your shell's current
directory.

If the file's extenstion is `.bash` or `.sh`, then `require_relative`
doesn't require the extension be specified. Hence the `../lib/hello`
above. This borrows from ruby, where the library is called a "feature"
and is referred to by its name, without an extension.

I'm sure you've noticed the [command substitution] around the call to
`require_relative`. (the `$()`) That's because `require_relative`
actually generates a `source` statement on stdout which is then executed
by the command substitution, but in the context of the caller.

If the `source` command were run by the `require_relative` function
itself, certain statements (such as `declare` or `return`) would not be
executed properly.

When to Use `require_relative` vs `require`
-------------------------------------------

Looking back at `bin/myscript`, notice that we are sourcing `hello.bash`
there as well, but now we know that that will not work. If I decide to
distribute `hello.bash` with `myscript`, then I'll just use
`require_relative` to load it.

However, if I intend to distribute `hello.bash` separately, I'll install
it on the PATH and just source it. In that case, I could instead use
concorde's `require` instead of `source`. `require` does not require a
file extension, just like `require_relative`.

Otherwise `require` is pretty much the same as `source`, with one major
exception. Unlike both `source` and ruby's `require`, concorde's
`require` doesn't search the local directory. If you need to load a file
from the current directory, you'll need to provide an absolute or
relative path to either `require` or `require_relative`, respectively.

In this case, I'll choose `require_relative` for `myscript`:

``` bash
#!/usr/bin/env bash

source concorde.bash
$(require_relative ../lib/hello)

mymain () {
  hello
}

sourced && return

mymain "$@"
```

`require` and `feature`
-----------------------

`require` and company will source a file without needing the file
extension. In ruby (but not concorde), `require` also makes sure that a
feature loaded this way doesn't get executed more than once, since it
may be `require`d more than once in a given project. If it gets
`require`d again, ruby simply returns instead of loading it again.

Recognizing the fact that users may use `source` instead of concorde's
`require`, concorde provides a different function to ensure that
features aren't reloaded. Adding `feature` to your library will prevent
reloads, whether the library is `source`d or `require`d.

I'll update `hello.bash` as an example:

``` bash
source concorde.bash
$(feature hello)

hello () {
  echo "Hello, world!"
}
```

This is actually already useful for our example, since both `myscript`
and `hello.bash` load concorde. Concorde employs its own feature
protection to make sure it is not loaded multiple times itself.

Hello, name!
------------

Let's get back to coding.

I'm going to add an argument which allows me specify the name I'd like
the script to say hello to.

I fire up entr again:

``` bash
> echo lib/hello.bash | entr bash -c 'shpec shpec/hello_shpec.bash'
```

First I'll allow `hello` to say a name, if provided.

`shpec/hello_shpec.bash`:

``` bash
[...]

describe hello
  [...]

  it "outputs 'Hello, [arg]!' if an argument"
    result=$(hello myname)
    assert equal "Hello, myname!" "$result"
  end
end
```

I save `lib/hello.bash` to trigger shpec, which fails on the second
test. Good.

`lib/hello.bash`:

``` bash
[...]

hello () {
  local name=${1:-world}

  echo "Hello, $name!"
}
```

I save and this time the test passes. Now I'll modify `myscript` to
accept a name.

This time, I'll write tests for `mymain`.

I ctrl-c the entr window. Next I edit the test file. This is pretty much
going to look like the `hello` tests, but I'll be changing it soon.

`shpec/myscript_shpec.bash`:

``` bash
source concorde.bash
$(require_relative ../bin/myscript)

describe mymain
  it "outputs 'Hello, world!'"
    result=$(mymain)
    assert equal "Hello, world!" "$result"
  end

  it "outputs 'Hello, [arg]!' if given an option"
    result=$(mymain myname)
    assert equal "Hello, myname!" "$result"
  end
end
```

I run:

``` bash
> shpec shpec/myscript_shpec.bash
```

and the test fails. Again, good.

Now to update `bin/myscript`:

``` bash
[...]

mymain () {
  hello "$@"
}

[...]
```

`mymain` already receives the arguments from the user, so now it simply
passes them along to `hello`.

I run:

``` bash
> shpec shpec/myscript_shpec.bash
```

and the test passes.

Arguments vs Options and Command-line Parsing
---------------------------------------------

So a user's positional argument to the script works but that isn't
really option parsing. I'd like to use a real command-line option with
dashes.

How about a new option which lets us specify the greeting, something
other than "Hello"? We'll use a short option of `-g` and a long option
of `--greeting`. I'll want the greeting stored in the variable
"greeting" when all is said and done.

I'll be using concorde's option parser, which means I'll need to know a
bit about how it provides options to `mymain`.

First, I'll be calling the parser in the global scope, before I call
`mymain`. I'll provide it with the relevant information about the
options I'm defining. Then I'll also feed it the user's input arguments

The option parser is the function `parse_options`. First it wants an
array of option definitions, where the option definitions themselves are
an array of fields.

The fields are:

-   short option

-   long option

-   name of the user's value (blank if the option is a flag)

-   help

Short or long can be omitted so long as at least one of them is defined.

Help is there to remind us what the option is supposed to be, although
it's not currently used for anything else.

After the definitions, `parse_options` will want the user's actual
arguments.

Array Literals
--------------

If we were just defining a single option as an array, it would look
like:

``` bash
option=( -g --greeting greeting "an alternative greeting to 'Hello'" )
```

However, the option parser needs to take multiple such definitions,
themselves stored in an array. Unfortunately, bash can only store
strings in array elements, not other arrays.

Message for You, Sir
--------------------

Here's where we get to one of those...\[sigh\]

Concorde: Idioms, sir?

Idioms! for which concorde is named.

The rule in concorde is that, when passing array values, they are passed
as strings. This is convenient, since strings are the only thing that
bash can pass.

To do so, I use an array literal. What's an array literal, you ask? If
you've ever initialized an array during an assignment statement, you
already know. It's the syntax which bash allows on the right-hand side
of an array assignment statement to define an array.

Array literal syntax is a string value, starting and ending with
parentheses. Inside are values separated by spaces. For normal arrays,
values can appear with or without indices. If included, indices are
numerals in brackets, followed by an equal sign and the value. The value
appears in single- or double-quotes if it contains whitespace.

For example, the following is a valid literal, even though some values
have an index and others don't:

``` bash
( zero [1]=one [2]="two with spaces" 'three with single-quotes' )
```

The quotes are evaluated out and don't end up as part of the values.

If you assigned the above to the array "my\_array" and printed out the
values, you'd get:

``` bash
> for i in "${!my_array[@]}"; do echo "$i: ${my_array[i]}"; done
0: zero
1: one
2: two with spaces
3: three with single-quotes
```

`get_here_ary`
--------------

There is also a concorde function to help define the our option array,
`get_here_ary` (the "ary" stands for "array"). `get_here_ary` takes a
bash [here document] and returns an array composed of each line of the
heredoc. It's as if you split the heredoc on newlines, then put each
line into an array element (because that's what it does).

Another Message for You, Sir
----------------------------

Actually, here we get to another couple concorde idioms. The first is
that array and hash values are always returned as literals. As we've
already seen that's the same way arrays and hashes are passed into
functions, so that should seem familiar. Bash is good at passing
strings. Not so much other data structures.

The second is slightly more tricky. Rather than use command substitution
(the frequently seen `$()`) to capture string output into a variable,
concorde prefers to put returned strings into the global variable `__`
(double underscore). `__` is noted as a variable reserved by concorde
for its own use. Now that you know how it's used, it's for your use as
well.

The caveat with `__` is that it changes all the time, so you can't rely
on it to stay the same. Any concorde function you call may store its
return value there. If you want to preserve that value, then you need to
immediately assign it to another variable:

``` bash
myvalue=$__
```

`get_here_ary` Redux
--------------------

Here is the definition of two options:

``` bash
get_here_ary <<'EOS'
  ( -o  --option  ''     'a flag'       )
  ( -a  ''        value  'an argument'  )
EOS
```

First, `get_here_ary` strips the leading whitespace from the heredoc.
Then it creates an array from the lines of the heredoc. Finally, it
returns the literal representation of the array in the global variable
`__` (double-underscore).

Notice that the values of the lines are themselves already array
literals. That's how we can pass an array of arrays with concorde.

`parse_options` and `grab`
--------------------------

Now we're ready to feed the options to the parser.

`bin/myscript`:

``` bash
[...]

sourced && return

get_here_ary <<'EOS'
  ( -g --greeting greeting "an alternative greeting to 'Hello'" )
EOS

$(parse_options __ "$@" )
$(grab greeting from __ )
mymain "$greeting" "$@"
```

`parse_options` takes the option definition from `get_here_ary`, as well
as the arguments provided on the command line. It generates a hash with
the name of our option, "greeting", as a key and the user-supplied input
for that option as its value.

Of course, since it's being returned by `parse_options`, the hash is
returned as a hash literal (like an array literal, but keys are strings
and are required). Like other strings, the literal is returned in the
global variable `__`.

At this point we see a new function, `grab`. `grab` takes the name of
our key and gets it from the hash. By "getting", I mean that it creates
a local variable of the same name as the key, with the key's value as
its own value.

As you can see, the local variable "greeting" is then passed to
`mymain`. It contains the user-specified value that we will be saying
"hello" to.

If we run it, we see that it works:

``` bash
> bin/myscript -g Hola
Hola, world!

> bin/myscript --greeting Hola Clive
Hola, Clive!

> bin/myscript --greeting=Hola Jenny
Hola, Jenny!
```

Notice that both GNU-style long options are acceptable, with and without
equals sign.

`parse_options` Again
---------------------

Let's deconstruct the call a bit more:

``` bash
$(parse_options __ "$@")
```

Above, I said that the first argument was the option literal stored in
`__`. However, that would be represented as `"$__"`, which isn't what
I've done here. I've only given `__` instead.

That's because `parse_options` has a special method of receiving the
option definition array, because it is an array literal.

We could have used `"$__"` in the call like:

``` bash
$(parse_options "$__" "$@")
```

and `parse_options` will get the array literal as a normal argument.

However, concorde has another rule to make things more readable.
Wherever concorde's functions expect an array or hash literal as an
argument, they also accept the variable name which holds the literal as
an alternative. In this case, that's `__`.

They can do this because there's no ambiguity between the two kinds of
string, variable name and array literal. Variable names follow a strict,
single-word format, limited to underscores and alphanumerics. By
contrast, array and hash literals have characters which variable names
can't, like parentheses and spaces.

Concorde's functions use its `local_ary` and `local_hsh` functions to
detect the difference and store the correct value.

After the definitions, `parse_options` also expects the arguments passed
to the script. That's the `"$@"` at the end of the call. These are all
of the command-line arguments as typed by the user, including the option
flags themselves as well as the values.

When `parse_options` returns, it sets `__` to the hash of all of the
options. In the case of options which store values the hash key is the
name in the option definition.

In the case of flag options, the hash key is the option itself but with
"\_flag" appended to it. For example, if a flag option had a long name
of "--option", its key in the hash would be "option\_flag". The same
would be true of a short option (e.g. "o\_flag"), but if both a short
and long name are provided for the same option, then it receives the
long name as the key prefix.

Flags are set to "1" if they are present, otherwise they are unset and
not in the hash. Same with named options, if they aren't provided by the
user, then the key is not in the hash.

Either when all defined options are exhausted, or when the special
option "--" is encountered, then option processing stops and the
remainder of the arguments (if any) are treated as positional arguments.

When `parse_options` returns, it resets the positional arguments of the
caller (`$1`, etc.) to contain just the positional arguments left over
from the parsing process. That is, it removes the flag and named options
from the script's positional arguments. That's why the positional
arguments must be passed to `mymain` if they are needed, like so:

``` bash
mymain "$greeting" "$@"
```

The `"$@"` passed to `mymain` is no longer the same set of arguments
which went into `$(parse_options __ "$@")` the line before.

Reworking `mymain`
------------------

Usually, I will pass the option hash as well as the positional arguments
for `mymain` to handle, since `mymain` will usually have several options
to deal with, and that's easier than passing them onesy-twosy.

Let's do that. Of course, we'll need to update the test script first:

`shpec/myscript_shpec.bash`:

``` bash
[...]

describe mymain
  [...]

  it "outputs '[Greeting], world!' if given an option"
    result=$(mymain greeting=Hola)
    assert equal "Hola, world!" "$result"
  end
end
```

Ok, I'm cheating here again. Here's another idiom, that of the succinct
hash literal. "Succinct hash literal" is only a name of my own invention
and has no broader meaning, fyi.

See that `mymain greeting=Hola`? That's a function call, followed by a
hash literal. Normally the hash literal would look like:

``` bash
'( [greeting]=Hola )'
```

However, because hash literals require indices, they are a bit more
unambiguous than array literals. Concorde's functions use this to be
more succinct in what they accept for hash literals. The succinct form
does away with the parentheses as well as the brackets around the key
name. So the following is a valid succinct hash literal (note the fact
that it is in quotes so that it is a single string):

``` bash
'greeting=Hola other_key="other value"'
```

Back to `bin/myscript`:

``` bash
[...]

mymain () {
  $(grab greeting from "$1"); shift

  hello "$greeting" "$@"
}

[...]

$(parse_options __ "$@")
mymain __ "$@"
```

This passes the option hash and remaining positional arguments into
`mymain` for processing. Usually that will be `mymain`'s primary
responsibilty.

`mymain` uses `grab` to get the only value it cares about from the
passed hash and passes that to `hello`. If no greeting was provided by
the user, `$greeting` will exist but be empty.

A Last Couple Points - or - TL;DR
---------------------------------

So we've got a pretty good skeleton for a script that can be TDD'd, has
basic option parsing and can make use of libraries designed to keep our
global namespace clean.

Here's a template I might start with for a script:

``` bash
#!/usr/bin/env bash

get_here_str <<'EOS'
  Detailed usage message goes here
EOS
printf -v usage '\n%s\n' "$__"

script_main () {
  local opt1="default value for opt1"
  $(grab '( opt1 opt2_flag )' from "$1"); shift

  # consume positional arguments
  while (( $# )); do
    case $1 in
      [something] ) [process this case] ;;
                * ) echo "$usage"; exit ;;
    esac
    shift
  done
}

other_functions () {
  ...
}

sourced && return
strict_mode on              # stop on errors and issue traceback

get_here_ary <<'EOS'
  ( -o --opt1   opt1     "an option")
  ( '' --opt2   ''       "a flag"   )
EOS

$(parse_options __ "$@")    # parse options
script_main     __ "$@"     # run it
```

For a more concrete example, here's a slightly more interesting version
of `myscript` with some additions. I've brought `hello` back in for
conciseness:

``` bash
#!/usr/bin/env bash

source concorde.bash

get_here_str <<'EOS'
  myscript OPTIONS [name...name...]

    Outputs "Hello, world!" when run without options.

    Outputs "Hello, [name]!" when provided with a name.

    Multiple names result in multiple greetings, one per line.

    Options:
      --mellow        Don't use an exclamation mark
      -g GREETING     Use GREETING instead of "Hello"
EOS
printf -v usage '\n%s\n' "$__"

myscript_main () {
  $(grab '( greeting mellow_flag )' from "$1"); shift
  local punctuation

  (( mellow_flag )) && punctuation=. || punctuation=''

  hello "$greeting" "${1:-}" "$punctuation"
  (( $# )) && shift

  while (( $# )); do
    hello "$greeting" "$1" "$punctuation"
    shift
  done
}

hello () {
  local    greeting=${1:-Hello}
  local        name=${2:-world}
  local punctuation=${3:-!}

  echo "$greeting, $name$punctuation"
}

sourced && return
strict_mode on

get_here_ary <<'EOS'
  ( '' --mellow ''        "don't use an exclamation mark (flag)")
  ( -g ''       greeting  "an alternative greeting to 'Hello'"  )
EOS

$(parse_options __ "$@")
myscript_main   __ "$@"
```

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

``` bash
get_here_str <<'EOS'
  ( -o --option1            ''      'a flag'  )
  ( '' --option2 argument_name 'an argument'  )
EOS

options_new __
```

  [test-driven]: https://www.agilealliance.org/glossary/tdd
  [shpec]: https://github.com/rylnd/shpec
  [entr]: http://entrproject.org/
  [command substitution]: http://wiki.bash-hackers.org/syntax/expansion/cmdsubst
  [here document]: http://wiki.bash-hackers.org/syntax/redirection#here_documents
