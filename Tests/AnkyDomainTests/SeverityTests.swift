import AnkyDomain
import Testing

struct SeverityTests {
    @Test(arguments: [0, 5, 10])
    func acceptsScoresFromZeroToTen(value: Int) {
        #expect(Severity(value)?.value == value)
    }

    @Test(arguments: [-1, 11])
    func rejectsScoresOutsideZeroToTen(value: Int) {
        #expect(Severity(value) == nil)
    }
}
