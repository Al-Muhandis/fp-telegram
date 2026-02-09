unit tgstatlog;

{$mode objfpc}{$H+}

interface

uses SysUtils,Classes;

Type

  { TtgStatLog }

  TtgStatLog = Class(TComponent)
  Private
    fAppendContent : Boolean;
    FDirectory: String;
    FFieldDelimiter: String;
    FFilePostfix: String;
    FFilePrefix: String;
    FStream : TFileStream;
    FActive: Boolean;
    FDefaultEventType: TEventType;
    FTimeStampFormat: String;
    FPaused : Boolean;
    function GetFileName: String;
    procedure SetActive(const Value: Boolean);
    procedure ActivateLog;
    procedure DeActivateLog;
    procedure ActivateFileLog;
    procedure SetFieldDelimiter(AValue: String);
    procedure SetFilePostfix(AValue: String);
    procedure SetFilePrefix(AValue: String);
    procedure WriteFileLog(const Msg: String);
    procedure DeActivateFileLog;
  Protected
    Procedure CheckInactive;
    function CheckForNewLogFile: Boolean;
    Procedure EnsureActive;
    procedure CloseAndCreateNewLog;
  Public
    constructor Create(AOwner: TComponent); override;
    Destructor Destroy; override;
    function GetFileNameFromDate(ADate: TDate): String;
    Procedure Pause;
    Procedure Resume;
    Procedure Log (const Msg : String);
    procedure Log(const Fmt: String; Args: array of const);
    procedure Log(AFields: array of String);
  Published
    Property AppendContent : Boolean Read fAppendContent Write fAppendContent;
    Property Active : Boolean Read FActive write SetActive;
    Property DefaultEventType : TEventType Read FDEfaultEventType Write FDefaultEventType;
    property Directory: String read FDirectory write FDirectory;
    property FieldDelimiter: String read FFieldDelimiter write SetFieldDelimiter;
    Property FileName : String Read GetFileName;
    property FilePrefix: String read FFilePrefix write SetFilePrefix;
    property FilePostfix: String read FFilePostfix write SetFilePostfix;
    Property TimeStampFormat : String Read FTimeStampFormat Write FTimeStampFormat;
    Property Paused : Boolean Read FPaused Write FPaused;
  End;

  ELogError = Class(Exception);

implementation

{ TtgStatLog }

Resourcestring
  SErrOperationNotAllowed = 'Operation not allowed when eventlog is active.';

procedure TtgStatLog.CheckInactive;
begin
  If Active then
    Raise ELogError.Create(SErrOperationNotAllowed);
end;

function TtgStatLog.CheckForNewLogFile: Boolean;
begin
  Result:= not SameText(FStream.FileName, GetFileName);
end;

procedure TtgStatLog.EnsureActive;
begin
  If Not Active then
    Active:=True;
end;

procedure TtgStatLog.CloseAndCreateNewLog;
begin
  DeActivateLog;
  ActivateLog;
end;

constructor TtgStatLog.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPaused:=True;
  FDirectory:='';
  FFilePostfix:='.csv';
  FFilePrefix:='~log';
  FFieldDelimiter:='; ';
  FTimeStampFormat:='';
  AppendContent:=True;
end;


procedure TtgStatLog.Pause;
begin
  Paused:=True;
end;


procedure TtgStatLog.Resume;
begin
  Paused:=False;
end;

procedure TtgStatLog.Log(const Msg: String);
begin
  If Paused then
    exit;
  EnsureActive;
  WriteFileLog(Msg);
end;

procedure TtgStatLog.WriteFileLog(const Msg : String);

Var
  S,TS: String;

begin
  if CheckForNewLogFile then
    CloseAndCreateNewLog;
  If FTimeStampFormat='' then
    FTimeStampFormat:='yyyy-mm-dd hh:nn:ss';
  TS:=FormatDateTime(FTimeStampFormat,Now);
  S:=TS+FieldDelimiter+Msg+LineEnding;
  try
    FStream.WriteBuffer(S[1],Length(S));
    S:='';
  except
    On E : Exception do
      S:=E.Message;
  end;
end;

procedure TtgStatLog.Log(const Fmt: String; Args: array of const);
begin
  Log(Format(Fmt,Args));
end;

procedure TtgStatLog.Log(AFields: array of String);
var
  i: Integer;
  S: String;
begin
  S:='';
  for i:=0 to Length(AFields)-1 do
    S+=AFields[i]+FieldDelimiter;
  Log(S);
end;

procedure TtgStatLog.SetActive(const Value: Boolean);
begin
  If Value<>FActive then
    begin
    If Value then
      ActivateLog
    else
      DeActivateLog;
    FActive:=Value;
    end;
end;

function TtgStatLog.GetFileName: String;
begin
  Result:=GetFileNameFromDate(Date);
end;

procedure TtgStatLog.ActivateLog;

begin
  ActivateFileLog;
end;

procedure TtgStatLog.DeActivateLog;

begin
    DeActivateFileLog;
end;

procedure TtgStatLog.ActivateFileLog;
var
  fFileFlags : Word;
  AFileName: String;
begin
  AFileName:=GetFileName;
  if fAppendContent and FileExists(AFileName) then
    fFileFlags := fmOpenWrite
  else
    fFileFlags := fmCreate;

  fFileFlags := fFileFlags or fmShareDenyWrite;
  FStream:=TFileStream.Create(AFileName,fFileFlags);
  if fAppendContent then
    FStream.Seek(0,soFromEnd);
end;

procedure TtgStatLog.SetFieldDelimiter(AValue: String);
begin
  if FFieldDelimiter=AValue then Exit;
  FFieldDelimiter:=AValue;
end;

procedure TtgStatLog.SetFilePostfix(AValue: String);
begin
  if FFilePostfix=AValue then Exit;
  FFilePostfix:=AValue;
end;

procedure TtgStatLog.DeActivateFileLog;

begin
  FStream.Free;
  FStream:=Nil;
end;

function TtgStatLog.GetFileNameFromDate(ADate: TDate): String;
begin
  Result:=Directory+FilePrefix+FormatDateTime('yyyymmdd', ADate)+FilePostfix;
end;

procedure TtgStatLog.SetFilePrefix(AValue: String);
begin
  if FFilePrefix=AValue then Exit;
  FFilePrefix:=AValue;
end;

destructor TtgStatLog.Destroy;
begin
  Active:=False;
  inherited;
end;

end.
