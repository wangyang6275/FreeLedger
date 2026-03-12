import SwiftUI
import UniformTypeIdentifiers
import GRDB

struct PDFExportView: View {
    let dbQueue: GRDB.DatabaseQueue
    let settingsRepository: SettingsRepositoryProtocol

    @State private var selectedRange: PDFRangeOption = .currentMonth
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var pdfDocument: PDFDocumentFile?
    @State private var showExporter = false
    @State private var isExporting = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    private let currentYear = Calendar.current.component(.year, from: Date())

    enum PDFRangeOption: String, CaseIterable {
        case currentMonth
        case specificMonth
        case specificYear
        case all

        var labelKey: String {
            switch self {
            case .currentMonth: return "pdf_range_current_month"
            case .specificMonth: return "pdf_range_month"
            case .specificYear: return "pdf_range_year"
            case .all: return "pdf_range_all"
            }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section(L("pdf_select_range")) {
                    ForEach(PDFRangeOption.allCases, id: \.self) { option in
                        Button {
                            selectedRange = option
                        } label: {
                            HStack {
                                Text(L(option.labelKey))
                                    .foregroundColor(AppColors.textPrimary)
                                Spacer()
                                if selectedRange == option {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(AppColors.primary)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                }

                if selectedRange == .specificMonth || selectedRange == .specificYear {
                    Section {
                        Picker(L("pdf_year"), selection: $selectedYear) {
                            ForEach((2020...currentYear).reversed(), id: \.self) { year in
                                Text(String(year)).tag(year)
                            }
                        }

                        if selectedRange == .specificMonth {
                            Picker(L("pdf_month"), selection: $selectedMonth) {
                                ForEach(1...12, id: \.self) { month in
                                    Text(monthName(month)).tag(month)
                                }
                            }
                        }
                    }
                }

                Section {
                    Button {
                        exportPDF()
                    } label: {
                        HStack {
                            Spacer()
                            if isExporting {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Label(L("pdf_export_button"), systemImage: "doc.richtext")
                                .font(AppTypography.bodyLarge)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(isExporting)
                }
            }
            .navigationTitle(L("pdf_export_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L("action_cancel")) {
                        dismiss()
                    }
                }
            }
            .fileExporter(
                isPresented: $showExporter,
                document: pdfDocument,
                contentType: .pdf,
                defaultFilename: pdfFilename
            ) { result in
                switch result {
                case .success:
                    UserDefaults.standard.set(true, forKey: "has_exported_data")
                    dismiss()
                case .failure:
                    errorMessage = L("error_save_failed")
                }
                pdfDocument = nil
            }
            .alert(L("error_title"), isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button(L("error_ok"), role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Helpers

    private var pdfFilename: String {
        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "yyyyMMdd"
        let dateStr = dateFmt.string(from: Date())
        switch selectedRange {
        case .currentMonth:
            let y = Calendar.current.component(.year, from: Date())
            let m = Calendar.current.component(.month, from: Date())
            return "ColorFuLedger-\(y)\(String(format: "%02d", m))-\(dateStr).pdf"
        case .specificMonth:
            return "ColorFuLedger-\(selectedYear)\(String(format: "%02d", selectedMonth))-\(dateStr).pdf"
        case .specificYear:
            return "ColorFuLedger-\(selectedYear)-\(dateStr).pdf"
        case .all:
            return "ColorFuLedger-All-\(dateStr).pdf"
        }
    }

    private func monthName(_ month: Int) -> String {
        let f = DateFormatter()
        f.locale = LanguageManager.locale
        f.setLocalizedDateFormatFromTemplate("MMMM")
        var comps = DateComponents()
        comps.year = currentYear
        comps.month = month
        comps.day = 1
        if let d = Calendar.current.date(from: comps) {
            return f.string(from: d)
        }
        return "\(month)"
    }

    private func exportPDF() {
        isExporting = true
        let range: PDFExportRange
        switch selectedRange {
        case .currentMonth:
            let y = Calendar.current.component(.year, from: Date())
            let m = Calendar.current.component(.month, from: Date())
            range = .month(year: y, month: m)
        case .specificMonth:
            range = .month(year: selectedYear, month: selectedMonth)
        case .specificYear:
            range = .year(year: selectedYear)
        case .all:
            range = .all
        }

        let currency = (try? settingsRepository.getCurrency()) ?? "CNY"
        let service = PDFExportService(dbQueue: dbQueue)

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data = try service.exportPDF(range: range, currencyCode: currency)
                DispatchQueue.main.async {
                    isExporting = false
                    pdfDocument = PDFDocumentFile(data: data)
                    showExporter = true
                }
            } catch {
                DispatchQueue.main.async {
                    isExporting = false
                    AppLogger.service.error("PDFExportView exportPDF failed: \(error.localizedDescription)")
                    errorMessage = L("error_save_failed")
                }
            }
        }
    }
}

// MARK: - PDF FileDocument

struct PDFDocumentFile: FileDocument {
    static var readableContentTypes: [UTType] { [.pdf] }

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
