unit API.Types;

interface

uses System.SysUtils, System.Classes, skhttpcli, API.Types.Enums, Proxy.Types;

type

(******************************************************************************)

  TVarProc<T> = reference to procedure (var Arg1: T);

(******************************************************************************)

  IMultipartFormData = interface
    ['{DAEB81EB-E71B-42A8-861E-99D09997DBA7}']
    procedure Write(AStream: TStream);
  end;

(******************************************************************************)

  IRequestData = interface
    ['{D35EF429-5EC6-43CC-A344-E16D43E21640}']
    function GetDomain: string;
    procedure SetDomain(const Value: string);
    function GetStoreMultipartForm: TMemoryStream;
    procedure SetStoreMultipartForm(const Value: TMemoryStream);
    function GetStoreHeaders: TStrings;
    function GetStoreUrl: TStrings;
    procedure SetStoreHeaders(const Value: TStrings);
    procedure SetStoreUrl(const Value: TStrings);

    function ClearParams: IRequestData;
    function UrlDataToString: string;

    property Domain: string read GetDomain write SetDomain;

    property StoreMultipartForm: TMemoryStream read GetStoreMultipartForm write SetStoreMultipartForm;
    property StoreUrl: TStrings read GetStoreUrl write SetStoreUrl;
    property StoreHeaders: TStrings read GetStoreHeaders write SetStoreHeaders;
  end;

(******************************************************************************)

  IAPIRequest = interface(IRequestData)
    ['{70926019-C21E-43FC-ABC1-5CAAECCA56D1}']
    function GetMethodUrl: string;
    procedure SetMethodUrl(const Value: string);
    function GetProxy: IProxy;
    procedure SetProxy(const Value: IProxy);
    function GetTimeout: integer;
    procedure SetTimeout(const Value: integer);
    procedure SetHTTPCliMode(const Value: TSKHTTPCliMode);
    function GetHTTPCliMode: TSKHTTPCliMode;
    function GetOnDataReceiveAsString: TFunc<string, string>;
    procedure SetOnDataReceiveAsString(const Value: TFunc<string, string>);
    procedure SetOnDataReceiveAsStream(
      const Value: TFunc<TMemoryStream, TMemoryStream>);
    function GetOnDataReceiveAsStream: TFunc<TMemoryStream, TMemoryStream>;
    function GetOnStaticFill: TProc;
    procedure SetOnStaticFill(const Value: TProc);
    function GetOnDataSend: TVarProc<TMemoryStream>;
    procedure SetOnDataSend(const Value: TVarProc<TMemoryStream>);
    function GetUserAgent: string;
    procedure SetUserAgentProc(const Value: string);
    procedure SetMimeTypeProc(const Value: string);
    function GetMimeType: string;
    procedure SetProtocol(const Value: string);
    function GetProtocol: string;
    function GetCookiesData: TStrings;
    procedure SetCookiesData(const Value: TStrings);
    procedure SetOnFillForURL(const Value: TProc<string>);
    function GetOnFillForURL: TProc<string>;
    procedure SetKeepAlive(const Value: Boolean);
    function GetKeepAlive: Boolean;
    procedure SetKeepAliveTimeout(const Value: integer);
    function GetKeepAliveTimeout: integer;
    procedure SetStoreCookies(const Value: Boolean);
    function GetStoreCookies: Boolean;

    function AddParameter(const AKey: string; const AValue: string;
      const AStoreFormat: TStoreFormat = TStoreFormat.sfFormData; ASkipEmpty: boolean = True): IApiRequest; overload;
    function AddParameter(const AKey: string; const AValue: Int64;
      const AStoreFormat: TStoreFormat = TStoreFormat.sfFormData; ASkipEmpty: boolean = True): IApiRequest; overload;
    function AddParameter(const AKey: string; const AValue: Double;
      const AStoreFormat: TStoreFormat = TStoreFormat.sfFormData; ASkipEmpty: boolean = True): IApiRequest; overload;
    function AddParameter(const AKey: string; const AValue: Boolean;
      const AStoreFormat: TStoreFormat = TStoreFormat.sfFormData; ASkipEmpty: boolean = True): IApiRequest; overload;
    function AddParameter(const AParams: TArray<string>;
      const AStoreFormat: TStoreFormat = TStoreFormat.sfFormData; ASkipEmpty: boolean = True): IAPIRequest; overload;

    function LastHTTPMethod: THTTPMethod;
    function LastRequest: string;
    function ResultCode: integer;
    function ResultString: string;
    function ReceivedHeaders: TStringList;

    function ExecuteAsString(const HTTPMethod: THTTPMethod = THTTPMethod.httpGET): string;
    function ExecuteAsStream(const HTTPMethod: THTTPMethod = THTTPMethod.httpGET): TMemoryStream;

    function SetMethod(const AValue: string): IApiRequest;
    function SetMimeType(const AValue: string): IApiRequest;
    function SetUserAgent(const AValue: string): IApiRequest;

    function ClearCookies: IAPIRequest;
    function AppendCookie(const AName, AValue: string): IAPIRequest;
    function SetCookies(const AValue: string): IAPIRequest; overload;
    function SetCookies(const AValue: TStrings): IAPIRequest; overload;

    property MethodUrl: string read GetMethodUrl write SetMethodUrl;
    property Proxy: IProxy read GetProxy write SetProxy;
    property Timeout: integer read GetTimeout write SetTimeout;
    property UserAgent: string read GetUserAgent write SetUserAgentProc;
    property MimeType: string read GetMimeType write SetMimeTypeProc;
    property Protocol: string read GetProtocol write SetProtocol;
    property HTTPCliMode: TSKHTTPCliMode read GetHTTPCliMode write SetHTTPCliMode;
    property StoreCookies: Boolean read GetStoreCookies write SetStoreCookies;
    property KeepAlive: Boolean read GetKeepAlive write SetKeepAlive;
    property KeepAliveTimeout: integer read GetKeepAliveTimeout write SetKeepAliveTimeout;

    property Cookies: TStrings read GetCookiesData write SetCookiesData;

    property OnDataSend: TVarProc<TMemoryStream> read GetOnDataSend write SetOnDataSend;
    property OnDataReceiveAsString: TFunc<string, string> read GetOnDataReceiveAsString write SetOnDataReceiveAsString;
    property OnDataReceiveAsStream: TFunc<TMemoryStream,TMemoryStream> read GetOnDataReceiveAsStream write SetOnDataReceiveAsStream;
    property OnStaticFill: TProc read GetOnStaticFill write SetOnStaticFill;
    property OnFillForURL: TProc<string> read GetOnFillForURL write SetOnFillForURL;
  end;

(******************************************************************************)

  IAPIRateLimiter = interface
    ['{7B15CCF6-8601-4B6C-B80B-CF82527DA080}']
    function GetLimit: integer;
    function GetPeriod: integer;
    procedure SetLimit(const Value: integer);
    procedure SetPeriod(const Value: integer);
    function GetLastTickCount: Cardinal;
    procedure SetLastTickCount(const Value: Cardinal);

    function TimeoutIsOver: boolean;

    property Period: integer read GetPeriod write SetPeriod;
    property Limit: integer read GetLimit write SetLimit;
  end;

(******************************************************************************)

implementation

end.

