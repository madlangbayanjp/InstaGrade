import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

void main() {
  runApp(const InstagradeApp());
}

class InstagradeApp extends StatelessWidget {
  const InstagradeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Instagrade',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 35, 142, 230),
        ),
        useMaterial3: true,
      ),
      home: const InstagradeHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class InstagradeHome extends StatefulWidget {
  const InstagradeHome({super.key});

  @override
  State<InstagradeHome> createState() => _InstagradeHomeState();
}

class _InstagradeHomeState extends State<InstagradeHome> {
  File? _image;
  String? _extractedText;
  String? _classificationResult;
  int _selectedIndex = 0;
  bool _isProcessing = false;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _extractedText = null;
        _classificationResult = null;
      });
    }
  }

  Future<void> _extractTextFromImage(File imageFile) async {
    setState(() => _isProcessing = true);
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer();
    final RecognizedText recognizedText = await textRecognizer.processImage(
      inputImage,
    );
    await textRecognizer.close();
    setState(() {
      _extractedText = recognizedText.text;
      _isProcessing = false;
    });
  }

  Future<void> _classifyImage(File imageFile) async {
    setState(() => _isProcessing = true);
    final inputImage = InputImage.fromFile(imageFile);
    final imageLabeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.5),
    );
    final List<ImageLabel> labels = await imageLabeler.processImage(inputImage);
    await imageLabeler.close();
    if (labels.isNotEmpty) {
      final topLabel = labels.first;
      setState(() {
        _classificationResult =
            'Label: \\"${topLabel.label}\\"\nConfidence: \\${(topLabel.confidence * 100).toStringAsFixed(2)}%';
        _isProcessing = false;
      });
    } else {
      setState(() {
        _classificationResult = 'No label detected.';
        _isProcessing = false;
      });
    }
  }

  void _onCameraButtonPressed() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.of(context).pop();
                await _pickAndExtractText(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Upload Image'),
              onTap: () async {
                Navigator.of(context).pop();
                await _pickAndExtractText(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndExtractText(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      setState(() {
        _image = imageFile;
      });
      // Extract text
      final inputImage = InputImage.fromFile(imageFile);
      final textRecognizer = TextRecognizer();
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );
      await textRecognizer.close();
      final extractedText = recognizedText.text.toLowerCase();
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Extracted Text:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 12),
                Text(extractedText.isEmpty ? 'No text found.' : extractedText),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Search bar and settings icon
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.black54,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.settings, color: Colors.black87),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
        // Card with illustration and message
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),
                  Container(
                    height: MediaQuery.of(context).size.height * 0.22,
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: Image.asset(
                      'assets/illustration.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'No Tests',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Click below to create test',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 200,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const TestPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7EA6D6),
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Make Tests'),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFBF8),
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.article, color: Color(0xFF2196F3)),
                  SizedBox(height: 2),
                  Text(
                    'Tests',
                    style: TextStyle(
                      color: Color(0xFF2196F3),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _onCameraButtonPressed,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Color(0xFF2196F3), width: 3),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 40,
                    color: Color(0xFF2196F3),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.group, color: Colors.black38),
                  SizedBox(height: 2),
                  Text('Sections', style: TextStyle(color: Colors.black38)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TestPage extends StatefulWidget {
  final String initialTestName;
  const TestPage({Key? key, this.initialTestName = 'Test'}) : super(key: key);

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  late TextEditingController _controller;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTestName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String testName = _controller.text.trim();
    int idx = tests.indexWhere((t) => t.name == testName);
    final test = idx != -1 ? tests[idx] : null;
    return Scaffold(
      backgroundColor: const Color(0xFFFCFBF8),
      body: SafeArea(
        child: Column(
          children: [
            // AppBar row
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 32),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            // Title and subtitle
            Padding(
              padding: const EdgeInsets.only(top: 0, bottom: 8),
              child: Column(
                children: [
                  _editing
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: TextField(
                            controller: _controller,
                            autofocus: true,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) {
                              setState(() => _editing = false);
                            },
                          ),
                        )
                      : GestureDetector(
                          onTap: () => setState(() => _editing = true),
                          child: Text(
                            _controller.text,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => setState(() => _editing = true),
                    child: const Text(
                      'Click to edit test name',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Divider
            Container(
              margin: const EdgeInsets.only(top: 8),
              height: 1,
              color: const Color(0xFFEAEAEA),
            ),
            // Card with illustration and message or questions
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: test == null || test.questions.isEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 32),
                            Container(
                              height: MediaQuery.of(context).size.height * 0.22,
                              constraints: const BoxConstraints(maxHeight: 220),
                              child: Image.asset(
                                'assets/illustration.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 32),
                            const Text(
                              'No Question',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Click below to create question',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: 200,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () {
                                  final String testName = _controller.text
                                      .trim();
                                  if (testName.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Test name cannot be empty.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  int idx = tests.indexWhere(
                                    (t) => t.name == testName,
                                  );
                                  if (idx == -1) {
                                    tests.add(
                                      TestData(name: testName, questions: []),
                                    );
                                    idx = tests.length - 1;
                                  }
                                  Navigator.of(context)
                                      .push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              QuestionPage(testIndex: idx),
                                        ),
                                      )
                                      .then((_) {
                                        if (mounted) setState(() {});
                                      });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF7EA6D6),
                                  foregroundColor: Colors.white,
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text('Make Question'),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
                            const Text(
                              'Questions',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: ListView.builder(
                                itemCount: test.questions.length,
                                itemBuilder: (context, i) {
                                  final q = test.questions[i];
                                  return ListTile(
                                    title: Text(q.question),
                                    subtitle: Text(
                                      'Answer: ${q.answer}\nType: ${q.type} | Points: ${q.points}',
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          test.questions.removeAt(i);
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: 200,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () {
                                  final String testName = _controller.text
                                      .trim();
                                  if (testName.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Test name cannot be empty.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  int idx = tests.indexWhere(
                                    (t) => t.name == testName,
                                  );
                                  if (idx == -1) {
                                    tests.add(
                                      TestData(name: testName, questions: []),
                                    );
                                    idx = tests.length - 1;
                                  }
                                  Navigator.of(context)
                                      .push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              QuestionPage(testIndex: idx),
                                        ),
                                      )
                                      .then((_) {
                                        if (mounted) setState(() {});
                                      });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF7EA6D6),
                                  foregroundColor: Colors.white,
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text('Make Question'),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.article, color: Color(0xFF2196F3)),
                  SizedBox(height: 2),
                  Text(
                    'Tests',
                    style: TextStyle(
                      color: Color(0xFF2196F3),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Color(0xFF2196F3), width: 3),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.camera_alt,
                  size: 40,
                  color: Color(0xFF2196F3),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.group, color: Colors.black38),
                  SizedBox(height: 2),
                  Text('Sections', style: TextStyle(color: Colors.black38)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Question {
  String type;
  int points;
  String question;
  String answer;
  Question({
    required this.type,
    required this.points,
    required this.question,
    required this.answer,
  });
}

class TestData {
  String name;
  List<Question> questions;
  TestData({required this.name, required this.questions});
}

// Global test storage (for demo)
final List<TestData> tests = [];

class QuestionPage extends StatefulWidget {
  final int testIndex;
  const QuestionPage({Key? key, required this.testIndex}) : super(key: key);

  @override
  State<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'Identification';
  int _points = 1;
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();
  bool _showSummary = false;
  List<Question> _tempQuestions = [];

  @override
  void initState() {
    super.initState();
    // Start with a copy of the current test's questions
    _tempQuestions = List<Question>.from(tests[widget.testIndex].questions);
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  void _addQuestion() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _tempQuestions.add(
          Question(
            type: _type,
            points: _points,
            question: _questionController.text.trim(),
            answer: _answerController.text.trim(),
          ),
        );
        _type = 'Identification';
        _points = 1;
        _questionController.clear();
        _answerController.clear();
      });
    }
  }

  void _showConfirmSummary() {
    setState(() {
      _showSummary = true;
    });
  }

  Future<void> _analyzeAndScoreAndReturn() async {
    if (_tempQuestions.isEmpty) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Upload Image'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      final inputImage = InputImage.fromFile(imageFile);
      final textRecognizer = TextRecognizer();
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );
      await textRecognizer.close();
      final extractedText = recognizedText.text.toLowerCase();
      int score = 0;
      List<Map<String, dynamic>> results = [];
      for (final q in _tempQuestions) {
        final found = extractedText.contains(q.answer.toLowerCase());
        if (found) score += q.points;
        results.add({
          'question': q.question,
          'answer': q.answer,
          'correct': found,
        });
      }
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Score'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your score: $score'),
                  const SizedBox(height: 12),
                  ...results.map(
                    (r) => Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          r['correct'] ? Icons.check_circle : Icons.cancel,
                          color: r['correct'] ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Q: ${r['question']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'A: ${r['answer']}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              Text(
                                r['correct'] ? 'Correct' : 'Wrong',
                                style: TextStyle(
                                  color: r['correct']
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) {
        tests[widget.testIndex].questions = List<Question>.from(_tempQuestions);
        Navigator.of(context).pop();
      }
    }
  }

  void _deleteQuestion(int index) {
    setState(() {
      _tempQuestions.removeAt(index);
    });
  }

  void _finalConfirm() {
    // Save questions to the test and go back to TestPage
    tests[widget.testIndex].questions = List<Question>.from(_tempQuestions);
    debugPrint('Saved questions: ${tests[widget.testIndex].questions.length}');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final test = tests[widget.testIndex];
    return Scaffold(
      backgroundColor: const Color(0xFFFCFBF8),
      body: SafeArea(
        child: Column(
          children: [
            // AppBar row
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 32),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            // Title and subtitle
            Padding(
              padding: const EdgeInsets.only(top: 0, bottom: 8),
              child: Column(
                children: [
                  Text(
                    test.name,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Click to edit test name',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            // Divider
            Container(
              margin: const EdgeInsets.only(top: 8),
              height: 1,
              color: const Color(0xFFEAEAEA),
            ),
            // Card with form or summary
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _showSummary
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 24),
                            const Text(
                              'Questions',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: ListView.builder(
                                itemCount: _tempQuestions.length,
                                itemBuilder: (context, i) {
                                  final q = _tempQuestions[i];
                                  return ListTile(
                                    title: Text(q.question),
                                    subtitle: Text(
                                      'Answer: ${q.answer}\nType: ${q.type} | Points: ${q.points}',
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _deleteQuestion(i),
                                    ),
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Row(
                                children: [
                                  // Left Edit button (replaces Save)
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        // Return to add/edit form
                                        setState(() {
                                          _showSummary = false;
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFF2F4F7,
                                        ),
                                        foregroundColor: const Color(
                                          0xFF101828,
                                        ),
                                        textStyle: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: const Text('Edit'),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Right Confirm button (blue, triggers image picker and scoring)
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _tempQuestions.isNotEmpty
                                          ? () async {
                                              try {
                                                await _analyzeAndScoreAndReturn();
                                              } catch (e, st) {
                                                debugPrint(
                                                  'Error during image analysis: $e\n$st',
                                                );
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'An error occurred: $e',
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          : null,
                                      style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateProperty.all<Color>(
                                              const Color(0xFF4A80FF),
                                            ),
                                        foregroundColor:
                                            MaterialStateProperty.all<Color>(
                                              Colors.white,
                                            ),
                                        textStyle:
                                            MaterialStateProperty.all<
                                              TextStyle
                                            >(
                                              const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                        shape:
                                            MaterialStateProperty.all<
                                              RoundedRectangleBorder
                                            >(
                                              RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                        elevation:
                                            MaterialStateProperty.all<double>(
                                              0,
                                            ),
                                      ),
                                      child: const Text('Confirm'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Type',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black26),
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.grey[100],
                                    ),
                                    child: const Text(
                                      'Identification',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    'Points',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove,
                                          size: 32,
                                        ),
                                        onPressed: _points > 1
                                            ? () => setState(() => _points--)
                                            : null,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                        ),
                                        child: Text(
                                          '$_points',
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add, size: 32),
                                        onPressed: () =>
                                            setState(() => _points++),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    'Question',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _questionController,
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(
                                        Icons.help_outline,
                                      ),
                                      hintText: 'Write your question here',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty
                                        ? 'Enter a question'
                                        : null,
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    'Answer',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _answerController,
                                    decoration: InputDecoration(
                                      hintText: 'Write your answer here',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty
                                        ? 'Enter an answer'
                                        : null,
                                  ),
                                  const SizedBox(height: 32),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: _addQuestion,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.grey[200],
                                            foregroundColor: Colors.black54,
                                            textStyle: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: const Text('Add'),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: _showConfirmSummary,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF7EA6D6,
                                            ),
                                            foregroundColor: Colors.white,
                                            textStyle: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: const Text('Save'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.article, color: Color(0xFF2196F3)),
                  SizedBox(height: 2),
                  Text(
                    'Tests',
                    style: TextStyle(
                      color: Color(0xFF2196F3),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Color(0xFF2196F3), width: 3),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.camera_alt,
                  size: 40,
                  color: Color(0xFF2196F3),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.group, color: Colors.black38),
                  SizedBox(height: 2),
                  Text('Sections', style: TextStyle(color: Colors.black38)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
