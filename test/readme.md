# Tests

The test suite consists of two tiers.

## Unit tests

Real unit tests: they run completely offline (no bot, no network) and are
always registered:

* `testtgtypes.pas` — parsing of the Telegram API JSON (updates, messages,
  users, chats, payments, reactions, quotes and so on) into the `TTelegram*`
  object tree of the `tgtypes` unit.
* `testsendertypes.pas` — the request-building JSON wrappers of the
  `tgsendertypes` unit: reply markups and keyboards, bot commands, labeled
  prices, input media, inline query results.
* `testtgutils.pas` — text helpers of `tgutils` and the statistics logger
  `tgstatlog`.
* `testsendermock.pas` — the logic of `TTelegramSender` itself (request
  building, response handling, update dispatching, command handlers) with a
  mock HTTP client injected via the `TTelegramSender.HTTPClientClass` property.

## Integration tests

`testtelegram.pas` performs real requests to the Telegram API server. These
tests are registered **only** when `testtelegram.ini` is configured (both the
bot token and the chat ID are present), so CI and machines without a test bot
simply skip them.

### Manual tests

A few tests need a human interaction during the run or a private chat started
with the bot. They are excluded from the default run and are registered only
when the ini contains:

``` INI
[Manual]
Enable=1
```

They are: `TTestSenderManual.SendReplyKeyboard` (press Start in the bot's
private chat first), `TTestReceiveLongPolling.ReceiveUpdate` (send a message
to the bot during the test) and `TTestPayments` (send the invoice and pay it
during the test; the payment provider token must be valid).

Add some data so that you can test the telegram bots API wrapper
``` INI

[Bot]
;; Please specify bot token below!
Token=

[API]
;; Do not pay attention to this - it is needs for countries where telegram is blocked. (You can specify custom telegram endpoint)
;; Endpoint=
[Chat]
;; Enter Your user/chat ID
ID=

;; The section for payments tests
[Payment]

;; Get from the @BotFather
ProviderToken=
;; For example, USD or USD
Currency=USD
;; For example, $
PricePortionLabel=
;; for example: 10000, that is 100.00 [dollars/rub/etc]
PricePortionAmount=10000

[Send]
;; Url link to [short] video file (for example, http://sample.com/video.mp4)
videourl=
;; Url for setWebhook test
url=
;; Video filename for sendVideoBFileName
VideoFile=
;; Photo filename for sendPhotoByFileName
PhotoFile=
;; JSON array of InputMedia objects for sendMediaGroup
JSONMediaGroup=

;; Proxy support is implemented only for the synapse HTTP Client broker. Not yet implemented in the native FPHTTPClient.
;; You can specify HTTP proxy via Host/Port/UserName/Password name-value strings or via the Uri.
[Proxy]
Host=
Port=
Username=
Password=
Uri=
;;Uri=username:password@host:port
```
In order to test receiving updates via longpolling, send a message or other \[action\] to the bot just before testing (procedure `TTestReceiveLongPolling.ReceiveUpdate`).

In order to test payments wiring, run sendInvoice test. Test the payment via telegram than run the ReceivePreCheckOutQuery (You must run the test during 10 seconds after the payment test!).
The program will send answerPreCheckOutQuery as soon as it receives PreCheckOutQuery update from telegram API.
At the end of the wiring the telegram API will send a successfulpayment update, the reception of which you can also run using ReceiveSuccessfulPayment test

## Running

Build and run the console test runner (the recommended way):

    lazbuild --build-all console.lpi
    ./console --all --format=plain

The `console_synapse`, `gui` and `gui_synapse` projects contain the same tests
with the synapse HTTP broker or the GUI runner correspondingly.

Note for Windows machines with a non-UTF8 system codepage: on such systems
fpjson re-encodes non-ASCII strings (see
[issue #4](https://github.com/Al-Muhandis/fp-telegram/issues/4)); the library
supports the `-dJsonNoUTF8` compiler define as a workaround. The unit tests
parse JSON with the equivalent parser options, so they pass on every system
without the define.
