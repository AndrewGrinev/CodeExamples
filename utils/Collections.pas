unit Collections;

interface

uses System.Types, System.SysUtils, Winapi.Windows, System.Generics.Collections;

type

  TThreadedQueue<T> = class
  private
    FQueue: array of T;
    FQueueSize, FQueueOffset: Integer;
    FQueueNotEmpty,
    FQueueNotFull: THandle;
    FQueueLock: RTL_CRITICAL_SECTION;
    FShutDown: Boolean;
    FPushTimeout: Cardinal;
    FPopTimeout: Cardinal;
    FTotalItemsPushed, FTotalItemsPopped: Cardinal;

    procedure Lock; inline;
    procedure Unlock; inline;
  public
    constructor Create(AQueueDepth: Integer = 10; PushTimeout: Cardinal = INFINITE; PopTimeout: Cardinal = INFINITE);
    destructor Destroy; override;

    procedure Grow(ADelta: Integer);
    function PushItem(const AItem: T): TWaitResult; overload;
    function PushItem(const AItem: T; var AQueueSize: Integer): TWaitResult; overload;
    function PopItem: T; overload;
    function PopItem(var AQueueSize: Integer): T; overload;
    function PopItem(var AQueueSize: Integer; var AItem: T): TWaitResult; overload;
    function PopItem(var AItem: T): TWaitResult; overload;
    procedure DoShutDown;

    property QueueSize: Integer read FQueueSize;
    property ShutDown: Boolean read FShutDown;
    property TotalItemsPushed: Cardinal read FTotalItemsPushed;
    property TotalItemsPopped: Cardinal read FTotalItemsPopped;
  end;

implementation

uses System.RTLConsts;

{ TThreadedQueue<T> }

constructor TThreadedQueue<T>.Create(AQueueDepth: Integer; PushTimeout,
  PopTimeout: Cardinal);
begin
  inherited Create;
  SetLength(FQueue, AQueueDepth);
  InitializeCriticalSection(FQueueLock);
  FQueueNotEmpty := CreateEvent(nil, False, False, '');
  FQueueNotFull := CreateEvent(nil, False, False, '');
  FPushTimeout := PushTimeout;
  FPopTimeout := PopTimeout;
end;

destructor TThreadedQueue<T>.Destroy;
begin
  DoShutDown;
  CloseHandle(FQueueNotFull);
  CloseHandle(FQueueNotEmpty);
  DeleteCriticalSection(FQueueLock);
  inherited;
end;

procedure TThreadedQueue<T>.DoShutDown;
begin
  Lock;
  try
    FShutDown := True;
  finally
    Unlock;
  end;
  SetEvent(FQueueNotFull);
  SetEvent(FQueueNotEmpty);
end;

procedure TThreadedQueue<T>.Grow(ADelta: Integer);
var
  Ind, PartialLength, OldLength, NewLength: Integer;
begin
  Lock;
  try
    OldLength := Length(FQueue);
    NewLength := OldLength + ADelta;
    if ADelta < 0 then
    begin
      if FQueueSize > NewLength then
        raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange)
      else if FQueueOffset <> 0 then
      begin
        if (NewLength <= FQueueOffset) then
        begin
          for Ind := FQueueSize - 1 downto 0 do
          begin
            FQueue[Ind] := FQueue[(FQueueOffset + Ind) mod OldLength];
            FQueue[(FQueueOffset + Ind) mod OldLength] := Default(T);
          end;
          FQueueOffset := 0;
        end
        else if (NewLength <= FQueueOffset + FQueueSize - 1) then
        begin
          for Ind := 0 to FQueueSize - 1 do
          begin
            FQueue[Ind] := FQueue[(FQueueOffset + Ind) mod OldLength];
            FQueue[(FQueueOffset + Ind) mod OldLength] := Default(T);
          end;
          FQueueOffset := 0;
        end;
      end;
      SetLength(FQueue, NewLength);
    end
    else if ADelta > 0 then
    begin
      SetLength(FQueue, NewLength);
      PartialLength := OldLength - FQueueOffset;
      if FQueueSize > PartialLength then
      begin
        for Ind := OldLength - 1 downto FQueueOffset do
        begin
          FQueue[Ind + ADelta] := FQueue[Ind];
          FQueue[Ind] := Default(T);
        end;
        FQueueOffset := NewLength - PartialLength;
      end
    end;
  finally
    Unlock;
  end;
  SetEvent(FQueueNotFull);
end;

function TThreadedQueue<T>.PopItem: T;
var
  LQueueSize: Integer;
begin
  PopItem(LQueueSize, Result);
end;

function TThreadedQueue<T>.PopItem(var AQueueSize: Integer): T;
begin
  PopItem(AQueueSize, Result);
end;

function TThreadedQueue<T>.PopItem(var AQueueSize: Integer;
  var AItem: T): TWaitResult;
begin
  AItem := Default(T);
  Lock;
  try
    Result := wrSignaled;
    while (Result = wrSignaled) and (FQueueSize = 0) and not FShutDown do
    begin
      ResetEvent(FQueueNotEmpty);
      Unlock;
      if WaitForSingleObject(FQueueNotEmpty, FPopTimeout) = WAIT_TIMEOUT then
        Result := wrTimeout;
      Lock;
    end;

    if (FShutDown and (FQueueSize = 0)) or (Result <> wrSignaled) then
      Exit;

    AItem := FQueue[FQueueOffset];

    FQueue[FQueueOffset] := Default(T);

    Dec(FQueueSize);
    Inc(FQueueOffset);
    Inc(FTotalItemsPopped);

    if FQueueOffset = Length(FQueue) then
      FQueueOffset := 0;

  finally
    AQueueSize := FQueueSize;
    Unlock;
  end;

  SetEvent(FQueueNotFull);
end;

function TThreadedQueue<T>.PopItem(var AItem: T): TWaitResult;
var
  LQueueSize: Integer;
begin
  Result := PopItem(LQueueSize, AItem);
end;

function TThreadedQueue<T>.PushItem(const AItem: T;
  var AQueueSize: Integer): TWaitResult;
begin
  Lock;
  try
    Result := wrSignaled;
    while (Result = wrSignaled) and (FQueueSize = Length(FQueue)) and not FShutDown do
    begin
      ResetEvent(FQueueNotFull);
      Unlock;
      if WaitForSingleObject(FQueueNotFull, FPushTimeout) = WAIT_TIMEOUT then
        Result := wrTimeout;
      Lock;
    end;

    if FShutDown or (Result <> wrSignaled) then
      Exit;

    FQueue[(FQueueOffset + FQueueSize) mod Length(FQueue)] := AItem;
    Inc(FQueueSize);
    Inc(FTotalItemsPushed);
  finally
    AQueueSize := FQueueSize;
    Unlock;
  end;

  SetEvent(FQueueNotEmpty);
end;

function TThreadedQueue<T>.PushItem(const AItem: T): TWaitResult;
var
  LQueueSize: Integer;
begin
  Result := PushItem(AItem, LQueueSize);
end;

procedure TThreadedQueue<T>.Lock;
begin
  EnterCriticalSection(FQueueLock);
end;

procedure TThreadedQueue<T>.Unlock;
begin
  LeaveCriticalSection(FQueueLock);
end;

end.
