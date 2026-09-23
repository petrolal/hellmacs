(ns demo.core-test
  (:require [clojure.test :refer [deftest is testing]]
            [demo.core :as core]))

(deftest greets-by-name
  (is (= "Hello, Ann, from Hellmacs!" (core/greet "Ann"))))

(deftest builds-a-person
  (testing "the map has both keys"
    (is (= {:name "Bob" :age 7} (core/person "Bob" 7)))))
