unit tgtypes;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpJSON, jsonparser, fgl;

type
  TTelegramUpdateObj = class;
  TTelegramMessageObj = class;
  TTelegramMessageEntityObj = class;
  TTelegramChatMemberUpdated = class;
  TTelegramInlineQueryObj = class;
  TTelegramChosenInlineResultObj = class;
  TTelegramUserObj = class;
  TTelegramChatObj = class;
  TCallbackQueryObj = class;
  TTelegramBusinessConnectionObj = class;
  TTelegramLocation = class; 
  TTelegramContact = class;
  TArrayOfPhotoSize = class(TJSONArray);
  TTelegramPhotoSize = class;
  TTelegramPreCheckOutQuery = class;
  TTelegramSuccessfulPayment = class;
  TTelegramUpdateObjList = specialize TFPGObjectList<TTelegramMessageEntityObj>;
  TTelegramPhotoSizeList = specialize TFPGObjectList<TTelegramPhotoSize>;
  TTelegramVideo = class;
  TTelegramVoice = class;
  TTelegramAudio = class;
  TTelegramDocument = class;
  TTelegramReactionType = class;
  TTelegramReactionCount = class;
  TTelegramMessageReactionUpdated = class;
  TTelegramMessageReactionCountUpdated = class;

  TUpdateType = (utMessage, utEditedMessage, utChannelPost, utEditedChannelPost, utInlineQuery,
    utChosenInlineResult, utCallbackQuery, utShippingQuery, utPreCheckoutQuery, utMyChatMember, utChatMember,
    utBusinessConnection, utBusinessMessage, utMessageReaction, utMessageReactionCount, utUnknown);
  TChatType = (ctPrivate, ctGroup, ctSuperGroup, ctChannel, ctUnknown);
  TChatMemberStatus = (msCreator, msAdministrator, msMember, msRestricted, msLeft, msKicked, msUnknown);
  TUpdateSet = set of TUpdateType;

  { TTelegramObj }

  TTelegramObj = class
  private
    fJSON: TJSONObject;
  public
    constructor Create(JSONObject: TJSONObject); virtual;  // Caution! The JSONObject must be released separately
    destructor Destroy; override;
    class function CreateFromJSONObject(JSONObject: TJSONObject): TTelegramObj;
    function AsString: String;
  end;

  { TTelegramUpdateObj }

  TTelegramUpdateObj = class(TTelegramObj)
  private
    { Once in this object (according to the description in Telegram bot API) can be present only one
      parameter then the field FUpdateParameter will be one }
    FUpdateParameter: TTelegramObj;
    fUpdateId: Integer;
    FUpdateType: TUpdateType;
    function GetBusinessConnection: TTelegramBusinessConnectionObj;
    function GetBusinessMessage: TTelegramMessageObj;
    function GetCallbackQuery: TCallbackQueryObj;
    function GetChannelPost: TTelegramMessageObj;
    function GetChatMember: TTelegramChatMemberUpdated;
    function GetChosenInlineResult: TTelegramChosenInlineResultObj;
    function GetEditedChannelPost: TTelegramMessageObj;
    function GetEditedMessage: TTelegramMessageObj;
    function GetInlineQuery: TTelegramInlineQueryObj;
    function GetMessage: TTelegramMessageObj;
    function GetMessageReaction: TTelegramMessageReactionUpdated;
    function GetMessageReactionCount: TTelegramMessageReactionCountUpdated;
    function GetMyChatMember: TTelegramChatMemberUpdated;
    function GetPreCheckoutQuery: TTelegramPreCheckOutQuery;
    function ParseUpdateParameter: TUpdateType;
  public
    constructor Create(JSONObject: TJSONObject); override;
    function Clone: TTelegramUpdateObj;
    destructor Destroy; override;
    property UpdateId: Integer read fUpdateId;
    property UpdateType: TUpdateType read FUpdateType;
    property Message: TTelegramMessageObj read GetMessage;
    property EditedMessage: TTelegramMessageObj read GetEditedMessage;
    property CallbackQuery: TCallbackQueryObj read GetCallbackQuery;
    property InlineQuery: TTelegramInlineQueryObj read GetInlineQuery;
    property ChosenInlineResult: TTelegramChosenInlineResultObj read GetChosenInlineResult;
    property ChannelPost: TTelegramMessageObj read GetChannelPost;
    property EditedChannelPost: TTelegramMessageObj read GetEditedChannelPost;
    property PreCheckoutQuery: TTelegramPreCheckOutQuery read GetPreCheckoutQuery;
    property BusinessConnection: TTelegramBusinessConnectionObj read GetBusinessConnection; 
    property BusinessMessage: TTelegramMessageObj read GetBusinessMessage;   
    property MessageReaction: TTelegramMessageReactionUpdated read GetMessageReaction;
    property MessageReactionCount: TTelegramMessageReactionCountUpdated read GetMessageReactionCount;
    property MyChatMember: TTelegramChatMemberUpdated read GetMyChatMember;
    property ChatMember: TTelegramChatMemberUpdated read GetChatMember;
  end;

  TContentType = (cntUnknown, cntText, cntPhoto, cntVideo, cntAudio, cntVoice, cntDocument, cntLocation, cntContact);

  { TTelegramMessageObj }

  TTelegramMessageObj = class(TTelegramObj)
  private
    FAudio: TTelegramAudio;
    FBusinessConnectionID: String;
    FCaption: String;
    FChat: TTelegramChatObj;
    FContact: TTelegramContact;
    FDate: Int64;
    FDocument: TTelegramDocument;
    FForwardFrom: TTelegramUserObj;
    FForwardFromChat: TTelegramChatObj;
    FForwardFromMessageID: LongInt;
    FFrom: TTelegramUserObj;
    FIsTopicMessage: Boolean;
    FLocation: TTelegramLocation;
    FMediaGroupID: String;
    fMessageId: Integer;
    fChatId: Int64;
    FMessageThreadID: Integer;
    FPhoto: TTelegramPhotoSizeList;
    FReplyToMessage: TTelegramMessageObj;
    FSuccessfulPayment: TTelegramSuccessfulPayment;
    FViaBot: TTelegramUserObj;
    FVideo: TTelegramVideo;
    fText: string;
    fEntities: TTelegramUpdateObjList;
    FVoice: TTelegramVoice;
  public
    constructor Create(JSONObject: TJSONObject); override;
    destructor Destroy; override;
    function ContentFromMessage(out aText: String; out aMedia: String): TContentType;
    property Caption: String read FCaption;
    property BusinessConnectionID: String read FBusinessConnectionID;
    property MessageId: Integer read fMessageId;
    property From: TTelegramUserObj read FFrom;
    property Date: Int64 read FDate;
    property Chat: TTelegramChatObj read FChat;
    property ForwardFrom: TTelegramUserObj read FForwardFrom;
    property ForwardFromChat: TTelegramChatObj read FForwardFromChat;
    property ForwardFromMessageID: Integer read FForwardFromMessageID;
    property ChatId: Int64 read fChatId;
    property ReplyToMessage: TTelegramMessageObj read FReplyToMessage;
    property Text: string read fText;
    property Entities: TTelegramUpdateObjList read fEntities;
    property Document: TTelegramDocument read FDocument;
    property Location: TTelegramLocation read FLocation;
    property Photo: TTelegramPhotoSizeList read FPhoto;
    property Audio: TTelegramAudio read FAudio;
    property Video: TTelegramVideo read FVideo;
    property Voice: TTelegramVoice read FVoice;
    property Contact: TTelegramContact read FContact;
    property SuccessfulPayment: TTelegramSuccessfulPayment read FSuccessfulPayment;
    property ViaBot: TTelegramUserObj read FViaBot;
    property MediaGroupID: String read FMediaGroupID;
    property MessageThreadID: Integer read FMessageThreadID;
    property IsTopicMessage: Boolean read FIsTopicMessage;
  end;

  { TTelegramMessageEntityObj }

  TTelegramMessageEntityObj = class(TTelegramObj)
  private
    fTypeEntity: string;
    fOffset: Integer;
    fLength: Integer;
  public
    constructor Create(JSONObject: TJSONObject); override;
    property TypeEntity: string read fTypeEntity;
    property Offset: Integer read fOffset;
    property Length: Integer read fLength;
  end;

  { TCallbackQueryObj }

  TCallbackQueryObj = class(TTelegramObj)
  private
    FChatInstance: String;
    FData: String;
    FFrom: TTelegramUserObj;
    FID: String;
    FMessage: TTelegramMessageObj;
  public
    constructor Create(JSONObject: TJSONObject); override;
    destructor Destroy; override;
    property ID: String read FID;
    property From: TTelegramUserObj read FFrom;
    property Message: TTelegramMessageObj read FMessage;
    property ChatInstance: String read FChatInstance;
    property Data: String read FData;  // optional 1-64 bytes!!!
  end;

  { TTelegramReactionType }

  TTelegramReactionType = class(TTelegramObj)
  private
    FTypeName: String;
    FEmoji: String;
    FCustomEmojiID: String;
  public
    constructor Create(JSONObject: TJSONObject); override;
    property TypeName: String read FTypeName;
    property Emoji: String read FEmoji;
    property CustomEmojiID: String read FCustomEmojiID;
  end;

  TTelegramReactionTypeList = specialize TFPGObjectList<TTelegramReactionType>;

  { TTelegramReactionCount }

  TTelegramReactionCount = class(TTelegramObj)
  private
    FReactionType: TTelegramReactionType;
    FTotalCount: Integer;
  public
    constructor Create(JSONObject: TJSONObject); override;
    destructor Destroy; override;
    property ReactionType: TTelegramReactionType read FReactionType;
    property TotalCount: Integer read FTotalCount;
  end;

  TTelegramReactionCountList = specialize TFPGObjectList<TTelegramReactionCount>;

  { TTelegramMessageReactionUpdated }

  TTelegramMessageReactionUpdated = class(TTelegramObj)
  private
    FChat: TTelegramChatObj;
    FMessageID: Integer;
    FUser: TTelegramUserObj;
    FActorChat: TTelegramChatObj;
    FDate: Int64;
    FOldReactions: TTelegramReactionTypeList;
    FNewReactions: TTelegramReactionTypeList;
  public
    constructor Create(JSONObject: TJSONObject); override;
    destructor Destroy; override;
    property Chat: TTelegramChatObj read FChat;
    property MessageID: Integer read FMessageID;
    property User: TTelegramUserObj read FUser;
    property ActorChat: TTelegramChatObj read FActorChat;
    property Date: Int64 read FDate;
    property OldReactions: TTelegramReactionTypeList read FOldReactions;
    property NewReactions: TTelegramReactionTypeList read FNewReactions;
  end;

  { TTelegramMessageReactionCountUpdated }

  TTelegramMessageReactionCountUpdated = class(TTelegramObj)
  private
    FChat: TTelegramChatObj;
    FMessageID: Integer;
    FDate: Int64;
    FReactions: TTelegramReactionCountList;
  public
    constructor Create(JSONObject: TJSONObject); override;
    destructor Destroy; override;
    property Chat: TTelegramChatObj read FChat;
    property MessageID: Integer read FMessageID;
    property Date: Int64 read FDate;
    property Reactions: TTelegramReactionCountList read FReactions;
  end;

  { TTelegramBusinessConnectionObj }

  TTelegramBusinessConnectionObj = class(TTelegramObj)
  private
    FCanReply: Boolean;
    FDate: Int64;
    FID: Int64;
    FUser: TTelegramUserObj;
    FUserChatID: Int64;
    FIsEnabled: Boolean;
  public
    constructor Create(JSONObject: TJSONObject); override;
    destructor Destroy; override;
    property ID: Int64 read FID;
    property User: TTelegramUserObj read FUser;
    property UserChatID: Int64 read FUserChatID;
    property Date: Int64 read FDate; // Unix Time
    property CanReply: Boolean read FCanReply;
    property IsEnabled: Boolean read FIsEnabled;
  end;

  { TTelegramInlineQueryObj }

  TTelegramInlineQueryObj = class(TTelegramObj)
  private
    FFrom: TTelegramUserObj;
    FID: String;
    FLocation: TTelegramLocation;
    FOffset: String;
    FQuery: String;
  public
    constructor Create(JSONObject: TJSONObject); override;
    destructor Destroy; override;
    property ID: String read FID;
    property From: TTelegramUserObj read FFrom;
    property Location: TTelegramLocation read FLocation;
    property Query: String read FQuery;
    property Offset: String read FOffset;
  end;

  { TTelegramChosenInlineResultObj }

  TTelegramChosenInlineResultObj = class(TTelegramObj)
  private
    FFrom: TTelegramUserObj;
    FInlineMessageID: String;
    FLocation: TTelegramLocation;
    FQuery: String;
    FResultID: String;
    procedure SetFrom(AValue: TTelegramUserObj);
    procedure SetInlineMessageID(AValue: String);
    procedure SetLocation(AValue: TTelegramLocation);
    procedure SetQuery(AValue: String);
    procedure SetResultID(AValue: String);
  public
    constructor Create(JSONObject: TJSONObject); override;
    destructor Destroy; override;
    property ResultID: String read FResultID;
    property From: TTelegramUserObj read FFrom;
    property Location: TTelegramLocation read FLocation;
    property InlineMessageID: String read FInlineMessageID;
    property Query: String read FQuery;
  end;

  { TTelegramBaseChat }

  TTelegramBaseChat=class(TTelegramObj)
  private
    FFirst_name: String;
    FID: Int64;
    FLast_name: String;
    FUsername: String;
  public
    constructor Create(JSONObject: TJSONObject); override;
    class function GetResolveUserLink(aID: Int64): String;
    function GetResolveUserLink: String;
    property ID: Int64 read FID;
    property First_name: String read FFirst_name;
    property Last_name: String read FLast_name;
    property Username: String read FUsername;
  end;

  { TTelegramUserObj }

  TTelegramUserObj = class(TTelegramBaseChat)
  private
    FIs_bot: Boolean;
    FLanguage_code: String;
  public
    function Clone: TTelegramUserObj;
    constructor Create(JSONObject: TJSONObject); override;
    property Is_bot: Boolean read FIs_bot;
    property Language_code: String read FLanguage_code;
  end;

  { TTelegramChatObj }

  TTelegramChatObj = class(TTelegramBaseChat)
  private
    FChatType: TChatType;
    FTitle: String;
    class function StringToChatType(const TypeString: String): TChatType;
  public                                                   
    function Clone: TTelegramChatObj;
    constructor Create(JSONObject: TJSONObject); override;
    property ChatType: TChatType read FChatType;
    property Title: String read FTitle;
  end;

  { TTelegramLocation }

  TTelegramLocation = class(TTelegramObj)
  private
    FLatitude: Double;
    FLongitude: Double;
  public
    constructor Create(JSONObject: TJSONObject); override;
    property Longitude: Double read FLongitude write FLongitude;
    property Latitude: Double read FLatitude write FLatitude;
  end;

  { TTelegramContact }

  TTelegramContact = class(TTelegramObj)
  private
    Ffirst_name: String;
    Flast_name: String;
    Fphone_number: String;
    FUser_id: Int64;
    Fvcard: String;
  public
    constructor Create(JSONObject: TJSONObject); override;
    property phone_number: String read Fphone_number write Fphone_number;
    property first_name: String read Ffirst_name write Ffirst_name;  
    property last_name: String read Flast_name write Flast_name;
    property user_id: Int64 read FUser_id write Fuser_id;
    property vcard: String read Fvcard write Fvcard;
  end;

  { TTelegramPhotoSize }

  TTelegramPhotoSize = class(TTelegramObj)
  private
    FFileID: String;
    FFileSize: Integer;
    FHeight: Integer;
    FWidth: Integer;
  public
    constructor Create(JSONObject: TJSONObject); override;
    property FileID: String read FFileID;
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property FileSize: Integer read FFileSize;
  end;

  { TTelegramFile }

  TTelegramFile = class(TTelegramObj)
  private
    FFileID: String;
    FFilePath: String;
    FFileSize: Integer;
  public
    constructor Create(JSONObject: TJSONObject); override;
    class function DownloadLink(const AFilePath, AToken: String): String;
    function DownloadLink(const AToken: String): String; overload;
    property FileID: String read FFileID;
    property FileSize: Integer read FFileSize;
    property FilePath: String read FFilePath; //  https://api.telegram.org/file/bot<token>/<file_path>
  end;

  { TOrderInfo }

  TOrderInfo = class(TTelegramObj)
  private
    FEmail: String;
    FName: String;
    FPhoneNumber: String;
  public
    constructor Create(JSONObject: TJSONObject); override;
    property Name: String read FName;
    property PhoneNumber: String read FPhoneNumber;
    property Email: String read FEmail;
  end;

  { TTelegramPreCheckOutQuery }

  TTelegramPreCheckOutQuery = class(TTelegramObj)
  private
    FCurrency: String;
    FFrom: TTelegramUserObj;
    FID: String;
    FInvoicePayload: String;
    FOrderInfo: TOrderInfo;
    FShippingOptionID: String;
    FTotalAmount: Integer;
  public
    constructor Create(JSONObject: TJSONObject); override;
    destructor Destroy; override;
    property ID: String read FID; // Unique query identifier
    property From: TTelegramUserObj read FFrom;  // User who sent the query
    property Currency: String read FCurrency;  // Three-letter ISO 4217 currency code
{ Total price in the smallest units of the currency (integer, not float/double).
    For example, for a price of US$ 1.45 pass amount = 145. See the exp parameter in https://core.telegram.org/bots/payments/currencies.json,
    it shows the number of digits past the decimal point for each currency (2 for the majority of currencies). }
    property TotalAmount: Integer read FTotalAmount;
    property InvoicePayload: String read FInvoicePayload; // Bot specified invoice payload
    property ShippingOptionID: String read FShippingOptionID;  // Optional. Identifier of the shipping option chosen by the user
    property OrderInfo: TOrderInfo read FOrderInfo; // Optional. Order info provided by the user
  end;

  { TTelegramSuccessfulPayment }

  TTelegramSuccessfulPayment = class(TTelegramObj)
  private
    FCurrency: String;
    FInvoicePayload: String;
    FOrderInfo: TOrderInfo;
    FProviderPaymentChargeID: String;
    FTelegramPaymentChargeID: String;
    FTotalAmount: Integer;
  public
    constructor Create(JSONObject: TJSONObject); override;
    destructor Destroy; override;
    property Currency: String read FCurrency;
    property TotalAmount: Integer read FTotalAmount;
    property InvoicePayload: String read FInvoicePayload;
    property OrderInfo: TOrderInfo read FOrderInfo;
    property TelegramPaymentChargeID: String read FTelegramPaymentChargeID;
    property ProviderPaymentChargeID: String read FProviderPaymentChargeID;
  end;

  { TTelegramChatMember }

  TTelegramChatMember = class(TTelegramObj)
  private
    FChatMemberStatus: TChatMemberStatus;
    Fis_member: Boolean;
    FUser: TTelegramUserObj;
    class function StringToStatus(const StatusString: String): TChatMemberStatus;
  public
    constructor Create(JSONObject: TJSONObject); override;
    destructor Destroy; override;
    property User: TTelegramUserObj read FUser;
    property is_member: Boolean read Fis_member;
    property StatusType: TChatMemberStatus read FChatMemberStatus;
  end;

  { TTelegramChatMemberUpdated }

  TTelegramChatMemberUpdated = class(TTelegramObj)
  private
    fChat: TTelegramChatObj;
    fDate: Integer;
    fNewChatMember: TTelegramChatMember;
    fOldChatMember: TTelegramChatMember;
    fFrom: TTelegramUserObj;
  public
    constructor Create(JSONObject: TJSONObject); override;
    destructor Destroy; override;
    property Chat: TTelegramChatObj read fChat;
    property From: TTelegramUserObj read fFrom;
    property Date: Integer read fDate;
    property OldChatMember: TTelegramChatMember read fOldChatMember;
    property NewChatMember: TTelegramChatMember read fNewChatMember;
  end;


  { TTelegramWebhookInfo }

  TTelegramWebhookInfo = class(TTelegramObj)
  private
    FAllowedUpdates: TUpdateSet;
    FHasCustomCertificate: Boolean;
    FLastErrorDate: Int64;
    FLastErrorMessage: String;
    FMaxConnections: Integer;
    FPendingUpdateCount: Integer;
    FUrl: String;
    function GetLastErrorDateAsDateTime: TDateTime;
  public
    constructor Create(JSONObject: TJSONObject); override;
    property Url: String read FUrl;
    property AllowedUpdates: TUpdateSet read FAllowedUpdates;
    property HasCustomCertificate: Boolean read FHasCustomCertificate;
    property LastErrorDate: Int64 read FLastErrorDate;  // UnixTime
    property LastErrorDateAsDateTime: TDateTime read GetLastErrorDateAsDateTime;
    property LastErrorMessage: String read FLastErrorMessage;
    property MaxConnections: Integer read FMaxConnections;
    property PendingUpdateCount: Integer read FPendingUpdateCount;
  end;

  { TTelegramVideo }

  TTelegramVideo = class(TTelegramObj)
  private
    FDuration: Integer;
    FFileID: String;
    FFileName: String;
    FFileSize: Integer;
    FHeight: Integer;
    FMimeType: String;
    FThumb: TTelegramPhotoSize;
    FWidth: Integer;
  public
    constructor Create(JSONObject: TJSONObject); override;
    destructor Destroy; override;
    property FileID: String read FFileID;
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property Duration: Integer read FDuration;
    property Thumb: TTelegramPhotoSize read FThumb;
    property MimeType: String read FMimeType;
    property FileSize: Integer read FFileSize;
    property FileName: String read FFileName;
  end;


  { TTelegramDocument }

  TTelegramDocument = class(TTelegramObj)
  private
    FFileID: String;
    FFileName: String;
    FFileSize: Integer;
    FMimeType: String;
    FThumb: TTelegramPhotoSize;
  public
    constructor Create(JSONObject: TJSONObject); override;
    destructor Destroy; override;
    property FileID: String read FFileID;
    property FileName: String read FFileName;
    property MimeType: String read FMimeType;
    property FileSize: Integer read FFileSize;
    property Thumb: TTelegramPhotoSize read FThumb;
  end;

  { TTelegramAudio }

  TTelegramAudio = class(TTelegramObj)
  private
    FDuration: Integer;
    FFileID: String;
    FFileSize: Integer;
    FMimeType: String;
    FPerformer: String;
    FThumb: TTelegramPhotoSize;
    FTitle: String;
  public
    constructor Create(JSONObject: TJSONObject); override;
    destructor Destroy; override;
    property FileID: String read FFileID;
    property Duration: Integer read FDuration;
    property Performer: String read FPerformer;
    property Title: String read FTitle;
    property MimeType: String read FMimeType;
    property FileSize: Integer read FFileSize;
    property Thumb: TTelegramPhotoSize read FThumb;
  end;

  { TTelegramVoice }

  TTelegramVoice = class(TTelegramObj)
  private
    FDuration: Integer;
    FFileID: String;
    FFileSize: Integer;
    FMimeType: String;
  public
    constructor Create(JSONObject: TJSONObject); override;
    property FileID: String read FFileID;
    property Duration: Integer read FDuration;
    property MimeType: String read FMimeType;
    property FileSize: Integer read FFileSize;
  end;

  TTelegramObjClass = class of TTelegramObj;

  const
    TELEGRAM_REQUEST_GETUPDATES = 'getUpdates';
    UpdateTypeAliases: array[TUpdateType] of String = ('message', 'edited_message', 'channel_post',
      'edited_channel_post', 'inline_query', 'chosen_inline_result', 'callback_query',
      'shipping_query', 'pre_checkout_query', 'my_chat_member', 'chat_member', 'business_connection',
      'business_message', 'message_reaction', 'message_reaction_count', '');
    UpdateTypeClasses: array[TUpdateType] of TTelegramObjClass = (TTelegramMessageObj, TTelegramMessageObj,
      TTelegramMessageObj, TTelegramMessageObj, TTelegramInlineQueryObj, TTelegramChosenInlineResultObj,
      TCallbackQueryObj, TTelegramObj, TTelegramPreCheckOutQuery, TTelegramChatMemberUpdated,
      TTelegramChatMemberUpdated, TTelegramBusinessConnectionObj, TTelegramMessageObj,
      TTelegramMessageReactionUpdated, TTelegramMessageReactionCountUpdated, TTelegramObj);
    _nullThrd = 0;

function AllowedUpdatesToJSON(const AllowedUpdates: TUpdateSet): TJSONArray;

const
  utAllUpdates = [Low(TUpdateType)..Pred(High(TUpdateType))];
  utDefaultUpdates = utAllUpdates-[utChatMember];

implementation

uses
  strutils, dateutils
  ;

const
  API_URL_FILE='https://api.telegram.org/file/bot';

  s_FileSize = 'file_size';  
  s_FileName = 'file_name';
  s_IsTpcMsg = 'is_topic_message';
  s_MsgThrdID ='message_thread_id';
  s_BsnsCnctnID='business_connection_id';

function AllowedUpdatesToJSON(const AllowedUpdates: TUpdateSet): TJSONArray;
var
  u: TUpdateType;
begin
  Result:=TJSONArray.Create;
  for u in AllowedUpdates do
    Result.Add(UpdateTypeAliases[u]);
end;

function JSONToUpdateSet(const aUpdateSet: TJSONArray): TUpdateSet;
var
  aEnum: TJSONEnum;
  i: Integer;
begin
  Result:=[];
  for aEnum in aUpdateSet do
  begin
    i:=AnsiIndexStr(aEnum.Value.AsString, UpdateTypeAliases);
    if i<>-1 then
      Include(Result, TUpdateType(i));
  end;
  if Result=[] then
    Result:=utAllUpdates;
end;

{ TTelegramBaseChat }

constructor TTelegramBaseChat.Create(JSONObject: TJSONObject);
begin
  inherited Create(JSONObject);
  FID := fJSON.Int64s['id'];
  FFirst_name:=fJSON.Get('first_name', EmptyStr);
  FLast_name:=fJSON.Get('last_name', EmptyStr);
  FUsername:=fJSON.Get('username', EmptyStr);
end;

class function TTelegramBaseChat.GetResolveUserLink(aID: Int64): String;
begin
  Result:=Format('tg://user?id=%d', [aID]);
end;

function TTelegramBaseChat.GetResolveUserLink: String;
begin
  Result:=GetResolveUserLink(FID);
end;

{ TTelegramContact }

constructor TTelegramContact.Create(JSONObject: TJSONObject);
begin
  inherited Create(JSONObject);
  Fphone_number := fJSON.Strings['phone_number'];
  Ffirst_name :=   fJSON.Strings['first_name'];
  Flast_name :=    fJSON.Get('last_name', EmptyStr);
  FUser_id :=      fJSON.Get('user_id', 0);
  Fvcard :=        fJSON.Get('vcard', EmptyStr);
end;

{ TTelegramWebhookInfo }

function TTelegramWebhookInfo.GetLastErrorDateAsDateTime: TDateTime;
begin
  Result:=UnixToDateTime(FLastErrorDate);
end;

constructor TTelegramWebhookInfo.Create(JSONObject: TJSONObject);
var
  aJSONArray: TJSONArray;
begin
  inherited Create(JSONObject);
  FUrl:=fJSON.Strings['url'];
  FHasCustomCertificate:=fJSON.Booleans['has_custom_certificate'];
  FPendingUpdateCount:=fJSON.Integers['pending_update_count'];
  FLastErrorDate:=fJSON.Get('last_error_date', 0);
  FLastErrorMessage:=fJSON.Get('last_error_message', EmptyStr);
  FMaxConnections:=fJSON.Get('max_connections', 0);

  if fJSON.Find('allowed_updates', aJSONArray) then
    FAllowedUpdates:=JSONToUpdateSet(aJSONArray)
  else
    FAllowedUpdates:=[];
end;

{ TTelegramDocument }

constructor TTelegramDocument.Create(JSONObject: TJSONObject);
begin
  inherited Create(JSONObject);
  FFileID := fJSON.Strings['file_id'];
  FThumb:=TTelegramPhotoSize.CreateFromJSONObject(fJSON.Find('thumb', jtObject) as TJSONObject) as TTelegramPhotoSize;
  FMimeType:=fJSON.Get('mime_type', EmptyStr);
  FFileSize := fJSON.Get(s_FileSize, 0);
  FFileName := fJSON.Get(s_FileName, EmptyStr);
end;

destructor TTelegramDocument.Destroy;
begin
  FThumb.Free;
  inherited Destroy;
end;

{ TTelegramAudio }

constructor TTelegramAudio.Create(JSONObject: TJSONObject);
begin
  inherited Create(JSONObject);
  FFileID := fJSON.Strings['file_id'];
  FDuration:=fJSON.Integers['duration'];
  FPerformer:=fJSON.Get('performer', EmptyStr);
  FTitle:=fJSON.Get('title', EmptyStr);
  FThumb:=TTelegramPhotoSize.CreateFromJSONObject(fJSON.Find('thumb', jtObject) as TJSONObject) as TTelegramPhotoSize;
  FMimeType:=fJSON.Get('mime_type', EmptyStr);
  FFileSize := fJSON.Get(s_FileSize, 0);
end;

destructor TTelegramAudio.Destroy;
begin
  FThumb.Free;
  inherited Destroy;
end;

{ TTelegramVoice }

constructor TTelegramVoice.Create(JSONObject: TJSONObject);
begin
  inherited Create(JSONObject);
  FFileID := fJSON.Strings['file_id'];
  FDuration:=fJSON.Integers['duration'];
  FMimeType:=fJSON.Get('mime_type', EmptyStr);
  FFileSize := fJSON.Get(s_FileSize, 0);
end;

{ TTelegramVideo }

constructor TTelegramVideo.Create(JSONObject: TJSONObject);
begin
  inherited Create(JSONObject);
  FFileID := fJSON.Strings['file_id'];
  FWidth:=fJSON.Integers['width'];
  FHeight:=fJSON.Integers['height'];
  FDuration:=fJSON.Integers['duration'];
  FThumb:=TTelegramPhotoSize.CreateFromJSONObject(fJSON.Find('thumb', jtObject) as TJSONObject) as TTelegramPhotoSize;
  FMimeType:=fJSON.Get('mime_type', EmptyStr);
  FFileSize := fJSON.Get(s_FileSize, 0);
  FFileName := fJSON.Get(s_FileName, EmptyStr);
end;

destructor TTelegramVideo.Destroy;
begin
  FThumb.Free;
  inherited Destroy;
end;

{ TTelegramChatMember }

class function TTelegramChatMember.StringToStatus(const StatusString: String
  ): TChatMemberStatus;
begin
  if StatusString='creator' then
    Exit(msCreator);
  if StatusString='administrator' then
    Exit(msAdministrator);
  if StatusString='member' then
    Exit(msMember);
  if StatusString='restricted' then
    Exit(msRestricted);
  if StatusString='left' then
    Exit(msLeft);
  if StatusString='kicked' then
    Exit(msKicked);
  Result:=msUnknown;
end;

constructor TTelegramChatMember.Create(JSONObject: TJSONObject);
begin
  inherited Create(JSONObject);
  FUser:=TTelegramUserObj.CreateFromJSONObject(fJSON.Find('user', jtObject) as TJSONObject) as TTelegramUserObj;
  Fis_member:=fJSON.Get('is_member', False);
  FChatMemberStatus:=StringToStatus(fJSON.Strings['status']);
end;

destructor TTelegramChatMember.Destroy;
begin
  FUser.Free;
  inherited Destroy;
end;

{ TTelegramChatMemberUpdated }

constructor TTelegramChatMemberUpdated.Create(JSONObject: TJSONObject);
begin
  inherited Create(JSONObject);
  fChat:=TTelegramChatObj.CreateFromJSONObject(fJSON.Find('chat', jtObject) as TJSONObject) as TTelegramChatObj;
  fFrom:=TTelegramUserObj.CreateFromJSONObject(fJSON.Find('from', jtObject) as TJSONObject) as TTelegramUserObj;
  fDate:=fJSON.Integers['date'];
  fOldChatMember:=TTelegramChatMember.CreateFromJSONObject(fJSON.Find('old_chat_member', jtObject) as TJSONObject)
    as TTelegramChatMember;   
  fNewChatMember:=TTelegramChatMember.CreateFromJSONObject(fJSON.Find('new_chat_member', jtObject) as TJSONObject)
    as TTelegramChatMember;
end;

destructor TTelegramChatMemberUpdated.Destroy;
begin
  fChat.Free;
  fFrom.Free;
  fOldChatMember.Free;
  fNewChatMember.Free;
  inherited Destroy;
end;

{ TTelegramSuccessfulPayment }

constructor TTelegramSuccessfulPayment.Create(JSONObject: TJSONObject);
begin
  inherited Create(JSONObject);
  FCurrency:=fJSON.Strings['currency'];
  FTotalAmount:=fJSON.Integers['total_amount'];
  FInvoicePayload:=fJSON.Strings['invoice_payload'];
  FOrderInfo:=TOrderInfo.CreateFromJSONObject(
    fJSON.Find('order_info', jtObject) as TJSONObject) as TOrderInfo;
  FTelegramPaymentChargeID:=fJSON.Strings['telegram_payment_charge_id'];
  FProviderPaymentChargeID:=fJSON.Strings['provider_payment_charge_id'];
end;

destructor TTelegramSuccessfulPayment.Destroy;
begin
  FreeAndNil(FOrderInfo);
  inherited Destroy;
end;

{ TOrderInfo }

constructor TOrderInfo.Create(JSONObject: TJSONObject);
begin
  inherited Create(JSONObject);
  FName := fJSON.Get('name', EmptyStr);
  FPhoneNumber := fJSON.Get('phone_number', EmptyStr);
  FEmail := fJSON.Get('email', EmptyStr);
end;

{ TTelegramPreCheckOutQuery }

constructor TTelegramPreCheckOutQuery.Create(JSONObject: TJSONObject);
begin
  inherited Create(JSONObject);
  FID:=fJSON.Strings['id'];
  FFrom:=TTelegramUserObj.CreateFromJSONObject(fJSON.Find('from', jtObject) as TJSONObject) as TTelegramUserObj;;
  FCurrency:=fJSON.Strings['currency'];
  FTotalAmount:=fJSON.Integers['total_amount'];
  FInvoicePayload:=fJSON.Strings['invoice_payload'];
  FShippingOptionID:=fJSON.Get('shipping_option_id', EmptyStr);
  FOrderInfo:=TOrderInfo.CreateFromJSONObject(
    fJSON.Find('order_info', jtObject) as TJSONObject) as TOrderInfo;
end;

destructor TTelegramPreCheckOutQuery.Destroy;
begin
  FreeAndNil(FOrderInfo);
  FreeAndNil(FFrom);
  inherited Destroy;
end;

{ TTelegramFile }

constructor TTelegramFile.Create(JSONObject: TJSONObject);
begin
  inherited Create(JSONObject);
  FFileID := fJSON.Strings['file_id'];
  FFileSize := fJSON.Get(s_FileSize, 0);
  FFilePath := fJSON.Get('file_path', '');
end;

class function TTelegramFile.DownloadLink(const AFilePath, AToken: String
  ): String;
begin
  Result:=API_URL_FILE+AToken+'/'+AFilePath;
end;

function TTelegramFile.DownloadLink(const AToken: String): String;
begin
  Result:=DownloadLink(FFilePath, AToken);
end;

{ TTelegramPhotoSize }

constructor TTelegramPhotoSize.Create(JSONObject: TJSONObject);
begin
  inherited Create(JSONObject);
  FFileID := fJSON.Strings['file_id'];
  FWidth := fJSON.Integers['width'];
  FHeight := fJSON.Integers['height'];
  FFileSize:=fJSON.Get(s_FileSize, 0);
end;

{ TTelegramChatObj }

class function TTelegramChatObj.StringToChatType(const TypeString: String
  ): TChatType;
begin
  if TypeString='private' then
    Exit(ctPrivate);
  if TypeString='group' then
    Exit(ctGroup);
  if TypeString='supergroup' then
    Exit(ctSuperGroup);
  if TypeString='channel' then
    Exit(ctChannel);
  Result:=ctUnknown;
end;

function TTelegramChatObj.Clone: TTelegramChatObj;
begin
  Result:=TTelegramChatObj.Create(fJSON);
end;

constructor TTelegramChatObj.Create(JSONObject: TJSONObject);
begin
  inherited Create(JSONObject);
  FChatType:=StringToChatType(fJSON.Strings['type']);
  FTitle:=fJSON.Get('title', '');
end;

{ TTelegramChosenInlineResultObj }

procedure TTelegramChosenInlineResultObj.SetFrom(AValue: TTelegramUserObj);
begin
  if FFrom=AValue then Exit;
  FFrom:=AValue;
end;

procedure TTelegramChosenInlineResultObj.SetInlineMessageID(AValue: String);
begin
  if FInlineMessageID=AValue then Exit;
  FInlineMessageID:=AValue;
end;

procedure TTelegramChosenInlineResultObj.SetLocation(AValue: TTelegramLocation);
begin
  if FLocation=AValue then Exit;
  FLocation:=AValue;
end;

procedure TTelegramChosenInlineResultObj.SetQuery(AValue: String);
begin
  if FQuery=AValue then Exit;
  FQuery:=AValue;
end;

procedure TTelegramChosenInlineResultObj.SetResultID(AValue: String);
begin
  if FResultID=AValue then Exit;
  FResultID:=AValue;
end;

constructor TTelegramChosenInlineResultObj.Create(JSONObject: TJSONObject);
begin
  inherited Create(JSONObject);
  FResultID := fJSON.Strings['result_id'];
  FFrom:=TTelegramUserObj.CreateFromJSONObject(fJSON.Find('from', jtObject) as TJSONObject) as TTelegramUserObj;
  FLocation:=TTelegramLocation.CreateFromJSONObject(fJSON.Find('location', jtObject) as TJSONObject) as TTelegramLocation;
  FInlineMessageID:=fJSON.Get('inline_message_id', '');
  FQuery:=fJSON.Strings['query'];
end;

destructor TTelegramChosenInlineResultObj.Destroy;
begin
  FreeAndNil(FLocation);
  FreeAndNil(FFrom);
  inherited Destroy;
end;

{ TTelegramLocation }

constructor TTelegramLocation.Create(JSONObject: TJSONObject);
begin
  inherited Create(JSONObject);
  FLongitude := fJSON.Floats['longitude'];
  FLatitude :=  fJSON.Floats['latitude'];
end;

{ TCallbackQueryObj }

constructor TCallbackQueryObj.Create(JSONObject: TJSONObject);
begin
  inherited Create(JSONObject);
  FID := fJSON.Strings['id'];
  FFrom:=TTelegramUserObj.CreateFromJSONObject(fJSON.Find('from', jtObject) as TJSONObject) as TTelegramUserObj;
  FMessage := TTelegramMessageObj.CreateFromJSONObject(
      fJSON.Find('message', jtObject) as TJSONObject) as TTelegramMessageObj;
  FChatInstance:= fJSON.Strings['chat_instance'];
  FData:=fJSON.Get('data', '');
end;

destructor TCallbackQueryObj.Destroy;
begin
  FMessage.Free;
  FFrom.Free;
  inherited Destroy;
end;

{ TTelegramReactionType }

constructor TTelegramReactionType.Create(JSONObject: TJSONObject);
begin
  inherited Create(JSONObject);
  FTypeName:=fJSON.Get('type', EmptyStr);
  FEmoji:=fJSON.Get('emoji', EmptyStr);
  FCustomEmojiID:=fJSON.Get('custom_emoji_id', EmptyStr);
end;

{ TTelegramReactionCount }

constructor TTelegramReactionCount.Create(JSONObject: TJSONObject);
begin
  inherited Create(JSONObject);
  FReactionType:=TTelegramReactionType.CreateFromJSONObject(
    fJSON.Find('type', jtObject) as TJSONObject) as TTelegramReactionType;
  FTotalCount:=fJSON.Get('total_count', 0);
end;

destructor TTelegramReactionCount.Destroy;
begin
  FReactionType.Free;
  inherited Destroy;
end;

{ TTelegramMessageReactionUpdated }

constructor TTelegramMessageReactionUpdated.Create(JSONObject: TJSONObject);
var
  lJSONArray: TJSONArray;
  lJSONEnum: TJSONEnum;
begin
  inherited Create(JSONObject);
  FMessageID:=fJSON.Integers['message_id'];
  FDate:=fJSON.Int64s['date'];
  FChat:=TTelegramChatObj.CreateFromJSONObject(fJSON.Find('chat', jtObject) as TJSONObject) as TTelegramChatObj;
  FUser:=TTelegramUserObj.CreateFromJSONObject(fJSON.Find('user', jtObject) as TJSONObject) as TTelegramUserObj;
  FActorChat:=TTelegramChatObj.CreateFromJSONObject(fJSON.Find('actor_chat', jtObject) as TJSONObject) as TTelegramChatObj;
  FOldReactions:=TTelegramReactionTypeList.Create;
  FNewReactions:=TTelegramReactionTypeList.Create;

  lJSONArray := fJSON.Find('old_reaction', jtArray) as TJSONArray;
  if Assigned(lJSONArray) then
    for lJSONEnum in lJSONArray do
      FOldReactions.Add(TTelegramReactionType.CreateFromJSONObject(
        lJSONEnum.Value as TJSONObject) as TTelegramReactionType);

  lJSONArray := fJSON.Find('new_reaction', jtArray) as TJSONArray;
  if Assigned(lJSONArray) then
    for lJSONEnum in lJSONArray do
      FNewReactions.Add(TTelegramReactionType.CreateFromJSONObject(
        lJSONEnum.Value as TJSONObject) as TTelegramReactionType);
end;

destructor TTelegramMessageReactionUpdated.Destroy;
begin
  FChat.Free;
  FUser.Free;
  FActorChat.Free;
  FOldReactions.Free;
  FNewReactions.Free;
  inherited Destroy;
end;

{ TTelegramMessageReactionCountUpdated }

constructor TTelegramMessageReactionCountUpdated.Create(JSONObject: TJSONObject);
var
  lJSONArray: TJSONArray;
  lJSONEnum: TJSONEnum;
begin
  inherited Create(JSONObject);
  FMessageID:=fJSON.Integers['message_id'];
  FDate:=fJSON.Int64s['date'];
  FChat:=TTelegramChatObj.CreateFromJSONObject(fJSON.Find('chat', jtObject) as TJSONObject) as TTelegramChatObj;
  FReactions:=TTelegramReactionCountList.Create;

  lJSONArray := fJSON.Find('reactions', jtArray) as TJSONArray;
  if Assigned(lJSONArray) then
    for lJSONEnum in lJSONArray do
      FReactions.Add(TTelegramReactionCount.CreateFromJSONObject(
        lJSONEnum.Value as TJSONObject) as TTelegramReactionCount);
end;

destructor TTelegramMessageReactionCountUpdated.Destroy;
begin
  FChat.Free;
  FReactions.Free;
  inherited Destroy;
end;

{ TTelegramBusinessConnectionObj }

constructor TTelegramBusinessConnectionObj.Create(JSONObject: TJSONObject);
begin
  inherited Create(JSONObject);
  FID := fJSON.Int64s['id'];
  FUser:=TTelegramUserObj.CreateFromJSONObject(fJSON.Find('user', jtObject) as TJSONObject) as TTelegramUserObj;
  FUserChatID:= fJSON.Int64s['user_chat_id'];
  FDate:=fJSON.Int64s['date'];
  FCanReply:=fJSON.Booleans['can_reply'];    
  FIsEnabled:=fJSON.Booleans['is_enabled'];
end;

destructor TTelegramBusinessConnectionObj.Destroy;
begin
  FUser.Free;
  inherited Destroy;
end;

{ TTelegramUserObj }

function TTelegramUserObj.Clone: TTelegramUserObj;
begin
  Result:=TTelegramUserObj.Create(fJSON);
end;

constructor TTelegramUserObj.Create(JSONObject: TJSONObject);
begin
  inherited Create(JSONObject);
  FIs_bot := fJSON.Booleans['is_bot'];
  FLanguage_code:=fJSON.Get('language_code', '');
end;

{ TTelegramInlineQueryObj }

constructor TTelegramInlineQueryObj.Create(JSONObject: TJSONObject);
begin
  inherited Create(JSONObject);
  FID := fJSON.Strings['id'];
  FQuery:=fJSON.Get('query', '');
  FOffset:=fJSON.Get('offset', '');

  FFrom:=TTelegramUserObj.CreateFromJSONObject(fJSON.Find('from', jtObject) as TJSONObject) as TTelegramUserObj;
  FLocation:=TTelegramLocation.CreateFromJSONObject(fJSON.Find('location', jtObject) as TJSONObject) as TTelegramLocation;
end;

destructor TTelegramInlineQueryObj.Destroy;
begin
  FLocation.Free;
  FFrom.Free;
  inherited Destroy;
end;

{ TTelegramObj }

constructor TTelegramObj.Create(JSONObject: TJSONObject);
begin
  fJSON := JSONObject.Clone as TJSONObject;
end;

destructor TTelegramObj.Destroy;
begin
  fJSON.Free;
  inherited Destroy;
end;

class function TTelegramObj.CreateFromJSONObject(JSONObject: TJSONObject): TTelegramObj;
begin
  try
    if Assigned(JSONObject) then
      Result := Create(JSONObject)
    else
      Result := nil;
  except
    Result := nil;
  end;
end;

function TTelegramObj.AsString: String;
begin
  Result:=fJSON.AsJSON;
end;

{ TTelegramUpdateObj }

function TTelegramUpdateObj.ParseUpdateParameter: TUpdateType;
begin
  Result:=Low(TUpdateType);
  while (Result<utUnknown) and not Assigned(FUpdateParameter) do
  begin
    FUpdateParameter := UpdateTypeClasses[Result].CreateFromJSONObject(
      fJSON.Find(UpdateTypeAliases[Result], jtObject) as TJSONObject);
    if not Assigned(FUpdateParameter) then
      Inc(Result)
  end;
end;

function TTelegramUpdateObj.GetMessage: TTelegramMessageObj;
begin
  if FUpdateType=utMessage then
    Result:=TTelegramMessageObj(FUpdateParameter)
  else
    Result:=nil;
end;

function TTelegramUpdateObj.GetMyChatMember: TTelegramChatMemberUpdated;
begin
  if FUpdateType=utMyChatMember then
    Result:=TTelegramChatMemberUpdated(FUpdateParameter)
  else
    Result:=nil;
end;

function TTelegramUpdateObj.GetPreCheckoutQuery: TTelegramPreCheckOutQuery;
begin
  if FUpdateType=utPreCheckoutQuery then
    Result:=TTelegramPreCheckOutQuery(FUpdateParameter)
  else
    Result:=nil;
end;

function TTelegramUpdateObj.GetCallbackQuery: TCallbackQueryObj;
begin
  if FUpdateType=utCallbackQuery then
    Result:=TCallbackQueryObj(FUpdateParameter)
  else
    Result:=nil;
end;

function TTelegramUpdateObj.GetBusinessConnection: TTelegramBusinessConnectionObj;
begin
  if FUpdateType=utBusinessConnection then
    Result:=TTelegramBusinessConnectionObj(FUpdateParameter)
  else
    Result:=nil;
end;

function TTelegramUpdateObj.GetBusinessMessage: TTelegramMessageObj;
begin
  if FUpdateType=utBusinessMessage then
    Result:=TTelegramMessageObj(FUpdateParameter)
  else
    Result:=nil;
end;

function TTelegramUpdateObj.GetChannelPost: TTelegramMessageObj;
begin
  if FUpdateType=utChannelPost then
    Result:=TTelegramMessageObj(FUpdateParameter)
  else
    Result:=nil;
end;

function TTelegramUpdateObj.GetChatMember: TTelegramChatMemberUpdated;
begin
  if FUpdateType=utChatMember then
    Result:=TTelegramChatMemberUpdated(FUpdateParameter)
  else
    Result:=nil;
end;

function TTelegramUpdateObj.GetChosenInlineResult: TTelegramChosenInlineResultObj;
begin
  if FUpdateType=utChosenInlineResult then
    Result:=TTelegramChosenInlineResultObj(FUpdateParameter)
  else
    Result:=nil;
end;

function TTelegramUpdateObj.GetEditedChannelPost: TTelegramMessageObj;
begin
  if FUpdateType=utEditedChannelPost then
    Result:=TTelegramMessageObj(FUpdateParameter)
  else
    Result:=nil;
end;

function TTelegramUpdateObj.GetEditedMessage: TTelegramMessageObj;
begin
  if FUpdateType=utEditedMessage then
    Result:=TTelegramMessageObj(FUpdateParameter)
  else
    Result:=nil;
end;

function TTelegramUpdateObj.GetInlineQuery: TTelegramInlineQueryObj;
begin
  if FUpdateType=utInlineQuery then
    Result:=TTelegramInlineQueryObj(FUpdateParameter)
  else
    Result:=nil;
end;

function TTelegramUpdateObj.GetMessageReaction: TTelegramMessageReactionUpdated;
begin
  if FUpdateType=utMessageReaction then
    Result:=TTelegramMessageReactionUpdated(FUpdateParameter)
  else
    Result:=nil;
end;

function TTelegramUpdateObj.GetMessageReactionCount: TTelegramMessageReactionCountUpdated;
begin
  if FUpdateType=utMessageReactionCount then
    Result:=TTelegramMessageReactionCountUpdated(FUpdateParameter)
  else
    Result:=nil;
end;

constructor TTelegramUpdateObj.Create(JSONObject: TJSONObject);
begin
  inherited Create(JSONObject);
  fUpdateId := fJSON.Integers['update_id'];
  FUpdateParameter:=nil;
  FUpdateType:=ParseUpdateParameter;
end;

function TTelegramUpdateObj.Clone: TTelegramUpdateObj;
begin
  Result:=TTelegramUpdateObj.Create(fJSON);
end;

destructor TTelegramUpdateObj.Destroy;
begin
  FUpdateParameter.Free;
  inherited Destroy;
end;

{ TTelegramMessageObj }

constructor TTelegramMessageObj.Create(JSONObject: TJSONObject);
var
  lJSONArray: TJSONArray;
  lJSONEnum: TJSONEnum;
begin
  inherited Create(JSONObject);
  fMessageId := fJSON.Integers['message_id'];

  FIsTopicMessage:=fJSON.Get(s_IsTpcMsg, False);
  FMessageThreadID:=fJSON.Get(s_MsgThrdID, 0);

  fText := fJSON.Get('text', EmptyStr);
  fEntities := TTelegramUpdateObjList.Create;
  FPhoto := TTelegramPhotoSizeList.Create;
  FCaption := fJSON.Get('caption', EmptyStr);
  FDate:=fJSON.Int64s['date'];
  FChat:=TTelegramChatObj.CreateFromJSONObject(fJSON.Find('chat', jtObject) as TJSONObject) as TTelegramChatObj;
  fChatId := fJSON.Objects['chat'].Int64s['id']; // deprecated?
  FFrom:=TTelegramUserObj.CreateFromJSONObject(fJSON.Find('from', jtObject) as TJSONObject) as TTelegramUserObj;
  FDocument := TTelegramDocument.CreateFromJSONObject(fJSON.Find('document', jtObject) as TJSONObject) as TTelegramDocument;
  FVideo := TTelegramVideo.CreateFromJSONObject(fJSON.Find('video', jtObject) as TJSONObject) as TTelegramVideo;
  FAudio := TTelegramAudio.CreateFromJSONObject(fJSON.Find('audio', jtObject) as TJSONObject) as TTelegramAudio;
  FVoice := TTelegramVoice.CreateFromJSONObject(fJSON.Find('voice', jtObject) as TJSONObject) as TTelegramVoice; 
  FViaBot := TTelegramUserObj.CreateFromJSONObject(fJSON.Find('via_bot', jtObject) as TJSONObject) as TTelegramUserObj;

  FForwardFrom:=TTelegramUserObj.CreateFromJSONObject(fJSON.Find('forward_from', jtObject) as TJSONObject) as TTelegramUserObj;
  FForwardFromChat:=TTelegramChatObj.CreateFromJSONObject(fJSON.Find('forward_from_chat', jtObject) as TJSONObject) as TTelegramChatObj;
  FForwardFromMessageID:=fJSON.Get('forward_from_message_id', 0);

  FLocation:=TTelegramLocation.CreateFromJSONObject(fJSON.Find('location', jtObject) as TJSONObject) as TTelegramLocation;

  FContact:=TTelegramContact.CreateFromJSONObject(fJSON.Find('contact', jtObject) as TJSONObject) as TTelegramContact;

  FMediaGroupID:=fJSON.Get('media_group_id', EmptyStr);

  FReplyToMessage:=
    TTelegramMessageObj.CreateFromJSONObject(fJSON.Find('reply_to_message', jtObject) as TJSONObject)
    as TTelegramMessageObj;

  lJSONArray := fJSON.Find('entities', jtArray) as TJSONArray;
  if Assigned(lJSONArray) then
    for lJSONEnum in lJSONArray do
      fEntities.Add(TTelegramMessageEntityObj.CreateFromJSONObject(lJSONEnum.Value as TJSONObject) as TTelegramMessageEntityObj);

  lJSONArray := fJSON.Find('photo', jtArray) as TJSONArray;
  if Assigned(lJSONArray) then
    for lJSONEnum in lJSONArray do
      FPhoto.Add(TTelegramPhotoSize.CreateFromJSONObject(lJSONEnum.Value as TJSONObject) as TTelegramPhotoSize);

  FSuccessfulPayment:=
    TTelegramSuccessfulPayment.CreateFromJSONObject(fJSON.Find('successful_payment', jtObject) as TJSONObject)
    as TTelegramSuccessfulPayment;

  FBusinessConnectionID:=fJSON.Get(s_BsnsCnctnID, EmptyStr);

end;

destructor TTelegramMessageObj.Destroy;
begin
  FForwardFrom.Free;
  FForwardFromChat.Free;
  FSuccessfulPayment.Free;
  FViaBot.Free;
  FFrom.Free;
  FContact.Free;
  FLocation.Free;
  FChat.Free;
  FReplyToMessage.Free;
  FPhoto.Free;
  FDocument.Free;
  FAudio.Free;
  FVideo.Free;
  FVoice.Free;
  fEntities.Free;
  inherited Destroy;
end;

function TTelegramMessageObj.ContentFromMessage(out aText: String; out aMedia: String): TContentType;
begin
  Result:=cntUnknown;
  aText:=Text;
  if aText<>EmptyStr then
    Exit(cntText);
  aText:=Caption;
  if Assigned(Photo) then if (Photo.Count>0) then
  begin
    aMedia:=Photo.Last.FileID;
    Exit(cntPhoto);
  end;
  if Assigned(Video) then
  begin
    aMedia:=Video.FileID;
    Exit(cntVideo);
  end;
  if Assigned(Voice) then
  begin
    aMedia:=Voice.FileID;
    Exit(cntVoice);
  end;
  if Assigned(Audio) then
  begin
    aMedia:=Audio.FileID;
    Exit(cntAudio);
  end;
  if Assigned(Document) then
  begin
    aMedia:=Document.FileID;
    Exit(cntDocument);
  end;
  if Assigned(Location) then
  begin
    aMedia:=EmptyStr;
    Exit(cntLocation);
  end;
  if Assigned(Contact) then
  begin
    aMedia:=EmptyStr;
    Exit(cntContact);
  end;
end;

{ TTelegramMessageEntityObj }

constructor TTelegramMessageEntityObj.Create(JSONObject: TJSONObject);
begin
  inherited Create(JSONObject);
  fTypeEntity := fJSON.Strings['type'];
  fOffset := fJSON.Integers['offset'];
  fLength := fJSON.Integers['length'];
end;

end.
