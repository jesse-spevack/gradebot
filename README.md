# GradeBot

AI-powered assignment grading system that automates feedback for student work in Google Docs. Built with Rails 8, integrates with Google Drive, and uses LLM technology for intelligent grading.

## Features
- Google Drive integration
- Automated grading with rubric support
- Individual and class-wide feedback
- Real-time progress tracking
- Mobile-responsive interface

## Setup
Requires Google OAuth credentials and LLM API key.

## Code Conventions

### Tailwind CSS Class Ordering
To maintain consistency and readability across our templates, follow this ordering convention for Tailwind CSS classes:

1. Layout & Position
   - Display & Flow (`flex`, `grid`, `absolute`, `relative`)
   - Flex/Grid properties (`flex-col`, `items-center`, `justify-start`)

2. Box Model
   - Dimensions (`w-full`, `h-full`, `min-h-screen`)
   - Max/Min constraints (`max-w-md`)

3. Spacing
   - Padding (`p-`, `px-`, `py-`, `pt-`)
   - Margin (`m-`, `mx-`, `my-`, `mt-`)

4. Typography
   - Font properties (`font-mono`, `font-black`)
   - Text sizing (`text-6xl`, `sm:text-7xl`)
   - Text styling (`tracking-tight`)

5. Visual
   - Shape (`rounded-lg`, `border`)
   - Shadows (`shadow-md`)

6. Colors
   - Background (`bg-black`)
   - Text (`text-white`)

7. Interactive States
   - Hover (`hover:bg-gray-800`)
   - Focus (`focus:ring-2`)

Example:
```html
<button class="absolute right-0 top-0 h-full rounded-lg px-6 bg-black text-white hover:bg-gray-800">
```
