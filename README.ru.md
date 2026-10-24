# fp-telegram #

Библиотека для работы с API ботов в Telegram (FreePascal/Lazarus)

FreePascal-библиотека классов для работы с API телеграм-ботов. Вы уже можете использовать её в своих рабочих проектах. Если Вы хотите помочь в развитии проекта — присоединяйтесь!

Библиотека **не использует никаких сторонних библиотек**, кроме встроенных в FPC. Вы можете использовать её как самостоятельно, так и в составе других библиотек,
к примеру, как [плагин](https://github.com/Al-Muhandis/brook-telegram/) к Brook-framework/Brook4FreePascal.

**Поддерживаемая версия Bot API: 10.3** (24 августа 2026), включая Rich Messages (10.1–10.3).

# Возможности

* Получение апдейтов: long polling (`getUpdates`/`getUpdatesEx`) и webhook; события на каждый тип апдейта (`OnReceiveMessage`, `OnReceiveCallbackQuery`, `OnReceiveMessageReaction`, business-апдейты и др.), обработчики команд (`CommandHandlers['/start']`), фильтры пользователей (`IsBanned`, `IsAdminUser`).
* Отправка: текст, фото, видео, аудио, голос, документы, анимации, опросы, локации, инвойсы, медиа-группы — по `file_id`, по URL, загрузкой файла и потоком.
* Полные reply/inline-клавиатуры: inline-клавиатуры, reply-клавиатуры (`is_persistent`, плейсхолдеры), кнопки Web App, login-ссылки, кнопки копирования текста, pay/disabled-кнопки, кнопки запроса опросов и пользователей/чатов, `switch_inline_query_chosen_chat`.
* Rich Messages (Bot API 10.1+): `sendRichMessage` (markdown, HTML или блоки), кнопки внутри rich-сообщений, редактирование через `editMessageTextRich`, приём `Message.RichMessage` с хелперами `PlainText`/`ExtractButtons`.
* Администрирование чатов и пользователей: бан/разбан, promote/restrict member, закрепление сообщений, пакетные удаление/пересылка/копирование.
* Профиль бота: команды, описание, краткое описание, имя, кнопка меню.
* Бизнес-подключения, `answerWebAppQuery`, `getUserProfilePhotos`, `getChat`/`getChatMember`/`getChatAdministrators`.
* Логирование: `Logger: TEventLog` + событие `OnLogMessage`, отладка всех запросов и ответов.
* Пакет `bot_ex`: готовый `TTelegramBot` со статистикой, обратной связью, deeplink-ами, i18n и системой плагинов.

# Требования

* FPC 3.2.2+ (3.0.4 всё ещё поддерживается с ограничениями); Lazarus 2.0+ для пакетов и designtime.
* Внешних зависимостей нет. HTTPS работает через встроенную в FPC поддержку OpenSSL (`tgfclhttpclientbroker`) или через [Synapse](https://github.com/geby/synapse) (`tgsynapsehttpclientbroker`, поддержка HTTP-прокси).

# Установка

* **Lazarus / OPM**: установите через Online Package Manager (поиск "FpTelegram") — поставятся run-time и design-time пакеты.
* **Вручную**: откройте и скомпилируйте `fptelegram.lpk` (run-time), при необходимости `fptgbot_ex.lpk` (расширенный бот) и `fptelegram_dt.lpk` (design-time).

# Быстрый старт

```pascal
uses tgsendertypes, tgfclhttpclientbroker; // брокер регистрирует HTTP-клиент

var
  Bot: TTelegramSender;
begin
  Bot := TTelegramSender.Create('<токен бота>');
  try
    Bot.OnReceiveMessage := @HandleMessage;
    if Bot.sendMessage(ChatID, 'Привет от fp-telegram!') then
      WriteLn(Bot.JSONResponse.AsJSON);
    // rich-сообщение с кнопкой (Bot API 10.1+)
    // Rich := TInputRichMessage.CreateFromMarkdown('# Заголовок' + LineEnding + 'текст');
    // Rich.AddButtonsBlock.Buttons.AddCallbackButton('Нажми', 'cb1');
    // Bot.sendRichMessage(ChatID, Rich);
  finally
    Bot.Free;
  end;
end;
```

Больше примеров — в папке `examples` и в [вики](https://github.com/Al-Muhandis/fp-telegram/wiki).

# DesignTime (компонент «времени разработки»)

Библиотека содержит два пакета: run-time (`fptelegram.lpk`) и design-time (`fptelegram_dt.lpk`). `fptelegram_dt.lpk` содержит компонент `DTLongPolBot`.
Это готовый longpolling-бот, который можно использовать для быстрой разработки телеграм-ботов.
О создании longpolling-бота — [здесь](https://github.com/Al-Muhandis/fp-telegram/wiki/How-to-step-by-step.-Creation-telegram-bot-in-Lazarus-(longpolling)).
Компонент работает в GUI- и не-GUI-приложениях, демонах и сервисах и
даже на веб-сервере (хотя в последнем случае предпочтительнее webhook для получения апдейтов.
О webhook-ботах — [здесь](https://github.com/Al-Muhandis/fp-telegram/wiki/How-to-step-by-step.-Creation-telegram-bot-in-Lazarus-(webhook))).

# Структура

| Юнит | Назначение |
|------|-----------|
| `tgsendertypes` | `TTelegramSender`: все методы API, JSON-обёртки для запросов (клавиатуры, медиа, rich-сообщения, команды) |
| `tgtypes` | приёмная сторона: JSON → дерево объектов `TTelegram*` (апдейты, сообщения, чаты, реакции, rich-сообщения) |
| `tgbasehttpclient` | абстракция HTTP-клиента; брокеры регистрируют себя через `RegisterClientClass` |
| `tgfclhttpclientbroker` / `tgsynapsehttpclientbroker` | реализации на FCL (`fphttpclient`) и на Synapse |
| `tgutils` | текстовые хелперы: экранирование Markdown, подписи, deeplink-и |
| `tgstatlog` | логгер статистики (ежедневные CSV-файлы) |
| `bot_ex` (`fptgbot_ex.lpk`) | `TTelegramBot`: статистика, обратная связь, deeplink-и, i18n, плагины |
| `designtime` (`fptelegram_dt.lpk`) | компонент `DTLongPolBot` |
| `test` | юнит- и интеграционные тесты (см. `test/readme.md`) |

HTTP-клиент можно подменить на уровне отправителя: `Bot.HTTPClientClass := TMyClient` — так тесты мокают сетевой слой.

# Тесты

В папке `test` два уровня:

* **Юнит-тесты** (запускаются всегда, без сети): построение запросов, парсинг JSON, клавиатуры, логика отправителя против мок-HTTP-клиента.
* **Интеграционные тесты** (только при настроенном `test/testtelegram.ini` с токеном бота): реальные запросы к Telegram API. Тесты, требующие участия человека, дополнительно включаются секцией `[Manual] Enable=1`.

```bash
cd test
lazbuild --build-all console.lpi
./console --all --format=plain     # или console.exe на Windows
```

CI собирает всё и запускает юнит-тесты на каждый push.

# Примеры в папке examples

Различные архитектуры использования библиотеки:
long polling и webhook,
однопоточные и многопоточные,
с использованием компонентов runtime и designtime — см. `examples/readme.md`.

# Участие в разработке (люди и AI-агенты)

Команды сборки/тестов, конвенции кода (включая правила концовок строк в репозитории) и рецепт добавления нового метода API — в [AGENTS.md](AGENTS.md).
