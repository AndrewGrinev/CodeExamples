unit MQTT.Helpers;

interface

uses MQTT.Types.Enums, MQTT.Types.Consts;

type

  TMQTTMessageTypeHelper = record helper for TMQTTMessageType
    function ToString: string;
  end;

implementation

{ TMQTTMessageTypeHelper }

function TMQTTMessageTypeHelper.ToString: string;
begin
  Result := MQTT_MESSAGE_TYPE_NAMES[Self];
end;

end.
