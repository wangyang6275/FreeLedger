import Testing
@testable import FreeLedger

@MainActor @Test func appColorsExist() async throws {
    #expect(AppColors.primary != nil)
}
