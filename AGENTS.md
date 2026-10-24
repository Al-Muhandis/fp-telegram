# AGENTS.md — fp-telegram

Guidelines for contributors, both humans and AI agents. Read this before
changing the code.

## The one hard rule

The public API is **frozen**: a large amount of third-party software is built
on this library. Only **additive** changes are allowed — new methods, new
properties, new classes. Never rename, remove or change the signature of an
existing public symbol, and never change the behaviour of existing code paths
unless it is a bug fix (explain it in the commit message).

## Project layout

| Path | Purpose |
|------|---------|
| `tgsendertypes.pas` | `TTelegramSender` (all API methods) + request-building JSON wrappers (markups, input media, rich messages) |
| `tgtypes.pas` | receiving side: JSON → `TTelegram*` object tree |
| `tgbasehttpclient.pas` | HTTP client abstraction (`RegisterClientClass` / `GetClientClass`) |
| `tgfclhttpclientbroker.pas`, `tgsynapsehttpclientbroker.pas` | HTTP implementations (FCL and Synapse) |
| `tgutils.pas`, `tgstatlog.pas` | helpers, statistics logger |
| `bot_ex/`, `designtime/` | `fptgbot_ex.lpk` and `fptelegram_dt.lpk` packages |
| `test/` | test suites (see below) |
| `examples/` | demo projects |

## Build

```bash
lazbuild --build-all fptelegram.lpk          # run-time package
lazbuild --build-all fptgbot_ex.lpk           # extended bot (depends on fptelegram)
lazbuild --build-all fptelegram_dt.lpk        # design-time (needs LCL/IDEIntf)
```

Test projects (from `test/`):

```bash
cd test
lazbuild --build-all --no-write-project console.lpi
./console --all --format=plain                # console.exe on Windows
```

`console.lpr` covers the FCL broker, `console_synapse.lpr` the Synapse one
(requires the `use/synapse` submodule: `git submodule update --init`).

## Tests

Two tiers (details in `test/readme.md`):

* **Unit tests** — always registered, run offline. `testsendermock.pas`
  injects a mock HTTP client via `TTelegramSender.HTTPClientClass`; use this
  pattern to test request building of any new method.
* **Integration tests** (`testtelegram.pas`) — registered only when
  `test/testtelegram.ini` has a bot token + chat id. Manual-interaction tests
  are additionally gated behind `[Manual] Enable=1`.

Rules:

* Every new feature needs unit tests. A live integration test is welcome for
  methods with real side effects.
* `testtelegram.ini` contains a **real bot token** and is git-ignored — never
  commit it, never print the token.
* Telegram rate limit is ~20 messages/min per chat: integration tests pause
  between tests (see `TTestTelegramClass.SetUp`). Keep the number of sent
  messages per test minimal.
* On non-UTF8 Windows codepages fpjson mangles non-ASCII strings; the unit
  tests parse JSON with `joUTF8` excluded (see `TTestTgTypesParse.JSONFromString`)
  and compare emoji byte-wise.

## Line endings (important!)

The repository stores two different conventions and mixing them produces
whole-file diffs:

* The **original root files** (`tgsendertypes.pas`, `tgtypes.pas`, `*.lpk`,
  `README*.md`, `examples/readme.md`) keep **CRLF** in git blobs. Commit them
  with `git -c core.autocrlf=false add <file>` (after `unix2dos`).
* The **test sources** (`test/*.pas`, `test/*.lpr`, `test/readme.md`) keep
  **LF** in blobs. Commit with plain `git add` (after `dos2unix`).

## Code conventions

* Style: 2-space indents, `:=`, no space before `:` in assignments; class
  declarations group getters/setters in `private`, published API last.
* JSON keys are named constants (`s_ChatId = 'chat_id'`) in the
  implementation section of `tgsendertypes.pas`.
* Request-building types subclass `TJSONObject`/`TJSONArray` (fpjson) with
  typed properties; receiving types subclass `TTelegramObj` in `tgtypes.pas`
  (the raw JSON is kept and available via `AsString`).
* Optional object properties: getters return `nil` when absent
  (`Find(key, jtObject)` + soft cast), setters replace the value.
* `TInlineKeyboardButton` enforces "exactly one optional action field"
  (`CheckOptnlNull`) — extend that list when adding a new action field.

## Recipe: adding a Bot API method

1. Add the method-name and parameter constants to the implementation section
   of `tgsendertypes.pas` (`s_SendThing='sendThing'`, `s_Param='param'`).
2. Declare the method in `TTelegramSender` public section with default
   parameter values matching the API optionality; only include non-default
   values into the request body.
3. Implement via `SendMethod(...)`: either the open-array form for simple
   calls or the `TJSONObject` form when conditional parameters are needed.
4. Add a request-building test in `test/testsendermock.pas` (copy an existing
   one) and, when useful, a live integration test in `test/testtelegram.pas`.
5. Bump `<Version Release=...>` in `fptelegram.lpk` once per feature wave.

## Bot API reference

The official docs are split per page:
`https://core.telegram.org/bots/api/types/<typename>.md` and
`https://core.telegram.org/bots/api/methods/<methodname>.md`
(`api.md` itself is only an index now). The changelog:
`https://core.telegram.org/bots/api-changelog`.

When adding support for new Bot API types, prefer small typed wrappers +
raw JSON passthrough (as done for rich messages) over mapping every
subclass unless there is a clear demand.

## Generated files — do not hand-edit

`FpTelegram.json` and `update_FpTelegram.json` are OPM publish manifests
regenerated by Lazarus when publishing a package release.
