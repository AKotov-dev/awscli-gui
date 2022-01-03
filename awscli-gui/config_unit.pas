unit config_unit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons, Process, LCLType;

type

  { TConfigForm }

  TConfigForm = class(TForm)
    OkBtn: TBitBtn;
    CloseBtn: TBitBtn;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    procedure FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure OkBtnClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
  private

  public

  end;

var
  ConfigForm: TConfigForm;

implementation

uses unit1;

{$R *.lfm}

{ TConfigForm }

procedure TConfigForm.OkBtnClick(Sender: TObject);
var
  S: TStringList;
begin
  //Обновить правую панель, если подключение состоялось
  left_panel := False;
  //Каталог конфигураций aws
  if not DirectoryExists(GetUserDir + '.aws') then
    MkDir(GetUserDir + '.aws');

  //Делаем новые файлы конфигурации и сохраняем
  try
    S := TStringList.Create;
    S.Add('[default]');
    S.Add('aws_access_key_id=' + Trim(Edit1.Text));
    S.Add('aws_secret_access_key=' + Trim(Edit2.Text));
    S.SaveToFile(GetUserDir + '.aws/credentials');

    S.Clear;

    S.Add('[default]');
    S.Add('region=' + Trim(Edit3.Text));
    S.SaveToFile(GetUserDir + '.aws/config');

    S.Clear;

    S.Add('--endpoint-url=' + Trim(Edit4.Text));
    S.SaveToFile(GetUserDir + '.awscli-gui/endpoint_url');

    endpoint_url := S[0];

    //Отцепляем от конфигов, если занят
    MainForm.StartProcess('killall aws');

    //Проверяем подключение выводим ошибки в LogMemo
    MainForm.CheckConnect;
  finally
    S.Free;
  end;
end;

procedure TConfigForm.FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    ConfigForm.Close;
end;

procedure TConfigForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction := caFree;
end;

//Чтение параметров напрямую из ~/.s3cfg
procedure TConfigForm.FormShow(Sender: TObject);
var
  S: ansistring;
begin
  if FileExists(GetUserDir + '.aws/credentials') then
  begin
    if RunCommand('/bin/bash',
      ['-c', 'grep "aws_access_key_id=" ~/.aws/credentials | sed "s/aws_access_key_id=//"'],
      S) then
      Edit1.Text := Trim(S);

    if RunCommand('/bin/bash',
      ['-c', 'grep "aws_secret_access_key=" ~/.aws/credentials | sed "s/aws_secret_access_key=//"'],
      S) then
      Edit2.Text := Trim(S);
  end;

  if FileExists(GetUserDir + '.aws/config') then
    if RunCommand('/bin/bash',
      ['-c', 'grep "region=" ~/.aws/config | sed "s/region=//"'], S) then
      Edit3.Text := Trim(S);

  if FileExists(GetUserDir + '.awscli-gui/endpoint_url') then
    if RunCommand('/bin/bash',
      ['-c', 'grep "\-\-endpoint-url=" ~/.awscli-gui/endpoint_url | sed "s/--endpoint-url=//"'],
      S) then
      Edit4.Text := Trim(S);
end;

end.
