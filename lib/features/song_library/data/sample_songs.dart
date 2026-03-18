import '../domain/models/chord_event.dart';
import '../domain/models/section_type.dart';
import '../domain/models/song.dart';
import '../domain/models/song_line.dart';
import '../domain/models/song_section.dart';

/// In-memory sample songs used during Phase 0 and Phase 1.
///
/// These are original fictional songs with realistic guitar chord progressions.
/// Phase 2 will seed Isar with these on first launch, then load from DB.
final List<Song> sampleSongs = [
  Song(
    id: 'sample-1',
    title: 'River Road',
    artist: 'The Wayfarers',
    key: 'G',
    bpm: 92,
    notes: 'Capo 2. Fingerpicked intro.',
    createdAt: DateTime(2024, 1, 15),
    updatedAt: DateTime(2024, 1, 15),
    sections: [
      SongSection(
        id: 's1-intro',
        name: 'Intro',
        type: SectionType.intro,
        lines: [
          SongLine(
            id: 's1-intro-l1',
            lyric: '',
            chords: [
              const ChordEvent(chord: 'G'),
              const ChordEvent(chord: 'D'),
              const ChordEvent(chord: 'Em'),
              const ChordEvent(chord: 'C'),
            ],
          ),
        ],
      ),
      SongSection(
        id: 's1-v1',
        name: 'Verse 1',
        type: SectionType.verse,
        lines: [
          SongLine(
            id: 's1-v1-l1',
            lyric: 'Walking down the river road',
            chords: [
              const ChordEvent(chord: 'G', position: 0),
              const ChordEvent(chord: 'D', position: 12),
            ],
          ),
          SongLine(
            id: 's1-v1-l2',
            lyric: 'Watching light on water flow',
            chords: [
              const ChordEvent(chord: 'Em', position: 0),
              const ChordEvent(chord: 'C', position: 14),
            ],
          ),
          SongLine(
            id: 's1-v1-l3',
            lyric: 'Days go by like turning leaves',
            chords: [
              const ChordEvent(chord: 'G', position: 0),
              const ChordEvent(chord: 'D', position: 14),
            ],
          ),
          SongLine(
            id: 's1-v1-l4',
            lyric: 'Carried off on autumn breeze',
            chords: [
              const ChordEvent(chord: 'Em', position: 0),
              const ChordEvent(chord: 'C', position: 11),
            ],
          ),
        ],
      ),
      SongSection(
        id: 's1-ch1',
        name: 'Chorus',
        type: SectionType.chorus,
        lines: [
          SongLine(
            id: 's1-ch1-l1',
            lyric: 'Take me where the rivers run',
            chords: [
              const ChordEvent(chord: 'C', position: 0),
              const ChordEvent(chord: 'G', position: 16),
            ],
          ),
          SongLine(
            id: 's1-ch1-l2',
            lyric: 'Back beneath the setting sun',
            chords: [
              const ChordEvent(chord: 'D', position: 0),
              const ChordEvent(chord: 'Em', position: 15),
            ],
          ),
          SongLine(
            id: 's1-ch1-l3',
            lyric: 'On this road I find my way',
            chords: [
              const ChordEvent(chord: 'C', position: 0),
              const ChordEvent(chord: 'G', position: 13),
            ],
          ),
          SongLine(
            id: 's1-ch1-l4',
            lyric: 'One more beautiful day',
            chords: [
              const ChordEvent(chord: 'D', position: 0),
              const ChordEvent(chord: 'Em', position: 4),
              const ChordEvent(chord: 'C', position: 15),
            ],
          ),
        ],
      ),
      SongSection(
        id: 's1-v2',
        name: 'Verse 2',
        type: SectionType.verse,
        lines: [
          SongLine(
            id: 's1-v2-l1',
            lyric: 'Fireflies at dusk arrive',
            chords: [
              const ChordEvent(chord: 'G', position: 0),
              const ChordEvent(chord: 'D', position: 13),
            ],
          ),
          SongLine(
            id: 's1-v2-l2',
            lyric: 'Marking all the ways I feel alive',
            chords: [
              const ChordEvent(chord: 'Em', position: 0),
              const ChordEvent(chord: 'C', position: 18),
            ],
          ),
          SongLine(
            id: 's1-v2-l3',
            lyric: 'Stars above the trembling stream',
            chords: [
              const ChordEvent(chord: 'G', position: 0),
              const ChordEvent(chord: 'D', position: 16),
            ],
          ),
          SongLine(
            id: 's1-v2-l4',
            lyric: 'Tell me something like a dream',
            chords: [
              const ChordEvent(chord: 'Em', position: 0),
              const ChordEvent(chord: 'C', position: 15),
            ],
          ),
        ],
      ),
      SongSection(
        id: 's1-ch2',
        name: 'Chorus',
        type: SectionType.chorus,
        lines: [
          SongLine(
            id: 's1-ch2-l1',
            lyric: 'Take me where the rivers run',
            chords: [
              const ChordEvent(chord: 'C', position: 0),
              const ChordEvent(chord: 'G', position: 16),
            ],
          ),
          SongLine(
            id: 's1-ch2-l2',
            lyric: 'Back beneath the setting sun',
            chords: [
              const ChordEvent(chord: 'D', position: 0),
              const ChordEvent(chord: 'Em', position: 15),
            ],
          ),
          SongLine(
            id: 's1-ch2-l3',
            lyric: 'On this road I find my way',
            chords: [
              const ChordEvent(chord: 'C', position: 0),
              const ChordEvent(chord: 'G', position: 13),
            ],
          ),
          SongLine(
            id: 's1-ch2-l4',
            lyric: 'One more beautiful day',
            chords: [
              const ChordEvent(chord: 'D', position: 0),
              const ChordEvent(chord: 'Em', position: 4),
              const ChordEvent(chord: 'C', position: 15),
            ],
          ),
        ],
      ),
      SongSection(
        id: 's1-outro',
        name: 'Outro',
        type: SectionType.outro,
        lines: [
          SongLine(
            id: 's1-outro-l1',
            lyric: '',
            chords: [
              const ChordEvent(chord: 'G'),
              const ChordEvent(chord: 'D'),
              const ChordEvent(chord: 'Em'),
              const ChordEvent(chord: 'C'),
            ],
          ),
        ],
      ),
    ],
  ),

  Song(
    id: 'sample-2',
    title: 'Evening Light',
    artist: 'Clara Webb',
    key: 'C',
    bpm: 78,
    notes: 'Capo 0. Slow strum pattern.',
    createdAt: DateTime(2024, 2, 3),
    updatedAt: DateTime(2024, 2, 3),
    sections: [
      SongSection(
        id: 's2-v1',
        name: 'Verse 1',
        type: SectionType.verse,
        lines: [
          SongLine(
            id: 's2-v1-l1',
            lyric: 'Sitting by the window',
            chords: [
              const ChordEvent(chord: 'C', position: 0),
              const ChordEvent(chord: 'G', position: 11),
            ],
          ),
          SongLine(
            id: 's2-v1-l2',
            lyric: 'Watching daylight fade away',
            chords: [
              const ChordEvent(chord: 'Am', position: 0),
              const ChordEvent(chord: 'F', position: 16),
            ],
          ),
          SongLine(
            id: 's2-v1-l3',
            lyric: 'Coffee getting cold now',
            chords: [
              const ChordEvent(chord: 'C', position: 0),
              const ChordEvent(chord: 'G', position: 11),
            ],
          ),
          SongLine(
            id: 's2-v1-l4',
            lyric: "Thinking 'bout what you might say",
            chords: [
              const ChordEvent(chord: 'Am', position: 0),
              const ChordEvent(chord: 'F', position: 20),
            ],
          ),
        ],
      ),
      SongSection(
        id: 's2-ch1',
        name: 'Chorus',
        type: SectionType.chorus,
        lines: [
          SongLine(
            id: 's2-ch1-l1',
            lyric: 'Evening light is falling',
            chords: [
              const ChordEvent(chord: 'F', position: 0),
              const ChordEvent(chord: 'C', position: 13),
            ],
          ),
          SongLine(
            id: 's2-ch1-l2',
            lyric: 'Shadows on the wall',
            chords: [
              const ChordEvent(chord: 'G', position: 0),
              const ChordEvent(chord: 'Am', position: 11),
            ],
          ),
          SongLine(
            id: 's2-ch1-l3',
            lyric: 'Somewhere in the distance',
            chords: [
              const ChordEvent(chord: 'F', position: 0),
              const ChordEvent(chord: 'C', position: 13),
            ],
          ),
          SongLine(
            id: 's2-ch1-l4',
            lyric: 'I can hear you call',
            chords: [
              const ChordEvent(chord: 'G', position: 0),
              const ChordEvent(chord: 'C', position: 13),
            ],
          ),
        ],
      ),
      SongSection(
        id: 's2-v2',
        name: 'Verse 2',
        type: SectionType.verse,
        lines: [
          SongLine(
            id: 's2-v2-l1',
            lyric: 'Letters left unopened',
            chords: [
              const ChordEvent(chord: 'C', position: 0),
              const ChordEvent(chord: 'G', position: 11),
            ],
          ),
          SongLine(
            id: 's2-v2-l2',
            lyric: 'Photographs that line the shelf',
            chords: [
              const ChordEvent(chord: 'Am', position: 0),
              const ChordEvent(chord: 'F', position: 17),
            ],
          ),
          SongLine(
            id: 's2-v2-l3',
            lyric: 'Conversations echo',
            chords: [
              const ChordEvent(chord: 'C', position: 0),
              const ChordEvent(chord: 'G', position: 10),
            ],
          ),
          SongLine(
            id: 's2-v2-l4',
            lyric: 'Telling stories to myself',
            chords: [
              const ChordEvent(chord: 'Am', position: 0),
              const ChordEvent(chord: 'F', position: 15),
            ],
          ),
        ],
      ),
      SongSection(
        id: 's2-bridge',
        name: 'Bridge',
        type: SectionType.bridge,
        lines: [
          SongLine(
            id: 's2-bridge-l1',
            lyric: 'And maybe time will carry me',
            chords: [
              const ChordEvent(chord: 'Am', position: 0),
              const ChordEvent(chord: 'F', position: 17),
            ],
          ),
          SongLine(
            id: 's2-bridge-l2',
            lyric: 'Back to where I need to be',
            chords: [
              const ChordEvent(chord: 'C', position: 0),
              const ChordEvent(chord: 'G', position: 15),
            ],
          ),
        ],
      ),
      SongSection(
        id: 's2-ch2',
        name: 'Chorus',
        type: SectionType.chorus,
        lines: [
          SongLine(
            id: 's2-ch2-l1',
            lyric: 'Evening light is falling',
            chords: [
              const ChordEvent(chord: 'F', position: 0),
              const ChordEvent(chord: 'C', position: 13),
            ],
          ),
          SongLine(
            id: 's2-ch2-l2',
            lyric: 'Shadows on the wall',
            chords: [
              const ChordEvent(chord: 'G', position: 0),
              const ChordEvent(chord: 'Am', position: 11),
            ],
          ),
          SongLine(
            id: 's2-ch2-l3',
            lyric: 'Somewhere in the distance',
            chords: [
              const ChordEvent(chord: 'F', position: 0),
              const ChordEvent(chord: 'C', position: 13),
            ],
          ),
          SongLine(
            id: 's2-ch2-l4',
            lyric: 'I can hear you call',
            chords: [
              const ChordEvent(chord: 'G', position: 0),
              const ChordEvent(chord: 'C', position: 13),
            ],
          ),
        ],
      ),
    ],
  ),

  Song(
    id: 'sample-3',
    title: 'Hollow Mountain',
    artist: 'The Stillwater Band',
    key: 'Am',
    bpm: 110,
    notes: 'Capo 0. Up-tempo. Watch the F barre.',
    createdAt: DateTime(2024, 3, 20),
    updatedAt: DateTime(2024, 3, 20),
    sections: [
      SongSection(
        id: 's3-intro',
        name: 'Intro',
        type: SectionType.intro,
        lines: [
          SongLine(
            id: 's3-intro-l1',
            lyric: '',
            chords: [
              const ChordEvent(chord: 'Am'),
              const ChordEvent(chord: 'F'),
              const ChordEvent(chord: 'C'),
              const ChordEvent(chord: 'G'),
            ],
          ),
        ],
      ),
      SongSection(
        id: 's3-v1',
        name: 'Verse 1',
        type: SectionType.verse,
        lines: [
          SongLine(
            id: 's3-v1-l1',
            lyric: 'Hollow mountain calling out my name',
            chords: [
              const ChordEvent(chord: 'Am', position: 0),
              const ChordEvent(chord: 'F', position: 18),
            ],
          ),
          SongLine(
            id: 's3-v1-l2',
            lyric: 'Wind cuts through the canyon just the same',
            chords: [
              const ChordEvent(chord: 'C', position: 0),
              const ChordEvent(chord: 'G', position: 20),
            ],
          ),
          SongLine(
            id: 's3-v1-l3',
            lyric: 'I have walked this trail a thousand times',
            chords: [
              const ChordEvent(chord: 'Am', position: 0),
              const ChordEvent(chord: 'F', position: 21),
            ],
          ),
          SongLine(
            id: 's3-v1-l4',
            lyric: 'Never quite escaped these mountain lines',
            chords: [
              const ChordEvent(chord: 'C', position: 0),
              const ChordEvent(chord: 'G', position: 19),
            ],
          ),
        ],
      ),
      SongSection(
        id: 's3-ch1',
        name: 'Chorus',
        type: SectionType.chorus,
        lines: [
          SongLine(
            id: 's3-ch1-l1',
            lyric: 'So I climb and I climb',
            chords: [
              const ChordEvent(chord: 'F', position: 0),
              const ChordEvent(chord: 'G', position: 12),
            ],
          ),
          SongLine(
            id: 's3-ch1-l2',
            lyric: 'Past the ridge and the pine',
            chords: [
              const ChordEvent(chord: 'Am', position: 0),
              const ChordEvent(chord: 'E', position: 14),
            ],
          ),
          SongLine(
            id: 's3-ch1-l3',
            lyric: "Till I'm standing where the cold winds blow",
            chords: [
              const ChordEvent(chord: 'F', position: 0),
              const ChordEvent(chord: 'G', position: 22),
            ],
          ),
          SongLine(
            id: 's3-ch1-l4',
            lyric: 'Hollow mountain, let me go',
            chords: [
              const ChordEvent(chord: 'Am', position: 0),
              const ChordEvent(chord: 'G', position: 18),
            ],
          ),
        ],
      ),
      SongSection(
        id: 's3-solo',
        name: 'Solo',
        type: SectionType.solo,
        lines: [
          SongLine(
            id: 's3-solo-l1',
            lyric: '',
            chords: [
              const ChordEvent(chord: 'Am'),
              const ChordEvent(chord: 'F'),
              const ChordEvent(chord: 'C'),
              const ChordEvent(chord: 'G'),
            ],
          ),
          SongLine(
            id: 's3-solo-l2',
            lyric: '',
            chords: [
              const ChordEvent(chord: 'Am'),
              const ChordEvent(chord: 'F'),
              const ChordEvent(chord: 'C'),
              const ChordEvent(chord: 'E'),
            ],
          ),
        ],
      ),
      SongSection(
        id: 's3-ch2',
        name: 'Chorus',
        type: SectionType.chorus,
        lines: [
          SongLine(
            id: 's3-ch2-l1',
            lyric: 'So I climb and I climb',
            chords: [
              const ChordEvent(chord: 'F', position: 0),
              const ChordEvent(chord: 'G', position: 12),
            ],
          ),
          SongLine(
            id: 's3-ch2-l2',
            lyric: 'Past the ridge and the pine',
            chords: [
              const ChordEvent(chord: 'Am', position: 0),
              const ChordEvent(chord: 'E', position: 14),
            ],
          ),
          SongLine(
            id: 's3-ch2-l3',
            lyric: "Till I'm standing where the cold winds blow",
            chords: [
              const ChordEvent(chord: 'F', position: 0),
              const ChordEvent(chord: 'G', position: 22),
            ],
          ),
          SongLine(
            id: 's3-ch2-l4',
            lyric: 'Hollow mountain, let me go',
            chords: [
              const ChordEvent(chord: 'Am', position: 0),
              const ChordEvent(chord: 'G', position: 18),
            ],
          ),
        ],
      ),
    ],
  ),
];
