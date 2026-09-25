# Contributing & Development Workflows

This guide outlines how to develop, test, and contribute to **Hellmacs**.

---

## 1. Local Development Setup

To work on Hellmacs itself:
1. Clone the repository into a development directory:
   ```sh
   git clone https://github.com/petrolal/hellmacs.git ~/src/hellmacs
   ```
2. Launch a test instance of Emacs using the test directory:
   ```sh
   emacs --init-directory ~/src/hellmacs
   ```
3. Or test isolated named profiles:
   ```sh
   ~/src/hellmacs/bin/hellmacs --profile dev sync
   emacs --init-directory ~/src/hellmacs --profile dev
   ```

---

## 2. Running Test Suites

Hellmacs includes an extensive ERT (Emacs Lisp Regression Testing) suite with zero external mock dependencies.

```sh
# Run the entire test suite
bin/hellmacs test

# Run a specific test selector
bin/hellmacs test test-java
bin/hellmacs test test-debugger
```

### Integration & Parity Checklists
* `test/integration/java-e2e.el`: End-to-end integration test validating real JDTLS, compilation, debugger stepping, and hot-code replacement against sample projects.
* `test/integration/java-parity.el`: Automated parity runner verifying that all daily IntelliJ/Eclipse capabilities function correctly on Maven/Gradle test projects.

---

## 3. Creating a New Module

To build a new feature or language module:

1. Copy the template from [`static/module-template/`](file:///home/petrolal/hellmacs/static/module-template/) into `modules/<category>/<name>/`:
   ```sh
   cp -r static/module-template modules/lang/scala
   ```

2. Implement the required module files:
   * **`packages.el`**: Declare packages using `(package! <name>)`, the modules yours needs with `(depends-on! :tools lsp)`, and tree-sitter grammars with `(hellmacs-treesit! ...)`.
   * **`config.el`**: Configure features inside `use-package` blocks.
   * **`autoload.el`**: Export interactive commands lazily loaded before the module is invoked.
   * **`doctor.el`**: Define diagnostic checks for `bin/hellmacs doctor`.

3. Register your module in [`static/init.example.el`](file:///home/petrolal/hellmacs/static/init.example.el) and add ERT tests in `test/`.

4. Run `bin/hellmacs sync` and verify with `bin/hellmacs test`.
