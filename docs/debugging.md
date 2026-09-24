# Debugging & Hot Code Replacement

Hellmacs provides enterprise-grade debugging capabilities via the **Debug Adapter Protocol (DAP)** using `dap-mode` and `dap-java` (Microsoft's `java-debug` server).

---

## Enabling Debugger Support

Ensure `:tools debugger` and `:tools lsp` are present in your `(hellmacs! ...)` configuration block in `~/.config/hellmacs/init.el`:

```elisp
(hellmacs! :tools
           lsp
           debugger           ; DAP debugger (C-c d)
           build

           :lang
           (java +lombok))
```

Run `bin/hellmacs sync` to download and pin the Java debug server.

---

## Debugging Workflows

All debugging commands are centralized under the `C-c d` prefix.

### Launching & Sessions
| Key | Command | Description |
|---|---|---|
| `C-c d d` | `dap-debug` | Start a new debug session (select launch template) |
| `C-c d D` | `dap-debug-last` | Re-launch the last active debug configuration |
| `C-c d r` | `dap-debug-restart` | Restart current debug session |
| `C-c d q` | `dap-disconnect` | Stop and terminate the debug session |

### Breakpoints
| Key | Command | Description |
|---|---|---|
| `C-c d b` | `dap-breakpoint-toggle` | Toggle line breakpoint on current line |
| `C-c d B` | `dap-breakpoint-condition` | Set a condition on breakpoint (e.g. `i == 10`) |
| `C-c d L` | `dap-breakpoint-log-message` | Set a log point (logs message without stopping execution) |
| `C-c d x` | `dap-breakpoint-delete-all` | Clear all active breakpoints across workspace |

### Stepping Through Code
When paused at a breakpoint, use stepping shortcuts:
* `C-c d n`: Step over (`next`)
* `C-c d i`: Step in (`step-in`)
* `C-c d o`: Step out (`step-out`)
* `C-c d c`: Continue execution (`continue`)

> **Fast Stepping**: After initiating a step with `C-c d n` (or `i`, `o`, `c`), you can keep stepping simply by pressing `n`, `i`, `o`, or `c` repeatedly without pressing the `C-c d` prefix again! Press any other key to resume normal editing.

### Inspecting Variables & Expressions
* `C-c d e`: Evaluate expression under point / selection.
* `C-c d E`: Prompt to evaluate an arbitrary expression.
* When paused, Hellmacs automatically presents side panels showing:
  * **Locals**: Local variables and their current values.
  * **Breakpoints**: Overview of all active breakpoints.
  * **Expressions**: Watched expressions.
  * **REPL**: Interactive evaluation console.

### Debugging Unit Tests
* `C-c d t`: Debug the test method under the cursor.
* `C-c d T`: Debug all tests in the current test class.

---

## Hot Code Replacement (Crucible: `C-c h r`)

Hellmacs supports **Hot Code Replacement (HCR)** into running JVM debug sessions:

1. Start your application in debug mode via `C-c d d`.
2. Make code edits in your Java source files.
3. Press **`C-c h r`** (Crucible).
4. JDTLS compiles the updated class files and immediately hot-swaps the new bytecode into the running JVM process without requiring an application restart.
