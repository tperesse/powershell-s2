$ListeOrdinateurs = Import-Csv -Delimiter "," -Path "G:\Documents\Cours\powershell\inventaire.csv"
$Fait = Import-Csv -Delimiter "," -Path "fait.csv"
$DossierPartage = "G:\Documents\Cours\powershell\"

$Valeur = Get-Content "G:\Documents\Cours\powershell\inventaire.csv" | Select-Object -First 1

Set-Content -Path "${DossierPartage}PretMigration.csv" -Value $Valeur -Encoding UTF8
$PretMigration = @()

foreach ($Ordinateur in $ListeOrdinateurs) {
    [int]$Memoire = $Ordinateur.RAM
    [int]$GenerationDeProcesseur = [convert]::ToInt32($Ordinateur.Processeur[21], 10)
    [int]$TailleDisque = $Ordinateur.TailleDisqueGB
    try {
        [int]$VitesseAdaptateurSansFil = $Ordinateur.VitesseAdaptateurSansFilGB
    }
    catch [System.InvalidCastException] {
        $VitesseAdaptateurSansFil = 0
    }
    try {
        [int]$VitesseAdaptateurFil = $Ordinateur.VitesseAdaptateurFilGB
    }
    catch [System.InvalidCastException] {
        $VitesseAdaptateurFil = 0
    }
    if ($Memoire -ge 12 -and $GenerationDeProcesseur -ge 6 -and $TailleDisque -ge 500 -and ($VitesseAdaptateurFil -ge 1 -or $VitesseAdaptateurSansFil -ge 1 )) {
        $PretMigration += $Ordinateur
    }
    else {
        $OrdinateursAAcheter += 1
    }
}

$PretMigration | Export-Csv -NoTypeInformation -Path "${DossierPartage}PretMigration.csv" -Encoding UTF8
$Temps = Get-Date -UFormat "%Y/%m/%d %T"
Set-Content -Path ${DossierPartage}OrdinateursAAcheter.txt -Value "$Temps : ordinateurs a acheter: ${OrdinateursAAcheter}" -Encoding UTF8
$TravailFait = (($PretMigration | Measure-Object).Count - ($Fait | Measure-Object).Count)
Add-Content -path ${DossierPartage}TravailEffectue.txt -Value "$Temps : $TravailFait ordinateurs restant a etre migres" -Encoding UTF8
