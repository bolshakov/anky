import Foundation

public enum PlaceSearch {
    public static func joints(
        matching query: String,
        jointName: (Joint) -> String,
        groupName: (PlaceGroup) -> String
    ) -> [Joint] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return Joint.allCases }
        return Joint.allCases.filter { joint in
            contains(jointName(joint), query) || contains(groupName(joint.group), query)
        }
    }

    private static func contains(_ name: String, _ query: String) -> Bool {
        name.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }
}
