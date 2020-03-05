# Download suff
$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/cloudacademy/azure-lab-provisioners/master/custom-rbac/bootstrap.ps1" `
                  -OutFile C:\Users\student\Desktop\script.ps1 -UseBasicParsing

# execute script.ps1
 