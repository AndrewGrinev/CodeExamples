unit MQTT.Types.Enums;

interface

type
  TMQTTMessageType =
  (
    mtReserved0,	  //  0	Reserved
    mtCONNECT,      //	1	Client request to connect to Broker
    mtCONNACK,      //	2	Connect Acknowledgment
    mtPUBLISH,      //	3	Publish message
    mtPUBACK,       //	4	Publish Acknowledgment
    mtPUBREC,       //	5	Publish Received (assured delivery part 1)
    mtPUBREL,       //	6	Publish Release (assured delivery part 2)
    mtPUBCOMP,      //	7	Publish Complete (assured delivery part 3)
    mtSUBSCRIBE,    //	8	Client Subscribe request
    mtSUBACK,       //	9	Subscribe Acknowledgment
    mtUNSUBSCRIBE,  // 10	Client Unsubscribe request
    mtUNSUBACK,     // 11	Unsubscribe Acknowledgment
    mtPINGREQ,      // 12	PING Request
    mtPINGRESP,     // 13	PING Response
    mtDISCONNECT,   // 14	Client is Disconnecting
    mtReserved15    // 15
  );

  TMQTTQOSType =
  (
    qtAT_MOST_ONCE,   //  0 At most once Fire and Forget        <=1
    qtAT_LEAST_ONCE,  //  1 At least once Acknowledged delivery >=1
    qtEXACTLY_ONCE,   //  2 Exactly once Assured delivery       =1
    qtReserved3	      //  3	Reserved
  );

  TMQTTConnectReturnCode =
  (
    crcConnectionAccepted,          // 0 Соединение принято
    crcUnacceptableProtocolVersion, // 1 Сервер не поддерживает уровень протокола MQTT, запрошенный клиентом
    crcIdentifierRejected,          // 2 Идентификатор клиента не разрешен сервером
    crcServerUnavailable,           // 3 Служба MQTT недоступна
    crcBadUserNameOrPassword,       // 4 Неправильное имя пользователя или пароль
    crcNotAuthorized                // 5 Клиент не авторизован для подключения
  );

  TMQTTRxState = (
    rsHdr,    // Fixed header
    rsLen,    // Remaining Length
    rsVarHdr, // Variable header
    rsPayload // Payload
  );

implementation

end.
