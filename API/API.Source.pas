unit API.Source;

interface

uses API.DataProvider, System.Classes, API.Exceptions, System.SysUtils, skhttpcli;

type

(******************************************************************************)

  TCommonSource = class(TDataProvider)
  private
    FOnStop: TNotifyEvent;
    FOnStart: TNotifyEvent;
    FOnError: TOnError;
  protected
    FThread: TThread;
    FIsActive: boolean;

    procedure WaitForTimeout(ATimeout: integer);

    procedure SetIsActive(const Value: boolean); virtual;

    procedure Go; virtual; abstract;

    procedure DoOnStart; virtual;
    procedure DoOnStop; virtual;
    procedure DoOnError(const AException: Exception); virtual;
    procedure DoCallLogEvent(AException: Exception; const ACanBeFree: Boolean); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property IsActive: boolean read FIsActive write SetIsActive;

    procedure Start;
    procedure Stop;
  published
    { Вызывается, когда задача начинает работу }
    property OnStart: TNotifyEvent read FOnStart write FOnStart;
    { Вызывается, когда задача закончила работу }
    property OnStop: TNotifyEvent read FOnStop write FOnStop;
    { Вызывается, когда произошла какая-то непредвиденная ошибка API }
    property OnError: TOnError read FOnError write FOnError;
  end;

(******************************************************************************)

  TAPICommonSource = class(TDataProvider)
  private
    FOnStop: TNotifyEvent;
    FOnStart: TNotifyEvent;
    FOnError: TOnError;
    FHTTPTimeout: integer;
    FHTTPCliMode: TSKHTTPCliMode;
  protected
    FThread: TThread;
    FIsActive: boolean;

    procedure SetIsActive(const Value: boolean); virtual;

    procedure Go; virtual; abstract;

    procedure DoOnStart; virtual;
    procedure DoOnStop; virtual;
    procedure DoOnError(const AException: Exception); virtual;
    procedure DoCallLogEvent(AException: Exception; const ACanBeFree: Boolean); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property IsActive: boolean read FIsActive write SetIsActive;

    procedure Start;
    procedure Stop;
  published
    property HTTPTimeout: integer read FHTTPTimeout write FHTTPTimeout;
    property HTTPCliMode: TSKHTTPCliMode read FHTTPCliMode write FHTTPCliMode;

    { Вызывается, когда задача начинает работу }
    property OnStart: TNotifyEvent read FOnStart write FOnStart;
    { Вызывается, когда задача закончила работу }
    property OnStop: TNotifyEvent read FOnStop write FOnStop;
    { Вызывается, когда произошла какая-то непредвиденная ошибка API }
    property OnError: TOnError read FOnError write FOnError;
  end;

(******************************************************************************)

implementation

{ TCommonSource }

constructor TAPICommonSource.Create(AOwner: TComponent);
begin
  inherited;

  FHTTPTimeout := 30;
  FHTTPCliMode := skmIcs;
  FThread := nil;
end;

destructor TAPICommonSource.Destroy;
begin
  Stop;

  inherited;
end;

procedure TAPICommonSource.DoCallLogEvent(AException: Exception;
  const ACanBeFree: Boolean);
begin
  if Assigned(FOnError) then
    FOnError(Self, AException)
  else
    raise AException;
  if ACanBeFree then
    FreeAndNil(AException);
end;

procedure TAPICommonSource.DoOnError(const AException: Exception);
begin
  if Assigned(FOnError) then
    FOnError(Self, AException);
end;

procedure TAPICommonSource.DoOnStart;
begin
  if Assigned(FOnStart) then
    FOnStart(Self);
end;

procedure TAPICommonSource.DoOnStop;
begin
  if Assigned(FOnStop) then
    FOnStop(Self);
end;

procedure TAPICommonSource.SetIsActive(const Value: boolean);
begin
  if FIsActive = Value then
    Exit;
  FIsActive := Value;
  if Value then
  begin
    if Assigned(FThread) then
    begin
      FThread.Terminate;
      FThread.WaitFor;
      FreeAndNil(FThread);
    end;

    FThread := TThread.CreateAnonymousThread(Go);
    FThread.FreeOnTerminate := False;
    FThread.Start;
  end
  else
  begin
    if Assigned(FThread) then
    begin
      FThread.Terminate;
      FThread.WaitFor;
      FreeAndNil(FThread);
    end;
  end;
end;

procedure TAPICommonSource.Start;
begin
  IsActive := True;
end;

procedure TAPICommonSource.Stop;
begin
  IsActive := False;
end;

{ TCommonSource }

constructor TCommonSource.Create(AOwner: TComponent);
begin
  inherited;

  FThread := nil;
end;

destructor TCommonSource.Destroy;
begin
  Stop;

  inherited;
end;

procedure TCommonSource.DoCallLogEvent(AException: Exception;
  const ACanBeFree: Boolean);
begin
  if Assigned(FOnError) then
    FOnError(Self, AException)
  else
    raise AException;
  if ACanBeFree then
    FreeAndNil(AException);
end;

procedure TCommonSource.DoOnError(const AException: Exception);
begin
  if Assigned(FOnError) then
    FOnError(Self, AException);
end;

procedure TCommonSource.DoOnStart;
begin
  if Assigned(FOnStart) then
    FOnStart(Self);
end;

procedure TCommonSource.DoOnStop;
begin
  if Assigned(FOnStop) then
    FOnStop(Self);
end;

procedure TCommonSource.SetIsActive(const Value: boolean);
begin
  if FIsActive = Value then
    Exit;
  FIsActive := Value;
  if Value then
  begin
    if Assigned(FThread) then
    begin
      FThread.Terminate;
      FThread.WaitFor;
      FreeAndNil(FThread);
    end;

    FThread := TThread.CreateAnonymousThread(Go);
    FThread.FreeOnTerminate := False;
    FThread.Start;
  end
  else
  begin
    if Assigned(FThread) then
    begin
      FThread.Terminate;
      FThread.WaitFor;
      FreeAndNil(FThread);
    end;
  end;
end;

procedure TCommonSource.Start;
begin
  IsActive := True;
end;

procedure TCommonSource.Stop;
begin
  IsActive := False;
end;

procedure TCommonSource.WaitForTimeout(ATimeout: integer);
begin
  while IsActive and (ATimeout > 0) do
  begin
    Sleep(10);
    ATimeout := ATimeout - 10;
  end;
end;

end.
