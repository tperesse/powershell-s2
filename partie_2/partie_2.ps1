function RecupVitesseAdaptateurReseau([string]$type) {
    $VitesseAdaptateurReseau = Get-WmiObject Win32_NetworkAdapter -ComputerName "localhost" |`
        Where-Object { $_.Name -match $type -and $_.Name -notmatch 'virtual' -and $null -ne $_.Speed -and $null -ne $_.MACAddress } |`
        Measure-Object -Property speed -sum |`
        ForEach-Object { [Math]::Round(($_.sum / 1GB))}    
    if ($null -ne $VitesseAdaptateurReseau) {
        return $VitesseAdaptateurReseau
    } else {
        return "aucun adaptateur ${type} trouve"
    }
}

$DossierPartage = "G:\Documents\Cours\powershell\"
do {
    Write-Host "1) Obtenez les specifications de l'ordinateur`n2) Fusionner a l'inventaire"
    Write-Host "Entrer 1 OU 2: " -NoNewline
    $choix = Read-Host
    if ($choix -eq 1) {
        $serveur = "localhost"
        $ObjetInfo = New-Object PSObject
        $CPU = Get-WmiObject Win32_Processor -ComputerName $serveur
        $SystemName = $CPU.SystemName
        $OS = Get-WmiObject Win32_OperatingSystem -ComputerName $serveur
        $RAM = Get-WmiObject CIM_PhysicalMemory -ComputerName $serveur | Measure-Object -Property capacity -Sum | ForEach-Object { [Math]::Round(($_.sum / 1GB), 2) }
        $TailleDisque = Get-WmiObject Win32_logicaldisk -ComputerName localhost | Measure-Object -Property size -Sum | ForEach-Object { [Math]::Round(($_.sum / 1GB), 2) }
        $VitesseAdaptateurSansFil = RecupVitesseAdaptateurReseau("wireless")
        $VitesseAdaptateurFil = RecupVitesseAdaptateurReseau("ethernet")
        $DateTime = Get-Date -UFormat "%Y/%m/%d %T"
        Add-Member -inputObject $ObjetInfo -memberType NoteProperty -name "SystemName" -value $SystemName
        Add-Member -inputObject $ObjetInfo -memberType NoteProperty -name "Processeur" -value $CPU.Name
        Add-Member -inputObject $ObjetInfo -memberType NoteProperty -name "CoeursPhysique" -value $CPU.NumberOfCores
        Add-Member -inputObject $ObjetInfo -memberType NoteProperty -name "CoeursLogiques" -value $CPU.NumberOfLogicalProcessors
        Add-Member -inputObject $ObjetInfo -memberType NoteProperty -name "NomOS" -value $OS.Caption
        Add-Member -inputObject $ObjetInfo -memberType NoteProperty -name "VersionOS" -value $OS.Version
        Add-Member -inputObject $ObjetInfo -memberType NoteProperty -name "RAM" -value $RAM
        Add-Member -inputObject $ObjetInfo -MemberType NoteProperty -name "TailleDisqueGB" -Value $TailleDisque
        Add-Member -inputObject $ObjetInfo -MemberType NoteProperty -name "VitesseAdaptateurSansFilGB" -Value $VitesseAdaptateurSansFil
        Add-Member -inputObject $ObjetInfo -MemberType NoteProperty -name "VitesseAdaptateurFilGB" -Value $VitesseAdaptateurFil
        Add-Member -inputObject $ObjetInfo -MemberType NoteProperty -name "Username" -Value $env:UserName
        Add-Member -inputObject $ObjetInfo -MemberType NoteProperty -name "InventaireDate" -Value $DateTime
        $ObjetInfo | ConvertTo-Csv -NoTypeInformation | Select-Object -Skip 1 | Set-Content -Path "${DossierPartage}${SystemName}.csv" -Encoding UTF8
        $do = $true
    }
    elseif ($choix -eq 2) {
        $valeurs = '"SystemName","Processeur","CoeursPhysique","CoeursLogiques","NomOS","VersionOS","RAM","TailleDisqueGB","VitesseAdaptateurSansFilGB","VitesseAdaptateurFilGB","Username","InventaireDate"'
        Set-Content -Path "${DossierPartage}inventaire.csv" -Value $valeurs -Encoding UTF8
        Get-ChildItem -File -Path "${DossierPartage}*" -Include *.csv -Exclude *inventaire.csv* | Foreach-Object {
            $contenu = Get-Content $_.FullName
            Add-Content -Path "${DossierPartage}inventaire.csv" -Value $contenu -Encoding UTF8
        }
        $do = $true
    }
    else {
        $do = $false
    }
} while ($do -eq $false)