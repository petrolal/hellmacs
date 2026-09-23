(ns demo.test-runner
  (:require [clojure.test :as t]
            demo.core-test
            demo.broken-test))

(defn -main [& _args]
  (let [{:keys [fail error]} (t/run-tests 'demo.core-test 'demo.broken-test)]
    (System/exit (if (zero? (+ fail error)) 0 1))))
