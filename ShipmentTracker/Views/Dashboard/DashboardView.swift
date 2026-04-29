import SwiftUI
import UniformTypeIdentifiers

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    let onLogout: () -> Void

    @State private var showImporter = false
    @State private var showCSVPreview = false
    @State private var showLogoutConfirm = false
    @State private var showClearHistoryConfirm = false
    private let quickQuestions = [
        "Which routes had the most delays last month?",
        "Show average delay by carrier this month",
        "Top 5 destinations with delayed shipments in last 30 days",
        "Create a table of delay count by route"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ProfileHeaderView(
                    initial: viewModel.profileInitial,
                    name: viewModel.userName,
                    email: viewModel.userEmail
                ) {
                    showLogoutConfirm = true
                }

                Text("Logistics Ops Assistant")
                    .font(.title.bold())
                Text("Upload CSV + ask shipment questions.")
                    .foregroundStyle(.secondary)

                GroupBox("1) Upload Shipment CSV") {
                    VStack(alignment: .leading, spacing: 10) {
                        Button("Import CSV") {
                            showImporter = true
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityLabel("Import shipment CSV")

                        if let dataSet = viewModel.dataSet {
                            Text("File: \(dataSet.fileName)")
                            Text("Records: \(dataSet.rows.count)")
                            Text("Columns: \(dataSet.columns.joined(separator: ", "))")
                                .font(.footnote)
                                .foregroundStyle(.secondary)

                            Button("View Full CSV") {
                                showCSVPreview = true
                            }
                            .buttonStyle(.bordered)
                        }

                        if !viewModel.validationErrors.isEmpty {
                            ForEach(viewModel.validationErrors, id: \.self) { error in
                                Text("• \(error)")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }

                GroupBox("2) Ask a Question") {
                    VStack(alignment: .leading, spacing: 10) {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8)
                        ], spacing: 8) {
                            ForEach(quickQuestions, id: \.self) { option in
                                Button {
                                    viewModel.question = option
                                } label: {
                                    Text(option)
                                        .font(.subheadline.weight(.semibold))
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                        .minimumScaleFactor(0.8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .frame(height: 40, alignment: .center)
                                }
                                .buttonStyle(.bordered)
                                .accessibilityLabel("Use suggested question: \(option)")
                            }
                        }

                        TextField("Example: top 5 delayed routes this month chart and table", text: $viewModel.question, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityLabel("Question input")
                        Button("Analyze") {
                            viewModel.analyzeQuestion()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.dataSet == nil)
                        .accessibilityLabel("Analyze question")
                    }
                }

                GroupBox("3) Result") {
                    ResultSectionView(viewModel: viewModel)
                }

                GroupBox("History") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Button("Clear History", role: .destructive) {
                                showClearHistoryConfirm = true
                            }
                            .disabled(viewModel.history.isEmpty)
                            Spacer()
                            Text("\(viewModel.history.count) item(s)")
                                .foregroundStyle(.secondary)
                                .font(.footnote)
                        }

                        if viewModel.history.isEmpty {
                            Text("No history yet for this user.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(viewModel.history) { item in
                                Button {
                                    viewModel.restoreHistory(item)
                                } label: {
                                    HistoryRowView(item: item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                GroupBox("4) Expected CSV Fields") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Required: shipment_id, route, carrier, origin, destination")
                        Text("Helpful examples: route, carrier, destination, planned_delivery_date, actual_delivery_date, delay_minutes, status")
                            .foregroundStyle(.secondary)
                    }
                    .font(.footnote)
                }
            }
            .padding()
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [UTType.commaSeparatedText, .plainText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let first = urls.first {
                    viewModel.importCSV(from: first)
                }
            case .failure:
                viewModel.validationErrors = ["Unable to open selected CSV file."]
            }
        }
        .sheet(isPresented: $showCSVPreview) {
            if let dataSet = viewModel.dataSet {
                CSVPreviewView(dataSet: dataSet)
            }
        }
        .alert("Confirm Logout", isPresented: $showLogoutConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Logout", role: .destructive) {
                viewModel.clearInMemoryState()
                onLogout()
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
        .alert("Clear History", isPresented: $showClearHistoryConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                viewModel.clearHistory()
            }
        } message: {
            Text("This will clear all saved uploads and analyses for this user.")
        }
        .onAppear {
            viewModel.loadSampleDataIfNeeded()
        }
    }
}
