# fp-telegram #

Library for working with the Telegram Bot API in FreePascal/Lazarus

FreePascal wrapper classes for the Telegram bot API. You can use it in your own production projects. Please join if you want to help the development of this library.

The library **does not use any third-party libraries**, besides the built-in FPC. You can use it both independently and together with other libraries,
for example, as a [plug-in](https://github.com/Al-Muhandis/brook-telegram/) to Brook-framework/Brook4FreePascal.

**Supported Bot API version: 10.3** (August 24, 2026), including Rich Messages (10.1–10.3).

# Features

* Receiving updates: long polling (`getUpdates`/`getUpdatesEx`) and webhooks; per-update events (`OnReceiveMessage`, `OnReceiveCallbackQuery`, `OnReceiveMessageReaction`, business updates and more), command handlers (`CommandHandlers['/start']`), ban/user-class filters (`IsBanned`, `IsAdminUser`).
* Sending: text, photos, videos, audio, voice, documents, animations, polls, locations, invoices, media groups — by `file_id`, by URL, by file upload and by stream.
* Complete reply/inline markups: inline keyboards, reply keyboards (`is_persistent`, placeholders), Web App buttons, login URLs, copy-text buttons, pay/disabled buttons, poll and user/chat request buttons, `switch_inline_query_chosen_chat`.
* Rich Messages (Bot API 10.1+): `sendRichMessage` (markdown, HTML or blocks), buttons inside rich messages, editing via `editMessageTextRich`, receiving `Message.RichMessage` with `PlainText`/`ExtractButtons` helpers.
* Chat and user administration: ban/unban, promote/restrict member, pin/unpin messages, batch delete/forward/copy.
* Bot profile: commands, description, short description, name, menu button.
* Business connections, `answerWebAppQuery`, `getUserProfilePhotos`, `getChat`/`getChatMember`/`getChatAdministrators`.
* Logging: `Logger: TEventLog` + `OnLogMessage` event, debug of all requests/responses.
* The `bot_ex` package: a ready `TTelegramBot` with statistics, feedback and deeplink handling, i18n and a plugin system.

# Requirements

* FPC 3.2.2+ (3.0.4 is still supported with limitations); Lazarus 2.0+ for the packages and design-time support.
* No external dependencies. HTTPS works through the FPC built-in OpenSSL support (`tgfclhttpclientbroker`) or through [Synapse](https://github.com/geby/synapse) (`tgsynapsehttpclientbroker`, HTTP proxy support).

# Installation

* **Lazarus / OPM**: install via the Online Package Manager (search "FpTelegram") — it installs both the run-time and design-time packages.
* **Manual**: open and compile `fptelegram.lpk` (run-time), optionally `fptgbot_ex.lpk` (extended bot) and `fptelegram_dt.lpk` (design-time).

# Quick start

```pascal
uses tgsendertypes, tgfclhttpclientbroker; // the broker registers the HTTP client

var
  Bot: TTelegramSender;
begin
  Bot := TTelegramSender.Create('<bot token>');
  try
    Bot.OnReceiveMessage := @HandleMessage;
    if Bot.sendMessage(ChatID, 'Hello from fp-telegram!') then
      WriteLn(Bot.JSONResponse.AsJSON);
    // a rich message with a button (Bot API 10.1+)
    // Rich := TInputRichMessage.CreateFromMarkdown('# Heading' + LineEnding + 'text');
    // Rich.AddButtonsBlock.Buttons.AddCallbackButton('Press', 'cb1');
    // Bot.sendRichMessage(ChatID, Rich);
  finally
    Bot.Free;
  end;
end;
```

More snippets: see the `examples` folder and the [wiki](https://github.com/Al-Muhandis/fp-telegram/wiki).

# Design-time

The library has two packages: run-time (`fptelegram.lpk`) and design-time (`fptelegram_dt.lpk`). `fptelegram_dt.lpk` contains the component `DTLongPolBot`.
It is a ready-made longpolling bot which you can use for the rapid development of longpolling telegram bots.
Look about longpolling [here](https://github.com/Al-Muhandis/fp-telegram/wiki/How-to-step-by-step.-Creation-telegram-bot-in-Lazarus-(longpolling)).
This component can be used in GUI and non-GUI applications, daemons and services and
even on a web server (however, in the latter case it is preferable to use the webhook mechanism to receive updates.
About webhooks [here](https://github.com/Al-Muhandis/fp-telegram/wiki/How-to-step-by-step.-Creation-telegram-bot-in-Lazarus-(webhook)).

# Layout

| Unit | Purpose |
|------|---------|
| `tgsendertypes` | `TTelegramSender`: all API methods, request-building JSON wrappers (markups, input media, rich messages, commands) |
| `tgtypes` | receiving side: JSON → `TTelegram*` object tree (updates, messages, chats, reactions, rich messages) |
| `tgbasehttpclient` | HTTP client abstraction; brokers register themselves via `RegisterClientClass` |
| `tgfclhttpclientbroker` / `tgsynapsehttpclientbroker` | FCL (`fphttpclient`) and Synapse implementations of the abstraction |
| `tgutils` | text helpers: Markdown escaping, captions, deep links |
| `tgstatlog` | statistics logger (daily CSV files) |
| `bot_ex` (`fptgbot_ex.lpk`) | `TTelegramBot`: statistics, feedback, deeplinks, i18n, plugins |
| `designtime` (`fptelegram_dt.lpk`) | `DTLongPolBot` component |
| `test` | unit + integration test suites (see `test/readme.md`) |

An HTTP client can be injected per sender: `Bot.HTTPClientClass := TMyClient` — this is how the tests mock the network layer.

# Testing

The `test` folder contains two tiers:

* **Unit tests** (always run, offline): request building, JSON parsing, markups, the sender logic against a mock HTTP client.
* **Integration tests** (only when `test/testtelegram.ini` is configured with a bot token): real requests to the Telegram API. Tests that need a human interaction are additionally gated behind `[Manual] Enable=1`.

```bash
cd test
lazbuild --build-all console.lpi
./console --all --format=plain     # or console.exe on Windows
```

CI builds everything and runs the unit tests on every push.

# Examples

You can find in the `examples` folder various architectures for using the library:
long polling and webhooks,
single-threaded and multithreaded,
using the design-time component and runtime classes — see `examples/readme.md`.

# Contributing (humans and AI agents)

See [AGENTS.md](AGENTS.md) for the build/test commands, code conventions (including the repository line-ending rules) and the recipe for adding a new API method.
