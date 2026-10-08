param(
    [string]$msg = "chore: Automatic sync and update project"
)

Write-Host ">>> Staging all modified files..." -ForegroundColor Cyan
git add .

$status = git status --porcelain
if (-not $status) {
    Write-Host ">>> Không có thay đổi nào cần commit." -ForegroundColor Yellow
} else {
    Write-Host ">>> Committing with message: '$msg'..." -ForegroundColor Cyan
    git commit -m "$msg"
}

Write-Host ">>> Checking remote origin..." -ForegroundColor Cyan
$remote = git remote
if ($remote -contains "origin") {
    Write-Host ">>> Pushing to GitHub (origin/main)..." -ForegroundColor Green
    git push origin main
} else {
    Write-Host ">>> Chưa cấu hình remote origin. Chạy lệnh: git remote add origin <URL_REPO_CUA_BAN>" -ForegroundColor Yellow
}
