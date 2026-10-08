# Auto-Push to GitHub Rule

## Purpose
Tự động lưu, commit và đẩy (push) mã nguồn lên GitHub mỗi khi hoàn thành cập nhật hoặc sửa lỗi mã nguồn trong dự án.

## Rules for Assistant
1. **Tự động Commit & Push**:
   - Khi hoàn thành bất kỳ tính năng mới, chỉnh sửa giao diện, sửa lỗi (bug fix) hoặc tạo asset nào:
     - Tự động chạy `git add .`
     - Tự động commit với thông điệp rõ ràng theo chuẩn Conventional Commits (ví dụ: `fix: ...`, `feat: ...`, `chore: ...`)
     - Tự động thực thi lệnh `git push origin main` (hoặc nhánh hiện tại nếu có remote).
2. **Xử lý khi chưa kết nối Remote**:
   - Nếu chưa cấu hình remote origin, thông báo commit hash và hướng dẫn lệnh kết nối repo cho người dùng.
3. **An toàn dữ liệu**:
   - Tuân thủ `.gitignore`, không commit các file rác, file nhị phân tạm hoặc file chứa API key / token bí mật.
