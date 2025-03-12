# You can compile a class with C# or other .NET languages in PowerShell v2
Add-Type @'
public class MyObject
{
    public int MyField = 5;
    public int xTimesMyField(int x) {
        return x * MyField;
    }
}
'@
$object = New-Object MyObject
$object
$object.xTimesMyField(10)

Write-Host "================================================"

# You can also use -asCustomObject with the New-Module cmdlet to export a module as a class
$object = New-Module {
    [int]$myField = 5
    function XTimesMyField($x) {
        $x * $myField
    }
    Export-ModuleMember -Variable * -Function *
} -asCustomObject
$object
$object.xTimesMyField(4)

# You can also simply declare an object and start tacking on properties and 
# methods with the Add-Member cmdlet. If you use -passThru you can make
# one giant pipeline that adds all of the members and assign it to a variable

$object = New-Object Object |
    Add-Member NoteProperty MyField 5 -PassThru |
    Add-Member ScriptMethod xTimesMyField {
        param($x)
        $x * $this.MyField
    } -PassThru
$object
$object.xTimesMyField(10)