# Yam - You and me

Мобильное приложение для iOS, позволяющее искать людей по интересам! 

Все просто: 
1. Заходи в приложение 
2. Подписывайся на интересующий тебя ивент (будь то футбол, игра в шахматы или совместный просмотр фильма) 
3. Находи новые знакомства!⚽🏓🫂

Стек:
- Архитектура - MVVM
- Интерфейс - SwiftUI
- Работа с данными - Combine
- Картинки - Cloudinary, SDWebImage
- Карта - MapKit, GeoFireUtils, ClusterMap
- Бэк - Firebase
- Асинхронность, многопоточность - async / await, GCD
- Менеджер зависимостей - SPM

Чтобы собрать проект, нужно: 
1. Создать проект в Firebase и поместить файл GoogleService-Info.plist  в директорию Yam/Yam/Core/Config.
2. Создать файл APIKey.swift в директории Yam/Yam/Core/Config, получить секьюрные дынные на сайте https://cloudinary.com через открытый API, вставить в созданный файл следующий код, заменив плейсхолдеры на актуальные секьюрные данные: 

```swift
enum APIKey {
    static let cloudNameSECURE: String = "YOUR_CLOUD_NAME"
    static let uploadPresetSECURE: String = "YOUR_UPLOAD_PRESET"
}
```


# Демо
https://github.com/user-attachments/assets/2b863b47-f72d-4021-846d-9839e46fa916

