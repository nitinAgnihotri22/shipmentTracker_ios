# ShipmentTracker (iOS)

ShipmentTracker is a SwiftUI iOS app for logistics teams to upload shipment CSV files, ask natural-language questions, and generate delay insights as charts/tables with optional PDF export.

## Features

- User authentication with local signup/login and session restore.
- CSV upload and validation with clear row-level error messages.
- Shipment normalization across common logistics field name variants.
- Natural-language insight engine (for example: top delays by route/carrier/destination).
- Time-aware queries (for example: last month, this month, last N days).
- Result visualization as chart or table.
- History of uploads and analyses per user.
- PDF report export of the generated insight.

## Tech Stack

- Swift 5
- SwiftUI
- Combine
- Xcode project (`ShipmentTracker.xcodeproj`)
- iOS deployment target: 17.0

No backend service is required. Data is stored locally on-device.

## Project Structure

- `ShipmentTracker/Views`: Authentication and dashboard UI.
- `ShipmentTracker/ViewModels`: App state, auth logic, dashboard orchestration.
- `ShipmentTracker/Services`: Auth, CSV parsing, insight generation, history, PDF export.
- `ShipmentTracker/Models`: Shared domain models.
- `ShipmentTracker/Resources`: Bundled sample CSV file.
- `ShipmentTrackerTests`: Unit tests for parser, insight logic, and history behavior.

## Requirements

- macOS with Xcode installed.
- iOS Simulator runtime or a physical iOS device.

## How To Run

1. Open `ShipmentTracker.xcodeproj` in Xcode.
2. Select the `ShipmentTracker` scheme.
3. Choose an iOS Simulator/device.
4. Build and run (`Cmd + R`).

### First App Flow

1. Sign up (or log in if already registered).
2. In Dashboard, import a CSV file using **Import CSV**.
3. Ask a question like:
   - `Which routes had the most delays last month?`
   - `Top 5 destinations with delayed shipments in last 30 days`
4. Review chart/table output.
5. Optionally export a PDF report.

## CSV Format

### Required columns

- `shipment_id`
- `route`
- `carrier`
- `origin`
- `destination`

### Common optional columns

- `planned_delivery_date`
- `actual_delivery_date`
- `delay_minutes`
- `status`
- `shipment_date`

The parser accepts minor header naming variations (for example spaces, hyphens, underscore differences) for normalized lookup.

You can use the bundled sample file at `ShipmentTracker/Resources/sample_shipments.csv` to get started quickly.

## Run Tests

From project root:

```bash
xcodebuild test -project "ShipmentTracker.xcodeproj" -scheme "ShipmentTracker" -destination 'platform=iOS Simulator,name=iPhone 15'
```

If your simulator name differs, replace `iPhone 15` with any available simulator on your machine.

## Notes

- User accounts, sessions, and history are persisted locally.
- Clearing history only removes saved upload/analysis records for the signed-in user.
