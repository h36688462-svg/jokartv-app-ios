import 'package:flutter/material.dart';

class TvGuideScreen extends StatelessWidget {
  const TvGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final timeSlots = ['06:00 AM', '09:00 AM', '12:00 PM', '03:00 PM', '06:00 PM', '09:00 PM', '12:00 AM'];
    final channels = [
      {'name': 'BeIN Sports 1 HD', 'now': 'UEFA Champions League Live', 'next': 'Match Analysis & Highlights'},
      {'name': 'OSN Movies First', 'now': 'Avatar: The Way of Water (2022)', 'next': 'Mission Impossible - Dead Reckoning'},
      {'name': 'MBC 1 HD', 'now': 'Prime Time News & Reports', 'next': 'Drama Series Episode 45'},
      {'name': 'National Geographic', 'now': 'Kingdom of the White Wolf', 'next': 'Secrets of the Everglades'},
      {'name': 'Sky News Arabia', 'now': 'Global Markets Live Update', 'next': 'Documentary Special: AI Future'},
      {'name': 'Star Cinema HD', 'now': 'Interstellar Sci-Fi Thriller', 'next': 'Inception Mind-Bending Odyssey'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        title: const Text('TV Guide (EPG)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: channels.length,
        itemBuilder: (context, index) {
          final ch = channels[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 90,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F1F1F),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ch['name']!.split(' ').first,
                    style: const TextStyle(color: Color(0xFFE50914), fontWeight: FontWeight.bold, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ch['name']!,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.fiber_manual_record, color: Colors.green, size: 12),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Now: ${ch['now']}',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Next: ${ch['next']}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_active_outlined, color: Colors.white70),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('EPG Reminder set successfully!')),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
