unit API.IO;

interface

uses
  System.Classes, System.SysUtils, {$IF CompilerVersion >= 27}System.JSON{$ELSE}Data.DBXJSON{$IFEND},
  API.Processor;

type

(******************************************************************************)

  TAPICommonRecorder = class(TCommonProcessor)
  private
    FFileName: TFileName;
    FFileStream: TFileStream;
  protected
    procedure SetData(const Value: TArray<IInterface>); override;
    property FileStream: TFileStream read FFileStream;
  public
    constructor Create(Owner: TComponent); override;
		destructor Destroy; override;
  published
    property FileName: TFileName read FFileName write FFileName;
  end;

(******************************************************************************)

  TAPITxtRecorder = class(TAPICommonRecorder)
  private
    FIsFirstData: boolean;
    FValueNames: TStrings;
    FDelimiter: string;
    FEncoding: TEncoding;
    FArrayDelimiter: string;
    FLineBreakReplacer: string;
    FLastLineInFile: string;
    FFirstLineInFile: string;

    function GetFieldPath(AValue: string): TArray<string>;
    function GetData(const AValue: IInterface): string;
    function GetStrValue(const AJSONValue: TJSONValue; const AFieldPath: TArray<string>): string;

    procedure Write(const Value: string);
    procedure WriteLine(const Value: string);

    procedure SetValueNames(const Value: TStrings);
  protected
    procedure SetData(const Value: TArray<IInterface>); override;
  public
    constructor Create(Owner: TComponent); override;
		destructor Destroy; override;
  published
    { Данные, которые хотим получить из объекта.
      Формат записи:
        first_name - получаем строкое представление
        career-group_id - получаем объект career и из него строковое представление group_id
    }
    property Encoding: TEncoding read FEncoding write FEncoding;
    property ValueNames: TStrings read FValueNames write SetValueNames;

    property Delimiter: string read FDelimiter write FDelimiter;
    property ArrayDelimiter: string read FArrayDelimiter write FArrayDelimiter;
    property LineBreakReplacer: string read FLineBreakReplacer write FLineBreakReplacer;
    property FirstLineInFile: string read FFirstLineInFile write FFirstLineInFile;
    property LastLineInFile: string read FLastLineInFile write FLastLineInFile;
  end;

implementation

uses
  StrUtils.Utils,
  API.Base;

{ TAPICommonRecorder }

constructor TAPICommonRecorder.Create(Owner: TComponent);
begin
  inherited;

  FFileStream := nil;
  FFileName := EmptyStr;
end;

destructor TAPICommonRecorder.Destroy;
begin
  if Assigned(FFileStream) then
    FreeAndNil(FFileStream);

  inherited;
end;

procedure TAPICommonRecorder.SetData(const Value: TArray<IInterface>);
begin
  inherited;

  if Enabled then
  begin
    try
      if not Assigned(FFileStream) then
      begin
        FFileStream := TFileStream.Create(FileName, fmCreate);
      end;
    except
      on E: Exception do
        DoOnError(E);
    end;
  end;
end;

{ TAPITxtRecorder }

constructor TAPITxtRecorder.Create(Owner: TComponent);
begin
  inherited;

  FIsFirstData := True;
  FValueNames := TStringList.Create;
  FDelimiter := '#';
  FArrayDelimiter := ',';
  FLineBreakReplacer := ' ';
  FFirstLineInFile := EmptyStr;
  FLastLineInFile := EmptyStr;
  FEncoding := TEncoding.Default;
end;

destructor TAPITxtRecorder.Destroy;
begin
  FreeAndNil(FValueNames);
  if Assigned(FFileStream) and not LastLineInFile.IsEmpty then
    WriteLine(LastLineInFile);

  inherited;
end;

function TAPITxtRecorder.GetData(const AValue: IInterface): string;
var
  BaseJSON: TBaseJSON;
  i: integer;
begin
  Result := EmptyStr;

  BaseJSON := TBaseJSON(AValue);

  for i := 0 to ValueNames.Count - 1 do
  begin
    if not Enabled then Exit;
    Result := Format('%s%s%s', [Result, Delimiter, GetStrValue(BaseJSON.GetJSON, GetFieldPath(ValueNames[i]))]);
  end;

  if Length(Result) > 0 then
    System.Delete(Result, 1, Length(Delimiter));
end;

function TAPITxtRecorder.GetFieldPath(AValue: string): TArray<string>;
var
  NewLength: integer;
  Idx: integer;
  Data: string;
begin
  NewLength := CountRecurrences('-', AValue);
  SetLength(Result, NewLength + 1);
  Idx := 0;
  while not AValue.IsEmpty do
  begin
    Data := SeparateLeft(AValue, '-');
    Result[Idx] := Data;
    Delete(AValue, 1, Length(Data) + 1);
    Inc(Idx);
  end;
end;

function TAPITxtRecorder.GetStrValue(const AJSONValue: TJSONValue;
  const AFieldPath: TArray<string>): string;
var
  LFieldPath: TArray<string>;
  i: Integer;
begin
  Result := EmptyStr;

  if not Assigned(AJSONValue) then Exit;

  if AJSONValue is TJSONArray then
  begin
    for i := 0 to (AJSONValue as TJSONArray).Size - 1 do
    begin
      Result := Format('%s%s%s', [Result, ArrayDelimiter, GetStrValue((AJSONValue as TJSONArray).Get(i), AFieldPath)]);
    end;

    if i > 0 then
      Delete(Result, 1, Length(ArrayDelimiter));
  end
  else if AJSONValue is TJSONObject then
  begin
    if Length(AFieldPath) > 0 then
    begin
      if Assigned((AJSONValue as TJSONObject).Get(AFieldPath[0])) then
        Result := GetStrValue((AJSONValue as TJSONObject).Get(AFieldPath[0]).JsonValue, Copy(AFieldPath, 1, Length(AFieldPath) - 1));
    end;
  end
  else
    Result := AJSONValue.Value;
end;

procedure TAPITxtRecorder.SetData(const Value: TArray<IInterface>);
var
  i: Integer;
  Line: string;
  StartTickCount: Cardinal;
begin
  inherited;

  if not Assigned(FileStream) then Exit;

  if FIsFirstData and not FirstLineInFile.IsEmpty then
    WriteLine(FirstLineInFile);

  try
    for i := 0 to Length(Value) - 1 do
    begin
      if not Enabled then Exit;

      DoChangeDataItem(Value[i]);
      try
        Line := GetData(Value[i]);
        Line := StringReplace(Line, #10, LineBreakReplacer, [rfReplaceAll]);

        if Length(Line) > 0 then
          WriteLine(Line);
      except
        on E: Exception do
          DoOnError(E);
      end;

      DoProcessedItem(Value[i]);
    end;
  finally
    DoChangeDataItem(nil);
  end;

  if Length(Value) > 0 then
    DataSource.UpdateConsumerData(Value);
end;

procedure TAPITxtRecorder.SetValueNames(const Value: TStrings);
begin
  FValueNames.Assign(Value);
end;

procedure TAPITxtRecorder.Write(const Value: string);
var Buffer: TBytes;
begin
  Buffer := FEncoding.GetBytes(Value);
  FFileStream.WriteBuffer(Buffer, Length(Buffer));
end;

procedure TAPITxtRecorder.WriteLine(const Value: string);
begin
  Write(Value + sLineBreak);
end;

end.
