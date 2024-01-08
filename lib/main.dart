import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_gemini/google_gemini.dart';
import 'package:google_gemini/src/models/config/gemini_safety_settings.dart';
import 'package:google_gemini/src/models/config/gemini_config.dart';

void main() async {
  await dotenv.load(fileName: "lib/.env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gemini Flutter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Google Gemini '),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController textEditingController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  List<Map<String, String>> responseList = [];
  bool isLoading = false;
  // Safety Settings

  final gemini = GoogleGemini(
      apiKey: dotenv.env['GOOGLE_AI_API']!,
      config: GenerationConfig(
          temperature: 0.5,
          maxOutputTokens: 100,
          topP: 1.0,
          topK: 40,
          stopSequences: []),
      safetySettings: [
        SafetySettings(
            category: SafetyCategory.HARM_CATEGORY_DANGEROUS_CONTENT,
            threshold: SafetyThreshold.BLOCK_ONLY_HIGH)
        // safety2
      ]);

  void _sendQuery() {
    responseList.add(
        {'type': 'question', 'text': textEditingController.text.toString()});
    setState(() {
      isLoading = true;
    });
    gemini
        .generateFromText(textEditingController.text.toString())
        .then((value) {
      textEditingController.clear();

      setState(() {
        responseList.add({'type': 'answer', 'text': value.text});

        isLoading = false;
      });
      // scrollController.jumpTo(scrollController.position.maxScrollExtent);
    }).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Try again.')));
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: EdgeInsets.only(bottom: size.height * 0.1),
        child: responseList.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/gemini_logo.png',
                      width: size.width * 0.4,
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: responseList.length,
                      itemBuilder: (context, index) {
                        bool question =
                            responseList[index]['type'] == 'question';
                        return ListTile(
                          dense: true,
                          isThreeLine:
                              true, // Set this to true to prevent the leading element from being vertically centered

                          leading: !question
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                      color: Colors.blueAccent.shade100,
                                      borderRadius: BorderRadius.circular(7)),
                                  child: const Text(
                                    'G',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                )
                              : const SizedBox(),
                          trailing: question
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                      borderRadius: BorderRadius.circular(9)),
                                  child: const Text(
                                    'U',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                )
                              : const SizedBox(),
                          title: TextWithBold(
                            responseText: responseList[index]['text'] ?? "",
                            question: question,
                          ),
                          subtitle: const Text(""),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: Container(
        decoration: const BoxDecoration(color: Colors.white),
        padding: const EdgeInsets.only(left: 30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // FloatingActionButton(
            //   onPressed: _sendQuery,
            //   tooltip: 'Increment',
            //   child: const Icon(Icons.add_a_photo),
            // ),
            const SizedBox(
              width: 5,
            ),
            Expanded(
              child: TextField(
                controller: textEditingController,
                readOnly: isLoading,
                onSubmitted: (string) => _sendQuery(),
                decoration: InputDecoration(
                  hintText: 'Enter your query',
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                ),
              ),
            ),
            const SizedBox(
              width: 15,
            ),
            FloatingActionButton(
              onPressed: !isLoading ? _sendQuery : null,
              tooltip: 'Increment',
              child: isLoading
                  ? const SizedBox(
                      height: 15,
                      width: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}

class TextWithBold extends StatelessWidget {
  final String responseText;
  final bool question;

  const TextWithBold(
      {super.key, required this.responseText, required this.question});

  @override
  Widget build(BuildContext context) {
    List<TextSpan> children = [];

    final RegExp boldRegex = RegExp(r'\*\*(.*?)\*\*');

    String remainingText = responseText;
    while (boldRegex.hasMatch(remainingText)) {
      Match match = boldRegex.firstMatch(remainingText)!;
      children.add(TextSpan(text: remainingText.substring(0, match.start)));

      // Add bold part
      children.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));

      // Update remaining text
      remainingText = remainingText.substring(match.end);
    }

    // Add any remaining regular text after the last bold part
    children.add(TextSpan(text: remainingText));

    return RichText(
      textAlign: !question ? TextAlign.left : TextAlign.right,
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: children,
      ),
    );
  }
}
