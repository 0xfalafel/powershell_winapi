
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
    Param(
        [Parameter(Mandatory = $True, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        [Parameter(Mandatory = $True, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Destination,

        [Switch]
        $FailIfExists
    )

    $MethodDefinition = @'
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode)]
    public static extern bool CopyFile(string IpExistingFileName, string IpNewFileName, bool bFailIfExists);
'@

    $Kernel32 = Add-Type -MemberDefinition $MethodDefinition -Name 'Kernel32' -Namespace 'Win32' -PassThru

    # Perform the copy
    $CopyResult = $Kernel32::CopyFile($Path, $Destination, ([Bool] $PSBoundParameters['FailIfExists']))

    if ($CopyResult -eq $False)
    {
        # An error occured. Display the Win32 error set by CopyFile
        throw (New-Object ComponentModel.Win32Exception)
    }
    else
    {
        Write-Output (Get-ChildItem $Destination)
    }
}
