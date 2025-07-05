import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class JobQuestionsWidget extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  final Function(List<Map<String, dynamic>>) onAnswersChanged;
  final List<Map<String, dynamic>>? initialAnswers;

  const JobQuestionsWidget({
    Key? key,
    required this.questions,
    required this.onAnswersChanged,
    this.initialAnswers,
  }) : super(key: key);

  @override
  State<JobQuestionsWidget> createState() => _JobQuestionsWidgetState();
}

class _JobQuestionsWidgetState extends State<JobQuestionsWidget> {
  final Map<String, dynamic> _answers = {};
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, String> _errors = {};

  @override
  void initState() {
    super.initState();
    _initializeAnswers();
    _initializeControllers();
  }

  @override
  void dispose() {
    // Dispose all text controllers
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeAnswers() {
    // Initialize with existing answers if provided
    if (widget.initialAnswers != null) {
      for (final answer in widget.initialAnswers!) {
        final questionId = answer['question_id'];
        _answers[questionId] = {
          'question_id': questionId,
          'answer_text': answer['answer_text'],
          'selected_options': answer['selected_options'],
        };
      }
    }
  }

  void _initializeControllers() {
    for (final question in widget.questions) {
      final questionId = question['id'];
      final questionType = question['question_type'];

      if (['text', 'number', 'date', 'time'].contains(questionType)) {
        final existingAnswer = _answers[questionId];
        _textControllers[questionId] = TextEditingController(
          text: existingAnswer?['answer_text'] ?? '',
        );
      }
    }
  }

  void _updateAnswer(String questionId, Map<String, dynamic> answerData) {
    setState(() {
      _answers[questionId] = {
        'question_id': questionId,
        ...answerData,
      };
      _errors.remove(questionId); // Clear error when answer is updated
    });

    _notifyAnswersChanged();
  }

  void _notifyAnswersChanged() {
    final answersList = _answers.values
        .map((answer) => Map<String, dynamic>.from(answer))
        .toList();
    widget.onAnswersChanged(answersList);
  }

  bool _validateAnswers() {
    bool isValid = true;
    _errors.clear();

    for (final question in widget.questions) {
      final questionId = question['id'];
      final isRequired = question['is_required'] ?? false;
      final questionText = question['question'] ??
          question['question_text']; // Support both formats
      final questionType = question['question_type'];

      if (!isRequired) continue;

      final answer = _answers[questionId];

      if (answer == null) {
        _errors[questionId] = 'This question is required';
        isValid = false;
        continue;
      }

      // Validate based on question type
      switch (questionType) {
        case 'text':
          final text = answer['answer_text'] ?? '';
          if (text.toString().trim().isEmpty) {
            _errors[questionId] = 'Please provide an answer';
            isValid = false;
          }
          break;
        case 'number':
          final text = answer['answer_text'] ?? '';
          if (text.toString().trim().isEmpty) {
            _errors[questionId] = 'Please enter a number';
            isValid = false;
          } else if (answer['answer_number'] == null) {
            _errors[questionId] = 'Please enter a valid number';
            isValid = false;
          }
          break;
        case 'yes_no':
          final selection = answer['answer_text'] ?? '';
          if (selection.toString().trim().isEmpty) {
            _errors[questionId] = 'Please make a selection';
            isValid = false;
          }
          break;
        case 'multiple_choice':
          final selection = answer['answer_text'] ?? '';
          if (selection.toString().trim().isEmpty) {
            _errors[questionId] = 'Please make a selection';
            isValid = false;
          }
          break;
        case 'checkbox':
          final selections = answer['selected_options'] as List<dynamic>?;
          if (selections == null || selections.isEmpty) {
            _errors[questionId] = 'Please make at least one selection';
            isValid = false;
          }
          break;
        case 'date':
          final dateText = answer['answer_text'] ?? '';
          if (dateText.toString().trim().isEmpty) {
            _errors[questionId] = 'Please select a date';
            isValid = false;
          }
          break;
        case 'time':
          final timeText = answer['answer_text'] ?? '';
          if (timeText.toString().trim().isEmpty) {
            _errors[questionId] = 'Please select a time';
            isValid = false;
          }
          break;
      }
    }

    setState(() {});
    return isValid;
  }

  Widget _buildQuestionWidget(Map<String, dynamic> question) {
    final questionId = question['id'];
    final questionText = question['question'] ??
        question['question_text']; // Support both formats
    final questionType = question['question_type'];
    final isRequired = question['is_required'] ?? true;
    final options = question['options'] as List<dynamic>?;
    final placeholderText = question['placeholder_text'];
    final hasError = _errors.containsKey(questionId);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question text
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              children: [
                TextSpan(text: questionText),
                if (isRequired)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Answer input widget
          _buildAnswerInput(question),

          // Error message
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _errors[questionId]!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnswerInput(Map<String, dynamic> question) {
    final questionId = question['id'];
    final questionType = question['question_type'];
    final options = question['options'] as List<dynamic>?;
    final placeholderText = question['placeholder_text'];
    final hasError = _errors.containsKey(questionId);

    switch (questionType) {
      case 'text':
        return TextField(
          controller: _textControllers[questionId],
          decoration: InputDecoration(
            hintText: placeholderText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red : Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red : Theme.of(context).primaryColor,
              ),
            ),
          ),
          maxLines: ((question['question'] ?? question['question_text'])
                      ?.toString()
                      .toLowerCase()
                      .contains('describe') ??
                  false)
              ? 3
              : 1,
          onChanged: (value) {
            _updateAnswer(questionId, {'answer_text': value});
          },
        );

      case 'number':
        return TextField(
          controller: _textControllers[questionId],
          decoration: InputDecoration(
            hintText: placeholderText ?? 'Enter a number',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red : Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red : Theme.of(context).primaryColor,
              ),
            ),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final numValue = double.tryParse(value);
            _updateAnswer(questionId, {
              'answer_text': value,
              'answer_number': numValue,
            });
          },
        );

      case 'yes_no':
        final currentSelection = _answers[questionId]?['answer_text'] ?? '';

        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: hasError ? Colors.red : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              RadioListTile<String>(
                title: const Text('Yes'),
                value: 'Yes',
                groupValue: currentSelection,
                onChanged: (value) {
                  if (value != null) {
                    _updateAnswer(questionId, {
                      'answer_text': value,
                      'answer_boolean': true,
                    });
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('No'),
                value: 'No',
                groupValue: currentSelection,
                onChanged: (value) {
                  if (value != null) {
                    _updateAnswer(questionId, {
                      'answer_text': value,
                      'answer_boolean': false,
                    });
                  }
                },
              ),
            ],
          ),
        );

      case 'multiple_choice':
        if (options == null) return const SizedBox();

        final currentSelection = _answers[questionId]?['answer_text'] ?? '';

        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: hasError ? Colors.red : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: options.map<Widget>((option) {
              final optionStr = option.toString();
              return RadioListTile<String>(
                title: Text(optionStr),
                value: optionStr,
                groupValue: currentSelection,
                onChanged: (value) {
                  if (value != null) {
                    _updateAnswer(questionId, {'answer_text': value});
                  }
                },
              );
            }).toList(),
          ),
        );

      case 'checkbox':
        if (options == null) return const SizedBox();

        final currentSelections =
            (_answers[questionId]?['selected_options'] as List<dynamic>?) ?? [];

        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: hasError ? Colors.red : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: options.map<Widget>((option) {
              final optionStr = option.toString();
              final isSelected = currentSelections.contains(optionStr);

              return CheckboxListTile(
                title: Text(optionStr),
                value: isSelected,
                onChanged: (checked) {
                  final newSelections = List<dynamic>.from(currentSelections);
                  if (checked == true) {
                    if (!newSelections.contains(optionStr)) {
                      newSelections.add(optionStr);
                    }
                  } else {
                    newSelections.remove(optionStr);
                  }
                  _updateAnswer(
                      questionId, {'selected_options': newSelections});
                },
              );
            }).toList(),
          ),
        );

      case 'date':
        final currentDate = _answers[questionId]?['answer_text'] ?? '';

        return InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );

            if (date != null) {
              final formattedDate = DateFormat('yyyy-MM-dd').format(date);
              _textControllers[questionId]?.text = formattedDate;
              _updateAnswer(questionId, {'answer_text': formattedDate});
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: hasError ? Colors.red : Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currentDate.isEmpty ? 'Select a date' : currentDate,
                  style: TextStyle(
                    color: currentDate.isEmpty ? Colors.grey : Colors.black87,
                  ),
                ),
                const Icon(Icons.calendar_today, color: Colors.grey),
              ],
            ),
          ),
        );

      case 'time':
        final currentTime = _answers[questionId]?['answer_text'] ?? '';

        return InkWell(
          onTap: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );

            if (time != null) {
              final formattedTime = time.format(context);
              _textControllers[questionId]?.text = formattedTime;
              _updateAnswer(questionId, {'answer_text': formattedTime});
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: hasError ? Colors.red : Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currentTime.isEmpty ? 'Select a time' : currentTime,
                  style: TextStyle(
                    color: currentTime.isEmpty ? Colors.grey : Colors.black87,
                  ),
                ),
                const Icon(Icons.access_time, color: Colors.grey),
              ],
            ),
          ),
        );

      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Job Specific Questions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Please answer the following questions to help helpers understand your specific requirements.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),

        // Questions list
        ...widget.questions.map((question) => _buildQuestionWidget(question)),
      ],
    );
  }

  // Public method to validate answers (can be called from parent)
  bool validateAnswers() {
    return _validateAnswers();
  }

  // Public method to get current answers
  List<Map<String, dynamic>> getCurrentAnswers() {
    return _answers.values
        .map((answer) => Map<String, dynamic>.from(answer))
        .toList();
  }
}
