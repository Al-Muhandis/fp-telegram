program gui_synapse;

{$mode objfpc}{$H+}

uses
  Interfaces, Forms, GuiTestRunner, testtelegram, testtgtypes, testsendertypes,
  testtgutils, testsendermock, tgsynapsehttpclientbroker
  ;

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TGuiTestRunner, TestRunner);
  Application.Run;
end.

