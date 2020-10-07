unit MQTT.Types;

interface

uses MQTT.Types.Enums, System.SysUtils;

type

  IMQTTPacket = interface
    ['{2DCF76E2-D37D-406C-A922-9A26DE97F632}']
    function MsgType: TMQTTMessageType;
    function DUP: boolean;
    function QoS: TMQTTQOSType;
    function Retain: boolean;
    function RemainingLength: UInt32;
  end;

  IMQTTConnAck = interface(IMQTTPacket)
    ['{38793065-0461-473D-9CB6-0268A530AAE6}']
    function ConnectReturnCode: TMQTTConnectReturnCode;
  end;

  IMQTTPublish = interface(IMQTTPacket)
    ['{AF402551-C4AC-474D-A950-E2C9B3E59B3B}']
    function TopicName: string;
    function MessageId: Word;
    function Payload: TBytes;
    function PayloadStr(AEncoding: TEncoding = nil): string;
  end;

  IMQTTPubAck = interface(IMQTTPacket)
    ['{5E2B02CD-959B-4FEB-A09D-4D1E6E0E175F}']
    function MessageId: Word;
  end;

implementation

end.
