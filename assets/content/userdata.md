# Erklärung der Accountdaten

Du kannst deine gespeicherten personenbezogenen Daten jederzeit automatisiert in den Accounteinstellungen exportieren.
Diese werden im maschinell lesbaren JSON-Format bereitgestellt.
Wenn du die App ohne Synchronisation nutzt, also dich nicht angemeldet hast, (Gast-Modus), werden deine Daten ausschließlich lokal auf deinem Gerät
gespeichert und es findet keine Übertragung an unsere Server statt.
In diesem Abschnitt findest du eine ausführliche Erklärung der Datenstruktur, die in diesem Export enthalten ist, damit du genau verstehst, welche
Informationen gespeichert sind und wie sie organisiert sind.

Deine Daten sind folgendermaßen strukturiert (weitere Informationen in den eignen Abschnitten):

| Name       | Datentyp                                             | Erklärung                                                             |
|------------|------------------------------------------------------|-----------------------------------------------------------------------|
| identities | [`identities`](#login-provider-identities) _(Liste)_ | Informationen zu deinen Login-Providern (z.B. Google)                 |
| sessions   | [`sessions`](#geräteanmeldungen-sessions) _(Liste)_  | Informationen zu den Geräten, von denen aus du dich angemeldet hast   |
| user_data  | [`user_data`](#accountdaten-user_data)               | Deine eingetragenen Accountdaten: Fächerwahl, Noten und Einstellungen |

## Login-Provider (identities)

| Name             | Datentyp                     | Erklärung                                                                   |
|------------------|------------------------------|-----------------------------------------------------------------------------|
| id               | [`string`](#datentyp-string) | Interner eindeutiger Identifikator für die Login-Identität als Zeichenkette |
| provider         | [`string`](#datentyp-string) | Name des Login-Providers (z.B. "google")                                    |
| provider_user_id | [`string`](#datentyp-string) | Eindeutige Benutzer-ID, die vom Login-Provider (z.B. Google) verwendet wird |

## Geräteanmeldungen (sessions)

Diese Daten werden ausschließlich für die Sicherheit deines Accounts verwendet, damit du jederzeit nachvollziehen kannst, von welchen Geräten aus dein
Account angemeldet ist und wann die letzte Aktivität stattgefunden hat.
Diese sind in den Accounteinstellungen unter "Geräte" einsehbar und können einzeln entfernt werden.

| Name           | Datentyp                     | Erklärung                                                                                       |
|----------------|------------------------------|-------------------------------------------------------------------------------------------------|
| id             | [`string`](#datentyp-string) | Interner eindeutiger Identifikator für die Sitzung als Zeichenkette                             |
| identity_id    | [`string`](#datentyp-string) | Verweis auf die zugehörige Login-Identität/-Provider (z.B. Google Account)                      |
| device_name    | [`string`](#datentyp-string) | Name des Geräts, von dem die Anmeldung erfolgte (z.B. "iPhone 12 Pro" oder "Desktop (Windows)") |
| expires_at     | [`date`](#datentyp-date)     | Datum und Uhrzeit, wann die Sitzung abläuft und gelöscht wird                                   |
| last_refreshed | [`date`](#datentyp-date)     | Datum und Uhrzeit, wann die Sitzung zuletzt erneuert (bzw. genutzt) wurde                       |

## Accountdaten (user_data)

| Name             | Datentyp                                                                            | Erklärung                                                                           |
|------------------|-------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------|
| id               | [`string`](#datentyp-string)                                                        | Interner eindeutiger Identifikator für den Account als Zeichenkette                 |
| email            | [`string`](#datentyp-string)                                                        | E-Mail die mit dem Account assoziiert ist (vom Login-Provider z.B. Google erhalten) |
| name             | [`string`](#datentyp-string)                                                        | Name des Accounts (vom Login-Provider z.B. Google erhalten)                         |
| picture          | [`string`](#datentyp-string)                                                        | Das vom Login-Provider (z.B. Google) erhaltene Profilbild als URL (Link)            |
| created_at       | [`date`](#datentyp-date)                                                            | Datum der Accounterstellung                                                         |
| last_sync        | [`date`](#datentyp-date)                                                            | Datum der letzten Synchronisation der Einstellungen und Noten                       |
| semester         | [`semester`](#semestertypen-semester)                                               | Aktuell ausgewähltes Semester/Halbjahr                                              |
| uses_slider      | [`boolean`](#datentyp-boolean)                                                      | Ob die Noten-Eingabe über den Schieberegler oder Rasterauswahl erfolgt              |
| abi_predictions  | [`int`](#datentyp-int) _(Map: Fach-Int)_                                            | Manuell eingetragene Abiturprüfungsprognosen                                        |
| grades           | [`grade`](#noteneintrag-grade) _(Map: Semester-Fach-Liste-Noteneintrag)_            | Zuordnung der Semester und Fächer (ID) zur Liste eingetragener Noten                |
| subject_settings | [`subject_setting`](#facheinstellungen-subject_setting) _(Map: Fach-Einstellungen)_ | Fachspezifische Einstellungen wie Farbdarstellung und Kolloquiumstermin             | 
| choice           | [`choice`](#fächerwahl-choice)                                                      | Fächerwahl                                                                          |

## Fächerwahl (choice)

| Name     | Datentyp                                       | Erklärung                                                                                               |
|----------|------------------------------------------------|---------------------------------------------------------------------------------------------------------|
| lk       | [`subject`](#fächertypen-subject)              | Leistungsfach                                                                                           |
| sg1      | [`subject`](#fächertypen-subject)              | Erste fortgeführte Fremdsprache                                                                         |
| ntg1     | [`subject`](#fächertypen-subject)              | Erste Naturwissenschaft                                                                                 |
| mint_sg2 | [`subject`](#fächertypen-subject)              | Zweite fortgeführte Fremdsprache / spät beginnende Fremdsprache / zweite Naturwissenschaft / Informatik |
| geo_wr   | [`subject`](#fächertypen-subject)              | Geographie oder Wirtschaft und Recht in Q12                                                             |
| ku_mu    | [`subject`](#fächertypen-subject)              | Kunst oder Musik                                                                                        |
| vk       | [`subject`](#fächertypen-subject)              | Vertiefungskurs, ersetzt zweite Naturwissenschaft / Fremdsprache / Informatik                           |
| sem      | [`subject`](#fächertypen-subject)              | Fach des W-Seminars                                                                                     |
| profil12 | [`subject`](#fächertypen-subject) _(optional)_ | Profilfach in Q12                                                                                       |
| profil13 | [`subject`](#fächertypen-subject) _(optional)_ | Profilfach in Q13                                                                                       |
| abi4     | [`subject`](#fächertypen-subject)              | Viertes Abiturprüfungsfach                                                                              |
| abi5     | [`subject`](#fächertypen-subject)              | Fünftes Abiturprüfungsfach                                                                              |
| oral1    | [`subject`](#fächertypen-subject) _(optional)_ | Erstes mündliches Abiturprüfungsfach                                                                    |
| oral2    | [`subject`](#fächertypen-subject) _(optional)_ | Zweites mündliches Abiturprüfungsfach                                                                   |
| sub_m    | [`boolean`](#datentyp-boolean)                 | Abiturprüfung in Mathematik substituiert                                                                |
| sub_d    | [`boolean`](#datentyp-boolean)                 | Abiturprüfung in Deutsch substituiert                                                                   |
| pug13    | [`boolean`](#datentyp-boolean)                 | Politik und Gesellschaft in Q13 weitergeführt                                                           |

## Fächertypen (subject)

Fächer werden intern durch ihre ID in der Form eines [`int`](#datentyp-int) (Ganzzahl) repräsentiert.

| ID  | Name                       |
|-----|----------------------------|
| 1   | Mathematik                 |
| 2   | Deutsch                    |
| 11  | Mathematik Vertiefungskurs |
| 12  | Deutsch Vertiefungskurs    |
| 21  | Englisch                   |
| 22  | Französisch                |
| 23  | Spanisch                   |
| 24  | Latein                     |
| 25  | Griechisch                 |
| 26  | Italienisch                |
| 27  | Russisch                   |
| 28  | Chinesisch                 |
| 31  | Spanisch spät beginnend    |
| 41  | Physik                     |
| 42  | Chemie                     |
| 43  | Biologie                   |
| 44  | Informatik                 |
| 51  | Religion                   |
| 52  | Geschichte                 |
| 53  | Geographie                 |
| 54  | Wirtschaft und Recht       |
| 55  | Politik und Gesellschaft   |
| 61  | Kunst                      |
| 62  | Musik                      |
| 81  | Sport                      |
| 91  | W-Seminar                  |
| 100 | Wahlfach                   |

## Noteneintrag (grade)

| Name | Datentyp                               | Erklärung                          |
|------|----------------------------------------|------------------------------------|
| g    | [`int`](#datentyp-int)                 | Note als Zahl                      |
| t    | [`grade_type`](#notentypen-grade_type) | Notentyp als ID für die Gewichtung |
| d    | [`date`](#datentyp-date)               | Datum des Noteneintrags            |

## Notentypen (grade_type)

| ID  | Name                                                               |
|-----|--------------------------------------------------------------------|
| 0   | Klausur                                                            |
| 1   | Stegreifaufgabe                                                    |
| 2   | Ausfrage                                                           |
| 3   | Referat                                                            |
| 4   | Unterrichtsbeitrag                                                 |
| 10  | Praxis (Sport)                                                     |
| 11  | Theorietest (Sport)                                                |
| 12  | Technik (Sport)                                                    |
| 20  | W-Seminar Arbeit                                                   |
| 21  | W-Seminar Präsentation                                             |
| 30  | Schriftliche Abiturprüfung                                         |
| 31  | Mündliche Abiturprüfung (Kolloquium)                               |
| 32  | Mündliche Zusatzprüfung (Nachprüfung)                              |
| 33  | Besondere Fachprüfung (Praktisch z.B. Sport Leistungsfach)         |
| 40  | Künstlertisches Projekt (Kunst Leistungsfach)                      |
| 50  | Praktische Prüfung (Musik Leistungsfach)                           |
| 100 | Direkt eingetragenes Ergebnis z.B. für Seminararbeit/Abiturprüfung |
| 200 | Befreiung vom Sportunterricht                                      |

## Semestertypen (semester)

| ID        | Name                                                |
|-----------|-----------------------------------------------------|
| q12_1     | Q12/1 (1. Halbjahr)                                 |
| q12_2     | Q12/2 (2. Halbjahr)                                 |
| q13_1     | Q13/1 (3. Halbjahr)                                 |
| q13_2     | Q13/2 (4. Halbjahr)                                 |
| seminar13 | Virtuelles Halbjahr für die W-Seminar Arbeit in Q13 |
| abi       | Abiturprüfungsphase                                 |

## Facheinstellungen (subject_setting)

| Name      | Datentyp                                         | Erklärung                                                                                 |
|-----------|--------------------------------------------------|-------------------------------------------------------------------------------------------|
| color     | rgb color as [`int`](#datentyp-int) _(optional)_ | Farbe für die Farbdarstellung in der App, gespeichert als Integer im RGB-Format           |
| oral_exam | [`date`](#datentyp-date) _(optional)_            | Kolloquiumstermins für das Fach, falls es als mündliches Abiturprüfungsfach gewählt wurde |

## Datentyp date

Datum im ISO-8601 Format als ``YYYY-MM-DD``, z.B. `2026-02-13` für den 13. Februar 2026.
Alternativ kann es auch ein vollständiger Zeitstempel im ISO-8601 Format mit Uhrzeit und Zeitzone sein, z.B. `2026-02-13T15:30:00Z` für den 13.
Februar 2026 um 15:30 Uhr UTC.

## Datentyp int

Integer, ganze Zahl, z.B. `1`, `2`, `3` usw.

## Datentyp string

Zeichenkette, eine Folge von Zeichen bzw. ein Text.

## Datentyp boolean

Wahrheitswert, der entweder `true` (wahr/ja) oder `false` (falsch/nein) sein kann. 

