# Nostalgic

**Your Daily Journey Through Azeroth’s History**

**Nostalgic** is a lightweight, "set-it-and-forget-it" utility designed to celebrate your legacy in World of Warcraft. Every day, **Nostalgic** scans your achievement history and displays every milestone you earned on that specific calendar date across all previous years.

Whether it’s the anniversary of defeating the Lich King, the day you finally earned your favorite mount, or a random fishing achievement from 2014, **Nostalgic** brings those memories back to life in an elegant, modern interface.

### The Problem in "Midnight" (12.0.1)
The native World of Warcraft: Midnight client has a defect in how it displays achievement dates in tooltips. If you mouse over an achievement, it might say "Earned on March 4th," regardless of when you actually completed it.

### The Nostalgic Solution
**Nostalgic** addresses this in two ways:
1.  **Search Logic:** Our scan accurately identifies achievements earned on the correct day (e.g., April 5th).
2.  **No-Lying Tooltips:** We bypass the buggy native tooltips completely. **Nostalgic** uses a customized tooltip that displays only the achievement name and description, ensuring you are never shown a conflicting, incorrect date.

---

### Key Features
* **Today in History:** Instantly view all achievements earned on the current day across your entire legacy.
* **Smart Autosizing Window (v1.4.0):** The **Nostalgic** window automatically calculates the pixel width of the longest achievement string for the current day and scales the entire interface to match it perfectly, side-to-side. *This ensures an elegant, adaptive look without the instability of manual resizing in the 12.0.1 engine.*
* **Persistent Positioning:** The window is fully draggable and remembers its exact coordinates, even after a logout or reload.
* **Titan Panel & LDB Support:** Includes a dedicated LDB launcher icon for Titan Panel and other Data Broker addons.
* **Full Interactivity:**
    * **Left-Click** an achievement to open it directly in your Achievement Journal.
    * **Shift-Click** to link your memories into chat and share them with friends.
* **Native Controls:** Access the interface instantly using `/nos` or `/nostalgic`, and close easily with the "X" button or the **Escape** key.

### Installation & Commands
1.  Download and extract the `Nostalgic` folder into your `World of Warcraft/_retail_/Interface/AddOns` directory.
2.  Log in! The addon will load and scan your achievements.
3.  Type **`/nos`** or **`/nostalgic`** to toggle the window.

### Compatibility
Optimized for **World of Warcraft: Midnight (12.0.1)** and designed to have a zero-impact footprint on your game's performance.

***

### Acknowledgments
This addon was developed through disciplined coding and extensive environmental testing to ensure maximum stability and accuracy within the unique architecture of the WoW 12.0.1 client.
