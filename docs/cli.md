# CLI Reference (`bin/hellmacs`)

Hellmacs includes a command-line tool (`bin/hellmacs`) to install, synchronize, upgrade, lock, test, and troubleshoot your installation without launching interactive Emacs.

---

## Commands

### `install`
```sh
bin/hellmacs install [--env] [--no-config]
```
Performs initial setup:
* Copies starter templates from `static/` to `~/.config/hellmacs/` (unless `--no-config` is provided or files already exist).
* Executes `sync` to download and compile all packages.
* If `--env` is supplied, exports your shell environment into `~/.local/share/hellmacs/env.eld`.
* Executes `doctor` to ensure everything is operational.

---

### `sync`
```sh
bin/hellmacs sync
```
* Analyzes all active modules declared in your `init.el` and `packages.el`.
* Uses Elpaca to fetch missing packages and compile Tree-sitter grammars.
* Rewrites the static load profile (`profile.eld`) for sub-second startup times.

---

### `upgrade`
```sh
bin/hellmacs upgrade [--packages]
```
* Pulls the latest commits from the Hellmacs git repository.
* Updates all installed packages that do not have a fixed `:pin`.
* Runs `sync` to generate a fresh profile.
* With `--packages`, upgrades only installed packages without running `git pull` on Hellmacs itself.

---

### `lock`
```sh
bin/hellmacs lock
```
* Generates a lockfile (`~/.config/hellmacs/packages.lock.eld`) pinning the exact Git commit SHA of every installed package.
* Commit this lockfile into your dotfiles repo to achieve 100% reproducible environments across team laptops and CI.

---

### `doctor`
```sh
bin/hellmacs doctor
```
Runs a health check on your system, reporting:
* Emacs version and native-compilation status.
* External CLI tools (`git`, `rg`, `fd`, `mvn`, `gradle`, `unzip`, JDKs).
* Module-specific assets (fonts, icons, language server binaries).
* Configuration and profile validity.

---

### `env`
```sh
bin/hellmacs env [--clear]
```
* Captures your current shell environment (`PATH`, `JAVA_HOME`, proxy settings, etc.) into `~/.local/share/hellmacs/env.eld`.
* Allows Emacs launched from GUI desktop launchers (which lack full shell environment) to discover all system tools.
* `--clear` removes the saved environment file.

---

### `gc`
```sh
bin/hellmacs gc [-n]
```
* Removes old and orphaned package installations that are no longer referenced by any enabled module.
* Use `-n` for a dry run.

---

### `test`
```sh
bin/hellmacs test [SELECTOR]
```
* Executes the internal ERT unit test suite.

---

## Multi-Profile Flag (`--profile`)

Every command accepts `--profile <NAME>` as its first argument:

```sh
bin/hellmacs --profile work sync
bin/hellmacs --profile work doctor
bin/hellmacs --profile work upgrade
```
