import Foundation
import GeoFireUtils
import FirebaseFirestore
import SwiftUI
import CoreLocation

final class DatabaseService: ObservableObject {

    static let shared = DatabaseService()
    private let db = Firestore.firestore()

    @Published var myEventsIDs = [String]()
    @Published var subscriptionsIDs = [String]()

    private init() {}

}

// MARK: - References

extension DatabaseService {

    //
    private func getUsersCollection() -> CollectionReference {
        db.collection("users")
    }

    private func getUserRef(userID: String) -> DocumentReference {
        getUsersCollection().document(userID)
    }

    //
    private func getFeedCollection() -> CollectionReference {
        db.collection("feed")
    }

    private func getEventRefFromFeed(eventID: String) -> DocumentReference {
        getFeedCollection().document(eventID)
    }

}

// MARK: - Auth module

extension DatabaseService {

    func createUser(user: YUser, completion: @escaping (Result<YUser, Error>) -> Void) {
        getUserRef(userID: user.id).setData(user.representation) { error in
            if let error {
                completion(.failure(error))
                Logger.Auth.userNotAddedToDatabase(error: error)
            } else {
                completion(.success(user))
                Logger.Auth.userAddedToDatabase()
            }
        }
    }

}

// MARK: - Events module

extension DatabaseService {

    func loadEventPack(
        addFromIndex: Int,
        my: Bool
    ) async -> (pack: [Event], newAddFromIndex: Int, isEndReached: Bool) {
        let right = min(addFromIndex + 3, my ? myEventsIDs.count - 1 : subscriptionsIDs.count - 1)
        guard right >= addFromIndex else { return ([], 0, true) }

        do {
            var pack = [Event]()
            var isEndReached = false

            let eventIDs = my ? myEventsIDs[addFromIndex...right] : subscriptionsIDs[addFromIndex...right]

            for id in eventIDs {
                let event = try await getEventFromFeed(by: id)
                pack.append(event)
            }

            let newAddFromIndex = addFromIndex + eventIDs.count

            if newAddFromIndex >= (my ? myEventsIDs.count : subscriptionsIDs.count) {
                isEndReached = true
            }

            return (pack, newAddFromIndex, isEndReached)
        } catch {
            Logger.Events.loadEventPackFail(error)
            return ([], 0, true)
        }

    }

}

// MARK: - Feed module

extension DatabaseService {

    func loadFeed(lastDoc: DocumentSnapshot?) async -> (events: [Event],
                                                        newLastDoc: DocumentSnapshot?,
                                                        isEndReached: Bool) {
        do {
            var query = getFeedCollection().order(by: "date", descending: false)
            if let lastDoc {
                query = query.start(afterDocument: lastDoc)
            }
            query = query.limit(to: 25)

            let snapshot = try await query.getDocuments()
            let newEvents = try snapshot.documents.compactMap { try $0.data(as: Event.self) }
            let newLastDoc = snapshot.documents.last
            let isEndReached = newEvents.isEmpty

            return (newEvents, newLastDoc, isEndReached)
        } catch {
            if lastDoc != nil {
                Logger.Feed.initialFeedLoadFail(error)
            } else {
                Logger.Feed.nextPackFeedLoadFail(error)
            }

            return ([], lastDoc, true)
        }
    }

}

// MARK: - Map module

extension DatabaseService {

    @Sendable func fetchMatchingEvents(from query: Query,
                                       userLocation: CLLocationCoordinate2D,
                                       radiusInM: Double) async throws -> [QueryDocumentSnapshot] {
        // кваждый квери - это геохеш квадрат
        let snapshot = try await query.getDocuments()

        // фильтрую все доки в снепшоте по дистанции от юзера до ивента
        // тк функция fetchMatchingEvents запускается многократно - происходит многократная фильтрация массивов доков в снепшотах
        return snapshot.documents.filter { eventSnapshot in
            
            do {
                let event = try eventSnapshot.data(as: Event.self)
                let geopoint = event.place.geopoint
                let lat = geopoint.latitude
                let lng = geopoint.longitude

                let eventLoc = CLLocation(latitude: lat, longitude: lng)
                let userLoc = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)

                let distance = userLoc.distance(from: eventLoc)

                return distance <= radiusInM
            } catch {
                Logger.Map.fetchMatchingEventsFail(error)
                return false
            }

        }
    }

    // на входе массив кверис баундс - возвращаю массив кверис по массиву кверис баундс
    func getQueries(from queryBounds: [GFGeoQueryBounds]) -> [Query] {
        queryBounds.map { bound -> Query in
            return getFeedCollection()
                .order(by: "place.geohash")
                .start(at: [bound.startValue])
                .end(at: [bound.endValue])
        }
    }

}

// MARK: - Events manipulating

extension DatabaseService {

    func addEventFor(userID: String, event: Event) async -> Bool {
        do {
            try await getEventRefFromFeed(eventID: event.id).setData(event.representation)

            try await getUserRef(userID: userID).updateData([
                "myEventsIDs": FieldValue.arrayUnion([event.id])
            ])
            Logger.BuildEvent.eventCreateSuccess(id: event.id)
            return true
        } catch {
            Logger.BuildEvent.eventCreateFail(error)
            return false
        }
    }

    func editEventFor(userID: String, event: Event) async -> Bool {
        do {
            try await getEventRefFromFeed(eventID: event.id).updateData(event.representation)

            Logger.BuildEvent.eventEditSuccess()
            return true
        } catch {
            Logger.BuildEvent.eventEditFail(error)
            return false
        }
    }

    func deleteEventFor(userID: String, event: Event) async -> Bool {
        do {
            try await getEventRefFromFeed(eventID: event.id).delete()

            try await getUserRef(userID: userID).updateData([
                "myEventsIDs": FieldValue.arrayRemove([event.id])
            ])

            for userID in event.userIDs {
                try await getUserRef(userID: userID).updateData([
                    "subscriptionsIDs": FieldValue.arrayRemove([event.id])
                ])
            }

            Logger.BuildEvent.eventDeleteSuccess()
            return true
        } catch {
            Logger.BuildEvent.eventDeleteFail(error)
            return false
        }
    }

    func subscribeToTheEvent(userID: String, event: Event) async -> Bool {
        do {
            try await getEventRefFromFeed(eventID: event.id).updateData([
                "seats.busy": event.seats.busy,
                "userIDs": event.userIDs
            ])

            try await getUserRef(userID: userID).updateData([
                "subscriptionsIDs": FieldValue.arrayUnion([event.id])
            ])

            Logger.Feed.subscribeToTheEventSuccess()
            return true
        } catch {
            Logger.Feed.subscribeToTheEventFail(error)
            return false
        }
    }

    func unsubscribeToTheEvent(userID: String, event: Event) async -> Bool {
        do {
            try await getEventRefFromFeed(eventID: event.id).updateData([
                "seats.busy": event.seats.busy,
                "userIDs": event.userIDs
            ])

            try await getUserRef(userID: userID).updateData([
                "subscriptionsIDs": FieldValue.arrayRemove([event.id])
            ])

            Logger.Feed.unsubscribeToTheEventSuccess()
            return true
        } catch {
            Logger.Feed.unsubscribeToTheEventFail(error)
            return false
        }
    }

    func getEventFromFeed(by eventID: String) async throws -> Event {
        let eventSnapshot = try await getFeedCollection().document(eventID).getDocument()
        return try eventSnapshot.data(as: Event.self)
    }

}

// MARK: - Support

extension DatabaseService {

    func updateMyEventIDs(userID: String) async {
        await updateEventIDs(userID: userID, my: true)
    }

    func updateSubscriptionIDs(userID: String) async {
        await updateEventIDs(userID: userID, my: false)
    }

    private func updateEventIDs(userID: String, my: Bool) async {
        do {
            let user = try await getUserRef(userID: userID).getDocument(as: YUser.self)

            if my {
                myEventsIDs = user.myEventsIDs
            } else {
                subscriptionsIDs = user.subscriptionsIDs
            }
        } catch {
            Logger.Feed.getEventsIDsFail(error)
        }
    }

}
