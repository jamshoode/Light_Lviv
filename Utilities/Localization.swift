import Foundation

struct Localization {
    static var language: String {
        // Check preferred languages first as this is what iOS uses for app language
        if let preferred = Locale.preferredLanguages.first, preferred.hasPrefix("uk") {
            return "uk"
        }
        // Fallback to current locale
        if Locale.current.identifier.hasPrefix("uk") {
            return "uk"
        }
        return "en"
    }
    
    static func get(_ key: String) -> String {
        let isUA = language == "uk"
        
        switch key {
        case "loading": return isUA ? "Завантаження графіку..." : "Loading schedule..."
        case "noData": return isUA ? "Немає даних розкладу" : "No schedule data found"
        case "noGroupsSaved": return isUA ? "Групи не вибрано" : "No groups selected"
        case "addSchedule": return isUA ? "Додати розклад" : "Add Schedule"
        case "retry": return isUA ? "Спробувати ще" : "Retry"
        case "reload": return isUA ? "Оновити" : "Reload"
        case "group": return isUA ? "Група" : "Group"
        case "scheduleForGroup": return isUA ? "Розклад для цієї групи" : "Schedule for this group"
        case "details": return isUA ? "Деталі" : "Details"
        case "done": return isUA ? "Готово" : "Done"
        case "cancel": return isUA ? "Скасувати" : "Cancel"
        case "selectGroup": return isUA ? "Оберіть групу" : "Select a group"
        case "settings": return isUA ? "Налаштування" : "Settings"
        case "appName": return isUA ? "Світло Львів" : "Light Lviv"
        case "powerOff_title": return isUA ? "Вимкнення" : "Power Off"
        case "powerOn_title": return isUA ? "Увімкнення" : "Power On"
        case "powerOff_body": return isUA ? "Електроенергії не буде через 15 хв для Групи %@" : "Electricity will be OFF in 15 mins for Group %@"
        case "powerOn_body": return isUA ? "Електроенергія з'явиться через 15 хв для Групи %@" : "Electricity will be ON in 15 mins for Group %@"
        case "delete": return isUA ? "Видалити" : "Delete"
        case "today": return isUA ? "Сьогодні" : "Today"
        case "tomorrow": return isUA ? "Завтра" : "Tomorrow"
        case "noScheduleTomorrow": return isUA ? "Розкладу на завтра ще немає" : "No schedule for tomorrow yet"
        case "scheduleChangedTitle": return isUA ? "Зміна розкладу" : "Schedule Changed"
        case "scheduleChangedBody": return isUA ? "Розклад для групи %@ змінився" : "Schedule for group %@ has changed"
        case "scheduleTomorrowTitle": return isUA ? "Розклад на завтра" : "Schedule for Tomorrow"
        case "scheduleTomorrowBody": return isUA ? "З'явився розклад на завтра для групи %@" : "Schedule for tomorrow is available for group %@"
        case "viewChanges": return isUA ? "Переглянути зміни" : "View Changes"
        case "previous": return isUA ? "Попередній" : "Previous"
        case "current": return isUA ? "Поточний" : "Current"
        case "noChanges": return isUA ? "Змін немає" : "No changes"
        case "lightIsOn": return isUA ? "Світло є!" : "Power is ON!"
        case "lightIsOff": return isUA ? "Світла ніц :(" : "No Power :("
        case "unknownStatus": return isUA ? "Статус невідомий" : "Status Unknown"
        case "renameGroup": return isUA ? "Перейменувати" : "Rename"
        case "enterName": return isUA ? "Введіть назву" : "Enter Name"
        case "selectSettlement": return isUA ? "Оберіть населений пункт" : "Select Settlement"
        case "selectStreet": return isUA ? "Оберіть вулицю" : "Select Street"
        case "selectHouse": return isUA ? "Оберіть будинок" : "Select House Number"
        case "searchPlaceholder": return isUA ? "Пошук..." : "Search..."
        case "groupFound": return isUA ? "Ваша група:" : "Your Group:"
        case "addGroup": return isUA ? "Додати групу" : "Add Group"
        case "findByAddress": return isUA ? "Знайти за адресою" : "Find by Address"
        default: return key
        }
    }
}
