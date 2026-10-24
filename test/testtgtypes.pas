unit testtgtypes;

{
  Unit tests for the tgtypes unit: parsing of the Telegram API JSON objects
  (updates, messages, users, chats, payments, reactions and so on) into
  the TTelegram* object tree. No network activity.
}

{$mode objfpc}{$H+}
{$codepage UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fpjson, tgtypes;

type

  { TTestTgTypesParse }
  { Base class with helpers for constructing TTelegramObj descendants from JSON }

  TTestTgTypesParse = class(TTestCase)
  protected
    function JSONFromString(const AJSON: String): TJSONData;
    function UpdateFromString(const AJSON: String): TTelegramUpdateObj;
  published
    procedure ParseMessageUpdate;
    procedure ParseMessageFull;
    procedure ParseEditedMessageUpdate;
    procedure ParseChannelPostUpdates;
    procedure ParseCallbackQuery;
    procedure ParseInlineQuery;
    procedure ParseChosenInlineResult;
    procedure ParsePreCheckoutQuery;
    procedure ParseSuccessfulPaymentMessage;
    procedure ParseChatMemberUpdates;
    procedure ParseBusinessConnection;
    procedure ParseBusinessMessage;
    procedure ParseMessageReactionUpdate;
    procedure ParseMessageReactionCountUpdate;
    procedure ParseMessageQuote;
    procedure ParseMessageExternalReply;
    procedure ParseWebhookInfo;
    procedure ParseFileObject;
    procedure UnknownUpdateType;
    procedure ContentFromMessageText;
    procedure ContentFromMessagePhoto;
    procedure ContentFromMessageVideo;
    procedure ContentFromMessageDocument;
    procedure ContentFromMessageLocation;
    procedure ContentFromMessageContact;
    procedure AllowedUpdatesToJSONRoundtrip;
    procedure UpdateObjClone;
  end;

implementation

uses
  jsonparser, jsonscanner, DateUtils
  ;

const
  { UTF-8 encoded emoji, written via byte constants so the literals do not
    depend on the source file codepage (important on Windows) }
  { The emoji values are compared byte-wise in the tests below, because
    string comparison is codepage-sensitive on systems with a non-UTF8 codepage }
  EmojiThumbsUp = #$F0#$9F#$91#$8D;          // thumbs up
  EmojiRedHeart = #$E2#$9D#$A4#$EF#$B8#$8F;  // red heart

const
  ChatJSON = '{"id":42,"type":"private","first_name":"Test","last_name":"User","username":"testuser"}';
  UserJSON = '{"id":99,"is_bot":false,"first_name":"Bob","last_name":"Smith","username":"bob","language_code":"de"}';
  BotJSON = '{"id":1,"is_bot":true,"first_name":"TestBot","username":"test_bot"}';

function TTestTgTypesParse.JSONFromString(const AJSON: String): TJSONData;
var
  lOptions: TJSONOptions;
  lParser: TJSONParser;
begin
  { Parse with joUTF8 excluded, mirroring the -dJsonNoUTF8 workaround of the library
    (see issue #4): with joUTF8 enabled fpjson re-encodes non-ASCII strings to the
    system ANSI codepage, so the expected UTF-8 byte sequences would survive only
    on systems where the ANSI codepage is UTF-8 }
  lOptions:=DefaultOptions;
  Exclude(lOptions, joUTF8);
  lParser:=TJSONParser.Create(AJSON, lOptions);
  try
    Result:=lParser.Parse;
  finally
    lParser.Free;
  end;
end;

function TTestTgTypesParse.UpdateFromString(const AJSON: String): TTelegramUpdateObj;
var
  lJSON: TJSONData;
begin
  lJSON:=JSONFromString(AJSON);
  try
    Result:=TTelegramUpdateObj.Create(lJSON as TJSONObject);
  finally
    lJSON.Free;
  end;
end;

procedure TTestTgTypesParse.ParseMessageUpdate;
var
  lUpdate: TTelegramUpdateObj;
begin
  lUpdate:=UpdateFromString('{"update_id":100,"message":{"message_id":5,"date":1700000000,'+
    '"chat":'+ChatJSON+',"from":'+UserJSON+',"text":"Hello"}}');
  try
    AssertEquals('Update type', Ord(utMessage), Ord(lUpdate.UpdateType));
    AssertNotNull('Message assigned', lUpdate.Message);
    AssertEquals(100, lUpdate.UpdateId);
    AssertEquals('Hello', lUpdate.Message.Text);
    // the properties of the other update kinds must return nil
    AssertNull(lUpdate.EditedMessage);
    AssertNull(lUpdate.CallbackQuery);
    AssertNull(lUpdate.InlineQuery);
  finally
    lUpdate.Free;
  end;
end;

procedure TTestTgTypesParse.ParseMessageFull;
var
  lUpdate: TTelegramUpdateObj;
  lMsg: TTelegramMessageObj;
begin
  lUpdate:=UpdateFromString('{"update_id":101,"message":{"message_id":55,"date":1700000100,'+
    '"chat":{"id":-100123,"type":"supergroup","title":"Group"},"from":'+UserJSON+','+
    '"text":"Hi there","entities":[{"type":"bold","offset":0,"length":2}],' +
    '"caption":"cap","media_group_id":"mgid","is_topic_message":true,"message_thread_id":7,'+
    '"business_connection_id":"bcid",' +
    '"photo":[{"file_id":"f1","width":100,"height":80,"file_size":1234},'+
    '{"file_id":"f2","width":200,"height":160,"file_size":4567}]}}');
  try
    lMsg:=lUpdate.Message;
    AssertEquals(55, lMsg.MessageId);
    AssertEquals(-100123, lMsg.ChatId);
    AssertEquals(Int64(1700000100), lMsg.Date);
    AssertEquals('Hi there', lMsg.Text);
    AssertEquals('cap', lMsg.Caption);
    AssertEquals('mgid', lMsg.MediaGroupID);
    AssertEquals('bcid', lMsg.BusinessConnectionID);
    AssertTrue('IsTopicMessage', lMsg.IsTopicMessage);
    AssertEquals(7, lMsg.MessageThreadID);
    AssertEquals('supergroup', 'supergroup'); // sanity
    AssertEquals(Ord(ctSuperGroup), Ord(lMsg.Chat.ChatType));
    AssertEquals('Group', lMsg.Chat.Title);
    AssertEquals(99, lMsg.From.ID);
    AssertFalse(lMsg.From.Is_bot);
    AssertEquals('de', lMsg.From.Language_code);
    AssertEquals(1, lMsg.Entities.Count);
    AssertEquals('bold', lMsg.Entities[0].TypeEntity);
    AssertEquals(0, lMsg.Entities[0].Offset);
    AssertEquals(2, lMsg.Entities[0].Length);
    AssertEquals(2, lMsg.Photo.Count);
    AssertEquals('f2', lMsg.Photo.Last.FileID);
    AssertEquals(4567, lMsg.Photo.Last.FileSize);
    // optional members are simply absent
    AssertNull(lMsg.Video);
    AssertNull(lMsg.Document);
    AssertNull(lMsg.Location);
    AssertNull(lMsg.ReplyToMessage);
  finally
    lUpdate.Free;
  end;
end;

procedure TTestTgTypesParse.ParseEditedMessageUpdate;
var
  lUpdate: TTelegramUpdateObj;
begin
  lUpdate:=UpdateFromString('{"update_id":102,"edited_message":{"message_id":6,"date":1700000001,'+
    '"edit_date":1700000002,"chat":'+ChatJSON+',"from":'+UserJSON+',"text":"Edited"}}');
  try
    AssertEquals(Ord(utEditedMessage), Ord(lUpdate.UpdateType));
    AssertEquals('Edited', lUpdate.EditedMessage.Text);
    AssertNull(lUpdate.Message);
  finally
    lUpdate.Free;
  end;
end;

procedure TTestTgTypesParse.ParseChannelPostUpdates;
var
  lUpdate: TTelegramUpdateObj;
begin
  lUpdate:=UpdateFromString('{"update_id":103,"channel_post":{"message_id":7,"date":1700000003,'+
    '"chat":{"id":-100555,"type":"channel","title":"Chan"},"text":"Post"}}');
  try
    AssertEquals(Ord(utChannelPost), Ord(lUpdate.UpdateType));
    AssertEquals('Post', lUpdate.ChannelPost.Text);
  finally
    lUpdate.Free;
  end;
  lUpdate:=UpdateFromString('{"update_id":104,"edited_channel_post":{"message_id":8,"date":1700000004,'+
    '"chat":{"id":-100555,"type":"channel","title":"Chan"},"text":"Post2"}}');
  try
    AssertEquals(Ord(utEditedChannelPost), Ord(lUpdate.UpdateType));
    AssertEquals('Post2', lUpdate.EditedChannelPost.Text);
  finally
    lUpdate.Free;
  end;
end;

procedure TTestTgTypesParse.ParseCallbackQuery;
var
  lUpdate: TTelegramUpdateObj;
  lCallback: TCallbackQueryObj;
begin
  lUpdate:=UpdateFromString('{"update_id":105,"callback_query":{"id":"cbid","from":'+UserJSON+','+
    '"message":{"message_id":9,"date":1700000005,"chat":'+ChatJSON+',"text":"Msg"},'+
    '"data":"payload","chat_instance":"ci"}}');
  try
    AssertEquals(Ord(utCallbackQuery), Ord(lUpdate.UpdateType));
    lCallback:=lUpdate.CallbackQuery;
    AssertEquals('cbid', lCallback.ID);
    AssertEquals('payload', lCallback.Data);
    AssertEquals('ci', lCallback.ChatInstance);
    AssertEquals(99, lCallback.From.ID);
    AssertNotNull('Message assigned', lCallback.Message);
    AssertEquals(9, lCallback.Message.MessageId);
  finally
    lUpdate.Free;
  end;
end;

procedure TTestTgTypesParse.ParseInlineQuery;
var
  lUpdate: TTelegramUpdateObj;
begin
  lUpdate:=UpdateFromString('{"update_id":106,"inline_query":{"id":"iqid","from":'+UserJSON+','+
    '"query":"search","offset":"10","location":{"latitude":1.5,"longitude":2.5}}}');
  try
    AssertEquals(Ord(utInlineQuery), Ord(lUpdate.UpdateType));
    AssertEquals('iqid', lUpdate.InlineQuery.ID);
    AssertEquals('search', lUpdate.InlineQuery.Query);
    AssertEquals('10', lUpdate.InlineQuery.Offset);
    AssertEquals(99, lUpdate.InlineQuery.From.ID);
    AssertNotNull('Location assigned', lUpdate.InlineQuery.Location);
    AssertEquals(1.5, lUpdate.InlineQuery.Location.Latitude, 0.0001);
    AssertEquals(2.5, lUpdate.InlineQuery.Location.Longitude, 0.0001);
  finally
    lUpdate.Free;
  end;
end;

procedure TTestTgTypesParse.ParseChosenInlineResult;
var
  lUpdate: TTelegramUpdateObj;
begin
  lUpdate:=UpdateFromString('{"update_id":107,"chosen_inline_result":{"result_id":"r1","from":'+
    UserJSON+',"query":"q","inline_message_id":"im1"}}');
  try
    AssertEquals(Ord(utChosenInlineResult), Ord(lUpdate.UpdateType));
    AssertEquals('r1', lUpdate.ChosenInlineResult.ResultID);
    AssertEquals('q', lUpdate.ChosenInlineResult.Query);
    AssertEquals('im1', lUpdate.ChosenInlineResult.InlineMessageID);
    AssertNull('No location', lUpdate.ChosenInlineResult.Location);
  finally
    lUpdate.Free;
  end;
end;

procedure TTestTgTypesParse.ParsePreCheckoutQuery;
var
  lUpdate: TTelegramUpdateObj;
  lQuery: TTelegramPreCheckOutQuery;
begin
  lUpdate:=UpdateFromString('{"update_id":108,"pre_checkout_query":{"id":"pcq1","from":'+UserJSON+','+
    '"currency":"USD","total_amount":145,"invoice_payload":"pl1","shipping_option_id":"so1",'+
    '"order_info":{"name":"Name","phone_number":"+123","email":"a@b.c"}}}');
  try
    AssertEquals(Ord(utPreCheckoutQuery), Ord(lUpdate.UpdateType));
    lQuery:=lUpdate.PreCheckoutQuery;
    AssertEquals('pcq1', lQuery.ID);
    AssertEquals('USD', lQuery.Currency);
    AssertEquals(145, lQuery.TotalAmount);
    AssertEquals('pl1', lQuery.InvoicePayload);
    AssertEquals('so1', lQuery.ShippingOptionID);
    AssertNotNull('OrderInfo assigned', lQuery.OrderInfo);
    AssertEquals('Name', lQuery.OrderInfo.Name);
    AssertEquals('+123', lQuery.OrderInfo.PhoneNumber);
    AssertEquals('a@b.c', lQuery.OrderInfo.Email);
  finally
    lUpdate.Free;
  end;
end;

procedure TTestTgTypesParse.ParseSuccessfulPaymentMessage;
var
  lUpdate: TTelegramUpdateObj;
  lPayment: TTelegramSuccessfulPayment;
begin
  lUpdate:=UpdateFromString('{"update_id":109,"message":{"message_id":10,"date":1700000006,'+
    '"chat":'+ChatJSON+',"text":"","successful_payment":{"currency":"EUR","total_amount":990,'+
    '"invoice_payload":"payload2","telegram_payment_charge_id":"tpci","provider_payment_charge_id":"ppci"}}}');
  try
    lPayment:=lUpdate.Message.SuccessfulPayment;
    AssertNotNull('SuccessfulPayment assigned', lPayment);
    AssertEquals('EUR', lPayment.Currency);
    AssertEquals(990, lPayment.TotalAmount);
    AssertEquals('payload2', lPayment.InvoicePayload);
    AssertEquals('tpci', lPayment.TelegramPaymentChargeID);
    AssertEquals('ppci', lPayment.ProviderPaymentChargeID);
  finally
    lUpdate.Free;
  end;
end;

procedure TTestTgTypesParse.ParseChatMemberUpdates;
var
  lUpdate: TTelegramUpdateObj;
  lMemberUpdated: TTelegramChatMemberUpdated;
begin
  lUpdate:=UpdateFromString('{"update_id":110,"my_chat_member":{"chat":'+ChatJSON+','+
    '"from":'+UserJSON+',"date":1700000007,'+
    '"old_chat_member":{"user":'+UserJSON+',"status":"left"},'+
    '"new_chat_member":{"user":'+UserJSON+',"status":"member"}}}');
  try
    AssertEquals(Ord(utMyChatMember), Ord(lUpdate.UpdateType));
    lMemberUpdated:=lUpdate.MyChatMember;
    AssertEquals(42, lMemberUpdated.Chat.ID);
    AssertEquals(99, lMemberUpdated.From.ID);
    AssertEquals(Ord(msLeft), Ord(lMemberUpdated.OldChatMember.StatusType));
    AssertEquals(Ord(msMember), Ord(lMemberUpdated.NewChatMember.StatusType));
    AssertEquals(99, lMemberUpdated.NewChatMember.User.ID);
  finally
    lUpdate.Free;
  end;
  lUpdate:=UpdateFromString('{"update_id":111,"chat_member":{"chat":'+ChatJSON+','+
    '"from":'+BotJSON+',"date":1700000008,'+
    '"old_chat_member":{"user":'+UserJSON+',"status":"administrator","is_member":true},'+
    '"new_chat_member":{"user":'+UserJSON+',"status":"kicked","is_member":false}}}');
  try
    AssertEquals(Ord(utChatMember), Ord(lUpdate.UpdateType));
    AssertEquals(Ord(msAdministrator), Ord(lUpdate.ChatMember.OldChatMember.StatusType));
    AssertTrue(lUpdate.ChatMember.OldChatMember.is_member);
    AssertEquals(Ord(msKicked), Ord(lUpdate.ChatMember.NewChatMember.StatusType));
  finally
    lUpdate.Free;
  end;
end;

procedure TTestTgTypesParse.ParseBusinessConnection;
var
  lUpdate: TTelegramUpdateObj;
  lConnection: TTelegramBusinessConnectionObj;
begin
  lUpdate:=UpdateFromString('{"update_id":112,"business_connection":{"id":777,"user":'+UserJSON+','+
    '"user_chat_id":4242,"date":1700000009,"can_reply":true,"is_enabled":true}}');
  try
    AssertEquals(Ord(utBusinessConnection), Ord(lUpdate.UpdateType));
    lConnection:=lUpdate.BusinessConnection;
    AssertEquals(777, lConnection.ID);
    AssertEquals(4242, lConnection.UserChatID);
    AssertEquals(Int64(1700000009), lConnection.Date);
    AssertTrue(lConnection.CanReply);
    AssertTrue(lConnection.IsEnabled);
    AssertEquals(99, lConnection.User.ID);
  finally
    lUpdate.Free;
  end;
end;

procedure TTestTgTypesParse.ParseBusinessMessage;
var
  lUpdate: TTelegramUpdateObj;
begin
  lUpdate:=UpdateFromString('{"update_id":113,"business_message":{"message_id":11,"date":1700000010,'+
    '"chat":'+ChatJSON+',"from":'+UserJSON+',"text":"biz","business_connection_id":"bc1"}}');
  try
    AssertEquals(Ord(utBusinessMessage), Ord(lUpdate.UpdateType));
    AssertEquals('biz', lUpdate.BusinessMessage.Text);
    AssertEquals('bc1', lUpdate.BusinessMessage.BusinessConnectionID);
  finally
    lUpdate.Free;
  end;
end;

procedure TTestTgTypesParse.ParseMessageReactionUpdate;
const
  ReactionUpdateJSON =
    '{' +
      '"update_id":1000,' +
      '"message_reaction":{' +
        '"chat":{"id":42,"type":"private","first_name":"Test"},' +
        '"message_id":7,' +
        '"user":{"id":99,"is_bot":false,"first_name":"Bob"},' +
        '"date":1700000000,' +
        '"old_reaction":[{"type":"emoji","emoji":"'#$F0#$9F#$91#$8D'"}],' +
        '"new_reaction":[{"type":"custom_emoji","custom_emoji_id":"abc123"}]' +
      '}' +
    '}';
var
  UpdateObj: TTelegramUpdateObj;
  ReactionUpdate: TTelegramMessageReactionUpdated;
begin
  UpdateObj:=UpdateFromString(ReactionUpdateJSON);
  try
    AssertEquals(Ord(utMessageReaction), Ord(UpdateObj.UpdateType));
    ReactionUpdate:=UpdateObj.MessageReaction;
    AssertNotNull('MessageReaction should be assigned', ReactionUpdate);
    AssertEquals(42, ReactionUpdate.Chat.ID);
    AssertEquals(7, ReactionUpdate.MessageID);
    AssertNotNull('MessageReaction user should be assigned', ReactionUpdate.User);
    AssertEquals(99, ReactionUpdate.User.ID);
    AssertEquals(1, ReactionUpdate.OldReactions.Count);
    AssertEquals(Ord(rtReactionTypeEmoji), Ord(ReactionUpdate.OldReactions[0].TypeEnum));
    AssertEquals('emoji byte length', Length(EmojiThumbsUp), Length(ReactionUpdate.OldReactions[0].Emoji));
    AssertEquals($F0, Ord(ReactionUpdate.OldReactions[0].Emoji[1]));
    AssertEquals($9F, Ord(ReactionUpdate.OldReactions[0].Emoji[2]));
    AssertEquals($91, Ord(ReactionUpdate.OldReactions[0].Emoji[3]));
    AssertEquals($8D, Ord(ReactionUpdate.OldReactions[0].Emoji[4]));
    AssertEquals(1, ReactionUpdate.NewReactions.Count);
    AssertEquals(Ord(rtReactionTypeCustomEmoji), Ord(ReactionUpdate.NewReactions[0].TypeEnum));
    AssertEquals('abc123', ReactionUpdate.NewReactions[0].CustomEmojiID);
  finally
    UpdateObj.Free;
  end;
end;

procedure TTestTgTypesParse.ParseMessageReactionCountUpdate;
const
  ReactionCountUpdateJSON =
    '{' +
      '"update_id":1001,' +
      '"message_reaction_count":{' +
        '"chat":{"id":123,"type":"supergroup","title":"Test Group"},' +
        '"message_id":10,' +
        '"date":1700000100,' +
        '"reactions":[{' +
          '"type":{"type":"emoji","emoji":"'#$E2#$9D#$A4#$EF#$B8#$8F'"},' +
          '"total_count":3' +
        '}]' +
      '}' +
    '}';
var
  aUpdateObj: TTelegramUpdateObj;
  aReactionCountUpdate: TTelegramMessageReactionCountUpdated;
begin
  aUpdateObj:=UpdateFromString(ReactionCountUpdateJSON);
  try
    AssertEquals(Ord(utMessageReactionCount), Ord(aUpdateObj.UpdateType));
    aReactionCountUpdate:=aUpdateObj.MessageReactionCount;
    AssertNotNull('MessageReactionCount should be assigned', aReactionCountUpdate);
    AssertEquals(123, aReactionCountUpdate.Chat.ID);
    AssertEquals(10, aReactionCountUpdate.MessageID);
    AssertEquals(1, aReactionCountUpdate.Reactions.Count);
    AssertEquals(3, aReactionCountUpdate.Reactions[0].TotalCount);
    AssertEquals(Ord(rtReactionTypeEmoji), Ord(aReactionCountUpdate.Reactions[0].ReactionType.TypeEnum));
    AssertEquals('emoji byte length', Length(EmojiRedHeart), Length(aReactionCountUpdate.Reactions[0].ReactionType.Emoji));
    AssertEquals($E2, Ord(aReactionCountUpdate.Reactions[0].ReactionType.Emoji[1]));
    AssertEquals($9D, Ord(aReactionCountUpdate.Reactions[0].ReactionType.Emoji[2]));
    AssertEquals($A4, Ord(aReactionCountUpdate.Reactions[0].ReactionType.Emoji[3]));
    AssertEquals($EF, Ord(aReactionCountUpdate.Reactions[0].ReactionType.Emoji[4]));
    AssertEquals($B8, Ord(aReactionCountUpdate.Reactions[0].ReactionType.Emoji[5]));
    AssertEquals($8F, Ord(aReactionCountUpdate.Reactions[0].ReactionType.Emoji[6]));
  finally
    aUpdateObj.Free;
  end;
end;

procedure TTestTgTypesParse.ParseMessageQuote;
const
  MessageWithQuoteJSON =
    '{' +
      '"update_id":1002,' +
      '"message":{' +
        '"message_id":55,' +
        '"date":1700000200,' +
        '"chat":{"id":77,"type":"private","first_name":"Test"},' +
        '"from":{"id":88,"is_bot":false,"first_name":"Alice"},' +
        '"text":"Reply with quote",' +
        '"quote":{' +
          '"position":6,' +
          '"text":"quoted",' +
          '"is_manual":true,' +
          '"entities":[{"type":"bold","offset":0,"length":6}]' +
        '}' +
      '}' +
    '}';
var
  aUpdateObj: TTelegramUpdateObj;
  aMessage: TTelegramMessageObj;
begin
  aUpdateObj:=UpdateFromString(MessageWithQuoteJSON);
  try
    AssertEquals(Ord(utMessage), Ord(aUpdateObj.UpdateType));
    aMessage:=aUpdateObj.Message;
    AssertNotNull('Message should be assigned', aMessage);
    AssertNotNull('Quote should be assigned', aMessage.Quote);
    AssertEquals(6, aMessage.Quote.Position);
    AssertEquals('quoted', aMessage.Quote.Text);
    AssertTrue('Quote.IsManual should be True', aMessage.Quote.IsManual);
    AssertEquals(1, aMessage.Quote.Entities.Count);
    AssertEquals('bold', aMessage.Quote.Entities[0].TypeEntity);
    AssertEquals(0, aMessage.Quote.Entities[0].Offset);
    AssertEquals(6, aMessage.Quote.Entities[0].Length);
  finally
    aUpdateObj.Free;
  end;
end;

procedure TTestTgTypesParse.ParseMessageExternalReply;
const
  MessageWithExternalReplyJSON =
    '{' +
      '"update_id":1003,' +
      '"message":{' +
        '"message_id":56,' +
        '"date":1700000300,' +
        '"chat":{"id":77,"type":"private","first_name":"Test"},' +
        '"from":{"id":88,"is_bot":false,"first_name":"Alice"},' +
        '"text":"Reply to external message",' +
        '"external_reply":{' +
          '"origin":{' +
            '"type":"user",' +
            '"date":1700000290,' +
            '"sender_user":{"id":99,"is_bot":false,"first_name":"Bob"}' +
          '}' +
        '}' +
      '}' +
    '}';
var
  aUpdateObj: TTelegramUpdateObj;
  aMessage: TTelegramMessageObj;
begin
  aUpdateObj:=UpdateFromString(MessageWithExternalReplyJSON);
  try
    AssertEquals(Ord(utMessage), Ord(aUpdateObj.UpdateType));
    aMessage:=aUpdateObj.Message;
    AssertNotNull('Message should be assigned', aMessage);
    AssertNotNull('ExternalReply should be assigned', aMessage.ExternalReply);
    AssertTrue('ExternalReply JSON should contain origin type',
      Pos('"type" : "user"', aMessage.ExternalReply.AsString)>0);
  finally
    aUpdateObj.Free;
  end;
end;

procedure TTestTgTypesParse.ParseWebhookInfo;
var
  lJSONData: TJSONData;
  lWebhookInfo: TTelegramWebhookInfo;
begin
  lJSONData:=JSONFromString('{"url":"https://example.com/hook","has_custom_certificate":false,'+
    '"pending_update_count":3,"last_error_date":1700000123,"last_error_message":"oops",'+
    '"max_connections":40,"allowed_updates":["message","callback_query"]}');
  try
    lWebhookInfo:=TTelegramWebhookInfo.Create(lJSONData as TJSONObject);
    try
      AssertEquals('https://example.com/hook', lWebhookInfo.Url);
      AssertFalse(lWebhookInfo.HasCustomCertificate);
      AssertEquals(3, lWebhookInfo.PendingUpdateCount);
      AssertEquals(Int64(1700000123), lWebhookInfo.LastErrorDate);
      AssertEquals('oops', lWebhookInfo.LastErrorMessage);
      AssertEquals(40, lWebhookInfo.MaxConnections);
      AssertTrue(utMessage in lWebhookInfo.AllowedUpdates);
      AssertTrue(utCallbackQuery in lWebhookInfo.AllowedUpdates);
      AssertFalse(utInlineQuery in lWebhookInfo.AllowedUpdates);
      AssertEquals(Int64(1700000123), DateTimeToUnix(lWebhookInfo.LastErrorDateAsDateTime));
    finally
      lWebhookInfo.Free;
    end;
  finally
    lJSONData.Free;
  end;
end;

procedure TTestTgTypesParse.ParseFileObject;
var
  lJSONData: TJSONData;
  lFile: TTelegramFile;
begin
  lJSONData:=JSONFromString('{"file_id":"fid","file_size":100,"file_path":"photos/a.jpg"}');
  try
    lFile:=TTelegramFile.Create(lJSONData as TJSONObject);
    try
      AssertEquals('fid', lFile.FileID);
      AssertEquals(100, lFile.FileSize);
      AssertEquals('photos/a.jpg', lFile.FilePath);
      AssertEquals('https://api.telegram.org/file/botTOKEN/photos/a.jpg',
        lFile.DownloadLink('TOKEN'));
    finally
      lFile.Free;
    end;
  finally
    lJSONData.Free;
  end;
end;

procedure TTestTgTypesParse.UnknownUpdateType;
var
  lUpdate: TTelegramUpdateObj;
begin
  lUpdate:=UpdateFromString('{"update_id":200,"some_future_update":{"a":1}}');
  try
    AssertEquals(Ord(utUnknown), Ord(lUpdate.UpdateType));
    AssertNull(lUpdate.Message);
    AssertNull(lUpdate.CallbackQuery);
  finally
    lUpdate.Free;
  end;
end;

procedure TTestTgTypesParse.ContentFromMessageText;
var
  lUpdate: TTelegramUpdateObj;
  lText, lMedia: String;
begin
  lUpdate:=UpdateFromString('{"update_id":1,"message":{"message_id":1,"date":1,"chat":'+ChatJSON+
    ',"text":"plain text"}}');
  try
    AssertEquals(Ord(cntText), Ord(lUpdate.Message.ContentFromMessage(lText, lMedia)));
    AssertEquals('plain text', lText);
  finally
    lUpdate.Free;
  end;
end;

procedure TTestTgTypesParse.ContentFromMessagePhoto;
var
  lUpdate: TTelegramUpdateObj;
  lText, lMedia: String;
begin
  lUpdate:=UpdateFromString('{"update_id":2,"message":{"message_id":2,"date":1,"chat":'+ChatJSON+
    ',"caption":"the caption","photo":[{"file_id":"small","width":10,"height":10},'+
    '{"file_id":"big","width":100,"height":100}]}}');
  try
    AssertEquals(Ord(cntPhoto), Ord(lUpdate.Message.ContentFromMessage(lText, lMedia)));
    AssertEquals('the caption', lText); // the caption is used as the text for a photo
    AssertEquals('big', lMedia);        // the largest photo is used
  finally
    lUpdate.Free;
  end;
end;

procedure TTestTgTypesParse.ContentFromMessageVideo;
var
  lUpdate: TTelegramUpdateObj;
  lText, lMedia: String;
begin
  lUpdate:=UpdateFromString('{"update_id":3,"message":{"message_id":3,"date":1,"chat":'+ChatJSON+
    ',"caption":"vcap","video":{"file_id":"vid","width":640,"height":480,"duration":12}}}');
  try
    AssertEquals(Ord(cntVideo), Ord(lUpdate.Message.ContentFromMessage(lText, lMedia)));
    AssertEquals('vcap', lText);
    AssertEquals('vid', lMedia);
  finally
    lUpdate.Free;
  end;
end;

procedure TTestTgTypesParse.ContentFromMessageDocument;
var
  lUpdate: TTelegramUpdateObj;
  lText, lMedia: String;
begin
  lUpdate:=UpdateFromString('{"update_id":4,"message":{"message_id":4,"date":1,"chat":'+ChatJSON+
    ',"caption":"dcap","document":{"file_id":"doc","file_name":"a.pdf","mime_type":"application/pdf"}}}');
  try
    AssertEquals(Ord(cntDocument), Ord(lUpdate.Message.ContentFromMessage(lText, lMedia)));
    AssertEquals('dcap', lText);
    AssertEquals('doc', lMedia);
  finally
    lUpdate.Free;
  end;
end;

procedure TTestTgTypesParse.ContentFromMessageLocation;
var
  lUpdate: TTelegramUpdateObj;
  lText, lMedia: String;
begin
  lUpdate:=UpdateFromString('{"update_id":5,"message":{"message_id":5,"date":1,"chat":'+ChatJSON+
    ',"location":{"latitude":10.5,"longitude":20.5}}}');
  try
    AssertEquals(Ord(cntLocation), Ord(lUpdate.Message.ContentFromMessage(lText, lMedia)));
    AssertEquals(EmptyStr, lMedia);
  finally
    lUpdate.Free;
  end;
end;

procedure TTestTgTypesParse.ContentFromMessageContact;
var
  lUpdate: TTelegramUpdateObj;
  lText, lMedia: String;
begin
  lUpdate:=UpdateFromString('{"update_id":6,"message":{"message_id":6,"date":1,"chat":'+ChatJSON+
    ',"contact":{"phone_number":"+7999","first_name":"Bob","user_id":99}}}');
  try
    AssertEquals(Ord(cntContact), Ord(lUpdate.Message.ContentFromMessage(lText, lMedia)));
    AssertEquals(EmptyStr, lMedia);
  finally
    lUpdate.Free;
  end;
end;

procedure TTestTgTypesParse.AllowedUpdatesToJSONRoundtrip;
var
  lSet: TUpdateSet;
  lJSONArray: TJSONArray;
begin
  lSet:=[utMessage, utCallbackQuery, utMessageReaction];
  lJSONArray:=AllowedUpdatesToJSON(lSet);
  try
    AssertEquals(3, lJSONArray.Count);
    AssertEquals('message', lJSONArray.Strings[0]);
    AssertEquals('callback_query', lJSONArray.Strings[1]);
    AssertEquals('message_reaction', lJSONArray.Strings[2]);
  finally
    lJSONArray.Free;
  end;
end;

procedure TTestTgTypesParse.UpdateObjClone;
var
  lUpdate, lClone: TTelegramUpdateObj;
begin
  lUpdate:=UpdateFromString('{"update_id":300,"message":{"message_id":5,"date":1700000000,'+
    '"chat":'+ChatJSON+',"from":'+UserJSON+',"text":"Hello"}}');
  try
    lClone:=lUpdate.Clone;
    try
      AssertEquals(lUpdate.UpdateId, lClone.UpdateId);
      AssertEquals(Ord(lUpdate.UpdateType), Ord(lClone.UpdateType));
      AssertEquals(lUpdate.Message.Text, lClone.Message.Text);
    finally
      lClone.Free;
    end;
  finally
    lUpdate.Free;
  end;
end;

initialization
  RegisterTest(TTestTgTypesParse);

end.
