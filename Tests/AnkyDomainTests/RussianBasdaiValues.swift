// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

/// The BASDAI form, list, result screen and their alerts, in the words design wrote for them. Each line is a key and
/// its Russian value, split on " => ".
let basdaiRussianValues = table("""
How would you describe the overall level of fatigue/tiredness you have experienced? => \
Каким был общий уровень слабости (утомляемости)?
How would you describe the overall level of AS **neck, back or hip** pain you have had? => \
Каким был общий уровень боли в **шее, спине или тазобедренных суставах**?
How would you describe the overall level of pain/swelling in joints **other than** neck, back or hips you have had? => \
Каким был общий уровень боли/припухлости в суставах, **кроме** шеи, спины и тазобедренных суставов?
How would you describe the overall level of discomfort you have had from any areas tender to touch or pressure? => \
Каким был общий уровень неприятных ощущений при прикосновении к болезненным областям или надавливании на них?
How would you describe the overall level of morning stiffness you have had from the time you wake up? => \
Каким был общий уровень утренней скованности с момента пробуждения?
How long does your morning stiffness last from the time you wake up? => \
Сколько длится утренняя скованность с момента пробуждения?
Spinal pain => Боль в шее, спине, тазобедренных суставах
Joint pain => Боль в других суставах
Tenderness => Болезненность
Stiffness severity => Выраженность скованности
Stiffness duration => Длительность скованности
Very severe => Наихудшее
0 hrs => 0 ч
2 or more hrs => 2 ч и больше
1 hr => 1 ч
%lld min => %lld мин
1 hr %lld min => 1 ч %lld мин
2 hrs or more => 2 ч и больше
Not answered => Нет ответа
not answered => ответа нет
BASDAI => BASDAI
Bath Ankylosing Spondylitis Disease Activity Index (Garrett et al., J Rheumatol 1994). => \
Bath Ankylosing Spondylitis Disease Activity Index (Garrett et al., J Rheumatol 1994).
Garrett S, et al. J Rheumatol 1994;21(12):2286-91. => Garrett S, et al. J Rheumatol 1994;21(12):2286-91.
Couldn't save this result. Try again. => Не удалось сохранить результат. Попробуй ещё раз.
Delete this result? This can't be undone. => Удалить этот результат? Это нельзя отменить.
Delete result => Удалить результат
Couldn't delete this result. Try again. => Не удалось удалить этот результат. Попробуй ещё раз.
Result deleted => Результат удалён
Score => Результат
Covers last week => За последние 7 дней
BASDAI, score %@, at %@, covers last week => BASDAI, результат %@, в %@, за последние 7 дней
""")

struct RussianBasdaiTests {
    private func value(_ key: String) throws -> String {
        try #require(basdaiRussianValues.first { $0.key == key }).value
    }

    @Test func thirtyOneKeysAreApproved() {
        #expect(basdaiRussianValues.count == 31)
        #expect(Set(basdaiRussianValues.map(\.key)).count == 31)
    }

    @Test func everyBasdaiTextReadsAsDesignWroteIt() throws {
        try CompiledCatalog.withBundle("ru") { ru in
            for (key, expected) in basdaiRussianValues {
                #expect(ru.localizedString(forKey: key, value: nil, table: nil) == expected, "\(key)")
            }
        }
    }

    @Test func theBoldMarksOfQuestionsTwoAndThreeSurviveInRussian() throws {
        let spine = try value("How would you describe the overall level of AS **neck, back or hip** pain you have had?")
        let joints = try value(
            "How would you describe the overall level of pain/swelling in joints **other than** "
                + "neck, back or hips you have had?"
        )
        #expect(spine.contains("**шее, спине или тазобедренных суставах**"))
        #expect(joints.contains("**кроме**"))
    }
}
