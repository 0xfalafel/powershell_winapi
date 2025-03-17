#region Module Builder
$Domain = [AppDomain]::CurrentDomain
$DynAssembly = New-Object System.Reflection.AssemblyName('TestAssembly')
# Only run in memory by specifying [System.Reflection.Emit.AssemblyBuilderAccess]::Run
$AssemblyBuilder = $Domain.DefineDynamicAssembly(
    $DynAssembly, 
    [System.Reflection.Emit.AssemblyBuilderAccess]::Run
) 
$ModuleBuilder = $AssemblyBuilder.DefineDynamicModule('BoxModule', $False)
#endregion Module Builder


#region DllImport
$TypeBuilder = $ModuleBuilder.DefineType('user32', 'Public, Class')

#region NtQueryInformationFile Method
$PInvokeMethod = $TypeBuilder.DefineMethod(
    'MessageBox', #Method Name
    [Reflection.MethodAttributes] 'PrivateScope, Public, Static, HideBySig, PinvokeImpl', #Method Attributes
    [Int], #Method Return Type
    [Type[]] @([IntPtr], [String], [String], [UInt32]) #Method Parameters
)


# Import the DLL

$DllImportConstructor = [Runtime.InteropServices.DllImportAttribute].GetConstructor(@([String]))
$FieldArray = [Reflection.FieldInfo[]] @(
    [Runtime.InteropServices.DllImportAttribute].GetField('EntryPoint'),
    [Runtime.InteropServices.DllImportAttribute].GetField('SetLastError')
)

$FieldValueArray = [Object[]] @(
    'MessageBox', #CASE SENSITIVE!!
    $True
)

$SetLastErrorCustomAttribute = New-Object Reflection.Emit.CustomAttributeBuilder(
    $DllImportConstructor,
    @('user32.dll'),
    $FieldArray,
    $FieldValueArray
)

$PInvokeMethod.SetCustomAttribute($SetLastErrorCustomAttribute)
[void]$TypeBuilder.CreateType()


[void] [user32]::MessageBox(0, "Hi mom!", "Greetings", 0)