# AnimeService Implementation

## Overview

The `AnimeService` class provides a comprehensive interface for managing anime library operations with Core Data persistence. It handles all CRUD operations for user anime data, including adding, updating, deleting, fetching, reordering, and moving anime between different status lists.

## Implementation Date

October 13, 2025

## Features Implemented

### Core Operations

1. **Add Anime to Library**
   - Adds anime to user's library with specified status
   - Automatically assigns sort order
   - Sets needsSync flag for remote synchronization
   - Prevents duplicate entries

2. **Update Operations**
   - Update anime progress (episode count)
   - Update anime status (watching, completed, etc.)
   - Update anime score/rating
   - All updates set needsSync flag and update lastModified timestamp

3. **Delete Operations**
   - Remove anime from library
   - Properly handles Core Data relationships

4. **Fetch Operations**
   - Fetch anime by status (watching, completed, etc.)
   - Fetch all user anime
   - Get specific user anime by ID
   - Get user anime by anime ID
   - Results are sorted by sortOrder

5. **List Management**
   - Move anime between different status lists
   - Automatically reorders items in old list after removal
   - Assigns correct sort order in new list

6. **Reordering**
   - Reorder anime within a status list
   - Maintains sequential sort orders
   - Updates needsSync flag for all affected items

### Offline Support

- All operations set the `needsSync` flag to track changes that need to be synchronized with the remote API
- `lastModified` timestamp is updated on every change
- Changes are persisted locally immediately

### Data Integrity

- Validates anime existence before operations
- Prevents duplicate anime entries
- Maintains referential integrity with Core Data relationships
- Handles genres as many-to-many relationships

## Protocol Definition

```swift
protocol AnimeServiceProtocol {
    func addAnimeToLibrary(_ anime: Anime, status: AnimeStatus, progress: Int, score: Double?) throws -> UserAnime
    func updateAnimeProgress(_ userAnimeId: Int, progress: Int) throws -> UserAnime
    func updateAnimeStatus(_ userAnimeId: Int, status: AnimeStatus) throws -> UserAnime
    func updateAnimeScore(_ userAnimeId: Int, score: Double?) throws -> UserAnime
    func deleteAnimeFromLibrary(_ userAnimeId: Int) throws
    func fetchAnimeByStatus(_ status: AnimeStatus) throws -> [UserAnime]
    func fetchAllUserAnime() throws -> [UserAnime]
    func moveAnimeBetweenLists(_ userAnimeId: Int, toStatus: AnimeStatus) throws -> UserAnime
    func reorderAnime(in status: AnimeStatus, from sourceIndex: Int, to destinationIndex: Int) throws
    func getUserAnime(byId id: Int) throws -> UserAnime?
    func getUserAnime(byAnimeId animeId: Int) throws -> UserAnime?
}
```

## Usage Examples

### Adding Anime to Library

```swift
let animeService = AnimeService()

let anime = Anime(
    id: 1,
    title: AnimeTitle(romaji: "Attack on Titan", english: "Attack on Titan", native: "進撃の巨人"),
    coverImage: CoverImage(large: "url", medium: "url"),
    episodes: 25,
    format: .tv,
    genres: ["Action", "Drama"],
    synopsis: "...",
    siteUrl: "https://anilist.co/anime/1"
)

let userAnime = try animeService.addAnimeToLibrary(
    anime,
    status: .watching,
    progress: 0,
    score: nil
)
```

### Updating Progress

```swift
let updatedAnime = try animeService.updateAnimeProgress(userAnime.id, progress: 5)
print("Progress: \(updatedAnime.progress)/\(updatedAnime.anime.episodes ?? 0)")
```

### Moving Between Lists

```swift
// Move from watching to completed
let completedAnime = try animeService.moveAnimeBetweenLists(
    userAnime.id,
    toStatus: .completed
)
```

### Reordering Within a List

```swift
// Move first item to third position
try animeService.reorderAnime(
    in: .watching,
    from: 0,
    to: 2
)
```

### Fetching Anime by Status

```swift
let watchingAnime = try animeService.fetchAnimeByStatus(.watching)
for anime in watchingAnime {
    print("\(anime.anime.title.preferred) - \(anime.progress)/\(anime.anime.episodes ?? 0)")
}
```

## Error Handling

The service throws `KiroError` for various error conditions:

- **Duplicate Entry**: Attempting to add anime that already exists in library
- **Not Found**: Attempting to update/delete non-existent anime
- **Invalid Index**: Reordering with out-of-bounds indices
- **Core Data Errors**: Database operation failures

## Testing

Comprehensive unit tests are provided in `AnimeServiceTests.swift` covering:

- ✓ Adding anime to library
- ✓ Updating anime progress, status, and score
- ✓ Deleting anime from library
- ✓ Fetching anime by status
- ✓ Fetching all user anime
- ✓ Moving anime between lists
- ✓ Reordering anime within lists
- ✓ NeedsSync flag updates
- ✓ LastModified timestamp updates
- ✓ Genre persistence
- ✓ Error handling for invalid operations
- ✓ Integration workflows

All tests use an in-memory Core Data stack for isolation and speed.

## Requirements Satisfied

This implementation satisfies the following requirements from the spec:

- **2.1**: Display five distinct lists (Watching, Completed, Plan to Watch, On Hold, Dropped)
- **2.2**: Allow selection of which list to add anime to
- **2.3**: Allow moving anime between lists
- **2.4**: Persist custom order locally
- **2.5**: Update status both locally and mark for sync
- **6.3**: Allow viewing and modifying locally stored anime data
- **6.4**: Queue changes for sync when made offline

## Dependencies

- CoreData framework for persistence
- CoreDataStack for database operations
- Domain models: Anime, UserAnime, AnimeStatus, AnimeFormat, etc.
- KiroError for error handling

## Performance Considerations

- Uses Core Data fetch request helpers for efficient queries
- Batch operations for reordering to minimize saves
- Indexes on id, status, and sortOrder fields for fast lookups
- Lazy loading of relationships

## Future Enhancements

Potential improvements for future iterations:

1. Batch operations for adding multiple anime
2. Undo/redo support for operations
3. Validation of progress against episode count
4. Automatic status updates (e.g., move to completed when progress equals episodes)
5. Custom sort options beyond sortOrder
6. Search and filter capabilities within the service

## Notes

- The service uses the anime ID as the user anime ID for simplicity
- Sort orders are automatically managed and kept sequential
- All operations are synchronous but fast due to local Core Data storage
- The needsSync flag is crucial for the sync service to identify pending changes
