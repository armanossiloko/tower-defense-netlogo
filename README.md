# Tower Defense - Complex Adaptive System Model

## Overview

This model demonstrates how simple local rules governing individual agents (towers attacking enemies, enemies targeting towers) lead to complex global patterns of defense success or failure. The simulation explores optimal tower configurations, enemy spawn dynamics, and threshold effects in defensive systems.

## Features

### Tower Types
- **Basic Towers** (Blue Circles): Balanced all-around defense with moderate range, fire rate, and damage
- **Fast Towers** (Yellow Squares): Rapid-fire towers for handling swarms of weak enemies
- **Long-Range Towers** (Red Houses): Sniper-style towers with extended range and high damage

### Enemy Types
- **Fast Enemies** (Red): Quick rushers with low health but high speed
- **Tough Enemies** (Orange): Slow tanks with high health and heavy damage
- **Balanced Enemies** (Yellow): Middle-ground units with moderate stats

### Key Capabilities
- Multiple tower placement strategies (defensive ring, clustered center, grid, random)
- Dynamic enemy spawning from all four sides of the battlefield
- Visual feedback through color-coded health indicators
- Real-time statistics and plotting
- Parameter sweep experiments for systematic analysis
- Victory/defeat conditions with detailed performance metrics

## Usage

### Prerequisites
- [NetLogo](https://ccl.northwestern.edu/netlogo/) (version 7.0.0 was used for development)

### Configuration Parameters

#### Tower Settings
- `num-towers`: Total number of towers (3-20)
- `basic-tower-percent`: Percentage of basic towers (0-100%)
- `fast-tower-percent`: Percentage of fast towers (0-100%)
- `tower-placement-strategy`: Arrangement pattern (defensive-ring, clustered-center, grid, random)

#### Enemy Settings
- `enemy-spawn-rate`: Probability of enemy spawning each tick (5-50%)
- `enemy-health-multiplier`: Scales all enemy health (0.5-3.0×)
- `fast-enemy-percent`: Percentage of fast enemies (0-100%)
- `tough-enemy-percent`: Percentage of tough enemies (0-100%)
- `max-enemies-spawn`: Maximum total enemies to spawn (0 for unlimited, positive number for finite waves)

#### Simulation Settings
- `max-simulation-ticks`: Maximum simulation duration (500-5000)
- `show-tower-range?`: Toggle visualization of tower attack ranges

### Monitoring Results
The interface includes real-time monitors for:
- Towers and enemies alive
- Total spawned and destroyed counts
- Kill rate percentage
- Average tower health
- Type-specific destruction statistics
- Simulation ticks

Three plots track:
1. **Population Over Time**: Tower and enemy counts
2. **Enemies Destroyed by Type**: Bar chart by enemy category
3. **Cumulative Kills**: Total enemies destroyed over time

## Experiments

The model includes pre-configured BehaviorSpace experiments:

### Tower Mix Experiment
Tests different tower compositions with fixed parameters:
- 0%, 33%, 50%, 100% basic towers
- 0%, 33%, 50% fast towers
- 10 total towers
- 15% spawn rate
- 5 repetitions per configuration

### Spawn Rate Experiment
Analyzes system performance across spawn rates:
- Spawn rates: 5%, 10%, 15%, 20%, 25%, 30%
- 10 towers with 40% basic, 30% fast
- 10 repetitions per configuration

## Complex Adaptive System Aspects

This model exemplifies CAS principles:

1. **Multiple Interacting Agents**: Towers, enemies, and bullets interact based on proximity
2. **Simple Local Rules**: Enemies move to nearest tower; towers shoot nearest enemy
3. **Emergent Global Behavior**: Defense patterns and survival time emerge from interactions
4. **Adaptation**: Enemies retarget as towers are destroyed
5. **Non-linearity**: Small parameter changes cause dramatic outcome shifts
6. **Self-organization**: Enemy distribution patterns organize based on spawn locations

## Things to Try

- **Balanced Defense**: 40% basic, 30% fast, 30% long-range at medium spawn rate
- **Extreme Scenarios**: Test all long-range vs. all fast towers
- **Placement Sensitivity**: Compare different placement strategies with identical parameters
- **Phase Transitions**: Find the critical spawn rate where defense collapses
- **Finite Wave Mode**: Set `max-enemies-spawn` to 100-200 for a defined challenge

## Model Details

### Agent Properties
- **Towers**: Type, range, fire rate, damage, health, cooldown, kill count
- **Enemies**: Type, health, speed, damage, target tower, spawn side, attack cooldown
- **Bullets**: Damage, speed, target enemy, lifetime

### Game Mechanics
- Enemies spawn from random sides (top, bottom, left, right)
- Color intensity indicates health status for both towers and enemies
- Towers pulse larger when under attack
- Bullets home in on targets and match their source tower's color
- Victory condition: Destroy all enemies in finite wave mode
- Defeat condition: All towers destroyed

## Authors

This project was developed by students as an educational exploration of complex adaptive systems:

- **Arman Ossi Loko**
  - Email: [arman.ossiloko@edu.fit.ba](mailto:arman.ossiloko@edu.fit.ba), [armanossiloko@gmail.com](mailto:armanossiloko@gmail.com)
  - GitHub: [@armanossiloko](https://github.com/armanossiloko)

- **Azemina Magrdžija**
  - Email: [azemina.magrdzija@edu.fit.ba](mailto:azemina.magrdzija@edu.fit.ba)

- **Almer Hodžić**
  - Email: [almer.hodzic@edu.fit.ba](mailto:almer.hodzic@edu.fit.ba)

- **Edin Šehović**
  - Email: [edin.sehovic@edu.fit.ba](mailto:edin.sehovic@edu.fit.ba)
  - GitHub: [@sehakespeare](https://github.com/sehakespeare)

**Model created**: 2025  
**Platform**: NetLogo 6.4.0  
**Purpose**: Educational demonstration of complex adaptive systems

## License

This model is provided for educational purposes. Please refer to the authors for usage permissions.

## Acknowledgments

- Based on tower defense game mechanics as a natural example of emergent behavior
- Developed using the NetLogo modeling environment
- Demonstrates principles from complex systems and agent-based modeling literature
