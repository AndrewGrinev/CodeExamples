unit API.Base;

interface

uses
  System.Classes, System.SysUtils, jsonutils, API.Types, API.Exceptions, Proxy.Types,
  {$IF CompilerVersion >= 27}System.JSON{$ELSE}Data.DBXJSON{$IFEND}, skhttpcli;

type
(******************************************************************************)

  TBaseJSONClass = class of TBaseJSON;

  TBaseJSON = class(TInterfacedObject)
  private
    FJSON: TJSONObject;
    FJSONRaw: string;
  protected

  public
    constructor Create(const AJson: string = '{}'); overload;
    constructor Create(const AJson: TJSONObject); overload;
    destructor Destroy; override;

    function ToStringValue(const AKey: string): string;
    function ToBooleanValue(const AKey: string): boolean;
    function ToInt64Value(const AKey: string): Int64;
    function ToUInt64Value(const AKey: string): UInt64;
    function ToIntegerValue(const AKey: string): integer;
    function ToDoubleValue(const AKey: string): Double;
    function ToDateTime(const AKey: string): TDateTime;
    function ToClass<T: class, constructor>(const AKey: string): T;
    function ToArray<TI: IInterface>(TgClass: TBaseJsonClass; const AKey: string): TArray<TI>;
    function ToStringArray(const AKey: string): TArray<string>;
    function ToIntArray(const AKey: string): TArray<integer>;
    function ToInt64Array(const AKey: string): TArray<Int64>;

    function ValueExists(const AKey: string): boolean;

    function IsStringValue(const AKey: string): boolean;
    function IsBooleanValue(const AKey: string): boolean;
    function IsNumberValue(const AKey: string): boolean;
    function IsObjectValue(const AKey: string): boolean;
    function IsArrayValue(const AKey: string): boolean;

    procedure Write(const AKey: string; const AValue: TJSONValue); overload;
    procedure Write(const AKey, AValue: string); overload;
    procedure Write(const AKey: string; const AValue: Int64); overload;
    procedure Write(const AKey: string; const AValue: boolean); overload;
    procedure Write(const AKey: string; const AValue: Double); overload;
    procedure Write(const AKey: string; const AValue: TArray<string>); overload;
    procedure Write(const AKey: string; const AValue: TArray<integer>); overload;

    class function AsArray<TI>(const AClass: TBaseJsonClass; const AValue: string): TArray<TI>; overload;
    class function AsArray<TI>(const AClass: TBaseJsonClass; const AValue: TJSONArray): TArray<TI>; overload;
    class function AsJSONArray(const AValue: string): TJSONArray;

    class function GetClass: TBaseJsonClass; virtual;

    procedure SetJSON(const AJson: string); overload;
    procedure SetJSON(const AJSON: TJSONObject); overload;

    function GetJSON: TJSONObject;
  published
    property JSONRaw: string read FJSONRaw;
  end;

(******************************************************************************)

  TOnReceiveRawData = procedure(ASender: TObject; const AData: string) of object;

  TBaseAPI = class(TComponent)
  private
    FRequest: IApiRequest;
    FOnReceiveRawData: TOnReceiveRawData;
    FOnError: TOnAPIError;
    FProxy: IProxy;
    FTimeout: integer;
    FHTTPCliMode: TSKHTTPCliMode;
    FRateLimiter: IAPIRateLimiter;
    procedure SetDomain(const Value: string);
  protected
    function GetDomain: string; virtual;
    procedure DoInitApiCore; virtual;
    function GetRequest: IApiRequest;
    procedure DoCallLogEvent(AException: EAPIException; const ACanBeFree: Boolean); overload;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Domain: string read GetDomain write SetDomain;
    property Proxy: IProxy read FProxy write FProxy;
    property Timeout: integer read FTimeout write FTimeout;
    property HTTPCliMode: TSKHTTPCliMode read FHTTPCliMode write FHTTPCliMode;
    property RateLimiter: IAPIRateLimiter read FRateLimiter write FRateLimiter;

    property OnReceiveRawData: TOnReceiveRawData read FOnReceiveRawData write FOnReceiveRawData;
    property OnError: TOnAPIError read FOnError write FOnError;
  end;

(******************************************************************************)

implementation

uses System.DateUtils, System.TypInfo, API.Types.Impl, Proxy.Types.Impl;

{ TBaseJSON }

class function TBaseJSON.AsArray<TI>(const AClass: TBaseJsonClass;
  const AValue: string): TArray<TI>;
var JsonArr: TJSONArray;
    I: Integer;
    GUID: TGUID;
    Bytes: TBytes;
    Len: integer;
begin
  GUID := GetTypeData(TypeInfo(TI))^.GUID;

  if AClass.GetInterfaceEntry(GUID) = nil then
  begin
    raise Exception.Create(Format('Unsupported interface for %S', [AClass.ClassName]));
  end;

  JsonArr := AsJSONArray(AValue);
  if (not Assigned(JsonArr)) or JsonArr.Null then
    Exit(nil);
  try
    SetLength(Result, JsonArr.Size);
    for I := 0 to High(Result) do
    begin
      SetLength(Bytes, JsonArr.Get(I).EstimatedByteSize);
      Len := JsonArr.Get(I).ToBytes(Bytes, 0);
      AClass.GetClass.Create(TEncoding.UTF8.GetString(Bytes, 0, Len)).GetInterface(GUID, Result[I]);
    end;
  finally
    if Assigned(JsonArr) then
      FreeAndNil(JsonArr);
  end;
end;

class function TBaseJSON.AsArray<TI>(const AClass: TBaseJsonClass;
  const AValue: TJSONArray): TArray<TI>;
var I: Integer;
    GUID: TGUID;
begin
  GUID := GetTypeData(TypeInfo(TI))^.GUID;

  if AClass.GetInterfaceEntry(GUID) = nil then
  begin
    raise Exception.Create(Format('Unsupported interface for %S', [AClass.ClassName]));
  end;

  if (not Assigned(AValue)) or AValue.Null then
    Exit(nil);

  SetLength(Result, AValue.Size);
  for I := 0 to High(Result) do
    AClass.GetClass.Create(AValue.Get(i) as TJSONObject).GetInterface(GUID, Result[I]);
end;

class function TBaseJSON.AsJSONArray(const AValue: string): TJSONArray;
var JSONValue: TJSONValue;
begin
  Result := nil;
  JSONValue := TJSONObject.ParseJSONValue(AValue);
  if Assigned(JSONValue) and (JSONValue is TJSONArray) then
    Result := JSONValue as TJSONArray
  else
    if Assigned(JSONValue) then
      FreeAndNil(JSONValue);
end;

constructor TBaseJSON.Create(const AJson: TJSONObject);
begin
  inherited Create;
  SetJSON(AJson);
end;

constructor TBaseJSON.Create(const AJson: string);
begin
  inherited Create;
  SetJSON(AJson);
end;

destructor TBaseJSON.Destroy;
begin
  if Assigned(FJSON) then
    FreeAndNil(FJSON);

  inherited;
end;

class function TBaseJSON.GetClass: TBaseJsonClass;
begin
  Result := Self;
end;

function TBaseJSON.GetJSON: TJSONObject;
begin
  Result := FJSON;
end;

function TBaseJSON.IsArrayValue(const AKey: string): boolean;
begin
  Result := False;
  if ValueExists(AKey) then
    Result := FJSON.Get(AKey).JsonValue is TJSONArray;
end;

function TBaseJSON.IsBooleanValue(const AKey: string): boolean;
var JSONValue: TJSONValue;
begin
  Result := False;
  if ValueExists(AKey) then
  begin
    JSONValue := FJSON.Get(AKey).JsonValue;
    Result := (JSONValue is TJSONTrue) or (JSONValue is TJSONFalse);
  end;
end;

function TBaseJSON.IsNumberValue(const AKey: string): boolean;
begin
  Result := False;
  if ValueExists(AKey) then
    Result := FJSON.Get(AKey).JsonValue is TJSONNumber;
end;

function TBaseJSON.IsObjectValue(const AKey: string): boolean;
begin
  Result := False;
  if ValueExists(AKey) then
    Result := FJSON.Get(AKey).JsonValue is TJSONObject;
end;

function TBaseJSON.ValueExists(const AKey: string): boolean;
begin
  Result := Assigned(FJSON) and Assigned(FJSON.Get(AKey)) and (not FJSON.Get(AKey).JsonValue.Null);
end;

procedure TBaseJSON.Write(const AKey: string; const AValue: Double);
begin
  Write(AKey, TJSONNumber.Create(AValue));
end;

function TBaseJSON.IsStringValue(const AKey: string): boolean;
begin
  Result := False;
  if ValueExists(AKey) then
    Result := FJSON.Get(AKey).JsonValue is TJSONString;
end;

procedure TBaseJSON.SetJSON(const AJSON: TJSONObject);
begin
  FJSONRaw := EmptyStr;
  if Assigned(AJSON) then
  begin
    FJSONRaw := ToUTF8String(AJSON);

    if Assigned(FJSON) then
      FreeAndNil(FJSON);
    { TODO : Копировать ли? }
    FJSON := AJSON.Clone as TJSONObject;
  end;
end;

function TBaseJSON.ToArray<TI>(TgClass: TBaseJsonClass;
  const AKey: string): TArray<TI>;
var
  LTmpArray: TJSONArray;
begin
  Result := nil;
  if ValueExists(AKey) then
  begin
    LTmpArray := FJSON.Get(AKey).JsonValue as TJSONArray;
    if Assigned(LTmpArray) then
      Result := TBaseJson.AsArray<TI>(TgClass, LTmpArray);
  end;
end;

function TBaseJSON.ToBooleanValue(const AKey: string): boolean;
var IntValue: integer;
begin
  { TODO : Проверить на числовые значения }
  Result := False;
  if ValueExists(AKey) then
  begin
    if FJSON.Get(AKey).JsonValue is TJSONTrue then
      Result := True
    else if TryStrToInt(FJSON.Get(AKey).JsonValue.Value, IntValue) then
      Result := Boolean(IntValue);
  end;
end;

function TBaseJSON.ToDateTime(const AKey: string): TDateTime;
var Value: Int64;
begin
  Value := ToInt64Value(AKey);
  Result := UnixToDateTime(Value);
end;

function TBaseJSON.ToDoubleValue(const AKey: string): Double;
begin
  Result := 0;
  if ValueExists(AKey) then
  begin
    if FJSON.Get(AKey).JsonValue is TJSONNumber then
      Result := (FJSON.Get(AKey).JsonValue as TJSONNumber).AsDouble
    else if not TryStrToFloat(FJSON.Get(AKey).JsonValue.Value, Result) then
      Result := 0;
  end;
end;

function TBaseJSON.ToInt64Array(const AKey: string): TArray<Int64>;
var LJsonArray: TJSONArray;
    i: Integer;
begin
  if ValueExists(AKey) then
  begin
    LJsonArray := FJSON.Get(AKey).JsonValue as TJSONArray;
    if (not Assigned(LJsonArray)) or LJsonArray.Null then
      Exit(nil);
    SetLength(Result, LJsonArray.Size);
    for i := 0 to High(Result) do
    begin
      Result[i] := (LJsonArray.Get(i) as TJSONNumber).AsInt64;
    end;
  end;
end;

function TBaseJSON.ToInt64Value(const AKey: string): Int64;
begin
  Result := 0;
  if ValueExists(AKey) then
  begin
    if FJSON.Get(AKey).JsonValue is TJSONNumber then
      Result := (FJSON.Get(AKey).JsonValue as TJSONNumber).AsInt64
    else if not TryStrToInt64(FJSON.Get(AKey).JsonValue.Value, Result) then
      Result := 0;
  end;
end;

function TBaseJSON.ToIntArray(const AKey: string): TArray<integer>;
var LJsonArray: TJSONArray;
    i: Integer;
begin
  if ValueExists(AKey) then
  begin
    LJsonArray := FJSON.Get(AKey).JsonValue as TJSONArray;
    if (not Assigned(LJsonArray)) or LJsonArray.Null then
      Exit(nil);
    SetLength(Result, LJsonArray.Size);
    for i := 0 to High(Result) do
    begin
      Result[i] := (LJsonArray.Get(i) as TJSONNumber).AsInt;
    end;
  end;
end;

function TBaseJSON.ToIntegerValue(const AKey: string): integer;
begin
  Result := 0;
  if ValueExists(AKey) then
  begin
    if FJSON.Get(AKey).JsonValue is TJSONNumber then
      Result := (FJSON.Get(AKey).JsonValue as TJSONNumber).AsInt
    else if not TryStrToInt(FJSON.Get(AKey).JsonValue.Value, Result) then
      Result := 0;
  end;
end;

function TBaseJSON.ToStringArray(const AKey: string): TArray<string>;
var LJsonArray: TJSONArray;
    i: Integer;
begin
  if ValueExists(AKey) then
  begin
    LJsonArray := FJSON.Get(AKey).JsonValue as TJSONArray;
    if (not Assigned(LJsonArray)) or LJsonArray.Null then
      Exit(nil);
    SetLength(Result, LJsonArray.Size);
    for i := 0 to High(Result) do
    begin
      Result[i] := LJsonArray.Get(i).Value;
    end;
  end;
end;

function TBaseJSON.ToStringValue(const AKey: string): string;
begin
  Result := EmptyStr;
  if ValueExists(AKey) then
    Result := FJSON.Get(AKey).JsonValue.Value;
end;

function TBaseJSON.ToUInt64Value(const AKey: string): UInt64;
begin
  Result := 0;
  if ValueExists(AKey) then
  begin
    if FJSON.Get(AKey).JsonValue is TJSONNumber then
      Result := (FJSON.Get(AKey).JsonValue as TJSONNumber).AsInt64
    else if not TryStrToUInt64(FJSON.Get(AKey).JsonValue.Value, Result) then
      Result := 0;
  end;
end;

procedure TBaseJSON.Write(const AKey: string; const AValue: Int64);
begin
  Write(AKey, TJSONNumber.Create(AValue));
end;

procedure TBaseJSON.Write(const AKey, AValue: string);
begin
  Write(AKey, TJSONString.Create(AValue));
//  Write(AKey, TSVJSONString.Create(AValue));
end;

procedure TBaseJSON.Write(const AKey: string; const AValue: TJSONValue);
var i: Integer;
begin
  for i := 0 to FJSON.Size - 1 do
  begin
    if FJSON.Get(i).JsonString.Value = AKey then
    begin
      FJSON.RemovePair(AKey).Free;
      Break;
    end;
  end;
  FJSON.AddPair(AKey, AValue);
  FJSONRaw := ToUTF8String(FJSON);
//  FJsonRaw := FJSON.ToString;
end;

procedure TBaseJSON.SetJSON(const AJson: string);
begin
  FJSONRaw := AJson;
  if FJSONRaw.IsEmpty then Exit;

  if Assigned(FJSON) then
    FreeAndNil(FJSON);
  FJSON := TJSONObject.ParseJSONValue(AJson) as TJSONObject;
end;

function TBaseJSON.ToClass<T>(const AKey: string): T;
var LObj: TJSONObject;
begin
  Result := nil;
  LObj := nil;
  if ValueExists(AKey) then
  begin
    LObj := FJSON.Get(AKey).JsonValue as TJSONObject;
  end;

  Result := TBaseJsonClass(T).Create(LObj) as T;
end;

procedure TBaseJSON.Write(const AKey: string; const AValue: boolean);
begin
  if AValue then
    Write(AKey, TJSONTrue.Create)
  else
    Write(AKey, TJSONFalse.Create);
end;

procedure TBaseJSON.Write(const AKey: string; const AValue: TArray<string>);
var
  JSONArray: TJSONArray;
  i: Integer;
begin
  JSONArray := TJSONArray.Create;
  for i := 0 to Length(AValue) - 1 do
    JSONArray.AddElement(TJSONString.Create(AValue[i]));
  Write(AKey, JSONArray);
end;

procedure TBaseJSON.Write(const AKey: string; const AValue: TArray<integer>);
var
  JSONArray: TJSONArray;
  i: Integer;
begin
  JSONArray := TJSONArray.Create;
  for i := 0 to Length(AValue) - 1 do
    JSONArray.AddElement(TJSONNumber.Create(AValue[i]));
  Write(AKey, JSONArray);
end;

{ TBaseAPI }

constructor TBaseAPI.Create(AOwner: TComponent);
begin
  inherited;
  FTimeout := 30;
  FHTTPCliMode := skmIcs;
  FProxy := TProxy.Create;
  DoInitApiCore;
end;

procedure TBaseAPI.DoCallLogEvent(AException: EAPIException;
  const ACanBeFree: Boolean);
begin
  if Assigned(FOnError) then
    FOnError(Self, AException)
  else
    raise AException;
  if ACanBeFree then
    FreeAndNil(AException);
end;

procedure TBaseAPI.DoInitApiCore;
begin
  FRequest := TAPIRequest.Create;

  GetRequest.OnStaticFill := procedure
    begin
      GetRequest.Proxy := Proxy;
      GetRequest.Timeout := Timeout;
      GetRequest.HTTPCliMode := HTTPCliMode;
    end;

  GetRequest.OnDataReceiveAsString := function(AData: string): string
    begin
      if Assigned(OnReceiveRawData) then
        OnReceiveRawData(Self, AData);
      Result := AData;
    end;
end;

function TBaseAPI.GetDomain: string;
begin
  Result := GetRequest.Domain;
end;

function TBaseAPI.GetRequest: IApiRequest;
begin
  Result := FRequest;
end;

procedure TBaseAPI.SetDomain(const Value: string);
begin
  GetRequest.Domain := Value;
end;

end.

