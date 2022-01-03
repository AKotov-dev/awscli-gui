unit acl_unit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  Buttons, LCLType, StrUtils;

type

  { TACLForm }

  TACLForm = class(TForm)
    OkBtn: TBitBtn;
    CloseBtn: TBitBtn;
    RadioGroup1: TRadioGroup;
    procedure FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure OkBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private

  public

  end;

var
  ACLForm: TACLForm;

implementation

uses unit1;

{$R *.lfm}

{ TACLForm }

//Публичный/Приватный (ACL)
procedure TACLForm.OkBtnClick(Sender: TObject);
var
  //  i: integer;
  i: longint;
  c, bucket_name, object_name: string;
const
  Delims = ['/'];
begin
  cmd := '';

  bucket_name := ExcludeTrailingPathDelimiter(MainForm.GroupBox2.Caption +
    MainForm.SDBox.Items[MainForm.SDBox.ItemIndex]);

  i := 6;
  bucket_name := ExtractSubstr(bucket_name, i, Delims);

  for i := 0 to MainForm.SDBox.Count - 1 do
  begin
    if MainForm.SDBox.Selected[i] then
    begin
      if RadioGroup1.ItemIndex = 0 then
      begin
        object_name := ExcludeTrailingPathDelimiter(MainForm.GroupBox2.Caption +
          MainForm.SDBox.Items[i]);
        object_name := Copy(object_name, Length(bucket_name) + 7, Length(object_name));

        if MainForm.GroupBox2.Caption <> 's3://' then
          c := 'aws s3api put-object-acl --bucket ' + bucket_name +
            ' --key "' + object_name + '" --acl public-read ' + endpoint_url
        else
          c := 'aws s3api put-bucket-acl --bucket ' + bucket_name +
            ' --acl public-read ' + endpoint_url;

        cmd := c + '; ' + cmd;
      end
      else
      begin
        object_name := ExcludeTrailingPathDelimiter(MainForm.GroupBox2.Caption +
          MainForm.SDBox.Items[i]);
        object_name := Copy(object_name, Length(bucket_name) + 7, Length(object_name));

        if MainForm.GroupBox2.Caption <> 's3://' then
          c := 'aws s3api put-object-acl --bucket ' + bucket_name +
            ' --key "' + object_name + '" --acl private ' + endpoint_url
        else
          c := 'aws s3api put-bucket-acl --bucket ' + bucket_name +
            ' --acl private ' + endpoint_url;

        cmd := c + '; ' + cmd;
      end;
    end;
  end;
  MainForm.StartCmd;
end;

procedure TACLForm.FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    ACLForm.Close;
end;

procedure TACLForm.FormCreate(Sender: TObject);
begin
  RadioGroup1.Items[0] := SPublicAccess;
  RadioGroup1.Items[1] := SPrivateAccess;
end;

procedure TACLForm.FormShow(Sender: TObject);
begin
  ACLForm.Height := OkBtn.Top + OkBtn.Height + 8;
end;

end.
