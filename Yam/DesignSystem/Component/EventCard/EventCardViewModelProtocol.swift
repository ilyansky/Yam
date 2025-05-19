import Foundation

protocol EventCardViewModelProtocol {

    var selectedEvent: Event? { get set }
    var invalidLink: Bool { get set }
    var isActiveEventLocation: Bool { get set }
    var isActiveBuildEvent: Bool { get set }
    var subscribeFail: Bool { get set }
    var unsubcribeFail: Bool { get set }
    var fail: Bool { get set }

    func showBuildEvent(for event: Event)

    func showLocation(of event: Event)

    func open(link: String)

    func handleSubscribeButton(
        event: Event,
        eventType: EventType,
    ) async -> Bool

    func updateEvent(eventID: String) async

}

extension EventCardViewModelProtocol {

    func getNewEvent(
        userID: String,
        event: Event,
        eventType: EventType,
        subscriptionsContainsEvent: Bool
    ) async -> Event? {

        switch eventType {
        case .added:
            // можно ли отписаться от ивента?
            guard subscriptionsContainsEvent,
                  event.seats.busy > 0,
                  let userToRemoveIndex = event.userIDs.firstIndex(of: userID) else {
                return nil
            }

            // изменяем поля ивента
            var newEvent = event
            newEvent.seats.busy -= 1
            newEvent.userIDs.remove(at: userToRemoveIndex)

            return newEvent

        case .notAdded:
            // можно ли подписаться на ивент?
            guard !subscriptionsContainsEvent &&
                    event.seats.busy < event.seats.all else {
                return nil
            }

            // изменяем поля ивента
            var newEvent = event
            newEvent.seats.busy += 1
            newEvent.userIDs.append(userID)

            return newEvent

        default: return nil
        }
        
    }

    func convertToString(from seats: Seats) -> String {
        EventHandler.getSeatsString(from: seats)
    }

    func convertToString(from date: Date) -> String {
        EventHandler.getDateString(from: date)
    }

}
