(ns demo.core
  "Entry point and a plain namespace: completion, navigation and REPL targets.")

(defn greet
  "Returns a greeting for NAME."
  [name]
  (str "Hello, " name ", from Hellmacs!"))

(defn person
  "A person as a map."
  [name age]
  {:name name :age age})

(defn -main
  "Set a breakpoint (or evaluate) on the greeting line to test the REPL."
  [& _args]
  (let [p (person "Doomguy" 42)
        greeting (greet (:name p))]
    (println greeting)))
