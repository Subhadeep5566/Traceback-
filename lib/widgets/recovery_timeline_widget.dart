import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/incident.dart';

class RecoveryTimelineWidget extends StatelessWidget {
  final Incident incident;
  final VoidCallback? onConfirmRecovery;

  const RecoveryTimelineWidget({
    super.key,
    required this.incident,
    this.onConfirmRecovery,
  });

  @override
  Widget build(BuildContext context) {
    final steps = incident.timeline;
    final isRecovered = incident.status == 'Recovered';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRecovered ? const Color(0xFF10B981).withOpacity(0.3) : const Color(0xFF334155),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isRecovered ? Icons.check_circle_outline_rounded : Icons.search_rounded,
                    size: 18,
                    color: isRecovered ? const Color(0xFF10B981) : const Color(0xFF38BDF8),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'RECOVERY PROGRESS',
                    style: TextStyle(
                      color: isRecovered ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isRecovered ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  incident.status.toUpperCase(),
                  style: TextStyle(
                    color: isRecovered ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFF334155)),
          const SizedBox(height: 14),

          // Steps list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: steps.length,
            itemBuilder: (context, index) {
              final step = steps[index];
              final isLast = index == steps.length - 1;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: step.isCompleted ? const Color(0xFF10B981) : const Color(0xFF475569),
                        ),
                        child: Icon(
                          step.isCompleted ? Icons.check : Icons.circle,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 32,
                          color: const Color(0xFF334155),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                step.title,
                                style: const TextStyle(
                                  color: Color(0xFFF1F5F9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                DateFormat('HH:mm').format(step.timestamp),
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            step.description,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          if (!isRecovered && onConfirmRecovery != null) ...[
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: onConfirmRecovery,
                icon: const Icon(Icons.check_circle_rounded, size: 16),
                label: const Text(
                  'MARK AS RECOVERED & SAFE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
