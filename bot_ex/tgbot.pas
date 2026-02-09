unit tgbot;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, tgsendertypes, tgstatlog, tgtypes
  ;

type
  TCallbackHandlersMap = specialize TStringHashMap<TCallbackEvent>;
  TReceiveDeepLinkEvent = procedure (const AParameter: String) of object;
  TUserStatus = (usAdmin, usModerator, usDefault, usBanned);

  { TTelegramBot }
  TTelegramBot = class(TTelegramSender)
  private
    FAutoTranslate: Boolean;
    FCallbackAnswered: Boolean;
    FCallbackHandlers: TCallbackHandlersMap;
    FHelpText: String;

    FFeedbackText: String;
    FFeedbackThanks: String;
    //FOnRate: TRateEvent;
    FOnReceiveDeepLinking: TReceiveDeepLinkEvent;

    FPublicStat: Boolean;
    FStartText: String;
    FStatLogger: TtgStatLog;
    FUserPermissions: TStringList;
    procedure BrowseStatFile(aDate: TDate; var Msg: String; ReplyMarkup: TReplyMarkup; Offset: Integer);
    class procedure CalculateStat4Strings(aStatFile: TStrings; IDs: TIntegerHashSet;
      var aEvents: Integer);
    procedure DoCallbackQueryStat(ACallbackQuery: TCallbackQueryObj; SendFile: Boolean = False);
    procedure DoCallbackQueryGetUsers(ACallbackQuery: TCallbackQueryObj);
    procedure DoGetStat(aFromDate: TDate = 0; aToDate: TDate = 0; Scroll: Boolean = False; Offset: Integer = 0);
    procedure DoGetUsers(aFromDate: TDate = 0; aToDate: TDate = 0);
    procedure DoGetStatMonth(aYear, aMonth: Word);
    procedure DoGetStatFile(ADate: TDate = 0);
    procedure DoStat(const SDate: String; const SOffset: String = ''; SendFile: Boolean = false);
    procedure DoUsers(const SDate: String);
    function GetCallbackHandlers(const Command: String): TCallbackEvent;
    function GetUserStatus(ID: Int64): TUserStatus;
    procedure SendStatLog(ADate: TDate = 0; AReplyMarkup: TReplyMarkup = nil);
    procedure SetCallbackHandlers(const Command: String; AValue: TCallbackEvent
      );
    procedure SetCommandReply({%H-}ASender: TObject; const ACommand: String;
      AMessage: TTelegramMessageObj);
    procedure SetOnReceiveDeepLinking(AValue: TReceiveDeepLinkEvent);
    procedure SetPublicStat(AValue: Boolean);
    procedure SetUserStatus(ID: Int64; AValue: TUserStatus);
    procedure TlgrmStartHandler({%H-}ASender: TObject; const {%H-}ACommand: String;
      {%H-}AMessage: TTelegramMessageObj);
    procedure TlgrmHelpHandler({%H-}ASender: TObject; const {%H-}ACommand: String;
      {%H-}AMessage: TTelegramMessageObj);
    procedure TlgrmFeedback({%H-}ASender: TObject; const {%H-}ACommand: String;
      {%H-}AMessage: TTelegramMessageObj);
    procedure TlgrmStatHandler({%H-}ASender: TObject;
      const {%H-}ACommand: String; AMessage: TTelegramMessageObj);
    procedure TlgrmStatFHandler({%H-}ASender: TObject;
      const {%H-}ACommand: String; AMessage: TTelegramMessageObj);
    procedure SendStatInlineKeyboard(SendFile: Boolean = False);
    procedure StatLog(const AMessage: String; UpdateType: TUpdateType);
  protected
    function CreateInlineKeyboardRate: TInlineKeyboard;
    function CreateInlineKeyboardStat(aFromDate, aToDate: TDate): TInlineKeyboard;
    function CreateInlineKeyboardStat(ADate: TDate; SendFile: Boolean): TInlineKeyboard; overload;
    function CreateInlineKeyboardStatFile: TInlineKeyboard;
    function CreateInlineKeyboardStatMonth(ADate: TDate): TInlineKeyboard;
    function CreateInlineKeyboardStat(ADate: TDate; Len: Integer; Offset: Integer = 0;
      Step: Integer = 20): TInlineKeyboard; overload;
    procedure DoReceiveMessageUpdate(AMessage: TTelegramMessageObj); override;
    procedure DoReceiveCallbackQuery(ACallback: TCallbackQueryObj); override;
    procedure DoReceiveChannelPost(AChannelPost: TTelegramMessageObj); override;
    procedure DoReceiveChosenInlineResult(
      AChosenInlineResult: TTelegramChosenInlineResultObj); override;
    procedure DoReceiveInlineQuery(AnInlineQuery: TTelegramInlineQueryObj); override;
    function IsAdminUser(ChatID: Int64): Boolean; override;
    function IsBanned(ChatID: Int64): Boolean; override;
    function IsBotUser(ChatID: Int64): Boolean; override;
    function IsSimpleUser(ChatID: Int64): Boolean; override;
    procedure SaveFeedback({%H-}AFrom: TTelegramUserObj; {%H-}AMessage: String); virtual;
    procedure SetLanguage(const ALang: String); override;
  public
    function answerCallbackQuery(const CallbackQueryId: String; const Text: String=''; ShowAlert: Boolean=False;
      const Url: String=''; CacheTime: Integer=0): Boolean; override;
    procedure CalculateStat(aFromDate, aToDate: TDate; out aUsers, aEvents: Integer;
      aIDs: TStrings = nil);
    constructor Create(const AToken: String);
    destructor Destroy; override;
    procedure DoReceiveDeepLinking(const AParameter: String);
    procedure EditOrSendMessage(const AMessage: String; AParseMode: TParseMode = pmDefault;
      ReplyMarkup: TReplyMarkup = nil; TryEdit: Boolean = False);    
    procedure LangTranslate(const {%H-}ALang: String);
    procedure LoadUserStatusValues(AStrings: TStrings); 
    property AutoTranslate: Boolean read FAutoTranslate write FAutoTranslate;
    property CallbackHandlers [const Command: String]: TCallbackEvent read GetCallbackHandlers
      write SetCallbackHandlers;  // It can create command handlers by assigning their to array elements
    property StartText: String read FStartText write FStartText; // Text for /start command reply
    property HelpText: String read FHelpText write FHelpText;  // Text for /help command reply
    property FeedbackText: String read FFeedbackText write FFeedbackText;
    property FeedbackThanks: String read FFeedbackThanks write FFeedbackThanks;
    property UserStatus [ID: Int64]: TUserStatus read GetUserStatus write SetUserStatus;
    //property OnRate: TRateEvent read FOnRate write SetOnRate;
    property OnReceiveDeepLinking: TReceiveDeepLinkEvent read FOnReceiveDeepLinking write SetOnReceiveDeepLinking;
    property PublicStat: Boolean read FPublicStat write SetPublicStat;
    property StatLogger: TtgStatLog read FStatLogger write FStatLogger;
  end;

function ExtractArgPart(const ASource, ACommand: String): String;
function FormatStatRec(const S: String): String;

implementation

uses      
{ Please define ni18n for excluding translate unit to uses and exclude standard po i18n support }
  tgutils, fpjson, StrUtils, DateUtils, {$IFNDEF ni18n} Translations,{$ENDIF} FileUtil
  ;

resourcestring
  str_FeedbackThanks='Thanks! %s Your message will be considered!'; // Спасибо, %s! Ваш сообщение будет обязательно рассмотрено!;
  str_FeedbackText='Send us your suggestions or bug reports please';  // Отправьте разработчику бота пожелание, рекомендацию, информацию об ошибке
  str_TxtRplyIsScsChngd='Text reply for command is succesfully changed!'; // Текст сообщения для команды успешно изменен
  str_SttstcsNtFnd='Statistics for this date not found'; // Статистика не найдено за указанный день
//  str_ErrFldTLdSttstcsFl='Error: failed to load statistics file';
  str_EntrDtInFrmt='Please enter the date in format: dd-mm-yyyy';
  str_SttstcsFr='Statistics for ';
  str_SlctSttstcs_line1='Select statistics by pressing the button. In addition, the available commands:';
  str_SlctSttstcs_line2='/stat <i>day</i> - the last records for a specified <i>date</i>, ';
  str_SlctSttstcs_line3= '/statf <i>date</i> - statistics file for the <i>date</i>,';
  str_SlctSttstcs_line4='where <i>date</i> is <i>today</i> or <i>yesterday</i> or in format <i>dd-mm-yyyy</i>';
  str_Today='Today';
  str_Yesterday='Yesterday';
  str_Monthly='Monthly';
  str_PrevDay='Prev day';
  str_NextDay='Next day';
  str_Users='Users';
  str_Prev='<';
  str_Next='>';
  str_Rate='Rate';
  //str_RateText='Please leave feedback on "Storebot" if you like our bot!';
  str_Browse='Browse';
  str_StatParseError='Stat line parser error';

const
  StatDateFormat = 'dd-mm-yyyy';
  StatMonthFormat = 'mm-yyyy';
  UserStatusChars: array [TUserStatus] of AnsiChar = ('a', 'm', 'b', '_');
  cmd_Start = '/start';
  cmd_Help = '/help';
  cmd_Stat = '/stat';
  cmd_StatF = '/statf';
  cmd_Feedback = '/feedback';
  cmd_SetStart = '/setstart';
  cmd_SetHelp = '/sethelp';
  //cmd_Rate = '/rate';
  s_Today = 'today';
  s_Yesterday = 'yesterday';
  s_GetStat='GetStat';
  s_GetUsers='GetUsers';
  s_File='File';
  s_StoreBotRate='https://telegram.me/storebot?start=';

function ExtractArgPart(const ASource, ACommand: String): String;
begin
  Result:=Trim(RightStr(ASource, Length(ASource)-Length(ACommand)));
end;

function FormatStatRec(const S: String): String;
var
  Ss: TStringList;
  l: Integer;
begin
  Ss:=TStringList.Create;
  try
    l:=ExtractStrings([';'], [' '], PChar(S), Ss, True);
    if l<>8 then
      Result:=str_StatParseError
    else
      Result:=Ss[0]+'; '+'['+Ss[1]+'](tg://user?id='+Ss[1]+') '+
        MarkdownEscape(Ss[2]+' {'+TJSONUnicodeStringType(Ss[3]+' '+Ss[4])+'}')+ ' '+
        MarkdownEscape(Ss[5])+' <'+MarkdownEscape(Ss[6])+'> '+MarkdownEscape(JSONStringToString(Ss[7]));
  except
    Result:=str_StatParseError
  end;
  Ss.Free;
end;

function TryStrToMonth(const S: String; out aYear, aMonth: Word): Boolean;
var
  i: SizeInt;
  wMonth, wYear: DWord;
begin
  i:=Pos('-', S);
  if (i<2) or (i>3) then
    Exit(False);
  if TryStrToDWord(LeftStr(S, i-1), wMonth) then
  begin
    aMonth:=wMonth;
    if not TryStrToDWord(RightStr(S, Length(S)-i), wYear) then
      aYear:=CurrentYear
    else
      aYear:=wYear;
  end
  else
    Exit(False);
  Result:=True;
end;

function AnsiCharToUserStatus(const StatusChar: String): TUserStatus;
var
  a: AnsiChar;
begin
  if StatusChar=EmptyStr then
    a:=UserStatusChars[usDefault]
  else
    a:=PAnsiChar(StatusChar)[0];
  case a of
    'a': Result:=usAdmin;
    'm': Result:=usModerator;
    'b': Result:=usBanned;
  else
    Result:=usDefault;
  end;
end;

{ TTelegramBot }

procedure TTelegramBot.SetCallbackHandlers(const Command: String;
  AValue: TCallbackEvent);
begin
  FCallbackHandlers.Items[Command]:=AValue;
end;


{ Caution! You must save this values in db or in configuration file! }
procedure TTelegramBot.SetCommandReply(ASender: TObject; const ACommand: String;
  AMessage: TTelegramMessageObj);
var
  S: String;
begin
  if not CurrentIsAdminUser then
    Exit;
  S:=ExtractArgPart(AMessage.Text, ACommand);
  if ACommand=cmd_SetStart then
    StartText:=S
  else
    if ACommand=cmd_SetHelp then
      HelpText:=S;
  sendMessage(str_TxtRplyIsScsChngd);
end;

procedure TTelegramBot.SetOnReceiveDeepLinking(AValue: TReceiveDeepLinkEvent);
begin
  if FOnReceiveDeepLinking=AValue then Exit;
  FOnReceiveDeepLinking:=AValue;
end;

procedure TTelegramBot.SetPublicStat(AValue: Boolean);
begin
  if FPublicStat=AValue then Exit;
  FPublicStat:=AValue;
end;

procedure TTelegramBot.BrowseStatFile(aDate: TDate; var Msg: String;
  ReplyMarkup: TReplyMarkup; Offset: Integer);
var
  StatFile: TStringList;
  aFileName: String;
  i: Integer;
const
  Step=20;
begin
  aFileName:=FStatLogger.GetFileNameFromDate(aDate);
  if FileExists(aFileName) then
  begin
    StatFile:=TStringList.Create;
    try
      StatFile.LoadFromFile(AFileName);
      ReplyMarkup.InlineKeyBoard:=CreateInlineKeyboardStat(aDate, StatFile.Count, Offset,
        Step);
      for i:=Offset to Offset+Step-1 do
      begin
        if i>=StatFile.Count then
          Break;
        Msg+=FormatStatRec(StatFile[i])+LineEnding;
      end;
    finally
      StatFile.Free;
    end;
  end;
end;

class procedure TTelegramBot.CalculateStat4Strings(aStatFile: TStrings; IDs: TIntegerHashSet; var aEvents: Integer);
var
  i: Integer;
  AnID: Int64;
begin
  for i:=aStatFile.Count-1 downto 0 do
  begin
    AnID:=StrToInt64Def(ExtractDelimited(2, aStatFile[i], [';']), 0);
    if AnID>0 then
    begin
      Inc(aEvents);
      IDs.insert(AnID);
    end;
  end;
end;

procedure TTelegramBot.CalculateStat(aFromDate, aToDate: TDate; out aUsers, aEvents: Integer; aIDs: TStrings);
var
  StatFile: TStringList;
  aDate: TDate;
  aFileName: String;
  IDs: TIntegerHashSet;
  aIterator: TIntegerHashSet.TIterator;
begin
  StatFile:=TStringList.Create;
  IDs:=TIntegerHashSet.create;
  aDate:=aFromDate;
  aEvents:=0;
  try
    repeat
      aFileName:=StatLogger.GetFileNameFromDate(aDate);
      if FileExists(aFileName) then
      begin
        StatFile.LoadFromFile(AFileName);
        { Simple calculation of statistics: the number of unique users per day and
          the number of received events from users (private chats) }
        CalculateStat4Strings(StatFile, IDs, aEvents);
      end;
      aDate+=1;
    until aDate>aToDate;
    aUsers:=IDs.size;
    if Assigned(aIDs) then
    begin
      aIDs.Clear;
      aIterator:=IDs.Iterator;
      try
        if IDs.IsEmpty then
          Exit;
        repeat
          aIDs.Add(aIterator.Data.ToString);
        until not aIterator.Next;
      finally
        aIterator.Free;
      end;
    end;
  finally
    StatFile.Free;
    IDs.Free;
  end;
end;

procedure TTelegramBot.DoCallbackQueryStat(ACallbackQuery: TCallbackQueryObj;
  SendFile: Boolean);
begin
  DoStat(ExtractDelimited(2, ACallbackQuery.Data, [' ']),
    ExtractDelimited(3, ACallbackQuery.Data, [' ']), SendFile);
  { After the user presses a callback button, Telegram clients will display a progress bar until
you call answerCallbackQuery. It is, therefore, necessary to react by calling answerCallbackQuery
even if no notification to the user is needed }
  RequestWhenAnswer:=False;
  answerCallbackQuery(ACallbackQuery.ID);
end;

procedure TTelegramBot.DoCallbackQueryGetUsers(ACallbackQuery: TCallbackQueryObj
  );
begin
  DoUsers(ExtractDelimited(2, ACallbackQuery.Data, [' ']));
  RequestWhenAnswer:=False;
  answerCallbackQuery(ACallbackQuery.ID);
end;

procedure TTelegramBot.DoGetStat(aFromDate: TDate; aToDate: TDate;
  Scroll: Boolean; Offset: Integer);
var
  Msg, SDate: String;
  SDate1: String;
  aEvents, aUsers: Integer;
  ReplyMarkup: TReplyMarkup;
begin
  if not CurrentIsAdminUser then
    if not PublicStat or Scroll then
      Exit;
  ReplyMarkup:=TReplyMarkup.Create;
  try
    RequestWhenAnswer:=False;
    try
      if aToDate<=aFromDate then
      begin
        DateTimeToString(SDate, 'dd-mm-yyyy', aFromDate);
        Msg:='*Statistics for '+SDate+'*'+LineEnding;
      end
      else begin
        DateTimeToString(SDate, 'dd-mm-yyyy', aFromDate);
        DateTimeToString(SDate1, 'dd-mm-yyyy', aToDate);
        Msg:='*Statistics from '+SDate+' to '+SDate1+'*'+LineEnding;
      end;
      if not Scroll then
      begin
        ReplyMarkup.InlineKeyBoard:=CreateInlineKeyboardStat(aFromDate, aToDate);
        aUsers:=0;
        aEvents:=0;
        CalculateStat(aFromDate, aToDate, aUsers, aEvents);
        Msg+=LineEnding+'Unique users: '+IntToStr(aUsers)+', user events: '+IntToStr(aEvents);
      end
      else
        BrowseStatFile(aFromDate, Msg, ReplyMarkup, Offset);
      editMessageText(Msg, pmMarkdown, True, ReplyMarkup);
    except
      on E: Exception do
        ErrorMessage('Error while get statistics: ['+E.ClassName+'] '+E.Message);
    end;
  finally
    ReplyMarkup.Free;
  end;
end;

procedure TTelegramBot.DoGetUsers(aFromDate: TDate; aToDate: TDate);
var
  Msg, SDate: String;
  SDate1: String;
  aEvents, aUsers: Integer;
  ReplyMarkup: TReplyMarkup;
  aIDs: TStringList;
  aStream: TStringStream;
begin
  if not CurrentIsAdminUser then
    Exit;
  ReplyMarkup:=TReplyMarkup.Create;
  try
    RequestWhenAnswer:=False;
    try
      if aToDate<=aFromDate then
      begin
        DateTimeToString(SDate, 'dd-mm-yyyy', aFromDate);
      end
      else begin
        DateTimeToString(SDate, 'dd-mm-yyyy', aFromDate);
        DateTimeToString(SDate1, 'dd-mm-yyyy', aToDate);
      end;
      ReplyMarkup.InlineKeyBoard:=CreateInlineKeyboardStat(aFromDate, aToDate);
      aUsers:=0;
      aEvents:=0;
      Msg:=EmptyStr;
      aIDs:=TStringList.Create;
      try
        CalculateStat(aFromDate, aToDate, aUsers, aEvents, aIDs);
        Msg+=LineEnding+'Unique users: '+IntToStr(aUsers)+', user events: '+IntToStr(aEvents);
        aStream:=TStringStream.Create(aIDs.Text);
        sendDocumentStream(CurrentChatId, 'users.txt', aStream, Msg);
      finally
        aStream.Free;
        aIDs.Free;
      end;
    except
      on E: Exception do
        ErrorMessage('Error while get statistics: ['+E.ClassName+'] '+E.Message);
    end;
  finally
    ReplyMarkup.Free;
  end;
end;

procedure TTelegramBot.DoGetStatMonth(aYear, aMonth: Word);
var
  Msg, SDate: String;
  aEvents, aUsers, sEvents, sUsers: Integer;
  ReplyMarkup: TReplyMarkup;
  aDate: TDate;
  aToDate, aFromDate: TDate;
begin
  if not CurrentIsAdminUser then
    if not PublicStat then
      Exit;
  ReplyMarkup:=TReplyMarkup.Create;
  try
    RequestWhenAnswer:=False;
    try
      SDate:=aMonth.ToString+'-'+aYear.ToString;
      aToDate:=EndOfAMonth(aYear, aMonth);
      aFromDate:=StartOfAMonth(aYear, aMonth);
      Msg:='*Statistics for '+SDate+'*'+LineEnding;
      ReplyMarkup.InlineKeyBoard:=CreateInlineKeyboardStatMonth(aFromDate);
      aUsers:=0;
      aEvents:=0;
      CalculateStat(aFromDate, aToDate, aUsers, aEvents);
      Msg+=LineEnding+'Unique users: '+IntToStr(aUsers)+', user events: '+IntToStr(aEvents);
      aDate:=aFromDate;
      sUsers:=0;
      sEvents:=0;
      repeat
        aUsers:=0;
        aEvents:=0;
        CalculateStat(aDate, aDate,  aUsers, aEvents);
        DateTimeToString(SDate, 'dd-mm-yyyy', aDate);
        Msg+=LineEnding+mdCode+SDate+mdCode+' - _users:_ '+IntToStr(aUsers)+'_, events:_ '+IntToStr(aEvents);
        sEvents+=aEvents;
        sUsers+=aUsers;
        aDate+=1;
      until (aDate>aToDate) or (aDate>Date);
      Msg+=LineEnding+mdCode+'Summary'+mdCode+' - _users:_ '+
        IntToStr(sUsers div DaysBetween(aFromDate, aToDate))+'_, events:_ '+IntToStr(sEvents);
      editMessageText(Msg, pmMarkdown, True, ReplyMarkup);
    except
      on E: Exception do
        ErrorMessage('Error while get month statistics: ['+E.ClassName+'] '+E.Message);
    end;
  finally
    ReplyMarkup.Free;
  end;
end;

procedure TTelegramBot.DoGetStatFile(ADate: TDate);
var
  ReplyMarkup: TReplyMarkup;
begin
  if not CurrentIsAdminUser then
    Exit;
  ReplyMarkup:=TReplyMarkup.Create;
  try
    ReplyMarkup.InlineKeyBoard:=CreateInlineKeyboardStatFile;
    SendStatLog(ADate, ReplyMarkup)
  finally
    ReplyMarkup.Free;
  end;
end;

procedure TTelegramBot.DoStat(const SDate: String; const SOffset: String;
  SendFile: Boolean);
var
  S: String;
  i: SizeInt;
  aToDate, aFromDate: TDate;
  aMonth, aYear: Word;
begin
  if not Assigned(FStatLogger) then
    Exit;
  aToDate:=0;
  S:=Trim(SDate);
  if (S=s_Today) or (S=EmptyStr) then
    aFromDate:=Date
  else
    if S=s_Yesterday then
      aFromDate:=Date-1
    else begin
      i:=Pos('/', S);
      if i>0 then
      begin
        if not (TryStrToDate(LeftStr(S, i-1), aFromDate, StatDateFormat, '-') and
          TryStrToDate(RightStr(S, Length(S)-i), aToDate, StatDateFormat, '-')) then
        begin
          RequestWhenAnswer:=True;
          sendMessage(str_EntrDtInFrmt);
          Exit;
        end
      end
      else
        if Length(S)>7 then
        begin
          if not TryStrToDate(S, aFromDate, StatDateFormat, '-') then
          begin
            RequestWhenAnswer:=True;
            sendMessage(str_EntrDtInFrmt);
            Exit;
          end
        end
        else begin
          if TryStrToMonth(S, aYear, aMonth) then
            DoGetStatMonth(aYear, aMonth)
          else begin
            RequestWhenAnswer:=True;
            sendMessage(str_EntrDtInFrmt);
          end;
          Exit;
        end;
     end;
  if SOffset=EmptyStr then
    if not SendFile then
      DoGetStat(aFromDate, aToDate)
    else
      DoGetStatFile(aFromDate)
  else
    DoGetStat(aFromDate, aToDate, True, StrToIntDef(SOffset, 0));
end;

procedure TTelegramBot.DoUsers(const SDate: String);
var
  S: String;
  i: SizeInt;
  aToDate, aFromDate: TDate;
begin
  if not Assigned(FStatLogger) then
    Exit;
  aToDate:=0;
  S:=Trim(SDate);
  if (S=s_Today) or (S=EmptyStr) then
    aFromDate:=Date
  else
    if S=s_Yesterday then
      aFromDate:=Date-1
    else begin
      i:=Pos('/', S);
      if i>0 then
      begin
        if not (TryStrToDate(LeftStr(S, i-1), aFromDate, StatDateFormat, '-') and
          TryStrToDate(RightStr(S, Length(S)-i), aToDate)) then
        begin
          RequestWhenAnswer:=True;
          sendMessage(str_EntrDtInFrmt);
          Exit;
        end
      end
      else
        if not TryStrToDate(S, aFromDate, StatDateFormat, '-') then
        begin
          RequestWhenAnswer:=True;
          sendMessage(str_EntrDtInFrmt);
        end
     end;
  DoGetUsers(aFromDate, aToDate)
end;

function TTelegramBot.GetCallbackHandlers(const Command: String): TCallbackEvent;
begin
    Result:=FCallbackHandlers.Items[Command];
end;

function TTelegramBot.GetUserStatus(ID: Int64): TUserStatus;
begin
  Result:=AnsiCharToUserStatus(FUserPermissions.Values[IntToStr(ID)]);
end;

procedure TTelegramBot.SendStatLog(ADate: TDate; AReplyMarkup: TReplyMarkup);
var
  AFileName: String;
begin
  if ADate=0 then
    ADate:=sysutils.Date;
  AFileName:=FStatLogger.GetFileNameFromDate(ADate);
  if FileExists(AFileName) then
  begin
    RequestWhenAnswer:=False;
    sendDocumentByFileName(CurrentChatId, AFileName, str_SttstcsFr+DateToStr(ADate));
  end
  else
  begin
    RequestWhenAnswer:=True;
    EditOrSendMessage(str_SttstcsNtFnd, pmDefault, AReplyMarkup, True);
  end;
end;

procedure TTelegramBot.SetUserStatus(ID: Int64; AValue: TUserStatus);
var
  i: Integer;
begin
  if AValue=usDefault then
  begin
    i:= FUserPermissions.IndexOf(IntToStr(ID));
    if i >-1 then
      FUserPermissions.Delete(i)
    else
      Exit;
  end;
  FUserPermissions.Values[IntToStr(ID)]:=UserStatusChars[AValue];
end;

procedure TTelegramBot.TlgrmStartHandler(ASender: TObject;
  const ACommand: String; AMessage: TTelegramMessageObj);
begin
  UpdateProcessed:=True;
  if not {%H-}AMessage.Text.Contains(' ') then
    sendMessage(FStartText, pmMarkdown)
  else
    DoReceiveDeepLinking(RightStr(AMessage.Text, AMessage.Text.Length-Length(ACommand)));
end;

procedure TTelegramBot.TlgrmHelpHandler(ASender: TObject;
  const ACommand: String; AMessage: TTelegramMessageObj);
begin
  UpdateProcessed:=True;
  sendMessage(FHelpText, pmMarkdown);
end;

procedure TTelegramBot.TlgrmFeedback(ASender: TObject; const ACommand: String;
  AMessage: TTelegramMessageObj);
var
  ReplyMarkup: TReplyMarkup;
begin
  UpdateProcessed:=True;
  ReplyMarkup:=TReplyMarkup.Create;
  try
    ReplyMarkup.ForceReply:=True;
    sendMessage(cmd_Feedback+LineEnding+FFeedbackText, pmMarkdown, True, ReplyMarkup);
  finally
    ReplyMarkup.Free;
  end;
end;

procedure TTelegramBot.TlgrmStatHandler(ASender: TObject;
  const ACommand: String; AMessage: TTelegramMessageObj);
var
  S, O: String;
begin
  if not (PublicStat or CurrentIsAdminUser) then
    Exit;
  RequestWhenAnswer:=True;
  S:=ExtractDelimited(2, AMessage.Text, [' ']);
  O:=ExtractDelimited(3, AMessage.Text, [' ']);
  if S<>EmptyStr then
    DoStat(S, O)
  else
    SendStatInlineKeyboard();
  UpdateProcessed:=True;
end;

procedure TTelegramBot.TlgrmStatFHandler(ASender: TObject;
  const ACommand: String; AMessage: TTelegramMessageObj);
var
  S: String;
begin
  if not CurrentIsAdminUser then
    Exit;
  RequestWhenAnswer:=True;
  S:=ExtractDelimited(2, AMessage.Text, [' ']);
  if S<>EmptyStr then
     DoStat(S, '', True)
  else
    SendStatInlineKeyboard(True);
end;

{ Please define ni18n for excluding translate unit to uses and exclude standard po i18n support }
procedure TTelegramBot.LangTranslate(const ALang: String);{$IFNDEF ni18n}
var
  L, F, aExeName: String;  {$ENDIF}
begin{$IFNDEF ni18n}
  if ALang=EmptyStr then
    Exit;
  if Length(ALang)>2 then
    L:=LeftStr(ALang, 2)
  else
    L:=ALang;
  aExeName:=ChangeFileExt(ExtractFileName(ParamStr(0)), '');
  F:='languages'+PathDelim+aExeName+'.%s.po';
  TranslateResourceStrings(F, L, '');{$ENDIF}
end;

procedure TTelegramBot.SendStatInlineKeyboard(SendFile: Boolean);
var
  ReplyMarkup: TReplyMarkup;
begin
  ReplyMarkup:=TReplyMarkup.Create;
  try
    ReplyMarkup.InlineKeyBoard:=CreateInlineKeyboardStat(Date, SendFile);
    RequestWhenAnswer:=True;
    sendMessage(str_SlctSttstcs_line1+LineEnding+str_SlctSttstcs_line2+LineEnding+
      str_SlctSttstcs_line3+LineEnding+str_SlctSttstcs_line4, pmHTML, True, ReplyMarkup);
  finally
    ReplyMarkup.Free;
  end;
end;

procedure TTelegramBot.StatLog(const AMessage: String; UpdateType: TUpdateType);
var
  EscMsg: String;
begin
  if CurrentIsAdminUser or CurrentIsBotUser then
    Exit;
  if AMessage=EmptyStr then
    Exit;
  if AMessage.Length>150 then
    EscMsg:='... to big text...'{ #todo : Truncate UTF8 text }
  else
    EscMsg:=AMessage;
  try
    if Assigned(CurrentUser)then
    begin
      if (CurrentChatId>0) or UpdateProcessed then        // if message in the group and not processed then do not log
        StatLogger.Log([IntToStr(CurrentChatId), '@'+CurrentUser.Username,
          CurrentUser.First_name, CurrentUser.Last_name, CurrentUser.Language_code,
          UpdateTypeAliases[UpdateType], '"'+StringToJSONString(EscMsg)+'"'])
    end
    else begin
      if Assigned(CurrentChat) then
        FStatLogger.Log([IntToStr(CurrentChatId), '@'+CurrentChat.Username,
          CurrentChat.First_name, CurrentChat.Last_name, '-', UpdateTypeAliases[UpdateType],
          '"'+StringToJSONString(EscMsg)+'"'])
    end;
  except
    on E: Exception do
      ErrorMessage('Can''t write to log StatLogger. '+E.ClassName+': '+E.Message);
  end;
end;

function TTelegramBot.CreateInlineKeyboardRate: TInlineKeyboard;
var
  btns: TInlineKeyboardButtons;
  btn: TInlineKeyboardButton;
begin
  Result:=TInlineKeyboard.Create;
  btns:=Result.Add;
  btn:=TInlineKeyboardButton.Create(str_Rate);
  btn.url:=s_StoreBotRate+BotUsername;
  btns.Add(btn);
end;

function TTelegramBot.CreateInlineKeyboardStat(aFromDate, aToDate: TDate): TInlineKeyboard;
var
  btns: TInlineKeyboardButtons;
  S, PrevDate, NextDate, FromDate, ToDate, SMonth: String;
begin
  DateTimeToString(PrevDate, StatDateFormat, aFromDate-1);
  DateTimeToString(NextDate, StatDateFormat, aFromDate+1);
  DateTimeToString(FromDate, StatDateFormat, aFromDate);
  DateTimeToString(ToDate, StatDateFormat, aToDate);
  Result:=TInlineKeyboard.Create;
  btns:=Result.Add;
  DateTimeToString(S, StatDateFormat, aFromDate);
  DateTimeToString(SMonth, StatMonthFormat, aFromDate);
  if CurrentIsAdminUser then
  begin
    btns.AddButtons([str_Today+' 🔃', s_GetStat+' '+s_Today, str_Monthly,
      s_GetStat+' '+SMonth, str_Browse, s_GetStat+' '+S+' '+'0']);
    btns:=Result.Add;
    btns.AddButtons([str_PrevDay, s_GetStat+' '+PrevDate, str_NextDay, s_GetStat+' '+NextDate,
      str_Users, s_GetUsers+' '+FromDate+'/'+ToDate]);
  end
  else
    btns.AddButtons([str_Today+' 🔃', s_GetStat+' '+s_Today,
      str_PrevDay, s_GetStat+' '+PrevDate, str_NextDay, s_GetStat+' '+NextDate])
end;

function TTelegramBot.CreateInlineKeyboardStat(ADate: TDate; SendFile: Boolean
  ): TInlineKeyboard;
begin
  if SendFile then
    Result:=CreateInlineKeyboardStatFile
  else
    Result:=CreateInlineKeyboardStat(ADate, ADate);
end;

function TTelegramBot.CreateInlineKeyboardStatFile: TInlineKeyboard;
var
  btns: TInlineKeyboardButtons;
begin
  Result:=TInlineKeyboard.Create;
  btns:=Result.Add;
  btns.AddButtons([str_Today+' 🔃', s_GetStat+'File'+' '+s_Today, str_Yesterday,
    s_GetStat+'File'+' '+s_Yesterday]);
end;

function TTelegramBot.CreateInlineKeyboardStatMonth(ADate: TDate
  ): TInlineKeyboard;
var
  btns: TInlineKeyboardButtons;
  S, PrevDate, NextDate: String;
begin
  DateTimeToString(PrevDate, StatMonthFormat, IncMonth(ADate, -1));
  DateTimeToString(NextDate, StatMonthFormat, IncMonth(ADate, 1));
  Result:=TInlineKeyboard.Create;
  btns:=Result.Add;
  DateTimeToString(S, StatDateFormat, ADate);
  if CurrentIsAdminUser then
  begin
    btns.AddButtons([str_Today+' 🔃', s_GetStat+' '+s_Yesterday, str_Browse+' '+S, s_GetStat+' '+S+' '+'0']);
    btns:=Result.Add;
    btns.AddButtons([str_Prev, s_GetStat+' '+PrevDate, str_Next, s_GetStat+' '+NextDate]);
  end
  else
    btns.AddButtons([str_Today+' 🔃', s_GetStat+' '+s_Today,
      str_Prev, s_GetStat+' '+PrevDate, str_Next, s_GetStat+' '+NextDate])
end;

function TTelegramBot.CreateInlineKeyboardStat(ADate: TDate; Len: Integer;
  Offset: Integer; Step: Integer): TInlineKeyboard;
var
  PrevDate, NextDate, SDate: String;
  btns: TInlineKeyboardButtons;
  i: Integer;
begin
  Result:=TInlineKeyboard.Create;
  if Len=0 then
    Exit;
  DateTimeToString(PrevDate, StatDateFormat, ADate-1);
  DateTimeToString(NextDate, StatDateFormat, ADate+1);
  btns:=Result.Add;
  DateTimeToString(SDate, StatDateFormat, ADate);
  if Offset>0 then
  begin
    btns.AddButton('<<', s_GetStat+' '+ SDate+' '+IntToStr(0));
    i:=Offset-Step;
    if i<0 then
      i:=0;
    btns.AddButton('<', s_GetStat+' '+SDate+' '+IntToStr(i));
  end;
  if Offset+Step<Len then
  begin
    btns.AddButton('>', s_GetStat+' '+SDate+' '+IntToStr(Offset+Step));
    btns.AddButton('>>', s_GetStat+' '+SDate+' '+IntToStr(Len-Step));
  end;
  Result.Add.AddButtons([str_Today+' 🔃', s_GetStat+' '+s_Today,
    str_PrevDay, s_GetStat+' '+PrevDate+' '+'0', str_NextDay, s_GetStat+' '+NextDate+' '+'0']);
end;

procedure TTelegramBot.DoReceiveDeepLinking(const AParameter: String);
begin
  if Assigned(FOnReceiveDeepLinking) then
    FOnReceiveDeepLinking(AParameter);
end;

constructor TTelegramBot.Create(const AToken: String);
begin
  inherited Create(AToken);
  FStatLogger:=TtgStatLog.Create(nil);
  FStatLogger.Active:=False;
  FStatLogger.TimeStampFormat:='hh:nn:ss';
  FUserPermissions:=TStringList.Create;
  FUserPermissions.Sorted:=True;
  FUserPermissions.Duplicates:=dupIgnore;
  FFeedbackThanks:=str_FeedbackThanks;
  FFeedbackText:=str_FeedbackText;
  CommandHandlers[cmd_Start]:=   @TlgrmStartHandler;
  CommandHandlers[cmd_Help]:=    @TlgrmHelpHandler;
  CommandHandlers[cmd_Feedback]:=@TlgrmFeedback;
  //CommandHandlers[cmd_Rate]:=    @TlgrmRate;
  CommandHandlers[cmd_Stat]:=    @TlgrmStatHandler;
  CommandHandlers[cmd_StatF]:=   @TlgrmStatFHandler;
  CommandHandlers[cmd_SetStart]:= @SetCommandReply;
  CommandHandlers[cmd_SetHelp]:=  @SetCommandReply;
  FCallbackHandlers:=TCallbackHandlersMap.create;
  FPublicStat:=False;
  FCallbackAnswered:=False;
  FAutoTranslate:=True;
end;

destructor TTelegramBot.Destroy;
begin
  FCallbackHandlers.Free;
  FUserPermissions.Free;
  FStatLogger.Free;
  inherited Destroy;
end;

procedure TTelegramBot.DoReceiveMessageUpdate(AMessage: TTelegramMessageObj);
begin
  inherited DoReceiveMessageUpdate(AMessage);
  if Assigned(AMessage.ReplyToMessage) and not UpdateProcessed then
  begin
    if Assigned(AMessage.ReplyToMessage.From) then
      if SameText(AMessage.ReplyToMessage.From.Username, BotUsername) and
        AnsiStartsStr(cmd_Feedback, AMessage.ReplyToMessage.Text) then
      begin
        sendMessage(Format(FFeedbackThanks, [AMessage.From.First_name]));
        With AMessage do
          SaveFeedback(From, Text);
      end;
    Exit;
  end;
  StatLog(AMessage.Text, utMessage);
end;

procedure TTelegramBot.DoReceiveCallbackQuery(ACallback: TCallbackQueryObj);
var
  AHandled, AFlag: Boolean;
  ACommand: String;
  H: TCallbackEvent;
begin
  AHandled:=False;
  FCallbackAnswered:=False;   
  try
    inherited DoReceiveCallbackQuery(ACallback);
    if CurrentIsAdminUser or PublicStat then
    begin
      if AnsiStartsStr(s_GetStat+' ', ACallback.Data) then
      begin
        AHandled:=True;
        DoCallbackQueryStat(ACallback);
      end;
      if AnsiStartsStr(s_GetStat+s_File+' ', ACallback.Data) then
      begin
        AHandled:=True;
        DoCallbackQueryStat(ACallback, True);
      end;
    end;
    if CurrentIsAdminUser and AnsiStartsStr(s_GetUsers+' ', ACallback.Data) then
    begin
      AHandled:=True;
      DoCallbackQueryGetUsers(ACallback);
    end;
    StatLog(ACallback.Data, utCallbackQuery);
    if not AHandled then
    begin
      AFlag:=RequestWhenAnswer;
      ACommand:=ExtractWord(1, ACallback.Data, [' ']);
      if FCallbackHandlers.contains(ACommand) then
      begin
        H:=FCallbackHandlers.Items[ACommand];
        H(Self, ACallback);
        RequestWhenAnswer:=False;
        if not FCallbackAnswered then
          answerCallbackQuery(ACallback.ID); // if user do not call this in callback procedure
        RequestWhenAnswer:=AFlag;
        AHandled:=True;
      end;
    end;
  except
    on E:Exception do
      Logger.Error('Error TTelegramBot.DoReceiveCallbackQuery ('+E.ClassName+': '+E.Message+')'); 
  end;
end;

procedure TTelegramBot.DoReceiveChannelPost(AChannelPost: TTelegramMessageObj);
begin
  inherited DoReceiveChannelPost(AChannelPost);
  StatLog(AChannelPost.Text, utChannelPost);
end;

procedure TTelegramBot.DoReceiveChosenInlineResult(
  AChosenInlineResult: TTelegramChosenInlineResultObj);
begin
  inherited DoReceiveChosenInlineResult(AChosenInlineResult);
  StatLog(AChosenInlineResult.Query, utChosenInlineResult);
end;

procedure TTelegramBot.DoReceiveInlineQuery(
  AnInlineQuery: TTelegramInlineQueryObj);
begin
  inherited DoReceiveInlineQuery(AnInlineQuery);
  StatLog(AnInlineQuery.Query, utInlineQuery);
end;

function TTelegramBot.IsAdminUser(ChatID: Int64): Boolean;
begin
  Result:=(FUserPermissions.Values[IntToStr(ChatID)]='a') or
    (FUserPermissions.Values[IntToStr(ChatID)]='m');
end;

procedure TTelegramBot.EditOrSendMessage(const AMessage: String;
  AParseMode: TParseMode; ReplyMarkup: TReplyMarkup; TryEdit: Boolean);
var
  aCanEdit: Boolean;
begin
  { Variable aCanEdit is to avoid telegram API error "Bad Request: there is no text in the message to edit" }
  aCanEdit:=False;
  if Assigned(CurrentUpdate.CallbackQuery) then
    if Assigned(CurrentUpdate.CallbackQuery.Message) then
      aCanEdit:=CurrentUpdate.CallbackQuery.Message.Text<>EmptyStr;
  if not (TryEdit and aCanEdit)  then
    sendMessage(AMessage, AParseMode, True, ReplyMarkup)
  else
    editMessageText(AMessage, AParseMode, True, ReplyMarkup);
end;

function TTelegramBot.IsBanned(ChatID: Int64): Boolean;
begin
  Result:=FUserPermissions.Values[IntToStr(ChatID)]='b'
end;

function TTelegramBot.IsBotUser(ChatID: Int64): Boolean;
begin
  Result:=FUserPermissions.Values[IntToStr(ChatID)]='r'; // robot
end;

function TTelegramBot.IsSimpleUser(ChatID: Int64): Boolean;
begin
  Result:=(FUserPermissions.Values[IntToStr(ChatID)]<>'a') and
    (FUserPermissions.Values[IntToStr(ChatID)]<>'m');
end;

procedure TTelegramBot.SaveFeedback(AFrom: TTelegramUserObj; AMessage: String);
begin
  // to-do
end;

procedure TTelegramBot.SetLanguage(const ALang: String);
begin
  inherited SetLanguage(ALang);
  if FAutoTranslate then
    LangTranslate(ALang);
end;

function TTelegramBot.answerCallbackQuery(const CallbackQueryId: String; const Text: String; ShowAlert: Boolean;
  const Url: String; CacheTime: Integer): Boolean;
begin
  Result:=inherited;
  FCallbackAnswered:=True;
end;

procedure TTelegramBot.LoadUserStatusValues(AStrings: TStrings);
begin
  FUserPermissions.AddStrings(AStrings);
end;

end.

