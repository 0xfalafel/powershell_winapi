$MethodDefinition = @'

[DllImport("kernel32.dll", CharSet=CharSet.Unicode)]
public static extern bool CopyFile(string IpExistingFileName, string IpNewFileName, bool bFailIfExists);
'@

$Kernel32 = Add-Type -MemberDefinition $MethodDefinition -Name 'Kernel32' -Namespace 'Win32' -PassThru

# You may now call the CopyFile function

# Copy calc.exe to the user's desktop
$Kernel32::CopyFile("$($Env:SystemRoot)\System32\calc.exe", "$($Env:USERPROFILE)\Desktop\calc.exe", $False)