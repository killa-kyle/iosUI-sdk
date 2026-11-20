# Reference interactions

This ledger separates observed app behavior from SDK implementation choices.
Reference recordings, application artifacts and account information stay private.
The package uses independently written Swift code and platform controls.

## Claude Code: input during work

Reference: installed Claude Code CLI 2.1.326 on macOS, inspected on November 20,
2026. A separate fixture workspace contained 30 numbered sample entries. Existing
MCP configurations and hooks were disabled. The request read that fixture and
returned text; it did not change project files.

Observed in the running terminal interface:

- The composer remains editable while a request is processing.
- Submitting a follow-up marks it queued and exposes separate editing and
  send-now controls.
- Escape changes the running response to interrupted and asks for the next
  instruction. Up recalls the follow-up text into composer history.
- File-reading activity presents a compact summary with an expansion shortcut.

These observations support distinct draft, queued input and running activity
states. The host should expose queue/edit/send-now intents and confirm admission
and cancellation. UI state alone does not prove a remote task stopped. The SDK's
activity model preserves explicit expansion choices across host updates.

Not verified in this pass: activity expansion, queue persistence across restart,
automatic resumption, terminal scroll displacement, or physical iOS posture.

## ChatGPT and Codex

Initial inspection identified the installed desktop bundle and its packaged
renderer. A terminal-specific module schedules bottom scrolling through animation
frames and cancels its pending frame on teardown. This is a static finding about
that module; it does not establish chat-transcript behavior.

The first general JavaScript graph exceeded the analysis tool's retention limit.
Further inspection must select a smaller source boundary. The next comparison
should replay a long fixture while scrolling back, expand activity during output,
then change the keyboard/viewport on the iOS reference where available.

## Native acceptance checklist

Use the same local content and record differences in viewport, platform and input:

- New chunks do not move a reader who scrolled away from the end.
- Latest explicitly returns to following.
- Prepending history retains a measured row and pixel offset.
- Activity expansion choice survives updates and confirmed termination.
- A delayed scroll or keyboard callback cannot act on a new conversation/window.
- Keyboard focus keeps the draft and composer reachable.
- Reserved regions come from explicit host geometry; layout previews are labelled.

Core transition tests cover the policy boundaries. Native replay is required for
claims about actual gestures, scroll position, keyboard geometry and motion.
