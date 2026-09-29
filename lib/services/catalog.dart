import '../models/book.dart';

/// Litlens's starter catalog. Recommendations are picked from here by
/// matching [Book.tags] against the topics Umbra shares.
const kCatalog = <Book>[
  Book(
    id: 'shallows',
    title: 'The Shallows',
    author: 'Nicholas Carr',
    pages: 276,
    tags: ['technology', 'psychology', 'science'],
  ),
  Book(
    id: 'extended',
    title: 'The Extended Mind',
    author: 'Annie Murphy Paul',
    pages: 336,
    tags: ['psychology', 'science'],
  ),
  Book(
    id: 'klara',
    title: 'Klara and the Sun',
    author: 'Kazuo Ishiguro',
    pages: 320,
    tags: ['fiction', 'science fiction'],
  ),
  Book(
    id: 'doet',
    title: 'The Design of Everyday Things',
    author: 'Don Norman',
    pages: 368,
    tags: ['design', 'psychology'],
  ),
  Book(
    id: 'moonwalking',
    title: 'Moonwalking with Einstein',
    author: 'Joshua Foer',
    pages: 320,
    tags: ['psychology', 'science'],
  ),
  Book(
    id: 'sapiens',
    title: 'Sapiens',
    author: 'Yuval Noah Harari',
    pages: 464,
    tags: ['history', 'science'],
  ),
  Book(
    id: 'thinking',
    title: 'Thinking, Fast and Slow',
    author: 'Daniel Kahneman',
    pages: 499,
    tags: ['psychology', 'economics'],
  ),
  Book(
    id: 'hailmary',
    title: 'Project Hail Mary',
    author: 'Andy Weir',
    pages: 496,
    tags: ['science fiction', 'fiction'],
  ),
  Book(
    id: 'midnight',
    title: 'The Midnight Library',
    author: 'Matt Haig',
    pages: 304,
    tags: ['fiction', 'philosophy'],
  ),
  Book(
    id: 'educated',
    title: 'Educated',
    author: 'Tara Westover',
    pages: 352,
    tags: ['biography'],
  ),
  Book(
    id: 'habits',
    title: 'Atomic Habits',
    author: 'James Clear',
    pages: 320,
    tags: ['self improvement'],
  ),
  Book(
    id: 'wind',
    title: 'The Name of the Wind',
    author: 'Patrick Rothfuss',
    pages: 662,
    tags: ['fantasy', 'fiction'],
  ),
  Book(
    id: 'meditations',
    title: 'Meditations',
    author: 'Marcus Aurelius',
    pages: 256,
    tags: ['philosophy', 'history'],
  ),
  Book(
    id: 'money',
    title: 'The Psychology of Money',
    author: 'Morgan Housel',
    pages: 256,
    tags: ['economics', 'business', 'self improvement'],
  ),
  Book(
    id: 'jobs',
    title: 'Steve Jobs',
    author: 'Walter Isaacson',
    pages: 656,
    tags: ['biography', 'technology', 'business'],
  ),
  Book(
    id: 'patient',
    title: 'The Silent Patient',
    author: 'Alex Michaelides',
    pages: 336,
    tags: ['mystery', 'fiction'],
  ),
  Book(
    id: 'sleep',
    title: 'Why We Sleep',
    author: 'Matthew Walker',
    pages: 368,
    tags: ['health', 'science'],
  ),
  Book(
    id: 'sweetgrass',
    title: 'Braiding Sweetgrass',
    author: 'Robin Wall Kimmerer',
    pages: 408,
    tags: ['nature', 'science'],
  ),
  Book(
    id: 'pride',
    title: 'Pride and Prejudice',
    author: 'Jane Austen',
    pages: 432,
    tags: ['romance', 'fiction', 'classics'],
  ),
];

/// Topics offered in Litlens's short onboarding, in catalog order.
final kTopicOptions = <String>{for (final b in kCatalog) ...b.tags}.toList();

Book? bookById(String id) {
  for (final b in kCatalog) {
    if (b.id == id) return b;
  }
  return null;
}
