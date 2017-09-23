Message For You, Sir [![Build Status](https://travis-ci.org/binaryphile/concorde.svg?branch=master)](https://travis-ci.org/binaryphile/concorde)
====================

Bash scripting in my own particular...\[sigh\]...

Concorde: "Idiom, sir?"

Idiom!

Concorde is a toolkit for writing bash scripts and libraries.

Features
========

-   an enhanced-getopt-style option parser - `parse_options`

-   array and hash utility functions (hashes as in "associative arrays")

-   smarter versions of `source`, a.k.a. the `.` operator - `require`
    and `require_relative`

-   support for test frameworks - `sourced`

-   namespaces to isolate library variables from one another

-   importation of only specified functions from libraries - `bring`

Requirements
============

-   GNU `readlink` on your PATH - for Mac users, `greadlink` is also
    acceptable

-   `sed` on your PATH

-   bash 4.3 or 4.4 - tested with:

    -   4.3.11

    -   4.3.33

    -   4.3.42

    -   4.4.12

Reserved Global Variables
=========================

Concorde reserves a couple global variables for its own use.  They begin
with `__` (double-underscore)

-   `__` - double-underscore itself

-   `__ns` - short for "namespace"

Any script or library used with concorde cannot change the purpose of
these variables.

Installation
============

Clone or download this repository, then put its `lib` directory in your
PATH, or copy `lib/concorde.bash` into a PATH directory.

Use `source concorde.bash` in your scripts.

Usage
=====

Consult the API specification below for full details.

Functions Which Return Boolean Values
-------------------------------------

Functions used for their truth value are typically used in expressions
in order to trigger actions.

For example the `sourced` function typically is used like so:

```bash
sourced && return
```

These functions use the normal bash return code mechanism where `0` is
success and any other value is failure.

Functions Which Return Strings
------------------------------

Bash's typical mechanism for storing strings generated by a function is
to use command substitution.

For example, the result of an `echo` command might be stored like so:

```bash
# This is not concorde's method of doing this
my_value=$(echo "the value")
```

Concorde doesn't use this method as it is prone to capturing unexpected
output and also requires an unnecessary subshell.

Any concorde function which returns a string value does so in the global
variable `__` (double-underscore).

Because any function is allowed to overwrite `__` to return a value, you
want to save that value before calling any other functions like so:

```bash
get <<<"the value"
my_value=$__
```

`get` is a concorde function which stores a string from `stdin` and
`<<<` feeds it the supplied string.

`__` must be treated much the same as the `$?` return code, since every
successive command may change it.

Note that because `__` is a global, it is discarded by the subshells
which are employed by pipelines.  Therefore you cannot use pipelines to
return strings from concorde functions.  For example, this will not
work:

```bash
# Doesn't work
echo "the value" | get
my_value=$__
```

Because `__`'s value is ephemeral, it can be used to hold interim values
and feed the output of one operation to the next:

```bash
get <<<"the value"
to_upper "$__"
value=$__
```

`to_upper` capitalizes the input string and returns it in `__`.

Note that `__` is always a string value.  Your functions should be
careful not to store an actual array or hash in it, e.g. `__=( "array
item" )`.

This is because some of concorde's features rely on `__`'s type to be
string.  Since bash automatically converts a string variable to an array
or hash when assigned, doing so can interfere with concorde.

Dealing with Hashes and Arrays as Parameters
--------------------------------------------

Bash can pass string variables to functions, but is not able to pass
arrays nor hashes as individual parameters to a function.

If an array needs to be treated as a singular parameter to a function,
typical bash practice is to use the shortcut of not passing it at all
and instead just referring to the global variable directly by name.

Another approach is to use named references (`declare -n` or
`${!reference}`) instead of using a normal local variable.

For a variety of reasons, each of these approaches is problematic.

The workaround employed by concorde is to convert arrays and hashes to
strings (serialize them) when crossing function boundaries, whether as
arguments or return values.  This gives you full control of your
variable namespace. And while it's not good at passing arrays (hashes
especially), bash is good at passing strings, so why not use that.

Any concorde function which expects an array or hash argument will
expect a string representation of the array. Although there are a couple
functions which actually operate on arrays/hashes directly, those are
clearly noted in the API documentation.

Although bash doesn't have a general-purpose string literal
representation for an array, it does define such a format in its array
assignment statements. You can see an example by running `declare -p
<variable_name>`.

Concorde borrows the same format for the array literals expected by
concorde's functions, with minor changes.

### Passing an Array or Hash

For example, to call a function `my_function` which expects a single
array argument, you might define the array, then use concorde's `repr`
function to generate the string format:

```bash
my_ary=( "first item" "second item" )
repr my_ary
my_function "$__"
```

Note that `repr` takes the name of the array as an argument and returns
the string representation in `__`.

The same method works for a hash.

### Receiving an Array

To write a function which receives such an argument, you use concorde's
`local_ary` function:

```bash
my_func () {
  $(local_ary input_ary=$1)
  local item

  for item in "${input_ary[@]}"; do
    echo "$item"
  done
}
```

`ary` is short for "array".

`local_ary` creates a local array variable, in this case `input_ary`,
and gives it the contents provided in the string argument.  For the rest
of the function you use it like a normal array, because it is one.

Note that the `$()` command substitution operator around `local_ary` is
necessary.  Without it, `local_ary` can't create a local variable in the
scope of the caller.

To receive a hash instead of an array, simply use the `local_hsh`
function instead of `local_ary`.

### Just Passing Through

Of course, if your function only needs to receive an array/hash in order
to pass it to another function, you don't need to convert the string
representation into its array form, you can simply receive and pass the
array in its string form:

```bash
my_function () {
  local array_representation=$1
  function2 "$array_representation"
}
```

### Passing Arrays/Hashes by Name

Both `local_ary` and `local_hsh` will allow you to pass them the name of
the variable holding the string representation instead of the
representation itself. They will detect the variable name and expand it
themselves.  This is the recommended method of calling them, as detailed
in the "caveat" section below.

This means you can call any concorde function which takes an array like
so:

```bash
array=( "item one" )
repr array
member_of __ "item one" && echo "'item one' is in array"
```

`member_of` takes an array and an item and returns whether the array
contains the item.  `repr` returns the string representation of the
array in `__`. Concorde lets you feed the name `__` as the first
argument to `member_of` instead of the expansion `$__`.

Concorde supports passing by name for array and hash representations,
but not normal strings.

### A Caveat

The recommended way to use `local_ary` and `local_hsh` (and functions
that employ them) is to always pass array parameters by name.

The caveat introduced by the pass-by-name functionality is that when
*not* passing by name, an array which happens to contain only one item,
one that is the name of a variable, it will have that item expanded when
it wasn't meant to be.

This is not a problem for hashes, only arrays.

Be careful to avoid this situation or you will get unexpected behavior.
The recommended way to avoid it is to always pass by variable name.  If
you do pass a literal, however, ensure that it is not a single-item
array that is also the name of a variable.

### Passing by Literal

You may also construct your own literals for arrays or hashes but each
follows its own, slightly different, rule.

#### Arrays (Not Hashes)

The array syntax is to use a string which contains whitespace-separated
items.  Whitespace includes spaces, tabs and newlines, the normal
values in the field separator variable `IFS`.

Array items which contain whitespace must either be quoted or escaped:

```bash
# example actual arrays and equivalent representations
array1=( 'an item' 'another item' )
representation1="'an item' 'another item'"

array2=( an\ item  another\ item )
representation2="an\ item  another\ item"
```

Either form, quoted or escaped, is acceptable.

Notice that the representations above are simply the string form of what
appears between the parentheses in the array declarations.  In fact, an
array representation should be usable in the form:

```bash
eval "array=( $representation )"
```

For the most part, an array representation is equivalent to the portion
of `declare -p`'s output from inside the parentheses, minus the
bracketed indices.

`repr` returns the escaped form, rather than quoted, and without
indices.  Therefore concorde doesn't preserve the indexing of sparse
arrays, since those require the inclusion of indices.

The following are both examples of valid array literals:

```bash
# newlines separating items (spaced items still require quotes)
my_literal='
one
two
"three and four"
'

another_literal='one two "three and four"'
```
### Hashes

Hashes, like arrays, are similar to the portion of `declare -p`'s output
from inside the parentheses.  Unlike arrays, hash literals must include
indices.  Unlike the regular form of hash declarations though, the
indices are not in brackets.  For example:

```bash
my_literal="one=1 two=2 three_and_four='3 and 4'"
```

In this case, quoted items are quoted after the index and equals sign.
Escaping works as well.

`repr` generates this format when invoked on a hash.

Notably, the following does *not* work on a hash representation:

```bash
# does NOT work
eval "declare -A my_hsh=( $representation )"
```

That's because of the missing brackets on indices.

Because the indices do not have brackets, concorde also doesn't support
hash indices with spaces.  In general, concorde only supports hash
indices which are also usable as variable names.  That is, keys which
are composed only of alphanumeric and underscore characters, and don't
start with a number.

### Passing Arrays as Multiple Arguments

`local_ary` is also geared to accept multiple arguments as an array.
This can be useful when converting positional arguments into a named
array:

```bash
my_function () {
  $(local_ary my_ary="$@")
  local item

  for item in "${my_ary[@]}"; do
    do_something_with "$item"
  done
}
```

### Passing Hashes as Multiple Arguments (a.k.a. Keyword Arguments)

`local_hsh` can do the same thing with multiple arguments:

```bash
my_function () {
  $(local_hsh my_hsh="$@")
  local key

  for key in "${!my_hsh[@]}"; do
    do_something_with "${my_hsh[$key]}"
  done
}
```

Calling a function like this looks familiar from other languages:

```bash
my_function one=1 two=2 threeandfour="3 and 4"
```

Languages such as python and ruby allow you to specify named arguments
via keywords like the above.

Concorde's functions specify that any required arguments are passed
first as positional arguments, and optional arguments are passed last as
keyword arguments.  Optional arguments typically have built-in default
values.  Here is an example of how such a function is implemented:

```bash
my_function () {
  local required_arg=$1; shift
  local optional_arg="default value"
  $(grab optional_arg from "$@")

  do_something_with "$required_arg"
  do_something_with "$optional_arg"
}
```

Any required arguments are stored and `shift`ed out of the positional
arguments, then the remainder of optional arguments are `grab`bed from
the remaining arguments.  `grab` just passes them to `local_hsh` before
extracting them into local variables based on the key name(s).

This is what it looks like calling `my_function`:

```bash
my_function "required value" optional_arg="optional value"
```

`optional_arg` can be left off, in which case it will get the value
`"default value"`.

To see an example of this, look at the `die` function.

### The Other Array Literal, or Nested Arrays

You can construct multidimensional arrays with concorde fairly simply.

Let's start with a function which expects a two-dimensional array as its
only argument:

```bash
my_function () {
  $(local_nry outer_ary=$1)
  local item
  local row

  for row in "${outer_ary[@]}"; do
    $(local_ary inner_ary=$row)
    for item in "${inner_ary[@]}"; do
      echo "$item"
    done
  done
}
```

`local_nry` introduces the idea of a newline-delimited array
representation.  It creates a normal, local array named `outer_ary`, but
expects a slightly different input.

It expects a multiline array literal, separated by newlines.  This is
different from `local_ary` because it only splits on newlines, not
spaces or tabs.  In fact, that's the only difference between the two.

That means that each row of the array representation can also contain an
array representation, although those arrays can't hold unescaped
newlines, just whitespace and escaped newlines.

The function above creates the outer array from the newline-delimited
representation, then interprets each row as a regular array
representation.  That makes a nested array.

Here's what such a representation looks like, using `get` and a heredoc:

```bash
get <<'EOS'
  "first array, item one"  "first array, item two"
  "second array, item one" "second array, item two"
EOS
my_func __
```

which would output:

```bash
first array, item one
first array, item two
second array, item one
second array, item two
```
