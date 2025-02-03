# CodePulse

A decentralized educational platform for learning programming languages through interactive lessons.

## Features
- Create and manage programming courses
- Track student progress with timestamps
- Automatic course completion detection
- Issue completion certificates
- Reward system for completing lessons
- Course marketplace
- Per-lesson rewards and completion tracking
- Course and lesson rating system
- Student feedback and comments

## Architecture
The smart contract handles:
- Course creation and management 
- Student enrollment and progress tracking
- Certificate issuance
- Token rewards for completion
- Lesson-specific reward distribution
- Rating and feedback system

## Progress Tracking
- Tracks last activity timestamp for each enrollment
- Automatically marks course as completed when all lessons finished
- Validates progress against total lesson count
- Maximum of 20 completed lessons tracked per course

## Reward System
- Students earn PULSE tokens for completing individual lessons
- Bonus rewards for course completion
- Reward amounts configurable per lesson
- Maximum of 20 completed lessons tracked per course

## Rating System
- Students can rate lessons from 1-5 stars
- Leave comments/feedback on lessons
- Course average rating calculated automatically
- Rating history tracked per student
