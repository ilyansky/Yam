import Foundation
import Combine

final class NavigationManager: ObservableObject {

    private let authInteractor = AuthInteractor.shared
    @Published var isUserAuthorized = false

    init() {
        // подписка на изменения из AuthInteractor.
        // доступ к паблишеру, а не к значению, тип паблишера = Published<Bool>.Publisher.
        // паблишер публикует новое значение каждый раз, когда isUserAuthorized меняется.
        authInteractor.$isUserAuthorized
        // доставка значений на главной очереди.
            .receive(on: DispatchQueue.main)
        // это автоматическое присваивание значений из паблишера в @Published свойство (через ссылку на его projected value).
            .assign(to: &$isUserAuthorized)
    }

    func goToAuthorizedEntry() {
        isUserAuthorized = true
    }

    func backToRoot() {
        isUserAuthorized = false
    }

}
