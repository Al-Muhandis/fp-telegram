unit testsendertypes;

{
  Unit tests for the request-building JSON wrapper classes of tgsendertypes:
  keyboards and markups, bot commands, labeled prices, input media,
  inline query results and so on. No network activity.

  The JSON assertions re-parse the produced JSON instead of comparing
  strings, so they do not depend on the JSON formatting of the used FPC version.
}

{$mode objfpc}{$H+}
{$codepage UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fpjson, tgtypes, tgsendertypes;

type

  { TTestMarkupCompletion }
  { Coverage of the previously missing markup fields: web apps, login urls,
    copy text, pay and disabled buttons, poll and user/chat requests }

  TTestMarkupCompletion = class(TTestCase)
  protected
    function ParseObject(const AJSON: String): TJSONObject;
  published
    procedure ReplyKeyboardIsPersistent;
    procedure InlineMarkupForceReply;
    procedure InlineButtonCopyText;
    procedure InlineButtonPay;
    procedure InlineButtonDisabled;
    procedure InlineButtonWebApp;
    procedure InlineButtonLoginUrl;
    procedure InlineButtonSwitchInlineQueryChosenChat;
    procedure KeyboardButtonRequestPoll;
    procedure KeyboardButtonRequestUsers;
    procedure KeyboardButtonRequestChat;
  end;

  { TTestRichMessages }
  { Rich messages of the Bot API 10.1+ }

  TTestRichMessages = class(TTestCase)
  protected
    function ParseObject(const AJSON: String): TJSONObject;
  published
    procedure InputRichMessageMarkdown;
    procedure InputRichMessageHTML;
    procedure InputRichMessageBlocks;
    procedure InputRichMessageFlags;
    procedure RichMessageButtonFactories;
    procedure RichMessageButtonProperties;
  end;

  { TTestKeyboards }

  TTestKeyboards = class(TTestCase)
  protected
    function ParseObject(const AJSON: String): TJSONObject;
  published
    procedure InlineKeyboardJSON;
    procedure InlineKeyboardAddButtonMaxColsInRow;
    procedure InlineButtonStyles;
    procedure InlineButtonOptionalParamsAreExclusive;
    procedure ReplyKeyboardJSON;
    procedure ReplyKeyboardButtonProperties;
    procedure RemoveKeyboardMarkup;
    procedure ForceReplyMarkup;
    procedure InputFieldPlaceholder;
    procedure ReplyMarkupCreateFromString;
  end;

  { TTestRequestTypes }

  TTestRequestTypes = class(TTestCase)
  protected
    function ParseObject(const AJSON: String): TJSONObject;
  published
    procedure BotCommandsJSON;
    procedure BotCommandScopeTypes;
    procedure LabeledPriceArrayJSON;
    procedure InputMediaDefaults;
    procedure InputMediaVideoProperties;
    procedure InputMediaArray;
    procedure InputMessageContentJSON;
    procedure InlineQueryResultJSON;
    procedure InlineQueryResultMpeg4WidthAndHeight;
    procedure ParseModeConversion;
    procedure MediaTypeConversion;
  end;

implementation

uses
  jsonparser
  ;

{ helpers }

function TTestKeyboards.ParseObject(const AJSON: String): TJSONObject;
begin
  Result:=GetJSON(AJSON) as TJSONObject;
end;

function TTestRequestTypes.ParseObject(const AJSON: String): TJSONObject;
begin
  Result:=GetJSON(AJSON) as TJSONObject;
end;

{ TTestKeyboards }

procedure TTestKeyboards.InlineKeyboardJSON;
var
  lMarkup: TReplyMarkup;
  lInline: TInlineKeyboard;
  lJSON: TJSONObject;
  lRow: TJSONArray;
  lButton: TJSONObject;
  lUrlButton: TInlineKeyboardButton;
begin
  lMarkup:=TReplyMarkup.Create;
  try
    lInline:=lMarkup.CreateInlineKeyBoard;
    lInline.Add.AddButtons(['Button 1', 'Callback data 1', 'Button 2', 'Callback data 2']);
    lUrlButton:=TInlineKeyboardButton.Create('Url button');
    lUrlButton.url:='http://example.com';
    lInline.AddButton(lUrlButton); // appended to the last row
    lInline.Add.AddButtonInline('Inline button', 'query');
    lJSON:=ParseObject(lMarkup.AsJSON);
    try
      AssertTrue('inline_keyboard present', lJSON.Find('inline_keyboard', jtArray)<>nil);
      AssertFalse('no reply keyboard in an inline markup',
        lJSON.Find('keyboard', jtArray)<>nil);
      AssertEquals(2, lJSON.Arrays['inline_keyboard'].Count);
      lRow:=lJSON.Arrays['inline_keyboard'].Arrays[0];
      AssertEquals(3, lRow.Count); // AddButton appends the button to the last row
      lButton:=lRow.Objects[0];
      AssertEquals('Button 1', lButton.Strings['text']);
      AssertEquals('Callback data 1', lButton.Strings['callback_data']);
      AssertEquals('Button 2', lRow.Objects[1].Strings['text']);
      AssertEquals('Url button', lRow.Objects[2].Strings['text']);
      AssertEquals('http://example.com', lRow.Objects[2].Strings['url']);
      lRow:=lJSON.Arrays['inline_keyboard'].Arrays[1];
      AssertEquals(1, lRow.Count);
      AssertEquals('Inline button', lRow.Objects[0].Strings['text']);
      AssertEquals('query', lRow.Objects[0].Strings['switch_inline_query']);
    finally
      lJSON.Free;
    end;
  finally
    lMarkup.Free;
  end;
end;

procedure TTestKeyboards.InlineKeyboardAddButtonMaxColsInRow;
var
  lMarkup: TReplyMarkup;
  lInline: TInlineKeyboard;
begin
  lMarkup:=TReplyMarkup.Create;
  try
    lInline:=lMarkup.CreateInlineKeyBoard;
    lInline.AddButton('B1', 'c1', 2);
    lInline.AddButton('B2', 'c2', 2);
    lInline.AddButton('B3', 'c3', 2); // must start a new row
    AssertEquals(2, lInline.Count);
    AssertEquals(2, lInline.Arrays[0].Count);
    AssertEquals(1, lInline.Arrays[1].Count);
    AssertEquals('B3', (lInline.Arrays[1].Items[0] as TInlineKeyboardButton).text);
  finally
    lMarkup.Free;
  end;
end;

procedure TTestKeyboards.InlineButtonStyles;
var
  aReplyMarkup: TReplyMarkup;
  aReplyButtons: TKeyboardButtons;
  aInlineButtons: TInlineKeyboardButtons;
  aReplyButton: TKeyboardButton;
  aInlineButton: TInlineKeyboardButton;
begin
  aReplyMarkup:=TReplyMarkup.Create;
  try
    aReplyButtons:=aReplyMarkup.CreateReplyKeyboard.Add;
    aReplyButton:=TKeyboardButton.Create('Reply button');
    aReplyButton.Style:='primary';
    aReplyButtons.Add(aReplyButton);

    aInlineButtons:=aReplyMarkup.CreateInlineKeyBoard.Add;
    aInlineButton:=TInlineKeyboardButton.Create('Inline button');
    aInlineButton.Callback_Data:='cb';
    aInlineButton.Style:='secondary';
    aInlineButtons.Add(aInlineButton);

    AssertEquals('primary', aReplyButton.Style);
    AssertEquals('secondary', aInlineButton.Style);
    AssertTrue('Reply keyboard JSON should contain style', Pos('"style"', aReplyMarkup.AsJSON)>0);
    AssertTrue('Inline keyboard JSON should contain style', Pos('"style"', aReplyMarkup.AsJSON)>0);
  finally
    aReplyMarkup.Free;
  end;
end;

procedure TTestKeyboards.InlineButtonOptionalParamsAreExclusive;
var
  lButton: TInlineKeyboardButton;
begin
  lButton:=TInlineKeyboardButton.Create('Text');
  try
    lButton.callback_data:='cb';
    // an inline keyboard button must have exactly one of the optional action fields:
    // assigning url after callback_data must not replace it
    lButton.url:='http://example.com';
    AssertEquals('cb', lButton.callback_data);
    AssertEquals(EmptyStr, lButton.url);
    // re-assigning the same field is allowed
    lButton.callback_data:='cb2';
    AssertEquals('cb2', lButton.callback_data);
  finally
    lButton.Free;
  end;
end;

procedure TTestKeyboards.ReplyKeyboardJSON;
var
  lMarkup: TReplyMarkup;
  lButtons: TKeyboardButtons;
  lJSON: TJSONObject;
  lRow: TJSONArray;
begin
  lMarkup:=TReplyMarkup.Create;
  try
    lButtons:=lMarkup.CreateReplyKeyboard.Add;
    lButtons.AddButton('One');
    lButtons.AddButton('Two');
    lMarkup.ResizeKeyboard:=True;
    lMarkup.OneTimeKeyboard:=True;
    lJSON:=ParseObject(lMarkup.AsJSON);
    try
      AssertTrue('keyboard present', lJSON.Find('keyboard', jtArray)<>nil);
      AssertEquals(1, lJSON.Arrays['keyboard'].Count);
      lRow:=lJSON.Arrays['keyboard'].Arrays[0];
      AssertEquals(2, lRow.Count);
      AssertEquals('One', lRow.Objects[0].Strings['text']);
      AssertEquals('Two', lRow.Objects[1].Strings['text']);
      AssertTrue('resize_keyboard', lJSON.Booleans['resize_keyboard']);
      AssertTrue('one_time_keyboard', lJSON.Booleans['one_time_keyboard']);
    finally
      lJSON.Free;
    end;
  finally
    lMarkup.Free;
  end;
end;

procedure TTestKeyboards.ReplyKeyboardButtonProperties;
var
  lMarkup: TReplyMarkup;
  lButtons: TKeyboardButtons;
  lJSON: TJSONObject;
  lRow: TJSONArray;
begin
  lMarkup:=TReplyMarkup.Create;
  try
    lButtons:=lMarkup.CreateReplyKeyboard.Add;
    lButtons.AddButton('Send location');
    lButtons.Buttons[0].RequestLocation:=True;
    lButtons.AddButton('Send contact');
    lButtons.Buttons[1].RequestContact:=True;
    AssertTrue(lButtons.Buttons[0].RequestLocation);
    AssertFalse(lButtons.Buttons[0].RequestContact);
    AssertTrue(lButtons.Buttons[1].RequestContact);
    lJSON:=ParseObject(lMarkup.AsJSON);
    try
      lRow:=lJSON.Arrays['keyboard'].Arrays[0];
      AssertTrue('request_location', lRow.Objects[0].Booleans['request_location']);
      AssertTrue('request_contact', lRow.Objects[1].Booleans['request_contact']);
    finally
      lJSON.Free;
    end;
  finally
    lMarkup.Free;
  end;
end;

procedure TTestKeyboards.RemoveKeyboardMarkup;
var
  lMarkup: TReplyMarkup;
  lJSON: TJSONObject;
begin
  lMarkup:=TReplyMarkup.Create;
  try
    lMarkup.RemoveKeyboard:=True;
    AssertTrue(lMarkup.RemoveKeyboard);
    lJSON:=ParseObject(lMarkup.AsJSON);
    try
      AssertTrue('remove_keyboard', lJSON.Booleans['remove_keyboard']);
    finally
      lJSON.Free;
    end;
    lMarkup.RemoveKeyboard:=False;
    AssertFalse(lMarkup.RemoveKeyboard);
    lJSON:=ParseObject(lMarkup.AsJSON);
    try
      AssertEquals('Markup must be empty', 0, lJSON.Count);
    finally
      lJSON.Free;
    end;
  finally
    lMarkup.Free;
  end;
end;

procedure TTestKeyboards.ForceReplyMarkup;
var
  lMarkup: TReplyMarkup;
  lJSON: TJSONObject;
begin
  lMarkup:=TReplyMarkup.Create;
  try
    lMarkup.Selective:=True; // selective implies force_reply
    AssertTrue(lMarkup.ForceReply);
    AssertTrue(lMarkup.Selective);
    lMarkup.ForceReply:=False; // clears both fields
    AssertFalse(lMarkup.ForceReply);
    AssertFalse(lMarkup.Selective);
    lMarkup.ForceReply:=True;
    lJSON:=ParseObject(lMarkup.AsJSON);
    try
      AssertTrue('force_reply', lJSON.Booleans['force_reply']);
    finally
      lJSON.Free;
    end;
  finally
    lMarkup.Free;
  end;
end;

procedure TTestKeyboards.InputFieldPlaceholder;
var
  lMarkup: TReplyMarkup;
begin
  lMarkup:=TReplyMarkup.Create;
  try
    lMarkup.InputFieldPlaceholder:='Type here...';
    AssertEquals('Type here...', lMarkup.InputFieldPlaceholder);
    AssertTrue('input_field_placeholder in JSON',
      Pos('input_field_placeholder', lMarkup.AsJSON)>0);
  finally
    lMarkup.Free;
  end;
end;

procedure TTestKeyboards.ReplyMarkupCreateFromString;
var
  lMarkup: TReplyMarkup;
begin
  lMarkup:=TReplyMarkup.CreateFromString('{"inline_keyboard":[[{"text":"Go","url":"http://x"}]]}');
  try
    AssertEquals(1, lMarkup.InlineKeyBoard.Count);
    AssertEquals(1, lMarkup.InlineKeyBoard.Arrays[0].Count);
    AssertEquals('Go', (lMarkup.InlineKeyBoard.Arrays[0].Items[0] as TInlineKeyboardButton).text);
  finally
    lMarkup.Free;
  end;
end;

{ TTestRequestTypes }

procedure TTestRequestTypes.BotCommandsJSON;
var
  lCommands: TBotCommandArray;
  lJSON: TJSONArray;
begin
  lCommands:=TBotCommandArray.Create;
  try
    lCommands.AddCommands(['start', 'Start command', 'help', 'Help command']);
    AssertEquals(2, lCommands.Count);
    lJSON:=GetJSON(lCommands.AsJSON) as TJSONArray;
    try
      AssertEquals('start', lJSON.Objects[0].Strings['command']);
      AssertEquals('Start command', lJSON.Objects[0].Strings['description']);
      AssertEquals('help', lJSON.Objects[1].Strings['command']);
      AssertEquals('Help command', lJSON.Objects[1].Strings['description']);
    finally
      lJSON.Free;
    end;
  finally
    lCommands.Free;
  end;
end;

procedure TTestRequestTypes.BotCommandScopeTypes;
var
  lScope: TBotCommandScope;
  lJSON: TJSONObject;
const
  TypeStrings: array[TCommandScopeType] of String = ('default', 'all_private_chats',
    'all_group_chats', 'all_chat_administrators', 'chat', 'chat_administrators', 'chat_member');
var
  lType: TCommandScopeType;
begin
  lScope:=TBotCommandScope.Create;
  try
    for lType:=Low(TCommandScopeType) to High(TCommandScopeType) do
    begin
      lScope.ScopeType:=lType;
      AssertEquals(Ord(lType), Ord(lScope.ScopeType));
      lJSON:=ParseObject(lScope.AsJSON);
      try
        AssertEquals(TypeStrings[lType], lJSON.Strings['type']);
      finally
        lJSON.Free;
      end;
    end;
  finally
    lScope.Free;
  end;
end;

procedure TTestRequestTypes.LabeledPriceArrayJSON;
var
  lPrices: TLabeledPriceArray;
  lJSON: TJSONArray;
begin
  lPrices:=TLabeledPriceArray.Create('РУБ', 10000);
  try
    AssertEquals(1, lPrices.Count);
    AssertEquals('РУБ', (lPrices[0] as TLabeledPrice).PortionLabel);
    AssertEquals(10000, (lPrices[0] as TLabeledPrice).PortionAmount);
    lJSON:=GetJSON(lPrices.AsJSON) as TJSONArray;
    try
      AssertEquals('РУБ', lJSON.Objects[0].Strings['label']);
      AssertEquals(10000, lJSON.Objects[0].Integers['amount']);
    finally
      lJSON.Free;
    end;
  finally
    lPrices.Free;
  end;
end;

procedure TTestRequestTypes.InputMediaDefaults;
var
  lMedia: TInputMediaPhoto;
  lJSON: TJSONObject;
begin
  lMedia:=TInputMediaPhoto.Create;
  try
    lMedia.Media:='file1.png';
    lMedia.Caption:='cap';
    AssertEquals(Ord(mtPhoto), Ord(lMedia.MediaType));
    AssertEquals(Ord(pmDefault), Ord(lMedia.ParseMode));
    lJSON:=ParseObject(lMedia.AsJSON);
    try
      AssertEquals('photo', lJSON.Strings['type']);
      AssertEquals('file1.png', lJSON.Strings['media']);
      AssertEquals('cap', lJSON.Strings['caption']);
      AssertTrue('no parse_mode by default', lJSON.Find('parse_mode')=nil);
    finally
      lJSON.Free;
    end;
  finally
    lMedia.Free;
  end;
end;

procedure TTestRequestTypes.InputMediaVideoProperties;
var
  lMedia: TInputMediaVideo;
  lJSON: TJSONObject;
begin
  lMedia:=TInputMediaVideo.Create;
  try
    AssertEquals(Ord(mtVideo), Ord(lMedia.MediaType));
    lMedia.Media:='attach://file0';
    lMedia.Width:=640;
    lMedia.Height:=480;
    lMedia.Duration:=12;
    lMedia.SupportsStreaming:=True;
    lJSON:=ParseObject(lMedia.AsJSON);
    try
      AssertEquals('video', lJSON.Strings['type']);
      AssertEquals('attach://file0', lJSON.Strings['media']);
      AssertEquals(640, lJSON.Integers['width']);
      AssertEquals(480, lJSON.Integers['height']);
      AssertEquals(12, lJSON.Integers['duration']);
      AssertTrue('supports_streaming', lJSON.Booleans['supports_streaming']);
    finally
      lJSON.Free;
    end;
  finally
    lMedia.Free;
  end;
end;

procedure TTestRequestTypes.InputMediaArray;
var
  lMedias: TInputMediaArray;
begin
  lMedias:=TInputMediaArray.Create;
  try
    AssertEquals(0, lMedias.AddPhoto('p.png'));
    AssertEquals(1, lMedias.AddVideo('v.mp4'));
    AssertEquals(2, lMedias.Count);
    AssertEquals(Ord(mtPhoto), Ord((lMedias.Objects[0] as TInputMedia).MediaType));
    AssertEquals(Ord(mtVideo), Ord((lMedias.Objects[1] as TInputMedia).MediaType));
    AssertEquals('p.png', (lMedias.Objects[0] as TInputMedia).Media);
  finally
    lMedias.Free;
  end;
end;

procedure TTestRequestTypes.InputMessageContentJSON;
var
  lContent: TInputMessageContent;
  lJSON: TJSONObject;
begin
  lContent:=TInputMessageContent.Create('the text');
  try
    AssertEquals('the text', lContent.MessageText);
    AssertEquals(Ord(pmDefault), Ord(lContent.ParseMode));
    lJSON:=ParseObject(lContent.AsJSON);
    try
      AssertEquals('the text', lJSON.Strings['message_text']);
      AssertTrue('no parse_mode by default', lJSON.Find('parse_mode')=nil);
    finally
      lJSON.Free;
    end;
  finally
    lContent.Free;
  end;
  lContent:=TInputMessageContent.Create('the text', pmMarkdownV2);
  try
    lJSON:=ParseObject(lContent.AsJSON);
    try
      AssertEquals('MarkdownV2', lJSON.Strings['parse_mode']);
    finally
      lJSON.Free;
    end;
  finally
    lContent.Free;
  end;
end;

procedure TTestRequestTypes.InlineQueryResultJSON;
var
  lResults: TInlineQueryResultArray;
  lResult: TInlineQueryResult;
  lJSON: TJSONArray;
begin
  lResults:=TInlineQueryResultArray.Create;
  try
    lResult:=lResults.Add;
    lResult.IQRType:=qrtArticle;
    lResult.ID:='r1';
    lResult.Title:='Title';
    lResult.Description:='Desc';
    lResult.InputMessageContent:=TInputMessageContent.Create('msg');
    AssertEquals(1, lResults.Count);
    AssertEquals(Ord(qrtArticle), Ord(lResult.IQRType));
    lJSON:=GetJSON(lResults.AsJSON) as TJSONArray;
    try
      AssertEquals('article', lJSON.Objects[0].Strings['type']);
      AssertEquals('r1', lJSON.Objects[0].Strings['id']);
      AssertEquals('Title', lJSON.Objects[0].Strings['title']);
      AssertEquals('Desc', lJSON.Objects[0].Strings['description']);
      AssertEquals('msg', lJSON.Objects[0].Objects['input_message_content'].Strings['message_text']);
    finally
      lJSON.Free;
    end;
  finally
    lResults.Free;
  end;
end;

procedure TTestRequestTypes.InlineQueryResultMpeg4WidthAndHeight;
var
  lResult: TInlineQueryResult;
  lJSON: TJSONObject;
begin
  lResult:=TInlineQueryResult.Create;
  try
    lResult.Mpeg4Width:=320;
    lResult.Mpeg4Height:=240;
    AssertEquals(320, lResult.Mpeg4Width);
    AssertEquals(240, lResult.Mpeg4Height);
    lJSON:=ParseObject(lResult.AsJSON);
    try
      // regression: Mpeg4Width used to write into the mpeg4_height key
      AssertEquals(320, lJSON.Integers['mpeg4_width']);
      AssertEquals(240, lJSON.Integers['mpeg4_height']);
    finally
      lJSON.Free;
    end;
  finally
    lResult.Free;
  end;
end;

procedure TTestRequestTypes.ParseModeConversion;
begin
  AssertEquals(Ord(pmDefault), Ord(StringToParseMode('')));
  AssertEquals(Ord(pmMarkdown), Ord(StringToParseMode('Markdown')));
  AssertEquals(Ord(pmHTML), Ord(StringToParseMode('HTML')));
  AssertEquals(Ord(pmMarkdownV2), Ord(StringToParseMode('MarkdownV2')));
  AssertEquals(Ord(pmDefault), Ord(StringToParseMode('unknown')));
end;

procedure TTestRequestTypes.MediaTypeConversion;
begin
  AssertEquals(Ord(mtPhoto), Ord(StringToMediaType('photo')));
  AssertEquals(Ord(mtVideo), Ord(StringToMediaType('video')));
  AssertEquals(Ord(mtUnknown), Ord(StringToMediaType('audio')));
  AssertEquals(Ord(mtUnknown), Ord(StringToMediaType('')));
end;


{ TTestMarkupCompletion }

function TTestMarkupCompletion.ParseObject(const AJSON: String): TJSONObject;
begin
  Result:=GetJSON(AJSON) as TJSONObject;
end;

procedure TTestMarkupCompletion.ReplyKeyboardIsPersistent;
var
  lMarkup: TReplyMarkup;
  lJSON: TJSONObject;
begin
  lMarkup:=TReplyMarkup.Create;
  try
    lMarkup.CreateReplyKeyboard.Add.AddButton('Btn');
    lMarkup.IsPersistent:=True;
    AssertTrue(lMarkup.IsPersistent);
    lJSON:=ParseObject(lMarkup.AsJSON);
    try
      AssertTrue('is_persistent', lJSON.Booleans['is_persistent']);
    finally
      lJSON.Free;
    end;
  finally
    lMarkup.Free;
  end;
end;

procedure TTestMarkupCompletion.InlineMarkupForceReply;
var
  lMarkup: TReplyMarkup;
  lJSON: TJSONObject;
begin
  lMarkup:=TReplyMarkup.Create;
  try
    lMarkup.CreateInlineKeyBoard.AddButton('B', 'cb');
    lMarkup.ForceReply:=True; // force_reply is allowed in InlineKeyboardMarkup since Bot API 10.3
    lJSON:=ParseObject(lMarkup.AsJSON);
    try
      AssertTrue('inline keyboard present', lJSON.Find('inline_keyboard', jtArray)<>nil);
      AssertTrue('force_reply', lJSON.Booleans['force_reply']);
    finally
      lJSON.Free;
    end;
  finally
    lMarkup.Free;
  end;
end;

procedure TTestMarkupCompletion.InlineButtonCopyText;
var
  lButton: TInlineKeyboardButton;
  lJSON: TJSONObject;
begin
  lButton:=TInlineKeyboardButton.Create('Copy me');
  try
    lButton.copy_text:=TCopyTextButton.Create('text to copy');
    AssertEquals('text to copy', lButton.copy_text.Text);
    // another optional action must not replace copy_text
    lButton.url:='http://example.com';
    AssertEquals(EmptyStr, lButton.url);
    lJSON:=ParseObject(lButton.AsJSON);
    try
      AssertEquals('text to copy', lJSON.Objects['copy_text'].Strings['text']);
      AssertTrue('no url', lJSON.Find('url')=nil);
    finally
      lJSON.Free;
    end;
  finally
    lButton.Free;
  end;
end;

procedure TTestMarkupCompletion.InlineButtonPay;
var
  lButton: TInlineKeyboardButton;
  lJSON: TJSONObject;
begin
  lButton:=TInlineKeyboardButton.Create('Pay with Stars');
  try
    lButton.pay:=True;
    AssertTrue(lButton.pay);
    // callback_data must not replace pay
    lButton.callback_data:='cb';
    AssertEquals(EmptyStr, lButton.callback_data);
    lJSON:=ParseObject(lButton.AsJSON);
    try
      AssertTrue('pay', lJSON.Booleans['pay']);
      AssertTrue('no callback_data', lJSON.Find('callback_data')=nil);
    finally
      lJSON.Free;
    end;
    lButton.pay:=False;
    AssertFalse(lButton.pay);
    lJSON:=ParseObject(lButton.AsJSON);
    try
      AssertTrue('pay removed', lJSON.Find('pay')=nil);
    finally
      lJSON.Free;
    end;
  finally
    lButton.Free;
  end;
end;

procedure TTestMarkupCompletion.InlineButtonDisabled;
var
  lButton: TInlineKeyboardButton;
  lJSON: TJSONObject;
begin
  lButton:=TInlineKeyboardButton.Create('N/A');
  try
    lButton.disabled:=True;
    AssertTrue(lButton.disabled);
    lJSON:=ParseObject(lButton.AsJSON);
    try
      AssertNotNull('disabled object present', lJSON.Find('disabled', jtObject));
    finally
      lJSON.Free;
    end;
    lButton.disabled:=False;
    AssertFalse(lButton.disabled);
    lJSON:=ParseObject(lButton.AsJSON);
    try
      AssertTrue('disabled removed', lJSON.Find('disabled')=nil);
    finally
      lJSON.Free;
    end;
  finally
    lButton.Free;
  end;
end;

procedure TTestMarkupCompletion.InlineButtonWebApp;
var
  lButton: TInlineKeyboardButton;
  lJSON: TJSONObject;
begin
  lButton:=TInlineKeyboardButton.Create('Open app');
  try
    lButton.web_app:=TWebAppInfo.Create('https://example.com/app');
    lButton.IconCustomEmojiID:='emoji123';
    AssertEquals('https://example.com/app', lButton.web_app.Url);
    AssertEquals('emoji123', lButton.IconCustomEmojiID);
    lJSON:=ParseObject(lButton.AsJSON);
    try
      AssertEquals('https://example.com/app', lJSON.Objects['web_app'].Strings['url']);
      AssertEquals('emoji123', lJSON.Strings['icon_custom_emoji_id']);
    finally
      lJSON.Free;
    end;
  finally
    lButton.Free;
  end;
end;

procedure TTestMarkupCompletion.InlineButtonLoginUrl;
var
  lButton: TInlineKeyboardButton;
  lLogin: TLoginUrl;
  lJSON: TJSONObject;
begin
  lButton:=TInlineKeyboardButton.Create('Login');
  try
    lLogin:=TLoginUrl.Create('https://example.com/auth');
    lLogin.ForwardText:='Continue';
    lLogin.RequestWriteAccess:=True;
    lButton.login_url:=lLogin;
    lJSON:=ParseObject(lButton.AsJSON);
    try
      AssertEquals('https://example.com/auth', lJSON.Objects['login_url'].Strings['url']);
      AssertEquals('Continue', lJSON.Objects['login_url'].Strings['forward_text']);
      AssertTrue('request_write_access', lJSON.Objects['login_url'].Booleans['request_write_access']);
    finally
      lJSON.Free;
    end;
  finally
    lButton.Free;
  end;
end;

procedure TTestMarkupCompletion.InlineButtonSwitchInlineQueryChosenChat;
var
  lButton: TInlineKeyboardButton;
  lSwitch: TSwitchInlineQueryChosenChat;
  lJSON: TJSONObject;
begin
  lButton:=TInlineKeyboardButton.Create('Share');
  try
    lSwitch:=TSwitchInlineQueryChosenChat.Create;
    lSwitch.Query:='gift';
    lSwitch.AllowUserChats:=True;
    lSwitch.AllowGroupChats:=True;
    lButton.switch_inline_query_chosen_chat:=lSwitch;
    lJSON:=ParseObject(lButton.AsJSON);
    try
      AssertEquals('gift', lJSON.Objects['switch_inline_query_chosen_chat'].Strings['query']);
      AssertTrue('allow_user_chats', lJSON.Objects['switch_inline_query_chosen_chat'].Booleans['allow_user_chats']);
      AssertTrue('allow_group_chats', lJSON.Objects['switch_inline_query_chosen_chat'].Booleans['allow_group_chats']);
      AssertFalse('allow_bot_chats', lJSON.Objects['switch_inline_query_chosen_chat'].Get('allow_bot_chats', False));
    finally
      lJSON.Free;
    end;
  finally
    lButton.Free;
  end;
end;

procedure TTestMarkupCompletion.KeyboardButtonRequestPoll;
var
  lMarkup: TReplyMarkup;
  lButtons: TKeyboardButtons;
  lJSON: TJSONObject;
begin
  lMarkup:=TReplyMarkup.Create;
  try
    lButtons:=lMarkup.CreateReplyKeyboard.Add;
    lButtons.AddButton('Create poll');
    lButtons.Buttons[0].RequestPoll:=TKeyboardButtonPollType.Create('quiz');
    lJSON:=ParseObject(lMarkup.AsJSON);
    try
      AssertEquals('quiz', lJSON.Arrays['keyboard'].Arrays[0].Objects[0].Objects['request_poll'].Strings['type']);
    finally
      lJSON.Free;
    end;
    // an empty poll type must not be sent
    lButtons.Buttons[0].RequestPoll:=TKeyboardButtonPollType.Create('');
    lJSON:=ParseObject(lMarkup.AsJSON);
    try
      AssertTrue('empty type omitted',
        lJSON.Arrays['keyboard'].Arrays[0].Objects[0].Objects['request_poll'].Find('type')=nil);
    finally
      lJSON.Free;
    end;
  finally
    lMarkup.Free;
  end;
end;

procedure TTestMarkupCompletion.KeyboardButtonRequestUsers;
var
  lMarkup: TReplyMarkup;
  lButtons: TKeyboardButtons;
  lRequest: TKeyboardButtonRequestUsers;
  lJSON: TJSONObject;
begin
  lMarkup:=TReplyMarkup.Create;
  lRequest:=TKeyboardButtonRequestUsers.Create(77);
  lRequest.MaxQuantity:=5;
  lRequest.RequestName:=True;
  try
    lButtons:=lMarkup.CreateReplyKeyboard.Add;
    lButtons.AddButton('Share users');
    lButtons.Buttons[0].RequestUsers:=lRequest;
    lJSON:=ParseObject(lMarkup.AsJSON);
    try
      AssertEquals(77, lJSON.Arrays['keyboard'].Arrays[0].Objects[0].Objects['request_users'].Integers['request_id']);
      AssertEquals(5, lJSON.Arrays['keyboard'].Arrays[0].Objects[0].Objects['request_users'].Integers['max_quantity']);
      AssertTrue('request_name', lJSON.Arrays['keyboard'].Arrays[0].Objects[0].Objects['request_users'].Booleans['request_name']);
    finally
      lJSON.Free;
    end;
  finally
    lMarkup.Free;
  end;
end;

procedure TTestMarkupCompletion.KeyboardButtonRequestChat;
var
  lMarkup: TReplyMarkup;
  lButtons: TKeyboardButtons;
  lRequest: TKeyboardButtonRequestChat;
  lJSON: TJSONObject;
begin
  lMarkup:=TReplyMarkup.Create;
  lRequest:=TKeyboardButtonRequestChat.Create(78, False);
  lRequest.ChatIsForum:=True;
  lRequest.BotIsMember:=True;
  lRequest.RequestTitle:=True;
  try
    lButtons:=lMarkup.CreateReplyKeyboard.Add;
    lButtons.AddButton('Share chat');
    lButtons.Buttons[0].RequestChat:=lRequest;
    lJSON:=ParseObject(lMarkup.AsJSON);
    try
      AssertEquals(78, lJSON.Arrays['keyboard'].Arrays[0].Objects[0].Objects['request_chat'].Integers['request_id']);
      AssertFalse('chat_is_channel', lJSON.Arrays['keyboard'].Arrays[0].Objects[0].Objects['request_chat'].Booleans['chat_is_channel']);
      AssertTrue('chat_is_forum', lJSON.Arrays['keyboard'].Arrays[0].Objects[0].Objects['request_chat'].Booleans['chat_is_forum']);
      AssertTrue('bot_is_member', lJSON.Arrays['keyboard'].Arrays[0].Objects[0].Objects['request_chat'].Booleans['bot_is_member']);
      AssertTrue('request_title', lJSON.Arrays['keyboard'].Arrays[0].Objects[0].Objects['request_chat'].Booleans['request_title']);
    finally
      lJSON.Free;
    end;
  finally
    lMarkup.Free;
  end;
end;

{ TTestRichMessages }

function TTestRichMessages.ParseObject(const AJSON: String): TJSONObject;
begin
  Result:=GetJSON(AJSON) as TJSONObject;
end;

procedure TTestRichMessages.InputRichMessageMarkdown;
var
  lRich: TInputRichMessage;
  lJSON: TJSONObject;
begin
  lRich:=TInputRichMessage.CreateFromMarkdown('# Heading' + LineEnding + 'Some *bold* text');
  try
    AssertEquals('# Heading' + LineEnding + 'Some *bold* text', lRich.Markdown);
    lJSON:=ParseObject(lRich.AsJSON);
    try
      AssertTrue('markdown present', lJSON.Find('markdown')<>nil);
      AssertTrue('no html', lJSON.Find('html')=nil);
    finally
      lJSON.Free;
    end;
  finally
    lRich.Free;
  end;
end;

procedure TTestRichMessages.InputRichMessageHTML;
var
  lRich: TInputRichMessage;
  lJSON: TJSONObject;
begin
  lRich:=TInputRichMessage.CreateFromHTML('<h1>Heading</h1>');
  try
    AssertEquals('<h1>Heading</h1>', lRich.HTML);
    lJSON:=ParseObject(lRich.AsJSON);
    try
      AssertEquals('<h1>Heading</h1>', lJSON.Strings['html']);
    finally
      lJSON.Free;
    end;
  finally
    lRich.Free;
  end;
end;

procedure TTestRichMessages.InputRichMessageBlocks;
var
  lRich: TInputRichMessage;
  lBlock: TInputRichBlockButtons;
  lJSON: TJSONObject;
begin
  lRich:=TInputRichMessage.Create;
  try
    lBlock:=lRich.AddButtonsBlock;
    lBlock.Buttons.AddButton('Site', 'https://example.com');
    lBlock.Buttons.AddCallbackButton('Press', 'cb1');
    lBlock.Align:='center';
    AssertEquals(1, lRich.Blocks.Count);
    lJSON:=ParseObject(lRich.AsJSON);
    try
      AssertEquals('buttons', lJSON.Arrays['blocks'].Objects[0].Strings['type']);
      AssertEquals('center', lJSON.Arrays['blocks'].Objects[0].Strings['align']);
      AssertEquals(2, lJSON.Arrays['blocks'].Objects[0].Arrays['buttons'].Count);
      AssertEquals('Site', lJSON.Arrays['blocks'].Objects[0].Arrays['buttons'].Objects[0].Strings['text']);
      AssertEquals('https://example.com', lJSON.Arrays['blocks'].Objects[0].Arrays['buttons'].Objects[0].Strings['url']);
      AssertEquals('cb1', lJSON.Arrays['blocks'].Objects[0].Arrays['buttons'].Objects[1].Strings['callback_data']);
    finally
      lJSON.Free;
    end;
  finally
    lRich.Free;
  end;
end;

procedure TTestRichMessages.InputRichMessageFlags;
var
  lRich: TInputRichMessage;
begin
  lRich:=TInputRichMessage.CreateFromMarkdown('text');
  try
    lRich.IsRTL:=True;
    lRich.SkipEntityDetection:=True;
    AssertTrue(lRich.IsRTL);
    AssertTrue(lRich.SkipEntityDetection);
  finally
    lRich.Free;
  end;
end;

procedure TTestRichMessages.RichMessageButtonFactories;
var
  lButtons: TRichMessageButtons;
begin
  lButtons:=TRichMessageButtons.Create;
  try
    lButtons.AddButton('Url btn', 'https://example.com');
    lButtons.AddCallbackButton('Callback btn', 'data');
    lButtons.AddCopyButton('Copy btn', 'copied text');
    AssertEquals(3, lButtons.Count);
    AssertEquals('Url btn', (lButtons.Objects[0] as TRichMessageButton).text);
    AssertEquals('https://example.com', (lButtons.Objects[0] as TRichMessageButton).url);
    AssertEquals('data', (lButtons.Objects[1] as TRichMessageButton).callback_data);
    AssertEquals('copied text', (lButtons.Objects[2] as TRichMessageButton).copy_text.Text);
  finally
    lButtons.Free;
  end;
end;

procedure TTestRichMessages.RichMessageButtonProperties;
var
  lButton: TRichMessageButton;
  lJSON: TJSONObject;
begin
  lButton:=TRichMessageButton.Create('Danger');
  try
    lButton.Style:='danger';
    lButton.disabled:=True;
    AssertEquals('danger', lButton.Style);
    AssertTrue(lButton.disabled);
    lJSON:=ParseObject(lButton.AsJSON);
    try
      AssertEquals('danger', lJSON.Strings['style']);
      AssertNotNull('disabled present', lJSON.Find('disabled', jtObject));
    finally
      lJSON.Free;
    end;
    lButton.disabled:=False;
    AssertFalse(lButton.disabled);
  finally
    lButton.Free;
  end;
end;

initialization
  RegisterTest(TTestKeyboards);
  RegisterTest(TTestMarkupCompletion);
  RegisterTest(TTestRichMessages);
  RegisterTest(TTestRequestTypes);

end.
