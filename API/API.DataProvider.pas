unit API.DataProvider;

interface

uses System.Classes;

type

  TDataProvider = class;

  {Базовый класс потребителя данных}
  TDataConsumer = class(TComponent)
	private
		FData: TArray<IInterface>;
		FEnabled: boolean;
		FDataProvider: TDataProvider;
		FOnSetData: TNotifyEvent;
		procedure SetOnSetData(const Value: TNotifyEvent);
	protected
    procedure SetEnabled(const Value: boolean); virtual;
    procedure SetDataProvider(const Value: TDataProvider); virtual;
		procedure SetData(const Value: TArray<IInterface>); virtual;
	public
		constructor Create(Owner: TComponent); override;
		destructor Destroy; override;

		property Data: TArray<IInterface> read FData write SetData;
	published
		property Enabled: boolean read FEnabled write SetEnabled;
		property DataProvider: TDataProvider read FDataProvider write SetDataProvider;
		property OnSetData: TNotifyEvent read FOnSetData write SetOnSetData;
	end;

(******************************************************************************)

  { Базовый класс поставщика данных }
  TDataProvider = class(TComponent)
	private
		FDataConsumers: TThreadList;
    FOnUpdateConsumerData: TNotifyEvent;
    function GetConsumersCount: Integer;
    function GetConsumers(Idx: integer): TDataConsumer;
  protected
    procedure DoUpdateConsumerData; virtual;
	public
    constructor Create(AOwner: TComponent); override;
		destructor Destroy; override;

		procedure UpdateConsumerData(Buf: TArray<IInterface>); virtual;

		procedure AddDataConsumer(ADataConsumer: TDataConsumer); virtual;
		procedure RemoveDataConsumer(ADataConsumer: TDataConsumer); virtual;

    property ConsumersCount: Integer read GetConsumersCount;
    property Consumers[Idx: integer]: TDataConsumer read GetConsumers;
  published
    property OnUpdateConsumerData: TNotifyEvent read FOnUpdateConsumerData write FOnUpdateConsumerData;
	end;

implementation

uses System.SysUtils;

{ TDataConsumer }

constructor TDataConsumer.Create(Owner: TComponent);
begin
  inherited;

  FDataProvider := nil;
	Enabled := true;
end;

destructor TDataConsumer.Destroy;
begin
  FEnabled := False;

  if Assigned(FDataProvider) then
		FDataProvider.RemoveDataConsumer(Self);

	if Assigned(FData) then
		FData := nil;

  inherited;
end;

procedure TDataConsumer.SetData(const Value: TArray<IInterface>);
begin
  if not Assigned(Value) then
  begin
    if Assigned(FData) then
      FData := nil;

    Exit;
  end;
	if not Enabled then Exit;

  FData := Value;

	if Assigned(FOnSetData) then FOnSetData(Self);
end;

procedure TDataConsumer.SetDataProvider(const Value: TDataProvider);
begin
   if Assigned(FDataProvider) then
		FDataProvider.RemoveDataConsumer(Self);

	FDataProvider := Value;

	if Assigned(FDataProvider) then
		FDataProvider.AddDataConsumer(Self);
end;

procedure TDataConsumer.SetEnabled(const Value: boolean);
begin
  FEnabled := Value;
end;

procedure TDataConsumer.SetOnSetData(const Value: TNotifyEvent);
begin
  FOnSetData := Value;
end;

{ TDataProvider }

procedure TDataProvider.AddDataConsumer(ADataConsumer: TDataConsumer);
var DataConsumers: TList;
begin
	DataConsumers := FDataConsumers.LockList;
  try
    if DataConsumers.IndexOf(ADataConsumer) = -1 then
		  DataConsumers.Add(ADataConsumer);
  finally
    FDataConsumers.UnlockList;
  end;
end;

constructor TDataProvider.Create(AOwner: TComponent);
begin
  inherited;

  FDataConsumers := TThreadList.Create;
end;

destructor TDataProvider.Destroy;
var DataConsumers: TList;
begin
	DataConsumers := FDataConsumers.LockList;
  try
    while DataConsumers.Count > 0 do
    begin
      TDataConsumer(DataConsumers.Items[0]).DataProvider := nil;
    end;
  finally
    FDataConsumers.UnlockList;
  end;

	FreeAndNil(FDataConsumers);

  inherited;
end;

procedure TDataProvider.DoUpdateConsumerData;
begin
  if Assigned(FOnUpdateConsumerData) then
    FOnUpdateConsumerData(Self);
end;

function TDataProvider.GetConsumers(Idx: integer): TDataConsumer;
var List: TList;
begin
  List := FDataConsumers.LockList;
  try
    Result := TDataConsumer(List.Items[Idx]);
  finally
    FDataConsumers.UnlockList;
  end;
end;

function TDataProvider.GetConsumersCount: Integer;
var List: TList;
begin
  List := FDataConsumers.LockList;
  Result := List.Count;
  FDataConsumers.UnlockList;
end;

procedure TDataProvider.RemoveDataConsumer(ADataConsumer: TDataConsumer);
begin
  FDataConsumers.Remove(ADataConsumer)
end;

procedure TDataProvider.UpdateConsumerData(Buf: TArray<IInterface>);
var i: integer;
		DataConsumers: TList;
begin
	DataConsumers := FDataConsumers.LockList;
  try
    for i := 0 to DataConsumers.Count - 1 do
    begin
      TDataConsumer(DataConsumers.Items[i]).Data := Buf;
    end;

    DoUpdateConsumerData;
  finally
    FDataConsumers.UnlockList;
  end;
end;

end.
