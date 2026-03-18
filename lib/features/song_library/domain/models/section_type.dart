/// The structural type of a song section.
enum SectionType {
  intro,
  verse,
  preChorus,
  chorus,
  bridge,
  outro,
  solo,
  instrumental,
  custom;

  String get displayName {
    switch (this) {
      case SectionType.intro:
        return 'Intro';
      case SectionType.verse:
        return 'Verse';
      case SectionType.preChorus:
        return 'Pre-Chorus';
      case SectionType.chorus:
        return 'Chorus';
      case SectionType.bridge:
        return 'Bridge';
      case SectionType.outro:
        return 'Outro';
      case SectionType.solo:
        return 'Solo';
      case SectionType.instrumental:
        return 'Instrumental';
      case SectionType.custom:
        return 'Section';
    }
  }
}
