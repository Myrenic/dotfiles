#                                                           *%###%###%           
#                                                      ,%.    ./&&&  ,#,         
#                                                   ,             &&&.           
#                  ,###%#            *####%    ##%###############*#&&@           
#                 ########         .%######,,#################### &&&,           
#                %#########       #########(        #####(       &&&(            
#               ##### /#####    ##### .####%       /#####      %&&&.             
#             .#####   (##### #####,   #####       #####(    /&&&&               
#            /#####     %########/     #####*     ,#####   %&&&&                 
#           ######       ######%       #####%     ####( /&&&&&                   
#                          ..                       .&&&&&&.                     
#                                      *&&&&#(#&&&&&&&&&                         
#                                       #&&&&&&&&&&%                             
#
# made by Mike
# Always read the code before use, edit if needed for your site.

Clear-Host



$flag = "$env:TEMP\shown_aliases.flag"

if (-not (Test-Path $flag)) {
    # Output formatted details
    Write-Host "==================== Alias ====================" -ForegroundColor Cyan
    Write-Host "k                   : Launch Kubectl view"
    Write-Host "m                   : Launch multipane view"
    Write-Host "l                   : delegate locked?"
    Write-Host "ctrl+arrow          : Split pane"
    Write-Host "ctrl+shift+w        : close pane"
    Write-Host "=====================================================" -ForegroundColor Cyan

    # Create the flag so it won't show again until next reboot
    New-Item -Path $flag -ItemType File -Force | Out-Null
}


Set-Alias -Name k -Value kubeView
Set-Alias -Name m -Value MultipaneView
function get-delegate() {
    Get-User nlgro.del.mtuntelder
}

Set-Alias -Name l -Value get-delegate

