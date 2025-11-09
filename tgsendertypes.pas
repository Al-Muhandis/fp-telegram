unit tgsendertypes;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, tgtypes, ghashmap, ghashset, tgstatlog, eventlog,
  tgbasehttpclient
  ;

type
  TParseMode = (pmDefault, pmMarkdown, pmHTML, pmMarkdownV2);
  TMediaType = (mtPhoto, mtVideo, mtUnknown);
  TInlineQueryResultType = (qrtArticle, qrtPhoto, qrtVideo, qrtAudio, qrtVoice, qrtMpeg4Gif,
    qrtDocument, qrtUnknown);
  TLogMessageEvent = procedure(ASender: TObject; EventType: TEventType; const Msg: String) of object;
  TTelegramSender = class;
  TInlineKeyboardButton = class;
  TKeyboardButton = class;
  TKeyboardButtonArray = class;
  TInlineKeyboard = class;

  TOnUpdateEvent = procedure (ASender: TObject; AnUpdate: TTelegramUpdateObj) of object;

  TCommandEvent = procedure (ASender: TObject; const ACommand: String;
    AMessage: TTelegramMessageObj) of object;
  TCallbackEvent = procedure (ASender: TObject; ACallback: TCallbackQueryObj) of object;
  TMessageEvent = procedure (ASender: TObject; AMessage: TTelegramMessageObj) of object;
  TChatMemberEvent = procedure (ASender: TTelegramSender; aChatMemberUpdated: TTelegramChatMemberUpdated) of object;
  TBusinessConnectionEvent = procedure (ASender: TObject; ABusinessConnection: TTelegramBusinessConnectionObj) of object;
  TInlineQueryEvent = procedure (ASender: TObject; AnInlineQuery: TTelegramInlineQueryObj) of object;
  TChosenInlineResultEvent = procedure (ASender: TObject;
    AChosenInlineResult: TTelegramChosenInlineResultObj) of object;
  TPreCheckoutQueryEvent = procedure (ASender: TObject;
    APreCheckoutQuery: TTelegramPreCheckOutQuery) of object;
  TSuccessfulPaymentEvent = procedure (ASender: TObject;
    ASuccessfulPayment: TTelegramSuccessfulPayment) of object;

  { TStringHash }

  TStringHash = class
    class function hash(s: String; n: Integer): Integer;
  end;

  generic TStringHashMap<T> = class(specialize THashMap<String,T,TStringHash>) end;

  TCommandHandlersMap = specialize TStringHashMap<TCommandEvent>;

  { TIntegerHash }

  TIntegerHash = class
    class function hash(i: Int64; n: Integer): Integer;
  end;

  TIntegerHashSet = specialize THashSet<Int64,TIntegerHash>;

  { TReplyMarkup }

  TReplyMarkup = class(TJSONObject)
  private
    function GetForceReply: Boolean;
    function GetInlineKeyBoard: TInlineKeyboard;
    function GetInputFieldPlaceholder: String;
    function GetOneTimeKeyboard: Boolean;
    function GetRemoveKeyboard: Boolean;
    function GetReplyKeyboardMarkup: TKeyboardButtonArray;
    function GetResizeKeyboard: Boolean;
    function GetSelective: Boolean;
    procedure SetForceReply(AValue: Boolean);
    procedure SetInlineKeyBoard(AValue: TInlineKeyboard);
    procedure SetInputFieldPlaceholder(AValue: String);
    procedure SetOneTimeKeyboard(AValue: Boolean);
    procedure SetRemoveKeyboard(AValue: Boolean);
    procedure SetReplyKeyboardMarkup(AValue: TKeyboardButtonArray);
    procedure SetResizeKeyboard(AValue: Boolean);
    procedure SetSelective(AValue: Boolean);
  public
    class function CreateFromObject(aObject: TJSONObject): TReplyMarkup;
    class function CreateFromString(const aJSONString: String): TReplyMarkup;
    function CreateInlineKeyBoard: TInlineKeyboard;                          
    function CreateReplyKeyboard: TKeyboardButtonArray;
    { Only one from InlineKeyboard or ReplyMarkup is must to set }
    property InlineKeyBoard: TInlineKeyboard read GetInlineKeyBoard write SetInlineKeyBoard;
{ ReplyKeyboard properties }
    property ReplyKeyboardMarkup: TKeyboardButtonArray read GetReplyKeyboardMarkup
      write SetReplyKeyboardMarkup;
    property RemoveKeyboard: Boolean read GetRemoveKeyboard write SetRemoveKeyboard;
{ Only if ReplyKeyboard is present then optional}
    property ResizeKeyboard: Boolean read GetResizeKeyboard write SetResizeKeyboard;
    property OneTimeKeyboard: Boolean read GetOneTimeKeyboard write SetOneTimeKeyboard;
{ ForceReply properties
  If property ForceReply is set then ReplyMarkup must be only ForceReply type }
    property ForceReply: Boolean read GetForceReply write SetForceReply;
    property InputFieldPlaceholder: String read GetInputFieldPlaceholder write SetInputFieldPlaceholder;
    property Selective: Boolean read GetSelective write SetSelective;
  end;

  TReplyMarkupClass=class of TReplyMarkup;

  { TKeyboardButton }

  TKeyboardButton = class(TJSONObject)
  private
    function GetRequestContact: Boolean;
    function GetRequestLocation: Boolean;
    function Gettext: String;
    procedure SetRequestContact(AValue: Boolean);
    procedure SetRequestLocation(AValue: Boolean);
    procedure Settext(AValue: String);
  public
    constructor Create(const AText: String);
    property text: String read Gettext write Settext;
    property RequestContact: Boolean read GetRequestContact write SetRequestContact; // Optional
    property RequestLocation: Boolean read GetRequestLocation write SetRequestLocation; // Optional
  end;

  { TKeyboardButtons }

  TKeyboardButtons = class(TJSONArray)
  private
    function GetButtons(Index : Integer): TKeyboardButton;
    procedure SetButtons(Index : Integer; AValue: TKeyboardButton);
  public
    constructor Create(const AText: String); overload;
    constructor Create(const AButtons: array of String); overload;
    function AddButton(const AButtonText: String): Integer;
    procedure AddButtons(const AButtons: array of String);
    property Buttons[Index : Integer]: TKeyboardButton read GetButtons write SetButtons;
  end;

  { TInlineKeyboardButton }

  TInlineKeyboardButton = class(TJSONObject)
  private
    function CheckOptnlNull: Boolean;
    procedure CheckOptnlAndSet(const ParamName, ParamValue: String);
    function Getcallback_data: String;
    function Getswitch_inline_query: String;
    function Getswitch_inline_query_current_chat: String;
    function Gettext: String;
    function Geturl: String;
    procedure Setcallback_data(AValue: String);
    procedure Setswitch_inline_query(AValue: String);
    procedure Setswitch_inline_query_current_chat(AValue: String);
    procedure Settext(AValue: String);
    procedure Seturl(AValue: String);
  public
    constructor Create(const AText: String);
    property text: String read Gettext write Settext;
    property url: String read Geturl write Seturl;
    property callback_data: String read Getcallback_data write Setcallback_data;
    property switch_inline_query: String read Getswitch_inline_query write Setswitch_inline_query;
    property switch_inline_query_current_chat: String read Getswitch_inline_query_current_chat
      write Setswitch_inline_query_current_chat;
  end;

  { TInlineKeyboardButtons }

  TInlineKeyboardButtons = class(TJSONArray)
  public
    constructor Create(const AButtonText, CallbackData: String); overload;
    function AddButton(const AButtonText, CallbackData: String): Integer;
    function AddButtonUrl(const AButtonText, AUrl: String): Integer;
    function AddButtonInline(const AButtonText, AQuery: String): Integer;
    procedure AddButtons(const AButtons: array of String);
  end;

  { TInlineKeyboard }

  TInlineKeyboard = class(TJSONArray)
  public
    function Add(AButtons: TInlineKeyboardButtons): Integer; overload;
    function Add: TInlineKeyboardButtons;
    { Added to the last row of buttons. If you specify a MaxColsinRow then
      a new row of buttons is automatically created if needed }
    procedure AddButton(aButton: TInlineKeyboardButton; MaxColsinRow: Integer = 0);
    { Add button with callback data to the last row of buttons. If you specify a MaxColsinRow then
      a new row of buttons is automatically created if needed  }
    procedure AddButton(const AButtonText, CallbackData: String; MaxColsinRow: Integer = 0);
  end;

  { TKeyboardButtonArray }

  TKeyboardButtonArray = class(TJSONArray)
  public
    function Add(aButtons: TKeyboardButtons): Integer; overload;
    function Add: TKeyboardButtons;
  end;

  { TInputMessageContent }

  TInputMessageContent = class(TJSONObject)
  private
    function GetMessageText: String;
    function GetParseMode: TParseMode;
    procedure SetMessageText(AValue: String);
    procedure SetParseMode(AValue: TParseMode);
  public
    constructor Create(const AMessageText: String; AParseMode: TParseMode = pmDefault);
    property MessageText: String read GetMessageText write SetMessageText;
    property ParseMode: TParseMode read GetParseMode write SetParseMode;
  end;

  { TInlineQueryResult }

  TInlineQueryResult = class(TJSONObject)
  private
    function GetAudioDuration: Integer;
    function GetAudioFileID: String;
    function GetAudioUrl: String;
    function GetCaption: String;
    function GetDescription: String;
    function GetDocumentFileID: String;
    function GetID: String;
    function GetInputMessageContent: TInputMessageContent;
    function GetIQRType: TInlineQueryResultType;
    function GetMimeType: String;
    function GetMpeg4Height: Integer;
    function GetMpeg4Url: String;
    function GetMpeg4Width: Integer;
    function GetParseMode: TParseMode;
    function GetPerformer: String;
    function GetPhotoFileID: String;
    function GetPhotoHeight: Integer;
    function GetPhotoUrl: String;
    function GetPhotoWidth: Integer;
    function GetReplyMarkup: TReplyMarkup;
    function GetThumbUrl: String;
    function GetTitle: String;
    function GetVideoFileID: String;
    function GetVideoUrl: String;
    function GetVoiceFileID: String;
    procedure SetAudioDuration(AValue: Integer);
    procedure SetAudioFileID(AValue: String);
    procedure SetAudioUrl(AValue: String);
    procedure SetCaption(AValue: String);
    procedure SetDescription(AValue: String);
    procedure SetDocumentFileID(AValue: String);
    procedure SetID(AValue: String);
    procedure SetInputMessageContent(AValue: TInputMessageContent);
    procedure SetIQRType(AValue: TInlineQueryResultType);
    procedure SetMimeType(AValue: String);
    procedure SetMpeg4Height(AValue: Integer);
    procedure SetMpeg4Url(AValue: String);
    procedure SetMpeg4Width(AValue: Integer);
    procedure SetParseMode(AValue: TParseMode);
    procedure SetPerformer(AValue: String);
    procedure SetPhotoFileID(AValue: String);
    procedure SetPhotoHeight(AValue: Integer);
    procedure SetPhotoUrl(AValue: String);
    procedure SetPhotoWidth(AValue: Integer);
    procedure SetReplyMarkup(AValue: TReplyMarkup);
    procedure SetThumbUrl(AValue: String);
    procedure SetTitle(AValue: String);
    procedure SetVideoFileID(AValue: String);
    procedure SetVideoUrl(AValue: String);
    procedure SetVoiceFileID(AValue: String);
  public
    property IQRType: TInlineQueryResultType read GetIQRType write SetIQRType;
    property ID: String read GetID write SetID;
    property Title: String read GetTitle write SetTitle;
    property InputMessageContent: TInputMessageContent read GetInputMessageContent write SetInputMessageContent;
    property ReplyMarkup: TReplyMarkup read GetReplyMarkup write SetReplyMarkup;
    property Description: String read GetDescription write SetDescription;

    property AudioFileID: String read GetAudioFileID write SetAudioFileID;
    property DocumentFileID: String read GetDocumentFileID write SetDocumentFileID;
    property PhotoFileID: String read GetPhotoFileID write SetPhotoFileID;
    property VideoFileID: String read GetVideoFileID write SetVideoFileID;
    property VoiceFileID: String read GetVoiceFileID write SetVoiceFileID;

    property PhotoUrl: String read GetPhotoUrl write SetPhotoUrl;
    property ThumbUrl: String read GetThumbUrl write SetThumbUrl;

    property VideoUrl: String read GetVideoUrl write SetVideoUrl;
    property MimeType: String read GetMimeType write SetMimeType;

    property PhotoWidth: Integer read GetPhotoWidth write SetPhotoWidth;
    property PhotoHeight: Integer read GetPhotoHeight write SetPhotoHeight;

    property Mpeg4Url: String read GetMpeg4Url write SetMpeg4Url;
    property Mpeg4Height: Integer read GetMpeg4Height write SetMpeg4Height;
    property Mpeg4Width: Integer read GetMpeg4Width write SetMpeg4Width;

    property AudioUrl: String read GetAudioUrl write SetAudioUrl;
    property Caption: String read GetCaption write SetCaption;
    property ParseMode: TParseMode read GetParseMode write SetParseMode;
    property Performer: String read GetPerformer write SetPerformer;
    property AudioDuration: Integer read GetAudioDuration write SetAudioDuration;
  end;

  { TInlineQueryResultArray }

  TInlineQueryResultArray = class(TJSONArray)
  public
    function Add(aInlineQueryResult: TInlineQueryResult): Integer; overload;
    function Add: TInlineQueryResult;
  end;

  { TInputMedia }

  TInputMedia = class(TJSONObject)
  private
    function GetCaption: String;
    function GetMedia: String;
    function GetMediaType: TMediaType;
    function GetParseMode: TParseMode;
    procedure SetCaption(AValue: String);
    procedure SetMedia(AValue: String);
    procedure SetMediaType(AValue: TMediaType);
    procedure SetParseMode(AValue: TParseMode);
  public
    property MediaType: TMediaType read GetMediaType write SetMediaType;
    property Media: String read GetMedia write SetMedia;
    property Caption: String read GetCaption write SetCaption;
    property ParseMode: TParseMode read GetParseMode write SetParseMode;
  end;

  { TInputMediaPhoto }

  TInputMediaPhoto = class(TInputMedia)
  public
    constructor Create; reintroduce;
  end;

  { TInputMediaVideo }

  TInputMediaVideo = class(TInputMedia)
  private
    function GetDuration: Integer;
    function GetHeight: Integer;
    function GetSupportsStreaming: Boolean;
    function GetWidth: Integer;
    procedure SetDuration(AValue: Integer);
    procedure SetHeight(AValue: Integer);
    procedure SetSupportsStreaming(AValue: Boolean);
    procedure SetWidth(AValue: Integer);
  public
    constructor Create; reintroduce;
    property Width: Integer read GetWidth write SetWidth;
    property Height: Integer read GetHeight write SetHeight;
    property Duration: Integer read GetDuration write SetDuration;
    property SupportsStreaming: Boolean read GetSupportsStreaming write SetSupportsStreaming;
  end;

  { TInputMediaArray }

  TInputMediaArray = class(TJSONArray)
  public
    function Add(AMedia: TInputMedia): Integer; overload;
    function AddPhoto: TInputMediaPhoto;
    function AddPhoto(const APhoto: String): Integer; overload;
    function AddVideo: TInputMediaVideo;
    function AddVideo(const AVideo: String): Integer; overload;
  end;

  { TLabeledPrice }

  TLabeledPrice = class(TJSONObject)
  private
    function GetPortionAmount: Integer;
    function GetPortionLabel: String;
    procedure SetPortionAmount(AValue: Integer);
    procedure SetPortionLabel(AValue: String);
  public
    property PortionLabel: String read GetPortionLabel write SetPortionLabel;
    property PortionAmount: Integer read GetPortionAmount write SetPortionAmount;
  end;

  { TLabeledPriceArray }

  TLabeledPriceArray = class(TJSONArray)
  public
    constructor Create(const APortionLabel: String; APortionAmount: Integer);
    function AddLabeledPrice: TLabeledPrice;
  end;

  { TBotCommand }

  TBotCommand = class(TJSONObject)
  private
    function GetCommand: String;
    function GetDescription: String;
    procedure SetCommand(const AValue: String);
    procedure SetDescription(const AValue: String);
  public
    constructor Create(const aCommand, aDescription: String);
    property Command: String read GetCommand write SetCommand;
    property Description: String read GetDescription write SetDescription;
  end;

  { TBotCommandArray }

  TBotCommandArray = class(TJSONArray)
  public
    procedure AddCommands(aBotCommands: array of String);
    procedure AddCommand(const aCommand, aDescription: String);
  end;

  TCommandScopeType = (stDefault, stAllPrivateChats, stAllGroupChats, stAllChatAdministrators, stSpecificChat,
    stChatAdministrators, stChatMember);

  { TBotCommandScope }

  TBotCommandScope = class(TJSONObject)
  private
    FChatID: Int64;
    FUserID: Int64;
    function GetScopeType: TCommandScopeType;
    procedure SetScopeChat(AValue: TCommandScopeType);
  public
    property ScopeType: TCommandScopeType read GetScopeType write SetScopeChat;
    property ChatID: Int64 read FChatID write FChatID;   
    property UserID: Int64 read FUserID write FUserID;
  end;

  TPollType=(ptRegular, ptQuiz);

  { TTelegramSender }

  TTelegramSender = class
  private
    FAPIEndPoint: String;
    FBotUsername: String;
    FCurrentChat: TTelegramChatObj;
    FCurrentChatId: Int64;
    FCurrentIsTopicMessage: Boolean;
    FCurrentThreadId: Integer;
    FCurrentMessage: TTelegramMessageObj;
    FCurrentUser: TTelegramUserObj;
    FBotUser: TTelegramUserObj;
    FFileObj: TTelegramFile;
    FHTTPProxyHost: String;
    FHTTPProxyPassword: String;
    FHTTPProxyUser: String;
    FHTTPProxyPort: Word;
    FLanguage: string;
    FLastErrorCode: Integer;
    FLastErrorDescription: String;
    FLogDebug: Boolean;
    FLogger: TEventLog;
    FOnAfterParseUpdate: TNotifyEvent;       
    FOnReceiveBusinessConnection: TBusinessConnectionEvent;
    FOnReceiveBusinessMessage: TMessageEvent;
    FOnReceiveCallbackQuery: TCallbackEvent;
    FOnReceiveChannelPost: TMessageEvent;
    FOnReceiveChatMemberUpdated: TChatMemberEvent;
    FOnReceiveChosenInlineResult: TChosenInlineResultEvent;
    FOnReceiveEditedChannelPost: TMessageEvent;
    FOnReceiveEditedMessage: TMessageEvent;
    FOnReceiveInlineQuery: TInlineQueryEvent;
    FOnReceiveMessage: TMessageEvent;
    FOnReceiveMyChatMemberUpdated: TChatMemberEvent;
    FOnReceivePreCheckoutQuery: TPreCheckoutQueryEvent;
    FOnReceiveSuccessfulPayment: TMessageEvent;
    FUpdate: TTelegramUpdateObj;
    FJSONResponse: TJSONData;
    FOnLogMessage: TLogMessageEvent;
    FOnReceiveUpdate: TOnUpdateEvent;
    FProcessUpdate: Boolean;
    FResponse: String;
    FRequestBody: String;
    FToken: String;
    FRequestWhenAnswer: Boolean;
    FCommandHandlers: TCommandHandlersMap; 
    FChannelCommandHandlers: TCommandHandlersMap;
    FUpdateID: Integer;
    FUpdateLogger: TtgStatLog;
    FUpdateProcessed: Boolean;
    FTimeout: Integer; {$IF FPC_FULLVERSION <= 30004}
    function AddPair(aStringList: TStrings; const AName, AValue: string): TStrings;  {$ENDIF}
    procedure AssignHTTProxy(aHTTPClient: TBaseHTTPClient; const aHost: String; aPort: Word;
      const aUserName, aPassword: String);
    procedure AssignHTTProxy(aHTTPClient: TBaseHTTPClient);
    function CurrentLanguage(AUser: TTelegramUserObj): String;
    function CurrentLanguage(AMessage: TTelegramMessageObj): String;
    function GetAPIEndPoint: String;
    function GetChannelCommandHandlers(const Command: String): TCommandEvent;
    function GetCommandHandlers(const Command: String): TCommandEvent;
    function GetTimeout: Integer;
    procedure SetAPIEndPoint(AValue: String);
    procedure SetBotUsername(AValue: String);
    procedure SetChannelCommandHandlers(const Command: String;
      AValue: TCommandEvent);
    procedure SetCommandHandlers(const Command: String; AValue: TCommandEvent);
    function HTTPPostFile(const Method, FileField, FileName: String; AFormData: TStrings): Boolean;
    function HTTPPostFiles(const Method: String; aFormData, aFiles: TStrings): Boolean;
    function HTTPPostJSON(const Method: String): Boolean;
    function HTTPPostStream(const Method, FileField, FileName: String;
      AStream: TStream; AFormData: TStrings): Boolean;
    function HTTPPostStreams(const Method: String; aFormData, aStreams: TStrings): Boolean;
    procedure ProcessCommands(AMessage: TTelegramMessageObj; AHandlers: TCommandHandlersMap);
    function ResponseToJSONObject: TJSONObject;
    function ResponseHandle: Boolean;
    function SendFile(const AMethod, AFileField, AFileName: String; MethodParameters: TStrings): Boolean;
    function SendFiles(const AMethod: String; AFiles, MethodParameters: TStrings): Boolean;
    function SendMethod(const Method: String; MethodParameters: array of const): Boolean;
    function SendMethod(const Method: String; MethodParameters: TJSONObject): Boolean; overload;
    function SendStream(const AMethod, AFileField, AFileName: String; AStream: TStream;
      MethodParameters: TStrings): Boolean;
    function SendStreams(const AMethod: String; AStreams, MethodParameters: TStrings): Boolean;
    procedure SetFileObj(AValue: TTelegramFile);
    procedure SetJSONResponse(AValue: TJSONData);
    procedure SetLastErrorCode(AValue: Integer);
    procedure SetLastErrorDescription(AValue: String);
    procedure SetLogDebug(AValue: Boolean);
    procedure SetLogger(AValue: TEventLog);
    procedure SetOnAfterParseUpdate(AValue: TNotifyEvent);
    procedure SetProcessUpdate(AValue: Boolean);
    procedure SetRequestBody(AValue: String);
    procedure SetRequestWhenAnswer(AValue: Boolean);
    procedure SetTimeout(AValue: Integer);
    procedure SetUpdateID(AValue: Integer);
    procedure SetUpdateLogger(AValue: TtgStatLog);
    procedure SetUpdateProcessed(AValue: Boolean);
    class function StringToJSONObject(const AString: String): TJSONObject;
  protected
    procedure DoAfterParseUpdate; // After the parse of the update object prior to calling all custom handlers (OnReceive...)
    procedure DoReceiveMessageUpdate(AMessage: TTelegramMessageObj); virtual;
    procedure DoReceiveEditedMessage(AMessage: TTelegramMessageObj); virtual;
    procedure DoReceiveCallbackQuery(ACallback: TCallbackQueryObj); virtual;
    procedure DoReceiveChannelPost(AChannelPost: TTelegramMessageObj); virtual;
    procedure DoReceiveEditedChannelPost(AChannelPost: TTelegramMessageObj); virtual;
    procedure DoReceiveInlineQuery(AnInlineQuery: TTelegramInlineQueryObj);  virtual;
    procedure DoReceiveChosenInlineResult(AChosenInlineResult: TTelegramChosenInlineResultObj); virtual;
    procedure DoReceivePreCheckoutQuery(APreCheckoutQuery: TTelegramPreCheckOutQuery); virtual;  
    procedure DoReceiveMyChatMemberQuery(AMyChatMember: TTelegramChatMemberUpdated); virtual;
    procedure DoReceiveChatMemberQuery(AChatMember: TTelegramChatMemberUpdated); virtual;
    procedure DoReceiveSuccessfulPayment(AMessage: TTelegramMessageObj); virtual;  
    procedure DoReceiveBusinessConnection(ABusinessConnection: TTelegramBusinessConnectionObj); virtual; 
    procedure DoReceiveBusinessMessage(ABusinessMessage: TTelegramMessageObj); virtual;
    procedure DebugMessage(const Msg: String); virtual; // it will send all requests and responses to the log. Useful during development
    procedure ErrorMessage(const Msg: String); virtual;
    procedure InfoMessage(const Msg: String); virtual;
    function IsBanned({%H-}ChatID: Int64): Boolean; virtual;
    function IsSimpleUser({%H-}ChatID: Int64): Boolean; virtual; 
    function IsAdminUser({%H-}ChatID: Int64): Boolean; virtual;
    function IsBotUser({%H-}ChatID: Int64): Boolean; virtual; // For example, a search engine bot
    procedure SetLanguage(const AValue: String); virtual;
  public
    constructor Create(const AToken: String);
    function DeepLinkingUrl(const AParameter: String): String;
    destructor Destroy; override;
    procedure DoReceiveUpdate(AnUpdate: TTelegramUpdateObj); virtual; // After calling the rest of handlers OnReceive...
    function CurrentIsAdminUser: Boolean;
    function CurrentIsSimpleUser: Boolean;
    function CurrentIsBanned: Boolean;
    function CurrentIsBotUser: Boolean;

    function answerCallbackQuery(const CallbackQueryId: String; const Text: String = '';
      ShowAlert: Boolean=False; const Url: String = ''; CacheTime: Integer = 0): Boolean; virtual;
    function answerPreCheckoutQuery(const PreCheckoutQueryID: String; Ok: Boolean;
      AnErrorMessage: String = ''): Boolean;
    function deleteMessage(chat_id: Int64; message_id: Int64): Boolean;
    function deleteMessage(message_id: Int64): Boolean;
    function editMessageReplyMarkup(chat_id: Int64 = 0; message_id: Int64 = 0;
      const inline_message_id: String = ''; ReplyMarkup: TReplyMarkup = nil): Boolean;
    function editMessageText(const AMessage: String; chat_id: Int64; message_id: Int64;
      ParseMode: TParseMode = pmDefault; DisableWebPagePreview: Boolean=False;
      inline_message_id: String = ''; ReplyMarkup: TReplyMarkup = nil): Boolean;
    function editMessageText(const AMessage: String; ParseMode: TParseMode = pmDefault;
      DisableWebPagePreview: Boolean=False; ReplyMarkup: TReplyMarkup = nil): Boolean; overload;
    function editMessageMediaStream(aStream: TStream; media: TInputMedia; chat_id: Int64; message_id: Int64 = 0;
      inline_message_id: String = ''; ReplyMarkup: TReplyMarkup = nil): Boolean;
    function copyMessage(chat_id, from_chat_id, message_id: Int64; DisableNotification: Boolean = False;
      ReplyMarkup: TReplyMarkup = nil): Boolean;
    function forwardMessage(chat_id: Int64; from_chat_id: Int64; DisableNotification: Boolean;
      message_id: Int64): Boolean;
    function forwardMessage(chat_id: String; from_chat_id: Int64; DisableNotification: Boolean;
      message_id: Int64): Boolean;
    function getChat(chat_id: Int64; out aChat:TTelegramChatObj): Boolean;
    function getChat(chat_id: String; out aChat:TTelegramChatObj): Boolean;
    function getChatMember(chat_id: Int64; user_id: Int64): Boolean;
    function getChatMember(chat_id: Int64; user_id: Int64;
      out aChatMember: TTelegramChatMember): Boolean; overload;
    function getMe: Boolean;
    function getMyCommands(aScope: TBotCommandScope = nil; const aLanguage: String = ''): Boolean;
    function getWebhookInfo(out aWebhookInfo: TTelegramWebhookInfo): Boolean; 
    function setMyCommands(aBotCommands: TBotCommandArray; aScope: TBotCommandScope = nil;
      const aLanguage: String = ''): Boolean;
    { Specify an empty Update set ([]) to receive all updates regardless of type (default).
      If not specified or [utUnknown], the previous setting will be used }
    function setWebhook(const url: String; MaxConnections: Integer = 0; AllowedUpdates: TUpdateSet = [utUnknown]): Boolean; 
    function deleteWebhook: Boolean;
    function getUpdates(offset: Integer = 0; limit: Integer = 0; lp_timeout: Integer = 0; allowed_updates: TUpdateSet = []): Boolean;
 { To receive updates (LongPolling) You do not need to recalculate Offset in procedure below.
      The offset itself will take it from the previous UpdateID and increment by one.
      LongPollingTimeout in seconds! Timeout with 0 sec only for test cases}
    function getUpdatesEx(limit: Integer; lp_timeout: Integer; allowed_updates: TUpdateSet = []): Boolean;
    function kickChatMember(chat_id: Int64; user_id: Int64; kickDuration:Int64): Boolean; deprecated; // use banChatMember
    function SendAudio(chat_id: Int64; const audio: String; const Caption: String = '';
      ParseMode: TParseMode = pmDefault; Duration: Integer = 0; DisableNotification: Boolean = False;
      ReplyToMessageID: Integer = 0; const Performer:String = ''; const Title: String = '';
      ReplyMarkup: TReplyMarkup = nil): Boolean;
    function sendDocument(chat_id: Int64; const file_id: String; const Caption: String = '';
      ParseMode: TParseMode = pmDefault; DisableNotification: Boolean = False;
      ReplyToMessageID: Integer = 0; ReplyMarkup: TReplyMarkup = nil): Boolean;
    function sendDocumentByFileName(chat_id: Int64; const AFileName: String;
      const ACaption: String; ReplyMarkup: TReplyMarkup = nil; ParseMode: TParseMode = pmDefault): Boolean;
    function sendDocumentStream(chat_id: Int64;  const AFileName: String; ADocStream: TStream;
      const ACaption: String; ReplyMarkup: TReplyMarkup = nil): Boolean;
    function sendInvoice(chat_id: Int64; const Title, Description, Payload, ProviderToken,
      StartParameter, Currency: String; Prices: TLabeledPriceArray; ProviderData: TJSONObject = nil;
      const PhotoUrl: String = ''; PhotoSize: Integer = 0; PhotoWidth: Integer = 0; PhotoHeight: Integer = 0;
      NeedName: Boolean = False; NeedPhoneNumber: Boolean = False; NeedEmail: Boolean = False; NeedShippingAddress: Boolean = False;
      SendPhoneNumberToProvider: Boolean = False; SendEmailToProvider: Boolean = False;
      IsFlexible: Boolean = False;
      DisableNotification: Boolean = False; ReplyToMessageID: Integer = 0;
      ReplyMarkup: TReplyMarkup = nil): Boolean;
    function sendLocation(chat_id: Int64; Latitude, Longitude: Real; LivePeriod: Integer = 0;
      ParseMode: TParseMode = pmDefault; DisableWebPagePreview: Boolean=False;
      ReplyMarkup: TReplyMarkup = nil): Boolean;
    function sendMediaGroup(chat_id: Int64; media: TInputMediaArray;
      DisableWebPagePreview: Boolean=False; ReplyToMessageID: Integer = 0): Boolean;
    function sendMediaGroupByFileNames(chat_id: Int64; media: TInputMediaArray): Boolean;
    function sendMediaGroupByStreams(chat_id: Int64; const ACaption: String; StreamsList:TStringList): Boolean;
    function sendMessage(chat_id: Int64; const AMessage: String; ParseMode: TParseMode = pmDefault;
      DisableWebPagePreview: Boolean=False; ReplyMarkup: TReplyMarkup = nil;
      ReplyToMessageID: Integer = 0; DisableNotification: Boolean = False; MessageThreadID: Integer = _nullThrd;
      const BusinessConnectionID: String = ''): Boolean;
    function sendMessageChannel(const chat_id, AMessage: String; ParseMode: TParseMode = pmDefault;
      DisableWebPagePreview: Boolean=False; ReplyMarkup: TReplyMarkup = nil;
      ReplyToMessageID: Integer = 0): Boolean;
    function sendMessage(const AMessage: String; ParseMode: TParseMode = pmDefault;
      DisableWebPagePreview: Boolean=False; ReplyMarkup: TReplyMarkup = nil;
      ReplyToMessageID: Integer = 0; DisableNotification: Boolean = False): Boolean; overload;
    function sendPhoto(chat_id: Int64; const APhoto: String; const ACaption: String = '';
      ParseMode: TParseMode = pmDefault; ReplyMarkup: TReplyMarkup = nil;
      ReplyToMessageID: Integer = 0): Boolean;
    function sendPhotoByFileName(chat_id: Int64; const AFileName: String; const ACaption: String = '';
      ParseMode: TParseMode = pmDefault; ReplyMarkup: TReplyMarkup = nil;
      ReplyToMessageID: Integer = 0): Boolean;
    function sendPhoto(const APhoto: String; const ACaption: String = '';
      ParseMode: TParseMode = pmDefault; ReplyMarkup: TReplyMarkup = nil;
      ReplyToMessageID: Integer = 0): Boolean; overload;
 { AFileName is not the fullpath to the file but the filename for request POST data.
   Photo pass as a stream in the APhotoStream parameter }
    function sendPhotoStream(chat_id: Int64;  const AFileName: String; APhotoStream: TStream;
      const ACaption: String; ParseMode: TParseMode = pmDefault; ReplyMarkup: TReplyMarkup = nil): Boolean; overload;
    function sendVideo(chat_id: Int64; const AVideo: String; const ACaption: String = ''; ParseMode: TParseMode = pmDefault;
      ReplyMarkup: TReplyMarkup = nil; ReplyToMessageID: Integer = 0; Width: Integer = 0; Height: Integer = 0): Boolean;
    function sendVideo(const AVideo: String; const ACaption: String = ''; ParseMode: TParseMode = pmDefault;
      ReplyMarkup: TReplyMarkup = nil; ReplyToMessageID: Integer = 0; Width: Integer = 0; Height: Integer = 0): Boolean; overload;
    function sendVideoByFileName(chat_id: Int64; const AFileName: String;
      const ACaption: String; ParseMode: TParseMode = pmDefault; ReplyMarkup: TReplyMarkup = nil;
      ReplyToMessageID: Integer = 0; Width: Word=0; Height: Word=0): Boolean;
    function sendVideoStream(chat_id: Int64; const AFileName: String; AVideoStream: TStream;
      const ACaption: String = ''; ParseMode: TParseMode = pmDefault;  ReplyMarkup: TReplyMarkup = nil;
      ReplyToMessageID: Integer = 0; Width: Integer = 0; Height: Integer = 0): Boolean;
    function sendVoice(chat_id: Int64; const Voice: String; const Caption: String = '';
      ParseMode: TParseMode = pmDefault; Duration: Integer=0; DisableNotification: Boolean = False;
      ReplyToMessageID: Integer = 0; ReplyMarkup: TReplyMarkup = nil): Boolean;
    function sendAnimation(chat_id: Int64; const aAnimation: String; const ACaption: String = ''; ParseMode: TParseMode = pmDefault;
      ReplyMarkup: TReplyMarkup = nil; ReplyToMessageID: Integer = 0; Width: Integer = 0; Height: Integer = 0): Boolean;
    function sendAnimation(const aAnimation: String; const ACaption: String = ''; ParseMode: TParseMode = pmDefault;
      ReplyMarkup: TReplyMarkup = nil; ReplyToMessageID: Integer = 0; Width: Integer = 0; Height: Integer = 0): Boolean; 
    function sendAnimationByFileName(chat_id: Int64; const AFileName: String; const ACaption: String = '';
      ParseMode: TParseMode = pmDefault; ReplyMarkup: TReplyMarkup = nil; ReplyToMessageID: Integer = 0;
      Width: Integer = 0; Height: Integer = 0): Boolean;
    function sendPoll(chat_id: Int64; const Question: String; const Options: array of String;
      IsAnonymous: Boolean = True; aType: TPollType = ptRegular; AllowMultipleAnswers: Boolean = False;
      CorrectOptionID: Integer = -1; const Explanation: String = ''; explanation_parse_mode: TParseMode = pmDefault;
      ReplyMarkup: TReplyMarkup = nil): Boolean;
    function answerInlineQuery(const AnInlineQueryID: String; Results: TInlineQueryResultArray;
      CacheTime: Integer = 300; IsPersonal: Boolean = False; const NextOffset: String = '';
      const SwitchPmText: String = ''; const SwitchPmParameter: String = ''): Boolean;
    function getFile(const FileID: String): Boolean;
    function banChatMember(chat_id, user_id: Int64; until_date: Int64=0): Boolean;
    function unbanChatMember(chat_id, user_id: Int64; only_if_banned: Boolean = False): Boolean;
    { A special analog function that is not available in the API.
      It can be useful for simplifying and unifying the sending of content }
    function SendContent(aChatID: Int64; aContentType: TContentType; const aText, aMedia: String;
      aParseMode: TParseMode =pmDefault; aReplyMarkup: TReplyMarkup = nil): Boolean;
    function getChatAdministrators(chat_id: Int64; out aChatMembers: TJSONArray): Boolean;
    property APIEndPoint: String read GetAPIEndPoint write SetAPIEndPoint;
    property BotUser: TTelegramUserObj read FBotUser;
    property JSONResponse: TJSONData read FJSONResponse write SetJSONResponse;
    { Current chat_id that was received when processing the last update from the telegram server }
    property CurrentChatId: Int64 read FCurrentChatId;
    property CurrentUser: TTelegramUserObj read FCurrentUser;
    property CurrentChat: TTelegramChatObj read FCurrentChat;
    property CurrentMessage: TTelegramMessageObj read FCurrentMessage;
    property CurrentUpdate: TTelegramUpdateObj read FUpdate;
    property CurrentIsTopicMessage: Boolean read FCurrentIsTopicMessage; 
    property CurrentThreadID: Integer read FCurrentThreadId;
    property FileObj: TTelegramFile read FFileObj write SetFileObj;
    property Language: string read FLanguage write SetLanguage;
    property LogDebug: Boolean read FLogDebug write SetLogDebug;
    property OnLogMessage: TLogMessageEvent read FOnLogMessage write FOnLogMessage;
    property UpdateID: Integer read FUpdateID write SetUpdateID;
    { Gives a flag that the Update object is processed and there is no need for further processing
      and for calling the appropriate events }
    property UpdateProcessed: Boolean read FUpdateProcessed write SetUpdateProcessed;
    property RequestBody: String read FRequestBody write SetRequestBody;
    property Response: String read FResponse;
    property HTTPProxyUser: String read FHTTPProxyUser write FHTTPProxyUser;
    property HTTPProxyPassword: String read FHTTPProxyPassword write FHTTPProxyPassword;
    property HTTPProxyHost: String read FHTTPProxyHost write FHTTPProxyHost;
    property HTTPProxyPort: Word read FHTTPProxyPort write FHTTPProxyPort;
    property Token: String read FToken write FToken;
    { If you're using webhooks, you can perform a request to the API while sending an answer...
      In this case the method to be invoked in the method parameter of the request.}
    property RequestWhenAnswer: Boolean read FRequestWhenAnswer write SetRequestWhenAnswer;
    { if ProcessUpdate then the incoming update object will be processed.
      May be useful for multithreaded work when updates is receiving in one Sender object and
      processing and sending to telegram server in another Sender object. In this case ProcessUpdate = False}
    property ProcessUpdate: Boolean read FProcessUpdate write SetProcessUpdate;
    property CommandHandlers [const Command: String]: TCommandEvent read GetCommandHandlers
      write SetCommandHandlers;  // It can create command handlers by assigning their to array elements
    property ChannelCommandHandlers [const Command: String]: TCommandEvent read GetChannelCommandHandlers
      write SetChannelCommandHandlers;  // It can create command handlers by assigning their to array elements
    property BotUsername: String read FBotUsername write SetBotUsername;
    property LastErrorCode: Integer read FLastErrorCode write SetLastErrorCode;
    property LastErrorDescription: String read FLastErrorDescription write SetLastErrorDescription;
    property Logger: TEventLog read FLogger write SetLogger;

    property UpdateLogger: TtgStatLog read FUpdateLogger write SetUpdateLogger; //We will log the update object completely if need
    property Timeout: Integer read GetTimeout write SetTimeout;

{ After the parse of the update object prior to calling all other custom events (OnReceive...) }
    property OnAfterParseUpdate: TNotifyEvent read FOnAfterParseUpdate write SetOnAfterParseUpdate;
{ After calling the rest of events OnReceive... }
    property OnReceiveUpdate: TOnUpdateEvent read FOnReceiveUpdate write FOnReceiveUpdate;
    property OnReceiveMessage: TMessageEvent read FOnReceiveMessage write FOnReceiveMessage;
    property OnReceiveEditedMessage: TMessageEvent read FOnReceiveEditedMessage
      write FOnReceiveEditedMessage;
    property OnReceiveCallbackQuery: TCallbackEvent read FOnReceiveCallbackQuery
      write FOnReceiveCallbackQuery;
    property OnReceiveChannelPost: TMessageEvent read FOnReceiveChannelPost write FOnReceiveChannelPost;
    property OnReceiveEditedChannelPost: TMessageEvent read FOnReceiveEditedChannelPost
      write FOnReceiveEditedChannelPost;
    property OnReceiveInlineQuery: TInlineQueryEvent read FOnReceiveInlineQuery
      write FOnReceiveInlineQuery;
    property OnReceiveChosenInlineResult: TChosenInlineResultEvent read FOnReceiveChosenInlineResult
      write FOnReceiveChosenInlineResult;
    property OnReceivePreCheckoutQuery: TPreCheckoutQueryEvent read FOnReceivePreCheckoutQuery
      write FOnReceivePreCheckoutQuery;
    property OnReceiveSuccessfulPayment: TMessageEvent read FOnReceiveSuccessfulPayment
      write FOnReceiveSuccessfulPayment;  
    property OnReceiveBusinessConnection: TBusinessConnectionEvent read FOnReceiveBusinessConnection
      write FOnReceiveBusinessConnection;
    property OnReceiveBusinessMessage: TMessageEvent read FOnReceiveBusinessMessage
      write FOnReceiveBusinessMessage;    
    property OnReceiveMyChatMemberUpdated: TChatMemberEvent read FOnReceiveMyChatMemberUpdated
      write FOnReceiveMyChatMemberUpdated;
    property OnReceiveChatMemberUpdated: TChatMemberEvent read FOnReceiveChatMemberUpdated
      write FOnReceiveChatMemberUpdated;
  end;

 { Procedure style method to send message from Bot to chat/user }
function TgBotSendMessage(const AToken: String; chat_id: Int64; const AMessage: String;
  out AReply: String;
  ParseMode: TParseMode = pmDefault; DisableWebPagePreview: Boolean=False;
  AReplyMarkup: TReplyMarkup = nil; ReplyToMessageID: Integer = 0): Boolean;

function StringToParseMode(const S: String): TParseMode;
function StringToMediaType(const S: String): TMediaType;

var
  TelegramAPI_URL: String ='https://api.telegram.org/bot';

implementation

uses
  jsonparser, jsonscanner
{  added tgfclhttpclientbroker unit by default for backward compatibility.
  But in your projects it is better to specify the appropriate broker explicitly }
  , tgfclhttpclientbroker
  ;

const
//  API names constants

  s_editMessageText='editMessageText'; 
  s_editMessageMedia='editMessageMedia';
  s_editMessageReplyMarkup='editMessageReplyMarkup';
  s_sendMessage='sendMessage';
  s_sendPhoto='sendPhoto';
  s_sendAudio='sendAudio';
  s_sendVoice='sendVoice';
  s_sendVideo='sendVideo';
  s_sendAnimation='sendAnimation';
  s_sendDocument='sendDocument';
  s_sendLocation='sendLocation';
  s_sendInvoice='sendInvoice';
  s_sendMediaGroup='sendMediaGroup';
  s_sendPoll='sendPoll';
  s_getChat = 'getChat';
  s_getMyCommands = 'getMyCommands'; 
  s_setMyCommands = 'setMyCommands';
  s_getWebhookInfo = 'getWebhookInfo';
  s_setWebhook = 'setWebhook';  
  s_deleteWebhook = 'deleteWebhook';
  s_getUpdates='getUpdates';
  s_getMe='getMe';
  s_getChatMember='getChatMember';
  s_forwardMessage='forwardMessage';  
  s_copyMessage='copyMessage';
  s_answerInlineQuery='answerInlineQuery';
  s_answerPreCheckoutQuery='answerPreCheckoutQuery';
  s_deleteMessage='deleteMessage';
  s_getFile = 'getFile';
  //s_kickChatMember = 'kickChatMember';  
  s_banChatMember = 'banChatMember';
  s_unbanChatMember = 'unbanChatMember';
  s_commands = 'commands';
  s_scope='scope';


  s_Method='method';
  s_Url = 'url';
  s_MaxConnections = 'max_connections';
  s_Text = 'text';
  s_ChatId = 'chat_id';
  s_UserID = 'user_id';
  s_MessageId = 'message_id';
  s_InlineMessageId = 'inline_message_id';
  s_Document = 'document';
  s_Photo = 'photo';
  s_Video = 'video';
  s_Audio = 'audio';
  s_Voice = 'voice';
  s_Animation='animation';
  s_Caption = 'caption';
  s_Media = 'media';
  s_ParseMode = 'parse_mode';
  s_ReplyMarkup = 'reply_markup';
  s_ReplyToMessageID = 'reply_to_message_id';
  s_Latitude = 'latitude';
  s_Longitude = 'longitude';
  s_LivePeriod = 'live_period';
  s_DsblWbpgPrvw = 'disable_web_page_preview';
  s_DsblNtfctn = 'disable_notification';
  s_Performer = 'performer';
  s_Duration = 'duration';
  s_SupportsStreaming = 'supports_streaming';
  s_InlineKeyboard = 'inline_keyboard';
  s_Keyboard = 'keyboard';
  s_RemoveKeyboard = 'remove_keyboard';
  s_ResizeKeyboard = 'resize_keyboard';
  s_OneTimeKeyboard = 'one_time_keyboard';
  s_RequestContact = 'request_contact';
  s_RequestLocation = 'request_location';
  s_SwitchInlineQuery = 'switch_inline_query';
  s_CallbackData = 'callback_data';
  s_SwitchInlineQueryCurrentChat = 's_switch_inline_query_current_chat';
  s_Selective = 'selective';
  s_InputFieldPlaceholder = 'input_field_placeholder';
  s_ForceReply = 'force_reply';
  s_Offset = 'offset';
  s_Limit = 'limit';
  s_Timeout = 'timeout';
  s_AllowedUpdates = 'allowed_updates';
  s_Ok = 'ok';
  s_ErrorCode = 'error_code';
  s_ErrorMessage = 'error_message';
  s_Description = 'description';
  s_Result = 'result';
  s_BotCommand = 'bot_command';
  s_Amount = 'amount';
  s_Label = 'label';
  s_Payload = 'payload';
  s_ProviderToken = 'provider_token';
  s_ProviderData = 'provider_data';
  s_StartParameter = 'start_parameter';
  s_Currency = 'currency';
  s_Prices = 'prices';
  s_PreCheckoutQueryID = 'pre_checkout_query_id';
  s_FromChatID='from_chat_id';
  s_UntilDate = 'until_date';
  s_OnlyIfBanned = 'only_if_banned';
  s_Command = 'command';
  s_LanguageCode='language_code';
  s_Question='question';
  s_Options='options';
  s_IsAnonymous='is_anonymous';
  s_quiz='quiz';
  s_regular='regular';  
  s_AllowMultipleAnswers='allows_multiple_answers';
  s_CorrectOptionID='correct_option_id';
  s_Explanation='explanation';

  s_CallbackQueryID = 'callback_query_id';
  s_ShowAlert = 'show_alert';

  s_ID = 'id';
  s_InputMessageContent = 'input_message_content';
  s_Type = 'type';
  s_Title = 'title';

  s_MessageText = 'message_text';

  s_InlineQueryID = 'inline_query_id';
  s_Results = 'results';
  s_CacheTime = 'cache_time';
  s_IsPersonal = 'is_personal';
  s_NextOffset = 'next_offset';
  s_SwitchPmText = 'switch_pm_text';
  s_SwitchPmParameter = 'switch_pm_parameter';

  s_FileID = 'file_id';

  s_answerCallbackQuery = 'answerCallbackQuery';

  s_PhotoUrl ='photo_url';
  s_ThumbUrl ='thumb_url';
  s_VideoUrl ='video_url';
  s_MimeType ='mime_type';
  s_PhotoHeight = 'photo_height';
  s_PhotoWidth = 'photo_width';
  s_PhotoSize = 'photo_size';
  s_AudioFileID = 'audio_file_id';
  s_DocumentFileID = 'document_file_id';
  s_PhotoFileID = 'photo_file_id';
  s_VideoFileID = 'video_file_id';
  s_VoiceFileID = 'voice_file_id';
  s_Mpeg4Url = 'mpeg4_url';
  s_Mpeg4Width = 'mpeg4_width';
  s_Mpeg4Height = 'mpeg4_height';
  s_Width = 'width';
  s_Height = 'height';

  s_NeedName = 'need_name';
  s_NeedPhoneNumber = 'need_phone_number';
  s_NeedEmail = 'need_email';
  s_NeedShippingAddress = 'need_shipping_address';
  s_SendPhoneNumber2Provider = 'send_phone_number_to_provider';
  s_SendEmail2Provider = 'send_email_to_provider';
  s_IsFlexible = 'is_flexible';

  s_AudioDuration = 'audio_duration';
  s_AudioUrl = 'audio_url';

  s_Default='default';
  s_AlPrvtChts='all_private_chats';
  s_AlGrpChats='all_group_chats';
  s_AlChtAdmnstrtrs='all_chat_administrators';
  s_Cht='chat';
  s_ChtAdmnstrtrs='chat_administrators';
  s_ChtMmbr='chat_member';
  s_MsgThrdID ='message_thread_id';

  s_GetChatAdministrators='getChatAdministrators';

  s_BsnsCnctnID='business_connection_id';

  ParseModes: array[TParseMode] of PChar = ('', 'Markdown', 'HTML', 'MarkdownV2');
  MediaTypes: array[TMediaType] of PChar = ('photo', 'video', '');
  QueryResultTypeArray: array[TInlineQueryResultType] of PChar =
    ('article', 'photo', 'video', 'audio', 'voice', 'mpeg4_gif', 'document', '');

  TgBotUrlStart = 'https://t.me/';

function PollTypeToAlias(aType: TPollType): String;
begin
  case aType of
    ptRegular: Result:=s_Regular;
    ptQuiz:    Result:=s_quiz;
  else
    Result:=EmptyStr;
  end;
end;

function StringToIQRType(const S: String): TInlineQueryResultType;
var
  iqrt: TInlineQueryResultType;
begin
  Result:=qrtUnknown;
  for iqrt:=Low(QueryResultTypeArray) to High(QueryResultTypeArray) do
    if AnsiSameStr(QueryResultTypeArray[iqrt], S) then
      Exit(iqrt);
end;

function StringToParseMode(const S: String): TParseMode;
var
  pm: TParseMode;
begin
  Result:=pmDefault;
  for pm:=Low(ParseModes) to High(ParseModes) do
    if AnsiSameStr(ParseModes[pm], S) then
      Exit(pm);
end;

function StringToMediaType(const S: String): TMediaType;
var
  mt: TMediaType;
begin
  Result:=mtUnknown;
  for mt:=Low(MediaTypes) to High(MediaTypes) do
    if AnsiSameStr(MediaTypes[mt], S) then
      Exit(mt);
end;

function TgBotSendMessage(const AToken: String; chat_id: Int64;
  const AMessage: String; out AReply: String; ParseMode: TParseMode;
  DisableWebPagePreview: Boolean; AReplyMarkup: TReplyMarkup;
  ReplyToMessageID: Integer): Boolean;
var
  ABot: TTelegramSender;
begin
  Result:=False;
  ABot:=TTelegramSender.Create(AToken);
  try
    ABot.APIEndPoint:=TelegramAPI_URL;
    Result:=ABot.sendMessage(chat_id, AMessage, ParseMode, DisableWebPagePreview, AReplyMarkup, ReplyToMessageID);
    AReply:=ABot.Response;
  finally
    ABot.Free;
  end;
end;

{ TBotCommandScope }

function TBotCommandScope.GetScopeType: TCommandScopeType;
begin
  case Strings[s_Type] of
    s_Default:         Result:=stDefault;
    s_AlPrvtChts:      Result:=stAllPrivateChats;
    s_AlGrpChats:      Result:=stAllGroupChats;
    s_AlChtAdmnstrtrs: Result:=stAllChatAdministrators;
    s_Cht:             Result:=stSpecificChat;
    s_ChtAdmnstrtrs:   Result:=stChatAdministrators;
    s_ChtMmbr:         Result:=stChatMember;
  else
    Result:=stDefault;
  end;
end;

procedure TBotCommandScope.SetScopeChat(AValue: TCommandScopeType);
begin
  case AValue of
    stDefault:               Strings[s_Type]:=s_Default;
    stAllPrivateChats:       Strings[s_Type]:=s_AlPrvtChts;
    stAllGroupChats:         Strings[s_Type]:=s_AlGrpChats;
    stAllChatAdministrators: Strings[s_Type]:=s_AlChtAdmnstrtrs;
    stSpecificChat:          Strings[s_Type]:=s_Cht;
    stChatAdministrators:    Strings[s_Type]:=s_ChtAdmnstrtrs;
    stChatMember:            Strings[s_Type]:=s_ChtMmbr;
  else
    Strings[s_Type]:=s_Default;
  end;
end;

{ TBotCommand }

function TBotCommand.GetCommand: String;
begin
  Result:=Strings[s_Command];
end;

function TBotCommand.GetDescription: String;
begin
  Result:=Strings[s_Description];
end;

procedure TBotCommand.SetCommand(const AValue: String);
begin
  Strings[s_Command]:=AValue;
end;

procedure TBotCommand.SetDescription(const AValue: String);
begin
  Strings[s_Description]:=AValue;
end;

constructor TBotCommand.Create(const aCommand, aDescription: String);
begin
  inherited Create;
  Command:=aCommand;
  Description:=aDescription;
end;

{ TBotCommandArray }

procedure TBotCommandArray.AddCommands(aBotCommands: array of String);
var
  i, c: Integer;
begin
  c:=Length(aBotCommands) div 2;
  for i:=0 to c-1 do
    AddCommand(aBotCommands[i*2], aBotCommands[i*2+1]);
end;

procedure TBotCommandArray.AddCommand(const aCommand, aDescription: String);
begin
  Add(TBotCommand.Create(aCommand, aDescription));
end;

{ TKeyboardButtonArray }

function TKeyboardButtonArray.Add(aButtons: TKeyboardButtons): Integer;
begin
  Result:=Add(aButtons as TJSONArray);
end;

function TKeyboardButtonArray.Add: TKeyboardButtons;
begin
  Result:=TKeyboardButtons.Create;
  Add(Result);
end;

{ TInlineQueryResultArray }

function TInlineQueryResultArray.Add(aInlineQueryResult: TInlineQueryResult
  ): Integer;
begin
  Result:=Add(aInlineQueryResult as TJSONObject);
end;

function TInlineQueryResultArray.Add: TInlineQueryResult;
begin
  Result:=TInlineQueryResult.Create;
  Add(Result);
end;

{ TLabeledPriceArray }

constructor TLabeledPriceArray.Create(const APortionLabel: String;
  APortionAmount: Integer);
var
  ALabeledPrice: TLabeledPrice;
begin
  inherited Create;
  ALabeledPrice:=AddLabeledPrice;
  ALabeledPrice.PortionLabel:=APortionLabel;
  ALabeledPrice.PortionAmount:=APortionAmount;
end;

function TLabeledPriceArray.AddLabeledPrice: TLabeledPrice;
begin
  Result:=TLabeledPrice.Create;
  Add(Result);
end;

{ TLabeledPrice }

function TLabeledPrice.GetPortionAmount: Integer;
begin
  Result:=Integers[s_Amount];
end;

function TLabeledPrice.GetPortionLabel: String;
begin
  Result:=Strings[s_Label];
end;

procedure TLabeledPrice.SetPortionAmount(AValue: Integer);
begin
  Integers[s_Amount]:=AValue;
end;

procedure TLabeledPrice.SetPortionLabel(AValue: String);
begin
  Strings[s_Label]:=AValue;
end;

{ TIntegerHash }

class function TIntegerHash.hash(i: Int64; n: Integer): Integer;
begin
  Result:=i mod n;
end;

{ TInputMediaPhoto }

constructor TInputMediaPhoto.Create;
begin
  inherited Create;
  MediaType:=mtPhoto;
end;

{ TInputMediaArray }

function TInputMediaArray.Add(AMedia: TInputMedia): Integer;
begin
  Result:=Add(AMedia as TJSONObject);
end;

function TInputMediaArray.AddPhoto: TInputMediaPhoto;
begin
  Result:=TInputMediaPhoto.Create;
  Add(Result);
end;

function TInputMediaArray.AddPhoto(const APhoto: String): Integer;
var
  AnInputMedia: TInputMedia;
begin
  AnInputMedia:=TInputMediaPhoto.Create;
  AnInputMedia.Media:=APhoto;
  Result:=Add(AnInputMedia);
end;

function TInputMediaArray.AddVideo: TInputMediaVideo;
begin
  Result:=TInputMediaVideo.Create;
  Add(Result);
end;

function TInputMediaArray.AddVideo(const AVideo: String): Integer;
var
  AnInputMedia: TInputMedia;
begin
  AnInputMedia:=TInputMediaVideo.Create;
  AnInputMedia.Media:=AVideo;
  Result:=Add(AnInputMedia);
end;

{ TInputMediaVideo }

function TInputMediaVideo.GetDuration: Integer;
begin
  Result:=Get(s_Duration, 0);
end;

function TInputMediaVideo.GetHeight: Integer;
begin
  Result:=Get(s_Height, 0);
end;

function TInputMediaVideo.GetSupportsStreaming: Boolean;
begin
  Result:=Get(s_SupportsStreaming, False);
end;

function TInputMediaVideo.GetWidth: Integer;
begin
  Result:=Get(s_Width, 0);
end;

procedure TInputMediaVideo.SetDuration(AValue: Integer);
begin
  Integers[s_Duration]:=AValue;
end;

procedure TInputMediaVideo.SetHeight(AValue: Integer);
begin
  Integers[s_Height]:=AValue;
end;

procedure TInputMediaVideo.SetSupportsStreaming(AValue: Boolean);
begin
  Booleans[s_SupportsStreaming]:=AValue;
end;

procedure TInputMediaVideo.SetWidth(AValue: Integer);
begin
  Integers[s_Width]:=AValue;
end;

constructor TInputMediaVideo.Create;
begin
  inherited Create;
  MediaType:=mtVideo;
end;

{ TInputMedia }

function TInputMedia.GetCaption: String;
begin
  Result:=Get(s_Caption, EmptyStr);
end;

function TInputMedia.GetMedia: String;
begin
  Result:=Get(s_Media, EmptyStr);
end;

function TInputMedia.GetMediaType: TMediaType;
begin
  Result:=StringToMediaType(Get(s_Type, EmptyStr));
end;

function TInputMedia.GetParseMode: TParseMode;
begin
  Result:=StringToParseMode(Get(s_ParseMode, EmptyStr));
end;

procedure TInputMedia.SetCaption(AValue: String);
begin
  Strings[s_Caption]:=AValue;
end;

procedure TInputMedia.SetMedia(AValue: String);
begin
  Strings[s_Media]:=AValue;
end;

procedure TInputMedia.SetMediaType(AValue: TMediaType);
begin
  Strings[s_Type]:=MediaTypes[AValue];
end;

procedure TInputMedia.SetParseMode(AValue: TParseMode);
begin
  Strings[s_ParseMode]:=ParseModes[AValue];
end;

{ TInlineKeyboard }

function TInlineKeyboard.Add(AButtons: TInlineKeyboardButtons): Integer;
begin
  Result:=Add(AButtons as TJSONArray);
end;

function TInlineKeyboard.Add: TInlineKeyboardButtons;
begin
  Result:=TInlineKeyboardButtons.Create;
  Add(Result);
end;

procedure TInlineKeyboard.AddButton(aButton: TInlineKeyboardButton; MaxColsinRow: Integer);
var
  aInlnKybrdBtns: TInlineKeyboardButtons;
begin
  if Count=0 then
    aInlnKybrdBtns:=Add
  else
    aInlnKybrdBtns:=TInlineKeyboardButtons(Items[Count-1]);
  if (MaxColsinRow<>0) and (aInlnKybrdBtns.Count>=MaxColsinRow) then
    aInlnKybrdBtns:=Add;
  aInlnKybrdBtns.Add(aButton);
end;

procedure TInlineKeyboard.AddButton(const AButtonText, CallbackData: String;
  MaxColsinRow: Integer);
var
  aButton: TInlineKeyboardButton;
begin
  aButton:=TInlineKeyboardButton.Create(AButtonText);
  aButton.callback_data:=CallbackData;
  AddButton(aButton, MaxColsinRow);
end;

{ TInputMessageContent }

function TInputMessageContent.GetMessageText: String;
begin
  Result:=Strings[s_MessageText];
end;

function TInputMessageContent.GetParseMode: TParseMode;
begin
  Result:=StringToParseMode(Get(s_ParseMode, EmptyStr));
end;

procedure TInputMessageContent.SetMessageText(AValue: String);
begin
  Strings[s_MessageText]:=AValue;
end;

procedure TInputMessageContent.SetParseMode(AValue: TParseMode);
begin
  Strings[s_ParseMode]:=ParseModes[AValue];
end;

constructor TInputMessageContent.Create(const AMessageText: String;
  AParseMode: TParseMode);
begin
  if AParseMode=pmDefault then
    inherited Create([s_MessageText, AMessageText])
  else
    inherited Create([s_MessageText, AMessageText, s_ParseMode, ParseModes[AParseMode]])
end;

{ TInlineQueryResult }

function TInlineQueryResult.GetAudioDuration: Integer;
begin
  Result:=Get(s_AudioDuration, 0);
end;

function TInlineQueryResult.GetAudioFileID: String;
begin
  Result:=Get(s_AudioFileID, EmptyStr);
end;

function TInlineQueryResult.GetAudioUrl: String;
begin
  Result:=Get(s_AudioUrl, EmptyStr);
end;

function TInlineQueryResult.GetCaption: String;
begin
  Result:=Get(s_Caption, EmptyStr);
end;

function TInlineQueryResult.GetDescription: String;
begin
  Result:=Get(s_Description, EmptyStr);
end;

function TInlineQueryResult.GetDocumentFileID: String;
begin
  Result:=Get(s_DocumentFileID, EmptyStr);
end;

function TInlineQueryResult.GetID: String;
begin
  Result:=Strings[s_ID];
end;

function TInlineQueryResult.GetInputMessageContent: TInputMessageContent;
begin
  Result:=Objects[s_InputMessageContent] as TInputMessageContent;
end;

function TInlineQueryResult.GetIQRType: TInlineQueryResultType;
begin
  Result:=StringToIQRType(Strings[s_Type]);
end;

function TInlineQueryResult.GetMimeType: String;
begin
  Result:=Get(s_MimeType, EmptyStr);
end;

function TInlineQueryResult.GetMpeg4Height: Integer;
begin
  Result:=Get(s_Mpeg4Height, 0);
end;

function TInlineQueryResult.GetMpeg4Url: String;
begin
  Result:=Get(s_Mpeg4Url, EmptyStr);
end;

function TInlineQueryResult.GetMpeg4Width: Integer;
begin
  Result:=Get(s_Mpeg4Width, 0);
end;

function TInlineQueryResult.GetParseMode: TParseMode;
begin
  Result:=StringToParseMode(Get(s_ParseMode, EmptyStr));
end;

function TInlineQueryResult.GetPerformer: String;
begin
  Result:=Get(s_Performer, EmptyStr);
end;

function TInlineQueryResult.GetPhotoFileID: String;
begin
  Result:=Get(s_PhotoFileID, EmptyStr);
end;

function TInlineQueryResult.GetPhotoHeight: Integer;
begin
  Result:=Get(s_PhotoHeight, 0);
end;

function TInlineQueryResult.GetPhotoUrl: String;
begin
  Result:=Get(s_PhotoUrl, '');
end;

function TInlineQueryResult.GetPhotoWidth: Integer;
begin
  Result:=Get(s_PhotoWidth, 0);
end;

function TInlineQueryResult.GetReplyMarkup: TReplyMarkup;
begin
  Result:=Find(s_ReplyMarkup, jtObject) as TReplyMarkup;
end;

function TInlineQueryResult.GetThumbUrl: String;
begin
  Result:=Get(s_ThumbUrl, '');
end;

function TInlineQueryResult.GetTitle: String;
begin
  Result:=Strings[s_Title];
end;

function TInlineQueryResult.GetVideoFileID: String;
begin
  Result:=Get(s_VideoFileID, EmptyStr);
end;

function TInlineQueryResult.GetVideoUrl: String;
begin
  Result:=Get(s_VideoUrl, '');
end;

function TInlineQueryResult.GetVoiceFileID: String;
begin
  Result:=Get(s_VoiceFileID, '');
end;

procedure TInlineQueryResult.SetAudioDuration(AValue: Integer);
begin
  Integers[s_AudioDuration]:=AValue;
end;

procedure TInlineQueryResult.SetAudioFileID(AValue: String);
begin
  Strings[s_AudioFileID]:=AValue;
end;

procedure TInlineQueryResult.SetAudioUrl(AValue: String);
begin
  Strings[s_AudioUrl]:=AValue;
end;

procedure TInlineQueryResult.SetCaption(AValue: String);
begin
  Strings[s_Caption]:=AValue;
end;

procedure TInlineQueryResult.SetDescription(AValue: String);
begin
  Strings[s_Description]:=AValue;
end;

procedure TInlineQueryResult.SetDocumentFileID(AValue: String);
begin
  Strings[s_DocumentFileID]:=AValue;
end;

procedure TInlineQueryResult.SetID(AValue: String);
begin
  Strings[s_ID]:=AValue;
end;

procedure TInlineQueryResult.SetInputMessageContent(AValue: TInputMessageContent
  );
begin
  Objects[s_InputMessageContent]:=AValue;
end;

procedure TInlineQueryResult.SetIQRType(AValue: TInlineQueryResultType);
begin
  Strings[s_Type]:=QueryResultTypeArray[AValue];
end;

procedure TInlineQueryResult.SetMimeType(AValue: String);
begin
  Strings[s_MimeType]:=AValue;
end;

procedure TInlineQueryResult.SetMpeg4Height(AValue: Integer);
begin
  Integers[s_Mpeg4Height]:=AValue;
end;

procedure TInlineQueryResult.SetMpeg4Url(AValue: String);
begin
  Strings[s_Mpeg4Url]:=AValue;
end;

procedure TInlineQueryResult.SetMpeg4Width(AValue: Integer);
begin
  Integers[s_Mpeg4Height]:=AValue;
end;

procedure TInlineQueryResult.SetParseMode(AValue: TParseMode);
begin
  Strings[s_ParseMode]:=ParseModes[AValue];
end;

procedure TInlineQueryResult.SetPerformer(AValue: String);
begin
  Strings[s_Performer]:=AValue;
end;

procedure TInlineQueryResult.SetPhotoFileID(AValue: String);
begin
  Strings[s_PhotoFileID]:=AValue;
end;

procedure TInlineQueryResult.SetPhotoHeight(AValue: Integer);
begin
  Integers[s_PhotoHeight]:=AValue;
end;

procedure TInlineQueryResult.SetPhotoUrl(AValue: String);
begin
  Strings[s_PhotoUrl]:=AValue;
end;

procedure TInlineQueryResult.SetPhotoWidth(AValue: Integer);
begin
  Integers[s_PhotoWidth]:=AValue;
end;

procedure TInlineQueryResult.SetReplyMarkup(AValue: TReplyMarkup);
begin
  Objects[s_ReplyMarkup]:=AValue;
end;

procedure TInlineQueryResult.SetThumbUrl(AValue: String);
begin
  Strings[s_ThumbUrl]:=AValue;
end;

procedure TInlineQueryResult.SetTitle(AValue: String);
begin
  Strings[s_Title]:=AValue;
end;

procedure TInlineQueryResult.SetVideoFileID(AValue: String);
begin
  Strings[s_VideoFileID]:=AValue;
end;

procedure TInlineQueryResult.SetVideoUrl(AValue: String);
begin
  Strings[s_VideoUrl]:=AValue;
end;

procedure TInlineQueryResult.SetVoiceFileID(AValue: String);
begin
  Strings[s_VoiceFileID]:=AValue;
end;

{ TStringHash }

class function TStringHash.hash(s: String; n: Integer): Integer;
var
  c: Char;
begin
  Result := 0;
  for c in s do
    Inc(Result,Ord(c));
  Result := Result mod n;
end;

  { TKeyboardButtons }

function TKeyboardButtons.GetButtons(Index : Integer): TKeyboardButton;
begin
  Result:=Items[Index] as TKeyboardButton;
end;

procedure TKeyboardButtons.SetButtons(Index : Integer; AValue: TKeyboardButton);
begin
  Items[Index]:=AValue;
end;

constructor TKeyboardButtons.Create(const AText: String);
begin
  inherited Create;
  AddButton(AText);
end;

constructor TKeyboardButtons.Create(const AButtons: array of String);
begin
  inherited Create;
  AddButtons(AButtons);
end;

function TKeyboardButtons.AddButton(const AButtonText: String): Integer;
begin
  Result:=Add(TKeyboardButton.Create(AButtonText));
end;

procedure TKeyboardButtons.AddButtons(const AButtons: array of String);
var
  i: Integer;
begin
  for i:=0 to Length(AButtons)-1 do
    Add(TKeyboardButton.Create(AButtons[i]));
end;

{ TKeyboardButton }

function TKeyboardButton.GetRequestContact: Boolean;
begin
  Result:=Get(s_RequestContact, False);
end;

function TKeyboardButton.GetRequestLocation: Boolean;
begin
  Result:=Get(s_RequestLocation, False);
end;

function TKeyboardButton.Gettext: String;
begin
  Result:=Strings[s_text];
end;

procedure TKeyboardButton.SetRequestContact(AValue: Boolean);
begin
  Booleans[s_RequestContact]:=AValue;
end;

procedure TKeyboardButton.SetRequestLocation(AValue: Boolean);
begin
  Booleans[s_RequestLocation]:=AValue;
end;

procedure TKeyboardButton.Settext(AValue: String);
begin
  Strings[s_text]:=AValue;
end;

constructor TKeyboardButton.Create(const AText: String);
begin
  inherited Create;
  Add(s_text, AText);
end;

{ TInlineKeyboardButtons }

constructor TInlineKeyboardButtons.Create(const AButtonText,
  CallbackData: String);
begin
  inherited Create;
  AddButton(AButtonText, CallbackData);
end;

function TInlineKeyboardButtons.AddButton(const AButtonText, CallbackData: String): Integer;
var
  btn: TInlineKeyboardButton;
begin
  btn:=TInlineKeyboardButton.Create(AButtonText);
  btn.callback_data:=CallbackData;
  Result:=Add(btn);
end;

function TInlineKeyboardButtons.AddButtonUrl(const AButtonText, AUrl: String
  ): Integer;
var
  btn: TInlineKeyboardButton;
begin
  btn:=TInlineKeyboardButton.Create(AButtonText);
  btn.url:=AUrl;
  Result:=Add(btn);
end;

function TInlineKeyboardButtons.AddButtonInline(const AButtonText,
  AQuery: String): Integer;
var
  btn: TInlineKeyboardButton;
begin
  btn:=TInlineKeyboardButton.Create(AButtonText);
  btn.switch_inline_query:=AQuery;
  Result:=Add(btn);
end;

procedure TInlineKeyboardButtons.AddButtons(const AButtons: array of String);
var
  btn: TInlineKeyboardButton;
  i, c: Integer;
begin
  c:=Length(AButtons) div 2;
  for i:=0 to c-1 do
  begin
    btn:=TInlineKeyboardButton.Create(AButtons[i*2]);
    btn.callback_data:=AButtons[i*2+1];
    Add(btn);
  end;
end;

{ TReplyMarkup }

function TReplyMarkup.GetForceReply: Boolean;
begin
  Result:=Booleans[s_ForceReply];
end;

function TReplyMarkup.GetInlineKeyBoard: TInlineKeyboard;
begin
  Result:=Arrays[s_InlineKeyboard] as TInlineKeyboard;
end;

function TReplyMarkup.GetInputFieldPlaceholder: String;
begin
  Result:=Get(s_InputFieldPlaceholder, EmptyStr);
end;

function TReplyMarkup.GetOneTimeKeyboard: Boolean;
begin
  Result:=Get(s_OneTimeKeyboard, False);
end;

function TReplyMarkup.GetRemoveKeyboard: Boolean;
begin
  Result:=Get(s_RemoveKeyboard, False);
end;

function TReplyMarkup.GetReplyKeyboardMarkup: TKeyboardButtonArray;
begin
  Result:=Arrays[s_Keyboard] as TKeyboardButtonArray;
end;

function TReplyMarkup.GetResizeKeyboard: Boolean;
begin
  Result:=Get(s_ResizeKeyboard, False);     // default False
end;

function TReplyMarkup.GetSelective: Boolean;
begin
  Result:=Get(s_Selective, False);     // default ??? False
end;

procedure TReplyMarkup.SetForceReply(AValue: Boolean);
begin
  if not AValue then
  begin
    if IndexOfName(s_ForceReply)>-1 then
      Delete(s_ForceReply);
    if IndexOfName(s_Selective)>-1 then
      Delete(s_Selective);
  end
  else
    Booleans[s_ForceReply]:=True;
end;

procedure TReplyMarkup.SetInlineKeyBoard(AValue: TInlineKeyboard);
begin
  Arrays[s_InlineKeyboard]:=AValue;
end;

procedure TReplyMarkup.SetInputFieldPlaceholder(AValue: String);
begin
  Strings[s_InputFieldPlaceholder]:=AValue;
end;

procedure TReplyMarkup.SetOneTimeKeyboard(AValue: Boolean);
begin
  Booleans[s_OneTimeKeyboard]:=AValue;
end;

procedure TReplyMarkup.SetRemoveKeyboard(AValue: Boolean);
begin
  Booleans[s_RemoveKeyboard]:=AValue;
end;

procedure TReplyMarkup.SetReplyKeyboardMarkup(AValue: TKeyboardButtonArray);
begin
  Arrays[s_Keyboard]:=AValue;
end;

procedure TReplyMarkup.SetResizeKeyboard(AValue: Boolean);
begin
  Booleans[s_ResizeKeyboard]:=AValue;
end;

procedure TReplyMarkup.SetSelective(AValue: Boolean);
begin
  if AValue then
    if not ForceReply then
      ForceReply:=True;
  Booleans[s_Selective]:=AValue;
end;

class function TReplyMarkup.CreateFromObject(aObject: TJSONObject
  ): TReplyMarkup;
Var
  I: Integer;
begin
  Result:=TReplyMarkup.Create;
  try
    For I:=0 to aObject.Count-1 do
      Result.Add(aObject.Names[I],aObject.Items[I].Clone);
  except
    FreeAndNil(Result);
    Raise;
  end;
end;

class function TReplyMarkup.CreateFromString(const aJSONString: String
  ): TReplyMarkup;
var
  aJSONObject: TJSONObject;
begin
  aJSONObject:=TTelegramSender.StringToJSONObject(aJSONString);
  try
    Result:=CreateFromObject(aJSONObject);
  finally
    aJSONObject.Free;
  end;
end;

function TReplyMarkup.CreateInlineKeyBoard: TInlineKeyboard;
begin
  Result:=TInlineKeyboard.Create;
  InlineKeyBoard:=Result;
end;

function TReplyMarkup.CreateReplyKeyboard: TKeyboardButtonArray;
begin
  Result:=TKeyboardButtonArray.Create;
  ReplyKeyboardMarkup:=Result;
end;

{ TInlineKeyboardButton }

procedure TInlineKeyboardButton.Settext(AValue: String);
begin
  Strings[s_text]:=AValue;
end;

procedure TInlineKeyboardButton.Setcallback_data(AValue: String);
begin
  CheckOptnlAndSet(s_callbackdata, AValue);
end;

function TInlineKeyboardButton.Geturl: String;
begin
  Result:=Strings[s_url];
end;

function TInlineKeyboardButton.CheckOptnlNull: Boolean;
begin
  Result:=not (Assigned(Find(s_CallbackData)) or Assigned(Find(s_SwitchInlineQuery)) or
    Assigned(Find(s_SwitchInlineQueryCurrentChat)) or Assigned(Find(s_Url)))
end;

procedure TInlineKeyboardButton.CheckOptnlAndSet(const ParamName, ParamValue: String);
var
  Op: Boolean;
begin
  Op:=CheckOptnlNull;
  if op or (not op and Assigned(Find(ParamName))) then // Only one optional parameters must set!
    Strings[ParamName]:=ParamValue
 { else
     DoError('Error')}
end;

function TInlineKeyboardButton.Getcallback_data: String;
begin
  Result:=Strings[s_callbackdata];
end;

function TInlineKeyboardButton.Getswitch_inline_query: String;
begin
  Result:=Strings[s_SwitchInlineQuery];
end;

function TInlineKeyboardButton.Getswitch_inline_query_current_chat: String;
begin
  Result:=Strings[s_SwitchInlineQueryCurrentChat];
end;

function TInlineKeyboardButton.Gettext: String;
begin
  Result:=Strings[s_text];
end;

procedure TInlineKeyboardButton.Setswitch_inline_query(AValue: String);
begin
  CheckOptnlAndSet(s_SwitchInlineQuery, AValue);
end;

procedure TInlineKeyboardButton.Setswitch_inline_query_current_chat(
  AValue: String);
begin
  CheckOptnlAndSet(s_SwitchInlineQueryCurrentChat, AValue);
end;

procedure TInlineKeyboardButton.Seturl(AValue: String);
begin
  CheckOptnlAndSet(s_url, AValue);
end;

constructor TInlineKeyboardButton.Create(const AText: String);
begin
  inherited Create;
  Add(s_text, AText);
end;

{ TTelegramSender }

class function TTelegramSender.StringToJSONObject(const AString: String): TJSONObject;
var
  lParser: TJSONParser;
  aOptions: TJSONOptions;
begin
  Result := nil;
  if AString<>EmptyStr then
  begin
    aOptions:=DefaultOptions;
    { See https://github.com/Al-Muhandis/fp-telegram/issues/4 about this compiler key.
      You can add -dJsonNoUTF8 compiler key to the project for avoiding the problem mentioned in the issue above}
    {$ifdef JsonNoUTF8}Exclude(Options,joUTF8);{$endif}
    lParser := TJSONParser.Create(AString{$IF FPC_FULLVERSION > 30002}, aOptions{$ENDIF});
    try
      try
        Result := lParser.Parse as TJSONObject
      except
        Result:=nil;
      end;
    finally
      lParser.Free;
    end;
  end;
end;

procedure TTelegramSender.DoAfterParseUpdate;
begin
  if Assigned(FOnAfterParseUpdate) then
    FOnAfterParseUpdate(Self);
end;

procedure TTelegramSender.DebugMessage(const Msg: String);
begin
  if FLogDebug then
  begin
    if Assigned(FLogger) then
      FLogger.Debug(Msg);
    if Assigned(FOnLogMessage) then
      FOnLogMessage(Self, etDebug, Msg);
  end;
end;

function TTelegramSender.GetCommandHandlers(const Command: String
  ): TCommandEvent;
begin
  Result:=FCommandHandlers.Items[Command];
end;

function TTelegramSender.GetTimeout: Integer;
begin
  Result:=FTimeout;
end;

procedure TTelegramSender.SetAPIEndPoint(AValue: String);
begin
  if FAPIEndPoint=AValue then Exit;
  FAPIEndPoint:=AValue;
end;

procedure TTelegramSender.SetBotUsername(AValue: String);
begin
  if FBotUsername=AValue then Exit;
  FBotUsername:=AValue;
end;

{$IF FPC_FULLVERSION <= 30004}
function TTelegramSender.AddPair(aStringList: TStrings; const AName,
  AValue: string): TStrings;
begin
  aStringList.AddObject(Concat(AName, aStringList.NameValueSeparator, AValue), nil);
end;{$ENDIF}

procedure TTelegramSender.AssignHTTProxy(aHTTPClient: TBaseHTTPClient; const aHost: String;
  aPort: Word; const aUserName, aPassword: String);
begin
  with aHTTPClient do
  begin
    HTTPProxyHost:=aHost;
    HTTPProxyPort:=aPort;
    HTTPProxyUsername:=aUserName;
    HTTPProxyPassword:=aPassword;
  end;
end;

procedure TTelegramSender.AssignHTTProxy(aHTTPClient: TBaseHTTPClient);
begin
  AssignHTTProxy(aHTTPClient, FHTTPProxyHost, FHTTPProxyPort, FHTTPProxyUser,
    FHTTPProxyPassword);
end;

function TTelegramSender.CurrentLanguage(AUser: TTelegramUserObj): String;
begin
  Result:=AUser.Language_code;
end;

function TTelegramSender.CurrentLanguage(AMessage: TTelegramMessageObj): String;
begin
  Result:=EmptyStr;
  if Assigned(AMessage.From) then
    Result:=AMessage.From.Language_code
  else begin
    if Assigned(AMessage.ReplyToMessage) then
      Result:=CurrentLanguage(AMessage.ReplyToMessage)
  end;
end;

function TTelegramSender.GetAPIEndPoint: String;
begin
  if FAPIEndPoint=EmptyStr then
    Result:=TelegramAPI_URL
  else
    Result:=FAPIEndPoint;
end;

function TTelegramSender.GetChannelCommandHandlers(const Command: String
  ): TCommandEvent;
begin
  Result:=FChannelCommandHandlers.Items[Command];
end;

procedure TTelegramSender.SetChannelCommandHandlers(const Command: String;
  AValue: TCommandEvent);
begin
  FChannelCommandHandlers.Items[Command]:=AValue;
end;

procedure TTelegramSender.SetCommandHandlers(const Command: String;
  AValue: TCommandEvent);
begin
  FCommandHandlers.Items[Command]:=AValue;
end;

procedure TTelegramSender.DoReceiveMessageUpdate(AMessage: TTelegramMessageObj);
begin
  FCurrentMessage:=AMessage;
  FCurrentChatID:=AMessage.ChatId;
  FCurrentThreadId:=AMessage.MessageThreadID;
  FCurrentIsTopicMessage:=AMessage.IsTopicMessage;
  FCurrentChat:=AMessage.Chat;
  FCurrentUser:=AMessage.From;
  if CurrentIsBanned then
    Exit;
  DoAfterParseUpdate;
  if FLanguage=EmptyStr then
    SetLanguage(CurrentLanguage(AMessage));
  ProcessCommands(AMessage, FCommandHandlers);
  if Assigned(AMessage.SuccessfulPayment) and not FUpdateProcessed then
    DoReceiveSuccessfulPayment(AMessage);
  if Assigned(FOnReceiveMessage) and not FUpdateProcessed then
    FOnReceiveMessage(Self, AMessage);
end;

procedure TTelegramSender.DoReceiveEditedMessage(AMessage: TTelegramMessageObj);
begin
  FCurrentMessage:=AMessage;
  FCurrentChatID:=AMessage.ChatId;
  FCurrentThreadId:=AMessage.MessageThreadID;
  FCurrentIsTopicMessage:=AMessage.IsTopicMessage;
  FCurrentChat:=AMessage.Chat;
  FCurrentUser:=AMessage.From;
  if CurrentIsBanned then
    Exit;
  DoAfterParseUpdate;
  if FLanguage=EmptyStr then
    SetLanguage(CurrentLanguage(AMessage));
  ProcessCommands(AMessage, FCommandHandlers);
  if Assigned(FOnReceiveEditedMessage) then
    FOnReceiveEditedMessage(Self, AMessage);
end;

procedure TTelegramSender.DoReceiveCallbackQuery(ACallback: TCallbackQueryObj);
begin
  FCurrentMessage:=ACallback.Message;
  if Assigned(FCurrentMessage) then
    FCurrentChat:=FCurrentMessage.Chat;
  FCurrentUser:=ACallback.From;
  FCurrentChatID:=FCurrentUser.ID; { Bot will send to private chat if in channel is called } {ACallback.Message.ChatId;}
  FCurrentThreadId:=_nullThrd;
  FCurrentIsTopicMessage:=False;
  if CurrentIsBanned then
    Exit;
  if Assigned(FCurrentMessage) then
    if Assigned(FCurrentMessage.From) then
      FBotUsername:=FCurrentMessage.From.Username;
  DoAfterParseUpdate;
  if FLanguage=EmptyStr then
    SetLanguage(CurrentLanguage(ACallback.From));
  if Assigned(FOnReceiveCallbackQuery) then
    FOnReceiveCallbackQuery(Self, ACallback);
end;

procedure TTelegramSender.DoReceiveChannelPost(AChannelPost: TTelegramMessageObj);
begin
  FCurrentMessage:=AChannelPost;
  FCurrentChat:=AChannelPost.Chat;
  FCurrentChatID:=AChannelPost.ChatId;  
  FCurrentThreadId:=AChannelPost.MessageThreadID;
  FCurrentIsTopicMessage:=AChannelPost.IsTopicMessage;
  FCurrentUser:=AChannelPost.From;
  if CurrentIsBanned then
    Exit;
  DoAfterParseUpdate;
  if FLanguage=EmptyStr then
    SetLanguage(CurrentLanguage(AChannelPost));
  ProcessCommands(AChannelPost, FChannelCommandHandlers);
  if Assigned(FOnReceiveChannelPost) then
    FOnReceiveChannelPost(Self, AChannelPost);
end;

procedure TTelegramSender.DoReceiveEditedChannelPost(AChannelPost: TTelegramMessageObj);
begin
  FCurrentMessage:=AChannelPost;
  FCurrentChat:=AChannelPost.Chat;
  FCurrentChatID:=AChannelPost.ChatId;  
  FCurrentThreadId:=AChannelPost.MessageThreadID;
  FCurrentIsTopicMessage:=AChannelPost.IsTopicMessage;
  FCurrentUser:=AChannelPost.From;
  if CurrentIsBanned then
    Exit;
  DoAfterParseUpdate;
  if FLanguage=EmptyStr then
    SetLanguage(CurrentLanguage(AChannelPost));
  ProcessCommands(AChannelPost, FChannelCommandHandlers);
  if Assigned(FOnReceiveEditedChannelPost) then
    FOnReceiveChannelPost(Self, AChannelPost);
end;

procedure TTelegramSender.DoReceiveInlineQuery(
  AnInlineQuery: TTelegramInlineQueryObj);
begin
  FCurrentMessage:=nil;
  FCurrentChat:=nil;
  FCurrentChatID:=AnInlineQuery.From.ID;
  FCurrentThreadId:=_nullThrd;
  FCurrentIsTopicMessage:=False;
  FCurrentUser:=AnInlineQuery.From;
  if CurrentIsBanned then
    Exit;
  DoAfterParseUpdate;
  if FLanguage=EmptyStr then
    SetLanguage(CurrentLanguage(AnInlineQuery.From));
  if Assigned(FOnReceiveInlineQuery) then
    FOnReceiveInlineQuery(Self, AnInlineQuery);
end;

procedure TTelegramSender.DoReceiveChosenInlineResult(
  AChosenInlineResult: TTelegramChosenInlineResultObj);
begin
  FCurrentMessage:=nil;
  FCurrentChat:=nil;
  FCurrentChatID:=AChosenInlineResult.From.ID; 
  FCurrentThreadId:=_nullThrd;
  FCurrentIsTopicMessage:=False;
  FCurrentUser:=AChosenInlineResult.From;
  if CurrentIsBanned then
    Exit;
  DoAfterParseUpdate;
  if FLanguage=EmptyStr then
    SetLanguage(CurrentLanguage(AChosenInlineResult.From));
  if Assigned(FOnReceiveChosenInlineResult) then
    FOnReceiveChosenInlineResult(Self, AChosenInlineResult);
end;

procedure TTelegramSender.DoReceivePreCheckoutQuery(
  APreCheckoutQuery: TTelegramPreCheckOutQuery);
begin
  FCurrentUser:=APreCheckoutQuery.From;
  FCurrentChatID:=FCurrentUser.ID; 
  FCurrentThreadId:=_nullThrd;
  FCurrentIsTopicMessage:=False;
  if CurrentIsBanned then
    Exit;
  DoAfterParseUpdate;
  if FLanguage=EmptyStr then
    SetLanguage(CurrentLanguage(APreCheckoutQuery.From));
  if Assigned(FOnReceivePreCheckoutQuery) then
    FOnReceivePreCheckoutQuery(Self, APreCheckoutQuery);
end;

procedure TTelegramSender.DoReceiveMyChatMemberQuery(AMyChatMember: TTelegramChatMemberUpdated);
begin
  FCurrentMessage:=nil;
  FCurrentChat:=AMyChatMember.Chat;
  FCurrentUser:=AMyChatMember.From;
  FCurrentThreadId:=_nullThrd;
  FCurrentIsTopicMessage:=False;
  FCurrentChatId:=FCurrentUser.ID;
  if CurrentIsBanned then
    Exit;                          
  DoAfterParseUpdate;
  if FLanguage=EmptyStr then
    SetLanguage(CurrentLanguage(FCurrentUser));
  if Assigned(FOnReceiveMyChatMemberUpdated) then
    FOnReceiveMyChatMemberUpdated(Self, AMyChatMember);
end;

procedure TTelegramSender.DoReceiveChatMemberQuery(AChatMember: TTelegramChatMemberUpdated);
begin
  FCurrentMessage:=nil;
  FCurrentChat:=AChatMember.Chat;
  FCurrentUser:=AChatMember.From;
  FCurrentThreadId:=_nullThrd;
  FCurrentIsTopicMessage:=False;
  FCurrentChatId:=FCurrentUser.ID;
  if CurrentIsBanned then
    Exit;
  DoAfterParseUpdate;
  if FLanguage=EmptyStr then
    SetLanguage(CurrentLanguage(FCurrentUser));
  if Assigned(FOnReceiveChatMemberUpdated) then
    FOnReceiveChatMemberUpdated(Self, AChatMember);
end;

procedure TTelegramSender.DoReceiveSuccessfulPayment(
  AMessage: TTelegramMessageObj);
begin
  if CurrentIsBanned then
    Exit;
  DoAfterParseUpdate;
  if Assigned(FOnReceiveSuccessfulPayment) then
    FOnReceiveSuccessfulPayment(Self, AMessage);
end;

procedure TTelegramSender.DoReceiveBusinessConnection(ABusinessConnection: TTelegramBusinessConnectionObj);
begin
  FCurrentChatID:=ABusinessConnection.UserChatID;
  FCurrentUser:=ABusinessConnection.User;
  if CurrentIsBanned then
    Exit;
  DoAfterParseUpdate;
  if Assigned(FOnReceiveBusinessConnection) then
    FOnReceiveBusinessConnection(Self, ABusinessConnection);
end;

procedure TTelegramSender.DoReceiveBusinessMessage(ABusinessMessage: TTelegramMessageObj);
begin
  FCurrentMessage:=ABusinessMessage;
  FCurrentChatID:=ABusinessMessage.ChatId;
  FCurrentThreadId:=ABusinessMessage.MessageThreadID;   // ? I think no need but...
  FCurrentIsTopicMessage:=ABusinessMessage.IsTopicMessage;
  FCurrentChat:=ABusinessMessage.Chat;
  FCurrentUser:=ABusinessMessage.From;
  if CurrentIsBanned then
    Exit;
  DoAfterParseUpdate;
  if FLanguage=EmptyStr then
    SetLanguage(CurrentLanguage(ABusinessMessage));
  ProcessCommands(ABusinessMessage, FCommandHandlers);
  if Assigned(ABusinessMessage.SuccessfulPayment) and not FUpdateProcessed then
    DoReceiveSuccessfulPayment(ABusinessMessage);
  if Assigned(FOnReceiveBusinessMessage) and not FUpdateProcessed then
    FOnReceiveBusinessMessage(Self, ABusinessMessage);
end;

procedure TTelegramSender.DoReceiveUpdate(AnUpdate: TTelegramUpdateObj);
begin
  FreeAndNil(FUpdate);
  FUpdate:=AnUpdate;
  FCurrentMessage:=nil;
  FCurrentChatId:=0;
  FCurrentThreadId:=_nullThrd;
  FCurrentIsTopicMessage:=False;
  FCurrentUser:=nil;
  FCurrentChat:=nil;
  FLanguage:='';
  FUpdateProcessed:=False;
  if Assigned(AnUpdate) then
  begin
    FUpdateID:=AnUpdate.UpdateId;
    DebugMessage('Receive the update: '+FUpdate.AsString);
    if FProcessUpdate then
    begin
      case AnUpdate.UpdateType of
        utMessage:            DoReceiveMessageUpdate(AnUpdate.Message);
        utEditedMessage:      DoReceiveEditedMessage(AnUpdate.EditedMessage);
        utChannelPost:        DoReceiveChannelPost(AnUpdate.ChannelPost);
        utEditedChannelPost:  DoReceiveEditedChannelPost(AnUpdate.EditedChannelPost);
        utInlineQuery:        DoReceiveInlineQuery(AnUpdate.InlineQuery);
        utChosenInlineResult: DoReceiveChosenInlineResult(AnUpdate.ChosenInlineResult);
        utCallbackQuery:      DoReceiveCallbackQuery(AnUpdate.CallbackQuery);
        utPreCheckoutQuery:   DoReceivePreCheckoutQuery(AnUpdate.PreCheckoutQuery);
        utMyChatMember:       DoReceiveMyChatMemberQuery(AnUpdate.MyChatMember);
        utChatMember:         DoReceiveChatMemberQuery(AnUpdate.ChatMember);
        utBusinessConnection: DoReceiveBusinessConnection(AnUpdate.BusinessConnection);
        utBusinessMessage:    DoReceiveBusinessMessage(AnUpdate.BusinessMessage);
      end;
      if Assigned(FUpdateLogger) then
        if CurrentIsSimpleUser then  // This is to ensure that admins and moderators do not affect the statistics
          FUpdateLogger.Log(AnUpdate.AsString);
    end;
    if Assigned(FOnReceiveUpdate) and not FUpdateProcessed then
      FOnReceiveUpdate(Self, AnUpdate);
  end;
end;

function TTelegramSender.CurrentIsAdminUser: Boolean;
begin
{ for example, for business message security admin is only business message sender ("from" field)
  but is not current chat id }
  if Assigned(FCurrentUser) then
    Result:=IsAdminUser(FCurrentUser.ID)
  else
    Result:=IsAdminUser(FCurrentChatId);
end;

function TTelegramSender.answerCallbackQuery(const CallbackQueryId: String;
  const Text: String; ShowAlert: Boolean; const Url: String; CacheTime: Integer
  ): Boolean;
var
  sendObj: TJSONObject;
begin
  Result:=False;
  sendObj:=TJSONObject.Create;
  with sendObj do
    try
      Add(s_CallbackQueryID, CallbackQueryId);
      if Text<>EmptyStr then
        Add(s_Text, Text);
      if ShowAlert then
        Add(s_ShowAlert, ShowAlert);
      if Url<>EmptyStr then
        Add(s_Url, Url);
      if CacheTime<>0 then
        Add(s_CacheTime, CacheTime);
      Result:=SendMethod(s_answerCallbackQuery, sendObj);
    finally
      Free;
    end;
end;

function TTelegramSender.answerPreCheckoutQuery(
  const PreCheckoutQueryID: String; Ok: Boolean; AnErrorMessage: String
  ): Boolean;
var
  sendObj: TJSONObject;
begin
  Result:=False;
  sendObj:=TJSONObject.Create;
  with sendObj do
    try
      Add(s_PreCheckoutQueryID, PreCheckoutQueryID);
      Add(s_Ok, Ok);
      if AnErrorMessage<>EmptyStr then
        Add(s_ErrorMessage, AnErrorMessage);
      Result:=SendMethod(s_answerPreCheckoutQuery, sendObj);
    finally
      Free;
    end;
end;

function TTelegramSender.deleteMessage(chat_id: Int64; message_id: Int64
  ): Boolean;
var
  sendObj: TJSONObject;
begin
  Result:=False;
  sendObj:=TJSONObject.Create;
  with sendObj do
  try
    Add(s_ChatId, chat_id);
    Add(s_MessageId, message_id);
    Result:=SendMethod(s_deleteMessage, sendObj);
  finally
    Free;
  end;
end;

function TTelegramSender.deleteMessage(message_id: Int64): Boolean;
begin
  Result:=deleteMessage(CurrentChatId, message_id);
end;

function TTelegramSender.editMessageReplyMarkup(chat_id: Int64; message_id: Int64;
  const inline_message_id: String; ReplyMarkup: TReplyMarkup): Boolean;
var
  sendObj: TJSONObject;
begin
  Result:=False;
  sendObj:=TJSONObject.Create;
  with sendObj do
  try
    if chat_id<>0 then
      Add(s_ChatId, chat_id);
    if message_id<>0 then
      Add(s_MessageId, message_id);
    if inline_message_id<>EmptyStr then
      Add(s_InlineMessageId, inline_message_id);
    if Assigned(ReplyMarkup) then
      Add(s_ReplyMarkup, ReplyMarkup.Clone);
    Result:=SendMethod(s_editMessageReplyMarkup, sendObj);
  finally
    Free;
  end;
end;

procedure TTelegramSender.ErrorMessage(const Msg: String);
begin
  if Assigned(FLogger) then
    FLogger.Error(Msg);
  if Assigned(FOnLogMessage) then
    FOnLogMessage(Self, etError, Msg);
end;

procedure TTelegramSender.InfoMessage(const Msg: String);
begin
  if Assigned(FLogger) then
    FLogger.Info(Msg);
  if Assigned(FOnLogMessage) then
    FOnLogMessage(Self, etInfo, Msg);
end;

function TTelegramSender.IsBanned(ChatID: Int64): Boolean;
begin
  Result:=False;
end;

function TTelegramSender.IsSimpleUser(ChatID: Int64): Boolean;
begin
  Result:=True;
end;

function TTelegramSender.IsAdminUser(ChatID: Int64): Boolean;
begin
  Result:=False;
end;

function TTelegramSender.IsBotUser(ChatID: Int64): Boolean;
begin
  Result:=False;
end;

function TTelegramSender.CurrentIsSimpleUser: Boolean;
begin
  Result:=IsSimpleUser(FCurrentChatId);
end;

function TTelegramSender.CurrentIsBanned: Boolean;
begin
  Result:=IsBanned(FCurrentChatId);
end;

function TTelegramSender.CurrentIsBotUser: Boolean;
begin
  Result:=IsBotUser(FCurrentChatId);
end;

function TTelegramSender.HTTPPostFile(const Method, FileField, FileName: String;
  AFormData: TStrings): Boolean;
var
  HTTP: TBaseHTTPClient;
  AStream: TStringStream;
begin
  Result:=False;
  JSONResponse:=nil;
  FResponse:=EmptyStr;
  HTTP:=TBaseHTTPClient.GetClientClass.Create(nil);
  AssignHTTProxy(HTTP);
  AStream:=TStringStream.Create(EmptyStr);
  try
    try
      HTTP.AddHeader('Content-Type','multipart/form-data');
      HTTP.FileFormPost(APIEndPoint+FToken+'/'+Method, AFormData, FileField, FileName, AStream);
      FResponse:=AStream.DataString;
      Result:=True;
    except
      Result:=False;
    end;
  finally
    AStream.Free;
    HTTP.Free;
  end;
end;

function TTelegramSender.HTTPPostFiles(const Method: String; aFormData, aFiles: TStrings): Boolean;
var
  HTTP: TBaseHTTPClient;
begin
  Result:=False;
  JSONResponse:=nil;
  FResponse:=EmptyStr;
  HTTP:=TBaseHTTPClient.GetClientClass.Create(nil);
  AssignHTTProxy(HTTP);
  try
    try
      FResponse:=HTTP.FilesFormPost(APIEndPoint+FToken+'/'+Method, aFormData, aFiles);
      Result:=True;
    except
      Result:=False;
    end;
  finally
    HTTP.Free;
  end;
end;

function TTelegramSender.HTTPPostJSON(const Method: String): Boolean;
var
  HTTP: TBaseHTTPClient;
begin
  Result:=False;
  HTTP:=TBaseHTTPClient.GetClientClass.Create(nil);
  AssignHTTProxy(HTTP);
  try
    HTTP.IOTimeout:=FTimeout;
    HTTP.RequestBody:=TStringStream.Create(FRequestBody);
    try
      HTTP.AddHeader('Content-Type','application/json');
      FResponse:=HTTP.Post(FAPIEndPoint+FToken+'/'+Method);
    finally
      HTTP.RequestBody.Free;
      HTTP.RequestBody:=nil;
    end;
    Result:=True;
    DebugMessage('Response: '+FResponse);
  except
    on E: Exception do
      ErrorMessage('[HTTPPostJSON] '+e.ClassName+': '+e.Message);
  end;
  HTTP.Free;
end;

function TTelegramSender.HTTPPostStream(const Method, FileField, FileName: String;
  AStream: TStream; AFormData: TStrings): Boolean;
var
  HTTP: TBaseHTTPClient;
  AStringStream: TStringStream;
begin
  HTTP:=TBaseHTTPClient.GetClientClass.Create(nil);
  AssignHTTProxy(HTTP);
  AStringStream:=TStringStream.Create(EmptyStr);
  try
    HTTP.IOTimeout:=FTimeout;
    HTTP.AddHeader('Content-Type','multipart/form-data');
    HTTP.StreamFormPost(FAPIEndPoint+FToken+'/'+Method, AFormData, FileField, FileName, AStream, AStringStream);
    FResponse:=AStringStream.DataString;
    Result:=True;
  except
    Result:=False;
  end;
  AStringStream.Free;
  HTTP.Free;
end;

function TTelegramSender.HTTPPostStreams(const Method: String; aFormData,
  aStreams: TStrings): Boolean;
var
  HTTP: TBaseHTTPClient;
begin
  Result:=False;
  JSONResponse:=nil;
  FResponse:=EmptyStr;
  HTTP:=TBaseHTTPClient.GetClientClass.Create(nil);
  AssignHTTProxy(HTTP);
  try
    try
      FResponse:=HTTP.StreamsFormPost(APIEndPoint+FToken+'/'+Method, aFormData, aStreams);
      Result:=True;
    except
      Result:=False;
    end;
  finally
    HTTP.Free;
  end;
end;

procedure TTelegramSender.ProcessCommands(AMessage: TTelegramMessageObj;
  AHandlers: TCommandHandlersMap);
var
  lCommand, Txt: String;
  lMessageEntityObj: TTelegramMessageEntityObj;
  H: TCommandEvent;
  AtPos: Integer;
begin
  Txt:=AMessage.Text;
  for lMessageEntityObj in AMessage.Entities do
  begin
    if (lMessageEntityObj.TypeEntity = s_BotCommand) and (lMessageEntityObj.Offset = 0) then
    begin
      lCommand := Copy(Txt, lMessageEntityObj.Offset, lMessageEntityObj.Length);
      AtPos:=Pos('@', lCommand);
      if AtPos>0 then
        lCommand:=LeftStr(lCommand, AtPos-1);
      if AHandlers.contains(lCommand) then
      begin
        H:=AHandlers.Items[lCommand];
        H(Self, lCommand, AMessage);
      end;
    end;
  end;
end;

function TTelegramSender.ResponseToJSONObject: TJSONObject;
begin
  Result:=StringToJSONObject(FResponse);
end;

function TTelegramSender.ResponseHandle: Boolean;
var
  lJSON: TJSONObject;
begin
  Result:=False;
  lJSON:=ResponseToJSONObject;
  if Assigned(lJSON) then
  begin
    if lJSON.Booleans[s_Ok] then
    begin
      JSONResponse := lJSON.Find(s_Result);
      FLastErrorCode:=0;
      FLastErrorDescription:='';
      Result:=True;
    end
    else begin
      JSONResponse:=lJSON;
      FLastErrorCode:=lJSON.Integers[s_ErrorCode];
      FLastErrorDescription:=lJSON.Get(s_Description, EmptyStr);
    end;
    lJSON.Free;
  end;
end;

function TTelegramSender.SendFile(const AMethod, AFileField, AFileName: String;
  MethodParameters: TStrings): Boolean;
begin
  Result:=False;
  RequestBody:=MethodParameters.CommaText;
  DebugMessage('Request for method "'+AMethod+'": '+FRequestBody);
  DebugMessage('Sending file '+AFileName);
  try
    Result:=HTTPPostFile(AMethod, AFileField, AFileName, MethodParameters);
    if Result then
      if FResponse<>EmptyStr then     // longpolling
        if not ResponseHandle then
        begin
          Result:=False;
          ErrorMessage('Error request: '+FResponse);
        end;
    DebugMessage('Response: '+FResponse);
  except
    ErrorMessage('It is not succesful request to API! Request body: '+FRequestBody);
  end;
end;

function TTelegramSender.SendFiles(const AMethod: String; AFiles, MethodParameters: TStrings): Boolean;
begin
  Result:=False;
  RequestBody:=MethodParameters.CommaText;
  DebugMessage('Request for method "'+AMethod+'": '+FRequestBody);
  try
    Result:=HTTPPostFiles(AMethod, MethodParameters, AFiles);
    if Result then
      if FResponse<>EmptyStr then     // longpolling
        if not ResponseHandle then
        begin
          Result:=False;
          ErrorMessage('Error request: '+FResponse);
        end;
    DebugMessage('Response: '+FResponse);
  except
    ErrorMessage('It is not succesful request to API! Request body: '+FRequestBody);
  end;
end;

procedure TTelegramSender.SetRequestBody(AValue: String);
begin
  if FRequestBody=AValue then Exit;
  FRequestBody:=AValue;
end;

procedure TTelegramSender.SetRequestWhenAnswer(AValue: Boolean);
begin
  if FRequestWhenAnswer=AValue then Exit;
  FRequestWhenAnswer:=AValue;
end;

procedure TTelegramSender.SetTimeout(AValue: Integer);
begin
  FTimeout:=AValue;
end;

procedure TTelegramSender.SetUpdateID(AValue: Integer);
begin
  if FUpdateID=AValue then Exit;
  FUpdateID:=AValue;
end;

procedure TTelegramSender.SetUpdateLogger(AValue: TtgStatLog);
begin
  if FUpdateLogger=AValue then Exit;
  FUpdateLogger:=AValue;
end;

procedure TTelegramSender.SetUpdateProcessed(AValue: Boolean);
begin
  if FUpdateProcessed=AValue then Exit;
  FUpdateProcessed:=AValue;
end;

function TTelegramSender.SendMethod(const Method: String;
  MethodParameters: array of const): Boolean;
var
  sendObj: TJSONObject;
begin
  sendObj:=TJSONObject.Create(MethodParameters);
  Result:=SendMethod(Method, sendObj);
  sendObj.Free;
end;

function TTelegramSender.SendMethod(const Method: String; MethodParameters: TJSONObject): Boolean;
begin
  Result:=False;
  JSONResponse:=nil;
  FResponse:=EmptyStr;
  if not FRequestWhenAnswer then
  begin
    RequestBody:=MethodParameters.AsJSON;
    DebugMessage('Request for method "'+Method+'": '+FRequestBody);
    Result:=HTTPPostJson(Method);

    if Result then
      if FResponse<>EmptyStr then     // longpolling
        if not ResponseHandle then
        begin
          Result:=False;
          ErrorMessage('Error request: '+FResponse);
        end;
  end
  else
  begin
    MethodParameters.Strings[s_Method]:=Method;
    RequestBody:=MethodParameters.AsJSON;
    DebugMessage('Request in HTTP reply: '+FRequestBody);
    Result:=True;
  end;
end;

function TTelegramSender.SendStream(const AMethod, AFileField, AFileName: String;
  AStream: TStream; MethodParameters: TStrings): Boolean;
begin
  Result:=False;
  JSONResponse:=nil;
  FResponse:=EmptyStr;
  DebugMessage('Request for method "'+AMethod+'": '+FRequestBody);
  DebugMessage('Sending file '+AFileName);
  try
    Result:=HTTPPostStream(AMethod, AFileField, AFileName, AStream, MethodParameters);
    DebugMessage('Response: '+FResponse);
    if Result then
      if FResponse<>EmptyStr then     // longpolling
        if not ResponseHandle then
        begin
          Result:=False;
          ErrorMessage('Error request: '+FResponse);
        end;
  except
    ErrorMessage('It is not succesful request to API! Request body: '+FRequestBody);
  end;
end;

function TTelegramSender.SendStreams(const AMethod: String; AStreams,
  MethodParameters: TStrings): Boolean;
begin
  Result:=False;
  RequestBody:=MethodParameters.CommaText;
  DebugMessage('Request for method "'+AMethod+'": '+FRequestBody);
  try
    Result:=HTTPPostStreams(AMethod, MethodParameters, AStreams);
    if Result then
      if FResponse<>EmptyStr then     // longpolling
        if not ResponseHandle then
        begin
          Result:=False;
          ErrorMessage('Error request: '+FResponse);
        end;
    DebugMessage('Response: '+FResponse);
  except
    ErrorMessage('It is not succesful request to API! Request body: '+FRequestBody);
  end;
end;

procedure TTelegramSender.SetFileObj(AValue: TTelegramFile);
begin
  if FFileObj=AValue then Exit;
  FreeAndNil(FFileObj);
  FFileObj:=AValue;
end;

procedure TTelegramSender.SetJSONResponse(AValue: TJSONData);
begin
  if FJSONResponse=AValue then Exit;
  FreeAndNil(FJSONResponse);
  if Assigned(AValue) then
    FJSONResponse:=AValue.Clone;
end;

procedure TTelegramSender.SetLastErrorCode(AValue: Integer);
begin
  if FLastErrorCode=AValue then Exit;
  FLastErrorCode:=AValue;
end;

procedure TTelegramSender.SetLastErrorDescription(AValue: String);
begin
  if FLastErrorDescription=AValue then Exit;
  FLastErrorDescription:=AValue;
end;

procedure TTelegramSender.SetLogDebug(AValue: Boolean);
begin
  if FLogDebug=AValue then Exit;
  FLogDebug:=AValue;
end;

procedure TTelegramSender.SetLogger(AValue: TEventLog);
begin
  if FLogger=AValue then Exit;
  FLogger:=AValue;
end;

procedure TTelegramSender.SetOnAfterParseUpdate(AValue: TNotifyEvent);
begin
  if FOnAfterParseUpdate=AValue then Exit;
  FOnAfterParseUpdate:=AValue;
end;

procedure TTelegramSender.SetLanguage(const AValue: String);
begin
  if FLanguage=AValue then Exit;
  FLanguage:=AValue;
end;

procedure TTelegramSender.SetProcessUpdate(AValue: Boolean);
begin
  if FProcessUpdate=AValue then Exit;
  FProcessUpdate:=AValue;
end;

constructor TTelegramSender.Create(const AToken: String);
begin
  inherited Create;
  FAPIEndPoint:=TelegramAPI_URL;
  FToken:=AToken;
  FRequestWhenAnswer:=False;
  FProcessUpdate:=True;
  FCommandHandlers:=TCommandHandlersMap.create;
  FChannelCommandHandlers:=TCommandHandlersMap.create;
  FLogDebug:=False;
  FTimeout:=12000;
end;

function TTelegramSender.DeepLinkingUrl(const AParameter: String): String;
begin
  Result:=TgBotUrlStart+FBotUsername+'?start='+AParameter;
end;

destructor TTelegramSender.Destroy;
begin
  JSONResponse:=nil;
  FreeAndNil(FUpdateLogger);
  FreeAndNil(FChannelCommandHandlers);
  FreeAndNil(FCommandHandlers);
  FreeAndNil(FBotUser);
  FileObj:=nil;
  FreeAndNil(FUpdate);
  inherited Destroy;
end;

function TTelegramSender.editMessageText(const AMessage: String;
  chat_id: Int64; message_id: Int64; ParseMode: TParseMode;
  DisableWebPagePreview: Boolean; inline_message_id: String;
  ReplyMarkup: TReplyMarkup): Boolean;
var
  sendObj: TJSONObject;
begin
  Result:=False;
  sendObj:=TJSONObject.Create;
  with sendObj do
  try
    if chat_id<>0 then
      Add(s_ChatId, chat_id);
    if message_id<>0 then
      Add(s_MessageId, message_id);
    if inline_message_id<>EmptyStr then
      Add(s_InlineMessageId, inline_message_id);
    Add(s_Text, AMessage);
    if ParseMode<>pmDefault then
      Add(s_ParseMode, ParseModes[ParseMode]);
    Add(s_DsblWbpgPrvw, DisableWebPagePreview);
    if Assigned(ReplyMarkup) then
      Add(s_ReplyMarkup, ReplyMarkup.Clone); // Clone of ReplyMarkup object will have released with sendObject
    Result:=SendMethod(s_editMessageText, sendObj);
  finally
    Free;
  end;
end;

function TTelegramSender.editMessageText(const AMessage: String;
  ParseMode: TParseMode; DisableWebPagePreview: Boolean;
  ReplyMarkup: TReplyMarkup): Boolean;
begin  { try to edit message if the message is present and chat is private with sender user }
  if Assigned(FCurrentMessage) and (FCurrentChatId = FCurrentMessage.ChatId) and (FUpdate.UpdateType=utCallbackQuery) then
    Result:=editMessageText(AMessage, FCurrentChatId, FCurrentMessage.MessageId,
      ParseMode, DisableWebPagePreview, EmptyStr, ReplyMarkup)
  else
    Result:=sendMessage(AMessage, ParseMode, DisableWebPagePreview, ReplyMarkup);
end;

function TTelegramSender.editMessageMediaStream(aStream: TStream; media: TInputMedia; chat_id: Int64;
  message_id: Int64; inline_message_id: String; ReplyMarkup: TReplyMarkup): Boolean;
var
  sendObj: TStringList;
  aFileField, aFileName: String;
const
  _field='media';
begin
  Result:=False;
  sendObj:=TStringList.Create;
  with sendObj do
  try
    if chat_id<>0 then
      Add(s_ChatId+'='+IntToStr(chat_id));
    media.Media:='attach://'+_field;
    {$IF FPC_FULLVERSION <= 30004}
    Self.AddPair(sendObj,s_Media, media.AsJSON);
    {$ELSE}
    AddPair(s_Media, media.AsJSON);
    {$ENDIF}
    if message_id<>0 then
      Add(s_MessageId+'='+message_id.ToString);
    if inline_message_id<>EmptyStr then
      Add(s_InlineMessageId+'='+inline_message_id);
    if Assigned(ReplyMarkup) then
      Add(s_ReplyMarkup+'='+ReplyMarkup.AsJSON);
    aFileField:=_field;
    aFileName:=_field;
    Result:=SendStream(s_editMessageMedia, aFileField, aFileName, aStream, sendObj);
  finally
    Free;
  end;
end;

function TTelegramSender.copyMessage(chat_id, from_chat_id, message_id: Int64; DisableNotification: Boolean;
  ReplyMarkup: TReplyMarkup): Boolean;
var
  sendObj: TJSONObject;
begin
  Result:=False;
  sendObj:=TJSONObject.Create;
  with sendObj do
  try
    Add(s_ChatId, chat_id);
    Add(s_FromChatID, from_chat_id);
    Add(s_MessageId, message_id);     
    if DisableNotification then
      Add(s_DsblNtfctn, DisableNotification);
    if Assigned(ReplyMarkup) then
      Add(s_ReplyMarkup, ReplyMarkup.Clone); // Clone of ReplyMarkup object will have released with sendObject
    Result:=SendMethod(s_copyMessage, sendObj);
  finally
    Free;
  end;
end;

function TTelegramSender.forwardMessage(chat_id: Int64; from_chat_id: Int64;
  DisableNotification: Boolean; message_id: Int64): Boolean;
begin
  Result:=forwardMessage(IntToStr(chat_id), from_chat_id, DisableNotification, message_id);
end;

function TTelegramSender.forwardMessage(chat_id: String; from_chat_id: Int64;
  DisableNotification: Boolean; message_id: Int64): Boolean;
var
  sendObj: TJSONObject;
begin
  Result:=False;
  sendObj:=TJSONObject.Create;
  with sendObj do
  try
    Add(s_ChatId, chat_id);
    Add(s_FromChatID, from_chat_id);
    if DisableNotification then
      Add(s_DsblNtfctn, DisableNotification);
    Add(s_MessageId, message_id);
    Result:=SendMethod(s_forwardMessage, sendObj);
  finally
    Free;
  end;
end;

function TTelegramSender.getChat(chat_id: Int64; out aChat: TTelegramChatObj
  ): Boolean;
var
  sendObj: TJSONObject;
begin
  Result:=False;
  sendObj:=TJSONObject.Create;
  with sendObj do
  try
    Add(s_ChatId, chat_id);
    Result:=SendMethod(s_getChat, sendObj);
    if Result and Assigned(JSONResponse) then
      aChat:=TTelegramChatObj.CreateFromJSONObject(JSONResponse as TJSONObject) as TTelegramChatObj
    else
      aChat:=nil;
  finally
    Free;
  end;
end;

function TTelegramSender.getChat(chat_id: String; out aChat: TTelegramChatObj
  ): Boolean;
var
  sendObj: TJSONObject;
begin
  Result:=False;
  sendObj:=TJSONObject.Create;
  with sendObj do
  try
    Add(s_ChatId, chat_id);
    Result:=SendMethod(s_getChat, sendObj);
    if Result and Assigned(JSONResponse) then
      aChat:=TTelegramChatObj.CreateFromJSONObject(JSONResponse as TJSONObject) as TTelegramChatObj;;
  finally
    Free;
  end;
end;

function TTelegramSender.getChatMember(chat_id: Int64; user_id: Int64): Boolean;
var
  sendObj: TJSONObject;
begin
  Result:=False;
  sendObj:=TJSONObject.Create;
  with sendObj do
  try
    Add(s_ChatId, chat_id);
    Add(s_UserID, user_id);
    Result:=SendMethod(s_getChatMember, sendObj);
  finally
    Free;
  end;
end;

function TTelegramSender.getChatMember(chat_id: Int64; user_id: Int64; out
  aChatMember: TTelegramChatMember): Boolean;
begin
  Result:=getChatMember(chat_id, user_id);
  if Result then
    if Assigned(JSONResponse) then
      aChatMember:=TTelegramChatMember.CreateFromJSONObject(JSONResponse as TJSONObject) as TTelegramChatMember;
end;

function TTelegramSender.getMe: Boolean;
var
  sendObj: TJSONObject;
begin
  Result:=False;
  sendObj:=TJSONObject.Create;
  with sendObj do
  try
    Result:=SendMethod(s_getMe, sendObj);
    if Result then
      if Assigned(JSONResponse) then
      begin
        FBotUser := TTelegramUserObj.CreateFromJSONObject(JSONResponse as TJSONObject) as TTelegramUserObj;
        if Assigned(FBotUser) then
          FBotUsername:=FBotUser.Username;
      end;
  finally
    Free;
  end;
end;

function TTelegramSender.getMyCommands(aScope: TBotCommandScope; const aLanguage: String): Boolean;
var
  sendObj: TJSONObject;
begin
  Result:=False;
  sendObj:=TJSONObject.Create;
  try
    if Assigned(aScope) then
      sendObj.Add(s_scope, aScope.Clone);
    if not aLanguage.IsEmpty then
      sendObj.Add(s_LanguageCode, aLanguage);
    Result:=SendMethod(s_getMyCommands, sendObj);
  finally
    sendObj.Free;
  end;
end;

function TTelegramSender.getWebhookInfo(out aWebhookInfo: TTelegramWebhookInfo): Boolean;
var
  sendObj: TJSONObject;
begin
  Result:=False;
  aWebhookInfo:=nil;
  sendObj:=TJSONObject.Create;
  with sendObj do
  try
    Result:=SendMethod(s_getWebhookInfo, sendObj);
    if Result then
      if Assigned(JSONResponse) then
        aWebhookInfo:=TTelegramWebhookInfo.CreateFromJSONObject(JSONResponse as TJSONObject) as TTelegramWebhookInfo;
  finally
    Free;
  end;
end;

function TTelegramSender.setMyCommands(aBotCommands: TBotCommandArray; aScope: TBotCommandScope; const aLanguage: String
  ): Boolean;
var
  sendObj: TJSONObject;
begin
  Result:=False;
  sendObj:=TJSONObject.Create;
  try
    if Assigned(aBotCommands) then
      sendObj.Add(s_commands, aBotCommands.Clone);
    if Assigned(aScope) then
      sendObj.Add(s_scope, aScope.Clone);               
    if not aLanguage.IsEmpty then
      sendObj.Add(s_LanguageCode, aLanguage);
    Result:=SendMethod(s_setMyCommands, sendObj);
  finally
    sendObj.Free;
  end;
end;

function TTelegramSender.setWebhook(const url: String; MaxConnections: Integer; AllowedUpdates: TUpdateSet): Boolean;
var
  sendObj: TJSONObject;
begin
  Result:=False;
  sendObj:=TJSONObject.Create;
  with sendObj do
  try
    Add(s_Url, url);
    if MaxConnections<>0 then
      Add(s_MaxConnections, MaxConnections);
    if AllowedUpdates<>[utUnknown] then
      Add(s_AllowedUpdates, AllowedUpdatesToJSON(AllowedUpdates));
    Result:=SendMethod(s_setWebhook, sendObj);
  finally
    Free;
  end;
end;

function TTelegramSender.deleteWebhook: Boolean;
var
  sendObj: TJSONObject;
begin
  sendObj:=TJSONObject.Create;
  with sendObj do
  try
    Result:=SendMethod(s_deleteWebhook, sendObj);
  finally
    Free;
  end;
end;


function TTelegramSender.getUpdates(offset: Integer; limit: Integer;
  lp_timeout: Integer; allowed_updates: TUpdateSet): Boolean;
var
  sendObj: TJSONObject;
  lJSONArray: TJSONArray;
  lUpdateObj: TTelegramUpdateObj;
  lJSONEnum: TJSONEnum;
  aTimeout: Integer;
begin
  Result:=False;
  sendObj:=TJSONObject.Create;
  with sendObj do
  try    
    aTimeout:=Self.Timeout;
    if lp_timeout*1000>self.Timeout then
      Self.Timeout:=lp_timeout*1000+3000; // The HTTPClient timeout cannot be less than logpolling timeout!
    if offset<>0 then
      Add(s_Offset, offset);
    if limit<>0 then    // if not specified then default[ = 100]
      Add(s_Limit, limit);
    if lp_timeout<>0 then
      Add(s_Timeout, lp_timeout);
    if allowed_updates <> [] then
      Add(s_AllowedUpdates, AllowedUpdatesToJSON(allowed_updates));
    FRequestWhenAnswer:=False; // You must do only HTTP request because because it's important to get a response in the form of an update array
    Result:=SendMethod(s_getUpdates, sendObj);
    if Result then
      if Assigned(JSONResponse) then
      begin
        lJSONArray:=(JSONResponse.Clone as TJSONArray);  // jsonResponse maybe changed or freed in OnReceive event
        try
          for lJSONEnum in lJSONArray do
          begin
            lUpdateObj := TTelegramUpdateObj.CreateFromJSONObject(lJSONEnum.Value as TJSONObject) as TTelegramUpdateObj;
            DoReceiveUpdate(lUpdateObj);
          end;
        finally
          lJSONArray.Free;
        end;
      end;
  finally
    self.Timeout:=aTimeout;
    Free;
  end;
end;

function TTelegramSender.getUpdatesEx(limit: Integer; lp_timeout: Integer;
  allowed_updates: TUpdateSet): Boolean;
var
  aUpdateID: Integer;
begin
  aUpdateID:=FUpdateID;
  if aUpdateID<>0 then
    Inc(aUpdateID);
  Result:=getUpdates(aUpdateID, limit, lp_timeout, allowed_updates);
end;

function TTelegramSender.kickChatMember(chat_id: Int64; user_id: Int64;
  kickDuration: Int64): Boolean;
var
  sendObj: TJSONObject;
begin
  Result:=False;
  sendObj:=TJSONObject.Create;
  with sendObj do
  try
    Add(s_ChatId, chat_id);
    Add(s_UserID, user_id);
    Add(s_UntilDate, kickDuration);
    Result:=SendMethod(s_banChatMember, sendObj);
  finally
    Free;
  end;
end;

function TTelegramSender.SendAudio(chat_id: Int64; const audio: String;
  const Caption: String; ParseMode: TParseMode; Duration: Integer;
  DisableNotification: Boolean; ReplyToMessageID: Integer;
  const Performer: String; const Title: String; ReplyMarkup: TReplyMarkup
  ): Boolean;
var
  sendObj: TJSONObject;
begin
  Result:=False;
  sendObj:=TJSONObject.Create;
  with sendObj do
  try
    Add(s_ChatId, chat_id);
    Add(s_Audio, audio);
    if Caption<>EmptyStr then
      Add(s_Caption, Caption);
    if ParseMode<>pmDefault then
      Add(s_ParseMode, ParseModes[ParseMode]);
    if Duration<>0 then
      Add(s_Duration, Duration);
    if DisableNotification then
      Add(s_DsblNtfctn, DisableNotification);
    if ReplyToMessageID<>0 then
      Add(s_ReplyToMessageID, ReplyToMessageID);
    if Performer<>EmptyStr then
      Add(s_Performer, Performer);
    if Title<>EmptyStr then
      Add(s_Title, Title);
    if Assigned(ReplyMarkup) then
      Add(s_ReplyMarkup, ReplyMarkup.Clone); // Clone of ReplyMarkup object will have released with sendObject
    Result:=SendMethod(s_sendAudio, sendObj);
  finally
    Free;
  end;
end;

function TTelegramSender.sendDocument(chat_id: Int64; const file_id: String;
  const Caption: String; ParseMode: TParseMode; DisableNotification: Boolean;
  ReplyToMessageID: Integer; ReplyMarkup: TReplyMarkup): Boolean;
var
  sendObj: TJSONObject;
begin
  Result:=False;
  sendObj:=TJSONObject.Create;
  with sendObj do
  try
    Add(s_ChatId, chat_id);
    Add(s_Document, file_id);
    if Caption<>EmptyStr then
      Add(s_Caption, Caption);
    if ParseMode<>pmDefault then
      Add(s_ParseMode, ParseModes[ParseMode]);
    if DisableNotification then
      Add(s_DsblNtfctn, DisableNotification);
    if ReplyToMessageID<>0 then
      Add(s_ReplyToMessageID, ReplyToMessageID);
    if Assigned(ReplyMarkup) then
      Add(s_ReplyMarkup, ReplyMarkup.Clone); // Clone of ReplyMarkup object will have released with sendObject
    Result:=SendMethod(s_sendDocument, sendObj);
  finally
    Free;
  end;
end;

function TTelegramSender.sendDocumentByFileName(chat_id: Int64; const AFileName: String; const ACaption: String;
  ReplyMarkup: TReplyMarkup; ParseMode: TParseMode): Boolean;
var
  sendObj: TStringList;
begin
  Result:=False;
  sendObj:=TStringList.Create;
  with sendObj do
  try
    Add(s_ChatId+'='+IntToStr(chat_id));
    if ACaption<>EmptyStr then
      Add(s_Caption+'='+ACaption);
    if ParseMode<>pmDefault then
      Add(s_ParseMode+'='+ParseModes[ParseMode]);
    if Assigned(ReplyMarkup) then
      Add(s_ReplyMarkup+'='+ReplyMarkup.AsJSON);
    Result:=SendFile(s_sendDocument, s_Document, AFileName, sendObj);
  finally
    Free;
  end;
end;

function TTelegramSender.sendDocumentStream(chat_id: Int64;
  const AFileName: String; ADocStream: TStream; const ACaption: String;
  ReplyMarkup: TReplyMarkup): Boolean;
var
  sendObj: TStringList;
begin
  Result:=False;
  sendObj:=TStringList.Create;
  with sendObj do
  try
    Add(s_ChatId+'='+IntToStr(chat_id));
    if ACaption<>EmptyStr then
      Add(s_Caption+'='+ACaption);
    if Assigned(ReplyMarkup) then
      Add(s_ReplyMarkup+'='+ReplyMarkup.AsJSON);
    Result:=SendStream(s_sendDocument, s_Document, AFileName, ADocStream, sendObj);
  finally
    Free;
  end;
end;

function TTelegramSender.sendInvoice(chat_id: Int64; const Title, Description, Payload,
  ProviderToken, StartParameter, Currency: String; Prices: TLabeledPriceArray;
  ProviderData: TJSONObject; const PhotoUrl: String; PhotoSize: Integer; PhotoWidth: Integer;
  PhotoHeight: Integer; NeedName: Boolean; NeedPhoneNumber: Boolean; NeedEmail: Boolean;
  NeedShippingAddress: Boolean; SendPhoneNumberToProvider: Boolean; SendEmailToProvider: Boolean;
  IsFlexible: Boolean; DisableNotification: Boolean; ReplyToMessageID: Integer;
  ReplyMarkup: TReplyMarkup): Boolean;
var
  sendObj: TJSONObject;
begin
  Result:=False;
  sendObj:=TJSONObject.Create;
  with sendObj do
  try
    Add(s_ChatId, chat_id);
    Add(s_Title, Title);
    Add(s_Description, Description);
    Add(s_Payload, Payload);
    Add(s_ProviderToken, ProviderToken);
    Add(s_StartParameter, StartParameter);
    Add(s_Currency, Currency);
    Add(s_Prices, Prices.Clone);
    if Assigned(ProviderData) then
      Add(s_ProviderData, ProviderData.Clone);
    if PhotoUrl<>EmptyStr then
      Add(s_PhotoUrl, PhotoUrl);
    if PhotoSize<>0 then
      Add(s_PhotoSize, PhotoSize);
    if PhotoWidth<>0 then
      Add(s_PhotoWidth, PhotoWidth);
    if PhotoHeight<>0 then
      Add(s_PhotoHeight, PhotoHeight);
    if NeedName then
      Add(s_NeedName, NeedName);
    if NeedPhoneNumber then
      Add(s_NeedPhoneNumber, NeedPhoneNumber);
    if NeedEmail then
      Add(s_NeedEmail, NeedEmail);
    if NeedShippingAddress then
      Add(s_NeedShippingAddress, NeedShippingAddress);
    if SendPhoneNumberToProvider then
      Add(s_SendPhoneNumber2Provider, SendPhoneNumberToProvider);
    if SendEmailToProvider then
      Add(s_SendEmail2Provider, SendEmailToProvider);
    if IsFlexible then
      Add(s_IsFlexible, IsFlexible);
    if DisableNotification then
      Add(s_DsblNtfctn, DisableNotification);
    if ReplyToMessageID<>0 then
      Add(s_ReplyToMessageID, ReplyToMessageID);
    if Assigned(ReplyMarkup) then
      Add(s_ReplyMarkup, ReplyMarkup.Clone);
    Result:=SendMethod(s_sendInvoice, sendObj);
  finally
    Free;
  end;
end;

function TTelegramSender.sendLocation(chat_id: Int64; Latitude,
  Longitude: Real; LivePeriod: Integer; ParseMode: TParseMode;
  DisableWebPagePreview: Boolean; ReplyMarkup: TReplyMarkup): Boolean;
var
  sendObj: TJSONObject;
begin
  Result:=False;
  sendObj:=TJSONObject.Create;
  with sendObj do
  try
    Add(s_ChatId, chat_id);
    Add(s_Latitude, Latitude);
    Add(s_Longitude, Longitude);
    if LivePeriod<>0 then
      Add(s_LivePeriod, LivePeriod);
    if ParseMode<>pmDefault then
      Add(s_ParseMode, ParseModes[ParseMode]);
    Add(s_DsblWbpgPrvw, DisableWebPagePreview);
    if Assigned(ReplyMarkup) then
      Add(s_ReplyMarkup, ReplyMarkup.Clone); // Clone of ReplyMarkup object will have released with sendObject
    Result:=SendMethod(s_sendLocation, sendObj);
  finally
    Free;
  end;
end;

function TTelegramSender.sendMediaGroup(chat_id: Int64;
  media: TInputMediaArray; DisableWebPagePreview: Boolean;
  ReplyToMessageID: Integer): Boolean;
var
  sendObj: TJSONObject;
begin
  Result:=False;
  sendObj:=TJSONObject.Create;
  with sendObj do
    try
      Add(s_ChatId, chat_id);
      if Assigned(media) then
        Add(s_Media, media.Clone);
      Add(s_DsblWbpgPrvw, DisableWebPagePreview);
      if ReplyToMessageID<>0 then
        Add(s_ReplyToMessageID, ReplyToMessageID);
      Result:=SendMethod(s_sendMediaGroup, sendObj);
    finally
      Free;
    end;
end;

function TTelegramSender.sendMediaGroupByFileNames(chat_id: Int64; media: TInputMediaArray): Boolean;
var
  sendObj, aFiles: TStringList;
  aMediaEnum: TJSONEnum;
  aField, aFileName: String;
  aMediaAlbum: TInputMediaArray;
  aInputMedia: TJSONObject;
begin
  Result:=False;
  aFiles:=nil;
  sendObj:=TStringList.Create;
  with sendObj do
  try
    AddPair({$IF FPC_FULLVERSION <= 30004}sendObj, {$ENDIF}s_ChatId, IntToStr(chat_id));
    if Assigned(media) then
    begin
      aFiles:=TStringList.Create;
      aMediaAlbum:=media.Clone as TInputMediaArray;
      try
        for aMediaEnum in aMediaAlbum do
        begin
          aInputMedia:=aMediaEnum.Value as TJSONObject;
          aFileName:=aInputMedia.Get(s_Media, EmptyStr);
          aField:='file'+aMediaEnum.KeyNum.ToString; {$IF FPC_FULLVERSION <= 30004}
          AddPair(aFiles, aField, aFileName);{$ELSE}
          aFiles.AddPair(aField, aFileName);
          {$ENDIF}
          aInputMedia.Strings[s_Media]:='attach://'+aField;
        end;
        AddPair({$IF FPC_FULLVERSION <= 30004}sendObj, {$ENDIF}s_Media, aMediaAlbum.AsJSON);
      finally
        aMediaAlbum.Free;
      end;
    end;
    Result:=SendFiles(s_sendMediaGroup, aFiles, sendObj);
  finally
    aFiles.Free;
    Free;
  end;
end;

function TTelegramSender.sendMediaGroupByStreams(chat_id: Int64;
  const ACaption: String; StreamsList: TStringList): Boolean;
var
  sendObj, aFiles: TStringList;
  aField, aFileName, aMediaType: String;
  aMediaAlbum: TJSONArray;
  aInputMedia: TJSONObject;
  f: Integer;{$IF FPC_FULLVERSION <= 30004}
  obj: TObject;{$ENDIF}
  aux: TJSONStringType;
begin
  Result:=False;
  aFiles:=nil;
  if not Assigned(StreamsList) then exit(false);
  sendObj:=TStringList.Create;
  try
    sendObj.AddPair({$IF FPC_FULLVERSION <= 30004}sendObj, {$ENDIF}s_ChatId, IntToStr(chat_id));

    aFiles:=TStringList.Create;
    try
      aMediaAlbum:=TJSONArray.Create;
      try

        for f:=0 to StreamsList.Count-1 do begin
          if (not assigned(StreamsList.Objects[f])) or (not (StreamsList.Objects[f] is TStream)) then continue;
          StreamsList.GetNameValue(f,aFileName,aMediaType);
          aField:='file'+f.ToString;
          aInputMedia :=TJSONObject.Create;
          aInputMedia.Add(s_Media,   'attach://'+aField);
          aInputMedia.Add(s_Type,    aMediaType);
          if f=0 then
            aInputMedia.Add(s_Caption, ACaption);
          aMediaAlbum.Add(aInputMedia);
          aField:='file'+f.ToString;
          aFiles.AddPair(aField, aFileName,StreamsList.Objects[f]);
        end;
        aux:=aMediaAlbum.AsJSON;
        sendObj.AddPair({$IF FPC_FULLVERSION <= 30004}sendObj, {$ENDIF}s_Media, aux);

        Result:=SendStreams(s_sendMediaGroup, aFiles, sendObj);
      finally
        aMediaAlbum.Free;
      end;
    finally
      aFiles.Free
    end;
  finally
    sendObj.Free;
  end;
end;

{  https://core.telegram.org/bots/api#sendmessage  }
function TTelegramSender.sendMessage(chat_id: Int64; const AMessage: String; ParseMode: TParseMode;
  DisableWebPagePreview: Boolean; ReplyMarkup: TReplyMarkup; ReplyToMessageID: Integer; DisableNotification: Boolean;
  MessageThreadID: Integer; const BusinessConnectionID: String): Boolean;
var
  sendObj: TJSONObject;
begin
  Result:=False;
  sendObj:=TJSONObject.Create;
  with sendObj do
    try
      if not BusinessConnectionID.IsEmpty then
        Add(s_BsnsCnctnID, BusinessConnectionID);
      Add(s_ChatId, chat_id);
      Add(s_Text, {$IF FPC_FULLVERSION < 30202}TJSONUnicodeStringType(AMessage){$else}AMessage{$endif});
      if ParseMode<>pmDefault then
        Add(s_ParseMode, ParseModes[ParseMode]);
      Add(s_DsblWbpgPrvw, DisableWebPagePreview);
      Add(s_DsblNtfctn, DisableNotification);
      if Assigned(ReplyMarkup) then
        Add(s_ReplyMarkup, ReplyMarkup.Clone); // Clone of ReplyMarkup object will have released with sendObject
      if ReplyToMessageID<>0 then
        Add(s_ReplyToMessageID, ReplyToMessageID);
      if MessageThreadID<>_nullThrd then
        Add(s_MsgThrdID, MessageThreadID);
      Result:=SendMethod(s_sendMessage, sendObj);
    finally
      Free;
    end;
end;

function TTelegramSender.sendMessageChannel(const chat_id, AMessage: String;
  ParseMode: TParseMode; DisableWebPagePreview: Boolean;
  ReplyMarkup: TReplyMarkup; ReplyToMessageID: Integer): Boolean;
var
  sendObj: TJSONObject;
begin
  Result:=False;
  sendObj:=TJSONObject.Create;
  with sendObj do
  try
    Add(s_ChatId, chat_id);
    Add(s_Text, AMessage);
    if ParseMode<>pmDefault then
      Add(s_ParseMode, ParseModes[ParseMode]);
    Add(s_DsblWbpgPrvw, DisableWebPagePreview);
    if Assigned(ReplyMarkup) then
      Add(s_ReplyMarkup, ReplyMarkup.Clone); // Clone of ReplyMarkup object will have released with sendObject
    if ReplyToMessageID<>0 then
      Add(s_ReplyToMessageID, ReplyToMessageID);
    Result:=SendMethod(s_sendMessage, sendObj);
  finally
    Free;
  end;
end;

function TTelegramSender.sendMessage(const AMessage: String; ParseMode: TParseMode; DisableWebPagePreview: Boolean;
  ReplyMarkup: TReplyMarkup; ReplyToMessageID: Integer; DisableNotification: Boolean): Boolean;
var
  aMsgThrdID: Integer;
begin
  if FCurrentIsTopicMessage then  // Need for the checking is questionable
    aMsgThrdID:=FCurrentThreadId
  else
    aMsgThrdID:=_nullThrd;
  Result:=sendMessage(FCurrentChatId, AMessage, ParseMode, DisableWebPagePreview, ReplyMarkup,
    ReplyToMessageID, DisableNotification, aMsgThrdID);
end;

{ https://core.telegram.org/bots/api#sendphoto }
function TTelegramSender.sendPhoto(chat_id: Int64; const APhoto: String;
  const ACaption: String; ParseMode: TParseMode; ReplyMarkup: TReplyMarkup;
  ReplyToMessageID: Integer): Boolean;
var
  sendObj: TJSONObject;
begin
  Result:=False;
  sendObj:=TJSONObject.Create;
  with sendObj do
    try
      Add(s_ChatId, chat_id);
      Add(s_Photo, APhoto);
      Add(s_Caption, ACaption);
      if ParseMode<>pmDefault then
        Add(s_ParseMode, ParseModes[ParseMode]);
      if Assigned(ReplyMarkup) then
        Add(s_ReplyMarkup, ReplyMarkup.Clone); // Clone of ReplyMarkup object will have released with sendObject
      if ReplyToMessageID<>0 then
        Add(s_ReplyToMessageID, ReplyToMessageID);
      Result:=SendMethod(s_sendPhoto, sendObj);
    finally
      Free;
    end;
end;

function TTelegramSender.sendPhotoByFileName(chat_id: Int64; const AFileName: String; const ACaption: String;
  ParseMode: TParseMode; ReplyMarkup: TReplyMarkup; ReplyToMessageID: Integer): Boolean;
var
  sendObj: TStringList;
begin
  Result:=False;
  sendObj:=TStringList.Create;
  with sendObj do
  try
    Add(s_ChatId+'='+IntToStr(chat_id));
    if ACaption<>EmptyStr then
      Add(s_Caption+'='+ACaption);
    if ParseMode<>pmDefault then
      Add(s_ParseMode+'='+ParseModes[ParseMode]);
    if Assigned(ReplyMarkup) then
      Add(s_ReplyMarkup+'='+ReplyMarkup.AsJSON);
    if ReplyToMessageID<>0 then
      Add(s_ReplyToMessageID+'='+IntToStr(ReplyToMessageID));
    Result:=SendFile(s_sendPhoto, s_Photo, AFileName, sendObj);
  finally
    Free;
  end;
end;

function TTelegramSender.sendPhoto(const APhoto: String;
  const ACaption: String; ParseMode: TParseMode; ReplyMarkup: TReplyMarkup;
  ReplyToMessageID: Integer): Boolean;
begin
  Result:=sendPhoto(FCurrentChatId, APhoto, ACaption, ParseMode, ReplyMarkup, ReplyToMessageID);
end;

function TTelegramSender.sendPhotoStream(chat_id: Int64;
  const AFileName: String; APhotoStream: TStream; const ACaption: String;
  ParseMode: TParseMode; ReplyMarkup: TReplyMarkup): Boolean;
var
  sendObj: TStringList;
begin
  Result:=False;
  sendObj:=TStringList.Create;
  with sendObj do
  try
    Add(s_ChatId+'='+IntToStr(chat_id));
    if ACaption<>EmptyStr then
      Add(s_Caption+'='+ACaption);  
    if ParseMode<>pmDefault then
      Add(s_ParseMode+'='+ParseModes[ParseMode]);
    if Assigned(ReplyMarkup) then
      Add(s_ReplyMarkup+'='+ReplyMarkup.AsJSON);
    Result:=SendStream(s_sendPhoto, s_Photo, AFileName, APhotoStream, sendObj);
  finally
    Free;
  end;
end;

{ https://core.telegram.org/bots/api#sendvideo }
function TTelegramSender.sendVideo(chat_id: Int64; const AVideo: String;
  const ACaption: String; ParseMode: TParseMode; ReplyMarkup: TReplyMarkup;
  ReplyToMessageID: Integer; Width: Integer; Height: Integer): Boolean;
var
  sendObj: TJSONObject;
begin
  Result:=False;
  sendObj:=TJSONObject.Create;
  with sendObj do
  try
    Add(s_ChatId, chat_id);
    Add(s_Video, AVideo);
    if Width<>0 then
      Add(s_Width, Width);
    if Height<>0 then
      Add(s_Height, Height);
    if ACaption<>EmptyStr then
      Add('caption', ACaption);
    if ParseMode<>pmDefault then
      Add(s_ParseMode, ParseModes[ParseMode]);
    if Assigned(ReplyMarkup) then
      Add(s_ReplyMarkup, ReplyMarkup.Clone); // Clone of ReplyMarkup object will have released with sendObject
    if ReplyToMessageID<>0 then
      Add(s_ReplyToMessageID, ReplyToMessageID);
    Result:=SendMethod(s_sendVideo, sendObj);
  finally
    Free;
  end;
end;

function TTelegramSender.sendVideo(const AVideo: String;
  const ACaption: String; ParseMode: TParseMode; ReplyMarkup: TReplyMarkup;
  ReplyToMessageID: Integer; Width: Integer; Height: Integer): Boolean;
begin
  Result:=sendVideo(FCurrentChatId, AVideo, ACaption, ParseMode, ReplyMarkup, ReplyToMessageID, Width, Height);
end;

function TTelegramSender.sendVideoByFileName(chat_id: Int64; const AFileName: String; const ACaption: String;
  ParseMode: TParseMode; ReplyMarkup: TReplyMarkup; ReplyToMessageID: Integer; Width: Word = 0; Height: Word = 0): Boolean;
var
  sendObj: TStringList;
begin
  Result:=False;
  sendObj:=TStringList.Create;
  with sendObj do
  try
    Add(s_ChatId+'='+IntToStr(chat_id));
    if Width<>0 then
      Add(s_Width+'='+Width.ToString);  
    if Height<>0 then
      Add(s_Height+'='+Height.ToString);
    if ACaption<>EmptyStr then
      Add(s_Caption+'='+ACaption);
    if ParseMode<>pmDefault then
      Add(s_ParseMode+'='+ParseModes[ParseMode]);
    if Assigned(ReplyMarkup) then
      Add(s_ReplyMarkup+'='+ReplyMarkup.AsJSON); 
    if ReplyToMessageID<>0 then
      Add(s_ReplyToMessageID+'='+IntToStr(ReplyToMessageID));
    Result:=SendFile(s_sendVideo, s_Video, AFileName, sendObj);
  finally
    Free;
  end;
end;

function TTelegramSender.sendVideoStream(chat_id: Int64; const AFileName: String; AVideoStream: TStream;
  const ACaption: String; ParseMode: TParseMode; ReplyMarkup: TReplyMarkup; ReplyToMessageID: Integer; Width: Integer;
  Height: Integer): Boolean;
var
  sendObj: TStringList;
begin
  Result:=False;
  sendObj:=TStringList.Create;
  with sendObj do
  try
    Add(s_ChatId+'='+IntToStr(chat_id));
    if ACaption<>EmptyStr then
      Add(s_Caption+'='+ACaption);
    if ParseMode<>pmDefault then
      Add(s_ParseMode+'='+ParseModes[ParseMode]);
    if Assigned(ReplyMarkup) then
      Add(s_ReplyMarkup+'='+ReplyMarkup.AsJSON);
     if Width<>0 then
      Add(s_Width+'='+Width.ToString);
    if Height<>0 then
      Add(s_Height+'='+Height.ToString);
    if ReplyToMessageID<>0 then
      Add(s_ReplyToMessageID+'='+ReplyToMessageID.ToString);
    Result:=SendStream(s_sendVideo, s_Video, AFileName, AVideoStream, sendObj);
  finally
    Free;
  end;
end;

function TTelegramSender.sendVoice(chat_id: Int64; const Voice: String;
  const Caption: String; ParseMode: TParseMode; Duration: Integer;
  DisableNotification: Boolean; ReplyToMessageID: Integer;
  ReplyMarkup: TReplyMarkup): Boolean;
var
  sendObj: TJSONObject;
begin
  Result:=False;
  sendObj:=TJSONObject.Create;
  with sendObj do
  try
    Add(s_ChatId, chat_id);
    Add(s_Voice, Voice);
    if Caption<>EmptyStr then
      Add(s_Caption, Caption);
    if ParseMode<>pmDefault then
      Add(s_ParseMode, ParseModes[ParseMode]);
    if Duration<>0 then
      Add(s_Duration, Duration);
    if DisableNotification then
      Add(s_DsblNtfctn, DisableNotification);
    if ReplyToMessageID<>0 then
      Add(s_ReplyToMessageID, ReplyToMessageID);
    if Assigned(ReplyMarkup) then
      Add(s_ReplyMarkup, ReplyMarkup.Clone); // Clone of ReplyMarkup object will have released with sendObject
    Result:=SendMethod(s_sendVoice, sendObj);
  finally
    Free;
  end;
end;

function TTelegramSender.sendAnimation(chat_id: Int64;
  const aAnimation: String; const ACaption: String; ParseMode: TParseMode;
  ReplyMarkup: TReplyMarkup; ReplyToMessageID: Integer; Width: Integer;
  Height: Integer): Boolean;
var
  sendObj: TJSONObject;
begin
  Result:=False;
  sendObj:=TJSONObject.Create;
  with sendObj do
  try
    Add(s_ChatId, chat_id);
    Add(s_Animation, aAnimation);
    if Width<>0 then
      Add(s_Width, Width);
    if Height<>0 then
      Add(s_Height, Height);
    if ACaption<>EmptyStr then
      Add('caption', ACaption);
    if ParseMode<>pmDefault then
      Add(s_ParseMode, ParseModes[ParseMode]);
    if Assigned(ReplyMarkup) then
      Add(s_ReplyMarkup, ReplyMarkup.Clone); // Clone of ReplyMarkup object will have released with sendObject
    if ReplyToMessageID<>0 then
      Add(s_ReplyToMessageID, ReplyToMessageID);
    Result:=SendMethod(s_sendAnimation, sendObj);
  finally
    Free;
  end;
end;

function TTelegramSender.sendAnimation(const aAnimation: String;
  const ACaption: String; ParseMode: TParseMode; ReplyMarkup: TReplyMarkup;
  ReplyToMessageID: Integer; Width: Integer; Height: Integer): Boolean;
begin
  Result:=sendAnimation(FCurrentChatId, aAnimation, ACaption, ParseMode, ReplyMarkup, ReplyToMessageID, Width, Height);
end;

function TTelegramSender.sendAnimationByFileName(chat_id: Int64; const AFileName: String; const ACaption: String;
  ParseMode: TParseMode; ReplyMarkup: TReplyMarkup; ReplyToMessageID: Integer; Width: Integer; Height: Integer
  ): Boolean;
var
  sendObj: TStringList;
begin
  Result:=False;
  sendObj:=TStringList.Create;
  with sendObj do
  try
    Add(s_ChatId+'='+IntToStr(chat_id));
    if Width<>0 then
      Add(s_Width+'='+Width.ToString);
    if Height<>0 then
      Add(s_Height+'='+Height.ToString);
    if ACaption<>EmptyStr then
      Add(s_Caption+'='+ACaption);
    if ParseMode<>pmDefault then
      Add(s_ParseMode+'='+ParseModes[ParseMode]);
    if Assigned(ReplyMarkup) then
      Add(s_ReplyMarkup+'='+ReplyMarkup.AsJSON);
    if ReplyToMessageID<>0 then
      Add(s_ReplyToMessageID+'='+IntToStr(ReplyToMessageID));
    Result:=SendFile(s_sendAnimation, s_Animation, AFileName, sendObj);
  finally
    Free;
  end;
end;

function TTelegramSender.sendPoll(chat_id: Int64; const Question: String; const Options: array of String;
  IsAnonymous: Boolean; aType: TPollType; AllowMultipleAnswers: Boolean; CorrectOptionID: Integer;
  const Explanation: String; explanation_parse_mode: TParseMode; ReplyMarkup: TReplyMarkup): Boolean;
var
  sendObj: TJSONObject;
  s: String;
  aJSONArray: TJSONArray;
begin
  Result:=False;
  sendObj:=TJSONObject.Create;
  with sendObj do
    try
      Add(s_ChatId, chat_id);
      Add(s_Question, Question);
      aJSONArray:=TJSONArray.Create;
      for s in Options do
        aJSONArray.Add(s);
      Add(s_Options, aJSONArray);
      if not IsAnonymous then
        Add(s_IsAnonymous, IsAnonymous);
      if aType<>ptRegular then
        Add(s_Type, PollTypeToAlias(aType));
      if AllowMultipleAnswers then
        Add(s_AllowMultipleAnswers, AllowMultipleAnswers);
      if CorrectOptionID<>-1 then
        Add(s_CorrectOptionID, CorrectOptionID);
      if not Explanation.IsEmpty then
        Add(s_Explanation);
      if explanation_parse_mode<>pmDefault then
        Add(s_ParseMode, ParseModes[explanation_parse_mode]);
      if Assigned(ReplyMarkup) then
        Add(s_ReplyMarkup, ReplyMarkup.Clone); // Clone of ReplyMarkup object will have released with sendObject
      Result:=SendMethod(s_sendPoll, sendObj);
    finally
      Free;
    end;
end;

function TTelegramSender.answerInlineQuery(const AnInlineQueryID: String;
  Results: TInlineQueryResultArray; CacheTime: Integer; IsPersonal: Boolean;
  const NextOffset: String; const SwitchPmText: String;
  const SwitchPmParameter: String): Boolean;
begin  // todo: do not include default parameters... but is it really so necessary?
  Result:=SendMethod(s_answerInlineQuery, [s_InlineQueryID, AnInlineQueryID, s_Results, Results.Clone,
    s_CacheTime, CacheTime, s_IsPersonal, IsPersonal, s_NextOffset, NextOffset,
    s_switchPmText, SwitchPmText, s_SwitchPmParameter, SwitchPmParameter]);
end;

function TTelegramSender.getFile(const FileID: String): Boolean;
begin
  Result:=SendMethod(s_getFile, [s_FileID, FileID]);
  if Result then
    if Assigned(JSONResponse) then
      FileObj := TTelegramFile.CreateFromJSONObject(JSONResponse as TJSONObject) as TTelegramFile;
end;

function TTelegramSender.banChatMember(chat_id, user_id: Int64; until_date: Int64 = 0): Boolean;
var
  sendObj: TJSONObject;
begin
  Result:=False;
  sendObj:=TJSONObject.Create;
  with sendObj do
  try
    Add(s_ChatId, chat_id);
    Add(s_UserID, user_id);
    if until_date<>0 then
      Add(s_UntilDate, until_date);
    Result:=SendMethod(s_banChatMember, sendObj);
  finally
    Free;
  end;
end;

function TTelegramSender.unbanChatMember(chat_id, user_id: Int64; only_if_banned: Boolean): Boolean;
var
  sendObj: TJSONObject;
begin
  Result:=False;
  sendObj:=TJSONObject.Create;
  with sendObj do
  try
    Add(s_ChatId, chat_id);
    Add(s_UserID, user_id);
    if only_if_banned then
      Add(s_OnlyIfBanned, only_if_banned);
    Result:=SendMethod(s_unbanChatMember, sendObj);
  finally
    Free;
  end;
end;

function TTelegramSender.SendContent(aChatID: Int64; aContentType: TContentType; const aText, aMedia: String;
  aParseMode: TParseMode; aReplyMarkup: TReplyMarkup): Boolean;
begin
  case aContentType of
    cntText:     Result:=sendMessage(aChatID, aText, aParseMode, False, aReplyMarkup);
    cntPhoto:    Result:=sendPhoto(aChatID, aMedia, aText, aParseMode, aReplyMarkup);
    cntAudio:    Result:=SendAudio(aChatID, aMedia, aText, aParseMode, 0, False, 0, EmptyStr,
      EmptyStr, aReplyMarkup);
    cntVideo:    Result:=sendVideo(aChatID, aMedia, aText, aParseMode, aReplyMarkup);
    cntVoice:    Result:=sendVoice(aChatID, aMedia, aText, aParseMode, 0, False, 0, aReplyMarkup);
    cntDocument: Result:=sendDocument(aChatID, aMedia, aText, aParseMode, False, 0, aReplyMarkup);
  end;
end;

function TTelegramSender.getChatAdministrators(chat_id: Int64; out aChatMembers: TJSONArray): Boolean;
var
  sendObj: TJSONObject;
begin
  Result:=False;
  sendObj:=TJSONObject.Create;
  with sendObj do
  try
    Add(s_ChatId, chat_id);
    Result:=SendMethod(s_GetChatAdministrators, sendObj);
    if Result and Assigned(JSONResponse) then
      aChatMembers:=JSONResponse.Clone as TJSONArray
    else
      aChatMembers:=TJSONArray.Create;
  finally
    Free;
  end;
end;

end.

