unit MQTT.Types.Consts;

interface

uses MQTT.Types.Enums;

const
  MQTT_FRAME_MIN_SIZE = 2;
  MQTT_PROTOCOL   = 'MQIsdp';
  MQTT_VERSION    = 3;

  MQTT_MESSAGE_TYPE_NAMES: array[TMQTTMessageType] of string =
  (
    'Reserved0',
    'CONNECT',
    'CONNACK',
    'PUBLISH',
    'PUBACK',
    'PUBREC',
    'PUBREL',
    'PUBCOMP',
    'SUBSCRIBE',
    'SUBACK',
    'UNSUBSCRIBE',
    'UNSUBACK',
    'PINGREQ',
    'PINGRESP',
    'DISCONNECT',
    'Reserved15'
  );

implementation

end.
