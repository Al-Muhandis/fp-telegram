unit testtgutils;

{
  Unit tests for the tgutils unit (text helpers) and the tgstatlog unit
  (the statistics logger). No network activity.
}

{$mode objfpc}{$H+}
{$codepage UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fpjson, tgtypes, tgsendertypes,
  tgutils, tgstatlog;

type

  { TTestTgUtils }

  TTestTgUtils = class(TTestCase)
  published
    procedure MarkdownEscapeTest;
    procedure MarkdownEscapeV2Test;
    procedure BuildLinkTest;
    procedure UserLinkTest;
    procedure CaptionFromUserTest;
    procedure CaptionFromChatTest;
  end;

  { TTestTgStatLog }

  TTestTgStatLog = class(TTestCase)
  private
    FDir: String;
    FLog: TtgStatLog;
    procedure DeleteTempDir;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure LogWritesToFile;
    procedure PausedLogWritesNothing;
    procedure LogFieldsUsesDelimiter;
    procedure FileNameContainsDate;
  end;

implementation

{ TTestTgUtils }

procedure TTestTgUtils.MarkdownEscapeTest;
begin
  AssertEquals('plain', MarkdownEscape('plain'));
  AssertEquals('C:+dir \*\_\`x\`', MarkdownEscape('C:+dir *_`x`'));
end;

procedure TTestTgUtils.MarkdownEscapeV2Test;
begin
  AssertEquals('plain', MarkdownEscapeV2('plain'));
  AssertEquals('a\_b\*c\[d\] \(e\) \~f\`g\>h\#i\+j\-k\=l\|m\{n\}o\.p\!q',
    MarkdownEscapeV2('a_b*c[d] (e) ~f`g>h#i+j-k=l|m{n}o.p!q'));
end;

procedure TTestTgUtils.BuildLinkTest;
begin
  AssertEquals('https://example.com', BuildLink('caption', 'https://example.com'));
  AssertEquals('[caption](https://example.com)',
    BuildLink('caption', 'https://example.com', pmMarkdown));
  AssertEquals('<a href="https://example.com">caption</a>',
    BuildLink('caption', 'https://example.com', pmHTML));
end;

procedure TTestTgUtils.UserLinkTest;
begin
  AssertEquals('tg://user?id=123456789', UserLink(123456789));
end;

procedure TTestTgUtils.CaptionFromUserTest;
var
  lJSON: TJSONObject;
  lUser: TTelegramUserObj;
begin
  lJSON:=TJSONObject.Create;
  try
    lJSON.Add('id', 99);
    lJSON.Add('is_bot', False);
    lJSON.Add('first_name', 'Bob');
    lJSON.Add('last_name', 'Smith');
    lJSON.Add('username', 'bob');
    lUser:=TTelegramUserObj.Create(lJSON);
    try
      AssertEquals('Bob Smith @bob', CaptionFromUser(lUser));
    finally
      lUser.Free;
    end;
  finally
    lJSON.Free;
  end;
end;

procedure TTestTgUtils.CaptionFromChatTest;
var
  lJSON: TJSONObject;
  lChat: TTelegramChatObj;
begin
  lJSON:=TJSONObject.Create;
  try
    lJSON.Add('id', -100123);
    lJSON.Add('type', 'supergroup');
    lJSON.Add('title', 'Group title');
    lChat:=TTelegramChatObj.Create(lJSON);
    try
      AssertEquals('Group title', CaptionFromChat(lChat));
    finally
      lChat.Free;
    end;
  finally
    lJSON.Free;
  end;
end;

{ TTestTgStatLog }

procedure TTestTgStatLog.DeleteTempDir;
var
  lSR: TSearchRec;
begin
  if FindFirst(FDir+AllFilesMask, faAnyFile, lSR)=0 then
  begin
    repeat
      if (lSR.Attr and faDirectory)=0 then
        DeleteFile(FDir+lSR.Name);
    until FindNext(lSR)<>0;
    FindClose(lSR);
  end;
  RemoveDir(ExcludeTrailingPathDelimiter(FDir));
end;

procedure TTestTgStatLog.SetUp;
begin
  inherited SetUp;
  FDir:=IncludeTrailingPathDelimiter(SysUtils.GetTempDir(False))+
    'fptg-test-stat-'+IntToStr(Random(1000000))+DirectorySeparator;
  ForceDirectories(FDir);
  FLog:=TtgStatLog.Create(nil);
  FLog.Directory:=FDir;
  FLog.Resume; // a fresh TtgStatLog is paused by default
end;

procedure TTestTgStatLog.TearDown;
begin
  FLog.Free;
  DeleteTempDir;
  inherited TearDown;
end;

procedure TTestTgStatLog.LogWritesToFile;
var
  lLines: TStringList;
begin
  FLog.Log('hello');
  AssertTrue('Log file created', FileExists(FLog.FileName));
  FLog.Active:=False; // release the log stream before reading the file
  lLines:=TStringList.Create;
  try
    lLines.LoadFromFile(FLog.FileName);
    AssertEquals(1, lLines.Count);
    AssertTrue('Line contains the message', Pos('hello', lLines[0])>0);
    AssertTrue('Line contains the timestamp', Pos(FLog.FieldDelimiter, lLines[0])>0);
  finally
    lLines.Free;
  end;
end;

procedure TTestTgStatLog.PausedLogWritesNothing;
var
  lLines: TStringList;
begin
  FLog.Log('first');
  FLog.Pause;
  FLog.Log('second');
  FLog.Active:=False; // release the log stream before reading the file
  lLines:=TStringList.Create;
  try
    lLines.LoadFromFile(FLog.FileName);
    AssertEquals(1, lLines.Count);
    AssertTrue('Only the message written before pausing is stored',
      (Pos('first', lLines[0])>0) and (Pos('second', lLines[0])=0));
  finally
    lLines.Free;
  end;
end;

procedure TTestTgStatLog.LogFieldsUsesDelimiter;
var
  lLines: TStringList;
begin
  FLog.Log(['a', 'b', 'c']);
  FLog.Active:=False; // release the log stream before reading the file
  lLines:=TStringList.Create;
  try
    lLines.LoadFromFile(FLog.FileName);
    AssertEquals(1, lLines.Count);
    AssertTrue('Fields are joined with the delimiter',
      Pos('a'+FLog.FieldDelimiter+'b'+FLog.FieldDelimiter+'c', lLines[0])>0);
  finally
    lLines.Free;
  end;
end;

procedure TTestTgStatLog.FileNameContainsDate;
begin
  AssertEquals(FDir+FLog.FilePrefix+FormatDateTime('yyyymmdd', Date)+FLog.FilePostfix,
    FLog.FileName);
  AssertEquals(FDir+FLog.FilePrefix+'20240115'+FLog.FilePostfix,
    FLog.GetFileNameFromDate(EncodeDate(2024, 1, 15)));
end;

initialization
  RegisterTest(TTestTgUtils);
  RegisterTest(TTestTgStatLog);

end.
