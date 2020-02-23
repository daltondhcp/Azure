Configuration DemoConfig {
Import-DscResource -ModuleName 'PSDscResources'

    WindowsFeature WebServer {
        Ensure  = 'Present'
        Name    = 'Web-Server'
    }
    Script DownloadMsi {
        GetScript =  
        {
            @{
                GetScript = $GetScript
                SetScript = $SetScript
                TestScript = $TestScript
                Result = ('True' -in (Test-Path d:\depagent.exe))
            }
        }
        SetScript = 
        {
            #Download files to temporary storage
             Invoke-WebRequest https://aka.ms/dependencyagentwindows -OutFile d:\depagent.exe
        }

        TestScript = 
        {
            $Status = ('True' -in (Test-Path d:\depagent.exe))
            $Status -eq $True
        }
    }
    Package InstallDepAgent {
            Ensure = 'Present'
            Name = 'Dependency Agent'
            Path = d:\depagent.exe
            Arguments = '/S /AcceptEndUserLicenseAgreement:1'
            ProductId = ''
            DependsOn = '[Package]InstallMMAAgent'
   }
}
