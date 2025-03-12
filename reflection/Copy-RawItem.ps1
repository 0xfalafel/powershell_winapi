function Copy-RawItem
{
# Reference:
# https://devblogs.microsoft.com/scripting/use-powershell-to-interact-with-the-windows-api-part-3/

<#
	.SYNOPSIS
	Copies a file from on location to another including files contained within DeviceObject paths.

	.PARAMETER Path
	Specifies the path to the file to copy.

	.PARAMETER Destination
	Specifies the path to the location where the item is to be copied.

	.PARAMETER FailIfExists
	Do not copy the file if it already exists in the specified destination.

	.OUTPUTS
	None or an object representing the copied item.

	.EXAMPLE
	Copy-RawItem '\\?\GLOBALROOT\Device\HarddiskVolumeShadowCopy2\Windows\System32\config\SAM' 'C:\temp\SAM'
#>

	[CmdletBinding()]
	[OutputType([System.IO.FileSystemInfo])]
	Param (
		[Parameter(Mandatory=$True, Position=0)]
		[ValidateNotNullOrEmpty()]
		[String]
		$Path,

		[Parameter(Mandatory=$True, Position=1)]
		[ValidateNotNullOrEmpty()]
		[String]
		$Destination,

		[Switch]
		$FailIfExists
	)

	# Create a new dynamic assembly. An assembly (typically a dll file) is the container for modules
	$DynAssembly = New-Object System.Reflection.AssemblyName('Win32Lib')

	# Define the assembly and tell it to remain in memory only(via [Reflection.Emit.AssemblyBuilderAccess]::Run)
	$AssemblyBuilder = [AppDomain]::CurrentDomain.DefineDynamicAssembly($DynAssembly, [Reflection.Emit.AssemblyBuilderAccess]::Run)

	# Define a new dynamic module. A module is the container for types (a.k.a classes)
	$ModuleBuilder = $AssemblyBuilder.DefineDynamicModule('Win32Lib', $False)

	# Define a new type (class). This class will contain our method - CopyFile
	# I'm naming it 'Kernel32' so that you will be able to call CopyFile like this:
	# [Kernel32]::CopyFile(src, dst, FailIfExists)
	$TypeBuilder = $ModuleBuilder.DefineType('Kernel32', 'Public, Class')

	# Define the CopyFile method. This method is a special type to a method called P/Invoke method.
	# A P/Invoke method is an unmanaged exported function from a module - like kernel32.dll
	$PinvokeMethod = $TypeBuilder.DefineMethod(
		'CopyFile',
		[Reflection.MethodAttributes] 'Public, Static',
		[Bool],
		[Type[]] @([String], [String], [Bool])
	)

	
	# Region DllImportAttribute
	# Set the equivalent of: [DllImport(
	# "kernel32.dll",
	# SetLastError = true,
	# PreserveSig = true,
	# CallingConvention = CallingConvention.WinApi,
	# CharSet = CharSet.Unicode)]
	# Note: DefinePinvokeMethod cannot be used if SetLastError needs to be set
	$DllImportConstructor = [Runtime.InteropServices.DllImportAttribute].GetConstructor(@([String]))

	$FieldArray = [Reflection.FieldInfo[]] @(
		[Runtime.InteropServices.DllImportAttribute].GetField('EntryPoint'),
		[Runtime.InteropServices.DllImportAttribute].GetField('PreserveSig'),
		[Runtime.InteropServices.DllImportAttribute].GetField('SetLastError'),
		[Runtime.InteropServices.DllImportAttribute].GetField('CallingConvention'),
		[Runtime.InteropServices.DllImportAttribute].GetField('CharSet')
	)

	$FieldValueArray = [Object[]] @(
		'CopyFile',
		$True,
		$True,
		[Runtime.InteropServices.CallingConvention]::WinApi,
		[Runtime.InteropServices.CharSet]::Unicode
	)

	$SetLastErrorCustomAttribute = New-Object Reflection.Emit.CustomAttributeBuilder(
		$DllImportConstructor,
		@('kernel32.dll'),
		$FieldArray,
		$FieldValueArray
	)

	$PinvokeMethod.SetCustomAttribute($SetLastErrorCustomAttribute)
	#endregion

	# Make our method accessible to PowerShell
	$Kernel32 = $TypeBuilder.CreateType()

	# Perform the copy
	$CopyResult = $Kernel32::CopyFile($Path, $Destination, ([Bool] $PSBoundParameters['FailIfExists']))

	if  ($CopyResult -eq $False)
	{
		# An error occured. Display the Win32 error set by CopyFile
		# throw (New-Object ComponentModel.Win32Exception)
		$lastError = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()  
		throw(New-Object ComponentModel.Win32Exception($lastError))
	}
	else
	{
		Write-Output (Get-ChildItem $Destination)
	}
}
