unit tgfclhttpclientbroker;

{$mode objfpc}{$H+}

interface

{$IF FPC_FULLVERSION < 30200}{$DEFINE ExplSSL}{$else}{$DEFINE SSLOpenSockets}{$ENDIF}

uses
  Classes, SysUtils{$IFDEF ExplSSL}, ssockets{$ENDIF}, tgbasehttpclient, fphttpclient;

type

  { TFCLHTTPClient }

  TFCLHTTPClient=class(TBaseHTTPClient)
  private
    FHTTPClient: TFPHTTPClient;
    procedure PrepareHeaders;   {$IFDEF ExplSSL}
    procedure HttpClientGetSocketHandler(Sender: TObject; const {%H-}UseSSL: Boolean;
      out {%H-}AHandler: TSocketHandler);{$ENDIF}
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
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    class function EncodeUrlElement(S: String): String; override;
    procedure FileFormPost(const AURL: string; FormData: TStrings; AFieldName, AFileName: string;
      const Response: TStream); override;    
    function FilesFormPost(const AURL: string; FormData: TStrings; const AFiles: TStrings): String; override;
    function StreamsFormPost(const AURL: string; FormData: TStrings; const AFiles: TStrings): String; override;
    function FormPost(const URL: string; FormData: TStrings): String; override;
    function Get(const AUrl: String): String; override;
    function Post(const URL: string): String; override;
    procedure StreamFormPost(const AURL: string; FormData: TStrings; const AFieldName,
      AFileName: string; const AStream: TStream; const Response: TStream); override;
  end;

{$IF FPC_FULLVERSION <= 30004}
{ TRawByteStringStream }

  TRawByteStringStream = Class(TBytesStream)
  public
    Constructor Create (const aData : RawByteString); overload;
    function DataString: RawByteString;

    function ReadString(Count: Longint): RawByteString;
    procedure WriteString(const AString: RawByteString);
  end;
{$ENDIF}

implementation

uses
  {$IFDEF ExplSSL}sslsockets, fpopenssl{$ENDIF}
  {$IFDEF SSLOpenSockets}opensslsockets{$endif}
  ;

Const
  CRLF = #13#10;

{$IF FPC_FULLVERSION <= 30004}
{ TRawByteStringStream }

constructor TRawByteStringStream.Create(const aData: RawByteString);
begin
  Inherited Create;
  If Length(aData)>0 then
    begin
    WriteBuffer(aData[1],Length(aData));
    Position:=0;
    end;
end;

function TRawByteStringStream.DataString: RawByteString;
begin
  Result:='';
  SetLength(Result,Size);
  if Size>0 then
    Move(Memory^, Result[1], Size);
end;

function TRawByteStringStream.ReadString(Count: Longint): RawByteString;
Var
  NewLen : Longint;

begin
  NewLen:=Size-Position;
  If NewLen>Count then NewLen:=Count;
  Result:='';
  if NewLen>0 then
    begin
    SetLength(Result, NewLen);
    Move(Bytes[Position],Result[1],NewLen);
    Position:=Position+Newlen;
    end;
end;

procedure TRawByteStringStream.WriteString(const AString: RawByteString);
begin
  if Length(AString)>0 then
    WriteBuffer(AString[1],Length(AString));
end;
{$ENDIF}

{ TFCLHTTPClient }

function TFCLHTTPClient.FilesFormPost(const AURL: string; FormData: TStrings; const AFiles: TStrings): String;
Var
  S, Sep : string;
  SS : TRawByteStringStream;
  I: Integer;
  N,V, aFieldName, aFileName: String;
  F: TFileStream;
begin
  Sep:=Format('%.8x_multipart_boundary',[Random($ffffff)]);
  AddHeader('Content-Type','multipart/form-data; boundary='+Sep);
  SS:=TRawByteStringStream.Create();
  try
    if (FormData<>Nil) then
      for I:=0 to FormData.Count -1 do
        begin
        // not url encoded
        FormData.GetNameValue(I,N,V);
        S :='--'+Sep+CRLF;
        S:=S+Format('Content-Disposition: form-data; name="%s"'+CRLF+CRLF+'%s'+CRLF,[N, V]);
        SS.WriteBuffer(S[1],Length(S));
        end;
    if (AFiles<>Nil) then
      for I:=0 to AFiles.Count-1 do
        begin             
          AFiles.GetNameValue(I,aFieldName,aFileName);
          S:='--'+Sep+CRLF;
          s:=s+Format('Content-Disposition: form-data; name="%s"; filename="%s"'+CRLF,
            [aFieldName,ExtractFileName(aFileName)]);
          s:=s+'Content-Type: application/octet-string'+CRLF+CRLF;
          SS.WriteBuffer(S[1],Length(S));
          F:=TFileStream.Create(aFileName,fmOpenRead or fmShareDenyWrite);
          try
            F.Seek(0, soFromBeginning);
            SS.CopyFrom(F,F.Size);
            S:=CRLF;
            SS.WriteBuffer(S[1],Length(S));
          finally
            F.Free;
          end;
        end;

    S:='--'+Sep+'--'+CRLF;
    SS.WriteBuffer(S[1],Length(S));
    SS.Position:=0;
    RequestBody:=SS;
    Result:=Post(AURL);
  finally
    RequestBody:=Nil;
    SS.Free;
  end;
end;

function TFCLHTTPClient.StreamsFormPost(const AURL: string; FormData: TStrings;
  const AFiles: TStrings): String;
Var
  S, Sep : string;
  SS : TRawByteStringStream;
  I: Integer;
  N,V, aFieldName, aFileName: String;
  F: TStream;
begin
  Sep:=Format('%.8x_multipart_boundary',[Random($ffffff)]);
  AddHeader('Content-Type','multipart/form-data; boundary='+Sep);
  SS:=TRawByteStringStream.Create();
  try
    if (FormData<>Nil) then
      for I:=0 to FormData.Count -1 do
        begin
        // not url encoded
        FormData.GetNameValue(I,N,V);
        S :='--'+Sep+CRLF;
        S:=S+Format('Content-Disposition: form-data; name="%s"'+CRLF+CRLF+'%s'+CRLF,[N, V]);
        SS.WriteBuffer(S[1],Length(S));
        end;
    if (AFiles<>Nil) then
      for I:=0 to AFiles.Count-1 do
        begin
          if not (AFiles.Objects[i] is TStream) then continue;
          AFiles.GetNameValue(I,aFieldName,aFileName);
          S:='--'+Sep+CRLF;
          s:=s+Format('Content-Disposition: form-data; name="%s"; filename="%s"'+CRLF,
            [aFieldName,ExtractFileName(aFileName)]);
          s:=s+'Content-Type: application/octet-string'+CRLF+CRLF;
          SS.WriteBuffer(S[1],Length(S));
          F:=AFiles.Objects[i] as TStream;
          F.Seek(0, soFromBeginning);
          SS.CopyFrom(F,F.Size);
          S:=CRLF;
          SS.WriteBuffer(S[1],Length(S));
        end;

    S:='--'+Sep+'--'+CRLF;
    SS.WriteBuffer(S[1],Length(S));
    SS.Position:=0;
    RequestBody:=SS;
    Result:=Post(AURL);
  finally
    RequestBody:=Nil;
    SS.Free;
  end;
end;

procedure TFCLHTTPClient.PrepareHeaders;
begin
  FHTTPClient.AddHeader('User-Agent', UserAgent);
end;
{$IFDEF ExplSSL}
procedure TFCLHTTPClient.HttpClientGetSocketHandler(Sender: TObject;
  const UseSSL: Boolean; out AHandler: TSocketHandler);
begin
  {$IFDEF LINUX}
    if UseSSL then begin
      AHandler:=TSSLSocketHandler.Create;
      TSSLSocketHandler(AHandler).SSLType:=stTLSv1_2;  // <--
    end;
  {$ENDIF}
end;
{$ENDIF}
function TFCLHTTPClient.GetAllowRedirect: Boolean;
begin
  Result:=FHTTPClient.AllowRedirect;
end;

function TFCLHTTPClient.GetCookies: TStrings;
begin
  Result:=FHTTPClient.Cookies;
end;

function TFCLHTTPClient.GetHTTPProxyHost: String;
begin
  Result:=FHTTPClient.Proxy.Host;
end;

function TFCLHTTPClient.GetHTTPProxyPassword: String;
begin
  Result:=FHTTPClient.Proxy.Password;
end;

function TFCLHTTPClient.GetHTTPProxyPort: Word;
begin
  Result:=FHTTPClient.Proxy.Port;
end;

function TFCLHTTPClient.GetHTTPProxyUsername: String;
begin
  Result:=FHTTPClient.Proxy.UserName;
end;

function TFCLHTTPClient.GetInternalHTTPClient: TObject;
begin
  Result:=FHTTPClient;
end;

function TFCLHTTPClient.GetIOTimeout: Integer;
begin
  Result:=FHTTPClient.IOTimeout;
end;

function TFCLHTTPClient.GetRequestBody: TStream;
begin
  Result:=FHTTPClient.RequestBody;
end;

function TFCLHTTPClient.GetRequestHeaders: TStrings;
begin
  Result:=FHTTPClient.RequestHeaders;
end;

function TFCLHTTPClient.GetResponseHeaders: TStrings;
begin
  Result:=FHTTPClient.ResponseHeaders;
end;

function TFCLHTTPClient.GetResponseStatusCode: Integer;
begin
  Result:=FHTTPClient.ResponseStatusCode;
end;

function TFCLHTTPClient.GetResponseStatusText: String;
begin
  Result:=FHTTPClient.ResponseStatusText;
end;

procedure TFCLHTTPClient.SetAllowRedirect(AValue: Boolean);
begin
  FHTTPClient.AllowRedirect:=AValue;
end;

procedure TFCLHTTPClient.SetCookies(AValue: TStrings);
begin
  FHTTPClient.Cookies:=AValue;
end;

procedure TFCLHTTPClient.SetHTTPProxyHost(AValue: String);
begin
  FHTTPClient.Proxy.Host:=AValue;
end;

procedure TFCLHTTPClient.SetHTTPProxyPassword(AValue: String);
begin
  FHTTPClient.Proxy.Password:=AValue;
end;

procedure TFCLHTTPClient.SetHTTPProxyPort(AValue: Word);
begin
  FHTTPClient.Proxy.Port:=AValue;
end;

procedure TFCLHTTPClient.SetHTTPProxyUsername(AValue: String);
begin
  FHTTPClient.Proxy.UserName:=AValue;
end;

procedure TFCLHTTPClient.SetIOTimeout(AValue: Integer);
begin
  FHTTPClient.IOTimeout:=AValue;
end;

procedure TFCLHTTPClient.SetRequestBody(AValue: TStream);
begin
  FHTTPClient.RequestBody:=AValue;
end;

procedure TFCLHTTPClient.SetRequestHeaders(AValue: TStrings);
begin
  FHTTPClient.RequestHeaders:=AValue;
end;

procedure TFCLHTTPClient.AddHeader(const AHeader, AValue: String);
begin
  FHTTPClient.AddHeader(AHeader, AValue);
end;

constructor TFCLHTTPClient.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FHTTPClient:=TFPHTTPClient.Create(AOwner);
  // FCL defaults are infinite (IOTimeout=0, ConnectTimeout unset).
  FHTTPClient.IOTimeout:=15000;
  FHTTPClient.ConnectTimeout:=10000;
  {$IFDEF ExplSSL}FHTTPClient.OnGetSocketHandler:=@HttpClientGetSocketHandler;{$ENDIF}
end;

destructor TFCLHTTPClient.Destroy;
begin
  FreeAndNil(FHTTPClient);
  inherited Destroy;
end;

class function TFCLHTTPClient.EncodeUrlElement(S: String): String;
begin
  Result:=fphttpclient.EncodeURLElement(S);
end;

procedure TFCLHTTPClient.FileFormPost(const AURL: string; FormData: TStrings; AFieldName,
  AFileName: string; const Response: TStream);
begin
  FHTTPClient.FileFormPost(AURL, FormData, AFieldName, AFileName, Response);
end;

function TFCLHTTPClient.FormPost(const URL: string; FormData: TStrings
  ): String;
begin
  PrepareHeaders;
  Result:=FHTTPClient.FormPost(URL, FormData);
end;

function TFCLHTTPClient.Get(const AUrl: String): String;
begin
  PrepareHeaders;
  Result:=FHTTPClient.Get(AUrl);
end;

function TFCLHTTPClient.Post(const URL: string): String;
begin
  PrepareHeaders;
  Result:=FHTTPClient.Post(URL);
end;

procedure TFCLHTTPClient.StreamFormPost(const AURL: string; FormData: TStrings; const AFieldName,
  AFileName: string; const AStream: TStream; const Response: TStream);
begin
  FHTTPClient.StreamFormPost(AURL, FormData, AFieldName, AFileName, AStream, Response);
end;

initialization
  TFCLHTTPClient.UnregisterClientClass;
  TFCLHTTPClient.RegisterClientClass;

end.

