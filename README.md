# WEARDO

**Build outfits. Find your look.**

WEARDO is a Flutter app for browsing clothing items, mixing and matching them into outfits, and saving your favorite combinations — all with a black-and-white brutalist aesthetic.

---

## Features

**Catalog** — Browse your wardrobe in a responsive grid. Search by name, filter by category or favorites. Tap any item to favorite or remove it.

**Outfit Builder** — Mix and match clothing across five slots (headwear, outer, inner, bottoms, shoes). Lock items you want to keep, shuffle the rest. Toggle single/double-layer mode and headwear visibility. Save outfits with one tap.

**Profile** — View your saved outfits in a masonry grid. Tap to load an outfit back into the builder. Long-press to delete.

**Background Removal** — When adding clothing from your camera or gallery, the app automatically removes the background for cleaner outfit previews.

**Real-time Sync** — All data syncs to Supabase. Add clothes on one device, build outfits on another.

---

## Screenshots

<!--
Add screenshots here:

![Catalog](screenshots/catalog.png)
![Builder](screenshots/builder.png)
![Profile](screenshots/profile.png)
![Add Clothing](screenshots/add_clothing.png)
*(Drop screenshots into a `screenshots/` folder and uncomment the lines above.)*
-->


---

## Architecture

```
lib/
├── main.dart                   # App entry, providers, router, theme
├── models/                     # Data models (ClothingItem, FavoriteOutfit)
├── services/                   # Background removal API client
├── widgets/                    # Shared UI (button, nav bar, FAB, dialogs)
└── features/
    ├── auth/                   # Login, register, auth provider
    ├── splash/                 # Animated pixel-art splash screen
    ├── catalog/                # Wardrobe grid, add clothes, filters
    ├── outfit_builder/         # Builder canvas, carousels, picker
    └── profile/                # User profile, saved outfits grid
```

**State Management** — Provider + ChangeNotifier with four providers: Auth, Catalog, SavedOutfits, Builder. Cross-provider communication via a pending-load signal.

**Routing** — GoRouter with StatefulShellRoute for persistent bottom navigation. Auth redirect guards on every route change.

**Data** — Supabase (Postgres) with Row Level Security. All queries are one-shot fetch-after-mutate with optimistic updates for favorites.

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | Flutter / Dart |
| Backend | Supabase (Auth, Postgres, Storage) |
| Background Removal | Python / FastAPI / rembg |
| State Management | Provider |
| Routing | GoRouter |
| Fonts | JetBrains Mono |

---

## License

MIT
