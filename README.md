nano [![Build Status](https://travis-ci.org/binaryphile/nano.svg?branch=master)](https://travis-ci.org/binaryphile/nano)
====

A nano-sized bash library

Defines a handful of functions useful for writing libraries in bash.

nano API
========

-   **`_joina`** *`delimiter array_name return_variable`* - joins the
    elements of the array `array_name` with the character `delimiter`

*Returns*: the joined string in the variable `return_variable`
