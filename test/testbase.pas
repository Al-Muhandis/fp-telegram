unit testbase;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, tgsendertypes, IniFiles, fpjson;

type

  { TTestTelegramBase }
  { Base class for the integration tests: reads the testtelegram.ini configuration }

  TTestTelegramBase= class(TTestCase)
  private
    FConf: TIniFile;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
    property Conf: TIniFile read FConf;
    procedure SaveJSONData(AData: TJSONData; const AFileName: String);
    procedure SaveString(const AString, AFileName: String);
  end;

  { TTestTelegramClass }
  { Base class for the integration tests working with a real bot.
    The tests are registered only when the bot token and chat ID are configured,
    see class function Configured }

  TTestTelegramClass= class(TTestTelegramBase)
  private
    FBot: TTelegramSender;
    FChatID: Int64;
    FUserID: Int64;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
    property Bot: TTelegramSender read FBot;
    property ChatID: Int64 read FChatID;
    property UserID: Int64 read FUserID;
  public
    { True when testtelegram.ini contains both the bot token and the chat ID.
      Integration tests must be registered only if it is True }
    class function Configured: Boolean;
    { True when [Manual] Enable=1 is set in testtelegram.ini: additional tests
      that need a human interaction during the run are registered then }
    class function ManualEnabled: Boolean;
  end;

implementation

uses
  eventlog
  ;

{ TTestTelegramClass }

class function TTestTelegramClass.Configured: Boolean;
var
  lConf: TMemIniFile;
begin
  Result:=False;
  if not FileExists('testtelegram.ini') then
    Exit;
  lConf:=TMemIniFile.Create('testtelegram.ini');
  try
    Result:=(lConf.ReadString('Bot', 'Token', EmptyStr)<>EmptyStr) and
      (lConf.ReadInt64('Chat', 'ID', 0)<>0);
  finally
    lConf.Free;
  end;
end;

class function TTestTelegramClass.ManualEnabled: Boolean;
var
  lConf: TMemIniFile;
begin
  Result:=False;
  if not FileExists('testtelegram.ini') then
    Exit;
  lConf:=TMemIniFile.Create('testtelegram.ini');
  try
    Result:=lConf.ReadInteger('Manual', 'Enable', 0)<>0;
  finally
    lConf.Free;
  end;
end;

procedure TTestTelegramClass.SetUp;
begin
  inherited SetUp;
  { Telegram limits the message rate per chat (~20/min). The integration suite
    sends many messages to the same chat in a row, so keep a pause between the
    tests to avoid 429 Too Many Requests responses }
  TThread.Sleep(3200);
  FBot:=TTelegramSender.Create(FConf.ReadString('Bot', 'Token', EmptyStr));
  FBot.Logger:=TEventLog.Create(nil);
  FBot.LogDebug:=True;
  with FBot.Logger do
  begin
    LogType:=ltFile;
    FileName:=ChangeFileExt(ParamStr(0), '.log');
    AppendContent:=True;
  end;
  if FBot.Token=EmptyStr then
    Fail('Please, specify bot token in testtelegram.ini! See readme.md');
  FChatID:=Conf.ReadInt64('Chat', 'ID', 0);
  if FChatID=0 then
    Fail('Please, specify chat ID in testtelegram.ini! See readme.md');
  FUserID:=Conf.ReadInt64('User', 'ID', 0);
end;

procedure TTestTelegramClass.TearDown;
begin
  FBot.Logger.Free;
  FBot.Logger:=nil;
  FreeAndNil(FBot);
  inherited TearDown;
end;

{ TTestTelegramBase }

procedure TTestTelegramBase.SetUp;
begin
  FConf:=TMemIniFile.Create('testtelegram.ini');
  TelegramAPI_URL:=FConf.ReadString('API', 'Endpoint', TelegramAPI_URL); // For Russian specific case
end;

procedure TTestTelegramBase.TearDown;
begin
  FreeAndNil(FConf);
end;

procedure TTestTelegramBase.SaveJSONData(AData: TJSONData;
  const AFileName: String);
begin
  if not Assigned(AData) then
  begin
    Fail('JSON data is empty!');
    Exit;
  end;
  SaveString(AData.FormatJSON, AFileName);
end;

procedure TTestTelegramBase.SaveString(const AString, AFileName: String);
var
  AStrings: TStringList;
begin
  AStrings:=TStringList.Create;
  try
    AStrings.Text:=AString;
    AStrings.SaveToFile(AFileName);
  finally
    AStrings.Free;
  end;
end;

end.
