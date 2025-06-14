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
1. Создать проект в Firebase.
2. Добавить в проект в Firebase модуль Authentication, в качестве провайдера выбрать Email/Password. 
3. Добавить в проект в Firebase модуль Firestore Database.
4. Скачать файл GoogleService-Info.plist, поместить его в директорию Yam/Yam/Core/Config.
5. Создать файл APIKey.swift в директории Yam/Yam/Core/Config.
6. Получить `Cloud name` и `Upload preset name` на сайте https://cloudinary.com. ВАЖНО: Upload preset нужно создавать типа Unsigned.
7. Вставить в файл APIKey.swift следующий код, заменив плейсхолдеры на данные, полученные в пункте 6.

```swift
enum APIKey {
    static let cloudNameSECURE: String = "YOUR_CLOUD_NAME"
    static let uploadPresetSECURE: String = "YOUR_UPLOAD_PRESET"
}
```

# Демо
https://github.com/user-attachments/assets/2b863b47-f72d-4021-846d-9839e46fa916
