# Plan: Game UI Redesign - Dark Neon/Cyberpunk

## Feature Name
`game-ui-redesign`

## Overview
ChromaBlocks 게임의 전체 UI 디자인을 현재 Ghibli 크림톤 스타일에서 Dark Neon/Cyberpunk 스타일로 전면 변경

## Problem Statement
현재 디자인이 밋밋하고 게임의 활력을 제대로 전달하지 못함. 크림색 배경과 세이지 그린 톤이 퍼즐 게임의 에너지와 맞지 않음.

## Target Style
**NYC Rebel Dark Neon** - 어두운 배경에 네온 컬러 글로우 효과, 모던하고 게임다운 느낌

## Scope

### Screens (3)
1. **Home Screen** - 타이틀, 버튼, 통계 영역
2. **Game Screen** - HUD, 게임보드, 피스 트레이, 광고 배너
3. **Game Over Screen** - 스코어 카드, 버튼 영역

### Design Changes

#### Color Palette
| Element | Before | After |
|---------|--------|-------|
| Background | `#FBF7F2` (cream) | `#0A0A0A` (pitch black) |
| Card Surface | `#FFFFFF` (white) | `#18181B` (zinc) |
| Primary Accent | `#7B9E5E` (sage green) | `#C4F82A` (electric lime) |
| Text Primary | `#3D3529` (brown) | `#FFFFFF` (white) |
| Text Secondary | `#7A7266` (muted brown) | `#A1A1AA` (silver) |
| Borders | `#E5DDD3` (warm beige) | `#27272A` (dark zinc) |
| Board | `#FFFFFF` (white) | `#18181B` (zinc) |

#### Typography
| Element | Before | After |
|---------|--------|-------|
| Title Font | Outfit | Space Grotesk |
| Body Font | Inter | Manrope |
| Title Weight | 800 | 700-800 |
| Score Display | Outfit 900 | Space Grotesk 800 |

#### Effects
- Neon glow on accent elements (lime shadow: `#C4F82A25`)
- Card borders instead of shadows (`1px #27272A`)
- Gradient buttons (Purple-Blue, Lime tones)

## Deliverables
- Updated `chroma.pen` file with all 3 screens redesigned
- Visual verification screenshots for each screen

## Dependencies
- Pencil MCP tool for .pen file editing
- Style guide: NYC Rebel Dark Neon

## Created
- Date: 2026-02-10
- Phase: Plan
