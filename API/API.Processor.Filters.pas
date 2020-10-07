unit API.Processor.Filters;

interface

uses
  System.Classes, System.SysUtils,
  Generics.Collections,
  API.Processor;

type

  TItemEvent = procedure(ASender: TObject; AItem: IInterface) of object;
  TItemsEvent = procedure(Sender: TObject; AItems: TArray<IInterface>) of object;

(******************************************************************************)

  TLimiterFilter = class(TCommonProcessor)
  private
    FCurrentCount: integer;
    FLimit: integer;
    FOnGetLimit: TNotifyEvent;
  protected
    procedure SetData(const Value: TArray<IInterface>); override;

    procedure DoOnGetLimit; virtual;
  public
    constructor Create(Owner: TComponent); override;
  published
    property Limit: integer read FLimit write FLimit;

    property OnGetLimit: TNotifyEvent read FOnGetLimit write FOnGetLimit;
  end;

(******************************************************************************)

  { Передает по цепочке по 1 элементу через тайм-аут }
  TTimeoutShootingLimiter = class(TCommonProcessor)
  private
    FSkipNextTimeout: boolean;
    FTimeoutMin: integer;
    FTimeoutMax: integer;
    FOnDone: TNotifyEvent;
    FOnBeforeShoot: TItemEvent;
    FOnAfterShoot: TItemEvent;
  protected
    procedure SetData(const Value: TArray<IInterface>); override;

    procedure DoBeforeShoot(AItem: IInterface); virtual;
    procedure DoAfterShoot(AItem: IInterface); virtual;
    procedure DoDone; virtual;
  public
    constructor Create(Owner: TComponent); override;

    procedure SkipNextTimeout;
  published
    property TimeoutMin: integer read FTimeoutMin write FTimeoutMin;
    property TimeoutMax: integer read FTimeoutMax write FTimeoutMax;

    property OnBeforeShoot: TItemEvent read FOnBeforeShoot write FOnBeforeShoot;
    property OnAfterShoot: TItemEvent read FOnAfterShoot write FOnAfterShoot;
    property OnDone: TNotifyEvent read FOnDone write FOnDone;
  end;

(******************************************************************************)

  { Выбирает случайные интерфейсы и передает их дальше по цепочке }
  TRandomLimiter = class(TCommonProcessor)
  private
    FMaxCount: integer;
    FMinCount: integer;
    FOnSelectRandomItems: TItemsEvent;
  protected
    procedure SetData(const Value: TArray<IInterface>); override;

    procedure DoSelectRandomItems(AItems: TArray<IInterface>); virtual;
  public
    constructor Create(Owner: TComponent); override;
  published
    property MinCount: integer read FMinCount write FMinCount;
    property MaxCount: integer read FMaxCount write FMaxCount;

    property OnSelectRandomItems: TItemsEvent read FOnSelectRandomItems write FOnSelectRandomItems;
  end;

(******************************************************************************)

implementation

uses
  Winapi.Windows,
  System.Math;

{ TLimiterFilter }

constructor TLimiterFilter.Create(Owner: TComponent);
begin
  inherited;

  FCurrentCount := 0;
  FLimit := 1000000;
end;

procedure TLimiterFilter.DoOnGetLimit;
begin
  if Assigned(FOnGetLimit) then
    FOnGetLimit(Self);
end;

procedure TLimiterFilter.SetData(const Value: TArray<IInterface>);
var
  i: Integer;
  Count: integer;
  Res: TArray<IInterface>;
begin
  inherited;

  if FCurrentCount >= Limit then Exit;

  Count := Min(Limit - FCurrentCount, Length(Value));
  SetLength(Res, Count);
  for i := 0 to Count - 1 do
  begin
    if not Enabled then Exit;

    Res[i] := Value[i];
  end;

  if Length(Res) > 0 then
  begin
    FCurrentCount := FCurrentCount + Length(Res);
    DataSource.UpdateConsumerData(Res);
  end;

  if FCurrentCount >= Limit then
    DoOnGetLimit;
end;

{ TTimeoutLimiter }

constructor TTimeoutShootingLimiter.Create(Owner: TComponent);
begin
  inherited;

  FTimeoutMin := 1;
  FTimeoutMax := 1;
end;

procedure TTimeoutShootingLimiter.DoAfterShoot(AItem: IInterface);
begin
  if Assigned(FOnAfterShoot) then
    FOnAfterShoot(Self, AItem);
end;

procedure TTimeoutShootingLimiter.DoBeforeShoot(AItem: IInterface);
begin
  if Assigned(FOnBeforeShoot) then
    FOnBeforeShoot(Self, AItem);
end;

procedure TTimeoutShootingLimiter.DoDone;
begin
  if Assigned(FOnDone) then
    FOnDone(Self);
end;

procedure TTimeoutShootingLimiter.SetData(const Value: TArray<IInterface>);
var
  i: Integer;
  OutputData: TArray<IInterface>;
  LastUpdateTickCount: Cardinal;
begin
  inherited;

  SetLength(OutputData, 1);
  for i := 0 to Length(Value) - 1 do
  begin
    if not Enabled then Break;
    
    OutputData[0] := Value[i];
    LastUpdateTickCount := GetTickCount;
    FSkipNextTimeout := False;
    DoBeforeShoot(OutputData[0]);
    DataSource.UpdateConsumerData(OutputData);
    DoAfterShoot(OutputData[0]);

    if FSkipNextTimeout then Continue;

    WaitForTimeout(RandomRange(TimeoutMin, TimeoutMax) - (GetTickCount - LastUpdateTickCount));
  end;

  DoDone;
end;

procedure TTimeoutShootingLimiter.SkipNextTimeout;
begin
  FSkipNextTimeout := True;
end;

{ TRandomLimiter }

constructor TRandomLimiter.Create(Owner: TComponent);
begin
  inherited;

  FMinCount := 10;
  FMaxCount := 20;
end;

procedure TRandomLimiter.DoSelectRandomItems(AItems: TArray<IInterface>);
begin
  if Assigned(FOnSelectRandomItems) then
    FOnSelectRandomItems(Self, AItems);
end;

procedure TRandomLimiter.SetData(const Value: TArray<IInterface>);
var
  i: Integer;
  Count: integer;
  OutputDataList: TList<IInterface>;
  DataArray: TArray<IInterface>;
  Data: IInterface;
begin
  inherited;

  Count := Min(Length(Value), RandomRange(MinCount, MaxCount));
  if Count > 0 then
  begin
    OutputDataList := TList<IInterface>.Create;
    try
      while True do
      begin
        if not Enabled then Exit;
        
        if OutputDataList.Count >= Count then
        begin
          DataArray := OutputDataList.ToArray;
          if Length(DataArray) > 0 then
          begin
            DoSelectRandomItems(DataArray);
            DataSource.UpdateConsumerData(DataArray);
          end;
          Break;
        end;

        Randomize;
        Data := Value[Random(Length(Value))];
        if OutputDataList.IndexOf(Data) = -1 then
          OutputDataList.Add(Data);
      end;
    finally
      FreeAndNil(OutputDataList);
    end;
  end;
end;

end.
