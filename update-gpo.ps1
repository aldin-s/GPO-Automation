import-module grouppolicy

$current_gpos=Get-GPO -All
$date=$(get-date -f MM-dd-yyyy_HH_mm_ss)
$backup_folder="PATH_TO_THE_TO_THE_GPO_BACKUP_FOLDER"


$gpo_import_folder="PATH_TO_THE_TO_BE_IMPORTED_GPOs_FOLDER"

#since dcgpofix, does not work ...
#exclude "Default Domain Controllers Policy", "Default Domain Policy" 
#$default_gpos=@("31b2f340-016d-11d2-945f-00c04fb984f9", "6ac1786c-016f-11d2-945f-00c04fb984f9")
$default_gpos=@("Default Domain Controllers Policy", "Default Domain Policy")
#executing 
$default_gpos_id=@("31b2f340-016d-11d2-945f-00c04fb984f9", "6ac1786c-016f-11d2-945f-00c04fb984f9")



#create backupfolder
If(!(test-path $backup_folder))
{
      New-Item -ItemType Directory -Force -Path $backup_folder
}

#backup GPOs
foreach ($gpo in $current_gpos) {
    
    $path=$backup_folder+$gpo.Displayname
    New-Item -ItemType directory -Path $path
    Backup-GPO -Guid $gpo.id -Path $path
 }

#remove existing GPOs from AD
 
 foreach ($gpo in $current_gpos) {
 
    $gpo_name=$gpo.Name
    $gpo_id=$gpo.ID

#   Write-Output "remove gpo: wprking on $gpo_name $gpo_id"
    #name can be empty so we use IDs
    if  (-Not $default_gpos_id.Contains([string]$gpo_id)){
        Remove-GPO -Guid $gpo.id
    }
 }
 
 # import / install new gpos
 $domain_name = (Get-WmiObject Win32_ComputerSystem).Domain
 $domain_parts = $domain_name.Split(".")

 foreach ($gpo in  Get-childItem -Path $gpo_import_folder) {

    if (-Not $default_gpos.Contains([string]$gpo.Name)){
        $gpo_name=$gpo.Name
        $gpo_path=$gpo_import_folder+$gpo_name
        $gpo_id=Get-ChildItem -Path $gpo_path

#       Write-Output "install gpo: working ON $gpo_name"

        New-GPO -Name $gpo_name
        Import-GPO -TargetName $gpo_name -Path $gpo_path -BackupId $gpo_id.Name
        New-GPLink -Name $gpo_name -Target "DC=$($domain_parts[0]),DC=$($domain_parts[1]),DC=$($domain_parts[2])" -LinkEnabled Yes
    }
    
}
