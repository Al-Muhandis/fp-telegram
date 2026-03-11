program tgpclocker;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads, Unix, xlib, x, CairoXlib,
  {$ENDIF}
  Classes, SysUtils, CustApp, process, tgsendertypes, tgtypes, Cairo;

type

  { TMyApplication }

  TMyApplication = class(TCustomApplication)
  protected
    fbot:TTelegramSender;
    procedure DoRun; override;
    procedure TGLockCmd(ASender: TObject; const ACommand: String; AMessage: TTelegramMessageObj);
    procedure TGUnlockCmd(ASender: TObject; const ACommand: String; AMessage: TTelegramMessageObj);
    procedure TGScreenshotCmd(ASender: TObject; const ACommand: String; AMessage: TTelegramMessageObj);
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
  end;

const
  API_TOKEN = 'BotToken'; //TODO: fill with your bot API
  AuthorizedSender = 1234567890; //PC owner ID; TODO: fill with the ID of the user allower do lock/unlock PC remotely

{ TMyApplication }

procedure TMyApplication.DoRun;
begin
  while not Terminated do begin
    fbot.getUpdatesEx(0,0);
  end;
end;

procedure TMyApplication.TGLockCmd(ASender: TObject; const ACommand: String;
  AMessage: TTelegramMessageObj);
var
  ec: Integer;
begin
  if AMessage.From.ID = AuthorizedSender then begin
    ec:=ExecuteProcess('/usr/bin/cinnamon-screensaver-command', ['--lock']);
    fbot.sendMessage(AMessage.ChatId,'Lock command exited with code '+ec.ToString,pmDefault,false,nil,AMessage.MessageId);
  end;
end;

procedure TMyApplication.TGUnlockCmd(ASender: TObject; const ACommand: String;
  AMessage: TTelegramMessageObj);
var
  ec: Integer;
begin
  if AMessage.From.ID = AuthorizedSender then begin
    ec:=ExecuteProcess('/usr/bin/loginctl', ['unlock-session']);
    fbot.sendMessage(AMessage.ChatId,'Lock command exited with code '+ec.ToString,pmDefault,false,nil,AMessage.MessageId);
  end;
end;

procedure TMyApplication.TGScreenshotCmd(ASender: TObject;
  const ACommand: String; AMessage: TTelegramMessageObj);
var
  display: PDisplay;
  root: TWindow;
  scr: cint;
  surface: Pcairo_surface_t;
  fn: String;
begin
  fn:='/tmp/tgpclocker_'+GetProcessID.ToString+'.png';
  display := XOpenDisplay(nil);
  try
    root := DefaultRootWindow(display);
    scr := DefaultScreen(display);

    surface := cairo_xlib_surface_create(display,
                                         root,
                                         DefaultVisual(display, scr),
                                         DisplayWidth(display, scr),
                                         DisplayHeight(display, scr));


      cairo_surface_write_to_png(surface, pchar(fn));
      cairo_surface_destroy(surface);

      fbot.sendPhotoByFileName(AMessage.ChatId, fn, '', pmDefault, nil, AMessage.MessageId);
  finally
    XCloseDisplay(display);
  end;
end;

constructor TMyApplication.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  fbot:=TTelegramSender.Create(API_TOKEN);
  fbot.Timeout:=2000;
  fbot.CommandHandlers['/lock']       := @TGLockCmd;
  fbot.CommandHandlers['/unlock']     := @TGUnlockCmd;
  fbot.CommandHandlers['/screenshot'] := @TGScreenshotCmd;
  StopOnException:=True;
end;

destructor TMyApplication.Destroy;
begin
  inherited Destroy;
end;

var
  Application: TMyApplication;
begin
  Application:=TMyApplication.Create(nil);
  Application.Title:='My Application';
  Application.Run;
  Application.Free;
end.

