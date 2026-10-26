public func deep(_ a: Bool, _ b: Bool, _ c: Bool, _ d: Bool) -> Int {
    if a {
        if b {
            if c {
                if d {
                    return 1
                }
            }
        }
    }
    return 0
}
