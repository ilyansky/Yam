import SwiftUI
import FirebaseFirestore

final class MyEventsViewModel: ObservableObject {

    private let authInteractor = AuthInteractor.shared
    private let dbService = DatabaseService.shared

    @Published var myEvents: [Event] = []

    @Published var isActiveCreateEvent = false

    // EventCardViewModelProtocol
    @Published var selectedEvent: Event?
    @Published var invalidLink = false
    @Published var isActiveEventLocation = false
    @Published var isActiveBuildEvent = false
    @Published var subscribeFail = false
    @Published var unsubcribeFail = false
    @Published var fail = false

    // TableFetchDataProtocol
    @Published var isLoading = false
    var addFromIndex = 0
    var isEndReached = false
    var isFirstPack = true 

    init() {
        Task {
            await loadPack()
        }
    }

}

// MARK: - Support

extension MyEventsViewModel {

    func showCreateEvent() {
        isActiveCreateEvent = true
    }

    func getMyEventsCount() -> String {
        EventHandler.getEventsCountString(myEvents.count)
    }

    private func updateMyEventIDs() async {
        guard let userID = authInteractor.getUserID() else { return }

        await dbService.updateMyEventIDs(userID: userID)
    }

}

// MARK: - EventCard

extension MyEventsViewModel: EventCardViewModelProtocol {

    func showBuildEvent(for event: Event) {
        selectedEvent = event
        isActiveBuildEvent = true
    }

    func showLocation(of event: Event) {
        selectedEvent = event
        isActiveEventLocation = true
    }

    func open(link: String) {
        if !EventHandler.openLink(link) {
            invalidLink = true
        }
    }

    func handleSubscribeButton(event: Event, eventType: EventType) async -> Bool {
        return false
    }

    @MainActor
    func updateEvent(eventID: String) async {
        do {
            let updatedEvent = try await dbService.getEventFromFeed(by: eventID)

            await updateMyEventIDs()

            if let index = myEvents.firstIndex(where: { $0.id == updatedEvent.id }) {
                myEvents[index] = updatedEvent
            }

            Logger.Feed.eventUpdated()
        } catch {
            Logger.Feed.eventNotUpdated(error)
        }
    }

}

// MARK: - Table

extension MyEventsViewModel: TableFetchDataProtocol {

    @MainActor
    func loadPack() async {
        guard !isLoading,
              !isEndReached else { return }

        if isFirstPack {
            await updateMyEventIDs()
        }

        isLoading = true

        let loadResult = await dbService.loadEventPack(addFromIndex: addFromIndex, my: true)
        myEvents = isFirstPack ? loadResult.pack : myEvents + loadResult.pack
        addFromIndex = loadResult.newAddFromIndex
        isEndReached = loadResult.isEndReached

        isLoading = false

        if isFirstPack { self.isFirstPack = false }
    }

    @MainActor
    func refresh() async {
        guard !isLoading else { return }

        isLoading = true

        myEvents.removeAll()
        isFirstPack = true
        addFromIndex = 0
        isEndReached = false

        isLoading = false
    }

    func removeEventFromTable(eventID: String) {
        guard let index = myEvents.firstIndex(where: { $0.id == eventID} ) else {
            Logger.MyEvents.eventNotRemovedFromTable(eventID: eventID)
            return
        }


        myEvents.remove(at: index)
        Logger.MyEvents.eventRemovedFromTable(eventID: eventID)
    }

}
