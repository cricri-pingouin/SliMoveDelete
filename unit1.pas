Unit unit1;

Interface

Uses
  Windows, SysUtils, Forms, Dialogs, ShellApi, StdCtrls, Classes, Controls;

Type
  TMainForm = Class(TForm)
    lblList: TLabel;
    cmbList: TComboBox;
    lblExtension: TLabel;
    cmbExtension: TComboBox;
    lblAction: TLabel;
    RadioButton1: TRadioButton;
    RadioButton2: TRadioButton;
    RadioButton3: TRadioButton;
    RadioButton4: TRadioButton;
    txtFolder: TEdit;
    cmdGo: TButton;
    txtPasses: TEdit;
    Procedure FormCreate(Sender: TObject);
    Procedure cmdGoClick(Sender: TObject);
  End;

Var
  MainForm: TMainForm;

Implementation

{$R *.dfm}

Procedure WipeFile(filename: String; Passes: Integer);
Var
  buffer: Array[0..4095] Of byte;
  max, n: LongInt;
  i: Integer;
  fs: TFileStream;

  Procedure RandomizeBuffer;
  Var
    i: Integer;
  Begin
    For i := Low(buffer) To High(buffer) Do
      buffer[i] := Random(256);
  End;

Begin
  fs := TFilestream.Create(filename, fmOpenReadWrite Or fmShareExclusive);
  Try
    For i := 1 To Passes Do
    Begin
      RandomizeBuffer;
      max := fs.Size;
      fs.Position := 0;
      While max > 0 Do
      Begin
        If max > Sizeof(buffer) Then
          n := sizeof(buffer)
        Else
          n := max;
        fs.Write(buffer, n);
        max := max - n;
      End;
      FlushFileBuffers(fs.handle);
    End;
  Finally
    fs.free;
  End;
  Deletefile(filename);
End;

Function RecycleFile(FileName: String): boolean;
Var
  Struct: TSHFileOpStruct;
  pFromc: Array[0..255] Of char;
  Resultval: integer;
Begin
  If Not FileExists(FileName) Then
  Begin
    Result := False;
    exit;
  End
  Else
  Begin
    fillchar(pFromc, sizeof(pFromc), 0);
    StrPcopy(pFromc, expandfilename(FileName) + #0#0);
    Struct.wnd := 0;
    Struct.wFunc := FO_DELETE;
    Struct.pFrom := pFromc;
    Struct.pTo := nil;
    Struct.fFlags := FOF_ALLOWUNDO Or FOF_NOCONFIRMATION Or FOF_SILENT;
    Struct.fAnyOperationsAborted := false;
    Struct.hNameMappings := nil;
    Resultval := ShFileOperation(Struct);
    Result := (Resultval = 0);
  End;
End;

Function FileCount(FileFilter: String): Integer;
Var
  SearchRec: TSearchRec;
Begin
  Result := 0;
  If FindFirst(FileFilter, faAnyFile, SearchRec) = 0 Then
    Repeat
      If SearchRec.Attr <> faDirectory Then
        Inc(Result);
    Until FindNext(SearchRec) <> 0;
End;

Procedure TMainForm.FormCreate(Sender: TObject);
Var
  SRec: TSearchRec;
  FilesExtensions: TStringList;
  i, CurrCount, MaxCount, MaxIndex: Integer;
Begin
  //Populate list of text files
  cmblist.Clear;
  Try
    If FindFirst('*.txt', faAnyfile, SRec) = 0 Then
      Repeat
        cmbList.AddItem(SRec.Name, nil);
      Until FindNext(SRec) <> 0;
  Finally
    FindClose(SRec)
  End;
  If (cmbList.Items.Count = 0) Then
  Begin
    showmessage('No text files found!' + sLineBreak + 'A text file is needed as source.' + sLineBreak + 'The program will now exit.');
    cmdGo.Enabled := False;
    Application.Terminate;
    exit;
  End;
  //Populate list of extensions
  cmbList.ItemIndex := 0;
  FilesExtensions := TStringList.Create;
  FilesExtensions.Sorted := True;
  FilesExtensions.Duplicates := dupIgnore;
  cmbExtension.Clear;
  Try
    If FindFirst('*.*', faAnyfile - faDirectory, SRec) = 0 Then
      Repeat
        FilesExtensions.add(ExtractFileExt(SRec.Name));
      Until FindNext(SRec) <> 0;
  Finally
    FindClose(SRec)
  End;
  MaxCount := 0;
  MaxIndex := 0;
  For i := 0 To FilesExtensions.Count - 1 Do
  Begin
    CurrCount := FileCount('*' + FilesExtensions[i]);
    //Identify most common extension
    If CurrCount > MaxCount Then
    Begin
      MaxCount := CurrCount;
      MaxIndex := i;
    End;
    cmbExtension.AddItem(FilesExtensions[i], nil);
  End;
  //Select most common
  cmbExtension.ItemIndex := MaxIndex;
End;

Procedure TMainForm.cmdGoClick(Sender: TObject);
Var
  fileData: TStringList;
  i, FilesFound, FilesNotFound: Integer;
  ThisFile: PChar;
  FileOpStruc: TSHFileOpStruct;
  Path: String;
Begin
  Path := IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName));
  //Create list of names from selected file
  fileData := TStringList.Create;
  fileData.LoadFromFile(Path + cmblist.Text);
  //Create backup folder
  If RadioButton4.Checked Then
    ForceDirectories(Path + txtFolder.Text);
  FilesFound := 0;
  FilesNotFound := 0;
  For i := 0 To fileData.Count - 1 Do
  Begin
    ThisFile := PChar(Path + fileData[i] + cmbExtension.Text);
    If fileexists(ThisFile) Then
    Begin
      inc(FilesFound);
      If RadioButton1.Checked Then
        RecycleFile(ThisFile) //Send to Recycle Bin
      Else If RadioButton2.Checked Then
        DeleteFile(ThisFile) //Delete permanently
      Else If RadioButton3.Checked Then
        WipeFile(ThisFile, StrToInt(txtPasses.Text)) //Shred
      Else If RadioButton4.Checked Then
        MoveFile(ThisFile, PChar(Path + txtFolder.Text + '\' + fileData[i] + cmbExtension.Text));  //Move to backup folder
    End
    Else
      inc(FilesNotFound);
  End;
  showmessage('Number of files found and processed: ' + IntToStr(FilesFound) + sLineBreak + 'Number of files not found and skipped: ' + IntToStr(FilesNotFound));
End;

End.

