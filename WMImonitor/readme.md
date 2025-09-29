\# WMI Monitor



Script PowerShell này dùng \*\*ETW (Event Tracing for Windows)\*\* để giám sát hoạt động \*\*WMI\*\* trên Windows thông qua provider `Microsoft-Windows-WMI-Activity`.



\## 📌 Tính năng

\- Tạo ETW session để ghi log các sự kiện WMI.

\- Xuất log ra nhiều định dạng: \*\*ETL\*\*, \*\*CSV\*\*, \*\*XML\*\*, \*\*JSON\*\*.

\- Tự động tạo thư mục lưu log nếu chưa tồn tại.



\## ⚙️ Tham số

\- `-Start`  

&nbsp; Bắt đầu monitor WMI và ghi log vào file `.etl`.



\- `-Stop`  

&nbsp; Dừng monitor, xuất log ra \*\*CSV\*\*, \*\*XML\*\* và chuyển đổi sang \*\*JSON\*\*.





\## 🚀 Cách sử dụng



\### Bắt đầu monitor

```powershell

.\\WMImonitor.ps1 -Start




