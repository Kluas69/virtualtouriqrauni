# Requirements Document

## Introduction

This specification addresses the issue where location cards on the home screen display only one card at a time on desktop, when the user expects to see 3 cards simultaneously. The current implementation uses a PageView with viewport fractions configured for multiple cards, but the visual presentation (scaling and opacity) makes adjacent cards appear diminished or hidden.

## Glossary

- **Location_Card**: A visual card component displaying campus location information with image, title, and interactive elements
- **PageView**: Flutter widget that creates a scrollable list of pages with configurable viewport
- **Viewport_Fraction**: The fraction of the viewport that each page should occupy (0.33 = ~3 cards visible)
- **Desktop_Layout**: Screen width >= 1024px
- **Card_Visibility**: The visual prominence of cards including scale, opacity, and interactive state

## Requirements

### Requirement 1: Desktop Multi-Card Display

**User Story:** As a desktop user, I want to see 3 location cards simultaneously on the home screen, so that I can browse multiple campus locations at once without scrolling.

#### Acceptance Criteria

1. WHEN viewing the home screen on desktop (width >= 1024px), THE System SHALL display 3 location cards simultaneously in the viewport
2. WHEN the carousel is at the first position, THE System SHALL show cards at positions 0, 1, and 2 with full visibility
3. WHEN the carousel is at a middle position, THE System SHALL show the selected card and one card on each side with full visibility
4. WHEN the carousel is at the last position, THE System SHALL show the last 3 cards with full visibility

### Requirement 2: Card Visual Equality

**User Story:** As a user, I want all visible cards to appear equally prominent, so that I can easily compare and select from multiple locations.

#### Acceptance Criteria

1. WHEN multiple cards are visible on desktop, THE System SHALL render all visible cards at 100% scale
2. WHEN multiple cards are visible on desktop, THE System SHALL render all visible cards at 100% opacity
3. WHEN a user hovers over any visible card, THE System SHALL apply hover effects only to that specific card
4. WHEN cards are not selected, THE System SHALL maintain their full visibility and interactivity

### Requirement 3: Responsive Behavior Preservation

**User Story:** As a user on different devices, I want the card display to adapt appropriately to my screen size, so that the interface remains usable and visually appealing.

#### Acceptance Criteria

1. WHEN viewing on mobile (width < 600px), THE System SHALL display 1 card at a time with viewport fraction 0.85
2. WHEN viewing on tablet (600px <= width < 1024px), THE System SHALL display approximately 2 cards with viewport fraction 0.45
3. WHEN viewing on desktop (width >= 1024px), THE System SHALL display 3 cards with viewport fraction 0.33
4. WHEN transitioning between screen sizes, THE System SHALL smoothly update the card layout without visual glitches

### Requirement 4: Navigation and Interaction

**User Story:** As a user, I want to navigate through location cards smoothly, so that I can explore all campus locations efficiently.

#### Acceptance Criteria

1. WHEN navigation arrows are clicked on desktop, THE System SHALL scroll the carousel by one card position
2. WHEN a user clicks on any visible card, THE System SHALL navigate to that location's detail screen
3. WHEN the page indicator is displayed, THE System SHALL accurately reflect the current carousel position
4. WHEN swiping or dragging on any device, THE System SHALL respond with smooth physics-based scrolling
