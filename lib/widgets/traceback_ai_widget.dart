import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/asset.dart';
import '../models/incident.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';

class TracebackAIWidget extends StatefulWidget {
  final Asset asset;
  final Incident incident;

  const TracebackAIWidget({
    super.key,
    required this.asset,
    required this.incident,
  });

  @override
  State<TracebackAIWidget> createState() => _TracebackAIWidgetState();
}

class _TracebackAIWidgetState extends State<TracebackAIWidget> {
  final AIService _aiService = AIService();
  final TextEditingController _questionController = TextEditingController();
  final _scrollController = ScrollController();

  String? _apiKey;
  bool _isLoading = false;
  String _selectedAction = 'summary';
  String? _lastResponse;
  String? _error;

  final List<_AIAction> _actions = [
    _AIAction(
      id: 'summary',
      label: 'Summarize Incident',
      icon: Icons.summarize_rounded,
      description: 'Get a concise incident overview',
    ),
    _AIAction(
      id: 'location',
      label: 'Analyze Location',
      icon: Icons.location_on_rounded,
      description: 'Understand detection patterns',
    ),
    _AIAction(
      id: 'guidance',
      label: 'Recovery Guidance',
      icon: Icons.directions_rounded,
      description: 'Actionable next steps',
    ),
    _AIAction(
      id: 'report',
      label: 'Generate Report',
      icon: Icons.description_rounded,
      description: 'Formal incident report',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final storage = context.read<StorageService>();
    _apiKey = storage.getSetting('gemini_api_key') as String?;
    if (_apiKey != null && _apiKey!.isNotEmpty) {
      await _aiService.initialize(_apiKey!);
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    _aiService.dispose();
    super.dispose();
  }

  Future<void> _runAction(String actionId) async {
    if (!_aiService.isAvailable) {
      setState(() => _error = 'AI not configured. Add API key in settings.');
      return;
    }

    setState(() {
      _isLoading = true;
      _selectedAction = actionId;
      _lastResponse = null;
      _error = null;
    });

    String? response;
    try {
      switch (actionId) {
        case 'summary':
          response = await _aiService.summarizeIncident(widget.incident, widget.asset);
          break;
        case 'location':
          response = await _aiService.analyzeLocation(widget.incident, widget.asset);
          break;
        case 'guidance':
          response = await _aiService.generateRecoveryGuidance(widget.incident, widget.asset);
          break;
        case 'report':
          response = await _aiService.generateIncidentReport(widget.incident, widget.asset);
          break;
      }
    } catch (e) {
      response = 'Error: ${e.toString()}';
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _lastResponse = response;
      });
      _scrollToBottom();
    }
  }

  Future<void> _askQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty || !_aiService.isAvailable) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await _aiService.answerQuestion(widget.incident, widget.asset, question);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _lastResponse = response;
        _questionController.clear();
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isStolen = widget.asset.status == AssetStatus.stolen;
    final isAvailable = _aiService.isAvailable;

    if (!isStolen) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology_rounded, size: 18, color: const Color(0xFF38BDF8)),
                const SizedBox(width: 8),
                const Text(
                  'TRACEBACK AI',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Traceback AI is available when an asset is in Lost/Tracking mode. Mark this asset as missing to activate AI assistance.',
              style: TextStyle(color: Colors.grey[500], fontSize: 13, height: 1.4),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAvailable ? const Color(0xFF38BDF8).withOpacity(0.5) : const Color(0xFF334155),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.psychology_rounded, size: 18, color: Color(0xFF38BDF8)),
              ),
              const SizedBox(width: 10),
              const Text(
                'TRACEBACK AI',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              if (!isAvailable)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)),
                  ),
                  child: const Text(
                    'Setup Required',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Action Buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _actions.map((action) {
              final isSelected = _selectedAction == action.id;
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(action.icon, size: 14, color: isSelected ? Colors.white : const Color(0xFF38BDF8)),
                    const SizedBox(width: 6),
                    Text(action.label),
                  ],
                ),
                selected: isSelected,
                selectedColor: const Color(0xFF38BDF8),
                backgroundColor: const Color(0xFF0F172A),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF334155),
                ),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                onSelected: isAvailable ? (selected) {
                    if (selected) _runAction(action.id);
                  } : null,
                tooltip: action.description,
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Response Area
          if (_error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          if (_lastResponse != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.psychology_rounded, size: 14, color: Color(0xFF38BDF8)),
                      const SizedBox(width: 6),
                      Text(
                        _actions.firstWhere((a) => a.id == _selectedAction).label,
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (_isLoading)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _lastResponse ?? '',
                    style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),

          if (_lastResponse == null && !_isLoading && _error == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                children: [
                  Icon(Icons.lightbulb_outline_rounded, size: 32, color: Colors.grey[700]),
                  const SizedBox(height: 8),
                  Text(
                    'Select an action above to get AI assistance',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Or ask a question below',
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Ask a Question
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _questionController,
                  enabled: isAvailable && !_isLoading,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Ask about this recovery...',
                    hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: const Color(0xFF334155)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: const Color(0xFF334155)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 2),
                    ),
                  ),
                  onSubmitted: (_) => _askQuestion(),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: isAvailable ? const Color(0xFF38BDF8) : const Color(0xFF334155),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: isAvailable && !_isLoading ? _askQuestion : null,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),

          if (!isAvailable) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'To enable Traceback AI, add your Gemini API key in Settings. The AI will then provide contextual recovery assistance.',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AIAction {
  final String id;
  final String label;
  final IconData icon;
  final String description;

  const _AIAction({
    required this.id,
    required this.label,
    required this.icon,
    required this.description,
  });
}