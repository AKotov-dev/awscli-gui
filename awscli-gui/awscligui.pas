program awscligui;

{$mode objfpc}{$H+}

uses {$IFDEF UNIX}
  cthreads, {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms,
  Unit1,
  config_unit,
  about_unit,
  FirstConnectTRD,
  acl_unit { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Title := 'AwsCli-GUI v0.1';
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TACLForm, ACLForm);
  Application.Run;
end.
