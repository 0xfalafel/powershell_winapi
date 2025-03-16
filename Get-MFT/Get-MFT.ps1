#region Module Builder
$Domain = [AppDomain]::CurrentDomain
$DynAssembly = New-Object System.Reflection.AssemblyName('TestAssembly')
# Only run in memory by specifying [System.Reflection.Emit.AssemblyBuilderAccess]::Run
$AssemblyBuilder = $Domain.DefineDynamicAssembly(
    $DynAssembly, 
    [System.Reflection.Emit.AssemblyBuilderAccess]::Run
) 
$ModuleBuilder = $AssemblyBuilder.DefineDynamicModule('TimeStampModule', $False)
#endregion Module Builder

#region STRUCTs

#region IOStatusBlock
#Define STRUCT
$Attributes = 'AutoLayout, AnsiClass, Class, Public, SequentialLayout, Sealed, BeforeFieldInit'
$TypeBuilder = $ModuleBuilder.DefineType('IOStatusBlock', $Attributes, [System.ValueType], 1, 0x40)
[void]$TypeBuilder.DefineField('status', [UInt64], 'Public')
[void]$TypeBuilder.DefineField('information', [UInt64], 'Public')

#Create STRUCT Type
[void]$TypeBuilder.CreateType()
#endregion IOStatusBlock

#region FileBasicInformation
#Define STRUCT
$Attributes = 'AutoLayout, AnsiClass, Class, ExplicitLayout, Sealed, BeforeFieldInit,public'
$TypeBuilder = $ModuleBuilder.DefineType('FileBasicInformation', $Attributes, [System.ValueType], 8, 0x28)
$CreateTimeField = $TypeBuilder.DefineField('CreationTime', [UInt64], 'Public')
$CreateTimeField.SetOffset(0)
$LastAccessTimeField = $TypeBuilder.DefineField('LastAccessTime', [UInt64], 'Public')
$LastAccessTimeField.SetOffset(8)
$LastWriteTimeField = $TypeBuilder.DefineField('LastWriteTime', [UInt64], 'Public')
$LastWriteTimeField.SetOffset(16)
$ChangeTimeField = $TypeBuilder.DefineField('ChangeTime', [UInt64], 'Public')
$ChangeTimeField.SetOffset(24)
$FileAttributesField = $TypeBuilder.DefineField('FileAttributes', [UInt64], 'Public')
$FileAttributesField.SetOffset(32)

#Create STRUCT Type
[void]$TypeBuilder.CreateType()
#endregion FileBasicInformation

#region ENUMs
$EnumBuilder = $ModuleBuilder.DefineEnum('FileInformationClass', 'Public', [UInt32])
# Define values of the enum
[void]$EnumBuilder.DefineLiteral('FileDirectoryInformation', [UInt32] 1)
[void]$EnumBuilder.DefineLiteral('FileBasicInformation', [UInt32] 4)
[void]$EnumBuilder.DefineLiteral('FileModeInformation', [UInt32] 16)
[void]$EnumBuilder.DefineLiteral('FileHardLinkInformation', [UInt32] 46)

#Create ENUM Type
[void]$EnumBuilder.CreateType()
#endregion ENUMs

#region DllImport
$TypeBuilder = $ModuleBuilder.DefineType('ntdll', 'Public, Class')

#region NtQueryInformationFile Method
$PInvokeMethod = $TypeBuilder.DefineMethod(
    'NtQueryInformationFile', #Method Name
    [Reflection.MethodAttributes] 'PrivateScope, Public, Static, HideBySig, PinvokeImpl', #Method Attributes
    [IntPtr], #Method Return Type
    [Type[]] @([Microsoft.Win32.SafeHandles.SafeFileHandle], [IOStatusBlock], [IntPtr] ,[UInt16], [FileInformationClass]) #Method Parameters
)

$DllImportConstructor = [Runtime.InteropServices.DllImportAttribute].GetConstructor(@([String]))
$FieldArray = [Reflection.FieldInfo[]] @(
    [Runtime.InteropServices.DllImportAttribute].GetField('EntryPoint'),
    [Runtime.InteropServices.DllImportAttribute].GetField('SetLastError')
)

$FieldValueArray = [Object[]] @(
    'NtQueryInformationFile', #CASE SENSITIVE!!
    $True
)

$SetLastErrorCustomAttribute = New-Object Reflection.Emit.CustomAttributeBuilder(
    $DllImportConstructor,
    @('ntdll.dll'),
    $FieldArray,
    $FieldValueArray
)

$PInvokeMethod.SetCustomAttribute($SetLastErrorCustomAttribute)
#endregion NtQueryInformationFile Method

[void]$TypeBuilder.CreateType()
#endregion DllImport

$fbi = New-Object "FileBasicInformation"
$iosb = New-Object "IOStatusBlock"

$FileStream = [System.IO.File]::Open("C:\Users\olivier\Desktop\test.txt",'Open','Read','ReadWrite')

$p_fbi = [System.Runtime.InteropServices.Marshal]::AllocHGlobal([System.Runtime.InteropServices.Marshal]::SizeOf($fbi))

$iprc = [ntdll]::NtQueryInformationFile($FileStream.SafeFileHandle, $iosb, $p_fbi, 
    [System.Runtime.InteropServices.Marshal]::SizeOf($fbi), [FileInformationClass]::FileBasicInformation
)

# Check to make sure no issues occurred
$IsOK = (($iprc -eq [intptr]::Zero) -AND ($iosb.status -eq 0))

If ($IsOK) {
    # Pull data from unmanaged memory block into a usable object
    $fbi = [System.Runtime.InteropServices.Marshal]::PtrToStructure($p_fbi, [System.Type][FileBasicInformation])
    $Object = [pscustomobject]@{
        FullName = $FileStream.Name
        CreationTime = [datetime]::FromFileTime($fbi.CreationTime)
        LastAccessTime = [datetime]::FromFileTime($fbi.LastAccessTime)
        LastWriteTime = [datetime]::FromFileTime($fbi.LastWriteTime)
        ChangeTime = [datetime]::FromFileTime($fbi.ChangeTime)
    }
    $Object.PSTypeNames.Insert(0,'System.Io.FileTimeStamp')
    Write-Output $Object
} Else {
    Write-Warning "$($Item): $(New-Object ComponentModel.Win32Exception)"
}
#region Perform Cleanup
$FileStream.Close()
# Deallocate memory
If ($p_fbi -ne [intptr]::Zero) {
    [System.Runtime.InteropServices.Marshal]::FreeHGlobal($p_fbi)
}