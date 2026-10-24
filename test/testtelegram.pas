unit testtelegram;

{
  Integration tests: they perform real requests to the Telegram API server using
  the bot token and the chat ID from testtelegram.ini.
  These tests are registered only when testtelegram.ini is configured
  (see TTestTelegramClass.Configured), so CI and machines without a test bot
  run only the unit tests (see testtgtypes, testsendertypes and testsendermock units).
}

{$mode objfpc}{$H+}
{$codepage UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fpjson, tgsendertypes, testbase, tgtypes;

type

  { TTestSender }
  { Test sending messages. Object style }
  TTestSender= class(TTestTelegramClass)
  private
    FJSONMediaGroup: String;
    FPhotoFile: String;
    FPhotoUrl: String;
    FPrivateChatID: Int64;
    FUrl: String;
    FVideoFile: String;
    FVideoUrl: String;
  protected
    procedure SetUp; override;
  public
    { Private chat with the bot: some keyboards (request_location, request_contact)
      are allowed in private chats only }
    property PrivateChatID: Int64 read FPrivateChatID;
    property VideoUrl: String read FVideoUrl;
    property Url: String read FUrl;
    property VideoFile: String read FVideoFile;
    property PhotoUrl: String read FPhotoUrl;
    property PhotoFile: String read FPhotoFile;
    property jsonMediaGroup: String read FJSONMediaGroup;
  published
    procedure sendMessage;
    procedure InlineKeyboard;
    procedure sendVideo;
    procedure sendVideoByFileName;
    procedure sendVideoStream;
    procedure sendPhoto;
    procedure sendPhotoWithInlineKeyboardAndThenEdit;
    procedure sendPhotoByFileName;
    procedure sendMediaGroup;
    procedure sendMediaGroupByFileName;
    procedure SendPoll;
    procedure ChatMember;
    procedure getWebhookInfo;
    procedure setWebhook;
    procedure deleteWebhook; {$IF FPC_FULLVERSION > 30004}
    procedure testCodePage;{$ENDIF}
    procedure getMyCommands;
    procedure setMyCommands;
    procedure editMessageMediaStream;
    procedure getChatAdministators;
    procedure sendRichMessageMarkdown;
    procedure sendRichMessageWithButtonsAndEdit;
    procedure sendPersistentKeyboard;
    procedure sendInlineCopyTextButton;
    procedure sendChatActionTyping;
    procedure pinAndUnpinMessage;
    procedure getUserProfilePhotosTest;
    procedure editMessageCaptionTest;
  end;

  { TTestSenderManual }
  { Tests that need a human interaction or a private chat started with the bot:
    registered only when [Manual] Enable=1 is set in testtelegram.ini }

  TTestSenderManual = class(TTestSender)
  published
    { request_location/request_contact buttons are allowed in private chats only,
      so the bot must have a chat with the user: press Start in the bot's private chat }
    procedure SendReplyKeyboard;
  end;

  { TTestProxySender }

  TTestProxySender = class(TTestSender)
  private
    FProxyHost: String;
    FProxyPassword: String;
    FProxyPort: Word;
    FProxyUser: String;
  protected
    procedure SetUp; override;
  public
    property ProxyUser: String read FProxyUser write FProxyUser;
    property ProxyPassword: String read FProxyPassword write FProxyPassword;
    property ProxyHost: String read FProxyHost write FProxyHost;
    property ProxyPort: Word read FProxyPort write FProxyPort;
  end;

  { TTestSenderProcedure }
  { Test sending messages. Simple procedure style}
  TTestSenderProcedure=class(TTestTelegramBase)
  published
    procedure sendMessage;
  end;

  { TTestReceiveLongPollingBase }
  { Test receiving updates via longpolling from the test bot. Please send test messages to the bot
    immediately before running the test! }
  TTestReceiveLongPolling=class(TTestTelegramClass)
  private
    FReceived: Boolean;
    procedure BotReceiveUpdate({%H-}ASender: TObject; AnUpdate: TTelegramUpdateObj);
  protected
    procedure SetUp; override;
    property Received: Boolean read FReceived write FReceived;
  published
    procedure ReceiveUpdate;
  end;

  { TTestPayments }

  TTestPayments=class(TTestTelegramClass)
  private
    FCurrency: String;
    FPortionAmount: Integer;
    FPortionLabel: String;
    FProviderToken: String;
    FReceived: Boolean;
    procedure BotReceivePreCheckoutQuery({%H-}ASender: TObject;
      APreCheckoutQuery: TTelegramPreCheckOutQuery);
    procedure BotReceiveSuccessfulPayment({%H-}ASender: TObject;
      AMessage: TTelegramMessageObj);
  protected
    procedure SetUp; override;
  public
    property Currency: String read FCurrency write FCurrency; // 3-letter ISO 4217 currency code
    property ProviderToken: String read FProviderToken write FProviderToken; // Payments provider token
    property PortionLabel: String read FPortionLabel write FPortionLabel;  //  Price portion label
    property PortionAmount: Integer read FPortionAmount write FPortionAmount; // Price portion amount
    property Received: Boolean read FReceived write FReceived;
  published
    procedure sendInvoice; // test send invoice
    procedure ReceivePreCheckoutQuery; // test receiving test pre_checkout_query update (after invoice is sent!)
    procedure ReceiveSuccessfulPayment;
  end;

implementation

uses
  URIParser, jsonparser
  ;

const
  Msg='Test message sent from %s. Test procedure: %s';
  vd_cptn='Test video sent from %s. Test procedure: %s';
  pht_cptn='Test photo sent from %s. Test procedure: %s';
  Msg_md='Test message sent from %s. Test procedure: _%s_';

  DefaultMediaGroupURLs='[{ "type" : "photo", "media" : "https://picsum.photos/seed/tgA/800/600" },'+
    '{ "type" : "photo", "media" : "https://picsum.photos/seed/tgB/800/600" }]';

  s_Username='Username';
  s_Password='Password';
  s_Proxy='Proxy';
  s_Host='Host';
  s_Port='Port';
  s_Uri='Uri';

{ TTestProxySender }

procedure TTestProxySender.SetUp;
var
  AHost, AUsername, APassword: String;
  APort: Word;
  URI: TURI;
begin
  inherited SetUp;
  AHost:=    Conf.ReadString(s_Proxy,  s_Host,     EmptyStr);
  AUsername:=Conf.ReadString(s_Proxy,  s_Username, EmptyStr);
  APassword:=Conf.ReadString(s_Proxy,  s_Password, EmptyStr);
  APort:=    Conf.ReadInteger(s_Proxy, s_Port,     0);
  if AHost=EmptyStr then
  begin
    URI:=URIParser.ParseURI('https://'+Conf.ReadString(s_Proxy, s_Uri, EmptyStr));
    AHost:=URI.Host;
    APort:=URI.Port;
    AUsername:=URI.Username;
    APassword:=URI.Password;
  end;
  Bot.HTTPProxyHost:=AHost;
  Bot.HTTPProxyPort:=APort;
  Bot.HTTPProxyUser:=AUsername;
  Bot.HTTPProxyPassword:=APassword;
end;

{ TTestReceiveLongPolling }

procedure TTestReceiveLongPolling.BotReceiveUpdate(ASender: TObject;
  AnUpdate: TTelegramUpdateObj);
begin
  SaveJSONData(Bot.JSONResponse, '~responce.json');
  SaveString(AnUpdate.AsString, '~update.json');
  Received:=True;
end;

procedure TTestReceiveLongPolling.SetUp;
begin
  inherited SetUp;
  Bot.OnReceiveUpdate:=@BotReceiveUpdate;
  FReceived:=False;
end;

procedure TTestReceiveLongPolling.ReceiveUpdate;
begin
  Bot.getUpdates();
  if not Received then
    Fail('No updates were received. Send, for example, a message to the test bot')
  else
    Bot.getUpdatesEx(100, 1); //
end;

{ TTestPayments }

procedure TTestPayments.BotReceivePreCheckoutQuery(ASender: TObject;
  APreCheckoutQuery: TTelegramPreCheckOutQuery);
begin
  SaveJSONData(Bot.JSONResponse, '~responce.json');
  SaveString(APreCheckoutQuery.AsString, '~PreCheckoutQuery.json');
  Received:=True;
  Bot.answerPreCheckoutQuery(APreCheckoutQuery.ID, True);
  if Bot.LastErrorCode<>0 then
    Fail('Error from telegram API server. Error code: '+IntToStr(Bot.LastErrorCode)+
      '. Description: '+Bot.LastErrorDescription);
end;

procedure TTestPayments.BotReceiveSuccessfulPayment(ASender: TObject;
  AMessage: TTelegramMessageObj);
begin
  SaveJSONData(Bot.JSONResponse, '~responce.json');
  SaveString(AMessage.SuccessfulPayment.AsString, '~SuccessfulPayment.json');
  Received:=True;
end;

procedure TTestPayments.SetUp;
begin
  inherited SetUp;
  Bot.OnReceivePreCheckoutQuery:=@BotReceivePreCheckoutQuery;
  Bot.OnReceiveSuccessfulPayment:=@BotReceiveSuccessfulPayment;
  FProviderToken:=Conf.ReadString('Payment', 'ProviderToken', EmptyStr);
  FCurrency:=Conf.ReadString('Payment', 'Currency', EmptyStr);
  FPortionLabel:=Conf.ReadString('Payment', 'PricePortionLabel', EmptyStr);
  FPortionAmount:=Conf.ReadInteger('Payment', 'PricePortionAmount', 0);
end;

procedure TTestPayments.sendInvoice;
var
  Prices: TLabeledPriceArray;
begin
  Prices:=TLabeledPriceArray.Create(PortionLabel, PortionAmount);
  try
    Bot.sendInvoice(ChatID, 'TestProduct', 'This is test product for the testing purpose', 'payload001',
      ProviderToken, 'DeepLinkingStartParameter', Currency, Prices, nil);
  finally
    FreeAndNil(Prices);
  end;
  if Bot.LastErrorCode<>0 then
    Fail('Error from telegram API server. Error code: '+IntToStr(Bot.LastErrorCode)+
      '. Description: '+Bot.LastErrorDescription);
end;

procedure TTestPayments.ReceivePreCheckoutQuery;
begin
  Bot.getUpdates;
  if not Received then
    Fail('No updates were received. Please send the (test) payment for the created previously invoice')
  else
    Bot.getUpdatesEx(100, 1);  // Telegram API will understand that previous updates have been processed
end;

procedure TTestPayments.ReceiveSuccessfulPayment;
begin
  Bot.getUpdates;
  if not Received then
    Fail('No updates were received. Please receive PreCheckoutQuery before')
  else
    Bot.getUpdatesEx(100, 1);  // Telegram API will understand that previous updates have been processed
end;

{ TTestSenderProcedure }

procedure TTestSenderProcedure.sendMessage;
var
  AToken: String;
  AChatID: Int64;
  AReply: String;
begin
  AToken:=Conf.ReadString('Bot', 'Token', EmptyStr);
  AChatID:=Conf.ReadInt64('Chat', 'ID', 0);
  if not TgBotSendMessage(AToken, AChatID, Format(Msg, [Self.ClassName, TestName]), AReply) then
    Fail('Fail to send message from telegram bot!');
  SaveString(AReply, '~JSONResponce.json');
end;

{ TTestSender }

procedure TTestSender.SetUp;
begin
  inherited SetUp;
  FVideoUrl:=Conf.ReadString('Send', 'videourl', EmptyStr);
  FUrl:=Conf.ReadString('Send', 'Url', EmptyStr);
  FVideoFile:=Conf.ReadString('Send', 'VideoFile', EmptyStr);
  FPhotoUrl:=Conf.ReadString('Send', 'photourl', EmptyStr);
  FPhotoFile:=Conf.ReadString('Send', 'PhotoFile', EmptyStr);
  FJSONMediaGroup:=Conf.ReadString('Send', 'JSONMediaGroup', EmptyStr);
  FPrivateChatID:=Conf.ReadInt64('Chat', 'PrivateID', 0);
  if FPrivateChatID=0 then
    FPrivateChatID:=ChatID;
end;

procedure TTestSender.sendMessage;
begin
  if not Bot.sendMessage(ChatID, Format(Msg, [Self.ClassName, TestName])) then
    Fail('Connection error. See log');
  if Bot.LastErrorCode<>0 then
    Fail('Error from telegram API server. Error code: '+IntToStr(Bot.LastErrorCode)+
      '. Description: '+Bot.LastErrorDescription);
  if not Bot.sendMessage(ChatID, Format(Msg_md, [Self.ClassName, TestName]), pmMarkdown) then
    Fail('Connection error. See log');
  if Bot.LastErrorCode<>0 then
    Fail('Error from telegram API server. Error code: '+IntToStr(Bot.LastErrorCode)+
      '. Description: '+Bot.LastErrorDescription);
end;

procedure TTestSender.InlineKeyboard;
var
  ReplyMarkup: TReplyMarkup;
  Buttons: TInlineKeyboardButtons;
begin
  ReplyMarkup:=TReplyMarkup.Create;
  try
    Buttons:=ReplyMarkup.CreateInlineKeyBoard.Add;
    Buttons.AddButtonUrl('Github.com',
      'https://github.com/Al-Muhandis/fp-telegram');
    ReplyMarkup.InlineKeyBoard.Add.AddButtons(['Button 1', 'Callback data 1', 'Button 2', 'Callback data 2']);
    if not Bot.sendMessage(ChatID, Format(Msg_md, [Self.ClassName, TestName]), pmMarkdown,
      False, ReplyMarkup) then
      Fail('Connection error. See log');
  finally
    ReplyMarkup.Free;
  end;
  if Bot.LastErrorCode<>0 then
    Fail('Error from telegram API server. Error code: '+IntToStr(Bot.LastErrorCode)+
      '. Description: '+Bot.LastErrorDescription);
end;

procedure TTestSenderManual.SendReplyKeyboard;
var
  ReplyMarkup: TReplyMarkup;
  Buttons: TKeyboardButtons;
  i: Integer;
begin
  ReplyMarkup:=TReplyMarkup.Create;
  try
    Buttons:=ReplyMarkup.CreateReplyKeyboard.Add;
    i:=Buttons.AddButton('Send location');
    Buttons.Buttons[i].RequestLocation:=True;
    i:=Buttons.AddButton('Send contact');
    Buttons.Buttons[i].RequestContact:=True;
    if not Bot.sendMessage(PrivateChatID, Format(Msg_md, [Self.ClassName, TestName]), pmMarkdown,
      False, ReplyMarkup) then
      Fail('Connection error. See log');
  finally
    ReplyMarkup.Free;
  end;
  if Bot.LastErrorCode<>0 then
    Fail('Error from telegram API server. Error code: '+IntToStr(Bot.LastErrorCode)+
      '. Description: '+Bot.LastErrorDescription);
end;

procedure TTestSender.sendVideo;
begin
  if not Bot.sendVideo(ChatID, VideoUrl, Format(vd_cptn, [Self.ClassName, TestName])) then
    Fail('Connection error. See log');
  if Bot.LastErrorCode<>0 then
    Fail('Error from telegram API server. Error code: '+IntToStr(Bot.LastErrorCode)+
      '. Description: '+Bot.LastErrorDescription);
end;

procedure TTestSender.sendVideoByFileName;
begin
  if not Bot.sendVideoByFileName(ChatID, VideoFile, Format(vd_cptn, [Self.ClassName, TestName]), pmDefault, Nil) then
    Fail('Connection error. See log');
  if Bot.LastErrorCode<>0 then
    Fail('Error from telegram API server. Error code: '+IntToStr(Bot.LastErrorCode)+
      '. Description: '+Bot.LastErrorDescription);
end;

procedure TTestSender.sendVideoStream;
var
  aStream: TMemoryStream;
begin
  aStream:=TMemoryStream.Create;
  aStream.LoadFromFile(VideoFile);
  if not Bot.sendVideoStream(ChatID, VideoFile, aStream, Format(vd_cptn, [Self.ClassName, TestName])) then
    Fail('Connection error. See log');
  if Bot.LastErrorCode<>0 then
    Fail('Error from telegram API server. Error code: '+IntToStr(Bot.LastErrorCode)+
      '. Description: '+Bot.LastErrorDescription);
  aStream.Free;
end;

procedure TTestSender.sendPhoto;
begin
  if not Bot.sendPhoto(ChatID, PhotoUrl, Format(pht_cptn, [Self.ClassName, TestName])) then
    Fail('Connection error. See log');
  if Bot.LastErrorCode<>0 then
    Fail('Error from telegram API server. Error code: '+IntToStr(Bot.LastErrorCode)+
      '. Description: '+Bot.LastErrorDescription);
end;

procedure TTestSender.sendPhotoWithInlineKeyboardAndThenEdit;
var
  aReplyMarkup: TReplyMarkup;
  aButtons: TInlineKeyboardButtons;
  aRespObject: TJSONObject;
begin
  aReplyMarkup:=TReplyMarkup.Create;
  try
    aButtons:=aReplyMarkup.CreateInlineKeyBoard.Add;
    aButtons.AddButtonUrl('Github.com',
      'https://github.com/Al-Muhandis/fp-telegram');
    aReplyMarkup.InlineKeyBoard.Add.AddButtons(['Button 1', 'Callback data 1', 'Button 2', 'Callback data 2']);
    if not Bot.sendPhoto(ChatID, PhotoUrl, Format(pht_cptn, [Self.ClassName, TestName]), pmDefault, aReplyMarkup) then
      Fail('Connection error. See log');
    if Assigned(Bot.JSONResponse) then
      aRespObject:=TJSONObject(Bot.JSONResponse);
    aReplyMarkup.InlineKeyBoard.AddButton('Another button', 'another btn data');
    Bot.editMessageReplyMarkup(ChatID, aRespObject.Integers['message_id'], '', aReplyMarkup);
  finally
    aReplyMarkup.Free;
  end;
  if Bot.LastErrorCode<>0 then
    Fail('Error from telegram API server. Error code: '+IntToStr(Bot.LastErrorCode)+
      '. Description: '+Bot.LastErrorDescription);
end;

procedure TTestSender.sendPhotoByFileName;
begin
  if not Bot.sendPhotoByFileName(ChatID, PhotoFile, Format(pht_cptn, [Self.ClassName, TestName])) then
    Fail('Connection error. See log');
  if Bot.LastErrorCode<>0 then
    Fail('Error from telegram API server. Error code: '+IntToStr(Bot.LastErrorCode)+
      '. Description: '+Bot.LastErrorDescription);
end;

procedure TTestSender.sendMediaGroup;
var
  aJSONData: TJSONArray;
  aMedias: TInputMediaArray;
  i: TJSONEnum;
begin
  { This test sends media by URL: take the list from JSONMediaGroupURLs.
    JSONMediaGroup is used by sendMediaGroupByFileNames and contains local file names }
  aJSONData:=GetJSON(Conf.ReadString('Send', 'JSONMediaGroupURLs', DefaultMediaGroupURLs)) as TJSONArray;
  aMedias:=TInputMediaArray.Create;
  try
    for i in aJSONData do
      aMedias.Add(i.Value.Clone as TJSONObject);
    if not Bot.sendMediaGroup(ChatID, aMedias) then
      Fail('Connection error. See log');
  finally
    aJSONData.Free;
    aMedias.Free;
  end;
  if Bot.LastErrorCode<>0 then
    Fail('Error from telegram API server. Error code: '+IntToStr(Bot.LastErrorCode)+
      '. Description: '+Bot.LastErrorDescription);
end;

procedure TTestSender.sendMediaGroupByFileName;
var
  aJSONData: TJSONArray;
  aMedias: TInputMediaArray;
  i: TJSONEnum;
begin
  aJSONData:=GetJSON(JSONMediaGroup) as TJSONArray;
  aMedias:=TInputMediaArray.Create;
  try
    for i in aJSONData do
      aMedias.Add(i.Value.Clone as TJSONObject);
    if not Bot.sendMediaGroupByFileNames(ChatID, aMedias) then
      Fail('Connection error. See log');
  finally
    aJSONData.Free;
    aMedias.Free;
  end;
  if Bot.LastErrorCode<>0 then
    Fail('Error from telegram API server. Error code: '+IntToStr(Bot.LastErrorCode)+
      '. Description: '+Bot.LastErrorDescription);
end;

procedure TTestSender.SendPoll;
begin
  if not Bot.sendPoll(ChatID, 'Some poll question', ['Option1', 'Option 2'], True, ptRegular, False, -1, EmptyStr,
    pmDefault, nil) then
    Fail('Connection error. See log');
  if Bot.LastErrorCode<>0 then
    Fail('Error from telegram API server. Error code: '+IntToStr(Bot.LastErrorCode)+
      '. Description: '+Bot.LastErrorDescription);
end;

procedure TTestSender.ChatMember;
begin
  if not Bot.getChatMember(ChatID, UserID) then
    Fail('Connection error. See log');
  SaveJSONData(Bot.JSONResponse, '~responce.json');
  if Bot.LastErrorCode<>0 then
    Fail('Error from telegram API server. Error code: '+IntToStr(Bot.LastErrorCode)+
      '. Description: '+Bot.LastErrorDescription);
end;

procedure TTestSender.getWebhookInfo;
var
  aWebhookInfo: TTelegramWebhookInfo;
begin
  try
    if not Bot.getWebhookInfo(aWebhookInfo) then
      Fail('Connection error. See log')
    else
      SaveString(aWebhookInfo.AsString, '~webhookinfo.json');
  finally
    aWebhookInfo.Free;
  end;
  if Bot.LastErrorCode<>0 then
    Fail('Error from telegram API server. Error code: '+IntToStr(Bot.LastErrorCode)+
      '. Description: '+Bot.LastErrorDescription);
end;

procedure TTestSender.setWebhook;
begin
  if not Bot.setWebhook(Url, 10, []) then
    Fail('Connection error. See log');
  SaveJSONData(Bot.JSONResponse, '~responce.json');
  if Bot.LastErrorCode<>0 then
    Fail('Error from telegram API server. Error code: '+IntToStr(Bot.LastErrorCode)+
      '. Description: '+Bot.LastErrorDescription);
end;

procedure TTestSender.deleteWebhook;
begin
  if not Bot.deleteWebhook then
    Fail('Connection error. See log');
  SaveJSONData(Bot.JSONResponse, '~responce.json');
  if Bot.LastErrorCode<>0 then
    Fail('Error from telegram API server. Error code: '+IntToStr(Bot.LastErrorCode)+
      '. Description: '+Bot.LastErrorDescription);
end;
{$IF FPC_FULLVERSION > 30004}
procedure TTestSender.testCodePage;
var
  aStream: TStringStream;
  s: String;
begin
  aStream:=TStringStream.Create(EmptyStr);
  aStream.LoadFromFile('~debugutf8.txt');
  S:=EmptyStr;
  s+=aStream.DataString;
  Bot.Logger.Debug(CodePageToCodePageName(StringCodePage(S)));
  if not Bot.sendMessage(ChatID, s, pmMarkdown) then
    Fail('Connection error. See log');
  aStream.Free;
  if Bot.LastErrorCode<>0 then
    Fail('Error from telegram API server. Error code: '+IntToStr(Bot.LastErrorCode)+
      '. Description: '+Bot.LastErrorDescription);
  if not Bot.sendMessage(ChatID, Format(Msg_md, [Self.ClassName, TestName]), pmMarkdown) then
    Fail('Connection error. See log');
  if Bot.LastErrorCode<>0 then
    Fail('Error from telegram API server. Error code: '+IntToStr(Bot.LastErrorCode)+
      '. Description: '+Bot.LastErrorDescription);
end;
{$endif}
procedure TTestSender.getMyCommands;
begin
  if not Bot.getMyCommands then
    Fail('Connection error. See log');
end;

procedure TTestSender.setMyCommands;
var
  aCommands: TBotCommandArray;
begin
  aCommands:=TBotCommandArray.Create;
  try
    aCommands.AddCommands(['start', 'Start command', 'help', 'Help command']);
    if not Bot.setMyCommands(aCommands) then
      Fail('Connection error. See log');
  finally
    aCommands.Free;
  end;
end;

procedure TTestSender.editMessageMediaStream;
var
  aMedia: TInputMedia;
  aMessageID: Int64;
  aStream: TFileStream;
begin
  if not Bot.sendPhoto(ChatID, PhotoUrl, Format(pht_cptn, [Self.ClassName, TestName])) then
    Fail('Connection error. See log');
  aMessageID:=(Bot.JSONResponse as TJSONObject).Int64s['message_id'];
  if Bot.LastErrorCode<>0 then
    Fail('Error from telegram API server. Error code: '+IntToStr(Bot.LastErrorCode)+
      '. Description: '+Bot.LastErrorDescription);
  aMedia:=TInputMediaPhoto.Create;
  aStream:=TFileStream.Create(PhotoFile, fmOpenRead);
  try
    if not Bot.editMessageMediaStream(aStream, aMedia, ChatID, aMessageID) then
      Fail('Connection error. See log');
  finally
    aStream.Free;
    aMedia.Free;
  end;
end;

procedure TTestSender.getChatAdministators;
var
  aAdministrators: TJSONArray;
begin
  Bot.getChatAdministrators(ChatID, aAdministrators);
  SaveJSONData(Bot.JSONResponse, '~responce.json');
  aAdministrators.Free;
end;

{ TTestSender: rich messages (Bot API 10.1+) }

procedure TTestSender.sendRichMessageMarkdown;
var
  aRich: TInputRichMessage;
begin
  aRich:=TInputRichMessage.CreateFromMarkdown('# Rich heading' + LineEnding +
    'Sent by *fp-telegram* unit test `' + TestName + '`');
  try
    if not Bot.sendRichMessage(ChatID, aRich) then
      Fail('Connection error. See log');
  finally
    aRich.Free;
  end;
  if Bot.LastErrorCode<>0 then
    Fail('Error from telegram API server. Error code: '+IntToStr(Bot.LastErrorCode)+
      '. Description: '+Bot.LastErrorDescription);
  SaveJSONData(Bot.JSONResponse, '~richmessage.json');
  if Assigned(Bot.JSONResponse) then
    if (Bot.JSONResponse as TJSONObject).Find('rich_message', jtObject)=nil then
      Fail('The sent message must contain the rich_message field');
end;

procedure TTestSender.sendRichMessageWithButtonsAndEdit;
var
  aRich, aEdited: TInputRichMessage;
  aBlock: TInputRichBlockButtons;
  aMessageID: Int64;
begin
  aRich:=TInputRichMessage.CreateFromMarkdown('Rich message with a button row');
  try
    aBlock:=aRich.AddButtonsBlock;
    aBlock.Buttons.AddCallbackButton('Rich callback', 'rich-cb-data');
    aBlock.Buttons.AddButton('Rich link', 'https://github.com/Al-Muhandis/fp-telegram');
    if not Bot.sendRichMessage(ChatID, aRich) then
      Fail('Connection error. See log');
  finally
    aRich.Free;
  end;
  if Bot.LastErrorCode<>0 then
    Fail('Error from telegram API server. Error code: '+IntToStr(Bot.LastErrorCode)+
      '. Description: '+Bot.LastErrorDescription);
  aMessageID:=(Bot.JSONResponse as TJSONObject).Int64s['message_id'];
  { edit the sent message with another rich message (the rich_message parameter of editMessageText) }
  aEdited:=TInputRichMessage.CreateFromMarkdown('Edited *rich* text');
  try
    if not Bot.editMessageTextRich(aEdited, ChatID, aMessageID) then
      Fail('Connection error. See log');
  finally
    aEdited.Free;
  end;
  if Bot.LastErrorCode<>0 then
    Fail('Error from telegram API server. Error code: '+IntToStr(Bot.LastErrorCode)+
      '. Description: '+Bot.LastErrorDescription);
end;

procedure TTestSender.sendPersistentKeyboard;
var
  aReplyMarkup: TReplyMarkup;
  aButtons: TKeyboardButtons;
begin
  aReplyMarkup:=TReplyMarkup.Create;
  try
    aButtons:=aReplyMarkup.CreateReplyKeyboard.Add;
    aButtons.AddButton('Persistent button');
    aReplyMarkup.IsPersistent:=True;
    aReplyMarkup.ResizeKeyboard:=True;
    aReplyMarkup.InputFieldPlaceholder:='Type or press the button...';
    if not Bot.sendMessage(ChatID, Format(Msg, [Self.ClassName, TestName]), pmDefault,
      False, aReplyMarkup) then
      Fail('Connection error. See log');
  finally
    aReplyMarkup.Free;
  end;
  if Bot.LastErrorCode<>0 then
    Fail('Error from telegram API server. Error code: '+IntToStr(Bot.LastErrorCode)+
      '. Description: '+Bot.LastErrorDescription);
  { clean up: remove the persistent keyboard }
  aReplyMarkup:=TReplyMarkup.Create;
  try
    aReplyMarkup.RemoveKeyboard:=True;
    Bot.sendMessage(ChatID, 'Keyboard removed', pmDefault, False, aReplyMarkup);
  finally
    aReplyMarkup.Free;
  end;
end;

procedure TTestSender.sendChatActionTyping;
begin
  if not Bot.sendChatAction(ChatID, caTyping) then
    Fail('Connection error. See log');
  if Bot.LastErrorCode<>0 then
    Fail('Error from telegram API server. Error code: '+IntToStr(Bot.LastErrorCode)+
      '. Description: '+Bot.LastErrorDescription);
end;

procedure TTestSender.pinAndUnpinMessage;
var
  aMessageID: Int64;
begin
  if not Bot.sendMessage(ChatID, 'Message to pin. Test: '+TestName) then
    Fail('Connection error. See log');
  if Bot.LastErrorCode<>0 then
    Fail('Error from telegram API server. Error code: '+IntToStr(Bot.LastErrorCode)+
      '. Description: '+Bot.LastErrorDescription);
  aMessageID:=(Bot.JSONResponse as TJSONObject).Int64s['message_id'];
  if not Bot.pinChatMessage(ChatID, aMessageID) then
    Fail('Connection error. See log');
  if Bot.LastErrorCode<>0 then
    Fail('Error from telegram API server. Error code: '+IntToStr(Bot.LastErrorCode)+
      '. Description: '+Bot.LastErrorDescription);
  if not Bot.unpinChatMessage(ChatID, aMessageID) then
    Fail('Connection error. See log');
  if Bot.LastErrorCode<>0 then
    Fail('Error from telegram API server. Error code: '+IntToStr(Bot.LastErrorCode)+
      '. Description: '+Bot.LastErrorDescription);
end;

procedure TTestSender.getUserProfilePhotosTest;
begin
  { the user may have no photos: an empty result is still a success }
  if not Bot.getUserProfilePhotos(UserID) then
    Fail('Connection error. See log');
  if Bot.LastErrorCode<>0 then
    Fail('Error from telegram API server. Error code: '+IntToStr(Bot.LastErrorCode)+
      '. Description: '+Bot.LastErrorDescription);
end;

procedure TTestSender.editMessageCaptionTest;
var
  aMessageID: Int64;
begin
  if not Bot.sendPhoto(ChatID, PhotoUrl, 'Caption before editing') then
    Fail('Connection error. See log');
  if Bot.LastErrorCode<>0 then
    Fail('Error from telegram API server. Error code: '+IntToStr(Bot.LastErrorCode)+
      '. Description: '+Bot.LastErrorDescription);
  aMessageID:=(Bot.JSONResponse as TJSONObject).Int64s['message_id'];
  if not Bot.editMessageCaption(ChatID, aMessageID, 'Caption after editing') then
    Fail('Connection error. See log');
  if Bot.LastErrorCode<>0 then
    Fail('Error from telegram API server. Error code: '+IntToStr(Bot.LastErrorCode)+
      '. Description: '+Bot.LastErrorDescription);
end;

procedure TTestSender.sendInlineCopyTextButton;
var
  aReplyMarkup: TReplyMarkup;
  aButton: TInlineKeyboardButton;
begin
  aReplyMarkup:=TReplyMarkup.Create;
  try
    aButton:=TInlineKeyboardButton.Create('Copy the answer');
    aButton.copy_text:=TCopyTextButton.Create('42');
    aReplyMarkup.CreateInlineKeyBoard.AddButton(aButton);
    if not Bot.sendMessage(ChatID, Format(Msg, [Self.ClassName, TestName]), pmDefault,
      False, aReplyMarkup) then
      Fail('Connection error. See log');
  finally
    aReplyMarkup.Free;
  end;
  if Bot.LastErrorCode<>0 then
    Fail('Error from telegram API server. Error code: '+IntToStr(Bot.LastErrorCode)+
      '. Description: '+Bot.LastErrorDescription);
end;

initialization
  { Integration tests require a configured bot: register them only in this case.
    Otherwise (for example, in CI) only the unit tests are run.
    The manual tests additionally require a human interaction during the run
    (a message sent to the bot, a test payment) or a private chat started with
    the bot, so they are registered only when [Manual] Enable=1 is set }
  if TTestTelegramClass.Configured then
  begin
    RegisterTests([TTestSender, TTestSenderProcedure, TTestProxySender]);
    if TTestTelegramClass.ManualEnabled then
      RegisterTests([TTestSenderManual, TTestReceiveLongPolling, TTestPayments]);
  end;

end.
