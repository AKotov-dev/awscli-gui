unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ShellCtrls, Buttons, ComCtrls, IniPropStorage, Types, Process,
  LCLType, DefaultTranslator;

type

  { TMainForm }

  TMainForm = class(TForm)
    ACLBtn: TSpeedButton;
    CompDir: TShellTreeView;
    SettingsBtn: TSpeedButton;
    CopyFromPC: TSpeedButton;
    CopyFromBucket: TSpeedButton;
    DelBtn: TSpeedButton;
    AddBtn: TSpeedButton;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    ImageList1: TImageList;
    IniPropStorage1: TIniPropStorage;
    MkPCDirBtn: TSpeedButton;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    ProgressBar1: TProgressBar;
    UpdateBtn: TSpeedButton;
    SDBox: TListBox;
    LogMemo: TMemo;
    SelectAllBtn: TSpeedButton;
    InfoBtn: TSpeedButton;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    UpBtn: TSpeedButton;
    procedure ACLBtnClick(Sender: TObject);
    procedure AddBtnClick(Sender: TObject);
    procedure CompDirGetImageIndex(Sender: TObject; Node: TTreeNode);
    procedure CopyFromBucketClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure InfoBtnClick(Sender: TObject);
    procedure SettingsBtnClick(Sender: TObject);
    procedure CopyFromPCClick(Sender: TObject);
    procedure DelBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure MkPCDirBtnClick(Sender: TObject);
    procedure UpdateBtnClick(Sender: TObject);
    procedure CompDirUpdate;
    procedure SDBoxDblClick(Sender: TObject);
    procedure SDBoxDrawItem(Control: TWinControl; Index: integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure SelectAllBtnClick(Sender: TObject);
    procedure StartProcess(command: string);
    procedure StartLS;
    procedure StartCmd;
    procedure UpBtnClick(Sender: TObject);
    procedure ReadS3Root;
    procedure CheckConnect;

  private

  public

  end;

var
  left_panel: boolean;
  cmd, endpoint_url: string;

resourcestring
  SDelete = 'Delete selected object(s)?';
  SOverwriteObject = 'Overwrite existing objects?';
  SObjectExists = 'The folder already exists!';
  SCreateDir = 'Create directory';
  SInputName = 'Enter the name:';
  SCancelCopyng = 'Esc - cancel... ';
  SCloseQuery = 'Copying is in progress! Finish the process?';
  SPublicAccess = 'Public access [READ, objects, --acl public-read]';
  SPrivateAccess = 'Private access [READ, objects, --acl private]';
  SNewBucket = 'Create new private Bucket';
  SBucketName = 'Bucket name:';

var
  MainForm: TMainForm;

implementation

uses config_unit, about_unit, lsfoldertrd, S3CommandTRD, FirstConnectTRD, acl_unit;

{$R *.lfm}

{ TMainForm }

//Ошибки первого подключения
procedure TMainForm.CheckConnect;
var
  FStartFirstConnect: TThread;
begin
  FStartFirstConnect := StartFirstConnect.Create(False);
  FStartFirstConnect.Priority := tpHighest; //tpHigher
end;

//Чтение корня хранилища
procedure TMainForm.ReadS3Root;
begin
  GroupBox2.Caption := 's3://';
  StartLS;
end;

//ls в директории s3:// (SDBox)
procedure TMainForm.StartCmd;
var
  FStartCmdThread: TThread;
begin
  FStartCmdThread := StartS3Command.Create(False);
  FStartCmdThread.Priority := tpHighest; //tpHigher
end;

//ls в директории s3:// (SDBox)
procedure TMainForm.StartLS;
var
  FLSFolderThread: TThread;
begin
  FLSFolderThread := StartLSFolder.Create(False);
  FLSFolderThread.Priority := tpHighest; //tpHigher
end;

//Уровень вверх
procedure TMainForm.UpBtnClick(Sender: TObject);
var
  i: integer;
begin
  if GroupBox2.Caption <> 's3://' then

  begin
    for i := Length(GroupBox2.Caption) - 1 downto 1 do
      if GroupBox2.Caption[i] = '/' then
      begin
        GroupBox2.Caption := Copy(GroupBox2.Caption, 1, i);
        break;
      end;
  end;
  //Чтение текущей директории
  StartLS;
end;

//StartCommand (служебные команды)
procedure TMainForm.StartProcess(command: string);
var
  ExProcess: TProcess;
begin
  try
    ExProcess := TProcess.Create(nil);
    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');
    ExProcess.Parameters.Add(command);
    ExProcess.Options := [poWaitOnExit, poUsePipes];
    ExProcess.Execute;
  finally
    ExProcess.Free;
  end;
end;

//Апдейт текущей директории CompDir (ShellTreeView)
procedure TMainForm.CompDirUpdate;
var
  i: integer; //Абсолютный индекс выделенного
  d: string; //Выделенная директория
begin
  try
    //Запоминаем позицию курсора
    i := CompDir.Selected.AbsoluteIndex;
    d := ExtractFilePath(CompDir.GetPathFromNode(CompDir.Selected));

    //Обновляем  выбранного родителя
    with CompDir do
      Refresh(Selected.Parent);

    //Курсор на созданную папку
    CompDir.Path := d;
    CompDir.Select(CompDir.Items[i]);
    CompDir.SetFocus;
  except;
    //Если сбой - перечитать корень
    UpdateBtn.Click;
  end;
end;

//Сменить директорию облака (s3://.../..)
procedure TMainForm.SDBoxDblClick(Sender: TObject);
begin
  if SDBox.Count <> 0 then
  begin
   { if GroupBox2.Caption = 's3://' then
      GroupBox2.Caption := ' ';}

    if (Pos('//', SDBox.Items.Strings[SDBox.ItemIndex]) <> 0) or
      (Copy(SDBox.Items.Strings[SDBox.ItemIndex],
      Length(SDBox.Items.Strings[SDBox.ItemIndex]), 1) = '/') then
    begin
      GroupBox2.Caption := Trim(IncludeTrailingPathDelimiter(GroupBox2.Caption +
        SDBox.Items[SDBox.ItemIndex]));
      StartLS;
    end;
  end;
end;

//Прорисовка иконок панели 's3://'
procedure TMainForm.SDBoxDrawItem(Control: TWinControl; Index: integer;
  ARect: TRect; State: TOwnerDrawState);
var
  BitMap: TBitMap;
begin
  BitMap := TBitMap.Create;
  try
    ImageList1.GetBitMap(0, BitMap);

    with SDBox do
    begin
      Canvas.FillRect(aRect);
      //Вывод текста со сдвигом (общий)
      //Сверху иконки взависимости от последнего символа ('/')
      if (Pos('//', Items[Index]) <> 0) or
        (Copy(Items[Index], Length(Items[Index]), 1) = '/') then
      begin
        //Имя папки
        Canvas.TextOut(aRect.Left + 27, aRect.Top + 5, Items[Index]);
        //Иконка папки
        ImageList1.GetBitMap(0, BitMap);
        Canvas.Draw(aRect.Left + 2, aRect.Top + 2, BitMap);
      end
      else
      begin
        //Имя файла
        Canvas.TextOut(aRect.Left + 27, aRect.Top + 5, Items[Index]);
        //Иконка файла
        ImageList1.GetBitMap(1, BitMap);
        Canvas.Draw(aRect.Left + 2, aRect.Top + 2, BitMap);
      end;
    end;
  finally
    BitMap.Free;
  end;
end;

//Выделить всё
procedure TMainForm.SelectAllBtnClick(Sender: TObject);
begin
  if GroupBox2.Caption <> 's3://' then
    SDBox.SelectAll;
end;

//Подстановка иконок папка/файл в ShellTreeView
procedure TMainForm.CompDirGetImageIndex(Sender: TObject; Node: TTreeNode);
begin
  if FileGetAttr(CompDir.GetPathFromNode(node)) and faDirectory <> 0 then
    Node.ImageIndex := 0
  else
    Node.ImageIndex := 1;
  Node.SelectedIndex := Node.ImageIndex;
end;

//Копирование из облака на компьютер
procedure TMainForm.CopyFromBucketClick(Sender: TObject);
var
  i: integer;
  c: string;
  e: boolean;
begin
  //Флаг выбора панели
  left_panel := True;

  c := '';
  cmd := '';  //Команда
  e := False; //Флаг совпадения файлов/папок (перезапись)

  if (SDBox.SelCount <> 0) and (GroupBox2.Caption <> 's3://') then
  begin
    for i := 0 to SDBox.Count - 1 do
    begin
      if SDBox.Selected[i] then
      begin
        if not e then
          if (FileExists(ExtractFilePath(CompDir.GetPathFromNode(CompDir.Selected)) +
            SDBox.Items[i]) or (DirectoryExists(
            ExtractFilePath(CompDir.GetPathFromNode(CompDir.Selected)) +
            SDBox.Items[i]))) then
            e := True;

        if Pos('/', SDBox.Items[i]) <> 0 then
          c := 'aws ' + endpoint_url + ' s3 cp --recursive ' +
            '''' + ExcludeTrailingPathDelimiter(GroupBox2.Caption + SDBox.Items[i]) +
            '''' + ' ' + '''' + ExtractFilePath(CompDir.GetPathFromNode(
            CompDir.Selected)) + SDBox.Items[i] + ''''
        else
          c := 'aws ' + endpoint_url + ' s3 cp ' + '''' +
            ExcludeTrailingPathDelimiter(GroupBox2.Caption + SDBox.Items[i]) +
            '''' + ' ' + '''' + ExtractFilePath(CompDir.GetPathFromNode(
            CompDir.Selected)) + SDBox.Items[i] + '''';

        cmd := c + '; ' + cmd;
      end;
    end;

    //Если есть совпадения (перезапись файлов)
    if e and (MessageDlg(SOverwriteObject, mtConfirmation, [mbYes, mbNo], 0) <>
      mrYes) then
      exit;

    StartCmd;
  end;
end;

//Предупреждение о завершении обмена с облаком, если в прогрессе
procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  if cmd <> '' then
    if MessageDlg(SCloseQuery, mtWarning, [mbYes, mbCancel], 0) <> mrYes then
      Canclose := False
    else
    begin
      StartProcess('killall aws');
      CanClose := True;
    end;
end;

//Esc - отмена операций
procedure TMainForm.FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  if key = VK_ESCAPE then
  begin
    //Если копирование выполняется - отменяем
    if cmd <> '' then
    begin
      StartProcess('killall aws');
      LogMemo.Append('AWScli-GUI: Esc - Cancellation of the operation...');
    end;
  end;
end;

//Форма About
procedure TMainForm.InfoBtnClick(Sender: TObject);
begin
  AboutForm := TAboutForm.Create(Application);
  AboutForm.ShowModal;
end;

//Создание нового бакета
procedure TMainForm.AddBtnClick(Sender: TObject);
var
  S: string;
begin
  S := '';
  repeat
    if not InputQuery(SNewBucket, SBucketName, S) then
      Exit
  until S <> '';

  cmd := 'aws ' + endpoint_url + ' s3 mb s3://' + Trim(S);

  left_panel := False;

  //Создаём новый бакет и показываем список бакетов 's3://'
  MainForm.GroupBox2.Caption := 's3://';
  MainForm.StartCmd;
end;

//Публичный/Приватный объект(ы)
procedure TMainForm.ACLBtnClick(Sender: TObject);
begin
  if (SDBox.SelCount <> 0) and ((Pos('/', SDBox.Items[SDBox.ItemIndex]) = 0) or
    (GroupBox2.Caption = 's3://')) then
    ACLForm.ShowModal;
end;

//Форма конфигурации ~/.s3cfg
procedure TMainForm.SettingsBtnClick(Sender: TObject);
begin
  ConfigForm := TConfigForm.Create(Application);
  ConfigForm.ShowModal;
end;

//Копирование с компа в облако (файлы и папки без пробелов)
procedure TMainForm.CopyFromPCClick(Sender: TObject);
var
  i, sd: integer;
  c: string;
  e: boolean;
begin
  //Флаг выбора панели
  left_panel := False;
  //Сборка единой команды
  c := '';
  //Флаг совпадения имени
  e := False;
  //Команда
  cmd := '';

  //Если выбрано и выбран не корень и копируем не в корень облака (s3://)
  if (CompDir.Items.SelectionCount <> 0) and (not CompDir.Items.Item[0].Selected) and
    (GroupBox2.Caption <> 's3://') then
  begin
    for i := 0 to CompDir.Items.Count - 1 do
    begin
      if CompDir.Items[i].Selected then
      begin
        //Ищем совпадения (перезапись объектов)
        if not e then
          for sd := 0 to SDBox.Count - 1 do
          begin
            if CompDir.Items[i].Text = ExcludeTrailingPathDelimiter(
              SDBox.Items[sd]) then
              e := True;
          end;

        if DirectoryExists(CompDir.Items[i].GetTextPath) then
          c := 'aws ' + endpoint_url + ' s3 cp --recursive ' + '''' +
            CompDir.Items[i].GetTextPath + '''' + ' ' + '''' +
            ExcludeTrailingPathDelimiter(GroupBox2.Caption +
            ExtractFileName(CompDir.Items[i].GetTextPath)) + ''''
        else
          c := 'aws ' + endpoint_url + ' s3 cp ' + '''' +
            CompDir.Items[i].GetTextPath + '''' + ' ' + '''' +
            ExcludeTrailingPathDelimiter(GroupBox2.Caption +
            ExtractFileName(CompDir.Items[i].GetTextPath)) + '''';

        cmd := c + '; ' + cmd;
      end;
    end;

    //Если есть совпадения (перезапись файлов)
    if e and (MessageDlg(SOverwriteObject, mtConfirmation, [mbYes, mbNo], 0) <>
      mrYes) then
      exit;

    StartCmd;
  end;
end;

//Удаление объекта(ов)
procedure TMainForm.DelBtnClick(Sender: TObject);
var
  i: integer;
  c: string; //сборка команд...
begin
  //Удаление файлов, папок и бакетов с незавершенными загрузками
  if (SDBox.SelCount = 0) or (MessageDlg(SDelete, mtConfirmation, [mbYes, mbNo], 0) <>
    mrYes) then
    exit;

  //Команда в поток
  cmd := '';
  //Сборка команды
  c := '';

  //Флаг выбора панели
  left_panel := False;

  if GroupBox2.Caption <> 's3://' then
  begin
    for i := 0 to SDBox.Count - 1 do
    begin
      if SDBox.Selected[i] then
      begin
        if Pos('/', SDBox.Items[i]) <> 0 then
          c := 'aws ' + endpoint_url + ' s3 rm --recursive ' +
            '''' + GroupBox2.Caption + SDBox.Items[i] + ''''
        else
          c := 'aws ' + endpoint_url + ' s3 rm ' + '''' +
            GroupBox2.Caption + SDBox.Items[i] + '''';

        //Собираем команду
        cmd := c + '; ' + cmd;
      end;
    end;
    StartCmd;
  end
  else
    //Удаление бакета и его незавершенных загрузок (очистка/удаление)
  begin
    cmd := 'aws ' + endpoint_url + ' s3api list-multipart-uploads --bucket ' +
      ExcludeTrailingPathDelimiter(SDBox.Items[SDBox.ItemIndex]) +
      ' | grep -E "\"Key\":|\"UploadId\":" | cut -d ":" -f2 | tr -d "," | sed "s/^ *//" > ~/.awscli-gui/111;'
      + 'rm -f ~/.awscli-gui/{222,333}; a=0;' + 'while read keyid; do ' +
      '[[ $(expr $a % 2) != "1" ]] && echo "$keyid" >> ~/.awscli-gui/333 || echo "$keyid" >> ~/.awscli-gui/222;'
      + 'let a++; done < ~/.awscli-gui/111; [[ -f ~/.awscli-gui/222 ]] && paste ~/.awscli-gui/{222,333} > ~/.awscli-gui/111;'
      + 'echo -e "#!/bin/bash\n" > ~/.awscli-gui/rm_backet;' +
      'while read keyid; do ' +
      'echo -e "echo remove multipart upload: $(echo "$keyid" | cut -f1) $(echo "$keyid" | cut -f2);\n" >> ~/.awscli-gui/rm_backet'
      + 'echo "aws --endpoint-url=https://storage.yandexcloud.net s3api abort-multipart-upload --bucket '
      + ExcludeTrailingPathDelimiter(SDBox.Items[SDBox.ItemIndex]) +
      ' --key $(echo "$keyid" | cut -f1) --upload-id $(echo "$keyid" | cut -f2);" >> ~/.awscli-gui/rm_backet;'
      + 'done < ~/.awscli-gui/111;' + 'echo "aws ' + endpoint_url +
      ' s3 rb --force ' + GroupBox2.Caption + ExcludeTrailingPathDelimiter(
      SDBox.Items[SDBox.ItemIndex]) + ';" >> ~/.awscli-gui/rm_backet;' +
      'chmod +x ~/.awscli-gui/rm_backet; sh ~/.awscli-gui/rm_backet';

    //Выполняем скрипт в потоке с индикацией
    StartCmd;
  end;
end;

//Домашняя папка юзера - корень
procedure TMainForm.FormCreate(Sender: TObject);
var
  S: ansistring;
begin
  //Очищаем переменную команды для потока
  cmd := '';

  CompDir.Root := ExcludeTrailingPathDelimiter(GetUserDir);
  CompDir.Items.Item[0].Selected := True;

  //Рабочая директория ~/.s3cmd-gui
  if not DirectoryExists(GetUserDir + '.awscli-gui') then
    MkDir(GetUserDir + '.awscli-gui');

  IniPropStorage1.IniFileName := GetUserDir + '.awscli-gui/awscli-gui.conf';

  //Переменная endpoint_url
  if FileExists(GetUserDir + '.awscli-gui/endpoint_url') then
    if RunCommand('/bin/bash', ['-c', 'cat ~/.awscli-gui/endpoint_url | head -n1'],
      S) then
      endpoint_url := Trim(S);
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  MainForm.Caption := Application.Title;
  IniPropStorage1.Restore;

  //Коррекция размеров при масштабировании в Plasma
  Panel3.Height := CopyFromPC.Height + 14;
  Panel4.Height := Panel3.Height;

  //Проверяем подключение выводим ошибки в LogMemo = StartLS (s3://)
  MainForm.CheckConnect;
end;

//Создать каталог на компьютере
procedure TMainForm.MkPCDirBtnClick(Sender: TObject);
var
  S: string;
begin
  //Флаг выбора панели
  left_panel := False;

  S := '';
  repeat
    if not InputQuery(SCreateDir, SInputName, S) then
      Exit
  until S <> '';

  //Если есть совпадения (перезапись файлов)
  if DirectoryExists(IncludeTrailingPathDelimiter(
    ExtractFilePath(CompDir.GetPathFromNode(CompDir.Selected))) + S) then
  begin
    MessageDlg(SObjectExists, mtWarning, [mbOK], 0);
    Exit;
  end;
  //Создаём директорию
  MkDir(IncludeTrailingPathDelimiter(
    ExtractFilePath(CompDir.GetPathFromNode(CompDir.Selected))) + S);

  //Обновляем содержимое выделенного нода
  CompDirUpdate;
end;

//Перечитываем домашнюю папку на компьютере
procedure TMainForm.UpdateBtnClick(Sender: TObject);
begin
  with CompDir do
  begin
    Select(CompDir.TopItem, [ssCtrl]);
    Refresh(CompDir.Selected.Parent);
    Select(CompDir.TopItem, [ssCtrl]);
    SetFocus;
  end;
end;

end.
