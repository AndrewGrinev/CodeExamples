unit API.Types.Impl;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes,
  API.Types, API.Types.Enums,
  skhttpcli, Generics.Collections, Proxy.Types;

type

(******************************************************************************)

  TMultipartFormData = class(TInterfacedObject, IMultipartFormData)
  private
    FBoundary: string;
    FContentDisposition: string;
    FContentType: string;
    FContentTransferEncoding: string;
    FContent: TMemoryStream;

    procedure WriteLine(AValue: string; AStream: TStream);
  public
    constructor Create(ABoundary, AContentDisposition, AContentType, AContentTransferEncoding: string; AContent: TStream); virtual;
    destructor Destroy; override;

    class function Init(ABoundary, AContentDisposition, AContentType, AContentTransferEncoding: string; AContent: TStream): IMultipartFormData; overload;
    class function Init(ABoundary, AContentDisposition, AContentType, AContentTransferEncoding: string; AContent: String): IMultipartFormData; overload;
    class function Init(ABoundary, AContentDisposition, AContentType, AContentTransferEncoding: string; AContent: Integer): IMultipartFormData; overload;
    class function Init(ABoundary, AContentDisposition, AContentType, AContentTransferEncoding: string; AContent: Int64): IMultipartFormData; overload;

    procedure Write(AStream: TStream);
  end;

(******************************************************************************)

  TRequestData = class(TInterfacedObject, IRequestData)
  private
    FDomain: string;
    FStoreMultipartForm: TMemoryStream;
    FStoreUrl: TStringList;
    FStoreHeaders: TStringList;

    function DataToString(const AData: TStringList): string;

    function GetDomain: string;
    procedure SetDomain(const Value: string);
    function GetStoreMultipartForm: TMemoryStream;
    procedure SetStoreMultipartForm(const Value: TMemoryStream);
    function GetStoreHeaders: TStrings;
    function GetStoreUrl: TStrings;
    procedure SetStoreHeaders(const Value: TStrings);
    procedure SetStoreUrl(const Value: TStrings);
  public
    constructor Create; virtual;
    destructor Destroy; override;

    function ClearParams: IRequestData; virtual;

    function UrlDataToString: string;
    function HeadersToString(const AHeaders: TStrings): string;
  published
    property Domain: string read GetDomain write SetDomain;

    property StoreMultipartForm: TMemoryStream read GetStoreMultipartForm write SetStoreMultipartForm;
    property StoreUrl: TStrings read GetStoreUrl write SetStoreUrl;
    property StoreHeaders: TStrings read GetStoreHeaders write SetStoreHeaders;
  end;

(******************************************************************************)

  TAPIRequest = class(TRequestData, IAPIRequest)
  private
    FReceivedHeaders: TStringList;
    FMethod: string;
    FProxy: IProxy;
    FOnDataReceiveAsString: TFunc<string, string>;
    FOnDataReceiveAsStream: TFunc<TMemoryStream, TMemoryStream>;
    FOnStaticFill: TProc;
    FOnSendData: TVarProc<TMemoryStream>;
    FTimeout: integer;
    FLastRequest: string;
    FResultCode: integer;
    FResultString: string;
    FHTTPCliMode: TSKHTTPCliMode;
    FUserAgent: string;
    FMimeType: string;
    FProtocol: string;
    FCookies: TStrings;
    FOnFillForURL: TProc<string>;
    FLastHTTPMethod: THTTPMethod;
    FKeepAlive: Boolean;
    FKeepAliveTimeout: integer;
    FStoreCookies: Boolean;

    procedure DoStoreParam(const AKey: string; const AValue: string;
      const AStoreFormat: TStoreFormat);

    procedure DoExecute_Post(const AHTTPClient: TSKHTTPCli; const AUrl: string);
    procedure DoExecute_Get(const AHTTPClient: TSKHTTPCli; const AUrl: string);
    procedure DoExecute_Delete(const AHTTPClient: TSKHTTPCli; const AUrl: string);
    procedure DoExecute_Put(const AHTTPClient: TSKHTTPCli; const AUrl: string);

    function GetMethodUrl: string;
    procedure SetMethodUrl(const Value: string);
    function GetOnDataReceiveAsString: TFunc<string, string>;
    procedure SetOnDataReceiveAsString(const Value: TFunc<string, string>);
    function GetOnStaticFill: TProc;
    procedure SetOnStaticFill(const Value: TProc);
    function GetOnDataSend: TVarProc<TMemoryStream>;
    procedure SetOnDataSend(const Value: TVarProc<TMemoryStream>);
    function GetProxy: IProxy;
    procedure SetProxy(const Value: IProxy);
    function GetTimeout: integer;
    procedure SetTimeout(const Value: integer);
    procedure SetHTTPCliMode(const Value: TSKHTTPCliMode);
    function GetHTTPCliMode: TSKHTTPCliMode;
    function GetUserAgent: string;
    procedure SetUserAgentProc(const Value: string);
    function GetMimeType: string;
    procedure SetProtocol(const Value: string);
    function GetProtocol: string;
    function GetCookiesData: TStrings;
    procedure SetCookiesData(const Value: TStrings);
    procedure SetMimeTypeProc(const Value: string);
    procedure SetOnDataReceiveAsStream(
      const Value: TFunc<TMemoryStream, TMemoryStream>);
    function GetOnDataReceiveAsStream: TFunc<TMemoryStream, TMemoryStream>;
    procedure SetOnFillForURL(const Value: TProc<string>);
    function GetOnFillForURL: TProc<string>;
    procedure SetKeepAlive(const Value: Boolean);
    function GetKeepAlive: Boolean;
    procedure SetKeepAliveTimeout(const Value: integer);
    function GetKeepAliveTimeout: integer;
    procedure SetStoreCookies(const Value: Boolean);
    function GetStoreCookies: Boolean;
  public
    constructor Create; override;
    destructor Destroy; override;

    function ExecuteAsString(const HTTPMethod: THTTPMethod = THTTPMethod.httpGET): string;
    function ExecuteAsStream(const HTTPMethod: THTTPMethod = THTTPMethod.httpGET): TMemoryStream;

    function ClearParams: IApiRequest; reintroduce;

    procedure DoStaticFill;
    procedure DoFillForURL(const AURL: string);

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

    function SetMethod(const AValue: string): IApiRequest;
    function SetMimeType(const AValue: string): IApiRequest;
    function SetUserAgent(const AValue: string): IApiRequest;

    function ClearCookies: IAPIRequest;
    function AppendCookie(const AName, AValue: string): IAPIRequest;
    function SetCookies(const AValue: string): IAPIRequest; overload;
    function SetCookies(const AValue: TStrings): IAPIRequest; overload;
  published
    property MethodUrl: string read GetMethodUrl write SetMethodUrl;
    property Proxy: IProxy read GetProxy write SetProxy;
    property Timeout: integer read GetTimeout write SetTimeout;  // HTTP Timeout
    property UserAgent: string read GetUserAgent write SetUserAgentProc;
    property MimeType: string read GetMimeType write SetMimeTypeProc;
    property Protocol: string read GetProtocol write SetProtocol;
    property HTTPCliMode: TSKHTTPCliMode read GetHTTPCliMode write SetHTTPCliMode;
    property StoreCookies: Boolean read GetStoreCookies write SetStoreCookies;

    { keep alive }
    property KeepAlive: Boolean read GetKeepAlive write SetKeepAlive;
    property KeepAliveTimeout: integer read GetKeepAliveTimeout write SetKeepAliveTimeout;

    property Cookies: TStrings read GetCookiesData write SetCookiesData;

    property OnStaticFill: TProc read GetOnStaticFill write SetOnStaticFill;
    property OnFillForURL: TProc<string> read GetOnFillForURL write SetOnFillForURL;
    property OnDataSend: TVarProc<TMemoryStream> read GetOnDataSend write SetOnDataSend;
    property OnDataReceiveAsString: TFunc<string, string> read GetOnDataReceiveAsString write SetOnDataReceiveAsString;
    property OnDataReceiveAsStream: TFunc<TMemoryStream,TMemoryStream> read GetOnDataReceiveAsStream write SetOnDataReceiveAsStream;
  end;

(******************************************************************************)

  TAPIRateLimiter = class(TInterfacedObject, IAPIRateLimiter)
  private
    FPeriod: integer;
    FLimit: integer;
    FLastRequestTickCount: Cardinal;

    function GetLimit: integer;
    function GetPeriod: integer;
    procedure SetLimit(const Value: integer);
    procedure SetPeriod(const Value: integer);
    function GetLastTickCount: Cardinal;
    procedure SetLastTickCount(const Value: Cardinal);
  public
    constructor Create; virtual;

    function TimeoutIsOver: boolean; virtual;

    procedure Lock; inline;
    procedure Unlock; inline;
  published
    property Period: integer read GetPeriod write SetPeriod;
    property Limit: integer read GetLimit write SetLimit;
    property LastTickCount: Cardinal read GetLastTickCount write SetLastTickCount;
  end;

(******************************************************************************)

implementation

uses 
  StrUtils.Utils, System.Math, API.Utils, Proxy.Types.Impl, synacode;

{ TRequestData }

function TRequestData.ClearParams: IRequestData;
begin
  FStoreMultipartForm.Clear;
  FStoreUrl.Clear;
  FStoreHeaders.Clear;
end;

constructor TRequestData.Create;
begin
  inherited;

  FStoreMultipartForm := TMemoryStream.Create;
  FStoreUrl := TStringList.Create;
  FStoreHeaders := TStringList.Create;
end;

function TRequestData.DataToString(const AData: TStringList): string;
var OldDelimiter: Char;
begin
  Result := EmptyStr;

  if not Assigned(AData) then Exit;

  OldDelimiter := AData.Delimiter;
  try
    AData.Delimiter := '&';

    Result := AData.DelimitedText;
  finally
    AData.Delimiter := OldDelimiter;
  end;
end;

destructor TRequestData.Destroy;
begin
  FreeAndNil(FStoreMultipartForm);
  FreeAndNil(FStoreUrl);
  FreeAndNil(FStoreHeaders);

  inherited;
end;

function TRequestData.GetDomain: string;
begin
  Result := FDomain;
end;

function TRequestData.GetStoreHeaders: TStrings;
begin
  Result := FStoreHeaders;
end;

function TRequestData.GetStoreMultipartForm: TMemoryStream;
begin
  Result := FStoreMultipartForm;
end;

function TRequestData.GetStoreUrl: TStrings;
begin
  Result := FStoreUrl;
end;

function TRequestData.HeadersToString(const AHeaders: TStrings): string;
begin
  Result := AHeaders.Text;
end;

procedure TRequestData.SetDomain(const Value: string);
begin
  FDomain := Value;
end;

procedure TRequestData.SetStoreHeaders(const Value: TStrings);
begin
  FStoreHeaders.Assign(Value);
end;

procedure TRequestData.SetStoreMultipartForm(const Value: TMemoryStream);
begin
  FStoreMultipartForm.Size := 0;
  FStoreMultipartForm.CopyFrom(Value, Value.Size);
end;

procedure TRequestData.SetStoreUrl(const Value: TStrings);
begin
  FStoreUrl.Assign(Value);
end;

function TRequestData.UrlDataToString: string;
begin
  Result := DataToString(FStoreUrl);
end;

{ TAPIRequest }

function TAPIRequest.AddParameter(const AKey: string; const AValue: Int64;
  const AStoreFormat: TStoreFormat; ASkipEmpty: boolean): IApiRequest;
begin
  if not(ASkipEmpty and (AValue = 0)) then
    AddParameter(AKey, IntToStr(AValue), AStoreFormat);
  Result := Self;
end;

function TAPIRequest.AddParameter(const AKey, AValue: string;
  const AStoreFormat: TStoreFormat; ASkipEmpty: boolean): IApiRequest;
begin
  if not(ASkipEmpty and AValue.IsEmpty) then
    DoStoreParam(AKey, AValue, AStoreFormat);
  Result := Self;
end;

function TAPIRequest.AddParameter(const AKey: string; const AValue: Boolean;
  const AStoreFormat: TStoreFormat; ASkipEmpty: boolean): IApiRequest;
const Values : array [boolean] of string = ( '0', '1' );
begin
  if not(ASkipEmpty and not AValue) then
    AddParameter(AKey, Values[AValue], AStoreFormat);
  Result := Self;
end;

function TAPIRequest.AppendCookie(const AName, AValue: string): IAPIRequest;
begin
  FCookies.Add(Format('%s=%s', [AName, AValue]));
  Result := Self;
end;

function TAPIRequest.ClearCookies: IAPIRequest;
begin
  FCookies.Clear;
  Result := Self;
end;

function TAPIRequest.ClearParams: IApiRequest;
begin
  inherited ClearParams;
  Result := Self;
end;

constructor TAPIRequest.Create;
begin
  inherited;

  FCookies := TStringList.Create;
  FReceivedHeaders := TStringList.Create;

  FProxy := TProxy.Create;
  FTimeout := 30;
  FHTTPCliMode := skmIcs;
  FResultCode := 0;
  FResultString := '';
  FProtocol := '1.0';
  FUserAgent := 'Mozilla/4.0 (compatible; Synapse)';
  FMimeType := 'text/html';
end;

destructor TAPIRequest.Destroy;
begin
  FreeAndNil(FCookies);
  FreeAndNil(FReceivedHeaders);

  inherited;
end;

procedure TAPIRequest.DoExecute_Delete(const AHTTPClient: TSKHTTPCli; const AUrl: string);
begin
  AHTTPClient.HTTPMethod('DELETE', AUrl);
end;

procedure TAPIRequest.DoExecute_Get(const AHTTPClient: TSKHTTPCli; const AUrl: string);
begin
  AHTTPClient.HTTPMethod('GET', AUrl);
end;

procedure TAPIRequest.DoExecute_Post(const AHTTPClient: TSKHTTPCli; const AUrl: string);
begin
  AHTTPClient.HTTPMethod('POST', AUrl);
end;

procedure TAPIRequest.DoExecute_Put(const AHTTPClient: TSKHTTPCli; const AUrl: string);
begin
  AHTTPClient.HTTPMethod('PUT', AUrl);
end;

procedure TAPIRequest.DoFillForURL(const AURL: string);
begin
  if Assigned(FOnFillForURL) then
    FOnFillForURL(AURL);
end;

procedure TAPIRequest.DoStaticFill;
begin
  if Assigned(FOnStaticFill) then
    FOnStaticFill;
end;

procedure TAPIRequest.DoStoreParam(const AKey, AValue: string;
  const AStoreFormat: TStoreFormat);
var
  Bytes: TBytes;
  Split: TArray<string>;
  i: Integer;
begin
  case AStoreFormat of
    sfFormData:
    begin
      if AKey.IsEmpty then
      begin
        Bytes := TEncoding.UTF8.GetBytes(AValue);
      end
      else
      begin
        if StoreMultipartForm.Size = 0 then
          Bytes := TEncoding.UTF8.GetBytes(Format('%s=%s', [AKey, AValue]))
        else
          Bytes := TEncoding.UTF8.GetBytes(Format('&%s=%s', [AKey, AValue]))
      end;

      StoreMultipartForm.Seek(0, soFromEnd);
      StoreMultipartForm.WriteData(Bytes, Length(Bytes) * SizeOf(Bytes[0]));
    end;
    sfUrlData:
    begin
      if AKey.IsEmpty then
      begin
        Split := AValue.Split(['&']);
        for i := 0 to Length(Split) - 1 do
          StoreUrl.Values[SeparateLeft(Split[i], '=')] := EncodeURL(AnsiToUtf8(SeparateRight(Split[i], '=')))
      end
      else
        StoreUrl.Values[AKey] := EncodeTriplet(AnsiToUtf8(StringReplace(AValue, ' ', '+', [rfReplaceAll])), '%', URLSpecialChar + [';', '/', '=', '?']);
    end;
    sfHeader: StoreHeaders.Add(Format('%s: %s', [AKey, AValue]));
  end;
end;

function TAPIRequest.ExecuteAsStream(
  const HTTPMethod: THTTPMethod): TMemoryStream;
var
  HTTPClient: TSKHTTPCli;
  LinkToStoreMultipartForm: TMemoryStream;
  MS: TMemoryStream;
begin
  TMonitor.Enter(Self);
  try
    Result := nil;
    FLastHTTPMethod := HTTPMethod;

    DoStaticFill;
    try
      DoFillForURL(string.Join('/', [Domain, MethodUrl]));

      if StoreUrl.Count > 0 then
        FLastRequest := SeparatorCombine('/', [Domain, MethodUrl]) + '?' + string.Join('&', StoreUrl.ToStringArray)
      else
        FLastRequest := SeparatorCombine('/', [Domain, MethodUrl]);

      HTTPClient := TSKHTTPCli.Create;
      try
        HTTPClient.Mode := HTTPCliMode;
        HTTPClient.SetProxy(Proxy);
        HTTPClient.Timeout := Timeout;
        HTTPClient.UserAgent := UserAgent;
        HTTPClient.MimeType := MimeType;
        HTTPClient.Protocol := Protocol;
        HTTPClient.KeepAlive := KeepAlive;
        HTTPClient.KeepAliveTimeout := KeepAliveTimeout;
        HTTPClient.Headers.Clear;
        HTTPClient.Headers.Assign(StoreHeaders);
        HTTPClient.Cookies.Assign(Cookies);
        HTTPClient.StoreCookies := StoreCookies;

        if Assigned(FOnSendData) then
        begin
          LinkToStoreMultipartForm := StoreMultipartForm;
          FOnSendData(LinkToStoreMultipartForm);
        end;
        HTTPClient.Document.LoadFromStream(StoreMultipartForm);

        case HTTPMethod of
          httpGET:    DoExecute_Get(HttpClient, FLastRequest);
          httpPOST:   DoExecute_Post(HttpClient, FLastRequest);
          httpDELETE: DoExecute_Delete(HttpClient, FLastRequest);
          httpPUT:    DoExecute_Put(HttpClient, FLastRequest);
        end;

        FResultCode := HTTPClient.ResultCode;
        FResultString := HTTPClient.ResultString;
        Cookies := HTTPClient.Cookies;
        FReceivedHeaders.Assign(HTTPClient.Headers);


        MS := TMemoryStream.Create;
        try
        if Assigned(OnDataReceiveAsStream) then
          MS.CopyFrom(OnDataReceiveAsStream(HTTPClient.Document), -1)
        else
          MS.CopyFrom(HTTPClient.Document, -1);
        except
          FreeAndNil(MS);
          raise
        end;

        Result := MS;
      finally
        FreeAndNil(HTTPClient);
      end;
    finally
      ClearParams;
    end;
  finally
    TMonitor.Exit(Self);
  end;
end;

function TAPIRequest.ExecuteAsString(const HTTPMethod: THTTPMethod): string;
var
  HTTPClient: TSKHTTPCli;
  LinkToStoreMultipartForm: TMemoryStream;
begin
  TMonitor.Enter(Self);
  try
    FLastHTTPMethod := HTTPMethod;

    DoStaticFill;
    try
      DoFillForURL(string.Join('/', [Domain, MethodUrl]));

      if StoreUrl.Count > 0 then
        FLastRequest := SeparatorCombine('/', [Domain, MethodUrl]) + '?' + string.Join('&', StoreUrl.ToStringArray)
      else
        FLastRequest := SeparatorCombine('/', [Domain, MethodUrl]);

      HTTPClient := TSKHTTPCli.Create;
      try
        HTTPClient.Mode := HTTPCliMode;
        HTTPClient.SetProxy(Proxy);
        HTTPClient.Timeout := Timeout;
        HTTPClient.UserAgent := UserAgent;
        HTTPClient.MimeType := MimeType;
        HTTPClient.Protocol := Protocol;
        HTTPClient.KeepAlive := KeepAlive;
        HTTPClient.KeepAliveTimeout := KeepAliveTimeout;
        HTTPClient.Headers.Clear;
        HTTPClient.Headers.Assign(StoreHeaders);
        HTTPClient.Cookies.Assign(Cookies);
        HTTPClient.StoreCookies := StoreCookies;

        if Assigned(FOnSendData) then
        begin
          LinkToStoreMultipartForm := StoreMultipartForm;
          FOnSendData(LinkToStoreMultipartForm);
        end;
        HTTPClient.Document.LoadFromStream(StoreMultipartForm);

        case HTTPMethod of
          httpGET:    DoExecute_Get(HttpClient, FLastRequest);
          httpPOST:   DoExecute_Post(HttpClient, FLastRequest);
          httpDELETE: DoExecute_Delete(HttpClient, FLastRequest);
          httpPUT:    DoExecute_Put(HttpClient, FLastRequest);
        end;

        Result := HTTPClient.DocumentStr;

        FReceivedHeaders.Assign(HTTPClient.Headers);
        FResultCode := HTTPClient.ResultCode;
        FResultString := HTTPClient.ResultString;
        Cookies := HTTPClient.Cookies;
      finally
        FreeAndNil(HTTPClient);
      end;

      if Assigned(OnDataReceiveAsString) then
        Result := OnDataReceiveAsString(Result);
    finally
      ClearParams;
    end;
  finally
    TMonitor.Exit(Self);
  end;
end;

function TAPIRequest.GetCookiesData: TStrings;
begin
  Result := FCookies;
end;

function TAPIRequest.GetHTTPCliMode: TSKHTTPCliMode;
begin
  Result := FHTTPCliMode;
end;

function TAPIRequest.GetKeepAlive: Boolean;
begin
  Result := FKeepAlive;
end;

function TAPIRequest.GetKeepAliveTimeout: integer;
begin
  Result := FKeepAliveTimeout;
end;

function TAPIRequest.GetMethodUrl: string;
begin
  Result := FMethod;
end;

function TAPIRequest.GetMimeType: string;
begin
  Result := FMimeType;
end;

function TAPIRequest.GetOnDataReceiveAsStream: TFunc<TMemoryStream, TMemoryStream>;
begin
  Result := FOnDataReceiveAsStream;
end;

function TAPIRequest.GetOnDataReceiveAsString: TFunc<string, string>;
begin
  Result := FOnDataReceiveAsString;
end;

function TAPIRequest.GetOnDataSend: TVarProc<TMemoryStream>;
begin
  Result := FOnSendData;
end;

function TAPIRequest.GetOnFillForURL: TProc<string>;
begin
  Result := FOnFillForURL;
end;

function TAPIRequest.GetOnStaticFill: TProc;
begin
  Result := FOnStaticFill;
end;

function TAPIRequest.GetProtocol: string;
begin
  Result := FProtocol;
end;

function TAPIRequest.GetProxy: IProxy;
begin
  Result := FProxy;
end;

function TAPIRequest.GetStoreCookies: Boolean;
begin
  Result := FStoreCookies;
end;

function TAPIRequest.GetTimeout: integer;
begin
  Result := FTimeout;
end;

function TAPIRequest.GetUserAgent: string;
begin
  Result := FUserAgent;
end;

function TAPIRequest.LastHTTPMethod: THTTPMethod;
begin
  Result := FLastHTTPMethod;
end;

function TAPIRequest.LastRequest: string;
begin
  Result := FLastRequest;
end;

function TAPIRequest.ReceivedHeaders: TStringList;
begin
  Result := FReceivedHeaders;
end;

function TAPIRequest.ResultCode: integer;
begin
  Result := FResultCode;
end;

function TAPIRequest.ResultString: string;
begin
  Result := FResultString;
end;

function TAPIRequest.SetCookies(const AValue: TStrings): IAPIRequest;
var
  OldDelimiter: Char;
  OldQuoteChar: Char;
begin
  OldDelimiter := AValue.Delimiter;
  OldQuoteChar := AValue.QuoteChar;
  AValue.Delimiter := ';';
  AValue.QuoteChar := '"';
  try
    SetCookies(AValue.Text);
    Result := Self;
  finally
    AValue.Delimiter := OldDelimiter;
    AValue.QuoteChar := OldQuoteChar;
  end;
end;

function TAPIRequest.SetCookies(const AValue: string): IAPIRequest;
begin
  FCookies.Clear;
  FCookies.Delimiter := ';';
  FCookies.QuoteChar := '"';
  FCookies.Text := AValue;
  Result := Self;
end;

procedure TAPIRequest.SetCookiesData(const Value: TStrings);
begin
  FCookies.Assign(Value);
end;

procedure TAPIRequest.SetHTTPCliMode(const Value: TSKHTTPCliMode);
begin
  FHTTPCliMode := Value;
end;

procedure TAPIRequest.SetKeepAlive(const Value: Boolean);
begin
  FKeepAlive := Value;
end;

procedure TAPIRequest.SetKeepAliveTimeout(const Value: integer);
begin
  FKeepAliveTimeout := Value;
end;

function TAPIRequest.SetMethod(const AValue: string): IApiRequest;
begin
  MethodUrl := AValue;
  Result := Self;
end;

procedure TAPIRequest.SetMethodUrl(const Value: string);
begin
  FMethod := Value;
end;

function TAPIRequest.SetMimeType(const AValue: string): IApiRequest;
begin
  MimeType := AValue;
  Result := Self;
end;

procedure TAPIRequest.SetMimeTypeProc(const Value: string);
begin
  FMimeType := Value;
end;

procedure TAPIRequest.SetOnDataReceiveAsStream(
  const Value: TFunc<TMemoryStream, TMemoryStream>);
begin
  FOnDataReceiveAsStream := Value;
end;

procedure TAPIRequest.SetOnDataReceiveAsString(const Value: TFunc<string, string>);
begin
  FOnDataReceiveAsString := Value;
end;

procedure TAPIRequest.SetOnDataSend(const Value: TVarProc<TMemoryStream>);
begin
  FOnSendData := Value;
end;

procedure TAPIRequest.SetOnFillForURL(const Value: TProc<string>);
begin
  FOnFillForURL := Value;
end;

procedure TAPIRequest.SetOnStaticFill(const Value: TProc);
begin
  FOnStaticFill := Value;
end;

procedure TAPIRequest.SetProtocol(const Value: string);
begin
  FProtocol := Value;
end;

procedure TAPIRequest.SetProxy(const Value: IProxy);
begin
  FProxy := Value;
end;

procedure TAPIRequest.SetStoreCookies(const Value: Boolean);
begin
  FStoreCookies := Value;
end;

procedure TAPIRequest.SetTimeout(const Value: integer);
begin
  FTimeout := Value;
end;

function TAPIRequest.SetUserAgent(const AValue: string): IApiRequest;
begin
  UserAgent := AValue;
  Result := Self;
end;

procedure TAPIRequest.SetUserAgentProc(const Value: string);
begin
  FUserAgent := Value;
end;

function TAPIRequest.AddParameter(const AKey: string; const AValue: Double;
  const AStoreFormat: TStoreFormat; ASkipEmpty: boolean): IApiRequest;
begin
  if not(ASkipEmpty and (AValue = 0)) then
    AddParameter(AKey, FloatToStr(AValue), AStoreFormat);
  Result := Self;
end;

function TAPIRequest.AddParameter(const AParams: TArray<string>;
  const AStoreFormat: TStoreFormat; ASkipEmpty: boolean): IAPIRequest;
var
  Param: string;
  Key, Value: string;
begin
  for Param in AParams do
  begin
    Key := SeparateLeft(Param, '=');
    Value := SeparateRight(Param, '=');
    if not(ASkipEmpty and Value.IsEmpty) then
      DoStoreParam(Key, Value, AStoreFormat);
    Result := Self;
  end;
end;

{ TAPIRateLimiter }

constructor TAPIRateLimiter.Create;
begin
  inherited Create;

  { Default value 6 requests per 1 second }
  FLimit := 6;
  FPeriod := 1000;
  FLastRequestTickCount := 0;
end;

function TAPIRateLimiter.GetLastTickCount: Cardinal;
begin
  Lock;
  try
    Result := FLastRequestTickCount;
  finally
    Unlock;
  end;
end;

function TAPIRateLimiter.GetLimit: integer;
begin
  Result := FLimit;
end;

function TAPIRateLimiter.GetPeriod: integer;
begin
  Result := FPeriod;
end;

procedure TAPIRateLimiter.Lock;
begin
  TMonitor.Enter(Self);
end;

procedure TAPIRateLimiter.SetLastTickCount(const Value: Cardinal);
begin
  Lock;
  try
    FLastRequestTickCount := Value;
  finally
    Unlock;
  end;
end;

procedure TAPIRateLimiter.SetLimit(const Value: integer);
begin
  FLimit := Value;
end;

procedure TAPIRateLimiter.SetPeriod(const Value: integer);
begin
  FPeriod := Value;
end;

function TAPIRateLimiter.TimeoutIsOver: boolean;
begin
  Lock;
  try
    Result := (GetTickCount - LastTickCount) >= (Ceil(Period / Limit));
    if Result then
      LastTickCount := GetTickCount;
  finally
    Unlock;
  end;
end;

procedure TAPIRateLimiter.Unlock;
begin
  TMonitor.Exit(Self);
end;

{ TMultipartFormData }

constructor TMultipartFormData.Create(ABoundary, AContentDisposition,
  AContentType, AContentTransferEncoding: string; AContent: TStream);
begin
  inherited Create;

  FContent := TMemoryStream.Create;

  FBoundary := ABoundary;
  FContentDisposition := AContentDisposition;
  FContentType := AContentType;
  FContentTransferEncoding := AContentTransferEncoding;
  FContent.CopyFrom(AContent, -1);
end;

destructor TMultipartFormData.Destroy;
begin
  FreeAndNil(FContent);

  inherited;
end;

class function TMultipartFormData.Init(ABoundary, AContentDisposition,
  AContentType, AContentTransferEncoding: string;
  AContent: Int64): IMultipartFormData;
begin
  Result := Init(ABoundary, AContentDisposition, AContentType, AContentTransferEncoding, IntToStr(AContent));
end;

class function TMultipartFormData.Init(ABoundary, AContentDisposition,
  AContentType, AContentTransferEncoding: string;
  AContent: Integer): IMultipartFormData;
begin
  Result := Init(ABoundary, AContentDisposition, AContentType, AContentTransferEncoding, IntToStr(AContent));
end;

class function TMultipartFormData.Init(ABoundary, AContentDisposition,
  AContentType, AContentTransferEncoding, AContent: String): IMultipartFormData;
var
  MS: TMemoryStream;
  Buffer: TBytes;
begin
  MS := TMemoryStream.Create;
  try
    Buffer := TEncoding.UTF8.GetBytes(AContent);
    MS.WriteData(Buffer, Length(Buffer));

    Result := Init(ABoundary, AContentDisposition, AContentType, AContentTransferEncoding, MS);
  finally
    FreeAndNil(MS);
  end;
end;

class function TMultipartFormData.Init(ABoundary, AContentDisposition,
  AContentType, AContentTransferEncoding: string;
  AContent: TStream): IMultipartFormData;
begin
  Result := TMultipartFormData.Create(ABoundary, AContentDisposition, AContentType, AContentTransferEncoding, AContent);
end;

procedure TMultipartFormData.Write(AStream: TStream);
begin
  WriteLine(Format('--%s', [FBoundary]), AStream);
  WriteLine(Format('Content-Disposition: %s', [FContentDisposition]), AStream);
  WriteLine(Format('Content-Type: %s', [FContentType]), AStream);
  WriteLine(Format('Content-Length: %d', [FContent.Size]), AStream);
  WriteLine(Format('Content-Transfer-Encoding: %s', [FContentTransferEncoding]), AStream);
  WriteLine(EmptyStr, AStream);
  AStream.CopyFrom(FContent, -1);
  WriteLine(EmptyStr, AStream);
end;

procedure TMultipartFormData.WriteLine(AValue: string; AStream: TStream);
var
  Bytes: TBytes;
begin
  Bytes := TEncoding.UTF8.GetBytes(AValue + sLineBreak);
  AStream.Write(Bytes, Length(Bytes));
end;

end.
