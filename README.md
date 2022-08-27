Simple format-strings for Janet
===============================
Lightweight format strings for Janet "3 $(2 + 2) 5" or "3 $var 5" 

Inspired by kotlin "foo $bar" strings or Python f"foo "

Implemented as a macro wrapper around the [`string`](https://janet-lang.org/api/index.html#string) function.

## Examples
```janet
(defn var "bar")
(print (sfmt "foo $var baz") # Prints "foo bar baz"
(print (sfmt "3 $(2 + 2) 5") # Prints "3 4 5"
```

Unlike [spork/temple] this doees absolutely no HTML escaping at all.

At runtime, everything boils down to an invocation of `string`.
So `(sfmt "foo $var baz")` becomes `(string "foo " var " baz")` after macro expansion (which is almost exactly what a user would write by hand). 
