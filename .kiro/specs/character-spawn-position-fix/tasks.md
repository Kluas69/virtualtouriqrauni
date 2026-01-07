# Implementation Plan: Character Spawn Position Fix

## Overview

Fix the character spawn positioning by aligning the initial camera setup with the working reset position logic. This involves modifying the camera initialization in the HTML file to use the same eye-level calculation as the resetPlayer() function.

## Tasks

- [x] 1. Analyze current positioning logic
  - Examine the resetPlayer() function to extract exact positioning coordinates
  - Document the current initial camera position (0, 2, 5) vs correct position
  - Identify the eye level calculation: player.position.y + player.size.height - 0.1
  - _Requirements: 1.2, 2.1_

- [ ] 2. Update initial camera positioning
  - [x] 2.1 Modify camera initialization in professional_classroom_enhanced.html
    - Replace hardcoded camera.position.set(0, 2, 5) with calculated eye level position
    - Use the same formula as resetPlayer(): player.position.y + player.size.height - 0.1
    - Ensure camera starts at approximately (0, 1.1, 5) instead of (0, 2, 5)
    - _Requirements: 1.1, 1.4_

  - [ ]* 2.2 Write property test for camera positioning consistency
    - **Property 1: Initialization and Reset Consistency**
    - **Validates: Requirements 1.2, 1.3, 2.1, 3.3**

  - [ ]* 2.3 Write property test for eye level calculation
    - **Property 2: Eye Level Camera Positioning**
    - **Validates: Requirements 1.1, 1.4**

- [ ] 3. Ensure proper initialization state
  - [x] 3.1 Verify player object initialization consistency
    - Ensure player.position uses spawnHeight consistently
    - Verify player starts with onGround = true
    - Ensure player velocity is zeroed on initialization
    - _Requirements: 2.2, 2.3, 2.4_

  - [ ]* 3.2 Write unit tests for initialization state
    - Test player.onGround = true after initialization
    - Test player velocity = {x:0, y:0, z:0} after initialization
    - Test camera rotation = (0,0,0) after initialization
    - _Requirements: 2.3, 2.4, 2.5_

- [ ] 4. Validate reset function preservation
  - [x] 4.1 Test that resetPlayer() function remains unchanged
    - Verify resetPlayer() still works correctly after changes
    - Ensure reset positioning matches new initial positioning
    - Test that reset function serves as reference implementation
    - _Requirements: 3.1, 3.2_

  - [ ]* 4.2 Write property test for reset function preservation
    - **Property 4: Reset Function Preservation**
    - **Validates: Requirements 3.1**

- [ ] 5. Integration testing and validation
  - [x] 5.1 Test complete initialization flow
    - Load the HTML page and verify camera starts at correct position
    - Test that no manual "Reset Position" is needed
    - Verify positioning works across different screen sizes
    - _Requirements: 1.1, 1.3_

  - [ ]* 5.2 Write integration tests
    - Test page load → correct positioning flow
    - Test load → reset → verify identical positioning
    - Test mobile and desktop consistency
    - _Requirements: 1.1, 1.2, 1.3_

- [x] 6. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- The main change is a single line modification in the HTML file
- Property tests validate universal correctness properties
- Unit tests validate specific examples and edge cases
- The resetPlayer() function should remain completely unchanged as it works correctly