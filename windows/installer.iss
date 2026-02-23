#define AppName "UtopiaScoreboard"
#define AppVersion "1.0.0"
#define AppPublisher "UtopiaXC"
#define AppURL "https://github.com/UtopiaXC/UtopiaScoreboard"

#define MyAppExeName "UtopiaScoreboard.exe"

[Setup]
AppId={{263b7370-f52e-4b0f-88eb-b0deb3089009}}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}
AppUpdatesURL={#AppURL}
PrivilegesRequired=lowest
DefaultDirName={autopf}\{#AppName}
OutputBaseFilename=UtopiaScoreboard_{#AppVersion}_Windows_x64_setup
Compression=lzma
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64
DisableProgramGroupPage=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\build\windows\x64\runner\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(AppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent