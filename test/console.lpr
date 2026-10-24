program console;

{$mode objfpc}{$H+}

uses
  Classes, consoletestrunner, testtelegram, testtgtypes, testsendertypes,
  testtgutils, testsendermock, tgfclhttpclientbroker;

type

  { TMyTestRunner }

  TMyTestRunner = class(TTestRunner)
  protected
  // override the protected methods of TTestRunner to customize its behavior
  end;

var
  Application: TMyTestRunner;

begin
  Application := TMyTestRunner.Create(nil);
  Application.Initialize;
  Application.Title:='console';
  Application.Run;
  Application.Free;
end.
