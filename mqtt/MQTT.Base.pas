unit MQTT.Base;

interface

uses System.Classes, System.SysUtils, MQTT.Types.Enums, MQTT.Types, MQTT.Types.Impl;

type

  TMQTTStreamEvent = procedure (Sender : TObject; anID : Word; Retry : integer; aStream : TMemoryStream) of object;

  TMQTTConnAckEvent = procedure(Sender: TObject; AConnAck: IMQTTConnAck) of object;
  TMQTTPublishEvent = procedure(Sender: TObject; APublish: IMQTTPublish) of object;
  TMQTTPubAckEvent = procedure(Sender: TObject; APubAck: IMQTTPubAck) of object;


  TMQTTBase = class
  private
    FTxStream: TMemoryStream;
    FRxStream: TMemoryStream;
    FWillFlag: boolean;
    FWillTopic: UTF8String;
    FWillMessage: UTF8String;
    FWillRetain: Boolean;
    FWillQos: TMQTTQOSType;
    FKeepAliveCount: Cardinal;
    FMaxRetries: Word;
    FKeepAlive: Word;
    FRetryTime: Word;
    FOnSend: TMQTTStreamEvent;
    FOnConnAck: TMQTTConnAckEvent;
    FOnPingResp: TNotifyEvent;
    FOnPublish: TMQTTPublishEvent;
    FOnPubAck: TMQTTPubAckEvent;
    procedure SetKeepAlive(const Value: Word);
  protected
    procedure DoConnAck(AConnAck: IMQTTConnAck); virtual;
    procedure DoPublish(APublish: IMQTTPublish); virtual;
    procedure DoPubAck(APubAck: IMQTTPubAck); virtual;
    procedure DoPingResp; virtual;
  public
    constructor Create; virtual;
    destructor Destroy; override;

    procedure SetWill(ATopic, AMessage: UTF8String; AQos: TMQTTQOSType; ARetain: boolean);

    procedure Parse(ABytes: TBytes); overload;

    procedure SendConnect(AClientID, AUsername, APassword : UTF8String; AKeepAlive: Word = 10; AClean: boolean = False);
    procedure SendSubscribe(anID: Word; aTopic: UTF8String; aQOS: TMQTTQOSType; aTopicQOS: TMQTTQOSType);
    procedure SendUnsubscribe(anID: Word; aTopic: UTF8String);
    procedure SendPublish(anID: Word; aTopic: UTF8String; aMessage : AnsiString; aQOS : TMQTTQOSType; aDup : boolean = false; aRetain : boolean = false);
    procedure SendPing;

    property WillTopic: UTF8String read FWillTopic write FWillTopic;
    property WillMessage: UTF8String read FWillMessage write FWillMessage;
    property WillRetain: Boolean read FWillRetain write FWillRetain;
    property WillQos: TMQTTQOSType read FWillQos write FWillQos;

    property KeepAlive : Word read FKeepAlive write SetKeepAlive;
    property RetryTime : Word read FRetryTime write FRetryTime;
    property MaxRetries : Word read FMaxRetries write FMaxRetries;
  published
    property OnSend: TMQTTStreamEvent read FOnSend write FOnSend;

    property OnConnAck: TMQTTConnAckEvent read FOnConnAck write FOnConnAck;
    property OnPublish: TMQTTPublishEvent read FOnPublish write FOnPublish;
    property OnPubAck: TMQTTPubAckEvent read FOnPubAck write FOnPubAck;
    property OnPingResp : TNotifyEvent read FOnPingResp write FOnPingResp;
  end;

  procedure WriteByte(AStream : TStream; AByte: Byte);
  procedure WriteLength(AStream: TStream; ALen: integer);
  procedure WriteStr(AStream : TStream; AStr: UTF8String);
  procedure WriteHdr(AStream : TStream; AMsgType: TMQTTMessageType; ADup: Boolean; AQos: TMQTTQOSType; ARetain: Boolean);

  function ReadByte(AStream: TStream): Byte;
  function ReadLength(AStream: TStream): integer;
  function ReadStr(AStream: TStream): UTF8String;
  function ReadHdr(AStream: TStream; var MsgType: TMQTTMessageType; var Dup: Boolean; var Qos: TMQTTQOSType; var Retain: Boolean): byte;

implementation

uses MQTT.Types.Consts, MQTT.Helpers;

procedure WriteByte(AStream : TStream; AByte: Byte);
begin
  AStream.Write(AByte, 1);
end;

procedure WriteLength (AStream : TStream; ALen: integer);
var
  x : integer;
  dig : byte;
begin
  x := ALen;
  repeat
    dig := x mod 128;
    x := x div 128;
    if (x > 0) then
      dig := dig or $80;
    WriteByte(AStream, dig);
  until (x = 0);
end;

procedure WriteStr(AStream : TStream; AStr: UTF8String);
var
  l: integer;
begin
  l := Length(AStr);
  WriteByte(AStream, l div $100);
  WriteByte (aStream, l mod $100);
  AStream.Write(AStr[1], Length(AStr));
end;

procedure WriteHdr(AStream : TStream; AMsgType: TMQTTMessageType; ADup: Boolean; AQos: TMQTTQOSType; ARetain: Boolean);
begin
  { Фиксированный заголовок:
    bit	   |7 6	5	4	    | |3	     | |2	1	     |  |  0   |
    byte 1 |Message Type| |DUP flag| |QoS level|	|RETAIN| }
  WriteByte(AStream, (Ord(AMsgType) shl 4) + (Ord(ADup) shl 3) + (Ord(AQos) shl 1) + Ord(ARetain));
end;

function ReadByte(AStream: TStream): Byte;
begin
  if aStream.Position = aStream.Size then
    Result := 0
  else
    aStream.Read (Result, 1);
end;

function ReadLength(AStream: TStream): integer;
var
  mult : integer;
  x : byte;
begin
  mult := 0;
  Result := 0;
  repeat
    x := ReadByte (aStream);
    Result := Result + ((x and $7f) * mult);
  until (x and $80) <> 0;
end;

function ReadStr(AStream: TStream): UTF8String;
var
  l: integer;
begin
  l := ReadByte(aStream) * $100 + ReadByte(aStream);
  if aStream.Position + l <= aStream.Size then
  begin
    SetLength(Result, l);
    aStream.Read(Result[1], l);
  end;
end;

function ReadHdr(AStream: TStream; var MsgType: TMQTTMessageType; var Dup: Boolean;
  var Qos: TMQTTQOSType; var Retain: Boolean): byte;
begin
  Result := ReadByte(aStream);
  { Фиксированный заголовок:
    bit	   |7 6	5	4	    | |3	     | |2	1	     |  |  0   |
    byte 1 |Message Type| |DUP flag| |QoS level|	|RETAIN| }
  MsgType := TMQTTMessageType ((Result and $f0) shr 4);
  Dup := (Result and $08) > 0;
  Qos := TMQTTQOSType ((Result and $06) shr 1);
  Retain := (Result and $01) > 0;
end;

{ TMQTTParser }

constructor TMQTTBase.Create;
begin
  inherited;

  FKeepAlive := 10;
  FKeepAliveCount := 0;

  FTxStream:= TMemoryStream.Create;
  FRxStream := TMemoryStream.Create;

  WillTopic := '';
  WillMessage := '';
  FWillFlag := False;
  WillQos := qtAT_LEAST_ONCE;
  WillRetain := False;
end;

destructor TMQTTBase.Destroy;
begin
  FreeAndNil(FTxStream);
  FreeAndNil(FRxStream);

  inherited;
end;

procedure TMQTTBase.DoConnAck(AConnAck: IMQTTConnAck);
begin
  if Assigned(FOnConnAck) then
    FOnConnAck(Self, AConnAck);
end;

procedure TMQTTBase.DoPingResp;
begin
  if Assigned(FOnPingResp) then
    FOnPingResp(Self);
end;

procedure TMQTTBase.DoPubAck(APubAck: IMQTTPubAck);
begin
  if Assigned(FOnPubAck) then
    FOnPubAck(Self, APubAck);
end;

procedure TMQTTBase.DoPublish(APublish: IMQTTPublish);
begin
  if Assigned(FOnPublish) then
    FOnPublish(Self, APublish);
end;

procedure TMQTTBase.Parse(ABytes: TBytes);
var
  MQTTPacket: IMQTTPacket;
begin
  MQTTPacket := TMQTTPacket.Create(Copy(ABytes, 0, MQTT_FRAME_MIN_SIZE));

  case MQTTPacket.MsgType of
//    mtCONNECT:;
    mtCONNACK: DoConnAck(TMQTTConnAck.Create(ABytes));
    mtPUBLISH: DoPublish(TMQTTPublish.Create(ABytes));
    mtPUBACK: DoPubAck(TMQTTPubAck.Create(ABytes));
//    mtPUBREC:;
//    mtPUBREL:;
//    mtPUBCOMP:;
//    mtSUBSCRIBE:;
//    mtSUBACK:;
//    mtUNSUBSCRIBE:;
//    mtUNSUBACK:;
//    mtPINGREQ:;
    mtPINGRESP: DoPingResp;
//    mtDISCONNECT:;
    else
      raise Exception.CreateFmt('Message type "%s" not implemented.', [MQTTPacket.MsgType.ToString]);
  end;
end;

procedure TMQTTBase.SendConnect(AClientID, AUsername, APassword : UTF8String;
  AKeepAlive: Word; AClean: boolean);
const
  VARIABLE_HEADER_LENGTH = 12;
var
  MS: TMemoryStream;
  ConnectFlags: Byte;
begin
  KeepAlive := AKeepAlive;

  FTxStream.Clear;

  WriteHdr(FTxStream, mtCONNECT, False, qtAT_MOST_ONCE, False);

  MS := TMemoryStream.Create;
  try
    { Generate payload }
    WriteStr(MS, AClientID);
    if FWillFlag then
    begin
      WriteStr(MS, WillTopic);
      WriteStr(MS, WillMessage);
    end;
    if Length(AUsername) > 0 then
    begin
      WriteStr(MS, AUsername);
      WriteStr(MS, APassword);
    end;

    WriteLength(FTxStream, VARIABLE_HEADER_LENGTH + MS.Size);  // Fixed header - remaining Length

    { Variable header }
    WriteStr(FTxStream, MQTT_PROTOCOL); // Protocol Name
    WriteByte(FTxStream, MQTT_VERSION); // Protocol level
    ConnectFlags := 0;
    if Length(AUsername) > 0 then
    begin
      ConnectFlags := ConnectFlags or $80;
      ConnectFlags := ConnectFlags or $40;
    end;
    if FWillFlag then
      begin
        ConnectFlags := ConnectFlags or $04;
        if WillRetain then
          ConnectFlags := ConnectFlags or $10;
        ConnectFlags := ConnectFlags or (Ord(WillQos) shl 3);
      end;
    if AClean then
      ConnectFlags := ConnectFlags or $02;

    WriteByte(FTxStream, ConnectFlags);
    WriteByte(FTxStream, AKeepAlive div $100);  // Keep Alive
    WriteByte(FTxStream, AKeepAlive mod $100);
    // payload
    MS.Seek (0, soFromBeginning);
    FTxStream.CopyFrom (MS, MS.Size);
  finally
    FreeAndNil(MS);
  end;

  if Assigned(FOnSend) then
    FOnSend(Self, 0, 0, FTxStream);
end;

procedure TMQTTBase.SendPing;
begin
  FTxStream.Clear;        // dup, qos, retain not used
  WriteHdr(FTxStream, mtPINGREQ, false, qtAT_MOST_ONCE, false);
  WriteLength(FTxStream, 0);
  if Assigned(FOnSend) then
    FOnSend(Self, 0, 0, FTxStream);
end;

procedure TMQTTBase.SendPublish(anID: Word; aTopic: UTF8String;
  aMessage: AnsiString; aQOS: TMQTTQOSType; aDup, aRetain: boolean);
var
  s : TMemoryStream;
begin
  FTxStream.Clear;     // dup qos and retain used
  WriteHdr(FTxStream, mtPUBLISH, aDup, aQos, aRetain);
  s := TMemoryStream.Create;
  WriteStr(s, aTopic);
  if aQos in [qtAT_LEAST_ONCE, qtEXACTLY_ONCE] then
    begin
      WriteByte(s, anID div $100);
      WriteByte(s, anID mod $100);
    end;
  if Length(aMessage) > 0 then s.Write(aMessage[1], Length(aMessage));
  // payload
  s.Seek (0, soFromBeginning);
  WriteLength(FTxStream, s.Size);
  FTxStream.CopyFrom (s, s.Size);
  s.Free;
  if Assigned (FOnSend) then FOnSend (Self, anID, 0, FTxStream);
end;

procedure TMQTTBase.SendSubscribe(anID: Word; aTopic: UTF8String;
  aQOS: TMQTTQOSType; aTopicQOS: TMQTTQOSType);
begin
  FTxStream.Clear;                // qos and dup used
  WriteHdr(FTxStream, mtSUBSCRIBE, false, qtAT_LEAST_ONCE, false);
  WriteLength(FTxStream, 5 + Length(aTopic));
  WriteByte(FTxStream, anID div $100);
  WriteByte(FTxStream, anID mod $100);
  WriteStr(FTxStream, aTopic);
  WriteByte(FTxStream, Ord(aTopicQOS));
  if Assigned(FOnSend) then
    FOnSend(Self, anID, 0, FTxStream);
end;

procedure TMQTTBase.SendUnsubscribe(anID: Word; aTopic: UTF8String);
begin
  FTxStream.Clear;      // qos and dup used
  WriteHdr(FTxStream, mtUNSUBSCRIBE, false, qtAT_LEAST_ONCE, false);
  WriteLength(FTxStream, 4 + Length(aTopic));
  WriteByte(FTxStream, anID div $100);
  WriteByte(FTxStream, anID mod $100);
  WriteStr(FTxStream, aTopic);
  if Assigned(FOnSend) then
    FOnSend(Self, anID, 0, FTxStream);
end;

procedure TMQTTBase.SetKeepAlive(const Value: Word);
begin
  FKeepAlive := Value;
  FKeepAliveCount := Value * 10;
end;

procedure TMQTTBase.SetWill(ATopic, AMessage: UTF8String; AQos: TMQTTQOSType;
  ARetain: boolean);
begin
  WillTopic := ATopic;
  WillMessage := AMessage;
  WillRetain := ARetain;
  WillQos := AQos;
  FWillFlag := (Length(ATopic) > 0) and (Length(AMessage) > 0);
end;

end.
