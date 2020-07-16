# Import du CSV.
$listeUsers = Import-Csv -Delimiter "," -Path "users.csv"

do {
    Write-Host "1) Supprimer les utilisateurs expires`n2) Creation des utilisateurs a partir du CSV"
    Write-Host "Entrer 1 ou 2: " -NoNewline
    $choix = Read-Host
    if ($choix -eq 1) {
        # Suppression des comptes inactifs.
        $date = (Get-Date).AddDays(-30)
        foreach ($user in $listeUsers) {
            $username = $user.nom + "." + $user.surname
            Search-ADAccount -AccountExpired | Where-Object { $_.enabled -eq $False -and $_.SamAccountName -eq $username -and $_.AccountExpirationDate -lt $date } | Remove-ADUser
            write-host "Suppression ${username}"
        }
        $do = $true
    }
    elseif ($choix -eq 2) {
        # Création des comptes utilisateurs.
        foreach ($user in $listeUsers) {
            $password = $user.nom[0] + "." + $user.surname[0] + "@" + $user.entreprise + (get-date -Format "MM")
            $username = $user.nom + "." + $user.surname
            $initiales = $user.nom[0] + $user.surname[0]
            $nom = $user.nom
            $surname = $user.surname
            $displayname = $user.nom + " " + $user.surname
            $entreprise = $user.entreprise
            $departement = $user.departement
            $DateExpiration = $user.fincontrat
            if ($user.estpresent -eq 1) {
                $estactive = $True
            }
            else {
                $estactive = $False
            }
            Try {
                if ($estactive) {
                    Get-ADuser -Identity $username | Enable-ADAccount 
                    write-host "l'utilisateur existe, aucune action requise"
                }
                else {
                    Get-ADuser -Identity $username | Disable-ADAccount
                    write-host "${username} a ete desactive"
                }
            }
            Catch {
                if ($estactive) {
                    New-ADUser `
                        -AccountExpirationDate $DateExpiration `
                        -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) `
                        -ChangePasswordAtLogon $true `
                        -Company $entreprise `
                        -Department $departement `
                        -DisplayName $displayname `
                        -Enabled $estactive `
                        -Initials $initiales `
                        -Name $nom `
                        -SamAccountName $username `
                        -Surname $surname `
                        -GivenName $surname
                    Add-ADGroupMember -Identity "Admin local" -Members $username
                    write-host "${username} a ete cree"
                }
                else {
                    write-host "aucune action requise ${username} n'est pas present"

                }
            }
        }
        $do = $true
    }
    else {
        $do = $false
    }
} while ($do -eq $false)
