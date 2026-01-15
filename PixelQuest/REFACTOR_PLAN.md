# Role
You are a UI/UX expert specializing in "Cozy" App Design. We are iterating on the "PixelQuest" design.

# CRITICAL FEEDBACK ON PREVIOUS ITERATION
The user HATED the previous "Hardcore Pixel" look.
1. **The Black Borders are too harsh:** They look depressing and disconnected.
2. **The Stepped Corners look buggy:** They look like low-res glitches, not a style choice.
3. **The Native Tab Bar is ugly:** It breaks the immersion completely.

# NEW GOAL: "HD Remastered" Pixel Style
We need a softer, warmer, and more cohesive look. Think "High-Res Pixel Art" or "Stardew Valley UI" — smooth rounded corners, warm colors, but retaining the pixel fonts and blocky progress bars.

---

## 🛠 Task: Refine DesignSystem & Dashboard

Please modify `DesignSystem.swift` and `DashboardView` with these specific changes:

### 1. 🎨 The Color Palette (Softening)
* **Global Stroke Color:** Change ALL borders/strokes from `Color.black` to a **Dark Coffee Color** (e.g., Hex `#4A3B32` or similar warm dark brown).
* **Card Background:** Keep the Cream/Off-white background.

### 2. 🔲 The "Chunky" Border (Fixing the Corners)
* **REMOVE** the jagged `Path` based corner logic.
* **USE** standard SwiftUI shapes with thick strokes.
* **Implementation:** * Use `RoundedRectangle(cornerRadius: 12, style: .continuous)`
    * Apply a `.stroke(Color("DarkCoffee"), lineWidth: 3)` (Thick, solid line).
    * This gives us the "Cartoony/RPG" feel without the ugly jagged edges.

### 3. 📊 Refined Progress Bar
* Keep the "Block/Cell" concept (it was good), but:
    * Change the border color to the new **Dark Coffee**.
    * Make the un-filled blocks slightly visible (e.g., `Color.gray.opacity(0.2)`) so the user can see the "empty slots".

### 4. 🧭 Custom Tab Bar (Fixing the Vibe)
* **Hide** the native `TabView` bar (`.toolbar(.hidden, for: .tabBar)`).
* **Create** a custom floating `HStack` at the bottom of the `ZStack`.
* **Style:** A floating capsule or rounded rectangle.
    * Background: `Color("CreamBackground")`
    * Border: `Color("DarkCoffee")`, lineWidth: 3.
    * Shadow: Solid color shadow (no blur).
    * Icons: Use the existing icons, but color the *selected* tab Dark Coffee and the *unselected* tab Light Brown.

### 5. 🔤 Typography
* **Action:** Ensure the Headers (Strength, Intellect) in the Dashboard Cards are using the **Pixel Font (VT323)**. They looked like standard Sans-Serif in the last screenshot.

---

# Execution Order
1. Update `DesignSystem.swift` with the new **Dark Coffee** color and the **Smooth Rounded Border** modifier.
2. Refactor `DashboardView` to use the new border style and implement the **Custom Floating Tab Bar**.