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

initialization
  RegisterTest(TTestKeyboards);
  RegisterTest(TTestRequestTypes);

end.
