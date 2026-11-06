#!/usr/bin/env python3
"""Build the empty yearly budget workbooks the app ships as templates.

    python3 tools/budget_template.py            # -> app/assets/templates/budget_{de,en,ru}.xlsx
                                                #    and app/lib/budget/template_texts.dart

The layout is the contract in README "The spreadsheet is the database":
sheet 1 bookings (A Datum, B Monat formula, C Kategorie, D Beschreibung,
E Betrag, F Notiz, rows pre-formatted to 2000), sheet 2 overview (inputs,
actual/plan/difference by category, chart), sheet 3 settings (categories
with type and hint, limits), sheet 4 history. Everything is in the language
of the template; the app finds rows by their labels (any of the three
languages), the formulas use the sheet and category names of the file.

Year placeholder: 2026 in the titles and in the history labels; the app
replaces it when it creates a file for another year.

The texts below are also written to app/lib/budget/template_texts.dart, which
is what the app uses to translate a file from one template language to
another (every label is looked up by its text and replaced by the same key's
text in the target language), so keep the keys parallel across languages.
"""
import os
import sys

from openpyxl import Workbook
from openpyxl.chart import BarChart, LineChart, Reference
from openpyxl.comments import Comment
from openpyxl.formatting.rule import CellIsRule, FormulaRule
from openpyxl.styles import Alignment, Border, Font, PatternFill, Side
from openpyxl.utils import get_column_letter
from openpyxl.workbook.defined_name import DefinedName
from openpyxl.worksheet.datavalidation import DataValidation
from openpyxl.worksheet.table import Table, TableStyleInfo

YEAR = 2026
FONT = "Roboto"
C_DARK, C_MID, C_BAND, C_PINK, C_PINK_L, C_PINK_D, C_WHITE, C_GREEN = "3B3B40", "8E8E95", "F3F3F5", "E7A5BE", "FBE9F0", "B5456E", "FFFFFF", "4E7A5A"
EUR = '#,##0.00 "€";-#,##0.00 "€";"–"'
EUR0 = '#,##0 "€";-#,##0 "€";"–"'
MAX_ROWS = 2000

# --- texts per language --------------------------------------------------------------
L = {
    "de": dict(
        sheets=("Buchungen", "Übersicht", "Einstellungen", "Verlauf", "Regeln"),
        months=["Jan", "Feb", "Mär", "Apr", "Mai", "Jun", "Jul", "Aug", "Sep", "Okt", "Nov", "Dez"],
        cols=["Datum", "Monat", "Kategorie", "Beschreibung", "Betrag (€)", "Notiz"],
        title="Budget", subtitle="Alle Beträge in €. Rosa hinterlegte Zellen sind Eingaben (Kontostand, Sparkonto, Kreditkarte, Plan), alles andere wird aus den Buchungen berechnet.",
        konto="Konto", start="Kontostand Monatsanfang (alle Konten + Bargeld)", save="Sparkonto", card="Kreditkarte offen (Monatsanfang)",
        inc="Einnahmen", exp="Ausgaben", saldo="Saldo (Einnahmen − Ausgaben)", expect="Erwarteter Kontostand Monatsende",
        diff="Abweichung zum nächsten Monatsanfang (Konto + Sparkonto − Kreditkarte)", year="Jahr",
        ist="Ausgaben nach Kategorie (Ist)", sum_exp="Summe Ausgaben", plan="Plan", sum_plan="Summe Plan", difference="Differenz (Plan − Ist)", sum="Summe",
        chart="Ausgaben und Plan je Monat", settings_title="Einstellungen",
        settings_sub="Kategorien speisen die Auswahl in den Buchungen, Limits steuern die Hervorhebung. Die App liest dieses Blatt; weitere Einstellungen können hier ergänzt werden.",
        cat_cols=["Kategorie", "Typ", "", "Hinweis", "Symbol & Farbe"], types=("Ausgabe", "Einnahme", "Umbuchung"),
        setting_cols=["Einstellung", "Wert"],
        settings=[("Monatslimit 1", 3000, "Monatsausgaben über diesem Wert: gelb"), ("Monatslimit 2", 4000, "Monatsausgaben über diesem Wert: rot"),
                  ("Ausgabenlimit 1", 200, "Einzelbuchung ab diesem Betrag: hellrosa"), ("Ausgabenlimit 2", 500, "Einzelbuchung ab diesem Betrag: rosa"),
                  ("Ausgabenlimit 3", 1000, "Einzelbuchung ab diesem Betrag: dunkelrosa")],
        legend="Legende", input_="Eingabe", legend_text="rosa hinterlegte Zellen sind Eingaben, alles andere sind Formeln",
        hist_title="Verlauf", hist_sub="Saldo = Einnahmen − Ausgaben je Monat. Kumuliert zeigt, was über das Jahr gespart oder von den Ersparnissen gelebt wurde.",
        hist_cols=["Monat", "Saldo", "Kumuliert"], hist_chart="Kumuliertes Saldo",
        rules_title="Regeln", rules_sub="Beim Import von Kontoauszügen und beim Scannen: enthält der Buchungstext das Muster, bekommt die Buchung diese Kategorie (und Beschreibung, wenn angegeben). Groß-/Kleinschreibung ist egal, * steht für beliebigen Text. Die App fragt erst danach die Historie und zuletzt das Modell.",
        rules_cols=["Muster", "Kategorie", "Beschreibung"],
        categories=[
            ("Wohnen", 0, "Miete, Energie, Versicherung, Möbel"), ("Lebensmittel", 0, "Supermarkt, Bäckerei"), ("Restaurants & Cafés", 0, "Essen außer Haus, Lieferdienste, Kantine"),
            ("Haushalt", 0, "Drogerie, Deko, Geräte, Kleinkram"), ("Kleidung", 0, ""), ("Gesundheit", 0, "Apotheke, Ärzte, Versicherung"),
            ("Schulung", 0, "Schule, Kurse, Sport der Kinder, eigene Kurse"), ("Kinder", 0, "Taschengeld, Geschenke für die Kinder"), ("Transport", 0, "Jahreskarte, Tickets, Taxi, Flüge"),
            ("Freizeit & Reisen", 0, "Hotels, Eintritte, Wandern"), ("Abos & Internet", 0, "Private Abos, Mobilfunk, Streaming"), ("Arbeit", 0, "Dienstreisen, Werkzeuge"),
            ("Business", 0, "Eigenes Unternehmen: Cloud, KI-Tools, Geräte"), ("Bank & Gebühren", 0, "Kontoführung, Überweisungsgebühren, Zinsen"),
            ("Kreditkarte", 2, "Kreditkartenabrechnung: Umbuchung, zählt nicht als Ausgabe, die Käufe sind einzeln erfasst"), ("Spenden", 0, ""),
            ("Sonstiges", 0, "Friseur, Lotto, Geschenke, Souvenirs"), ("Einnahmen", 1, "Negative Beträge: Gehalt, Kindergeld, Rückerstattungen"),
        ],
    ),
    "en": dict(
        sheets=("Entries", "Overview", "Settings", "History", "Rules"),
        months=["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
        cols=["Date", "Month", "Category", "Description", "Amount (€)", "Note"],
        title="Budget", subtitle="All amounts in €. Pink cells are inputs (balance, savings, credit card, plan), everything else is computed from the entries.",
        konto="Account", start="Balance at start of month (all accounts + cash)", save="Savings account", card="Credit card open (start of month)",
        inc="Income", exp="Expenses", saldo="Saldo (income − expenses)", expect="Expected balance at end of month",
        diff="Deviation to next month start (account + savings − credit card)", year="Year",
        ist="Expenses by category (actual)", sum_exp="Total expenses", plan="Plan", sum_plan="Total plan", difference="Difference (plan − actual)", sum="Total",
        chart="Expenses and plan per month", settings_title="Settings",
        settings_sub="Categories feed the selection in the entries, limits drive the highlighting. The app reads this sheet; further settings can be added here.",
        cat_cols=["Category", "Type", "", "Hint", "Icon & colour"], types=("Expense", "Income", "Transfer"),
        setting_cols=["Setting", "Value"],
        settings=[("Month limit 1", 3000, "Monthly expenses above this: amber"), ("Month limit 2", 4000, "Monthly expenses above this: red"),
                  ("Expense limit 1", 200, "Single entry from this amount: light pink"), ("Expense limit 2", 500, "Single entry from this amount: pink"),
                  ("Expense limit 3", 1000, "Single entry from this amount: dark pink")],
        legend="Legend", input_="Input", legend_text="pink cells are inputs, everything else are formulas",
        hist_title="History", hist_sub="Saldo = income − expenses per month. Cumulated shows what was saved or taken from savings over the year.",
        hist_cols=["Month", "Saldo", "Cumulated"], hist_chart="Cumulated saldo",
        rules_title="Rules", rules_sub="For statement imports and scans: when the booking text contains the pattern, the booking gets this category (and description, if given). Case does not matter, * stands for any text. The app asks the history only after the rules, and the model last.",
        rules_cols=["Pattern", "Category", "Description"],
        categories=[
            ("Housing", 0, "Rent, energy, insurance, furniture"), ("Groceries", 0, "Supermarket, bakery"), ("Restaurants & Cafés", 0, "Eating out, delivery, canteen"),
            ("Household", 0, "Drugstore, decoration, appliances, small stuff"), ("Clothing", 0, ""), ("Health", 0, "Pharmacy, doctors, insurance"),
            ("Education", 0, "School, courses, kids' sports, own courses"), ("Kids", 0, "Pocket money, gifts for the kids"), ("Transport", 0, "Season ticket, tickets, taxi, flights"),
            ("Leisure & Travel", 0, "Hotels, admissions, hiking"), ("Subscriptions & Internet", 0, "Private subscriptions, mobile, streaming"), ("Work", 0, "Business trips, tools"),
            ("Business", 0, "Own company: cloud, AI tools, devices"), ("Bank & Fees", 0, "Account fees, transfer fees, interest"),
            ("Credit card", 2, "Credit card statement: transfer, not an expense, the purchases are entered individually"), ("Donations", 0, ""),
            ("Other", 0, "Hairdresser, lottery, gifts, souvenirs"), ("Income", 1, "Negative amounts: salary, child benefit, refunds"),
        ],
    ),
    "ru": dict(
        sheets=("Записи", "Обзор", "Настройки", "История", "Правила"),
        months=["Янв", "Фев", "Мар", "Апр", "Май", "Июн", "Июл", "Авг", "Сен", "Окт", "Ноя", "Дек"],
        cols=["Дата", "Месяц", "Категория", "Описание", "Сумма (€)", "Заметка"],
        title="Бюджет", subtitle="Все суммы в €. Розовые ячейки это ввод (остаток, сбережения, кредитка, план), остальное считается из записей.",
        konto="Счёт", start="Остаток на начало месяца (все счета + наличные)", save="Сберегательный счёт", card="Кредитка: долг на начало месяца",
        inc="Доходы", exp="Расходы", saldo="Сальдо (доходы − расходы)", expect="Ожидаемый остаток на конец месяца",
        diff="Отклонение к началу следующего месяца (счёт + сбережения − кредитка)", year="Год",
        ist="Расходы по категориям (факт)", sum_exp="Итого расходы", plan="План", sum_plan="Итого план", difference="Разница (план − факт)", sum="Итого",
        chart="Расходы и план по месяцам", settings_title="Настройки",
        settings_sub="Категории попадают в выбор при записи, лимиты управляют подсветкой. Приложение читает этот лист; сюда можно добавлять другие настройки.",
        cat_cols=["Категория", "Тип", "", "Подсказка", "Иконка и цвет"], types=("Расход", "Доход", "Перевод"),
        setting_cols=["Настройка", "Значение"],
        settings=[("Месячный лимит 1", 3000, "Расходы за месяц выше этого: жёлтый"), ("Месячный лимит 2", 4000, "Расходы за месяц выше этого: красный"),
                  ("Лимит записи 1", 200, "Одна запись от этой суммы: светло-розовый"), ("Лимит записи 2", 500, "Одна запись от этой суммы: розовый"),
                  ("Лимит записи 3", 1000, "Одна запись от этой суммы: тёмно-розовый")],
        legend="Легенда", input_="Ввод", legend_text="розовые ячейки это ввод, остальное формулы",
        hist_title="История", hist_sub="Сальдо = доходы − расходы за месяц. Накопительно показывает, сколько за год отложено или прожито из сбережений.",
        hist_cols=["Месяц", "Сальдо", "Накопительно"], hist_chart="Сальдо накопительно",
        rules_title="Правила", rules_sub="При импорте выписок и сканировании: если текст операции содержит шаблон, запись получает эту категорию (и описание, если задано). Регистр не важен, * означает любой текст. История проверяется после правил, модель в последнюю очередь.",
        rules_cols=["Шаблон", "Категория", "Описание"],
        categories=[
            ("Жильё", 0, "Аренда, энергия, страховка, мебель"), ("Продукты", 0, "Супермаркет, пекарня"), ("Рестораны и кафе", 0, "Еда вне дома, доставка, столовая"),
            ("Дом и быт", 0, "Бытовая химия, декор, техника, мелочи"), ("Одежда", 0, ""), ("Здоровье", 0, "Аптека, врачи, страховка"),
            ("Обучение", 0, "Школа, курсы, спорт детей, свои курсы"), ("Дети", 0, "Карманные деньги, подарки детям"), ("Транспорт", 0, "Проездной, билеты, такси, перелёты"),
            ("Отдых и поездки", 0, "Отели, билеты, походы"), ("Подписки и интернет", 0, "Личные подписки, мобильная связь, стриминг"), ("Работа", 0, "Командировки, инструменты"),
            ("Бизнес", 0, "Своё дело: облако, ИИ-инструменты, техника"), ("Банк и комиссии", 0, "Обслуживание счёта, комиссии за переводы, проценты"),
            ("Кредитка", 2, "Погашение кредитки: перевод, не расход, покупки записаны по отдельности"), ("Пожертвования", 0, ""),
            ("Прочее", 0, "Парикмахер, лотерея, подарки, сувениры"), ("Доходы", 1, "Отрицательные суммы: зарплата, пособия, возвраты"),
        ],
    ),
}


def font(bold=False, color=C_DARK, size=10, italic=False):
    return Font(name=FONT, bold=bold, color=color, size=size, italic=italic)


def fill(color):
    return PatternFill("solid", start_color=color, end_color=color)


def header_row(ws, row, c0, c1, dark=True):
    for c in range(c0, c1 + 1):
        cell = ws.cell(row=row, column=c)
        cell.font = font(bold=True, color=C_WHITE if dark else C_DARK)
        cell.fill = fill(C_DARK if dark else C_PINK_L)
        cell.alignment = Alignment(horizontal="center" if c > c0 else "left", vertical="center")


def style_block(ws, r0, r1, c0, c1, number=EUR, band=True):
    for r in range(r0, r1 + 1):
        for c in range(c0, c1 + 1):
            cell = ws.cell(row=r, column=c)
            cell.font = font()
            if c > c0:
                cell.number_format = number
                cell.alignment = Alignment(horizontal="right")
            if band and (r - r0) % 2 == 1:
                cell.fill = fill(C_BAND)


def total_row(ws, r, c0, c1, number=EUR):
    for c in range(c0, c1 + 1):
        cell = ws.cell(row=r, column=c)
        cell.font = font(bold=True)
        cell.fill = fill(C_PINK_L)
        cell.border = Border(top=Side(style="thin", color=C_PINK))
        if c > c0:
            cell.number_format = number
            cell.alignment = Alignment(horizontal="right")


def input_cell(cell, number=EUR):
    cell.font = font(color="5A2A3F")
    cell.fill = fill(C_PINK_L)
    cell.number_format = number
    cell.alignment = Alignment(horizontal="right")


def q(name):
    """Sheet name for a formula."""
    return "'" + name.replace("'", "''") + "'"


def build(lang, out):
    t = L[lang]
    s_entries, s_over, s_set, s_hist, s_rules = t["sheets"]
    cats = t["categories"]
    expense = [c for c in cats if c[1] == 0]
    income_name = next(c[0] for c in cats if c[1] == 1)
    transfer_names = [c[0] for c in cats if c[1] == 2]

    wb = Workbook()
    ws_book = wb.active
    ws_book.title = s_entries
    ws_over = wb.create_sheet(s_over)
    ws_cat = wb.create_sheet(s_set)
    ws_hist = wb.create_sheet(s_hist)
    ws_rules = wb.create_sheet(s_rules)
    for ws, color in [(ws_book, C_DARK), (ws_over, C_PINK), (ws_cat, C_MID), (ws_hist, C_MID), (ws_rules, C_MID)]:
        ws.sheet_properties.tabColor = color
        ws.sheet_view.showGridLines = False

    # ---- settings ----
    ws = ws_cat
    ws["A1"] = t["settings_title"]
    ws["A1"].font = font(bold=True, size=16)
    ws["A2"] = t["settings_sub"]
    ws["A2"].font = font(color=C_MID)
    for c, h in enumerate(t["cat_cols"], start=1):
        ws.cell(row=4, column=c, value=h)
    header_row(ws, 4, 1, 5)
    for i, (name, typ, hint) in enumerate(cats):
        r = 5 + i
        ws.cell(row=r, column=1, value=name).font = font(bold=True)
        ws.cell(row=r, column=2, value=t["types"][typ]).font = font()
        ws.cell(row=r, column=4, value=hint).font = font(color=C_MID)
        ws.cell(row=r, column=5).font = font(color=C_MID)  # "home #FF2E7E", written by the app
        if i % 2 == 1:
            for c in range(1, 6):
                ws.cell(row=r, column=c).fill = fill(C_BAND)
    CAT_FIRST, CAT_LAST = 5, 5 + len(cats) - 1
    ws.column_dimensions["A"].width = 24
    ws.column_dimensions["B"].width = 11
    ws.column_dimensions["C"].width = 4
    ws.column_dimensions["D"].width = 60
    ws.column_dimensions["E"].width = 18
    ws["F4"], ws["G4"] = t["setting_cols"]
    header_row(ws, 4, 6, 7)
    names = ["MonatsLimit1", "MonatsLimit2", "AusgabenLimit1", "AusgabenLimit2", "AusgabenLimit3"]
    for i, (label, val, note) in enumerate(t["settings"]):
        r = 5 + i
        ws.cell(row=r, column=6, value=label).font = font(bold=True)
        input_cell(ws.cell(row=r, column=7, value=val), EUR0)
        ws.cell(row=r, column=8, value=note).font = font(color=C_MID)
        wb.defined_names[names[i]] = DefinedName(names[i], attr_text=f"{q(s_set)}!$G${r}")
    ws.column_dimensions["F"].width = 20
    ws.column_dimensions["G"].width = 12
    ws.column_dimensions["H"].width = 48
    ws["F12"] = t["legend"]
    ws["F12"].font = font(bold=True)
    ws["F13"] = t["input_"]
    input_cell(ws["F13"], "@")
    ws["G13"] = t["legend_text"]
    ws["G13"].font = font(color=C_MID)
    ws.freeze_panes = "A5"

    # ---- entries ----
    ws = ws_book
    for c, h in enumerate(t["cols"], start=1):
        ws.cell(row=1, column=c, value=h)
    header_row(ws, 1, 1, 6)
    for r in range(2, MAX_ROWS + 1):
        ws.cell(row=r, column=1).number_format = "DD.MM.YYYY"
        c = ws.cell(row=r, column=2, value=f'=IF(A{r}="","",MONTH(A{r}))')
        c.font = font()
        c.alignment = Alignment(horizontal="center")
        ws.cell(row=r, column=5).number_format = EUR
    table = Table(displayName="Buchungen", ref=f"A1:F{MAX_ROWS}")
    table.tableStyleInfo = TableStyleInfo(name="TableStyleLight1", showRowStripes=False, showColumnStripes=False)
    ws.add_table(table)
    dv_cat = DataValidation(type="list", formula1=f"={q(s_set)}!$A${CAT_FIRST}:$A${CAT_LAST}", allow_blank=True, showErrorMessage=True)
    dv_cat.add(f"C2:C{MAX_ROWS}")
    dv_date = DataValidation(type="date", operator="greaterThan", formula1="DATE(2020,1,1)", allow_blank=True)
    dv_date.add(f"A2:A{MAX_ROWS}")
    for dv in (dv_cat, dv_date):
        ws.add_data_validation(dv)
    rng = f"E2:E{MAX_ROWS}"
    ws.conditional_formatting.add(rng, FormulaRule(formula=["E2>=AusgabenLimit3"], fill=fill(C_PINK_D), font=Font(name=FONT, color=C_WHITE, bold=True), stopIfTrue=True))
    ws.conditional_formatting.add(rng, FormulaRule(formula=["E2>=AusgabenLimit2"], fill=fill(C_PINK), stopIfTrue=True))
    ws.conditional_formatting.add(rng, FormulaRule(formula=["E2>=AusgabenLimit1"], fill=fill(C_PINK_L), stopIfTrue=True))
    ws.conditional_formatting.add(rng, FormulaRule(formula=['AND(E2<>"",E2<0)'], font=Font(name=FONT, color=C_GREEN, italic=True)))
    for tn in transfer_names:
        ws.conditional_formatting.add(f"A2:F{MAX_ROWS}", FormulaRule(formula=[f'$C2="{tn}"'], font=Font(name=FONT, color=C_MID, italic=True)))
    ws.conditional_formatting.add(f"A2:F{MAX_ROWS}", FormulaRule(formula=["MOD(ROW(),2)=0"], fill=fill(C_BAND)))
    for k, v in {"A": 12, "B": 8, "C": 22, "D": 44, "E": 13, "F": 34}.items():
        ws.column_dimensions[k].width = v
    ws.freeze_panes = "A2"

    # ---- overview ----
    ws = ws_over
    ws["A1"] = f"{t['title']} {YEAR}"
    ws["A1"].font = font(bold=True, size=18)
    ws["A2"] = t["subtitle"]
    ws["A2"].font = font(color=C_MID)
    for m in range(12):
        ws.cell(row=3, column=2 + m, value=m + 1).font = font(color=C_MID, size=8)
        ws.cell(row=3, column=2 + m).alignment = Alignment(horizontal="center")

    def month_header(row, label):
        ws.cell(row=row, column=1, value=label)
        for m in range(12):
            ws.cell(row=row, column=2 + m, value=t["months"][m])
        ws.cell(row=row, column=14, value=t["year"])
        header_row(ws, row, 1, 14)

    month_header(4, t["konto"])
    R_START, R_SAVE, R_CARD, R_INC, R_EXP, R_SALDO, R_EXPECT, R_DIFF = 5, 6, 7, 8, 9, 10, 11, 12
    labels = {R_START: t["start"], R_SAVE: t["save"], R_CARD: t["card"], R_INC: t["inc"], R_EXP: t["exp"], R_SALDO: t["saldo"], R_EXPECT: t["expect"], R_DIFF: t["diff"]}
    for r, label in labels.items():
        ws.cell(row=r, column=1, value=label).font = font(bold=r in (R_SALDO, R_EXPECT))
    E = q(s_entries)
    not_expense = "".join(f',{E}!$C:$C,"<>{n}"' for n in [income_name] + transfer_names)
    for m in range(1, 13):
        col = get_column_letter(1 + m)
        for r in (R_START, R_SAVE, R_CARD):
            input_cell(ws.cell(row=r, column=1 + m))
        ws.cell(row=R_INC, column=1 + m, value=f'=-SUMIFS({E}!$E:$E,{E}!$B:$B,{col}$3,{E}!$C:$C,"{income_name}")')
        ws.cell(row=R_EXP, column=1 + m, value=f'=SUMIFS({E}!$E:$E,{E}!$B:$B,{col}$3{not_expense})')
        ws.cell(row=R_SALDO, column=1 + m, value=f"={col}{R_INC}-{col}{R_EXP}")
        ws.cell(row=R_EXPECT, column=1 + m, value=f'=IF({col}{R_START}="","",{col}{R_START}+{col}{R_SALDO})')
        if m < 12:
            nxt = get_column_letter(2 + m)
            ws.cell(row=R_DIFF, column=1 + m, value=f'=IF(OR({nxt}{R_START}="",{col}{R_EXPECT}=""),"",{nxt}{R_START}+N({nxt}{R_SAVE})-N({nxt}{R_CARD})-{col}{R_EXPECT}-N({col}{R_SAVE})+N({col}{R_CARD}))')
    for r in (R_INC, R_EXP, R_SALDO):
        ws.cell(row=r, column=14, value=f"=SUM(B{r}:M{r})")
    style_block(ws, R_INC, R_DIFF, 1, 14, band=False)
    for r in (R_START, R_SAVE, R_CARD):
        ws.cell(row=r, column=1).font = font()
    for c in range(1, 15):
        cell = ws.cell(row=R_SALDO, column=c)
        cell.font = font(bold=True, size=11)
        cell.fill = fill(C_PINK_L)
        cell.border = Border(top=Side(style="thin", color=C_PINK), bottom=Side(style="thin", color=C_PINK))
    ws.conditional_formatting.add(f"B{R_SALDO}:N{R_SALDO}", CellIsRule(operator="lessThan", formula=["0"], font=Font(name=FONT, color=C_PINK_D, bold=True, size=11)))
    ws.conditional_formatting.add(f"B{R_SALDO}:N{R_SALDO}", CellIsRule(operator="greaterThan", formula=["0"], font=Font(name=FONT, color=C_GREEN, bold=True, size=11)))
    for c in range(2, 15):
        ws.cell(row=R_EXPECT, column=c).font = font(bold=True)
    ws.conditional_formatting.add(f"B{R_DIFF}:L{R_DIFF}", CellIsRule(operator="lessThan", formula=["-50"], font=Font(name=FONT, color=C_PINK_D, bold=True)))

    R_IST_H = R_DIFF + 2
    month_header(R_IST_H, t["ist"])
    R_IST = R_IST_H + 1
    for i, (name, _, _) in enumerate(expense):
        r = R_IST + i
        ws.cell(row=r, column=1, value=name)
        for m in range(1, 13):
            col = get_column_letter(1 + m)
            ws.cell(row=r, column=1 + m, value=f"=SUMIFS({E}!$E:$E,{E}!$C:$C,$A{r},{E}!$B:$B,{col}$3)")
        ws.cell(row=r, column=14, value=f"=SUM(B{r}:M{r})")
    R_IST_SUM = R_IST + len(expense)
    ws.cell(row=R_IST_SUM, column=1, value=t["sum_exp"])
    for c in range(2, 15):
        col = get_column_letter(c)
        ws.cell(row=R_IST_SUM, column=c, value=f"=SUM({col}{R_IST}:{col}{R_IST_SUM - 1})")
    style_block(ws, R_IST, R_IST_SUM - 1, 1, 14)
    total_row(ws, R_IST_SUM, 1, 14)
    ws.conditional_formatting.add(f"B{R_IST_SUM}:M{R_IST_SUM}", FormulaRule(formula=[f"B{R_IST_SUM}>MonatsLimit2"], fill=fill(C_PINK_D), font=Font(name=FONT, color=C_WHITE, bold=True), stopIfTrue=True))
    ws.conditional_formatting.add(f"B{R_IST_SUM}:M{R_IST_SUM}", FormulaRule(formula=[f"B{R_IST_SUM}>MonatsLimit1"], fill=fill(C_PINK), font=Font(name=FONT, bold=True), stopIfTrue=True))

    R_PLAN_H = R_IST_SUM + 2
    month_header(R_PLAN_H, t["plan"])
    R_PLAN = R_PLAN_H + 1
    for i, (name, _, _) in enumerate(expense):
        r = R_PLAN + i
        ws.cell(row=r, column=1, value=name)
        for m in range(1, 13):
            input_cell(ws.cell(row=r, column=1 + m), EUR0)
        ws.cell(row=r, column=14, value=f"=SUM(B{r}:M{r})")
        ws.cell(row=r, column=14).number_format = EUR0
        ws.cell(row=r, column=14).font = font(bold=True)
    R_PLAN_SUM = R_PLAN + len(expense)
    ws.cell(row=R_PLAN_SUM, column=1, value=t["sum_plan"])
    for c in range(2, 15):
        col = get_column_letter(c)
        ws.cell(row=R_PLAN_SUM, column=c, value=f"=SUM({col}{R_PLAN}:{col}{R_PLAN_SUM - 1})")
    total_row(ws, R_PLAN_SUM, 1, 14, EUR0)
    for r in range(R_PLAN, R_PLAN_SUM):
        ws.cell(row=r, column=1).font = font()

    R_DIF_H = R_PLAN_SUM + 2
    month_header(R_DIF_H, t["difference"])
    R_DIF = R_DIF_H + 1
    for i in range(len(expense)):
        r = R_DIF + i
        ws.cell(row=r, column=1, value=expense[i][0])
        for m in range(1, 13):
            col = get_column_letter(1 + m)
            ws.cell(row=r, column=1 + m, value=f'=IF({col}{R_PLAN + i}="","",{col}{R_PLAN + i}-{col}{R_IST + i})')
        ws.cell(row=r, column=14, value=f"=SUM(B{r}:M{r})")
    R_DIF_SUM = R_DIF + len(expense)
    ws.cell(row=R_DIF_SUM, column=1, value=t["sum"])
    for c in range(2, 15):
        col = get_column_letter(c)
        ws.cell(row=R_DIF_SUM, column=c, value=f"={col}{R_PLAN_SUM}-{col}{R_IST_SUM}")
    style_block(ws, R_DIF, R_DIF_SUM - 1, 1, 14)
    total_row(ws, R_DIF_SUM, 1, 14)
    ws.conditional_formatting.add(f"B{R_DIF}:N{R_DIF_SUM}", CellIsRule(operator="lessThan", formula=["0"], font=Font(name=FONT, color=C_PINK_D, bold=True)))
    ws.column_dimensions["A"].width = 52
    for c in range(2, 15):
        ws.column_dimensions[get_column_letter(c)].width = 13
    ws.freeze_panes = "B5"
    chart = BarChart()
    chart.type = "col"
    chart.title = t["chart"]
    chart.height, chart.width = 7.5, 22
    chart.add_data(Reference(ws, min_col=1, max_col=13, min_row=R_IST_SUM, max_row=R_IST_SUM), from_rows=True, titles_from_data=True)
    chart.add_data(Reference(ws, min_col=1, max_col=13, min_row=R_PLAN_SUM, max_row=R_PLAN_SUM), from_rows=True, titles_from_data=True)
    chart.set_categories(Reference(ws, min_col=2, max_col=13, min_row=R_IST_H, max_row=R_IST_H))
    chart.series[0].graphicalProperties.solidFill = C_PINK
    chart.series[1].graphicalProperties.solidFill = C_MID
    chart.legend.position = "b"
    ws.add_chart(chart, "P4")

    # ---- history ----
    ws = ws_hist
    ws["A1"] = t["hist_title"]
    ws["A1"].font = font(bold=True, size=16)
    ws["A2"] = t["hist_sub"]
    ws["A2"].font = font(color=C_MID)
    for c, h in enumerate(t["hist_cols"], start=1):
        ws.cell(row=4, column=c, value=h)
    header_row(ws, 4, 1, 3)
    O = q(s_over)
    for m in range(1, 13):
        r = 4 + m
        col = get_column_letter(1 + m)
        ws.cell(row=r, column=1, value=f"{YEAR}-{m:02d}")
        ws.cell(row=r, column=2, value=f'=IF(COUNTIF({E}!$B:$B,{m})=0,"",{O}!{col}{R_SALDO})')
        # Sum so far, N/A (a gap in the chart) for months without bookings, so
        # a year that starts in March still gets a line.
        ws.cell(row=r, column=3, value=f'=IF(B{r}="",NA(),SUM(B$5:B{r}))')
    style_block(ws, 5, 16, 1, 3)
    for r in range(5, 17):
        ws.cell(row=r, column=1).alignment = Alignment(horizontal="left")
        ws.cell(row=r, column=3).font = font(bold=True)
    ws.conditional_formatting.add("B5:B16", CellIsRule(operator="greaterThan", formula=["0"], font=Font(name=FONT, color=C_GREEN)))
    ws.conditional_formatting.add("B5:B16", CellIsRule(operator="lessThan", formula=["0"], font=Font(name=FONT, color=C_PINK_D)))
    ws.conditional_formatting.add("C5:C16", FormulaRule(formula=["ISNA(C5)"], font=Font(name=FONT, color=C_WHITE)))
    for k, v in {"A": 12, "B": 14, "C": 14}.items():
        ws.column_dimensions[k].width = v
    ws.freeze_panes = "A5"
    lc = LineChart()
    lc.title = t["hist_chart"]
    lc.height, lc.width = 9, 26
    lc.add_data(Reference(ws, min_col=3, min_row=4, max_row=16), titles_from_data=True)
    lc.set_categories(Reference(ws, min_col=1, min_row=5, max_row=16))
    lc.series[0].graphicalProperties.line.solidFill = C_PINK_D
    lc.legend = None
    lc.display_blanks = "gap"
    ws.add_chart(lc, "E4")

    # ---- rules ----
    ws = ws_rules
    ws["A1"] = t["rules_title"]
    ws["A1"].font = font(bold=True, size=16)
    ws["A2"] = t["rules_sub"]
    ws["A2"].font = font(color=C_MID)
    for c, h in enumerate(t["rules_cols"], start=1):
        ws.cell(row=4, column=c, value=h)
    header_row(ws, 4, 1, 3)
    for r in range(5, 60):
        for c in range(1, 4):
            ws.cell(row=r, column=c).font = font()
    dv_rule = DataValidation(type="list", formula1=f"={q(s_set)}!$A${CAT_FIRST}:$A${CAT_LAST}", allow_blank=True, showErrorMessage=True)
    dv_rule.add("B5:B200")
    ws.add_data_validation(dv_rule)
    for k, v in {"A": 32, "B": 24, "C": 32}.items():
        ws.column_dimensions[k].width = v
    ws.freeze_panes = "A5"

    wb.calculation.fullCalcOnLoad = True
    wb.properties.title = f"{t['title']} {YEAR}"
    wb.save(out)


def flatten(t):
    """Every text of a language as key -> text (lists and tuples get indexed keys)."""
    out = {}
    for key, val in t.items():
        if isinstance(val, str):
            out[key] = val
        elif key == "settings":
            for i, (label, _, note) in enumerate(val):
                out[f"settings.{i}.label"], out[f"settings.{i}.note"] = label, note
        elif key == "categories":
            for i, (name, _, hint) in enumerate(val):
                out[f"categories.{i}.name"], out[f"categories.{i}.hint"] = name, hint
        else:
            for i, v in enumerate(val):
                out[f"{key}.{i}"] = v
    return out


def write_dart(path):
    flat = {lang: flatten(L[lang]) for lang in L}
    keys = list(flat["de"])
    for lang in L:
        assert list(flat[lang]) == keys, lang
    # A text must translate to one text only, whichever key carried it. The
    # type labels are translated by the category's parsed type, not by text
    # ("Income" is a type and a category, "Einnahme" and "Einnahmen" in German).
    for src in L:
        for dst in L:
            seen = {}
            for k in keys:
                if k.startswith("types."):
                    continue
                a, b = flat[src][k], flat[dst][k]
                if a and a in seen and seen[a] != b:
                    raise SystemExit(f"{src}->{dst}: '{a}' is both '{seen[a]}' and '{b}'")
                seen[a] = b
    def esc(v):
        return v.replace("\\", "\\\\").replace("'", "\\'").replace("$", "\\$")
    lines = ["// GENERATED by tools/budget_template.py, do not edit: the texts of the",
             "// bundled templates, used to translate a file between the languages.",
             "library;", "",
             "/// Template language -> label key -> text. Keys are the same in every language.",
             "const Map<String, Map<String, String>> templateTexts = {"]
    for lang in L:
        lines.append(f"  '{lang}': {{")
        for k in keys:
            lines.append(f"    '{k}': '{esc(flat[lang][k])}',")
        lines.append("  },")
    lines.append("};")
    lines.append("")
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))


if __name__ == "__main__":
    here = os.path.dirname(os.path.abspath(__file__))
    root = os.path.join(here, "..", "app", "assets", "templates")
    os.makedirs(root, exist_ok=True)
    for lang in sys.argv[1:] or L:
        path = os.path.join(root, f"budget_{lang}.xlsx")
        build(lang, path)
        print(path, os.path.getsize(path))
    dart = os.path.join(here, "..", "app", "lib", "budget", "template_texts.dart")
    write_dart(dart)
    print(dart)
