import AnkyDomain
import Foundation
import Testing

struct PlaceCatalogTests {
    @Test func aPlaceIdEncodesAsAPlainString() throws {
        let data = try JSONEncoder().encode([PlaceID(rawValue: "lower")])
        #expect(String(data: data, encoding: .utf8) == #"["lower"]"#)
        #expect(try JSONDecoder().decode([PlaceID].self, from: data) == [PlaceID(rawValue: "lower")])
    }
}
}
