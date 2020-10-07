unit MQTT.Types.Impl;

interface

uses System.SysUtils, MQTT.Types, MQTT.Types.Enums;

type

(******************************************************************************)

  TMQTTPacket = class(TInterfacedObject, IMQTTPacket)
  private
    FFixedHeaderLen: integer;
    FMsgType: TMQTTMessageType;
    FDUP: boolean;
    FQoS: TMQTTQOSType;
    FRetain: boolean;
    FRemainingLength: UInt32;
  protected
    property FixedHeaderLen: integer read FFixedHeaderLen;

    procedure Parse(ABytes: TBytes); virtual;
  public
    constructor Create(ABytes: TBytes); overload;

    function MsgType: TMQTTMessageType;
    function DUP: boolean;
    function QoS: TMQTTQOSType;
    function Retain: boolean;
    function RemainingLength: UInt32;
  end;

(******************************************************************************)

  TMQTTConnAck = class(TMQTTPacket, IMQTTConnAck)
  private
    FConnectReturnCode: TMQTTConnectReturnCode;
  protected
    procedure Parse(ABytes: TBytes); override;
  public
    function ConnectReturnCode: TMQTTConnectReturnCode;
  end;

(******************************************************************************)

  TMQTTPublish = class(TMQTTPacket, IMQTTPublish)
  private
    FTopicName: string;
    FMessageId: Word;
    FPayload: TBytes;
  protected
    procedure Parse(ABytes: TBytes); override;
  public
    function TopicName: string;
    function MessageId: Word;
    function Payload: TBytes;
    function PayloadStr(AEncoding: TEncoding = nil): string;
  end;

(******************************************************************************)

  TMQTTPubAck = class(TMQTTPacket, IMQTTPubAck)
  private
    FMessageId: Word;
  protected
    procedure Parse(ABytes: TBytes); override;
  public
    function MessageId: Word;
  end;

(******************************************************************************)

implementation

uses MQTT.Types.Consts, MQTT.Helpers;

{ TMQTTPacket }

constructor TMQTTPacket.Create(ABytes: TBytes);
begin
  inherited Create;

  if Length(ABytes) = 0 then
    raise Exception.Create('Invalid control packet.');

  Parse(ABytes);
end;

function TMQTTPacket.DUP: boolean;
begin
  Result := FDUP;
end;

function TMQTTPacket.MsgType: TMQTTMessageType;
begin
  Result := FMsgType;
end;

procedure TMQTTPacket.Parse(ABytes: TBytes);
var
  Mult: Word;
begin
  FMsgType := TMQTTMessageType((ABytes[0] and $F0) shr 4);
  FDUP := (ABytes[0] and $8) <> 0;
  FQoS := TMQTTQOSType((ABytes[0] and $6) shr 1);
  FRetain := (ABytes[0] and 1) <> 0;
  FRemainingLength := 0;
  FFixedHeaderLen := 0;
  Mult := 1;
  repeat
    Inc(FFixedHeaderLen);
    FRemainingLength := FRemainingLength + ((ABytes[FFixedHeaderLen] and $7f) * Mult);
    Mult := Mult * $80;
  until (ABytes[FFixedHeaderLen] and $80) = 0;
end;

function TMQTTPacket.QoS: TMQTTQOSType;
begin
  Result := FQoS;
end;

function TMQTTPacket.RemainingLength: UInt32;
begin
  Result := FRemainingLength;
end;

function TMQTTPacket.Retain: boolean;
begin
  Result := FRetain;
end;

{ TMQTTConnAck }

function TMQTTConnAck.ConnectReturnCode: TMQTTConnectReturnCode;
begin
  Result := FConnectReturnCode;
end;

procedure TMQTTConnAck.Parse(ABytes: TBytes);
begin
  inherited;

  if MsgType <> mtCONNACK then
    raise Exception.CreateFmt('Message type "%s" is not "CONNACK".', [MsgType.ToString]);

  FConnectReturnCode := TMQTTConnectReturnCode(ABytes[3]);  // 4 байт - код возврата подключения
end;

{ TMQTTPublish }

function TMQTTPublish.MessageId: Word;
begin
  Result := FMessageId;
end;

procedure TMQTTPublish.Parse(ABytes: TBytes);
var
  Len: integer;
  Offset: integer;
  Test: string;
begin
  inherited;

  if MsgType <> mtPUBLISH then
    raise Exception.CreateFmt('Message type "%s" is not "PUBLISH".', [MsgType.ToString]);

  // topic name
  Offset := FixedHeaderLen + 1;
  Len := ABytes[Offset] shl 8 + ABytes[Offset + 1];
  Inc(Offset, 2);
  FTopicName := TEncoding.UTF8.GetString(ABytes, Offset, Len);
  Inc(Offset, Len);

  //message id
  FMessageId := 0;
  if (QoS = qtAT_LEAST_ONCE) or (QoS = qtEXACTLY_ONCE) then
  begin
    FMessageId := ABytes[Offset] shl 8 + ABytes[Offset + 1];
    Inc(Offset, 2);
  end;

  //payload
  FPayload := Copy(ABytes, Offset, RemainingLength - (Offset - Len));
end;

function TMQTTPublish.Payload: TBytes;
begin
  Result := FPayload;
end;

function TMQTTPublish.PayloadStr(AEncoding: TEncoding = nil): string;
begin
  if not Assigned(AEncoding) then
    AEncoding := TEncoding.UTF8;

  Result := AEncoding.GetString(FPayload);
end;

function TMQTTPublish.TopicName: string;
begin
  Result := FTopicName;
end;

{ TMQTTPubAck }

function TMQTTPubAck.MessageId: Word;
begin
  Result := FMessageId;
end;

procedure TMQTTPubAck.Parse(ABytes: TBytes);
begin
  inherited;

  if MsgType <> mtPUBACK then
    raise Exception.CreateFmt('Message type "%s" is not "PUBACK".', [MsgType.ToString]);

  FMessageId := ABytes[2] shl 8 + ABytes[3];
end;

end.
