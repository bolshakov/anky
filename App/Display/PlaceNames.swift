// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation

/// A list of pairs, not a switch: 28 switch arms go over the lizard limit.
private let placeNames = keyed(
    ("neck", "Neck"),
    ("upper", "Upper back"),
    ("lower", "Lower back"),
    ("tail", "Tailbone"),
    ("si_l", "Left SI joint"),
    ("si_r", "Right SI joint"),
    ("hip_l", "Left hip"),
    ("hip_r", "Right hip"),
    ("ribs", "Ribs"),
    ("chest", "Chest wall"),
    ("shoulder_l", "Left shoulder"),
    ("shoulder_r", "Right shoulder"),
    ("elbow_l", "Left elbow"),
    ("elbow_r", "Right elbow"),
    ("wrist_l", "Left wrist"),
    ("wrist_r", "Right wrist"),
    ("hand_l", "Left hand and fingers"),
    ("hand_r", "Right hand and fingers"),
    ("knee_l", "Left knee"),
    ("knee_r", "Right knee"),
    ("ankle_l", "Left ankle"),
    ("ankle_r", "Right ankle"),
    ("foot_l", "Left foot and toes"),
    ("foot_r", "Right foot and toes"),
    ("heel_l", "Left heel"),
    ("heel_r", "Right heel"),
    ("jaw", "Jaw"),
    ("eyes", "Eyes")
)

private let jointNames = keyed(
    ("neck", "Neck"),
    ("upper", "Upper back"),
    ("lower", "Lower back"),
    ("tail", "Tailbone"),
    ("si", "SI joint"),
    ("hip", "Hip"),
    ("ribs", "Ribs"),
    ("chest", "Chest wall"),
    ("shoulder", "Shoulder"),
    ("elbow", "Elbow"),
    ("wrist", "Wrist"),
    ("hand", "Hand and fingers"),
    ("knee", "Knee"),
    ("ankle", "Ankle"),
    ("foot", "Foot and toes"),
    ("heel", "Heel"),
    ("jaw", "Jaw"),
    ("eyes", "Eyes")
)

private func keyed(_ pairs: (String, LocalizedStringResource)...) -> [String: LocalizedStringResource] {
    Dictionary(uniqueKeysWithValues: pairs)
}

extension PlaceID {
    var displayName: LocalizedStringResource {
        placeNames[rawValue] ?? ""
    }
}

extension Joint {
    var displayName: LocalizedStringResource {
        jointNames[rawValue] ?? ""
    }
}

extension PlaceGroup {
    var displayName: LocalizedStringResource {
        switch self {
        case .spine: "Spine"
        case .pelvisAndChest: "Pelvis and chest"
        case .arms: "Arms"
        case .legs: "Legs"
        case .head: "Head"
        }
    }
}
