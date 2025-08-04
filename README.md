# 📍Location-Based Attendance Syste
<table>
  <tr>
    <td>
      <img src="https://github.com/user-attachments/assets/a8ed1404-be55-4265-9c46-d00830f122a9" alt="geomark-showcase" />
    </td>
    <td>
        GeoMark, a Flutter-based mobile application that automates attendance marking using geofencing technology.<br>
        This app is ideal for educational institutions aiming to streamline attendance tracking via mobile devices.
    </td>
  </tr>
</table>

## 🔑 Key Features

### ✅ Geofence-Based Attendance Marking
  - Ensures users are within a specific location radius before allowing attendance actions.

### ✅ Real-Time Location Detection
  - Uses device GPS to verify user proximity to predefined coordinates.

### ✅ Attendance Records
  - Saves attendance records with timestamps for audit and review.

### ✅ Location Status Alerts
  - Notifies users about attendance status (e.g., outside the predefined area, inside the predefined area).

---

## 👥 User Roles

### 👨‍🎓 Student
- **Mark Attendance:** Students can mark their attendance only when physically present within the geofenced area.
- **Attendance History:** Students can view their own attendance records and leave request status.
- **Leave Requests:** Students can submit leave requests and track their approval status.

### 👨‍🏫 Staff
- **Attendance Management:** Staff can view and manage attendance records for their assigned subjects.
- **Analytics:** Staff have access to attendance analytics, including pie charts and statistics for their subjects.
- **Report Generation:** Staff can export pie charts as pdf file.

### 👩‍💼 Admin
- **Approve/Reject Leave:** Staff can review, approve, or reject student leave requests.
- **System Configuration:** Admins can set up geofence locations, manage subjects, tutorial groups and timetable.

---

## 💻 Tech Stack
<table>
  <tr>
    <td>
      <b>Frontend:</b>
    </td>
    <td>
      <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
    </td>
  </tr>
  <tr>
    <td>
      <b>Backend:</b>
    </td>
    <td>
      <img src="https://img.shields.io/badge/firebase-ffca28?style=for-the-badge&logo=firebase&logoColor=black" />
      <img src="https://img.shields.io/badge/Cloudinary-3448C5?style=for-the-badge&logo=Cloudinary&logoColor=white" />
    </td>
  </tr>
</table>

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK
- Firebase Project (Cloud Firestore)
- Cloudinary Project (Media Storage)

### Installation
```bash
git clone https://github.com/ObsCure9277/Location-Based-Attendance-System.git
cd Location-Based-Attendance-System
flutter clean
flutter pub get
```

### Run the App

> 🔑 Make sure to set up `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) in the correct directories before running the app.
```bash
flutter run
```

---


