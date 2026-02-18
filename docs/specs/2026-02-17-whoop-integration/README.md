# Whoop Integration Spec

**Date:** 2026-02-17
**Owner:** Vinh Nguyen / Daily Ritual Team

## Overview

This specification covers the complete Whoop wearable integration for DailyRitual, connecting biometric data (recovery, sleep, strain, workouts) to the athlete's daily journaling practice. The integration bridges the gap between physical readiness metrics and mental performance reflection.

## Documents

- **[requirements.md](./requirements.md)** -- EARS-format requirements, acceptance criteria, edge cases
- **[design.md](./design.md)** -- Architecture, data model, UI/UX wireframes, sequence diagrams
- **[tasks.md](./tasks.md)** -- Phased implementation tasks with verification checklists

## Current State

Significant backend scaffolding already exists:
- OAuth flow (authorization URL generation, code exchange, callback with deep link)
- Token storage and refresh logic in `user_integrations` table
- Whoop API service with endpoints for recovery, strain, workouts, cycles
- Webhook handler for `workout.created`, `workout.updated`, `recovery.updated`
- Workout import pipeline (Whoop workout -> training_plan + draft workout_reflection)
- iOS deep link handler for `dailyritual://whoop/connected`

## What This Spec Adds

- iOS-side connection UI (settings view, connect/disconnect flow)
- Morning dashboard recovery/sleep display card
- Post-workout reflection trigger via push notification (1hr after workout detection)
- Strain-aware training plan recommendations
- Background data sync and refresh
- Privacy controls and data management
- Sleep detail view
- Comprehensive error handling and offline resilience
