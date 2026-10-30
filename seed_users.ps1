$apiKey = "AIzaSyD0a7TlthZ7dl06OjBP3_15_PVtvdk9UDk"
$projectId = "carecampus-app"

$users = @(
    @{ email = "student@carecampus.org";    password = "StudentPassword@123";    name = "Jane Doe";          role = "student" },
    @{ email = "counsellor@carecampus.org"; password = "CounsellorPassword@123"; name = "Dr. Sarah Jenkins"; role = "counsellor" },
    @{ email = "admin@carecampus.org";      password = "AdminPassword@123";      name = "Campus Admin";      role = "admin" }
)

$uids = @{}

foreach ($user in $users) {
    Write-Host "Processing $($user.role)..." -ForegroundColor Cyan

    $uid = $null
    $idToken = $null

    # Try sign-up first
    try {
        $body = @{ email = $user.email; password = $user.password; returnSecureToken = $true } | ConvertTo-Json
        $r = Invoke-RestMethod -Uri "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey" `
            -Method Post -ContentType "application/json" -Body $body -ErrorAction Stop
        $uid = $r.localId
        $idToken = $r.idToken
        Write-Host "  ✅ Created in Firebase Auth (uid: $uid)" -ForegroundColor Green
    } catch {
        # User may already exist - sign in instead
        try {
            $body = @{ email = $user.email; password = $user.password; returnSecureToken = $true } | ConvertTo-Json
            $r = Invoke-RestMethod -Uri "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey" `
                -Method Post -ContentType "application/json" -Body $body -ErrorAction Stop
            $uid = $r.localId
            $idToken = $r.idToken
            Write-Host "  ⚠️  Already exists, signed in (uid: $uid)" -ForegroundColor Yellow
        } catch {
            Write-Host "  ❌ Failed to create/sign-in $($user.email): $_" -ForegroundColor Red
            continue
        }
    }

    $uids[$user.role] = $uid

    # Write user document to Firestore
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    $fsBody = @{
        fields = @{
            uid      = @{ stringValue  = $uid }
            name     = @{ stringValue  = $user.name }
            username = @{ stringValue  = $user.email }
            role     = @{ stringValue  = $user.role }
            createdAt = @{ integerValue = $now.ToString() }
        }
    } | ConvertTo-Json -Depth 10

    try {
        Invoke-RestMethod -Uri "https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/users/$uid" `
            -Method Patch -ContentType "application/json" `
            -Headers @{ Authorization = "Bearer $idToken" } `
            -Body $fsBody -ErrorAction Stop | Out-Null
        Write-Host "  ✅ Firestore user document saved" -ForegroundColor Green
    } catch {
        Write-Host "  ❌ Firestore write failed: $_" -ForegroundColor Red
        Write-Host "     Make sure Firestore database is created in Firebase Console!" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "🎉 Done! Login credentials:" -ForegroundColor Green
Write-Host "  Student:    student@carecampus.org     / StudentPassword@123"
Write-Host "  Counsellor: counsellor@carecampus.org  / CounsellorPassword@123"
Write-Host "  Admin:      admin@carecampus.org       / AdminPassword@123"
Write-Host ""
Write-Host "Now hot-restart your Flutter app (press R in the terminal running flutter run)" -ForegroundColor Cyan
