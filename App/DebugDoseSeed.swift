// SPDX-License-Identifier: GPL-3.0-or-later
#if DEBUG
    import AnkyDomain
    import AnkyMedicationModel
    import Foundation

    /// Debug builds only, for the walks: a launch with `ANKY_SEED_DOSE_IN=<seconds>` saves one scheduled medication,
    /// "Walkmed", due daily at the first whole minute at least that many seconds away. It saves through the model, so
    /// the scheduler asks for permission and requests the notification as for any medication. The file
    /// `dose-seeded` in the folder marks it done, so a relaunch with the same folder seeds nothing.
    @MainActor
    enum DebugDoseSeed {
        static func seed(into medications: MedicationsModel, folder: URL, now: Date = .now) {
            let marker = folder.appending(path: "dose-seeded")
            guard let seconds = requestedSeconds, !FileManager.default.fileExists(atPath: marker.path),
                  let medication = medication(
                      dueAt: firstWholeMinute(after: now.addingTimeInterval(seconds)),
                      now: now
                  ),
                  (try? medications.add(medication)) != nil else { return }
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try? Data().write(to: marker)
        }

        private static var requestedSeconds: TimeInterval? {
            ProcessInfo.processInfo.environment["ANKY_SEED_DOSE_IN"].flatMap(Int.init).map(TimeInterval.init)
        }

        private static func firstWholeMinute(after date: Date) -> Date {
            let minutes = (date.timeIntervalSinceReferenceDate / 60).rounded(.up)
            return Date(timeIntervalSinceReferenceDate: minutes * 60)
        }

        private static func medication(dueAt date: Date, now: Date) -> Medication? {
            let calendar = Calendar.current
            let parts = calendar.dateComponents([.hour, .minute], from: date)
            guard let hour = parts.hour, let minute = parts.minute,
                  let time = DoseTime(hour: hour, minute: minute),
                  let schedule = try? MedicationSchedule(
                      repeat: .days(1),
                      times: [time],
                      start: ScheduleDay(now, in: calendar.timeZone),
                      end: nil
                  )
            else { return nil }
            var medication = Medication(id: UUID(), name: "Walkmed", takenAs: .scheduled, createdAt: now)
            medication.schedule = schedule
            return medication
        }
    }
#endif
