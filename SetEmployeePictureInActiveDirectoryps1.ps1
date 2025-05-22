Set-ADUser -Identity "chadm" -Replace @{thumbnailPhoto=([byte[]](Get-Content "Y:\TCI\Pics\EmployeePhotos\M365pics\Chad May.png" -Encoding byte))}
