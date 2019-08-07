Configuration DemoConfig {
Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

    WindowsFeature WebServer {
        Ensure  = 'Absent'
        Name    = 'Web-Server'
    }
    Script DownloadMsi {
        GetScript =  
        {
            @{
                GetScript = $GetScript
                SetScript = $SetScript
                TestScript = $TestScript
                Result = ('True' -in (Test-Path d:\installpbi64.msi))
            }
        }
        SetScript = 
        {
            #Download files to temporary storage
            Invoke-WebRequest -Uri "https://download.microsoft.com/download/9/B/A/9BAEFFEF-1A68-4102-8CDF-5D28BFFE6A61/PBIDesktop_x64.msi" -OutFile "D:\installpbi64.msi"
        }

        TestScript = 
        {
            $Status = ('True' -in (Test-Path d:\installpbi64.msi))
            $Status -eq $True
        }
    }
    Package InstallPbi64 
    {
        Ensure = 'Present'
        Name = 'Microsoft Power BI Desktop (x64)'
        Path = 'd:\installpbi64.msi'
        Arguments = '/qn /norestart ACCEPT_EULA=1'
        ProductId = 'A1B8A2F7-C948-47FB-AD92-B4AF7BEF402F'
    }
}
