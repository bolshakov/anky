// SPDX-License-Identifier: GPL-3.0-or-later

/// Provisional Russian drafts for the report PDF's medication table, until design supplies its own in t-276.
let reportDraftPlainValues = table("""
Averages use only doses that have both a before and an after reading (the fourth column). Pain is 0 to 10. => \
Средние значения учитывают только приёмы, у которых есть и запись до, и запись после (четвёртый столбец). \
Боль — от 0 до 10.
Averages use only doses that have both a before and an after reading (the fourth column). Pain is 0 to 10. \
A scheduled medication often has no after-reading. => \
Средние значения учитывают только приёмы, у которых есть и запись до, и запись после (четвёртый столбец). \
Боль — от 0 до 10. У лекарства по расписанию записи после приёма часто нет.
""")

let reportDraftFormatValues = table("""
%@ (%lld–%lld) => %1$@ (%2$lld–%3$lld)
%lld min to the after-reading => %lld мин
%lld h to the after-reading => %lld ч
%lld h %lld min to the after-reading => %1$lld ч %2$lld мин
""")

let reportDraftEnglishFormatValues = table("""
%@ (%lld–%lld) => %1$@ (%2$lld–%3$lld)
%lld min to the after-reading => %lld min
%lld h to the after-reading => %lld h
%lld h %lld min to the after-reading => %1$lld h %2$lld min
""")
