# Quiz Scanner – AI-Powered OMR Evaluation System

## 📌 Project Overview

Quiz Scanner is an AI-powered quiz evaluation system that uses **OMR (Optical Mark Recognition)** and **QR Code scanning** to automate the grading of answer sheets. The Flutter mobile app captures a photo of a quiz sheet and sends it to a Python/Flask backend hosted on the cloud, which processes the image using OpenCV, extracts student information via OCR, evaluates the marked answers, and returns a complete grade all in seconds.

The goal of this project is to eliminate manual grading, improve accuracy, and provide a fast, efficient evaluation workflow for educational institutions.

---

## ✨ Key Features

- QR Code scanning to extract quiz metadata and answer keys
- OMR bubble detection and evaluation using OpenCV
- Handwritten OCR for student name and registration number (Google ML Kit + Tesseract)
- Automatic answer checking with negative marking support
- Per-question breakdown with tick / cross / dash indicators
- Batch grading support for multiple answer sheets
- Excel (.xlsx) result export with summary statistics
- History management
- Cloud-hosted backend (Railway) with Flutter mobile frontend

---

## ✅ Tasks Completed

### Task 1 – QR Code Processing

| Requirement | Status |
|---|---|
| Accept JPG/PNG as input | ✅ Done |
| Locate QR anywhere on page | ✅ Done |
| Handle rotation / skew / glare | ✅ Done (multiple preprocessing methods) |
| Quiz set identifier | ✅ Done |
| Correct answers Part-I Q01–Q08 | ✅ Done |
| Correct answers Part-II Q01–Q08 | ✅ Done |
| Display answer key in readable format | ✅ Done |

### Task 2 – Student Information Extraction (OCR)

| Requirement | Status |
|---|---|
| Locate Name and Registration # fields | ✅ Done |
| Extract handwritten text | ✅ Google ML Kit |
| Handle OCR noise / smudges | ✅ Multiple preprocessing methods |
| Return `{name: string, reg_no: string}` | ✅ Done |
| Correct field region detection (5 pts) | ✅ Done |
| Accurate OCR for printed text (5 pts) | ✅ Tesseract |
| Reasonable accuracy for handwriting (+5 pts) | ✅ ML Kit |

### Task 3 – OMR Bubble Detection

| Requirement | Status |
|---|---|
| Detect answer grid / table | ✅ Done |
| Identify filled bubble A/B/C/D for Q01–Q08 | ✅ Done |
| Handle partially filled bubbles | ✅ Fill ratio threshold 0.28 |
| Handle unattempted questions (null) | ✅ Done |
| Flag multi-filled answers as INVALID | ✅ Done |
| Correctly reads 16 bubbles on clean scan (12 pts) | ✅ Done |
| Handles image tilt / warp (+4 pts) | ✅ Perspective correction |
| Flags invalid bubbles (+4 pts) | ✅ Done |

### Task 4 – Answer Evaluation

| Requirement | Status |
|---|---|
| Compare each answer bubble-by-bubble against key | ✅ Done in `grade()` function |
| Count correct, incorrect, unattempted | ✅ Done |
| Calculate total marks (1 per correct) | ✅ Done |
| Negative marking if specified in QR | ✅ Done — checks for "negative" in QR payload |
| Per-question breakdown (tick / cross / dash) | ✅ Done in result screen |
| Display final score e.g. 12/16 | ✅ Done |
| Handle invalid (multi-filled) responses | ✅ Done |

### Task 5 – Excel Export

| Column Required | Status |
|---|---|
| Quiz, Set, Class, Subject | ✅ Done |
| Name, Reg No | ✅ Done |
| Part1_Q01 … Part1_Q08 | ✅ Done |
| Part2_Q01 … Part2_Q08 | ✅ Done |
| Correct, Incorrect, Unattempted | ✅ Done |
| Total Marks, Percentage, Grade | ✅ Done |
| Auto-named with quiz title + timestamp | ✅ Done |
| Summary row (avg, highest, lowest) | ✅ Done |

---

## ⚠️ For Best Results

Accuracy depends heavily on image quality. Detection may fail if:

- The answer sheet is blurry or low-resolution
- The scan is excessively tilted
- The image contains shadows or glare
- Bubbles are not filled clearly
- The sheet is damaged or incomplete

**Best practices:**

- Use a well-lit environment when photographing the sheet
- Hold the phone directly above the sheet (flat, not at an angle)
- Fill bubbles completely and clearly
- Ensure the full sheet is visible within the frame

---

## 🛠 Technologies & Libraries Used

### Flutter App (`quiz_scanner`)

| Category | Details |
|---|---|
| Language | Dart |
| Framework | Flutter SDK |
| Packages | `image_picker`, `mobile_scanner`, `http`, `excel`, `path_provider`, `provider` |
| Platforms | Android |

### Python Backend (`quiz_api`)

| Category | Details |
|---|---|
| Language | Python |
| Framework | Flask |
| Libraries | OpenCV, NumPy, Pyzbar, Tesseract (pytesseract), Pillow |
| Deployment | Railway (cloud) |
| Output | JSON response with grades + Excel file |

---

## 🚀 Installation & Setup

### Prerequisites

- [ ] Python installed
- [ ] VS Code + extensions
- [ ] Flutter installed
- [ ] Android Studio installed
- [ ] Git installed

### Backend Setup (`quiz_api`)

```bash
# Clone the repository
git clone https://github.com/your-username/quiz-scanner.git
cd quiz-scanner/quiz_api

# Install Python dependencies
pip install -r requirements.txt

# Run locally
python app.py
```

Deploy to Railway:
1. Push `quiz_api/` to GitHub
2. Connect the repository to [Railway](https://railway.app)
3. Railway auto-detects `Procfile` and `runtime.txt` and deploys

### Flutter App Setup (`quiz_scanner`)

```bash
cd quiz_scanner

# Install Flutter packages
flutter pub get

# Add your Railway backend URL in the app config
# (update the base URL constant in lib/main.dart)

# Connect Android phone via USB and run
flutter run
```

---

## 📖 How to Use

**Scan a Sheet**
1. Open the app and tap **Scan Quiz**.
2. Point the camera at the answer sheet — the app captures and uploads the image.
3. The backend processes the QR code, extracts student info, detects bubbles, and returns grades.
4. View the per-question breakdown and final score on the result screen.

**Batch Grading**
1. Select multiple images from your gallery.
2. Tap **Run Batch** — all sheets are processed and combined into one report.

**Export Results**
1. From the result or history screen, tap **Export Excel**.
2. The `.xlsx` file is saved to your device with all columns and a summary row.

---

## 📂 Project Structure

```
quiz-scanner/
│
├── quiz_api/                  # Python Flask backend
│   ├── app.py
│   ├── requirements.txt
│   ├── Procfile
│   └── runtime.txt
│
├── quiz_scanner/              # Flutter mobile app
│   ├── android/
│   ├── lib/
│   │   └── main.dart
│   ├── pubspec.yaml
│   └── pubspec.lock
│
└── README.md
```

---

## 👥 Team Contributions

Khola Asghar 
Marwa Sajjad
Syeda Eman

---

## 🔮 Future Enhancements

- Support for additional OMR sheet templates
- Improved automatic rotation and perspective correction
- Cloud storage for result history
- Teacher dashboard with analytics
- iOS support
- Offline mode with on-device inference
