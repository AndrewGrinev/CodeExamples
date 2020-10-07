unit API.Processor;

interface

uses
  System.Classes, System.SysUtils, Generics.Collections,
  API.DataProvider, API.Exceptions,
  Proxy.Types,
  skhttpcli;

type

  TInterfaceEvent = procedure(Sender: TObject; Item: IInterface) of object;

(******************************************************************************)

  TCommonProcessor = class(TDataConsumer)
  private
    FDataSource: TDataProvider;
    FOnChangeDataItem: TInterfaceEvent;
    FOnError: TOnError;
    FOnProcessedItem: TInterfaceEvent;
  protected
    procedure DoChangeDataItem(const AItem: IInterface); virtual;
    procedure DoProcessedItem(const AItem: IInterface); virtual;
    procedure DoOnError(const AException: Exception); virtual;
    procedure DoCallLogEvent(AException: Exception; const ACanBeFree: Boolean); virtual;
  public
    constructor Create(Owner: TComponent); override;
		destructor Destroy; override;

    procedure WaitForTimeout(ATimeout: integer); virtual;

    property DataSource: TDataProvider read FDataSource;
  published
    property OnChangeDataItem: TInterfaceEvent read FOnChangeDataItem write FOnChangeDataItem;
    property OnProcessedItem: TInterfaceEvent read FOnProcessedItem write FOnProcessedItem;
    property OnError: TOnError read FOnError write FOnError;
  end;

(******************************************************************************)

  TWebCommonProcessor = class(TCommonProcessor)
  private
    FHTTPTimeout: integer;
    FHTTPCliMode: TSKHTTPCliMode;
    FProxies: TList<IProxy>;
    FUnconnectionProxies: TDictionary<IProxy, Cardinal>;
    FTimeoutForConnectionCheck: integer;
    FOnConnectionError: TProxyEvent;
    FOnConnectionRestore: TProxyEvent;
    FProxyIdx: integer;

    procedure UnconnectionProxyNotifyExecute(Sender: TObject; const Item: IProxy; Action: TCollectionNotification);

    procedure SetProxies(const Value: TList<IProxy>);
  protected
    procedure SetData(const Value: TArray<IInterface>); override;

    procedure WaitForTimeout(ATimeout: integer);

    procedure DoUnconnectionProxy(const Value: IProxy); virtual;

    procedure DoOnConnectionError(const Value: IProxy); virtual;
    procedure DoOnConnectionRestore(const Value: IProxy); virtual;

    function GetAvailableProxy(var aProxyIdx: integer): IProxy;
    function GetNextWorkProxy: IProxy; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property Proxies: TList<IProxy> read FProxies write SetProxies;

    property UnconnectionProxies: TDictionary<IProxy, Cardinal> read FUnconnectionProxies;
  published
    property HTTPTimeout: integer read FHTTPTimeout write FHTTPTimeout;
    property HTTPCliMode: TSKHTTPCliMode read FHTTPCliMode write FHTTPCliMode;
    { Через какое минимальное кол-во времени пробовать делать запрос при обрыве соединения }
    property TimeoutForConnectionCheck: integer read FTimeoutForConnectionCheck write FTimeoutForConnectionCheck;

    { Вызывается, когда случается ошибка подключения у прокси }
    property OnConnectionError: TProxyEvent read FOnConnectionError write FOnConnectionError;
    { Вызывается, когда прокси восстановило соединение }
    property OnConnectionRestore: TProxyEvent read FOnConnectionRestore write FOnConnectionRestore;
  end;

(******************************************************************************)

  TAPIAccumulationProcessor = class(TCommonProcessor)
  private
    FMaxCount: integer;
    FData: TList<IInterface>;
    FOnAccumulatedData: TNotifyEvent;
  protected
    procedure DoOnAccumulatedData;

    procedure SetData(const Value: TArray<IInterface>); override;
  public
    constructor Create(Owner: TComponent); override;
		destructor Destroy; override;

    property Data: TList<IInterface> read FData;
  published
    property MaxCount: integer read FMaxCount write FMaxCount;

    property OnAccumulatedData: TNotifyEvent read FOnAccumulatedData write FOnAccumulatedData;
  end;

(******************************************************************************)

implementation

uses System.Generics.Defaults, WinAPI.Windows;

{ TCommonProcessor }

constructor TCommonProcessor.Create(Owner: TComponent);
begin
  inherited;

  FDataSource := TDataProvider.Create(Self);
end;

destructor TCommonProcessor.Destroy;
begin
  FreeAndNil(FDataSource);

  inherited;
end;

procedure TCommonProcessor.DoCallLogEvent(AException: Exception;
  const ACanBeFree: Boolean);
begin
  if Assigned(FOnError) then
    FOnError(Self, AException)
  else
    raise AException;
  if ACanBeFree then
    FreeAndNil(AException);
end;

procedure TCommonProcessor.DoChangeDataItem(const AItem: IInterface);
begin
  if Assigned(FOnChangeDataItem) then
    FOnChangeDataItem(Self, AItem);
end;

procedure TCommonProcessor.DoOnError(const AException: Exception);
begin
  if Assigned(FOnError) then
    FOnError(Self, AException);
end;

procedure TCommonProcessor.DoProcessedItem(const AItem: IInterface);
begin
  if Assigned(FOnProcessedItem) then
    FOnProcessedItem(Self, AItem);
end;

procedure TCommonProcessor.WaitForTimeout(ATimeout: integer);
begin
  while Enabled and (ATimeout > 0) do
  begin
    Sleep(10);
    ATimeout := ATimeout - 10;
  end;
end;

{ TAPIAccumulationProcessor }

constructor TAPIAccumulationProcessor.Create(Owner: TComponent);
begin
  inherited;

  FData := TList<IInterface>.Create;
  FMaxCount := 1000;
end;

destructor TAPIAccumulationProcessor.Destroy;
begin
  FreeAndNil(FData);

  inherited;
end;

procedure TAPIAccumulationProcessor.DoOnAccumulatedData;
begin
  if Assigned(FOnAccumulatedData) then
    FOnAccumulatedData(Self);
end;

procedure TAPIAccumulationProcessor.SetData(const Value: TArray<IInterface>);
var
  i: integer;
begin
  if not Enabled then Exit;

  if FData.Count + Length(Value) >= MaxCount then
  begin
    i := 0;
    while FData.Count < MaxCount do
    begin
      if not Enabled then Exit;

      FData.Add(Value[i]);
      Inc(i);
    end;

    DoOnAccumulatedData;
    DataSource.UpdateConsumerData(FData.ToArray);
    FData.Clear;

    SetData(Copy(Value, i, Length(Value) - i));
  end
  else
    FData.AddRange(Value);
end;

{ TWebCommonProcessor }

constructor TWebCommonProcessor.Create(AOwner: TComponent);
var Comparer: IEqualityComparer<IProxy>;
begin
  inherited;

  FProxyIdx := 0;
  FProxies := TList<IProxy>.Create;
  FHTTPTimeout := 30;
  FHTTPCliMode := skmIcs;
  FTimeoutForConnectionCheck := 1000;


  Comparer := TDelegatedEqualityComparer<IProxy>.Create(
    function(const Left, Right: IProxy): Boolean
    begin
      Result := CompareText(Left.ProxyHost + Left.ProxyPort, Right.ProxyHost + Right.ProxyPort) = 0;
    end,
    function(const Value: IProxy): Integer
    var AT: string;
    begin
      AT := AnsiLowerCase(Value.ProxyHost + Value.ProxyPort);
      Result := BobJenkinsHash(AT[1], Length(AT) * SizeOf(AT[1]), 0);
    end
  );

  FUnconnectionProxies := TDictionary<IProxy, Cardinal>.Create(Comparer);
  FUnconnectionProxies.OnKeyNotify := UnconnectionProxyNotifyExecute;
end;

destructor TWebCommonProcessor.Destroy;
begin
  FreeAndNil(FProxies);
  FreeAndNil(FUnconnectionProxies);

  inherited;
end;

procedure TWebCommonProcessor.DoOnConnectionError(const Value: IProxy);
begin
  if Assigned(FOnConnectionError) then
    FOnConnectionError(Self, Value)
end;

procedure TWebCommonProcessor.DoOnConnectionRestore(const Value: IProxy);
begin
  if Assigned(FOnConnectionRestore) then
    FOnConnectionRestore(Self, Value);
end;

procedure TWebCommonProcessor.DoUnconnectionProxy(const Value: IProxy);
begin
  TMonitor.Enter(Self);
  try
    FUnconnectionProxies.AddOrSetValue(Value, GetTickCount);
  finally
    TMonitor.Exit(Self);
  end;
end;

function TWebCommonProcessor.GetAvailableProxy(var aProxyIdx: integer): IProxy;
var InitProxyIdx: integer;
    TickCount: Cardinal;
    Proxy: IProxy;
begin
  Result := nil;

  InitProxyIdx := aProxyIdx;
  while True do
  begin
    try
      if not Enabled then Exit;

      Proxy := Proxies.Items[aProxyIdx];

      { Если этот прокси имеет проблемы с подключением }
      if UnconnectionProxies.TryGetValue(Proxy, TickCount) then
      begin
        if Abs(GetTickCount - TickCount) >= TimeoutForConnectionCheck then
          Exit(Proxy)
      end
      else
        Exit(Proxy);

      { Если прошлись по всем аккаунтам }
      if InitProxyIdx = aProxyIdx then
        WaitForTimeout(300);
    finally
      Inc(aProxyIdx);
      if aProxyIdx >= Proxies.Count then
        aProxyIdx := 0;
    end;
  end;
end;

function TWebCommonProcessor.GetNextWorkProxy: IProxy;
begin
  TMonitor.Enter(Self);
  try
    Result := GetAvailableProxy(FProxyIdx);
  finally
    TMonitor.Exit(Self);
  end;
end;

procedure TWebCommonProcessor.SetData(const Value: TArray<IInterface>);
begin
  inherited;

  if Proxies.Count = 0 then
    raise Exception.Create('Proxies is empty.');
end;

procedure TWebCommonProcessor.SetProxies(const Value: TList<IProxy>);
begin
  FProxies.Clear;
  FProxies.AddRange(Value.ToArray);
end;

procedure TWebCommonProcessor.UnconnectionProxyNotifyExecute(Sender: TObject;
  const Item: IProxy; Action: TCollectionNotification);
begin
  case Action of
    cnAdded:
      DoOnConnectionError(Item);
    cnRemoved:
      DoOnConnectionRestore(Item);
  end;
end;

procedure TWebCommonProcessor.WaitForTimeout(ATimeout: integer);
begin
  while Enabled and (ATimeout > 0) do
  begin
    Sleep(10);
    ATimeout := ATimeout - 10;
  end;
end;

end.
