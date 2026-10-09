# Nav App - ung dung dan duong cho o to (Flutter + Vietmap SDK)

Du an Flutter tu dong build file APK tren GitHub Actions. Dung SDK cong khai
`vietmap_flutter_navigation` va Maps API cua Vietmap. Day la ung dung doc lap,
khong phai san pham chinh thuc cua Vietmap.

## Tinh nang

| Nhom | Trang thai |
|---|---|
| Dan duong tung buoc (banner re, xem lai lo trinh, tim kiem, nhan giu tren ban do de chi duong) | Co - do SDK Vietmap cung cap |
| Hien thi thong tin lan duong / giao lo giao thong | Phu thuoc SDK va du lieu Vietmap, chua xac minh duoc ban 4.2.0 hien thi gi |
| Canh bao giao thong: cam re theo khung gio, cam vuot, khu dan cu, doan cam dung theo gio, cam dung/do chan-le, lan dung khan cap, camera | Co khung xu ly (`lib/services/traffic_rules.dart`); du lieu mau o `assets/data/traffic_rules.json`, can thay bang nguon that |
| Toc do gioi han hien tai / tiep theo / canh bao vuot toc | Co khung xu ly; du lieu mau o `assets/data/speed_zones.json`, toc do xe lay tu GPS |
| Thong bao so du ePass | Chi co giao dien trong (`epass_service.dart`); chua co API cong khai |
| Android Auto | Chua co - can module Android Car App Library rieng |
| CarPlay | Khong the trong file APK (chi danh cho iOS) |

## Cach dung

1. Xin API key Vietmap tai https://vietmap.vn/maps-api
2. Tao repo tren GitHub, day toan bo thu muc nay len nhanh `main`.
3. Vao **Settings > Secrets and variables > Actions > New repository secret**, tao
   secret `VIETMAP_API_KEY`.
4. Vao tab **Actions > Build APK > Run workflow**. Xong tai file `app-release.apk`
   o muc **Artifacts**. Day tag `v1.0.0` de tu dong dang len **Releases**.

Build local:

```bash
flutter create --platforms=android --org vn.example --project-name nav_app .
python3 scripts/patch_android.py .
flutter pub get
flutter run --dart-define=VIETMAP_API_KEY=xxxx
```

## Luu y

- APK build ra duoc ky bang khoa debug; muon len CH Play phai tu cau hinh keystore.
- Ma nguon chua duoc bien dich thu trong moi truong tao ra no; lan chay dau tien neu
  CI bao loi ten ham/tham so cua SDK, doi chieu voi
  https://pub.dev/documentation/vietmap_flutter_navigation/latest/
- Du lieu canh bao va toc do trong `assets/data/` chi la du lieu mau o TP.HCM.
