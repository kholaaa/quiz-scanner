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

##  For Best Results

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

### Flutter App (`quiz-scanner`)

| Category | Details |
|---|---|
| Language | Dart |
| Framework | Flutter SDK |
| Packages | `image_picker`, `mobile_scanner`, `http`, `excel`, `path_provider`, `provider` |
| Platforms | Android |

### Python Backend (`quiz-api`)

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

### Backend Setup (`quiz-api`)

```bash
# Clone the repository
git clone https://github.com/your-username/quiz-scanner.git
cd quiz-scanner/quiz-api

# Install Python dependencies
pip install -r requirements.txt

# Run locally
python app.py
```

Deploy to Railway:
1. Push `quiz_api/` to GitHub
2. Connect the repository to [Railway](https://railway.app)
3. Railway auto-detects `Procfile` and `runtime.txt` and deploys

### Flutter App Setup (`quiz-scanner`)

```bash
cd quiz-scanner

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

##OMR DETECTION 
<img width="638" height="790" alt="image" src="https://github.com/user-attachments/assets/15c58eef-a856-4935-8168-90692ccba9cf" />
<img width="472" height="502" alt="image" src="https://github.com/user-attachments/assets/86cc22d7-18df-4a3e-a21f-7c5a18d5253d" />
<img width="562" height="798" alt="image" src="https://github.com/user-attachments/assets/1416bdfd-3b6a-461a-a2ac-08381f3748de" />
<img width="230" height="468" alt="image" src="https://github.com/user-attachments/assets/3d8fd8ec-609d-483b-93f4-a32a8c6eed45" />
<img width="572" height="767" alt="image" src="https://github.com/user-attachments/assets/36a76c51-3741-4692-a5fb-d14bf98e6e0e" />

##Batch processing
<img width="343" height="708" alt="image" src="https://github.com/user-attachments/assets/596d73cc-5fb7-44f1-9cc3-b3eb83a4864a" />
<img width="321" height="677" alt="image" src="https://github.com/user-attachments/assets/e2df7bbe-f86a-45d2-ab24-ef924af228cc" />
<img width="555" height="445" alt="image" src="https://github.com/user-attachments/assets/0d59c655-73f6-430e-8b47-52e21ddb4742" />

##Bonus Task
<img width="396" height="735" alt="image" src="https://github.com/user-attachments/assets/8681d23d-40ee-4e00-be09-2097ab4ef232" />
<img width="397" height="732" alt="image" src="https://github.com/user-attachments/assets/87cf7629-3461-4d6e-b95d-afebb2a8d172" />
<img width="557" height="562" alt="image" src="https://github.com/user-attachments/assets/ce237ac3-5ef5-4b59-a74b-2c93d3204c35" />
<img width="402" height="737" alt="image" src="https://github.com/user-attachments/assets/2e9e1788-9b15-4483-b803-e0813e2b0461" />
<img width="405" height="748" alt="image" src="https://github.com/user-attachments/assets/79735b06-8c91-47d4-aecf-e59a684ccd28" />
<img width="405" height="740" alt="image" src="https://github.com/user-attachments/assets/9e692fc9-6560-4569-b184-6c25f392546d" />
<img width="405" height="740" alt="image" src="https://github.com/user-attachments/assets/f59d6813-1842-480f-b641-721464e85d19" />


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
