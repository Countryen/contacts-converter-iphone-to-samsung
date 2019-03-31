<#
    Skript für die Übertragung von iPhone Kontakten auf Android  Kontakte.
    Die Kontakte können als vCard in Android (Samsung Galaxy S9) importiert werden.
    Die Kontakte wurden vom iPhone (Backup) extrahiert
    Datei: Home/Library/AddressBook/AddressBook.sqlitedb
    Januar 2019, countryen@kabelbw.de | PS v5.1
#>

# Verwendete "Konstanten"
$CRLF = [System.Environment]::NewLine
$ENCODING_UTF8_WITHOUT_BOM = New-Object System.Text.UTF8Encoding $False

# Konfiguration:
$CFG = @{
    SqliteInstallPath     = "P:/IDE/System.Data.SQLite/2010/bin"
    DataSourcePath        = "./AddressBook.sqlitedb"
    CardsOutputFolderPath = "./Cards"
}

Write-Host "Start. Konvertierung von iPhone-Kontakten in Android-kompatible VCF-Dateien."
Write-Host "Konfiguration:"
Write-Host "- SqliteInstallPath: $($CFG.SqliteInstallPath)"
Write-Host "- DataSourcePath: $($CFG.DataSourcePath)"
Write-Host "- CardsOutputFolderPath: $($CFG.CardsOutputFolderPath)"

# Laden der Typen für SQLite.
# Siehe: https://social.technet.microsoft.com/wiki/contents/articles/30562.powershell-accessing-sqlite-databases.aspx
# Siehe: https://system.data.sqlite.org/downloads/1.0.109.0/sqlite-netFx40-setup-x64-2010-1.0.109.0.exe
Add-Type -Path "$($CFG.SqliteInstallPath)/System.Data.SQLite.dll"

# Step 1: Verbindung zur Datenbank aufbauen.
$path = $CFG.DataSourcePath
Write-Host -ForegroundColor DarkGreen "Verbindungsaufbau zur SQLite-Datenbank: [$path]"
$con = New-Object -TypeName System.Data.SQLite.SQLiteConnection
$con.ConnectionString = "Data Source=$path"
$con.Open()

# Step 2: Testen der Verbindung
if ($false) {
    $sql = $con.CreateCommand()
    $sql.CommandText = "SELECT * FROM ABPerson LIMIT 10"
    $adapter = New-Object -TypeName System.Data.SQLite.SQLiteDataAdapter $sql
    $data = New-Object System.Data.DataSet
    [void]$adapter.Fill($data)

    $data.Tables.Rows.ROWID # <- Ausgabe
}

Write-Host -ForegroundColor DarkGreen "Verbunden."

# Step 3: Abrufen der Daten aus der SQLite-Datenbank.
Write-Host -ForegroundColor DarkGreen "Daten der SQLite-Datenbank werden abgerufen."

# ABPerson: Alle Personen-Details, PK=ROWID
$rows1 = "ROWID, Prefix, First, Middle, Last, Suffix, Organization, Department, Note, Birthday, JobTitle, Nickname"
$table1 = "ABPerson"

# Ausführung des SQL
$sql1 = $con.CreateCommand()
$sql1.CommandText = "SELECT $rows1 FROM $table1"
$adapter1 = New-Object -TypeName System.Data.SQLite.SQLiteDataAdapter $sql1
$data1 = New-Object System.Data.DataSet
[void]$adapter1.Fill($data1)

# ===================================

# ABMultiValue: Kontaktmöglichkeiten, PK=UID, FK_ABPerson=record_id
$rows2 = "UID, record_id, property, value"
$table2 = "ABMultiValue"
$where2 = "value <> ''"

# Ausführung des SQL
$sql2 = $con.CreateCommand()
$sql2.CommandText = "SELECT $rows2 FROM $table2 WHERE $where2"
$adapter2 = New-Object -TypeName System.Data.SQLite.SQLiteDataAdapter $sql2
$data2 = New-Object System.Data.DataSet
[void]$adapter2.Fill($data2)

# Zwischenspeicherung der Ergebnisse
$PersonData = $data1.Tables.Rows
$ContactData = $data2.Tables.Rows

Write-Host -ForegroundColor DarkGreen "Anzahl geladener Personen: [$($PersonData.Count)]"
Write-Host -ForegroundColor DarkGreen "Anzahl geladener Kontaktmöglichkeiten: [$($ContactData.Count)]"

# Step 3: Gruppierung der Daten
Write-Host -ForegroundColor DarkGreen "SQLite-Datenbank Daten werden verarbeitet - Kontaktmöglichkeiten werden den Personen zugeordnet."
# Die Personen sind einmalig, aber zu jeder Person kann es mehrere Kontaktmöglichkeiten geben (Person 1:n Contacts)
# Die Kontaktmöglichkeiten können in Typen unterteilt werden, anhand "property"
# Jede Person kann mehrere Kontaktmöglichkeiten vom selben Typ haben (Array)
# Filter auf nur Telefon-Nummern: property=3
# Filter auf nur E-Mails: property=4
# Filter auf nur URLs: property=22
# Filter auf nur Zusatznamen: property=23
# Sonstige: property = 5, 13, 46 => NULL

# Struktur für eine Person mit allen Kontaktdaten
$NewContactPerson = [PSCustomObject] @{
    PersonId               = 0
    NamePrefix             = ""
    NameFirst              = ""
    NameMiddle             = ""
    NameLast               = ""
    NameSuffix             = ""
    Nickname               = ""
    OrganizationName       = ""
    OrganizationDepartment = ""
    JobTitle               = ""
    Birthday               = ""
    Notes                  = ""
    PhoneNumbers           = @()
    MailAddresses          = @()
    Urls                   = @()
    AdditionalNames        = @()
}

$ContactPersons = @();

foreach ($row in ($PersonData)) {
    # Neue Instanz
    $cp = $NewContactPerson | Select-Object * 

    # Personeninformationen:
    $cp.PersonId = [string]$row.ROWID
    $cp.NamePrefix = [string]$row.Prefix
    $cp.NameFirst = [string]$row.First
    $cp.NameMiddle = [string]$row.Middle
    $cp.NameLast = [string]$row.Last
    $cp.NameSuffix = [string]$row.Suffix
    $cp.Nickname = [string]$row.Nickname
    $cp.OrganizationName = [string]$row.Organization
    $cp.OrganizationDepartment = [string]$row.Department
    $cp.JobTitle = [string]$row.JobTitle
    $cp.Birthday = [string]$row.Birthday
    $cp.Notes = [string]$row.Note

    # Kontaktmöglichkeiten:
    $contacts = $ContactData | ? { $_.record_id -eq $row.ROWID }
    foreach ($contact in $contacts) {
        # Zuweisung:
        $p = [string]$contact.property;
        $v = [string]$contact.value;
        switch ($p) {
            # Telefon-Nummern
            "3" { $cp.PhoneNumbers += $v }
            # E-Mails
            "4" {  $cp.MailAddresses += $v }
            # URLs
            "22" { $cp.Urls += $v }
            # Zusatznamen
            "23" { $cp.AdditionalNames += $v }
            # Sonstiges kommt zu den Notizen
            Default { $cp.Notes += " &$v&"}
        }
    }
    
    # Zwischenspeicherung
    $ContactPersons += $cp
}

Write-Host -ForegroundColor DarkGreen "Zuordnungen abgeschlossen, Anzahl: [$($ContactPersons.Count)]"

# Step 4: Konvertierung zu vCards https://de.wikipedia.org/wiki/VCard
# Die genaue Formatierung wurde einem exportierten Beispiel-Kontakt entnommen (Android 9)
# N, FN, ADR wird im "Quoted-Printable-Konvertierung" angegeben: https://de.wikipedia.org/wiki/Quoted-Printable-Kodierung
# Obwohl die hier verwendete Formatierung abweicht, funktioniert es (getestet)
Write-Host -ForegroundColor DarkGreen "Daten werden nun in vCard-Format konvertiert."

$Cards = @();
foreach ($cp in ($ContactPersons)) {
    $card = ""

    # Kopf
    $card += "BEGIN:VCARD" + $CRLF
    $card += "VERSION:2.1" + $CRLF

    # Strukturierter Name (nicht Quoted Printable)
    # Trennung der Elemente mit [;]: Nachname[;]Vorname[;]Zweiter Vorname[;]Präfix[;]Suffix
    $v = "$($cp.NameLast);$($cp.NameFirst);$($cp.NameMiddle);$($cp.NamePrefix);$($cp.NameSuffix)"
    $card += "N:$v" + $CRLF
    # QP Beispiel:
    # #$v = "=4E=61=63=68=6E=61=6D=65;=56=6F=72=6E=61=6D=65;=5A=77=65=69=74=65=72=20=56=6F=72=6E=61=6D=65;=50=72=C3=A4=66=69=78;=4E=61=6D=65=6E=73=73=75=66=66=69=78"
    # #$card += "N;CHARSET=UTF-8;ENCODING=QUOTED-PRINTABLE:$v" + $CRLF
    
    # Anzeigename (wird von Android "Kontakte" nicht verwendet) (nicht Quoted Printable)
    # Trennung der Elemente mit [ ] und [,]: Präfix[ ]Vorname[ ]Zweiter Vorname[ ]Nachname[ ][,]Suffix
    if ($false) {
        $v = "$($cp.NamePrefix) $($cp.NameFirst) $($cp.NameMiddle) $($cp.NameLast), $($cp.NameSuffix)"
        $card += "FN:$v" + $CRLF
    }
    # QP Beispiel:
    # #$v = "=50=72=C3=A4=66=69=78 =20 =56=6F=72=6E=61=6D=65 =20= 5A=77=65=69=74=65=72=20=56=6F=72=6E=61=6D=65 =20 =4E=61=63=68=6E=61=6D=65 =2C=20= 4E=61=6D=65=6E=73=73=75=66=66=69=78"
    # #$card += "FN;CHARSET=UTF-8;ENCODING=QUOTED-PRINTABLE:$v" + $CRLF

    # Adresse (Wurden zuvor nicht gepflegt) (nicht Quoted Printable) 
    $v = ""
    $card += "ADR:$v" + $CRLF
    # QP Beispiel:
    # #$v = ";;=4B=6F=72=6E=62=69=6E=64=73=74=72=61=C3=9F=65=20=35=36;=56=53;=42=57;=37=38=30=35=36;=44=45"
    # #$card += "ADR;HOME;CHARSET=UTF-8;ENCODING=QUOTED-PRINTABLE:$v" + $CRLF

    # Firma / Organisation  
    if (!([string]::IsNullOrWhiteSpace($cp.OrganizationName) -or [string]::IsNullOrWhiteSpace($cp.OrganizationDepartment))) {
        $v = "$($cp.OrganizationName) ($($cp.OrganizationDepartment))"
        $card += "ORG:$v" + $CRLF
    }
    if (![string]::IsNullOrWhiteSpace($cp.JobTitle)) {
        $v = $cp.JobTitle
        $card += "TITLE:$v" + $CRLF
    }

    # Nummern
    $len = ($cp.PhoneNumbers | Measure-Object).Count
    for ($i = 0; $i -lt $len; $i++) {
        $v = $cp.PhoneNumbers[$i]
        $card += "TEL;N$($i+1):$v" + $CRLF
    }
    
    # E-Mail-Adressen
    $len = ($cp.EmailAddresses | Measure-Object).Count
    for ($i = 0; $i -lt $len; $i++) {
        $v = $cp.EmailAddresses[$i]
        $card += "EMAIL;M$($i+1):$v" + $CRLF
    }
    
    # Web-Adressen
    $len = ($cp.Urls | Measure-Object).Count
    for ($i = 0; $i -lt $len; $i++) {
        $v = $cp.Urls[$i]
        $card += "URL;U$($i+1):$v" + $CRLF
    }

    # Notizen
    # Von Android/VCF nicht unterstützte Eigenschaften: -> Kommen mit zu den Notizen
    $card += "NOTE:[Importiert vom iPhone am " + (Get-Date).ToString("dd.MM.yyyy") + "]"
    if (![string]::IsNullOrWhiteSpace($cp.Notes)) {
        $v = $cp.Notes
        $card += "[Original-Notizen: $v]"
    }

    if (![string]::IsNullOrWhiteSpace($cp.Nickname)) {
        $v = $cp.Nickname
        $card += "[Nickname: $v]"
    }

    if (![string]::IsNullOrWhiteSpace($cp.Birthday)) {
        $v = $cp.Birthday
        $card += "[Geburtstag: $v]"
    }
    $len = ($cp.AdditionalNames | Measure-Object).Count
    for ($i = 0; $i -lt $len; $i++) {
        $v = $cp.AdditionalNames[$i]
        $card += "[Zusatzname $($i+1): $v]"
    }
    $card += $CRLF
    
    # Fuß
    $card += "END:VCARD"

    # Abspeicherung
    $Cards += $card
}
Write-Host -ForegroundColor DarkGreen "Konvertierung abgeschlossen, Anzahl: [$($Cards.Count)]"

# Step 5: Speicherung der Karten.
# Siehe: https://it-pro-berlin.de/2016/05/powershell-hack-utf-8-ohne-bom-ausgeben/
Write-Host -ForegroundColor DarkGreen  "Daten werden nun in [$($CFG.CardsOutputFolderPath)] gespeichert."

# Entfernen von Alt-Daten
Remove-Item -Recurse -Path $CFG.CardsOutputFolderPath
sleep 0.5
New-Item -ItemType Directory -Path $CFG.CardsOutputFolderPath

# Ausgabe aller Karten in je eine VCF
$len = $Cards.Count
for ($i = 0; $i -lt $len; $i++) {
    $cardText = $Cards[$i];
    $newFilePath = Join-Path -Path $CFG.CardsOutputFolderPath -ChildPath "Kontakt_$i.vcf"
    [System.IO.File]::WriteAllText($newFilePath, $cardText, $ENCODING_UTF8_WITHOUT_BOM)
}

# Ausgabe aller Karten in einer VCF
$cardText = $Cards -join $CRLF 
$newFilePath = Join-Path -Path $CFG.CardsOutputFolderPath -ChildPath "Alle_$($len)_Kontakte.vcf"
[System.IO.File]::WriteAllText($newFilePath, $cardText, $ENCODING_UTF8_WITHOUT_BOM)


# Cleanup
Write-Host -ForegroundColor DarkGreen "Ende. Konvertierung vollständig abgeschlossen. Das Programm wird nun beendet."
if ($null -ne $con) { $con.Close() }