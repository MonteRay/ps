Add-Type @'
public class MyClass
{
    public double a = 3.14;
    public double b = 5.36;
}
'@            
            
$Object = New-Object MyClass

#function my(