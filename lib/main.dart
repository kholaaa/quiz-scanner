import 'package:camera/camera.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:confetti/confetti.dart';

const String API_URL = "https://quiz-api-production-e737.up.railway.app";

void main() => runApp(const QuizScannerApp());

class QuizScannerApp extends StatelessWidget {
  const QuizScannerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(elevation: 2, centerTitle: true),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quiz Scanner")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.document_scanner_outlined,
              size: 130,
              color: Colors.indigo,
            ),
            const SizedBox(height: 32),
            const Text(
              "AI Quiz Grader",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const Text(
              "Scan • Grade • Export",
              style: TextStyle(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 70),
            _buildMenuButton(
              context,
              Icons.camera_alt,
              "Single Quiz Scan",
              "Grade one paper",
              Colors.indigo,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScanScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _buildMenuButton(
              context,
              Icons.folder_copy_outlined,
              "Batch Processing",
              "Multiple quizzes → Excel",
              Colors.teal,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BatchScreen()),
              ),
              isOutlined: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap, {
    bool isOutlined = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isOutlined ? null : color,
          border: isOutlined ? Border.all(color: color, width: 2.5) : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 42, color: isOutlined ? color : Colors.white),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isOutlined ? color : Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isOutlined ? Colors.grey : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====================== SCAN SCREEN ======================
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  File? _image;
  bool _loading = false;
  String _status = "";
  String _error = "";

  Future<void> pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() {
      _image = File(picked.path);
      _error = "";
      _status = "";
    });
  }

  Future<Map<String, String>> extractStudentInfoOnDevice(
    String imagePath,
  ) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizer = TextRecognizer();
    final result = await recognizer.processImage(inputImage);
    await recognizer.close();

    String name = "";
    String regNo = "";

    for (var block in result.blocks) {
      for (var line in block.lines) {
        String text = line.text.toLowerCase();
        if (text.contains("name") && name.isEmpty) {
          String lineText = line.text;
          if (lineText.contains(":")) {
            name = lineText.split(":").last.trim();
          }
          if (name.isEmpty || name.length < 2) {
            int lineIdx = block.lines.indexOf(line);
            if (lineIdx + 1 < block.lines.length) {
              name = block.lines[lineIdx + 1].text.trim();
            }
          }
        }
        if ((text.contains("reg") || text.contains("registration")) &&
            regNo.isEmpty) {
          String lineText = line.text;
          if (lineText.contains("#")) {
            regNo = lineText.split("#").last.trim();
          } else if (lineText.contains(":")) {
            regNo = lineText.split(":").last.trim();
          }
          if (regNo.isEmpty || regNo.length < 2) {
            int lineIdx = block.lines.indexOf(line);
            if (lineIdx + 1 < block.lines.length) {
              regNo = block.lines[lineIdx + 1].text.trim();
            }
          }
        }
      }
    }
    return {
      "name": name.isNotEmpty ? name : "Not detected",
      "reg_no": regNo.isNotEmpty ? regNo : "Not detected",
    };
  }

  Future<void> scanQuiz() async {
    if (_image == null) return;
    setState(() {
      _loading = true;
      _status = "Reading student info...";
    });
    try {
      final studentInfo = await extractStudentInfoOnDevice(_image!.path);
      setState(() => _status = "Sending to server for grading...");
      var request = http.MultipartRequest("POST", Uri.parse("$API_URL/scan"));
      request.files.add(
        await http.MultipartFile.fromPath("image", _image!.path),
      );
      setState(() => _status = "AI is grading...");
      var response = await request.send();
      var data = jsonDecode(await response.stream.bytesToString());
      if (data.containsKey("error")) {
        setState(() => _error = data["error"]);
        return;
      }
      if (studentInfo["name"] != "Not detected") {
        data["student"]["name"] = studentInfo["name"];
      }
      if (studentInfo["reg_no"] != "Not detected") {
        data["student"]["reg_no"] = studentInfo["reg_no"];
      }
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ResultScreen(result: data)),
      );
    } catch (e) {
      setState(() => _error = "Connection failed: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Quiz")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              height: 340,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.file(_image!, fit: BoxFit.cover),
                    )
                  : const Center(
                      child: Icon(
                        Icons.add_a_photo_outlined,
                        size: 90,
                        color: Colors.grey,
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Camera"),
                    onPressed: () => pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Gallery"),
                    onPressed: () => pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            if (_image != null)
              _loading
                  ? Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 10),
                        Text(
                          _status,
                          style: const TextStyle(color: Colors.indigo),
                        ),
                      ],
                    )
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.grading),
                      label: const Text(
                        "Grade This Quiz",
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 60),
                      ),
                      onPressed: scanQuiz,
                    ),
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(_error, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}

// ====================== RESULT SCREEN ======================
class ResultScreen extends StatefulWidget {
  final Map result;
  const ResultScreen({super.key, required this.result});
  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    final grade = widget.result["grade"]?["grade"] ?? "F";
    if (grade == "A" || grade == "B") _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Color getGradeColor(String grade) {
    switch (grade) {
      case "A":
        return Colors.green;
      case "B":
        return Colors.blue;
      case "C":
        return Colors.orange;
      case "D":
        return Colors.deepOrange;
      default:
        return Colors.red;
    }
  }

  Widget _buildAnswerKeyRow(Map answers) {
    if (answers.isEmpty) return const Text("Not found");
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: List.generate(8, (i) {
        String q = "Q${i + 1}";
        String ans = answers[q]?.toString() ?? "?";
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.indigo[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.indigo),
          ),
          child: Text(
            "$q=$ans",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.result["student"] ?? {};
    final gradeData = widget.result["grade"] ?? {};
    final breakdown = gradeData["breakdown"] as Map? ?? {};
    final answerKey = widget.result["answer_key"] ?? {};

    return Scaffold(
      appBar: AppBar(title: const Text("Quiz Result")),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Student Info
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.indigo[100],
                          radius: 32,
                          child: const Icon(
                            Icons.person,
                            color: Colors.indigo,
                            size: 36,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student['name'] ?? 'Name not found',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "Reg: ${student['reg_no'] ?? 'Not found'}",
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Grade Card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.indigo[50],
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          "Final Result",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          "${gradeData['score'] ?? '0/0'}",
                          style: const TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                        Text(
                          "${gradeData['percentage']?.toString() ?? '0'}%",
                          style: const TextStyle(fontSize: 26),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: getGradeColor(gradeData['grade'] ?? 'F'),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            "Grade ${gradeData['grade'] ?? 'F'}",
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statCard(
                      "Correct",
                      "${gradeData['correct'] ?? 0}",
                      Colors.green,
                    ),
                    _statCard(
                      "Wrong",
                      "${gradeData['incorrect'] ?? 0}",
                      Colors.red,
                    ),
                    _statCard(
                      "Skipped",
                      "${gradeData['unattempted'] ?? 0}",
                      Colors.grey,
                    ),
                    _statCard(
                      "Invalid",
                      "${gradeData['invalid'] ?? 0}",
                      Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Answer Key Card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.qr_code, color: Colors.indigo),
                            const SizedBox(width: 8),
                            const Text(
                              "Decoded Answer Key",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          answerKey['title']?.toString() ?? '',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        const Divider(height: 20),
                        const Text(
                          "Part-I:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildAnswerKeyRow(Map.from(answerKey['part1'] ?? {})),
                        const SizedBox(height: 12),
                        const Text(
                          "Part-II:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildAnswerKeyRow(Map.from(answerKey['part2'] ?? {})),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Question Breakdown
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Question Breakdown",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...breakdown.entries.map((e) {
                          bool correct = e.value == "correct";
                          bool wrong = e.value == "incorrect";
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              correct
                                  ? Icons.check_circle
                                  : wrong
                                  ? Icons.cancel
                                  : Icons.remove_circle_outline,
                              color: correct
                                  ? Colors.green
                                  : wrong
                                  ? Colors.red
                                  : Colors.grey,
                              size: 22,
                            ),
                            title: Text(
                              e.key
                                  .toString()
                                  .replaceAll("_", " ")
                                  .toUpperCase(),
                              style: const TextStyle(fontSize: 13),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: correct
                                    ? Colors.green
                                    : wrong
                                    ? Colors.red
                                    : Colors.grey,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                correct
                                    ? "✓ Correct"
                                    : wrong
                                    ? "✗ Wrong"
                                    : "— Skipped",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── AR Button ──
                ElevatedButton.icon(
                  icon: const Icon(Icons.view_in_ar),
                  label: const Text(
                    "View Result in AR",
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ARResultScreen(result: widget.result),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label),
      ],
    );
  }
}

// ====================== AR RESULT SCREEN ======================
class ARResultScreen extends StatefulWidget {
  final Map result;
  const ARResultScreen({super.key, required this.result});
  @override
  State<ARResultScreen> createState() => _ARResultScreenState();
}

class _ARResultScreenState extends State<ARResultScreen> {
  CameraController? _cameraController;
  bool _cameraReady = false;
  bool _showOverlay = true;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      _cameraController = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (mounted) setState(() => _cameraReady = true);
    } catch (e) {
      debugPrint("Camera error: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.result["student"] ?? {};
    final gradeData = widget.result["grade"] ?? {};
    final answerKey = widget.result["answer_key"] ?? {};

    final String name = student["name"]?.toString() ?? "Unknown";
    final String regNo = student["reg_no"]?.toString() ?? "";
    final String score = gradeData["score"]?.toString() ?? "0/0";
    final String pct = gradeData["percentage"]?.toString() ?? "0";
    final String grade = gradeData["grade"]?.toString() ?? "F";
    final String title = answerKey["title"]?.toString() ?? "AI Quiz";
    final int correct = gradeData["correct"] ?? 0;
    final int incorrect = gradeData["incorrect"] ?? 0;
    final int unattempted = gradeData["unattempted"] ?? 0;

    Color gradeColor = grade == "A"
        ? Colors.green
        : grade == "B"
        ? Colors.blue
        : grade == "C"
        ? Colors.orange
        : grade == "D"
        ? Colors.deepOrange
        : Colors.red;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera background
          if (_cameraReady && _cameraController != null)
            CameraPreview(_cameraController!)
          else
            Container(
              color: Colors.black,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      "Starting camera...",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

          // AR Overlay
          if (_showOverlay)
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: gradeColor, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: gradeColor.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quiz title
                    Row(
                      children: [
                        const Icon(
                          Icons.qr_code,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Student info
                    Row(
                      children: [
                        const Icon(Icons.person, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              regNo,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Big score
                    Center(
                      child: Column(
                        children: [
                          Text(
                            score,
                            style: TextStyle(
                              color: gradeColor,
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "$pct%",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: gradeColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "Grade $grade",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _arStat(
                          "✅",
                          correct.toString(),
                          "Correct",
                          Colors.green,
                        ),
                        _arStat("❌", incorrect.toString(), "Wrong", Colors.red),
                        _arStat(
                          "—",
                          unattempted.toString(),
                          "Skipped",
                          Colors.grey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.only(
                top: 40,
                bottom: 10,
                left: 16,
                right: 16,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "AR Result View",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      _showOverlay ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white,
                    ),
                    onPressed: () =>
                        setState(() => _showOverlay = !_showOverlay),
                  ),
                ],
              ),
            ),
          ),

          // Bottom hint
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Point camera at quiz paper • Take screenshot to save",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _arStat(String icon, String value, String label, Color color) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 10),
        ),
      ],
    );
  }
}

// ====================== BATCH SCREEN ======================
class BatchScreen extends StatefulWidget {
  const BatchScreen({super.key});
  @override
  State<BatchScreen> createState() => _BatchScreenState();
}

class _BatchScreenState extends State<BatchScreen> {
  List<File> _images = [];
  bool _loading = false;
  String _status = "";
  List _results = [];
  String _downloadFile = "";
  String _errorMsg = "";

  Future<void> pickImages() async {
    final picked = await ImagePicker().pickMultiImage();
    setState(() {
      _images = picked.map((e) => File(e.path)).toList();
      _results = [];
      _downloadFile = "";
      _errorMsg = "";
      _status = "";
    });
  }

  Future<void> processBatch() async {
    if (_images.isEmpty) return;
    setState(() {
      _loading = true;
      _status = "Uploading ${_images.length} images...";
      _results = [];
      _downloadFile = "";
      _errorMsg = "";
    });
    try {
      var request = http.MultipartRequest("POST", Uri.parse("$API_URL/batch"));
      for (var img in _images) {
        request.files.add(
          await http.MultipartFile.fromPath("images", img.path),
        );
      }
      setState(() => _status = "AI is grading all quizzes...");
      var response = await request.send();
      var data = jsonDecode(await response.stream.bytesToString());
      if (data.containsKey("error")) {
        setState(() {
          _errorMsg = data["error"];
          _loading = false;
          _status = "";
        });
        return;
      }
      setState(() {
        _loading = false;
        _status = data["message"] ?? "Done!";
        _results = data["results"] ?? [];
        _downloadFile = data["file"] ?? "";
      });
    } catch (e) {
      setState(() {
        _errorMsg = "Connection failed: $e";
        _loading = false;
        _status = "";
      });
    }
  }

  Future<void> downloadExcel() async {
    if (_downloadFile.isEmpty) return;
    final url = "$API_URL/download/$_downloadFile";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Could not open: $url")));
    }
  }

  Color _gradeColor(String grade) {
    switch (grade) {
      case "A":
        return Colors.green;
      case "B":
        return Colors.blue;
      case "C":
        return Colors.orange;
      case "D":
        return Colors.deepOrange;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Batch Processing")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.photo_library),
              label: const Text("Select Multiple Images"),
              onPressed: pickImages,
            ),
            if (_images.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                "${_images.length} image(s) selected",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(
                height: 70,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _images[i],
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (_images.isNotEmpty && !_loading)
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text(
                  "Process All & Generate Excel",
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 52),
                ),
                onPressed: processBatch,
              ),
            if (_loading) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 10),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.indigo),
              ),
            ],
            if (_errorMsg.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _errorMsg,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (_status.isNotEmpty && !_loading)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (_downloadFile.isNotEmpty) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text(
                  "Download Excel Report",
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  minimumSize: const Size(double.infinity, 52),
                ),
                onPressed: downloadExcel,
              ),
              const SizedBox(height: 4),
              Text(
                _downloadFile,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 12),
            if (_results.isNotEmpty)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Results (${_results.length} students):",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (_, i) {
                          var r = _results[i];
                          final grade = r["Grade"]?.toString() ?? "?";
                          final score = r["Total Marks"]?.toString() ?? "0";
                          final pct = r["Percentage"]?.toString() ?? "0";
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _gradeColor(grade),
                                child: Text(
                                  grade,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                r["Name"]?.toString() ?? "Unknown",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                "Reg: ${r["Reg No"] ?? ''}  •  $pct%",
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "$score/16",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    "marks",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
