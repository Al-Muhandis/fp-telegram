unit testtelegram;

{$mode objfpc}{$H+}

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
    FUrl: String;
    FVideoFile: String;
    FVideoUrl: String;
  protected
    procedure SetUp; override;
  public
    property VideoUrl: String read FVideoUrl;
    property Url: String read FUrl;
    property VideoFile: String read FVideoFile;
    property PhotoUrl: String read FPhotoUrl;
    property PhotoFile: String read FPhotoFile;
    property jsonMediaGroup: String read FJSONMediaGroup;
  published
    procedure sendMessage;
    procedure InlineKeyboard;
    procedure SendReplyKeyboard;
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

procedure TTestSender.SendReplyKeyboard;
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
  aJSONData:=GetJSON(JSONMediaGroup) as TJSONArray;
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

initialization
  RegisterTests([TTestSender, TTestSenderProcedure, TTestProxySender, TTestReceiveLongPolling, TTestPayments]);

end.

