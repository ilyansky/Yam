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
- Менеджер зависимостей - SPM

Чтобы собрать проект, нужно: 
1. Создать проект в Firebase и поместить файл GoogleService-Info.plist  в директорию Yam/Yam/Core.
2. В файле Yam/Yam/Service/ImageService.swift добавить свои данные в плейсхолдеры cloudNameSECURE и uploadPresetSECURE. Их можно получить на сайте https://cloudinary.com через открытый API.

```swift
final class ImageService {

    ...

    let cloudNameSECURE: String = "YOUR_CLOUD_NAME"
    var uploadPresetSECURE: String = "YOUR_UPLOAD_PRESET"
    
    ...

}
```
