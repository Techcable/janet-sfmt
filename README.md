Simple format-strings for Janet
===============================
Lightweight format strings for Janet: `"3 $(2 + 2) 5"` or `"3 $var 5"`

Inspired by Kotlin-style `"foo $bar"` template strings or Python `f"foo {bar}"` format strings.

Implemented as a macro wrapper around the builtin [`string`](https://janet-lang.org/api/index.html#string) function.

Similar to [spork/temple](https://github.com/janet-lang/spork/blob/master/spork/temple.janet), but significantly simpler (and does no HTML escaping).

## Examples
```janet
(def var "bar")
(print (sfmt "foo $var baz") # Prints "foo bar baz"
(print (sfmt "3 $(2 + 2) 5") # Prints "3 4 5"
```

At runtime (after macro compilation), everything boils down to an invocation of `string`.
So `(sfmt "foo $var baz")` becomes `(string "foo " var " baz")` after macro expansion (which is almost exactly what a user would write by hand). 

The main downside of using `string` directly is that there is no support for recursive types like arrays and tables.
The underlying call to `(string [3 4])` will just be based on a pointer (I get `"<tuple 0x6000022340E0>"`).
