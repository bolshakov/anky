public enum PlaceGroup: CaseIterable, Sendable {
    case spine, pelvisAndChest, arms, legs, head
}

public enum Side: Sendable {
    case left, right
}

public enum Joint: String, CaseIterable, Sendable {
    case neck, upperBack = "upper", lowerBack = "lower", tailbone = "tail"
    case siJoint = "si", hip, ribs, chestWall = "chest"
    case shoulder, elbow, wrist, hand, knee, ankle, foot, heel, jaw, eyes

    public var group: PlaceGroup {
        switch self {
        case .neck, .upperBack, .lowerBack, .tailbone: .spine
        case .siJoint, .hip, .ribs, .chestWall: .pelvisAndChest
        case .shoulder, .elbow, .wrist, .hand: .arms
        case .knee, .ankle, .foot, .heel: .legs
        case .jaw, .eyes: .head
        }
    }

    public var isPaired: Bool {
        switch self {
        case .siJoint, .hip, .shoulder, .elbow, .wrist, .hand, .knee, .ankle, .foot, .heel: true
        default: false
        }
    }

    public var places: [PlaceID] {
        guard isPaired else { return [PlaceID(rawValue: rawValue)] }
        return [PlaceID(rawValue: rawValue + "_l"), PlaceID(rawValue: rawValue + "_r")]
    }

    public func place(_ side: Side) -> PlaceID? {
        guard isPaired else { return nil }
        return PlaceID(rawValue: rawValue + (side == .left ? "_l" : "_r"))
    }
}
