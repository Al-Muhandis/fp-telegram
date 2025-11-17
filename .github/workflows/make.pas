//castle-engine.io/modern_pascal

program Make;
{$mode objfpc}{$H+}

uses
  Classes,
  SysUtils,
  StrUtils,
  FileUtil,
  LazFileUtils,
  Zipper,
  fphttpclient,
  RegExpr,
  openssl,
  LazUTF8,
  opensslsockets,
  eventlog,
  Process;

  function OutLog(const Knd: TEventType; const Msg: string): string; cdecl;
  begin
    case Knd of
      etError: OutLog := #27'[31m%s'#27'[0m';
      etInfo:  OutLog := #27'[32m%s'#27'[0m';
      etDebug: OutLog := #27'[33m%s'#27'[0m';
    end;
    if Knd = etError then
        ExitCode += 1;
    Writeln(stderr, UTF8ToConsole(OutLog.Format([Msg])));
  end;

  function SelectString(const Input, Reg: string): string; cdecl;
  var
    Line: string;
  begin
    SelectString := EmptyStr;
    with TRegExpr.Create do
    begin
      Expression := Reg;
      for Line in Input.Split(LineEnding) do
        if Exec(Line) then
          SelectString += Line + LineEnding;
      Free;
    end;
  end;

  function AddPackage(const Path: string): string; cdecl;
  begin
    AddPackage :=
      {$IFDEF MSWINDOWS}
        '(cocoa|x11|_template)'
      {$ELSE}
        '(cocoa|gdi|_template)'
      {$ENDIF}
    ;
    if SelectString(Path, AddPackage) = EmptyStr then
      if RunCommand('lazbuild', ['--add-package-link', Path], AddPackage, [poStderrToOutPut]) then
        OutLog(etDebug, 'Add package:'#9 + Path)
      else
        OutLog(etError, AddPackage);
  end;

  function ConsoleTestRunner(const Path: String): string; cdecl;
  begin
    OutLog(etDebug, #9'Run test:'#9 + Path);
    if not RunCommand(Path, ['--all', '--format=plain'], ConsoleTestRunner, [poStderrToOutPut]) then
      OutLog(etError, ConsoleTestRunner);
  end;

  function AddLibrary(const Path: String): string; cdecl;
  const
    LibPath: string = '/usr/lib/';
  begin
    OutLog(etDebug, #9'Add lib:'#9 + Path);
    if not FileExists(LibPath + ExtractFileName(Path)) and not RunCommand('sudo', ['cp', Path, LibPath, ';',  'ldconfig'], AddLibrary, [poStderrToOutPut]) then
        OutLog(etError, AddLibrary);
  end;

  function BuildProject(const Path: string): string; cdecl;
  var
    Text: string;
  begin
    OutLog(etDebug, 'Build from:'#9 + Path);
    if RunCommand('lazbuild',
      ['--build-all', '--recursive', '--no-write-project', Path], BuildProject, [poStderrToOutPut, poWaitOnExit]) then
    begin
      BuildProject := SelectString(BuildProject, 'Linking').Split(' ')[2].Replace(LineEnding, EmptyStr);
      OutLog(etInfo, #9'to:'#9 + BuildProject);
      Text := ReadFileToString(Path.Replace('.lpi', '.lpr'));
      if Text.Contains('program') and Text.Contains('consoletestrunner') then
        ConsoleTestRunner(BuildProject)
      else if Text.Contains('library') and Text.Contains('exports') then
        AddLibrary(BuildProject)
    end
    else
      OutLog(etError, SelectString(BuildProject, '(Fatal|Error):'));
  end;

  function DownloadFile(const Uri: string): string; cdecl;
  var
    FileStream: TStream;
  begin
    InitSSLInterface;
    DownloadFile := GetTempFileName;
    FileStream := TFileStream.Create(DownloadFile, fmCreate or fmOpenWrite);
    with TFPHttpClient.Create(nil) do
    begin
      try
        AddHeader('User-Agent', 'Mozilla/5.0 (compatible; fpweb)');
        AllowRedirect := True;
        Get(Uri, FileStream);
        OutLog(etDebug, 'Download from'#9 + Uri + #9'to'#9 + DownloadFile);
      finally
        Free;
        FileStream.Free;
      end;
    end;
  end;

  procedure UnZip(const ZipFile, ZipPath: string); cdecl;
  begin
    with TUnZipper.Create do
    begin
      try
        FileName := ZipFile;
        OutputPath := ZipPath;
        Examine;
        UnZipAllFiles;
        OutLog(etDebug, 'Unzip from'#9 + ZipFile + #9'to'#9 + ZipPath);
        DeleteFile(ZipFile);
      finally
        Free;
      end;
    end;
  end;

  function InstallOPM(const Path: string): string; cdecl;
  begin
    InstallOPM :=
      {$IFDEF MSWINDOWS}
      GetEnvironmentVariable('APPDATA')
      {$ELSE}
      GetEnvironmentVariable('HOME')
      {$ENDIF}
      + '/.lazarus/onlinepackagemanager/packages/'.Replace('/', DirectorySeparator)
      + Path;
    if not DirectoryExists(InstallOPM) and ForceDirectories(InstallOPM) then
        UnZip(DownloadFile('https://packages.lazarus-ide.org/' + Path + '.zip'), InstallOPM);
  end;

  function BuildAll(const Dependencies: array of string): string;
  var
    List: TStringList;
    DT: TDateTime;
  begin
    // INSTALL-ENVIRONMENTS
    DT := Time;
    if FileExists('.gitmodules') then
      if not RunCommand('git', ['submodule', 'update', '--init', '--recursive',
        '--force', '--remote'], BuildAll, [poStderrToOutPut]) then
        OutLog(etError, BuildAll);
    // INSTALL-PACKAGES
    List := FindAllFiles(GetCurrentDir, '*.lpk');
    try
      for BuildAll in Dependencies do
        List.AddStrings(FindAllFiles(InstallOPM(BuildAll), '*.lpk'));
      List.Sort;
      for BuildAll in List do
        AddPackage(BuildAll);
      // BUILD-PROJECTS
      List := FindAllFiles(GetCurrentDir, '*.lpi');
      List.Sort;
      for BuildAll in List do
        if not BuildAll.Contains(DirectorySeparator + 'use' + DirectorySeparator) then
          BuildProject(BuildAll);
    finally
      List.Free;
    end;
    OutLog(etDebug, 'Duration:'#9'%s'#10'Errors:'#9'%s'.Format(
      [FormatDateTime('hh:nn:ss', Time - DT), ExitCode.ToString]
    ));
  end;

//-------------------------------------------------------------------------------
// MAIN ENDPOINT
//-------------------------------------------------------------------------------

begin
  try
    if ParamCount > 0 then
      case ParamStr(1) of
        'build': BuildAll([]);
        else
          OutLog(etError, ParamStr(1));
      end;
  except
    on E: Exception do
      OutLog(etError, E.ClassName + #9 + E.Message);
  end;
end.
