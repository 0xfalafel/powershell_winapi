$Domain = [AppDomain]::CurrentDomain
$DynAssembly = New-Object System.Reflection.AssemblyName('TestAssembly')
$AssemblyBuilder = $Domain.DefineDynamicAssembly($DynAssembly, [System.Reflection.Emit.AssemblyBuilderAccess]::Run)
$ModuleBuilder = $AssemblyBuilder.DefineDynamicModule('TestModule', $False)

# Enum derived from 'wintnt.h'
$EnumBuilder = $ModuleBuilder.DefineEnum('IMAGE_DOS_SIGNATURE', 'Public', [UInt16])
# Define values of the enum
$EnumBuilder.DefineLiteral('DOS_SIGNATURE', [UInt16] 0x5A4D)
$EnumBuilder.DefineLiteral('OS2_SIGNATURE', [UInt16] 0x454E)
$EnumBuilder.DefineLiteral('OS2_SIGNATURE_LE', [UInt16] 0x454C)

$DosSigType = $EnumBuilder.CreateType()

# Struct derived from 'wintnt.h'
$Attributes = 'AutoLayout, AnsiClass, Class, Public, SequentialLayout, Sealed, BeforeFieldInit'
# There is no such thing as a DefineStruct type. So define a type with the attributes of a struct.
# A struct is essentially a class with no methods.
$TypeBuilder = $ModuleBuilder.DefineType('_IMAGE_DOS_HEADER', $Attributes, [System.ValueType], 1, 0x40)

$TypeBuilder.DefineField('e_magic', $DosSigType, 'Public') | Out-Null
$TypeBuilder.DefineField('e_cblp', [UInt16], 'Public') | Out-Null
$TypeBuilder.DefineField('e_cp', [UInt16], 'Public') | Out-Null
$TypeBuilder.DefineField('e_crlc', [UInt16], 'Public') | Out-Null
$TypeBuilder.DefineField('e_cparhdr', [UInt16], 'Public') | Out-Null
$TypeBuilder.DefineField('e_minalloc', [UInt16], 'Public') | Out-Null
$TypeBuilder.DefineField('e_maxalloc', [UInt16], 'Public') | Out-Null
$TypeBuilder.DefineField('e_ss', [UInt16], 'Public') | Out-Null
$TypeBuilder.DefineField('e_sp', [UInt16], 'Public') | Out-Null
$TypeBuilder.DefineField('e_csum', [UInt16], 'Public') | Out-Null
$TypeBuilder.DefineField('e_ip', [UInt16], 'Public') | Out-Null
$TypeBuilder.DefineField('e_cs', [UInt16], 'Public') | Out-Null
$TypeBuilder.DefineField('e_lfarlc', [UInt16], 'Public') | Out-Null
$TypeBuilder.DefineField('e_ovno', [UInt16], 'Public') | Out-Null
$e_resField = $TypeBuilder.DefineField('e_res', [String], 'Public, HasFieldMarshal')

$ConstructorInfo = [System.Runtime.InteropServices.MarshalAsAttribute].GetConstructors()[0]
$ConstructorValue = [System.Runtime.InteropServices.UnmanagedType]::ByValTStr
$FieldArray = @([System.Runtime.InteropServices.MarshalAsAttribute].GetField('SizeConst'))
$AttribBuilder = New-Object System.Reflection.Emit.CustomAttributeBuilder($ConstructorInfo, $ConstructorValue, $FieldArray, @([Int32] 8))
$e_resField.SetCustomAttribute($AttribBuilder)

$TypeBuilder.DefineField('e_oemid', [UInt16], 'Public') | Out-Null
$TypeBuilder.DefineField('e_oeminfo', [UInt16], 'Public') | Out-Null
$e_res2Field = $TypeBuilder.DefineField('e_res2', [UInt16[]], 'Public, HasFieldMarshal')

$ConstructorValue = [System.Runtime.InteropServices.UnmanagedType]::ByValArray
$AttribBuilder = New-Object System.Reflection.Emit.CustomAttributeBuilder($ConstructorInfo, $ConstructorValue, $FieldArray, @([Int32] 10))
$e_res2Field.SetCustomAttribute($AttribBuilder)

$TypeBuilder.DefineField('e_lfanew', [UInt32], 'Public') | Out-Null

$DosHeaderType = $TypeBuilder.CreateType()

[Byte[]] $Calc = [IO.File]::ReadAllBytes('C:\Windows\System32\calc.exe')
$Handle = [System.Runtime.InteropServices.GCHandle]::Alloc(([Byte[]] $Calc[0..0x40]), 'Pinned')
$PtrArray = $Handle.AddrOfPinnedObject()
$Handle.Free()

$DosHeader = [System.Runtime.InteropServices.Marshal]::PtrToStructure($PtrArray, $DosHeaderType)
$DosHeader
