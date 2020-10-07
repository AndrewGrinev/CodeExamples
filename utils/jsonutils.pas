unit jsonutils;

interface

uses System.Classes, System.SysUtils, {$IF CompilerVersion >= 27}System.JSON{$ELSE}Data.DBXJSON{$IFEND};

function SafeGetStringValue(aObj: TJSONObject; aPairName: string): string;
function SafeGetArrayToStringValue(aObj: TJSONObject; aPairName: string; aDelimiter: string = ','): string;
function SafeGetBooleanValue(aObj: TJSONObject; aPairName: string; Default: boolean = False): boolean;
function SafeGetIntegerValue(aObj: TJSONObject; aPairName: string): integer;
function SafeGetInt64Value(aObj: TJSONObject; aPairName: string): Int64;
function SafeGetDoubleValue(aObj: TJSONObject; aPairName: string): double;

{ Проверет, существует ли JSONValue по указанному пути }
function JsonValueByPathExists(aValue: TJSONValue; Path: string; Delimiter: Char = '/'): boolean;

function GetJSONValueByPath(aValue: TJSONValue; Path: string; Delimiter: Char = '/'): TJSONValue;
function GetStringValueByPath(aValue: TJSONValue; Path: string): string;

function BoolToJSONValue(Value: boolean): TJSONValue;
function StringsToJSONArray(Strings: TStrings): TJSONArray;

function CreateBooleanJSONValue(Value: boolean): TJSONValue;

function ToUTF8String(const AValue: TJSONValue): string;

implementation

uses
  synautil;

function SafeGetStringValue(aObj: TJSONObject; aPairName: string): string;
begin
  Result := '';

  if Assigned(aObj) and Assigned(aObj.Get(aPairName)) then
    Result := aObj.Get(aPairName).JsonValue.Value;
end;

function SafeGetArrayToStringValue(aObj: TJSONObject; aPairName: string; aDelimiter: string = ','): string;
var
  JSONArray: TJSONArray;
  i: Integer;
begin
  Result := EmptyStr;

  if Assigned(aObj) and Assigned(aObj.Get(aPairName)) and (aObj.Get(aPairName).JsonValue is TJSONArray) then
  begin
    JSONArray := aObj.Get(aPairName).JsonValue as TJSONArray;
    for i := 0 to JSONArray.Size - 1 do
      Result := Format('%s%s%s', [Result, aDelimiter, JSONArray.Get(i).Value]);

    Delete(Result, 1, Length(aDelimiter));
  end;
end;

function SafeGetBooleanValue(aObj: TJSONObject; aPairName: string; Default: boolean): boolean;
begin
  Result := Default;

  if Assigned(aObj) and Assigned(aObj.Get(aPairName)) then
  begin
    if aObj.Get(aPairName).JsonValue is TJSONTrue then
      Result := True;
  end;
end;

function SafeGetIntegerValue(aObj: TJSONObject; aPairName: string): integer;
begin
  Result := 0;

  if Assigned(aObj) and Assigned(aObj.Get(aPairName)) then
    Result := (aObj.Get(aPairName).JsonValue as TJSONNumber).AsInt;
end;

function SafeGetInt64Value(aObj: TJSONObject; aPairName: string): Int64;
begin
  Result := 0;

  if Assigned(aObj) and Assigned(aObj.Get(aPairName)) then
    Result := (aObj.Get(aPairName).JsonValue as TJSONNumber).AsInt64;
end;

function SafeGetDoubleValue(aObj: TJSONObject; aPairName: string): double;
var OldDecimalSeparator: Char;
    Value: string;
begin
  Result := 0;

  if Assigned(aObj) and Assigned(aObj.Get(aPairName)) then
  begin
    Value := SafeGetStringValue(aObj, aPairName);
    if Value = EmptyStr then Exit;
    
    OldDecimalSeparator := FormatSettings.DecimalSeparator;
    FormatSettings.DecimalSeparator := ',';
    if not TryStrToFloat(Value, Result) then
    begin
      FormatSettings.DecimalSeparator := '.';
      TryStrToFloat(Value, Result);
    end;
    FormatSettings.DecimalSeparator := OldDecimalSeparator;
  end;
end;

function JsonValueByPathExists(aValue: TJSONValue; Path: string; Delimiter: Char = '/'): boolean;
begin
  Result := Assigned(GetJSONValueByPath(aValue, Path, Delimiter));
end;

function GetJSONValueByPath(aValue: TJSONValue; Path: string; Delimiter: Char = '/'): TJSONValue;
var
  SL: TStringList;
  i: Integer;
  Value: integer;
  JSONValue: TJSONValue;
begin
  Result := nil;

  SL := TStringList.Create;
  try
    ParseParametersEx(Path, Delimiter, SL);

    JSONValue := aValue;

    for i := 0 to SL.Count - 1 do
    begin
      if TryStrToInt(SL[i], Value) then
      begin
        if JSONValue is TJSONObject then
        begin
          if Assigned((JSONValue as TJSONObject).Get(Value)) then
            JSONValue := (JSONValue as TJSONObject).Get(Value).JsonValue
          else Exit;
        end
        else if JSONValue is TJSONArray then
        begin
          if Assigned((JSONValue as TJSONArray).Get(Value)) then
            JSONValue := (JSONValue as TJSONArray).Get(Value)
          else Exit;
        end;
      end
      else
        if JSONValue is TJSONObject then
        begin
          if Assigned((JSONValue as TJSONObject).Get(SL[i])) then
            JSONValue := (JSONValue as TJSONObject).Get(SL[i]).JsonValue
          else Exit;
        end
        else Exit;
    end;

    Result := JSONValue;
  finally
    FreeAndNil(SL);
  end;
end;

function GetStringValueByPath(aValue: TJSONValue; Path: string): string;
begin
  Result := GetJSONValueByPath(aValue, Path).Value;
end;

function BoolToJSONValue(Value: boolean): TJSONValue;
begin
  if Value then
    Result := TJSONTrue.Create
  else
    Result := TJSONFalse.Create;
end;

function StringsToJSONArray(Strings: TStrings): TJSONArray;
var i: Integer;
begin
  Result := TJSONArray.Create;

  for i := 0 to Strings.Count - 1 do
    Result.Add(Strings[i]);
end;

function CreateBooleanJSONValue(Value: boolean): TJSONValue;
begin
  if Value then
    Result := TJSONTrue.Create
  else
    Result := TJSONFalse.Create;
end;

function ToUTF8String(const AValue: TJSONValue): string;
var Bytes: TBytes;
    Len: integer;
begin
  SetLength(Bytes, AValue.EstimatedByteSize);
  Len := AValue.ToBytes(Bytes, 0);
  Result := TEncoding.UTF8.GetString(Bytes, 0, Len);
end;

end.
