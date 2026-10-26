import AnkyDomain
import Testing

struct PainScoreTests {
    @Test(arguments: [0, 5, 10])
    func acceptsScoresFromZeroToTen(value: Int) {
        #expect(PainScore(value)?.value == value)
    }

    @Test(arguments: [-1, 11])
    func rejectsScoresOutsideZeroToTen(value: Int) {
        #expect(PainScore(value) == nil)
    }
}
