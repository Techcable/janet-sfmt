(def- open-closing-table {"(" ")" "{" "}" "[" "]"})


(defn- desc-string-loc [line col]
  (if (= line 1) (string "offset " col) (string "line " line " offset " col)))

(def- fmt-peg
  (do
    (defn parse-fmt-expr [line col args]
      (def parser (parser/new))
      (defn check-error []
        (when (= :error (parser/status parser))
          (def [line col] (parser/where parser))
          (errorf "Bad syntax for expression at %s: %s" (desc-string-loc line col) (parser/error parser))))
      (parser/where parser line col)
      (parser/consume parser (string ;args))
      (check-error)
      (parser/eof parser)
      (def res (parser/produce parser))
      (check-error)
      {:expr res})
    (defn describe-bad-dollar [line column char]
      (def desc (if (empty? char) "Unexpected EOF" (string/format "Unexpected char %q" char)))
      (string/format "%s after a `$` at %s" desc (desc-string-loc line column)))
    (defn verify-closing [opening closing]
      (defn expected-closing (in open-closing-table opening))
      (assert (not= closing expected-closing)
              (errorf "Expected closing %q to match opening %q (but got %q)" expected-closing opening closing))
      closing)
    (peg/compile ~{:main (* (any :fmtPart) (+ -1 (error)))
                   :fmtPart (+ :dollarExpr :litString)
                   :dollarExpr (* "$" (+
                                        (if "(" (/ (* (line) (column) :balancedGroups) ,parse-fmt-expr))
                                        (/ :token ,symbol)
                                        (/ "$" "$")
                                        (error (/ (* (line) (column) (% (? (<- 1)))) ,describe-bad-dollar))))
                   :balancedGroups (group (unref (*
                                                   (capture (set "({[") :openGroup)
                                                   (any (+ :balancedGroups '(some (if-not (set "{([])}") 1))))
                                                   (cmt (* (backref :openGroup) '(set ")}]")) ,verify-closing))))
                   :litString '(some (if-not "$" 1))
                   # See https://janet-lang.org/docs/syntax.html#Grammar
                   :symchars (+ (range "09" "AZ" "az" "\x80\xFF") (set "!$%&*+-./:<?=>@^_"))
                   :token '(some :symchars)})))

(defmacro sfmt
  ````Evaluate a format string, permitting string substitution with `$`

  Substituion is done based on the `$` symbol:
  - Use $(f a) to quote the value of `(f a)` into the result
  - Use $foo to interpolate a variable foo
  - Use $$ to escape the dolar sign itself (equivalent to `$(string '$')`)

  At runtime, everything should compile away to an invocation of the string function

  So `"Foo $bar (+ 3 4)" would translate into (string "Foo " bar (+ 3 4))"````
  [format-string]
  (def template (peg/match fmt-peg format-string))
  (pp template)
  (def parts @[])
  (defn append-literal [lit]
    (def last-index (- (length parts) 1))
    (def last-part (last parts))
    # Combine literals at compile time, not runtime
    (if (string? last-part)
      (set (parts last-index) (string last-part lit))
      (array/push parts lit)))
  (each entry template
    (match entry
      {:expr expr} (array/push parts expr)
      # Symbols have check to avoid unecessiary concat, while symbols
      # are pushed directly into the result
      [x] (if (string? x) (append-literal x) (array/push parts entry))))
  ~(string ;,parts))
