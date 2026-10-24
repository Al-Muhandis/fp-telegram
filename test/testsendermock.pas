unit testsendermock;

{
  Unit tests for the TTelegramSender logic with a mock HTTP client:
  request building, response handling, update dispatching, command handlers.
  The mock client is injected via the TTelegramSender.HTTPClientClass property,
  so no real network activity happens here.
}

{$mode objfpc}{$H+}
{$codepage UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fpjson, tgbasehttpclient,
  tgtypes, tgsendertypes;

type

  { TMockHTTPClient }
  { Records the last request made by the sender and returns the configured
    response text. The request log is kept in class vars because the sender
    creates a new client instance for every API request }

  TMockHTTPClient = class(TBaseHTTPClient)
  private
    FAllowRedirect: Boolean;
    FCookies: TStrings;
    FHTTPProxyHost: String;
    FHTTPProxyPassword: String;
    FHTTPProxyPort: Word;
    FHTTPProxyUsername: String;
    FIOTimeout: Integer;
    FRequestBody: TStream;
    FRequestHeaders: TStrings;
    FResponseHeaders: TStrings;
    FResponseStatusCode: Integer;
    FResponseStatusText: String;
    procedure RecordRequest(const AURL: String);
  protected
    function GetAllowRedirect: Boolean; override;
    function GetCookies: TStrings; override;
    function GetHTTPProxyHost: String; override;
    function GetHTTPProxyPassword: String; override;
    function GetHTTPProxyPort: Word; override;
    function GetHTTPProxyUsername: String; override;
    function GetInternalHTTPClient: TObject; override;
    function GetIOTimeout: Integer; override;
    function GetRequestBody: TStream; override;
    function GetRequestHeaders: TStrings; override;
    function GetResponseHeaders: TStrings; override;
    function GetResponseStatusCode: Integer; override;
    function GetResponseStatusText: String; override;
    procedure SetAllowRedirect(AValue: Boolean); override;
    procedure SetCookies(AValue: TStrings); override;
    procedure SetHTTPProxyHost(AValue: String); override;
    procedure SetHTTPProxyPassword(AValue: String); override;
    procedure SetHTTPProxyPort(AValue: Word); override;
    procedure SetHTTPProxyUsername(AValue: String); override;
    procedure SetIOTimeout(AValue: Integer); override;
    procedure SetRequestBody(AValue: TStream); override;
    procedure SetRequestHeaders(AValue: TStrings); override;
  public
    procedure AddHeader(const AHeader, AValue: String); override;
    class function EncodeUrlElement(S: String): String; override;
    procedure FileFormPost(const AURL: string; FormData: TStrings; AFieldName,
      AFileName: string; const Response: TStream); override;
    function FilesFormPost(const AURL: string; FormData: TStrings; const AFiles: TStrings): String; override;
    function FormPost(const URL: string; FormData: TStrings): String; override;
    function Get(const AUrl: String): String; override;
    function Post(const URL: string): String; override;
    procedure StreamFormPost(const AURL: string; FormData: TStrings; const AFieldName,
      AFileName: string; const AStream: TStream; const Response: TStream); override;
    function StreamsFormPost(const AURL: string; FormData: TStrings; const AFiles: TStrings): String; override;
    class procedure Reset;
    class var LastURL: String;
    class var LastBody: String;         // body of the last POST request
    class var LastFormData: String;     // CommaText of the form data of the last file/stream request
    class var LastFileName: String;     // file name of the last file upload request
    class var LastFieldName: String;    // form field name of the last file upload request
    class var ResponseText: String;     // the text returned to the sender
    class var FailRequests: Boolean;    // when True the requests raise an exception (connection error)
  end;

  { TBanBotSender }
  { TTelegramSender descendant used to test the banned users filtering }

  TBanBotSender = class(TTelegramSender)
  protected
    function IsBanned(ChatID: Int64): Boolean; override;
  end;

  { TTestSenderMock }

  TTestSenderMock = class(TTestCase)
  private
    FBot: TTelegramSender;
    FMessageReceived: Boolean;
    FCommandReceived: String;
    FCallbackReceived: Boolean;
    procedure BotReceiveMessage({%H-}ASender: TObject; AMessage: TTelegramMessageObj);
    procedure BotReceiveCommand({%H-}ASender: TObject; const ACommand: String;
      {%H-}AMessage: TTelegramMessageObj);
    procedure BotReceiveCallback({%H-}ASender: TObject; ACallback: TCallbackQueryObj);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
    property Bot: TTelegramSender read FBot;
    function LastRequestBody: TJSONObject;
    procedure MockResponse(const AResultJSON: String);
    procedure MockErrorResponse(const ACode: Integer; const ADescription: String);
  published
    procedure sendMessageBuildsRequest;
    procedure sendMessageHandlesApiError;
    procedure sendMessageHandlesConnectionError;
    procedure getMeParsesBotUser;
    procedure getUpdatesDispatchesMessageUpdate;
    procedure getUpdatesExUsesNextOffset;
    procedure getUpdatesDispatchesCallbackQuery;
    procedure getUpdatesFiresCommandHandler;
    procedure getUpdatesSkipsBannedUser;
    procedure sendPollPassesExplanation;
    procedure sendRichMessageBuildsRequest;
    procedure editMessageTextRichBuildsRequest;
    procedure getFileParsesFileObject;
    procedure sendPhotoByFileNameUploadsFile;
    procedure requestWhenAnswerBuildsInlineReply;
    procedure TgBotSendMessageFunction;
  end;

implementation

uses
  jsonparser, tgfclhttpclientbroker
  ;

const
  TestToken='123456:TEST-TOKEN';
  OkResult='{"ok":true,"result":';

{ TMockHTTPClient }

class procedure TMockHTTPClient.Reset;
begin
  LastURL:=EmptyStr;
  LastBody:=EmptyStr;
  LastFormData:=EmptyStr;
  LastFileName:=EmptyStr;
  LastFieldName:=EmptyStr;
  ResponseText:=EmptyStr;
  FailRequests:=False;
end;

procedure TMockHTTPClient.RecordRequest(const AURL: String);
begin
  LastURL:=AURL;
  if FailRequests then
    raise EHTTPClient.Create('Mock connection error');
end;

function TMockHTTPClient.GetAllowRedirect: Boolean;
begin
  Result:=FAllowRedirect;
end;

function TMockHTTPClient.GetCookies: TStrings;
begin
  Result:=FCookies;
end;

function TMockHTTPClient.GetHTTPProxyHost: String;
begin
  Result:=FHTTPProxyHost;
end;

function TMockHTTPClient.GetHTTPProxyPassword: String;
begin
  Result:=FHTTPProxyPassword;
end;

function TMockHTTPClient.GetHTTPProxyPort: Word;
begin
  Result:=FHTTPProxyPort;
end;

function TMockHTTPClient.GetHTTPProxyUsername: String;
begin
  Result:=FHTTPProxyUsername;
end;

function TMockHTTPClient.GetInternalHTTPClient: TObject;
begin
  Result:=Self;
end;

function TMockHTTPClient.GetIOTimeout: Integer;
begin
  Result:=FIOTimeout;
end;

function TMockHTTPClient.GetRequestBody: TStream;
begin
  Result:=FRequestBody;
end;

function TMockHTTPClient.GetRequestHeaders: TStrings;
begin
  Result:=FRequestHeaders;
end;

function TMockHTTPClient.GetResponseHeaders: TStrings;
begin
  Result:=FResponseHeaders;
end;

function TMockHTTPClient.GetResponseStatusCode: Integer;
begin
  Result:=FResponseStatusCode;
end;

function TMockHTTPClient.GetResponseStatusText: String;
begin
  Result:=FResponseStatusText;
end;

procedure TMockHTTPClient.SetAllowRedirect(AValue: Boolean);
begin
  FAllowRedirect:=AValue;
end;

procedure TMockHTTPClient.SetCookies(AValue: TStrings);
begin
  FCookies:=AValue;
end;

procedure TMockHTTPClient.SetHTTPProxyHost(AValue: String);
begin
  FHTTPProxyHost:=AValue;
end;

procedure TMockHTTPClient.SetHTTPProxyPassword(AValue: String);
begin
  FHTTPProxyPassword:=AValue;
end;

procedure TMockHTTPClient.SetHTTPProxyPort(AValue: Word);
begin
  FHTTPProxyPort:=AValue;
end;

procedure TMockHTTPClient.SetHTTPProxyUsername(AValue: String);
begin
  FHTTPProxyUsername:=AValue;
end;

procedure TMockHTTPClient.SetIOTimeout(AValue: Integer);
begin
  FIOTimeout:=AValue;
end;

procedure TMockHTTPClient.SetRequestBody(AValue: TStream);
begin
  FRequestBody:=AValue;
end;

procedure TMockHTTPClient.SetRequestHeaders(AValue: TStrings);
begin
  FRequestHeaders:=AValue;
end;

procedure TMockHTTPClient.AddHeader(const AHeader, AValue: String);
begin
  // request headers are not recorded
end;

class function TMockHTTPClient.EncodeUrlElement(S: String): String;
begin
  Result:=S;
end;

procedure TMockHTTPClient.FileFormPost(const AURL: string; FormData: TStrings;
  AFieldName, AFileName: string; const Response: TStream);
begin
  RecordRequest(AURL);
  if Assigned(FormData) then
    LastFormData:=FormData.CommaText;
  LastFieldName:=AFieldName;
  LastFileName:=AFileName;
  if ResponseText<>EmptyStr then
    Response.WriteBuffer(ResponseText[1], Length(ResponseText));
end;

function TMockHTTPClient.FilesFormPost(const AURL: string; FormData: TStrings;
  const AFiles: TStrings): String;
begin
  RecordRequest(AURL);
  if Assigned(FormData) then
    LastFormData:=FormData.CommaText;
  Result:=ResponseText;
end;

function TMockHTTPClient.FormPost(const URL: string; FormData: TStrings): String;
begin
  RecordRequest(URL);
  if Assigned(FormData) then
    LastFormData:=FormData.CommaText;
  Result:=ResponseText;
end;

function TMockHTTPClient.Get(const AUrl: String): String;
begin
  RecordRequest(AUrl);
  Result:=ResponseText;
end;

function TMockHTTPClient.Post(const URL: string): String;
var
  lSavedPos: Int64;
begin
  RecordRequest(URL);
  LastBody:=EmptyStr;
  if Assigned(FRequestBody) then
  begin
    lSavedPos:=FRequestBody.Position;
    FRequestBody.Position:=0;
    with TStringStream.Create do
    try
      CopyFrom(FRequestBody, FRequestBody.Size);
      LastBody:=DataString;
    finally
      Free;
    end;
    FRequestBody.Position:=lSavedPos;
  end;
  Result:=ResponseText;
end;

procedure TMockHTTPClient.StreamFormPost(const AURL: string; FormData: TStrings;
  const AFieldName, AFileName: string; const AStream: TStream; const Response: TStream);
begin
  FileFormPost(AURL, FormData, AFieldName, AFileName, Response);
end;

function TMockHTTPClient.StreamsFormPost(const AURL: string; FormData: TStrings;
  const AFiles: TStrings): String;
begin
  Result:=FilesFormPost(AURL, FormData, AFiles);
end;

{ TBanBotSender }

function TBanBotSender.IsBanned(ChatID: Int64): Boolean;
begin
  Result:=True;
end;

{ TTestSenderMock }

procedure TTestSenderMock.BotReceiveMessage(ASender: TObject;
  AMessage: TTelegramMessageObj);
begin
  FMessageReceived:=True;
end;

procedure TTestSenderMock.BotReceiveCommand(ASender: TObject;
  const ACommand: String; AMessage: TTelegramMessageObj);
begin
  FCommandReceived:=ACommand;
end;

procedure TTestSenderMock.BotReceiveCallback(ASender: TObject;
  ACallback: TCallbackQueryObj);
begin
  FCallbackReceived:=True;
end;

procedure TTestSenderMock.SetUp;
begin
  inherited SetUp;
  TMockHTTPClient.Reset;
  FBot:=TTelegramSender.Create(TestToken);
  FBot.HTTPClientClass:=TMockHTTPClient;
  FMessageReceived:=False;
  FCommandReceived:=EmptyStr;
  FCallbackReceived:=False;
end;

procedure TTestSenderMock.TearDown;
begin
  FreeAndNil(FBot);
  TMockHTTPClient.Reset;
  inherited TearDown;
end;

function TTestSenderMock.LastRequestBody: TJSONObject;
begin
  Result:=GetJSON(TMockHTTPClient.LastBody) as TJSONObject;
end;

procedure TTestSenderMock.MockResponse(const AResultJSON: String);
begin
  TMockHTTPClient.ResponseText:=OkResult+AResultJSON+'}';
end;

procedure TTestSenderMock.MockErrorResponse(const ACode: Integer;
  const ADescription: String);
begin
  TMockHTTPClient.ResponseText:=Format('{"ok":false,"error_code":%d,"description":"%s"}',
    [ACode, ADescription]);
end;

procedure TTestSenderMock.sendMessageBuildsRequest;
var
  lBody: TJSONObject;
begin
  MockResponse('true');
  AssertTrue('sendMessage must succeed', Bot.sendMessage(42, 'Hello', pmMarkdown, True));
  AssertEquals('true', Bot.JSONResponse.AsJSON);

  AssertEquals('Request URL', TelegramAPI_URL+TestToken+'/sendMessage', TMockHTTPClient.LastURL);
  lBody:=LastRequestBody;
  try
    AssertEquals(42, lBody.Integers['chat_id']);
    AssertEquals('Hello', lBody.Strings['text']);
    AssertEquals('Markdown', lBody.Strings['parse_mode']);
    AssertTrue('disable_web_page_preview', lBody.Booleans['disable_web_page_preview']);
  finally
    lBody.Free;
  end;
  // parse_mode must be omitted for the default value
  AssertTrue(Bot.sendMessage(42, 'plain'));
  lBody:=LastRequestBody;
  try
    AssertTrue('parse_mode omitted by default', lBody.Find('parse_mode')=nil);
    AssertFalse('disable_web_page_preview false by default', lBody.Booleans['disable_web_page_preview']);
  finally
    lBody.Free;
  end;
end;

procedure TTestSenderMock.sendMessageHandlesApiError;
begin
  MockErrorResponse(400, 'Bad Request: message text is empty');
  AssertFalse('sendMessage must fail on API error', Bot.sendMessage(42, 'x'));
  AssertEquals(400, Bot.LastErrorCode);
  AssertEquals('Bad Request: message text is empty', Bot.LastErrorDescription);
  AssertNotNull('JSONResponse contains the error object', Bot.JSONResponse);
  AssertEquals(400, (Bot.JSONResponse as TJSONObject).Integers['error_code']);
end;

procedure TTestSenderMock.sendMessageHandlesConnectionError;
begin
  TMockHTTPClient.FailRequests:=True;
  AssertFalse('sendMessage must fail on a connection error', Bot.sendMessage(42, 'x'));
  AssertEquals(EmptyStr, Bot.Response);
end;

procedure TTestSenderMock.getMeParsesBotUser;
begin
  MockResponse('{"id":1,"is_bot":true,"first_name":"TestBot","username":"test_bot"}');
  AssertTrue(Bot.getMe);
  AssertNotNull('BotUser assigned', Bot.BotUser);
  AssertEquals(1, Bot.BotUser.ID);
  AssertTrue(Bot.BotUser.Is_bot);
  AssertEquals('TestBot', Bot.BotUser.First_name);
  AssertEquals('test_bot', Bot.BotUsername);
end;

procedure TTestSenderMock.getUpdatesDispatchesMessageUpdate;
begin
  Bot.OnReceiveMessage:=@BotReceiveMessage;
  MockResponse('[{"update_id":500,"message":{"message_id":1,"date":1700000000,'+
    '"chat":{"id":42,"type":"private"},"from":{"id":99,"is_bot":false,"first_name":"Bob"},'+
    '"text":"hello"}}]');
  AssertTrue(Bot.getUpdates);
  AssertTrue('OnReceiveMessage fired', FMessageReceived);
  AssertEquals(500, Bot.UpdateID);
  AssertEquals(42, Bot.CurrentChatId);
  AssertEquals(99, Bot.CurrentUser.ID);
  AssertEquals('hello', Bot.CurrentMessage.Text);
  AssertEquals('Request URL', TelegramAPI_URL+TestToken+'/getUpdates', TMockHTTPClient.LastURL);
end;

procedure TTestSenderMock.getUpdatesExUsesNextOffset;
var
  lBody: TJSONObject;
begin
  MockResponse('[{"update_id":500,"message":{"message_id":1,"date":1,'+
    '"chat":{"id":42,"type":"private"},"text":"x"}}]');
  AssertTrue(Bot.getUpdates);
  MockResponse('[]');
  AssertTrue(Bot.getUpdatesEx(0, 0));
  lBody:=LastRequestBody;
  try
    // the offset must be the last UpdateID + 1
    AssertEquals(501, lBody.Integers['offset']);
  finally
    lBody.Free;
  end;
end;

procedure TTestSenderMock.getUpdatesDispatchesCallbackQuery;
begin
  Bot.OnReceiveCallbackQuery:=@BotReceiveCallback;
  MockResponse('[{"update_id":501,"callback_query":{"id":"cb1","from":{"id":99,"is_bot":false},'+
    '"data":"payload","chat_instance":"ci"}}]');
  AssertTrue(Bot.getUpdates);
  AssertTrue('OnReceiveCallbackQuery fired', FCallbackReceived);
  AssertEquals('for the callback query the answer goes to the private chat of the user',
    99, Bot.CurrentChatId);
end;

procedure TTestSenderMock.getUpdatesFiresCommandHandler;
begin
  Bot.CommandHandlers['/start']:=@BotReceiveCommand;
  MockResponse('[{"update_id":502,"message":{"message_id":2,"date":1,'+
    '"chat":{"id":42,"type":"private"},"from":{"id":99,"is_bot":false},'+
    '"text":"/start@somebot hello","entities":[{"type":"bot_command","offset":0,"length":12}]}}]');
  AssertTrue(Bot.getUpdates);
  AssertEquals('/start', FCommandReceived);
end;

procedure TTestSenderMock.getUpdatesSkipsBannedUser;
var
  lBanBot: TBanBotSender;
begin
  lBanBot:=TBanBotSender.Create(TestToken);
  try
    lBanBot.HTTPClientClass:=TMockHTTPClient;
    lBanBot.OnReceiveMessage:=@BotReceiveMessage;
    MockResponse('[{"update_id":503,"message":{"message_id":3,"date":1,'+
      '"chat":{"id":42,"type":"private"},"text":"x"}}]');
    FMessageReceived:=False;
    AssertTrue(lBanBot.getUpdates);
    AssertFalse('The message of a banned user must be ignored', FMessageReceived);
  finally
    lBanBot.Free;
  end;
end;

procedure TTestSenderMock.sendPollPassesExplanation;
var
  lBody: TJSONObject;
begin
  MockResponse('true');
  AssertTrue(Bot.sendPoll(42, 'The question', ['Yes', 'No'], True, ptQuiz, False, 0,
    'The explanation', pmDefault, nil));
  lBody:=LastRequestBody;
  try
    // regression: the explanation value was lost and null was sent instead
    AssertEquals('The question', lBody.Strings['question']);
    AssertEquals('The explanation', lBody.Strings['explanation']);
    AssertEquals('quiz', lBody.Strings['type']);
    AssertEquals(2, lBody.Arrays['options'].Count);
    AssertEquals('Yes', lBody.Arrays['options'].Strings[0]);
  finally
    lBody.Free;
  end;
end;

procedure TTestSenderMock.sendRichMessageBuildsRequest;
var
  lRich: TInputRichMessage;
  lBody: TJSONObject;
begin
  MockResponse('{"message_id":80,"date":1,"chat":{"id":42,"type":"private"}}');
  lRich:=TInputRichMessage.CreateFromMarkdown('# Hello rich');
  try
    AssertTrue('sendRichMessage must succeed', Bot.sendRichMessage(42, lRich));
  finally
    lRich.Free;
  end;
  AssertEquals('Request URL', TelegramAPI_URL+TestToken+'/sendRichMessage', TMockHTTPClient.LastURL);
  lBody:=LastRequestBody;
  try
    AssertEquals(42, lBody.Integers['chat_id']);
    AssertEquals('# Hello rich', lBody.Objects['rich_message'].Strings['markdown']);
    AssertTrue('rich_message present', lBody.Find('rich_message', jtObject)<>nil);
  finally
    lBody.Free;
  end;
end;

procedure TTestSenderMock.editMessageTextRichBuildsRequest;
var
  lRich: TInputRichMessage;
  lBlock: TInputRichBlockButtons;
  lBody: TJSONObject;
begin
  MockResponse('true');
  lRich:=TInputRichMessage.Create;
  try
    lBlock:=lRich.AddButtonsBlock;
    lBlock.Buttons.AddCallbackButton('Press me', 'rich-cb');
    AssertTrue('editMessageTextRich must succeed', Bot.editMessageTextRich(lRich, 42, 100));
  finally
    lRich.Free;
  end;
  AssertEquals('Request URL', TelegramAPI_URL+TestToken+'/editMessageText', TMockHTTPClient.LastURL);
  lBody:=LastRequestBody;
  try
    AssertEquals(42, lBody.Integers['chat_id']);
    AssertEquals(100, lBody.Integers['message_id']);
    AssertEquals(1, lBody.Objects['rich_message'].Arrays['blocks'].Count);
    AssertEquals('rich-cb', lBody.Objects['rich_message'].Arrays['blocks'].Objects[0]
      .Arrays['buttons'].Objects[0].Strings['callback_data']);
  finally
    lBody.Free;
  end;
end;

procedure TTestSenderMock.getFileParsesFileObject;
begin
  MockResponse('{"file_id":"fid","file_size":100,"file_path":"photos/a.jpg"}');
  AssertTrue(Bot.getFile('fid'));
  AssertNotNull('FileObj assigned', Bot.FileObj);
  AssertEquals('photos/a.jpg', Bot.FileObj.FilePath);
  AssertEquals('https://api.telegram.org/file/bot'+TestToken+'/photos/a.jpg',
    Bot.FileObj.DownloadLink(TestToken));
end;

procedure TTestSenderMock.sendPhotoByFileNameUploadsFile;
begin
  MockResponse('{"message_id":77,"date":1,"chat":{"id":42,"type":"private"}}');
  AssertTrue(Bot.sendPhotoByFileName(42, 'photo.png', 'the caption'));
  AssertEquals('Request URL', TelegramAPI_URL+TestToken+'/sendPhoto', TMockHTTPClient.LastURL);
  AssertEquals('Form field name', 'photo', TMockHTTPClient.LastFieldName);
  AssertEquals('File name', 'photo.png', TMockHTTPClient.LastFileName);
  AssertTrue('chat_id in the form data', Pos('chat_id=42', TMockHTTPClient.LastFormData)>0);
  AssertTrue('caption in the form data', Pos('caption=the caption', TMockHTTPClient.LastFormData)>0);
end;

procedure TTestSenderMock.requestWhenAnswerBuildsInlineReply;
var
  lBody: TJSONObject;
begin
  // in the webhook mode the API call is embedded into the HTTP response body
  Bot.RequestWhenAnswer:=True;
  AssertTrue(Bot.editMessageText('new text', 42, 100));
  AssertEquals(EmptyStr, TMockHTTPClient.LastURL); // no HTTP request was made
  lBody:=GetJSON(Bot.RequestBody) as TJSONObject;
  try
    AssertEquals('editMessageText', lBody.Strings['method']);
    AssertEquals('new text', lBody.Strings['text']);
    AssertEquals(42, lBody.Integers['chat_id']);
    AssertEquals(100, lBody.Integers['message_id']);
  finally
    lBody.Free;
  end;
end;

procedure TTestSenderMock.TgBotSendMessageFunction;
var
  lReply: String;
begin
  // the standalone function creates its own sender, so the mock must be
  // registered globally for this test
  TBaseHTTPClient.UnregisterClientClass;
  TMockHTTPClient.RegisterClientClass;
  try
    MockResponse('{"message_id":5,"date":1,"chat":{"id":42,"type":"private"}}');
    AssertTrue(TgBotSendMessage(TestToken, 42, 'Hello function', lReply));
    AssertEquals('Request URL', TelegramAPI_URL+TestToken+'/sendMessage', TMockHTTPClient.LastURL);
    AssertTrue('The reply contains the sent message', Pos('"message_id"', lReply)>0);
  finally
    TBaseHTTPClient.UnregisterClientClass;
    TFCLHTTPClient.RegisterClientClass;
  end;
end;

initialization
  RegisterTest(TTestSenderMock);

end.
