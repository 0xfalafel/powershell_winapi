function Copy-RawItem

{

<#
.SYNOPSIS
    Copies a file from one location to another including files contained within DeviceObject paths.

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

    [Parameter(Mandatory = $True, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [String]
    $Path,

    [Parameter(Mandatory = $True, Position = 1)]
    [ValidateNotNullOrEmpty()]
    [String]
    $Destination,

    [Switch]
    $FailIfExists
)

    # Get a reference to the internal method – Microsoft.Win32.Win32Native.CopyFile()
    $mscorlib = [AppDomain]::CurrentDomain.GetAssemblies() | Where-Object {$_.Location -and ($_.Location.Split('\')[-1] -eq 'mscorlib.dll')}
    $Win32Native = $mscorlib.GetType('Microsoft.Win32.Win32Native')

    $CopyFileMethod = $Win32Native.GetMethod('CopyFile', ([Reflection.BindingFlags] 'NonPublic, Static'))


    # Perform the copy
    $CopyResult = $CopyFileMethod.Invoke($null, @($Path, $Destination, ([Bool] $PSBoundParameters['FailIfExists'])))
    $HResult = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()

    if ($CopyResult -eq $False -and $HResult -ne 0)
    {
        # An error occured. Display Win32 error set by CopyFile
        throw (New-Object ComponentModel.Win32Exception)
	# WriteError 'Failed to copy file'
    }
    else
    {
        Write-Output (Get-ChildItem $Destination)
    }
}
