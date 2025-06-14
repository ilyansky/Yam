import Foundation
import FirebaseFirestore

protocol TableFetchDataProtocol {

    var isLoading: Bool { get set }
    var addFromIndex: Int { get set }
    var isEndReached: Bool { get set }
    var isFirstPack: Bool { get set }

    func loadPack() async
    func updateEventIDs() async
    func updateEvent(eventID: String) async
    func refresh() async

}
