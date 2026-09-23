(ns demo.broken-test
  "Fails on purpose, but only when run with -Dhellmacs.fail=true, so a
  normal run passes and failure handling can still be tested."
  (:require [clojure.test :refer [deftest is]]
            [demo.core :as core]))

(when (= "true" (System/getProperty "hellmacs.fail"))
  (deftest fails-on-purpose
    (is (= "heaven" (core/greet "Ann")))))
