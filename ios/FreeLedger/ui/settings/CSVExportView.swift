import SwiftUI
import UniformTypeIdentifiers

struct CSVExportView: View {
    let csvExportService: CSVExportService

    @State private var fields = CSVExportField.defaultFields()
    @State private var csvDocument: CSVDocument?
    @State private var showExporter = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section(L("csv_select_fields")) {
                    ForEach($fields) { $field in
                        Toggle(L(field.labelKey), isOn: $field.isSelected)
                    }
                }

                Section {
                    Button {
                        exportCSV()
                    } label: {
                        HStack {
                            Spacer()
                            Label(L("csv_export_button"), systemImage: "doc.text")
                                .font(AppTypography.bodyLarge)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(!fields.contains(where: \.isSelected))
                }
            }
            .navigationTitle(L("csv_export_title"))
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
                document: csvDocument,
                contentType: .commaSeparatedText,
                defaultFilename: "FreeLedger-\(dateString).csv"
            ) { result in
                switch result {
                case .success:
                    dismiss()
                case .failure:
                    errorMessage = L("error_save_failed")
                }
                csvDocument = nil
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

    private var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"
        return f.string(from: Date())
    }

    private func exportCSV() {
        do {
            let data = try csvExportService.exportCSV(fields: fields)
            csvDocument = CSVDocument(data: data)
            showExporter = true
        } catch {
            errorMessage = L("error_save_failed")
        }
    }
}

struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }

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
